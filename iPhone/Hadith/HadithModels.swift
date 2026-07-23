import SwiftUI

// The Hadith catalog and data models: the 17 collections served by AhmedBaset/hadith-json, the
// hadith-json decoding shapes, reference parsing ("bukhari 5"), and the bookmark / last-read records.

#if os(iOS)

// MARK: - Catalog

extension String {
    /// Whether the text carries any Arabic-script characters - drives script-aware search (an Arabic
    /// query is only ever found in the Arabic field, a Latin one only in the English).
    var containsArabicScript: Bool {
        unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) || (0x0750...0x077F).contains($0.value) || (0x08A0...0x08FF).contains($0.value) }
    }

    /// Dataset hygiene, applied once at decode: the source JSONs carry hard-wrapped lines (a newline +
    /// leading spaces mid-sentence - Bukhari 1 is the poster child), doubled spaces, tabs, and no-break
    /// spaces. Deliberate paragraph breaks (blank lines) survive as one "\n\n"; every other run of
    /// whitespace collapses to a single space. The fast path skips strings that are already clean -
    /// which is most of the Arabic.
    var cleanedHadithText: String {
        guard contains("\n") || contains("  ") || contains("\t") || contains("\r") || contains("\u{00A0}") else {
            return self
        }
        var text = self
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
        // Blank-line breaks are real paragraphs: protect them, unwrap every remaining (hard-wrap)
        // newline into a space, then restore.
        text = text.replacingOccurrences(of: "[ ]*\\n[ ]*", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\n{2,}", with: "\u{2029}", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n", with: " ")
        text = text.replacingOccurrences(of: " {2,}", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: " ?\u{2029} ?", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

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


    /// 1-based position in the catalog ("1: Sahih al-Bukhari" ... "10: The Forty Hadith of Imam Nawawi"),
    /// the same numbered style the surah rows use. Memoized - `firstIndex(of:)` compared whole structs
    /// (long description strings included) on every badge render.
    private static let numberBySlug: [String: Int] = Dictionary(
        uniqueKeysWithValues: all.enumerated().map { ($0.element.slug, $0.offset + 1) }
    )

    var number: Int {
        Self.numberBySlug[slug] ?? 0
    }

    /// Chapter / hadith counts per book, measured from the actual CDN data (2026-07) - so the catalog
    /// shows a book's SHAPE ("97 C • 7,277 H", the surah rows' ayah-count language) before it is ever
    /// downloaded. Self-healing: `HadithStore` records the live counts whenever a book decodes, and the
    /// rows prefer those - a CDN update can never leave these numbers wrong for a downloaded book.
    private static let countsBySlug: [String: (chapters: Int, hadiths: Int)] = [
        "bukhari": (97, 7277), "muslim": (57, 7459), "ibnmajah": (38, 4345),
        "abudawud": (43, 5276), "tirmidhi": (49, 4053), "nasai": (52, 5768),
        "malik": (61, 1985), "ahmed": (8, 1374), "darimi": (24, 3406),
        "qudsi40": (1, 40), "nawawi40": (1, 42), "shahwaliullah40": (1, 40),
        "aladab_almufrad": (57, 1326), "shamail_muhammadiyah": (57, 402),
        "riyad_assalihin": (20, 1896), "mishkat_almasabih": (25, 4428), "bulugh_almaram": (16, 1767)
    ]

    var chapterCount: Int? { Self.countsBySlug[slug]?.chapters }
    var hadithCount: Int? { Self.countsBySlug[slug]?.hadiths }

    static let all: [HadithCatalogBook] = [
        // The Six Books (al-Kutub as-Sittah), in chronological order of their compilers.
        HadithCatalogBook(
            slug: "bukhari", folder: "the_9_books",
            englishTitle: "Sahih al-Bukhari", arabicTitle: "صَحِيح البُخارِي",
            group: .six, approximateMegabytes: 13,
            authorEnglish: "Imam Muhammad ibn Ismail al-Bukhari", authorArabic: "الإمام محمد بن إسماعيل البخاري",
            era: "d. 256 AH / 870 CE",
            shortDescription: "The most authentic book after the Quran, sifted from hundreds of thousands of narrations.",
            longDescription: "Its full title is al-Jami’ al-Musnad as-Sahih al-Mukhtasar min Umur Rasul Allah ﷺ wa Sunanihi wa Ayyamihi - “the abridged, authentically-chained collection of the affairs, practice, and times of the Messenger of Allah ﷺ.” Compiled over sixteen years by Imam al-Bukhari (الإمام البخاري), who sifted its 7,563 hadiths (about 2,600 without repetition) from hundreds of thousands he examined under the strictest standards of authenticity.\n\nMuslims across every generation have regarded it as the most authentic book after the Quran itself.",
            aliases: ["bukhari", "bukharee", "bukhary", "albukhari"]
        ),
        HadithCatalogBook(
            slug: "muslim", folder: "the_9_books",
            englishTitle: "Sahih Muslim", arabicTitle: "صَحِيح مُسلِم",
            group: .six, approximateMegabytes: 11.5,
            authorEnglish: "Imam Muslim ibn al-Hajjaj", authorArabic: "الإمام مسلم بن الحجاج",
            era: "d. 261 AH / 875 CE",
            shortDescription: "The second most authentic collection, every hadith gathered with its chains side by side.",
            longDescription: "Its full title is al-Musnad as-Sahih al-Mukhtasar bi-Naql al-‘Adl ‘an al-‘Adl ila Rasul Allah ﷺ. Compiled by Imam Muslim ibn al-Hajjaj of Naysabur (الإمام مسلم بن الحجاج النيسابوري), a student of Imam al-Bukhari.\n\nAlongside Sahih al-Bukhari it forms the Sahihayn, the two most authentic books of hadith - this the second of them. Scholars especially prize its arrangement: every narration of a hadith is gathered in one place with its chains compared side by side.",
            aliases: ["muslim", "sahihmuslim"]
        ),
        HadithCatalogBook(
            slug: "ibnmajah", folder: "the_9_books",
            englishTitle: "Sunan Ibn Majah", arabicTitle: "سُنَن ابن ماجَه",
            group: .six, approximateMegabytes: 5.7,
            authorEnglish: "Imam Muhammad ibn Yazid ibn Majah", authorArabic: "الإمام محمد بن يزيد بن ماجه",
            era: "d. 273 AH / 887 CE",
            shortDescription: "The sixth of the Six Books, preserving many hadiths found in none of the other five.",
            longDescription: "Its full title is Sunan Ibn Majah.\n\nCompiled by Imam Ibn Majah of Qazwin (الإمام ابن ماجه القزويني), it completes the famous Six Books (al-Kutub as-Sittah), and its particular value is the many hadiths - the zawa’id - it preserves that appear in none of the other five.",
            aliases: ["ibnmajah", "majah", "ibnmaja", "maja"]
        ),
        HadithCatalogBook(
            slug: "abudawud", folder: "the_9_books",
            englishTitle: "Sunan Abi Dawud", arabicTitle: "سُنَن أَبِي داوُد",
            group: .six, approximateMegabytes: 8,
            authorEnglish: "Imam Abu Dawud as-Sijistani", authorArabic: "الإمام أبو داود السجستاني",
            era: "d. 275 AH / 889 CE",
            shortDescription: "The Sunan of legal rulings, about 4,800 hadiths chosen from 500,000.",
            longDescription: "Its full title is Sunan Abi Dawud. Imam Abu Dawud (الإمام أبو داود) selected roughly 4,800 hadiths from the 500,000 he had collected - the Sunan of legal rulings, focused on the narrations jurists build upon.\n\nHe remarked that four hadiths of it suffice a person for their religion, among them “Actions are by intentions.”",
            aliases: ["abudawud", "abidawud", "abudaud", "abidaud", "dawud", "daud", "dawood", "abudawood"]
        ),
        HadithCatalogBook(
            slug: "tirmidhi", folder: "the_9_books",
            englishTitle: "Jami` at-Tirmidhi", arabicTitle: "جامِع التِرمِذِي",
            group: .six, approximateMegabytes: 7.7,
            authorEnglish: "Imam Muhammad ibn Isa at-Tirmidhi", authorArabic: "الإمام محمد بن عيسى الترمذي",
            era: "d. 279 AH / 892 CE",
            shortDescription: "The graded collection, noting each hadith's strength and the jurists' positions.",
            longDescription: "Its full title is al-Jami’ al-Kabir, known everywhere as Jami’ at-Tirmidhi. Compiled by Imam at-Tirmidhi (الإمام الترمذي), a student of Imam al-Bukhari.\n\nIts distinction is method: after most hadiths he states the grading (sahih, hasan, or otherwise) and which schools of law acted upon it - as much a manual of hadith science as a collection.",
            aliases: ["tirmidhi", "tirmizi", "tirmidhee", "attirmidhi", "altirmidhi"]
        ),
        HadithCatalogBook(
            slug: "nasai", folder: "the_9_books",
            englishTitle: "Sunan an-Nasa'i", arabicTitle: "سُنَن النَسائِي",
            group: .six, approximateMegabytes: 8,
            authorEnglish: "Imam Ahmad ibn Shu'ayb an-Nasa'i", authorArabic: "الإمام أحمد بن شعيب النسائي",
            era: "d. 303 AH / 915 CE",
            shortDescription: "The strictest of the four Sunan in its conditions for accepting narrators.",
            longDescription: "Its full title is al-Mujtaba, also called as-Sunan as-Sughra - Imam an-Nasa’i’s (الإمام النسائي) own refinement of his larger Sunan, keeping the narrations he judged strongest.\n\nHis conditions for accepting narrators were the most rigorous among the authors of the four Sunan.",
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
            longDescription: "Its full title is al-Muwatta - “the well-trodden path.” The Muwatta of Imam Malik (الإمام مالك), the Imam of Madinah, is the earliest collection in this library, compiled a full century before Bukhari and Muslim.\n\nIt weaves hadith together with the established practice of the people of Madinah. Imam ash-Shafi’i called it the soundest book of its time.",
            aliases: ["malik", "muwatta", "muwattamalik", "almuwatta"]
        ),
        HadithCatalogBook(
            slug: "ahmed", folder: "the_9_books",
            englishTitle: "Musnad Ahmad", arabicTitle: "مُسنَد أَحمَد",
            group: .early, approximateMegabytes: 2.4,
            authorEnglish: "Imam Ahmad ibn Hanbal", authorArabic: "الإمام أحمد بن حنبل",
            era: "d. 241 AH / 855 CE",
            shortDescription: "The great Musnad, arranged by the Companion who narrates each hadith.",
            longDescription: "Its full title is Musnad al-Imam Ahmad ibn Hanbal. The great Musnad of Imam Ahmad (الإمام أحمد بن حنبل), founder of the Hanbali school and the towering hadith scholar of his age.\n\nUnlike the Sunan books it is arranged by the narrating Companion rather than by topic; the full Musnad spans over 27,000 narrations, of which this dataset carries a selection.",
            aliases: ["ahmad", "ahmed", "musnadahmad", "musnadahmed"]
        ),
        HadithCatalogBook(
            slug: "darimi", folder: "the_9_books",
            englishTitle: "Sunan ad-Darimi", arabicTitle: "سُنَن الدارِمِي",
            group: .early, approximateMegabytes: 3,
            authorEnglish: "Imam Abdullah ibn Abd ar-Rahman ad-Darimi", authorArabic: "الإمام عبد الله بن عبد الرحمن الدارمي",
            era: "d. 255 AH / 869 CE",
            shortDescription: "The early Sunan of a teacher of Muslim, Abu Dawud, and at-Tirmidhi.",
            longDescription: "Its full title is Musnad ad-Darimi, widely known as Sunan ad-Darimi. Compiled by Imam ad-Darimi of Samarqand (الإمام الدارمي), a hadith master whose students included Imam Muslim, Abu Dawud, and at-Tirmidhi.\n\nHis Sunan opens with a celebrated introduction on the Prophet’s ﷺ status and the etiquette of knowledge.",
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
            longDescription: "Its full title is al-Arba’un an-Nawawiyyah. Imam an-Nawawi (الإمام النووي) gathered forty-two foundational hadiths - mostly from Bukhari and Muslim - each chosen because scholars described it as an axis the religion turns upon.\n\nMemorized across the Muslim world for over seven centuries, it is usually the first hadith book a student ever studies.",
            aliases: ["nawawi", "nawawi40", "arbaeen", "arbain", "arbaeennawawi", "fortynawawi"]
        ),
        HadithCatalogBook(
            slug: "shahwaliullah40", folder: "forties",
            englishTitle: "Forty Hadith of Shah Waliullah", arabicTitle: "أَربَعُون الشاه وَلِي الله",
            group: .forties, approximateMegabytes: 0.1,
            authorEnglish: "Shah Waliullah ad-Dihlawi", authorArabic: "شاه ولي الله الدهلوي",
            era: "d. 1176 AH / 1762 CE",
            shortDescription: "The forty concise hadiths with the shortest, most elevated chains.",
            longDescription: "Collected by Shah Waliullah of Delhi (شاه ولي الله الدهلوي), the reviver of hadith studies in the Indian subcontinent.\n\nHe chose forty concise hadiths distinguished by their short, elevated chains of transmission - comprehensive words gathered in the briefest form.",
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
            longDescription: "Its full title is al-Adab al-Mufrad - “the singular book of manners.”\n\nImam al-Bukhari’s (الإمام البخاري) dedicated book of Islamic manners: over 1,300 narrations on treating parents, neighbors, children, and guests; on speech, anger, mercy, and the everyday character the Prophet ﷺ taught - the gentler companion to his Sahih.",
            aliases: ["adab", "adabmufrad", "adabalmufrad", "aladabalmufrad"]
        ),
        HadithCatalogBook(
            slug: "shamail_muhammadiyah", folder: "other_books",
            englishTitle: "Shama'il Muhammadiyah", arabicTitle: "الشَمائِل المُحَمَّدِيَّة",
            group: .other, approximateMegabytes: 0.5,
            authorEnglish: "Imam Muhammad ibn Isa at-Tirmidhi", authorArabic: "الإمام محمد بن عيسى الترمذي",
            era: "d. 279 AH / 892 CE",
            shortDescription: "The portrait of the Prophet ﷺ, his appearance, habits, and character.",
            longDescription: "Its full title is ash-Shama’il al-Muhammadiyyah wa’l-Khasa’il al-Mustafawiyyah - “the noble qualities of Muhammad ﷺ and the characteristics of the Chosen One.”\n\nImam at-Tirmidhi’s (الإمام الترمذي) beloved portrait of the Prophet ﷺ: around 400 narrations describing his appearance, dress, food, sleep, worship, humility, and character - gathered so that those who never saw him ﷺ could almost see him.",
            aliases: ["shamail", "shamaail", "shamailmuhammadiyah"]
        ),
        HadithCatalogBook(
            slug: "riyad_assalihin", folder: "other_books",
            englishTitle: "Riyad as-Salihin", arabicTitle: "رِياض الصالِحِين",
            group: .other, approximateMegabytes: 2.2,
            authorEnglish: "Imam Yahya ibn Sharaf an-Nawawi", authorArabic: "الإمام يحيى بن شرف النووي",
            era: "d. 676 AH / 1277 CE",
            shortDescription: "The Gardens of the Righteous, the world's most-read book of the daily Sunnah.",
            longDescription: "Its full title is Riyad as-Salihin min Kalam Sayyid al-Mursalin - “Gardens of the Righteous, from the words of the Master of the Messengers.” By Imam an-Nawawi (الإمام النووي): around 1,900 hadiths on worship, character, and everyday conduct, arranged under verses of the Quran.\n\nPerhaps the most widely read hadith book in the world - a practical guide to living the Sunnah day by day.",
            aliases: ["riyad", "riyadh", "riyadassalihin", "riyadussalihin", "riyadsaliheen", "riyadhussaliheen", "salihin", "saliheen"]
        ),
        HadithCatalogBook(
            slug: "mishkat_almasabih", folder: "other_books",
            englishTitle: "Mishkat al-Masabih", arabicTitle: "مِشكاة المَصابِيح",
            group: .other, approximateMegabytes: 5.2,
            authorEnglish: "Imam al-Khatib at-Tabrizi", authorArabic: "الإمام الخطيب التبريزي",
            era: "d. c. 741 AH / 1340 CE",
            shortDescription: "The Niche of the Lamps, a comprehensive sourced survey of the whole Sunnah.",
            longDescription: "Its full title is Mishkat al-Masabih - “the niche of the lamps.”\n\nAl-Khatib at-Tabrizi (الخطيب التبريزي) expanded al-Baghawi’s Masabih as-Sunnah: he named each hadith’s source collection and added a third section to every chapter, producing one of the most comprehensive single surveys of the Sunnah ever assembled.",
            aliases: ["mishkat", "mishkaat", "mishkatalmasabih"]
        ),
        HadithCatalogBook(
            slug: "bulugh_almaram", folder: "other_books",
            englishTitle: "Bulugh al-Maram", arabicTitle: "بُلُوغ المَرام",
            group: .other, approximateMegabytes: 2.1,
            authorEnglish: "Imam Ibn Hajar al-Asqalani", authorArabic: "الإمام ابن حجر العسقلاني",
            era: "d. 852 AH / 1449 CE",
            shortDescription: "The evidences of Islamic law, the hadiths behind the legal rulings of fiqh.",
            longDescription: "Its full title is Bulugh al-Maram min Adillat al-Ahkam - “attainment of the objective from the evidences of the rulings.”\n\nBy Ibn Hajar al-Asqalani (ابن حجر العسقلاني), the commentator of Sahih al-Bukhari: around 1,580 hadiths that serve as the evidences for Islamic legal rulings, each with its source noted - studied wherever fiqh is taught.",
            aliases: ["bulugh", "buloogh", "bulughalmaram", "bulughmaram"]
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

    /// The dataset's ids are integers everywhere except Shama'il Muhammadiyah, which squeezes in a
    /// sub-chapter as the FLOAT id `8.2` (on the chapter AND its hadiths). Truncating it collided with
    /// chapter 8 and a strict Int decode took the whole book down - map fractional ids to a stable
    /// synthetic integer instead (8.2 -> 1082) so the sub-chapter keeps its own identity.
    static func normalizedChapterId(_ raw: Double) -> Int {
        raw == raw.rounded(.down) ? Int(raw) : 1000 + Int((raw * 10).rounded())
    }

    struct Chapter: Decodable, Identifiable, Hashable {
        let id: Int
        let arabic: String
        let english: String

        private enum CodingKeys: String, CodingKey {
            case id, arabic, english
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let whole = try? container.decode(Int.self, forKey: .id) {
                id = whole
            } else {
                id = HadithBookData.normalizedChapterId(try container.decode(Double.self, forKey: .id))
            }
            arabic = try container.decode(String.self, forKey: .arabic).cleanedHadithText
            english = try container.decode(String.self, forKey: .english).cleanedHadithText
        }
    }

    struct Hadith: Decodable, Identifiable {
        struct EnglishText: Decodable {
            let narrator: String
            let text: String

            init(narrator: String, text: String) {
                self.narrator = narrator
                self.text = text
            }

            private enum CodingKeys: String, CodingKey { case narrator, text }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                narrator = try container.decode(String.self, forKey: .narrator).cleanedHadithText
                text = try container.decode(String.self, forKey: .text).cleanedHadithText
            }
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
            // Shama'il Muhammadiyah's dataset carries hadiths with `chapterId: 8.2` - a FLOAT in a
            // field that is an integer everywhere else. Same synthetic mapping as Chapter.id, so these
            // hadiths stay linked to their own sub-chapter.
            if let whole = try? container.decode(Int.self, forKey: .chapterId) {
                chapterId = whole
            } else {
                chapterId = HadithBookData.normalizedChapterId(try container.decode(Double.self, forKey: .chapterId))
            }
            arabic = try container.decode(String.self, forKey: .arabic).cleanedHadithText
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

    /// Compiled once: `parse` runs on the main thread per keystroke and several times per body pass,
    /// and it used to compile this same pattern twice per call (once via `range(of:)`, once here).
    // Five digits on BOTH numbers: every current book is < 10,000 hadiths, but a fuller collection
    // (Musnad Ahmad) would make "ahmad 12345" silently fall through to keyword search at {1,4}.
    private static let referenceRegex = try? NSRegularExpression(
        pattern: #"^(.+?)\s+(\d{1,5})(?:\s*[:.\-]\s*(\d{1,5}))?$"#
    )

    /// Parse "bukhari 5" or "muslim 3:12" (also "3.12" / "3-12"). Returns nil when the text before the
    /// numbers doesn't resolve to a known book alias.
    static func parse(_ query: String) -> Reference? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let regex = referenceRegex,
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
    /// The hadith's chapter, so "jump back" can land in the chapter scrolled to it without a scan.
    /// Optional: entries saved by older builds decode without it and resolve by idInBook instead.
    var chapterId: Int? = nil
}

#endif
