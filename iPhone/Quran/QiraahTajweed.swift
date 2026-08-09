#if os(iOS)
import Foundation
import SwiftUI
import Compression

/// Print-derived tajweed / khilaf coloring for the 19 non-Hafs riwayat,
/// extracted from the Islamweb printed mushaf series (the same books the beta
/// texts come from). Each riwayah pack carries:
///  * word-level rule colors (`rules`): the printed color of every colored
///    word - what differs from Hafs, idgham, imalah/taqlil, sakt, ... The
///    MEANING of a color is per edition and ships in `legend`, transcribed
///    from that mushaf's own printed legend box.
///  * the riwayah's own ayah -> page table (`pages`): the true pagination of
///    ITS 604-page print. The Madinah page numbers on the Hafs rows do not
///    hold for other riwayat (merged ayahs, different orthography), which is
///    why page mode used to break on them.
///
/// Same storage/loading pattern as `BetaQiraatStore`: one raw-deflate JSON
/// per riwayah, lazily loaded, thread-safe by lock (rendering reads on main,
/// pagination reads from a detached build).
final class QiraahTajweedStore: @unchecked Sendable {
    static let shared = QiraahTajweedStore()
    private init() {}

    struct LegendEntry: Identifiable {
        let letter: Character
        /// Stable rule key ("idgham", "silah_meem", ...) - the same rule keeps the same key
        /// across riwayat, so descriptions and show/hide preferences follow the MEANING.
        let key: String
        let arabic: String
        let english: String
        var id: String { key }
        var color: Color { Color(QiraahTajweedStore.uiColor(for: letter)) }
        var uiColor: UIColor { QiraahTajweedStore.uiColor(for: letter) }
        var shortDescription: String { QiraahTajweedStore.shortDescriptions[key] ?? "" }
        var longDescription: String { QiraahTajweedStore.longDescriptions[key] ?? "" }
    }

    /// One line for the legend card.
    static let shortDescriptions: [String: String] = [
        "khilaf_word": "Word read differently from Ḥafṣ.",
        "khilaf_harf": "Letter read differently from Ḥafṣ.",
        "idgham": "Letter merges into the next.",
        "imalah": "Vowel inclined toward 'eh'.",
        "imalah_taqlil": "Vowel inclined toward 'eh' (full or slight).",
        "taqlil": "Vowel slightly inclined toward 'eh'.",
        "silah_meem": "Plural mīm linked with a small wāw.",
        "ha_dhamir": "Pronoun hāʾ vowelled differently from Ḥafṣ.",
        "sakt": "Brief breathless pause.",
        "ishmam_sad": "Ṣād blended toward a zāy sound.",
        "ghunnah_kha_ghayn": "Nasal kept even before khāʾ/ghayn.",
        "madd_badal": "Hamzah followed by a lengthened vowel.",
        "madd_leen": "Soft wāw/yāʾ stretched before a stop.",
        "raa_muraqqaqah": "Rāʾ pronounced light here.",
        "lam_mughallazah": "Lām pronounced heavy here.",
    ]

