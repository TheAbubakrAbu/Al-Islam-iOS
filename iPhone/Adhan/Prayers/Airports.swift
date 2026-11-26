#if os(iOS)
import Foundation

// Flight Mode, part 3 of 4: the airports a flight is picked from.
//
// Resources/Data/Islam/Airports.tsv (Scripts/build_airports.py): every airport with an IATA code
// and scheduled service, about 4,000, from OurAirports' public-domain list, with each one's time
// zone. Shipped in the bundle because the form is filled in where there is no network: at the gate
// in airplane mode, or already in the air.
//
// Resources/Data/Islam/AirportNames-<language>.tsv (Scripts/build_airport_names.py): the same
// airports and their cities named in each language the app is translated into, from Wikidata's
// labels. Only the interface's own language is read. An airport or city Wikidata has no name for
// in that language keeps its English one, and the English names are always searched as well, so
// "Jeddah", "جدة" and "JED" all find the same row (Abu, 2026-11-26: "Fix ... airport and city names").

struct Airport: Identifiable, Equatable {
    let code: String
    /// "L", "M" or "S": the list is sorted large first, and a search keeps that order within a rank.
    let size: String
    let name: String
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    let timeZoneID: String
    /// Alternate names ("Tokyo" for Narita): searched, never shown.
    let keywords: String
    /// The airport and its city in the interface's language, where the names file has them.
    var localName: String? = nil
    var localCity: String? = nil

    var id: String { code }

    /// What is shown: the interface language's name, or the English one.
    var displayName: String { localName ?? name }
    var displayCity: String { localCity ?? city }

    /// The airport as one end of a flight, under the names shown for it, so everything that later
    /// speaks of the flight (the board, a notification, a widget) says them in the same language
    /// without looking the airport up again.
    var place: FlightPlace {
        FlightPlace(code: code, name: displayName, city: displayCity, country: country,
                    latitude: latitude, longitude: longitude, timeZoneID: timeZoneID)
    }

    /// "London, United Kingdom", in the interface's language (the country is iOS's own name for it).
    var cityAndCountry: String {
        let countryName = Locale(identifier: AppLanguage.code).localizedString(forRegionCode: country)
            ?? Locale.current.localizedString(forRegionCode: country) ?? country
        let shown = displayCity
        return shown.isEmpty ? countryName : String(localized: "\(shown), \(countryName)")
    }

    static func == (lhs: Airport, rhs: Airport) -> Bool { lhs.code == rhs.code }
}

enum Airports {
    /// The whole list, read on first use (about 150 KB packed; a few milliseconds).
    static let all: [Airport] = load()

    private static let byCode: [String: Airport] = Dictionary(all.map { ($0.code, $0) }, uniquingKeysWith: { first, _ in first })

    /// What a search compares against, folded once: lowercase, no accents ("Sao Paulo" finds São
    /// Paulo), in English and in the interface's language both.
    private static let folded: [(code: String, city: String, name: String, localCity: String, localName: String, rest: String)] = {
        let locale = Locale(identifier: AppLanguage.code)
        return all.map {
            (fold($0.code), fold($0.city), fold($0.name), fold($0.localCity ?? ""), fold($0.localName ?? ""),
             fold($0.keywords + " " + (locale.localizedString(forRegionCode: $0.country) ?? "")
                  + " " + (Locale.current.localizedString(forRegionCode: $0.country) ?? "")))
        }
    }()

    static func airport(code: String) -> Airport? { byCode[code.uppercased()] }

    /// Letters a search should not tell apart, per script: the forms of alif, taa marbutah and
    /// haa, the Arabic, Persian and Urdu yaa and kaf (so "جده" finds "جدة" and an Urdu keyboard
    /// finds an Arabic spelling).
    private static let arabicFolds: [Character: Character] = [
        "أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا", "ة": "ه", "ۃ": "ه", "ہ": "ه", "ھ": "ه", "ى": "ي", "ی": "ي",
        "ے": "ي", "ئ": "ي", "ؤ": "و", "ک": "ك",
    ]

