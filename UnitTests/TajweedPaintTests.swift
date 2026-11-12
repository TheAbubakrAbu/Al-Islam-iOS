import XCTest
import SwiftUI
import UIKit
@testable import iPhone

/// The Hafs tajweed painter, one letter at a time (Quality Guide, Phase 8).
///
/// Each case names a letter of the shipped text and the rule the reader sees on it, through
/// `TajweedStore.ruleCategories`, which resolves overlapping rules exactly the way the screen does.
/// The sites are a sample of the 2026-10-04 fixes; the whole-Quran diff that backs each fix ran
/// outside the app (a copy of the painter over all 6,236 ayahs).
@MainActor
final class TajweedPaintTests: XCTestCase {

    private struct Site {
        let surah: Int
        let ayah: Int
        /// The word as the pack spells it, written as scalars so the file stays plain.
        let word: String
        /// The letter or mark inside the word, and which of its occurrences there (0 is the first).
        let scalar: UInt32
        var occurrence = 0
        var reference: String { "\(surah):\(ayah)" }
    }

    private func rules(at site: Site, file: StaticString = #filePath, line: UInt = #line) async throws -> [TajweedLegendCategory] {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        guard TajweedLegendCategory.allCases.allSatisfy(Settings.shared.isTajweedCategoryVisible) else {
            throw XCTSkip("a tajweed category is hidden in this simulator's settings")
        }
        let ayah = try XCTUnwrap(data.ayah(surah: site.surah, ayah: site.ayah), "no ayah \(site.reference)", file: file, line: line)
        let raw = ayah.rawArabicText(surahId: site.surah, qiraahOverride: "")
        let wordRange = (raw as NSString).range(of: site.word)
        guard wordRange.location != NSNotFound else {
            XCTFail("\(site.reference): the word is not in the text", file: file, line: line)
            return []
        }
        let units = Array(site.word.utf16)
        let hits = units.indices.filter { UInt32(units[$0]) == site.scalar }
        guard hits.indices.contains(site.occurrence) else {
            XCTFail(String(format: "\(site.reference): U+%04X not in the word", site.scalar), file: file, line: line)
            return []
        }
        let letter = NSRange(location: wordRange.location + hits[site.occurrence], length: 1)
        return TajweedStore.shared.ruleCategories(surah: site.surah, ayah: site.ayah, text: raw, wordRange: letter)
    }

    private func assertRule(_ site: Site, is expected: TajweedLegendCategory,
                            file: StaticString = #filePath, line: UInt = #line) async throws {
        let found = try await rules(at: site, file: file, line: line)
        XCTAssertEqual(found, [expected], "\(site.reference): found \(found.map(\.rawValue))", file: file, line: line)
    }

    /// J1: a maddah with no hamza, shadda or sukoon after it is two counts (madd badal, a madd at the
    /// stop). It was painted Madd Lazim at 278 sites.
    func testMaddBadalIsNotLazim() async throws {
        // ٱلۡأٓخِرَةِ
        try await assertRule(Site(surah: 2, ayah: 4, word: "\u{0671}\u{0644}\u{06E1}\u{0623}\u{0653}\u{062E}\u{0650}\u{0631}\u{064E}\u{0629}\u{0650}", scalar: 0x0653), is: .maddNatural)
        // لِأٓدَمَ
        try await assertRule(Site(surah: 2, ayah: 34, word: "\u{0644}\u{0650}\u{0623}\u{0653}\u{062F}\u{064E}\u{0645}\u{064E}", scalar: 0x0653), is: .maddNatural)
        // ضَلُّوٓاْ, the madd at the stop
        try await assertRule(Site(surah: 20, ayah: 92, word: "\u{0636}\u{064E}\u{0644}\u{0651}\u{064F}\u{0648}\u{0653}\u{0627}\u{0652}", scalar: 0x0653), is: .maddNatural)
    }

    /// J1: the true Lazim sites keep it (148 in the Hafs text).
    func testMaddLazimSitesStayLazim() async throws {
        // ٱلضَّآلِّينَ
        try await assertRule(Site(surah: 1, ayah: 7, word: "\u{0671}\u{0644}\u{0636}\u{0651}\u{064E}\u{0627}\u{0653}\u{0644}\u{0651}\u{0650}\u{064A}\u{0646}\u{064E}", scalar: 0x0653), is: .maddNecessary)
        // ٱلۡحَآقَّةُ
        try await assertRule(Site(surah: 69, ayah: 1, word: "\u{0671}\u{0644}\u{06E1}\u{062D}\u{064E}\u{0627}\u{0653}\u{0642}\u{0651}\u{064E}\u{0629}\u{064F}", scalar: 0x0653), is: .maddNecessary)
        // ءَآلۡـَٰٔنَ, a sukoon after the madd
        try await assertRule(Site(surah: 10, ayah: 51, word: "\u{0621}\u{064E}\u{0627}\u{0653}\u{0644}\u{06E1}\u{0640}\u{0654}\u{064E}\u{0670}\u{0646}\u{064E}", scalar: 0x0653), is: .maddNecessary)
        // الٓمٓ, a muqatta'at letter
        try await assertRule(Site(surah: 2, ayah: 1, word: "\u{0627}\u{0644}\u{0653}\u{0645}\u{0653}", scalar: 0x0653), is: .maddNecessary)
    }

    /// J2: the alif under the small upright zero is dropped in connected reading.
    func testAlifUnderTheUprightZeroIsDropped() async throws {
        // أَنَا۠
        try await assertRule(Site(surah: 2, ayah: 258, word: "\u{0623}\u{064E}\u{0646}\u{064E}\u{0627}\u{06E0}", scalar: 0x0627), is: .droppedLetter)
    }

    /// The four that END an ayah are read at the stop and stay unpainted (J2). After a heavy raa the alif
    /// took the raa's weight instead: قَوَارِيرَا۠ (76:15) was the one alif in the Quran drawn heavy blue
    /// until 2026-10-28 (Abu's screenshot).
    func testAyahFinalAlifUnderTheUprightZeroStaysUnpainted() async throws {
        // قَوَارِيرَا۠, after a heavy raa
        let qawareera = Site(surah: 76, ayah: 15, word: "\u{0642}\u{064E}\u{0648}\u{064E}\u{0627}\u{0631}\u{0650}\u{064A}\u{0631}\u{064E}\u{0627}\u{06E0}", scalar: 0x0627, occurrence: 1)
        let found = try await rules(at: qawareera)
        XCTAssertEqual(found, [], "\(qawareera.reference): found \(found.map(\.rawValue))")
        // ٱلظُّنُونَا۠, after a light noon
        let thunoona = Site(surah: 33, ayah: 10, word: "\u{0671}\u{0644}\u{0638}\u{064F}\u{0651}\u{0646}\u{064F}\u{0648}\u{0646}\u{064E}\u{0627}\u{06E0}", scalar: 0x0627)
        let other = try await rules(at: thunoona)
        XCTAssertEqual(other, [], "\(thunoona.reference): found \(other.map(\.rawValue))")
    }

    /// J4 and J5: a saakin raa is heavy after hamzatul-wasl, and after a kasra when an open isti'la
    /// letter follows it in the same word. A kasra on that letter leaves the choice open, and the
    /// painter keeps it light.
    func testSaakinRaaWeight() async throws {
        // ٱرۡجِعُوٓاْ, started on, the hamza's kasra is incidental
        try await assertRule(Site(surah: 12, ayah: 81, word: "\u{0671}\u{0631}\u{06E1}\u{062C}\u{0650}\u{0639}\u{064F}\u{0648}\u{0653}\u{0627}\u{0652}", scalar: 0x0631), is: .tafkhim)
        // قِرۡطَاسٖ
        try await assertRule(Site(surah: 6, ayah: 7, word: "\u{0642}\u{0650}\u{0631}\u{06E1}\u{0637}\u{064E}\u{0627}\u{0633}\u{0656}", scalar: 0x0631), is: .tafkhim)
        // فِرۡقٖ, either way
        let firq = Site(surah: 26, ayah: 63, word: "\u{0641}\u{0650}\u{0631}\u{06E1}\u{0642}\u{0656}", scalar: 0x0631)
        let found = try await rules(at: firq)
        XCTAssertFalse(found.contains(.tafkhim), "\(firq.reference): found \(found.map(\.rawValue))")
    }

    /// A raa with a tanween fath at the end of an ayah keeps its fatha at the stop (the tanween turns
    /// into the 'iwad alif), so it is heavy whatever comes before it. The stopped-raa rule, which
    /// weighs the letter BEFORE the raa, is for a raa stopped on a sukoon. 131 ayah ends were painted
    /// light until 2026-10-27, 117 of them after a madd yaa.
    func testAyahFinalRaaWithTanweenFathIsHeavy() async throws {
        // سَعِيرًا, after a madd yaa
        try await assertRule(Site(surah: 33, ayah: 64, word: "\u{0633}\u{064E}\u{0639}\u{0650}\u{064A}\u{0631}\u{064B}\u{0627}", scalar: 0x0631), is: .tafkhim)
        // ذِكۡرٗا, saakin after a kasra
        try await assertRule(Site(surah: 18, ayah: 70, word: "\u{0630}\u{0650}\u{0643}\u{06E1}\u{0631}\u{0657}\u{0627}", scalar: 0x0631), is: .tafkhim)
        // مُنتَصِرًا, after a kasra
        try await assertRule(Site(surah: 18, ayah: 43, word: "\u{0645}\u{064F}\u{0646}\u{062A}\u{064E}\u{0635}\u{0650}\u{0631}\u{064B}\u{0627}", scalar: 0x0631), is: .tafkhim)
        // قَدِيرٞ, a dammatan stopped on a sukoon after a madd yaa, stays light
        let qadeer = Site(surah: 2, ayah: 20, word: "\u{0642}\u{064E}\u{062F}\u{0650}\u{064A}\u{0631}\u{065E}", scalar: 0x0631)
        let found = try await rules(at: qadeer)
        XCTAssertFalse(found.contains(.tafkhim), "\(qadeer.reference): found \(found.map(\.rawValue))")
    }

    /// A raa stopped on a sukoon after a saakin letter takes the vowel before that letter, and a waw
    /// there can be a consonant with a fatha: وَٱلۡوَتۡرِ (89:3) is heavy. It was read as a madd waw, which
    /// asks for a damma, and painted light until 2026-10-27 (the one disagreement of a whole-Quran raa
    /// sweep against an independent classifier, 12,402 raas).
    func testAyahFinalRaaAfterAVowelledWawIsHeavy() async throws {
        // وَٱلۡوَتۡرِ
        try await assertRule(Site(surah: 89, ayah: 3, word: "\u{0648}\u{064E}\u{0671}\u{0644}\u{06E1}\u{0648}\u{064E}\u{062A}\u{06E1}\u{0631}\u{0650}", scalar: 0x0631), is: .tafkhim)
    }

    /// Iqlab colours the small meem that marks it, above (ۢ U+06E2) or below (ۭ U+06ED), and the letter
    /// carrying it keeps its own rule (Abu, 2026-10-27: "it was just supposed to be bottom and top meem").
    /// Where KFGQPC HAFS draws the meem inside a bigger glyph, the paint covers that glyph, since a glyph
    /// takes one colour: the kasra and meem of قِۭ, or the whole letter of طُۢ and رِۭ (`tinyMeemPaintRanges`).
    func testIqlabPaintsTheSmallMeemsGlyph() async throws {
        guard Settings.quranArabicFontName(selectedFontName: Settings.shared.fontArabic, qiraah: nil,
                                           style: Settings.shared.arabicScriptStyle) == Settings.hafsUthmaniFontName else {
            throw XCTSkip("the glyph split is KFGQPC HAFS's; this simulator reads another face")
        }
        func check(_ surah: Int, _ ayah: Int, _ word: String, letter: UInt32, occurrence: Int = 0,
                   mark: UInt32, letterRule: TajweedLegendCategory?, line: UInt = #line) async throws {
            try await assertRule(Site(surah: surah, ayah: ayah, word: word, scalar: mark), is: .iqlaab, line: line)
            let carrier = Site(surah: surah, ayah: ayah, word: word, scalar: letter, occurrence: occurrence)
            let found = try await rules(at: carrier, line: line)
            XCTAssertEqual(found, letterRule.map { [$0] } ?? [], "\(carrier.reference): the letter has \(found.map(\.rawValue))", line: line)
        }
        // The meem is a glyph of its own: the meem alone.
        // مِنۢ: a bare noon, the meem above
        try await check(2, 27, "\u{0645}\u{0650}\u{0646}\u{06E2}", letter: 0x0646, mark: 0x06E2, letterRule: nil)
        // بَصِيرُۢ: a heavy raa, the meem above
        try await check(2, 96, "\u{0628}\u{064E}\u{0635}\u{0650}\u{064A}\u{0631}\u{064F}\u{06E2}", letter: 0x0631, mark: 0x06E2, letterRule: .tafkhim)
        // أَلِيمُۢ: a meem with no shadda, the meem above
        try await check(2, 10, "\u{0623}\u{064E}\u{0644}\u{0650}\u{064A}\u{0645}\u{064F}\u{06E2}", letter: 0x0645, mark: 0x06E2, letterRule: nil)

        // The kasra and the meem below are one glyph: both, and the isti'la letter keeps its weight.
        let shiqaq = "\u{0634}\u{0650}\u{0642}\u{064E}\u{0627}\u{0642}\u{0650}\u{06ED}"
        try await check(2, 176, shiqaq, letter: 0x0642, occurrence: 1, mark: 0x06ED, letterRule: .tafkhim)
        try await assertRule(Site(surah: 2, ayah: 176, word: shiqaq, scalar: 0x0650, occurrence: 1), is: .iqlaab)

        // The meem is baked into the letter's own glyph: only the whole letter can show it.
        // مُحِيطُۢ, the meem above
        try await check(2, 19, "\u{0645}\u{064F}\u{062D}\u{0650}\u{064A}\u{0637}\u{064F}\u{06E2}", letter: 0x0637, mark: 0x06E2, letterRule: .iqlaab)
        // كَافِرِۭ, the meem below
        try await check(2, 41, "\u{0643}\u{064E}\u{0627}\u{0641}\u{0650}\u{0631}\u{0650}\u{06ED}", letter: 0x0631, mark: 0x06ED, letterRule: .iqlaab)
    }

    /// J6: the plural waw before hamzatul-wasl is dropped, its silent alif notwithstanding.
    func testPluralWawBeforeHamzatWaslIsDropped() async throws {
        // وَعَمِلُواْ ٱلصَّٰلِحَٰتِ: the second waw of the word
        try await assertRule(Site(surah: 2, ayah: 25, word: "\u{0648}\u{064E}\u{0639}\u{064E}\u{0645}\u{0650}\u{0644}\u{064F}\u{0648}\u{0627}\u{0652}", scalar: 0x0648, occurrence: 1), is: .droppedLetter)
    }

    /// J7: a dagger alif before an ayah's last letter is an Ending Madd, like a written alif.
    func testDaggerAlifAtTheStopIsEndingMadd() async throws {
        // ٱلرَّحۡمَٰنُ
        try await assertRule(Site(surah: 55, ayah: 1, word: "\u{0671}\u{0644}\u{0631}\u{0651}\u{064E}\u{062D}\u{06E1}\u{0645}\u{064E}\u{0670}\u{0646}\u{064F}", scalar: 0x0670), is: .maddSukoon)
    }

    /// J10: two rules painted in another rule's color keep their own names in the word card. The
    /// noon of مَن يَقُولُ merges WITH ghunnah (drawn grey, as it is not heard), and the meem of
    /// هُم بِمُؤۡمِنِينَ is hidden before baa (drawn in iqlab's color). Both colors are unchanged.
    func testBorrowedColorsKeepTheirRuleNames() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        guard TajweedLegendCategory.allCases.allSatisfy(Settings.shared.isTajweedCategoryVisible) else {
            throw XCTSkip("a tajweed category is hidden in this simulator's settings")
        }
        let ayah = try XCTUnwrap(data.ayah(surah: 2, ayah: 8))
        let raw = ayah.rawArabicText(surahId: 2, qiraahOverride: "") as NSString
        func rule(on phrase: String, letterAt offset: Int) throws -> TajweedWordRule {
            let found = raw.range(of: phrase, options: .literal)
            let start = try XCTUnwrap(found.location == NSNotFound ? nil : found.location, "\(phrase) not in \(raw)")
            let letter = NSRange(location: start + offset, length: 1)
            let rules = TajweedStore.shared.wordRules(surah: 2, ayah: 8, text: raw as String, wordRange: letter)
            XCTAssertEqual(rules.count, 1, "\(phrase): \(rules.map(\.id))")
            return try XCTUnwrap(rules.first)
        }
        // مَن (before يَقُولُ): the noon
        let noon = try rule(on: "\u{0645}\u{064E}\u{0646}", letterAt: 2)
        XCTAssertEqual(noon.category, .idghamBilaGhunnah)
        XCTAssertEqual(noon.alias, .idghamWithGhunnah)
        XCTAssertEqual(noon.englishTitle, TajweedLegendCategory.idghamGhunnah.englishTitle)
        // هُم (before بِمُؤۡمِنِينَ): the meem
        let meem = try rule(on: "\u{0647}\u{064F}\u{0645}", letterAt: 2)
        XCTAssertEqual(meem.category, .iqlaab)
        XCTAssertEqual(meem.alias, .ikhfaaShafawi)
        XCTAssertEqual(meem.transliteration, "Ikhfaa Shafawi")
    }

    /// J11: three small misses.
    func testSmallMisses() async throws {
        // بَلَٰٓؤٞاْ مُّبِينٌ: the tanween merges past its silent alif
        let tanween = Site(surah: 44, ayah: 33, word: "\u{0628}\u{064E}\u{0644}\u{064E}\u{0670}\u{0653}\u{0624}\u{065E}\u{0627}\u{0652}", scalar: 0x065E)
        let merged = try await rules(at: tanween)
        XCTAssertFalse(merged.isEmpty, "\(tanween.reference): the tanween is unpainted")
        // يَلۡهَثۚ ذَّٰلِكَ: the merged ث, a stop sign riding it
        try await assertRule(Site(surah: 7, ayah: 176, word: "\u{064A}\u{064E}\u{0644}\u{06E1}\u{0647}\u{064E}\u{062B}\u{06DA}", scalar: 0x062B), is: .droppedLetter)
        // عِظَامَهُۥ: the silah at the ayah's end is not read at the stop
        let silah = Site(surah: 75, ayah: 3, word: "\u{0639}\u{0650}\u{0638}\u{064E}\u{0627}\u{0645}\u{064E}\u{0647}\u{064F}\u{06E5}", scalar: 0x06E5)
        let atStop = try await rules(at: silah)
        XCTAssertEqual(atStop, [], "\(silah.reference): found \(atStop.map(\.rawValue))")
    }

    // MARK: - The 2026-10-12 audit fixes (cross-check against cpfair/quran-tajweed)

    /// A tanween on a noon or meem WITH shadda is a noon sound of its own: the letter keeps its
    /// ghunnah and the tanween mark takes its ikhfa or idgham into the next word (24 sites). An izhar
    /// tanween paints nothing of its own, so the whole cluster stays ghunnah.
    func testShaddaTanweenKeepsItsOwnRule() async throws {
        // مُّسَمّٗى فَٱكۡتُبُوهُ: the open fathatan hides before ف; the مّ under it is ghunnah
        let musamman = "\u{0645}\u{0651}\u{064F}\u{0633}\u{064E}\u{0645}\u{0651}\u{0657}\u{0649}"
        try await assertRule(Site(surah: 2, ayah: 282, word: musamman, scalar: 0x0657), is: .ikhfaaLight)
        try await assertRule(Site(surah: 2, ayah: 282, word: musamman, scalar: 0x0645, occurrence: 1), is: .generalGhunnah)
        // صُمّٞ وَبُكۡمٞ: the open dammatan merges into the waw (drawn silent), the waw takes the ghunnah
        try await assertRule(Site(surah: 6, ayah: 39, word: "\u{0635}\u{064F}\u{0645}\u{0651}\u{065E}", scalar: 0x065E), is: .idghamBilaGhunnah)
        try await assertRule(Site(surah: 6, ayah: 39, word: "\u{0648}\u{064E}\u{0628}\u{064F}\u{0643}\u{06E1}\u{0645}\u{065E}", scalar: 0x0648), is: .generalGhunnah)
        // بِغَمّٖ لِّكَيۡلَا: the open kasratan merges into the laam without ghunnah
        try await assertRule(Site(surah: 3, ayah: 153, word: "\u{0628}\u{0650}\u{063A}\u{064E}\u{0645}\u{0651}\u{0656}", scalar: 0x0656), is: .idghamBilaGhunnah)
        // مُّسَمًّى عِندَهُ: izhar before ع, so the tanween stays inside the ghunnah
        try await assertRule(Site(surah: 6, ayah: 2, word: "\u{0645}\u{0651}\u{064F}\u{0633}\u{064E}\u{0645}\u{0651}\u{064B}\u{0649}", scalar: 0x064B), is: .generalGhunnah)
        // صُمُّۢ بُكۡمٌ: iqlab written as a small meem on the shadda'd letter; the mark is iqlab, the letter ghunnah
        try await assertRule(Site(surah: 2, ayah: 18, word: "\u{0635}\u{064F}\u{0645}\u{0651}\u{064F}\u{06E2}", scalar: 0x06E2), is: .iqlaab)
        try await assertRule(Site(surah: 2, ayah: 18, word: "\u{0635}\u{064F}\u{0645}\u{0651}\u{064F}\u{06E2}", scalar: 0x0645), is: .generalGhunnah)
    }

    /// The ۞ ornament before an ayah's first letter is not that letter: a hamzat wasl after it opens
    /// the ayah and is pronounced, and the laam of ٱللَّهُ opening 24:35 is heavy as at 2:255.
    func testHizbMarkDoesNotSilenceTheOpeningWasl() async throws {
        let allah = "\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{064F}"
        let wasl = try await rules(at: Site(surah: 24, ayah: 35, word: allah, scalar: 0x0671))
        XCTAssertEqual(wasl, [], "24:35: the opening wasl is painted \(wasl.map(\.rawValue))")
        try await assertRule(Site(surah: 24, ayah: 35, word: allah, scalar: 0x0644, occurrence: 1), is: .tafkhim)
        // ۞ ٱحۡشُرُواْ 37:22
        let ihshuru = try await rules(at: Site(surah: 37, ayah: 22, word: "\u{0671}\u{062D}\u{06E1}\u{0634}\u{064F}\u{0631}\u{064F}\u{0648}\u{0627}\u{0652}", scalar: 0x0671))
        XCTAssertEqual(ihshuru, [], "37:22: the opening wasl is painted \(ihshuru.map(\.rawValue))")
    }

    /// A ص under the small high seen is read as seen, a light letter; the ص of ٱلۡمُصَيۡطِرُونَ (52:37)
    /// and بِمُصَيۡطِرٍ (88:22) is read as itself and stays heavy.
    func testSmallHighSeenReadsAsSeen() async throws {
        let yabsutu = try await rules(at: Site(surah: 2, ayah: 245, word: "\u{0648}\u{064E}\u{064A}\u{064E}\u{0628}\u{06E1}\u{0635}\u{06DC}\u{064F}\u{0637}\u{064F}", scalar: 0x0635))
        XCTAssertEqual(yabsutu, [], "2:245: found \(yabsutu.map(\.rawValue))")
        let bastatan = try await rules(at: Site(surah: 7, ayah: 69, word: "\u{0628}\u{064E}\u{0635}\u{06DC}\u{06E1}\u{0637}\u{064E}\u{0629}\u{0657}\u{06D6}", scalar: 0x0635))
        XCTAssertEqual(bastatan, [], "7:69: found \(bastatan.map(\.rawValue))")
        try await assertRule(Site(surah: 52, ayah: 37, word: "\u{0671}\u{0644}\u{06E1}\u{0645}\u{064F}\u{0635}\u{06DC}\u{064E}\u{064A}\u{06E1}\u{0637}\u{0650}", scalar: 0x0635), is: .tafkhim)
        try await assertRule(Site(surah: 88, ayah: 22, word: "\u{0628}\u{0650}\u{0645}\u{064F}\u{0635}\u{064E}\u{064A}\u{06E1}\u{0637}\u{0650}\u{0631}\u{064D}", scalar: 0x0635), is: .tafkhim)
    }

    /// J10: silent letters are "Written but Not Pronounced", not a joining hamzah: the plural alif
    /// of ٱذۡكُرُواْ and the silent waw of ٱلصَّلَوٰةَ. The wasl itself keeps its own name.
    func testSilentLettersAreNamedDropped() async throws {
        let udhkuru = "\u{0671}\u{0630}\u{06E1}\u{0643}\u{064F}\u{0631}\u{064F}\u{0648}\u{0627}\u{0652}"
        try await assertRule(Site(surah: 2, ayah: 47, word: udhkuru, scalar: 0x0627), is: .droppedLetter)
        try await assertRule(Site(surah: 2, ayah: 47, word: udhkuru, scalar: 0x0671), is: .hamzatWaslSilent)
        try await assertRule(Site(surah: 2, ayah: 3, word: "\u{0671}\u{0644}\u{0635}\u{0651}\u{064E}\u{0644}\u{064E}\u{0648}\u{0670}\u{0629}\u{064E}", scalar: 0x0648), is: .droppedLetter)
    }

    /// The small waw before an ayah's last letter is the madd letter of the stop: ٱلۡغَاوُۥنَ and
    /// يَسۡتَوُۥنَ end on an Ending Madd, not the two-count Tiny Madd.
    func testSmallWawAtTheStopIsEndingMadd() async throws {
        try await assertRule(Site(surah: 26, ayah: 94, word: "\u{0648}\u{064E}\u{0671}\u{0644}\u{06E1}\u{063A}\u{064E}\u{0627}\u{0648}\u{064F}\u{06E5}\u{0646}\u{064E}", scalar: 0x06E5), is: .maddSukoon)
        try await assertRule(Site(surah: 32, ayah: 18, word: "\u{064A}\u{064E}\u{0633}\u{06E1}\u{062A}\u{064E}\u{0648}\u{064F}\u{06E5}\u{0646}\u{064E}", scalar: 0x06E5), is: .maddSukoon)
    }

    /// The word card's rules on a cold ayah come straight off the paint, not off a cache read-back
    /// (2:122 lost its opening dagger alif once in 6,236 on 2026-10-12), and with Hide Dots on.
    func testWordRulesOnAColdAyah() async throws {
        let yabani = "\u{064A}\u{064E}\u{0670}\u{0628}\u{064E}\u{0646}\u{0650}\u{064A}\u{0653}"
        try await assertRule(Site(surah: 2, ayah: 122, word: yabani, scalar: 0x0670), is: .maddNaturalMiniature)
        let settings = Settings.shared
        let hadDots = settings.removeArabicDots
        settings.removeArabicDots = true
        defer { settings.removeArabicDots = hadDots }
        try await assertRule(Site(surah: 2, ayah: 47, word: yabani, scalar: 0x0670), is: .maddNaturalMiniature)
    }

    // MARK: - The laam of the name of Allah (heavy / light)

    /// The laam of ٱللَّه is heavy after a fatha or a damma. The letter asserted is the SECOND laam,
    /// the pronounced one carrying the shadda, so the scalar is U+0644 occurrence 1.
    func testLaamOfAllahIsHeavyAfterFathaOrDamma() async throws {
        // خَتَمَ ٱللَّهُ - after the fatha of خَتَمَ
        try await assertRule(Site(surah: 2, ayah: 7, word: "\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{064F}", scalar: 0x0644, occurrence: 1), is: .tafkhim)
        // قُلۡ هُوَ ٱللَّهُ أَحَدٌ - after the fatha of هُوَ
        try await assertRule(Site(surah: 112, ayah: 1, word: "\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{064F}", scalar: 0x0644, occurrence: 1), is: .tafkhim)
        // وَمَا ٱللَّهُ - the fatha of وَمَا sits before a SILENT alif, which the scan walks past
        try await assertRule(Site(surah: 2, ayah: 74, word: "\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{064F}", scalar: 0x0644, occurrence: 1), is: .tafkhim)
    }

    /// ... and light after a kasra. This is the whole point of the rule: the same four letters,
    /// painted differently by the sound BEFORE them.
    func testLaamOfAllahIsLightAfterKasra() async throws {
        // بِسۡمِ ٱللَّهِ - after the kasra of بِسۡمِ
        let basmala = Site(surah: 1, ayah: 1, word: "\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{0650}", scalar: 0x0644, occurrence: 1)
        let onBasmala = try await rules(at: basmala)
        XCTAssertFalse(onBasmala.contains(.tafkhim), "1:1: the laam after a kasra must not be heavy")
        // فِي ٱللَّهِ - the kasra sits before a silent ya
        let afterFi = Site(surah: 2, ayah: 139, word: "\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{0650}", scalar: 0x0644, occurrence: 1)
        let onAfterFi = try await rules(at: afterFi)
        XCTAssertFalse(onAfterFi.contains(.tafkhim), "2:139: the laam after a kasra must not be heavy")
    }

    /// The alif-less spelling لِلَّه / وَلِلَّه is the name too - 500+ sites. Its first laam carries the
    /// preposition's own kasra, so a predicate demanding a BARE first laam drops every one of them.
    func testAlifLessSpellingIsStillTheName() async throws {
        // وَلِلَّهِ - the laam is light, the kasra of لِ governs it
        let walillaahi = Site(surah: 5, ayah: 18, word: "\u{0648}\u{064E}\u{0644}\u{0650}\u{0644}\u{0651}\u{064E}\u{0647}\u{0650}", scalar: 0x0644, occurrence: 1)
        let found = try await rules(at: walillaahi)
        XCTAssertFalse(found.contains(.tafkhim), "5:18: لِ's kasra makes it light")
    }

    /// The two look-alikes whose letters also run ل + ل + ه but which are NOT the name: the heavy
    /// laam must not touch them. The same pair the red Highlight Allah guards against.
    func testTheLookAlikesAreNotTheName() async throws {
        // ٱللَّهۡوِ (62:11, the amusement)
        let amusement = Site(surah: 62, ayah: 11, word: "\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{06E1}\u{0648}\u{0650}", scalar: 0x0644, occurrence: 1)
        let onAmusement = try await rules(at: amusement)
        XCTAssertFalse(onAmusement.contains(.tafkhim), "62:11: ٱللَّهۡوِ is not the name")
        // ٱللَّهَبِ (77:31, the flame)
        let flame = Site(surah: 77, ayah: 31, word: "\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{064E}\u{0628}\u{0650}", scalar: 0x0644, occurrence: 1)
        let onFlame = try await rules(at: flame)
        XCTAssertFalse(onFlame.contains(.tafkhim), "77:31: ٱللَّهَبِ is not the name")
    }

    /// When the name OPENS the ayah there is no preceding sound to read. Begun there, the hamzat
    /// wasl takes a fatha, so the laam is heavy: 31 sites, 2:255 among them.
    func testAyahInitialNameIsHeavy() async throws {
        // ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ (Ayat al-Kursi)
        try await assertRule(Site(surah: 2, ayah: 255, word: "\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{064F}", scalar: 0x0644, occurrence: 1), is: .tafkhim)
        // ٱللَّهُ يَسۡتَهۡزِئُ بِهِمۡ
        try await assertRule(Site(surah: 2, ayah: 15, word: "\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{064F}", scalar: 0x0644, occurrence: 1), is: .tafkhim)
    }

    /// The vocative ٱللَّهُمَّ IS the name, and keeps the rule (heavy, after the damma of its own heh is
    /// irrelevant - the governing sound precedes the laam).
    func testAllahummaIsStillTheName() async throws {
        // 3:26 قُلِ ٱللَّهُمَّ - after the kasra of قُلِ, so LIGHT
        let allahumma = Site(surah: 3, ayah: 26, word: "\u{0671}\u{0644}\u{0644}\u{0651}\u{064E}\u{0647}\u{064F}\u{0645}\u{0651}\u{064E}", scalar: 0x0644, occurrence: 1)
        let found = try await rules(at: allahumma)
        XCTAssertFalse(found.contains(.tafkhim), "3:26: قُلِ's kasra makes it light")
    }

    /// The small high yeh of إِبۡرَٰهِـۧمَ (U+06E7, 38 places) sits in the waqf band but is part of a
    /// letter, not a stop sign. Until 2026-10-14 the paint skipped it, so its Tiny Madd colored only
    /// the tatweel under it and the yeh itself stayed in the text color. Reads the DRAWN color, since
    /// `ruleCategories` resolves the ops and never saw the skip.
    func testSmallHighYehIsPaintedLikeItsTatweel() async throws {
        XCTAssertFalse(TajweedRules.shouldSkipWaqfColoring(UnicodeScalar(0x06E7)!))
        for stop in TajweedRules.stopSignScalars {
            XCTAssertTrue(TajweedRules.shouldSkipWaqfColoring(UnicodeScalar(stop)!), String(format: "U+%04X is painted", stop))
        }
        let data = QuranData.shared
        await data.waitUntilLoaded()
        guard TajweedLegendCategory.allCases.allSatisfy(Settings.shared.isTajweedCategoryVisible) else {
            throw XCTSkip("a tajweed category is hidden in this simulator's settings")
        }
        let ayah = try XCTUnwrap(data.ayah(surah: 2, ayah: 124), "no ayah 2:124")
        let raw = ayah.rawArabicText(surahId: 2, qiraahOverride: "")
        let units = Array(raw.utf16)
        let yeh = try XCTUnwrap(units.firstIndex(of: 0x06E7), "2:124: no small high yeh")
        XCTAssertEqual(units[yeh - 1], 0x0640, "2:124: the small high yeh rides a tatweel")
        let styled = try XCTUnwrap(TajweedStore.shared.attributedText(surah: 2, ayah: 124, text: raw, removeArabicDots: false))
        let painted = NSAttributedString(styled)
        let traits = UITraitCollection(userInterfaceStyle: .light)
        func rgba(_ color: UIColor?) -> [CGFloat] {
            var r: CGFloat = -1, g: CGFloat = -1, b: CGFloat = -1, a: CGFloat = -1
            color?.resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
            return [r, g, b, a].map { ($0 * 255).rounded() }
        }
        func drawn(_ i: Int) -> [CGFloat] { rgba(painted.attribute(.foregroundColor, at: i, effectiveRange: nil) as? UIColor) }
        let tiny = rgba(UIColor(TajweedLegendCategory.maddNaturalMiniature.color))
        XCTAssertEqual(drawn(yeh - 1), tiny, "2:124: the tatweel is not Tiny Madd")
        XCTAssertEqual(drawn(yeh), tiny, "2:124: the small high yeh is not Tiny Madd")
    }

    /// A glyph shows only its first character's colour, so a rule painted on a later character of a
    /// ligature never showed (the madd inside the lam-alif of ٱلۡأٓخِرَةِ, the alif of بِـَٔا). Where the
    /// glyph's first character is plain, the whole glyph now takes that rule's colour; where it has a rule
    /// of its own (the heavy raa of رَٰءۡ 2:72), it keeps it (`paintWholeGlyphs`, 2026-10-27).
    func testARuleInsideALigatureColoursTheGlyph() async throws {
        guard Settings.quranArabicFontName(selectedFontName: Settings.shared.fontArabic, qiraah: nil,
                                           style: Settings.shared.arabicScriptStyle) == Settings.hafsUthmaniFontName else {
            throw XCTSkip("the ligatures are KFGQPC HAFS's; this simulator reads another face")
        }
        let data = QuranData.shared
        await data.waitUntilLoaded()
        guard TajweedLegendCategory.allCases.allSatisfy(Settings.shared.isTajweedCategoryVisible) else {
            throw XCTSkip("a tajweed category is hidden in this simulator's settings")
        }
        let traits = UITraitCollection(userInterfaceStyle: .light)
        func rgba(_ color: UIColor?) -> [CGFloat] {
            var r: CGFloat = -1, g: CGFloat = -1, b: CGFloat = -1, a: CGFloat = -1
            color?.resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
            return [r, g, b, a].map { ($0 * 255).rounded() }
        }
        func drawn(_ surah: Int, _ ayah: Int, at sequence: [UInt16], offset: Int) throws -> [CGFloat] {
            let raw = try XCTUnwrap(data.ayah(surah: surah, ayah: ayah)).rawArabicText(surahId: surah, qiraahOverride: "")
            let units = Array(raw.utf16)
            let start = try XCTUnwrap(units.indices.first { units[$0...].starts(with: sequence) }, "\(surah):\(ayah): sequence not found")
            let styled = try XCTUnwrap(TajweedStore.shared.attributedText(surah: surah, ayah: ayah, text: raw, removeArabicDots: false))
            return rgba(NSAttributedString(styled).attribute(.foregroundColor, at: start + offset, effectiveRange: nil) as? UIColor)
        }
        let madd = rgba(UIColor(TajweedLegendCategory.maddNatural.color))
        // ٱلۡأٓخِرَةِ: the laam of the lam-alif glyph carries the madd of its alif
        XCTAssertEqual(try drawn(2, 4, at: [0x0644, 0x06E1, 0x0623, 0x0653], offset: 0), madd, "2:4: the lam-alif does not show its madd")
        // بِـَٔايَٰتِنَآ: no longer one glyph (the bake left the face 2026-10-31), so the alif shows its madd
        // and the baa stays plain instead of turning gold with it
        let biHamzaAlif: [UInt16] = [0x0628, 0x0650, 0x0640, 0x0654, 0x064E, 0x0627]
        XCTAssertEqual(try drawn(2, 39, at: biHamzaAlif, offset: 5), madd, "2:39: بِـَٔا does not show its madd")
        XCTAssertEqual(try drawn(2, 39, at: biHamzaAlif, offset: 0), rgba(UIColor.label), "2:39: the baa of بِـَٔا took the madd")
        // رَٰءۡ: the glyph's raa is heavy and stays heavy
        XCTAssertEqual(try drawn(2, 72, at: [0x0631, 0x064E, 0x0670, 0x0621, 0x06E1], offset: 0),
                       rgba(UIColor(TajweedLegendCategory.tafkhim.color)), "2:72: the heavy raa lost its colour")
        // The sajdah words of 19:58 are each one glyph, overline included, and the line is never coloured
        // (Abu, 2026-10-28): خَرُّواْۤ drew heavy blue end to end, سُجَّدٗاۤ grey ("not pronounced")
        let plain = rgba(UIColor.label)
        XCTAssertEqual(try drawn(19, 58, at: [0x062E, 0x064E, 0x0631, 0x0651, 0x064F, 0x0648, 0x0627, 0x0652, 0x06E4], offset: 0),
                       plain, "19:58: خَرُّواْۤ draws its sajdah line in a colour")
        XCTAssertEqual(try drawn(19, 58, at: [0x0633, 0x064F, 0x062C, 0x0651, 0x064E, 0x062F, 0x0657, 0x0627, 0x06E4], offset: 0),
                       plain, "19:58: سُجَّدٗاۤ draws its sajdah line in a colour")
    }

    /// Not a rule check: writes the whole Quran's painted rules, one JSON line per ayah
    /// (`{"s","a","t","c":[[cluster, [rule ids]], ...]}`, one entry per grapheme cluster of the raw
    /// text), to the file named by TAJWEED_DUMP_PATH (TEST_RUNNER_TAJWEED_DUMP_PATH on the xcodebuild
    /// line), for an offline comparison against another annotator: the 2026-10-11 cross-check against
    /// cpfair's quran-tajweed ran on it. Skipped unless that variable is set.
    func testDumpWholeQuranPaintWhenAsked() async throws {
        guard let path = ProcessInfo.processInfo.environment["TAJWEED_DUMP_PATH"], !path.isEmpty else {
            throw XCTSkip("set TEST_RUNNER_TAJWEED_DUMP_PATH to write the dump")
        }
        let data = QuranData.shared
        await data.waitUntilLoaded()
        guard TajweedLegendCategory.allCases.allSatisfy(Settings.shared.isTajweedCategoryVisible) else {
            throw XCTSkip("a tajweed category is hidden in this simulator's settings")
        }
        var lines: [String] = []
        for surah in data.quran {
            for ayah in surah.ayahs {
                let raw = ayah.rawArabicText(surahId: surah.id, qiraahOverride: "")
                var clusters: [[Any]] = []
                var location = 0
                for character in raw {
                    let range = NSRange(location: location, length: character.utf16.count)
                    location += character.utf16.count
                    let rules = TajweedStore.shared.wordRules(surah: surah.id, ayah: ayah.id, text: raw, wordRange: range)
                    clusters.append([String(character), rules.map(\.id)])
                }
                let object: [String: Any] = ["s": surah.id, "a": ayah.id, "t": raw, "c": clusters]
                let json = try JSONSerialization.data(withJSONObject: object)
                lines.append(String(decoding: json, as: UTF8.self))
            }
        }
        try lines.joined(separator: "\n").write(toFile: path, atomically: true, encoding: .utf8)
    }

    /// Every ayah's DRAWN colours for the glyph audit (2026-10-27): a glyph takes the colour of its first
    /// character, so a colour on any later character of a ligature never shows. Writes one JSON line per
    /// ayah, the painted text and its foreground runs as [start, length, "RRGGBB"] in UTF-16, for a
    /// CoreText script to shape against the font. Opt in with TEST_RUNNER_TAJWEED_COLOR_DUMP_PATH.
    func testDumpWholeQuranColorsWhenAsked() async throws {
        guard let path = ProcessInfo.processInfo.environment["TAJWEED_COLOR_DUMP_PATH"], !path.isEmpty else {
            throw XCTSkip("set TEST_RUNNER_TAJWEED_COLOR_DUMP_PATH to write the dump")
        }
        let data = QuranData.shared
        await data.waitUntilLoaded()
        guard TajweedLegendCategory.allCases.allSatisfy(Settings.shared.isTajweedCategoryVisible) else {
            throw XCTSkip("a tajweed category is hidden in this simulator's settings")
        }
        func hex(_ color: UIColor) -> String {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).getRed(&r, green: &g, blue: &b, alpha: &a)
            return String(format: "%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
        }
        var lines: [String] = []
        for surah in data.quran {
            for ayah in surah.ayahs {
                let raw = ayah.rawArabicText(surahId: surah.id, qiraahOverride: "")
                guard let painted = TajweedStore.shared.attributedText(surah: surah.id, ayah: ayah.id, text: raw) else { continue }
                let ns = NSAttributedString(painted)
                var runs: [[Any]] = []
                ns.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: ns.length)) { value, range, _ in
                    guard let color = value as? UIColor else { return }
                    runs.append([range.location, range.length, hex(color)])
                }
                let object: [String: Any] = ["s": surah.id, "a": ayah.id, "t": ns.string, "r": runs]
                lines.append(String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self))
            }
        }
        try lines.joined(separator: "\n").write(toFile: path, atomically: true, encoding: .utf8)
    }
}

