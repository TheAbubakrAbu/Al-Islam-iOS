import SwiftUI

// Per-imam and per-narrator pages for the Qiraat guide: tapping any of the ten readings or any of the
// twenty riwayat in `QiraatView` opens the biography here.
//
// SOURCING. The facts below - lineage, cities, teachers, death years, what each reading is known for -
// are the standard biographical record of the qurra, and they are kept CONSISTENT WITH THE NUMBERS THE
// APP ALREADY SHIPS in `Settings.Riwayah` (`teacherDiedAH`, `narratorDiedAH`) so the guide and the
// pickers can never disagree. QiraatHub is credited as the further-reading companion for these pages
// and every profile links to it; the prose itself is written for this app rather than copied, so
// nothing here reproduces another site's text.

struct QiraahMasterProfile: Identifiable, Hashable {
    /// Matches `Settings.Riwayah.*Teacher`, so a profile can be found from a riwayah tag.
    let id: String
    let arabic: String
    /// The full classical name, as a biography would give it.
    let fullName: String
    let city: String
    let bornAH: Int?
    let diedAH: Int
    let diedCE: Int
    /// One-line description used as the row subtitle in the list.
    let summary: String
    /// The body of the page, one paragraph per entry.
    let paragraphs: [String]
    /// What this reading is particularly known for.
    let hallmarks: [String]
    /// The Companions the reading is transmitted from, as the guide's chain section words it.
    let companions: String
    /// The two narrator ids (`Settings.Riwayah` tags) whose profiles this page links to.
    let narratorTags: [String]

    var lifespan: String {
        guard let bornAH else { return "d. \(diedAH) AH (\(diedCE) CE)" }
        return "\(bornAH)–\(diedAH) AH (d. \(diedCE) CE)"
    }
}

struct RiwayahNarratorProfile: Identifiable, Hashable {
    /// The `Settings.Riwayah` tag ("" for Hafs), so a picker row maps straight to a profile.
    let id: String
    let name: String
    let arabic: String
    let fullName: String
    let masterID: String
    let city: String
    let bornAH: Int?
    let diedAH: Int
    let summary: String
    let paragraphs: [String]
    let hallmarks: [String]

    var lifespan: String {
        guard let bornAH else { return "d. \(diedAH) AH" }
        return "\(bornAH)–\(diedAH) AH"
    }
}

enum QiraatProfiles {
    static let sourceURL = URL(string: "https://qiraathub.com/")!

    static func master(id: String) -> QiraahMasterProfile? {
        masters.first { $0.id == id }
    }

    static func narrator(tag: String) -> RiwayahNarratorProfile? {
        narrators.first { $0.id == tag }
    }

    static func narrators(ofMaster id: String) -> [RiwayahNarratorProfile] {
        narrators.filter { $0.masterID == id }
    }

    // MARK: - Narrations that share one transmitted text

    /// Riwayat whose texts match because the transmission does not separate them.
    ///
    /// Ishaq and Idris are the two narrators of Khalaf al-Ashir, and via al-Durrah al-Mutammimah
    /// nothing is transmitted differently between them: not in the usul, and no difference in the
    /// farsh is reported either. The electronic mushaf the app's Arabic comes from prints one body
    /// text under both names, and every other narrator pair in that same series does differ (58
    /// ayahs at the closest, Ibn Wardan against Ibn Jammaz), so an exact match here is a statement
    /// about the transmission rather than a shortcut taken by the publisher.
    ///
    /// Where the two narrations DO part company is Tayyibat al-Nashr, the greater ten, in which Ibn
    /// al-Jazari gives Idris two turuq. The app follows the Durrah path, so that divergence is out
    /// of scope for the text it shows.
    static let sharedTextRiwayat: Set<String> = [Settings.Riwayah.ishaq, Settings.Riwayah.idris]

    /// True when two riwayat carry one transmitted text, so a reader comparing them can be told why
    /// they match instead of being left to read it as a defect in the app.
    static func shareOneText(_ a: String, _ b: String) -> Bool {
        let (x, y) = (Settings.Riwayah.canonicalTag(a), Settings.Riwayah.canonicalTag(b))
        return x != y && sharedTextRiwayat.contains(x) && sharedTextRiwayat.contains(y)
    }

    /// The riwayah `tag` shares its text with, when it shares with one.
    static func sharedTextPartner(of tag: String) -> String? {
        let canonical = Settings.Riwayah.canonicalTag(tag)
        guard sharedTextRiwayat.contains(canonical) else { return nil }
        return sharedTextRiwayat.first { $0 != canonical }
    }

    /// The narrator's short name for a riwayah tag ("Idris"), for captions that name the other side.
    static func shortName(of tag: String) -> String {
        narrator(tag: Settings.Riwayah.canonicalTag(tag))?.name ?? tag
    }

    /// The explanation itself, shared by the profile pages and the comparison sheet so the reader
    /// meets one account of this rather than two that drift apart.
    static let sharedTextExplanation = "Ishaq and Idris are the two narrators of Khalaf al-Ashir, and via al-Durrah al-Mutammimah nothing is transmitted differently between them: they agree in the usul, and no difference in the farsh is reported either. The mushaf this app's Arabic is taken from prints one body text under both narrators' names, so the two read alike in every ayah. The places where the two narrations do part company belong to Tayyibat al-Nashr, the greater ten, in which Ibn al-Jazari gives Idris two turuq."

    /// The one-line form, for a footer under a list that already names the two.
    static let sharedTextShortNote = "Nothing is transmitted differently between these two narrators via al-Durrah, so they carry one text. Open either for the detail."

