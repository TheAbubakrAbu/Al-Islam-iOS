import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - App identifiers
/// Central place for reverse-DNS strings and the App Group name.
/// When you change these, update `Resources/Entitlements-Main.entitlements`,
/// `Resources/Entitlements-Widget.entitlements`, and `Resources/Info-Main.plist` to match.
enum AppIdentifiers {
    static let appFullName = "Al-Islam | Islamic Pillars"
    static let appName = "Al-Islam"
    
    static let mainColor = AccentColor.alIslam
    static let mainColorString = "alIslam"
    
    /// Shared App Group for `UserDefaults` / data (matches entitlements).
    static let appGroupSuiteName = "group.com.IslamicPillars.AppGroup"

    /// Main iOS bundle ID and OSLog subsystem prefix (matches `PRODUCT_BUNDLE_IDENTIFIER` for the app target).
    static let bundleIdentifier = "com.Quran.Elmallah.Islamic-Pillars"

    static let backgroundFetchPrayerTimesTaskIdentifier = "\(bundleIdentifier).fetchPrayerTimes"
    static let reciterDownloadsBackgroundSessionIdentifier = "\(bundleIdentifier).reciter-downloads"
    static let networkMonitorQueueLabel = "\(bundleIdentifier).NetworkMonitor"
    static let reciterDownloadDedupeQueueLabel = "\(bundleIdentifier).reciter-dedupe"
}

enum AppPerformance {
    static var isLowMemoryDevice: Bool {
        ProcessInfo.processInfo.physicalMemory < 3_000_000_000
    }

    static var shouldAvoidBroadPrewarm: Bool {
        #if os(watchOS)
        true
        #else
        isLowMemoryDevice
        #endif
    }

    static var ayahRowCacheLimit: Int {
        #if os(watchOS)
        900
        #else
        isLowMemoryDevice ? 1800 : 5000
        #endif
    }

    static var preparedSurahCacheLimit: Int {
        #if os(watchOS)
        24
        #else
        isLowMemoryDevice ? 60 : 160
        #endif
    }

    static var tajweedAttributedCacheLimit: Int {
        #if os(watchOS)
        180
        #else
        isLowMemoryDevice ? 700 : 1800
        #endif
    }

    static var cleanArabicCacheLimit: Int {
        #if os(watchOS)
        400
        #else
        isLowMemoryDevice ? 1500 : 4000
        #endif
    }

    static var prewarmArabicAyahLimit: Int? {
        #if os(watchOS)
        20
        #else
        isLowMemoryDevice ? 32 : nil
        #endif
    }
}

/// An accent is a *pair* of colors, not one.
///
/// `color` is the primary and drives every flat tint in the app — it's what the hundreds of existing
/// `settings.accentColor.color` call sites read, so none of them change. `secondaryColor` is the far stop,
/// and for most presets it is simply the same color, which makes `gradient` collapse to a solid fill that
/// renders identically to the flat one. Only `alIslam` (green → yellow) and a `custom` accent with a second
/// color chosen actually read as a gradient.
enum AccentColor: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    /// `alIslam` leads the list because it is the app's own accent, and the default.
    case alIslam, red, orange, yellow, green, blue, indigo, cyan, teal, mint, purple, pink, brown, custom

    /// The brand pair: systemGreen into systemYellow.
    static let alIslamPrimaryHex = "34C759"
    static let alIslamSecondaryHex = "FFD60A"

    var displayName: String {
        self == .alIslam ? "Al-Islam" : rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .alIslam: return Color(hex: Self.alIslamPrimaryHex) ?? .green
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .indigo: return .indigo
        case .cyan: return .cyan
        case .teal: return .teal
        case .mint: return .mint
        case .purple: return .purple
        case .pink: return .pink
        case .brown: return .brown
        // Resolved from the user's stored hex. Views observe `settings`, so changing the hex re-renders them.
        case .custom: return Color(hex: Settings.shared.customAccentColorHex) ?? .green
        }
    }

    /// The gradient's far stop. Equal to `color` unless this accent genuinely has two — see `isGradient`.
    var secondaryColor: Color {
        switch self {
        case .alIslam:
            return Color(hex: Self.alIslamSecondaryHex) ?? .yellow
        case .custom:
            // An empty second hex is how "the user picked only one color" is stored: both stops are that color.
            return Color(hex: Settings.shared.customAccentColorHex2) ?? color
        default:
            return color
        }
    }

    /// True when the two stops differ, so a view can keep its plain rendering for a solid accent instead of
    /// swapping in a gradient that would look the same but lay out subtly differently.
    var isGradient: Bool {
        switch self {
        case .alIslam: return true
        case .custom: return Color(hex: Settings.shared.customAccentColorHex2) != nil
        default: return false
        }
    }

    var gradientColors: [Color] { [color, secondaryColor] }

    func gradient(from start: UnitPoint = .topLeading, to end: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: start, endPoint: end)
    }

    /// For rings and arcs: sweeps out to the second color and back, so the seam at 0° doesn't show.
    var angularGradient: AngularGradient {
        AngularGradient(colors: [color, secondaryColor, color], center: .center)
    }
}

