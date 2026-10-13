import XCTest
@testable import iPhone

/// The Quran Planner's Revision plan (2026-10-12): the set, the daily portion and the cycle.
@MainActor
final class QuranRevisionPlanTests: XCTestCase {
    private var savedPlanData = Data()
    private var savedRevisedData = Data()

    override func setUp() async throws {
        try await super.setUp()
        await QuranData.shared.waitUntilLoaded()
        let settings = Settings.shared
        savedPlanData = settings.quranRevisionPlanData
        savedRevisedData = settings.quranRevisionRevisedData
        settings.quranRevisionPlan = nil
        settings.resetRevisionProgress()
    }

    override func tearDown() async throws {
        let settings = Settings.shared
        settings.quranRevisionPlan = nil
        settings.resetRevisionProgress()
        settings.quranRevisionPlanData = savedPlanData
        settings.quranRevisionRevisedData = savedRevisedData
        settings.revisionCacheLoaded = false
        try await super.tearDown()
    }

    private func plan(scope: QuranRevisionPlan.Scope, cycleDays: Int, startedDaysAgo: Int = 0) -> QuranRevisionPlan {
        let start = Calendar.current.date(byAdding: .day, value: -startedDaysAgo, to: Calendar.current.startOfDay(for: Date()))!
        return QuranRevisionPlan(scope: scope, cycleDays: cycleDays, startDate: start, cycleStartDate: start,
                                 cyclesCompleted: 0, dayKey: QuranPlan.dayKey(for: Date()), dayStartRevised: 0,
                                 carriedToday: 0, history: [:])
    }

    /// Juz 30 is 564 ayahs over 23 pages; juz 29 adds 431; chosen surahs take whole surahs in mushaf order.
    /// `Surah.ayahs` carries 50 riwayah-only slots with no Hafs text (112:5, 114:7), which no set counts.
    func testScopeEnumeratesTheSet() {
        let quran = QuranData.shared.quran
        XCTAssertEqual(QuranPlannerMath.totalAyahs(quran: quran), 6236, "the khatm total is the Hafs count")
        let juz30 = QuranRevisionMath.ayahs(in: .juzRange(from: 30, to: 30), quran: quran)
        XCTAssertEqual(juz30.count, 564)
        XCTAssertEqual(QuranRevisionMath.pageCount(of: juz30), 23)
        XCTAssertEqual(juz30.first.map { "\($0.surahID):\($0.ayahID)" }, "78:1")
        XCTAssertEqual(juz30.last.map { "\($0.surahID):\($0.ayahID)" }, "114:6")

        XCTAssertEqual(QuranRevisionMath.ayahs(in: .juzRange(from: 29, to: 30), quran: quran).count, 564 + 431)

        let picked = QuranRevisionMath.ayahs(in: .surahs([114, 1, 112]), quran: quran)
        XCTAssertEqual(picked.count, 7 + 4 + 6)
        XCTAssertEqual(picked.map(\.surahID).first, 1)
        XCTAssertEqual(picked.map(\.surahID).last, 114)

        XCTAssertTrue(QuranRevisionMath.scope(.juzRange(from: 30, to: 30), contains: 78, ayah: 1))
        XCTAssertFalse(QuranRevisionMath.scope(.juzRange(from: 30, to: 30), contains: 77, ayah: 50))
        XCTAssertTrue(QuranRevisionMath.scope(.surahs([1, 112]), contains: 112, ayah: 4))
        XCTAssertFalse(QuranRevisionMath.scope(.surahs([1, 112]), contains: 113, ayah: 1))
    }

