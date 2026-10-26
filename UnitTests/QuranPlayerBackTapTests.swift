import XCTest
@testable import iPhone

/// The back button's one rule (2026-10-23, "be consistent with going back and forward"): a lone tap
/// restarts what is playing, a second tap within 1.5 s goes back one, in every playback mode and from
/// Control Center. `QuranPlayer.consumeBackTap(at:)` is the counter every mode asks; each test ends on
/// a consumed pair so the shared player's counter is clean for the next.
final class QuranPlayerBackTapTests: XCTestCase {
    func testSecondTapWithinWindowGoesBackAndResets() {
        let player = QuranPlayer.shared
        let t0 = Date(timeIntervalSinceReferenceDate: 1_000_000)
        XCTAssertFalse(player.consumeBackTap(at: t0), "a lone tap restarts")
        XCTAssertTrue(player.consumeBackTap(at: t0.addingTimeInterval(1.0)), "a second tap within 1.5 s goes back")
        // The pair is consumed: the next tap is a first tap again, however soon it lands.
        XCTAssertFalse(player.consumeBackTap(at: t0.addingTimeInterval(1.1)), "after going back, the next tap restarts")
        XCTAssertTrue(player.consumeBackTap(at: t0.addingTimeInterval(1.2)))
    }

    func testTapOutsideWindowIsAFirstTapAgain() {
        let player = QuranPlayer.shared
        let t0 = Date(timeIntervalSinceReferenceDate: 2_000_000)
        XCTAssertFalse(player.consumeBackTap(at: t0))
        XCTAssertFalse(player.consumeBackTap(at: t0.addingTimeInterval(1.6)), "1.6 s later is a fresh first tap")
        XCTAssertTrue(player.consumeBackTap(at: t0.addingTimeInterval(1.6 + 1.4)), "and its own second tap goes back")
    }

    func testQuickDoubleTapGoesBack() {
        let player = QuranPlayer.shared
        let t0 = Date(timeIntervalSinceReferenceDate: 3_000_000)
        XCTAssertFalse(player.consumeBackTap(at: t0))
        // 0.15 s apart: the old ayah path ignored a second tap this soon, so a quick double tap only
        // restarted; the shared rule honours it, as the surah mode always did.
        XCTAssertTrue(player.consumeBackTap(at: t0.addingTimeInterval(0.15)))
    }
}
