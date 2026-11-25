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

/// What a page's own search bar is on, which decides what its results show and in which language.
enum ArticleSearchKind {
    /// An English article (Pillars & Beliefs, the How-To Guides, Proving Islam, the generated pages
    /// and the Miracles articles): IN THIS ARTICLE, then the other articles, in English.
    case article
    /// A page of the app's own, translated or not (a Tajweed Foundations page, a Tajweed Course
    /// lesson, a hadith's explanation): ON THIS PAGE alone, in the reader's language.
    case page
}

enum IslamArticleHome: String, Hashable, CaseIterable {
    case pillars
    case guides
    /// The Proving Islam library (2026-09-29): the cumulative case that Islam is true, adapted from
    /// provingislam.net's "The Complete Case". Its chapters are ordinary catalog articles, so search,
    /// the Ask AI corpus and the in-page search reach them like any other page.
    case proving
    // The six reading libraries opened as Islamic resources on 2026-11-24 (Abu: "Stories of prophets",
    // "Sahaba, Ahlul Bayt, Salaf", "Refuting religions", "Preservation/Compilation of Quran", "Science of
    // Hadiths", "Domino Process proving Islam"). Each is drawn by `IslamLibraryView`; its groups list its
    // own chapters beside the Pillars & Beliefs and Proving Islam articles on the same subject
    // (`IslamArticleCatalog.members`), so the library is whole without a second copy of any page.
    case stories
    case companions
    case religions
    case preservation
    case hadithScience
    /// The Domino Process: Abu's own dawah workshop series (Dawah/Handbook), seven dominoes from
    /// reality to a Creator, to revelation, to Islam.
    case domino

    /// The resource's English title. Data (the Ask AI sources cite it); it is shown beside the English
    /// articles through `AppLanguage.article`, while the Islam tab's own tile translates.
    var title: String {
        switch self {
        case .pillars: return "Pillars & Beliefs"
        case .guides: return "How-To Guides"
        case .proving: return "Proving Islam"
        case .stories: return "Stories of the Prophets"
        case .companions: return "Sahabah, Ahlul Bayt & Salaf"
        case .religions: return "Refuting Religions"
        case .preservation: return "Preservation of the Quran"
        case .hadithScience: return "Science of Hadith"
        case .domino: return "The Domino Process"
        }
    }

    var systemImage: String {
        switch self {
        case .pillars: return "moon.stars"
        case .guides: return "list.bullet.rectangle"
        case .proving: return "checkmark.shield"
        case .stories: return "scroll"
        case .companions: return "person.3"
        case .religions: return "signpost.right"
        case .preservation: return "lock.doc"
        case .hadithScience: return "link"
        case .domino: return "rectangle.split.3x1"
        }
    }

    /// One line of what the home holds: the resource's subtitle, in English (a door to the library sits
    /// on English pages and says it with them).
    var subtitle: String {
        switch self {
        case .pillars: return "The Five Pillars and Six Beliefs"
        case .guides: return "Wudu, salah, Jumuah, and more"
        case .proving: return "The complete case that Islam is true, one line of evidence at a time"
        case .stories: return "From Adam to Isa, told from the Quran and sound hadith"
        case .companions: return "The Companions, the Prophet\u{2019}s household, and the early generations"
        case .religions: return "Other faiths and worldviews, answered fairly"
        case .preservation: return "How the Quran was revealed, memorised, written, and kept"
        case .hadithScience: return "How every narration is checked, graded, and preserved"
        case .domino: return "From reality to a Creator, to revelation, to Islam"
        }
    }

    /// The homes drawn by `IslamLibraryView` (every one but the three with screens of their own).
    var isLibrary: Bool {
        switch self {
        case .pillars, .guides, .proving: return false
        default: return true
        }
    }