// MARK: - Legend examples

/// Every Hafs rule's example ayah (`TajweedLegendCategory.exampleAyah`) must carry the rule where the
/// engine colors it, or the legend would show an example with nothing colored (2026-11-01).
@MainActor
final class TajweedLegendExampleTests: XCTestCase {
    func testEveryRuleExamplePaintsItsRule() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        for item in TajweedLegendCategory.allCases {
            let place = item.exampleAyah
            let ayah = try XCTUnwrap(data.ayah(surah: place.surah, ayah: place.ayah), "\(item.rawValue): no ayah \(place.surah):\(place.ayah)")
            let text = ayah.rawArabicText(surahId: place.surah, qiraahOverride: "")
            let styled = TajweedStore.legendExamples.exampleText(surah: place.surah, ayah: place.ayah, text: text, category: item)
            XCTAssertNotNil(styled, "\(item.rawValue): \(place.surah):\(place.ayah) paints nothing of the rule")
        }
    }

    /// The shared painter never answers (its snapshot is the reader's), so a row can never mistake it.
    func testSharedPainterGivesNoExamples() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let ayah = try XCTUnwrap(data.ayah(surah: 1, ayah: 1))
        let text = ayah.rawArabicText(surahId: 1, qiraahOverride: "")
        XCTAssertNil(TajweedStore.shared.exampleText(surah: 1, ayah: 1, text: text, category: .tafkhim))
    }
}

