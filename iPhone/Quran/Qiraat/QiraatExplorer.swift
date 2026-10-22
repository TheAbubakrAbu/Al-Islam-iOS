#if os(iOS)
import SwiftUI

// The Qiraat Explorer's data: where the riwayat differ from Hafs, found rather than hunted for.
//
// The comparison sheet answers "how do the riwayat read THIS ayah". The explorer answers the question
// before it: WHERE do they differ at all. Only a fraction of the Quran's ayahs are read differently
// by any riwayah, so the explorer steps from one such place to the next (across surahs). This file
// holds the word diff, what one riwayah changes, the tint and the place index, plus the explorer's
// two sheets; QiraatPlace.swift works a place out word by word and QiraatExplorerView.swift is the
// screen (both since the 2026-10-09 redesign).
//
// The differences come from two sources that see different things: the folded-word diff of the two
// texts (dropped, added or re-dotted words) and each riwayah's printed mushaf, whose khilaf wash
// (the tajweed pack) flags words read with other vowels over the same skeleton, which a folded diff
// is blind to (مَٰلِكِ / مَلِكِ in al-Fatiha). The per-riwayah place index is precomputed in the app itself
// ("-exportQiraatPlaces", DEBUG) into Resources/Data/Quran/QiraatPlaces.json.xz; without the pack
// the same computation runs per surah on demand.

// MARK: - Word diff with a mapping

/// The folded-word LCS between a Hafs text and a riwayah's, keeping the MAPPING (which Hafs word a
/// riwayah word answers to) rather than only the leftovers, so a word the print flags as read
/// differently while its skeleton matches can be paired with its Hafs form.
enum QiraatWordDiff {
    struct Token {
        let range: Range<String.Index>
        let text: String
        let folded: String
    }

    struct Result {
        let hafs: [Token]
        let riwayah: [Token]
        /// Hafs token index -> riwayah token index, for the words both read alike (folded).
        let pairs: [Int: Int]
        /// Hafs tokens with no counterpart (dropped or replaced words), ascending.
        let hafsOnly: [Int]
        /// Riwayah tokens with no counterpart (added or replaced words), ascending.
        let riwayahOnly: [Int]
    }

    /// Whitespace-split tokens (space, NBSP, newline), the same units the tajweed packs and the
    /// comparison sheet's diff count words in.
    static func tokens(of text: String) -> [Token] {
        var result: [Token] = []
        var cursor = text.startIndex
        while cursor < text.endIndex {
            while cursor < text.endIndex, text[cursor].isWhitespace { cursor = text.index(after: cursor) }
            guard cursor < text.endIndex else { break }
            let start = cursor
            while cursor < text.endIndex, !text[cursor].isWhitespace { cursor = text.index(after: cursor) }
            let word = String(text[start..<cursor])
            result.append(Token(range: start..<cursor, text: word,
                                folded: HighlightedSnippet.normalizeForSearchText(word, trimWhitespace: true)))
        }
        return result
    }

    static func compare(hafs: String, riwayah: String) -> Result {
        let a = tokens(of: hafs)
        let b = tokens(of: riwayah)
        let af = a.map(\.folded)
        let bf = b.map(\.folded)
        var table = Array(repeating: Array(repeating: 0, count: bf.count + 1), count: af.count + 1)
        if !af.isEmpty, !bf.isEmpty {
            for i in stride(from: af.count - 1, through: 0, by: -1) {
                for j in stride(from: bf.count - 1, through: 0, by: -1) {
                    // Standalone signs fold to nothing and never pair - they are not words.
                    table[i][j] = (!af[i].isEmpty && af[i] == bf[j])
                        ? table[i + 1][j + 1] + 1
                        : max(table[i + 1][j], table[i][j + 1])
                }
            }
        }
        var pairs: [Int: Int] = [:]
        var i = 0
        var j = 0
        while i < af.count, j < bf.count {
            if !af[i].isEmpty, af[i] == bf[j] {
                pairs[i] = j
                i += 1
                j += 1
            } else if table[i + 1][j] >= table[i][j + 1] {
                i += 1
            } else {
                j += 1
            }
        }
        let matched = Set(pairs.values)
        let hafsOnly = a.indices.filter { pairs[$0] == nil && !af[$0].isEmpty }
        let riwayahOnly = b.indices.filter { !matched.contains($0) && !bf[$0].isEmpty }
        return Result(hafs: a, riwayah: b, pairs: pairs, hafsOnly: hafsOnly, riwayahOnly: riwayahOnly)
    }
}

// MARK: - What one riwayah changes

