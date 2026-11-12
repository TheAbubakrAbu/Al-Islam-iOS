#if os(iOS)
import Foundation
import SwiftUI
import UIKit

/// "Differs from Hafs" one letter at a time (Abu, 2026-11-01: "instead of highlighting whole words
/// i want just individual letters", starting with Warsh).
///
/// The print already says WHICH letters of the riwayah's word are read differently: the tajweed pack's
/// khilaf extents are the magenta the printed mushaf inks, cluster by cluster. What was still a whole
/// word was the computed accent tint drawn where that paint is not: the reader with Tajweed Colors
/// off, and the comparison sheet's rows. This carries the print's letters into both places, and over
/// to the Hafs side: each marked letter of the riwayah's word lands on its counterpart letter in the
/// Hafs word (letters aligned on their folded bases), and a Hafs letter the riwayah drops counts as
/// changed too. A word the print leaves black stays plain on both sides; a Hafs word the riwayah has
/// no word for stays tinted whole (there is no letter to point at). The Qiraat Explorer's cards
/// (the Hafs ayah, each riwayah's whole ayah, the site readings, Compare Two) are tinted from the
/// same letters by `QiraatPlaceBuilder.tints`, through `projectedRanges` and `ownLetterRanges`.
enum QiraatLetterDiff {
    /// The riwayat whose "differs from Hafs" tint is drawn letter by letter. A print joins the list
    /// once its khilaf extents have been measured against its pages: Warsh (5,705 of 7,405 marked
    /// words are one letter), Qalun (1,207 of 1,510), al-Bazzi (942 of 1,267), Qunbul (990 of
    /// 1,321), as-Susi (2,268 of 2,556), Shubah (420 of 550), Hisham (694 of 931), Ibn Dhakwan
    /// (603 of 803), Abu al-Harith (961 of 1,208), ad-Duri an al-Kisai (941 of 1,202), Ibn Wardan
    /// (2,437 of 2,812), Ibn Jammaz (2,426 of 2,800), Ruways (1,392 of 1,676), Rawh (1,091 of
    /// 1,359), Ishaq (579 of 750) and Idris (the same 579 of 750: his pack and his text are Ishaq's
    /// byte for byte). ad-Duri an Abi Amr's, Khalaf's and Khallad's prints ink whole words, so their
    /// letters come from the builder instead: it narrows each marked word to the clusters that differ
    /// from the aligned Hafs word (ad-Duri: 1,215 of 1,459 are one letter, 3 keep the whole word;
    /// Khalaf: 767 of 999, 7 keep the whole word; Khallad: 774 of 997, 4 keep the whole word).
    static let letterLevelTags: Set<String> = [Settings.Riwayah.warsh, Settings.Riwayah.qaloon,
                                               Settings.Riwayah.buzzi, Settings.Riwayah.qunbul,
                                               Settings.Riwayah.susi, Settings.Riwayah.shubah,
                                               Settings.Riwayah.duri,
                                               Settings.Riwayah.hisham, Settings.Riwayah.ibnDhakwan,
                                               Settings.Riwayah.khalaf, Settings.Riwayah.khallad,
                                               Settings.Riwayah.abuHarith, Settings.Riwayah.duriKisai,
                                               Settings.Riwayah.ibnWardan, Settings.Riwayah.ibnJammaz,
                                               Settings.Riwayah.ruways, Settings.Riwayah.rawh,
                                               Settings.Riwayah.ishaq, Settings.Riwayah.idris]

    /// Whether `tag`'s differences are shown letter by letter: a listed riwayah whose pack is bundled
    /// and whose text may render. A beta print's pack is bundled before its text is unlocked, and
    /// until then `textArabic` hands back Hafs, which the pack's extents do not describe.
    static func isLetterLevel(tag: String) -> Bool {
        let canonical = Settings.Riwayah.canonicalTag(tag)
        guard hasLetterPack(tag: canonical) else { return false }
        if Settings.Riwayah.isBeta(canonical), !Settings.shared.betaQiraatEnabled { return false }
        return true
    }

    /// `isLetterLevel` without the beta gate: a listed riwayah whose pack is bundled. For callers
    /// that already hold a text the gate let through (the Explorer builds its places off the main
    /// thread, from the riwayat the gate enabled, and reads no setting there).
    static func hasLetterPack(tag: String) -> Bool {
        let canonical = Settings.Riwayah.canonicalTag(tag)
        guard !canonical.isEmpty, letterLevelTags.contains(canonical) else { return false }
        return QiraahTajweedStore.shared.isAvailable(tag: canonical)
    }

