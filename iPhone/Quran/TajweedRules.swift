import SwiftUI

enum TajweedLegendCategory: String, CaseIterable, Identifiable {
    case lamShamsiyah
    case droppedLetter
    case hamzatWaslSilent
    case idghamBilaGhunnah
    
    case idghamGhunnah
    case generalGhunnah
    case ikhfaaLight
    case ikhfaaHeavy
    case iqlaab
    
    case qalqalah
    case tafkhim
    
    case maddNatural
    case maddNaturalMiniature
    case maddSukoon
    case maddSeparated
    case maddConnected
    case maddNecessary

    enum Section: String, CaseIterable, Identifiable {
        case silents
        case ghunnah
        case sifaat
        case madd

        var id: String { rawValue }

        var title: String {
            switch self {
            case .silents: return "Sukn (Silent)"
            case .ghunnah: return "Ghunnah (Nasal)"
            case .sifaat: return "Sifaat (Articulation)"
            case .madd: return "Madd (Elongation)"
            }
        }
    }

    var id: String { rawValue }

    var englishTitle: String {
        switch self {
        case .lamShamsiyah: return "Solar Lam"
        case .droppedLetter: return "Written but Not Pronounced"
        case .hamzatWaslSilent: return "Joining Hamzah"
        case .idghamBilaGhunnah: return "Merge Without Ghunnah"
            
        case .idghamGhunnah: return "Merge with Ghunnah"
        case .generalGhunnah: return "Shaddah Ghunnah"
        case .ikhfaaLight: return "Hidden Letter (Light)"
        case .ikhfaaHeavy: return "Hidden Letter (Heavy)"
        case .iqlaab: return "Noon into Meem"
            
        case .qalqalah: return "Bounce Letter"
        case .tafkhim: return "Heavy Letter"
            
        case .maddNatural: return "Madd Letters (2 Counts)"
        case .maddNaturalMiniature: return "Tiny Madd Marks"
        case .maddSukoon: return "Ending Madd"
        case .maddSeparated: return "Madd Munfasil"
        case .maddConnected: return "Madd Muttasil"
        case .maddNecessary: return "Madd Lazim"
            
        @unknown default: return rawValue
        }
    }

    var arabicTitle: String {

        switch self {
        case .lamShamsiyah: return "لَامٌ شَمسِيَّة"
        case .droppedLetter: return "حَرفٌ غَيرُ مَنطُوق"
        case .hamzatWaslSilent: return "هَمزَةُ الوَصل"
        case .idghamBilaGhunnah: return "إِدغَامٌ بِلَا غُنَّة"
            
        case .idghamGhunnah: return "إِدغَامٌ بِغُنَّةٍ"
        case .generalGhunnah: return "غُنَّة عَامَّة"
        case .ikhfaaLight: return "إِخفَاء مُرَقَّق"
        case .ikhfaaHeavy: return "إِخفَاء مُفَخَّم"
        case .iqlaab: return "إِقلَاب"
            
        case .qalqalah: return "قَلقَلَة"
        case .tafkhim: return "تَفخِيم"
            
        case .maddNatural: return "مَدٌّ طَبِيعِي"
        case .maddNaturalMiniature: return "مَدٌّ طَبِيعِي صَغِير"
        case .maddSukoon: return "مَدّ الوَقف"
        case .maddSeparated: return "مَدٌّ مُنفَصِل"
        case .maddConnected: return "مَدٌّ مُتَّصِل"
        case .maddNecessary: return "مَدٌّ لَازِم"

        @unknown default: return rawValue

        }

    }

    var transliteration: String {
        switch self {
        case .lamShamsiyah: return "Laam Shamiyyah"
        case .droppedLetter: return "Harf Ghayr Mantuq"
        case .hamzatWaslSilent: return "Hamzat al-Wasl"
        case .idghamBilaGhunnah: return "Idgham Bilaa Ghunnah"
            
        case .idghamGhunnah: return "Idgham Bighunnah"
        case .generalGhunnah: return "Ghunnah Aammah"
        case .ikhfaaLight: return "Ikhfaa (Light)"
        case .ikhfaaHeavy: return "Ikhfaa (Heavy)"
        case .iqlaab: return "Iqlaab"
            
        case .qalqalah: return "Qalqalah"
        case .tafkhim: return "Tafkheem"
            
        case .maddNatural: return "Madd Tabee Letters"
        case .maddNaturalMiniature: return "Madd Tabee Tiny Marks"
        case .maddSukoon: return "Ending Madd"
        case .maddSeparated: return "Madd Munfasil"
        case .maddConnected: return "Madd Muttasil"
        case .maddNecessary: return "Madd Laazim"
            
        @unknown default: return rawValue
        }
    }

