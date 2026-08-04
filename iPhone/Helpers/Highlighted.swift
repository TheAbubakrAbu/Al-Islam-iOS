import SwiftUI

struct HighlightedSnippet: View {
    @ObservedObject var settings = Settings.shared

    let source: String
    let term: String
    let font: Font
    let accent: Color
    let fg: Color
    var preStyledSource: AttributedString? = nil
    var beginnerMode: Bool = false
    var trailingSuffix: String = ""
    var trailingSuffixFont: Font? = nil
    var trailingSuffixColor: Color? = nil
    var lineLimit: Int? = nil
    /// With `lineLimit`, also RESERVE the clamped height (iOS 16+/watchOS 9+; plain clamp below): a
    /// one-line snippet occupies the same box as a full one, so preview cards line up. NOTE: an outer
    /// `.lineLimit` can never do this job - the unconditional `.lineLimit(lineLimit)` below sets the
    /// innermost value (nil = unlimited), which silently overrides whatever a caller wraps around this.
    var reservesSpace: Bool = false
    var highlightAllahNames: Bool = false
    /// When `true`, this field is guaranteed to show at least one highlight: if no confident match is found
    /// the fuzzy last-resorts (Arabic partial-prefix, closest/longest word) kick in so the user always sees
    /// *something*. Meant for ayah search, and only for the field(s) that actually matched the query.
    ///
    /// When `false` (the default, used by Surah rows and anywhere a single query is shown against several
    /// fields side-by-side), only high-confidence matches are colored - exact substring, a full
    /// alef-insensitive Arabic match, or a phrase-prefix. A field that doesn't really contain the term is
    /// left un-highlighted, so a query that matched only the transliteration doesn't also paint the English
    /// name and the Arabic name.
    var guaranteeMatch: Bool = false
    /// The classical Quranic faces (Uthmani/IndoPak) map Arabic punctuation like "،" to ornament glyphs.
    /// Set this to the text's point size to render commas and semicolons in the system face instead.
    var basicFontForCommas: CGFloat? = nil

    private static let commaCharacters: Set<Character> = ["،", "؛", ","]

    /// source → contains-a-comma, memoized: this gate runs in `body` for every Arabic snippet that
    /// passes `basicFontForCommas`, and the O(n) character scan repeated on every re-render of every
    /// visible row. A string's comma content never changes, so it is a perfect cache key.
    private static let commaPresenceCache: NSCache<NSString, NSNumber> = {
        let c = NSCache<NSString, NSNumber>()
        c.countLimit = 10_000
        return c
    }()

    private var sourceHasCommas: Bool {
        let key = source as NSString
        if let cached = Self.commaPresenceCache.object(forKey: key) { return cached.boolValue }
        let has = source.contains(where: { Self.commaCharacters.contains($0) })
        Self.commaPresenceCache.setObject(NSNumber(value: has), forKey: key)
        return has
    }

    var body: some View {
        let resolvedSearchTerm = searchTerm
        let needsSearchHighlight = !resolvedSearchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let needsCommaWork = basicFontForCommas != nil && sourceHasCommas
        let needsAttributedWork = needsSearchHighlight || highlightAllahNames || preStyledSource != nil || needsCommaWork
        let suffixText = Text(trailingSuffix)
            .font(trailingSuffixFont ?? font)
            .foregroundColor(trailingSuffixColor ?? fg)

        if needsAttributedWork {
            // When highlighting a search term, base the attributed text on the PLAIN `source` - never a
            // `preStyledSource` (e.g. tajweed-colored Arabic). The matched ranges are `String.Index` ranges
            // into `source`; a preStyledSource can have a different character layout (clean text / removed
            // dots / beginner spacing), so converting those indices into it silently fails (`Index(_, within:)`
            // returns nil) and a real - even exact - match never gets colored. On a matched row the search
            // highlight takes priority over tajweed, matching how text-search results are shown elsewhere.
            let base = needsSearchHighlight ? plainSourceAttributed() : baseAttributedText()
            let highlightedText = applyBasicFontToCommas(
                highlightAllahIfNeeded(
                    source: source,
                    baseAttributed: highlight(
                        source: source,
                        baseAttributed: base,
                        term: resolvedSearchTerm
                    )
                )
            )

            limited(Text("\(Text(highlightedText))\(suffixText)"))
        } else {
            limited(Text("\(Text(source).foregroundColor(fg))\(suffixText)"))
        }
    }

