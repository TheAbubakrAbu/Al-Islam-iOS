#if os(iOS)
import SwiftUI

/// The Prophecies of the Prophet (peace and blessings be upon him): things he foretold, and what
/// history did with them.
///
/// EVERY narration here was resolved to a row in the app's OWN hadith packs and read from there -
/// never retyped from a website (`Scripts/verify_prophecies.py` checks the whole list, and
/// `Scripts/prophecy_ranges.py` computes the token ranges each `ScriptureQuote` quotes by). Three
/// candidates from the source sites were DROPPED because our packs grade them weak, and two more
/// because their citations could not be resolved here at all; the standing rule is sahih or hasan
/// only, and a claim we cannot verify does not ship.
///
/// The sources that suggested the list - islamreligion.com, Yaqeen Institute's "The Prophecies of
/// Prophet Muhammad" (Sh. Mohammad Elshinawy) and Proving Islam's "101 Fulfilled Prophecies" - gave
/// permission to draw on them (Abu, 2026-09-19). The wording below is this app's own; the hadith
/// text is the shelf's.
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

        /// Title, summary, group and aliases folded once, for the index's search.
        var searchKey: String {
            IslamArticles.fold(([title, summary, group.rawValue] + aliases).joined(separator: " "))
        }

        enum Group: String, CaseIterable, Identifiable {
            case empires = "Empires and conquests"
            case companions = "The Companions"
            case ummah = "The ummah after him"
            case endTimes = "Signs before the Hour"

            var id: String { rawValue }
            var systemImage: String {
                switch self {
                case .empires:    return "crown"
                case .companions: return "person.2"
                case .ummah:      return "building.columns"
                case .endTimes:   return "hourglass"
                }
            }
        }
    }

    /// The strongest first, within each group: the ones whose wording is most specific and whose
    /// fulfilment is hardest to read backwards into the text.
    static let entries: [Entry] = [
        .init(id: "security-hira", title: "A woman travelling alone, and the treasures of Persia",
              summary: "Safety from al-Hira to the Kaaba, and Chosroes' treasure opened - to a man who lived to see both.",
              group: .empires,
              aliases: ["persia", "chosroes", "khosrow", "kisra", "hira", "kaaba", "kabah", "woman travelling", "safety", "security", "adi ibn hatim", "treasure", "poverty"]),
        .init(id: "end-of-empires", title: "The last Chosroes, the last Caesar",
              summary: "When these two perish there will be no more after them - said while both empires ruled the world.",
              group: .empires,
              aliases: ["rome", "byzantine", "caesar", "persia", "sasanian", "yazdegerd", "heraclius", "empire", "emperor", "no chosroes"]),
        .init(id: "egypt-conquest", title: "Egypt, and how to treat its people",
              summary: "You will conquer Egypt; be good to its people, for they have kinship and a covenant.",
              group: .empires,
              aliases: ["egypt", "misr", "copts", "coptic", "amr ibn al-as", "umar", "hajar", "kinship", "covenant", "abu dharr", "conquest"]),
        .init(id: "mutah-martyrs", title: "Three deaths, six hundred miles away",
              summary: "He announced Zayd, Ja'far and Ibn Rawahah's deaths at Mu'tah as they happened, from Madinah.",
              group: .companions,
              aliases: ["mutah", "zayd", "jafar", "ibn rawahah", "khalid ibn al-walid", "jordan", "battle", "martyrs", "banner", "sword of allah"]),
        .init(id: "tabuk-wind", title: "The wind at Tabuk",
              summary: "A violent wind would strike that night; the man who stood up in it was carried off.",
              group: .companions,
              aliases: ["tabuk", "wind", "storm", "camels", "tayyi", "expedition"]),
        .init(id: "hasan-reconciles", title: "The grandson who would reconcile two armies",
              summary: "This son of mine is a chief, and Allah will reconcile two great parties of Muslims through him.",
              group: .companions,
              aliases: ["hasan", "al-hasan", "muawiyah", "year of unity", "am al-jamaah", "caliphate", "grandson", "civil war", "reconcile"]),
        .init(id: "six-signs", title: "Six signs, in order",
              summary: "His death, Jerusalem, a plague, surplus wealth, a tribulation, a broken truce - and they came in that order.",
              group: .ummah,
              aliases: ["six signs", "awf ibn malik", "jerusalem", "plague", "amwas", "uthman", "tribulation", "truce", "wealth", "order"]),
        .init(id: "fire-hijaz", title: "A fire out of the Hijaz",
              summary: "A fire lighting the necks of camels in Busra - and in 654 AH a volcano east of Madinah did exactly that.",
              group: .endTimes,
              aliases: ["fire", "hijaz", "volcano", "busra", "madinah", "654", "harrat", "lava", "eruption", "camels", "end times", "hour"]),
    ]

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
        return Self.entries.filter { entry in terms.allSatisfy { entry.searchKey.contains($0) } }
    }

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
                    Section {
                        Text(verbatim: "He foretold things no one could have known, and he said them in front of people who wrote them down and lived to see them happen. A few are gathered here, with what the narration says and what history did with it. Every hadith is quoted from this app's own collections and is sahih or hasan; anything our copies grade weak was left out.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(grouped, id: \.0.id) { group, rows in
                        Section(header: ArticleHeader(group.rawValue.uppercased())) {
                            ForEach(rows) { row($0) }
                        }
                    }

                    AboutSignsSection(heading: "About Prophecy & Prophethood",
                                      systemImage: "checkmark.seal",
                                      doors: [.prophet, .sunnah, .hadith],
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
                switch entry.id {
                case "security-hira":      securityHira
                case "end-of-empires":     endOfEmpires
                case "egypt-conquest":     egyptConquest
                case "mutah-martyrs":      mutahMartyrs
                case "tabuk-wind":         tabukWind
                case "hasan-reconciles":   hasanReconciles
                case "six-signs":          sixSigns
                case "fire-hijaz":         fireHijaz
                default:                   EmptyView()
                }
            }
            .themedListRowBackground()
        }
        .selectableArticleList(article: "Prophecy-\(entry.id)")
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Empires

    @ViewBuilder
    private var securityHira: some View {
        Section(header: ArticleHeader("WHAT HE SAID")) {
            Text(verbatim: "'Adi ibn Hatim was sitting with him when a man complained of poverty and another of highway robbery. Arabia at that time was not a place where a woman travelled alone, and Persia was the superpower on its border.")
                .font(.body)

            ScriptureQuote(hadith: "bukhari:3595", cite: "Sahih al-Bukhari 3595",
                           arabic: 60...64, english: 58...77)
        }

        Section(header: ArticleHeader("WHAT HAPPENED")) {
            Text(verbatim: "'Adi lived to see it. He reports at the end of the same narration that he saw a woman travel from al-Hira and circle the Kaaba fearing no one but Allah, and that he was among those who opened the treasures of Chosroes son of Hurmuz. Both halves were fulfilled in the lifetime of the man who heard them.")
                .font(.body)
        }

        Section(header: ArticleHeader("WHY IT IS STRIKING")) {
            Text(verbatim: "The prophecy is specific in a way that could have failed: a named road, a named empire, a named man told he would live to see it. It is reported by that same man against himself, which is the opposite of how invented stories are told.")
                .font(.body)
        }
    }

    @ViewBuilder
    private var endOfEmpires: some View {
        Section(header: ArticleHeader("WHAT HE SAID")) {
            Text(verbatim: "Rome and Persia had divided the known world between them for centuries. He said each would have a last ruler.")
                .font(.body)

            ScriptureQuote(hadith: "bukhari:3618", cite: "Sahih al-Bukhari 3618",
                           arabic: 29...34, english: 4...14)
        }

        Section(header: ArticleHeader("WHAT HAPPENED")) {
            Text(verbatim: "Yazdegerd III was the last Sasanian emperor; the dynasty ended with him and no Chosroes followed. Caesar is the subtler half: Heraclius was the last to rule Syria and Egypt as Caesar, and Byzantium never returned to those lands. The Muslims did spend the treasures of both, as the same narration says they would.")
                .font(.body)
        }
    }

    @ViewBuilder
    private var egyptConquest: some View {
        Section(header: ArticleHeader("WHAT HE SAID")) {
            ScriptureQuote(hadith: "muslim:2543", cite: "Sahih Muslim 2543",
                           arabic: 45...50, english: 0...15)

            Text(verbatim: "The instruction that follows the prediction is the remarkable part: he told them how to behave in a country they did not yet rule, because its people had a claim of kinship on them through Hajar, the mother of Isma'il.")
                .font(.body)
        }

        Section(header: ArticleHeader("WHAT HAPPENED")) {
            Text(verbatim: "Egypt was opened under 'Amr ibn al-'As in the caliphate of 'Umar. Abu Dharr, who narrated the hadith, later saw two men quarrelling over the space of a brick there and left, as he had been told to.")
                .font(.body)
        }
    }

    // MARK: Companions

    @ViewBuilder
    private var mutahMartyrs: some View {
        Section(header: ArticleHeader("WHAT HE SAID")) {
            Text(verbatim: "The army had gone to Mu'tah, in what is now Jordan - about six hundred miles from Madinah, weeks away by the communications of the time. He stood and announced the battle as it was happening.")
                .font(.body)

            ScriptureQuote(hadith: "bukhari:1246", cite: "Sahih al-Bukhari 1246",
                           arabic: 30...33, english: 4...11)
        }

        Section(header: ArticleHeader("WHAT HAPPENED")) {
            Text(verbatim: "He named the three commanders in the order they fell - Zayd, then Ja'far, then 'Abdullah ibn Rawahah - and his eyes filled with tears as he spoke. Then he said a sword of Allah's swords took the banner, and Khalid ibn al-Walid brought the army out. The messenger confirming it all arrived days later.")
                .font(.body)
        }
    }

    @ViewBuilder
    private var tabukWind: some View {
        Section(header: ArticleHeader("WHAT HE SAID")) {
            ScriptureQuote(hadith: "bukhari:1481", cite: "Sahih al-Bukhari 1481",
                           arabic: 69...73, english: 87...93)

            Text(verbatim: "He told them to tie up their camels and that no one should stand in it.")
                .font(.body)
        }

        Section(header: ArticleHeader("WHAT HAPPENED")) {
            Text(verbatim: "The wind came that night as he said. A man who stood up in it was carried away and thrown onto the two mountains of Tayyi'.")
                .font(.body)
        }
    }

    @ViewBuilder
    private var hasanReconciles: some View {
        Section(header: ArticleHeader("WHAT HE SAID")) {
            Text(verbatim: "He took his grandson al-Hasan up onto the pulpit beside him and said of a child who was then very young:")
                .font(.body)

            ScriptureQuote(hadith: "bukhari:3629", cite: "Sahih al-Bukhari 3629",
                           arabic: 41...43, english: 18...24)
        }

        Section(header: ArticleHeader("WHAT HAPPENED")) {
            Text(verbatim: "Nearly forty years later, with two Muslim armies facing each other, al-Hasan gave up the caliphate to Mu'awiyah and ended the war. The year is still called the Year of Unity. The prophecy named the child, the act, and that it would be two parties of Muslims - the detail that makes it hard to read backwards.")
                .font(.body)
        }
    }

    // MARK: The ummah, and the Hour

    @ViewBuilder
    private var sixSigns: some View {
        Section(header: ArticleHeader("WHAT HE SAID")) {
            Text(verbatim: "At Tabuk, sitting in a leather tent, he told 'Awf ibn Malik to count six things.")
                .font(.body)

            ScriptureQuote(hadith: "bukhari:3176", cite: "Sahih al-Bukhari 3176",
                           arabic: 46...50, english: 21...30)
        }

        Section(header: ArticleHeader("WHAT HAPPENED")) {
            Text(verbatim: "They came in the order given. He died in 11 AH. Jerusalem was opened in 15 AH. The plague of 'Amwas struck in 18 AH and took thousands, including Abu 'Ubaydah. Wealth reached the point described under 'Uthman. The tribulation came with the killing of 'Uthman in 35 AH, and the broken truce followed. Six predictions, in sequence, inside one generation.")
                .font(.body)
        }
    }

    @ViewBuilder
    private var fireHijaz: some View {
        Section(header: ArticleHeader("WHAT HE SAID")) {
            ScriptureQuote(hadith: "bukhari:7118", cite: "Sahih al-Bukhari 7118",
                           arabic: 27...32, english: 10...20)
        }

        Section(header: ArticleHeader("WHAT HAPPENED")) {
            Text(verbatim: "In 654 AH a volcanic fissure opened east of Madinah and erupted for weeks. The historians of the time - Ibn Kathir and al-Nawawi among those who recorded it - write that the glow was seen from Busra in Syria, hundreds of miles north, and that people read by its light at night. The lava field it left, Harrat Rahat, is still there.")
                .font(.body)
        }

        Section(header: ArticleHeader("A NOTE")) {
            Text(verbatim: "This is one of the few end-times signs with a date attached to it by people who watched it happen and knew the hadith. It is quoted here as they reported it, not as proof that the Hour is near: he himself said no one knows when that is.")
                .font(.body)
        }
    }
}
#endif
