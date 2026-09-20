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

        enum Group: String, CaseIterable, Identifiable {
            case why = "Why prophets are given signs"
            case before = "The prophets before him"
            case his = "His own"

            var id: String { rawValue }
        }

        /// Title, summary and aliases folded once, for the index's search.
        var searchKey: String {
            IslamArticles.fold(([title, summary, group.rawValue] + aliases).joined(separator: " "))
        }
    }

    static let entries: [Entry] = [
        .init(id: "why", title: "Why a prophet is given a miracle",
              summary: "A sign is a credential, matched to what the people of that age already prized.",
              group: .why,
              aliases: ["mujizah", "proof", "evidence", "credential", "sign", "purpose"]),
        .init(id: "earlier", title: "Salih, Ibrahim, Musa and 'Isa",
              summary: "The she-camel, the fire that did not burn, the staff and the sea, the dead raised.",
              group: .before,
              aliases: ["moses", "jesus", "abraham", "saleh", "thamud", "she-camel", "fire", "staff",
                        "sea", "parting", "healing", "cradle", "raised the dead", "isa", "musa",
                        "ibrahim", "nimrod", "pharaoh", "firaun"]),
        .init(id: "others", title: "Dawud, Sulayman and Yunus",
              summary: "Iron softened, the wind and the jinn, the speech of birds, and a man kept alive in a whale.",
              group: .before,
              aliases: ["david", "solomon", "jonah", "whale", "fish", "iron", "mountains", "birds",
                        "ants", "jinn", "wind", "sheba", "saba", "hoopoe", "dhun-nun", "sulaiman",
                        "dawood", "yunus"]),
        .init(id: "quran", title: "The Quran itself",
              summary: "His standing miracle: the only one still open to examination fourteen centuries later.",
              group: .his,
              aliases: ["ijaz", "inimitability", "challenge", "eloquence", "language", "arabic",
                        "poetry", "literary", "muhammad"]),
        .init(id: "moon", title: "The splitting of the moon",
              summary: "Asked for a sign, he pointed at the moon and it split in two before them.",
              group: .his,
              aliases: ["qamar", "shaqq al-qamar", "quraysh", "mina", "surah 54", "muhammad"]),
        .init(id: "water", title: "Water from between his fingers",
              summary: "At al-Hudaybiyah a whole company drank and made wudu from a small pot.",
              group: .his,
              aliases: ["hudaybiyah", "jabir", "thirst", "wudu", "vessel", "fifteen hundred",
                        "provision", "food", "muhammad"]),
        .init(id: "trunk", title: "The palm trunk that wept",
              summary: "The stump he used to lean on cried aloud when he moved to a pulpit.",
              group: .his,
              aliases: ["minbar", "pulpit", "palm", "stump", "wept", "crying", "hasan al-basri",
                        "friday", "khutbah", "muhammad"]),
        .init(id: "isra", title: "The night journey and the ascent",
              summary: "Taken by night from Makkah to al-Aqsa and raised through the heavens, and he described a city he had never seen.",
              group: .his,
              aliases: ["isra", "miraj", "mi'raj", "night journey", "ascension", "aqsa", "jerusalem",
                        "buraq", "heavens", "abu bakr", "siddiq", "muhammad"]),
    ]

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Every term has to hit, the same rule the Miracles of the Quran index searches by.
    private var results: [Entry] {
        let terms = IslamArticles.fold(query).split(separator: " ").map(String.init)
        guard !terms.isEmpty else { return [] }
        return Self.entries.filter { entry in terms.allSatisfy { entry.searchKey.contains($0) } }
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
                        Text(verbatim: "Every prophet was given something his people could not explain away, and it was always chosen to speak to them: sorcery in Egypt, medicine among the Greeks of Palestine, language among the Arabs. Read in that order, the signs given to Muhammad (peace and blessings be upon him) are not an odd claim to assess on their own - they are the last entry in a pattern Muslims, Jews and Christians already accept.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(grouped, id: \.0.id) { group, rows in
                        Section(header: ArticleHeader(group.rawValue.uppercased())) {
                            ForEach(rows) { row($0) }
                        }
                    }

                    AboutSignsSection(heading: "About Miracles & Prophethood",
                                      systemImage: "staroflife",
                                      doors: [.prophets, .prophet, .god],
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
                switch entry.id {
                case "why":     why
                case "earlier": earlier
                case "others":  others
                case "quran":   quran
                case "moon":    moon
                case "water":   water
                case "trunk":   trunk
                case "isra":    isra
                default:        EmptyView()
                }

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

    @ViewBuilder
    private var why: some View {
        Section(header: ArticleHeader("A SIGN IS A CREDENTIAL")) {
            Text(verbatim: "A messenger arrives claiming to speak for God. Anyone can claim that. A miracle is the credential that cannot be forged: something outside the reach of the people being addressed, done openly, in front of those best placed to expose it.")
                .font(.body)

            Text(verbatim: "So the sign is always matched to the age. Egypt's court was full of expert magicians, and Musa was given a staff that swallowed their work. 'Isa came to a people who prized healing, and he healed the blind and the leper and raised the dead. The Arabs had no equal in language, and the sign given to Muhammad (peace and blessings be upon him) was a book.")
                .font(.body)
        }

        Section(header: ArticleHeader("AND WHAT IT CANNOT DO")) {
            Text(verbatim: "A miracle compels no one. The Quran is blunt about this: people watched the sea split and still went back to a calf. A sign removes the excuse of ignorance; it does not remove the choice.")
                .font(.body)

            ScriptureQuote(quran: "6:111")
        }
    }

    @ViewBuilder
    private var earlier: some View {
        Section(header: ArticleHeader("SALIH: THE SHE-CAMEL")) {
            Text(verbatim: "Thamud asked for a sign and were given one out of the rock itself, with a warning not to harm it.")
                .font(.body)

            ScriptureQuote(quran: "7:73")
        }

        Section(header: ArticleHeader("IBRAHIM: THE FIRE")) {
            Text(verbatim: "They built a fire and threw him into it. The command that followed is one of the shortest in the Quran:")
                .font(.body)

            ScriptureQuote(quran: "21:69")
        }

        Section(header: ArticleHeader("MUSA: THE STAFF AND THE SEA")) {
            Text(verbatim: "Sent to a court that had made an art of sorcery, he was given a sign the magicians themselves recognised as beyond them - and they were the first to believe.")
                .font(.body)

            ScriptureQuote(quran: "20:20")

            ScriptureQuote(quran: "26:63")
        }

        Section(header: ArticleHeader("'ISA: HEALING AND THE DEAD")) {
            Text(verbatim: "He was given signs of life itself, and the Quran has him name them as things done by Allah's permission, never his own power.")
                .font(.body)

            ScriptureQuote(quran: "3:49")

            Text(verbatim: "His first sign came before any of that, while he was still an infant in arms, and it was an answer to the accusation against his mother:")
                .font(.body)

            ScriptureQuote(quran: "19:29-30")
        }
    }

    @ViewBuilder
    private var others: some View {
        Section(header: ArticleHeader("DAWUD: IRON AND THE MOUNTAINS")) {
            Text(verbatim: "Dawud (peace be upon him) was given a voice the mountains and the birds answered, and iron that yielded in his hands.")
                .font(.body)

            ScriptureQuote(quran: "34:10")

            Text(verbatim: "The Quran names what he made with it: armour, so that the gift was a trade taught to a prophet and not a spectacle.")
                .font(.body)
        }

        Section(header: ArticleHeader("SULAYMAN: THE WIND, THE JINN, THE BIRDS")) {
            Text(verbatim: "His son was given a kingdom of a kind no one was given before or after: the wind under his command, the jinn working for him, and the speech of the animals.")
                .font(.body)

            ScriptureQuote(quran: "34:12")

            ScriptureQuote(quran: "27:16")

            Text(verbatim: "The most quietly extraordinary of them is the ant. He halted an army because he overheard one, and the Quran preserves what she said:")
                .font(.body)

            ScriptureQuote(quran: "27:18")

            Text(verbatim: "He asked for the kingdom and asked in the same breath that it not be given to anyone after him, which is the point the story is told for: the gift was tested obedience, not a reward.")
                .font(.body)
        }

        Section(header: ArticleHeader("YUNUS: ALIVE IN THE FISH")) {
            Text(verbatim: "Yunus (peace be upon him) left his people before he was permitted to, and was swallowed at sea. That he lived is the sign; what he said in the dark is why the story is in the Quran at all.")
                .font(.body)

            ScriptureQuote(quran: "21:87")

            Text(verbatim: "The Quran then says plainly what would have happened otherwise:")
                .font(.body)

            ScriptureQuote(quran: "37:143-144")

            Text(verbatim: "It is the one sign in this list whose whole content is a du'a. He was not saved by the fish releasing him but by the words he said inside it, and the Prophet (peace and blessings be upon him) told his ummah that no one says them in distress without being answered.")
                .font(.body)
        }
    }

    @ViewBuilder
    private var quran: some View {
        Section(header: ArticleHeader("THE STANDING MIRACLE")) {
            Text(verbatim: "The signs given to the earlier prophets were events: you had to be there. The Quran is the one miracle that did not end with the generation that saw it - the same text is in your hands now, and the challenge it makes is still open.")
                .font(.body)

            ScriptureQuote(quran: "2:23")
        }

        Section(header: ArticleHeader("WHY IT LANDED WHERE IT DID")) {
            Text(verbatim: "Pre-Islamic Arabia measured a man by his tongue. Poetry was the currency of status, and the best verses were prized above wealth. The book came to the people least likely to be impressed by language and most able to judge it - and its fiercest opponents, who had every motive to answer it, never produced the three verses asked of them.")
                .font(.body)
        }
    }

    @ViewBuilder
    private var moon: some View {
        Section(header: ArticleHeader("WHAT HAPPENED")) {
            Text(verbatim: "The Quraysh asked him for a sign. At Mina, before them, the moon split.")
                .font(.body)

            ScriptureQuote(hadith: "bukhari:3636", cite: "Sahih al-Bukhari 3636",
                           arabic: 27...28, english: 1...13)

            ScriptureQuote(quran: "54:1")
        }

        Section(header: ArticleHeader("WHY IT IS REPORTED THE WAY IT IS")) {
            Text(verbatim: "The narration is plain to the point of flatness - it happened, and he said bear witness. What makes it hard to dismiss is the setting: it is addressed to hostile eyewitnesses in a Meccan surah, recited publicly to the very people who were there. A claim that a whole city had seen something it had not would have been the easiest of all to refute.")
                .font(.body)
        }
    }

    @ViewBuilder
    private var water: some View {
        Section(header: ArticleHeader("WHAT HAPPENED")) {
            Text(verbatim: "On the day of al-Hudaybiyah the people ran out of water. He put his hand into a small vessel:")
                .font(.body)

            ScriptureQuote(hadith: "bukhari:3576", cite: "Sahih al-Bukhari 3576",
                           arabic: 64...70, english: 77...85)
        }

        Section(header: ArticleHeader("HOW MANY SAW IT")) {
            Text(verbatim: "Jabir was asked afterwards how many they had been, and answered that had they been a hundred thousand it would have been enough for them; they were fifteen hundred. This is not a sign reported by one man in private - it is reported by a Companion who names the crowd that drank from it.")
                .font(.body)
        }
    }

    @ViewBuilder
    private var trunk: some View {
        Section(header: ArticleHeader("WHAT HAPPENED")) {
            Text(verbatim: "He used to lean on a palm trunk while giving the Friday sermon. When a pulpit was built for him and he stepped onto it instead:")
                .font(.body)

            ScriptureQuote(hadith: "bukhari:3584", cite: "Sahih al-Bukhari 3584",
                           arabic: 65...68, english: 38...63)
        }

        Section(header: ArticleHeader("WHAT HE DID ABOUT IT")) {
            Text(verbatim: "He came down from the pulpit and embraced it until it quietened, and said it was crying for what it used to hear of the remembrance of Allah. Al-Hasan al-Basri used to weep at this hadith and say: a piece of wood yearns for the Messenger of Allah - you have more right to yearn for him than it did.")
                .font(.body)
        }
    }

    @ViewBuilder
    private var isra: some View {
        Section(header: ArticleHeader("WHAT HAPPENED")) {
            Text(verbatim: "In one night he was taken from the sacred mosque in Makkah to al-Masjid al-Aqsa in Jerusalem, and from there raised through the heavens. The Quran opens the surah named after it by glorifying the One who did it, which is the whole framing: the journey is Allah's act, not the Prophet's power.")
                .font(.body)

            ScriptureQuote(quran: "17:1")
        }

        Section(header: ArticleHeader("WHAT HE BROUGHT BACK")) {
            Text(verbatim: "He came back with the five daily prayers, which is the reason the night matters to every Muslim after him: the one obligation not delivered by an angel to the earth but given to him above it.")
                .font(.body)

            Text(verbatim: "He also came back with a claim the Quraysh could test. They asked him to describe a city he had never travelled to, and he described it. He said afterwards how he was able to:")
                .font(.body)

            ScriptureQuote(hadith: "bukhari:4710", cite: "Sahih al-Bukhari 4710",
                           arabic: 35...52, english: 4...44)

            Text(verbatim: "Some of those listening had seen Jerusalem and confirmed the description. He told them too about a caravan on the road and what it was carrying, and it arrived as he said.")
                .font(.body)
        }

        Section(header: ArticleHeader("WHY THE TEST MATTERS")) {
            Text(verbatim: "This is the one sign he was forced to defend in public, on the spot, to people who wanted him discredited. A liar says as little as possible; he answered a demand for verifiable detail about a place he had no way of having seen. When it was put to Abu Bakr he said that if the Prophet said it then it is true, and he was called as-Siddiq, the one who affirms, from that day.")
                .font(.body)
        }
    }
}
#endif
