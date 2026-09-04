import SwiftUI
import Combine
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
    /// 3 GB-class and below - see `PerformanceProfile.isLowEndDevice` for the threshold's reasoning.
    static var isLowMemoryDevice: Bool {
        PerformanceProfile.isLowEndDevice
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

    /// Capped everywhere now (Phase 5 step 9): nil on 3 GB+ devices pushed all 6,236 ayahs through
    /// a 5,000-entry cache that evicted itself mid-sweep, so the tail of the sweep undid its head.
    static var prewarmArabicAyahLimit: Int? {
        #if os(watchOS)
        20
        #else
        isLowMemoryDevice ? 32 : 40
        #endif
    }
}

// MARK: - Performance profile (live, observable)

/// The live performance tier, as an object views can react to.
///
/// `AppPerformance`'s static gates are correct but inert: a body reads them once and keeps whatever it
/// decided, so a view already on screen when the user flips Low Power Mode never notices. This object
/// re-reads the inputs on their notifications (power state, thermal state, Reduce Motion, Reduce
/// Transparency) and publishes only when the resolved flags actually change. The app root folds it into
/// `AppearanceEnvironment`, so one publish here re-evaluates every mounted view exactly once, together,
/// instead of each site subscribing on its own.
///
/// Main-thread only (every notification is delivered on the main queue; `shared` is first touched from
/// the app root).
final class PerformanceProfile: ObservableObject {
    static let shared = PerformanceProfile()

    enum Tier: Equatable {
        /// Materials, shadows, decorative animation, broad prewarms.
        case full
        /// Low Power Mode, a serious/critical thermal state, or a 3 GB-class device: flat fills instead of
        /// material blurs, no drop shadows, decorative animation off, prewarms narrowed to what is on screen.
        case reduced
    }

    @Published private(set) var tier: Tier = .full
    @Published private(set) var isLowPowerMode = false
    @Published private(set) var isThermallyThrottled = false
    @Published private(set) var isReduceMotionEnabled = false
    @Published private(set) var isReduceTransparencyEnabled = false

    /// 3 GB-class and below (iPhone 8, X, XR, the SE line). Memory is the one stable proxy for the GPU
    /// generation that struggles with stacked material blurs; core count is no use (every iPhone since the
    /// A11 reports six). 3.5 GB rather than 3: a "3 GB" device reports a little under 3_000_000_000 and
    /// a "4 GB" one a little under 4_000_000_000, so the old `< 3 GB` test let the XR and X through as fast.
    static let isLowEndDevice: Bool = ProcessInfo.processInfo.physicalMemory < 3_500_000_000

    /// Decorative animation off: starfield twinkle, forever pulses, launch springs. Functional
    /// transitions stay animated (Reduce Motion asks for less motion, not a frozen UI).
    var shouldReduceAnimations: Bool { isLowPowerMode || isReduceMotionEnabled }

    /// Flat fills instead of material blurs, on the pre-Liquid-Glass fallback. Each material is a
    /// backdrop pass; the Adhan tab alone stacks ~35 of them, which is the single biggest GPU cost on
    /// A11-A13 hardware. Reduce Transparency is the same request made through accessibility.
    var shouldFlattenMaterials: Bool { tier == .reduced || isReduceTransparencyEnabled }

    /// Drop shadows are offscreen render passes; skipped entirely on the reduced tier (`.softShadow`).
    var shouldDropShadows: Bool { tier == .reduced }

    private var observers: [NSObjectProtocol] = []

