#if os(iOS)
import SwiftUI
import UIKit
import Compression

// Word-by-word meanings: tap any word of an ayah and see what that word means, and how it is said.
//
// Three pieces live here:
//   * `WordByWordStore`   - the bundled gloss pack and the lookup that lines it up with the text
//                           actually on screen;
//   * `WordByWordText`    - the reader's Arabic, rendered so a single word can be tapped and lit;
//   * `WordMeaningSheet`  - the card that names the tapped word.
//
// Everything is additive: with the setting off (the default) the reader renders exactly as it always
// has, and nothing in this file is even loaded.

// MARK: - Store

/// Per-word English glosses AND Latin transliteration for all 6236 ayahs, from `WordByWord.json.xz`.
///
/// The two layers are aligned by the same build-time walk against the same tokens, so index *n* names
/// the same word in both: a caller that has the glosses can ask for the transliteration with no second
/// reconciliation.
///
/// THE INVARIANT THIS RESTS ON: the pack stores one entry per whitespace-separated token of THIS APP's
/// Hafs text, in the app's own token order - the alignment against the upstream corpus (whose tokenizing
/// differs on ~200 ayahs) is done at build time by `Scripts/build_wordbyword.py` and gated by
/// `Scripts/verify_wordbyword.py`. So the reader never matches, normalizes, or guesses: it splits the
/// ayah on whitespace and indexes straight in. Tokens with no gloss of their own (the ۞ mark; the tail
/// of a word the corpus writes as two) hold "" and are simply not tappable.
///
/// Thread-safe by lock rather than actor isolation, exactly like `BetaQiraatStore`: glosses are read
/// from the main thread while rendering, and the load itself is a megabyte of JSON that must not be
/// parsed on it.
final class WordByWordStore: @unchecked Sendable {
    static let shared = WordByWordStore()
    private init() {}

    /// The two aligned layers, each surah id → ayahs in id order → one entry per token.
    struct Table {
        let english: [Int: [[String]]]
        let latin: [Int: [[String]]]
    }

    /// Which layer a lookup wants. Both are indexed identically.
    enum Layer {
        case english
        case transliteration
    }

    private let lock = NSLock()
    private var table: Table?
    private var loadFailed = false

    /// Whether the pack is in the bundle at all - a cheap URL lookup, so callers can gate UI (the
    /// settings toggle) without paying for the parse.
    static let isBundled: Bool = packURL() != nil

    /// The pack file itself, for the cross-language lexicon's cache signature (its size and date
    /// stamp the lexicon that was derived from it).
    static var bundledPackURL: URL? { packURL() }

    /// Raw entries for one ayah, in the app's Hafs token order. Prefer `entries(_:surah:ayah:rawText:displayText:)`,
    /// which reconciles this with what the reader is actually showing.
    func entries(_ layer: Layer, surah: Int, ayah: Int) -> [String]? {
        guard let table = loadedTable() else { return nil }
        let source = layer == .english ? table.english : table.latin
        guard let rows = source[surah], ayah >= 1, ayah <= rows.count else { return nil }
        return rows[ayah - 1]
    }

    /// Raw English glosses for one ayah, in the app's Hafs token order.
    func glosses(surah: Int, ayah: Int) -> [String]? {
        entries(.english, surah: surah, ayah: ayah)
    }

    /// Raw per-word transliteration for one ayah, in the app's Hafs token order.
    func transliterations(surah: Int, ayah: Int) -> [String]? {
        entries(.transliteration, surah: surah, ayah: ayah)
    }

    /// Entries lined up with the tokens of `displayText`, or nil when they cannot be lined up.
    ///
    /// The reader does not always show the raw text: "Hide Tashkeel and Signs" strips U+06D6…U+06ED,
    /// which DELETES the standalone ۞ token from the 199 ayahs that carry one, so the displayed text has
    /// one token fewer than the pack has glosses. Dropping the glosses whose token vanished restores the
    /// alignment. Any other disagreement (a riwayah with different wording, beginner letter-spacing) is
    /// not reconcilable and returns nil, which switches the feature off for that ayah rather than
    /// showing a neighbouring word's meaning.
    func entries(_ layer: Layer, surah: Int, ayah: Int, rawText: String, displayText: String) -> [String]? {
        guard let raw = entries(layer, surah: surah, ayah: ayah) else { return nil }

        let displayCount = WordTokens.count(in: displayText)
        if raw.count == displayCount { return raw }

        let rawTokens = WordTokens.tokens(in: rawText)
        guard rawTokens.count == raw.count else { return nil }

        // Keep only the entries whose token still has content once the sign-stripping is applied.
        var kept: [String] = []
        kept.reserveCapacity(displayCount)
        for (token, entry) in zip(rawTokens, raw) where !token.removingArabicDiacriticsAndSigns
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            kept.append(entry)
        }
        return kept.count == displayCount ? kept : nil
    }

    /// English glosses lined up with the tokens of `displayText`, or nil when they cannot be lined up.
    func glosses(surah: Int, ayah: Int, rawText: String, displayText: String) -> [String]? {
        entries(.english, surah: surah, ayah: ayah, rawText: rawText, displayText: displayText)
    }

    /// Per-word transliteration lined up with the tokens of `displayText`, or nil when they cannot be.
    func transliterations(surah: Int, ayah: Int, rawText: String, displayText: String) -> [String]? {
        entries(.transliteration, surah: surah, ayah: ayah, rawText: rawText, displayText: displayText)
    }

    /// Parses the pack off-main ahead of the first glossed row (Phase 10.5). `loadedTable()` runs on the
    /// CALLER's thread, and the first caller used to be an `AyahRow` body: ~2 MB of JSON inflated and
    /// bridged on the main thread, in the launch window for a reader opened at launch. The Quran load
    /// kicks this when a word switch is on, and the switches kick it when they turn on.
    func prewarm() {
        lock.lock()
        let needed = table == nil && !loadFailed
        lock.unlock()
        guard needed, Self.isBundled else { return }
        Task.detached(priority: .utility) { [self] in _ = self.loadedTable() }
    }

    /// Drops the parsed table (the setting was switched off). The pack reloads on next use.
    func unload() {
        lock.lock(); defer { lock.unlock() }
        table = nil
        loadFailed = false
    }

    private func loadedTable() -> Table? {
        lock.lock()
        if let table { lock.unlock(); return table }
        if loadFailed { lock.unlock(); return nil }
        lock.unlock()

        // Parse OUTSIDE the lock (~1 MB of JSON); double-check on the way back in so two threads racing
        // the first lookup just keep the first result.
        guard let parsed = Self.load() else {
            lock.lock(); loadFailed = true; lock.unlock()
            return nil
        }
        lock.lock(); defer { lock.unlock() }
        if let table { return table }
        table = parsed
        return parsed
    }

    private static func packURL() -> URL? {
        Bundle.main.url(forResource: "WordByWord", withExtension: "json.xz", subdirectory: "Data/Quran")
            ?? Bundle.main.url(forResource: "WordByWord", withExtension: "json.xz", subdirectory: "Quran")
            ?? Bundle.main.url(forResource: "WordByWord", withExtension: "json.xz")
    }

    private static func load() -> Table? {
        guard let url = packURL(),
              let blob = try? Data(contentsOf: url),
              let json = inflate(blob),
              let root = try? JSONSerialization.jsonObject(with: json) as? [String: Any] else { return nil }

        // Version 2 carries both layers under "en"/"tr". Version 1 was the English layer alone, with
        // surah ids at the top level; it is still read so an older pack degrades to no transliteration
        // rather than to no word-by-word at all.
        if let english = root["en"] as? [String: [[String]]] {
            let latin = root["tr"] as? [String: [[String]]] ?? [:]
            let table = Table(english: keyedBySurah(english), latin: keyedBySurah(latin))
            return table.english.isEmpty ? nil : table
        }

        guard let legacy = root as? [String: [[String]]] else { return nil }
        let english = keyedBySurah(legacy)
        return english.isEmpty ? nil : Table(english: english, latin: [:])
    }

    private static func keyedBySurah(_ raw: [String: [[String]]]) -> [Int: [[String]]] {
        var out: [Int: [[String]]] = [:]
        out.reserveCapacity(raw.count)
        for (surahKey, rows) in raw {
            guard let sid = Int(surahKey) else { continue }
            out[sid] = rows
        }
        return out
    }

    /// The payload is an xz stream (what `Scripts/build_wordbyword.py` writes); `COMPRESSION_LZMA` reads that container directly.
    private static func inflate(_ data: Data) -> Data? {
        SolidPack.xzDecompress(data)
    }
}

// MARK: - Tokenizing

/// The one definition of "a word" in an ayah: a run of non-whitespace. It has to match, exactly, the
/// tokenizing `Scripts/build_wordbyword.py` does - the gloss at index *n* belongs to the *n*th token and
/// nothing reconciles them at runtime.
enum WordTokens {
    /// UTF-16 ranges of each token, for indexing into an `NSAttributedString`.
    static func ranges(in text: String) -> [NSRange] {
        let ns = text as NSString
        var ranges: [NSRange] = []
        var index = 0
        while index < ns.length {
            // Skip whitespace.
            while index < ns.length, isWhitespace(ns.character(at: index)) { index += 1 }
            guard index < ns.length else { break }
            let start = index
            while index < ns.length, !isWhitespace(ns.character(at: index)) { index += 1 }
            ranges.append(NSRange(location: start, length: index - start))
        }
        return ranges
    }

    /// Cut from `ranges(in:)`, so a token index means the same thing on both sides. They were a
    /// `split` on `Character.isWhitespace`, which reads a grapheme's FIRST scalar: a space carrying
    /// a combining mark (" ۚ" in ad-Duri's and as-Susi's 4:44) was one whitespace Character there and
    /// a token of its own here, and every tap after it opened the next word's card (2026-10-04).
    static func tokens(in text: String) -> [String] {
        let ns = text as NSString
        return ranges(in: text).map { ns.substring(with: $0) }
    }

    static func count(in text: String) -> Int {
        ranges(in: text).count
    }

    /// Which token contains `utf16Offset`, or nil when the offset is in whitespace / past the tokens.
    static func index(of utf16Offset: Int, in ranges: [NSRange]) -> Int? {
        ranges.firstIndex { NSLocationInRange(utf16Offset, $0) }
    }

    private static func isWhitespace(_ unit: unichar) -> Bool {
        // The separators that actually occur between Quranic words: space, tab, newline, NBSP, and the
        // narrow/thin spaces some sources use.
        unit == 0x20 || unit == 0x09 || unit == 0x0A || unit == 0x0D
            || unit == 0xA0 || unit == 0x2009 || unit == 0x200A || unit == 0x202F
    }
}

// MARK: - Cross-language search highlight

/// Maps a search hit in one language to the aligned word(s) in the other, through the gloss pack:
/// an ARABIC query's matched tokens name their English glosses, whose content words are then lit in
/// the translation lines; an ENGLISH query lights the Arabic tokens whose gloss carries the query.
/// Alignment holds only where the pack's contract holds (Hafs display, no beginner spacing) - the
/// callers gate on that, and `glosses(surah:ayah:rawText:displayText:)` returns nil otherwise anyway.
///
/// Everything here is approximate ON PURPOSE: glosses are a literal word-for-word rendering, not an
/// excerpt of the flowing translation, so the English side matches word-by-word (whole words, prefix
/// and shared-stem tolerant) rather than as phrases - a wrong-word highlight is worse than none.
enum CrossLanguageWordHighlight {
    /// Glue words a gloss carries around its content word ("(of) Allah", "the Most Gracious") and
    /// that an English query shouldn't align through - too common to identify a word pair.
    private static let stopwords: Set<String> = [
        "the", "and", "for", "with", "that", "this", "those", "these", "not", "nor",
        "who", "whom", "what", "which", "will", "shall", "was", "were", "are", "has",
        "have", "had", "his", "her", "him", "its", "their", "them", "they", "you",
        "your", "then", "than", "but", "from", "into", "unto", "upon", "when", "there",
        "indeed", "surely", "verily", "any", "all", "one"
    ]

    private final class SpansEntry: NSObject {
        let spans: [NSRange]
        init(_ spans: [NSRange]) { self.spans = spans }
    }

    private final class TermsEntry: NSObject {
        let terms: [String]
        init(_ terms: [String]) { self.terms = terms }
    }

    /// NSRange spans are UTF-16 offsets - instance-free, so entries keyed by string CONTENT can serve
    /// any equal-content instance (the `HighlightedSnippet` caches' exact reasoning).
    nonisolated(unsafe) private static let spansCache: NSCache<NSString, SpansEntry> = {
        let c = NSCache<NSString, SpansEntry>()
        c.countLimit = 4_000
        return c
    }()

    nonisolated(unsafe) private static let termsCache: NSCache<NSString, TermsEntry> = {
        let c = NSCache<NSString, TermsEntry>()
        c.countLimit = 2_000
        return c
    }()

    /// ARABIC query → the English gloss content-words of the Arabic tokens the query highlighted.
    /// The caller runs these through `wordSpans(of:in:)` against each translation line.
    ///
    /// Two lanes, unioned. Lane 1 is the display-text match (exact substrings, phrases, the loose
    /// Arabic skeleton) → the tokens those spans touch. Lane 2 is the MORPHOLOGICAL sweep: every
    /// token any query word matches through `arabicWordsMatch` - proclitics (و ف ب ل ك + ال),
    /// enclitic pronouns (صلاتهم ↔ صلاة), the plural واو (قالوا ↔ قال), and the vowel-letter
    /// skeleton (قلب ↔ قلوب). Lane 2 is what "maximize" means here, and it is SAFE in a way the
    /// corpus lexicon can't be: the gloss always comes from the exact token that matched, so looser
    /// matching can never import a neighbouring word's meaning.
    static func englishTermsForArabicMatch(query: String, surah: Int, ayah: Int,
                                           rawText: String, displayText: String,
                                           wordRule: SearchWordRule = .anywhere) -> [String] {
        let key = "a→e\(wordRule.rawValue)\u{0000}\(query)\u{0000}\(surah):\(ayah)\u{0000}\(displayText.hashValue)" as NSString
        if let cached = termsCache.object(forKey: key) { return cached.terms }

        var terms: [String] = []
        defer { termsCache.setObject(TermsEntry(terms), forKey: key) }

        guard query.containsArabicLetters,
              let glosses = WordByWordStore.shared.glosses(surah: surah, ayah: ayah,
                                                           rawText: rawText, displayText: displayText)
        else { return terms }

        let tokenRanges = WordTokens.ranges(in: displayText)
        guard tokenRanges.count == glosses.count else { return terms }

        var tokenIndices: [Int] = []
        var seenTokens = Set<Int>()

        // Lane 1: the matched spans → the tokens they touch (a phrase query or a loose Arabic match
        // can cover several), in order, deduped.
        for match in HighlightedSnippet.matchRanges(of: query, in: displayText, wordRule: wordRule) {
            let span = NSRange(match, in: displayText)
            for (index, token) in tokenRanges.enumerated()
            where NSIntersectionRange(span, token).length > 0 && seenTokens.insert(index).inserted {
                tokenIndices.append(index)
            }
        }

        // Lane 2: the morphological sweep over the ayah's own tokens.
        let queryWords = HighlightedSnippet.normalizeForSearchText(query, trimWhitespace: true)
            .split(separator: " ").map(String.init)
            .filter { $0.count >= 3 }
        if !queryWords.isEmpty {
            let ns = displayText as NSString
            for (index, tokenRange) in tokenRanges.enumerated() where !seenTokens.contains(index) {
                let folded = HighlightedSnippet.normalizeForSearchText(
                    ns.substring(with: tokenRange), trimWhitespace: true)
                guard folded.count >= 3 else { continue }
                if queryWords.contains(where: { arabicWordsMatch($0, folded) }),
                   seenTokens.insert(index).inserted {
                    tokenIndices.append(index)
                }
            }
        }

        var seenTerms = Set<String>()
        for index in tokenIndices.sorted() {
            for word in contentWords(of: glosses[index]) where seenTerms.insert(word).inserted {
                terms.append(word)
            }
        }
        return terms
    }

    /// The Arabic spans an ARABIC query lights in the ayah itself, through the SAME morphology lane 2
    /// uses - so the reader can also tint صلاتهم when the query was صلاة, beyond what the plain
    /// substring highlighter finds. Returns only tokens the base highlighter would MISS.
    static func arabicSpansForArabicQuery(query: String, in displayText: String,
                                          wordRule: SearchWordRule = .anywhere) -> [NSRange] {
        // A word FAMILY is the opposite of what Whole Word, Starts With and Ends With ask for.
        guard wordRule == .anywhere else { return [] }
        let key = "a→a\u{0000}\(query)\u{0000}\(displayText.hashValue)" as NSString
        if let cached = spansCache.object(forKey: key) { return cached.spans }

        var spans: [NSRange] = []
        defer { spansCache.setObject(SpansEntry(spans), forKey: key) }

        guard query.containsArabicLetters else { return spans }
        let queryWords = HighlightedSnippet.normalizeForSearchText(query, trimWhitespace: true)
            .split(separator: " ").map(String.init)
            .filter { $0.count >= 3 }
        guard !queryWords.isEmpty else { return spans }

        // Tokens the base highlighter already colors are excluded - these spans are ADDITIVE.
        var covered = Set<Int>()
        let tokenRanges = WordTokens.ranges(in: displayText)
        for match in HighlightedSnippet.matchRanges(of: query, in: displayText) {
            let span = NSRange(match, in: displayText)
            for (index, token) in tokenRanges.enumerated()
            where NSIntersectionRange(span, token).length > 0 {
                covered.insert(index)
            }
        }

        let ns = displayText as NSString
        for (index, tokenRange) in tokenRanges.enumerated() where !covered.contains(index) {
            let folded = HighlightedSnippet.normalizeForSearchText(
                ns.substring(with: tokenRange), trimWhitespace: true)
            guard folded.count >= 3 else { continue }
            if queryWords.contains(where: { arabicWordsMatch($0, folded) }) {
                spans.append(tokenRange)
            }
        }
        return spans
    }

