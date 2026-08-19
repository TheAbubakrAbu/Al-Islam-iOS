#if os(iOS)
import SwiftUI
import UIKit
import Compression

// Word-by-word meanings: tap any word of an ayah and see what that word means.
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

/// Per-word English glosses for all 6236 ayahs, from `WordByWord.json.deflate`.
///
/// THE INVARIANT THIS RESTS ON: the pack stores one gloss per whitespace-separated token of THIS APP's
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

    private let lock = NSLock()
    /// surah id → ayahs in id order → one gloss per token.
    private var table: [Int: [[String]]]?
    private var loadFailed = false

    /// Whether the pack is in the bundle at all - a cheap URL lookup, so callers can gate UI (the
    /// settings toggle) without paying for the parse.
    static let isBundled: Bool = packURL() != nil

    /// Raw glosses for one ayah, in the app's Hafs token order. Prefer `glosses(surah:ayah:displayText:)`,
    /// which reconciles this with what the reader is actually showing.
    func glosses(surah: Int, ayah: Int) -> [String]? {
        guard let table = loadedTable(),
              let rows = table[surah],
              ayah >= 1, ayah <= rows.count else { return nil }
        return rows[ayah - 1]
    }

    /// Glosses lined up with the tokens of `displayText`, or nil when they cannot be lined up.
    ///
    /// The reader does not always show the raw text: "Hide Tashkeel and Signs" strips U+06D6…U+06ED,
    /// which DELETES the standalone ۞ token from the 199 ayahs that carry one, so the displayed text has
    /// one token fewer than the pack has glosses. Dropping the glosses whose token vanished restores the
    /// alignment. Any other disagreement (a riwayah with different wording, beginner letter-spacing) is
    /// not reconcilable and returns nil, which switches the feature off for that ayah rather than
    /// showing a neighbouring word's meaning.
    func glosses(surah: Int, ayah: Int, rawText: String, displayText: String) -> [String]? {
        guard let raw = glosses(surah: surah, ayah: ayah) else { return nil }

        let displayCount = WordTokens.count(in: displayText)
        if raw.count == displayCount { return raw }

        let rawTokens = WordTokens.tokens(in: rawText)
        guard rawTokens.count == raw.count else { return nil }

        // Keep only the glosses whose token still has content once the sign-stripping is applied.
        var kept: [String] = []
        kept.reserveCapacity(displayCount)
        for (token, gloss) in zip(rawTokens, raw) where !token.removingArabicDiacriticsAndSigns
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            kept.append(gloss)
        }
        return kept.count == displayCount ? kept : nil
    }

    /// Drops the parsed table (the setting was switched off). The pack reloads on next use.
    func unload() {
        lock.lock(); defer { lock.unlock() }
        table = nil
        loadFailed = false
    }

    private func loadedTable() -> [Int: [[String]]]? {
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
        Bundle.main.url(forResource: "WordByWord", withExtension: "json.deflate", subdirectory: "Data/Quran")
            ?? Bundle.main.url(forResource: "WordByWord", withExtension: "json.deflate", subdirectory: "Quran")
            ?? Bundle.main.url(forResource: "WordByWord", withExtension: "json.deflate")
    }

    private static func load() -> [Int: [[String]]]? {
        guard let url = packURL(),
              let blob = try? Data(contentsOf: url),
              let json = inflate(blob),
              let raw = try? JSONSerialization.jsonObject(with: json) as? [String: [[String]]] else { return nil }

        var out: [Int: [[String]]] = [:]
        out.reserveCapacity(raw.count)
        for (surahKey, rows) in raw {
            guard let sid = Int(surahKey) else { continue }
            out[sid] = rows
        }
        return out.isEmpty ? nil : out
    }

    /// Raw-deflate inflate - no zlib header, matching the Qiraah/Tajweed payloads and what
    /// `Scripts/build_wordbyword.py` writes.
    private static func inflate(_ data: Data) -> Data? {
        let capacity = max(data.count * 12, 1 << 21)
        var out = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        defer { buffer.deallocate() }
        let written = data.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) -> Int in
            guard let base = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return compression_decode_buffer(buffer, capacity, base, data.count, nil, COMPRESSION_ZLIB)
        }
        guard written > 0 else { return nil }
        out.append(buffer, count: written)
        return out
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

    static func tokens(in text: String) -> [String] {
        text.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    }

    static func count(in text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace }).count
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
                                           rawText: String, displayText: String) -> [String] {
        let key = "a→e\u{0000}\(query)\u{0000}\(surah):\(ayah)\u{0000}\(displayText.hashValue)" as NSString
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
        for match in HighlightedSnippet.matchRanges(of: query, in: displayText) {
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
    static func arabicSpansForArabicQuery(query: String, in displayText: String) -> [NSRange] {
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
        spansCache.setObject(SpansEntry(spans), forKey: key)
        return spans
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
            // Snapshot the (value-type) surah array on the calling thread; the fold work moves off it.
            let surahs = quranSnapshot()
            DispatchQueue.global(qos: .utility).async { buildLexicon(surahs: surahs) }
        }
        return nil
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
        var table: [String: Set<String>] = [:]
        table.reserveCapacity(24_000)
        for surah in surahs {
            for ayah in surah.ayahs {
                guard let glosses = WordByWordStore.shared.glosses(surah: surah.id, ayah: ayah.id) else { continue }
                let tokens = WordTokens.tokens(in: ayah.textHafs.trimmingCharacters(in: .whitespacesAndNewlines))
                guard tokens.count == glosses.count else { continue }
                for (token, gloss) in zip(tokens, glosses) {
                    let words = contentWords(of: gloss)
                    guard !words.isEmpty else { continue }
                    // Indexed under EVERY variant, exactly the set the lookups ask for, so a hadith's
                    // والصبر and the Quran's ٱلصَّبْر meet at the same key.
                    for key in lookupKeys(for: HighlightedSnippet.normalizeForSearchText(token, trimWhitespace: true)) {
                        table[key, default: []].formUnion(words)
                    }
                }
            }
        }
        table = table.filter { $0.value.count <= glossNoiseCap }

        lexiconLock.lock()
        if table.count >= minimumLexiconEntries {
            lexicon = table
        } else {
            lexiconBuildStarted = false
        }
        lexiconLock.unlock()
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

        /// ...and when it DOES land on a word, the row's tap must not also fire: the reader asked for the
        /// word, not for the ayah to be marked. Requiring the other recognizer to wait for this one is
        /// the only lever available here - SwiftUI's tap gesture lives on an ancestor this view cannot
        /// reach to configure directly.
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

/// Builds the attributed ayah (tajweed colors, the name الله, the trailing ayah ornament) and hands it to
/// the text view above. Kept separate so the representable stays a dumb renderer.
struct WordByWordText: View {
    @ObservedObject private var settings = Settings.shared

    /// What the reader is showing - already clean-mode / dots-mode processed.
    let displayText: String
    /// Tajweed-colored version of `displayText`, when tajweed colors are on.
    let preStyled: AttributedString?
    let fontName: String?
    let fontSize: CGFloat
    let ayahNumberArabic: String
    let glosses: [String]
    /// Non-Hafs riwayat have no gloss pack, but their words still open the riwayah word card -
    /// every LETTERED token is tappable regardless of `glosses` (ornament-only tokens stay silent).
    var alwaysTappable: Bool = false
    /// The word currently showing its card, lit in the accent.
    let selectedWord: Int?
    let onSelectWord: (Int) -> Void

    /// The reader's content width. Seeded from the last measurement so only the very first row of a
    /// session has to wait for a layout pass to know it.
    @State private var width: CGFloat = WordByWordText.lastMeasuredWidth

    private static var lastMeasuredWidth: CGFloat = 0

    private var wordRanges: [NSRange] { WordTokens.ranges(in: displayText) }

    var body: some View {
        // Until the width is known the text view would lay out on one endless line; the plain snippet
        // renders identically (it just isn't tappable), so the row never flashes an empty or wrong-height
        // block while measuring.
        Group {
            if width > 0 {
                WordByWordTextView(
                    attributed: attributedText(),
                    wordRanges: wordRanges,
                    width: width,
                    selectedWord: selectedWord,
                    highlightColor: settings.accentColor.color,
                    onTapWord: { index in
                        // A token with no gloss of its own (the ۞ mark, the tail of a merged word) has
                        // nothing to show - stay silent rather than open an empty card. In riwayah mode
                        // (no glosses exist at all) any token that carries letters opens the word card.
                        if alwaysTappable {
                            let tokens = WordTokens.tokens(in: displayText)
                            guard tokens.indices.contains(index),
                                  !tokens[index].removingArabicDiacriticsAndSigns
                                      .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        } else {
                            guard glosses.indices.contains(index), !glosses[index].isEmpty else { return }
                        }
                        settings.hapticFeedback()
                        onSelectWord(index)
                    }
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                HighlightedSnippet(
                    source: displayText,
                    term: "",
                    font: swiftUIFont,
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: preStyled,
                    trailingSuffix: " \(ayahNumberArabic)",
                    trailingSuffixFont: .custom(Settings.hafsUthmaniFontName, size: fontSize),
                    trailingSuffixColor: settings.accentColor.color,
                    highlightAllahNames: settings.highlightAllahNames
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
        if let fontName, let font = UIFont(name: fontName, size: fontSize) {
            return font
        }
        return .roundedSystemFont(ofSize: fontSize)
    }

    /// The ayah as TextKit needs it: the same colors the list renders today, plus the ayah-number
    /// ornament, which always comes from the Uthmani face (the system font would print bare digits).
    private func attributedText() -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = fontName == nil ? .natural : .right
        paragraph.baseWritingDirection = .rightToLeft

        let body: NSMutableAttributedString
        // A pre-styled string whose characters don't match the display text (a mode the tajweed store
        // couldn't map) would shift every word range - fall back to the plain text rather than paint the
        // wrong word.
        if let preStyled, String(preStyled.characters) == displayText {
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

        if settings.highlightAllahNames {
            let ns = displayText as NSString
            for range in HighlightedSnippet.arabicAllahRanges(in: displayText) {
                let utf16 = NSRange(range, in: displayText)
                guard utf16.location + utf16.length <= ns.length else { continue }
                body.addAttribute(.foregroundColor, value: UIColor.systemRed, range: utf16)
            }
        }

        let markerFont = UIFont(name: Settings.hafsUthmaniFontName, size: fontSize) ?? uiFont
        body.append(NSAttributedString(
            string: " \(ayahNumberArabic)",
            attributes: [
                .font: markerFont,
                .foregroundColor: UIColor(settings.accentColor.color),
                .paragraphStyle: paragraph,
            ]
        ))
        return body
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
    /// The word currently showing its card, washed in the accent.
    let selectedWord: Int?
    let onSelectWord: (Int) -> Void

    @State private var width: CGFloat = 0

    private struct WordCell: Identifiable {
        let id: Int
        let arabic: AttributedString
        let gloss: String
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
                    highlightAllahNames: settings.highlightAllahNames
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
        if let fontName, let font = UIFont(name: fontName, size: fontSize) { return font }
        return .roundedSystemFont(ofSize: fontSize)
    }

    /// One styled slice per token (plus the trailing ornament cell), colors carried per word. Sliced
    /// from ONE styled pass over the whole ayah so tajweed runs, the red الله, and any future paint
    /// stay identical to the flowing rendering.
    private var cells: [WordCell] {
        let base: NSMutableAttributedString
        // A pre-styled string whose characters don't match the display text (a mode the tajweed
        // store couldn't map) would shift every word range - fall back to plain rather than paint
        // the wrong word (same rule as `WordByWordText`).
        if let preStyled, String(preStyled.characters) == displayText {
            base = NSMutableAttributedString(attributedString: NSAttributedString(preStyled))
        } else {
            base = NSMutableAttributedString(
                string: displayText,
                attributes: [.foregroundColor: UIColor.label]
            )
        }
        if settings.highlightAllahNames {
            let ns = displayText as NSString
            for range in HighlightedSnippet.arabicAllahRanges(in: displayText) {
                let utf16 = NSRange(range, in: displayText)
                guard utf16.location + utf16.length <= ns.length else { continue }
                base.addAttribute(.foregroundColor, value: UIColor.systemRed, range: utf16)
            }
        }

        var out: [WordCell] = []
        let ranges = WordTokens.ranges(in: displayText)
        out.reserveCapacity(ranges.count + 1)
        for (index, range) in ranges.enumerated() {
            guard range.location + range.length <= base.length else { continue }
            out.append(WordCell(
                id: index,
                arabic: AttributedString(base.attributedSubstring(from: range)),
                gloss: glosses.indices.contains(index) ? glosses[index] : ""
            ))
        }
        out.append(WordCell(id: -1, arabic: AttributedString(ayahNumberArabic), gloss: ""))
        return out
    }

    // MARK: Geometry

    private var glossFontSize: CGFloat { max(11, min(14, fontSize * 0.32)) }
    /// Widest a gloss may render; longer ones wrap to a second line, then truncate.
    private let glossMaxWidth: CGFloat = 110
    private let cellHorizontalPadding: CGFloat = 3
    private let cellSpacing: CGFloat = 4

    private func cellView(_ cell: WordCell) -> some View {
        let selected = !cell.isOrnament && selectedWord == cell.id
        return VStack(spacing: 2) {
            Text(cell.arabic)
                .font(cell.isOrnament ? .custom(Settings.hafsUthmaniFontName, size: fontSize) : arabicSwiftUIFont)
                .foregroundColor(cell.isOrnament ? settings.accentColor.color : nil)
                .arabicFontDesign(custom: true)
                .lineLimit(1)
                .fixedSize()
            if !cell.gloss.isEmpty {
                Text(cell.gloss)
                    .font(.system(size: glossFontSize))
                    .foregroundColor(.secondary)
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
                .fill(selected ? settings.accentColor.color.opacity(0.18) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // A token with no gloss of its own (the ۞ mark, the tail of a merged word) has nothing
            // to show - stay silent rather than open an empty card.
            guard !cell.isOrnament, !cell.gloss.isEmpty else { return }
            settings.hapticFeedback()
            onSelectWord(cell.id)
        }
    }

    /// A cell's rendered width, measured with the SAME fonts the cell view uses - so rows can be
    /// partitioned deterministically in plain code (no alignment-guide layout tricks, which proved
    /// unreliable under RTL inside a List).
    private func cellWidth(_ cell: WordCell) -> CGFloat {
        let font = cell.isOrnament
            ? (UIFont(name: Settings.hafsUthmaniFontName, size: fontSize) ?? arabicUIFont)
            : arabicUIFont
        let arabicWidth = ceil((String(cell.arabic.characters) as NSString)
            .size(withAttributes: [.font: font]).width)
        var glossWidth: CGFloat = 0
        if !cell.gloss.isEmpty {
            glossWidth = min(glossMaxWidth, ceil((cell.gloss as NSString)
                .size(withAttributes: [.font: UIFont.systemFont(ofSize: glossFontSize)]).width))
        }
        return max(arabicWidth, glossWidth) + cellHorizontalPadding * 2
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
        VStack(alignment: .leading, spacing: 8) {
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
struct TappedWord: Identifiable {
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
            Group {
                if let styled {
                    Text(beginnerSpacedStyled(styled))
                } else {
                    Text(word.beginnerSpaced)
                }
            }
            .font(.custom(fontName, size: fontSize))
            .arabicFontDesign(custom: true)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }
}

/// What one word means. Deliberately small: the word, its meaning, where it sits, and the two things
/// worth doing with it.
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

    private var isSpeakingThis: Bool { speech.currentText == word }

    /// The word located in the RAW (uncleaned) ayah text: the raw text is what the tajweed engine
    /// annotates, so both the colored word and its rules list resolve against it.
    ///
    /// `position` counts DISPLAY tokens, and clean mode deletes ornament-only tokens (the ۞ mark)
    /// outright - so the display index is walked over the raw tokens, skipping any token that
    /// vanishes under cleaning, exactly the rule `WordByWordStore` aligns glosses with.
    private var rawWord: (text: String, range: NSRange)? {
        let rawText = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: "")
        let ranges = WordTokens.ranges(in: rawText)
        let tokens = WordTokens.tokens(in: rawText)
        guard ranges.count == tokens.count else { return nil }

        var displayIndex = 0
        for (index, token) in tokens.enumerated() {
            let visible = !token.removingArabicDiacriticsAndSigns
                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            // A token clean mode would delete only counts toward the display index when the reader
            // is NOT in clean mode (where display == raw and every token counts).
            if !visible && settings.cleanArabicText { continue }
            displayIndex += 1
            if displayIndex == position {
                return (rawText, ranges[index])
            }
        }
        return nil
    }

    /// The word painted with its tajweed colors, when tajweed is on and paints anything here.
    private var tajweedStyledWord: AttributedString? {
        guard settings.showTajweedColors, settings.isHafsDisplay,
              let located = rawWord,
              let styled = TajweedStore.shared.attributedText(
                  surah: surah.id, ayah: ayah.id, text: located.text
              ) else { return nil }
        let ns = NSAttributedString(styled)
        guard located.range.location + located.range.length <= ns.length else { return nil }
        return AttributedString(ns.attributedSubstring(from: located.range))
    }

    /// The visible tajweed rules inside this word, in legend order.
    private var wordRules: [TajweedLegendCategory] {
        guard settings.showTajweedColors, settings.isHafsDisplay, let located = rawWord else { return [] }
        return TajweedStore.shared.ruleCategories(
            surah: surah.id, ayah: ayah.id, text: located.text, wordRange: located.range
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        if let styled = tajweedStyledWord {
                            Text(styled)
                        } else {
                            Text(word)
                        }
                    }
                    .font(.custom(Settings.hafsUthmaniFontName, size: CGFloat(settings.fontArabicSize) + 16))
                    .arabicFontDesign(custom: true)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // Leading, not centered (user rule): the English gloss reads as a sentence fragment,
                    // and centered fragments float - lead-align it like the translation block below.
                    Text(meaning.isEmpty ? "No meaning recorded for this word." : meaning)
                        .font(.title3)
                        .foregroundColor(meaning.isEmpty ? .secondary : .primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Word \(position) of \(total) · \(surah.nameTransliteration) \(surah.id):\(ayah.id)")
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
                            UIPasteboard.general.string = meaning.isEmpty
                                ? word
                                : "\(word) - \(meaning)\n\(surah.nameTransliteration) \(surah.id):\(ayah.id)"
                        }
                    }
                    .padding(.top, 4)

                    // The tajweed rules this word carries, matching the colors painted on it above -
                    // the card doubles as a per-word legend. Only rules the reader has visible are
                    // listed, so the list never names a color that isn't on screen.
                    if !wordRules.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Divider()
                                .padding(.bottom, 4)
                            Text("TAJWEED IN THIS WORD")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            ForEach(wordRules) { rule in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(rule.color)
                                        .frame(width: 12, height: 12)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(rule.englishTitle)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
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
                        .padding(.top, 4)
                    }

                    // The whole ayah underneath, so the word is never read out of its sentence. Named,
                    // because it is a DIFFERENT source than the word above it - a reader comparing the
                    // two should know the gloss is not simply the translation chopped up.
                    VStack(alignment: .leading, spacing: 4) {
                        Divider()
                            .padding(.bottom, 4)
                        Text(ayah.textEnglishSaheeh)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("- Saheeh International")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // Where the word's own meaning comes from. Word-by-word glosses are their own
                    // scholarly work - a literal, grammatical rendering of each word in place - not an
                    // excerpt of any full translation, so they carry their own attribution.
                    VStack(alignment: .leading, spacing: 4) {
                        Divider()
                            .padding(.bottom, 4)
                        Text("Word-by-word meanings from the Quranic Arabic Corpus, via Quran.com. They render each word literally and in place, so they read differently from the flowing translation above.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 4)

                    BeginnerLettersSection(
                        styled: tajweedStyledWord,
                        word: word,
                        fontName: Settings.hafsUthmaniFontName,
                        fontSize: CGFloat(settings.fontArabicSize) + 8
                    )
                }
                .padding()
            }
            .navigationTitle("Word Meaning")
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

// MARK: - The riwayah word card

/// The word a reader tapped in a NON-Hafs riwayah. There is no gloss pack for these texts (the
/// meanings are Hafs-token-aligned), so the card's job is different: name the riwayah's own rules
/// on this word - what the colors mean and how the word is recited - and show the Hafs counterpart
/// underneath, aligned word-by-word through the ayah alignment.
struct RiwayahTappedWord: Identifiable {
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
        let rawText = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: tag)
        let ranges = WordTokens.ranges(in: rawText)
        let tokens = WordTokens.tokens(in: rawText)
        guard ranges.count == tokens.count else { return nil }

        var displayIndex = -1
        for (rawIndex, token) in tokens.enumerated() {
            let visible = !token.removingArabicDiacriticsAndSigns
                .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if !visible && settings.cleanArabicText { continue }
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

    /// Base-letter skeleton with hamza seats folded, so orthography differences (seatless qat',
    /// Maghribi wasl alefs) don't break the word matching.
    private static func skeleton(_ token: String) -> String {
        var out = ""
        for scalar in token.unicodeScalars {
            let v = scalar.value
            guard (0x0621...0x064A).contains(v) || v == 0x0671 || v == 0x0649
                    || v == 0x066E || v == 0x06CC || v == 0x067E
                    || v == 0x066F || v == 0x06A1 || v == 0x06BA else { continue }
            switch v {
            case 0x0671, 0x0622, 0x0623, 0x0625: out.append("ا")
            case 0x0624: out.append("و")
            case 0x0626: out.append("ي")
            case 0x0621: break
            default: out.append(Character(scalar))
            }
        }
        return out
    }

    /// The Hafs word(s) this riwayah word corresponds to, via the ayah alignment plus a token-level
    /// LCS over letter skeletons. A word absent from Hafs (or unmappable) returns nil - the card
    /// says so instead of guessing.
    private var hafsCounterpart: String? {
        guard let located = rawWord else { return nil }
        let quranData = QuranData.shared
        let span = QiraahComparison.alignment(surahID: surah.id, tag: tag, quranData: quranData)?
            .hafsRangeForRiwayah[ayah.id] ?? (ayah.id...ayah.id)
        var hafsTokens: [String] = []
        for n in span {
            guard let hafsAyah = quranData.ayah(surah: surah.id, ayah: n) else { continue }
            hafsTokens.append(contentsOf: WordTokens.tokens(
                in: hafsAyah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: "")
            ))
        }
        guard !hafsTokens.isEmpty else { return nil }

        let mine = WordTokens.tokens(in: located.text)
        let a = mine.map(Self.skeleton)
        let b = hafsTokens.map(Self.skeleton)

        // LCS table over the two token skeleton lists (ayahs are small - at most a few dozen words).
        var lcs = [[Int]](repeating: [Int](repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in stride(from: a.count - 1, through: 0, by: -1) {
            for j in stride(from: b.count - 1, through: 0, by: -1) {
                lcs[i][j] = a[i] == b[j] ? lcs[i + 1][j + 1] + 1 : max(lcs[i + 1][j], lcs[i][j + 1])
            }
        }
        // Walk the LCS, recording each matched pair.
        var matches: [(mine: Int, hafs: Int)] = []
        var i = 0, j = 0
        while i < a.count, j < b.count {
            if a[i] == b[j], lcs[i][j] == lcs[i + 1][j + 1] + 1 {
                matches.append((i, j)); i += 1; j += 1
            } else if lcs[i + 1][j] >= lcs[i][j + 1] {
                i += 1
            } else {
                j += 1
            }
        }
        if let exact = matches.first(where: { $0.mine == located.tokenIndex }) {
            return hafsTokens[exact.hafs]
        }
        // Unmatched (the word differs from Hafs): the Hafs words BETWEEN the nearest matched
        // neighbours are its counterpart - possibly several (a merged word), possibly none.
        let before = matches.last(where: { $0.mine < located.tokenIndex })
        let after = matches.first(where: { $0.mine > located.tokenIndex })
        let lo = before.map { $0.hafs + 1 } ?? 0
        let hi = after.map { $0.hafs } ?? hafsTokens.count
        guard lo < hi else { return nil }
        return hafsTokens[lo..<hi].joined(separator: " ")
    }

    private var riwayahFontName: String { settings.quranArabicFontName(for: tag) }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        if let styled = styledWord {
                            Text(styled)
                        } else {
                            Text(word)
                        }
                    }
                    .font(.custom(riwayahFontName, size: CGFloat(settings.fontArabicSize) + 16))
                    .arabicFontDesign(custom: true)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
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

                    // The Hafs counterpart, so the difference is visible side by side. Aligned
                    // word-by-word; a merged or dropped word shows its whole Hafs span.
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                            .padding(.bottom, 4)
                        Text("IN HAFS AN 'ASIM")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        if let hafs = hafsCounterpart {
                            Text(hafs)
                                .font(.custom(Settings.hafsUthmaniFontName, size: CGFloat(settings.fontArabicSize) + 6))
                                .arabicFontDesign(custom: true)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                            if Self.skeleton(hafs) == Self.skeleton(word) {
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

                    BeginnerLettersSection(
                        styled: styledWord,
                        word: word,
                        fontName: riwayahFontName,
                        fontSize: CGFloat(settings.fontArabicSize) + 8
                    )
                }
                .padding()
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
