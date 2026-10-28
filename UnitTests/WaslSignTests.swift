import XCTest
@testable import iPhone

/// Hamzat al-wasl in the other notation (WaslSigns.swift): the Swift splice must reproduce the
/// engine's output byte for byte, the shipped sidecar must fit the shipped texts word for word, and
/// the tajweed painter's projection must come out identical to the display text it paints.
final class WaslSignTests: XCTestCase {

    /// The Quran loads asynchronously at launch: run after a quick suite, these checks met an empty
    /// text and counted nothing.
    override func setUp() async throws {
        await QuranData.shared.waitUntilLoaded()
    }

    /// Words as the engine and the splice count them: one per U+0020 scalar, never per `Character`
    /// (a space followed by a combining mark is one grapheme but still a word gap here).
    private func wordCount(_ text: String) -> Int {
        text.unicodeScalars.reduce(1) { $0 + ($1.value == 0x20 ? 1 : 0) }
    }

    /// W1: the splice equals the Python reference on every generated sample (150 ayahs across the
    /// twenty texts, al-Fatihah to the tricky ones: al-ismu 49:11, a-llahu 10:59, a-bi-llahi 9:65).
    func testSpliceMatchesTheEngine() {
        XCTAssertGreaterThan(WaslSignSamples.all.count, 100)
        for sample in WaslSignSamples.all {
            XCTAssertEqual(WaslSignTransform.apply(sample.text, codes: sample.codes), sample.expected,
                           "\(sample.tag) \(sample.surah):\(sample.ayah)")
        }
    }

    /// W1: a word with no code, an empty code string and a code string shorter than the text leave
    /// the text alone; a code never touches another word.
    func testSpliceEdges() {
        let basmala = WaslSignSamples.all.first { $0.tag == "Hafs" && $0.surah == 1 && $0.ayah == 1 }!
        XCTAssertEqual(WaslSignTransform.apply(basmala.text, codes: ""), basmala.text)
        XCTAssertEqual(WaslSignTransform.apply(basmala.text, codes: "...."), basmala.text)
        // only the second word (Allah) changes under ".4"
        let partial = WaslSignTransform.apply(basmala.text, codes: ".4")
        let words = partial.split(separator: " ", omittingEmptySubsequences: false)
        let original = basmala.text.split(separator: " ", omittingEmptySubsequences: false)
        XCTAssertEqual(words.count, original.count)
        XCTAssertEqual(words[0], original[0]); XCTAssertEqual(words[2], original[2]); XCTAssertEqual(words[3], original[3])
        XCTAssertNotEqual(words[1], original[1])
        XCTAssertFalse(words[1].unicodeScalars.contains(WaslSignTransform.wasla))
    }

    /// W2: the sidecar is bundled, and for Hafs and the seven bundled riwayat every code string is
    /// exactly one character per word of the text it describes, and every Hafs ayah with a wasla
    /// has codes (so no alef is left in the saad form under the Dot setting).
    func testSidecarFitsTheShippedTexts() {
        let data = QuranData.shared
        let store = WaslSignStore.shared
        XCTAssertNotNil(store.codes(qiraah: nil, surah: 1, ayah: 1, style: .dot), "WaslSigns.json.xz is not bundled or has no Hafs 1:1")
        XCTAssertNil(store.codes(qiraah: nil, surah: 1, ayah: 1, style: .saad), "Hafs already writes the saad")
        XCTAssertNil(store.codes(qiraah: nil, surah: 1, ayah: 1, style: .print))

        var hafsAyahs = 0, hafsWithCodes = 0
        for surah in data.quran {
            for ayah in surah.ayahs {
                let raw = ayah.rawArabicText(surahId: surah.id, qiraahOverride: "")
                guard !raw.isEmpty else { continue }
                hafsAyahs += 1
                let words = wordCount(raw)
                let hasWasla = raw.unicodeScalars.contains(WaslSignTransform.wasla)
                if let codes = store.codes(qiraah: nil, surah: surah.id, ayah: ayah.id, style: .dot) {
                    hafsWithCodes += 1
                    XCTAssertEqual(codes.count, words, "Hafs \(surah.id):\(ayah.id) codes do not fit the words")
                    let dot = ayah.displayArabicText(surahId: surah.id, clean: false, removeDots: false, qiraahOverride: "", waslSign: .dot)
                    XCTAssertFalse(dot.unicodeScalars.contains(WaslSignTransform.wasla), "Hafs \(surah.id):\(ayah.id) keeps a saad under Dot")
                    XCTAssertEqual(wordCount(dot), words)
                } else {
                    XCTAssertFalse(hasWasla, "Hafs \(surah.id):\(ayah.id) has a wasla but no codes")
                }
            }
        }
        XCTAssertEqual(hafsAyahs, 6236)
        XCTAssertEqual(hafsWithCodes, 4798, "ayahs of Hafs with a wasl alef (the engine's count)")

        // The seven bundled riwayat are only loaded when the reader has them on screen (the overlay
        // follows `showQiraahDetails`); on a fresh simulator this half of the check has nothing to read.
        guard data.quran.first?.ayahs.first?.textWarsh != nil else {
            print("WaslSignTests: riwayah overlay not loaded, the bundled riwayat were not checked")
            return
        }
        for tag in [Settings.Riwayah.warsh, Settings.Riwayah.qaloon, Settings.Riwayah.duri, Settings.Riwayah.susi,
                    Settings.Riwayah.buzzi, Settings.Riwayah.qunbul, Settings.Riwayah.shubah] {
            var checked = 0
            for surah in data.quran {
                for ayah in surah.ayahs where ayah.existsInQiraah(tag, surahID: surah.id) {
                    let raw = ayah.rawArabicText(surahId: surah.id, qiraahOverride: tag)
                    let style: Settings.WaslSignStyle = Settings.dotWaslRiwayahTags.contains(tag) ? .saad : .dot
                    guard let codes = store.codes(qiraah: tag, surah: surah.id, ayah: ayah.id, style: style) else { continue }
                    checked += 1
                    XCTAssertEqual(codes.count, wordCount(raw), "\(tag) \(surah.id):\(ayah.id) codes do not fit the words")
                }
            }
            XCTAssertGreaterThan(checked, 4500, tag)
        }
    }

