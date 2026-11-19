import XCTest
@testable import iPhone

/// The Chosen Ayah widget's rotating feeds (2026-11-17). The extension draws its timeline from
/// `ChosenAyahPlan.schedule` and the app pre-renders the same picks, so the schedule must be a pure
/// function: the same answer in both processes, on every launch.
final class ChosenAyahScheduleTests: XCTestCase {
    private let pool = (1...50).map { ChosenAyahRef(surah: 2, ayah: $0) }

    func testAShuffledRoundShowsEveryAyahOnce() {
        // Slots 1000..<1050 are exactly one round of a 50-ayah pool.
        let picks = ChosenAyahSchedule.picks(from: pool, slots: Array(1000..<1050), shuffled: true, seed: 42)
        XCTAssertEqual(Set(picks).count, pool.count)
    }

    func testPicksAreTheSameEveryTime() {
        let slots = Array(500..<530)
        let first = ChosenAyahSchedule.picks(from: pool, slots: slots, shuffled: true, seed: ChosenAyahSchedule.seed("anyAyah|hour"))
        let again = ChosenAyahSchedule.picks(from: pool, slots: slots, shuffled: true, seed: ChosenAyahSchedule.seed("anyAyah|hour"))
        XCTAssertEqual(first, again)
        let otherFeed = ChosenAyahSchedule.picks(from: pool, slots: slots, shuffled: true, seed: ChosenAyahSchedule.seed("bookmarks|hour"))
        XCTAssertNotEqual(first, otherFeed)
    }

    func testTheSeedIsNotProcessSeeded() {
        // FNV-1a of "a": a fixed number, unlike `Hasher`, which changes per launch.
        XCTAssertEqual(ChosenAyahSchedule.seed("a"), 0xAF63_DC4C_8601_EC8C)
    }

    func testAListTakesTurnsInItsOwnOrder() {
        let list = Array(pool.prefix(3))
        let picks = ChosenAyahSchedule.picks(from: list, slots: [9, 10, 11, 12], shuffled: false, seed: 0)
        XCTAssertEqual(picks, [list[0], list[1], list[2], list[0]])
    }

    func testHourSlotsTurnOnTheHour() throws {
        var calendar = Calendar.current
        calendar.timeZone = .current
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 17, hour: 10, minute: 37)))
        let slots = ChosenAyahSchedule.slots(from: date, count: 3, step: .hour, fajrByDay: nil)
        XCTAssertEqual(slots.count, 3)
        XCTAssertEqual(slots[0].start, date, "the first entry is dated now")
        XCTAssertEqual(calendar.component(.hour, from: slots[1].start), 11)
        XCTAssertEqual(calendar.component(.minute, from: slots[1].start), 0)
        XCTAssertEqual(calendar.component(.hour, from: slots[2].start), 12)
        XCTAssertEqual(slots[1].index, slots[0].index + 1)
        XCTAssertEqual(slots[2].index, slots[1].index + 1)
    }

    func testQuarterHourSlotsTurnEveryFifteenMinutes() throws {
        let calendar = Calendar.current
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 17, hour: 10, minute: 37, second: 20)))
        let slots = ChosenAyahSchedule.slots(from: date, count: 3, step: .quarterHour, fajrByDay: nil)
        XCTAssertEqual(calendar.component(.minute, from: slots[1].start), 45)
        XCTAssertEqual(calendar.component(.second, from: slots[1].start), 0)
        XCTAssertEqual(slots[2].start.timeIntervalSince(slots[1].start), 900)
    }

    func testOneAyahIsOneEntry() {
        let plan = ChosenAyahPlan(source: .oneAyah, step: .hour, chosen: ChosenAyahRef(surah: 36, ayah: 9), list: [])
        let schedule = plan.schedule(from: Date(), count: 12, snapshot: nil)
        XCTAssertEqual(schedule.count, 1)
        XCTAssertEqual(schedule.first?.ref, ChosenAyahRef(surah: 36, ayah: 9))
    }

    func testRandomAyahDrawsFromTheMirroredPool() {
        var snapshot = QuranWidgetSnapshot()
        snapshot.randomRefs = [2255, 94005, 94006, 112001]
        let plan = ChosenAyahPlan(source: .anyAyah, step: .hour, chosen: nil, list: [])
        let schedule = plan.schedule(from: Date(), count: 12, snapshot: snapshot)
        XCTAssertEqual(schedule.count, 12)
        let allowed: Set<ChosenAyahRef> = [ChosenAyahRef(surah: 2, ayah: 255), ChosenAyahRef(surah: 94, ayah: 5),
                                           ChosenAyahRef(surah: 94, ayah: 6), ChosenAyahRef(surah: 112, ayah: 1)]
        XCTAssertTrue(schedule.allSatisfy { allowed.contains($0.ref) })
    }

    func testRandomBookmarkWithNoBookmarksFallsBackToRandomAyahs() {
        var snapshot = QuranWidgetSnapshot()
        snapshot.bookmarks = []
        snapshot.randomRefs = [94005]
        let plan = ChosenAyahPlan(source: .bookmarks, step: .day, chosen: nil, list: [])
        let schedule = plan.schedule(from: Date(), count: 2, snapshot: snapshot)
        XCTAssertEqual(schedule.first?.ref, ChosenAyahRef(surah: 94, ayah: 5))
    }

    func testAnEmptyListShowsTheDefault() {
        let plan = ChosenAyahPlan(source: .myAyahs, step: .hour, chosen: nil, list: [])
        let schedule = plan.schedule(from: Date(), count: 12, snapshot: nil)
        XCTAssertEqual(schedule.count, 1)
        XCTAssertEqual(schedule.first?.ref, ChosenAyahRef(surah: 2, ayah: 255))
    }
}