    /// The Islam tab's DEBUG launch argument that opens an article on this home's index.
    var debugArticleArgument: String {
        switch self {
        case .pillars: return "-pillarsArticle"
        case .guides: return "-guidesArticle"
        case .proving: return "-provingArticle"
        default: return "-libraryArticle"
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
    /// The `-pillarsArticle` / `-guidesArticle` DEBUG launch-argument key. It is also the second half
    /// of the article's shared link (`linkKey`), so a key that has shipped is never renamed.
    let debugKey: String
    /// THE BASICS rows are set larger and in the accent, the way the index has always drawn them.
    var emphasized: Bool = false
    /// Spellings the row title does not carry but a searcher will type ("wudu", "ablution").
    var aliases: [String] = []

    /// The row id in the index list, the target of "Scroll To Article".
    var listID: String { "article_\(id)" }

    /// What a shared link calls this article (AppLink.swift): "pillars.shahadah", "guides.wudhu".
    /// The home comes first because four keys ("god", "zakah", "hajj", "evil-eye") name a page in
    /// two homes.
    var linkKey: String { "\(home.rawValue).\(debugKey)" }
}

struct IslamArticleGroup: Identifiable {
    let title: String
    let home: IslamArticleHome
    let entries: [IslamArticleEntry]
    /// How many rows the index shows before a "Show All" row takes over, for a group long enough to
    /// bury the sections under it (the 25 prophets). Nil shows every row.
    var foldedCount: Int? = nil

    var id: String { "\(home.rawValue)/\(title)" }

    /// What the rows are, for a folded group's "Show All 25 Prophets".
    var rowNoun: String {
        title.localizedCaseInsensitiveContains("PROPHETS") ? "Prophets" : "Articles"
    }

    /// The group's icon, drawn on every row in it as an `AccentIconChip` (Abu, 2026-09-19: the index
    /// rows were bare text while every other list in the app leads with a chip, so Pillars and the
    /// How-to Guides read as a different, plainer app). Keyed off the group title, which is the one
    /// thing every row in a section already shares.
    var systemImage: String {
        switch title {
        case "THE BASICS":                      return "questionmark.circle"
        case "THE 5 PILLARS OF ISLAM":          return "building.columns"
        case "THE 6 PILLARS OF IMAN (FAITH)":   return "heart"
        case "THE 3 PILLARS OF TAWHID":         return "hand.point.up"
        case "THE 25 PROPHETS NAMED IN THE QURAN": return "person.wave.2"
        case "THE THREE HOLY MOSQUES":          return "building.2"
        case "QURAN & TAFSIR":                  return "book.closed"
        case "HADITH & ITS SCIENCES":           return "books.vertical"
        case "THE METHOD":                      return "scalemass"
        case "THE MESSENGER":                   return "person.fill.checkmark"
        case "THE BOOK":                        return "book"
        case "WHAT HE COULD NOT HAVE KNOWN":    return "eye"
        case "THE MESSAGE":                     return "text.quote"
        case "THE VERDICT":                     return "checkmark.seal"
        case "THE ISLAMIC CALENDAR":            return "calendar"
        case "HISTORICAL & BIOGRAPHICAL":       return "clock.arrow.circlepath"
        case "SCHOLARS OF AHL AS-SUNNAH":       return "text.book.closed"
        case "SALAFIYYAH: THE WAY OF THE SALAF": return "arrow.triangle.branch"
        case "ANSWERING OTHER PATHS":           return "bubble.left.and.bubble.right"
        case "HOW TO WORSHIP":                  return "hands.sparkles"
        case "PURIFICATION & PRAYER":           return "drop"
        case "MORE PRAYERS":                    return "moon.stars"
        case "PRAYER IN SPECIAL CASES":         return "airplane"
        case "FASTING & CHARITY":               return "sunrise"
        case "EID":                             return "sparkles"
        case "FAITH & THE HEART":               return "heart.text.square"
        // The six libraries (2026-11-24).
        case "BEFORE THE STORIES":              return "book"
        case "THE FIRST PEOPLE":                return "figure.stand"
        case "IBRAHIM AND HIS HOUSE":           return "flame"
        case "PATIENCE AND RETURN":             return "hourglass"
        case "MUSA AND BANI ISRA'IL":           return "water.waves"
        case "THE PROPHETS OF ARABIA":          return "sun.dust"
        case "THE KINGS AND PROPHETS OF BANI ISRA'IL": return "crown"
        case "THE LAST OF BANI ISRA'IL":        return "star.and.crescent"
        case "BEYOND THE QURAN":                return "questionmark.folder"
        case "THE SEAL OF THE PROPHETS":        return "seal"
        case "WHO THEY ARE":                    return "person.3"
        case "THE RIGHTLY GUIDED CALIPHS":      return "flag"
        case "PROMISED PARADISE":               return "leaf"
        case "AHLUL BAYT: THE PROPHET'S HOUSEHOLD": return "house"
        case "COMPANIONS OF NOTE":              return "star"
        case "THE SALAF AFTER THEM":            return "arrow.down.forward"
        case "THE PEOPLE OF THE BOOK":          return "book.closed"
        case "THE RELIGIONS OF THE EAST":       return "sunrise"
        case "WITHOUT GOD OR WITHOUT REVELATION": return "questionmark.circle"
        case "NEW PROPHETS AND SECTS":          return "exclamationmark.triangle"
        case "HOW IT CAME DOWN":                return "arrow.down.to.line"
        case "KEPT IN HEARTS AND ON PAGES":     return "heart.text.square"
        case "THE MUSHAF ACROSS THE CENTURIES": return "text.book.closed"
        case "QUESTIONS ANSWERED":              return "questionmark.bubble"
        case "THE FOUNDATIONS":                 return "square.stack.3d.up"
        case "THE CHAIN":                       return "link"
        case "THE TEXT AND ITS FORGERS":        return "exclamationmark.shield"
        case "THE BOOKS AND THEIR GRADES":      return "books.vertical"
        case "ANSWERING THE DOUBTS":            return "bubble.left.and.bubble.right"
        case "PART 1: DOES GOD EXIST?":         return "sparkles"
        case "PART 2: WHICH RELIGION IS TRUE?": return "signpost.right"
        case "PART 3: WHY ISLAM?":              return "moon.stars"
        case "DOING DAWAH":                     return "person.wave.2"
        default:                                return "doc.text"
        }
    }
}

/// An article to open on top of its index: what a result on the Islam tab's root asks Pillars & Beliefs
/// or the How-to Guides to push as they appear, so the article stacks on its index (Islam \u{203A} Pillars &
/// Beliefs \u{203A} Shahadah) and Back returns to the index, the way a hadith opened from the Hadith tab's
/// search stacks on its book and chapter. `section` lands the page on that heading.
struct IslamArticleOpenRequest: Hashable {
    let id: String
    var section: String? = nil
    /// The section is one only the full article has (a search hit there): open the page in full.
    var long = false
}

enum IslamArticleCatalog {
    private static func entry(_ id: String, _ title: String, _ group: String, _ home: IslamArticleHome,
                              key: String, emphasized: Bool = false, aliases: [String] = []) -> IslamArticleEntry {
        IslamArticleEntry(id: id, title: title, group: group, home: home, debugKey: key,
                          emphasized: emphasized, aliases: aliases)
    }

    private static func group(_ title: String, _ home: IslamArticleHome,
                              _ rows: [(id: String, title: String, key: String, aliases: [String])],
                              emphasized: Bool = false, foldedCount: Int? = nil) -> IslamArticleGroup {
        IslamArticleGroup(title: title, home: home, entries: rows.map {
            entry($0.id, $0.title, title, home, key: $0.key, emphasized: emphasized, aliases: $0.aliases)
        }, foldedCount: foldedCount)
    }

    /// A row of one of the six libraries: a chapter written for it, or an article another home already
    /// has (Pillars & Beliefs, Proving Islam) that the library lists in its reading order too. The
    /// borrowed row keeps its own home and group, so it opens, shares and is cited exactly as before.
    private enum LibraryRow {
        case new(String, String, String, [String])
        case existing(String)
    }

    private static func library(_ title: String, _ home: IslamArticleHome, _ rows: [LibraryRow]) -> IslamArticleGroup {
        IslamArticleGroup(title: title, home: home, entries: rows.compactMap { row in
            switch row {
            case let .new(id, rowTitle, key, aliases):
                return entry(id, rowTitle, title, home, key: key, aliases: aliases)
            case let .existing(id):
                return borrowable[id]
            }
        })
    }

    /// The articles a library may list from the other homes, by id.
    private static let borrowable: [String: IslamArticleEntry] = Dictionary(
        (pillarsGroups + guidesGroups + provingGroups).flatMap(\.entries).map { ($0.id, $0) },
        uniquingKeysWith: { a, _ in a })

    /// Pillars & Beliefs, in the order the index shows them.
    static let pillarsGroups: [IslamArticleGroup] = [
        group("THE BASICS", .pillars, [
            ("GodPillarView", "Does God Exist?", "god", ["existence", "atheism", "creator"]),
            ("IslamPillarView", "What is Islam?", "islam", ["religion", "submission"]),
            ("MuslimPillarView", "What is a Muslim?", "muslim", ["believer", "mumin"]),
            ("AllahPillarView", "Who is Allah \u{FDFB}\u{200E}?", "allah", ["god", "allah"]),
            ("NamesOfAllahPillarView", "The 99 Names of Allah", "names-of-allah",
             ["99 names", "ninety-nine", "asma", "husna", "asma ul husna", "beautiful names", "attributes", "ahsaha"]),
            ("QuranPillarView", "What is the Quran?", "quran", ["koran", "book", "revelation"]),
            // Abu, 2026-11-24: "How do we know the prophet was given the Quran or that Allah gave it to the
            // prophet? Prove just using the Quran then later u can use Hadith."
            ("QuranRevealedPillarView", "How Do We Know Allah Revealed the Quran?", "quran-revealed",
             ["revealed", "revelation", "wahy", "tanzil", "proof of the quran", "is the quran from god", "who wrote the quran",
              "author of the quran", "jibril", "gabriel", "hira", "iqra", "unlettered", "ummi", "challenge", "tahaddi",
              "inspiration", "word of god", "speech of allah"]),
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
        // Abu, 2026-11-24: "add a section called three pillars of tawheed", beside the five pillars of
        // Islam and the six of iman. The scholars' word is aqsam, categories; each is a pillar in that
        // tawhid falls without it.
        group("THE 3 PILLARS OF TAWHID", .pillars, [
            ("RububiyyahView", "Tawhid ar-Rububiyyah (Lordship)", "rububiyyah",
             ["tawheed", "three pillars", "categories of tawhid", "types of tawhid", "lordship", "rabb", "lord",
              "creator", "creation", "khalq", "mulk", "tadbir", "fitrah", "qadariyyah", "amulet", "tamimah",
              "horoscope", "astrology", "fortune teller", "talbiyah of the pagans", "qawaid al-arba"]),
            ("UluhiyyahView", "Tawhid al-Uluhiyyah (Worship)", "uluhiyyah",
             ["tawheed", "three pillars", "categories of tawhid", "worship", "ibadah", "ibaadah", "ilah", "uloohiyyah",
              "uluhiyya", "ikhlas", "sincerity", "intercession", "shafaah", "tawassul", "istighathah", "graves",
              "dua is worship", "vow", "nadhr", "sacrifice", "wadd", "suwa", "two conditions"]),
            ("AsmaSifatView", "Tawhid al-Asma\u{2019} was-Sifat (Names & Attributes)", "asma-sifat",
             ["tawheed", "three pillars", "categories of tawhid", "names and attributes", "asma wa sifat",
              "asma was sifat", "sifat", "attributes", "istiwa", "istawa", "throne", "arsh", "rising", "malik",
              "where is allah", "above the throne", "uluw", "tahrif", "tatil", "takyif", "tamthil", "tafwid",
              "tawil", "hand of allah", "seeing allah", "ruyah", "tadmuriyyah", "qawaid al-muthla"]),
        ]),
        group("THE 25 PROPHETS NAMED IN THE QURAN", .pillars, [
            ("ProphetAdamView", "Adam", "adam", ["first man", "father of mankind"]),
            ("ProphetIdrisView", "Idris", "idris", ["enoch"]),
            ("ProphetNuhView", "Nuh", "nuh", ["noah", "ark", "flood"]),
            ("ProphetHudView", "Hud", "hud", ["aad", "ad", "ahqaf"]),
            ("ProphetSalihView", "Salih", "salih", ["saleh", "thamud", "she-camel", "hijr"]),
            ("ProphetIbrahimView", "Ibrahim", "ibrahim", ["abraham", "khalil", "kabah", "sacrifice"]),
            ("ProphetLutView", "Lut", "lut", ["lot", "sodom"]),
            ("ProphetIsmailView", "Ismail", "ismail", ["ishmael", "zamzam", "hajar"]),
            ("ProphetIshaqView", "Ishaq", "ishaq", ["isaac", "sarah"]),
            ("ProphetYaqubView", "Yaqub / Israil", "yaqub", ["jacob", "israil", "israel", "twelve tribes"]),
            ("ProphetYusufView", "Yusuf", "yusuf", ["joseph", "egypt", "well", "dream"]),
            ("ProphetAyyubView", "Ayyub", "ayyub", ["job", "patience", "illness"]),
            ("ProphetShuaybView", "Shu\u{2019}ayb", "shuayb", ["shuaib", "jethro", "madyan", "midian", "weights", "measures"]),
            ("ProphetMusaView", "Musa", "musa", ["moses", "pharaoh", "firaun", "torah", "tuwa", "staff"]),
            ("ProphetHarunView", "Harun", "harun", ["aaron", "calf"]),
            ("ProphetDhulKiflView", "Dhul-Kifl", "dhulkifl", ["dhu al-kifl", "zulkifl", "ezekiel"]),
            ("ProphetDawudView", "Dawud", "dawud", ["david", "zabur", "psalms", "jalut", "goliath"]),
            ("ProphetSulaymanView", "Sulayman", "sulayman", ["solomon", "sulaiman", "jinn", "sheba", "saba", "hoopoe", "ant"]),
            ("ProphetIlyasView", "Ilyas", "ilyas", ["elias", "elijah", "bal"]),
            ("ProphetAlyasaView", "Alyasa", "alyasa", ["elisha", "al-yasa"]),
            ("ProphetYunusView", "Yunus", "yunus", ["jonah", "whale", "dhun-nun", "nineveh"]),
            ("ProphetZakariyaView", "Zakariya", "zakariya", ["zachariah", "zakariyya"]),
            ("ProphetYahyaView", "Yahya", "yahya", ["john the baptist"]),
            ("ProphetIsaView", "Isa", "isa", ["jesus", "masih", "messiah", "injil", "maryam", "mary"]),
            ("ProphetMuhammadView", "Muhammad", "muhammad-prophet", ["final messenger", "seal of the prophets", "khatam"]),
        // Folded to the first five (Abu, 2026-09-29: "shrink it and have a show more"): all 25 rows
        // pushed the Holy Mosques and everything after them far down the index.
        ], foldedCount: 5),
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
            ("QuranWordsPillarView", "The Words of the Quran", "quran-words",
             ["vocabulary", "quran vocabulary", "common words", "most common words", "word count", "how many words",
              "lemma", "lemmas", "dictionary words", "roots", "jidhr", "learn arabic", "understand the quran",
              "understanding", "tadabbur", "reflect", "meaning", "kalimah"]),
            ("JuzView", "The 30 Juz (Parts)", "juz", ["ajza", "para", "hizb", "parts of the quran"]),
            ("AhrufView", "The 7 Ahruf (Modes)", "ahruf", ["harf", "modes", "seven ahruf"]),
            ("QiraatView", "The 10 Qiraat (Recitations)", "qiraat", ["qiraah", "riwayah", "hafs", "warsh", "readings"]),
            // Abu, 2026-11-24: "do the qiraat contradict?"
            ("QiraatContradictView", "Do the Qiraat Contradict?", "qiraat-contradict",
             ["contradiction", "contradict", "contradictions", "different readings", "different qurans", "variants",
              "variant readings", "ikhtilaf", "tanawwu", "tadadd", "maliki", "maaliki", "arjulakum", "arjulikum",
              "yathurna", "rasm", "ibn al-jazari", "nashr", "4:82"]),
            ("RiwayatDifferencesView", "How the Riwayat Differ on the Page", "riwayat-differences",
             ["hamzah", "hamza", "hamzat al-wasl", "wasl", "madani", "maghribi", "dot", "dots", "imalah", "taqlil",
              "tas-hil", "tashil", "ibdal", "naql", "silah", "warsh", "qalun", "qaloon", "susi", "duri", "abu jafar",
              "hamzah az-zayyat", "kisai", "orthography", "mushaf differences", "dabt",
              "legend", "colors", "color code", "khilaf", "idgham", "sakt", "ishmam", "ghunnah", "tashdid", "bazzi",
              "ibn kathir", "madd al-badal", "tarqiq", "taghlidh", "pronoun ha", "ha dhamir"]),
        ]),
        // Its own group beside the Quran's (Abu, 2026-09-29: "add Hadith sciences ... make that its own
        // link near the Quran stuff like tafsir and seerah").
        group("HADITH & ITS SCIENCES", .pillars, [
            ("HadithSciencesView", "The Sciences of Hadith", "hadith-sciences",
             ["mustalah", "mustalah al-hadith", "ulum al-hadith", "usul al-hadith", "isnad", "matn", "sahih", "hasan",
              "daif", "da'if", "weak", "mawdu", "fabricated", "grading", "grades", "jarh", "tadil", "rijal", "narrators",
              "mutawatir", "ahad", "authentic"]),
            ("HadithPreservationView", "How the Hadith Were Preserved", "hadith-preservation",
             ["compilation", "writing hadith", "tadwin", "six books", "kutub as-sittah", "muwatta", "musnad",
              "umar ibn abd al-aziz", "zuhri", "sahifah", "hammam", "bukhari", "muslim"]),
            ("HadithRejectorsView", "Answering the Hadith Rejectors", "hadith-rejectors",
             ["quranist", "quranists", "quran only", "quran alone", "quraniyyun", "ahl al-quran", "hadith rejector",
              "sunnah rejector", "munkir", "inkar as-sunnah", "parwez", "rashad khalifa"]),
        ]),
        group("THE ISLAMIC CALENDAR", .pillars, [
            ("HijriCalendarView", "Hijri Calendar", "hijri", ["islamic calendar", "lunar", "months", "muharram", "ramadan"]),
            ("SacredMonthsView", "The Sacred Months", "sacred-months", ["ashhur al-hurum", "hurum", "muharram", "rajab", "dhul qadah", "dhul hijjah", "ashura", "nasi", "atirah"]),
            ("MoonSightingView", "Sighting the New Month", "moon-sighting", ["hilal", "crescent", "moon sighting", "ruyah", "new moon", "calculation", "matali", "day of doubt", "eid"]),
        ]),
        group("HISTORICAL & BIOGRAPHICAL", .pillars, [
            ("SeerahView", "The Seerah (Biography)", "seerah", ["sirah", "biography", "life of the prophet", "hijrah", "badr"]),
            ("FarewellView", "The Farewell (Final) Sermon", "farewell", ["khutbah", "arafah", "last sermon"]),
            ("AhlulBaytView", "The Ahlul Bayt (People of the House)", "ahlulbayt", ["ahl al-bayt", "fatimah", "ali", "hasan", "husayn", "family of the prophet"]),
            ("WivesView", "The Wives of the Prophet", "wives", ["khadijah", "aisha", "aishah", "mothers of the believers", "ummahat"]),
            ("SahabahView", "The Sahabah (Companions)", "sahabah", ["companions", "abu bakr", "umar", "uthman", "ali"]),
            ("CaliphatesView", "The Caliphates", "caliphates", ["khilafah", "caliph", "rashidun", "umayyad", "abbasid", "ottoman"]),
            ("MadhabView", "The Madhahib of Fiqh (Schools of Law)", "madhab", ["madhhab", "hanafi", "maliki", "shafii", "hanbali", "fiqh", "jurisprudence"]),
            ("AqeedahMadhabView", "The Madhahib of Aqeedah (Schools of Creed)", "aqeedah", ["aqidah", "creed", "athari", "ashari", "maturidi", "theology", "jahmiyyah", "qadariyyah", "mutazilah", "khawarij"]),
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
            ("TawhidView", "Tawhid: The Oneness of Allah", "tawhid", ["tawheed", "oneness", "monotheism", "la ilaha illa allah",
             "three pillars of tawhid"]),
            ("SalafiyyahView", "What is Salafiyyah?", "salafiyyah", ["salafi", "salafism", "wahhabi", "najd", "ibn abd al-wahhab", "salaf", "dhahabi"]),
            ("QuranSunnahView", "The Quran and the Sunnah", "quransunnah", ["two sources", "revelation", "evidence", "daleel"]),
            ("ShirkView", "Shirk: The Unforgivable Sin", "shirk", ["polytheism", "idolatry", "associating partners", "grave worship"]),
            ("KufrView", "Kufr and What Breaks Islam", "kufr", ["disbelief", "apostasy", "nullifiers", "riddah", "takfir"]),
            ("BidahView", "Bid\u{2019}ah (Innovation)", "bidah", ["bidah", "innovation", "newly invented", "bidah hasanah",
             "good innovation", "shafii", "two kinds of bidah", "four imams", "istihsan"]),
            ("MawlidView", "The Mawlid", "mawlid", ["birthday", "milad", "rabi al-awwal", "celebration"]),
            // What it is and what it is not (Abu, 2026-11-14); the practical side is the How-to guide
            // `EvilEyeGuideView`, and each page opens the other.
            ("EvilEyeView", "The Evil Eye (Al-\u{2018}Ayn)", "evil-eye",
             ["evil eye", "ayn", "al-ayn", "al ayn", "nazar", "hasad", "envy", "jealousy", "ain", "ma sha allah",
              "mashallah", "barakallah", "amulet", "taweez", "tamimah", "blue bead", "nazar bead", "hamsa",
              "hand of fatimah", "superstition", "charm"]),
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
            // Abu, 2026-11-24: "Awrah of men versus women"
            ("AwrahView", "How to Cover the Awrah (Men and Women)", "awrah",
             ["awrah", "aurah", "aurat", "awra", "satr", "cover", "covering", "private parts", "navel", "knee", "thigh",
              "shoulders", "hijab", "niqab", "khimar", "jilbab", "face veil", "veil", "modesty", "mahram", "dress code",
              "clothing", "what to wear", "prayer clothes", "women in prayer"]),
            ("JumuahView", "How to Pray Jumuah", "jumuah", ["friday prayer", "jummah", "juma", "khutbah", "late for jumuah", "eid on friday"]),
            ("KhutbahView", "How to Give the Khutbah", "khutbah", ["khutba", "sermon", "friday sermon", "khatib", "minbar", "khutbat al-hajah", "amma bad", "imam"]),
            ("AdhanOtherView", "How to Give the Adhan", "adhan", ["azan", "call to prayer", "muadhin", "muezzin", "jumuah adhan", "first adhan", "tarji"]),
            ("IqamahView", "How to Give the Iqamah", "iqamah", ["iqama", "second call"]),
        ]),
        group("MORE PRAYERS", .guides, [
            ("RawatibView", "How to Pray the Sunnah Prayers", "rawatib", ["rawatib", "nawafil", "voluntary", "twelve rakah", "before fajr"]),
            ("WitrView", "How to Pray Witr", "witr", ["qunut", "odd", "night", "last prayer"]),
            ("TahajjudView", "How to Pray Tahajjud", "tahajjud", ["night prayer", "qiyam", "qiyam al-layl", "last third"]),
            ("DuhaView", "How to Pray Duha", "duha", ["forenoon", "ishraq", "morning prayer", "chasht"]),
            ("TaraweehView", "How to Pray Taraweeh", "taraweeh", ["tarawih", "ramadan night", "qiyam"]),
            ("JanazahView", "How to Pray the Funeral Prayer", "janazah", ["janaza", "funeral", "death", "burial", "shroud", "kafan", "deceased"]),
            // The prayer and its dua are ONE guide (Abu, 2026-10-25: "merge them into one"); the dua page's
            // aliases live here so "dua istikhara" still lands on it.
            ("IstikharahView", "How to Pray Istikharah", "istikharah", ["istikhara", "salat al-istikhara", "dua istikhara", "istikhara dua", "dua al-istikhara", "allahumma inni astakhiruka", "supplication", "decision", "guidance prayer", "choice"]),
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
            ("RuqyahView", "How to Do Ruqyah", "ruqyah", ["ruqya", "ruqyah shariyyah", "raqi", "healing", "shifa", "cure", "evil eye", "ayn", "nazar", "hasad", "envy", "sihr", "magic", "black magic", "jinn", "possession", "muawwidhat", "amulet", "taweez"]),
            ("EvilEyeGuideView", "How to Deal With the Evil Eye", "evil-eye",
             ["evil eye", "ayn", "al-ayn", "al ayn", "nazar", "hasad", "envy", "jealousy", "ain", "ma sha allah",
              "mashallah", "barakallah", "allahumma barik", "protection", "protect", "cure", "wash", "ghusl of the ain",
              "children", "baby", "newborn", "amulet", "blue bead"]),
        ]),
    ]

    /// The Proving Islam library's chapters, in reading order: how the case works, then the man, the
    /// book, what he could not have known, the message, and the verdict. Adapted from provingislam.net's
    /// "The Complete Case" (Abu, 2026-09-29: "incorporate Proving Islam ... actually use a lot of their
    /// stuff"), in the app's own words and held to its sahih/hasan rule.
    static let provingGroups: [IslamArticleGroup] = [
        group("THE METHOD", .proving, [
            ("ProvingCaseView", "How the Case Works", "case", ["cumulative case", "method", "occam", "evidence", "proof"]),
            ("ProvingFingerprintView", "The Human Fingerprint Test", "fingerprint",
             ["fingerprints", "aristotle", "galen", "ptolemy", "darwin", "errors", "human author"]),
        ]),
        group("THE MESSENGER", .proving, [
            ("ProvingProphetView", "The Prophet\u{2019}s Character", "character",
             ["al-amin", "trustworthy", "safa", "khadijah", "heraclius", "abu sufyan", "motive", "liar", "fraud"]),
            ("ProvingContinuationView", "One Message, Many Messengers", "continuation",
             ["prophets", "messengers", "last brick", "seal of the prophets", "religion of ibrahim", "same message"]),
        ]),
        group("THE BOOK", .proving, [
            ("ProvingStylometryView", "Two Voices: Quran and Hadith", "stylometry",
             ["stylometry", "sayoud", "sadeghi", "style", "author", "authorship"]),
            ("ProvingPreservationView", "Preserved as Promised", "preservation",
             ["preservation", "birmingham", "sanaa", "manuscript", "memorisation", "15:9", "corruption"]),
            ("ProvingIjazView", "The Unmatched Quran", "ijaz",
             ["ijaz", "inimitability", "challenge", "poetry", "walid ibn al-mughirah", "musaylimah", "eloquence"]),
            ("ProvingScienceView", "The Errors It Did Not Make", "science",
             ["science", "scientific", "expanding universe", "orbits", "bees", "iron", "embryo", "water"]),
        ]),
        group("WHAT HE COULD NOT HAVE KNOWN", .proving, [
            ("ProvingProphecyView", "Foretold, and Fulfilled", "prophecy",
             ["prophecy", "prophecies", "byzantines", "abu lahab", "mongols", "falsifiable", "fulfilled"]),
            ("ProvingSourcesView", "Where Could He Have Learned It?", "sources",
             ["borrowing", "arabic bible", "king or pharaoh", "abdullah ibn salam", "copied", "teacher"]),
            ("ProvingBibleView", "The Bible Points Ahead", "bible",
             ["bible", "deuteronomy 18", "isaiah 42", "paraclete", "ishmael", "ismail", "kedar", "cornerstone"]),
            ("ProvingScriptureView", "The Quran and Earlier Scripture", "scripture",
             ["torah", "gospel", "talmud", "midrash", "muhaymin", "parallels", "luke", "earlier scripture"]),
        ]),
        group("THE MESSAGE", .proving, [
            ("ProvingEthicsView", "Justice Beyond the Tribe", "ethics",
             ["justice", "ethics", "law", "4:135", "harvard", "tribalism", "harm"]),
            ("ProvingJesusView", "Jesus in the Gospels", "jesus",
             ["jesus", "isa", "gospels", "trinity", "messiah", "christianity", "prophet jesus"]),
            ("ProvingGodView", "God: The Prior Question", "god",
             ["god", "existence of god", "atheism", "first cause", "fine-tuning", "fitrah", "creator"]),
        ]),
        group("THE VERDICT", .proving, [
            ("ProvingQuestionsView", "Six Hard Questions", "questions", ["questions", "sceptic", "skeptic", "critic"]),
            ("ProvingClosingView", "The Converging Case", "closing", ["conclusion", "closing", "verdict", "invitation"]),
        ]),
    ]

    // BEGIN LIBRARY GROUPS: generated from the libraries' plan (2026-11-24); the order inside a
    // group is reading order, an `.existing` row is a Pillars & Beliefs or Proving Islam page the
    // library lists too.

    /// Stories of the Prophets, in the order its index shows it.
    static let storiesGroups: [IslamArticleGroup] = [
        library("BEFORE THE STORIES", .stories, [
            .new("StoryProphetsView", "Prophets and Messengers", "prophets-and-messengers",
                 ["nabi", "rasul", "anbiya", "rusul", "prophethood", "nubuwwah", "ulul azm", "firm resolve", "ismah", "infallibility", "124000 prophets", "twenty five prophets", "mujizah", "miracles", "scriptures", "suhuf", "zabur", "injil", "tawrah", "o prophet", "seal of the prophets", "khatam an-nabiyyin", "shepherds"]),
            .new("StoryIntroView", "Why the Quran Tells Their Stories", "why",
                 ["qasas", "best of stories", "ahsan al-qasas", "israiliyyat", "israeliyyat", "people of the book", "ibrah", "lessons", "bible", "torah", "sources", "weak stories", "order of the prophets", "chronology", "ibn taymiyyah", "ibn kathir", "repetition"]),
            .new("StoryFamilyView", "One Family: The Prophets\u{2019} Family Tree", "family-tree",
                 ["family tree", "lineage", "genealogy", "nasab", "dhurriyyah", "twelve tribes", "asbat", "tribes of israel", "sons of jacob", "reuben", "levi", "judah", "benjamin", "sam ham yafith", "shem ham japheth", "azar", "terah", "adnan", "quraysh", "hajar", "sarah", "leah", "rachel", "cousins", "israel"]),
            .new("StoryNationsView", "The Peoples They Were Sent To", "nations",
                 ["nations", "peoples", "ad", "aad", "iram", "ahqaf", "thamud", "hijr", "madain salih", "hegra", "sodom", "mutafikat", "madyan", "midian", "aykah", "thicket", "pharaoh", "haman", "qarun", "korah", "nineveh", "ashab ar-rass", "tubba", "saba", "sheba"]),
        ]),
        library("THE FIRST PEOPLE", .stories, [
            .new("StoryAdamView", "Adam", "adam",
                 ["abu al-bashar", "father of mankind", "hawwa", "eve", "iblis", "satan", "khalifah", "successor", "the names", "prostration", "the tree", "garden of eternity", "repentance", "qabil", "habil", "cain", "abel", "shith", "seth", "covenant", "alast", "fitrah", "adamah", "safiyyullah", "bani adam"]),
            .new("StoryIdrisView", "Idris", "idris",
                 ["enoch", "akhnukh", "hanokh", "idrees", "siddiq", "high station", "makanan aliyya", "fourth heaven", "miraj", "hermes", "jared", "methuselah", "israiliyyat", "ka'b al-ahbar"]),
            .new("StoryNuhView", "Nuh", "nuh",
                 ["noah", "noach", "ark", "flood", "deluge", "tufan", "judi", "al-judi", "ararat", "tannur", "wadd", "suwa", "yaghuth", "yauq", "nasr", "950 years", "surah nuh", "grateful servant", "first messenger", "ulul azm", "sam ham yafith", "shem", "japheth", "kanan", "yam"]),
        ]),
        library("THE PROPHETS OF ARABIA", .stories, [
            .new("StoryHudView", "Hud", "hud",
                 ["ad", "aad", "‘ad", "iram", "ahqaf", "al-ahqaf", "barren wind", "dabur", "saba", "east wind", "eber", "abir", "hadramawt", "hood", "surah hud", "envoy of ad", "qayl", "ubar", "sarsar", "cloud", "grey hair", "shayyabatni"]),
            .new("StorySalihView", "Salih", "salih",
                 ["saleh", "thamud", "she-camel", "naqah", "naqat allah", "camel", "hijr", "al-hijr", "madain salih", "mada’in salih", "hegra", "al-ula", "tabuk", "qudar", "nine men", "sayhah", "rajfah", "omen", "tatayyur", "abu zamah"]),
            .new("StoryShuaybView", "Shu\u{2019}ayb", "shuayb",
                 ["shuaib", "shoaib", "shuayb", "jethro", "reuel", "hobab", "madyan", "midian", "aykah", "thicket", "laykah", "al-bad", "scales", "measure", "weights", "mutaffifin", "tatfif", "khatib al-anbiya", "zullah", "old man of madyan", "baqiyyatullah"]),
        ]),
        library("IBRAHIM AND HIS HOUSE", .stories, [
            .new("StoryIbrahimView", "Ibrahim", "ibrahim",
                 ["abraham", "abram", "ibraheem", "khalil", "khalilullah", "al-khalil", "azar", "terah", "sarah", "hajar", "namrud", "nimrod", "fire", "idols", "hanif", "millah", "suhuf", "scrolls of ibrahim", "ur", "babylon", "hebron", "father of the prophets", "four birds", "neither jew nor christian"]),
            .new("StoryLutView", "Lut", "lut",
                 ["lot", "sodom", "sadum", "gomorrah", "mutafikat", "al-mutafikat", "overturned cities", "dead sea", "bahr lut", "qawm lut", "people of lut", "sijjil", "fahishah", "wife of lut", "daughters of lut", "ruknun shadid", "strong support", "haran"]),
            .new("StoryKabahView", "Isma\u{2019}il", "ismail-kabah",
                 ["ismail", "ishmael", "ismael", "yishmael", "hajar", "hagar", "zamzam", "safa", "marwah", "sa'y", "jurhum", "kaaba", "kabah", "sacrifice", "dhabih", "adh-dhabih", "maqam ibrahim", "eid al-adha", "nabit", "qaydar", "kedar", "adnan", "arabs", "hajj"]),
            .new("StoryIshaqView", "Ishaq", "ishaq",
                 ["isaac", "yitzhaq", "yitzhak", "ishak", "sarah", "laughter", "glad tidings", "bushra", "guests of ibrahim", "honoured guests", "rebekah", "rifqa", "esau", "al-is", "edom", "nafilah", "ghulam alim"]),
            .new("StoryYaqubView", "Ya\u{2019}qub / Isra\u{2019}il", "yaqub",
                 ["yaqub", "jacob", "israel", "israil", "isra'il", "bani israil", "children of israel", "twelve tribes", "asbat", "al-asbat", "sabrun jamil", "beautiful patience", "leah", "rachel", "bilhah", "zilpah", "reuben", "judah", "levi", "binyamin", "benjamin", "dinah", "laban", "sciatica", "irq an-nasa"]),
            .new("StoryYusufView", "Yusuf", "yusuf",
                 ["joseph", "yosef", "binyamin", "benjamin", "zulaykha", "zulaikha", "al-aziz", "potiphar", "rachel", "rahil", "eleven stars", "the well", "sabrun jamil", "beautiful patience", "as-siddiq", "ahsan al-qasas", "best of stories", "egypt", "famine", "the shirt", "seven cows", "dream interpretation", "al-karim ibn al-karim", "surah yusuf"]),
        ]),
        library("PATIENCE AND RETURN", .stories, [
            .new("StoryAyyubView", "Ayyub", "ayyub",
                 ["job", "ayub", "iyyov", "patience", "sabr", "awwab", "the spring", "golden locusts", "dighth", "bundle of grass", "oath", "rahmah", "his wife", "illness", "affliction", "worms", "book of job", "hawran", "esau"]),
            .new("StoryYunusView", "Yunus", "yunus",
                 ["jonah", "yonah", "dhun-nun", "dhu an-nun", "sahib al-hut", "companion of the fish", "whale", "the fish", "matta", "amittai", "nineveh", "mosul", "gourd", "yaqtin", "la ilaha illa anta subhanaka", "dua of yunus", "mughadib", "surah yunus", "ibn matta"]),
        ]),
        library("MUSA AND BANI ISRA'IL", .stories, [
            .new("StoryMusaEarlyView", "Musa: From the River to the Fire", "musa-early",
                 ["moses", "moshe", "kalimullah", "burning bush", "tuwa", "madyan", "midian", "staff", "white hand", "basket", "nile", "asiyah", "zipporah", "safura", "jethro", "imran", "amram", "jochebed", "miriam", "levi", "tawrah", "torah", "mount tur", "sinai"]),
            .new("StoryMusaPharaohView", "Musa and Pharaoh", "musa-pharaoh",
                 ["moses", "firaun", "fir'awn", "haman", "magicians", "sorcerers", "asiyah", "believer of pharaoh's family", "nine signs", "plagues", "red sea", "exodus", "ashura", "muharram", "drowning", "egypt", "tower", "istikhfaf"]),
            .new("StoryHarunView", "Harun", "harun",
                 ["aaron", "aharon", "wazir", "minister", "golden calf", "samiri", "sister of harun", "ukht harun", "safiyyah", "ali", "tabuk", "manzilah", "fifth heaven", "mount hor", "elisheba", "eleazar", "priesthood", "levi", "ibn umm"]),
            .new("StoryWildernessView", "Bani Isra\u{2019}il in the Wilderness", "wilderness",
                 ["children of israel", "bani israel", "golden calf", "samiri", "tih", "wandering", "forty years", "manna", "quails", "mann", "salwa", "twelve springs", "tablets", "seventy", "see allah", "cow", "baqarah", "qarun", "korah", "yusha", "joshua", "hittah", "red sand hill", "death of musa"]),
            .new("StoryKhidrView", "Musa and al-Khidr", "khidr",
                 ["khadir", "al-khadir", "khizr", "two seas", "majma al-bahrayn", "fish", "yusha", "joshua", "ship", "boy", "wall", "orphans", "ilm ladunni", "kahf", "surah kahf", "is khidr alive", "patience", "knowledge"]),
        ]),
        library("THE KINGS AND PROPHETS OF BANI ISRA'IL", .stories, [
            .new("StoryDawudView", "Dawud", "dawud",
                 ["david", "dawood", "daud", "zabur", "psalms", "talut", "saul", "jalut", "goliath", "armour", "chain mail", "iron", "mountains and birds", "awwab", "khalifah", "fast of dawud", "prayer of dawud", "sajdah sad", "two litigants", "jesse", "judah", "bathsheba", "tel dan"]),
            .new("StorySulaymanView", "Sulayman", "sulayman",
                 ["solomon", "sulaiman", "suleiman", "shelomoh", "ant", "naml", "hoopoe", "hudhud", "sheba", "saba", "bilqis", "queen of sheba", "throne", "jinn", "ifrit", "wind", "harut", "marut", "magic", "staff", "horses", "bayt al-maqdis", "two mothers", "in sha allah"]),
            .new("StoryIlyasView", "Ilyas", "ilyas",
                 ["elijah", "elias", "ilyaas", "eliyahu", "baal", "ba'l", "il yasin", "al yasin", "baalbek", "ahab", "jezebel", "carmel", "tishbite", "khidr", "still alive", "chariot of fire"]),
            .new("StoryAlyasaView", "al-Yasa\u{2019}", "alyasa",
                 ["elisha", "alyasa", "al-yasa", "yasa", "al-laysa", "laysa", "elisha son of shaphat", "successor of ilyas", "akhyar", "faddalna", "banyas", "mantle"]),
            .new("StoryDhulKiflView", "Dhul-Kifl", "dhul-kifl",
                 ["dhul kifl", "zul kifl", "dhu al-kifl", "zulkifli", "kifl", "al-kifl", "ezekiel", "hizqil", "bishr", "pledge", "patient", "sabirin", "akhyar", "tomb of dhul kifl"]),
        ]),
        library("THE LAST OF BANI ISRA'IL", .stories, [
            .new("StoryZakariyyaView", "Zakariyya", "zakariyya",
                 ["zakariya", "zakaria", "zechariah", "zacharias", "zekharyah", "carpenter", "mihrab", "prayer chamber", "guardian of maryam", "casting of pens", "lots", "kafalah", "barren wife", "elisabeth", "isha", "heir", "three nights silence", "sign of silence", "private supplication", "bayt al-maqdis", "yahya father"]),
            .new("StoryYahyaView", "Yahya", "yahya",
                 ["john", "john the baptist", "yuhanna", "yohanan", "baptist", "hasur", "sayyid", "samiyy", "hanan", "five commands", "five words", "cousins", "sons of maternal aunts", "second heaven", "herod", "salome", "son of zakariyya", "chaste", "wisdom as a child"]),
            .new("StoryMaryamView", "Maryam", "maryam",
                 ["mary", "mariam", "miriam", "virgin mary", "mother of jesus", "imran", "hannah", "anne", "wife of imran", "sister of harun", "sister of aaron", "siddiqah", "batul", "palm tree", "annunciation", "jibril", "mihrab", "muharrar", "best of women", "surah maryam", "joseph", "najran"]),
            .new("StoryIsaView", "Isa", "isa",
                 ["jesus", "yeshua", "yasu", "messiah", "al-masih", "christ", "son of maryam", "ibn maryam", "kalimah", "word of allah", "ruh", "injil", "gospel", "disciples", "hawariyyun", "table", "maidah", "crucifixion", "not crucified", "raised", "second coming", "return of jesus", "dajjal", "damascus", "trinity"]),
        ]),
        library("THE SEAL OF THE PROPHETS", .stories, [
            .new("StoryMuhammadView", "Muhammad ﷺ", "muhammad",
                 ["muhammad", "mohammed", "ahmad", "al-mahi", "al-hashir", "al-aqib", "abu al-qasim", "khatam an-nabiyyin", "seal of the prophets", "ummi", "quraysh", "banu hashim", "abdullah", "aminah", "abd al-muttalib", "abu talib", "khadijah", "fatimah", "ibrahim son of the prophet", "waraqah", "rahmatan lil alamin", "surah muhammad"]),
            .existing("SeerahView"),
            .existing("ProphetMuhammadView"),
        ]),
        library("BEYOND THE QURAN", .stories, [
            .new("StoryIsraeliyyatView", "Prophets Named Only Outside the Quran", "beyond-the-quran",
                 ["israiliyyat", "israeliyyat", "joshua", "yusha ibn nun", "samuel", "shamwil", "seth", "shith", "daniel", "danyal", "tustar", "jeremiah", "irmiya", "isaiah", "ezekiel", "hizqil", "uzayr", "ezra", "khidr", "luqman", "dhul-qarnayn", "talut", "tubba", "khalid ibn sinan", "unnamed prophets"]),
        ]),
    ]

    /// Sahabah, Ahlul Bayt & Salaf, in the order its index shows it.
    static let companionsGroups: [IslamArticleGroup] = [
        library("WHO THEY ARE", .companions, [
            .new("CompanionsIntroView", "Who Are the Sahabah?", "who",
                 ["sahabi", "sahaba", "companions", "ashab", "adalah", "udul", "best generation", "qarn", "salaf", "muhajirun", "ansar", "badr", "ahl badr", "bayat ar-ridwan", "pledge of ridwan", "hudaybiyah", "people of the tree", "do not revile my companions", "mujtahid", "camel", "siffin", "hawd", "usayhabi", "rafidah", "muawiyah"]),
            .existing("SahabahView"),
            .existing("AhlusSunnahView"),
        ]),
        library("THE RIGHTLY GUIDED CALIPHS", .companions, [
            .new("CompanionAbuBakrView", "Abu Bakr as-Siddiq", "abu-bakr",
                 ["abubakar", "siddiq", "siddique", "atiq", "abdullah ibn uthman", "abu quhafah", "cave of thawr", "thani ithnayn", "hijrah", "ibn ad-daghinah", "bilal", "khalil", "saqifah", "banu saidah", "khalifat rasul allah", "riddah", "ridda wars", "apostasy wars", "musaylimah", "yamamah", "usamah", "mistah"]),
            .new("CompanionUmarView", "Umar ibn al-Khattab", "umar",
                 ["omar", "farooq", "faruq", "al-faruq", "abu hafs", "amir al-muminin", "muhaddath", "agreements with revelation", "diwan", "hijri calendar", "qadisiyyah", "yarmuk", "jerusalem", "al-quds", "year of ashes", "ramadah", "amwas", "abu lulu", "tarawih", "black stone", "sasanian", "kisra"]),
            .new("CompanionUthmanView", "Uthman ibn Affan", "uthman",
                 ["usman", "othman", "osman", "dhun-nurayn", "dhul nurain", "two lights", "ruqayyah", "umm kulthum", "well of rumah", "bir rumah", "army of hardship", "jaysh al-usrah", "tabuk", "mushaf", "uthmani mushaf", "hudhayfah", "zayd ibn thabit", "day of the house", "yawm ad-dar", "siege", "al-walid ibn uqbah", "banu umayyah"]),
            .new("CompanionAliView", "Ali ibn Abi Talib", "ali",
                 ["aly", "imam ali", "abu turab", "abu al-hasan", "abu talib", "fatimah", "khaybar", "banner", "harun", "aaron", "tabuk", "ghadir khumm", "mawla", "man kuntu mawlahu", "thaqalayn", "yemen", "khawarij", "kharijites", "haruriyyah", "nahrawan", "ibn muljam", "kufah", "nawasib", "city of knowledge"]),
            .existing("CaliphatesView"),
        ]),
        library("PROMISED PARADISE", .companions, [
            .new("CompanionTenView", "The Ten Promised Paradise", "the-ten",
                 ["ashara mubashshara", "asharah mubashsharah", "mubashsharun", "ten promised jannah", "talha", "talhah ibn ubaydullah", "zubair", "zubayr ibn al-awwam", "abdur rahman ibn auf", "abd al-rahman ibn awf", "saad ibn abi waqqas", "sa'd", "said ibn zayd", "saeed ibn zaid", "abu ubaidah", "abu ubaydah ibn al-jarrah", "amin of this ummah", "hawari", "shura", "bilal", "thabit ibn qays", "ukkashah", "abdullah ibn salam", "qadisiyyah", "amwas plague"]),
        ]),
        library("AHLUL BAYT: THE PROPHET'S HOUSEHOLD", .companions, [
            .new("CompanionKhadijahAishahView", "Khadijah and A\u{2019}ishah", "khadijah-aishah",
                 ["khadija", "khadijah bint khuwaylid", "aisha", "aishah", "ayesha", "aisha bint abi bakr", "mothers of the believers", "umm al-muminin", "ummahat al-muminin", "ifk", "slander", "surah an-nur", "hira", "waraqah", "house of qasab", "tharid", "battle of the camel", "jamal", "year of sorrow", "wives of the prophet"]),
            .new("CompanionFatimahView", "Fatimah, al-Hasan and al-Husayn", "fatimah",
                 ["fatima", "fatimah az-zahra", "zahra", "hasan", "hussain", "husain", "husayn ibn ali", "ahl al-kisa", "people of the cloak", "hadith al-kisa", "mubahalah", "ayah of purification", "karbala", "ashura", "muharram", "yazid", "zayn al-abidin", "year of unity", "am al-jamaah", "leaders of the youth of paradise", "sayyidat nisa ahl al-jannah", "tasbih fatimah"]),
            .new("CompanionUnclesView", "Hamzah, al-Abbas and Ja\u{2019}far", "hamzah-abbas",
                 ["hamza", "hamzah ibn abd al-muttalib", "sayyid ash-shuhada", "leader of the martyrs", "wahshi", "uhud", "abbas", "al-abbas ibn abd al-muttalib", "istisqa", "rain prayer", "tawassul", "jafar", "jafar ibn abi talib", "jafar at-tayyar", "dhul-janahayn", "two wings", "mutah", "negus", "najashi", "abyssinia", "habasha", "abu talib", "abu lahab", "surah al-masad", "uncles of the prophet"]),
            .existing("AhlulBaytView"),
            .existing("WivesView"),
        ]),
        library("COMPANIONS OF NOTE", .companions, [
            .new("CompanionFirstBelieversView", "The First Believers and the First Martyrs", "first-believers",
                 ["bilal", "ahad ahad", "ammar ibn yasir", "yasir", "sumayyah", "sumayya", "first martyr", "khabbab", "musab ibn umayr", "mus'ab", "abu dharr", "ghifar", "suhayb", "miqdad", "abyssinia", "habasha", "najashi", "negus", "people of the ship", "siffin", "transgressing party", "sabiqun", "early muslims", "persecution"]),
            .new("CompanionAbuHurayrahView", "Abu Hurayrah and the Narrators", "abu-hurayrah",
                 ["abu huraira", "abu hurairah", "abd ar-rahman ibn sakhr", "daws", "dawsi", "suffah", "ahl as-suffah", "mukthirun", "most hadith", "narrators", "ibn umar", "anas ibn malik", "jabir ibn abdullah", "abu said al-khudri", "ibn abbas", "hammam ibn munabbih", "sahifah", "abu rayyah", "goldziher", "orientalists", "adalah", "kitten"]),
            .new("CompanionWomenView", "The Women Companions", "women",
                 ["sahabiyat", "sahabiyyah", "female companions", "umm salamah", "hudaybiyah", "asma bint abi bakr", "two belts", "dhat an-nitaqayn", "umm sulaym", "umm haram", "cyprus", "ash-shifa", "umm atiyyah", "umm ayman", "barakah", "asma bint umays", "umm kulthum bint uqbah", "khawlah", "mujadilah", "pledge of the women", "rubayyi", "umm umarah", "al-hajjaj"]),
            .existing("SahabahScholarsView"),
        ]),
        library("THE SALAF AFTER THEM", .companions, [
            .new("CompanionTabiunView", "The Tabi\u{2019}un", "tabiun",
                 ["tabiun", "tabi'un", "tabiin", "tabi'in", "successors", "uways al-qarani", "uwais", "said ibn al-musayyib", "hasan al-basri", "ibn sirin", "mujahid", "said ibn jubayr", "umar ibn abd al-aziz", "zuhri", "urwah ibn az-zubayr", "atba at-tabiin", "sufyan ath-thawri", "awzai", "layth ibn sad", "ibn al-mubarak", "mujaddid", "renewer", "mukhadram", "hajjaj"]),
            .new("CompanionFourImamsView", "The Four Imams", "four-imams",
                 ["abu hanifa", "abu hanifah", "imam malik", "malik ibn anas", "shafii", "ash-shafi'i", "imam shafi", "ahmad ibn hanbal", "imam ahmad", "hanafi", "maliki", "shafi'i school", "hanbali", "madhhab", "madhab", "muwatta", "risalah", "musnad ahmad", "mihnah", "created quran", "khalq al-quran", "usul al-fiqh", "taqlid", "golden chain"]),
            .existing("SalafScholarsView"),
            .existing("SalafiyyahView"),
        ]),
    ]

    /// Refuting Religions, in the order its index shows it.
    static let religionsGroups: [IslamArticleGroup] = [
        library("THE METHOD", .religions, [
            .new("ReligionsMethodView", "How the Quran Argues With Other Faiths", "method",
                 ["dawah", "debate", "jadal", "hikmah", "mubahalah", "munazarah", "hujjah", "burhan", "dialogue", "interfaith", "heraclius", "najran", "people of the book", "ahl al-kitab", "common word", "ibrahim", "abraham", "namrud", "nimrod", "al-jawab as-sahih", "hidayat al-hayara", "ibn taymiyyah", "ibn al-qayyim", "apologetics"]),
            .new("ReligionsOneView", "One Religion From Adam to Muhammad", "one-religion",
                 ["islam", "submission", "tawhid", "hanif", "hunafa", "din", "shariah", "shirah", "minhaj", "brothers", "allat", "covenant of the prophets", "mithaq", "primordial monotheism", "fitrah", "wadd", "suwa", "yaqub", "jacob", "abraham", "millah", "name muslim", "mohammedan", "noah"]),
            .new("ReligionsPluralismView", "Are All Religions the Same?", "pluralism",
                 ["religious pluralism", "perennialism", "perennial philosophy", "traditionalism", "john hick", "schuon", "guenon", "elephant", "many paths", "unity of religions", "wahdat al-adyan", "interfaith", "salvation", "exclusivism", "2:62", "5:69", "sabians", "ahl al-fatrah", "people of the interval", "message never reached", "la ikraha", "al-kafirun", "lakum dinukum", "permanent committee", "abrahamic"]),
        ]),
        library("THE PEOPLE OF THE BOOK", .religions, [
            .existing("ChristianityAnswerView"),
            .existing("JudaismAnswerView"),
        ]),
        library("THE RELIGIONS OF THE EAST", .religions, [
            .existing("HinduismAnswerView"),
            .existing("BuddhismAnswerView"),
            .new("ReligionsSikhismView", "Answering Sikhism", "sikhism",
                 ["sikh", "sikhs", "guru nanak", "nanak", "guru granth sahib", "adi granth", "khalsa", "gurdwara", "waheguru", "ik onkar", "mool mantar", "guru gobind singh", "guru arjan", "punjab", "langar", "reincarnation", "rebirth", "karma", "five ks", "amritsar", "golden temple", "baba farid"]),
            .new("ReligionsZoroastrianismView", "Answering Zoroastrianism", "zoroastrianism",
                 ["zoroaster", "zarathustra", "zoroastrian", "majus", "magians", "magi", "parsi", "parsis", "ahura mazda", "ahriman", "angra mainyu", "avesta", "gathas", "fire temple", "fire worship", "dualism", "chinvat bridge", "persia", "kisra", "salman al-farisi", "nowruz", "jizyah"]),
            .new("ReligionsEastAsiaView", "Answering Confucianism, Taoism and Shinto", "east-asia",
                 ["confucius", "confucian", "kongzi", "analects", "tian", "taoism", "daoism", "laozi", "lao tzu", "tao te ching", "wu wei", "shinto", "kami", "amaterasu", "japanese emperor", "ancestor worship", "ancestors", "china", "japan", "hui", "zheng he", "immortality", "yin yang"]),
        ]),
        library("WITHOUT GOD OR WITHOUT REVELATION", .religions, [
            .existing("AtheismAnswerView"),
            .existing("PaganismAnswerView"),
            .new("ReligionsSecularismView", "Answering Secular Humanism and Liberalism", "secularism",
                 ["secularism", "secular", "humanism", "liberalism", "liberal", "almaniyyah", "ilmaniyyah", "mill", "harm principle", "locke", "rawls", "hume", "is ought", "nietzsche", "autonomy", "freedom", "liberty", "hawa", "desire", "ubudiyyah", "tashri", "legislation", "hukm", "man-made law", "neutrality"]),
        ]),
        library("NEW PROPHETS AND SECTS", .religions, [
            .new("ReligionsNewProphetsView", "Answering the Ahmadiyyah, the Baha\u{2019}is and the Nation of Islam", "new-prophets",
                 ["ahmadiyya", "ahmadi", "qadiani", "qadiyani", "lahori", "mirza ghulam ahmad", "bahai", "baha'i", "bahaullah", "the bab", "kitab-i-aqdas", "nation of islam", "elijah muhammad", "wallace fard", "farrakhan", "malcolm x", "seal of the prophets", "khatam an-nabiyyin", "false prophet", "promised messiah", "mahdi", "yuz asaf"]),
            .existing("ShiaAnswerView"),
            .existing("SufismAnswerView"),
            .existing("HadithRejectorsView"),
        ]),
    ]

    /// Preservation of the Quran, in the order its index shows it.
    static let preservationGroups: [IslamArticleGroup] = [
        library("HOW IT CAME DOWN", .preservation, [
            .existing("QuranRevealedPillarView"),
            .new("PreservationStagesView", "Revealed in Stages", "stages",
                 ["tanjim", "asbab an-nuzul", "occasions of revelation", "laylat al-qadr", "night of decree", "first revelation", "iqra", "hira", "last verse", "last ayah", "makki", "madani", "makkan", "madinan", "meccan", "medinan", "wine prohibition", "khamr", "fatrah", "bayt al-izzah", "jibril", "gabriel", "wahy"]),
        ]),
        library("KEPT IN HEARTS AND ON PAGES", .preservation, [
            .new("PreservationMemoryView", "Preserved in the Hearts", "memory",
                 ["hifz", "hifdh", "hafiz", "huffaz", "memorisation", "memorization", "qurra", "reciters", "ijazah", "sanad", "chain of recitation", "talaqqi", "mu'aradah", "final review", "ardah", "bir maunah", "yamamah", "ubayy ibn kab", "ibn masud", "asim", "hafs", "as-sulami"]),
            .new("PreservationWritingView", "Written in His Lifetime", "writing",
                 ["scribes of revelation", "kuttab al-wahy", "zayd ibn thabit", "katib", "writing the quran", "parchment", "palm stalks", "shoulder blade", "usub", "likhaf", "riqa", "do not write from me", "writing hadith", "suhuf", "mushaf", "muawiyah", "hanzalah", "abu shah", "two covers", "daffatayn"]),
            .existing("CompileView"),
            .new("PreservationOrderView", "The Order of the Ayat and Surahs", "order",
                 ["tartib", "arrangement", "sequence", "surah order", "ayah order", "tawqifi", "order of revelation", "chronological order", "mufassal", "mathani", "seven long surahs", "tiwal", "miun", "at-tawbah", "basmalah", "bismillah", "surah 9", "ayah count", "munasabah", "ibn az-zubayr", "ibn masud mushaf"]),
        ]),
        library("THE MUSHAF ACROSS THE CENTURIES", .preservation, [
            .new("PreservationScriptView", "Dots, Vowels and the Uthmani Script", "script",
                 ["rasm", "uthmani rasm", "i'jam", "ijam", "naqt", "tashkil", "harakat", "abu al-aswad ad-duali", "duali", "al-khalil ibn ahmad", "farahidi", "nasr ibn asim", "yahya ibn yamur", "al-muqni", "ad-dani", "juz", "hizb", "ayah numbers", "madinah mushaf", "king fahd complex", "uthman taha", "cairo 1924", "diacritics", "quran spelling"]),
            .new("PreservationManuscriptsView", "The Oldest Manuscripts", "manuscripts",
                 ["birmingham quran", "mingana", "tubingen", "tübingen", "radiocarbon", "carbon dating", "sanaa palimpsest", "sana'a", "codex parisino-petropolitanus", "deroche", "topkapi", "samarkand", "tashkent", "uthman's mushaf", "hijazi script", "kufic", "corpus coranicum", "bergstrasser", "van putten", "wansbrough", "parchment", "palimpsest"]),
            .existing("AhrufView"),
            .existing("QiraatView"),
            .existing("QiraatContradictView"),
        ]),
        library("QUESTIONS ANSWERED", .preservation, [
            .new("PreservationNaskhView", "Abrogation (Naskh)", "naskh",
                 ["abrogation", "nasikh", "mansukh", "abrogated verses", "2:106", "verse of stoning", "rajm", "ten sucklings", "five sucklings", "qiblah change", "bada", "bada'", "takhsis", "verse of the sword", "widow's waiting period", "bir maunah", "abrogated recitation", "lifted verses"]),
            .new("PreservationClaimsView", "Answering the Claims of Corruption", "claims",
                 ["tahrif", "corruption of the quran", "ibn masud", "mu'awwidhatayn", "muawwidhatayn", "al-falaq", "an-nas", "ubayy ibn kab", "qunut", "al-khal", "al-hafd", "uthman burned the mushafs", "goat ate the verses", "sheep ate", "surah al-ahzab", "fasl al-khitab", "al-kafi", "nuri tabarsi", "hajjaj", "shia quran", "missing verses", "surat al-wilayah"]),
            .existing("ProvingPreservationView"),
        ]),
    ]

    /// Science of Hadith, in the order its index shows it.
    static let hadithScienceGroups: [IslamArticleGroup] = [
        library("THE FOUNDATIONS", .hadithScience, [
            .existing("HadithPillarView"),
            .existing("HadithSciencesView"),
            .new("HadithScienceTermsView", "The Terms of Hadith", "terms",
                 ["mustalah", "glossary", "terminology", "marfu", "mawquf", "maqtu", "qudsi", "musnad", "muttasil", "thulathiyyat", "musalsal", "aziz", "gharib", "mashhur", "mutabaah", "shahid", "shadh", "munkar", "mudraj", "maqlub", "mudtarib", "musahhaf", "haddathana", "akhbarana", "hasan sahih"]),
        ]),
        library("THE CHAIN", .hadithScience, [
            .new("HadithScienceBreaksView", "When the Chain Breaks", "breaks",
                 ["muallaq", "mursal", "munqati", "mudal", "tadlis", "mudallis", "ananah", "mursal khafi", "taliq", "taghliq", "broken chain", "missing link", "hisham ibn ammar", "maazif", "baqiyyah", "abu az-zubayr", "mustakhraj", "ibn ishaq", "taswiyah", "marasil"]),
            .new("HadithScienceRijalView", "The Narrators and Their Critics", "rijal",
                 ["rijal", "jarh", "tadil", "jarh wa tadil", "adalah", "dabt", "thiqah", "saduq", "taqrib", "tahdhib", "mizan", "ibn hajar", "dhahabi", "ibn main", "shubah", "yahya al-qattan", "ibn abi hatim", "narrator criticism", "backbiting", "mukhtalit", "innovators"]),
            .new("HadithScienceAhadView", "Mutawatir, Ahad and Belief", "ahad",
                 ["khabar al-wahid", "single narrator", "single report", "aqidah", "creed", "tawatur", "mutawatir lafzi", "mutawatir manawi", "kalam", "mutazilah", "zann", "certainty", "risalah", "ibn al-qayyim", "sawaiq", "albani", "talaqqi bil-qabul", "quba qiblah", "muadh yemen", "fatimah bint qais"]),
        ]),
        library("THE TEXT AND ITS FORGERS", .hadithScience, [
            .new("HadithScienceFabricationView", "Fabrication, and How It Was Caught", "fabrication",
                 ["mawdu", "mawdoo", "forged hadith", "fake hadith", "fabricated hadith", "whoever lies about me", "seek knowledge even in china", "love of the homeland", "ink of the scholar", "differing of my ummah is a mercy", "lawlaka", "al-manar al-munif", "ibn al-jawzi", "al-mawdu'at", "silsilah ad-da'ifah", "zindiq", "zanadiqah", "storytellers", "khaybar document", "check before sharing"]),
            .new("HadithScienceQudsiView", "Hadith Qudsi", "qudsi",
                 ["sacred hadith", "divine hadith", "hadith ilahi", "hadith rabbani", "40 hadith qudsi", "forty hadith qudsi", "o my servants", "i have forbidden oppression", "as my servant thinks of me", "wali", "friend of allah", "descent of allah", "last third of the night", "fatihah divided", "i was sick and you did not visit me", "hidden treasure", "kuntu kanzan", "allah says", "hadith nabawi"]),
        ]),
        library("THE BOOKS AND THEIR GRADES", .hadithScience, [
            .existing("HadithPreservationView"),
            .new("HadithScienceGradesView", "How to Read a Hadith\u{2019}s Grade", "grades",
                 ["grading", "sahih", "hasan", "daif", "da'if", "hasan sahih", "li-ghayrihi", "isnad sahih", "albani", "shuayb al-arnaut", "zubair ali zai", "ahmad shakir", "darussalam", "bashar awad maruf", "weak hadith in virtues", "fadail al-amal", "sunan", "authenticity", "hadith numbering", "tirmidhi"]),
        ]),
        library("ANSWERING THE DOUBTS", .hadithScience, [
            .existing("HadithRejectorsView"),
            .new("HadithScienceOrientalistsView", "Goldziher, Schacht and the Western Critics", "orientalists",
                 ["orientalism", "orientalists", "mustashriq", "juynboll", "common link", "madar", "azami", "al-azami", "motzki", "schoeler", "sezgin", "nabia abbott", "hammam ibn munabbih", "sahifah", "sibai", "isnad-cum-matn", "argument from silence", "backward growth", "zuhri", "three mosques"]),
        ]),
    ]

    /// The Domino Process, in the order its index shows it.
    static let dominoGroups: [IslamArticleGroup] = [
        library("THE METHOD", .domino, [
            .new("DominoIntroView", "The Domino Process", "process",
                 ["domino", "domino effect", "seven dominoes", "dawah", "da'wah", "method", "proving islam", "why are you muslim", "basirah", "yaqin", "certainty", "aql", "reason", "steelman", "how we argue", "private evidence", "al imran", "3:190", "afala taqilun", "workshop"]),
        ]),
        library("PART 1: DOES GOD EXIST?", .domino, [
            .new("DominoRealityView", "Dominoes 1 and 2: Something Exists, Something Is Necessary", "reality",
                 ["contingency", "contingent", "necessary being", "necessary existent", "wajib al-wujud", "mumkin al-wujud", "cosmological argument", "kalam", "ibn sina", "avicenna", "first cause", "infinite regress", "borrowed book", "big bang", "52:35", "surat at-tur", "al-ghani", "al-awwal", "something from nothing", "quantum vacuum", "tahawi"]),
            .new("DominoCreatorView", "Domino 3: An Intelligent Creator", "creator",
                 ["design", "fine-tuning", "fine tuning", "cosmological constant", "chance", "randomness", "takhsis", "particularization", "consciousness", "hard problem", "chalmers", "nagel", "plantinga", "wigner", "mathematics", "attributes of allah", "iradah", "hikmah", "al-ghazali", "bedouin"]),
            .new("DominoOneView", "Domino 4: Only One", "one",
                 ["oneness", "tawhid", "monotheism", "polytheism", "two gods", "dualism", "manichaeism", "tamanu", "mutual hindrance", "21:22", "23:91", "ikhlas", "surah al-ikhlas", "as-samad", "ahad", "fitrah", "ikrimah", "rububiyyah", "uluhiyyah", "hanif"]),
            .new("DominoWorldviewsView", "Atheism, Agnosticism and Deism", "worldviews",
                 ["atheist", "agnostic", "deist", "naturalism", "materialism", "who created god", "multiverse", "god of the gaps", "problem of evil", "suffering", "divine hiddenness", "schellenberg", "huxley", "thomas paine", "watchmaker", "burden of proof", "pair exercise", "did god speak"]),
        ]),
        library("PART 2: WHICH RELIGION IS TRUE?", .domino, [
            .new("DominoRevelationView", "Domino 5: Has the Creator Spoken?", "revelation",
                 ["deism", "deist", "revelation", "wahy", "risalah", "prophethood", "messengers", "purpose of life", "watchmaker", "voltaire", "thomas paine", "is reason enough", "silent god", "why did god send prophets", "suda", "hujjah", "23:115", "75:36", "4:165", "17:15"]),
            .new("DominoTestView", "Domino 6: Testing Every Claim", "test",
                 ["which religion is true", "comparative religion", "criteria for revelation", "heraclius", "abu sufyan", "buddhism", "jainism", "taoism", "confucianism", "polytheism", "zeus", "hinduism", "judaism", "noahide laws", "zoroastrianism", "druze", "sikhism", "bahai", "ahmadiyya", "nation of islam", "seal of the prophets", "khatam an-nabiyyin", "rububiyyah", "uluhiyyah"]),
        ]),
        library("PART 3: WHY ISLAM?", .domino, [
            .new("DominoChristianityView", "Christianity Tested", "christianity",
                 ["jesus", "isa", "trinity", "crucifixion", "cross", "bible", "gospels", "new testament", "nicaea", "paul", "james", "ebionites", "atonement", "original sin", "john 10:30", "john 1:1", "shubbiha lahum", "4:157", "injil", "nasara", "gospel of barnabas", "swoon theory", "1 john 5:7", "canon"]),
            .new("DominoIslamView", "Domino 7: Islam", "islam",
                 ["shahadah", "why islam", "preservation of the quran", "birmingham manuscript", "qiraat", "challenge of the quran", "tahaddi", "ijaz", "jubayr ibn mutim", "prophecies", "romans", "abu lahab", "adi ibn hatim", "al-ikhlas", "seven dominoes", "4:82", "15:9", "becoming muslim", "yaqin", "ikhtilaf"]),
        ]),
        library("DOING DAWAH", .domino, [
            .new("DominoDawahView", "Say This, Not That", "dawah",
                 ["dawah", "da'wah", "how to give dawah", "adab", "debate", "jidal", "hikmah", "basirah", "balagh", "16:125", "28:56", "convey from me even one ayah", "red camels", "i don't know", "doubts", "roleplay", "exercises", "common mistakes", "talking to christians", "overclaiming"]),
        ]),
    ]

    static let libraryGroups: [IslamArticleGroup] = storiesGroups + companionsGroups + religionsGroups + preservationGroups + hadithScienceGroups + dominoGroups
    // END LIBRARY GROUPS

    static func groups(for home: IslamArticleHome) -> [IslamArticleGroup] {
        switch home {
        case .pillars: return pillarsGroups
        case .guides: return guidesGroups
        case .proving: return provingGroups
        case .stories: return storiesGroups
        case .companions: return companionsGroups
        case .religions: return religionsGroups
        case .preservation: return preservationGroups
        case .hadithScience: return hadithScienceGroups
        case .domino: return dominoGroups
        }
    }

    /// Every article once, under the home that owns it: a library's borrowed rows are counted where
    /// they live.
    static let all: [IslamArticleEntry] = (pillarsGroups + guidesGroups + provingGroups).flatMap(\.entries)
        + libraryGroups.flatMap { group in group.entries.filter { $0.home == group.home } }

    /// The article ids each home LISTS, its own and the ones it borrows: what a search scoped to that
    /// home covers (`covers`), so Refuting Religions' search finds Answering Christianity.
    static let members: [IslamArticleHome: Set<String>] = Dictionary(uniqueKeysWithValues: IslamArticleHome.allCases.map { home in
        (home, Set(groups(for: home).flatMap { $0.entries.map(\.id) }))
    })

    /// The article ids in each group, by the group's id ("religions/THE PEOPLE OF THE BOOK"): what the
    /// Topics filter admits (`IslamSearchFilters.admits`), borrowed rows included.
    static let groupMembers: [String: Set<String>] = Dictionary(
        IslamArticleHome.allCases.flatMap(groups(for:)).map { ($0.id, Set($0.entries.map(\.id))) },
        uniquingKeysWith: { a, b in a.union(b) })

    /// Whether a search over `homes` reaches this article: its own home, or a library that lists it.
    static func covers(_ homes: Set<IslamArticleHome>, _ entry: IslamArticleEntry) -> Bool {
        homes.contains(entry.home) || homes.contains { members[$0]?.contains(entry.id) == true }
    }

    static let byID: [String: IslamArticleEntry] = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

    private static let byLinkKey: [String: IslamArticleEntry] = Dictionary(all.map { ($0.linkKey.lowercased(), $0) }, uniquingKeysWith: { a, _ in a })

    /// The article a shared link names: its `linkKey`, or the catalog id itself ("ShahadahView"),
    /// which a hand-written link may carry. Case is ignored: a link is retyped and autocorrected.
    static func entry(linkKey: String) -> IslamArticleEntry? {
        byLinkKey[linkKey.lowercased()] ?? byID[linkKey] ?? all.first { $0.id.caseInsensitiveCompare(linkKey) == .orderedSame }
    }

    /// Index position per article id (result order) and the folded title+group+aliases haystack per
    /// id: both used to be rebuilt on every keystroke (Performance Guide, Phase 6 step 10).
    static let order: [String: Int] = Dictionary(all.enumerated().map { ($1.id, $0) }, uniquingKeysWith: { a, _ in a })
    static let foldedHaystacks: [String: String] = Dictionary(
        all.map { ($0.id, IslamArticles.fold(([$0.title, $0.group] + $0.aliases).joined(separator: " "))) },
        uniquingKeysWith: { a, _ in a }
    )
    /// Each row's title and aliases folded for spelling (`SpellingFold`), so "yousuf", "ibraheem"
    /// and "dawood" reach Yusuf, Ibrahim and Dawud. The section name stays out: it is a heading, and
    /// folding it would make every row in a section answer to it.
    static let spellings: [String: SpellingFold.Entry] = Dictionary(
        all.map { ($0.id, SpellingFold.Entry(names: [$0.title] + $0.aliases)) },
        uniquingKeysWith: { a, _ in a }
    )

    /// The article's index screen, told to push the article as it appears (`ArticleAutoOpen`). Before
    /// iOS 16 there is no `navigationDestination(isPresented:)`, so the article opens directly.
    @MainActor
    static func homeDestination(_ home: IslamArticleHome, opening request: IslamArticleOpenRequest) -> AnyView {
        #if os(iOS)
        if #available(iOS 16.0, *) {
            switch home {
            case .pillars: return AnyView(PillarsView(openArticle: request))
            case .guides: return AnyView(GuidesView(openArticle: request))
            case .proving: return AnyView(ProvingIslamView(openArticle: request))
            default: return AnyView(IslamLibraryView(home: home, openArticle: request))
            }
        }
        #endif
        return destination(id: request.id, section: request.section, long: request.long)
    }

    /// The article page. With a `section`, the page scrolls to that heading as it appears (see
    /// `ArticleHeader` and `selectableArticleList`).
    @MainActor
    static func destination(_ entry: IslamArticleEntry, section: String? = nil) -> AnyView {
        destination(id: entry.id, section: section)
    }

    /// `long` opens the page in full whatever the setting: a search hit in words only the full article
    /// has (ArticleLength.swift).
    @MainActor
    static func destination(id: String, section: String? = nil, long: Bool = false) -> AnyView {
        guard let view = IslamArticles.destination(for: id) else {
            return AnyView(Text(verbatim: AppLanguage.article("Article not found")).foregroundColor(.secondary))
        }
        // Declared open by id, so a `door` row further down the stack that leads back here greys
        // out (`ArticleDoorRow`): articles that cite each other could be pushed without end.
        if let section, !section.isEmpty {
            return AnyView(view.environment(\.articleScrollTarget, section).environment(\.articleOpensLong, long)
                .openScreen(.islamArticle, id: id))
        }
        // Cleared, not left unset: the environment carries down the navigation stack, so an article
        // pushed without a section from one opened on "SUMMARY" (a door row, an OTHER ARTICLES result)
        // inherited that heading, opened hidden and landed on its OWN "SUMMARY" instead of the top.
        return AnyView(view.environment(\.articleScrollTarget, nil).openScreen(.islamArticle, id: id))
    }
}

// MARK: - Index rows

/// The index screens' sections, drawn from the catalog: one `Section` per group, one navigation row per
/// article. THE BASICS rows keep their larger accent title; every other row is a subheadline.
struct IslamArticleIndexSections: View {
    @Environment(\.appearance) private var appearance

