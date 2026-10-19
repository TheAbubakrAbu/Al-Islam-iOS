import XCTest
@testable import iPhone

/// The update dialog's rules (AppUpdateCheck.swift, 2026-10-19): how versions compare, what the store's
/// answer parses to, and when a listing is worth the dialog.
final class AppUpdateCheckTests: XCTestCase {
    private typealias Checker = AppUpdateChecker

    private func listing(_ version: String, minimumOS: String = "16.0") -> Checker.StoreListing {
        Checker.StoreListing(version: version, minimumOSVersion: minimumOS, storeURL: nil)
    }

    // MARK: Versions

    func testVersionsCompareNumberByNumber() {
        XCTAssertTrue(Checker.isVersion("4.7", newerThan: "4.6.5"))
        XCTAssertTrue(Checker.isVersion("4.6.10", newerThan: "4.6.9"), "10 is more than 9, not less (no string compare)")
        XCTAssertTrue(Checker.isVersion("5.0", newerThan: "4.99.99"))
        XCTAssertFalse(Checker.isVersion("4.6.5", newerThan: "4.6.5"))
        XCTAssertFalse(Checker.isVersion("4.6.5", newerThan: "4.6.5.0"), "a trailing zero is the same version")
        XCTAssertFalse(Checker.isVersion("4.6.4", newerThan: "4.6.5"))
    }

    func testGarbageComponentsCountAsZero() {
        XCTAssertFalse(Checker.isVersion("4.6.beta", newerThan: "4.6.5"))
        XCTAssertEqual(Checker.compare("", "0"), .orderedSame)
    }

    // MARK: The store's answer

    func testListingParsesFromTheLookupService() {
        let json = """
        {"resultCount":1,"results":[{"version":"4.7","minimumOsVersion":"16.0",
         "trackViewUrl":"https://apps.apple.com/us/app/al-islam/id6449729655?uo=4","bundleId":"x"}]}
        """
        let listing = Checker.parseListing(Data(json.utf8))
        XCTAssertEqual(listing?.version, "4.7")
        XCTAssertEqual(listing?.minimumOSVersion, "16.0")
        XCTAssertEqual(listing?.storeURL?.host, "apps.apple.com")
    }

    func testEmptyLookupIsNoListing() {
        XCTAssertNil(Checker.parseListing(Data("{\"resultCount\":0,\"results\":[]}".utf8)))
        XCTAssertNil(Checker.parseListing(Data("not json".utf8)))
    }

    func testLookupURLNamesTheBundleAndTheStorefront() {
        let url = Checker.lookupURL(bundleIdentifier: "com.example.app", region: "GB")
        XCTAssertEqual(url?.host, "itunes.apple.com")
        XCTAssertEqual(url?.path, "/lookup")
        XCTAssertTrue(url?.query?.contains("bundleId=com.example.app") == true)
        XCTAssertTrue(url?.query?.contains("country=gb") == true)
    }

    // MARK: When to ask

    func testNewerVersionIsOffered() {
        XCTAssertTrue(Checker.shouldOffer(listing: listing("4.7"), installed: "4.6.5", os: "26.0",
                                          lastOfferedVersion: "", lastOfferedAt: nil, now: Date()))
    }

    func testSameOrOlderVersionIsNot() {
        XCTAssertFalse(Checker.shouldOffer(listing: listing("4.6.5"), installed: "4.6.5", os: "26.0",
                                           lastOfferedVersion: "", lastOfferedAt: nil, now: Date()))
        XCTAssertFalse(Checker.shouldOffer(listing: listing("4.6.4"), installed: "4.6.5", os: "26.0",
                                           lastOfferedVersion: "", lastOfferedAt: nil, now: Date()),
                       "a TestFlight build ahead of the store is not asked to go back")
    }

    func testVersionThisOSCannotRunIsNotAnUpdate() {
        XCTAssertFalse(Checker.shouldOffer(listing: listing("4.7", minimumOS: "18.0"), installed: "4.6.5", os: "16.4",
                                           lastOfferedVersion: "", lastOfferedAt: nil, now: Date()))
        XCTAssertTrue(Checker.shouldOffer(listing: listing("4.7", minimumOS: "16.0"), installed: "4.6.5", os: "16.4",
                                          lastOfferedVersion: "", lastOfferedAt: nil, now: Date()))
    }

    func testTheSameVersionWaitsADayBetweenOffers() {
        let now = Date()
        XCTAssertFalse(Checker.shouldOffer(listing: listing("4.7"), installed: "4.6.5", os: "26.0",
                                           lastOfferedVersion: "4.7", lastOfferedAt: now.addingTimeInterval(-2 * 3600), now: now),
                       "offered two hours ago")
        XCTAssertTrue(Checker.shouldOffer(listing: listing("4.7"), installed: "4.6.5", os: "26.0",
                                          lastOfferedVersion: "4.7", lastOfferedAt: now.addingTimeInterval(-25 * 3600), now: now),
                      "offered yesterday")
        XCTAssertTrue(Checker.shouldOffer(listing: listing("4.8"), installed: "4.6.5", os: "26.0",
                                          lastOfferedVersion: "4.7", lastOfferedAt: now.addingTimeInterval(-60), now: now),
                      "a newer version than the one offered a minute ago is news")
    }
}
