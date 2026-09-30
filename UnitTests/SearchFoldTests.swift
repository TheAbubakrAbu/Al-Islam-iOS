import XCTest
@testable import iPhone

/// Latin accents in search: `String.foldingLatinDiacritics` and every fold that carries it (Abu,
/// 2026-09-29: "Sunan Abī Dāwūd 3331, allow me to search this up with diacritics, so strip it").
final class SearchFoldTests: XCTestCase {

    func testFoldsAcademicTransliteration() {
        XCTAssertEqual("Sunan Abī Dāwūd".foldingLatinDiacritics, "Sunan Abi Dawud")
        XCTAssertEqual("Ṣaḥīḥ al-Bukhārī".foldingLatinDiacritics, "Sahih al-Bukhari")
        XCTAssertEqual("Jāmiʿ at-Tirmidhī".foldingLatinDiacritics, "Jami at-Tirmidhi")
        XCTAssertEqual("Nasāʾī".foldingLatinDiacritics, "Nasai")
        XCTAssertEqual("ʻUmar ibn al-Khaṭṭāb".foldingLatinDiacritics, "Umar ibn al-Khattab")
        XCTAssertEqual("Mûsa, Ibrâhîm, Muḥammad ﷺ".foldingLatinDiacritics, "Musa, Ibrahim, Muhammad ﷺ")
        XCTAssertEqual("ẒĀHIR, ḌUḤĀ".foldingLatinDiacritics, "ZAHIR, DUHA")
    }

    /// A pasted "ā" can arrive as "a" plus a combining macron.
    func testDecomposedAccentsFold() {
        XCTAssertEqual("Abi\u{0304} Da\u{0304}wu\u{0304}d".foldingLatinDiacritics, "Abi Dawud")
    }

    /// Arabic keeps every mark (its own folds decide what they mean), and plain text comes back as is.
    func testArabicAndPlainTextPassThrough() {
        let arabic = "سُنَن أَبِي داوُد ١٥"
        XCTAssertEqual(arabic.foldingLatinDiacritics, arabic)
        let plain = "Sunan Abi Dawud 3331, 'A'ishah (may Allah be pleased with her)"
        XCTAssertEqual(plain.foldingLatinDiacritics, plain)
    }

    /// The Encyclopedia's byte fold and `IslamArticles.fold` must agree byte for byte ("-auditPacks").
    func testByteFoldMatchesStringFold() {
        let samples = [
            "Ṣaḥīḥ al-Bukhārī", "Jāmiʿ at-Tirmidhī 2664", "ʿĀʾishah (may Allah be pleased with her)",
            "Abi\u{0304} Da\u{0304}wu\u{0304}d", "İstanbul", "Mûsa, Ibrâhîm", "سُنَن أَبِي داوُد", "Plain text, 42.",
        ]
        for sample in samples {
            var bytes: [UInt8] = []
            HadeethEncStore.foldEnglish(sample, into: &bytes)
            XCTAssertEqual(bytes, Array(IslamArticles.fold(sample).utf8), sample)
        }
        XCTAssertEqual(IslamArticles.fold("Ṣaḥīḥ al-Bukhārī"), "sahih al bukhari")
    }

    /// The Quran search fold reads accents in the same single pass as its Arabic folds.
    @MainActor
    func testCleanSearchFoldsAccents() {
        let settings = Settings.shared
        XCTAssertEqual(settings.cleanSearch("Mūsā"), "musa")
        XCTAssertEqual(settings.cleanSearch("ʿImrān", whitespace: true), "imran")
        XCTAssertEqual(settings.cleanSearch("Al-Fātiḥah"), settings.cleanSearch("Al-Fatihah"))
    }

    /// The highlighter paints the accented word for a plain query, the whole word.
    @MainActor
    func testHighlightFindsAccentedWord() {
        XCTAssertEqual(HighlightedSnippet.normalizeForSearchText("Ṣaḥīḥ", trimWhitespace: true), "sahih")
        let source = "Narrated ʿĀʾishah: the Prophet said"
        let spans = HighlightedSnippet.matchSpans(in: source, term: "aishah", guaranteeMatch: false)
        XCTAssertEqual(spans.count, 1)
        if let span = spans.first, let range = Range(span, in: source) {
            XCTAssertEqual(String(source[range]), "ʿĀʾishah")
        }
    }

    /// No book's English search text still carries a letter the fold would change, so a plain query
    /// reaches every narration.
    func testPackSearchTextIsFolded() {
        for book in HadithCatalogBook.all {
            guard let url = HadithPack.bundledURL(book.slug), let pack = HadithPack(slug: book.slug, url: url) else {
                XCTFail("\(book.slug) did not open")
                continue
            }
            // Built with the fold the app queries with (Hadith-JSON-Engine's tools/pack/build.sh).
            XCTAssertTrue(pack.foldMatchesApp, "\(book.slug) was packed with another fold")
            var unfolded = 0
            pack.scanSearchFolds(in: 0..<pack.rows.count, isArabic: false) { _, fold in
                guard fold.contains(where: { $0 >= 0xC3 && ($0 <= 0xCD || $0 == 0xE1) }) else { return }
                if String(decoding: fold, as: UTF8.self).unicodeScalars.contains(where: LatinFold.affects) { unfolded += 1 }
            }
            XCTAssertEqual(unfolded, 0, book.slug)
        }
    }

    /// A narration spelled with accents is found by its plain spelling, through the same sweep the
    /// Hadith tab runs.
    func testPlainQueryFindsAccentedNarration() {
        var checked = 0
        for slug in ["tirmidhi", "muslim", "mishkat_almasabih"] {
            guard let url = HadithPack.bundledURL(slug), let pack = HadithPack(slug: slug, url: url) else {
                XCTFail("\(slug) did not open")
                continue
            }
            var found = 0
            for row in 0..<pack.rows.count where found < 3 {
                let strings = pack.strings(row: row)
                let words = (strings.text + " " + strings.narrator).split(whereSeparator: \.isWhitespace)
                guard let word = words.first(where: { word in
                    word.unicodeScalars.contains { LatinFold.base($0) != nil }
                        && HadithFold.english(String(word).foldingLatinDiacritics).count >= 3
                }) else { continue }
                let query = HadithFold.query(String(word))
                XCTAssertEqual(pack.matchingRows(in: row..<(row + 1), query: query, limit: 1), [row],
                               "\(slug) row \(row): \(word)")
                found += 1
            }
            checked += found
        }
        XCTAssertGreaterThan(checked, 0, "no accented narration found to check")
    }

    /// The packs' fold (`HadithFold.english`, copied from the engine) and the app's `LatinFold` read
    /// every Latin letter alike, so what the Hadith search finds is what the highlighter paints.
    func testPackFoldAgreesWithAppFold() {
        let strip = CharacterSet.punctuationCharacters.union(.symbols).union(.nonBaseCharacters)
        var disagreements: [String] = []
        for range: ClosedRange<UInt32> in [0x0020...0x036F, 0x1E00...0x1EFF] {
            for value in range {
                guard let scalar = Unicode.Scalar(value) else { continue }
                let app = String(String(scalar).foldingLatinDiacritics.unicodeScalars.filter { !strip.contains($0) }).lowercased()
                if HadithFold.english(String(scalar)) != app { disagreements.append(String(format: "U+%04X", value)) }
            }
        }
        XCTAssertEqual(disagreements, [])
        XCTAssertEqual(HadithFold.english("Sunan Abī Dāwūd, ʿĀʾishah, Muħammad"), "sunan abi dawud aishah muhammad")
    }
}
