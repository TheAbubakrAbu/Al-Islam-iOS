import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if os(watchOS)
import WatchKit
#endif

// MARK: - App identifiers
/// Central place for reverse-DNS strings and the App Group name.
/// When you change these, update `Resources/Entitlements-Main.entitlements`,
/// `Resources/Entitlements-Widget.entitlements`, and `Resources/Info-Main.plist` to match.
enum AppIdentifiers {
    static let appFullName = "Al-Islam | Islamic Pillars"
    static let appName = "Al-Islam"
    
    static let mainColor = AccentColor.green
    static let mainColorString = "green"
    
    /// Shared App Group for `UserDefaults` / data (matches entitlements).
    static let appGroupSuiteName = "group.com.IslamicPillars.AppGroup"

    /// Main iOS bundle ID and OSLog subsystem prefix (matches `PRODUCT_BUNDLE_IDENTIFIER` for the app target).
    static let bundleIdentifier = "com.Quran.Elmallah.Islamic-Pillars"

    static let backgroundFetchPrayerTimesTaskIdentifier = "\(bundleIdentifier).fetchPrayerTimes"
    /// The overnight BGProcessingTask twin of the refresh above. Processing tasks get the system's
    /// nightly maintenance windows (typically while charging) - the slot that actually lines up with
    /// refreshing before Fajr.
    static let backgroundProcessingRefreshTaskIdentifier = "\(bundleIdentifier).processingRefresh"
    static let reciterDownloadsBackgroundSessionIdentifier = "\(bundleIdentifier).reciter-downloads"
    static let networkMonitorQueueLabel = "\(bundleIdentifier).NetworkMonitor"
    static let reciterDownloadDedupeQueueLabel = "\(bundleIdentifier).reciter-dedupe"
}

enum AppPerformance {
    static var isLowMemoryDevice: Bool {
        ProcessInfo.processInfo.physicalMemory < 3_000_000_000
    }

    /// Live, not cached: the user can flip Low Power Mode at any moment, and every gate below should follow.
    /// LPM throttles background QoS hard, so optional work (prewarm sweeps, decorative animation) that is
    /// merely cheap in normal conditions becomes contention against the user's actual taps.
    static var isLowPowerMode: Bool {
        ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    static var shouldAvoidBroadPrewarm: Bool {
        #if os(watchOS)
        true
        #else
        isLowMemoryDevice || isLowPowerMode
        #endif
    }

    /// The OS accessibility setting. Live like `isLowPowerMode` - the user can flip it any time.
    static var isReduceMotionEnabled: Bool {
        #if os(iOS)
        UIAccessibility.isReduceMotionEnabled
        #elseif os(watchOS)
        WKAccessibilityIsReduceMotionEnabled()
        #else
        false
        #endif
    }

    /// The one gate for DECORATIVE animation (starfield twinkle, forever pulses, spinners, launch
    /// springs): off under Low Power Mode (contention) and under Reduce Motion (accessibility).
    /// Functional state transitions (a row appearing, a toggle) stay animated - Reduce Motion asks for
    /// less MOTION, not a frozen UI.
    static var shouldReduceAnimations: Bool {
        isLowPowerMode || isReduceMotionEnabled
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

/// One color per accent. `accent1` and `accent2` both resolve to it, so a screen can keep saying "this section
/// is the second accent" while the two currently look the same - the split stays wired up without a two-color
/// accent existing to drive it.
enum AccentColor: String, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    case red, orange, yellow, green, blue, indigo, cyan, teal, mint, purple, pink, brown, custom

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
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
        // Cached per hex: `.color`/`.accent1`/`.accent2` are read by nearly every row of every list, and
        // re-parsing the hex string on each read made the custom theme measurably slower than the built-ins.
        case .custom: return Self.cachedCustomColor(hex: Settings.shared.customAccentColorHex)
        }
    }

    private static let customColorLock = NSLock()
    nonisolated(unsafe) private static var customColorCache: (hex: String, color: Color)?

    private static func cachedCustomColor(hex: String) -> Color {
        customColorLock.lock()
        defer { customColorLock.unlock() }
        if let cached = customColorCache, cached.hex == hex { return cached.color }
        let parsed = Color(hex: hex) ?? .green
        customColorCache = (hex, parsed)
        return parsed
    }

    /// Kept so the (many) gradient/second-accent call sites still compile - it is simply the accent itself, so
    /// every "gradient" collapses to a solid fill that renders exactly like the flat color.
    var secondaryColor: Color { color }

    /// No accent has two stops any more, so views keep their plain rendering.
    var isGradient: Bool { false }

    var gradientColors: [Color] { [color, secondaryColor] }