    // MARK: - The ten imams, in the guide's own alphabetical order

    static let masters: [QiraahMasterProfile] = [
        QiraahMasterProfile(
            id: Settings.Riwayah.abiJafarTeacher,
            arabic: Settings.Riwayah.abiJafarTeacherArabic,
            fullName: "Abu Ja'far Yazid ibn al-Qa'qa' al-Makhzumi al-Madani",
            city: "Madinah", bornAH: nil, diedAH: 130, diedCE: 748,
            summary: "The senior Madinan reader, and Nafi's own teacher.",
            paragraphs: [
                "Abu Ja'far was among the senior Successors (tabi'in) of Madinah and the earliest of the ten imams to die. He learned from Companions of the Prophet (peace and blessings be upon him) directly, and taught in the Prophet's Mosque for decades.",
                "He is the teacher of Nafi al-Madani, which places him a generation above most of the ten: the Madinan reading that later spread through Qalun and Warsh was shaped by what Abu Ja'far taught. His own reading was added to the canonical ten by Ibn al-Jazari alongside Ya'qub and Khalaf.",
                "He was known for his piety as much as his recitation, and the reports about him dwell on how carefully he held to what he had been taught rather than on any innovation of his own.",
            ],
            hallmarks: [
                "The oldest of the ten readings by generation.",
                "Distinctive treatment of the hamzah and of the letters at the openings of surahs.",
            ],
            companions: "Transmitted from Zayd ibn Thabit, Ubayy ibn Ka'b, Abdullah ibn Abbas, Abdullah ibn Ayyash, and Abu Hurayrah (may Allah be pleased with them).",
            narratorTags: [Settings.Riwayah.ibnWardan, Settings.Riwayah.ibnJammaz]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.abiAmrTeacher,
            arabic: Settings.Riwayah.abiAmrTeacherArabic,
            fullName: "Abu Amr Zabban ibn al-Ala' ibn Ammar al-Mazini al-Basri",
            city: "Basra", bornAH: 68, diedAH: 154, diedCE: 770,
            summary: "Imam of Basra, and one of the founders of Arabic grammar.",
            paragraphs: [
                "Abu Amr was born in Makkah and settled in Basra, where he became both the imam of recitation and one of the founding figures of the Basran school of Arabic grammar. That double authority is why his reading is so often cited in discussions of Arabic usage as well as of recitation.",
                "He was famous for the breadth of his study: he is reported to have said that what he memorised would fill a house, and he travelled widely to read on the Successors. His students Yahya al-Yazidi and then ad-Duri and as-Susi carried the reading forward.",
                "Both of his canonical narrators read on al-Yazidi rather than on Abu Amr himself, so the riwayat of ad-Duri and as-Susi meet one generation below the imam.",
            ],
            hallmarks: [
                "Extensive idgham (assimilation), including the large idgham between words.",
                "A generally light, easing treatment of the hamzah.",
            ],
            companions: "Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas'ud, Abu Musa al-Ash'ari, Abdullah ibn Abbas, Ubayy ibn Ka'b, Zayd ibn Thabit, and Abu Hurayrah (may Allah be pleased with them).",
            narratorTags: [Settings.Riwayah.duri, Settings.Riwayah.susi]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.kisaiTeacher,
            arabic: Settings.Riwayah.kisaiTeacherArabic,
            fullName: "Abu al-Hasan Ali ibn Hamzah al-Kisai",
            city: "Kufa", bornAH: nil, diedAH: 189, diedCE: 805,
            summary: "The last of the seven, and head of the Kufan school of grammar.",
            paragraphs: [
                "Al-Kisai took his name from the cloak (kisa') he was wearing when he entered ihram. He read on Hamzah az-Zayyat and on others, and after Hamzah's death he became the imam of recitation in Kufa.",
                "He led the Kufan school of Arabic grammar and was appointed tutor to the sons of the Abbasid caliph, which carried his reading into the centre of scholarly life in Baghdad. His well-known grammatical debate with Sibawayh, the great Basran, marks the high point of the rivalry between the two schools.",
                "He is the seventh and last of the imams gathered by Ibn Mujahid into the famous seven.",
            ],
            hallmarks: [
                "Frequent imalah (tilting the fatha towards a kasra).",
                "Distinctive pausing conventions on the feminine ta.",
            ],
            companions: "Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka'b, Zayd ibn Thabit, Abdullah ibn Mas'ud, Abdullah ibn Abbas, Abu Hurayrah, and Husayn ibn Ali (may Allah be pleased with them).",
            narratorTags: [Settings.Riwayah.abuHarith, Settings.Riwayah.duriKisai]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.asimTeacher,
            arabic: Settings.Riwayah.asimTeacherArabic,
            fullName: "Abu Bakr Asim ibn Abi an-Najud Bahdalah al-Asadi",
            city: "Kufa", bornAH: nil, diedAH: 127, diedCE: 745,
            summary: "The reading almost the whole Muslim world recites today, through Hafs.",
            paragraphs: [
                "Asim was a Successor (tabi'i) of Kufa who learned from Abu Abd ar-Rahman as-Sulami, who in turn read on Uthman, Ali, Ibn Mas'ud, Ubayy ibn Ka'b and Zayd ibn Thabit (may Allah be pleased with them). His chain to the Prophet (peace and blessings be upon him) is therefore short and famously well attested.",
                "He was described as the most beautiful reciter of his time, and as exacting to the point that he would not pass a student on until the recitation was exactly as he had received it.",
                "His two narrators went in different directions: Shu'bah preserved what he took with great caution, while Hafs transmitted the reading that would eventually become the standard printed mushaf across most of the world.",
            ],
            hallmarks: [
                "The basis of the Madinah mushaf and of most printed Qurans today (through Hafs).",
                "Clear pronunciation of the hamzah, with relatively little assimilation.",
            ],
            companions: "Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas'ud, Zayd ibn Thabit, and Ubayy ibn Ka'b (may Allah be pleased with them).",
            narratorTags: [Settings.Riwayah.hafsTag, Settings.Riwayah.shubah]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.hamzahTeacher,
            arabic: Settings.Riwayah.hamzahTeacherArabic,
            fullName: "Abu Imarah Hamzah ibn Habib az-Zayyat at-Taymi",
            city: "Kufa", bornAH: 80, diedAH: 156, diedCE: 773,
            summary: "Known for the longest madd and for his pauses on the hamzah.",
            paragraphs: [
                "Hamzah was called az-Zayyat because he traded in oil between Kufa and Hulwan. He became the imam of recitation in Kufa after Asim, and his reading is among the most distinctive of the ten.",
                "He was known for long night prayer and for an exacting devotion to tajwid. His reading asks more of the reciter than most: the elongations are the longest of the ten, and the treatment of the hamzah when pausing is a subject studied on its own.",
                "His student Khalaf later made his own selection from Hamzah's reading and became the tenth imam in his own right - which is why Khalaf appears twice in the guide, once as a narrator and once as a master.",
            ],
            hallmarks: [
                "The longest madd (elongation) of the ten readings.",
                "Extensive sakt (brief pause) and a distinctive easing of the hamzah at a stop.",
                "Frequent imalah.",
            ],
            companions: "Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka'b, Zayd ibn Thabit, Abdullah ibn Mas'ud, and Husayn ibn Ali (may Allah be pleased with them).",
            narratorTags: [Settings.Riwayah.khalaf, Settings.Riwayah.khallad]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.ibnAmirTeacher,
            arabic: Settings.Riwayah.ibnAmirTeacherArabic,
            fullName: "Abu Imran Abdullah ibn Amir al-Yahsubi",
            city: "Damascus", bornAH: 21, diedAH: 118, diedCE: 736,
            summary: "The Damascene reading, and the earliest-born of the ten.",
            paragraphs: [
                "Ibn Amir was born in the lifetime of the Companions and is counted among the Successors. He served as judge of Damascus and as imam of its great Umayyad Mosque, and he led recitation there through the whole of the early Umayyad period.",
                "He learned from Abu ad-Darda and from al-Mughirah ibn Abi Shihab al-Makhzumi, who read on Uthman ibn Affan (may Allah be pleased with them). His is the reading of Sham, and it remained the recitation of Damascus for centuries.",
                "Both of his canonical narrators, Hisham and Ibn Dhakwan, came generations later and received the reading through intermediate teachers.",
            ],
            hallmarks: [
                "Distinctive word-forms in several places where the Syrian mushaf's rasm differs.",
                "A characteristic treatment of the two consecutive hamzahs.",
            ],
            companions: "Transmitted from Uthman ibn Affan and Abu ad-Darda (may Allah be pleased with them).",
            narratorTags: [Settings.Riwayah.hisham, Settings.Riwayah.ibnDhakwan]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.ibnKathirTeacher,
            arabic: Settings.Riwayah.ibnKathirTeacherArabic,
            fullName: "Abu Ma'bad Abdullah ibn Kathir ad-Dari al-Makki",
            city: "Makkah", bornAH: 45, diedAH: 120, diedCE: 738,
            summary: "Imam of recitation in Makkah, and a Successor who met Companions.",
            paragraphs: [
                "Ibn Kathir al-Makki was born in Makkah and lived his whole life there. He was a Successor who met a number of Companions, among them Abdullah ibn az-Zubayr, Anas ibn Malik and Abu Ayyub al-Ansari (may Allah be pleased with them).",
                "He was the undisputed imam of recitation in Makkah in his generation, and people travelled to read on him. He is not to be confused with the much later Ibn Kathir the mufassir, who is a different scholar entirely.",
                "Neither al-Bazzi nor Qunbul met him: both received the Makkan reading through intermediate teachers, which is the usual pattern for the earlier imams of the ten.",
            ],
            hallmarks: [
                "Generous madd on the connecting vowels.",
                "A distinctive doubling in certain words, transmitted through al-Bazzi.",
            ],
            companions: "Transmitted from Umar ibn al-Khattab, Zayd ibn Thabit, Ubayy ibn Ka'b, Abdullah ibn Abbas, and Abdullah ibn as-Sa'ib (may Allah be pleased with them).",
            narratorTags: [Settings.Riwayah.buzzi, Settings.Riwayah.qunbul]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.khalafAshirTeacher,
            arabic: Settings.Riwayah.khalafAshirTeacherArabic,
            fullName: "Abu Muhammad Khalaf ibn Hisham al-Bazzar al-Baghdadi",
            city: "Baghdad", bornAH: 150, diedAH: 229, diedCE: 844,
            summary: "A narrator of Hamzah who became the tenth imam in his own right.",
            paragraphs: [
                "Khalaf memorised the Quran as a boy and read on Sulaym, the student of Hamzah, becoming one of Hamzah's two canonical narrators. He then made his own considered selection (ikhtiyar) from the readings he had received, and that selection is the tenth of the ten Qiraat.",
                "This is why his name appears twice in the guide: Khalaf an Hamzah is a riwayah of the sixth reading, while Khalaf al-Ashir - Khalaf the Tenth - is a reading of its own, with its own two narrators, Ishaq and Idris.",
                "He was a scholar of Baghdad known for his precision and his asceticism, and his selection was recognised as canonical because it met the same three conditions as the rest: the Uthmanic rasm, sound Arabic, and authentic mass transmission.",
            ],
            hallmarks: [
                "A considered selection (ikhtiyar) drawn mostly from the Kufan readings.",
                "Close to Hamzah in many places, but with its own settled choices.",
            ],
            companions: "Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas'ud, Zayd ibn Thabit, Ubayy ibn Ka'b, and Husayn ibn Ali (may Allah be pleased with them).",
            narratorTags: [Settings.Riwayah.ishaq, Settings.Riwayah.idris]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.nafiTeacher,
            arabic: Settings.Riwayah.nafiTeacherArabic,
            fullName: "Abu Ruwaym Nafi ibn Abd ar-Rahman ibn Abi Nu'aym al-Laythi",
            city: "Madinah", bornAH: nil, diedAH: 169, diedCE: 785,
            summary: "Imam of Madinah for seventy years; the reading of North and West Africa.",
            paragraphs: [
                "Nafi was of Isfahani descent and lived in Madinah, where he led recitation in the Prophet's Mosque for some seventy years. He is reported to have read on around seventy of the Successors, Abu Ja'far al-Madani among them.",
                "He was asked which of his teachers he followed and answered that he took what at least two of them agreed upon - a method that gives his reading its particular authority, since it represents the settled practice of Madinah rather than one chain.",
                "Through Warsh his reading became the recitation of North and West Africa, where it remains dominant; through Qalun it is the reading of Libya and parts of Tunisia.",
            ],
            hallmarks: [
                "The most widely recited reading after Hafs, especially across Africa.",
                "Warsh and Qalun differ from each other more than most narrator pairs.",
            ],
            companions: "Transmitted from Umar ibn al-Khattab, Zayd ibn Thabit, Ubayy ibn Ka'b, Abdullah ibn Abbas, Abdullah ibn Ayyash, and Abu Hurayrah (may Allah be pleased with them).",
            narratorTags: [Settings.Riwayah.warsh, Settings.Riwayah.qaloon]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.yaqubTeacher,
            arabic: Settings.Riwayah.yaqubTeacherArabic,
            fullName: "Abu Muhammad Ya'qub ibn Ishaq ibn Zayd al-Hadrami",
            city: "Basra", bornAH: 117, diedAH: 205, diedCE: 821,
            summary: "Imam of Basra after Abu Amr, and the ninth of the ten.",
            paragraphs: [
                "Ya'qub al-Hadrami succeeded to the leadership of recitation in Basra after Abu Amr's circle, and held it for the rest of his life. He was known for his command of Arabic dialects and of the variant readings, and was consulted on both.",
                "His reading was added to the canonical seven, with Abu Ja'far and Khalaf, to make the ten recognised by Ibn al-Jazari. It remained in practical use in parts of the Muslim world long after, and is still taught today.",
                "His two narrators, Ruways and Rawh, were both Basrans who read directly on him.",
            ],
            hallmarks: [
                "A distinctive treatment of the connecting pronouns (ha' al-kinayah).",
                "Several word-forms that make the reading immediately recognisable.",
            ],
            companions: "Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka'b, Zayd ibn Thabit, Abdullah ibn Mas'ud, Abu Musa al-Ash'ari, Abdullah ibn Abbas, and Abu Hurayrah (may Allah be pleased with them).",
            narratorTags: [Settings.Riwayah.ruways, Settings.Riwayah.rawh]
        ),
    ]

