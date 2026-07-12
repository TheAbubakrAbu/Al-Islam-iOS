import Foundation

/// Spelled-out pronunciation data for the muqatta'at - the disconnected opening letters of 29 surahs
/// (e.g. الٓمٓ). The mushaf prints them joined with maddah marks, but they are recited letter by letter
/// ("Alif Lām Mīm"), so this provides the individual letters, their fully-vocalized Arabic names, and a
/// transliteration to display as a reading aid above the ayah.
///
/// Tashkeel notes (so the names recite - and colour - correctly):
/// - Letters whose names carry a 6-count madd lāzim (نقص عسلكم → ن ق ص ع س ل ك م) are marked with the
///   maddah sign (U+0653) on their long vowel, exactly the way the mushaf marks الٓمٓ. That sign is what
///   the tajweed engine keys madd-lāzim colouring off, so the spelled-out names colour like the real ayah.
/// - The remaining letters (حي طهر → ح ي ط ه ر) take an ordinary 2-count madd, so they get the plain
///   long vowel with no maddah sign.
/// - No shaddah is written on the names. The idghām gemination between adjacent letters (e.g. لام → ميم
///   in الٓمٓ) is treated as madd lāzim via the maddah sign, but not shown as a shaddah.
/// - The "no vowel" mark is the Uthmani U+06E1 (small high dotless head of khah), not the plain sukūn.
/// - A final nūn or mīm that meets a following letter triggering a noon/meem rule (ikhfāʾ, idghām, …) is
///   left BARE (no sukūn). The mushaf does the same, and it lets the engine colour the rule - e.g. the
///   nūn of سِين before قَاف in عٓسٓقٓ is ikhfāʾ, so it carries no sukūn. A sukūn is kept only when the
///   letter is final or its rule is iẓhār (clear), where the nūn/mīm really is plainly silent/clear.
enum Muqattaat {
    struct LetterName {
        let letter: Character       // ا
        let transliteration: String // Alif
    }

    /// The 14 distinct letters that appear in the muqatta'at: bare letter + transliteration.
    static let letterNames: [Character: LetterName] = [
        "ا": LetterName(letter: "ا", transliteration: "Alif"),
        "ل": LetterName(letter: "ل", transliteration: "Lām"),
        "م": LetterName(letter: "م", transliteration: "Mīm"),
        "ص": LetterName(letter: "ص", transliteration: "Ṣād"),
        "ر": LetterName(letter: "ر", transliteration: "Rā"),
        "ك": LetterName(letter: "ك", transliteration: "Kāf"),
        "ه": LetterName(letter: "ه", transliteration: "Hā"),
        "ي": LetterName(letter: "ي", transliteration: "Yā"),
        "ع": LetterName(letter: "ع", transliteration: "ʿAyn"),
        "ط": LetterName(letter: "ط", transliteration: "Ṭā"),
        "س": LetterName(letter: "س", transliteration: "Sīn"),
        "ح": LetterName(letter: "ح", transliteration: "Ḥā"),
        "ق": LetterName(letter: "ق", transliteration: "Qāf"),
        "ن": LetterName(letter: "ن", transliteration: "Nūn"),
    ]