    var exactEnglishTranslation: String {
        switch self {
        case .lamShamsiyah: return "Solar Lam"
        case .droppedLetter: return "Unpronounced letter"
        case .hamzatWaslSilent: return "Connecting Hamzah"
        case .idghamBilaGhunnah: return "Merging without nasal"
            
        case .idghamGhunnah: return "Merging with nasal"
        case .generalGhunnah: return "Shaddah nasalization"
        case .ikhfaaLight: return "Light Concealment"
        case .ikhfaaHeavy: return "Heavy Concealment"
        case .iqlaab: return "Conversion"
            
        case .qalqalah: return "Echoing bounce"
        case .tafkhim: return "Heavy articulation"
            
        case .maddNatural: return "Natural elongation letters"
        case .maddNaturalMiniature: return "Tiny natural elongation marks"
        case .maddSukoon: return "Elongation due to end"
        case .maddSeparated: return "Separated elongation"
        case .maddConnected: return "Connected elongation"
        case .maddNecessary: return "Necessary elongation"
            
        @unknown default: return rawValue
        }
    }

    var englishMeaning: String {
        switch self {
        case .lamShamsiyah:
            return "Solar lam: the lam in al- is absorbed into the following sun letter, so that next letter is emphasized."
        case .droppedLetter:
            return "A letter is written in the mushaf but not fully pronounced in recitation."
        case .hamzatWaslSilent:
            return "Hamzat al-wasl is heard only when starting a word and dropped when reading continuously from before it."
        case .idghamBilaGhunnah:
            return "Idgham bilaa ghunnah merges noon/tanween directly into the next letter without nasalization."
            
        case .idghamGhunnah:
            return "Idgham with ghunnah merges noon or tanween into the next letter with a nasal sound."
        case .generalGhunnah:
            return "This is the two-count nasal sound on noon or meem with shaddah, also used for linked helper highlights where the nasal target needs to stay clear."
        case .ikhfaaLight:
            return "Light Ikhfaa partially hides noon or tanween before certain letters with a lighter nasal ghunnah."
        case .ikhfaaHeavy:
            return "Heavy Ikhfaa partially hides noon or tanween before heavy letters with a stronger, fuller nasal ghunnah."
        case .iqlaab:
            return "Iqlaab changes noon/tanween to a meem-like sound before baa, with ghunnah."
            
        case .qalqalah:
            return "Qalqalah is a brief bounce on the Qutb Jad letters when they are sakin or when stopping on them."
        case .tafkhim:
            return "Tafkhim is a heavy, fuller articulation where the sound is pronounced with depth and thickness."
            
        case .maddNatural:
            return "Madd tabi'i is the baseline natural stretch of 2 counts on alif, waw, or ya after matching vowels."
        case .maddNaturalMiniature:
            return "Tiny madd marks such as small alif, small waw, and small ya indicate a natural two-count vowel sound written as miniature tashkeel."
        case .maddSukoon:
            return "Ending madd covers stop-based madd, including madd aarid lis-sukoon and madd leen. It is read as 2, 4, or 6 counts when stopping."
        case .maddSeparated:
            return "Madd munfasil is when a word ends with madd and the next word begins with hamzah, so the stretch carries across words."
        case .maddConnected:
            return "Madd muttasil is when a madd letter is followed by hamzah in the same word, so it is lengthened beyond natural madd."
        case .maddNecessary:
            return "Madd lazim is an obligatory fixed stretch of 6 counts due to a shaddah after madd."

        @unknown default:
            return "Tajweed rule meaning"
        }
    }

    var countLabel: String? {
        switch self {
        case .maddNatural, .maddNaturalMiniature, .idghamGhunnah, .generalGhunnah, .ikhfaaLight, .ikhfaaHeavy, .iqlaab:
            return "2 counts"
        case .maddSukoon:
            return "2, 4, or 6 counts"
        case .maddSeparated:
            return "2, 4, or 5 counts"
        case .maddConnected:
            return "4 or 5 counts"
        case .maddNecessary:
            return "6 counts"
        default:
            return nil
        }
    }

    var applicableLettersDetail: String? {
        switch self {
        case .idghamBilaGhunnah:
            return "When noon (ن) or tanween comes before: ل، ر"
            
        case .idghamGhunnah:
            return "When a noon sound (ن or tanween) comes before: ي، ن، م، و"
        case .generalGhunnah:
            return "Noon or meem with shaddah; also used on selected nasal merge targets"
        case .ikhfaaLight:
            return "When a noon sound (ن or tanween) comes before lighter letters: ت، ث، ج، د، ذ، ز، س، ش، ف، ك"
        case .ikhfaaHeavy:
            return "When a noon sound (ن or tanween) comes before heavier letters: ص، ض، ط، ظ، ق"
        case .iqlaab:
            return "When noon (ن) or tanween comes before: ب (changes to meem sound)"
            
        case .qalqalah:
            return "Letters that bounce when they have sukoon or are stopped on: ق، ط، ب، ج، د"
        case .tafkhim:
            return "Letters pronounced heavily (elevated tongue): خ، ص، ض، غ، ط، ق، ظ"
            
        case .maddNatural:
            return "Occurs on madd letters: ا، و، ي (normal 2-count elongation)"
        case .maddNaturalMiniature:
            return "Occurs on miniature madd marks: alif sagheerah, waw sagheerah, ya sagheerah"
        case .maddSukoon:
            return "When stopping creates madd aarid lis-sukoon after ا، و، ي, or madd leen after َ + وۡ / َ + يۡ"
        case .maddSeparated:
            return "When madd letters (ا، و، ي) are followed by hamzah in the next word"
        case .maddConnected:
            return "When madd letters (ا، و، ي) are followed by hamzah in the same word"
        case .maddNecessary:
            return "When madd letters (ا، و، ي) are followed by a permanent sukoon or shaddah"
            
        default:
            return nil
        }
    }

