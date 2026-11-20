import XCTest
@testable import iPhone

/// Recitation speed (RecitationSpeed.swift; a reader's request, 2026-11-19): the speeds on offer, the
/// one a stored value resolves to, how a speed is written, and what the player does with it.
final class RecitationSpeedTests: XCTestCase {
    private var savedSpeed: Double = 1

    override func setUp() {
        super.setUp()
        savedSpeed = Settings.shared.recitationSpeed
    }

    override func tearDown() {
        Settings.shared.recitationSpeed = savedSpeed
        super.tearDown()
    }

    // MARK: The speeds

    func testTheReadersSpeedsAreAllOffered() {
        // "0.5x, 0.75x, 1.0x, 1.5x, 1.75x, 2.0x", and 1.25 between the two most used.
        XCTAssertEqual(RecitationSpeed.all, [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2])
        XCTAssertEqual(RecitationSpeed.all, RecitationSpeed.all.sorted(), "slowest first, as the menu lists them")
        XCTAssertTrue(RecitationSpeed.all.contains(RecitationSpeed.normal))
    }

    func testAStoredValueResolvesToTheNearestOfferedSpeed() {
        for speed in RecitationSpeed.all {
            XCTAssertEqual(RecitationSpeed.nearest(to: speed), speed)
        }
        XCTAssertEqual(RecitationSpeed.nearest(to: 1.3), 1.25)
        XCTAssertEqual(RecitationSpeed.nearest(to: 0.1), 0.5, "nothing slower than the slowest")
        XCTAssertEqual(RecitationSpeed.nearest(to: 16), 2, "nothing faster than the fastest")
    }

    func testAValueNoPlayerCouldTakeIsNormalSpeed() {
        XCTAssertEqual(RecitationSpeed.nearest(to: 0), 1, "a rate of 0 is a pause, never a speed")
        XCTAssertEqual(RecitationSpeed.nearest(to: -2), 1)
        XCTAssertEqual(RecitationSpeed.nearest(to: .nan), 1)
        XCTAssertEqual(RecitationSpeed.nearest(to: .infinity), 1)
    }

    func testASpeedIsWrittenWithoutTrailingZeros() {
        XCTAssertEqual(RecitationSpeed.label(1), "1\u{00D7}")
        XCTAssertEqual(RecitationSpeed.label(2), "2\u{00D7}")
        XCTAssertEqual(RecitationSpeed.label(0.5), "0.5\u{00D7}")
        XCTAssertEqual(RecitationSpeed.label(0.75), "0.75\u{00D7}")
        XCTAssertEqual(RecitationSpeed.label(1.25), "1.25\u{00D7}")
    }

    // MARK: The player

    func testThePlayerRecitesAtTheStoredSpeed() {
        Settings.shared.recitationSpeed = 1.5
        XCTAssertEqual(QuranPlayer.shared.recitationRate, 1.5)
        Settings.shared.recitationSpeed = 1
        XCTAssertEqual(QuranPlayer.shared.recitationRate, 1)
    }

    func testAStoredValueOffTheListNeverReachesThePlayerRaw() {
        Settings.shared.recitationSpeed = 0
        XCTAssertEqual(QuranPlayer.shared.recitationRate, 1, "a stored 0 would start every recitation paused")
        Settings.shared.recitationSpeed = 9
        XCTAssertEqual(QuranPlayer.shared.recitationRate, 2)
    }

    func testChoosingASpeedStoresTheOfferedOne() {
        QuranPlayer.shared.setRecitationSpeed(1.74)
        XCTAssertEqual(Settings.shared.recitationSpeed, 1.75)
        QuranPlayer.shared.setRecitationSpeed(1)
        XCTAssertEqual(Settings.shared.recitationSpeed, 1)
    }

    func testTheNextSurahIsReadiedSoonerAtAFasterSpeed() {
        // Ten seconds of AUDIO are five seconds on the clock at 2×: the lead is kept in clock time.
        XCTAssertEqual(QuranPlayer.prewarmLead(10, rate: 2), 20)
        XCTAssertEqual(QuranPlayer.prewarmLead(10, rate: 1), 10)
        XCTAssertEqual(QuranPlayer.prewarmLead(10, rate: 0.5), 10, "never later than it was at normal speed")
    }
}