    private init() {
        refresh()

        var names: [Notification.Name] = [
            .NSProcessInfoPowerStateDidChange,
            ProcessInfo.thermalStateDidChangeNotification
        ]
        #if os(iOS)
        names.append(UIAccessibility.reduceMotionStatusDidChangeNotification)
        names.append(UIAccessibility.reduceTransparencyStatusDidChangeNotification)
        #elseif os(watchOS)
        names.append(NSNotification.Name.WKAccessibilityReduceMotionStatusDidChange)
        #endif
        // `.main` queue: the power-state notification arrives on an arbitrary thread, and the
        // `@Published` writes below must happen where SwiftUI reads them.
        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.refresh()
            }
        }
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    private func refresh() {
        #if DEBUG
        // "-lowPowerMode": pretend Low Power Mode is on (the simulator has no switch for it): the
        // reduced tier plus everything keyed on the flag itself, such as the Classic Look's automatic rule.
        let lpm = ProcessInfo.processInfo.isLowPowerModeEnabled
            || ProcessInfo.processInfo.arguments.contains("-lowPowerMode")
        #else
        let lpm = ProcessInfo.processInfo.isLowPowerModeEnabled
        #endif
        let thermal = ProcessInfo.processInfo.thermalState
        let throttled = thermal == .serious || thermal == .critical
        let reduceMotion = AppPerformance.isReduceMotionEnabled
        #if os(iOS)
        let reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
        #else
        let reduceTransparency = false
        #endif
        var tier: Tier = (lpm || throttled || Self.isLowEndDevice) ? .reduced : .full
        #if DEBUG
        // "-perfTierReduced": force the reduced tier on the simulator, where Low Power Mode cannot be
        // switched on and the host Mac's memory reads as a fast device - the only way to screenshot
        // the flat-material / no-shadow path headlessly.
        if ProcessInfo.processInfo.arguments.contains("-perfTierReduced") { tier = .reduced }
        #endif

        // Assign only what changed: each `@Published` write is a publish, and the root re-renders per publish.
        if isLowPowerMode != lpm { isLowPowerMode = lpm }
        if isThermallyThrottled != throttled { isThermallyThrottled = throttled }
        if isReduceMotionEnabled != reduceMotion { isReduceMotionEnabled = reduceMotion }
        if isReduceTransparencyEnabled != reduceTransparency { isReduceTransparencyEnabled = reduceTransparency }
        if self.tier != tier { self.tier = tier }
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
        case .custom: return Self.cachedCustomColor(hex: Self.customHexForThisProcess)
        }
    }

    /// The custom-accent hex as THIS process can see it. The app reads the live property; a widget or
    /// complication reads the App Group mirror the app writes on every change, so painting `.custom`
    /// no longer costs the extension the whole `Settings.init` (three location decodes, ~240 stored
    /// properties) for one string. Read once per extension process - it is a short-lived one.
    private static let extensionCustomHex: String = {
        UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)?.string(forKey: "customAccentColorHex") ?? "34C759"
    }()
    private static var customHexForThisProcess: String {
        Settings.isAppProcess ? Settings.shared.customAccentColorHex : extensionCustomHex
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

    /// Indents a setting that only exists because the setting above it is on.
    ///
    /// A dependent switch shown flush with its parent reads as a peer, and a reader hunting for why
    /// it vanished has nothing to look at; one step of indentation says "this belongs to the row
    /// above" without a second header or a nested box. Used for the word-by-word lines, Hide Arabic
    /// Dots under Hide Tashkeel, the nagging schedule under Nagging Mode, and their kin.
    func settingsDependent() -> some View {
        padding(.leading, 16).padding(.vertical, 2)
    }
}

