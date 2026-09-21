import SwiftUI

extension String {
    /// Beginner mode's letter-spaced Arabic: one space between every grapheme cluster.
    /// THE single producer of beginner-spaced text - every surface that renders it and
    /// every consumer that reasons about it must agree on the same construction:
    /// `TajweedStore.tajweedProjection` promises byte-identity with this join, and
    /// `QiraahTajweedStore.tokenSpans` recovers word boundaries from the fact that an
    /// original word gap comes out as a run of 2+ spaces while the inserted letter gaps
    /// are single. Change the spacing here and those two must change with it.
    var beginnerSpaced: String {
        map { String($0) }.joined(separator: " ")
    }
}

struct Juz: Codable, Identifiable, Equatable {
    let id: Int
    let nameArabic: String
    let nameTransliteration: String
    let startSurah: Int
    let startAyah: Int
    let endSurah: Int
    let endAyah: Int
}

/// The highlighter's palette. Six hues, chosen to echo the system highlight colors and to read on both
/// the light and the dark page - the same base hue is reused across themes and only the wash's alpha
/// changes (`tintOpacity`), because a light-theme wash that reads as a highlight disappears on black.
///
/// A highlight is not a separate record: it is a FIELD on `BookmarkedAyah`. Highlighting an ayah
/// bookmarks it, and the bookmark then wears the highlight's color everywhere it appears - the reader's
/// bookmark glyph, the mushaf page badge, and the bookmarks list. Removing the bookmark removes the
/// highlight with it; removing the highlight leaves the (plain, accent-colored) bookmark behind.
enum AyahHighlightColor: String, Codable, CaseIterable, Identifiable {
    case yellow, green, blue, pink, orange, purple

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yellow: return "Yellow"
        case .green:  return "Green"
        case .blue:   return "Blue"
        case .pink:   return "Pink"
        case .orange: return "Orange"
        case .purple: return "Purple"
        }
    }

    /// The saturated hue: swatches, the bookmark glyph, and the picker's checkmarks.
    var color: Color {
        switch self {
        case .yellow: return Color(red: 1.00, green: 0.84, blue: 0.04)
        case .green:  return Color(red: 0.20, green: 0.83, blue: 0.47)
        case .blue:   return Color(red: 0.04, green: 0.52, blue: 1.00)
        case .pink:   return Color(red: 1.00, green: 0.22, blue: 0.37)
        case .orange: return Color(red: 1.00, green: 0.62, blue: 0.04)
        case .purple: return Color(red: 0.75, green: 0.35, blue: 0.95)
        }
    }

    /// The wash laid behind the ayah. Dark mode needs more presence to register against the dim page.
    /// Deliberately faint (user rule: "make highlighting opacity wayyy less") - a highlight is a standing
    /// margin note, not a selection, so it must never compete with the text it sits behind.
    func tintOpacity(_ scheme: ColorScheme) -> Double {
        scheme == .dark ? 0.14 : 0.10
    }

    func tint(_ scheme: ColorScheme) -> Color {
        color.opacity(tintOpacity(scheme))
    }

    /// Lenient decode: an unknown stored value (an older build, a future color) resolves to `nil` rather
    /// than throwing. `bookmarkedAyahs` decodes the whole array with `try?`, so a strict enum field would
    /// let one bad value silently wipe every bookmark the user has.
    static func resolve(_ raw: String?) -> AyahHighlightColor? {
        guard let raw else { return nil }
        return AyahHighlightColor(rawValue: raw)
    }
}

struct BookmarkedAyah: Codable, Identifiable, Equatable, Hashable {
    var id: String { "\(surah)-\(ayah)" }

    var surah: Int
    var ayah: Int
    var note: String? = nil
    /// The highlighter's color, stored raw (not as the enum) so an unrecognized value degrades to "no
    /// highlight" instead of failing the array's decode - see `AyahHighlightColor.resolve`.
    var highlightRaw: String? = nil
    /// When the bookmark was made (2026-09-07 on; older rows decode without it), so a bookmark
    /// anniversary can exist one day (Tilawa Guide, Phase 9 step 8).
    var createdAt: Date? = nil