    /// The longer note under the card.
    static let longDescriptions: [String: String] = [
        "khilaf_word": "This whole word is recited differently from the Ḥafṣ an ʿĀṣim reading - a different word form, added or dropped letters, or different vowels. The coloring follows this riwayah's printed muṣḥaf exactly.",
        "khilaf_harf": "A letter in this word differs from the Ḥafṣ an ʿĀṣim reading - its dots, its hamzah, or its vowel. The coloring follows this riwayah's printed muṣḥaf exactly.",
        "idgham": "The colored letter is merged (assimilated) into the letter after it instead of being pronounced separately - including the major idghām this riwayah is known for, where even vowelled letters merge.",
        "imalah": "The colored vowel is 'inclined': the alif drifts from 'aa' toward 'eh', the way this reader recites it. Listen for a sound between fatḥah and kasrah.",
        "imalah_taqlil": "The colored vowel is 'inclined' from 'aa' toward 'eh' - fully (imālah kubrā) or slightly (taqlīl), as this reader recites it in these words.",
        "taqlil": "The colored vowel is slightly inclined from 'aa' toward 'eh' (between the plain fatḥah and full imālah) - the hallmark of this reading in these words.",
        "silah_meem": "The plural mīm (كُم / هُم / تُم) is given a ḍammah and linked to the next word with a small wāw sound - mīm becomes 'muu' before the following word.",
        "ha_dhamir": "The pronoun hāʾ in this word carries different vowelling than Ḥafṣ - typically linked with a long vowel (ṣilah) where Ḥafṣ reads it short, or vice versa.",
        "sakt": "The reader pauses here for a brief moment WITHOUT taking a breath, then continues - a signature of this transmission in these specific places.",
        "ishmam_sad": "The colored ṣād is pronounced with a blend of zāy in it (like the ṣ in 'aṣ-ṣirāṭ' shading toward z) - a distinctive feature of this reading.",
        "ghunnah_kha_ghayn": "The nūn/tanwīn keeps its nasal sound (ghunnah) even before خ and غ, where other readings drop it - a hallmark of Abū Jaʿfar's reading.",
        "madd_badal": "A hamzah followed by a long vowel (like آمَنُوا) is stretched longer than usual in this reading - Warsh lengthens these to two, four, or six counts.",
        "madd_leen": "The soft wāw or yāʾ (preceded by fatḥah) before the word's final letter is stretched - Warsh gives these extra length when stopping.",
        "raa_muraqqaqah": "This rāʾ is pronounced LIGHT (muraqqaqah) where Ḥafṣ says it heavy - one of Warsh's well-known rāʾ rules after a kasrah or yāʾ.",
        "lam_mughallazah": "This lām is pronounced HEAVY (mughallaẓah) - Warsh thickens the lām after ṣād, ṭāʾ, or ẓāʾ, similar to the lām of Allāh.",
    ]

    struct WordRule {
        let letter: Character
        /// Base-letter index range the PRINT colors within the word (reading
        /// order), extracted from the word's own ink runs. Nil = whole word
        /// colored, or the extent couldn't be mapped.
        let baseLo: Int
        let baseHi: Int
        var hasExtent: Bool { baseLo >= 0 }
    }

    struct Pack {
        /// surah -> ayah (riwayah's own numbering, = `Ayah.id`) -> word index
        /// over space/NBSP-split tokens -> rule.
        let rules: [Int: [Int: [Int: WordRule]]]
        /// surah -> ayah -> page (1...604) in this riwayah's own print.
        let pages: [Int: [Int: Int]]
        let legend: [LegendEntry]
        /// Ayahs whose number medallion is printed with a magenta ring - the
        /// ayah NUMBERING there differs from Hafs (merge/split points).
        let khilafMarkers: [Int: Set<Int>]
    }

    private let lock = NSLock()
    private var loaded: [String: Pack] = [:]
    private var missing: Set<String> = []

    /// File base name for a riwayah tag; nil when the tag has no tajweed pack.
    static func fileName(for tag: String) -> String? {
        switch Settings.Riwayah.canonicalTag(tag) {
        case Settings.Riwayah.warsh: return "TajweedWarsh"
        case Settings.Riwayah.qaloon: return "TajweedQaloon"
        case Settings.Riwayah.duri: return "TajweedDuri"
        case Settings.Riwayah.susi: return "TajweedSusi"
        case Settings.Riwayah.buzzi: return "TajweedBazzi"
        case Settings.Riwayah.qunbul: return "TajweedQunbul"
        case Settings.Riwayah.shubah: return "TajweedShubah"
        case Settings.Riwayah.hisham: return "TajweedHisham"
        case Settings.Riwayah.ibnDhakwan: return "TajweedIbnDhakwan"
        case Settings.Riwayah.khalaf: return "TajweedKhalaf"
        case Settings.Riwayah.khallad: return "TajweedKhallad"
        case Settings.Riwayah.abuHarith: return "TajweedAbuHarith"
        case Settings.Riwayah.duriKisai: return "TajweedDuriKisai"
        case Settings.Riwayah.ibnWardan: return "TajweedIbnWardan"
        case Settings.Riwayah.ibnJammaz: return "TajweedIbnJammaz"
        case Settings.Riwayah.ruways: return "TajweedRuways"
        case Settings.Riwayah.rawh: return "TajweedRawh"
        case Settings.Riwayah.ishaq: return "TajweedIshaq"
        case Settings.Riwayah.idris: return "TajweedIdris"
        default: return nil
        }
    }

