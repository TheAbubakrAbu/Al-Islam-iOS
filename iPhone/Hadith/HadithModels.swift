import SwiftUI

// The Hadith catalog and data models: the 17 collections, ALL of which ship inside the app as packs
// (see HadithPack.swift), reference parsing ("bukhari 5"), and the bookmark / last-read records.

#if os(iOS)

// MARK: - Catalog

// `containsArabicScript` lives in Globals.swift's String extension (shared app-wide by every
// searchable screen), alongside the other Arabic string utilities.
//
// The dataset's whitespace hygiene - hard-wrapped lines, doubled spaces, tabs, no-break spaces - used
// to be cleaned here on every decode on every device. It now runs ONCE, in Tools/pack-hadith.swift,
// and the packs ship the cleaned text.

/// One collection in the catalog: how it's titled and its scholarly context. Every book ships in the
/// app, so this table is purely presentational - there is no download state to describe.
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
    let englishTitle: String
    /// Vocalized (tashkeel) Arabic title - no sukoon marks, and each word's final letter left bare.
    let arabicTitle: String
    let group: Group
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
    /// The Arabic names a reference can use ("البخاري ١٥"), written the way a reader types them:
    /// `HadithReferenceParser` folds them (hamza carriers, ta marbuta, tashkeel, the article) exactly
    /// as it folds the query, so no spelling of a hamza or a final ha needs listing twice.
    let arabicAliases: [String]

    var id: String { slug }


    /// 1-based position in the catalog ("1: Sahih al-Bukhari" ... "10: The Forty Hadith of Imam Nawawi"),
    /// the same numbered style the surah rows use. Memoized - `firstIndex(of:)` compared whole structs
    /// (long description strings included) on every badge render.
    private static let numberBySlug: [String: Int] = Dictionary(
        uniqueKeysWithValues: all.enumerated().map { ($0.element.slug, $0.offset + 1) }
    )

    var number: Int {
        Self.numberBySlug[slug] ?? 0
    }

    static let all: [HadithCatalogBook] = [
        // The Six Books (al-Kutub as-Sittah), in chronological order of their compilers.
        HadithCatalogBook(
            slug: "bukhari",
            englishTitle: "Sahih al-Bukhari", arabicTitle: "صَحِيح البُخارِي",
            group: .six,
            authorEnglish: "Imam Muhammad ibn Ismail al-Bukhari", authorArabic: "الإِمَامُ مُحَمَّدُ بنُ إِسمَاعِيلَ البُخَارِيُّ",
            era: "d. 256 AH / 870 CE",
            shortDescription: "The most authentic book after the Quran, sifted from hundreds of thousands of narrations.",
            longDescription: "Its full title is al-Jami’ al-Musnad as-Sahih al-Mukhtasar min Umur Rasul Allah ﷺ wa Sunanihi wa Ayyamihi, “the abridged, authentically-chained collection of the affairs, practice, and times of the Messenger of Allah ﷺ.” Compiled over sixteen years by Imam al-Bukhari (الإِمَامُ البُخَارِيُّ), who sifted its 7,563 hadiths (about 2,600 without repetition) from hundreds of thousands he examined under the strictest standards of authenticity.\n\nMuslims across every generation have regarded it as the most authentic book after the Quran itself.",
            aliases: ["bukhari", "bukharee", "bukhary", "albukhari", "bokhari", "buhari", "bukhaari"],
            arabicAliases: ["البخاري", "صحيح البخاري", "بخاري"]
        ),
        HadithCatalogBook(
            slug: "muslim",
            englishTitle: "Sahih Muslim", arabicTitle: "صَحِيح مُسلِم",
            group: .six,
            authorEnglish: "Imam Muslim ibn al-Hajjaj", authorArabic: "الإِمَامُ مُسلِمُ بنُ الحَجَّاجِ",
            era: "d. 261 AH / 875 CE",
            shortDescription: "The second most authentic collection, every hadith gathered with its chains side by side.",
            longDescription: "Its full title is al-Musnad as-Sahih al-Mukhtasar bi-Naql al-‘Adl ‘an al-‘Adl ila Rasul Allah ﷺ. Compiled by Imam Muslim ibn al-Hajjaj of Naysabur (الإِمَامُ مُسلِمُ بنُ الحَجَّاجِ النَّيسَابُورِيُّ), a student of Imam al-Bukhari.\n\nAlongside Sahih al-Bukhari it forms the Sahihayn, the two most authentic books of hadith, this the second of them. Scholars especially prize its arrangement: every narration of a hadith is gathered in one place with its chains compared side by side.",
            aliases: ["muslim", "sahihmuslim", "muslem", "moslem"],
            arabicAliases: ["مسلم", "صحيح مسلم"]
        ),
        HadithCatalogBook(
            slug: "ibnmajah",
            englishTitle: "Sunan Ibn Majah", arabicTitle: "سُنَنُ ابنِ مَاجَه",
            group: .six,
            authorEnglish: "Imam Muhammad ibn Yazid ibn Majah", authorArabic: "الإِمَامُ مُحَمَّدُ بنُ يَزِيدَ بنِ مَاجَه",
            era: "d. 273 AH / 887 CE",
            shortDescription: "The sixth of the Six Books, preserving many hadiths found in none of the other five.",
            longDescription: "Its full title is Sunan Ibn Majah.\n\nCompiled by Imam Ibn Majah of Qazwin (الإِمَامُ ابنُ مَاجَه القَزوِينِيُّ), it completes the famous Six Books (al-Kutub as-Sittah), and its particular value is the many hadiths (the zawa’id) it preserves that appear in none of the other five.",
            aliases: ["ibnmajah", "majah", "ibnmaja", "maja"],
            arabicAliases: ["ابن ماجه", "سنن ابن ماجه", "ماجه"]
        ),
        HadithCatalogBook(
            slug: "abudawud",
            englishTitle: "Sunan Abi Dawud", arabicTitle: "سُنَن أَبِي داوُد",
            group: .six,
            authorEnglish: "Imam Abu Dawud as-Sijistani", authorArabic: "الإِمَامُ أَبُو دَاوُدَ السِّجِستَانِيُّ",
            era: "d. 275 AH / 889 CE",
            shortDescription: "The Sunan of legal rulings, about 4,800 hadiths chosen from 500,000.",
            longDescription: "Its full title is Sunan Abi Dawud. Imam Abu Dawud (الإِمَامُ أَبُو دَاوُدَ) selected roughly 4,800 hadiths from the 500,000 he had collected: the Sunan of legal rulings, focused on the narrations jurists build upon.\n\nHe remarked that four hadiths of it suffice a person for their religion, among them “Actions are by intentions.”",
            aliases: ["abudawud", "abidawud", "abudaud", "abidaud", "dawud", "daud", "dawood", "abudawood", "dawoud", "daood", "abu"],
            arabicAliases: ["أبو داود", "أبي داود", "سنن أبي داود", "داود", "أبو داوود", "أبي داوود"]
        ),
        HadithCatalogBook(
            slug: "tirmidhi",
            englishTitle: "Jami` at-Tirmidhi", arabicTitle: "جامِع التِرمِذِي",
            group: .six,
            authorEnglish: "Imam Muhammad ibn Isa at-Tirmidhi", authorArabic: "الإِمَامُ مُحَمَّدُ بنُ عِيسَى التِّرمِذِيُّ",
            era: "d. 279 AH / 892 CE",
            shortDescription: "The graded collection, noting each hadith's strength and the jurists' positions.",
            longDescription: "Its full title is al-Jami’ al-Kabir, known everywhere as Jami’ at-Tirmidhi. Compiled by Imam at-Tirmidhi (الإِمَامُ التِّرمِذِيُّ), a student of Imam al-Bukhari.\n\nIts distinction is method: after most hadiths he states the grading (sahih, hasan, or otherwise) and which schools of law acted upon it, as much a manual of hadith science as a collection.",
            aliases: ["tirmidhi", "tirmizi", "tirmidhee", "attirmidhi", "altirmidhi", "tirmidi", "termizi", "termidhi", "tirmithi", "tirmizee"],
            arabicAliases: ["الترمذي", "جامع الترمذي", "سنن الترمذي"]
        ),
        HadithCatalogBook(
            slug: "nasai",
            englishTitle: "Sunan an-Nasa'i", arabicTitle: "سُنَن النَسائِي",
            group: .six,
            authorEnglish: "Imam Ahmad ibn Shu'ayb an-Nasa'i", authorArabic: "الإِمَامُ أَحمَدُ بنُ شُعَيبٍ النَّسَائِيُّ",
            era: "d. 303 AH / 915 CE",
            shortDescription: "The strictest of the four Sunan in its conditions for accepting narrators.",
            longDescription: "Its full title is al-Mujtaba, also called as-Sunan as-Sughra, Imam an-Nasa’i’s (الإِمَامُ النَّسَائِيُّ) own refinement of his larger Sunan, keeping the narrations he judged strongest.\n\nHis conditions for accepting narrators were the most rigorous among the authors of the four Sunan.",
            aliases: ["nasai", "nisai", "nasaee", "annasai", "alnasai", "annisai", "alnisai", "nasaai", "nassai", "nasayi"],
            arabicAliases: ["النسائي", "سنن النسائي"]
        ),
        // The early collections - all compiled before the Six Books - chronologically.
        HadithCatalogBook(
            slug: "malik",
            englishTitle: "Muwatta Malik", arabicTitle: "مُوَطَّأ مالِك",
            group: .early,
            authorEnglish: "Imam Malik ibn Anas", authorArabic: "الإِمَامُ مَالِكُ بنُ أَنَسٍ",
            era: "d. 179 AH / 795 CE",
            shortDescription: "The earliest collection of all, joining hadith with the practice of Madinah.",
            longDescription: "Its full title is al-Muwatta, “the well-trodden path.” The Muwatta of Imam Malik (الإِمَامُ مَالِكٌ), the Imam of Madinah, is the earliest collection in this library, compiled a full century before Bukhari and Muslim.\n\nIt weaves hadith together with the established practice of the people of Madinah. Imam ash-Shafi’i called it the soundest book of its time.",
            aliases: ["malik", "muwatta", "muwattamalik", "almuwatta", "muatta", "mowatta", "muwata"],
            arabicAliases: ["مالك", "الموطأ", "موطأ مالك", "موطأ الإمام مالك"]
        ),
        HadithCatalogBook(
            slug: "ahmed",
            englishTitle: "Musnad Ahmad", arabicTitle: "مُسنَد أَحمَد",
            group: .early,
            authorEnglish: "Imam Ahmad ibn Hanbal", authorArabic: "الإِمَامُ أَحمَدُ بنُ حَنبَلٍ",
            era: "d. 241 AH / 855 CE",
            shortDescription: "The great Musnad, arranged by the Companion who narrates each hadith.",
            longDescription: "Its full title is Musnad al-Imam Ahmad ibn Hanbal. The great Musnad of Imam Ahmad (الإِمَامُ أَحمَدُ بنُ حَنبَلٍ), founder of the Hanbali school and the towering hadith scholar of his age.\n\nUnlike the Sunan books it is arranged by the narrating Companion rather than by topic; the full Musnad spans over 27,000 narrations, of which this dataset carries a selection.",
            aliases: ["ahmad", "ahmed", "musnadahmad", "musnadahmed"],
            arabicAliases: ["أحمد", "مسند أحمد", "مسند الإمام أحمد"]
        ),
        HadithCatalogBook(
            slug: "darimi",
            englishTitle: "Sunan ad-Darimi", arabicTitle: "سُنَن الدارِمِي",
            group: .early,
            authorEnglish: "Imam Abdullah ibn Abd ar-Rahman ad-Darimi", authorArabic: "الإِمَامُ عَبدُ اللَّهِ بنُ عَبدِ الرَّحمَنِ الدَّارِمِيُّ",
            era: "d. 255 AH / 869 CE",
            shortDescription: "The early Sunan of a teacher of Muslim, Abu Dawud, and at-Tirmidhi.",
            longDescription: "Its full title is Musnad ad-Darimi, widely known as Sunan ad-Darimi. Compiled by Imam ad-Darimi of Samarqand (الإِمَامُ الدَّارِمِيُّ), a hadith master whose students included Imam Muslim, Abu Dawud, and at-Tirmidhi.\n\nHis Sunan opens with a celebrated introduction on the Prophet’s ﷺ status and the etiquette of knowledge.",
            aliases: ["darimi", "daremi", "addarimi", "aldarimi"],
            arabicAliases: ["الدارمي", "سنن الدارمي", "مسند الدارمي"]
        ),
        // The forties - short, foundational collections, usually the first hadith book a student studies.
        HadithCatalogBook(
            slug: "qudsi40",
            englishTitle: "Forty Hadith Qudsi", arabicTitle: "الأَحادِيث القُدسِيَّة",
            group: .forties,
            authorEnglish: "Related by the Prophet ﷺ from His Lord", authorArabic: "يَروِيهِ النَّبِيُّ ﷺ عَن رَبِّهِ",
            era: "Compiled selection",
            shortDescription: "The forty sacred hadiths, their meaning from Allah in the Prophet's ﷺ wording.",
            longDescription: "A hadith qudsi (حَدِيثٌ قُدسِيٌّ) is a narration in which the Prophet ﷺ relates words whose meaning is from Allah, expressed in the Prophet’s ﷺ own wording, distinct from the Quran, which is Allah’s speech in both word and meaning. This is a well-known selection of forty such sacred hadiths, drawn from the authentic collections.\n\nThis selection follows the widely-circulated compilation of Ezzedin Ibrahim and Denys Johnson-Davies (Abdul Wadud).",
            aliases: ["qudsi", "qudsi40", "hadithqudsi", "kudsi", "qudsee"],
            arabicAliases: ["القدسي", "القدسية", "الحديث القدسي", "الأحاديث القدسية", "الأربعون القدسية"]
        ),
        HadithCatalogBook(
            slug: "nawawi40",
            englishTitle: "The Forty Hadith of Imam Nawawi", arabicTitle: "الأَربَعُون النَوَوِيَّة",
            group: .forties,
            authorEnglish: "Imam Yahya ibn Sharaf an-Nawawi", authorArabic: "الإِمَامُ يَحيَى بنُ شَرَفٍ النَّوَوِيُّ",
            era: "d. 676 AH / 1277 CE",
            shortDescription: "The forty-two foundational hadiths, each an axis the religion turns upon.",
            longDescription: "Its full title is al-Arba’un an-Nawawiyyah. Imam an-Nawawi (الإِمَامُ النَّوَوِيُّ) gathered forty-two foundational hadiths (mostly from Bukhari and Muslim), each chosen because scholars described it as an axis the religion turns upon.\n\nMemorized across the Muslim world for over seven centuries, it is usually the first hadith book a student ever studies.",
            aliases: ["nawawi", "nawawi40", "arbaeen", "arbain", "arbaeennawawi", "fortynawawi", "nawawee", "nawawy"],
            arabicAliases: ["النووي", "النووية", "الأربعون النووية", "الأربعين النووية"]
        ),
        HadithCatalogBook(
            slug: "shahwaliullah40",
            englishTitle: "Forty Hadith of Shah Waliullah", arabicTitle: "أَربَعُونَ الشَّاه وَلِيِّ اللَّهِ",
            group: .forties,
            authorEnglish: "Shah Waliullah ad-Dihlawi", authorArabic: "شَاه وَلِيُّ اللَّهِ الدِّهلَوِيُّ",
            era: "d. 1176 AH / 1762 CE",
            shortDescription: "The forty concise hadiths with the shortest, most elevated chains.",
            longDescription: "Collected by Shah Waliullah of Delhi (شَاه وَلِيُّ اللَّهِ الدِّهلَوِيُّ), the reviver of hadith studies in the Indian subcontinent.\n\nHe chose forty concise hadiths distinguished by their short, elevated chains of transmission: comprehensive words gathered in the briefest form.",
            aliases: ["shahwaliullah", "waliullah", "shahwaliullah40"],
            arabicAliases: ["شاه ولي الله", "ولي الله الدهلوي", "الدهلوي"]
        ),
        // Other books, chronologically.
        HadithCatalogBook(
            slug: "aladab_almufrad",
            englishTitle: "Al-Adab Al-Mufrad", arabicTitle: "الأَدَب المُفرَد",
            group: .other,
            authorEnglish: "Imam Muhammad ibn Ismail al-Bukhari", authorArabic: "الإِمَامُ مُحَمَّدُ بنُ إِسمَاعِيلَ البُخَارِيُّ",
            era: "d. 256 AH / 870 CE",
            shortDescription: "The book of manners, Imam al-Bukhari's own work on family and character.",
            longDescription: "Its full title is al-Adab al-Mufrad, “the singular book of manners.”\n\nImam al-Bukhari’s (الإِمَامُ البُخَارِيُّ) dedicated book of Islamic manners: over 1,300 narrations on treating parents, neighbors, children, and guests; on speech, anger, mercy, and the everyday character the Prophet ﷺ taught; the gentler companion to his Sahih.",
            aliases: ["adab", "adabmufrad", "adabalmufrad", "aladabalmufrad"],
            arabicAliases: ["الأدب المفرد", "الأدب"]
        ),
        HadithCatalogBook(
            slug: "shamail_muhammadiyah",
            englishTitle: "Shama'il Muhammadiyah", arabicTitle: "الشَمائِل المُحَمَّدِيَّة",
            group: .other,
            authorEnglish: "Imam Muhammad ibn Isa at-Tirmidhi", authorArabic: "الإِمَامُ مُحَمَّدُ بنُ عِيسَى التِّرمِذِيُّ",
            era: "d. 279 AH / 892 CE",
            shortDescription: "The portrait of the Prophet ﷺ, his appearance, habits, and character.",
            longDescription: "Its full title is ash-Shama’il al-Muhammadiyyah wa’l-Khasa’il al-Mustafawiyyah, “the noble qualities of Muhammad ﷺ and the characteristics of the Chosen One.”\n\nImam at-Tirmidhi’s (الإِمَامُ التِّرمِذِيُّ) beloved portrait of the Prophet ﷺ: around 400 narrations describing his appearance, dress, food, sleep, worship, humility, and character, gathered so that those who never saw him ﷺ could almost see him.",
            aliases: ["shamail", "shamaail", "shamailmuhammadiyah"],
            arabicAliases: ["الشمائل", "الشمائل المحمدية"]
        ),
        HadithCatalogBook(
            slug: "riyad_assalihin",
            englishTitle: "Riyad as-Salihin", arabicTitle: "رِياض الصالِحِين",
            group: .other,
            authorEnglish: "Imam Yahya ibn Sharaf an-Nawawi", authorArabic: "الإِمَامُ يَحيَى بنُ شَرَفٍ النَّوَوِيُّ",
            era: "d. 676 AH / 1277 CE",
            shortDescription: "The Gardens of the Righteous, the world's most-read book of the daily Sunnah.",
            longDescription: "Its full title is Riyad as-Salihin min Kalam Sayyid al-Mursalin, “Gardens of the Righteous, from the words of the Master of the Messengers.” By Imam an-Nawawi (الإِمَامُ النَّوَوِيُّ): around 1,900 hadiths on worship, character, and everyday conduct, arranged under verses of the Quran.\n\nPerhaps the most widely read hadith book in the world, a practical guide to living the Sunnah day by day.",
            aliases: ["riyad", "riyadh", "riyadassalihin", "riyadussalihin", "riyadsaliheen", "riyadhussaliheen", "salihin", "saliheen", "riad", "riadh"],
            arabicAliases: ["رياض الصالحين", "رياض"]
        ),
        HadithCatalogBook(
            slug: "mishkat_almasabih",
            englishTitle: "Mishkat al-Masabih", arabicTitle: "مِشكاة المَصابِيح",
            group: .other,
            authorEnglish: "Imam al-Khatib at-Tabrizi", authorArabic: "الإِمَامُ الخَطِيبُ التِّبرِيزِيُّ",
            era: "d. c. 741 AH / 1340 CE",
            shortDescription: "The Niche of the Lamps, a comprehensive sourced survey of the whole Sunnah.",
            longDescription: "Its full title is Mishkat al-Masabih, “the niche of the lamps.”\n\nAl-Khatib at-Tabrizi (الخَطِيبُ التِّبرِيزِيُّ) expanded al-Baghawi’s Masabih as-Sunnah: he named each hadith’s source collection and added a third section to every chapter, producing one of the most comprehensive single surveys of the Sunnah ever assembled.",
            aliases: ["mishkat", "mishkaat", "mishkatalmasabih", "meshkat"],
            arabicAliases: ["مشكاة المصابيح", "المشكاة", "مشكاة"]
        ),
        HadithCatalogBook(
            slug: "bulugh_almaram",
            englishTitle: "Bulugh al-Maram", arabicTitle: "بُلُوغ المَرام",
            group: .other,
            authorEnglish: "Imam Ibn Hajar al-Asqalani", authorArabic: "الإِمَامُ ابنُ حَجَرٍ العَسقَلَانِيُّ",
            era: "d. 852 AH / 1449 CE",
            shortDescription: "The evidences of Islamic law, the hadiths behind the legal rulings of fiqh.",
            longDescription: "Its full title is Bulugh al-Maram min Adillat al-Ahkam, “attainment of the objective from the evidences of the rulings.”\n\nBy Ibn Hajar al-Asqalani (ابنُ حَجَرٍ العَسقَلَانِيُّ), the commentator of Sahih al-Bukhari: around 1,580 hadiths that serve as the evidences for Islamic legal rulings, each with its source noted; studied wherever fiqh is taught.",
            aliases: ["bulugh", "buloogh", "bulughalmaram", "bulughmaram"],
            arabicAliases: ["بلوغ المرام", "بلوغ"]
        ),
    ]

    // `let`, not a computed var: each book struct carries paragraphs of description text, and the
    // computed form rebuilt (and copied) the whole 17-entry dictionary on every access - including once
    // per element inside prewarm's compactMap and inside render bodies.
    static let bySlug: [String: HadithCatalogBook] =
        Dictionary(uniqueKeysWithValues: all.map { ($0.slug, $0) })

    static func books(in group: Group) -> [HadithCatalogBook] {
        all.filter { $0.group == group }
    }
}

