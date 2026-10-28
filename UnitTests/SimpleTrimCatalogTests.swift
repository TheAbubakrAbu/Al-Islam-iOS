import XCTest
@testable import iPhone

/// The Simple Mode catalog (Docs/Product/Simple Mode v2 Design.md, section 5): every hideable thing is
/// one `SimpleTrim` case with exactly one entry, so the Simple Mode page and the checking script can
/// trust the table. These pin the table's shape, not any one view's behavior.
final class SimpleTrimCatalogTests: XCTestCase {
    func testEveryCaseHasOneEntryInOrder() {
        XCTAssertEqual(SimpleTrim.entries.map(\.trim), SimpleTrim.allCases)
    }

    func testTitlesAreUniqueAndNonEmpty() {
        let titles = SimpleTrim.entries.map(\.title)
        XCTAssertFalse(titles.contains { $0.isEmpty })
        XCTAssertEqual(Set(titles).count, titles.count)
    }

    func testEveryDoorReads() {
        for entry in SimpleTrim.entries {
            XCTAssertFalse(entry.door.text.isEmpty, "\(entry.trim) has a blank door")
            switch entry.door {
            case .moreMenu(let s), .settings(let s), .longPress(let s), .elsewhere(let s):
                XCTAssertFalse(s.isEmpty, "\(entry.trim) names no place")
            case .dropped:
                break
            }
        }
    }

    func testEverySurfaceHasAnEntry() {
        for surface in SimpleTrim.Surface.allCases {
            XCTAssertTrue(SimpleTrim.entries.contains { $0.surface == surface }, "\(surface) has no entry")
        }
    }

    func testGroupedFollowsSurfaceOrder() {
        XCTAssertEqual(SimpleTrim.grouped.map(\.surface), SimpleTrim.Surface.allCases)
    }

    func testDoorText() {
        XCTAssertEqual(SimpleTrim.Door.moreMenu("Today").text, "⋯ menu › Today")
        XCTAssertEqual(SimpleTrim.Door.settings("Prayer Settings › Optional Prayers").text,
                       "Settings › Prayer Settings › Optional Prayers")
        XCTAssertEqual(SimpleTrim.Door.longPress("Favorite").text, "Press and hold › Favorite")
        XCTAssertEqual(SimpleTrim.Door.elsewhere("the bottom pair").text, "The bottom pair")
        XCTAssertEqual(SimpleTrim.Door.dropped().text, "Dropped")
        XCTAssertEqual(SimpleTrim.Door.dropped("the figures").text, "Dropped: the figures")
    }

    func testUnlessKeepsTheControl() {
        let settings = Settings.shared
        let previous = settings.simpleMode
        // Turning Simple Mode on folds every Advanced switch (rule 9), so the host app's are put back.
        let storedAdvanced = Settings.AdvancedScreen.allCases.map { ($0.storageKey, UserDefaults.standard.object(forKey: $0.storageKey)) }
        defer {
            settings.simpleMode = previous
            for (key, value) in storedAdvanced {
                if let value {
                    UserDefaults.standard.set(value, forKey: key)
                } else {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        }

        settings.simpleMode = true
        XCTAssertFalse(settings.hides(.playTestMode, unless: true))
        XCTAssertTrue(settings.hides(.playTestMode, unless: false))

        settings.simpleMode = false
        XCTAssertFalse(settings.hides(.playTestMode, unless: true))
        XCTAssertFalse(settings.hides(.playTestMode, unless: false))
    }

    func testCatalogCount() {
        XCTAssertEqual(SimpleTrim.allCases.count, 44)
    }
}