    var hasNote: Bool {
        !(note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    var highlight: AyahHighlightColor? {
        get { AyahHighlightColor.resolve(highlightRaw) }
        set { highlightRaw = newValue?.rawValue }
    }

    var isHighlighted: Bool { highlight != nil }
}

struct VerseIndexEntry: Identifiable, Hashable, Codable {
    let id: String
    let surah: Int
    let ayah: Int
    /// Positions into the `[Surah]` the index was built from. The two rare exact lanes (`#` with
    /// tashkeel, exact English) read the raw texts through them on demand; every entry used to carry
    /// both as two more copies of its own text, about a third of the index's ~15 MB.
    let surahOffset: Int32
    let ayahOffset: Int32
    let arabicBlob: String
    let silentArabicBlob: String
    /// The hamza-preserving twin of `arabicBlob`, consulted ONLY when the query carries a bare ء (see
    /// `Settings.HamzaPrecisionFilter`). Nil for an ayah with no hamza at all - which can never satisfy
    /// such a query, so there is nothing worth storing.
    let hamzaArabicBlob: String?
    let englishBlob: String
    let arabicTokens: [String]
    let silentArabicTokens: [String]
    let englishTokens: [String]
}

enum BoundaryDividerStyle: Codable, Equatable {
    case allGreen
    case allSecondary
    case pageAccentJuzSecondary
    case allAccent
}

struct BoundaryDividerModel: Codable, Equatable {
    let text: String
    let pageSegment: String
    let juzSegment: String?
    let style: BoundaryDividerStyle

    /// Where this page falls WITHIN the surah, and how many pages the surah spans - the "(3/10)" already shown
    /// inside `pageSegment`, kept as numbers so the floating overlay can draw a progress bar from them instead
    /// of parsing them back out of the label. `nil` when the boundary is a juz with no page.
    var pageInSurah: Int? = nil
    var surahPageCount: Int? = nil
}

extension Surah {
    /// Absolute mushaf page where this surah begins (falls back to the smallest ayah page).
    var resolvedPageStart: Int? {
        pageStart ?? ayahs.compactMap(\.page).min()
    }

    /// 1-based page number *within* this surah for an absolute mushaf `page`
    /// (e.g. a surah starting on page 100 returns 3 for page 102). `nil` when
    /// the surah's start page is unknown or `page` falls before it.
    func pageWithinSurah(_ page: Int) -> Int? {
        guard let start = resolvedPageStart else { return nil }
        let relative = page - start + 1
        return relative >= 1 ? relative : nil
    }
}

/// "Page 102 (3/6)" - the absolute mushaf page annotated with its position within `surah`, out of how many
/// pages that surah spans, when that can be determined; otherwise just "Page 102". The total is what makes the
/// relative number mean anything - "(3)" alone doesn't say whether you're near the end. Pass `nil` for
/// cross-surah boundaries (the relative number would belong to a different surah).
func mushafPageLabel(forAbsolutePage page: Int, in surah: Surah?) -> String {
    if let surah, let relative = surah.pageWithinSurah(page) {
        return "Page \(page) (\(relative)/\(max(surah.pageCount, relative)))"
    }
    return "Page \(page)"
}

struct SurahBoundaryModel: Codable, Equatable {
    let startDivider: BoundaryDividerModel?
    let startDividerHighlighted: Bool
    let dividerBeforeAyah: [Int: BoundaryDividerModel]
    let endOfSurahDivider: BoundaryDividerModel?
    let endDivider: BoundaryDividerModel?
    let endDividerHighlighted: Bool
}

/// The other names and spellings a surah is searched by (Abu, 2026-09-20).
///
/// `SpellingFold` equates the PHONETIC spellings on its own (Yasin, Yaseen, Ya-Sin), so this table
/// holds only what no fold can derive: a genuinely different NAME (Bara'ah for at-Tawbah, Bani
/// Isra'il for al-Isra), another language's romanization where a letter changes class (the Turkish
/// Casiye for al-Jathiyah), a Biblical name (Joseph, Jonah), and a second Arabic name.
///
/// GENERATED by `Scripts/build_surah_aliases.py` from `Scripts/surah_aliases.json`; edit the JSON
/// and rerun, never the region below. An alias must identify ONE surah: the builder refuses a name
/// two surahs share, because a wrong alias sends the reader to the wrong surah.
enum SurahSpelling {
    // BEGIN GENERATED SURAH ALIASES
    static let latin: [Int: [String]] = [
        1: ["umm al-kitab", "umm al-quran", "fatihat al-kitab", "fatihat al-quran", "as-sab al-mathani", "sab al-mathani", "al-hamd", "al-quran al-azim", "ash-shifa", "ash-shafiyah", "ar-ruqyah", "al-wafiyah", "al-kafiyah", "ash-shukr", "al-munajat", "at-tafwid", "fotiha"],
        2: ["bakara", "al-bekara", "fustat al-quran", "sanam al-quran", "al-kursi"],
        3: ["taybah", "taj al-quran", "âl-i imrân", "al-e-imran", "oli imron"],
        4: ["an-nisa al-kubra", "an-nisa at-tula", "niso"],
        5: ["al-uqud", "al-munqidhah", "al-ahbar", "al-akhyar", "maide", "al-maeda", "moida"],
        6: ["al-hujjah", "al-mardiyyah", "en'âm", "anom"],
        7: ["alif lam mim sad", "al-miqat", "al-airaaf", "arof"],
        8: ["badr", "enfal", "al-enfal", "anfol"],
        9: ["baraah", "al-baraah", "al-fadihah", "al-adhab", "al-buhuth", "al-munaqqirah", "al-hafirah", "al-muthirah", "al-mudamdimah", "al-mukhziyah", "al-munakkilah", "al-musharridah", "al-muhlikah", "al-mustaqsiyah", "tevbe", "at-tevba", "at-tauba", "at-taubah", "tavba"],
        10: ["jonah", "jonas", "jona", "junus"],
        11: ["houd"],
        12: ["joseph", "josip", "jusuf", "youssef", "yousuf"],
        13: ["ar-raad"],
        14: ["abraham", "ibrohim", "ebrahim"],
        15: ["rubama", "hicr", "al-hidžr", "al-hidschr"],
        16: ["an-niam", "an-naim"],
        17: ["bani israil", "bani israel", "banu israil", "subhan", "al-aqsa", "isro"],
        18: ["ashab al-kahf", "al-hailah", "kehf", "al-kehf"],
        19: ["mary", "marie", "marija", "meryem", "merjem", "kaf ha ya ayn sad"],
        20: ["al-kalim", "at-taklim", "tâhâ", "toha"],
        21: ["iqtaraba", "al-ambiya", "ambiya", "ambiyaa", "enbiyâ", "al-enbija", "anbiyo"],
        22: ["hac", "al-hadždž", "al-haddsch", "al-hagg", "hagg"],
        23: ["qad aflaha", "qad aflaha al-muminun", "al-falah", "mü'minun", "al-mumenoon", "mominun"],
        25: ["tabarak al-furqan", "furkan", "al-furqane", "furqon"],
        26: ["ta sin mim ash-shuara", "al-jamiah", "az-zullah", "şu'ara", "aš-šuara", "asy-syuara", "ach-chuara", "shuaro"],
        27: ["sulayman", "al-hudhud", "ta sin", "ta sin sulayman", "neml", "an-neml"],
        28: ["kasas", "al-kasas", "qasos"],
        29: ["ankebût", "al-ankebut", "al-ankaboot"],
        30: ["rome", "romans", "byzantium", "al-room"],
        31: ["lokman", "lukman", "luqmon", "loqman"],
        32: ["alif lam mim tanzil", "alif lam mim tanzil as-sajdah", "al-madaji", "sajdat luqman", "secde", "as-sedžda", "as-sadschda"],
        33: ["ahzâb", "ahzob"],
        34: ["sheba", "sebe"],
        35: ["al-malaikah", "malaika", "fotir", "fâtır"],
        36: ["qalb al-quran", "habib an-najjar", "al-muimmah", "ad-dafiah", "al-qadiyah", "ja-sin", "yosin"],
        37: ["adh-dhabih", "az-zinah", "soffot"],
        38: ["dawud", "suaad", "sod"],
        39: ["al-ghuraf", "zümer"],
        40: ["al-mumin", "ha mim al-mumin", "at-tawl", "momin", "al-momin", "mü'min", "gafir", "gofir"],
        41: ["ha mim as-sajdah", "ha mim sajdah", "ha mim sajda", "haa-meem-sajdah", "al-masabih", "al-aqwat", "sajdat al-mumin", "fussilet"],
        42: ["ha mim ayn sin qaf", "ayn sin qaf", "şûrâ", "aš-šura", "asy-syura", "asch-schura", "ach-chura", "as-shoura", "shuro"],
        43: ["ha mim az-zukhruf", "zuhruf", "az-zuhruf", "az-zuchruf", "zuxruf"],
        44: ["ha mim ad-dukhan", "al-mubarakah", "duhan", "ad-duhan", "ad-duchan", "duxon"],
        45: ["ha mim al-jathiyah", "ash-shariah", "casiye", "al-džasija", "al-dschathiya", "al-jasiyah", "al-jasia", "al-jassiya", "al-jatiya", "josiya"],
        46: ["ha mim al-ahqaf", "ahkaf", "al-ahkaf", "ahqof"],
        47: ["al-qital", "alladhina kafaru", "muhammed", "mohammed", "mohamed", "mohammad", "mahomet"],
        48: ["fetih", "al-feth", "al-fateh", "fateh", "al-fatah", "fatah"],
        49: ["hucurât", "al-hudžurat", "al-hudschurat", "al-hujraat", "hujurot"],
        50: ["al-basiqat", "qaf wal-quran al-majid", "kaf", "qof"],
        51: ["wadh-dhariyat", "wa adh-dhariyat", "zariyat", "az-zariyat", "az-zaariyat", "ad-dariyat", "ad-darijat", "zoriyot"],
        52: ["wat-tur", "wa at-tur"],
        53: ["wan-najm", "wa an-najm", "necm", "an-nedžm", "an-nadschm"],
        54: ["iqtarabat", "iqtarabat as-saah", "kamer", "al-kamer"],
        55: ["arus al-quran", "rehman", "ar-rehman", "rohman", "ar-rohman"],
        56: ["idha waqaat", "vakıa", "vakia", "al-vakia", "voqea", "waqia", "al-waqia"],
        58: ["az-zihar", "qad samia", "qad sami allah", "mücadele", "al-mudžadela", "al-mudschadala", "mujodala", "al-mujadalah"],
        59: ["bani an-nadir", "banu an-nadir", "bani nadir", "haşr", "al-hašr", "al-hasyr", "al-haschr", "al-hachr"],
        60: ["al-imtihan", "al-mawaddah", "al-mumtahinah", "mümtehine"],
        61: ["al-hawariyyin", "al-hawariyyun", "saf", "soff"],
        62: ["cuma", "al-džumua", "al-dschumua", "jumma", "juma", "al-jumua", "gomaa", "al-gomaa"],
        63: ["idha jaaka al-munafiqun", "münafikun", "al-munafikun", "munofiqun"],
        64: ["teğabun", "at-tegabun", "at-tagabun", "tagobun"],
        65: ["an-nisa al-qusra", "an-nisa as-sughra", "talâk", "at-talak", "taloq"],
        66: ["lima tuharrim", "lim tuharrim", "al-mutaharrim"],
        67: ["tabarak", "tabarak alladhi biyadihi al-mulk", "tabarak al-mulk", "al-munjiyah", "al-maniah", "al-mannaah", "mülk", "tebareke"],
        68: ["nun", "nun wal-qalam", "noon", "kalem", "al-kalem"],
        69: ["as-silsilah", "hakka", "al-hakka"],
        70: ["saala sail", "saala", "me'aric", "al-mearidž", "al-maaridsch", "maorij"],
        71: ["noah", "noe", "noa", "inna arsalna nuhan", "nooh", "nouh"],
        72: ["qul uhiya", "qul uhiya ilayya", "cin", "al-džinn", "al-dschinn", "jin", "al-jin"],
        73: ["müzzemmil", "al-muzemmil"],
        74: ["müddessir", "müddesir", "al-muddessir", "al-muddassir", "al-mudassir", "al-muddattir"],
        75: ["la uqsimu bi-yawm al-qiyamah", "kıyamet", "kiyamet", "al-kijama", "qiyomat", "qayamat", "qiyamat"],
        76: ["ad-dahr", "dahr", "dahar", "hal ata", "hal ata ala al-insan", "al-abrar", "al-amshaj", "inson"],
        77: ["wal-mursalat", "wal-mursalat urfan", "al-urf", "mürselat", "al-mursalate"],
        78: ["amma", "amma yatasaalun", "am yatasaalun", "at-tasaul", "al-musirat", "nebe"],
        79: ["as-sahirah", "at-tammah", "noziot", "an-naziate"],
        80: ["as-safarah", "as-sakhkhah", "al-ama", "ibn umm maktum", "abese", "abas"],
        81: ["kuwwirat", "idha ash-shamsu kuwwirat", "tekvir", "at-takvir", "takvir"],
        82: ["infatarat", "idha as-samau infatarat", "al-munfatirah", "infitor"],
        83: ["at-tatfif", "tatfif", "wayl lil-mutaffifin", "al-mutaffifun", "al-mutaffifune"],
        84: ["inshaqqat", "idha as-samau inshaqqat", "ash-shafaq", "inşikak", "al-inšikak", "al-insyiqaq", "al-inschiqaq", "al-inchiqaq", "inshiqoq"],
        85: ["as-sama dhat al-buruj", "was-samai dhat al-buruj", "büruc", "al-burudž", "al-burudsch"],
        86: ["as-sama wat-tariq", "was-samai wat-tariq", "târık", "tarik", "at-tarik", "toriq"],
        87: ["sabbih", "sabbih isma rabbika al-ala", "sabbihisma"],
        88: ["hal ataka", "hal ataka hadith al-ghashiyah", "gaşiye", "al-gašija", "al-ghasyiyah", "al-ghaschiya", "al-ghachiyah", "al-gachiyah", "goshiya"],
        89: ["wal-fajr", "fecr", "al-fedžr", "al-fadschr"],
        90: ["la uqsimu bi-hadha al-balad", "al-aqabah", "beled", "al-beled"],
        91: ["wash-shams", "wash-shamsi wa duhaha", "şems", "aš-šems", "asy-syams", "asch-schams", "ach-chams"],
        92: ["wal-layl", "wal-layli idha yaghsha", "leyl", "al-lejl", "al-lail"],
        93: ["wad-duha", "ad-dhuha", "dhuha", "ad-douha", "douha", "zuha", "az-zuha", "zuho", "doha", "ad-doha", "wad-duha wal-layl"],
        94: ["al-inshirah", "inshirah", "alam nashrah", "alam nashrah laka", "al-alm-nashrah", "al-yusr", "inşirah", "al-inširah", "al-insyirah", "asch-scharh", "ach-charh"],
        95: ["wat-tin", "wat-tin waz-zaytun", "az-zaytun", "at-teen"],
        96: ["iqra", "iqra bismi rabbika", "iqra bismi rabbik", "ikra", "alak", "al-alek"],
        97: ["inna anzalnahu", "inna anzalnahu fi laylat al-qadr", "laylat al-qadr", "kadir", "al-kadr"],
        98: ["lam yakun", "lam yakun alladhina kafaru", "lam yakon", "ahl al-kitab", "al-bariyyah", "al-munfakkin", "al-infikak", "beyyine", "al-bejjina", "al-baiyinah"],
        99: ["az-zilzal", "zilzal", "al-zalzaal", "az-zalzal", "idha zulzilat", "zulzilat"],
        100: ["wal-adiyat", "al-adijat", "adiyot", "al-adiyate"],
        101: ["karia", "al-karia", "qoria"],
        102: ["alhakum", "alhakum at-takathur", "al-maqbarah", "tekasür", "at-tekasur", "at-takasur", "at-takaasur", "at-takatur", "takosur"],
        103: ["wal-asr", "asar", "al-asar"],
        104: ["wayl li-kulli humazah", "al-hutamah", "hümeze"],
        105: ["alam tara", "alam tara kayfa", "al-feel"],
        106: ["ilaf", "li-ilaf", "li-ilafi quraysh", "li-ilaf quraysh", "kureyş", "kurejš", "quraisy", "quraisch", "quraych", "qouraych", "qoraysh", "quraish", "koreish"],
        107: ["araayta", "araayta alladhi", "ad-din", "al-yatim", "at-takdhib"],
        108: ["inna ataynaka", "inna ataynaka al-kawthar", "kevser", "al-kevser", "al-kausar", "kausar", "al-kauser", "al-kauthar", "kavsar", "al-kawtar"],
        109: ["qul ya ayyuha al-kafirun", "al-ibadah", "al-munabadhah", "kâfirûn", "kofirun", "al-kafirune"],
        110: ["idha jaa nasr allah", "idha jaa nasrullah", "idha jaa nasr allah wal-fath", "at-tawdi"],
        111: ["tabbat", "tabbat yada", "tabbat yada abi lahab", "al-lahab", "lahab", "abu lahab", "abi lahab", "al-lahb", "tebbet", "al-leheb", "leheb", "al-massad"],
        112: ["at-tawhid", "tawhid", "tauhid", "tevhid", "qul huwa allahu ahad", "qul huwallahu ahad", "qul hu allah", "as-samad", "ihlas", "al-ihlas", "al-ichlas", "ixlos"],
        113: ["qul audhu bi-rabb al-falaq", "qul audhu bi rabbil falaq", "felak", "al-felek"],
        114: ["qul audhu bi-rabb an-nas", "qul audhu bi rabbin nas"]
    ]
    static let arabic: [Int: [String]] = [
        1: ["أم الكتاب", "أم القرآن", "فاتحة الكتاب", "فاتحة القرآن", "السبع المثاني", "سبع المثاني", "الحمد", "القرآن العظيم", "الشفاء", "الشافية", "الرقية", "الوافية", "الكافية", "الشكر", "المناجاة", "التفويض"],
        2: ["فسطاط القرآن", "سنام القرآن", "الكرسي"],
        3: ["طيبة", "تاج القرآن"],
        4: ["النساء الكبرى", "النساء الطولى"],
        5: ["العقود", "المنقذة", "الأحبار", "الأخيار"],
        6: ["الحجة", "المرضية"],
        7: ["المص", "الميقات", "أطول الطوليين"],
        8: ["بدر"],
        9: ["براءة", "البراءة", "الفاضحة", "العذاب", "البحوث", "المنقرة", "الحافرة", "المثيرة", "المدمدمة", "المخزية", "المنكلة", "المشردة", "المهلكة", "المستقصية"],
        15: ["ربما"],
        16: ["النعم", "النعيم"],
        17: ["بني إسرائيل", "سبحان", "الأقصى"],
        18: ["أصحاب الكهف", "الحائلة"],
        19: ["كهيعص"],
        20: ["الكليم", "التكليم"],
        21: ["اقترب"],
        23: ["قد أفلح", "قد أفلح المؤمنون", "الفلاح"],
        25: ["تبارك الفرقان"],
        26: ["طسم الشعراء", "الجامعة", "الظلة"],
        27: ["سليمان", "الهدهد", "طس", "طس سليمان"],
        32: ["الم تنزيل", "الم تنزيل السجدة", "المضاجع", "سجدة لقمان"],
        35: ["الملائكة"],
        36: ["قلب القرآن", "حبيب النجار", "المعمة", "الدافعة", "القاضية"],
        37: ["الذبيح", "الزينة"],
        38: ["داود"],
        39: ["الغرف"],
        40: ["المؤمن", "حم المؤمن", "الطول", "حم الأولى"],
        41: ["حم السجدة", "حم سجدة", "المصابيح", "الأقوات", "سجدة المؤمن"],
        42: ["حم عسق", "عسق"],
        43: ["حم الزخرف"],
        44: ["حم الدخان", "المباركة"],
        45: ["حم الجاثية", "الشريعة"],
        46: ["حم الأحقاف"],
        47: ["القتال", "الذين كفروا"],
        50: ["الباسقات", "ق والقرآن المجيد"],
        51: ["والذاريات"],
        52: ["والطور"],
        53: ["والنجم"],
        54: ["اقتربت", "اقتربت الساعة"],
        55: ["عروس القرآن"],
        56: ["إذا وقعت"],
        58: ["الظهار", "قد سمع"],
        59: ["بني النضير", "بنو النضير"],
        60: ["الامتحان", "المودة"],
        61: ["الحواريين", "الحواريون"],
        63: ["إذا جاءك المنافقون"],
        65: ["النساء القصرى", "النساء الصغرى"],
        66: ["لم تحرم", "المتحرم"],
        67: ["تبارك", "تبارك الذي بيده الملك", "تبارك الملك", "المنجية", "المانعة", "الواقية", "المناعة"],
        68: ["ن", "ن والقلم", "نون"],
        69: ["السلسلة", "الواعية"],
        70: ["سأل سائل", "سأل", "الواقع", "المواقع"],
        71: ["إنا أرسلنا نوحا"],
        72: ["قل أوحي", "قل أوحي إلي"],
        75: ["لا أقسم بيوم القيامة"],
        76: ["الدهر", "هل أتى", "هل أتى على الإنسان", "الأبرار", "الأمشاج"],
        77: ["والمرسلات", "والمرسلات عرفا", "العرف"],
        78: ["عم", "عم يتساءلون", "التساؤل", "المعصرات"],
        79: ["الساهرة", "الطامة"],
        80: ["السفرة", "الصاخة", "الأعمى", "ابن أم مكتوم"],
        81: ["كورت", "إذا الشمس كورت"],
        82: ["انفطرت", "إذا السماء انفطرت", "المنفطرة"],
        83: ["التطفيف", "ويل للمطففين", "المطففون"],
        84: ["انشقت", "إذا السماء انشقت", "الشفق"],
        85: ["السماء ذات البروج", "والسماء ذات البروج"],
        86: ["السماء والطارق", "والسماء والطارق"],
        87: ["سبح", "سبح اسم ربك الأعلى"],
        88: ["هل أتاك", "هل أتاك حديث الغاشية"],
        89: ["والفجر"],
        90: ["لا أقسم بهذا البلد", "العقبة"],
        91: ["والشمس", "والشمس وضحاها"],
        92: ["والليل", "والليل إذا يغشى"],
        93: ["والضحى", "والضحى والليل"],
        94: ["الانشراح", "ألم نشرح", "اليسر"],
        95: ["والتين", "والتين والزيتون", "الزيتون"],
        96: ["اقرأ", "اقرأ باسم ربك", "اقرأ باسم ربك الذي خلق"],
        97: ["إنا أنزلناه", "إنا أنزلناه في ليلة القدر", "ليلة القدر"],
        98: ["لم يكن", "لم يكن الذين كفروا", "أهل الكتاب", "البرية", "المنفكين", "الانفكاك", "القيمة"],
        99: ["الزلزال", "إذا زلزلت", "زلزلت"],
        100: ["والعاديات"],
        102: ["ألهاكم", "ألهاكم التكاثر", "المقبرة"],
        103: ["والعصر"],
        104: ["ويل لكل همزة", "الحطمة"],
        105: ["ألم تر", "ألم تر كيف"],
        106: ["إيلاف", "لإيلاف", "لإيلاف قريش"],
        107: ["أرأيت", "أرأيت الذي", "أرأيت الذي يكذب", "الدين", "اليتيم", "التكذيب"],
        108: ["إنا أعطيناك", "إنا أعطيناك الكوثر", "النحر"],
        109: ["قل يا أيها الكافرون", "العبادة", "المنابذة"],
        110: ["إذا جاء نصر الله والفتح", "إذا جاء نصر الله", "التوديع"],
        111: ["تبت", "تبت يدا أبي لهب", "اللهب", "أبي لهب", "أبو لهب"],
        112: ["التوحيد", "قل هو الله أحد", "الصمد"],
        113: ["قل أعوذ برب الفلق"],
        114: ["قل أعوذ برب الناس"]
    ]
    // END GENERATED SURAH ALIASES

    private static let lock = NSLock()
    private static var entries: [Int: SpellingFold.Entry] = [:]

    /// Locked rather than main-confined: the Siri resolvers ask from their own executor.
    static func entry(for surah: Surah) -> SpellingFold.Entry {
        lock.lock()
        defer { lock.unlock() }
        if let cached = entries[surah.id] { return cached }
        let built = SpellingFold.Entry(names: [surah.nameTransliteration] + (latin[surah.id] ?? []))
        entries[surah.id] = built
        return built
    }

    /// The surahs a folded spelling finds. `exactOnly` is for callers that must pick ONE surah and
    /// act on it (Siri, "open surah ..."): a merely similar start is not enough to act on.
    static func matches(_ text: String, in surahs: [Surah], exactOnly: Bool = false) -> [Surah] {
        guard let query = SpellingFold.Query(text) else { return [] }
        if exactOnly {
            return surahs.filter {
                let strength = SpellingFold.strength(of: query, in: entry(for: $0))
                return strength == .keyExact || strength == .skeletonExact
            }
        }
        return SpellingFold.matches(text, in: surahs) { entry(for: $0) }
    }
}

extension Surah {
    var normalizedSearchNames: [String] {
        let baseNames = [
            nameTransliteration,
            nameEnglish,
            nameArabic.removingArabicMarks()
        ].map { $0.normalizedForSurahQuery }

        let curated = ((SurahSpelling.latin[id] ?? []) + (SurahSpelling.arabic[id] ?? []))
            .flatMap { [$0.normalizedForSurahQuery] + $0.transliterationSearchAliases }

        return Array(Set(baseNames + transliterationSearchAliases + curated)).sorted()
    }

    var transliterationSearchAliases: [String] {
        nameTransliteration.transliterationSearchAliases
    }
}

extension String {
    func removingArabicMarks() -> String {
        let filtered = unicodeScalars.filter {
            $0.value != 0x0640 &&
            !(0x0610...0x061A).contains($0.value) &&
            !(0x064B...0x065F).contains($0.value) &&
            !(0x06D6...0x06ED).contains($0.value)
        }
        return String(String.UnicodeScalarView(filtered))
    }

    func arabicDigitsToWestern() -> String {
        let digitMap: [Character: Character] = [
            "٠":"0","١":"1","٢":"2","٣":"3","٤":"4",
            "٥":"5","٦":"6","٧":"7","٨":"8","٩":"9",
            "۰":"0","۱":"1","۲":"2","۳":"3","۴":"4",
            "۵":"5","۶":"6","۷":"7","۸":"8","۹":"9"
        ]
        return String(map { digitMap[$0] ?? $0 })
    }

    var normalizedForSurahQuery: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .removingArabicMarks()
            .arabicDigitsToWestern()
            .lowercased()
    }

    var transliterationSearchAliases: [String] {
        let normalized = normalizedForSurahQuery
        guard !normalized.isEmpty else { return [] }

        var aliases = Set<String>()

        func insert(_ value: String) {
            let cleaned = value.normalizedForSurahQuery
            if !cleaned.isEmpty {
                aliases.insert(cleaned)
            }
        }

        insert(normalized)
        insert(normalized.replacingOccurrences(of: "-", with: " "))
        insert(normalized.replacingOccurrences(of: "-", with: ""))
        insert(normalized.replacingOccurrences(of: " ", with: ""))

        let articlePrefixes = ["al", "ar", "an", "ad", "adh", "as", "at", "ath", "az", "ash"]
        for prefix in articlePrefixes {
            let hyphenPrefix = "\(prefix)-"
            let spacePrefix = "\(prefix) "

            if normalized.hasPrefix(hyphenPrefix) {
                let stripped = String(normalized.dropFirst(hyphenPrefix.count))
                insert(stripped)
                insert(stripped.replacingOccurrences(of: "-", with: " "))
                insert(stripped.replacingOccurrences(of: " ", with: ""))
            }

            if normalized.hasPrefix(spacePrefix) {
                let stripped = String(normalized.dropFirst(spacePrefix.count))
                insert(stripped)
                insert(stripped.replacingOccurrences(of: "-", with: " "))
                insert(stripped.replacingOccurrences(of: " ", with: ""))
            }
        }

        return Array(aliases)
    }

    var normalizedSurahIntentQuery: String {
        normalizedForSurahQuery.replacingOccurrences(
            of: #"^\s*(surah|surat|sura|chapter|سورة|سوره)\s+"#,
            with: "",
            options: .regularExpression
        )
    }
}

struct LastListenedSurah: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let reciter: Reciter
    let currentDuration: Double
    let fullDuration: Double
    /// When this position was recorded, shown on the summary tile ("Today 5:30 PM"). Optional so
    /// entries saved by older builds still decode (they show no timestamp).
    var savedAt: Date? = nil
}

