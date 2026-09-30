import XCTest
@testable import iPhone

/// Hide Arabic Dots: `String.removingArabicDots` and the tajweed projection must map scalar by
/// scalar through the one table, `ArabicRasm.dotless` (the private `dotlessArabicScalar` forwards to it).
final class ArabicDotsTests: XCTestCase {

    /// The dotted letters (and ta marbuta) the table must leave none of.
    private static let dottedLetters: Set<UInt32> = [
        0x0628, 0x062A, 0x062B, 0x062C, 0x062E, 0x0630, 0x0632, 0x0634,
        0x0636, 0x0638, 0x063A, 0x0641, 0x0642, 0x0646, 0x064A, 0x0629,
    ]

    /// Maps each scalar through the table, the reference the string transform must equal.
    private func scalarMapped(_ text: String) -> String {
        var out = String.UnicodeScalarView()
        for scalar in text.unicodeScalars { out.append(ArabicRasm.dotless(scalar)) }
        return String(out)
    }

    /// A1: the transform equals the per-scalar map and keeps the scalar and UTF-16 counts.
    func testTransformIsThePerScalarMap() {
        let samples = [
            "\u{0628}\u{0650}\u{0633}\u{06E1}\u{0645}\u{0650} \u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{0650}",   // بِسۡمِ ٱللَّهِ
            "\u{0642}\u{064F}\u{0644}\u{0652} \u{0647}\u{064F}\u{0648}\u{064E} \u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{064F} \u{0623}\u{064E}\u{062D}\u{064E}\u{062F}\u{064C}",
            "\u{0627}\u{0653}\u{0644}\u{0645}",                               // alef + maddah, the A1 case
            "\u{0622}\u{0645}\u{0646}",                                       // precomposed alef with madda
            "\u{0625}\u{0650}\u{0646}\u{0651}\u{064E} \u{0624}\u{0626}\u{0629}",
            "Latin text, digits 123 and \u{0661}\u{0662}\u{0663}",
            "",
        ]
        for text in samples {
            let out = text.removingArabicDots
            XCTAssertEqual(out, scalarMapped(text), text)
            XCTAssertEqual(out.unicodeScalars.count, text.unicodeScalars.count, text)
            XCTAssertEqual(out.utf16.count, text.utf16.count, text)
        }
    }

    /// A1: alef + maddah (U+0627 U+0653) keeps its maddah; the old Character map deleted it.
    func testDecomposedMaddahSurvives() {
        let out = "\u{0627}\u{0653}".removingArabicDots
        XCTAssertEqual(Array(out.unicodeScalars.map(\.value)), [0x0627, 0x0653])
    }

    /// A1: a letter carrying a harakah still loses its dots (88% of dotted letters kept them before).
    func testVocalizedLettersLoseTheirDots() {
        // بِ نَ قُ يْ each with a mark.
        let out = "\u{0628}\u{0650}\u{0646}\u{064E}\u{0642}\u{064F}\u{064A}\u{0652}".removingArabicDots
        XCTAssertEqual(Array(out.unicodeScalars.map(\.value)),
                       [0x066E, 0x0650, 0x06BA, 0x064E, 0x066F, 0x064F, 0x0649, 0x0652])
    }

    /// A1: the table is one scalar to one scalar, never outputs a dotted letter, and is idempotent.
    func testTableIsClosedAndIdempotent() {
        for value in UInt32(0x0600)...UInt32(0x06FF) {
            guard let scalar = Unicode.Scalar(value) else { continue }
            let once = ArabicRasm.dotless(scalar)
            XCTAssertEqual(ArabicRasm.dotless(once), once, String(format: "U+%04X", value))
            XCTAssertFalse(Self.dottedLetters.contains(once.value), String(format: "U+%04X", value))
            XCTAssertEqual(String(once).utf16.count, String(scalar).utf16.count, String(format: "U+%04X", value))
        }
    }

    /// A1: over the whole Hafs text: same length, lockstep with the map, no dotted letter left, every maddah kept.
    @MainActor
    func testWholeHafsTextStaysInLockstep() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        XCTAssertEqual(data.quran.count, 114, "the Quran did not load")
        var ayahs = 0, dottedBefore = 0, maddahBefore = 0, maddahAfter = 0
        for surah in data.quran {
            // Skip the slots only other counts have (empty Hafs text, e.g. Basri's extra ayahs).
            for ayah in surah.ayahs where !ayah.textHafs.isEmpty {
                let raw = ayah.textHafs
                let out = raw.removingArabicDots
                ayahs += 1
                XCTAssertEqual(out.utf16.count, raw.utf16.count, "\(surah.id):\(ayah.id) changed length")
                XCTAssertEqual(out, scalarMapped(raw), "\(surah.id):\(ayah.id)")
                XCTAssertFalse(out.unicodeScalars.contains { Self.dottedLetters.contains($0.value) }, "\(surah.id):\(ayah.id)")
                dottedBefore += raw.unicodeScalars.filter { Self.dottedLetters.contains($0.value) }.count
                maddahBefore += raw.unicodeScalars.filter { $0.value == 0x0653 }.count
                maddahAfter += out.unicodeScalars.filter { $0.value == 0x0653 }.count
            }
        }
        XCTAssertEqual(ayahs, 6236)
        XCTAssertGreaterThan(dottedBefore, 100_000)
        XCTAssertGreaterThan(maddahBefore, 0)
        XCTAssertEqual(maddahAfter, maddahBefore)
    }

    /// A1: the tajweed projection (dotless, tashkeel shown) draws exactly the string the list reader draws.
    @MainActor
    func testTajweedProjectionMatchesTheStringTransform() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        var compared = 0
        for surahID in [1, 2, 18, 36] + Array(78...114) {
            guard let surah = data.surah(surahID) else { XCTFail("no surah \(surahID)"); continue }
            for ayah in surah.ayahs where !ayah.textHafs.isEmpty {
                let raw = ayah.rawArabicText(surahId: surahID, qiraahOverride: "")
                let listReader = ayah.displayArabicText(surahId: surahID, clean: false, removeDots: true, qiraahOverride: "")
                XCTAssertEqual(listReader, raw.removingArabicDots, "\(surahID):\(ayah.id) list reader")
                guard let painted = TajweedStore.shared.attributedText(
                    surah: surahID, ayah: ayah.id, text: raw, removeArabicDots: true) else { continue }
                XCTAssertEqual(String(painted.characters), listReader, "\(surahID):\(ayah.id) tajweed projection")
                compared += 1
            }
        }
        // Nil means no category painted (every tajweed category hidden in Settings); then nothing was compared.
        if compared == 0 { throw XCTSkip("tajweed painted nothing: every category is hidden on this simulator") }
    }
}
