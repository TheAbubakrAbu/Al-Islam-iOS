import XCTest
@testable import iPhone

/// The widget deep link (`QuranDeepLink.parseAyah`) and the Chosen Ayah picker's typed references
/// (`ChosenAyahReference.parse`).
final class AyahReferenceParsingTests: XCTestCase {

    private func parse(_ text: String) -> String? {
        ChosenAyahReference.parse(text).map { "\($0.surah):\($0.ayah)" }
    }

    // MARK: QuranDeepLink

    /// U18: an ayah link round-trips through the builder and the parser.
    func testDeepLinkRoundTrip() throws {
        for (surah, ayah) in [(1, 1), (2, 255), (36, 9), (114, 6)] {
            let url = try XCTUnwrap(QuranDeepLink.ayah(surah: surah, ayah: ayah))
            let parsed = try XCTUnwrap(QuranDeepLink.parseAyah(url), url.absoluteString)
            XCTAssertEqual(parsed.surah, surah)
            XCTAssertEqual(parsed.ayah, ayah)
        }
    }

    /// U18: the surah is the first path number and the ayah the second, never the other way.
    func testDeepLinkOrder() throws {
        let parsed = try XCTUnwrap(QuranDeepLink.parseAyah(URL(string: "alislam://ayah/2/255")!))
        XCTAssertEqual(parsed.surah, 2)
        XCTAssertEqual(parsed.ayah, 255)
    }

    /// U18: scheme and host compare case-insensitively.
    func testDeepLinkIsCaseInsensitive() throws {
        let parsed = try XCTUnwrap(QuranDeepLink.parseAyah(URL(string: "ALISLAM://AYAH/36/9")!))
        XCTAssertEqual(parsed.surah, 36)
        XCTAssertEqual(parsed.ayah, 9)
    }

    /// U18: any other shape of link is not an ayah.
    func testDeepLinkRejectsOtherURLs() {
        for text in ["alislam://surah/2/255", "https://ayah/2/255", "alislam://ayah/2", "alislam://ayah/2/255/1",
                     "alislam://ayah/two/255", "alislam://ayah/2/x"] {
            XCTAssertNil(QuranDeepLink.parseAyah(URL(string: text)!), text)
        }
    }

    // MARK: ChosenAyahReference

    /// U18: the guide's probe cases: a name then "S:A" takes the LAST number as the ayah.
    func testNameThenSurahColonAyah() {
        XCTAssertEqual(parse("Baqarah 2:255"), "2:255")
        XCTAssertEqual(parse("Al-Baqarah 2:255"), "2:255")
        XCTAssertEqual(parse("Yaseen 36:9"), "36:9")
        XCTAssertEqual(parse("An-Nas 114:1"), "114:1")
    }

    /// U18: every surah's widget title ("Al-Baqarah 2:255") parses back to itself, first and last ayah.
    func testWidgetTitleFormatRoundTripsForEverySurah() {
        for entry in ChosenAyahCatalog.surahs {
            for ayah in Set([1, entry.ayahCount]) {
                let title = ChosenAyahCatalog.reference(surah: entry.id, ayah: ayah)
                XCTAssertEqual(parse(title), "\(entry.id):\(ayah)", title)
            }
        }
    }

    /// U18: the plain number shapes the picker documents.
    func testNumericShapes() {
        XCTAssertEqual(parse("2:255"), "2:255")
        XCTAssertEqual(parse("2 255"), "2:255")
        XCTAssertEqual(parse("2.255"), "2:255")
        XCTAssertEqual(parse("36"), "36:1")
        XCTAssertEqual(parse("\u{0663}\u{0666}:\u{0669}"), "36:9")   // Arabic-Indic "36:9"
    }

    /// U18: a surah name with one number names the ayah in that surah.
    func testNameThenAyah() {
        XCTAssertEqual(parse("Baqarah 255"), "2:255")
        XCTAssertEqual(parse("surah al-baqarah ayah 255"), "2:255")
        XCTAssertEqual(parse("kursi 255"), "2:255")
        XCTAssertEqual(parse("Yaseen 9"), "36:9")
    }

    /// U18: references past the Quran's end resolve to nothing.
    func testOutOfRangeIsNil() {
        XCTAssertNil(parse("2:287"))
        XCTAssertNil(parse("115"))
        XCTAssertNil(parse("0:1"))
        XCTAssertNil(parse("An-Nas 114:7"))
        XCTAssertNil(parse(""))
        XCTAssertNil(parse("   "))
    }
}
