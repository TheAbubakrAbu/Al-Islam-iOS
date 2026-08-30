import SwiftUI
import UIKit
import Combine
#if canImport(AppKit)
import AppKit
#endif
import os

struct Surah: Codable, Identifiable, Equatable {
    let id: Int
    let idArabic: String

    let nameArabic: String
    let nameTransliteration: String
    let nameEnglish: String
    let similarNames: [String]

    let type: String
    let numberOfAyahs: Int

    let revelationOrder: Int?
    let revelationExceptions: String?

    let pageStart: Int?
    let pageEnd: Int?
    let numberOfPages: Int?
    let isLessThanOnePage: Bool?

    let firstJuz: Int?
    let lastJuz: Int?
    let juzs: [Int]?
    let juzChangesWithinSurah: Bool

    let wordCount: Int
    let letterCount: Int

    let ayahs: [Ayah]

    enum CodingKeys: String, CodingKey {
        case id, nameArabic, nameTransliteration, nameEnglish, similarNames, type, numberOfAyahs
        case revelationOrder, revelationExceptions
        case pageStart, pageEnd, numberOfPages, isLessThanOnePage
        case firstJuz, lastJuz, juzs, juzChangesWithinSurah
        case wordCount, letterCount
        case ayahs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(Int.self, forKey: .id)
        nameArabic = try c.decode(String.self, forKey: .nameArabic)
        nameTransliteration = try c.decode(String.self, forKey: .nameTransliteration)
        nameEnglish = try c.decode(String.self, forKey: .nameEnglish)
        similarNames = try c.decodeIfPresent([String].self, forKey: .similarNames) ?? []
        type = try c.decode(String.self, forKey: .type)
        numberOfAyahs = try c.decode(Int.self, forKey: .numberOfAyahs)

        revelationOrder = try c.decodeIfPresent(Int.self, forKey: .revelationOrder)
        revelationExceptions = try c.decodeIfPresent(String.self, forKey: .revelationExceptions)

        pageStart = try c.decodeIfPresent(Int.self, forKey: .pageStart)
        pageEnd = try c.decodeIfPresent(Int.self, forKey: .pageEnd)
        numberOfPages = try c.decodeIfPresent(Int.self, forKey: .numberOfPages)
        isLessThanOnePage = try c.decodeIfPresent(Bool.self, forKey: .isLessThanOnePage)

        firstJuz = try c.decodeIfPresent(Int.self, forKey: .firstJuz)
        lastJuz = try c.decodeIfPresent(Int.self, forKey: .lastJuz)
        juzs = try c.decodeIfPresent([Int].self, forKey: .juzs)
        juzChangesWithinSurah = try c.decodeIfPresent(Bool.self, forKey: .juzChangesWithinSurah)
            ?? ((juzs?.count ?? 0) > 1 || (firstJuz != nil && lastJuz != nil && firstJuz != lastJuz))

        let decodedAyahs = try c.decode([Ayah].self, forKey: .ayahs)
        ayahs = decodedAyahs
        wordCount = (try? c.decodeIfPresent(Int.self, forKey: .wordCount)) ?? decodedAyahs.reduce(0) { $0 + $1.wordCount }
        letterCount = (try? c.decodeIfPresent(Int.self, forKey: .letterCount)) ?? decodedAyahs.reduce(0) { $0 + $1.letterCount }

        idArabic = arabicNumberString(from: id)
    }

    init(
        id: Int,
        idArabic: String,
        nameArabic: String,
        nameTransliteration: String,
        nameEnglish: String,
        similarNames: [String] = [],
        type: String,
        numberOfAyahs: Int,
        revelationOrder: Int? = nil,
        revelationExceptions: String? = nil,
        pageStart: Int? = nil,
        pageEnd: Int? = nil,
        numberOfPages: Int? = nil,
        isLessThanOnePage: Bool? = nil,
        firstJuz: Int? = nil,
        lastJuz: Int? = nil,
        juzs: [Int]? = nil,
        juzChangesWithinSurah: Bool = false,
        ayahs: [Ayah]
    ) {
        self.id = id
        self.idArabic = idArabic
        self.nameArabic = nameArabic
        self.nameTransliteration = nameTransliteration
        self.nameEnglish = nameEnglish
        self.similarNames = similarNames
        self.type = type
        self.numberOfAyahs = numberOfAyahs
        self.revelationOrder = revelationOrder
        self.revelationExceptions = revelationExceptions

        self.pageStart = pageStart
        self.pageEnd = pageEnd
        self.numberOfPages = numberOfPages
        self.isLessThanOnePage = isLessThanOnePage

        self.firstJuz = firstJuz
        self.lastJuz = lastJuz
        self.juzs = juzs
        self.juzChangesWithinSurah = juzChangesWithinSurah

        self.ayahs = ayahs
        self.wordCount = ayahs.reduce(0) { $0 + $1.wordCount }
        self.letterCount = ayahs.reduce(0) { $0 + $1.letterCount }
    }

    var wordCountLabel: String { "\(wordCount) Words" }
    var letterCountLabel: String { "\(letterCount) Letters" }

    var pageCount: Int {
        if let n = numberOfPages, n > 0 { return n }
        if let start = pageStart, let end = pageEnd, end >= start {
            return (end - start) + 1
        }
        return 1
    }

    var pageChangesWithinSurah: Bool {
        pageCount > 1 || Set(ayahs.compactMap(\.page)).count > 1
    }

    var pageOrJuzChangesWithinSurah: Bool {
        pageChangesWithinSurah || juzChangesWithinSurah
    }

    var pageCountLabel: String {
        let count = max(pageCount, 1)
        if count == 1, isLessThanOnePage == true {
            #if os(iOS)
            return "<1 Page"
            #else
            return "<1 Pg"
            #endif
        }
        
        #if os(iOS)
        return count == 1 ? "1 Page" : "\(count) Pages"
        #else
        return count == 1 ? "1 Pg" : "\(count) Pgs"
        #endif
    }

    func ayahCountLabel(for displayQiraah: String? = nil) -> String {
        let count = displayQiraah == nil ? numberOfAyahs : numberOfAyahs(for: displayQiraah)
        return count == 1 ? "1 Ayah" : "\(count) Ayahs"
    }

    /// Ayah count for the given qiraah (e.g. Baqarah has 286 in Hafs but 285 in Warsh). Use for display and range selection.
    func numberOfAyahs(for displayQiraah: String?) -> Int {
        guard let qIn = displayQiraah, !qIn.isEmpty else { return numberOfAyahs }
        let q = Settings.normalizeLegacyRiwayahTag(qIn)
        guard !q.isEmpty, q != Settings.Riwayah.hafsTag, q != "Hafs" else { return numberOfAyahs }
        return ayahs.filter { $0.existsInQiraah(displayQiraah, surahID: id) }.count
    }
}

/// Thread-safe memoization for the diacritic-stripping in `Ayah.textCleanArabic`. The cleaned
/// result is a pure function of the raw Arabic text + the `removeArabicDots` flag, so the same
/// ayah rendered repeatedly (SwiftUI re-evaluations, scrolling) reuses the cached string instead
/// of re-running two O(n) Unicode passes each time. NSCache is thread-safe and self-evicting.
private enum CleanArabicTextCache {
    static let cache: NSCache<NSString, NSString> = {
        let c = NSCache<NSString, NSString>()
        c.countLimit = AppPerformance.cleanArabicCacheLimit
        return c
    }()
}

struct Ayah: Codable, Identifiable, Equatable {
    let id: Int
    let idArabic: String

    let textHafs: String
    let textTransliteration: String
    let textEnglishSaheeh: String
    let textEnglishMustafa: String

    let juz: Int?
    let page: Int?

    let textShubah: String?
    
    let textBuzzi: String?
    let textQunbul: String?
    
    let textWarsh: String?
    let textQaloon: String?

    let textDuri: String?
    let textSusi: String?