    /// Ordered bare letters for each muqatta'at ayah, keyed by surah then ayah. Almost always ayah 1;
    /// Ash-Shura (42) is the exception - its muqatta'at span ayah 1 (Ḥā Mīm) and ayah 2 (ʿAyn Sīn Qāf).
    private static let lettersBySurahAyah: [Int: [Int: [Character]]] = [
        2:  [1: ["ا", "ل", "م"]],
        3:  [1: ["ا", "ل", "م"]],
        7:  [1: ["ا", "ل", "م", "ص"]],
        10: [1: ["ا", "ل", "ر"]],
        11: [1: ["ا", "ل", "ر"]],
        12: [1: ["ا", "ل", "ر"]],
        13: [1: ["ا", "ل", "م", "ر"]],
        14: [1: ["ا", "ل", "ر"]],
        15: [1: ["ا", "ل", "ر"]],
        19: [1: ["ك", "ه", "ي", "ع", "ص"]],
        20: [1: ["ط", "ه"]],
        26: [1: ["ط", "س", "م"]],
        27: [1: ["ط", "س"]],
        28: [1: ["ط", "س", "م"]],
        29: [1: ["ا", "ل", "م"]],
        30: [1: ["ا", "ل", "م"]],
        31: [1: ["ا", "ل", "م"]],
        32: [1: ["ا", "ل", "م"]],
        36: [1: ["ي", "س"]],
        38: [1: ["ص"]],
        40: [1: ["ح", "م"]],
        41: [1: ["ح", "م"]],
        42: [1: ["ح", "م"], 2: ["ع", "س", "ق"]],
        43: [1: ["ح", "م"]],
        44: [1: ["ح", "م"]],
        45: [1: ["ح", "م"]],
        46: [1: ["ح", "م"]],
        50: [1: ["ق"]],
        68: [1: ["ن"]],
    ]

    // Combining marks (kept explicit so the vocalization is unambiguous).
    private static let fatha  = "\u{064E}"
    private static let kasra  = "\u{0650}"
    private static let damma  = "\u{064F}"
    private static let maddah = "\u{0653}" // the mushaf's madd-lāzim sign, e.g. الٓمٓ
    private static let sukoon = "\u{06E1}" // ARABIC SMALL HIGH DOTLESS HEAD OF KHAH (Uthmani "no vowel")

    // Fully vocalized letter names. The long vowel + maddah marks (and colours) madd lāzim; no shaddah is
    // written. A final nūn/mīm keeps its sukūn only when it is iẓhār or word-final - when a noon/meem rule
    // applies it is left bare (…Bare) so the engine colours the ikhfāʾ / idghām instead.
    private static let alif    = "\u{0623}" + fatha + "\u{0644}" + kasra + "\u{0641}" + sukoon   // a-li-f (no madd)
    private static let lam     = "\u{0644}" + fatha + "\u{0627}" + maddah + "\u{0645}" + sukoon  // lā-m, iẓhār (before rā)
    private static let lamBare = "\u{0644}" + fatha + "\u{0627}" + maddah + "\u{0645}"           // lā-m, idghām into mīm
    private static let mim     = "\u{0645}" + kasra + "\u{064A}" + maddah + "\u{0645}" + sukoon  // mī-m (iẓhār / final)
    private static let sad     = "\u{0635}" + fatha + "\u{0627}" + maddah + "\u{062F}" + sukoon  // ṣā-d
    private static let kaf     = "\u{0643}" + fatha + "\u{0627}" + maddah + "\u{0641}" + sukoon  // kā-f
    private static let sin     = "\u{0633}" + kasra + "\u{064A}" + maddah + "\u{0646}" + sukoon  // sī-n (iẓhār / final)
    private static let sinBare = "\u{0633}" + kasra + "\u{064A}" + maddah + "\u{0646}"           // sī-n, ikhfāʾ / idghām
    private static let ayn     = "\u{0639}" + fatha + "\u{064A}" + maddah + "\u{0646}"           // ʿay-n, always ikhfāʾ here
    private static let qaf     = "\u{0642}" + fatha + "\u{0627}" + maddah + "\u{0641}" + sukoon  // qā-f
    private static let nun     = "\u{0646}" + damma + "\u{0648}" + maddah + "\u{0646}" + sukoon  // nū-n (final)
    // Natural 2-count madd letters: plain long vowel, no maddah sign.
    private static let ra      = "\u{0631}" + fatha + "\u{0627}"  // rā
    private static let ha      = "\u{0647}" + fatha + "\u{0627}"  // hā
    private static let ya      = "\u{064A}" + fatha + "\u{0627}"  // yā
    private static let taa     = "\u{0637}" + fatha + "\u{0627}"  // ṭā
    private static let haa     = "\u{062D}" + fatha + "\u{0627}"  // ḥā

