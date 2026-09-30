import XCTest
@testable import iPhone

/// `Faraid.distribute`: textbook inheritance cases. Shares follow Quran 4:11, 4:12 and 4:176 and the
/// rules the code documents beside each step; the source is named on each case.
final class FaraidTests: XCTestCase {

    private func run(_ counts: [FaraidHeir: Int]) -> (result: Faraid.Result, share: [FaraidHeir: Fraction]) {
        let result = Faraid.distribute(counts: counts)
        var share: [FaraidHeir: Fraction] = [:]
        for award in result.awards { share[award.heir] = award.share }
        return (result, share)
    }

    private func total(_ result: Faraid.Result) -> Fraction {
        result.awards.reduce(result.unclaimed) { $0 + $1.share }
    }

    /// A12: wife, son and daughter: wife 1/8 (4:12, with a child), the rest 2:1 to son and daughter (4:11).
    func testWifeSonDaughter() {
        let (result, share) = run([.wives: 1, .sons: 1, .daughters: 1])
        XCTAssertEqual(share[.wives], Fraction(1, 8))
        XCTAssertEqual(share[.sons], Fraction(7, 12))
        XCTAssertEqual(share[.daughters], Fraction(7, 24))
        XCTAssertEqual(total(result), .one)
    }

    /// A12: husband, mother and one full brother: 1/2 (4:12), 1/3 (4:11, fewer than two siblings), residue 1/6.
    func testHusbandMotherFullBrother() {
        let (result, share) = run([.husband: 1, .mother: 1, .fullBrothers: 1])
        XCTAssertEqual(share[.husband], Fraction(1, 2))
        XCTAssertEqual(share[.mother], Fraction(1, 3))
        XCTAssertEqual(share[.fullBrothers], Fraction(1, 6))
        XCTAssertFalse(result.didAwl)
        XCTAssertFalse(result.didRadd)
    }

    /// A12: the first 'Umariyyah, husband and both parents: mother takes a third of what remains (1/6), father 1/3.
    func testUmariyyahWithHusband() {
        let (_, share) = run([.husband: 1, .mother: 1, .father: 1])
        XCTAssertEqual(share[.husband], Fraction(1, 2))
        XCTAssertEqual(share[.mother], Fraction(1, 6))
        XCTAssertEqual(share[.father], Fraction(1, 3))
    }

    /// A12: the second 'Umariyyah, wife and both parents: wife 1/4, mother 1/4 (a third of 3/4), father 1/2.
    func testUmariyyahWithWife() {
        let (_, share) = run([.wives: 1, .mother: 1, .father: 1])
        XCTAssertEqual(share[.wives], Fraction(1, 4))
        XCTAssertEqual(share[.mother], Fraction(1, 4))
        XCTAssertEqual(share[.father], Fraction(1, 2))
    }

    /// A12: the guide's case: daughter 1/2, full sister 1/2 as residuary with her, paternal half-brother excluded by the sister.
    func testDaughterFullSisterPaternalBrother() throws {
        let (result, share) = run([.daughters: 1, .fullSisters: 1, .paternalBrothers: 1])
        XCTAssertEqual(share[.daughters], Fraction(1, 2))
        XCTAssertEqual(share[.fullSisters], Fraction(1, 2))
        XCTAssertNil(share[.paternalBrothers])
        let reason = try XCTUnwrap(result.blocked.first { $0.heir == .paternalBrothers }?.reason)
        XCTAssertTrue(reason.contains("full sister"), reason)
        XCTAssertFalse(reason.contains("use up the whole estate"), reason)
    }

    /// A12: the same family with a paternal half-sister beside the half-brother: she too is excluded by the full sister, not by spent shares.
    func testDaughterFullSisterPaternalBrotherAndSister() throws {
        // The full sister beside a daughter stands in her brother's rank and "shuts out everyone her
        // brother would have" (the code's own comment); a full brother excludes the paternal half-sisters.
        let (result, share) = run([.daughters: 1, .fullSisters: 1, .paternalBrothers: 1, .paternalSisters: 1])
        XCTAssertEqual(share[.daughters], Fraction(1, 2))
        XCTAssertEqual(share[.fullSisters], Fraction(1, 2))
        XCTAssertNil(share[.paternalSisters])
        let reason = try XCTUnwrap(result.blocked.first { $0.heir == .paternalSisters }?.reason)
        XCTAssertTrue(reason.contains("full sister"), reason)
        XCTAssertFalse(reason.contains("use up the whole estate"), reason)
    }

    /// A12: 'awl, husband and two full sisters: 1/2 + 2/3 overflows, base 6 raised to 7 (3/7 and 4/7).
    func testAwlHusbandTwoFullSisters() throws {
        let (result, share) = run([.husband: 1, .fullSisters: 2])
        XCTAssertTrue(result.didAwl)
        XCTAssertEqual(share[.husband], Fraction(3, 7))
        XCTAssertEqual(share[.fullSisters], Fraction(4, 7))
        XCTAssertEqual(try XCTUnwrap(result.awards.first { $0.heir == .fullSisters }).each, Fraction(2, 7))
        XCTAssertEqual(total(result), .one)
    }

