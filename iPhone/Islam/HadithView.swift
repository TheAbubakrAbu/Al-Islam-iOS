import SwiftUI

// The Hadith tab: all 17 collections served by AhmedBaset/hadith-json (jsDelivr CDN), fetched per book on
// first open and cached to disk forever after - the same fetch-once model as tafsir. The three forty-hadith
// collections are bundled INSIDE the app, so they work offline from the first launch. Browsing goes
// collection -> chapters -> hadiths (list or paged), with search at every level, reference lookups
// ("bukhari 5"), all-books search, favorites, and per-hadith bookmarks.

#if os(iOS)

// MARK: - Catalog

/// One collection in the catalog: where it lives on the CDN, how it's titled, and its scholarly context.
/// The catalog is static so the tab renders instantly with nothing downloaded.
struct HadithCatalogBook: Identifiable, Hashable {
    enum Group: String, CaseIterable {
        /// Al-Kutub as-Sittah - the six canonical Sunnah collections.
        case six = "THE SIX BOOKS"
        /// The Muwatta, Sunan ad-Darimi, and Musnad Ahmad - the three that, with the six, make the Nine Books.
        /// All three were compiled before the six.
        case early = "EARLY COLLECTIONS"
        case forties = "THE FORTY COLLECTIONS"
        case other = "OTHER BOOKS"
    }

    let slug: String
    let folder: String
    let englishTitle: String
    /// Vocalized (tashkeel) Arabic title - no sukoon marks, and each word's final letter left bare.
    let arabicTitle: String
    let group: Group
    /// Measured raw JSON size, for the download UI.
    let approximateMegabytes: Double
    /// "Imam al-Bukhari (الإمام البخاري)" - compiler in English with Arabic in parentheses.
    let authorEnglish: String
    let authorArabic: String
    /// "d. 256 AH / 870 CE" - when the compiler died (the classical way these books are dated).
    let era: String
    /// 1-2 lines shown in the catalog list.
    let shortDescription: String
    /// The fuller story shown at the top of the book's own screen.
    let longDescription: String
    /// Normalized alias forms for reference lookups ("bukhari 5"). See `HadithReferenceParser.normalize`.
    let aliases: [String]

    var id: String { slug }

    /// The forties ship inside the app bundle - tiny files, always available offline, never downloaded.
    var isBundled: Bool { group == .forties }

    /// 1-based position in the catalog ("1: Sahih al-Bukhari" ... "10: The Forty Hadith of Imam Nawawi"),
    /// the same numbered style the surah rows use.
    var number: Int {
        (Self.all.firstIndex(of: self) ?? 0) + 1
    }

