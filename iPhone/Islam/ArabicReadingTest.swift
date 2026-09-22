import Foundation
import Combine

// The Reading Test (Arabic Alphabet > Reading Test): a ladder of tiers in the order a qaa'idah teaches
// reading, from single letters to words printed with no tashkeel at all. It tests reading, spelling
// and pronunciation, not meaning (Abu, 2026-09-21: "focused more on pronunciation spelling and reading
// than understanding and comprehension, with different tiers similar to the Arabic beginner book
// qaedah before starting the Quran").
//
// This file is the model and has no SwiftUI in it, so the question builder can be run and checked
// outside the app. The words come from `ArabicReadingBank` (generated and verified by
// Scripts/build_reading_test.py); nothing in here types a word or a reading of its own. What this file
// adds is the WRONG answers, and those are built the way a learner goes wrong: one vowel swapped, a
// long vowel read short, a shaddah missed, a heavy letter read as its light twin.

// MARK: - Text

/// Everything the test does to a string of Arabic: which sukoon it draws, how a word is pulled apart
/// into letters for Beginner Mode and for the build-a-word tiles, and how it is handed to the voice.
enum ReadingTestText {
    static let fatha: Unicode.Scalar = "\u{064E}"
    static let damma: Unicode.Scalar = "\u{064F}"
    static let kasra: Unicode.Scalar = "\u{0650}"
    static let fathatan: Unicode.Scalar = "\u{064B}"
    static let dammatan: Unicode.Scalar = "\u{064C}"
    static let kasratan: Unicode.Scalar = "\u{064D}"
    static let shaddah: Unicode.Scalar = "\u{0651}"
    /// In the bank (the mushaf's own encoding) U+0652 is the small circle over a letter that is never
    /// read, and U+06E1 is the sukoon. In ordinary Arabic U+0652 IS the sukoon.
    static let circle: Unicode.Scalar = "\u{0652}"
    static let mushafSukoon: Unicode.Scalar = "\u{06E1}"
    static let dagger: Unicode.Scalar = "\u{0670}"
    static let maddah: Unicode.Scalar = "\u{0653}"
    static let smallWaw: Unicode.Scalar = "\u{06E5}"
    static let smallYaa: Unicode.Scalar = "\u{06E6}"
    static let wasla: Unicode.Scalar = "\u{0671}"
    static let alif: Unicode.Scalar = "\u{0627}"
    static let waw: Unicode.Scalar = "\u{0648}"
    static let yaa: Unicode.Scalar = "\u{064A}"
    static let maqsura: Unicode.Scalar = "\u{0649}"
    static let taaMarbuta: Unicode.Scalar = "\u{0629}"
    static let hamzaOnAlif: Unicode.Scalar = "\u{0623}"
    static let hamzaUnderAlif: Unicode.Scalar = "\u{0625}"

    static let shortVowels: [Unicode.Scalar] = [fatha, kasra, damma]
    static let tanweens: [Unicode.Scalar] = [fathatan, kasratan, dammatan]

    static func isMark(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x064B...0x065F, 0x0670, 0x06D6...0x06DC, 0x06DF...0x06E4, 0x06E7, 0x06E8, 0x06EA...0x06ED: return true
        default: return false
        }
    }

    /// The word as it is drawn. The bank stores the mushaf's marks; with the plain sukoon chosen
    /// (`Settings.quranicSukoonInLetterPractice` off, the default) the sukoon becomes the ordinary
    /// U+0652 and the "never read" circle is dropped, which is how ordinary Arabic writes both.
    static func display(_ word: String, mushafMarks: Bool) -> String {
        guard !mushafMarks else { return word }
        var out = String.UnicodeScalarView()
        for scalar in word.unicodeScalars where scalar != circle {
            out.append(scalar == mushafSukoon ? circle : scalar)
        }
        return String(out)
    }

    /// The word as the voice should hear it: ordinary marks only, the small letters spelled out as
    /// the full letters they sound like, and no madd sign (composed with its alif it becomes آ,
    /// which the voice reads as a hamza).
    static func spoken(_ word: String) -> String {
        var out = String.UnicodeScalarView()
        for scalar in word.unicodeScalars {
            switch scalar {
            case circle, maddah: continue
            case mushafSukoon: out.append(circle)
            case smallWaw: out.append(waw)
            case smallYaa: out.append(yaa)
            default: out.append(scalar)
            }
        }
        return String(out)
    }

    /// The word with nothing on it, the way ordinary Arabic prints: marks off, the small letters
    /// gone with them, and a plain alif for the wasl alif.
    static func bare(_ word: String) -> String {
        var out = String.UnicodeScalarView()
        for scalar in word.unicodeScalars {
            if isMark(scalar) || scalar == smallWaw || scalar == smallYaa { continue }
            out.append(scalar == wasla ? alif : scalar)
        }
        return String(out)
    }

    /// The word letter by letter: each letter with the marks it carries. A small waaw or yaa is not
    /// a combining mark, so it arrives as a character of its own; it belongs to the haa it follows.
    static func letters(_ word: String) -> [String] {
        var out: [String] = []
        for character in word {
            let scalars = character.unicodeScalars
            let isSmallLetter = scalars.first == smallWaw || scalars.first == smallYaa
            if isSmallLetter, !out.isEmpty {
                out[out.count - 1] += String(character)
            } else {
                out.append(String(character))
            }
        }
        return out
    }

    /// Beginner Mode's spelling of a word or a phrase: a space between every letter, and a wider
    /// gap between words so they can still be told apart.
    static func spaced(_ text: String) -> String {
        text.split(separator: " ")
            .map { letters(String($0)).joined(separator: " ") }
            .joined(separator: "    ")
    }
}

// MARK: - The reading scheme

/// The Latin spelling the test reads words in: the letter sounds the alphabet pages already use,
/// made unambiguous ('ayn gets its own sign, because a test cannot ask "which spelling?" when two
/// letters share one).
enum ReadingScheme {
    static let ayn = "\u{02BF}"
    static let hamza = "'"

    static let consonants: [String: String] = [
        "ء": hamza, "أ": hamza, "إ": hamza, "ؤ": hamza, "ئ": hamza,
        "ب": "b", "ت": "t", "ث": "th", "ج": "j", "ح": "H", "خ": "kh", "د": "d", "ذ": "dh",
        "ر": "r", "ز": "z", "س": "s", "ش": "sh", "ص": "S", "ض": "D", "ط": "T", "ظ": "Dh",
        "ع": ayn, "غ": "gh", "ف": "f", "ق": "q", "ك": "k", "ل": "l", "م": "m", "ن": "n",
        "ه": "h", "و": "w", "ي": "y",
    ]

    private static let digraphs: Set<String> = ["th", "sh", "dh", "kh", "gh", "Dh"]
    static let vowels: Set<String> = ["a", "i", "u"]

    /// A reading as sounds: digraphs kept whole, and the hyphen, the hamza and a space each a token.
    static func tokens(_ reading: String) -> [String] {
        let characters = Array(reading)
        var out: [String] = []
        var index = 0
        while index < characters.count {
            if index + 1 < characters.count {
                let pair = String(characters[index...index + 1])
                if digraphs.contains(pair) {
                    out.append(pair)
                    index += 2
                    continue
                }
            }
            out.append(String(characters[index]))
            index += 1
        }
        return out
    }

    static func isConsonant(_ token: String) -> Bool {
        !vowels.contains(token) && token != "-" && token != " "
    }

    /// Tokens back into a reading, with the hyphen that keeps s + h from reading as sh.
    static func join(_ tokens: [String]) -> String {
        var out = ""
        for token in tokens {
            if token == "h", let last = out.last, "tsdkgDT".contains(last),
               !digraphs.contains(String(out.suffix(2))) {
                out += "-"
            }
            out += token
        }
        return out
    }

    /// Every line of the key, in the order the alphabet runs. Shown on the Reading Key sheet.
    static let key: [(sign: String, letter: String, note: String)] = [
        ("'", "ء", "hamza: a catch in the throat, as between the two halves of \u{201C}uh-oh\u{201D}. Not written at the start of a word."),
        ("b", "ب", "as in book"),
        ("t", "ت", "as in table"),
        ("th", "ث", "as in three, never as in this"),
        ("j", "ج", "as in jam"),
        ("H", "ح", "a deep, breathy h from the throat. Capital, to tell it from the soft h"),
        ("kh", "خ", "the ch of the Scottish loch"),
        ("d", "د", "as in door"),
        ("dh", "ذ", "the th of this, never of three"),
        ("r", "ر", "a tapped r, as in the Spanish pero"),
        ("z", "ز", "as in zebra"),
        ("s", "س", "as in sun"),
        ("sh", "ش", "as in ship"),
        ("S", "ص", "a heavy s, the mouth full. Capital = the heavy twin"),
        ("D", "ض", "a heavy d, from the side of the tongue"),
        ("T", "ط", "a heavy t"),
        ("Dh", "ظ", "a heavy dh"),
        (ayn, "ع", "'ayn: a voiced squeeze deep in the throat. A sound, not a pause"),
        ("gh", "غ", "a gargled r, as in the French Paris"),
        ("f", "ف", "as in fan"),
        ("q", "ق", "a k made at the very back of the mouth"),
        ("k", "ك", "as in king"),
        ("l", "ل", "as in lamp"),
        ("m", "م", "as in moon"),
        ("n", "ن", "as in noon"),
        ("h", "ه", "as in hat"),
        ("w", "و", "as in water"),
        ("y", "ي", "as in yes"),
    ]

    static let vowelKey: [(sign: String, note: String)] = [
        ("a  i  u", "the short vowels: fatha, kasra, damma (one count)"),
        ("aa  ii  uu", "the long vowels, written with alif, yaa and waaw (two counts)"),
        ("aaaa  iiii  uuuu", "a long vowel under the madd sign, held four to six counts"),
        ("ay  aw", "the soft letters: a fatha gliding into a yaa or a waaw"),
        ("an  in  un", "tanween: the n is heard and never written"),
        ("bb", "a doubled letter is a shaddah: hold it"),
        ("al-  ash-sh", "the hyphen marks the article; before a sun letter the laam is silent and the letter doubles"),
        ("s-h", "a hyphen between two letters keeps them apart: s then h, not sh"),
    ]
}

