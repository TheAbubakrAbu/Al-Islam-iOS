import SwiftUI

struct LetterData: Identifiable, Codable, Equatable, Comparable {
    let id: Int
    let letter: String
    let forms: [String]
    let name: String
    let transliteration: String
    let showTashkeel: Bool
    let sound: String

    var weight: LetterWeight?
    var weightRule: String?

    static func < (lhs: LetterData, rhs: LetterData) -> Bool {
        lhs.id < rhs.id
    }

    var isNonArabicScriptLetter: Bool {
        nonArabicArabicScriptLetters.contains { $0.id == id }
    }
}

enum LetterWeight: String, Codable {
    case light
    case heavy
    case conditional
    case followsPrevious
}

struct Tashkeel {
    let english: String
    let arabic: String
    let tashkeelMark: String
    let transliteration: String
}

private enum LetterID {
    private static var nextValue = 1

    static func next() -> Int {
        defer { nextValue += 1 }
        return nextValue
    }
}

let standardArabicLetters: [LetterData] = [
    LetterData(
        id: LetterID.next(),
        letter: "ا",
        forms: ["ـا", "ـا ـ", "ا ـ"],
        name: "أَلِف",
        transliteration: "alif",
        showTashkeel: false,
        sound: "a",
        weight: .followsPrevious,
        weightRule: "Alif has no weight of its own; it follows the heaviness or lightness of the previous letter."
    ),

    LetterData(id: LetterID.next(), letter: "ب", forms: ["ـب", "ـبـ", "بـ"], name: "بَاء", transliteration: "baa", showTashkeel: true, sound: "b", weight: .light),
    LetterData(id: LetterID.next(), letter: "ت", forms: ["ـت", "ـتـ", "تـ"], name: "تَاء", transliteration: "taa", showTashkeel: true, sound: "t", weight: .light),
    LetterData(id: LetterID.next(), letter: "ث", forms: ["ـث", "ـثـ", "ثـ"], name: "ثَاء", transliteration: "thaa", showTashkeel: true, sound: "th", weight: .light),
    LetterData(id: LetterID.next(), letter: "ج", forms: ["ـج", "ـجـ", "جـ"], name: "جِيم", transliteration: "jeem", showTashkeel: true, sound: "j", weight: .light),
    LetterData(id: LetterID.next(), letter: "ح", forms: ["ـح", "ـحـ", "حـ"], name: "حَاء", transliteration: "Haa", showTashkeel: true, sound: "H", weight: .light),

    LetterData(id: LetterID.next(), letter: "خ", forms: ["ـخ", "ـخـ", "خـ"], name: "خَاء", transliteration: "khaa", showTashkeel: true, sound: "kh", weight: .heavy),

    LetterData(id: LetterID.next(), letter: "د", forms: ["ـد", "ـد ـ", "د ـ"], name: "دَال", transliteration: "daal", showTashkeel: true, sound: "d", weight: .light),
    LetterData(id: LetterID.next(), letter: "ذ", forms: ["ـذ", "ـذ ـ", "ذ ـ"], name: "ذَال", transliteration: "dhaal", showTashkeel: true, sound: "dh", weight: .light),

    LetterData(
        id: LetterID.next(),
        letter: "ر",
        forms: ["ـر", "ـر ـ", "ر ـ"],
        name: "رَاء",
        transliteration: "raa",
        showTashkeel: true,
        sound: "r",
        weight: .conditional,
        weightRule: "Heavy with fatha/damma, or sukoon preceded by fatha/damma (or by an incidental kasra); light with kasra, or sukoon preceded by an original kasra — unless an isti'la letter with fatha/damma follows in the same word (قِرْطَاس), which makes it heavy."
    ),

    LetterData(id: LetterID.next(), letter: "ز", forms: ["ـز", "ـز ـ", "ز ـ"], name: "زَاي", transliteration: "zaay", showTashkeel: true, sound: "z", weight: .light),
    LetterData(id: LetterID.next(), letter: "س", forms: ["ـس", "ـسـ", "سـ"], name: "سِين", transliteration: "seen", showTashkeel: true, sound: "s", weight: .light),
    LetterData(id: LetterID.next(), letter: "ش", forms: ["ـش", "ـشـ", "شـ"], name: "شِين", transliteration: "sheen", showTashkeel: true, sound: "sh", weight: .light),

    LetterData(id: LetterID.next(), letter: "ص", forms: ["ـص", "ـصـ", "صـ"], name: "صَاد", transliteration: "Saad", showTashkeel: true, sound: "S", weight: .heavy),
    LetterData(id: LetterID.next(), letter: "ض", forms: ["ـض", "ـضـ", "ضـ"], name: "ضَاد", transliteration: "Daad", showTashkeel: true, sound: "D", weight: .heavy),
    LetterData(id: LetterID.next(), letter: "ط", forms: ["ـط", "ـطـ", "طـ"], name: "طَاء", transliteration: "Taa", showTashkeel: true, sound: "T", weight: .heavy),
    LetterData(id: LetterID.next(), letter: "ظ", forms: ["ـظ", "ـظـ", "ظـ"], name: "ظَاء", transliteration: "Dhaa", showTashkeel: true, sound: "Dh", weight: .heavy),

    LetterData(id: LetterID.next(), letter: "ع", forms: ["ـع", "ـعـ", "عـ"], name: "عَين", transliteration: "'ayn", showTashkeel: true, sound: "'a", weight: .light),
    LetterData(id: LetterID.next(), letter: "غ", forms: ["ـغ", "ـغـ", "غـ"], name: "غَين", transliteration: "ghayn", showTashkeel: true, sound: "gh", weight: .heavy),
    LetterData(id: LetterID.next(), letter: "ف", forms: ["ـف", "ـفـ", "فـ"], name: "فَاء", transliteration: "faa", showTashkeel: true, sound: "f", weight: .light),
    LetterData(id: LetterID.next(), letter: "ق", forms: ["ـق", "ـقـ", "قـ"], name: "قَاف", transliteration: "qaaf", showTashkeel: true, sound: "q", weight: .heavy),
    LetterData(id: LetterID.next(), letter: "ك", forms: ["ـك", "ـكـ", "كـ"], name: "كَاف", transliteration: "kaaf", showTashkeel: true, sound: "k", weight: .light),

    LetterData(
        id: LetterID.next(),
        letter: "ل",
        forms: ["ـل", "ـلـ", "لـ"],
        name: "لَام",
        transliteration: "laam",
        showTashkeel: true,
        sound: "l",
        weight: .conditional,
        weightRule: "Heavy only in the Name of Allah when preceded by fatha or damma; otherwise light."
    ),

    LetterData(id: LetterID.next(), letter: "م", forms: ["ـم", "ـمـ", "مـ"], name: "مِيم", transliteration: "meem", showTashkeel: true, sound: "m", weight: .light),
    LetterData(id: LetterID.next(), letter: "ن", forms: ["ـن", "ـنـ", "نـ"], name: "نُون", transliteration: "nuun", showTashkeel: true, sound: "n", weight: .light),
    LetterData(id: LetterID.next(), letter: "ه", forms: ["ـه", "ـهـ", "هـ"], name: "هَاء", transliteration: "haa", showTashkeel: true, sound: "h", weight: .light),

    LetterData(
        id: LetterID.next(),
        letter: "و",
        forms: ["ـو", "ـو ـ", "و ـ"],
        name: "وَاو",
        transliteration: "waaw",
        showTashkeel: true,
        sound: "w",
        weight: .light,
        weightRule: "Waaw is pronounced as a light letter in all positions."
    ),

    LetterData(
        id: LetterID.next(),
        letter: "ي",
        forms: ["ـي", "ـيـ", "يـ"],
        name: "يَاء",
        transliteration: "yaa",
        showTashkeel: true,
        sound: "y",
        weight: .light,
        weightRule: "Yaa is pronounced as a light letter in all positions."
    )
]

