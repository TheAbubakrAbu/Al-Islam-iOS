import XCTest
@testable import iPhone

/// The grid switches' split (2026-10-10, `Settings.migrateGridModes`): every screen keeps its own
/// grid/list choice, and the update itself changes nothing on screen. Until then the Quran tab's switch
/// was the fallback four other screens followed, and the Hadith chapters read the collections' key with
/// the opposite default.
@MainActor
final class GridModeMigrationTests: XCTestCase {
    private let keys = ["quranGridMode", "hadithGridMode", "hadithChapterGridMode", "gridModesPerScreenMigrated"]
        + Settings.gridModeFollowerKeys
    private var saved: [String: Any] = [:]

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults.standard
        saved = [:]
        for key in keys {
            if let value = defaults.object(forKey: key) { saved[key] = value }
            defaults.removeObject(forKey: key)
        }
    }

    override func tearDown() {
        let defaults = UserDefaults.standard
        for key in keys {
            if let value = saved[key] { defaults.set(value, forKey: key) } else { defaults.removeObject(forKey: key) }
        }
        super.tearDown()
    }

    func testAListUserKeepsTheirListsEverywhere() {
        // The old fallback showed this person lists on all four screens; after the split it still does.
        UserDefaults.standard.set(false, forKey: "quranGridMode")
        Settings.migrateGridModes()
        for key in Settings.gridModeFollowerKeys {
            XCTAssertEqual(UserDefaults.standard.object(forKey: key) as? Int, 0, key)
        }
        let settings = Settings.shared
        XCTAssertFalse(settings.islamGridMode)
        XCTAssertFalse(settings.arabicGridMode)
        XCTAssertFalse(settings.namesGridMode)
        XCTAssertFalse(settings.settingsGridMode)
    }

    func testTheQuranTabNoLongerMovesTheOtherScreens() {
        Settings.migrateGridModes()
        let settings = Settings.shared
        XCTAssertTrue(settings.islamGridMode, "a fresh install is grid, the default")
        // Flipping the Quran tab to lists (or a Scroll To Surah, before the fix) used to take these along.
        UserDefaults.standard.set(false, forKey: "quranGridMode")
        XCTAssertTrue(settings.islamGridMode)
        XCTAssertTrue(settings.arabicGridMode)
        XCTAssertTrue(settings.namesGridMode)
        XCTAssertTrue(settings.settingsGridMode)
    }

    func testAChoiceAlreadyMadeIsKept() {
        UserDefaults.standard.set(false, forKey: "quranGridMode")
        UserDefaults.standard.set(1, forKey: "gridModeIslamRaw")
        Settings.migrateGridModes()
        XCTAssertEqual(UserDefaults.standard.object(forKey: "gridModeIslamRaw") as? Int, 1)
        XCTAssertTrue(Settings.shared.islamGridMode)
    }

    func testChaptersTakeTheCollectionsStoredChoice() {
        UserDefaults.standard.set(true, forKey: "hadithGridMode")
        Settings.migrateGridModes()
        XCTAssertEqual(UserDefaults.standard.object(forKey: "hadithChapterGridMode") as? Bool, true)
    }

    func testChaptersStayAListWhenNothingWasChosen() {
        Settings.migrateGridModes()
        XCTAssertEqual(UserDefaults.standard.object(forKey: "hadithChapterGridMode") as? Bool, false)
    }

    func testEveryScreenIsWrittenSoBackupsCarryIt() {
        Settings.migrateGridModes()
        for key in Settings.gridModeFollowerKeys {
            XCTAssertEqual(UserDefaults.standard.object(forKey: key) as? Int, 1, key)
        }
    }

    func testItRunsOnceUnlessForced() {
        Settings.migrateGridModes()
        // A later list choice on the Quran tab must not be copied anywhere by a second launch.
        UserDefaults.standard.set(false, forKey: "quranGridMode")
        Settings.migrateGridModes()
        XCTAssertEqual(UserDefaults.standard.object(forKey: "gridModeIslamRaw") as? Int, 1)
        // Nor by a restore of a NEW backup, which carries every screen's own choice.
        Settings.migrateGridModes(force: true)
        XCTAssertEqual(UserDefaults.standard.object(forKey: "gridModeIslamRaw") as? Int, 1)
    }

    func testAnOldBackupKeepsItsOldMeaning() {
        // A pre-split backup restored: its followers come back unset beside a stored Quran list, which
        // on the device that made it meant lists on all four screens.
        Settings.migrateGridModes()
        for key in Settings.gridModeFollowerKeys { UserDefaults.standard.removeObject(forKey: key) }
        UserDefaults.standard.removeObject(forKey: "hadithChapterGridMode")
        UserDefaults.standard.set(false, forKey: "quranGridMode")
        UserDefaults.standard.set(true, forKey: "hadithGridMode")
        Settings.migrateGridModes(force: true)
        XCTAssertEqual(UserDefaults.standard.object(forKey: "gridModeIslamRaw") as? Int, 0)
        XCTAssertEqual(UserDefaults.standard.object(forKey: "hadithChapterGridMode") as? Bool, true)
    }
}