    func isAvailable(tag: String) -> Bool {
        pack(for: tag) != nil
    }

    func legend(for tag: String) -> [LegendEntry] {
        pack(for: tag)?.legend ?? []
    }

    func wordRules(tag: String, surah: Int, ayah: Int) -> [Int: WordRule]? {
        pack(for: tag)?.rules[surah]?[ayah]
    }

    /// The riwayah's own ayah -> page table, for `MushafPagination`.
    func pageTable(for tag: String) -> [Int: [Int: Int]]? {
        pack(for: tag)?.pages
    }

    func pack(for tag: String) -> Pack? {
        let key = Settings.Riwayah.canonicalTag(tag)
        lock.lock()
        if let cached = loaded[key] { lock.unlock(); return cached }
        if missing.contains(key) { lock.unlock(); return nil }
        lock.unlock()

        guard let name = Self.fileName(for: key), let parsed = Self.load(name) else {
            lock.lock(); missing.insert(key); lock.unlock()
            return nil
        }
        lock.lock(); defer { lock.unlock() }
        if let cached = loaded[key] { return cached }
        loaded[key] = parsed
        return parsed
    }

    // MARK: - Colors

    /// The print palette, adjusted per appearance for on-screen legibility.
    /// r red, b blue, m magenta, c cyan, o orange, g green, l royal, y olive.
    static func uiColor(for letter: Character) -> UIColor {
        func dyn(_ light: (CGFloat, CGFloat, CGFloat), _ dark: (CGFloat, CGFloat, CGFloat)) -> UIColor {
            UIColor { traits in
                let c = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
            }
        }
        switch letter {
        case "m": return dyn((0.78, 0.00, 0.58), (1.00, 0.38, 0.86))
        case "b": return dyn((0.05, 0.20, 0.88), (0.42, 0.60, 1.00))
        case "r": return dyn((0.82, 0.06, 0.06), (1.00, 0.42, 0.36))
        case "c": return dyn((0.00, 0.52, 0.66), (0.30, 0.83, 1.00))
        case "o": return dyn((0.85, 0.42, 0.00), (1.00, 0.64, 0.22))
        case "g": return dyn((0.00, 0.58, 0.12), (0.32, 0.88, 0.42))
        case "l": return dyn((0.32, 0.42, 0.95), (0.60, 0.72, 1.00))
        case "y": return dyn((0.55, 0.53, 0.00), (0.82, 0.80, 0.28))
        default:  return .label
        }
    }

    // MARK: - Coloring

