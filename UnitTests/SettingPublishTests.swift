import XCTest
import Combine
@testable import iPhone

/// The publish contract of a stored setting (Performance Guide, section 18, Stage 1).
///
/// `Settings` used to keep its fields in `@AppStorage`, which inside an `ObservableObject` publishes
/// TWICE per write (the wrapper's own set plus SwiftUI's defaults-observer echo) and again for a
/// write of the value already stored. Every view observing `Settings` re-rendered for each. The
/// `@Setting` wrapper keeps the same key, the same default and the same standard-defaults storage,
/// and publishes exactly once, only when the value changes.
///
/// Hosted in iPhone.app, so `Settings.shared` is the live object: every test puts the value it
/// touched back.
@MainActor
final class SettingPublishTests: XCTestCase {
    private var originalHelper = false
    private var originalSortDirection = ""
    private var originalFavoriteLetters = Data()

    override func setUp() {
        super.setUp()
        // Let the debounced follow-ups of the previous test (a prayer refetch 150 ms after a Duha
        // flip) land before the counting starts, or they are counted here.
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        let settings = Settings.shared
        originalHelper = settings.showMuqattaatHelper
        originalSortDirection = settings.quranSortDirectionRaw
        originalFavoriteLetters = settings.favoriteLetterData
    }

    override func tearDown() {
        let settings = Settings.shared
        settings.showMuqattaatHelper = originalHelper
        settings.quranSortDirectionRaw = originalSortDirection
        settings.favoriteLetterData = originalFavoriteLetters
        super.tearDown()
    }

    /// Settings publishes while `work` runs, plus anything a defaults observer echoes on the next
    /// turns of the run loop (SwiftUI's `@AppStorage` echo is what this counts in the old shape).
    private func publishes(during work: () -> Void) -> Int {
        var count = 0
        let sink = Settings.shared.objectWillChange.sink { _ in count += 1 }
        work()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        sink.cancel()
        return count
    }

    func testChangedBoolWritePublishesExactlyOnce() {
        let settings = Settings.shared
        let flipped = !settings.showMuqattaatHelper
        XCTAssertEqual(publishes { settings.showMuqattaatHelper = flipped }, 1,
                       "one publish per changed write: no defaults-observer echo")
        XCTAssertEqual(settings.showMuqattaatHelper, flipped)
    }

    func testUnchangedWriteDoesNotPublish() {
        let settings = Settings.shared
        let same = settings.showMuqattaatHelper
        XCTAssertEqual(publishes { settings.showMuqattaatHelper = same }, 0,
                       "writing the stored value again changes nothing a view could show")
    }

    func testChangedStringWritePublishesExactlyOnce() {
        let settings = Settings.shared
        let next = settings.quranSortDirectionRaw == "descending" ? "ascending" : "descending"
        XCTAssertEqual(publishes { settings.quranSortDirectionRaw = next }, 1)
        XCTAssertEqual(settings.quranSortDirectionRaw, next)
    }

    func testChangedDataWritePublishesExactlyOnce() {
        let settings = Settings.shared
        let next = Data([0x01, 0x02, 0x03]) == settings.favoriteLetterData ? Data([0x04]) : Data([0x01, 0x02, 0x03])
        XCTAssertEqual(publishes { settings.favoriteLetterData = next }, 1)
        XCTAssertEqual(settings.favoriteLetterData, next)
    }

    /// Same storage as before: the key, the suite and the value shape a `defaults read` shows.
    func testWriteLandsInStandardDefaultsUnderTheSameKey() {
        let settings = Settings.shared
        let flipped = !settings.showMuqattaatHelper
        settings.showMuqattaatHelper = flipped
        XCTAssertEqual(UserDefaults.standard.object(forKey: "showMuqattaatHelper") as? Bool, flipped)
    }

    /// A raw defaults write (a restore, a `-seedBool`, a probe) shows through the property.
    func testRawDefaultsWriteIsVisibleThroughTheProperty() {
        let settings = Settings.shared
        let flipped = !settings.showMuqattaatHelper
        UserDefaults.standard.set(flipped, forKey: "showMuqattaatHelper")
        XCTAssertEqual(settings.showMuqattaatHelper, flipped)
    }

    /// A store that keeps its own defaults key (hadith favorites, the reading history, a sheet's
    /// draft) never publishes `Settings`: the only views that may show its value observe that store.
    func testRawWriteOfAForeignKeyDoesNotPublishSettings() {
        let key = "SettingPublishTests.foreignKey"
        defer { UserDefaults.standard.removeObject(forKey: key) }
        XCTAssertEqual(publishes { UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: key) }, 0)
    }

    /// A raw write of a SETTINGS key is the bulk-restore shape: the caller publishes once through
    /// `storedContentWasReplaced`, so the wrapper itself must stay silent.
    func testRawWriteOfASettingsKeyDoesNotPublishByItself() {
        let settings = Settings.shared
        let flipped = !settings.showMuqattaatHelper
        XCTAssertEqual(publishes { UserDefaults.standard.set(flipped, forKey: "showMuqattaatHelper") }, 0)
    }
}
