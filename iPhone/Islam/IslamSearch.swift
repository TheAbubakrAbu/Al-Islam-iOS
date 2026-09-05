import SwiftUI

// Search across the Islam tab's ARTICLES: the Pillars & Beliefs pages and the How-to guides.
//
// Three screens search them - the Islam tab root (everything at once, alongside the resources), the
// Pillars & Beliefs index and the How-to Guides index - and all three draw from the two pieces here:
//
//   * `IslamArticleCatalog` is the ONE list of articles: which list section each sits in, its row
//     title, its debug key, and the view type that opens it. The two index screens render their rows
//     from it, so a search result can always say which section an article lives in, and adding an
//     article is one entry (plus its `IslamArticles.destination` case, which the corpus verifier
//     checks).
//   * `IslamArticleSearch` matches a query two ways. TITLE hits are the index rows themselves (the
//     row title, its section name, a few aliases like "wudu" for "Wudhu"). CONTENT hits come from the
//     article prose in `IslamArticles` (the pack the Ask AI chat reads): each hit is one SECTION of
//     one article, shown with the article's title and the section heading it matched in, and
//     opening it lands on that section.
//
// Result rows carry the Quran list's grammar: a context menu and a trailing swipe that clears the
// search and scrolls the index back to the article's own row ("Scroll To Article").

// MARK: - Catalog

enum IslamArticleHome: String, Hashable, CaseIterable {
    case pillars
    case guides

    /// The resource's title, as the Islam tab prints it.
    var title: String {
        switch self {
        case .pillars: return "Pillars & Beliefs"
        case .guides: return "How-To Guides"
        }
    }

    var systemImage: String {
        switch self {
        case .pillars: return "moon.stars"
        case .guides: return "list.bullet.rectangle"
        }
    }
}

struct IslamArticleEntry: Identifiable, Hashable {
    /// The article view's type name, e.g. "WudhuView" - the id `IslamArticles` uses too, so a content
    /// hit maps straight back to its index row.
    let id: String
    /// The row title, exactly as the index prints it.
    let title: String
    /// The index section the row sits in ("THE 5 PILLARS OF ISLAM").
    let group: String
    let home: IslamArticleHome
    /// The `-pillarsArticle` / `-guidesArticle` DEBUG launch-argument key.
    let debugKey: String
    /// THE BASICS rows are set larger and in the accent, the way the index has always drawn them.
    var emphasized: Bool = false
    /// Spellings the row title does not carry but a searcher will type ("wudu", "ablution").
    var aliases: [String] = []

    /// The row id in the index list, the target of "Scroll To Article".
    var listID: String { "article_\(id)" }
}

struct IslamArticleGroup: Identifiable {
    let title: String
    let home: IslamArticleHome
    let entries: [IslamArticleEntry]

    var id: String { "\(home.rawValue)/\(title)" }
}

enum IslamArticleCatalog {
    private static func entry(_ id: String, _ title: String, _ group: String, _ home: IslamArticleHome,
                              key: String, emphasized: Bool = false, aliases: [String] = []) -> IslamArticleEntry {
        IslamArticleEntry(id: id, title: title, group: group, home: home, debugKey: key,
                          emphasized: emphasized, aliases: aliases)
    }

    private static func group(_ title: String, _ home: IslamArticleHome,
                              _ rows: [(id: String, title: String, key: String, aliases: [String])],
                              emphasized: Bool = false) -> IslamArticleGroup {
        IslamArticleGroup(title: title, home: home, entries: rows.map {
            entry($0.id, $0.title, title, home, key: $0.key, emphasized: emphasized, aliases: $0.aliases)
        })
    }

    /// Pillars & Beliefs, in the order the index shows them.
    static let pillarsGroups: [IslamArticleGroup] = [
        group("THE BASICS", .pillars, [
            ("GodPillarView", "Does God Exist?", "god", ["existence", "atheism", "creator"]),
            ("IslamPillarView", "What is Islam?", "islam", ["religion", "submission"]),
            ("MuslimPillarView", "What is a Muslim?", "muslim", ["believer", "mumin"]),
            ("AllahPillarView", "Who is Allah \u{FDFB}\u{200E}?", "allah", ["god", "allah"]),
            ("QuranPillarView", "What is the Quran?", "quran", ["koran", "book", "revelation"]),
            ("ProphetPillarView", "Who is Prophet Muhammad \u{FDFA}?", "prophet", ["messenger", "rasul", "muhammad"]),
            ("SunnahPillarView", "What is the Sunnah?", "sunnah", ["tradition", "way of the prophet"]),
            ("HadithPillarView", "What are Hadiths?", "hadith", ["narration", "ahadith", "bukhari", "muslim"]),
        ], emphasized: true),
        group("THE 5 PILLARS OF ISLAM", .pillars, [
            ("ShahadahView", "Shahadah (Testimony of Faith)", "shahadah", ["shahada", "testimony", "declaration"]),
            ("SalahView", "Salah (Five Daily Prayers)", "salah", ["salat", "prayer", "namaz"]),
            ("SawmView", "Sawm (Fasting in Ramadan)", "sawm", ["fasting", "fast", "ramadan", "siyam"]),
            ("ZakahView", "Zakah (Annual Charity)", "zakah", ["zakat", "charity", "alms"]),
            ("HajjView", "Hajj (Pilgrimage to Makkah)", "hajj", ["pilgrimage", "mecca", "kaaba"]),
        ]),
        group("THE 6 PILLARS OF IMAN (FAITH)", .pillars, [
            ("GodView", "Belief in Allah", "belief-allah", ["iman", "tawhid", "god"]),
            ("AngelsView", "Belief in the Angels", "angels", ["angel", "jibril", "gabriel", "malaikah"]),
            ("BooksView", "Belief in the Books", "books", ["scripture", "torah", "gospel", "psalms", "injil", "tawrah"]),
            ("ProphetsView", "Belief in the Prophets", "prophets", ["messengers", "anbiya", "rusul"]),
            ("DayView", "Belief in the Last Day", "lastday", ["judgement", "judgment", "resurrection", "qiyamah", "afterlife", "paradise", "hell"]),
            ("QadarView", "Belief in Al-Qadar", "qadar", ["qadr", "destiny", "predestination", "decree", "fate"]),
        ]),
        group("THE THREE HOLY MOSQUES", .pillars, [
            ("HaramView", "Masjid Al-Haram (The Holy Mosque)", "haram", ["makkah", "mecca", "kaaba", "kabah"]),
            ("NabawiView", "Masjid An-Nabawi (The Prophet\u{2019}s Mosque)", "nabawi", ["madinah", "medina", "prophet's mosque"]),
            ("AqsaView", "Masjid Al-Aqsa (The Farthest Mosque)", "aqsa", ["jerusalem", "quds", "palestine", "isra"]),
        ]),
        group("QURAN & TAFSIR", .pillars, [
            ("CompileView", "Compilation of the Quran", "compile", ["preservation", "uthman", "abu bakr", "mushaf"]),
            ("TafsirView", "Tafsir (Exegesis)", "tafsir", ["commentary", "interpretation", "ibn kathir"]),
            ("TajweedView", "Tajweed", "tajweed", ["recitation rules", "pronunciation"]),
            ("MuqattaatPillarView", "Muqatta\u{2019}at Letters", "muqattaat", ["muqattaat", "alif lam mim", "disjointed letters", "fawatih"]),
            ("JuzView", "The 30 Juz (Parts)", "juz", ["ajza", "para", "hizb", "parts of the quran"]),
            ("AhrufView", "The 7 Ahruf (Modes)", "ahruf", ["harf", "modes", "seven ahruf"]),
            ("QiraatView", "The 10 Qiraat (Recitations)", "qiraat", ["qiraah", "riwayah", "hafs", "warsh", "readings"]),
        ]),
        group("THE ISLAMIC CALENDAR", .pillars, [
            ("HijriCalendarView", "Hijri Calendar", "hijri", ["islamic calendar", "lunar", "months", "muharram", "ramadan"]),
        ]),
        group("HISTORICAL & BIOGRAPHICAL", .pillars, [
            ("SeerahView", "The Seerah (Biography)", "seerah", ["sirah", "biography", "life of the prophet", "hijrah", "badr"]),
            ("FarewellView", "The Farewell (Final) Sermon", "farewell", ["khutbah", "arafah", "last sermon"]),
            ("AhlulBaytView", "The Ahlul Bayt (People of the House)", "ahlulbayt", ["ahl al-bayt", "fatimah", "ali", "hasan", "husayn", "family of the prophet"]),
            ("WivesView", "The Wives of the Prophet", "wives", ["khadijah", "aisha", "aishah", "mothers of the believers", "ummahat"]),
            ("SahabahView", "The Sahabah (Companions)", "sahabah", ["companions", "abu bakr", "umar", "uthman", "ali"]),
            ("CaliphatesView", "The Caliphates", "caliphates", ["khilafah", "caliph", "rashidun", "umayyad", "abbasid", "ottoman"]),
            ("MadhabView", "The Madhahib of Fiqh (Schools of Law)", "madhab", ["madhhab", "hanafi", "maliki", "shafii", "hanbali", "fiqh", "jurisprudence"]),
            ("AqeedahMadhabView", "The Madhahib of Aqeedah (Schools of Creed)", "aqeedah", ["aqidah", "creed", "athari", "ashari", "maturidi", "theology"]),
            ("AhlusSunnahView", "Ahl As-Sunnah Wal Jama\u{2019}ah", "ahlussunnah", ["ahlus sunnah", "sunni", "jamaah", "saved sect"]),
            ("FiqhAqeedahManhajView", "Fiqh, Aqeedah, and Manhaj", "manhaj", ["methodology", "fiqh", "creed"]),
        ]),
        group("SCHOLARS OF AHL AS-SUNNAH", .pillars, [
            ("SahabahScholarsView", "The Scholars of the Sahabah", "sahabah-scholars", ["ibn abbas", "ibn masud", "ibn umar", "aishah", "zayd"]),
            ("SalafScholarsView", "The Salaf and the Imams", "salaf", ["abu hanifah", "malik", "shafii", "ahmad", "imams", "tabiun"]),
            ("TabariView", "Ibn Jarir at-Tabari", "tabari", ["tabari", "history", "tafsir"]),
            ("IbnTaymiyyahView", "Shaykh al-Islam Ibn Taymiyyah", "ibntaymiyyah", ["ibn taymiyya", "taymiyyah", "shaykh al islam"]),
            ("IbnQayyimView", "Ibn al-Qayyim", "ibnqayyim", ["ibn qayyim", "jawziyyah"]),
            ("DhahabiView", "Adh-Dhahabi", "dhahabi", ["dhahabi", "siyar"]),
            ("IbnKathirView", "Ibn Kathir", "ibnkathir", ["ibn kathir", "tafsir", "bidayah"]),
            ("LaterScholarsView", "Later Scholars of the Sunnah", "later", ["ibn hajar", "nawawi", "albani", "ibn baz", "ibn uthaymin", "muhammad ibn abd al-wahhab"]),
        ]),
        group("SALAFIYYAH: THE WAY OF THE SALAF", .pillars, [
            ("TawhidView", "Tawhid: The Oneness of Allah", "tawhid", ["tawheed", "oneness", "monotheism", "la ilaha illa allah"]),
            ("SalafiyyahView", "What is Salafiyyah?", "salafiyyah", ["salafi", "salafism", "wahhabi", "najd", "ibn abd al-wahhab"]),
            ("QuranSunnahView", "The Quran and the Sunnah", "quransunnah", ["two sources", "revelation", "evidence", "daleel"]),
            ("ShirkView", "Shirk: The Unforgivable Sin", "shirk", ["polytheism", "idolatry", "associating partners", "grave worship"]),
            ("KufrView", "Kufr and What Breaks Islam", "kufr", ["disbelief", "apostasy", "nullifiers", "riddah", "takfir"]),
            ("BidahView", "Bid\u{2019}ah (Innovation)", "bidah", ["bidah", "innovation", "newly invented"]),
            ("MawlidView", "The Mawlid", "mawlid", ["birthday", "milad", "rabi al-awwal", "celebration"]),
        ]),
        group("ANSWERING OTHER PATHS", .pillars, [
            ("SufismAnswerView", "Answering Sufism", "sufism", ["sufi", "tasawwuf", "tariqah", "dervish"]),
            ("ShiaAnswerView", "Answering the Shia", "shia", ["shiah", "shiism", "rafidah", "twelver", "imamah"]),
            ("ChristianityAnswerView", "Answering Christianity", "christianity", ["christian", "trinity", "jesus", "bible", "crucifixion"]),
            ("JudaismAnswerView", "Answering Judaism", "judaism", ["jewish", "jews", "torah", "talmud", "israel"]),
            ("HinduismAnswerView", "Answering Hinduism", "hinduism", ["hindu", "vedas", "brahman", "karma", "reincarnation"]),
            ("PaganismAnswerView", "Answering Paganism", "paganism", ["pagan", "idols", "polytheism", "shamanism", "witchcraft"]),
            ("BuddhismAnswerView", "Answering Buddhism", "buddhism", ["buddha", "buddhist", "nirvana", "dharma"]),
            ("AtheismAnswerView", "Answering Atheism", "atheism", ["atheist", "agnostic", "secular", "evolution", "science"]),
        ]),
    ]