// MARK: - Items

/// One thing the test can ask about: a letter, a word, an ayah, a name.
struct ReadingItem: Hashable {
    /// The Arabic as the bank stores it (the mushaf's marks), or bare for the unmarked tiers.
    let arabic: String
    /// What the learner must choose: how it is read.
    let reading: String
    /// How it is read when the reader stops on it. Equal to `reading` where stopping changes nothing.
    var stopped: String = ""
    /// Where the word was cut from, "2:29".
    var reference: String? = nil
    /// The word-by-word gloss of that occurrence, or a name's meaning. Shown after the answer only.
    var gloss: String? = nil
    /// The unmarked tiers: the same word with its marks on, for the second hint and for the voice.
    var marked: String? = nil
    /// The word sounded out, (letters, reading) a syllable at a time.
    var sounded: [SoundedPart] = []
    /// What the voice says, when that is not the Arabic itself (a letter is called by its name).
    var spokenOverride: String? = nil

    struct SoundedPart: Hashable {
        let arabic: String
        let reading: String
    }

    /// The text handed to the voice.
    var spoken: String { ReadingTestText.spoken(spokenOverride ?? marked ?? arabic) }
}

// MARK: - The ladder

enum ReadingStage: Int, CaseIterable, Identifiable {
    case letters, marks, longSounds, stops, mushaf, unmarked

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .letters: return "The Letters"
        case .marks: return "The Vowel Marks"
        case .longSounds: return "Long Sounds"
        case .stops: return "Stops and Doubles"
        case .mushaf: return "Reading the Mushaf"
        case .unmarked: return "Without Tashkeel"
        }
    }

    var arabic: String {
        switch self {
        case .letters: return "الحُرُوف"
        case .marks: return "الحَرَكَات"
        case .longSounds: return "المَدّ وَاللِّين"
        case .stops: return "السُّكُون وَالشَّدَّة"
        case .mushaf: return "قِرَاءَة المُصحَف"
        case .unmarked: return "بِلَا تَشكِيل"
        }
    }

    var blurb: String {
        switch self {
        case .letters: return "Every letter alone, joined, and by its name."
        case .marks: return "Fatha, kasra, damma, and the tanween that doubles them."
        case .longSounds: return "What stretches a vowel, and what only glides."
        case .stops: return "The letter with no vowel, and the letter said twice."
        case .mushaf: return "What the mushaf writes that ordinary Arabic does not."
        case .unmarked: return "How Arabic is printed everywhere except the mushaf."
        }
    }
}

/// How a tier draws its Arabic.
enum ReadingDisplay {
    /// Beginner Mode: a space between every letter. The very first word tier reads this way.
    case spaced
    /// Joined, the way the mushaf prints it.
    case joined
    /// Joined and always in the mushaf's own marks, whatever sukoon the reader has chosen: the
    /// tier is ABOUT those marks.
    case mushaf
    /// No marks, in the plain system face (a mushaf face drops a final yaa's dots).
    case unmarked
}

/// What a question asks the learner to do.
enum ReadingSkill: String, CaseIterable, Identifiable {
    /// See the Arabic, choose how it is read.
    case read
    /// See the reading, choose the Arabic that spells it.
    case spell
    /// Hear it, choose the Arabic.
    case listen
    /// See (and hear) the reading, tap the letters into place.
    case build
    /// See a word, choose how it is read when you stop on it.
    case stop
    /// See a joined word, choose the letters it is made of.
    case takeApart
    /// See loose letters, choose how they look joined.
    case join
    /// Read it aloud, then check yourself against the voice. Never part of a scored test.
    case aloud

    var id: String { rawValue }

    var title: String {
        switch self {
        case .read: return "Read"
        case .spell: return "Spell"
        case .listen: return "Listen"
        case .build: return "Build"
        case .stop: return "Stop"
        case .takeApart: return "Take Apart"
        case .join: return "Join"
        case .aloud: return "Read Aloud"
        }
    }

    var caption: String {
        switch self {
        case .read: return "See the Arabic, choose how it is read"
        case .spell: return "See the reading, choose the spelling"
        case .listen: return "Hear it, choose what was said"
        case .build: return "Tap the letters into place"
        case .stop: return "Choose how the word ends when you stop on it"
        case .takeApart: return "See a joined word, choose its letters"
        case .join: return "See the letters, choose the joined word"
        case .aloud: return "Say it, then check yourself against the voice"
        }
    }

    var systemImage: String {
        switch self {
        case .read: return "eye"
        case .spell: return "character.cursor.ibeam"
        case .listen: return "ear"
        case .build: return "square.grid.3x1.below.line.grid.1x2"
        case .stop: return "hand.raised"
        case .takeApart: return "scissors"
        case .join: return "link"
        case .aloud: return "mouth"
        }
    }

    /// Needs the device's Arabic voice.
    var needsVoice: Bool { self == .listen }
}

/// What the hint button does on a tier.
enum ReadingHint {
    /// Beginner Mode: every letter apart. The default, and Abu's rule for the whole test.
    case letterByLetter
    /// The unmarked tiers: letter by letter first, then the word with its marks on.
    case letterByLetterThenMarks
    /// Nothing to reveal that would not BE the answer (the letter tiers, the joined-shapes tier).
    case none
}

struct ReadingTier: Identifiable, Hashable {
    let id: String
    let stage: ReadingStage
    let title: String
    let arabic: String
    /// One line for the ladder's row.
    let summary: String
    /// What the tier teaches and tests, a paragraph at a time. No Arabic words are typed here: the
    /// tier page draws its worked examples from the bank.
    let teaches: [String]
    /// The tile's glyph on the ladder.
    let specimen: String
    let display: ReadingDisplay
    let skills: [ReadingSkill]
    let hint: ReadingHint

    static func == (lhs: ReadingTier, rhs: ReadingTier) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// 1-based place on the ladder.
    var number: Int { (ReadingTier.all.firstIndex(of: self) ?? 0) + 1 }

    var next: ReadingTier? {
        guard let index = ReadingTier.all.firstIndex(of: self), index + 1 < ReadingTier.all.count else { return nil }
        return ReadingTier.all[index + 1]
    }

    static func tier(id: String) -> ReadingTier? { all.first { $0.id == id } }

    static func tiers(in stage: ReadingStage) -> [ReadingTier] { all.filter { $0.stage == stage } }