    /// Fully vocalized recitation of each distinct combination, keyed by the bare letters joined.
    /// Bare nūn/mīm are chosen per the noon/meem rule with the following letter:
    /// لام→ميم idghām, عين/سين→(ص/س/ق) ikhfāʾ, سين→ميم idghām bi-ghunnah.
    private static let vocalizedByLetters: [String: String] = [
        "الم":   [alif, lamBare, mim].joined(separator: " "),
        "المص":  [alif, lamBare, mim, sad].joined(separator: " "),
        "الر":   [alif, lam, ra].joined(separator: " "),
        "المر":  [alif, lamBare, mim, ra].joined(separator: " "),
        "كهيعص": [kaf, ha, ya, ayn, sad].joined(separator: " "),
        "طه":    [taa, ha].joined(separator: " "),
        "طسم":   [taa, sinBare, mim].joined(separator: " "),
        "طس":    [taa, sin].joined(separator: " "),
        "يس":    [ya, sin].joined(separator: " "),
        "ص":     sad,
        "حم":    [haa, mim].joined(separator: " "),
        "عسق":   [ayn, sinBare, qaf].joined(separator: " "),
        "ق":     qaf,
        "ن":     nun,
    ]

    /// The letter names that carry the maddah sign above, and so are held for the 6-count madd lāzim: نقص عسلكم.
    private static let maddLazimLetters: Set<Character> = ["ن", "ق", "ص", "ع", "س", "ل", "ك", "م"]
    /// The letter names that carry a plain long vowel and are held for the ordinary 2 counts: حي طهر.
    private static let maddNaturalLetters: Set<Character> = ["ح", "ي", "ط", "ه", "ر"]
    /// ʿayn is a leen letter, so its name is held for 4 or 6 counts rather than a flat 6.
    private static let leenLetter: Character = "ع"

    struct Pronunciation {
        let letters: [LetterName]
        /// Fully vocalized letter names, e.g. "أَلِفۡ لَآم مِيٓمۡ".
        let spelledOutArabic: String
        /// Individual letters separated for clarity, e.g. "ا ل م".
        var individualLetters: String { letters.map { String($0.letter) }.joined(separator: " ") }
        /// Transliteration of the letter names, e.g. "Alif Lām Mīm".
        var transliteration: String { letters.map { $0.transliteration }.joined(separator: " ") }

        /// What to tell the reader about elongation, derived from the letters actually present rather than assumed.
        ///
        /// Only نقص عسلكم carry the maddah sign (the red squiggle) and take the 6-count madd lāzim; حي طهر carry a
        /// plain long vowel and take 2; أَلِف has no long vowel at all. So Ṭā-Hā, which is only ط + ه, has no 6-count
        /// madd anywhere and must not claim one. `nil` when the combination has no madd to describe.
        var maddDescription: String? {
            let chars = Set(letters.map(\.letter))
            let lazim = chars.contains { Muqattaat.maddLazimLetters.contains($0) }
            let natural = chars.contains { Muqattaat.maddNaturalLetters.contains($0) }
            let leen = chars.contains(Muqattaat.leenLetter)

            switch (lazim, natural) {
            case (true, true):   return leen ? "Madd is 2, 4, or 6 counts" : "Madd is 2 or 6 counts"
            case (true, false):  return leen ? "Madd is 4 or 6 counts" : "Madd is 6 counts"
            case (false, true):  return "Madd is 2 counts"
            case (false, false): return nil
            }
        }
    }

    /// The muqatta'at pronunciation for the given ayah, or nil if that ayah does not open with them.
    static func pronunciation(surah: Int, ayah: Int) -> Pronunciation? {
        guard let chars = lettersBySurahAyah[surah]?[ayah] else { return nil }
        let names = chars.compactMap { letterNames[$0] }
        guard names.count == chars.count, !names.isEmpty else { return nil }
        let vocalized = vocalizedByLetters[String(chars)] ?? names.map { $0.transliteration }.joined(separator: " ")
        return Pronunciation(letters: names, spelledOutArabic: vocalized)
    }
}
