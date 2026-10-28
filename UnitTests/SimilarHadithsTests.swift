import XCTest
@testable import iPhone

/// The similar narrations (SimilarHadiths.swift): the shipped pack reads back exactly what
/// Scripts/build_similar_hadiths.py found (its generated `SimilarHadithSamples`), runs to tint
/// included, every match names a row that exists, and every run lands on whole words of the matched
/// narration's own text, so the tint the app paints without computing anything is on the right words.
final class SimilarHadithsTests: XCTestCase {
    private func book(_ slug: String) throws -> HadithBookData {
        let url = try XCTUnwrap(HadithPack.bundledURL(slug), slug)
        return HadithBookData(pack: try XCTUnwrap(HadithPack(slug: slug, url: url), slug))
    }

    private func pack() throws -> SimilarHadithsPack {
        let url = try XCTUnwrap(SimilarHadithsPack.bundledURL(), "SimilarHadiths.qpk is not bundled")
        return try XCTUnwrap(SimilarHadithsPack(url: url), "SimilarHadiths.qpk does not open")
    }

    func testEveryBookOfThePackReadsBackInOrder() throws {
        let pack = try pack()
        XCTAssertEqual(pack.slugs.count, 17)
        XCTAssertEqual(pack.books.count, 17)
        XCTAssertEqual(pack.slugs.first, "bukhari")
        XCTAssertGreaterThan(pack.rowCount, 30_000)
        var total = 0
        for slug in pack.slugs {
            let book = try XCTUnwrap(pack.books[slug], slug)
            let rows = pack.rows(slug: slug)
            XCTAssertEqual(rows.count, book.count, slug)
            XCTAssertEqual(rows.map(\.idInBook), rows.map(\.idInBook).sorted(), slug)
            XCTAssertTrue(rows.allSatisfy { !$0.matches.isEmpty }, slug)
            total += rows.count
        }
        XCTAssertEqual(total, pack.rowCount)
        XCTAssertFalse(pack.contains(slug: "bukhari", idInBook: 0))
        XCTAssertTrue(pack.matches(slug: "nobody", idInBook: 1).isEmpty)
    }

    /// The binary search finds, for every sample, exactly the records the script wrote for it, runs included.
    func testThePackHoldsTheScriptsMatches() throws {
        let pack = try pack()
        XCTAssertGreaterThan(SimilarHadithSamples.all.count, 8)
        for sample in SimilarHadithSamples.all {
            let found = pack.matches(slug: sample.slug, idInBook: sample.idInBook)
            let expected = sample.matches.map {
                "\($0.slug):\($0.idInBook):\($0.tier):\($0.score):\($0.flags):" + $0.runs.map { "\($0[0])+\($0[1])" }.joined(separator: ",")
            }
            let actual = found.map {
                "\($0.slug):\($0.idInBook):\($0.tier.rawValue):\($0.score):\($0.sameEnglish ? 1 : 0):"
                    + $0.sharedRanges.map { "\($0.location)+\($0.length)" }.joined(separator: ",")
            }
            XCTAssertEqual(actual, expected, "\(sample.slug) \(sample.idInBook)")
            XCTAssertEqual(pack.contains(slug: sample.slug, idInBook: sample.idInBook), !sample.matches.isEmpty,
                           "\(sample.slug) \(sample.idInBook)")
        }
    }