    // MARK: - The twenty narrators

    static let narrators: [RiwayahNarratorProfile] = [
        // Asim
        RiwayahNarratorProfile(
            id: Settings.Riwayah.hafsTag, name: "Hafs", arabic: "حَفص",
            fullName: "Abu Amr Hafs ibn Sulayman al-Asadi al-Kufi",
            masterID: Settings.Riwayah.asimTeacher, city: "Kufa", bornAH: 90, diedAH: 180,
            summary: "The narration almost the entire Muslim world recites from today.",
            paragraphs: [
                "Hafs was the stepson of Asim and read on him over many years. Of the two narrators of Asim, Hafs is the one described as the more precise in conveying exactly what Asim taught.",
                "His narration became the basis of the Ottoman printed mushaf and then of the Madinah mushaf, and through printing it spread until it became the recitation of the overwhelming majority of Muslims - commonly estimated at more than nine in ten.",
                "That dominance is a fact of history and printing, not of rank: every one of the twenty riwayat is equally the Quran.",
            ],
            hallmarks: [
                "The default reading of this app and of most printed Qurans.",
                "Almost no imalah, and a single well-known instance of the weak-letter pronunciation in Surah Fussilat.",
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.shubah, name: "Shu'bah", arabic: "شُعبَة",
            fullName: "Abu Bakr Shu'bah ibn Ayyash ibn Salim al-Kufi",
            masterID: Settings.Riwayah.asimTeacher, city: "Kufa", bornAH: 95, diedAH: 193,
            summary: "Asim's other narrator, famed for caution and for long worship.",
            paragraphs: [
                "Shu'bah read the Quran on Asim three times over and was one of the great worshippers of his age; the reports say he completed the Quran in prayer regularly for decades.",
                "He was so cautious about transmitting that he is said to have wished he had never narrated at all rather than risk a single error - a scrupulousness that is itself part of why his narration is trusted.",
                "His riwayah differs from Hafs in a few hundred places, most of them small differences of vowel or of assimilation.",
            ],
            hallmarks: [
                "Differs from Hafs in roughly five hundred points across the Quran.",
                "Distinctive readings in the disconnected letters opening some surahs.",
            ]
        ),
        // Nafi
        RiwayahNarratorProfile(
            id: Settings.Riwayah.warsh, name: "Warsh", arabic: "وَرش",
            fullName: "Abu Sa'id Uthman ibn Sa'id al-Misri",
            masterID: Settings.Riwayah.nafiTeacher, city: "Egypt", bornAH: 110, diedAH: 197,
            summary: "The reading of North and West Africa, and the app's Maghribi script.",
            paragraphs: [
                "Warsh was Egyptian, and travelled to Madinah to read the whole Quran on Nafi several times over before returning to Egypt to teach. Nafi gave him the nickname Warsh, said to be after a kind of white curd, for his fair complexion.",
                "He became the imam of recitation in Egypt, and from there his narration spread west across North Africa, where it is still the dominant recitation and the one the printed Maghribi mushafs are set in.",
                "It is the most different from Hafs of the widely-recited narrations, and the one most likely to surprise a reader who has only ever heard Hafs.",
            ],
            hallmarks: [
                "Extensive taqlil and imalah (tilting the long a towards e).",
                "Longer madd than Hafs in several categories, and a distinctive treatment of the hamzah.",
                "The narration whose printed mushaf uses the Maghribi script.",
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.qaloon, name: "Qalun", arabic: "قَالُون",
            fullName: "Abu Musa Isa ibn Mina al-Zarqi al-Madani",
            masterID: Settings.Riwayah.nafiTeacher, city: "Madinah", bornAH: 120, diedAH: 220,
            summary: "Nafi's closest Madinan student; the reading of Libya.",
            paragraphs: [
                "Qalun was Nafi's stepson and read on him for some twenty years. The name Qalun was given to him by Nafi himself and is said to be a Byzantine word for 'good', a comment on the quality of his recitation.",
                "He is reported to have gone deaf in later life and yet to have continued correcting students by watching their lips - a story the biographers tell to convey how completely he had internalised the reading.",
                "His narration is the recitation of Libya and of parts of Tunisia today.",
            ],
            hallmarks: [
                "Shorter madd than Warsh, and a lighter touch overall.",
                "The two narrators of Nafi differ from each other in several hundred places.",
            ]
        ),
        // Ibn Kathir
        RiwayahNarratorProfile(
            id: Settings.Riwayah.buzzi, name: "al-Bazzi", arabic: "البَزِّي",
            fullName: "Abu al-Hasan Ahmad ibn Muhammad ibn Abd Allah al-Bazzi",
            masterID: Settings.Riwayah.ibnKathirTeacher, city: "Makkah", bornAH: 170, diedAH: 250,
            summary: "Muezzin of the Sacred Mosque and imam of recitation in Makkah.",
            paragraphs: [
                "Al-Bazzi was the muezzin of the Sacred Mosque in Makkah for around forty years and the leading teacher of the Makkan reading in his generation. He received Ibn Kathir's reading through intermediate teachers, Ibn Kathir having died half a century before his birth.",
                "His narration carries a well-known feature: the doubling of the ta in a set of verbs, which is particular to him among the narrators of Ibn Kathir.",
            ],
            hallmarks: [
                "The doubled ta in a defined set of words.",
                "The takbir between the surahs at the end of the Quran is transmitted through him.",
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.qunbul, name: "Qunbul", arabic: "قُنبُل",
            fullName: "Abu Amr Muhammad ibn Abd ar-Rahman al-Makhzumi al-Makki",
            masterID: Settings.Riwayah.ibnKathirTeacher, city: "Makkah", bornAH: 195, diedAH: 291,
            summary: "The other Makkan narrator, who taught into his nineties.",
            paragraphs: [
                "Qunbul read on al-Qawwas, and through him on the chain back to Ibn Kathir. He led recitation in Makkah for many years and students travelled to him from across the Muslim world.",
                "He lived to a great age and continued teaching almost to the end, which is part of why his narration is so widely attested.",
            ],
            hallmarks: [
                "Differs from al-Bazzi in a modest number of places.",
                "A distinctive reading of the hamzah in several words.",
            ]
        ),
        // Abu Amr
        RiwayahNarratorProfile(
            id: Settings.Riwayah.duri, name: "ad-Duri", arabic: "الدُّورِي",
            fullName: "Abu Umar Hafs ibn Umar ad-Duri al-Baghdadi",
            masterID: Settings.Riwayah.abiAmrTeacher, city: "Baghdad", bornAH: nil, diedAH: 246,
            summary: "The only man who narrates two of the ten readings.",
            paragraphs: [
                "Ad-Duri took his name from ad-Dur, a district of Baghdad. He is the only narrator among the twenty who transmits two of the ten readings: Abu Amr's, through al-Yazidi, and al-Kisai's, on whom he read directly.",
                "He is also credited with being among the first to gather the variant readings systematically and travel in search of them, which makes him a foundational figure for the science itself and not only a link in one chain.",
                "His narration of Abu Amr is widely recited in parts of Sudan and the Horn of Africa.",
            ],
            hallmarks: [
                "Appears twice in the twenty riwayat, once under Abu Amr and once under al-Kisai.",
                "Carries Abu Amr's extensive assimilation between words.",
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.susi, name: "as-Susi", arabic: "السُّوسِي",
            fullName: "Abu Shu'ayb Salih ibn Ziyad as-Susi",
            masterID: Settings.Riwayah.abiAmrTeacher, city: "Basra", bornAH: nil, diedAH: 261,
            summary: "Abu Amr's other narrator, through al-Yazidi.",
            paragraphs: [
                "As-Susi read on Yahya al-Yazidi, Abu Amr's foremost student, and transmitted the Basran reading alongside ad-Duri.",
                "His narration takes Abu Amr's assimilation furthest: the large idgham, where a final letter merges into the first letter of the next word, is applied more consistently in as-Susi than anywhere else among the twenty.",
            ],
            hallmarks: [
                "The fullest application of the large idgham (idgham kabir).",
                "A markedly flowing, connected sound as a result.",
            ]
        ),
        // Ibn Amir
        RiwayahNarratorProfile(
            id: Settings.Riwayah.hisham, name: "Hisham", arabic: "هِشَام",
            fullName: "Abu al-Walid Hisham ibn Ammar ad-Dimashqi",
            masterID: Settings.Riwayah.ibnAmirTeacher, city: "Damascus", bornAH: 153, diedAH: 245,
            summary: "Preacher, judge and imam of the Umayyad Mosque in Damascus.",
            paragraphs: [
                "Hisham ibn Ammar was the khatib of Damascus and later its judge, as well as a hadith scholar of standing. He received the Damascene reading through the chain from Ibn Amir and taught it in the Umayyad Mosque.",
                "He and Ibn Dhakwan are the two narrators through whom the reading of Sham survived, at a distance of roughly a century from the imam himself.",
            ],
            hallmarks: [
                "Distinctive handling of the two consecutive hamzahs.",
                "Several readings unique to him within the Syrian tradition.",
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.ibnDhakwan, name: "Ibn Dhakwan", arabic: "ابنُ ذَكوَان",
            fullName: "Abu Amr Abdullah ibn Ahmad ibn Bashir ibn Dhakwan",
            masterID: Settings.Riwayah.ibnAmirTeacher, city: "Damascus", bornAH: 173, diedAH: 242,
            summary: "Imam and teacher of recitation in Damascus.",
            paragraphs: [
                "Ibn Dhakwan led the recitation in the Umayyad Mosque and was the leading teacher of the Syrian reading in his generation, alongside Hisham.",
                "The two narrators of Ibn Amir differ from one another in a number of places, so the Damascene reading is normally studied as the pair rather than as one.",
            ],
            hallmarks: [
                "Differs from Hisham in a modest but well-catalogued set of places.",
                "A characteristic imalah in particular words.",
            ]
        ),
        // Hamzah
        RiwayahNarratorProfile(
            id: Settings.Riwayah.khalaf, name: "Khalaf", arabic: "خَلَف",
            fullName: "Abu Muhammad Khalaf ibn Hisham al-Bazzar al-Baghdadi",
            masterID: Settings.Riwayah.hamzahTeacher, city: "Baghdad", bornAH: 150, diedAH: 229,
            summary: "Narrator of Hamzah - and the tenth imam under his own name.",
            paragraphs: [
                "Khalaf read on Sulaym, Hamzah's student, and is one of Hamzah's two canonical narrators. He is the same Khalaf who later made his own selection and became the tenth of the ten imams, which is why the guide lists him in both places.",
                "Read as a narrator of Hamzah, he transmits Hamzah's reading with its long madd and its distinctive pauses; read as Khalaf al-Ashir, he is following his own considered choices.",
            ],
            hallmarks: [
                "The only person in the twenty who is also one of the ten imams.",
                "Carries Hamzah's long elongation and hamzah treatment.",
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.khallad, name: "Khallad", arabic: "خَلَّاد",
            fullName: "Abu Isa Khallad ibn Khalid as-Sayrafi al-Kufi",
            masterID: Settings.Riwayah.hamzahTeacher, city: "Kufa", bornAH: nil, diedAH: 220,
            summary: "Hamzah's Kufan narrator, through Sulaym.",
            paragraphs: [
                "Khallad also read on Sulaym and transmitted Hamzah's reading in Kufa. He was regarded as exacting in the details of Hamzah's tajwid, which in this reading are unusually demanding.",
                "The differences between Khalaf and Khallad are few, and mostly concern the sakt and the treatment of certain hamzahs.",
            ],
            hallmarks: [
                "Very close to Khalaf, differing in a small set of places.",
                "Preserves Hamzah's demanding pausing rules.",
            ]
        ),
        // al-Kisai
        RiwayahNarratorProfile(
            id: Settings.Riwayah.abuHarith, name: "Abu al-Harith", arabic: "أَبُو الحَارِث",
            fullName: "Abu al-Harith al-Layth ibn Khalid al-Baghdadi",
            masterID: Settings.Riwayah.kisaiTeacher, city: "Baghdad", bornAH: nil, diedAH: 240,
            summary: "Al-Kisai's foremost student in Baghdad.",
            paragraphs: [
                "Abu al-Harith read directly on al-Kisai and was counted his most accomplished student. He taught in Baghdad, where the Kufan reading had followed al-Kisai to the caliphal capital.",
                "His narration and ad-Duri's are the two through which al-Kisai's reading is preserved.",
            ],
            hallmarks: [
                "Carries al-Kisai's frequent imalah.",
                "Distinctive pausing on the feminine ta.",
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.duriKisai, name: "ad-Duri", arabic: "الدُّورِي",
            fullName: "Abu Umar Hafs ibn Umar ad-Duri al-Baghdadi",
            masterID: Settings.Riwayah.kisaiTeacher, city: "Baghdad", bornAH: nil, diedAH: 246,
            summary: "The same ad-Duri, here reading directly on al-Kisai.",
            paragraphs: [
                "This is the same Hafs ibn Umar ad-Duri who narrates Abu Amr's reading. Under al-Kisai he read directly on the imam rather than through an intermediary, so his two narrations sit at different distances from their sources.",
                "That one man carries two of the ten readings is a reminder of how small and interconnected the circle of early qurra was: the students of one imam were often the students of another.",
            ],
            hallmarks: [
                "The second of ad-Duri's two narrations among the twenty.",
                "Read directly on al-Kisai, unlike his narration of Abu Amr.",
            ]
        ),
        // Abu Ja'far
        RiwayahNarratorProfile(
            id: Settings.Riwayah.ibnWardan, name: "Ibn Wardan", arabic: "ابنُ وَردَان",
            fullName: "Abu al-Harith Isa ibn Wardan al-Madani",
            masterID: Settings.Riwayah.abiJafarTeacher, city: "Madinah", bornAH: nil, diedAH: 160,
            summary: "A Madinan who read on both Abu Ja'far and Nafi.",
            paragraphs: [
                "Ibn Wardan read on Abu Ja'far and also on Nafi, which places him inside both Madinan traditions. He is counted the first of Abu Ja'far's two narrators.",
                "He died a generation before most of the other narrators of the twenty, which is consistent with Abu Ja'far being the earliest of the ten imams.",
            ],
            hallmarks: [
                "Preserves the older Madinan practice Abu Ja'far taught.",
                "Distinctive treatment of the disconnected letters.",
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.ibnJammaz, name: "Ibn Jammaz", arabic: "ابنُ جَمَّاز",
            fullName: "Abu ar-Rabi Sulayman ibn Muslim ibn Jammaz al-Madani",
            masterID: Settings.Riwayah.abiJafarTeacher, city: "Madinah", bornAH: nil, diedAH: 170,
            summary: "Abu Ja'far's second narrator, who also read on Nafi.",
            paragraphs: [
                "Ibn Jammaz read on Abu Ja'far and, like Ibn Wardan, also on Nafi. He taught in Madinah and is the second of the two narrators through whom Abu Ja'far's reading reaches us.",
                "The differences between the two narrators of Abu Ja'far are relatively few.",
            ],
            hallmarks: [
                "Close to Ibn Wardan throughout.",
                "Carries the Madinan reading of the generation before Nafi.",
            ]
        ),
        // Ya'qub
        RiwayahNarratorProfile(
            id: Settings.Riwayah.ruways, name: "Ruways", arabic: "رُوَيس",
            fullName: "Abu Abd Allah Muhammad ibn al-Mutawakkil al-Lu'lu'i al-Basri",
            masterID: Settings.Riwayah.yaqubTeacher, city: "Basra", bornAH: nil, diedAH: 238,
            summary: "Ya'qub's leading Basran student.",
            paragraphs: [
                "Ruways read directly on Ya'qub al-Hadrami and was regarded as the most accomplished of his students. He taught in Basra and his narration travelled from there.",
                "Ruways is a nickname; his given name was Muhammad ibn al-Mutawakkil.",
            ],
            hallmarks: [
                "Carries Ya'qub's distinctive handling of the connecting pronoun.",
                "Differs from Rawh in a limited, well-documented set of places.",
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.rawh, name: "Rawh", arabic: "رَوح",
            fullName: "Abu al-Hasan Rawh ibn Abd al-Mu'min al-Hudhali al-Basri",
            masterID: Settings.Riwayah.yaqubTeacher, city: "Basra", bornAH: nil, diedAH: 234,
            summary: "Ya'qub's other narrator, and a hadith scholar of standing.",
            paragraphs: [
                "Rawh read on Ya'qub in Basra and was also a transmitter of hadith whose narrations are cited in the major collections.",
                "He and Ruways are the pair through whom the ninth reading is preserved.",
            ],
            hallmarks: [
                "Very close to Ruways, with a small set of differences.",
                "Preserves Ya'qub's characteristic word-forms.",
            ]
        ),
        // Khalaf al-Ashir
        RiwayahNarratorProfile(
            id: Settings.Riwayah.ishaq, name: "Ishaq", arabic: "إِسحَاق",
            fullName: "Abu Ya'qub Ishaq ibn Ibrahim al-Warraq al-Baghdadi",
            masterID: Settings.Riwayah.khalafAshirTeacher, city: "Baghdad", bornAH: nil, diedAH: 286,
            summary: "The narrator who took Khalaf's own selection directly.",
            paragraphs: [
                "Ishaq al-Warraq read on Khalaf al-Bazzar and transmitted the selection Khalaf had made, rather than Khalaf's narration of Hamzah. He taught in Baghdad after Khalaf's death.",
                "He is the first of the two narrators of the tenth reading.",
            ],
            hallmarks: [
                "Transmits Khalaf's own ikhtiyar, not Hamzah's reading.",
                "Baghdadi in chain and in teaching.",
                "Reads identically to Idris: al-Durrah reports no difference between them.",
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.idris, name: "Idris", arabic: "إِدرِيس",
            fullName: "Abu al-Hasan Idris ibn Abd al-Karim al-Haddad al-Baghdadi",
            masterID: Settings.Riwayah.khalafAshirTeacher, city: "Baghdad", bornAH: 189, diedAH: 292,
            summary: "The last of the twenty narrators to die.",
            paragraphs: [
                "Idris al-Haddad read on Khalaf al-Bazzar and became the leading teacher of the tenth reading in Baghdad. He was also a trusted transmitter of hadith.",
                "He died in 292 AH, the latest death date among the twenty narrators, which makes him the closing link of the whole canonical chain.",
            ],
            hallmarks: [
                "The most widely transmitted of the two narrations of Khalaf al-Ashir.",
                "The last of the twenty by death date.",
                "Reads identically to Ishaq: al-Durrah reports no difference between them.",
            ]
        ),
    ]
}

// MARK: - Detail views

struct QiraahMasterDetailView: View {
    @ObservedObject var settings = Settings.shared
    let profile: QiraahMasterProfile

    var body: some View {
        List {
            Group {
                Section(header: Text("THE IMAM")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(profile.arabic)
                            .font(.title2)
                            .foregroundColor(settings.accentColor.color)
                        Text(profile.fullName)
                            .font(.body.weight(.semibold))
                        Text("\(profile.city) · \(profile.lifespan)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)

                    Text(profile.summary)
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("BIOGRAPHY")) {
                    ForEach(profile.paragraphs, id: \.self) { paragraph in
                        ProseText(text: paragraph)
                    }
                }

                Section(header: Text("KNOWN FOR")) {
                    ForEach(profile.hallmarks, id: \.self) { item in
                        Text("• \(item)").font(.body)
                    }
                }

                Section(header: Text("CHAIN TO THE COMPANIONS")) {
                    ProseText(text: profile.companions)
                }

                let riwayat = QiraatProfiles.narrators(ofMaster: profile.id)
                Section {
                    ForEach(riwayat) { narrator in
                        NavigationLink(destination: LazyDestination { RiwayahNarratorDetailView(profile: narrator) }) {
                            QiraatProfileRow(title: narrator.name, arabic: narrator.arabic,
                                             detail: "\(narrator.city) · d. \(narrator.diedAH) AH")
                        }
                    }
                } header: {
                    Text("ITS TWO RIWAYAT")
                } footer: {
                    if riwayat.count == 2,
                       QiraatProfiles.shareOneText(riwayat[0].id, riwayat[1].id) {
                        Text(QiraatProfiles.sharedTextShortNote)
                    }
                }

                QiraatSourceSection()
            }
            .themedListRowBackground()
        }
        .navigationTitle(profile.id)
        .selectableArticleList()
    }
}

struct RiwayahNarratorDetailView: View {
    @ObservedObject var settings = Settings.shared
    let profile: RiwayahNarratorProfile

    var body: some View {
        List {
            Group {
                Section(header: Text("THE NARRATOR")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(profile.arabic)
                            .font(.title2)
                            .foregroundColor(settings.accentColor.color)
                        Text(profile.fullName)
                            .font(.body.weight(.semibold))
                        Text("\(profile.city) · \(profile.lifespan)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)

                    Text(profile.summary)
                        .font(.body)
                        .foregroundColor(settings.accentColor.color)
                }

                Section(header: Text("BIOGRAPHY")) {
                    ForEach(profile.paragraphs, id: \.self) { paragraph in
                        ProseText(text: paragraph)
                    }
                }

                // Two riwayat that always read alike look like a defect in the app unless the page
                // says why they do, so the reason travels with the narrator rather than sitting
                // only in the comparison sheet where the match is first noticed.
                if let partner = QiraatProfiles.sharedTextPartner(of: profile.id) {
                    Section(header: Text("THE SAME TEXT AS \(QiraatProfiles.shortName(of: partner).uppercased())")) {
                        ProseText(text: QiraatProfiles.sharedTextExplanation)
                    }
                }

                Section(header: Text("KNOWN FOR")) {
                    ForEach(profile.hallmarks, id: \.self) { item in
                        Text("• \(item)").font(.body)
                    }
                }

                if let master = QiraatProfiles.master(id: profile.masterID) {
                    Section(header: Text("THE READING IT NARRATES")) {
                        NavigationLink(destination: LazyDestination { QiraahMasterDetailView(profile: master) }) {
                            QiraatProfileRow(title: master.id, arabic: master.arabic,
                                             detail: "\(master.city) · d. \(master.diedAH) AH")
                        }
                    }
                }

                QiraatSourceSection()
            }
            .themedListRowBackground()
        }
        .navigationTitle(profile.name)
        .selectableArticleList()
    }
}

/// The row shape shared by every list of imams and narrators in the guide.
struct QiraatProfileRow: View {
    @ObservedObject var settings = Settings.shared
    let title: String
    let arabic: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(detail).font(.caption).foregroundColor(.secondary)
            }
            Spacer(minLength: 8)
            Text(arabic)
                .font(.body)
                .foregroundColor(settings.accentColor.color)
        }
    }
}

/// Every profile page carries the same further-reading credit.
struct QiraatSourceSection: View {
    var body: some View {
        Section(header: Text("FURTHER READING")) {
            Link(destination: QiraatProfiles.sourceURL) {
                Label("QiraatHub - profiles of the ten readings and their narrators", systemImage: "link")
            }
            .font(.caption)

            Text("These pages are written for this app. QiraatHub is the companion reference for the ten readings and is credited in Settings → Credits.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