    // MARK: - The Hafs side of one ayah

    /// The UTF-16 ranges of `hafsText` (one Hafs ayah, fully vocalized) that `tag` reads differently:
    /// the print's khilaf letters of the riwayah's own ayah (`ownAyah`, or every piece of `splitSpan`
    /// when the riwayah divides this Hafs ayah) carried over to their Hafs counterparts, plus whole
    /// Hafs words the riwayah has no word for. Stop signs are never inside a range. Nil when `tag` is
    /// not letter-level. Safe off the main thread: it reads the lock-guarded store and QuranData.
    static func hafsLetterRanges(hafsText: String, tag: String, surah: Int, ownAyah: Int,
                                 splitSpan: ClosedRange<Int>?) -> [NSRange]? {
        let canonical = Settings.Riwayah.canonicalTag(tag)
        guard isLetterLevel(tag: canonical) else { return nil }
        let store = QiraahTajweedStore.shared
        let quranData = QuranData.shared
        var riwayahWords: [(text: String, extents: [(lo: Int, hi: Int)])] = []
        for own in splitSpan.map(Array.init) ?? [ownAyah] {
            guard let ayah = quranData.ayah(surah: surah, ayah: own) else { continue }
            let piece = ayah.rawArabicText(surahId: surah, qiraahOverride: canonical)
            let extents = store.khilafExtents(tag: canonical, surah: surah, ayah: own)
            for (index, word) in WordTokens.tokens(in: piece).enumerated() {
                riwayahWords.append((word, extents[index] ?? []))
            }
        }
        let hafs = hafsText as NSString
        let hafsRanges = WordTokens.ranges(in: hafsText)
        let hafsWords = hafsRanges.map { hafs.substring(with: $0) }
        let pairing = pairWords(hafs: hafsWords, riwayah: riwayahWords.map(\.text))
        var ranges: [NSRange] = []
        for (hafsIndex, riwayahIndex) in pairing.pairs {
            let word = riwayahWords[riwayahIndex]
            guard !word.extents.isEmpty else { continue }
            let base = hafsRanges[hafsIndex].location
            for range in projectedRanges(hafsWord: hafsWords[hafsIndex], riwayahWord: word.text, extents: word.extents) {
                ranges.append(NSRange(location: base + range.location, length: range.length))
            }
        }
        for hafsIndex in pairing.hafsOnly { ranges.append(hafsRanges[hafsIndex]) }
        let units = Array(hafsText.utf16)
        return ranges.sorted { $0.location < $1.location }.flatMap { withoutStopSigns($0, in: units) }
    }