extension String {
    /// آ (U+0622) written as its canonical parts: ا + the combining maddah (U+0653).
    ///
    /// The KFGQPC Hafs face - the one the Quran is set in, and the only one whose tajweed colouring
    /// stays crisp - ships no precomposed آ, because the Madinah mushaf itself writes the maddah as a
    /// separate mark. Ordinary Arabic prose (hadith, adhkar, duas, the 99 Names) uses the precomposed
    /// character constantly, so rendering it in that face left thousands of characters to the system
    /// fallback mid-word. The face DOES carry both pieces and positions marks (`mark`/`mkmk` GPOS), so
    /// swapping in the decomposition renders identically without touching the font itself - which the
    /// KFGQPC licence forbids ("no modifying, altering").
    ///
    /// Canonical equivalence, so search, copy and share are unaffected; the other faces (IndoPak,
    /// system) draw the decomposed form the same way they draw the composed one.
    var decomposingAlefMadda: String {
        contains("\u{0622}") ? replacingOccurrences(of: "\u{0622}", with: "\u{0627}\u{0653}") : self
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

            // ٱ (hamzatul-wasl) is KEPT - `cleanSearch` folds it to a plain ا downstream. Dropping the
            // whole cluster here made the silent-lane blob start "لذين" instead of "الذين", so every
            // silent-letter query beginning with ال missed for a reason users could never see.

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

    /// Search twin of the mushaf's alif al-wiqaya: every whitespace-delimited token ending in "وا"
    /// loses that final silent alif (ءامنوا → ءامنو, وعملوا → وعملو). Applied to the ALREADY FOLDED
    /// corpus lane AND the folded query alike, so spellings with the alif, without it, or mixing
    /// both converge to identical bytes - the mushaf-sukoon fold above can't do that for queries,
    /// which carry no sukoon marks. Runs only on folded search text; NEVER fold this into the
    /// highlighter's per-cluster normalization, where a context-sensitive rule desyncs its index map.
    var removingAlifWiqayaForSearch: String {
        guard contains("وا") else { return self }
        var out = ""
        out.reserveCapacity(count)
        var token = ""

        func flushToken() {
            if token.hasSuffix("وا") {
                token.removeLast()
            }
            out += token
            token = ""
        }

        for character in self {
            if character == " " {
                flushToken()
                out.append(" ")
            } else {
                token.append(character)
            }
        }
        flushToken()

        return out
    }

    /// Search-lane twin of the dagger alif: the mushaf writes some long-a sounds as a superscript alef
    /// (يَٰنِسَآءَ, إِبۡرَٰهِـۧمَ). `cleanSearch` folds that dagger into a full ا - matching a typed
    /// "يانساء" / "ابراهيم" - and THIS fold removes it instead, matching the equally common typed
    /// spellings that omit the alif ("ينساء" / "ابرهيم"). Run it on the RAW text BEFORE `cleanSearch`
    /// (afterwards the dagger is already a full ا) and index both lanes so either spelling finds the ayah.
    var removingDaggerAlifForSearch: String {
        guard unicodeScalars.contains(where: { $0.value == 0x0670 }) else { return self }
        return String(unicodeScalars.filter { $0.value != 0x0670 })
    }

    /// Query-side twin of the mushaf's attached vocative: the Uthmani script writes "يا + noun" as ONE
    /// word (يَٰنِسَآءَ, يَٰٓأَيُّهَا), so a typed "يا نساء" can never substring-match the folded corpus,
    /// where the يا is glued to the word it calls. Joining a standalone folded "يا" token onto the token
    /// after it converges the typed form with the mushaf's. Whole tokens only - a word merely ENDING in
    /// "يا" (الدنيا) is untouched. Applied to FOLDED QUERIES as an additional lane, never to corpus blobs
    /// (which carry no standalone يا) and never inside the highlighter's per-cluster fold, where any
    /// context-sensitive rule desyncs its index map.
    var joiningVocativeYaForSearch: String {
        guard contains("يا ") else { return self }
        let tokens = split(separator: " ", omittingEmptySubsequences: true)
        var out: [String] = []
        out.reserveCapacity(tokens.count)
        var index = 0
        while index < tokens.count {
            if tokens[index] == "يا", index + 1 < tokens.count {
                out.append("يا" + tokens[index + 1])
                index += 2
            } else {
                out.append(String(tokens[index]))
                index += 1
            }
        }
        return out.joined(separator: " ")
    }

    /// Whether the text carries a BARE hamza (ء) - the one the reader has to go out of their way to
    /// type, and therefore the one that should mean something. Seated hamzas (أ إ آ ؤ ئ) don't count:
    /// they come along for free with ordinary spellings.
    var containsBareHamza: Bool {
        unicodeScalars.contains { $0.value == 0x0621 }
    }

    /// The dagger-alif variants a corpus text has to be checked against, deduplicated. The mushaf writes
    /// some long-a sounds as a superscript alef; the main fold turns it into a full ا and this pairs that
    /// with the spelling that omits it, which is the same two-lane treatment the search index uses.
    var arabicDaggerVariantsForSearch: [String] {
        let dropped = removingDaggerAlifForSearch
        return dropped == self ? [self] : [self, dropped]
    }

    /// Noon maps to U+06BA (not U+066E like ba/ta/tha): in the early rasm a FINAL noon keeps its
    /// deep bowl while ba/ta/tha finals stay flat, and U+06BA is exactly that skeleton - bowl in
    /// isolated/final position, tooth elsewhere. Must stay in lockstep with `dotlessArabicScalar`
    /// (QuranData.swift), the scalar-level twin the tajweed projection uses.
    var removingArabicDots: String {
        let dotlessMap: [Character: Character] = [
            "أ": "ا", "إ": "ا", "ؤ": "ء", "ئ": "ء",
            "آ": "ا", "ٱ": "ا", "ى": "ى",
            "ب": "ٮ", "ت": "ٮ", "ث": "ٮ", "ن": "ں", "ي": "ى",
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
    /// The bundled printed-mushaf facsimile for the selected riwayah (see `MushafPDFLibrary`). Page mode
    /// only - a printed page has no list equivalent - and only offered when that riwayah's PDF is bundled.
    case pdf
    case transliteration
    case clearQuran
    case saheeh

    var id: String { rawValue }
    /// The PDF is Arabic, but it is NOT composed text: it renders as a page image, so everything gated on
    /// "is this page English" (tajweed, qiraat comparison, the text composer) must treat it as neither.
    var isEnglish: Bool { self != .arabic && self != .pdf }
    var isPDF: Bool { self == .pdf }

    var displayName: String {
        switch self {
        case .arabic:          return "Arabic"
        case .pdf:             return "Printed Mushaf (PDF)"
        case .transliteration: return "Transliteration (English)"
        case .clearQuran:      return "The Clear Quran (English)"
        case .saheeh:          return "Saheeh International (English)"
        }
    }
}

/// How the printed-mushaf facsimile is lit. `auto` (the default) follows the app's light/dark
/// appearance; `light` always shows the printed page as printed; `night` always applies the
/// hue-preserving invert. Raw values are persisted in `Settings.mushafPDFAppearance`.
enum MushafPDFAppearance: String, CaseIterable, Identifiable {
    case auto
    case light
    case night

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto:  return "Automatic"
        case .light: return "Light"
        case .night: return "Night"
        }
    }

    var systemImage: String {
        switch self {
        case .auto:  return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .night: return "moon"
        }
    }

    /// Whether the invert applies, given whether the surrounding appearance is dark.
    func isNight(inDarkScheme dark: Bool) -> Bool {
        self == .night || (self == .auto && dark)
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

/// The DEBUG launch stopwatch (`-launchTiming`): "LAUNCH TIMING <label> +<ms>" lines, measured from the
/// app struct's init (pre-main time is constant across builds and not something these phases touch). The
/// marks sit at the hand-offs the launch is built from - stores ready, Quran tab settled, warm, finale,
/// reveal - so a session can read where a cold launch spends its time instead of guessing from sleeps.
enum LaunchClock {
    static let start = Date()
    static func elapsedMS() -> Int { Int(Date().timeIntervalSince(start) * 1000) }
    #if DEBUG
    static let enabled = ProcessInfo.processInfo.arguments.contains("-launchTiming")
    static func mark(_ label: String) {
        guard enabled else { return }
        NSLog("LAUNCH TIMING %@ +%d ms", label, elapsedMS())
    }
    #else
    @inline(__always) static func mark(_ label: String) {}
    #endif
}

/// `-renderCounter` (DEBUG): counts the SwiftUI body evaluations of the views that call `hit` and logs
/// "RENDER COUNT <label> n, ..." once per second, only for seconds that had any. The way to prove
/// "zero body evaluations per second while idle" headlessly, where the SwiftUI instrument cannot run.
/// Bodies run on the main thread, so the dictionary needs no lock.
enum RenderCounter {
    #if DEBUG
    static let enabled = ProcessInfo.processInfo.arguments.contains("-renderCounter")
    private static var counts: [String: Int] = [:]
    private static var flushScheduled = false

    static func hit(_ label: String) {
        guard enabled else { return }
        counts[label, default: 0] += 1
        guard !flushScheduled else { return }
        flushScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            flushScheduled = false
            let line = counts.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: ", ")
            counts.removeAll(keepingCapacity: true)
            NSLog("RENDER COUNT %@", line)
        }
    }
    #else
    @inline(__always) static func hit(_ label: String) {}
    #endif
}

#if canImport(UIKit)
/// `UIFont(name:size:)` resolves the face through the font registry every call; the mushaf composer
/// asked for it ~450 times per page fit and the word-by-word layout once per cell (Phase 5 step 11).
/// Keyed by name and size, thread-safe, never evicted (a few dozen entries at most).
enum QuranFontCache {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var fonts: [String: UIFont] = [:]