/// Preset swatches shown in Appearance. `.custom` is excluded — it's driven by the color picker instead.
let accentColors: [AccentColor] = AccentColor.allCases.filter { $0 != .custom }

extension Color {
    /// Creates a color from a 6-digit RGB hex string ("RRGGBB", leading "#" optional). Returns nil if invalid.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let rgb = UInt64(s, radix: 16) else { return nil }
        self = Color(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    /// 6-digit RGB hex string for this color.
    var hexString: String {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        let clamp = { (v: CGFloat) in Int(round(max(0, min(1, v)) * 255)) }
        return String(format: "%02X%02X%02X", clamp(r), clamp(g), clamp(b))
        #else
        return "000000"
        #endif
    }
}

struct CustomColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme? = nil
}

extension EnvironmentValues {
    var customColorScheme: ColorScheme? {
        get { self[CustomColorSchemeKey.self] }
        set { self[CustomColorSchemeKey.self] = newValue }
    }
}

func arabicNumberString(from number: Int) -> String {
    let arabicNumbers = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]
    return String(number).map { ch -> String in
        guard let digit = ch.wholeNumberValue, digit >= 0, digit <= 9 else { return String(ch) }
        return arabicNumbers[digit]
    }.joined()
}

private let quranStripScalars: Set<UnicodeScalar> = {
    var s = Set<UnicodeScalar>()

    // Tashkeel  U+064B…U+065F
    for v in 0x064B...0x065F { if let u = UnicodeScalar(v) { s.insert(u) } }

    // Quranic annotation signs  U+06D6…U+06ED
    for v in 0x06D6...0x06ED { if let u = UnicodeScalar(v) { s.insert(u) } }

    // Extras: short alif, madda, open taa marbuutah, dagger alif
    [0x0670, 0x0657, 0x0674, 0x0656].forEach { v in
        if let u = UnicodeScalar(v) { s.insert(u) }
    }

    return s
}()

