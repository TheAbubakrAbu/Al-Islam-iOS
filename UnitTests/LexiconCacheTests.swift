import XCTest
@testable import iPhone

/// The cross-language lexicon is kept in Caches between launches (Phase 10.11). The file is only ever
/// read by the same build that wrote it, so the one thing that can go wrong is the codec itself: this
/// round-trips a table shaped like the real one (folded Arabic keys, ASCII gloss words, one to twelve
/// words per key) and checks that damaged bytes are refused rather than decoded into a wrong table.
final class LexiconCacheTests: XCTestCase {

    private static let sample: [String: Set<String>] = [
        "الصبر": ["patience", "patient"],
        "رحمة": ["mercy"],
        "كتاب": ["book", "scripture", "decree", "written", "record"],
        "a": ["x"],
        "مؤمنون": ["believers", "believe", "faithful", "faith", "those", "trust", "secure", "amen", "belief", "certain", "sure", "safe"],
        "ٱلرَّحِيم": ["merciful"],
        "": ["empty"],
        "بسم الله": ["name", "allah"],
    ]

    func testRoundTripIsExact() {
        let data = CrossLanguageWordHighlight.encodeLexiconForTests(Self.sample)
        XCTAssertFalse(data.isEmpty)
        XCTAssertEqual(CrossLanguageWordHighlight.decodeLexiconForTests(data), Self.sample)
    }

    func testEncodingIsStableForOneTable() {
        // Sets iterate in a per-process order; the file must not depend on it.
        let first = CrossLanguageWordHighlight.encodeLexiconForTests(Self.sample)
        let second = CrossLanguageWordHighlight.encodeLexiconForTests(Self.sample)
        XCTAssertEqual(first, second)
    }

    func testEmptyTableRoundTrips() {
        let data = CrossLanguageWordHighlight.encodeLexiconForTests([:])
        XCTAssertEqual(CrossLanguageWordHighlight.decodeLexiconForTests(data), [:])
    }

    func testDamagedDataIsRefused() {
        let data = CrossLanguageWordHighlight.encodeLexiconForTests(Self.sample)
        XCTAssertNil(CrossLanguageWordHighlight.decodeLexiconForTests(Data()))
        XCTAssertNil(CrossLanguageWordHighlight.decodeLexiconForTests(data.prefix(data.count - 1)))
        XCTAssertNil(CrossLanguageWordHighlight.decodeLexiconForTests(data + Data([0])))
        var wrongMagic = data
        wrongMagic[0] = wrongMagic[0] &+ 1
        XCTAssertNil(CrossLanguageWordHighlight.decodeLexiconForTests(wrongMagic))
        var wrongFormat = data
        wrongFormat[4] = wrongFormat[4] &+ 1
        XCTAssertNil(CrossLanguageWordHighlight.decodeLexiconForTests(wrongFormat))
    }
}