/// The one order of the riwayah rules (`QiraahTajweedStore.ruleOrder`, 2026-11-01): every print's legend
/// and the Legend's By Rule index follow it, and the riwayat page explains the rules in it.
final class QiraahRuleOrderTests: XCTestCase {
    private var packTags: [String] {
        Settings.Riwayah.allOptions.map(\.tag).filter { QiraahTajweedStore.fileName(for: $0) != nil }
    }

    /// Abu, 2026-11-01: "in tajweed legend taqlil should come after imaalah" (its mixed form between them),
    /// then "fix them to be best order that makes sense": the khilaf wash first, the groups in the order
    /// the store's comment gives, each rule once.
    func testTaqlilFollowsImalah() throws {
        let order = QiraahTajweedStore.ruleOrder
        let imalah = try XCTUnwrap(order.firstIndex(of: "imalah"))
        XCTAssertEqual(order.firstIndex(of: "imalah_taqlil"), imalah + 1)
        XCTAssertEqual(order.firstIndex(of: "taqlil"), imalah + 2)
        XCTAssertEqual(Set(order).count, order.count)
        XCTAssertEqual(order.prefix(2), ["khilaf_word", "khilaf_harf"])
        let rank = QiraahTajweedStore.ruleRank
        // The groups: differs from Hafs, tilts, lengthenings, joins, letters, thin and thick, pauses.
        XCTAssertLessThan(rank("taqlil"), rank("madd_badal"))
        XCTAssertLessThan(rank("madd_leen"), rank("silah_meem"))
        XCTAssertLessThan(rank("ha_dhamir"), rank("idgham"))
        XCTAssertLessThan(rank("ishmam_sad"), rank("raa_muraqqaqah"))
        XCTAssertLessThan(rank("lam_mughallazah"), rank("sakt"))
        XCTAssertEqual(order.last, "ibtida_wasl")
    }

