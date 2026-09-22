import SwiftUI

// The tajweed side of the alphabet, as data (Abu, 2026-09-20: "add all types of cool filtering stuff
// like whistling letters and hams", "yaa is an idgham bighunnah letter show that there", "merge that
// stuff in tajweed too").
//
// One table, three readers: the Arabic Alphabet's grouping menu, every letter's TAJWEED PROFILE, and
// the Tajweed Foundations pages. Each family is named in Arabic AND English, because the Arabic term
// is what a teacher will say and the English is what makes it stick.
//
// Every letter list here was checked against the course pack's own letter sets
// (TajweedLessons.json.xz: sifat-opposites, sifat-standalone, makharij-table, the noon sakinah
// lessons, lam-shamsiyyah-qamariyyah), and the complements (jahr, rakhawah, istifal, infitah, ismat)
// are COMPUTED from the listed side, so a family and its opposite can never overlap or leave a
// letter out. Every Quran example was cut from the Hafs source text by script, with its reference.

// MARK: - Model

/// One family of letters that share something a reciter can hear or feel: a place in the mouth
/// (makhraj), a quality of sound (sifah), or the tajweed rule they trigger.
struct LetterFamily: Identifiable, Hashable {
    let id: String
    /// The Arabic term, romanized: "Hams".
    let name: String
    /// The Arabic term itself: "الهَمس".
    let arabic: String
    /// What the term means in plain English: "Breath".
    let meaning: String
    /// One sentence: what the letters have in common.
    let summary: String
    /// How to hear it, feel it or test it.
    var detail: [String] = []
    let letters: [String]
    /// The phrase the tajweed books gather the letters in, where they have one.
    var mnemonic: String? = nil
    var mnemonicNote: String? = nil
    var systemImage: String = "circle.grid.2x2"
    /// The Tajweed course lesson that teaches this family in full (iOS only).
    var lessonID: String? = nil
    /// The reader's tajweed colour for this rule, where the mushaf paints one.
    var legend: TajweedLegendCategory? = nil
    /// Extra spellings and English words the alphabet's search should find this family by.
    var keywords: [String] = []

    static func == (lhs: LetterFamily, rhs: LetterFamily) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    func contains(_ letter: String) -> Bool { letters.contains(letter) }

    /// "Hams (Breath)": the way a family is named in running text and on chips.
    var title: String { "\(name) (\(meaning))" }
}

/// One question you can ask of every letter, and the families that answer it.
enum LetterAxis: String, CaseIterable, Identifiable {
    case makhraj
    case breath
    case flow
    case elevation
    case closure
    case fluency
    case special
    case weight
    case noonSakinah
    case meemSakinah
    case lamOfAl
    case madd
    case openers

    var id: String { rawValue }

    /// The three shelves the axes sit on, in the menu and in the Letter Families index.
    enum Shelf: String, CaseIterable, Identifiable {
        case place
        case qualities
        case rules

        var id: String { rawValue }

        var title: String {
            switch self {
            case .place: return "Where the Letter Is Made"
            case .qualities: return "How the Letter Sounds"
            case .rules: return "What the Letter Does to Its Neighbours"
            }
        }

        var arabic: String {
            switch self {
            case .place: return "المَخَارِج"
            case .qualities: return "الصِّفَات"
            case .rules: return "الأَحكَام"
            }
        }

        var transliteration: String {
            switch self {
            case .place: return "Makharij"
            case .qualities: return "Sifaat"
            case .rules: return "Ahkaam"
            }
        }

        var axes: [LetterAxis] { LetterAxis.allCases.filter { $0.shelf == self } }
    }

    var shelf: Shelf {
        switch self {
        case .makhraj: return .place
        case .breath, .flow, .elevation, .closure, .fluency, .special: return .qualities
        case .weight, .noonSakinah, .meemSakinah, .lamOfAl, .madd, .openers: return .rules
        }
    }

    /// The axis in English: what the menu and the index call it.
    var title: String {
        switch self {
        case .makhraj: return "Articulation Point"
        case .breath: return "Breath or Voice"
        case .flow: return "Stop or Flow"
        case .elevation: return "Raised or Lowered"
        case .closure: return "Clamped or Open"
        case .fluency: return "Fluent or Restrained"
        case .special: return "Special Qualities"
        case .weight: return "Heavy or Light"
        case .noonSakinah: return "After Noon Sakinah"
        case .meemSakinah: return "After Meem Sakinah"
        case .lamOfAl: return "Sun and Moon Letters"
        case .madd: return "Madd Letters"
        case .openers: return "Opening Letters"
        }
    }

    var arabic: String {
        switch self {
        case .makhraj: return "المَخرَج"
        case .breath: return "الهَمس وَالجَهر"
        case .flow: return "الشِّدَّة وَالرَّخَاوَة"
        case .elevation: return "الاِستِعلَاء وَالاِستِفَال"
        case .closure: return "الإِطبَاق وَالاِنفِتَاح"
        case .fluency: return "الإِذلَاق وَالإِصمَات"
        case .special: return "صِفَات لَا ضِدَّ لَهَا"
        case .weight: return "التَّفخِيم وَالتَّرقِيق"
        case .noonSakinah: return "النُّون السَّاكِنَة وَالتَّنوِين"
        case .meemSakinah: return "المِيم السَّاكِنَة"
        case .lamOfAl: return "اللَّام الشَّمسِيَّة وَالقَمَرِيَّة"
        case .madd: return "حُرُوف المَدّ"
        case .openers: return "الحُرُوف المُقَطَّعَة"
        }
    }

    var transliteration: String {
        switch self {
        case .makhraj: return "Makhraj"
        case .breath: return "Hams and Jahr"
        case .flow: return "Shiddah and Rakhawah"
        case .elevation: return "Isti'la and Istifal"
        case .closure: return "Itbaq and Infitah"
        case .fluency: return "Idhlaq and Ismat"
        case .special: return "Sifaat with no opposite"
        case .weight: return "Tafkheem and Tarqeeq"
        case .noonSakinah: return "Noon Sakinah and Tanween"
        case .meemSakinah: return "Meem Sakinah"
        case .lamOfAl: return "Laam Shamsiyyah and Qamariyyah"
        case .madd: return "Huroof al-Madd"
        case .openers: return "Al-Huroof al-Muqatta'ah"
        }
    }

    /// The question this axis asks of a letter.
    var question: String {
        switch self {
        case .makhraj: return "Where in the mouth or throat is the letter made?"
        case .breath: return "Does the breath keep flowing while the letter is said?"
        case .flow: return "Does the sound stop dead, or can you hold it?"
        case .elevation: return "Does the back of the tongue rise toward the roof of the mouth?"
        case .closure: return "Does the tongue clamp against the roof of the mouth?"
        case .fluency: return "Is the letter made at the quick tip of the tongue or the lips?"
        case .special: return "Does the letter carry a quality all of its own?"
        case .weight: return "Is the letter read full and heavy, or thin and light?"
        case .noonSakinah: return "What happens to a noon sakinah or tanween when this letter follows it?"
        case .meemSakinah: return "What happens to a meem sakinah when this letter follows it?"
        case .lamOfAl: return "Is the laam of ٱلۡ read before this letter, or merged into it?"
        case .madd: return "Can the letter be a long vowel?"
        case .openers: return "Is it one of the letters that open a surah on their own?"
        }
    }

    /// What the rest of the alphabet is called on this axis, for the letters no family claims.
    var restTitle: String {
        switch self {
        case .special: return "No Special Quality"
        case .madd: return "Consonants Only"
        case .openers: return "Never Open a Surah"
        case .lamOfAl: return "Never Follows the Laam"
        case .noonSakinah, .meemSakinah: return "Never Follows a Sukoon"
        default: return "The Other Letters"
        }
    }

    /// Why a letter can sit outside every family of this axis, shown under that last section.
    var restNote: String? {
        switch self {
        case .lamOfAl, .noonSakinah, .meemSakinah:
            return "Alif only ever follows a fatha, so it never comes after a sukoon or starts a word. The alif in the classic lists of these letters is really the hamza."
        default:
            return nil
        }
    }

    var systemImage: String {
        switch self {
        case .makhraj: return "mouth"
        case .breath: return "wind"
        case .flow: return "pause.circle"
        case .elevation: return "arrow.up.and.down"
        case .closure: return "rectangle.compress.vertical"
        case .fluency: return "hare"
        case .special: return "sparkles"
        case .weight: return "scalemass"
        case .noonSakinah: return "n.circle"
        case .meemSakinah: return "m.circle"
        case .lamOfAl: return "sun.max"
        case .madd: return "arrow.left.and.right"
        case .openers: return "book"
        }
    }