    /// ENGLISH query → the UTF-16 spans of the Arabic tokens whose gloss carries a query word.
    /// Feed the result to `HighlightedSnippet.extraHighlightRanges` on the Arabic line.
    static func arabicSpansForEnglishMatch(query: String, surah: Int, ayah: Int,
                                           rawText: String, displayText: String) -> [NSRange] {
        let key = "e→a\u{0000}\(query)\u{0000}\(surah):\(ayah)\u{0000}\(displayText.hashValue)" as NSString
        if let cached = spansCache.object(forKey: key) { return cached.spans }

        var spans: [NSRange] = []
        defer { spansCache.setObject(SpansEntry(spans), forKey: key) }

        guard !query.containsArabicLetters,
              let glosses = WordByWordStore.shared.glosses(surah: surah, ayah: ayah,
                                                           rawText: rawText, displayText: displayText)
        else { return spans }

        let queryTokens = HighlightedSnippet.normalizeForSearchText(query, trimWhitespace: true)
            .split(separator: " ").map(String.init)
            .filter { $0.count >= 3 && !stopwords.contains($0) }
        guard !queryTokens.isEmpty else { return spans }

        let tokenRanges = WordTokens.ranges(in: displayText)
        guard tokenRanges.count == glosses.count else { return spans }

        for (index, gloss) in glosses.enumerated() {
            let glossWords = gloss.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 3 && !stopwords.contains($0) }
            guard !glossWords.isEmpty else { continue }
            if queryTokens.contains(where: { q in glossWords.contains { wordMatches(query: q, word: $0) } }) {
                spans.append(tokenRanges[index])
            }
        }
        return spans
    }

    /// Whole-word spans of `terms` in `text` (a translation line): each whitespace token is folded
    /// and compared word-to-word, so "ease" can never light the middle of "increase" the way a
    /// substring pass would. A hyphenated/compound token ("All-Knowing", "so-called") also matches
    /// through its alphanumeric PARTS, which the whole-token fold would otherwise glue into one
    /// unmatchable word. Spans are trimmed of the token's surrounding punctuation.
    static func wordSpans(of terms: [String], in text: String) -> [NSRange] {
        guard !terms.isEmpty, !text.isEmpty else { return [] }
        let key = "spans\u{0000}\(terms.joined(separator: "\u{0001}"))\u{0000}\(text.hashValue)" as NSString
        if let cached = spansCache.object(forKey: key) { return cached.spans }

        var spans: [NSRange] = []
        let ns = text as NSString
        for tokenRange in WordTokens.ranges(in: text) {
            let raw = ns.substring(with: tokenRange)
            let word = HighlightedSnippet.normalizeForSearchText(raw, trimWhitespace: true)
            guard word.count >= 3 else { continue }
            var matched = terms.contains { wordMatches(query: $0, word: word) }
            if !matched, raw.contains(where: { !$0.isLetter && !$0.isNumber }) {
                let parts = raw.lowercased()
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { $0.count >= 3 }
                matched = parts.contains { part in terms.contains { wordMatches(query: $0, word: part) } }
            }
            if matched {
                spans.append(trimmedWordSpan(tokenRange, in: ns))
            }
        }
        spans = bridgingGlueWords(spans, in: ns)
        spansCache.setObject(SpansEntry(spans), forKey: key)
        return spans
    }

    /// Two lit words with nothing but glue between them become ONE span: "establish [the] prayer",
    /// "mercy [of his] Lord". The glosses name content words, so a phrase query landed as scattered
    /// single words with unlit articles and prepositions punched through it - a highlight that read
    /// as chopped. A gap of at most two tokens, every one a stopword or a one-to-two-letter word, is
    /// bridged (the span then runs from the first word's start to the last word's end); a gap
    /// carrying any real word ("prayer and give zakah") stays two spans, because that middle word
    /// was never matched.
    private static func bridgingGlueWords(_ spans: [NSRange], in ns: NSString) -> [NSRange] {
        guard spans.count >= 2 else { return spans }
        var bridged: [NSRange] = [spans[0]]
        for span in spans.dropFirst() {
            let previous = bridged[bridged.count - 1]
            let gapStart = previous.location + previous.length
            let gapLength = span.location - gapStart
            guard gapLength > 0 else {
                bridged[bridged.count - 1] = NSUnionRange(previous, span)
                continue
            }
            let gap = ns.substring(with: NSRange(location: gapStart, length: gapLength))
            let gapWords = gap.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
            // A sentence boundary in the gap is never glue: "prayer. And patience" stays two spans.
            let crossesClause = gap.contains { ".!?;:".contains($0) }
            let isGlue = !crossesClause && gapWords.count <= 2
                && gapWords.allSatisfy { $0.count <= 2 || stopwords.contains($0) }
            if isGlue {
                bridged[bridged.count - 1] = NSUnionRange(previous, span)
            } else {
                bridged.append(span)
            }
        }
        return bridged
    }

    // MARK: Quran-derived lexicon (texts with NO alignment data - hadith)

    /// folded-Arabic-skeleton → every gloss content word that token carries anywhere in the Quran.
    /// Hadith has no word-alignment pack, so its cross-language highlight matches through this
    /// dictionary instead: classical Arabic vocabulary overlaps heavily, and a word the Quran never
    /// uses simply highlights nothing (no guessing). Built ONCE off-main from the gloss pack zipped
    /// against the app's own Hafs text; until it's ready the lookups return empty WITHOUT caching,
    /// so no empty result can stick from the pre-build window.
    nonisolated(unsafe) private static var lexicon: [String: Set<String>]?
    private static let lexiconLock = NSLock()
    nonisolated(unsafe) private static var lexiconBuildStarted = false

    /// The lexicon if built; otherwise kicks the build off (once) and returns nil. Callable from any
    /// thread; the build itself runs at utility QoS off-main (~77k token folds).
    private static func lexiconIfReady(quranSnapshot: @autoclosure () -> [Surah]) -> [String: Set<String>]? {
        lexiconLock.lock()
        let ready = lexicon
        let alreadyStarted = lexiconBuildStarted
        if ready == nil, !alreadyStarted { lexiconBuildStarted = true }
        lexiconLock.unlock()

        if let ready { return ready }
        if !alreadyStarted {
            if Thread.isMainThread {
                // Snapshot the (value-type) surah array here; the fold work moves off main.
                let surahs = quranSnapshot()
                DispatchQueue.global(qos: .utility).async { loadOrBuildLexicon(surahs: surahs) }
            } else {
                // Asked first from a background task (a hadith search row's detached highlight):
                // `QuranData.quran` belongs to the main thread, which reassigns it at load and on a
                // qiraah change, and copying it here raced that write (the suspected source of the
                // 2026-09-21 heap corruption, Quality Guide C5). The snapshot is taken on main.
                DispatchQueue.main.async {
                    let surahs = QuranData.shared.quran
                    DispatchQueue.global(qos: .utility).async { loadOrBuildLexicon(surahs: surahs) }
                }
            }
        }
        return nil
    }

    /// The lexicon from disk when one applies: the file this build of the app wrote to Caches, else
    /// the one shipped in the bundle (Phase 10.17, built by the UnitTests export from these same texts
    /// and stamped with them), else a fresh build, which is then written to Caches for the next launch.
    /// Off-main.
    private static func loadOrBuildLexicon(surahs: [Surah]) {
        if let ready = LexiconCache.load() ?? LexiconCache.loadBundled() {
            lexiconLock.lock()
            if lexicon == nil { lexicon = ready }
            lexiconLock.unlock()
            // The build parsed the gloss pack as a side effect, and the per-ayah alignment the
            // search rows read (`englishTermsForArabicMatch`) parses it on the CALLER's thread when
            // nothing has: keep that table warm here too, off-main, so the first result row after a
            // cache hit finds it ready exactly as it did after a build.
            WordByWordStore.shared.prewarm()
            return
        }
        buildLexicon(surahs: surahs)
    }

    /// Start the lexicon build now (off-main, once), so the first hadith rows a query produces find it
    /// ready. Left to its lazy trigger, the build began on the FIRST ROW'S render and finished after
    /// that row was already on screen: the row's English line stayed unlit (the row never re-renders
    /// for the same query), which read as the cross-language highlight silently missing. The tabs call
    /// this once the Quran text is loaded; an early call before that is harmless (the build discards
    /// itself under `minimumLexiconEntries` and re-arms).
    static func prewarmLexicon() {
        let surahs = QuranData.shared.quran
        guard !surahs.isEmpty else { return }
        _ = lexiconIfReady(quranSnapshot: surahs)
    }

    /// The floor a real build clears by a wide margin (the shipping corpus yields ~17.8k keys).
    /// Anything under it means the inputs weren't there - Quran data still loading at launch, or the
    /// gloss pack unloaded mid-build by the word-by-word setting - so the result is DISCARDED and the
    /// build is re-armed rather than caching a crippled lexicon for the rest of the session.
    private static let minimumLexiconEntries = 1_000

    /// A key carrying more than this many distinct glosses is a grammatical particle (or a word as
    /// ubiquitous as الله), not a content word: highlighting it would paint noise across every row.
    /// Measured against the shipping data this drops ~24 keys and nothing else. (Allah's names have
    /// their own dedicated highlight setting, so losing that key here costs nothing.)
    private static let glossNoiseCap = 12

    private static func buildLexicon(surahs: [Surah]) {
        #if DEBUG
        let started = DispatchTime.now().uptimeNanoseconds
        #endif
        let table = makeLexicon(surahs: surahs)

        lexiconLock.lock()
        let accepted = table.count >= minimumLexiconEntries
        if accepted {
            lexicon = table
        } else {
            lexiconBuildStarted = false
        }
        lexiconLock.unlock()
        #if DEBUG
        if RenderCounter.enabled {
            let ms = Double(DispatchTime.now().uptimeNanoseconds - started) / 1_000_000
            NSLog("LEXICON built %d keys %.1f ms %@", table.count, ms, accepted ? "accepted" : "discarded")
        }
        #endif
        if accepted { LexiconCache.save(table) }
    }

    /// The lexicon as a pure function of the texts and the gloss pack: what the export writes and what
    /// `buildLexicon` installs.
    private static func makeLexicon(surahs: [Surah]) -> [String: Set<String>] {
        var table: [String: Set<String>] = [:]
        table.reserveCapacity(24_000)
        // The three per-token steps are pure functions of their string, and the 77k tokens repeat
        // heavily (about one distinct spelled form in four, fewer glosses), so each distinct input is
        // folded once. The table that comes out is the same one the unmemoized loop produced.
        var keysByToken: [String: [String]] = [:]
        keysByToken.reserveCapacity(20_000)
        var wordsByGloss: [String: [String]] = [:]
        wordsByGloss.reserveCapacity(20_000)
        for surah in surahs {
            for ayah in surah.ayahs {
                guard let glosses = WordByWordStore.shared.glosses(surah: surah.id, ayah: ayah.id) else { continue }
                let tokens = WordTokens.tokens(in: ayah.textHafs.trimmingCharacters(in: .whitespacesAndNewlines))
                guard tokens.count == glosses.count else { continue }
                for (token, gloss) in zip(tokens, glosses) {
                    let words: [String]
                    if let memo = wordsByGloss[gloss] {
                        words = memo
                    } else {
                        words = contentWords(of: gloss)
                        wordsByGloss[gloss] = words
                    }
                    guard !words.isEmpty else { continue }
                    // Indexed under EVERY variant, exactly the set the lookups ask for, so a hadith's
                    // والصبر and the Quran's ٱلصَّبْر meet at the same key.
                    let keys: [String]
                    if let memo = keysByToken[token] {
                        keys = memo
                    } else {
                        keys = lookupKeys(for: HighlightedSnippet.normalizeForSearchText(token, trimWhitespace: true))
                        keysByToken[token] = keys
                    }
                    for key in keys {
                        table[key, default: []].formUnion(words)
                    }
                }
            }
        }
        return table.filter { $0.value.count <= glossNoiseCap }
    }

    #if DEBUG
    /// Test hooks (`LexiconCacheTests`): the cache file's encoder and decoder, round-tripped on a
    /// synthetic table so a format slip cannot ship a lexicon that differs from the built one.
    static func encodeLexiconForTests(_ table: [String: Set<String>]) -> Data {
        LexiconCache.encode(table, stamps: LexiconCache.currentStamps ?? LexiconCache.Stamps(quranFingerprint: 0, glossSize: 0, glossFingerprint: 0))
    }
    static func decodeLexiconForTests(_ data: Data) -> [String: Set<String>]? { LexiconCache.decode(data) }
    /// `PrecomputedPackTests`: a live build of the table, the shipped file's table (nil when it is
    /// missing or stamped with other texts), and the shipped file's bytes for a fresh export.
    static func buildLexiconTableForTests(surahs: [Surah]) -> [String: Set<String>] { makeLexicon(surahs: surahs) }
    static func bundledLexiconForTests() -> [String: Set<String>]? { LexiconCache.loadBundled() }
    static func exportLexiconForTests(_ table: [String: Set<String>]) -> Data? {
        LexiconCache.currentStamps.map { LexiconCache.encode(table, stamps: $0) }
    }
    #endif

    /// The built lexicon, kept in Caches between launches (Phase 10.11). Building it meant parsing the
    /// 2 MB gloss pack and folding 77k tokens, about 2 s of CPU after every reveal on the full tier;
    /// its inputs are two bundled files and this binary's code, none of which changes between
    /// launches of one build, so the result is written once and read back in a few milliseconds.
    /// The file name carries the signature of those inputs (the app executable's and both packs'
    /// size and date), so a new build, a rebuilt pack or a reinstalled app misses and rebuilds; a
    /// file that fails to decode, or decodes to fewer keys than a real build yields, is a miss too.
    private enum LexiconCache {
        private static let magic: UInt32 = 0x4C455831   // "LEX1"
        /// Bumped by hand when `makeLexicon`'s rules change: the Caches file of a hot-reloaded dev loop
        /// (a release build always changes the executable's date) and the SHIPPED file, which only its
        /// stamps and the equivalence test otherwise guard, are then refused.
        private static let format = 2

        /// What the shipped file was built from (Phase 10.17): quran.qpk's own fingerprint, and the
        /// size and content hash of the gloss pack. A file stamped with other texts is not used.
        struct Stamps: Equatable {
            let quranFingerprint: UInt64
            let glossSize: UInt32
            let glossFingerprint: UInt64
        }

        static let currentStamps: Stamps? = {
            guard let quran = VerseSearchPack.quranFingerprint, let glossURL = WordByWordStore.bundledPackURL,
                  let gloss = try? Data(contentsOf: glossURL, options: .mappedIfSafe) else { return nil }
            return Stamps(quranFingerprint: quran, glossSize: UInt32(truncatingIfNeeded: gloss.count),
                          glossFingerprint: VerseSearchPack.fnv1a(gloss))
        }()

        private static func bundledURL() -> URL? {
            Bundle.main.url(forResource: "CrossLanguageLexicon", withExtension: "bin", subdirectory: "Quran")
                ?? Bundle.main.url(forResource: "CrossLanguageLexicon", withExtension: "bin", subdirectory: "Data/Quran")
                ?? Bundle.main.url(forResource: "CrossLanguageLexicon", withExtension: "bin")
        }

        /// The lexicon shipped in the bundle, when its stamps are this bundle's texts.
        static func loadBundled() -> [String: Set<String>]? {
            guard let url = bundledURL(), let data = try? Data(contentsOf: url, options: .mappedIfSafe),
                  let expected = currentStamps, stamps(in: data) == expected else { return nil }
            #if DEBUG
            let started = DispatchTime.now().uptimeNanoseconds
            #endif
            guard let table = decode(data), table.count >= minimumLexiconEntries else { return nil }
            #if DEBUG
            if RenderCounter.enabled {
                let ms = Double(DispatchTime.now().uptimeNanoseconds - started) / 1_000_000
                NSLog("LEXICON bundled %d keys %d KB %.1f ms", table.count, data.count / 1024, ms)
            }
            #endif
            return table
        }

        private static func stamp(_ url: URL?) -> String? {
            guard let url, let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attributes[.size] as? NSNumber,
                  let date = attributes[.modificationDate] as? Date else { return nil }
            return "\(size.int64Value)-\(Int64(date.timeIntervalSince1970))"
        }

        private static func fileURL() -> URL? {
            guard let app = stamp(Bundle.main.executableURL),
                  let gloss = stamp(WordByWordStore.bundledPackURL),
                  let quran = stamp(QuranPackLoader.url("quran")),
                  let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            else { return nil }
            let directory = caches.appendingPathComponent("CrossLanguageLexicon", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory.appendingPathComponent("lexicon-v\(format)-\(app)-\(gloss)-\(quran).bin")
        }

        static func load() -> [String: Set<String>]? {
            guard let url = fileURL(), let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
            #if DEBUG
            let started = DispatchTime.now().uptimeNanoseconds
            #endif
            guard let table = decode(data), table.count >= minimumLexiconEntries else {
                try? FileManager.default.removeItem(at: url)
                return nil
            }
            #if DEBUG
            if RenderCounter.enabled {
                let ms = Double(DispatchTime.now().uptimeNanoseconds - started) / 1_000_000
                NSLog("LEXICON cache hit %d keys %d KB %.1f ms", table.count, data.count / 1024, ms)
            }
            #endif
            return table
        }

        static func save(_ table: [String: Set<String>]) {
            guard let url = fileURL(), let stamps = currentStamps else { return }
            // Older builds' files are dead weight: the signature in the name never matches again.
            let directory = url.deletingLastPathComponent()
            if let siblings = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
                for sibling in siblings where sibling.lastPathComponent != url.lastPathComponent {
                    try? FileManager.default.removeItem(at: sibling)
                }
            }
            try? encode(table, stamps: stamps).write(to: url, options: .atomic)
        }

        // [magic][format][quran fingerprint u64][gloss size u32][gloss fingerprint u64][key count] then
        // per key: [u16 key bytes][key][u8 word count] per word: [u8 word bytes][word]. Keys are folded
        // Arabic (a few dozen bytes), words are gloss content words (ASCII); anything that does not fit
        // the width is a build change and fails the write.
        static func encode(_ table: [String: Set<String>], stamps: Stamps) -> Data {
            var data = Data()
            data.reserveCapacity(table.count * 48)
            func appendU32(_ value: UInt32) {
                withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
            }
            func appendU64(_ value: UInt64) {
                withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
            }
            appendU32(magic)
            appendU32(UInt32(format))
            appendU64(stamps.quranFingerprint)
            appendU32(stamps.glossSize)
            appendU64(stamps.glossFingerprint)
            appendU32(UInt32(table.count))
            // Sorted so the file is byte-stable for one table (Set iteration order is not).
            for key in table.keys.sorted() {
                let words = table[key]!.sorted()
                let keyBytes = Array(key.utf8)
                guard keyBytes.count <= Int(UInt16.max), words.count <= Int(UInt8.max) else { return Data() }
                data.append(UInt8(keyBytes.count & 0xFF))
                data.append(UInt8(keyBytes.count >> 8))
                data.append(contentsOf: keyBytes)
                data.append(UInt8(words.count))
                for word in words {
                    let wordBytes = Array(word.utf8)
                    guard wordBytes.count <= Int(UInt8.max) else { return Data() }
                    data.append(UInt8(wordBytes.count))
                    data.append(contentsOf: wordBytes)
                }
            }
            return data
        }

        /// The stamps a file carries, or nil when it is not a lexicon file of this format.
        static func stamps(in data: Data) -> Stamps? {
            guard data.count >= 32 else { return nil }
            var reader = QuranPackReader(data: data, cursor: 0)
            guard reader.u32() == Int(magic), reader.u32() == format else { return nil }
            let quran = reader.u64()
            let size = UInt32(truncatingIfNeeded: reader.u32())
            let gloss = reader.u64()
            return Stamps(quranFingerprint: quran, glossSize: size, glossFingerprint: gloss)
        }

        static func decode(_ data: Data) -> [String: Set<String>]? {
            return data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> [String: Set<String>]? in
                guard let base = raw.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return nil }
                let count = raw.count
                var cursor = 0
                func u32() -> UInt32? {
                    guard cursor + 4 <= count else { return nil }
                    defer { cursor += 4 }
                    return UInt32(base[cursor]) | UInt32(base[cursor + 1]) << 8
                        | UInt32(base[cursor + 2]) << 16 | UInt32(base[cursor + 3]) << 24
                }
                func string(_ length: Int) -> String? {
                    guard cursor + length <= count else { return nil }
                    defer { cursor += length }
                    return String(decoding: UnsafeBufferPointer(start: base + cursor, count: length), as: UTF8.self)
                }
                guard u32() == magic, u32() == UInt32(format) else { return nil }
                // The stamps (quran u64, gloss size u32, gloss u64): the callers that care read them
                // through `stamps(in:)`; the Caches file is validated by its name.
                guard u32() != nil, u32() != nil, u32() != nil, u32() != nil, u32() != nil, let keyCount = u32() else { return nil }
                var table: [String: Set<String>] = [:]
                // The count is read from the file: bounded by what the bytes can hold (a record is at
                // least 3 bytes), so a corrupt or truncated cache cannot reserve gigabytes first.
                table.reserveCapacity(min(Int(keyCount), count / 3))
                for _ in 0..<keyCount {
                    guard cursor + 2 <= count else { return nil }
                    let keyLength = Int(base[cursor]) | Int(base[cursor + 1]) << 8
                    cursor += 2
                    guard let key = string(keyLength), cursor < count else { return nil }
                    let wordCount = Int(base[cursor])
                    cursor += 1
                    var words = Set<String>()
                    words.reserveCapacity(wordCount)
                    for _ in 0..<wordCount {
                        guard cursor < count else { return nil }
                        let wordLength = Int(base[cursor])
                        cursor += 1
                        guard let word = string(wordLength) else { return nil }
                        words.insert(word)
                    }
                    table[key] = words
                }
                return cursor == count ? table : nil
            }
        }
    }

    /// Every key one folded Arabic word should be findable under: itself, plus the forms left after
    /// peeling PROCLITICS - the connectives و/ف, the prepositions ب/ل/ك, and the article ال (alone or
    /// after one of those). So a hadith's وَالصَّبْر and the Quran's ٱلصَّبْر meet at the same key.
    ///
    /// Deliberately NOT stripping enclitic pronouns (رحمته → رحمة): measured against the shipping
    /// corpus that conflation drags a possessor's gloss words in with the noun's, turning a clean
    /// رحمة → "mercy" into "mercy, Allah, Lord, bestowed". Precision wins - a word this misses simply
    /// highlights nothing, which is the correct failure for a feature that points at meaning.
    private static let minimumStemLength = 3

    private static func lookupKeys(for folded: String) -> [String] {
        var keys: [String] = []
        var seen = Set<String>()
        func add(_ candidate: String) {
            guard candidate.count >= 2, seen.insert(candidate).inserted else { return }
            keys.append(candidate)
        }

        add(folded)
        var stem = folded
        while let first = stem.first, "وفبلك".contains(first), stem.count - 1 >= minimumStemLength {
            stem.removeFirst()
            add(stem)
            if stem.hasPrefix("ال"), stem.count - 2 >= minimumStemLength {
                add(String(stem.dropFirst(2)))
            }
        }
        if folded.hasPrefix("ال"), folded.count - 2 >= minimumStemLength {
            add(String(folded.dropFirst(2)))
        }
        return keys
    }

    /// ARABIC query against a text with NO alignment data (hadith): the query words' Quran-lexicon
    /// gloss words. Run the result through `wordSpans(of:in:)` against the English text.
    static func englishTermsForUnalignedArabicQuery(_ query: String) -> [String] {
        guard query.containsArabicLetters else { return [] }
        let key = "lex-a→e\u{0000}\(query)" as NSString
        if let cached = termsCache.object(forKey: key) { return cached.terms }
        guard let lexicon = lexiconIfReady(quranSnapshot: QuranData.shared.quran) else { return [] }

        var terms: [String] = []
        var seen = Set<String>()
        let queryWords = HighlightedSnippet.normalizeForSearchText(query, trimWhitespace: true)
            .split(separator: " ").map(String.init).filter { $0.count >= 2 }
        for word in queryWords {
            // The enclitic-aware variants, not just the proclitic keys: a query typed as صلاتهم or
            // رحمته still reaches the noun's lexicon entry. Peeling happens on the QUERY side only -
            // the build stays unpeeled, so the possessor-noise problem this peel causes there can't occur.
            for lookupKey in arabicMatchVariants(of: word) {
                for gloss in lexicon[lookupKey] ?? [] where seen.insert(gloss).inserted {
                    terms.append(gloss)
                }
            }
        }
        termsCache.setObject(TermsEntry(terms), forKey: key)
        return terms
    }

    /// ENGLISH query against Arabic with NO alignment data (hadith): spans of the Arabic tokens whose
    /// Quran-lexicon gloss carries a query word. Feed to `extraHighlightRanges` on the Arabic line.
    static func arabicSpansForEnglishQuery(_ query: String, arabicText: String) -> [NSRange] {
        guard !query.containsArabicLetters, !arabicText.isEmpty else { return [] }
        let key = "lex-e→a\u{0000}\(query)\u{0000}\(arabicText.hashValue)" as NSString
        if let cached = spansCache.object(forKey: key) { return cached.spans }
        guard let lexicon = lexiconIfReady(quranSnapshot: QuranData.shared.quran) else { return [] }

        let queryTokens = HighlightedSnippet.normalizeForSearchText(query, trimWhitespace: true)
            .split(separator: " ").map(String.init)
            .filter { $0.count >= 3 && !stopwords.contains($0) }
        guard !queryTokens.isEmpty else {
            spansCache.setObject(SpansEntry([]), forKey: key)
            return []
        }

        var spans: [NSRange] = []
        let ns = arabicText as NSString
        for tokenRange in WordTokens.ranges(in: arabicText) {
            let folded = HighlightedSnippet.normalizeForSearchText(ns.substring(with: tokenRange), trimWhitespace: true)
            guard folded.count >= 2 else { continue }
            var glossWords = Set<String>()
            // Enclitic-aware on the TEXT side too, so رحمته in a hadith reaches رحمة's entry.
            for lookupKey in arabicMatchVariants(of: folded) {
                glossWords.formUnion(lexicon[lookupKey] ?? [])
            }
            guard !glossWords.isEmpty else { continue }
            if queryTokens.contains(where: { q in glossWords.contains { wordMatches(query: q, word: $0) } }) {
                spans.append(tokenRange)
            }
        }
        spansCache.setObject(SpansEntry(spans), forKey: key)
        return spans
    }

    /// The gloss minus its "(...)" glue inserts, split to content words. "(is) the book" → ["book"].
    private static func contentWords(of gloss: String) -> [String] {
        var text = gloss
        while let open = text.firstIndex(of: "("), let close = text[open...].firstIndex(of: ")") {
            text.removeSubrange(open...close)
        }
        return text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !stopwords.contains($0) }
    }

    // MARK: Arabic morphology (per-ayah matching)

    /// One layer of enclitic pronoun / plural / verbal endings, longest first. Peeled only for MATCHING
    /// a query word against a token whose own gloss is then used - never on the lexicon build, where the
    /// same peel measurably drags a possessor's gloss in with the noun's. The plural morphemes (ون ين ات)
    /// and the verbal تم are what let الصبر meet ٱلصَّٰبِرِينَ and أخذ meet أَخَذتُم; every peel leaves ≥3 letters.
    private static let encliticSuffixes = [
        "كموها", "كموه", "هما", "كما", "كم", "كن", "هم", "هن", "ها", "نا",
        "ون", "ين", "ات", "تم", "وا", "ه", "ك", "ي",
    ]

    /// Every folded form a word should be comparable under: itself, its proclitic-peeled forms
    /// (و ف ب ل ك + ال - `lookupKeys`), and each of those with ONE enclitic layer peeled
    /// (صلاتهم → صلاته? no - صلاتهم → صلات; قالوا → قال). Minimum 3 letters survive any peel.
    static func arabicMatchVariants(of folded: String) -> [String] {
        var out: [String] = []
        var seen = Set<String>()
        func add(_ candidate: String) {
            guard candidate.count >= 2, seen.insert(candidate).inserted else { return }
            out.append(candidate)
        }
        func addWithTaTwins(_ candidate: String) {
            add(candidate)
            // The taa marbuta reappears as a plain taa before a suffix (صلاتهم = صلاة + هم), and the
            // feminine past verb ends in a plain taa (ضاقت = ضاق + ت) - keep the stripped form and
            // the ة-restored twin so any of the three spellings meets the query.
            if candidate.hasSuffix("ت"), candidate.count - 1 >= 3 {
                let stripped = String(candidate.dropLast())
                add(stripped)
                add(stripped + "ة")
            }
        }
        for base in lookupKeys(for: folded) {
            addWithTaTwins(base)
            for suffix in encliticSuffixes
            where base.hasSuffix(suffix) && base.count - suffix.count >= 3 {
                addWithTaTwins(String(base.dropLast(suffix.count)))
                break   // longest suffix only - one layer
            }
        }
        return out
    }

    /// The word minus its long vowel letters (ا و ي) - the loosest comparable form, only trusted at
    /// ≥3 letters so short roots can't collide (قوم/قيم both skeleton to قم and are correctly refused).
    private static func vowelSkeleton(_ word: String) -> String {
        word.filter { $0 != "ا" && $0 != "و" && $0 != "ي" && $0 != "ى" }
    }

    /// Whether two folded Arabic words are the same word for highlighting purposes: any variant pair
    /// equal, a ≥4-letter prefix of the other, equal once alef-stripped (الرحمن/الرحمان), or equal on
    /// the ≥3-letter vowel skeleton (قلب/قلوب, يعلمون/تعلمون stays apart on its lead letter).
    static func arabicWordsMatch(_ a: String, _ b: String) -> Bool {
        let variantsA = arabicMatchVariants(of: a)
        let variantsB = arabicMatchVariants(of: b)
        for va in variantsA {
            for vb in variantsB {
                if va == vb { return true }
                if va.count >= 4, vb.hasPrefix(va) { return true }
                if vb.count >= 4, va.hasPrefix(vb) { return true }
                let alefA = va.filter { $0 != "ا" }
                let alefB = vb.filter { $0 != "ا" }
                if alefA.count >= 3, alefA == alefB { return true }
                let skeletonA = vowelSkeleton(va)
                let skeletonB = vowelSkeleton(vb)
                if skeletonA.count >= 3, skeletonA == skeletonB { return true }
            }
        }
        return false
    }

    // MARK: English morphology

    /// One layer of English inflection, longest first, with a ≥3-letter stem guard - enough for the
    /// gloss↔translation drift that actually occurs (believe/believers, mercy/mercies, pray/prayers).
    private static func englishStem(_ word: String) -> String {
        for suffix in ["ingly", "fully", "ings", "ers", "ies", "ing", "est", "ed", "er", "ly", "es", "s"]
        where word.hasSuffix(suffix) && word.count - suffix.count >= 3 {
            var stem = String(word.dropLast(suffix.count))
            // "mercies" → "merc" + trailing i-restore → "mercy"; "carried" → "carri" → "carry".
            if stem.hasSuffix("i") { stem = String(stem.dropLast()) + "y" }
            return stem
        }
        return word
    }

    /// Word-to-word tolerance: equal, one a prefix of the other (≥3), the same after one inflection
    /// layer, or a shared stem long enough to be the same word family ("mercy" → "merciful").
    private static func wordMatches(query: String, word: String) -> Bool {
        if pairMatches(query, word) { return true }
        let stemmedQuery = englishStem(query)
        let stemmedWord = englishStem(word)
        if (stemmedQuery != query || stemmedWord != word), pairMatches(stemmedQuery, stemmedWord) {
            return true
        }
        return false
    }

    private static func pairMatches(_ a: String, _ b: String) -> Bool {
        if a == b { return true }
        if a.count >= 3, b.hasPrefix(a) { return true }
        if b.count >= 3, a.hasPrefix(b) { return true }
        guard a.count >= 4, b.count >= 4 else { return false }
        let common = zip(a, b).prefix(while: { $0.0 == $0.1 }).count
        return common >= max(4, min(a.count, b.count) - 2)
    }

    /// The token span minus leading/trailing punctuation, so a highlight on "ease," stops at the "e".
    private static func trimmedWordSpan(_ span: NSRange, in ns: NSString) -> NSRange {
        var start = span.location
        var end = span.location + span.length
        let alnum = CharacterSet.alphanumerics
        while start < end {
            guard let scalar = Unicode.Scalar(ns.character(at: start)), !alnum.contains(scalar) else { break }
            start += 1
        }
        while end > start {
            guard let scalar = Unicode.Scalar(ns.character(at: end - 1)), !alnum.contains(scalar) else { break }
            end -= 1
        }
        return NSRange(location: start, length: end - start)
    }
}