    static let all: [ReadingTier] = [
        ReadingTier(
            id: "letters", stage: .letters, title: "Letter Sounds", arabic: "الحُرُوف المُفرَدَة",
            summary: "Each letter alone: its sound and its name",
            teaches: [
                "Every letter on its own: the sound it makes, and the name you hear it called by.",
                "Letters that differ only by their dots, and letters that sound alike to an English ear, are asked against each other on purpose. Those are the ones that get mixed up.",
            ],
            specimen: "ب", display: .joined, skills: [.read, .spell, .listen], hint: .none),
        ReadingTier(
            id: "forms", stage: .letters, title: "Joined Shapes", arabic: "الحُرُوف المُرَكَّبَة",
            summary: "Take a joined word apart, and join loose letters up",
            teaches: [
                "Arabic is written joined, and a letter changes shape at the start, in the middle and at the end of a word.",
                "Here a joined word is taken apart into its letters, and loose letters are joined back up. No vowels yet: only the shapes, and the dots that tell them apart.",
            ],
            specimen: "ـبـ", display: .unmarked, skills: [.takeApart, .join, .build], hint: .none),
        ReadingTier(
            id: "openers", stage: .letters, title: "Opening Letters", arabic: "الحُرُوف المُقَطَّعَة",
            summary: "The letters that open twenty-nine surahs, read by name",
            teaches: [
                "Twenty-nine surahs open with letters that are read by their NAMES, one after another, never as a word.",
                "All it takes is knowing what each letter is called, which is why a qaa'idah teaches them this early. The madd sign over a letter means its name is held long.",
            ],
            specimen: "الٓمٓ", display: .mushaf, skills: [.read, .spell], hint: .letterByLetter),
        ReadingTier(
            id: "harakat", stage: .marks, title: "Short Vowels", arabic: "الحَرَكَات",
            summary: "Fatha, kasra and damma on one letter at a time",
            teaches: [
                "A fatha above the letter is a short a, a kasra below it a short i, and a damma above it a short u. One count each.",
                "Every syllable you will ever read is built on one of these three, so they come first, one letter at a time.",
            ],
            specimen: "بَ", display: .joined, skills: [.read, .spell, .listen], hint: .none),
        ReadingTier(
            id: "spaced", stage: .marks, title: "Letter by Letter", arabic: "التَّهَجِّي",
            summary: "Whole words with every letter apart, as Beginner Mode writes them",
            teaches: [
                "Whole words, written the way Beginner Mode writes them: every letter apart, each one carrying its own mark.",
                "Read each letter, then run them together. Nothing is joined yet, so there is no shape to work out: only the sounds.",
            ],
            specimen: "بَ تَ", display: .spaced, skills: [.read, .spell, .listen, .build], hint: .none),
        ReadingTier(
            id: "vowels", stage: .marks, title: "Short-Vowel Words", arabic: "كَلِمَات بِالحَرَكَات",
            summary: "The same kind of word with its letters joined",
            teaches: [
                "The same kind of word with its letters joined, the way the mushaf prints them.",
                "If a word will not come apart in your head, the hint spaces it out again, letter by letter.",
            ],
            specimen: "كَتَبَ", display: .joined, skills: [.read, .spell, .listen, .build], hint: .letterByLetter),
        ReadingTier(
            id: "tanween", stage: .marks, title: "Tanween", arabic: "التَّنوِين",
            summary: "The doubled mark that adds an n: an, in, un",
            teaches: [
                "Two fathas, two kasras or two dammas on the last letter add an n that is heard and never written: an, in, un.",
                "A double fatha usually sits before an alif. That alif is a seat for the mark, and is not read.",
            ],
            specimen: "بٌ", display: .joined, skills: [.read, .spell, .listen, .build], hint: .letterByLetter),
        ReadingTier(
            id: "long", stage: .longSounds, title: "Long Vowels", arabic: "حُرُوف المَدّ",
            summary: "Alif, yaa and waaw stretching the vowel before them",
            teaches: [
                "An alif after a fatha, a yaa after a kasra, and a waaw after a damma stretch that vowel to two counts: aa, ii, uu.",
                "The madd letter carries no mark of its own. That is how you know it is stretching the letter before it and not starting a syllable.",
            ],
            specimen: "بَا", display: .joined, skills: [.read, .spell, .listen, .build], hint: .letterByLetter),
        ReadingTier(
            id: "small", stage: .longSounds, title: "Small Alif, Yaa and Waaw", arabic: "الحُرُوف الصَّغِيرَة",
            summary: "The long vowels the mushaf writes small",
            teaches: [
                "The mushaf writes some long vowels small: a dagger alif standing over a letter, a small yaa or waaw after the pronoun for \u{201C}him\u{201D}, and a dotless yaa (alif maqsuurah) closing a word.",
                "They sound exactly like the full letters. Only the writing is smaller.",
            ],
            specimen: "بَٰ", display: .joined, skills: [.read, .spell, .listen, .build], hint: .letterByLetter),
        ReadingTier(
            id: "leen", stage: .longSounds, title: "Soft Letters", arabic: "حُرُوف اللِّين",
            summary: "A yaa or waaw after a fatha glides: ay, aw",
            teaches: [
                "A yaa or a waaw with a sukoon, after a FATHA, does not stretch anything: it glides. Fatha into yaa is ay, fatha into waaw is aw.",
                "This is the one readers get wrong, by stretching it into ii or uu. The vowel before it is what decides.",
            ],
            specimen: "بَيۡ", display: .joined, skills: [.read, .spell, .listen, .build], hint: .letterByLetter),
        ReadingTier(
            id: "sukoon", stage: .stops, title: "Sukoon", arabic: "السُّكُون",
            summary: "The letter with no vowel: stop on it",
            teaches: [
                "A sukoon means no vowel. Stop on the letter and close the syllable with it, joined to the vowel before.",
                "The usual slip is to give the letter a vowel it does not have. If there is a sukoon, nothing follows the consonant.",
            ],
            specimen: "بۡ", display: .joined, skills: [.read, .spell, .listen, .build], hint: .letterByLetter),
        ReadingTier(
            id: "shaddah", stage: .stops, title: "Shaddah", arabic: "الشَّدَّة",
            summary: "The doubled letter: land on it, then carry on",
            teaches: [
                "A shaddah doubles its letter. The first copy closes the syllable before it, and the second carries the vowel written with the shaddah.",
                "In the readings a shaddah is simply the letter written twice. Missing it changes the word.",
            ],
            specimen: "بَّ", display: .joined, skills: [.read, .spell, .listen, .build], hint: .letterByLetter),
        ReadingTier(
            id: "mixed", stage: .stops, title: "Hamza and the Madd Sign", arabic: "الهَمزَة وَالمَدّ",
            summary: "The hamza on its seats, and the long vowel held longer",
            teaches: [
                "A hamza is one sound, a catch in the throat, whatever it sits on: an alif, a waaw, a yaa, or nothing at all. The readings write it as an apostrophe, and leave it off at the very start of a word.",
                "The madd sign over a long vowel means hold it longer, four to six counts. The readings write that vowel four letters long.",
            ],
            specimen: "آ", display: .joined, skills: [.read, .spell, .listen, .build], hint: .letterByLetter),
        ReadingTier(
            id: "article", stage: .mushaf, title: "Sun and Moon Letters", arabic: "اللَّام الشَّمسِيَّة وَالقَمَرِيَّة",
            summary: "The article al-, read or swallowed, and the Name of Allah",
            teaches: [
                "Before a moon letter the article is read in full, al-, and its laam carries a sukoon. Before a sun letter the laam is written and not read: the sun letter is doubled instead, and carries a shaddah to say so.",
                "The Name of Allah is read with a long vowel that the script does not write: allaah.",
            ],
            specimen: "ٱلۡ", display: .joined, skills: [.read, .spell, .listen, .build], hint: .letterByLetter),
        ReadingTier(
            id: "wasl", stage: .mushaf, title: "Hamzat al-Wasl", arabic: "هَمزَة الوَصل",
            summary: "The alif that is only read when you start on it",
            teaches: [
                "An alif with a small Saad over it is a joining hamza: it is read only when you START on its word. After wa- or fa- it is silent, and the reading runs straight into the next letter.",
                "Started on, a verb opens with u when its third letter carries a damma and with i otherwise. A handful of nouns (the words for name and son among them) always open with i.",
            ],
            specimen: "ٱ", display: .joined, skills: [.read, .spell, .listen, .build], hint: .letterByLetter),
        ReadingTier(
            id: "silent", stage: .mushaf, title: "Marks of the Mushaf", arabic: "عَلَامَات الضَّبط",
            summary: "Letters written and never read, and the noon left bare",
            teaches: [
                "The mushaf puts a small circle over a letter that is written and never read, such as the alif after the waaw of a plural verb.",
                "It leaves a noon with no mark at all when that noon is hidden into the letter after it. The noon is still read, through the nose.",
                "This tier always shows the mushaf's own marks: its sukoon is the small head of a khaa, so that the circle can mean \u{201C}not read\u{201D}.",
            ],
            specimen: "واْ", display: .mushaf, skills: [.read, .spell, .listen, .build], hint: .letterByLetter),
        ReadingTier(
            id: "waqf", stage: .mushaf, title: "Stopping on a Word", arabic: "الوَقف",
            summary: "How a word's ending changes when you stop on it",
            teaches: [
                "You never stop on a vowel. Stop on a word and its last short vowel is dropped, and so is a tanween of kasra or damma.",
                "A double fatha becomes a long aa, and a taa marbuutah is read as a soft h. A long vowel or a sukoon stays as it is.",
            ],
            specimen: "ة", display: .joined, skills: [.stop], hint: .letterByLetter),
        ReadingTier(
            id: "ayat", stage: .mushaf, title: "Short Ayat", arabic: "آيَات قَصِيرَة",
            summary: "Whole ayat read straight through, stopping at the end",
            teaches: [
                "Short ayat, read straight through. Inside an ayah a joining hamza is dropped, so the word before runs into the laam or the letter after it.",
                "The last word is read the way you would stop on it.",
            ],
            specimen: "۝", display: .joined, skills: [.read, .spell, .listen, .build], hint: .letterByLetter),
        ReadingTier(
            id: "bare", stage: .unmarked, title: "Unmarked Words", arabic: "كَلِمَات بِلَا تَشكِيل",
            summary: "No tashkeel: read the word by its long vowels",
            teaches: [
                "Outside the mushaf, Arabic is printed with no tashkeel. The long vowels are still written, as alif, waaw and yaa, and they are what you read a word by.",
                "Every wrong answer here is a reading the bare spelling could NOT have, so the spelling alone settles it. Words are read stopped, without their case endings, the way they are said.",
                "This is for reading outside the Quran. The mushaf is always fully marked.",
            ],
            specimen: "كتب", display: .unmarked, skills: [.read, .spell, .listen, .build], hint: .letterByLetterThenMarks),
        ReadingTier(
            id: "names", stage: .unmarked, title: "Names You Know", arabic: "أَسمَاء مَعرُوفَة",
            summary: "Surah names and the Names of Allah, printed bare",
            teaches: [
                "Surah names and the Names of Allah, the way a contents page or a poster prints them: no marks at all.",
                "You already know how they sound. The test is finding them in the bare script.",
            ],
            specimen: "يس", display: .unmarked, skills: [.read, .spell], hint: .letterByLetterThenMarks),
        ReadingTier(
            id: "everyday", stage: .unmarked, title: "Everyday Phrases", arabic: "عِبَارَات يَومِيَّة",
            summary: "The phrases you say every day, the way they are written",
            teaches: [
                "The phrases you say every day, the way they are written in a message or on a wall.",
                "You know them by ear. Here you meet them by eye.",
            ],
            specimen: "سلام", display: .unmarked, skills: [.read, .spell, .build], hint: .letterByLetter),
    ]
}

// MARK: - The bank, parsed

/// `ArabicReadingBank`'s tables turned into items, once, on first use.
enum ReadingTestBank {
    private static func rows(_ table: String) -> [[String]] {
        table.split(separator: "\n").map { line in
            line.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        }
    }

    private static func sounded(_ field: String) -> [ReadingItem.SoundedPart] {
        field.split(separator: " ").compactMap { pair in
            let halves = pair.split(separator: "=", maxSplits: 1).map(String.init)
            return halves.count == 2 ? ReadingItem.SoundedPart(arabic: halves[0], reading: halves[1]) : nil
        }
    }

    /// The Quranic words, by the tier the builder filed them under.
    static let words: [String: [ReadingItem]] = {
        var out: [String: [ReadingItem]] = [:]
        for row in rows(ArabicReadingBank.words) where row.count >= 6 {
            let item = ReadingItem(arabic: row[1], reading: row[2], stopped: row[3], reference: row[4],
                                   gloss: row[5], sounded: row.count > 6 ? sounded(row[6]) : [])
            out[row[0], default: []].append(item)
        }
        return out
    }()

    static let ayat: [ReadingItem] = rows(ArabicReadingBank.ayat).compactMap { row in
        guard row.count >= 4 else { return nil }
        return ReadingItem(arabic: row[0], reading: row[1], stopped: row[1], reference: row[2], gloss: row[3])
    }