    /// `displayText` colored from the riwayah's print, letter-precise like the
    /// Hafs engine: the pack says WHICH word carries a rule (straight from the
    /// print), and a per-rule resolver says WHICH LETTERS of that word the rule
    /// lives on (the ṣād of an ishmām, the final mīm of a ṣilah, the inclined
    /// vowel of an imālah, the merging letter of an idghām, ...). A resolver
    /// that can't find its target letters falls back to the whole word.
    /// `hiddenRules` (rule keys) come from the legend's show/hide toggles.
    /// Nil when nothing paints (plain text renders cheaper).
    func attributedText(tag: String, surah: Int, ayah: Int, displayText: String,
                        hiddenRules: Set<String> = []) -> AttributedString? {
        guard let pack = pack(for: tag),
              let rules = pack.rules[surah]?[ayah], !rules.isEmpty else { return nil }
        var keyOf: [Character: String] = [:]
        for entry in pack.legend { keyOf[entry.letter] = entry.key }

        let ns = NSMutableAttributedString(string: displayText)
        ns.addAttribute(.foregroundColor, value: UIColor.label,
                        range: NSRange(location: 0, length: ns.length))

        let units = Array(displayText.utf16)
        var tokenIndex = 0
        var start = 0
        var painted = false
        var i = 0
        while i <= units.count {
            let isBreak = i == units.count || units[i] == 0x20 || units[i] == 0xA0
            if isBreak {
                if i > start {
                    if let rule = rules[tokenIndex] {
                        let key = keyOf[rule.letter] ?? String(rule.letter)
                        if !hiddenRules.contains(key) {
                            // Rules whose target letter is DETERMINED by the rule itself
                            // (the final mim of a silah, the sad of an ishmam, ...) use the
                            // resolver - the print's floating signs sit BETWEEN words and
                            // their ink bleeds into neighbor runs, so measured extents are
                            // noisy exactly for these. Positional rules (which letter of
                            // the word differs from Hafs, where the imalah/idgham sits)
                            // use the extent measured off the print, resolver as fallback.
                            let resolverFirst = ["silah_meem", "ha_dhamir", "ishmam_sad",
                                                 "raa_muraqqaqah", "lam_mughallazah"].contains(key)
                            let ranges: [NSRange]
                            if !resolverFirst, rule.hasExtent,
                               let extent = Self.clusterRange(baseLo: rule.baseLo, baseHi: rule.baseHi,
                                                              in: units, tokenStart: start, tokenEnd: i) {
                                ranges = [extent]
                            } else {
                                ranges = Self.paintRanges(key: key, in: units, tokenStart: start, tokenEnd: i)
                            }
                            for range in ranges {
                                ns.addAttribute(.foregroundColor, value: Self.uiColor(for: rule.letter), range: range)
                                painted = true
                            }
                        }
                    }
                    tokenIndex += 1
                }
                start = i + 1
            }
            i += 1
        }
        guard painted else { return nil }
        return AttributedString(ns)
    }

    // MARK: Letter resolvers

    private static func isBase(_ u: UInt16) -> Bool {
        (0x0621...0x064A).contains(u) || u == 0x0671 || u == 0x0649 || u == 0x066E || u == 0x06CC || u == 0x067E
    }

    /// Everything that rides on a base letter: harakat, tanwin, sukoons, madd
    /// signs, small letters, and the imalah/taqlil dots.
    private static func isCombining(_ u: UInt16) -> Bool {
        (0x064B...0x065F).contains(u) || u == 0x0670
            || (0x06D6...0x06ED).contains(u) || u == 0x0653 || u == 0x0654 || u == 0x0655
    }

    private struct Cluster {
        let base: UInt16
        let start: Int   // utf16 index of the base
        let end: Int     // one past the last combining mark
    }

    /// The token as base-letter clusters (base + its riding marks).
    private static func clusters(in units: [UInt16], from lo: Int, to hi: Int) -> [Cluster] {
        var out: [Cluster] = []
        var i = lo
        while i < hi {
            if isBase(units[i]) {
                let s = i
                var j = i + 1
                while j < hi, !isBase(units[j]) { j += 1 }
                out.append(Cluster(base: units[i], start: s, end: j))
                i = j
            } else {
                i += 1
            }
        }
        return out
    }

    private static func range(_ from: Cluster, _ to: Cluster) -> NSRange {
        NSRange(location: from.start, length: to.end - from.start)
    }

    /// UTF-16 range of base-letter clusters [baseLo, baseHi) of the token -
    /// the letter indexes the extraction measured off the print's ink.
    private static func clusterRange(baseLo: Int, baseHi: Int, in units: [UInt16],
                                     tokenStart: Int, tokenEnd: Int) -> NSRange? {
        let cl = clusters(in: units, from: tokenStart, to: tokenEnd)
        guard baseLo >= 0, baseHi > baseLo, baseLo < cl.count else { return nil }
        let hi = min(baseHi, cl.count)
        return range(cl[baseLo], cl[hi - 1])
    }