// MARK: - Models (a book, backed by its pack)

/// One open collection. It holds no text: `HadithPack` has the book memory-mapped, and every string
/// below is fetched from it (and its block cache) at the moment a view asks for it. That is what lets
/// all 17 books - 50,884 hadiths - be open at once for the price of their id tables.
/// `@unchecked Sendable`: every stored property is a `let` (the pack is Sendable by design, the rest
/// are value arrays), so the store can build one in a detached task and hand it to the main actor.
struct HadithBookData: @unchecked Sendable {
    struct Metadata {
        struct Titles {
            let title: String
            let author: String
        }
        let arabic: Titles
        let english: Titles
    }

    /// The dataset's ids are integers everywhere except Shama'il Muhammadiyah, which squeezes in a
    /// sub-chapter as the FLOAT id `8.2` (on the chapter AND its hadiths). Truncating it collided with
    /// chapter 8, so fractional ids map to a stable synthetic integer instead (8.2 -> 1082) and the
    /// sub-chapter keeps its own identity. Applied by the packer; kept here as the definition of the
    /// rule the packer implements.
    static func normalizedChapterId(_ raw: Double) -> Int {
        raw == raw.rounded(.down) ? Int(raw) : 1000 + Int((raw * 10).rounded())
    }

    struct Chapter: Identifiable, Hashable {
        let id: Int
        let arabic: String
        let english: String
        /// The prebuilt search folds. Chapter names are small enough to ride in the pack's eager
        /// section, so matching a chapter never touches a block.
        let foldArabic: String
        let foldEnglish: String
        /// The chapter's run in the book's hadith array, computed when the pack was built. Opening a
        /// chapter is a slice of `hadiths`, not a scan of all 7,000 of them.
        let firstRow: Int
        let rowCount: Int