    /// Alternate spellings and English words the search should find this axis by.
    var keywords: [String] {
        switch self {
        case .makhraj: return ["makharij", "makhaarij", "articulation", "point", "exit", "place"]
        case .breath, .flow, .elevation, .closure, .fluency, .special:
            return ["sifaat", "sifat", "quality", "qualities", "characteristic", "characteristics", "attribute"]
        case .weight: return ["tafkhim", "tarqiq", "heavy", "light"]
        case .noonSakinah: return ["noon", "nun", "tanween", "tanwin"]
        case .meemSakinah: return ["meem", "mim", "shafawi"]
        case .lamOfAl: return ["sun", "moon", "solar", "lunar", "shams", "qamar", "al-"]
        case .madd: return ["madd", "long vowel", "elongation"]
        case .openers: return ["muqattaat", "muqatta'at", "disjointed", "openers"]
        }
    }

    var families: [LetterFamily] { LetterTraits.families(of: self) }
}

/// One of the seventeen articulation points, deepest first, as Ibn al-Jazari counts them.
struct LetterMakhraj: Identifiable, Hashable {
    let id: Int
    /// The `LetterAxis.makhraj` family (the zone) this exit belongs to.
    let zoneID: String
    let arabic: String
    let name: String
    /// Where it is, in plain English.
    let place: String
    let letters: [String]
    /// The classical nickname of the letters made here, e.g. the whistling trio's "Asaliyyah".
    var groupName: String? = nil
    var groupArabic: String? = nil
    /// Set for the two exits a letter only uses in one of its roles (waaw and yaa as consonants).
    var roleNote: String? = nil
}

/// A Quran example, cut verbatim from the Hafs text.
struct LetterRuleExample: Hashable {
    let text: String
    let surah: Int
    let ayah: Int

    var citation: String { "Quran \(surah):\(ayah)" }
}

/// Two letters a learner tends to swap, and the one thing that tells them apart.
struct SoundAlikePair: Identifiable, Hashable {
    let first: String
    let second: String
    let tip: String

    var id: String { first + second }
    func contains(_ letter: String) -> Bool { first == letter || second == letter }
    func partner(of letter: String) -> String { first == letter ? second : first }
}

// MARK: - The tables

enum LetterTraits {
    /// The 29 letters tajweed counts: the hamza and the alif separately, then the other 27.
    static let alphabet: [String] = [
        "ء", "ا", "ب", "ت", "ث", "ج", "ح", "خ", "د", "ذ", "ر", "ز", "س", "ش", "ص",
        "ض", "ط", "ظ", "ع", "غ", "ف", "ق", "ك", "ل", "م", "ن", "ه", "و", "ي",
    ]

    /// Everything in `alphabet` that none of `groups` lists, in alphabet order.
    private static func complement(of groups: [String]...) -> [String] {
        let taken = Set(groups.flatMap { $0 })
        return alphabet.filter { !taken.contains($0) }
    }

    // MARK: Sifaat with opposites

    private static let hamsLetters = ["ف", "ح", "ث", "ه", "ش", "خ", "ص", "س", "ك", "ت"]
    private static let shiddahLetters = ["ء", "ج", "د", "ق", "ط", "ب", "ك", "ت"]
    private static let tawassutLetters = ["ل", "ن", "ع", "م", "ر"]
    private static let istilaLetters = ["خ", "ص", "ض", "غ", "ط", "ق", "ظ"]
    private static let itbaqLetters = ["ص", "ض", "ط", "ظ"]
    private static let idhlaqLetters = ["ف", "ر", "م", "ن", "ل", "ب"]

    static let hams = LetterFamily(
        id: "hams", name: "Hams", arabic: "الهَمس", meaning: "Breath",
        summary: "The breath keeps flowing while the letter is said.",
        detail: [
            "The vocal cords stay still, so nothing holds the air back. Hold a hand in front of your mouth and say سۡ: you feel a steady stream of air.",
            "Two of the ten, kaaf and taa, also stop the sound dead (shiddah). The sound is cut first, and a small puff of breath follows it.",
        ],
        letters: hamsLetters,
        mnemonic: "فَحَثَّهُ شَخۡصٌ سَكَتۡ",
        mnemonicNote: "Every letter of the phrase is a hams letter.",
        systemImage: "wind", lessonID: "sifat-opposites",
        keywords: ["whisper", "whispered", "air", "breathy", "voiceless", "hams"]
    )

    static let jahr = LetterFamily(
        id: "jahr", name: "Jahr", arabic: "الجَهر", meaning: "Voice",
        summary: "The breath is held back while the letter is said.",
        detail: [
            "The vocal cords vibrate and the air is cut off. A hand in front of the mouth feels almost nothing on دۡ or بۡ.",
            "Every letter outside the ten hams letters is a jahr letter.",
        ],
        letters: complement(of: hamsLetters),
        mnemonic: "عَظُمَ وَزۡنُ قَارِئٍ ذِي غَضٍّ جَدَّ طَلَب",
        mnemonicNote: "Every letter of the phrase is a jahr letter, counting the alif and the hamza separately.",
        systemImage: "waveform", lessonID: "sifat-opposites",
        keywords: ["voiced", "loud", "apparent", "jahr"]
    )

    static let shiddah = LetterFamily(
        id: "shiddah", name: "Shiddah", arabic: "الشِّدَّة", meaning: "Strength",
        summary: "The sound stops dead at the articulation point.",
        detail: [
            "Say the letter with a sukoon and try to hold it. You cannot: the exit is shut completely and the sound is locked in.",
            "Five of the eight are voiced as well (ق ط ب ج د), so with a sukoon neither sound nor breath would escape. That is why those five bounce: qalqalah.",
        ],
        letters: shiddahLetters,
        mnemonic: "أَجِدۡ قَطٍ بَكَتۡ",
        mnemonicNote: "Every letter of the phrase is a shiddah letter.",
        systemImage: "stop.circle", lessonID: "sifat-opposites",
        keywords: ["strong", "stop", "plosive", "shidda"]
    )

    static let tawassut = LetterFamily(
        id: "tawassut", name: "Tawassut", arabic: "التَّوَسُّط", meaning: "In Between",
        summary: "The sound neither stops dead nor flows freely.",
        detail: [
            "These five can be held for a moment, but not for as long as your breath lasts: the exit is only partly closed. The books also call this rank bayniyyah, between the two.",
        ],
        letters: tawassutLetters,
        mnemonic: "لِنۡ عُمَرَ",
        mnemonicNote: "Every letter of the phrase is a tawassut letter.",
        systemImage: "minus.circle", lessonID: "sifat-opposites",
        keywords: ["between", "moderate", "bayniyyah", "bainiyah"]
    )

    static let rakhawah = LetterFamily(
        id: "rakhawah", name: "Rakhawah", arabic: "الرَّخَاوَة", meaning: "Softness",
        summary: "The sound keeps running for as long as you have breath.",
        detail: [
            "Say سۡ or شۡ and hold it as long as you like: the exit stays slightly open and the sound runs through the gap.",
            "Every letter that is neither shiddah nor tawassut is a rakhawah letter.",
        ],
        letters: complement(of: shiddahLetters, tawassutLetters),
        systemImage: "play.circle", lessonID: "sifat-opposites",
        keywords: ["soft", "flow", "flowing", "continuous", "rikhwah", "rakhawa"]
    )

    static let istila = LetterFamily(
        id: "istila", name: "Isti'la", arabic: "الاِستِعلَاء", meaning: "Elevation",
        summary: "The back of the tongue rises toward the roof of the mouth.",
        detail: [
            "That lift fills the mouth with sound and makes the letter heavy (tafkheem). These seven are heavy whatever vowel they carry, even a kasra.",
        ],
        letters: istilaLetters,
        mnemonic: "خُصَّ ضَغۡطٍ قِظۡ",
        mnemonicNote: "Every letter of the phrase is an isti'la letter.",
        systemImage: "arrow.up.to.line", lessonID: "sifat-opposites",
        keywords: ["elevated", "raised", "istila", "isti'laa", "heavy"]
    )

    static let istifal = LetterFamily(
        id: "istifal", name: "Istifal", arabic: "الاِستِفَال", meaning: "Lowering",
        summary: "The tongue lies low, so the letter stays light.",
        detail: [
            "Every letter outside the seven isti'la letters is read light (tarqeeq). Three of them can still turn heavy: raa, the laam of Allah's Name, and alif, which copies the letter before it.",
        ],
        letters: complement(of: istilaLetters),
        systemImage: "arrow.down.to.line", lessonID: "sifat-opposites",
        keywords: ["lowered", "low", "istifaal", "light"]
    )

    static let itbaq = LetterFamily(
        id: "itbaq", name: "Itbaq", arabic: "الإِطبَاق", meaning: "Clamping",
        summary: "The tongue presses up against the roof of the mouth and traps the sound.",
        detail: [
            // The left-to-right marks keep each pair in its own run: without them the comma joins "س, ط"
            // into one right-to-left run and the sentence DISPLAYS as "ص into ط ,س into ت".
            "These four are the heaviest letters in the language. Take the clamp away and each collapses into its light twin: ص into س,\u{200E} ط into ت,\u{200E} ظ into ذ,\u{200E} ض into د.",
        ],
        letters: itbaqLetters,
        systemImage: "rectangle.compress.vertical", lessonID: "sifat-opposites",
        keywords: ["adhesion", "covered", "closed", "itbaaq", "emphatic"]
    )