let otherArabicLetters: [LetterData] = [
    LetterData(id: LetterID.next(), letter: "ة", forms: ["ـة", "ـة ـ", "ة ـ"], name: "تَاء مَربُوطَة", transliteration: "taa marbuuTah", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ء", forms: ["ـ ء", "ـ ء ـ", "ء ـ"], name: "هَمزَة", transliteration: "hamza", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "أ", forms: ["ـأ", "ـأ ـ", "أ ـ"], name: "هَمزَة عَلَى أَلِف", transliteration: "hamza on alif", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "إ", forms: ["ـإ", "ـإ ـ", "إ ـ"], name: "هَمزَة تَحتَ أَلِف", transliteration: "hamza under alif", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ئ", forms: ["ـئ", "ـئ ـ", "ئ ـ"], name: "هَمزَة عَلَى يَاء", transliteration: "hamza on yaa", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ؤ", forms: ["ـؤ", "ـؤ ـ", "ؤ ـ"], name: "هَمزَة عَلَى وَاو", transliteration: "hamza on waaw", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ٱ", forms: ["ٱـ", "ـٱ", "ـٱـ"], name: "هَمزَة الوَصل", transliteration: "hamzatul waSl", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "آ", forms: ["ـآ", "ـآ ـ", "آ ـ"], name: "أَلِف مَدَّ", transliteration: "alif madd", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "يٓ", forms: ["ـيٓ", "ـيٓـ", "يٓـ"], name: "يَاء مَدّ", transliteration: "yaa madd", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "وٓ", forms: ["ـوٓ", "ـوٓـ", "وٓـ"], name: "واو مَدّ", transliteration: "waaw madd", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ى", forms: ["ـى", "ـى ـ", "ى ـ"], name: "أَلِف مَقصُورَة", transliteration: "alif maqSoorah", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ل ا - لا", forms: ["ـلا", "ـلا ـ", "لا ـ"], name: "لَام أَلِف", transliteration: "laam alif", showTashkeel: false, sound: ""),
]

