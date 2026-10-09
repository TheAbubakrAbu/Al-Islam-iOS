import XCTest
import Foundation
@testable import iPhone

/// `IslamArticles.fold` is the search fold every article title and section body is stored under, so
/// it runs over the whole ~1 MB corpus at load (`IslamArticles.all`, prewarmed off main) and again
/// for every query. The 2026-10-08 pass replaced its per-scalar `[Character]` build and
/// `CharacterSet.alphanumerics` membership with the byte-style walk `HadeethEncStore.foldEnglish`
/// already used, so this file keeps the OLD implementation verbatim as the reference and compares
/// the two over every string the app actually folds, the way `SearchFoldEquivalenceTests` pins the
/// Quran folds (Performance Guide, Phase 10).
///
/// If this fails, the fold's output moved: search results and highlighting move with it. Fix the
/// implementation rather than this reference.
final class IslamArticlesFoldEquivalenceTests: XCTestCase {

    /// The pre-optimization `IslamArticles.fold`, copied exactly.
    private func referenceFold(_ text: String) -> String {
        String(text.foldingLatinDiacritics.lowercased().unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
        })
    }

    private func assertSame(_ sample: String, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(IslamArticles.fold(sample), referenceFold(sample), label, file: file, line: line)
    }

    /// Every title and every section body of every shipped article: the strings `load()` folds.
    func testMatchesReferenceOverTheWholeCorpus() throws {
        let articles = IslamArticles.all
        XCTAssertFalse(articles.isEmpty, "the article pack did not load; the comparison would be vacuous")

        var strings = 0
        for article in articles {
            assertSame(article.title, "title of \(article.id)")
            strings += 1
            for section in article.sections {
                assertSame(section.heading, "heading in \(article.id)")
                assertSame(section.text, "section body in \(article.id)")
                strings += 2
            }
        }
        print("ISLAM FOLD EQUIVALENCE compared \(strings) strings over \(articles.count) articles")
        XCTAssertGreaterThan(strings, 100, "the corpus should be far larger than this")
    }

    /// The stored folds really are what the fold produces now (what `load()` wrote must still match).
    func testStoredFoldsMatchTheFoldOfTheirText() {
        for article in IslamArticles.all {
            XCTAssertEqual(article.foldedTitle, IslamArticles.fold(article.title), article.id)
            for section in article.sections {
                XCTAssertEqual(section.folded, IslamArticles.fold(section.text), article.id)
            }
        }
    }

    /// The edge cases the two implementations could disagree on: the accent and hamza marks the Latin
    /// fold drops, decomposed accents, uppercase ASCII, digits, Arabic (which passes through), emoji
    /// and other non-BMP scalars (a surrogate pair is one scalar but was one `Character` before),
    /// dotted-I casing, ligatures and symbols, and the empty string.
    func testMatchesReferenceOnEdgeCases() {
        let samples = [
            "", " ", "   ", "\n\t",
            "Plain text, 42.", "ALL CAPS TEXT", "mixed Case 123",
            "Ṣaḥīḥ al-Bukhārī", "Jāmiʿ at-Tirmidhī 2664", "ʿĀʾishah (may Allah be pleased with her)",
            "Nasāʾī", "ʻUmar ibn al-Khaṭṭāb", "Mûsa, Ibrâhîm, Muḥammad ﷺ", "ẒĀHIR, ḌUḤĀ",
            "Abi\u{0304} Da\u{0304}wu\u{0304}d", "a\u{0300}e\u{0301}i\u{0302}o\u{0303}u\u{0308}",
            "İstanbul", "ı dotless", "ﬁ ligature", "Straße",
            "سُنَن أَبِي داوُد ١٥", "الْحَمْدُ لِلَّهِ", "بِسْمِ ٱللَّهِ",
            "emoji 🕌 mosque", "👨‍👩‍👧‍👦 family", "𝐀𝐁𝐂 math bold", "\u{1F600}",
            "wudhu,", "(wudhu)", "half-life", "e.g. this/that", "a—b", "“quoted”",
            "tab\tseparated", "new\nline", "non breaking\u{00A0}space",
            "¹²³ superscripts", "½ fraction", "№ numero", "™ ® ©",
            "Ⅻ roman numeral", "ⅷ roman small", "①② circled",
            "ZERO\u{200B}WIDTH", "\u{FEFF}bom", "\u{0000}null",
            // Casing that could depend on context or leave the BMP: Greek final sigma (the old code
            // lowercased the whole string, the new one scalar by scalar), Deseret capitals (non-BMP
            // letters with case), titlecase digraphs and a letter that lowercases to itself.
            "ΟΔΟΣ", "ΣΟΦΟΣ ΚΑΙ", "abΣ", "𐐀𐐁 Deseret", "ǅ ǈ ǋ", "ŉ",
        ]
        for sample in samples {
            assertSame(sample, "edge case \(sample.debugDescription)")
        }
    }

    /// Every scalar in the BMP, one at a time and in a short word, so no single code point disagrees.
    func testMatchesReferenceOverEveryBMPScalar() {
        var checked = 0
        for value in UInt32(0)...UInt32(0xFFFF) {
            guard let scalar = Unicode.Scalar(value) else { continue }
            let single = String(scalar)
            XCTAssertEqual(IslamArticles.fold(single), referenceFold(single),
                           "U+\(String(format: "%04X", value)) alone")
            let inWord = "ab\(single)cd"
            XCTAssertEqual(IslamArticles.fold(inWord), referenceFold(inWord),
                           "U+\(String(format: "%04X", value)) in a word")
            checked += 1
        }
        print("ISLAM FOLD EQUIVALENCE compared \(checked) BMP scalars")
        XCTAssertGreaterThan(checked, 60000)
    }

    /// Every scalar in supplementary plane 1 (historic scripts with case such as Deseret and Osage,
    /// the mathematical alphanumerics, emoji), the same two ways: the BMP sweep above never leaves
    /// plane 0, and a non-BMP scalar is where a scalar walk and a `Character` walk could part ways.
    func testMatchesReferenceOverSupplementaryPlaneOne() {
        var checked = 0
        for value in UInt32(0x10000)...UInt32(0x1FFFF) {
            guard let scalar = Unicode.Scalar(value) else { continue }
            let single = String(scalar)
            XCTAssertEqual(IslamArticles.fold(single), referenceFold(single),
                           "U+\(String(format: "%05X", value)) alone")
            let inWord = "ab\(single)cd"
            XCTAssertEqual(IslamArticles.fold(inWord), referenceFold(inWord),
                           "U+\(String(format: "%05X", value)) in a word")
            checked += 1
        }
        print("ISLAM FOLD EQUIVALENCE compared \(checked) plane-1 scalars")
        XCTAssertEqual(checked, 65536)
    }

    /// The Encyclopedia's byte fold is documented as the same rule; it must stay identical.
    func testStillAgreesWithTheByteFold() {
        for sample in ["Ṣaḥīḥ al-Bukhārī", "Jāmiʿ at-Tirmidhī 2664", "Plain text, 42.",
                       "ʿĀʾishah", "Abi\u{0304} Da\u{0304}wu\u{0304}d", "سُنَن أَبِي داوُد"] {
            var bytes: [UInt8] = []
            HadeethEncStore.foldEnglish(sample, into: &bytes)
            XCTAssertEqual(bytes, Array(IslamArticles.fold(sample).utf8), sample)
        }
    }
}