// MARK: - The reader's word-tappable Arabic

/// The ayah's Arabic, rendered through TextKit so one word can be hit-tested and lit.
///
/// A SwiftUI `Text` cannot do this: it has no way to ask "which word is under this point". The mushaf
/// page reader already solved the same problem the same way (`MushafPageTextView`), and this is the
/// per-row twin of it - including the explicit container width, without which a non-scrolling
/// `UITextView` lays the whole ayah out on one infinitely-wide line.
struct WordByWordTextView: UIViewRepresentable {
    let attributed: NSAttributedString
    let wordRanges: [NSRange]
    let width: CGFloat
    /// The word whose meaning is showing, lit in the accent.
    var selectedWord: Int?
    var highlightColor: Color
    /// Taps that open a word - two in the reader rows, one on the ayah preview cards (see `WordByWordText`).
    var tapsRequired: Int = 2
    let onTapWord: (Int) -> Void

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = false
        view.isScrollEnabled = false
        // A line's last letter routinely overhangs its glyph advance with tashkeel ink; clipping would
        // shear those marks off at the container edge (same reasoning as the mushaf page view).
        view.clipsToBounds = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.adjustsFontForContentSizeCategory = false
        view.textContainer.widthTracksTextView = false
        view.textContainer.size = CGSize(width: width, height: .greatestFiniteMagnitude)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        // Touch the TextKit-1 layout manager: hit-testing goes through it, and iOS 16+ would otherwise
        // default this view to TextKit 2, where `characterIndex(for:)` does not apply.
        _ = view.layoutManager

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        // TWO taps open a word, in list mode as in page mode (Abu, 2026-09-04: a single tap kept
        // opening cards by accident). The row's own single tap is not made to wait for this one,
        // so marking an ayah stays instant; a double tap marks it twice (a visual no-op) and then
        // opens the card, the same trade page mode makes (see `onDoubleTapWord`). The ayah preview
        // cards ask for ONE tap instead (Abu, 2026-09-05): there is no row tap to collide with.
        tap.numberOfTapsRequired = max(1, tapsRequired)
        // The coordinator needs the view before the recognizer can hit-test against it.
        context.coordinator.textView = view
        tap.delegate = context.coordinator
        view.addGestureRecognizer(tap)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.wordRanges = wordRanges
        context.coordinator.onTapWord = onTapWord

