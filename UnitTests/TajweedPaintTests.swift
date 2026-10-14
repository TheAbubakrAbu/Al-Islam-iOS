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
}
