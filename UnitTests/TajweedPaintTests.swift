import XCTest
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
}