/// One bundled "About this Surah" write-up (e.g. Maududi, Ibn Ashur). `contents` is lightweight markdown
/// (## headings + paragraphs) pre-converted from the source HTML so it renders without runtime HTML parsing.
struct SurahInfoSource: Codable, Identifiable, Equatable {
    let name: String
    let contents: String

    var id: String { name }
}

/// The last individual ayah (single ayah or custom-range playback) the user listened to. Full-surah
/// playback is tracked separately by `LastListenedSurah`.
struct LastListenedAyah: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    let reciter: Reciter
    /// See `LastListenedSurah.savedAt`.
    var savedAt: Date? = nil
}

struct ListeningHistoryItem: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let reciter: Reciter
    /// Where playback stood when this entry was displaced from Last Listened - powers the history row's
    /// "resume from here". Optional so entries saved by older builds still decode (they show no position).
    var currentDuration: Double? = nil
    var fullDuration: Double? = nil
    var timestamp: Date = Date()
}

struct ReadingHistoryItem: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    var timestamp: Date = Date()
}

/// A previously listened individual ayah (single ayah / custom range), shown under the Last Listened Ayah row.
struct AyahListeningHistoryItem: Identifiable, Codable {
    var id = UUID()
    let surahNumber: Int
    let surahName: String
    let ayahNumber: Int
    let reciter: Reciter
    var timestamp: Date = Date()
}