    /// Which letters of the flagged word the rule paints.
    private static func paintRanges(key: String, in units: [UInt16], tokenStart: Int, tokenEnd: Int) -> [NSRange] {
        let whole = [NSRange(location: tokenStart, length: tokenEnd - tokenStart)]
        let cl = clusters(in: units, from: tokenStart, to: tokenEnd)
        guard !cl.isEmpty else { return whole }

        func hasMark(_ c: Cluster) -> Bool {
            for k in c.start..<c.end where units[k] == 0x065C || units[k] == 0x06EA { return true }
            return false
        }

        switch key {
        case "imalah", "imalah_taqlil", "taqlil":
            // The printed dot marks the exact letter; paint its cluster plus the
            // inclined vowel glyph after it (alif / maqsura / dagger-alif rides inside).
            if let idx = cl.firstIndex(where: hasMark) {
                let next = idx + 1 < cl.count ? cl[idx + 1] : cl[idx]
                let isVowel = next.base == 0x0627 || next.base == 0x0649 || next.base == 0x0671
                return [range(cl[idx], isVowel ? next : cl[idx])]
            }
            // No mark in the text (Yaqub / Khalaf al-Ashir): the inclination is on
            // the final 'aa' - paint the last alif/maqsura cluster with its lead-in.
            if let idx = cl.lastIndex(where: { $0.base == 0x0627 || $0.base == 0x0649 || $0.base == 0x0671 }) {
                return [range(cl[max(0, idx - 1)], cl[idx])]
            }
            return whole

        case "idgham":
            // The merge happens at the word's junction: its final letter.
            return [range(cl[cl.count - 1], cl[cl.count - 1])]

        case "silah_meem":
            if let idx = cl.lastIndex(where: { $0.base == 0x0645 }) {
                return [NSRange(location: cl[idx].start, length: tokenEnd - cl[idx].start)]
            }
            return whole

        case "ha_dhamir":
            if let idx = cl.lastIndex(where: { $0.base == 0x0647 }) {
                return [NSRange(location: cl[idx].start, length: tokenEnd - cl[idx].start)]
            }
            return whole

        case "ishmam_sad":
            let sads = cl.filter { $0.base == 0x0635 }.map { range($0, $0) }
            return sads.isEmpty ? whole : sads

        case "raa_muraqqaqah":
            let ras = cl.filter { $0.base == 0x0631 }.map { range($0, $0) }
            return ras.isEmpty ? whole : ras

        case "lam_mughallazah":
            // Warsh thickens the lam after sad/ta/zha; prefer those, else any lam.
            var heavy: [NSRange] = []
            var any: [NSRange] = []
            for (i, c) in cl.enumerated() where c.base == 0x0644 {
                any.append(range(c, c))
                if i > 0, [0x0635, 0x0637, 0x0638].contains(Int(cl[i - 1].base)) {
                    heavy.append(range(c, c))
                }
            }
            return heavy.isEmpty ? (any.isEmpty ? whole : any) : heavy

        case "ghunnah_kha_ghayn":
            // The kept ghunnah sits on a noon (or tanwin) meeting kha/ghayn.
            for (i, c) in cl.enumerated() where c.base == 0x0646 {
                if i + 1 < cl.count, c.base == 0x0646, [0x062E, 0x063A].contains(Int(cl[i + 1].base)) {
                    return [range(c, c)]
                }
            }
            if let idx = cl.lastIndex(where: { $0.base == 0x0646 }) {
                return [range(cl[idx], cl[idx])]
            }
            return whole

        case "madd_badal":
            // Hamzah then a lengthened vowel (e.g. آمنوا).
            let hamzas: Set<UInt16> = [0x0621, 0x0622, 0x0623, 0x0624, 0x0625, 0x0626]
            for (i, c) in cl.enumerated() where hamzas.contains(c.base) || c.base == 0x0622 {
                if c.base == 0x0622 { return [range(c, c)] }   // madda alif carries both
                if i + 1 < cl.count, [0x0627, 0x0648, 0x064A, 0x0649].contains(Int(cl[i + 1].base)) {
                    return [range(c, cl[i + 1])]
                }
            }
            return whole

        case "madd_leen":
            // Soft waw/ya before the final letter.
            if cl.count >= 2 {
                for i in stride(from: cl.count - 2, through: 0, by: -1)
                where cl[i].base == 0x0648 || cl[i].base == 0x064A {
                    return [range(cl[max(0, i - 1)], cl[i])]
                }
            }
            return whole

        case "sakt":
            // The pause is at the word's end.
            return [range(cl[cl.count - 1], cl[cl.count - 1])]

        default:
            // khilaf_word / khilaf_harf and anything unknown: the print flags the
            // word; without a reliable letter-level diff, paint it whole.
            return whole
        }
    }

