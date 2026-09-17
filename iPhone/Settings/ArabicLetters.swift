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

struct Tashkeel: Identifiable, Equatable {
    /// The English name is already the key the tashkeel views use in their `ForEach`es, and it is unique.
    var id: String { english }

    let english: String
    let arabic: String
    let tashkeelMark: String
    let transliteration: String

    /// The trilateral root of the mark's own Arabic name, spaced out (e.g. "ف ت ح" for fatḥah). The root is the
    /// teaching aid here: a fatḥah is named from "to open" because you open your mouth to say it, a kasrah from
    /// "to break" because you drop the jaw, a ḍammah from "to gather" because you gather the lips. Naming the
    /// root turns each mark from a symbol to memorize into an instruction.
    var root: String? = nil
    /// What that root means, phrased as the mouth movement it describes.
    var rootMeaning: String? = nil
    /// How to actually make the sound.
    var howTo: String? = nil
    /// How long the mark is held, in ḥarakāt. `nil` for marks that are not a vowel length at all (shaddah, sukūn).
    var length: String? = nil
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
        weightRule: "Heavy with fatha/damma, or sukoon preceded by fatha/damma (or by an incidental kasra); light with kasra, or sukoon preceded by an original kasra, unless an isti'la letter with fatha/damma follows in the same word (قِرطَاس), which makes it heavy."
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
        weight: .light
        // No `weightRule`: waaw is unconditionally light, and `ArabicView.alwaysWeightRule` now says so for
        // every unconditional letter in one shared sentence. Spelling it out only here made waaw and yaa look
        // like special cases.
    ),

    LetterData(
        id: LetterID.next(),
        letter: "ي",
        forms: ["ـي", "ـيـ", "يـ"],
        name: "يَاء",
        transliteration: "yaa",
        showTashkeel: true,
        sound: "y",
        weight: .light
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
    LetterData(id: LetterID.next(), letter: "آ", forms: ["ـآ", "ـآ ـ", "آ ـ"], name: "أَلِف مَدّ", transliteration: "alif madd", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "يٓ", forms: ["ـيٓ", "ـيٓـ", "يٓـ"], name: "يَاء مَدّ", transliteration: "yaa madd", showTashkeel: false, sound: ""),
    LetterData(id: LetterID.next(), letter: "وٓ", forms: ["ـوٓ", "ـوٓـ", "وٓـ"], name: "وَاو مَدّ", transliteration: "waaw madd", showTashkeel: false, sound: ""),
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

/// Where a non-Arabic letter comes from: the languages that added it to the Arabic script, and the sound
/// they added it for. Keyed by the letter's transliteration (the key the letter page's `nonArabicBaseSound`
/// already switches on). Shown on the letter's page and under the alphabet's NON-ARABIC LETTERS section:
/// "used in non-Arabic languages" named no language (user rule, 2026-09-15).
struct NonArabicLetterOrigin {
    /// The languages that write the letter, the most familiar first.
    let languages: String
    /// The sound it stands for, described by an English word that has it.
    let sound: String
}

let nonArabicLetterOrigins: [String: NonArabicLetterOrigin] = [
    "pe": NonArabicLetterOrigin(
        languages: "Persian, Urdu, Kurdish and Pashto",
        sound: "the \"p\" sound, which Arabic does not have: Arabic spells borrowed words with a baa instead, as in بَاكِسْتَان (Pakistan)"
    ),
    "che": NonArabicLetterOrigin(
        languages: "Persian, Urdu, Kurdish and Pashto",
        sound: "the \"ch\" sound, as in \"church\""
    ),
    "ve": NonArabicLetterOrigin(
        languages: "Kurdish, and Arabic dialect writing in Iraq and the Maghreb",
        sound: "the \"v\" sound, as in \"van\" (Malay and Indonesian Jawi write the same shape for \"p\")"
    ),
    "gaaf (gaa)": NonArabicLetterOrigin(
        languages: "Persian, Urdu, Kurdish and Pashto",
        sound: "the hard \"g\" sound, as in \"go\""
    ),
    "ngaf": NonArabicLetterOrigin(
        languages: "Uyghur, Kazakh and Kyrgyz, and Ottoman Turkish before it moved to the Latin alphabet",
        sound: "the \"ng\" sound, as in \"sing\" (Moroccan Arabic writes the same letter for a hard \"g\", as in أڭادير, Agadir)"
    ),
    "zhe": NonArabicLetterOrigin(
        languages: "Persian, Urdu, Kurdish and Pashto",
        sound: "the \"zh\" sound, the \"s\" of \"measure\""
    ),
]

/// A shape two (or more) letters make when they are written together: the mandatory laam-alif
/// ligature, the hamza forms of the definite article that a reader meets constantly in the mushaf,
/// and the stacked naskh pairs that look nothing like the letters standing alone.
///
/// These are NOT letters, which is exactly why they live apart from the alphabet: nothing here adds a
/// sound, and a beginner who files them as new letters has learned something wrong. What they add is
/// recognition, the step between knowing the 28 shapes and being able to read a line of the mushaf.
struct JoinedShape: Identifiable {
    var id: String { shape }
    /// The joined form as the mushaf prints it.
    let shape: String
    /// The letters it is made of, spelled out unjoined.
    let parts: String
    /// The name to read it by.
    let name: String
    let transliteration: String
    /// One line: what makes this shape worth knowing.
    let note: String
    /// A word from the Quran that contains it, and where it is.
    let example: String
    let exampleReference: String
    /// Whether the joining is REQUIRED (laam-alif is the only one) or a style the font chooses.
    let isMandatory: Bool
}

let joinedArabicShapes: [JoinedShape] = [
    JoinedShape(
        shape: "لا",
        parts: "ل + ا",
        name: "لَام أَلِف",
        transliteration: "laam alif",
        note: "The only ligature Arabic REQUIRES. Laam followed by alif must be written as this one joined shape; side by side and unjoined is simply incorrect, which is why it is taught with the alphabet. The sound does not change: laam, then the long alif.",
        example: "لَا",
        exampleReference: "the word of negation, and لَآ إِلَٰهَ إِلَّا ٱللَّهُ",
        isMandatory: true
    ),
    JoinedShape(
        shape: "ٱلۡأَ",
        parts: "ٱ + ل + أ",
        name: "أَل مَعَ هَمزَة مَفتُوحَة",
        transliteration: "al + hamza with fatHah",
        note: "The definite article on a word that begins with a hamza carrying a short fatHah: one beat, \"a\". Compare it with the madd form below - they differ only in the mark above the hamza, and that mark is the whole difference in length.",
        example: "ٱلۡأَرۡضِ",
        exampleReference: "al-ard, \"the earth\", Quran 2:11",
        isMandatory: false
    ),
    JoinedShape(
        shape: "ٱلۡأٓ",
        parts: "ٱ + ل + أ + madd",
        name: "أَل مَعَ أَلِف مَدّ",
        transliteration: "al + alif madd",
        note: "The same article on a word beginning with a LONG \"aa\": the madd sign (ٓ) over the hamza holds it about twice as long. This is the alif madd (آ) you already know, written the way the mushaf writes it here, as a hamza carrying the madd rather than as the single letter آ.",
        example: "ٱلۡأٓخِرَةِ",
        exampleReference: "al-aakhirah, \"the Hereafter\", Quran 2:102",
        isMandatory: false
    ),
    JoinedShape(
        shape: "يخ",
        parts: "ي + خ",
        name: "يَاء خَاء",
        transliteration: "yaa khaa",
        note: "Naskh stacks a yaa before khaa so the yaa tucks under the khaa's bowl. Look for the two dots below and the one dot above.",
        example: "يَخۡدَعُونَ",
        exampleReference: "Quran 2:9",
        isMandatory: false
    ),
    JoinedShape(
        shape: "يج",
        parts: "ي + ج",
        name: "يَاء جِيم",
        transliteration: "yaa jeem",
        note: "The same stack with jeem: one dot INSIDE the bowl instead of above it. Telling jeem, Haa and khaa apart by their dot is most of reading this shape.",
        example: "يَجۡعَلُونَ",
        exampleReference: "Quran 2:19",
        isMandatory: false
    ),
    JoinedShape(
        shape: "لح",
        parts: "ل + ح",
        name: "لَام حَاء",
        transliteration: "laam Haa",
        note: "After the definite article this is one of the most frequent shapes in the Quran: the laam's tail runs straight into the Haa with no dot at all.",
        example: "ٱلۡحَمۡدُ",
        exampleReference: "al-hamd, \"the praise\", Quran 1:2",
        isMandatory: false
    ),
    JoinedShape(
        shape: "لج",
        parts: "ل + ج",
        name: "لَام جِيم",
        transliteration: "laam jeem",
        note: "The same joint with a dot inside the bowl.",
        example: "ٱلۡجَنَّةَ",
        exampleReference: "al-jannah, \"the Garden\", Quran 2:35",
        isMandatory: false
    ),
    JoinedShape(
        shape: "لخ",
        parts: "ل + خ",
        name: "لَام خَاء",
        transliteration: "laam khaa",
        note: "And with the dot above: laam khaa.",
        example: "ٱلۡخَٰسِرُونَ",
        exampleReference: "Quran 2:27",
        isMandatory: false
    ),
    JoinedShape(
        shape: "لم",
        parts: "ل + م",
        name: "لَام مِيم",
        transliteration: "laam meem",
        note: "The meem's head sits tight against the laam's upright. Very common, and easy to misread as a single tall letter until you have seen it named.",
        example: "ٱلۡعَٰلَمِينَ",
        exampleReference: "al-'aalameen, \"the worlds\", Quran 1:2",
        isMandatory: false
    ),
    JoinedShape(
        shape: "مح",
        parts: "م + ح",
        name: "مِيم حَاء",
        transliteration: "meem Haa",
        note: "The meem's round head, then the Haa's open bowl beneath the line.",
        example: "ٱلۡمُحۡسِنِينَ",
        exampleReference: "Quran 2:58",
        isMandatory: false
    ),
    JoinedShape(
        shape: "نج",
        parts: "ن + ج",
        name: "نُون جِيم",
        transliteration: "noon jeem",
        note: "One dot above from the noon, one inside the bowl from the jeem: two dots that belong to two different letters.",
        example: "نَجَّيۡنَٰكُم",
        exampleReference: "Quran 2:49",
        isMandatory: false
    ),
    JoinedShape(
        shape: "سج",
        parts: "س + ج",
        name: "سِين جِيم",
        transliteration: "seen jeem",
        note: "The seen's three teeth run straight into the jeem's bowl, as in the word for prostration.",
        example: "ٱسۡجُدُواْ",
        exampleReference: "\"prostrate\", Quran 2:34",
        isMandatory: false
    ),
    JoinedShape(
        shape: "عج",
        parts: "ع + ج",
        name: "عَين جِيم",
        transliteration: "'ayn jeem",
        note: "The 'ayn's open mouth closes into the jeem below it.",
        example: "ٱلۡعِجۡلَ",
        exampleReference: "al-'ijl, \"the calf\", Quran 2:51",
        isMandatory: false
    ),
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

/// Ordered a → i → u (fatha, kasra, damma) - the order these are taught in - and grouped in threes, which is
/// how `ArabicLetterView` chunks them into rows: short vowels, then tanween, then the long vowels and their
/// madd forms, each triple following the same a/i/u sequence.
///
/// Every mark carries its own root, because the root *is* the instruction: fatḥah is from "to open" (you open
/// your mouth), kasrah from "to break" (you break the jaw downward), ḍammah from "to gather" (you gather the
/// lips forward). Lengths are in ḥarakāt: a short vowel is 1 count, its long partner is 2, and a madd marked
/// with the squiggle (ٓ) is longer still.
let tashkeels: [Tashkeel] = [
    Tashkeel(
        english: "Fatha", arabic: "فَتحَة", tashkeelMark: "َ", transliteration: "a",
        root: "ف ت ح", rootMeaning: "to open",
        howTo: "Open your mouth and let out a short \"a\", as in \"cup\". The name says what to do: you open.",
        length: "1 count"
    ),
    Tashkeel(
        english: "Kasra", arabic: "كَسرَة", tashkeelMark: "ِ", transliteration: "i",
        root: "ك س ر", rootMeaning: "to break",
        howTo: "Break your jaw downward and lower the sound to a short \"i\", as in \"sit\". The mark is written below the letter, and the sound drops below too.",
        length: "1 count"
    ),
    Tashkeel(
        english: "Damma", arabic: "ضَمَّة", tashkeelMark: "ُ", transliteration: "u",
        root: "ض م م", rootMeaning: "to gather, to join together",
        howTo: "Gather your lips and point them forward into a short \"u\", as in \"put\".",
        length: "1 count"
    ),
    Tashkeel(
        english: "Alif", arabic: "أَلِف", tashkeelMark: "َا", transliteration: "aa",
        root: "ف ت ح", rootMeaning: "the stretched fatha",
        howTo: "A fatha followed by alif. Same open mouth, simply held: the stronger, extended version of the fatha.",
        length: "2 counts"
    ),
    Tashkeel(
        english: "Yaa", arabic: "يَاء", tashkeelMark: "ِي", transliteration: "ii",
        root: "ك س ر", rootMeaning: "the stretched kasra",
        howTo: "A kasra followed by yaa. The extended version of the kasra: \"ee\" as in \"see\".",
        length: "2 counts"
    ),
    Tashkeel(
        english: "Waaw", arabic: "وَاو", tashkeelMark: "ُو", transliteration: "uu",
        root: "ض م م", rootMeaning: "the stretched damma",
        howTo: "A damma followed by waaw. The extended version of the damma: \"oo\" as in \"moon\".",
        length: "2 counts"
    ),
    // Row order of the per-letter table (three marks to a row): the short vowels, then the long vowels
    // that stretch them, then the tanween that close them with a noon (user rule, 2026-09-15: the
    // tanween used to sit between the two, splitting the a/aa, i/ii, u/uu pairs across a row).
    Tashkeel(
        english: "Fathatayn", arabic: "فَتحَتَين", tashkeelMark: "ًا", transliteration: "an",
        root: "ف ت ح", rootMeaning: "two fathas",
        howTo: "Two fathas stacked. Say the fatha, then close it with an \"n\" sound: \"an\". The \"n\" is pronounced but never written as a letter.",
        length: "1 count, then the noon"
    ),
    Tashkeel(
        english: "Kasratayn", arabic: "كَسرَتَين", tashkeelMark: "ٍ", transliteration: "in",
        root: "ك س ر", rootMeaning: "two kasras",
        howTo: "Two kasras stacked. Say the kasra, then close it with an \"n\": \"in\".",
        length: "1 count, then the noon"
    ),
    Tashkeel(
        english: "Dammatayn", arabic: "ضَمَّتَين", tashkeelMark: "ٌ", transliteration: "un",
        root: "ض م م", rootMeaning: "two dammas",
        howTo: "Two dammas stacked. Say the damma, then close it with an \"n\": \"un\".",
        length: "1 count, then the noon"
    ),
    Tashkeel(
        english: "Dagger Alif", arabic: "ألف خنجرية", tashkeelMark: "\u{064E}\u{0670}\u{0640}", transliteration: "aa",
        root: "خ ن ج ر", rootMeaning: "dagger, for the small blade-like stroke",
        howTo: "A small vertical stroke standing in for a full alif. It sounds exactly like a long alif; only the writing is shorter.",
        length: "2 counts"
    ),
    Tashkeel(
        english: "Miniature Yaa", arabic: "يَاء صغيرة", tashkeelMark: "ِۦ", transliteration: "ii",
        root: "ص غ ر", rootMeaning: "to be small",
        howTo: "A small yaa written above the line. It sounds exactly like a long yaa.",
        length: "2 counts"
    ),
    Tashkeel(
        english: "Miniature Waaw", arabic: "واو صغيرة", tashkeelMark: "ُۥ", transliteration: "uu",
        root: "ص غ ر", rootMeaning: "to be small",
        howTo: "A small waaw written above the line. It sounds exactly like a long waaw.",
        length: "2 counts"
    ),
    // Alif + a COMBINING maddah (U+0653), exactly like the yaa and waaw madds below it. It used to be the
    // precomposed ALEF WITH MADDA ABOVE (U+0622), which the Quranic fonts draw in its isolated form - so it sat
    // detached from the letter it belongs to (شَ آ instead of شَآ).
    Tashkeel(
        english: "Alif Madd", arabic: "أَلِف مَدّ", tashkeelMark: "\u{064E}\u{0627}\u{0653}", transliteration: "aaaa",
        root: "م د د", rootMeaning: "to stretch, to extend",
        howTo: "The squiggle (ٓ) over the alif tells you to hold it well past the ordinary two counts. How long depends on which madd rule applies.",
        length: "4 to 6 counts"
    ),
    Tashkeel(
        english: "Yaa Madd", arabic: "يَاء مَدّ", tashkeelMark: "ِيٓ", transliteration: "iiii",
        root: "م د د", rootMeaning: "to stretch, to extend",
        howTo: "The squiggle over the long yaa. Hold the \"ee\" well past two counts.",
        length: "4 to 6 counts"
    ),
    Tashkeel(
        english: "Waaw Madd", arabic: "واو مَدّ", tashkeelMark: "ُوٓ", transliteration: "uuuu",
        root: "م د د", rootMeaning: "to stretch, to extend",
        howTo: "The squiggle over the long waaw. Hold the \"oo\" well past two counts.",
        length: "4 to 6 counts"
    ),
    // The small (superscript) forms, in the same a/i/u order. The dagger alif takes a maddah just as the
    // miniature yaa and waaw do - it was the one missing from the set. Like the plain dagger alif above, it
    // rides on a tatweel (ـ) rather than sitting on the letter, which is how it's shown in isolation.
    Tashkeel(
        english: "Small Alif Madd", arabic: "ألف خنجرية مدّ", tashkeelMark: "\u{064E}\u{0670}\u{0653}\u{0640}", transliteration: "aaaa",
        root: "م د د", rootMeaning: "to stretch, to extend",
        howTo: "A dagger alif carrying the madd squiggle. Same sound as the full alif madd, written small.",
        length: "4 to 6 counts"
    ),
    Tashkeel(
        english: "Small Yaa Madd", arabic: "ياء مدّ صغيرة", tashkeelMark: "ِۦٓ", transliteration: "iiii",
        root: "م د د", rootMeaning: "to stretch, to extend",
        howTo: "A miniature yaa carrying the madd squiggle. Same sound as the full yaa madd, written small.",
        length: "4 to 6 counts"
    ),
    Tashkeel(
        english: "Small Waaw Madd", arabic: "واو مدّ صغيرة", tashkeelMark: "ُۥٓ", transliteration: "uuuu",
        root: "م د د", rootMeaning: "to stretch, to extend",
        howTo: "A miniature waaw carrying the madd squiggle. Same sound as the full waaw madd, written small.",
        length: "4 to 6 counts"
    ),
    // The three alif maqsuurah forms, a → i → u order not applying here: they are one vowel written three ways,
    // bare, with the small alif above it, and with the small alif carrying the madd squiggle.
    Tashkeel(
        english: "Alif MaqSuurah", arabic: "أَلِف مَقصُورَة", tashkeelMark: "َى", transliteration: "aa",
        root: "ق ص ر", rootMeaning: "to shorten",
        howTo: "A yaa without dots doing the job of an alif at the end of a word. It is \"shortened\" only in how it is written; it still sounds like a long alif.",
        length: "2 counts"
    ),
    Tashkeel(
        english: "Alif MaqSuurah 2", arabic: "أَلِف مَقصُورَة بِأَلِف صَغِيرَة", tashkeelMark: "\u{0649}\u{0670}", transliteration: "aa",
        root: "ق ص ر", rootMeaning: "to shorten",
        howTo: "An alif maqsuurah with a small alif written above it, spelling out the long \"aa\" the dotless yaa is standing in for.",
        length: "2 counts"
    ),
    Tashkeel(
        english: "Alif MaqSuurah Madd", arabic: "أَلِف مَقصُورَة مَدّ", tashkeelMark: "\u{0649}\u{0670}\u{0653}", transliteration: "aaaa",
        root: "م د د", rootMeaning: "to stretch, to extend",
        howTo: "The same alif maqsuurah with the madd squiggle on top, so it is held well past two counts.",
        length: "4 to 6 counts"
    ),
    // Not vowel lengths at all: one doubles a letter, the other takes its vowel away.
    Tashkeel(
        english: "Shaddah", arabic: "شَدَّة", tashkeelMark: "ّ", transliteration: "",
        root: "ش د د", rootMeaning: "to make strong, to intensify",
        howTo: "Doubles the letter. Land on it and hold it, as in the double \"n\" of \"unnatural\". It is not a vowel, so it rides on top of one.",
        length: nil
    ),
    Tashkeel(
        english: "Sukuun 1", arabic: "سُكُون", tashkeelMark: "ْ", transliteration: "",
        root: "س ك ن", rootMeaning: "to be still, to be silent",
        howTo: "Marks a letter with no vowel after it. The mouth stops still on the letter: \"ab\", not \"aba\".",
        length: nil
    ),
    Tashkeel(
        english: "Sukuun 2", arabic: "سكون عثماني", tashkeelMark: "ۡ", transliteration: "",
        root: "س ك ن", rootMeaning: "to be still, to be silent",
        howTo: "The same sukuun, in the Uthmani script of the mushaf. Identical meaning, different shape.",
        length: nil
    )
]

// The favorite-letters accessor lives next to `LetterData` (not in Settings.swift) so the core settings
// file names no letter model type - it keeps only the raw `Data` @AppStorage backing. Same seam as the
// Quran accessors in SettingsQuran.swift.
extension Settings {
    /// Memoized: the alphabet rows call `isLetterFavorite` per row per render.
    private static var favoriteLettersCache: (data: Data, value: [LetterData])?
    var favoriteLetters: [LetterData] {
        get {
            if let cached = Self.favoriteLettersCache, cached.data == favoriteLetterData {
                return cached.value
            }
            let decoded = (try? Self.decoder.decode([LetterData].self, from: favoriteLetterData)) ?? []
            Self.favoriteLettersCache = (favoriteLetterData, decoded)
            return decoded
        }
        set {
            let encoded = (try? Self.encoder.encode(newValue)) ?? Data()
            Self.favoriteLettersCache = (encoded, newValue)
            favoriteLetterData = encoded
        }
    }

    func toggleLetterFavorite(letterData: LetterData) {
        withAnimation {
            if isLetterFavorite(letterData: letterData) {
                favoriteLetters.removeAll(where: { $0.id == letterData.id })
            } else {
                favoriteLetters.append(letterData)
            }
        }
    }

    func isLetterFavorite(letterData: LetterData) -> Bool {
        favoriteLetters.contains { $0.id == letterData.id }
    }
}