struct ShareSettings: Equatable {
    var arabic = false
    var transliteration = false
    var englishSaheeh = false
    var englishMustafa = false
    var includeQiraah = false
    var shareArabicFont = ""
    var cleanArabic = false
    var hideArabicDots = false
    var showTajweed = false
}

/// The other ways a reciter's name is written and searched for (Abu, 2026-09-20: "ayoub, ayyoub,
/// ayub"). `SpellingFold` already equates vowel length, doubled letters and the swapped consonants,
/// so this table holds only what a fold cannot reach: the rest of a FULL name the catalogue shortens
/// (Abdul Basit is Abdul Basit Abdus Samad), an assimilated article that changes a letter
/// (Abdurrahman for Abdul Rahman), and a digraph of another class (Hudhaify for Huthaifi).
///
/// Keyed by the catalogue name without its parenthetical, so every recording of one reciter
/// ("... (Mujawwad)", "... (Special)") shares the entry.
enum ReciterSpelling {
    private static let table: [String: [String]] = [
        "Abdul Basit": ["Abdul Basit Abdus Samad", "Abdelbasset Abdessamad", "Abdulbasit Abdulsamad", "Abd al-Basit Abd as-Samad"],
        "Abdul Rahman Al-Sudais": ["Abdurrahman As-Sudais", "Abdulrahman Al-Sudais", "Abdur Rahman Sudays", "Abdel Rahman El-Sudais"],
        "Mishary Alafasy": ["Mishary Rashid Alafasy", "Mishari Al-Afasy", "Meshary Al-Afasi", "Mishary bin Rashid Al-Afasy"],
        "Muhammad Al-Minshawi": ["Mohamed Siddiq El-Minshawi", "Muhammad Siddiq Al-Minshawy", "Menshawi", "Minshawy"],
        "Mahmoud Al-Hussary": ["Mahmoud Khalil Al-Husary", "Mahmud Khalil Al-Husari", "El-Hosary", "Hussari"],
        "Ali Al-Huthaifi": ["Ali Al-Hudhaify", "Ali Al-Hudhaifi", "Ali Al-Huzaifi", "Ali Al-Hudaifi", "Ali Al-Hudhayfi"],
        "Saud Al-Shuraim": ["Saud Ash-Shuraym", "Saood Shuraim", "Sa'ud Al-Shuraim", "Shreem"],
        "Saad Al-Ghamdi": ["Sa'd Al-Ghamidi", "Saad El-Ghamidi", "Saad Al-Gamdi"],
        "Maher Al-Muaiqly": ["Maher Al-Mueaqly", "Mahir Al-Muayqali", "Maher Al-Mu'aiqly", "Maher Al-Moaiqly", "Muaiqli"],
        "Abu Bakr Al-Shatri": ["Abu Bakr Ash-Shatri", "Abu Bakr Ash-Shatiri", "Abu Bakr Al-Shatery", "Abubakr Shatri"],
        "Yasser Al-Dosari": ["Yasser Ad-Dussary", "Yasir Al-Dossari", "Yaser Ad-Dawsari", "Yasser Al-Dosary"],
        "Ibrahim Al-Dossary": ["Ibrahim Ad-Dosari", "Ibrahim Al-Dawsari", "Ibraheem Ad-Dussary", "Ebrahim Al-Dosari"],
        "Abdurrasheed Sufi": ["Abdul Rashid Sufi", "Abdirashid Ali Sufi", "Abdulrashid Sufi", "Abdur Rasheed Sufi"],
        "Abdulrahman Aloosi": ["Abdurrahman Al-Alusi", "Abdul Rahman Al-Oosi", "Abdulrahman Al-Ossi", "Abdur Rahman Al-Aloosi"],
        "Mohamed Al-Tablawi": ["Muhammad Mahmoud At-Tablawi", "Mohammed El-Tablawy", "Tablawy"],
        "Mustafa Ismail": ["Moustafa Ismail", "Mostafa Ismaeel", "Mustapha Ismail", "Mustafa Isma'il"],
        "Mahmoud Ali Al-Banna": ["Mahmoud Ali El-Banna", "Mahmud Ali Al-Bana"],
        "Hani Al-Rifai": ["Hani Ar-Rifai", "Hany Al-Refai", "Hani Ar-Rifa'i"],
        "Ahmad Al-Ajmy": ["Ahmed Al-Ajamy", "Ahmad Al-Ajmi", "Ahmed Al-Ajami", "Ahmad bin Ali Al-Ajmy"],
        "Abdullah Al-Juhany": ["Abdullah Al-Johani", "Abdullah Awad Al-Juhani", "Abdallah Al-Juhaynee"],
        "Abdullah Al-Mattrod": ["Abdullah Al-Matrood", "Abdullah Al-Matroud", "Abdallah Al-Matrud"],
        "Bandar Baleela": ["Bandar Balila", "Bandar Baleelah", "Bander Balilah"],
        "Muhammad Al-Luhaidan": ["Mohammed Al-Lohaidan", "Muhammad Al-Luhaydan", "Mohammad Al-Lahidan"],
        "Khalifa Al-Tunaiji": ["Khalifa At-Tunaiji", "Khalifah Al-Tunaijy", "Khalifa Al-Tunayji"],
        "Omar Al-Qazabri": ["Omar Al-Kazabri", "Umar Al-Qazabri", "Omar El-Kazabri"],
        "Noreen Mohammad Siddiq": ["Noreen Muhammad Siddique", "Nurain Mohammed Sadiq", "Noorin Muhammad Siddiq"],
        "Muhammad Ayyub": ["Mohammed Ayoub", "Muhammad Ayyoub", "Mohammad Ayub", "Muhammad Ayoob"],
        "Muhammad Jibreel": ["Mohamed Gebril", "Muhammad Jibril", "Mohammed Jebril", "Mohamed Gibreel"],
        "Islam Sobhi": ["Islam Subhi", "Eslam Sobhy"],
        "Ali Jaber": ["Ali Jabir", "Ali Abdullah Jaber", "Ali Gaber"],
        "Yasser Al-Mazroyee": ["Yasser Al-Mazrouei", "Yasir Al-Mazrooei", "Yaser Al-Mazroui"],
        "Hazza Al-Balushi": ["Hazaa Al-Blushi", "Hazza Al-Baloushi", "Hazzaa Al-Balooshi"],
        "Abdelmoujib Benkirane": ["Abdul Mujib Bin Kiran", "Abdelmujib Benkiran", "Abd al-Mujib Bin Kiran"],
        "Rachid Belalya": ["Rashid Belalia", "Rasheed Belalya"],
        "Rachid Ifrad": ["Rashid Ifrad", "Rasheed Ifrad"],
        "Tareq Daawob": ["Tariq Daoub", "Tarek Daaoub", "Tariq Da'ub"],
        "Karim Rajeh": ["Kareem Rajih", "Kurayyim Rajih"],
        "Ahmad Al-Nufais": ["Ahmed Al-Nufays", "Ahmad An-Nufais", "Ahmad Al-Nofais"],
        "Badr Al-Turki": ["Bader Al-Turky", "Badr At-Turki"]
    ]