    static let unmarked: [ReadingItem] = rows(ArabicReadingBank.unmarked).compactMap { row in
        guard row.count >= 5 else { return nil }
        return ReadingItem(arabic: row[0], reading: row[1], stopped: row[1], reference: row[3], gloss: row[4],
                           marked: row[2], sounded: row.count > 5 ? sounded(row[5]) : [])
    }

    /// Surah names, then the Names of Allah. `kind` keeps a name's wrong answers among its own kind.
    static let names: [(kind: String, item: ReadingItem)] = rows(ArabicReadingBank.names).compactMap { row in
        guard row.count >= 5 else { return nil }
        return (row[0], ReadingItem(arabic: row[1], reading: row[3], stopped: row[3], gloss: row[4], marked: row[2]))
    }

    static let everyday: [ReadingItem] = rows(ArabicReadingBank.everyday).compactMap { row in
        guard row.count >= 3 else { return nil }
        return ReadingItem(arabic: row[0], reading: row[1], stopped: row[1], gloss: row[2])
    }

    /// The fourteen openings, read by the names of their letters.
    static let openers: [ReadingItem] = LetterTraits.openings.compactMap { opening in
        let names: [String] = opening.text.unicodeScalars.compactMap { scalar in
            guard !ReadingTestText.isMark(scalar) else { return nil }
            return standardArabicLetters.first { $0.letter == String(scalar) }?.transliteration
        }
        guard !names.isEmpty else { return nil }
        let surahs = opening.surahs.map(String.init).joined(separator: ", ")
        return ReadingItem(arabic: opening.text, reading: names.joined(separator: " "),
                           stopped: names.joined(separator: " "),
                           gloss: opening.surahs.count == 1 ? "Opens surah \(surahs)" : "Opens surahs \(surahs)")
    }

    /// The 28 letters, read by their sound. The alif has none of its own, so it is left to its name.
    static let letters: [ReadingItem] = standardArabicLetters.compactMap { letter in
        guard let sound = ReadingScheme.consonants[letter.letter] else { return nil }
        return ReadingItem(arabic: letter.letter, reading: sound, stopped: sound,
                           gloss: letter.englishSound, spokenOverride: letter.name)
    }

    /// One letter under each short vowel: 27 letters and the hamza on its alif, three ways.
    static let harakat: [ReadingItem] = {
        var out: [ReadingItem] = []
        let marks: [(Unicode.Scalar, String)] = [(ReadingTestText.fatha, "a"), (ReadingTestText.kasra, "i"), (ReadingTestText.damma, "u")]
        for letter in standardArabicLetters {
            guard let sound = ReadingScheme.consonants[letter.letter] else { continue }
            for (mark, vowel) in marks {
                let arabic = letter.letter + String(mark)
                out.append(ReadingItem(arabic: arabic, reading: sound + vowel, stopped: sound + vowel,
                                       gloss: "\(letter.transliteration) with a \(vowel == "a" ? "fatha" : vowel == "i" ? "kasra" : "damma")"))
            }
        }
        return out
    }()

    /// Bare joined words of two to four letters, for the joined-shapes tier: the skeletons of the
    /// first word tiers, so the shapes met here are the ones read next.
    static let shapes: [ReadingItem] = {
        var seen: Set<String> = []
        var out: [ReadingItem] = []
        for tier in ["spaced", "vowels", "tanween", "long", "leen", "sukoon"] {
            for item in words[tier] ?? [] {
                let bare = ReadingTestText.bare(item.arabic)
                guard (2...4).contains(bare.count), seen.insert(bare).inserted else { continue }
                let spelled = bare.map(String.init).joined(separator: " ")
                out.append(ReadingItem(arabic: bare, reading: spelled, stopped: spelled))
            }
        }
        return out
    }()

    static func items(for tier: ReadingTier) -> [ReadingItem] {
        switch tier.id {
        case "letters": return letters
        case "forms": return shapes
        case "openers": return openers
        case "harakat": return harakat
        case "spaced": return (words["spaced"] ?? [])
        case "ayat": return ayat
        case "bare": return unmarked
        case "names": return names.map(\.item)
        case "everyday": return everyday
        default: return words[tier.id] ?? []
        }
    }

    /// A few worked examples for the tier page: the commonest items, which the builder lists first.
    static func examples(for tier: ReadingTier, count: Int = 4) -> [ReadingItem] {
        let items = items(for: tier)
        switch tier.id {
        case "letters", "harakat":
            // the head of the alphabet says nothing: take a spread
            return stride(from: 1, to: items.count, by: max(1, items.count / count)).prefix(count).map { items[$0] }
        case "names":
            return Array(items.prefix(2)) + Array(items.dropFirst(114).prefix(2))
        default:
            return Array(items.prefix(count))
        }
    }
}

// MARK: - Questions

struct ReadingChoice: Identifiable, Hashable {
    let id: Int
    let text: String
    let isArabic: Bool
}

struct ReadingTile: Identifiable, Hashable {
    let id: Int
    let text: String
}

struct ReadingQuestion: Identifiable {
    let id = UUID()
    let tier: ReadingTier
    let skill: ReadingSkill
    let item: ReadingItem
    /// What is asked, in words.
    let ask: String
    /// What is shown: Arabic, or a reading. Empty for a listening question.
    let prompt: String
    let promptIsArabic: Bool
    /// Multiple choice. Empty for `build` and `aloud`.
    let choices: [ReadingChoice]
    let answer: Int
    /// `build`: the tiles on offer, and the order that is right.
    let tiles: [ReadingTile]
    let target: [String]
    /// True when the tiles are whole words (an ayah, a phrase), not letters.
    let tilesAreWords: Bool

    /// True when the tier has a hint to give (the letter tiers have nothing to reveal but the answer).
    var allowsHint: Bool {
        if case .none = tier.hint { return false }
        return true
    }
}

/// Builds rounds. Everything random goes through `generator`, so the harness can replay a round.
struct ReadingQuestionFactory {
    var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
    /// False where the device has no Arabic voice: listening questions are left out.
    var voiceAvailable = true

    // MARK: Rounds

    /// A scored round: the tier's skills mixed, no word asked twice.
    mutating func round(for tier: ReadingTier, length: Int = 10, only skill: ReadingSkill? = nil) -> [ReadingQuestion] {
        let items = ReadingTestBank.items(for: tier)
        guard !items.isEmpty else { return [] }
        var skills = tier.skills.filter { voiceAvailable || !$0.needsVoice }
        if let skill { skills = [skill] }
        guard !skills.isEmpty else { return [] }

        var out: [ReadingQuestion] = []
        var pool = shuffled(items)
        var turn = Int(next(upTo: skills.count))
        var guardrail = 0
        while out.count < length, guardrail < length * 6 {
            guardrail += 1
            if pool.isEmpty { pool = shuffled(items) }
            let item = pool.removeLast()
            let chosen = skills[turn % skills.count]
            turn += 1
            if let question = question(item, in: tier, skill: chosen) {
                out.append(question)
            }
        }
        return out
    }

    /// Find My Level: two questions a tier, up the ladder. The caller stops at the first miss.
    mutating func placementPair(for tier: ReadingTier) -> [ReadingQuestion] {
        let preferred: [ReadingSkill] = tier.skills.contains(.read) ? [.read, .spell]
            : tier.skills.contains(.stop) ? [.stop, .stop] : Array(tier.skills.prefix(2))
        var out: [ReadingQuestion] = []
        var pool = shuffled(ReadingTestBank.items(for: tier))
        var guardrail = 0
        while out.count < 2, !pool.isEmpty, guardrail < 12 {
            guardrail += 1
            let skill = preferred[out.count % preferred.count]
            if let question = question(pool.removeLast(), in: tier, skill: tier.skills.contains(skill) ? skill : tier.skills[0]) {
                out.append(question)
            }
        }
        return out
    }

    /// A mixed review across every tier in `tiers`.
    mutating func review(of tiers: [ReadingTier], length: Int = 15) -> [ReadingQuestion] {
        guard !tiers.isEmpty else { return [] }
        var out: [ReadingQuestion] = []
        var guardrail = 0
        while out.count < length, guardrail < length * 6 {
            guardrail += 1
            let tier = tiers[Int(next(upTo: tiers.count))]
            out += round(for: tier, length: 1)
        }
        return out
    }

    // MARK: One question

    mutating func question(_ item: ReadingItem, in tier: ReadingTier, skill: ReadingSkill) -> ReadingQuestion? {
        switch skill {
        case .read, .stop: return readingQuestion(item, in: tier, skill: skill)
        case .spell, .listen: return spellingQuestion(item, in: tier, skill: skill)
        case .takeApart, .join: return shapeQuestion(item, in: tier, skill: skill)
        case .build: return buildQuestion(item, in: tier)
        case .aloud:
            return ReadingQuestion(tier: tier, skill: .aloud, item: item, ask: "Read it aloud, then check yourself.",
                                   prompt: item.arabic, promptIsArabic: true, choices: [], answer: 0,
                                   tiles: [], target: [], tilesAreWords: false)
        }
    }

    /// Arabic shown, readings to choose from.
    private mutating func readingQuestion(_ item: ReadingItem, in tier: ReadingTier, skill: ReadingSkill) -> ReadingQuestion? {
        let right = skill == .stop ? item.stopped : item.reading
        let wrong: [String]
        switch tier.id {
        case "letters": wrong = wrongLetterSounds(for: item)
        case "openers": wrong = wrongFromPool(right, pool: ReadingTestBank.openers.map(\.reading))
        case "names": wrong = wrongNames(for: item, arabic: false)
        case "everyday": wrong = wrongFromPool(right, pool: ReadingTestBank.everyday.map(\.reading))
        case "waqf": wrong = wrongStops(for: item)
        default: wrong = wrongReadings(for: right, item: item, tier: tier)
        }
        guard wrong.count == 3 else { return nil }
        let (choices, answer) = arrange(right: right, wrong: wrong, arabic: false)
        let ask: String
        switch (skill, tier.id) {
        case (.stop, _): ask = "How is this read when you STOP on it?"
        case (_, "letters"): ask = "Which sound does this letter make?"
        case (_, "openers"): ask = "How are these opening letters read?"
        case (_, "names"): ask = "Which name is this?"
        case (_, "everyday"): ask = "Which phrase is this?"
        case (_, "bare"): ask = "Which reading fits this spelling?"
        default: ask = "How is this read?"
        }
        return ReadingQuestion(tier: tier, skill: skill, item: item, ask: ask, prompt: item.arabic, promptIsArabic: true,
                               choices: choices, answer: answer, tiles: [], target: [], tilesAreWords: false)
    }