    let groups: [IslamArticleGroup]
    /// The folded groups (`IslamArticleGroup.foldedCount`) the reader opened. Held by the index screen,
    /// so a search and back finds them as they were, and so "Scroll To Article" can open the group its
    /// row is folded into.
    @Binding var unfolded: Set<String>

    init(groups: [IslamArticleGroup], unfolded: Binding<Set<String>> = .constant([])) {
        self.groups = groups
        self._unfolded = unfolded
    }

    var body: some View {
        ForEach(groups) { group in
            let folded = group.foldedCount.map { $0 < group.entries.count && !unfolded.contains(group.id) } ?? false
            Section(header: Text(group.title)) {
                ForEach(folded ? Array(group.entries.prefix(group.foldedCount ?? 0)) : group.entries) { entry in
                    row(entry, icon: group.systemImage)
                }

                if group.foldedCount.map({ $0 < group.entries.count }) == true {
                    foldButton(group, folded: folded)
                }
            }
        }
    }

    /// "Show All 25 Prophets" under a folded group, "Show Fewer" once it is open: the Quran themes'
    /// "Show All" row, so the two read alike.
    private func foldButton(_ group: IslamArticleGroup, folded: Bool) -> some View {
        Button {
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut) {
                if folded {
                    _ = unfolded.insert(group.id)
                } else {
                    _ = unfolded.remove(group.id)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: folded ? "chevron.down.circle" : "chevron.up.circle")
                    .font(.subheadline)

                // The index is an article screen: English, like the rows above it.
                Text(verbatim: folded ? AppLanguage.article("Show All \(group.entries.count) \(group.rowNoun)")
                                      : AppLanguage.article("Show Fewer"))
                    .font(.subheadline.weight(.semibold))

                Spacer()
            }
            .foregroundColor(appearance.accent)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// One index row: an accent chip, then the title. Every other list in the app leads with a chip
    /// (the Islam root's `toolLabel`, the Hadith books, the resource rows), and these indexes used to
    /// be bare text in two different sizes - a headline accent for THE BASICS and small grey
    /// subheadline for everything else - which read as two different screens stitched together
    /// (Abu, 2026-09-19: "list mode looks ugly in a lot of places"). Now every row is the same
    /// shape; THE BASICS keeps its accent, as the entry point it is, but at the same size as its
    /// neighbours.
    @ViewBuilder
    private func row(_ entry: IslamArticleEntry, icon: String) -> some View {
        let link = NavigationLink(destination: LazyDestination { IslamArticleCatalog.destination(entry) }) {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: icon, size: 29)

                // A prophet's row carries his Arabic name and his tags, an answer to another faith its
                // own (`LibraryTags`, 2026-11-24): "so I can see each prophet together".
                let tags = LibraryTags.tags(for: entry.id)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(AppLanguage.article(entry.title))
                            .font(.subheadline.weight(entry.emphasized ? .semibold : .regular))
                            .foregroundColor(entry.emphasized ? appearance.accent : .primary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let arabic = LibraryTags.arabic(for: entry.id) {
                            Spacer(minLength: 6)
                            Text(arabic)
                                .font(.subheadline)
                                .foregroundColor(appearance.accent)
                        }
                    }
                    if !tags.isEmpty {
                        LibraryTagFlow(tags: tags)
                    }
                }
            }
            .padding(.vertical, 3)
        }
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
        #if os(iOS)
        Text(quranicInline: title.articleDisplayDigits, size: UIFont.preferredFont(forTextStyle: .footnote).pointSize, relativeTo: .footnote)
            .background(ArticleHeaderProbe(heading: title))
            .id(Self.anchorID(title))
        #else
        Text(title.articleDisplayDigits)
            .id(Self.anchorID(title))
        #endif
    }

    static func anchorID(_ heading: String) -> String { "articleSection_\(heading)" }
}