let nonArabicArabicScriptLetters: [LetterData] = [
    LetterData(id: LetterID.next(), letter: "پ", forms: ["ـپ", "ـپـ", "پـ"], name: "پے", transliteration: "pe", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "چ", forms: ["ـچ", "ـچـ", "چـ"], name: "چے", transliteration: "che", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ڤ", forms: ["ـڤ", "ـڤـ", "ڤـ"], name: "ڤے", transliteration: "ve", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "گ", forms: ["ـگ", "ـگـ", "گـ"], name: "گاف", transliteration: "gaaf (gaa)", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ڭ", forms: ["ـڭ", "ـڭـ", "ڭـ"], name: "ڭاف", transliteration: "ngaf", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "ژ", forms: ["ـژ", "ـژ ـ", "ژ ـ"], name: "ژے", transliteration: "zhe", showTashkeel: false, sound: "")
]

let numbers = [
    (number: "٠", name: "صِفر", transliteration: "sifr", englishNumber: "0"),
    (number: "١", name: "وَاحِد", transliteration: "waahid", englishNumber: "1"),
    (number: "٢", name: "اِثنَان", transliteration: "ithnaan", englishNumber: "2"),
    (number: "٣", name: "ثَلاثَة", transliteration: "thalaathah", englishNumber: "3"),
    (number: "٤", name: "أَربَعَة", transliteration: "arba'ah", englishNumber: "4"),
    (number: "٥", name: "خَمسَة", transliteration: "khamsah", englishNumber: "5"),
    (number: "٦", name: "سِتَّة", transliteration: "sittah", englishNumber: "6"),
    (number: "٧", name: "سَبعَة", transliteration: "sab'ah", englishNumber: "7"),
    (number: "٨", name: "ثَمَانِيَة", transliteration: "thamaaniyah", englishNumber: "8"),
    (number: "٩", name: "تِسعَة", transliteration: "tis'ah", englishNumber: "9"),
    (number: "١٠", name: "عَشَرَة", transliteration: "'asharah", englishNumber: "10")
]

