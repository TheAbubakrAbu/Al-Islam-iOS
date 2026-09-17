import Foundation

// A quoted narration as a REFERENCE into the app's own shelf, not a copy. The Islam tab's articles
// and the Dua screen used to carry each quoted hadith as Swift string literals, the Arabic and the
// English, and 598 of the article quotes were word-for-word what the bundled collection already
// holds. A reference cannot drift and costs nothing to ship: the words are read out of the .hpk
// the Hadith tab reads (`HadithQuoteSource`) when the quote renders, so the article shows exactly
// what the reader finds when they open the same narration on the shelf.
//
// The link names the row the way the reminder pack does: "bukhari:6306", "muslim:1163a" (the
// collection's slug and its sunnah.com citation). Word ranges are 0-based inclusive ranges of the
// row's whitespace tokens, the Arabic's counted with its chain of narrators, the English's over the
// translation alone: `arabic: 22...58` is the matn, `english: 4...61` the quoted sentence. The
// citation the reader sees is carried as written ("Sahih al-Bukhari 6306, Sahih Muslim 2705").

/// One narration on the shelf: its collection and its citation ("6306", "1163a"), or, where a
/// citation string names more than one row of the book (Tirmidhi and Bulugh carry duplicates;
/// Muslim's Muqaddimah shares its numbers with the main book's lettered variants), its number in
/// the book ("#7393", what `HadithBookData.hadith(numbered:)` takes).
struct HadithQuoteReference: Hashable {
    let slug: String
    let citation: String

    /// Parses "slug:citation" and "slug:#number"; nil for anything else.
    init?(_ link: String) {
        let parts = link.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, !parts[0].isEmpty, let first = parts[1].first,
              first.isNumber || (first == "#" && parts[1].dropFirst().allSatisfy(\.isNumber) && parts[1].count > 1) else { return nil }
        slug = parts[0].lowercased()
        citation = parts[1]
    }

    /// The row's number in the book, for a "#7393" reference.
    var numbered: Int? { citation.first == "#" ? Int(citation.dropFirst()) : nil }

    /// "6306" -> (6306, nil); "1163a" -> (1163, "a"): what `HadithBookData.hadith(referenced:suffix:)` takes.
    var parts: (number: Int, suffix: String?) {
        var digits = citation
        var suffix: String?
        if let last = digits.last, last.isLetter {
            suffix = String(last)
            digits = String(digits.dropLast())
        }
        return (Int(digits) ?? 0, suffix)
    }

    var link: String { "\(slug):\(citation)" }
}

/// The narration's texts as the pack has them: the Arabic with its chain, the narrator line and
/// the translation. Callers slice these by the word ranges the reference carries.
struct HadithQuoteText: Equatable {
    let arabic: String
    let narrator: String
    let text: String
}

/// Whitespace tokens sliced by 0-based inclusive ranges: the one convention every pack's word
/// range uses (`DailyReminderStore.resolveReferences` slices the same way).
enum WordRange {
    static func words(_ text: String, _ range: ClosedRange<Int>) -> String {
        let tokens = text.split(whereSeparator: \.isWhitespace)
        guard range.lowerBound >= 0, range.lowerBound < tokens.count else { return "" }
        return tokens[range.lowerBound...min(range.upperBound, tokens.count - 1)].joined(separator: " ")
    }

    /// Several ranges read in order, joined by an ellipsis: a quote that skips part of the narration.
    static func words(_ text: String, _ ranges: [ClosedRange<Int>]) -> String {
        ranges.map { words(text, $0) }.filter { !$0.isEmpty }.joined(separator: " \u{2026} ")
    }
}

#if os(watchOS)
/// Where a referenced narration gets its words on the Watch, which compiles the article files and
/// the Dua screen but bundles no shelf: `HadithQuotes.json.deflate`, the referenced rows alone, cut
/// from the shelf at build time by Scripts/build_hadith_quotes_pack.py and gated byte-identical to a
/// fresh build by Scripts/verify_islam_corpus.py. The phone never bundles it.
enum HadithQuoteSource {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var rows: [String: HadithQuoteText]?

    /// The row's texts once the pack has been read (a lock, no I/O): safe on the main actor.
    static func cached(_ reference: HadithQuoteReference) -> HadithQuoteText? {
        lock.lock(); defer { lock.unlock() }
        return rows?[reference.link]
    }