    /// Every shipped run of the samples' matches is whole words of the matched narration's own Arabic:
    /// inside the text, no space at either end, a space (or the text's edge) on both sides. The
    /// same-text tier ships one run, the whole text after the chain; the same-everything tier none.
    func testTheShippedRunsLandOnWholeWords() throws {
        let pack = try pack()
        var books: [String: HadithBookData] = [:]
        var checked = 0
        for sample in SimilarHadithSamples.all {
            for match in pack.matches(slug: sample.slug, idInBook: sample.idInBook) {
                let data = try books[match.slug] ?? book(match.slug)
                books[match.slug] = data
                let hadith = try XCTUnwrap(data.hadith(numbered: match.idInBook), "\(match.slug) \(match.idInBook)")
                let text = hadith.arabic as NSString
                switch match.tier {
                case .sameTextAndChain: XCTAssertTrue(match.sharedRanges.isEmpty, "\(match.slug) \(match.idInBook)")
                case .sameText: XCTAssertEqual(match.sharedRanges.count, 1, "\(match.slug) \(match.idInBook)")
                case .similar: XCTAssertFalse(match.sharedRanges.isEmpty, "\(match.slug) \(match.idInBook)")
                }
                var end = 0
                for range in match.sharedRanges {
                    let where_ = "\(match.slug) \(match.idInBook) \(range)"
                    XCTAssertGreaterThanOrEqual(range.location, end, where_)
                    XCTAssertGreaterThan(range.length, 0, where_)
                    XCTAssertLessThanOrEqual(range.location + range.length, text.length, where_)
                    guard range.location + range.length <= text.length else { continue }
                    let run = text.substring(with: range)
                    XCTAssertEqual(run, run.trimmingCharacters(in: .whitespacesAndNewlines), where_)
                    if range.location > 0 {
                        XCTAssertTrue(isSpace(text.character(at: range.location - 1)), where_)
                    }
                    if range.location + range.length < text.length {
                        XCTAssertTrue(isSpace(text.character(at: range.location + range.length)), where_)
                    }
                    end = range.location + range.length
                    checked += 1
                }
            }
        }
        XCTAssertGreaterThan(checked, 200)
    }

    private func isSpace(_ unit: unichar) -> Bool {
        guard let scalar = Unicode.Scalar(unit) else { return false }
        return scalar.properties.isWhitespace
    }

    /// Every match of al-Bukhari's rows names a row that exists, never the row itself, within the
    /// script's score range; and the exact tiers list each other both ways.
    func testEveryMatchOfAlBukhariNamesARow() throws {
        let pack = try pack()
        var ids: [String: Set<Int>] = [:]
        func idsInBook(_ slug: String) throws -> Set<Int> {
            if let known = ids[slug] { return known }
            let known = Set(try book(slug).hadiths.map(\.idInBook))
            ids[slug] = known
            return known
        }
        let rows = pack.rows(slug: "bukhari")
        XCTAssertGreaterThan(rows.count, 5_000)
        var checked = 0
        var missing: [String] = []
        var unreturned: [String] = []
        for (id, matches) in rows {
            for match in matches {
                XCTAssertFalse(match.slug == "bukhari" && match.idInBook == id, "bukhari \(id) lists itself")
                XCTAssertTrue((45...100).contains(match.score), "bukhari \(id): score \(match.score)")
                if try !idsInBook(match.slug).contains(match.idInBook) {
                    missing.append("\(match.slug) \(match.idInBook) from bukhari \(id)")
                }
                if match.tier != .similar {
                    let back = pack.matches(slug: match.slug, idInBook: match.idInBook)
                    if !back.contains(where: { $0.slug == "bukhari" && $0.idInBook == id && $0.tier == match.tier }) {
                        unreturned.append("\(match.slug) \(match.idInBook) does not list bukhari \(id)")
                    }
                }
                checked += 1
            }
        }
        XCTAssertGreaterThan(checked, 10_000)
        XCTAssertEqual(missing.prefix(5), [], "\(missing.count) matches name rows that do not exist")
        XCTAssertEqual(unreturned.prefix(5), [], "\(unreturned.count) exact matches are one-way")
    }

    func testTheStoreAnswersAndSurvivesAPurge() throws {
        XCTAssertTrue(SimilarHadithsStore.shared.hasMatches(slug: "bukhari", idInBook: 1))
        XCTAssertFalse(SimilarHadithsStore.shared.matches(slug: "bukhari", idInBook: 1).isEmpty)
        // A memory warning empties the cache; the next question inflates the book again.
        SimilarHadithsStore.shared.purge()
        XCTAssertTrue(SimilarHadithsStore.shared.hasMatches(slug: "bukhari", idInBook: 1))
        XCTAssertFalse(SimilarHadithsStore.shared.hasMatches(slug: "bukhari", idInBook: 0))
    }
}