        /// The 1-based position of a hadith within THIS chapter (the ayah row's within-surah
        /// numbering, for hadiths): the chapter starts at `firstRow`, so this needs no search.
        func position(ofRow row: Int) -> Int? {
            guard row >= firstRow, row < firstRow + rowCount else { return nil }
            return row - firstRow + 1
        }
    }

    struct Hadith: Identifiable {
        struct EnglishText {
            let narrator: String
            let text: String

            init(narrator: String, text: String) {
                self.narrator = narrator
                self.text = text
            }
        }

        /// Where this hadith's text comes from. `.packed` is every real hadith - the strings are read
        /// out of the pack on demand; `.literal` covers the placeholder rows the reference screens
        /// build for a hadith they are still resolving.
        fileprivate enum Storage {
            case packed(HadithPack, Int)
            case literal(String, EnglishText)
        }

        let id: Int
        let idInBook: Int
        let chapterId: Int
        /// The standard sunnah.com citation ("2950", "8a") - the number readers cite, which is NOT
        /// `idInBook` (upstream's row index drifts from the standard numbering; Jami` at-Tirmidhi
        /// 2950 sits at idInBook 3033). Nil where sunnah.com has no collection-level number
        /// (Muwatta Malik, most of Bulugh al-Maram) and for placeholder rows.
        let citation: String?
        /// Precomputed answers that would otherwise need this hadith's text - see `HadithPack.Flag`.
        let flags: UInt8
        fileprivate let storage: Storage