extension View {
    /// Marks where a passage of a page built at runtime begins, so its own search bar can land there
    /// (`IslamArticle.PagePassage.anchor`): what `ArticleHeader` is to a catalog article, for a row or
    /// a header the page draws its own way. Goes on a section's header, or on the outermost view of
    /// the row.
    func articleAnchor(_ key: String) -> some View {
        #if os(iOS)
        background(ArticleHeaderProbe(heading: key))
            .id(ArticleHeader.anchorID(key))
        #else
        id(ArticleHeader.anchorID(key))
        #endif
    }
}

/// The scroll to a section heading: three plain jumps a fifth of a second apart, then the exact offset.
/// A List measures its rows as they come on screen, so `scrollTo` aims at ESTIMATED row heights; an
/// animated scroll keeps measuring rows on its way and lands a section early or late on a long page
/// (Abu: a result "doesn't scroll to the right place"), while a jump lands, lets the rows around the
/// target measure, and the next jump corrects from a consistent layout. Even then `scrollTo` puts the
/// section's first ROW at the top and leaves the heading itself under the navigation bar, so the last
/// word goes to `ArticleScrollHandle.settle`, which reads the heading's measured frame and sets the
/// offset that shows it `topPadding` points below the bar.
///
/// All of it happens behind `ArticleScrollHandle.isLanding`, which the page reads to stay hidden
/// until the last settle, then fades in on the heading. Shown, the landing was two moves: the jumps
/// left the heading under the bar and the settle then pulled the page back down to it (Abu,
/// 2026-10-27: "it scrolls down properly yay but then it scrolls up a little bit too").
enum ArticleScroll {
    static let topPadding: CGFloat = 16

    static func land(on heading: String, proxy: ScrollViewProxy, after delay: Double, handle: ArticleScrollHandle?) {
        let id = ArticleHeader.anchorID(heading)
        let landing = handle?.beginLanding()
        for step in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + Double(step) * 0.2) {
                proxy.scrollTo(id, anchor: .top)
                guard step == 2 else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    handle?.settle(on: heading, padding: topPadding)
                }
                // Settled a second time before the page shows: on a page's first open the rows
                // around the heading can still be measuring at the first settle, and one that
                // changes height after it moves the heading again (the first open of a fresh
                // install ended with the heading under the bar).
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    handle?.settle(on: heading, padding: topPadding)
                    if let landing { handle?.endLanding(landing) }
                }
            }
        }
    }
}

/// The page's UIKit handle for the landing: the header views by heading, registered by
/// `ArticleHeaderProbe` from inside the List, so `settle` can place a heading from its ACTUAL frame
/// instead of from what `ScrollViewProxy.scrollTo` makes of a section header. One per page, handed to
/// the headers through `articleScrollHandle`.
final class ArticleScrollHandle: ObservableObject {
    /// True from the start of a landing to its last settle: the page stays hidden meanwhile, so the
    /// reader sees it once, already on the heading (see `ArticleScroll`).
    @Published private(set) var isLanding = false
    /// Whether a landing has finished on this page. A page opened ON a section hides from its first
    /// frame until then, before its own landing has even begun.
    @Published private(set) var hasLanded = false
    /// Set once the page has asked for its opening landing, so coming back to it (Back from a page it
    /// pushed, a tab switch) does not yank the reader back to the section they searched for.
    var openingLandingRequested = false
    /// The latest landing. Only it may end the hiding; an earlier one it overtook does not.
    private var landingGeneration = 0
    /// The version of the page on screen, for a page written twice (ArticleLength.swift): the
    /// setting's when the page opens, then the switch's. Here because the page's search moves it too: a
    /// hit only the full article has opens the full article before it lands.
    @Published var length: ArticleLength = .preferred

    func beginLanding() -> Int {
        landingGeneration += 1
        let generation = landingGeneration
        isLanding = true
        // Never left hidden: if a landing is cut short (the page closed mid-way), this lets go anyway.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.endLanding(generation)
        }
        return generation
    }

    func endLanding(_ generation: Int) {
        guard generation == landingGeneration, isLanding else { return }
        isLanding = false
        hasLanded = true
    }

    #if os(iOS)
    private final class Weak {
        weak var view: UIView?
        init(_ view: UIView) { self.view = view }
    }

    private var headers: [String: Weak] = [:]

    func register(_ view: UIView, heading: String) {
        headers[heading] = Weak(view)
    }
    #endif

    /// Sets the scroll offset that shows `heading` `padding` points below the top of the visible area.
    /// Nothing happens while the heading is off screen (its view is not laid out), which is why the
    /// jumps in `ArticleScroll.land` come first.
    func settle(on heading: String, padding: CGFloat) {
        #if os(iOS)
        guard let header = headers[heading]?.view, header.window != nil else { return }
        var ancestor = header.superview
        while let candidate = ancestor, !(candidate is UIScrollView) { ancestor = candidate.superview }
        guard let scrollView = ancestor as? UIScrollView else { return }
        let top = header.convert(CGPoint.zero, to: scrollView).y
        let inset = scrollView.adjustedContentInset
        let minY = -inset.top
        let maxY = max(minY, scrollView.contentSize.height + inset.bottom - scrollView.bounds.height)
        let y = min(max(top - inset.top - padding, minY), maxY)
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: y), animated: false)
        #endif
    }
}

private struct ArticleScrollHandleKey: EnvironmentKey {
    static let defaultValue: ArticleScrollHandle? = nil
}

extension EnvironmentValues {
    /// The page's `ArticleScrollHandle`, set by `selectableArticleList` for the headers inside the page.
    var articleScrollHandle: ArticleScrollHandle? {
        get { self[ArticleScrollHandleKey.self] }
        set { self[ArticleScrollHandleKey.self] = newValue }
    }
}

#if os(iOS)
/// A drawing-free UIView behind a section heading, registered with the page's handle once it is in the
/// window: the heading's measured frame, for `ArticleScrollHandle.settle`.
private struct ArticleHeaderProbe: UIViewRepresentable {
    @Environment(\.articleScrollHandle) private var handle

    let heading: String

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: ProbeView, context: Context) {
        view.heading = heading
        view.handle = handle
    }

    final class ProbeView: UIView {
        var heading = ""
        weak var handle: ArticleScrollHandle?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil { handle?.register(self, heading: heading) }
        }
    }
}
#endif

/// One block of article prose, as data. The largest articles (Phase 6 step 3 of the Performance Guide)
/// keep their sections in a `static let [ArticleSection]` rendered by `ArticleSectionsView`, so the List
/// gets a keyed `ForEach` tree whose rows are built as they scroll in, instead of a 200-leaf static
/// tuple that SwiftUI materialises in full when the page opens. The spellings are fixed: the corpus
/// builder (Scripts/build_islam_corpus.py) and the quote audit (Scripts/audit_islam_quotes.py) read
/// `.text(`, `.markdown(`, `.quote(text:`, `.ayah(`, `.hadith(` and `ArticleSection("HEADING"` straight
/// out of the source.
enum ArticleBlock {
    /// Plain prose, drawn with `ArticleParagraph(verbatim:)`.
    case text(String)
    /// Prose with inline **bold** terms, drawn through `ArticleParagraph(articleMarkdown:)`.
    case markdown(String)
    /// A `ScriptureQuote`, same arguments: the words of scholars and anything the packs do not
    /// carry, as written.
    case quote(text: String, arabic: String? = nil, dimmed: Bool = false)
    /// A Quran quote by reference (`ScriptureQuote(quran:words:)`): the words come from the Quran
    /// the app ships, never from a copy in the article.
    case ayah(String, words: ClosedRange<Int>? = nil)
    /// A hadith by reference (`ScriptureQuote(hadith:cite:arabic:english:)`): the words come from
    /// the bundled collection's row, each side a token range, or literal where the article's
    /// wording is not the shelf's.
    case hadith(String, cite: String, arabic: ClosedRange<Int>? = nil, english: [ClosedRange<Int>] = [],
                text: String? = nil, arabicText: String? = nil)