    /// A reading shown (or spoken), Arabic to choose from.
    private mutating func spellingQuestion(_ item: ReadingItem, in tier: ReadingTier, skill: ReadingSkill) -> ReadingQuestion? {
        let wrong: [String]
        switch tier.id {
        case "letters": wrong = wrongLetters(for: item)
        case "openers": wrong = wrongFromPool(item.arabic, pool: ReadingTestBank.openers.map(\.arabic))
        case "names": wrong = wrongNames(for: item, arabic: true)
        case "everyday": wrong = wrongFromPool(item.arabic, pool: ReadingTestBank.everyday.map(\.arabic))
        case "ayat": wrong = wrongAyat(for: item)
        default: wrong = wrongSpellings(for: item, tier: tier)
        }
        guard wrong.count == 3 else { return nil }
        let (choices, answer) = arrange(right: item.arabic, wrong: wrong, arabic: true)
        let ask: String
        if skill == .listen {
            ask = tier.id == "letters" ? "Which letter did you hear named?" : "Which one did you hear?"
        } else {
            ask = tier.id == "letters" ? "Which letter makes this sound?" : "Which spelling is read this way?"
        }
        return ReadingQuestion(tier: tier, skill: skill, item: item, ask: ask,
                               prompt: skill == .listen ? "" : item.reading, promptIsArabic: false,
                               choices: choices, answer: answer, tiles: [], target: [], tilesAreWords: false)
    }

    /// The joined-shapes tier: a bare word against its letters, either way round.
    private mutating func shapeQuestion(_ item: ReadingItem, in tier: ReadingTier, skill: ReadingSkill) -> ReadingQuestion? {
        var wrongWords: [String] = []
        var guardrail = 0
        while wrongWords.count < 3, guardrail < 40 {
            guardrail += 1
            guard let swapped = ArabicMoves.lookAlike(ReadingTestText.letters(item.arabic), using: &generator)?.joined(),
                  swapped != item.arabic, !wrongWords.contains(swapped) else { continue }
            wrongWords.append(swapped)
        }
        guard wrongWords.count == 3 else { return nil }
        let spell: (String) -> String = { $0.map(String.init).joined(separator: " ") }
        if skill == .takeApart {
            let (choices, answer) = arrange(right: item.reading, wrong: wrongWords.map(spell), arabic: true)
            return ReadingQuestion(tier: tier, skill: skill, item: item, ask: "Which letters is this word made of?",
                                   prompt: item.arabic, promptIsArabic: true, choices: choices, answer: answer,
                                   tiles: [], target: [], tilesAreWords: false)
        }
        let (choices, answer) = arrange(right: item.arabic, wrong: wrongWords, arabic: true)
        return ReadingQuestion(tier: tier, skill: skill, item: item, ask: "How do these letters look joined?",
                               prompt: item.reading, promptIsArabic: true, choices: choices, answer: answer,
                               tiles: [], target: [], tilesAreWords: false)
    }

    /// Tiles to tap into place: a word's letters, or a phrase's words, with a few that do not belong.
    private mutating func buildQuestion(_ item: ReadingItem, in tier: ReadingTier) -> ReadingQuestion? {
        let isPhrase = item.arabic.contains(" ")
        let target: [String]
        var decoys: [String] = []
        if isPhrase {
            target = item.arabic.split(separator: " ").map(String.init)
            let others = ReadingTestBank.items(for: tier).filter { $0 != item }
                .flatMap { $0.arabic.split(separator: " ").map(String.init) }
                .filter { !target.contains($0) }
            decoys = Array(Set(shuffled(others).prefix(8))).prefix(2).map { $0 }
        } else {
            target = ReadingTestText.letters(item.arabic)
            guard target.count >= 2 else { return nil }
            var guardrail = 0
            while decoys.count < 2, guardrail < 30 {
                guardrail += 1
                let index = Int(next(upTo: target.count))
                let move = tier.display == .unmarked || next(upTo: 2) == 0
                    ? ArabicMoves.lookAlike([target[index]], using: &generator)
                    : ArabicMoves.haraka([target[index]], using: &generator)
                guard let decoy = move?.first, !target.contains(decoy), !decoys.contains(decoy) else { continue }
                decoys.append(decoy)
            }
        }
        let tiles = shuffled(target + decoys).enumerated().map { ReadingTile(id: $0.offset, text: $0.element) }
        let ask = isPhrase ? "Tap the words into order." : tier.id == "forms" ? "Tap the letters of this word, in order." : "Spell it: tap the letters in order."
        return ReadingQuestion(tier: tier, skill: .build, item: item, ask: ask,
                               prompt: tier.id == "forms" ? item.arabic : item.reading,
                               promptIsArabic: tier.id == "forms", choices: [], answer: 0,
                               tiles: tiles, target: target, tilesAreWords: isPhrase)
    }

    // MARK: Wrong readings

    /// Three readings a learner could plausibly give instead, the tier's own mistake first.
    private mutating func wrongReadings(for right: String, item: ReadingItem, tier: ReadingTier) -> [String] {
        let focus = LatinMoves.focus(for: tier.id, arabic: item.marked ?? item.arabic)
        let fallback: [LatinMoves.Move] = tier.display == .unmarked
            ? [.shorten, .lengthen, .consonant, .moveLong]
            : [.vowel, .shorten, .lengthen, .undouble, .consonant, .double]
        var out: [String] = []
        var guardrail = 0
        // A phrase's wrong answers start on a random word and move along it, one word each.
        let firstWord = Int(next(upTo: 8))
        // Two from the tier's own mistakes, one from anywhere, so the focus is always on the table.
        while out.count < 3, guardrail < 80 {
            guardrail += 1
            let moves = out.count < 2 && guardrail < 40 ? focus : focus + fallback
            guard !moves.isEmpty else { continue }
            let move = moves[Int(next(upTo: moves.count))]
            guard let wrong = LatinMoves.apply(move, to: right, word: guardrail < 40 ? firstWord + out.count : nil, using: &generator),
                  wrong != right, !out.contains(wrong), wrong != item.reading || right != item.reading else { continue }
            out.append(wrong)
        }
        return out
    }

    /// Stopping: the written reading is the first wrong answer, then the wrong ways of stopping.
    private mutating func wrongStops(for item: ReadingItem) -> [String] {
        let right = item.stopped
        let reading = item.reading
        var candidates: [String] = [reading]                                 // read on, not stopped
        let tokens = ReadingScheme.tokens(reading)
        let endsLong = tokens.count >= 2 && ReadingScheme.vowels.contains(tokens[tokens.count - 1])
            && tokens[tokens.count - 2] == tokens[tokens.count - 1]
        if item.arabic.unicodeScalars.contains(ReadingTestText.taaMarbuta) {
            let stem = String(right.dropLast())                              // raHma-
            candidates += [stem + "t", stem + "taa"]                        // raHmat, raHmataa
        } else if endsLong {
            candidates += [String(reading.dropLast()), right + "u"]         // lahu, lahu
        } else if reading.hasSuffix("an") {
            candidates += [String(reading.dropLast(2)), String(reading.dropLast(1))]          // qaliil, qaliila
        } else if reading.hasSuffix("un") || reading.hasSuffix("in") {
            candidates += [String(reading.dropLast(2)) + "aa", String(reading.dropLast(1))]   // aliimaa, aliimu
        } else if let last = tokens.last, ReadingScheme.vowels.contains(last) {
            candidates.append(reading + last)                                // the vowel held instead of dropped
            candidates.append(right + (last == "a" ? "i" : "a"))             // stopped on the wrong vowel
        }
        var out: [String] = []
        for candidate in shuffled(candidates) where candidate != right && !out.contains(candidate) {
            out.append(candidate)
            if out.count == 3 { break }
        }
        var guardrail = 0
        while out.count < 3, guardrail < 30 {
            guardrail += 1
            guard let wrong = LatinMoves.apply(.vowel, to: right, using: &generator), wrong != right, !out.contains(wrong) else { continue }
            out.append(wrong)
        }
        return out
    }

    private mutating func wrongLetterSounds(for item: ReadingItem) -> [String] {
        let letter = item.arabic
        var out: [String] = []
        for glyph in shuffled(ArabicMoves.lookAlikes(of: letter) + ArabicMoves.soundAlikes(of: letter)) {
            guard let sound = ReadingScheme.consonants[glyph], sound != item.reading, !out.contains(sound) else { continue }
            out.append(sound)
            if out.count == 2 { break }
        }
        for other in shuffled(ReadingTestBank.letters) where other.reading != item.reading && !out.contains(other.reading) {
            if out.count == 3 { break }
            out.append(other.reading)
        }
        return out
    }

    private mutating func wrongLetters(for item: ReadingItem) -> [String] {
        let letter = item.arabic
        var out: [String] = []
        for glyph in shuffled(ArabicMoves.lookAlikes(of: letter) + ArabicMoves.soundAlikes(of: letter))
        where glyph != letter && !out.contains(glyph) && ReadingScheme.consonants[glyph] != item.reading {
            out.append(glyph)
            if out.count == 2 { break }
        }
        for other in shuffled(ReadingTestBank.letters) where other.arabic != letter && !out.contains(other.arabic) {
            if out.count == 3 { break }
            out.append(other.arabic)
        }
        return out
    }