    /// The one place the line clamp lands, so `reservesSpace` and the plain clamp can't drift apart.
    @ViewBuilder
    private func limited(_ text: Text) -> some View {
        if reservesSpace, let lineLimit, #available(iOS 16.0, watchOS 9.0, *) {
            text.font(font).lineLimit(lineLimit, reservesSpace: true)
        } else {
            text.font(font).lineLimit(lineLimit)
        }
    }

    private var searchTerm: String {
        beginnerMode ? term.map(String.init).joined(separator: " ") : term
    }

    /// Re-fonts every comma/semicolon run to the rounded system face - see `basicFontForCommas`.
    ///
    /// Two-phase on purpose: the old single pass kept walking with indices captured BEFORE each attribute
    /// write, and AttributedString documents its indices as invalidated by ANY mutation (attribute-only
    /// included). Collecting character offsets first, then re-deriving fresh indices from the current
    /// string per write, never uses an index across a mutation. Comma counts are tiny, so the
    /// offset-walk cost is noise. Scans the attributed string itself (not `source`) because a
    /// `preStyledSource` base can have a different character layout than `source`.
    private func applyBasicFontToCommas(_ attributed: AttributedString) -> AttributedString {
        guard let size = basicFontForCommas, sourceHasCommas else { return attributed }
        var result = attributed

        var commaOffsets: [Int] = []
        var index = result.startIndex
        var offset = 0
        while index < result.endIndex {
            if Self.commaCharacters.contains(result.characters[index]) {
                commaOffsets.append(offset)
            }
            index = result.characters.index(after: index)
            offset += 1
        }

        for commaOffset in commaOffsets {
            let start = result.characters.index(result.startIndex, offsetBy: commaOffset)
            let end = result.characters.index(after: start)
            result[start..<end].font = .system(size: size, design: .rounded)
        }
        return result
    }

    // nonisolated: statics on a View struct inherit @MainActor, but the prewarm path (a detached task)
    // reads these - the fold tables are immutable and NSCache is thread-safe, so cross-thread access is
    // the design, not an accident. This is what silences the "main actor-isolated ... can not be
    // referenced from a nonisolated context" warnings on every target that compiles this file.
    nonisolated private static let englishHighlightStripSet: CharacterSet = {
        CharacterSet.punctuationCharacters.union(.symbols).union(.nonBaseCharacters)
    }()

    // MARK: - Caches

    private final class SourceNormEntry: NSObject {
        let normalizedSource: String
        /// UTF-16 offsets, NOT `String.Index`: cache entries are keyed by string CONTENT, so a hit can
        /// serve an equal-content instance different from the one the entry was built on - and indices
        /// are only defined for their own instance. Offsets are instance-free; `indices(atUTF16Offsets:in:)`
        /// rebuilds real indices for the exact string being rendered.
        let mapUTF16: [Int]
        init(_ n: String, _ m: [Int]) { normalizedSource = n; mapUTF16 = m }
    }

    private final class RangeEntry: NSObject {
        /// (lower, upper) UTF-16 offset pairs - instance-free, same reason as `SourceNormEntry.mapUTF16`.
        let spans: [(Int, Int)]
        init(_ s: [(Int, Int)]) { spans = s }
    }

    /// Rebuilds `String.Index` values for THIS `source` instance from stored UTF-16 offsets
    /// (non-decreasing; duplicates allowed - a collapsed space maps to the same character as the letter
    /// after it). One O(n) walk. Returns nil if any offset fails to land on a character boundary of this
    /// instance - impossible for equal content, but callers treat nil as a cache miss and recompute
    /// rather than trust the entry.
    nonisolated private static func indices(atUTF16Offsets offsets: [Int], in source: String) -> [String.Index]? {
        var result: [String.Index] = []
        result.reserveCapacity(offsets.count)
        var i = 0
        var utf16Pos = 0
        var idx = source.startIndex
        while i < offsets.count {
            if offsets[i] == utf16Pos {
                result.append(idx)
                i += 1
                continue
            }
            guard offsets[i] > utf16Pos, idx < source.endIndex else { return nil }
            let next = source.index(after: idx)
            utf16Pos += source.utf16.distance(from: idx, to: next)
            idx = next
        }
        return result
    }

    /// The stored-span twin: materializes `Range<String.Index>` values for THIS instance. Nil means an
    /// offset didn't line up (callers recompute fresh).
    nonisolated private static func ranges(fromUTF16Spans spans: [(Int, Int)], in source: String) -> [Range<String.Index>]? {
        guard !spans.isEmpty else { return [] }
        let wanted = Set(spans.flatMap { [$0.0, $0.1] }).sorted()
        guard let landed = indices(atUTF16Offsets: wanted, in: source) else { return nil }
        let lookup = Dictionary(uniqueKeysWithValues: zip(wanted, landed))
        var out: [Range<String.Index>] = []
        out.reserveCapacity(spans.count)
        for (lo, hi) in spans {
            guard let l = lookup[lo], let h = lookup[hi], l < h else { return nil }
            out.append(l..<h)
        }
        return out
    }

    /// Converts a range on THIS instance into instance-free UTF-16 offsets for storage.
    nonisolated private static func utf16Span(of range: Range<String.Index>, in source: String) -> (Int, Int) {
        (source.utf16.distance(from: source.startIndex, to: range.lowerBound),
         source.utf16.distance(from: source.startIndex, to: range.upperBound))
    }

    /// source → (normalizedSource, mapUTF16): amortises the O(n×k) per-character normalization.
    /// nonisolated(unsafe): NSCache is thread-safe by contract; the prewarm fills it off-main.
    nonisolated(unsafe) private static let sourceNormCache: NSCache<NSString, SourceNormEntry> = {
        let c = NSCache<NSString, SourceNormEntry>()
        c.countLimit = 7_000
        return c
    }()

    /// "source\0normalizedTerm" → matched ranges in original source: amortises the range search.
    private static let matchRangeCache: NSCache<NSString, RangeEntry> = {
        let c = NSCache<NSString, RangeEntry>()
        c.countLimit = 10_000
        return c
    }()

    /// source → Allah highlight ranges: amortises the O(n) per-render Allah scan.
    private static let allahRangeCache: NSCache<NSString, RangeEntry> = {
        let c = NSCache<NSString, RangeEntry>()
        c.countLimit = 7_000
        return c
    }()

    private func normalizeEnglishForHighlight(_ text: String, trimWhitespace: Bool) -> String {
        Self.normalizeEnglishForHighlightText(text, trimWhitespace: trimWhitespace)
    }

    /// The SEARCH-side twin of the highlight normalization: same punctuation/symbol strip + lowercase.
    /// Hadith search folds BOTH its index and its queries through this, so "aishah" matches "'A'ishah"
    /// exactly where the highlighter would color it - the matcher used to be stricter than the
    /// highlighter (plain `lowercased()`), silently missing apostrophe/diacritic narrator names.
    nonisolated static func foldedEnglishForSearch(_ text: String) -> String {
        normalizeEnglishForHighlightText(text, trimWhitespace: false)
    }

    nonisolated static func normalizeEnglishForHighlightText(_ text: String, trimWhitespace: Bool) -> String {
        var cleaned = String(text.unicodeScalars
            .filter { !Self.englishHighlightStripSet.contains($0) }
        ).lowercased()

        if trimWhitespace {
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }

    /// Populates the fold cache for `sources` - safe to call from ANY thread (NSCache is thread-safe, and the
    /// fold reads only immutable static tables). The search pipeline calls this from its background task with
    /// the exact strings the result rows are about to render, so each row's first body evaluation is a cache
    /// hit instead of paying the O(source × fold) cost on the main thread.
    // nonisolated: pure string work over thread-safe NSCache, called from a detached task off-main -
    // View statics otherwise inherit @MainActor and Swift 6 makes that call an error.
    nonisolated static func prewarmNormalization(of sources: [String]) {
        for source in sources where !source.isEmpty {
            let key = source as NSString
            guard sourceNormCache.object(forKey: key) == nil else { continue }
            let built = normalizedSourceAndMap(for: source)
            sourceNormCache.setObject(SourceNormEntry(built.normalized, built.mapUTF16), forKey: key)
        }
    }

    private func normalizeForSearch(_ text: String, trimWhitespace: Bool) -> String {
        Self.normalizeForSearchText(text, trimWhitespace: trimWhitespace)
    }

    /// Static so the search pipeline can run it off the main thread (see `prewarmNormalization`). Reads only
    /// `Settings.shared.cleanSearch`, which is a pure scalar-map fold - thread-safe.
    nonisolated static func normalizeForSearchText(_ text: String, trimWhitespace: Bool) -> String {
        // Strip search operators (`# ^ % $ …`) first so a query like `#الله` or `^Allah%` highlights the
        // residual word instead of failing to match (the source text never contains these characters).
        let base = text.removingAyahSearchOperators
        if !base.containsArabicLetters {
            return Self.normalizeEnglishForHighlightText(base, trimWhitespace: trimWhitespace)
        }
        return Settings.shared.cleanSearch(base, whitespace: trimWhitespace)
            .removingArabicDiacriticsAndSigns
    }

    private func normalizeForAllahHighlight(_ text: String) -> String {
        settings.cleanSearch(text.removingArabicDiacriticsAndSigns, whitespace: false)
    }

    private func baseAttributedText() -> AttributedString {
        if let preStyledSource {
            return preStyledSource
        }

        return plainSourceAttributed()
    }

    /// A plain attributed copy of `source` with the base foreground color - indices always align with
    /// `source`, so highlight ranges computed against `source` map cleanly onto it.
    private func plainSourceAttributed() -> AttributedString {
        var attributed = AttributedString(source)
        attributed.foregroundColor = fg
        return attributed
    }

    private func highlight(source: String, baseAttributed: AttributedString, term: String) -> AttributedString {
        var attributed = baseAttributed

        let normalizedTerm = normalizeForSearch(term, trimWhitespace: true)
        guard !normalizedTerm.isEmpty else { return attributed }

        // --- Step 1: normalizedSource + UTF-16 map, cached per source CONTENT ---
        let sourceKey = source as NSString
        let normEntry: SourceNormEntry
        if let cached = Self.sourceNormCache.object(forKey: sourceKey) {
            normEntry = cached
        } else {
            let built = Self.normalizedSourceAndMap(for: source)
            normEntry = SourceNormEntry(built.normalized, built.mapUTF16)
            Self.sourceNormCache.setObject(normEntry, forKey: sourceKey)
        }

        // --- Step 2: matched ranges in original source, cached per (source, normalizedTerm, guarantee) ---
        // `guaranteeMatch` changes which fallbacks run, so it must be part of the key - otherwise the same
        // source+term shown once as a matched ayah field and once as a non-matching sibling would collide.
        // Cached as UTF-16 spans and materialized for THIS instance; a nil materialization (offsets that
        // don't land on this instance's character boundaries - impossible for equal content) falls through
        // to a fresh compute instead of being trusted.
        let matchKey = "\(guaranteeMatch ? "1" : "0")\u{0000}\(source)\u{0000}\(normalizedTerm)" as NSString
        var matchedRanges: [Range<String.Index>]? = nil
        if let cached = Self.matchRangeCache.object(forKey: matchKey) {
            matchedRanges = Self.ranges(fromUTF16Spans: cached.spans, in: source)
        }
        if matchedRanges == nil {
            // Instance-true indices for the cached fold; if the entry somehow doesn't fit this instance,
            // rebuild the fold fresh - the fresh offsets fit by construction.
            let normalizedSource: String
            let indexMap: [String.Index]
            if let materialized = Self.indices(atUTF16Offsets: normEntry.mapUTF16, in: source) {
                normalizedSource = normEntry.normalizedSource
                indexMap = materialized
            } else {
                let built = Self.normalizedSourceAndMap(for: source)
                normalizedSource = built.normalized
                indexMap = Self.indices(atUTF16Offsets: built.mapUTF16, in: source) ?? []
            }

            let ranges = Self.matchRanges(
                in: source,
                normalizedSource: normalizedSource,
                indexMap: indexMap,
                normalizedTerm: normalizedTerm,
                guaranteeMatch: guaranteeMatch
            )
            Self.matchRangeCache.setObject(
                RangeEntry(ranges.map { Self.utf16Span(of: $0, in: source) }),
                forKey: matchKey
            )
            matchedRanges = ranges
        }

        // --- Step 3: apply accent colour to each matched range ---
        for range in matchedRanges ?? [] {
            if let start = AttributedString.Index(range.lowerBound, within: attributed),
               let end = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[start..<end].foregroundColor = accent
            }
        }

        return attributed
    }

    /// The canonical match-range ladder, shared by the list snippet (`highlight`, via its caches) and the
    /// mushaf page reader so BOTH surfaces color the same substrings for the same query: exact normalized
    /// substring → Arabic alef-insensitive skeleton → phrase-prefix → (only with `guaranteeMatch`) the
    /// closest-word safety net. The caller supplies the already-folded source + index map so a cached fold
    /// is reused rather than recomputed.
    nonisolated static func matchRanges(
        in source: String,
        normalizedSource: String,
        indexMap: [String.Index],
        normalizedTerm: String,
        guaranteeMatch: Bool
    ) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStart = normalizedSource.startIndex
        while searchStart < normalizedSource.endIndex,
              let matchRange = normalizedSource.range(of: normalizedTerm, range: searchStart..<normalizedSource.endIndex) {
            if let orig = originalRange(
                in: source,
                normalizedSource: normalizedSource,
                matchRange: matchRange,
                indexMap: indexMap
            ) {
                ranges.append(orig)
            }
            searchStart = matchRange.upperBound
        }
        // Arabic fallback: an alef-insensitive match (so الرحمن / الرحمان / الرحمٰن all match), with a
        // longest-prefix partial match so something is always highlighted even when the exact phrase
        // isn't present. This is why exact substring matching alone was missing most Arabic terms.
        if ranges.isEmpty, source.containsArabicLetters {
            ranges = arabicLooseRanges(
                source: source,
                normalizedSource: normalizedSource,
                indexMap: indexMap,
                normalizedTerm: normalizedTerm,
                guaranteeMatch: guaranteeMatch
            )
        }
        // Phrase-prefix fallback for BOTH scripts: highlights consecutive words where the leading words
        // match and the final word is a prefix (e.g. "those who believ" → "those who believe"). This is
        // the same "close match" rule the verse search itself uses, so English close matches - which
        // previously highlighted nothing - now get colored like the Arabic ones.
        if ranges.isEmpty {
            ranges = phrasePrefixRanges(
                in: source,
                normalizedSource: normalizedSource,
                normalizedTerm: normalizedTerm,
                indexMap: indexMap
            )
        }
        // Final safety net - ONLY when this field is expected to contain the match (`guaranteeMatch`, i.e.
        // ayah search on the field that actually matched). If nothing matched yet, highlight the closest
        // word(s) in THIS field so the user always sees at least one thing for their query. It works on the
        // original words normalized individually, so it doesn't depend on the whole-string index alignment
        // the paths above need - which can silently fail on heavily-marked Arabic and leave a real match
        // un-highlighted. Skipped by default so a query that matched a sibling field doesn't force a
        // spurious highlight here.
        if ranges.isEmpty, guaranteeMatch {
            ranges = closestMatchRanges(in: source, normalizedTerm: normalizedTerm)
        }
        return ranges
    }

    /// Convenience for callers without a cached fold (the mushaf page reader): folds `source` fresh, then
    /// runs the shared ladder. Returns ranges into `source`, empty when the term genuinely isn't present
    /// (so an English query on an Arabic page highlights nothing rather than washing the whole ayah).
    nonisolated static func matchRanges(
        of term: String,
        in source: String,
        guaranteeMatch: Bool = false
    ) -> [Range<String.Index>] {
        let normalizedTerm = normalizeForSearchText(term, trimWhitespace: true)
        guard !normalizedTerm.isEmpty else { return [] }
        let built = normalizedSourceAndMap(for: source)
        guard let indexMap = indices(atUTF16Offsets: built.mapUTF16, in: source) else { return [] }
        return matchRanges(
            in: source,
            normalizedSource: built.normalized,
            indexMap: indexMap,
            normalizedTerm: normalizedTerm,
            guaranteeMatch: guaranteeMatch
        )
    }

    nonisolated private static func phrasePrefixRanges(
        in source: String,
        normalizedSource: String,
        normalizedTerm: String,
        indexMap: [String.Index]
    ) -> [Range<String.Index>] {
        let queryTokens = normalizedTerm
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !queryTokens.isEmpty else { return [] }

        let sourceTokens = normalizedTokenRanges(in: normalizedSource)
        guard sourceTokens.count >= queryTokens.count else { return [] }

        var ranges: [Range<String.Index>] = []
        for start in 0...(sourceTokens.count - queryTokens.count) {
            var matched = true

            for offset in queryTokens.indices {
                let tokenRange = sourceTokens[start + offset]
                let sourceToken = String(normalizedSource[tokenRange])
                let queryToken = queryTokens[offset]

                if offset == queryTokens.count - 1 {
                    if !sourceToken.hasPrefix(queryToken) {
                        matched = false
                        break
                    }
                } else if sourceToken != queryToken {
                    matched = false
                    break
                }
            }

            guard matched else { continue }

            let lower = sourceTokens[start].lowerBound
            let lastTokenRange = sourceTokens[start + queryTokens.count - 1]
            let lastToken = String(normalizedSource[lastTokenRange])
            let upper: String.Index
            if lastToken == queryTokens.last {
                upper = lastTokenRange.upperBound
            } else {
                upper = normalizedSource.index(lastTokenRange.lowerBound, offsetBy: queryTokens.last?.count ?? 0)
            }

            if let orig = originalRange(
                in: source,
                normalizedSource: normalizedSource,
                matchRange: lower..<upper,
                indexMap: indexMap
            ) {
                ranges.append(orig)
            }
        }

        return ranges
    }

    /// Alef-insensitive matching with a longest-prefix partial fallback.
    ///
    /// `normalizeForSearch` already folds the dagger alef (ٰ) to a plain alef, so dropping every "ا" from
    /// both the source and the term produces a skeleton where الرحمن, الرحمان and الرحمٰن all compare equal.
    /// The kept-character → source-index map lets a skeleton match map back to a contiguous original range.
    /// If the whole term skeleton isn't found, the longest leading chunk (≥ 2 letters) is highlighted - but
    /// only when `guaranteeMatch` is set, so this "always sees *something*" fuzziness is limited to fields
    /// that are meant to contain the match (ayah search) and doesn't leak onto side-by-side sibling fields.
    nonisolated private static func arabicLooseRanges(
        source: String,
        normalizedSource: String,
        indexMap: [String.Index],
        normalizedTerm: String,
        guaranteeMatch: Bool
    ) -> [Range<String.Index>] {
        guard indexMap.count == normalizedSource.count else { return [] }

        var skeleton = ""
        var skeletonMap: [String.Index] = []
        skeleton.reserveCapacity(normalizedSource.count)
        skeletonMap.reserveCapacity(normalizedSource.count)
        var k = 0
        for ch in normalizedSource {
            if ch != "ا" {
                skeleton.append(ch)
                skeletonMap.append(indexMap[k])
            }
            k += 1
        }

        var termSkeleton = ""
        for ch in normalizedTerm where ch != "ا" { termSkeleton.append(ch) }
        guard termSkeleton.count >= 2, !skeleton.isEmpty else { return [] }

        func mapRange(_ r: Range<String.Index>) -> Range<String.Index>? {
            let lo = skeleton.distance(from: skeleton.startIndex, to: r.lowerBound)
            let hi = skeleton.distance(from: skeleton.startIndex, to: r.upperBound)
            guard lo >= 0, hi > lo, hi - 1 < skeletonMap.count else { return nil }
            var start = skeletonMap[lo]
            let end = source.index(after: skeletonMap[hi - 1])
            // Pull a directly-preceding alef (e.g. the ا of الـ) into the highlight so it reads naturally.
            if start > source.startIndex {
                let prev = source.index(before: start)
                if Self.normalizeForSearchText(String(source[prev]), trimWhitespace: false) == "ا" { start = prev }
            }
            return start..<end
        }

        // Full alef-insensitive substring matches.
        var ranges: [Range<String.Index>] = []
        var searchStart = skeleton.startIndex
        while searchStart < skeleton.endIndex,
              let m = skeleton.range(of: termSkeleton, range: searchStart..<skeleton.endIndex) {
            if let mapped = mapRange(m) { ranges.append(mapped) }
            searchStart = m.upperBound
        }
        if !ranges.isEmpty { return ranges }

        // Longest-prefix partial: highlight the longest leading chunk of the term we can find. This is a
        // fuzzy guess (it colors a fragment even when the full term isn't present), so it's reserved for
        // fields that are supposed to contain the match - otherwise a two-letter overlap on an unrelated
        // sibling field would light up.
        guard guaranteeMatch else { return [] }
        var prefixLen = termSkeleton.count - 1
        while prefixLen >= 2 {
            let prefix = String(termSkeleton.prefix(prefixLen))
            if let m = skeleton.range(of: prefix), let mapped = mapRange(m) {
                return [mapped]
            }
            prefixLen -= 1
        }
        return []
    }

    /// Guarantees at least one highlight: scans the original words (each normalized on its own, so there's
    /// no fragile whole-string alignment), scores them against the query, and returns every word that
    /// contains the query - or, if none do, the single closest word. This is the "something is always
    /// highlighted, the closest match" behavior.
    nonisolated private static func closestMatchRanges(in source: String, normalizedTerm: String) -> [Range<String.Index>] {
        // Match against the most specific (longest) query word.
        guard let primaryQuery = normalizedTerm
            .split(separator: " ")
            .map(String.init)
            .filter({ !$0.isEmpty })
            .max(by: { $0.count < $1.count })
        else { return [] }

        var scored: [(range: Range<String.Index>, score: Int)] = []
        var cursor = source.startIndex
        while cursor < source.endIndex {
            while cursor < source.endIndex, source[cursor].isWhitespace { cursor = source.index(after: cursor) }
            guard cursor < source.endIndex else { break }
            let start = cursor
            while cursor < source.endIndex, !source[cursor].isWhitespace { cursor = source.index(after: cursor) }
            let tokenRange = start..<cursor

            let normToken = Self.normalizeForSearchText(String(source[tokenRange]), trimWhitespace: true)
            guard !normToken.isEmpty else { continue }
            let score = wordMatchScore(word: normToken, query: primaryQuery)
            if score > 0 { scored.append((tokenRange, score)) }
        }

        guard let best = scored.max(by: { $0.score < $1.score }) else {
            // Absolute last resort. The row only passes `term` when its field matched the query, so we should
            // always show *something* - even a 1% match. If no word scored at all (a normalization mismatch
            // between the verse-search index and this highlighter), highlight the longest word so the user
            // never sees a "matched but nothing colored" row.
            return longestWordRange(in: source).map { [$0] } ?? []
        }
        // Words that actually contain the query (or equal it) are all highlighted; otherwise fall back to
        // the single closest word so there's always exactly something.
        let strong = scored.filter { $0.score >= 70 }.map(\.range)
        return strong.isEmpty ? [best.range] : strong
    }

    /// The range of the longest whitespace-delimited word in `source` (the guaranteed-something fallback).
    nonisolated private static func longestWordRange(in source: String) -> Range<String.Index>? {
        var best: Range<String.Index>? = nil
        var bestLen = 0
        var cursor = source.startIndex
        while cursor < source.endIndex {
            while cursor < source.endIndex, source[cursor].isWhitespace { cursor = source.index(after: cursor) }
            guard cursor < source.endIndex else { break }
            let start = cursor
            while cursor < source.endIndex, !source[cursor].isWhitespace { cursor = source.index(after: cursor) }
            let len = source.distance(from: start, to: cursor)
            if len > bestLen { bestLen = len; best = start..<cursor }
        }
        return best
    }

    nonisolated private static func wordMatchScore(word: String, query: String) -> Int {
        if word == query { return 100 }
        if word.contains(query) { return 70 }
        if query.contains(word) { return 60 }
        let lcp = commonPrefixLength(word, query)
        return lcp >= 2 ? lcp : 0
    }

    nonisolated private static func commonPrefixLength(_ a: String, _ b: String) -> Int {
        var count = 0
        var i = a.startIndex
        var j = b.startIndex
        while i < a.endIndex, j < b.endIndex, a[i] == b[j] {
            count += 1
            i = a.index(after: i)
            j = b.index(after: j)
        }
        return count
    }

    nonisolated private static func normalizedTokenRanges(in text: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var cursor = text.startIndex

        while cursor < text.endIndex {
            while cursor < text.endIndex, text[cursor].isWhitespace {
                cursor = text.index(after: cursor)
            }
            guard cursor < text.endIndex else { break }

            let start = cursor
            while cursor < text.endIndex, !text[cursor].isWhitespace {
                cursor = text.index(after: cursor)
            }
            ranges.append(start..<cursor)
        }

        return ranges
    }

    private func highlightAllahIfNeeded(source: String, baseAttributed: AttributedString) -> AttributedString {
        guard highlightAllahNames else { return baseAttributed }

        var attributed = baseAttributed

        if !source.containsArabicLetters {
            highlightEnglishAllah(source: source, attributed: &attributed)
            return attributed
        }

        highlightArabicAllah(source: source, attributed: &attributed)

        return attributed
    }

    private func highlightEnglishAllah(source: String, attributed: inout AttributedString) {
        var searchStart = source.startIndex
        while searchStart < source.endIndex,
              let matchRange = source.range(
                of: "Allah",
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchStart..<source.endIndex
              ) {
            if let start = AttributedString.Index(matchRange.lowerBound, within: attributed),
               let end = AttributedString.Index(matchRange.upperBound, within: attributed) {
                attributed[start..<end].foregroundColor = .red
            }

            searchStart = matchRange.upperBound
        }
    }

    private func highlightArabicAllah(source: String, attributed: inout AttributedString) {
        let cacheKey = source as NSString
        let ranges: [Range<String.Index>]
        // Cached as instance-free UTF-16 spans; a nil materialization (can't happen for equal content)
        // falls through to a fresh scan rather than being trusted.
        if let cached = Self.allahRangeCache.object(forKey: cacheKey),
           let materialized = Self.ranges(fromUTF16Spans: cached.spans, in: source) {
            ranges = materialized
        } else {
            var found: [Range<String.Index>] = []
            for start in source.indices {
                if let range = arabicAllahRange(startingAt: start, in: source) {
                    found.append(range)
                }
            }
            Self.allahRangeCache.setObject(
                RangeEntry(found.map { Self.utf16Span(of: $0, in: source) }),
                forKey: cacheKey
            )
            ranges = found
        }

        for range in ranges {
            if let start = AttributedString.Index(range.lowerBound, within: attributed),
               let end = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[start..<end].foregroundColor = .red
            }
        }
    }

    private func arabicAllahRange(startingAt start: String.Index, in source: String) -> Range<String.Index>? {
        if source[start].allahBase?.isAllahAlif == true,
           let afterAlif = nextNonMarkIndex(after: start, in: source),
           source[afterAlif].allahBase == "ل",
           let secondLam = nextNonMarkIndex(after: afterAlif, in: source),
           source[secondLam].allahBase == "ل",
           let heh = nextNonMarkIndex(after: secondLam, in: source),
           source[heh].allahBase == "ه" {
            return start..<rangeUpperBound(afterBaseAt: heh, in: source)
        }

        if source[start].allahBase == "ل",
           let secondLam = nextNonMarkIndex(after: start, in: source),
           source[secondLam].allahBase == "ل",
           let heh = nextNonMarkIndex(after: secondLam, in: source),
           source[heh].allahBase == "ه" {
            return start..<rangeUpperBound(afterBaseAt: heh, in: source)
        }

        return nil
    }

    private func nextNonMarkIndex(after index: String.Index, in source: String) -> String.Index? {
        var cursor = source.index(after: index)
        while cursor < source.endIndex {
            // Stop at a word boundary: the letters of "Allah" (ل + ل + ه) must all be in the same word.
            // Skipping whitespace here wrongly matched sequences like سَوَّلَ لَهُمۡ (لـ + لـه across a space).
            if source[cursor].isWhitespace {
                return nil
            }
            if !source[cursor].isArabicMark {
                return cursor
            }
            cursor = source.index(after: cursor)
        }
        return nil
    }

    private func rangeUpperBound(afterBaseAt index: String.Index, in source: String) -> String.Index {
        guard var scalarCursor = index.samePosition(in: source.unicodeScalars) else {
            return source.index(after: index)
        }

        var foundBase = false
        while scalarCursor < source.unicodeScalars.endIndex {
            let scalar = source.unicodeScalars[scalarCursor]
            if !foundBase {
                foundBase = scalar.value == 0x0647
                scalarCursor = source.unicodeScalars.index(after: scalarCursor)
                continue
            }
            guard scalar.isArabicAllahHighlightMarkScalar else { break }
            scalarCursor = source.unicodeScalars.index(after: scalarCursor)
        }

        return scalarCursor.samePosition(in: source) ?? source.index(after: index)
    }

    /// Builds the folded source and its index map TOGETHER, in one pass, with the same whitespace collapsing
    /// the query's fold applies.
    ///
    /// They used to be built by two different code paths: the folded string by folding the whole source at
    /// once (which collapses whitespace runs and drops leading/trailing whitespace), and the map by folding
    /// one character at a time (which counts every whitespace character). Any source with a doubled space, a
    /// leading space, or beginner-mode letter spacing made the two lengths disagree - and the mapper treats a
    /// length mismatch as corruption and refuses to map, so EVERY highlight on that row silently vanished.
    /// That was the "Arabic highlighting just doesn't work sometimes" bug. Built together, the lengths agree
    /// by construction.
    nonisolated static func normalizedSourceAndMap(for source: String) -> (normalized: String, mapUTF16: [Int]) {
        var normalized = ""
        var map: [Int] = []
        map.reserveCapacity(source.count)
        var pendingSpace = false
        var utf16Pos = 0

        for idx in source.indices {
            let next = source.index(after: idx)
            let piece = Self.normalizeForSearchText(String(source[idx..<next]), trimWhitespace: false)
            for ch in piece {
                if ch.isWhitespace {
                    // Collapse runs, and drop leading whitespace outright - exactly what the query's fold does.
                    pendingSpace = !normalized.isEmpty
                } else {
                    if pendingSpace {
                        normalized.append(" ")
                        map.append(utf16Pos)
                        pendingSpace = false
                    }
                    normalized.append(ch)
                    map.append(utf16Pos)
                }
            }
            utf16Pos += source.utf16.distance(from: idx, to: next)
        }
        // Trailing whitespace was never emitted, matching the query's trim.
        return (normalized, map)
    }

    nonisolated private static func originalRange(
        in source: String,
        normalizedSource: String,
        matchRange: Range<String.Index>,
        indexMap: [String.Index]
    ) -> Range<String.Index>? {
        guard indexMap.count == normalizedSource.count else { return nil }

        let lowerOffset = normalizedSource.distance(from: normalizedSource.startIndex, to: matchRange.lowerBound)
        let upperOffset = normalizedSource.distance(from: normalizedSource.startIndex, to: matchRange.upperBound)

        guard lowerOffset >= 0,
              upperOffset > lowerOffset,
              lowerOffset < indexMap.count,
              upperOffset - 1 < indexMap.count else {
            return nil
        }

        let start = indexMap[lowerOffset]
        let lastMatched = indexMap[upperOffset - 1]
        var end = source.index(after: lastMatched)

        // A cluster that folds to nothing (a standalone tashkeel or Quranic sign written as its own grapheme)
        // belongs to the word it follows. Left outside the range, the word tints in the accent while its final
        // mark stays in the base color - the "highlight stops one mark short" artifact on Arabic. Absorb them.
        while end < source.endIndex {
            let next = source.index(after: end)
            let cluster = source[end..<next]
            guard cluster.first?.isWhitespace != true,
                  Self.normalizeForSearchText(String(cluster), trimWhitespace: false).isEmpty else { break }
            end = next
        }

        return start..<end
    }

}