        // Reassigning `attributedText` is a full TextKit relayout, and this view's parent re-renders on
        // every settings/playback change - so only when something visible actually changed. The comparison
        // must be FULL attributed equality (attributes included), not a characters-only key: a font-size,
        // font-face, or tajweed/accent recolor keeps the exact same characters, and the old string-hash key
        // swallowed those - every VISIBLE ayah stayed on its old font until it scrolled off screen and was
        // rebuilt through `makeUIView` ("only the rows I can't see change" - user report). `isEqual(to:)`
        // still skips the relayout when a playback tick re-renders the parent with identical content.
        let selectionAndWidthUnchanged = context.coordinator.lastSelectedWord == (selectedWord ?? -1)
            && context.coordinator.lastWidth == width
        if selectionAndWidthUnchanged,
           let last = context.coordinator.lastAttributed,
           last === attributed || last.isEqual(to: attributed) {
            return
        }
        context.coordinator.lastAttributed = attributed
        context.coordinator.lastSelectedWord = selectedWord ?? -1
        context.coordinator.lastWidth = width

        view.textContainer.widthTracksTextView = false
        view.textContainer.size = CGSize(width: width, height: .greatestFiniteMagnitude)
        view.attributedText = lit(attributed)
        view.invalidateIntrinsicContentSize()
    }

    /// SwiftUI sizes a representable from `sizeThatFits`, and a `UITextView`'s own answer is its
    /// CURRENT bounds' fitting size - one line, before it has ever been given the real width. Answer
    /// with the text's laid-out height at the row width instead, or every ayah rendered through this
    /// view clips to its first line.
    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard width > 0 else { return nil }
        let fitting = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fitting.height))
    }

    /// The selected word's accent wash, painted on top rather than composed in: a background attribute
    /// changes no layout, so lighting a word re-measures nothing.
    private func lit(_ text: NSAttributedString) -> NSAttributedString {
        guard let selectedWord, wordRanges.indices.contains(selectedWord) else { return text }
        let range = wordRanges[selectedWord]
        guard range.location + range.length <= text.length else { return text }

        let mutable = NSMutableAttributedString(attributedString: text)
        mutable.addAttribute(
            .backgroundColor,
            value: UIColor(highlightColor).withAlphaComponent(0.22),
            range: range
        )
        return mutable
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var textView: UITextView?
        var wordRanges: [NSRange] = []
        var onTapWord: ((Int) -> Void)?
        /// The last content actually assigned to the view, for the update guard above. The un-lit
        /// original (not the `lit(_:)` copy), so selection changes compare against the right base.
        var lastAttributed: NSAttributedString?
        var lastSelectedWord = -1
        var lastWidth: CGFloat = 0

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let word = word(at: gesture.location(in: textView)) else { return }
            onTapWord?(word)
        }

        /// Which word is under `point`, or nil when the point isn't on one.
        private func word(at point: CGPoint) -> Int? {
            guard let textView, !wordRanges.isEmpty else { return nil }
            var location = point
            location.x -= textView.textContainerInset.left
            location.y -= textView.textContainerInset.top

            let layoutManager = textView.layoutManager
            let container = textView.textContainer
            let glyphIndex = layoutManager.glyphIndex(for: location, in: container)
            // `glyphIndex(for:)` returns the NEAREST glyph, so a tap in the empty run at the end of a
            // line would otherwise "hit" the last word on it. And the glyph's bounding rect spans the
            // whole LINE FRAGMENT, whose generous Arabic leading meant taps in the air between lines
            // still opened the word card ("a little too easy to tap" - user report). Accept only the
            // word's actual text band: the glyph's font line height, centered in its fragment.
            let bounds = layoutManager.boundingRect(
                forGlyphRange: NSRange(location: glyphIndex, length: 1),
                in: container
            )
            let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
            let glyphFont = (charIndex < textView.textStorage.length
                ? textView.textStorage.attribute(.font, at: charIndex, effectiveRange: nil) as? UIFont
                : nil) ?? textView.font
            let bandHeight = min(bounds.height, (glyphFont?.lineHeight ?? bounds.height) * 1.15)
            let band = CGRect(
                x: bounds.minX - 2,
                y: bounds.midY - bandHeight / 2,
                width: bounds.width + 4,
                height: bandHeight
            )
            guard band.contains(location) else { return nil }

            return WordTokens.index(of: charIndex, in: wordRanges)
        }

        /// Only claim taps that land ON a word. A tap anywhere else in the text block - the gaps at the
        /// end of a line, the margins - never begins, so it falls through to the row's own tap and still
        /// toggles the ayah highlight the way it does with this mode off.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            word(at: gestureRecognizer.location(in: textView)) != nil
        }

        /// The row's single tap is NOT made to wait for this double tap: with the recognizer at two
        /// taps, forcing the ancestor's tap to wait for it would delay every ayah mark by the
        /// double-tap timeout. So a double tap on a word marks the ayah twice (no visible change)
        /// and then opens the card, exactly as page mode's double tap does.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            false
        }
    }
}

/// One ayah's share of a `WordByWordText` run: its display text, its tajweed paint, its glosses and its
/// trailing number ornament. A reader row passes one; the ayah preview cards (page actions sheet, tafsir
/// sheet) pass one per ayah of a group, laid out as ONE continuous run with inline markers - the mushaf's
/// shape - and every word of every segment stays tappable.
struct WordByWordSegment {
    /// What the reader is showing - already clean-mode / dots-mode processed.
    let displayText: String
    /// Tajweed-colored version of `displayText`, when tajweed colors are on.
    let preStyled: AttributedString?
    let ayahNumberArabic: String
    let glosses: [String]
    /// Non-Hafs riwayat have no gloss pack, but their words still open the riwayah word card -
    /// every LETTERED token is tappable regardless of `glosses` (ornament-only tokens stay silent).
    var alwaysTappable: Bool = false
    /// "Highlight Allah" for this ayah: the app setting, or the ayah's own pin
    /// (`AyahDisplayOverride`) - and always OFF while a sheet's preview card is in plain text.
    ///
    /// NO DEFAULT, deliberately: it used to default to `true`, so any future segment built without
    /// passing the flag would have painted the name red even in plain text, which is exactly the
    /// bug plain text exists to prevent. Making it required means the compiler asks the question.
    var highlightAllahNames: Bool
    /// The active search term's matches (UTF-16 ranges into `displayText`), painted in the accent.
    /// Non-empty puts the run into its search look: the plain text under the accent spans, tajweed
    /// standing down exactly as it does in `HighlightedSnippet` - so a searched row keeps THIS
    /// renderer (and its geometry) instead of swapping to the one-Text snippet and back.
    var highlightRanges: [NSRange] = []
}

/// A word of a `WordByWordText` run: which segment (ayah) and which token of it.
struct WordByWordRef: Hashable {
    let segment: Int
    let index: Int
}

/// Builds the attributed ayah run (tajweed colors, the name الله, the trailing ayah ornaments) and hands it
/// to the text view above. Kept separate so the representable stays a dumb renderer.
struct WordByWordText: View {
    @ObservedObject private var settings = Settings.shared

    let segments: [WordByWordSegment]
    let fontName: String?
    let fontSize: CGFloat
    /// Taps that open a word: TWO in the reader rows (Abu, 2026-09-04: single taps opened cards by
    /// accident), ONE on the ayah preview cards (Abu, 2026-09-05: the card is there to be touched).
    var tapsRequired: Int = 2
    /// The word currently showing its card, lit in the accent.
    let selectedWord: WordByWordRef?
    let onSelectWord: (WordByWordRef) -> Void

    /// The single-ayah form the reader rows use.
    init(displayText: String, preStyled: AttributedString?, fontName: String?, fontSize: CGFloat,
         ayahNumberArabic: String, glosses: [String], alwaysTappable: Bool = false,
         highlightAllahNames: Bool, highlightRanges: [NSRange] = [], tapsRequired: Int = 2,
         selectedWord: Int?, onSelectWord: @escaping (Int) -> Void) {
        self.segments = [WordByWordSegment(
            displayText: displayText, preStyled: preStyled, ayahNumberArabic: ayahNumberArabic,
            glosses: glosses, alwaysTappable: alwaysTappable, highlightAllahNames: highlightAllahNames,
            highlightRanges: highlightRanges
        )]
        self.fontName = fontName
        self.fontSize = fontSize
        self.tapsRequired = tapsRequired
        self.selectedWord = selectedWord.map { WordByWordRef(segment: 0, index: $0) }
        self.onSelectWord = { onSelectWord($0.index) }
    }

    /// The multi-ayah form the preview cards use.
    init(segments: [WordByWordSegment], fontName: String?, fontSize: CGFloat, tapsRequired: Int = 2,
         selectedWord: WordByWordRef?, onSelectWord: @escaping (WordByWordRef) -> Void) {
        self.segments = segments
        self.fontName = fontName
        self.fontSize = fontSize
        self.tapsRequired = tapsRequired
        self.selectedWord = selectedWord
        self.onSelectWord = onSelectWord
    }

    /// The reader's content width. Seeded from the last measurement so only the very first row of a
    /// session has to wait for a layout pass to know it.
    @State private var width: CGFloat = WordByWordText.lastMeasuredWidth

    private static var lastMeasuredWidth: CGFloat = 0

    /// Where every segment's tokens sit in the concatenated run: `wordRanges` are UTF-16 ranges into the
    /// string `buildAttributedText` assembles (each segment's text, then " marker", then a joining space
    /// before the next), and `segmentStarts[i]` is the index of segment i's first token in it.
    private struct RunLayout {
        var wordRanges: [NSRange] = []
        var segmentStarts: [Int] = []
    }

    private var runLayout: RunLayout {
        var layout = RunLayout()
        var offset = 0
        for (i, segment) in segments.enumerated() {
            layout.segmentStarts.append(layout.wordRanges.count)
            for range in WordTokens.ranges(in: segment.displayText) {
                layout.wordRanges.append(NSRange(location: range.location + offset, length: range.length))
            }
            offset += (segment.displayText as NSString).length
                + (" \(segment.ayahNumberArabic)" as NSString).length
            if i < segments.count - 1 { offset += 1 }
        }
        return layout
    }

    private func globalIndex(of ref: WordByWordRef, in layout: RunLayout) -> Int? {
        guard layout.segmentStarts.indices.contains(ref.segment) else { return nil }
        return layout.segmentStarts[ref.segment] + ref.index
    }

    private func ref(ofGlobal index: Int, in layout: RunLayout) -> WordByWordRef? {
        guard let segment = layout.segmentStarts.lastIndex(where: { $0 <= index }) else { return nil }
        return WordByWordRef(segment: segment, index: index - layout.segmentStarts[segment])
    }

