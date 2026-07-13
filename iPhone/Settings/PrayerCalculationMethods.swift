import Foundation
import Adhan

/// How Isha is determined for a method: an angle below the horizon, or a fixed number of minutes after Maghrib.
enum IshaRule: Equatable {
    case angle(Double)
    /// Umm al-Qura and the Gulf use a clock interval instead of an angle (90 minutes; 120 in Ramadan for
    /// Umm al-Qura, which `_computeRawPrayers` already applies).
    case minutesAfterMaghrib(Int)

    var summary: String {
        switch self {
        case .angle(let deg): return "Isha: \(Self.format(deg))°"
        case .minutesAfterMaghrib(let mins): return "Isha: \(mins) min after Maghrib"
        }
    }

    static func format(_ value: Double) -> String {
        value == value.rounded()
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}

/// One prayer-calculation method: who publishes it, and the twilight angles it uses.
///
/// The app used to lean entirely on `Adhan.CalculationMethod`, so it could only ever offer the dozen methods
/// that enum happens to contain. This model carries the angles itself and builds `CalculationParameters` from
/// them, so a method is just data - which is what makes the regional methods below (and the user's own custom
/// angles) possible at all.
struct PrayerCalculationMethod: Identifiable, Equatable {
    /// Stable identifier, and the string persisted in `Settings.prayerCalculation`. Never localize or rename
    /// one of these without adding a legacy alias, or every user on that method silently falls back to MWL.
    let id: String
    /// What the row shows.
    let name: String
    /// Where it is the customary choice. Empty for the global/organizational methods.
    let region: String?
    let fajrAngle: Double
    let isha: IshaRule
    /// ISO country codes this method is the default for, used by automatic detection. At most ONE method may
    /// claim a given country (asserted in `PrayerCalculationCatalog.byCountry`).
    let countryCodes: [String]
    /// When set, `Adhan` gets to apply the method's own seasonal behavior instead of plain angles. Only used
    /// for Moonsighting Committee, whose rule is not expressible as a fixed angle.
    var adhanMethod: CalculationMethod? = nil

    var angleSummary: String {
        "Fajr: \(IshaRule.format(fajrAngle))° / \(isha.summary)"
    }

    /// The parameters Adhan actually computes with.
    ///
    /// `CalculationParameters`' initializers are internal to the Adhan module, so they cannot be called from
    /// here. `.other` is the supported escape hatch: it hands back a parameters value whose angle fields are
    /// public and mutable, which is exactly what a data-driven method needs.
    var parameters: CalculationParameters {
        if let adhanMethod {
            return adhanMethod.params
        }
        var params = CalculationMethod.other.params
        params.fajrAngle = fajrAngle
        switch isha {
        case .angle(let deg):
            params.ishaAngle = deg
            params.ishaInterval = 0
        case .minutesAfterMaghrib(let mins):
            params.ishaAngle = 0
            params.ishaInterval = mins
        }
        return params
    }
}

/// Every method the app offers.
///
/// Curation rules, all deliberate:
/// - **One method per country.** Automatic detection has to pick exactly one, and a list with three competing
///   entries per country is a list nobody can choose from.
/// - **Sunni sources only.** The Adhan package also ships Tehran (Institute of Geophysics) and a Jafari
///   method; both are Twelver Shia in origin and are intentionally absent here. Tehran was previously exposed
///   and has been removed, with a legacy alias so anyone on it lands on a sensible Sunni default rather than
///   losing their setting.
/// - **Angles are the published values** of the body named, not approximations.
enum PrayerCalculationCatalog {
    static let muslimWorldLeagueID = "Muslim World League"
    static let customID = "Custom Angles"