private extension Character {
    var allahBase: Character? {
        for scalar in unicodeScalars where !scalar.isArabicMarkScalar {
            switch scalar.value {
            case 0x0627, 0x0671:
                return "ا"
            case 0x0644:
                return "ل"
            case 0x0647:
                return "ه"
            default:
                continue
            }
        }

        return nil
    }

    var isAllahAlif: Bool {
        self == "ا"
    }

    var isArabicMark: Bool {
        unicodeScalars.allSatisfy(\.isArabicMarkScalar)
    }

    var isArabicAllahHighlightMark: Bool {
        unicodeScalars.allSatisfy(\.isArabicAllahHighlightMarkScalar)
    }
}

private extension UnicodeScalar {
    var isArabicMarkScalar: Bool {
        switch value {
        case 0x0610...0x061A,
             0x064B...0x065F,
             0x0670,
             0x06D6...0x06ED:
            return true
        default:
            return false
        }
    }

    var isArabicAllahHighlightMarkScalar: Bool {
        switch value {
        case 0x0610...0x061A,
             0x064B...0x065F,
             0x0670:
            return true
        default:
            return false
        }
    }
}

extension String {
    var containsArabicLetters: Bool {
        unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x0600...0x06FF,
                 0x0750...0x077F,
                 0x08A0...0x08FF,
                 0xFB50...0xFDFF,
                 0xFE70...0xFEFF,
                 0x1EE00...0x1EEFF:
                return true
            default:
                return false
            }
        }
    }
}