    static let all: [HadithCatalogBook] = [
        // The Six Books (al-Kutub as-Sittah).
        HadithCatalogBook(
            slug: "bukhari", folder: "the_9_books",
            englishTitle: "Sahih al-Bukhari", arabicTitle: "صَحِيح البُخارِي",
            group: .six, approximateMegabytes: 13,
            authorEnglish: "Imam Muhammad ibn Ismail al-Bukhari", authorArabic: "الإمام محمد بن إسماعيل البخاري",
            era: "d. 256 AH / 870 CE",
            shortDescription: "The most authentic book after the Quran, sifted from hundreds of thousands of narrations.",
            longDescription: "Compiled over sixteen years by Imam al-Bukhari (الإمام البخاري), who selected its 7,563 hadiths (about 2,600 without repetition) from hundreds of thousands he examined, applying the strictest standards of authenticity. Muslims across every generation have regarded it as the most authentic book after the Quran itself.",
            aliases: ["bukhari", "bukharee", "bukhary", "albukhari"]
        ),
        HadithCatalogBook(
            slug: "muslim", folder: "the_9_books",
            englishTitle: "Sahih Muslim", arabicTitle: "صَحِيح مُسلِم",
            group: .six, approximateMegabytes: 11.5,
            authorEnglish: "Imam Muslim ibn al-Hajjaj", authorArabic: "الإمام مسلم بن الحجاج",
            era: "d. 261 AH / 875 CE",
            shortDescription: "The second most authentic collection, every hadith gathered with its chains side by side.",
            longDescription: "Compiled by Imam Muslim ibn al-Hajjaj of Naysabur (الإمام مسلم بن الحجاج النيسابوري), a student of Imam al-Bukhari. Alongside Sahih al-Bukhari it forms the \"Sahihayn,\" the two most authentic books of hadith. Scholars especially prize its arrangement: every narration of a hadith is gathered in one place with its chains compared side by side.",
            aliases: ["muslim", "sahihmuslim"]
        ),
        HadithCatalogBook(
            slug: "nasai", folder: "the_9_books",
            englishTitle: "Sunan an-Nasa'i", arabicTitle: "سُنَن النَسائِي",
            group: .six, approximateMegabytes: 8,
            authorEnglish: "Imam Ahmad ibn Shu'ayb an-Nasa'i", authorArabic: "الإمام أحمد بن شعيب النسائي",
            era: "d. 303 AH / 915 CE",
            shortDescription: "The strictest of the four Sunan in its conditions for accepting narrators.",
            longDescription: "Compiled by Imam an-Nasa'i (الإمام النسائي), whose conditions for accepting narrators were the most rigorous among the authors of the four Sunan. This collection, as-Sunan as-Sughra (also called al-Mujtaba), is his refinement of a larger work, keeping the narrations he judged strongest.",
            aliases: ["nasai", "nisai", "nasaee", "annasai", "alnasai", "annisai", "alnisai"]
        ),
        HadithCatalogBook(
            slug: "abudawud", folder: "the_9_books",
            englishTitle: "Sunan Abi Dawud", arabicTitle: "سُنَن أَبِي داوُد",
            group: .six, approximateMegabytes: 8,
            authorEnglish: "Imam Abu Dawud as-Sijistani", authorArabic: "الإمام أبو داود السجستاني",
            era: "d. 275 AH / 889 CE",
            shortDescription: "The Sunan of legal rulings, about 4,800 hadiths chosen from 500,000.",
            longDescription: "Imam Abu Dawud (الإمام أبو داود) selected roughly 4,800 hadiths from the 500,000 he had collected, focusing on the narrations jurists build legal rulings upon. He remarked that four hadiths of it suffice a person for their religion - among them \"Actions are by intentions.\"",
            aliases: ["abudawud", "abidawud", "abudaud", "abidaud", "dawud", "daud", "dawood", "abudawood"]
        ),
        HadithCatalogBook(
            slug: "tirmidhi", folder: "the_9_books",
            englishTitle: "Jami` at-Tirmidhi", arabicTitle: "جامِع التِرمِذِي",
            group: .six, approximateMegabytes: 7.7,
            authorEnglish: "Imam Muhammad ibn Isa at-Tirmidhi", authorArabic: "الإمام محمد بن عيسى الترمذي",
            era: "d. 279 AH / 892 CE",
            shortDescription: "The graded collection, noting each hadith's strength and the jurists' positions.",
            longDescription: "Compiled by Imam at-Tirmidhi (الإمام الترمذي), a student of Imam al-Bukhari. Its distinction is method: after most hadiths he states its grading (sahih, hasan, or otherwise) and which schools of law acted upon it - making it as much a manual of hadith science as a collection.",
            aliases: ["tirmidhi", "tirmizi", "tirmidhee", "attirmidhi", "altirmidhi"]
        ),
        HadithCatalogBook(
            slug: "ibnmajah", folder: "the_9_books",
            englishTitle: "Sunan Ibn Majah", arabicTitle: "سُنَن ابن ماجَه",
            group: .six, approximateMegabytes: 5.7,
            authorEnglish: "Imam Muhammad ibn Yazid ibn Majah", authorArabic: "الإمام محمد بن يزيد بن ماجه",
            era: "d. 273 AH / 887 CE",
            shortDescription: "The sixth of the Six Books, preserving many hadiths found in none of the other five.",
            longDescription: "Compiled by Imam Ibn Majah of Qazwin (الإمام ابن ماجه القزويني). It completes the famous \"Six Books\" (al-Kutub as-Sittah), and its particular value is the many hadiths - the zawa'id - it preserves that appear in none of the other five.",
            aliases: ["ibnmajah", "majah", "ibnmaja", "maja"]
        ),
        HadithCatalogBook(
            slug: "malik", folder: "the_9_books",
            englishTitle: "Muwatta Malik", arabicTitle: "مُوَطَّأ مالِك",
            group: .early, approximateMegabytes: 3.3,
            authorEnglish: "Imam Malik ibn Anas", authorArabic: "الإمام مالك بن أنس",
            era: "d. 179 AH / 795 CE",
            shortDescription: "The earliest collection of all, joining hadith with the practice of Madinah.",
            longDescription: "The Muwatta of Imam Malik (الإمام مالك), the Imam of Madinah, is the earliest collection in this library - compiled a full century before Bukhari and Muslim. It weaves hadith together with the established practice of the people of Madinah. Imam ash-Shafi'i called it the soundest book of its time.",
            aliases: ["malik", "muwatta", "muwattamalik", "almuwatta"]
        ),
        HadithCatalogBook(
            slug: "darimi", folder: "the_9_books",
            englishTitle: "Sunan ad-Darimi", arabicTitle: "سُنَن الدارِمِي",
            group: .early, approximateMegabytes: 3,
            authorEnglish: "Imam Abdullah ibn Abd ar-Rahman ad-Darimi", authorArabic: "الإمام عبد الله بن عبد الرحمن الدارمي",
            era: "d. 255 AH / 869 CE",
            shortDescription: "The early Sunan of a teacher of Muslim, Abu Dawud, and at-Tirmidhi.",
            longDescription: "Compiled by Imam ad-Darimi (الإمام الدارمي) of Samarqand, a hadith master whose students included Imam Muslim, Abu Dawud, and at-Tirmidhi. His Sunan (also called his Musnad) opens with a celebrated introduction on the Prophet's ﷺ status and the etiquette of knowledge.",
            aliases: ["darimi", "daremi", "addarimi", "aldarimi"]
        ),
        HadithCatalogBook(
            slug: "ahmed", folder: "the_9_books",
            englishTitle: "Musnad Ahmad", arabicTitle: "مُسنَد أَحمَد",
            group: .early, approximateMegabytes: 2.4,
            authorEnglish: "Imam Ahmad ibn Hanbal", authorArabic: "الإمام أحمد بن حنبل",
            era: "d. 241 AH / 855 CE",
            shortDescription: "The great Musnad, arranged by the Companion who narrates each hadith.",
            longDescription: "The Musnad of Imam Ahmad ibn Hanbal (الإمام أحمد بن حنبل), founder of the Hanbali school and the towering hadith scholar of his age. Unlike the Sunan books it is arranged by narrating Companion rather than by topic; the full Musnad spans over 27,000 narrations, of which this dataset carries a selection.",
            aliases: ["ahmad", "ahmed", "musnadahmad", "musnadahmed"]
        ),
        // The forties (bundled in the app).
        HadithCatalogBook(
            slug: "nawawi40", folder: "forties",
            englishTitle: "The Forty Hadith of Imam Nawawi", arabicTitle: "الأَربَعُون النَوَوِيَّة",
            group: .forties, approximateMegabytes: 0.1,
            authorEnglish: "Imam Yahya ibn Sharaf an-Nawawi", authorArabic: "الإمام يحيى بن شرف النووي",
            era: "d. 676 AH / 1277 CE",
            shortDescription: "The forty-two foundational hadiths, each an axis the religion turns upon.",
            longDescription: "Imam an-Nawawi (الإمام النووي) gathered forty-two hadiths - mostly from Bukhari and Muslim - each chosen because scholars described it as an axis the religion turns upon. Memorized across the Muslim world for over seven centuries, it is usually the first hadith book a student ever studies.",
            aliases: ["nawawi", "nawawi40", "arbaeen", "arbain", "arbaeennawawi", "fortynawawi"]
        ),
        HadithCatalogBook(
            slug: "qudsi40", folder: "forties",
            englishTitle: "Forty Hadith Qudsi", arabicTitle: "الأَحادِيث القُدسِيَّة",
            group: .forties, approximateMegabytes: 0.1,
            authorEnglish: "Related by the Prophet ﷺ from His Lord", authorArabic: "يرويه النبي ﷺ عن ربه",
            era: "Compiled selection",
            shortDescription: "The forty sacred hadiths, their meaning from Allah in the Prophet's ﷺ wording.",
            longDescription: "A hadith qudsi (حديث قدسي) is a narration in which the Prophet ﷺ relates words whose meaning is from Allah, expressed in the Prophet's ﷺ own wording - distinct from the Quran, which is Allah's speech in both word and meaning. This is a well-known selection of forty such sacred hadiths.",
            aliases: ["qudsi", "qudsi40", "hadithqudsi"]
        ),
        HadithCatalogBook(
            slug: "shahwaliullah40", folder: "forties",
            englishTitle: "Forty Hadith of Shah Waliullah", arabicTitle: "أَربَعُون الشاه وَلِي الله",
            group: .forties, approximateMegabytes: 0.1,
            authorEnglish: "Shah Waliullah ad-Dihlawi", authorArabic: "شاه ولي الله الدهلوي",
            era: "d. 1176 AH / 1762 CE",
            shortDescription: "The forty concise hadiths with the shortest, most elevated chains.",
            longDescription: "Collected by Shah Waliullah of Delhi (شاه ولي الله الدهلوي), the reviver of hadith studies in the Indian subcontinent. He chose forty concise hadiths distinguished by their short, elevated chains of transmission - comprehensive words gathered in the briefest form.",
            aliases: ["shahwaliullah", "waliullah", "shahwaliullah40"]
        ),
        // Other books.
        HadithCatalogBook(
            slug: "riyad_assalihin", folder: "other_books",
            englishTitle: "Riyad as-Salihin", arabicTitle: "رِياض الصالِحِين",
            group: .other, approximateMegabytes: 2.2,
            authorEnglish: "Imam Yahya ibn Sharaf an-Nawawi", authorArabic: "الإمام يحيى بن شرف النووي",
            era: "d. 676 AH / 1277 CE",
            shortDescription: "The Gardens of the Righteous, the world's most-read book of the daily Sunnah.",
            longDescription: "\"Gardens of the Righteous\" by Imam an-Nawawi (الإمام النووي): around 1,900 hadiths on worship, character, and everyday conduct, arranged under verses of the Quran. Perhaps the most widely read hadith book in the world - a practical guide to living the Sunnah day by day.",
            aliases: ["riyad", "riyadh", "riyadassalihin", "riyadussalihin", "riyadsaliheen", "riyadhussaliheen", "salihin", "saliheen"]
        ),
        HadithCatalogBook(
            slug: "mishkat_almasabih", folder: "other_books",
            englishTitle: "Mishkat al-Masabih", arabicTitle: "مِشكاة المَصابِيح",
            group: .other, approximateMegabytes: 5.2,
            authorEnglish: "Imam al-Khatib at-Tabrizi", authorArabic: "الإمام الخطيب التبريزي",
            era: "d. c. 741 AH / 1340 CE",
            shortDescription: "The Niche of the Lamps, a comprehensive sourced survey of the whole Sunnah.",
            longDescription: "\"The Niche of the Lamps\" by al-Khatib at-Tabrizi (الخطيب التبريزي) expands al-Baghawi's Masabih as-Sunnah: he named each hadith's source collection and added a third section to every chapter, producing one of the most comprehensive single surveys of the Sunnah ever assembled.",
            aliases: ["mishkat", "mishkaat", "mishkatalmasabih"]
        ),
        HadithCatalogBook(
            slug: "bulugh_almaram", folder: "other_books",
            englishTitle: "Bulugh al-Maram", arabicTitle: "بُلُوغ المَرام",
            group: .other, approximateMegabytes: 2.1,
            authorEnglish: "Imam Ibn Hajar al-Asqalani", authorArabic: "الإمام ابن حجر العسقلاني",
            era: "d. 852 AH / 1449 CE",
            shortDescription: "The evidences of Islamic law, the hadiths behind the legal rulings of fiqh.",
            longDescription: "\"Attainment of the Objective\" by Ibn Hajar al-Asqalani (ابن حجر العسقلاني), the commentator of Sahih al-Bukhari. Around 1,580 hadiths that serve as the evidences for Islamic legal rulings, each with its source noted - studied wherever fiqh is taught.",
            aliases: ["bulugh", "buloogh", "bulughalmaram", "bulughmaram"]
        ),
        HadithCatalogBook(
            slug: "aladab_almufrad", folder: "other_books",
            englishTitle: "Al-Adab Al-Mufrad", arabicTitle: "الأَدَب المُفرَد",
            group: .other, approximateMegabytes: 1.8,
            authorEnglish: "Imam Muhammad ibn Ismail al-Bukhari", authorArabic: "الإمام محمد بن إسماعيل البخاري",
            era: "d. 256 AH / 870 CE",
            shortDescription: "The book of manners, Imam al-Bukhari's own work on family and character.",
            longDescription: "Imam al-Bukhari's (الإمام البخاري) dedicated book of Islamic manners: over 1,300 narrations on treating parents, neighbors, children, and guests; on speech, anger, mercy, and the everyday character the Prophet ﷺ taught - the gentler companion to his Sahih.",
            aliases: ["adab", "adabmufrad", "adabalmufrad", "aladabalmufrad"]
        ),
        HadithCatalogBook(
            slug: "shamail_muhammadiyah", folder: "other_books",
            englishTitle: "Shama'il Muhammadiyah", arabicTitle: "الشَمائِل المُحَمَّدِيَّة",
            group: .other, approximateMegabytes: 0.5,
            authorEnglish: "Imam Muhammad ibn Isa at-Tirmidhi", authorArabic: "الإمام محمد بن عيسى الترمذي",
            era: "d. 279 AH / 892 CE",
            shortDescription: "The portrait of the Prophet ﷺ, his appearance, habits, and character.",
            longDescription: "Imam at-Tirmidhi's (الإمام الترمذي) beloved portrait of the Prophet ﷺ: around 400 narrations describing his appearance, dress, food, sleep, worship, humility, and character - gathered so that those who never saw him ﷺ could almost see him.",
            aliases: ["shamail", "shamaail", "shamailmuhammadiyah"]
        ),
    ]