    /// W3: the raw text never changes: `rawArabicText` is what tajweed, word-by-word and the
    /// alignments key on, and it ignores the setting by construction.
    func testRawTextIgnoresTheSetting() {
        let data = QuranData.shared
        guard let fatihah = data.quran.first(where: { $0.id == 1 }), let ayah = fatihah.ayahs.first(where: { $0.id == 2 }) else {
            return XCTFail("no 1:2")
        }
        let raw = ayah.rawArabicText(surahId: 1, qiraahOverride: "")
        XCTAssertTrue(raw.unicodeScalars.contains(WaslSignTransform.wasla))
        let dot = ayah.displayArabicText(surahId: 1, clean: false, removeDots: false, qiraahOverride: "", waslSign: .dot)
        XCTAssertNotEqual(dot, raw)
        XCTAssertEqual(ayah.displayArabicText(surahId: 1, clean: false, removeDots: false, qiraahOverride: "", waslSign: .print), raw)
        XCTAssertEqual(ayah.displayArabicText(surahId: 1, clean: false, removeDots: false, qiraahOverride: "", waslSign: .saad), raw)
        // Hide Tashkeel has neither notation: the same stripped text whatever the setting
        XCTAssertEqual(ayah.displayArabicText(surahId: 1, clean: true, removeDots: false, qiraahOverride: "", waslSign: .dot),
                       ayah.displayArabicText(surahId: 1, clean: true, removeDots: false, qiraahOverride: "", waslSign: .print))
    }

    /// W4: the tajweed projection under Dot comes out byte-identical to the display text (the
    /// mushaf page's justification transplant and word-by-word align the two by offset), on the
    /// surahs the painter colours most densely and the ones that open with a wasl word.
    func testTajweedProjectionMatchesTheDotText() {
        let data = QuranData.shared
        var painted = 0
        for sid in [1, 2, 18, 36, 47, 55, 67, 112, 113, 114] {
            guard let surah = data.quran.first(where: { $0.id == sid }) else { continue }
            for ayah in surah.ayahs.prefix(60) {
                let raw = ayah.rawArabicText(surahId: sid, qiraahOverride: "")
                let display = ayah.displayArabicText(surahId: sid, clean: false, removeDots: false, qiraahOverride: "", waslSign: .dot)
                guard let styled = TajweedStore.shared.attributedText(surah: sid, ayah: ayah.id, text: raw, displayText: display,
                                                                       cleanDisplayText: false, beginnerSpacing: false,
                                                                       removeArabicDots: false, waslSign: .dot) else { continue }
                painted += 1
                XCTAssertEqual(String(styled.characters), display, "\(sid):\(ayah.id) painted text drifts from the dot text")
            }
        }
        XCTAssertGreaterThan(painted, 200, "the painter coloured almost nothing")
    }
}