    /// Day 1 of a 7-day cycle over 564 ayahs asks for 81; with 300 left and 2 days to go it asks for
    /// 150; a cycle past its length asks for everything left.
    func testTodayTargetSpreadsWhatIsLeft() {
        let fresh = plan(scope: .juzRange(from: 30, to: 30), cycleDays: 7)
        XCTAssertEqual(fresh.daysLeftInCycle(), 7)
        XCTAssertEqual(QuranRevisionMath.todayTarget(plan: fresh, scopeCount: 564, dayStartRevised: 0), 81)

        let lateCycle = plan(scope: .juzRange(from: 30, to: 30), cycleDays: 7, startedDaysAgo: 5)
        XCTAssertEqual(lateCycle.daysLeftInCycle(), 2)
        XCTAssertEqual(QuranRevisionMath.todayTarget(plan: lateCycle, scopeCount: 564, dayStartRevised: 264), 150)

        let overdue = plan(scope: .juzRange(from: 30, to: 30), cycleDays: 7, startedDaysAgo: 9)
        XCTAssertEqual(overdue.daysLeftInCycle(), 1)
        XCTAssertEqual(overdue.daysOverdue(), 3)
        XCTAssertEqual(QuranRevisionMath.todayTarget(plan: overdue, scopeCount: 564, dayStartRevised: 500), 64)
        XCTAssertEqual(QuranRevisionMath.todayTarget(plan: overdue, scopeCount: 564, dayStartRevised: 564), 0)
    }

    /// Reading an ayah of the set marks it; one outside the set does nothing; settling after the
    /// whole set is revised closes the cycle (count +1, set emptied, today's count carried).
    func testReadingMarksAndAFullSetClosesTheCycle() {
        let settings = Settings.shared
        let quran = QuranData.shared.quran
        settings.quranRevisionPlan = plan(scope: .surahs([112, 113]), cycleDays: 3)

        settings.noteRevisionAyahRead(surah: 112, ayah: 1)
        settings.noteRevisionAyahRead(surah: 2, ayah: 1)
        XCTAssertTrue(settings.isRevisionAyahRevised(surah: 112, ayah: 1))
        XCTAssertFalse(settings.isRevisionAyahRevised(surah: 2, ayah: 1))
        XCTAssertEqual(settings.revisionRevisedCount, 1)

        let refs = QuranRevisionMath.ayahs(in: .surahs([112, 113]), quran: quran)
        XCTAssertEqual(refs.count, 9)
        let span = QuranRevisionMath.todaySpan(refs: refs, scope: .surahs([112, 113]), settings: settings, count: 3)
        XCTAssertEqual(span?.startAyah, 2, "the span starts at the first unrevised ayah")
        XCTAssertEqual(span?.endAyah, 4)

        settings.settleQuranRevisionPlan(quran: quran)
        XCTAssertEqual(settings.quranRevisionPlan?.cyclesCompleted, 0, "a part-revised set keeps the cycle open")

        QuranRevisionMath.markNextUnrevisedAyahs(refs: refs, settings: settings, count: 8)
        XCTAssertEqual(settings.revisionRevisedCount, 9)
        settings.settleQuranRevisionPlan(quran: quran)
        let closed = settings.quranRevisionPlan
        XCTAssertEqual(closed?.cyclesCompleted, 1)
        XCTAssertEqual(settings.revisionRevisedCount, 0, "the next cycle starts from the top")
        XCTAssertEqual(closed.map { QuranRevisionMath.doneToday(plan: $0, revisedCount: 0) }, 9, "today's count survives the reset")
        XCTAssertEqual(closed?.dayStartRevised, 0)
    }

    /// Adjusting the set mid-cycle keeps the marks still inside it and drops the rest.
    func testAdjustingTheScopePrunesMarks() {
        let settings = Settings.shared
        settings.quranRevisionPlan = plan(scope: .surahs([112, 113, 114]), cycleDays: 7)
        settings.markRevisionAyahRevised(surah: 112, ayah: 1, immediate: true)
        settings.markRevisionAyahRevised(surah: 114, ayah: 1, immediate: true)
        XCTAssertEqual(settings.revisionRevisedCount, 2)

        settings.pruneRevisionProgress(to: .surahs([112, 113]))
        XCTAssertEqual(settings.revisionRevisedCount, 1)
        XCTAssertTrue(settings.isRevisionAyahRevised(surah: 112, ayah: 1))
        XCTAssertFalse(settings.isRevisionAyahRevised(surah: 114, ayah: 1))
    }