/// Ordered a → i → u (fatha, kasra, damma) — the order these are taught in — and grouped in threes, which is
/// how `ArabicLetterView` chunks them into rows: short vowels, then tanween, then the long vowels and their
/// madd forms, each triple following the same a/i/u sequence.
let tashkeels: [Tashkeel] = [
    Tashkeel(english: "Fatha", arabic: "فَتحَة", tashkeelMark: "َ", transliteration: "a"),
    Tashkeel(english: "Kasra", arabic: "كَسرَة", tashkeelMark: "ِ", transliteration: "i"),
    Tashkeel(english: "Damma", arabic: "ضَمَّة", tashkeelMark: "ُ", transliteration: "u"),
    Tashkeel(english: "Fathatayn", arabic: "فَتحَتَين", tashkeelMark: "ًا", transliteration: "an"),
    Tashkeel(english: "Kasratayn", arabic: "كَسرَتَين", tashkeelMark: "ٍ", transliteration: "in"),
    Tashkeel(english: "Dammatayn", arabic: "ضَمَّتَين", tashkeelMark: "ٌ", transliteration: "un"),
    Tashkeel(english: "Alif", arabic: "أَلِف", tashkeelMark: "َا", transliteration: "aa"),
    Tashkeel(english: "Yaa", arabic: "يَاء", tashkeelMark: "ِي", transliteration: "ii"),
    Tashkeel(english: "Waaw", arabic: "وَاو", tashkeelMark: "ُو", transliteration: "uu"),
    Tashkeel(english: "Dagger Alif", arabic: "ألف خنجرية", tashkeelMark: "\u{064E}\u{0670}\u{0640}", transliteration: "aa"),
    Tashkeel(english: "Miniature Yaa", arabic: "يَاء صغيرة", tashkeelMark: "ِۦ", transliteration: "ii"),
    Tashkeel(english: "Miniature Waaw", arabic: "واو صغيرة", tashkeelMark: "ُۥ", transliteration: "uu"),
    // Alif + a COMBINING maddah (U+0653), exactly like the yaa and waaw madds below it. It used to be the
    // precomposed ALEF WITH MADDA ABOVE (U+0622), which the Quranic fonts draw in its isolated form — so it sat
    // detached from the letter it belongs to (شَ آ instead of شَآ).
    Tashkeel(english: "Alif Madd", arabic: "أَلِف مَدّ", tashkeelMark: "\u{064E}\u{0627}\u{0653}", transliteration: "aaaa"),
    Tashkeel(english: "Yaa Madd", arabic: "يَاء مَدّ", tashkeelMark: "ِيٓ", transliteration: "iiii"),
    Tashkeel(english: "Waaw Madd", arabic: "واو مَدّ", tashkeelMark: "ُوٓ", transliteration: "uuuu"),
    // The small (superscript) forms, in the same a/i/u order. The dagger alif takes a maddah just as the
    // miniature yaa and waaw do — it was the one missing from the set. Like the plain dagger alif above, it
    // rides on a tatweel (ـ) rather than sitting on the letter, which is how it's shown in isolation.
    Tashkeel(english: "Small Alif Madd", arabic: "ألف خنجرية مدّ", tashkeelMark: "\u{064E}\u{0670}\u{0653}\u{0640}", transliteration: "aaaa"),
    Tashkeel(english: "Small Yaa Madd", arabic: "ياء مدّ صغيرة", tashkeelMark: "ِۦٓ", transliteration: "iiii"),
    Tashkeel(english: "Small Waaw Madd", arabic: "واو مدّ صغيرة", tashkeelMark: "ُۥٓ", transliteration: "uuuu"),
    // Last two rows: [MaqSuurah · Shaddah · Sukoon], then the Uthmani sukoon ALONE beneath the plain one —
    // they're the same mark in two scripts, so they read as a pair stacked in the same column.
    Tashkeel(english: "Alif MaqSuurah", arabic: "أَلِف مَقصُورَة", tashkeelMark: "َى", transliteration: "aa"),
    Tashkeel(english: "Shaddah", arabic: "شَدَّة", tashkeelMark: "ّ", transliteration: ""),
    Tashkeel(english: "Sukuun 1", arabic: "سُكُون", tashkeelMark: "ْ", transliteration: ""),
    Tashkeel(english: "Sukuun 2", arabic: "سكون عثماني", tashkeelMark: "ۡ", transliteration: "")
]