    static var bySlug: [String: HadithCatalogBook] {
        Dictionary(uniqueKeysWithValues: all.map { ($0.slug, $0) })
    }

    static func books(in group: Group) -> [HadithCatalogBook] {
        all.filter { $0.group == group }
    }

    /// Downloadable size only - bundled books cost nothing.
    static let totalMegabytes: Int = Int(all.filter { !$0.isBundled }.reduce(0) { $0 + $1.approximateMegabytes }.rounded())
}

// MARK: - Models (the hadith-json shapes)

struct HadithBookData: Decodable {
    struct Metadata: Decodable {
        struct Titles: Decodable {
            let title: String
            let author: String
        }
        let arabic: Titles
        let english: Titles
    }

    struct Chapter: Decodable, Identifiable, Hashable {
        let id: Int
        let arabic: String
        let english: String
    }

    struct Hadith: Decodable, Identifiable {
        struct EnglishText: Decodable {
            let narrator: String
            let text: String
        }
        let id: Int
        let idInBook: Int
        let chapterId: Int
        let arabic: String
        let english: EnglishText
    }

    let metadata: Metadata
    let chapters: [Chapter]
    let hadiths: [Hadith]
}

// MARK: - Reference lookups ("bukhari 5", "muslim 3:12")

enum HadithReferenceParser {
    /// Lowercase, split into alphanumeric tokens, drop articles and generic words, join. "Sunan An-Nisa'i"
    /// and "nisai" both normalize to "nisai"; "Al-Adab Al-Mufrad" stays distinct ("adabmufrad").
    static func normalize(_ raw: String) -> String {
        let dropped: Set<String> = ["al", "an", "as", "ad", "at", "the", "imam", "sahih", "sunan", "jami", "musnad", "hadith", "forty", "40", "of", "book", "collection"]
        let tokens = raw.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !dropped.contains($0) }
        return tokens.joined()
    }

    struct Reference {
        let book: HadithCatalogBook
        /// 1-based chapter position in the book's chapter list, when the query was "book C:N".
        let chapter: Int?
        /// "book N" -> the hadith numbered N in the book; "book C:N" -> the Nth hadith of chapter C.
        let hadith: Int
    }

    /// Parse "bukhari 5" or "muslim 3:12" (also "3.12" / "3-12"). Returns nil when the text before the
    /// numbers doesn't resolve to a known book alias.
    static func parse(_ query: String) -> Reference? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = trimmed.range(of: #"^(.+?)\s+(\d{1,4})(?:\s*[:.\-]\s*(\d{1,5}))?$"#, options: .regularExpression) else { return nil }
        _ = match

        // Re-extract with NSRegularExpression for capture groups (String.range(of:) can't give them).
        guard let regex = try? NSRegularExpression(pattern: #"^(.+?)\s+(\d{1,4})(?:\s*[:.\-]\s*(\d{1,5}))?$"#),
              let result = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) else { return nil }

        func group(_ index: Int) -> String? {
            guard let range = Range(result.range(at: index), in: trimmed) else { return nil }
            return String(trimmed[range])
        }

        guard let namePart = group(1), let firstNumber = group(2).flatMap({ Int($0) }) else { return nil }
        let secondNumber = group(3).flatMap { Int($0) }

        let normalized = normalize(namePart)
        guard !normalized.isEmpty,
              let book = HadithCatalogBook.all.first(where: { $0.aliases.contains(normalized) || normalize($0.englishTitle) == normalized }) else { return nil }

        if let secondNumber {
            return Reference(book: book, chapter: firstNumber, hadith: secondNumber)
        }
        return Reference(book: book, chapter: nil, hadith: firstNumber)
    }
}

// MARK: - Store

/// Disk + memory cache over the hadith-json CDN (with the forties served straight from the app bundle),
/// plus bulk download, favorite books, and per-hadith bookmarks.
@MainActor
final class HadithStore: ObservableObject {
    static let shared = HadithStore()

    private static let favoritesKey = "hadithFavoriteBooks"
    private static let bookmarksKey = "hadithBookmarks"

    private init() {
        favoriteSlugs = Set(UserDefaults.standard.stringArray(forKey: Self.favoritesKey) ?? [])
        if let data = UserDefaults.standard.data(forKey: Self.bookmarksKey),
           let decoded = try? JSONDecoder().decode([HadithBookmark].self, from: data) {
            bookmarks = decoded
        }
    }

    // Download progress, published for the catalog UI.
    @Published private(set) var isDownloading = false
    @Published private(set) var downloadingBookTitle = ""
    @Published private(set) var downloadCompletedBooks = 0
    @Published private(set) var downloadTotalBooks = 0
    @Published var downloadError: String?
    /// Slugs with a file on disk, so rows can show their downloaded state (bundled books are always offline).
    @Published private(set) var downloadedSlugs: Set<String> = []
    @Published private(set) var diskUsageBytes: Int64 = 0

    /// Favorited book slugs, pinned to the top of the catalog. Persisted in UserDefaults.
    @Published private(set) var favoriteSlugs: Set<String> = []

    /// Bookmarked individual hadiths, newest first. Each carries enough text to render its row without
    /// loading the (large) book it came from. Persisted in UserDefaults.
    @Published private(set) var bookmarks: [HadithBookmark] = []

    /// Decoded books kept in memory, newest last (tiny LRU - Bukhari decoded is large).
    private var decoded: [(slug: String, book: HadithBookData)] = []
    private var downloadTask: Task<Void, Never>?

    // MARK: Favorites

    func isFavorite(_ slug: String) -> Bool { favoriteSlugs.contains(slug) }

    func toggleFavorite(_ slug: String) {
        if favoriteSlugs.contains(slug) {
            favoriteSlugs.remove(slug)
        } else {
            favoriteSlugs.insert(slug)
        }
        UserDefaults.standard.set(Array(favoriteSlugs), forKey: Self.favoritesKey)
    }

    // MARK: Bookmarks

    func isBookmarked(slug: String, idInBook: Int) -> Bool {
        bookmarks.contains { $0.slug == slug && $0.idInBook == idInBook }
    }