/// What one riwayah changes in one Hafs ayah (or in the joined span it reads as one ayah): the
/// words on each side, and where the Hafs words sit ayah by ayah.
struct QiraatChange {
    let hafsText: String
    let riwayahText: String
    let diff: QiraatWordDiff.Result
    /// Every differing Hafs token index over `hafsText`, ascending.
    let hafsWords: [Int]
    /// Every differing riwayah token index over `riwayahText`, ascending.
    let riwayahWords: [Int]
    /// The WORD-LEVEL subset: another word form, added or dropped letters, other vowels across the
    /// word (the folded diff plus the print's whole-word khilaf). The rest differ in one letter's
    /// dots, hamzah or vowel (the print's letter khilaf).
    let hafsWordLevel: Set<Int>
    let riwayahWordLevel: Set<Int>
    /// Hafs ayah -> its own differing token indices (local to that ayah's text), SIGNED: a
    /// word-level index as itself, a letter-level one as -(index + 1). The place index stores
    /// exactly this, so the explorer can step by notable changes or by every change.
    let hafsWordsByAyah: [Int: [Int]]
    /// Hafs ayah -> the index of its first token in `hafsText` (a joined span's earlier ayahs first).
    var hafsStartByAyah: [Int: Int] = [:]

    var differs: Bool { !hafsWords.isEmpty || !riwayahWords.isEmpty }
    var differsAtWordLevel: Bool { !hafsWordLevel.isEmpty || !riwayahWordLevel.isEmpty }

    /// The Hafs words that change, as one phrase (stop signs dropped).
    var hafsPhrase: String { Self.phrase(diff.hafs, hafsWords) }
    /// The riwayah's words in their place, as one phrase.
    var riwayahPhrase: String { Self.phrase(diff.riwayah, riwayahWords) }

    private static func phrase(_ tokens: [QiraatWordDiff.Token], _ indices: [Int]) -> String {
        indices.compactMap { tokens.indices.contains($0) ? QiraatTint.withoutStopSigns(tokens[$0].text) : nil }
            .joined(separator: " ")
    }

    /// Two folded words that differ only by a lengthening waw or ya on the riwayah's side (or on
    /// Hafs's, for a riwayah that shortens what Hafs lengthens): a silah, not another word.
    static func isSilahPair(hafs: String, riwayah: String) -> Bool {
        func stripped(_ word: String) -> String? {
            guard word.count >= 3, let last = word.last, last == "و" || last == "ي" else { return nil }
            return String(word.dropLast())
        }
        if let short = stripped(riwayah), short == hafs { return true }
        if let short = stripped(hafs), short == riwayah { return true }
        return false
    }

    /// What `tag` changes at one Hafs ayah. The Hafs side is the ayah itself or the whole span the
    /// riwayah joins; the riwayah side is its own ayah or every piece a split divides this ayah into.
    /// Both sides are the RAW texts (`rawArabicText`, as the resolver hands them back): a comparison
    /// made on the reader's Hide Dots text cannot see a difference that is only a letter's dots.
    /// Safe off the main thread, like everything it reads.
    static func at(tag: String, surah: Int, hafsAyah: Int, resolved: ResolvedQiraahText, quranData: QuranData) -> QiraatChange {
        let span = resolved.mergedSpan ?? (hafsAyah...hafsAyah)
        let hafsPieces: [(ayah: Int, text: String)] = span.compactMap { number in
            quranData.ayah(surah: surah, ayah: number).map { (number, $0.rawArabicText(surahId: surah, qiraahOverride: "")) }
        }
        let own = resolved.ownNumber ?? hafsAyah
        let owns = resolved.splitSpan.map { Array($0) } ?? [own]
        let riwayahPieces: [(own: Int, text: String)] = owns.compactMap { number in
            quranData.ayah(surah: surah, ayah: number).map { (number, $0.rawArabicText(surahId: surah, qiraahOverride: tag)) }
        }
        return analyze(hafsPieces: hafsPieces, riwayahPieces: riwayahPieces, tag: tag, surah: surah)
    }