    /// How-to guides, in the order the index shows them.
    static let guidesGroups: [IslamArticleGroup] = [
        group("HOW TO WORSHIP", .guides, [
            ("HowToPrayView", "How to Pray (Salah)", "pray", ["salat", "prayer", "namaz", "rakah", "ruku", "sujud"]),
            ("HowToFastView", "How to Fast (Sawm)", "fast", ["fasting", "ramadan", "suhoor", "iftar", "siyam"]),
            ("HowToZakahView", "How to Give Zakah", "zakah", ["zakat", "charity", "nisab", "2.5"]),
            ("HowToHajjView", "How to Perform Hajj", "hajj", ["pilgrimage", "ihram", "tawaf", "arafah", "mina"]),
            ("HowToUmrahView", "How to Perform Umrah", "umrah", ["minor pilgrimage", "ihram", "tawaf", "sai"]),
        ]),
        group("PURIFICATION & PRAYER", .guides, [
            ("WudhuView", "How to Make Wudhu", "wudhu", ["wudu", "ablution", "purification", "washing"]),
            ("GhuslView", "How to Make Ghusl", "ghusl", ["bath", "full ablution", "janabah", "ritual bath"]),
            ("TayammumView", "How to Make Tayammum", "tayammum", ["dry ablution", "no water", "earth", "dust", "sand"]),
            ("JumuahView", "How to Pray Jumuah", "jumuah", ["friday prayer", "jummah", "khutbah"]),
            ("AdhanOtherView", "How to Give the Adhan", "adhan", ["azan", "call to prayer", "muadhin"]),
            ("IqamahView", "How to Give the Iqamah", "iqamah", ["iqama", "second call"]),
        ]),
        group("MORE PRAYERS", .guides, [
            ("RawatibView", "How to Pray the Sunnah Prayers", "rawatib", ["rawatib", "nawafil", "voluntary", "twelve rakah", "before fajr"]),
            ("WitrView", "How to Pray Witr", "witr", ["qunut", "odd", "night", "last prayer"]),
            ("TahajjudView", "How to Pray Tahajjud", "tahajjud", ["night prayer", "qiyam", "qiyam al-layl", "last third"]),
            ("DuhaView", "How to Pray Duha", "duha", ["forenoon", "ishraq", "morning prayer", "chasht"]),
            ("TaraweehView", "How to Pray Taraweeh", "taraweeh", ["tarawih", "ramadan night", "qiyam"]),
            ("JanazahView", "How to Pray the Funeral Prayer", "janazah", ["janaza", "funeral", "death", "burial", "shroud", "kafan", "deceased"]),
            ("IstikharahView", "How to Pray Istikharah", "istikharah", ["istikhara", "decision", "guidance prayer", "choice"]),
        ]),
        group("PRAYER IN SPECIAL CASES", .guides, [
            ("TravelPrayerView", "How to Pray While Traveling", "travel", ["traveler", "qasr", "shorten", "combine", "jam", "journey", "plane"]),
            ("SickPrayerView", "How to Pray When Sick", "sick", ["illness", "sitting", "chair", "lying down", "hospital", "disabled"]),
            ("MissedPrayerView", "How to Make Up Missed Prayers", "missed", ["qada", "make up", "forgot", "slept", "overslept"]),
            ("SujudSahwView", "How to Perform Sujud as-Sahw", "sahw", ["sujud sahw", "forgetfulness", "prostration of forgetfulness", "doubt", "mistake in prayer"]),
        ]),
        group("FASTING & CHARITY", .guides, [
            ("VoluntaryFastsView", "How to Fast Voluntary Fasts", "voluntary-fasts", ["monday", "thursday", "shawwal", "arafah", "ashura", "white days", "ayyam al-bid", "nafl fast"]),
            ("ItikafView", "How to Perform I'tikaf", "itikaf", ["itikaf", "seclusion", "last ten nights", "laylat al-qadr", "mosque retreat"]),
            ("ZakatFitrView", "How to Give Zakat al-Fitr", "zakat-fitr", ["fitrah", "fitra", "sadaqat al-fitr", "eid charity", "sa"]),
        ]),
        group("EID", .guides, [
            ("TakbiratView", "How to Pray Eid", "eid", ["eid prayer", "takbir", "takbirat", "eid al-fitr", "eid al-adha"]),
            ("UdhiyahView", "How to Offer the Eid Sacrifice", "udhiyah", ["udhiya", "qurbani", "sacrifice", "slaughter", "sheep", "eid al-adha"]),
        ]),
        group("FAITH & THE HEART", .guides, [
            ("BecomeMuslimView", "How to Become a Muslim", "become-muslim", ["convert", "revert", "shahadah", "shahada", "embrace islam", "new muslim"]),
            ("TawbahView", "How to Repent", "tawbah", ["tawba", "repentance", "forgiveness", "istighfar", "sin"]),
            ("MakeDuaView", "How to Make Dua", "dua", ["supplication", "prayer", "ask allah", "etiquette", "times of answer"]),
        ]),
    ]

    static func groups(for home: IslamArticleHome) -> [IslamArticleGroup] {
        switch home {
        case .pillars: return pillarsGroups
        case .guides: return guidesGroups
        }
    }

    static let all: [IslamArticleEntry] = (pillarsGroups + guidesGroups).flatMap(\.entries)

    static let byID: [String: IslamArticleEntry] = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

    /// Index position per article id (result order) and the folded title+group+aliases haystack per
    /// id: both used to be rebuilt on every keystroke (Performance Guide, Phase 6 step 10).
    static let order: [String: Int] = Dictionary(all.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { a, _ in a })
    static let foldedHaystacks: [String: String] = Dictionary(
        all.map { ($0.id, IslamArticles.fold(([$0.title, $0.group] + $0.aliases).joined(separator: " "))) },
        uniquingKeysWith: { a, _ in a }
    )

    /// The `-pillarsArticle` / `-guidesArticle` dictionaries, built from the catalog instead of by hand.
    @MainActor
    static func debugArticles(for home: IslamArticleHome) -> [String: AnyView] {
        var out: [String: AnyView] = [:]
        for entry in groups(for: home).flatMap(\.entries) {
            if let view = IslamArticles.destination(for: entry.id) { out[entry.debugKey] = view }
        }
        return out
    }

    /// The article page. With a `section`, the page scrolls to that heading as it appears (see
    /// `ArticleHeader` and `selectableArticleList`).
    @MainActor
    static func destination(_ entry: IslamArticleEntry, section: String? = nil) -> AnyView {
        destination(id: entry.id, section: section)
    }

    @MainActor
    static func destination(id: String, section: String? = nil) -> AnyView {
        guard let view = IslamArticles.destination(for: id) else {
            return AnyView(Text("Article not found").foregroundColor(.secondary))
        }
        if let section, !section.isEmpty {
            return AnyView(view.environment(\.articleScrollTarget, section))
        }
        return view
    }
}

// MARK: - Index rows

/// The index screens' sections, drawn from the catalog: one `Section` per group, one navigation row per
/// article. THE BASICS rows keep their larger accent title; every other row is a subheadline.
struct IslamArticleIndexSections: View {
    @Environment(\.appearance) private var appearance

    let groups: [IslamArticleGroup]