    func gradient(from start: UnitPoint = .topLeading, to end: UnitPoint = .bottomTrailing) -> LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: start, endPoint: end)
    }

    /// For rings and arcs.
    var angularGradient: AngularGradient {
        AngularGradient(colors: [color, secondaryColor, color], center: .center)
    }

    // MARK: - The two accents, by name
    //
    // Sections declare which of the two they belong to (leading toolbar / location on the first, trailing
    // toolbar / prayer times on the second). Both resolve to the selected color today - picking a color takes
    // both - but the wiring stays, so a two-color accent can be reintroduced by changing only `secondaryColor`.

    /// The primary accent. Leading toolbar, location, and every "first" section.
    var accent1: Color { color }
    /// The secondary accent. Trailing toolbar, prayer times, and every "second" section.
    var accent2: Color { secondaryColor }
}

/// Preset swatches shown in Appearance. `.custom` is excluded - it's driven by the color picker instead.
let accentColors: [AccentColor] = AccentColor.allCases.filter { $0 != .custom }

// MARK: - Rounded design, app-wide
//
// Every system font in the app renders in SF Rounded. That is set once, as `.fontDesign(.rounded)` on the root
// view: `fontDesign` propagates down the environment, so it covers all ~2,200 `.font(.headline)`-style call sites
// without any of them being touched.
//
// The catch is that `fontDesign` overrides the design of *every* font in its subtree, `.custom(...)` faces
// included, which would silently replace the Quranic Arabic faces (Uthmani / Qiraat / IndoPak) with a system one.
// So each view that renders Arabic must declare which face it is actually using via `arabicFontDesign(custom:)`.

extension View {
    /// Applies the app-wide rounded design. Called once, on the root view.
    ///
    /// `fontDesign` needs iOS 16.1, and the app deploys to 15.0, so on older systems this is a no-op and the app
    /// keeps the default system face. That is a purely visual fallback: nothing below depends on the design.
    @ViewBuilder
    func appFontDesign() -> some View {
        if #available(iOS 16.1, macOS 13.0, watchOS 9.1, *) {
            self.fontDesign(.rounded)
        } else {
            self
        }
    }

    /// Declares how Arabic text in this subtree should interact with the app-wide rounded design.
    ///
    /// Pass `true` when a real bundled Arabic face (Uthmani / Qiraat / IndoPak) is in play, which opts the subtree
    /// out of the rounded design so the face renders as authored. Pass `false` when the reader picked "Basic" and
    /// the Arabic is really the system face, which keeps it rounded like the rest of the UI.
    ///
    /// A view that opts out is responsible for naming `design: .rounded` on any *system* font it still draws - the
    /// environment no longer supplies one. That case is real: an ayah keeps its Uthmani number marker even when the
    /// body text is "Basic", so the row must opt out yet still round its body.
    @ViewBuilder
    func arabicFontDesign(custom: Bool) -> some View {
        if #available(iOS 16.1, macOS 13.0, watchOS 9.1, *) {
            self.fontDesign(custom ? nil : .rounded)
        } else {
            self
        }
    }
}

extension Font {
    /// The app's Arabic font resolver. A real bundled face (Uthmani / Qiraat / IndoPak) renders as
    /// authored; the "Basic" sentinel resolves to the ROUNDED system face explicitly. A bare
    /// `.custom(sentinel, ...)` fell back to the DEFAULT design - the `fontDesign` environment never
    /// reaches `.custom` fonts - so Basic Arabic was the one text in the app that wasn't rounded.
    static func arabic(_ name: String, size: CGFloat) -> Font {
        name == Settings.systemArabicFontName
            ? .system(size: size, design: .rounded)
            : .custom(name, size: size)
    }

    /// `relativeTo` variant. The Basic branch keeps the fixed size (`.system(size:design:)` has no
    /// text-style anchor) - the trade for guaranteed rounding.
    static func arabic(_ name: String, size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        name == Settings.systemArabicFontName
            ? .system(size: size, design: .rounded)
            : .custom(name, size: size, relativeTo: style)
    }
}

#if canImport(UIKit)
extension UIFont {
    /// The rounded system face. The `fontDesign` environment only reaches SwiftUI text, so the UIKit-drawn surfaces
    /// (the mushaf page, the share-image renderer) have to ask for the design themselves to match the rest of the app.
    static func roundedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
#endif

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

/// The twelve months of the Hijri year, in order.
///
/// One table, because three screens need it: the Hijri Calendar in the Adhan tab, the Hijri Date Converter, and
/// the Hijri reference page in Pillars. Each had its own hardcoded list, and only one of them carried the Arabic.
struct HijriMonth: Identifiable {
    var id: Int { number }