    /// Canonical color for this rule everywhere in the app.
    var color: Color {
        switch self {
        case .lamShamsiyah: return Color(red: 0.7059, green: 0.7059, blue: 0.7059) // B4B4B4
        case .hamzatWaslSilent: return Color(red: 0.7059, green: 0.7059, blue: 0.7059) // B4B4B4
        case .droppedLetter: return Color(red: 0.7059, green: 0.7059, blue: 0.7059) // B4B4B4
        case .idghamBilaGhunnah: return Color(red: 0.7059, green: 0.7059, blue: 0.7059) // B4B4B4
            
        case .idghamGhunnah: return Color(red: 0.2706, green: 0.7373, blue: 0.4510) // 45BC73
        case .generalGhunnah: return Color(red: 0.2706, green: 0.7373, blue: 0.4510) // same as idgham bighunnah
        case .ikhfaaLight: return Color(red: 0.2706, green: 0.7373, blue: 0.4510) // 45BC73 light green
        case .ikhfaaHeavy: return Color(red: 0.1216, green: 0.6667, blue: 0.5804) // 1FAA94 teal-accent green
        case .iqlaab: return Color(red: 0.4588, green: 0.6980, blue: 0.2000) // 75B233 olive-green
            
        case .tafkhim: return Color(red: 0.2314, green: 0.5216, blue: 0.7608) // 3B85C2
        case .qalqalah: return Color(red: 0.4706, green: 0.8000, blue: 0.9765) // 78CCF9
            
        case .maddNatural: return Color(red: 0.7255, green: 0.5490, blue: 0.1843) // B98C2F
        case .maddNaturalMiniature: return Color(red: 0.7255, green: 0.5490, blue: 0.1843) // B98C2F
        case .maddSukoon: return Color(red: 0.8902, green: 0.4745, blue: 0.2078) // E37935
        case .maddSeparated: return Color(red: 0.9216, green: 0.3176, blue: 0.6667) // EB51AA
        case .maddConnected: return Color(red: 0.8510, green: 0.2706, blue: 0.2431) // D9453E
        case .maddNecessary: return Color(red: 0.6824, green: 0.1451, blue: 0.0902) // AE2517
            
        @unknown default: return Color.secondary
        }
    }

    var section: Section {
        switch self {
        case .lamShamsiyah, .droppedLetter, .hamzatWaslSilent, .idghamBilaGhunnah:
            return .silents
        case .tafkhim, .qalqalah:
            return .sifaat
        case .maddNatural, .maddNaturalMiniature, .maddSukoon, .maddConnected, .maddSeparated, .maddNecessary:
            return .madd
        case .idghamGhunnah, .generalGhunnah, .ikhfaaLight, .ikhfaaHeavy, .iqlaab:
            return .ghunnah
        }
    }

    var sortRank: Int {
        switch self {
        case .lamShamsiyah: return 0
        case .droppedLetter: return 1
        case .hamzatWaslSilent: return 2
        case .idghamBilaGhunnah: return 3
            
        case .generalGhunnah: return 4
        case .idghamGhunnah: return 5
        case .ikhfaaLight: return 6
        case .ikhfaaHeavy: return 7
        case .iqlaab: return 8
            
        case .qalqalah: return 9
        case .tafkhim: return 10
            
        case .maddNatural: return 11
        case .maddNaturalMiniature: return 12
        case .maddSukoon: return 13
        case .maddNecessary: return 14
        case .maddSeparated: return 15
        case .maddConnected: return 16
        }
    }

    var shortDescription: String {
        switch self {
        case .lamShamsiyah:
            return "Lam of al- is silent before sun letters."
        case .droppedLetter:
            return "Letter written in the script but dropped in recitation."
        case .hamzatWaslSilent:
            return "Start-only hamzah; dropped when connecting."
        case .idghamBilaGhunnah:
            return "Silent-style merge into next without nasal sound."
            
        case .idghamGhunnah:
            return "Merge into the next letter with nasal."
        case .generalGhunnah:
            return "Noon/meem with shaddah nasal sound."
        case .ikhfaaLight:
            return "Lightly hide noon or tanween with nasal."
        case .ikhfaaHeavy:
            return "Heavily hide noon or tanween with nasal."
        case .iqlaab:
            return "Noon/tanween turns to meem before baa."
            
        case .qalqalah:
            return "Qutb jad letters bounce on sukoon/stop."
        case .tafkhim:
            return "Heavy, full-mouth pronunciation."
            
        case .maddNatural:
            return "From full vowel letters: alif, waw, or yaa."
        case .maddNaturalMiniature:
            return "From tiny vowel diacritics: small alif, waw, or yaa."
        case .maddSukoon:
            return "Stop-based madd, including aarid and leen."
        case .maddSeparated:
            return "Madd at word end before next hamzah."
        case .maddConnected:
            return "Madd letter + hamzah in one word."
        case .maddNecessary:
            return "Fixed required madd due to shaddah after madd."
            
        @unknown default:
            return "Tajweed rule"
        }
    }