    var body: some View {
        ForEach(groups) { group in
            Section(header: Text(group.title)) {
                ForEach(group.entries) { entry in
                    row(entry)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ entry: IslamArticleEntry) -> some View {
        let link = NavigationLink(destination: LazyDestination { IslamArticleCatalog.destination(entry) }) {
            if entry.emphasized {
                Text(entry.title)
                    .foregroundColor(appearance.accent)
                    .font(.headline)
            } else {
                Text(entry.title)
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
        .id(entry.listID)

        #if os(iOS)
        link.islamArticleRowActions(title: entry.title, copyText: nil, onScrollTo: nil)
        #else
        link
        #endif
    }
}

// MARK: - Section anchors

/// A section header inside an article that a search result can scroll to. Every article section is
/// `Section(header: ArticleHeader("HEADING"))`: the same `Text` the pages always drew, with an id
/// the page's `ScrollViewReader` (installed by `selectableArticleList`) can find. The corpus builder
/// reads these headings too (build_islam_corpus.py's SECTION_RE), so the heading a search result
/// names is the heading the page scrolls to.
struct ArticleHeader: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .id(Self.anchorID(title))
    }

    static func anchorID(_ heading: String) -> String { "articleSection_\(heading)" }
}

/// One block of article prose, as data. The largest articles (Phase 6 step 3 of the Performance Guide)
/// keep their sections in a `static let [ArticleSection]` rendered by `ArticleSectionsView`, so the List
/// gets a keyed `ForEach` tree whose rows are built as they scroll in, instead of a 200-leaf static
/// tuple that SwiftUI materialises in full when the page opens. The spellings are fixed: the corpus
/// builder (Scripts/build_islam_corpus.py) and the quote audit (Scripts/audit_islam_quotes.py) read
/// `.text(`, `.markdown(`, `.quote(text:` and `ArticleSection("HEADING"` straight out of the source.
enum ArticleBlock {
    /// Plain prose, drawn with `Text(verbatim:)`.
    case text(String)
    /// Prose with inline **bold** terms, drawn through `Text(articleMarkdown:)`.
    case markdown(String)
    /// A `ScriptureQuote`, same arguments.
    case quote(text: String, arabic: String? = nil, dimmed: Bool = false)
}

struct ArticleSection {
    let heading: String
    let blocks: [ArticleBlock]

    init(_ heading: String, _ blocks: [ArticleBlock]) {
        self.heading = heading
        self.blocks = blocks
    }
}

/// The sections of a data-backed article: one `Section(header: ArticleHeader(...))` each, the same
/// anchors a search result scrolls to, one row per block.
struct ArticleSectionsView: View {
    let sections: [ArticleSection]

    var body: some View {
        ForEach(sections.indices, id: \.self) { index in
            let section = sections[index]
            Section(header: ArticleHeader(section.heading)) {
                ForEach(section.blocks.indices, id: \.self) { blockIndex in
                    ArticleBlockView(block: section.blocks[blockIndex])
                }
            }
        }
    }
}

struct ArticleBlockView: View {
    let block: ArticleBlock

    var body: some View {
        switch block {
        case .text(let prose):
            Text(verbatim: prose)
                .font(.body)
        case .markdown(let prose):
            Text(articleMarkdown: prose)
                .font(.body)
        case .quote(let text, let arabic, let dimmed):
            ScriptureQuote(text: text, arabic: arabic, dimmed: dimmed)
        }
    }
}

extension Text {
    /// Article prose with inline markdown (the **bold** key terms). `Text("...")` takes a
    /// `LocalizedStringKey`, which looks the literal up in a strings table and parses its markdown
    /// every time the text resolves; the app has no strings table, and an article carries up to 270
    /// such literals. This parses once per literal into a process-wide cache. Plain literals are
    /// spelled `Text(verbatim:)` in the article files for the same reason (no lookup, no parse).
    init(articleMarkdown: String) {
        self.init(ArticleMarkdownCache.attributed(articleMarkdown))
    }
}

enum ArticleMarkdownCache {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var cache: [String: AttributedString] = [:]

    static func attributed(_ markdown: String) -> AttributedString {
        lock.lock(); defer { lock.unlock() }
        if let hit = cache[markdown] { return hit }
        // The same inline-only grammar `LocalizedStringKey` uses, so nothing renders differently.
        let parsed = (try? AttributedString(
            markdown: markdown,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(markdown)
        cache[markdown] = parsed
        return parsed
    }
}

private struct ArticleScrollTargetKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

extension EnvironmentValues {
    /// The section heading an article page should scroll to as it appears - set by a search result,
    /// nil for a page opened from its index row.
    var articleScrollTarget: String? {
        get { self[ArticleScrollTargetKey.self] }
        set { self[ArticleScrollTargetKey.self] = newValue }
    }
}

// MARK: - Search

enum IslamArticleSearch {
    /// One section of one article that contains the query.
    struct ContentHit: Identifiable, Equatable {
        let article: IslamArticle
        let section: IslamArticle.Section
        let sectionIndex: Int
        /// A window of the section's prose around the first match, ready to display.
        let snippet: String

        var id: String { "\(article.id)#\(sectionIndex)" }
        var entry: IslamArticleEntry? { IslamArticleCatalog.byID[article.id] }
        var home: IslamArticleHome? { entry?.home }

        static func == (l: Self, r: Self) -> Bool { l.id == r.id && l.snippet == r.snippet }
    }

    /// Non-overlapping occurrences of `term` in `haystack`, without the array `components(separatedBy:)`
    /// allocated per term per section (~1,000 sections per keystroke).
    static func occurrences(of term: String, in haystack: String) -> Int {
        var count = 0
        var start = haystack.startIndex
        while start < haystack.endIndex, let range = haystack.range(of: term, range: start..<haystack.endIndex) {
            count += 1
            start = range.upperBound
        }
        return count
    }

    /// The folded query words: lowercased, punctuation flattened, empties dropped.
    static func words(_ query: String) -> [String] {
        IslamArticles.fold(query).split(separator: " ").map(String.init).filter { !$0.isEmpty }
    }

    /// Index rows whose title, section name or aliases carry EVERY word of the query.
    static func titleHits(_ query: String, homes: Set<IslamArticleHome>) -> [IslamArticleEntry] {
        let terms = words(query)
        guard !terms.isEmpty else { return [] }
        return IslamArticleCatalog.all.filter { entry in
            guard homes.contains(entry.home), let haystack = IslamArticleCatalog.foldedHaystacks[entry.id] else { return false }
            return terms.allSatisfy { haystack.contains($0) }
        }
    }

    /// Sections whose prose carries every word of the query, in the index's order, at most
    /// `perArticle` sections per article (the ones with the most hits) and `limit` in all.
    ///
    /// Reads `IslamArticles.all`, which inflates the article pack on first use - call this off the
    /// main actor (`IslamArticleSearchModel` does).
    static func contentHits(_ query: String, homes: Set<IslamArticleHome>,
                            perArticle: Int = 3, limit: Int = 60) -> [ContentHit] {
        let terms = words(query)
        guard !terms.isEmpty else { return [] }
        // Index order, so the results read top to bottom like the list they came from.
        let order = IslamArticleCatalog.order
        let articles = IslamArticles.all
            .filter { article in
                guard let entry = IslamArticleCatalog.byID[article.id] else { return false }
                return homes.contains(entry.home)
            }
            .sorted { (order[$0.id] ?? .max) < (order[$1.id] ?? .max) }

        var hits: [ContentHit] = []
        for article in articles {
            // A newer keystroke has already replaced this search: stop walking 93 articles for it.
            if Task.isCancelled { return hits }
            var scored: [(index: Int, count: Int)] = []
            for (index, section) in article.sections.enumerated() {
                var total = 0
                var all = true
                for term in terms {
                    let count = occurrences(of: term, in: section.folded)
                    if count == 0 { all = false; break }
                    total += count
                }
                if all { scored.append((index, total)) }
            }
            guard !scored.isEmpty else { continue }
            let picked = scored.sorted { $0.count > $1.count }.prefix(perArticle).sorted { $0.index < $1.index }
            for pick in picked {
                let section = article.sections[pick.index]
                hits.append(ContentHit(article: article, section: section, sectionIndex: pick.index,
                                       snippet: snippet(of: section.text, around: query, terms: terms)))
                if hits.count >= limit { return hits }
            }
        }
        return hits
    }

    /// A window of `text` around the first occurrence of the query (or of its first word), cut at
    /// word boundaries with ellipses, so the row shows the match in context rather than the section's
    /// opening line.
    static func snippet(of text: String, around query: String, terms: [String], radius: Int = 110) -> String {
        let flat = text.replacingOccurrences(of: "\n", with: " ")
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        var match = flat.range(of: query.trimmingCharacters(in: .whitespacesAndNewlines), options: options)
        if match == nil {
            for term in terms {
                if let r = flat.range(of: term, options: options) { match = r; break }
            }
        }
        guard let match else {
            return flat.count > radius * 2 ? String(flat.prefix(radius * 2)).trimmingCharacters(in: .whitespaces) + "\u{2026}" : flat
        }

        var start = match.lowerBound
        var steps = 0
        while start > flat.startIndex, steps < radius {
            start = flat.index(before: start); steps += 1
        }
        var end = match.upperBound
        steps = 0
        while end < flat.endIndex, steps < radius {
            end = flat.index(after: end); steps += 1
        }
        // Snap to word boundaries, so the window never opens or closes mid-word.
        if start > flat.startIndex, let space = flat[start...].firstIndex(of: " "), space < match.lowerBound {
            start = flat.index(after: space)
        }
        if end < flat.endIndex, let space = flat[..<end].lastIndex(of: " "), space > match.upperBound {
            end = space
        }
        var out = String(flat[start..<end]).trimmingCharacters(in: .whitespaces)
        if start > flat.startIndex { out = "\u{2026}" + out }
        if end < flat.endIndex { out += "\u{2026}" }
        return out
    }
}

#if os(iOS)
/// The live content search for one screen: debounced, computed off the main actor (the article pack
/// inflates on first use), delivered as `@Published` hits. Title hits are cheap and computed inline by
/// the screen; only the prose scan goes through here.
@MainActor
final class IslamArticleSearchModel: ObservableObject {
    @Published private(set) var contentHits: [IslamArticleSearch.ContentHit] = []
    /// True between a query change and its results landing, so the screen can hold "no matches"
    /// until the scan has actually run.
    @Published private(set) var isSearching = false

    private var task: Task<Void, Never>?

    /// Inflate the pack ahead of the first keystroke. Cheap to call repeatedly.
    nonisolated static func prewarm() {
        Task.detached(priority: .utility) { _ = IslamArticles.all }
    }

    func update(query: String, homes: Set<IslamArticleHome>) {
        task?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            if !contentHits.isEmpty { contentHits = [] }
            isSearching = false
            return
        }
        isSearching = true
        task = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 180_000_000)
            guard !Task.isCancelled else { return }
            let hits = await Task.detached(priority: .userInitiated) {
                IslamArticleSearch.contentHits(trimmed, homes: homes)
            }.value
            guard !Task.isCancelled else { return }
            self?.contentHits = hits
            self?.isSearching = false
        }
    }
}

// MARK: - Result rows

/// An index row as a search result: the title with the match coloured, and beneath it the section it
/// lives in (and, when several resources are searched at once, which resource).
struct IslamArticleTitleRow: View {
    @Environment(\.appearance) private var appearance

    let entry: IslamArticleEntry
    let query: String
    var showHome: Bool = false
    var scrollLabel: String = "Scroll To Article"
    /// Clears the search and scrolls the index to this article's row. Nil = no such row on this screen.
    var onScrollTo: (() -> Void)? = nil

    private var caption: String {
        showHome ? "\(entry.home.title) \u{203A} \(entry.group)" : entry.group
    }

    var body: some View {
        NavigationLink(destination: LazyDestination { IslamArticleCatalog.destination(entry) }) {
            VStack(alignment: .leading, spacing: 3) {
                HighlightedSnippet(
                    source: entry.title,
                    term: query,
                    font: entry.emphasized ? .headline : .subheadline,
                    accent: appearance.accent,
                    fg: entry.emphasized ? appearance.accent : .primary
                )

                Text(caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 4)
        }
        .id(entry.listID)
        .islamArticleRowActions(title: entry.title, copyText: nil, scrollLabel: scrollLabel, onScrollTo: onScrollTo)
    }
}

/// A passage that matched: "Article \u{203A} SECTION" in the accent, then the prose around the match.
/// Opens the article scrolled to that section.
struct IslamArticleContentRow: View {
    @Environment(\.appearance) private var appearance

    let hit: IslamArticleSearch.ContentHit
    let query: String
    var showHome: Bool = false
    var scrollLabel: String = "Scroll To Article"
    var onScrollTo: (() -> Void)? = nil

    private var caption: String {
        var parts: [String] = []
        if showHome, let home = hit.home { parts.append(home.title) }
        parts.append(hit.article.title)
        if !hit.section.heading.isEmpty { parts.append(hit.section.heading) }
        return parts.joined(separator: " \u{203A} ")
    }

    var body: some View {
        NavigationLink(destination: LazyDestination {
            IslamArticleCatalog.destination(id: hit.article.id, section: hit.section.heading)
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(caption)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(appearance.accent)
                    .lineLimit(2)

                HighlightedSnippet(
                    source: hit.snippet,
                    term: query,
                    font: .subheadline,
                    accent: appearance.accent,
                    fg: .primary,
                    lineLimit: 4,
                    guaranteeMatch: true
                )
            }
            .padding(.vertical, 4)
        }
        .islamArticleRowActions(title: hit.article.title, copyText: hit.snippet, scrollLabel: scrollLabel, onScrollTo: onScrollTo)
    }
}

/// The Quran list's row grammar on an article result: a context menu (scroll to the article's index
/// row, copy) and a trailing swipe whose arrow does the same scroll.
private struct IslamArticleRowActions: ViewModifier {
    let title: String
    let copyText: String?
    let scrollLabel: String
    let onScrollTo: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Text("Article Actions")
                    .foregroundStyle(.secondary)

                if let onScrollTo {
                    Button {
                        Settings.shared.hapticFeedback()
                        onScrollTo()
                    } label: {
                        Label(scrollLabel, systemImage: "arrow.down.circle")
                    }

                    Divider()
                }

                Button {
                    Settings.shared.hapticFeedback()
                    UIPasteboard.general.string = title
                } label: {
                    Label("Copy Title", systemImage: "doc.on.doc")
                }

                if let copyText, !copyText.isEmpty {
                    Button {
                        Settings.shared.hapticFeedback()
                        UIPasteboard.general.string = copyText.replacingOccurrences(of: "\u{2026}", with: "")
                    } label: {
                        Label("Copy Passage", systemImage: "doc.on.doc")
                    }
                }
            }
            .swipeActions(edge: .trailing) {
                if let onScrollTo {
                    Button {
                        Settings.shared.hapticFeedback()
                        onScrollTo()
                    } label: {
                        Image(systemName: "arrow.down.circle")
                    }
                    .tint(.secondary)
                }
            }
    }
}

extension View {
    func islamArticleRowActions(title: String, copyText: String?, scrollLabel: String = "Scroll To Article",
                                onScrollTo: (() -> Void)?) -> some View {
        modifier(IslamArticleRowActions(title: title, copyText: copyText, scrollLabel: scrollLabel, onScrollTo: onScrollTo))
    }
}

// MARK: - Result sections

/// The ARTICLES and IN THE ARTICLES sections a searching screen shows, plus the empty state. Title hits
/// are computed inline (cheap); content hits come from the screen's `IslamArticleSearchModel`.
struct IslamArticleSearchSections: View {
    let query: String
    let homes: Set<IslamArticleHome>
    let contentHits: [IslamArticleSearch.ContentHit]
    let isSearching: Bool
    var showHome: Bool = false
    /// True when the screen has other matches of its own (the Islam tab's resources), so an empty
    /// article result is not "nothing matched".
    var hasOtherResults: Bool = false
    /// The menu label for the scroll action: "Scroll To Article" on an index, the resource's name on
    /// the Islam tab root, where the scroll lands on the resource row instead.
    var scrollLabel: (IslamArticleEntry) -> String = { _ in "Scroll To Article" }
    let onScrollTo: (IslamArticleEntry) -> Void

