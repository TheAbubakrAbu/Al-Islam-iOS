#if os(iOS)
import SwiftUI
import MapKit
import CoreLocation
import UIKit
import Contacts

// The Masjid Locator and the Halal Food Locator: one map, one search and one results panel over two
// profiles. Redesigned 2026-11-24 (Abu: "revamp ... the two locators they look chopped horrible ui
// horrible experience and too cramped", "add more functionality more filters more search more
// specification"): the search bar with the profile's KINDS as chips under it (Islamic Centers, Prayer
// Rooms; Restaurants, Markets & Butchers), the map with tappable pins and a "Search This Area" that
// appears once the map has moved, and a results panel at the foot. Folded, the panel is the chosen
// place's card (the nearest, until one is picked): its kind, distance and address, and Directions,
// Call, Website and Share. Unfolded, it is the whole list, sorted nearest first or by name, held to a
// distance, with the dishes to search for on the halal side, and a way to look a typed city up and
// search there instead. The old panel was a 150 pt strip that showed two results at a time.

/// One narrowing of a locator's search, a chip under the search bar.
struct PlaceLocatorKind: Identifiable, Hashable {
    let id: String
    let title: String
    let systemImage: String
    /// What an empty search bar looks for under this chip.
    let baseQueries: [String]
    /// How the reader's own words are expanded into queries under this chip.
    let queries: (String) -> [String]
    /// Post-filter on result names/titles. Empty trusts MapKit's relevance ranking: right for a query
    /// like "halal", where most matching restaurants don't carry the word in their name.
    let nameKeywords: [String]
    /// Category filter handed to MKLocalSearch. Nil means all point-of-interest kinds.
    let poiCategories: [MKPointOfInterestCategory]?

    var poiFilter: MKPointOfInterestFilter? {
        poiCategories.map { MKPointOfInterestFilter(including: $0) }
    }

    static func == (lhs: PlaceLocatorKind, rhs: PlaceLocatorKind) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// The places a locator never lists, whatever MapKit returned for the search (Abu, 2026-11-25: "Hide
/// Shia and Sufi masaajid if it says that in the name or description"). MapKit hands a place no
/// description, so the two texts it does carry are read: the NAME and the WEBSITE address.
///
/// Only words that say what the place IS count: "Shia", "Ja'fari", "Imambargah", "Hussainiya",
/// "Jamatkhana", "Sufi", "Zawiya", "Khanqah", "Dargah", a tariqa's name. A Companion's or a
/// Household member's name alone never hides a masjid ("Masjid Ali", "Al-Husayn Mosque" stay); the
/// Shia imams' TITLES do ("Imam Hussain Center", "Imam Reza", "Imam-e-Zamana"). Ahmadiyya and Nation of
/// Islam places are hidden on the same terms. The address is never read: a Sunni masjid on Imam Ali
/// Street stays.
struct PlaceLocatorExclusion: Sendable {
    /// Folded words and phrases (`folded(_:)`'s form), matched whole in the name and in the website.
    let terms: [String]
    /// Lowercased stems matched anywhere in the website's host and path, where words run together
    /// ("shiacenter.org"). Only stems no Sunni masjid's address would contain.
    let websiteStems: [String]
    /// Whole sites (and their subdomains) that belong to a hidden group: "alislam.org" is a stem inside
    /// "daralislam.org", so it is matched as a host, never as a stem.
    let websiteHosts: [String]

    static let none = PlaceLocatorExclusion(terms: [], websiteStems: [], websiteHosts: [])

    func excludes(name: String?, website: URL? = nil) -> Bool {
        guard !terms.isEmpty else { return false }
        if let name, Self.containsTerm(terms, in: Self.folded(name)) { return true }
        guard let website else { return false }
        let host = (website.host ?? "").lowercased()
        let bareHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        if websiteHosts.contains(where: { bareHost == $0 || bareHost.hasSuffix("." + $0) }) { return true }
        let raw = host + " " + website.path
        if Self.containsTerm(terms, in: Self.folded(raw)) { return true }
        let lowered = raw.lowercased()
        if websiteStems.contains(where: lowered.contains) { return true }
        // "shiacenter", "islamicshia": the word at either end of a run-together host word.
        return Self.folded(raw).split(separator: " ").contains { $0.hasPrefix("shia") || $0.hasSuffix("shia") }
    }

    private static func containsTerm(_ terms: [String], in folded: String) -> Bool {
        terms.contains { folded.contains(" \($0) ") }
    }

    /// Lowercased, accents and Arabic vowel marks gone, apostrophes and ʿayn marks dropped
    /// ("Shi'a", "Shiʿa" -> "shia"), every other mark a space ("Ahl-ul-Bayt" -> "ahl ul bayt"), padded
    /// with a space at each end so a term matches only as whole words.
    static func folded(_ text: String) -> String {
        let lowered = text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
        var out = String.UnicodeScalarView()
        var pendingSpace = false
        for scalar in lowered.unicodeScalars {
            switch scalar.properties.generalCategory {
            case .modifierLetter, .nonspacingMark, .spacingMark, .enclosingMark:
                continue
            case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter, .otherLetter, .decimalNumber:
                if pendingSpace, !out.isEmpty { out.append(" ") }
                pendingSpace = false
                out.append(scalar)
            default:
                if "'’‘`´".unicodeScalars.contains(scalar) { continue }
                pendingSpace = true
            }
        }
        return " " + String(out) + " "
    }

