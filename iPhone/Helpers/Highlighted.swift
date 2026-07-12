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

    var body: some View {
        let resolvedSearchTerm = searchTerm
        let needsSearchHighlight = !resolvedSearchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let needsAttributedWork = needsSearchHighlight || highlightAllahNames || preStyledSource != nil
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
            let highlightedText = highlightAllahIfNeeded(
                source: source,
                baseAttributed: highlight(
                    source: source,
                    baseAttributed: base,
                    term: resolvedSearchTerm
                )
            )

            Text("\(Text(highlightedText))\(suffixText)")
                .font(font)
                .lineLimit(lineLimit)
        } else {
            Text("\(Text(source).foregroundColor(fg))\(suffixText)")
                .font(font)
                .lineLimit(lineLimit)
        }
    }

    private var searchTerm: String {
        beginnerMode ? term.map(String.init).joined(separator: " ") : term
    }

    private static let englishHighlightStripSet: CharacterSet = {
        CharacterSet.punctuationCharacters.union(.symbols).union(.nonBaseCharacters)
    }()

    // MARK: - Caches

    private final class SourceNormEntry: NSObject {
        let normalizedSource: String
        let indexMap: [String.Index]
        init(_ n: String, _ i: [String.Index]) { normalizedSource = n; indexMap = i }
    }

    private final class RangeEntry: NSObject {
        let ranges: [Range<String.Index>]
        init(_ r: [Range<String.Index>]) { ranges = r }
    }

    private final class NSRangeEntry: NSObject {
        let ranges: [NSRange]
        init(_ r: [NSRange]) { ranges = r }
    }

    /// source → (normalizedSource, indexMap): amortises the O(n×k) per-character normalization.
    private static let sourceNormCache: NSCache<NSString, SourceNormEntry> = {
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

    private static let allahNSRangeCache: NSCache<NSString, NSRangeEntry> = {
        let c = NSCache<NSString, NSRangeEntry>()
        c.countLimit = 7_000
        return c
    }()

    private func normalizeEnglishForHighlight(_ text: String, trimWhitespace: Bool) -> String {
        var cleaned = String(text.unicodeScalars
            .filter { !Self.englishHighlightStripSet.contains($0) }
        ).lowercased()

        if trimWhitespace {
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }

    private func normalizeForSearch(_ text: String, trimWhitespace: Bool) -> String {
        // Strip search operators (`# ^ % $ …`) first so a query like `#الله` or `^Allah%` highlights the
        // residual word instead of failing to match (the source text never contains these characters).
        let base = text.removingAyahSearchOperators
        if !base.containsArabicLetters {
            return normalizeEnglishForHighlight(base, trimWhitespace: trimWhitespace)
        }
        return settings.cleanSearch(base, whitespace: trimWhitespace)
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

        // --- Step 1: normalizedSource + indexMap, cached per source string ---
        let sourceKey = source as NSString
        let normEntry: SourceNormEntry
        if let cached = Self.sourceNormCache.object(forKey: sourceKey) {
            normEntry = cached
        } else {
            let ns = normalizeForSearch(source, trimWhitespace: false)
            let im = normalizedIndexMap(in: source, normalizedSource: ns)
            normEntry = SourceNormEntry(ns, im)
            Self.sourceNormCache.setObject(normEntry, forKey: sourceKey)
        }

        // --- Step 2: matched ranges in original source, cached per (source, normalizedTerm, guarantee) ---
        // `guaranteeMatch` changes which fallbacks run, so it must be part of the key - otherwise the same
        // source+term shown once as a matched ayah field and once as a non-matching sibling would collide.
        let matchKey = "\(guaranteeMatch ? "1" : "0")\u{0000}\(source)\u{0000}\(normalizedTerm)" as NSString
        let matchedRanges: [Range<String.Index>]
        if let cached = Self.matchRangeCache.object(forKey: matchKey) {
            matchedRanges = cached.ranges
        } else {
            var ranges: [Range<String.Index>] = []
            var searchStart = normEntry.normalizedSource.startIndex
            while searchStart < normEntry.normalizedSource.endIndex,
                  let matchRange = normEntry.normalizedSource.range(of: normalizedTerm, range: searchStart..<normEntry.normalizedSource.endIndex) {
                if let orig = originalRange(
                    in: source,
                    normalizedSource: normEntry.normalizedSource,
                    matchRange: matchRange,
                    indexMap: normEntry.indexMap
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
                    normalizedSource: normEntry.normalizedSource,
                    indexMap: normEntry.indexMap,
                    normalizedTerm: normalizedTerm
                )
            }
            // Phrase-prefix fallback for BOTH scripts: highlights consecutive words where the leading words
            // match and the final word is a prefix (e.g. "those who believ" → "those who believe"). This is
            // the same "close match" rule the verse search itself uses, so English close matches - which
            // previously highlighted nothing - now get colored like the Arabic ones.
            if ranges.isEmpty {
                ranges = phrasePrefixRanges(
                    in: source,
                    normalizedSource: normEntry.normalizedSource,
                    normalizedTerm: normalizedTerm,
                    indexMap: normEntry.indexMap
                )
            }
            // Final safety net - ONLY when this field is expected to contain the match (`guaranteeMatch`,
            // i.e. ayah search on the field that actually matched). If nothing matched yet, highlight the
            // closest word(s) in THIS field so the user always sees at least one thing for their query. It
            // works on the original words normalized individually, so it doesn't depend on the whole-string
            // index alignment the paths above need - which can silently fail on heavily-marked Arabic and
            // leave a real match un-highlighted. Skipped by default so a query that matched a sibling field
            // doesn't force a spurious highlight here.
            if ranges.isEmpty, guaranteeMatch {
                ranges = closestMatchRanges(in: source, normalizedTerm: normalizedTerm)
            }
            Self.matchRangeCache.setObject(RangeEntry(ranges), forKey: matchKey)
            matchedRanges = ranges
        }

        // --- Step 3: apply accent colour to each matched range ---
        for range in matchedRanges {
            if let start = AttributedString.Index(range.lowerBound, within: attributed),
               let end = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[start..<end].foregroundColor = accent
            }
        }

        return attributed
    }

    private func phrasePrefixRanges(
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
    private func arabicLooseRanges(
        source: String,
        normalizedSource: String,
        indexMap: [String.Index],
        normalizedTerm: String
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
                if normalizeForSearch(String(source[prev]), trimWhitespace: false) == "ا" { start = prev }
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
    private func closestMatchRanges(in source: String, normalizedTerm: String) -> [Range<String.Index>] {
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

            let normToken = normalizeForSearch(String(source[tokenRange]), trimWhitespace: true)
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
    private func longestWordRange(in source: String) -> Range<String.Index>? {
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

    private func wordMatchScore(word: String, query: String) -> Int {
        if word == query { return 100 }
        if word.contains(query) { return 70 }
        if query.contains(word) { return 60 }
        let lcp = commonPrefixLength(word, query)
        return lcp >= 2 ? lcp : 0
    }

    private func commonPrefixLength(_ a: String, _ b: String) -> Int {
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

    private func normalizedTokenRanges(in text: String) -> [Range<String.Index>] {
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
        if let cached = Self.allahRangeCache.object(forKey: cacheKey) {
            ranges = cached.ranges
        } else {
            var found: [Range<String.Index>] = []
            for start in source.indices {
                if let range = arabicAllahRange(startingAt: start, in: source) {
                    found.append(range)
                }
            }
            Self.allahRangeCache.setObject(RangeEntry(found), forKey: cacheKey)
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

    private func arabicAllahNSRange(startingAt start: String.Index, in source: String) -> NSRange? {
        if source[start].allahBase?.isAllahAlif == true,
           let afterAlif = nextNonMarkIndex(after: start, in: source),
           source[afterAlif].allahBase == "ل",
           let secondLam = nextNonMarkIndex(after: afterAlif, in: source),
           source[secondLam].allahBase == "ل",
           let heh = nextNonMarkIndex(after: secondLam, in: source),
           source[heh].allahBase == "ه" {
            return allahNSRange(from: start, throughHehAt: heh, in: source)
        }

        if source[start].allahBase == "ل",
           let secondLam = nextNonMarkIndex(after: start, in: source),
           source[secondLam].allahBase == "ل",
           let heh = nextNonMarkIndex(after: secondLam, in: source),
           source[heh].allahBase == "ه" {
            return allahNSRange(from: start, throughHehAt: heh, in: source)
        }

        return nil
    }

    private func allahNSRange(from start: String.Index, throughHehAt heh: String.Index, in source: String) -> NSRange? {
        guard var scalarCursor = heh.samePosition(in: source.unicodeScalars) else { return nil }

        let lower = source.utf16.distance(from: source.startIndex, to: start)
        var upper = source.utf16.distance(from: source.startIndex, to: heh)
        var foundHeh = false

        while scalarCursor < source.unicodeScalars.endIndex {
            let scalar = source.unicodeScalars[scalarCursor]
            if !foundHeh {
                guard scalar.value == 0x0647 else { break }
                foundHeh = true
                upper += scalar.utf16.count
                scalarCursor = source.unicodeScalars.index(after: scalarCursor)
                continue
            }
            guard scalar.isArabicAllahHighlightMarkScalar else { break }
            upper += scalar.utf16.count
            scalarCursor = source.unicodeScalars.index(after: scalarCursor)
        }

        guard upper > lower else { return nil }
        return NSRange(location: lower, length: upper - lower)
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

    private func platformRedColor() -> Any {
        #if canImport(UIKit)
        return UIColor(Color.red)
        #elseif canImport(AppKit)
        return NSColor(Color.red)
        #else
        return Color.red
        #endif
    }

    private func normalizedIndexMap(in source: String, normalizedSource: String) -> [String.Index] {
        var map: [String.Index] = []
        map.reserveCapacity(normalizedSource.count)

        for idx in source.indices {
            let next = source.index(after: idx)
            let normalizedCharacter = normalizeForSearch(String(source[idx..<next]), trimWhitespace: false)
            for _ in normalizedCharacter {
                map.append(idx)
            }
        }

        return map
    }

    private func originalRange(
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
        let end = source.index(after: lastMatched)
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