    /// The plan round-trips through its stored blob, the scope enum included.
    func testPlanPersistsAsAWhole() throws {
        let settings = Settings.shared
        let original = plan(scope: .juzRange(from: 28, to: 30), cycleDays: 14)
        settings.quranRevisionPlan = original
        let data = settings.quranRevisionPlanData
        XCTAssertFalse(data.isEmpty)
        let decoded = try Settings.decoder.decode(QuranRevisionPlan.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(QuranRevisionMath.scopeLabel(decoded.scope, quran: QuranData.shared.quran), "Juz 28 to 30")
    }

    /// A restore or a merge writes the revised set's bytes behind the cache (`storedContentWasReplaced`):
    /// the cache reloads from them, and a debounced save that was still pending is dropped rather than
    /// landed over the restored bytes (the khatm set behaves the same on that path).
    func testReplacedStoredBytesReloadTheRevisedSet() async throws {
        let settings = Settings.shared
        settings.quranRevisionPlan = plan(scope: .surahs([112, 113, 114]), cycleDays: 7)
        settings.markRevisionAyahRevised(surah: 112, ayah: 1)   // debounced: a save is pending
        settings.markRevisionAyahRevised(surah: 112, ayah: 2)
        XCTAssertEqual(settings.revisionRevisedCount, 2)
        XCTAssertNotNil(settings.revisionSaveTask, "the automatic marks ride the debounce")

        let restored = [Settings.revisionKey(surah: 114, ayah: 1), Settings.revisionKey(surah: 114, ayah: 2),
                        Settings.revisionKey(surah: 114, ayah: 3)]
        settings.quranRevisionRevisedData = try Settings.encoder.encode(restored)
        settings.reloadRevisionProgressCacheFromStorage()

        XCTAssertEqual(settings.revisionRevisedCount, 3)
        XCTAssertTrue(settings.isRevisionAyahRevised(surah: 114, ayah: 3))
        XCTAssertFalse(settings.isRevisionAyahRevised(surah: 112, ayah: 1), "the stale in-memory set is gone")
        XCTAssertNil(settings.revisionSaveTask, "the pending save was dropped")

        try await Task.sleep(nanoseconds: 1_400_000_000)   // past the debounce on either tier
        let stored = try Settings.decoder.decode([Int].self, from: settings.quranRevisionRevisedData)
        XCTAssertEqual(Set(stored), Set(restored), "nothing wrote the stale set back over the restored bytes")
    }

    /// "Mark as Revised" with fewer ayahs left than the day asks for: the batch still publishes at
    /// once (the LAST mark of the batch is the immediate one, not the count-th).
    func testBatchMarkWithFewerLeftThanAskedPublishesAtOnce() {
        let settings = Settings.shared
        let quran = QuranData.shared.quran
        settings.quranRevisionPlan = plan(scope: .surahs([112]), cycleDays: 7)
        let refs = QuranRevisionMath.ayahs(in: .surahs([112]), quran: quran)
        XCTAssertEqual(refs.count, 4)
        settings.markRevisionAyahRevised(surah: 112, ayah: 1, immediate: true)
        settings.markRevisionAyahRevised(surah: 112, ayah: 2, immediate: true)

        var publishes = 0
        let sink = settings.objectWillChange.sink { _ in publishes += 1 }
        QuranRevisionMath.markNextUnrevisedAyahs(refs: refs, settings: settings, count: 10)
        sink.cancel()

        XCTAssertEqual(settings.revisionRevisedCount, 4)
        XCTAssertEqual(publishes, 1, "the last of the two marks that were left published immediately")

        publishes = 0
        let again = settings.objectWillChange.sink { _ in publishes += 1 }
        QuranRevisionMath.markNextUnrevisedAyahs(refs: refs, settings: settings, count: 10)
        again.cancel()
        XCTAssertEqual(publishes, 0, "nothing left to mark, nothing published")
    }
}