    // The design blocks (ArticleDesign.swift, 2026-09-29). Every string here is prose the corpus
    // builder reads, spelled as these cases spell them.

    /// The "In short" card that opens a page.
    case lead(String)
    /// One numbered step, "3. Wash both **hands** ...", markdown.
    case step(String)
    /// One bullet, markdown ("•" optional).
    case bullet(String)
    /// A point set apart in a card with an icon and a title; markdown.
    case callout(String, title: String, icon: String = "lightbulb.fill")
    /// A term with its Arabic set large and its meaning (markdown) under it.
    case term(String, arabic: String, meaning: String)
    /// Number tiles.
    case stats([ArticleStat])
    /// A line drawn node by node (the messengers in order, a chain of causes).
    case chain([ArticleChainLink], caption: String? = nil)
    /// A chain of transmission drawn as the isnad diagram (IsnadDiagram.swift), with the caption that
    /// names its people in order: the words the corpus builder reads for it.
    case isnad(String, ArticleIsnad)
    /// A short list in one card under a heading; each item markdown.
    case checklist([String], title: String, icon: String = "checkmark.circle.fill")
    /// Two things side by side (two spellings, two claims).
    case versus(ArticleVersus.Side, ArticleVersus.Side, quranic: Bool = true)
    /// The scale of hadith grades (`HadithGradeLadder`).
    case gradeLadder
    /// The classes of report by how many carried it, counted at the narrowest point
    /// (`HadithCountLadder`).
    case countLadder
    /// A row that opens another page: an article, a prophecy, a site.
    case door(ArticleDoor)
    /// A prophet's facts card (`ProphetFactsCard`): his Arabic name and his tags, by his key in
    /// `ProphetFacts` ("musa"). Under SUMMARY on his first chapter (2026-11-24).
    case facts(String)
    /// Every surah and ayah that names him (`ProphetMentionsCard`), from the preprocessed table.
    case mentions(String)

    // The two versions (ArticleLength.swift, 2026-11-25): a block only one of them shows. Unwrapped by
    // `ArticleSection.shown(_:in:)` before any row is made; the corpus builder reads the mark.

    /// A block only the full article shows.
    indirect case longOnly(ArticleBlock)
    /// A block only the short version shows: the few lines that stand in for what it leaves out.
    indirect case shortOnly(ArticleBlock)
}

/// Where an article's `door` row goes. Articles are named by their catalog id, so a door can never
/// point at a page the catalog does not have without the corpus gate noticing (see
/// Scripts/build_islam_corpus.py, which checks every `.article(` door).
enum ArticleDoor {
    /// A Pillars & Beliefs, How-to or Proving Islam article, by its view-type id.
    case article(String)
    /// A Prophecies of the Prophet article, by its entry id (iOS; the watch draws nothing).
    case prophecy(String)
    /// A Miracles of the Quran article, by its slug in the miracles pack, with the title to show (the
    /// row must not load the pack just to draw itself).
    case miracle(String, title: String)
    /// A Miracles of the Prophets article, by its entry id.
    case prophetMiracle(String)
    /// One of the signs libraries, whole.
    case library(ArticleLibrary)
    /// The Proving Islam library itself.
    case provingIslam
    /// One of the six reading libraries (2026-11-24) whole, by its home (`IslamLibraryView`).
    case home(IslamArticleHome)
    /// A page on the web.
    case link(String, title: String, subtitle: String)
}

/// The data-backed libraries a door can open whole: the three signs libraries, and the Sunnahs of
/// the Prophet (2026-10-26).
enum ArticleLibrary {
    case miraclesOfQuran, propheciesOfProphet, miraclesOfProphets, sunnahsOfProphet
}

struct ArticleSection {
    let heading: String
    /// The one version that shows this section, or nil for both (ArticleLength.swift).
    let only: ArticleLength?
    let blocks: [ArticleBlock]

    init(_ heading: String, only: ArticleLength? = nil, _ blocks: [ArticleBlock]) {
        self.heading = heading
        self.only = only
        self.blocks = blocks
    }
}

/// The sections of a data-backed article: one `Section(header: ArticleHeader(...))` each, the same
/// anchors a search result scrolls to, one row per block.
///
/// Two sections every article has are drawn as cards without the data saying so (2026-09-29): the
/// first paragraph of SUMMARY is the page's `ArticleLead`, and the first paragraph of IN SUMMARY its
/// `ArticleClosing`. The words are the same `.text` they always were.
struct ArticleSectionsView: View {
    let sections: [ArticleSection]

    /// The version on screen, for a page written twice (ArticleLength.swift).
    @Environment(\.articleLength) private var length

    var body: some View {
        // A door that leads nowhere on this platform, and a block or section the other version shows,
        // are left out HERE: every block that reaches a ForEach is exactly one row (see
        // `ArticleBlockView.body`). Rows keep their index in the article as their identity, so a switch
        // between the versions inserts and removes rows instead of redrawing every one.
        let shown = ArticleSection.shown(sections, in: length)
        // The Short / Full switch first, above SUMMARY: only the sections that open the page have it (a
        // page can draw its sections in two parts with rows of its own between them).
        if shown.first?.heading == "SUMMARY" {
            ArticleLengthSection()
        }
        ForEach(shown, id: \.index) { section in
            Section(header: ArticleHeader(section.heading)) {
                let first = section.rows.first?.index
                ForEach(section.rows, id: \.index) { row in
                    ArticleBlockView(block: row.block, role: Self.role(heading: section.heading, isFirst: row.index == first))
                }
            }
        }
    }

    /// The first block a version shows of SUMMARY is the page's lead card, and of IN SUMMARY its
    /// closing card.
    static func role(heading: String, isFirst: Bool) -> ArticleBlockView.Role {
        guard isFirst else { return .body }
        switch heading {
        case "SUMMARY": return .lead
        case "IN SUMMARY": return .closing
        default: return .body
        }
    }
}

struct ArticleBlockView: View {
    /// Where the block sits, for the two paragraphs a page's structure promotes to cards.
    enum Role {
        case body, lead, closing
    }

    let block: ArticleBlock
    var role: Role = .body

    var body: some View {
        // One view by its type: every paragraph, quote and card of every article is a List row made
        // here, and as a bare `switch` each was a row the List builds to count and re-inserts after
        // a scroll (see `OneRow`). The lead card's cell modifiers are restated on the row, since from
        // inside the container `ArticleLead`'s own never reach the cell.
        OneRow {
            switch block {
            case .text(let prose):
                switch role {
                case .lead: ArticleLead(prose)
                case .closing: ArticleClosing(prose)
                case .body:
                    ArticleParagraph(verbatim: prose)
                }
            case .markdown(let prose):
                ArticleParagraph(articleMarkdown: prose)
            case .quote(let text, let arabic, let dimmed):
                ScriptureQuote(text: text, arabic: arabic, dimmed: dimmed)
            case .ayah(let reference, let words):
                ScriptureQuote(quran: reference, words: words)
            case .hadith(let link, let cite, let arabic, let english, let text, let arabicText):
                ScriptureQuote(hadith: link, cite: cite, arabic: arabic, english: english, text: text, arabicText: arabicText)
            case .lead(let prose):
                ArticleLead(prose)
            case .step(let prose):
                ArticleStep(prose)
            case .bullet(let prose):
                ArticleBullet(prose)
            case .callout(let prose, let title, let icon):
                ArticleCallout(prose, title: title, systemImage: icon)
            case .term(let term, let arabic, let meaning):
                ArticleTermCard(term, arabic: arabic, meaning: meaning)
            case .stats(let stats):
                ArticleStatGrid(stats)
            case .chain(let links, let caption):
                ArticleChainDiagram(links, caption: caption)
            case .isnad(let caption, let isnad):
                ArticleIsnadCard(caption, isnad: isnad)
            case .checklist(let items, let title, let icon):
                ArticleChecklist(items, title: title, systemImage: icon)
            case .versus(let left, let right, let quranic):
                ArticleVersus(left, right, quranic: quranic)
            case .gradeLadder:
                HadithGradeLadder()
            case .countLadder:
                HadithCountLadder()
            case .door(let door):
                ArticleDoorRow(door: door)
            case .facts(let key):
                if let facts = ProphetFacts.named(key) { ProphetFactsCard(facts: facts) }
            case .mentions(let key):
                if let facts = ProphetFacts.named(key) { ProphetMentionsCard(facts: facts) }
            case .longOnly, .shortOnly:
                // Unwrapped before a row is made (`ArticleSection.shown`).
                EmptyView()
            }
        }
        .articleCardRow(when: isLeadCard)
    }

    /// Whether this block draws as `ArticleLead`, the card that IS its row.
    private var isLeadCard: Bool {
        switch block {
        case .lead: return true
        case .text: return role == .lead
        default: return false
        }
    }
}

extension ArticleBlock {
    /// False for a door `ArticleDoorRow` draws nothing for (a page this platform does not have, an
    /// id the catalog does not know): `ArticleSectionsView` leaves those out of its rows.
    var drawsRow: Bool {
        switch self {
        case .door(let door): return door.opens
        case .facts(let key), .mentions(let key): return ProphetFacts.named(key) != nil
        default: return true
        }
    }
}

extension ArticleDoor {
    /// Whether `ArticleDoorRow` has a row to draw for this door: its conditions, restated.
    var opens: Bool {
        switch self {
        case .article(let id):
            return IslamArticleCatalog.byID[id] != nil
        case .link(let raw, _, _):
            return URL(string: raw) != nil
        case .prophecy(let id):
            #if os(iOS)
            return PropheciesView.entries.contains { $0.id == id }
            #else
            return false
            #endif
        case .prophetMiracle(let id):
            #if os(iOS)
            return ProphetMiraclesView.entries.contains { $0.id == id }
            #else
            return false
            #endif
        case .miracle, .library, .provingIslam, .home:
            #if os(iOS)
            return true
            #else
            return false
            #endif
        }
    }
}

/// One `door` block: a row that opens another page. One link per row (the List rule every article
/// keeps), with the destination built only when it is opened.
struct ArticleDoorRow: View {
    @Environment(\.appearance) private var appearance

    let door: ArticleDoor

    var body: some View {
        switch door {
        case .article(let id):
            if let entry = IslamArticleCatalog.byID[id] {
                #if os(iOS)
                // Guarded: an article already on the stack is shown greyed instead of pushed again
                // (the app's no-infinite-chains rule; these rows were plain links until 2026-10-04).
                OpenScreenLink(screen: .islamArticle, id: id) {
                    IslamArticleCatalog.destination(entry)
                } label: {
                    label(title: AppLanguage.article(entry.title),
                          subtitle: "\(AppLanguage.article(entry.home.title)) \u{203A} \(Self.groupTitle(entry.group))",
                          systemImage: IslamArticleCatalog.groups(for: entry.home).first { $0.title == entry.group }?.systemImage
                              ?? entry.home.systemImage)
                }
                #else
                NavigationLink(destination: LazyDestination { IslamArticleCatalog.destination(entry) }) {
                    label(title: AppLanguage.article(entry.title),
                          subtitle: "\(AppLanguage.article(entry.home.title)) \u{203A} \(Self.groupTitle(entry.group))",
                          systemImage: IslamArticleCatalog.groups(for: entry.home).first { $0.title == entry.group }?.systemImage
                              ?? entry.home.systemImage)
                }
                #endif
            }
        case .prophecy(let id):
            #if os(iOS)
            if let entry = PropheciesView.entries.first(where: { $0.id == id }) {
                NavigationLink(destination: LazyDestination { ProphecyArticleView(entry: entry) }) {
                    label(title: entry.title, subtitle: entry.summary, systemImage: "checkmark.seal")
                }
            }
            #else
            EmptyView()
            #endif
        case .miracle(let slug, let title):
            #if os(iOS)
            NavigationLink(destination: LazyDestination { MiracleDoorDestination(slug: slug) }) {
                label(title: title, subtitle: AppLanguage.article("Miracles of the Quran"), systemImage: "sparkle.magnifyingglass")
            }
            #else
            EmptyView()
            #endif
        case .prophetMiracle(let id):
            #if os(iOS)
            if let entry = ProphetMiraclesView.entries.first(where: { $0.id == id }) {
                NavigationLink(destination: LazyDestination { ProphetMiracleArticleView(entry: entry) }) {
                    label(title: entry.title, subtitle: entry.summary, systemImage: "staroflife")
                }
            }
            #else
            EmptyView()
            #endif
        case .library(let library):
            #if os(iOS)
            // A door sits inside an English article, so the words it shares with the Islam tab's tiles
            // read English with it (`AppLanguage.article`).
            switch library {
            case .miraclesOfQuran:
                OpenScreenLink(screen: .miraclesLibrary) {
                    MiraclesView().openScreen(.miraclesLibrary)
                } label: {
                    label(title: AppLanguage.article("Miracles of the Quran"),
                          subtitle: AppLanguage.article("Signs in creation, science, and history"),
                          systemImage: "sparkle.magnifyingglass")
                }
            case .propheciesOfProphet:
                OpenScreenLink(screen: .propheciesLibrary) {
                    PropheciesView().openScreen(.propheciesLibrary)
                } label: {
                    label(title: AppLanguage.article("Prophecies of the Prophet"),
                          subtitle: AppLanguage.article("What he foretold, and what history did"),
                          systemImage: "checkmark.seal")
                }
            case .miraclesOfProphets:
                OpenScreenLink(screen: .prophetMiraclesLibrary) {
                    ProphetMiraclesView().openScreen(.prophetMiraclesLibrary)
                } label: {
                    label(title: AppLanguage.article("Miracles of the Prophets"),
                          subtitle: AppLanguage.article("The signs given to the prophets, and to him"),
                          systemImage: "staroflife")
                }
            case .sunnahsOfProphet:
                OpenScreenLink(screen: .sunnahLibrary) {
                    SunnahView().openScreen(.sunnahLibrary)
                } label: {
                    label(title: AppLanguage.article("Sunnahs of the Prophet"),
                          subtitle: AppLanguage.article("What he did each day, from waking to sleeping"),
                          systemImage: "sun.horizon")
                }
            }
            #else
            EmptyView()
            #endif
        case .provingIslam:
            #if os(iOS)
            // Guarded like the three signs libraries: a chapter's door back to the index that pushed it
            // is greyed instead of starting a second lap (the no-infinite-chains rule).
            OpenScreenLink(screen: .provingIslamLibrary) {
                ProvingIslamView().openScreen(.provingIslamLibrary)
            } label: {
                label(title: "Proving Islam: The Complete Case",
                      subtitle: "The case that Islam is true, one line of evidence at a time",
                      systemImage: IslamArticleHome.proving.systemImage)
            }
            #else
            EmptyView()
            #endif
        case .home(let home):
            #if os(iOS)
            OpenScreenLink(screen: .articleLibrary, id: home.rawValue) {
                IslamLibraryView(home: home).openScreen(.articleLibrary, id: home.rawValue)
            } label: {
                label(title: AppLanguage.article(home.title), subtitle: AppLanguage.article(home.subtitle),
                      systemImage: home.systemImage)
            }
            #else
            EmptyView()
            #endif
        case .link(let raw, let title, let subtitle):
            if let url = URL(string: raw) {
                Link(destination: url) {
                    label(title: title, subtitle: subtitle, systemImage: "link", external: true)
                }
            }
        }
    }

    /// "HADITH & ITS SCIENCES" -> "Hadith & Its Sciences", with the small words kept small.
    static func groupTitle(_ group: String) -> String {
        let small: Set<String> = ["of", "the", "and", "in", "to", "a", "an", "on", "at", "for"]
        return group.lowercased().split(separator: " ").enumerated().map { index, word in
            let text = String(word)
            if index > 0, small.contains(text) { return text }
            if text.hasPrefix("(") { return "(" + text.dropFirst().capitalized }
            return text.capitalized
        }.joined(separator: " ")
    }