    var longDescription: String {
        switch self {
        case .lamShamsiyah:
            return "In connected recitation, this appears most clearly in words beginning with al- followed by sun letters (like ta, daal, seen, sheen). The lam remains in writing but is absorbed into the next consonant, which is heard with emphasis/doubling."
        case .droppedLetter:
            return "This is a practical reading aid for orthographic letters preserved in the Uthmani script while the transmitted recitation does not fully sound them. Examples can include dropped alif, dropped yaa, or similar written forms that remain visible for script fidelity."
        case .hamzatWaslSilent:
            return "Its role is to allow smooth word-initial pronunciation when starting, but to avoid extra breaks mid-flow when linking words. In practice, students should test both states: start from the word (hear hamzah), then connect from before it (hamzah drops)."
        case .idghamBilaGhunnah:
            return "Unlike ghunnah-based merges, no nasal hold is maintained here; the sound moves straight into the target letter. This makes timing cleaner and shorter, so avoid adding extra nasal color by habit."
            
        case .idghamGhunnah:
            return "This uses merging into the next letter with a gentle nasal ghunnah. The sound flows smoothly, with the noon or tanween fully blending into the following letter while maintaining clear timing and resonance. It also overlaps with shafawi-style merging behavior in meem-linked contexts."
        case .generalGhunnah:
            return "Use this for explicit noon or meem with shaddah. It is also reused for a few helper target highlights in idgham-style nasal merges, so those targets stay visually connected to the same ghunnah family."
        case .ikhfaaLight:
            return "This is a light concealment, where the noon or tanween is partially hidden with a soft nasal ghunnah. The sound remains subtle, balancing clarity and smooth transition without fully merging. In shafawi contexts, meem before baa follows this same light-hidden nasal pattern."
        case .ikhfaaHeavy:
            return "This is a heavier concealment, where the noon or tanween is partially hidden with a stronger nasal ghunnah. The tongue prepares for the next letter while the ghunnah carries the sound, requiring careful control and balance."
        case .iqlaab:
            return "The practical cue is the following baa: articulation shifts toward the lips with a meem-quality nasal sound before entering baa. Done correctly, the transition sounds natural and connected rather than abrupt."
            
        case .qalqalah:
            return "The effect is a quick release, not an added harakah and not a long vowel. Strength can vary by position, but the principle stays the same: keep it crisp and brief so the consonant remains clear without over-bouncing."
        case .tafkhim:
            return "A useful way to hear it is contrast: read the same syllable lightly, then with tafkhim, and notice the darker resonance. It is strongest on isti'la letters and should stay controlled so heaviness does not spread into nearby vowels or letters."
        
        case .maddNatural:
            return "Because it is the reference madd length, mastering its steady two-count rhythm helps calibrate all longer madd forms. The stretch should sound even and relaxed, not clipped and not drifting longer than intended."
        case .maddNaturalMiniature:
            return "These tiny written signs carry the same two-count natural vowel sound but are controlled separately so you can hide or show miniature Uthmani madd marks independently from normal madd letters."
        case .maddSukoon:
            return "The key condition is pausing at the word ending. This includes madd aarid lis-sukoon, where the final letter becomes temporarily sakin after a normal madd letter, and madd leen, where a sakin waaw or yaa follows a fathah and is stretched softly when stopping. Use 2, 4, or 6 counts consistently, and keep madd leen no longer than the madd aarid length chosen in the same recitation."
        case .maddSeparated:
            return "Because the hamzah is in the following word, scholars classify this separately from muttasil. Allowed lengths vary by riwayah, so learners should follow one taught pattern and avoid switching counts randomly in the same recitation. This color also marks Madd Munfasil Hukmi (\"ruled\" separated). In a handful of words, the vocative يَٰٓ (\"O…\") and demonstrative هَٰٓ (\"these…\") particles are written joined to a following hamzah, such as يَٰٓأَيُّهَا and هَٰٓؤُلَآءِ; there, only that superscript-particle sequence is treated as separated even though it sits inside one written word."
        case .maddConnected:
            return "Since both elements occur inside one word, this is treated as a stronger extension than natural madd. Keep the elongation measured and stable according to your riwayah so the hamzah after it remains clear and not swallowed. Note one exception: in the يَٰٓ/هَٰٓ particle words (e.g. يَٰٓأَيُّهَا, هَٰٓؤُلَآءِ) the superscript madd before the hamzah is recited as Madd Munfasil Hukmi instead, but any real madd letter + hamzah elsewhere in those same words (e.g. لَآءِ in هَٰٓؤُلَآءِ) stays muttasil."
        case .maddNecessary:
            return "This category is fixed and not flexible like optional madd forms, so it should be given its full required length whenever encountered. Its consistency is one of the easiest ways to stabilize rhythm and accuracy in longer passages."
            
        @unknown default:
            return "Tajweed rule"
        }
    }
}

