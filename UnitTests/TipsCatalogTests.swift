import XCTest
@testable import iPhone

/// Tips & Tricks across the family (2026-10-11): Al-Adhan and Al-Quran compile TipsAndTricks.swift too,
/// each with only its own domains (HAS_ADHAN, HAS_QURAN, HAS_HADITH). This target builds Al-Islam,
/// which ships them all, so what these pin is that sharing the file changed nothing here: every area
/// is offered, the tips that now word themselves per app read as they always did, and the tips that
/// lean on a second domain are still shown. The companions' side is checked by building with their
/// flags (sibling-sync-toolchain: the companion test build).
final class TipsCatalogTests: XCTestCase {
    private func tip(_ id: String, file: StaticString = #filePath, line: UInt = #line) -> AppTip? {
        let found = TipCatalog.all.first { $0.id == id }
        XCTAssertNotNil(found, "no tip \(id)", file: file, line: line)
        return found
    }

    func testEveryAreaIsOffered() {
        XCTAssertEqual(TipArea.offered, TipArea.allCases)
        XCTAssertEqual(SettingsSearchEntry.tipsEntries.count, 6, "the hub and one entry per area page")
    }

    func testTipIDsAreUnique() {
        let ids = TipCatalog.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Ask AI's citations and the spotlight look tips up by id")
    }

    func testTipsThatLeanOnASecondDomainAreShown() {
        // Sunnah Reminders and the Tajweed Course need the Quran, Turn Over at Fajr the prayer times,
        // and Open the App On is Al-Islam's own control.
        for id in ["notif.sunnah", "islam.course", "islam.fajr", "app.launchtab"] {
            XCTAssertEqual(tip(id)?.isAvailable(), true, id)
        }
        let spotlight = TipCatalog.spotlight.map(\.id)
        XCTAssertTrue(spotlight.contains("notif.sunnah"))
        XCTAssertTrue(spotlight.contains("islam.fajr"))
    }

    func testPerAppWordingReadsAsBeforeInAlIslam() {
        XCTAssertEqual(tip("islam.askai")?.detail, "Ask AI answers from the Quran, the hadith collections, and the app's articles, on your device. Every citation opens its source, and wording it could not verify is marked as such.")
        XCTAssertEqual(tip("islam.font")?.detail, "The duas, the dhikr, the 99 Names, and the alphabet share one Arabic font, chosen here. The Quran and the hadith books keep their own.")
        XCTAssertEqual(tip("islam.journal")?.title, "A journal that gathers your notes")
        XCTAssertEqual(tip("islam.journal")?.detail, "The Islamic Journal collects the notes you leave on ayahs and hadiths beside your own entries. Swipe an entry to pin or delete it, and export everything as text from its menu.")
        XCTAssertEqual(tip("app.advanced")?.detail, "Two settings screens keep their fine-tuning behind Show Advanced Settings, at their foot: Prayer Calculation (custom angles, the high latitude rule) and Nagging Mode (how often it repeats, the last calls, its tone). Each has its own switch; every other screen shows everything it has. A search result or a tip marked Advanced turns the switch on for you.")
        XCTAssertEqual(tip("app.simple")?.detail, "Simple Mode keeps each tab to its essentials. Shortcuts move into a ⋯ menu at the top of the tab or into Settings, and extras like Need a Hand? and At a Glance step aside. Nothing is turned off, and turning it back off brings everything back. What Moves Where, on the Simple Mode page, lists every shortcut and where it went.")
        XCTAssertEqual(tip("app.helpdoors")?.detail, "Each tab keeps a Need a Hand? section: a few questions, each with the setting that answers it. Need Help Praying? on the prayer times opens Nagging Mode, Need Help Reading? on the Quran answers with Arabic Beginner Mode, and Reading in One Language? on the hadith picks the Arabic, the English or both. Hold a question for a quick switch, tap the arrow beside the header to fold them away, and use each tab's settings page (or Show on Every Tab, in Look and Feel) to hide them.")
        XCTAssertEqual(tip("app.helpdoors")?.place, "Adhan, Quran, Hadith and Islam tabs")
        XCTAssertEqual(TipCatalog.searchHint, "\"adhan\", \"tajweed\" or \"widget\"")
    }

    /// Islam is the one area with two colours, yellow into green, and the spotlight card, the chips
    /// and the hub rows all read them from here.
    func testIslamWearsBothColours() {
        XCTAssertEqual(TipArea.islam.tint, SettingsTint.islam)
        XCTAssertEqual(TipArea.islam.secondaryTint, SettingsTint.islamSecondary)
        XCTAssertNil(TipArea.adhan.secondaryTint)
        XCTAssertNil(TipArea.quran.secondaryTint)
        XCTAssertNil(TipArea.hadith.secondaryTint)
    }

    /// The 2026-10-19 audit: the features that had shipped without a tip have one, Test Mode's opens the
    /// screen that owns it and joins the Settings-tab cards, and the reworded tips say what changed.
    /// The count is pinned on purpose: a new tip is a conscious addition (the App Store copy quotes it).
    func testOctoberFeaturesHaveTips() {
        for id in ["quran.testmode", "quran.history", "quran.awake", "quran.controls", "adhan.controls",
                   "app.menushortcuts", "islam.locators"] {
            XCTAssertNotNil(tip(id), id)
        }
        XCTAssertEqual(TipCatalog.all.count, 158)

        if case .quranPage(let page)? = tip("quran.testmode")?.destination {
            XCTAssertEqual(page, .testMode)
        } else {
            XCTFail("Test Mode's tip opens Quran Settings, Test Mode")
        }
        XCTAssertEqual(tip("quran.testmode")?.tour, true)
        let spotlight = TipCatalog.spotlight.map(\.id)
        XCTAssertEqual(spotlight.count, 13)
        XCTAssertEqual(spotlight.prefix(3), ["notif.nagging", "adhan.travel", "quran.wordtap"],
                       "the welcome's discover page names the first three cards")
        XCTAssertTrue(spotlight.contains("quran.testmode"))

        XCTAssertEqual(tip("quran.planner")?.title, "Plan a khatm, or a revision")
        XCTAssertEqual(tip("quran.sort")?.title, "Eleven ways to sort")
        XCTAssertTrue(tip("quran.range")?.detail.contains("Play Range") == true)
        XCTAssertTrue(tip("quran.nowplaying")?.detail.contains("Range Ayahs") == true)
        XCTAssertTrue(tip("adhan.stopadhan")?.detail.contains("Play Automatically") == true)
        XCTAssertTrue(tip("adhan.weather")?.detail.contains("Try Another Sky") == true)
        XCTAssertEqual(tip("app.menushortcuts")?.detail, "Double tap the ⋯ menu at the top of the Quran, Hadith, Islam, and Settings tabs to switch between the grid and the list without opening it. On the Quran tab, holding it opens the Quran Planner. A single tap still opens the whole menu.")
    }
}