    /// A rule the app can describe has a place in the order; an unknown key sorts last, in its own order.
    func testEveryDescribedRuleHasAPlace() {
        for key in QiraahTajweedStore.shortDescriptions.keys {
            XCTAssertLessThan(QiraahTajweedStore.ruleRank(key), QiraahTajweedStore.ruleOrder.count, key)
        }
        XCTAssertEqual(QiraahTajweedStore.ruleRank("made_up"), QiraahTajweedStore.ruleOrder.count)
        XCTAssertEqual(QiraahTajweedStore.sortedByRule(["taqlil", "zzz", "idgham", "aaa", "imalah"]) { $0 },
                       ["imalah", "taqlil", "idgham", "zzz", "aaa"])
    }

    /// Every shipped pack's legend comes out sorted, whatever order its print's box used.
    func testEveryPackLegendIsInTheOrder() {
        let tags = packTags
        XCTAssertEqual(tags.count, 19)
        for tag in tags {
            let keys = QiraahTajweedStore.shared.legend(for: tag).map(\.key)
            XCTAssertFalse(keys.isEmpty, tag)
            XCTAssertEqual(keys, QiraahTajweedStore.sortedByRule(keys) { $0 }, tag)
            XCTAssertEqual(keys.first.map { QiraahTajweedStore.ruleAliases[$0] ?? $0 }, "khilaf_harf", "\(tag) leads with the khilaf wash")
        }
    }

    /// The cross-riwayah index folds the two khilaf captions, keeps the order, and counts every print.
    func testRulesAcrossRiwayatFoldTheKhilafCaptions() throws {
        let rules = QiraahTajweedStore.shared.rulesAcrossRiwayat(tags: packTags)
        XCTAssertEqual(rules.first?.key, "khilaf_harf")
        XCTAssertEqual(rules.first?.english, "Differing from Ḥafṣ")
        XCTAssertEqual(rules.first?.uses.count, 19)
        XCTAssertNil(rules.first { $0.key == "khilaf_word" })
        XCTAssertEqual(rules.map(\.key), QiraahTajweedStore.sortedByRule(rules.map(\.key)) { $0 })
        let taqlil = try XCTUnwrap(rules.first { $0.key == "taqlil" })
        XCTAssertEqual(taqlil.uses.map(\.tag), [Settings.Riwayah.warsh])
        XCTAssertGreaterThan(taqlil.uses[0].count, 1000)
    }
}

/// "Differs from Hafs" one letter at a time (2026-11-01, Warsh first): the print's khilaf letters carried
/// over to their Hafs counterparts, and the word pairing underneath.
@MainActor
final class QiraatLetterDiffTests: XCTestCase {
    private func text(_ word: String, _ range: NSRange) -> String { (word as NSString).substring(with: range) }