    static let shiaSufiAndOthers = PlaceLocatorExclusion(
        terms: [
            // Shia, Twelver and Ja'fari
            "shia", "shiah", "shiite", "shiites", "shiism", "ithna ashari", "ithna asheri", "ithna ashri",
            "ithnaashari", "ithnaasheri", "isna ashari", "twelver", "jafari", "jafaria", "jafariya",
            "jafariyya", "jafariyah", "jaffari", "jaffaria", "jafria", "jafriya", "imamia", "imamiya", "imamiyya",
            "imamiyah", "imambargah", "imambargha", "imambara", "imambarah", "imambada", "imam bargah",
            "imam bargha", "imam bara", "imam bada", "hussainiya", "hussainiyah", "hussainia", "hussainiyya",
            "husainiya", "husainiyah", "husainia", "husseiniya", "husseiniyah", "husseinia", "husayniyya",
            "husayniyyah", "husayniya", "hussainiyat", "husainiyat", "husseiniyat", "husayniyyat", "hosseinieh", "hoseinieh", "hosseiniyeh", "huseyniye", "zainabia",
            "zainabiya", "zainabiyya", "zaynabiya", "zaynabiyya", "ahlul bayt", "ahl ul bayt", "ahl al bayt",
            "ahlulbayt", "ahlulbait", "ahlul bait", "ahl ul bait", "ahle bait", "ahle bayt", "ahl e bait",
            "ahl e bayt", "ahlebait", "ahlebayt", "panjtan", "panjetan", "al khoei", "alkhoei", "khoei",
            "imam hussain", "imam husain", "imam hussein", "imam husayn", "imam hossein", "imam hosein",
            "imam ali", "imam reza", "imam rida", "imam ridha", "imam mahdi",
            "imam al mahdi", "imam e zamana", "imam e zaman", "imam zamana", "imam zaman", "imam sadiq",
            "imam al sadiq", "imam jafar", "imam baqir", "imam al baqir", "imam kazim", "imam kadhim",
            "imam musa kazim", "imam sajjad", "imam zainul abideen", "imam zain ul abideen", "imam taqi",
            "imam naqi", "imam askari", "masoomeen", "masumeen", "masoomin", "maasoomeen",
            // Isma'ili, Bohra, Alevi
            "ismaili", "ismailis", "ismaeli", "nizari", "jamatkhana", "jamat khana", "jamaatkhana",
            "jamaat khana", "aga khan", "bohra", "bohras", "alevi", "alevis", "cemevi", "cem evi",
            // The Dawoodi Bohra jamaats take these names ("Anjuman-e-Burhani", "Saifee Masjid")
            "anjuman e burhani", "anjumane burhani", "anjuman e saifee", "anjuman e najmi", "anjuman e ezzi",
            "anjuman e fakhri", "anjuman e hakimi", "anjuman e taiyebi", "anjuman e shujaee", "anjuman e jamali",
            "anjuman e qutbi", "anjuman e zainee", "burhani masjid", "masjid e burhani", "saifee masjid",
            "saifiyah masjid",
            // Sufi: the word, its lodges and shrines, and the orders by name
            "sufi", "sufis", "sufism", "sufiyya", "tasawwuf", "tariqa", "tariqah", "tariqat", "tarikat",
            "tarekat", "zawiya", "zawiyah", "zawiyya", "zaouia", "zaouiya", "khanqah", "khanqa", "khanaqah",
            "khanaqa", "khaneqah", "khankah", "dargah", "dargha", "durgah", "darbar", "tekke", "tekija",
            "tekiya", "tekkesi", "dergah", "dergahi", "naqshbandi", "naqshbandiya", "naqshbandiyya",
            "naqshbandia", "nakshbandi", "nakshibendi", "naksibendi", "qadiriyya", "qadiriya", "qadiriyyah",
            "qadria", "qadriya", "ghousia", "ghousiya", "ghausia", "ghausiya", "gausia", "gausiya", "chishti",
            "chishtiya", "chishtiyya", "chishtia", "chisti", "tijaniyya", "tijaniya", "tidjania", "shadhiliyya",
            "shadhiliya", "rifaiyya", "rifaiya", "mevlevi", "mevlevihane", "halveti", "khalwati", "jerrahi", "cerrahi", "bektashi",
            "bektasi", "ba alawi", "baalawi", "alawiyya", "mouride", "mourides", "muridiyya", "qalandar",
            "qalandari", "suhrawardi", "suhrawardiyya",
            // Ahmadiyya and the Nation of Islam
            "ahmadiyya", "ahmadiya", "ahmadiyyah", "ahmadiyyat", "ahmadi muslim", "ahmadi muslims", "qadiani",
            "qadiyani", "mirzai", "nation of islam", "moorish science",
            // Arabic, Persian, Urdu
            "شيعة", "الشيعة", "شيعي", "الشيعي", "الشيعية", "شیعه", "شیعہ", "الجعفرية", "جعفرية", "جعفریہ",
            "حسينية", "الحسينية", "حسينيه", "حسینیه", "حسینیہ", "امامباره", "امامبارگاه", "امام بارگاه",
            "امام بارگاہ", "امامبارگاہ", "امام باڑہ", "امامباڑہ",
            "صوفي", "الصوفي", "الصوفية", "صوفية", "صوفیہ", "صوفیه", "زاوية", "الزاوية", "خانقاه", "خانقاہ",
            "درگاه", "درگاہ", "دربار", "الطريقة", "تكية", "التكية", "الأحمدية", "الاحمدية", "احمدیہ", "قادیانی",
        ].map { folded($0).trimmingCharacters(in: .whitespaces) },
        websiteStems: [
            "shiite", "ithnaashari", "ithnaasheri", "jafaria", "imamia", "imambargah", "imambara", "hussainia",
            "hussainiy", "husainia", "husainiy", "husseinia", "husseiniy", "husayniy", "hosseinieh", "zainabia", "zainabiya", "ahlulbayt", "ahlulbait",
            "alkhoei", "jamatkhana", "jamaatkhana", "dawoodibohra", "sufism", "sufiorder", "tariqa", "zawiya",
            "khanqah", "dargah", "naqshbandi", "chishtiya", "tijaniyya", "shadhiliyya", "ahmadiyya", "nationofislam",
        ],
        websiteHosts: ["alislam.org", "ahmadiyya.us", "ahmadiyya.ca", "ahmadiyya.org.uk", "noi.org", "finalcall.com"]
    )
}

/// A search the halal side offers in one tap ("Shawarma"): its label, and the words MapKit is given.
struct PlaceLocatorQuickSearch: Identifiable, Hashable {
    let title: String
    let query: String
    var id: String { query }
}

/// Everything that distinguishes one place locator from another.
struct PlaceLocatorProfile {
    let title: String
    /// Shown next to the spinner in the results header.
    let loadingText: String
    /// Shown while the first search of an area is in flight.
    let searchingText: String
    let emptyText: String
    /// Stands in for a result whose POI has no name.
    let fallbackName: String
    let contextMenuTitle: String
    let searchPrompt: String
    /// The pin's symbol.
    let markerSymbol: String
    /// The chips; the first is the whole search ("All").
    let kinds: [PlaceLocatorKind]
    /// One-tap searches under the list's header.
    let quickSearches: [PlaceLocatorQuickSearch]
    /// Where the home-area results are cached, so each locator remembers its own neighbourhood; the
    /// distance and sort choices are kept under keys made from it too.
    let homeCacheKey: String
    /// Places never listed, whatever the search found.
    var exclusion: PlaceLocatorExclusion = .none

    /// Mosques have no MKPointOfInterestCategory, so the masjid profile filters by name instead,
    /// including the Arabic spellings: a masjid named only مسجد… never matched the Latin-only keyword
    /// list even when MapKit returned it.
    static let masjid = PlaceLocatorProfile(
        title: String(localized: "Masjid Locator"),
        loadingText: String(localized: "Loading masaajid…"),
        searchingText: String(localized: "Searching nearby masaajid…"),
        emptyText: String(localized: "No masaajid found in this area"),
        fallbackName: String(localized: "Masjid"),
        contextMenuTitle: String(localized: "Masjid Info"),
        searchPrompt: String(localized: "Search masaajid, or a city"),
        markerSymbol: "moon.stars.fill",
        kinds: [
            PlaceLocatorKind(
                id: "all", title: String(localized: "All"), systemImage: "square.grid.2x2",
                baseQueries: ["mosque", "masjid", "islamic center", "muslim", "rahma", "مسجد"],
                queries: { text in
                    unique([text, "\(text) mosque", "\(text) masjid", "\(text) islamic", "\(text) islamic center",
                            "\(text) muslim", "\(text) rahma"])
                },
                nameKeywords: ["masjid", "mosque", "islam", "islamic", "muslim", "rahma", "musalla", "مسجد", "جامع"],
                poiCategories: nil),
            PlaceLocatorKind(
                id: "masjids", title: String(localized: "Masaajid"), systemImage: "moon.stars",
                baseQueries: ["mosque", "masjid", "jamia masjid", "مسجد", "جامع"],
                queries: { text in unique(["\(text) mosque", "\(text) masjid", text]) },
                nameKeywords: ["masjid", "mosque", "jamia", "jame", "مسجد", "جامع"],
                poiCategories: nil),
            PlaceLocatorKind(
                id: "centers", title: String(localized: "Islamic Centers"), systemImage: "building.2",
                baseQueries: ["islamic center", "islamic society", "muslim community center", "islamic association"],
                queries: { text in unique(["\(text) islamic center", "\(text) islamic society", "\(text) muslim"]) },
                nameKeywords: ["islamic", "muslim", "islam"],
                poiCategories: nil),
            PlaceLocatorKind(
                id: "prayerRooms", title: String(localized: "Prayer Rooms"), systemImage: "house",
                baseQueries: ["musalla", "musallah", "muslim prayer room", "prayer room"],
                queries: { text in unique(["\(text) musalla", "\(text) prayer room", text]) },
                nameKeywords: ["musalla", "musallah", "prayer room", "prayer space", "مصلى"],
                poiCategories: nil),
            PlaceLocatorKind(
                id: "schools", title: String(localized: "Islamic Schools"), systemImage: "graduationcap",
                baseQueries: ["islamic school", "quran school", "madrasa", "hifz school", "islamic academy"],
                queries: { text in unique(["\(text) islamic school", "\(text) quran school", "\(text) madrasa"]) },
                nameKeywords: ["islamic", "quran", "madrasa", "madrassa", "madrasah", "hifz", "muslim", "مدرسة"],
                poiCategories: nil),
        ],
        quickSearches: [],
        homeCacheKey: "masjidLocatorHomeCacheData",
        exclusion: .shiaSufiAndOthers
    )