    private static func baseName(_ reciter: Reciter) -> String {
        guard let paren = reciter.name.range(of: " (") else { return reciter.name }
        return String(reciter.name[..<paren.lowerBound])
    }

    static func otherNames(for reciter: Reciter) -> [String] {
        table[baseName(reciter)] ?? []
    }

    /// Main-thread only, like the reciter list that asks: a plain memo, one entry per catalogue name.
    private static var entries: [String: SpellingFold.Entry] = [:]

    static func entry(for reciter: Reciter) -> SpellingFold.Entry {
        let base = baseName(reciter)
        if let cached = entries[base] { return cached }
        let built = SpellingFold.Entry(names: [base] + (table[base] ?? []))
        entries[base] = built
        return built
    }

    static let entry: (Reciter) -> SpellingFold.Entry = { entry(for: $0) }
}

struct Reciter: Identifiable, Comparable, Codable, Hashable {
    var id: String { "\(name)|\(qiraah ?? "Hafs")|\(surahLink)" }

    let name: String
    let ayahIdentifier: String
    let ayahBitrate: String
    let surahLink: String
    var qiraah: String?

    /// When set, per-ayah audio is sourced from everyayah.com's `{surah}{ayah}.mp3` scheme in this folder
    /// instead of cdn.islamic.network's global-ayah-id scheme. Used for editions whose islamic.network feed is
    /// unreliable - notably Minshawi Mujawwad, whose `ar.minshawimujawwad` files are the *Murattal* recording
    /// for ~1 in 5 ayahs (verified by identical md5), which made playback audibly drop to Murattal mid-surah.
    var everyayahFolder: String? = nil