    static func font(name: String, size: CGFloat) -> UIFont? {
        let key = "\(name)|\(size)"
        lock.lock()
        if let hit = fonts[key] { lock.unlock(); return hit }
        lock.unlock()
        guard let font = UIFont(name: name, size: size) else { return nil }
        lock.lock(); fonts[key] = font; lock.unlock()
        return font
    }
}
#endif

/// `-renderCounter` companion for the OTHER observable objects (DEBUG): counts every `objectWillChange`
/// of an attached object per second and logs "OBJECT PUBLISH <label> n, ...". `Settings` has its own
/// counter (`-publishCounter`); this one answers "which store woke the readers up?".
enum ObjectPublishCounter {
    #if DEBUG
    private static var counts: [String: Int] = [:]
    private static var flushScheduled = false
    private static var subscriptions: [AnyCancellable] = []

    static func attach<Object: ObservableObject>(_ object: Object, label: String) {
        guard RenderCounter.enabled else { return }
        subscriptions.append(object.objectWillChange.sink { _ in note(label) })
    }

    private static func note(_ label: String) {
        counts[label, default: 0] += 1
        guard !flushScheduled else { return }
        flushScheduled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            flushScheduled = false
            let line = counts.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: ", ")
            counts.removeAll(keepingCapacity: true)
            NSLog("OBJECT PUBLISH %@", line)
        }
    }
    #else
    @inline(__always) static func attach<Object: ObservableObject>(_ object: Object, label: String) {}
    #endif
}