    static let infitah = LetterFamily(
        id: "infitah", name: "Infitah", arabic: "الاِنفِتَاح", meaning: "Opening",
        summary: "The tongue stays apart from the roof of the mouth, so the sound has an open path.",
        detail: [
            "Every letter outside the four itbaq letters. Three of them are still heavy (خ غ ق): their tongue rises without clamping.",
        ],
        letters: complement(of: itbaqLetters),
        systemImage: "rectangle.expand.vertical", lessonID: "sifat-opposites",
        keywords: ["open", "separation", "infitaah"]
    )

    static let idhlaq = LetterFamily(
        id: "idhlaq", name: "Idhlaq", arabic: "الإِذلَاق", meaning: "Fluency",
        summary: "Made at the tip of the tongue or the lips, so the letter leaves the mouth quickly.",
        detail: [
            "This pair describes the letters themselves, not something the reciter performs. Arabic grammarians noticed that a native root of four or five letters nearly always contains one of these six.",
        ],
        letters: idhlaqLetters,
        mnemonic: "فَرَّ مِنۡ لُبٍّ",
        mnemonicNote: "Every letter of the phrase is an idhlaq letter.",
        systemImage: "hare", lessonID: "sifat-opposites",
        keywords: ["fluent", "quick", "easy", "idhlaaq"]
    )

    static let ismat = LetterFamily(
        id: "ismat", name: "Ismat", arabic: "الإِصمَات", meaning: "Restraint",
        summary: "Every other letter: a little heavier on the tongue than the fluent six.",
        detail: [
            "Every letter outside the six idhlaq letters.",
        ],
        letters: complement(of: idhlaqLetters),
        systemImage: "tortoise", lessonID: "sifat-opposites",
        keywords: ["restrained", "ismaat", "silent"]
    )

    // MARK: Sifaat with no opposite

    static let safeer = LetterFamily(
        id: "safeer", name: "Safeer", arabic: "الصَّفِير", meaning: "Whistling",
        summary: "A sharp whistle as the air squeezes between the tongue tip and the front teeth.",
        detail: [
            "Seen is the plain whistle, zaay is the same whistle with the voice switched on, and Saad is the whistle made heavy.",
            "The whistle is the test: if there is none at all, the tongue is sitting too far back.",
        ],
        letters: ["ص", "س", "ز"],
        systemImage: "music.note", lessonID: "sifat-standalone",
        keywords: ["whistle", "whistling", "safir", "sibilant", "hiss"]
    )

    static let qalqalah = LetterFamily(
        id: "qalqalah", name: "Qalqalah", arabic: "القَلقَلَة", meaning: "Bounce",
        summary: "A short bounce when the letter carries a sukoon or is stopped on.",
        detail: [
            "These five stop the sound AND the breath, so a sakin one would be inaudible without help. The bounce is a release of the letter, never an added vowel: if it sounds like an \u{201C}a\u{201D}, it is wrong.",
            "The bounce is strongest when you stop on the letter, as on the daal of أَحَدٌ.",
        ],
        letters: ["ق", "ط", "ب", "ج", "د"],
        mnemonic: "قُطۡبُ جَدٍّ",
        mnemonicNote: "Every letter of the phrase is a qalqalah letter.",
        systemImage: "arrow.up.arrow.down", lessonID: "qalqalah", legend: .qalqalah,
        keywords: ["bounce", "echo", "bouncing", "qalqala"]
    )

    static let leen = LetterFamily(
        id: "leen", name: "Leen", arabic: "اللِّين", meaning: "Ease",
        summary: "Waaw and yaa with a sukoon after a fatha: they glide out with no effort.",
        detail: [
            "As in خَوۡف and بَيۡت. Reading on, a leen letter is not stretched at all. Stopping on the word lets it lengthen (madd leen): 2, 4 or 6 counts.",
        ],
        letters: ["و", "ي"],
        systemImage: "wave.3.right", lessonID: "madd-leen",
        keywords: ["soft", "glide", "diphthong", "lin", "leen"]
    )

    static let inhiraf = LetterFamily(
        id: "inhiraf", name: "Inhiraf", arabic: "الاِنحِرَاف", meaning: "Deviation",
        summary: "The sound starts at the tongue tip and escapes another way.",
        detail: [
            "In laam it slips off the sides of the tongue. In raa it bends back over the tip.",
        ],
        letters: ["ل", "ر"],
        systemImage: "arrow.triangle.branch", lessonID: "sifat-standalone",
        keywords: ["deviation", "drift", "inhiraaf"]
    )

    static let takreer = LetterFamily(
        id: "takreer", name: "Takreer", arabic: "التَّكرِير", meaning: "Repetition",
        summary: "The tongue tip is ready to trill, and the reciter holds it to one light tap.",
        detail: [
            "This is the one quality you learn in order to restrain. A rolled r is a mistake: even a doubled raa (رّ) is one tap held longer, never a drum roll.",
        ],
        letters: ["ر"],
        systemImage: "repeat", lessonID: "sifat-standalone",
        keywords: ["trill", "roll", "rolled", "takrir", "repeat"]
    )

    static let tafashshi = LetterFamily(
        id: "tafashshi", name: "Tafashshi", arabic: "التَّفَشِّي", meaning: "Spreading",
        summary: "The air spreads out through the whole mouth as the letter is said.",
        detail: [
            "Sheen shares the middle of the tongue with jeem and yaa. The spread is what sets it apart: jeem shuts the exit, yaa only approaches it, and sheen lets the air fan out.",
        ],
        letters: ["ش"],
        systemImage: "dot.radiowaves.left.and.right", lessonID: "sifat-standalone",
        keywords: ["spread", "spreading", "diffusion", "tafashi"]
    )

    static let istitalah = LetterFamily(
        id: "istitalah", name: "Istitalah", arabic: "الاِستِطَالَة", meaning: "Extension",
        summary: "The sound travels along the side of the tongue, from the back molars forward.",
        detail: [
            "The extension is in distance, not in time: Daad is not held longer than any other letter. It is counted the hardest letter to pronounce, and Arabic is called the language of the Daad after it.",
        ],
        letters: ["ض"],
        systemImage: "arrow.right.to.line", lessonID: "sifat-standalone",
        keywords: ["extension", "elongation", "istitaalah"]
    )

    static let ghunnah = LetterFamily(
        id: "ghunnah", name: "Ghunnah", arabic: "الغُنَّة", meaning: "Nasal Sound",
        summary: "A hum from the nose that belongs to noon and meem in every state.",
        detail: [
            "Pinch your nose while saying نّ or مّ and the sound chokes off: the hum leaves through the nasal passage (الخَيشُوم), the seventeenth articulation point.",
            "It is held two full counts when the letter carries a shaddah, and in idgham with ghunnah, iqlaab and ikhfaa. Ibn al-Jazari lists seven qualities with no opposite; many books add the ghunnah to them.",
        ],
        letters: ["ن", "م"],
        systemImage: "nose", lessonID: "ghunnah", legend: .generalGhunnah,
        keywords: ["nasal", "nose", "hum", "ghunna", "khayshum", "khaishum"]
    )

    // MARK: Makhraj zones

    static let jawf = LetterFamily(
        id: "jawf", name: "Al-Jawf", arabic: "الجَوف", meaning: "The Empty Space",
        summary: "The open space of the mouth and throat: nothing touches, the sound just carries.",
        detail: [
            "Only the three madd letters come from here: alif after a fatha, waaw with a sukoon after a damma, and yaa with a sukoon after a kasra. As consonants, waaw and yaa have exits of their own at the lips and the middle of the tongue.",
        ],
        letters: ["ا", "و", "ي"],
        mnemonic: "نُوحِيهَآ",
        mnemonicNote: "One Quranic word with all three long vowels in it (Quran 11:49).",
        systemImage: "circle.dashed", lessonID: "jawf-letters",
        keywords: ["jawf", "hollow", "empty", "cavity", "madd"]
    )

    static let halq = LetterFamily(
        id: "halq", name: "Al-Halq", arabic: "الحَلق", meaning: "The Throat",
        summary: "Three depths of the throat, two letters at each.",
        detail: [
            "Deepest, nearest the chest (أَقصَى الحَلق): ء and ه. Middle (وَسَط الحَلق): ع and ح. Top, nearest the mouth (أَدنَى الحَلق): غ and خ.",
            "In each pair the second letter is the breathy one. These six are also the idhaar letters: a noon sakinah before them is always read clearly.",
        ],
        letters: ["ء", "ه", "ع", "ح", "غ", "خ"],
        systemImage: "arrow.down.circle", lessonID: "throat-letters",
        keywords: ["throat", "halqi", "halqiyyah", "guttural"]
    )

    static let aqsaLisan = LetterFamily(
        id: "aqsaLisan", name: "Aqsa al-Lisan", arabic: "أَقصَى اللِّسَان", meaning: "Back of the Tongue",
        summary: "The very back of the tongue rises to meet the roof of the mouth.",
        detail: [
            "Qaaf meets the soft palate, as far back as the tongue reaches. Kaaf is the same movement one small step forward, where the hard palate begins. The pair are called the lahawiyyah letters (اللَّهَوِيَّة), after the uvula beside them.",
        ],
        letters: ["ق", "ك"],
        systemImage: "arrow.turn.up.left", lessonID: "tongue-regions",
        keywords: ["back", "uvular", "lahawiyyah", "tongue"]
    )

