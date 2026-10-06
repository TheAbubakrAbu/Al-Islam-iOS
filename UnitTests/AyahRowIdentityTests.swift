import XCTest
@testable import iPhone

/// The reading list's row identity.
///
/// `SurahView` swaps the displayed surah IN PLACE (`swappedSurah`) rather than pushing a new reader,
/// so one `ForEach` outlives the swap. If its rows are keyed on `Ayah.id` - the ayah's number within
/// its own surah - the old and new surahs hand it identical identities, SwiftUI diffs zero changes
/// and REUSES the existing rows instead of rebuilding them. Rows off-screen across the swap then keep
/// the previous surah's Arabic under the new surah's numbering (reported 2026-10-05: An-Nas 114:5's
/// header and translation sitting over Al-Falaq 113:5's text).
final class AyahRowIdentityTests: XCTestCase {

    /// The collision the defect rested on: `Ayah.id` alone is NOT unique across surahs.
    @MainActor
    func testAyahIDAloneCollidesAcrossSurahs() async {
        let data = QuranData.shared
        await data.waitUntilLoaded()

        guard let falaq = data.quran.first(where: { $0.id == 113 }),
              let nas = data.quran.first(where: { $0.id == 114 }) else {
            return XCTFail("Al-Falaq and An-Nas must both load")
        }

        let falaqIDs = Set(falaq.ayahs.map(\.id))
        let nasIDs = Set(nas.ayahs.map(\.id))
        XCTAssertFalse(falaqIDs.isDisjoint(with: nasIDs),
                       "Precondition: bare ayah numbers are expected to repeat across surahs")
    }

    /// The fix: qualifying by surah makes the identity unique, so an in-place swap is a full
    /// replacement (every old key deleted, every new key inserted) rather than a silent reuse.
    @MainActor
    func testAyahKeyIsUniqueAcrossTheWholeQuran() async {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        XCTAssertFalse(data.quran.isEmpty, "The Quran must load")

        var seen = Set<String>()
        for surah in data.quran {
            for ayah in surah.ayahs {
                let key = surah.ayahKey(ayah.id)
                XCTAssertTrue(seen.insert(key).inserted,
                              "Duplicate row identity \(key) - rows would be reused across surahs")
            }
        }
    }

    /// A swap between two surahs shares no identity at all, which is what forces the rebuild.
    @MainActor
    func testSwapSharesNoIdentityBetweenSurahs() async {
        let data = QuranData.shared
        await data.waitUntilLoaded()

        guard let falaq = data.quran.first(where: { $0.id == 113 }),
              let nas = data.quran.first(where: { $0.id == 114 }) else {
            return XCTFail("Al-Falaq and An-Nas must both load")
        }

        let before = Set(falaq.ayahs.map { falaq.ayahKey($0.id) })
        let after = Set(nas.ayahs.map { nas.ayahKey($0.id) })
        XCTAssertTrue(before.isDisjoint(with: after),
                      "A surah swap must share no row identity, or SwiftUI reuses the old rows")
    }
}
