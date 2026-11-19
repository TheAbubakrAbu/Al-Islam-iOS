import XCTest
@testable import iPhone

/// The ayah actions sheet's tile rows.
///
/// The tiles sit three across in the menus' own groups (mark, study, play, text). Which tiles exist
/// depends on the riwayah, the bundled packs and Apple Intelligence, so a group's count moves, and a
/// plain three-column grid left the last tile alone beside two empty cells (Abu, 2026-11-18: "long
/// hold ayah has copy ayah on its own row which is ugly"). `AyahActionLayout` decides the rows so
/// that never happens: every row is full width, and no tile stands alone while it has neighbours.
final class AyahActionLayoutTests: XCTestCase {

    func testFullRowsStayThreeAcross() {
        XCTAssertEqual(AyahActionLayout.rowSizes(count: 3), [3])
        XCTAssertEqual(AyahActionLayout.rowSizes(count: 6), [3, 3])
        XCTAssertEqual(AyahActionLayout.rowSizes(count: 9), [3, 3, 3])
    }

    /// Two left over share the last row as halves.
    func testTwoLeftOverShareTheLastRow() {
        XCTAssertEqual(AyahActionLayout.rowSizes(count: 2), [2])
        XCTAssertEqual(AyahActionLayout.rowSizes(count: 5), [3, 2])
        XCTAssertEqual(AyahActionLayout.rowSizes(count: 8), [3, 3, 2])
    }

    /// One left over takes a tile from the row above: two rows of two, never three and one.
    func testOneLeftOverBorrowsFromTheRowAbove() {
        XCTAssertEqual(AyahActionLayout.rowSizes(count: 4), [2, 2])
        XCTAssertEqual(AyahActionLayout.rowSizes(count: 7), [3, 2, 2])
        XCTAssertEqual(AyahActionLayout.rowSizes(count: 10), [3, 3, 2, 2])
    }

    func testNothingAndOne() {
        XCTAssertEqual(AyahActionLayout.rowSizes(count: 0), [])
        XCTAssertEqual(AyahActionLayout.rowSizes(count: 1), [1])
    }

    /// The rule as a whole: every tile is placed, no row is wider than three, and from two tiles up
    /// no row holds a single tile.
    func testNoCountLeavesATileAlone() {
        for count in 2...40 {
            let rows = AyahActionLayout.rowSizes(count: count)
            XCTAssertEqual(rows.reduce(0, +), count, "\(count) tiles: some were dropped or repeated")
            XCTAssertFalse(rows.contains(1), "\(count) tiles: a tile sits alone in \(rows)")
            XCTAssertTrue(rows.allSatisfy { (2...3).contains($0) }, "\(count) tiles: a row is too wide in \(rows)")
        }
    }

    /// A group that comes out with one tile (another riwayah on display leaves the study group with
    /// Apply Settings only) joins the group before it, so its tile has neighbours.
    func testAGroupOfOneJoinsTheGroupBeforeIt() {
        let groups = AyahActionLayout.merged([["bookmark", "highlight", "note"], ["settings"], ["select", "copy"]])
        XCTAssertEqual(groups, [["bookmark", "highlight", "note", "settings"], ["select", "copy"]])
    }

    /// With no group before it, it joins the one after.
    func testALeadingGroupOfOneJoinsTheNext() {
        let groups = AyahActionLayout.merged([["only"], ["a", "b", "c"]])
        XCTAssertEqual(groups, [["only", "a", "b", "c"]])
    }

    func testEmptyGroupsAreDropped() {
        let groups = AyahActionLayout.merged([["a", "b", "c"], [], ["d", "e"]])
        XCTAssertEqual(groups, [["a", "b", "c"], ["d", "e"]])
    }

    /// A single group of one has nowhere to go and stays.
    func testALoneGroupOfOneStays() {
        XCTAssertEqual(AyahActionLayout.merged([["only"]]), [["only"]])
        XCTAssertEqual(AyahActionLayout.merged([[String]]()), [])
    }

    /// Splitting a group's tiles into its rows keeps their order.
    func testRowsKeepTheTilesInOrder() {
        XCTAssertEqual(AyahActionLayout.rows(of: ["a", "b", "c", "d", "e"]), [["a", "b", "c"], ["d", "e"]])
        XCTAssertEqual(AyahActionLayout.rows(of: ["a", "b", "c", "d"]), [["a", "b"], ["c", "d"]])
        XCTAssertEqual(AyahActionLayout.rows(of: [String]()), [])
    }
}