    /// Wrong answers drawn from the same list: the ones that start the same way first.
    private mutating func wrongFromPool(_ right: String, pool: [String]) -> [String] {
        let others = Array(Set(pool)).filter { $0 != right }
        let near = shuffled(others.filter { $0.prefix(2) == right.prefix(2) })
        let far = shuffled(others.filter { $0.prefix(2) != right.prefix(2) })
        return Array((near + far).prefix(3))
    }

    private mutating func wrongNames(for item: ReadingItem, arabic: Bool) -> [String] {
        let kind = ReadingTestBank.names.first { $0.item == item }?.kind
        let pool = ReadingTestBank.names.filter { $0.kind == kind }.map { arabic ? $0.item.arabic : $0.item.reading }
        return wrongFromPool(arabic ? item.arabic : item.reading, pool: pool)
    }

    // MARK: Wrong spellings

    private mutating func wrongSpellings(for item: ReadingItem, tier: ReadingTier) -> [String] {
        let unmarked = tier.display == .unmarked
        // An unmarked word is changed WITH its marks on, then stripped: only a change the bare
        // spelling shows (a long vowel, a letter) survives, which is the only fair wrong answer.
        let source = ReadingTestText.letters(item.marked ?? item.arabic)
        let focus = ArabicMoves.focus(for: tier.id)
        let fallback: [ArabicMoves.Move] = unmarked ? [.dropMadd, .addMadd, .lookAlike, .soundAlike]
            : [.haraka, .dropMadd, .addMadd, .shaddah, .lookAlike, .soundAlike]
        let right = item.arabic
        var out: [String] = []
        var guardrail = 0
        while out.count < 3, guardrail < 90 {
            guardrail += 1
            let moves = (out.count < 2 && guardrail < 40 ? focus : focus + fallback).filter { !unmarked || fallback.contains($0) }
            let pickFrom = moves.isEmpty ? fallback : moves
            let move = pickFrom[Int(next(upTo: pickFrom.count))]
            guard let changed = ArabicMoves.apply(move, to: source, using: &generator)?.joined() else { continue }
            let wrong = unmarked ? ReadingTestText.bare(changed) : changed
            guard wrong != right, !out.contains(wrong) else { continue }
            out.append(wrong)
        }
        return out
    }

    /// An ayah's wrong spellings change one word each.
    private mutating func wrongAyat(for item: ReadingItem) -> [String] {
        let words = item.arabic.split(separator: " ").map(String.init)
        var out: [String] = []
        var guardrail = 0
        let firstWord = Int(next(upTo: 8))
        while out.count < 3, guardrail < 90 {
            guardrail += 1
            // one word each while that works, then wherever a change can be made
            let index = guardrail < 40 ? (firstWord + out.count) % words.count : Int(next(upTo: words.count))
            let moves: [ArabicMoves.Move] = [.haraka, .dropMadd, .addMadd, .shaddah, .lookAlike]
            guard let changed = ArabicMoves.apply(moves[Int(next(upTo: moves.count))],
                                                  to: ReadingTestText.letters(words[index]), using: &generator)?.joined(),
                  changed != words[index] else { continue }
            var copy = words
            copy[index] = changed
            let wrong = copy.joined(separator: " ")
            if !out.contains(wrong) { out.append(wrong) }
        }
        return out
    }

    // MARK: Plumbing

    private mutating func arrange(right: String, wrong: [String], arabic: Bool) -> ([ReadingChoice], Int) {
        let order = shuffled([right] + wrong)
        let choices = order.enumerated().map { ReadingChoice(id: $0.offset, text: $0.element, isArabic: arabic) }
        return (choices, order.firstIndex(of: right) ?? 0)
    }

    private mutating func next(upTo bound: Int) -> UInt {
        bound <= 1 ? 0 : UInt.random(in: 0..<UInt(bound), using: &generator)
    }

    private mutating func shuffled<T>(_ values: [T]) -> [T] {
        values.shuffled(using: &generator)
    }
}

// MARK: - Wrong readings, one mistake at a time

/// Each move is one way a learner misreads a word. It works on the reading's sounds, never on its
/// letters, so a digraph is never cut in half.
enum LatinMoves {
    enum Move {
        /// One short vowel read as another.
        case vowel
        /// A long vowel read short, or a held one read as an ordinary long one.
        case shorten
        /// A short vowel stretched.
        case lengthen
        /// A long vowel moved to the next syllable: the right letters, the wrong place.
        case moveLong
        /// A shaddah missed.
        case undouble
        /// A shaddah that is not there.
        case double
        /// A letter read as its sound-alike (the heavy one as its light twin, 'ayn as a hamza).
        case consonant
        /// One tanween read as another.
        case tanween
        /// The tanween's n left off.
        case dropTanween
        /// A soft letter stretched: ay read ii, aw read uu.
        case leen
        /// A vowel given to a letter with a sukoon.
        case insertVowel
        /// The article read the other way: al- before a sun letter, or a moon letter doubled.
        case article
        /// A joining hamza started on the wrong vowel.
        case waslVowel
        /// A hamza passed over.
        case dropHamza
        /// The silent alif after the plural waaw read out.
        case silentAlif
        /// A bare noon skipped, or swallowed into the next letter.
        case bareNoon
    }

    /// The mistakes that belong to a tier. `arabic` lets the mushaf-marks tier tell which of its
    /// three subjects a word is about.
    static func focus(for tierID: String, arabic: String) -> [Move] {
        switch tierID {
        case "harakat", "spaced", "vowels": return [.vowel, .vowel, .consonant]
        case "tanween": return [.tanween, .tanween, .dropTanween]
        case "long": return [.shorten, .lengthen, .moveLong]
        case "small": return [.shorten, .shorten, .vowel]
        case "leen": return [.leen, .leen, .vowel]
        case "sukoon": return [.insertVowel, .insertVowel, .vowel]
        case "shaddah": return [.undouble, .double, .vowel]
        case "mixed": return [.shorten, .dropHamza, .consonant]
        case "article": return [.article, .article, .undouble]
        case "wasl": return [.waslVowel, .waslVowel, .insertVowel]
        case "silent":
            let scalars = arabic.unicodeScalars
            var moves: [Move] = [.shorten, .vowel]
            if scalars.contains(ReadingTestText.circle) { moves.insert(.silentAlif, at: 0) }
            if arabic.contains("ن") { moves.insert(.bareNoon, at: 0) }
            return moves
        case "ayat": return [.vowel, .shorten, .undouble, .lengthen]
        case "bare": return [.shorten, .lengthen, .moveLong, .consonant]
        default: return [.vowel, .shorten, .undouble]
        }
    }

    private static let soundAlikes: [String: [String]] = [
        "s": ["S", "th"], "S": ["s"], "t": ["T"], "T": ["t"], "d": ["D"], "D": ["d", "Dh"],
        "dh": ["Dh", "z"], "Dh": ["dh", "D"], "z": ["dh"], "th": ["s"], "h": ["H"], "H": ["h", "kh"],
        "kh": ["H", "gh"], "gh": ["kh"], "k": ["q"], "q": ["k"],
        ReadingScheme.ayn: [ReadingScheme.hamza], ReadingScheme.hamza: [ReadingScheme.ayn],
    ]