    /// Food is the opposite shape from mosques: the category filter does the narrowing (restaurants,
    /// cafes, markets, not hotels and gas stations), and the "halal" relevance comes from the query
    /// itself, because most halal restaurants don't have "halal" in their NAME and a name filter would
    /// throw them away. `.store` stays out: it let any supermarket that ranked near a "halal X" query
    /// through, and with no name filter there was nothing downstream to catch it.
    static let halalFood = PlaceLocatorProfile(
        title: String(localized: "Halaal Food Locator"),
        loadingText: String(localized: "Loading halaal places…"),
        searchingText: String(localized: "Searching nearby halaal food…"),
        emptyText: String(localized: "No halaal places found in this area"),
        fallbackName: String(localized: "Halaal Place"),
        contextMenuTitle: String(localized: "Place Info"),
        searchPrompt: String(localized: "Search a dish, a place, or a city"),
        markerSymbol: "fork.knife",
        kinds: [
            PlaceLocatorKind(
                id: "all", title: String(localized: "All"), systemImage: "square.grid.2x2",
                baseQueries: ["halal restaurant", "halal food", "halal market", "halal butcher", "حلال"],
                queries: halalQueries,
                nameKeywords: [],
                poiCategories: [.restaurant, .cafe, .bakery, .foodMarket]),
            PlaceLocatorKind(
                id: "restaurants", title: String(localized: "Restaurants"), systemImage: "fork.knife",
                baseQueries: ["halal restaurant", "halal food", "halal grill"],
                queries: halalQueries,
                nameKeywords: [],
                poiCategories: [.restaurant]),
            PlaceLocatorKind(
                id: "quick", title: String(localized: "Quick Bites"), systemImage: "takeoutbag.and.cup.and.straw",
                baseQueries: ["halal cart", "halal fast food", "halal shawarma", "halal burger", "halal fried chicken"],
                queries: halalQueries,
                nameKeywords: [],
                poiCategories: [.restaurant, .cafe]),
            PlaceLocatorKind(
                id: "cafes", title: String(localized: "Cafés & Sweets"), systemImage: "cup.and.saucer",
                baseQueries: ["halal cafe", "halal bakery", "halal desserts"],
                queries: halalQueries,
                nameKeywords: [],
                poiCategories: [.cafe, .bakery]),
            PlaceLocatorKind(
                id: "markets", title: String(localized: "Markets & Butchers"), systemImage: "cart",
                baseQueries: ["halal market", "halal butcher", "halal meat", "halal grocery"],
                queries: halalQueries,
                nameKeywords: [],
                poiCategories: [.foodMarket]),
        ],
        quickSearches: [
            PlaceLocatorQuickSearch(title: String(localized: "Shawarma"), query: "shawarma"),
            PlaceLocatorQuickSearch(title: String(localized: "Burgers"), query: "burger"),
            PlaceLocatorQuickSearch(title: String(localized: "Fried Chicken"), query: "fried chicken"),
            PlaceLocatorQuickSearch(title: String(localized: "Pizza"), query: "pizza"),
            PlaceLocatorQuickSearch(title: String(localized: "Kebab"), query: "kebab"),
            PlaceLocatorQuickSearch(title: String(localized: "Biryani"), query: "biryani"),
            PlaceLocatorQuickSearch(title: String(localized: "Mandi"), query: "mandi"),
            PlaceLocatorQuickSearch(title: String(localized: "Desserts"), query: "desserts"),
        ],
        homeCacheKey: "halalLocatorHomeCacheData"
    )

    private static func halalQueries(_ text: String) -> [String] {
        unique(["\(text) halal", "halal \(text)", text])
    }

    private static func unique(_ queries: [String]) -> [String] {
        var seen = Set<String>()
        return queries.filter { seen.insert($0).inserted }
    }
}

struct PlaceLocatorView: View {
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// Prayer times and the location publish from `LiveState`, not `Settings` (see its comment).
    @ObservedObject private var live = LiveState.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var sysScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let profile: PlaceLocatorProfile

    @AppStorage private var homeCacheData: Data
    /// The distance the list is held to, as an index into `radiusSteps` (0: any distance).
    @AppStorage private var radiusIndex: Int
    /// "distance" or "name".
    @AppStorage private var sortRaw: String

    @State private var searchText = ""
    @State private var kind: PlaceLocatorKind
    @State private var results = [MKMapItem]()
    @State private var selectedItem: MKMapItem?
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?
    /// The panel shows the whole list, rather than the chosen place's card.
    @State private var panelExpanded = false
    /// Where the last search looked: "Search This Area" appears once the map has moved off it.
    @State private var lastSearchCenter: CLLocationCoordinate2D?
    /// A typed city being looked up on the map, and the one that could not be found.
    @State private var lookingUpPlace = false
    @State private var placeNotFound: String?
    @State private var containerHeight: CGFloat = 800
    /// The map opened without a fix (fresh install, or permission granted just now); when the first real
    /// location arrives, recenter on it once and re-search - without this, a first-time user stared at the
    /// Kaaba fallback with no nearby results and no way to know why.
    @State private var awaitingFirstFix = false

    @State private var region = MKCoordinateRegion(
        center: .init(latitude: 21.422445, longitude: 39.826388),
        span: .init(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )

    private static let homeCacheMatchDistanceMeters: CLLocationDistance = 150
    private static let homeRefreshRadiusMeters: CLLocationDistance = 10_000

    private var scheme: ColorScheme { settings.colorScheme ?? sysScheme }
    private var accent: Color { settings.accentColor.color }

    private var homeCoordinate: CLLocationCoordinate2D? {
        settings.homeLocation?.coordinate
    }

    init(profile: PlaceLocatorProfile) {
        self.profile = profile
        _homeCacheData = AppStorage(wrappedValue: Data(), profile.homeCacheKey)
        _radiusIndex = AppStorage(wrappedValue: 0, profile.homeCacheKey + ".radius")
        _sortRaw = AppStorage(wrappedValue: SortOrder.distance.rawValue, profile.homeCacheKey + ".sort")
        _kind = State(initialValue: profile.kinds[0])

        let coord: CLLocationCoordinate2D = {
            let s = Settings.shared
            if let cur = s.currentLocation, cur.latitude != 1000, cur.longitude != 1000 {
                return cur.coordinate
            }
            if let home = s.homeLocation {
                return home.coordinate
            }
            return .init(latitude: 21.422445, longitude: 39.826388)
        }()

        _region = State(initialValue: MKCoordinateRegion(
            center: coord,
            span: .init(latitudeDelta: 0.15, longitudeDelta: 0.15)
        ))
    }

    private var hasRealLocation: Bool {
        if let cur = live.currentLocation, cur.latitude != 1000, cur.longitude != 1000 { return true }
        return false
    }

    // MARK: Sorting and distance

    private enum SortOrder: String, CaseIterable {
        case distance, name

        var title: String {
            switch self {
            case .distance: return String(localized: "Nearest First")
            case .name: return String(localized: "By Name")
            }
        }

        var systemImage: String {
            switch self {
            case .distance: return "location.north.line"
            case .name: return "textformat"
            }
        }
    }

    private var sortOrder: SortOrder { SortOrder(rawValue: sortRaw) ?? .distance }

    /// Miles where the reader's region measures in them (the US, the UK), kilometres elsewhere.
    private var usesMiles: Bool { Locale.current.measurementSystem != .metric }

    /// The distances the list can be held to, in the reader's unit; 0 is any distance.
    private static let radiusSteps: [Double] = [0, 1, 3, 5, 10, 25]

    private var radius: Double { Self.radiusSteps.indices.contains(radiusIndex) ? Self.radiusSteps[radiusIndex] : 0 }

    private var radiusMeters: CLLocationDistance? {
        radius == 0 ? nil : radius * (usesMiles ? 1_609.344 : 1_000)
    }

    private func distanceText(_ meters: CLLocationDistance) -> String {
        let unit: UnitLength = usesMiles ? .miles : .kilometers
        let value = Measurement(value: meters, unit: UnitLength.meters).converted(to: unit)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = value.value < 10 ? 1 : 0
        return formatter.string(from: value)
    }

    private func radiusTitle(_ step: Double) -> String {
        step == 0 ? String(localized: "Any Distance")
            : String(localized: "Within \(distanceText(step * (usesMiles ? 1_609.344 : 1_000)))")
    }

    /// Where distances are measured from: the reader, when the app has a fix; nil otherwise.
    private var origin: CLLocation? {
        guard let cur = live.currentLocation, cur.latitude != 1000, cur.longitude != 1000 else { return nil }
        return CLLocation(latitude: cur.latitude, longitude: cur.longitude)
    }

    private func distance(to item: MKMapItem) -> CLLocationDistance? {
        guard let origin else { return nil }
        let coordinate = item.placemark.coordinate
        return origin.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }

    // MARK: Markers

    private struct MarkerItem: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let tint: Color
        let systemImage: String
        var title: String? = nil
        var isSelected = false
        /// The result this pin stands for, by its index in `results`.
        var resultIndex: Int? = nil
    }