    var body: some View {
        // Until the width is known the text view would lay out on one endless line; the plain snippet
        // renders identically (it just isn't tappable), so the row never flashes an empty or wrong-height
        // block while measuring.
        Group {
            if width > 0 {
                let layout = runLayout
                WordByWordTextView(
                    attributed: attributedText(),
                    wordRanges: layout.wordRanges,
                    width: width,
                    selectedWord: selectedWord.flatMap { globalIndex(of: $0, in: layout) },
                    highlightColor: settings.accentColor.color,
                    tapsRequired: tapsRequired,
                    onTapWord: { index in
                        guard let ref = ref(ofGlobal: index, in: layout),
                              segments.indices.contains(ref.segment) else { return }
                        let segment = segments[ref.segment]
                        // A token with no gloss of its own (the ۞ mark, the tail of a merged word) has
                        // nothing to show - stay silent rather than open an empty card. In riwayah mode
                        // (no glosses exist at all) any token that carries letters opens the word card.
                        if segment.alwaysTappable {
                            let tokens = WordTokens.tokens(in: segment.displayText)
                            guard tokens.indices.contains(ref.index),
                                  !tokens[ref.index].removingArabicDiacriticsAndSigns
                                      .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        } else {
                            guard segment.glosses.indices.contains(ref.index),
                                  !segment.glosses[ref.index].isEmpty else { return }
                        }
                        settings.hapticFeedback()
                        onSelectWord(ref)
                    }
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                VStack(alignment: .trailing, spacing: 4) {
                    ForEach(segments.indices, id: \.self) { i in
                        HighlightedSnippet(
                            source: segments[i].displayText,
                            term: "",
                            font: swiftUIFont,
                            accent: settings.accentColor.color,
                            fg: .primary,
                            preStyledSource: segments[i].preStyled,
                            trailingSuffix: " \(segments[i].ayahNumberArabic)",
                            trailingSuffixFont: .custom(Settings.hafsUthmaniFontName, size: fontSize),
                            trailingSuffixColor: settings.accentColor.color,
                            highlightAllahNames: segments[i].highlightAllahNames
                        )
                        .arabicFontDesign(custom: true)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: WordByWordWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(WordByWordWidthKey.self) { measured in
            guard measured > 0, abs(measured - width) > 0.5 else { return }
            width = measured
            Self.lastMeasuredWidth = measured
        }
    }

    private var swiftUIFont: Font {
        if let fontName {
            return .custom(fontName, size: fontSize)
        }
        return .system(size: fontSize, design: .rounded)
    }

    private var uiFont: UIFont {
        if let fontName, let font = QuranFontCache.font(name: fontName, size: fontSize) {
            return font
        }
        return .roundedSystemFont(ofSize: fontSize)
    }

    /// The ayah as TextKit needs it: the same colors the list renders today, plus the ayah-number
    /// ornament, which always comes from the Uthmani face (the system font would print bare digits).
    private static let attributedMemo: NSCache<NSString, NSAttributedString> = {
        let cache = NSCache<NSString, NSAttributedString>()
        cache.countLimit = 200
        return cache
    }()

    /// Memoized per (texts, faces, colours, tajweed digests): the build ran on every body pass of every
    /// visible row, and the representable then compared the result attribute by attribute just to
    /// find nothing had changed (Phase 5 step 1).
    private func attributedText() -> NSAttributedString {
        var parts: [String] = [fontName ?? "", "\(fontSize)", "\(settings.accentColor.color)"]
        for segment in segments {
            parts.append(segment.displayText)
            parts.append(segment.ayahNumberArabic)
            parts.append(segment.highlightAllahNames ? "a" : "-")
            parts.append(segment.preStyled.map { "\($0.renderDigest)" } ?? "plain")
            parts.append(segment.highlightRanges.map { "\($0.location):\($0.length)" }.joined(separator: ","))
        }
        let key = parts.joined(separator: "\u{1F}") as NSString
        if let hit = Self.attributedMemo.object(forKey: key) { return hit }
        let built = buildAttributedText()
        Self.attributedMemo.setObject(built, forKey: key)
        return built
    }

    /// Assembles the run exactly as `runLayout` measures it: every segment's text, its " marker", and one
    /// joining space before the next segment.
    private func buildAttributedText() -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = fontName == nil ? .natural : .right
        paragraph.baseWritingDirection = .rightToLeft
        let markerFont = QuranFontCache.font(name: Settings.hafsUthmaniFontName, size: fontSize) ?? uiFont

        let run = NSMutableAttributedString()
        for (i, segment) in segments.enumerated() {
            let displayText = segment.displayText
            let body: NSMutableAttributedString
            // A pre-styled string whose characters don't match the display text (a mode the tajweed store
            // couldn't map) would shift every word range - fall back to the plain text rather than paint the
            // wrong word. A search match also takes the plain base: on a matched row the accent spans
            // win over tajweed, the priority `HighlightedSnippet` gives them.
            if segment.highlightRanges.isEmpty,
               let preStyled = segment.preStyled, String(preStyled.characters) == displayText {
                body = NSMutableAttributedString(attributedString: NSAttributedString(preStyled))
                // Tajweed colors are already UIColors on the string; only the font and paragraph go on top.
                body.addAttributes(
                    [.font: uiFont, .paragraphStyle: paragraph],
                    range: NSRange(location: 0, length: body.length)
                )
            } else {
                body = NSMutableAttributedString(
                    string: displayText,
                    attributes: [.font: uiFont, .foregroundColor: UIColor.label, .paragraphStyle: paragraph]
                )
            }

            if segment.highlightAllahNames {
                let ns = displayText as NSString
                for range in HighlightedSnippet.arabicAllahRanges(in: displayText) {
                    let utf16 = NSRange(range, in: displayText)
                    guard utf16.location + utf16.length <= ns.length else { continue }
                    body.addAttribute(.foregroundColor, value: UIColor.systemRed, range: utf16)
                }
            }

            // The search term's words in the accent - the one-Text snippet's paint, on this renderer.
            let textLength = (displayText as NSString).length
            let accent = UIColor(settings.accentColor.color)
            for range in segment.highlightRanges
            where range.location >= 0 && range.length > 0 && range.location + range.length <= textLength {
                body.addAttribute(.foregroundColor, value: accent, range: range)
            }

            body.append(NSAttributedString(
                string: " \(segment.ayahNumberArabic)",
                attributes: [
                    .font: markerFont,
                    .foregroundColor: UIColor(settings.accentColor.color),
                    .paragraphStyle: paragraph,
                ]
            ))
            if i < segments.count - 1 {
                body.append(NSAttributedString(
                    string: " ",
                    attributes: [.font: uiFont, .paragraphStyle: paragraph]
                ))
            }
            run.append(body)
        }
        return run
    }
}

private struct WordByWordWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - The inline study layout (meaning under every word)

/// "Show Meanings Under Words": the ayah laid out word by word, right to left, wrapping like text -
/// each word a small column with its English gloss directly beneath it, the way word-by-word study
/// mushafs print it. Same data, same colors, and the same tap (the word card) as `WordByWordText`;
/// only the geometry differs, so the two stay interchangeable behind the one setting.
/// The active search term as the study layout paints it: which Arabic tokens the term matched
/// (UTF-16 ranges into the display text, from the same ladder the one-Text snippet uses, plus the
/// cross-language spans), and the folded term itself, so a gloss or a transliteration that carries
/// it lights as well. While this is set the layout wears its search look: every line primary (the
/// transliteration's accent and the glosses' grey both stand down) and only the matched words - their
/// Arabic, their transliteration and their meaning - in the accent (Abu, 2026-09-05).
struct WordByWordSearchPaint: Equatable {
    var arabicRanges: [NSRange]
    var normalizedQuery: String
}

struct WordByWordInlineText: View {
    @ObservedObject private var settings = Settings.shared

    /// What the reader is showing - already clean-mode / dots-mode processed.
    let displayText: String
    /// Tajweed-colored version of `displayText`, when tajweed colors are on.
    let preStyled: AttributedString?
    let fontName: String?
    let fontSize: CGFloat
    let ayahNumberArabic: String
    let glosses: [String]
    /// "Highlight Allah" for this ayah: the app setting, or the ayah's own pin (`AyahDisplayOverride`).
    let highlightAllahNames: Bool
    /// Whether the gloss LINE is drawn. The glosses themselves always arrive: a word still opens its
    /// card on tap, and a word with no gloss still isn't tappable, whichever lines are showing.
    let showsGlosses: Bool
    /// Per-word transliteration, aligned with `glosses`. Empty when the pack could not line up, or
    /// when the reader has the study layout's transliteration line switched off.
    let transliterations: [String]
    /// The word currently showing its card, washed in the accent.
    let selectedWord: Int?
    /// Nil when "Tap a Word for Its Meaning" is off: the study layout still draws, its words just
    /// do not open a card (the two switches are independent).
    let onSelectWord: ((Int) -> Void)?
    /// The active search term's paint, nil when nothing is being searched (see the type).
    var searchPaint: WordByWordSearchPaint? = nil

    @State private var width: CGFloat = 0

    private struct WordCell: Identifiable {
        let id: Int
        let arabic: AttributedString
        let gloss: String
        let transliteration: String
        /// The search term landed on this word (its Arabic, its transliteration or its meaning).
        var isHit: Bool = false
        var isOrnament: Bool { id == -1 }
    }

    var body: some View {
        Group {
            if width > 0 {
                flow(containerWidth: width)
                    // Rows are pre-partitioned with measured widths; RTL layout makes each HStack
                    // lay its first word at the RIGHT edge, the mushaf's reading order.
                    .environment(\.layoutDirection, .rightToLeft)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                // Until the width is known, the plain one-Text rendering (identical content, not
                // tappable) keeps the row from flashing an empty block while measuring.
                HighlightedSnippet(
                    source: displayText,
                    term: "",
                    font: arabicSwiftUIFont,
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: preStyled,
                    trailingSuffix: " \(ayahNumberArabic)",
                    trailingSuffixFont: .custom(Settings.hafsUthmaniFontName, size: fontSize),
                    trailingSuffixColor: settings.accentColor.color,
                    highlightAllahNames: highlightAllahNames
                )
                .arabicFontDesign(custom: true)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: WordByWordWidthKey.self, value: proxy.size.width)
            }
        )
        .onPreferenceChange(WordByWordWidthKey.self) { measured in
            guard measured > 0, abs(measured - width) > 0.5 else { return }
            width = measured
        }
    }

    // MARK: Content

    private var arabicSwiftUIFont: Font {
        if let fontName { return .custom(fontName, size: fontSize) }
        return .system(size: fontSize, design: .rounded)
    }

    private var arabicUIFont: UIFont {
        if let fontName, let font = QuranFontCache.font(name: fontName, size: fontSize) { return font }
        return .roundedSystemFont(ofSize: fontSize)
    }

    /// One styled slice per token (plus the trailing ornament cell), colors carried per word. Sliced
    /// from ONE styled pass over the whole ayah so tajweed runs, the red الله, and any future paint
    /// stay identical to the flowing rendering.
    private var cells: [WordCell] {
        let base: NSMutableAttributedString
        // A pre-styled string whose characters don't match the display text (a mode the tajweed
        // store couldn't map) would shift every word range - fall back to plain rather than paint
        // the wrong word (same rule as `WordByWordText`). A search takes the plain base too: on a
        // matched row the accent wins over tajweed, as it does in the one-Text snippet.
        if searchPaint == nil, let preStyled, String(preStyled.characters) == displayText {
            base = NSMutableAttributedString(attributedString: NSAttributedString(preStyled))
        } else {
            base = NSMutableAttributedString(
                string: displayText,
                attributes: [.foregroundColor: UIColor.label]
            )
        }
        if highlightAllahNames {
            let ns = displayText as NSString
            for range in HighlightedSnippet.arabicAllahRanges(in: displayText) {
                let utf16 = NSRange(range, in: displayText)
                guard utf16.location + utf16.length <= ns.length else { continue }
                base.addAttribute(.foregroundColor, value: UIColor.systemRed, range: utf16)
            }
        }

        var out: [WordCell] = []
        let ranges = WordTokens.ranges(in: displayText)
        let accent = UIColor(settings.accentColor.color)
        out.reserveCapacity(ranges.count + 1)
        for (index, range) in ranges.enumerated() {
            guard range.location + range.length <= base.length else { continue }
            let gloss = glosses.indices.contains(index) ? glosses[index] : ""
            let transliteration = transliterations.indices.contains(index) ? transliterations[index] : ""
            let hit = isHit(tokenRange: range, gloss: gloss, transliteration: transliteration)
            // A matched word is painted whole (the ladder snaps its spans to whole words anyway).
            if hit { base.addAttribute(.foregroundColor, value: accent, range: range) }
            out.append(WordCell(
                id: index,
                arabic: AttributedString(base.attributedSubstring(from: range)),
                gloss: gloss,
                transliteration: transliteration,
                isHit: hit
            ))
        }
        out.append(WordCell(id: -1, arabic: AttributedString(ayahNumberArabic),
                            gloss: "", transliteration: ""))
        return out
    }

    /// Whether the search term landed on this word: its Arabic intersects a matched span, or - for a
    /// Latin query - its transliteration or its meaning carries the folded term (the same fold the
    /// snippet matches with, so "lawful" lights أُحِلَّ through its gloss "are made lawful").
    private func isHit(tokenRange: NSRange, gloss: String, transliteration: String) -> Bool {
        guard let paint = searchPaint else { return false }
        if paint.arabicRanges.contains(where: { NSIntersectionRange($0, tokenRange).length > 0 }) { return true }
        let query = paint.normalizedQuery
        guard !query.isEmpty, !query.containsArabicLetters else { return false }
        if !gloss.isEmpty,
           HighlightedSnippet.normalizeForSearchText(gloss, trimWhitespace: true).contains(query) { return true }
        if !transliteration.isEmpty,
           HighlightedSnippet.normalizeForSearchText(transliteration, trimWhitespace: true).contains(query) { return true }
        return false
    }

    // MARK: Geometry

    private var glossFontSize: CGFloat { max(11, min(14, fontSize * 0.32)) }
    /// The transliteration sits between the Arabic and its meaning, a shade smaller than the gloss:
    /// it is how to SAY the word, so it reads as a pronunciation note rather than as a second gloss.
    private var transliterationFontSize: CGFloat { max(10, glossFontSize - 1) }
    /// Widest a gloss may render; longer ones wrap to a second line, then truncate.
    private let glossMaxWidth: CGFloat = 110
    /// No padding inside a cell: the Arabic sits as close to its neighbours as the plain one-Text
    /// rendering puts it (the spacing the reader preferred, Abu 2026-09-05). The selected word's wash
    /// grows outward on its own instead (see `cellView`).
    private let cellHorizontalPadding: CGFloat = 0
    /// The gap between words is the face's own space glyph, the width a space takes in the plain
    /// rendering - so a run of words with short meanings under them reads exactly like flowing text.
    private var cellSpacing: CGFloat {
        max(3, ceil((" " as NSString).size(withAttributes: [.font: arabicUIFont]).width))
    }
    /// Rows of bare Arabic stack at the face's own line pitch, like the lines of a paragraph; rows
    /// carrying a transliteration or meaning line keep a small gap so one row's Latin never crowds
    /// the next row's marks.
    private var rowSpacing: CGFloat {
        let hasLatinLines = (showsGlosses && glosses.contains { !$0.isEmpty })
            || transliterations.contains { !$0.isEmpty }
        return hasLatinLines ? 6 : 0
    }

    private func cellView(_ cell: WordCell) -> some View {
        let selected = !cell.isOrnament && selectedWord == cell.id
        let accent = settings.accentColor.color
        // The search look: everything primary, the matched words alone in the accent - the
        // transliteration's accent and the glosses' grey are the READING look, not a highlight, and
        // they would drown the one word the search is pointing at.
        let searching = searchPaint != nil
        let transliterationColor: Color = searching ? (cell.isHit ? accent : .primary) : accent
        let glossColor: Color = searching ? (cell.isHit ? accent : .primary) : .secondary
        return VStack(spacing: 2) {
            Text(cell.arabic)
                .font(cell.isOrnament ? .custom(Settings.hafsUthmaniFontName, size: fontSize) : arabicSwiftUIFont)
                .foregroundColor(cell.isOrnament ? accent : nil)
                .arabicFontDesign(custom: true)
                .lineLimit(1)
                .fixedSize()
            if !cell.transliteration.isEmpty {
                Text(cell.transliteration)
                    .font(.system(size: transliterationFontSize).italic())
                    .foregroundColor(transliterationColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: glossMaxWidth)
                    .environment(\.layoutDirection, .leftToRight)
            }
            if showsGlosses, !cell.gloss.isEmpty {
                Text(cell.gloss)
                    .font(.system(size: glossFontSize))
                    .foregroundColor(glossColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: glossMaxWidth)
                    .fixedSize(horizontal: false, vertical: true)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .padding(.horizontal, cellHorizontalPadding)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(selected ? accent.opacity(0.18) : Color.clear)
                // The wash reaches 3pt past the glyphs on each side, the room the cell padding used
                // to give it, without spreading the words themselves.
                .padding(.horizontal, -3)
        )
        .contentShape(Rectangle())
        // Two taps, like every word in the app (Abu, 2026-09-04).
        .onTapGesture(count: 2) {
            // A token with no gloss of its own (the ۞ mark, the tail of a merged word) has nothing
            // to show - stay silent rather than open an empty card.
            guard let onSelectWord, !cell.isOrnament, !cell.gloss.isEmpty else { return }
            settings.hapticFeedback()
            onSelectWord(cell.id)
        }
    }

    /// A cell's rendered width, measured with the SAME fonts the cell view uses - so rows can be
    /// partitioned deterministically in plain code (no alignment-guide layout tricks, which proved
    /// unreliable under RTL inside a List).
    private func cellWidth(_ cell: WordCell) -> CGFloat {
        let font = cell.isOrnament
            ? (QuranFontCache.font(name: Settings.hafsUthmaniFontName, size: fontSize) ?? arabicUIFont)
            : arabicUIFont
        let arabicWidth = ceil((String(cell.arabic.characters) as NSString)
            .size(withAttributes: [.font: font]).width)
        var glossWidth: CGFloat = 0
        if showsGlosses, !cell.gloss.isEmpty {
            glossWidth = min(glossMaxWidth, ceil((cell.gloss as NSString)
                .size(withAttributes: [.font: UIFont.systemFont(ofSize: glossFontSize)]).width))
        }
        // The transliteration renders on ONE line with a minimum scale, so it never widens the cell
        // past the gloss cap - but a short gloss under a long transliteration still needs the room.
        var latinWidth: CGFloat = 0
        if !cell.transliteration.isEmpty {
            latinWidth = min(glossMaxWidth, ceil((cell.transliteration as NSString)
                .size(withAttributes: [.font: UIFont.italicSystemFont(ofSize: transliterationFontSize)]).width))
        }
        return max(arabicWidth, max(glossWidth, latinWidth)) + cellHorizontalPadding * 2
    }

    /// Rows of cell indices, greedily filled in reading order against the measured widths.
    private func partitionedRows(containerWidth: CGFloat) -> [[WordCell]] {
        var rows: [[WordCell]] = []
        var row: [WordCell] = []
        var used: CGFloat = 0
        for cell in cells {
            let width = cellWidth(cell)
            if !row.isEmpty, used + cellSpacing + width > containerWidth - 2 {
                rows.append(row)
                row = []
                used = 0
            }
            used += (row.isEmpty ? 0 : cellSpacing) + width
            row.append(cell)
        }
        if !row.isEmpty { rows.append(row) }
        return rows
    }

    private func flow(containerWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(Array(partitionedRows(containerWidth: containerWidth).enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: cellSpacing) {
                    ForEach(row) { cell in
                        cellView(cell)
                    }
                }
            }
        }
        // `.leading` under the RTL environment = the right edge, where the first word belongs.
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - The card

/// The word a reader tapped, resolved: which token it was, its text, its meaning, and how many words the
/// ayah has. Identified by index so tapping a second word while the first card is up re-presents the
/// sheet with the new word instead of leaving the old one on screen.
/// The word itself, drag-selectable.
///
/// `Text(...).textSelection(.enabled)` gives at best a long-press that copies the WHOLE block, and the
/// reason a reader opens this card is usually to pick out ONE letter - the hamzah, the shaddah'd
/// consonant, the letter this riwayah spells differently. So the word and the letter-by-letter line
/// both draw through the same read-only `UITextView` the app's prose surfaces use, where a drag
/// highlights any run of it and the standard Copy/Look Up/Share menu applies to exactly that run.
/// Tajweed colors survive: the styled string's own attributes are kept and only the font and
/// paragraph style are layered on top.
private struct SelectableWordText: View {
    let styled: AttributedString?
    let plain: String
    let font: UIFont
    var lineSpacing: CGFloat = 2

    private var attributed: NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.baseWritingDirection = .rightToLeft
        paragraph.lineSpacing = lineSpacing
        let ns = styled.map { NSMutableAttributedString(attributedString: NSAttributedString($0)) }
            ?? NSMutableAttributedString(string: plain)
        let all = NSRange(location: 0, length: ns.length)
        ns.addAttributes([.font: font, .paragraphStyle: paragraph], range: all)
        // Only where the styling left it unset - a tajweed color must win over the default label color.
        ns.enumerateAttribute(.foregroundColor, in: all) { value, range, _ in
            if value == nil { ns.addAttribute(.foregroundColor, value: UIColor.label, range: range) }
        }
        return ns
    }

    var body: some View {
        SelectableTextView(attributed: attributed)
            .frame(maxWidth: .infinity)
    }
}

struct TappedWord: Identifiable, Equatable {
    let index: Int
    let word: String
    let meaning: String
    let total: Int

    var id: Int { index }
}

/// `String.beginnerSpaced`, for a STYLED word: every grapheme cluster re-joined with a plain space,
/// each keeping the exact attributes painted on it - so the letter-by-letter line below shows the
/// same tajweed colors the word above carries.
private func beginnerSpacedStyled(_ styled: AttributedString) -> AttributedString {
    let ns = NSAttributedString(styled)
    let full = ns.string as NSString
    let out = NSMutableAttributedString()
    var index = 0
    while index < full.length {
        let cluster = full.rangeOfComposedCharacterSequence(at: index)
        if out.length > 0 {
            // The space inherits the cluster's attributes (minus any wash) so the gap scales with
            // the letter it follows.
            var attrs = ns.attributes(at: cluster.location, effectiveRange: nil)
            attrs.removeValue(forKey: .backgroundColor)
            out.append(NSAttributedString(string: " ", attributes: attrs))
        }
        out.append(ns.attributedSubstring(from: cluster))
        index = NSMaxRange(cluster)
    }
    return AttributedString(out)
}

/// The beginner block at the BOTTOM of both word cards (user rule: "add a beginner arabic mode option
/// at the bottom showing each letter"): the exact same word - same tajweed colors, same face - just
/// with a space between every letter, so a beginner can read it letter by letter.
private struct BeginnerLettersSection: View {
    let styled: AttributedString?
    let word: String
    let fontName: String
    let fontSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.bottom, 4)
            Text("BEGINNER MODE - LETTER BY LETTER")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            SelectableWordText(
                styled: styled.map(beginnerSpacedStyled),
                plain: word.beginnerSpaced,
                font: UIFont(name: fontName, size: fontSize) ?? .roundedSystemFont(ofSize: fontSize),
                lineSpacing: 6
            )
        }
        .padding(.top, 4)
    }
}

// MARK: - The same word across the riwayat

/// One spelling of a tapped word, and every riwayah that prints it that way. Riwayat are GROUPED
/// by identical spelling on purpose: most words read the same in most riwayat, and twenty identical
/// rows would bury the one or two that actually differ.
private struct WordRiwayahReading: Identifiable {
    let word: String
    let options: [Settings.Riwayah.Option]
    /// True for the reading the card was opened in - its row (and its qiraah's cell) gets the
    /// accent-tinted background.
    let includesCurrent: Bool
    /// True when this spelling is not what Hafs prints for the same word - the word itself wears
    /// the accent wherever it is shown (Abu, 2026-09-07: "every time you show the word color
    /// different from hafs no matter where"). The Hafs baseline, not the reader's riwayah: that is
    /// the reference every reader knows, and the one the khilaf coloring in the prints uses too.
    let differsFromHafs: Bool