    static let methods: [PrayerCalculationMethod] = [
        // MARK: Global / organizational
        PrayerCalculationMethod(
            id: muslimWorldLeagueID,
            name: "Muslim World League",
            region: "Global default",
            fajrAngle: 18, isha: .angle(17),
            countryCodes: []
        ),
        PrayerCalculationMethod(
            id: "Islamic Society of North America (ISNA)",
            name: "Islamic Society of North America (ISNA)",
            region: "United States, Canada",
            fajrAngle: 15, isha: .angle(15),
            countryCodes: ["US", "CA", "MX", "PR", "VI", "GU", "AS", "MP", "UM"]
        ),
        PrayerCalculationMethod(
            id: "Britain (Moonsighting Committee)",
            name: "Moonsighting Committee Worldwide",
            region: "United Kingdom, Ireland",
            // Seasonal, not a fixed angle - the summary shows its base angles, but Adhan applies the real rule.
            fajrAngle: 18, isha: .angle(18),
            countryCodes: ["GB", "IE"],
            adhanMethod: .moonsightingCommittee
        ),

        // MARK: Middle East
        PrayerCalculationMethod(
            id: "Saudi Arabia (Umm Al-Qura)",
            name: "Umm Al-Qura, Makkah",
            region: "Saudi Arabia",
            fajrAngle: 18.5, isha: .minutesAfterMaghrib(90),
            countryCodes: ["SA", "BH", "OM", "YE"]
        ),
        PrayerCalculationMethod(
            id: "UAE (General Authority of Islamic Affairs)",
            name: "UAE General Authority of Islamic Affairs",
            region: "United Arab Emirates",
            fajrAngle: 18.2, isha: .angle(18.2),
            countryCodes: ["AE"]
        ),
        PrayerCalculationMethod(
            id: "Kuwait",
            name: "Kuwait",
            region: "Kuwait",
            fajrAngle: 18, isha: .angle(17.5),
            countryCodes: ["KW"]
        ),
        PrayerCalculationMethod(
            id: "Qatar",
            name: "Qatar",
            region: "Qatar",
            fajrAngle: 18, isha: .minutesAfterMaghrib(90),
            countryCodes: ["QA"]
        ),
        PrayerCalculationMethod(
            id: "Jordan (Ministry of Awqaf)",
            name: "Jordan, Ministry of Awqaf",
            region: "Jordan, Palestine",
            fajrAngle: 18, isha: .angle(17),
            countryCodes: ["JO", "PS"]
        ),

        // MARK: Africa
        PrayerCalculationMethod(
            id: "Egypt",
            name: "Egyptian General Authority of Survey",
            region: "Egypt",
            fajrAngle: 19.5, isha: .angle(17.5),
            countryCodes: ["EG", "LY", "SD", "SS", "DJ", "ER", "SO", "LB", "SY", "IQ"]
        ),
        PrayerCalculationMethod(
            id: "Morocco (Ministry of Endowments)",
            name: "Morocco, Ministry of Endowments",
            region: "Morocco",
            fajrAngle: 19, isha: .angle(17),
            countryCodes: ["MA"]
        ),
        PrayerCalculationMethod(
            id: "Algeria (Ministry of Religious Affairs)",
            name: "Algeria, Ministry of Religious Affairs",
            region: "Algeria",
            fajrAngle: 18, isha: .angle(17),
            countryCodes: ["DZ"]
        ),
        PrayerCalculationMethod(
            id: "Tunisia (Ministry of Religious Affairs)",
            name: "Tunisia, Ministry of Religious Affairs",
            region: "Tunisia",
            fajrAngle: 18, isha: .angle(18),
            countryCodes: ["TN"]
        ),
        PrayerCalculationMethod(
            id: "South Africa",
            name: "South Africa",
            region: "South Africa",
            fajrAngle: 18, isha: .angle(17),
            countryCodes: ["ZA"]
        ),

        // MARK: Europe
        PrayerCalculationMethod(
            id: "Turkey (Diyanet)",
            name: "Diyanet İşleri Başkanlığı",
            region: "Turkey",
            fajrAngle: 18, isha: .angle(17),
            countryCodes: ["TR", "CY", "AL", "XK", "BA", "MK"]
        ),
        PrayerCalculationMethod(
            id: "France (Musulmans de France)",
            name: "Musulmans de France (ex-UOIF)",
            region: "France",
            fajrAngle: 12, isha: .angle(12),
            countryCodes: ["FR"]
        ),
        PrayerCalculationMethod(
            id: "Belgium (Islamic Centre)",
            name: "Belgium, Islamic Centre",
            region: "Belgium",
            fajrAngle: 18, isha: .angle(17),
            countryCodes: ["BE"]
        ),
        PrayerCalculationMethod(
            id: "Russia (Spiritual Administration)",
            name: "Russia, Spiritual Administration of Muslims",
            region: "Russia",
            fajrAngle: 16, isha: .angle(15),
            countryCodes: ["RU"]
        ),

        // MARK: Asia and Oceania
        PrayerCalculationMethod(
            id: "Karachi",
            name: "University of Islamic Sciences, Karachi",
            region: "Pakistan, India, Bangladesh",
            fajrAngle: 18, isha: .angle(18),
            countryCodes: ["PK", "IN", "BD", "AF", "NP", "LK"]
        ),
        PrayerCalculationMethod(
            id: "Malaysia (JAKIM)",
            name: "JAKIM (Jabatan Kemajuan Islam Malaysia)",
            region: "Malaysia",
            fajrAngle: 20, isha: .angle(18),
            countryCodes: ["MY", "BN"]
        ),
        PrayerCalculationMethod(
            id: "Singapore (MUIS)",
            name: "MUIS (Majlis Ugama Islam Singapura)",
            region: "Singapore",
            fajrAngle: 20, isha: .angle(18),
            countryCodes: ["SG"]
        ),
        PrayerCalculationMethod(
            id: "Indonesia (Kemenag)",
            name: "Kemenag (Kementerian Agama Indonesia)",
            region: "Indonesia",
            fajrAngle: 20, isha: .angle(18),
            countryCodes: ["ID", "TH", "PH"]
        ),
        PrayerCalculationMethod(
            id: "Australia",
            name: "Australia",
            region: "Australia, New Zealand",
            fajrAngle: 18, isha: .angle(17),
            countryCodes: ["AU", "NZ"]
        ),
    ]

