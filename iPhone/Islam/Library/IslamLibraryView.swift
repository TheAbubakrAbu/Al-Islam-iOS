#if os(iOS)
import SwiftUI

/// The six reading libraries opened as Islamic resources on 2026-11-24 (Abu: "Stories of prophets
/// Islamic resource", "Sahaba, Ahlul Bayt, Salaf Islamic resource", "Refuting religions Islamic resource",
/// "Preservation/Compilation of Quran resource", "Science of Hadiths Islamic resource", "Domino Process
/// proving Islam Islamic resource"), drawn as one screen over their catalog home, the way Proving Islam
/// draws its own: the hero, the chapters numbered straight through their groups, the libraries beside
/// them, and the same search (Topics, Match, Words, Without, Best Match) over every page the library
/// lists.
///
/// A library's chapters are its own pages (the six content files in this folder) and, in the same reading
/// order, the Pillars & Beliefs and Proving Islam pages already written on its subject
/// (`IslamArticleCatalog.members`): Refuting Religions lists Answering Christianity, Science of Hadith
/// lists The Sciences of Hadith. Those rows say where they live and open the page as it is, so nothing is
/// written twice.
struct IslamLibraryView: View {
    let home: IslamArticleHome
    /// An article to push on top of the index as it appears: a result on the Islam tab's root.
    var openArticle: IslamArticleOpenRequest?

    init(home: IslamArticleHome, openArticle: IslamArticleOpenRequest? = nil) {
        self.home = home
        self.openArticle = openArticle
    }

    @Environment(\.appearance) private var appearance

    @State private var searchText = ""
    @State private var barsCollapsed = false
    @State private var scrollTarget: String?
    @StateObject private var search = IslamArticleSearchModel()
    @State private var searchFilters = IslamSearchFilters.remembered()

    private var groups: [IslamArticleGroup] { IslamArticleCatalog.groups(for: home).filter { !$0.entries.isEmpty } }