    static let wasatLisan = LetterFamily(
        id: "wasatLisan", name: "Wasat al-Lisan", arabic: "وَسَط اللِّسَان", meaning: "Middle of the Tongue",
        summary: "The middle of the tongue against the hard palate above it.",
        detail: [
            "Jeem closes completely, sheen lets the air spread, and yaa only approaches. The yaa meant here is the consonant yaa and the leen yaa: the madd yaa comes from the jawf. The three are called the shajriyyah letters (الشَّجرِيَّة).",
        ],
        letters: ["ج", "ش", "ي"],
        systemImage: "arrow.up.circle", lessonID: "tongue-regions",
        keywords: ["middle", "palatal", "shajriyyah", "tongue"]
    )

    static let haffatLisan = LetterFamily(
        id: "haffatLisan", name: "Haffat al-Lisan", arabic: "حَافَّة اللِّسَان", meaning: "Side of the Tongue",
        summary: "One side of the tongue, or both, pressed against the upper molars.",
        detail: [
            "Only Daad is made here, and no other language has it. The left side is the easier and the more common. Laam uses the front of the same edge, further forward, and is counted with the tongue tip.",
        ],
        letters: ["ض"],
        systemImage: "arrow.left.arrow.right.circle", lessonID: "tongue-regions",
        keywords: ["side", "edge", "molars", "tongue"]
    )

    static let tarafLisan = LetterFamily(
        id: "tarafLisan", name: "Taraf al-Lisan", arabic: "طَرَف اللِّسَان", meaning: "Tip of the Tongue",
        summary: "Twelve letters, a few millimetres apart, at the tip of the tongue.",
        detail: [
            "Against the gum of the upper front teeth: laam, then noon just below it, then raa slightly further in (the dhalqiyyah letters, الذَّلقِيَّة).",
            "At the roots of the upper front teeth: ط د ت (the nit'iyyah letters, النِّطعِيَّة). Just above the lower front teeth, whistling: ص س ز (the asaliyyah letters, الأَسَلِيَّة). Touching the edges of the upper front teeth: ظ ذ ث (the lithawiyyah letters, اللِّثَوِيَّة).",
        ],
        letters: ["ل", "ن", "ر", "ط", "د", "ت", "ص", "س", "ز", "ظ", "ذ", "ث"],
        systemImage: "arrow.up.forward.circle", lessonID: "tongue-regions",
        keywords: ["tip", "tongue", "teeth", "dental"]
    )

    static let shafatan = LetterFamily(
        id: "shafatan", name: "Ash-Shafatan", arabic: "الشَّفَتَان", meaning: "The Lips",
        summary: "The only articulation points you can watch in a mirror.",
        detail: [
            "Faa: the inside of the lower lip against the edges of the upper front teeth. Baa and meem: both lips pressed together, baa firmly, meem lightly with the sound leaving through the nose. Waaw: both lips rounded and pushed forward, never closing.",
            "The waaw meant here is the consonant waaw and the leen waaw: the madd waaw comes from the jawf. The four are called the shafawiyyah letters (الشَّفَوِيَّة).",
        ],
        letters: ["ف", "ب", "م", "و"],
        systemImage: "mouth", lessonID: "lips-nasal-passage",
        keywords: ["lips", "lip", "labial", "shafawi", "shafawiyyah"]
    )

    /// The seventeen exits, deepest first. The order is the course's `makharij-table`.
    static let makharij: [LetterMakhraj] = [
        LetterMakhraj(id: 1, zoneID: "jawf", arabic: "الجَوف", name: "Al-Jawf",
                      place: "The empty space of the mouth and throat, with no contact anywhere",
                      letters: ["ا", "و", "ي"], groupName: "Jawfiyyah", groupArabic: "الجَوفِيَّة",
                      roleNote: "as a madd letter"),
        LetterMakhraj(id: 2, zoneID: "halq", arabic: "أَقصَى الحَلق", name: "Aqsa al-Halq",
                      place: "The deepest part of the throat, nearest the chest",
                      letters: ["ء", "ه"], groupName: "Halqiyyah", groupArabic: "الحَلقِيَّة"),
        LetterMakhraj(id: 3, zoneID: "halq", arabic: "وَسَط الحَلق", name: "Wasat al-Halq",
                      place: "The middle of the throat",
                      letters: ["ع", "ح"], groupName: "Halqiyyah", groupArabic: "الحَلقِيَّة"),
        LetterMakhraj(id: 4, zoneID: "halq", arabic: "أَدنَى الحَلق", name: "Adna al-Halq",
                      place: "The top of the throat, nearest the mouth",
                      letters: ["غ", "خ"], groupName: "Halqiyyah", groupArabic: "الحَلقِيَّة"),
        LetterMakhraj(id: 5, zoneID: "aqsaLisan", arabic: "أَقصَى اللِّسَان", name: "Aqsa al-Lisan",
                      place: "The very back of the tongue against the soft palate",
                      letters: ["ق"], groupName: "Lahawiyyah", groupArabic: "اللَّهَوِيَّة"),
        LetterMakhraj(id: 6, zoneID: "aqsaLisan", arabic: "أَقصَى اللِّسَان", name: "Aqsa al-Lisan",
                      place: "The back of the tongue, one step forward, where the hard palate begins",
                      letters: ["ك"], groupName: "Lahawiyyah", groupArabic: "اللَّهَوِيَّة"),
        LetterMakhraj(id: 7, zoneID: "wasatLisan", arabic: "وَسَط اللِّسَان", name: "Wasat al-Lisan",
                      place: "The middle of the tongue against the hard palate",
                      letters: ["ج", "ش", "ي"], groupName: "Shajriyyah", groupArabic: "الشَّجرِيَّة",
                      roleNote: "as a consonant or a leen letter"),
        LetterMakhraj(id: 8, zoneID: "haffatLisan", arabic: "حَافَّة اللِّسَان", name: "Haffat al-Lisan",
                      place: "The side of the tongue, or both sides, against the upper molars",
                      letters: ["ض"]),
        LetterMakhraj(id: 9, zoneID: "tarafLisan", arabic: "أَدنَى حَافَّة اللِّسَان", name: "Adna Haffat al-Lisan",
                      place: "The front edge of the tongue, up to the tip, against the gum of the upper front teeth",
                      letters: ["ل"], groupName: "Dhalqiyyah", groupArabic: "الذَّلقِيَّة"),
        LetterMakhraj(id: 10, zoneID: "tarafLisan", arabic: "طَرَف اللِّسَان", name: "Taraf al-Lisan",
                      place: "The tip of the tongue against the gum of the upper front teeth, just below laam's place",
                      letters: ["ن"], groupName: "Dhalqiyyah", groupArabic: "الذَّلقِيَّة"),
        LetterMakhraj(id: 11, zoneID: "tarafLisan", arabic: "طَرَف اللِّسَان", name: "Taraf al-Lisan",
                      place: "The tip of the tongue at the same gum, slightly further in than noon",
                      letters: ["ر"], groupName: "Dhalqiyyah", groupArabic: "الذَّلقِيَّة"),
        LetterMakhraj(id: 12, zoneID: "tarafLisan", arabic: "طَرَف اللِّسَان", name: "Taraf al-Lisan",
                      place: "The tip of the tongue at the roots of the two upper front teeth",
                      letters: ["ط", "د", "ت"], groupName: "Nit'iyyah", groupArabic: "النِّطعِيَّة"),
        LetterMakhraj(id: 13, zoneID: "tarafLisan", arabic: "طَرَف اللِّسَان", name: "Taraf al-Lisan",
                      place: "The tip of the tongue just above the lower front teeth, the air whistling past the upper ones",
                      letters: ["ص", "س", "ز"], groupName: "Asaliyyah", groupArabic: "الأَسَلِيَّة"),
        LetterMakhraj(id: 14, zoneID: "tarafLisan", arabic: "طَرَف اللِّسَان", name: "Taraf al-Lisan",
                      place: "The tip of the tongue touching the edges of the two upper front teeth",
                      letters: ["ظ", "ذ", "ث"], groupName: "Lithawiyyah", groupArabic: "اللِّثَوِيَّة"),
        LetterMakhraj(id: 15, zoneID: "shafatan", arabic: "بَطن الشَّفَة السُّفلَى", name: "Batn ash-Shafah as-Sufla",
                      place: "The inside of the lower lip against the edges of the upper front teeth",
                      letters: ["ف"], groupName: "Shafawiyyah", groupArabic: "الشَّفَوِيَّة"),
        LetterMakhraj(id: 16, zoneID: "shafatan", arabic: "الشَّفَتَان", name: "Ash-Shafatan",
                      place: "The two lips: pressed shut for baa and meem, rounded and open for waaw",
                      letters: ["ب", "م", "و"], groupName: "Shafawiyyah", groupArabic: "الشَّفَوِيَّة",
                      roleNote: "as a consonant or a leen letter"),
        LetterMakhraj(id: 17, zoneID: "khayshum", arabic: "الخَيشُوم", name: "Al-Khayshum",
                      place: "The nasal passage. No letter is made here: it carries the ghunnah of noon and meem",
                      letters: []),
    ]