    func toggleBookmark(book: HadithCatalogBook, hadith: HadithBookData.Hadith) {
        if let index = bookmarks.firstIndex(where: { $0.slug == book.slug && $0.idInBook == hadith.idInBook }) {
            bookmarks.remove(at: index)
        } else {
            let preview = hadith.english.text.isEmpty ? hadith.arabic : hadith.english.text
            bookmarks.insert(
                HadithBookmark(
                    slug: book.slug,
                    idInBook: hadith.idInBook,
                    reference: "\(book.englishTitle) \(hadith.idInBook)",
                    preview: String(preview.prefix(140))
                ),
                at: 0
            )
        }
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: Self.bookmarksKey)
        }
    }

    // MARK: Fetching

    private nonisolated static let directory: URL = {
        let base = (try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )) ?? FileManager.default.temporaryDirectory
        var dir = base.appendingPathComponent("HadithCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dir.setResourceValues(values)
        return dir
    }()

    private nonisolated static func fileURL(_ book: HadithCatalogBook) -> URL {
        directory.appendingPathComponent("\(book.slug).json")
    }

    private nonisolated static func endpoint(_ book: HadithCatalogBook) -> URL? {
        URL(string: "https://cdn.jsdelivr.net/gh/AhmedBaset/hadith-json@main/db/by_book/\(book.folder)/\(book.slug).json")
    }

    /// True when this book can be read right now without the network.
    func isAvailableOffline(_ book: HadithCatalogBook) -> Bool {
        book.isBundled || downloadedSlugs.contains(book.slug)
    }

    /// Cache-first: memory (decoded), then the app bundle (forties), then disk, then network - decode always
    /// runs off-main.
    func book(_ book: HadithCatalogBook) async throws -> HadithBookData {
        if let hit = decoded.first(where: { $0.slug == book.slug })?.book {
            return hit
        }

        let data: Data
        if book.isBundled, let bundled = Bundle.main.url(forResource: book.slug, withExtension: "json"),
           let bundledData = await Task.detached(priority: .userInitiated, operation: { try? Data(contentsOf: bundled) }).value {
            data = bundledData
        } else {
            let file = Self.fileURL(book)
            if let disk = await Task.detached(priority: .userInitiated, operation: { try? Data(contentsOf: file) }).value {
                data = disk
            } else {
                guard let remote = Self.endpoint(book) else { throw URLError(.badURL) }
                let (fetched, response) = try await URLSession.shared.data(from: remote)
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    throw URLError(.badServerResponse)
                }
                data = fetched
                Task.detached(priority: .utility) {
                    try? fetched.write(to: file, options: .atomic)
                }
                downloadedSlugs.insert(book.slug)
            }
        }

        let parsed = try await Task.detached(priority: .userInitiated) {
            try JSONDecoder().decode(HadithBookData.self, from: data)
        }.value

        decoded.removeAll { $0.slug == book.slug }
        decoded.append((book.slug, parsed))
        if decoded.count > 3 { decoded.removeFirst() }
        return parsed
    }

    // MARK: Bulk download

    /// Fetch every non-bundled book not yet on disk, one at a time (the files are large; parallel fetches of
    /// 13 MB JSONs just fight each other for bandwidth).
    func startDownloadAll() {
        guard !isDownloading else { return }
        let downloadable = HadithCatalogBook.all.filter { !$0.isBundled }
        isDownloading = true
        downloadError = nil
        downloadTotalBooks = downloadable.count
        downloadCompletedBooks = 0

        downloadTask = Task { [weak self] in
            var failures = 0
            for book in downloadable {
                if Task.isCancelled { break }
                guard let self else { return }
                self.downloadingBookTitle = book.englishTitle

                let file = Self.fileURL(book)
                let exists = await Task.detached(priority: .userInitiated) {
                    FileManager.default.fileExists(atPath: file.path)
                }.value
                if exists {
                    self.downloadCompletedBooks += 1
                    self.downloadedSlugs.insert(book.slug)
                    continue
                }

                guard let url = Self.endpoint(book),
                      let (data, response) = try? await URLSession.shared.data(from: url),
                      let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                    failures += 1
                    continue
                }
                let write = data
                await Task.detached(priority: .utility) {
                    try? write.write(to: file, options: .atomic)
                }.value
                self.downloadedSlugs.insert(book.slug)
                self.downloadCompletedBooks += 1
            }

            guard let self else { return }
            if failures > 0, !Task.isCancelled {
                self.downloadError = "\(failures) books failed to download. Run the download again to retry them."
            }
            self.isDownloading = false
            self.downloadingBookTitle = ""
            self.refreshDiskState()
        }
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        isDownloading = false
        downloadingBookTitle = ""
    }

    func deleteDownload(_ book: HadithCatalogBook) {
        guard !book.isBundled else { return }
        decoded.removeAll { $0.slug == book.slug }
        downloadedSlugs.remove(book.slug)
        Task.detached(priority: .utility) { [weak self] in
            try? FileManager.default.removeItem(at: Self.fileURL(book))
            await self?.refreshDiskState()
        }
    }

    func deleteAllDownloads() {
        cancelDownload()
        decoded.removeAll()
        downloadedSlugs = []
        Task.detached(priority: .utility) { [weak self] in
            let contents = (try? FileManager.default.contentsOfDirectory(at: Self.directory, includingPropertiesForKeys: nil)) ?? []
            for file in contents {
                try? FileManager.default.removeItem(at: file)
            }
            await self?.refreshDiskState()
        }
    }

    func refreshDiskState() {
        Task.detached(priority: .utility) { [weak self] in
            let contents = (try? FileManager.default.contentsOfDirectory(
                at: Self.directory, includingPropertiesForKeys: [.fileSizeKey]
            )) ?? []
            var slugs: Set<String> = []
            var bytes: Int64 = 0
            for url in contents {
                slugs.insert(url.deletingPathExtension().lastPathComponent)
                bytes += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
            }
            let finalSlugs = slugs
            let finalBytes = bytes
            await MainActor.run { [weak self] in
                self?.downloadedSlugs = finalSlugs
                self?.diskUsageBytes = finalBytes
            }
        }
    }
}

/// A bookmarked hadith, self-contained so the bookmarks list renders without loading its (large) book.
struct HadithBookmark: Codable, Identifiable, Equatable {
    let slug: String
    let idInBook: Int
    let reference: String
    let preview: String

    var id: String { "\(slug)-\(idInBook)" }
}

// MARK: - The tab root: collections