    /// 1...12, matching `Calendar(identifier: .islamicUmmAlQura)`'s month component.
    let number: Int
    let english: String
    let arabic: String
    /// The four sacred months (al-ashhur al-hurum), in which fighting is forbidden: Quran 9:36.
    let isSacred: Bool
    let note: String
}

let hijriMonths: [HijriMonth] = [
    HijriMonth(number: 1,  english: "Muharram",       arabic: "مُحَرَّم",        isSacred: true,  note: "A sacred month. The Day of Ashura falls on the 10th."),
    HijriMonth(number: 2,  english: "Safar",          arabic: "صَفَر",           isSacred: false, note: "No worship is tied to this month, and there is no bad omen in it."),
    HijriMonth(number: 3,  english: "Rabi al-Awwal",  arabic: "رَبِيع الأَوَّل",  isSacred: false, note: "The month the Prophet ﷺ migrated to Madinah."),
    HijriMonth(number: 4,  english: "Rabi al-Thani",  arabic: "رَبِيع الثَّانِي", isSacred: false, note: "The second of the two Rabi months."),
    HijriMonth(number: 5,  english: "Jumada al-Ula",  arabic: "جُمَادَى الأُولَى", isSacred: false, note: "The first of the two Jumada months."),
    HijriMonth(number: 6,  english: "Jumada al-Thani", arabic: "جُمَادَى الآخِرَة", isSacred: false, note: "The second of the two Jumada months."),
    HijriMonth(number: 7,  english: "Rajab",          arabic: "رَجَب",           isSacred: true,  note: "A sacred month, standing alone between the others."),
    HijriMonth(number: 8,  english: "Sha'ban",        arabic: "شَعبَان",         isSacred: false, note: "The Prophet ﷺ fasted more in Sha'ban than in any month but Ramadan."),
    HijriMonth(number: 9,  english: "Ramadan",        arabic: "رَمَضَان",        isSacred: false, note: "The month of the obligatory fast, and the month the Quran was sent down."),
    HijriMonth(number: 10, english: "Shawwal",        arabic: "شَوَّال",         isSacred: false, note: "Eid al-Fitr is on the 1st, followed by the six recommended fasts."),
    HijriMonth(number: 11, english: "Dhul Qi'dah",    arabic: "ذُو القَعدَة",     isSacred: true,  note: "A sacred month, and one of the months of Hajj."),
    HijriMonth(number: 12, english: "Dhul Hijjah",    arabic: "ذُو الحِجَّة",     isSacred: true,  note: "A sacred month. Hajj is performed, and Eid al-Adha is on the 10th."),
]

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
    /// Whether the text carries any Arabic-script characters - drives script-aware search across the app
    /// (an Arabic query is only ever found in an Arabic field, a Latin one only in the English). Lives here
    /// with the other Arabic string utilities so every screen that searches (Quran, Hadith, Letters, 99
    /// Names, Duas, Adhkar) shares one definition.
    var containsArabicScript: Bool {
        unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) || (0x0750...0x077F).contains($0.value) || (0x08A0...0x08FF).contains($0.value) }
    }

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
    /// (or highlighted within) ayah content - otherwise a query like `#الله` keeps the `#`, never matches
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

/// Defers building a `NavigationLink` destination until navigation actually presents it. Constructing a view
/// struct is usually cheap, but it is not free (stored-property and `@State` default expressions run), and a
/// list of eager links pays that cost for every destination on every body pass.
struct LazyDestination<Content: View>: View {
    let build: () -> Content
    var body: Content { build() }
}

/// What the mushaf page reader draws as a page's body text. `arabic` is the mushaf itself; the English
/// cases swap the page's text wholesale for a Latin-script rendering (same canonical page boundaries,
/// same fit-to-page). Raw values are persisted in `Settings.mushafPageLanguage`.
enum MushafPageLanguage: String, CaseIterable, Identifiable {
    case arabic
    case transliteration
    case clearQuran
    case saheeh

    var id: String { rawValue }
    var isEnglish: Bool { self != .arabic }

    var displayName: String {
        switch self {
        case .arabic:          return "Arabic"
        case .transliteration: return "Transliteration (English)"
        case .clearQuran:      return "The Clear Quran (English)"
        case .saheeh:          return "Saheeh International (English)"
        }
    }
}

/// True once the launch/splash cover has been lifted and the tabs are actually on screen. Views that fire
/// user-facing side effects on appear (e.g. AdhanView's prayer-calculation confirmation dialogs) read this so
/// they don't present while they're only being built behind the launch screen. Defaults to `true`, so anywhere
/// it isn't explicitly set (the Watch app, previews) behaves normally. Defined here because this file is shared
/// by both the iPhone and Watch targets; it's only *set* by the iPhone app root.
struct AppRevealedKey: EnvironmentKey { static let defaultValue = true }
extension EnvironmentValues {
    var appRevealed: Bool {
        get { self[AppRevealedKey.self] }
        set { self[AppRevealedKey.self] = newValue }
    }
}

/// Live mirror of the reveal state for code that checks it from ESCAPING tasks. A value-type modifier's
/// captured `@Environment(\.appRevealed)` snapshot freezes at capture time - the review prompt's retry
/// loop, whose capture chain starts before the launch cover lifts, read a stale `false` forever and
/// silently suppressed the prompt for the whole session. Defaults to `true` for the same reason as the
/// environment key (Watch app, previews); only the iPhone app root writes it.
@MainActor enum AppReveal {
    static var revealed = true
}
