import XCTest
@testable import iPhone

/// The two juz tables: `QuranData.juzList` (Juz tab, filter chips) and the pack's per-ayah `juz`
/// (reader dividers, "juz N" jump). They must agree on all thirty (mirrors `-auditJuzTables`).
final class JuzTableTests: XCTestCase {

    private typealias Ref = (surah: Int, ayah: Int)

    /// The first and last ayah of each juz as the pack assigns them, over the Hafs ayahs (the
    /// slots only other counts have carry no Hafs text and no juz; `-auditJuzTables` skips them too).
    @MainActor
    private func packRanges() async -> (start: [Int: Ref], end: [Int: Ref], unassigned: Int, hafsAyahs: Int) {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        var start: [Int: Ref] = [:], end: [Int: Ref] = [:]
        var unassigned = 0, hafsAyahs = 0
        for surah in data.quran {
            for ayah in surah.ayahs where !ayah.textHafs.isEmpty {
                hafsAyahs += 1
                guard let juz = ayah.juz else { unassigned += 1; continue }
                if start[juz] == nil { start[juz] = (surah.id, ayah.id) }
                end[juz] = (surah.id, ayah.id)
            }
        }
        return (start, end, unassigned, hafsAyahs)
    }

    /// A4: every one of the 30 juz starts and ends at the same ayah in both tables.
    @MainActor
    func testJuzListAgreesWithThePack() async {
        let pack = await packRanges()
        XCTAssertEqual(QuranData.shared.quran.count, 114, "the Quran did not load")
        XCTAssertEqual(pack.hafsAyahs, 6236)
        XCTAssertEqual(pack.unassigned, 0, "Hafs ayahs with no juz in the pack")
        XCTAssertEqual(QuranData.juzList.map(\.id), Array(1...30))
        XCTAssertEqual(Set(pack.start.keys), Set(1...30))
        for juz in QuranData.juzList {
            let start = pack.start[juz.id], end = pack.end[juz.id]
            XCTAssertEqual(start?.surah, juz.startSurah, "juz \(juz.id) start surah")
            XCTAssertEqual(start?.ayah, juz.startAyah, "juz \(juz.id) start ayah")
            XCTAssertEqual(end?.surah, juz.endSurah, "juz \(juz.id) end surah")
            XCTAssertEqual(end?.ayah, juz.endAyah, "juz \(juz.id) end ayah")
        }
    }

    /// A4: the pack's juz never goes backwards or skips a number through the mushaf.
    @MainActor
    func testPackJuzIsMonotonic() async {
        _ = await packRanges()
        var previous = 1
        for surah in QuranData.shared.quran {
            for ayah in surah.ayahs where !ayah.textHafs.isEmpty {
                guard let juz = ayah.juz else { continue }
                XCTAssertTrue(juz == previous || juz == previous + 1, "\(surah.id):\(ayah.id) juz \(juz) after \(previous)")
                previous = juz
            }
        }
        XCTAssertEqual(previous, 30)
    }

    /// A4: the decided boundaries (2026-09-29): juz 4 opens at 3:93 and juz 11 at 9:93, the printed mushaf's marks.
    @MainActor
    func testDecidedBoundariesJuz4AndJuz11() async throws {
        let pack = await packRanges()
        let juz4 = try XCTUnwrap(QuranData.juzList.first { $0.id == 4 })
        let juz11 = try XCTUnwrap(QuranData.juzList.first { $0.id == 11 })
        XCTAssertEqual([juz4.startSurah, juz4.startAyah], [3, 93])
        XCTAssertEqual([juz11.startSurah, juz11.startAyah], [9, 93])
        XCTAssertEqual(pack.start[4].map { [$0.surah, $0.ayah] }, [3, 93])
        XCTAssertEqual(pack.start[11].map { [$0.surah, $0.ayah] }, [9, 93])
        XCTAssertEqual(QuranData.shared.ayah(surah: 3, ayah: 92)?.juz, 3)
        XCTAssertEqual(QuranData.shared.ayah(surah: 9, ayah: 92)?.juz, 10)
    }

    /// A4: consecutive juz in `juzList` leave no gap and no overlap.
    func testJuzListIsContiguous() {
        let list = QuranData.juzList
        XCTAssertEqual([list.first?.startSurah, list.first?.startAyah], [1, 1])
        XCTAssertEqual([list.last?.endSurah, list.last?.endAyah], [114, 6])
        for (a, b) in zip(list, list.dropFirst()) {
            if a.endSurah == b.startSurah {
                XCTAssertEqual(b.startAyah, a.endAyah + 1, "juz \(a.id) to \(b.id)")
            } else {
                XCTAssertEqual(b.startSurah, a.endSurah + 1, "juz \(a.id) to \(b.id)")
                XCTAssertEqual(b.startAyah, 1, "juz \(b.id) must open a surah")
            }
        }
    }

    /// A4: hizb 2k-1 in QuranMetadata.json opens where juz k opens (hizbs 7 and 21 moved with juz 4 and 11).
    func testOddHizbsOpenWithTheirJuz() throws {
        guard QuranMetadata.isBundled else { throw XCTSkip("QuranMetadata.json is not bundled") }
        XCTAssertEqual(QuranMetadata.count(of: .hizb), 60)
        for juz in QuranData.juzList {
            let hizb = try XCTUnwrap(QuranMetadata.range(of: .hizb, number: juz.id * 2 - 1), "hizb \(juz.id * 2 - 1)")
            XCTAssertEqual(hizb.start.surah, juz.startSurah, "hizb \(juz.id * 2 - 1) vs juz \(juz.id)")
            XCTAssertEqual(hizb.start.ayah, juz.startAyah, "hizb \(juz.id * 2 - 1) vs juz \(juz.id)")
        }
    }
}
