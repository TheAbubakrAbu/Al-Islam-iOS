#if os(iOS)
import SwiftUI

// The Qiraat Explorer: where the riwayat differ from Hafs, found rather than hunted for.
//
// The comparison sheet answers "how do the riwayat read THIS ayah". This screen answers the question
// before it: WHERE do they differ at all. Only a fraction of the Quran's ayahs are read differently
// by any riwayah, so the explorer steps from one such place to the next (across surahs), says what
// changes at each in Hafs-reads / they-read pairs, adds the meaning of the readings where the
// Quran.com qiraat reference has one, and lays out every riwayah's text with its changed words
// tinted. A second mode walks one riwayah through a whole surah against Hafs, differing ayahs only.
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

    /// `hafsPieces` are the Hafs ayahs of the span in order; `riwayahPieces` the riwayah's own ayahs
    /// (one, or every piece a split divides the Hafs ayah into), in its own numbering, for the
    /// print's word flags.
    @MainActor
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
            let count = QiraatWordDiff.tokens(of: piece.text).count
            if !wordLetters.isEmpty || !harfLetters.isEmpty,
               let rules = store.wordRules(tag: tag, surah: surah, ayah: piece.own) {
                for (word, list) in rules {
                    if list.contains(where: { wordLetters.contains($0.letter) }) {
                        khilafWord.insert(offset + word)
                    } else if list.contains(where: { harfLetters.contains($0.letter) }) {
                        khilafLetter.insert(offset + word)
                    }
                }
            }
            offset += count
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
        var start = 0
        for piece in hafsPieces {
            let count = QiraatWordDiff.tokens(of: piece.text).count
            let local = hafsAll.filter { $0 >= start && $0 < start + count }.sorted()
                .map { hafsWordLevel.contains($0) ? $0 - start : -($0 - start) - 1 }
            if !local.isEmpty { byAyah[piece.ayah] = local }
            start += count
        }
        return QiraatChange(hafsText: hafsText, riwayahText: riwayahText, diff: diff,
                            hafsWords: hafsAll.sorted(), riwayahWords: riwayahAll.sorted(),
                            hafsWordLevel: hafsWordLevel, riwayahWordLevel: riwayahWordLevel,
                            hafsWordsByAyah: byAyah)
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
    }

    /// The per-surah tables computed for riwayat the pack lacks, and the counts cache: rebuilt on demand.
    func purgeComputed() {
        computed.removeAll()
        variantCache.removeAll()
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

    /// Whether a place's signed word list counts under the chosen tier: every place does when
    /// letter-level changes are in; otherwise it needs a word-level index (or none at all: added
    /// words).
    static func counts(_ words: [Int], everyDifference: Bool) -> Bool {
        everyDifference || words.isEmpty || words.contains { $0 >= 0 }
    }

    /// The Hafs word indices a signed list names under the chosen tier.
    static func wordIndices(_ words: [Int], everyDifference: Bool) -> [Int] {
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
    static func compute(surah: Int, tag: String, quranData: QuranData) -> [Int: [Int]] {
        guard let alignment = QiraahComparison.alignment(surahID: surah, tag: tag, quranData: quranData) else { return [:] }
        var spans: [ClosedRange<Int>: [Int]] = [:]
        for (own, span) in alignment.hafsRangeForRiwayah { spans[span, default: []].append(own) }

        var out: [Int: [Int]] = [:]
        for (span, ownsUnsorted) in spans {
            var riwayahPieces: [(own: Int, text: String)] = []
            for own in ownsUnsorted.sorted() {
                guard let ayah = quranData.ayah(surah: surah, ayah: own),
                      ayah.existsInQiraah(tag, surahID: surah) else { continue }
                riwayahPieces.append((own, ayah.displayArabicText(surahId: surah, clean: false, qiraahOverride: tag)))
            }
            guard !riwayahPieces.isEmpty else { continue }
            var hafsPieces: [(ayah: Int, text: String)] = []
            for number in span {
                guard let ayah = quranData.ayah(surah: surah, ayah: number) else { continue }
                hafsPieces.append((number, ayah.displayArabicText(surahId: surah, clean: false, qiraahOverride: "")))
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
/// halves Phase 6 step 2 asks about - the per-surah alignment every resolve needs (cached for the
/// app's life) and the per-place resolve and word diff. Walks the real place list with the real
/// enabled riwayat, so the numbers are the ones a user feels. Run it on an optimized build
/// (`SWIFT_OPTIMIZATION_LEVEL=-O`) before drawing any conclusion: the diff is 30x slower at -Onone.
enum QiraatExplorerBench {
    @MainActor
    static func run(places wanted: Int) {
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

            // The warm half: exactly what `refreshRows` rebuilds per place.
            let rowsStarted = DispatchTime.now().uptimeNanoseconds
            for tag in tags {
                guard let resolved = QiraahAyahResolver.resolve(surahNumber: place.surah, ayahNumber: place.ayah,
                                                                anchorHafsAyah: place.ayah, optionTag: tag, clean: false) else { continue }
                _ = QiraatExplorerView.change(for: tag, surah: place.surah, hafsAyah: place.ayah,
                                              resolved: resolved, quranData: quranData)
            }
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

// MARK: - Rows

/// One riwayah at the explorer's ayah: its aligned text and what it changes.
struct QiraatRiwayahRow: Identifiable {
    let option: Settings.Riwayah.Option
    let resolved: ResolvedQiraahText?
    let change: QiraatChange?

    var id: String { option.id }
    var differs: Bool { change?.differs ?? false }
}

/// Riwayat that make the same change, together: one Hafs-reads / they-read pair with their names.
struct QiraatReadingGroup: Identifiable {
    let id: String
    var tags: [String]
    let hafsWords: String
    let riwayahWords: String
}

// MARK: - The explorer

struct QiraatExplorerView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    enum Mode: String {
        /// Every riwayah at one place, against Hafs.
        case ayah
        /// Two chosen riwayat against each other, stepping through the places where THEY differ.
        case duel
        /// One riwayah through a whole surah against Hafs.
        case surah
    }

    /// Rows per page of the surah walk: ten on the reduced tier (each row is a resolve and a diff).
    private static var surahPage: Int { AppPerformance.shouldAvoidBroadPrewarm ? 10 : 20 }

    @State private var mode: Mode = .ayah
    @State private var surahID: Int
    @State private var hafsAyah: Int
    @AppStorage("qiraatExplorerRiwayah") private var compareTagRaw: String = Settings.Riwayah.warsh
    @AppStorage("qiraatExplorerOnlyDifferences") private var onlyDifferences = true
    @AppStorage("qiraatExplorerFontSize") private var fontSize: Double = 24
    /// Off: step by word-level changes (another word form, added or dropped letters, other vowels).
    /// On: every change, down to one letter's dots, hamzah or vowel.
    @AppStorage("qiraatExplorerEveryDifference") private var everyDifference = false
    @State private var showIdentical = false
    @State private var visibleRows = QiraatExplorerView.surahPage
    @State private var showPicker = false
    @State private var rows: [QiraatRiwayahRow] = []
    @State private var rowsKey = ""
    @State private var surahRows: [Int: QiraatSurahRowModel] = [:]
    @State private var surahRowsKey = ""
    /// Head-to-Head: the two sides, remembered across places and openings (Hafs against Warsh
    /// until the reader picks). Either may be Hafs (the empty tag).
    @AppStorage("qiraatExplorerDuelA") private var duelARaw: String = Settings.Riwayah.hafsTag
    @AppStorage("qiraatExplorerDuelB") private var duelBRaw: String = Settings.Riwayah.warsh
    @State private var duel = DuelDerived()
    /// The places where the two sides read differently, per surah and pair (see `duelPlaces`).
    @State private var duelPlacesCache: [String: [Int]] = [:]
    /// The "compare all 20" sheet: unlocks the beta text of the twelve unpublished riwayat.
    @State private var showUnlock = false

    /// `ayah` in the reader's riwayah numbering (`originTag`); the explorer thinks in Hafs numbers.
    init(surah: Int, ayah: Int, originTag: String? = nil) {
        let anchor = QiraahComparison.hafsAnchor(surahID: surah, ayahNumber: ayah, tag: originTag, quranData: QuranData.shared)
        _surahID = State(initialValue: surah)
        _hafsAyah = State(initialValue: anchor)
    }

    /// Opens on the first place in the Quran where a riwayah differs: al-Fatiha's مالك / ملك (1:4),
    /// which is the first place in every riwayah set, so it is a constant here and the index (a
    /// 56 KB pack, parsed on the main thread in this init before) loads off-main in the task below,
    /// which corrects the place in the rare case the index says otherwise.
    init() {
        _surahID = State(initialValue: 1)
        _hafsAyah = State(initialValue: 4)
        _openedAtDefault = State(initialValue: true)
    }

    /// Opens the surah walk on one riwayah (from a narrator's page in the Qiraat guide): al-Fatiha
    /// from its first ayah, the riwayah remembered as the walk's own exactly as if picked there.
    init(surahWalk tag: String) {
        UserDefaults.standard.set(tag, forKey: "qiraatExplorerRiwayah")
        _mode = State(initialValue: .surah)
        _surahID = State(initialValue: 1)
        _hafsAyah = State(initialValue: 1)
    }

    /// Opens straight into a mode (the guide's Head-to-Head door), at the first place.
    init(mode: Mode) {
        _mode = State(initialValue: mode)
        _surahID = State(initialValue: 1)
        _hafsAyah = State(initialValue: mode == .surah ? 1 : 4)
        _openedAtDefault = State(initialValue: mode == .ayah)
    }

    /// True when the explorer opened at the constant first place and the index has not confirmed it yet.
    @State private var openedAtDefault = false
    /// Everything the ayah mode derives from the rows, the tags and the tier: computed in `refreshRows`,
    /// never per body (the previous/next place each walked up to 114 surahs per evaluation).
    private struct AyahDerived {
        var previous: (surah: Int, ayah: Int)?
        var next: (surah: Int, ayah: Int)?
        var caption = ""
        var reference = AttributedString()
        var groups: [QiraatReadingGroup] = []
        var junctures: [QiraatVariantsStore.Juncture] = []
    }
    @State private var derived = AyahDerived()
    /// Everything the head-to-head derives from the two sides at the current place.
    private struct DuelDerived {
        var previous: (surah: Int, ayah: Int)?
        var next: (surah: Int, ayah: Int)?
        var caption = ""
        var aResolved: ResolvedQiraahText?
        var bResolved: ResolvedQiraahText?
        var aStyled = AttributedString()
        var bStyled = AttributedString()
        var aWords = ""
        var bWords = ""
        var differs = false
        var wordCount = 0
        var junctures: [QiraatVariantsStore.Juncture] = []
    }
    /// The rolling warm of the next surah's alignments (see `warmNextSurah`).
    @State private var warmTask: Task<Void, Never>?

    private var store: QiraatPlacesStore { QiraatPlacesStore.shared }
    private var enabledTags: [String] { store.enabledTags }
    private var accent: Color { settings.accentColor.color }
    private var surahObject: Surah? { quranData.surah(surahID) }
    private var ayahObject: Ayah? { surahObject?.ayahs.first { $0.id == hafsAyah } }
    private var surahName: String { surahObject?.nameTransliteration ?? "Surah \(surahID)" }
    private var compareTag: String {
        let tag = Settings.Riwayah.canonicalTag(compareTagRaw)
        // The stored riwayah may be beta text that is no longer unlocked: fall back to Warsh.
        return enabledTags.contains(tag) ? tag : (enabledTags.first ?? Settings.Riwayah.warsh)
    }
    private var compareOption: Settings.Riwayah.Option { Settings.Riwayah.option(for: compareTag) }

    /// Side A of the head-to-head: the stored riwayah while its text may render, else Hafs.
    private var duelA: String {
        let tag = Settings.Riwayah.canonicalTag(duelARaw)
        return tag.isEmpty || enabledTags.contains(tag) ? tag : Settings.Riwayah.hafsTag
    }

    /// Side B: the stored riwayah while it may render and is not side A, else the first other one.
    private var duelB: String {
        let tag = Settings.Riwayah.canonicalTag(duelBRaw)
        if (tag.isEmpty || enabledTags.contains(tag)) && tag != duelA { return tag }
        return enabledTags.first { $0 != duelA } ?? Settings.Riwayah.hafsTag
    }

    private var duelShortA: String { QiraatProfiles.shortName(of: duelA) }
    private var duelShortB: String { QiraatProfiles.shortName(of: duelB) }

    var body: some View {
        let _ = RenderCounter.hit("QiraatExplorerView")
        List {
            Group {
                switch mode {
                case .ayah: ayahSections
                case .duel: duelSections
                case .surah: surahSections
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .compactListSectionSpacing()
        .safeAreaInset(edge: .top, spacing: 0) { header }
        .navigationTitle("Qiraat Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) { sizeMenu }
        }
        .sheet(isPresented: $showPicker) {
            QiraatPlacePickerSheet(surahID: surahID, hafsAyah: hafsAyah,
                                   tags: mode == .duel ? [duelA, duelB].filter { !$0.isEmpty } : enabledTags,
                                   everyDifference: everyDifference, startOnSurahs: mode == .surah) { surah, ayah in
                withAnimation(.easeInOut) {
                    surahID = surah
                    if let ayah {
                        hafsAyah = ayah
                        if mode == .surah { mode = .ayah }
                    } else {
                        hafsAyah = 1
                    }
                }
            }
        }
        .sheet(isPresented: $showUnlock) {
            QiraatExplorerUnlockSheet()
        }
        .task {
            // The place index (56 KB xz) parses off the main thread here, never in the push; the
            // constant first place is corrected once the index is in, and the counts cache follows.
            let store = QiraatPlacesStore.shared
            if !store.isIndexLoaded {
                await Task.detached(priority: .userInitiated) { store.prewarmIndex() }.value
            }
            // The riwayat's tajweed packs (one raw-deflate JSON each) carry the print's khilaf
            // wash, which `QiraatChange.analyze` reads for every row. The first place used to
            // inflate all of them on the main thread: 103 ms for the seven default riwayat, 224 ms
            // for all nineteen (`-qiraatBench` on an optimized build). The store is lock-guarded
            // and Sendable, so they inflate here, before the first row build asks for one.
            // The juncture table (949 KB) and the clip index (32 KB) went the same way: both are
            // read from the row build and both parsed on the main thread there.
            let tags = enabledTags
            await Task.detached(priority: .userInitiated) {
                for tag in tags { _ = QiraahTajweedStore.shared.pack(for: tag) }
                QiraatVariantsStore.shared.prewarm()
                QiraatVariantAudioStore.shared.prewarm()
            }.value
            if openedAtDefault {
                openedAtDefault = false
                if let first = store.firstPlace(tags: enabledTags, everyDifference: everyDifference),
                   first.surah != surahID || first.ayah != hafsAyah {
                    surahID = first.surah
                    hafsAyah = first.ayah
                }
            }
            refresh()
        }
        .onDisappear { warmTask?.cancel() }
        .onChange(of: hafsAyah) { _ in refresh() }
        .onChange(of: surahID) { _ in
            visibleRows = Self.surahPage
            refresh()
        }
        .onChange(of: mode) { _ in refresh() }
        .onChange(of: compareTagRaw) { _ in
            visibleRows = Self.surahPage
            refresh()
        }
        .onChange(of: onlyDifferences) { _ in
            visibleRows = Self.surahPage
            refresh()
        }
        .onChange(of: visibleRows) { _ in refresh() }
        .onChange(of: everyDifference) { _ in
            visibleRows = Self.surahPage
            duelPlacesCache.removeAll()
            refresh()
        }
        .onChange(of: duelARaw) { _ in refresh() }
        .onChange(of: duelBRaw) { _ in refresh() }
        .onChange(of: settings.betaQiraatEnabled) { _ in
            QiraatPlacesStore.shared.invalidateVariantCache()
            duelPlacesCache.removeAll()
            refresh()
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 10) {
            Picker("Mode", selection: $mode) {
                Text("All Riwayat").tag(Mode.ayah)
                Text("Head-to-Head").tag(Mode.duel)
                Text("By Surah").tag(Mode.surah)
            }
            .pickerStyle(.segmented)

            switch mode {
            case .ayah:
                placeBar(previous: previousPlace, next: nextPlace, caption: placeCaption)
                coverageStrip
            case .duel:
                placeBar(previous: duel.previous, next: duel.next, caption: duel.caption)
                coverageStrip
            case .surah:
                surahBar
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .overlay(Divider(), alignment: .bottom)
    }

    /// How many of the twenty riwayat the explorer can compare right now, and the way to all of
    /// them: the twelve unpublished riwayat compare only once their beta text is unlocked.
    @ViewBuilder
    private var coverageStrip: some View {
        let total = Settings.Riwayah.allOptions.count
        let enabled = enabledTags.count + 1
        if enabled < total {
            Button {
                settings.hapticFeedback()
                showUnlock = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "lock.open")
                        .font(.caption2.weight(.semibold))
                    Text("Comparing \(enabled) of \(total) riwayat · Compare all \(total)")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundColor(accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(accent.opacity(0.12)))
            }
            .buttonStyle(.plain)
        } else {
            Text("All \(total) riwayat compared")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var previousPlace: (surah: Int, ayah: Int)? { derived.previous }
    private var nextPlace: (surah: Int, ayah: Int)? { derived.next }
    private var placeCaption: String { derived.caption }

    private func computePlaceCaption() -> String {
        let places = store.variantAyahs(surah: surahID, tags: enabledTags, everyDifference: everyDifference)
        if let index = places.firstIndex(of: hafsAyah) {
            return "Place \(index + 1) of \(places.count) in this surah"
        }
        switch places.count {
        case 0: return "No riwayah differs anywhere in this surah"
        case 1: return "Read alike here · 1 place differs in this surah"
        default: return "Read alike here · \(places.count) places differ in this surah"
        }
    }

    private func placeBar(previous: (surah: Int, ayah: Int)?, next: (surah: Int, ayah: Int)?, caption: String) -> some View {
        HStack(spacing: 10) {
            stepButton("chevron.left", label: "Previous place", enabled: previous != nil) { jump(to: previous) }

            Button {
                settings.hapticFeedback()
                showPicker = true
            } label: {
                VStack(spacing: 2) {
                    Text(ayahSheetTitle(surahNumber: surahID, ayahNumber: hafsAyah))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            stepButton("chevron.right", label: "Next place", enabled: next != nil) { jump(to: next) }
        }
    }

    private var surahBar: some View {
        let count = store.count(surah: surahID, tags: [compareTag], everyDifference: everyDifference)
        let ayahCount = surahObject?.numberOfAyahs ?? 0
        return HStack(spacing: 10) {
            stepButton("chevron.left", label: "Previous surah", enabled: surahID > 1) {
                withAnimation(.easeInOut) { surahID -= 1 }
            }

            Button {
                settings.hapticFeedback()
                showPicker = true
            } label: {
                VStack(spacing: 2) {
                    Text("\(surahID). \(surahName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(count == 0
                         ? "\(QiraatProfiles.shortName(of: compareTag)) reads every ayah as Hafs"
                         : "\(count) of \(ayahCount) ayahs differ in \(QiraatProfiles.shortName(of: compareTag))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            stepButton("chevron.right", label: "Next surah", enabled: surahID < 114) {
                withAnimation(.easeInOut) { surahID += 1 }
            }
        }
    }

    private func stepButton(_ systemName: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .foregroundColor(enabled ? accent : .secondary)
                .frame(width: 40, height: 40)
                .conditionalGlassEffect(circle: true, flat: true)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func jump(to place: (surah: Int, ayah: Int)?) {
        guard let place else { return }
        withAnimation(.easeInOut) {
            surahID = place.surah
            hafsAyah = place.ayah
        }
    }

    private var sizeMenu: some View {
        Menu {
            Picker("Text Size", selection: $fontSize) {
                Text("Small").tag(20.0)
                Text("Medium").tag(24.0)
                Text("Large").tag(28.0)
                Text("Extra Large").tag(34.0)
            }
            Divider()
            // `.automatic`, not the app's padded switch: inside a menu that style draws double-height
            // rows with stray checkmarks (see the memory note on menu toggles).
            Toggle(isOn: $everyDifference) {
                Label("Every Difference", systemImage: "textformat.abc.dottedunderline")
            }
            .toggleStyle(.automatic)
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .fixedMenuOrder()
        .tint(accent)
        .accessibilityLabel("Explorer options")
    }

    // MARK: Fonts

    private func quranFont(tag: String) -> Font {
        .custom(settings.quranArabicFontName(for: tag), size: CGFloat(fontSize))
    }

    private func arabicBlock(_ attributed: AttributedString, tag: String) -> some View {
        Text(attributed)
            .font(quranFont(tag: tag))
            .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
            .multilineTextAlignment(.trailing)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .textSelection(.enabled)
    }

    // MARK: Ayah mode

    private var differingRows: [QiraatRiwayahRow] { rows.filter(\.differs) }
    private var identicalRows: [QiraatRiwayahRow] { rows.filter { !$0.differs } }

    private var hafsText: String {
        ayahObject?.displayArabicText(surahId: surahID, clean: false, qiraahOverride: "") ?? ""
    }

    /// The Hafs text with every word any riwayah changes tinted (set in `refreshRows`).
    private var referenceAttributed: AttributedString { derived.reference }

    private func computeReferenceAttributed() -> AttributedString {
        let text = hafsText
        var words = Set<Int>()
        for row in rows {
            if let local = row.change?.hafsWordsByAyah[hafsAyah] {
                words.formUnion(QiraatPlacesStore.wordIndices(local, everyDifference: true))
            }
        }
        return QiraatTint.attributed(text, tokens: QiraatWordDiff.tokens(of: text), words: words, base: .primary, tint: accent)
    }

    private var differingSummary: String {
        let available = rows.filter { $0.resolved != nil }.count
        let differ = differingRows.count
        if differ == 0 { return "All \(available) riwayat read this ayah as Hafs does." }
        if differ == available { return "Every one of the \(available) riwayat reads this ayah differently." }
        return "\(differ) of \(available) riwayat read this ayah differently."
    }

    private var readingGroups: [QiraatReadingGroup] { derived.groups }

    private func computeReadingGroups() -> [QiraatReadingGroup] {
        var groups: [QiraatReadingGroup] = []
        var index: [String: Int] = [:]
        for row in differingRows {
            guard let change = row.change else { continue }
            let hafs = change.hafsPhrase
            let theirs = change.riwayahPhrase
            // Keyed on the vocalized words: two riwayat only share a row when they read the same
            // form, so a vowel-only difference between them is never folded into one word.
            let key = hafs + "|" + theirs
            if let at = index[key] {
                groups[at].tags.append(row.option.tag)
            } else {
                index[key] = groups.count
                groups.append(QiraatReadingGroup(id: key, tags: [row.option.tag], hafsWords: hafs, riwayahWords: theirs))
            }
        }
        return groups
    }

    private var junctures: [QiraatVariantsStore.Juncture] { derived.junctures }

    @ViewBuilder
    private var ayahSections: some View {
        Section(header: Text("HAFS AN ASIM · REFERENCE")) {
            VStack(alignment: .leading, spacing: 8) {
                arabicBlock(referenceAttributed, tag: "")

                if let english = ayahObject?.textEnglishSaheeh, !english.isEmpty {
                    Text(english)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(differingSummary)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(differingRows.isEmpty ? .secondary : accent)
            }
            .padding(.vertical, 4)
        }

        if differingRows.isEmpty {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Read alike here", systemImage: "checkmark.circle")
                        .font(.subheadline.weight(.semibold))
                    Text("No riwayah differs from Hafs anywhere in this ayah. Use the arrows to move to the nearest place where one does.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        } else {
            Section(header: Text("WHAT CHANGES")) {
                ForEach(readingGroups) { group in
                    readingGroupRow(group)
                }
            }
        }

        juncturesSection(junctures)

        Section(header: riwayatHeader) {
            ForEach(differingRows) { row in
                riwayahRow(row)
            }

            if !identicalRows.isEmpty {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { showIdentical.toggle() }
                } label: {
                    HStack {
                        Text(showIdentical
                             ? "Hide the \(identicalRows.count) that read as Hafs here"
                             : "Show the \(identicalRows.count) that read as Hafs here")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: showIdentical ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .foregroundColor(accent)
                }
                .buttonStyle(.plain)

                if showIdentical {
                    ForEach(identicalRows) { row in
                        riwayahRow(row)
                    }
                }
            }
        }

        Section(footer:
            Text("Every riwayah's words come from its printed mushaf, and its changed words are tinted: those the words themselves show, and those the print marks as read differently over the same letters. Ayahs are aligned by their words, so a riwayah that numbers this ayah differently or joins it with a neighbor still shows the same words, with a note on its row. Readings and their meanings are from the Quran.com qiraat reference.")
                .font(.caption2)
        ) { EmptyView() }
    }

    @ViewBuilder
    private func juncturesSection(_ junctures: [QiraatVariantsStore.Juncture]) -> some View {
        if !junctures.isEmpty {
            Section(header: Text("THE READINGS AND WHAT THEY MEAN")) {
                ForEach(junctures) { juncture in
                    junctureRow(juncture)
                }

                if let surah = surahObject, let ayah = ayahObject {
                    NavigationLink(destination: LazyDestination { AyahQiraatVariantsView(surah: surah, ayah: ayah) }) {
                        Label("All Readings and Notes", systemImage: "text.book.closed")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(accent)
                    }
                }
            }
        }
    }

    private var riwayatHeader: some View {
        HStack {
            Text("RIWAYAT")
            Spacer()
            Text(differingRows.count == 1 ? "1 differs" : "\(differingRows.count) differ")
        }
    }

    private func chip(_ tag: String) -> some View {
        Text(QiraatProfiles.shortName(of: tag))
            .font(.caption2.weight(.bold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.primary.opacity(0.08)))
    }

    private func readingGroupRow(_ group: QiraatReadingGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            FlowLayoutView(spacing: 6) {
                ForEach(group.tags, id: \.self) { tag in
                    chip(tag)
                }
            }

            HStack(alignment: .top, spacing: 10) {
                readingColumn(title: "Hafs reads", words: group.hafsWords, tint: .primary)

                Image(systemName: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 22)

                readingColumn(
                    title: group.tags.count == 1 ? "\(QiraatProfiles.shortName(of: group.tags[0])) reads" : "They read",
                    words: group.riwayahWords,
                    tint: accent
                )
            }
        }
        .padding(.vertical, 4)
    }

    private func readingColumn(title: String, words: String, tint: Color) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            if words.isEmpty {
                Text("no word here")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            } else {
                Text(words)
                    .font(quranFont(tag: ""))
                    .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                    .foregroundColor(tint)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func junctureRow(_ juncture: QiraatVariantsStore.Juncture) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(juncture.text)
                .font(.custom(settings.quranArabicFontName(for: nil), size: 20))
                .arabicFontDesign(custom: true)
                .foregroundColor(accent)
                .frame(maxWidth: .infinity, alignment: .trailing)

            if let caption = juncture.categoryCaption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ForEach(juncture.readings) { reading in
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(QiraatVariantsStore.shared.attribution(for: reading))
                            .font(.caption.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        if !reading.english.isEmpty {
                            Text(reading.english)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(reading.text)
                        .font(.custom(settings.quranArabicFontName(for: nil), size: 18))
                        .arabicFontDesign(custom: true)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !juncture.note.isEmpty {
                Text(juncture.note)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func betaBadge(_ option: Settings.Riwayah.Option) -> some View {
        if option.beta {
            Text("BETA")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.orange)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.15), in: Capsule())
        }
    }

    private func riwayahRow(_ row: QiraatRiwayahRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(row.option.label)
                    .font(.subheadline.weight(.semibold))
                Text(row.option.arabic)
                    .font(.caption)
                    .foregroundColor(accent)
                betaBadge(row.option)
                Spacer()
                if row.resolved == nil {
                    Text("Unavailable")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else if !row.differs {
                    Text("Read as Hafs here")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else if let change = row.change {
                    let count = max(change.hafsWords.count, change.riwayahWords.count)
                    wordCountPill(count)
                }
            }

            if let resolved = row.resolved, let note = QiraahAyahResolver.numberNote(resolved) {
                Text(note)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(accent)
            }

            if let change = row.change {
                arabicBlock(
                    QiraatTint.attributed(change.riwayahText, tokens: change.diff.riwayah,
                                          words: Set(change.riwayahWords), base: .primary, tint: accent),
                    tag: row.option.tag
                )
                // Hearing the difference: the same reciter, both readings (four riwayat have one).
                if QiraatVariantAudioStore.isBundled {
                    QiraatVariantAudioButtons(tag: row.option.tag, surah: surahID, ayah: hafsAyah)
                        .padding(.top, 2)
                }
            } else {
                Text("This ayah is not separate in this riwayah.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(row.resolved == nil ? 0.55 : 1)
    }

    private func wordCountPill(_ count: Int) -> some View {
        Text(count == 1 ? "1 word" : "\(count) words")
            .font(.caption2.weight(.bold))
            .foregroundColor(accent)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill(accent.opacity(0.14)))
    }

    // MARK: Head-to-Head

    private func duelText(_ tag: String, surah: Int, ayah: Int) -> ResolvedQiraahText? {
        QiraahAyahResolver.resolve(surahNumber: surah, ayahNumber: ayah, anchorHafsAyah: ayah, optionTag: tag, clean: false)
    }

    /// The Hafs ayahs of a surah where the two sides read differently: the places where either
    /// differs from Hafs (the index), kept when the two resolved texts actually differ. Cached per
    /// surah and pair; two narrators who carry one text (Ishaq and Idris) have none anywhere.
    private func duelPlaces(surah: Int) -> [Int] {
        let a = duelA, b = duelB
        let key = "\(surah)|\(a)|\(b)|\(everyDifference ? 1 : 0)"
        if let cached = duelPlacesCache[key] { return cached }
        var out: [Int] = []
        if a != b, !QiraatProfiles.shareOneText(a, b) {
            let tags = [a, b].filter { !$0.isEmpty }
            for ayah in store.variantAyahs(surah: surah, tags: tags, everyDifference: everyDifference) {
                let x = duelText(a, surah: surah, ayah: ayah).map { QiraatTint.withoutStopSigns($0.text) }
                let y = duelText(b, surah: surah, ayah: ayah).map { QiraatTint.withoutStopSigns($0.text) }
                if x != y { out.append(ayah) }
            }
        }
        duelPlacesCache[key] = out
        return out
    }

    private func duelStep(from surah: Int, ayah: Int, forward: Bool) -> (surah: Int, ayah: Int)? {
        var current = surah
        var floor = ayah
        while (1...114).contains(current) {
            let list = duelPlaces(surah: current)
            if forward, let next = list.first(where: { $0 > floor }) { return (current, next) }
            if !forward, let previous = list.last(where: { $0 < floor }) { return (current, previous) }
            current += forward ? 1 : -1
            floor = forward ? 0 : Int.max
        }
        return nil
    }

    /// The two sides at the current place, diffed against EACH OTHER (not against Hafs), and the
    /// previous and next places where they part ways.
    private func refreshDuel() {
        let a = duelA, b = duelB
        var next = DuelDerived()
        next.aResolved = duelText(a, surah: surahID, ayah: hafsAyah)
        next.bResolved = duelText(b, surah: surahID, ayah: hafsAyah)
        let aText = next.aResolved?.text ?? ""
        let bText = next.bResolved?.text ?? ""
        let diff = QiraatWordDiff.compare(hafs: aText, riwayah: bText)
        var aWords = Set(diff.hafsOnly)
        var bWords = Set(diff.riwayahOnly)
        // Paired words that fold alike but are written differently (other vowels, a dagger alef,
        // a hamzah): the folded diff is blind to them, the exact text is not.
        for (h, r) in diff.pairs
        where QiraatTint.withoutStopSigns(diff.hafs[h].text) != QiraatTint.withoutStopSigns(diff.riwayah[r].text) {
            aWords.insert(h)
            bWords.insert(r)
        }
        next.aStyled = QiraatTint.attributed(aText, tokens: diff.hafs, words: aWords, base: .primary, tint: accent)
        next.bStyled = QiraatTint.attributed(bText, tokens: diff.riwayah, words: bWords, base: .primary, tint: accent)
        next.aWords = aWords.sorted().map { QiraatTint.withoutStopSigns(diff.hafs[$0].text) }.joined(separator: " ")
        next.bWords = bWords.sorted().map { QiraatTint.withoutStopSigns(diff.riwayah[$0].text) }.joined(separator: " ")
        next.differs = !aWords.isEmpty || !bWords.isEmpty
        next.wordCount = max(aWords.count, bWords.count)
        next.previous = duelStep(from: surahID, ayah: hafsAyah, forward: false)
        next.next = duelStep(from: surahID, ayah: hafsAyah, forward: true)
        let places = duelPlaces(surah: surahID)
        if let index = places.firstIndex(of: hafsAyah) {
            next.caption = "Place \(index + 1) of \(places.count) in this surah"
        } else if places.isEmpty {
            next.caption = "\(duelShortA) and \(duelShortB) read this surah alike"
        } else {
            next.caption = "Read alike here · \(places.count) places differ in this surah"
        }
        next.junctures = QiraatVariantsStore.shared.junctures(surah: surahID, ayah: hafsAyah)
        duel = next
    }

    private var duelFooter: String {
        if QiraatProfiles.shareOneText(duelA, duelB) { return QiraatProfiles.sharedTextExplanation }
        let tier = everyDifference
            ? "Every difference counts, down to one letter's marks."
            : "Stepping by word-level changes; turn on Every Difference in the options menu to step by single marks too."
        return "Pick any two riwayat and step through the places where they read differently. Words tinted in the accent color differ between the two. " + tier
    }

    @ViewBuilder
    private var duelSections: some View {
        Section {
            HStack(spacing: 10) {
                ArabicTextRiwayahPicker(selection: Binding(get: { duelA }, set: { duelARaw = $0 }), sideLabel: "A")

                Button {
                    settings.hapticFeedback()
                    let a = duelA, b = duelB
                    withAnimation(.easeInOut) {
                        duelARaw = b
                        duelBRaw = a
                    }
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accent)
                        .padding(6)
                        .background(Circle().fill(accent.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Swap the two riwayat")

                ArabicTextRiwayahPicker(selection: Binding(get: { duelB }, set: { duelBRaw = $0 }), sideLabel: "B")
            }
            .padding(.vertical, 2)
        } footer: {
            Text(duelFooter)
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section(header: Text(duel.differs ? "WHAT CHANGES" : "AT THIS PLACE")) {
            if duel.differs, !duel.aWords.isEmpty || !duel.bWords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        wordCountPill(duel.wordCount)
                        Text("differ between \(duelShortA) and \(duelShortB)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    HStack(alignment: .top, spacing: 10) {
                        readingColumn(title: "\(duelShortA) reads", words: duel.aWords, tint: .primary)

                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 22)

                        readingColumn(title: "\(duelShortB) reads", words: duel.bWords, tint: accent)
                    }
                }
                .padding(.vertical, 4)
            } else if duel.differs {
                Text("The two texts differ only in the marks or the signs of this ayah.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Label("\(duelShortA) and \(duelShortB) read this ayah alike", systemImage: "checkmark.circle")
                        .font(.subheadline.weight(.semibold))
                    Text("Use the arrows to move to the nearest place where the two part ways.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }
        }

        Section(header: Text("SIDE BY SIDE")) {
            duelCard(tag: duelA, resolved: duel.aResolved, styled: duel.aStyled)
            duelCard(tag: duelB, resolved: duel.bResolved, styled: duel.bStyled)
        }

        juncturesSection(duel.junctures)

        Section(footer:
            Text("Each side is the riwayah's own printed text, aligned to the same words through Hafs, so a riwayah that numbers this ayah differently or joins it with a neighbor still shows the same words, with a note on its card.")
                .font(.caption2)
        ) { EmptyView() }
    }

    private func duelCard(tag: String, resolved: ResolvedQiraahText?, styled: AttributedString) -> some View {
        let option = Settings.Riwayah.option(for: tag)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(option.label)
                    .font(.subheadline.weight(.semibold))
                Text(option.arabic)
                    .font(.caption)
                    .foregroundColor(accent)
                betaBadge(option)
                Spacer()
                if resolved == nil {
                    Text("Unavailable")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if let resolved, let note = QiraahAyahResolver.numberNote(resolved) {
                Text(note)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(accent)
            }

            if resolved != nil {
                arabicBlock(styled, tag: tag)
                if QiraatVariantAudioStore.isBundled, !tag.isEmpty {
                    QiraatVariantAudioButtons(tag: tag, surah: surahID, ayah: hafsAyah)
                        .padding(.top, 2)
                }
            } else {
                Text("This ayah is not separate in this riwayah.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(resolved == nil ? 0.55 : 1)
    }

    // MARK: Surah mode

    private var listedAyahs: [Int] {
        if onlyDifferences { return store.variantAyahs(surah: surahID, tags: [compareTag], everyDifference: everyDifference) }
        return Array(1...max(1, surahObject?.numberOfAyahs ?? 1))
    }

    @ViewBuilder
    private var surahSections: some View {
        let listed = listedAyahs
        let ayahCount = surahObject?.numberOfAyahs ?? 0
        let count = store.count(surah: surahID, tags: [compareTag], everyDifference: everyDifference)

        Section {
            riwayahMenu

            Toggle(isOn: $onlyDifferences.animation(.easeInOut)) {
                Text("Only differences")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(accent)
            .onChange(of: onlyDifferences) { _ in settings.hapticFeedback() }

            Toggle(isOn: $everyDifference.animation(.easeInOut)) {
                Text("Every difference")
                    .font(.subheadline.weight(.semibold))
            }
            .tint(accent)
            .onChange(of: everyDifference) { _ in settings.hapticFeedback() }
        } footer: {
            Text((count == 0
                  ? "\(QiraatProfiles.shortName(of: compareTag)) reads every ayah of \(surahName) as Hafs does. "
                  : "\(count) of \(ayahCount) ayahs of \(surahName) differ between Hafs and \(QiraatProfiles.shortName(of: compareTag)). Tap an ayah to see what changes and how every riwayah reads it. ")
                 + (everyDifference
                    ? "Every difference counts, down to one letter's dots, hamzah or vowel."
                    : "Counting word-level changes: another word form, added or dropped letters, other vowels. Turn on Every Difference to count single letters too."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        Section(header: Text(onlyDifferences ? "AYAHS THAT DIFFER" : "EVERY AYAH")) {
            if listed.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("\(QiraatProfiles.shortName(of: compareTag)) reads this surah exactly as Hafs does", systemImage: "checkmark.circle")
                        .font(.subheadline.weight(.semibold))
                    Text("There is nothing here to line up. Choose another riwayah, or turn the filter off to read the surah through.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            ForEach(listed.prefix(visibleRows), id: \.self) { ayah in
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        hafsAyah = ayah
                        mode = .ayah
                    }
                } label: {
                    surahRow(ayah)
                }
                .buttonStyle(.plain)
            }

            if listed.count > visibleRows {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { visibleRows += Self.surahPage }
                } label: {
                    HStack {
                        Text("Show \(min(Self.surahPage, listed.count - visibleRows)) more")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(listed.count - visibleRows) left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .foregroundColor(accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// The app's one riwayah picker (the nested qiraah menu), in row form, without Hafs: the walk
    /// compares against Hafs, so Hafs is never the thing walked.
    private var riwayahMenu: some View {
        ArabicTextRiwayahPicker(selection: $compareTagRaw, useMenuRow: true, title: "Riwayah", includeHafs: false)
    }

    private func surahRow(_ ayah: Int) -> some View {
        let model = surahRows[ayah]
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Ayah \(ayah)")
                    .font(.subheadline.weight(.semibold))
                if let model, model.differs {
                    Text(model.wordCount == 1 ? "1 word" : "\(model.wordCount) words")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(accent)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(accent.opacity(0.14)))
                } else if model != nil {
                    Text("Read alike")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }

            if let model {
                if let note = model.note {
                    Text(note)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(accent)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text("HAFS")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tertiary)
                    arabicBlock(model.hafs, tag: "")
                }

                if let riwayah = model.riwayah {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(QiraatProfiles.shortName(of: compareTag).uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.tertiary)
                        arabicBlock(riwayah, tag: compareTag)
                    }
                } else {
                    Text("This ayah is not separate in this riwayah.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: Data

    private func refresh() {
        switch mode {
        case .ayah: refreshRows()
        case .duel: refreshDuel()
        case .surah: refreshSurahRows()
        }
        warmNextSurah()
    }

    /// Every resolve needs its surah's alignment against Hafs, and building one costs about 7 ms a
    /// riwayah: stepping into a new surah blocked the main thread for 46 ms with the seven default
    /// riwayat and 240 ms with all nineteen (`-qiraatBench`, optimized build, iPhone 17 Pro
    /// simulator). It cannot simply move off the main thread (`QiraahComparison` is main-only by
    /// the crash-hardening rule), so it moves EARLY instead: while the reader looks at this place,
    /// the NEXT surah is aligned one riwayah per runloop turn, and the step into it finds the
    /// tables already built. Forward only (that is the direction the bar walks), and never on the
    /// reduced tier, which does no prebuilds at all.
    private func warmNextSurah() {
        warmTask?.cancel()
        guard !AppPerformance.shouldAvoidBroadPrewarm, surahID < 114 else { return }
        let next = surahID + 1
        let tags: [String]
        switch mode {
        case .ayah: tags = enabledTags
        case .duel: tags = [duelA, duelB].filter { !$0.isEmpty }
        case .surah: tags = [compareTag]
        }
        guard !tags.isEmpty else { return }
        warmTask = Task { @MainActor in
            #if DEBUG
            let started = DispatchTime.now().uptimeNanoseconds
            #endif
            for tag in tags {
                guard !Task.isCancelled else { return }
                _ = QiraahComparison.alignment(surahID: next, tag: tag, quranData: quranData)
                await Task.yield()
            }
            #if DEBUG
            if RenderCounter.enabled {
                NSLog("EXPLORER warm surah %d, %d riwayat, %.1f ms spread", next, tags.count,
                      Double(DispatchTime.now().uptimeNanoseconds - started) / 1_000_000)
            }
            #endif
        }
    }

    /// Every enabled riwayah at the current ayah, resolved through Hafs and diffed once, and the
    /// values the bar and the reference block derive from them.
    private func refreshRows() {
        let tags = enabledTags
        let key = "\(surahID)|\(hafsAyah)|\(everyDifference ? 1 : 0)|\(settings.accentColor.rawValue)|\(tags.joined(separator: ","))"
        guard key != rowsKey else { return }
        #if DEBUG
        let started = DispatchTime.now().uptimeNanoseconds
        #endif
        let rowsChanged = !rowsKey.hasPrefix("\(surahID)|\(hafsAyah)|") || rows.isEmpty
        rowsKey = key
        if rowsChanged {
            showIdentical = false
            rows = tags.map { tag in
                let option = Settings.Riwayah.option(for: tag)
                guard let resolved = QiraahAyahResolver.resolve(surahNumber: surahID, ayahNumber: hafsAyah,
                                                                anchorHafsAyah: hafsAyah, optionTag: tag, clean: false) else {
                    return QiraatRiwayahRow(option: option, resolved: nil, change: nil)
                }
                return QiraatRiwayahRow(option: option, resolved: resolved,
                                        change: Self.change(for: tag, surah: surahID, hafsAyah: hafsAyah, resolved: resolved, quranData: quranData))
            }
        }
        var next = AyahDerived()
        next.previous = store.step(from: surahID, ayah: hafsAyah, forward: false, tags: tags, everyDifference: everyDifference)
        next.next = store.step(from: surahID, ayah: hafsAyah, forward: true, tags: tags, everyDifference: everyDifference)
        next.caption = computePlaceCaption()
        next.reference = computeReferenceAttributed()
        next.groups = computeReadingGroups()
        next.junctures = QiraatVariantsStore.shared.junctures(surah: surahID, ayah: hafsAyah)
        derived = next
        #if DEBUG
        if RenderCounter.enabled {
            NSLog("EXPLORER rows %d:%d %d riwayat %.1f ms (rows %@)", surahID, hafsAyah, tags.count,
                  Double(DispatchTime.now().uptimeNanoseconds - started) / 1_000_000, rowsChanged ? "rebuilt" : "kept")
        }
        #endif
    }

    /// The Hafs side is the ayah itself or the whole span the riwayah joins; the riwayah side is its
    /// own ayah or every piece a split divides this ayah into.
    static func change(for tag: String, surah: Int, hafsAyah: Int, resolved: ResolvedQiraahText, quranData: QuranData) -> QiraatChange {
        let span = resolved.mergedSpan ?? (hafsAyah...hafsAyah)
        let hafsPieces: [(ayah: Int, text: String)] = span.compactMap { number in
            quranData.ayah(surah: surah, ayah: number).map { (number, $0.displayArabicText(surahId: surah, clean: false, qiraahOverride: "")) }
        }
        let own = resolved.ownNumber ?? hafsAyah
        let owns = resolved.splitSpan.map { Array($0) } ?? [own]
        let riwayahPieces: [(own: Int, text: String)] = owns.compactMap { number in
            quranData.ayah(surah: surah, ayah: number).map { (number, $0.displayArabicText(surahId: surah, clean: false, qiraahOverride: tag)) }
        }
        return QiraatChange.analyze(hafsPieces: hafsPieces, riwayahPieces: riwayahPieces, tag: tag, surah: surah)
    }

    private func refreshSurahRows() {
        let listed = Array(listedAyahs.prefix(visibleRows))
        let key = "\(surahID)|\(compareTag)|\(onlyDifferences)|\(everyDifference)|\(listed.count)"
        guard key != surahRowsKey else { return }
        surahRowsKey = key
        #if DEBUG
        let started = DispatchTime.now().uptimeNanoseconds
        defer {
            if RenderCounter.enabled {
                NSLog("EXPLORER surah %d %d rows %.1f ms", surahID, listed.count, Double(DispatchTime.now().uptimeNanoseconds - started) / 1_000_000)
            }
        }
        #endif
        var models: [Int: QiraatSurahRowModel] = [:]
        for ayah in listed {
            models[ayah] = QiraatSurahRowModel.make(surah: surahID, hafsAyah: ayah, tag: compareTag, quranData: quranData, accent: accent)
        }
        surahRows = models
    }
}

/// One ayah of the surah walk: Hafs and the riwayah, each with its changed words tinted.
struct QiraatSurahRowModel {
    let hafs: AttributedString
    let riwayah: AttributedString?
    let note: String?
    let differs: Bool
    let wordCount: Int

    @MainActor
    static func make(surah: Int, hafsAyah: Int, tag: String, quranData: QuranData, accent: Color) -> QiraatSurahRowModel {
        let hafsText = quranData.ayah(surah: surah, ayah: hafsAyah)?.displayArabicText(surahId: surah, clean: false, qiraahOverride: "") ?? ""
        guard let resolved = QiraahAyahResolver.resolve(surahNumber: surah, ayahNumber: hafsAyah, anchorHafsAyah: hafsAyah,
                                                        optionTag: tag, clean: false) else {
            return QiraatSurahRowModel(hafs: AttributedString(hafsText), riwayah: nil, note: nil, differs: false, wordCount: 0)
        }
        let change = QiraatExplorerView.change(for: tag, surah: surah, hafsAyah: hafsAyah, resolved: resolved, quranData: quranData)
        let hafsWords = Set(QiraatPlacesStore.wordIndices(change.hafsWordsByAyah[hafsAyah] ?? [], everyDifference: true))
        return QiraatSurahRowModel(
            hafs: QiraatTint.attributed(hafsText, tokens: QiraatWordDiff.tokens(of: hafsText), words: hafsWords, base: .primary, tint: accent),
            riwayah: QiraatTint.attributed(change.riwayahText, tokens: change.diff.riwayah, words: Set(change.riwayahWords), base: .primary, tint: accent),
            note: QiraahAyahResolver.numberNote(resolved),
            differs: change.differs,
            wordCount: max(hafsWords.count, change.riwayahWords.count)
        )
    }
}

// MARK: - Compare all twenty

/// The way from eight riwayat to all twenty: the twelve riwayat the King Fahd Complex has not
/// published as text ship as printed mushafs, and their selectable text is a beta transcription
/// that the reader turns on knowingly (the same consent the reader's Page Text menu asks for).
struct QiraatExplorerUnlockSheet: View {
    @ObservedObject private var settings = Settings.shared
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
/// with its count of places.
struct QiraatPlacePickerSheet: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahID: Int
    let hafsAyah: Int
    let tags: [String]
    let everyDifference: Bool
    var startOnSurahs = false
    /// `ayah` nil = the surah was picked (surah mode), else the place.
    let onPick: (_ surah: Int, _ ayah: Int?) -> Void

    @State private var tab = 0
    @State private var searchText = ""

    init(surahID: Int, hafsAyah: Int, tags: [String], everyDifference: Bool, startOnSurahs: Bool = false,
         onPick: @escaping (_ surah: Int, _ ayah: Int?) -> Void) {
        self.surahID = surahID
        self.hafsAyah = hafsAyah
        self.tags = tags
        self.everyDifference = everyDifference
        self.startOnSurahs = startOnSurahs
        self.onPick = onPick
        _tab = State(initialValue: startOnSurahs ? 1 : 0)
    }

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
    }

    private var thisSurahSection: some View {
        let places = store.variantAyahs(surah: surahID, tags: tags, everyDifference: everyDifference)
        let name = quranData.surah(surahID)?.nameTransliteration ?? "Surah \(surahID)"
        return Section(header: HStack {
            Text(name.uppercased())
            Spacer()
            Text(places.count == 1 ? "1 place" : "\(places.count) places")
        }) {
            if places.isEmpty {
                Text("No riwayah differs from Hafs anywhere in this surah.")
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
        let text = quranData.ayah(surah: surahID, ayah: ayah)?.displayArabicText(surahId: surahID, clean: false, qiraahOverride: "") ?? ""
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
        let counted = store.hasWholeQuranCounts
        return Section(header: Text("SURAHS")) {
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
                        if counted {
                            let count = store.count(surah: surah.id, tags: tags, everyDifference: everyDifference)
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
