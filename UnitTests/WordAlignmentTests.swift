import XCTest
@testable import iPhone

/// The bundled word alignment (`WordAlignmentStore`, built by `Scripts/build_word_alignment.py`):
/// which Arabic word each English word of a translation renders. The store must line up with the
/// texts the app shows for every ayah, and answer nil the moment it does not, because a pack one
/// word off lights the NEIGHBOURING word.
final class WordAlignmentTests: XCTestCase {

    private let store = WordAlignmentStore.shared

    @MainActor
    private func ready() async throws {
        await QuranData.shared.waitUntilLoaded()
        try XCTSkipIf(Settings.shared.displayQiraahForArabic != nil,
                      "the alignment is Hafs: launch once with -displayQiraah \"\" first")
    }

    @MainActor
    private func text(_ surah: Int, _ ayah: Int) throws -> (arabic: String, saheeh: String, mustafa: String) {
        let found = try XCTUnwrap(QuranData.shared.ayah(surah: surah, ayah: ayah), "\(surah):\(ayah)")
        return (found.rawArabicText(surahId: surah), found.textEnglishSaheeh, found.textEnglishMustafa)
    }

    /// The folded Arabic word the first English token spelled `word` points at.
    @MainActor
    private func arabicWord(under word: String, _ surah: Int, _ ayah: Int,
                            _ translation: WordAlignmentStore.Translation) throws -> String? {
        let text = try text(surah, ayah)
        let english = translation == .saheeh ? text.saheeh : text.mustafa
        let alignment = try XCTUnwrap(store.arabicTokens(
            surah: surah, ayah: ayah, translation: translation, english: english,
            rawArabic: text.arabic, displayArabic: text.arabic), "\(surah):\(ayah) does not line up")
        let ns = english as NSString
        let letters = CharacterSet.letters
        let tokens = WordAlignmentStore.englishTokenRanges(in: english)
            .map { ns.substring(with: $0).trimmingCharacters(in: letters.inverted) }
        let index = try XCTUnwrap(tokens.firstIndex(of: word), "no \(word) in \(english)")
        guard let arabicIndex = alignment[index] else { return nil }
        let arabic = WordTokens.tokens(in: text.arabic)
        return HighlightedSnippet.normalizeForSearchText(arabic[arabicIndex], trimWhitespace: true)
    }

    func testThePackIsInTheBundle() {
        XCTAssertTrue(WordAlignmentStore.isBundled)
    }

    func testEnglishTokensEndAtWhitespaceAndLongDashes() {
        let text = "a \u{2018}human\u{2019} life\u{2014}made sacred by Allah\u{2014}except"
        let ns = text as NSString
        let tokens = WordAlignmentStore.englishTokenRanges(in: text).map { ns.substring(with: $0) }
        XCTAssertEqual(tokens, ["a", "\u{2018}human\u{2019}", "life", "made", "sacred", "by", "Allah", "except"])
    }

    /// All 6,236 ayahs, both translations: the pack's counts are the live texts' counts, and every
    /// index names a word the ayah has.
    @MainActor
    func testEveryAyahLinesUp() async throws {
        try await ready()
        var checked = 0
        var misaligned: [String] = []
        for surah in QuranData.shared.quran {
            // With a riwayah's texts loaded a surah also lists the ayah numbers only that riwayah
            // has (2:287 in the Basri count): they carry no Hafs text and the pack has no row for them.
            for ayah in surah.ayahs where !ayah.textHafs.isEmpty {
                let arabic = ayah.rawArabicText(surahId: surah.id)
                let arabicCount = WordTokens.count(in: arabic)
                for (translation, english) in [(WordAlignmentStore.Translation.saheeh, ayah.textEnglishSaheeh),
                                               (.mustafa, ayah.textEnglishMustafa)] {
                    guard let alignment = store.arabicTokens(
                        surah: surah.id, ayah: ayah.id, translation: translation, english: english,
                        rawArabic: arabic, displayArabic: arabic) else {
                        misaligned.append("\(surah.id):\(ayah.id) \(translation)")
                        continue
                    }
                    checked += 1
                    if alignment.count != WordAlignmentStore.englishTokenRanges(in: english).count
                        || alignment.contains(where: { ($0 ?? 0) >= arabicCount }) {
                        misaligned.append("\(surah.id):\(ayah.id) \(translation) (index out of range)")
                    }
                }
            }
        }
        XCTAssertEqual(misaligned.prefix(10).map { $0 }, [], "\(misaligned.count) ayah lines do not line up: rerun Scripts/build_word_alignment.py")
        XCTAssertEqual(checked, 6236 * 2)
    }