    /// `hafsPieces` are the Hafs ayahs of the span in order; `riwayahPieces` the riwayah's own ayahs
    /// (one, or every piece a split divides the Hafs ayah into), in its own numbering, for the
    /// print's word flags. Not bound to the main actor: the tajweed store it reads is lock-guarded,
    /// and the explorer builds its places off the main thread.
    static func analyze(hafsPieces: [(ayah: Int, text: String)],
                        riwayahPieces: [(own: Int, text: String)],
                        tag: String, surah: Int) -> QiraatChange {
        let hafsText = hafsPieces.map(\.text).joined(separator: " ")
        let riwayahText = riwayahPieces.map(\.text).joined(separator: " ")
        let diff = QiraatWordDiff.compare(hafs: hafsText, riwayah: riwayahText)

        // The print's khilaf wash, word by word: the tajweed pack indexes words per own ayah, so a
        // piece's indices shift by the words of the pieces before it. Whole-word khilaf is a
        // word-level change; letter khilaf (dots, hamzah, a vowel) is the finer tier.
        var khilafWord = Set<Int>()
        var khilafLetter = Set<Int>()
        let store = QiraahTajweedStore.shared
        let legend = store.legend(for: tag)
        let wordLetters = Set(legend.filter { $0.key == "khilaf_word" }.map(\.letter))
        let harfLetters = Set(legend.filter { $0.key == "khilaf_harf" }.map(\.letter))
        var offset = 0
        for piece in riwayahPieces {
            let tokens = QiraatWordDiff.tokens(of: piece.text)
            if !wordLetters.isEmpty || !harfLetters.isEmpty,
               let rules = store.wordRules(tag: tag, surah: surah, ayah: piece.own) {
                // The pack counts words over UTF-16 spaces (`WordTokens`), where a lone stop sign between
                // two spaces is a word of its own; the diff's tokens are graphemes, where that sign rides
                // on the space before it. So each pack word is mapped to the diff token holding its first
                // character rather than trusting the two counts to agree (ad-Duri's and as-Susi's 4:44
                // differ by one after the sign, which put every later flag one word off).
                let packRanges = WordTokens.ranges(in: piece.text)
                func diffIndex(ofPackWord word: Int) -> Int? {
                    guard packRanges.indices.contains(word),
                          let start = Range(NSRange(location: packRanges[word].location, length: 0), in: piece.text)?.lowerBound
                    else { return nil }
                    return tokens.firstIndex { $0.range.contains(start) }
                }
                for (word, list) in rules {
                    guard let index = diffIndex(ofPackWord: word) else { continue }
                    if list.contains(where: { wordLetters.contains($0.letter) }) {
                        khilafWord.insert(offset + index)
                    } else if list.contains(where: { harfLetters.contains($0.letter) }) {
                        khilafLetter.insert(offset + index)
                    }
                }
            }
            offset += tokens.count
        }
        func isWord(_ index: Int) -> Bool {
            diff.riwayah.indices.contains(index) && !diff.riwayah[index].folded.isEmpty
        }

        // Silah written as a letter: the Makki and Madani prints spell the lengthened pronoun with a
        // full waw or ya (أَنفُسَهُمُو for Hafs's أَنفُسَهُمْ), so the folded diff sees another word where the
        // recitation differs only in the vowel's length. Pair those leftovers off as letter-level.
        var silahHafs = Set<Int>()
        var silahRiwayah = Set<Int>()
        var hafsLeft = diff.hafsOnly
        var riwayahLeft = diff.riwayahOnly
        var hi = 0
        var ri = 0
        while hi < hafsLeft.count, ri < riwayahLeft.count {
            let h = hafsLeft[hi], r = riwayahLeft[ri]
            let hf = diff.hafs[h].folded, rf = diff.riwayah[r].folded
            if Self.isSilahPair(hafs: hf, riwayah: rf) {
                silahHafs.insert(h); silahRiwayah.insert(r)
                hi += 1; ri += 1
            } else if h < r {
                hi += 1
            } else {
                ri += 1
            }
        }
        hafsLeft.removeAll { silahHafs.contains($0) }
        riwayahLeft.removeAll { silahRiwayah.contains($0) }

        var riwayahWordLevel = Set(riwayahLeft)
        for index in khilafWord where isWord(index) { riwayahWordLevel.insert(index) }
        var riwayahAll = riwayahWordLevel.union(silahRiwayah)
        for index in khilafLetter where isWord(index) { riwayahAll.insert(index) }

        var hafsWordLevel = Set(hafsLeft)
        var hafsAll = hafsWordLevel.union(silahHafs)
        for (h, r) in diff.pairs {
            if khilafWord.contains(r) { hafsWordLevel.insert(h); hafsAll.insert(h) }
            else if khilafLetter.contains(r) { hafsAll.insert(h) }
        }

        var byAyah: [Int: [Int]] = [:]
        var starts: [Int: Int] = [:]
        var start = 0
        for piece in hafsPieces {
            let count = QiraatWordDiff.tokens(of: piece.text).count
            let local = hafsAll.filter { $0 >= start && $0 < start + count }.sorted()
                .map { hafsWordLevel.contains($0) ? $0 - start : -($0 - start) - 1 }
            if !local.isEmpty { byAyah[piece.ayah] = local }
            starts[piece.ayah] = start
            start += count
        }
        return QiraatChange(hafsText: hafsText, riwayahText: riwayahText, diff: diff,
                            hafsWords: hafsAll.sorted(), riwayahWords: riwayahAll.sorted(),
                            hafsWordLevel: hafsWordLevel, riwayahWordLevel: riwayahWordLevel,
                            hafsWordsByAyah: byAyah, hafsStartByAyah: starts)
    }
}

