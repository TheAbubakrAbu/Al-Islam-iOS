import XCTest
import Combine
@testable import iPhone

/// The slices (Performance Guide, section 18, Stage 2): a write of a stored setting publishes the ONE
/// slice that owns its key, so a view observing `QuranDisplay` never re-renders for a Duha toggle.
/// `Settings` itself still publishes (the safety net until Stage 4), which `SettingPublishTests` pins.
///
/// Hosted in iPhone.app; every test puts back the value it touched.
@MainActor
final class SettingsSliceTests: XCTestCase {
    private var originalHelper = false
    private var originalDuha = false
    private var originalAccentHex = ""

    override func setUp() {
        super.setUp()
        // Let the debounced follow-ups of the previous test (a prayer refetch 150 ms after a Duha
        // flip) land before the counting starts, or they are counted here.
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        originalHelper = Settings.shared.showMuqattaatHelper
        originalDuha = Settings.shared.showDuha
        originalAccentHex = Settings.shared.customAccentColorHex
    }

    override func tearDown() {
        Settings.shared.showMuqattaatHelper = originalHelper
        Settings.shared.showDuha = originalDuha
        Settings.shared.customAccentColorHex = originalAccentHex
        super.tearDown()
    }

    private func publishes<Object: ObservableObject>(of object: Object, during work: () -> Void) -> Int
    where Object.ObjectWillChangePublisher == ObservableObjectPublisher {
        var count = 0
        let sink = object.objectWillChange.sink { _ in count += 1 }
        work()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        sink.cancel()
        return count
    }

    func testQuranDisplayKeyPublishesItsSliceOnce() {
        let flipped = !Settings.shared.showMuqattaatHelper
        XCTAssertEqual(publishes(of: QuranDisplay.shared) { Settings.shared.showMuqattaatHelper = flipped }, 1)
    }

    func testQuranDisplayKeyLeavesTheOtherSlicesAlone() {
        let flipped = !Settings.shared.showMuqattaatHelper
        XCTAssertEqual(publishes(of: AdhanSettings.shared) { Settings.shared.showMuqattaatHelper = flipped }, 0)
        XCTAssertEqual(publishes(of: HadithSettings.shared) { Settings.shared.showMuqattaatHelper = !flipped }, 0)
    }

    func testAdhanKeyPublishesOnlyTheAdhanSlice() {
        let flipped = !Settings.shared.showDuha
        XCTAssertEqual(publishes(of: AdhanSettings.shared) { Settings.shared.showDuha = flipped }, 1)
        XCTAssertEqual(publishes(of: QuranDisplay.shared) { Settings.shared.showDuha = !flipped }, 0)
    }

    func testUnchangedWritePublishesNoSlice() {
        let same = Settings.shared.showMuqattaatHelper
        XCTAssertEqual(publishes(of: QuranDisplay.shared) { Settings.shared.showMuqattaatHelper = same }, 0)
    }

    /// The app-group preferences stay `@Published` on `Settings`; their key routes to a slice too.
    func testPublishedAppGroupFieldRoutesToItsSlice() {
        let next = Settings.shared.customAccentColorHex == "FF2D55" ? "34C759" : "FF2D55"
        XCTAssertEqual(publishes(of: AppearanceSettings.shared) { Settings.shared.customAccentColorHex = next }, 1)
        XCTAssertEqual(publishes(of: QuranDisplay.shared) { Settings.shared.customAccentColorHex = originalAccentHex }, 0)
    }

    func testSliceForwarderReadsAndWritesTheSameStorage() {
        let flipped = !Settings.shared.showMuqattaatHelper
        QuranDisplay.shared.showMuqattaatHelper = flipped
        XCTAssertEqual(Settings.shared.showMuqattaatHelper, flipped)
        XCTAssertEqual(QuranDisplay.shared.showMuqattaatHelper, flipped)
        XCTAssertEqual(UserDefaults.standard.object(forKey: "showMuqattaatHelper") as? Bool, flipped)
    }

    /// Every `@Setting` on `Settings` belongs to exactly one slice: a new field that nobody assigned
    /// would publish no slice, and the views observing slices would miss it.
    func testEveryStoredSettingBelongsToExactlyOneSlice() {
        var keys: [String] = []
        for child in Mirror(reflecting: Settings.shared).children {
            if let stored = child.value as? SettingKeyed { keys.append(stored.settingKey) }
        }
        XCTAssertGreaterThan(keys.count, 200, "the Mirror walk should see the stored settings")
        var unowned: [String] = []
        var shared: [String] = []
        for key in keys {
            let owners = SettingsSlices.all.filter { type(of: $0).keys.contains(key) }
            if owners.isEmpty { unowned.append(key) }
            if owners.count > 1 { shared.append(key) }
        }
        XCTAssertEqual(unowned, [], "stored settings with no slice")
        XCTAssertEqual(shared, [], "stored settings claimed by two slices")
    }
}