    // MARK: Heavy and light

    /// Built from `LetterData.weight`, the alphabet's own record, so the two can never disagree.
    private static func weightLetters(_ weight: LetterWeight) -> [String] {
        standardArabicLetters.filter { $0.weight == weight }.map(\.letter)
    }

    static let heavy = LetterFamily(
        id: "heavy", name: "Tafkheem", arabic: "التَّفخِيم", meaning: "Always Heavy",
        summary: "Read full and heavy in every position, whatever vowel they carry.",
        detail: [
            "These are the seven isti'la letters. The heaviest of them are the four that also clamp the tongue (ص ض ط ظ).",
            "How heavy depends on the vowel: fullest with a fatha followed by an alif, then a fatha, a damma, a sukoon, and lightest (but still heavy) with a kasra.",
        ],
        letters: weightLetters(.heavy),
        mnemonic: "خُصَّ ضَغۡطٍ قِظۡ",
        mnemonicNote: "Every letter of the phrase is a heavy letter.",
        systemImage: "scalemass.fill", lessonID: "heavy-light-letters", legend: .tafkhim,
        keywords: ["heavy", "tafkhim", "tafkheem", "mufakhkham", "thick", "full"]
    )

    static let light = LetterFamily(
        id: "light", name: "Tarqeeq", arabic: "التَّرقِيق", meaning: "Always Light",
        summary: "Read thin and light in every position.",
        detail: [
            "The tongue stays relaxed and low. The common mistake is to let a heavy neighbour thicken them, as with the seen of مُسۡتَقِيم beside its qaaf.",
        ],
        letters: ["ء"] + weightLetters(.light),
        systemImage: "scalemass", lessonID: "heavy-light-letters",
        keywords: ["light", "tarqiq", "tarqeeq", "muraqqaq", "thin"]
    )

    static let conditionalWeight = LetterFamily(
        id: "conditionalWeight", name: "Heavy or Light", arabic: "يُفَخَّم وَيُرَقَّق", meaning: "Depends on Context",
        summary: "Raa and laam change weight with the vowels around them.",
        detail: [
            "Raa is heavy with a fatha or damma and light with a kasra. With a sukoon it follows the vowel before it.",
            "Laam is light everywhere except in the Name of Allah, where it is heavy after a fatha or damma and light after a kasra.",
        ],
        letters: weightLetters(.conditional),
        systemImage: "circle.lefthalf.filled", lessonID: "ra-tafkheem-tarqeeq",
        keywords: ["conditional", "depends"]
    )

    static let followsPrevious = LetterFamily(
        id: "followsPrevious", name: "Follows the Letter Before", arabic: "تَابِع لِمَا قَبلَه", meaning: "No Weight of Its Own",
        summary: "Alif is heavy after a heavy letter and light after a light one.",
        detail: [
            "Alif has no weight to give: قَالَ is heavy because of its qaaf, كَانَ is light because of its kaaf. Alif follows, it never leads.",
        ],
        letters: weightLetters(.followsPrevious),
        systemImage: "arrow.uturn.backward.circle", lessonID: "heavy-light-letters",
        keywords: ["follows", "previous"]
    )

    // MARK: Noon sakinah and tanween

    static let idhaar = LetterFamily(
        id: "idhaar", name: "Idhaar Halqi", arabic: "الإِظهَار الحَلقِيّ", meaning: "Clear",
        summary: "The noon is pronounced clearly, with no extra nasal hold.",
        detail: [
            "These six come from the throat, far from the noon's place at the tongue tip, so the two sounds never blend. The mushaf writes the sukoon on the noon to tell you so.",
        ],
        letters: ["ء", "ه", "ع", "ح", "غ", "خ"],
        mnemonic: "أَخِي هَاكَ عِلۡمًا حَازَهُ غَيۡرُ خَاسِرٍ",
        mnemonicNote: "The first letter of each word is an idhaar letter.",
        systemImage: "speaker.wave.2", lessonID: "idhhar",
        keywords: ["idhar", "izhar", "idhhar", "clear", "throat"]
    )

    static let idghamGhunnah = LetterFamily(
        id: "idghamGhunnah", name: "Idgham Bighunnah", arabic: "الإِدغَام بِغُنَّة", meaning: "Merge with Ghunnah",
        summary: "The noon merges into the next letter and the nasal hum is held two counts.",
        detail: [
            "Only across two words. Inside one word the noon stays clear, which happens in four words of the Quran: ٱلدُّنۡيَا (dunyaa), بُنۡيَٰنٞ (bunyaan), قِنۡوَانٞ (qinwaan) and صِنۡوَانٞ (sinwaan).",
            "The mushaf leaves the noon bare, with no sukoon, as a sign that it is not read on its own.",
        ],
        letters: ["ي", "ن", "م", "و"],
        mnemonic: "يَنۡمُو",
        mnemonicNote: "One word holds all four. With laam and raa they make the six idgham letters: يَرۡمُلُونَ.",
        systemImage: "arrow.triangle.merge", lessonID: "idgham-with-ghunnah", legend: .idghamGhunnah,
        keywords: ["idgham", "idghaam", "merge", "merging", "ghunnah", "bighunnah", "yanmu", "yarmaloon"]
    )

    static let idghamBilaGhunnah = LetterFamily(
        id: "idghamBilaGhunnah", name: "Idgham Bilaa Ghunnah", arabic: "الإِدغَام بِغَيرِ غُنَّة", meaning: "Merge Without Ghunnah",
        summary: "The noon merges completely into the next letter, with no nasal sound at all.",
        detail: [
            "The noon vanishes and the laam or raa is doubled: مِن رَّبِّهِمۡ is read \u{201C}mir-rabbihim\u{201D}. The mushaf shows it with a shaddah on the next letter.",
        ],
        letters: ["ل", "ر"],
        systemImage: "arrow.merge", lessonID: "idgham-without-ghunnah", legend: .idghamBilaGhunnah,
        keywords: ["idgham", "idghaam", "merge", "without ghunnah", "bila ghunnah"]
    )

    static let iqlaab = LetterFamily(
        id: "iqlaab", name: "Iqlaab", arabic: "الإِقلَاب", meaning: "Noon into Meem",
        summary: "Before a baa, the noon turns into a hidden meem with a two-count hum.",
        detail: [
            "The mushaf marks it with a small meem (ۢ) over the noon or in place of the second tanween stroke. The lips come together lightly for the meem, then open on the baa.",
        ],
        letters: ["ب"],
        systemImage: "arrow.2.squarepath", lessonID: "iqlab", legend: .iqlaab,
        keywords: ["iqlab", "iqlaab", "conversion", "flip"]
    )

    static let ikhfaa = LetterFamily(
        id: "ikhfaa", name: "Ikhfaa Haqiqi", arabic: "الإِخفَاء الحَقِيقِيّ", meaning: "Hidden",
        summary: "The noon is hidden: between clear and merged, with a two-count hum.",
        detail: [
            "The tongue does not touch the noon's place. It gets ready for the next letter instead, while the nose carries the hum, so the hum is heavy before a heavy letter (ص ض ط ظ ق) and light before the rest.",
        ],
        letters: ["ص", "ذ", "ث", "ك", "ج", "ش", "ق", "س", "د", "ط", "ز", "ف", "ت", "ض", "ظ"],
        mnemonic: "صِفۡ ذَا ثَنَا كَمۡ جَادَ شَخۡصٌ قَدۡ سَمَا\nدُمۡ طَيِّبًا زِدۡ فِي تُقًى ضَعۡ ظَالِمًا",
        mnemonicNote: "A line of Tuhfat al-Atfal: the first letter of each word is an ikhfaa letter.",
        systemImage: "eye.slash", lessonID: "ikhfa", legend: .ikhfaaLight,
        keywords: ["ikhfa", "ikhfaa", "hidden", "hiding", "conceal"]
    )

    // MARK: Meem sakinah

    static let ikhfaaShafawi = LetterFamily(
        id: "ikhfaaShafawi", name: "Ikhfaa Shafawi", arabic: "الإِخفَاء الشَّفَوِيّ", meaning: "Hidden at the Lips",
        summary: "Before a baa, the meem is hidden with a two-count hum.",
        detail: [
            "The lips close lightly, without pressing, and the hum is held before the baa opens. The mushaf leaves the meem bare, with no sukoon.",
        ],
        letters: ["ب"],
        systemImage: "eye.slash", lessonID: "mim-sakin-rules", legend: .ikhfaaLight,
        keywords: ["shafawi", "lips", "ikhfa"]
    )