/// Tints chosen words of an ayah text, leaving the waqf stop signs riding their last letters in the
/// base color (user rule: stop signs are never highlighted).
enum QiraatTint {
    static func attributed(_ text: String, tokens: [QiraatWordDiff.Token], words: Set<Int>,
                           base: Color, tint: Color) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.foregroundColor = base
        for index in words where tokens.indices.contains(index) {
            for run in stopSignFreeRuns(of: tokens[index].range, in: text) {
                if let lo = AttributedString.Index(run.lowerBound, within: attributed),
                   let hi = AttributedString.Index(run.upperBound, within: attributed), lo < hi {
                    attributed[lo..<hi].foregroundColor = tint
                }
            }
        }
        return attributed
    }

    static func withoutStopSigns(_ word: String) -> String {
        String(String.UnicodeScalarView(word.unicodeScalars.filter { !TajweedRules.stopSignScalars.contains($0.value) }))
    }

    private static func stopSignFreeRuns(of range: Range<String.Index>, in text: String) -> [Range<String.Index>] {
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

// MARK: - The place index

/// Where each riwayah differs from Hafs: per riwayah, per surah, the Hafs ayahs that differ and
/// the Hafs words involved (empty = the riwayah adds words, nothing of Hafs to point at). Read from
/// the bundled pack; computed per surah on demand when the pack is missing or lacks a riwayah.
@MainActor
final class QiraatPlacesStore {
    static let shared = QiraatPlacesStore()
    private init() {}

    nonisolated static let isBundled: Bool = ThemesPack.url("QiraatPlaces") != nil

    // The bundled index is parsed off the main actor (the explorer's task); these three are guarded
    // by `indexLock` rather than by the actor.
    nonisolated(unsafe) private var bundled: [String: [Int: [Int: [Int]]]]?
    nonisolated(unsafe) private var bundledLoaded = false
    nonisolated private let indexLock = NSLock()
    private var computed: [String: [Int: [Int: [Int]]]] = [:]
    /// `variantAyahs` per (surah, tags, tier): `step` walks up to 114 surahs and the explorer's bar
    /// asked three times per body; cleared when the beta gate changes the tag set.
    private var variantCache: [String: [Int]] = [:]

    /// Whether the bundled index is parsed (or found missing).
    nonisolated var isIndexLoaded: Bool {
        indexLock.lock(); defer { indexLock.unlock() }
        return bundledLoaded
    }

    /// Parses the bundled index off the calling thread (the explorer's task, detached), once.
    nonisolated func prewarmIndex() {
        _ = loadBundled()
    }

    func invalidateVariantCache() {
        variantCache.removeAll()
        QiraatDuelPlacesCache.shared.purge()
    }

    /// The per-surah tables computed for riwayat the pack lacks, and the counts cache: rebuilt on demand.
    func purgeComputed() {
        computed.removeAll()
        variantCache.removeAll()
        QiraatDuelPlacesCache.shared.purge()
    }

    /// The riwayat the explorer compares: every riwayah whose text may render (the beta gate),
    /// Hafs excluded since it is the reference.
    var enabledTags: [String] {
        Settings.Riwayah.textOptions.map(\.tag).filter { !$0.isEmpty }
    }

    /// Hafs ayah -> differing Hafs word indices, for one riwayah in one surah.
    func places(surah: Int, tag: String) -> [Int: [Int]] {
        let tag = Settings.Riwayah.canonicalTag(tag)
        if let table = loadBundled()?[tag] { return table[surah] ?? [:] }
        if let cached = computed[tag]?[surah] { return cached }
        let fresh = Self.compute(surah: surah, tag: tag, quranData: QuranData.shared)
        computed[tag, default: [:]][surah] = fresh
        return fresh
    }

    /// `places(surah:tag:)` for the explorer's build task, off the main thread: the bundled index, or
    /// for a riwayah the pack lacks the same computation uncached (the main actor owns that cache).
    nonisolated func placesOffMain(surah: Int, tag: String) -> [Int: [Int]] {
        let tag = Settings.Riwayah.canonicalTag(tag)
        if let table = loadBundled()?[tag] { return table[surah] ?? [:] }
        return Self.compute(surah: surah, tag: tag, quranData: QuranData.shared)
    }

    /// Whether a place's signed word list counts under the chosen tier: every place does when
    /// letter-level changes are in; otherwise it needs a word-level index (or none at all: added
    /// words).
    nonisolated static func counts(_ words: [Int], everyDifference: Bool) -> Bool {
        everyDifference || words.isEmpty || words.contains { $0 >= 0 }
    }

    /// The Hafs word indices a signed list names under the chosen tier.
    nonisolated static func wordIndices(_ words: [Int], everyDifference: Bool) -> [Int] {
        words.compactMap { $0 >= 0 ? $0 : (everyDifference ? -$0 - 1 : nil) }
    }

    /// Every riwayah in `tags` that differs at this Hafs ayah under the tier, in the order given.
    func differing(surah: Int, ayah: Int, tags: [String], everyDifference: Bool) -> [(tag: String, words: [Int])] {
        tags.compactMap { tag in
            guard let words = places(surah: surah, tag: tag)[ayah],
                  Self.counts(words, everyDifference: everyDifference) else { return nil }
            return (tag, Self.wordIndices(words, everyDifference: everyDifference))
        }
    }

    /// The Hafs ayahs of a surah where any riwayah in `tags` differs under the tier, ascending.
    func variantAyahs(surah: Int, tags: [String], everyDifference: Bool) -> [Int] {
        let key = "\(surah)|\(everyDifference ? 1 : 0)|\(tags.joined(separator: ","))"
        if let cached = variantCache[key] { return cached }
        var union = Set<Int>()
        for tag in tags {
            for (ayah, words) in places(surah: surah, tag: tag) where Self.counts(words, everyDifference: everyDifference) {
                union.insert(ayah)
            }
        }
        let sorted = union.sorted()
        variantCache[key] = sorted
        return sorted
    }

    func count(surah: Int, tags: [String], everyDifference: Bool) -> Int {
        variantAyahs(surah: surah, tags: tags, everyDifference: everyDifference).count
    }

    /// Counts across the Quran only come from the bundled pack: computing 114 surahs on demand
    /// would stall the screen.
    var hasWholeQuranCounts: Bool { loadBundled() != nil }

    /// The next (or previous) place from an ayah, across surah boundaries; nil at either end.
    func step(from surah: Int, ayah: Int, forward: Bool, tags: [String], everyDifference: Bool) -> (surah: Int, ayah: Int)? {
        var current = surah
        var floor = ayah
        while (1...114).contains(current) {
            let list = variantAyahs(surah: current, tags: tags, everyDifference: everyDifference)
            if forward, let next = list.first(where: { $0 > floor }) { return (current, next) }
            if !forward, let previous = list.last(where: { $0 < floor }) { return (current, previous) }
            current += forward ? 1 : -1
            floor = forward ? 0 : Int.max
        }
        return nil
    }

    func firstPlace(tags: [String], everyDifference: Bool) -> (surah: Int, ayah: Int)? {
        step(from: 1, ayah: 0, forward: true, tags: tags, everyDifference: everyDifference)
    }

    nonisolated private func loadBundled() -> [String: [Int: [Int: [Int]]]]? {
        indexLock.lock()
        if bundledLoaded { indexLock.unlock(); return bundled }
        indexLock.unlock()
        let table = PackTrace.measure("QiraatPlaces") { () -> (result: [String: [Int: [Int: [Int]]]]?, bytes: Int) in
            guard Self.isBundled, let json = ThemesPack.data("QiraatPlaces"),
                  let root = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any],
                  let riwayat = root["riwayat"] as? [String: [String: [[Int]]]] else { return (nil, 0) }
            var table: [String: [Int: [Int: [Int]]]] = [:]
            for (tag, surahs) in riwayat {
                var perSurah: [Int: [Int: [Int]]] = [:]
                for (key, rows) in surahs {
                    guard let surah = Int(key) else { continue }
                    var byAyah: [Int: [Int]] = [:]
                    for row in rows where !row.isEmpty { byAyah[row[0]] = Array(row.dropFirst()) }
                    perSurah[surah] = byAyah
                }
                table[Settings.Riwayah.canonicalTag(tag)] = perSurah
            }
            return (table, json.count)
        }
        indexLock.lock(); defer { indexLock.unlock() }
        if bundledLoaded { return bundled }
        bundled = table
        bundledLoaded = true
        return table
    }

    /// One riwayah through one surah: every Hafs span the riwayah's own ayahs map to, diffed as a
    /// unit (a merged ayah against the Hafs ayahs it joins, a split ayah's pieces against the one
    /// Hafs ayah), the differing Hafs words handed back to the ayahs they belong to.
    nonisolated static func compute(surah: Int, tag: String, quranData: QuranData) -> [Int: [Int]] {
        guard let alignment = QiraahComparison.alignment(surahID: surah, tag: tag, quranData: quranData) else { return [:] }
        var spans: [ClosedRange<Int>: [Int]] = [:]
        for (own, span) in alignment.hafsRangeForRiwayah { spans[span, default: []].append(own) }

        var out: [Int: [Int]] = [:]
        for (span, ownsUnsorted) in spans {
            var riwayahPieces: [(own: Int, text: String)] = []
            for own in ownsUnsorted.sorted() {
                guard let ayah = quranData.ayah(surah: surah, ayah: own),
                      ayah.existsInQiraah(tag, surahID: surah) else { continue }
                riwayahPieces.append((own, ayah.rawArabicText(surahId: surah, qiraahOverride: tag)))
            }
            guard !riwayahPieces.isEmpty else { continue }
            var hafsPieces: [(ayah: Int, text: String)] = []
            for number in span {
                guard let ayah = quranData.ayah(surah: surah, ayah: number) else { continue }
                hafsPieces.append((number, ayah.rawArabicText(surahId: surah, qiraahOverride: "")))
            }
            guard !hafsPieces.isEmpty else { continue }
            let change = QiraatChange.analyze(hafsPieces: hafsPieces, riwayahPieces: riwayahPieces, tag: tag, surah: surah)
            for (ayah, words) in change.hafsWordsByAyah { out[ayah] = words }
            // Words the riwayah adds leave nothing of Hafs to point at: the span's first ayah is
            // the place, word-level (an empty list reads as such throughout).
            if change.differsAtWordLevel, change.hafsWordsByAyah.isEmpty { out[span.lowerBound] = [] }
        }
        return out
    }
}