/// Live mirror of the reveal state for code that checks it from ESCAPING tasks. A value-type modifier's
/// captured `@Environment(\.appRevealed)` snapshot freezes at capture time - the review prompt's retry
/// loop, whose capture chain starts before the launch cover lifts, read a stale `false` forever and
/// silently suppressed the prompt for the whole session. Defaults to `true` for the same reason as the
/// environment key (Watch app, previews); only the iPhone app root writes it.
@MainActor enum AppReveal {
    static var revealed = true {
        didSet {
            guard revealed else { return }
            let parked = waiters
            waiters.removeAll()
            parked.forEach { $0.resume() }
        }
    }

    private static var waiters: [CheckedContinuation<Void, Never>] = []

    /// Parks a task until the launch/splash cover has lifted. Deferred launch work (the 17-book
    /// hadith sweep, the broad surah sweep, the NLEmbedding probe) waits on this so the under-cover
    /// warm - the window the launch screen's reveal is actually gated on - keeps the main actor and
    /// the disk to itself. A continuation, not a poll: a dozen tasks park here at launch, and their
    /// 100 ms wakeups were timers Low Power Mode throttles and the launch window paid for. A parked
    /// task resumes on the reveal (always within seconds) and checks its own cancellation after.
    static func waitUntilRevealed() async {
        if revealed || Task.isCancelled { return }
        await withCheckedContinuation { continuation in
            if revealed {
                continuation.resume()
            } else {
                waiters.append(continuation)
            }
        }
    }
}
