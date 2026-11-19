import XCTest
@testable import iPhone

/// The Legend's Signs page (2026-11-17): each card's example is cut by token from the app's own Hafs
/// text, so a shifted range would show words without the sign it is meant to show.
final class StopSignTests: XCTestCase {
    private func hafsText(surah: Int, ayah: Int) throws -> String {
        let found = try XCTUnwrap(QuranData.shared.ayah(surah: surah, ayah: ayah), "\(surah):\(ayah) is not loaded")
        return found.rawArabicText(surahId: surah, qiraahOverride: Settings.Riwayah.hafsTag)
    }

    /// Every sign has an example since 2026-11-18 (Abu: "give examples for each").
    func testEverySignHasAnExampleThatCarriesIt() throws {
        for sign in StopSignInfo.all {
            XCTAssertNotNil(sign.example, "\(sign.key) has no example")
            let phrase = try XCTUnwrap(sign.examplePhrase, "\(sign.key) found no text")
            let scalars = Set(phrase.unicodeScalars.map(\.value))
            XCTAssertFalse(sign.marks.isDisjoint(with: scalars), "\(sign.key): the example has no \(sign.symbol)")
        }
    }

    func testTheLegendHasEverythingItShows() {
        XCTAssertEqual(Set(StopSignInfo.all.map(\.key)).count, StopSignInfo.all.count, "duplicate keys")
        for sign in StopSignInfo.all {
            XCTAssertFalse(sign.gist.isEmpty, sign.key)
            XCTAssertFalse(sign.meaning.isEmpty, sign.key)
            XCTAssertFalse(sign.marks.isEmpty, sign.key)
            XCTAssertNotNil(sign.arabicName, sign.key)
        }
    }

    /// A sign an example ADDS is one the app's text does not print (لا). The day the text carries it,
    /// the example would show it twice: this fails then, and `addsMark` goes.
    func testAnAddedSignIsOneTheTextDoesNotPrint() throws {
        for sign in StopSignInfo.all {
            guard let place = sign.example, let added = place.addsMark else { continue }
            XCTAssertTrue(place.words.contains(added.word), "\(sign.key): the sign is set on a word outside the cut")
            XCTAssertTrue(sign.marks.contains(added.scalar), "\(sign.key): the added sign is not one of its marks")

            let text = try hafsText(surah: place.surah, ayah: place.ayah)
            XCTAssertFalse(text.unicodeScalars.contains { $0.value == added.scalar },
                           "\(sign.key): the Hafs text prints the sign now, so the example must not add it")

            let phrase = try XCTUnwrap(sign.examplePhrase)
            let words = WordTokens.tokens(in: phrase)
            let marked = words.indices.filter { index in words[index].unicodeScalars.contains { $0.value == added.scalar } }
            XCTAssertEqual(marked, [added.word - place.words.lowerBound], "\(sign.key): the sign sits on the wrong word")
            // The word under the sign is still the text's own, with nothing else changed.
            let source = WordTokens.tokens(in: text)[added.word]
            XCTAssertEqual(String(words[marked[0]].unicodeScalars.dropLast()), source)
        }
    }

    /// Must Continue is the sign the app's text lacks; its example is the place the Madinah mushaf's
    /// guide gives, with the sign after "tayyibeen".
    func testMustContinueShowsItsSignAfterTayyibeen() throws {
        let sign = try XCTUnwrap(StopSignInfo.all.first { $0.key == "mustContinue" })
        let place = try XCTUnwrap(sign.example)
        XCTAssertEqual([place.surah, place.ayah], [16, 32])
        let added = try XCTUnwrap(place.addsMark)
        XCTAssertEqual(added.scalar, 0x06D9)
        let word = WordTokens.tokens(in: try hafsText(surah: 16, ayah: 32))[added.word]
        XCTAssertEqual(word.arabicLettersOnlyForTest, "طيبين")
    }

    /// The end-of-ayah ring is drawn by the Quran face from the ayah's number, after the last word.
    func testAyahEndClosesWithItsNumber() throws {
        let sign = try XCTUnwrap(StopSignInfo.all.first { $0.key == "ayahEnd" })
        let place = try XCTUnwrap(sign.example)
        XCTAssertTrue(place.endsWithNumber)
        let words = WordTokens.tokens(in: try XCTUnwrap(sign.examplePhrase))
        XCTAssertEqual(words.last, arabicNumberString(from: place.ayah))
        XCTAssertEqual(words.count, place.words.count + 1)
        // The whole ayah, or the ring would close words that are not its end.
        XCTAssertEqual(place.words.upperBound, WordTokens.count(in: try hafsText(surah: place.surah, ayah: place.ayah)) - 1)
    }
}

private extension String {
    /// The base letters alone (U+0621 to U+064A), for comparing a vocalized word with a plain one.
    var arabicLettersOnlyForTest: String {
        String(String.UnicodeScalarView(unicodeScalars.filter { (0x0621...0x064A).contains($0.value) }))
    }
}