#if DEBUG
/// "-exportQiraatPlaces": the place index comes out of the app itself, so the alignment, the texts
/// and the print flags are exactly the runtime's. Run it in the simulator with beta text on
/// (`-seedBool betaQiraatEnabled=1`), wait for "QIRAAT PLACES EXPORT done" in the log, then xz the
/// container's Documents/qiraat-places.json to Resources/Data/Quran/QiraatPlaces.json.xz. Re-run
/// after any riwayah text or tajweed pack change.
enum QiraatPlacesExport {
    @MainActor
    static func run() async {
        let quranData = QuranData.shared
        var riwayat: [String: [String: [[Int]]]] = [:]
        var total = 0
        for option in Settings.Riwayah.options where !option.tag.isEmpty {
            var perSurah: [String: [[Int]]] = [:]
            var count = 0
            for surah in 1...114 {
                let places = QiraatPlacesStore.compute(surah: surah, tag: option.tag, quranData: quranData)
                if !places.isEmpty {
                    perSurah[String(surah)] = places.keys.sorted().map { [$0] + (places[$0] ?? []) }
                    count += places.count
                }
                await Task.yield()
            }
            riwayat[option.tag] = perSurah
            total += count
            NSLog("QIRAAT PLACES %@: %d ayahs", option.tag, count)
        }
        let root: [String: Any] = ["version": 1, "riwayat": riwayat]
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.sortedKeys]),
              let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            NSLog("QIRAAT PLACES EXPORT FAILED to encode")
            return
        }
        let url = documents.appendingPathComponent("qiraat-places.json")
        do {
            try data.write(to: url)
            NSLog("QIRAAT PLACES EXPORT done: %d ayah places, %@", total, url.path)
        } catch {
            NSLog("QIRAAT PLACES EXPORT FAILED: %@", "\(error)")
        }
    }
}