    var body: some View {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        ScrollViewReader { proxy in
            List {
                Group {
                    if query.isEmpty {
                        ResourceHeroSection(hero)

                        chapterSections

                        relatedSection
                    } else {
                        if searchFilters.shows(.askAI) {
                            AskAISearchSection(query: query)
                        }

                        IslamArticleSearchSections(
                            query: query,
                            homes: [home],
                            contentHits: search.contentHits,
                            isSearching: search.isSearching,
                            onScrollTo: { entry in
                                withAnimation { searchText = "" }
                                scrollTarget = entry.listID
                            },
                            filters: searchFilters,
                            reference: search.reference
                        )
                    }
                }
                .themedListRowBackground()
            }
            .englishArticle()
            .applyConditionalListStyle()
            .autoOpenArticle(openArticle, home: home)
            .islamSearchFilterChrome($searchFilters, isSearching: !query.isEmpty, homes: [home],
                                     kinds: [.scripture, .articles, .passages, .askAI])
            .islamArticleIndexSearch(searchText: $searchText, barsCollapsed: $barsCollapsed,
                                     scrollTarget: scrollTarget, proxy: proxy)
        }
        .navigationTitle(home.title)
        .onAppear {
            IslamArticleSearchModel.prewarm()
            #if DEBUG
            if let seeded = IslamSearchDebug.launchQuery("-librarySearch"), searchText.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { searchText = seeded }
            }
            #endif
        }
        .onChange(of: searchText) { text in
            search.update(query: text, homes: [home], filters: searchFilters)
            if !text.isEmpty { scrollTarget = nil }
        }
        .onChange(of: searchFilters) { filters in
            search.update(query: searchText, homes: [home], filters: filters)
        }
    }

    // MARK: Chapters

    /// The chapters, numbered straight through the groups, so "chapter 9" means one page wherever it
    /// is said.
    @ViewBuilder
    private var chapterSections: some View {
        let groups = groups
        let offsets = groups.indices.map { index in groups[..<index].reduce(0) { $0 + $1.entries.count } }
        ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
            Section(header: SectionPillHeader(title: group.title, count: group.entries.count, icon: group.systemImage)) {
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
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(entry.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        // A prophet's first chapter: his name in Arabic (Abu: "would be nice if each prophet
                        // has the arabi name after").
                        if let arabic = LibraryTags.arabic(for: entry.id) {
                            Spacer(minLength: 6)
                            Text(arabic)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(appearance.accent)
                        }
                    }

                    if let tagline = IslamLibraryTaglines.all[entry.id] {
                        Text(tagline)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Its tags (2026-11-24): a prophet's rank, lineage, book, surah, how often the Quran
                    // names him, who he was sent to and what he is known for; every other chapter's own.
                    let tags = LibraryTags.tags(for: entry.id)
                    if !tags.isEmpty {
                        LibraryTagFlow(tags: tags)
                            .padding(.top, 3)
                    }

                    // A page another resource owns says where it lives: it opens as it is there.
                    if entry.home != home {
                        Text(entry.home.title.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundColor(appearance.accent)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(appearance.accent.opacity(0.14)))
                            .padding(.top, 1)
                    }
                }
            }
            .padding(.vertical, 3)
        }
        .id(entry.listID)
        .islamArticleRowActions(title: entry.title, copyText: nil, onScrollTo: nil)
    }

    // MARK: Beside it

    /// The libraries and pages that carry the subject on: one section, a door each.
    private var relatedSection: some View {
        Section(
            header: Text("ALSO IN THE APP"),
            footer: Text(footer)
        ) {
            ForEach(Array(related.enumerated()), id: \.offset) { _, door in
                ArticleDoorRow(door: door)
            }
        }
    }

    private var related: [ArticleDoor] {
        switch home {
        case .stories: return [.library(.miraclesOfProphets), .article("ProphetsView"), .home(.companions)]
        case .companions: return [.home(.hadithScience), .article("AqeedahMadhabView"), .article("ShiaAnswerView")]
        case .religions: return [.home(.domino), .provingIslam, .library(.propheciesOfProphet)]
        case .preservation: return [.library(.miraclesOfQuran), .article("TafsirView"), .home(.hadithScience)]
        case .hadithScience: return [.home(.companions), .home(.preservation), .library(.sunnahsOfProphet)]
        case .domino: return [.provingIslam, .home(.religions), .article("BecomeMuslimView")]
        default: return []
        }
    }

    private var footer: String {
        let rule = "Every ayah is quoted from the Quran text bundled with the app and every hadith from its collections, sahih or hasan only. Stories and reports the scholars grade weak, and the tales of the People of the Book, are left out."
        switch home {
        case .stories:
            return "Every ayah is quoted from the Quran text bundled with the app and every hadith from its collections, sahih or hasan only. Reports the scholars grade weak are left out or named as weak, and whatever is known only from the People of the Book is labelled Isra’iliyyat where it is told: neither believed nor denied, as the Prophet taught. The counts of each name are found word by word in the app’s Quran text."
        case .domino:
            return "Adapted from the Domino Process dawah workshops: one argument in three sessions, from reality to a Creator, from a Creator to revelation, from revelation to Islam. " + rule
        case .religions:
            return "Each faith is described the way its own followers describe it before it is answered. " + rule
        default:
            return rule
        }
    }

    // MARK: Hero

    private var hero: ResourceHero<AnyView> {
        let rows = groups.reduce(0) { $0 + $1.entries.count }
        switch home {
        case .stories:
            return ResourceHero(
                eyebrow: "QISAS AL-ANBIYA",
                systemImage: "scroll.fill",
                headline: "There was certainly in their stories a lesson for those of understanding.",
                source: "Quran 12:111",
                message: "From the clay of Adam to the seal of the prophets, a chapter for every prophet the Quran names, as the Quran and the sound Sunnah tell it: his name and what it means, his family, the people he was sent to, and every ayah that names him. What is known only from the People of the Book is marked as Isra’iliyyat.",
                stats: [ResourceHeroStat("\(rows)", "chapters"), ResourceHeroStat("25", "prophets named"),
                        ResourceHeroStat("\(groups.count)", "parts")]
            ) { AnyView(ProphetStoriesArt()) }
        case .companions:
            return ResourceHero(
                eyebrow: "THE BEST OF GENERATIONS",
                systemImage: "person.3.fill",
                headline: "Allah is pleased with them and they are pleased with Him.",
                source: "Quran 9:100",
                message: "The Companions who carried the Quran and the Sunnah to us, the household of the Prophet (peace be upon him), and the generations who learned from them: who they were, what they did, and why Ahl as-Sunnah love every one of them.",
                stats: [ResourceHeroStat("\(rows)", "chapters"), ResourceHeroStat("3", "best generations"),
                        ResourceHeroStat("10", "promised Paradise")]
            ) { AnyView(BestGenerationsArt()) }
        case .religions:
            return ResourceHero(
                eyebrow: "ANSWERED WITH WISDOM",
                systemImage: "signpost.right.fill",
                headline: "Say, \u{201C}Produce your proof, if you should be truthful.\u{201D}",
                source: "Quran 2:111",
                message: "The world\u{2019}s faiths and worldviews, each described the way its own followers describe it, then answered from the Quran, the Sunnah and sound reason, the way the Quran itself argues: with wisdom, good counsel and the best of manners.",
                stats: [ResourceHeroStat("\(rows)", "chapters"), ResourceHeroStat("\(groups.count)", "parts"),
                        ResourceHeroStat("1", "straight path")]
            ) { AnyView(StraightPathArt()) }
        case .preservation:
            return ResourceHero(
                eyebrow: "KEPT AS PROMISED",
                systemImage: "lock.doc.fill",
                headline: "Indeed, it is We who sent down the Qur\u{2019}an and indeed, We will be its guardian.",
                source: "Quran 15:9",
                message: "How the Quran came down over twenty-three years, lived in the hearts of the Companions, was written in the Prophet\u{2019}s lifetime, gathered by Abu Bakr, copied by Uthman, dotted and vowelled, and reached us letter by letter, with the critics\u{2019} questions answered.",
                stats: [ResourceHeroStat("\(rows)", "chapters"), ResourceHeroStat("23", "years revealed"),
                        ResourceHeroStat("114", "surahs")]
            ) { AnyView(QuranTwoWaysArt()) }
        case .hadithScience:
            return ResourceHero(
                eyebrow: "MUSTALAH AL-HADITH",
                systemImage: "link",
                headline: "If there comes to you a disobedient one with information, investigate.",
                source: "Quran 49:6",
                message: "The science that weighed every narrator and every chain, so that what the Prophet (peace be upon him) said could be told apart from what was said about him: its terms, its critics, its books, its answer to the forgers, and how to read a grade yourself.",
                stats: [ResourceHeroStat("\(rows)", "chapters"), ResourceHeroStat("5", "conditions of sahih"),
                        ResourceHeroStat("\(groups.count)", "parts")]
            ) { AnyView(SahihConditionsArt()) }
        case .domino:
            return ResourceHero(
                eyebrow: "ONE ARGUMENT, SEVEN DOMINOES",
                systemImage: "rectangle.split.3x1.fill",
                headline: "Indeed, in the creation of the heavens and the earth and the alternation of the night and the day are signs for those of understanding.",
                source: "Quran 3:190",
                message: "Something exists; something exists necessarily; it has will and knowledge; it is one; it has spoken; its word can be tested; and one revelation passes every test. Each domino stands only if the one before it does, and nobody is asked to assume Islam at the start.",
                stats: [ResourceHeroStat("7", "dominoes"), ResourceHeroStat("3", "parts"),
                        ResourceHeroStat("\(rows)", "chapters")]
            ) { AnyView(DominoesArt()) }
        default:
            return ResourceHero(eyebrow: home.title.uppercased(), systemImage: home.systemImage, headline: home.title,
                                message: home.subtitle) { AnyView(EmptyView()) }
        }
    }
}
#endif

