import XCTest
@testable import iPhone

/// The Tongue Twisters page (2026-11-17): its Quran phrases are cut by token from the app's own Hafs
/// text, and its own lines follow the app's teaching orthography.
final class TongueTwisterTests: XCTestCase {
    /// The letters alone: every mark off, every alif form folded to a bare alif.
    private func skeleton(_ text: String) -> String {
        var result = ""
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x064B...0x065F, 0x0670, 0x06D6...0x06ED: continue
            case 0x0671, 0x0623, 0x0625, 0x0622: result.unicodeScalars.append("\u{0627}")
            default: result.unicodeScalars.append(scalar)
            }
        }
        return result
    }

    func testQuranPhrasesAreTheMushafsWords() throws {
        let expected = [
            "hud48": "وعلى امم ممن معك",
            "hijr22": "فاسقينكموه",
            "hud28": "انلزمكموها",
            "baqarah137": "فسيكفيكهم الله",
        ]
        XCTAssertEqual(Set(QuranTongueTwister.all.map(\.id)), Set(expected.keys))
        for phrase in QuranTongueTwister.all {
            let arabic = try XCTUnwrap(phrase.arabic, "\(phrase.id) found no text")
            XCTAssertEqual(skeleton(arabic), expected[phrase.id], phrase.id)
            XCTAssertNil(arabic.unicodeScalars.first { (0x06D6...0x06DC).contains($0.value) },
                         "\(phrase.id) kept a waqf sign")
        }
    }

    func testLinesUseTheTeachingOrthography() {
        for twister in TongueTwisters.all {
            for line in twister.lines {
                // Scalars, not `String.contains`: Swift compares strings by canonical equivalence,
                // so a search for آ also matches the ا + ٓ it should be.
                let scalars = line.unicodeScalars.map(\.value)
                XCTAssertFalse(scalars.contains(0x0652), "\(twister.id): a plain sukoon, not the Uthmani ۡ")
                XCTAssertFalse(scalars.contains(0x0622), "\(twister.id): a precomposed آ, not ا + ٓ")
                for word in line.split(separator: " ") where word.hasPrefix("ال") || word.hasPrefix("وال") || word.hasPrefix("فال") {
                    XCTFail("\(twister.id): \(word) carries a plain alif on the article, not ٱ")
                }
            }
            XCTAssertFalse(twister.letters.isEmpty, twister.id)
            XCTAssertFalse(twister.reading.isEmpty, twister.id)
        }
        XCTAssertEqual(Set(TongueTwisters.all.map(\.id)).count, TongueTwisters.all.count, "duplicate ids")
    }

    func testEverySoundAlikePairHasATwister() {
        let drilled = TongueTwisters.all.map { Set($0.letters) }
        for pair in LetterTraits.soundAlikes {
            XCTAssertTrue(drilled.contains { $0.contains(pair.first) && $0.contains(pair.second) },
                          "no twister drills \(pair.first) and \(pair.second)")
        }
    }
}
