import XCTest
@testable import iPhone

/// `SearchRank`: the order of the rows a list search already matched. It may never add or drop a row.
final class SearchRankTests: XCTestCase {

    private func order(_ names: [String], for query: String) -> [String] {
        SearchRank.sorted(names, by: query) { [$0] }
    }

    func testTheNameItselfLeads() {
        XCTAssertEqual(order(["Al-Anbiya", "Maryam", "Ya-Sin", "Al-Ahqaf"], for: "ya").first, "Ya-Sin")
        XCTAssertEqual(order(["Al-Mu'minun", "An-Nur", "Nuh", "Al-Munafiqun"], for: "nuh").first, "Nuh")
        XCTAssertEqual(order(["Ali 'Imran", "Al-Isra", "Al-Mulk"], for: "al mulk").first, "Al-Mulk")
    }

    func testAnArticleIsNotPartOfTheName() {
        // "fat" starts the names of all three, article or none: the order they came in holds.
        XCTAssertEqual(order(["Al-Fatihah", "Fatir", "Al-Fath"], for: "fat"), ["Al-Fatihah", "Fatir", "Al-Fath"])
        // The whole name beats a name that merely starts with it.
        XCTAssertEqual(order(["Al-Fatihah", "Fatir", "Al-Fath"], for: "fath").first, "Al-Fath")
        XCTAssertEqual(order(["النور", "نوح", "المنافقون"], for: "نور").first, "النور")
    }

    func testTiersInOrder() {
        let names = ["Morning prayer of the traveller", "The prayer", "Prayer", "Prayers at night", "Before sleeping"]
        // "The prayer" IS the name (an article is not part of it), so it ties with "Prayer" and the
        // two keep the order they came in.
        XCTAssertEqual(order(names, for: "prayer"),
                       ["The prayer", "Prayer", "Prayers at night", "Morning prayer of the traveller", "Before sleeping"])
    }

    func testSeveralWords() {
        let names = ["Rights of the neighbour", "Neighbour rights", "The neighbour", "Rights"]
        let ranked = order(names, for: "neighbour rights")
        XCTAssertEqual(ranked.first, "Neighbour rights")
        XCTAssertEqual(ranked[1], "Rights of the neighbour")
    }

    func testAccentsCaseAndJoinersFold() {
        XCTAssertEqual(order(["Sunan Abi Dawud", "Ṣaḥīḥ al-Bukhārī"], for: "sahih al bukhari").first, "Ṣaḥīḥ al-Bukhārī")
        XCTAssertEqual(order(["Night", "AL-LAYL"], for: "al-layl").first, "AL-LAYL")
    }

    func testSecondaryNamesCountForLess() {
        struct Row { let title: String; let subtitle: String }
        let rows = [Row(title: "Morning", subtitle: "Patience"), Row(title: "Patience", subtitle: "Evening")]
        XCTAssertEqual(SearchRank.sorted(rows, by: "patience") { [$0.title, $0.subtitle] }.first?.title, "Patience")
    }

    /// The contract every call site relies on: the same rows come back, and ties keep their order.
    func testNothingIsAddedOrDropped() {
        let names = ["Zakah", "Hajj", "Fasting", "Prayer", "Faith"]
        for query in ["", "   ", "zzz", "a", "fa", "prayer", "حج"] {
            let ranked = order(names, for: query)
            XCTAssertEqual(ranked.sorted(), names.sorted(), query)
        }
        XCTAssertEqual(order(names, for: "zzz"), names)
        XCTAssertEqual(order(names, for: ""), names)
        XCTAssertEqual(order(["Fasting", "Faith"], for: "fa"), ["Fasting", "Faith"])
    }
}