/// Single source of truth for tajweed coloring constants and rule-group metadata.
///
/// Keep the rule engine in one place so Quran rendering, legend labels, and future color tweaks
/// all read from the same definitions instead of duplicating sets and maps across files.
///
/// ============================================================================================
/// TAJWEED ENGINE REFERENCE
/// ============================================================================================
/// This is the full specification of how the app classifies and colors tajweed, written so a future
/// standalone engine can be rebuilt from it. `TajweedLegendCategory` (above) is the public rule set and
/// owns the canonical color + copy for each rule; the per-letter DETECTION lives in `QuranData`
/// (`collectMaddAndWaslPaintOps`, `appendExplicitMaddahPaintOps`, `appendTreeDrivenPaintOps`, and the
/// `append…PaintOps` helpers). This comment ties the two together and enumerates every exception.
///
/// --------------------------------------------------------------------------------------------
/// 1. PIPELINE (how a colored ayah is produced)
/// --------------------------------------------------------------------------------------------
///   a. The ayah's `textArabic` is split into GRAPHEME CLUSTERS (`CharacterClusterInfo`): one base
///      Arabic letter plus its trailing combining marks (harakat, shadda, maddah, dagger alif, small
///      high marks, etc.). Word boundaries are whitespace clusters (`wordClusterRanges`).
///   b. Two independent producers emit `PaintOp`s (a UTF-16 range + category + integer priority):
///        • TREE-DRIVEN: precomputed annotations decoded from the bundled tajweed JSON, keyed by
///          (surah, ayah), mapped to categories via `treeDrivenRuleMap`. Used mainly for the
///          ghunnah / ikhfaa / iqlaab / idgham / qalqalah / silent families.
///        • HEURISTIC: per-cluster scanning for madd, tafkhim, qalqalah, lam shamsiyyah, hamzat wasl,
///          and the madd EXCEPTIONS below. This is authoritative for madd.
///   c. All ops are sorted ascending by priority and applied per UTF-16 unit, so the HIGHEST priority
///      wins on any overlap (see `PaintPriority` in `QuranData`). Waqf ornaments are skipped.
///   d. A category is only painted if the user has it enabled (`isTajweedCategoryVisible`) and it is not
///      in `stopBasedCategories` (stop-only madds are computed but intentionally not painted yet).
///
/// --------------------------------------------------------------------------------------------
/// 2. KEY UNICODE SCALARS (the engine is scalar-driven, never glyph-driven)
/// --------------------------------------------------------------------------------------------
///   Madd letters (full):        alif U+0627, waw U+0648, yaa U+064A; alif-maqsura U+0649; alif-madda U+0622
///   Madd letters (superscript): dagger alif U+0670, small waw U+06E5, small yaa U+06E6, small high yaa U+06E7
///   Maddah (explicit madd):     U+0653  (turns a carrier into an explicit muttasil/munfasil/lazim madd)
///   Hamza (base letters):       U+0621 ء, U+0623 أ, U+0624 ؤ, U+0625 إ, U+0626 ئ
///   Hamza (combining, on seat): U+0654 (above), U+0655 (below) - e.g. tatweel+ٔ
///   Hamzat al-wasl:             U+0671 ٱ  (silent when connecting)
///   Harakat / shadda / sukoon:  fatha U+064E, damma U+064F, kasra U+0650, shadda U+0651, sukoon U+0652
///   Tanwin:                     fathatayn U+064B, dammatayn U+064C, kasratayn U+064D (+ Uthmani variants)
///   Iqlaab/ikhfaa tiny marks:   small high meem U+06E2, small low meem U+06ED (silent tanwin carriers)
///   Waqf ornaments:             U+06D6…U+06ED skipped for coloring EXCEPT {U+06E1, U+06E2, U+06E5,
///                               U+06E6, U+06ED} which are parts of letters, not stop symbols.
///
/// --------------------------------------------------------------------------------------------
/// 3. RULE TAXONOMY (category · trigger · length)
/// --------------------------------------------------------------------------------------------
///   MADD - elongation
///     • maddNatural (Tabi'i) ......... full madd letter preceded by its matching vowel, with NO maddah,
///                                      NO sukoon after, and not before hamza/hamzat-wasl. 2 counts.
///     • maddNaturalMiniature ......... a superscript madd mark (dagger alif / small waw / small yaa)
///                                      that does NOT itself carry a maddah. Still 2 counts.
///     • maddConnected (Muttasil) ..... madd letter + hamza in the SAME word. 4–5 counts (obligatory).
///     • maddSeparated (Munfasil) ..... madd letter ending a word + hamza starting the NEXT word.
///                                      2/4/5 counts. ALSO carries Munfasil Hukmi (see exceptions).
///     • maddSukoon (Aarid/Leen) ...... only when STOPPING: a madd letter (aarid) or leen (sakin
///                                      waw/yaa after fatha) before the final letter. 2/4/6 counts.
///                                      In `stopBasedCategories` → computed but not painted by default.
///     • maddNecessary (Lazim) ........ madd + permanent sukoon or shadda. 6 counts. Includes Lazim
///                                      Harfi (muqatta'at letter names) and Lazim Kalimi (e.g. ٱلضَّآلِّينَ).
///   GHUNNAH / NASAL (2-count nasal)
///     • idghamGhunnah, idghamBilaGhunnah, generalGhunnah, ikhfaaLight, ikhfaaHeavy, iqlaab - driven by
///       noon/tanwin + following letter (see the noon/tanwin sets below) and by tree annotations.
///   SIFAAT / ARTICULATION
///     • qalqalah ..... qutb-jad letters (ق ط ب ج د) on sukoon or when stopped. Verse-final too.
///     • tafkhim ...... isti'la letters (خ ص ض ط ظ غ ق); final ر has its own higher-priority case.
///   SILENT / JOINING (gray)
///     • hamzatWaslSilent, droppedLetter, lamShamsiyah, idghamBilaGhunnah.
///
/// --------------------------------------------------------------------------------------------
/// 4. NOON / TANWIN & MEEM TABLES (used by the ghunnah family)
/// --------------------------------------------------------------------------------------------
///   After noon-sakin / tanwin:
///     ن only ........... idgham WITH ghunnah          (`noonTanweenTargetOnlyIdghamLetters`)
///     م ي و ............ split idgham handling         (`noonTanweenSplitIdghamLetters`)
///     ل ر .............. idgham WITHOUT ghunnah        (`noonTanweenSourceOnlyIdghamLetters`)
///     ب ................ iqlaab (noon → meem sound)
///     ص ض ط ظ ق ........ ikhfaa HEAVY                  (`ikhfaaHeavyLetters`)
///     ت ث ج د ذ ز س ش ف ك  ikhfaa LIGHT               (`ikhfaaLightLetters`)
///   After meem-sakin: ب → iqlaab(shafawi-style), م → idgham ghunnah.
///   Helper alif/alif-maqsura after fathatayn is skipped to find the governed letter
///   (`fathataynFollowerSkipLetters`).
///
/// --------------------------------------------------------------------------------------------
/// 5. EXPLICIT-MADDAH CLASSIFIER (the core madd decision) - `explicitMaddahCategory`
/// --------------------------------------------------------------------------------------------
///   For any cluster carrying a maddah (U+0653) that is NOT a final-aarid carrier and NOT a tiny mark:
///     1. If the NEXT non-space cluster has a shadda → Lazim (maddNecessary).
///     2. Else scan forward, skipping transparent marks (tatweel, harakat) and hamzat-wasl:
///          • first hamza found  → with a word break before it = Munfasil, else = Muttasil.
///          • EXCEPTION (Hukmi)  → if this is one of the proper_words AND the carrier is a SUPERSCRIPT
///            madd letter, force Munfasil even though it is in the same word (see §6.1).
///     3. Else, if the carrier is a superscript mark → miniature natural madd.
///     4. Else → Lazim catch-all (explicit maddah that is none of the above).
///
/// --------------------------------------------------------------------------------------------
/// 6. EXCEPTIONS & SPECIAL CASES (the part a naive engine gets wrong)
/// --------------------------------------------------------------------------------------------
///   6.1  MADD MUNFASIL HUKMI ("ruled" separated). The vocative يَا and demonstrative هَا particles are
///        written joined to a following hamzah, so a superscript carrier (dagger alif / small waw / small
///        yaa) + maddah + hamza sits inside ONE written word yet is recited as Munfasil. The 21 exact
///        words are `QuranData.hukmiMunfasilProperWords` (NFC-normalized). Only that superscript-particle
///        sequence is overridden; a real madd letter + hamza elsewhere in the SAME word stays Muttasil
///        (e.g. هَٰٓؤُلَآءِ = هَٰٓؤُ munfasil-hukmi + لَآءِ muttasil).
///   6.2  GENUINE MUTTASIL WRITTEN WITH A DAGGER ALIF. A dagger alif + hamza inside one true morpheme
///        (no joined يَا/هَا) is ordinary Muttasil and must NOT be reclassified - أُوْلَٰٓئِكَ, مَلَٰٓئِكَة,
///        إِسۡرَٰٓءِيل. This is why the override is gated by the exact-word set, not by the dagger alif alone.
///   6.3  AYAH-FINAL LONE MADD. A lone madd letter ending the ayah is read as natural madd at waqf, not
///        as the Lazim catch-all (`ayahFinalMaddNaturalIndex`).
///   6.4  MADD 'IWAD. A word ending in tanwin-fath has a SILENT final alif; at waqf it is a 2-count 'iwad,
///        never aarid lis-sukoon. The final-aarid scan skips this silent alif (`finalWordMaddAaridCarrierIndex`).
///   6.5  MINIATURE MARK CARRYING A MADDAH. A dagger alif / small waw / small yaa is normally a 2-count
///        natural madd, but if it ALSO carries an explicit maddah it is handled by the explicit-maddah
///        classifier instead (so it can become muttasil/munfasil/lazim). See `hasMiniatureMaddMark`.
///   6.6  MUQATTA'AT (disconnected opening letters). Three buckets:
///          • `surahsOpeningMuqattaat` - letter names with a madd+sukoon are Lazim Harfi (6 counts);
///            in ayah 1 an explicit maddah forces Lazim.
///          • `completeAyahMuqattaatSurahs` - the letters fill the whole first ayah.
///          • `firstWordOnlyMuqattaatSurahs` - only the first WORD of ayah 1 is muqatta'at; the rest of
///            that ayah uses normal rules. (Ash-Shura's letters span the first TWO ayahs - handled apart.)
///   6.7  LAZIM KALIMI. A madd letter immediately before a shadda/permanent sukoon inside a word →
///        6 counts: combined alif+shadda clusters (ٱلضَّآلِّينَ) and waw-then-alif-sukoon sequences.
///   6.8  HAMZAT AL-WASL. Silent (gray) when connecting from a previous word; pronounced only when the
///        word is the start of recitation. The hamzat-wasl that opens the FIRST letter of an ayah is not
///        painted silent.
///   6.9  IQLAAB / IKHFAA TINY MARKS. A small high/low meem (U+06E2 / U+06ED) marks a tanwin that becomes
///        a hidden meem; the alif that follows is a silent tanwin carrier, NOT natural madd
///        (`clusterHasTinyMeemIqlaabMark`).
///   6.10 FINAL RAA TAFKHIM. A word-final ر carrying tafkhim uses a dedicated higher priority so it wins
///        over generic tafkhim on overlap.
///   6.11 STOP-BASED MADD NOT PAINTED. `maddSukoon` (aarid + leen) is fully detected but kept out of the
///        painted text for now (`stopBasedCategories`); the legend still documents it.
///   6.12 WAQF ORNAMENTS. Pause symbols in U+06D6…U+06ED are not colored, except the five exception
///        scalars that are letter components (`waqfScalarExceptions`).
///
/// --------------------------------------------------------------------------------------------
/// 7. PRIORITIES (highest wins; see `PaintPriority` in QuranData)
/// --------------------------------------------------------------------------------------------
///   Lowest: tafkhim/silent/ghunnah families → natural madd → aarid → lazim → explicit muttasil →
///   explicit munfasil(22) → explicit lazim(23) → hamzat-wasl-silent(50) → tiny-meem-iqlaab(51) →
///   final-raa-tafkhim(52). The Hukmi-munfasil override emits at the explicit-munfasil tier (22), the
///   highest madd tier, so it always beats any competing muttasil op for the same letters.
///
/// --------------------------------------------------------------------------------------------
/// 8. LENGTH SUMMARY (harakat / counts)
/// --------------------------------------------------------------------------------------------
///   Natural & miniature, Badal, 'Iwad, Tamkin, Silah-sughra ... 2
///   Munfasil & Munfasil-Hukmi & Silah-kubra ................... 2 / 4 / 5 (consistent within a recitation)
///   Muttasil ................................................. 4 / 5
///   Aarid lis-sukoon / Leen .................................. 2 / 4 / 6 (leen ≤ chosen aarid length)
///   Lazim (Harfi & Kalimi) ................................... 6 (fixed)
/// ============================================================================================
struct TajweedRules {
    /// Seven heavy letters used by tafkhim detection.
    static let heavyBaseLetters: Set<Character> = ["خ", "ص", "ض", "ط", "ظ", "غ", "ق"]