    /// `word` names the word of a phrase to change (any, when nil), so a question's wrong answers
    /// can be spread over the phrase and not pile up on one word.
    static func apply(_ move: Move, to reading: String, word: Int? = nil, using generator: inout RandomNumberGenerator) -> String? {
        // A phrase is changed one word at a time, so the spaces never move.
        if reading.contains(" ") {
            var words = reading.split(separator: " ").map(String.init)
            let index = word.map { $0 % words.count } ?? Int(UInt.random(in: 0..<UInt(words.count), using: &generator))
            guard let changed = apply(move, to: words[index], using: &generator) else { return nil }
            words[index] = changed
            return words.joined(separator: " ")
        }

        var tokens = ReadingScheme.tokens(reading)
        func pick(_ indices: [Int]) -> Int? {
            indices.isEmpty ? nil : indices[Int(UInt.random(in: 0..<UInt(indices.count), using: &generator))]
        }
        let isVowel: (Int) -> Bool = { tokens.indices.contains($0) && ReadingScheme.vowels.contains(tokens[$0]) }
        /// Runs of one vowel: (start, length).
        var runs: [(start: Int, length: Int)] = []
        var index = 0
        while index < tokens.count {
            if isVowel(index) {
                var end = index
                while end + 1 < tokens.count, tokens[end + 1] == tokens[index] { end += 1 }
                runs.append((index, end - index + 1))
                index = end + 1
            } else {
                index += 1
            }
        }

        switch move {
        case .vowel:
            guard let run = pick(runs.indices.filter { runs[$0].length == 1 }).map({ runs[$0] }) else { return nil }
            let others = ["a", "i", "u"].filter { $0 != tokens[run.start] }
            tokens[run.start] = others[Int(UInt.random(in: 0..<2, using: &generator))]

        case .shorten:
            guard let run = pick(runs.indices.filter { runs[$0].length >= 2 }).map({ runs[$0] }) else { return nil }
            tokens.removeSubrange(run.start..<(run.start + (run.length >= 4 ? 2 : 1)))

        case .lengthen:
            guard let run = pick(runs.indices.filter { runs[$0].length == 1 }).map({ runs[$0] }) else { return nil }
            tokens.insert(tokens[run.start], at: run.start)

        case .moveLong:
            guard let longIndex = pick(runs.indices.filter { runs[$0].length == 2 }),
                  let shortIndex = pick(runs.indices.filter { runs[$0].length == 1 }) else { return nil }
            let long = runs[longIndex], short = runs[shortIndex]
            // lengthen the short one first when it sits later, so the earlier index stays true
            if short.start > long.start {
                tokens.insert(tokens[short.start], at: short.start)
                tokens.remove(at: long.start)
            } else {
                tokens.remove(at: long.start)
                tokens.insert(tokens[short.start], at: short.start)
            }

        case .undouble:
            let doubles = tokens.indices.dropLast().filter { ReadingScheme.isConsonant(tokens[$0]) && tokens[$0] == tokens[$0 + 1] }
            guard let at = pick(Array(doubles)) else { return nil }
            tokens.remove(at: at)

        case .double:
            let singles = tokens.indices.filter { index in
                index > 0 && index + 1 < tokens.count && ReadingScheme.isConsonant(tokens[index])
                    && tokens[index] != ReadingScheme.hamza
                    && isVowel(index - 1) && isVowel(index + 1)
            }
            guard let at = pick(singles) else { return nil }
            tokens.insert(tokens[at], at: at)

        case .consonant:
            guard let at = pick(tokens.indices.filter { soundAlikes[tokens[$0]] != nil }),
                  let partners = soundAlikes[tokens[at]] else { return nil }
            let partner = partners[Int(UInt.random(in: 0..<UInt(partners.count), using: &generator))]
            let wasDoubled = at + 1 < tokens.count && tokens[at + 1] == tokens[at]
            if partner == ReadingScheme.hamza, at == 0 {
                tokens.remove(at: 0)                      // an opening hamza is not written
            } else {
                tokens[at] = partner
                if wasDoubled { tokens[at + 1] = partner }
            }

        case .tanween:
            guard tokens.count >= 2, tokens.last == "n", isVowel(tokens.count - 2) else { return nil }
            let others = ["a", "i", "u"].filter { $0 != tokens[tokens.count - 2] }
            tokens[tokens.count - 2] = others[Int(UInt.random(in: 0..<2, using: &generator))]

        case .dropTanween:
            guard tokens.count >= 2, tokens.last == "n", isVowel(tokens.count - 2) else { return nil }
            tokens.removeLast()

        case .leen:
            let glides = tokens.indices.dropLast().filter { index in
                tokens[index] == "a" && (tokens[index + 1] == "y" || tokens[index + 1] == "w")
                    && !isVowel(index + 2) && !(index > 0 && tokens[index - 1] == "a")
            }
            guard let at = pick(Array(glides)) else { return nil }
            let long = tokens[at + 1] == "y" ? "i" : "u"
            let stretched = UInt.random(in: 0..<2, using: &generator) == 0
            tokens.replaceSubrange(at...at + 1, with: stretched ? [long, long] : ["a", "a"])

        case .insertVowel:
            // after a consonant that closes a syllable: before another consonant, or at the end
            let closed = tokens.indices.filter { index in
                guard ReadingScheme.isConsonant(tokens[index]), index > 0, isVowel(index - 1) else { return false }
                if index + 1 == tokens.count { return true }
                return ReadingScheme.isConsonant(tokens[index + 1]) && tokens[index + 1] != tokens[index]
            }
            guard let at = pick(closed) else { return nil }
            tokens.insert(["a", "i", "u"][Int(UInt.random(in: 0..<3, using: &generator))], at: at + 1)

        case .article:
            guard let hyphen = tokens.firstIndex(of: "-"), hyphen > 0, hyphen + 1 < tokens.count else { return nil }
            let first = tokens[hyphen + 1]
            guard ReadingScheme.isConsonant(first) else { return nil }
            if tokens[hyphen - 1] == "l", first != "l" {
                tokens[hyphen - 1] = first                // a moon letter doubled like a sun letter
            } else if tokens[hyphen - 1] == first, first != "l" {
                tokens[hyphen - 1] = "l"                  // a sun letter's laam read out
            } else {
                return nil
            }

        case .waslVowel:
            guard let first = tokens.first, ReadingScheme.vowels.contains(first), !isVowel(1) else { return nil }
            let others = ["a", "i", "u"].filter { $0 != first }
            tokens[0] = others[Int(UInt.random(in: 0..<2, using: &generator))]

        case .dropHamza:
            // not between two of the same vowel: what is left would read as one long vowel
            let hamzas = tokens.indices.filter { index in
                tokens[index] == ReadingScheme.hamza
                    && !(index > 0 && index + 1 < tokens.count && tokens[index - 1] == tokens[index + 1])
            }
            guard let at = pick(hamzas) else { return nil }
            tokens.remove(at: at)

        case .silentAlif:
            guard tokens.count >= 2, tokens.suffix(2) == ["u", "u"] else { return nil }
            tokens.replaceSubrange((tokens.count - 1)..., with: ["w", "a", "a"])

        case .bareNoon:
            let hidden = tokens.indices.filter { index in
                tokens[index] == "n" && index > 0 && isVowel(index - 1) && index + 1 < tokens.count
                    && ReadingScheme.isConsonant(tokens[index + 1]) && tokens[index + 1] != "n"
            }
            guard let at = pick(hidden) else { return nil }
            if UInt.random(in: 0..<2, using: &generator) == 0 {
                tokens.remove(at: at)                     // skipped
            } else {
                tokens[at] = tokens[at + 1]               // swallowed into the next letter
            }
        }
        let out = ReadingScheme.join(tokens)
        return out.isEmpty ? nil : out
    }
}

// MARK: - Wrong spellings, one mistake at a time

/// The same idea on the Arabic side: one change to one letter, always a spelling that could exist.
enum ArabicMoves {
    enum Move {
        /// One short vowel for another.
        case haraka
        /// A madd letter (or a dagger alif) removed: the long vowel written short.
        case dropMadd
        /// A madd letter added after a short vowel.
        case addMadd
        /// A shaddah added or removed.
        case shaddah
        /// A letter for one that differs only by its dots.
        case lookAlike
        /// A letter for the one it is confused with by ear.
        case soundAlike
        /// One tanween for another.
        case tanween
        /// A sukoon replaced by a vowel.
        case sukoon
    }

    static func focus(for tierID: String) -> [Move] {
        switch tierID {
        case "harakat", "spaced", "vowels": return [.haraka, .haraka, .lookAlike]
        case "tanween": return [.tanween, .tanween, .haraka]
        case "long", "small": return [.dropMadd, .addMadd, .haraka]
        case "leen": return [.sukoon, .haraka, .addMadd]
        case "sukoon": return [.sukoon, .sukoon, .haraka]
        case "shaddah": return [.shaddah, .shaddah, .haraka]
        case "mixed": return [.dropMadd, .haraka, .soundAlike]
        case "article", "wasl", "silent": return [.shaddah, .haraka, .lookAlike]
        case "bare": return [.dropMadd, .addMadd, .lookAlike]
        default: return [.haraka, .lookAlike]
        }
    }

    private static let lookAlikeGroups: [[String]] = [
        ["ب", "ت", "ث", "ن", "ي"], ["ج", "ح", "خ"], ["د", "ذ"], ["ر", "ز"], ["س", "ش"],
        ["ص", "ض"], ["ط", "ظ"], ["ع", "غ"], ["ف", "ق"],
    ]

    static func lookAlikes(of letter: String) -> [String] {
        (lookAlikeGroups.first { $0.contains(letter) } ?? []).filter { $0 != letter }
    }

    /// The app's own sound-alike pairs (`LetterTraits.soundAlikes`), minus the hamza, whose seat a
    /// one-letter swap cannot get right.
    static func soundAlikes(of letter: String) -> [String] {
        LetterTraits.soundAlikes.filter { $0.contains(letter) }.map { $0.partner(of: letter) }.filter { $0 != "ء" }
    }

    private static func base(of letter: String) -> Unicode.Scalar? { letter.unicodeScalars.first }

    private static func marks(of letter: String) -> [Unicode.Scalar] { Array(letter.unicodeScalars.dropFirst()) }

    private static func isBareMadd(_ letter: String) -> Bool {
        let scalars = Array(letter.unicodeScalars)
        guard let first = scalars.first,
              [ReadingTestText.alif, ReadingTestText.waw, ReadingTestText.yaa, ReadingTestText.maqsura].contains(first) else { return false }
        return scalars.dropFirst().allSatisfy { $0 == ReadingTestText.maddah || $0 == ReadingTestText.dagger }
    }

    private static func isLetter(_ scalar: Unicode.Scalar) -> Bool {
        (0x0621...0x064A).contains(scalar.value) && scalar.value != 0x0640
    }

    static func haraka(_ letters: [String], using generator: inout RandomNumberGenerator) -> [String]? {
        apply(.haraka, to: letters, using: &generator)
    }

    static func lookAlike(_ letters: [String], using generator: inout RandomNumberGenerator) -> [String]? {
        apply(.lookAlike, to: letters, using: &generator)
    }