        /// The number every user-facing surface prints beside this hadith: the standard citation
        /// when one exists, the internal row number when none does (which is also what those books
        /// showed before citations existed, so nothing regresses).
        var displayNumber: String {
            guard let citation else { return String(idInBook) }
            return isIntroduction ? "Introduction \(citation)" : citation
        }

        /// Whether this row is in Sahih Muslim's muqaddimah, whose 91 rows carry the Introduction's
        /// OWN numbering (1-92; 34 of the numbers exist in Book 1 too). sunnah.com prints those as
        /// "Sahih Muslim Introduction 9", so every display of the citation qualifies it the same way.
        var isIntroduction: Bool {
            guard chapterId == 0, case let .packed(pack, _) = storage else { return false }
            return pack.slug == "muslim"
        }

        /// This hadith's position in its book, which is also its row in the pack. -1 for placeholders.
        var row: Int {
            if case let .packed(_, row) = storage { return row }
            return -1
        }

        fileprivate init(pack: HadithPack, row: Int) {
            let record = pack.rows[row]
            id = Int(record.id)
            idInBook = Int(record.idInBook)
            chapterId = Int(record.chapterId)
            citation = record.citation
            flags = record.flags
            storage = .packed(pack, row)
        }

        init(id: Int, idInBook: Int, chapterId: Int, citation: String? = nil,
             arabic: String, english: EnglishText) {
            self.id = id
            self.idInBook = idInBook
            self.chapterId = chapterId
            self.citation = citation
            self.flags = 0
            self.storage = .literal(arabic, english)
        }

        var arabic: String {
            switch storage {
            case let .packed(pack, row): return pack.string(row: row, field: 0)
            case let .literal(arabic, _): return arabic
            }
        }

        var english: EnglishText {
            switch storage {
            case let .packed(pack, row):
                let strings = pack.strings(row: row)
                return EnglishText(narrator: strings.narrator, text: strings.text)
            case let .literal(_, english): return english
            }
        }

        /// All three strings in one block lookup - for the paths that render (or copy, or share) the
        /// whole hadith and would otherwise ask for them one at a time.
        var allText: (arabic: String, narrator: String, text: String) {
            switch storage {
            case let .packed(pack, row): return pack.strings(row: row)
            case let .literal(arabic, english): return (arabic, english.narrator, english.text)
            }
        }

        /// The scholar verdicts (sahih / hasan / da'if and their many nuanced forms), every one the
        /// data carries - where scholars disagree, all are kept. Empty means "no grading is known",
        /// never "ungraded": Bukhari and Muslim carry none by design (the collections are sahih),
        /// and placeholders carry none at all. Display verbatim; the 2,358 distinct verdict strings
        /// are not points on one scale and must not be ranked or color-coded by parsing.
        var grades: [(name: String, grade: String)] {
            if case let .packed(pack, row) = storage { return pack.grades(row: row) }
            return []
        }
    }

    let pack: HadithPack
    let metadata: Metadata
    let chapters: [Chapter]
    let hadiths: [Hadith]