/// "-qiraatBench [places]": what a Next tap in the explorer actually costs, split into the two
/// halves Phase 6 step 2 asks about: the per-surah alignment every resolve needs (cached for the
/// app's life) and the place build (every riwayah resolved and diffed, in parallel since the
/// 2026-10-09 redesign, then cut into sites). Walks the real place list with the real enabled
/// riwayat, so the numbers are the ones a user feels. Run it on an optimized build
/// (`SWIFT_OPTIMIZATION_LEVEL=-O`) before drawing any conclusion: the diff is 30x slower at -Onone.
enum QiraatExplorerBench {
    @MainActor
    static func run(places wanted: Int) async {
        let quranData = QuranData.shared
        let store = QiraatPlacesStore.shared
        let tags = store.enabledTags
        let everyDifference = UserDefaults.standard.bool(forKey: "qiraatExplorerEveryDifference")
        guard !tags.isEmpty, var place = store.firstPlace(tags: tags, everyDifference: everyDifference) else {
            NSLog("QIRAAT BENCH: no places for %d tags", tags.count)
            return
        }

        var alignedSurahs = Set<Int>()
        var newSurahMillis: [Double] = []
        var sameSurahMillis: [Double] = []
        var alignmentMillis = 0.0
        var rowsMillis = 0.0
        var stepMillis = 0.0
        var firstLine = ""

        for index in 0..<max(1, wanted) {
            let started = DispatchTime.now().uptimeNanoseconds
            // The cold half: the alignment of this surah for each riwayah, which the resolve below
            // would otherwise pull in unmeasured.
            let alignStarted = DispatchTime.now().uptimeNanoseconds
            let coldSurah = !alignedSurahs.contains(place.surah)
            if coldSurah {
                alignedSurahs.insert(place.surah)
                for tag in tags { _ = QiraahComparison.alignment(surahID: place.surah, tag: tag, quranData: quranData) }
            }
            let align = Self.millis(since: alignStarted)
            alignmentMillis += align

            // The warm half: exactly what the explorer's build task makes per place.
            let rowsStarted = DispatchTime.now().uptimeNanoseconds
            _ = await QiraatPlaceBuilder.build(surah: place.surah, hafsAyah: place.ayah, tags: tags,
                                               everyDifference: everyDifference, quranData: quranData)
            let rows = Self.millis(since: rowsStarted)
            rowsMillis += rows

            // The bar: both step lookups and the caption's count, per place.
            let stepStarted = DispatchTime.now().uptimeNanoseconds
            _ = store.step(from: place.surah, ayah: place.ayah, forward: false, tags: tags, everyDifference: everyDifference)
            let next = store.step(from: place.surah, ayah: place.ayah, forward: true, tags: tags, everyDifference: everyDifference)
            _ = store.variantAyahs(surah: place.surah, tags: tags, everyDifference: everyDifference)
            stepMillis += Self.millis(since: stepStarted)

            let total = Self.millis(since: started)
            if index == 0 {
                firstLine = String(format: "QIRAAT BENCH first place %d:%d %.1f ms (alignment %.1f, rows %.1f)",
                                   place.surah, place.ayah, total, align, rows)
            } else if coldSurah {
                newSurahMillis.append(total)
            } else {
                sameSurahMillis.append(total)
            }

            guard let onward = next else { break }
            place = onward
        }

        func report(_ label: String, _ samples: [Double]) {
            guard !samples.isEmpty else { return }
            let sorted = samples.sorted()
            NSLog("QIRAAT BENCH %@: %d places, mean %.1f ms, median %.1f ms, worst %.1f ms",
                  label, sorted.count, sorted.reduce(0, +) / Double(sorted.count),
                  sorted[sorted.count / 2], sorted[sorted.count - 1])
        }

        NSLog("QIRAAT BENCH tags %d, everyDifference %@, %d surahs touched",
              tags.count, everyDifference ? "on" : "off", alignedSurahs.count)
        NSLog("%@", firstLine)
        report("new surah", newSurahMillis)
        report("same surah", sameSurahMillis)
        NSLog("QIRAAT BENCH totals: alignment %.0f ms, rows %.0f ms, bar %.0f ms",
              alignmentMillis, rowsMillis, stepMillis)
        NSLog("QIRAAT BENCH done")
    }

