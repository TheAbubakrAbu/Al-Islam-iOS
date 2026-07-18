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

    /// The forties ship inside the app bundle as a data SOURCE: "downloading" one copies the bundled
    /// file to the cache instead of hitting the network. They follow the same download / temporary-read /
    /// delete flow as every other book.
    var isBundled: Bool { group == .forties }

    /// 1-based position in the catalog ("1: Sahih al-Bukhari" ... "10: The Forty Hadith of Imam Nawawi"),
    /// the same numbered style the surah rows use.
    var number: Int {
        (Self.all.firstIndex(of: self) ?? 0) + 1
    }

    static let all: [HadithCatalogBook] = [
        // The Six Books (al-Kutub as-Sittah), in chronological order of their compilers.
        HadithCatalogBook(
            slug: "bukhari", folder: "the_9_books",
            englishTitle: "Sahih al-Bukhari", arabicTitle: "صَحِيح البُخارِي",
            group: .six, approximateMegabytes: 13,
            authorEnglish: "Imam Muhammad ibn Ismail al-Bukhari", authorArabic: "الإمام محمد بن إسماعيل البخاري",
            era: "d. 256 AH / 870 CE",
            shortDescription: "The most authentic book after the Quran, sifted from hundreds of thousands of narrations.",
            longDescription: "Its full title is al-Jami’ al-Musnad as-Sahih al-Mukhtasar min Umur Rasul Allah ﷺ wa Sunanihi wa Ayyamihi - “the abridged, authentically-chained collection of the affairs, practice, and times of the Messenger of Allah ﷺ.” Compiled over sixteen years by Imam al-Bukhari (الإمام البخاري), who sifted its 7,563 hadiths (about 2,600 without repetition) from hundreds of thousands he examined under the strictest standards of authenticity. Muslims across every generation have regarded it as the most authentic book after the Quran itself.",
            aliases: ["bukhari", "bukharee", "bukhary", "albukhari"]
        ),
        HadithCatalogBook(
            slug: "muslim", folder: "the_9_books",
            englishTitle: "Sahih Muslim", arabicTitle: "صَحِيح مُسلِم",
            group: .six, approximateMegabytes: 11.5,
            authorEnglish: "Imam Muslim ibn al-Hajjaj", authorArabic: "الإمام مسلم بن الحجاج",
            era: "d. 261 AH / 875 CE",
            shortDescription: "The second most authentic collection, every hadith gathered with its chains side by side.",
            longDescription: "Its full title is al-Musnad as-Sahih al-Mukhtasar bi-Naql al-‘Adl ‘an al-‘Adl ila Rasul Allah ﷺ. Compiled by Imam Muslim ibn al-Hajjaj of Naysabur (الإمام مسلم بن الحجاج النيسابوري), a student of Imam al-Bukhari. Alongside Sahih al-Bukhari it forms the Sahihayn, the two most authentic books of hadith - this the second of them. Scholars especially prize its arrangement: every narration of a hadith is gathered in one place with its chains compared side by side.",
            aliases: ["muslim", "sahihmuslim"]
        ),
        HadithCatalogBook(
            slug: "ibnmajah", folder: "the_9_books",
            englishTitle: "Sunan Ibn Majah", arabicTitle: "سُنَن ابن ماجَه",
            group: .six, approximateMegabytes: 5.7,
            authorEnglish: "Imam Muhammad ibn Yazid ibn Majah", authorArabic: "الإمام محمد بن يزيد بن ماجه",
            era: "d. 273 AH / 887 CE",
            shortDescription: "The sixth of the Six Books, preserving many hadiths found in none of the other five.",
            longDescription: "Its full title is Sunan Ibn Majah. Compiled by Imam Ibn Majah of Qazwin (الإمام ابن ماجه القزويني), it completes the famous Six Books (al-Kutub as-Sittah), and its particular value is the many hadiths - the zawa’id - it preserves that appear in none of the other five.",
            aliases: ["ibnmajah", "majah", "ibnmaja", "maja"]
        ),
        HadithCatalogBook(
            slug: "abudawud", folder: "the_9_books",
            englishTitle: "Sunan Abi Dawud", arabicTitle: "سُنَن أَبِي داوُد",
            group: .six, approximateMegabytes: 8,
            authorEnglish: "Imam Abu Dawud as-Sijistani", authorArabic: "الإمام أبو داود السجستاني",
            era: "d. 275 AH / 889 CE",
            shortDescription: "The Sunan of legal rulings, about 4,800 hadiths chosen from 500,000.",
            longDescription: "Its full title is Sunan Abi Dawud. Imam Abu Dawud (الإمام أبو داود) selected roughly 4,800 hadiths from the 500,000 he had collected - the Sunan of legal rulings, focused on the narrations jurists build upon. He remarked that four hadiths of it suffice a person for their religion, among them “Actions are by intentions.”",
            aliases: ["abudawud", "abidawud", "abudaud", "abidaud", "dawud", "daud", "dawood", "abudawood"]
        ),
        HadithCatalogBook(
            slug: "tirmidhi", folder: "the_9_books",
            englishTitle: "Jami` at-Tirmidhi", arabicTitle: "جامِع التِرمِذِي",
            group: .six, approximateMegabytes: 7.7,
            authorEnglish: "Imam Muhammad ibn Isa at-Tirmidhi", authorArabic: "الإمام محمد بن عيسى الترمذي",
            era: "d. 279 AH / 892 CE",
            shortDescription: "The graded collection, noting each hadith's strength and the jurists' positions.",
            longDescription: "Its full title is al-Jami’ al-Kabir, known everywhere as Jami’ at-Tirmidhi. Compiled by Imam at-Tirmidhi (الإمام الترمذي), a student of Imam al-Bukhari. Its distinction is method: after most hadiths he states the grading (sahih, hasan, or otherwise) and which schools of law acted upon it - as much a manual of hadith science as a collection.",
            aliases: ["tirmidhi", "tirmizi", "tirmidhee", "attirmidhi", "altirmidhi"]
        ),
        HadithCatalogBook(
            slug: "nasai", folder: "the_9_books",
            englishTitle: "Sunan an-Nasa'i", arabicTitle: "سُنَن النَسائِي",
            group: .six, approximateMegabytes: 8,
            authorEnglish: "Imam Ahmad ibn Shu'ayb an-Nasa'i", authorArabic: "الإمام أحمد بن شعيب النسائي",
            era: "d. 303 AH / 915 CE",
            shortDescription: "The strictest of the four Sunan in its conditions for accepting narrators.",
            longDescription: "Its full title is al-Mujtaba, also called as-Sunan as-Sughra - Imam an-Nasa’i’s (الإمام النسائي) own refinement of his larger Sunan, keeping the narrations he judged strongest. His conditions for accepting narrators were the most rigorous among the authors of the four Sunan.",
            aliases: ["nasai", "nisai", "nasaee", "annasai", "alnasai", "annisai", "alnisai"]
        ),
        // The early collections - all compiled before the Six Books - chronologically.
        HadithCatalogBook(
            slug: "malik", folder: "the_9_books",
            englishTitle: "Muwatta Malik", arabicTitle: "مُوَطَّأ مالِك",
            group: .early, approximateMegabytes: 3.3,
            authorEnglish: "Imam Malik ibn Anas", authorArabic: "الإمام مالك بن أنس",
            era: "d. 179 AH / 795 CE",
            shortDescription: "The earliest collection of all, joining hadith with the practice of Madinah.",
            longDescription: "Its full title is al-Muwatta - “the well-trodden path.” The Muwatta of Imam Malik (الإمام مالك), the Imam of Madinah, is the earliest collection in this library, compiled a full century before Bukhari and Muslim. It weaves hadith together with the established practice of the people of Madinah. Imam ash-Shafi’i called it the soundest book of its time.",
            aliases: ["malik", "muwatta", "muwattamalik", "almuwatta"]
        ),
        HadithCatalogBook(
            slug: "ahmed", folder: "the_9_books",
            englishTitle: "Musnad Ahmad", arabicTitle: "مُسنَد أَحمَد",
            group: .early, approximateMegabytes: 2.4,
            authorEnglish: "Imam Ahmad ibn Hanbal", authorArabic: "الإمام أحمد بن حنبل",
            era: "d. 241 AH / 855 CE",
            shortDescription: "The great Musnad, arranged by the Companion who narrates each hadith.",
            longDescription: "Its full title is Musnad al-Imam Ahmad ibn Hanbal. The great Musnad of Imam Ahmad (الإمام أحمد بن حنبل), founder of the Hanbali school and the towering hadith scholar of his age. Unlike the Sunan books it is arranged by the narrating Companion rather than by topic; the full Musnad spans over 27,000 narrations, of which this dataset carries a selection.",
            aliases: ["ahmad", "ahmed", "musnadahmad", "musnadahmed"]
        ),
        HadithCatalogBook(
            slug: "darimi", folder: "the_9_books",
            englishTitle: "Sunan ad-Darimi", arabicTitle: "سُنَن الدارِمِي",
            group: .early, approximateMegabytes: 3,
            authorEnglish: "Imam Abdullah ibn Abd ar-Rahman ad-Darimi", authorArabic: "الإمام عبد الله بن عبد الرحمن الدارمي",
            era: "d. 255 AH / 869 CE",
            shortDescription: "The early Sunan of a teacher of Muslim, Abu Dawud, and at-Tirmidhi.",
            longDescription: "Its full title is Musnad ad-Darimi, widely known as Sunan ad-Darimi. Compiled by Imam ad-Darimi of Samarqand (الإمام الدارمي), a hadith master whose students included Imam Muslim, Abu Dawud, and at-Tirmidhi. His Sunan opens with a celebrated introduction on the Prophet’s ﷺ status and the etiquette of knowledge.",
            aliases: ["darimi", "daremi", "addarimi", "aldarimi"]
        ),
        // The forties (bundled in the app as a data source; they download like everything else).
        HadithCatalogBook(
            slug: "qudsi40", folder: "forties",
            englishTitle: "Forty Hadith Qudsi", arabicTitle: "الأَحادِيث القُدسِيَّة",
            group: .forties, approximateMegabytes: 0.1,
            authorEnglish: "Related by the Prophet ﷺ from His Lord", authorArabic: "يرويه النبي ﷺ عن ربه",
            era: "Compiled selection",
            shortDescription: "The forty sacred hadiths, their meaning from Allah in the Prophet's ﷺ wording.",
            longDescription: "A hadith qudsi (حديث قدسي) is a narration in which the Prophet ﷺ relates words whose meaning is from Allah, expressed in the Prophet’s ﷺ own wording - distinct from the Quran, which is Allah’s speech in both word and meaning. This is a well-known selection of forty such sacred hadiths, drawn from the authentic collections.\n\nThis selection follows the widely-circulated compilation of Ezzedin Ibrahim and Denys Johnson-Davies (Abdul Wadud).",
            aliases: ["qudsi", "qudsi40", "hadithqudsi"]
        ),
        HadithCatalogBook(
            slug: "nawawi40", folder: "forties",
            englishTitle: "The Forty Hadith of Imam Nawawi", arabicTitle: "الأَربَعُون النَوَوِيَّة",
            group: .forties, approximateMegabytes: 0.1,
            authorEnglish: "Imam Yahya ibn Sharaf an-Nawawi", authorArabic: "الإمام يحيى بن شرف النووي",
            era: "d. 676 AH / 1277 CE",
            shortDescription: "The forty-two foundational hadiths, each an axis the religion turns upon.",
            longDescription: "Its full title is al-Arba’un an-Nawawiyyah. Imam an-Nawawi (الإمام النووي) gathered forty-two foundational hadiths - mostly from Bukhari and Muslim - each chosen because scholars described it as an axis the religion turns upon. Memorized across the Muslim world for over seven centuries, it is usually the first hadith book a student ever studies.",
            aliases: ["nawawi", "nawawi40", "arbaeen", "arbain", "arbaeennawawi", "fortynawawi"]
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
        // Other books, chronologically.
        HadithCatalogBook(
            slug: "aladab_almufrad", folder: "other_books",
            englishTitle: "Al-Adab Al-Mufrad", arabicTitle: "الأَدَب المُفرَد",
            group: .other, approximateMegabytes: 1.8,
            authorEnglish: "Imam Muhammad ibn Ismail al-Bukhari", authorArabic: "الإمام محمد بن إسماعيل البخاري",
            era: "d. 256 AH / 870 CE",
            shortDescription: "The book of manners, Imam al-Bukhari's own work on family and character.",
            longDescription: "Its full title is al-Adab al-Mufrad - “the singular book of manners.” Imam al-Bukhari’s (الإمام البخاري) dedicated book of Islamic manners: over 1,300 narrations on treating parents, neighbors, children, and guests; on speech, anger, mercy, and the everyday character the Prophet ﷺ taught - the gentler companion to his Sahih.",
            aliases: ["adab", "adabmufrad", "adabalmufrad", "aladabalmufrad"]
        ),
        HadithCatalogBook(
            slug: "shamail_muhammadiyah", folder: "other_books",
            englishTitle: "Shama'il Muhammadiyah", arabicTitle: "الشَمائِل المُحَمَّدِيَّة",
            group: .other, approximateMegabytes: 0.5,
            authorEnglish: "Imam Muhammad ibn Isa at-Tirmidhi", authorArabic: "الإمام محمد بن عيسى الترمذي",
            era: "d. 279 AH / 892 CE",
            shortDescription: "The portrait of the Prophet ﷺ, his appearance, habits, and character.",
            longDescription: "Its full title is ash-Shama’il al-Muhammadiyyah wa’l-Khasa’il al-Mustafawiyyah - “the noble qualities of Muhammad ﷺ and the characteristics of the Chosen One.” Imam at-Tirmidhi’s (الإمام الترمذي) beloved portrait of the Prophet ﷺ: around 400 narrations describing his appearance, dress, food, sleep, worship, humility, and character - gathered so that those who never saw him ﷺ could almost see him.",
            aliases: ["shamail", "shamaail", "shamailmuhammadiyah"]
        ),
        HadithCatalogBook(
            slug: "riyad_assalihin", folder: "other_books",
            englishTitle: "Riyad as-Salihin", arabicTitle: "رِياض الصالِحِين",
            group: .other, approximateMegabytes: 2.2,
            authorEnglish: "Imam Yahya ibn Sharaf an-Nawawi", authorArabic: "الإمام يحيى بن شرف النووي",
            era: "d. 676 AH / 1277 CE",
            shortDescription: "The Gardens of the Righteous, the world's most-read book of the daily Sunnah.",
            longDescription: "Its full title is Riyad as-Salihin min Kalam Sayyid al-Mursalin - “Gardens of the Righteous, from the words of the Master of the Messengers.” By Imam an-Nawawi (الإمام النووي): around 1,900 hadiths on worship, character, and everyday conduct, arranged under verses of the Quran. Perhaps the most widely read hadith book in the world - a practical guide to living the Sunnah day by day.",
            aliases: ["riyad", "riyadh", "riyadassalihin", "riyadussalihin", "riyadsaliheen", "riyadhussaliheen", "salihin", "saliheen"]
        ),
        HadithCatalogBook(
            slug: "mishkat_almasabih", folder: "other_books",
            englishTitle: "Mishkat al-Masabih", arabicTitle: "مِشكاة المَصابِيح",
            group: .other, approximateMegabytes: 5.2,
            authorEnglish: "Imam al-Khatib at-Tabrizi", authorArabic: "الإمام الخطيب التبريزي",
            era: "d. c. 741 AH / 1340 CE",
            shortDescription: "The Niche of the Lamps, a comprehensive sourced survey of the whole Sunnah.",
            longDescription: "Its full title is Mishkat al-Masabih - “the niche of the lamps.” Al-Khatib at-Tabrizi (الخطيب التبريزي) expanded al-Baghawi’s Masabih as-Sunnah: he named each hadith’s source collection and added a third section to every chapter, producing one of the most comprehensive single surveys of the Sunnah ever assembled.",
            aliases: ["mishkat", "mishkaat", "mishkatalmasabih"]
        ),
        HadithCatalogBook(
            slug: "bulugh_almaram", folder: "other_books",
            englishTitle: "Bulugh al-Maram", arabicTitle: "بُلُوغ المَرام",
            group: .other, approximateMegabytes: 2.1,
            authorEnglish: "Imam Ibn Hajar al-Asqalani", authorArabic: "الإمام ابن حجر العسقلاني",
            era: "d. 852 AH / 1449 CE",
            shortDescription: "The evidences of Islamic law, the hadiths behind the legal rulings of fiqh.",
            longDescription: "Its full title is Bulugh al-Maram min Adillat al-Ahkam - “attainment of the objective from the evidences of the rulings.” By Ibn Hajar al-Asqalani (ابن حجر العسقلاني), the commentator of Sahih al-Bukhari: around 1,580 hadiths that serve as the evidences for Islamic legal rulings, each with its source noted - studied wherever fiqh is taught.",
            aliases: ["bulugh", "buloogh", "bulughalmaram", "bulughmaram"]
        ),
    ]

    static var bySlug: [String: HadithCatalogBook] {
        Dictionary(uniqueKeysWithValues: all.map { ($0.slug, $0) })
    }

    static func books(in group: Group) -> [HadithCatalogBook] {
        all.filter { $0.group == group }
    }

    static let totalMegabytes: Int = Int(all.reduce(0) { $0 + $1.approximateMegabytes }.rounded())
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

        init(id: Int, idInBook: Int, chapterId: Int, arabic: String, english: EnglishText) {
            self.id = id
            self.idInBook = idInBook
            self.chapterId = chapterId
            self.arabic = arabic
            self.english = english
        }

        private enum CodingKeys: String, CodingKey {
            case id, idInBook, chapterId, arabic, english
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            idInBook = try container.decode(Int.self, forKey: .idInBook)
            // Shama'il Muhammadiyah's dataset carries two hadiths with `chapterId: 8.2` - a FLOAT in a
            // field that is an integer everywhere else. A strict Int decode failed on them and took the
            // whole book down ("the data couldn't be read..."), so fall back to truncating a Double.
            if let whole = try? container.decode(Int.self, forKey: .chapterId) {
                chapterId = whole
            } else {
                chapterId = Int(try container.decode(Double.self, forKey: .chapterId))
            }
            arabic = try container.decode(String.self, forKey: .arabic)
            english = try container.decode(EnglishText.self, forKey: .english)
        }
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
                    preview: String(preview.prefix(140)),
                    chapterId: hadith.chapterId,
                    arabicPreview: String(hadith.arabic.prefix(120)),
                    englishPreview: String(hadith.english.text.prefix(140))
                ),
                at: 0
            )
        }
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: Self.bookmarksKey)
        }
    }

    // MARK: Last read

    /// The most recently read hadith, Quran's Last Read Ayah counterpart. Recorded when a hadith's
    /// detail opens or a page lands on it; persisted across launches.
    @Published private(set) var lastRead: HadithLastRead?

    private static let lastReadKey = "hadithLastRead"

    func loadLastRead() {
        guard lastRead == nil,
              let data = UserDefaults.standard.data(forKey: Self.lastReadKey),
              let decoded = try? JSONDecoder().decode(HadithLastRead.self, from: data) else { return }
        lastRead = decoded
    }

    func recordLastRead(book: HadithCatalogBook, hadith: HadithBookData.Hadith) {
        let entry = HadithLastRead(
            slug: book.slug,
            idInBook: hadith.idInBook,
            reference: "\(book.englishTitle) \(hadith.idInBook)",
            arabicPreview: String(hadith.arabic.prefix(120)),
            englishPreview: String(hadith.english.text.prefix(140)),
            timestamp: Date()
        )
        lastRead = entry
        if let data = try? JSONEncoder().encode(entry) {
            UserDefaults.standard.set(data, forKey: Self.lastReadKey)
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

    /// The book's JSON inside the app bundle, if it ships there (loose or under JSONs/). Any book whose
    /// file exists in the bundle is treated as ALREADY AVAILABLE - no download flow, no storage cost -
    /// so bundling more collections (or building an all-bundled Hadith app) needs no code changes.
    nonisolated static func bundledURL(_ slug: String) -> URL? {
        Bundle.main.url(forResource: slug, withExtension: "json")
            ?? Bundle.main.url(forResource: slug, withExtension: "json", subdirectory: "JSONs")
    }

    /// True when this book can be read right now without the network: downloaded, or shipped in the
    /// app bundle itself.
    func isAvailableOffline(_ book: HadithCatalogBook) -> Bool {
        downloadedSlugs.contains(book.slug) || Self.bundledURL(book.slug) != nil
    }

    /// Bundled books never occupy cache storage and never show download UI.
    nonisolated static func isBundledResource(_ book: HadithCatalogBook) -> Bool {
        bundledURL(book.slug) != nil
    }

    /// The decoded book if it's already in the memory cache - synchronous, so an open of a recently-read
    /// book can render instantly instead of flashing the loading screen.
    func cachedBook(_ slug: String) -> HadithBookData? {
        decoded.first(where: { $0.slug == slug })?.book
    }

    /// Cache-first: memory (decoded), then disk, then the app bundle (forties), then network - decode
    /// always runs off-main. `persist: false` is the TEMPORARY read: the book is loaded into the small
    /// memory cache for this session and nothing is written to disk - it evaporates on its own instead
    /// of taking up storage.
    func book(_ book: HadithCatalogBook, persist: Bool = true) async throws -> HadithBookData {
        if let hit = decoded.first(where: { $0.slug == book.slug })?.book {
            return hit
        }

        let data: Data
        let file = Self.fileURL(book)
        if let bundled = Self.bundledURL(book.slug),
           let bundledData = await Task.detached(priority: .userInitiated, operation: { try? Data(contentsOf: bundled) }).value {
            // Shipped in the app bundle: the bundle IS its storage - nothing to download, nothing to keep.
            data = bundledData
        } else if let disk = await Task.detached(priority: .userInitiated, operation: { try? Data(contentsOf: file) }).value {
            data = disk
        } else {
            guard let remote = Self.endpoint(book) else { throw URLError(.badURL) }
            let (fetched, response) = try await URLSession.shared.data(from: remote)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }
            data = fetched
            if persist {
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

    /// Fetch every non-bundled book not yet on disk, one at a time (the files are large; parallel
    /// fetches of 13 MB JSONs just fight each other for bandwidth). Bundle-shipped books are already
    /// available and skipped.
    func startDownloadAll() {
        guard !isDownloading else { return }
        let downloadable = HadithCatalogBook.all.filter { Self.bundledURL($0.slug) == nil }
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

/// The Hadith tab's trailing toolbar, split with iOS 26 ToolbarSpacers so Liquid Glass doesn't merge
/// the buttons into one capsule - the same treatment the Quran tab's trailing toolbar has.
private struct HadithTrailingToolbar: ViewModifier {
    @ObservedObject var settings = Settings.shared
    @Binding var hadithGridMode: Bool
    @Binding var showHadithSettings: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { gridButton }
                ToolbarSpacer(.fixed, placement: .navigationBarTrailing)
                ToolbarItem(placement: .navigationBarTrailing) { gearButton }
            }
        } else {
            content.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { gridButton }
                ToolbarItem(placement: .navigationBarTrailing) { gearButton }
            }
        }
    }

    private var gridButton: some View {
        Button {
            settings.hapticFeedback()
            withAnimation { hadithGridMode.toggle() }
        } label: {
            Image(systemName: hadithGridMode ? "list.bullet" : "square.grid.2x2")
        }
        .accessibilityLabel(hadithGridMode ? "Show list" : "Show grid")
        .tint(settings.accentColor.accent2)
    }

    private var gearButton: some View {
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

/// A bookmarked hadith, self-contained so the bookmarks list renders without loading its (large) book.
struct HadithBookmark: Codable, Identifiable, Equatable {
    let slug: String
    let idInBook: Int
    let reference: String
    let preview: String
    /// One-line previews, Quran-bookmark style (Arabic + English, never the narrator). Optional so
    /// bookmarks saved by older builds still decode; they fall back to `preview`.
    var chapterId: Int? = nil
    var arabicPreview: String? = nil
    var englishPreview: String? = nil

    var id: String { "\(slug)-\(idInBook)" }
}

/// The most recently read hadith - enough to render its row and jump back without loading the book.
struct HadithLastRead: Codable, Equatable {
    let slug: String
    let idInBook: Int
    let reference: String
    let arabicPreview: String
    let englishPreview: String
    let timestamp: Date
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

    /// Collapse state for the favorites/bookmarks sections, same as the Quran tab's.
    @AppStorage("showHadithFavoriteBooks") private var showFavoriteBooks = true
    @AppStorage("showHadithBookmarks") private var showHadithBookmarks = true
    /// The Hadith tab's OWN grid/list choice - deliberately decoupled from the app-wide `gridMode`
    /// switch, so flipping the hadith catalog doesn't flip the Quran, 99 Names, and Islam grids too.
    @AppStorage("hadithGridMode") private var hadithGridMode = false
    /// "Scroll to book" from a search result: clears the search and lands the catalog on this book.
    @State private var pendingScrollToBookSlug: String? = nil
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false

    // All-books search.
    @State private var globalResults: [(book: HadithCatalogBook, hadiths: [HadithBookData.Hadith])] = []
    @State private var isGlobalSearching = false
    @State private var globalSearchRanFor = ""
    @State private var globalSearchTask: Task<Void, Never>?

    // Hadith of the Day, drawn from the BUNDLED forties - guaranteed offline from first launch.
    @State private var dailyHadith: (book: HadithCatalogBook, hadith: HadithBookData.Hadith)?
    /// "dayKey|slug|idInBook" - a shuffled replacement for TODAY only, exactly like the Ayah of the Day's.
    @AppStorage("hadithOfTheDayOverride") private var dailyOverride = ""
    /// Bumped to re-resolve the daily hadith after a shuffle.
    @State private var dailyReloadTick = 0
    /// Whether the daily section's history (last 5 days) is unfolded - the shuffle only shows here.
    @State private var showDailyHistory = false
    /// Compact "summary mode": Hadith of the Day + Last Read as tiles, like the Quran tab. On by default.
    @AppStorage("hadithSummaryMode") private var hadithSummaryMode = true
    /// A hidden push target (shuffled bookmark, summary tiles) - HadithReferenceView by slug+number.
    @State private var pushedReference: HadithBookmark? = nil

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
            ScrollViewReader { scrollProxy in
            List {
                Group {
                    aboutHadithSection

                    if searchText.isEmpty {
                        if hadithSummaryMode {
                            summaryTilesSection
                        } else {
                            hadithOfTheDaySection
                            lastReadSection
                        }
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
                        bookSection(
                            title: "FAVORITE BOOKS",
                            books: favorites,
                            icon: "star.fill",
                            accentTitle: true,
                            isExpanded: $showFavoriteBooks
                        )
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
            // And the one the shuffled bookmark / summary tiles / daily history push through.
            .background(
                NavigationLink(isActive: Binding(
                    get: { pushedReference != nil },
                    set: { if !$0 { pushedReference = nil } }
                )) {
                    if let pushedReference, let book = HadithCatalogBook.bySlug[pushedReference.slug] {
                        HadithReferenceView(book: book, chapter: nil, hadith: pushedReference.idInBook)
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

            }
            // Trailing buttons live in their own modifier so iOS 26 can interleave ToolbarSpacers
            // between them - without spacers, Liquid Glass merges them into ONE capsule (the same
            // treatment the Quran tab's trailing toolbar has).
            .modifier(HadithTrailingToolbar(
                hadithGridMode: $hadithGridMode,
                showHadithSettings: $showHadithSettings
            ))
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
                Text("This downloads every hadith collection for offline reading. It may use significant data - Wi-Fi is recommended. Already-downloaded books are skipped.")
            }
            .confirmationDialog("Delete all downloaded books?", isPresented: $confirmDeleteAll, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    settings.hapticFeedback()
                    store.deleteAllDownloads()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Books will be re-downloaded as you open them (the forty-hadith collections restore instantly from the app itself).")
            }
            .onAppear {
                store.refreshDiskState()
                store.loadLastRead()
            }
            .task(id: dailyReloadTick) {
                await loadDailyHadith()
            }
            .onChange(of: searchText) { _ in
                // A new query invalidates the last all-books sweep.
                globalSearchTask?.cancel()
                isGlobalSearching = false
                globalResults = []
                globalSearchRanFor = ""
            }
            .onChange(of: pendingScrollToBookSlug) { slug in
                guard let slug else { return }
                pendingScrollToBookSlug = nil
                // Clear the search first so the catalog rows exist, then land on the book.
                withAnimation { searchText = "" }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation { scrollProxy.scrollTo("hadith-book-\(slug)", anchor: .top) }
                }
            }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Hadith of the Day

    /// Words that keep a hadith out of the daily rotation - the same gentle filter the Ayah of the Day
    /// pool uses, plus a length cap so the card never carries a page-long hadith.
    private static let dailyBlockedWords = [
        "kill", "killing", "fight", "fighting", "violence", "violent",
        "murder", "slay", "slaughter", "battle", "war"
    ]

    private static func isDailyWorthy(_ hadith: HadithBookData.Hadith) -> Bool {
        // Short enough for a card: roughly the Ayah of the Day's budget, scaled for hadith prose.
        guard hadith.arabic.count <= 220, hadith.english.text.count <= 220, !hadith.english.text.isEmpty else { return false }
        let combined = (hadith.english.text + " " + hadith.english.narrator).lowercased()
        return !dailyBlockedWords.contains { combined.contains($0) }
    }

    private struct DailyHadithEntry: Codable {
        let dayKey: String
        let slug: String
        let idInBook: Int
        let reference: String
        let arabicPreview: String
        let englishPreview: String
        let date: Date
    }

    private static func loadDailyHistory() -> [DailyHadithEntry] {
        guard let data = UserDefaults.standard.data(forKey: "hadithOfTheDayHistory"),
              let decoded = try? JSONDecoder().decode([DailyHadithEntry].self, from: data) else { return [] }
        return decoded
    }

    private static func saveDailyHistory(_ entries: [DailyHadithEntry]) {
        if let data = try? JSONEncoder().encode(Array(entries.prefix(5))) {
            UserDefaults.standard.set(data, forKey: "hadithOfTheDayHistory")
        }
    }

    private var dailyHistory: [DailyHadithEntry] { Self.loadDailyHistory() }

    /// A deterministic daily pick from the short, gentle pool of the bundled forty collections - the
    /// same hadith all day, a different one tomorrow. A shuffle stores a today-only override, exactly
    /// like the Ayah of the Day's.
    private func loadDailyHadith() async {
        let dayKey = Settings.dayKey()

        // A shuffle override for today wins.
        let parts = dailyOverride.split(separator: "|")
        if parts.count == 3, String(parts[0]) == dayKey,
           let id = Int(parts[2]),
           let book = HadithCatalogBook.bySlug[String(parts[1])],
           let data = try? await store.book(book, persist: false),
           let hadith = data.hadiths.first(where: { $0.idInBook == id }) {
            dailyHadith = (book, hadith)
            recordDailyHistory(book: book, hadith: hadith, dayKey: dayKey)
            return
        }

        var combined: [(HadithCatalogBook, HadithBookData.Hadith)] = []
        for book in HadithCatalogBook.all where book.isBundled {
            // Temporary read: served straight from the app bundle without marking the book downloaded.
            if let data = try? await store.book(book, persist: false) {
                combined.append(contentsOf: data.hadiths.filter(Self.isDailyWorthy).map { (book, $0) })
            }
        }
        guard !combined.isEmpty else { return }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        let pick = combined[day % combined.count]
        dailyHadith = pick
        recordDailyHistory(book: pick.0, hadith: pick.1, dayKey: dayKey)
    }

    /// Keeps the last 5 days on record, one entry per day (a shuffle REPLACES today's entry).
    private func recordDailyHistory(book: HadithCatalogBook, hadith: HadithBookData.Hadith, dayKey: String) {
        var history = Self.loadDailyHistory()
        let entry = DailyHadithEntry(
            dayKey: dayKey,
            slug: book.slug,
            idInBook: hadith.idInBook,
            reference: "\(book.englishTitle) \(hadith.idInBook)",
            arabicPreview: String(hadith.arabic.prefix(120)),
            englishPreview: String(hadith.english.text.prefix(140)),
            date: Date()
        )
        if let first = history.first, first.dayKey == dayKey {
            history[0] = entry
        } else {
            history.insert(entry, at: 0)
        }
        Self.saveDailyHistory(history)
    }

    /// A GENUINELY random hadith - from any collection available on this device (downloaded or bundled),
    /// filtered to the same short-and-gentle pool - stored as today's override.
    private func shuffleDailyHadith() async {
        let available = HadithCatalogBook.all.filter { store.isAvailableOffline($0) }.shuffled()
        for book in available {
            guard let data = try? await store.book(book, persist: false) else { continue }
            let worthy = data.hadiths.filter(Self.isDailyWorthy)
            guard let pick = worthy.randomElement() else { continue }
            dailyOverride = "\(Settings.dayKey())|\(book.slug)|\(pick.idInBook)"
            dailyReloadTick += 1
            return
        }
    }

    @ViewBuilder
    private var hadithOfTheDaySection: some View {
        if let dailyHadith {
            Section {
                HadithRow(book: dailyHadith.book, hadith: dailyHadith.hadith)

                if showDailyHistory {
                    // The last 5 days, timestamped and dimmed - today first. The Today row carries the
                    // shuffle (a genuinely random pick from any collection on this device).
                    ForEach(Array(dailyHistory.enumerated()), id: \.element.dayKey) { index, entry in
                        dailyHistoryRow(entry, isToday: index == 0)
                            .opacity(index == 0 ? 1 : 0.75)
                    }
                }
            } header: {
                HStack {
                    Text("HADITH OF THE DAY")

                    Spacer()

                    Image(systemName: showDailyHistory ? "minus.circle" : "plus.circle")
                        .foregroundColor(settings.accentColor.color)
                        .padding(4)
                        .conditionalGlassEffect()
                        .onTapGesture {
                            settings.hapticFeedback()
                            withAnimation { showDailyHistory.toggle() }
                        }
                        .accessibilityLabel("Show recent hadiths of the day")
                }
            }
        }
    }

    private func dailyHistoryRow(_ entry: DailyHadithEntry, isToday: Bool) -> some View {
        HStack(spacing: 8) {
            Button {
                settings.hapticFeedback()
                pushedReference = HadithBookmark(
                    slug: entry.slug, idInBook: entry.idInBook,
                    reference: entry.reference, preview: entry.englishPreview
                )
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(entry.reference)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)

                        Spacer(minLength: 8)

                        historyTimestampLabel(entry.date)
                    }

                    if !entry.arabicPreview.isEmpty {
                        Text(entry.arabicPreview)
                            .font(settings.useFontArabic
                                  ? Font.arabic(settings.nonQuranArabicFontName, size: 15)
                                  : .footnote)
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                            .lineLimit(1)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    if !entry.englishPreview.isEmpty {
                        Text(entry.englishPreview)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isToday {
                Image(systemName: "shuffle")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: SectionPillHeader.pillHeight, height: SectionPillHeader.pillHeight)
                    .conditionalGlassEffect(circle: true)
                    .onTapGesture {
                        settings.hapticFeedback()
                        Task { await shuffleDailyHadith() }
                    }
                    .accessibilityLabel("Pick a random hadith of the day")
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: Summary tiles + last read

    /// Compact "summary mode", the Quran tab's pattern: Hadith of the Day and Last Read as two tappable
    /// tiles in one section. On by default; the full rows return when it's off (Hadith settings).
    @ViewBuilder
    private var summaryTilesSection: some View {
        Section(header:
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(settings.accentColor.color)
                Text("YOUR SUMMARY")

                Spacer()

                Image(systemName: showDailyHistory ? "minus.circle" : "plus.circle")
                    .foregroundColor(settings.accentColor.color)
                    .padding(4)
                    .conditionalGlassEffect()
                    .onTapGesture {
                        settings.hapticFeedback()
                        withAnimation { showDailyHistory.toggle() }
                    }
            }
        ) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                if let dailyHadith {
                    summaryTile(
                        title: "Hadith of the Day",
                        icon: "sparkles",
                        reference: "\(dailyHadith.book.englishTitle) \(dailyHadith.hadith.idInBook)",
                        arabic: String(dailyHadith.hadith.arabic.prefix(120)),
                        english: String(dailyHadith.hadith.english.text.prefix(140))
                    ) {
                        pushedReference = HadithBookmark(
                            slug: dailyHadith.book.slug, idInBook: dailyHadith.hadith.idInBook,
                            reference: "", preview: ""
                        )
                    }
                }

                if let lastRead = store.lastRead {
                    summaryTile(
                        title: "Last Read Hadith",
                        icon: "book",
                        reference: lastRead.reference,
                        arabic: lastRead.arabicPreview,
                        english: lastRead.englishPreview
                    ) {
                        pushedReference = HadithBookmark(
                            slug: lastRead.slug, idInBook: lastRead.idInBook,
                            reference: lastRead.reference, preview: ""
                        )
                    }
                }
            }
            .padding(.vertical, 4)

            if showDailyHistory {
                ForEach(Array(dailyHistory.enumerated()), id: \.element.dayKey) { index, entry in
                    dailyHistoryRow(entry, isToday: index == 0)
                        .opacity(index == 0 ? 1 : 0.75)
                }
            }
        }
    }

    private func summaryTile(title: String, icon: String, reference: String, arabic: String, english: String, onTap: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(settings.accentColor.color)
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Text(reference)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if !arabic.isEmpty {
                    Text(arabic)
                        .font(settings.useFontArabic
                              ? Font.arabic(settings.nonQuranArabicFontName, size: 15)
                              : .footnote)
                        .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                        .lineLimit(1)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                if !english.isEmpty {
                    Text(english)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(12)
            .conditionalGlassEffect(clear: true, rectangle: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// Last Read Hadith, full-row form (summary mode off) - the Quran's Last Read Ayah counterpart.
    @ViewBuilder
    private var lastReadSection: some View {
        if let lastRead = store.lastRead {
            Section(header: Text("LAST READ HADITH")) {
                Button {
                    settings.hapticFeedback()
                    pushedReference = HadithBookmark(
                        slug: lastRead.slug, idInBook: lastRead.idInBook,
                        reference: lastRead.reference, preview: ""
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(lastRead.reference)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(settings.accentColor.color)

                            Spacer(minLength: 8)

                            historyTimestampLabel(lastRead.timestamp)
                        }

                        if !lastRead.arabicPreview.isEmpty {
                            Text(lastRead.arabicPreview)
                                .font(settings.useFontArabic
                                      ? Font.arabic(settings.nonQuranArabicFontName, size: 15)
                                      : .footnote)
                                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                                .lineLimit(1)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        if !lastRead.englishPreview.isEmpty {
                            Text(lastRead.englishPreview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 2)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: About hadith

    /// One polished orientation card: the two pillar screens as proper links on a glass card, with the
    /// pointer to where the full teachings live.
    private var aboutHadithSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "text.book.closed.fill")
                        .font(.subheadline)
                        .foregroundColor(settings.accentColor.color)

                    Text("About Hadith & the Sunnah")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                }

                NavigationLink(destination: LazyDestination { SunnahPillarView() }) {
                    HStack {
                        Text("What is the Sunnah?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .conditionalGlassEffect(clear: true, rectangle: true)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                NavigationLink(destination: LazyDestination { HadithPillarView() }) {
                    HStack {
                        Text("What are Hadiths?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .conditionalGlassEffect(clear: true, rectangle: true)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text("Learn more under Al-Islam → Pillars and Beliefs.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
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
            let globalMatchCount = globalResults.reduce(0) { $0 + $1.hadiths.count }
            Section(header: HStack {
                Text("ALL BOOKS")
                Spacer()
                if !isGlobalSearching, globalSearchRanFor == query, globalMatchCount > 0 {
                    CountPill(count: globalMatchCount)
                }
            }) {
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
                            // The Quran search's "scroll down to" pattern: a swipe or a long-press takes
                            // you to the book's own row in the catalog instead of opening the hit.
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    settings.hapticFeedback()
                                    pendingScrollToBookSlug = result.book.slug
                                } label: {
                                    Label("Scroll to Book", systemImage: "arrow.down.to.line")
                                }
                                .tint(settings.accentColor.color)
                            }
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
        Section(header: SectionPillHeader(
            title: "BOOKMARKED HADITHS",
            count: store.bookmarks.count,
            icon: "bookmark.fill",
            accentTitle: true,
            isExpanded: $showHadithBookmarks,
            onShuffle: store.bookmarks.isEmpty ? nil : {
                if let random = store.bookmarks.randomElement() {
                    pushedReference = random
                }
            }
        )) {
            if showHadithBookmarks {
                // The first five, Quran-bookmark style; the full list lives one push away.
                ForEach(store.bookmarks.prefix(5)) { bookmark in
                    HadithBookmarkRow(bookmark: bookmark)
                }

                if store.bookmarks.count > 5 {
                    NavigationLink {
                        HadithBookmarksListView()
                    } label: {
                        Label("View All (\(store.bookmarks.count))", systemImage: "bookmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
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

    /// A catalog section rendered as a grid of tiles or a list of rows, per the app-wide `gridMode`,
    /// under the shared counted header. Pass `isExpanded` (plus the star icon and accent) for the
    /// collapsible favorites treatment the Quran tab uses.
    @ViewBuilder
    private func bookSection(
        title: String,
        books: [HadithCatalogBook],
        icon: String? = nil,
        accentTitle: Bool = false,
        isExpanded: Binding<Bool>? = nil
    ) -> some View {
        let header = SectionPillHeader(
            title: title,
            count: books.count,
            icon: icon,
            accentTitle: accentTitle,
            isExpanded: isExpanded
        )
        Section(header: header) {
            if isExpanded?.wrappedValue ?? true {
                if hadithGridMode {
                    LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 10) {
                        ForEach(books) { book in
                            bookGridTile(book)
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(books) { book in
                        NavigationLink {
                            HadithBookView(book: book)
                        } label: {
                            bookRow(book)
                        }
                        .contextMenu { bookContextMenu(book) }
                        // The Quran surah rows' language: swipe to favorite; swipe the other way to
                        // free a download.
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) { store.toggleFavorite(book.slug) }
                            } label: {
                                Label(store.isFavorite(book.slug) ? "Unfavorite" : "Favorite",
                                      systemImage: store.isFavorite(book.slug) ? "star.slash.fill" : "star.fill")
                            }
                            .tint(settings.accentColor.color)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if store.downloadedSlugs.contains(book.slug) {
                                Button(role: .destructive) {
                                    settings.hapticFeedback()
                                    store.deleteDownload(book)
                                } label: {
                                    Label("Delete Download", systemImage: "trash")
                                }
                            }
                        }
                        .id("hadith-book-\(book.slug)")
                    }
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

    /// "~3 MB" - always shown, downloaded or not (the offline icon carries the downloaded state).
    private func bookSizeText(_ book: HadithCatalogBook) -> String {
        "~\(book.approximateMegabytes < 1 ? "0.1" : String(format: "%.0f", book.approximateMegabytes)) MB"
    }

    private func arabicTitleFont(_ style: UIFont.TextStyle, bump: CGFloat) -> Font {
        settings.useFontArabic
            ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: style).pointSize + bump)
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

                    // The size sits right of the title in small type - always, downloaded or not.
                    Text(bookSizeText(book))
                        .font(.caption2)
                        .foregroundColor(.secondary)
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
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.55)

                HStack(spacing: 4) {
                    Text("\(book.number)")
                        .font(.caption2.monospacedDigit())
                        .foregroundColor(.secondary)

                    Text("• \(bookSizeText(book))")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if store.isAvailableOffline(book) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(settings.accentColor.color)
                    }
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            // A fixed height so every tile in the grid lines up regardless of how its titles wrap.
            .frame(height: 84)
            .padding(.vertical, 4)
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
        // No context menu on grid tiles - the long-press preview snapshot fought the tile's glass and
        // the row form still carries the full menu.
    }
}

// MARK: - Hadith settings

/// What a hadith row shows: Arabic, English, the narrator line, and which Arabic face. Small enough to live
/// in a sheet off the Hadith tab rather than the app settings tree.
struct HadithSettingsSheet: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared

    /// What's on the device at a glance: every downloaded book with its size and a per-book delete.
    @ViewBuilder
    private var downloadedBooksSection: some View {
        let downloaded = HadithCatalogBook.all.filter { store.downloadedSlugs.contains($0.slug) }
        Section(
            header: SectionPillHeader(title: "DOWNLOADED", count: downloaded.count),
            footer: downloaded.isEmpty
                ? Text("No books are downloaded. Open any book to download it, or read it once without keeping it.")
                : Text("Tap the trash to remove a book from this device. It can be downloaded again anytime.")
        ) {
            ForEach(downloaded) { book in
                HStack(spacing: 8) {
                    Text(book.englishTitle)
                        .font(.subheadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer()

                    Text("~\(book.approximateMegabytes < 1 ? "0.1" : String(format: "%.0f", book.approximateMegabytes)) MB")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { store.deleteDownload(book) }
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                Group {
                    Section(footer: Text("Summary mode shows Hadith of the Day and your Last Read Hadith as compact tiles, like the Quran tab.")) {
                        Toggle("Summary Mode", isOn: Binding(
                            get: { UserDefaults.standard.object(forKey: "hadithSummaryMode") == nil ? true : UserDefaults.standard.bool(forKey: "hadithSummaryMode") },
                            set: { newValue in
                                settings.hapticFeedback()
                                UserDefaults.standard.set(newValue, forKey: "hadithSummaryMode")
                            }
                        ).animation(.easeInOut))
                    }

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

                            Stepper(value: $settings.hadithArabicFontSize.animation(.easeInOut), in: 15...40, step: 1) {
                                Text("Arabic Font Size: \(Int(settings.hadithArabicFontSize))")
                                    .font(.subheadline)
                            }
                            .onChange(of: settings.hadithArabicFontSize) { _ in settings.hapticFeedback() }
                        }
                    }

                    if settings.showHadithEnglish {
                        Section(header: Text("ENGLISH FONT")) {
                            Stepper(value: $settings.hadithEnglishFontSize.animation(.easeInOut), in: 10...32, step: 1) {
                                Text("English Font Size: \(Int(settings.hadithEnglishFontSize))")
                                    .font(.subheadline)
                            }
                            .onChange(of: settings.hadithEnglishFontSize) { _ in settings.hapticFeedback() }
                        }
                    }

                    downloadedBooksSection
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
    /// "Read Without Downloading": the book loads into the session's memory cache only - full reading,
    /// zero storage kept afterward.
    @State private var temporaryRead = false
    @State private var confirmDeleteDownload = false
    /// The loading spinner waits a beat before appearing - a downloaded book decodes fast enough that
    /// flashing a full loading screen for it read as a glitch.
    @State private var showLoadingSpinner = false
    /// Reading mode for the book, like the Quran's list/mushaf toggle: flipping it changes THIS screen
    /// instead of pushing a new one.
    @AppStorage("hadithPageMode") private var hadithPageMode = false
    @State private var showBookFullScreen = false
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false

    init(book: HadithCatalogBook) {
        self.book = book
        // A book still in the session's memory cache renders instantly - no task hop, no flash.
        _data = State(initialValue: HadithStore.shared.cachedBook(book.slug))
    }

    /// Offline books open straight away; everything else shows the info + download/temporary prompt first.
    private var needsDownloadPrompt: Bool {
        data == nil && !store.isAvailableOffline(book) && !didConfirmDownload && !temporaryRead
    }

    private var hadithCountsByChapter: [Int: Int] {
        guard let data else { return [:] }
        return data.hadiths.reduce(into: [:]) { $0[$1.chapterId, default: 0] += 1 }
    }

    /// Each chapter's span of hadith numbers ("Hadiths 100-200"), from the data itself.
    private var hadithRangesByChapter: [Int: ClosedRange<Int>] {
        guard let data else { return [:] }
        return data.hadiths.reduce(into: [:]) { ranges, hadith in
            if let existing = ranges[hadith.chapterId] {
                ranges[hadith.chapterId] = min(existing.lowerBound, hadith.idInBook)...max(existing.upperBound, hadith.idInBook)
            } else {
                ranges[hadith.chapterId] = hadith.idInBook...hadith.idInBook
            }
        }
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
                if hadithPageMode {
                    HadithPagedView(book: book, bookData: data, chapterIndex: 0)
                } else {
                    loadedBody(data)
                }
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
                Group {
                    if showLoadingSpinner {
                        ProgressView("Loading \(book.englishTitle)...")
                    } else {
                        Color.clear
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task {
                    // Only a load that actually takes a moment earns a spinner.
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    showLoadingSpinner = true
                }
            }
        }
        .navigationTitle(book.englishTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if data != nil {
                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { hadithPageMode.toggle() }
                    } label: {
                        Image(systemName: hadithPageMode ? "list.bullet.rectangle" : "book")
                    }
                    .accessibilityLabel(hadithPageMode ? "Read as a list" : "Read as pages")
                    .tint(settings.accentColor.accent1)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if data != nil {
                    Button {
                        settings.hapticFeedback()
                        showBookFullScreen = true
                    } label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                    .accessibilityLabel("View full screen")
                    .tint(settings.accentColor.accent2)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if data != nil {
                    Button {
                        settings.hapticFeedback()
                        presentSystemShareSheet(items: [bookShareText])
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share this book")
                    .tint(settings.accentColor.accent2)
                }
            }
        }
        .fullScreenCover(isPresented: $showBookFullScreen) {
            if let data {
                HadithImmersiveView(title: book.englishTitle, book: book, hadiths: data.hadiths)
            }
        }
        .task(id: "\(loadAttempt)|\(didConfirmDownload)|\(temporaryRead)") {
            guard data == nil, !needsDownloadPrompt else { return }
            do {
                data = try await store.book(book, persist: !temporaryRead)
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
                                  ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize + 2)
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

                OnlineNoticeCard(text: "This book is about \(bookSizeText) and has not been downloaded yet. Download it to keep it on this device for offline reading, or read it once without keeping it.")

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
                // Anchored to the Download button, so the dialog pops from the control that asked.
                .confirmationDialog("Download \(book.englishTitle)?", isPresented: $confirmDownload, titleVisibility: .visible) {
                    Button("Download (\(bookSizeText))") {
                        settings.hapticFeedback()
                        didConfirmDownload = true
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This fetches the whole book for offline reading. It may use significant data - Wi-Fi is recommended.")
                }

                // The storage-saver: the whole book loads for THIS reading session only and nothing is
                // kept on the device afterward.
                Button {
                    settings.hapticFeedback()
                    temporaryRead = true
                } label: {
                    VStack(spacing: 3) {
                        Label("Read Without Downloading", systemImage: "eye")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)

                        Text("Loads the full book just for now - nothing stays on your device.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .conditionalGlassEffect(clear: true, rectangle: true)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
    }

    private var bookSizeText: String {
        book.approximateMegabytes < 1 ? "under 1 MB" : "\(String(format: "%.0f", book.approximateMegabytes)) MB"
    }

    /// What sharing the BOOK sends: its identity and story, not 13 MB of text.
    private var bookShareText: String {
        var parts = ["\(book.englishTitle) (\(book.arabicTitle))", "\(book.authorEnglish) - \(book.era)", book.longDescription]
        if let data {
            parts.append("\(data.hadiths.count) hadiths - \(data.chapters.count) chapters")
        }
        return parts.joined(separator: "\n\n")
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
                                      ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2)
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

                        // The book's shape at a glance, in the same pill language the section headers use.
                        HStack(spacing: 8) {
                            statPill("\(data.hadiths.count) Hadiths")
                            statPill("\(data.chapters.count) Chapters")
                            statPill(bookSizeText)
                        }
                        .padding(.top, 2)
                    }
                    .padding(.vertical, 2)
                }

                // While searching, matched HADITHS come first - the searcher is usually hunting a text,
                // not a chapter name.
                if !matchingHadiths.isEmpty {
                    Section(header: SectionPillHeader(title: "MATCHING HADITHS", count: matchingHadiths.count)) {
                        ForEach(matchingHadiths) { hadith in
                            HadithRow(book: book, hadith: hadith, searchText: searchText)
                        }
                    }
                }

                Section(header: SectionPillHeader(title: "CHAPTERS", count: filteredChapters.count)) {
                    ForEach(filteredChapters) { chapter in
                        NavigationLink {
                            HadithChapterView(book: book, bookData: data, chapter: chapter)
                        } label: {
                            chapterRow(chapter)
                        }
                        // Swipe a chapter to share its full text.
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                settings.hapticFeedback()
                                let hadiths = data.hadiths.filter { $0.chapterId == chapter.id }
                                var parts = ["\(book.englishTitle) - \(chapter.english)"]
                                parts.append(contentsOf: hadiths.map { HadithShareSheet.composedText(book: book, hadith: $0) })
                                presentSystemShareSheet(items: [parts.joined(separator: "\n\n")])
                            } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .tint(settings.accentColor.color)
                        }
                    }

                    if filteredChapters.isEmpty {
                        Text("No chapters found.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Free the storage right from the book's own page. Bundle-shipped books occupy no
                // cache storage, so there is nothing to delete for them.
                if store.downloadedSlugs.contains(book.slug) {
                    Section {
                        Button(role: .destructive) {
                            settings.hapticFeedback()
                            confirmDeleteDownload = true
                        } label: {
                            Label("Delete Download (\(bookSizeText))", systemImage: "trash")
                                .font(.subheadline)
                        }
                        // Anchored to the Delete button itself.
                        .confirmationDialog("Delete \(book.englishTitle)?", isPresented: $confirmDeleteDownload, titleVisibility: .visible) {
                            Button("Delete Download", role: .destructive) {
                                settings.hapticFeedback()
                                store.deleteDownload(book)
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("Frees about \(bookSizeText). You can download it again anytime\(book.isBundled ? " - it restores instantly from the app itself" : "").")
                        }
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

    /// A small glass stat chip, in the count-pill language.
    private func statPill(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(settings.accentColor.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .conditionalGlassEffect()
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
                    CountPill(count: count)
                }
            }

            // Which hadith numbers this chapter spans - "Hadiths 100-200".
            if let range = hadithRangesByChapter[chapter.id] {
                Text(range.lowerBound == range.upperBound
                     ? "Hadith \(range.lowerBound)"
                     : "Hadiths \(range.lowerBound)-\(range.upperBound)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            if !chapter.arabic.isEmpty {
                HighlightedSnippet(
                    source: chapter.arabic,
                    term: searchText,
                    font: settings.useFontArabic
                        ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2)
                        : .caption,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
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
    /// In-place list/pages toggle, like the Quran reader.
    @State private var chapterPageMode = false
    @State private var showChapterFullScreen = false

    private var chapterIndex: Int {
        bookData.chapters.firstIndex(where: { $0.id == chapter.id }) ?? 0
    }

    private var allChapterHadiths: [HadithBookData.Hadith] {
        bookData.hadiths.filter { $0.chapterId == chapter.id }
    }

    private var chapterRange: ClosedRange<Int>? {
        let ids = allChapterHadiths.map(\.idInBook)
        guard let low = ids.min(), let high = ids.max() else { return nil }
        return low...high
    }

    /// Sharing a CHAPTER sends its full text - name, then every hadith.
    private var chapterShareText: String {
        var parts = ["\(book.englishTitle) - \(chapter.english)"]
        parts.append(contentsOf: allChapterHadiths.map { HadithShareSheet.composedText(book: book, hadith: $0) })
        return parts.joined(separator: "\n\n")
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
        Group {
            if chapterPageMode {
                HadithPagedView(book: book, bookData: bookData, chapterIndex: chapterIndex)
            } else {
                chapterList
            }
        }
        .navigationTitle(chapter.english.isEmpty ? book.englishTitle : chapter.english)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { chapterPageMode.toggle() }
                } label: {
                    Image(systemName: chapterPageMode ? "list.bullet.rectangle" : "book")
                }
                .accessibilityLabel(chapterPageMode ? "Read as a list" : "Read as pages")
                .tint(settings.accentColor.accent1)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    showChapterFullScreen = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .accessibilityLabel("View full screen")
                .tint(settings.accentColor.accent2)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    presentSystemShareSheet(items: [chapterShareText])
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share this chapter")
                .tint(settings.accentColor.accent2)
            }
        }
        .fullScreenCover(isPresented: $showChapterFullScreen) {
            HadithImmersiveView(
                title: chapter.english.isEmpty ? book.englishTitle : chapter.english,
                book: book,
                hadiths: allChapterHadiths
            )
        }
    }

    /// Bookmarks that live inside THIS chapter, matched by stored chapter id (new bookmarks) or by the
    /// chapter's hadith-number span (older ones).
    private var chapterBookmarks: [HadithBookmark] {
        let range = chapterRange
        return HadithStore.shared.bookmarks.filter { bookmark in
            guard bookmark.slug == book.slug else { return false }
            if let chapterId = bookmark.chapterId { return chapterId == chapter.id }
            return range.map { $0.contains(bookmark.idInBook) } ?? false
        }
    }

    @AppStorage("showHadithChapterBookmarks") private var showChapterBookmarks = true
    @State private var pushedChapterBookmark: HadithBookmark? = nil

    private var chapterList: some View {
        List {
            Group {
                if !chapterBookmarks.isEmpty, searchText.isEmpty {
                    Section(header: SectionPillHeader(
                        title: "BOOKMARKED IN THIS CHAPTER",
                        count: chapterBookmarks.count,
                        icon: "bookmark.fill",
                        accentTitle: true,
                        isExpanded: $showChapterBookmarks,
                        onShuffle: {
                            if let random = chapterBookmarks.randomElement() {
                                pushedChapterBookmark = random
                            }
                        }
                    )) {
                        if showChapterBookmarks {
                            ForEach(chapterBookmarks.prefix(5)) { bookmark in
                                HadithBookmarkRow(bookmark: bookmark)
                            }

                            if chapterBookmarks.count > 5 {
                                NavigationLink {
                                    HadithBookmarksListView()
                                } label: {
                                    Label("View All (\(chapterBookmarks.count))", systemImage: "bookmark")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(settings.accentColor.color)
                                }
                            }
                        }
                    }
                }

                Section(header: chapterHeader) {
                    ForEach(hadiths) { hadith in
                        HadithRow(book: book, hadith: hadith, searchText: searchText)
                    }

                    if hadiths.isEmpty {
                        Text("No hadiths found.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .background(
            NavigationLink(isActive: Binding(
                get: { pushedChapterBookmark != nil },
                set: { if !$0 { pushedChapterBookmark = nil } }
            )) {
                if let pushedChapterBookmark, let refBook = HadithCatalogBook.bySlug[pushedChapterBookmark.slug] {
                    HadithReferenceView(book: refBook, chapter: nil, hadith: pushedChapterBookmark.idInBook)
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
    }

    /// The chapter's proper header: its name, the hadith count pill, and the span of hadith numbers.
    private var chapterHeader: some View {
        HStack(spacing: 8) {
            Text("CHAPTER \(chapterIndex + 1)")

            if let range = chapterRange {
                Text(range.lowerBound == range.upperBound
                     ? "- HADITH \(range.lowerBound)"
                     : "- HADITHS \(range.lowerBound)-\(range.upperBound)")
                    .monospacedDigit()
            }

            Spacer()

            CountPill(count: allChapterHadiths.count)
        }
    }
}

// MARK: - Page mode: as many hadiths per page as fit, right-to-left, chapter by chapter

/// The paged reader, in the mushaf's manner: pages turn RIGHT-TO-LEFT, and each page carries as many
/// whole hadiths as the current Arabic/English font sizes allow. Chapter-scoped - paging all ~7,500
/// hadiths of Bukhari through one TabView is the page-realization stampede the Quran mushaf had to
/// engineer around; a chapter is at most a few hundred light pages.
///
/// Layout rules: a chapter heading is never left as the last thing on a page (it moves to the top of
/// the next page so its hadiths follow it), and a hadith is atomic - its reference line and its text
/// always travel together.
struct HadithPagedView: View {
    @ObservedObject private var settings = Settings.shared

    let book: HadithCatalogBook
    let bookData: HadithBookData

    @State var chapterIndex: Int
    @State private var pageIndex = 0

    private enum PageElement: Identifiable {
        case heading(HadithBookData.Chapter)
        case hadith(HadithBookData.Hadith)

        var id: String {
            switch self {
            case .heading(let chapter): return "heading-\(chapter.id)"
            case .hadith(let hadith): return "hadith-\(hadith.id)"
            }
        }
    }

    private var chapter: HadithBookData.Chapter? {
        bookData.chapters.indices.contains(chapterIndex) ? bookData.chapters[chapterIndex] : nil
    }

    private var chapterHadiths: [HadithBookData.Hadith] {
        guard let chapter else { return [] }
        return bookData.hadiths.filter { $0.chapterId == chapter.id }
    }

    // MARK: Measurement

    private func measuredHeight(of text: String, font: UIFont, width: CGFloat, lineSpacing: CGFloat = 0) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        let rect = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font, .paragraphStyle: style],
            context: nil
        )
        return ceil(rect.height)
    }

    /// Estimated on-screen height of one hadith block, mirroring `HadithRow`'s fonts and spacings (with
    /// a little slack - the page also scrolls, so a slight under-estimate can never hide text).
    private func height(of hadith: HadithBookData.Hadith, width: CGFloat) -> CGFloat {
        var total: CGFloat = 28 + 10 + 8   // number badge row + stack spacing + row padding

        if settings.showHadithArabic, !hadith.arabic.isEmpty {
            let arabicFont = UIFont(name: settings.nonQuranArabicFontName, size: settings.hadithArabicFontSize)
                ?? .roundedSystemFont(ofSize: settings.hadithArabicFontSize)
            total += measuredHeight(of: hadith.arabic, font: arabicFont, width: width, lineSpacing: 6) + 10
        }
        if settings.showHadithEnglish {
            let englishFont = UIFont.roundedSystemFont(ofSize: settings.hadithEnglishFontSize)
            if settings.showHadithNarrator, !hadith.english.narrator.isEmpty {
                total += measuredHeight(of: hadith.english.narrator, font: englishFont, width: width) + 10
            }
            if !hadith.english.text.isEmpty {
                total += measuredHeight(of: hadith.english.text, font: englishFont, width: width) + 10
            }
        }
        return total * 1.06
    }

    private func headingHeight(_ chapter: HadithBookData.Chapter, width: CGFloat) -> CGFloat {
        var total: CGFloat = 12
        total += measuredHeight(of: chapter.english, font: .roundedSystemFont(ofSize: 15, weight: .semibold), width: width)
        if !chapter.arabic.isEmpty {
            let arabicFont = UIFont(name: settings.nonQuranArabicFontName, size: 15) ?? .roundedSystemFont(ofSize: 15)
            total += measuredHeight(of: chapter.arabic, font: arabicFont, width: width) + 4
        }
        return total * 1.06
    }

    /// Packs the chapter into pages: fill until the height budget runs out, never orphan the heading,
    /// keep every hadith whole. Re-runs whenever the fonts or display toggles change (it is a pure
    /// function of its inputs), which is what makes the per-page count adapt to the font sizes.
    private func paginate(size: CGSize) -> [[PageElement]] {
        let width = max(size.width - 40, 1)
        let budget = max(size.height - 24, 200)
        let hadiths = chapterHadiths
        guard !hadiths.isEmpty else { return [] }

        var elements: [PageElement] = []
        if let chapter { elements.append(.heading(chapter)) }
        elements.append(contentsOf: hadiths.map { .hadith($0) })

        var pages: [[PageElement]] = []
        var current: [PageElement] = []
        var used: CGFloat = 0
        let spacing: CGFloat = 16

        for element in elements {
            let h: CGFloat
            switch element {
            case .heading(let chapter): h = headingHeight(chapter, width: width)
            case .hadith(let hadith): h = height(of: hadith, width: width)
            }

            let needed = (current.isEmpty ? 0 : spacing) + h
            if !current.isEmpty, used + needed > budget {
                // Never leave a heading stranded as the page's last line - it moves with what follows.
                if case .heading = current.last {
                    let heading = current.removeLast()
                    if !current.isEmpty { pages.append(current) }
                    current = [heading]
                    used = headingHeight(chapter!, width: width)
                } else {
                    pages.append(current)
                    current = []
                    used = 0
                }
                current.append(element)
                used += h
            } else {
                current.append(element)
                used += needed
            }
        }
        if !current.isEmpty { pages.append(current) }
        return pages
    }

    var body: some View {
        GeometryReader { geo in
            let pages = paginate(size: geo.size)

            Group {
                if pages.isEmpty {
                    Text("This chapter has no hadiths.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Right-to-left, exactly like the mushaf: the DATA is reversed rather than the layout
                    // direction, so page 0 sits at the far right and reading advances leftward.
                    TabView(selection: $pageIndex) {
                        ForEach(pages.indices.reversed(), id: \.self) { index in
                            pageBody(pages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .safeAreaInset(edge: .bottom) {
                pagerFooter(pageCount: pages.count, hadithCount: chapterHadiths.count)
            }
        }
        .navigationTitle(chapter?.english.isEmpty == false ? (chapter?.english ?? "") : book.englishTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: chapterIndex) { _ in
            pageIndex = 0
        }
        .onChange(of: pageIndex) { _ in
            recordPageLastRead()
        }
        .onAppear {
            recordPageLastRead()
        }
    }

    /// The page's first hadith becomes the Last Read - the paged equivalent of opening a detail.
    private func recordPageLastRead() {
        guard let first = chapterHadiths.first else { return }
        HadithStore.shared.recordLastRead(book: book, hadith: first)
    }

    private func pageBody(_ elements: [PageElement]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(elements) { element in
                    switch element {
                    case .heading(let chapter):
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chapter.english)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(settings.accentColor.color)

                            if !chapter.arabic.isEmpty {
                                Text(chapter.arabic)
                                    .font(settings.useFontArabic
                                          ? Font.arabic(settings.nonQuranArabicFontName, size: 15)
                                          : .subheadline)
                                    .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }

                    case .hadith(let hadith):
                        HadithRow(book: book, hadith: hadith, opensDetail: false)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private func pagerFooter(pageCount: Int, hadithCount: Int) -> some View {
        VStack(spacing: 6) {
            TrackedBar(
                fraction: pageCount > 1 ? CGFloat(pageIndex) / CGFloat(pageCount - 1) : 1,
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
                        .contentShape(Rectangle())
                }
                .disabled(chapterIndex == 0)

                VStack(spacing: 1) {
                    Text("Chapter \(chapterIndex + 1)/\(bookData.chapters.count)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()

                    Text(pageCount > 0 ? "Page \(pageIndex + 1)/\(pageCount) - \(hadithCount) hadiths" : "-")
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
                        .contentShape(Rectangle())
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
    /// List rows push the hadith's own detail screen; the paged reader turns this off (it IS the reading
    /// surface, and a nav-push mid-page would be jarring).
    var opensDetail: Bool = true

    @State private var showShareSheet = false

    /// "Sahih al-Bukhari 1234" - the standard way a hadith is cited.
    private var reference: String {
        "\(book.englishTitle) \(hadith.idInBook)"
    }

    private var isBookmarked: Bool {
        store.isBookmarked(slug: book.slug, idInBook: hadith.idInBook)
    }

    var body: some View {
        if opensDetail {
            NavigationLink {
                HadithDetailView(book: book, hadith: hadith)
            } label: {
                rowContent
            }
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                // The number badge, in the same conditional-glass language as the surah rows' numbers -
                // tinted when the hadith is bookmarked.
                Text("\(hadith.idInBook)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .conditionalGlassEffect(
                        useColor: isBookmarked ? 0.3 : nil,
                        customTint: isBookmarked ? settings.accentColor.color : nil,
                        interactive: false
                    )

                Text(book.englishTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

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
                        ? Font.arabic(settings.nonQuranArabicFontName, size: settings.hadithArabicFontSize)
                        : .system(size: settings.hadithArabicFontSize),
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
                        font: .system(size: settings.hadithEnglishFontSize).italic(),
                        accent: settings.accentColor.color,
                        fg: .secondary
                    )
                }

                if !hadith.english.text.isEmpty {
                    HighlightedSnippet(
                        source: hadith.english.text,
                        term: searchText,
                        font: .system(size: settings.hadithEnglishFontSize),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        highlightAllahNames: settings.highlightAllahNames
                    )
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Text(reference)
                .foregroundStyle(.secondary)

            if isBookmarked {
                Button(role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        store.toggleBookmark(book: book, hadith: hadith)
                    }
                } label: {
                    Label("Remove Bookmark", systemImage: "bookmark.fill")
                }
            } else {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        store.toggleBookmark(book: book, hadith: hadith)
                    }
                } label: {
                    Label("Bookmark Hadith", systemImage: "bookmark")
                }
            }

            Divider()

            // ONE share surface and ONE copy, both driven by the same composition options - the pile of
            // per-field copy actions collapsed into the Share Hadith sheet.
            Button {
                settings.hapticFeedback()
                showShareSheet = true
            } label: {
                Label("Share Hadith", systemImage: "square.and.arrow.up")
            }

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = HadithShareSheet.composedText(book: book, hadith: hadith)
            } label: {
                Label("Copy Hadith", systemImage: "doc.on.doc")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            HadithShareSheet(book: book, hadith: hadith)
                .smallMediumSheetPresentation()
        }
    }
}

// MARK: - Bookmark rows (Quran-style one-line previews) + the full list

/// A bookmarked hadith row in the Quran-bookmark format: reference, ONE line of Arabic (trailing), ONE
/// line of English - never the narrator. Opens the hadith through the reference resolver.
struct HadithBookmarkRow: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared

    let bookmark: HadithBookmark

    var body: some View {
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

                    if let arabic = bookmark.arabicPreview, !arabic.isEmpty {
                        Text(arabic)
                            .font(settings.useFontArabic
                                  ? Font.arabic(settings.nonQuranArabicFontName, size: 15)
                                  : .footnote)
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                            .lineLimit(1)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    if let english = bookmark.englishPreview, !english.isEmpty {
                        Text(english)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else if bookmark.arabicPreview == nil {
                        // A bookmark saved by an older build carries only the combined preview.
                        Text(bookmark.preview)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.vertical, 2)
            }
            .contextMenu {
                Button(role: .destructive) {
                    settings.hapticFeedback()
                    let placeholder = HadithBookData.Hadith(
                        id: -1, idInBook: bookmark.idInBook, chapterId: bookmark.chapterId ?? -1,
                        arabic: "", english: HadithBookData.Hadith.EnglishText(narrator: "", text: "")
                    )
                    store.toggleBookmark(book: book, hadith: placeholder)
                } label: {
                    Label("Remove Bookmark", systemImage: "bookmark.fill")
                }
            }
        }
    }
}

/// Every bookmarked hadith, pushed from the "View All" row.
struct HadithBookmarksListView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared

    var body: some View {
        List {
            Group {
                Section(header: SectionPillHeader(title: "BOOKMARKED HADITHS", count: store.bookmarks.count)) {
                    ForEach(store.bookmarks) { bookmark in
                        HadithBookmarkRow(bookmark: bookmark)
                    }

                    if store.bookmarks.isEmpty {
                        Text("No bookmarked hadiths yet. Press and hold any hadith to bookmark it.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle("Bookmarked Hadiths")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Hadith detail (one hadith, full size)

/// A single hadith on its own screen: full text with selection enabled, bookmark, the unified share
/// sheet, and an immersive full-screen reading cover.
struct HadithDetailView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    @State private var showShareSheet = false
    @State private var showFullScreen = false

    private var isBookmarked: Bool {
        store.isBookmarked(slug: book.slug, idInBook: hadith.idInBook)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HadithRow(book: book, hadith: hadith, opensDetail: false)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .navigationTitle("\(book.englishTitle) \(hadith.idInBook)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { store.toggleBookmark(book: book, hadith: hadith) }
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                }
                .tint(settings.accentColor.accent1)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    showFullScreen = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .accessibilityLabel("View full screen")
                .tint(settings.accentColor.accent2)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    settings.hapticFeedback()
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .tint(settings.accentColor.accent2)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            HadithShareSheet(book: book, hadith: hadith)
                .smallMediumSheetPresentation()
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            HadithImmersiveView(title: "\(book.englishTitle) \(hadith.idInBook)", book: book, hadiths: [hadith])
        }
        .onAppear {
            store.recordLastRead(book: book, hadith: hadith)
        }
    }
}

// MARK: - Immersive full-screen reading (hadith / chapter / book)

/// Edge-to-edge distraction-free reading: just the hadith text on the system background, with a quiet
/// dismiss control - the hadith counterpart of the Quran's full-screen reading.
struct HadithImmersiveView: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    let title: String
    let book: HadithCatalogBook
    let hadiths: [HadithBookData.Hadith]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    ForEach(hadiths) { hadith in
                        HadithRow(book: book, hadith: hadith, opensDetail: false)
                            .textSelection(.enabled)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        settings.hapticFeedback()
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                    }
                    .accessibilityLabel("Exit full screen")
                    .tint(settings.accentColor.color)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Share Hadith (custom sheet, image or text - the Share Ayah counterpart)

struct HadithShareSheet: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    // What travels with the share - persisted, and shared with Copy Hadith so the two always agree.
    @AppStorage("shareHadithArabic") private var includeArabic = true
    @AppStorage("shareHadithEnglish") private var includeEnglish = true
    @AppStorage("shareHadithNarrator") private var includeNarrator = true
    @AppStorage("shareHadithReference") private var includeReference = true
    @AppStorage("shareHadithAsImage") private var shareAsImage = true

    private var composed: String {
        Self.composedText(book: book, hadith: hadith)
    }

    /// The unified hadith text composition, honoring the persisted include toggles - used by this sheet
    /// AND by the context menu's Copy Hadith, so copy and share always produce the same thing.
    static func composedText(book: HadithCatalogBook, hadith: HadithBookData.Hadith) -> String {
        let defaults = UserDefaults.standard
        func flag(_ key: String) -> Bool { defaults.object(forKey: key) == nil ? true : defaults.bool(forKey: key) }
        var parts: [String] = []
        if flag("shareHadithReference") { parts.append("[\(book.englishTitle) \(hadith.idInBook)]") }
        if flag("shareHadithArabic"), !hadith.arabic.isEmpty { parts.append(hadith.arabic) }
        if flag("shareHadithNarrator"), !hadith.english.narrator.isEmpty { parts.append(hadith.english.narrator) }
        if flag("shareHadithEnglish"), !hadith.english.text.isEmpty { parts.append(hadith.english.text) }
        return parts.joined(separator: "\n\n")
    }

    var body: some View {
        NavigationView {
            List {
                Group {
                    Section {
                        Picker("Share As", selection: $shareAsImage.animation(.easeInOut)) {
                            Text("Image").tag(true)
                            Text("Text").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: shareAsImage) { _ in settings.hapticFeedback() }
                    }

                    Section(header: Text("INCLUDE")) {
                        Toggle("Reference", isOn: $includeReference.animation(.easeInOut))
                        if !hadith.arabic.isEmpty {
                            Toggle("Arabic", isOn: $includeArabic.animation(.easeInOut))
                        }
                        if !hadith.english.text.isEmpty {
                            Toggle("English", isOn: $includeEnglish.animation(.easeInOut))
                        }
                        if !hadith.english.narrator.isEmpty {
                            Toggle("Narrator", isOn: $includeNarrator.animation(.easeInOut))
                        }
                    }
                    .tint(settings.accentColor.color)

                    Section(header: Text("PREVIEW")) {
                        if shareAsImage {
                            if let image = renderImage() {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(16)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                        } else {
                            Text(composed)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Section {
                        Button {
                            settings.hapticFeedback()
                            if shareAsImage, let image = renderImage() {
                                presentSystemShareSheet(items: [image])
                            } else {
                                presentSystemShareSheet(items: [composed])
                            }
                        } label: {
                            Label("Share Hadith", systemImage: "square.and.arrow.up")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }

                        Button {
                            settings.hapticFeedback()
                            if shareAsImage, let image = renderImage() {
                                UIPasteboard.general.image = image
                            } else {
                                UIPasteboard.general.string = composed
                            }
                        } label: {
                            Label("Copy Hadith", systemImage: "doc.on.doc")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .foregroundColor(settings.accentColor.color)
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .navigationTitle("Share Hadith")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
    }

    /// The dark rounded share card, in the Share Ayah visual language: reference caption, Arabic
    /// trailing in the reader's face (Basic falls back to the rounded system face), narrator italic,
    /// English body.
    private func renderImage() -> UIImage? {
        let width: CGFloat = 1080
        let inset: CGFloat = 72
        let textWidth = width - inset * 2

        let baseSize: CGFloat = 40
        let arabicFont = UIFont(name: settings.nonQuranArabicFontName, size: baseSize * 1.2)
            ?? .roundedSystemFont(ofSize: baseSize * 1.2)
        let englishFont = UIFont.roundedSystemFont(ofSize: baseSize)
        let narratorFont = UIFont.italicSystemFont(ofSize: baseSize * 0.85)
        let captionFont = UIFont.roundedSystemFont(ofSize: baseSize * 0.7, weight: .semibold)

        let accent = UIColor(settings.accentColor.color)

        func paragraph(_ alignment: NSTextAlignment, spacing: CGFloat = 8) -> NSParagraphStyle {
            let p = NSMutableParagraphStyle()
            p.alignment = alignment
            p.lineSpacing = spacing
            return p
        }

        let text = NSMutableAttributedString()
        func append(_ string: String, font: UIFont, color: UIColor, alignment: NSTextAlignment) {
            if text.length > 0 { text.append(NSAttributedString(string: "\n\n")) }
            text.append(NSAttributedString(string: string, attributes: [
                .font: font, .foregroundColor: color, .paragraphStyle: paragraph(alignment)
            ]))
        }

        if includeReference { append("\(book.englishTitle) \(hadith.idInBook)", font: captionFont, color: accent, alignment: .center) }
        if includeArabic, !hadith.arabic.isEmpty { append(hadith.arabic, font: arabicFont, color: .white, alignment: .right) }
        if includeNarrator, !hadith.english.narrator.isEmpty { append(hadith.english.narrator, font: narratorFont, color: .lightGray, alignment: .left) }
        if includeEnglish, !hadith.english.text.isEmpty { append(hadith.english.text, font: englishFont, color: .white, alignment: .left) }
        guard text.length > 0 else { return nil }

        let bounds = text.boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let height = ceil(bounds.height) + inset * 2
        let canvas = CGRect(x: 0, y: 0, width: width, height: height)

        return UIGraphicsImageRenderer(size: canvas.size).image { context in
            UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1).setFill()
            UIBezierPath(roundedRect: canvas, cornerRadius: 48).fill()
            text.draw(with: CGRect(x: inset, y: inset, width: textWidth, height: ceil(bounds.height)),
                      options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        HadithView()
    }
}
#endif