    init(pack: HadithPack) {
        self.pack = pack
        metadata = Metadata(
            arabic: Metadata.Titles(title: pack.arabicTitle, author: pack.arabicAuthor),
            english: Metadata.Titles(title: pack.englishTitle, author: pack.englishAuthor)
        )
        chapters = pack.chapters.map {
            Chapter(id: $0.id, arabic: $0.arabic, english: $0.english,
                    foldArabic: $0.foldArabic, foldEnglish: $0.foldEnglish,
                    firstRow: $0.firstRow, rowCount: $0.rowCount)
        }
        hadiths = (0..<pack.rows.count).map { Hadith(pack: pack, row: $0) }
        chapterIndexByID = Dictionary(
            pack.chapters.enumerated().map { ($0.element.id, $0.offset) },
            uniquingKeysWith: { first, _ in first }
        )
        // First row per base as a flat Int32 map; the rare bases that own several rows (Sahih
        // Muslim's 8a...8e) keep their tail in an overflow map. The old `[Int: [Int]]` held one heap
        // array per cited row - 47,476 allocations and ~3 MB shelf-wide for a table that is one
        // integer almost everywhere (performance plan, Phase 7 step 6).
        var firstRows: [Int32: Int32] = [:]
        firstRows.reserveCapacity(pack.rows.count)
        var overflow: [Int32: [Int32]] = [:]
        for (row, record) in pack.rows.enumerated() where record.citationBase > 0 {
            if firstRows[record.citationBase] == nil {
                firstRows[record.citationBase] = Int32(row)
            } else {
                overflow[record.citationBase, default: []].append(Int32(row))
            }
        }
        citationFirstRow = firstRows
        citationOverflowRows = overflow
    }

    // MARK: Text prefetch

    /// Whether every text block behind `rows` is already decoded and resident - the chapter reader
    /// renders its rows at once when this is true and gates them behind a prefetch otherwise.
    func hasText(rows range: Range<Int>) -> Bool {
        pack.hasText(rows: range)
    }

    /// Decode the text blocks behind `rows` into the shared cache - see `HadithPack.prefetchText`.
    /// Call from a detached task; it is pure pack work and touches nothing on the main actor.
    func prewarmText(rows range: Range<Int>) {
        pack.prefetchText(rows: range)
    }

    /// The rows in `range` matching the query, at most `limit`, scanned one search block at a
    /// time - the sweep primitive every hadith search uses (`HadithPack.matchingRows`).
    func matchingRows(in range: Range<Int>, query: HadithFold.Query, limit: Int) -> [Int] {
        pack.matchingRows(in: range, query: query, limit: limit)
    }

    /// The filtered sweep: several needles and a row test (`HadithSearchFilters`).
    func matchingRows(in range: Range<Int>, queries: [HadithFold.Query], requireAll: Bool, limit: Int,
                      accept: ((Int) -> Bool)?) -> [Int] {
        pack.matchingRows(in: range, queries: queries, requireAll: requireAll, limit: limit, accept: accept)
    }

    // MARK: Chapters

    /// Chapter id -> its position in `chapters`, so the "which chapter is this?" lookups the rows do
    /// per render are a hash hit rather than a linear search.
    private let chapterIndexByID: [Int: Int]

    /// This chapter's hadiths - a SLICE of `hadiths`, in O(1). The packer proved the run is unbroken
    /// when it built the pack, so no filter over the book is needed (and Bukhari's chapter rows used
    /// to pay 7,277 comparisons each, every time one opened).
    func hadiths(in chapter: Chapter) -> ArraySlice<Hadith> {
        let upper = min(chapter.firstRow + chapter.rowCount, hadiths.count)
        guard chapter.firstRow >= 0, chapter.firstRow <= upper else { return [] }
        return hadiths[chapter.firstRow..<upper]
    }

    /// The chapter a hadith belongs to, by id.
    func chapter(id: Int) -> Chapter? {
        chapterIndexByID[id].map { chapters[$0] }
    }

    /// The chapter a hadith sits in - by ROW, so it works even for the books whose chapter ids repeat
    /// nothing and costs one hash lookup.
    func chapter(of hadith: Hadith) -> Chapter? {
        chapter(id: hadith.chapterId)
    }

    /// The 1-based position of this hadith within its own chapter, or nil if it can't be placed.
    func positionInChapter(_ hadith: Hadith) -> Int? {
        guard hadith.row >= 0, let chapter = chapter(of: hadith) else { return nil }
        return chapter.position(ofRow: hadith.row)
    }

    // MARK: Searching

    /// A query that is nothing but digits is a hadith NUMBER, not text: "5" means "hadith 5", the way
    /// hadiths are actually cited - and folding it into a keyword search finds only the hadiths whose
    /// text happens to contain a "5". Returns nil for anything else, so ordinary search is untouched.
    /// Capped at five digits, the ceiling `HadithReferenceParser` already uses for the same reason.
    static func hadithNumber(inQuery raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 5,
              trimmed.allSatisfy({ $0.isASCII && $0.isNumber }),
              let number = Int(trimmed), number > 0 else { return nil }
        return number
    }

    /// The citation form of the same rule: digits with an optional variant letter, "2950" or "8a" -
    /// how sunnah.com actually numbers. Returns nil for anything else, so keyword search is untouched.
    static func citationNumber(inQuery raw: String) -> (base: Int, suffix: String?)? {
        // Arabic-Indic digits read as numbers here too ("١٥"), the way "1:4" below already reads them.
        var trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().normalizingArabicIndicDigitsToWestern
        var suffix: String? = nil
        // One variant letter, or two where sunnah.com ran past "z" ("1211aa"); the second letter
        // is only ever preceded by "a", so "ab" is a suffix and "xy" is not a citation at all.
        let letters = String(trimmed.reversed().prefix { $0.isASCII && $0.isLetter }.reversed())
        if letters.count == 1 || (letters.count == 2 && letters.first == "a") {
            suffix = letters
            trimmed = String(trimmed.dropLast(letters.count)).trimmingCharacters(in: .whitespaces)
        } else if !letters.isEmpty {
            return nil
        }
        guard !trimmed.isEmpty, trimmed.count <= 5,
              trimmed.allSatisfy({ $0.isASCII && $0.isNumber }),
              let number = Int(trimmed), number > 0 else { return nil }
        return (number, suffix)
    }