    let wordCount: Int
    let letterCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case textHafs = "textArabic"
        case textTransliteration, textEnglishSaheeh, textEnglishMustafa
        case juz, page
        case textWarsh, textQaloon, textDuri, textBuzzi, textQunbul, textShubah, textSusi
        case wordCount, letterCount
    }

    /// Raw Arabic for the given display qiraah. Nil = Hafs.
    ///
    /// `surahID` is only needed to reach the beta riwayat, whose text lives in a side
    /// table keyed by surah (see `BetaQiraatStore`) rather than in this struct. Callers
    /// that don't pass it still get every bundled riwayah.
    func textArabic(for displayQiraah: String?, surahID: Int? = nil) -> String {
        let raw: String? = {
            guard let qIn = displayQiraah else { return nil }
            let q = Settings.normalizeLegacyRiwayahTag(qIn)
            switch q {
            case Settings.Riwayah.warsh: return textWarsh
            case Settings.Riwayah.qaloon: return textQaloon
            case Settings.Riwayah.duri: return textDuri
            case Settings.Riwayah.buzzi: return textBuzzi
            case Settings.Riwayah.qunbul: return textQunbul
            case Settings.Riwayah.shubah: return textShubah
            case Settings.Riwayah.susi: return textSusi
            default:
                #if os(iOS)
                guard Settings.shared.betaQiraatEnabled, let surahID else { return nil }
                return BetaQiraatStore.shared.text(tag: q, surah: surahID, ayah: id)
                #else
                return nil
                #endif
            }
        }()
        return (raw ?? textHafs).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    /// Clean (no diacritics) Arabic for the given display qiraah.
    func textCleanArabic(for displayQiraah: String?, surahID: Int? = nil) -> String {
        // `surahID` matters for the 12 BETA riwayat: without it `textArabic` cannot reach the
        // BetaQiraatStore side-table and SILENTLY falls back to Hafs - the search-index-vs-display
        // desync bug (index said 3:65 matched, the reader showed the riwayah's own 3:65 = different
        // words). Every caller that has the surah must pass it.
        let raw = textArabic(for: displayQiraah, surahID: surahID)
        let removeDots = Settings.shared.removeArabicDots
        let key = ((removeDots ? "D1:" : "D0:") + raw) as NSString
        if let cached = CleanArabicTextCache.cache.object(forKey: key) {
            return cached as String
        }
        let base = raw.removingArabicDiacriticsAndSigns
        let result = removeDots ? base.removingArabicDots : base
        CleanArabicTextCache.cache.setObject(result as NSString, forKey: key)
        return result
    }

    /// True if this ayah exists as its own verse in the given qiraah. In Hafs every ayah exists; in Warsh/Qaloon/etc. some Hafs ayahs are merged, so we only show ayahs that have qiraah-specific text (e.g. Baqarah has 286 in Hafs but 285 in Warsh).
    func existsInQiraah(_ displayQiraah: String?, surahID: Int? = nil) -> Bool {
        guard let qIn = displayQiraah, !qIn.isEmpty, qIn != "Hafs" else {
            return !textHafs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let q = Settings.normalizeLegacyRiwayahTag(qIn)
        switch q {
        case Settings.Riwayah.hafsTag: return !textHafs.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case Settings.Riwayah.warsh: return textWarsh != nil
        case Settings.Riwayah.qaloon: return textQaloon != nil
        case Settings.Riwayah.duri: return textDuri != nil
        case Settings.Riwayah.buzzi: return textBuzzi != nil
        case Settings.Riwayah.qunbul: return textQunbul != nil
        case Settings.Riwayah.shubah: return textShubah != nil
        case Settings.Riwayah.susi: return textSusi != nil
        default:
            #if os(iOS)
            // Beta riwayat merge/split ayahs like the bundled ones do; without a surah
            // to look in, assume it exists (callers that have one get the real answer).
            guard Settings.shared.betaQiraatEnabled, Settings.Riwayah.isBeta(q) else { return true }
            guard let surahID else { return true }
            return BetaQiraatStore.shared.text(tag: q, surah: surahID, ayah: id) != nil
            #else
            return true
            #endif
        }
    }

    /// Current riwayah's Arabic (uses Settings.displayQiraahForArabic). Used for display, search, share.
    var textArabic: String { textArabic(for: Settings.shared.displayQiraahForArabic) }
    var textCleanArabic: String { textCleanArabic(for: Settings.shared.displayQiraahForArabic) }

    /// Clean Bismillah (no diacritics). Shown for Fatiha 1 when the riwayah’s first ayah is ta'awwudh.
    static let bismillahCleanArabic = "بسم الله الرحمن الرحيم"

    /// Arabic to show in UI. For Fatiha ayah 1 with clean mode, if the ayah doesn’t start with بسم (e.g. ta'awwudh), shows Bismillah instead.
    /// - Parameter qiraahOverride: When non-nil, use this qiraah instead of Settings (e.g. comparison mode). Use "" for Hafs.
    func displayArabicText(surahId: Int, clean: Bool, qiraahOverride: String? = nil) -> String {
        let qiraah: String? = if let override = qiraahOverride {
            (override.isEmpty || override == "Hafs") ? nil : override
        } else {
            Settings.shared.displayQiraahForArabic
        }
        // Clean/no-dots applies to EVERY riwayah, not just Hafs: the transforms are pure string
        // maps (all 20 texts ship fully vocalized; the skeleton is derived at render time), and
        // stripping tashkeel + signs is exactly what exposes the shared Uthmani rasm across qiraat.
        let text = if qiraah == nil {
            clean ? textCleanArabic(for: qiraah) : textArabic(for: qiraah, surahID: surahId)
        } else if clean {
            textCleanArabic(for: qiraah, surahID: surahId)
        } else {
            textArabic(for: qiraah, surahID: surahId).removingArabicSukoon
        }
        if surahId == 1 && id == 1 && clean {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.hasPrefix("بسم") {
                return Self.bismillahCleanArabic
            }
        }
        return text
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        textHafs = try c.decode(String.self, forKey: .textHafs)
        textTransliteration = try c.decode(String.self, forKey: .textTransliteration)
        textEnglishSaheeh = try c.decode(String.self, forKey: .textEnglishSaheeh)
        textEnglishMustafa = try c.decode(String.self, forKey: .textEnglishMustafa)
        juz = try c.decodeIfPresent(Int.self, forKey: .juz)
        page = try c.decodeIfPresent(Int.self, forKey: .page)
        textWarsh = try c.decodeIfPresent(String.self, forKey: .textWarsh)
        textQaloon = try c.decodeIfPresent(String.self, forKey: .textQaloon)
        textDuri = try c.decodeIfPresent(String.self, forKey: .textDuri)
        textBuzzi = try c.decodeIfPresent(String.self, forKey: .textBuzzi)
        textQunbul = try c.decodeIfPresent(String.self, forKey: .textQunbul)
        textShubah = try c.decodeIfPresent(String.self, forKey: .textShubah)
        textSusi = try c.decodeIfPresent(String.self, forKey: .textSusi)
        idArabic = arabicNumberString(from: id)
        wordCount = (try? c.decodeIfPresent(Int.self, forKey: .wordCount)) ?? textHafs.split(separator: " ").filter { !$0.isEmpty }.count
        letterCount = (try? c.decodeIfPresent(Int.self, forKey: .letterCount)) ?? textHafs.unicodeScalars.filter {
            ($0.value >= 0x0621 && $0.value <= 0x063A) || ($0.value >= 0x0641 && $0.value <= 0x064A) || $0.value == 0x0671
        }.count
    }

    init(id: Int, idArabic: String, textHafs: String, textTransliteration: String, textEnglishSaheeh: String, textEnglishMustafa: String, juz: Int? = nil, page: Int? = nil, textWarsh: String?, textQaloon: String?, textDuri: String?, textBuzzi: String?, textQunbul: String?, textShubah: String?, textSusi: String?) {
        self.id = id
        self.idArabic = idArabic
        self.textHafs = textHafs
        self.textTransliteration = textTransliteration
        self.textEnglishSaheeh = textEnglishSaheeh
        self.textEnglishMustafa = textEnglishMustafa
        self.juz = juz
        self.page = page
        self.textWarsh = textWarsh
        self.textQaloon = textQaloon
        self.textDuri = textDuri
        self.textBuzzi = textBuzzi
        self.textQunbul = textQunbul
        self.textShubah = textShubah
        self.textSusi = textSusi
        self.wordCount = textHafs.split(separator: " ").filter { !$0.isEmpty }.count
        self.letterCount = textHafs.unicodeScalars.filter {
            ($0.value >= 0x0621 && $0.value <= 0x063A) || ($0.value >= 0x0641 && $0.value <= 0x064A) || $0.value == 0x0671
        }.count
    }

    // (A `displayArabic(qiraah:clean:)` convenience used to live here. Deleted: it had no callers,
    // and with no `surahID` it could never serve beta-riwayat text - the silent-Hafs-fallback trap.
    // Use `displayArabicText(surahId:clean:qiraahOverride:)`.)
}

final class TajweedStore {
    static let shared = TajweedStore()
    private static let fatha = UnicodeScalar(0x064E)!
    private static let damma = UnicodeScalar(0x064F)!
    private static let fathatayn = UnicodeScalar(0x064B)!
    private static let dammatayn = UnicodeScalar(0x064C)!
    private static let kasra = UnicodeScalar(0x0650)!
    private static let kasratayn = UnicodeScalar(0x064D)!
    private static let specialFathatayn = UnicodeScalar(0x0657)!
    private static let specialDammatayn = UnicodeScalar(0x065E)!
    private static let specialKasratayn = UnicodeScalar(0x0656)!
    private static let sukoon = UnicodeScalar(0x0652)!
    private static let sukoonUthmani = UnicodeScalar(0x06E1)!
    private static let shadda = UnicodeScalar(0x0651)!
    private static let bareHamza = UnicodeScalar(0x0621)!
    private static let daggerAlif = UnicodeScalar(0x0670)!
    private static let hamzaAbove = UnicodeScalar(0x0654)!
    private static let hamzaBelow = UnicodeScalar(0x0655)!
    private static let maddah = UnicodeScalar(0x0653)!
    private static let hamzatWasl = UnicodeScalar(0x0671)!
    private static let highHamza = UnicodeScalar(0x0674)!
    private static let smallHighUprightRectangularZero = UnicodeScalar(0x06E0)!
    private static let smallWaw = UnicodeScalar(0x06E5)!
    private static let smallYeh = UnicodeScalar(0x06E6)!
    /// Small high yeh (ۧ), e.g. ٱلنَّبِيِّـۧنَ - another miniature natural-madd mark, treated like smallYeh.
    private static let smallHighYeh = UnicodeScalar(0x06E7)!
    private static let smallHighMeem = UnicodeScalar(0x06E2)!
    private static let smallLowMeem = UnicodeScalar(0x06ED)!

    /// Words from `madd_muttasil_analysis.json` `proper_words`. Each is written with a superscript madd
    /// letter (dagger-alif ٰ / small-waw ۥ / small-yeh ۦ) carrying a maddah and immediately followed by a
    /// hamzah inside the same written word - which normally reads as madd muttaṣil - but here that specific
    /// sequence is recited as madd munfaṣil ḥukmī (a يا/ها particle joined to a following hamzah). Only that
    /// superscript-carrier sequence is reclassified; any genuine madd muttaṣil elsewhere in the same word
    /// (e.g. لَآءِ in هَٰٓؤُلَآءِ, a real alif) is left untouched. Stored NFC-normalized so the exact-word
    /// match is independent of combining-mark order.
    static let hukmiMunfasilProperWords: Set<String> = Set([
        "يَٰٓأَيُّهَا", "هَٰٓؤُلَآءِ", "يَٰٓأَهۡلَ", "يَٰٓأَبَتِ", "يَٰٓأُوْلِي",
        "يَٰٓـَٔادَمُ", "هَٰٓأَنتُمۡ", "أَهَٰٓؤُلَآءِ", "يَٰٓأَبَانَا", "هَٰٓؤُلَآءِۚ",
        "يَٰٓإِبۡرَٰهِيمُ", "يَٰٓأَبَانَآ", "يَٰٓإِبۡلِيسُ", "وَيَٰٓـَٔادَمُ", "يَٰٓأَرۡضُ",
        "يَٰٓأَسَفَىٰ", "وَهَٰٓؤُلَآءِ", "يَٰٓأُخۡتَ", "يَٰٓإِبۡرَٰهِيمُۖ", "يَٰٓأَيُّهَ",
        "يَٰٓأَيَّتُهَا",
    ].map { $0.precomposedStringWithCanonicalMapping })

    /// Higher value wins when painting overlapping UTF-16 units.
    private enum PaintPriority {
        static let tafkhim = 1
        static let droppedLetter = 2
        static let lamShamsiyah = 3
        static let qalqalah = 4
        static let idghamBiGhunnahLight = 5
        static let idghamBiGhunnahHeavy = 6
        static let ikhfaa = 7
        static let iqlaab = 8
        static let idghamBilaGhunnah = 9
        static let generalGhunnah = 10
        static let finalRaaTafkhim = 52
        static let tinyMeemIqlaab = 51
        static let maddNatural2 = 12
        /// Miniature madd scalars (U+06E5, U+06E6, U+0670) use same category as natural madd; slightly higher priority than letter-body natural madd.
        static let maddNatural2MiniatureScalars = 13
        static let maddAaridLisSukoon = 17
        static let maddNecessary6 = 18
        static let maddSeparated = 19
        static let maddConnected = 20
        static let explicitMaddConnected = 21
        static let explicitMaddSeparated = 22
        static let explicitMaddNecessary = 23
        static let hamzatWaslSilent = 50
    }

    /// Boxes the `AttributedString` value so it can live in an `NSCache` (which requires class types).
    private final class AttributedStringBox {
        let value: AttributedString
        init(_ value: AttributedString) { self.value = value }
    }

    private struct TajweedAyahKey: Hashable {
        let surah: Int
        let ayah: Int
    }

    private struct TajweedRuleAnnotation: Decodable {
        let start: Int
        let end: Int
        let rule: String
    }

    private struct TajweedRuleAyah: Decodable {
        let surah: Int
        let ayah: Int
        let annotations: [TajweedRuleAnnotation]
    }


    /// Forces the lazy rule-tree decode (a multi-MB JSON read) to happen on the caller's thread - the
    /// background Quran load calls this so the first tajweed-colored ayah doesn't hitch the main thread
    /// with it. Safe from any thread: `static let` initialization is once-only and thread-safe.
    static func prewarmRuleTrees() {
        _ = tajweedRuleTreesByAyah.isEmpty
    }

    private static let tajweedRuleTreesByAyah: [TajweedAyahKey: [TajweedRuleAnnotation]] = {
        guard let url = tajweedRulesResourceURL() else { return [:] }
        guard let data = try? Data(contentsOf: url) else { return [:] }
        guard let decoded = try? JSONDecoder().decode([TajweedRuleAyah].self, from: data) else { return [:] }
        var out: [TajweedAyahKey: [TajweedRuleAnnotation]] = [:]
        out.reserveCapacity(decoded.count)
        for item in decoded {
            out[TajweedAyahKey(surah: item.surah, ayah: item.ayah)] = item.annotations
        }
        return out
    }()

    private static func tajweedRulesResourceURL() -> URL? {
        let bundle = Bundle.main
        if let nested = bundle.url(forResource: "TajweedRules", withExtension: "json", subdirectory: "JSONs") {
            return nested
        }
        return bundle.url(forResource: "TajweedRules", withExtension: "json")
    }

    /// Self-evicting (and thread-safe) tajweed attributed-string cache. Replaces a plain dict whose only
    /// eviction was a full `removeAll` once it crossed the limit - a cliff that wiped the entire cache
    /// mid-scroll on long surahs (Baqarah), forcing the expensive projection+painting to re-run. `NSCache`
    /// drops just the coldest entries at `countLimit` and also evicts automatically under memory pressure.
    /// The final per-ayah paint ops, cached under the SAME key as the styled string. They carry
    /// the rule categories, which is what the word-meaning card's "rules in this word" list reads -
    /// the colors alone couldn't say WHICH rule painted a letter.
    private final class PaintOpsBox {
        let ops: [PaintOp]
        init(_ ops: [PaintOp]) { self.ops = ops }
    }
    private let opsCache: NSCache<NSString, PaintOpsBox> = {
        let c = NSCache<NSString, PaintOpsBox>()
        c.countLimit = 128
        return c
    }()

    private let attributedCache: NSCache<NSString, AttributedStringBox> = {
        let c = NSCache<NSString, AttributedStringBox>()
        c.countLimit = AppPerformance.tajweedAttributedCacheLimit
        return c
    }()
    private var lastVisibilitySignature = ""
    /// Guards `lastVisibilitySignature`'s check-and-clear. Most callers are main-thread renders, but the
    /// share-image queue also calls `attributedText` - the NSCache is already thread-safe; this string was
    /// the one unsynchronized piece of shared state.
    private let visibilityLock = NSLock()
    private let settings = Settings.shared


    private struct PaintOp {
        let range: NSRange
        let priority: Int
        let category: TajweedLegendCategory
        let color: Color?

        init(range: NSRange, priority: Int, category: TajweedLegendCategory, color: Color? = nil) {
            self.range = range
            self.priority = priority
            self.category = category
            self.color = color
        }
    }

    private static let bareTashkeelScalars: Set<UInt32> = [
        0x064B, 0x064C, 0x064D, 0x064E, 0x064F, 0x0650,
        0x0651, 0x0652, 0x0653, 0x0656, 0x0657, 0x0670,
        0x06E1, 0x06E5, 0x06E6
    ]

    private init() {}

    /// Stable fingerprint so cache invalidates when verse text changes (qiraah, data updates).
    private static func stableTextDigest(_ string: String) -> UInt64 {
        var hash: UInt64 = 1469598103934665603
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1099511628211
        }
        return hash
    }

    func attributedText(
        surah: Int,
        ayah: Int,
        text: String,
        displayText requestedDisplayText: String? = nil,
        cleanDisplayText: Bool = false,
        beginnerSpacing: Bool = false,
        removeArabicDots: Bool? = nil
    ) -> AttributedString? {
        let visibilitySignature = tajweedVisibilitySignature()
        visibilityLock.lock()
        if visibilitySignature != lastVisibilitySignature {
            attributedCache.removeAllObjects()
            opsCache.removeAllObjects()
            lastVisibilitySignature = visibilitySignature
        }
        visibilityLock.unlock()

        let shouldRemoveArabicDots = removeArabicDots ?? (cleanDisplayText && settings.removeArabicDots)

        // Key the cache on the INPUTS, not on the projected `displayText`. `displayText` is a pure function of
        // (text, requestedDisplayText, cleanDisplayText, beginnerSpacing, shouldRemoveArabicDots), so keying on
        // those is equivalent - but it lets a cache HIT skip `tajweedProjection` (a full per-scalar pass)
        // entirely. Previously the projection ran on every call just to build the key, even on hits, which is
        // the per-scroll-render cost. (surah/ayah are in the key because they change the painting, not the text.)
        let requestedDisplayDigest = requestedDisplayText.map(Self.stableTextDigest) ?? 0
        let cacheKey = "\(surah):\(ayah):\(Self.stableTextDigest(text)):\(requestedDisplayDigest):\(cleanDisplayText ? 1 : 0):\(beginnerSpacing ? 1 : 0):\(shouldRemoveArabicDots ? 1 : 0)" as NSString
        if let cached = attributedCache.object(forKey: cacheKey) {
            return cached.value
        }

        // Cache miss - only now run the expensive projection + painting.
        let projection = (requestedDisplayText != nil || cleanDisplayText || beginnerSpacing || shouldRemoveArabicDots)
            ? tajweedProjection(
                from: text,
                requestedDisplayText: requestedDisplayText,
                cleanDisplayText: cleanDisplayText,
                beginnerSpacing: beginnerSpacing,
                removeArabicDots: shouldRemoveArabicDots
            )
            : nil
        let displayText = projection?.displayText ?? text

        guard !text.isEmpty else { return nil }
        guard TajweedLegendCategory.allCases.contains(where: { settings.isTajweedCategoryVisible($0) }) else {
            return nil
        }

        // Use NSAttributedString for UTF-16 painting. Per-code-unit Swift `Range(NSRange,in: String)` often
        // fails inside Arabic grapheme clusters, so `AttributedString.Index(..., within:)` skipped all colors.
        let attributed = NSMutableAttributedString(string: displayText)
        let fullRange = NSRange(location: 0, length: attributed.length)
        attributed.addAttribute(.foregroundColor, value: platformLabelColor(), range: fullRange)

        let utf16Count = attributed.length
        let rawUTF16Count = text.utf16.count
        var priorityPerUTF16 = [Int](repeating: 0, count: utf16Count)

        var ops: [PaintOp] = []
        let clusters = characterClusters(in: text)
        let muqattaatProtectedIndices = muqattaatProtectedClusterIndices(surah: surah, ayah: ayah, clusters: clusters)

        if settings.isTajweedCategoryVisible(.tafkhim) {
            for index in clusters.indices where shouldUseHeavyColor(clusters: clusters, index: index) {
                // Allah heavy-lam special case intentionally disabled for now.
                // if clusters[index].primaryArabicLetter == "ل",
                //    isFirstLamOfAllahWord(clusters: clusters, index: index),
                //    let secondLamRange = secondLamScalarRange(in: clusters[index]) {
                //     ops.append(PaintOp(range: secondLamRange, priority: PaintPriority.tafkhim, category: .tafkhim))
                // } else {
                    appendTafkhimPaintOps(clusters: clusters, index: index, into: &ops)
                // }
            }
        }

        if settings.isTajweedCategoryVisible(.droppedLetter) {
            for index in clusters.indices where hasStandardSukoon(clusters[index]) {
                let cluster = clusters[index]
                guard let base = cluster.primaryArabicLetter, isArabicLetterBase(base) else { continue }
                if TajweedRules.qalqalahLetters.contains(base), settings.isTajweedCategoryVisible(.qalqalah) {
                    continue
                }
                if shouldUseHeavyColor(clusters: clusters, index: index) {
                    continue
                }
                ops.append(PaintOp(range: nsRange(for: cluster), priority: PaintPriority.droppedLetter, category: .droppedLetter))
            }
        }

        if settings.isTajweedCategoryVisible(.lamShamsiyah) {
            for index in clusters.indices where isLamShamsiyah(clusters: clusters, index: index) {
                ops.append(PaintOp(range: nsRange(for: clusters[index]), priority: PaintPriority.lamShamsiyah, category: .lamShamsiyah))
            }
        }

        if settings.isTajweedCategoryVisible(.qalqalah) {
            let verseFinalQalqalahIndex = indexOfVerseFinalQalqalahCluster(clusters: clusters)
            for idx in clusters.indices {
                let cluster = clusters[idx]
                guard let base = cluster.primaryArabicLetter, TajweedRules.qalqalahLetters.contains(base) else { continue }
                // If the qalqalah letter itself carries maddah, treat it as madd-driven instead of qalqalah.
                guard !hasMaddah(cluster) else { continue }
                let uthmaniHere = hasUthmaniSukoon(cluster)
                let splitUthmani = !uthmaniHere && idx + 1 < clusters.count
                    && clusterIsOnlyUthmaniSukoonMark(clusters[idx + 1])
                if uthmaniHere || hasStandardSukoon(cluster) {
                    // Letter + the specific diacritic scalar only (no NSUnionRange).
                    appendQalqalahClusterPaintOps(clusters: clusters, index: idx, priority: PaintPriority.qalqalah, into: &ops)
                    continue
                }
                if splitUthmani {
                    // Sukoon is in the next cluster - emit letter here, sukoon scalar there.
                    let letterRange = primaryArabicLetterScalarRange(in: cluster) ?? nsRange(for: cluster)
                    ops.append(PaintOp(range: letterRange, priority: PaintPriority.qalqalah, category: .qalqalah))
                    if let sRange = scalarRange(in: clusters[idx + 1], scalar: Self.sukoonUthmani) {
                        ops.append(PaintOp(range: sRange, priority: PaintPriority.qalqalah, category: .qalqalah))
                    }
                    continue
                }
                guard verseFinalQalqalahIndex == idx else { continue }
                // Verse-final: letter only.
                let letterRange = primaryArabicLetterScalarRange(in: cluster) ?? nsRange(for: cluster)
                ops.append(PaintOp(range: letterRange, priority: PaintPriority.qalqalah, category: .qalqalah))
            }
        }

        let _ = wordClusterRanges(clusters: clusters)

        appendTreeDrivenPaintOps(surah: surah, ayah: ayah, text: text, utf16Count: rawUTF16Count, into: &ops)
        appendNuunMeemGhunnahHeuristicPaintOps(text: text, into: &ops)

        collectMaddAndWaslPaintOps(surah: surah, ayah: ayah, text: text, clusters: clusters, into: &ops)
        appendBareConsonantSilentPaintOps(clusters: clusters, muqattaatProtectedIndices: muqattaatProtectedIndices, into: &ops)
        appendMuqattaatBareRaaTafkhimPaintOps(clusters: clusters, protectedIndices: muqattaatProtectedIndices, into: &ops)
        appendMuqattaatMaddLazimPaintOps(clusters: clusters, protectedIndices: muqattaatProtectedIndices, into: &ops)
        ops = filteredMuqattaatPaintOps(ops, clusters: clusters, protectedIndices: muqattaatProtectedIndices)
        opsCache.setObject(PaintOpsBox(ops), forKey: cacheKey)

        let rawWaqfUTF16Skip = Self.utf16IndicesOfWaqfOrnaments(in: text)
        let waqfUTF16Skip = Self.utf16IndicesOfWaqfOrnaments(in: displayText)
        let orderedOps = ops.enumerated().sorted {
            if $0.element.priority == $1.element.priority { return $0.offset < $1.offset }
            return $0.element.priority < $1.element.priority
        }
        for (_, op) in orderedOps {
            let targetIndices = projectedPaintIndices(for: op.range, projection: projection, rawWaqfUTF16Skip: rawWaqfUTF16Skip)
            for i in targetIndices {
                guard i >= 0, i < utf16Count else { continue }
                if waqfUTF16Skip.contains(i) { continue }
                guard op.priority >= priorityPerUTF16[i] else { continue }
                priorityPerUTF16[i] = op.priority
                attributed.addAttribute(
                    .foregroundColor,
                    value: platformTajweedColor(op.color ?? op.category.color),
                    range: NSRange(location: i, length: 1)
                )
            }
        }

        let anyPainted = priorityPerUTF16.contains { $0 > 0 }
        guard anyPainted else { return nil }

        let result = AttributedString(attributed)
        attributedCache.setObject(AttributedStringBox(result), forKey: cacheKey)
        return result
    }

    /// The visible tajweed rules whose painted range touches `wordRange` of the RAW ayah text,
    /// in legend order. Runs the same pipeline as `attributedText` (and warms the same caches),
    /// so the list always agrees with the colors on screen. Empty when tajweed can't paint here.
    func ruleCategories(surah: Int, ayah: Int, text: String, wordRange: NSRange) -> [TajweedLegendCategory] {
        let cacheKey = "\(surah):\(ayah):\(Self.stableTextDigest(text)):0:0:0:0" as NSString
        if opsCache.object(forKey: cacheKey) == nil {
            _ = attributedText(surah: surah, ayah: ayah, text: text)
        }
        guard let box = opsCache.object(forKey: cacheKey) else { return [] }

        // Only the rule that actually WINS a character is listed - resolved exactly the way
        // `attributedText` paints (ascending priority, later op wins a tie), so a letter two rules
        // both claim (the bare wasl alef of ٱللَّهِ, which the dropped-letter pass also marks before
        // the wasl rule outpaints it) reports only the color the reader sees.
        guard wordRange.location >= 0, wordRange.length > 0 else { return [] }
        var winner = [(priority: Int, category: TajweedLegendCategory)?](repeating: nil, count: wordRange.length)
        let ordered = box.ops.enumerated().sorted {
            if $0.element.priority == $1.element.priority { return $0.offset < $1.offset }
            return $0.element.priority < $1.element.priority
        }
        for (_, op) in ordered {
            let hit = NSIntersectionRange(op.range, wordRange)
            guard hit.length > 0 else { continue }
            for i in hit.location ..< hit.location + hit.length {
                let slot = i - wordRange.location
                if let current = winner[slot], op.priority < current.priority { continue }
                winner[slot] = (op.priority, op.category)
            }
        }
        let present = Set(winner.compactMap { $0?.category })
        return TajweedLegendCategory.allCases.filter { present.contains($0) }
    }

    private struct TajweedProjection {
        let displayText: String
        let rawUTF16ToDisplayRange: [Range<Int>?]
        let fallbackDisplayRangeByRawUTF16: [NSRange?]
    }

    private func tajweedProjection(
        from rawText: String,
        requestedDisplayText: String?,
        cleanDisplayText: Bool,
        beginnerSpacing: Bool,
        removeArabicDots: Bool
    ) -> TajweedProjection {
        var projectedScalars = String.UnicodeScalarView()
        projectedScalars.reserveCapacity(rawText.unicodeScalars.count * (beginnerSpacing ? 2 : 1))

        let rawUTF16Count = rawText.utf16.count
        var rawUTF16ToDisplayRange = [Range<Int>?](repeating: nil, count: rawUTF16Count)
        var fallbackDisplayRangeByRawUTF16 = [NSRange?](repeating: nil, count: rawUTF16Count)

        var rawUTF16Offset = 0
        var displayUTF16Offset = 0
        // Beginner spacing goes BETWEEN emitting clusters, never after the last one - every caller
        // builds its display text with `joined(separator: " ")`, and the projection must come out
        // byte-identical to it or every consumer that aligns the two by offset (the mushaf page's
        // justification transplant, word-by-word's equality check) drifts by the stray trailing space.
        var pendingBeginnerSpacer = false

        for character in rawText {
            let clusterRawStart = rawUTF16Offset
            let clusterDisplayStart = displayUTF16Offset
            var primaryRange: NSRange?
            var emittedVisibleClusterContent = false

            for scalar in String(character).unicodeScalars {
                let rawLength = utf16Length(of: scalar)
                let outScalars = displayScalars(for: scalar, cleanDisplayText: cleanDisplayText, removeArabicDots: removeArabicDots)
                if pendingBeginnerSpacer, !outScalars.isEmpty {
                    projectedScalars.append(" ")
                    displayUTF16Offset += 1
                    pendingBeginnerSpacer = false
                }
                let outStart = displayUTF16Offset

                for outScalar in outScalars {
                    projectedScalars.append(outScalar)
                    displayUTF16Offset += utf16Length(of: outScalar)
                }

                if displayUTF16Offset > outStart {
                    emittedVisibleClusterContent = true
                    let displayRange = outStart..<displayUTF16Offset
                    for rawUnit in rawUTF16Offset..<(rawUTF16Offset + rawLength) where rawUnit < rawUTF16ToDisplayRange.count {
                        rawUTF16ToDisplayRange[rawUnit] = displayRange
                    }
                    if primaryRange == nil, isArabicLetterScalar(scalar) {
                        primaryRange = NSRange(location: outStart, length: displayUTF16Offset - outStart)
                    }
                }

                rawUTF16Offset += rawLength
            }

            if beginnerSpacing, emittedVisibleClusterContent {
                pendingBeginnerSpacer = true
            }

            let fallback: NSRange?
            if let primaryRange {
                fallback = primaryRange
            } else if displayUTF16Offset > clusterDisplayStart {
                fallback = NSRange(location: clusterDisplayStart, length: displayUTF16Offset - clusterDisplayStart)
            } else {
                fallback = nil
            }

            for rawUnit in clusterRawStart..<rawUTF16Offset where rawUnit < fallbackDisplayRangeByRawUTF16.count {
                fallbackDisplayRangeByRawUTF16[rawUnit] = fallback
            }
        }

        let projectedText = String(projectedScalars)
        return TajweedProjection(
            displayText: projectedText == requestedDisplayText ? (requestedDisplayText ?? projectedText) : projectedText,
            rawUTF16ToDisplayRange: rawUTF16ToDisplayRange,
            fallbackDisplayRangeByRawUTF16: fallbackDisplayRangeByRawUTF16
        )
    }

    private func projectedPaintIndices(
        for rawRange: NSRange,
        projection: TajweedProjection?,
        rawWaqfUTF16Skip: Set<Int>
    ) -> [Int] {
        guard let projection else {
            let lo = rawRange.location
            let hi = rawRange.location + rawRange.length
            guard hi >= lo else { return [] }
            return Array(lo..<hi)
        }

        var indices = Set<Int>()
        let lo = max(0, rawRange.location)
        let hi = min(projection.rawUTF16ToDisplayRange.count, rawRange.location + rawRange.length)
        guard hi > lo else { return [] }

        for rawIndex in lo..<hi where !rawWaqfUTF16Skip.contains(rawIndex) {
            if let displayRange = projection.rawUTF16ToDisplayRange[rawIndex] {
                for displayIndex in displayRange { indices.insert(displayIndex) }
            }
        }

        if indices.isEmpty {
            for rawIndex in lo..<hi where !rawWaqfUTF16Skip.contains(rawIndex) {
                guard let fallback = projection.fallbackDisplayRangeByRawUTF16[rawIndex] else { continue }
                let end = fallback.location + fallback.length
                for displayIndex in fallback.location..<end { indices.insert(displayIndex) }
            }
        }

        return indices.sorted()
    }

    private func displayScalars(for scalar: UnicodeScalar, cleanDisplayText: Bool, removeArabicDots: Bool) -> [UnicodeScalar] {
        let visibleScalar: UnicodeScalar?
        if cleanDisplayText {
            switch scalar.value {
            case 0x0671:
                visibleScalar = UnicodeScalar(0x0627)!
            default:
                visibleScalar = shouldStripForCleanArabic(scalar) ? nil : scalar
            }
        } else {
            visibleScalar = scalar
        }

        guard var out = visibleScalar else { return [] }
        if cleanDisplayText && removeArabicDots {
            out = dotlessArabicScalar(out)
        }
        return [out]
    }

    private func shouldStripForCleanArabic(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x064B...0x065F:
            return true
        case 0x06D6...0x06ED:
            return true
        case 0x0670, 0x0674:
            return true
        default:
            return false
        }
    }

    private func isArabicLetterScalar(_ scalar: UnicodeScalar) -> Bool {
        let v = scalar.value
        return (0x0621...0x063A).contains(v) || (0x0641...0x064A).contains(v) || v == 0x0671
    }

    private func dotlessArabicScalar(_ scalar: UnicodeScalar) -> UnicodeScalar {
        switch scalar.value {
        case 0x0623, 0x0625: return UnicodeScalar(0x0627)!
        case 0x0624, 0x0626: return UnicodeScalar(0x0621)!
        case 0x0622: return UnicodeScalar(0x0627)!
        case 0x0671: return UnicodeScalar(0x0627)!
        case 0x0628, 0x062A, 0x062B: return UnicodeScalar(0x066E)!
        // Noon keeps its own skeleton (U+06BA: bowl in isolated/final, tooth elsewhere), matching
        // the early-manuscript rasm - see `removingArabicDots` in Globals.swift, its string twin.
        case 0x0646: return UnicodeScalar(0x06BA)!
        case 0x064A: return UnicodeScalar(0x0649)!
        case 0x062C, 0x062E: return UnicodeScalar(0x062D)!
        case 0x0630: return UnicodeScalar(0x062F)!
        case 0x0632: return UnicodeScalar(0x0631)!
        case 0x0634: return UnicodeScalar(0x0633)!
        case 0x0636: return UnicodeScalar(0x0635)!
        case 0x0638: return UnicodeScalar(0x0637)!
        case 0x063A: return UnicodeScalar(0x0639)!
        case 0x0641: return UnicodeScalar(0x06A1)!
        case 0x0642: return UnicodeScalar(0x066F)!
        case 0x0629: return UnicodeScalar(0x0647)!
        default: return scalar
        }
    }

    private func platformLabelColor() -> AnyObject {
        #if canImport(UIKit)
        #if os(watchOS)
        return UIColor(Color.primary)
        #else
        return UIColor.label
        #endif
        #elseif canImport(AppKit)
        return NSColor.labelColor
        #else
        return Color.primary as AnyObject
        #endif
    }

    private func platformTajweedColor(_ color: Color) -> AnyObject {
        #if canImport(UIKit)
        return UIColor(color)
        #elseif canImport(AppKit)
        return NSColor(color)
        #else
        return color as AnyObject
        #endif
    }

    private static func utf16IndicesOfWaqfOrnaments(in text: String) -> Set<Int> {
        var out = Set<Int>()
        var offset = 0
        for ch in text {
            let s = String(ch)
            var scalarOffset = offset
            for sc in s.unicodeScalars {
                let hit = TajweedRules.shouldSkipWaqfColoring(sc)
                if hit {
                    let len = sc.utf16.count
                    for j in 0..<len { out.insert(scalarOffset + j) }
                }
                scalarOffset += sc.utf16.count
            }
            offset += s.utf16.count
        }
        return out
    }

    private func collectMaddAndWaslPaintOps(surah: Int, ayah: Int, text: String, clusters: [CharacterClusterInfo], into ops: inout [PaintOp]) {
        let words = wordClusterRanges(clusters: clusters)
        let finalAaridCarrier = finalWordMaddAaridCarrierIndex(words: words, clusters: clusters)

        // A lone madd letter at the very end of the last word of the ayah (e.g. the final آ in أَقۡفَالُهَآ)
        // is read as a natural 2-count madd at waqf, not madd lazim. Don't highlight it - except in the
        // muqatta'at openings, where a final maddah letter genuinely is madd lazim (e.g. صٓ, نٓ).
        let muqattaatOpening = TajweedRules.surahsOpeningMuqattaat.contains(surah)
            && (ayah == 1 || (surah == 42 && ayah == 2))
        let ayahFinalMaddNaturalIndex: Int? = muqattaatOpening
            ? nil
            : indexOfFinalPronouncedArabicLetterCluster(clusters: clusters)

        if settings.isTajweedCategoryVisible(.maddNaturalMiniature) {
            appendScalarPaintOps(
                text: text,
                scalars: [Self.smallWaw.value, Self.smallYeh.value, Self.daggerAlif.value],
                priority: PaintPriority.maddNatural2MiniatureScalars,
                category: .maddNaturalMiniature,
                into: &ops
            )

            // Small high yeh (ۧ) sits on a tatweel (e.g. ـۧ in ٱلنَّبِيِّـۧنَ) and the font won't paint a
            // foreground color onto the bare mark, so color the whole carrier cluster instead - the same
            // "color the whole letter" approach used for the tiny iqlaab meem - so it's actually visible.
            for cluster in clusters where clusterHasSmallHighYehMaddMark(cluster) {
                for range in smallHighYehMaddPaintRanges(in: cluster) {
                    appendPaintOpIfVisible(
                        range: range,
                        priority: PaintPriority.maddNatural2MiniatureScalars,
                        category: .maddNaturalMiniature,
                        into: &ops
                    )
                }
            }
        }

        appendExplicitMaddahPaintOps(text: text, clusters: clusters, words: words, finalAaridCarrier: finalAaridCarrier, ayahFinalNaturalIndex: ayahFinalMaddNaturalIndex, into: &ops)

        if settings.isTajweedCategoryVisible(.maddNecessary) {
            for index in clusters.indices where isLazimCombinedAlifCluster(clusters[index]) {
                if index == finalAaridCarrier { continue }
                if hasMiniatureMaddScalar(clusters[index]) { continue }
                if strongerMaddRuleCovers(range: nsRange(for: clusters[index]), ops: ops) { continue }
                ops.append(PaintOp(range: nsRange(for: clusters[index]), priority: PaintPriority.maddNecessary6, category: .maddNecessary))
            }
            // Alif + maddah (ٓ) after an istila letter, without ٓاْ on one cluster - e.g. ٱلضَّآلِّينَ (lazim-style coloring).
            for i in clusters.indices where i > 0 {
                let cur = clusters[i]
                if i == finalAaridCarrier { continue }
                if hasMiniatureMaddScalar(cur) { continue }
                guard isBareAlifForMadd(cur), hasMaddah(cur) else { continue }
                if isLazimCombinedAlifCluster(cur) { continue }
                if strongerMaddRuleCovers(range: nsRange(for: cur), ops: ops) { continue }
                let prev = clusters[i - 1]
                guard let pl = prev.primaryArabicLetter, TajweedRules.heavyBaseLetters.contains(pl) else { continue }
                ops.append(PaintOp(range: nsRange(for: cur), priority: PaintPriority.maddNecessary6, category: .maddNecessary))
            }
            for i in clusters.indices where isLazimWawThenAlifSukoon(clusters: clusters, wawIndex: i) {
                guard i + 1 < clusters.count else { continue }
                if i == finalAaridCarrier || i + 1 == finalAaridCarrier { continue }
                if hasMiniatureMaddScalar(clusters[i]) || hasMiniatureMaddScalar(clusters[i + 1]) { continue }
                if strongerMaddRuleCovers(range: nsRange(for: clusters[i]), ops: ops) { continue }
                ops.append(PaintOp(range: nsRange(for: clusters[i]), priority: PaintPriority.maddNecessary6, category: .maddNecessary))
                ops.append(PaintOp(range: nsRange(for: clusters[i + 1]), priority: PaintPriority.maddNecessary6, category: .maddNecessary))
            }
            if ayah == 1, TajweedRules.surahsOpeningMuqattaat.contains(surah) {
                for i in clusters.indices {
                    if i == finalAaridCarrier { continue }
                    if hasMiniatureMaddScalar(clusters[i]) { continue }
                    guard hasMaddah(clusters[i]) else { continue }
                    if isLazimCombinedAlifCluster(clusters[i]) { continue }
                    if isLazimWawThenAlifSukoon(clusters: clusters, wawIndex: i) { continue }
                    if strongerMaddRuleCovers(range: nsRange(for: clusters[i]), ops: ops) { continue }
                    ops.append(PaintOp(range: nsRange(for: clusters[i]), priority: PaintPriority.maddNecessary6, category: .maddNecessary))
                }
            }
        }

        if settings.isTajweedCategoryVisible(.maddConnected) {
            for w in words {
                let lo = w.lowerBound, hi = w.upperBound
                guard hi - lo >= 3 else { continue }
                for i in lo..<(hi - 1) {
                    if isLastMeaningfulWord(w, in: words, clusters: clusters) { continue }
                    if hasMiniatureMaddScalar(clusters[i]) { continue }
                    if isLazimWawThenAlifSukoon(clusters: clusters, wawIndex: i) { continue }
                    if isLazimCombinedAlifCluster(clusters[i]) { continue }
                    guard isNaturalMaddCarrier(clusters: clusters, index: i, wordStart: lo) else { continue }
                    guard i + 1 < hi, hasStandardSukoon(clusters[i + 1]) else { continue }
                    var foundHamza = false
                    var k = i + 2
                    while k < hi {
                        if isHamzaCarrier(clusters[k]) { foundHamza = true; break }
                        k += 1
                    }
                    if foundHamza {
                        appendNaturalMaddPaintOps(
                            clusters: clusters,
                            index: i,
                            priority: PaintPriority.maddConnected,
                            category: .maddConnected,
                            into: &ops
                        )
                    }
                }
            }
        }

        if settings.isTajweedCategoryVisible(.maddSeparated) {
            for wi in words.indices.dropLast() {
                let w1 = words[wi], w2 = words[wi + 1]
                guard w1.upperBound - w1.lowerBound >= 2 else { continue }
                let pen = w1.upperBound - 2
                let last = w1.upperBound - 1
                if hasMiniatureMaddScalar(clusters[pen]) || hasMiniatureMaddScalar(clusters[last]) { continue }
                if isLazimWawThenAlifSukoon(clusters: clusters, wawIndex: pen) { continue }
                if isLazimCombinedAlifCluster(clusters[last]) { continue }
                guard isNaturalMaddCarrier(clusters: clusters, index: pen, wordStart: w1.lowerBound) else { continue }
                guard hasStandardSukoon(clusters[last]) else { continue }
                let firstNext = w2.lowerBound
                guard firstNext < clusters.count, isHamzaCarrier(clusters[firstNext]) else { continue }
                appendNaturalMaddPaintOps(
                    clusters: clusters,
                    index: pen,
                    priority: PaintPriority.maddSeparated,
                    category: .maddSeparated,
                    into: &ops
                )
            }
        }

        // Fallback: explicit maddah (ٓ) is not madd tabi'i.
        // If not already covered by connected/separated/necessary logic, color as necessary.
        if settings.isTajweedCategoryVisible(.maddNecessary) {
            for i in clusters.indices where hasMaddah(clusters[i]) {
                if i == finalAaridCarrier { continue }
                if i == ayahFinalMaddNaturalIndex { continue }
                if hasMiniatureMaddScalar(clusters[i]) { continue }
                if strongerMaddRuleCoversCluster(index: i, ops: ops, clusters: clusters) { continue }
                appendSpecialMaddPaintOps(
                    text: text,
                    range: nsRange(for: clusters[i]),
                    priority: PaintPriority.maddNecessary6,
                    category: .maddNecessary,
                    into: &ops
                )
            }
        }

        if settings.isTajweedCategoryVisible(.maddSukoon),
           let finalCarrier = finalAaridCarrier,
           !strongerMaddRuleCoversCluster(index: finalCarrier, ops: ops, clusters: clusters) {
            appendAaridMaddPaintOps(
                clusters: clusters,
                index: finalCarrier,
                priority: PaintPriority.maddAaridLisSukoon,
                category: .maddSukoon,
                into: &ops
            )
        }

        if settings.isTajweedCategoryVisible(.maddNatural) {
            for w in words {
                let lo = w.lowerBound, hi = w.upperBound
                for i in lo..<hi {
                    if i == finalAaridCarrier { continue }
                    if isFinalFathataynSilentAlifMadd(clusters: clusters, index: i) {
                        // Madd 'iwad: at the END of the ayah (waqf) the tanwin fath is dropped and the final
                        // alif / alif-maqsura IS pronounced as a 2-count natural madd, so colour it (not
                        // silent). Mid-ayah those alifs stay silent. Covers both fathatayn forms (ً 064B and
                        // Uthmani ٗ 0657) via hasFathatayn, for alif and alif-maqsura.
                        if strongerMaddRuleCoversCluster(index: i, ops: ops, clusters: clusters) { continue }
                        appendLetterOnlyMaddPaintOps(
                            clusters: clusters,
                            index: i,
                            priority: PaintPriority.maddNatural2,
                            category: .maddNatural,
                            into: &ops
                        )
                        continue
                    }
                    guard shouldOfferNaturalMadd2(clusters: clusters, index: i, wordStart: lo) else { continue }
                    if strongerMaddRuleCoversCluster(index: i, ops: ops, clusters: clusters) { continue }
                    appendNaturalMaddPaintOps(
                        clusters: clusters,
                        index: i,
                        priority: PaintPriority.maddNatural2,
                        category: .maddNatural,
                        into: &ops
                    )
                }
            }
        }

        if settings.isTajweedCategoryVisible(.hamzatWaslSilent),
           let firstContentUTF16 = utf16StartOfFirstNonWhitespace(clusters: clusters) {
            for index in clusters.indices where clusters[index].contains(Self.hamzatWasl) {
                let cl = clusters[index]
                if cl.utf16Range.lowerBound > firstContentUTF16 {
                    ops.append(PaintOp(range: nsRange(for: cl), priority: PaintPriority.hamzatWaslSilent, category: .hamzatWaslSilent))
                }
            }
            // Standard sukun (ْ) on و / ي / ا: silent (not read); Uthmani ۡ (U+06E1) is excluded so وۡ can still be a madd carrier.
            for cl in clusters {
                guard hasStandardSukoon(cl), !hasUthmaniSukoon(cl) else { continue }
                if cl.contains(Self.hamzatWasl) { continue }
                guard let base = cl.primaryArabicLetter else { continue }
                let silentCarrier = base == "و" || isYaBase(cl) || (base == "ا" && isBareAlifForMadd(cl))
                guard silentCarrier else { continue }
                ops.append(PaintOp(range: nsRange(for: cl), priority: PaintPriority.hamzatWaslSilent, category: .hamzatWaslSilent))
            }

            // Waw carrying a dagger-alif can be either pronounced or silent depending on attached voweling.
            // Keep pronounced cases (e.g. صَلَوَٰتِهِمۡ) untouched; only gray the silent-form waw.
            for cl in clusters {
                guard cl.primaryArabicLetter == "و", cl.contains(Self.daggerAlif) else { continue }
                guard !hasArabicVowelOnCluster(cl), !hasShadda(cl), !hasStandardSukoon(cl), !hasUthmaniSukoon(cl) else {
                    continue
                }
                guard let wawLetterRange = primaryArabicLetterScalarRange(in: cl) else { continue }
                ops.append(PaintOp(range: wawLetterRange, priority: PaintPriority.hamzatWaslSilent, category: .hamzatWaslSilent))
            }
        }
    }

    /// Necessary / sukoon / separated / connected madd already paint this cluster; skip natural madd.
    private func strongerMaddRuleCoversCluster(index: Int, ops: [PaintOp], clusters: [CharacterClusterInfo]) -> Bool {
        let r = nsRange(for: clusters[index])
        return strongerMaddRuleCovers(range: r, ops: ops)
    }

    private func strongerMaddRuleCovers(range: NSRange, ops: [PaintOp]) -> Bool {
        let blocking: Set<TajweedLegendCategory> = [.maddNecessary, .maddSukoon, .maddSeparated, .maddConnected]
        for op in ops where blocking.contains(op.category) {
            let olo = op.range.location, ohi = olo + op.range.length
            if range.location < ohi && range.location + range.length > olo { return true }
        }
        return false
    }

    private func appendExplicitMaddahPaintOps(text: String, clusters: [CharacterClusterInfo], words: [Range<Int>], finalAaridCarrier: Int?, ayahFinalNaturalIndex: Int?, into ops: inout [PaintOp]) {
        let hukmiOverrideIndices = hukmiMunfasilOverrideClusterIndices(clusters: clusters, words: words)
        for index in clusters.indices where hasMaddah(clusters[index]) {
            if index == finalAaridCarrier { continue }
            if hasMiniatureMaddMark(clusters[index]) { continue }
            var classification = explicitMaddahCategory(
                clusters: clusters,
                index: index,
                allowHukmiMunfasilOverride: hukmiOverrideIndices.contains(index)
            )
            // Ayah-final lone madd letter: read as natural madd at waqf, not the highlighted madd lazim catch-all.
            if index == ayahFinalNaturalIndex, classification.category == .maddNecessary {
                classification = (.maddNatural, PaintPriority.maddNatural2)
            }
            guard settings.isTajweedCategoryVisible(classification.category) else { continue }
            appendSpecialMaddPaintOps(
                text: text,
                range: nsRange(for: clusters[index]),
                priority: classification.priority,
                category: classification.category,
                into: &ops
            )
        }
    }

    /// Cluster indices that belong to a `proper_words` (hukmī munfaṣil) exact-match word, so the superscript
    /// madd carrier + same-word hamzah inside them is reclassified munfaṣil instead of muttaṣil.
    private func hukmiMunfasilOverrideClusterIndices(clusters: [CharacterClusterInfo], words: [Range<Int>]) -> Set<Int> {
        guard !Self.hukmiMunfasilProperWords.isEmpty else { return [] }
        var result = Set<Int>()
        for word in words {
            let wordText = word.map { clusters[$0].text }.joined().precomposedStringWithCanonicalMapping
            if Self.hukmiMunfasilProperWords.contains(wordText) {
                result.formUnion(word)
            }
        }
        return result
    }

    private func explicitMaddahCategory(
        clusters: [CharacterClusterInfo],
        index: Int,
        allowHukmiMunfasilOverride: Bool = false
    ) -> (category: TajweedLegendCategory, priority: Int) {
        let hasTashkeelMaddCarrier = scalarRange(in: clusters[index], scalar: Self.daggerAlif) != nil ||
            scalarRange(in: clusters[index], scalar: Self.smallWaw) != nil ||
            scalarRange(in: clusters[index], scalar: Self.smallYeh) != nil ||
            scalarRange(in: clusters[index], scalar: Self.smallHighYeh) != nil

        if index + 1 < clusters.count,
           !isWhitespaceOnly(clusters[index + 1]),
           hasShadda(clusters[index + 1]) {
            return (.maddNecessary, PaintPriority.explicitMaddNecessary)
        }

        var sawWordBreak = false
        var scanIndex = index + 1
        while scanIndex < clusters.count {
            let cluster = clusters[scanIndex]
            if isWhitespaceOnly(cluster) {
                sawWordBreak = true
                scanIndex += 1
                continue
            }
            if shouldIgnoreForExplicitMaddahScan(cluster) {
                scanIndex += 1
                continue
            }
            // Check hamza before the Arabic-letter guard so tatweel+hamza (e.g. ـَٔ) is caught as muttasil.
            if isHamzaCarrier(cluster) {
                if sawWordBreak {
                    return (.maddSeparated, PaintPriority.explicitMaddSeparated)
                }
                // Exception: in the `proper_words` hukmī munfaṣil words, a superscript madd carrier
                // (dagger-alif / small-waw / small-yeh) followed by a hamzah in the SAME written word is
                // recited as madd munfaṣil, not muttaṣil. Only the superscript-carrier sequence is
                // overridden - a real madd letter + hamzah in these words stays muttaṣil.
                if allowHukmiMunfasilOverride, hasTashkeelMaddCarrier {
                    return (.maddSeparated, PaintPriority.explicitMaddSeparated)
                }
                return (.maddConnected, PaintPriority.explicitMaddConnected)
            }
            guard cluster.primaryArabicLetter != nil else {
                scanIndex += 1
                continue
            }
            break
        }

        if hasTashkeelMaddCarrier {
            return (.maddNaturalMiniature, PaintPriority.maddNatural2MiniatureScalars)
        }

        return (.maddNecessary, PaintPriority.explicitMaddNecessary)
    }

    private func hasMiniatureMaddMark(_ cluster: CharacterClusterInfo) -> Bool {
        // If the miniature mark carries an explicit maddah (U+0653), treat it as explicit madd - not natural.
        guard !cluster.contains(Self.maddah) else { return false }
        return hasMiniatureMaddScalar(cluster)
    }

    private func hasMiniatureMaddScalar(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.daggerAlif) || cluster.contains(Self.smallWaw) || cluster.contains(Self.smallYeh) || cluster.contains(Self.smallHighYeh)
    }

    private func shouldIgnoreForExplicitMaddahScan(_ cluster: CharacterClusterInfo) -> Bool {
        if cluster.contains(Self.hamzatWasl) { return true }
        guard let base = cluster.primaryArabicLetter else { return false }
        if hasStandardSukoon(cluster) {
            if base == "و" || isYaBase(cluster) || isBareAlifForMadd(cluster) {
                return true
            }
        }
        if !hasAnyTashkeel(cluster) {
            return true
        }
        return false
    }

    private func appendTafkhimPaintOps(clusters: [CharacterClusterInfo], index: Int, into ops: inout [PaintOp]) {
        let cluster = clusters[index]
        let tanweenScalars: Set<UInt32> = [
            Self.fathatayn.value,
            Self.dammatayn.value,
            Self.kasratayn.value,
            Self.specialFathatayn.value,
            Self.specialDammatayn.value,
            Self.specialKasratayn.value,
        ]
        let priority = cluster.primaryArabicLetter == "ر" && indexOfFinalPronouncedArabicLetterCluster(clusters: clusters) == index
            ? PaintPriority.finalRaaTafkhim
            : PaintPriority.tafkhim

        // Always color the Arabic base letter.
        var letterRange: NSRange?
        var offset = cluster.utf16Range.lowerBound
        for scalar in cluster.text.unicodeScalars {
            let length = utf16Length(of: scalar)
            let v = scalar.value
            if (0x0621...0x063A).contains(v) || (0x0641...0x064A).contains(v) || v == 0x0671 {
                letterRange = NSRange(location: offset, length: length)
                break
            }
            offset += length
        }
        guard let letterRange else { return }
        ops.append(PaintOp(range: letterRange, priority: priority, category: .tafkhim))

        // Ayah-final pronounced heavy letter → letter only (tashkeel is silent at waqf).
        if indexOfFinalPronouncedArabicLetterCluster(clusters: clusters) == index { return }

        // Otherwise: color all non-tanween tashkeel scalars on this cluster too.
        offset = cluster.utf16Range.lowerBound
        for scalar in cluster.text.unicodeScalars {
            let length = utf16Length(of: scalar)
            if TajweedRules.tashkeelScalars.contains(scalar.value) && !tanweenScalars.contains(scalar.value) {
                ops.append(PaintOp(
                    range: NSRange(location: offset, length: length),
                    priority: priority,
                    category: .tafkhim
                ))
            }
            offset += length
        }
    }

    /// True when no Arabic letter follows in the same word (next non-decoration, non-whitespace is whitespace or end of ayah).
    private func isClusterWordFinal(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        var next = index + 1
        while next < clusters.count {
            let cl = clusters[next]
            if isWhitespaceOnly(cl) { return true }
            if cl.primaryArabicLetter != nil { return false }
            next += 1
        }
        return true // end of ayah
    }

    private func appendNaturalMaddPaintOps(
        clusters: [CharacterClusterInfo],
        index: Int,
        priority: Int,
        category: TajweedLegendCategory,
        into ops: inout [PaintOp]
    ) {
        let cluster = clusters[index]
        let skipScalars: Set<UInt32> = [Self.daggerAlif.value, Self.smallWaw.value, Self.smallYeh.value, Self.smallHighYeh.value]
        var u = cluster.utf16Range.lowerBound
        for s in cluster.text.unicodeScalars {
            if !skipScalars.contains(s.value) {
                let len = utf16Length(of: s)
                ops.append(PaintOp(range: NSRange(location: u, length: len), priority: priority, category: category))
            }
            u += utf16Length(of: s)
        }
    }

    private func appendLetterOnlyMaddPaintOps(
        clusters: [CharacterClusterInfo],
        index: Int,
        priority: Int,
        category: TajweedLegendCategory,
        into ops: inout [PaintOp]
    ) {
        let cluster = clusters[index]
        let range = primaryArabicLetterScalarRange(in: cluster) ?? nsRange(for: cluster)
        ops.append(PaintOp(range: range, priority: priority, category: category))
    }

    private func appendAaridMaddPaintOps(
        clusters: [CharacterClusterInfo],
        index: Int,
        priority: Int,
        category: TajweedLegendCategory,
        into ops: inout [PaintOp]
    ) {
        let cluster = clusters[index]
        if hasMiniatureMaddScalar(cluster) {
            for range in specialMaddScalarRanges(in: cluster) {
                ops.append(PaintOp(range: range, priority: priority, category: category))
            }
        } else {
            ops.append(PaintOp(range: nsRange(for: cluster), priority: priority, category: category))
        }
    }

    private func utf16Length(of scalar: UnicodeScalar) -> Int {
        scalar.value > 0xFFFF ? 2 : 1
    }

    private func appendScalarPaintOps(
        text: String,
        scalars: [UInt32],
        priority: Int,
        category: TajweedLegendCategory,
        into ops: inout [PaintOp]
    ) {
        let want = Set(scalars)
        var u16 = 0
        for s in text.unicodeScalars {
            let w = utf16Length(of: s)
            if want.contains(s.value) {
                ops.append(PaintOp(range: NSRange(location: u16, length: w), priority: priority, category: category))
            }
            u16 += w
        }
    }

    private func isWhitespaceOnly(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.text.allSatisfy { $0.isWhitespace }
    }

    /// Uthmani end-of-ayah marker and similar ornaments (not a spoken letter).
    private func isAyahEndOrDecorativeCluster(_ cluster: CharacterClusterInfo) -> Bool {
        guard let v = cluster.base?.unicodeScalars.first?.value else { return false }
        switch v {
        case 0x06DD: return true // ۝
        case 0x061E: return true // ۞
        default: return false
        }
    }

    /// True when the cluster is only U+06E1 (Uthmani sukun mark), optional VS / whitespace.
    private func clusterIsOnlyUthmaniSukoonMark(_ cluster: CharacterClusterInfo) -> Bool {
        var found = false
        for s in cluster.text.unicodeScalars {
            if s.value == Self.sukoonUthmani.value {
                found = true
                continue
            }
            if s.value == 0xFE0E || s.value == 0xFE0F { continue }
            if CharacterSet.whitespacesAndNewlines.contains(UnicodeScalar(s.value)!) { continue }
            return false
        }
        return found
    }

    /// Appends qalqalah PaintOps for one cluster using separate scalar-level ops (never NSUnionRange).
    /// - Sukoon case: letter op + sukoon scalar op
    /// - Shaddah case: letter op + shaddah scalar op  (nothing else between them)
    /// - Verse-final / no mark: letter op only
    private func appendQalqalahClusterPaintOps(
        clusters: [CharacterClusterInfo],
        index i: Int,
        priority: Int,
        into ops: inout [PaintOp]
    ) {
        let cl = clusters[i]

        // Always color the Arabic letter scalar itself.
        let letterRange = primaryArabicLetterScalarRange(in: cl) ?? NSRange(location: cl.utf16Range.lowerBound, length: 1)
        ops.append(PaintOp(range: letterRange, priority: priority, category: .qalqalah))

        // Standard sukoon (U+0652) or Uthmani sukoon (U+06E1) → also color that scalar.
        if let r = scalarRange(in: cl, scalar: Self.sukoon) {
            ops.append(PaintOp(range: r, priority: priority, category: .qalqalah))
        } else if let r = scalarRange(in: cl, scalar: Self.sukoonUthmani) {
            ops.append(PaintOp(range: r, priority: priority, category: .qalqalah))
        } else if let r = scalarRange(in: cl, scalar: Self.shadda) {
            // Shaddah → also color only the shaddah scalar (nothing in between).
            ops.append(PaintOp(range: r, priority: priority, category: .qalqalah))
        }
        // Verse-final / no explicit mark → letter only (already emitted above).
    }

    /// Last qalqalah letter of the ayah (waqf implies sukun), skipping trailing space and ۝.
    private func indexOfVerseFinalQalqalahCluster(clusters: [CharacterClusterInfo]) -> Int? {
        var i = clusters.count - 1
        while i >= 0 {
            let cl = clusters[i]
            if isWhitespaceOnly(cl) {
                i -= 1
                continue
            }
            if isAyahEndOrDecorativeCluster(cl) {
                i -= 1
                continue
            }
            guard let p = cl.primaryArabicLetter else {
                i -= 1
                continue
            }
            if isSilentFinalLetter(clusters: clusters, index: i) {
                if isFinalFathataynSilentAlifMadd(clusters: clusters, index: i) {
                    return nil
                }
                i -= 1
                continue
            }
            if TajweedRules.qalqalahLetters.contains(p) {
                return i
            }
            if isArabicLetterBase(p) {
                return nil
            }
            i -= 1
        }
        return nil
    }

    private func indexOfFinalArabicLetterCluster(clusters: [CharacterClusterInfo]) -> Int? {
        var i = clusters.count - 1
        while i >= 0 {
            let cl = clusters[i]
            if isWhitespaceOnly(cl) || isAyahEndOrDecorativeCluster(cl) {
                i -= 1
                continue
            }
            if cl.primaryArabicLetter != nil {
                return i
            }
            i -= 1
        }
        return nil
    }

    private func indexOfFinalPronouncedArabicLetterCluster(clusters: [CharacterClusterInfo]) -> Int? {
        var i = clusters.count - 1
        while i >= 0 {
            let cl = clusters[i]
            if isWhitespaceOnly(cl) || isAyahEndOrDecorativeCluster(cl) {
                i -= 1
                continue
            }
            guard cl.primaryArabicLetter != nil else {
                i -= 1
                continue
            }
            if isSilentFinalLetter(clusters: clusters, index: i) {
                i -= 1
                continue
            }
            return i
        }
        return nil
    }

    private func isSilentFinalLetter(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters.indices.contains(index), let base = clusters[index].primaryArabicLetter else { return false }
        if base == "ا" || base == "ى" {
            guard !hasAnyTashkeel(clusters[index]) || clusters[index].contains(Self.smallHighUprightRectangularZero) else {
                return false
            }
            if let previous = previousArabicLetterClusterIndex(clusters: clusters, before: index) {
                return hasFathatayn(clusters[previous])
            }
        }
        if base == "و" || isYaBase(clusters[index]) {
            return clusters[index].contains(Self.smallHighUprightRectangularZero)
        }
        return false
    }

    private func isFinalFathataynSilentAlifMadd(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters.indices.contains(index) else { return false }
        guard let base = clusters[index].primaryArabicLetter, base == "ا" || base == "ى" else { return false }
        guard indexOfFinalArabicLetterCluster(clusters: clusters) == index else { return false }
        guard let previous = previousArabicLetterClusterIndex(clusters: clusters, before: index) else { return false }
        // Tanwin fath at the end of an ayah → madd 'iwad (the helper alif / alif-maqsura is a 2-count
        // natural madd on waqf, not silent). It is written two ways and BOTH qualify:
        //   • fathatayn (ـً 064B / Uthmani ٗ 0657), e.g. غَفُورًا - caught by isSilentFinalLetter + hasFathatayn.
        //   • the Uthmani iqlaab form: a fatha + tiny high/low meem (the meem replaces the tanwin's noon),
        //     e.g. رُوَيۡدَۢا / سَمِيعَۢا - caught by isSilentFinalLetterAfterTinyMeem. We don't pronounce the
        //     tanwin at a stop, so the alif elongates here exactly like the fathatayn form.
        if isSilentFinalLetter(clusters: clusters, index: index), hasFathatayn(clusters[previous]) { return true }
        return isSilentFinalLetterAfterTinyMeem(clusters: clusters, index: index, previousIndex: previous)
    }

    private func wordClusterRanges(clusters: [CharacterClusterInfo]) -> [Range<Int>] {
        var out: [Range<Int>] = []
        var start = 0
        for idx in clusters.indices {
            if isWhitespaceOnly(clusters[idx]) {
                if start < idx { out.append(start..<idx) }
                start = idx + 1
            }
        }
        if start < clusters.count { out.append(start..<clusters.count) }
        return out
    }

    private func isLastMeaningfulWord(_ word: Range<Int>, in words: [Range<Int>], clusters: [CharacterClusterInfo]) -> Bool {
        guard let last = words.last else { return false }
        return word == last && last.contains(where: { clusters.indices.contains($0) && clusters[$0].primaryArabicLetter != nil })
    }

    private func finalWordNaturalMaddCarrierIndex(words: [Range<Int>], clusters: [CharacterClusterInfo]) -> Int? {
        guard let finalWord = words.last else { return nil }
        var candidate: Int?
        for i in finalWord {
            guard shouldOfferNaturalMadd2(clusters: clusters, index: i, wordStart: finalWord.lowerBound) else { continue }
            candidate = i
        }
        return candidate
    }

    private func finalWordMaddAaridCarrierIndex(words: [Range<Int>], clusters: [CharacterClusterInfo]) -> Int? {
        guard let finalWord = words.last else { return nil }

        // A word ending in madd 'iwad (a silent final alif/alif-maqsurah preceded by tanwin fath, e.g.
        // مَّذۡكُورًا) is recited as a 2-count 'iwad madd on waqf - never aarid lil sukoon. Stripping that
        // silent alif would otherwise shift the "second-to-last" letter onto the preceding madd letter
        // (the waw here), wrongly flagging it. Bail so only a genuine second-to-last carrier qualifies.
        let rawFinalLetters = finalWord.filter { clusters.indices.contains($0) && clusters[$0].primaryArabicLetter != nil }
        if let rawLast = rawFinalLetters.last,
           let base = clusters[rawLast].primaryArabicLetter, base == "ا" || base == "ى",
           let prev = previousArabicLetterClusterIndex(clusters: clusters, before: rawLast),
           (isSilentFinalLetter(clusters: clusters, index: rawLast) && hasFathatayn(clusters[prev]))
             || isSilentFinalLetterAfterTinyMeem(clusters: clusters, index: rawLast, previousIndex: prev) {
            return nil
        }

        let pronouncedLetters = effectivePronouncedArabicLetterIndices(in: finalWord, clusters: clusters)
        guard pronouncedLetters.count >= 2 else { return nil }
        let requiredCarrierIndex = pronouncedLetters[pronouncedLetters.count - 2]

        var candidate: Int?
        for index in finalWord {
            guard index == requiredCarrierIndex else { continue }
            guard isAaridMaddCarrier(
                clusters: clusters,
                index: index,
                wordStart: finalWord.lowerBound,
                finalPronouncedIndex: pronouncedLetters.last
            ) else { continue }
            candidate = index
        }
        
        return candidate
    }

    private func effectivePronouncedArabicLetterIndices(in word: Range<Int>, clusters: [CharacterClusterInfo]) -> [Int] {
        var indices = word.filter { clusters.indices.contains($0) && clusters[$0].primaryArabicLetter != nil }
        while let last = indices.last, isSilentFinalLetter(clusters: clusters, index: last) {
            indices.removeLast()
        }
        return indices
    }

    private func isAaridMaddCarrier(
        clusters: [CharacterClusterInfo],
        index: Int,
        wordStart: Int,
        finalPronouncedIndex: Int?
    ) -> Bool {
        guard clusters.indices.contains(index), index > wordStart else { return false }
        let cluster = clusters[index]

        if isLeenMaddCarrier(clusters: clusters, index: index, finalPronouncedIndex: finalPronouncedIndex) {
            return true
        }
        
        // Check for clusters with miniature madd marks (dagger alif, small waw, small yeh)
        // These should also be recognized as madd arid carriers
        if hasMiniatureMaddScalar(cluster) {
            guard let base = cluster.primaryArabicLetter else { return false }
            // Miniature marks should be on actual letter bases
            if base == "ا" || base == "و" || base == "ي" || base == "ى" {
                // Verify previous letter has appropriate vowel
                if index > 0 {
                    let previous = clusters[index - 1]
                    // For miniature marks, check if previous has any vowel or is appropriate carrier
                    if hasFathaFamily(previous) || hasDammaFamily(previous) || hasKasraFamily(previous) {
                        return !hasFathatayn(previous)
                    }
                }
            }
            return false
        }
        
        if cluster.primaryArabicLetter == "ى" {
            if isAlifMaqsurahWithDaggerAlif(cluster) { return false }
            guard !hasStandardSukoon(cluster), !cluster.contains(Self.hamzatWasl), !cluster.contains(Self.smallHighUprightRectangularZero) else {
                return false
            }
            let previous = clusters[index - 1]
            guard hasFathaFamily(previous), !hasFathatayn(previous) else { return false }
            return true
        }
        return shouldOfferNaturalMadd2(clusters: clusters, index: index, wordStart: wordStart)
    }

    private func isLeenMaddCarrier(
        clusters: [CharacterClusterInfo],
        index: Int,
        finalPronouncedIndex: Int?
    ) -> Bool {
        guard clusters.indices.contains(index),
              index > 0,
              let finalPronouncedIndex,
              clusters.indices.contains(finalPronouncedIndex),
              finalPronouncedIndex > index,
              indexOfFinalPronouncedArabicLetterCluster(clusters: clusters) == finalPronouncedIndex,
              clusters[finalPronouncedIndex].primaryArabicLetter != nil,
              !isSilentFinalLetter(clusters: clusters, index: finalPronouncedIndex) else {
            return false
        }
        let cluster = clusters[index]
        guard cluster.primaryArabicLetter == "و" || isYaBase(cluster) else { return false }
        guard hasUthmaniSukoon(cluster), !hasStandardSukoon(cluster) else { return false }
        guard !hasUnmarkedVowelLetterAfter(clusters: clusters, index: index) else { return false }
        let previous = clusters[index - 1]
        guard !isWhitespaceOnly(previous), hasFathaFamily(previous), !hasFathatayn(previous) else { return false }
        return true
    }

    private func hasUnmarkedVowelLetterAfter(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        var nextIndex = index + 1
        while nextIndex < clusters.count {
            let cluster = clusters[nextIndex]
            if isWhitespaceOnly(cluster) { break }
            if isUnmarkedVowelLetterCluster(cluster) { return true }
            nextIndex += 1
        }
        return false
    }

    private func isUnmarkedVowelLetterCluster(_ cluster: CharacterClusterInfo) -> Bool {
        guard let base = cluster.primaryArabicLetter,
              base == "ا" || base == "ى" || base == "و" || base == "ي" else {
            return false
        }
        return !cluster.text.unicodeScalars.contains { isArabicMarkScalar($0) }
    }

    private func isArabicMarkScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x064B...0x065F,
             0x0670,
             0x06D6...0x06ED:
            return true
        default:
            return false
        }
    }

    private func utf16StartOfFirstNonWhitespace(clusters: [CharacterClusterInfo]) -> Int? {
        clusters.first(where: { !isWhitespaceOnly($0) })?.utf16Range.lowerBound
    }

    private func hasMaddah(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.maddah)
    }

    private func isBareAlifForMadd(_ cluster: CharacterClusterInfo) -> Bool {
        (cluster.primaryArabicLetter == "ا" || cluster.primaryArabicLetter == "ى") && !cluster.contains(Self.hamzatWasl)
    }

    private func isAlifMaqsurahWithDaggerAlif(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.primaryArabicLetter == "ى" && cluster.contains(Self.daggerAlif)
    }

    private func isLazimCombinedAlifCluster(_ cluster: CharacterClusterInfo) -> Bool {
        hasMaddah(cluster) && isBareAlifForMadd(cluster) && hasStandardSukoon(cluster)
    }

    private func isLazimWawThenAlifSukoon(clusters: [CharacterClusterInfo], wawIndex: Int) -> Bool {
        guard wawIndex + 1 < clusters.count else { return false }
        let w = clusters[wawIndex], a = clusters[wawIndex + 1]
        guard w.primaryArabicLetter == "و", hasMaddah(w) else { return false }
        return isBareAlifForMadd(a) && hasStandardSukoon(a)
    }

    private func hasArabicVowelOnCluster(_ cluster: CharacterClusterInfo) -> Bool {
        hasHeavyOpenVowel(cluster) || hasKasraFamily(cluster)
    }

    private func hasFathaFamily(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.fatha) ||
        cluster.contains(Self.fathatayn) ||
        cluster.contains(Self.specialFathatayn)
    }

    private func hasDammaFamily(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.damma) ||
        cluster.contains(Self.dammatayn) ||
        cluster.contains(Self.specialDammatayn)
    }

    private func isYaBase(_ cluster: CharacterClusterInfo) -> Bool {
        guard let p = cluster.primaryArabicLetter else { return false }
        return p == "ي"
    }

    private func isHamzaCarrier(_ cluster: CharacterClusterInfo) -> Bool {
        if cluster.contains(Self.hamzatWasl) { return false }
        if cluster.contains(Self.bareHamza)
            || cluster.contains(Self.hamzaAbove)
            || cluster.contains(Self.hamzaBelow)
            || cluster.contains(Self.highHamza) {
            return true
        }
        guard let b = cluster.primaryArabicLetter else { return false }
        switch b {
        case "ء", "أ", "إ", "ئ", "ؤ", "آ", "ٴ", "ٶ", "ٷ", "ٸ": return true
        default: return false
        }
    }

    private func nextMeaningfulClusterIndex(clusters: [CharacterClusterInfo], after index: Int) -> Int? {
        var nextIndex = index + 1
        while nextIndex < clusters.count {
            if !isWhitespaceOnly(clusters[nextIndex]) {
                return nextIndex
            }
            nextIndex += 1
        }
        return nil
    }

    private func nextArabicLetterClusterIndex(
        clusters: [CharacterClusterInfo],
        after index: Int,
        skipFathataynCarrier: Bool = false
    ) -> Int? {
        var nextIndex = index + 1
        var skippedFollower = false
        while nextIndex < clusters.count {
            if isWhitespaceOnly(clusters[nextIndex]) {
                nextIndex += 1
                continue
            }
            if let letter = clusters[nextIndex].primaryArabicLetter {
                if skipFathataynCarrier,
                   !skippedFollower,
                   TajweedRules.fathataynFollowerSkipLetters.contains(letter) {
                    skippedFollower = true
                    nextIndex += 1
                    continue
                }
                return nextIndex
            }
            nextIndex += 1
        }
        return nil
    }

    private func hasAnyTashkeel(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.text.unicodeScalars.contains { TajweedRules.tashkeelScalars.contains($0.value) }
    }

    private func hasAnyArabicMark(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.text.unicodeScalars.contains { isArabicMarkScalar($0) }
    }

    private func appendBareConsonantSilentPaintOps(clusters: [CharacterClusterInfo], muqattaatProtectedIndices: Set<Int>, into ops: inout [PaintOp]) {
        guard settings.isTajweedCategoryVisible(.droppedLetter) else { return }
        let ayahFinalLetterIndex = indexOfFinalArabicLetterCluster(clusters: clusters)
        for index in clusters.indices {
            if muqattaatProtectedIndices.contains(index) { continue }
            let cluster = clusters[index]
            guard let base = cluster.primaryArabicLetter else { continue }
            guard !hasAnyArabicMark(cluster) else { continue }
            if hasDetachedArabicMarkAfter(clusters, index: index) { continue }
            if cluster.contains(Self.hamzatWasl),
               rangeIncludesFirstAyahLetterHamzatWasl(nsRange(for: cluster), clusters: clusters) {
                continue
            }
            if isFathataynHelperBeforeIdghamBilaGhunnah(clusters: clusters, index: index) { continue }
            if base == "ل", isLamConnectedToAllahWord(clusters: clusters, index: index) { continue }
            // The ayah-FINAL bare consonant (e.g. the meem of أَمۡثَٰلَكُم at waqf) has no tashkeel and meets no
            // other rule - it is pronounced with a waqf sukoon, not dropped, so leave it in the default color.
            // This exception is limited to the ayah's final letter: word-final bare consonants elsewhere in the
            // ayah still get the normal silent/dropped coloring. (Madd letters ا/و/ي can be genuinely silent
            // word-final, so they keep their existing behavior even at the ayah end.)
            let isMaddLetter = base == "ا" || base == "ى" || base == "و" || base == "ي"
            if !isMaddLetter, index == ayahFinalLetterIndex { continue }
            // An unmarked alif / alif-maqsura / ya is only genuinely silent when there is a reason for it:
            //   (A) the next word begins with hamzatul-wasl (ٱ), e.g. فِي ٱلۡأَرۡضِ, or
            //   (B) the preceding letter carries fathatayn (ً or ٗ), e.g. خُشَّعًا / هُدٗى.
            // Without either, leave it in the default color (a madd rule may color it instead) rather than
            // graying these letters at random. (و keeps its existing behavior.)
            if base == "ا" || base == "ى" || base == "ي" {
                let prevIdx = previousArabicLetterClusterIndex(clusters: clusters, before: index)
                let justifiedByNextHamzatWasl = nextWordStartsWithHamzatWasl(clusters: clusters, index: index)
                let justifiedByPrecedingFathatayn = prevIdx.map { hasFathatayn(clusters[$0]) } ?? false
                // (C) Iqlab tanwin: the previous letter carries the tiny high/low meem (e.g. سَمِيعَۢا),
                // which leaves a silent carrier alif just like fathatayn does - gray it too.
                let justifiedByPrecedingIqlaab = prevIdx.map {
                    isSilentFinalLetterAfterTinyMeem(clusters: clusters, index: index, previousIndex: $0)
                } ?? false
                if !justifiedByNextHamzatWasl, !justifiedByPrecedingFathatayn, !justifiedByPrecedingIqlaab { continue }
            }
            let range = primaryArabicLetterScalarRange(in: cluster) ?? nsRange(for: cluster)
            ops.append(PaintOp(range: range, priority: PaintPriority.droppedLetter, category: .droppedLetter))
        }
    }

    /// True when `index` is a word-final letter whose following word begins with hamzatul-wasl (ٱ),
    /// e.g. the ya of `فِي ٱلۡأَرۡضِ`. Requires an intervening word boundary so only a *next word* counts.
    private func nextWordStartsWithHamzatWasl(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        var i = index + 1
        var sawWordBoundary = false
        while i < clusters.count {
            let cl = clusters[i]
            if isWhitespaceOnly(cl) { sawWordBoundary = true; i += 1; continue }
            if isAyahEndOrDecorativeCluster(cl) { i += 1; continue }
            guard cl.primaryArabicLetter != nil else { i += 1; continue }
            return sawWordBoundary && cl.contains(Self.hamzatWasl)
        }
        return false
    }

    private func isFathataynHelperBeforeIdghamBilaGhunnah(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters.indices.contains(index),
              let base = clusters[index].primaryArabicLetter,
              TajweedRules.fathataynFollowerSkipLetters.contains(base),
              isSilentFinalLetter(clusters: clusters, index: index),
              let previous = previousArabicLetterClusterIndex(clusters: clusters, before: index),
              hasFathatayn(clusters[previous]),
              let nextIndex = nextArabicLetterClusterIndex(clusters: clusters, after: index),
              let nextBase = clusters[nextIndex].primaryArabicLetter else {
            return false
        }
        return TajweedRules.noonTanweenSourceOnlyIdghamLetters.contains(nextBase)
    }

    private func muqattaatProtectedClusterIndices(surah: Int, ayah: Int, clusters: [CharacterClusterInfo]) -> Set<Int> {
        if surah == 42, ayah == 1 || ayah == 2 {
            return Set(clusters.indices.filter { clusters[$0].primaryArabicLetter != nil })
        }

        if ayah == 1, TajweedRules.completeAyahMuqattaatSurahs.contains(surah) {
            return Set(clusters.indices.filter { clusters[$0].primaryArabicLetter != nil })
        }

        if ayah == 1, TajweedRules.firstWordOnlyMuqattaatSurahs.contains(surah),
           let firstWord = wordClusterRanges(clusters: clusters).first {
            return Set(firstWord.filter { clusters[$0].primaryArabicLetter != nil })
        }

        return []
    }

    private func appendMuqattaatMaddLazimPaintOps(
        clusters: [CharacterClusterInfo],
        protectedIndices: Set<Int>,
        into ops: inout [PaintOp]
    ) {
        guard settings.isTajweedCategoryVisible(.maddNecessary) else { return }
        for index in protectedIndices where clusters.indices.contains(index) && hasMaddah(clusters[index]) {
            ops.append(
                PaintOp(
                    range: nsRange(for: clusters[index]),
                    priority: PaintPriority.explicitMaddNecessary,
                    category: .maddNecessary
                )
            )
        }
    }

    private func appendMuqattaatBareRaaTafkhimPaintOps(
        clusters: [CharacterClusterInfo],
        protectedIndices: Set<Int>,
        into ops: inout [PaintOp]
    ) {
        guard settings.isTajweedCategoryVisible(.tafkhim) else { return }
        for index in protectedIndices where clusters.indices.contains(index) {
            let cluster = clusters[index]
            guard isBareMuqattaatHeavyRaa(cluster) else { continue }
            appendTafkhimPaintOps(clusters: clusters, index: index, into: &ops)
        }
    }

    private func filteredMuqattaatPaintOps(
        _ ops: [PaintOp],
        clusters: [CharacterClusterInfo],
        protectedIndices: Set<Int>
    ) -> [PaintOp] {
        guard !protectedIndices.isEmpty else { return ops }
        return ops.filter { op in
            let intersectingProtected = protectedIndices.filter {
                clusters.indices.contains($0) && nsRangesOverlap(op.range, nsRange(for: clusters[$0]))
            }
            guard !intersectingProtected.isEmpty else { return true }

            for index in intersectingProtected {
                let cluster = clusters[index]
                if hasMaddah(cluster) {
                    if op.category != .maddNecessary { return false }
                    continue
                }

                if !hasAnyTashkeel(cluster) {
                    if isHeavyCarrier(clusters: clusters, index: index) || isBareMuqattaatHeavyRaa(cluster) {
                        if op.category != .tafkhim { return false }
                    } else {
                        return false
                    }
                }
            }

            return true
        }
    }

    private func nsRangesOverlap(_ lhs: NSRange, _ rhs: NSRange) -> Bool {
        lhs.location < rhs.location + rhs.length && lhs.location + lhs.length > rhs.location
    }

    private func isBareMuqattaatHeavyRaa(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.primaryArabicLetter == "ر" && !hasAnyTashkeel(cluster)
    }

    private func containsAnySpecialNextLetterTrigger(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.text.unicodeScalars.contains { TajweedRules.specialNextLetterTriggerScalars.contains($0.value) }
    }

    private func appendPaintOpIfVisible(
        range: NSRange,
        priority: Int,
        category: TajweedLegendCategory,
        into ops: inout [PaintOp]
    ) {
        guard settings.isTajweedCategoryVisible(category) else { return }
        ops.append(PaintOp(range: range, priority: priority, category: category, color: category.color))
    }

    /// Noon/tanween behavior where next-letter coloring is allowed only for idgham variants.
    private func appendNoonSoundPaintOps(
        sourceRange: NSRange,
        targetRange: NSRange,
        nextLetter: Character,
        into ops: inout [PaintOp]
    ) {
        if TajweedRules.noonTanweenTargetOnlyIdghamLetters.contains(nextLetter) {
            // Noon/tanween before noon: leave source normal, color the target as ghunnah.
            appendPaintOpIfVisible(range: targetRange, priority: PaintPriority.generalGhunnah, category: .generalGhunnah, into: &ops)
            return
        }

        if TajweedRules.noonTanweenSplitIdghamLetters.contains(nextLetter) {
            // Noon/tanween before meem/yaa/waw: source is bilaa ghunnah, target gets ghunnah color.
            appendPaintOpIfVisible(range: sourceRange, priority: PaintPriority.idghamBilaGhunnah, category: .idghamBilaGhunnah, into: &ops)
            appendPaintOpIfVisible(range: targetRange, priority: PaintPriority.generalGhunnah, category: .generalGhunnah, into: &ops)
            return
        }

        if TajweedRules.noonTanweenSourceOnlyIdghamLetters.contains(nextLetter) {
            // Noon/tanween before laam/raa: color source only.
            appendPaintOpIfVisible(range: sourceRange, priority: PaintPriority.idghamBilaGhunnah, category: .idghamBilaGhunnah, into: &ops)
            return
        }

        // Non-idgham cases keep color on source only.
        guard let category = TajweedRules.categoryForNoTashkeelNoonOrProxy(nextLetter: nextLetter) else { return }
        let priority: Int
        switch category {
        case .ikhfaaLight, .ikhfaaHeavy:
            priority = PaintPriority.ikhfaa
        case .iqlaab:
            priority = PaintPriority.iqlaab
        case .idghamBilaGhunnah:
            priority = PaintPriority.idghamBilaGhunnah
        case .idghamGhunnah, .generalGhunnah:
            priority = PaintPriority.generalGhunnah
        default:
            priority = PaintPriority.idghamBiGhunnahHeavy
        }
        appendPaintOpIfVisible(range: sourceRange, priority: priority, category: category, into: &ops)
    }

    private func appendMeemNoTashkeelPaintOps(
        sourceRange: NSRange,
        targetRange: NSRange,
        nextLetter: Character,
        into ops: inout [PaintOp]
    ) {
        guard let category = TajweedRules.categoryForNoTashkeelMeem(nextLetter: nextLetter) else { return }
        if category == .idghamGhunnah {
            appendPaintOpIfVisible(range: sourceRange, priority: PaintPriority.idghamBiGhunnahHeavy, category: .idghamGhunnah, into: &ops)
            appendPaintOpIfVisible(range: targetRange, priority: PaintPriority.generalGhunnah, category: .generalGhunnah, into: &ops)
            return
        }
        let priority = category == .iqlaab ? PaintPriority.iqlaab : PaintPriority.ikhfaa
        appendPaintOpIfVisible(range: sourceRange, priority: priority, category: category, into: &ops)
    }

    /// Madd before ٱ merges (e.g. بِٱلله); not a stand-alone two-count madd.
    private func nextClusterIsHamzatWasl(clusters: [CharacterClusterInfo], after i: Int) -> Bool {
        guard let nextIndex = nextMeaningfulClusterIndex(clusters: clusters, after: i) else { return false }
        return clusters[nextIndex].contains(Self.hamzatWasl)
    }

    /// ي / ى carrying natural madd: kasrah on the letter before the ya.
    private func isYaaMaddLetterCluster(clusters: [CharacterClusterInfo], yaIndex: Int) -> Bool {
        guard yaIndex > 0, yaIndex < clusters.count else { return false }
        guard isYaBase(clusters[yaIndex]) else { return false }
        return hasKasraFamily(clusters[yaIndex - 1])
    }

    private func isNaturalMaddCarrier(clusters: [CharacterClusterInfo], index i: Int, wordStart: Int) -> Bool {
        guard i >= wordStart, i > 0 else { return false }
        let cur = clusters[i], prev = clusters[i - 1]
        if isWhitespaceOnly(cur) || isWhitespaceOnly(prev) { return false }
        // Explicit maddah (ٓ) must never be classified as madd tabi'i.
        if hasMaddah(cur) { return false }
        guard !hasArabicVowelOnCluster(cur) else { return false }
        if isLazimCombinedAlifCluster(cur) { return false }
        if isBareAlifForMadd(cur) {
            if isAlifMaqsurahWithDaggerAlif(cur) { return false }
            if hasStandardSukoon(cur) { return false }
            if cur.contains(Self.hamzatWasl) { return false }
            if cur.contains(Self.smallHighUprightRectangularZero) { return false }
            guard hasFathaFamily(prev) else { return false }
            // Tanwin fath (regular ً or Uthmani ٗ on previous letter) + following alif: not colored as natural madd.
            if hasFathatayn(prev) { return false }
            // Iqlab tanwin (fatha + tiny high/low meem on previous letter, e.g. سَمِيعَۢا): the following
            // alif is a silent tanwin carrier, not natural madd - let the silent painter color it instead.
            if clusterHasTinyMeemIqlaabMark(prev) { return false }
            return !nextClusterIsHamzatWasl(clusters: clusters, after: i)
        }
        if cur.primaryArabicLetter == "و" {
            if hasStandardSukoon(cur) { return false }
            if hasMaddah(cur), i + 1 < clusters.count,
               isBareAlifForMadd(clusters[i + 1]), hasStandardSukoon(clusters[i + 1]) {
                return false
            }
            let ok = hasDammaFamily(prev)
            return ok && !nextClusterIsHamzatWasl(clusters: clusters, after: i)
        }
        if isYaBase(cur) {
            if hasStandardSukoon(cur) { return false }
            let ok = hasKasraFamily(prev)
            return ok && !nextClusterIsHamzatWasl(clusters: clusters, after: i)
        }
        return false
    }

    private func hasDetachedArabicMarkAfter(_ clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard index + 1 < clusters.count else { return false }
        let next = clusters[index + 1]
        guard next.primaryArabicLetter == nil else { return false }
        return hasAnyArabicMark(next)
    }

    private func shouldOfferNaturalMadd2(clusters: [CharacterClusterInfo], index i: Int, wordStart: Int) -> Bool {
        guard isNaturalMaddCarrier(clusters: clusters, index: i, wordStart: wordStart) else { return false }
        if isLazimWawThenAlifSukoon(clusters: clusters, wawIndex: i) { return false }
        if isLazimCombinedAlifCluster(clusters[i]) { return false }
        return true
    }

    private func nsRange(for info: CharacterClusterInfo) -> NSRange {
        NSRange(location: info.utf16Range.lowerBound, length: info.utf16Range.upperBound - info.utf16Range.lowerBound)
    }

    private func tajweedVisibilitySignature() -> String {
        TajweedLegendCategory.allCases
            .map { settings.isTajweedCategoryVisible($0) ? "1" : "0" }
            .joined(separator: "")
    }

    private struct CharacterClusterInfo {
        let text: String
        let utf16Range: Range<Int>

        /// The full Swift grapheme (may bundle letter + diacritics).
        var base: Character? { text.first }

        /// First main Arabic letter in this cluster. `base` alone is wrong for sets like `heavyBaseLetters`
        /// because `Character("ضَّ")` ≠ `Character("ض")`.
        var primaryArabicLetter: Character? {
            for s in text.unicodeScalars {
                let v = s.value
                if (0x0621...0x063A).contains(v) || (0x0641...0x064A).contains(v) || v == 0x0671 {
                    return Character(s)
                }
            }
            return nil
        }

        func contains(_ scalar: UnicodeScalar) -> Bool {
            text.unicodeScalars.contains(scalar)
        }
    }

    private func characterClusters(in text: String) -> [CharacterClusterInfo] {
        var clusters: [CharacterClusterInfo] = []
        clusters.reserveCapacity(text.count)
        var currentUTF16Offset = 0
        for character in text {
            let clusterText = String(character)
            let utf16Count = clusterText.utf16.count
            let utf16Range = currentUTF16Offset..<(currentUTF16Offset + utf16Count)
            clusters.append(CharacterClusterInfo(text: clusterText, utf16Range: utf16Range))
            currentUTF16Offset += utf16Count
        }
        return clusters
    }

    private func isArabicLetterBase(_ c: Character) -> Bool {
        guard let v = c.unicodeScalars.first?.value else { return false }
        return (0x0600...0x06FF).contains(v)
            || (0x0750...0x077F).contains(v)
            || (0x08A0...0x08FF).contains(v)
    }

    private func hasStandardSukoon(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.sukoon)
    }

    private func hasUthmaniSukoon(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.sukoonUthmani)
    }

    private func hasShadda(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.shadda)
    }

    private func appendTreeDrivenPaintOps(surah: Int, ayah: Int, text: String, utf16Count: Int, into ops: inout [PaintOp]) {
        let key = TajweedAyahKey(surah: surah, ayah: ayah)
        guard let annotations = Self.tajweedRuleTreesByAyah[key], !annotations.isEmpty else { return }
        let clusters = characterClusters(in: text)
        let words = wordClusterRanges(clusters: clusters)
        let finalWord = words.last
        let finalAaridCarrier = finalWordMaddAaridCarrierIndex(words: words, clusters: clusters)

        for annotation in annotations {
            guard let category = TajweedRules.treeDrivenRuleMap[annotation.rule] else { continue }
            guard settings.isTajweedCategoryVisible(category) else { continue }
            guard TajweedRules.shouldPaintCategory(category) else { continue }
            let start = max(0, min(annotation.start, utf16Count))
            let end = max(start, min(annotation.end, utf16Count))
            guard end > start else { continue }
            let range = NSRange(location: start, length: end - start)
            if category == .maddConnected,
               let finalWord,
               rangeIntersectsWord(range, word: finalWord, clusters: clusters) {
                continue
            }
            if (category == .maddNecessary || category == .maddConnected),
               let finalAaridCarrier,
               rangeIntersectsCluster(range, clusterIndex: finalAaridCarrier, clusters: clusters) {
                continue
            }
            let priority: Int
            switch category {
            case .maddNatural:
                priority = PaintPriority.maddNatural2
            case .maddSukoon:
                continue
            case .maddSeparated:
                priority = PaintPriority.maddSeparated
            case .maddConnected:
                priority = PaintPriority.maddConnected
            case .maddNecessary:
                priority = PaintPriority.maddNecessary6
            case .qalqalah:
                priority = PaintPriority.qalqalah
            case .hamzatWaslSilent:
                if rangeIncludesFirstAyahLetterHamzatWasl(range, clusters: clusters) { continue }
                priority = PaintPriority.hamzatWaslSilent
            case .idghamGhunnah:
                priority = PaintPriority.idghamBiGhunnahLight
            case .generalGhunnah:
                priority = PaintPriority.generalGhunnah
            case .ikhfaaLight:
                priority = PaintPriority.ikhfaa
            case .ikhfaaHeavy:
                priority = PaintPriority.ikhfaa
            case .iqlaab:
                priority = PaintPriority.iqlaab
            case .idghamBilaGhunnah:
                priority = PaintPriority.idghamBilaGhunnah
            default:
                continue
            }

            if category == .qalqalah {
                appendQalqalahTreePaintOps(
                    text: text,
                    range: range,
                    priority: priority,
                    into: &ops
                )
                continue
            }

            if TajweedRules.specialTanweenCategories.contains(category) {
                appendSpecialTanweenPaintOps(
                    text: text,
                    range: range,
                    priority: priority,
                    category: category,
                    into: &ops
                )
                continue
            }

            if category == .maddNatural || category == .maddSeparated || category == .maddConnected || category == .maddNecessary {
                appendSpecialMaddPaintOps(
                    text: text,
                    range: range,
                    priority: priority,
                    category: category,
                    into: &ops
                )
                continue
            }

            ops.append(
                PaintOp(
                    range: range,
                    priority: priority,
                    category: category,
                    color: category.color
                )
            )
        }
    }

    private func rangeIntersectsCluster(_ range: NSRange, clusterIndex: Int, clusters: [CharacterClusterInfo]) -> Bool {
        guard clusters.indices.contains(clusterIndex) else { return false }
        let lo = range.location
        let hi = range.location + range.length
        let clusterRange = clusters[clusterIndex].utf16Range
        return lo < clusterRange.upperBound && hi > clusterRange.lowerBound
    }

    private func rangeIntersectsWord(_ range: NSRange, word: Range<Int>, clusters: [CharacterClusterInfo]) -> Bool {
        let lo = range.location
        let hi = range.location + range.length
        for index in word where clusters.indices.contains(index) {
            let clusterRange = clusters[index].utf16Range
            if lo < clusterRange.upperBound && hi > clusterRange.lowerBound {
                return true
            }
        }
        return false
    }

    private func appendSpecialTanweenPaintOps(
        text: String,
        range: NSRange,
        priority: Int,
        category: TajweedLegendCategory,
        into ops: inout [PaintOp]
    ) {
        let clusters = characterClusters(in: text)
        var paintedTanween = false
        for (idx, cluster) in clusters.enumerated() {
            guard utf16RangesOverlap(cluster.utf16Range, range) else { continue }
            if category == .iqlaab, clusterHasTinyMeemIqlaabMark(cluster) {
                paintedTanween = true
                continue
            }
            guard let tanweenRange = tanweenScalarRange(in: cluster) else { continue }
            // Waqf: a tanween at the end of the ayah - the last letter (e.g. نٌ), or with only a final
            // silent alif/yaa after it (نًا / نًى) - isn't pronounced when stopping, so never color it.
            // Mark it as "painted" so the whole-range fallback below doesn't end up coloring it instead.
            if isTanweenClusterAtAyahEnd(clusters: clusters, index: idx) {
                paintedTanween = true
                continue
            }
            ops.append(PaintOp(range: tanweenRange, priority: priority, category: category, color: category.color))
            paintedTanween = true
        }

        if !paintedTanween {
            ops.append(PaintOp(range: range, priority: priority, category: category, color: category.color))
        }
    }

    /// True when the tanween-carrying cluster sits at a waqf (ayah-end) position: it is the final Arabic
    /// letter, or the only thing after it is the ayah's final silent alif / alif-maqsura / yaa (نًا / نًى).
    /// Tanween is not pronounced at waqf, so its mark must never be colored there. Applies to all six
    /// tanween marks (tanweenScalarRange already matches every form).
    private func isTanweenClusterAtAyahEnd(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard let finalIdx = indexOfFinalArabicLetterCluster(clusters: clusters) else { return false }
        if index == finalIdx { return true }
        guard let nextIdx = nextArabicLetterClusterIndex(clusters: clusters, after: index) else { return true }
        guard nextIdx == finalIdx else { return false }
        if let base = clusters[finalIdx].primaryArabicLetter, base == "ا" || base == "ى" { return true }
        return isYaBase(clusters[finalIdx])
    }

    /// Ghunnah for a noon/meem with shadda colours the whole cluster - EXCEPT a trailing tanween at waqf
    /// (ayah end), which is dropped when stopping and so must stay uncoloured (e.g. وَلَا جَآنّٞ: the نّ stays
    /// green, the final tanween ٞ does not). Mid-ayah the tanween is pronounced, so the whole cluster colours.
    private func appendShaddaGhunnahPaintOps(clusters: [CharacterClusterInfo], index: Int, into ops: inout [PaintOp]) {
        let cluster = clusters[index]
        let full = nsRange(for: cluster)

        guard let tanweenRange = tanweenScalarRange(in: cluster),
              isTanweenClusterAtAyahEnd(clusters: clusters, index: index) else {
            appendPaintOpIfVisible(range: full, priority: PaintPriority.generalGhunnah, category: .generalGhunnah, into: &ops)
            return
        }

        // Colour everything in the cluster except the tanween scalar.
        let beforeLength = tanweenRange.location - full.location
        if beforeLength > 0 {
            appendPaintOpIfVisible(range: NSRange(location: full.location, length: beforeLength), priority: PaintPriority.generalGhunnah, category: .generalGhunnah, into: &ops)
        }
        let afterLocation = tanweenRange.location + tanweenRange.length
        let afterLength = (full.location + full.length) - afterLocation
        if afterLength > 0 {
            appendPaintOpIfVisible(range: NSRange(location: afterLocation, length: afterLength), priority: PaintPriority.generalGhunnah, category: .generalGhunnah, into: &ops)
        }
    }

    private func appendQalqalahTreePaintOps(
        text: String,
        range: NSRange,
        priority: Int,
        into ops: inout [PaintOp]
    ) {
        let clusters = characterClusters(in: text)
        var painted = false
        for idx in clusters.indices {
            let cluster = clusters[idx]
            guard utf16RangesOverlap(cluster.utf16Range, range) else { continue }
            guard let base = cluster.primaryArabicLetter, TajweedRules.qalqalahLetters.contains(base) else { continue }
            guard isQalqalahEligible(clusters: clusters, index: idx) else { continue }
            // Use scalar-level ops (letter + specific diacritic) - never NSUnionRange.
            appendQalqalahClusterPaintOps(clusters: clusters, index: idx, priority: priority, into: &ops)
            painted = true
        }

        _ = painted
    }

    private func tanweenScalarRange(in cluster: CharacterClusterInfo) -> NSRange? {
        var offset = cluster.utf16Range.lowerBound
        for scalar in cluster.text.unicodeScalars {
            let length = utf16Length(of: scalar)
            if scalar == Self.fathatayn ||
                scalar == Self.dammatayn ||
                scalar == Self.kasratayn ||
                scalar == Self.specialFathatayn ||
                scalar == Self.specialDammatayn ||
                scalar == Self.specialKasratayn {
                return NSRange(location: offset, length: length)
            }
            offset += length
        }
        return nil
    }

    private func sourceRangeForNoonSound(in cluster: CharacterClusterInfo) -> NSRange {
        if let tanweenRange = tanweenScalarRange(in: cluster) {
            return tanweenRange
        }
        return nsRange(for: cluster)
    }

    private func clusterHasTinyMeemIqlaabMark(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.smallHighMeem) || cluster.contains(Self.smallLowMeem)
    }

    private func shouldSuppressTinyMeemIqlaab(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters.indices.contains(index) else { return false }
        let cluster = clusters[index]
        let suppressesAtFinalSound = cluster.contains(Self.smallHighMeem) || cluster.contains(Self.smallLowMeem) || hasFathatayn(cluster)
        guard suppressesAtFinalSound else { return false }

        var next = index + 1
        while next < clusters.count {
            let cluster = clusters[next]
            if isWhitespaceOnly(cluster) || isAyahEndOrDecorativeCluster(cluster) {
                next += 1
                continue
            }
            guard cluster.primaryArabicLetter != nil else {
                next += 1
                continue
            }
            if isSilentFinalLetter(clusters: clusters, index: next) ||
                isSilentFinalLetterAfterTinyMeem(clusters: clusters, index: next, previousIndex: index) {
                next += 1
                continue
            }
            return false
        }
        return true
    }

    private func isSilentFinalLetterAfterTinyMeem(clusters: [CharacterClusterInfo], index: Int, previousIndex: Int) -> Bool {
        guard clusters.indices.contains(index),
              clusters.indices.contains(previousIndex),
              clusterHasTinyMeemIqlaabMark(clusters[previousIndex]),
              let base = clusters[index].primaryArabicLetter,
              base == "ا" || base == "ى" else {
            return false
        }
        return !hasAnyTashkeel(clusters[index]) || clusters[index].contains(Self.smallHighUprightRectangularZero)
    }

    private func tinyMeemPaintRanges(in cluster: CharacterClusterInfo) -> [NSRange] {
        // Color the whole carrier letter (e.g. the ة in ةُۢ before baa), not just the small meem mark,
        // so the iqlaab is actually visible on the letter.
        guard clusterHasTinyMeemIqlaabMark(cluster) else { return [] }
        return [nsRange(for: cluster)]
    }

    private func clusterHasSmallHighYehMaddMark(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.smallHighYeh)
    }

    private func smallHighYehMaddPaintRanges(in cluster: CharacterClusterInfo) -> [NSRange] {
        // Color the whole carrier cluster (e.g. the ـۧ in ٱلنَّبِيِّـۧنَ), not just the bare small high yeh
        // mark, so this miniature natural madd actually shows - same reasoning as `tinyMeemPaintRanges`.
        guard clusterHasSmallHighYehMaddMark(cluster) else { return [] }
        return [nsRange(for: cluster)]
    }

    private func hasFathatayn(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.fathatayn) || cluster.contains(Self.specialFathatayn)
    }

    private func isQalqalahEligible(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters.indices.contains(index) else { return false }
        let cluster = clusters[index]
        if hasUthmaniSukoon(cluster) || hasStandardSukoon(cluster) {
            return true
        }
        return indexOfVerseFinalQalqalahCluster(clusters: clusters) == index
    }

    private func sourceRangeForSpecialNoonProxyMark(in cluster: CharacterClusterInfo) -> NSRange {
        for scalar in [UnicodeScalar(0x0657)!, UnicodeScalar(0x065E)!, UnicodeScalar(0x0656)!] {
            if let hit = scalarRange(in: cluster, scalar: scalar) {
                return hit
            }
        }
        return nsRange(for: cluster)
    }

    private func scalarRange(in cluster: CharacterClusterInfo, scalar wanted: UnicodeScalar) -> NSRange? {
        var offset = cluster.utf16Range.lowerBound
        for scalar in cluster.text.unicodeScalars {
            let length = utf16Length(of: scalar)
            if scalar == wanted {
                return NSRange(location: offset, length: length)
            }
            offset += length
        }
        return nil
    }

    private func primaryArabicLetterScalarRange(in cluster: CharacterClusterInfo) -> NSRange? {
        var offset = cluster.utf16Range.lowerBound
        for scalar in cluster.text.unicodeScalars {
            let length = utf16Length(of: scalar)
            let v = scalar.value
            if (0x0621...0x063A).contains(v) || (0x0641...0x064A).contains(v) || v == 0x0671 {
                return NSRange(location: offset, length: length)
            }
            offset += length
        }
        return nil
    }

    private func appendSpecialMaddPaintOps(
        text: String,
        range: NSRange,
        priority: Int,
        category: TajweedLegendCategory,
        into ops: inout [PaintOp]
    ) {
        let clusters = characterClusters(in: text)
        if category == .maddNatural,
           rangeContainsTanweenFathAlifMaddCarrier(range, clusters: clusters) {
            return
        }
        var paintedSpecialMark = false

        for cluster in clusters {
            guard utf16RangesOverlap(cluster.utf16Range, range) else { continue }
            if hasMaddah(cluster) {
                for maddRange in explicitMaddahPaintRanges(in: cluster) {
                    ops.append(PaintOp(range: maddRange, priority: priority, category: category, color: category.color))
                }
                paintedSpecialMark = true
                continue
            }
            let specialRanges = specialMaddScalarRanges(in: cluster)
            if specialRanges.isEmpty { continue }
            paintedSpecialMark = true
            for specialRange in specialRanges {
                ops.append(PaintOp(range: specialRange, priority: priority, category: category, color: category.color))
            }
        }

        if !paintedSpecialMark {
            ops.append(PaintOp(range: range, priority: priority, category: category, color: category.color))
        }
    }

    private func rangeContainsTanweenFathAlifMaddCarrier(_ range: NSRange, clusters: [CharacterClusterInfo]) -> Bool {
        for index in clusters.indices {
            let cluster = clusters[index]
            guard utf16RangesOverlap(cluster.utf16Range, range) else { continue }
            guard isBareAlifForMadd(cluster),
                  let previous = previousArabicLetterClusterIndex(clusters: clusters, before: index) else {
                continue
            }
            if hasFathatayn(clusters[previous]) {
                return true
            }
        }
        return false
    }

    private func utf16RangesOverlap(_ lhs: Range<Int>, _ rhs: NSRange) -> Bool {
        let rhsLower = rhs.location
        let rhsUpper = rhs.location + rhs.length
        return lhs.lowerBound < rhsUpper && lhs.upperBound > rhsLower
    }

    private func specialMaddScalarRanges(in cluster: CharacterClusterInfo) -> [NSRange] {
        var offset = cluster.utf16Range.lowerBound
        var ranges: [NSRange] = []
        for scalar in cluster.text.unicodeScalars {
            let length = utf16Length(of: scalar)
            if scalar == Self.daggerAlif || scalar == Self.maddah || scalar == Self.smallWaw || scalar == Self.smallYeh || scalar == Self.smallHighYeh {
                ranges.append(NSRange(location: offset, length: length))
            }
            offset += length
        }
        return ranges
    }

    private func explicitMaddahPaintRanges(in cluster: CharacterClusterInfo) -> [NSRange] {
        let hasTashkeelMaddCarrier = scalarRange(in: cluster, scalar: Self.daggerAlif) != nil ||
            scalarRange(in: cluster, scalar: Self.smallWaw) != nil ||
            scalarRange(in: cluster, scalar: Self.smallYeh) != nil ||
            scalarRange(in: cluster, scalar: Self.smallHighYeh) != nil
        if hasTashkeelMaddCarrier {
            return specialMaddScalarRanges(in: cluster)
        }

        var ranges: [NSRange] = []
        if let letterRange = primaryArabicLetterScalarRange(in: cluster) {
            ranges.append(letterRange)
        }
        if let maddahRange = scalarRange(in: cluster, scalar: Self.maddah) {
            ranges.append(maddahRange)
        }
        return ranges.isEmpty ? [nsRange(for: cluster)] : ranges
    }

    private func appendNuunMeemGhunnahHeuristicPaintOps(text: String, into ops: inout [PaintOp]) {
        let clusters = characterClusters(in: text)
        for idx in clusters.indices {
            let cluster = clusters[idx]

            // Tiny high meem (ۢ): color only the mark. Tiny low meem (ۭ): color the full cluster.
            if clusterHasTinyMeemIqlaabMark(cluster),
               !shouldSuppressTinyMeemIqlaab(clusters: clusters, index: idx) {
                for range in tinyMeemPaintRanges(in: cluster) {
                    appendPaintOpIfVisible(range: range, priority: PaintPriority.tinyMeemIqlaab, category: .iqlaab, into: &ops)
                }
            }

            let base = cluster.primaryArabicLetter

            if let base,
               (base == "ن" || base == "م") && hasShadda(cluster) {
                // Global ghunnah: any noon or meem with shaddah.
                appendShaddaGhunnahPaintOps(clusters: clusters, index: idx, into: &ops)
                continue
            }

            // Tanween follows noon-sound rules; color source as tanween mark only.
            // Note: a tanween cluster that also carries the iqlaab tiny-meem mark (e.g. taa-marbuta ةٌۢ before
            // baa) still colors its tanween source as iqlaab - the tiny-meem mark above is painted separately.
            if tanweenScalarRange(in: cluster) != nil {
                let skipFollower = hasFathatayn(cluster)
                guard let nextIndex = nextArabicLetterClusterIndex(
                    clusters: clusters,
                    after: idx,
                    skipFathataynCarrier: skipFollower
                ),
                let nextBase = clusters[nextIndex].primaryArabicLetter else {
                    continue
                }
                appendNoonSoundPaintOps(
                    sourceRange: sourceRangeForNoonSound(in: cluster),
                    targetRange: nsRange(for: clusters[nextIndex]),
                    nextLetter: nextBase,
                    into: &ops
                )
                continue
            }

            // Meem with no tashkeel: classify from the next Arabic letter (ignoring spaces).
            if base == "م" && !hasAnyTashkeel(cluster) {
                guard let nextIndex = nextArabicLetterClusterIndex(clusters: clusters, after: idx),
                      let nextBase = clusters[nextIndex].primaryArabicLetter else {
                    continue
                }
                appendMeemNoTashkeelPaintOps(
                    sourceRange: nsRange(for: cluster),
                    targetRange: nsRange(for: clusters[nextIndex]),
                    nextLetter: nextBase,
                    into: &ops
                )
                continue
            }

            // Noon with no tashkeel: classify from the next Arabic letter (ignoring spaces).
            if base == "ن" && !hasAnyTashkeel(cluster) {
                guard let nextIndex = nextArabicLetterClusterIndex(clusters: clusters, after: idx),
                      let nextBase = clusters[nextIndex].primaryArabicLetter else {
                    continue
                }
                appendNoonSoundPaintOps(
                    sourceRange: nsRange(for: cluster),
                    targetRange: nsRange(for: clusters[nextIndex]),
                    nextLetter: nextBase,
                    into: &ops
                )
                continue
            }

            // Special Uthmani marks requested by rule: دٗ / مٞ / تٖ style clusters.
            // Apply noon-sound mapping with idgham-only target coloring.
            if containsAnySpecialNextLetterTrigger(cluster) {
                guard let nextIndex = nextArabicLetterClusterIndex(
                    clusters: clusters,
                    after: idx,
                    skipFathataynCarrier: true
                ),
                      let nextBase = clusters[nextIndex].primaryArabicLetter else {
                    continue
                }
                appendNoonSoundPaintOps(
                    sourceRange: sourceRangeForSpecialNoonProxyMark(in: cluster),
                    targetRange: nsRange(for: clusters[nextIndex]),
                    nextLetter: nextBase,
                    into: &ops
                )
            }
        }
    }

    private func isAlifLike(_ c: Character?) -> Bool {
        guard let c else { return false }
        return c == "ا" || c == "أ" || c == "إ" || c == "ئ" || c == "ؤ" || c == "آ" || c == "\u{671}"
    }

    private func isLamInAllahWord(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        let isFirstLam =
            index >= 1 &&
            isAlifLike(clusters[index - 1].primaryArabicLetter) &&
            index + 2 < clusters.count &&
            clusters[index + 1].primaryArabicLetter == "ل" &&
            clusters[index + 2].primaryArabicLetter == "ه"
        let isSecondLam =
            index >= 2 &&
            isAlifLike(clusters[index - 2].primaryArabicLetter) &&
            clusters[index - 1].primaryArabicLetter == "ل" &&
            index + 1 < clusters.count &&
            clusters[index + 1].primaryArabicLetter == "ه"
        return isFirstLam || isSecondLam
    }

    private func isFirstLamOfAllahWord(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters[index].primaryArabicLetter == "ل" else { return false }
        if index + 2 < clusters.count,
           clusters[index + 1].primaryArabicLetter == "ل",
           clusters[index + 2].primaryArabicLetter == "ه" {
            return true
        }
        return index + 1 < clusters.count &&
            clusters[index + 1].primaryArabicLetter == "ه" &&
            hasShadda(clusters[index])
    }

    private func isLamConnectedToAllahWord(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters[index].primaryArabicLetter == "ل" else { return false }
        if isLamInAllahWord(clusters: clusters, index: index) { return true }
        if isFirstLamOfAllahWord(clusters: clusters, index: index) { return true }
        let isSecondLamWithoutWasl =
            index > 0 &&
            clusters[index - 1].primaryArabicLetter == "ل" &&
            index + 1 < clusters.count &&
            clusters[index + 1].primaryArabicLetter == "ه"
        return isSecondLamWithoutWasl
    }

    private func isHamzatWaslConnectedToAllahWord(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters[index].contains(Self.hamzatWasl), index + 3 < clusters.count else { return false }
        return clusters[index + 1].primaryArabicLetter == "ل" &&
            clusters[index + 2].primaryArabicLetter == "ل" &&
            clusters[index + 3].primaryArabicLetter == "ه"
    }

    private func isLamShamsiyah(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters[index].primaryArabicLetter == "ل" else { return false }
        // Only the exact article shape ٱ + bare ل can trigger lam shamsiyyah.
        // Plain ا + ل appears inside normal words too, e.g. ٱلثَّالِثَةَ, and must not silence the لِ.
        guard !hasAnyArabicMark(clusters[index]) else { return false }
        if isLamInAllahWord(clusters: clusters, index: index) { return false }
        guard index >= 1 else { return false }
        guard clusters[index - 1].contains(Self.hamzatWasl) else { return false }
        guard index + 1 < clusters.count, let next = clusters[index + 1].primaryArabicLetter, TajweedRules.sunLetters.contains(next) else {
            return false
        }
        return true
    }

    private func rangeIncludesFirstAyahLetterHamzatWasl(_ range: NSRange, clusters: [CharacterClusterInfo]) -> Bool {
        guard let firstContentUTF16 = utf16StartOfFirstNonWhitespace(clusters: clusters),
              let firstCluster = clusters.first(where: { $0.utf16Range.lowerBound == firstContentUTF16 }),
              firstCluster.contains(Self.hamzatWasl) else {
            return false
        }
        return range.location < firstCluster.utf16Range.upperBound &&
            range.location + range.length > firstCluster.utf16Range.lowerBound
    }

    private func previousCluster(in clusters: [CharacterClusterInfo], before index: Int) -> CharacterClusterInfo? {
        guard index > 0 else { return nil }
        return clusters[index - 1]
    }

    private func previousArabicLetterClusterIndex(clusters: [CharacterClusterInfo], before index: Int) -> Int? {
        var i = index - 1
        while i >= 0 {
            let cluster = clusters[i]
            if isWhitespaceOnly(cluster) { return nil }
            if cluster.primaryArabicLetter != nil {
                return i
            }
            i -= 1
        }
        return nil
    }

    private func previousPronouncedArabicLetterClusterIndex(clusters: [CharacterClusterInfo], before index: Int) -> Int? {
        var i = index - 1
        while i >= 0 {
            let cluster = clusters[i]
            if isWhitespaceOnly(cluster) { return nil }
            guard cluster.primaryArabicLetter != nil else {
                i -= 1
                continue
            }
            if isSilentFinalLetter(clusters: clusters, index: i) {
                i -= 1
                continue
            }
            return i
        }
        return nil
    }

    private func hasHeavyOpenVowel(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.fatha) ||
        cluster.contains(Self.damma) ||
        cluster.contains(Self.fathatayn) ||
        cluster.contains(Self.dammatayn) ||
        cluster.contains(Self.specialFathatayn) ||
        cluster.contains(Self.specialDammatayn)
    }

    private func hasKasraFamily(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.kasra) ||
        cluster.contains(Self.kasratayn) ||
        cluster.contains(Self.specialKasratayn)
    }

    private func hasSukoon(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.sukoon) || cluster.contains(Self.sukoonUthmani)
    }

    private func hasDaggerAlif(_ cluster: CharacterClusterInfo) -> Bool {
        cluster.contains(Self.daggerAlif)
    }

    private func shouldUseHeavyAllahLam(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        if hasKasraFamily(clusters[index]) { return false }
        if hasHeavyOpenVowel(clusters[index]) { return true }
        var previousIndex = index - 1
        while previousIndex >= 0 {
            let previous = clusters[previousIndex]
            if isWhitespaceOnly(previous) || previous.contains(Self.hamzatWasl) {
                previousIndex -= 1
                continue
            }
            if isSilentCarrierForAllahLamScan(previous) {
                previousIndex -= 1
                continue
            }
            return hasFathaFamily(previous) || hasDammaFamily(previous)
        }
        return false
    }

    private func secondLamScalarRange(in cluster: CharacterClusterInfo) -> NSRange? {
        var offset = cluster.utf16Range.lowerBound
        var seenFirstLam = false

        for scalar in cluster.text.unicodeScalars {
            let length = utf16Length(of: scalar)
            if scalar.value == 0x0644 {
                if seenFirstLam {
                    return NSRange(location: offset, length: length)
                }
                seenFirstLam = true
            }
            offset += length
        }

        return nil
    }

    private func isSilentCarrierForAllahLamScan(_ cluster: CharacterClusterInfo) -> Bool {
        guard let base = cluster.primaryArabicLetter else { return false }
        if cluster.contains(Self.hamzatWasl) { return true }
        if hasStandardSukoon(cluster), !hasUthmaniSukoon(cluster) {
            return base == "و" || isYaBase(cluster) || (base == "ا" && isBareAlifForMadd(cluster))
        }
        if base == "و", cluster.contains(Self.daggerAlif),
           !hasArabicVowelOnCluster(cluster), !hasShadda(cluster), !hasStandardSukoon(cluster), !hasUthmaniSukoon(cluster) {
            return true
        }
        return false
    }

    private func shouldUseHeavyColor(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard let base = clusters[index].primaryArabicLetter else { return false }

        // Seven istila letters: always tafkhim in coloring; vowels on the letter are ignored (sukun still gets its own higher-priority color).
        if TajweedRules.heavyBaseLetters.contains(base) {
            return true
        }

        if base == "ر" {
            return isHeavyRaa(clusters: clusters, index: index)
        }

        // Allah heavy-lam special case intentionally disabled for now.
        // if base == "ل", isFirstLamOfAllahWord(clusters: clusters, index: index) {
        //     return shouldUseHeavyAllahLam(clusters: clusters, index: index)
        // }

        // Alif maqsuurah (ى) should NOT inherit heaviness from previous letters
        if base == "ى" {
            return false
        }

        if TajweedRules.alifFollowerLetters.contains(base), index > 0 {
            if let previous = previousArabicLetterClusterIndex(clusters: clusters, before: index),
               hasFathatayn(clusters[previous]),
               isSilentFinalLetter(clusters: clusters, index: index) {
                return false
            }
            return isHeavyCarrier(clusters: clusters, index: index - 1)
        }

        return false
    }

    private func isHeavyCarrier(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard let base = clusters[index].primaryArabicLetter else { return false }
        if TajweedRules.heavyBaseLetters.contains(base) {
            return true
        }
        if base == "ر" {
            return isHeavyRaa(clusters: clusters, index: index)
        }
        return false
    }

    /// Heavy ra: normal connected reading follows local vowels; ayah-final raa follows the stopped sound.
    private func isHeavyRaa(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters[index].primaryArabicLetter == "ر" else { return false }
        let current = clusters[index]
        if indexOfFinalPronouncedArabicLetterCluster(clusters: clusters) == index {
            guard let previousIndex = previousPronouncedArabicLetterClusterIndex(clusters: clusters, before: index) else { return false }
            let previous = finalRaaVowelContextCluster(clusters: clusters, previousIndex: previousIndex)
            if hasKasraFamily(previous) { return false }
            if previous.primaryArabicLetter == "و" {
                return !hasAnyTashkeel(previous) || hasDammaFamily(previous)
            }
            if previous.primaryArabicLetter == "ا" || previous.primaryArabicLetter == "ى" {
                return !hasAnyTashkeel(previous)
            }
            return hasFathaFamily(previous) || hasDammaFamily(previous)
        }
        if hasKasraFamily(current) { return false }
        if hasHeavyOpenVowel(current) { return true }
        if hasSukoon(current) {
            switch saakinRaaVowelContext(clusters: clusters, index: index) {
            case .none:
                return false
            case .startingHamzatWasl(let takesDamma):
                return takesDamma
            case .letter(let previous):
                if hasKasraFamily(previous) { return false }
                if hasFathaFamily(previous) || hasDammaFamily(previous) { return true }
                if previous.primaryArabicLetter == "و" {
                    return !hasAnyTashkeel(previous)
                }
                if previous.primaryArabicLetter == "ا" || previous.primaryArabicLetter == "ى" {
                    return !hasAnyTashkeel(previous)
                }
                return false
            }
        }
        if hasShadda(current) { return true }
        guard let prev = previousCluster(in: clusters, before: index) else { return false }
        if hasKasraFamily(prev) { return true }
        if isYaaMaddLetterCluster(clusters: clusters, yaIndex: index - 1) { return true }
        return false
    }

    /// What a saakin raa leans on for its weight.
    private enum SaakinRaaVowelContext {
        /// The pronounced letter before it; its vowel decides.
        case letter(CharacterClusterInfo)
        /// A hamzatul-wasl that actually opens the recitation, so its own assumed vowel decides.
        case startingHamzatWasl(takesDamma: Bool)
        case none
    }

    /// A saakin raa preceded by hamzatul-wasl (`وَٱرۡتَبۡتُمۡ` 57:14, `قَالُوا۟ ٱرۡجِعُوا۟`) has no vowel of its own to
    /// lean on, and the wasl hamza is dropped in connected reading — so the weight is decided by whatever comes
    /// before the hamza, reaching back across the word boundary if need be (in 57:14 that's the fatha on the
    /// و of وَ, which makes the raa heavy; the old code stopped at the vowel-less hamza and called it light).
    ///
    /// Only when the hamza opens the ayah is it actually pronounced, and then it carries its own assumed vowel:
    /// the classic rule is that it takes a damma when the word's third letter has one, and a kasra otherwise —
    /// so damma → heavy, anything else → light.
    private func saakinRaaVowelContext(clusters: [CharacterClusterInfo], index: Int) -> SaakinRaaVowelContext {
        // Stops at the word boundary, so this only ever finds a hamzatul-wasl that sits in the raa's own word.
        guard let previousIndex = previousPronouncedArabicLetterClusterIndex(clusters: clusters, before: index) else {
            return .none
        }
        guard clusters[previousIndex].contains(Self.hamzatWasl) else {
            return .letter(clusters[previousIndex])
        }
        if let beforeHamzaIndex = previousPronouncedArabicLetterClusterIndexCrossingWords(clusters: clusters, before: previousIndex) {
            return .letter(clusters[beforeHamzaIndex])
        }
        return .startingHamzatWasl(takesDamma: hamzatWaslStartTakesDamma(clusters: clusters, hamzaIndex: previousIndex))
    }

    /// Like `previousPronouncedArabicLetterClusterIndex`, but steps over word boundaries instead of stopping at
    /// them — needed only where a letter is dropped in connected reading and the sound carries over from the
    /// previous word.
    private func previousPronouncedArabicLetterClusterIndexCrossingWords(clusters: [CharacterClusterInfo], before index: Int) -> Int? {
        var i = index - 1
        while i >= 0 {
            let cluster = clusters[i]
            guard cluster.primaryArabicLetter != nil, !isAyahEndOrDecorativeCluster(cluster) else {
                i -= 1
                continue
            }
            if isSilentFinalLetter(clusters: clusters, index: i) {
                i -= 1
                continue
            }
            return i
        }
        return nil
    }

    /// The hamzatul-wasl "third letter" rule: counting the hamza itself as the first letter of its word, a damma
    /// on the third letter means the hamza is started with a damma (heavy), anything else means a kasra (light).
    private func hamzatWaslStartTakesDamma(clusters: [CharacterClusterInfo], hamzaIndex: Int) -> Bool {
        var letterCount = 1 // the hamza
        var i = hamzaIndex + 1
        while i < clusters.count {
            let cluster = clusters[i]
            if isWhitespaceOnly(cluster) { return false } // word ended before a third letter
            guard cluster.primaryArabicLetter != nil else {
                i += 1
                continue
            }
            letterCount += 1
            if letterCount == 3 {
                return hasDammaFamily(cluster)
            }
            i += 1
        }
        return false
    }

    private func finalRaaVowelContextCluster(clusters: [CharacterClusterInfo], previousIndex: Int) -> CharacterClusterInfo {
        let previous = clusters[previousIndex]
        guard hasSukoonOnClusterOrDetachedAfter(clusters: clusters, index: previousIndex),
              let beforeSukoonIndex = previousPronouncedArabicLetterClusterIndex(clusters: clusters, before: previousIndex) else {
            return previous
        }
        return clusters[beforeSukoonIndex]
    }

    private func hasSukoonOnClusterOrDetachedAfter(clusters: [CharacterClusterInfo], index: Int) -> Bool {
        guard clusters.indices.contains(index) else { return false }
        if hasSukoon(clusters[index]) { return true }
        guard index + 1 < clusters.count else { return false }
        let next = clusters[index + 1]
        guard next.primaryArabicLetter == nil else { return false }
        return hasSukoon(next)
    }

}
final class QuranData: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loadingCore
        case buildingIndexes
        case ready
        case failed
    }

    private enum RevelationSearchMode {
        case makkan
        case madinan
    }

    private static let makkanAliases: Set<String> = [
        "makkah", "makkan", "makki"
    ]

    private static let madinanAliases: Set<String> = [
        "madinah", "madinan", "madina", "madani"
    ]

    /// Surahs that should always display as less than one page in UI metadata.
    private static let forcedLessThanOnePageSurahIDs: Set<Int> = Set([82, 86, 87]).union(Set(90...114))

    struct SurahSearchIndexEntry: Identifiable, Codable, Equatable {
        let surahID: Int
        let nameEnglishUpper: String
        let nameTransliterationUpper: String
        let searchableBlob: String
        let compactSearchableBlob: String

        var id: Int { surahID }
    }

    struct JuzSearchIndexEntry: Identifiable, Codable, Equatable {
        let juzID: Int
        let searchableBlob: String
        let compactSearchableBlob: String

        var id: Int { juzID }
    }

    enum CountOperator {
        case equal
        case lessThan
        case lessThanOrEqual
        case greaterThan
        case greaterThanOrEqual
    }

    struct CountFilter {
        let op: CountOperator
        let value: Int
    }

    struct PageSectionData: Identifiable, Codable, Equatable {
        let page: Int
        let surahIDs: [Int]

        var id: Int { page }
    }

    struct JuzSectionData: Identifiable, Codable, Equatable {
        struct Row: Identifiable, Codable, Equatable {
            enum Kind: Codable, Equatable {
                case plain
                case start(ayah: Int)
                case end(ayah: Int)
            }

            let surahID: Int
            let kind: Kind

            var id: String {
                switch kind {
                case .plain:
                    return "\(surahID)-plain"
                case .start(let ayah):
                    return "\(surahID)-start-\(ayah)"
                case .end(let ayah):
                    return "\(surahID)-end-\(ayah)"
                }
            }
        }

        let juz: Juz
        let surahIDs: [Int]
        let rows: [Row]

        var id: Int { juz.id }
    }

    static let shared: QuranData = {
        let q = QuranData()
        q.startLoading()
        return q
    }()

    /// Set once the full "warm every surah" prewarm pass has completed (whether driven from the app root when
    /// the Adhan tab appears, or from QuranView). Shared so neither site repeats the broad pass.
    @MainActor static var didBroadPrewarm = false

    private let settings = Settings.shared

    @Published private(set) var quran: [Surah] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var pageSections: [PageSectionData] = []
    @Published private(set) var juzSections: [JuzSectionData] = []
    @Published private(set) var revelationOrderSurahIDs: [Int] = []
    @Published private(set) var surahSearchIndex: [SurahSearchIndexEntry] = []
    @Published private(set) var isVerseSearchReady = false
    private(set) var verseIndex: [VerseIndexEntry] = []

    private var surahIndex = [Int:Int]()
    private var ayahIndex = [[Int:Int]]()
    /// Qiraah key the verse index was built for ("" = Hafs). Rebuild when display qiraah changes.
    private var cachedVerseIndexQiraah: String? = nil
    /// Qiraah key the boundary model was built for ("" = Hafs). Rebuild when display qiraah changes.
    private var cachedBoundaryQiraah: String? = nil
    /// Qiraah key for first page/juz ayah lookup tables ("" = Hafs).
    private var cachedFirstAyahLookupQiraah: String? = nil
    private var surahBoundaryModels = [Int: SurahBoundaryModel]()
    private var firstAyahByPage = [Int: (surah: Int, ayah: Int)]()
    private var firstAyahByJuz = [Int: (surah: Int, ayah: Int)]()
    /// Cached contiguous index list to avoid reallocating Array(verseIndex.indices) on every query.
    private var allVerseIndices: [Int] = []
    /// The immutable per-keystroke search snapshot, reused until the index is (re)built. Built/read only on
    /// the main actor (`verseSearchSnapshot()` is called from a View before its detached search task), and
    /// nil'd wherever the underlying index arrays change. Avoids reconstructing the 9-field struct each keystroke.
    private var cachedVerseSearchSnapshot: VerseSearchSnapshot?
    private var surahIDsByAyahCount = [Int: [Int]]()
    private var surahIDsByPageCount = [Int: [Int]]()
    private var surahIDsByJuz = [Int: [Int]]()
    private var juzSearchIndex: [JuzSearchIndexEntry] = []
    private var cachedSajdahAyahResults: [(surah: Surah, ayah: Ayah)]?
    private var cachedMuqattaatAyahResults: [(surah: Surah, ayah: Ayah)]?
    private var cachedPageAyahResults: [(page: Int, surah: Surah, ayah: Ayah)]?

    private var loadTask: Task<Void, Never>?
    private var searchIndexBuildTask: Task<Void, Never>?
    private var loadErrorDescription: String? = nil

    private init() {}

    private static let arFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "ar")
        return f
    }()

    struct VerseSearchSnapshot {
        let qiraahKey: String
        let verseIndex: [VerseIndexEntry]
        let allVerseIndices: [Int]

        private struct BooleanAyahTerm {
            enum MatchMode {
                case contains
                case startsWith
                case endsWith
                case exact
                case wholeWord   // `=` - matches whole words / a series of whole words (not substrings)
            }

            let value: String
            let isNegated: Bool
            let matchMode: MatchMode
            let requiresTashkeelMatch: Bool
            let tashkeelPattern: String
            let requiresExactEnglishMatch: Bool
            let exactEnglishPhrase: String
        }

        func search(term raw: String, limit: Int = 10, offset: Int = 0) -> [VerseIndexEntry] {
            guard !verseIndex.isEmpty else { return [] }

            let q = Settings.shared.cleanSearch(raw, whitespace: true)
            guard !q.isEmpty else { return [] }
            if q.rangeOfCharacter(from: .decimalDigits) != nil { return [] }

            let booleanGroups = booleanAyahSearchGroups(from: raw)
            if let booleanGroups, booleanGroups.isEmpty { return [] }

            let useArabic = raw.containsArabicLetters

            if let booleanGroups {
                var filtered: [VerseIndexEntry] = []
                filtered.reserveCapacity(limit == .max ? 64 : min(limit, 64))

                var skipped = 0
                var scanned = 0
                for entry in verseIndex {
                    // Same abandoned-keystroke early-out as the regular branch below - operator queries
                    // use the heavier per-term matcher and never break at `limit` on rare matches, so
                    // they were the slowest AND the only uninterruptible scan.
                    scanned += 1
                    if scanned & 0x1FF == 0, Task.isCancelled { break }
                    guard matchesBooleanAyahSearch(entry: entry, useArabic: useArabic, groups: booleanGroups) else { continue }
                    if skipped < offset { skipped += 1; continue }
                    filtered.append(entry)
                    if limit != .max, filtered.count >= limit { break }
                }
                return filtered
            }

            let silentQuery = useArabic
                ? Settings.shared.cleanSearchIgnoringSilentArabicLetters(raw, whitespace: true)
                : nil
            return regularSearchResults(
                for: q,
                rawQuery: raw,
                silentQuery: silentQuery,
                useArabic: useArabic,
                limit: limit,
                offset: offset
            )
        }

        /// The typed query plus its vocative-joined twin ("يا نساء" → "يانساء"), or nil when joining
        /// changes nothing. An ADDITIONAL lane, so the original spaced query still matches everything
        /// it used to.
        private func joinedArabicQueryVariant(_ query: String) -> String? {
            let joined = query.joiningVocativeYaForSearch
            return joined == query ? nil : joined
        }

        private func regularSearchResults(
            for cleanedQuery: String,
            rawQuery: String,
            silentQuery: String?,
            useArabic: Bool,
            limit: Int,
            offset: Int
        ) -> [VerseIndexEntry] {
            // Plain substring search, returned in mushaf order. Word and sentence boundaries don't matter - a
            // query matches anywhere it appears (e.g. "رب" inside "ربهم"). Use the `=` operator for whole-word
            // / phrase matching, or `#` for an exact (case- and tashkeel-sensitive) substring. The scan exits
            // early at `limit` and runs off the main thread.
            var results: [VerseIndexEntry] = []
            results.reserveCapacity(limit == .max ? 64 : min(limit, 64))

            // Joined once per query, not per entry - the scan below visits up to 6,236 entries.
            let joinedQuery = useArabic ? joinedArabicQueryVariant(cleanedQuery) : nil
            let joinedSilentQuery = useArabic ? silentQuery.flatMap(joinedArabicQueryVariant) : nil
            // Built once too. Non-nil only when the reader typed a bare ء, and then it REPLACES the
            // ordinary Arabic test: the hamza lane is strictly stricter, so passing it implies passing
            // the plain one. Filtering here (not at the call site) keeps limit/offset paging honest.
            let hamzaFilter = useArabic ? Settings.HamzaPrecisionFilter(query: rawQuery) : nil

            var skipped = 0
            var scanned = 0
            for index in allVerseIndices {
                // A superseded keystroke's scan (the task is cancelled the moment the next character
                // arrives) stops paying for the rest of the 6,236 entries - it matters most under Low
                // Power Mode, where every wasted scan competes with the keystroke that replaced it.
                scanned += 1
                if scanned & 0x1FF == 0, Task.isCancelled { break }
                guard verseIndex.indices.contains(index) else { continue }
                let entry = verseIndex[index]
                guard regularSearchEntryMatches(
                    entry,
                    cleanedQuery: cleanedQuery,
                    joinedQuery: joinedQuery,
                    silentQuery: silentQuery,
                    joinedSilentQuery: joinedSilentQuery,
                    hamzaFilter: hamzaFilter,
                    useArabic: useArabic
                ) else { continue }
                if skipped < offset {
                    skipped += 1
                    continue
                }
                results.append(entry)
                if limit != .max, results.count >= limit { break }
            }
            return results
        }

        private func regularSearchEntryMatches(
            _ entry: VerseIndexEntry,
            cleanedQuery: String,
            joinedQuery: String?,
            silentQuery: String?,
            joinedSilentQuery: String?,
            hamzaFilter: Settings.HamzaPrecisionFilter?,
            useArabic: Bool
        ) -> Bool {
            // Pure substring (`contains`) - boundaries don't matter. Whole-word / phrase matching lives in
            // the `=` operator instead.
            if useArabic {
                // A bare ء in the query is a deliberate keystroke, so it has to survive the fold on BOTH
                // sides. This lane subsumes the ones below (dropping the hamza can only merge more words
                // together), so it stands alone rather than adding to them.
                if let hamzaFilter { return hamzaFilter.matches(lanes: entry.hamzaArabicBlob) }
                if entry.arabicBlob.contains(cleanedQuery) { return true }
                if let joinedQuery, entry.arabicBlob.contains(joinedQuery) { return true }
                guard let silentQuery, !silentQuery.isEmpty else { return false }
                if entry.silentArabicBlob.contains(silentQuery) { return true }
                if let joinedSilentQuery, entry.silentArabicBlob.contains(joinedSilentQuery) { return true }
                return false
            }

            return entry.englishBlob.contains(cleanedQuery)
        }

        /// True if `query`'s tokens appear as a consecutive run in `haystack`. The leading tokens must match
        /// exactly; the final token must match exactly when `lastMustBeExact` is true, otherwise it only has
        /// to be a prefix (e.g. query "when" hits "...whenever..." when `lastMustBeExact` is false).
        private func consecutiveTokenMatch(_ haystack: [String], query: [String], lastMustBeExact: Bool) -> Bool {
            guard !query.isEmpty, haystack.count >= query.count else { return false }

            for start in 0...(haystack.count - query.count) {
                var matched = true
                for offset in query.indices {
                    let word = haystack[start + offset]
                    let term = query[offset]
                    if offset == query.count - 1 && !lastMustBeExact {
                        if !word.hasPrefix(term) { matched = false; break }
                    } else if word != term {
                        matched = false
                        break
                    }
                }
                if matched { return true }
            }

            return false
        }

        private func booleanAyahSearchGroups(from rawQuery: String) -> [[BooleanAyahTerm]]? {
            let normalized = rawQuery
                .replacingOccurrences(of: "&&", with: "&")
                .replacingOccurrences(of: "||", with: "|")

            guard normalized.contains("&") || normalized.contains("|") || normalized.contains("!") || normalized.contains("#") || normalized.contains("^") || normalized.contains("%") || normalized.contains("$") || normalized.contains("=") else {
                return nil
            }

            return normalized
                .split(separator: "|", omittingEmptySubsequences: false)
                .map { part in
                    part
                        .split(separator: "&", omittingEmptySubsequences: false)
                        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                        .compactMap(booleanAyahSearchTerm(from:))
                }
                .filter { !$0.isEmpty }
        }

        private func booleanAyahSearchTerm(from rawTerm: String) -> BooleanAyahTerm? {
            var term = rawTerm.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !term.isEmpty else { return nil }

            var isNegated = false
            while term.hasPrefix("!") {
                isNegated.toggle()
                term.removeFirst()
                term = term.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            var requiresTashkeelMatch = false
            while term.hasPrefix("#") {
                requiresTashkeelMatch = true
                term.removeFirst()
                term = term.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            var wholeWordMatch = false
            while term.hasPrefix("=") {
                wholeWordMatch = true
                term.removeFirst()
                term = term.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            var startsWithMatch = false
            if term.hasPrefix("^") {
                startsWithMatch = true
                term.removeFirst()
                term = term.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            var endsWithMatch = false
            if term.hasSuffix("%") || term.hasSuffix("$") {
                endsWithMatch = true
                term.removeLast()
                term = term.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            guard !term.isEmpty else { return nil }
            let cleaned = Settings.shared.cleanSearch(term, whitespace: true)
            guard !cleaned.isEmpty else { return nil }

            let matchMode: BooleanAyahTerm.MatchMode
            if wholeWordMatch {
                matchMode = .wholeWord
            } else if startsWithMatch && endsWithMatch {
                matchMode = .exact
            } else if startsWithMatch {
                matchMode = .startsWith
            } else if endsWithMatch {
                matchMode = .endsWith
            } else {
                matchMode = .contains
            }

            return BooleanAyahTerm(
                value: cleaned,
                isNegated: isNegated,
                matchMode: matchMode,
                requiresTashkeelMatch: requiresTashkeelMatch && term.containsArabicLetters,
                tashkeelPattern: arabicTashkeelBlob(term),
                requiresExactEnglishMatch: requiresTashkeelMatch && !term.containsArabicLetters,
                exactEnglishPhrase: exactPhraseBlob(term)
            )
        }

        private func ayahTermMatch(haystack: String, tokens: [String], term: String, mode: BooleanAyahTerm.MatchMode) -> Bool {
            switch mode {
            case .contains:
                return haystack.contains(term)
            case .startsWith:
                return haystack.hasPrefix(term) || tokens.contains(where: { $0.hasPrefix(term) })
            case .endsWith:
                return haystack.hasSuffix(term) || tokens.contains(where: { $0.hasSuffix(term) })
            case .exact:
                return haystack == term || tokens.contains(term)
            case .wholeWord:
                // The query's words must appear as a consecutive run of whole words (a full word, or a
                // full series of words) - e.g. "=رب" matches the word رب but not "ربهم".
                return consecutiveTokenMatch(tokens, query: searchTokens(from: term), lastMustBeExact: true)
            }
        }

        private func matchesBooleanAyahSearch(entry: VerseIndexEntry, useArabic: Bool, groups: [[BooleanAyahTerm]]) -> Bool {
            groups.contains { andTerms in
                andTerms.allSatisfy { term in
                    let containsTerm: Bool
                    if useArabic, term.requiresTashkeelMatch {
                        let lettersMatch = ayahTermMatch(
                            haystack: entry.arabicBlob,
                            tokens: entry.arabicTokens,
                            term: term.value,
                            mode: term.matchMode
                        )
                        let tashkeelMatch = term.tashkeelPattern.isEmpty || entry.arabicTashkeelBlob.contains(term.tashkeelPattern)
                        containsTerm = lettersMatch && tashkeelMatch
                    } else if !useArabic, term.requiresExactEnglishMatch {
                        let exactTokens = searchTokens(from: term.exactEnglishPhrase)
                        containsTerm = !term.exactEnglishPhrase.isEmpty && ayahTermMatch(
                            haystack: entry.englishExactBlob,
                            tokens: exactTokens,
                            term: term.exactEnglishPhrase,
                            mode: term.matchMode
                        )
                    } else {
                        let haystack = useArabic ? entry.arabicBlob : entry.englishBlob
                        let tokens = useArabic ? entry.arabicTokens : entry.englishTokens
                        containsTerm = ayahTermMatch(haystack: haystack, tokens: tokens, term: term.value, mode: term.matchMode)
                    }
                    return term.isNegated ? !containsTerm : containsTerm
                }
            }
        }

        private func searchTokens(from cleanedText: String) -> [String] {
            cleanedText
                .split(separator: " ")
                .map(String.init)
                .filter { !$0.isEmpty }
        }

        private func exactPhraseBlob(_ text: String) -> String {
            text
                .lowercased()
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }

        private func arabicTashkeelBlob(_ text: String) -> String {
            String(text.unicodeScalars.filter { Self.arabicTashkeelCharacterSet.contains($0) })
        }

        private static let arabicTashkeelCharacterSet: CharacterSet = {
            var set = CharacterSet()
            set.insert(charactersIn: "\u{0610}"..."\u{061A}")
            set.insert(charactersIn: "\u{064B}"..."\u{065F}")
            set.insert(charactersIn: "\u{0670}"..."\u{0670}")
            set.insert(charactersIn: "\u{06D6}"..."\u{06ED}")
            return set
        }()
    }

    private func arabicToEnglishNumber(_ arabicNumber: String) -> Int? {
        Self.arFormatter.number(from: arabicNumber)?.intValue
    }

    /// One-time cleanup: the static/dynamic plist cache layer is gone (the bundled .qpk packs made it
    /// redundant - they ARE the preprocessed form), but shipped versions left multi-MB cache files in
    /// Application Support. Delete the whole directory so users get the disk back.
    private static func purgeLegacyDerivedCaches() {
        // One-shot: after the first successful run the directory is gone; skip the syscall forever.
        let purgeFlag = "didPurgeLegacyQuranCaches"
        guard !UserDefaults.standard.bool(forKey: purgeFlag) else { return }
        defer { UserDefaults.standard.set(true, forKey: purgeFlag) }
        let fileManager = FileManager.default
        guard let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let directoryURL = baseURL
            .appendingPathComponent(AppIdentifiers.bundleIdentifier, isDirectory: true)
            .appendingPathComponent("QuranCache", isDirectory: true)
        try? fileManager.removeItem(at: directoryURL)
    }

    private func scheduleVerseSearchIndexBuild(
        qiraahKey: String,
        surahs: [Surah]
    ) {
        #if os(watchOS)
        return
        #else
        searchIndexBuildTask?.cancel()

        // .userInitiated, not .utility: the user is blocked on this (search shows "preparing" until it
        // lands), and .utility is the QoS tier Low Power Mode throttles hardest - under LPM the index could
        // take tens of seconds to appear, which read as "search is broken."
        searchIndexBuildTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            // Give first render a chance to settle before building the heavier global ayah index.
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }

            let displayQiraah = qiraahKey.isEmpty ? nil : qiraahKey
            var vIndex: [VerseIndexEntry] = []
            let estimatedVerseCount = surahs.reduce(0) { $0 + $1.ayahs.count }
            vIndex.reserveCapacity(estimatedVerseCount)

            for surah in surahs {
                for ayah in surah.ayahs {
                    if Task.isCancelled { return }
                    // surahID is REQUIRED for beta riwayat - without it both reads silently fall
                    // back to Hafs and the index desyncs from what the reader displays.
                    let raw = ayah.textArabic(for: displayQiraah, surahID: surah.id)
                    let clean = ayah.textCleanArabic(for: displayQiraah, surahID: surah.id)
                    vIndex.append(
                        self.makeVerseIndexEntry(
                            surahID: surah.id,
                            ayahID: ayah.id,
                            rawArabic: raw,
                            cleanArabic: clean,
                            englishSaheeh: ayah.textEnglishSaheeh,
                            englishMustafa: ayah.textEnglishMustafa,
                            transliteration: ayah.textTransliteration
                        )
                    )
                }
                await Task.yield()
            }

            if Task.isCancelled { return }

            let finalizedVerseIndex = vIndex
            let finalizedAllVerseIndices = Array(finalizedVerseIndex.indices)
            let currentQiraahKey = await MainActor.run { self.settings.displayQiraahForArabic ?? "" }
            guard currentQiraahKey == qiraahKey else { return }

            await MainActor.run {
                self.verseIndex = finalizedVerseIndex
                self.allVerseIndices = finalizedAllVerseIndices
                self.cachedVerseIndexQiraah = qiraahKey
                self.cachedVerseSearchSnapshot = nil
                self.isVerseSearchReady = true
            }
        }
        #endif
    }

    #if !os(watchOS)
    /// The missed-invalidation escape hatch for `verseSearchSnapshot()`: the index's qiraah didn't match the
    /// display qiraah and no scheduled build is in flight, so rebuild off-main from a main-thread copy of
    /// `quran` and publish atomically - the same shape as `scheduleVerseSearchIndexBuild`, minus the
    /// dynamic-cache save (this path is a repair, not a normal load). MUST be called on the main actor
    /// (it snapshots `quran` there).
    @MainActor
    private func scheduleFallbackVerseIndexRebuild(qiraahKey: String) {
        searchIndexBuildTask?.cancel()

        // A main-thread COW handoff, like the search snapshot itself: the task reads only this immutable
        // local copy, never the live published array.
        let surahs = quran

        searchIndexBuildTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            let displayQiraah = qiraahKey.isEmpty ? nil : qiraahKey
            var vIndex: [VerseIndexEntry] = []
            vIndex.reserveCapacity(surahs.reduce(0) { $0 + $1.ayahs.count })

            for surah in surahs {
                for ayah in surah.ayahs {
                    if Task.isCancelled { return }
                    vIndex.append(
                        self.makeVerseIndexEntry(
                            surahID: surah.id,
                            ayahID: ayah.id,
                            rawArabic: ayah.textArabic(for: displayQiraah, surahID: surah.id),
                            cleanArabic: ayah.textCleanArabic(for: displayQiraah, surahID: surah.id),
                            englishSaheeh: ayah.textEnglishSaheeh,
                            englishMustafa: ayah.textEnglishMustafa,
                            transliteration: ayah.textTransliteration
                        )
                    )
                }
                await Task.yield()
            }

            if Task.isCancelled { return }

            let finalizedVerseIndex = vIndex
            let finalizedAllVerseIndices = Array(finalizedVerseIndex.indices)
            let currentQiraahKey = await MainActor.run { self.settings.displayQiraahForArabic ?? "" }
            guard currentQiraahKey == qiraahKey else { return }

            await MainActor.run {
                self.verseIndex = finalizedVerseIndex
                self.allVerseIndices = finalizedAllVerseIndices
                self.cachedVerseIndexQiraah = qiraahKey
                self.cachedVerseSearchSnapshot = nil
                self.isVerseSearchReady = true
            }
        }
    }
    #endif

    private func startLoading() {
        guard loadTask == nil else { return }
        // `.userInitiated`: this fires at app launch (QuranData.shared is created up front) while the app
        // opens on the Adhan tab. It runs on a BACKGROUND thread (it's a detached parse + index build), so it
        // doesn't block the Adhan tab's first paint - and the heavy launch *main-thread* work (prayer-time
        // scheduling) is now deferred off the synchronous path separately, so this no longer contends with it.
        // The higher QoS gets the Quran data ready before the user navigates to the Quran tab, so opening it
        // doesn't catch the load mid-flight (which lands data while the view is on screen and stutters). The
        // search-index build remains a separate lower-priority task.
        loadTask = Task(priority: .userInitiated) { [weak self] in
            await self?.load()
        }
    }

    /// Re-merge the data when the user toggles "show qiraah" on (qiraat overlays are skipped at launch
    /// for speed when it is off). Runs in the background and keeps the already-shown data visible until
    /// the new data is ready, so there is no lag or launch-screen flash. No-op until the first load finishes.
    func reloadForQiraahAvailabilityChange() {
        guard loadState == .ready || loadState == .failed else { return }
        loadTask?.cancel()
        loadTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }
            try? await self.loadAttempt()
            await MainActor.run { self.loadTask = nil }
        }
    }

    private func invalidateDerivedResultCaches() {
        cachedSajdahAyahResults = nil
        cachedMuqattaatAyahResults = nil
        cachedPageAyahResults = nil
        invalidatePageJuzResultMemos()
    }

    private func searchTokens(from cleanedText: String) -> [String] {
        cleanedText
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private static let arabicTashkeelCharacterSet: CharacterSet = {
        var set = CharacterSet()
        set.insert(charactersIn: "\u{0610}"..."\u{061A}")
        set.insert(charactersIn: "\u{064B}"..."\u{065F}")
        set.insert(charactersIn: "\u{0670}"..."\u{0670}")
        set.insert(charactersIn: "\u{06D6}"..."\u{06ED}")
        return set
    }()

    private func arabicTashkeelBlob(_ text: String) -> String {
        String(text.unicodeScalars.filter { Self.arabicTashkeelCharacterSet.contains($0) })
    }

    private func exactPhraseBlob(_ text: String) -> String {
        text
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func makeVerseIndexEntry(
        surahID: Int,
        ayahID: Int,
        rawArabic: String,
        cleanArabic: String,
        englishSaheeh: String,
        englishMustafa: String,
        transliteration: String
    ) -> VerseIndexEntry {
        // Three Arabic lanes per ayah: the raw fold (dagger alif → full ا: "يانسا", "ابراهيم"), the
        // pre-cleaned display text, and the dagger-DROPPED fold ("ينسا", "ابرهيم") - so typed spellings
        // with or without the alif the mushaf writes as a superscript both land. The dagger lane is
        // dropped when it folds to the same bytes as the raw one (~30% of ayahs carry no dagger alif),
        // so those entries don't pay for a duplicate copy of their own text.
        let rawArabicFold = settings.cleanSearch(rawArabic)
        let daggerlessFold = settings.cleanSearch(rawArabic.removingDaggerAlifForSearch)
        let arabicBlob = ([rawArabicFold, settings.cleanSearch(cleanArabic)]
            + (daggerlessFold == rawArabicFold ? [] : [daggerlessFold]))
            .joined(separator: " ")
        let silentArabicBlob = [rawArabic, cleanArabic]
            .map { settings.cleanSearchIgnoringSilentArabicLetters($0) }
            .joined(separator: " ")
        let englishBlob = [englishSaheeh, englishMustafa, transliteration]
            .map { settings.cleanSearch($0) }
            .joined(separator: " ")
        let arabicTokens = searchTokens(from: arabicBlob)
        let silentArabicTokens = searchTokens(from: silentArabicBlob)
        let englishTokens = searchTokens(from: englishBlob)

        return VerseIndexEntry(
            id: "\(surahID):\(ayahID)",
            surah: surahID,
            ayah: ayahID,
            arabicTashkeelBlob: arabicTashkeelBlob(rawArabic),
            englishExactBlob: exactPhraseBlob([englishSaheeh, englishMustafa, transliteration].joined(separator: " ")),
            arabicBlob: arabicBlob,
            silentArabicBlob: silentArabicBlob,
            hamzaArabicBlob: Settings.HamzaPrecisionFilter.corpusLanes(for: [rawArabic, cleanArabic]),
            englishBlob: englishBlob,
            arabicTokens: arabicTokens,
            silentArabicTokens: silentArabicTokens,
            englishTokens: englishTokens
        )
    }

    func waitUntilLoaded() async {
        while true {
            let state = await MainActor.run { self.loadState }
            if state == .ready || state == .failed {
                return
            }
            if loadTask == nil {
                return
            }
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
    }

    func waitUntilCoreLoaded() async {
        while true {
            let state = await MainActor.run { self.loadState }
            if state == .buildingIndexes || state == .ready || state == .failed {
                return
            }
            if loadTask == nil {
                return
            }
            // A cancelled caller must leave: `Task.sleep` throws at once after cancellation, and the
            // swallowed throw turned this into a hot spin until the core finished loading.
            if Task.isCancelled { return }
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
    }

    var isReadyForUI: Bool {
        loadState == .ready
    }

    var isCoreReadyForUI: Bool {
        loadState == .buildingIndexes || loadState == .ready
    }

    var shouldWaitForFullLaunchReadiness: Bool {
        // Reveal as soon as the core Quran data is applied (loadState == .buildingIndexes). The verse-search
        // index finishes building a moment later in the background (see `scheduleVerseSearchIndexBuild`),
        // and search shows a brief "preparing" state until it does - no reason to hold the launch screen.
        false
    }

    var hasLoadFailed: Bool {
        loadState == .failed
    }

    private func load() async {
        await MainActor.run {
            self.loadState = .loadingCore
            self.loadErrorDescription = nil
            self.isVerseSearchReady = false
        }

        // Off the load path: reclaim the disk the retired plist cache layer left behind.
        Task.detached(priority: .background) {
            Self.purgeLegacyDerivedCaches()
        }

        // While the core load already owns a background context: pay the tajweed rule-tree decode now
        // if coloring is on, so the first colored ayah doesn't hitch the main thread with it.
        // (The AI-search NLEmbedding probe is prewarmed similarly, from the app root - see Al-IslamApp;
        // SemanticSearch.swift isn't compiled into every target this file is.)
        if await MainActor.run(body: { Settings.shared.showTajweedColors }) {
            TajweedStore.prewarmRuleTrees()
        }

        defer {
            Task { @MainActor in
                self.loadTask = nil
            }
        }

        let maxAttempts = 2
        for attempt in 1...maxAttempts {
            do {
                try await loadAttempt()
                await MainActor.run {
                    self.loadState = .ready
                    // The Quran-widget snapshot writer silently no-ops while `quran` is still empty, and
                    // its other triggers (page flip, backgrounding) can all fire before the load finishes -
                    // after which nothing retried, so the widgets sat on sample data until the next reading
                    // session. Data just became available: write the snapshot now.
                    if Settings.isAppProcess {
                        Settings.shared.refreshQuranWidgets()
                    }
                }
                return
            } catch {
                let message = "Failed to load Quran attempt \(attempt)/\(maxAttempts): \(error.localizedDescription)"
                logger.error("\(message)")
                await MainActor.run {
                    self.loadErrorDescription = message
                }

                if attempt < maxAttempts {
                    // Small backoff avoids repeated pressure spikes on slower devices.
                    try? await Task.sleep(nanoseconds: 180_000_000)
                    continue
                }
            }
        }

        await MainActor.run {
            self.loadState = .failed
        }
    }

    private func loadAttempt() async throws {
        // Most users never look at other qiraat, so decoding the 7 overlay columns on every launch is
        // wasted work. Only include them when the user actually shows qiraah (or has a non-Hafs display
        // selected). When they later enable it, `reloadForQiraahAvailabilityChange()` re-runs this in the
        // background so there is no lag.
        let includeQiraat = await MainActor.run { settings.showQiraahDetails || settings.displayQiraahForArabic != nil }

        // The bundled .qpk packs are the only source: what used to be 16.8 MB of JSON is 3.1 MB,
        // memory-mapped, with ayah text staying on disk until a block is actually read, and no JSON
        // decode at all. `QuranPackLoader` was verified to produce models identical to the retired
        // JSON path (216,885 assertions, with and without qiraat), so everything downstream - derived
        // metadata, boundary models, search indexes - is untouched and unaware.
        guard let packed = QuranPackLoader.quran(includeQiraat: includeQiraat) else {
            throw NSError(domain: "QuranData", code: 1, userInfo: [NSLocalizedDescriptionKey: "quran.qpk missing or unreadable"])
        }
        let surahsToPublish = applyDerivedSurahMetadata(to: packed, displayQiraah: nil)

        let (sIndex, aIndex) = buildIndexes(for: surahsToPublish)
        let preprocessedSections = buildPreprocessedSections(for: surahsToPublish)
        let surahSearchIndex = buildSurahSearchIndex(for: surahsToPublish)
        let countIndexes = buildSurahCountIndexes(for: surahsToPublish)
        let surahIDsByJuz = Dictionary(uniqueKeysWithValues: preprocessedSections.juzSections.map { ($0.juz.id, $0.surahIDs) })
        let juzSearchIndex = buildJuzSearchIndex()

        // Single main-actor hop so QuranView re-renders once, not twice (publishing `quran` and then the
        // index batch separately triggered two heavy first builds in a row).
        await MainActor.run {
            self.quran = surahsToPublish
            self.invalidateDerivedResultCaches()
            self.surahIndex = sIndex
            self.ayahIndex = aIndex
            self.pageSections = preprocessedSections.pageSections
            self.juzSections = preprocessedSections.juzSections
            self.revelationOrderSurahIDs = preprocessedSections.revelationOrderSurahIDs
            self.surahSearchIndex = surahSearchIndex
            self.surahIDsByAyahCount = countIndexes.ayah
            self.surahIDsByPageCount = countIndexes.page
            self.surahIDsByJuz = surahIDsByJuz
            self.juzSearchIndex = juzSearchIndex
            self.loadState = .buildingIndexes
        }

        let displayQiraah = await MainActor.run { settings.displayQiraahForArabic }

        let boundaryModels = buildBoundaryModels(for: surahsToPublish, displayQiraah: displayQiraah)
        let firstAyahLookups = buildFirstAyahLookups(for: surahsToPublish, displayQiraah: displayQiraah)
        let finalizedQiraahKey = displayQiraah ?? ""

        await MainActor.run {
            self.verseIndex = []
            self.allVerseIndices = []
            self.cachedVerseIndexQiraah = finalizedQiraahKey
            self.surahBoundaryModels = boundaryModels
            self.cachedBoundaryQiraah = finalizedQiraahKey
            self.firstAyahByPage = firstAyahLookups.page
            self.firstAyahByJuz = firstAyahLookups.juz
            self.cachedFirstAyahLookupQiraah = finalizedQiraahKey
            self.isVerseSearchReady = false
        }

        scheduleVerseSearchIndexBuild(
            qiraahKey: finalizedQiraahKey,
            surahs: surahsToPublish
        )

        await MainActor.run {
            self.loadState = .ready
        }
    }

    private func applyDerivedSurahMetadata(to surahs: [Surah], displayQiraah: String?) -> [Surah] {
        guard !surahs.isEmpty else { return surahs }

        return surahs.enumerated().map { index, surah in
            let derivedLessThanOnePage: Bool = {
                if Self.forcedLessThanOnePageSurahIDs.contains(surah.id) { return true }
                if let explicit = surah.isLessThanOnePage { return explicit }
                guard surah.pageCount == 1 else { return false }
                guard index + 1 < surahs.count else { return false }

                let ayahsForQiraah = surah.ayahs.filter { $0.existsInQiraah(displayQiraah, surahID: surah.id) }
                guard let currentLastAyah = ayahsForQiraah.last,
                      let currentLastPage = currentLastAyah.page else {
                    return false
                }

                let nextSurah = surahs[index + 1]
                guard let nextFirstAyah = nextSurah.ayahs.first(where: { $0.existsInQiraah(displayQiraah, surahID: nextSurah.id) }),
                      let nextFirstPage = nextFirstAyah.page else {
                    return false
                }

                return currentLastPage == nextFirstPage
            }()

            return Surah(
                id: surah.id,
                idArabic: surah.idArabic,
                nameArabic: surah.nameArabic,
                nameTransliteration: surah.nameTransliteration,
                nameEnglish: surah.nameEnglish,
                similarNames: surah.similarNames,
                type: surah.type,
                numberOfAyahs: surah.numberOfAyahs,
                revelationOrder: surah.revelationOrder,
                revelationExceptions: surah.revelationExceptions,
                pageStart: surah.pageStart,
                pageEnd: surah.pageEnd,
                numberOfPages: surah.numberOfPages,
                isLessThanOnePage: derivedLessThanOnePage,
                firstJuz: surah.firstJuz,
                lastJuz: surah.lastJuz,
                juzs: surah.juzs,
                juzChangesWithinSurah: surah.juzChangesWithinSurah,
                ayahs: surah.ayahs
            )
        }
    }

    // NOTE: There is deliberately no synchronous rebuildVerseIndex() anymore. The full 6,236-entry index
    // build MUST run off-main (`scheduleVerseSearchIndexBuild` / `scheduleFallbackVerseIndexRebuild`):
    // running it inline on the main thread - which the search path once did on a keystroke - froze the app
    // long enough under Low Power Mode's CPU throttle for the watchdog to kill it.

    private func rebuildBoundaryModels() {
        let displayQiraah = settings.displayQiraahForArabic
        surahBoundaryModels = buildBoundaryModels(for: quran, displayQiraah: displayQiraah)
        cachedBoundaryQiraah = displayQiraah ?? ""
    }

    private func rebuildFirstAyahLookups() {
        let displayQiraah = settings.displayQiraahForArabic
        let lookups = buildFirstAyahLookups(for: quran, displayQiraah: displayQiraah)
        firstAyahByPage = lookups.page
        firstAyahByJuz = lookups.juz
        cachedFirstAyahLookupQiraah = displayQiraah ?? ""
    }

    private func boundaryText(from oldAyah: Ayah, to newAyah: Ayah, in surah: Surah?) -> String? {
        let pageChanged = oldAyah.page != newAyah.page
        let juzChanged = oldAyah.juz != newAyah.juz
        guard pageChanged || juzChanged else { return nil }

        if let page = newAyah.page, let juz = newAyah.juz {
            return "\(mushafPageLabel(forAbsolutePage: page, in: surah)) • Juz \(juz)"
        }
        if let page = newAyah.page {
            return mushafPageLabel(forAbsolutePage: page, in: surah)
        }
        if let juz = newAyah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    private func boundaryText(for ayah: Ayah, in surah: Surah?) -> String? {
        if let page = ayah.page, let juz = ayah.juz {
            return "\(mushafPageLabel(forAbsolutePage: page, in: surah)) • Juz \(juz)"
        }
        if let page = ayah.page {
            return mushafPageLabel(forAbsolutePage: page, in: surah)
        }
        if let juz = ayah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    private func boundaryStyle(pageChanged: Bool, juzChanged: Bool) -> BoundaryDividerStyle {
        if pageChanged {
            return juzChanged ? .allAccent : .pageAccentJuzSecondary
        }
        if juzChanged {
            return .allAccent
        }
        return .allSecondary
    }

    private func dividerModel(from text: String, style: BoundaryDividerStyle) -> BoundaryDividerModel {
        if let juzRange = text.range(of: "Juz ") {
            let prefix = String(text[..<juzRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if prefix.isEmpty {
                return BoundaryDividerModel(
                    text: text,
                    pageSegment: text,
                    juzSegment: nil,
                    style: style
                )
            }
            let pageSegment = prefix.trimmingCharacters(in: CharacterSet(charactersIn: " -•").union(.whitespacesAndNewlines))
            let juzSegment = String(text[juzRange.lowerBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            return BoundaryDividerModel(
                text: text,
                pageSegment: pageSegment,
                juzSegment: juzSegment,
                style: style
            )
        }

        return BoundaryDividerModel(
            text: text,
            pageSegment: text,
            juzSegment: nil,
            style: style
        )
    }

    private func buildBoundaryModels(for surahs: [Surah], displayQiraah: String?) -> [Int: SurahBoundaryModel] {
        var result = [Int: SurahBoundaryModel]()
        result.reserveCapacity(surahs.count)

        for (index, surah) in surahs.enumerated() {
            let ayahsForQiraah = surah.ayahs.filter { $0.existsInQiraah(displayQiraah, surahID: surah.id) }
            guard !ayahsForQiraah.isEmpty else {
                result[surah.id] = SurahBoundaryModel(
                    startDivider: nil,
                    startDividerHighlighted: false,
                    dividerBeforeAyah: [:],
                    endOfSurahDivider: nil,
                    endDivider: nil,
                    endDividerHighlighted: false
                )
                continue
            }

            let startDividerText = ayahsForQiraah.first.flatMap { boundaryText(for: $0, in: surah) }
            let startDividerHighlighted: Bool = {
                guard index > 0,
                      let firstAyah = ayahsForQiraah.first else { return false }
                let previousSurah = surahs[index - 1]
                let previousLastAyah = previousSurah.ayahs.last { $0.existsInQiraah(displayQiraah, surahID: previousSurah.id) }
                guard let previousLastAyah else { return false }
                return previousLastAyah.page != firstAyah.page || previousLastAyah.juz != firstAyah.juz
            }()
            let startDividerStyle: BoundaryDividerStyle = {
                if surah.id == 1 { return .allGreen }
                guard index > 0,
                      let firstAyah = ayahsForQiraah.first else { return .allSecondary }
                let previousSurah = surahs[index - 1]
                let previousLastAyah = previousSurah.ayahs.last { $0.existsInQiraah(displayQiraah, surahID: previousSurah.id) }
                guard let previousLastAyah else { return .allSecondary }
                return boundaryStyle(
                    pageChanged: previousLastAyah.page != firstAyah.page,
                    juzChanged: previousLastAyah.juz != firstAyah.juz
                )
            }()

            var dividerBeforeAyah = [Int: BoundaryDividerModel]()
            if ayahsForQiraah.count > 1 {
                for i in 1..<ayahsForQiraah.count {
                    let prev = ayahsForQiraah[i - 1]
                    let current = ayahsForQiraah[i]
                    if let text = boundaryText(from: prev, to: current, in: surah) {
                        dividerBeforeAyah[current.id] = dividerModel(
                            from: text,
                            style: boundaryStyle(pageChanged: prev.page != current.page, juzChanged: prev.juz != current.juz)
                        )
                    }
                }
            }

            var endDividerText: String? = nil
            var endDividerHighlighted = false
            var endOfSurahDividerText: String? = nil
            var endBoundaryJuzChanged = false
            var endBoundaryPageChanged = false
            var nextFirstAyah: Ayah? = nil
            if index + 1 < surahs.count {
                let nextSurah = surahs[index + 1]
                if let lastAyah = ayahsForQiraah.last,
                   let nextAyah = nextSurah.ayahs.first(where: { $0.existsInQiraah(displayQiraah, surahID: nextSurah.id) }) {
                    nextFirstAyah = nextAyah
                    // Cross-surah boundary: the page belongs to the next surah, so it is shown without a
                    // surah-relative annotation - an "(N)" here would read as the next surah's page count.
                    endDividerText = boundaryText(from: lastAyah, to: nextAyah, in: nil)
                    endBoundaryPageChanged = lastAyah.page != nextAyah.page
                    endBoundaryJuzChanged = lastAyah.juz != nextAyah.juz
                    endDividerHighlighted = lastAyah.page != nextAyah.page || lastAyah.juz != nextAyah.juz
                }
            }

            if let nextFirstAyah {
                endOfSurahDividerText = boundaryText(for: nextFirstAyah, in: nil)
            } else if let lastAyah = ayahsForQiraah.last {
                endOfSurahDividerText = boundaryText(for: lastAyah, in: nil)
            }
            let endDividerStyle = boundaryStyle(pageChanged: endBoundaryPageChanged, juzChanged: endBoundaryJuzChanged)
            let endOfSurahDividerStyle: BoundaryDividerStyle = {
                if surah.id == 114 { return .allGreen }
                return endDividerStyle
            }()

            result[surah.id] = SurahBoundaryModel(
                startDivider: startDividerText.map { dividerModel(from: $0, style: startDividerStyle) },
                startDividerHighlighted: startDividerHighlighted,
                dividerBeforeAyah: dividerBeforeAyah,
                endOfSurahDivider: endOfSurahDividerText.map { dividerModel(from: $0, style: endOfSurahDividerStyle) },
                endDivider: endDividerText.map { dividerModel(from: $0, style: endDividerStyle) },
                endDividerHighlighted: endDividerHighlighted
            )
        }

        return result
    }

    private func buildIndexes(for surahs: [Surah]) -> ([Int:Int], [[Int:Int]]) {
        let sIndex = Dictionary(uniqueKeysWithValues: surahs.enumerated().map { ($1.id, $0) })
        let aIndex = surahs.map { surah in
            Dictionary(uniqueKeysWithValues: surah.ayahs.enumerated().map { ($1.id, $0) })
        }
        return (sIndex, aIndex)
    }

    private func buildSurahSearchIndex(for surahs: [Surah]) -> [SurahSearchIndexEntry] {
        surahs.map { surah in
            let searchableBlob = [
                settings.cleanSearch(surah.nameArabic),
                settings.cleanSearch(surah.nameTransliteration),
                settings.cleanSearch(surah.nameEnglish),
                surah.normalizedSearchNames.map { settings.cleanSearch($0) }.joined(separator: " "),
                settings.cleanSearch(String(surah.id)),
                settings.cleanSearch(surah.idArabic)
            ].joined(separator: " ")
            let compactSearchableBlob = searchableBlob.replacingOccurrences(of: " ", with: "")

            return SurahSearchIndexEntry(
                surahID: surah.id,
                nameEnglishUpper: surah.nameEnglish.uppercased(),
                nameTransliterationUpper: surah.nameTransliteration.uppercased(),
                searchableBlob: searchableBlob,
                compactSearchableBlob: compactSearchableBlob
            )
        }
    }

    private func buildSurahCountIndexes(for surahs: [Surah]) -> (ayah: [Int: [Int]], page: [Int: [Int]]) {
        var ayah = [Int: [Int]]()
        var page = [Int: [Int]]()

        for surah in surahs {
            ayah[surah.numberOfAyahs, default: []].append(surah.id)
            page[surah.pageCount, default: []].append(surah.id)
        }

        return (ayah: ayah, page: page)
    }

    private func buildJuzSearchIndex() -> [JuzSearchIndexEntry] {
        Self.juzList.map { juz in
            let searchableBlob = [
                settings.cleanSearch(juz.nameArabic),
                settings.cleanSearch(juz.nameTransliteration),
                settings.cleanSearch("juz \(juz.id)"),
                settings.cleanSearch("juz\(juz.id)"),
                settings.cleanSearch("para \(juz.id)")
            ].joined(separator: " ")

            return JuzSearchIndexEntry(
                juzID: juz.id,
                searchableBlob: searchableBlob,
                compactSearchableBlob: searchableBlob.replacingOccurrences(of: " ", with: "")
            )
        }
    }

    private func buildFirstAyahLookups(
        for surahs: [Surah],
        displayQiraah: String?
    ) -> (
        page: [Int: (surah: Int, ayah: Int)],
        juz: [Int: (surah: Int, ayah: Int)]
    ) {
        var pageLookup = [Int: (surah: Int, ayah: Int)]()
        var juzLookup = [Int: (surah: Int, ayah: Int)]()

        for surah in surahs {
            for ayah in surah.ayahs where ayah.existsInQiraah(displayQiraah, surahID: surah.id) {
                if let page = ayah.page, pageLookup[page] == nil {
                    pageLookup[page] = (surah: surah.id, ayah: ayah.id)
                }
                if let juz = ayah.juz, juzLookup[juz] == nil {
                    juzLookup[juz] = (surah: surah.id, ayah: ayah.id)
                }
            }
        }

        #if DEBUG
        // Data-regression tripwire. Everything downstream trusts `ayah.page`/`ayah.juz` from the JSON,
        // and a gap fails SILENTLY at runtime (a page query just returns nothing, the Pages list skips
        // the page with no indication). Only meaningful for the full corpus - a partial build or an
        // in-flight qiraah merge legitimately has holes.
        if !surahs.isEmpty, surahs.count == 114 {
            let expectedLastPage = surahs.last?.pageEnd ?? 604
            let missingPages = (1...expectedLastPage).filter { pageLookup[$0] == nil }
            let missingJuz = (1...30).filter { juzLookup[$0] == nil }
            if !missingPages.isEmpty { logger.debug("Mushaf page map has gaps: \(missingPages)") }
            if !missingJuz.isEmpty { logger.debug("Juz map has gaps: \(missingJuz)") }
        }
        #endif

        return (page: pageLookup, juz: juzLookup)
    }

    private func buildPreprocessedSections(for surahs: [Surah]) -> (
        pageSections: [PageSectionData],
        juzSections: [JuzSectionData],
        revelationOrderSurahIDs: [Int]
    ) {
        let pageSections: [PageSectionData] = {
            let pairs = surahs.compactMap { surah -> (Int, Int)? in
                guard let page = surah.pageStart ?? surah.ayahs.compactMap(\.page).min() else { return nil }
                return (page, surah.id)
            }
            let grouped = Dictionary(grouping: pairs, by: { $0.0 })
            return grouped.keys.sorted().map { page in
                let surahIDs = (grouped[page] ?? []).map(\.1).sorted()
                return PageSectionData(page: page, surahIDs: surahIDs)
            }
        }()

        let juzSections: [JuzSectionData] = Self.juzList.sorted(by: { $0.id < $1.id }).map { juz in
            let surahIDs = surahs
                .filter { $0.id >= juz.startSurah && $0.id <= juz.endSurah }
                .map(\.id)
            let rows = buildPreprocessedJuzRows(juz: juz, surahs: surahs)
            return JuzSectionData(juz: juz, surahIDs: surahIDs, rows: rows)
        }

        let revelationOrderSurahIDs = surahs
            .sorted {
                let left = $0.revelationOrder ?? Int.max
                let right = $1.revelationOrder ?? Int.max
                if left == right {
                    return $0.id < $1.id
                }
                return left < right
            }
            .map(\.id)

        return (pageSections, juzSections, revelationOrderSurahIDs)
    }

    private func buildPreprocessedJuzRows(juz: Juz, surahs: [Surah]) -> [JuzSectionData.Row] {
        let surahByID = Dictionary(uniqueKeysWithValues: surahs.map { ($0.id, $0) })
        var rows: [JuzSectionData.Row] = []

        guard juz.startSurah <= juz.endSurah else { return rows }
        for surahID in juz.startSurah...juz.endSurah {
            guard let surah = surahByID[surahID] else { continue }
            let totalAyahs = surah.numberOfAyahs

            if surahID == juz.startSurah && surahID == juz.endSurah {
                rows.append(.init(surahID: surahID, kind: .start(ayah: juz.startAyah)))
                if juz.endAyah < totalAyahs {
                    rows.append(.init(surahID: surahID, kind: .end(ayah: juz.endAyah)))
                }
                continue
            }

            if surahID == juz.startSurah {
                rows.append(.init(surahID: surahID, kind: .start(ayah: juz.startAyah)))
                continue
            }

            if surahID == juz.endSurah {
                // Keep one plain surah entry first so this surah is not shown only as an "end" row.
                rows.append(.init(surahID: surahID, kind: .plain))
                if juz.endAyah < totalAyahs {
                    rows.append(.init(surahID: surahID, kind: .end(ayah: juz.endAyah)))
                }
                continue
            }

            rows.append(.init(surahID: surahID, kind: .plain))
        }

        return rows
    }
    
    func surah(_ number: Int) -> Surah? {
        surahIndex[number].map { quran[$0] }
    }

    // MARK: - Surah Info (bundled, lazily loaded)

    private var surahInfosCache: [Int: [SurahInfoSource]] = [:]

    /// The available info sources (e.g. Maududi, Ibn Ashur) for a surah, loaded once from surahinfos.qpk
    /// and cached. Returns an empty array when no info is bundled for that surah.
    func surahInfoSources(for surahNumber: Int) -> [SurahInfoSource] {
        if let cached = surahInfosCache[surahNumber] { return cached }
        // One block per surah in the pack, decompressed on first request for exactly that surah -
        // opening "About this surah" no longer decompresses the other 113.
        let sources = QuranPackLoader.surahInfo(surah: surahNumber)
        surahInfosCache[surahNumber] = sources
        return sources
    }

    func ayah(surah: Int, ayah: Int) -> Ayah? {
        guard let sIdx = surahIndex[surah], let aIdx = ayahIndex[sIdx][ayah] else { return nil }
        return quran[sIdx].ayahs[aIdx]
    }

    func resolveSurahIdentifier(_ raw: String) -> Surah? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let number = Int(trimmed) ?? arabicToEnglishNumber(trimmed), (1...114).contains(number) {
            return surah(number)
        }

        let cleaned = settings.cleanSearch(trimmed)
        let compactCleaned = cleaned.replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty else { return nil }

        if let exact = quran.first(where: { surah in
            let exactNames = [
                settings.cleanSearch(surah.nameArabic),
                settings.cleanSearch(surah.nameTransliteration),
                settings.cleanSearch(surah.nameEnglish)
            ] + surah.normalizedSearchNames.map { settings.cleanSearch($0) }
            let compactExactNames = exactNames.map { $0.replacingOccurrences(of: " ", with: "") }
            return exactNames.contains(cleaned) || compactExactNames.contains(compactCleaned)
        }) {
            return exact
        }

        return surahSearchIndex.first(where: {
            $0.searchableBlob.contains(cleaned) || $0.compactSearchableBlob.contains(compactCleaned)
        })
            .flatMap { surah($0.surahID) }
    }

    func resolveJuzIdentifier(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let number = Int(trimmed) ?? arabicToEnglishNumber(trimmed), (1...30).contains(number) {
            return number
        }

        let cleaned = settings.cleanSearch(trimmed)
        let compactCleaned = cleaned.replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty else { return nil }

        if let exact = juzSearchIndex.first(where: {
            $0.searchableBlob.split(separator: " ").map(String.init).contains(cleaned)
                || $0.compactSearchableBlob.split(separator: " ").map(String.init).contains(compactCleaned)
        }) {
            return exact.juzID
        }

        return juzSearchIndex.first(where: {
            $0.searchableBlob.contains(cleaned) || $0.compactSearchableBlob.contains(compactCleaned)
        })?.juzID
    }

    func surahs(inJuz juzID: Int?) -> [Surah] {
        guard let juzID else { return [] }
        return (surahIDsByJuz[juzID] ?? []).compactMap { surah($0) }
    }

    struct JuzStats: Equatable {
        let surahCount: Int
        let ayahCount: Int
        let wordCount: Int
        let letterCount: Int
        let pageCount: Int
    }

    /// Aggregate counts for a single juz, computed from the ayahs actually assigned to it
    /// (`ayah.juz == juz.id`) so surahs that straddle a juz boundary are split correctly.
    func juzStats(for juz: Juz) -> JuzStats {
        var surahIDs = Set<Int>()
        var ayahCount = 0
        var wordCount = 0
        var letterCount = 0
        var pages = Set<Int>()

        for surahID in juz.startSurah...juz.endSurah {
            guard let surah = surah(surahID) else { continue }
            for ayah in surah.ayahs where ayah.juz == juz.id {
                surahIDs.insert(surahID)
                ayahCount += 1
                wordCount += ayah.wordCount
                letterCount += ayah.letterCount
                if let page = ayah.page { pages.insert(page) }
            }
        }

        return JuzStats(
            surahCount: surahIDs.count,
            ayahCount: ayahCount,
            wordCount: wordCount,
            letterCount: letterCount,
            pageCount: pages.count
        )
    }

    func surahsMatchingCount(ayahFilter: CountFilter?, pageFilter: CountFilter?) -> [Surah] {
        func matchingIDs(from index: [Int: [Int]], filter: CountFilter?) -> Set<Int>? {
            guard let filter else { return nil }

            if filter.value < 1 { return [] }
            switch filter.op {
            case .equal:
                return Set(index[filter.value] ?? [])
            case .lessThan:
                return Set(index.filter { $0.key < filter.value }.flatMap { $0.value })
            case .lessThanOrEqual:
                return Set(index.filter { $0.key <= filter.value }.flatMap { $0.value })
            case .greaterThan:
                return Set(index.filter { $0.key > filter.value }.flatMap { $0.value })
            case .greaterThanOrEqual:
                return Set(index.filter { $0.key >= filter.value }.flatMap { $0.value })
            }
        }

        let ayahIDs = matchingIDs(from: surahIDsByAyahCount, filter: ayahFilter)
        let pageIDs = matchingIDs(from: surahIDsByPageCount, filter: pageFilter)

        let selectedIDs: Set<Int>
        switch (ayahIDs, pageIDs) {
        case let (a?, p?): selectedIDs = a.intersection(p)
        case let (a?, nil): selectedIDs = a
        case let (nil, p?): selectedIDs = p
        case (nil, nil):
            return quran
        }

        return quran.filter { selectedIDs.contains($0.id) }
    }

    func sajdahAyahResults() -> [(surah: Surah, ayah: Ayah)] {
        if let cachedSajdahAyahResults {
            return cachedSajdahAyahResults
        }

        let results = quran.flatMap { surah in
            surah.ayahs.compactMap { ayah in
                ayah.textHafs.contains("۩") ? (surah: surah, ayah: ayah) : nil
            }
        }
        cachedSajdahAyahResults = results
        return results
    }

    func muqattaatAyahResults() -> [(surah: Surah, ayah: Ayah)] {
        if let cachedMuqattaatAyahResults {
            return cachedMuqattaatAyahResults
        }

        let openingSurahs = TajweedRules.surahsOpeningMuqattaat
        let results = quran
            .filter { openingSurahs.contains($0.id) }
            .flatMap { surah -> [(surah: Surah, ayah: Ayah)] in
                if surah.id == 42 {
                    return surah.ayahs
                        .filter { (1...2).contains($0.id) }
                        .map { (surah: surah, ayah: $0) }
                }

                guard let firstAyah = surah.ayahs.first(where: { $0.id == 1 }) else { return [] }
                return [(surah: surah, ayah: firstAyah)]
            }
        cachedMuqattaatAyahResults = results
        return results
    }

    /// First ayah of every mushaf page, in page order - used by the "Pages" browse mode (Sajdah-style).
    func pageAyahResults() -> [(page: Int, surah: Surah, ayah: Ayah)] {
        if let cachedPageAyahResults {
            return cachedPageAyahResults
        }

        var seenPages = Set<Int>()
        var results: [(page: Int, surah: Surah, ayah: Ayah)] = []
        for surah in quran {
            for ayah in surah.ayahs {
                guard let page = ayah.page, !seenPages.contains(page) else { continue }
                seenPages.insert(page)
                results.append((page: page, surah: surah, ayah: ayah))
            }
        }
        results.sort { $0.page < $1.page }
        cachedPageAyahResults = results
        return results
    }

    /// One-entry memos for the page/juz search results: the search sections re-evaluate these on every
    /// body pass while a "page N" / "juz N" query is active, and the unmemoized version flatMapped all
    /// 6,236 ayahs per render. Invalidated alongside the other derived caches when `quran` reloads.
    private var cachedAyahsOnPage: (page: Int, results: [(surah: Surah, ayah: Ayah)])?
    private var cachedAyahsInJuz: (juz: Int, results: [(surah: Surah, ayah: Ayah)])?

    func invalidatePageJuzResultMemos() {
        cachedAyahsOnPage = nil
        cachedAyahsInJuz = nil
    }

    /// Every ayah on a given mushaf page, in order - used by page search results. Page numbers ascend
    /// monotonically through the mushaf, so the scan skips whole surahs before the page and stops at
    /// the first ayah past it.
    func ayahs(onPage page: Int) -> [(surah: Surah, ayah: Ayah)] {
        if let cached = cachedAyahsOnPage, cached.page == page { return cached.results }
        var results: [(surah: Surah, ayah: Ayah)] = []
        outer: for surah in quran {
            if let end = surah.pageEnd, end < page { continue }
            for ayah in surah.ayahs {
                guard let p = ayah.page else { continue }
                if p == page {
                    results.append((surah: surah, ayah: ayah))
                } else if p > page {
                    break outer
                }
            }
        }
        cachedAyahsOnPage = (page, results)
        return results
    }

    /// Every ayah in a given juz, in order - used by juz search results. Juz numbers ascend through the
    /// corpus the same way pages do.
    func ayahs(inJuz juz: Int) -> [(surah: Surah, ayah: Ayah)] {
        if let cached = cachedAyahsInJuz, cached.juz == juz { return cached.results }
        var results: [(surah: Surah, ayah: Ayah)] = []
        outer: for surah in quran {
            for ayah in surah.ayahs {
                guard let j = ayah.juz else { continue }
                if j == juz {
                    results.append((surah: surah, ayah: ayah))
                } else if j > juz {
                    break outer
                }
            }
        }
        cachedAyahsInJuz = (juz, results)
        return results
    }

    func filteredSurahs(query rawQuery: String) -> [Surah] {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return quran }

        let cleanedQuery = settings.cleanSearch(trimmed.replacingOccurrences(of: ":", with: ""))
        let upperQuery = trimmed.uppercased()
        let normalizedQuery = cleanedQuery.replacingOccurrences(of: " ", with: "")
        let surahAyahPair = trimmed.split(separator: ":").map(String.init)
        let numericQuery: Int? = {
            if surahAyahPair.count == 2 {
                if let resolved = resolveSurahIdentifier(surahAyahPair[0]) {
                    return resolved.id
                }
                return Int(surahAyahPair[0]) ?? arabicToEnglishNumber(surahAyahPair[0])
            }
            return Int(cleanedQuery) ?? arabicToEnglishNumber(cleanedQuery)
        }()

        let revelationSearchMode: RevelationSearchMode? = {
            guard !normalizedQuery.isEmpty else { return nil }

            // Treat the query as a revelation-place filter only when it's a deliberate word, not an incidental
            // prefix. Typing a single letter like "m" used to prefix-match "makkah" and silently swap the whole
            // list for all 86 Meccan surahs (and "d" → every Madinan one). Require at least 4 characters before
            // a *partial* alias counts; a fully-typed alias ("makki", "madina", …) still matches at any point.
            let minRevelationPrefix = 4
            func hits(_ aliases: Set<String>) -> Bool {
                aliases.contains { alias in
                    normalizedQuery.hasPrefix(alias)
                        || (normalizedQuery.count >= minRevelationPrefix && alias.hasPrefix(normalizedQuery))
                }
            }

            if hits(Self.makkanAliases) { return .makkan }
            if hits(Self.madinanAliases) { return .madinan }

            return nil
        }()

        let matches: [Surah] = surahSearchIndex.compactMap { entry -> Surah? in
            if let revelationSearchMode {
                guard let s = surah(entry.surahID) else { return nil }
                switch revelationSearchMode {
                case .makkan:
                    return s.type == "makkan" ? s : nil
                case .madinan:
                    return s.type == "madinan" ? s : nil
                }
            }

            if let numericQuery, entry.surahID == numericQuery {
                return surah(entry.surahID)
            }
            if upperQuery.contains(entry.nameEnglishUpper)
                || upperQuery.contains(entry.nameTransliterationUpper)
                || entry.searchableBlob.contains(cleanedQuery)
                || entry.compactSearchableBlob.contains(normalizedQuery) {
                return surah(entry.surahID)
            }
            return nil
        }

        guard settings.quranSortMode == .revelation else {
            return matches
        }

        return matches.sorted {
            let left = $0.revelationOrder ?? Int.max
            let right = $1.revelationOrder ?? Int.max
            if left == right {
                return $0.id < $1.id
            }
            return left < right
        }
    }

    func firstAyahResult(page: Int? = nil, juz: Int? = nil) -> (surah: Surah, ayah: Ayah)? {
        guard page != nil || juz != nil else { return nil }

        let currentKey = settings.displayQiraahForArabic ?? ""
        if cachedFirstAyahLookupQiraah != currentKey {
            rebuildFirstAyahLookups()
        }

        if let page, let hit = firstAyahByPage[page], let s = surah(hit.surah), let a = ayah(surah: hit.surah, ayah: hit.ayah) {
            return (surah: s, ayah: a)
        }

        if let juz, let hit = firstAyahByJuz[juz], let s = surah(hit.surah), let a = ayah(surah: hit.surah, ayah: hit.ayah) {
            return (surah: s, ayah: a)
        }

        return nil
    }

    @MainActor
    func verseSearchSnapshot() -> VerseSearchSnapshot? {
        #if os(watchOS)
        return nil
        #else
        guard isVerseSearchReady else { return nil }
        let currentKey = settings.displayQiraahForArabic ?? ""
        if cachedVerseIndexQiraah != currentKey {
            // A missed invalidation (index built for another qiraah). This used to run the FULL 6,236-entry
            // rebuild synchronously right here, on the main thread, on a search KEYSTROKE - under Low Power
            // Mode's CPU throttle that is long enough for the watchdog to kill the app, which presents as
            // "search crashed when I retyped." Rebuild off-main instead: flip to not-ready (the search UI
            // shows its preparing state and re-runs automatically when this lands) and hand the build to the
            // same background pipeline every other rebuild uses.
            isVerseSearchReady = false
            cachedVerseSearchSnapshot = nil
            scheduleFallbackVerseIndexRebuild(qiraahKey: currentKey)
            return nil
        }
        guard !verseIndex.isEmpty else { return nil }

        // Reuse the immutable snapshot across keystrokes; it's nil'd whenever the index is (re)built, so a
        // stale one can't be returned. The qiraah guard is belt-and-suspenders against any missed invalidation.
        if let cached = cachedVerseSearchSnapshot, cached.qiraahKey == currentKey {
            return cached
        }

        let snapshot = VerseSearchSnapshot(
            qiraahKey: currentKey,
            verseIndex: verseIndex,
            allVerseIndices: allVerseIndices
        )
        cachedVerseSearchSnapshot = snapshot
        return snapshot
        #endif
    }

    func boundaryModel(forSurah surahID: Int) -> SurahBoundaryModel? {
        let currentKey = settings.displayQiraahForArabic ?? ""
        if cachedBoundaryQiraah != currentKey {
            rebuildBoundaryModels()
        }
        return surahBoundaryModels[surahID]
    }

    static let juzList: [Juz] = [
        Juz(id: 1,
            nameArabic: "الم",
            nameTransliteration: "Alif Lam Meem",
            startSurah: 1, startAyah: 1,
            endSurah: 2, endAyah: 141
        ),

        Juz(id: 2,
            nameArabic: "سَيَقُول",
            nameTransliteration: "Sayaqoolu",
            startSurah: 2, startAyah: 142,
            endSurah: 2, endAyah: 252
        ),

        Juz(id: 3,
            nameArabic: "تِلكَ ٱلرُّسُل",
            nameTransliteration: "Tilka Ar-Rusul",
            startSurah: 2, startAyah: 253,
            endSurah: 3, endAyah: 92
        ),

        Juz(id: 4,
            nameArabic: "كُلُّ ٱلطَّعَامِ",
            nameTransliteration: "Kullu At-Ta'am",
            startSurah: 3, startAyah: 93,
            endSurah: 4, endAyah: 23
        ),

        Juz(id: 5,
            nameArabic: "وَٱلمُحصَنَات",
            nameTransliteration: "Wal-Muhsanat",
            startSurah: 4, startAyah: 24,
            endSurah: 4, endAyah: 147
        ),

        Juz(id: 6,
            nameArabic: "لَا يُحِبُّ ٱللهُ",
            nameTransliteration: "Laa Yuhibbu Allahu",
            startSurah: 4, startAyah: 148,
            endSurah: 5, endAyah: 81
        ),

        Juz(id: 7,
            nameArabic: "لَتَجِدَنَّ أَشَدّ",
            nameTransliteration: "Latajidanna Ashadd",
            startSurah: 5, startAyah: 82,
            endSurah: 6, endAyah: 110
        ),

        Juz(id: 8,
            nameArabic: "وَلَو أَنَّنَا",
            nameTransliteration: "Walaw Annana",
            startSurah: 6, startAyah: 111,
            endSurah: 7, endAyah: 87
        ),

        Juz(id: 9,
            nameArabic: "قَالَ ٱلمَلَأُ",
            nameTransliteration: "Qala Al-Mala'u",
            startSurah: 7, startAyah: 88,
            endSurah: 8, endAyah: 40
        ),

        Juz(id: 10,
            nameArabic: "وَٱعلَمُوا",
            nameTransliteration: "Wa'alamoo",
            startSurah: 8, startAyah: 41,
            endSurah: 9, endAyah: 92
        ),

        Juz(id: 11,
            nameArabic: "إِنَّمَا ٱلسَّبِيلُ",
            nameTransliteration: "Innama As-Sabeel",
            startSurah: 9, startAyah: 93,
            endSurah: 11, endAyah: 5
        ),

        Juz(id: 12,
            nameArabic: "وَمَا مِن دَآبَّة",
            nameTransliteration: "Wamaa Min Daabbah",
            startSurah: 11, startAyah: 6,
            endSurah: 12, endAyah: 52
        ),

        Juz(id: 13,
            nameArabic: "وَمَا أُبَرِّئُ",
            nameTransliteration: "Wamaa Ubarri'u",
            startSurah: 12, startAyah: 53,
            endSurah: 14, endAyah: 52
        ),

        Juz(id: 14,
            nameArabic: "رُبَمَا",
            nameTransliteration: "Rubamaa",
            startSurah: 15, startAyah: 1,
            endSurah: 16, endAyah: 128
        ),

        Juz(id: 15,
            nameArabic: "سُبحَانَ ٱلَّذِى",
            nameTransliteration: "Subhaana Al-Ladhee",
            startSurah: 17, startAyah: 1,
            endSurah: 18, endAyah: 74
        ),

        Juz(id: 16,
            nameArabic: "قَالَ أَلَم",
            nameTransliteration: "Qala Alam",
            startSurah: 18, startAyah: 75,
            endSurah: 20, endAyah: 135
        ),

        Juz(id: 17,
            nameArabic: "ٱقتَرَبَ لِلنَّاسِ",
            nameTransliteration: "Iqtaraba Lin-Naas",
            startSurah: 21, startAyah: 1,
            endSurah: 22, endAyah: 78
        ),

        Juz(id: 18,
            nameArabic: "قَد أَفلَحَ",
            nameTransliteration: "Qad Aflaha",
            startSurah: 23, startAyah: 1,
            endSurah: 25, endAyah: 20
        ),

        Juz(id: 19,
            nameArabic: "وَقَالَ ٱلَّذِينَ",
            nameTransliteration: "Waqaala Al-Ladheena",
            startSurah: 25, startAyah: 21,
            endSurah: 27, endAyah: 55
        ),

        Juz(id: 20,
            nameArabic: "فَمَا كَانَ جَوَاب",
            nameTransliteration: "Fama Kaana Jawaab",
            startSurah: 27, startAyah: 56,
            endSurah: 29, endAyah: 45
        ),

        Juz(id: 21,
            nameArabic: "وَلَا تُجَٰدِلُوٓاْ",
            nameTransliteration: "Walaa Tujadiloo",
            startSurah: 29, startAyah: 46,
            endSurah: 33, endAyah: 30
        ),

        Juz(id: 22,
            nameArabic: "وَمَن يَّقنُت",
            nameTransliteration: "Waman Yaqnut",
            startSurah: 33, startAyah: 31,
            endSurah: 36, endAyah: 27
        ),

        Juz(id: 23,
            nameArabic: "وَمَآ أَنزَلۡنَا",
            nameTransliteration: "Wammaa Anzalnaa",
            startSurah: 36, startAyah: 28,
            endSurah: 39, endAyah: 31
        ),

        Juz(id: 24,
            nameArabic: "فَمَن أَظلَم",
            nameTransliteration: "Faman Adhlam",
            startSurah: 39, startAyah: 32,
            endSurah: 41, endAyah: 46
        ),

        Juz(id: 25,
            nameArabic: "إِلَيهِ يُرَدّ",
            nameTransliteration: "Ilayhi Yuradd",
            startSurah: 41, startAyah: 47,
            endSurah: 45, endAyah: 37
        ),

        Juz(id: 26,
            nameArabic: "حم",
            nameTransliteration: "Ha Meem",
            startSurah: 46, startAyah: 1,
            endSurah: 51, endAyah: 30
        ),

        Juz(id: 27,
            nameArabic: "قَالَ فَمَا خَطبُكُم",
            nameTransliteration: "Qaala Famaa Khatbukum",
            startSurah: 51, startAyah: 31,
            endSurah: 57, endAyah: 29
        ),

        Juz(id: 28,
            nameArabic: "قَد سَمِعَ",
            nameTransliteration: "Qad Sami'a",
            startSurah: 58, startAyah: 1,
            endSurah: 66, endAyah: 12
        ),

        Juz(id: 29,
            nameArabic: "تَبَارَك",
            nameTransliteration: "Tabaarak",
            startSurah: 67, startAyah: 1,
            endSurah: 77, endAyah: 50
        ),

        Juz(id: 30,
            nameArabic: "عَمَّ",
            nameTransliteration: "'Amma",
            startSurah: 78, startAyah: 1,
            endSurah: 114, endAyah: 6
        )
    ]
}

// MARK: - Qiraah comparison engine (ayah alignment + word-level diff)

/// The smart-comparison engine. Two jobs:
///
/// 1. ALIGNMENT. The overlay riwayah texts are numbered 1..N in each riwayah's OWN counting
///    tradition, not in Hafs numbers - the Madani/Basri/Makki/Dimashqi counts merge or split
///    neighbors of the Kufi (Hafs) count, drifting by up to a handful per surah. So "row 2 of
///    Warsh" is NOT "Hafs 2:2"; asking a riwayah for a Hafs number needs a mapping. The mapping is
///    recovered from the texts themselves: word counts per ayah are compared with a greedy walk
///    that pairs one riwayah ayah against one, two, or three Hafs ayahs (and the reverse for
///    splits) - at a genuine merge point the word-count evidence is unambiguous, and identical
///    totals short-circuit to identity (all the Kufi-counted riwayat).
///
/// 2. WORD DIFF. Ranges in a riwayah's display text whose words differ from a reference text
///    (usually the selected riwayah), computed as folded-word LCS - the search fold strips
///    tashkeel and normalizes hamza carriers, so vocalization and orthography differences don't
///    light whole ayahs up, while real word differences (يخدعون / يخادعون, ملك / مالك) do.
@MainActor
enum QiraahComparison {
    struct Alignment {
        /// Hafs ayah number → the riwayah's own ayah number whose text contains that Hafs ayah.
        let riwayahNumberForHafs: [Int: Int]
        /// Riwayah ayah number → the Hafs ayah number(s) its text spans (more than one = merged).
        let hafsRangeForRiwayah: [Int: ClosedRange<Int>]
    }

    private static var alignmentCache: [String: Alignment] = [:]
    private static var diffCache: [String: [(Int, Int)]] = [:]

    /// The alignment for one surah of one riwayah, cached for the app's lifetime (texts are
    /// immutable). Nil for Hafs itself, unknown tags, or a riwayah with no text for this surah.
    static func alignment(surahID: Int, tag: String, quranData: QuranData) -> Alignment? {
        let canonical = Settings.Riwayah.canonicalTag(tag)
        guard !canonical.isEmpty else { return nil }
        let key = "\(surahID)|\(canonical)"
        if let cached = alignmentCache[key] { return cached }
        #if DEBUG
        var phase = Date()
        func lap(_ slot: Int) { phaseMillis[slot] += Date().timeIntervalSince(phase) * 1000; phase = Date() }
        #else
        func lap(_ slot: Int) {}
        #endif

        // Each side's texts are read and split ONCE: word counts for the count walk, rasm sets for
        // the word check. Hafs's side serves all nineteen riwayat of this surah.
        guard let hafs = hafsSide(surahID: surahID, quranData: quranData),
              let riwayahTexts = texts(surahID: surahID, tag: canonical, quranData: quranData) else { return nil }
        let riwayah = Side(texts: riwayahTexts)
        lap(0)

        var result = countWalk(riwayahWords: riwayah.counts, hafsWords: hafs.counts)
        lap(3)

        // WORD COUNTS ARE NOT ENOUGH. The count walk decides from counts alone, and equal counts
        // do not imply equal boundaries: al-Fatiha has seven ayahs in every tradition, yet the
        // Madani and Basri counts do not number the basmalah and split the last ayah, so every
        // verse sits one place off - the identity short-circuit then aligned Warsh 1:3
        // (مَلِكِ يَوْمِ ٱلدِّينِ) to Hafs 1:3 (ٱلرَّحْمَٰنِ ٱلرَّحِيمِ); Al Imran keeps its 200
        // through one merge and one split each way. So the mapping is CHECKED against the words
        // themselves, and re-derived from content where it fails - a surah the counts got right
        // keeps exactly the mapping it had.
        let countScore = agreement(result.hafsRangeForRiwayah, riwayah: riwayah.rasm, hafs: hafs.rasm)
        lap(1)
        var finalScore = countScore.mean
        var walkScore: Double? = nil
        // The gate is the WORST ayah, not the average: a long surah hides one misplaced ayah
        // behind a high mean (one slip in Baqarah still averages 0.996), while the misplaced ayah
        // itself scores near zero - and mere wording differences never drag one below about 0.7.
        if countScore.worst < 0.6 {
            let repaired = contentAlignment(riwayah: riwayah.rasm, hafs: hafs.rasm)
            lap(2)
            let repairedScore = agreement(repaired.hafsRangeForRiwayah, riwayah: riwayah.rasm, hafs: hafs.rasm)
            lap(1)
            walkScore = repairedScore.mean
            if repairedScore.mean > countScore.mean + 0.005 {
                result = repaired
                finalScore = repairedScore.mean
            }
        }
        #if DEBUG
        diagnostics[key] = Diagnostics(countScore: countScore.mean, finalScore: finalScore, walkScore: walkScore)
        #endif

        alignmentCache[key] = result
        return result
    }

    /// The greedy count walk: pairs one riwayah ayah against one, two, or three Hafs ayahs (and
    /// the reverse for splits) by word counts alone - at a genuine merge point the count evidence
    /// is unambiguous, and identical totals short-circuit to identity. Right for most surahs,
    /// and checked against the words by `alignment` for the rest.
    private static func countWalk(riwayahWords: [Int], hafsWords: [Int]) -> Alignment {
        var rForH: [Int: Int] = [:]
        var hForR: [Int: ClosedRange<Int>] = [:]

        if riwayahWords.count == hafsWords.count {
            // Same count = same numbering (every Kufi-counted riwayah): identity.
            for i in 1...hafsWords.count {
                rForH[i] = i
                hForR[i] = i...i
            }
        } else {
            var h = 0
            var r = 0
            while h < hafsWords.count, r < riwayahWords.count {
                let one = abs(riwayahWords[r] - hafsWords[h])
                let merge2 = h + 1 < hafsWords.count
                    ? abs(riwayahWords[r] - (hafsWords[h] + hafsWords[h + 1])) : Int.max
                let merge3 = h + 2 < hafsWords.count
                    ? abs(riwayahWords[r] - (hafsWords[h] + hafsWords[h + 1] + hafsWords[h + 2])) : Int.max
                let split2 = r + 1 < riwayahWords.count
                    ? abs((riwayahWords[r] + riwayahWords[r + 1]) - hafsWords[h]) : Int.max

                let best = min(one, merge2, merge3, split2)
                if best == one {
                    // Ties break toward 1:1 on purpose - merges must EARN the pairing.
                    rForH[h + 1] = r + 1
                    hForR[r + 1] = (h + 1)...(h + 1)
                    h += 1; r += 1
                } else if best == merge2 {
                    rForH[h + 1] = r + 1
                    rForH[h + 2] = r + 1
                    hForR[r + 1] = (h + 1)...(h + 2)
                    h += 2; r += 1
                } else if best == merge3 {
                    rForH[h + 1] = r + 1
                    rForH[h + 2] = r + 1
                    rForH[h + 3] = r + 1
                    hForR[r + 1] = (h + 1)...(h + 3)
                    h += 3; r += 1
                } else {
                    // Split: the riwayah divides this Hafs ayah - both riwayah pieces map to it,
                    // and the Hafs number points at the piece that STARTS it.
                    rForH[h + 1] = r + 1
                    hForR[r + 1] = (h + 1)...(h + 1)
                    hForR[r + 2] = (h + 1)...(h + 1)
                    h += 1; r += 2
                }
            }
            // Leftovers (a desynced tail can only be a data defect): map 1:1 so lookups still land.
            while h < hafsWords.count {
                let r0 = min(r, riwayahWords.count - 1)
                rForH[h + 1] = r0 + 1
                h += 1
            }
        }
        return Alignment(riwayahNumberForHafs: rForH, hafsRangeForRiwayah: hForR)
    }

    // MARK: Content check

    /// A word reduced to its bare rasm: marks dropped, hamza seats folded to their carrier, the
    /// dotless letters and alef maqsura folded back. What every riwayah of one ayah shares is the
    /// skeleton, so this is what alignment can be checked against - vowels, hamza spellings and
    /// dots differ by design.
    nonisolated static func wordSkeleton<S: StringProtocol>(_ token: S) -> String {
        var out = String.UnicodeScalarView()
        for scalar in token.unicodeScalars {
            switch scalar.value {
            case 0x0622, 0x0623, 0x0625, 0x0671: out.append(Self.alef)     // hamza seats, wasl alef
            case 0x0624: out.append(Self.waw)
            case 0x0626, 0x0649, 0x06CC: out.append(Self.ya)              // ya seat, alef maqsura, Farsi ya
            case 0x066E, 0x067E: out.append(Self.ba)                      // dotless beh, peh
            case 0x066F: out.append(Self.qaf)
            case 0x06A1: out.append(Self.fa)
            case 0x06BA: out.append(Self.noon)
            case 0x0621, 0x0640: continue                                 // bare hamza, tatweel: no rasm
            case 0x0627...0x064A: out.append(scalar)
            default: continue                                             // marks, digits, ornaments
            }
        }
        return String(out)
    }

    private nonisolated static let alef: Unicode.Scalar = "ا"
    private nonisolated static let waw: Unicode.Scalar = "و"
    private nonisolated static let ya: Unicode.Scalar = "ي"
    private nonisolated static let ba: Unicode.Scalar = "ب"
    private nonisolated static let qaf: Unicode.Scalar = "ق"
    private nonisolated static let fa: Unicode.Scalar = "ف"
    private nonisolated static let noon: Unicode.Scalar = "ن"

    /// One reading's surah, split once: each ayah's word count and its set of rasm words.
    private struct Side {
        let counts: [Int]
        let rasm: [Set<String>]

        init(texts: [String]) {
            var counts: [Int] = []
            var rasm: [Set<String>] = []
            counts.reserveCapacity(texts.count)
            rasm.reserveCapacity(texts.count)
            for text in texts {
                var words = Set<String>()
                var count = 0
                for token in text.split(whereSeparator: { $0.isWhitespace }) {
                    count += 1
                    let skeleton = wordSkeleton(token)
                    if !skeleton.isEmpty { words.insert(skeleton) }
                }
                counts.append(count)
                rasm.append(words)
            }
            self.counts = counts
            self.rasm = rasm
        }
    }

    /// Surah → the Hafs side, shared by every riwayah's alignment of that surah.
    private static var hafsSideCache: [Int: Side] = [:]

    private static func hafsSide(surahID: Int, quranData: QuranData) -> Side? {
        if let cached = hafsSideCache[surahID] { return cached }
        guard let texts = texts(surahID: surahID, tag: nil, quranData: quranData) else { return nil }
        let side = Side(texts: texts)
        hafsSideCache[surahID] = side
        return side
    }

    /// The ayah texts of one reading for a surah (nil tag = Hafs), in that reading's own
    /// numbering. Nil when the surah has no text there. numberOfAyahs > 0 also protects the
    /// `1...` range - a truncated pack decodes surah metas with count 0.
    private static func texts(surahID: Int, tag: String?, quranData: QuranData) -> [String]? {
        guard let surah = quranData.surah(surahID), surah.numberOfAyahs > 0 else { return nil }
        var out: [String] = []
        if let tag {
            var n = 1
            while let a = quranData.ayah(surah: surahID, ayah: n), a.existsInQiraah(tag, surahID: surahID) {
                out.append(a.textArabic(for: tag, surahID: surahID))
                n += 1
            }
        } else {
            for n in 1...surah.numberOfAyahs {
                guard let a = quranData.ayah(surah: surahID, ayah: n) else { return nil }
                out.append(a.textArabic(for: nil))
            }
        }
        return out.isEmpty ? nil : out
    }

    /// How much of each riwayah ayah's rasm actually appears in the Hafs ayah(s) it was mapped to:
    /// the average over the surah, and the single worst ayah. Containment (not Jaccard) so a
    /// genuine merge or split still scores 1: the question is whether the riwayah's words are IN
    /// the span, not whether the span is the same size. An unmapped ayah scores 0.
    private static func agreement(_ mapping: [Int: ClosedRange<Int>],
                                  riwayah: [Set<String>], hafs: [Set<String>]) -> (mean: Double, worst: Double) {
        guard !riwayah.isEmpty else { return (0, 0) }
        var total = 0.0
        var worst = 1.0
        for (index, words) in riwayah.enumerated() {
            // An ayah with no rasm at all (marks only) says nothing either way.
            guard !words.isEmpty else { total += 1; continue }
            var score = 0.0
            if let span = mapping[index + 1] {
                var union = Set<String>()
                for n in span where n >= 1 && n <= hafs.count { union.formUnion(hafs[n - 1]) }
                score = containment(words, union)
            }
            total += score
            worst = min(worst, score)
        }
        return (total / Double(riwayah.count), worst)
    }

    private static func containment(_ a: Set<String>, _ b: Set<String>) -> Double {
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        return Double(a.intersection(b).count) / Double(min(a.count, b.count))
    }

    /// The content alignment proper: a banded dynamic-programming alignment of the two ayah
    /// sequences, scored by the words themselves. A block pairs one riwayah ayah with up to five
    /// Hafs ayahs (a merge), up to five riwayah ayahs with one Hafs ayah (a split - Ta-Ha 40 is
    /// FOUR ayahs in the Shami count), or leaves an ayah on either side unpaired (a Hafs ayah this
    /// counting does not number at all - the basmalah - or a riwayah ayah Hafs has no counterpart
    /// for). A block earns its shared words and pays half for every word only one side has, so a
    /// merge or split wins only where the extra ayah's words are genuinely there; a wider block
    /// pays a hair more, so a tie between absorbing a neighbor and leaving it alone goes to
    /// leaving it alone. Globally optimal, so a many-piece split or an early drift cannot throw
    /// the rest of the surah off the way a greedy step does.
    ///
    /// Every distinct rasm word in the surah gets one bit, so an ayah (or a run of them) is a few
    /// UInt64 lanes and a block's shared-word count is a few popcounts - the table scores tens of
    /// thousands of blocks for a long surah.
    private static func contentAlignment(riwayah: [Set<String>], hafs: [Set<String>]) -> Alignment {
        let n = riwayah.count, m = hafs.count
        guard n > 0, m > 0 else { return Alignment(riwayahNumberForHafs: [:], hafsRangeForRiwayah: [:]) }

        var bitOf: [String: Int] = [:]
        for words in riwayah { for word in words where bitOf[word] == nil { bitOf[word] = bitOf.count } }
        for words in hafs { for word in words where bitOf[word] == nil { bitOf[word] = bitOf.count } }
        let lanes = max(1, (bitOf.count + 63) / 64)
        let maxSpan = 5

        // Flat lane buffers, [width - 1][ayah][lane]: width 1 is the ayahs themselves, wider
        // slots the unions of that many consecutive ayahs (clamped at the end - such blocks are
        // never scored anyway). `counts` holds each slot's popcount.
        func buffers(_ sets: [Set<String>]) -> (bits: [UInt64], counts: [Int]) {
            let count = sets.count
            var bits = [UInt64](repeating: 0, count: maxSpan * count * lanes)
            for (index, words) in sets.enumerated() {
                for word in words {
                    guard let bit = bitOf[word] else { continue }
                    bits[index * lanes + (bit >> 6)] |= 1 << UInt64(bit & 63)
                }
            }
            for width in 2...maxSpan {
                let base = (width - 1) * count * lanes
                let prev = (width - 2) * count * lanes
                for index in 0..<count {
                    let last = min(index + width - 1, count - 1) * lanes
                    for lane in 0..<lanes {
                        bits[base + index * lanes + lane] = bits[prev + index * lanes + lane] | bits[last + lane]
                    }
                }
            }
            var counts = [Int](repeating: 0, count: maxSpan * count)
            for slot in 0..<(maxSpan * count) {
                var total = 0
                for lane in 0..<lanes { total += bits[slot * lanes + lane].nonzeroBitCount }
                counts[slot] = total
            }
            return (bits, counts)
        }
        let r = buffers(riwayah)
        let h = buffers(hafs)

        // (riwayah ayahs consumed, Hafs ayahs consumed).
        var moves: [(dr: Int, dh: Int)] = [(1, 1)]
        for width in 2...maxSpan { moves.append((1, width)) }
        for width in 2...maxSpan { moves.append((width, 1)) }
        moves.append((0, 1))
        moves.append((1, 0))
        // The true path never strays further from the diagonal than the counts differ, plus a few
        // local merge/split pairs that cancel out - the band keeps the table small.
        let band = abs(n - m) + 8
        let stride = m + 1
        var best = [Double](repeating: -.infinity, count: (n + 1) * stride)
        var from = [Int](repeating: -1, count: (n + 1) * stride)
        best[0] = 0
        r.bits.withUnsafeBufferPointer { rp in
            h.bits.withUnsafeBufferPointer { hp in
                best.withUnsafeMutableBufferPointer { bp in
                    from.withUnsafeMutableBufferPointer { fp in
                        for i in 0...n {
                            let lo = max(0, i - band), hi = min(m, i + band)
                            guard lo <= hi else { continue }
                            for j in lo...hi {
                                let here = bp[i * stride + j]
                                guard here > -.infinity else { continue }
                                for (index, move) in moves.enumerated() {
                                    let ni = i + move.dr, nj = j + move.dh
                                    guard ni <= n, nj <= m else { continue }
                                    let score: Double
                                    if move.dr == 0 {
                                        // Leaving an ayah unpaired costs exactly what pairing it
                                        // with nothing would: half its words.
                                        score = -0.5 * Double(h.counts[j])
                                    } else if move.dh == 0 {
                                        score = -0.5 * Double(r.counts[i])
                                    } else {
                                        let ra = ((move.dr - 1) * n + i) * lanes
                                        let hb = ((move.dh - 1) * m + j) * lanes
                                        var common = 0
                                        for lane in 0..<lanes {
                                            common += (rp[ra + lane] & hp[hb + lane]).nonzeroBitCount
                                        }
                                        let only = r.counts[(move.dr - 1) * n + i] + h.counts[(move.dh - 1) * m + j] - 2 * common
                                        score = Double(common) - 0.5 * Double(only) - 0.01 * Double(move.dr + move.dh - 2)
                                    }
                                    let total = here + score
                                    let slot = ni * stride + nj
                                    if total > bp[slot] {
                                        bp[slot] = total
                                        fp[slot] = index
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Walk the chosen blocks back from the end. Same conventions as the count walk: every
        // piece of a split maps to its one Hafs ayah, and a Hafs ayah points at the riwayah ayah
        // that STARTS its block. A skipped ayah simply has no entry.
        var rForH: [Int: Int] = [:]
        var hForR: [Int: ClosedRange<Int>] = [:]
        var i = n, j = m
        while i > 0 || j > 0 {
            let index = from[i * stride + j]
            guard index >= 0 else { break }
            let move = moves[index]
            let ri = i - move.dr, hj = j - move.dh
            if move.dr > 0, move.dh > 0 {
                let hafsSpan = (hj + 1)...(hj + move.dh)
                for piece in (ri + 1)...(ri + move.dr) { hForR[piece] = hafsSpan }
                for hafsNumber in hafsSpan { rForH[hafsNumber] = ri + 1 }
            }
            i = ri; j = hj
        }
        return Alignment(riwayahNumberForHafs: rForH, hafsRangeForRiwayah: hForR)
    }

    #if DEBUG
    struct Diagnostics {
        let countScore: Double
        let finalScore: Double
        /// What the content alignment scored, when it was tried at all.
        let walkScore: Double?
        var repaired: Bool { finalScore > countScore }
    }

    /// "surahID|tag" → how the count-derived mapping scored and what shipped, filled in as
    /// alignments are computed.
    static var diagnostics: [String: Diagnostics] = [:]
    /// Milliseconds spent per phase across every alignment computed: 0 = reading and splitting
    /// the texts, 1 = agreement scoring, 2 = the content alignment table, 3 = the count walk.
    static var phaseMillis = [0.0, 0.0, 0.0, 0.0]

    /// "-auditQiraahAlignment" - align every surah of every riwayah and print what the word check
    /// made of it. Alignment is the one part of the reader that cannot be verified by looking at a
    /// page, and a silent one-ayah shift reads as perfectly ordinary text.
    static func auditAlignments(quranData: QuranData) {
        var repairs: [String] = []
        var weak: [String] = []
        var weakCount = 0
        var worst = 1.0
        var count = 0
        let started = Date()
        var slowest = (ms: 0.0, pair: "")
        for option in Settings.Riwayah.allOptions where !Settings.Riwayah.canonicalTag(option.tag).isEmpty {
            let tag = Settings.Riwayah.canonicalTag(option.tag)
            for surahID in 1...114 {
                let t0 = Date()
                let aligned = alignment(surahID: surahID, tag: tag, quranData: quranData) != nil
                let ms = Date().timeIntervalSince(t0) * 1000
                if ms > slowest.ms { slowest = (ms, "\(option.label) surah \(surahID)") }
                guard aligned, let diagnostic = diagnostics["\(surahID)|\(tag)"] else { continue }
                count += 1
                worst = min(worst, diagnostic.finalScore)
                if diagnostic.repaired {
                    repairs.append(String(format: "  %@ surah %d: %.3f -> %.3f",
                                          option.label, surahID, diagnostic.countScore, diagnostic.finalScore))
                } else if diagnostic.finalScore < 0.75 {
                    weakCount += 1
                    weak.append(String(format: "  %@ surah %d: %.3f (word check scored %.3f - kept the count mapping)",
                                       option.label, surahID, diagnostic.finalScore, diagnostic.walkScore ?? -1))
                    weak.append(contentsOf: weakDetail(surahID: surahID, tag: tag, quranData: quranData))
                }
            }
        }
        print("ALIGNMENT AUDIT: \(count) surah/riwayah pairs, worst score \(String(format: "%.3f", worst))")
        print(String(format: "ALIGNMENT AUDIT: %.0f ms total, slowest %.1f ms (%@)",
                     Date().timeIntervalSince(started) * 1000, slowest.ms, slowest.pair))
        print(String(format: "ALIGNMENT AUDIT: phases - texts %.0f ms, agreement %.0f ms, content table %.0f ms, count walk %.0f ms",
                     phaseMillis[0], phaseMillis[1], phaseMillis[2], phaseMillis[3]))
        print("ALIGNMENT AUDIT: \(repairs.count) repaired by the word check")
        repairs.forEach { print($0) }
        print("ALIGNMENT AUDIT: \(weakCount) still below 0.75")
        weak.forEach { print($0) }
        print("ALIGNMENT AUDIT: done")
        fflush(stdout)
    }

    /// Per-ayah detail for one weak pair: each riwayah ayah whose rasm is not fully inside the
    /// Hafs ayah(s) it maps to, with the words that went missing.
    private static func weakDetail(surahID: Int, tag: String, quranData: QuranData) -> [String] {
        guard let alignment = alignment(surahID: surahID, tag: tag, quranData: quranData),
              let hafs = hafsSide(surahID: surahID, quranData: quranData),
              let riwayahTexts = texts(surahID: surahID, tag: tag, quranData: quranData) else { return [] }
        let riwayah = Side(texts: riwayahTexts)
        var lines = ["    \(riwayah.rasm.count) ayahs here vs \(hafs.rasm.count) in Hafs"]
        for (index, words) in riwayah.rasm.enumerated() {
            guard let span = alignment.hafsRangeForRiwayah[index + 1] else {
                lines.append("    r\(index + 1): unmapped")
                continue
            }
            var union = Set<String>()
            for n in span where n >= 1 && n <= hafs.rasm.count { union.formUnion(hafs.rasm[n - 1]) }
            let missing = words.subtracting(union)
            guard !missing.isEmpty else { continue }
            lines.append("    r\(index + 1) -> h\(span.lowerBound)-\(span.upperBound): missing [\(missing.sorted().joined(separator: " "))] hafs [\(union.sorted().joined(separator: " "))]")
        }
        return lines
    }
    #endif

    /// The Hafs anchor for a riwayah's own ayah number - what "\(riwayahNumber)" means in Hafs
    /// terms when reading that riwayah. Identity for Hafs/unknown.
    static func hafsAnchor(surahID: Int, ayahNumber: Int, tag: String?, quranData: QuranData) -> Int {
        guard let tag, !Settings.Riwayah.canonicalTag(tag).isEmpty,
              let alignment = alignment(surahID: surahID, tag: tag, quranData: quranData),
              let span = alignment.hafsRangeForRiwayah[ayahNumber] else { return ayahNumber }
        return span.lowerBound
    }

    // MARK: Word diff

    private static func tokens(of text: String) -> [(range: Range<String.Index>, folded: String)] {
        var result: [(Range<String.Index>, String)] = []
        var cursor = text.startIndex
        while cursor < text.endIndex {
            while cursor < text.endIndex, text[cursor].isWhitespace { cursor = text.index(after: cursor) }
            guard cursor < text.endIndex else { break }
            let start = cursor
            while cursor < text.endIndex, !text[cursor].isWhitespace { cursor = text.index(after: cursor) }
            let range = start..<cursor
            result.append((range, HighlightedSnippet.normalizeForSearchText(String(text[range]), trimWhitespace: true)))
        }
        return result
    }

    /// Ranges in `text` whose words are not part of the folded-word LCS with `reference` - the
    /// words this riwayah reads differently from the reference riwayah. Cached per text pair.
    static func differingRanges(in text: String, vs reference: String) -> [Range<String.Index>] {
        guard text != reference else { return [] }
        let key = "\(text)\u{0}\(reference)"
        if let spans = diffCache[key] {
            return spans.compactMap { span in
                guard let lo = utf16Index(span.0, in: text), let hi = utf16Index(span.1, in: text), lo < hi else { return nil }
                return lo..<hi
            }
        }

        let a = tokens(of: text)
        let b = tokens(of: reference)
        // Standalone marks fold to nothing (pause signs) - never diff-worthy on their own.
        let aFolded = a.map(\.folded)
        let bFolded = b.map(\.folded)

        // Classic LCS table - ayah-sized inputs, dozens of words at most.
        var table = Array(repeating: Array(repeating: 0, count: bFolded.count + 1), count: aFolded.count + 1)
        if !aFolded.isEmpty, !bFolded.isEmpty {
            for i in stride(from: aFolded.count - 1, through: 0, by: -1) {
                for j in stride(from: bFolded.count - 1, through: 0, by: -1) {
                    table[i][j] = aFolded[i] == bFolded[j]
                        ? table[i + 1][j + 1] + 1
                        : max(table[i + 1][j], table[i][j + 1])
                }
            }
        }

        var common = Set<Int>()
        var i = 0
        var j = 0
        while i < aFolded.count, j < bFolded.count {
            if aFolded[i] == bFolded[j] {
                common.insert(i)
                i += 1; j += 1
            } else if table[i + 1][j] >= table[i][j + 1] {
                i += 1
            } else {
                j += 1
            }
        }

        var ranges: [Range<String.Index>] = []
        for (index, token) in a.enumerated() where !common.contains(index) && !token.folded.isEmpty {
            ranges.append(token.range)
        }
        diffCache[key] = ranges.map { range in
            (text.utf16.distance(from: text.startIndex, to: range.lowerBound),
             text.utf16.distance(from: text.startIndex, to: range.upperBound))
        }
        if diffCache.count > 4_000 { diffCache.removeAll(keepingCapacity: true) }
        return ranges
    }

    private static func utf16Index(_ offset: Int, in text: String) -> String.Index? {
        text.utf16.index(text.utf16.startIndex, offsetBy: offset, limitedBy: text.utf16.endIndex)
            .flatMap { $0.samePosition(in: text) }
    }

    /// The display text as an AttributedString with its differing words tinted - ready to feed a
    /// `HighlightedSnippet.preStyledSource` (an active search term still wins, by that view's rule).
    static func diffAttributed(text: String, reference: String, baseColor: Color, diffColor: Color) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.foregroundColor = baseColor
        for range in differingRanges(in: text, vs: reference) {
            // A differing word can carry a stop-sign ornament on its last letter - tint around it
            // (user rule: stop signs are never highlighted), splitting the word into the runs between.
            for run in stopSignFreeSubranges(of: range, in: text) {
                if let start = AttributedString.Index(run.lowerBound, within: attributed),
                   let end = AttributedString.Index(run.upperBound, within: attributed) {
                    attributed[start..<end].foregroundColor = diffColor
                }
            }
        }
        return attributed
    }

    /// `range` minus the waqf stop-sign scalars inside it, as the contiguous runs between them. Walked at
    /// SCALAR granularity: the stop signs are combining marks riding a word's last letter, so they live
    /// INSIDE that letter's grapheme cluster - a character-level walk could never separate them. Scalar
    /// boundaries are valid String (and AttributedString) indices, the same mechanics the Allah-name
    /// highlighter already banks on to stop its red before a trailing waqf mark.
    private static func stopSignFreeSubranges(of range: Range<String.Index>, in text: String) -> [Range<String.Index>] {
        let scalars = text.unicodeScalars
        var runs: [Range<String.Index>] = []
        var runStart = range.lowerBound
        var cursor = range.lowerBound
        while cursor < range.upperBound {
            let next = scalars.index(after: cursor)
            if TajweedRules.stopSignScalars.contains(scalars[cursor].value) {
                if runStart < cursor { runs.append(runStart..<cursor) }
                runStart = next
            }
            cursor = next
        }
        if runStart < range.upperBound { runs.append(runStart..<range.upperBound) }
        return runs
    }
}