    static let idghamShafawi = LetterFamily(
        id: "idghamShafawi", name: "Idgham Shafawi", arabic: "الإِدغَام الشَّفَوِيّ", meaning: "Merged at the Lips",
        summary: "Before another meem, the two merge into one doubled meem with a two-count hum.",
        detail: [
            "Also called idgham mithlayn sagheer (إِدغَام المِثلَين الصَّغِير): two identical letters, the first with a sukoon. The mushaf shows it with a shaddah on the second meem.",
        ],
        letters: ["م"],
        systemImage: "arrow.triangle.merge", lessonID: "mim-sakin-rules", legend: .idghamGhunnah,
        keywords: ["shafawi", "lips", "mithlayn", "idgham"]
    )

    static let idhaarShafawi = LetterFamily(
        id: "idhaarShafawi", name: "Idhaar Shafawi", arabic: "الإِظهَار الشَّفَوِيّ", meaning: "Clear at the Lips",
        summary: "Before every other letter, the meem is pronounced clearly.",
        detail: [
            "Take the most care before waaw and faa: they are made at the lips too, so the meem is tempted to hide or merge. Close the lips fully on the meem, then move on.",
        ],
        letters: complement(of: ["ب", "م", "ا"]),
        systemImage: "speaker.wave.2", lessonID: "mim-sakin-rules",
        keywords: ["shafawi", "lips", "clear", "idhar"]
    )

    // MARK: The laam of al-

    static let sunLetters = LetterFamily(
        id: "sunLetters", name: "Laam Shamsiyyah", arabic: "اللَّام الشَّمسِيَّة", meaning: "Sun Letters",
        summary: "The laam of ٱلۡ is not read: it merges into the letter, which is doubled.",
        detail: [
            "The mushaf leaves the laam bare and writes a shaddah on the next letter: ٱلشَّمۡس is read \u{201C}ash-shams\u{201D}, never \u{201C}al-shams\u{201D}. All fourteen are made near the laam's own place at the front of the tongue, which is why the laam gives way to them.",
        ],
        letters: ["ط", "ث", "ص", "ر", "ت", "ض", "ذ", "ن", "د", "س", "ظ", "ز", "ش", "ل"],
        mnemonic: "طِبۡ ثُمَّ صِلۡ رَحِمًا تَفُزۡ ضِفۡ ذَا نِعَمۡ\nدَعۡ سُوءَ ظَنٍّ زُرۡ شَرِيفًا لِلۡكَرَمۡ",
        mnemonicNote: "A line of Tuhfat al-Atfal: the first letter of each word is a sun letter.",
        systemImage: "sun.max", lessonID: "lam-shamsiyyah-qamariyyah", legend: .lamShamsiyah,
        keywords: ["sun", "solar", "shams", "shamsi", "shamsiyyah"]
    )

    static let moonLetters = LetterFamily(
        id: "moonLetters", name: "Laam Qamariyyah", arabic: "اللَّام القَمَرِيَّة", meaning: "Moon Letters",
        summary: "The laam of ٱلۡ is read clearly, with a sukoon.",
        detail: [
            "The mushaf writes the sukoon on the laam: ٱلۡقَمَر is read \u{201C}al-qamar\u{201D}. The alif in the classic list of fourteen is the hamza, as in ٱلۡأَرۡض: no word begins with a bare alif.",
        ],
        letters: ["ء", "ب", "غ", "ح", "ج", "ك", "و", "خ", "ف", "ع", "ق", "ي", "م", "ه"],
        mnemonic: "ٱبۡغِ حَجَّكَ وَخَفۡ عَقِيمَهُ",
        mnemonicNote: "Every letter of the phrase is a moon letter.",
        systemImage: "moon", lessonID: "lam-shamsiyyah-qamariyyah",
        keywords: ["moon", "lunar", "qamar", "qamari", "qamariyyah"]
    )

    // MARK: Madd letters

    static let maddLetters = LetterFamily(
        id: "maddLetters", name: "Huroof al-Madd", arabic: "حُرُوف المَدّ", meaning: "Long Vowels",
        summary: "Alif after a fatha, waaw after a damma, yaa after a kasra: a vowel held two counts.",
        detail: [
            "Two counts is the natural madd (مَدّ طَبِيعِيّ). A hamza or a sukoon after the madd letter lengthens it to four, five or six, and the mushaf marks that with the madd sign (ٓ).",
            "Waaw and yaa are also the leen letters when they carry a sukoon after a fatha.",
        ],
        letters: ["ا", "و", "ي"],
        mnemonic: "نُوحِيهَآ",
        mnemonicNote: "One Quranic word with all three long vowels in it (Quran 11:49).",
        systemImage: "arrow.left.and.right", lessonID: "madd-tabii", legend: .maddNatural,
        keywords: ["madd", "long", "vowel", "elongation", "stretch"]
    )

    // MARK: Opening letters

    static let openersSix = LetterFamily(
        id: "openersSix", name: "Madd Lazim Harfi", arabic: "مَدّ لَازِم حَرفِيّ", meaning: "Held Six Counts",
        summary: "Opening letters whose names are three letters with a madd in the middle.",
        detail: [
            "An opening letter is read by its NAME: نٓ is read \u{201C}noon\u{201D}, and its long vowel is followed by a sukoon, so it is held six counts. The mushaf writes the madd sign over each of them.",
            "'Ayn may also be read four counts, because the middle of its name (عَيۡن) is a leen letter rather than a madd letter.",
        ],
        letters: ["ن", "ق", "ص", "ع", "س", "ل", "ك", "م"],
        mnemonic: "نَقَصَ عَسَلُكُمۡ",
        mnemonicNote: "Every letter of the phrase is held six counts.",
        systemImage: "6.circle", lessonID: "madd-lazim", legend: .maddNecessary,
        keywords: ["muqattaat", "opening", "six", "lazim", "harfi"]
    )

    static let openersTwo = LetterFamily(
        id: "openersTwo", name: "Madd Tabee'i Harfi", arabic: "مَدّ طَبِيعِيّ حَرفِيّ", meaning: "Held Two Counts",
        summary: "Opening letters whose names end in a plain long vowel.",
        detail: [
            "Their names are two letters (حَا يَا طَا هَا رَا), a natural madd with nothing after it to lengthen it further.",
        ],
        letters: ["ح", "ي", "ط", "ه", "ر"],
        mnemonic: "حَيٌّ طَهُرَ",
        mnemonicNote: "Every letter of the phrase is held two counts.",
        systemImage: "2.circle", lessonID: "madd-lazim", legend: .maddNatural,
        keywords: ["muqattaat", "opening", "two", "natural"]
    )

    static let openersNone = LetterFamily(
        id: "openersNone", name: "No Madd", arabic: "لَا مَدَّ فِيه", meaning: "Not Lengthened",
        summary: "Alif's name (أَلِف) has no madd letter in it, so it is read without any lengthening.",
        letters: ["ا"],
        systemImage: "0.circle", lessonID: "madd-lazim",
        keywords: ["muqattaat", "opening"]
    )

    /// The fourteen distinct openings of the twenty-nine surahs, as the Hafs text writes them.
    static let openings: [(text: String, surahs: [Int])] = [
        ("الٓمٓ", [2, 3, 29, 30, 31, 32]),
        ("الٓمٓصٓ", [7]),
        ("الٓر", [10, 11, 12, 14, 15]),
        ("الٓمٓر", [13]),
        ("كٓهيعٓصٓ", [19]),
        ("طه", [20]),
        ("طسٓمٓ", [26, 28]),
        ("طسٓ", [27]),
        ("يسٓ", [36]),
        ("صٓ", [38]),
        ("حمٓ", [40, 41, 42, 43, 44, 45, 46]),
        ("عٓسٓقٓ", [42]),
        ("قٓ", [50]),
        ("نٓ", [68]),
    ]

    /// The phrase that gathers all fourteen opening letters.
    static let openersMnemonic = "نَصٌّ حَكِيمٌ قَاطِعٌ لَهُ سِرٌّ"

    // MARK: Lookups

    private static let familiesByAxis: [LetterAxis: [LetterFamily]] = [
        .makhraj: [jawf, halq, aqsaLisan, wasatLisan, haffatLisan, tarafLisan, shafatan],
        .breath: [hams, jahr],
        .flow: [shiddah, tawassut, rakhawah],
        .elevation: [istila, istifal],
        .closure: [itbaq, infitah],
        .fluency: [idhlaq, ismat],
        .special: [safeer, qalqalah, leen, inhiraf, takreer, tafashshi, istitalah, ghunnah],
        .weight: [heavy, light, conditionalWeight, followsPrevious],
        .noonSakinah: [idhaar, idghamGhunnah, idghamBilaGhunnah, iqlaab, ikhfaa],
        .meemSakinah: [ikhfaaShafawi, idghamShafawi, idhaarShafawi],
        .lamOfAl: [sunLetters, moonLetters],
        .madd: [maddLetters],
        .openers: [openersSix, openersTwo, openersNone],
    ]

    static func families(of axis: LetterAxis) -> [LetterFamily] { familiesByAxis[axis] ?? [] }

    static let allFamilies: [LetterFamily] = LetterAxis.allCases.flatMap { families(of: $0) }