    /// "1:4", the shape a reader types INSIDE a book: chapter 1, hadith 4. Also "1.4", "1-4" and
    /// "1/4", with Arabic-Indic digits folded. Returns nil for anything else, so keyword search is
    /// untouched. Both numbers keep the five-digit ceiling the other number readings use.
    static func chapterHadith(inQuery raw: String) -> (chapter: Int, hadith: Int)? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).normalizingArabicIndicDigitsToWestern
        let parts = trimmed.split(omittingEmptySubsequences: false) { ":.-/".contains($0) }
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              parts.allSatisfy({ !$0.isEmpty && $0.count <= 5 && $0.allSatisfy { $0.isASCII && $0.isNumber } }),
              let chapter = Int(parts[0]), let hadith = Int(parts[1]), chapter > 0, hadith > 0 else { return nil }
        return (chapter, hadith)
    }

    /// Whether the query is a number reading ("15", "8a", "1:4") rather than words: those get an
    /// exact lookup, so there is nothing for the keyword scan or the semantic engine to answer.
    static func isNumberQuery(_ raw: String) -> Bool {
        citationNumber(inQuery: raw) != nil || chapterHadith(inQuery: raw) != nil
    }

    /// The chapter a reader calls "chapter N": its POSITION in the book, which is the number every
    /// chapter row and tile shows.
    func chapter(atPosition position: Int) -> Chapter? {
        chapters.indices.contains(position - 1) ? chapters[position - 1] : nil
    }

    /// "C:N": the Nth hadith of the chapter at position C. The one rule behind "bukhari 1:4" in the
    /// all-books search, `HadithReferenceView`, and a bare "1:4" typed inside the book.
    func hadith(chapterPosition: Int, position: Int) -> Hadith? {
        guard let chapter = chapter(atPosition: chapterPosition) else { return nil }
        let inChapter = hadiths(in: chapter)
        let offset = inChapter.startIndex + (position - 1)
        guard position >= 1, offset < inChapter.endIndex else { return nil }
        return inChapter[offset]
    }

    /// The hadith numbered `number` in this book, by `idInBook` - the internal row numbering. In most
    /// books `idInBook` is simply the row + 1, so the common case costs one index check; the books
    /// whose numbering skips or repeats fall back to a scan.
    func hadith(numbered number: Int) -> Hadith? {
        let index = number - 1
        if hadiths.indices.contains(index), hadiths[index].idInBook == number { return hadiths[index] }
        return hadiths.first { $0.idInBook == number }
    }

    // MARK: Citations

    /// Citation base number -> the FIRST row carrying it; `citationOverflowRows` holds the rest for
    /// the bases that own several ("Sahih Muslim 8" owns five rows, 8a...8e; most own exactly one).
    private let citationFirstRow: [Int32: Int32]
    private let citationOverflowRows: [Int32: [Int32]]

    /// Every hadith cited under base `number` ("muslim 8" -> 8a, 8b, 8c, 8d, 8e), in book order.
    func hadiths(citing number: Int) -> [Hadith] {
        guard let base = Int32(exactly: number), let first = citationFirstRow[base] else { return [] }
        var result = [hadiths[Int(first)]]
        if let rest = citationOverflowRows[base] {
            result.append(contentsOf: rest.map { hadiths[Int($0)] })
        }
        return result
    }

    /// What a citation means in this book: the hadith cited `number` (+ optional variant letter),
    /// preferring the standard numbering and falling back to `idInBook` for the books that have no
    /// citations (Muwatta Malik, most of Bulugh al-Maram) - which is also what old habits typed in.
    /// Without a suffix, a multi-variant base resolves to its first variant, sunnah.com's own order.
    func hadith(referenced number: Int, suffix: String? = nil, introduction: Bool = false) -> Hadith? {
        var cited = hadiths(citing: number)
        // Sahih Muslim's muqaddimah numbers itself 1-92 and 34 of those numbers exist in Book 1
        // too. A plain "muslim 9" is the Book 1 hadith (its row comes first, and sunnah.com's
        // "Sahih Muslim 9" means that one); "muslim introduction 9" is the Introduction's.
        if introduction {
            cited = cited.filter(\.isIntroduction)
        }
        if let suffix, !suffix.isEmpty {
            return cited.first { $0.citation == "\(number)\(suffix)" }
        }
        if let first = cited.first { return first }
        return introduction ? nil : hadith(numbered: number)
    }

    /// Whether this hadith matches the folded query. The comparison runs as a byte search inside the
    /// pack's decompressed search block - no per-hadith normalization, no String allocated, which is
    /// what the in-memory search index used to buy at the cost of holding the whole book folded in RAM.
    func matches(_ hadith: Hadith, _ query: HadithFold.Query) -> Bool {
        guard !query.isEmpty else { return false }
        switch hadith.storage {
        case let .packed(pack, row):
            return pack.matches(row: row, query: query)
        case let .literal(arabic, english):
            let haystack = query.isArabic
                ? HadithFold.arabic(arabic)
                : HadithFold.english(english.text + "\n" + english.narrator)
            return haystack.contains(query.folded)
        }
    }

    /// Whether a chapter's name matches - Arabic queries against the Arabic name, Latin against the
    /// English, the script-aware rule the rest of search follows.
    func matches(_ chapter: Chapter, _ query: HadithFold.Query) -> Bool {
        guard !query.folded.isEmpty else { return true }
        return query.isArabic
            ? chapter.foldArabic.contains(query.folded)
            : chapter.foldEnglish.contains(query.folded)
    }
}

// MARK: - Reference lookups ("bukhari 5", "muslim 3:12")

enum HadithReferenceParser {
    /// The words that name no collection on their own. Two kinds: articles, and the generic words that
    /// appear across half the shelf - every book is a "Sahih" or a "Sunan" or a "Musnad", three of them
    /// are a "Forty", and all 50,884 of them are a "Hadith". Dropping these is exactly what makes
    /// "Hadith 24" resolve to nothing (as it should - it names no book) while "Qudsi 24" resolves to one.
    private static let dropped: Set<String> = [
        "al", "an", "as", "ad", "at", "the", "of", "imam",
        "sahih", "sunan", "jami", "musnad", "hadith", "hadiths", "ahadith",
        "forty", "40", "book", "books", "collection",
        // The same generic words in Arabic, as `arabicWords` leaves them (folded, article dropped).
        // ("الله" too: it is a word of Shah Waliullah's name, and half of what is typed in Arabic.)
        "صحيح", "سنن", "جامع", "مسند", "حديث", "احاديث", "اربعون", "اربعين", "كتاب", "امام", "رقم", "الله",
    ]