    private static func millis(since start: UInt64) -> Double {
        Double(DispatchTime.now().uptimeNanoseconds - start) / 1_000_000
    }
}

#endif

// MARK: - Compare all twenty

/// The way from eight riwayat to all twenty: the twelve riwayat the King Fahd Complex has not
/// published as text ship as printed mushafs, and their selectable text is a beta transcription
/// that the reader turns on knowingly (the same consent the reader's Page Text menu asks for).
struct QiraatExplorerUnlockSheet: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        SheetNavigationContainer {
            List {
                Group {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Eight riwayat now, twenty with beta text", systemImage: "arrow.left.and.right.text.vertical")
                                .font(.subheadline.weight(.semibold))
                            Text("The explorer compares the eight riwayat whose text the King Fahd Complex has published. The other twelve ship as their printed mushafs; their selectable text is a beta transcription of those prints. Turn it on to compare all twenty riwayat at once, here and in the reader's comparison sheet.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }

                    Section {
                        Text(Settings.betaQiraatNotice)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } header: {
                        Text("ABOUT THE BETA TEXT")
                    }

                    Section {
                        Button {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) {
                                settings.betaQiraatEnabled = true
                                settings.acceptedBetaQiraatNotice = true
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Compare All 20 Riwayat", systemImage: "flask")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                            }
                        }
                        .foregroundColor(settings.accentColor.color)
                    } footer: {
                        Text("Change anytime: Quran Settings → Beta Text.")
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .navigationTitle("All 20 Riwayat")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .smallMediumSheetPresentation()
    }
}

// MARK: - The place picker

/// Where to go next: the places of this surah (each with the Hafs words that change), or any surah
/// with its count of places. The explorer hands over the lists, since All Riwayat and Compare Two
/// find their places differently.
struct QiraatPlacePickerSheet: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.dismiss) private var dismiss

    let surahID: Int
    let hafsAyah: Int
    /// This surah's places, in order.
    let places: [Int]
    /// The riwayat whose changed words name each place.
    let tags: [String]
    let everyDifference: Bool
    /// A surah's number of places, or nil where none is known up front (two riwayat against each
    /// other are only counted once their texts are compared).
    let count: ((Int) -> Int)?
    /// `ayah` nil = a surah was picked, else the place.
    let onPick: (_ surah: Int, _ ayah: Int?) -> Void

    @State private var tab = 0
    @State private var searchText = ""

    private var quranData: QuranData { QuranData.shared }

    private var store: QiraatPlacesStore { QiraatPlacesStore.shared }
    private var accent: Color { appearance.accent }

    var body: some View {
        let _ = RenderCounter.hit("QiraatPlacePickerSheet")
        NavigationView {
            List {
                Group {
                    if tab == 0 {
                        thisSurahSection
                    } else {
                        surahsSection
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle(disableNowPlayingInset: true)
            .compactListSectionSpacing()
            .safeAreaInset(edge: .top, spacing: 0) {
                Picker("Scope", selection: $tab) {
                    Text("This Surah").tag(0)
                    Text("All Surahs").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .overlay(Divider(), alignment: .bottom)
            }
            .adaptiveSafeArea(edge: .bottom) {
                if tab == 1 {
                    SearchBar(text: $searchText, placeholder: "Search surahs")
                        .padding(.horizontal, 24)
                        .padding(.bottom, BottomBarCushion.standard)
                        .background(Color.white.opacity(0.00001))
                }
            }
            .navigationTitle("Go to a Place")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            .accentWashedBackground()
        }
        .navigationViewStyle(.stack)
        .smallMediumSheetPresentation()
    }

    private var thisSurahSection: some View {
        let name = quranData.surah(surahID)?.nameTransliteration ?? "Surah \(surahID)"
        return Section(header: HStack {
            Text(name.uppercased())
            Spacer()
            Text(places.count == 1 ? "1 place" : "\(places.count) places")
        }) {
            if places.isEmpty {
                Text("No place in this surah, or the places are still being found. Pick another surah under All Surahs.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(places, id: \.self) { ayah in
                Button {
                    Settings.shared.hapticFeedback()
                    onPick(surahID, ayah)
                    dismiss()
                } label: {
                    placeRow(ayah)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func placeRow(_ ayah: Int) -> some View {
        let text = quranData.ayah(surah: surahID, ayah: ayah)?.rawArabicText(surahId: surahID, qiraahOverride: "") ?? ""
        let tokens = QiraatWordDiff.tokens(of: text)
        let differing = store.differing(surah: surahID, ayah: ayah, tags: tags, everyDifference: everyDifference)
        var words = Set<Int>()
        for entry in differing { words.formUnion(entry.words) }
        let phrase = words.sorted().compactMap { tokens.indices.contains($0) ? QiraatTint.withoutStopSigns(tokens[$0].text) : nil }
            .joined(separator: " · ")
        let isCurrent = ayah == hafsAyah

        return HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Ayah \(ayah)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isCurrent ? accent : .primary)
                    if isCurrent {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(accent)
                    }
                }
                Text(differing.count == 1 ? "1 riwayah" : "\(differing.count) riwayat")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(phrase.isEmpty ? "added words" : phrase)
                .font(phrase.isEmpty ? .caption : .custom(appearance.quranDisplayFace, size: 20))
                .arabicFontDesign(custom: !phrase.isEmpty)
                .foregroundColor(phrase.isEmpty ? .secondary : accent)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private var filteredSurahs: [Surah] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return quranData.quran }
        return quranData.surahListResults(for: query).sorted { $0.id < $1.id }
    }

    private var surahsSection: some View {
        Section(header: Text("SURAHS")) {
            ForEach(filteredSurahs) { surah in
                Button {
                    Settings.shared.hapticFeedback()
                    onPick(surah.id, nil)
                    dismiss()
                } label: {
                    HStack(spacing: 10) {
                        Text("\(surah.id)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(surah.nameTransliteration)
                                .font(.subheadline.weight(surah.id == surahID ? .semibold : .regular))
                                .foregroundColor(surah.id == surahID ? accent : .primary)
                            Text(surah.nameEnglish)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let countOf = self.count {
                            let count = countOf(surah.id)
                            Text(count == 0 ? "alike" : (count == 1 ? "1 place" : "\(count) places"))
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(count == 0 ? .secondary : accent)
                        }
                        Text(surah.nameArabic)
                            .font(.custom(appearance.quranDisplayFace, size: 18))
                            .arabicFontDesign(custom: true)
                            .foregroundColor(.primary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
#endif