    var id: String { (options.first?.tag ?? "") + "|" + word }

    /// "Hafs an Asim · Warsh an Nafi (Beta)" - every riwayah sharing this spelling. The Hafs label
    /// drops its "(default)" here: this list is about who reads what, not about which is selected.
    var names: String {
        options.map { option in
            let label = option.tag.isEmpty ? "Hafs an Asim" : option.label
            return option.beta ? "\(label) (Beta)" : label
        }
        .joined(separator: " · ")
    }

    /// "Warsh · Qalun" - the rawis' own names without the "an <imam>" tail, for the by-qiraah grid
    /// whose cell header already says which imam these are.
    var rawiNames: String {
        options.map { option in
            let label = option.tag.isEmpty ? "Hafs an Asim" : option.label
            guard let cut = label.range(of: " an ") else { return label }
            return String(label[..<cut.lowerBound])
        }
        .joined(separator: " · ")
    }
}

/// One qiraah's cell in the by-qiraah grid: the imam, and what his two rawis print. A qiraah is
/// wholly beta or wholly not (the twelve beta riwayat are the two rawis each of six qiraat), so the
/// "(Beta)" marker belongs on the cell rather than on every name inside it.
private struct WordQiraahCell: Identifiable {
    let teacher: String
    let teacherArabic: String
    let isBeta: Bool
    let readings: [WordRiwayahReading]

    var id: String { teacher }

    /// True when the card was opened in one of this qiraah's riwayat - the cell gets the accent tint.
    var isCurrent: Bool { readings.contains(where: \.includesCurrent) }
}

/// Maps ONE tapped word onto its counterpart in every other riwayah, pivoting through Hafs: the
/// tapped ayah is aligned to the Hafs ayah(s) it spans (`QiraahComparison`), the word is located in
/// those Hafs words by a token-level LCS over letter skeletons, and each riwayah's own text for the
/// same Hafs span is then walked back the other way. Going through Hafs (rather than riwayah to
/// riwayah directly) means one alignment per riwayah instead of one per pair.
// Not main-actor bound: the word card runs it detached. What it reads is thread-safe: QuranData's
// lookups are published under a lock, the comparison's caches sit behind its own (Quality Guide C5).
private enum WordAcrossRiwayat {
    /// The shared rasm skeleton (`QiraahComparison.wordSkeleton`): marks off, hamza seats and
    /// dotless letters folded, so spelling differences never break the word matching.
    static func skeleton(_ token: String) -> String { QiraahComparison.wordSkeleton(token) }

    /// Every (source, target) token pair that lines up, by LCS over the skeletons. Ayahs are small
    /// (at most a few dozen words), so the full table is cheap.
    private static func matches(_ source: [String], _ target: [String]) -> [(source: Int, target: Int)] {
        let a = source.map(skeleton)
        let b = target.map(skeleton)
        guard !a.isEmpty, !b.isEmpty else { return [] }

        var lcs = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in stride(from: a.count - 1, through: 0, by: -1) {
            for j in stride(from: b.count - 1, through: 0, by: -1) {
                lcs[i][j] = a[i] == b[j] ? lcs[i + 1][j + 1] + 1 : max(lcs[i + 1][j], lcs[i][j + 1])
            }
        }
        var out: [(source: Int, target: Int)] = []
        var i = 0, j = 0
        while i < a.count, j < b.count {
            if a[i] == b[j], lcs[i][j] == lcs[i + 1][j + 1] + 1 {
                out.append((i, j)); i += 1; j += 1
            } else if lcs[i + 1][j] >= lcs[i][j + 1] {
                i += 1
            } else {
                j += 1
            }
        }
        return out
    }

    /// The `target` tokens that `range` of `source` corresponds to. A matched word maps straight
    /// across; an unmatched one (spelled differently, merged, or dropped in this reading) maps to
    /// whatever sits BETWEEN its nearest matched neighbours - possibly several words, possibly none.
    private static func counterpart(of range: Range<Int>, source: [String], target: [String]) -> Range<Int>? {
        guard !target.isEmpty else { return nil }
        let pairs = matches(source, target)
        // Two texts of the same ayah always share most of their words. Sharing NONE means these
        // are different ayahs, and the between-the-neighbours fallback below would hand back the
        // whole verse as if it were one word's counterpart - say nothing instead.
        guard !pairs.isEmpty else { return nil }
        let inside = pairs.filter { range.contains($0.source) }
        if let first = inside.first, let last = inside.last {
            return first.target..<(last.target + 1)
        }
        let lo = pairs.last(where: { $0.source < range.lowerBound }).map { $0.target + 1 } ?? 0
        let hi = pairs.first(where: { $0.source >= range.upperBound }).map(\.target) ?? target.count
        return lo < hi ? lo..<hi : nil
    }

    private static func hafsTokens(surah: Int, span: ClosedRange<Int>) -> [String] {
        var out: [String] = []
        for n in span {
            guard let hafsAyah = QuranData.shared.ayah(surah: surah, ayah: n) else { continue }
            out.append(contentsOf: WordTokens.tokens(
                in: hafsAyah.rawArabicText(surahId: surah, qiraahOverride: "")
            ))
        }
        return out
    }

    /// Everything both word cards ask about a tapped word, resolved once: the Hafs ayah(s) the
    /// tapped ayah spans, their words, and where the tapped word sits among them.
    struct Context {
        let surah: Int
        /// The tapped ayah's number in the READER's riwayah (not necessarily its Hafs number).
        let ayahNumber: Int
        /// Canonical riwayah tag the word was tapped in ("" = Hafs).
        let tag: String
        let hafsSpan: ClosedRange<Int>
        let hafsTokens: [String]
        /// Nil when the word has no counterpart in Hafs at all.
        let hafsRange: Range<Int>?
    }

    static func context(surah: Int, ayahNumber: Int, tag: String,
                        tokenIndex: Int, sourceTokens: [String]) -> Context? {
        let canonical = Settings.Riwayah.canonicalTag(tag)
        let quranData = QuranData.shared
        // The same ayah alignment the qiraah comparison sheet rows use - one truth for both.
        let span: ClosedRange<Int> = canonical.isEmpty
            ? ayahNumber...ayahNumber
            : (QiraahComparison.alignment(surahID: surah, tag: canonical, quranData: quranData)?
                .hafsRangeForRiwayah[ayahNumber] ?? ayahNumber...ayahNumber)
        let hafsTokens = self.hafsTokens(surah: surah, span: span)
        guard !hafsTokens.isEmpty else { return nil }

        // Tapped in Hafs itself: the source words ARE the Hafs words, so no matching is needed.
        let hafsRange: Range<Int>? = canonical.isEmpty
            ? (tokenIndex < hafsTokens.count ? tokenIndex..<(tokenIndex + 1) : nil)
            : counterpart(of: tokenIndex..<(tokenIndex + 1), source: sourceTokens, target: hafsTokens)

        return Context(surah: surah, ayahNumber: ayahNumber, tag: canonical,
                       hafsSpan: span, hafsTokens: hafsTokens, hafsRange: hafsRange)
    }

    /// The Hafs word(s) the tapped word corresponds to - possibly several (a word Hafs splits),
    /// nil when this reading's word has no counterpart there at all.
    static func hafsCounterpart(_ context: Context) -> String? {
        guard let range = context.hafsRange else { return nil }
        let joined = context.hafsTokens[range].joined(separator: " ")
        return joined.isEmpty ? nil : joined
    }

    /// The tapped word as every riwayah prints it, one entry per riwayah, in the qiraat's own order.
    ///
    /// Only riwayat whose TEXT may render: the beta twelve stay out until their text is unlocked,
    /// so nothing here is a silent Hafs stand-in.
    static func spellings(_ context: Context, word: String)
        -> [(option: Settings.Riwayah.Option, spelling: String)] {
        guard let hafsRange = context.hafsRange else { return [] }

        var options = Settings.Riwayah.textOptions
        if !options.contains(where: { Settings.Riwayah.canonicalTag($0.tag) == context.tag }) {
            // The one being read is always included - but never a BETA riwayah while beta text is
            // locked. Its text cannot be on screen in that state, so this would be the one place
            // a locked riwayah leaked into the card.
            let current = Settings.Riwayah.option(for: context.tag)
            if !current.beta || Settings.shared.betaQiraatEnabled { options.append(current) }
        }
        options.sort { $0.order < $1.order }

        var out: [(option: Settings.Riwayah.Option, spelling: String)] = []
        for option in options {
            let canonical = Settings.Riwayah.canonicalTag(option.tag)
            let spelling: String?
            if canonical == context.tag {
                // The word already on screen - no round trip through the alignment for it.
                spelling = word.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if canonical.isEmpty {
                spelling = context.hafsTokens[hafsRange].joined(separator: " ")
            } else {
                let target = tokens(context: context, optionTag: canonical)
                spelling = counterpart(of: hafsRange, source: context.hafsTokens, target: target)
                    .map { target[$0].joined(separator: " ") }
            }
            guard let spelling, !spelling.isEmpty else { continue }
            out.append((option, spelling))
        }
        return out
    }

    /// The tapped word grouped by spelling, in the qiraat's own order.
    static func readings(_ context: Context, word: String) -> [WordRiwayahReading] {
        group(spellings(context, word: word), currentTag: context.tag, hafsSpelling: hafsCounterpart(context))
    }

    /// One cell per QIRAAH, in the classical order of the Ten, each carrying what its two rawis
    /// print. Grouped inside the cell as well, so the usual case - both rawis agreeing - is one
    /// word with both names under it rather than the same word twice.
    static func byQiraah(_ context: Context, word: String) -> [WordQiraahCell] {
        let pairs = spellings(context, word: word)
        let hafs = hafsCounterpart(context)
        return Settings.Riwayah.teacherOrder.compactMap { teacher in
            let mine = pairs.filter { $0.option.teacher == teacher }
            guard let first = mine.first else { return nil }
            return WordQiraahCell(teacher: teacher,
                                  teacherArabic: first.option.teacherArabic,
                                  isBeta: mine.allSatisfy { $0.option.beta },
                                  readings: group(mine, currentTag: context.tag, hafsSpelling: hafs))
        }
    }

    /// Collapse per-riwayah spellings into one entry per distinct spelling, first-seen order kept.
    /// `hafsSpelling` is the Hafs word(s) for the same span (nil when Hafs has no counterpart, in
    /// which case nothing is marked as differing - there is nothing to differ from).
    private static func group(_ pairs: [(option: Settings.Riwayah.Option, spelling: String)],
                              currentTag: String, hafsSpelling: String?) -> [WordRiwayahReading] {
        // Grouped by the spelling KEY, the same one the Hafs comparison below uses. The groups
        // were keyed on the printed bytes, so Hafs's كَفَرُواْ and every other riwayah's كَفَرُوا (the
        // same word, its silent letter ring stripped from all texts but Hafs's) made two rows
        // and "2 spellings". A group shows the first spelling seen for it.
        var order: [String] = []
        var shown: [String: String] = [:]
        var byKey: [String: [Settings.Riwayah.Option]] = [:]
        var currentKey: String?
        for (option, spelling) in pairs {
            let key = spellingKey(spelling)
            if byKey[key] == nil {
                order.append(key)
                shown[key] = spelling
            }
            byKey[key, default: []].append(option)
            if Settings.Riwayah.canonicalTag(option.tag) == currentTag { currentKey = key }
        }
        let hafsKey = hafsSpelling.map(spellingKey)
        return order.map { key in
            WordRiwayahReading(word: shown[key] ?? "", options: byKey[key] ?? [],
                               includesCurrent: key == currentKey,
                               differsFromHafs: hafsKey.map { key != $0 } ?? false)
        }
    }

    /// Two spellings are the same reading when their shared keys match (`QiraahSpelling.key`, the
    /// one the explorer and the comparison sheet compare under): marks are kept, a vowel being a
    /// reading, while the silent letter ring, the stop signs, the tatweel and the byte order of
    /// the marks are not.
    static func spellingKey(_ word: String) -> String {
        QiraahSpelling.key(word)
    }

    /// One riwayah's own words for the Hafs span, resolved ayah by ayah through
    /// `QiraahAyahResolver` - the comparison sheet's own resolver, so a reading that merges or
    /// splits verses yields exactly the words its comparison row shows, never a wrongly-numbered
    /// ayah (a split's pieces come joined, a merge's one ayah comes once).
    private static func tokens(context: Context, optionTag: String) -> [String] {
        var texts: [String] = []
        for hafsNumber in context.hafsSpan {
            guard let resolved = QiraahAyahResolver.resolve(
                surahNumber: context.surah,
                ayahNumber: context.ayahNumber,
                anchorHafsAyah: hafsNumber,
                optionTag: optionTag,
                clean: false
            ) else { continue }
            // A merged ayah resolves identically for every Hafs number it spans - keep it once.
            if texts.last != resolved.text { texts.append(resolved.text) }
        }
        return WordTokens.tokens(in: texts.joined(separator: " "))
    }
}

/// The bottom block of both word cards when the reader has qiraat on: the same word in every
/// riwayah, each spelling shown once with the riwayat that print it. Computed on appear, not in
/// `body` - it touches every riwayah's text and alignment.
private struct WordAcrossRiwayatSection: View {
    @ObservedObject private var settings = Settings.shared

    let surah: Surah
    let ayah: Ayah
    /// Riwayah the word was tapped in ("" = Hafs).
    let tag: String
    let word: String
    let tokenIndex: Int
    let sourceTokens: [String]

    @State private var readings: [WordRiwayahReading] = []
    @State private var cells: [WordQiraahCell] = []
    /// The comparison runs OFF the main thread (2026-09-16: a cold Al-Baqarah cost 550 ms on it, paid
    /// inside the sheet's own appearance, so "double tapping a word takes a while to open the sheet").
    /// The card opens at once; this block fills in when the comparison lands.
    @State private var comparing = false
    @State private var compareTask: Task<Void, Never>?

    private var riwayahCount: Int { readings.reduce(0) { $0 + $1.options.count } }

    private var summary: String {
        readings.count == 1
            ? "All \(riwayahCount) riwayat print this word the same way."
            : "\(readings.count) spellings across \(riwayahCount) riwayat. A word in the accent color differs from Hafs an Asim."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !readings.isEmpty {
                Divider()
                    .padding(.bottom, 4)
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACROSS THE RIWAYAT")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(summary)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                ForEach(readings) { reading in
                    // The word wears the accent when it is not Hafs's spelling; the reading the
                    // card was opened in is marked by its tinted background instead, the same
                    // grammar as the by-qiraah cells below.
                    VStack(alignment: .center, spacing: 4) {
                        Text(reading.word)
                            .font(Font.arabic(
                                settings.quranArabicFontName(for: reading.options.first?.tag),
                                size: CGFloat(settings.fontArabicSize) + 4
                            ))
                            .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                            .foregroundColor(reading.differsFromHafs ? settings.accentColor.color : .primary)
                            .multilineTextAlignment(.center)
                        Text(reading.names)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(settings.accentColor.color.opacity(reading.includesCurrent ? 0.10 : 0))
                    )
                }

                // Keyed on the cells so the uniform height starts over for every word (a height
                // measured for one word must not carry to the next).
                WordByQiraahGrid(cells: cells)
                    .id(cells.map(\.id).joined(separator: "|"))
            } else if comparing {
                Divider()
                    .padding(.bottom, 4)
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Comparing the riwayat…")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.top, 4)
        .onAppear(perform: compare)
        .onDisappear {
            compareTask?.cancel()
            compareTask = nil
        }
    }

    /// The comparison, detached: the alignment of this surah for every riwayah (the cold cost, cached
    /// for the session behind `QiraahComparison`'s lock), then the word's counterpart in each.
    private func compare() {
        guard readings.isEmpty, compareTask == nil else { return }
        comparing = true
        let surahID = surah.id
        let ayahNumber = ayah.id
        let tag = tag
        let tokenIndex = tokenIndex
        let sourceTokens = sourceTokens
        let word = word
        compareTask = Task.detached(priority: .userInitiated) {
            let context = WordCardTrace.measure("riwayat.context") {
                WordAcrossRiwayat.context(surah: surahID, ayahNumber: ayahNumber, tag: tag,
                                          tokenIndex: tokenIndex, sourceTokens: sourceTokens)
            }
            let found: (readings: [WordRiwayahReading], cells: [WordQiraahCell])? = context.map { context in
                (WordCardTrace.measure("riwayat.readings") { WordAcrossRiwayat.readings(context, word: word) },
                 WordCardTrace.measure("riwayat.byQiraah") { WordAcrossRiwayat.byQiraah(context, word: word) })
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    comparing = false
                    if let found {
                        readings = found.readings
                        cells = found.cells
                    }
                }
                #if DEBUG
                // Headless verification: the block sits below the fold of the Hafs card, so its data
                // goes to the console too.
                print("WORD CARD \(surahID):\(ayahNumber) [\(tag.isEmpty ? "Hafs" : tag)] \(word): \(summary)")
                for reading in readings { print("  \(reading.word) <- \(reading.names)") }
                for cell in cells {
                    let says = cell.readings.map { "\($0.rawiNames): \($0.word)" }.joined(separator: " | ")
                    print("  [\(cell.teacher)\(cell.isBeta ? " beta" : "")] \(says)")
                }
                fflush(stdout)
                #endif
            }
        }
    }
}

/// The same word laid out by QIRAAH rather than by spelling. The block above answers "who reads it
/// this way"; this one answers "what does each qiraah say", which is where a reader comparing the
/// Ten actually starts. Classical order of the Ten here rather than the menus' alphabetical order:
/// this is a comparison table, not a picker, and the order is part of what it teaches.
private struct WordByQiraahGrid: View {
    @ObservedObject private var settings = Settings.shared