    /// The distinctive words of a name, lowercased: "Hadith Al-Qudsi" -> ["qudsi"], "Al-Adab
    /// Al-Mufrad" -> ["adab", "mufrad"].
    static func words(_ raw: String) -> [String] {
        if HadithFold.isArabicScript(raw) { return arabicWords(raw) }
        // Apostrophes BIND, they don't separate: "Nasa'i" is one word. Splitting on them left the
        // single letter "i" standing as a name for Sunan an-Nasa'i (and "il" for the Shama'il).
        // The joined `normalize` form is unaffected either way - that is why the alias tables still match.
        var text = raw.lowercased()
        for apostrophe in ["'", "\u{2019}", "\u{02BC}", "`"] {
            text = text.replacingOccurrences(of: apostrophe, with: "")
        }
        return text
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty && !dropped.contains($0) }
    }

    /// `words` for a name in Arabic ("صحيح البخاري", "سنن أبي داود"): the search fold first (hamza
    /// carriers to bare letters, ta marbuta to ha, tashkeel and punctuation gone), then the article
    /// off each word, then the generic words out. "البُخَارِيّ", "بخاري" and "صحيح البخارى" all come
    /// out as ["بخاري"]: a dotless final ya is a ya in these names (the fold alone reads it as an
    /// alif), and the tatweel is dropped. The article stays on a word it would leave shorter than
    /// three letters ("الله"), so nothing is cut down to a stub.
    private static func arabicWords(_ raw: String) -> [String] {
        HadithFold.arabic(raw.replacingOccurrences(of: "\u{0640}", with: "").replacingOccurrences(of: "\u{0649}", with: "\u{064A}"))
            .split(separator: " ")
            .map { word -> String in
                word.hasPrefix("ال") && word.count >= 5 ? String(word.dropFirst(2)) : String(word)
            }
            .filter { !$0.isEmpty && !dropped.contains($0) }
    }

    /// Those words as one key. "Sunan An-Nisa'i" and "nisai" both normalize to "nisai"; "Al-Adab
    /// Al-Mufrad" stays distinct ("adabmufrad"). This is the form the alias tables are written in.
    static func normalize(_ raw: String) -> String {
        words(raw).joined()
    }

    /// Per book: the whole-name keys (its aliases, plus its title normalized), and separately every
    /// individual word that can name it. Built once - `parse` runs on the main thread per keystroke.
    /// The Arabic side of both tables is the book's own Arabic title plus its `arabicAliases`, folded
    /// here by the rule the query is folded by.
    private static let keysBySlug: [String: Set<String>] = Dictionary(
        uniqueKeysWithValues: HadithCatalogBook.all.map { book in
            let arabic = ([book.arabicTitle] + book.arabicAliases).map(normalize).filter { !$0.isEmpty }
            return (book.slug, Set(book.aliases).union([normalize(book.englishTitle)]).union(arabic))
        }
    )

    private static let wordsBySlug: [String: Set<String>] = Dictionary(
        uniqueKeysWithValues: HadithCatalogBook.all.map { book in
            let arabic = ([book.arabicTitle] + book.arabicAliases).flatMap(words)
            return (book.slug, Set(words(book.englishTitle)).union(book.aliases).union(arabic))
        }
    )

    /// The collection a name refers to. Tried in three passes, each stricter about guessing than the
    /// last, and every pass refuses a name that fits more than one book rather than picking one:
    ///
    ///   1. the whole name as a key      "abudawud", "riyadussalihin", "qudsi"
    ///   2. word by word                 "Mufrad 24", "Masabih 24", "Maram 24", "Shah 24"
    ///   3. word prefixes, 3+ characters "tirmid 24", "muhammad 24"
    ///   4. one spelling slip, 4+ chars  "Tirmidi 24", "Bokhari 5", "Nasayi 100"
    static func book(named raw: String) -> HadithCatalogBook? {
        let queryWords = words(raw)
        guard !queryWords.isEmpty else { return nil }

        let joined = queryWords.joined()
        if let book = HadithCatalogBook.all.first(where: { keysBySlug[$0.slug]?.contains(joined) == true }) {
            return book
        }

        let named = HadithCatalogBook.all.filter { book in
            let known = wordsBySlug[book.slug] ?? []
            return queryWords.allSatisfy(known.contains)
        }
        if named.count == 1 { return named[0] }
        // Fits two books: refuse it rather than pick one, and don't fall through to the looser pass.
        if named.count > 1 { return nil }

        // Shorter stubs than three characters match half the shelf and would resolve by accident.
        let prefixed = HadithCatalogBook.all.filter { book in
            let known = wordsBySlug[book.slug] ?? []
            return queryWords.allSatisfy { word in
                word.count >= 3 && known.contains { $0.hasPrefix(word) }
            }
        }
        if prefixed.count == 1 { return prefixed[0] }
        if prefixed.count > 1 { return nil }

        // One spelling slip: "Tirmidi" reaches "tirmidhi", "Bokhari" reaches "bukhari". Unlike
        // the passes above, each word matches independently here - exact, prefix (3+), or one
        // edit (4+) - so "Abu Dawod" resolves even though "abu" is exact-only and "dawod" needs
        // the edit. Four+ characters for the edit so a short word can't teleport across the
        // shelf, and - like every pass above - a query that fits more than one book resolves
        // nothing.
        let fuzzy = HadithCatalogBook.all.filter { book in
            let known = wordsBySlug[book.slug] ?? []
            return queryWords.allSatisfy { word in
                known.contains(word)
                    || (word.count >= 3 && known.contains { $0.hasPrefix(word) })
                    || (word.count >= 4 && known.contains { withinOneEdit(word, $0) })
            }
        }
        return fuzzy.count == 1 ? fuzzy[0] : nil
    }

    /// Whether two words are within ONE edit - insertion, deletion, or substitution - of each
    /// other. A single pass with early exit; this runs per keystroke, over short alias words.
    private static func withinOneEdit(_ a: String, _ b: String) -> Bool {
        // Scalars, not bytes: an Arabic letter is two bytes, so one wrong letter read as two edits.
        // The Latin aliases are ASCII, where the two counts are the same.
        let a = Array(a.unicodeScalars), b = Array(b.unicodeScalars)
        if a.count == b.count {
            var edits = 0
            for i in 0..<a.count where a[i] != b[i] {
                edits += 1
                if edits > 1 { return false }
            }
            return true
        }
        // Lengths differ by one: the longer word must read as the shorter with one extra scalar.
        let (long, short) = a.count > b.count ? (a, b) : (b, a)
        guard long.count - short.count == 1 else { return false }
        var i = 0, j = 0, skipped = false
        while i < long.count && j < short.count {
            if long[i] == short[j] { i += 1; j += 1; continue }
            if skipped { return false }
            skipped = true
            i += 1
        }
        return true
    }

    struct Reference {
        let book: HadithCatalogBook
        /// 1-based chapter position in the book's chapter list, when the query was "book C:N".
        let chapter: Int?
        /// "book N" -> the hadith CITED N in the book (standard sunnah.com numbering, falling back
        /// to idInBook); "book C:N" -> the Nth hadith of chapter C.
        let hadith: Int
        /// The citation's variant letter when the query carried one: "muslim 8a" -> "a". Only
        /// meaningful without `chapter`.
        var suffix: String? = nil
        /// "muslim introduction 9": the hadith numbered 9 in the book's Introduction chapter.
        /// Sahih Muslim's muqaddimah carries its own numbering (1-92), which collides with Book
        /// 1's, and sunnah.com cites it as "Sahih Muslim Introduction 9". Only meaningful without
        /// `chapter`.
        var introduction: Bool = false
    }

    /// Compiled once: `parse` runs on the main thread per keystroke and several times per body pass,
    /// and it used to compile this same pattern twice per call (once via `range(of:)`, once here).
    // Five digits on BOTH numbers: every current book is < 10,000 hadiths, but a fuller collection
    // (Musnad Ahmad) would make "ahmad 12345" silently fall through to keyword search at {1,4}.
    // The name/number separator is whitespace OR punctuation, so "Qudsi 24", "Qudsi: 24", "Qudsi:24"
    // and "Qudsi-24" are all the same reference. The name is lazy, so a book whose own name carries a
    // hyphen ("Al-Adab Al-Mufrad 24") still backtracks to the separator before the NUMBER.
    // The optional trailing letter is a citation variant - "muslim 8a", also "muslim 8 a" - which
    // sunnah.com uses wherever one number covers several narrations, and runs to two letters on two
    // Sahih Muslim numbers ("muslim 1211aa"; the second letter only ever follows "a"). It cannot
    // combine with "C:N".
    private static let referenceRegex = try? NSRegularExpression(
        pattern: #"^(.+?)[\s:.\-\u060C]+(\d{1,5})(?:\s*(a[a-z]|[a-z]))?(?:\s*[:.\-]\s*(\d{1,5}))?$"#,
        options: [.caseInsensitive]
    )

    /// Parse "bukhari 5", "muslim 8a", or "muslim 3:12" (also "3.12" / "3-12"). Returns nil when the
    /// text before the numbers doesn't name exactly one collection.
    /// The looser shapes readers actually type, folded into "book N" before the grammar runs:
    /// a pasted sunnah.com link ("https://sunnah.com/muslim:8a", "sunnah.com/bukhari/1/2"),
    /// "sahih muslim hadith no. 2013", "muslim #2013", "muslim2013", "2013 muslim",
    /// "muslim book 3 hadith 12", and Arabic-Indic digits in any of them.
    // The looser shapes' patterns, compiled once: `canonical` runs on every hadith search keystroke
    // and used to compile four expressions per call.
    // The Arabic twins ride in the same patterns: "البخاري حديث رقم 15", "مسلم كتاب 3 حديث 12",
    // "البخاري15" and "15 البخاري" (the digits already Western by then, see `canonical`).
    private static let wordNoiseRegex = try? NSRegularExpression(pattern: #"\b(hadith|hadeeth|no|number|num|الحديث|حديث|رقم)\.?\s*"#, options: [.caseInsensitive])
    private static let bookNumberRegex = try? NSRegularExpression(pattern: #"\b(?:book|الكتاب|كتاب)\s+(\d{1,5})\s+(\d{1,5})\b"#, options: [.caseInsensitive])
    private static let gluedNumberRegex = try? NSRegularExpression(pattern: #"(?<=[A-Za-z'\u2019\u0621-\u064A])(?=\d)"#)
    private static let numberFirstRegex = try? NSRegularExpression(pattern: #"^\s*(\d{1,5}[a-z]?)\s+([A-Za-z\u0621-\u064A].*)$"#)

    private static func replacing(_ regex: NSRegularExpression?, in text: String, with template: String) -> String {
        guard let regex else { return text }
        return regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
    }

    /// Whether `text` could carry any of the looser shapes; a plain "bukhari 5" skips every regex.
    private static func needsCanonicalising(_ text: String) -> Bool {
        if let first = text.unicodeScalars.first, CharacterSet.decimalDigits.contains(first) { return true }
        var previousWasLetter = false
        for scalar in text.unicodeScalars {
            if scalar == "#" { return true }
            let isDigit = CharacterSet.decimalDigits.contains(scalar)
            if isDigit, previousWasLetter { return true }
            previousWasLetter = CharacterSet.letters.contains(scalar) || scalar == "'" || scalar == "\u{2019}"
        }
        let lowered = text.lowercased()
        return lowered.contains("hadith") || lowered.contains("hadeeth") || lowered.contains("book")
            || lowered.contains("num") || lowered.contains("no.") || lowered.contains(" no ") || lowered.hasSuffix(" no")
            || lowered.contains("حديث") || lowered.contains("كتاب") || lowered.contains("رقم")
    }

    static func canonical(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines).normalizingArabicIndicDigitsToWestern
        let lowered = text.lowercased()
        if let range = lowered.range(of: "sunnah.com/") {
            var tail = String(text[range.upperBound...])
            if let query = tail.firstIndex(where: { $0 == "?" || $0 == "#" }) { tail = String(tail[..<query]) }
            let parts = tail.split(whereSeparator: { $0 == "/" || $0 == ":" }).map(String.init)
            if parts.count >= 3 { return "\(parts[0]) \(parts[1]):\(parts[2])" }
            if parts.count == 2 { return "\(parts[0]) \(parts[1])" }
            return tail
        }
        guard needsCanonicalising(text) else {
            return text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        }
        text = text.replacingOccurrences(of: "#", with: " ")
        text = replacing(wordNoiseRegex, in: text, with: " ")
        text = replacing(bookNumberRegex, in: text, with: "$1:$2")
        // "muslim2013" -> "muslim 2013", and "2013 muslim" -> "muslim 2013".
        text = replacing(gluedNumberRegex, in: text, with: " ")
        if let regex = numberFirstRegex,
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let number = Range(match.range(at: 1), in: text), let rest = Range(match.range(at: 2), in: text) {
            text = String(text[rest]) + " " + String(text[number])
        }
        return text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    /// Inside a book its own name is optional, so "bukhari 1:4" typed in Sahih al-Bukhari reads as
    /// the bare "1:4" (and "bukhari 15" as "15"). A query naming ANOTHER book, or no book, comes back
    /// untouched. Only a query carrying both a letter and a digit can be a reference, so ordinary
    /// typing never reaches the regex.
    static func localQuery(_ raw: String, in book: HadithCatalogBook) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var hasLetter = false, hasDigit = false
        for scalar in trimmed.unicodeScalars {
            if CharacterSet.decimalDigits.contains(scalar) { hasDigit = true }
            else if CharacterSet.letters.contains(scalar) { hasLetter = true }
        }
        guard hasLetter, hasDigit, let reference = parse(trimmed), reference.book.slug == book.slug,
              !reference.introduction else { return trimmed }
        if let chapter = reference.chapter { return "\(chapter):\(reference.hadith)" }
        return "\(reference.hadith)\(reference.suffix ?? "")"
    }

    private static let introductionWords = ["introduction", "muqaddimah", "muqaddima", "intro"]

    static func parse(_ query: String) -> Reference? {
        let trimmed = canonical(query)
        guard let regex = referenceRegex,
              let result = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)) else { return nil }

        func group(_ index: Int) -> String? {
            guard let range = Range(result.range(at: index), in: trimmed) else { return nil }
            return String(trimmed[range])
        }

        guard var namePart = group(1), let firstNumber = group(2).flatMap({ Int($0) }) else { return nil }
        let suffix = group(3)?.lowercased()
        let secondNumber = group(4).flatMap { Int($0) }

        // "muslim introduction 9" (also "muqaddimah", "intro"): the word names the book's
        // Introduction chapter, not the book, so it comes off before the name is resolved.
        var introduction = false
        for word in introductionWords {
            if let range = namePart.range(of: word, options: [.caseInsensitive, .backwards]),
               range.upperBound == namePart.endIndex || namePart[range.upperBound].isWhitespace {
                namePart.removeSubrange(range)
                introduction = true
                break
            }
        }

        guard let book = book(named: namePart) else { return nil }

        // "muslim 8a:3" is not a reference in any numbering; refuse rather than guess.
        if let secondNumber {
            guard suffix == nil, !introduction else { return nil }
            return Reference(book: book, chapter: firstNumber, hadith: secondNumber)
        }
        return Reference(book: book, chapter: nil, hadith: firstNumber, suffix: suffix, introduction: introduction)
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
    /// A personal note, the bookmarked-ayah rule: notes live on bookmarks (optional so older data decodes).
    var note: String? = nil
    /// The standard citation at save time ("2950", "8a"), so the badge and reference render without
    /// loading the book. Optional: bookmarks saved before citations existed decode without it and
    /// are refreshed once by the store's citation migration.
    var citation: String? = nil
    /// When the bookmark was made (2026-09-07 on; older rows decode without it), for a bookmark
    /// anniversary one day (Tilawa Guide, Phase 9 step 8).
    var createdAt: Date? = nil

    var id: String { "\(slug)-\(idInBook)" }

    /// The number on the bookmark's badge: the standard citation, or the row number for the books
    /// (and old saves) that have none. Sahih Muslim's Introduction is qualified the way the row is.
    var displayNumber: String {
        guard let citation else { return String(idInBook) }
        return slug == "muslim" && chapterId == 0 ? "Introduction \(citation)" : citation
    }
}

/// The most recently read hadith - enough to render its row and jump back without loading the book.
struct HadithLastRead: Codable, Equatable {
    let slug: String
    let idInBook: Int
    let reference: String
    let arabicPreview: String
    let englishPreview: String
    let timestamp: Date
    /// The hadith's chapter, so "jump back" can land in the chapter scrolled to it without a scan.
    /// Optional: entries saved by older builds decode without it and resolve by idInBook instead.
    var chapterId: Int? = nil
}

#endif
