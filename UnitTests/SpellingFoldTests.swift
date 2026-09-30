import XCTest
@testable import iPhone

/// `SpellingFold`, the forgiving-spelling fallback behind the surah, Names of Allah, reciter and article
/// title searches. The exact tiers are vowel-blind on purpose; the as-you-type tier reads vowels by
/// class (Abu, 2026-09-30: "musa" listed five surahs that have nothing to do with Musa).
final class SpellingFoldTests: XCTestCase {

    private func find(_ query: String, in names: [String]) -> [String] {
        SpellingFold.matches(query, in: names) { SpellingFold.Entry(names: [$0]) }
    }

    private let surahs = ["Al-Masad", "Al-Mulk", "Ar-Rahman", "Al-Kahf", "Ibrahim", "Al-Ikhlas", "Maryam",
                          "Al-Kawthar", "Al-Layl"]

    func testProphetNamesMatchNothingLoosely() {
        XCTAssertEqual(find("musa", in: surahs), [])
        XCTAssertEqual(find("mūsā", in: surahs), [])
        XCTAssertEqual(find("ayyub", in: ["Abu Lahab"]), [])
    }

    func testExactTiersStayVowelBlind() {
        XCTAssertEqual(find("rahmaan", in: surahs), ["Ar-Rahman"])
        XCTAssertEqual(find("rehman", in: surahs), ["Ar-Rahman"])
        XCTAssertEqual(find("meryem", in: surahs), ["Maryam"])
        XCTAssertEqual(find("kevser", in: surahs), ["Al-Kawthar"])
        XCTAssertEqual(find("lail", in: surahs), ["Al-Layl"])
    }

    func testHalfTypedNamesStillArrive() {
        XCTAssertEqual(find("masa", in: surahs), ["Al-Masad"])
        XCTAssertEqual(find("mol", in: surahs), ["Al-Mulk"])
        XCTAssertEqual(find("rehm", in: surahs), ["Ar-Rahman"])   // e reads as a
        XCTAssertEqual(find("ebra", in: surahs), ["Ibrahim"])     // e reads as i
        XCTAssertEqual(find("ekhl", in: surahs), ["Al-Ikhlas"])
        XCTAssertEqual(find("ikhl", in: surahs), ["Al-Ikhlas"])
    }

    /// A two-consonant skeleton still counts when the query is itself that short.
    func testShortSkeletonForShortQuery() {
        XCTAssertEqual(find("ab", in: ["Abu Lahab"]), ["Abu Lahab"])
    }
}