    // MARK: - Loading

    private static func load(_ name: String) -> Pack? {
        guard let json = SolidPack.json(named: name, inPack: "tajweed") ?? looseJSON(name),
              let raw = try? JSONSerialization.jsonObject(with: json) as? [String: Any] else { return nil }

        var rules: [Int: [Int: [Int: WordRule]]] = [:]
        if let rulesRaw = raw["rules"] as? [String: [String: [String: Any]]] {
            rules.reserveCapacity(rulesRaw.count)
            for (s, ayahs) in rulesRaw {
                guard let sid = Int(s) else { continue }
                var surahOut: [Int: [Int: WordRule]] = [:]
                for (a, words) in ayahs {
                    guard let aid = Int(a) else { continue }
                    var wordOut: [Int: WordRule] = [:]
                    for (wi, value) in words {
                        guard let w = Int(wi) else { continue }
                        // "m" = whole word; ["m", lo, hi] = the print's own
                        // colored-letter extent (base-letter indexes).
                        if let s = value as? String, let letter = s.first {
                            wordOut[w] = WordRule(letter: letter, baseLo: -1, baseHi: -1)
                        } else if let arr = value as? [Any], arr.count == 3,
                                  let s = arr[0] as? String, let letter = s.first,
                                  let lo = arr[1] as? Int, let hi = arr[2] as? Int {
                            wordOut[w] = WordRule(letter: letter, baseLo: lo, baseHi: hi)
                        }
                    }
                    if !wordOut.isEmpty { surahOut[aid] = wordOut }
                }
                if !surahOut.isEmpty { rules[sid] = surahOut }
            }
        }

        var pages: [Int: [Int: Int]] = [:]
        if let pagesRaw = raw["pages"] as? [String: [String: Int]] {
            pages.reserveCapacity(pagesRaw.count)
            for (s, ayahs) in pagesRaw {
                guard let sid = Int(s) else { continue }
                var surahOut: [Int: Int] = [:]
                surahOut.reserveCapacity(ayahs.count)
                for (a, page) in ayahs {
                    guard let aid = Int(a) else { continue }
                    surahOut[aid] = page
                }
                pages[sid] = surahOut
            }
        }

        var legend: [LegendEntry] = []
        if let legendRaw = raw["legend"] as? [[String: String]] {
            for entry in legendRaw {
                guard let c = entry["c"]?.first, let ar = entry["ar"], let en = entry["en"] else { continue }
                legend.append(LegendEntry(letter: c, key: entry["k"] ?? String(c), arabic: ar, english: en))
            }
        }

        var khilaf: [Int: Set<Int>] = [:]
        if let khilafRaw = raw["khilafMarkers"] as? [String: [Int]] {
            for (s, ayahs) in khilafRaw {
                guard let sid = Int(s) else { continue }
                khilaf[sid] = Set(ayahs)
            }
        }

        guard !rules.isEmpty || !pages.isEmpty else { return nil }
        return Pack(rules: rules, pages: pages, legend: legend, khilafMarkers: khilaf)
    }

    /// The pre-solidpack loose-file path, kept as a fallback: a `Tajweed<name>.json.deflate`
    /// dropped into the bundle loads without a repack step (mirrors `BetaQiraatStore`).
    private static func looseJSON(_ name: String) -> Data? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json.deflate", subdirectory: "QiraahBeta")
            ?? Bundle.main.url(forResource: name, withExtension: "json.deflate", subdirectory: "Data/QiraahBeta")
            ?? Bundle.main.url(forResource: name, withExtension: "json.deflate"),
              let blob = try? Data(contentsOf: url) else { return nil }
        return inflate(blob)
    }

    private static func inflate(_ data: Data) -> Data? {
        let capacity = max(data.count * 12, 1 << 21)
        var out = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        defer { buffer.deallocate() }
        let written = data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> Int in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return compression_decode_buffer(buffer, capacity, base, data.count, nil, COMPRESSION_ZLIB)
        }
        guard written > 0 else { return nil }
        out.append(buffer, count: written)
        return out
    }
}

#endif
