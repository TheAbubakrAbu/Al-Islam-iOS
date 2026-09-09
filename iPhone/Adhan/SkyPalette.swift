// watchOS is in scope too: only the iPhone can EDIT the palette (SkyColorsView is iOS-only), but the
// watch complications read it to paint the same sky gradient the home-screen widgets wear. The watch's
// copy arrives through `watchSyncedAppStorageKeys`.
#if os(iOS) || os(watchOS)
import SwiftUI

/// The two-stop gradient the sky card wears during each prayer, with the user's overrides applied.
///
/// Only the six real prayers are editable. Everything else - Friday's Jumuah, the traveling-mode pairs, the
/// optional night times - resolves to one of those six through `editableKey`, so renaming or recoloring
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
    /// Decoded-overrides memo, keyed by the exact JSON it was decoded from. SkyView reads the gradient
    /// once per second while its clock ticks; without this every read re-ran `JSONDecoder` on a string
    /// that changes only when the user edits colors. The string compare is a few bytes.
    private static var skyGradientOverridesCache: (json: String, decoded: [String: [String]])?

    private static let skyGradientSharedSuite = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)

    /// The palette JSON as THIS process can see it: the app reads its own `@AppStorage`; a widget or
    /// other extension reads the app-group mirror (its standard defaults are its own, always empty),
    /// which is what lets the gradient widget wear the user's custom colors.
    private var resolvedSkyGradientsJSON: String {
        if Self.isAppProcess { return skyGradientsJSON }
        return Self.skyGradientSharedSuite?.string(forKey: "skyGradients") ?? skyGradientsJSON
    }

    /// Stored as JSON in `@AppStorage` because `@AppStorage` can't hold a dictionary. Absent keys fall back to
    /// the defaults, so a partially-customized palette is fine and a future seventh slot needs no migration.
    private var skyGradientOverrides: [String: [String]] {
        get {
            let json = resolvedSkyGradientsJSON
            if let cached = Self.skyGradientOverridesCache, cached.json == json {
                return cached.decoded
            }
            let decoded: [String: [String]]
            if let data = json.data(using: .utf8),
               let parsed = try? JSONDecoder().decode([String: [String]].self, from: data) {
                decoded = parsed
            } else {
                decoded = [:]
            }
            Self.skyGradientOverridesCache = (json, decoded)
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

    /// The TRUE prayer period at `date`, resolved against the FULL, uncombined prayer set - never the
    /// traveling-mode pairs. This is what the sky is painted from: past Isha the sky wears Isha's colors
    /// and at Asr time Asr's, even while the list (and the current-prayer label) reads "Maghrib/Isha" or
    /// "Dhuhr/Asr" (user rule). Before the day's Fajr the previous night's period still holds, which is
    /// what the second pass over yesterday is for.
    ///
    /// It lives here, beside the palette, because every surface that paints a sky has to answer this the
    /// same way. The widgets used to answer it with the COMBINED timeline, which has no Isha boundary at
    /// all while traveling: a traveler's home screen sat on Maghrib's colors all night long while the app
    /// beside it had turned to Isha hours earlier (Abu, 2026-09-09).
    func skyPeriodName(at date: Date) -> String? {
        let calendar = Calendar.current
        for dayOffset in [0, -1] {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: date),
                  let table = getPrayerTimes(for: day, fullPrayers: true) else { continue }
            if let period = prayersIncludingOptional(table, for: day).last(where: { $0.time <= date }) {
                return period.nameTransliteration
            }
        }
        return nil
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

/// The night sky's stars - the same forty-four of them wherever a sky is drawn.
///
/// The app's card twinkles them on a `TimelineView`; a widget draws one still frame of the same field,
/// since a widget cannot animate. Sharing the generator is what makes the two the same sky: the field is
/// deterministic, so a widget's stars sit exactly where the app's do, and both come out at the same hour.
enum SkyStars {
    struct Star {
        let x, y, radius, phase, brightness: Double
    }

    static let all: [Star] = {
        // A tiny linear congruential generator: deterministic, and no dependency on the Foundation RNG.
        var seed: UInt64 = 0x5EED_1517
        func next() -> Double {
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return Double((seed >> 33) & 0xFFFF) / Double(0xFFFF)
        }
        return (0..<44).map { _ in
            Star(
                x: next(),
                // Bias toward the top: on the app's card the horizon runs 79-112 pt down its 200 pt
                // (see `SkyCard.arcTopInset`), and stars below it would be underground. The fraction
                // carries to a widget of any size.
                y: next() * 0.44,
                radius: 0.6 + next() * 1.1,
                phase: next(),
                brightness: 0.35 + next() * 0.55
            )
        }
    }()

    /// Stars come out at night: full through Isha and the late-night times, fading in over Maghrib and
    /// back out through Fajr, and gone once the sun is up. Keyed on the TRUE (full-set) period, so the
    /// stars agree with the gradient while traveling - see `Settings.skyPeriodName(at:)`.
    static func opacity(forPeriod period: String?) -> Double {
        switch period {
        case "Isha", "Islamic Midnight", "Last Third": return 1
        case "Fajr":                                   return 0.5
        case "Maghrib":                                return 0.3
        default:                                       return 0
        }
    }

    /// One frame of the field. `time` drives the twinkle: the app passes its timeline's date, a widget
    /// passes its entry's, which freezes the field at that instant.
    static func draw(in context: inout GraphicsContext, size: CGSize, time: TimeInterval, opacity: Double) {
        guard opacity > 0.01 else { return }
        for star in all {
            // Each star twinkles on its own cycle, offset by its phase.
            let twinkle = 0.55 + 0.45 * sin(2 * .pi * (time / 4.0 + star.phase))
            let alpha = star.brightness * twinkle * opacity
            let rect = CGRect(
                x: star.x * size.width - star.radius,
                y: star.y * size.height - star.radius,
                width: star.radius * 2,
                height: star.radius * 2
            )
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
        }
    }
}
#endif