/// One line under each chapter in a library's index: the question it answers. Generated with the
/// catalog (gen_catalog.py) from the chapters' own sidecars; the borrowed pages' lines are hand-written.
enum IslamLibraryTaglines {
    // BEGIN LIBRARY TAGLINES
    static let all: [String: String] = [
        "StoryProphetsView": "What a prophet is, how many were sent, and how the Quran speaks to them",
        "StoryIntroView": "Why the Quran retells the prophets, and how this library treats Isra\u{2019}iliyyat",
        "StoryFamilyView": "How the prophets descend from Adam, Nuh and Ibrahim, and the twelve tribes",
        "StoryNationsView": "Who were ‘Ad, Thamud, Madyan, Saba\u{2019} and the rest, where they lived, and how they ended",
        "StoryAdamView": "The first man and first prophet: the names, the tree, the repentance, the covenant",
        "StoryIdrisView": "A man of truth raised to a high station, and what is only Isra\u{2019}iliyyat about him",
        "StoryNuhView": "Nine hundred and fifty years of calling, the ark, the flood and the son who drowned",
        "StoryHudView": "One man against the strongest nation of its age, and a cloud that was not rain",
        "StorySalihView": "The she-camel of Allah, the nine who plotted, and the valley the Prophet crossed in tears",
        "StoryShuaybView": "A nation of traders, a crooked scale, and the orator of the prophets who would not bend",
        "StoryIbrahimView": "The idols, the fire, the king and the scrolls: the life of the friend of Allah",
        "StoryLutView": "Ibrahim\u{2019}s nephew, the towns of Sadum, and the night the angels came to his door",
        "StoryKabahView": "God hears: Zamzam, Jurhum, the sacrifice, the Kaaba and the father of the Arabs",
        "StoryIshaqView": "Sarah laughed, and the son\u{2019}s name means he laughs: Isaac and the glad tidings",
        "StoryYaqubView": "Israel himself: the twelve sons, beautiful patience, and the food he gave up",
        "StoryYusufView": "The only prophet whose whole life one surah tells, from a dream to its fulfilment",
        "StoryAyyubView": "The patient prophet who asked for relief without naming what he wanted",
        "StoryYunusView": "The man of the fish, his call from three darknesses, and the city that believed in time",
        "StoryMusaEarlyView": "How Pharaoh\u{2019}s own house raised the boy Allah would speak to at the fire",
        "StoryMusaPharaohView": "Gentle words, a contest of magicians, nine signs, and a sea that closed over a king",
        "StoryHarunView": "Musa\u{2019}s brother and minister, cleared of the calf, and the measure of Ali\u{2019}s place",
        "StoryWildernessView": "Forty years between the sea and the holy land: the calf, the cow, the manna and Qarun",
        "StoryKhidrView": "A prophet sent to learn: the fish, the ship, the boy, the wall, and is al-Khidr alive?",
        "StoryDawudView": "Jalut slain, the Zabur given, iron softened: the king who ate from his own hands",
        "StorySulaymanView": "The wind, the jinn, an ant and a queen: a kingdom met at every turn with gratitude",
        "StoryIlyasView": "“My God is the Lord”: the messenger who asked his people why they called on Ba‘l",
        "StoryAlyasaView": "Named twice, both times in praise: what is known of Elisha and what is not",
        "StoryDhulKiflView": "The man of the pledge: named among the patient, and what is only reported of him",
        "StoryZakariyyaView": "An old carpenter prays in secret for an heir, and is answered in the mihrab",
        "StoryYahyaView": "A name no one had carried, wisdom as a boy, and five commands in Bayt al-Maqdis",
        "StoryMaryamView": "The only woman the Quran names: vowed before birth, chosen above the women of the worlds",
        "StoryIsaView": "Created by a word, raised alive, and returning: Jesus son of Maryam in the Quran",
        "StoryMuhammadView": "His names, his family, the people he was sent to, and the seal of prophethood",
        "StoryIsraeliyyatView": "Yusha‘, Shamwil, Shith, Danyal and others: who is a prophet, and how we know",
        "CompanionsIntroView": "Who counts as a Companion, why Allah praised them, and how to read their disputes",
        "CompanionAbuBakrView": "The first free man to believe, the second of the two in the cave, the first caliph",
        "CompanionUmarView": "The enemy the Prophet prayed for, whom revelation agreed with and Satan avoided",
        "CompanionUthmanView": "Dhun-Nurayn, of whom the angels were shy, who gave the ummah one written mushaf",
        "CompanionAliView": "The Prophet\u{2019}s cousin and son-in-law: Khaybar, Harun to Musa, Ghadir Khumm, the Khawarij",
        "CompanionTenView": "Ten Companions named in one saying as people of Paradise, and what that asks of us",
        "CompanionKhadijahAishahView": "The first believer and the teacher of the ummah: two Mothers of the Believers",
        "CompanionFatimahView": "The Prophet\u{2019}s daughter and grandsons, the cloak, the peace of 41 AH and Karbala",
        "CompanionUnclesView": "The Prophet\u{2019}s uncles and cousin: who believed, who did not, and why it matters",
        "CompanionFirstBelieversView": "Slaves, strangers and the young: who believed first in Makkah, and what it cost them",
        "CompanionAbuHurayrahView": "Why the most prolific narrator narrated so much, and how the Companions confirmed him",
        "CompanionWomenView": "Believers, emigrants, nurses, teachers and questioners: the women who carried the Sunnah",
        "CompanionTabiunView": "The generation that learned from the Companions, from Uways to Umar ibn Abd al-Aziz",
        "CompanionFourImamsView": "Abu Hanifah, Malik, ash-Shafi‘i and Ahmad: their lives, their methods, their one creed",
        "ReligionsMethodView": "Wisdom, proof and courtesy: the Quran\u{2019}s own method for debating other religions",
        "ReligionsOneView": "Why every prophet taught Islam, and why only the law changed between them",
        "ReligionsPluralismView": "Do all paths lead to God? Pluralism weighed against the Quran and reason",
        "ReligionsSikhismView": "Guru Nanak confessed one Creator; where does that confession lead?",
        "ReligionsZoroastrianismView": "Two spirits, a sacred fire and a bridge of judgment, answered by one Creator",
        "ReligionsEastAsiaView": "Heaven, the Way and the kami: what the sages of China and Japan reached for",
        "ReligionsSecularismView": "Can morality, law and freedom stand without God? Humanism and liberalism examined",
        "ReligionsNewProphetsView": "Three movements claimed a prophet after the Seal; the Prophet answered them all",
        "PreservationStagesView": "Why the Quran came down over twenty-three years, and what came first and last",
        "PreservationMemoryView": "How the Quran was kept by heart, from the Prophet to the reciters of today",
        "PreservationWritingView": "Who wrote the Quran down as it came, on what, and why it was not yet one book",
        "PreservationOrderView": "Who set the order of the ayat and surahs, and why it is not chronological",
        "PreservationScriptView": "How bare letters for the ear became today\u{2019}s mushaf, without changing a letter",
        "PreservationManuscriptsView": "What the earliest Quran manuscripts show about the text, and what they cannot",
        "PreservationNaskhView": "How Allah lifted some rulings and recitations, and why that is no change of mind",
        "PreservationClaimsView": "Ibn Mas‘ud\u{2019}s copy, the eaten sheet, tahrif, al-Hajjaj: each claim read in full",
        "HadithScienceTermsView": "The vocabulary behind every grading note, from marfu‘ to hasan sahih, in real hadiths",
        "HadithScienceBreaksView": "Mu‘allaq, mursal, mu‘dal and tadlis: where a chain can fail, and how it was caught",
        "HadithScienceRijalView": "How every narrator was weighed for honesty and memory, ranked, and written into books",
        "HadithScienceAhadView": "Does a sound hadith from one narrator bind in creed? The Salaf against the kalam schools",
        "HadithScienceFabricationView": "Why men forged hadiths, how the critics caught them, and sayings that are not his",
        "HadithScienceQudsiView": "When the Prophet relates his Lord\u{2019}s words: what a hadith qudsi is, and what it is not",
        "HadithScienceGradesView": "What “graded sahih by al-Albani” means, and why careful graders sometimes differ",
        "HadithScienceOrientalistsView": "Did the hadith grow out of later disputes? The sceptics\u{2019} case, and how it was answered",
        "DominoIntroView": "Seven steps from the fact that anything exists to the testimony of faith",
        "DominoRealityView": "Why does anything exist? Contingency, the borrowed book and the Necessary Being",
        "DominoCreatorView": "Blind force or One who chooses? Will, chance, fine-tuning and the minds that ask",
        "DominoOneView": "Why there cannot be two gods, and why one Creator is not yet Islam",
        "DominoWorldviewsView": "Three places people stop, stated fairly and answered, ending on: did God speak?",
        "DominoRevelationView": "If a wise Creator made beings who ask why, would He stay silent?",
        "DominoTestView": "Six fair questions for any revelation, put to every major religion",
        "DominoChristianityView": "The Trinity, the Bible and the cross, stated fairly and weighed",
        "DominoIslamView": "The last claimant faces the same bar, and the chain ends in the shahadah",
        "DominoDawahView": "Lines that survive a well-read opponent, and the manners of inviting to Allah",
        "SeerahView": "His life from Makkah to Madinah, in outline",
        "ProphetMuhammadView": "The seal of the prophets, as Allah describes him",
        "SahabahView": "An overview of the Companions and what they left",
        "AhlusSunnahView": "Who Ahl as-Sunnah wal-Jama\u{2019}ah are, and why the name",
        "CaliphatesView": "From the Rightly Guided to the Ottomans, in outline",
        "AhlulBaytView": "Who the Prophet\u{2019}s household are, and the balanced position",
        "WivesView": "The Mothers of the Believers, and why he married each",
        "SahabahScholarsView": "Ibn Abbas, Ibn Mas\u{2019}ud, A\u{2019}ishah and the first teachers",
        "SalafScholarsView": "The Tabi\u{2019}un and the imams of fiqh and hadith, briefly",
        "SalafiyyahView": "Following the way of the first three generations",
        "ChristianityAnswerView": "Jesus, the Trinity and the cross, answered from the Quran",
        "JudaismAnswerView": "The covenant, the later prophets and the final messenger",
        "HinduismAnswerView": "One Creator without image, and resurrection, not rebirth",
        "BuddhismAnswerView": "A Maker, a purpose, and salvation by mercy",
        "AtheismAnswerView": "The argument that shook a heart, and the fitrah",
        "PaganismAnswerView": "They admitted the Creator, so why worship another?",
        "ShiaAnswerView": "The Companions, the imamate and the Mother of the Believers",
        "SufismAnswerView": "Closeness to Allah through what He legislated",
        "HadithRejectorsView": "Why the Quran itself commands following the Sunnah",
        "QuranRevealedPillarView": "How the Quran shows it is from Allah, then the hadith",
        "CompileView": "Abu Bakr\u{2019}s collection and Uthman\u{2019}s copies",
        "AhrufView": "The seven modes the Quran was revealed in",
        "QiraatView": "The ten canonical recitations and their chains",
        "QiraatContradictView": "Readings that add meaning and never contradict",
        "ProvingPreservationView": "A promise made by a persecuted few, kept for fourteen centuries",
        "HadithPillarView": "What a hadith is, and the scale of grades",
        "HadithSciencesView": "The chain, the text and the five conditions of sahih",
        "HadithPreservationView": "Written, memorised, travelled for and compiled",
    ]
    // END LIBRARY TAGLINES
}
