import XCTest
@testable import iPhone

/// `String.decomposingAlefMadda` stopped going through Foundation's non-literal `contains` and
/// `replacingOccurrences` on 2026-10-04 (Phase 10.11): those two calls were 88% of every hadith text
/// block's inflate. This pins the new scan to the OLD code, kept here verbatim as the reference, over
/// every display string in the 17 hadith packs (read raw, before the pass is applied), every Fortress
/// of the Muslim entry, and a bank of edge cases around what Foundation treated as one composed
/// character sequence (an آ followed by a combining mark was never matched; a bare one always was).
///
/// Known, deliberately unreplicated: Foundation also left an آ alone when one of the Arabic NUMBER
/// SIGNS (U+0600-U+0605, U+06DD, U+08E2, prepend characters that bind to the letter after them) stood
/// immediately before it and a base letter followed; the signs precede digits, never a letter, and the
/// corpus sweep below would fail if a text ever carried that sequence.
final class AlefMaddaEquivalenceTests: XCTestCase {

    // MARK: Reference (the pre-2026-10-04 code, character for character)

    private static func reference(_ text: String) -> String {
        text.contains("\u{0622}") ? text.replacingOccurrences(of: "\u{0622}", with: "\u{0627}\u{0653}") : text
    }

    private static func scalars(_ text: String) -> String {
        text.unicodeScalars.map { String(format: "%04X", $0.value) }.joined(separator: " ")
    }

    /// True when both forms agree scalar for scalar (stricter than `==`, which is canonical equivalence).
    @discardableResult
    private func assertSame(_ text: String, context: String = "", file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let old = Array(Self.reference(text).unicodeScalars)
        let new = Array(text.decomposingAlefMadda.unicodeScalars)
        if old == new { return true }
        XCTFail("\(context) [\(Self.scalars(text))] reference=[\(Self.scalars(Self.reference(text)))] new=[\(Self.scalars(text.decomposingAlefMadda))]",
                file: file, line: line)
        return false
    }

    // MARK: Edge cases

    func testBareAndMarkedAlefMadda() {
        let cases: [String] = [
            "", "\u{0622}", "\u{0622}\u{0622}", "x\u{0622}", "\u{0622}x", "ء\u{0622}", "\u{0627}\u{0653}",
            "\u{0622}\u{064E}", "\u{0622}\u{0651}", "\u{0622}\u{0670}", "\u{0622}\u{0653}", "\u{0622}\u{06E1}\u{064B}",
            "\u{0622}\u{200C}", "\u{0622}\u{200D}", "\u{200D}\u{0622}", "\u{0622}\u{FE0F}", "\u{0622}\u{034F}",
            "\u{0622}\u{0640}", "\u{0622} ", "\u{0622}\n", "\u{0622}\u{00A0}", "\u{0622}\u{060C}", "\u{0622}\u{061F}",
            "\u{0622}\u{0660}", "\u{0622}\u{06F1}", "\u{0622}\u{06D6}", "\u{0622}\u{06DD}", "\u{0622}\u{0600}",
            "قُرْآن", "آمِين", "ٱلْقُرْآنِ", "الْقُرْآنَ", "آخِرِ", "آيَة", "آل", "رَآهُ", "آدَمَ", "مِرْآة",
            "الْآخِرَةِ", "آمَنُوا", "آبَاؤُكُمْ", "آنِيَةٍ", "وَآتُوا", "آيَاتٌ بَيِّنَاتٌ", "e\u{0301}", "\u{FDF2}",
            "\u{0622}\u{0653}\u{0622}", "\u{0627}\u{0653}\u{064E}", "\u{0627}\u{064E}\u{0653}",
        ]
        for text in cases { assertSame(text, context: "edge") }
    }

    /// Every Arabic-script scalar, plus the format and space characters prose can carry, as the
    /// scalar right after an آ, in three contexts (word start, after a letter, after a fatha).
    ///
    /// The zero-width joiner (U+200D) is left out of the bank on purpose: Foundation treated a trailing
    /// one as part of the آ's sequence (no swap) but swapped an آ before a joiner that had a letter after
    /// it, and the scan keeps the first reading for both. No text in the app carries a joiner after an آ
    /// (the corpus sweeps below would fail), and the trailing case is in `testBareAndMarkedAlefMadda`.
    func testEveryArabicFollower() {
        let ranges: [ClosedRange<UInt32>] = [
            0x0020...0x007E, 0x00A0...0x00A0, 0x0600...0x06FF, 0x0750...0x077F, 0x08A0...0x08FF,
            0x200B...0x200C, 0x200E...0x200F, 0x2028...0x202F, 0x2060...0x2064, 0xFB50...0xFDFF, 0xFE70...0xFEFF,
        ]
        var compared = 0
        for range in ranges {
            for value in range {
                guard let scalar = Unicode.Scalar(value) else { continue }
                let follower = String(scalar)
                for prefix in ["", "ل", "\u{064E}", "بِ"] {
                    for text in [prefix + "\u{0622}" + follower, prefix + "\u{0622}" + follower + "\u{0622}",
                                 prefix + "\u{0622}" + follower + "ن\u{0622}\u{0652}"] {
                        compared += 1
                        guard assertSame(text, context: String(format: "follower U+%04X", value)) else { return }
                    }
                }
            }
        }
        XCTAssertGreaterThan(compared, 10_000)
    }

    // MARK: Corpora

    func testEveryHadithDisplayStringMatchesReference() {
        var compared = 0
        var failures = 0
        for book in HadithCatalogBook.all {
            guard let url = HadithPack.bundledURL(book.slug), let pack = HadithPack(slug: book.slug, url: url) else {
                XCTFail("\(book.slug): pack missing"); continue
            }
            for block in 0..<pack.textBlockCountForTests {
                guard let strings = pack.rawTextBlockForTests(block) else {
                    XCTFail("\(book.slug) block \(block): undecodable"); continue
                }
                for text in strings {
                    compared += 1
                    if !assertSame(text, context: "\(book.slug) block \(block)") {
                        failures += 1
                        if failures > 20 { return }
                    }
                }
            }
        }
        // Four strings per hadith across the 17 books: a count this low means a pack did not open.
        XCTAssertGreaterThan(compared, 100_000, "the whole shelf should have been compared")
    }

    func testEveryFortressEntryMatchesReference() {
        guard let library = HisnDuasStore.shared.loaded() else { XCTFail("Fortress pack missing"); return }
        XCTAssertGreaterThan(library.entries.count, 200)
        for entry in library.entries {
            assertSame(entry.arabic, context: "hisn \(entry.id) arabic")
            assertSame(entry.transliteration, context: "hisn \(entry.id) transliteration")
            assertSame(entry.translation, context: "hisn \(entry.id) translation")
        }
    }
}
