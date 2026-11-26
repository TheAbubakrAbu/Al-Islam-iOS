import XCTest
@testable import iPhone

/// The Masjid Locator hides Shia, Sufi, Ahmadiyya and Nation of Islam places by what their name or
/// website says they are (2026-11-25). These pin both sides: what must go, and the near misses a
/// careless word list would also throw away (a Companion's name, a city, a family name, Hagia Sophia).
final class PlaceLocatorExclusionTests: XCTestCase {
    private let exclusion = PlaceLocatorExclusion.shiaSufiAndOthers

    func testHidesPlacesNamedForWhatTheyAre() {
        let hidden = [
            "Shia Ithna'ashari Jamaat of Toronto",
            "Shiʿa Islamic Center",
            "Islamic Shia Ithna-Asheri Jamaat",
            "Jafaria Islamic Society",
            "Imambargah Hussainia",
            "Hussainiya Al-Zahra",
            "Imam Hussain Islamic Center",
            "Imam-e-Zamana Mosque",
            "Imam Reza Center",
            "Ahlul Bayt Islamic Center",
            "Ahl-ul-Bayt Society",
            "Zainabia Centre",
            "Ismaili Jamatkhana",
            "Jamat Khana",
            "Dawoodi Bohra Masjid",
            "Alevi Cemevi",
            "Sufi Center",
            "Naqshbandi Haqqani Sufi Order",
            "Zawiya of Shaykh Ahmad",
            "Khanqah Chishtiya",
            "Dargah Sharif",
            "Tijaniyya Zawiyah",
            "Jamia Masjid Ghousia",
            "Ahmadiyya Muslim Community Baitul Futuh",
            "Nation of Islam Mosque No. 7",
            "مسجد الشيعة",
            "حسينية الرسول الأعظم",
            "الطريقة الصوفية",
            "امام بارگاہ",
        ]
        for name in hidden {
            XCTAssertTrue(exclusion.excludes(name: name), "should hide: \(name)")
        }
    }

    func testKeepsSunniMasaajidThatOnlyShareAWord() {
        let kept = [
            "Masjid Ali",
            "Ali ibn Abi Talib Mosque",
            "Al-Husayn Mosque",
            "Masjid Hasan al-Basri",
            "Masjid Sufyan ath-Thawri",
            "Masjid Abu Sufian",
            "Ayasofya Camii",
            "Hagia Sophia Grand Mosque",
            "آيا صوفيا",
            "مسجد الإسماعيلية الكبير",
            "Masjid Ismailia",
            "Masjid Rahma",
            "Islamic Center of Imam Bukhari",
            "Masjid al-Imam Ahmad",
            "Masjid Fatimah az-Zahra",
            "Masjid Dawood",
            "Mawlawi Abdul Rahman Masjid",
            "Al-Rifai Family Mosque",
            "Masjid Tijani Adekunle",
            "Darul Uloom",
            "Masjid Ibrahim",
        ]
        for name in kept {
            XCTAssertFalse(exclusion.excludes(name: name), "should keep: \(name)")
        }
    }

    /// What MapKit really returned around Thornhill, Ontario on 2026-11-25 (names and websites as given).
    func testRealResultsAroundToronto() throws {
        let hidden: [(String, String?)] = [
            ("Islamic Shia Ithna Asheri Jamaat of Toronto", "https://www.jaffari.org"),
            ("Imam Mahdi Islamic Centre", nil),
            ("Anjuman-e-Burhani", "https://www.torontojamat.com/"),
            ("Imam Bargha Qasr-e-Zainab s.a", "https://qasrezainab.com"),
            ("Hussainiyat AlHawraa Zaynab AlKarbalaeia", "https://www.facebook.com/hazahusseinia"),
            ("Islamic Museum", "http://www.husainiyah.com"),
            ("Unionville Jamatkhana", "http://ismaili.net"),
            ("Ismaili Jamatkhana & Centre-Willowdale", "http://the.ismaili/"),
            ("Baitul Islam Mosque", "https://ahmadiyya.ca/content/baitul-islam-mosque"),
            ("Baitul ‘Afiyat Mosque", "https://www.ahmadiyya.ca"),
            ("Baitul Wahid Mosque - Ahmadiyya Mosque Toronto West", nil),
        ]
        for (name, site) in hidden {
            XCTAssertTrue(exclusion.excludes(name: name, website: site.flatMap(URL.init(string:))), "should hide: \(name)")
        }
        let kept: [(String, String?)] = [
            ("Masjid Vaughan", "http://masjidvaughan.ca"),
            ("Islamic Society of Vaughan", "http://www.islamicsocietyvaughan.com"),
            ("Mevlana Masjid", "https://a-than.info/vv.php?code=MEVLANA01"),
            ("Süleymaniye Mosque", nil),
            ("TARIC Islamic Centre", "https://taric.org"),
            ("Talim-ul-Islam", "https://talimul.com/TuiSite/"),
            ("Khalid Bin Al-Walid Mosque", "http://www.khalidmosque.com"),
            ("Al-Bukhari Community Center", "https://ajrcanada.com/about/"),
            ("Abu Ubaydah Islamic Center", "https://www.abuubaydah.org/"),
            ("Islamic Society of Toronto - Masjid Darussalam", "https://www.islamicsocietyoftoronto.com"),
        ]
        for (name, site) in kept {
            XCTAssertFalse(exclusion.excludes(name: name, website: site.flatMap(URL.init(string:))), "should keep: \(name)")
        }
    }

    func testReadsTheWebsiteButNeverTheAddress() throws {
        let shiaSite = try XCTUnwrap(URL(string: "https://www.shiacenter.org/about"))
        XCTAssertTrue(exclusion.excludes(name: "Islamic Center of Springfield", website: shiaSite))

        let ahmadiyyaSite = try XCTUnwrap(URL(string: "https://www.alislam.org/mosques/"))
        XCTAssertTrue(exclusion.excludes(name: "Baitur Rahman Mosque", website: ahmadiyyaSite))

        let sufiSite = try XCTUnwrap(URL(string: "https://naqshbandi.org"))
        XCTAssertTrue(exclusion.excludes(name: "Community Masjid", website: sufiSite))

        // "alislam.org" inside a longer host is a different site: Dar al-Islam, a Sunni one.
        let darAlIslam = try XCTUnwrap(URL(string: "https://daralislam.org"))
        XCTAssertFalse(exclusion.excludes(name: "Dar al-Islam", website: darAlIslam))

        // "ashiana" carries "shia" inside it, not at either end.
        let ashiana = try XCTUnwrap(URL(string: "https://ashianamasjid.org"))
        XCTAssertFalse(exclusion.excludes(name: "Ashiana Masjid", website: ashiana))
    }

    func testFoldingMakesWholeWords() {
        XCTAssertEqual(PlaceLocatorExclusion.folded("Shi'a"), " shia ")
        XCTAssertEqual(PlaceLocatorExclusion.folded("Shiʿa"), " shia ")
        XCTAssertEqual(PlaceLocatorExclusion.folded("Ahl-ul-Bayt"), " ahl ul bayt ")
        XCTAssertEqual(PlaceLocatorExclusion.folded("  Ithna-‘Asharī  "), " ithna ashari ")
    }

    func testHalalFoodHidesNothing() {
        XCTAssertFalse(PlaceLocatorProfile.halalFood.exclusion.excludes(name: "Sufi Kebab House"))
        XCTAssertTrue(PlaceLocatorProfile.masjid.exclusion.excludes(name: "Sufi Center"))
    }
}
