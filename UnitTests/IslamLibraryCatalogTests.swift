import XCTest
@testable import iPhone

/// The six reading libraries opened as Islamic resources on 2026-11-24 (Stories of the Prophets; Sahabah,
/// Ahlul Bayt & Salaf; Refuting Religions; Preservation of the Quran; Science of Hadith; the Domino
/// Process). Each lists its own chapters beside the Pillars & Beliefs and Proving Islam pages on its
/// subject, and its search has to reach both without counting any page twice.
final class IslamLibraryCatalogTests: XCTestCase {
    private let libraries = IslamArticleHome.allCases.filter(\.isLibrary)

    @MainActor
    func testEveryLibraryHasChaptersOfItsOwn() {
        XCTAssertEqual(libraries.count, 6)
        for home in libraries {
            let owned = IslamArticleCatalog.groups(for: home).flatMap(\.entries).filter { $0.home == home }
            XCTAssertFalse(owned.isEmpty, "\(home) has no chapters")
            for entry in owned {
                XCTAssertNotNil(IslamArticleCatalog.byID[entry.id], "\(entry.id) is not in the catalog")
                XCTAssertNotNil(IslamArticles.destination(for: entry.id), "\(entry.id) does not open")
            }
        }
    }

    func testNoArticleIsCountedTwice() {
        let ids = IslamArticleCatalog.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "a borrowed row leaked into `all`")
        let keys = IslamArticleCatalog.all.map(\.linkKey)
        XCTAssertEqual(keys.count, Set(keys).count, "two articles share a shared-link key")
    }

    func testABorrowedPageKeepsItsHome() {
        let entry = IslamArticleCatalog.byID["ChristianityAnswerView"]
        XCTAssertEqual(entry?.home, .pillars, "listing it in Refuting Religions must not move it")
        XCTAssertTrue(IslamArticleCatalog.members[.religions]?.contains("ChristianityAnswerView") == true)
        XCTAssertTrue(IslamArticleCatalog.members[.hadithScience]?.contains("HadithSciencesView") == true)
    }

    func testALibrarySearchReachesTheBorrowedPages() {
        let titles = IslamArticleSearch.titleHits("christianity", homes: [.religions])
        XCTAssertTrue(titles.contains { $0.id == "ChristianityAnswerView" })
        let passages = IslamArticleSearch.contentHits("trinity", homes: [.religions], limit: 200)
        XCTAssertFalse(passages.isEmpty)
        let listed = IslamArticleCatalog.members[.religions] ?? []
        XCTAssertTrue(passages.allSatisfy { listed.contains($0.article.id) }, "a hit from outside the library")
    }

    func testTopicsAdmitTheBorrowedRowsOfTheirGroup() {
        var filters = IslamSearchFilters()
        filters.groups = ["religions/THE PEOPLE OF THE BOOK"]
        let titles = IslamArticleSearch.titleHits("answering", homes: [.religions], filters: filters)
        XCTAssertTrue(titles.contains { $0.id == "ChristianityAnswerView" })
        XCTAssertFalse(titles.contains { $0.id == "HinduismAnswerView" }, "another group's row got through")
    }

    // MARK: Prophets' facts (2026-11-24)

    /// Every prophet's story chapters and Pillars page are real catalog pages, so his tags and his doors
    /// land somewhere.
    func testEveryProphetsPagesAreInTheCatalog() {
        XCTAssertEqual(ProphetFacts.all.count, 26, "25 prophets and Maryam")
        for facts in ProphetFacts.all {
            for id in facts.stories {
                XCTAssertNotNil(IslamArticleCatalog.byID[id], "\(facts.key): \(id) is not a catalog page")
            }
            if !facts.pillars.isEmpty {
                XCTAssertNotNil(IslamArticleCatalog.byID[facts.pillars], "\(facts.key): \(facts.pillars)")
            }
        }
    }

    /// The generated counts are the ones the scholars of the Quran give: if the Quran text or the matching
    /// ever changes, this says so before a tag does.
    func testTheNamesAreCountedAsTheScholarsCountThem() {
        let expected = ["musa": 136, "ibrahim": 69, "nuh": 43, "harun": 20, "yusuf": 27, "lut": 27, "adam": 25,
                        "isa": 25, "sulayman": 17, "ishaq": 17, "yaqub": 16, "dawud": 16, "ismail": 12,
                        "shuayb": 11, "salih": 9, "hud": 7, "zakariyya": 7, "yahya": 5, "muhammad": 4,
                        "ayyub": 4, "yunus": 4, "idris": 2, "ilyas": 2, "alyasa": 2, "dhulkifl": 2, "maryam": 34]
        for (key, times) in expected {
            let facts = ProphetFacts.named(key)
            XCTAssertEqual(facts?.times, times, key)
            XCTAssertEqual(facts?.surahs.reduce(0) { $0 + $1.ayahs.count }, facts?.ayahCount, key)
        }
    }

    /// A prophet's tags are on his first chapter and his Pillars page only; his later chapters and every
    /// other library's chapters carry their own written ones, each for a real page.
    func testTagsSitOnTheRightRows() {
        XCTAssertFalse(LibraryTags.tags(for: "StoryMusaEarlyView").isEmpty)
        XCTAssertEqual(LibraryTags.arabic(for: "ProphetMusaView"), ProphetFacts.named("musa")?.arabic)
        XCTAssertNil(LibraryTags.arabic(for: "StoryMusaPharaohView"), "a later chapter is not his primary row")
        for id in LibraryTags.written.keys {
            XCTAssertNotNil(IslamArticleCatalog.byID[id], "written tags for \(id), which is no catalog page")
        }
    }

    // MARK: The prophets' own pages (2026-11-25)

    /// The 25 prophets' pages left Pillars & Beliefs for Stories of the Prophets (its Prophets view). They
    /// are searched and opened there, and a link shared before the move still opens its page.
    func testTheProphetsPagesLiveInStoriesAndKeepTheirLinks() {
        let pages = IslamArticleCatalog.prophetGroups.flatMap(\.entries)
        XCTAssertEqual(pages.count, 25)
        XCTAssertFalse(IslamArticleCatalog.pillarsGroups.contains { $0.title.contains("PROPHETS NAMED") })
        for page in pages {
            XCTAssertEqual(IslamArticleCatalog.byID[page.id]?.home, .stories, page.id)
            XCTAssertTrue(page.linkKey.hasPrefix("pillars."), "\(page.id) lost its shared link: \(page.linkKey)")
            XCTAssertEqual(IslamArticleCatalog.entry(linkKey: page.linkKey)?.id, page.id)
            XCTAssertFalse(LibraryTags.tags(for: page.id).isEmpty, "\(page.id) has no tags for its row")
        }
        XCTAssertEqual(IslamArticleCatalog.entry(linkKey: "pillars.adam")?.id, "ProphetAdamView")
        XCTAssertEqual(IslamArticleCatalog.entry(linkKey: "stories.adam")?.id, "StoryAdamView")
        XCTAssertFalse(IslamArticleSearch.titleHits("adam", homes: [.pillars]).contains { $0.id == "ProphetAdamView" })
        XCTAssertTrue(IslamArticleSearch.titleHits("adam", homes: [.stories]).contains { $0.id == "ProphetAdamView" })
        // The stories' own index is the stories alone.
        XCTAssertFalse(IslamArticleCatalog.storiesGroups.contains { $0.title.contains("PROPHETS NAMED") })
    }

    /// Each name the Prophets view lists after the 25 opens a real page on a heading that page has.
    func testEveryNameBeyondTheTwentyFiveOpensARealHeading() {
        let headings: [String: [String]] = [
            "StoryIsraeliyyatView": StoryIsraeliyyatView.sections.map(\.heading),
            "StoryKhidrView": StoryKhidrView.sections.map(\.heading),
        ]
        XCTAssertEqual(Set(OtherProphet.all.map(\.id)).count, OtherProphet.all.count)
        for prophet in OtherProphet.all {
            XCTAssertNotNil(IslamArticleCatalog.byID[prophet.article], "\(prophet.id): \(prophet.article)")
            XCTAssertNotNil(headings[prophet.article], "\(prophet.id) opens a page this test does not know")
            if let section = prophet.section {
                XCTAssertTrue(headings[prophet.article]?.contains(section) == true, "\(prophet.id): no heading \(section)")
            }
        }
    }

    func testTheRootSearchStillFindsEachPageOnce() {
        let hits = IslamArticleSearch.titleHits("hadith", homes: Set(IslamArticleHome.allCases))
        let ids = hits.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }
}
