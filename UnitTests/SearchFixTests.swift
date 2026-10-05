import XCTest
@testable import iPhone

/// Quran search, both lanes, against the app's own index (Quality Guide, Phase 8). Each case was a
/// wrong or empty result on 2026-10-04, measured on the shipped text.
final class SearchFixTests: XCTestCase {

    @MainActor
    private func snapshot() async throws -> QuranData.VerseSearchSnapshot {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        data.ensureVerseSearchIndex()
        for await ready in data.$isVerseSearchReady.values where ready { break }
        return try XCTUnwrap(data.verseSearchSnapshot())
    }

    private func refs(_ entries: [VerseIndexEntry]) -> [String] {
        entries.map { "\($0.surah):\($0.ayah)" }
    }

    /// Q1: a hamza typed on its seat finds the mushaf's seatless spelling (شَيۡـًٔا, إِسۡرَٰٓءِيلَ), in the
    /// exact scan and the ranked lane alike. Both found nothing.
    @MainActor
    func testSeatedHamzaFindsTheMushafSpelling() async throws {
        let snapshot = try await snapshot()
        // شيئا
        let shayan = snapshot.search(term: "\u{0634}\u{064A}\u{0626}\u{0627}", limit: .max)
        XCTAssertGreaterThanOrEqual(shayan.count, 76)
        XCTAssertTrue(refs(shayan).contains("2:48"), "2:48 not among \(shayan.count)")
        // إسرائيل
        let israil = snapshot.search(term: "\u{0625}\u{0633}\u{0631}\u{0627}\u{0626}\u{064A}\u{0644}", limit: .max)
        XCTAssertGreaterThanOrEqual(israil.count, 41)
        XCTAssertTrue(refs(israil).contains("2:40"))

        let ranked = QuranRankedSearch.search("\u{0634}\u{064A}\u{0626}\u{0627}", snapshot: snapshot, limit: 200)
        XCTAssertGreaterThanOrEqual(ranked.total, 76)
        XCTAssertTrue(refs(ranked.hits).contains("2:48"))
    }

    /// Q1: a word that occurs as typed keeps exactly its own rows (the other spellings are a fallback).
    @MainActor
    func testATypedWordThatOccursIsNotRespelled() async throws {
        let snapshot = try await snapshot()
        // في, which would also be فى (folding to فا) if the fallback ran
        let fi = snapshot.search(term: "\u{0641}\u{064A}", limit: .max)
        let fiFolded = Settings.shared.cleanSearch("\u{0641}\u{064A}", whitespace: true)
        XCTAssertFalse(fi.isEmpty)
        XCTAssertTrue(fi.allSatisfy { $0.arabicBlob.contains(fiFolded) || $0.silentArabicBlob.contains(fiFolded) })
    }

    /// Q5: a final ya typed for an alef maqsura (موسي for موسى) finds the same ayahs, in both lanes.
    @MainActor
    func testFinalYaMeetsAlefMaqsura() async throws {
        let snapshot = try await snapshot()
        let typed = snapshot.search(term: "\u{0645}\u{0648}\u{0633}\u{064A}", limit: .max)
        let printed = snapshot.search(term: "\u{0645}\u{0648}\u{0633}\u{0649}", limit: .max)
        XCTAssertGreaterThan(printed.count, 100)
        XCTAssertEqual(refs(typed), refs(printed))

        let ranked = QuranRankedSearch.search("\u{0645}\u{0648}\u{0633}\u{064A}", snapshot: snapshot, limit: 300)
        XCTAssertGreaterThan(ranked.total, 100)
        XCTAssertTrue(refs(ranked.hits).contains("2:51"))
    }

    /// Q4: a word typed with a bare ء is ranked as itself, not as its hamza-less stub: every ماء row
    /// carries ماء, and the particle ما leads nothing.
    @MainActor
    func testRankedLaneKeepsATypedHamza() async throws {
        let snapshot = try await snapshot()
        let maa = "\u{0645}\u{0627}\u{0621}"
        let ranked = QuranRankedSearch.search(maa, snapshot: snapshot, limit: 40)
        XCTAssertFalse(ranked.hits.isEmpty)
        let filter = try XCTUnwrap(Settings.HamzaPrecisionFilter(query: maa))
        for hit in ranked.hits {
            XCTAssertTrue(filter.matches(lanes: hit.hamzaArabicBlob), "\(hit.surah):\(hit.ayah) has no ماء")
        }
        XCTAssertLessThan(ranked.total, 400, "the particle's ayahs are back (2,714 before)")
    }

    /// Q2: a stem found inside an unrelated word (صلاه in يَصۡلَىٰهَا, "burn in it") no longer throws out
    /// the ayahs whose ٱلصَّلَوٰةَ the skeleton matched whole.
    @MainActor
    func testPrayerIsNotBurning() async throws {
        let snapshot = try await snapshot()
        // الصلاة
        let ranked = QuranRankedSearch.search("\u{0627}\u{0644}\u{0635}\u{0644}\u{0627}\u{0629}", snapshot: snapshot, limit: 100)
        XCTAssertGreaterThanOrEqual(ranked.total, 50)
        let top = refs(Array(ranked.hits.prefix(10)))
        XCTAssertFalse(top.contains("92:15"))
        XCTAssertFalse(top.contains("17:18"))
        XCTAssertTrue(refs(ranked.hits).contains("2:3"))
    }

    /// Q8: an en or em dash is a word break, so words it joins neither glue nor match across it.
    func testDashIsAWordBreak() {
        XCTAssertEqual(Settings.shared.cleanSearch("forefathers\u{2014}Abraham", whitespace: true), "forefathers abraham")
        XCTAssertEqual(Settings.shared.cleanSearch("2020\u{2013}24", whitespace: true), "2020 24")
        XCTAssertEqual(Settings.shared.cleanSearch("All-Knowing", whitespace: true), "allknowing")
    }

    /// The spellings helper itself: the seats go (a word-initial alef keeps its hamza seat), the final
    /// ya and alef maqsura swap, and a word with nothing to change has no other spelling.
    func testArabicQuerySpellings() {
        // شيئا -> شيا
        XCTAssertTrue(SearchFoldTables.arabicQuerySpellings(of: "\u{0634}\u{064A}\u{0626}\u{0627}")
            .contains("\u{0634}\u{064A}\u{0627}"))
        // أسألك keeps its first أ: أسلك
        XCTAssertTrue(SearchFoldTables.arabicQuerySpellings(of: "\u{0623}\u{0633}\u{0623}\u{0644}\u{0643}")
            .contains("\u{0623}\u{0633}\u{0644}\u{0643}"))
        // موسي -> موسى
        XCTAssertTrue(SearchFoldTables.arabicQuerySpellings(of: "\u{0645}\u{0648}\u{0633}\u{064A}")
            .contains("\u{0645}\u{0648}\u{0633}\u{0649}"))
        // كتب
        XCTAssertEqual(SearchFoldTables.arabicQuerySpellings(of: "\u{0643}\u{062A}\u{0628}"), [])
        XCTAssertEqual(SearchFoldTables.arabicQuerySpellings(of: "mercy"), [])
    }
}