    /// The row's texts, the pack inflated off the main actor on the first ask.
    static func resolve(_ reference: HadithQuoteReference) async -> HadithQuoteText? {
        if let hit = cached(reference) { return hit }
        return await Task.detached(priority: .userInitiated) { read(reference) }.value
    }

    /// The same read, synchronously, for callers already off the main actor.
    static func read(_ reference: HadithQuoteReference) -> HadithQuoteText? {
        if let hit = cached(reference) { return hit }
        let loaded = load()
        lock.lock()
        if rows == nil { rows = loaded }
        let hit = rows?[reference.link]
        lock.unlock()
        return hit
    }

    private static func load() -> [String: HadithQuoteText] {
        guard let url = Bundle.main.url(forResource: "HadithQuotes", withExtension: "json.deflate")
                ?? Bundle.main.url(forResource: "HadithQuotes", withExtension: "json.deflate", subdirectory: "Data/Islam")
                ?? Bundle.main.url(forResource: "HadithQuotes", withExtension: "json.deflate", subdirectory: "Islam"),
              let compressed = try? Data(contentsOf: url),
              let json = IslamArticles.inflate(compressed),
              let root = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              root["version"] as? Int == 1,
              let packed = root["rows"] as? [String: [String]] else { return [:] }
        var out: [String: HadithQuoteText] = [:]
        for (link, strings) in packed where strings.count == 3 {
            out[link] = HadithQuoteText(arabic: strings[0], narrator: strings[1], text: strings[2])
        }
        return out
    }
}
#else
/// Where a referenced narration gets its words: the bundled .hpk of its collection, opened once
/// per book and read off the main actor, every row read kept, so a page of forty quotes decodes each
/// text block once and a row shown again renders without a hop.
enum HadithQuoteSource {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var books: [String: HadithBookData] = [:]
    nonisolated(unsafe) private static var texts: [String: HadithQuoteText] = [:]

    /// The row's texts if they have been read already (a lock, no I/O): safe on the main actor,
    /// what a quote renders with when its row is warm.
    static func cached(_ reference: HadithQuoteReference) -> HadithQuoteText? {
        lock.lock(); defer { lock.unlock() }
        return texts[reference.link]
    }

    /// The row's texts, read off the main actor (the pack decompresses a block); nil when the
    /// collection is not bundled or the citation is not in it.
    static func resolve(_ reference: HadithQuoteReference) async -> HadithQuoteText? {
        if let hit = cached(reference) { return hit }
        return await Task.detached(priority: .userInitiated) { read(reference) }.value
    }

    /// The same read, synchronously, for callers already off the main actor (a store resolving a
    /// whole screen's references at once).
    static func read(_ reference: HadithQuoteReference) -> HadithQuoteText? {
        if let hit = cached(reference) { return hit }
        guard let book = book(reference.slug) else { return nil }
        let hadith: HadithBookData.Hadith?
        if let number = reference.numbered {
            hadith = book.hadith(numbered: number)
        } else {
            // The row whose citation is exactly this string first ("26" is the Muqaddimah's 26, not
            // 26a), then the book's own rule for a bare base number (its first variant).
            let parts = reference.parts
            hadith = book.hadiths(citing: parts.number).first { $0.citation == reference.citation }
                ?? book.hadith(referenced: parts.number, suffix: parts.suffix)
        }
        guard let hadith else { return nil }
        let all = hadith.allText
        let text = HadithQuoteText(arabic: all.arabic, narrator: all.narrator, text: all.text)
        lock.lock(); texts[reference.link] = text; lock.unlock()
        return text
    }

    private static func book(_ slug: String) -> HadithBookData? {
        lock.lock()
        if let open = books[slug] { lock.unlock(); return open }
        lock.unlock()
        // Opened outside the lock (it maps the file and parses the eager section); two first
        // readers of one book at the same moment both open it and one copy wins, harmlessly.
        guard let url = HadithPack.bundledURL(slug), let pack = HadithPack(slug: slug, url: url) else { return nil }
        let data = HadithBookData(pack: pack)
        lock.lock()
        let kept = books[slug] ?? data
        books[slug] = kept
        lock.unlock()
        return kept
    }
}
#endif