struct HadithView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared

    @State private var searchText = ""
    @State private var confirmDownloadAll = false
    @State private var confirmDeleteAll = false
    @State private var showHadithSettings = false
    /// Grid tiles are plain Buttons (a NavigationLink cell in a List draws a chevron); tapping one sets
    /// this, and a hidden `NavigationLink` behind the List performs the actual push.
    @State private var pushedBook: HadithCatalogBook?
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false

    // All-books search.
    @State private var globalResults: [(book: HadithCatalogBook, hadiths: [HadithBookData.Hadith])] = []
    @State private var isGlobalSearching = false
    @State private var globalSearchRanFor = ""
    @State private var globalSearchTask: Task<Void, Never>?

    // Hadith of the Day, drawn from the BUNDLED forties - guaranteed offline from first launch.
    @State private var dailyHadith: (book: HadithCatalogBook, hadith: HadithBookData.Hadith)?
    @State private var dailyShuffleOffset = 0

    private func matches(_ book: HadithCatalogBook) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return book.englishTitle.localizedCaseInsensitiveContains(query) ||
            book.arabicTitle.localizedCaseInsensitiveContains(query) ||
            settings.cleanSearch(book.arabicTitle, whitespace: true).localizedCaseInsensitiveContains(settings.cleanSearch(query, whitespace: true))
    }

    private func filteredBooks(in group: HadithCatalogBook.Group) -> [HadithCatalogBook] {
        HadithCatalogBook.books(in: group).filter(matches)
    }

    private var filteredFavorites: [HadithCatalogBook] {
        HadithCatalogBook.all.filter { store.isFavorite($0.slug) && matches($0) }
    }

    private var referenceResult: HadithReferenceParser.Reference? {
        HadithReferenceParser.parse(searchText)
    }

    private var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    var body: some View {
        NavigationView {
            List {
                Group {
                    aboutHadithSection

                    if searchText.isEmpty {
                        hadithOfTheDaySection
                    }

                    if store.isDownloading {
                        downloadProgressSection
                    }

                    if let error = store.downloadError {
                        Section {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    if let reference = referenceResult {
                        referenceSection(reference)
                    }

                    globalSearchSection

                    if !store.bookmarks.isEmpty && searchText.isEmpty {
                        bookmarksSection
                    }

                    let favorites = filteredFavorites
                    if !favorites.isEmpty {
                        bookSection(title: "FAVORITE BOOKS", books: favorites)
                    }

                    ForEach(HadithCatalogBook.Group.allCases, id: \.self) { group in
                        let books = filteredBooks(in: group)
                        if !books.isEmpty {
                            bookSection(title: group.rawValue, books: books)
                        }
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .compactListSectionSpacing()
            // The invisible link the grid tiles push through (list rows use real NavigationLinks).
            .background(
                NavigationLink(isActive: Binding(
                    get: { pushedBook != nil },
                    set: { if !$0 { pushedBook = nil } }
                )) {
                    if let pushedBook {
                        HadithBookView(book: pushedBook)
                    }
                } label: {
                    EmptyView()
                }
                .opacity(0)
            )
            // Apple Music-style: the bottom search bar minimizes while scrolling down.
            .collapseBarsOnScroll($barsCollapsed)
            .adaptiveSafeArea(edge: .bottom) {
                SearchBar(text: $searchText.animation(.easeInOut))
                    .padding([.horizontal, .top], -8)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .background(Color.white.opacity(0.00001))
                    .minimizedBarStyle(barsCollapsed)
            }
            .navigationTitle("Hadith")
            .toolbar {
                // Download management on the LEFT.
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Text("Offline Books")
                            .foregroundStyle(.secondary)

                        Button {
                            settings.hapticFeedback()
                            confirmDownloadAll = true
                        } label: {
                            Label("Download All Books", systemImage: "icloud.and.arrow.down")
                        }
                        .disabled(store.isDownloading)

                        if !store.downloadedSlugs.isEmpty {
                            Button(role: .destructive) {
                                settings.hapticFeedback()
                                confirmDeleteAll = true
                            } label: {
                                Label("Delete All Downloads", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "icloud.and.arrow.down")
                    }
                    .tint(settings.accentColor.accent1)
                }

                // Grid/list toggle + hadith settings on the RIGHT.
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        settings.hapticFeedback()
                        withAnimation { settings.gridMode.toggle() }
                    } label: {
                        Image(systemName: settings.gridMode ? "list.bullet" : "square.grid.2x2")
                    }
                    .accessibilityLabel(settings.gridMode ? "Show list" : "Show grid")
                    .tint(settings.accentColor.accent2)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        settings.hapticFeedback()
                        showHadithSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityLabel("Hadith settings")
                    .tint(settings.accentColor.accent2)
                }
            }
            .sheet(isPresented: $showHadithSettings) {
                HadithSettingsSheet()
                    .smallMediumSheetPresentation()
            }
            .confirmationDialog("Download All Books?", isPresented: $confirmDownloadAll, titleVisibility: .visible) {
                Button("Download (~\(HadithCatalogBook.totalMegabytes) MB)") {
                    settings.hapticFeedback()
                    store.startDownloadAll()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This downloads the hadith collections for offline reading (the three forty-hadith collections are already included in the app). It may use significant data - Wi-Fi is recommended. Already-downloaded books are skipped.")
            }
            .confirmationDialog("Delete all downloaded books?", isPresented: $confirmDeleteAll, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    settings.hapticFeedback()
                    store.deleteAllDownloads()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Books will be re-downloaded from the Internet as you open them. The forty-hadith collections stay - they are part of the app.")
            }
            .onAppear {
                store.refreshDiskState()
            }
            .task(id: dailyShuffleOffset) {
                await loadDailyHadith()
            }
            .onChange(of: searchText) { _ in
                // A new query invalidates the last all-books sweep.
                globalSearchTask?.cancel()
                isGlobalSearching = false
                globalResults = []
                globalSearchRanFor = ""
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Hadith of the Day

    /// A deterministic daily pick from the ~120 bundled forty-collection hadiths - the same hadith all day,
    /// a different one tomorrow. The shuffle button steps to another for the curious.
    private func loadDailyHadith() async {
        var combined: [(HadithCatalogBook, HadithBookData.Hadith)] = []
        for book in HadithCatalogBook.all where book.isBundled {
            if let data = try? await store.book(book) {
                combined.append(contentsOf: data.hadiths.map { (book, $0) })
            }
        }
        guard !combined.isEmpty else { return }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        dailyHadith = combined[(day + dailyShuffleOffset) % combined.count]
    }

    @ViewBuilder
    private var hadithOfTheDaySection: some View {
        if let dailyHadith {
            Section {
                HadithRow(book: dailyHadith.book, hadith: dailyHadith.hadith)
            } header: {
                HStack {
                    Text("HADITH OF THE DAY")

                    Spacer()

                    Image(systemName: "shuffle")
                        .foregroundColor(settings.accentColor.color)
                        .padding(4)
                        .conditionalGlassEffect()
                        .onTapGesture {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) { dailyShuffleOffset += 1 }
                        }
                        .accessibilityLabel("Show another hadith")
                }
            }
        }
    }

    // MARK: About hadith

    /// The same orientation the Pillars screen gives - and in fact the same screens: the two
    /// Sunnah/Hadith pillar pages, pushed rather than paraphrased inline.
    private var aboutHadithSection: some View {
        Section {
            NavigationLink(destination: LazyDestination { SunnahPillarView() }) {
                Text("What is the Sunnah?")
                    .foregroundColor(settings.accentColor.color)
                    .font(.headline)
            }
            .padding(.vertical, 4)

            NavigationLink(destination: LazyDestination { HadithPillarView() }) {
                Text("What are Hadiths?")
                    .foregroundColor(settings.accentColor.color)
                    .font(.headline)
            }
            .padding(.vertical, 4)
        }
    }

    private var downloadProgressSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text(store.downloadingBookTitle)
                    .font(.subheadline.weight(.semibold))

                ProgressView(
                    value: Double(store.downloadCompletedBooks),
                    total: Double(max(store.downloadTotalBooks, 1))
                )

                Text("\(store.downloadCompletedBooks) of \(store.downloadTotalBooks) books")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()

                Button(role: .destructive) {
                    settings.hapticFeedback()
                    store.cancelDownload()
                } label: {
                    Text("Cancel Download")
                        .font(.subheadline)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: Reference lookup

    private func referenceSection(_ reference: HadithReferenceParser.Reference) -> some View {
        Section(header: Text("GO TO REFERENCE")) {
            NavigationLink {
                HadithReferenceView(book: reference.book, chapter: reference.chapter, hadith: reference.hadith)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "number")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(reference.chapter.map { "\(reference.book.englishTitle) - Chapter \($0), Hadith \(reference.hadith)" }
                             ?? "\(reference.book.englishTitle) - Hadith \(reference.hadith)")
                            .font(.subheadline.weight(.semibold))

                        Text(reference.book.arabicTitle)
                            .font(.caption)
                            .foregroundColor(settings.accentColor.color)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: All-books search

    @ViewBuilder
    private var globalSearchSection: some View {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.count >= 3, referenceResult == nil {
            Section(header: Text("ALL BOOKS")) {
                if isGlobalSearching {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Searching downloaded books...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if globalSearchRanFor == query {
                    if globalResults.isEmpty {
                        Text("No matches in the downloaded books.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        settings.hapticFeedback()
                        runGlobalSearch(query: query)
                    } label: {
                        Label("Search all books for \"\(query)\"", systemImage: "text.magnifyingglass")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                    }

                    Text("Searches every downloaded book (and the included forties). Books not downloaded yet are skipped.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            ForEach(globalResults, id: \.book.slug) { result in
                Section(header: Text(result.book.englishTitle.uppercased())) {
                    ForEach(result.hadiths) { hadith in
                        HadithRow(book: result.book, hadith: hadith, searchText: searchText)
                    }
                }
            }
        }
    }

    private func runGlobalSearch(query: String) {
        globalSearchTask?.cancel()
        isGlobalSearching = true
        globalResults = []

        let cleanQuery = settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns
        globalSearchTask = Task {
            var results: [(HadithCatalogBook, [HadithBookData.Hadith])] = []
            var total = 0

            for book in HadithCatalogBook.all where HadithStore.shared.isAvailableOffline(book) {
                if Task.isCancelled { return }
                guard total < 80, let data = try? await HadithStore.shared.book(book) else { continue }

                // Scan off-main: Bukhari alone is ~7,500 hadiths of long text.
                let matched = await Task.detached(priority: .userInitiated) { () -> [HadithBookData.Hadith] in
                    var found: [HadithBookData.Hadith] = []
                    for hadith in data.hadiths {
                        if hadith.english.text.localizedCaseInsensitiveContains(query)
                            || hadith.english.narrator.localizedCaseInsensitiveContains(query)
                            || Settings.shared.cleanSearch(hadith.arabic, whitespace: true).removingArabicDiacriticsAndSigns.contains(cleanQuery) {
                            found.append(hadith)
                            if found.count >= 10 { break }
                        }
                    }
                    return found
                }.value

                if !matched.isEmpty {
                    results.append((book, matched))
                    total += matched.count
                }
            }

            guard !Task.isCancelled else { return }
            globalResults = results
            globalSearchRanFor = query
            isGlobalSearching = false
        }
    }

    // MARK: Bookmarks

    private var bookmarksSection: some View {
        Section(header: Text("BOOKMARKED HADITHS")) {
            ForEach(store.bookmarks) { bookmark in
                if let book = HadithCatalogBook.bySlug[bookmark.slug] {
                    NavigationLink {
                        HadithReferenceView(book: book, chapter: nil, hadith: bookmark.idInBook)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Image(systemName: "bookmark.fill")
                                    .font(.caption2)
                                    .foregroundStyle(settings.accentColor.color)

                                Text(bookmark.reference)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(settings.accentColor.color)
                            }

                            Text(bookmark.preview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 2)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            settings.hapticFeedback()
                            if let hadith = placeholderHadith(for: bookmark) {
                                store.toggleBookmark(book: book, hadith: hadith)
                            }
                        } label: {
                            Label("Remove Bookmark", systemImage: "bookmark.slash")
                        }
                    }
                }
            }
        }
    }

    /// Removal only needs the identity fields; the store matches on slug + idInBook.
    private func placeholderHadith(for bookmark: HadithBookmark) -> HadithBookData.Hadith? {
        HadithBookData.Hadith(
            id: -1, idInBook: bookmark.idInBook, chapterId: -1,
            arabic: "", english: HadithBookData.Hadith.EnglishText(narrator: "", text: "")
        )
    }

    // MARK: Catalog sections

    /// A catalog section rendered as a grid of tiles or a list of rows, per the app-wide `gridMode`.
    @ViewBuilder
    private func bookSection(title: String, books: [HadithCatalogBook]) -> some View {
        if settings.gridMode {
            Section(header: Text(title)) {
                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 10) {
                    ForEach(books) { book in
                        bookGridTile(book)
                    }
                }
                .padding(.vertical, 4)
            }
        } else {
            Section(header: Text(title)) {
                ForEach(books) { book in
                    NavigationLink {
                        HadithBookView(book: book)
                    } label: {
                        bookRow(book)
                    }
                    .contextMenu { bookContextMenu(book) }
                }
            }
        }
    }

    @ViewBuilder
    private func bookContextMenu(_ book: HadithCatalogBook) -> some View {
        Text(book.englishTitle)
            .foregroundStyle(.secondary)

        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) { store.toggleFavorite(book.slug) }
        } label: {
            Label(store.isFavorite(book.slug) ? "Unfavorite" : "Favorite",
                  systemImage: store.isFavorite(book.slug) ? "star.slash" : "star")
        }

        if !book.isBundled, store.downloadedSlugs.contains(book.slug) {
            Button(role: .destructive) {
                settings.hapticFeedback()
                store.deleteDownload(book)
            } label: {
                Label("Remove Download", systemImage: "trash")
            }
        }
    }

    /// "~3 MB" while the book still needs downloading; nil once it's on the device (the offline icon
    /// says the rest - no "Downloaded" or "Included" labels anywhere).
    private func bookSizeText(_ book: HadithCatalogBook) -> String? {
        guard !store.isAvailableOffline(book) else { return nil }
        return "~\(book.approximateMegabytes < 1 ? "0.1" : String(format: "%.0f", book.approximateMegabytes)) MB"
    }

    private func arabicTitleFont(_ style: UIFont.TextStyle, bump: CGFloat) -> Font {
        settings.useFontArabic
            ? .custom(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: style).pointSize + bump)
            : Font(UIFont.preferredFont(forTextStyle: style))
    }

    private func bookRow(_ book: HadithCatalogBook) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                // The same numbered style the surah rows use: "1: Sahih al-Bukhari".
                HStack(spacing: 4) {
                    Text("\(book.number):")
                        .font(.subheadline.monospacedDigit().weight(.bold))
                        .foregroundColor(settings.accentColor.color)

                    HighlightedSnippet(
                        source: book.englishTitle,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )

                    // The download size sits right of the title, in small type - gone once offline.
                    if let size = bookSizeText(book) {
                        Text(size)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 8)

                HighlightedSnippet(
                    source: book.arabicTitle,
                    term: searchText,
                    font: arabicTitleFont(.subheadline, bump: 2),
                    accent: settings.accentColor.color,
                    fg: settings.accentColor.color
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)

                if store.isFavorite(book.slug) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(settings.accentColor.color)
                }

                if store.isAvailableOffline(book) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(settings.accentColor.color)
                }
            }

            // The 1-2 line orientation: who compiled it, and why it matters.
            Text(book.shortDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            Text("\(book.authorEnglish) - \(book.era)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 4)
    }

    /// A compact tile in the 99-Names style: Arabic, English, and the number stacked centered - a
    /// Button that pushes through the hidden `pushedBook` link, so no List chevron ever appears.
    private func bookGridTile(_ book: HadithCatalogBook) -> some View {
        Button {
            settings.hapticFeedback()
            pushedBook = book
        } label: {
            VStack(spacing: 3) {
                HighlightedSnippet(
                    source: book.arabicTitle,
                    term: searchText,
                    font: arabicTitleFont(.body, bump: 3),
                    accent: settings.accentColor.color,
                    fg: settings.accentColor.color
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

                HighlightedSnippet(
                    source: book.englishTitle,
                    term: searchText,
                    font: .caption.weight(.semibold),
                    accent: settings.accentColor.color,
                    fg: .primary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.55)

                HStack(spacing: 4) {
                    Text("\(book.number)")
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.secondary)

                    if let size = bookSizeText(book) {
                        Text("• \(size)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else if !book.isBundled {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(settings.accentColor.color)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .conditionalGlassEffect(
            clear: !store.isFavorite(book.slug),
            rectangle: true,
            useColor: store.isFavorite(book.slug) ? 0.25 : nil,
            customTint: store.isFavorite(book.slug) ? settings.accentColor.color : nil
        )
        .gridFavoriteStar(
            isFavorite: store.isFavorite(book.slug),
            accent: settings.accentColor.color,
            accessibilityName: book.englishTitle
        ) {
            store.toggleFavorite(book.slug)
        }
        .contextMenu { bookContextMenu(book) }
    }
}

// MARK: - Hadith settings

/// What a hadith row shows: Arabic, English, the narrator line, and which Arabic face. Small enough to live
/// in a sheet off the Hadith tab rather than the app settings tree.
struct HadithSettingsSheet: View {
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        NavigationView {
            List {
                Group {
                    Section(header: Text("TEXT")) {
                        Toggle("Show Arabic", isOn: Binding(
                            get: { settings.showHadithArabic },
                            set: { newValue in
                                settings.hapticFeedback()
                                settings.showHadithArabic = newValue
                                // Never allow both off - there would be nothing left to read.
                                if !newValue && !settings.showHadithEnglish {
                                    settings.showHadithEnglish = true
                                }
                            }
                        ).animation(.easeInOut))

                        Toggle("Show English", isOn: Binding(
                            get: { settings.showHadithEnglish },
                            set: { newValue in
                                settings.hapticFeedback()
                                settings.showHadithEnglish = newValue
                                if !newValue && !settings.showHadithArabic {
                                    settings.showHadithArabic = true
                                }
                            }
                        ).animation(.easeInOut))

                        if settings.showHadithEnglish {
                            Toggle("Show Narrator Line", isOn: $settings.showHadithNarrator.animation(.easeInOut))
                                .onChange(of: settings.showHadithNarrator) { _ in settings.hapticFeedback() }
                        }
                    }

                    if settings.showHadithArabic {
                        Section(header: Text("ARABIC FONT"), footer: Text("Uthmani and IndoPak are classical script styles; Basic is the standard system font. This choice is shared with the other Arabic screens (Adhkar, Duas, 99 Names, Arabic Alphabet).")) {
                            IslamArabicFontPicker()
                        }
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .navigationTitle("Hadith Settings")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
    }
}

// MARK: - One collection: chapters + book search + page mode

struct HadithBookView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared

    let book: HadithCatalogBook

    @State private var data: HadithBookData?
    @State private var loadError: String?
    @State private var searchText = ""
    @State private var loadAttempt = 0
    /// A book that is NOT yet on this device asks before fetching (they are big); this flips on confirm.
    @State private var didConfirmDownload = false
    @State private var confirmDownload = false
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false

    /// Offline books open straight away; everything else shows the info + download prompt first.
    private var needsDownloadPrompt: Bool {
        data == nil && !store.isAvailableOffline(book) && !didConfirmDownload
    }

    private var hadithCountsByChapter: [Int: Int] {
        guard let data else { return [:] }
        return data.hadiths.reduce(into: [:]) { $0[$1.chapterId, default: 0] += 1 }
    }

    private var filteredChapters: [HadithBookData.Chapter] {
        guard let data else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return data.chapters }
        return data.chapters.filter {
            $0.english.localizedCaseInsensitiveContains(query) || $0.arabic.contains(query)
        }
    }

    /// Book-wide hadith search (English text/narrator + diacritic-insensitive Arabic), capped so a common
    /// word in Bukhari doesn't try to render thousands of rows.
    private var matchingHadiths: [HadithBookData.Hadith] {
        guard let data else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 3 else { return [] }
        let cleanQuery = settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns

        var results: [HadithBookData.Hadith] = []
        for hadith in data.hadiths {
            if hadith.english.text.localizedCaseInsensitiveContains(query)
                || hadith.english.narrator.localizedCaseInsensitiveContains(query)
                || settings.cleanSearch(hadith.arabic, whitespace: true).removingArabicDiacriticsAndSigns.contains(cleanQuery) {
                results.append(hadith)
                if results.count >= 50 { break }
            }
        }
        return results
    }

    var body: some View {
        Group {
            if let data {
                loadedBody(data)
            } else if needsDownloadPrompt {
                downloadPrompt
            } else if let loadError {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text(loadError)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        settings.hapticFeedback()
                        self.loadError = nil
                        loadAttempt += 1
                    } label: {
                        Text("Try Again")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                    }
                }
                .padding()
            } else {
                ProgressView("Loading \(book.englishTitle)...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(book.englishTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if let data {
                    NavigationLink {
                        HadithPagedView(book: book, bookData: data, chapterIndex: 0)
                    } label: {
                        Image(systemName: "book")
                    }
                    .accessibilityLabel("Read as pages")
                    .tint(settings.accentColor.accent1)
                }
            }
        }
        .task(id: "\(loadAttempt)|\(didConfirmDownload)") {
            guard data == nil, !needsDownloadPrompt else { return }
            do {
                data = try await store.book(book)
            } catch {
                loadError = error.localizedDescription
            }
        }
    }

    /// The pre-download screen: everything worth knowing about the book (its story, compiler, era, size),
    /// and an explicit Download button behind a confirmation - nothing fetches until the reader says so.
    private var downloadPrompt: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(book.number): \(book.englishTitle)")
                            .font(.headline)

                        Spacer(minLength: 8)

                        Text(book.arabicTitle)
                            .font(settings.useFontArabic
                                  ? .custom(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize + 2)
                                  : .headline)
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                            .foregroundColor(settings.accentColor.color)
                    }

                    Text("\(book.authorEnglish) (\(book.authorArabic)) - \(book.era)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(book.longDescription)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .conditionalGlassEffect(rectangle: true, useColor: 0.08)

                OnlineNoticeCard(text: "This book is about \(bookSizeText) and has not been downloaded yet. Once downloaded, it is saved on this device and works fully offline.")

                Button {
                    settings.hapticFeedback()
                    confirmDownload = true
                } label: {
                    Label("Download \(book.englishTitle) (\(bookSizeText))", systemImage: "icloud.and.arrow.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .conditionalGlassEffect(rectangle: true)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .confirmationDialog("Download \(book.englishTitle)?", isPresented: $confirmDownload, titleVisibility: .visible) {
            Button("Download (\(bookSizeText))") {
                settings.hapticFeedback()
                didConfirmDownload = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This fetches the whole book for offline reading. It may use significant data - Wi-Fi is recommended.")
        }
    }

    private var bookSizeText: String {
        book.approximateMegabytes < 1 ? "under 1 MB" : "\(String(format: "%.0f", book.approximateMegabytes)) MB"
    }

    private func loadedBody(_ data: HadithBookData) -> some View {
        List {
            Group {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(data.metadata.english.title)
                                .font(.subheadline.weight(.semibold))

                            Spacer(minLength: 8)

                            Text(book.arabicTitle)
                                .font(settings.useFontArabic
                                      ? .custom(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2)
                                      : .subheadline)
                                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                                .foregroundColor(settings.accentColor.color)
                        }

                        Text("\(book.authorEnglish) (\(book.authorArabic)) - \(book.era)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // The fuller, authentic orientation to this collection.
                        Text(book.longDescription)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("\(data.hadiths.count) hadiths - \(data.chapters.count) chapters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.vertical, 2)
                }

                // While searching, matched HADITHS come first - the searcher is usually hunting a text,
                // not a chapter name.
                if !matchingHadiths.isEmpty {
                    Section(header: Text("MATCHING HADITHS")) {
                        ForEach(matchingHadiths) { hadith in
                            HadithRow(book: book, hadith: hadith, searchText: searchText)
                        }
                    }
                }

                Section(header: Text("CHAPTERS")) {
                    ForEach(filteredChapters) { chapter in
                        NavigationLink {
                            HadithChapterView(book: book, bookData: data, chapter: chapter)
                        } label: {
                            chapterRow(chapter)
                        }
                    }

                    if filteredChapters.isEmpty {
                        Text("No chapters found.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        // Apple Music-style: the bottom search bar minimizes while scrolling down.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: $searchText.animation(.easeInOut))
                .padding([.horizontal, .top], -8)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .background(Color.white.opacity(0.00001))
                .minimizedBarStyle(barsCollapsed)
        }
    }

    private func chapterRow(_ chapter: HadithBookData.Chapter) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline) {
                HighlightedSnippet(
                    source: chapter.english,
                    term: searchText,
                    font: .subheadline,
                    accent: settings.accentColor.color,
                    fg: .primary
                )

                Spacer(minLength: 8)

                if let count = hadithCountsByChapter[chapter.id] {
                    Text("\(count)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(settings.accentColor.color)
                }
            }

            if !chapter.arabic.isEmpty {
                HighlightedSnippet(
                    source: chapter.arabic,
                    term: searchText,
                    font: settings.useFontArabic
                        ? .custom(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2)
                        : .caption,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - One chapter: the hadiths

struct HadithChapterView: View {
    @ObservedObject private var settings = Settings.shared

    let book: HadithCatalogBook
    let bookData: HadithBookData
    let chapter: HadithBookData.Chapter

    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false

    private var chapterIndex: Int {
        bookData.chapters.firstIndex(where: { $0.id == chapter.id }) ?? 0
    }

    private var hadiths: [HadithBookData.Hadith] {
        let all = bookData.hadiths.filter { $0.chapterId == chapter.id }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return all }
        let cleanQuery = settings.cleanSearch(query, whitespace: true).removingArabicDiacriticsAndSigns
        return all.filter {
            $0.english.text.localizedCaseInsensitiveContains(query)
                || $0.english.narrator.localizedCaseInsensitiveContains(query)
                || settings.cleanSearch($0.arabic, whitespace: true).removingArabicDiacriticsAndSigns.contains(cleanQuery)
        }
    }

    var body: some View {
        List {
            Group {
                ForEach(hadiths) { hadith in
                    HadithRow(book: book, hadith: hadith, searchText: searchText)
                }

                if hadiths.isEmpty {
                    Text("No hadiths found.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        // Apple Music-style: the bottom search bar minimizes while scrolling down.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: $searchText.animation(.easeInOut))
                .padding([.horizontal, .top], -8)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
                .background(Color.white.opacity(0.00001))
                .minimizedBarStyle(barsCollapsed)
        }
        .navigationTitle(chapter.english.isEmpty ? book.englishTitle : chapter.english)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    HadithPagedView(book: book, bookData: bookData, chapterIndex: chapterIndex)
                } label: {
                    Image(systemName: "book")
                }
                .accessibilityLabel("Read this chapter as pages")
                .tint(settings.accentColor.accent1)
            }
        }
    }
}

// MARK: - Page mode: one hadith per page, chapter by chapter

/// The paged reader: swipe hadith-by-hadith through a chapter, and step between chapters with the footer
/// arrows. Deliberately chapter-scoped - paging all ~7,500 hadiths of Bukhari through one TabView is the
/// exact page-realization stampede the Quran mushaf had to engineer around; a chapter is at most a few
/// hundred light pages.
struct HadithPagedView: View {
    @ObservedObject private var settings = Settings.shared

    let book: HadithCatalogBook
    let bookData: HadithBookData

    @State var chapterIndex: Int
    @State private var hadithIndex = 0

    private var chapter: HadithBookData.Chapter? {
        bookData.chapters.indices.contains(chapterIndex) ? bookData.chapters[chapterIndex] : nil
    }

    private var chapterHadiths: [HadithBookData.Hadith] {
        guard let chapter else { return [] }
        return bookData.hadiths.filter { $0.chapterId == chapter.id }
    }

    var body: some View {
        let hadiths = chapterHadiths

        VStack(spacing: 0) {
            if hadiths.isEmpty {
                Text("This chapter has no hadiths.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $hadithIndex) {
                    ForEach(Array(hadiths.enumerated()), id: \.offset) { index, hadith in
                        ScrollView {
                            HadithRow(book: book, hadith: hadith)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .safeAreaInset(edge: .bottom) {
            pagerFooter(count: hadiths.count)
        }
        .navigationTitle(chapter?.english.isEmpty == false ? (chapter?.english ?? "") : book.englishTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: chapterIndex) { _ in
            hadithIndex = 0
        }
    }

    private func pagerFooter(count: Int) -> some View {
        VStack(spacing: 6) {
            TrackedBar(
                fraction: count > 1 ? CGFloat(hadithIndex) / CGFloat(count - 1) : 1,
                height: 3,
                color: settings.accentColor.color
            )
            .padding(.horizontal, 2)

            HStack(spacing: 12) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { chapterIndex = max(0, chapterIndex - 1) }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }
                .disabled(chapterIndex == 0)

                VStack(spacing: 1) {
                    Text("Chapter \(chapterIndex + 1)/\(bookData.chapters.count)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()

                    Text(count > 0 ? "Hadith \(hadithIndex + 1)/\(count)" : "-")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { chapterIndex = min(bookData.chapters.count - 1, chapterIndex + 1) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                }
                .disabled(chapterIndex >= bookData.chapters.count - 1)
            }
            .foregroundColor(settings.accentColor.color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .conditionalGlassEffect(rectangle: true)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

// MARK: - Reference resolution ("bukhari 5")

/// Loads the book, resolves the reference, and shows the hadith - the landing screen for "bukhari 5"-style
/// lookups and for bookmarked hadiths.
struct HadithReferenceView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared

    let book: HadithCatalogBook
    /// 1-based chapter position when the lookup was "book C:N"; nil for a plain hadith number.
    let chapter: Int?
    let hadith: Int

    @State private var data: HadithBookData?
    @State private var loadError: String?
    @State private var didConfirmDownload = false
    @State private var confirmDownload = false

    private var resolved: HadithBookData.Hadith? {
        guard let data else { return nil }
        if let chapter {
            guard data.chapters.indices.contains(chapter - 1) else { return nil }
            let chapterID = data.chapters[chapter - 1].id
            let inChapter = data.hadiths.filter { $0.chapterId == chapterID }
            guard inChapter.indices.contains(hadith - 1) else { return nil }
            return inChapter[hadith - 1]
        }
        return data.hadiths.first { $0.idInBook == hadith }
    }

    var body: some View {
        Group {
            if let data {
                if let resolved {
                    List {
                        Group {
                            if let chapterTitle = data.chapters.first(where: { $0.id == resolved.chapterId })?.english,
                               !chapterTitle.isEmpty {
                                Section {
                                    Text(chapterTitle)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Section {
                                HadithRow(book: book, hadith: resolved)
                            }
                        }
                        .themedListRowBackground()
                    }
                    .applyConditionalListStyle()
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "questionmark.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)

                        Text(chapter.map { "No hadith \(hadith) in chapter \($0) of \(book.englishTitle)." }
                             ?? "No hadith numbered \(hadith) in \(book.englishTitle).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else if let loadError {
                Text(loadError)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else if !store.isAvailableOffline(book) && !didConfirmDownload {
                // Same courtesy as opening the book itself: never silently pull a large file.
                VStack(spacing: 12) {
                    Text("\(book.englishTitle) has not been downloaded yet (~\(String(format: "%.0f", max(book.approximateMegabytes, 1))) MB).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        settings.hapticFeedback()
                        confirmDownload = true
                    } label: {
                        Label("Download Book", systemImage: "icloud.and.arrow.down")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                    }
                }
                .padding()
                .confirmationDialog("Download \(book.englishTitle)?", isPresented: $confirmDownload, titleVisibility: .visible) {
                    Button("Download") {
                        settings.hapticFeedback()
                        didConfirmDownload = true
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This fetches the whole book for offline reading. It may use significant data - Wi-Fi is recommended.")
                }
            } else {
                ProgressView("Loading \(book.englishTitle)...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(chapter.map { "\(book.englishTitle) \($0):\(hadith)" } ?? "\(book.englishTitle) \(hadith)")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: didConfirmDownload) {
            guard data == nil, store.isAvailableOffline(book) || didConfirmDownload else { return }
            do {
                data = try await store.book(book)
            } catch {
                loadError = error.localizedDescription
            }
        }
    }
}

// MARK: - One hadith

struct HadithRow: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith
    var searchText: String = ""

    /// "Sahih al-Bukhari 1234" - the standard way a hadith is cited.
    private var reference: String {
        "\(book.englishTitle) \(hadith.idInBook)"
    }

    private var isBookmarked: Bool {
        store.isBookmarked(slug: book.slug, idInBook: hadith.idInBook)
    }

    private var shareText: String {
        var parts: [String] = ["[\(reference)]"]
        if !hadith.arabic.isEmpty { parts.append(hadith.arabic) }
        if !hadith.english.narrator.isEmpty { parts.append(hadith.english.narrator) }
        if !hadith.english.text.isEmpty { parts.append(hadith.english.text) }
        return parts.joined(separator: "\n\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(reference)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)

                Spacer(minLength: 0)

                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption2)
                        .foregroundStyle(settings.accentColor.color)
                }
            }

            if settings.showHadithArabic, !hadith.arabic.isEmpty {
                HighlightedSnippet(
                    source: hadith.arabic,
                    term: searchText,
                    font: settings.useFontArabic
                        ? .custom(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .body).pointSize + 4)
                        : .body,
                    accent: settings.accentColor.color,
                    fg: .primary,
                    highlightAllahNames: settings.highlightAllahNames
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
            }

            if settings.showHadithEnglish {
                if settings.showHadithNarrator, !hadith.english.narrator.isEmpty {
                    HighlightedSnippet(
                        source: hadith.english.narrator,
                        term: searchText,
                        font: .system(size: settings.englishFontSize).italic(),
                        accent: settings.accentColor.color,
                        fg: .secondary
                    )
                }

                if !hadith.english.text.isEmpty {
                    HighlightedSnippet(
                        source: hadith.english.text,
                        term: searchText,
                        font: .system(size: settings.englishFontSize),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        highlightAllahNames: settings.highlightAllahNames
                    )
                }
            }
        }
        .padding(.vertical, 4)
        .textSelection(.enabled)
        .contextMenu {
            Text(reference)
                .foregroundStyle(.secondary)

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    store.toggleBookmark(book: book, hadith: hadith)
                }
            } label: {
                Label(isBookmarked ? "Remove Bookmark" : "Bookmark Hadith",
                      systemImage: isBookmarked ? "bookmark.slash" : "bookmark")
            }

            Divider()

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = shareText
            } label: {
                Label("Copy Hadith", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = hadith.arabic
            } label: {
                Label("Copy Arabic", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = [hadith.english.narrator, hadith.english.text]
                    .filter { !$0.isEmpty }
                    .joined(separator: "\n")
            } label: {
                Label("Copy English", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = reference
            } label: {
                Label("Copy Reference", systemImage: "number")
            }

            Divider()

            Button {
                settings.hapticFeedback()
                presentSystemShareSheet(items: [shareText])
            } label: {
                Label("Share Hadith", systemImage: "square.and.arrow.up")
            }
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        HadithView()
    }
}
#endif