    /// Pairs the gloss could never have found: its wording is "All-Aware" and "the trumpet".
    @MainActor
    func testPinnedPairs() async throws {
        try await ready()
        XCTAssertEqual(try arabicWord(under: "Acquainted", 57, 10, .saheeh), "خبير")
        XCTAssertEqual(try arabicWord(under: "Horn", 23, 101, .saheeh), "الصور")
        XCTAssertEqual(try arabicWord(under: "straight", 1, 6, .saheeh), "المستقيم")
        XCTAssertEqual(try arabicWord(under: "path", 1, 6, .saheeh), "الصراط")
        XCTAssertEqual(try arabicWord(under: "Straight", 1, 6, .mustafa), "المستقيم")
        XCTAssertEqual(try arabicWord(under: "worlds", 1, 2, .mustafa), "العالمين")
        // A glue word renders no word of its own.
        XCTAssertNil(try arabicWord(under: "the", 1, 6, .saheeh))
    }

    /// Khattab, the freer translation. Each of these was unaligned or wrong while one model ran
    /// over whole ayahs: a rare rendering of a frequent word ("responded" for قَالُواْ), a pair in
    /// crossed order ("ultimate triumph", ٱلۡفَوۡزُ ٱلۡعَظِيمُ) and a synonym seen once ("arrogance").
    @MainActor
    func testKhattabPairsTheWholeAyahModelMissed() async throws {
        try await ready()
        XCTAssertEqual(try arabicWord(under: "responded", 41, 14, .mustafa), "قالوا")
        XCTAssertEqual(try arabicWord(under: "triumph", 57, 12, .mustafa), "الفوز")
        XCTAssertEqual(try arabicWord(under: "ultimate", 57, 12, .mustafa), "العظيم")
        XCTAssertEqual(try arabicWord(under: "arrogance", 38, 2, .mustafa), "عزه")
        // "pay alms-tax": the verb is the verb's, not a second word of ٱلزَّكَوٰةَ.
        let pay = try arabicWord(under: "pay", 2, 83, .mustafa)
        let alms = try arabicWord(under: "alms-tax", 2, 83, .mustafa)
        XCTAssertNotNil(pay)
        XCTAssertNotNil(alms)
        XCTAssertNotEqual(pay, alms)
    }

    /// A translation that is not the one the pack was built from: refused, never read one word off.
    @MainActor
    func testAChangedTranslationIsRefused() async throws {
        try await ready()
        let text = try text(1, 6)
        XCTAssertNotNil(store.arabicTokens(surah: 1, ayah: 6, translation: .saheeh, english: text.saheeh,
                                           rawArabic: text.arabic, displayArabic: text.arabic))
        XCTAssertNil(store.arabicTokens(surah: 1, ayah: 6, translation: .saheeh, english: text.saheeh + " indeed",
                                        rawArabic: text.arabic, displayArabic: text.arabic))
        XCTAssertNil(store.arabicTokens(surah: 1, ayah: 6, translation: .saheeh, english: text.saheeh,
                                        rawArabic: text.arabic + " كلمة", displayArabic: text.arabic + " كلمة"))
        XCTAssertNil(store.arabicTokens(surah: 115, ayah: 1, translation: .saheeh, english: text.saheeh,
                                        rawArabic: text.arabic, displayArabic: text.arabic))
        XCTAssertNil(store.arabicTokens(surah: 1, ayah: 8, translation: .saheeh, english: text.saheeh,
                                        rawArabic: text.arabic, displayArabic: text.arabic))
    }

    /// 2:26 opens with the ۞ sign as a word of its own. "Hide Tashkeel and Signs" drops it from the
    /// page, so every displayed word sits one index below the pack's: the store moves with it.
    @MainActor
    func testHiddenSignsShiftTheIndices() async throws {
        try await ready()
        let text = try text(2, 26)
        let rawTokens = WordTokens.tokens(in: text.arabic)
        XCTAssertTrue(rawTokens[0].removingArabicDiacriticsAndSigns.trimmingCharacters(in: .whitespaces).isEmpty,
                      "2:26 no longer opens with a sign-only word: pick another ayah")
        let displayed = rawTokens.dropFirst().joined(separator: " ")
        let raw = try XCTUnwrap(store.arabicTokens(surah: 2, ayah: 26, translation: .saheeh, english: text.saheeh,
                                                   rawArabic: text.arabic, displayArabic: text.arabic))
        let shifted = try XCTUnwrap(store.arabicTokens(surah: 2, ayah: 26, translation: .saheeh, english: text.saheeh,
                                                       rawArabic: text.arabic, displayArabic: displayed))
        XCTAssertEqual(raw.count, shifted.count)
        XCTAssertFalse(raw.contains(0), "an English word points at the sign")
        XCTAssertGreaterThan(raw.compactMap { $0 }.count, 10)
        XCTAssertEqual(shifted, raw.map { $0.map { $0 - 1 } })
    }
}