    /// A12: 'awl, husband, mother and full sister (al-Mubahalah): 1/2 + 1/3 + 1/2, base 6 raised to 8.
    func testAwlMubahalah() {
        let (result, share) = run([.husband: 1, .mother: 1, .fullSisters: 1])
        XCTAssertTrue(result.didAwl)
        XCTAssertEqual(share[.husband], Fraction(3, 8))
        XCTAssertEqual(share[.mother], Fraction(1, 4))
        XCTAssertEqual(share[.fullSisters], Fraction(3, 8))
    }

    /// A12: radd, mother and daughter: 1/6 and 1/2 with the surplus returned 1:3, so 1/4 and 3/4.
    func testRaddMotherDaughter() {
        let (result, share) = run([.mother: 1, .daughters: 1])
        XCTAssertTrue(result.didRadd)
        XCTAssertEqual(share[.mother], Fraction(1, 4))
        XCTAssertEqual(share[.daughters], Fraction(3, 4))
    }

    /// A12: radd skips the spouse: wife 1/8 stays, the daughter takes the other 7/8.
    func testRaddSkipsTheSpouse() {
        let (result, share) = run([.wives: 1, .daughters: 1])
        XCTAssertTrue(result.didRadd)
        XCTAssertEqual(share[.wives], Fraction(1, 8))
        XCTAssertEqual(share[.daughters], Fraction(7, 8))
    }

    /// A12: both parents alone: mother 1/3 and father the residue 2/3 (4:11).
    func testParentsAlone() {
        let (_, share) = run([.mother: 1, .father: 1])
        XCTAssertEqual(share[.mother], Fraction(1, 3))
        XCTAssertEqual(share[.father], Fraction(2, 3))
    }

    /// A12: two brothers cut the mother to 1/6 even though the father excludes them (4:11, hajb nuqsan).
    func testExcludedBrothersStillReduceTheMother() {
        let (result, share) = run([.mother: 1, .father: 1, .fullBrothers: 2])
        XCTAssertEqual(share[.mother], Fraction(1, 6))
        XCTAssertEqual(share[.father], Fraction(5, 6))
        XCTAssertNil(share[.fullBrothers])
        XCTAssertTrue(result.blocked.contains { $0.heir == .fullBrothers })
    }

    /// A12: several wives share one eighth beside a son (4:12).
    func testWivesShareOneEighth() throws {
        let (result, share) = run([.wives: 2, .sons: 1])
        XCTAssertEqual(share[.wives], Fraction(1, 8))
        XCTAssertEqual(try XCTUnwrap(result.awards.first { $0.heir == .wives }).each, Fraction(1, 16))
        XCTAssertEqual(share[.sons], Fraction(7, 8))
    }

    /// A12: over 20,736 families: the shares plus the unclaimed part make exactly one estate, and every entered heir is either paid or given a reason.
    func testEveryFamilyAddsUpToOneEstate() {
        let axes: [(FaraidHeir?, [Int])] = [
            (nil, [0, 1, 2]),                // no spouse, husband, one wife
            (.mother, [0, 1]), (.father, [0, 1]), (.grandfather, [0, 1]),
            (.sons, [0, 1, 2]), (.daughters, [0, 1, 2]), (.granddaughters, [0, 1]),
            (.fullBrothers, [0, 1]), (.fullSisters, [0, 1, 2]),
            (.paternalBrothers, [0, 1]), (.paternalSisters, [0, 1]), (.maternalSiblings, [0, 2]),
        ]
        var choice = Array(repeating: 0, count: axes.count)
        var families = 0
        outer: while true {
            var counts: [FaraidHeir: Int] = [:]
            for (index, axis) in axes.enumerated() {
                let value = axis.1[choice[index]]
                if let heir = axis.0 {
                    counts[heir] = value
                } else if value == 1 {
                    counts[.husband] = 1
                } else if value == 2 {
                    counts[.wives] = 1
                }
            }
            let result = Faraid.distribute(counts: counts)
            let label = counts.filter { $0.value > 0 }.map { "\($0.key.rawValue)=\($0.value)" }.sorted().joined(separator: ",")
            XCTAssertEqual(total(result), .one, label)
            let awarded = Set(result.awards.map(\.heir))
            let blocked = Set(result.blocked.map(\.heir))
            XCTAssertTrue(awarded.isDisjoint(with: blocked), label)
            for (heir, count) in counts where count > 0 {
                XCTAssertTrue(awarded.contains(heir) || blocked.contains(heir), "\(label): \(heir.rawValue) vanished")
            }
            for award in result.awards {
                XCTAssertTrue(award.share > .zero, label)
                XCTAssertEqual(award.each * Fraction(award.count), award.share, label)
            }
            families += 1
            // Next combination (odometer).
            var position = axes.count - 1
            while position >= 0 {
                choice[position] += 1
                if choice[position] < axes[position].1.count { continue outer }
                choice[position] = 0
                position -= 1
            }
            break
        }
        XCTAssertEqual(families, 20_736)
    }
}