    /// Warsh's يُومِنُونَ marks its wāw (cluster 1): the letter it answers to in Hafs is the ؤ.
    func testKhilafLetterLandsOnItsHafsCounterpart() {
        let hafs = "يُؤۡمِنُونَ"
        let ranges = QiraatLetterDiff.projectedRanges(hafsWord: hafs, riwayahWord: "يُومِنُونَ", extents: [(lo: 1, hi: 1)])
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["ؤۡ"])
    }

    /// Warsh's اٰمَنُوا has no hamzah: Hafs's ء has no pair, so it is changed along with the alif it marks.
    func testDroppedHafsLettersAreChanged() {
        let hafs = "ءَامَنُواْ"
        let ranges = QiraatLetterDiff.projectedRanges(hafsWord: hafs, riwayahWord: "اٰمَنُوا", extents: [(lo: 0, hi: 0)])
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["ءَا"])
    }

    /// A whole-word mark (lo -1) covers the whole counterpart, the letter the riwayah drops included.
    func testWholeWordCoversTheWholeCounterpart() {
        let hafs = "وَسَارِعُوٓاْ"
        let ranges = QiraatLetterDiff.projectedRanges(hafsWord: hafs, riwayahWord: "سَارِعُوٓاْ", extents: [(lo: -1, hi: -1)])
        XCTAssertEqual(ranges.map { text(hafs, $0) }, [hafs])
    }

    /// A word the print leaves black tints nothing, however its spelling differs.
    func testUnmarkedWordsStayPlain() {
        XCTAssertEqual(QiraatLetterDiff.projectedRanges(hafsWord: "غَمَٰم", riwayahWord: "غَمَام", extents: []), [])
    }

    /// Two letters marked apart stay two ranges; the letter between them stays plain.
    func testSeparateLettersStaySeparate() {
        let hafs = "يُؤۡتِيَنِ"
        let ranges = QiraatLetterDiff.projectedRanges(hafsWord: hafs, riwayahWord: "يُّوتِيَنِۦ", extents: [(lo: 1, hi: 1), (lo: 4, hi: 4)])
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["ؤۡ", "نِ"])
    }

    /// The folded LCS pairs the words both read alike; a replaced word pairs positionally inside its gap.
    func testWordPairingFillsEqualGaps() {
        let pairing = QiraatLetterDiff.pairWords(hafs: ["قُلۡ", "هُوَ", "ٱللَّهُ", "أَحَدٌ"], riwayah: ["قَالَ", "هُوَ", "اَ۬للَّهُ", "اَحَدٌ"])
        XCTAssertEqual(pairing.pairs, [0: 0, 1: 1, 2: 2, 3: 3])
        XCTAssertTrue(pairing.hafsOnly.isEmpty)
        XCTAssertTrue(pairing.riwayahOnly.isEmpty)
    }

    /// A Hafs word the riwayah has no word for is left over; an uneven gap is not guessed at.
    func testWordPairingLeavesUnevenGaps() {
        let pairing = QiraatLetterDiff.pairWords(hafs: ["وَإِذۡ", "قَالَ", "مُوسَىٰ"], riwayah: ["وَإِذۡ", "مُوسَىٰ"])
        XCTAssertEqual(pairing.pairs, [0: 0, 2: 1])
        XCTAssertEqual(pairing.hafsOnly, [1])
    }

    /// A letter the riwayah adds has no Hafs pair: it lands on the Hafs letter it follows, so the word
    /// still shows where to look. Warsh's إِبۡرَٰهِـيمَ marks its yā; Hafs's small yā rides on the
    /// tatweel before it, and that tatweel is the only tint.
    func testAddedLetterLandsOnTheLetterItFollows() {
        let hafs = "قَالَ"
        let ranges = QiraatLetterDiff.projectedRanges(hafsWord: hafs, riwayahWord: "قَالُوا", extents: [(lo: 3, hi: 3)])
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["لَ"])
        let ibrahim = "إِبۡرَٰهِـۧمَ"
        let ibrahimRanges = QiraatLetterDiff.projectedRanges(hafsWord: ibrahim, riwayahWord: "إِبۡرَٰهِـيمَ", extents: [(lo: 5, hi: 5)])
        XCTAssertEqual(ibrahimRanges.map { text(ibrahim, $0) }, ["ـۧ"])
    }

    /// A swapped letter needs no anchor: Hafs's تَ sits in Qalun's يَ's gap and is marked as unpaired,
    /// so the ع after it stays plain.
    func testSwappedLetterDoesNotSpreadToItsNeighbour() {
        let hafs = "تَعۡمَلُونَ"
        let ranges = QiraatLetterDiff.projectedRanges(hafsWord: hafs, riwayahWord: "يَعۡمَلُونَ", extents: [(lo: 0, hi: 0)])
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["تَ"])
    }

    /// Every letter print is letter-level: Warsh, Qalun, al-Bazzi, Qunbul, as-Susi, Shubah, Hisham, Ibn
    /// Dhakwan, Abu al-Harith, ad-Duri an al-Kisai, Ibn Wardan, Ibn Jammaz, Ruways, Rawh, Ishaq and Idris,
    /// and so are ad-Duri an Abi Amr, Khalaf and Khallad, whose whole-word prints the builder narrows
    /// to the differing letters. A beta print is letter-level only while its text may render: before
    /// the beta consent its text surfaces hand back Hafs, which its extents do not describe.
    func testOnlyListedRiwayatAreLetterLevel() {
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.warsh))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.qaloon))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.buzzi))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.qunbul))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.susi))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.shubah))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.duri))
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.hafsTag))

        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = false
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.hisham))
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.ibnDhakwan))
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.abuHarith))
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.duriKisai))
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.ibnWardan))
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.ibnJammaz))
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.ruways))
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.rawh))
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.ishaq))
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.idris))
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.khalaf))
        XCTAssertFalse(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.khallad))
        Settings.shared.betaQiraatEnabled = true
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.hisham))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.ibnDhakwan))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.abuHarith))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.duriKisai))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.ibnWardan))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.ibnJammaz))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.ruways))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.rawh))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.ishaq))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.idris))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.khalaf))
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: Settings.Riwayah.khallad))
    }

    /// Hafs 2:3 against Warsh: the pack marks only the wāw of يُومِنُونَ, so Hafs's ayah tints only its ؤ.
    /// Warsh counts Madani, where الٓمٓ is not an ayah, so Hafs 2:3 is Warsh's own ayah 2 (the alignment
    /// says which; the sheet asks it the same way).
    func testHafsAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let hafs = try XCTUnwrap(data.ayah(surah: 2, ayah: 3)).rawArabicText(surahId: 2, qiraahOverride: "")
        let own = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: Settings.Riwayah.warsh, quranData: data)?
            .riwayahNumberForHafs[3])
        let warsh = try XCTUnwrap(data.ayah(surah: 2, ayah: own)).rawArabicText(surahId: 2, qiraahOverride: Settings.Riwayah.warsh)
        guard warsh != hafs, warsh.contains("يُومِنُونَ") else {
            throw XCTSkip("Warsh's text is not loaded in this simulator (showOtherQiraatReciters is off)")
        }
        XCTAssertEqual(own, 2)
        let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: Settings.Riwayah.warsh,
                                                                     surah: 2, ownAyah: own, splitSpan: nil))
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["ؤۡ"])
    }

    /// Hafs 1:4 against Qalun: the print marks the mīm and lām of مَلِكِ (no dagger alif), so Hafs's
    /// مَٰلِكِ tints those two letters and nothing else. Qalun counts Madani too: the basmalah is not
    /// ayah 1 of al-Fatihah, so Hafs 1:4 is Qalun's own ayah 3.
    func testQalunAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let hafs = try XCTUnwrap(data.ayah(surah: 1, ayah: 4)).rawArabicText(surahId: 1, qiraahOverride: "")
        let own = try XCTUnwrap(QiraahComparison.alignment(surahID: 1, tag: Settings.Riwayah.qaloon, quranData: data)?
            .riwayahNumberForHafs[4])
        let qalun = try XCTUnwrap(data.ayah(surah: 1, ayah: own)).rawArabicText(surahId: 1, qiraahOverride: Settings.Riwayah.qaloon)
        guard qalun != hafs, qalun.contains("مَلِكِ") else {
            throw XCTSkip("Qalun's text is not loaded in this simulator (showOtherQiraatReciters is off)")
        }
        XCTAssertEqual(own, 3)
        let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: Settings.Riwayah.qaloon,
                                                                     surah: 1, ownAyah: own, splitSpan: nil))
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["مَٰلِ"])
    }

    /// Hafs 11:40 against al-Bazzi: the print marks the alif of جَا (the hamzah of جَآءَ drops before
    /// أَمۡرُنَا, so Hafs's alif and its dropped hamzah are the counterpart) and the lām of كُلِّ.
    func testBazziAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let hafs = try XCTUnwrap(data.ayah(surah: 11, ayah: 40)).rawArabicText(surahId: 11, qiraahOverride: "")
        let own = try XCTUnwrap(QiraahComparison.alignment(surahID: 11, tag: Settings.Riwayah.buzzi, quranData: data)?
            .riwayahNumberForHafs[40])
        let bazzi = try XCTUnwrap(data.ayah(surah: 11, ayah: own)).rawArabicText(surahId: 11, qiraahOverride: Settings.Riwayah.buzzi)
        guard bazzi != hafs, bazzi.contains("جَا أَمۡرُنَا") else {
            throw XCTSkip("al-Bazzi's text is not loaded in this simulator (showOtherQiraatReciters is off)")
        }
        XCTAssertEqual(own, 40)
        let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: Settings.Riwayah.buzzi,
                                                                     surah: 11, ownAyah: own, splitSpan: nil))
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["آءَ", "لّٖ"])
    }

    /// Hafs 1:6 and 2:10 against Qunbul: the print marks the ṣād of ٱلصِّۜرَٰطَ (Qunbul reads it with a sīn)
    /// and the three changed letters of يُكَذِّبُونَ; the silah ۥ on the plural mīm is left black, so those
    /// words stay plain. Qunbul counts Makki, where الٓمٓ is not an ayah, so Hafs 2:10 is its own ayah 9.
    func testQunbulAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.qunbul
        let sirat = try XCTUnwrap(data.ayah(surah: 1, ayah: 6)).rawArabicText(surahId: 1, qiraahOverride: "")
        let ownSirat = try XCTUnwrap(QiraahComparison.alignment(surahID: 1, tag: tag, quranData: data)?
            .riwayahNumberForHafs[6])
        let qunbul = try XCTUnwrap(data.ayah(surah: 1, ayah: ownSirat)).rawArabicText(surahId: 1, qiraahOverride: tag)
        guard qunbul != sirat, qunbul.contains("ٱلصِّۜرَٰطَ") else {
            throw XCTSkip("Qunbul's text is not loaded in this simulator (showOtherQiraatReciters is off)")
        }
        XCTAssertEqual(ownSirat, 6)
        let siratRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: sirat, tag: tag, surah: 1,
                                                                          ownAyah: ownSirat, splitSpan: nil))
        XCTAssertEqual(siratRanges.map { text(sirat, $0) }, ["صِّ"])

        let hafs = try XCTUnwrap(data.ayah(surah: 2, ayah: 10)).rawArabicText(surahId: 2, qiraahOverride: "")
        let own = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: tag, quranData: data)?
            .riwayahNumberForHafs[10])
        XCTAssertEqual(own, 9)
        let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: tag, surah: 2,
                                                                     ownAyah: own, splitSpan: nil))
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["يَكۡذِ"])
    }

    /// Hafs 2:3 and 2:67 against as-Susi: the print marks the madd letter that replaces a sākin hamzah
    /// (يُومِنُونَ, يَامُرۡكُمۡ), the rā of يَامُرۡكُمۡ it reads sākin, and the wāw seat of هُزُؤٗا, so Hafs's ayahs
    /// tint only ؤ, then أ and ر apart in one word, then و. As-Susi counts Basri, where الٓمٓ is not an
    /// ayah, so Hafs 2:3 and 2:67 are its own ayahs 2 and 66.
    func testSusiAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.susi
        let believe = try XCTUnwrap(data.ayah(surah: 2, ayah: 3)).rawArabicText(surahId: 2, qiraahOverride: "")
        let ownBelieve = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: tag, quranData: data)?
            .riwayahNumberForHafs[3])
        let susi = try XCTUnwrap(data.ayah(surah: 2, ayah: ownBelieve)).rawArabicText(surahId: 2, qiraahOverride: tag)
        guard susi != believe, susi.contains("يُومِنُونَ") else {
            throw XCTSkip("as-Susi's text is not loaded in this simulator (showOtherQiraatReciters is off)")
        }
        XCTAssertEqual(ownBelieve, 2)
        let believeRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: believe, tag: tag, surah: 2,
                                                                            ownAyah: ownBelieve, splitSpan: nil))
        XCTAssertEqual(believeRanges.map { text(believe, $0) }, ["ؤۡ"])

        let hafs = try XCTUnwrap(data.ayah(surah: 2, ayah: 67)).rawArabicText(surahId: 2, qiraahOverride: "")
        let own = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: tag, quranData: data)?
            .riwayahNumberForHafs[67])
        XCTAssertEqual(own, 66)
        let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: tag, surah: 2,
                                                                     ownAyah: own, splitSpan: nil))
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["أۡ", "رُ", "وٗ"])
    }

    /// Hafs 2:271 and 21:4 against Shubah: the print marks the ʿayn it reads sākin in فَنِعۡمَّا and the nūn
    /// it reads for Hafs's yā in وَنُكَفِّرُ, so Hafs's ayah tints ع in one word and ي in the other. Where
    /// Shubah reads قُل for قَالَ the print marks the whole word, so Hafs's قَالَ tints whole and the
    /// rā of رَبِّي (Shubah رَّبِّي) alone. Shubah counts Kufi like Hafs, so the ayah numbers match.
    func testShubahAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.shubah
        let hafs = try XCTUnwrap(data.ayah(surah: 2, ayah: 271)).rawArabicText(surahId: 2, qiraahOverride: "")
        let own = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: tag, quranData: data)?
            .riwayahNumberForHafs[271])
        let shubah = try XCTUnwrap(data.ayah(surah: 2, ayah: own)).rawArabicText(surahId: 2, qiraahOverride: tag)
        guard shubah != hafs, shubah.contains("فَنِعۡمَّا") else {
            throw XCTSkip("Shubah's text is not loaded in this simulator (showOtherQiraatReciters is off)")
        }
        XCTAssertEqual(own, 271)
        let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: tag, surah: 2,
                                                                     ownAyah: own, splitSpan: nil))
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["عِ", "يُ"])

        let said = try XCTUnwrap(data.ayah(surah: 21, ayah: 4)).rawArabicText(surahId: 21, qiraahOverride: "")
        let ownSaid = try XCTUnwrap(QiraahComparison.alignment(surahID: 21, tag: tag, quranData: data)?
            .riwayahNumberForHafs[4])
        XCTAssertEqual(ownSaid, 4)
        let saidRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: said, tag: tag, surah: 21,
                                                                         ownAyah: ownSaid, splitSpan: nil))
        XCTAssertEqual(saidRanges.map { text(said, $0) }, ["قَالَ", "رَ"])
    }

    /// Hafs 2:10 and 2:85 against Hisham, the first beta print. Hisham counts Shami, where الٓمٓ is not an
    /// ayah and Hafs 2:10 is two ayahs (own 9 ends at أَلِيمُۢ, own 10 is بِمَا كَانُواْ يُكَذِّبُونَ), so the
    /// Hafs ayah is gathered from both pieces and tints only يَكۡذِ of يَكۡذِبُونَ, the print's يُكَذِّ. Hafs
    /// 2:85 is own 84: the ẓāʾ of تَظَٰهَرُونَ (Hisham تَظَّٰهَرُونَ) and تُفَٰ of تُفَٰدُوهُمۡ (Hisham
    /// تَفۡدُوهُمۡ). Beta text renders only after consent, so the test turns it on and back.
    func testHishamAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.hisham
        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = true
        guard BetaQiraatStore.shared.isAvailable(tag: tag) else {
            throw XCTSkip("Hisham's beta text is not bundled in this build")
        }
        let alignment = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: tag, quranData: data))

        let hafs = try XCTUnwrap(data.ayah(surah: 2, ayah: 10)).rawArabicText(surahId: 2, qiraahOverride: "")
        let own = try XCTUnwrap(alignment.riwayahNumberForHafs[10])
        XCTAssertEqual(own, 9)
        XCTAssertEqual(alignment.hafsRangeForRiwayah[own + 1], 10...10, "own 10 is the rest of Hafs 2:10")
        let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: tag, surah: 2,
                                                                     ownAyah: own, splitSpan: own...(own + 1)))
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["يَكۡذِ"])

        let ransom = try XCTUnwrap(data.ayah(surah: 2, ayah: 85)).rawArabicText(surahId: 2, qiraahOverride: "")
        let ownRansom = try XCTUnwrap(alignment.riwayahNumberForHafs[85])
        XCTAssertEqual(ownRansom, 84)
        let ransomRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: ransom, tag: tag, surah: 2,
                                                                           ownAyah: ownRansom, splitSpan: nil))
        XCTAssertEqual(ransomRanges.map { text(ransom, $0) }, ["ظَٰ", "تُفَٰ"])
    }

    /// Ibn Dhakwan, Ibn Amir's other rawi, counts Shami like Hisham: Hafs 2:10 is own 9 and 10 and tints
    /// only يَكۡذِ. Hafs 2:106 is own 105, where نَنسَخۡ (Ibn Dhakwan نُنسِخۡ) has two marked letters with an
    /// untouched nūn between them, so the Hafs word carries two separate runs, نَ and سَ. Hafs 18:34 is own
    /// 33 (al-Kahf has 106 ayahs in the Shami count): ثَمَ of ثَمَرٞ, the print's ثُمُ.
    func testIbnDhakwanAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.ibnDhakwan
        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = true
        guard BetaQiraatStore.shared.isAvailable(tag: tag) else {
            throw XCTSkip("Ibn Dhakwan's beta text is not bundled in this build")
        }
        let baqarah = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: tag, quranData: data))

        let hafs = try XCTUnwrap(data.ayah(surah: 2, ayah: 10)).rawArabicText(surahId: 2, qiraahOverride: "")
        let own = try XCTUnwrap(baqarah.riwayahNumberForHafs[10])
        XCTAssertEqual(own, 9)
        XCTAssertEqual(baqarah.hafsRangeForRiwayah[own + 1], 10...10, "own 10 is the rest of Hafs 2:10")
        let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: tag, surah: 2,
                                                                     ownAyah: own, splitSpan: own...(own + 1)))
        XCTAssertEqual(ranges.map { text(hafs, $0) }, ["يَكۡذِ"])

        let abrogate = try XCTUnwrap(data.ayah(surah: 2, ayah: 106)).rawArabicText(surahId: 2, qiraahOverride: "")
        let ownAbrogate = try XCTUnwrap(baqarah.riwayahNumberForHafs[106])
        XCTAssertEqual(ownAbrogate, 105)
        let abrogateRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: abrogate, tag: tag, surah: 2,
                                                                             ownAyah: ownAbrogate, splitSpan: nil))
        XCTAssertEqual(abrogateRanges.map { text(abrogate, $0) }, ["نَ", "سَ"])

        let kahf = try XCTUnwrap(QiraahComparison.alignment(surahID: 18, tag: tag, quranData: data))
        let fruit = try XCTUnwrap(data.ayah(surah: 18, ayah: 34)).rawArabicText(surahId: 18, qiraahOverride: "")
        let ownFruit = try XCTUnwrap(kahf.riwayahNumberForHafs[34])
        XCTAssertEqual(ownFruit, 33)
        let fruitRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: fruit, tag: tag, surah: 18,
                                                                          ownAyah: ownFruit, splitSpan: nil))
        XCTAssertEqual(fruitRanges.map { text(fruit, $0) }, ["ثَمَ"])
    }

    /// Abu al-Harith an al-Kisai, the third beta print, counts Kufi like Hafs, so the ayah numbers match.
    /// Hafs 3:109: تُرۡجَعُ (Abu al-Harith تَرۡجِعُ) has two marked letters with an untouched rā between
    /// them, so the Hafs word carries two separate runs, تُ and جَ. Hafs 3:39: the تۡ of فَنَادَتۡهُ (the
    /// print's فَنَادَىٰهُ marks the yā that stands in for it), the هُ of وَهُوَ (the print's وَهۡوَ) and
    /// يُبَشِّ of يُبَشِّرُكَ (the print's يَبۡشُرُ, three letters). Hafs 72:20: قُلۡ is marked whole for قَالَ.
    func testAbuHarithAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.abuHarith
        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = true
        guard BetaQiraatStore.shared.isAvailable(tag: tag) else {
            throw XCTSkip("Abu al-Harith's beta text is not bundled in this build")
        }
        let imran = try XCTUnwrap(QiraahComparison.alignment(surahID: 3, tag: tag, quranData: data))

        let returned = try XCTUnwrap(data.ayah(surah: 3, ayah: 109)).rawArabicText(surahId: 3, qiraahOverride: "")
        let own = try XCTUnwrap(imran.riwayahNumberForHafs[109])
        XCTAssertEqual(own, 109)
        let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: returned, tag: tag, surah: 3,
                                                                     ownAyah: own, splitSpan: nil))
        XCTAssertEqual(ranges.map { text(returned, $0) }, ["تُ", "جَ"])

        let glad = try XCTUnwrap(data.ayah(surah: 3, ayah: 39)).rawArabicText(surahId: 3, qiraahOverride: "")
        let ownGlad = try XCTUnwrap(imran.riwayahNumberForHafs[39])
        XCTAssertEqual(ownGlad, 39)
        let gladRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: glad, tag: tag, surah: 3,
                                                                         ownAyah: ownGlad, splitSpan: nil))
        XCTAssertEqual(gladRanges.map { text(glad, $0) }, ["تۡ", "هُ", "يُبَشِّ"])

        let jinn = try XCTUnwrap(QiraahComparison.alignment(surahID: 72, tag: tag, quranData: data))
        let say = try XCTUnwrap(data.ayah(surah: 72, ayah: 20)).rawArabicText(surahId: 72, qiraahOverride: "")
        let ownSay = try XCTUnwrap(jinn.riwayahNumberForHafs[20])
        XCTAssertEqual(ownSay, 20)
        let sayRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: say, tag: tag, surah: 72,
                                                                        ownAyah: ownSay, splitSpan: nil))
        XCTAssertEqual(sayRanges.map { text(say, $0) }, ["قُلۡ"])
    }

    /// ad-Duri an al-Kisai, the fourth beta print, shares al-Kisai's Kufi count with Hafs. Hafs 21:112:
    /// قَٰلَ is marked whole for the print's قُل, and the print's doubled رَّبِّ (the lām merges into it)
    /// carries only its rāʾ onto Hafs's رَبِّ. Hafs 2:284: the print's jazm on فَيَغۡفِرۡ and وَيُعَذِّب
    /// lands on the Hafs رُ and بُ, and the doubled مَّن on the Hafs مَ. Hafs 3:109: تُرۡجَعُ (the print's
    /// تَرۡجِعُ) has two marked letters with an untouched rāʾ between them, so two separate runs.
    func testDuriKisaiAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.duriKisai
        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = true
        guard BetaQiraatStore.shared.isAvailable(tag: tag) else {
            throw XCTSkip("ad-Duri an al-Kisai's beta text is not bundled in this build")
        }
        let prophets = try XCTUnwrap(QiraahComparison.alignment(surahID: 21, tag: tag, quranData: data))
        let judge = try XCTUnwrap(data.ayah(surah: 21, ayah: 112)).rawArabicText(surahId: 21, qiraahOverride: "")
        let ownJudge = try XCTUnwrap(prophets.riwayahNumberForHafs[112])
        XCTAssertEqual(ownJudge, 112)
        let judgeRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: judge, tag: tag, surah: 21,
                                                                           ownAyah: ownJudge, splitSpan: nil))
        XCTAssertEqual(judgeRanges.map { text(judge, $0) }, ["قَٰلَ", "رَ"])

        let cow = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: tag, quranData: data))
        let forgive = try XCTUnwrap(data.ayah(surah: 2, ayah: 284)).rawArabicText(surahId: 2, qiraahOverride: "")
        let ownForgive = try XCTUnwrap(cow.riwayahNumberForHafs[284])
        XCTAssertEqual(ownForgive, 284)
        let forgiveRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: forgive, tag: tag, surah: 2,
                                                                             ownAyah: ownForgive, splitSpan: nil))
        XCTAssertEqual(forgiveRanges.map { text(forgive, $0) }, ["رُ", "بُ", "مَ"])

        let imran = try XCTUnwrap(QiraahComparison.alignment(surahID: 3, tag: tag, quranData: data))
        let returned = try XCTUnwrap(data.ayah(surah: 3, ayah: 109)).rawArabicText(surahId: 3, qiraahOverride: "")
        let own = try XCTUnwrap(imran.riwayahNumberForHafs[109])
        XCTAssertEqual(own, 109)
        let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: returned, tag: tag, surah: 3,
                                                                     ownAyah: own, splitSpan: nil))
        XCTAssertEqual(ranges.map { text(returned, $0) }, ["تُ", "جَ"])
    }

    /// Ibn Wardan an Abi Jafar, the fifth beta print, counts Madani: الٓمٓ is not an ayah, so Hafs 2:6 is
    /// his own ayah 5. There the print's tashil pair ءَٰا۬ lands on Hafs's ءَأَ, and Abu Jafar's ibdal of the
    /// sākin hamzah (يُومِنُونَ) on Hafs's ؤ alone. Hafs 3:23: لِيُحۡكَمَ marks two letters with the ḥāʾ between
    /// them untouched, so two runs on Hafs's لِيَحۡكُمَ. Hafs 43:24 (own 23): قُلۡ is marked whole for Hafs's
    /// قَٰلَ, and جِينَٰكُمُۥ carries its yāʾ onto Hafs's ئ while the tāʾ Hafs alone reads is changed by definition.
    func testIbnWardanAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.ibnWardan
        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = true
        guard BetaQiraatStore.shared.isAvailable(tag: tag) else {
            throw XCTSkip("Ibn Wardan's beta text is not bundled in this build")
        }
        let cow = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: tag, quranData: data))
        let warned = try XCTUnwrap(data.ayah(surah: 2, ayah: 6)).rawArabicText(surahId: 2, qiraahOverride: "")
        let ownWarned = try XCTUnwrap(cow.riwayahNumberForHafs[6])
        XCTAssertEqual(ownWarned, 5)
        let warnedRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: warned, tag: tag, surah: 2,
                                                                            ownAyah: ownWarned, splitSpan: nil))
        XCTAssertEqual(warnedRanges.map { text(warned, $0) }, ["ءَأَ", "ؤۡ"])

        let imran = try XCTUnwrap(QiraahComparison.alignment(surahID: 3, tag: tag, quranData: data))
        let judge = try XCTUnwrap(data.ayah(surah: 3, ayah: 23)).rawArabicText(surahId: 3, qiraahOverride: "")
        let ownJudge = try XCTUnwrap(imran.riwayahNumberForHafs[23])
        XCTAssertEqual(ownJudge, 23)
        let judgeRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: judge, tag: tag, surah: 3,
                                                                           ownAyah: ownJudge, splitSpan: nil))
        XCTAssertEqual(judgeRanges.map { text(judge, $0) }, ["يَ", "كُ"])

        let ornaments = try XCTUnwrap(QiraahComparison.alignment(surahID: 43, tag: tag, quranData: data))
        let said = try XCTUnwrap(data.ayah(surah: 43, ayah: 24)).rawArabicText(surahId: 43, qiraahOverride: "")
        let ownSaid = try XCTUnwrap(ornaments.riwayahNumberForHafs[24])
        XCTAssertEqual(ownSaid, 23)
        let saidRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: said, tag: tag, surah: 43,
                                                                          ownAyah: ownSaid, splitSpan: nil))
        XCTAssertEqual(saidRanges.map { text(said, $0) }, ["قَٰلَ", "ئۡتُ"])
    }
    /// Ibn Jammaz an Abi Jafar, the sixth beta print, shares Abu Jafar's Madani count and nearly every mark
    /// with Ibn Wardan: Hafs 2:6 is again his own ayah 5, with ءَٰا۬ landing on Hafs's ءَأَ and the ibdal wāw
    /// on its ؤ alone. Hafs 3:13 carries one of the two marks only he has, يُوَيِّدُ for Hafs's يُؤَيِّدُ, beside
    /// Abu Jafar's فِيَتَيۡنِ, فِيَةٞ, رَايَ and the wasl dot of اِ۪نَّ, while تَرَوۡنَهُمُۥ for يَرَوۡنَهُم tints the
    /// yāʾ his tāʾ replaces. Hafs 11:116 carries the other: بِقۡيَةٖ marks three letters, one run on بَقِيَّةٖ.
    func testIbnJammazAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.ibnJammaz
        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = true
        guard BetaQiraatStore.shared.isAvailable(tag: tag) else {
            throw XCTSkip("Ibn Jammaz's beta text is not bundled in this build")
        }
        let cow = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: tag, quranData: data))
        let warned = try XCTUnwrap(data.ayah(surah: 2, ayah: 6)).rawArabicText(surahId: 2, qiraahOverride: "")
        let ownWarned = try XCTUnwrap(cow.riwayahNumberForHafs[6])
        XCTAssertEqual(ownWarned, 5)
        let warnedRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: warned, tag: tag, surah: 2,
                                                                            ownAyah: ownWarned, splitSpan: nil))
        XCTAssertEqual(warnedRanges.map { text(warned, $0) }, ["ءَأَ", "ؤۡ"])

        let imran = try XCTUnwrap(QiraahComparison.alignment(surahID: 3, tag: tag, quranData: data))
        let sign = try XCTUnwrap(data.ayah(surah: 3, ayah: 13)).rawArabicText(surahId: 3, qiraahOverride: "")
        let ownSign = try XCTUnwrap(imran.riwayahNumberForHafs[13])
        XCTAssertEqual(ownSign, 13)
        let signRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: sign, tag: tag, surah: 3,
                                                                          ownAyah: ownSign, splitSpan: nil))
        XCTAssertEqual(signRanges.map { text(sign, $0) }, ["ئَ", "ئَ", "يَ", "أۡ", "ؤَ", "إِ"])

        let hud = try XCTUnwrap(QiraahComparison.alignment(surahID: 11, tag: tag, quranData: data))
        let remnant = try XCTUnwrap(data.ayah(surah: 11, ayah: 116)).rawArabicText(surahId: 11, qiraahOverride: "")
        let ownRemnant = try XCTUnwrap(hud.riwayahNumberForHafs[116])
        XCTAssertEqual(ownRemnant, 116)
        let remnantRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: remnant, tag: tag, surah: 11,
                                                                             ownAyah: ownRemnant, splitSpan: nil))
        XCTAssertEqual(remnantRanges.map { text(remnant, $0) }, ["بَقِيَّ"])
    }

    /// Ruways an Yaqub, the seventh beta print, counts Basri: Hafs 2:6 is his own ayah 5, where Yaqub's
    /// عَلَيۡهُمۡ tints the hāʾ of عَلَيۡهِمۡ and the tashil of ءَا۬نذَرۡتَهُمۡ lands on the second hamzah alone, with
    /// nothing on the first. Hafs 2:10 is his own 9, where يُكَذِّبُونَ marks three letters, one run on يَكۡذِبُونَ.
    /// Hafs 2:260 is his own 261: أَرۡنِي tints only the rāʾ of أَرِنِي and فَصِرۡهُنَّ only the ṣād of فَصُرۡهُنَّ.
    /// Hafs 11:44 keeps its number and carries his ishmam on identical text: the qāf of each وَقِيلَ and the
    /// ghayn of وَغِيضَ, with the trailing alif of his وَقِيلَا never spilling onto Hafs, beside أَقۡلِعِي's hamzah.
    func testRuwaysAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.ruways
        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = true
        guard BetaQiraatStore.shared.isAvailable(tag: tag) else {
            throw XCTSkip("Ruways's beta text is not bundled in this build")
        }
        let cow = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: tag, quranData: data))
        let warned = try XCTUnwrap(data.ayah(surah: 2, ayah: 6)).rawArabicText(surahId: 2, qiraahOverride: "")
        let ownWarned = try XCTUnwrap(cow.riwayahNumberForHafs[6])
        XCTAssertEqual(ownWarned, 5)
        let warnedRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: warned, tag: tag, surah: 2,
                                                                            ownAyah: ownWarned, splitSpan: nil))
        XCTAssertEqual(warnedRanges.map { text(warned, $0) }, ["هِ", "أَ"])

        let liars = try XCTUnwrap(data.ayah(surah: 2, ayah: 10)).rawArabicText(surahId: 2, qiraahOverride: "")
        let ownLiars = try XCTUnwrap(cow.riwayahNumberForHafs[10])
        XCTAssertEqual(ownLiars, 9)
        let liarsRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: liars, tag: tag, surah: 2,
                                                                           ownAyah: ownLiars, splitSpan: nil))
        XCTAssertEqual(liarsRanges.map { text(liars, $0) }, ["يَكۡذِ"])

        let birds = try XCTUnwrap(data.ayah(surah: 2, ayah: 260)).rawArabicText(surahId: 2, qiraahOverride: "")
        let ownBirds = try XCTUnwrap(cow.riwayahNumberForHafs[260])
        XCTAssertEqual(ownBirds, 261)
        let birdsRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: birds, tag: tag, surah: 2,
                                                                           ownAyah: ownBirds, splitSpan: nil))
        XCTAssertEqual(birdsRanges.map { text(birds, $0) }, ["رِ", "صُ"])

        let hud = try XCTUnwrap(QiraahComparison.alignment(surahID: 11, tag: tag, quranData: data))
        let flood = try XCTUnwrap(data.ayah(surah: 11, ayah: 44)).rawArabicText(surahId: 11, qiraahOverride: "")
        let ownFlood = try XCTUnwrap(hud.riwayahNumberForHafs[44])
        XCTAssertEqual(ownFlood, 44)
        let floodRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: flood, tag: tag, surah: 11,
                                                                           ownAyah: ownFlood, splitSpan: nil))
        XCTAssertEqual(floodRanges.map { text(flood, $0) }, ["قِ", "أَ", "غِ", "قِ"])
    }

    /// Rawh an Yaqub, the eighth beta print, counts Basri like Ruways but reads his own pack: Hafs 2:6 is
    /// his own ayah 5, where عَلَيۡهُمۡ tints only the hāʾ of عَلَيۡهِمۡ (the tashil of ءَأَنذَرۡتَهُمۡ was Ruways's).
    /// Hafs 3:57 keeps its number: فَنُوَفِّيهُمۡ marks its nūn and its hāʾ, so the unpaired yāʾ and the hāʾ of
    /// فَيُوَفِّيهِمۡ tint as two runs. Hafs 16:2 marks three words at once: تَنَزَّلُ tints the yāʾ and the zāy
    /// of يُنَزِّلُ with the nūn between them plain, then the tāʾ marbūṭah of ٱلۡمَلَٰٓئِكَةَ and the nūn of
    /// فَٱتَّقُونِ. Hafs 7:123 is his own 122, where ءَأَٰمَنتُم marks its first hamzah: the tint lands on the
    /// first hamzah of ءَامَنتُم, where the print put it, not on the alif the computed change would pick.
    func testRawhAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.rawh
        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = true
        guard BetaQiraatStore.shared.isAvailable(tag: tag) else {
            throw XCTSkip("Rawh's beta text is not bundled in this build")
        }
        let cow = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: tag, quranData: data))
        let warned = try XCTUnwrap(data.ayah(surah: 2, ayah: 6)).rawArabicText(surahId: 2, qiraahOverride: "")
        let ownWarned = try XCTUnwrap(cow.riwayahNumberForHafs[6])
        XCTAssertEqual(ownWarned, 5)
        let warnedRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: warned, tag: tag, surah: 2,
                                                                            ownAyah: ownWarned, splitSpan: nil))
        XCTAssertEqual(warnedRanges.map { text(warned, $0) }, ["هِ"])

        let imran = try XCTUnwrap(QiraahComparison.alignment(surahID: 3, tag: tag, quranData: data))
        let wages = try XCTUnwrap(data.ayah(surah: 3, ayah: 57)).rawArabicText(surahId: 3, qiraahOverride: "")
        let ownWages = try XCTUnwrap(imran.riwayahNumberForHafs[57])
        XCTAssertEqual(ownWages, 57)
        let wagesRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: wages, tag: tag, surah: 3,
                                                                           ownAyah: ownWages, splitSpan: nil))
        XCTAssertEqual(wagesRanges.map { text(wages, $0) }, ["يُ", "هِ"])

        let bee = try XCTUnwrap(QiraahComparison.alignment(surahID: 16, tag: tag, quranData: data))
        let angels = try XCTUnwrap(data.ayah(surah: 16, ayah: 2)).rawArabicText(surahId: 16, qiraahOverride: "")
        let ownAngels = try XCTUnwrap(bee.riwayahNumberForHafs[2])
        XCTAssertEqual(ownAngels, 2)
        let angelsRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: angels, tag: tag, surah: 16,
                                                                            ownAyah: ownAngels, splitSpan: nil))
        XCTAssertEqual(angelsRanges.map { text(angels, $0) }, ["يُ", "زِّ", "ةَ", "نِ"])

        let heights = try XCTUnwrap(QiraahComparison.alignment(surahID: 7, tag: tag, quranData: data))
        let pharaoh = try XCTUnwrap(data.ayah(surah: 7, ayah: 123)).rawArabicText(surahId: 7, qiraahOverride: "")
        let ownPharaoh = try XCTUnwrap(heights.riwayahNumberForHafs[123])
        XCTAssertEqual(ownPharaoh, 122)
        let pharaohRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: pharaoh, tag: tag, surah: 7,
                                                                            ownAyah: ownPharaoh, splitSpan: nil))
        XCTAssertEqual(pharaohRanges.map { text(pharaoh, $0) }, ["ءَ"])
    }

    /// Ishaq an Khalaf al-Ashir, the ninth beta print, counts Kufi like Hafs, so his own numbers are the
    /// Hafs numbers. Hafs 2:85 marks two words: تَفۡدُوهُمۡ tints the tāʾ and the fāʾ of تُفَٰدُوهُمۡ as one run,
    /// and يَعۡمَلُونَ only the tāʾ of تَعۡمَلُونَ. Hafs 2:98 holds the two names: وَجَبۡرَءِيلَ marks its jīm, its
    /// rāʾ and the hamzah Hafs lacks, which tints the jīm and the rāʾ of وَجِبۡرِيلَ (the hamzah anchors to
    /// the rāʾ it follows), and وَمِيكَٰٓـِٔيلَ marks its kāf, the hamzah on the tatweel (a cluster of its
    /// own, as the tatweel sits in the base-letter range) and its yāʾ, so كَىٰ tints as one run and the lām
    /// stays plain. Hafs 22:2 marks only the sīn and the kāf of سَكۡرٜىٰ twice, narrower than the computed
    /// change, which would reach the rāʾ. Hafs 36:35 drops a letter: عَمِلَتۡ marks its tāʾ, and the hāʾ
    /// Hafs adds in عَمِلَتۡهُ is changed by definition, so تۡهُ tints as one run.
    func testIshaqAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.ishaq
        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = true
        guard BetaQiraatStore.shared.isAvailable(tag: tag) else {
            throw XCTSkip("Ishaq's beta text is not bundled in this build")
        }
        let cow = try XCTUnwrap(QiraahComparison.alignment(surahID: 2, tag: tag, quranData: data))
        let ransom = try XCTUnwrap(data.ayah(surah: 2, ayah: 85)).rawArabicText(surahId: 2, qiraahOverride: "")
        let ownRansom = try XCTUnwrap(cow.riwayahNumberForHafs[85])
        XCTAssertEqual(ownRansom, 85)
        let ransomRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: ransom, tag: tag, surah: 2,
                                                                            ownAyah: ownRansom, splitSpan: nil))
        XCTAssertEqual(ransomRanges.map { text(ransom, $0) }, ["تُفَٰ", "تَ"])

        let angels = try XCTUnwrap(data.ayah(surah: 2, ayah: 98)).rawArabicText(surahId: 2, qiraahOverride: "")
        let ownAngels = try XCTUnwrap(cow.riwayahNumberForHafs[98])
        XCTAssertEqual(ownAngels, 98)
        let angelsRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: angels, tag: tag, surah: 2,
                                                                            ownAyah: ownAngels, splitSpan: nil))
        XCTAssertEqual(angelsRanges.map { text(angels, $0) }, ["جِ", "رِ", "كَىٰ"])

        let hajj = try XCTUnwrap(QiraahComparison.alignment(surahID: 22, tag: tag, quranData: data))
        let drunk = try XCTUnwrap(data.ayah(surah: 22, ayah: 2)).rawArabicText(surahId: 22, qiraahOverride: "")
        let ownDrunk = try XCTUnwrap(hajj.riwayahNumberForHafs[2])
        XCTAssertEqual(ownDrunk, 2)
        let drunkRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: drunk, tag: tag, surah: 22,
                                                                           ownAyah: ownDrunk, splitSpan: nil))
        XCTAssertEqual(drunkRanges.map { text(drunk, $0) }, ["سُكَٰ", "سُكَٰ"])

        let yaSin = try XCTUnwrap(QiraahComparison.alignment(surahID: 36, tag: tag, quranData: data))
        let fruit = try XCTUnwrap(data.ayah(surah: 36, ayah: 35)).rawArabicText(surahId: 36, qiraahOverride: "")
        let ownFruit = try XCTUnwrap(yaSin.riwayahNumberForHafs[35])
        XCTAssertEqual(ownFruit, 35)
        let fruitRanges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: fruit, tag: tag, surah: 36,
                                                                           ownAyah: ownFruit, splitSpan: nil))
        XCTAssertEqual(fruitRanges.map { text(fruit, $0) }, ["ثَمَ", "تۡهُ"])
    }

    /// Idris an Khalaf al-Ashir, the tenth beta print and the last letter print, reads Ishaq's text: his
    /// pack and his text are Ishaq's byte for byte, and he counts Kufi too. The four Ishaq sites tint the
    /// same letters under his tag, and the two tags agree range for range, so the tint follows the pack
    /// his tag opens rather than the name on the picker.
    func testIdrisAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.idris
        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = true
        guard BetaQiraatStore.shared.isAvailable(tag: tag) else {
            throw XCTSkip("Idris's beta text is not bundled in this build")
        }
        let sites: [(surah: Int, ayah: Int, tinted: [String])] = [
            (2, 85, ["تُفَٰ", "تَ"]),
            (2, 98, ["جِ", "رِ", "كَىٰ"]),
            (22, 2, ["سُكَٰ", "سُكَٰ"]),
            (36, 35, ["ثَمَ", "تۡهُ"]),
        ]
        for site in sites {
            let where_ = "\(site.surah):\(site.ayah)"
            let alignment = try XCTUnwrap(QiraahComparison.alignment(surahID: site.surah, tag: tag, quranData: data))
            let hafs = try XCTUnwrap(data.ayah(surah: site.surah, ayah: site.ayah))
                .rawArabicText(surahId: site.surah, qiraahOverride: "")
            let own = try XCTUnwrap(alignment.riwayahNumberForHafs[site.ayah], where_)
            XCTAssertEqual(own, site.ayah, where_)
            let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: tag, surah: site.surah,
                                                                          ownAyah: own, splitSpan: nil), where_)
            XCTAssertEqual(ranges.map { text(hafs, $0) }, site.tinted, where_)
            let ishaq = QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: Settings.Riwayah.ishaq,
                                                          surah: site.surah, ownAyah: own, splitSpan: nil)
            XCTAssertEqual(ranges, ishaq ?? [], "\(where_): Idris and Ishaq disagree")
        }
    }

    /// ad-Duri an Abi Amr, the first whole-word print to join: his page inks the whole word, so the
    /// builder narrows each mark to the clusters that differ from the aligned Hafs word. He counts
    /// Basri, so Hafs 2:9 through 2:31 are his own 8 through 30. يُخَٰدِعُونَ and يُكَذِّبُونَ each mark one run of
    /// three letters on يَخۡدَعُونَ and يَكۡذِبُونَ; the eased hamzah of اَ۬لَآ tints only the hamzah of أَلَآ (not
    /// the lām, which his bare-alif spelling once made the normaliser read as an article); وَهۡوَ tints
    /// the hāʾ of وَهُوَ; the opened yāʾ of إِنِّيَ tints the yāʾ of إِنِّيٓ; and هَٰٓؤُلَآ, which drops the
    /// final hamzah, names its last letter, so Hafs's هَٰٓؤُلَآءِ tints the alif and the hamzah it keeps.
    func testDuriAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.duri
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: tag))
        let sites: [(surah: Int, ayah: Int, tinted: [String])] = [
            (2, 9, ["يَخۡدَ"]),
            (2, 10, ["يَكۡذِ"]),
            (2, 13, ["أَ"]),
            (2, 29, ["هُ"]),
            (2, 30, ["يٓ"]),
            (2, 31, ["آءِ"]),
        ]
        for site in sites {
            let where_ = "\(site.surah):\(site.ayah)"
            let alignment = try XCTUnwrap(QiraahComparison.alignment(surahID: site.surah, tag: tag, quranData: data))
            let hafs = try XCTUnwrap(data.ayah(surah: site.surah, ayah: site.ayah))
                .rawArabicText(surahId: site.surah, qiraahOverride: "")
            let own = try XCTUnwrap(alignment.riwayahNumberForHafs[site.ayah], where_)
            XCTAssertEqual(own, site.ayah - 1, where_)
            let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: tag, surah: site.surah,
                                                                          ownAyah: own, splitSpan: nil), where_)
            XCTAssertEqual(ranges.map { text(hafs, $0) }, site.tinted, where_)
        }
    }

    /// Khalaf an Hamzah, the second whole-word print to join and the eleventh beta print: his page inks
    /// the whole word, so the builder narrows each mark to the clusters that differ from the aligned
    /// Hafs word. He counts Kufi, so his own numbers are Hafs's. مَلِكِ tints the mīm of مَٰلِكِ; both
    /// عَلَيۡهُمۡ of 1:7 tint the hāʾ of عَلَيۡهِمۡ; the hāʾ as-sakt he drops in wasl (هِيَه۠) tints the hāʾ of
    /// هِيَهۡ, a difference only the wasl sign carries; in 13:4 the shaddah his text writes on وَّزَرۡعٖ,
    /// وَّنَخِيلٖ, وَّغَيۡرِ and وَّيُفَضِّلُ (the previous word's idgham) tints nothing, so each tints its own
    /// difference, and تُسۡقٜىٰ tints the yāʾ and the qāf of يُسۡقَىٰ, not the sīn between; سَيُكۡتَبُ tints
    /// the nūn and the tāʾ of سَنَكۡتُبُ, not the kāf; ثُمُرِهِۦ and عَمِلَتۡ tint what they tint under Ishaq;
    /// and in 7:44 Hafs's own idgham shaddah on لَّعۡنَةُ tints nothing either, so أَنَّ tints the nūn of
    /// أَن and لَعۡنَةَ the tāʾ marbūṭah of لَّعۡنَةُ.
    func testKhalafAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.khalaf
        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = true
        guard BetaQiraatStore.shared.isAvailable(tag: tag) else {
            throw XCTSkip("Khalaf's beta text is not bundled in this build")
        }
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: tag))
        let sites: [(surah: Int, ayah: Int, tinted: [String])] = [
            (1, 4, ["مَٰ"]),
            (1, 7, ["هِ", "هِ"]),
            (101, 10, ["هۡ"]),
            (13, 4, ["عٞ", "لٞ", "نٞ", "رُ", "يُ", "قَ", "نُ"]),
            (3, 181, ["نَ", "تُ", "لَ", "نَ"]),
            (36, 35, ["ثَمَ", "تۡهُ"]),
            (7, 44, ["ن", "ةُ"]),
        ]
        for site in sites {
            let where_ = "\(site.surah):\(site.ayah)"
            let alignment = try XCTUnwrap(QiraahComparison.alignment(surahID: site.surah, tag: tag, quranData: data))
            let hafs = try XCTUnwrap(data.ayah(surah: site.surah, ayah: site.ayah))
                .rawArabicText(surahId: site.surah, qiraahOverride: "")
            let own = try XCTUnwrap(alignment.riwayahNumberForHafs[site.ayah], where_)
            XCTAssertEqual(own, site.ayah, where_)
            let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: tag, surah: site.surah,
                                                                          ownAyah: own, splitSpan: nil), where_)
            XCTAssertEqual(ranges.map { text(hafs, $0) }, site.tinted, where_)
        }
    }

    /// Khallad an Hamzah, the third whole-word print and the last riwayah to join: the builder narrows
    /// his marks like Khalaf's, and he counts Kufi, so his own numbers are Hafs's. Both عَلَيۡهُمۡ of 1:7
    /// tint the hāʾ of عَلَيۡهِمۡ, as under Khalaf. His text drops the vowel of a word's first letter
    /// here and there (ونُكَفِّرۡ, ويُفَضِّلُ, لتُقُولُنَّ); no word begins with a vowelless consonant, so
    /// that letter takes Hafs's vowel and tints nothing: ونُكَفِّرۡ tints the yāʾ and the rāʾ of
    /// وَيُكَفِّرُ, not the wāw, and 13:4 tints one letter per word as under Khalaf. His يَاجُوجَ and
    /// وَمَاجُوجَ tint only the hamzah seat of يَأۡجُوجَ and وَمَأۡجُوجَ (a bare madd letter no longer reaches
    /// back to the letter before it), and خَرَٰجًا tints the rāʾ of خَرۡجًا. Readings that are his alone
    /// against Khalaf: وَيُعَذِّب with jazm tints the bāʾ of وَيُعَذِّبُ (and فَيَغۡفِرۡ the rāʾ), مَعۡذِرَةٌ
    /// tints the tāʾ marbūṭah of مَعۡذِرَةً, مَن without the sakt tints the nūn of مَنۡۜ with its sakt
    /// sign, and فَٱلۡمُلۡقِيَٰت, read into the next word, tints the final tāʾ. In 27:49 لَتُبَيِّتُنَّهُۥ,
    /// لتُقُولُنَّ and مُهۡلَكَ each tint two letters with the letters between left plain.
    func testKhalladAyahTintsOnlyTheCounterpartLetters() async throws {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let tag = Settings.Riwayah.khallad
        let betaWasEnabled = Settings.shared.betaQiraatEnabled
        defer { Settings.shared.betaQiraatEnabled = betaWasEnabled }
        Settings.shared.betaQiraatEnabled = true
        guard BetaQiraatStore.shared.isAvailable(tag: tag) else {
            throw XCTSkip("Khallad's beta text is not bundled in this build")
        }
        XCTAssertTrue(QiraatLetterDiff.isLetterLevel(tag: tag))
        let sites: [(surah: Int, ayah: Int, tinted: [String])] = [
            (1, 7, ["هِ", "هِ"]),
            (2, 271, ["نِ", "يُ", "رُ"]),
            (13, 4, ["عٞ", "لٞ", "نٞ", "رُ", "يُ", "قَ", "نُ"]),
            (18, 94, ["أۡ", "أۡ", "رۡ"]),
            (2, 284, ["رُ", "بُ"]),
            (7, 164, ["ةً"]),
            (75, 27, ["نۡۜ"]),
            (77, 5, ["تِ"]),
            (27, 49, ["نُ", "تَ", "نَ", "لَ", "مَ", "لِ"]),
        ]
        for site in sites {
            let where_ = "\(site.surah):\(site.ayah)"
            let alignment = try XCTUnwrap(QiraahComparison.alignment(surahID: site.surah, tag: tag, quranData: data))
            let hafs = try XCTUnwrap(data.ayah(surah: site.surah, ayah: site.ayah))
                .rawArabicText(surahId: site.surah, qiraahOverride: "")
            let own = try XCTUnwrap(alignment.riwayahNumberForHafs[site.ayah], where_)
            XCTAssertEqual(own, site.ayah, where_)
            let ranges = try XCTUnwrap(QiraatLetterDiff.hafsLetterRanges(hafsText: hafs, tag: tag, surah: site.surah,
                                                                          ownAyah: own, splitSpan: nil), where_)
            XCTAssertEqual(ranges.map { text(hafs, $0) }, site.tinted, where_)
        }
    }

    /// A changed word the print leaves black (the Explorer's fallback, `QiraatPlaceBuilder`): the
    /// letters the two words themselves disagree on. A base that differs (Hafs's hamzah seat against
    /// Warsh's wāw), a mark that differs (the dagger alif of مَٰلِكِ), a letter one side adds (a silah
    /// written as a wāw of its own, which lands on the mīm it follows; the mīm's own vowel changes
    /// too), and nothing where the words agree.
    func testUnmarkedWordNarrowsToTheLettersThatDiffer() {
        func both(_ hafs: String, _ riwayah: String) -> ([String], [String]) {
            let ranges = QiraatLetterDiff.wordDiffRanges(hafsWord: hafs, riwayahWord: riwayah)
            return (ranges.hafs.map { text(hafs, $0) }, ranges.riwayah.map { text(riwayah, $0) })
        }
        XCTAssertEqual(both("يُؤۡمِنُونَ", "يُومِنُونَ").0, ["ؤۡ"])
        XCTAssertEqual(both("يُؤۡمِنُونَ", "يُومِنُونَ").1, ["و"])
        XCTAssertEqual(both("مَٰلِكِ", "مَلِكِ").0, ["مَٰ"])
        XCTAssertEqual(both("مَٰلِكِ", "مَلِكِ").1, ["مَ"])
        XCTAssertEqual(both("رَزَقۡنَٰهُمۡ", "رَزَقۡنَٰهُمُو").0, ["مۡ"])
        XCTAssertEqual(both("رَزَقۡنَٰهُمۡ", "رَزَقۡنَٰهُمُو").1, ["مُو"])
        XCTAssertEqual(both("رَزَقۡنَٰهُمۡ", "رَزَقۡنَٰهُمۡ").0, [])
        XCTAssertEqual(both("رَزَقۡنَٰهُمۡ", "رَزَقۡنَٰهُمۡ").1, [])
    }
}