    static func apply(_ move: Move, to letters: [String], using generator: inout RandomNumberGenerator) -> [String]? {
        var letters = letters
        func pick(_ indices: [Int]) -> Int? {
            indices.isEmpty ? nil : indices[Int(UInt.random(in: 0..<UInt(indices.count), using: &generator))]
        }
        func rebuilt(_ base: Unicode.Scalar, _ marks: [Unicode.Scalar]) -> String {
            var view = String.UnicodeScalarView()
            view.append(base)
            view.append(contentsOf: marks)
            return String(view)
        }

        switch move {
        case .haraka:
            // not a vowel that a madd letter is stretching: a kasra before an alif spells nothing
            let candidates = letters.indices.filter { index in
                let marks = marks(of: letters[index])
                guard marks.contains(where: ReadingTestText.shortVowels.contains), !marks.contains(ReadingTestText.dagger) else { return false }
                return !(index + 1 < letters.count && isBareMadd(letters[index + 1]))
            }
            guard let at = pick(candidates), var base = base(of: letters[at]) else { return nil }
            var marks = marks(of: letters[at])
            guard let slot = marks.firstIndex(where: ReadingTestText.shortVowels.contains) else { return nil }
            let others = ReadingTestText.shortVowels.filter { $0 != marks[slot] }
            let replacement = others[Int(UInt.random(in: 0..<2, using: &generator))]
            marks[slot] = replacement
            // the hamza's seat follows its vowel: below the alif for a kasra, above it otherwise
            if base == ReadingTestText.hamzaOnAlif, replacement == ReadingTestText.kasra { base = ReadingTestText.hamzaUnderAlif }
            else if base == ReadingTestText.hamzaUnderAlif, replacement != ReadingTestText.kasra { base = ReadingTestText.hamzaOnAlif }
            letters[at] = rebuilt(base, marks)

        case .dropMadd:
            let madds = letters.indices.filter { $0 > 0 && isBareMadd(letters[$0]) && !(letters[$0 - 1].unicodeScalars.contains(ReadingTestText.fathatan)) }
            let daggers = letters.indices.filter { marks(of: letters[$0]).contains(ReadingTestText.dagger) && !isBareMadd(letters[$0]) }
            guard let at = pick(madds + daggers) else { return nil }
            if isBareMadd(letters[at]) {
                letters.remove(at: at)
            } else if let base = base(of: letters[at]) {
                letters[at] = rebuilt(base, marks(of: letters[at]).filter { $0 != ReadingTestText.dagger && $0 != ReadingTestText.maddah })
            }

        case .addMadd:
            let shorts = letters.indices.filter { index in
                let marks = marks(of: letters[index])
                guard marks.contains(where: ReadingTestText.shortVowels.contains), !marks.contains(ReadingTestText.dagger) else { return false }
                if index + 1 < letters.count, isBareMadd(letters[index + 1]) { return false }
                // a small waaw or yaa already stretches it
                return !letters[index].unicodeScalars.contains { $0 == ReadingTestText.smallWaw || $0 == ReadingTestText.smallYaa }
            }
            guard let at = pick(shorts), let vowel = marks(of: letters[at]).first(where: ReadingTestText.shortVowels.contains) else { return nil }
            let madd = vowel == ReadingTestText.fatha ? ReadingTestText.alif : vowel == ReadingTestText.kasra ? ReadingTestText.yaa : ReadingTestText.waw
            letters.insert(String(madd), at: at + 1)

        case .shaddah:
            let doubled = letters.indices.filter { marks(of: letters[$0]).contains(ReadingTestText.shaddah) }
            let single = letters.indices.filter { index in
                index > 0 && !marks(of: letters[index]).contains(ReadingTestText.shaddah)
                    && marks(of: letters[index]).contains(where: ReadingTestText.shortVowels.contains)
                    && base(of: letters[index]).map(isLetter) == true
                    && ![ReadingTestText.hamzaOnAlif, ReadingTestText.hamzaUnderAlif].contains(base(of: letters[index])!)
            }
            // taking a shaddah off is the commoner slip, so it goes first when there is one
            let removing = !doubled.isEmpty && (single.isEmpty || UInt.random(in: 0..<3, using: &generator) > 0)
            guard let at = pick(removing ? doubled : single), let base = base(of: letters[at]) else { return nil }
            var marks = marks(of: letters[at])
            if removing { marks.removeAll { $0 == ReadingTestText.shaddah } } else { marks.insert(ReadingTestText.shaddah, at: 0) }
            letters[at] = rebuilt(base, marks)

        case .lookAlike, .soundAlike:
            let candidates = letters.indices.filter { index in
                guard let base = base(of: letters[index]) else { return false }
                // a madd letter swapped for a consonant would change the word's whole shape
                if isBareMadd(letters[index]) { return false }
                let partners = move == .lookAlike ? lookAlikes(of: String(base)) : soundAlikes(of: String(base))
                return !partners.isEmpty
            }
            guard let at = pick(candidates), let base = base(of: letters[at]) else { return nil }
            let partners = move == .lookAlike ? lookAlikes(of: String(base)) : soundAlikes(of: String(base))
            guard let partner = partners[Int(UInt.random(in: 0..<UInt(partners.count), using: &generator))].unicodeScalars.first else { return nil }
            letters[at] = rebuilt(partner, marks(of: letters[at]))

        case .tanween:
            guard let at = letters.indices.last(where: { marks(of: letters[$0]).contains(where: ReadingTestText.tanweens.contains) }),
                  let base = base(of: letters[at]) else { return nil }
            var marks = marks(of: letters[at])
            guard let slot = marks.firstIndex(where: ReadingTestText.tanweens.contains) else { return nil }
            let wasFathatan = marks[slot] == ReadingTestText.fathatan
            // Only between the kasra and damma forms, or away from a double fatha: a double fatha
            // needs its alif seat, and which words take one is not a rule a swap can know.
            let options = wasFathatan ? [ReadingTestText.kasratan, ReadingTestText.dammatan]
                : [marks[slot] == ReadingTestText.kasratan ? ReadingTestText.dammatan : ReadingTestText.kasratan]
            marks[slot] = options[Int(UInt.random(in: 0..<UInt(options.count), using: &generator))]
            letters[at] = rebuilt(base, marks)
            if wasFathatan, at + 1 < letters.count, isBareMadd(letters[at + 1]) { letters.remove(at: at + 1) }

        case .sukoon:
            let stopped = letters.indices.filter { index in
                marks(of: letters[index]).contains { $0 == ReadingTestText.mushafSukoon || $0 == ReadingTestText.circle }
                    && base(of: letters[index]) != ReadingTestText.alif
                    && !(base(of: letters[index]) == ReadingTestText.waw && index + 1 < letters.count && letters[index + 1].unicodeScalars.first == ReadingTestText.alif)
            }
            guard let at = pick(stopped), let base = base(of: letters[at]) else { return nil }
            let vowel = ReadingTestText.shortVowels[Int(UInt.random(in: 0..<3, using: &generator))]
            letters[at] = rebuilt(base, marks(of: letters[at]).map { $0 == ReadingTestText.mushafSukoon || $0 == ReadingTestText.circle ? vowel : $0 })
        }
        return letters
    }
}

// MARK: - Progress

/// What the learner has done on each tier. Small, in UserDefaults, like `TajweedLessonProgress`.
final class ReadingTestProgress: ObservableObject {
    static let shared = ReadingTestProgress()

    struct Record: Codable, Equatable {
        /// Best score, as right answers out of a hundred.
        var best = 0
        var attempts = 0
        /// A pass with no hint used and nothing missed.
        var mastered = false
        var lastPlayed: Date? = nil

        var passed: Bool { best >= ReadingTestProgress.passMark }
    }

    /// Eight in ten.
    static let passMark = 80
    private static let key = "readingTestProgress"
    private static let placementKey = "readingTestPlacement"

    @Published private(set) var records: [String: Record]
    /// The tier Find My Level last sent the learner to, if they have taken it.
    @Published private(set) var placement: String?

    /// True once this object has something on disk, so the wipe check below never clears a ladder
    /// that was only ever in memory (the DEBUG seed).
    private var hasSaved = false
    private var defaultsObserver: NSObjectProtocol?

    private init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Self.key), let decoded = try? JSONDecoder().decode([String: Record].self, from: data) {
            records = decoded
            hasSaved = true
        } else {
            records = [:]
        }
        placement = defaults.string(forKey: Self.placementKey)
        if placement != nil { hasSaved = true }

        // "Erase Everything" removes the whole defaults domain while this object still holds the
        // ladder. Settings.swift compiles into targets this file is not in, so it cannot call in
        // here: notice the keys going instead.
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self, self.hasSaved,
                  UserDefaults.standard.data(forKey: Self.key) == nil,
                  UserDefaults.standard.string(forKey: Self.placementKey) == nil else { return }
            self.hasSaved = false
            if !self.records.isEmpty { self.records = [:] }
            if self.placement != nil { self.placement = nil }
        }
        // The observer above only notices the keys GOING (an erase). A restore writes them, which
        // it cannot tell from this object's own save, so that case is announced instead.
        storageObserver = StoredContentObserver(reload: { ReadingTestProgress.shared.reloadFromStorage() })
    }

    private var storageObserver: StoredContentObserver?

    /// The ladder on disk changed underneath this object (a restore): take it.
    private func reloadFromStorage() {
        let defaults = UserDefaults.standard
        let stored = defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode([String: Record].self, from: $0) }
        let storedPlacement = defaults.string(forKey: Self.placementKey)
        hasSaved = stored != nil || storedPlacement != nil
        if records != stored ?? [:] { records = stored ?? [:] }
        if placement != storedPlacement { placement = storedPlacement }
    }

    func record(for tier: ReadingTier) -> Record { records[tier.id] ?? Record() }

    var passedCount: Int { ReadingTier.all.filter { record(for: $0).passed }.count }

    /// Where to go next: the first tier not yet passed, from the placement tier on when there is one.
    var nextTier: ReadingTier? {
        let start = placement.flatMap { id in ReadingTier.all.firstIndex { $0.id == id } } ?? 0
        return ReadingTier.all[start...].first { !record(for: $0).passed } ?? ReadingTier.all.first { !record(for: $0).passed }
    }

    /// Files a finished round. `hints` and `missed` decide mastery; the best score only ever rises.
    func finish(_ tier: ReadingTier, right: Int, of total: Int, hints: Int) {
        guard total > 0 else { return }
        var record = record(for: tier)
        let score = Int((Double(right) / Double(total) * 100).rounded())
        record.best = max(record.best, score)
        record.attempts += 1
        record.lastPlayed = Date()
        if right == total, hints == 0 { record.mastered = true }
        records[tier.id] = record
        save()
    }

    func setPlacement(_ tier: ReadingTier) {
        placement = tier.id
        hasSaved = true
        UserDefaults.standard.set(tier.id, forKey: Self.placementKey)
    }

    func reset() {
        hasSaved = false
        records = [:]
        placement = nil
        UserDefaults.standard.removeObject(forKey: Self.key)
        UserDefaults.standard.removeObject(forKey: Self.placementKey)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            hasSaved = true
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    #if DEBUG
    /// "-readingTestSeed 12": marks the first twelve tiers passed, for a screenshot of a ladder in use.
    func debugSeed(passed count: Int) {
        for (index, tier) in ReadingTier.all.enumerated() where index < count {
            records[tier.id] = Record(best: index % 3 == 0 ? 100 : 90, attempts: 2, mastered: index % 3 == 0, lastPlayed: Date())
        }
    }
    #endif
}