    var body: some View {
        let titleHits = IslamArticleSearch.titleHits(query, homes: homes)

        if !titleHits.isEmpty {
            Section(header: SectionPillHeader(title: "ARTICLES", count: titleHits.count)) {
                ForEach(titleHits) { entry in
                    IslamArticleTitleRow(entry: entry, query: query, showHome: showHome,
                                         scrollLabel: scrollLabel(entry)) {
                        onScrollTo(entry)
                    }
                }
            }
        }

        if !contentHits.isEmpty {
            Section(header: SectionPillHeader(title: "IN THE ARTICLES", count: contentHits.count)) {
                ForEach(contentHits) { hit in
                    IslamArticleContentRow(hit: hit, query: query, showHome: showHome,
                                           scrollLabel: hit.entry.map(scrollLabel) ?? "Scroll To Article",
                                           onScrollTo: scrollAction(for: hit))
                }
            }
        }

        if titleHits.isEmpty, contentHits.isEmpty, !isSearching, !hasOtherResults {
            Section {
                Text("No articles match your search.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// The row's "Scroll To Article" action, or nil for a passage whose article has no index row here.
    private func scrollAction(for hit: IslamArticleSearch.ContentHit) -> (() -> Void)? {
        guard let entry = hit.entry else { return nil }
        return { onScrollTo(entry) }
    }
}

/// The "Ask AI about ..." row every searching Islam screen offers, with its sheet. Rendered only where
/// Apple Intelligence can run the chat.
struct AskAISearchSection: View {
    @Environment(\.appearance) private var appearance
    @State private var showAskAI = false

    let query: String

    var body: some View {
        if OnDeviceAsk.isAvailable {
            Section(header: HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("ASK AI")
                Spacer()
            }
            .foregroundStyle(appearance.accent)) {
                Button {
                    Settings.shared.hapticFeedback()
                    showAskAI = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption)

                        Text("Ask AI about \u{201C}\(query.trimmingCharacters(in: .whitespacesAndNewlines))\u{201D}")
                            .font(.caption.weight(.semibold))

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundColor(appearance.accent)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .conditionalGlassEffect(clear: true, rectangle: true)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showAskAI) {
                if #available(iOS 16.0, *) {
                    AskAIChatSheet(initialQuestion: query)
                }
            }
        }
    }
}

// MARK: - Index screens

/// One index screen's search plumbing, shared by Pillars & Beliefs and the How-to Guides: the query,
/// the async content hits, and the "Scroll To Article" target. The screen owns the `List`; this
/// hands it the sections and the bottom bar.
struct IslamArticleIndexSearch: ViewModifier {
    @Binding var searchText: String
    @Binding var barsCollapsed: Bool
    let scrollTarget: String?
    let proxy: ScrollViewProxy

    func body(content: Content) -> some View {
        content
            // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
            .collapseBarsOnScroll($barsCollapsed)
            .adaptiveSafeArea(edge: .bottom) {
                SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)))
                    .minimizedBarStyle(barsCollapsed)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
                    .padding(.horizontal, 24)
                    .padding(.bottom, BottomBarCushion.standard)
                    .background(Color.white.opacity(0.00001))
            }
            .onChange(of: scrollTarget) { target in
                guard let target else { return }
                // The search rows are still animating out; scroll once the index rows are back.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation { proxy.scrollTo(target, anchor: .top) }
                }
            }
    }
}

extension View {
    func islamArticleIndexSearch(searchText: Binding<String>, barsCollapsed: Binding<Bool>,
                                 scrollTarget: String?, proxy: ScrollViewProxy) -> some View {
        modifier(IslamArticleIndexSearch(searchText: searchText, barsCollapsed: barsCollapsed,
                                         scrollTarget: scrollTarget, proxy: proxy))
    }
}

#if DEBUG
/// `-pillarsSearch <query>`, `-guidesSearch <query>`, `-islamSearch <query>`: seed a screen's search a
/// moment after it appears - typing is not scriptable in the simulator, and this is the only way to
/// screenshot the result rows.
enum IslamSearchDebug {
    static func launchQuery(_ argument: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let idx = arguments.firstIndex(of: argument), arguments.indices.contains(idx + 1) else { return nil }
        return arguments[idx + 1]
    }
}
#endif
#endif

// MARK: - Article sources