    /// `text` with `ranges` in `tint` over `base`, as the comparison rows read it (SwiftUI colors).
    /// With a stripped `displayText` (the sheet's Hide Tashkeel / Hide Dots), the tint is laid over
    /// the full text and carried onto the stripped twin; nil when the twin is not a recognized strip.
    static func attributed(fullText: String, ranges: [NSRange], displayText: String,
                           base: Color, tint: Color) -> AttributedString? {
        if displayText == fullText {
            var attributed = AttributedString(fullText)
            attributed.foregroundColor = base
            for range in ranges {
                guard let swiftRange = Range(range, in: fullText),
                      let lo = AttributedString.Index(swiftRange.lowerBound, within: attributed),
                      let hi = AttributedString.Index(swiftRange.upperBound, within: attributed), lo < hi else { continue }
                attributed[lo..<hi].foregroundColor = tint
            }
            return attributed
        }
        var plain = AttributedString(displayText)
        plain.foregroundColor = base
        guard !ranges.isEmpty else { return plain }
        let painted = NSMutableAttributedString(string: fullText)
        painted.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: painted.length))
        for range in ranges where NSMaxRange(range) <= painted.length {
            painted.addAttribute(.foregroundColor, value: UIColor(tint), range: range)
        }
        guard let projected = QiraahTajweedStore.projectColors(from: AttributedString(painted), fullText: fullText,
                                                               onto: displayText) else { return plain }
        let projectedNS = NSAttributedString(projected)
        projectedNS.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: projectedNS.length)) { value, nsRange, _ in
            guard let color = value as? UIColor, color != .label,
                  let swiftRange = Range(nsRange, in: displayText),
                  let lo = AttributedString.Index(swiftRange.lowerBound, within: plain),
                  let hi = AttributedString.Index(swiftRange.upperBound, within: plain), lo < hi else { return }
            plain[lo..<hi].foregroundColor = tint
        }
        return plain
    }

    // MARK: - Pairing the words

    struct WordPairing: Equatable {
        /// Hafs token index -> riwayah token index, for every word with a counterpart.
        let pairs: [Int: Int]
        /// Hafs words with no counterpart (the riwayah reads none of them), ascending.
        let hafsOnly: [Int]
        /// Riwayah words with no counterpart (added words), ascending.
        let riwayahOnly: [Int]
    }

    /// Which riwayah word answers to which Hafs word: the folded-word LCS (the Explorer's diff), then
    /// the leftovers between two matched words paired positionally where both sides left the same
    /// number: a replaced word is usually the khilaf word itself, the one that matters most.
    static func pairWords(hafs: [String], riwayah: [String]) -> WordPairing {
        let hafsFolded = hafs.map { HighlightedSnippet.normalizeForSearchText($0, trimWhitespace: true) }
        let riwayahFolded = riwayah.map { HighlightedSnippet.normalizeForSearchText($0, trimWhitespace: true) }
        var pairs: [Int: Int] = [:]
        for (h, r) in lcsPairs(hafsFolded, riwayahFolded, equal: { !$0.isEmpty && $0 == $1 }) { pairs[h] = r }

        // Fill the gaps: between two matched words (and before the first, after the last), the Hafs
        // words left over against the riwayah words left over, when their counts agree.
        let matched = pairs.sorted { $0.key < $1.key }
        var hafsCursor = 0
        var riwayahCursor = 0
        func fill(hafsEnd: Int, riwayahEnd: Int) {
            let hafsGap = (hafsCursor..<hafsEnd).filter { !hafsFolded[$0].isEmpty }
            let riwayahGap = (riwayahCursor..<riwayahEnd).filter { !riwayahFolded[$0].isEmpty }
            guard !hafsGap.isEmpty, hafsGap.count == riwayahGap.count else { return }
            for (h, r) in zip(hafsGap, riwayahGap) { pairs[h] = r }
        }
        for (h, r) in matched {
            fill(hafsEnd: h, riwayahEnd: r)
            hafsCursor = h + 1
            riwayahCursor = r + 1
        }
        fill(hafsEnd: hafs.count, riwayahEnd: riwayah.count)

        let riwayahMatched = Set(pairs.values)
        let hafsOnly = hafs.indices.filter { pairs[$0] == nil && !hafsFolded[$0].isEmpty }
        let riwayahOnly = riwayah.indices.filter { !riwayahMatched.contains($0) && !riwayahFolded[$0].isEmpty }
        return WordPairing(pairs: pairs, hafsOnly: hafsOnly, riwayahOnly: riwayahOnly)
    }

    // MARK: - The riwayah's own letters

    /// The UTF-16 ranges inside the riwayah's own `word` that its print marks: `extents` are the
    /// pack's INCLUSIVE base-letter cluster ranges (lo -1 = the whole word), each run of marked
    /// clusters one range, stop signs left out. What the reader's `khilafText` paints, for a word
    /// held on its own (the Explorer's riwayah cards and site readings).
    static func ownLetterRanges(word: String, extents: [(lo: Int, hi: Int)]) -> [NSRange] {
        let wordClusters = clusters(of: word)
        guard !wordClusters.isEmpty, !extents.isEmpty else { return [] }
        var marked = Set<Int>()
        for extent in extents {
            if extent.lo < 0 {
                marked.formUnion(wordClusters.indices)
            } else if extent.lo <= extent.hi, extent.lo < wordClusters.count {
                marked.formUnion(extent.lo...min(extent.hi, wordClusters.count - 1))
            }
        }
        let units = Array(word.utf16)
        return joined(marked, of: wordClusters).flatMap { withoutStopSigns($0, in: units) }
    }

    /// Contiguous runs of marked clusters, each one range (clusters tile the word in order).
    private static func joined(_ marked: Set<Int>, of wordClusters: [Cluster]) -> [NSRange] {
        var ranges: [NSRange] = []
        for index in marked.sorted() {
            let cluster = wordClusters[index].range
            if let last = ranges.last, NSMaxRange(last) == cluster.location {
                ranges[ranges.count - 1] = NSRange(location: last.location, length: last.length + cluster.length)
            } else {
                ranges.append(cluster)
            }
        }
        return ranges
    }

    // MARK: - A word the print leaves black

    /// For a changed word the print does not mark (al-Bazzi's silah رَزَقۡنَٰهُمُو files its wāw under
    /// his silah rule, not his khilaf colour; Warsh's print does not ink مَلِكِ at 1:4): the letters
    /// the two words themselves disagree on. Letters are paired on their folded bases; a pair whose
    /// base or marks differ is changed, a letter only one side has is changed, and an added letter
    /// lands on the Hafs letter it follows (`projectedRanges`). Both sides' ranges, each in its own
    /// word; both empty when the words agree letter for letter and mark for mark, which leaves
    /// them whole. The Explorer's cards use it where the pack says nothing (`QiraatPlaceBuilder`).
    static func wordDiffRanges(hafsWord: String, riwayahWord: String) -> (hafs: [NSRange], riwayah: [NSRange]) {
        let hafsClusters = clusters(of: hafsWord)
        let riwayahClusters = clusters(of: riwayahWord)
        guard !hafsClusters.isEmpty, !riwayahClusters.isEmpty else { return ([], []) }
        let hafsUnits = Array(hafsWord.utf16)
        let riwayahUnits = Array(riwayahWord.utf16)
        var riwayahChanged = Set(riwayahClusters.indices)
        var hafsChanged = Set(hafsClusters.indices)
        for (r, h) in lcsPairs(riwayahClusters.map { foldedBase($0.base) }, hafsClusters.map { foldedBase($0.base) },
                               equal: { $0 == $1 })
        where riwayahClusters[r].base == hafsClusters[h].base
            && marks(of: riwayahClusters[r], in: riwayahUnits) == marks(of: hafsClusters[h], in: hafsUnits) {
            riwayahChanged.remove(r)
            hafsChanged.remove(h)
        }
        let extents = riwayahChanged.sorted().map { (lo: $0, hi: $0) }
        let hafs: [NSRange]
        if extents.isEmpty {
            hafs = joined(hafsChanged, of: hafsClusters).flatMap { withoutStopSigns($0, in: hafsUnits) }
        } else {
            hafs = projectedRanges(hafsWord: hafsWord, riwayahWord: riwayahWord, extents: extents)
                .flatMap { withoutStopSigns($0, in: hafsUnits) }
        }
        return (hafs, ownLetterRanges(word: riwayahWord, extents: extents))
    }

    /// The marks riding on a cluster's base, sorted (the texts write them in more than one order);
    /// a stop sign is no part of the reading.
    private static func marks(of cluster: Cluster, in units: [UInt16]) -> [UInt16] {
        guard cluster.range.length > 1 else { return [] }
        return units[(cluster.range.location + 1)..<NSMaxRange(cluster.range)]
            .filter { !TajweedRules.stopSignUTF16.contains($0) }
            .sorted()
    }

    // MARK: - Carrying letters over

    /// The UTF-16 ranges inside `hafsWord` that answer to the riwayah word's marked letters:
    /// `extents` are the pack's INCLUSIVE base-letter cluster ranges of `riwayahWord` (lo -1 = the
    /// whole word). Letters are paired on their folded bases; a marked riwayah letter lands on its
    /// pair (or, when the riwayah adds it, on the Hafs letter it follows), and every Hafs letter
    /// without a pair (one the riwayah drops) is changed by definition.
    static func projectedRanges(hafsWord: String, riwayahWord: String, extents: [(lo: Int, hi: Int)]) -> [NSRange] {
        let hafsClusters = clusters(of: hafsWord)
        let riwayahClusters = clusters(of: riwayahWord)
        guard !hafsClusters.isEmpty, !riwayahClusters.isEmpty, !extents.isEmpty else { return [] }

        var marked = Set<Int>()
        for extent in extents {
            if extent.lo < 0 {
                marked.formUnion(riwayahClusters.indices)
            } else if extent.lo <= extent.hi, extent.lo < riwayahClusters.count {
                marked.formUnion(extent.lo...min(extent.hi, riwayahClusters.count - 1))
            }
        }
        guard !marked.isEmpty else { return [] }

        var riwayahToHafs: [Int: Int] = [:]
        for (r, h) in lcsPairs(riwayahClusters.map { foldedBase($0.base) }, hafsClusters.map { foldedBase($0.base) },
                               equal: { $0 == $1 }) {
            riwayahToHafs[r] = h
        }
        let hafsPaired = Set(riwayahToHafs.values)
        var hafsMarked = Set<Int>()
        for (r, h) in riwayahToHafs where marked.contains(r) { hafsMarked.insert(h) }
        for h in hafsClusters.indices where !hafsPaired.contains(h) { hafsMarked.insert(h) }
        // A marked letter the riwayah ADDS has no pair. When a Hafs letter sits in the same gap it is
        // the counterpart (a swapped letter, marked above as unpaired); otherwise the added letter
        // points at the Hafs letter it follows (or the one after it at the start of a word), so the
        // word still shows where to look: Warsh's إِبۡرَٰهِـيمَ marks its yā, and Hafs's small yā rides
        // on the tatweel before it.
        for r in marked.sorted() where riwayahToHafs[r] == nil {
            let before = (0..<r).reversed().lazy.compactMap { riwayahToHafs[$0] }.first
            let after = ((r + 1)..<riwayahClusters.count).lazy.compactMap { riwayahToHafs[$0] }.first
            let gapStart = before.map { $0 + 1 } ?? 0
            let gapEnd = after ?? hafsClusters.count
            guard gapStart >= gapEnd, let anchor = before ?? after else { continue }
            hafsMarked.insert(anchor)
        }

        return joined(hafsMarked, of: hafsClusters)
    }

    // MARK: - Letters

    struct Cluster: Equatable {
        let base: UInt16
        /// The base letter and every mark riding on it, in UTF-16 units of the word.
        let range: NSRange
    }

    /// The word as base-letter clusters (base + its riding marks), the pack's own unit.
    static func clusters(of word: String) -> [Cluster] {
        let units = Array(word.utf16)
        var out: [Cluster] = []
        var i = 0
        while i < units.count {
            guard isBase(units[i]) else { i += 1; continue }
            var j = i + 1
            while j < units.count, !isBase(units[j]) { j += 1 }
            out.append(Cluster(base: units[i], range: NSRange(location: i, length: j - i)))
            i = j
        }
        return out
    }

    /// The same base-letter set the tajweed store clusters on.
    static func isBase(_ u: UInt16) -> Bool {
        (0x0621...0x064A).contains(u) || u == 0x0671 || u == 0x0649 || u == 0x066E || u == 0x06CC || u == 0x067E
            || u == 0x066F || u == 0x06A1 || u == 0x06BA
    }

    /// A base for pairing letters across spellings: the hamzah seats and the two alifs fold onto their
    /// carriers (Warsh's يُومِنُونَ pairs its wāw with Hafs's ؤ), as the builder's letter spine does.
    static func foldedBase(_ u: UInt16) -> UInt16 {
        switch u {
        case 0x0671, 0x0622, 0x0623, 0x0625: return 0x0627   // ٱ آ أ إ -> ا
        case 0x0624: return 0x0648                           // ؤ -> و
        case 0x0626, 0x0649, 0x06CC: return 0x064A            // ئ ى -> ي
        case 0x066E: return 0x0628                           // dotless ba
        case 0x066F, 0x06A1: return 0x0642                   // dotless qaf / feh
        case 0x06BA: return 0x0646                           // dotless noon
        default: return u
        }
    }

    // MARK: - Helpers

    /// The longest common subsequence of `a` and `b` under `equal`, as index pairs in order.
    static func lcsPairs<T>(_ a: [T], _ b: [T], equal: (T, T) -> Bool) -> [(Int, Int)] {
        guard !a.isEmpty, !b.isEmpty else { return [] }
        var table = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in stride(from: a.count - 1, through: 0, by: -1) {
            for j in stride(from: b.count - 1, through: 0, by: -1) {
                table[i][j] = equal(a[i], b[j]) ? table[i + 1][j + 1] + 1 : max(table[i + 1][j], table[i][j + 1])
            }
        }
        var pairs: [(Int, Int)] = []
        var i = 0
        var j = 0
        while i < a.count, j < b.count {
            if equal(a[i], b[j]) {
                pairs.append((i, j))
                i += 1
                j += 1
            } else if table[i + 1][j] >= table[i][j + 1] {
                i += 1
            } else {
                j += 1
            }
        }
        return pairs
    }

    /// `range` minus the stop-sign ornaments inside it, as the runs between them (user rule: stop signs
    /// are never highlighted).
    static func withoutStopSigns(_ range: NSRange, in units: [UInt16]) -> [NSRange] {
        let end = min(NSMaxRange(range), units.count)
        var start = max(range.location, 0)
        guard start < end else { return [] }
        var runs: [NSRange] = []
        var runStart = start
        while start < end {
            if TajweedRules.stopSignUTF16.contains(units[start]) {
                if start > runStart { runs.append(NSRange(location: runStart, length: start - runStart)) }
                runStart = start + 1
            }
            start += 1
        }
        if end > runStart { runs.append(NSRange(location: runStart, length: end - runStart)) }
        return runs
    }
}
#endif