    /// Qalqalah letters (Qutb Jad).
    static let qalqalahLetters: Set<Character> = ["ق", "ط", "ب", "ج", "د"]

    /// Sun letters for lam shamsiyyah detection.
    static let sunLetters: Set<Character> = ["ت", "ث", "د", "ذ", "ر", "ز", "س", "ش", "ص", "ض", "ط", "ظ", "ل", "ن"]

    /// Alif-like followers used in madd/wasl heuristics.
    static let alifFollowerLetters: Set<Character> = ["ا", "ى"]

    /// Surahs whose first ayah opens with disconnected letters (حروف مقطعة).
    static let surahsOpeningMuqattaat: Set<Int> = [
        2, 3, 7, 10, 11, 12, 13, 14, 15, 19, 26, 27, 28, 29, 30, 31, 32,
        20, 36, 38, 40, 41, 42, 43, 44, 45, 46, 50, 68,
    ]

    /// Muqatta'at that form a complete opening ayah in Hafs. Ash-Shura is handled separately because
    /// its muqatta'at occupy the first two ayahs.
    static let completeAyahMuqattaatSurahs: Set<Int> = [
        2, 3, 7, 19, 20, 26, 28, 29, 30, 31, 32, 36, 40, 41, 43, 44, 45, 46,
    ]

