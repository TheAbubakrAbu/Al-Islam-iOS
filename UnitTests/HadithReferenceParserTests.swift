import XCTest
@testable import iPhone

/// `HadithReferenceParser`: "bukhari 5", "muslim 3:12", pasted sunnah.com links, Arabic names.
final class HadithReferenceParserTests: XCTestCase {

    private func parse(_ text: String) -> HadithReferenceParser.Reference? {
        HadithReferenceParser.parse(text)
    }

    /// C3: the guide's case, 16 dotted capital I (two scalars each when lowercased) before the link.
    func testDottedCapitalIBeforeSunnahLink() {
        let text = String(repeating: "\u{0130}", count: 16) + " sunnah.com/bukhari:1"
        XCTAssertEqual(HadithReferenceParser.canonical(text), "bukhari 1")
        let reference = parse(text)
        XCTAssertEqual(reference?.book.slug, "bukhari")
        XCTAssertEqual(reference?.hadith, 1)
    }

    /// C3: any number of "İ" before the link (the old code failed at 1 and trapped at 16).
    func testAnyCountOfDottedCapitalI() {
        for count in 0...24 {
            let text = String(repeating: "\u{0130}", count: count) + " sunnah.com/muslim:8a"
            XCTAssertEqual(HadithReferenceParser.canonical(text), "muslim 8a", "\(count) x U+0130")
        }
    }

    /// C3: the link host is found case-insensitively in the original string.
    func testSunnahLinkCaseInsensitive() {
        XCTAssertEqual(HadithReferenceParser.canonical("SUNNAH.COM/Bukhari:1"), "Bukhari 1")
        XCTAssertEqual(parse("Https://Sunnah.com/bukhari:5")?.hadith, 5)
    }

    /// C3: the three link shapes: "book:N", "book:Na" and "book/C/N".
    func testSunnahLinkShapes() {
        let variant = parse("https://sunnah.com/muslim:8a")
        XCTAssertEqual(variant?.book.slug, "muslim")
        XCTAssertEqual(variant?.hadith, 8)
        XCTAssertEqual(variant?.suffix, "a")

        let chaptered = parse("sunnah.com/bukhari/1/2")
        XCTAssertEqual(chaptered?.book.slug, "bukhari")
        XCTAssertEqual(chaptered?.chapter, 1)
        XCTAssertEqual(chaptered?.hadith, 2)

        XCTAssertEqual(HadithReferenceParser.canonical("https://sunnah.com/bukhari:1?lang=en#top"), "bukhari 1")
    }

    /// C3: the plain "book N" and "book C:N" grammar.
    func testPlainReferences() {
        let plain = parse("bukhari 5")
        XCTAssertEqual(plain?.book.slug, "bukhari")
        XCTAssertNil(plain?.chapter)
        XCTAssertEqual(plain?.hadith, 5)

        let chaptered = parse("muslim 3:12")
        XCTAssertEqual(chaptered?.book.slug, "muslim")
        XCTAssertEqual(chaptered?.chapter, 3)
        XCTAssertEqual(chaptered?.hadith, 12)

        XCTAssertEqual(parse("Qudsi: 24")?.book.slug, "qudsi40")
        XCTAssertEqual(parse("Al-Adab Al-Mufrad 24")?.book.slug, "aladab_almufrad")
    }

    /// C3: the looser shapes the parser documents fold into "book N".
    func testLooseShapes() {
        XCTAssertEqual(parse("sahih muslim hadith no. 2013")?.hadith, 2013)
        XCTAssertEqual(parse("muslim #2013")?.hadith, 2013)
        XCTAssertEqual(parse("muslim2013")?.hadith, 2013)
        let numberFirst = parse("2013 muslim")
        XCTAssertEqual(numberFirst?.book.slug, "muslim")
        XCTAssertEqual(numberFirst?.hadith, 2013)
        let book = parse("muslim book 3 hadith 12")
        XCTAssertEqual(book?.chapter, 3)
        XCTAssertEqual(book?.hadith, 12)
    }

