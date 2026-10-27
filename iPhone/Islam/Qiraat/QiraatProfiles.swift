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
        guard let bornAH else { return String(localized: "d. \(String(diedAH).localizedDigits) AH (\(String(diedCE).localizedDigits) CE)") }
        return String(localized: "\(String(bornAH).localizedDigits)–\(String(diedAH).localizedDigits) AH (d. \(String(diedCE).localizedDigits) CE)")
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
        guard let bornAH else { return String(localized: "d. \(String(diedAH).localizedDigits) AH") }
        return String(localized: "\(String(bornAH).localizedDigits)–\(String(diedAH).localizedDigits) AH")
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

    // MARK: - The seven and the three

    /// The seven readings Ibn Mujahid (d. 324 AH) collected in his Kitab al-Sab'ah, in his order: one
    /// each from Madinah, Makkah, Basra and Damascus, then the three Kufans.
    static let sevenIDs: [String] = [
        Settings.Riwayah.nafiTeacher, Settings.Riwayah.ibnKathirTeacher, Settings.Riwayah.abiAmrTeacher,
        Settings.Riwayah.ibnAmirTeacher, Settings.Riwayah.asimTeacher, Settings.Riwayah.hamzahTeacher,
        Settings.Riwayah.kisaiTeacher,
    ]

    /// The three Ibn al-Jazari (d. 833 AH) established as equally mutawatir in al-Durrah
    /// al-Mutammimah, completing the ten, in his order.
    static let threeIDs: [String] = [
        Settings.Riwayah.abiJafarTeacher, Settings.Riwayah.yaqubTeacher, Settings.Riwayah.khalafAshirTeacher,
    ]

    static func masters(in ids: [String]) -> [QiraahMasterProfile] {
        ids.compactMap { master(id: $0) }
    }

    /// The imam's number among the ten, in the classical order (the seven, then the three).
    static func ordinal(ofMaster id: String) -> Int? {
        (sevenIDs + threeIDs).firstIndex(of: id).map { $0 + 1 }
    }

    // MARK: - Where each reading is recited today

    /// Where a reading is actually recited in public worship today, as opposed to where its imam
    /// lived. Only four narrations have a living regional following (Hafs almost everywhere, Warsh
    /// and Qalun in North and West Africa, ad-Duri of Abu Amr in the Sudan belt); the rest are kept
    /// alive by teachers with ijazah, by recordings and by the printed mushafs, which is what
    /// "taught by specialists" means below. Shown on the guide's rows and on every profile page
    /// (Abu, 2026-09-04: "mention where each riwayah/qiraah is generally recited").
    static let specialistsNote = "Taught by specialists with ijazah and heard in recordings; no region recites it in public worship today."

    private static let masterRegions: [String: String] = [
        Settings.Riwayah.nafiTeacher: "The Maghreb and West Africa through Warsh, Libya and Tunisia through Qalun. The second most recited reading in the world.",
        Settings.Riwayah.ibnKathirTeacher: "Historically the reading of Makkah. Today taught by specialists and heard in recordings; no region recites it in public worship.",
        Settings.Riwayah.abiAmrTeacher: "Sudan, Chad and Somalia through ad-Duri, with pockets of Nigeria. As-Susi is studied rather than recited regionally.",
        Settings.Riwayah.ibnAmirTeacher: "Historically Damascus and greater Syria. Today taught by specialists and heard in recordings.",
        Settings.Riwayah.asimTeacher: "Most of the Muslim world, through Hafs. That means the Middle East, Turkey, South and Southeast Asia and the diaspora; Shu'bah is taught by specialists.",
        Settings.Riwayah.hamzahTeacher: "Historically Kufa. Today taught by specialists and heard in recordings.",
        Settings.Riwayah.kisaiTeacher: "Historically Kufa and Baghdad. Today taught by specialists and heard in recordings.",
        Settings.Riwayah.abiJafarTeacher: "Historically Madinah. Today taught by specialists and heard in recordings.",
        Settings.Riwayah.yaqubTeacher: "Historically Basra. Today taught by specialists and heard in recordings.",
        Settings.Riwayah.khalafAshirTeacher: "Historically Kufa and Baghdad. Today taught by specialists and heard in recordings.",
    ]

    private static let narratorRegions: [String: String] = [
        Settings.Riwayah.hafsTag: "Most of the Muslim world: the Middle East, Turkey, South and Southeast Asia and the diaspora, and the text of most printed mushafs.",
        Settings.Riwayah.shubah: specialistsNote,
        Settings.Riwayah.warsh: "Morocco, Algeria, Mauritania and much of West Africa (Senegal, Mali, Niger), with a presence in Tunisia, Libya and Sudan.",
        Settings.Riwayah.qaloon: "Libya and Tunisia, and parts of the wider Maghreb.",
        Settings.Riwayah.buzzi: "Historically Makkah. " + specialistsNote,
        Settings.Riwayah.qunbul: "Historically Makkah. " + specialistsNote,
        Settings.Riwayah.duri: "Sudan, Chad and Somalia, with pockets of Nigeria and the Sahel.",
        Settings.Riwayah.susi: specialistsNote,
        Settings.Riwayah.hisham: "Historically Damascus and greater Syria. " + specialistsNote,
        Settings.Riwayah.ibnDhakwan: "Historically Damascus and greater Syria. " + specialistsNote,
        Settings.Riwayah.khalaf: "Historically Kufa. " + specialistsNote,
        Settings.Riwayah.khallad: "Historically Kufa. " + specialistsNote,
        Settings.Riwayah.abuHarith: "Historically Kufa and Baghdad. " + specialistsNote,
        Settings.Riwayah.duriKisai: "Historically Kufa and Baghdad. " + specialistsNote,
        Settings.Riwayah.ibnWardan: "Historically Madinah. " + specialistsNote,
        Settings.Riwayah.ibnJammaz: "Historically Madinah. " + specialistsNote,
        Settings.Riwayah.ruways: "Historically Basra. " + specialistsNote,
        Settings.Riwayah.rawh: "Historically Basra. " + specialistsNote,
        Settings.Riwayah.ishaq: "Historically Baghdad. " + specialistsNote,
        Settings.Riwayah.idris: "Historically Baghdad. " + specialistsNote,
    ]

    static func recitedToday(master id: String) -> String {
        masterRegions[id] ?? specialistsNote
    }

    static func recitedToday(narrator tag: String) -> String {
        narratorRegions[tag] ?? specialistsNote
    }

    /// The short form for a list row: the text up to its first full stop.
    static func recitedTodayShort(master id: String) -> String {
        firstSentence(recitedToday(master: id))
    }

    static func recitedTodayShort(narrator tag: String) -> String {
        firstSentence(recitedToday(narrator: tag))
    }

    private static func firstSentence(_ text: String) -> String {
        guard let end = text.firstIndex(of: ".") else { return text }
        return String(text[..<end])
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
    static let sharedTextExplanation = String(localized: "Ishaq and Idris are the two narrators of Khalaf al-Ashir, and via al-Durrah al-Mutammimah nothing is transmitted differently between them: they agree in the usul, and no difference in the farsh is reported either. The mushaf this app's Arabic is taken from prints one body text under both narrators' names, so the two read alike in every ayah. The places where the two narrations do part company belong to Tayyibat al-Nashr, the greater ten, in which Ibn al-Jazari gives Idris two turuq.")

    /// The one-line form, for a footer under a list that already names the two.
    static let sharedTextShortNote = String(localized: "Nothing is transmitted differently between these two narrators via al-Durrah, so they carry one text. Open either for the detail.")

    /// Under every WHAT STANDS OUT list: the page can show the letters, not the sound.
    static let pageShowsOnlyPart = String(localized: "A printed mushaf shows only part of this. The rest is passed on by ear, which is why a reading is learned with a teacher.")

    // MARK: - The ten imams, in the guide's own alphabetical order

    static let masters: [QiraahMasterProfile] = [
        QiraahMasterProfile(
            id: Settings.Riwayah.abiJafarTeacher,
            arabic: Settings.Riwayah.abiJafarTeacherArabic,
            fullName: String(localized: "Abu Ja'far Yazid ibn al-Qa'qa' al-Makhzumi al-Madani"),
            city: "Madinah", bornAH: nil, diedAH: 130, diedCE: 748,
            summary: String(localized: "The senior Madinan reader, and Nafi's own teacher."),
            paragraphs: [
                String(localized: "Abu Ja'far was among the senior Successors (tabi'in) of Madinah and one of the earliest of the ten imams. He learned from Companions of the Prophet (peace and blessings be upon him) directly, and taught in the Prophet's Mosque for decades."),
                String(localized: "He is the teacher of Nafi al-Madani, which places him a generation above most of the ten: the Madinan reading that later spread through Qalun and Warsh was shaped by what Abu Ja'far taught. His own reading was added to the canonical ten by Ibn al-Jazari alongside Ya'qub and Khalaf."),
                String(localized: "He was known for his piety as much as his recitation, and the reports about him dwell on how carefully he held to what he had been taught rather than on any innovation of his own."),
            ],
            hallmarks: [
                String(localized: "Every resting hamzah becomes a long vowel: يُؤۡمِنُونَ is read يُومِنُونَ and بِئۡسَ as بِيسَ. The mushaf writes it so, which is why it carries about 1,500 fewer hamzah signs than Hafs's."),
                String(localized: "The plural mim is joined with a waw before a vowel, قُلُوبِهِمُۥ, رَزَقۡنَٰهُمُۥ, as Ibn Kathir reads it."),
                String(localized: "Two hamzahs in one word: the second is softened and an alef slipped between them, ءَٰا۬نذَرۡتَهُمُۥ. The name إِسۡرَآيلَ loses its hamzah altogether."),
                String(localized: "The resting nun is hidden before خ and غ, مِن غَيۡرِ, where every other reading sounds it clearly."),
                String(localized: "The letters that open a surah are read with a breath-less pause after each one, and the separated madd is kept short, two counts."),
                String(localized: "No imalah: the reading stays level (fath) throughout."),
            ],
            companions: String(localized: "Transmitted from Zayd ibn Thabit, Ubayy ibn Ka'b, Abdullah ibn Abbas, Abdullah ibn Ayyash, and Abu Hurayrah (may Allah be pleased with them)."),
            narratorTags: [Settings.Riwayah.ibnWardan, Settings.Riwayah.ibnJammaz]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.abiAmrTeacher,
            arabic: Settings.Riwayah.abiAmrTeacherArabic,
            fullName: String(localized: "Abu Amr Zabban ibn al-Ala' ibn Ammar al-Mazini al-Basri"),
            city: "Basra", bornAH: 68, diedAH: 154, diedCE: 770,
            summary: String(localized: "Imam of Basra, and one of the founders of Arabic grammar."),
            paragraphs: [
                String(localized: "Abu Amr was born in Makkah and settled in Basra, where he became both the imam of recitation and one of the founding figures of the Basran school of Arabic grammar. That double authority is why his reading is so often cited in discussions of Arabic usage as well as of recitation."),
                String(localized: "He was famous for the breadth of his study: his notebooks are reported to have filled a house to the ceiling before he turned to worship and burned them, and he travelled widely to read on the Successors. His students Yahya al-Yazidi and then ad-Duri and as-Susi carried the reading forward."),
                String(localized: "Both of his canonical narrators read on al-Yazidi rather than on Abu Amr himself, so the riwayat of ad-Duri and as-Susi meet one generation below the imam."),
            ],
            hallmarks: [
                String(localized: "The large idgham: a word's last letter merges into the same or a near letter at the start of the next word, قَال رَّبُّكَ, رَبِحَت تِّجَٰرَتُهُمۡ, لَذَهَب بِّسَمۡعِهِمۡ. As-Susi's mushaf writes it at about a thousand places; ad-Duri does not read it by the Shatibiyyah route."),
                String(localized: "Imalah of the alef before a ra with a kasra, ٱلنَّٜاسِ, ٱلنَّٜارِ, ٱلۡكَٰٜفِرِينَ, and of words ending in ى after a ra, أُخۡرٜىٰ, تَرٜىٰ; a half tilt (taqlil) on ٱلدُّنۡيَا and مُوسَىٰ."),
                String(localized: "The vowel of a few verbs is dropped or slurred before كُمۡ: يَأۡمُرۡكُمۡ, بَارِئۡكُمۡ."),
                String(localized: "Two hamzahs meeting between words: the first is dropped, هَٰٓؤُلَآ إِن. As-Susi also turns every resting hamzah into a long vowel, يُومِنُونَ, تُومَرُونَ; ad-Duri keeps it."),
                String(localized: "The separated madd is short or medium: ad-Duri's mushaf prints it stretched, as-Susi's short."),
                String(localized: "Between two surahs three ways are transmitted: the basmalah, a breath-less pause, or running straight on."),
            ],
            companions: String(localized: "Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas'ud, Abu Musa al-Ash'ari, Abdullah ibn Abbas, Ubayy ibn Ka'b, Zayd ibn Thabit, and Abu Hurayrah (may Allah be pleased with them)."),
            narratorTags: [Settings.Riwayah.duri, Settings.Riwayah.susi]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.kisaiTeacher,
            arabic: Settings.Riwayah.kisaiTeacherArabic,
            fullName: String(localized: "Abu al-Hasan Ali ibn Hamzah al-Kisai"),
            city: "Kufa", bornAH: nil, diedAH: 189, diedCE: 805,
            summary: String(localized: "The last of the seven, and head of the Kufan school of grammar."),
            paragraphs: [
                String(localized: "Al-Kisai took his name from the cloak (kisa') he was wearing when he entered ihram. He read on Hamzah az-Zayyat and on others, and after Hamzah's death he became the imam of recitation in Kufa."),
                String(localized: "He led the Kufan school of Arabic grammar and was appointed tutor to the sons of the Abbasid caliph, which carried his reading into the centre of scholarly life in Baghdad. His well-known grammatical debate with Sibawayh, the great Basran, marks the high point of the rivalry between the two schools."),
                String(localized: "He is the seventh and last of the imams gathered by Ibn Mujahid into the famous seven."),
            ],
            hallmarks: [
                String(localized: "Imalah wherever a word ends in an alef written as a ya: مُوسٜىٰ, ٱلۡهُدٜىٰ, بَلٜىٰ, وَكَفٜىٰ, and in ٱلدُّنۡيٜا, some 1,600 places in Abu al-Harith's mushaf and 1,950 in ad-Duri's."),
                String(localized: "At a pause the feminine ta (ة) tilts as well: ٱلۡجَنَّةَ is heard as al-jannih. This is al-Kisai's alone among the ten, and nothing marks it on the page."),
                String(localized: "The lam of هَلۡ and بَلۡ merges into the letter after it: هَل ثُّوِّبَ, as Hamzah reads."),
                String(localized: "Every hamzah in full, reading on and at a stop, and four counts on the separated madd, as Hafs."),
                String(localized: "Basmalah between every two surahs."),
            ],
            companions: String(localized: "Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka'b, Zayd ibn Thabit, Abdullah ibn Mas'ud, Abdullah ibn Abbas, Abu Hurayrah, and Husayn ibn Ali (may Allah be pleased with them)."),
            narratorTags: [Settings.Riwayah.abuHarith, Settings.Riwayah.duriKisai]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.asimTeacher,
            arabic: Settings.Riwayah.asimTeacherArabic,
            fullName: String(localized: "Abu Bakr Asim ibn Abi an-Najud Bahdalah al-Asadi"),
            city: "Kufa", bornAH: nil, diedAH: 127, diedCE: 745,
            summary: String(localized: "The reading almost the whole Muslim world recites today, through Hafs."),
            paragraphs: [
                String(localized: "Asim was a Successor (tabi'i) of Kufa who learned from Abu Abd ar-Rahman as-Sulami, who in turn read on Uthman, Ali, Ibn Mas'ud, Ubayy ibn Ka'b and Zayd ibn Thabit (may Allah be pleased with them). His chain to the Prophet (peace and blessings be upon him) is therefore short and famously well attested."),
                String(localized: "He was described as the most beautiful reciter of his time, and as exacting to the point that he would not pass a student on until the recitation was exactly as he had received it."),
                String(localized: "His two narrators went in different directions: Shu'bah preserved what he took with great caution, while Hafs transmitted the reading that would eventually become the standard printed mushaf across most of the world."),
            ],
            hallmarks: [
                String(localized: "Every hamzah pronounced in full, with no softening at a stop. Hafs's one exception is ءَا۬عۡجَمِيّٞ in Fussilat."),
                String(localized: "Almost no imalah: Hafs has one, مَجۡرٜىٰهَا in Hud; Shu'bah a handful, أَدۡرٜىٰكَ, رٜءَا, and the opening letters حٜمٓ and الٓرٜ."),
                String(localized: "Four counts on both the joined and the separated madd, the middle measure of the ten."),
                String(localized: "Shu'bah differs from Hafs in some five hundred places, nearly all a vowel or a dot, so the pair shows cleanly how two riwayat of one imam can differ."),
                String(localized: "Basmalah between every two surahs, and the text of almost every printed mushaf today, through Hafs."),
            ],
            companions: String(localized: "Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas'ud, Zayd ibn Thabit, and Ubayy ibn Ka'b (may Allah be pleased with them)."),
            narratorTags: [Settings.Riwayah.hafsTag, Settings.Riwayah.shubah]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.hamzahTeacher,
            arabic: Settings.Riwayah.hamzahTeacherArabic,
            fullName: String(localized: "Abu Imarah Hamzah ibn Habib az-Zayyat at-Taymi"),
            city: "Kufa", bornAH: 80, diedAH: 156, diedCE: 773,
            summary: String(localized: "Known for the longest madd and for his pauses on the hamzah."),
            paragraphs: [
                String(localized: "Hamzah was called az-Zayyat because he traded in oil between Kufa and Hulwan. He became the imam of recitation in Kufa after Asim, and his reading is among the most distinctive of the ten."),
                String(localized: "He was known for long night prayer and for an exacting devotion to tajwid. His reading asks more of the reciter than most: the elongations are the longest of the ten, and the treatment of the hamzah when pausing is a subject studied on its own."),
                String(localized: "His student Khalaf later made his own selection from Hamzah's reading and became the tenth imam in his own right, which is why Khalaf appears twice in the guide, once as a narrator and once as a master."),
                String(localized: "What a listener hears is not always what the page writes. Reading on, Hamzah pronounces every hamzah in full. When he stops on a word, a hamzah in its middle or at its end is eased, following the written form: turned into a long vowel, moved onto the letter before it, or softened. Every recording stops at the end of each ayah, so the last word of every ayah is heard without its hamzah (قَدۡ أَفۡلَحَ ٱلۡمُؤۡمِنُونَ ends in al-muuminoon), while a mushaf prints the continuous form and keeps it. The test is the same word mid-ayah, where the reciter keeps going: in 4:92 Khalaf reads li-mu'minin and mu'minan with the hamzah in full."),
            ],
            hallmarks: [
                String(localized: "The longest madd of the ten: six counts on both the joined and the separated madd."),
                String(localized: "Every hamzah in full while reading on, eased at a stop: the last word of each ayah sounds hamzah-less in recordings, قَدۡ أَفۡلَحَ ٱلۡمُؤۡمِنُونَ ending in al-muuminoon, while the mushaf keeps it."),
                String(localized: "A sakt (brief pause without breath) before the hamzah of أل, of شَيۡء and of a detached word, through Khalaf; Khallad has it both ways on the first two."),
                String(localized: "Imalah wherever a word ends in an alef written as a ya, مُوسٜىٰ, ٱلۡهُدٜىٰ, ٱلدُّنۡيٜا, and in جٜآءَ and شٜآءَ wherever they occur, about 1,900 places."),
                String(localized: "The ha of عَلَيۡهُمۡ, إِلَيۡهُمۡ and لَدَيۡهُمۡ read with a damma, and the lam of هَلۡ and بَلۡ merged into the letter after it, هَل ثُّوِّبَ."),
                String(localized: "No basmalah between two surahs: the end of one surah runs straight into the next."),
            ],
            companions: String(localized: "Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka'b, Zayd ibn Thabit, Abdullah ibn Mas'ud, and Husayn ibn Ali (may Allah be pleased with them)."),
            narratorTags: [Settings.Riwayah.khalaf, Settings.Riwayah.khallad]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.ibnAmirTeacher,
            arabic: Settings.Riwayah.ibnAmirTeacherArabic,
            fullName: String(localized: "Abu Imran Abdullah ibn Amir al-Yahsubi"),
            city: "Damascus", bornAH: 21, diedAH: 118, diedCE: 736,
            summary: String(localized: "The Damascene reading, and the earliest-born of the ten."),
            paragraphs: [
                String(localized: "Ibn Amir was born in the lifetime of the Companions and is counted among the Successors. He served as judge of Damascus and as imam of its great Umayyad Mosque, and he led recitation there through the whole of the early Umayyad period."),
                String(localized: "He learned from Abu ad-Darda and from al-Mughirah ibn Abi Shihab al-Makhzumi, who read on Uthman ibn Affan (may Allah be pleased with them). His is the reading of Sham, and it remained the recitation of Damascus for centuries."),
                String(localized: "Both of his canonical narrators, Hisham and Ibn Dhakwan, came generations later and received the reading through intermediate teachers."),
            ],
            hallmarks: [
                String(localized: "Word-forms that follow the Damascus mushaf's own spelling: سَارِعُوٓاْ without the waw, فَلَا يَخَافُ for وَلَا يَخَافُ, and a dozen more."),
                String(localized: "Every hamzah in full for Ibn Dhakwan. Hisham softens a final hamzah at a stop, and may slip an alef between two hamzahs in one word, ءَٰا۬نتَ."),
                String(localized: "Imalah in a short list of words: Ibn Dhakwan tilts جٜآءَ and شٜآءَ wherever they occur; Hisham only in a few words and the opening letters الٓرٜ."),
                String(localized: "Four counts on both madds, as Hafs."),
                String(localized: "Between two surahs three ways are transmitted: the basmalah, a breath-less pause, or running straight on."),
            ],
            companions: String(localized: "Transmitted from Uthman ibn Affan and Abu ad-Darda (may Allah be pleased with them)."),
            narratorTags: [Settings.Riwayah.hisham, Settings.Riwayah.ibnDhakwan]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.ibnKathirTeacher,
            arabic: Settings.Riwayah.ibnKathirTeacherArabic,
            fullName: String(localized: "Abu Ma'bad Abdullah ibn Kathir ad-Dari al-Makki"),
            city: "Makkah", bornAH: 45, diedAH: 120, diedCE: 738,
            summary: String(localized: "Imam of recitation in Makkah, and a Successor who met Companions."),
            paragraphs: [
                String(localized: "Ibn Kathir al-Makki was born in Makkah and lived his whole life there. He was a Successor who met a number of Companions, among them Abdullah ibn az-Zubayr, Anas ibn Malik and Abu Ayyub al-Ansari (may Allah be pleased with them)."),
                String(localized: "He was the undisputed imam of recitation in Makkah in his generation, and people travelled to read on him. He is not to be confused with the much later Ibn Kathir the mufassir, who is a different scholar entirely."),
                String(localized: "Neither al-Bazzi nor Qunbul met him: both received the Makkan reading through intermediate teachers, which is the usual pattern for the earlier imams of the ten."),
            ],
            hallmarks: [
                String(localized: "The pronoun ha is drawn out even after a resting letter: فِيهِۦ, مِنۡهُۥ, عَنۡهُۥ, read fihee, minhoo. No other reading does this throughout."),
                String(localized: "The plural mim is joined with a waw before a vowel: رَزَقۡنَٰهُمُۥ, قُلُوبِهِمُۥ."),
                String(localized: "The separated madd kept short, two counts, and no imalah: the reading stays level (fath) throughout."),
                String(localized: "Two hamzahs meeting between words: al-Bazzi drops the first, جَا أَحَدٞ; Qunbul softens the second. Qunbul also reads الصراط with a seen, ٱلصِّۜرَٰطَ."),
                String(localized: "Al-Bazzi doubles the ta of a set of verbs, وَلَا تَّفَرَّقُواْ, and carries the takbir, Allahu akbar, before the basmalah of every surah from ad-Duha to the end."),
                String(localized: "Basmalah between every two surahs."),
            ],
            companions: String(localized: "Transmitted from Umar ibn al-Khattab, Zayd ibn Thabit, Ubayy ibn Ka'b, Abdullah ibn Abbas, and Abdullah ibn as-Sa'ib (may Allah be pleased with them)."),
            narratorTags: [Settings.Riwayah.buzzi, Settings.Riwayah.qunbul]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.khalafAshirTeacher,
            arabic: Settings.Riwayah.khalafAshirTeacherArabic,
            fullName: String(localized: "Abu Muhammad Khalaf ibn Hisham al-Bazzar al-Baghdadi"),
            city: "Baghdad", bornAH: 150, diedAH: 229, diedCE: 844,
            summary: String(localized: "A narrator of Hamzah who became the tenth imam in his own right."),
            paragraphs: [
                String(localized: "Khalaf memorised the Quran as a boy and read on Sulaym, the student of Hamzah, becoming one of Hamzah's two canonical narrators. He then made his own considered selection (ikhtiyar) from the readings he had received, and that selection is the tenth of the ten Qiraat."),
                String(localized: "This is why his name appears twice in the guide: Khalaf an Hamzah is a riwayah of the sixth reading, while Khalaf al-Ashir (Khalaf the Tenth) is a reading of its own, with its own two narrators, Ishaq and Idris."),
                String(localized: "The two are taught from different poems. Hamzah's reading, with Khalaf's narration of it, is in ash-Shatibiyyah; Khalaf's own reading is in ad-Durrah al-Mudiyyah, Ibn al-Jazari's poem on the three readings that complete the ten. They part company on the hamzah: as Khalaf al-Ashir he pronounces it in full at a stop as well, and ad-Durrah gives him no sakt. So a mushaf titled Khalaf al-Ashir and one titled Khalaf an Hamzah read differently, although the same man stands behind both."),
                String(localized: "He was a scholar of Baghdad known for his precision and his asceticism, and his selection was recognised as canonical because it met the same three conditions as the rest: the Uthmanic rasm, sound Arabic, and authentic mass transmission."),
            ],
            hallmarks: [
                String(localized: "A considered selection (ikhtiyar) drawn mostly from the Kufan readings: close to Hamzah in many places, but with its own settled choices."),
                String(localized: "The hamzah in full at a stop and no sakt, unlike his narration of Hamzah, which is why a Khalaf al-Ashir mushaf and a Khalaf an Hamzah mushaf read differently."),
                String(localized: "Four counts on the separated madd, against Hamzah's six."),
                String(localized: "Hamzah's imalah kept: مُوسٜىٰ, ٱلدُّنۡيٜا, جٜآءَ, شٜآءَ, about 1,870 places."),
                String(localized: "The ha of عَلَيۡهِمۡ with a kasra, as Hafs, where Hamzah reads a damma."),
            ],
            companions: String(localized: "Transmitted from Uthman ibn Affan, Ali ibn Abi Talib, Abdullah ibn Mas'ud, Zayd ibn Thabit, Ubayy ibn Ka'b, and Husayn ibn Ali (may Allah be pleased with them)."),
            narratorTags: [Settings.Riwayah.ishaq, Settings.Riwayah.idris]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.nafiTeacher,
            arabic: Settings.Riwayah.nafiTeacherArabic,
            fullName: String(localized: "Abu Ruwaym Nafi ibn Abd ar-Rahman ibn Abi Nu'aym al-Laythi"),
            city: "Madinah", bornAH: nil, diedAH: 169, diedCE: 785,
            summary: String(localized: "Imam of Madinah for seventy years; the reading of North and West Africa."),
            paragraphs: [
                String(localized: "Nafi was of Isfahani descent and lived in Madinah, where he led recitation in the Prophet's Mosque for some seventy years. He is reported to have read on around seventy of the Successors, Abu Ja'far al-Madani among them."),
                String(localized: "He was asked which of his teachers he followed and answered that he took what at least two of them agreed upon, a method that gives his reading its particular authority, since it represents the settled practice of Madinah rather than one chain."),
                String(localized: "Through Warsh his reading became the recitation of North and West Africa, where it remains dominant; through Qalun it is the reading of Libya and parts of Tunisia."),
            ],
            hallmarks: [
                String(localized: "Warsh and Qalun differ more than any other pair of narrators, so Nafi is learned as two readings in practice."),
                String(localized: "Warsh moves a hamzah's vowel onto the resting letter before it, قَدَ اَفۡلَحَ, وَبِالَاخِرَةِ, and turns a resting hamzah into a long vowel, يُومِنُونَ; Qalun keeps the hamzah, يُؤۡمِنُونَ."),
                String(localized: "The separated madd: six counts for Warsh, the longest, two for Qalun as his mushaf prints it. Warsh also stretches the alef after a hamzah, ءَامَنُواْ, by three transmitted lengths (madd al-badal)."),
                String(localized: "A half tilt (taqlil) for Warsh on words ending in ى and on ٱلدُّنۡيَا, مُوس۪ىٰ, ٱلۡهُد۪ىٰ, ٱلنّ۪ارِ, ٱلۡكٰ۪فِرِينَ; Qalun reads them level."),
                String(localized: "Two hamzahs meeting between words: Qalun drops the first, جَا أَحَدٞ, هَٰؤُلَآ۟ إِن; Warsh softens the second. The plural mim: Qalun may join it with a waw (two ways are transmitted), Warsh only before a hamzah, عَلَيۡهِمُۥٓ ءَآنذَرۡتَهُمُۥٓ."),
                String(localized: "Warsh thickens the lam after ص, ط and ظ, ٱلصَّلَوٰةَ, and thins the ra after a kasra, sounds a Hafs reader notices at once. Basmalah between every two surahs for Qalun; Warsh has three ways."),
            ],
            companions: String(localized: "Transmitted from Umar ibn al-Khattab, Zayd ibn Thabit, Ubayy ibn Ka'b, Abdullah ibn Abbas, Abdullah ibn Ayyash, and Abu Hurayrah (may Allah be pleased with them)."),
            narratorTags: [Settings.Riwayah.warsh, Settings.Riwayah.qaloon]
        ),
        QiraahMasterProfile(
            id: Settings.Riwayah.yaqubTeacher,
            arabic: Settings.Riwayah.yaqubTeacherArabic,
            fullName: String(localized: "Abu Muhammad Ya'qub ibn Ishaq ibn Zayd al-Hadrami"),
            city: "Basra", bornAH: 117, diedAH: 205, diedCE: 821,
            summary: String(localized: "Imam of Basra after Abu Amr, and the ninth of the ten."),
            paragraphs: [
                String(localized: "Ya'qub al-Hadrami succeeded to the leadership of recitation in Basra after Abu Amr's circle, and held it for the rest of his life. He was known for his command of Arabic dialects and of the variant readings, and was consulted on both."),
                String(localized: "His reading was added to the canonical seven, with Abu Ja'far and Khalaf, to make the ten recognised by Ibn al-Jazari. It remained in practical use in parts of the Muslim world long after, and is still taught today."),
                String(localized: "His two narrators, Ruways and Rawh, were both Basrans who read directly on him."),
            ],
            hallmarks: [
                String(localized: "The ha of عَلَيۡهُمۡ, إِلَيۡهُمۡ and لَدَيۡهُمۡ read with a damma, as Hamzah."),
                String(localized: "At a pause a soft ha is added to هُوَ and هِيَ, هُوَهۡ, هِيَهۡ, so the vowel is heard."),
                String(localized: "The separated madd kept short, two counts, and every hamzah in full; Ruways softens the second of two that meet between words, ٱلسُّفَهَآءُ اَلَآ."),
                String(localized: "Imalah only in ٱلۡكَٰٜفِرِينَ, through Ruways; Rawh reads level. Ruways also reads الصراط with a seen, صِۜرَٰطَ."),
                String(localized: "Basmalah between every two surahs."),
            ],
            companions: String(localized: "Transmitted from Umar ibn al-Khattab, Uthman ibn Affan, Ali ibn Abi Talib, Ubayy ibn Ka'b, Zayd ibn Thabit, Abdullah ibn Mas'ud, Abu Musa al-Ash'ari, Abdullah ibn Abbas, and Abu Hurayrah (may Allah be pleased with them)."),
            narratorTags: [Settings.Riwayah.ruways, Settings.Riwayah.rawh]
        ),
    ]

    // MARK: - The twenty narrators

    static let narrators: [RiwayahNarratorProfile] = [
        // Asim
        RiwayahNarratorProfile(
            id: Settings.Riwayah.hafsTag, name: "Hafs", arabic: "حَفص",
            fullName: String(localized: "Abu Amr Hafs ibn Sulayman al-Asadi al-Kufi"),
            masterID: Settings.Riwayah.asimTeacher, city: "Kufa", bornAH: 90, diedAH: 180,
            summary: String(localized: "The narration almost the entire Muslim world recites from today."),
            paragraphs: [
                String(localized: "Hafs was the stepson of Asim and read on him over many years. Of the two narrators of Asim, Hafs is the one described as the more precise in conveying exactly what Asim taught."),
                String(localized: "His narration became the basis of the Ottoman printed mushaf and then of the Madinah mushaf, and through printing it spread until it became the recitation of the overwhelming majority of Muslims, commonly estimated at more than nine in ten."),
                String(localized: "That dominance is a fact of history and printing, not of rank: every one of the twenty riwayat is equally the Quran."),
            ],
            hallmarks: [
                String(localized: "The default reading of this app and of most printed Qurans."),
                String(localized: "Every hamzah in full and almost no imalah: one tilt, مَجۡرٜىٰهَا in Hud, and one softened hamzah, ءَا۬عۡجَمِيّٞ in Fussilat."),
                String(localized: "Four breath-less pauses, عِوَجَاۜ, مَرۡقَدِنَاۜ, مَنۡۜ رَاقٖ, بَلۡۜ رَانَ, and the shaded nun of تَأۡمَ۬نَّا in Yusuf."),
                String(localized: "Four counts on both the joined and the separated madd."),
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.shubah, name: "Shu'bah", arabic: "شُعبَة",
            fullName: String(localized: "Abu Bakr Shu'bah ibn Ayyash ibn Salim al-Kufi"),
            masterID: Settings.Riwayah.asimTeacher, city: "Kufa", bornAH: 95, diedAH: 193,
            summary: String(localized: "Asim's other narrator, famed for caution and for long worship."),
            paragraphs: [
                String(localized: "Shu'bah read the Quran on Asim three times over and was one of the great worshippers of his age; the reports say he completed the Quran in prayer regularly for decades."),
                String(localized: "He was so cautious about transmitting that he is said to have wished he had never narrated at all rather than risk a single error, a scrupulousness that is itself part of why his narration is trusted."),
                String(localized: "His riwayah differs from Hafs in a few hundred places, most of them small differences of vowel or of assimilation."),
            ],
            hallmarks: [
                String(localized: "Differs from Hafs in roughly five hundred points across the Quran, nearly all a vowel or a dot."),
                String(localized: "Imalah in a handful of words, أَدۡرٜىٰكَ, رٜءَا, أَعۡمٜىٰ, and in the opening letters حٜمٓ, الٓرٜ, كٓهيٜعٓصٓ."),
                String(localized: "Every hamzah in full and four counts on both madds, as Hafs."),
            ]
        ),
        // Nafi
        RiwayahNarratorProfile(
            id: Settings.Riwayah.warsh, name: "Warsh", arabic: "وَرش",
            fullName: String(localized: "Abu Sa'id Uthman ibn Sa'id al-Misri"),
            masterID: Settings.Riwayah.nafiTeacher, city: "Egypt", bornAH: 110, diedAH: 197,
            summary: String(localized: "The reading of North and West Africa, and the app's Maghribi script."),
            paragraphs: [
                String(localized: "Warsh was Egyptian, and travelled to Madinah to read the whole Quran on Nafi several times over before returning to Egypt to teach. Nafi gave him the nickname Warsh, said to be after a kind of white curd, for his fair complexion."),
                String(localized: "He became the imam of recitation in Egypt, and from there his narration spread west across North Africa, where it is still the dominant recitation and the one the printed Maghribi mushafs are set in."),
                String(localized: "It is the most different from Hafs of the widely-recited narrations, and the one most likely to surprise a reader who has only ever heard Hafs."),
            ],
            hallmarks: [
                String(localized: "A hamzah's vowel moved onto the resting letter before it, قَدَ اَفۡلَحَ, وَبِالَاخِرَةِ, and every resting hamzah turned into a long vowel, يُومِنُونَ, اَ۬لۡمُومِنُونَ: his mushaf has 4,600 fewer hamzah signs than Hafs's."),
                String(localized: "Six counts on both madds, the longest, and three transmitted lengths on the alef after a hamzah, ءَامَنُواْ (madd al-badal)."),
                String(localized: "A half tilt (taqlil) on words ending in ى and on ٱلدُّنۡيَا, مُوس۪ىٰ, ٱلۡهُد۪ىٰ, ٱلنّ۪ارِ, ٱلۡكٰ۪فِرِينَ, about 2,500 places."),
                String(localized: "A thick lam after ص, ط and ظ, ٱلصَّلَوٰةَ, and a thin ra after a kasra."),
                String(localized: "The narration whose printed mushaf uses the Maghribi script, with the dot for hamzat al-wasl."),
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.qaloon, name: "Qalun", arabic: "قَالُون",
            fullName: String(localized: "Abu Musa Isa ibn Mina al-Zarqi al-Madani"),
            masterID: Settings.Riwayah.nafiTeacher, city: "Madinah", bornAH: 120, diedAH: 220,
            summary: String(localized: "Nafi's closest Madinan student; the reading of Libya."),
            paragraphs: [
                String(localized: "Qalun was Nafi's stepson and read on him for some twenty years. The name Qalun was given to him by Nafi himself and is said to be a Byzantine word for 'good', a comment on the quality of his recitation."),
                String(localized: "He is reported to have gone deaf in later life and yet to have continued correcting students by watching their lips, a story the biographers tell to convey how completely he had internalised the reading."),
                String(localized: "His narration is the recitation of Libya and of parts of Tunisia today."),
            ],
            hallmarks: [
                String(localized: "Shorter madd than Warsh, two counts on the separated madd as his mushaf prints it, and a lighter touch overall."),
                String(localized: "Keeps the hamzah where Warsh drops it, يُؤۡمِنُونَ, and drops the first of two hamzahs meeting between words, جَا أَحَدٞ, هَٰؤُلَآ۟ إِن."),
                String(localized: "Two hamzahs in one word: the second softened with an alef slipped between, ءَٰا۬نذَرۡتَهُمۡ."),
                String(localized: "The plural mim may be joined with a waw: both ways are transmitted, and the printed text keeps it closed, عَلَيۡهِمۡ."),
                String(localized: "Level reading (fath) where Warsh tilts, and the basmalah between every two surahs."),
            ]
        ),
        // Ibn Kathir
        RiwayahNarratorProfile(
            id: Settings.Riwayah.buzzi, name: "al-Bazzi", arabic: "البَزِّي",
            fullName: String(localized: "Abu al-Hasan Ahmad ibn Muhammad ibn Abd Allah al-Bazzi"),
            masterID: Settings.Riwayah.ibnKathirTeacher, city: "Makkah", bornAH: 170, diedAH: 250,
            summary: String(localized: "Muezzin of the Sacred Mosque and imam of recitation in Makkah."),
            paragraphs: [
                String(localized: "Al-Bazzi was the muezzin of the Sacred Mosque in Makkah for around forty years and the leading teacher of the Makkan reading in his generation. He received Ibn Kathir's reading through intermediate teachers, Ibn Kathir having died half a century before his birth."),
                String(localized: "His narration carries a well-known feature: the doubling of the ta in a set of verbs, which is particular to him among the narrators of Ibn Kathir."),
            ],
            hallmarks: [
                String(localized: "The doubled ta in a defined set of verbs, وَلَا تَّفَرَّقُواْ, when read on from the word before."),
                String(localized: "Drops the first of two hamzahs meeting between words, جَا أَحَدٞ."),
                String(localized: "Carries Ibn Kathir's drawn-out pronoun ha, فِيهِۦ, مِنۡهُۥ, and the joined plural mim, رَزَقۡنَٰهُمُۥ."),
                String(localized: "The takbir between the surahs from ad-Duha to the end of the Quran is transmitted through him."),
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.qunbul, name: "Qunbul", arabic: "قُنبُل",
            fullName: String(localized: "Abu Amr Muhammad ibn Abd ar-Rahman al-Makhzumi al-Makki"),
            masterID: Settings.Riwayah.ibnKathirTeacher, city: "Makkah", bornAH: 195, diedAH: 291,
            summary: String(localized: "The other Makkan narrator, who taught into his nineties."),
            paragraphs: [
                String(localized: "Qunbul read on al-Qawwas, and through him on the chain back to Ibn Kathir. He led recitation in Makkah for many years and students travelled to him from across the Muslim world."),
                String(localized: "He lived to a great age and continued teaching almost to the end, which is part of why his narration is so widely attested."),
            ],
            hallmarks: [
                String(localized: "Differs from al-Bazzi in a modest number of places, the best known being الصراط read with a seen, ٱلصِّۜرَٰطَ."),
                String(localized: "Softens the second of two hamzahs meeting between words where al-Bazzi drops the first."),
                String(localized: "Carries Ibn Kathir's drawn-out pronoun ha, عَنۡهُۥ, and the joined plural mim, قُلُوبِهِمُۥ."),
            ]
        ),
        // Abu Amr
        RiwayahNarratorProfile(
            id: Settings.Riwayah.duri, name: "ad-Duri", arabic: "الدُّورِي",
            fullName: String(localized: "Abu Umar Hafs ibn Umar ad-Duri al-Baghdadi"),
            masterID: Settings.Riwayah.abiAmrTeacher, city: "Baghdad", bornAH: nil, diedAH: 246,
            summary: String(localized: "The only man who narrates two of the ten readings."),
            paragraphs: [
                String(localized: "Ad-Duri took his name from ad-Dur, a district of Baghdad. He is the only narrator among the twenty who transmits two of the ten readings: Abu Amr's, through al-Yazidi, and al-Kisai's, on whom he read directly."),
                String(localized: "He is also credited with being among the first to gather the variant readings systematically and travel in search of them, which makes him a foundational figure for the science itself and not only a link in one chain."),
                String(localized: "His narration of Abu Amr is widely recited in parts of Sudan and the Horn of Africa."),
            ],
            hallmarks: [
                String(localized: "Appears twice in the twenty riwayat, once under Abu Amr and once under al-Kisai."),
                String(localized: "Abu Amr's imalah, ٱلنَّٜاسِ, ٱلنَّٜارِ, ٱلۡكَٰٜفِرِينَ, أُخۡرٜىٰ, with the half tilt on ٱلدُّنۡيَا and مُوسَىٰ, and the slurred vowels of يَأۡمُرۡكُمۡ, بَارِئۡكُمۡ."),
                String(localized: "Keeps the resting hamzah, يُؤۡمِنُونَ, where as-Susi turns it into a long vowel, and does not read the large idgham by the Shatibiyyah route."),
                String(localized: "His mushaf prints the separated madd stretched."),
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.susi, name: "as-Susi", arabic: "السُّوسِي",
            fullName: String(localized: "Abu Shu'ayb Salih ibn Ziyad as-Susi"),
            masterID: Settings.Riwayah.abiAmrTeacher, city: "Basra", bornAH: nil, diedAH: 261,
            summary: String(localized: "Abu Amr's other narrator, through al-Yazidi."),
            paragraphs: [
                String(localized: "As-Susi read on Yahya al-Yazidi, Abu Amr's foremost student, and transmitted the Basran reading alongside ad-Duri."),
                String(localized: "His narration takes Abu Amr's assimilation furthest: the large idgham, where a final letter merges into the first letter of the next word, is applied more consistently in as-Susi than anywhere else among the twenty."),
            ],
            hallmarks: [
                String(localized: "The fullest application of the large idgham (idgham kabir): قَال رَّبُّكَ, رَبِحَت تِّجَٰرَتُهُمۡ, حَيۡث شِّيتُمَا, written at about a thousand places in his mushaf."),
                String(localized: "Every resting hamzah turned into a long vowel, يُومِنُونَ, تُومَرُونَ, on top of Abu Amr's dropped first hamzah, هَٰؤُلَا إِن."),
                String(localized: "A markedly flowing, connected sound as a result, with the separated madd kept short."),
            ]
        ),
        // Ibn Amir
        RiwayahNarratorProfile(
            id: Settings.Riwayah.hisham, name: "Hisham", arabic: "هِشَام",
            fullName: String(localized: "Abu al-Walid Hisham ibn Ammar ad-Dimashqi"),
            masterID: Settings.Riwayah.ibnAmirTeacher, city: "Damascus", bornAH: 153, diedAH: 245,
            summary: String(localized: "Khatib, mufti and teacher of recitation in Damascus."),
            paragraphs: [
                String(localized: "Hisham ibn Ammar was the khatib of Damascus and its mufti, as well as a hadith scholar of standing from whom al-Bukhari narrates. He received the Damascene reading through the chain from Ibn Amir and taught it in the Umayyad Mosque."),
                String(localized: "He and Ibn Dhakwan are the two narrators through whom the reading of Sham survived, at a distance of roughly a century from the imam himself."),
            ],
            hallmarks: [
                String(localized: "Softens only the final hamzah of a word at a stop, and may slip an alef between two hamzahs in one word, ءَٰا۬نتَ."),
                String(localized: "Imalah only in the opening letters الٓرٜ, كٓهيٜعٓصٓ, and a few words such as عٰٜبِدُونَ, where Ibn Dhakwan tilts جَآءَ and شَآءَ throughout."),
                String(localized: "The Damascus spellings, سَارِعُوٓاْ, فَلَا يَخَافُ, shared with Ibn Dhakwan, and several readings unique to him within the Syrian tradition."),
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.ibnDhakwan, name: "Ibn Dhakwan", arabic: "ابنُ ذَكوَان",
            fullName: String(localized: "Abu Amr Abdullah ibn Ahmad ibn Bashir ibn Dhakwan"),
            masterID: Settings.Riwayah.ibnAmirTeacher, city: "Damascus", bornAH: 173, diedAH: 242,
            summary: String(localized: "Imam and teacher of recitation in Damascus."),
            paragraphs: [
                String(localized: "Ibn Dhakwan led the recitation in the Umayyad Mosque and was the leading teacher of the Syrian reading in his generation, alongside Hisham."),
                String(localized: "The two narrators of Ibn Amir differ from one another in a number of places, so the Damascene reading is normally studied as the pair rather than as one."),
            ],
            hallmarks: [
                String(localized: "Every hamzah in full, reading on and at a stop."),
                String(localized: "Imalah of جٜآءَ and شٜآءَ wherever they occur, about 370 places, which Hisham reads level."),
                String(localized: "The Damascus spellings, سَارِعُوٓاْ, فَلَا يَخَافُ, shared with Hisham, and a modest, well-catalogued set of places where the two part."),
            ]
        ),
        // Hamzah
        RiwayahNarratorProfile(
            id: Settings.Riwayah.khalaf, name: "Khalaf", arabic: "خَلَف",
            fullName: String(localized: "Abu Muhammad Khalaf ibn Hisham al-Bazzar al-Baghdadi"),
            masterID: Settings.Riwayah.hamzahTeacher, city: "Baghdad", bornAH: 150, diedAH: 229,
            summary: String(localized: "Narrator of Hamzah, and the tenth imam under his own name."),
            paragraphs: [
                String(localized: "Khalaf read on Sulaym, Hamzah's student, and is one of Hamzah's two canonical narrators. He is the same Khalaf who later made his own selection and became the tenth of the ten imams, which is why the guide lists him in both places."),
                String(localized: "Read as a narrator of Hamzah, he transmits Hamzah's reading with its long madd and its distinctive pauses; read as Khalaf al-Ashir, he is following his own considered choices."),
                String(localized: "The sakt is his: a short pause without breath on the consonant before a hamzah, in three places. The lam of أل (ٱلۡأَرۡضِ), the word شَيۡء, and a detached consonant ending the word before (قَدۡ أَفۡلَحَ, مِنۡ ءَامَنَ). Khallad never pauses on the detached word, and on the other two both ways are transmitted from him. At a stop both narrators ease the hamzah as Hamzah does, which is why a recording of either ends each ayah without it while the mushaf keeps it."),
                String(localized: "Two mushafs carry his name and read differently. One titled Khalaf an Hamzah is Hamzah's reading as ash-Shatibiyyah transmits it; one titled Khalaf al-Ashir is his own reading as ad-Durrah transmits it, with the hamzah in full at a stop and no sakt. A student should check which one the teacher wants. This app carries both."),
            ],
            hallmarks: [
                String(localized: "The only person in the twenty who is also one of the ten imams."),
                String(localized: "Carries Hamzah's six-count madd, his imalah, مُوسٜىٰ, جٜآءَ, and the damma of عَلَيۡهُمۡ."),
                String(localized: "Sakt before the hamzah of أل, of شَيۡء and of a detached word, قَدۡ أَفۡلَحَ, and الصراط with the sad shaded towards a zay (ishmam), a sound the page does not mark."),
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.khallad, name: "Khallad", arabic: "خَلَّاد",
            fullName: String(localized: "Abu Isa Khallad ibn Khalid as-Sayrafi al-Kufi"),
            masterID: Settings.Riwayah.hamzahTeacher, city: "Kufa", bornAH: nil, diedAH: 220,
            summary: String(localized: "Hamzah's Kufan narrator, through Sulaym."),
            paragraphs: [
                String(localized: "Khallad also read on Sulaym and transmitted Hamzah's reading in Kufa. He was regarded as exacting in the details of Hamzah's tajwid, which in this reading are unusually demanding."),
                String(localized: "The differences between Khalaf and Khallad are few, and the best known is the sakt, the short pause without breath before a hamzah. Khalaf pauses on the consonant before it in أل, in شَيۡء and at the end of a detached word (قَدۡ أَفۡلَحَ); Khallad never pauses on the detached word, and on أل and شَيۡء both ways are transmitted from him, with the pause and without. At a stop he eases the hamzah exactly as Khalaf does, so his recordings also end each ayah without it while the mushaf keeps it."),
            ],
            hallmarks: [
                String(localized: "Very close to Khalaf, differing in a small set of places."),
                String(localized: "No sakt on a detached word; both ways on أل and شَيۡء."),
                String(localized: "Preserves Hamzah's demanding pausing rules: the hamzah eased at a stop exactly as Khalaf does."),
            ]
        ),
        // al-Kisai
        RiwayahNarratorProfile(
            id: Settings.Riwayah.abuHarith, name: "Abu al-Harith", arabic: "أَبُو الحَارِث",
            fullName: String(localized: "Abu al-Harith al-Layth ibn Khalid al-Baghdadi"),
            masterID: Settings.Riwayah.kisaiTeacher, city: "Baghdad", bornAH: nil, diedAH: 240,
            summary: String(localized: "Al-Kisai's foremost student in Baghdad."),
            paragraphs: [
                String(localized: "Abu al-Harith read directly on al-Kisai and was counted his most accomplished student. He taught in Baghdad, where the Kufan reading had followed al-Kisai to the caliphal capital."),
                String(localized: "His narration and ad-Duri's are the two through which al-Kisai's reading is preserved."),
            ],
            hallmarks: [
                String(localized: "Carries al-Kisai's imalah in full, مُوسٜىٰ, ٱلۡهُدٜىٰ, ٱلدُّنۡيٜا, some 1,600 places, and the feminine ta tilted at a pause."),
                String(localized: "The lam of هَلۡ and بَلۡ merged into the letter after it, هَل ثُّوِّبَ."),
                String(localized: "Every hamzah in full and four counts on the madd, as Hafs."),
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.duriKisai, name: "ad-Duri", arabic: "الدُّورِي",
            fullName: String(localized: "Abu Umar Hafs ibn Umar ad-Duri al-Baghdadi"),
            masterID: Settings.Riwayah.kisaiTeacher, city: "Baghdad", bornAH: nil, diedAH: 246,
            summary: String(localized: "The same ad-Duri, here reading directly on al-Kisai."),
            paragraphs: [
                String(localized: "This is the same Hafs ibn Umar ad-Duri who narrates Abu Amr's reading. Under al-Kisai he read directly on the imam rather than through an intermediary, so his two narrations sit at different distances from their sources."),
                String(localized: "That one man carries two of the ten readings is a reminder of how small and interconnected the circle of early qurra was: the students of one imam were often the students of another."),
            ],
            hallmarks: [
                String(localized: "The second of ad-Duri's two narrations among the twenty."),
                String(localized: "Read directly on al-Kisai, unlike his narration of Abu Amr."),
                String(localized: "Al-Kisai's imalah with a few more words than Abu al-Harith tilts, about 1,950 places against 1,600."),
            ]
        ),
        // Abu Ja'far
        RiwayahNarratorProfile(
            id: Settings.Riwayah.ibnWardan, name: "Ibn Wardan", arabic: "ابنُ وَردَان",
            fullName: String(localized: "Abu al-Harith Isa ibn Wardan al-Madani"),
            masterID: Settings.Riwayah.abiJafarTeacher, city: "Madinah", bornAH: nil, diedAH: 160,
            summary: String(localized: "A Madinan who read on both Abu Ja'far and Nafi."),
            paragraphs: [
                String(localized: "Ibn Wardan read on Abu Ja'far and also on Nafi, which places him inside both Madinan traditions. He is counted the first of Abu Ja'far's two narrators."),
                String(localized: "He died a generation before most of the other narrators of the twenty, which is consistent with Abu Ja'far being among the earliest of the ten imams."),
            ],
            hallmarks: [
                String(localized: "Every resting hamzah a long vowel, يُومِنُونَ, and the name إِسۡرَآيلَ without its hamzah."),
                String(localized: "The joined plural mim, قُلُوبِهِمُۥ, and the softened second hamzah with an alef between, ءَٰا۬نذَرۡتَهُمُۥ."),
                String(localized: "The resting nun hidden before خ and غ, مِن غَيۡرِ, and a breath-less pause after each opening letter of a surah."),
                String(localized: "Level reading (fath) throughout, with the separated madd kept short."),
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.ibnJammaz, name: "Ibn Jammaz", arabic: "ابنُ جَمَّاز",
            fullName: String(localized: "Abu ar-Rabi Sulayman ibn Muslim ibn Jammaz al-Madani"),
            masterID: Settings.Riwayah.abiJafarTeacher, city: "Madinah", bornAH: nil, diedAH: 170,
            summary: String(localized: "Abu Ja'far's second narrator, who also read on Nafi."),
            paragraphs: [
                String(localized: "Ibn Jammaz read on Abu Ja'far and, like Ibn Wardan, also on Nafi. He taught in Madinah and is the second of the two narrators through whom Abu Ja'far's reading reaches us."),
                String(localized: "The differences between the two narrators of Abu Ja'far are relatively few."),
            ],
            hallmarks: [
                String(localized: "Close to Ibn Wardan throughout: the two part in 58 ayahs, the smallest gap between any pair of narrators but one."),
                String(localized: "Carries the Madinan reading of the generation before Nafi, with Abu Ja'far's long vowels for the resting hamzah and the joined plural mim."),
            ]
        ),
        // Ya'qub
        RiwayahNarratorProfile(
            id: Settings.Riwayah.ruways, name: "Ruways", arabic: "رُوَيس",
            fullName: String(localized: "Abu Abd Allah Muhammad ibn al-Mutawakkil al-Lu'lu'i al-Basri"),
            masterID: Settings.Riwayah.yaqubTeacher, city: "Basra", bornAH: nil, diedAH: 238,
            summary: String(localized: "Ya'qub's leading Basran student."),
            paragraphs: [
                String(localized: "Ruways read directly on Ya'qub al-Hadrami and was regarded as the most accomplished of his students. He taught in Basra and his narration travelled from there."),
                String(localized: "Ruways is a nickname; his given name was Muhammad ibn al-Mutawakkil."),
            ],
            hallmarks: [
                String(localized: "Carries Ya'qub's damma in عَلَيۡهُمۡ and his soft ha at a pause on هُوَ and هِيَ."),
                String(localized: "Softens the second of two hamzahs meeting between words, ٱلسُّفَهَآءُ اَلَآ, and reads الصراط with a seen, صِۜرَٰطَ."),
                String(localized: "Imalah in ٱلۡكَٰٜفِرِينَ only, about ninety places; otherwise level."),
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.rawh, name: "Rawh", arabic: "رَوح",
            fullName: String(localized: "Abu al-Hasan Rawh ibn Abd al-Mu'min al-Hudhali al-Basri"),
            masterID: Settings.Riwayah.yaqubTeacher, city: "Basra", bornAH: nil, diedAH: 234,
            summary: String(localized: "Ya'qub's other narrator, and a hadith scholar of standing."),
            paragraphs: [
                String(localized: "Rawh read on Ya'qub in Basra and was also a transmitter of hadith whose narrations are cited in the major collections."),
                String(localized: "He and Ruways are the pair through whom the ninth reading is preserved."),
            ],
            hallmarks: [
                String(localized: "Very close to Ruways, with a small set of differences."),
                String(localized: "Every hamzah in full and no imalah: the most level of Ya'qub's two riwayat."),
                String(localized: "Preserves Ya'qub's characteristic word-forms and the damma of عَلَيۡهُمۡ."),
            ]
        ),
        // Khalaf al-Ashir
        RiwayahNarratorProfile(
            id: Settings.Riwayah.ishaq, name: "Ishaq", arabic: "إِسحَاق",
            fullName: String(localized: "Abu Ya'qub Ishaq ibn Ibrahim al-Warraq al-Baghdadi"),
            masterID: Settings.Riwayah.khalafAshirTeacher, city: "Baghdad", bornAH: nil, diedAH: 286,
            summary: String(localized: "The narrator who took Khalaf's own selection directly."),
            paragraphs: [
                String(localized: "Ishaq al-Warraq read on Khalaf al-Bazzar and transmitted the selection Khalaf had made, rather than Khalaf's narration of Hamzah. He taught in Baghdad after Khalaf's death."),
                String(localized: "He is the first of the two narrators of the tenth reading."),
            ],
            hallmarks: [
                String(localized: "Transmits Khalaf's own ikhtiyar, not Hamzah's reading: the hamzah in full at a stop, no sakt, four counts on the madd."),
                String(localized: "Baghdadi in chain and in teaching."),
                String(localized: "Reads identically to Idris: al-Durrah reports no difference between them."),
            ]
        ),
        RiwayahNarratorProfile(
            id: Settings.Riwayah.idris, name: "Idris", arabic: "إِدرِيس",
            fullName: String(localized: "Abu al-Hasan Idris ibn Abd al-Karim al-Haddad al-Baghdadi"),
            masterID: Settings.Riwayah.khalafAshirTeacher, city: "Baghdad", bornAH: 189, diedAH: 292,
            summary: String(localized: "The last of the twenty narrators to die."),
            paragraphs: [
                String(localized: "Idris al-Haddad read on Khalaf al-Bazzar and became the leading teacher of the tenth reading in Baghdad. He was also a trusted transmitter of hadith."),
                String(localized: "He died in 292 AH, the latest death date among the twenty narrators, which makes him the closing link of the whole canonical chain."),
            ],
            hallmarks: [
                String(localized: "The most widely transmitted of the two narrations of Khalaf al-Ashir."),
                String(localized: "The last of the twenty by death date."),
                String(localized: "Reads identically to Ishaq: al-Durrah reports no difference between them."),
            ]
        ),
    ]
}

// MARK: - Detail views

struct QiraahMasterDetailView: View {
    let profile: QiraahMasterProfile

    var body: some View {
        List {
            Group {
                Section {
                    QiraatProfileHero(kicker: String(localized: "THE IMAM · ONE OF THE TEN"), name: profile.fullName,
                                      meta: String(localized: "\(profile.city.localizedDisplay) · \(profile.lifespan)"), arabic: profile.arabic,
                                      summary: profile.summary)
                }

                Section(header: Text("BIOGRAPHY")) {
                    ForEach(profile.paragraphs, id: \.self) { paragraph in
                        ProseText(text: paragraph)
                    }
                }

                // The reading's own sound, feature by feature, in the shape a student is used to from
                // the bookshop guides ("What stands out in Hamzah's reading"): a sentence each, with the
                // word as this app's own text of the riwayah writes it (Abu, 2026-10-26).
                Section {
                    ForEach(profile.hallmarks, id: \.self) { item in
                        Text("• \(item)").font(.body)
                    }
                } header: {
                    Text("WHAT STANDS OUT IN THIS READING")
                } footer: {
                    Text(QiraatProfiles.pageShowsOnlyPart)
                }

                Section(header: Text("RECITED TODAY")) {
                    ProseText(text: QiraatProfiles.recitedToday(master: profile.id).localizedDisplay)
                }

                #if os(iOS)
                QiraatIsnadSection(title: String(localized: "The reading of \(profile.id.localizedDisplay)"),
                                   subtitle: String(localized: "\(profile.arabic) · the chain of the reading to the Prophet ﷺ"),
                                   sentence: profile.companions + " " + QiraatIsnad.sentence(master: profile.id),
                                   chain: QiraatIsnad.chain(master: profile.id))
                #else
                Section(header: Text("CHAIN TO THE COMPANIONS")) {
                    ProseText(text: profile.companions)
                }
                #endif

                let riwayat = QiraatProfiles.narrators(ofMaster: profile.id)
                Section {
                    ForEach(riwayat) { narrator in
                        // The imam lists its riwayat and each riwayah links back to its imam, which is
                        // a corridor you could walk forever. Arriving here FROM a riwayah greys that
                        // riwayah's row rather than removing it, so the pair always reads as a pair.
                        #if os(iOS)
                        OpenScreenLink(screen: .riwayahNarrator,
                                       alreadyHereCaption: String(localized: "You are on \(narrator.name.localizedDisplay)'s page")) {
                            RiwayahNarratorDetailView(profile: narrator)
                        } label: {
                            QiraatProfileRow(title: narrator.name.localizedDisplay, arabic: narrator.arabic,
                                             detail: String(localized: "\(narrator.city.localizedDisplay) · d. \(String(narrator.diedAH).localizedDigits) AH"),
                                             systemImage: "link")
                        }
                        #else
                        NavigationLink(destination: LazyDestination { RiwayahNarratorDetailView(profile: narrator) }) {
                            QiraatProfileRow(title: narrator.name.localizedDisplay, arabic: narrator.arabic,
                                             detail: String(localized: "\(narrator.city.localizedDisplay) · d. \(String(narrator.diedAH).localizedDigits) AH"),
                                             systemImage: "link")
                        }
                        #endif
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
        .navigationTitle(profile.id.localizedDisplay)
        .selectableArticleList()
        #if os(iOS)
        .openScreen(.qiraahMaster)
        #endif
    }
}

struct RiwayahNarratorDetailView: View {
    let profile: RiwayahNarratorProfile

    var body: some View {
        ScrollViewReader { proxy in
            narratorList
                #if DEBUG && os(iOS)
                // "-scrollToDifferences" / "-scrollToChain" / "-scrollToChainEnd": bring that section
                // (or the chain's foot, where it forks into the two narrators) into a headless screenshot.
                .onAppear {
                    let arguments = ProcessInfo.processInfo.arguments
                    let chainEnd = arguments.contains("-scrollToChainEnd")
                    let target = arguments.contains("-scrollToDifferences") ? "riwayah-differences"
                        : chainEnd ? "isnad-chain-end"
                        : arguments.contains("-scrollToChain") ? "riwayah-chain" : nil
                    guard let target else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation { proxy.scrollTo(target, anchor: chainEnd ? .bottom : .top) }
                    }
                }
                #endif
        }
    }

    private var narratorList: some View {
        List {
            Group {
                Section {
                    QiraatProfileHero(kicker: String(localized: "THE NARRATOR · RIWAYAH OF \(profile.masterID.localizedDisplay.uppercased())"), name: profile.fullName,
                                      meta: String(localized: "\(profile.city.localizedDisplay) · \(profile.lifespan)"), arabic: profile.arabic,
                                      summary: profile.summary)
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
                    Section(header: Text("THE SAME TEXT AS \(QiraatProfiles.shortName(of: partner).localizedDisplay.uppercased())")) {
                        ProseText(text: QiraatProfiles.sharedTextExplanation)
                    }
                }

                Section {
                    ForEach(profile.hallmarks, id: \.self) { item in
                        Text("• \(item)").font(.body)
                    }
                } header: {
                    Text("WHAT STANDS OUT IN THIS RIWAYAH")
                } footer: {
                    Text(QiraatProfiles.pageShowsOnlyPart)
                }

                #if os(iOS)
                // The chain: teacher by teacher up to the Prophet ﷺ, and the students below (Abu,
                // 2026-09-12: "a chain from the narrator, both teacher and student, all the way to
                // the Prophet, and an image of it").
                QiraatIsnadSection(title: String(localized: "\(profile.name.localizedDisplay) an \(profile.masterID.localizedDisplay)"),
                                   subtitle: String(localized: "\(profile.arabic) · the chain of the narration to the Prophet ﷺ"),
                                   sentence: QiraatIsnad.sentence(master: profile.masterID, highlighting: profile.id),
                                   chain: QiraatIsnad.chain(narrator: profile.id))
                    .id("riwayah-chain")

                if !profile.id.isEmpty {
                    RiwayahDifferencesSection(tag: profile.id, name: profile.name.localizedDisplay)
                        .id("riwayah-differences")
                }
                #endif

                Section(header: Text("RECITED TODAY")) {
                    ProseText(text: QiraatProfiles.recitedToday(narrator: profile.id).localizedDisplay)
                }

                if let master = QiraatProfiles.master(id: profile.masterID) {
                    Section(header: Text("THE READING IT NARRATES")) {
                        // The other half of the pair: reached FROM this imam's page, the row greys out
                        // instead of offering a second lap.
                        #if os(iOS)
                        OpenScreenLink(screen: .qiraahMaster,
                                       alreadyHereCaption: String(localized: "You are on \(master.id.localizedDisplay)'s page")) {
                            QiraahMasterDetailView(profile: master)
                        } label: {
                            QiraatProfileRow(title: master.id.localizedDisplay, arabic: master.arabic,
                                             detail: String(localized: "\(master.city.localizedDisplay) · d. \(String(master.diedAH).localizedDigits) AH"),
                                             ordinal: QiraatProfiles.ordinal(ofMaster: master.id))
                        }
                        #else
                        NavigationLink(destination: LazyDestination { QiraahMasterDetailView(profile: master) }) {
                            QiraatProfileRow(title: master.id.localizedDisplay, arabic: master.arabic,
                                             detail: String(localized: "\(master.city.localizedDisplay) · d. \(String(master.diedAH).localizedDigits) AH"),
                                             ordinal: QiraatProfiles.ordinal(ofMaster: master.id))
                        }
                        #endif
                    }
                }

                QiraatSourceSection()
            }
            .themedListRowBackground()
        }
        .navigationTitle(profile.name.localizedDisplay)
        .selectableArticleList()
        #if os(iOS)
        .openScreen(.riwayahNarrator)
        #endif
    }
}

/// The row shape shared by every list of imams and narrators in the guide: a badge (the imam's
/// number among the ten, or a symbol), the name with its detail line, and the Arabic name in the
/// Islam tab's face on the trailing edge.
struct QiraatProfileRow: View {
    @Environment(\.appearance) private var appearance
    let title: String
    let arabic: String
    let detail: String
    /// Where the reading is recited today, when the list wants it on the row.
    var note: String? = nil
    /// The imam's place among the ten (1 to 10), drawn as the leading badge.
    var ordinal: Int? = nil
    /// A symbol badge instead of a number (narrators, chains).
    var systemImage: String? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            badge

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let note {
                    Label(note, systemImage: "mappin.and.ellipse")
                        .font(.caption2)
                        .foregroundColor(appearance.accent.opacity(0.9))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Text(arabic)
                .font(appearance.islamArabicFont(base: 18, relativeTo: .body))
                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                .foregroundColor(appearance.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 3)
        .rowSeparatorAtTitle(inset: hasBadge ? Self.titleInset : 0)
    }

    /// The badge (30) plus the stack's spacing (12): where the title starts.
    static let titleInset: CGFloat = 42

    private var hasBadge: Bool { ordinal != nil || systemImage != nil }

    @ViewBuilder
    private var badge: some View {
        if let ordinal {
            Text("\(ordinal)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(
                    Circle().fill(
                        LinearGradient(colors: [appearance.accent.opacity(0.95), appearance.accent.opacity(0.65)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                )
        } else if let systemImage {
            AccentIconChip(systemImage: systemImage, size: 30)
        }
    }
}

/// One reading in "The Companions behind each Qiraah": the reading's row (its place among the ten,
/// the imam, his two narrators, his Arabic name) with the Companions it is transmitted from as chips
/// beneath it (Abu, 2026-09-26: "listing all the qiraat like that looks terrible"; it was ten
/// paragraphs of run-on names). The imam, city and narrators come from the profiles; the Companions
/// are the article's own list, passed in at the call site, where `Scripts/build_islam_corpus.py`
/// reads them into the Ask AI corpus (`LINEAGE_RE`).
struct QiraahLineageRow: View {
    @Environment(\.appearance) private var appearance

    let masterID: String
    let companions: [String]
    var note: String? = nil

    var body: some View {
        if let master = QiraatProfiles.master(id: masterID) {
            let narrators = QiraatProfiles.narrators(ofMaster: masterID).map(\.name)
            VStack(alignment: .leading, spacing: 8) {
                QiraatProfileRow(
                    title: "\(master.id) · \(master.city)",
                    arabic: master.arabic,
                    detail: narrators.isEmpty ? "" : "Narrated by \(narrators.joined(separator: " and "))",
                    note: note,
                    ordinal: QiraatProfiles.ordinal(ofMaster: masterID)
                )

                companionChips
                    .padding(.leading, QiraatProfileRow.titleInset)
            }
            .padding(.vertical, 2)
            .rowSeparatorAtTitle(inset: QiraatProfileRow.titleInset)
        }
    }

    @ViewBuilder
    private var companionChips: some View {
        if #available(iOS 16.0, watchOS 9.0, *) {
            LeadingChipFlow(spacing: 5) {
                ForEach(companions, id: \.self) { name in
                    Text(name)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(appearance.accent.opacity(0.12)))
                }
            }
        } else {
            Text(companions.joined(separator: " \u{00B7} "))
                .font(.caption2.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension View {
    /// Starts the List row separator at the row's title. A List aligns the separator to a row's
    /// text, and a note line under the title (an icon, then text) dragged it part-way across.
    /// The guide does not exist on watchOS, whose lists draw no separators to align.
    @ViewBuilder
    func rowSeparatorAtTitle(inset: CGFloat) -> some View {
        #if os(watchOS)
        self
        #else
        if #available(iOS 16.0, *) {
            alignmentGuide(.listRowSeparatorLeading) { $0[.leading] + inset }
        } else {
            self
        }
        #endif
    }
}

/// Chips of any width, wrapped onto as many rows as they need, leading-aligned.
@available(iOS 16.0, watchOS 9.0, *)
struct LeadingChipFlow: Layout {
    var spacing: CGFloat = 5

    private func rows(_ subviews: Subviews, width: CGFloat) -> [[(index: Int, size: CGSize)]] {
        var rows: [[(index: Int, size: CGSize)]] = [[]]
        var x: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !rows[rows.count - 1].isEmpty, x + size.width > width {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append((index, size))
            x += size.width + spacing
        }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        // Plain loops: the chained map/reduce form timed out the Watch target's type checker.
        var height: CGFloat = 0
        var widest: CGFloat = 0
        for (index, row) in rows(subviews, width: width).enumerated() {
            var rowWidth: CGFloat = 0
            var rowHeight: CGFloat = 0
            for item in row {
                rowWidth += item.size.width
                rowHeight = max(rowHeight, item.size.height)
            }
            rowWidth += spacing * CGFloat(max(0, row.count - 1))
            widest = max(widest, rowWidth)
            height += rowHeight + (index > 0 ? spacing : 0)
        }
        return CGSize(width: width == .infinity ? widest : width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(subviews, width: bounds.width) {
            let rowHeight = row.map(\.size.height).max() ?? 0
            var x = bounds.minX
            for item in row {
                subviews[item.index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += rowHeight + spacing
        }
    }
}

/// The top of an imam's or a narrator's page: the kicker, the full name and dates, the Arabic name
/// large on the trailing edge, and the one-line summary in the accent.
struct QiraatProfileHero: View {
    @Environment(\.appearance) private var appearance
    let kicker: String
    let name: String
    let meta: String
    let arabic: String
    let summary: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(kicker)
                        .font(.caption2.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)
                    Text(name)
                        .font(.title3.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(meta)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 8)
                Text(arabic)
                    .font(appearance.islamArabicFont(base: 30, relativeTo: .largeTitle))
                    .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                    .foregroundColor(appearance.accent)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.trailing)
            }

            Text(summary)
                .font(.subheadline)
                .foregroundColor(appearance.accent)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }
}

/// Every profile page carries the same further-reading credit.
struct QiraatSourceSection: View {
    var body: some View {
        Section(header: Text("FURTHER READING")) {
            Link(destination: QiraatProfiles.sourceURL) {
                Label("QiraatHub: profiles of the ten readings and their narrators", systemImage: "link")
            }
            .font(.caption)

            Text("These pages are written for this app. QiraatHub is the companion reference for the ten readings and is credited in Settings → Credits.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