    static func fold(_ text: String) -> String {
        let plain = text.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: nil)
        guard plain.unicodeScalars.contains(where: { $0.value >= 0x0600 && $0.value <= 0x06FF }) else { return plain }
        // The vowel marks first (a shaddah is not an accent to the system's folding), then the letters.
        let bare = String(String.UnicodeScalarView(plain.unicodeScalars.filter {
            !((0x064B...0x065F).contains($0.value) || $0.value == 0x0670 || $0.value == 0x0640)
        }))
        return String(bare.map { arabicFolds[$0] ?? $0 })
    }

    /// Airports matching what was typed, best first: the code itself, then a city that starts with
    /// it, then a name or a word that does, then anything that contains it. Large airports lead each rank.
    static func search(_ query: String, limit: Int = 50) -> [Airport] {
        let needle = fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !needle.isEmpty else { return [] }
        var ranks: [[Airport]] = Array(repeating: [], count: 5)
        let word = " " + needle
        for (index, entry) in folded.enumerated() {
            let rank: Int
            if entry.code == needle {
                rank = 0
            } else if entry.city.hasPrefix(needle) || entry.localCity.hasPrefix(needle) {
                rank = 1
            } else if entry.name.hasPrefix(needle) || entry.localName.hasPrefix(needle)
                        || entry.name.contains(word) || entry.city.contains(word)
                        || entry.localName.contains(word) || entry.localCity.contains(word) {
                rank = 2
            } else if needle.count >= 2, entry.code.hasPrefix(needle) {
                rank = 3
            } else if needle.count >= 3, entry.name.contains(needle) || entry.city.contains(needle)
                        || entry.localName.contains(needle) || entry.localCity.contains(needle) || entry.rest.contains(needle) {
                rank = 4
            } else {
                continue
            }
            ranks[rank].append(all[index])
        }
        return Array(ranks.joined().prefix(limit))
    }

    /// The closest airport to a point, if one lies within `radius` metres: the origin offered when
    /// the form opens (the traveler is usually standing in it), large airports preferred.
    static func nearest(to point: FlightCoordinate, within radius: Double) -> Airport? {
        var best: (airport: Airport, score: Double)?
        for airport in all {
            // A cheap box first: one degree of latitude is 111 km.
            guard abs(airport.latitude - point.latitude) * 111_000 <= radius else { continue }
            let distance = FlightGeometry.distance(
                from: point, to: FlightCoordinate(latitude: airport.latitude, longitude: airport.longitude))
            guard distance <= radius else { continue }
            // A large airport a little further away is the likelier answer than an airstrip next door.
            let score = distance + (airport.size == "L" ? 0 : airport.size == "M" ? 15_000 : 40_000)
            if best == nil || score < best!.score { best = (airport, score) }
        }
        return best?.airport
    }

    /// The airports around a point, nearest first: what the picker shows before anything is typed.
    static func near(_ point: FlightCoordinate, within radius: Double, limit: Int) -> [Airport] {
        var found: [(airport: Airport, distance: Double)] = []
        for airport in all {
            guard abs(airport.latitude - point.latitude) * 111_000 <= radius else { continue }
            let distance = FlightGeometry.distance(
                from: point, to: FlightCoordinate(latitude: airport.latitude, longitude: airport.longitude))
            if distance <= radius { found.append((airport, distance)) }
        }
        return found.sorted { $0.distance < $1.distance }.prefix(limit).map(\.airport)
    }

    private static func load() -> [Airport] {
        guard let url = ShippedFile.url("Airports", "tsv", subdirectories: ["Data/Islam", "Islam", nil]),
              let data = ShippedFile.data(at: url),
              let text = String(data: data, encoding: .utf8) else { return [] }
        let local = localNames(language: AppLanguage.code)
        var list: [Airport] = []
        list.reserveCapacity(4_200)
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count >= 8, let latitude = Double(fields[5]), let longitude = Double(fields[6]) else { continue }
            let code = String(fields[0])
            let names = local[code]
            list.append(Airport(
                code: code, size: String(fields[1]), name: String(fields[2]), city: String(fields[3]),
                country: String(fields[4]), latitude: latitude, longitude: longitude, timeZoneID: String(fields[7]),
                keywords: fields.count > 8 ? String(fields[8]) : "",
                localName: names?.name, localCity: names?.city))
        }
        return list
    }

    /// The names file for a language ("ar", "fr", "pt-BR" reads "pt"): code to the airport's and
    /// the city's name, either of which may be missing. Empty for English and for a language
    /// without a file.
    static func localNames(language: String) -> [String: (name: String?, city: String?)] {
        let base = language.split(separator: "-").first.map(String.init) ?? language
        guard base != "en",
              let url = ShippedFile.url("AirportNames-\(base)", "tsv", subdirectories: ["Data/Islam", "Islam", nil]),
              let data = ShippedFile.data(at: url),
              let text = String(data: data, encoding: .utf8) else { return [:] }
        var names: [String: (name: String?, city: String?)] = [:]
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard fields.count >= 3 else { continue }
            names[String(fields[0])] = (fields[1].isEmpty ? nil : String(fields[1]),
                                        fields[2].isEmpty ? nil : String(fields[2]))
        }
        return names
    }
}
#endif