extension String {
    var normalizingArabicIndicDigitsToWestern: String {
        let arabicIndicZero: UInt32 = 0x0660
        let easternArabicIndicZero: UInt32 = 0x06F0
        let asciiZero: UInt32 = 0x0030

        var out = String.UnicodeScalarView()
        out.reserveCapacity(unicodeScalars.count)

        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x0660...0x0669:
                let value = scalar.value - arabicIndicZero
                if let mapped = UnicodeScalar(asciiZero + value) {
                    out.append(mapped)
                } else {
                    out.append(scalar)
                }
            case 0x06F0...0x06F9:
                let value = scalar.value - easternArabicIndicZero
                if let mapped = UnicodeScalar(asciiZero + value) {
                    out.append(mapped)
                } else {
                    out.append(scalar)
                }
            default:
                out.append(scalar)
            }
        }

        return String(out)
    }

    var removingArabicDiacriticsAndSigns: String {
        var out = String.UnicodeScalarView()
        out.reserveCapacity(unicodeScalars.count)

        for scalar in unicodeScalars {
            switch scalar.value {
            case 0x0671: // ٱ  hamzatul-wasl
                out.append(UnicodeScalar(0x0627)!)
            default:
                if !quranStripScalars.contains(scalar) { out.append(scalar) }
            }
        }
        return String(out)
    }

    var removingArabicSukoon: String {
        String(unicodeScalars.filter { $0.value != 0x0652 })
    }

    /// Replaces the ayah-search operator characters (`# ^ % $ & | !`) with spaces. The search parser
    /// consumes these as operators, so they must be removed before the residual text is matched against
    /// (or highlighted within) ayah content — otherwise a query like `#الله` keeps the `#`, never matches
    /// the source, and nothing highlights. Operators become spaces (not deleted) to preserve word breaks.
    var removingAyahSearchOperators: String {
        let operators = Set("#^%$&|!=".unicodeScalars)
        var out = String.UnicodeScalarView()
        out.reserveCapacity(unicodeScalars.count)
        for scalar in unicodeScalars {
            out.append(operators.contains(scalar) ? " " : scalar)
        }
        return String(out)
    }

    var removingSilentArabicLettersForSearch: String {
        var out = ""
        out.reserveCapacity(count)

        for cluster in self {
            let scalars = Array(String(cluster).unicodeScalars)
            guard let base = scalars.first(where: { (0x0621...0x064A).contains($0.value) || $0.value == 0x0671 }) else {
                out.append(cluster)
                continue
            }

            if base.value == 0x0671 {
                continue
            }

            let hasStandardSukoon = scalars.contains { $0.value == 0x0652 }
            let hasDaggerAlif = scalars.contains { $0.value == 0x0670 }
            let hasShadda = scalars.contains { $0.value == 0x0651 }
            let hasUthmaniSukoon = scalars.contains { $0.value == 0x06E1 }
            let hasArabicVowel = scalars.contains {
                $0.value == 0x064E || $0.value == 0x064F || $0.value == 0x0650 ||
                $0.value == 0x064B || $0.value == 0x064C || $0.value == 0x064D ||
                $0.value == 0x0656 || $0.value == 0x0657 || $0.value == 0x065A
            }

            switch base.value {
            case 0x0627, 0x0648, 0x064A, 0x0649:
                if hasStandardSukoon && !hasUthmaniSukoon {
                    continue
                }
            case 0x0644:
                if hasStandardSukoon {
                    continue
                }
            default:
                break
            }

            if base.value == 0x0648, hasDaggerAlif, !hasArabicVowel, !hasShadda, !hasStandardSukoon, !hasUthmaniSukoon {
                continue
            }

            out.append(cluster)
        }

        return out
    }

    var removingArabicDots: String {
        let dotlessMap: [Character: Character] = [
            "أ": "ا", "إ": "ا", "ؤ": "ء", "ئ": "ء",
            "آ": "ا", "ٱ": "ا", "ى": "ى",
            "ب": "ٮ", "ت": "ٮ", "ث": "ٮ", "ن": "ٮ", "ي": "ى",
            "ج": "ح", "خ": "ح", "ذ": "د", "ز": "ر", "ش": "س", "ض": "ص",
            "ظ": "ط", "غ": "ع", "ف": "ڡ", "ق": "ٯ", "ة": "ه"
        ]
        return String(map { dotlessMap[$0] ?? $0 })
    }
    
    func removeDiacriticsFromLastLetter() -> String {
        guard !isEmpty else { return self }

        let shaddah = UnicodeScalar(0x0651)!
        let scalars = Array(unicodeScalars)
        var idx = scalars.count
        var trailingShaddahCount = 0
        var removedNonShaddah = false

        // Remove trailing Arabic marks from final letter cluster, but keep shaddah.
        while idx > 0, quranStripScalars.contains(scalars[idx - 1]) {
            if scalars[idx - 1] == shaddah {
                trailingShaddahCount += 1
            } else {
                removedNonShaddah = true
            }
            idx -= 1
        }

        guard removedNonShaddah else { return self }

        var out = String.UnicodeScalarView()
        out.reserveCapacity(idx + trailingShaddahCount)
        for scalar in scalars[0..<idx] { out.append(scalar) }
        for _ in 0..<trailingShaddahCount { out.append(shaddah) }
        return String(out)
    }

    subscript(_ r: Range<Int>) -> Substring {
        let lower = Swift.max(0, Swift.min(r.lowerBound, count))
        let upper = Swift.max(lower, Swift.min(r.upperBound, count))
        let start = index(startIndex, offsetBy: lower, limitedBy: endIndex) ?? endIndex
        let end = index(startIndex, offsetBy: upper, limitedBy: endIndex) ?? endIndex
        return self[start..<end]
    }
}