    private func label(title: String, subtitle: String, systemImage: String, external: Bool = false) -> some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: systemImage, size: 29)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            if external {
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 3)
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
        /// True when the match is in the section's quotes' Arabic (an ayah, a hadith, a scholar's
        /// words), so the window is Arabic and reads right to left.
        var snippetIsArabic: Bool = false

        var id: String { "\(article.id)#\(sectionIndex)" }
        var entry: IslamArticleEntry? { IslamArticleCatalog.byID[article.id] }
        var home: IslamArticleHome? { entry?.home }

        static func == (l: Self, r: Self) -> Bool { l.id == r.id && l.snippet == r.snippet }
    }

    /// Non-overlapping occurrences of `term` in `haystack`, without the array `components(separatedBy:)`
    /// allocated per term per section (~1,000 sections per keystroke).
    static func occurrences(of term: String, in haystack: String) -> Int {
        IslamSearchQuery.count(term, in: haystack, rule: .contains)
    }

    /// The folded query words: lowercased, punctuation flattened, empties dropped.
    static func words(_ query: String) -> [String] {
        IslamArticles.fold(query).split(separator: " ").map(String.init).filter { !$0.isEmpty }
    }

    /// Index rows whose title, section name or aliases carry the query, under the filters (Match,
    /// Words, Without, Topics).
    /// The last answer (Phase 10.8): the sections view asked this on every body pass while a query was
    /// typed, and the ranking re-folds every title and alias each time.
    nonisolated(unsafe) private static var titleHitsMemo: (key: String, hits: [IslamArticleEntry])?
    private static let titleHitsLock = NSLock()

    static func titleHits(_ query: String, homes: Set<IslamArticleHome>,
                          filters: IslamSearchFilters = IslamSearchFilters()) -> [IslamArticleEntry] {
        let key = [query, homes.map(\.rawValue).sorted().joined(separator: "+"), filters.match.rawValue,
                   filters.combine.rawValue, filters.excludedWords.joined(separator: "+"),
                   filters.groups.sorted().joined(separator: "+")].joined(separator: "|")
        titleHitsLock.lock()
        if let memo = titleHitsMemo, memo.key == key { titleHitsLock.unlock(); return memo.hits }
        titleHitsLock.unlock()
        let hits = computeTitleHits(query, homes: homes, filters: filters)
        titleHitsLock.lock(); titleHitsMemo = (key, hits); titleHitsLock.unlock()
        return hits
    }

    private static func computeTitleHits(_ query: String, homes: Set<IslamArticleHome>,
                                         filters: IslamSearchFilters) -> [IslamArticleEntry] {
        let compiled = IslamSearchQuery(query, filters: filters)
        guard !compiled.words.isEmpty else { return [] }
        let candidates = IslamArticleCatalog.all.filter { IslamArticleCatalog.covers(homes, $0) && filters.admits($0) }
        let direct = candidates.filter { entry in
            guard let haystack = IslamArticleCatalog.foldedHaystacks[entry.id] else { return false }
            return compiled.matches(haystack)
        }
        // The article titled for the query leads the ones that carry it in a section name or alias.
        guard direct.isEmpty else { return SearchRank.sorted(direct, by: query) { [$0.title] + $0.aliases } }
        // No row spelled that way: fold the spelling and ask again. A fallback only, and only under the
        // default word rules (Whole Word or Without means what was typed).
        guard filters.match == .contains, filters.combine == .allWords, compiled.excluded.isEmpty else { return [] }
        return SpellingFold.matches(query, in: candidates) {
            IslamArticleCatalog.spellings[$0.id] ?? SpellingFold.Entry(names: [])
        }
    }

    /// Sections whose prose (or quotes' Arabic) carries the query, in the index's order, at most
    /// `perArticle` sections per article (the ones with the most hits) and `limit` in all; with Best
    /// Match, the strongest first. A query that names an ayah or a hadith lists the passages that cite
    /// exactly it instead.
    ///
    /// Reads `IslamArticles.all`, which inflates the article pack on first use - call this off the
    /// main actor (`IslamArticleSearchModel` does).
    static func contentHits(_ query: String, homes: Set<IslamArticleHome>,
                            perArticle: Int = 3, limit: Int = 60) -> [ContentHit] {
        contentHits(IslamSearchQuery(query), homes: homes, filters: IslamSearchFilters(), perArticle: perArticle, limit: limit)
    }

    static func contentHits(_ query: IslamSearchQuery, homes: Set<IslamArticleHome>, filters: IslamSearchFilters,
                            perArticle: Int = 3, limit: Int = 60) -> [ContentHit] {
        guard !query.isEmpty else { return [] }
        // Index order, so the results read top to bottom like the list they came from.
        let order = IslamArticleCatalog.order
        let articles = IslamArticles.all
            .filter { article in
                guard let entry = IslamArticleCatalog.byID[article.id] else { return false }
                return IslamArticleCatalog.covers(homes, entry) && filters.admits(entry)
            }
            .sorted { (order[$0.id] ?? .max) < (order[$1.id] ?? .max) }

        if let reference = query.reference {
            let byID = Dictionary(articles.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
            let cited = IslamScriptureReference.citations(for: reference.keys)
                .filter { byID[$0.article] != nil }
                .sorted { ((order[$0.article] ?? .max), $0.section) < ((order[$1.article] ?? .max), $1.section) }
            return cited.prefix(max(limit, 120)).compactMap { citation in
                guard let article = byID[citation.article], article.sections.indices.contains(citation.section) else { return nil }
                let section = article.sections[citation.section]
                return ContentHit(article: article, section: section, sectionIndex: citation.section,
                                  snippet: snippet(of: section.text, atUTF16: citation.location))
            }
        }

        var picked: [(article: IslamArticle, index: Int, score: Int)] = []
        for article in articles {
            // A newer keystroke has already replaced this search: stop walking the articles for it.
            if Task.isCancelled { return [] }
            var scored: [(index: Int, count: Int)] = []
            for (index, section) in article.sections.enumerated() {
                if let count = query.score(section.folded, section.foldedArabic) { scored.append((index, count)) }
            }
            guard !scored.isEmpty else { continue }
            let best = scored.sorted { $0.count > $1.count }.prefix(perArticle).sorted { $0.index < $1.index }
            picked += best.map { (article, $0.index, $0.count) }
            if filters.sort == .index, picked.count >= limit { break }
        }
        if filters.sort == .relevance {
            // Stable on ties, so equal scores keep the index's order.
            picked = picked.enumerated().sorted { a, b in
                a.element.score != b.element.score ? a.element.score > b.element.score : a.offset < b.offset
            }.map(\.element)
        }
        return picked.prefix(limit).map { hit(in: $0.article, at: $0.index, for: query) }
    }

    /// Every section of ONE article whose prose carries the query, in page order: the page's own
    /// search, which has no per-article cap. Off the main actor, like `contentHits`.
    /// `fallback`: the page's own sections, scanned when the corpus has no article for `articleID`
    /// (the prophecy and prophet-miracle pages are generated from data, so the corpus never carries
    /// them and their bar found nothing).
    /// `page`: the page's text as it is shown, searched in place of the corpus (a translated page,
    /// a page built at runtime); its sections land on their anchors and need no heading.
    static func sectionHits(_ query: String, articleID: String, fallback: IslamArticle? = nil,
                            page: IslamArticle? = nil) -> [ContentHit] {
        sectionHits(IslamSearchQuery(query), articleID: articleID, fallback: fallback, page: page)
    }

    static func sectionHits(_ query: IslamSearchQuery, articleID: String, fallback: IslamArticle? = nil,
                            page: IslamArticle? = nil) -> [ContentHit] {
        guard !query.isEmpty,
              let article = page ?? IslamArticles.all.first(where: { $0.id == articleID }) ?? fallback else { return [] }
        if let reference = query.reference, page == nil, article.id == articleID {
            let cited = IslamScriptureReference.citations(for: reference.keys).filter { $0.article == article.id }
            let hits = cited.sorted { $0.section < $1.section }.compactMap { citation -> ContentHit? in
                guard article.sections.indices.contains(citation.section) else { return nil }
                let section = article.sections[citation.section]
                guard !section.heading.isEmpty || section.anchor != nil else { return nil }
                return ContentHit(article: article, section: section, sectionIndex: citation.section,
                                  snippet: snippet(of: section.text, atUTF16: citation.location))
            }
            if !hits.isEmpty || query.words.isEmpty { return hits }
        }
        var hits: [ContentHit] = []
        for (index, section) in article.sections.enumerated() where !section.heading.isEmpty || section.anchor != nil {
            guard query.matches(section.folded, section.foldedArabic) else { continue }
            hits.append(hit(in: article, at: index, for: query))
        }
        return hits
    }

    /// The hit for one matching section, its window cut around the match: in the prose when the
    /// match is there, in the quotes' Arabic when only that carries it.
    private static func hit(in article: IslamArticle, at index: Int, for query: IslamSearchQuery) -> ContentHit {
        let section = article.sections[index]
        let flat = section.text.replacingOccurrences(of: "\n", with: " ")
        if let range = locate(query, in: flat) {
            return ContentHit(article: article, section: section, sectionIndex: index, snippet: window(flat, around: range))
        }
        if !section.arabic.isEmpty {
            let arabic = section.arabic.replacingOccurrences(of: "\n", with: " \u{2022} ")
            if let range = locate(query, in: arabic) ?? locate(query, in: arabic, daggerAsAlif: true) {
                return ContentHit(article: article, section: section, sectionIndex: index,
                                  snippet: window(arabic, around: range, radius: 70), snippetIsArabic: true)
            }
        }
        return ContentHit(article: article, section: section, sectionIndex: index, snippet: window(flat, around: nil))
    }

    /// Where the query sits in `text` itself, found in its fold and mapped back. `daggerAsAlif` reads
    /// the mushaf's dagger alif as a full alif first (the second Arabic lane, `Section.foldedArabic`);
    /// one scalar for one, so the offsets still fall in `text`.
    static func locate(_ query: IslamSearchQuery, in text: String, daggerAsAlif: Bool = false) -> Range<String.Index>? {
        let source = daggerAsAlif ? text.replacingOccurrences(of: "\u{0670}", with: "\u{0627}") : text
        let (folded, origins) = IslamArticles.foldMapped(source)
        guard let range = query.firstRange(in: folded) else { return nil }
        let scalars = folded.unicodeScalars
        let low = scalars.distance(from: scalars.startIndex, to: range.lowerBound)
        let high = scalars.distance(from: scalars.startIndex, to: range.upperBound)
        guard high > low, high - 1 < origins.count else { return nil }
        let textScalars = text.unicodeScalars
        guard origins[high - 1] < textScalars.count else { return nil }
        let start = textScalars.index(textScalars.startIndex, offsetBy: origins[low])
        let last = textScalars.index(textScalars.startIndex, offsetBy: origins[high - 1])
        return start..<textScalars.index(after: last)
    }

    /// A window of `text` around a citation at a UTF-16 offset (the reference index's location).
    static func snippet(of text: String, atUTF16 location: Int) -> String {
        let flat = text.replacingOccurrences(of: "\n", with: " ")
        let range = Range(NSRange(location: location, length: 1), in: flat)
        return window(flat, around: range)
    }

    /// A window of `text` around the first occurrence of the query (or of its first word), cut at
    /// word boundaries with ellipses, so the row shows the match in context rather than the section's
    /// opening line.
    static func snippet(of text: String, around query: String, terms: [String], radius: Int = 110) -> String {
        let flat = text.replacingOccurrences(of: "\n", with: " ")
        return window(flat, around: locate(IslamSearchQuery(query), in: flat), radius: radius)
    }

    /// `flat` (one line) cut to about `radius` characters either side of `match`, at word boundaries,
    /// with ellipses where it was cut; the opening of the text when there is no match.
    static func window(_ flat: String, around match: Range<String.Index>?, radius: Int = 110) -> String {
        guard let match else {
            return flat.count > radius * 2 ? String(flat.prefix(radius * 2)).trimmingCharacters(in: .whitespaces) + "\u{2026}" : flat
        }
        // Character boundaries: a scalar index inside an Arabic letter's marks moves back to its letter.
        func aligned(_ index: String.Index) -> String.Index {
            var index = index
            while index > flat.startIndex, index < flat.endIndex, index.samePosition(in: flat) == nil {
                index = flat.unicodeScalars.index(before: index)
            }
            return index
        }
        let lower = aligned(match.lowerBound)
        let upper = match.upperBound >= flat.endIndex ? flat.endIndex : aligned(match.upperBound)

        var start = lower
        var steps = 0
        while start > flat.startIndex, steps < radius {
            start = flat.index(before: start); steps += 1
        }
        var end = max(upper, lower)
        steps = 0
        while end < flat.endIndex, steps < radius {
            end = flat.index(after: end); steps += 1
        }
        // Snap to word boundaries, so the window never opens or closes mid-word.
        if start > flat.startIndex, let space = flat[start...].firstIndex(of: " "), space < lower {
            start = flat.index(after: space)
        }
        if end < flat.endIndex, let space = flat[..<end].lastIndex(of: " "), space > upper {
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
    /// Every matching section of the page's own article (`update(query:homes:within:)`), in page order.
    @Published private(set) var articleHits: [IslamArticleSearch.ContentHit] = []
    /// The ayah or hadith the query names, for the row that opens it (`IslamScriptureReferenceSection`).
    @Published private(set) var reference: IslamScriptureReference?
    /// True between a query change and its results landing, so the screen can hold "no matches"
    /// until the scan has actually run.
    @Published private(set) var isSearching = false

    private var task: Task<Void, Never>?

    /// Inflate the pack ahead of the first keystroke. Cheap to call repeatedly.
    nonisolated static func prewarm() {
        Task.detached(priority: .utility) { _ = IslamArticles.all }
    }

    /// `within`: the open article's id on an article page. Its own sections come back in `articleHits`
    /// (all of them), while `contentHits` still covers every article for the "other articles" rows.
    /// `fallback`: the page's own sections for an id the corpus lacks (see `sectionHits`).
    /// `page`: the page's text as it is shown, which wins over the corpus (see `sectionHits`).
    /// `filters`: the screen's search filters (Match, Words, Without, Topics, Best Match).
    /// Empty `homes` searches the page alone.
    func update(query: String, homes: Set<IslamArticleHome>, filters: IslamSearchFilters = IslamSearchFilters(),
                within articleID: String? = nil, fallback: IslamArticle? = nil, page: IslamArticle? = nil) {
        task?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            if !contentHits.isEmpty { contentHits = [] }
            if !articleHits.isEmpty { articleHits = [] }
            if reference != nil { reference = nil }
            isSearching = false
            return
        }
        isSearching = true
        task = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 180_000_000)
            guard !Task.isCancelled else { return }
            let (hits, own, reference) = await Task.detached(priority: .userInitiated) {
                let compiled = IslamSearchQuery(trimmed, filters: filters)
                return (homes.isEmpty ? [] : IslamArticleSearch.contentHits(compiled, homes: homes, filters: filters),
                        articleID.map { IslamArticleSearch.sectionHits(compiled, articleID: $0, fallback: fallback, page: page) } ?? [],
                        compiled.reference)
            }.value
            guard !Task.isCancelled else { return }
            self?.contentHits = hits
            self?.articleHits = own
            self?.reference = reference
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
    /// True on the Islam tab's root: the row opens the article's index with the article pushed on top.
    var openViaHome: Bool = false
    var scrollLabel: String = "Scroll To Article"
    /// Clears the search and scrolls the index to this article's row. Nil = no such row on this screen.
    var onScrollTo: (() -> Void)? = nil

    private var caption: String {
        showHome ? "\(AppLanguage.article(entry.home.title)) \u{203A} \(entry.group)" : entry.group
    }

    @MainActor
    private var destination: AnyView {
        openViaHome
            ? IslamArticleCatalog.homeDestination(entry.home, opening: IslamArticleOpenRequest(id: entry.id))
            : IslamArticleCatalog.destination(entry)
    }

    var body: some View {
        NavigationLink(destination: LazyDestination { destination }) {
            VStack(alignment: .leading, spacing: 3) {
                // Shown through `AppLanguage.article`: many titles are keys a translated screen shares
                // (the search itself matches the English `title`).
                HighlightedSnippet(
                    source: AppLanguage.article(entry.title),
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
            // The article's English keeps the left edge in the Arabic interface.
            .frame(maxWidth: .infinity, alignment: .leading)
            .leftToRightContent()
            .padding(.vertical, 4)
        }
        .id(entry.listID)
        .islamArticleRowActions(title: entry.title, copyText: nil, scrollLabel: scrollLabel, onScrollTo: onScrollTo,
                                translated: openViaHome)
    }
}

/// A passage that matched: "Article \u{203A} SECTION" in the accent, then the prose around the match.
/// Opens the article scrolled to that section.
struct IslamArticleContentRow: View {
    @Environment(\.appearance) private var appearance

    let hit: IslamArticleSearch.ContentHit
    let query: String
    var showHome: Bool = false
    /// True on the Islam tab's root: the row opens the article's index with the article pushed on top.
    var openViaHome: Bool = false
    var scrollLabel: String = "Scroll To Article"
    var onScrollTo: (() -> Void)? = nil

    private var caption: String {
        var parts: [String] = []
        if showHome, let home = hit.home { parts.append(AppLanguage.article(home.title)) }
        parts.append(AppLanguage.article(hit.article.title))
        if !hit.section.heading.isEmpty { parts.append(hit.section.heading) }
        return parts.joined(separator: " \u{203A} ")
    }

    @MainActor
    private var destination: AnyView {
        if openViaHome, let home = hit.home {
            return IslamArticleCatalog.homeDestination(
                home, opening: IslamArticleOpenRequest(id: hit.article.id, section: hit.section.heading,
                                                       long: hit.section.only == .long))
        }
        return IslamArticleCatalog.destination(id: hit.article.id, section: hit.section.heading,
                                               long: hit.section.only == .long)
    }

    var body: some View {
        NavigationLink(destination: LazyDestination { destination }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(caption)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(appearance.accent)
                    .lineLimit(2)

                if hit.snippetIsArabic {
                    // A quote's Arabic (an ayah, a hadith, a scholar's words): right to left, in the
                    // Islam tab's Arabic face, against the trailing edge.
                    HighlightedSnippet(
                        source: hit.snippet,
                        term: query,
                        font: appearance.islamArabicFont(base: 18, relativeTo: .body),
                        accent: appearance.accent,
                        fg: .primary,
                        lineLimit: 3,
                        guaranteeMatch: true
                    )
                    .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                } else {
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
            }
            // The article's English keeps the left edge in the Arabic interface.
            .frame(maxWidth: .infinity, alignment: .leading)
            .leftToRightContent()
            .padding(.vertical, 4)
        }
        .islamArticleRowActions(title: hit.article.title, copyText: hit.snippet, scrollLabel: scrollLabel, onScrollTo: onScrollTo,
                                translated: openViaHome)
    }
}

/// The Quran list's row grammar on an article result: a context menu (scroll to the article's index
/// row, copy) and a trailing swipe whose arrow does the same scroll.
private struct IslamArticleRowActions: ViewModifier {
    let title: String
    let copyText: String?
    let scrollLabel: String
    let onScrollTo: (() -> Void)?
    /// True on a translated screen (the Islam tab's root): the menu's own words follow the interface.
    /// Elsewhere the row sits in an English article screen and its menu reads English with it.
    let translated: Bool

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Text(verbatim: translated ? String(localized: "Article Actions") : AppLanguage.article("Article Actions"))
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
                    Label(translated ? String(localized: "Copy Title") : AppLanguage.article("Copy Title"), systemImage: "doc.on.doc")
                }

                if let copyText, !copyText.isEmpty {
                    Button {
                        Settings.shared.hapticFeedback()
                        UIPasteboard.general.string = copyText.replacingOccurrences(of: "\u{2026}", with: "")
                    } label: {
                        Label(translated ? String(localized: "Copy Passage") : AppLanguage.article("Copy Passage"),
                              systemImage: "doc.on.doc")
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
                                onScrollTo: (() -> Void)?, translated: Bool = false) -> some View {
        modifier(IslamArticleRowActions(title: title, copyText: copyText, scrollLabel: scrollLabel, onScrollTo: onScrollTo,
                                        translated: translated))
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
    /// True on the Islam tab's root: a result opens the article's index with the article pushed on top.
    /// The root is also the one translated screen these results sit on, so there the empty state and
    /// the rows' menus follow the interface; on the article screens they read English.
    var openViaHome: Bool = false
    /// The open article on an article page: it has its own IN THIS ARTICLE rows, so it is left out here.
    var excludeArticle: String? = nil
    /// The two headers: ARTICLES and IN THE ARTICLES on the indexes and the root, OTHER ARTICLES and IN
    /// OTHER ARTICLES under a page's own matches. The root passes its own, translated.
    var articlesTitle: String = AppLanguage.article("ARTICLES")
    var passagesTitle: String = AppLanguage.article("IN THE ARTICLES")
    /// True when the screen has other matches of its own (the Islam tab's resources), so an empty
    /// article result is not "nothing matched".
    var hasOtherResults: Bool = false
    /// The menu label for the scroll action: "Scroll To Article" on an index, the resource's name on
    /// the Islam tab root, where the scroll lands on the resource row instead.
    var scrollLabel: (IslamArticleEntry) -> String = { _ in "Scroll To Article" }
    /// Clears the search and scrolls the index to the article's row. Nil on an article page, which has
    /// no index rows to scroll to.
    var onScrollTo: ((IslamArticleEntry) -> Void)? = nil
    /// The screen's search filters (`IslamSearchFilterBar`): Search In and Topics narrow the titles
    /// as they narrow the passages, Match and Words shape both, and Show hides a kind.
    var filters: IslamSearchFilters = IslamSearchFilters()
    /// The ayah or hadith the query names (`IslamArticleSearchModel.reference`): a row on top opens it.
    var reference: IslamScriptureReference? = nil

    var body: some View {
        let searched = filters.searchedHomes(homes)
        let titleHits = filters.shows(.articles)
            ? IslamArticleSearch.titleHits(query, homes: searched, filters: filters).filter { $0.id != excludeArticle }
            : []
        let passages = !filters.shows(.passages) ? []
            : excludeArticle == nil ? contentHits : contentHits.filter { $0.article.id != excludeArticle }
        let showsReference = reference != nil && filters.shows(.scripture) && excludeArticle == nil

        if showsReference, let reference {
            IslamScriptureReferenceSection(reference: reference, translated: openViaHome)
        }

        if !titleHits.isEmpty {
            Section(header: SectionPillHeader(title: articlesTitle, count: titleHits.count)) {
                ForEach(titleHits) { entry in
                    IslamArticleTitleRow(entry: entry, query: query, showHome: showHome, openViaHome: openViaHome,
                                         scrollLabel: scrollLabel(entry), onScrollTo: scrollAction(for: entry))
                        .environment(\.searchWordRule, filters.match.wordRule)
                }
            }
        }

        if !passages.isEmpty {
            Section(header: SectionPillHeader(title: passagesTitle, count: passages.count)) {
                ForEach(passages) { hit in
                    IslamArticleContentRow(hit: hit, query: query, showHome: showHome, openViaHome: openViaHome,
                                           scrollLabel: hit.entry.map(scrollLabel) ?? "Scroll To Article",
                                           onScrollTo: hit.entry.flatMap(scrollAction))
                        // The colour follows the Match button, as the Quran tab's does.
                        .environment(\.searchWordRule, filters.match.wordRule)
                }
            }
        }

        if titleHits.isEmpty, passages.isEmpty, !isSearching, !hasOtherResults, !showsReference {
            Section {
                Text(verbatim: openViaHome ? String(localized: "No articles match your search.")
                                           : AppLanguage.article("No articles match your search."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// The row's "Scroll To Article" action, or nil where this screen has no index row to scroll to.
    private func scrollAction(for entry: IslamArticleEntry) -> (() -> Void)? {
        guard let onScrollTo else { return nil }
        return { onScrollTo(entry) }
    }
}

/// The "Ask AI about ..." row every searching Islam screen offers, with its sheet. Rendered only where
/// Apple Intelligence can run the chat.
struct AskAISearchSection: View {
    @Environment(\.appearance) private var appearance
    @State private var showAskAI = false

    let query: String
    /// True on a translated screen (the Islam tab's root). The index screens and article pages are
    /// English articles (`englishArticle()`), so there the section reads English with them.
    var translated: Bool = false

    var body: some View {
        if OnDeviceAsk.isAvailable {
            let asked = query.trimmingCharacters(in: .whitespacesAndNewlines)
            // Header gray: a search section (`SectionIconHeader.accentTitle`'s rule).
            Section(header: SectionIconHeader(translated ? String(localized: "ASK AI") : AppLanguage.article("ASK AI"), icon: "sparkles")) {
                Button {
                    Settings.shared.hapticFeedback()
                    showAskAI = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.caption)

                        Text(verbatim: translated ? String(localized: "Ask AI about \u{201C}\(asked)\u{201D}")
                                                  : AppLanguage.article("Ask AI about \u{201C}\(asked)\u{201D}"))
                            .font(.caption.weight(.semibold))

                        Spacer()

                        Image(systemName: "chevron.forward")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundColor(appearance.accent)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .contentSurface(clear: true, rectangle: true)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                // On the ROW, never on the Section. A modifier on a Section inside a List is applied
                // to each of the Section's children (the header and every row), so one `.sheet` here
                // became two presentation bridges bound to one Bool: both presented when it flipped,
                // UIKit refused the second ("Attempt to present ... which is already presenting"),
                // and SwiftUI answered by resetting the binding, which dismissed the first. The
                // sheet closed itself the first time it was opened (Abu, 2026-09-22).
                .sheet(isPresented: $showAskAI) {
                    if #available(iOS 16.0, *) {
                        AskAIChatSheet(initialQuestion: query)
                    }
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
                // The index screens are article screens: their bar reads English with them.
                SearchBar(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)),
                          placeholder: AppLanguage.article("Search"))
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

// MARK: - The article page's own search

/// The search bar at the foot of an article page and its results. Installed by
/// `selectableArticleList(article:)` around the page's List: while a query is typed the page fades out
/// under a results list that shares its wash and bottom insets - IN THIS ARTICLE first (every section
/// of the page that matches, tapped to scroll the page to that heading), then the other articles, which
/// push the way the index results do.
struct ArticleSearchChrome: ViewModifier {
    let articleID: String
    let proxy: ScrollViewProxy
    /// The page's landing handle (see `ArticleScroll`).
    let handle: ArticleScrollHandle
    let disableNowPlayingInset: Bool
    let topContentMargin: CGFloat
    /// The page is mid-landing and stays hidden (see `ArticleScroll`).
    var veiled = false
    /// The page's own sections, scanned in place of the corpus article when the corpus has none for
    /// `articleID` (a generated page). Its headings are the page's `ArticleHeader`s, so a hit still
    /// scrolls to its section. Nil on the catalog pages, which the corpus carries.
    var fallback: IslamArticle? = nil
    /// The page's text as the bar searches it, in place of the corpus: a page the corpus does not
    /// carry, or carries only in English (see `selectableArticleList(kind:)`, `searchablePage`).
    /// Built at the first query and kept while the page is the same (`articleID`).
    var page: (() -> IslamArticle?)? = nil
    var kind: ArticleSearchKind = .article
    /// The page's share button, beside the bar (`SearchBarWithShare`); nil for a page with no link.
    var share: PageShare? = nil

    @State private var searchText = ""
    /// `page`'s text, once built (a lesson stepped to its neighbour is a new page: see `searched`).
    @State private var builtPage: IslamArticle?
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// The heading a result asked for, consumed once the results have faded out.
    @State private var scrollTarget: String?
    @StateObject private var search = IslamArticleSearchModel()
    /// Match, Words and Without for the page's own search (2026-11-24), as the Quran reader's bar has.
    @State private var searchFilters = IslamSearchFilters()

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    func body(content: Content) -> some View {
        let searching = !query.isEmpty
        content
            // The section this page opened on is the page's own to land on (`SelectableArticleList` has
            // read it above here). Cleared inside, so nothing the page pushes (a door to a library or a
            // prophecy, a link in the prose) inherits it down the stack and lands on a heading of its own.
            .environment(\.articleScrollTarget, nil)
            // Faded rather than removed: the page keeps its scroll position and its measured rows, so the
            // scroll to a picked section starts from where the reader was. It stays faded through the
            // landing and comes back on the heading.
            .opacity(searching || veiled ? 0 : 1)
            .animation(.easeOut(duration: 0.2), value: veiled)
            .overlay {
                if searching {
                    ArticleSearchResults(articleID: articleID, query: query, kind: kind, search: search, filters: $searchFilters) { section in
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        // Hidden in the same update that clears the search, or the page starts fading
                        // back in at the old spot before the landing hides it again.
                        _ = handle.beginLanding()
                        // Words only the full article has: the full article, under the veil, so the
                        // landing finds the section drawn.
                        if section.only == .long { handle.length = .long }
                        withAnimation { searchText = "" }
                        scrollTarget = section.landing
                    }
                    .transition(.opacity)
                }
            }
            // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
            .collapseBarsOnScroll($barsCollapsed)
            .articleListStyle(disableNowPlayingInset: disableNowPlayingInset, topContentMargin: topContentMargin)
            .adaptiveSafeArea(edge: .bottom) {
                SearchBarWithShare(text: (AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut)),
                                   placeholder: kind == .article ? "Search this article" : String(localized: "Search this page"),
                                   share: share)
                    .minimizedBarStyle(barsCollapsed)
                    .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
                    .padding(.horizontal, 24)
                    .padding(.bottom, BottomBarCushion.standard)
                    .background(Color.white.opacity(0.00001))
            }
            .onAppear {
                IslamArticleSearchModel.prewarm()
                #if DEBUG
                // `-articleSearch <query>` seeds the page's search; `-articleSearchPick` alongside then
                // taps the first IN THIS ARTICLE row, the only headless way to screenshot both.
                if let seeded = IslamSearchDebug.launchQuery("-articleSearch"), searchText.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { searchText = seeded }
                    if ProcessInfo.processInfo.arguments.contains("-articleSearchPick") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            guard let first = search.articleHits.first else { return }
                            _ = handle.beginLanding()
                            withAnimation { searchText = "" }
                            scrollTarget = first.section.landing
                        }
                    }
                }
                #endif
            }
            .onChange(of: searchText) { text in
                search.update(query: text, homes: kind == .article ? Set(IslamArticleHome.allCases) : [], filters: searchFilters,
                              within: articleID, fallback: fallback, page: text.isEmpty ? nil : searched())
                if !text.isEmpty { scrollTarget = nil }
            }
            .onChange(of: searchFilters) { filters in
                guard !searchText.isEmpty else { return }
                search.update(query: searchText, homes: kind == .article ? Set(IslamArticleHome.allCases) : [], filters: filters,
                              within: articleID, fallback: fallback, page: searched())
            }
            .onChange(of: scrollTarget) { target in
                guard let target else { return }
                // The results are still fading out; scroll once the page is back.
                ArticleScroll.land(on: target, proxy: proxy, after: 0.2, handle: handle)
            }
    }

    /// The page's text for this query: built once, and again only for a new page (a lesson's
    /// Previous and Next replace the page in place) or while it is still loading (an explanation
    /// read off the main thread).
    private func searched() -> IslamArticle? {
        guard let page else { return nil }
        if let builtPage, builtPage.id == articleID { return builtPage }
        let built = page()
        builtPage = built
        return built
    }
}

/// The results over an article page: Ask AI, the page's own matching sections, then the other articles.
private struct ArticleSearchResults: View {
    let articleID: String
    let query: String
    let kind: ArticleSearchKind
    @ObservedObject var search: IslamArticleSearchModel
    @Binding var filters: IslamSearchFilters
    /// Called with the tapped section: clears the search and scrolls the page to where it lands (its
    /// heading or anchor), in the full article when only that has it.
    let onScrollTo: (IslamArticle.Section) -> Void

    private var translated: Bool { kind == .page }

    var body: some View {
        List {
            Group {
                AskAISearchSection(query: query, translated: translated)

                // Held until the scan has run, so the page never flashes "nothing matches" mid-keystroke.
                if !search.articleHits.isEmpty || !search.isSearching {
                    Section(header: SectionPillHeader(title: translated ? String(localized: "ON THIS PAGE") : "IN THIS ARTICLE",
                                                      count: search.articleHits.count)) {
                        if search.articleHits.isEmpty {
                            Text(verbatim: translated ? String(localized: "No matches on this page.")
                                                      : AppLanguage.article("Nothing in this article matches your search."))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(search.articleHits) { hit in
                            ArticleSectionHitRow(hit: hit, query: query, translated: translated) {
                                onScrollTo(hit.section)
                            }
                            .environment(\.searchWordRule, filters.match.wordRule)
                        }
                    }
                }

                if kind == .article {
                    IslamArticleSearchSections(
                        query: query,
                        homes: Set(IslamArticleHome.allCases),
                        contentHits: search.contentHits,
                        isSearching: search.isSearching,
                        showHome: true,
                        excludeArticle: articleID,
                        articlesTitle: "OTHER ARTICLES",
                        passagesTitle: "IN OTHER ARTICLES",
                        hasOtherResults: true,
                        filters: filters
                    )
                }
            }
            .themedListRowBackground()
        }
        // The page's own row of filters rides the RESULTS, not the page under them: an inset on the
        // page would move it while it lands on a section.
        .islamSearchFilterChrome($filters, isSearching: true, homes: [], kinds: [], translated: translated, inPage: true)
        // An overlay outside the page's own `englishArticle()`: an article's results are its English
        // too. A page of the app's own reads in the interface's language.
        .leftToRightContent(kind == .article && AppLanguage.pinsArticlesEnglish)
    }
}

/// One matching section of the open page: the heading in the accent, then the prose around the match.
/// Tapping scrolls the page to the heading - no push, the reader is already on the page.
private struct ArticleSectionHitRow: View {
    @Environment(\.appearance) private var appearance

    let hit: IslamArticleSearch.ContentHit
    let query: String
    /// On a page of the app's own: the menu follows the interface (see `ArticleSearchKind`).
    var translated = false
    let onSelect: () -> Void

    var body: some View {
        Button {
            Settings.shared.hapticFeedback()
            onSelect()
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    // A passage with no heading of its own (a Miracles article's paragraph) is its
                    // words alone.
                    if !hit.section.heading.isEmpty {
                        Text(hit.section.heading)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(appearance.accent)
                            .lineLimit(2)
                    }

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

                Spacer(minLength: 4)

                Image(systemName: "arrow.down.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .islamArticleRowActions(title: hit.section.heading.isEmpty ? hit.article.title : hit.section.heading,
                                copyText: hit.snippet,
                                scrollLabel: translated ? String(localized: "Scroll To Section") : "Scroll To Section",
                                onScrollTo: onSelect, translated: translated)
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
        "NamesOfAllahPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari 2736 and Sahih Muslim 2677, with the graded Sunan"),
            ArticleSource(title: "Al-Qawa'id al-Muthla", subtitle: "Ibn al-Uthaymin, the rules governing the names and attributes of Allah"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar al-Asqalani, on Sahih al-Bukhari 2736 and the enumeration"),
            ArticleSource(title: "Importance of knowing the Beautiful Names of Allah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/4043"),
            ArticleSource(title: "The 99 Names of Allah", subtitle: "Al-Asma al-Husna with transliteration and meanings", url: "https://99namesofallah.name/"),
        ],
        "QuranPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Itqan fi Ulum al-Quran", subtitle: "As-Suyuti"),
            ArticleSource(title: "Tafsir Ibn Kathir", subtitle: "Tafsir al-Quran al-Azim"),
            ArticleSource(title: "Muqaddimah fi Usul at-Tafsir", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Is the Quran the Word of Allah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/13804"),
            ArticleSource(title: "Miraculous aspects of the Holy Qur'an", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/245475"),
        ],
        "QuranRevealedPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar, on the Book of the Beginning of Revelation in Sahih al-Bukhari"),
            ArticleSource(title: "Tafsir Ibn Kathir", subtitle: "Tafsir al-Quran al-Azim"),
            ArticleSource(title: "Al-Jawab as-Sahih", subtitle: "Ibn Taymiyyah, on the proofs of prophethood"),
            ArticleSource(title: "Is the Quran the Word of Allah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/13804"),
            ArticleSource(title: "What Is the Evidence that Islam Is True?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/175339"),
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
        "ProphetAdamView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "The Story of Adam", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/223583"),
        ],
        "ProphetIdrisView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "Stories of the Prophets and Isra\u{2019}iliyyat reports", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/43012"),
        ],
        "ProphetNuhView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "The Story of Nuh and the Flood", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/175671"),
        ],
        "ProphetHudView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetSalihView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetIbrahimView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "Who was the sacrificed son, Ismail or Ishaq?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/106742"),
        ],
        "ProphetLutView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "The People of Lut and their punishment", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/38622"),
        ],
        "ProphetIsmailView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetIshaqView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetYaqubView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetYusufView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetAyyubView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetShuaybView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "Was the father-in-law of Musa the prophet Shu\u{2019}ayb?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/170696"),
        ],
        "ProphetMusaView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "The Story of Musa and Pharaoh", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/166187"),
        ],
        "ProphetHarunView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetDhulKiflView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "Was Dhul-Kifl a prophet?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/128203"),
        ],
        "ProphetDawudView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetSulaymanView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "Sulayman was free of magic", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12578"),
        ],
        "ProphetIlyasView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetAlyasaView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetYunusView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "The Dua of Dhun-Nun", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/145067"),
        ],
        "ProphetZakariyaView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetYahyaView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
        ],
        "ProphetIsaView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "Islam\u{2019}s belief about Jesus (peace be upon him)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12615"),
        ],
        "ProphetMuhammadView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on the ayat of each prophet\u{2019}s account"),
            ArticleSource(title: "Qasas al-Anbiya\u{2019}", subtitle: "Ibn Kathir, the stories of the prophets, drawn from al-Bidayah wan-Nihayah"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "The finality of the prophethood of Muhammad", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/113676"),
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
        "RububiyyahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Sharh Thalathat al-Usul", subtitle: "Ibn al-Uthaymin, the definitions of the three categories of tawhid (Majmu' Fatawa wa Rasa'il, vol. 6)"),
            ArticleSource(title: "Al-Qawa'id al-Arba'", subtitle: "Muhammad ibn Abd al-Wahhab, the first principle"),
            ArticleSource(title: "At-Tadmuriyyah", subtitle: "Ibn Taymiyyah, that no people held two equal makers (Majmu' al-Fatawa, vol. 3)"),
            ArticleSource(title: "What Is Tawhid Al-Rububiyyah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/49025"),
            ArticleSource(title: "Dividing Tawhid into categories", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/10262"),
        ],
        "UluhiyyahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Sharh Thalathat al-Usul", subtitle: "Ibn al-Uthaymin, the definitions of the three categories of tawhid (Majmu' Fatawa wa Rasa'il, vol. 6)"),
            ArticleSource(title: "Al-Usul ath-Thalathah", subtitle: "Muhammad ibn Abd al-Wahhab, the kinds of worship"),
            ArticleSource(title: "Kitab at-Tawhid", subtitle: "Muhammad ibn Abd al-Wahhab, with al-Qawl al-Mufid by Ibn al-Uthaymin"),
            ArticleSource(title: "Al-Ubudiyyah", subtitle: "Ibn Taymiyyah, the definition of worship"),
            ArticleSource(title: "Madarij as-Salikin", subtitle: "Ibn al-Qayyim, the two kinds of tawhid (vol. 3)"),
            ArticleSource(title: "Al-Ikhlas wan-Niyyah", subtitle: "Ibn Abi ad-Dunya, al-Fudayl ibn Iyad on the sincere and correct deed"),
            ArticleSource(title: "Conditions of Acceptability of Deeds by Allah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/14258"),
            ArticleSource(title: "The real meaning of ‘uboodiyyah (true submission to Allah)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/49016"),
        ],
        "AsmaSifatView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Sharh Thalathat al-Usul", subtitle: "Ibn al-Uthaymin, the definitions of the three categories of tawhid (Majmu' Fatawa wa Rasa'il, vol. 6)"),
            ArticleSource(title: "Al-Aqidah al-Wasitiyyah", subtitle: "Ibn Taymiyyah, with the commentary of Ibn al-Uthaymin"),
            ArticleSource(title: "At-Tadmuriyyah", subtitle: "Ibn Taymiyyah, the two principles on the attributes (Majmu' al-Fatawa, vol. 3)"),
            ArticleSource(title: "Al-Qawa'id al-Muthla", subtitle: "Ibn al-Uthaymin, the rules on the names and attributes of Allah"),
            ArticleSource(title: "Al-Asma' was-Sifat and Sharh Usul I'tiqad Ahl as-Sunnah", subtitle: "Al-Bayhaqi and al-Lalaka'i, the statements of the Salaf with their chains"),
            ArticleSource(title: "Ash-Shari'ah and Mukhtasar al-'Uluw", subtitle: "Al-Ajurri; and adh-Dhahabi's al-'Uluw abridged by al-Albani, with his gradings"),
            ArticleSource(title: "Dar' Ta'arud al-'Aql wan-Naql", subtitle: "Ibn Taymiyyah, on tafwid (vol. 1)"),
            ArticleSource(title: "How to Understand the Names and Attributes of Allah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/178915"),
            ArticleSource(title: "Meaning of tafweed with regard to the names and attributes of Allah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/138920"),
            ArticleSource(title: "Is Allah above the Throne?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/11035"),
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
            ArticleSource(title: "An-Nashr fi al-Qira'at al-'Ashr", subtitle: "Ibn al-Jazari, on the Uthmanic copies and why they were left without dots"),
            ArticleSource(title: "Majmu' al-Fatawa", subtitle: "Ibn Taymiyyah, his answer on the seven ahruf (vol. 13)"),
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
        "QuranWordsPillarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Iqtida' as-Sirat al-Mustaqim", subtitle: "Ibn Taymiyyah, on Arabic as part of the religion (ed. Nasir al-Aql, vol. 1)"),
            ArticleSource(title: "Tafsir as-Sadi", subtitle: "Abd ar-Rahman as-Sadi, Taysir al-Karim ar-Rahman"),
            ArticleSource(title: "Tafsir Ibn Kathir", subtitle: "Tafsir al-Quran al-Azim"),
            ArticleSource(title: "The Quranic Arabic Corpus", subtitle: "The word, dictionary-word and root counts, checked against the app's Hafs text"),
            ArticleSource(title: "Will a person be rewarded for reading Quran even if he does not know the meaning of what he reads?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/4040"),
            ArticleSource(title: "Do You Get Reward for Listening to the Quran Without Understanding It?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/150633"),
            ArticleSource(title: "Is it waajib (obligatory) for non-Arabs to learn Arabic?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/6524"),
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
            ArticleSource(title: "Majmu' al-Fatawa", subtitle: "Ibn Taymiyyah, his answer on the seven ahruf (vol. 13)"),
            ArticleSource(title: "Al-Ibanah an Ma'ani al-Qira'at", subtitle: "Makki ibn Abi Talib"),
            ArticleSource(title: "Al-Itqan fi Ulum al-Quran", subtitle: "As-Suyuti"),
            ArticleSource(title: "The revelation of the Quran in seven styles (ahruf, sing. harf)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/5142"),
            ArticleSource(title: "'Uthmaan's compilation of the Mushaf in one style (harf)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/125091"),
        ],
        "RiwayatDifferencesView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Hirz al-Amani wa Wajh at-Tahani (ash-Shatibiyyah)", subtitle: "Al-Qasim ibn Firruh ash-Shatibi, the principles of the seven readings"),
            ArticleSource(title: "Ad-Durrah al-Mudiyyah", subtitle: "Ibn al-Jazari, the three readings that complete the ten"),
            ArticleSource(title: "An-Nashr fi al-Qira’at al-‘Ashr", subtitle: "Ibn al-Jazari, the ten readings and their narrators"),
            ArticleSource(title: "Al-Muhkam fi Naqt al-Masahif", subtitle: "Abu ‘Amr ad-Dani, on the marks added to the mushaf"),
            ArticleSource(title: "The printed mushafs of the twenty riwayat", subtitle: "The King Fahd Complex and Islamweb editions this app’s texts are taken from"),
        ],
        "HadithSciencesView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "The Muqaddimah of Sahih Muslim", subtitle: "Imam Muslim on the isnad, with the sayings of Ibn Sirin and Ibn al-Mubarak"),
            ArticleSource(title: "Muqaddimah Ibn as-Salah", subtitle: "Ibn as-Salah, ‘Ulum al-Hadith, with ash-Shafi‘i’s ar-Risalah on the conditions of a report"),
            ArticleSource(title: "Nuzhat an-Nazar and Taqrib at-Tahdhib", subtitle: "Ibn Hajar al-‘Asqalani, on the terms of the science and the ranks of the narrators"),
            ArticleSource(title: "Conditions of a saheeh (sound) hadeeth", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/79163"),
            ArticleSource(title: "The science of hadith is based on reason and shar‘i guidelines", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/239540"),
        ],
        "HadithPreservationView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Fath al-Bari and Hady as-Sari", subtitle: "Ibn Hajar al-‘Asqalani, on the writing of hadith and his count of Sahih al-Bukhari"),
            ArticleSource(title: "Muqaddimah Ibn as-Salah", subtitle: "Ibn as-Salah, ‘Ulum al-Hadith, on the writing of hadith and the two Sahihs"),
            ArticleSource(title: "Sahifah Hammam ibn Munabbih", subtitle: "Edited by Muhammad Hamidullah, with an introduction on the early compilation of hadith"),
            ArticleSource(title: "The soundness of the hadeeth “Do not write anything from me…” and explanation of what it means", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/22394"),
            ArticleSource(title: "What are the reasons why the hadiths were written down?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/488953"),
        ],
        "HadithRejectorsView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ar-Risalah and Jima' al-'Ilm", subtitle: "Ash-Shafi'i, on the Sunnah as the Wisdom, and his debate with a man who rejected all reports"),
            ArticleSource(title: "Al-Ihkam fi Usul al-Ahkam", subtitle: "Ibn Hazm, on the one who takes only what he finds in the Quran"),
            ArticleSource(title: "Jami' Bayan al-'Ilm wa Fadlih", subtitle: "Ibn Abd al-Barr, the chapter on the place of the Sunnah beside the Book"),
            ArticleSource(title: "AHL Al-Quran Movement in Colonial Punjab: Exclusion of Hadith Literature", subtitle: "Saadia Sumbal, Journal of Social Sciences and Humanities 29:1 (2021)", url: "https://ojs.aiou.edu.pk/index.php/jssh/article/view/2202"),
            ArticleSource(title: "Refutation of those who quote the Holy Quran to reject the Sunnah and justify not acting upon it", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/256435"),
        ],
        "ProvingCaseView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the methodology and the note on intellectual honesty", url: "https://provingislam.net/"),
            ArticleSource(title: "Nuzhat an-Nazar", subtitle: "Ibn Hajar al-Asqalani, on the mutawatir report and the certainty it gives"),
            ArticleSource(title: "Al-Jawab as-Sahih li-man Baddala Din al-Masih", subtitle: "Ibn Taymiyyah, his reply to a Christian treatise sent from Cyprus"),
        ],
        "ProvingFingerprintView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on the human fingerprint test", url: "https://provingislam.net/"),
            ArticleSource(title: "Tafsir al-Quran al-Azim", subtitle: "Ibn Kathir, on 4:82 and 18:86"),
            ArticleSource(title: "Ibn al-Nafis, the pulmonary circulation, and the Islamic Golden Age", subtitle: "John B. West, Journal of Applied Physiology, 2008", url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC2612469/"),
            ArticleSource(title: "The Variation of Animals and Plants under Domestication", subtitle: "Charles Darwin, 1868, where he proposed pangenesis"),
            ArticleSource(title: "Dialogue Concerning the Two Chief World Systems", subtitle: "Galileo Galilei, 1632, whose fourth day sets out his theory of the tides"),
        ],
        "ProvingProphetView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "As-Silsilah as-Sahihah", subtitle: "Muhammad Nasir ad-Din al-Albani, no. 92: the report of ‘Aqil ibn Abi Talib, graded hasan"),
            ArticleSource(title: "Al-Jami‘ li-Ahkam al-Quran", subtitle: "Al-Qurtubi, on what the Prophet concealed in Quran 33:37"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on the Prophet’s character and the psychology of fraud", url: "https://provingislam.net/"),
            ArticleSource(title: "Detailed discussion about the verse “But you did hide in yourself that which Allaah will make manifest” [al-Ahzaab 33:37]", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/96464"),
        ],
        "ProvingContinuationView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Majmu‘ al-Fatawa", subtitle: "Ibn Taymiyyah, vol. 18, on “I was a prophet while Adam was between spirit and body”"),
            ArticleSource(title: "The Holy Bible, King James Version", subtitle: "Deuteronomy 6:4 and Mark 12:29"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on prophetic continuation", url: "https://provingislam.net/"),
            ArticleSource(title: "Muhammad (peace and blessings of Allah be upon him) is the Seal of the Prophets and Messengers", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/113393"),
        ],
        "ProvingStylometryView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "I'jaz al-Quran", subtitle: "Abu Bakr al-Baqillani, the chapter on the speech of the Prophet"),
            ArticleSource(title: "The Chronology of the Qurʾān: A Stylometric Research Program", subtitle: "Behnam Sadeghi, Arabica 58 (2011), pages 210–299"),
            ArticleSource(title: "Author discrimination between the Holy Quran and Prophet’s statements", subtitle: "Halim Sayoud, Literary and Linguistic Computing 27:4 (2012), pages 427–444", url: "https://academic.oup.com/dsh/article-abstract/27/4/427/941526"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on stylometry", url: "https://provingislam.net/"),
        ],
        "ProvingPreservationView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Jami' li-Ahkam al-Quran", subtitle: "Al-Qurtubi, on 15:9 and the scriptures entrusted to their guardians"),
            ArticleSource(title: "Ṣanʿāʾ 1 and the Origins of the Qurʾān", subtitle: "Behnam Sadeghi and Mohsen Goudarzi, Der Islam 87 (2012), pages 1–129"),
            ArticleSource(title: "A Textual Commentary on the Greek New Testament", subtitle: "Bruce M. Metzger, on Mark 16:9–20, John 7:53–8:11 and 1 John 5:7–8"),
            ArticleSource(title: "Birmingham Qur'an manuscript dated among the oldest in the world", subtitle: "University of Birmingham, 22 July 2015", url: "https://www.birmingham.ac.uk/news-archive/2015/birmingham-quran-manuscript-dated-among-the-oldest-in-the-world"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on preservation", url: "https://provingislam.net/"),
        ],
        "ProvingIjazView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Itqan fi Ulum al-Quran", subtitle: "As-Suyuti, the chapter on the inimitability of the Quran"),
            ArticleSource(title: "Al-Mustadrak 'ala as-Sahihayn", subtitle: "Al-Hakim, with adh-Dhahabi's Talkhis: the report of al-Walid ibn al-Mughirah"),
            ArticleSource(title: "Al-Isti'ab fi Ma'rifat al-Ashab", subtitle: "Ibn 'Abd al-Barr, the entry on Labid ibn Rabi'ah"),
            ArticleSource(title: "Miraculous aspects of the Holy Qur’an", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/245475"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on the unmatched Qur'an", url: "https://provingislam.net/"),
        ],
        "ProvingScienceView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari"),
            ArticleSource(title: "Jami' al-Bayan and Tafsir al-Quran al-'Azim", subtitle: "al-Tabari and Ibn Kathir, for the classical range of meaning of each verse"),
            ArticleSource(title: "Al-Muwafaqat", subtitle: "al-Shatibi, on the limits of reading the sciences into the Quran"),
            ArticleSource(title: "History of Animals, Meteorology and Generation of Animals", subtitle: "Aristotle, the Greek science the Quran's age inherited, on bees, hail, metals and the embryo"),
            ArticleSource(title: "Development of Religion and Thought in Ancient Egypt", subtitle: "James Henry Breasted (1912), on the Pyramid Texts"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on scientific compatibility", url: "https://provingislam.net/"),
        ],
        "ProvingProphecyView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with Sunan Abi Dawud, Jami` at-Tirmidhi, Sunan an-Nasa'i and Sunan Ibn Majah"),
            ArticleSource(title: "Sharh Sahih Muslim", subtitle: "al-Nawawi, on the hadith of the Turks and of the last Chosroes and Caesar"),
            ArticleSource(title: "'Awn al-Ma'bud", subtitle: "The commentary on Sunan Abi Dawud, on the hadith of al-Basrah and the Tigris"),
            ArticleSource(title: "The History of the Decline and Fall of the Roman Empire", subtitle: "Edward Gibbon, chapter 46, on the Persian war of Heraclius"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on prophecy", url: "https://provingislam.net/"),
            ArticleSource(title: "Proofs of Islam", subtitle: "Proving Islam: prophecies and historical accuracies", url: "https://provingislam.com/proofs"),
        ],
        "ProvingSourcesView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "The Bible in Arabic", subtitle: "Sidney H. Griffith, Princeton University Press, 2013"),
            ArticleSource(title: "Tafsir al-Quran al-'Azim", subtitle: "Ibn Kathir, on 6:105, 16:103 and 2:102"),
            ArticleSource(title: "Majmu' al-Fatawa", subtitle: "Ibn Taymiyyah, on the protection of the prophets (4/319-320)"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on historical and scriptural knowledge", url: "https://provingislam.net/"),
            ArticleSource(title: "Qur'anic Accuracy Vs. Biblical Error: The Kings & Pharaohs of Egypt", subtitle: "Islamic Awareness, citing Gardiner's Egyptian Grammar and Wilkinson's Dictionary of Ancient Egypt", url: "https://www.islamic-awareness.org/quran/contrad/external/josephdetail.html"),
        ],
        "ProvingBibleView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with al-Hakim’s Mustadrak"),
            ArticleSource(title: "Al-Jawab as-Sahih li man Baddala Din al-Masih", subtitle: "Ibn Taymiyyah, the chapters on the glad tidings of the earlier prophets and the Faraqlit"),
            ArticleSource(title: "Hidayat al-Hayara fi Ajwibat al-Yahud wan-Nasara", subtitle: "Ibn al-Qayyim, with the debate on Deuteronomy 18 in the Maghrib"),
            ArticleSource(title: "Izhar al-Haqq", subtitle: "Rahmatullah al-Kairanawi, the sixteenth glad tiding: the parable of the vineyard"),
            ArticleSource(title: "The Holy Bible, King James Version", subtitle: "Every Bible passage quoted; the Jewish readings from Rashi and the Aramaic Targum"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on Biblical prophecies", url: "https://provingislam.net/"),
        ],
        "ProvingScriptureView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari"),
            ArticleSource(title: "Tafsir al-Quran al-‘Azim", subtitle: "Ibn Kathir, on 5:48, 2:63, 7:171 and 27:76, and his introduction on the reports of the People of the Book"),
            ArticleSource(title: "The Mishnah, the Talmud and the Midrash", subtitle: "Mishnah Sanhedrin 4:5; Babylonian Talmud, Shabbat 88a and Bava Metzia 86b; Genesis Rabbah 48:14; Pirkei de-Rabbi Eliezer 21; Midrash Tanhuma, Bereshit 10"),
            ArticleSource(title: "The Holy Bible, King James Version, and the Arabic Gospel of the Infancy", subtitle: "The Bible as quoted; the infancy gospel in the Ante-Nicene Fathers, volume 8"),
            ArticleSource(title: "The failure of a Jewish program of public satire in the squares of Medina", subtitle: "Reuven Firestone, in the journal Judaism (1997), on “we hear and we disobey”"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on the Quran and prior scripture", url: "https://provingislam.net/"),
        ],
        "ProvingEthicsView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Al-Arba‘un an-Nawawiyyah", subtitle: "An-Nawawi, hadith 32 (no harm) and 33 (proof on the claimant), with his gradings"),
            ArticleSource(title: "On Liberty", subtitle: "John Stuart Mill, 1859: the harm principle"),
            ArticleSource(title: "The “Constitution” of Medina: Translation, Commentary, and Meaning Today", subtitle: "Ovamir Anjum, Yaqeen Institute for Islamic Research, 2021"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on ethics and law", url: "https://provingislam.net/"),
            ArticleSource(title: "Which Islamic or Qur'anic verse or quote is written on Harvard's main gate?", subtitle: "Harvard Library, Ask a Librarian: Quran 4:135 in the Words of Justice exhibit", url: "https://ask.library.harvard.edu/faq/82441"),
        ],
        "ProvingJesusView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "The Holy Bible, King James Version", subtitle: "The Gospels, Acts and Hebrews, quoted in the standard text of the Authorized Version"),
            ArticleSource(title: "Al-Jawab as-Sahih li man Baddala Din al-Masih", subtitle: "Ibn Taymiyyah, on John 17:3 and John 20:17 among the Gospels’ own witness"),
            ArticleSource(title: "The Catholic Encyclopedia", subtitle: "“The Blessed Trinity” (1912), on Theophilus of Antioch and Tertullian"),
            ArticleSource(title: "Trinity: History of Trinitarian Doctrines", subtitle: "Stanford Encyclopedia of Philosophy", url: "https://plato.stanford.edu/entries/trinity/trinity-history.html"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on Jesus", url: "https://provingislam.net/"),
        ],
        "ProvingGodView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Dar' Ta'arud al-Aql wan-Naql", subtitle: "Ibn Taymiyyah, on why a regress of causes is impossible"),
            ArticleSource(title: "Just Six Numbers", subtitle: "Martin Rees (1999), the constants on which stars and life depend"),
            ArticleSource(title: "The Beginning of the Universe", subtitle: "Alexander Vilenkin, Inference: International Review of Science (2015), on the Borde-Guth-Vilenkin theorem"),
            ArticleSource(title: "Fine-Tuning", subtitle: "Stanford Encyclopedia of Philosophy", url: "https://plato.stanford.edu/entries/fine-tuning/"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on God’s existence", url: "https://provingislam.net/"),
        ],
        "ProvingQuestionsView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the section on the key questions", url: "https://provingislam.net/"),
            ArticleSource(title: "King or Pharaoh?", subtitle: "Mohammad Baqer, Proving Islam", url: "https://provingislam.com/proofs/kingorpharaoh"),
            ArticleSource(title: "Author discrimination between the Holy Quran and Prophet’s statements", subtitle: "Halim Sayoud, Literary and Linguistic Computing 27:4, 2012"),
            ArticleSource(title: "The Chronology of the Qur’an: A Stylometric Research Program", subtitle: "Behnam Sadeghi, Arabica 58, 2011"),
            ArticleSource(title: "The Codex of a Companion of the Prophet and the Qur’an of the Prophet", subtitle: "Behnam Sadeghi and Uwe Bergmann, Arabica 57, 2010, on the Sana’a palimpsest"),
        ],
        "ProvingClosingView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "The Complete Case", subtitle: "Proving Islam, the closing argument and its pillars", url: "https://provingislam.net/"),
            ArticleSource(title: "Proofs of Islam", subtitle: "Proving Islam, the proof articles on prophecy and history", url: "https://provingislam.com/proofs"),
            ArticleSource(title: "Nuzhat an-Nazar", subtitle: "Ibn Hajar al-Asqalani, on the mutawatir report and the certainty it gives"),
        ],
        "QiraatView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "An-Nashr fil-Qira'at al-Ashr", subtitle: "Ibn al-Jazari"),
            ArticleSource(title: "Al-Ibanah an Ma'ani al-Qira'at", subtitle: "Makki ibn Abi Talib"),
            ArticleSource(title: "Al-Itqan fi Ulum al-Quran", subtitle: "As-Suyuti"),
            ArticleSource(title: "The revelation of the Quran in seven styles (ahruf, sing. harf)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/5142"),
            ArticleSource(title: "Ruling on one who, whilst praying, switches between the seven modes of recitation that were narrated via mutawaatir reports", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/192182"),
            ArticleSource(title: "Majmu' al-Fatawa", subtitle: "Ibn Taymiyyah, his answer on the seven ahruf and the readings (vol. 13)"),
            ArticleSource(title: "Al-Majmu' Sharh al-Muhadhdhab", subtitle: "An-Nawawi, on reciting the shadh readings (3/392)"),
            ArticleSource(title: "Ghayat an-Nihayah fi Tabaqat al-Qurra'", subtitle: "Ibn al-Jazari, the lives and teachers of the readers"),
            ArticleSource(title: "Mizan al-I'tidal", subtitle: "Adh-Dhahabi, on Humran ibn A'yan"),
        ],
        "HijriCalendarView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir Ibn Kathir", subtitle: "Tafsir al-Quran al-Azim"),
            ArticleSource(title: "Al-Bidayah wan-Nihayah", subtitle: "Ibn Kathir"),
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar al-Asqalani, commentary on Sahih al-Bukhari"),
            ArticleSource(title: "Why Is the Age of Islam Based on the Beginning of Hijrah?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/176819"),
            ArticleSource(title: "The reason why the Hijri months are called by their well-known names", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/211395"),
        ],
        "SacredMonthsView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir Ibn Kathir", subtitle: "Tafsir al-Quran al-Azim, on Quran 9:36-37"),
            ArticleSource(title: "Tabyin al-Ajab bima Warada fi Fadl Rajab", subtitle: "Ibn Hajar al-Asqalani, on what is and is not established about Rajab"),
            ArticleSource(title: "Lataif al-Maarif", subtitle: "Ibn Rajab al-Hanbali, on the seasons of the year and their acts of worship"),
            ArticleSource(title: "Majmu al-Fatawa", subtitle: "Ibn Taymiyyah, on the sacred months and on innovated observances"),
            ArticleSource(title: "The virtue of the month of Muharram and fasting on Ashura", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/21776"),
            ArticleSource(title: "Innovations in the month of Rajab", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/75394"),
        ],
        "MoonSightingView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar al-Asqalani, the book of fasting, on sighting the crescent"),
            ArticleSource(title: "Al-Majmu Sharh al-Muhadhdhab", subtitle: "An-Nawawi, on the sighting and on the differing places of moonrise"),
            ArticleSource(title: "Fatawa Ibn Baz and the Permanent Committee for Scholarly Research and Ifta", subtitle: "On sighting versus calculation, and on one sighting for the ummah"),
            ArticleSource(title: "Ash-Sharh al-Mumti", subtitle: "Ibn al-Uthaymin, on each land following its own sighting"),
            ArticleSource(title: "Sighting the new moon of Ramadan and relying on astronomical calculations", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/1226"),
            ArticleSource(title: "Do the people of every land have their own sighting?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12666"),
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
            ArticleSource(title: "Khalq Af'al al-'Ibad", subtitle: "Al-Bukhari, against the Jahmiyyah"),
            ArticleSource(title: "Minhaj as-Sunnah an-Nabawiyyah and at-Tis'iniyyah", subtitle: "Ibn Taymiyyah, on the two senses of Ahl as-Sunnah and the degrees of the Jahmiyyah"),
            ArticleSource(title: "Shifa' al-'Alil", subtitle: "Ibn al-Qayyim, the four levels of the decree"),
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
            ArticleSource(title: "Al-Ansab", subtitle: "As-Sam'ani, the entry on the ascription “as-Salafi”"),
            ArticleSource(title: "Siyar A'lam an-Nubala'", subtitle: "Adh-Dhahabi, the imams he called Salafi"),
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
            ArticleSource(title: "Jami' al-Ulum wal-Hikam", subtitle: "Ibn Rajab, on hadith 28, \"every innovation is misguidance\""),
            ArticleSource(title: "The Notion of Bid'ah Hasanah: the Statements of Imam ash-Shafi'i", subtitle: "Bidah.com, part 3 of the series", url: "https://www.bidah.com/articles/rouuz-the-notion-of-bidah-hasanah-good-innovation-in-worship-destroyed-part-3.cfm"),
            ArticleSource(title: "Majmu' al-Fatawa", subtitle: "Ibn Taymiyyah, the definition of bid'ah in belief and worship (vol. 18)"),
            ArticleSource(title: "Which Group Is the Saved One?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/90112"),
        ],
        "QiraatContradictView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "An-Nashr fi al-Qira'at al-'Ashr", subtitle: "Ibn al-Jazari, on the three kinds of difference between the readings"),
            ArticleSource(title: "Majmu' al-Fatawa", subtitle: "Ibn Taymiyyah, the fatwa on the seven ahruf (vol. 13)"),
            ArticleSource(title: "Tafsir Ibn Kathir", subtitle: "Tafsir al-Quran al-Azim, on al-Ma'idah 5:6"),
            ArticleSource(title: "The revelation of the Quran in seven styles (ahruf)", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/5142"),
            ArticleSource(title: "The seven modes of recitation are mutawaatir", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/178120"),
        ],
        "AwrahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Majmu' al-Fatawa", subtitle: "Ibn Taymiyyah, the chapter on dress in prayer (vol. 22)"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, on the conditions of prayer"),
            ArticleSource(title: "Fatawa al-Lajnah ad-Da'imah", subtitle: "The Permanent Committee, fatwas 5128 and 21302"),
            ArticleSource(title: "Risalat al-Hijab and Jilbab al-Mar'ah al-Muslimah", subtitle: "Ibn al-Uthaymin and al-Albani, the two views on the face"),
            ArticleSource(title: "Evidence that Men's Awrah Is from the Navel to the Knee", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/34976"),
            ArticleSource(title: "What is a woman permitted to uncover in front of other women and mahrams?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/34745"),
        ],
        "MawlidView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Iqtida' as-Sirat al-Mustaqim", subtitle: "Ibn Taymiyyah"),
            ArticleSource(title: "Al-Mawrid fi Amal al-Mawlid", subtitle: "Al-Fakihani"),
            ArticleSource(title: "Majmu' Fatawa wa Maqalat", subtitle: "Ibn Baz"),
            ArticleSource(title: "Celebrating Mawlid al-Nabi (Muhammad's Birthday): Allowed?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/249"),
            ArticleSource(title: "Ruling on celebrating the birthday of the Messenger (blessings and peace of Allah be upon him) without any singing or other haram things", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/148053"),
        ],
        "EvilEyeView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Tafsir al-Quran al-'Azim", subtitle: "Ibn Kathir, on al-Qalam 68:51 and Yusuf 12:67"),
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar al-Asqalani, the Book of Medicine: ruqyah for the eye and “the eye is real”"),
            ArticleSource(title: "Sharh Sahih Muslim", subtitle: "An-Nawawi, on the hadiths of the eye, the decree, and envy"),
            ArticleSource(title: "Zad al-Ma'ad and Bada'i' al-Fawa'id", subtitle: "Ibn al-Qayyim, on the eye, the envier, and their cure"),
            ArticleSource(title: "Majmu' al-Fatawa", subtitle: "Ibn Taymiyyah, on envy and its kinds"),
            ArticleSource(title: "Kitab at-Tawhid and al-Qawl al-Mufid", subtitle: "Muhammad ibn Abd al-Wahhab, the chapter on ruqyah and amulets, with Ibn al-Uthaymin's commentary on amulets, causes, and omens"),
            ArticleSource(title: "Majmu' Fatawa Ibn Baz and Majmu' Fatawa Ibn al-Uthaymin", subtitle: "On amulets made of Quran, what to say on admiring, and precaution against the eye"),
            ArticleSource(title: "Fatawa al-Lajnah ad-Da'imah", subtitle: "The Standing Committee, volume 1: the eye, amulets, and fumigation"),
            ArticleSource(title: "Protection from the Evil Eye: How?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/20954"),
            ArticleSource(title: "Can a man harm his beautiful wife with the “evil eye”?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/7190"),
            ArticleSource(title: "Types of amulets and superstition that some Muslims fall into", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/126359"),
            ArticleSource(title: "Meaning of Hasad", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/105471"),
            ArticleSource(title: "Waswas (Satanic Whispers) About the Evil Eye", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/89604"),
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
            ArticleSource(title: "Is Talking during Khutbah Permissible?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/45651"),
            ArticleSource(title: "What Are the Recommended Acts of Worship on Friday?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/13815"),
        ],
        "KhutbahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in his khutbahs"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Khutbat al-Hajah", subtitle: "Al-Albani, the opening the Prophet taught his Companions"),
            ArticleSource(title: "Al-Ajwibah an-Nafi'ah", subtitle: "Al-Albani, on the Friday Adhan and khutbah"),
            ArticleSource(title: "Conditions of Friday Khutbah", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/115854"),
            ArticleSource(title: "Friday khutbah in languages other than Arabic", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/112041"),
            ArticleSource(title: "What is your opinion of a Jumu’ah khutbah that, along with the prayer, lasts ten minutes?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/112084"),
        ],
        "AdhanOtherView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Sifat Salat an-Nabi", subtitle: "Al-Albani, the Prophet's prayer described from the sahih hadith"),
            ArticleSource(title: "How to Call Adhan", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/21376"),
            ArticleSource(title: "Is it valid to recite the adhan with thirteen phrases, including two takbirs at the beginning and without tarji` (repeating) of the Shahadatayn?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/340598"),
            ArticleSource(title: "Who Should Give Adhan?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/196257"),
            ArticleSource(title: "Is It Permissible to Give Recorded Adhan from Radio?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/48990"),
        ],
        "IqamahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Ash-Sharh al-Mumti'", subtitle: "Ibn al-Uthaymin, commentary on Zad al-Mustaqni'"),
            ArticleSource(title: "Bulugh al-Maram", subtitle: "Ibn Hajar al-Asqalani, the hadith of rulings with their grades"),
            ArticleSource(title: "Sifat Salat an-Nabi", subtitle: "Al-Albani, the Prophet's prayer described from the sahih hadith"),
            ArticleSource(title: "Iqamah: How Is It Done?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/10458"),
            ArticleSource(title: "Is it prescribed to repeat the phrases of the iqaamah twice?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/111893"),
            ArticleSource(title: "Is there a set time for the iqaamah (call immediately before the prayer)?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/97009"),
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
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar al-‘Asqalani, commentary on Sahih al-Bukhari, on the Istikharah hadith"),
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
        "RuqyahView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Kitab at-Tawhid", subtitle: "Muhammad ibn Abd al-Wahhab, the chapters on ruqyah, amulets and nushrah"),
            ArticleSource(title: "Al-Qawl al-Mufid 'ala Kitab at-Tawhid", subtitle: "Ibn al-Uthaymin, its explanation"),
            ArticleSource(title: "Fath al-Bari", subtitle: "Ibn Hajar al-Asqalani, on the conditions of ruqyah"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's medicine"),
            ArticleSource(title: "Majmu' Fatawa Ibn Baz", subtitle: "Ibn Baz, on ruqyah and the treatment of magic"),
            ArticleSource(title: "Selection of Verses and Supplications for Incantation Purposes", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/175189"),
            ArticleSource(title: "What conditions should be met by a “raaqi”?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/7874"),
            ArticleSource(title: "“Recite your ruqyahs to me. There is nothing wrong with a ruqyah that does not involve shirk”", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/209745"),
            ArticleSource(title: "Taking payment for reciting Qur’aan over a sick person", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/12627"),
            ArticleSource(title: "UnIslamic ruqyah may be a cause of harm", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/180492"),
        ],
        "EvilEyeGuideView": [
            ArticleSource(title: "The Quran and the authentic Sunnah", subtitle: "Saheeh International translation; Sahih al-Bukhari and Sahih Muslim, with the graded Sunan"),
            ArticleSource(title: "Zad al-Ma'ad", subtitle: "Ibn al-Qayyim, the Prophet's guidance in treating the one struck by the eye"),
            ArticleSource(title: "Fath al-Bari and Sharh Sahih Muslim", subtitle: "Ibn Hajar and an-Nawawi, on the washing of the one the eye came from"),
            ArticleSource(title: "Al-Muwatta", subtitle: "Malik ibn Anas, the Book of the Eye: the washing of 'Amir ibn Rabi'ah"),
            ArticleSource(title: "Bada'i' al-Fawa'id", subtitle: "Ibn al-Qayyim, on Surah al-Falaq: ten things that turn away the envier's harm"),
            ArticleSource(title: "Majmu' Fatawa wa Rasa'il and al-Qawl al-Mufid", subtitle: "Ibn al-Uthaymin, on the eye, its treatment, and lawful precaution"),
            ArticleSource(title: "Majmu' Fatawa Ibn Baz and Fatawa Nur 'ala ad-Darb", subtitle: "Ibn Baz, on treating the eye, what to say, and amulets"),
            ArticleSource(title: "Fatawa al-Lajnah ad-Da'imah", subtitle: "The Standing Committee, volume 1: the eye, its washing, and fumigation"),
            ArticleSource(title: "Protection from the Evil Eye: How?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/20954"),
            ArticleSource(title: "How to Protect Yourself from the Evil Eye", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/11359"),
            ArticleSource(title: "Barak Allahu Laka or ‘Alayk: Ward off the Evil Eye by It", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/130786"),
            ArticleSource(title: "How can a person know who has envied him, and how should the one who has been envied be treated?", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/45659"),
            ArticleSource(title: "Wearing gold on which Aayat al-Kursiy is engraved or which is in the shape of an eye or hand", subtitle: "IslamQA", url: "https://islamqa.info/en/answers/91370"),
        ],
    ]
}