    private static let familiesByID: [String: LetterFamily] =
        Dictionary(allFamilies.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    static func family(id: String) -> LetterFamily? { familiesByID[id] }

    static func axis(of family: LetterFamily) -> LetterAxis? {
        LetterAxis.allCases.first { axis in families(of: axis).contains(family) }
    }

    /// The family of `axis` that `letter` belongs to, if any.
    static func family(of letter: String, on axis: LetterAxis) -> LetterFamily? {
        families(of: axis).first { $0.contains(letter) }
    }

    /// The letters of `axis` that none of its families claims, in alphabet order.
    static func unclaimedLetters(of axis: LetterAxis) -> [String] {
        let claimed = Set(families(of: axis).flatMap(\.letters))
        return alphabet.filter { !claimed.contains($0) }
    }

    /// The letter a page's tajweed profile is looked up by: the letter itself for the 28, the hamza
    /// for every seat a hamza is written on, and the alif for alif maqSoorah (an alif in a yaa's
    /// shape). `nil` for the letters that have no single profile (taa marbuuTah, laam alif, the madd
    /// spellings, hamzatul waSl) and for the non-Arabic letters.
    static func profileLetter(for letterData: LetterData) -> String? {
        if alphabet.contains(letterData.letter) { return letterData.letter }
        switch letterData.letter {
        case "أ", "إ", "ئ", "ؤ": return "ء"
        case "ى": return "ا"
        default: return nil
        }
    }

    /// The exits a letter is made at, deepest first. Waaw and yaa have two: one as a madd letter and
    /// one as a consonant.
    static func makharij(of letter: String) -> [LetterMakhraj] {
        makharij.filter { $0.letters.contains(letter) }
    }

    /// The qualities a letter is said with: its side of each of the five opposing pairs, then any
    /// quality with no opposite it also carries.
    static func sifaat(of letter: String) -> [LetterFamily] {
        let paired: [LetterAxis] = [.breath, .flow, .elevation, .closure, .fluency]
        return paired.compactMap { family(of: letter, on: $0) }
            + families(of: .special).filter { $0.contains(letter) }
    }

    /// Every family `letter` belongs to, across every axis.
    static func families(containing letter: String) -> [LetterFamily] {
        allFamilies.filter { $0.contains(letter) }
    }

    /// The openings a letter appears in, in mushaf order.
    static func openings(containing letter: String) -> [(text: String, surahs: [Int])] {
        openings.filter { opening in
            opening.text.unicodeScalars.contains { String($0) == letter }
        }
    }

    /// The words the alphabet's search matches a letter by: the families it belongs to, under the
    /// Arabic term, its English meaning and the common alternate spellings.
    ///
    /// Only the families that PICK letters out. "Every other letter" families (jahr, istifal, idhaar
    /// shafawi...) would make "idhaar" return twenty-six letters instead of the six throat letters,
    /// and no keyword here may be a letter's own name: "noon" has to find the letter noon, not every
    /// letter that follows one. The families themselves are still found by name, in the search's
    /// LETTER FAMILIES section.
    static func searchTerms(for letter: String) -> [String] {
        families(containing: letter)
            .filter { $0.letters.count <= searchableFamilySize }
            .flatMap { [$0.name.lowercased(), $0.meaning.lowercased()] + $0.keywords }
            .compactMap(withoutLetterNames)
    }

    /// A family's name can carry a LETTER's name ("Laam Shamsiyyah", "Noon into Meem"), and a search
    /// for that letter must not come back with the whole family: "noon" returned baa, through iqlaab,
    /// and "laam" all twenty-eight sun and moon letters. The letter names are dropped from the term,
    /// and a term with nothing left to say is dropped with them.
    private static func withoutLetterNames(_ term: String) -> String? {
        let kept = term.split(separator: " ").filter { !letterNameWords.contains(String($0)) && $0 != "into" }
        let joined = kept.joined(separator: " ")
        return joined.count >= 3 ? joined : nil
    }

    private static let letterNameWords: Set<String> = [
        "alif", "baa", "taa", "thaa", "jeem", "haa", "khaa", "daal", "dhaal", "raa", "zaay", "seen",
        "sheen", "saad", "daad", "dhaa", "ayn", "'ayn", "ghayn", "faa", "qaaf", "kaaf", "laam", "meem",
        "nuun", "noon", "waaw", "yaa", "hamza",
    ]

    /// The ikhfaa letters are the largest family that still picks letters out.
    private static let searchableFamilySize = 15

    // MARK: Rule examples (verbatim from the Hafs text)

    /// A noon sakinah followed by each letter.
    static let noonExamples: [String: LetterRuleExample] = [
        "ء": LetterRuleExample(text: "مَنۡ ءَامَنَ", surah: 2, ayah: 62),
        "ه": LetterRuleExample(text: "مِنۡ هَادٍ", surah: 39, ayah: 23),
        "ع": LetterRuleExample(text: "مِنۡ عِلۡمٍ", surah: 4, ayah: 157),
        "ح": LetterRuleExample(text: "مِنۡ حَيۡثُ", surah: 2, ayah: 199),
        "غ": LetterRuleExample(text: "مِنۡ غَيۡرِ", surah: 20, ayah: 22),
        "خ": LetterRuleExample(text: "مِنۡ خَيۡرٖ", surah: 2, ayah: 197),
        "ي": LetterRuleExample(text: "مَن يَقُولُ", surah: 2, ayah: 8),
        "ن": LetterRuleExample(text: "مِن نِّعۡمَةٖ", surah: 92, ayah: 19),
        "م": LetterRuleExample(text: "مِن مَّالٖ", surah: 23, ayah: 55),
        "و": LetterRuleExample(text: "مِن وَالٍ", surah: 13, ayah: 11),
        "ل": LetterRuleExample(text: "مِن لَّدُنۡهُ", surah: 4, ayah: 40),
        "ر": LetterRuleExample(text: "مِن رَّبِّهِمۡ", surah: 2, ayah: 26),
        "ب": LetterRuleExample(text: "مِنۢ بَعۡدِ", surah: 2, ayah: 27),
        "ت": LetterRuleExample(text: "مِن تَحۡتِهَا", surah: 2, ayah: 25),
        "ث": LetterRuleExample(text: "مِن ثَمَرَةٖ", surah: 2, ayah: 25),
        "ج": LetterRuleExample(text: "مَن جَآءَ", surah: 6, ayah: 160),
        "د": LetterRuleExample(text: "مِن دُونِ", surah: 2, ayah: 165),
        "ذ": LetterRuleExample(text: "مَن ذَا", surah: 2, ayah: 255),
        "ز": LetterRuleExample(text: "مَن زَكَّىٰهَا", surah: 91, ayah: 9),
        "س": LetterRuleExample(text: "عَن سَبِيلِ", surah: 2, ayah: 217),
        "ش": LetterRuleExample(text: "مِن شَرِّ", surah: 113, ayah: 2),
        "ص": LetterRuleExample(text: "عَن صَلَاتِهِمۡ", surah: 107, ayah: 5),
        "ض": LetterRuleExample(text: "مِن ضَرِيعٖ", surah: 88, ayah: 6),
        "ط": LetterRuleExample(text: "مِن طِينٖ", surah: 7, ayah: 12),
        "ظ": LetterRuleExample(text: "مَن ظَلَمَ", surah: 18, ayah: 87),
        "ف": LetterRuleExample(text: "مِن فَضۡلِهِۦ", surah: 2, ayah: 90),
        "ق": LetterRuleExample(text: "مِن قَبۡلُ", surah: 2, ayah: 25),
        "ك": LetterRuleExample(text: "مَن كَانَ", surah: 2, ayah: 97),
    ]

    /// A meem sakinah followed by each letter.
    static let meemExamples: [String: LetterRuleExample] = [
        "ب": LetterRuleExample(text: "تَرۡمِيهِم بِحِجَارَةٖ", surah: 105, ayah: 4),
        "م": LetterRuleExample(text: "وَلَكُم مَّا", surah: 2, ayah: 134),
        "ء": LetterRuleExample(text: "عَلَيۡهِمۡ ءَأَنذَرۡتَهُمۡ", surah: 2, ayah: 6),
        "ت": LetterRuleExample(text: "أَلَمۡ تَرَ", surah: 105, ayah: 1),
        "ث": LetterRuleExample(text: "رَبَّكُمۡ ثُمَّ", surah: 11, ayah: 3),
        "ج": LetterRuleExample(text: "لَهُمۡ جَنَّٰتٖ", surah: 2, ayah: 25),
        "ح": LetterRuleExample(text: "أَمۡ حَسِبۡتُمۡ", surah: 2, ayah: 214),
        "خ": LetterRuleExample(text: "ذَٰلِكُمۡ خَيۡرٞ", surah: 2, ayah: 54),
        "د": LetterRuleExample(text: "لَكُمۡ دِينُكُمۡ", surah: 109, ayah: 6),
        "ذ": LetterRuleExample(text: "لَكُمۡ ذُنُوبَكُمۡ", surah: 3, ayah: 31),
        "ر": LetterRuleExample(text: "لَكُمۡ رَسُولٌ", surah: 26, ayah: 107),
        "ز": LetterRuleExample(text: "أَمۡ زَاغَتۡ", surah: 38, ayah: 63),
        "س": LetterRuleExample(text: "لَهُمۡ سُوٓءُ", surah: 9, ayah: 37),
        "ش": LetterRuleExample(text: "لَهُمۡ شَرَابٞ", surah: 6, ayah: 70),
        "ص": LetterRuleExample(text: "كُنتُمۡ صَٰدِقِينَ", surah: 2, ayah: 23),
        "ض": LetterRuleExample(text: "لَكُمۡ ضَرّٗا", surah: 5, ayah: 76),
        "ط": LetterRuleExample(text: "لَكُمۡ طَالُوتَ", surah: 2, ayah: 247),
        "ظ": LetterRuleExample(text: "وَهُمۡ ظَٰلِمُونَ", surah: 16, ayah: 113),
        "ع": LetterRuleExample(text: "وَلَهُمۡ عَذَابٌ", surah: 2, ayah: 7),
        "غ": LetterRuleExample(text: "عَلَيۡهِمۡ غَيۡرِ", surah: 1, ayah: 7),
        "ف": LetterRuleExample(text: "هُمۡ فِيهَا", surah: 2, ayah: 39),
        "ق": LetterRuleExample(text: "هُمۡ قَوۡمٞ", surah: 27, ayah: 60),
        "ك": LetterRuleExample(text: "إِنَّهُمۡ كَانُواْ", surah: 7, ayah: 64),
        "ل": LetterRuleExample(text: "وَهُمۡ لَا", surah: 2, ayah: 281),
        "ن": LetterRuleExample(text: "أَمۡ نَحۡنُ", surah: 56, ayah: 59),
        "ه": LetterRuleExample(text: "أَمۡ هُمۡ", surah: 25, ayah: 17),
        "و": LetterRuleExample(text: "عَلَيۡهِمۡ وَلَا", surah: 1, ayah: 7),
        "ي": LetterRuleExample(text: "هُمۡ يَحۡزَنُونَ", surah: 2, ayah: 38),
    ]

    /// The definite article before each letter.
    static let lamExamples: [String: LetterRuleExample] = [
        "ء": LetterRuleExample(text: "ٱلۡأَرۡضِ", surah: 2, ayah: 11),
        "ب": LetterRuleExample(text: "ٱلۡبَيۡتِ", surah: 2, ayah: 127),
        "ت": LetterRuleExample(text: "ٱلتَّوَّابُ", surah: 2, ayah: 37),
        "ث": LetterRuleExample(text: "ٱلثَّمَرَٰتِ", surah: 2, ayah: 22),
        "ج": LetterRuleExample(text: "ٱلۡجَنَّةَ", surah: 2, ayah: 35),
        "ح": LetterRuleExample(text: "ٱلۡحَمۡدُ", surah: 1, ayah: 2),
        "خ": LetterRuleExample(text: "ٱلۡخَبِيرُ", surah: 6, ayah: 18),
        "د": LetterRuleExample(text: "ٱلدِّينِ", surah: 1, ayah: 4),
        "ذ": LetterRuleExample(text: "ٱلذِّكۡرَ", surah: 15, ayah: 9),
        "ر": LetterRuleExample(text: "ٱلرَّحۡمَٰنِ", surah: 1, ayah: 1),
        "ز": LetterRuleExample(text: "ٱلزَّكَوٰةَ", surah: 2, ayah: 43),
        "س": LetterRuleExample(text: "ٱلسَّمَآءِ", surah: 2, ayah: 19),
        "ش": LetterRuleExample(text: "ٱلشَّمۡسَ", surah: 6, ayah: 78),
        "ص": LetterRuleExample(text: "ٱلصَّلَوٰةَ", surah: 2, ayah: 3),
        "ض": LetterRuleExample(text: "ٱلضَّآلِّينَ", surah: 1, ayah: 7),
        "ط": LetterRuleExample(text: "ٱلطَّيۡرِ", surah: 2, ayah: 260),
        "ظ": LetterRuleExample(text: "ٱلظَّٰلِمِينَ", surah: 2, ayah: 35),
        "ع": LetterRuleExample(text: "ٱلۡعَٰلَمِينَ", surah: 1, ayah: 2),
        "غ": LetterRuleExample(text: "ٱلۡغَفُورُ", surah: 10, ayah: 107),
        "ف": LetterRuleExample(text: "ٱلۡفَلَقِ", surah: 113, ayah: 1),
        "ق": LetterRuleExample(text: "ٱلۡقُرۡءَانَ", surah: 4, ayah: 82),
        "ك": LetterRuleExample(text: "ٱلۡكِتَٰبُ", surah: 2, ayah: 2),
        "ل": LetterRuleExample(text: "ٱللَّطِيفُ", surah: 6, ayah: 103),
        "م": LetterRuleExample(text: "ٱلۡمُسۡتَقِيمَ", surah: 1, ayah: 6),
        "ن": LetterRuleExample(text: "ٱلنَّاسِ", surah: 114, ayah: 1),
        "ه": LetterRuleExample(text: "ٱلۡهُدَىٰ", surah: 2, ayah: 120),
        "و": LetterRuleExample(text: "ٱلۡوَٰحِدُ", surah: 12, ayah: 39),
        "ي": LetterRuleExample(text: "ٱلۡيَوۡمَ", surah: 2, ayah: 249),
    ]

    // MARK: Sound-alikes

    /// The pairs a learner swaps most, each with the one thing that separates them. What they share
    /// and where they differ is COMPUTED from the families above (`differences(between:and:)`), so
    /// the page can never claim a difference the tables do not hold.
    static let soundAlikes: [SoundAlikePair] = [
        SoundAlikePair(first: "س", second: "ص",
                       tip: "Same place, same whistle. Saad raises the tongue and clamps it; seen keeps it low."),
        SoundAlikePair(first: "ت", second: "ط",
                       tip: "Same place, at the roots of the upper front teeth. Taa (ط) is heavy and voiced; taa (ت) is light and breathy."),
        SoundAlikePair(first: "د", second: "ض",
                       tip: "Daal taps the tongue tip behind the upper front teeth. Daad presses the SIDE of the tongue against the upper molars, and is heavy."),
        SoundAlikePair(first: "ذ", second: "ظ",
                       tip: "Same place, the tongue tip on the edges of the upper front teeth. Dhaa (ظ) is the heavy twin."),
        SoundAlikePair(first: "ذ", second: "ز",
                       tip: "For dhaal the tongue tip comes out to touch the edges of the upper teeth. For zaay it stays behind them and whistles."),
        SoundAlikePair(first: "ث", second: "س",
                       tip: "For thaa the tongue tip touches the edges of the upper teeth. For seen it stays behind them and whistles."),
        SoundAlikePair(first: "ه", second: "ح",
                       tip: "Both are breathy throat letters. Haa (ه) is a plain breath from the bottom of the throat; Haa (ح) is squeezed from the middle of it."),
        SoundAlikePair(first: "ء", second: "ع",
                       tip: "Hamza is a clean stop at the bottom of the throat. 'Ayn is a voiced squeeze from the middle of the throat, and can be held."),
        SoundAlikePair(first: "ك", second: "ق",
                       tip: "Kaaf is light, with a puff of breath. Qaaf is one step further back, heavy, and bounces with a sukoon."),
        SoundAlikePair(first: "خ", second: "غ",
                       tip: "Same place at the top of the throat. Khaa is breathed; ghayn is voiced."),
        SoundAlikePair(first: "ح", second: "خ",
                       tip: "Haa is a clear squeeze from the middle of the throat. Khaa is a rasp from the top of the throat, and heavy."),
        SoundAlikePair(first: "ض", second: "ظ",
                       tip: "Daad runs along the side of the tongue at the molars. Dhaa is at the tongue tip and the front teeth."),
    ]

    static func soundAlikes(for letter: String) -> [SoundAlikePair] {
        soundAlikes.filter { $0.contains(letter) }
    }

    /// One row of the comparison between two letters: the question, and each letter's answer.
    struct Difference: Identifiable, Hashable {
        let axis: LetterAxis
        let first: LetterFamily?
        let second: LetterFamily?

        var id: String { axis.rawValue }
        var isShared: Bool { first == second }
    }

    /// The axes a comparison is drawn on: place first, then the five opposing pairs.
    private static let comparisonAxes: [LetterAxis] = [.makhraj, .breath, .flow, .elevation, .closure, .fluency]

    static func differences(between first: String, and second: String) -> [Difference] {
        comparisonAxes.map { axis in
            Difference(axis: axis, first: family(of: first, on: axis), second: family(of: second, on: axis))
        }
    }

    /// Whether two letters leave the very same exit (one of the seventeen), which is a finer test
    /// than sharing a zone: ت and ط do, ذ and ز do not.
    static func shareExit(_ first: String, _ second: String) -> Bool {
        makharij(of: first).contains { $0.letters.contains(second) }
    }
}