    private struct CachedPlaceItem: Codable, Equatable {
        let name: String?
        let latitude: Double
        let longitude: Double
        let subThoroughfare: String?
        let thoroughfare: String?
        let locality: String?
        let administrativeArea: String?
        let postalCode: String?
        let country: String?

        init(item: MKMapItem) {
            name = item.name
            latitude = item.placemark.coordinate.latitude
            longitude = item.placemark.coordinate.longitude
            subThoroughfare = item.placemark.subThoroughfare
            thoroughfare = item.placemark.thoroughfare
            locality = item.placemark.locality
            administrativeArea = item.placemark.administrativeArea
            postalCode = item.placemark.postalCode
            country = item.placemark.country
        }

        func mapItem() -> MKMapItem {
            let address = CNMutablePostalAddress()
            address.street = [subThoroughfare, thoroughfare]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            address.city = locality ?? ""
            address.state = administrativeArea ?? ""
            address.postalCode = postalCode ?? ""
            address.country = country ?? ""

            let placemark = MKPlacemark(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                postalAddress: address
            )
            let item = MKMapItem(placemark: placemark)
            item.name = name
            return item
        }
    }

    private struct CachedPlaceHomeResults: Codable, Equatable {
        let homeLocation: Location
        let savedAt: Date
        let items: [CachedPlaceItem]
    }

    private struct AnimatedMarkerBubble: View {
        let tint: Color
        let systemImage: String
        var title: String? = nil
        var isSelected = false

        @State private var isVisible = false

