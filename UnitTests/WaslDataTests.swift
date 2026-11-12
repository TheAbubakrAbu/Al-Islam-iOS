import XCTest
@testable import iPhone

/// The hamzatul waSl page's phrases taken apart (Abu, 2026-11-08: "break down tanween and hamzatul
/// wasl more ... include Arabic in the test in how it's pronounced"): the forms derived from each
/// phrase's `saidAs`, and the hand-written Arabic for the two wrong readings, cross-checked against them.
final class WaslDataTests: XCTestCase {

    private static let wasla: Unicode.Scalar = "\u{0671}"

    /// The letters alone: every mark dropped, every alif shape (hamza seats, the waSl alif, madda,
    /// a dagger) read as a plain alif, the small waaw and yaa of the mushaf dropped.
    private func skeleton(_ text: String) -> String {
        var out = ""
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x064B...0x065F, 0x0670, 0x06D6...0x06ED, 0x06E5, 0x06E6, 0x0653...0x0655: continue
            case 0x0622, 0x0623, 0x0625, 0x0671: out.unicodeScalars.append("\u{0627}")
            case 0x20: continue
            default: out.unicodeScalars.append(scalar)
            }
        }
        return out
    }

    /// True when `longer` is `shorter` with exactly one scalar inserted somewhere.
    private func isOneInsertion(_ longer: String, over shorter: String) -> Bool {
        let a = Array(longer.unicodeScalars), b = Array(shorter.unicodeScalars)
        guard a.count == b.count + 1 else { return false }
        for skip in a.indices {
            var copy = a
            copy.remove(at: skip)
            if copy == b { return true }
        }
        return false
    }

    func testEveryPhraseHasTwoWrongReadingsInBothScripts() {
        for phrase in WaslData.phrases {
            XCTAssertEqual(phrase.wrong.count, 2, phrase.arabic)
            XCTAssertEqual(phrase.wrongArabic.count, 2, phrase.arabic)
            XCTAssertEqual(phrase.arabic.filter { $0 == " " }.count, 1, "one join per phrase: \(phrase.arabic)")
            XCTAssertEqual(phrase.saidAs.filter { $0 == " " }.count, 1, "saidAs keeps the one join: \(phrase.saidAs)")
        }
    }

    func testJoinedIsSaidAsInOneBreathWithNoWaslAlif() {
        for phrase in WaslData.phrases {
            XCTAssertFalse(phrase.joined.contains(" "), phrase.joined)
            XCTAssertFalse(phrase.joined.unicodeScalars.contains(Self.wasla), "the silent alif is gone: \(phrase.joined)")
            XCTAssertEqual(skeleton(phrase.joined), skeleton(phrase.saidAs))
        }
        let fil = WaslData.phrases.first { $0.reference == "2:11" }
        XCTAssertEqual(fil?.joined, "فِلۡأَرۡضِ")
        let nooh = WaslData.tanween.first { $0.reference == "11:42" }
        XCTAssertEqual(nooh?.joined, "نُوحُنِبۡنَهُۥ")
    }

    func testTanweenPhrasesDeriveTheNoonAndTheContrast() throws {
        for phrase in WaslData.tanween {
            let noonWritten = try XCTUnwrap(phrase.noonWritten, phrase.arabic)
            let without = try XCTUnwrap(phrase.withoutTanween, phrase.arabic)
            // The noon shows with a sukoon, and the printed second word, ٱ and all, follows.
            let words = noonWritten.split(separator: " ").map(String.init)
            XCTAssertEqual(words.count, 2, noonWritten)
            XCTAssertTrue(words[0].hasSuffix("\u{0646}\u{06E1}"), noonWritten)
            XCTAssertEqual(words[1], String(phrase.arabic.split(separator: " ")[1]), noonWritten)
            // Without the tanween: the same letters minus one noon, printed and joined.
            XCTAssertTrue(isOneInsertion(skeleton(noonWritten), over: skeleton(without.printed)), "\(without.printed) vs \(noonWritten)")
            XCTAssertTrue(isOneInsertion(skeleton(phrase.joined), over: skeleton(without.joined)), "\(phrase.joined) vs \(without.joined)")
            XCTAssertFalse(without.joined.contains(" "))
        }
        let nooh = try XCTUnwrap(WaslData.tanween.first { $0.reference == "11:42" })
        XCTAssertEqual(nooh.noonWritten, "نُوحُنۡ ٱبۡنَهُۥ")
        XCTAssertEqual(nooh.withoutTanween?.printed, "نُوحُ ٱبۡنَهُۥ")
        XCTAssertEqual(nooh.withoutTanween?.joined, "نُوحُبۡنَهُۥ")
        for phrase in WaslData.phrases where phrase.kind != .tanween {
            XCTAssertNil(phrase.noonWritten, phrase.arabic)
            XCTAssertNil(phrase.withoutTanween, phrase.arabic)
        }
    }

    func testWrongArabicMatchesTheSlipItNames() {
        for phrase in WaslData.phrases {
            let hamzaSaid = phrase.wrongArabic[0]
            let otherSlip = phrase.wrongArabic[1]
            XCTAssertNotEqual(hamzaSaid, phrase.joined, phrase.arabic)
            XCTAssertNotEqual(otherSlip, phrase.joined, phrase.arabic)
            XCTAssertNotEqual(hamzaSaid, otherSlip, phrase.arabic)
            // No wrong form keeps the waSl alif: it is either said as a hamza or dropped.
            XCTAssertFalse(hamzaSaid.unicodeScalars.contains(Self.wasla), hamzaSaid)
            XCTAssertFalse(otherSlip.unicodeScalars.contains(Self.wasla), otherSlip)

            // The hamza said: the same letters as the printed phrase (a tanween's as its written noon),
            // with a hamza seat where the ٱ was.
            let printed = phrase.noonWritten ?? phrase.arabic
            XCTAssertEqual(skeleton(hamzaSaid), skeleton(printed), "\(hamzaSaid) should be \(printed) with its hamza said")
            XCTAssertTrue(hamzaSaid.contains(" "), "the hamza said keeps the two words apart: \(hamzaSaid)")
            XCTAssertTrue(hamzaSaid.unicodeScalars.contains { $0 == "\u{0623}" || $0 == "\u{0625}" }, hamzaSaid)

            // The other slip is said in one breath: the right letters with a wrong mark, a long vowel
            // kept (one letter more), or a tanween's noon left off.
            XCTAssertFalse(otherSlip.contains(" "), otherSlip)
            let right = skeleton(phrase.joined)
            let slip = skeleton(otherSlip)
            let plainVowel = phrase.withoutTanween.map { skeleton($0.joined) }
            XCTAssertTrue(slip == right || isOneInsertion(slip, over: right) || slip == plainVowel,
                          "\(otherSlip) is not a one-move slip from \(phrase.joined)")
            switch phrase.kind {
            case .longVowel: XCTAssertTrue(isOneInsertion(slip, over: right), "a long vowel kept: \(otherSlip)")
            case .vowel, .sukoon: XCTAssertEqual(slip, right, "a wrong vowel only: \(otherSlip)")
            case .tanween: break
            }
        }
    }

    func testTanweenNoonDroppedSlipIsExactlyThePlainVowelForm() {
        // Thirteen of the fourteen tanween phrases name "the noon left off" as their second slip, and
        // that is the derived plain-vowel form to the byte. The fourteenth (14:26) names the wrong
        // vowel on the noon instead.
        var exact = 0
        for phrase in WaslData.tanween {
            if phrase.wrongArabic[1] == phrase.withoutTanween?.joined { exact += 1 }
            else { XCTAssertEqual(phrase.reference, "14:26", "\(phrase.wrongArabic[1]) vs \(phrase.withoutTanween?.joined ?? "")") }
        }
        XCTAssertEqual(exact, WaslData.tanween.count - 1)
    }

    func testStepsRunFromThePrintedPhraseToTheJoinedOne() {
        for phrase in WaslData.phrases {
            let steps = phrase.steps
            XCTAssertEqual(steps.count, phrase.kind == .tanween ? 4 : 3, phrase.arabic)
            XCTAssertEqual(steps.first?.arabic, phrase.arabic)
            XCTAssertEqual(steps.last?.arabic, phrase.joined)
            XCTAssertEqual(Set(steps.map(\.id)).count, steps.count, "distinct rungs: \(phrase.arabic)")
            if phrase.kind == .tanween { XCTAssertEqual(steps[1].arabic, phrase.noonWritten) }
            XCTAssertEqual(steps[steps.count - 2].arabic, phrase.saidAs)
        }
    }

    func testTanweenWordsWriteTheNoonOut() {
        let plain = "\u{0652}"
        XCTAssertEqual(TanweenWord.all.map(\.tanweenName), ["Dammatayn", "Fathatayn", "Kasratayn"])
        XCTAssertEqual(TanweenWord.all[0].word, "كِتَابٌ")
        XCTAssertEqual(TanweenWord.all[0].writtenOut(sukoon: plain), "كِتَابُنْ")
        XCTAssertEqual(TanweenWord.all[1].word, "كِتَابًا")
        XCTAssertEqual(TanweenWord.all[1].writtenOut(sukoon: plain), "كِتَابَنْ", "the seat alif is gone")
        XCTAssertEqual(TanweenWord.all[2].word, "كِتَابٍ")
        XCTAssertEqual(TanweenWord.all[2].writtenOut(sukoon: plain), "كِتَابِنْ")
        XCTAssertEqual(TanweenWord.all[0].writtenOut(sukoon: "\u{06E1}"), "كِتَابُنۡ")
        // The letter tables' own writer agrees on the ending.
        for word in TanweenWord.all {
            let letterForm = tanweenWrittenOut(letter: "ب", tanweenName: word.tanweenName, sukoon: plain)
            XCTAssertEqual(letterForm, "ب" + word.vowel + "\u{0646}" + plain, word.tanweenName)
        }
    }
}
