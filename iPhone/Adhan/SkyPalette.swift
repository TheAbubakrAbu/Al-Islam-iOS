#if os(iOS)
import SwiftUI

/// The two-stop gradient the sky card wears during each prayer, with the user's overrides applied.
///
/// Only the six real prayers are editable. Everything else — Friday's Jumuah, the traveling-mode pairs, the
/// optional night times — resolves to one of those six through `editableKey`, so renaming or recoloring
/// "Maghrib" also covers "Maghrib/Isha" without a second set of pickers to keep in sync.
enum SkyPalette {
    /// In the order they occur through the day, which is the order the settings screen lists them.
    static let editablePrayers = ["Fajr", "Shurooq", "Dhuhr", "Asr", "Maghrib", "Isha"]

    static let defaults: [String: [String]] = [
        "Fajr":    ["1B2A4A", "6E5B7B"],
        "Shurooq": ["8E6E88", "E8A05C"],
        "Dhuhr":   ["2B7FC4", "8FCBE8"],
        "Asr":     ["2F6FA8", "D8B26A"],
        "Maghrib": ["C2582C", "4B2B63"],
        "Isha":    ["0C1330", "25325C"],
    ]

    /// Maps any prayer the app can be "in" onto one of the six editable slots.
    static func editableKey(for transliteration: String?) -> String {
        switch transliteration {
        case "Fajr":                                        return "Fajr"
        case "Shurooq":                                     return "Shurooq"
        case "Dhuhr", "Jumuah", "Duhaa", "Dhuhr/Asr":       return "Dhuhr"
        case "Asr":                                         return "Asr"
        case "Maghrib", "Maghrib/Isha":                     return "Maghrib"
        case "Isha", "Islamic Midnight", "Last Third":      return "Isha"
        // No prayer resolved yet (no location, or before the first fetch): the night gradient reads as
        // "nothing to show" better than a bright midday sky would.
        default:                                            return "Isha"
        }
    }

    static func defaultHexes(for key: String) -> [String] {
        defaults[key] ?? defaults["Isha"]!
    }

    static func defaultColors(for key: String) -> [Color] {
        defaultHexes(for: key).map { Color(hex: $0) ?? .black }
    }
}

extension Settings {
    /// Stored as JSON in `@AppStorage` because `@AppStorage` can't hold a dictionary. Absent keys fall back to
    /// the defaults, so a partially-customized palette is fine and a future seventh slot needs no migration.
    private var skyGradientOverrides: [String: [String]] {
        get {
            guard let data = skyGradientsJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String: [String]].self, from: data)
            else { return [:] }
            return decoded
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let json = String(data: data, encoding: .utf8) else { return }
            skyGradientsJSON = json
        }
    }

    /// Hex pair for an editable slot: the user's, or the default.
    func skyGradientHexes(for key: String) -> [String] {
        guard let stored = skyGradientOverrides[key], stored.count == 2,
              stored.allSatisfy({ Color(hex: $0) != nil })
        else { return SkyPalette.defaultHexes(for: key) }
        return stored
    }

    /// The gradient to paint for whatever prayer is showing.
    func skyGradientColors(forPrayer transliteration: String?) -> [Color] {
        skyGradientHexes(for: SkyPalette.editableKey(for: transliteration))
            .map { Color(hex: $0) ?? .black }
    }

    func setSkyGradient(top: Color, bottom: Color, for key: String) {
        var overrides = skyGradientOverrides
        let pair = [top.hexString, bottom.hexString]
        // Storing a pair identical to the default would make `hasCustomSkyGradients` lie, and the reset
        // button would offer to undo nothing.
        if pair == SkyPalette.defaultHexes(for: key) {
            overrides.removeValue(forKey: key)
        } else {
            overrides[key] = pair
        }
        skyGradientOverrides = overrides
    }

    var hasCustomSkyGradients: Bool { !skyGradientOverrides.isEmpty }

    func resetSkyGradients() {
        skyGradientsJSON = ""
    }
}
#endif