    /// Muqatta'at that are only the first word of ayah 1; later words in that ayah use normal rules.
    static let firstWordOnlyMuqattaatSurahs: Set<Int> = [
        10, 11, 12, 13, 14, 15, 27, 38, 50, 68,
    ]

    /// Quranic pause / ornamental marks. These are reading symbols, not tajweed colors.
    static let waqfScalarSkipColorLower: UInt32 = 0x06D6
    static let waqfScalarSkipColorUpper: UInt32 = 0x06ED

    /// A few Uthmani marks in the same block must stay paintable because they are part of letters, not stop symbols.
    static let waqfScalarExceptions: Set<UInt32> = [0x06E1, 0x06E2, 0x06E5, 0x06E6, 0x06ED]

    /// Tree-driven annotations decoded from JSON, mapped to the public legend categories.
    static let treeDrivenRuleMap: [String: TajweedLegendCategory] = [
        "madd_2": .maddNatural,
        "madd_munfasil": .maddSeparated,
        "madd_muttasil": .maddConnected,
        "madd_6": .maddNecessary,
        "madd_246": .maddSukoon,
        "qalqalah": .qalqalah,
        "silent": .hamzatWaslSilent,
        "idghaam_ghunnah": .idghamGhunnah,
        "idghaam_shafawi": .idghamGhunnah,
        "idghaam_no_ghunnah": .idghamBilaGhunnah,
        "idghaam_mutajanisayn": .idghamGhunnah,
        "idghaam_mutaqaribayn": .idghamGhunnah,
        "ikhfa": .ikhfaaLight,
        "ikhfa_shafawi": .ikhfaaLight,
        "iqlaab": .iqlaab,
    ]