    /// For a Mujawwad/Muallim reciter that has no true per-ayah recording in that style anywhere, this names
    /// the Murattal that individual ayahs actually play instead (e.g. "Maher Al-Muaiqly (Murattal)"). Drives a
    /// heads-up confirmation on selection and the now-playing label during ayah/range playback. nil when the
    /// ayah audio matches the reciter's advertised style.
    var ayahMurattalStyleNote: String? = nil

    /// Surahs this reciter's mp3quran feed does NOT carry (some mushafs are partial - Islam Sobhi's covers
    /// 109 of 114). Optional so `Reciter` values persisted before the field existed still decode. Downloads
    /// skip these instead of dying on a 404, and playback explains instead of throwing a network error.
    var missingSurahs: Set<Int>? = nil

    /// The reciter's id in the QDC audio API (api.qurancdn.com - the service behind quran.com and QUL),
    /// which serves per-surah AYAH TIMESTAMPS. When set, downloaded surahs also fetch their timing table,
    /// and - once the timings are validated against the local file's duration - ayah and custom-range
    /// playback is cut from the downloaded surah file itself: the reciter's own voice, fully offline.
    /// nil = no timing source; every existing behavior is untouched.
    var qdcReciterID: Int? = nil

    func carriesSurah(_ surahNumber: Int) -> Bool {
        !(missingSurahs?.contains(surahNumber) ?? false)
    }

    /// How many surahs this reciter actually offers. THE completion denominator: comparing download
    /// counts against a flat 114 made a fully-downloaded partial-mushaf reciter (Islam Sobhi carries
    /// 109) read as forever-incomplete - and the incomplete-download purge then DELETED the finished
    /// download every time the reciter list appeared.
    var carriedSurahCount: Int {
        114 - (missingSurahs?.count ?? 0)
    }

    /// The surahs this reciter actually carries, in mushaf order.
    var carriedSurahs: [Int] {
        (1...114).filter(carriesSurah)
    }

    /// The carried surahs written as compact ranges: "1-5, 10-20, 25". Consecutive runs collapse,
    /// a run of one stays a bare number. "" when the reciter carries none, which cannot happen for
    /// a shipped entry but keeps the caller total.
    ///
    /// Built from `missingSurahs` rather than stored, so it can never disagree with what playback
    /// and the downloader do.
    var carriedSurahRangesDescription: String {
        var runs: [(Int, Int)] = []
        for surah in carriedSurahs {
            if let last = runs.last, surah == last.1 + 1 {
                runs[runs.count - 1].1 = surah
            } else {
                runs.append((surah, surah))
            }
        }
        return runs.map { $0.0 == $0.1 ? "\($0.0)" : "\($0.0)-\($0.1)" }
            .joined(separator: ", ")
    }

    /// Settings / lists: append English riwayah when this row is a non-Hafs surah feed.
    var displayNameWithEnglishQiraah: String {
        if let q = qiraah, !q.isEmpty { return "\(name) (\(q))" }
        return name
    }

    /// Lock screen and now playing: show the selected reciter name, plus riwayah for qiraat surah feeds.
    var displayNameForNowPlaying: String {
        let base = name
        if let q = qiraah, !q.isEmpty { return "\(base) (\(q))" }
        return base
    }

    /// Display name used for the Minshawi ayah fallback feed.
    static let minshawiAyahFallbackName = "Muhammad Al-Minshawi (Murattal)"

    /// True when this reciter has no ayah-by-ayah feed of its own and falls back to Minshawi (Murattal) for
    /// individual ayah audio. A reciter with its own `everyayahFolder` is NOT a fallback - it plays its own
    /// voice from everyayah.com, so it must be excluded here (otherwise it would still show the Minshawi
    /// confirmation/label even though its ayahs are genuinely its own).
    var defaultToMinshawi: Bool {
        everyayahFolder == nil && ayahIdentifier.contains("minshawi") && !name.contains("Minshawi")
    }

    /// True when a downloaded surah can also be played ayah-by-ayah OFFLINE, by cutting each ayah out of the
    /// full-surah file using this reciter's QDC timing table (the reciter's own voice, no network). Backed by
    /// `qdcReciterID`.
    var supportsAyahSegments: Bool { qdcReciterID != nil }

    /// True when this reciter has NO per-ayah recitation of its own to stream - individual ayahs otherwise
    /// play in a substitute Murattal (`defaultToMinshawi` or a named `ayahMurattalStyleNote`). Combined with
    /// `supportsAyahSegments`, this is the "must load the whole surah to hear an ayah in this voice" case.
    var lacksOwnStreamedAyahs: Bool { defaultToMinshawi || ayahMurattalStyleNote != nil }

    static func < (lhs: Reciter, rhs: Reciter) -> Bool {
        lhs.name < rhs.name
    }

    static func == (lhs: Reciter, rhs: Reciter) -> Bool {
        lhs.id == rhs.id
    }
}

/// Hosting quirks for surah audio feeds. mp3quran hosts serve plain per-surah "NNN.mp3" files with
/// no strings attached. islamweb's audio library (audio.islamweb.net) serves the same per-surah
/// "NNN.mp3" layout from its Azure Front Door CDN, but that CDN rejects any request that does not
/// carry an islamweb Referer header (it 307s to the islamweb homepage instead). Every player /
/// downloader request for those files must therefore attach the header via these helpers.
enum ReciterAudioHosting {
    /// audio.islamweb.net's CDN host - the origin behind the islamweb riwayah audio library.
    static let islamwebCDNHost = "quran-fjamfcbbeybteyat.z01.azurefd.net"
    private static let islamwebReferer = "https://audio.islamweb.net/"

    /// Extra HTTP headers this URL's host requires; nil for hosts (mp3quran, everyayah,
    /// islamic.network) that need none.
    static func httpHeaders(for url: URL) -> [String: String]? {
        guard url.host == islamwebCDNHost else { return nil }
        return ["Referer": islamwebReferer]
    }

    /// `AVURLAsset` options carrying any required headers. Apple does not expose
    /// "AVURLAssetHTTPHeaderFieldsKey" as a Swift constant, hence the literal key.
    static func assetOptions(for url: URL) -> [String: Any] {
        guard let headers = httpHeaders(for: url) else { return [:] }
        return ["AVURLAssetHTTPHeaderFieldsKey": headers]
    }

    /// A URLRequest for fetching `url`, with any required headers attached.
    static func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        httpHeaders(for: url)?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        return request
    }
}

let reciters: [Reciter] = {
    let all =
        recitersMinshawi +
        recitersMurattal +
        recitersMujawwad +
        recitersMuallim +

        recitersShubah +
        recitersWarsh +
        recitersBuzzi +
        recitersQunbul +
        recitersQaloon +
        recitersDuri +
        recitersSusi +
        recitersKhalaf +
        recitersHisham +
        recitersIbnDhakwan +
        recitersKhallad +
        recitersAbuHarith +
        recitersDuriKisai +
        recitersIbnWardan +
        recitersIbnJammaz +
        recitersRuways +
        recitersRawh +
        recitersIshaq +
        recitersIdris
    // The Minshawi variants intentionally appear in both `recitersMinshawi` and their style list, so the
    // combined lookup/random list must drop the duplicate ids (else `randomElement()` is biased and any
    // ForEach over `reciters` hits duplicate ids).
    var seen = Set<String>()
    return all.filter { seen.insert($0.id).inserted }.sorted()
}()