        var body: some View {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: isSelected ? 17 : 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: isSelected ? 40 : 30, height: isSelected ? 40 : 30)
                    .background(Circle().fill(tint))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.9), lineWidth: isSelected ? 2.5 : 2)
                    )
                    .shadow(color: .black.opacity(0.22), radius: isSelected ? 8 : 5, y: 2)
            }
            // No name under the chosen pin: MapKit gives annotations no stacking order, so its
            // neighbours drew over the label. The panel's card names the place.
            .accessibilityLabel(Text(title ?? ""))
            .scaleEffect(isVisible ? 1 : 0.72)
            .opacity(isVisible ? 1 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isSelected)
            .onAppear {
                // Annotation views are built inside the Map's own update, where this onAppear
                // fires synchronously; a state write there is "Modifying state during view
                // update". One turn later the pop-in animates the same.
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        isVisible = true
                    }
                }
            }
        }
    }

    private var markers: [MarkerItem] {
        var items: [MarkerItem] = []

        if let cur = live.currentLocation,
           cur.latitude != 1000,
           cur.longitude != 1000 {
            items.append(
                MarkerItem(
                    id: "current",
                    coordinate: cur.coordinate,
                    tint: .cyan,
                    systemImage: "location.fill"
                )
            )
        }

        // The chosen pin last, so it draws above its neighbours.
        let pins = results.enumerated().map { index, item in
            MarkerItem(
                id: "result-\(index)-\(item.placemark.coordinate.latitude)-\(item.placemark.coordinate.longitude)",
                coordinate: item.placemark.coordinate,
                tint: isSameItem(item, selectedItem) ? .green : accent,
                systemImage: profile.markerSymbol,
                title: item.name ?? profile.fallbackName,
                isSelected: isSameItem(item, selectedItem),
                resultIndex: index
            )
        }
        items += pins.filter { !$0.isSelected } + pins.filter(\.isSelected)
        return items
    }

    // MARK: Body

    var body: some View {
        mapContent
            .edgesIgnoringSafeArea(.all)
            .background(
                // The whole screen's height, not the safe area's: the panel is itself the bottom
                // inset, so a safe-area reading shrank as the panel grew and held the list to a row.
                GeometryReader { geo in
                    Color.clear
                        .onAppear { containerHeight = geo.size.height }
                        .onChange(of: geo.size.height) { containerHeight = $0 }
                }
                .ignoresSafeArea()
            )
            .overlay(alignment: .top) {
                topControls
            }
            .sheetNowPlayingBar()
            // Over a map the bar floats: no scroll-edge ground behind it.
            .adaptiveSafeArea(edge: .bottom, groundsBar: false) {
                bottomStack
            }
            .navigationTitle(profile.title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // This screen is all about "near me", so it asks for location itself instead of assuming the
                // prayer-times flow already did. No-op when already granted or denied.
                settings.requestLocationAuthorization()
                // One turn later, not inside this update: `init` already centred the map, and a
                // `region` write here lands in the same update the Map is built in, where the
                // deprecated `coordinateRegion` binding writes back ("Modifying state during view
                // update" in the log).
                DispatchQueue.main.async {
                    awaitingFirstFix = !hasRealLocation
                    configureInitialRegion()
                    loadCachedHomeResultsIfPossible()
                    scheduleSearch(for: "", force: true)
                    warmHomeCacheIfNeeded()
                }
            }
            .onChange(of: searchText) { newValue in
                placeNotFound = nil
                scheduleSearch(for: newValue, force: false)
            }
            .onChange(of: kind) { _ in scheduleSearch(for: searchText, force: true) }
            .onChange(of: radiusIndex) { _ in
                // A wider circle needs a wider search, not only a looser filter.
                if let radiusMeters { fitRegion(toRadius: radiusMeters) }
                scheduleSearch(for: searchText, force: true)
            }
            .onChange(of: sortRaw) { _ in
                withAnimation(.easeInOut(duration: 0.2)) { results = arranged(results) }
            }
            // A fan-out of ~6 concurrent MKLocalSearch requests started just before leaving would run to
            // completion for a screen nobody is looking at - cancel it with the screen.
            .onDisappear { searchTask?.cancel() }
            .onReceive(live.$currentLocation) { location in
                guard awaitingFirstFix,
                      let location, location.latitude != 1000, location.longitude != 1000 else { return }
                awaitingFirstFix = false
                updateRegion(to: location.coordinate)
                scheduleSearch(for: searchText, force: true)
            }
            .preferredColorScheme(scheme)
            .accentColor(accent)
            .tint(accent)
    }

    @ViewBuilder
    private var mapContent: some View {
        if #available(iOS 17.0, *) {
            CameraMap(region: $region, markers: markers) { index in
                guard results.indices.contains(index) else { return }
                select(results[index])
            }
        } else {
            Map(coordinateRegion: $region, annotationItems: markers) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    AnimatedMarkerBubble(tint: item.tint, systemImage: item.systemImage, title: item.title,
                                         isSelected: item.isSelected)
                        .onTapGesture {
                            guard let index = item.resultIndex, results.indices.contains(index) else { return }
                            select(results[index])
                        }
                }
            }
        }
    }

    /// `MKCoordinateRegion` is not Equatable; this is the part of it a camera move can change.
    private struct RegionKey: Equatable {
        let latitude: Double
        let longitude: Double
        let latitudeDelta: Double
        let longitudeDelta: Double

        init(_ region: MKCoordinateRegion) {
            latitude = region.center.latitude
            longitude = region.center.longitude
            latitudeDelta = region.span.latitudeDelta
            longitudeDelta = region.span.longitudeDelta
        }
    }

    /// iOS 17+: the camera-position Map. The deprecated `Map(coordinateRegion:)` writes its binding
    /// back from inside its own update whenever the app moves the region (MapKit's
    /// `mapLayerDidChangeVisibleRegion` into `Binding.setter`, "Modifying state during view update"
    /// in the log, verified with lldb 2026-09-04). Here the app's `region` stays the source the search
    /// reads; the map only hears about it through `position`, and reports pans back once a camera
    /// move ends, outside any update.
    @available(iOS 17.0, *)
    private struct CameraMap: View {
        @Binding var region: MKCoordinateRegion
        let markers: [MarkerItem]
        let onSelect: (Int) -> Void

        @State private var position: MapCameraPosition
        /// The last region the camera reported, so echoing it back into `region` does not re-move the camera.
        @State private var reported: RegionKey?

        init(region: Binding<MKCoordinateRegion>, markers: [MarkerItem], onSelect: @escaping (Int) -> Void) {
            _region = region
            self.markers = markers
            self.onSelect = onSelect
            _position = State(initialValue: .region(region.wrappedValue))
        }

        var body: some View {
            Map(position: $position) {
                ForEach(markers) { item in
                    Annotation("", coordinate: item.coordinate, anchor: .center) {
                        AnimatedMarkerBubble(tint: item.tint, systemImage: item.systemImage, title: item.title,
                                             isSelected: item.isSelected)
                            .onTapGesture {
                                if let index = item.resultIndex { onSelect(index) }
                            }
                            .accessibilityLabel(Text(item.title ?? String(localized: "Your location")))
                            .accessibilityAddTraits(item.resultIndex == nil ? [] : .isButton)
                    }
                    .annotationTitles(.hidden)
                }
            }
            // The map's own points of interest step back so the results read as the map's subject.
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .onChange(of: RegionKey(region)) { _, key in
                guard key != reported else { return }
                withAnimation(.easeInOut(duration: 0.35)) { position = .region(region) }
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                let key = RegionKey(context.region)
                reported = key
                if key != RegionKey(region) {
                    region = context.region
                }
            }
        }
    }

    // MARK: Top: search and kinds

    private var topControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            SearchBar(text: $searchText.animation(.easeInOut), placeholder: profile.searchPrompt)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(profile.kinds) { option in
                        kindChip(option)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 2)
            }
            // The row fades at its far edge, so the chip past it reads as more to scroll to, not cut off.
            .mask(
                HStack(spacing: 0) {
                    Color.black
                    LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 28)
                }
            )
        }
        .padding(.top, 6)
        .padding(.bottom, 14)
        // A scrim from the top edge down behind the bar and the chips: over a busy map the glass let
        // the streets and the pins show through the prompt.
        .background(
            LinearGradient(stops: [
                .init(color: Color(.systemBackground).opacity(0.85), location: 0),
                .init(color: Color(.systemBackground).opacity(0.6), location: 0.6),
                .init(color: Color(.systemBackground).opacity(0), location: 1),
            ], startPoint: .top, endPoint: .bottom)
                .padding(.top, -140)
                .allowsHitTesting(false)
        )
    }

    private func kindChip(_ option: PlaceLocatorKind) -> some View {
        let selected = option == kind
        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut(duration: 0.2)) { kind = option }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: option.systemImage)
                    .font(.caption.weight(.semibold))
                Text(option.title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundColor(selected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(selected ? accent : Color.clear)
            )
            .conditionalGlassEffect(clear: selected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Bottom: the map's buttons and the panel

    /// "Search This Area" once the map has moved off the last search, Near Me beside it, the panel under.
    private var bottomStack: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                if showsSearchHere {
                    Button {
                        settings.hapticFeedback()
                        scheduleSearch(for: searchText, force: true)
                    } label: {
                        Label("Search This Area", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(accent)
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .conditionalGlassEffect()
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer(minLength: 0)

                Button {
                    settings.hapticFeedback()
                    if hasRealLocation {
                        centerOnCurrentLocation()
                        scheduleSearch(for: searchText, force: true)
                    } else {
                        // Nothing to center on: ask (again) rather than silently doing nothing, and let the
                        // first-fix hook above finish the job when a location arrives.
                        settings.requestLocationAuthorization()
                        awaitingFirstFix = true
                    }
                } label: {
                    Image(systemName: hasRealLocation ? "location.fill" : "location.slash")
                        .font(.body.weight(.semibold))
                        .foregroundColor(accent)
                        .frame(width: 44, height: 44)
                        .conditionalGlassEffect(circle: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Near Me")
            }
            .animation(.easeInOut(duration: 0.2), value: showsSearchHere)

            resultsPanel
        }
        .padding(.horizontal, 12)
        .padding(.bottom, BottomBarCushion.standard)
    }

    private var showsSearchHere: Bool {
        guard !isSearching, let lastSearchCenter else { return false }
        let moved = CLLocation(latitude: lastSearchCenter.latitude, longitude: lastSearchCenter.longitude)
            .distance(from: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude))
        // A quarter of the visible span (a degree of latitude is ~111 km).
        return moved > region.span.latitudeDelta * 111_000 * 0.25
    }

    private var resultsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // The grabber and the header fold and unfold the panel, by a tap or a drag.
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.secondary.opacity(0.45))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                panelHeader
            }
            .contentShape(Rectangle())
            .onTapGesture { togglePanel() }
            .gesture(
                DragGesture(minimumDistance: 12).onEnded { value in
                    if value.translation.height < -24, !panelExpanded { togglePanel() }
                    if value.translation.height > 24, panelExpanded { togglePanel() }
                }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(Text(panelExpanded ? "Shows the chosen place" : "Shows every result"))

            if panelExpanded {
                if !profile.quickSearches.isEmpty {
                    quickSearchRow
                }
                Divider().opacity(0.5)
                resultsList
                    .frame(height: max(160, min(containerHeight * 0.42, 460)))
            } else {
                Divider().opacity(0.5)
                collapsedContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .conditionalGlassEffect(rectangle: true)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: panelExpanded)
    }

    private func togglePanel() {
        settings.hapticFeedback()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) { panelExpanded.toggle() }
    }

    private var panelHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if isSearching {
                        ProgressView().controlSize(.small)
                    }
                    Text(headerTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                Text(headerSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Menu {
                Picker(selection: $radiusIndex) {
                    ForEach(Self.radiusSteps.indices, id: \.self) { index in
                        Text(radiusTitle(Self.radiusSteps[index])).tag(index)
                    }
                } label: {
                    Text("Distance")
                }
                .pickerStyle(.inline)

                Picker(selection: $sortRaw) {
                    ForEach(SortOrder.allCases, id: \.rawValue) { order in
                        Label(order.title, systemImage: order.systemImage).tag(order.rawValue)
                    }
                } label: {
                    Text("Sort")
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(radius == 0 && sortOrder == .distance ? accent : .white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(radius == 0 && sortOrder == .distance ? accent.opacity(0.15) : accent))
            }
            .accessibilityLabel("Filter and sort")

            Image(systemName: "chevron.up")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(panelExpanded ? 180 : 0))
                .frame(width: 24, height: 34)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private var headerTitle: String {
        if isSearching && results.isEmpty { return profile.loadingText }
        if results.isEmpty { return profile.emptyText }
        return results.count == 1 ? String(localized: "\(results.count) match found") : String(localized: "\(results.count) matches found")
    }

    /// What the list is: its kind, its distance, its order.
    private var headerSubtitle: String {
        var parts: [String] = [kind.title]
        if radius > 0 { parts.append(radiusTitle(radius)) }
        parts.append(sortOrder.title)
        if !hasRealLocation { parts.append(String(localized: "Around the map")) }
        return parts.joined(separator: JoinSeparator.dot)
    }

    private var quickSearchRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(profile.quickSearches) { quick in
                    let selected = searchText.trimmingCharacters(in: .whitespaces).lowercased() == quick.query
                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { searchText = selected ? "" : quick.query }
                    } label: {
                        Text(quick.title)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(selected ? .white : accent)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(selected ? accent : accent.opacity(0.13)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .mask(
            HStack(spacing: 0) {
                Color.black
                LinearGradient(colors: [.black, .black.opacity(0)], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 28)
            }
        )
    }

    /// Folded: the chosen place's card, or what the search is doing.
    @ViewBuilder
    private var collapsedContent: some View {
        if let selectedItem, results.contains(where: { $0 === selectedItem }) {
            placeCard(selectedItem)
                .padding(14)
        } else {
            statusContent
                .padding(14)
        }
    }

    @ViewBuilder
    private var statusContent: some View {
        if isSearching {
            HStack(spacing: 10) {
                ProgressView()
                Text(profile.searchingText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(placeNotFound.map { String(localized: "Couldn’t find “\($0)” on the map.") } ?? profile.emptyText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                lookUpPlaceButton
            }
        }
    }

    /// "Look for “Brooklyn” on the map": the typed words as a PLACE, the map moved there and searched.
    @ViewBuilder
    private var lookUpPlaceButton: some View {
        let typed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !typed.isEmpty {
            Button {
                settings.hapticFeedback()
                lookUpPlace(typed)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: lookingUpPlace ? "hourglass" : "map")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(accent)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(accent.opacity(0.15)))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Search in “\(typed)”")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text("Move the map to that city or address")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(lookingUpPlace)
        }
    }

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        lookUpPlaceButton
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        Divider().padding(.leading, 14)
                    }
                    if results.isEmpty {
                        statusContent
                            .padding(14)
                    }
                    // Identity by object, not position: when a new search replaces `results`, rows are
                    // replaced rather than morphing one place's text into another's in place. By the
                    // object's identity, never `\.self`: MapKit can return one place twice (a category
                    // search and a text search both finding it), two map items that compare equal, and
                    // SwiftUI traps on duplicate ForEach keys ("Duplicate keys of type 'MKMapItem'",
                    // the 2026-10-12 stress walk, Halal Food Locator).
                    ForEach(results, id: \.rowIdentity) { item in
                        placeRow(item)
                            .id(item.rowIdentity)
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .onAppear {
                if let selectedItem { proxy.scrollTo(selectedItem.rowIdentity, anchor: .center) }
            }
        }
    }

    // MARK: A place

    private func categoryTitle(_ item: MKMapItem) -> String? {
        switch item.pointOfInterestCategory {
        case .restaurant?: return String(localized: "Restaurant")
        case .cafe?: return String(localized: "Café")
        case .bakery?: return String(localized: "Bakery")
        case .foodMarket?: return String(localized: "Market")
        default: return nil
        }
    }

    /// "Restaurant · 0.3 mi", "1.2 km": what kind of place and how far.
    private func detailLine(_ item: MKMapItem) -> String {
        [categoryTitle(item), distance(to: item).map(distanceText)].compactMap { $0 }.joined(separator: JoinSeparator.dot)
    }

    private func placeIcon(selected: Bool, size: CGFloat) -> some View {
        Image(systemName: profile.markerSymbol)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundColor(selected ? .white : accent)
            .frame(width: size, height: size)
            .background(Circle().fill(selected ? accent : accent.opacity(0.15)))
    }

    /// One row of the list: the place, its kind and distance, its address, and its actions.
    private func placeRow(_ item: MKMapItem) -> some View {
        let selected = isSameItem(item, selectedItem)
        return HStack(alignment: .top, spacing: 12) {
            placeIcon(selected: selected, size: 34)

            VStack(alignment: .leading, spacing: 4) {
                HighlightedSnippet(
                    source: item.name ?? profile.fallbackName,
                    term: searchText,
                    font: .subheadline.weight(.semibold),
                    accent: accent,
                    fg: .primary
                )
                .multilineTextAlignment(.leading)

                let detail = detailLine(item)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption.weight(.medium))
                        .foregroundColor(accent)
                }

                HighlightedSnippet(
                    source: formattedAddress(for: item),
                    term: searchText,
                    font: .caption,
                    accent: accent,
                    fg: .secondary
                )
                .multilineTextAlignment(.leading)
                .lineLimit(2)

                actionRow(item, prominent: false)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(selected ? accent.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture { select(item) }
        .contextMenu { placeMenu(item) }
    }

    /// The folded panel's card: the chosen place, larger, with Directions first.
    private func placeCard(_ item: MKMapItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                placeIcon(selected: true, size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name ?? profile.fallbackName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    let detail = detailLine(item)
                    if !detail.isEmpty {
                        Text(detail)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(accent)
                    }
                    Text(formattedAddress(for: item))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                // The neighbours, without opening the list.
                if results.count > 1 {
                    HStack(spacing: 0) {
                        stepButton(by: -1, systemImage: "chevron.left", label: "Previous place")
                        stepButton(by: 1, systemImage: "chevron.right", label: "Next place")
                    }
                }
            }
            actionRow(item, prominent: true)
        }
        .contextMenu { placeMenu(item) }
    }

    private func stepButton(by step: Int, systemImage: String, label: LocalizedStringKey) -> some View {
        Button {
            guard let index = results.firstIndex(where: { isSameItem($0, selectedItem) }) else { return }
            let next = (index + step + results.count) % results.count
            select(results[next])
        } label: {
            Image(systemName: systemImage)
                .font(.footnote.weight(.bold))
                .foregroundColor(accent)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// Directions, Call, Website and Share: Directions filled when it is the card's.
    private func actionRow(_ item: MKMapItem, prominent: Bool) -> some View {
        HStack(spacing: 8) {
            Menu {
                Button { openInMaps(item, mode: MKLaunchOptionsDirectionsModeDriving) } label: {
                    Label("Driving", systemImage: "car.fill")
                }
                Button { openInMaps(item, mode: MKLaunchOptionsDirectionsModeWalking) } label: {
                    Label("Walking", systemImage: "figure.walk")
                }
                Button { openInMaps(item, mode: MKLaunchOptionsDirectionsModeTransit) } label: {
                    Label("Transit", systemImage: "tram.fill")
                }
            } label: {
                actionLabel(String(localized: "Directions"), systemImage: "arrow.triangle.turn.up.right.diamond.fill",
                            filled: prominent, grows: prominent)
            } primaryAction: {
                settings.hapticFeedback()
                openInMaps(item, mode: MKLaunchOptionsDirectionsModeDriving)
            }

            // In a row, Call and Website are their symbols alone: with the words, "Directions" was cut
            // to "Directio..." beside them. The card has the room for all three.
            if let phone = item.phoneNumber, let url = Self.phoneURL(phone) {
                Link(destination: url) {
                    actionLabel(prominent ? String(localized: "Call") : nil, systemImage: "phone.fill", filled: false, grows: prominent)
                }
                .accessibilityLabel(Text("Call"))
            }

            if let website = item.url {
                Link(destination: website) {
                    actionLabel(prominent ? String(localized: "Website") : nil, systemImage: "safari.fill", filled: false, grows: prominent)
                }
                .accessibilityLabel(Text("Website"))
            }

            ShareLink(item: Self.mapsURL(for: item, fallbackName: profile.fallbackName),
                      subject: Text(item.name ?? profile.fallbackName),
                      message: Text(formattedAddress(for: item))) {
                actionLabel(nil, systemImage: "square.and.arrow.up", filled: false, grows: false)
            }
            .accessibilityLabel("Share")

            if !prominent { Spacer(minLength: 0) }
        }
        .buttonStyle(.plain)
    }

    private func actionLabel(_ title: String?, systemImage: String, filled: Bool, grows: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            if let title {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .foregroundColor(filled ? .white : accent)
        .padding(.horizontal, title == nil ? 9 : 11)
        .frame(maxWidth: grows ? .infinity : nil)
        .frame(height: grows ? 36 : 30)
        .background(Capsule().fill(filled ? accent : accent.opacity(0.13)))
        .contentShape(Capsule())
    }

    @ViewBuilder
    private func placeMenu(_ item: MKMapItem) -> some View {
        Text(profile.contextMenuTitle)
            .foregroundStyle(.secondary)

        Button {
            settings.hapticFeedback()
            UIPasteboard.general.string = item.name ?? profile.fallbackName
        } label: {
            Label("Copy Name", systemImage: "doc.on.doc")
        }

        Button {
            settings.hapticFeedback()
            UIPasteboard.general.string = formattedAddress(for: item)
        } label: {
            Label("Copy Address", systemImage: "doc.on.doc")
        }

        Button {
            settings.hapticFeedback()
            UIPasteboard.general.string = fullAddress(for: item)
        } label: {
            Label("Copy Full Address", systemImage: "doc.on.doc")
        }

        if let phone = item.phoneNumber {
            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = phone
            } label: {
                Label("Copy Phone Number", systemImage: "phone")
            }
        }
    }

    private static func phoneURL(_ phone: String) -> URL? {
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        return digits.isEmpty ? nil : URL(string: "tel:\(digits)")
    }

    /// An Apple Maps link to the place, for Share.
    private static func mapsURL(for item: MKMapItem, fallbackName: String) -> URL {
        let coordinate = item.placemark.coordinate
        var components = URLComponents(string: "https://maps.apple.com/")!
        components.queryItems = [
            URLQueryItem(name: "q", value: item.name ?? fallbackName),
            URLQueryItem(name: "ll", value: "\(coordinate.latitude),\(coordinate.longitude)"),
        ]
        return components.url ?? URL(string: "https://maps.apple.com/")!
    }

    // MARK: Actions

    private func centerOnCurrentLocation() {
        if let cur = live.currentLocation, cur.latitude != 1000, cur.longitude != 1000 {
            updateRegion(to: cur.coordinate)
        } else if let home = settings.homeLocation {
            updateRegion(to: home.coordinate)
        }
    }

    /// A pin or a row chosen: the panel folds to that place's card, and the map centres on it.
    private func select(_ item: MKMapItem) {
        settings.hapticFeedback()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            selectedItem = item
            panelExpanded = false
        }
        updateRegion(to: item.placemark.coordinate, keepingSpan: true)
    }

    private func openInMaps(_ item: MKMapItem, mode: String) {
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: mode])
    }

    /// Looks the typed words up as a place (a city, a neighbourhood, an address), moves the map there,
    /// and searches it, the search bar cleared.
    private func lookUpPlace(_ text: String) {
        lookingUpPlace = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.resultTypes = .address
        Task {
            let response = try? await MKLocalSearch(request: request).start()
            await MainActor.run {
                lookingUpPlace = false
                guard let place = response?.mapItems.first else {
                    placeNotFound = text
                    return
                }
                settings.hapticFeedback()
                updateRegion(to: place.placemark.coordinate)
                awaitingFirstFix = false
                placeNotFound = nil
                withAnimation(.easeInOut) { searchText = "" }
                scheduleSearch(for: "", force: true)
            }
        }
    }

    private func formattedAddress(for item: MKMapItem) -> String {
        let streetParts = [
            item.placemark.subThoroughfare,
            item.placemark.thoroughfare
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        let street = streetParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = [
            street.isEmpty ? nil : street,
            item.placemark.locality,
            item.placemark.country
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        if parts.isEmpty {
            return String(localized: "Address unavailable")
        }

        return Array(NSOrderedSet(array: parts)).compactMap { $0 as? String }.joined(separator: ", ")
    }

    private func fullAddress(for item: MKMapItem) -> String {
        let streetParts = [
            item.placemark.subThoroughfare,
            item.placemark.thoroughfare
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        let street = streetParts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = [
            street.isEmpty ? nil : street,
            item.placemark.locality,
            item.placemark.administrativeArea,
            item.placemark.postalCode,
            item.placemark.country
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        if parts.isEmpty {
            return formattedAddress(for: item)
        }

        return Array(NSOrderedSet(array: parts)).compactMap { $0 as? String }.joined(separator: ", ")
    }

    private func updateRegion(to coord: CLLocationCoordinate2D, keepingSpan: Bool = false) {
        let span = keepingSpan && region.span.latitudeDelta < 0.5
            ? region.span
            : MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        region = .init(center: coord, span: span)
    }

    /// The map opened out (or in) to show a circle of `meters` around the reader, or the map's centre.
    private func fitRegion(toRadius meters: CLLocationDistance) {
        let center = origin?.coordinate ?? region.center
        let degrees = min(meters * 2.2 / 111_000, 2)
        region = .init(center: center, span: .init(latitudeDelta: degrees, longitudeDelta: degrees))
    }

    private func configureInitialRegion() {
        centerOnCurrentLocation()
        if let radiusMeters { fitRegion(toRadius: radiusMeters) }
    }

    /// The results held to the chosen distance and put in the chosen order.
    private func arranged(_ items: [MKMapItem]) -> [MKMapItem] {
        var kept = items
        if let radiusMeters, origin != nil {
            kept = kept.filter { (distance(to: $0) ?? 0) <= radiusMeters }
        }
        switch sortOrder {
        case .distance:
            guard origin != nil else { return kept }
            return kept.sorted { (distance(to: $0) ?? .greatestFiniteMagnitude) < (distance(to: $1) ?? .greatestFiniteMagnitude) }
        case .name:
            return kept.sorted {
                ($0.name ?? "").localizedStandardCompare($1.name ?? "") == .orderedAscending
            }
        }
    }

    private func search(for text: String) async {
        let searchRegion = region
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let kind = kind

        // Read main-actor state (settings, region) before hopping off; the fan-out, filtering, and
        // distance sort all run in `performPlaceSearch`, off the main actor.
        let sortOrigin: CLLocationCoordinate2D? = {
            if let cur = live.currentLocation, cur.latitude != 1000, cur.longitude != 1000 {
                return cur.coordinate
            }
            if let homeCoordinate {
                return homeCoordinate
            }
            return searchRegion.center
        }()

        let items = await performPlaceSearch(
            queries: trimmed.isEmpty ? kind.baseQueries : kind.queries(trimmed),
            nameKeywords: kind.nameKeywords,
            exclusion: profile.exclusion,
            poiFilter: kind.poiFilter,
            in: searchRegion,
            sortOrigin: sortOrigin,
            limit: 25
        )

        guard !Task.isCancelled else { return }

        let shown = arranged(items.withoutDuplicatePlaces())
        withAnimation {
            results = shown
            isSearching = false
            lastSearchCenter = searchRegion.center
            if selectedItem == nil || !shown.contains(where: { isSameItem($0, selectedItem) }) {
                selectedItem = shown.first
            }
        }
        // The encode + UserDefaults write has no business inside an animation transaction. Only the
        // plain search is the home cache: a kind or a distance is a narrowing of it.
        if kind == profile.kinds[0] {
            persistHomeCacheIfNeeded(items: items, query: text, region: searchRegion)
        }
    }

    private func scheduleSearch(for text: String, force: Bool) {
        searchTask?.cancel()
        searchTask = Task {
            await MainActor.run { isSearching = true }
            if !force {
                try? await Task.sleep(nanoseconds: 250_000_000)
            }
            guard !Task.isCancelled else { return }
            await search(for: text)
        }
    }

    private func loadCachedHomeResultsIfPossible() {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              results.isEmpty,
              kind == profile.kinds[0],
              isRegionNearHome(region),
              let cache = decodeHomeCache(),
              isSameHome(cache.homeLocation, settings.homeLocation) else { return }

        // A cache written before a place was hidden still holds it; only the name was cached.
        let cachedItems = arranged(cache.items
            .filter { !profile.exclusion.excludes(name: $0.name) }
            .map { $0.mapItem() }
            .withoutDuplicatePlaces())
        guard !cachedItems.isEmpty else { return }

        results = cachedItems
        if selectedItem == nil {
            selectedItem = cachedItems.first
        }
    }

    private func warmHomeCacheIfNeeded() {
        // Reduced tier: the visible search is enough traffic; the home cache refreshes on a full-tier
        // visit or when the map opens at home (Performance Guide, Phase 6 step 13).
        guard !AppPerformance.shouldAvoidBroadPrewarm, let home = settings.homeLocation else { return }
        // When the map opened near home, the live search running right now covers the same area and
        // already persists into the cache (`persistHomeCacheIfNeeded` uses the same radius) - a second
        // identical five-query fan-out would just double the MKLocalSearch traffic. Warm only when the
        // map opened somewhere else, so the cache is still fresh for the next open at home.
        guard !isRegionNearHome(region) else { return }

        let base = profile.kinds[0]
        Task(priority: .utility) {
            let homeRegion = MKCoordinateRegion(
                center: home.coordinate,
                span: .init(latitudeDelta: 0.15, longitudeDelta: 0.15)
            )
            let items = await performPlaceSearch(
                queries: base.baseQueries,
                nameKeywords: base.nameKeywords,
                exclusion: profile.exclusion,
                poiFilter: base.poiFilter,
                in: homeRegion,
                sortOrigin: nil,
                limit: 25
            )
            guard !items.isEmpty else { return }

            let cache = CachedPlaceHomeResults(
                homeLocation: home,
                savedAt: Date(),
                items: items.map(CachedPlaceItem.init)
            )

            if let data = try? Settings.encoder.encode(cache) {
                await MainActor.run {
                    homeCacheData = data
                }
            }
        }
    }

    private func decodeHomeCache() -> CachedPlaceHomeResults? {
        guard !homeCacheData.isEmpty else { return nil }
        return try? Settings.decoder.decode(CachedPlaceHomeResults.self, from: homeCacheData)
    }

    private func persistHomeCacheIfNeeded(items: [MKMapItem], query: String, region: MKCoordinateRegion) {
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let home = settings.homeLocation,
              coordinateDistance(region.center, home.coordinate) <= Self.homeRefreshRadiusMeters else { return }

        let cache = CachedPlaceHomeResults(
            homeLocation: home,
            savedAt: Date(),
            items: items.map(CachedPlaceItem.init)
        )

        if let data = try? Settings.encoder.encode(cache) {
            homeCacheData = data
        }
    }

    private func isSameHome(_ lhs: Location, _ rhs: Location?) -> Bool {
        guard let rhs else { return false }
        return coordinateDistance(lhs.coordinate, rhs.coordinate) <= Self.homeCacheMatchDistanceMeters
    }

    private func isRegionNearHome(_ region: MKCoordinateRegion) -> Bool {
        guard let homeCoordinate else { return false }
        return coordinateDistance(region.center, homeCoordinate) <= Self.homeRefreshRadiusMeters
    }

    private func coordinateDistance(_ lhs: CLLocationCoordinate2D, _ rhs: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
            .distance(from: CLLocation(latitude: rhs.latitude, longitude: rhs.longitude))
    }

    private func isSameItem(_ lhs: MKMapItem, _ rhs: MKMapItem?) -> Bool {
        guard let rhs else { return false }
        let lhsName = lhs.name ?? ""
        let rhsName = rhs.name ?? ""
        let lhsCoordinate = lhs.placemark.coordinate
        let rhsCoordinate = rhs.placemark.coordinate
        return lhsName == rhsName
            && abs(lhsCoordinate.latitude - rhsCoordinate.latitude) < 0.000_001
            && abs(lhsCoordinate.longitude - rhsCoordinate.longitude) < 0.000_001
    }
}

/// The shared search core for the live search and the home-cache warmer. Top-level (not a `View` member,
/// which would pin it to the main actor): the queries fan out concurrently instead of serially - the
/// wall-clock cost is one round-trip, not five to seven - and the filter/dedup/sort never touch the main
/// thread. Result order is kept deterministic by reassembling buckets in query order.
private func performPlaceSearch(
    queries: [String],
    nameKeywords: [String],
    exclusion: PlaceLocatorExclusion,
    poiFilter: MKPointOfInterestFilter?,
    in searchRegion: MKCoordinateRegion,
    sortOrigin: CLLocationCoordinate2D?,
    limit: Int = 12
) async -> [MKMapItem] {
    var buckets = [[MKMapItem]](repeating: [], count: queries.count)
    // Five or six MKLocalSearch requests in flight at once on the full tier; two at a time on the
    // reduced tier, where the radio and the CPU are what Low Power Mode is rationing.
    let maxInFlight = AppPerformance.shouldAvoidBroadPrewarm ? 2 : queries.count

    await withTaskGroup(of: (Int, [MKMapItem]).self) { group in
        var inFlight = 0
        for (index, query) in queries.enumerated() {
            if inFlight >= maxInFlight, let (doneIndex, items) = await group.next() {
                buckets[doneIndex] = items
                inFlight -= 1
            }
            group.addTask {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = query
                request.resultTypes = .pointOfInterest
                request.region = searchRegion
                if let poiFilter {
                    request.pointOfInterestFilter = poiFilter
                }

                let response = try? await MKLocalSearch(request: request).start()
                return (index, response?.mapItems ?? [])
            }
            inFlight += 1
        }
        for await (index, items) in group {
            buckets[index] = items
        }
    }

    guard !Task.isCancelled else { return [] }

    let matching = buckets.joined().filter { item in
        if exclusion.excludes(name: item.name, website: item.url) { return false }
        guard !nameKeywords.isEmpty else { return true }
        let name = (item.name ?? "").lowercased()
        let title = (item.placemark.title ?? "").lowercased()
        return nameKeywords.contains { keyword in
            name.contains(keyword) || title.contains(keyword)
        }
    }

    var seen = Set<String>()
    let unique = matching.filter { item in
        let key = "\(item.name ?? "")|\(item.placemark.coordinate.latitude)|\(item.placemark.coordinate.longitude)"
        return seen.insert(key).inserted
    }

    guard let sortOrigin else { return Array(unique.prefix(limit)) }

    let origin = CLLocation(latitude: sortOrigin.latitude, longitude: sortOrigin.longitude)
    let sorted = unique
        .map { item -> (MKMapItem, CLLocationDistance) in
            let coord = item.placemark.coordinate
            return (item, origin.distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude)))
        }
        .sorted { $0.1 < $1.1 }
        .map { $0.0 }

    return Array(sorted.prefix(limit))
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        PlaceLocatorView(profile: .masjid)
    }
}
private extension MKMapItem {
    /// The row's ForEach identity: this object, whatever MapKit's `isEqual:` says about another.
    var rowIdentity: ObjectIdentifier { ObjectIdentifier(self) }
}

private extension Array where Element == MKMapItem {
    /// The same place listed once, whichever search found it first: equal items (MapKit's own
    /// equality, which the `\.self` identity used to key rows on) and same-name items at the same spot.
    func withoutDuplicatePlaces() -> [MKMapItem] {
        var seen: [MKMapItem] = []
        var keys = Set<String>()
        for item in self {
            let coordinate = item.placemark.coordinate
            let key = "\(item.name ?? "")|\(String(format: "%.5f,%.5f", coordinate.latitude, coordinate.longitude))"
            if keys.contains(key) || seen.contains(where: { $0 === item || $0.isEqual(item) }) { continue }
            keys.insert(key)
            seen.append(item)
        }
        return seen
    }
}
#endif