    /// Categories that require special tanween handling instead of a simple flat color fill.
    static let specialTanweenCategories: Set<TajweedLegendCategory> = [
        .idghamGhunnah,
        .generalGhunnah,
        .ikhfaaLight,
        .ikhfaaHeavy,
        .iqlaab,
        .idghamBilaGhunnah,
    ]

    /// Arabic combining marks treated as tashkeel for heuristic checks.
    static let tashkeelScalars: Set<UInt32> = [
        0x064B, 0x064C, 0x064D, 0x064E, 0x064F, 0x0650, 0x0651, 0x0652,
        0x0653, 0x0654, 0x0655, 0x0656, 0x0657, 0x0658, 0x0659, 0x065A,
        0x065B, 0x065C, 0x065D, 0x065E, 0x065F, 0x0670, 0x06E1, 0x06E5, 0x06E6, 0x06E7,
    ]

    /// The three special non-standard marks requested for next-letter heuristic handling.
    static let specialNextLetterTriggerScalars: Set<UInt32> = [0x0657, 0x065E, 0x0656]

    /// Noon/tanween idgham split requested by app behavior.
    static let noonTanweenTargetOnlyIdghamLetters: Set<Character> = ["ن"]
    static let noonTanweenSplitIdghamLetters: Set<Character> = ["م", "ي", "و"]
    static let noonTanweenSourceOnlyIdghamLetters: Set<Character> = ["ل", "ر"]

    /// Fathatayn is often followed by helper alif/alif maqsurah; skip these to find next governed letter.
    static let fathataynFollowerSkipLetters: Set<Character> = ["ا", "ى"]

    /// Noon/tanween ikhfaa split for app coloring.
    static let ikhfaaHeavyLetters: Set<Character> = ["ص", "ض", "ط", "ظ", "ق"]
    static let ikhfaaLightLetters: Set<Character> = ["ت", "ث", "ج", "د", "ذ", "ز", "س", "ش", "ف", "ك"]

    static func categoryForNoTashkeelNoonOrProxy(nextLetter: Character) -> TajweedLegendCategory? {
        if noonTanweenTargetOnlyIdghamLetters.contains(nextLetter) { return .idghamGhunnah }
        if noonTanweenSplitIdghamLetters.contains(nextLetter) { return .idghamBilaGhunnah }
        if noonTanweenSourceOnlyIdghamLetters.contains(nextLetter) { return .idghamBilaGhunnah }
        if ikhfaaHeavyLetters.contains(nextLetter) { return .ikhfaaHeavy }
        if ikhfaaLightLetters.contains(nextLetter) { return .ikhfaaLight }
        if nextLetter == "ب" { return .iqlaab }
        return nil
    }

    static func categoryForNoTashkeelMeem(nextLetter: Character) -> TajweedLegendCategory? {
        if nextLetter == "ب" { return .iqlaab }
        if nextLetter == "م" { return .idghamGhunnah }
        return nil
    }

    /// Stop-based categories are intentionally kept out of the painted Quran text for now.
    /// We can revisit waqf styling later without changing the underlying rule definitions.
    static let stopBasedCategories: Set<TajweedLegendCategory> = [.maddSukoon]

    static func shouldSkipWaqfColoring(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        guard value >= waqfScalarSkipColorLower, value <= waqfScalarSkipColorUpper else { return false }
        return !waqfScalarExceptions.contains(value)
    }

    static func shouldPaintCategory(_ category: TajweedLegendCategory) -> Bool {
        !stopBasedCategories.contains(category)
    }
}