let recitersMinshawi = [
    Reciter(name: "Muhammad Al-Minshawi (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/", qdcReciterID: 9),
    Reciter(name: "Muhammad Al-Minshawi (Mujawwad)", ayahIdentifier: "ar.minshawimujawwad", ayahBitrate: "64", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mojawwad/", everyayahFolder: "Minshawy_Mujawwad_192kbps"),
    // mp3quran's archival 1387 AH (1967 CE) recording - only 26 surahs survive (1-15, 17-22, 25-29).
    Reciter(name: "Muhammad Al-Minshawi (1387 AH)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh1387/", ayahMurattalStyleNote: "Muhammad Al-Minshawi (Murattal)", missingSurahs: Set([16, 23, 24]).union(Set(30...114))),
    // everyayah's Minshawy_Teacher_128kbps folder is absent from their recitations.js index but serves the
    // complete per-ayah teacher set (verified 1:1, 2:286, 67:1, 114:6) - so streamed ayahs play in the
    // Muallim style itself, not a substitute Murattal.
    Reciter(name: "Muhammad Al-Minshawi (Muallim)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mo-lim/", everyayahFolder: "Minshawy_Teacher_128kbps")
].sorted()

let recitersMurattal = [
    Reciter(name: "Abdul Basit (Murattal)", ayahIdentifier: "ar.abdulbasitmurattal", ayahBitrate: "192", surahLink: "https://server7.mp3quran.net/basit/", qdcReciterID: 2),
    Reciter(name: "Abdul Rahman Al-Sudais", ayahIdentifier: "ar.abdurrahmaansudais", ayahBitrate: "192", surahLink: "https://server11.mp3quran.net/sds/", qdcReciterID: 3),
    Reciter(name: "Abu Bakr Al-Shatri", ayahIdentifier: "ar.shaatree", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/shatri/", qdcReciterID: 4),
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Mahmoud Al-Hussary (Murattal)", ayahIdentifier: "ar.husary", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/", qdcReciterID: 6),
    Reciter(name: "Maher Al-Muaiqly (Murattal)", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/"),
    Reciter(name: "Mishary Alafasy", ayahIdentifier: "ar.alafasy", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/afs/", qdcReciterID: 7),
    Reciter(name: "Abdullah Al-Juhany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/jhn/", everyayahFolder: "Abdullaah_3awwaad_Al-Juhaynee_128kbps"),
    Reciter(name: "Abdurrasheed Sufi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/soufi/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Bandar Baleela", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server6.mp3quran.net/balilah/"),
    Reciter(name: "Badr Al-Turki", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/bader/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Muhammad Al-Luhaidan", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/lhdan/"),
    Reciter(name: "Abdullah Al Qarafi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/a_alqrafi/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Muhammad Al-Minshawi (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/", qdcReciterID: 9),
    Reciter(name: "Muhammad Jibreel", ayahIdentifier: "ar.muhammadjibreel", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/jbrl/"),
    Reciter(name: "Mustafa Ismail (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/mustafa/"),
    Reciter(name: "Mahmoud Ali Al-Banna (Murattal)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/bna/", everyayahFolder: "mahmoud_ali_al_banna_32kbps"),
    Reciter(name: "Saud Al-Shuraim", ayahIdentifier: "ar.saoodshuraym", ayahBitrate: "64", surahLink: "https://server7.mp3quran.net/shur/", qdcReciterID: 10),
    Reciter(name: "Hani Al-Rifai", ayahIdentifier: "ar.hanirifai", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/hani/", qdcReciterID: 5),
    Reciter(name: "Ahmad Al-Ajmy", ayahIdentifier: "ar.ahmedajamy", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/ajm/"),
    Reciter(name: "Muhammad Ayyub", ayahIdentifier: "ar.muhammadayyoub", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/ayyub/"),
    Reciter(name: "Muhammad Ayyub (Special)", ayahIdentifier: "ar.muhammadayyoub", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/ayyoub2/Rewayat-Hafs-A-n-Assem/"),
    Reciter(name: "Abdulrahman Aloosi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server6.mp3quran.net/aloosi/"),
    // mp3quran carries only 91 of 114 surahs for this mushaf (their API's surah_list omits these 23) -
    // without the list, tapping one of the missing surahs 404'd and surfaced as a bogus "no internet" error.
    Reciter(name: "Hazza Al-Balushi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/hazza/", missingSurahs: [2, 3, 4, 5, 7, 9, 10, 11, 16, 23, 24, 26, 27, 28, 33, 48, 58, 59, 60, 62, 64, 65, 66]),
    Reciter(name: "Ali Jaber", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/a_jbr/", everyayahFolder: "Ali_Jaber_64kbps"),
    Reciter(name: "Saad Al-Ghamdi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server7.mp3quran.net/s_gmd/", everyayahFolder: "Ghamadi_40kbps"),
    Reciter(name: "Yasser Al-Dosari", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/yasser/", everyayahFolder: "Yasser_Ad-Dussary_128kbps", qdcReciterID: 97),
    Reciter(name: "Abdullah Al-Mattrod", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/mtrod/", everyayahFolder: "Abdullah_Matroud_128kbps"),
    Reciter(name: "Ahmad Al-Nufais", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/nufais/Rewayat-Hafs-A-n-Assem/"),
    // mp3quran carries 109 of 114 surahs for this mushaf (their API's surah_list omits these five).
    Reciter(name: "Islam Sobhi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server14.mp3quran.net/islam/Rewayat-Hafs-A-n-Assem/", missingSurahs: [37, 39, 40, 45, 65]),
    // Only 24 surahs are recorded (mp3quran's surah_list), so this is written as the complement:
    // spelling out the other 90 would be unreadable and would rot the moment he records another.
    Reciter(name: "Mohammad Dibirov", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/m-dibirov/Rewayat-Hafs-A-n-Assem/", missingSurahs: Set(1...114).subtracting([2, 12, 13, 17, 18, 19, 20, 24, 26, 27, 31, 32, 36, 37, 41, 44, 53, 55, 56, 67, 70, 72, 76, 79])),
    Reciter(name: "Mohamed Al-Tablawi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/tblawi/", everyayahFolder: "Mohammad_al_Tablaway_128kbps"),
    // See recitersMinshawi: the surviving 26 surahs of the 1387 AH recording.
    Reciter(name: "Muhammad Al-Minshawi (1387 AH)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh1387/", ayahMurattalStyleNote: "Muhammad Al-Minshawi (Murattal)", missingSurahs: Set([16, 23, 24]).union(Set(30...114))),
    Reciter(name: "Khalifa Al-Tunaiji", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/tnjy/", everyayahFolder: "khalefa_al_tunaiji_64kbps", qdcReciterID: 161)
].sorted()

let recitersMujawwad = [
    Reciter(name: "Abdul Basit (Mujawwad)", ayahIdentifier: "ar.abdulsamad", ayahBitrate: "64", surahLink: "https://server7.mp3quran.net/basit/Almusshaf-Al-Mojawwad/", qdcReciterID: 1),
    Reciter(name: "Mahmoud Al-Hussary (Mujawwad)", ayahIdentifier: "ar.husarymujawwad", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Almusshaf-Al-Mojawwad/"),
    Reciter(name: "Maher Al-Muaiqly (Mujawwad)", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/Almusshaf-Al-Mojawwad/", ayahMurattalStyleNote: "Maher Al-Muaiqly (Murattal)"),
    Reciter(name: "Muhammad Al-Minshawi (Mujawwad)", ayahIdentifier: "ar.minshawimujawwad", ayahBitrate: "64", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mojawwad/", everyayahFolder: "Minshawy_Mujawwad_192kbps"),
    Reciter(name: "Mustafa Ismail (Mujawwad)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/mustafa/Almusshaf-Al-Mojawwad/"),
    Reciter(name: "Mahmoud Ali Al-Banna (Mujawwad)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server8.mp3quran.net/bna/Almusshaf-Al-Mojawwad/", everyayahFolder: "mahmoud_ali_al_banna_32kbps")
].sorted()

let recitersMuallim = [
    Reciter(name: "Maher Al-Muaiqly (Muallim)", ayahIdentifier: "ar.mahermuaiqly", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/maher/Almusshaf-Al-Mo-lim/", ayahMurattalStyleNote: "Maher Al-Muaiqly (Murattal)"),
    // everyayah's Minshawy_Teacher_128kbps folder is absent from their recitations.js index but serves the
    // complete per-ayah teacher set (verified 1:1, 2:286, 67:1, 114:6) - so streamed ayahs play in the
    // Muallim style itself, not a substitute Murattal.
    Reciter(name: "Muhammad Al-Minshawi (Muallim)", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/minsh/Almusshaf-Al-Mo-lim/", everyayahFolder: "Minshawy_Teacher_128kbps")
].sorted()

let recitersShubah = [
    // Trailing "/" only: QuranPlayer appends "NNN.mp3" itself - the old link ended in "001.mp3",
    // so every surah request became ".../001.mp3001.mp3" and 404'd.
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Sho-bah-A-n-Asim/", qiraah: Settings.Riwayah.shubah),
    Reciter(name: "Ali Al-Huthaifi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server9.mp3quran.net/hthfi/Rewayat-Sho-bah-A-n-Asim/", qiraah: Settings.Riwayah.shubah)
].sorted()

let recitersKhalaf = [
    Reciter(name: "Abdurrasheed Sufi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/soufi/Rewayat-Khalaf-A-n-Hamzah/", qiraah: Settings.Riwayah.khalaf)
].sorted()

let recitersWarsh = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Warsh-A-n-Nafi-Men-Tariq-Alazraq/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Abdul Basit", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server7.mp3quran.net/basit/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Mahmoud Al-Hussary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Al-Qari Yassin", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/qari/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Al-Uyoun Al-Koshi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server11.mp3quran.net/koshi/", qiraah: Settings.Riwayah.warsh),
    // mp3quran's surah_list omits Al-Ahzab for this mushaf - 113 of 114.
    Reciter(name: "Hisham Al Haraz", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/H-Lharraz/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh, missingSurahs: [33]),
    Reciter(name: "Abdelmoujib Benkirane", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/A-Benkirane/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Ibrahim Al-Dossary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/ibrahim_dosri/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Muhammad Sayed", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/m_sayed/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Omar Al-Qazabri", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server9.mp3quran.net/omar_warsh/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Rachid Belalya", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server6.mp3quran.net/bl3/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Rachid Ifrad", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server12.mp3quran.net/ifrad/", qiraah: Settings.Riwayah.warsh),
    Reciter(name: "Younes Souilass", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/souilass/Rewayat-Warsh-A-n-Nafi/", qiraah: Settings.Riwayah.warsh)
].sorted()

let recitersBuzzi = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Albizi-A-n-Ibn-Katheer/", qiraah: Settings.Riwayah.buzzi),
    Reciter(name: "Okasha Kameny", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/okasha/Rewayat-Albizi-A-n-Ibn-Katheer/", qiraah: Settings.Riwayah.buzzi),
    // mp3quran's combined "Al-Bazzi and Qunbul" mushaf (one complete recording covering Ibn Kathir
    // through both narrators), so it serves both riwayah lists.
    Reciter(name: "Mohammad Al-Abdullah", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server9.mp3quran.net/abdullah/", qiraah: Settings.Riwayah.buzzi)
].sorted()

let recitersQunbul = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Qunbol-A-n-Ibn-Katheer/", qiraah: Settings.Riwayah.qunbul),
    // See recitersBuzzi: the combined Al-Bazzi + Qunbul recording.
    Reciter(name: "Mohammad Al-Abdullah", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server9.mp3quran.net/abdullah/", qiraah: Settings.Riwayah.qunbul)
].sorted()

let recitersQaloon = [
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Qalon-A-n-Nafi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Mahmoud Al-Hussary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Rewayat-Qalon-A-n-Nafi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Ahmed Al-Trabulsi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/trablsi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Ibrahim Qushaydan", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/i_kshidan/Rewayat-Qalon-A-n-Nafi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Tareq Daawob", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/tareq/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Ali Al-Huthaifi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server9.mp3quran.net/huthifi_qalon/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Addokali Muhammad Al-Alim", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server7.mp3quran.net/dokali/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Marwan Al-Akri", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/m_akri/Rewayat-Qalon-A-n-Nafi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Muhammad Al-Amin Qeniwa", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/qeniwa/Rewayat-Qalon-A-n-Nafi/", qiraah: Settings.Riwayah.qaloon),
    Reciter(name: "Muhammad Abu Sneina", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/sneineh/Rewayat-Qalon-A-n-Nafi/", qiraah: Settings.Riwayah.qaloon)
].sorted()

let recitersDuri = [
    Reciter(name: "Noreen Mohammad Siddiq", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/nourin_siddig/Rewayat-Aldori-A-n-Abi-Amr/", qiraah: Settings.Riwayah.duri),
    Reciter(name: "Mahmoud Al-Hussary", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server13.mp3quran.net/husr/Rewayat-Aldori-A-n-Abi-Amr/", qiraah: Settings.Riwayah.duri),
    Reciter(name: "Ahmad Deban", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/deban/Rewayat-Aldori-A-n-Abi-Amr/", qiraah: Settings.Riwayah.duri),
    Reciter(name: "Alfateh Al-Zubair", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server6.mp3quran.net/fateh/", qiraah: Settings.Riwayah.duri),
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server14.mp3quran.net/muftah_sultany/Rewayat-Aldori-A-n-Abi-Amr/", qiraah: Settings.Riwayah.duri)
].sorted()

let recitersSusi = [
    Reciter(name: "Abdurrasheed Sufi", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server16.mp3quran.net/soufi/Rewayat-Assosi-A-n-Abi-Amr/", qiraah: Settings.Riwayah.susi)
].sorted()

// MARK: The ten remaining riwayat - one complete reciter each, so EVERY riwayah the app can
// display also has full-surah audio. mp3quran's API carries complete mushafs for Ibn Dhakwan and
// ad-Duri al-Kisai; the other eight stream from islamweb's audio library (audio.islamweb.net),
// whose per-surah files use the same "NNN.mp3" naming but sit behind a Referer-checking CDN -
// `ReciterAudioHosting` attaches the required header. Each URL pattern below was verified
// complete: all 114 surah files return HTTP 200/206 with an audio/mpeg content type.

let recitersHisham = [
    // islamweb: "Meftah Mohammed Alstunai", the same reciter mp3quran anglicizes as Muftah Alsaltany.
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/MeftahAlstunai/HishamIbnAmer/", qiraah: Settings.Riwayah.hisham)
].sorted()

let recitersIbnDhakwan = [
    // NOTE the underscore after "Rewayat" - that is how mp3quran's API spells this mushaf's path.
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server14.mp3quran.net/muftah_sultany/Rewayat_Ibn-Thakwan-A-n-Ibn-Amer/", qiraah: Settings.Riwayah.ibnDhakwan)
].sorted()

let recitersKhallad = [
    Reciter(name: "Karim Rajeh", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/KarimRajeh/khalad_hamzah/", qiraah: Settings.Riwayah.khallad)
].sorted()

let recitersAbuHarith = [
    Reciter(name: "Karim Rajeh", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/KarimRajeh/AbuHarith-Alexaii/", qiraah: Settings.Riwayah.abuHarith)
].sorted()

let recitersDuriKisai = [
    Reciter(name: "Mohammad Al-Abdullah", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server9.mp3quran.net/abdullah/Rewayat-AlDorai-A-n-Al-Kisa-ai/", qiraah: Settings.Riwayah.duriKisai),
    Reciter(name: "Mahmoud Al-Sheimy", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server10.mp3quran.net/sheimy/", qiraah: Settings.Riwayah.duriKisai),
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server14.mp3quran.net/muftah_sultany/Rewayat-AlDorai-A-n-Al-Kisa-ai/", qiraah: Settings.Riwayah.duriKisai)
].sorted()

let recitersIbnWardan = [
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/MeftahAlstunai/ibnwerdan_abujaafar/", qiraah: Settings.Riwayah.ibnWardan)
].sorted()

let recitersIbnJammaz = [
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/MeftahAlstunai/ibnjumaz_abujaafar/", qiraah: Settings.Riwayah.ibnJammaz)
].sorted()

let recitersRuways = [
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/MeftahAlstunai/rowais_yaqoob/", qiraah: Settings.Riwayah.ruways),
    // mp3quran's combined "Ruways and Rawh" mushaf (one complete recording covering Ya'qub through
    // both narrators), so it serves both riwayah lists.
    Reciter(name: "Yasser Al-Mazroyee", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server9.mp3quran.net/mzroyee/", qiraah: Settings.Riwayah.ruways)
].sorted()

let recitersRawh = [
    Reciter(name: "Abdullah Mohammed Hamid", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/AbdullahMohammedHamid/rawh_yaqoob/", qiraah: Settings.Riwayah.rawh),
    // See recitersRuways: the combined Ruways + Rawh recording.
    Reciter(name: "Yasser Al-Mazroyee", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://server9.mp3quran.net/mzroyee/", qiraah: Settings.Riwayah.rawh)
].sorted()

let recitersIshaq = [
    // islamweb's set is missing surah 4 (An-Nisa) - its 004.mp3 is a genuine 404 on their CDN.
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/MeftahAlstunai/eshaq_khalaf/", qiraah: Settings.Riwayah.ishaq, missingSurahs: [4])
].sorted()

let recitersIdris = [
    Reciter(name: "Muftah Alsaltany", ayahIdentifier: "ar.minshawi", ayahBitrate: "128", surahLink: "https://quran-fjamfcbbeybteyat.z01.azurefd.net/Audio3/quran/MeftahAlstunai/edris_khalaf/", qiraah: Settings.Riwayah.idris)
].sorted()