/// The printed works and verified fatwa pages each article's SOURCES section lists. Keyed by the
/// article view's type name (the catalog id). Rows without a URL name a printed work.
enum ArticleSources {
    static let table: [String: [ArticleSource]] = [
        "GodPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Miftah Dar as-Sa'adah", subtitle: "Ibn al-Qayyim, on knowledge, design, and the proofs of the Creator"),
            ArticleSource(title: "Dar' Ta'arud al-Aql wan-Naql", subtitle: "Ibn Taymiyyah, revelation and reason do not conflict"),
            ArticleSource(title: "Kashf ash-Shubuhat", subtitle: "Muhammad ibn Abd al-Wahhab"),
            ArticleSource(title: "Existence of God: Any Evidence?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/26745"),
            ArticleSource(title: "Evidence of the Oneness of Allah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/13532"),
        ],
        "IslamPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Usul ath-Thalathah", subtitle: "Muhammad ibn Abd al-Wahhab, the three fundamental principles"),
            ArticleSource(title: "Kitab at-Tawhid", subtitle: "Muhammad ibn Abd al-Wahhab, with Fath al-Majid by Abd ar-Rahman ibn Hasan"),
            ArticleSource(title: "Tafsir as-Sa'di", subtitle: "Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "What Is Islam?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/10446"),
            ArticleSource(title: "The Only Religion in the Sight of Allah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/287024"),
        ],
        "MuslimPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Usul ath-Thalathah", subtitle: "Muhammad ibn Abd al-Wahhab, the three fundamental principles"),
            ArticleSource(title: "Sharh Usul al-Iman", subtitle: "Ibn al-Uthaymin, on the six pillars of faith"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "Islam and Muslims", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/20756"),
            ArticleSource(title: "What Are the Pillars of Islam?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/13569"),
        ],
        "AllahPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Al-Qawa'id al-Muthla", subtitle: "Ibn al-Uthaymin, on the names and attributes of Allah"),
            ArticleSource(title: "Kitab at-Tawhid", subtitle: "Muhammad ibn Abd al-Wahhab, with Fath al-Majid by Abd ar-Rahman ibn Hasan"),
            ArticleSource(title: "Importance of knowing the Beautiful Names of Allah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/4043"),
            ArticleSource(title: "Important questions about the beliefs of Ahl as-Sunnah concerning the names and attributes of Allah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/155478"),
        ],
        "QuranPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Itqan fi Ulum al-Quran", subtitle: "As-Suyuti"),
            ArticleSource(title: "Tafsir Ibn Kathir", subtitle: "Tafsir al-Quran al-Azim"),
            ArticleSource(title: "Muqaddimah fi Usul at-Tafsir", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Is the Quran the Word of Allah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/13804"),
            ArticleSource(title: "Miraculous aspects of the Holy Qur'an", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/245475"),
        ],
        "ProphetPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ar-Raheeq al-Makhtum (The Sealed Nectar)", subtitle: "Safi ar-Rahman al-Mubarakpuri"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "Al-Bidayah wan-Nihayah", subtitle: "Ibn Kathir"),
            ArticleSource(title: "Who Is Muhammad?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/11575"),
            ArticleSource(title: "Muhammad (peace and blessings of Allah be upon him) is the Seal of the Prophets and Messengers", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/113393"),
        ],
        "SunnahPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Miftah al-Jannah fil-Ihtijaj bis-Sunnah", subtitle: "As-Suyuti, on the authority of the Sunnah"),
            ArticleSource(title: "I'lam al-Muwaqqi'in", subtitle: "Ibn al-Qayyim, on following evidence over men"),
            ArticleSource(title: "Raf' al-Malam an al-A'immah al-A'lam", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Justification for following the Sunnah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/604"),
            ArticleSource(title: "If the Quran is perfect and complete and contains everything needed for the laws and regulations of sharee'ah, what need is there for the Sunnah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/93111"),
        ],
        "HadithPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "The Muqaddimah of Sahih Muslim", subtitle: "Imam Muslim on the isnad and the rejection of weak reports"),
            ArticleSource(title: "Nukhbat al-Fikar", subtitle: "Ibn Hajar al-Asqalani, hadith terminology, with Nuzhat an-Nazar"),
            ArticleSource(title: "Silsilat al-Ahadith as-Sahihah", subtitle: "Al-Albani"),
            ArticleSource(title: "Categories of hadeeth", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/126978"),
            ArticleSource(title: "Guidelines for distinguishing a saheeh hadeeth from a da'eef one", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/140158"),
        ],
        "ShahadahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Kitab at-Tawhid", subtitle: "Muhammad ibn Abd al-Wahhab, with Fath al-Majid by Abd ar-Rahman ibn Hasan"),
            ArticleSource(title: "Al-Usul ath-Thalathah", subtitle: "Muhammad ibn Abd al-Wahhab, the three fundamental principles"),
            ArticleSource(title: "Kashf ash-Shubuhat", subtitle: "Muhammad ibn Abd al-Wahhab"),
            ArticleSource(title: "What Are the Conditions of La Ilaha Illa-Allah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12295"),
            ArticleSource(title: "Meaning of \"la ilaha illa Allah Muhammadun Rasul Allah\"", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/179"),
        ],
        "SalahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Sifat Salat an-Nabi", subtitle: "Al-Albani, the Prophet's prayer described from the sahih hadith"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Importance of Prayer", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12305"),
            ArticleSource(title: "The virtue of one who regularly offers the five daily prayers and does them as enjoined", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/238527"),
        ],
        "SawmView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Virtues of Ramadan", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/13480"),
            ArticleSource(title: "Is Fasting Compulsory?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/26814"),
        ],
        "ZakahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Categories of Zakah Recipients", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/46209"),
            ArticleSource(title: "How to Calculate Zakah on Money Earned during the Year", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/93414"),
        ],
        "HajjView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "At-Tahqiq wal-Idah", subtitle: "Ibn Baz, on Hajj and Umrah"),
            ArticleSource(title: "Manasik al-Hajj wal-Umrah", subtitle: "Al-Albani"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Hajj: Its Virtues and Benefits", subtitle: "IslamQA", url: "https://islamqa.info/en/articles/77"),
            ArticleSource(title: "The reason why it is prescribed for Muslims to perform Hajj once in a lifetime", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/22466"),
        ],
        "GodView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Al-Qawa'id al-Muthla", subtitle: "Ibn al-Uthaymin, on the names and attributes of Allah"),
            ArticleSource(title: "Kitab at-Tawhid", subtitle: "Muhammad ibn Abd al-Wahhab, with Fath al-Majid by Abd ar-Rahman ibn Hasan"),
            ArticleSource(title: "What Is the Meaning of Belief in Allah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/34630"),
            ArticleSource(title: "What Is the Meaning of Tawhid?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/49030"),
        ],
        "AngelsView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Sharh Usul al-Iman", subtitle: "Ibn al-Uthaymin, on the six pillars of faith"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Al-Aqidah at-Tahawiyyah", subtitle: "At-Tahawi, with the commentary of Ibn Abi al-Izz al-Hanafi"),
            ArticleSource(title: "Reality of Belief in the Angels", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/9477"),
            ArticleSource(title: "Angels in Islam", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/843"),
        ],
        "BooksView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Sharh Usul al-Iman", subtitle: "Ibn al-Uthaymin, on the six pillars of faith"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Al-Aqidah at-Tahawiyyah", subtitle: "At-Tahawi, with the commentary of Ibn Abi al-Izz al-Hanafi"),
            ArticleSource(title: "Belief in the Books of Allah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/9519"),
            ArticleSource(title: "Have the Torah and Gospel Been Changed?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/2001"),
        ],
        "ProphetsView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Sharh Usul al-Iman", subtitle: "Ibn al-Uthaymin, on the six pillars of faith"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Al-Aqidah at-Tahawiyyah", subtitle: "At-Tahawi, with the commentary of Ibn Abi al-Izz al-Hanafi"),
            ArticleSource(title: "What Is Belief in the Messengers?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/8929"),
            ArticleSource(title: "Belief in the Prophets and Messengers is one of the pillars of faith, not belief in the Messengers only", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/138141"),
        ],
        "DayView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Sharh Usul al-Iman", subtitle: "Ibn al-Uthaymin, on the six pillars of faith"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Al-Aqidah at-Tahawiyyah", subtitle: "At-Tahawi, with the commentary of Ibn Abi al-Izz al-Hanafi"),
            ArticleSource(title: "The reality of belief in the Last Day", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/13994"),
            ArticleSource(title: "What Will Happen on the Day Of Resurrection?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/220511"),
        ],
        "QadarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Sharh Usul al-Iman", subtitle: "Ibn al-Uthaymin, on the six pillars of faith"),
            ArticleSource(title: "Shifa' al-Alil", subtitle: "Ibn al-Qayyim, on divine decree"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "What Is Qadar in Islam?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/34732"),
            ArticleSource(title: "Al-Qada wal Qadar according to Ahl al-Sunnah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/49004"),
        ],
        "HaramView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar al-Asqalani, commentary on Sahih al-Bukhari"),
            ArticleSource(title: "Al-Bidayah wan-Nihayah", subtitle: "Ibn Kathir"),
            ArticleSource(title: "Iqtida' as-Sirat al-Mustaqim", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Does the Multiplied Prayer Reward Apply to All of the Haram (sanctuary)?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/124812"),
            ArticleSource(title: "Righteous deeds in Makkah are better than those done elsewhere, but we do not know to what degree they are better, except in the case of prayer", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/118128"),
        ],
        "NabawiView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar al-Asqalani, commentary on Sahih al-Bukhari"),
            ArticleSource(title: "Al-Bidayah wan-Nihayah", subtitle: "Ibn Kathir"),
            ArticleSource(title: "Iqtida' as-Sirat al-Mustaqim", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Etiquette of Visiting the Prophet's Mosque", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/34464"),
            ArticleSource(title: "Islamic Guidelines for Visitors to the Prophet's Mosque", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/36863"),
        ],
        "AqsaView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar al-Asqalani, commentary on Sahih al-Bukhari"),
            ArticleSource(title: "Al-Bidayah wan-Nihayah", subtitle: "Ibn Kathir"),
            ArticleSource(title: "Iqtida' as-Sirat al-Mustaqim", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "The Importance of Al-Quds for Muslims", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/7726"),
            ArticleSource(title: "Is al-Masjid al-Aqsa considered to be a sanctuary?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/34751"),
        ],
        "CompileView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Itqan fi Ulum al-Quran", subtitle: "As-Suyuti"),
            ArticleSource(title: "Fada'il al-Quran in Sahih al-Bukhari", subtitle: "The chapters on the collection of the Quran"),
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar al-Asqalani, commentary on Sahih al-Bukhari"),
            ArticleSource(title: "'Uthmaan's compilation of the Mushaf in one style (harf)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/125091"),
            ArticleSource(title: "Who Wrote the Quran?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/10012"),
        ],
        "TafsirView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Muqaddimah fi Usul at-Tafsir", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Tafsir Ibn Kathir", subtitle: "Tafsir al-Quran al-Azim"),
            ArticleSource(title: "Tafsir at-Tabari", subtitle: "Jami' al-Bayan fi Ta'wil al-Quran"),
            ArticleSource(title: "The principles of tafseer (Quranic exegesis)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/287146"),
            ArticleSource(title: "Tafseer on the basis of narrated texts and tafseer on the basis of individual understanding", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/205290"),
        ],
        "TajweedView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Muqaddimah al-Jazariyyah", subtitle: "Ibn al-Jazari, the rules of recitation in verse"),
            ArticleSource(title: "At-Tamhid fi Ilm at-Tajwid", subtitle: "Ibn al-Jazari"),
            ArticleSource(title: "An-Nashr fil-Qira'at al-Ashr", subtitle: "Ibn al-Jazari"),
            ArticleSource(title: "Is It Obligatory to Read the Quran with Tajwid?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/125106"),
            ArticleSource(title: "She resolved to memorize the Quran but was told to learn Tajwid first", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/84312"),
        ],
        "MuqattaatPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir Ibn Kathir", subtitle: "Tafsir al-Quran al-Azim"),
            ArticleSource(title: "Tafsir at-Tabari", subtitle: "Jami' al-Bayan fi Ta'wil al-Quran"),
            ArticleSource(title: "Al-Itqan fi Ulum al-Quran", subtitle: "As-Suyuti"),
            ArticleSource(title: "The meaning of al-huroof al-muqatta'ah in the Qur'aan", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/21811"),
            ArticleSource(title: "There is no contradiction between the description of the Qur'an as being clear and explained in detail, and the appearance of the huroof muqatta'ah in it", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/242365"),
        ],
        "JuzView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Itqan fi Ulum al-Quran", subtitle: "As-Suyuti"),
            ArticleSource(title: "Al-Burhan fi Ulum al-Quran", subtitle: "Az-Zarkashi"),
            ArticleSource(title: "Tafsir Ibn Kathir", subtitle: "Tafsir al-Quran al-Azim"),
            ArticleSource(title: "The division of the Qur'an into parts and portions", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/109885"),
            ArticleSource(title: "Do the thirty juz' of the Quran have special names?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/153745"),
        ],
        "AhrufView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "An-Nashr fil-Qira'at al-Ashr", subtitle: "Ibn al-Jazari"),
            ArticleSource(title: "Al-Ibanah an Ma'ani al-Qira'at", subtitle: "Makki ibn Abi Talib"),
            ArticleSource(title: "Al-Itqan fi Ulum al-Quran", subtitle: "As-Suyuti"),
            ArticleSource(title: "The revelation of the Quran in seven styles (ahruf, sing. harf)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/5142"),
            ArticleSource(title: "'Uthmaan's compilation of the Mushaf in one style (harf)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/125091"),
        ],
        "QiraatView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "An-Nashr fil-Qira'at al-Ashr", subtitle: "Ibn al-Jazari"),
            ArticleSource(title: "Al-Ibanah an Ma'ani al-Qira'at", subtitle: "Makki ibn Abi Talib"),
            ArticleSource(title: "Al-Itqan fi Ulum al-Quran", subtitle: "As-Suyuti"),
            ArticleSource(title: "The revelation of the Quran in seven styles (ahruf, sing. harf)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/5142"),
            ArticleSource(title: "Ruling on one who, whilst praying, switches between the seven modes of recitation that were narrated via mutawaatir reports", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/192182"),
        ],
        "HijriCalendarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir Ibn Kathir", subtitle: "Tafsir al-Quran al-Azim"),
            ArticleSource(title: "Al-Bidayah wan-Nihayah", subtitle: "Ibn Kathir"),
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar al-Asqalani, commentary on Sahih al-Bukhari"),
            ArticleSource(title: "Why Is the Age of Islam Based on the Beginning of Hijrah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/176819"),
            ArticleSource(title: "The reason why the Hijri months are called by their well-known names", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/211395"),
        ],
        "SeerahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ar-Raheeq al-Makhtum (The Sealed Nectar)", subtitle: "Safi ar-Rahman al-Mubarakpuri"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "Al-Bidayah wan-Nihayah", subtitle: "Ibn Kathir"),
            ArticleSource(title: "Important books for the seeker of Islamic knowledge", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/14082"),
            ArticleSource(title: "Biography of the Prophet", subtitle: "IslamQA", url: "https://islamqa.info/en/categories/topics/263/biography-of-the-prophet"),
        ],
        "FarewellView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "Ar-Raheeq al-Makhtum (The Sealed Nectar)", subtitle: "Safi ar-Rahman al-Mubarakpuri"),
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar al-Asqalani, commentary on Sahih al-Bukhari"),
            ArticleSource(title: "حجة الوداع", subtitle: "IslamQA", url: "https://islamqa.info/ar/answers/175128"),
            ArticleSource(title: "مقتطفات من خطبة حجة الوداع", subtitle: "Ibn Baz", url: "https://binbaz.org.sa/videos/96/مقتطفات-من-خطبة-حجة-الوداع"),
        ],
        "AhlulBaytView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Minhaj as-Sunnah an-Nabawiyyah", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Fada'il as-Sahabah", subtitle: "Ahmad ibn Hanbal"),
            ArticleSource(title: "Who Are Ahl al-Bayt?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/10055"),
            ArticleSource(title: "Virtues of Ahl Al-Bayt", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/121948"),
        ],
        "WivesView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Isabah fi Tamyiz as-Sahabah", subtitle: "Ibn Hajar al-Asqalani"),
            ArticleSource(title: "Siyar A'lam an-Nubala'", subtitle: "Adh-Dhahabi"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Wives of Prophet Muhammad", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/47072"),
            ArticleSource(title: "The attitudes of the Messenger of Allah (blessings and peace of Allah be upon him) towards his wives and his good treatment of them", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/191429"),
        ],
        "SahabahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Isabah fi Tamyiz as-Sahabah", subtitle: "Ibn Hajar al-Asqalani"),
            ArticleSource(title: "Siyar A'lam an-Nubala'", subtitle: "Adh-Dhahabi"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Virtues of the Sahabah (Prophet's Companions)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/83121"),
            ArticleSource(title: "The view of Ahl al-Sunnah towards the Sahaabah and the leadership of Abu Bakr al-Siddeeq", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/13713"),
        ],
        "CaliphatesView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Bidayah wan-Nihayah", subtitle: "Ibn Kathir"),
            ArticleSource(title: "Tarikh al-Khulafa'", subtitle: "As-Suyuti"),
            ArticleSource(title: "Minhaj as-Sunnah an-Nabawiyyah", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "How the caliph of the Muslims is appointed", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/111836"),
            ArticleSource(title: "The hadeeth \"There will appear among you twelve imams coming one after another, all of them from Quraysh.\"", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/146316"),
        ],
        "MadhabView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "I'lam al-Muwaqqi'in", subtitle: "Ibn al-Qayyim, on following evidence over men"),
            ArticleSource(title: "Raf' al-Malam an al-A'immah al-A'lam", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Jami' Bayan al-Ilm wa Fadlih", subtitle: "Ibn Abd al-Barr"),
            ArticleSource(title: "Do You Have to Follow a Madhhab?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/21420"),
            ArticleSource(title: "Why are there differences of opinion among the imams concerning fiqhi matters? Is it essential to follow one of the madhhabs?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/128658"),
        ],
        "AqeedahMadhabView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Sharh Usul I'tiqad Ahl as-Sunnah", subtitle: "Al-Lalaka'i, the creed of the Salaf with chains"),
            ArticleSource(title: "Al-Ibanah an Usul ad-Diyanah", subtitle: "Abu al-Hasan al-Ash'ari, his final creed"),
            ArticleSource(title: "Who are the Ash'aris? Are they among Ahl as-Sunnah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/226290"),
            ArticleSource(title: "Differences between Maturidis and Ahl as-Sunnah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/205836"),
        ],
        "AhlusSunnahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Usul as-Sunnah", subtitle: "Ahmad ibn Hanbal, the creed of the Salaf in his own words"),
            ArticleSource(title: "Sharh as-Sunnah", subtitle: "Al-Barbahari"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Who are Ahl al-Sunnah wa'l-Jamaa'ah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/10777"),
            ArticleSource(title: "Which Group Is the Saved One?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/90112"),
        ],
        "FiqhAqeedahManhajView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Usul ath-Thalathah", subtitle: "Muhammad ibn Abd al-Wahhab, the three fundamental principles"),
            ArticleSource(title: "Lum'at al-I'tiqad", subtitle: "Ibn Qudamah al-Maqdisi, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "I'lam al-Muwaqqi'in", subtitle: "Ibn al-Qayyim, on following evidence over men"),
            ArticleSource(title: "What Is 'Aqeedah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/951"),
            ArticleSource(title: "Difference between Shari'ah, Fiqh and Usul Al-Fiqh", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/282538"),
        ],
        "SahabahScholarsView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Isabah fi Tamyiz as-Sahabah", subtitle: "Ibn Hajar al-Asqalani"),
            ArticleSource(title: "Siyar A'lam an-Nubala'", subtitle: "Adh-Dhahabi"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Who Is `Abdullah ibn `Abbas?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/330016"),
            ArticleSource(title: "The Rightly-Guided Caliphs (may Allah be pleased with them) were more knowledgeable and more virtuous than the rest of the Sahabah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/211865"),
        ],
        "SalafScholarsView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Siyar A'lam an-Nubala'", subtitle: "Adh-Dhahabi"),
            ArticleSource(title: "Al-Intiqa' fi Fada'il ath-Thalathah al-A'immah al-Fuqaha'", subtitle: "Ibn Abd al-Barr"),
            ArticleSource(title: "Usul as-Sunnah", subtitle: "Ahmad ibn Hanbal, the creed of the Salaf in his own words"),
            ArticleSource(title: "Brief overview of the madhhab of Imam Abu Haneefah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/46992"),
            ArticleSource(title: "A brief biography of Imam Ahmad", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/153333"),
        ],
        "TabariView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir at-Tabari", subtitle: "Jami' al-Bayan fi Ta'wil al-Quran"),
            ArticleSource(title: "Tarikh ar-Rusul wal-Muluk", subtitle: "At-Tabari"),
            ArticleSource(title: "Siyar A'lam an-Nubala'", subtitle: "Adh-Dhahabi"),
            ArticleSource(title: "Which is more sound, Tafseer Ibn Katheer or Tafseer al-Tabari?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/43778"),
        ],
        "IbnTaymiyyahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Majmu' al-Fatawa", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Al-A'lam al-Aliyyah fi Manaqib Ibn Taymiyyah", subtitle: "Al-Bazzar"),
            ArticleSource(title: "The 'aqeedah of Shaykh al-Islam Ibn Taymiyah and the praise of the imams for him and Ibn Hajar's attitude towards him", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/96323"),
            ArticleSource(title: "Effect of Shaykh al-Islam Ibn Taymiyah on the da'wah of Shaykh Muhammad ibn 'Abd al-Wahhaab", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/89671"),
        ],
        "IbnQayyimView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Madarij as-Salikin", subtitle: "Ibn al-Qayyim"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "I'lam al-Muwaqqi'in", subtitle: "Ibn al-Qayyim, on following evidence over men"),
            ArticleSource(title: "ترجمة ابن القيم وابن الجوزي ، ومعنى \"نفعنا الله ببركتهم\" في كلام العلماء", subtitle: "IslamQA", url: "https://islamqa.info/ar/answers/127762"),
            ArticleSource(title: "Specious arguments of the Ash'aris about Ibn al-Qayyim and Ibn Abi'l-'Izz (may Allah have mercy on them)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/235416"),
        ],
        "DhahabiView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Siyar A'lam an-Nubala'", subtitle: "Adh-Dhahabi"),
            ArticleSource(title: "Al-Uluw lil-Aliyy al-Ghaffar", subtitle: "Adh-Dhahabi"),
            ArticleSource(title: "Tadhkirat al-Huffaz", subtitle: "Adh-Dhahabi"),
            ArticleSource(title: "Biography of Imam adh-Dhahabi", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/229097"),
        ],
        "IbnKathirView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir Ibn Kathir", subtitle: "Tafsir al-Quran al-Azim"),
            ArticleSource(title: "Al-Bidayah wan-Nihayah", subtitle: "Ibn Kathir"),
            ArticleSource(title: "Al-Ba'ith al-Hathith", subtitle: "Ibn Kathir, on hadith sciences"),
            ArticleSource(title: "ترجمة موجزة للحافظ ابن كثير", subtitle: "IslamQA", url: "https://islamqa.info/ar/answers/110699"),
            ArticleSource(title: "التعريف بكتاب البداية والنهاية وكتب يُنصح باقتنائها", subtitle: "Ibn Baz", url: "https://binbaz.org.sa/fatwas/12339/التعريف-بكتاب-البداية-والنهاية-وكتب-ينصح-باقتنائها"),
        ],
        "LaterScholarsView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Majmu' Fatawa wa Maqalat", subtitle: "Ibn Baz"),
            ArticleSource(title: "Majmu' Fatawa wa Rasa'il", subtitle: "Ibn al-Uthaymin"),
            ArticleSource(title: "Silsilat al-Ahadith as-Sahihah", subtitle: "Al-Albani"),
            ArticleSource(title: "Shaykh al-Albaani (may Allaah have mercy on him) was a great muhaddith and a mujtahid faqeeh", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/113687"),
            ArticleSource(title: "Advice to those who do not recognize the Salafi scholars and call them Wahhaabis", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12203"),
        ],
        "TawhidView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Kitab at-Tawhid", subtitle: "Muhammad ibn Abd al-Wahhab, with Fath al-Majid by Abd ar-Rahman ibn Hasan"),
            ArticleSource(title: "Al-Usul ath-Thalathah", subtitle: "Muhammad ibn Abd al-Wahhab, the three fundamental principles"),
            ArticleSource(title: "Kashf ash-Shubuhat", subtitle: "Muhammad ibn Abd al-Wahhab"),
            ArticleSource(title: "What Is the Meaning of Tawhid?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/49030"),
            ArticleSource(title: "What Are the Conditions of La Ilaha Illa-Allah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12295"),
        ],
        "SalafiyyahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Usul as-Sunnah", subtitle: "Ahmad ibn Hanbal, the creed of the Salaf in his own words"),
            ArticleSource(title: "Sharh as-Sunnah", subtitle: "Al-Barbahari"),
            ArticleSource(title: "Ad-Durar as-Saniyyah", subtitle: "The letters and creed of Muhammad ibn Abd al-Wahhab and the scholars of Najd"),
            ArticleSource(title: "Who are the Wahhaabis and what is their message?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/10867"),
            ArticleSource(title: "Muhammad ibn 'Abd al-Wahhaab – a reformer concerning whom many malicious lies have been told", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/36616"),
        ],
        "QuranSunnahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Miftah al-Jannah fil-Ihtijaj bis-Sunnah", subtitle: "As-Suyuti, on the authority of the Sunnah"),
            ArticleSource(title: "I'lam al-Muwaqqi'in", subtitle: "Ibn al-Qayyim, on following evidence over men"),
            ArticleSource(title: "Raf' al-Malam an al-A'immah al-A'lam", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Justification for following the Sunnah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/604"),
            ArticleSource(title: "The misguided sect of al-Qur'aaniyyeen", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/3440"),
        ],
        "ShirkView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Kitab at-Tawhid", subtitle: "Muhammad ibn Abd al-Wahhab, with Fath al-Majid by Abd ar-Rahman ibn Hasan"),
            ArticleSource(title: "Kashf ash-Shubuhat", subtitle: "Muhammad ibn Abd al-Wahhab"),
            ArticleSource(title: "Ighathat al-Lahfan", subtitle: "Ibn al-Qayyim"),
            ArticleSource(title: "What Is Shirk and its types?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/34817"),
            ArticleSource(title: "Minor shirk", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/91763"),
        ],
        "KufrView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Nawaqid al-Islam", subtitle: "Muhammad ibn Abd al-Wahhab, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Majmu' al-Fatawa, volumes 3 and 12", subtitle: "Ibn Taymiyyah, on takfir and its conditions"),
            ArticleSource(title: "Madarij as-Salikin", subtitle: "Ibn al-Qayyim"),
            ArticleSource(title: "Is there scholarly consensus on all ten things which nullify Islam that were mentioned by Imam Muhammad ibn 'Abd al-Wahhaab?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/227935"),
            ArticleSource(title: "What Is Takfir?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/85102"),
        ],
        "BidahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-I'tisam", subtitle: "Ash-Shatibi, on innovation"),
            ArticleSource(title: "Iqtida' as-Sirat al-Mustaqim", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Al-Ibanah al-Kubra", subtitle: "Ibn Battah"),
            ArticleSource(title: "Bid'ah Hasanah (\"Good Innovations\")", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/864"),
            ArticleSource(title: "What Is the Meaning of Bid'ah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/7277"),
        ],
        "MawlidView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Iqtida' as-Sirat al-Mustaqim", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Al-Mawrid fi Amal al-Mawlid", subtitle: "Al-Fakihani"),
            ArticleSource(title: "Majmu' Fatawa wa Maqalat", subtitle: "Ibn Baz"),
            ArticleSource(title: "Celebrating Mawlid al-Nabi (Muhammad's Birthday): Allowed?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/249"),
            ArticleSource(title: "Ruling on celebrating the birthday of the Messenger (blessings and peace of Allah be upon him) without any singing or other haram things", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/148053"),
        ],
        "SufismAnswerView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Furqan bayna Awliya' ar-Rahman wa Awliya' ash-Shaytan", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Madarij as-Salikin", subtitle: "Ibn al-Qayyim"),
            ArticleSource(title: "Majmu' al-Fatawa, volumes 10 and 11", subtitle: "Ibn Taymiyyah, on tasawwuf"),
            ArticleSource(title: "Sufi tareeqahs and the ruling on joining them", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/20375"),
            ArticleSource(title: "What Is Sufism?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/47431"),
        ],
        "ShiaAnswerView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Minhaj as-Sunnah an-Nabawiyyah", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Al-Muntaqa min Minhaj al-I'tidal", subtitle: "Adh-Dhahabi's abridgement of Minhaj as-Sunnah"),
            ArticleSource(title: "Information about the Shi'ah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/97448"),
            ArticleSource(title: "The status of the imams of the Ithna 'Ashari Shi'ah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/101272"),
        ],
        "ChristianityAnswerView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Jawab as-Sahih li man Baddala Din al-Masih", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Hidayat al-Hayara", subtitle: "Ibn al-Qayyim, answering the Jews and Christians"),
            ArticleSource(title: "Al-Fisal fil-Milal wal-Ahwa' wan-Nihal", subtitle: "Ibn Hazm"),
            ArticleSource(title: "What is the concept of the Christian Trinity that the Quran declares to be false?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/243142"),
            ArticleSource(title: "The crucifixion of the Messiah between Islam and Christianity", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/224199"),
        ],
        "JudaismAnswerView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Jawab as-Sahih li man Baddala Din al-Masih", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Hidayat al-Hayara", subtitle: "Ibn al-Qayyim, answering the Jews and Christians"),
            ArticleSource(title: "Al-Fisal fil-Milal wal-Ahwa' wan-Nihal", subtitle: "Ibn Hazm"),
            ArticleSource(title: "Question about the distortion to which the Torah was subjected", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/305743"),
            ArticleSource(title: "The misguidance of the Jews with regard to 'aqeedah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/9905"),
        ],
        "HinduismAnswerView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Kitab at-Tawhid", subtitle: "Muhammad ibn Abd al-Wahhab, with Fath al-Majid by Abd ar-Rahman ibn Hasan"),
            ArticleSource(title: "Ighathat al-Lahfan", subtitle: "Ibn al-Qayyim"),
            ArticleSource(title: "Al-Fisal fil-Milal wal-Ahwa' wan-Nihal", subtitle: "Ibn Hazm"),
            ArticleSource(title: "A brief look at Hinduism", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/126472"),
            ArticleSource(title: "Reincarnation in Islam", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/14379"),
        ],
        "PaganismAnswerView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Kitab at-Tawhid", subtitle: "Muhammad ibn Abd al-Wahhab, with Fath al-Majid by Abd ar-Rahman ibn Hasan"),
            ArticleSource(title: "Ighathat al-Lahfan", subtitle: "Ibn al-Qayyim"),
            ArticleSource(title: "Al-Fisal fil-Milal wal-Ahwa' wan-Nihal", subtitle: "Ibn Hazm"),
            ArticleSource(title: "What is meant by al-wathaniyyah (idolatry)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/307198"),
            ArticleSource(title: "Witchcraft and Seeking Help From Practitioners of it", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12578"),
        ],
        "BuddhismAnswerView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Kitab at-Tawhid", subtitle: "Muhammad ibn Abd al-Wahhab, with Fath al-Majid by Abd ar-Rahman ibn Hasan"),
            ArticleSource(title: "Ighathat al-Lahfan", subtitle: "Ibn al-Qayyim"),
            ArticleSource(title: "Al-Fisal fil-Milal wal-Ahwa' wan-Nihal", subtitle: "Ibn Hazm"),
            ArticleSource(title: "Buddha was a kaafir philosopher not a Prophet", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/106416"),
            ArticleSource(title: "Categories of religion", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/21525"),
        ],
        "AtheismAnswerView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Miftah Dar as-Sa'adah", subtitle: "Ibn al-Qayyim, on knowledge, design, and the proofs of the Creator"),
            ArticleSource(title: "Dar' Ta'arud al-Aql wan-Naql", subtitle: "Ibn Taymiyyah, revelation and reason do not conflict"),
            ArticleSource(title: "Kashf ash-Shubuhat", subtitle: "Muhammad ibn Abd al-Wahhab"),
            ArticleSource(title: "Existence of God: Any Evidence?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/26745"),
            ArticleSource(title: "Falseness of the theory of evolution", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/34508"),
        ],
        "HowToPrayView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Sifat Salat an-Nabi", subtitle: "Al-Albani, the Prophet's prayer described from the sahih hadith"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Description of the Prophet's Prayer", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/13340"),
            ArticleSource(title: "Obligatory Parts and Sunnah Acts of Prayer", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/65847"),
        ],
        "HowToFastView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "What Breaks Your Fast", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/38023"),
            ArticleSource(title: "Matters that Break the Fast", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/22981"),
        ],
        "HowToZakahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "How to Calculate Zakah on Gold", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/214221"),
            ArticleSource(title: "Evidence That the Rate of Zakah is 2.5%", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/145600"),
        ],
        "HowToHajjView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "At-Tahqiq wal-Idah", subtitle: "Ibn Baz, on Hajj and Umrah"),
            ArticleSource(title: "Manasik al-Hajj wal-Umrah", subtitle: "Al-Albani"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Description of Hajj", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/31822"),
            ArticleSource(title: "How to Perform Hajj", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/27090"),
        ],
        "HowToUmrahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "At-Tahqiq wal-Idah", subtitle: "Ibn Baz, on Hajj and Umrah"),
            ArticleSource(title: "Manasik al-Hajj wal-Umrah", subtitle: "Al-Albani"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "How to Perform 'Umrah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/154979"),
            ArticleSource(title: "What Is 'Umrah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/31819"),
        ],
        "WudhuView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "How to Make Wudu", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/11497"),
            ArticleSource(title: "What Are the Pillars of Wudu?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/226422"),
        ],
        "GhuslView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "Description of Islamic Ghusl (Complete Body Ablution)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/415"),
            ArticleSource(title: "How to Make Ghusl for Major Impurity", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/82344"),
        ],
        "TayammumView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "How to Perform Tayammum", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/21074"),
            ArticleSource(title: "Can You Do Tayammum Instead of Ghusl?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/40204"),
        ],
        "JumuahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Is the khutbah a condition of Jumu`ah prayer being valid?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/290308"),
            ArticleSource(title: "Conditions of Friday Khutbah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/115854"),
        ],
        "AdhanOtherView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Sifat Salat an-Nabi", subtitle: "Al-Albani, the Prophet's prayer described from the sahih hadith"),
            ArticleSource(title: "How to Call Adhan", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/21376"),
            ArticleSource(title: "Is it valid to recite the adhan with thirteen phrases, including two takbirs at the beginning and without tarji` (repeating) of the Shahadatayn?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/340598"),
        ],
        "IqamahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Sifat Salat an-Nabi", subtitle: "Al-Albani, the Prophet's prayer described from the sahih hadith"),
            ArticleSource(title: "Iqamah: How Is It Done?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/10458"),
            ArticleSource(title: "Is it prescribed to repeat the phrases of the iqaamah twice?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/111893"),
        ],
        "RawatibView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "Qiyam Ramadan", subtitle: "Al-Albani"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Sunnah Prayers", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/1048"),
            ArticleSource(title: "Sunnah Prayers: 10 or 12?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/175137"),
        ],
        "WitrView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "Qiyam Ramadan", subtitle: "Al-Albani"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "How to Pray Witr", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/46544"),
            ArticleSource(title: "When to Pray Witr?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/32577"),
        ],
        "TahajjudView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "Qiyam Ramadan", subtitle: "Al-Albani"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "How to Pray Tahajjud and Witr", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/216236"),
            ArticleSource(title: "What Is the Difference between Tahajjud and Qiyam Al-layl?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/143240"),
        ],
        "DuhaView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "Qiyam Ramadan", subtitle: "Al-Albani"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Duha Prayer: How Many Rak`ahs?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/209657"),
            ArticleSource(title: "Duha Prayer Time", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/22389"),
        ],
        "TaraweehView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "Qiyam Ramadan", subtitle: "Al-Albani"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Numbers of Rak'ahs in Tarawih Prayer", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/9036"),
            ArticleSource(title: "Is Tarawih Prayed in Sets of Two Rak`ahs?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/106463"),
        ],
        "JanazahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ahkam al-Jana'iz", subtitle: "Al-Albani"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "How to Pray Salat al-Janazah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12363"),
            ArticleSource(title: "How to Wash the Deceased in Islam", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/201085"),
        ],
        "IstikharahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Wabil as-Sayyib", subtitle: "Ibn al-Qayyim, on dhikr and dua"),
            ArticleSource(title: "Ad-Da' wad-Dawa'", subtitle: "Ibn al-Qayyim"),
            ArticleSource(title: "Hisn al-Muslim", subtitle: "Sa'id ibn Ali al-Qahtani, the authentic adhkar and duas"),
            ArticleSource(title: "How to Pray Istikharah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/2217"),
            ArticleSource(title: "Istikharah prayer", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/11981"),
        ],
        "TravelPrayerView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "Risalah fi Sujud as-Sahw", subtitle: "Ibn al-Uthaymin"),
            ArticleSource(title: "Ruling on Shortening Prayers when Travelling", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/82751"),
            ArticleSource(title: "Is Combining Prayers when Travelling Permissible?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/49885"),
        ],
        "SickPrayerView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "Risalah fi Sujud as-Sahw", subtitle: "Ibn al-Uthaymin"),
            ArticleSource(title: "Can You Pray Sitting Down?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/67934"),
            ArticleSource(title: "How to pray when lying down", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/294088"),
        ],
        "MissedPrayerView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "Risalah fi Sujud as-Sahw", subtitle: "Ibn al-Uthaymin"),
            ArticleSource(title: "Ruling on making up missed prayers", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/13664"),
            ArticleSource(title: "How should missed prayers be made up?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/20882"),
        ],
        "SujudSahwView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "Risalah fi Sujud as-Sahw", subtitle: "Ibn al-Uthaymin"),
            ArticleSource(title: "Reasons for Sujud As-Sahw", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12527"),
            ArticleSource(title: "When to Offer Sujud As-Sahw", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/77430"),
        ],
        "VoluntaryFastsView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Voluntary Fasting in Islam", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/21979"),
            ArticleSource(title: "Virtues of Shawwal Fasting", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/7859"),
        ],
        "ItikafView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "How Did Prophet Muhammad Perform I'tikaf?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12658"),
            ArticleSource(title: "Conditions of I'tikaaf", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12411"),
        ],
        "ZakatFitrView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Rules of Zakat al-Fitr", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/207225"),
            ArticleSource(title: "How Much Is Zakat al-Fitr?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/49793"),
        ],
        "TakbiratView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Ahkam al-Udhiyah wadh-Dhakah", subtitle: "Ibn al-Uthaymin"),
            ArticleSource(title: "How to Pray 'Eid Prayer", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/36491"),
            ArticleSource(title: "'Eid Takbir: What Are the Different Formulas?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/158543"),
        ],
        "UdhiyahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in worship and daily life"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Ahkam al-Udhiyah wadh-Dhakah", subtitle: "Ibn al-Uthaymin"),
            ArticleSource(title: "Conditions of Udhiyah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/36755"),
            ArticleSource(title: "Rulings of Udhiyah", subtitle: "IslamQA", url: "https://islamqa.info/en/articles/67"),
        ],
        "BecomeMuslimView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Usul ath-Thalathah", subtitle: "Muhammad ibn Abd al-Wahhab, the three fundamental principles"),
            ArticleSource(title: "Kitab at-Tawhid", subtitle: "Muhammad ibn Abd al-Wahhab, with Fath al-Majid by Abd ar-Rahman ibn Hasan"),
            ArticleSource(title: "Fatawa Arkan al-Islam", subtitle: "Ibn al-Uthaymin, on the pillars of Islam"),
            ArticleSource(title: "How to Become a Muslim", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/11819"),
            ArticleSource(title: "A person just accepting Islam should pronounce shahaadah before wudu", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/177"),
        ],
        "TawbahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Madarij as-Salikin, the station of tawbah", subtitle: "Ibn al-Qayyim"),
            ArticleSource(title: "Ad-Da' wad-Dawa'", subtitle: "Ibn al-Qayyim"),
            ArticleSource(title: "Riyad as-Salihin", subtitle: "An-Nawawi, with the takhrij of al-Albani"),
            ArticleSource(title: "Conditions of Repentance", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/289765"),
            ArticleSource(title: "How to Repent in Islam", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/14289"),
        ],
        "MakeDuaView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Wabil as-Sayyib", subtitle: "Ibn al-Qayyim, on dhikr and dua"),
            ArticleSource(title: "Ad-Da' wad-Dawa'", subtitle: "Ibn al-Qayyim"),
            ArticleSource(title: "Hisn al-Muslim", subtitle: "Sa'id ibn Ali al-Qahtani, the authentic adhkar and duas"),
            ArticleSource(title: "How to Make Du'a", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/36902"),
            ArticleSource(title: "Times When Du`a Is Accepted", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/22438"),
        ],
    ]
}