    let cells: [WordQiraahCell]

    /// Every cell the height of the tallest (Abu, 2026-09-07: "make sure each grid is the same
    /// height"): each cell reports its natural height through a preference, the maximum goes back
    /// to all of them as a minimum height, and the words center in whatever room that leaves. Stable
    /// by construction: a cell only ever reports the larger of its own content and the height it was
    /// already given, so the maximum settles after one pass. A qiraah whose two rawis disagree used
    /// to stack its two words, which made EVERY cell two words tall (Abu, 2026-09-16: "sometimes each
    /// grid is too big"); the two now sit side by side, so a cell is always one word tall.
    @State private var uniformHeight: CGFloat = 0

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 8, alignment: .top)]

    /// Deliberately smaller than the reader's Arabic size and clamped at both ends: ten cells of a
    /// title-sized word is a screen and a half of scrolling, and the grid is for comparing spellings
    /// at a glance, not for reading from.
    private var cellFontSize: CGFloat {
        min(max(CGFloat(settings.fontArabicSize) - 10, 15), 24)
    }

    private var anyDiffersFromHafs: Bool {
        cells.contains { $0.readings.contains(where: \.differsFromHafs) }
    }

    private var caption: String {
        let count = cells.count == 1
            ? "The one qiraah with its riwayat."
            : "Each of the \(cells.count) qiraat with its two riwayat."
        return anyDiffersFromHafs ? count + " A word in the accent color differs from Hafs an Asim." : count
    }

    var body: some View {
        if !cells.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                    .padding(.top, 6)
                    .padding(.bottom, 4)
                VStack(alignment: .leading, spacing: 4) {
                    Text("BY QIRAAH")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text(caption)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(cells) { cell in
                        cellView(cell)
                    }
                }
                .onPreferenceChange(WordQiraahCellHeightKey.self) { tallest in
                    if tallest > uniformHeight { uniformHeight = tallest }
                }
            }
        }
    }

    private func cellView(_ cell: WordQiraahCell) -> some View {
        VStack(alignment: .center, spacing: 4) {
            VStack(alignment: .center, spacing: 0) {
                Text(cell.isBeta ? "\(cell.teacher) (Beta)" : cell.teacher)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(cell.isCurrent ? settings.accentColor.color : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(cell.teacherArabic)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
            HStack(alignment: .top, spacing: 8) {
                ForEach(cell.readings) { reading in
                    VStack(alignment: .center, spacing: 0) {
                        // Accent = not Hafs's spelling, in every cell alike; the reader's own qiraah is
                        // told by the cell's tinted background and name, never by the word's color.
                        Text(reading.word)
                            .font(Font.arabic(
                                settings.quranArabicFontName(for: reading.options.first?.tag),
                                size: cellFontSize
                            ))
                            .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                            .foregroundColor(reading.differsFromHafs ? settings.accentColor.color : .primary)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text(reading.rawiNames)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .background(
            GeometryReader { geometry in
                Color.clear.preference(key: WordQiraahCellHeightKey.self, value: geometry.size.height)
            }
        )
        .frame(minHeight: uniformHeight > 0 ? uniformHeight : nil)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill((cell.isCurrent ? settings.accentColor.color : Color.secondary).opacity(0.10))
        )
    }
}

/// The tallest by-qiraah cell, for `WordByQiraahGrid`'s uniform cell height.
private struct WordQiraahCellHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Bottom-of-card anchor for headless verification. The across-the-riwayat and by-qiraah blocks
/// sit well below the fold of both word cards, and the simulator cannot be scrolled from a script,
/// so `-scrollWordCardToEnd` parks the card at its end once it has laid out. DEBUG only; in
/// release both the anchor and the modifier compile away to the view itself.
private let wordCardEndAnchorID = "wordCardEnd"

private extension View {
    func scrollsToWordCardEnd(_ proxy: ScrollViewProxy) -> some View {
        #if DEBUG
        return onAppear {
            guard ProcessInfo.processInfo.arguments.contains("-scrollWordCardToEnd") else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                proxy.scrollTo(wordCardEndAnchorID, anchor: .bottom)
            }
        }
        #else
        return self
        #endif
    }
}

/// "-wordCardTrace": stamps and per-piece timings for a word card on the console - the request, the
/// first body's pieces, the appear, the across-the-riwayat block - so a "double tap takes a while to
/// open the sheet" report (Abu, 2026-09-16) is measured, not guessed. Off (a bool check) in release.
enum WordCardTrace {
    static let enabled: Bool = {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-wordCardTrace")
        #else
        return false
        #endif
    }()

    static func stamp(_ what: String) {
        guard enabled else { return }
        print(String(format: "WORDCARD %@ t=%.3f", what, CFAbsoluteTimeGetCurrent()))
        fflush(stdout)
    }

    static func measure<T>(_ what: String, _ work: () -> T) -> T {
        guard enabled else { return work() }
        let start = CFAbsoluteTimeGetCurrent()
        let result = work()
        print(String(format: "WORDCARD %@ %.1f ms", what, (CFAbsoluteTimeGetCurrent() - start) * 1000))
        fflush(stdout)
        return result
    }
}

/// The word card a double tap opens: Tilawa's word study, brought over (Abu, 2026-10-01: "double
/// tapping a word and then being able to switch words and click on the root ... showing the whole
/// word and highlighting that one part, allowing me to switch to grammar ... roots and theme").
///
/// The card MOVES: the strip of the ayah's words, the Root page's occurrences and its other forms
/// all re-point it (`current`, a raw-token location) without closing, and the tab stays put. Under
/// the word: its transliteration and meaning, chips for its part of speech, root and verb form (each
/// opens its page), then pinned tabs: Meaning (the ayah with the word lit), Grammar (the word cut
/// into prefix / stem / suffix, the chosen part lit in the word above, and the analysis), Root
/// (every word of the root, a page at a time, and its other dictionary forms), Themes (the passage
/// and the ayah's topics), Tajweed, and Qiraat when the reader has qiraat on.
struct WordMeaningSheet: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var speech = ArabicSpeech.shared
    @Environment(\.presentationMode) private var presentationMode

    let surah: Surah
    let ayah: Ayah
    let word: String
    let meaning: String
    let position: Int
    let total: Int

    /// Where the card is now; nil = the word that was tapped.
    @State private var current: WordLocation?
    @State private var tab: WordStudyTab = .meaning
    /// The Grammar page's lit part (nil = the stem).
    @State private var selectedSegment: Int?

    enum WordStudyTab: String, CaseIterable, Identifiable {
        case meaning, grammar, root, themes, tajweed, qiraat
        var id: String { rawValue }

        var title: String {
            switch self {
            case .meaning: return "Meaning"
            case .grammar: return "Grammar"
            case .root: return "Root"
            case .themes: return "Themes"
            case .tajweed: return "Tajweed"
            case .qiraat: return "Qiraat"
            }
        }

    }

    /// The word located in the RAW (uncleaned) ayah text: the raw text is what the tajweed engine
    /// annotates and every word pack is aligned to.
    private typealias LocatedWord = (text: String, tokenIndex: Int, range: NSRange)

    /// The tapped word's raw token. `position` counts DISPLAY tokens, and clean mode deletes
    /// ornament-only tokens (the ۞ mark) outright, so the display index is walked over the raw
    /// tokens, skipping any token that vanishes under cleaning (the rule `WordByWordStore` aligns by).
    private var tappedLocation: WordLocation? {
        let rawText = ayah.rawArabicText(surahId: surah.id, qiraahOverride: "")
        let tokens = WordTokens.tokens(in: rawText)
        // Whether the text the tap landed on had lost its ornaments is read off the tap itself
        // (`total` counts the DISPLAY tokens), not off the app's Hide Tashkeel: an ayah's own pin
        // and a preview card's plain text both draw the ayah against that setting, and the walk
        // then landed one word off in every ayah that opens with ۞.
        let ornamentsDropped = total < tokens.count
        var displayIndex = 0
        for (index, token) in tokens.enumerated() {
            if ornamentsDropped && Self.isOrnament(token) { continue }
            displayIndex += 1
            if displayIndex == position {
                return WordLocation(surah: surah.id, ayah: ayah.id, token: index)
            }
        }
        return nil
    }

    private static func isOrnament(_ token: String) -> Bool {
        token.removingArabicDiacriticsAndSigns.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Everything the body shows about the word the card is on, resolved once per body.
    private struct Focus {
        let location: WordLocation
        let surah: Surah
        let ayah: Ayah
        let rawText: String
        let rawTokens: [String]
        let range: NSRange
        /// The word as the reader shows it (cleaned / dotless when the reader is).
        let shown: String
        let meaning: String
        let isTapped: Bool

        var located: LocatedWord { (rawText, location.token, range) }
        var rawToken: String { rawTokens[location.token] }
    }

    private func focus(at location: WordLocation, tapped: Bool) -> Focus? {
        let hereSurah = location.surah == surah.id ? surah : QuranData.shared.surah(location.surah)
        let hereAyah = (location.surah == surah.id && location.ayah == ayah.id)
            ? ayah : QuranData.shared.ayah(surah: location.surah, ayah: location.ayah)
        guard let hereSurah, let hereAyah else { return nil }
        let rawText = hereAyah.rawArabicText(surahId: hereSurah.id, qiraahOverride: "")
        let ranges = WordTokens.ranges(in: rawText)
        let tokens = WordTokens.tokens(in: rawText)
        guard ranges.count == tokens.count, tokens.indices.contains(location.token) else { return nil }
        let glosses = WordByWordStore.shared.glosses(surah: hereSurah.id, ayah: hereAyah.id)
        let gloss = (glosses?.indices.contains(location.token) ?? false) ? glosses![location.token] : ""
        return Focus(
            location: location, surah: hereSurah, ayah: hereAyah, rawText: rawText, rawTokens: tokens,
            range: ranges[location.token],
            shown: tapped ? word : displayForm(of: tokens[location.token]),
            meaning: tapped && !meaning.isEmpty ? meaning : gloss,
            isTapped: tapped
        )
    }

    /// A raw token as the reader draws it: without tashkeel in clean mode, without dots when dotless.
    private func displayForm(of token: String) -> String {
        settings.cleanedQuranArabic(token)
    }

    /// The word painted with its tajweed colors, when tajweed is on and paints anything here.
    private func tajweedStyledWord(_ focus: Focus) -> AttributedString? {
        guard settings.showTajweedColors, settings.isHafsDisplay,
              let styled = TajweedStore.shared.attributedText(
                  surah: focus.surah.id, ayah: focus.ayah.id, text: focus.rawText
              ) else { return nil }
        let ns = NSAttributedString(styled)
        guard focus.range.location + focus.range.length <= ns.length else { return nil }
        return AttributedString(ns.attributedSubstring(from: focus.range))
    }

    /// The word with ONE part in the accent (the Grammar page's choice), the rest in the label color.
    private func segmentStyledWord(_ grammar: WordGrammar?, selected: Int?) -> AttributedString? {
        guard let grammar, grammar.isCutFromToken, grammar.segments.count > 1 else { return nil }
        let lit = selected ?? grammar.stem?.index
        let accent = UIColor(settings.accentColor.color)
        let out = NSMutableAttributedString()
        for segment in grammar.segments where !segment.form.isEmpty {
            out.append(NSAttributedString(string: segment.form, attributes: [
                .foregroundColor: segment.index == lit ? accent : UIColor.label.withAlphaComponent(0.55)
            ]))
        }
        return out.length > 0 ? AttributedString(out) : nil
    }

    /// The reader's own Quran face for Hafs, so the card matches the page it was opened from.
    private var hafsFontName: String { settings.quranArabicFontName(for: nil) }

    private func transliteration(_ focus: Focus) -> String {
        guard let latin = WordByWordStore.shared.transliterations(surah: focus.surah.id, ayah: focus.ayah.id),
              latin.indices.contains(focus.location.token) else { return "" }
        return latin[focus.location.token]
    }

    private func wordRules(_ focus: Focus) -> [TajweedWordRule] {
        guard settings.showTajweedColors, settings.isHafsDisplay else { return [] }
        return TajweedStore.shared.wordRules(
            surah: focus.surah.id, ayah: focus.ayah.id, text: focus.rawText, wordRange: focus.range
        )
    }

    private var tabs: [WordStudyTab] {
        WordStudyTab.allCases.filter { $0 != .qiraat || settings.showQiraahDetails }
    }

    var body: some View {
        let tapped = WordCardTrace.measure("body.rawWord") { tappedLocation }
        let here = current ?? tapped
        let focus = here.flatMap { self.focus(at: $0, tapped: $0 == tapped) }

        return NavigationView {
            Group {
                if let focus {
                    studyBody(focus)
                } else {
                    // The tap could not be placed in the raw text (it never should): the word and its
                    // meaning, as the card always showed them.
                    VStack(spacing: 16) {
                        Text(word)
                            .font(.custom(hafsFontName, size: CGFloat(settings.fontArabicSize) + 16))
                        Text(meaning.isEmpty ? "No meaning recorded for this word." : meaning)
                            .font(.title3)
                    }
                    .padding()
                }
            }
            .navigationTitle("Word Study")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
        // Opens halfway like every other viewer (Abu, 2026-10-04: a double tap should not take over
        // the screen). The strip and the tabs sit below a medium fold, so drag up for the full card.
        .smallMediumSheetPresentation()
        .onAppear {
            WordCardTrace.stamp("appear")
            #if DEBUG
            // "-wordStudyTab grammar|root|themes|tajweed|qiraat": the card opens on that page.
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-wordStudyTab"), args.indices.contains(i + 1),
               let target = WordStudyTab(rawValue: args[i + 1]) {
                tab = target
            }
            #endif
        }
        .onDisappear { ArabicSpeech.shared.stop() }
        .onChange(of: current) { _ in selectedSegment = nil }
    }

    @ViewBuilder
    private func studyBody(_ focus: Focus) -> some View {
        let grammar = WordCardTrace.measure("body.grammar") {
            WordGrammarStore.shared.grammar(surah: focus.surah.id, ayah: focus.ayah.id,
                                            token: focus.location.token, tokenText: focus.rawToken)
        }
        let rootInfo = MorphologyStore.shared.root(surah: focus.surah.id, ayah: focus.ayah.id, token: focus.location.token)
        let lemmaInfo = MorphologyStore.shared.lemma(surah: focus.surah.id, ayah: focus.ayah.id, token: focus.location.token)
        let rules = WordCardTrace.measure("body.wordRules") { wordRules(focus) }
        let tajweedStyled = WordCardTrace.measure("body.tajweedStyledWord") { tajweedStyledWord(focus) }
        let heroStyled = tab == .grammar ? (segmentStyledWord(grammar, selected: selectedSegment) ?? tajweedStyled) : tajweedStyled
        let heroPlain = tab == .grammar && grammar?.isCutFromToken == true ? focus.rawToken : focus.shown
        let latin = transliteration(focus)
        let strip = stripWords(focus)
        let place = strip.firstIndex { $0.token == focus.location.token }.map { $0 + 1 } ?? position

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14, pinnedViews: [.sectionHeaders]) {
                    VStack(spacing: 12) {
                        heading(focus, place: place, total: strip.count)

                        SelectableWordText(
                            styled: heroStyled,
                            plain: heroPlain,
                            font: UIFont(name: hafsFontName, size: CGFloat(settings.fontArabicSize) + 18)
                                ?? .roundedSystemFont(ofSize: CGFloat(settings.fontArabicSize) + 18),
                            lineSpacing: 6
                        )
                        .id("hero-\(focus.location.id)-\(tab == .grammar ? (selectedSegment ?? -1) : -2)")

                        // How the word is SAID, then what it means: the order a reader works in.
                        if !latin.isEmpty {
                            Text(latin)
                                .font(.headline.italic())
                                .foregroundColor(settings.accentColor.color)
                                .multilineTextAlignment(.center)
                                .textSelection(.enabled)
                        }
                        Text(focus.meaning.isEmpty ? "No meaning recorded for this word." : focus.meaning)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(focus.meaning.isEmpty ? .secondary : .primary)
                            .multilineTextAlignment(.center)

                        factChips(grammar: grammar, root: rootInfo?.root)
                        actionRow(focus)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)

                    wordStrip(strip, focus: focus)

                    Section(header: tabBar) {
                        page(focus, grammar: grammar, rules: rules, styled: tajweedStyled,
                             root: rootInfo?.root.letters, lemma: lemmaInfo?.lemma.text)
                            .padding(.horizontal)
                    }

                    Color.clear.frame(height: 1).id(wordCardEndAnchorID)
                }
                .padding(.vertical, 8)
                .scrollsToWordCardEnd(proxy)
            }
        }
    }

    // MARK: Pieces

    private func heading(_ focus: Focus, place: Int, total: Int) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(focus.surah.nameTransliteration) \(focus.surah.id):\(focus.ayah.id)")
                .font(.headline)
                .foregroundColor(settings.accentColor.color)
            Spacer()
            Text("Word \(place) of \(total)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    /// Part of speech, root and verb form under the word: the answers a reader looks for first,
    /// each a door into the page that explains it.
    @ViewBuilder
    private func factChips(grammar: WordGrammar?, root: MorphologyStore.Root?) -> some View {
        let chips: (pos: String?, form: String?) = grammar.map(WordGrammarText.chips) ?? (pos: nil, form: nil)
        if chips.pos != nil || root != nil || chips.form != nil {
            HStack(spacing: 8) {
                if let pos = chips.pos {
                    factChip(title: pos, arabic: nil, target: .grammar)
                }
                if let root {
                    factChip(title: "Root", arabic: root.letters, target: .root)
                }
                if let form = chips.form {
                    factChip(title: form, arabic: nil, target: .grammar)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }

    private func factChip(title: String, arabic: String?, target: WordStudyTab) -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.2)) { tab = target }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption.weight(.semibold))
                if let arabic {
                    Text(arabic)
                        .font(.custom(hafsFontName, size: 16))
                        .arabicFontDesign(custom: true)
                }
            }
            .foregroundColor(tab == target ? .white : settings.accentColor.color)
            .padding(.horizontal, 12)
            .frame(minHeight: 32)
            .background(
                Capsule().fill(tab == target ? settings.accentColor.color : settings.accentColor.color.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the \(target.title) page")
    }

    private func actionRow(_ focus: Focus) -> some View {
        let speechAvailable = ArabicSpeech.shared.isAvailable
        let speaking = speech.currentText == focus.rawToken || speech.currentText == focus.shown
        return HStack(spacing: 10) {
            if speechAvailable {
                actionButton(speaking ? "Stop" : "Listen", system: speaking ? "stop.fill" : "speaker.wave.2.fill") {
                    settings.hapticFeedback()
                    if speaking { ArabicSpeech.shared.stop() } else { ArabicSpeech.shared.speak(focus.shown) }
                }
            }
            actionButton("Copy", system: "doc.on.doc") {
                settings.hapticFeedback()
                UIPasteboard.general.string = focus.meaning.isEmpty
                    ? focus.shown
                    : "\(focus.shown): \(focus.meaning)\n\(focus.surah.nameTransliteration) \(focus.surah.id):\(focus.ayah.id)"
            }
        }
    }

    /// One chip per word of the ayah (ornaments like ۞ skipped), word 1 on the RIGHT as the line
    /// reads; the card's word is filled and kept centred.
    private struct StripWord: Identifiable {
        let token: Int
        let text: String
        var id: Int { token }
    }

    private func stripWords(_ focus: Focus) -> [StripWord] {
        focus.rawTokens.enumerated().compactMap { index, token in
            Self.isOrnament(token) ? nil : StripWord(token: index, text: displayForm(of: token))
        }
    }

    private func wordStrip(_ words: [StripWord], focus: Focus) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("WORDS IN THIS AYAH")
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(words) { word in
                            let isOn = word.token == focus.location.token
                            Button {
                                settings.hapticFeedback()
                                current = WordLocation(surah: focus.surah.id, ayah: focus.ayah.id, token: word.token)
                            } label: {
                                Text(word.text)
                                    .font(.custom(hafsFontName, size: 22))
                                    .arabicFontDesign(custom: true)
                                    .foregroundColor(isOn ? .white : .primary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 2)
                                    .frame(minHeight: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(isOn ? settings.accentColor.color : Color.primary.opacity(0.07))
                                    )
                            }
                            .buttonStyle(.plain)
                            .id(word.token)
                            .accessibilityLabel(word.text)
                            .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
                        }
                    }
                    .padding(.horizontal)
                }
                .environment(\.layoutDirection, .rightToLeft)
                .onAppear { proxy.scrollTo(focus.location.token, anchor: .center) }
                .onChange(of: focus.location) { location in
                    withAnimation(.easeInOut(duration: 0.25)) { proxy.scrollTo(location.token, anchor: .center) }
                }
            }
        }
    }

    /// The pinned tab pills, on the bar material so the pages scroll cleanly under them. Titles only
    /// (icons pushed the fifth tab off the edge), and the chosen one is scrolled into view.
    private var tabBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tabs) { item in
                        let isOn = item == tab
                        Button {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut(duration: 0.2)) { tab = item }
                        } label: {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                                .foregroundColor(isOn ? .white : settings.accentColor.color)
                                .padding(.horizontal, 13)
                                .frame(minHeight: 36)
                                .background(
                                    Capsule().fill(isOn ? settings.accentColor.color : settings.accentColor.color.opacity(0.12))
                                )
                        }
                        .buttonStyle(.plain)
                        .id(item)
                        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .onAppear { proxy.scrollTo(tab, anchor: .center) }
            .onChange(of: tab) { item in
                withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo(item, anchor: .center) }
            }
        }
        .background(.bar)
    }

    // MARK: Pages

    @ViewBuilder
    private func page(_ focus: Focus, grammar: WordGrammar?, rules: [TajweedWordRule],
                      styled: AttributedString?, root: String?, lemma: String?) -> some View {
        switch tab {
        case .meaning:
            meaningPage(focus, styled: styled)
        case .grammar:
            WordGrammarPage(grammar: grammar, root: root, lemma: lemma, fontName: hafsFontName,
                            selected: $selectedSegment)
        case .root:
            if MorphologyStore.isBundled {
                WordRootPage(location: focus.location, fontName: hafsFontName) { location in
                    withAnimation(.easeInOut(duration: 0.2)) { current = location }
                }
            }
        case .themes:
            themesPage(focus)
        case .tajweed:
            tajweedPage(rules)
        case .qiraat:
            if settings.showQiraahDetails {
                WordAcrossRiwayatSection(
                    surah: focus.surah,
                    ayah: focus.ayah,
                    tag: Settings.Riwayah.hafsTag,
                    // The RAW token, like every other riwayah's spelling in the block: the
                    // displayed form loses its tashkeel under Hide Tashkeel, and Hafs's own row
                    // then stood apart from the riwayat that print the word identically, tinted
                    // as "differs from Hafs".
                    word: focus.rawToken,
                    tokenIndex: focus.location.token,
                    sourceTokens: focus.rawTokens
                )
                // One identity per word. The block compares on appear and keeps the result in its
                // own state, so when the strip moved the card to another word it went on showing
                // the first word's readings.
                .id(focus.location)
            }
        }
    }

    private func meaningPage(_ focus: Focus, styled: AttributedString?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // The whole ayah, the word lit inside it, so the word is never read out of its sentence.
            StudyCard(title: "IN THIS AYAH") {
                WordOccurrenceRow(surah: focus.surah, ayah: focus.ayah, tokens: [focus.location.token])
                    .equatable()
            }

            // Word-by-word glosses are their own scholarly work (a literal rendering of each word in
            // place), not an excerpt of the flowing translation, so they carry their own attribution.
            Text("Word-by-word meanings from the Quranic Arabic Corpus, via Quran.com. They render each word literally and in place, so they read differently from the flowing translation.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            BeginnerLettersSection(
                styled: styled,
                word: focus.shown,
                fontName: hafsFontName,
                fontSize: CGFloat(settings.fontArabicSize) + 8
            )
        }
    }

    @ViewBuilder
    private func themesPage(_ focus: Focus) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            AyahInsightsCard(surah: focus.surah, ayah: focus.ayah)

            NavigationLink {
                ThemesBrowseView(onOpenAyah: { _, _ in })
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.2x2")
                    Text("Browse Every Theme of the Quran")
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(settings.accentColor.color.opacity(0.10))
                )
            }
            .buttonStyle(.plain)

            Text("Themes belong to the ayah and its passage: every word of this ayah shares them.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func tajweedPage(_ rules: [TajweedWordRule]) -> some View {
        if !settings.showTajweedColors || !settings.isHafsDisplay {
            StudyCard(title: "TAJWEED IN THIS WORD") {
                Text("Turn on tajweed colors in Quran Settings to see the rules on each word.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else if rules.isEmpty {
            StudyCard(title: "TAJWEED IN THIS WORD") {
                Text("No tajweed rule falls on this word.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            // The rules this word carries, matching the colors painted on it: a per-word legend.
            StudyCard(title: "TAJWEED IN THIS WORD") {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(rules) { rule in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(rule.color)
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(rule.englishTitle)
                                    .font(.subheadline.weight(.medium))
                                Text(rule.transliteration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(rule.arabicTitle)
                                .font(.subheadline)
                                .foregroundColor(rule.color)
                        }
                    }
                }
            }
        }
    }

    private func actionButton(_ title: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: system)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16)
                .frame(minHeight: 40)
                .background(
                    Capsule().fill(settings.accentColor.color.opacity(0.15))
                )
                .foregroundColor(settings.accentColor.color)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - The riwayah word card

/// The word a reader tapped in a NON-Hafs riwayah. There is no gloss pack for these texts (the
/// meanings are Hafs-token-aligned), so the card's job is different: name the riwayah's own rules
/// on this word - what the colors mean and how the word is recited - and show the Hafs counterpart
/// underneath, aligned word-by-word through the ayah alignment.
struct RiwayahTappedWord: Identifiable, Equatable {
    let index: Int
    let word: String
    let total: Int
    let tag: String

    var id: Int { index }
}

struct RiwayahWordSheet: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var speech = ArabicSpeech.shared

    let surah: Surah
    let ayah: Ayah
    let tag: String
    let word: String
    /// Zero-based DISPLAY token index of the tapped word.
    let index: Int
    let total: Int

    private var isSpeakingThis: Bool { speech.currentText == word }

    /// The tapped word located in the RAW (uncleaned) riwayah text - the text the pack's word
    /// indices and letter extents address. Same display-index-over-raw-tokens walk as the Hafs
    /// card: clean mode deletes ornament-only tokens, so the display index skips them.
    private var rawWord: (text: String, tokenIndex: Int, range: NSRange)? {
        let rawText = ayah.rawArabicText(surahId: surah.id, qiraahOverride: tag)
        let ranges = WordTokens.ranges(in: rawText)
        let tokens = WordTokens.tokens(in: rawText)
        guard ranges.count == tokens.count else { return nil }

        // Same rule as the Hafs card: `total` counts the DISPLAY tokens, so it says whether the
        // tapped text had dropped its ornaments; the app's Hide Tashkeel does not (an ayah's own
        // pin, or a preview card's plain text, draws against it).
        let ornamentsDropped = total < tokens.count
        var displayIndex = -1
        for (rawIndex, token) in tokens.enumerated() {
            let visible = !token.removingArabicDiacriticsAndSigns
                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if !visible && ornamentsDropped { continue }
            displayIndex += 1
            if displayIndex == index {
                return (rawText, rawIndex, ranges[rawIndex])
            }
        }
        return nil
    }

    /// The word painted the way THIS riwayah's print colors it. Painted unconditionally (the card
    /// doubles as the word's legend), honouring only the reader's hidden-rule choices.
    private var styledWord: AttributedString? {
        guard let located = rawWord,
              let styled = QiraahTajweedStore.shared.attributedText(
                  tag: tag, surah: surah.id, ayah: ayah.id, displayText: located.text,
                  hiddenRules: settings.riwayahTajweedHiddenRuleSet
              ) else { return nil }
        let ns = NSAttributedString(styled)
        guard located.range.location + located.range.length <= ns.length else { return nil }
        return AttributedString(ns.attributedSubstring(from: located.range))
    }

    /// The riwayah rules this word carries, resolved through the pack's own legend - the names,
    /// the colors, and the how-to-recite descriptions, in legend order.
    private var wordRuleEntries: [QiraahTajweedStore.LegendEntry] {
        guard let located = rawWord,
              let rules = QiraahTajweedStore.shared.wordRules(tag: tag, surah: surah.id, ayah: ayah.id),
              let wordRules = rules[located.tokenIndex], !wordRules.isEmpty else { return [] }
        let legend = QiraahTajweedStore.shared.legend(for: tag)
        let hidden = settings.riwayahTajweedHiddenRuleSet
        var seen = Set<String>()
        var out: [QiraahTajweedStore.LegendEntry] = []
        for entry in legend where !hidden.contains(entry.key) {
            guard wordRules.contains(where: { $0.letter == entry.letter }), seen.insert(entry.key).inserted else { continue }
            out.append(entry)
        }
        return out
    }

    // MARK: Hafs counterpart

    /// The tapped word placed in the Hafs text: which Hafs ayah(s) this ayah spans, and which of
    /// their words this one answers to. Also what the across-the-riwayat block is built from.
    private var wordContext: WordAcrossRiwayat.Context? {
        guard let located = rawWord else { return nil }
        return WordAcrossRiwayat.context(
            surah: surah.id, ayahNumber: ayah.id, tag: tag,
            tokenIndex: located.tokenIndex,
            sourceTokens: WordTokens.tokens(in: located.text)
        )
    }

    /// The Hafs word(s) this riwayah word corresponds to. A word absent from Hafs (or unmappable)
    /// returns nil - the card says so instead of guessing.
    private var hafsCounterpart: String? {
        wordContext.flatMap(WordAcrossRiwayat.hafsCounterpart)
    }

    private var riwayahFontName: String { settings.quranArabicFontName(for: tag) }

    var body: some View {
        NavigationView {
            ScrollView {
                ScrollViewReader { proxy in
                VStack(spacing: 20) {
                    SelectableWordText(
                        styled: styledWord,
                        plain: word,
                        font: UIFont(name: riwayahFontName, size: CGFloat(settings.fontArabicSize) + 16)
                            ?? .roundedSystemFont(ofSize: CGFloat(settings.fontArabicSize) + 16),
                        lineSpacing: 6
                    )
                    .padding(.top, 8)

                    Text("Word \(index + 1) of \(total) · \(surah.nameTransliteration) \(surah.id):\(ayah.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        if ArabicSpeech.shared.isAvailable {
                            actionButton(
                                isSpeakingThis ? "Stop" : "Listen",
                                system: isSpeakingThis ? "stop.fill" : "speaker.wave.2.fill"
                            ) {
                                settings.hapticFeedback()
                                if isSpeakingThis {
                                    ArabicSpeech.shared.stop()
                                } else {
                                    ArabicSpeech.shared.speak(word)
                                }
                            }
                        }

                        actionButton("Copy", system: "doc.on.doc") {
                            settings.hapticFeedback()
                            UIPasteboard.general.string = "\(word)\n\(surah.nameTransliteration) \(surah.id):\(ayah.id)"
                        }
                    }
                    .padding(.top, 4)

                    // The riwayah's own rules on this word - the card doubles as a per-word legend,
                    // with each rule's how-it-is-recited note from the print's legend descriptions.
                    if !wordRuleEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Divider()
                                .padding(.bottom, 4)
                            Text("IN THIS RIWAYAH")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            ForEach(wordRuleEntries) { entry in
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 10) {
                                        Circle()
                                            .fill(entry.color)
                                            .frame(width: 12, height: 12)
                                        Text(entry.english)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text(entry.arabic)
                                            .font(.subheadline)
                                            .foregroundColor(entry.color)
                                    }
                                    let description = entry.longDescription.isEmpty
                                        ? entry.shortDescription : entry.longDescription
                                    if !description.isEmpty {
                                        Text(description)
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }

                    BeginnerLettersSection(
                        styled: styledWord,
                        word: word,
                        fontName: riwayahFontName,
                        fontSize: CGFloat(settings.fontArabicSize) + 8
                    )

                    // The Hafs counterpart, so the difference is visible side by side. Aligned
                    // word-by-word; a merged or dropped word shows its whole Hafs span. It sits
                    // BELOW beginner mode (user rule, 2026-08): the letter-by-letter line belongs
                    // to the word at the top of the card, and the comparisons follow it.
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                            .padding(.bottom, 4)
                        Text("IN HAFS AN 'ASIM")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        if let hafs = hafsCounterpart {
                            Text(hafs)
                                .font(Font.arabic(settings.quranArabicFontName(for: nil), size: CGFloat(settings.fontArabicSize) + 6))
                                .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                            if WordAcrossRiwayat.skeleton(hafs) == WordAcrossRiwayat.skeleton(word) {
                                Text("Written the same; the coloring above marks how this riwayah recites it.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("This word has no separate counterpart in the Hafs text.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)

                    // And the same word in every OTHER riwayah, under the Hafs one.
                    if settings.showQiraahDetails, let located = rawWord {
                        // The RAW token, not the tapped display form: under Hide Tashkeel the
                        // reader's own riwayah was compared stripped against every other text's
                        // full spelling, and always came out as differing from Hafs.
                        let rawTokens = WordTokens.tokens(in: located.text)
                        WordAcrossRiwayatSection(
                            surah: surah,
                            ayah: ayah,
                            tag: tag,
                            word: rawTokens.indices.contains(located.tokenIndex) ? rawTokens[located.tokenIndex] : word,
                            tokenIndex: located.tokenIndex,
                            sourceTokens: rawTokens
                        )
                    }
                    Color.clear.frame(height: 1).id(wordCardEndAnchorID)
                }
                .padding()
                .scrollsToWordCardEnd(proxy)
                }
            }
            .navigationTitle("Word")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
        .smallMediumSheetPresentation()
        .onDisappear { ArabicSpeech.shared.stop() }
    }

    private func actionButton(_ title: String, system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: system)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(settings.accentColor.color.opacity(0.15))
                )
                .foregroundColor(settings.accentColor.color)
        }
        .buttonStyle(.plain)
    }
}
#endif