    /// C3: Arabic names and Arabic-Indic digits.
    func testArabicReference() {
        let reference = parse("\u{0627}\u{0644}\u{0628}\u{062E}\u{0627}\u{0631}\u{064A} \u{0661}\u{0665}")   // "البخاري ١٥"
        XCTAssertEqual(reference?.book.slug, "bukhari")
        XCTAssertEqual(reference?.hadith, 15)
    }

    /// C3: spelling slips and prefixes reach one book.
    func testFuzzyNames() {
        XCTAssertEqual(parse("Bokhari 5")?.book.slug, "bukhari")
        XCTAssertEqual(parse("tirmid 24")?.book.slug, "tirmidhi")
        XCTAssertEqual(parse("Nasayi 100")?.book.slug, "nasai")
    }

    /// C3: Sahih Muslim's Introduction keeps its own numbering.
    func testMuslimIntroduction() {
        let reference = parse("muslim introduction 9")
        XCTAssertEqual(reference?.book.slug, "muslim")
        XCTAssertEqual(reference?.hadith, 9)
        XCTAssertEqual(reference?.introduction, true)
    }

    /// Names written or pasted in academic transliteration read as their plain spelling (Abu,
    /// 2026-09-29: "Sunan Abī Dāwūd 3331, allow me to search this up with diacritics").
    func testAccentedNames() {
        let dawud = parse("Sunan Abī Dāwūd 3331")
        XCTAssertEqual(dawud?.book.slug, "abudawud")
        XCTAssertEqual(dawud?.hadith, 3331)
        XCTAssertEqual(parse("Ṣaḥīḥ al-Bukhārī 1")?.book.slug, "bukhari")
        XCTAssertEqual(parse("Jāmiʿ at-Tirmidhī 2664")?.book.slug, "tirmidhi")
        XCTAssertEqual(parse("Sunan an-Nasāʾī 100")?.book.slug, "nasai")
        XCTAssertEqual(parse("Sunan Ibn Mājah 224")?.book.slug, "ibnmajah")
        XCTAssertEqual(parse("Riyāḍ aṣ-Ṣāliḥīn 27")?.book.slug, "riyad_assalihin")
        XCTAssertEqual(parse("Mishkāt al-Maṣābīḥ 5")?.book.slug, "mishkat_almasabih")
        XCTAssertEqual(parse("Jami\u{2018} at-Tirmidhi 5")?.book.slug, "tirmidhi")
        // The looser shapes see the plain letters too: number first, glued, and decomposed accents.
        let numberFirst = parse("3331 Sunan Abī Dāwūd")
        XCTAssertEqual(numberFirst?.book.slug, "abudawud")
        XCTAssertEqual(numberFirst?.hadith, 3331)
        XCTAssertEqual(parse("Abī Dāwūd3331")?.hadith, 3331)
        XCTAssertEqual(parse("Sunan Abi\u{0304} Da\u{0304}wu\u{0304}d 3331")?.book.slug, "abudawud")
        XCTAssertEqual(HadithReferenceParser.book(named: "Sunan Abī Dāwūd")?.slug, "abudawud")
        // Inside the book its own accented name is optional, like the plain one.
        if let book = HadithCatalogBook.all.first(where: { $0.slug == "abudawud" }) {
            XCTAssertEqual(HadithReferenceParser.localQuery("Sunan Abī Dāwūd 3331", in: book), "3331")
        } else {
            XCTFail("Sunan Abi Dawud is missing from the catalog")
        }
    }

    /// C3: a name that fits no book, or no one book, and malformed numbers give nothing.
    func testNonReferences() {
        XCTAssertNil(parse("Hadith 24"))
        XCTAssertNil(parse("muslim 8a:3"))
        XCTAssertNil(parse("patience"))
        XCTAssertNil(parse(""))
        XCTAssertNil(parse("sunnah.com/"))
    }
}