    /// The user's own angles. Its values come from `Settings`, so it is built on demand rather than stored.
    static func custom(fajrAngle: Double, ishaAngle: Double) -> PrayerCalculationMethod {
        PrayerCalculationMethod(
            id: customID,
            name: "Custom Angles",
            region: "Your own Fajr and Isha angles",
            fajrAngle: fajrAngle, isha: .angle(ishaAngle),
            countryCodes: []
        )
    }

    /// Every selectable method, including the custom one.
    static func allMethods(customFajr: Double, customIsha: Double) -> [PrayerCalculationMethod] {
        methods + [custom(fajrAngle: customFajr, ishaAngle: customIsha)]
    }

    static func method(id: String) -> PrayerCalculationMethod? {
        methods.first { $0.id == id }
    }

    /// ISO country code -> method id. Built from `countryCodes`, and it traps in debug if two methods claim the
    /// same country, which is the invariant that keeps automatic detection unambiguous.
    static let byCountry: [String: String] = {
        var map: [String: String] = [:]
        for method in methods {
            for code in method.countryCodes {
                assert(map[code] == nil, "Two calculation methods claim \(code): \(map[code]!) and \(method.id)")
                map[code] = method.id
            }
        }
        return map
    }()

    /// Old stored labels -> their replacement, so an existing user's setting survives this rework.
    ///
    /// "Tehran" and "Dubai" both disappear here: Tehran was the Twelver Shia Institute of Geophysics method,
    /// and Dubai is superseded by the UAE authority's own published angles.
    static let legacyAliases: [String: String] = [
        "Moonsight Committee": "Britain (Moonsighting Committee)",
        "Umm Al-Qura": "Saudi Arabia (Umm Al-Qura)",
        "Saudi Arabia": "Saudi Arabia (Umm Al-Qura)",
        "United Kingdom": "Britain (Moonsighting Committee)",
        "North America": "Islamic Society of North America (ISNA)",
        "Turkey": "Turkey (Diyanet)",
        "Dubai": "UAE (General Authority of Islamic Affairs)",
        "Singapore": "Singapore (MUIS)",
        // Was the Institute of Geophysics, University of Tehran - a Shia method. Anyone on it moves to MWL.
        "Tehran": muslimWorldLeagueID,
    ]
}
