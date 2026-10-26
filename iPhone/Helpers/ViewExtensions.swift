import SwiftUI
import Combine

// MARK: - App-wide toggle style

/// The standard switch with 2pt of vertical padding (user rule: every toggle in the app breathes a
/// little). Applied ONCE at each app root via `.toggleStyle(PaddedSwitchToggleStyle())`, so no
/// individual settings row can forget it - and any future toggle gets it for free. The explicit
/// `.switch` inside is what stops the style from recursing into itself.
struct PaddedSwitchToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        // Rebuilt from the configuration's own binding + label rather than `Toggle(configuration)`,
        // which needs iOS 16 (the app deploys to 15). The explicit `.switch` inside is what stops the
        // style from recursing into itself.
        Toggle(isOn: configuration.$isOn) { configuration.label }
            .toggleStyle(.switch)
            .padding(.vertical, 2)
    }
}

// MARK: - Appearance environment (one snapshot, no per-row Settings subscriptions)

/// Everything the shared chrome used to read straight off `Settings`, snapshotted once at the app root.
///
/// `ConditionalGlassEffect`, `ThemedListRowBackground`, `ConditionalListStyle`, `AccentGlowOverlay`,
/// `AccentWashedBackground`, `AccentIconChip` and `SectionPillHeader` were each an `@ObservedObject`
/// subscriber to the whole `Settings` object - so a 114-row list registered 114 row-background
/// subscribers plus a glass subscriber per pill, and EVERY Settings publish (a page turn, a GPS fix, a
/// countdown tick) re-ran all of them. As an Equatable environment value it flows down once from the
/// root and only views that read a field that actually changed re-evaluate.
///
/// The performance flags ride along so a Low Power Mode flip re-evaluates the same views the same way.
struct AppearanceEnvironment: Equatable {
    var accent: Color
    var colorScheme: ColorScheme?
    var defaultView: Bool
    var hasCustomTheme: Bool
    /// `Settings.themeBackgroundColor`, nil on Light/Dark/System.
    var themeBackground: Color?
    /// `Settings.themeRowBackgroundColor`, nil on Light/Dark/System (so a single `if let` gates the row paint).
    var themeRowBackground: Color?
    /// `Settings.themeGlassTint`, nil for untinted system glass.
    var glassTint: Color?
    var showAccentGlow: Bool
    var alIslamGlow: Bool
    /// `PerformanceProfile.shouldFlattenMaterials`: flat fills on the pre-Liquid-Glass fallback.
    var flattenMaterials: Bool
    /// `PerformanceProfile.shouldDropShadows`: `.softShadow` becomes a no-op.
    var dropShadows: Bool
    /// `PerformanceProfile.shouldReduceAnimations`: decorative animation off.
    var reduceAnimations: Bool
    /// `PerformanceProfile.tier == .reduced` (Low Power Mode, thermal throttling, a 3 GB-class device):
    /// the gate for work that is neither a material nor a shadow nor an animation, such as the
    /// Adhan tab's magnetometer, GPS burst and sky-clock cadence.
    var isReducedTier: Bool
    /// Whether the app's own glass surfaces use Liquid Glass: iOS/watchOS 26 with the Classic Look off
    /// and, when its Low Power Mode rule is on, Low Power Mode off. False on every earlier system, so a
    /// site can read this alone. `ConditionalGlassEffect` and the glass-only decorations key on it.
    /// Not keyed on it, by design: the search field (system glass on every iOS 26, Classic Look or
    /// not, Abu's rule) and `adaptiveSafeArea` (a flip there recreated every List).
    var liquidGlass: Bool
    /// The Islam tab's Arabic face (`Settings.nonQuranArabicFontName`) and whether it is a bundled face
    /// rather than "Basic". Carried here so the article pages (Pillars, Beliefs, How-to guides, and
    /// every `ScriptureQuote` in them) read their accent and faces from this one snapshot instead of
    /// observing `Settings`: those pages are 100-300-node trees, and observation re-diffed all of them
    /// on every publish (a location tick, a countdown) while the reader scrolled.
    var islamArabicFontName: String
    var islamUsesCustomArabicFace: Bool
    /// `Settings.highlightAllahNamesIslam`: the name of Allah in red across the Islam tab's Arabic.
    /// Rides here for the same reason the faces do; `Text.islamArabic` is what spends it.
    var highlightAllahIslam: Bool
    /// The Quran face (`Settings.fontArabic`) for the ayat quoted on those pages, and its custom flag.
    var quranArabicFontName: String
    var quranUsesCustomArabicFace: Bool
    /// `Settings.quranArabicFontName(for: nil)`: the Quran face as the readers resolve it, with the
    /// script style folded in. The ported screens quote ayat in this one, not in the raw selection
    /// above, and it rides in the snapshot so a script-style change re-renders them.
    var quranDisplayFace: String
    /// The reader's type sizes and face switches (`Settings.useFontArabic`, `fontArabicSize`,
    /// `hadithArabicFontSize`, `englishFontSize`, `hadithArabicWantsCustomFace`, `cleanArabicText`):
    /// what the Tilawa port's pushed screens read beside the accent and the faces, carried here so
    /// they stop observing `Settings` (Tilawa Guide, Phase 8 step 1's tail, 2026-09-07).
    var useFontArabic: Bool
    var fontArabicSize: Double
    var hadithArabicFontSize: Double
    var englishFontSize: Double
    var hadithArabicWantsCustomFace: Bool
    var cleanArabicText: Bool

    /// `Settings.scalableIslamArabicFont(base:relativeTo:)` off the snapshot.
    func islamArabicFont(base: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        Font.arabic(islamArabicFontName, size: base, relativeTo: style)
    }

    /// The Quran face at `size`, scaling with `style`.
    func quranArabicFont(size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        Font.arabic(quranArabicFontName, size: size, relativeTo: style)
    }

    /// The resolved `liquidGlass` flag for a Settings/profile pair.
    static func liquidGlass(_ settings: Settings, profile: PerformanceProfile) -> Bool {
        guard #available(iOS 26.0, watchOS 26.0, *) else { return false }
        #if DEBUG
        // "-classicLook": force the Classic Look on the simulator without touching the stored toggle.
        if ProcessInfo.processInfo.arguments.contains("-classicLook") { return false }
        #endif
        if settings.classicLook { return false }
        if settings.classicLookInLowPower && profile.isLowPowerMode { return false }
        return true
    }

    /// The live flag, for the few static helpers with no environment (`SafeAreaInsetVStackSpacing`).
    static var liveLiquidGlass: Bool {
        liquidGlass(Settings.shared, profile: PerformanceProfile.shared)
    }

    static func snapshot(_ settings: Settings, profile: PerformanceProfile) -> AppearanceEnvironment {
        let custom = settings.hasCustomThemeColors
        return AppearanceEnvironment(
            accent: settings.accentColor.color,
            colorScheme: settings.colorScheme,
            defaultView: settings.defaultView,
            hasCustomTheme: custom,
            themeBackground: custom ? settings.themeBackgroundColor : nil,
            themeRowBackground: custom ? settings.themeRowBackgroundColor : nil,
            glassTint: settings.themeGlassTint,
            showAccentGlow: settings.showAccentGlow,
            alIslamGlow: settings.alIslamGlow,
            flattenMaterials: profile.shouldFlattenMaterials,
            dropShadows: profile.shouldDropShadows,
            reduceAnimations: profile.shouldReduceAnimations,
            isReducedTier: profile.tier == .reduced,
            liquidGlass: liquidGlass(settings, profile: profile),
            islamArabicFontName: settings.nonQuranArabicFontName,
            islamUsesCustomArabicFace: settings.islamUsesCustomArabicFace,
            highlightAllahIslam: settings.highlightAllahNamesIslam,
            quranArabicFontName: settings.fontArabic,
            quranUsesCustomArabicFace: settings.quranUsesCustomArabicFace,
            quranDisplayFace: settings.quranArabicFontName(for: nil),
            useFontArabic: settings.useFontArabic,
            fontArabicSize: settings.fontArabicSize,
            hadithArabicFontSize: settings.hadithArabicFontSize,
            englishFontSize: settings.englishFontSize,
            hadithArabicWantsCustomFace: settings.hadithArabicWantsCustomFace,
            cleanArabicText: settings.cleanArabicText
        )
    }
}

struct AppearanceEnvironmentKey: EnvironmentKey {
    /// For trees no root injects into: previews, and off-tree renders (`ImageRenderer` share cards),
    /// which never inherit the window's environment. Every real root applies
    /// `.appearanceEnvironment()`, and SwiftUI only asks for this when the key is absent.
    ///
    /// Computed, NOT a `static let`: the one-time snapshot froze the accent, theme and faces at their
    /// launch values for every reader below an un-injected root. That is how Al-Adhan and Al-Quran
    /// shipped an accent that only changed after a restart (their roots are per-app files the port
    /// never touches; `check_root_wiring.py` beside `sync_from_islam.sh` now fails the sync on it).
    /// A fresh read is still not LIVE, since nothing invalidates the reader when Settings changes,
    /// so an app root must inject; this only guarantees a fallback reader is right when it renders.
    ///
    /// Stored as an Optional (nil = no root injected) so the injectors can write through
    /// `injectedAppearance`, whose getter never builds the fallback: a key-path write reads the old
    /// value first, and through `appearance` that read built a default snapshot (and tripped the DEBUG
    /// tripwire) on every launch, from the root's own injection (Quality Guide G11).
    static let defaultValue: AppearanceEnvironment? = nil

    /// The fallback for a reader with no root above it (see above).
    static func fallback() -> AppearanceEnvironment {
        #if DEBUG
        AppearanceDefaultTripwire.note()
        #endif
        return AppearanceEnvironment.snapshot(Settings.shared, profile: PerformanceProfile.shared)
    }
}

#if DEBUG
/// Says so, once, when an on-screen tree falls back to the key's default in the app process: the mark
/// of a root (`WindowGroup`, a hand-made `UIHostingController`) that forgot `.appearanceEnvironment()`.
/// Off-tree renders trip it too and are fine; the line names the fix so the difference is obvious.
enum AppearanceDefaultTripwire {
    nonisolated(unsafe) private static var noted = false

    static func note() {
        guard !noted, Settings.isAppProcess else { return }
        noted = true
        NSLog("APPEARANCE ENV default read: a view rendered outside any `.appearanceEnvironment()` root. Expected for ImageRenderer share cards and previews; if the app's chrome ignores accent or theme changes until a restart, the app root is missing `.appearanceEnvironment()`.")
    }
}
#endif

extension EnvironmentValues {
    /// What every reader takes: the injected value, or the fallback for a tree no root reaches.
    var appearance: AppearanceEnvironment {
        get { self[AppearanceEnvironmentKey.self] ?? AppearanceEnvironmentKey.fallback() }
        set { self[AppearanceEnvironmentKey.self] = newValue }
    }

    /// What the injectors write (`.environment(\.injectedAppearance, value)`): the same storage, with
    /// a getter that never builds the fallback, so an injection is not itself a default read.
    var injectedAppearance: AppearanceEnvironment? {
        get { self[AppearanceEnvironmentKey.self] }
        set { self[AppearanceEnvironmentKey.self] = newValue }
    }
}

/// The app root's view of `Settings`: the appearance fields above plus `firstLaunch`, re-snapshotted after
/// each Settings publish and republished ONLY when one of them changed.
///
/// The root used to hold `Settings` as an `@StateObject`, so every one of its ~236 publishing fields
/// re-evaluated the window, the tab host and all five mounted tab roots. This object turns that into a
/// publish on the rare change that actually reaches the root (an accent, a theme, a color scheme, the
/// first-launch flag). The refresh is coalesced to one per run-loop turn: `objectWillChange` fires
/// before the write, so the snapshot has to be taken on the next tick anyway.
final class RootAppearance: ObservableObject {
    static let shared = RootAppearance()

    @Published private(set) var environment: AppearanceEnvironment
    @Published private(set) var firstLaunch: Bool
    /// True until the About You question has been answered or skipped (the root's `.aboutYou` stage).
    @Published private(set) var needsAboutYou: Bool
    /// True until the iCloud Backup offer has been taken or declined (the root's `.cloudOffer` stage,
    /// after About You).
    @Published private(set) var needsCloudOffer: Bool

    private var cancellable: AnyCancellable?
    private var refreshScheduled = false

    private init() {
        let settings = Settings.shared
        environment = AppearanceEnvironment.snapshot(settings, profile: PerformanceProfile.shared)
        firstLaunch = settings.firstLaunch
        needsAboutYou = Self.needsAboutYou(settings)
        needsCloudOffer = Self.needsCloudOffer(settings)
        // Re-snapshot when a slice that feeds the snapshot publishes (the chrome, the system flags,
        // the reading faces and sizes): never for a prayer change, a tracker mark or a bookmark, which
        // used to re-run this through the whole-object publish (Performance Guide, section 18).
        let feeds: [any SettingsSlice] = [
            AppearanceSettings.shared, SystemSettings.shared, QuranDisplay.shared,
            HadithSettings.shared, IslamSettings.shared,
        ]
        cancellable = Publishers.MergeMany(feeds.map(\.willChange)).sink { [weak self] _ in self?.scheduleRefresh() }
        ObjectPublishCounter.attach(self, label: "RootAppearance")
    }

    private func scheduleRefresh() {
        guard !refreshScheduled else { return }
        refreshScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.refreshScheduled = false
            self.refresh()
        }
    }

    /// Re-read the inputs and publish what changed. Also called by `AppearanceEnvironmentInjector` on a
    /// performance-profile publish, so a Low Power Mode flip lands in the same snapshot.
    func refresh() {
        let settings = Settings.shared
        let next = AppearanceEnvironment.snapshot(settings, profile: PerformanceProfile.shared)
        if next != environment { environment = next }
        if settings.firstLaunch != firstLaunch { firstLaunch = settings.firstLaunch }
        let asks = Self.needsAboutYou(settings)
        if asks != needsAboutYou { needsAboutYou = asks }
        let offers = Self.needsCloudOffer(settings)
        if offers != needsCloudOffer { needsCloudOffer = offers }
    }

    /// Everyone is asked once, including everyone who had the app before the question existed.
    ///
    /// DEBUG: a scripted launch (every headless recipe passes "-skipNotificationPrompt") is never
    /// asked, or each of them would land on a screen it cannot tap past. "-showAboutYou" asks anyway
    /// (it also resets the seen version in `Settings.init`), and wins over the automation marker.
    private static func needsAboutYou(_ settings: Settings) -> Bool {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if !arguments.contains("-showAboutYou"), arguments.contains("-skipNotificationPrompt") { return false }
        #endif
        return settings.aboutYouVersionSeen < Settings.aboutYouCurrentVersion
    }

    /// The iCloud offer follows the same rule (`-showCloudOffer` forces it). iPhone and iPad only,
    /// and Al-Islam only (`HAS_ICLOUD_BACKUP`): the watch has no CloudKit here, and the companion
    /// apps have no iCloud Backup, so for them this is always false.
    private static func needsCloudOffer(_ settings: Settings) -> Bool {
        #if os(iOS) && HAS_ICLOUD_BACKUP
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if !arguments.contains("-showCloudOffer"), arguments.contains("-skipNotificationPrompt") { return false }
        #endif
        return settings.cloudOfferVersionSeen < Settings.cloudOfferCurrentVersion
        #else
        return false
        #endif
    }
}

#if DEBUG
/// `-printChanges` companion: logs WHICH `AppearanceEnvironment` fields differ between consecutive
/// injections ("APPEARANCE ENV changed: ..."), since every view reading `\.appearance` re-evaluates on
/// each change and a launch-time churn there is an app-wide re-render per flip.
enum AppearanceChangeLog {
    private static var last: AppearanceEnvironment?
    private static let enabled = ProcessInfo.processInfo.arguments.contains("-printChanges")

    private static var injections = 0

    static func note(_ next: AppearanceEnvironment) {
        guard enabled else { return }
        injections += 1
        NSLog("APPEARANCE ENV injection %d", injections)
        defer { last = next }
        guard let last else { return }
        guard last != next else { return }
        var changed: [String] = []
        for (before, after) in zip(Mirror(reflecting: last).children, Mirror(reflecting: next).children)
        where String(describing: before.value) != String(describing: after.value) {
            changed.append("\(before.label ?? "?"): \(before.value) -> \(after.value)")
        }
        NSLog("APPEARANCE ENV changed: %@", changed.joined(separator: "; "))
    }
}
#endif

/// Applied once at each app root (and at any secondary `UIHostingController` root, like the achievement
/// banner window): injects the live `AppearanceEnvironment` and asserts the accent + color scheme from it.
struct AppearanceEnvironmentInjector: ViewModifier {
    @ObservedObject private var root = RootAppearance.shared
    @ObservedObject private var profile = PerformanceProfile.shared

    func body(content: Content) -> some View {
        var environment = root.environment
        // Folded here rather than through `RootAppearance.refresh()` so a profile publish and its
        // consequences land in the SAME body pass, with no intermediate frame on the old flags.
        environment.flattenMaterials = profile.shouldFlattenMaterials
        environment.dropShadows = profile.shouldDropShadows
        environment.reduceAnimations = profile.shouldReduceAnimations
        environment.isReducedTier = profile.tier == .reduced
        environment.liquidGlass = AppearanceEnvironment.liquidGlass(Settings.shared, profile: profile)
        #if DEBUG
        AppearanceChangeLog.note(environment)
        #endif
        return content
            .environment(\.injectedAppearance, environment)
            .accentColor(environment.accent)
            .tint(environment.accent)
            .preferredColorScheme(environment.colorScheme)
    }
}

#if os(iOS)
import ImageIO

/// Large bundled images decoded at the size they are shown, not at their full pixel size.
/// `Image("Phone Wallpaper").resizable()` decoded the whole 1893x4096 asset (31 MB) to paint a
/// 340-point row; the four Wallpapers rows together were ~90 MB of footprint on open, a jetsam
/// candidate on a 3 GB device (Performance Guide, Phase 6 step 4).
///
/// These assets are DATA sets in the catalog, not image sets, on purpose: `UIImage(named:)` plus
/// `preparingThumbnail(of:)` decodes the full bitmap first and keeps it in the named-image cache
/// (measured: +31 MB per wallpaper, thumbnail on top), whereas ImageIO's thumbnail path over the
/// encoded bytes materialises only the thumbnail. The results live in a cost-limited cache so a
/// second visit is instant and the total stays bounded.
enum ImageThumbnails {
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 40 << 20
        return cache
    }()
    private static let aspectLock = NSLock()
    nonisolated(unsafe) private static var aspects: [String: CGFloat] = [:]

    /// A full-width list row in pixels: the screen minus the grouped insets, at the screen's scale.
    /// On the reduced tier (Low Power Mode, a 3 GB-class device) the scale is capped at 2x: a phone
    /// wallpaper thumbnail is 10 MB at 3x and 4.5 MB at 2x, and the preview row is the only place
    /// the difference could show.
    static var rowPixelWidth: CGFloat {
        let screen = UIScreen.main
        let scale = PerformanceProfile.shared.tier == .reduced ? min(screen.scale, 2) : screen.scale
        return (screen.bounds.width - 40) * scale
    }

    private static func key(_ name: String, _ width: CGFloat) -> NSString { "\(name)@\(Int(width))" as NSString }

    private static func source(_ name: String) -> CGImageSource? {
        guard let data = NSDataAsset(name: name)?.data else { return nil }
        return CGImageSourceCreateWithData(data as CFData, nil)
    }

    /// The full asset, decoded on demand (Copy / Save). Not cached: the caller keeps it only as
    /// long as the pasteboard or the photo library needs it.
    static func fullImage(_ name: String) -> UIImage? {
        NSDataAsset(name: name).flatMap { UIImage(data: $0.data) }
    }

    /// width / height from the header, so a placeholder can hold the row's height before the decode.
    static func aspectRatio(_ name: String) -> CGFloat {
        aspectLock.lock(); defer { aspectLock.unlock() }
        if let hit = aspects[name] { return hit }
        var aspect: CGFloat = 1
        if let source = source(name),
           let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
           let height = properties[kCGImagePropertyPixelHeight] as? CGFloat, height > 0 {
            aspect = width / height
        }
        aspects[name] = aspect
        return aspect
    }

    static func cached(_ name: String, maxPixelWidth: CGFloat) -> UIImage? {
        cache.object(forKey: key(name, maxPixelWidth))
    }

    /// The asset at most `maxPixelWidth` pixels wide (aspect kept), decoded off the main thread.
    static func thumbnail(_ name: String, maxPixelWidth: CGFloat) async -> UIImage? {
        if let hit = cached(name, maxPixelWidth: maxPixelWidth) { return hit }
        let image = await Task.detached(priority: .userInitiated) { () -> UIImage? in
            guard let source = source(name) else { return nil }
            // The longest side is capped, so scale the cap by the aspect to land on the width.
            let aspect = aspectRatio(name)
            let maxPixel = aspect >= 1 ? maxPixelWidth : maxPixelWidth / aspect
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: Int(maxPixel.rounded(.up)),
            ]
            #if DEBUG
            let before = MemoryFootprint.megabytes
            #endif
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
            #if DEBUG
            if RenderCounter.enabled {
                NSLog("THUMB %@ -> %dx%d footprint %.1f -> %.1f MB", name, cgImage.width, cgImage.height, before, MemoryFootprint.megabytes)
            }
            #endif
            return UIImage(cgImage: cgImage)
        }.value
        if let image {
            let cost = Int(image.size.width * image.scale * image.size.height * image.scale * 4)
            cache.setObject(image, forKey: key(name, maxPixelWidth), cost: cost)
        }
        return image
    }
}

/// `Image(name).resizable()` for a large bundled DATA asset (see `ImageThumbnails`): shows the cached
/// thumbnail at once when there is one, otherwise a placeholder with the asset's aspect ratio (so the
/// row keeps its height) until the downsample lands. Add `.aspectRatio` / corner radii / menus
/// exactly as on the `Image` it replaces.
struct DownsampledImage: View {
    let name: String
    let maxPixelWidth: CGFloat
    @State private var image: UIImage?

    init(_ name: String, maxPixelWidth: CGFloat = ImageThumbnails.rowPixelWidth) {
        self.name = name
        self.maxPixelWidth = maxPixelWidth
        _image = State(initialValue: ImageThumbnails.cached(name, maxPixelWidth: maxPixelWidth))
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else {
                Color.clear
                    .aspectRatio(ImageThumbnails.aspectRatio(name), contentMode: .fit)
            }
        }
        .task(id: name) {
            if image == nil {
                image = await ImageThumbnails.thumbnail(name, maxPixelWidth: maxPixelWidth)
            }
        }
    }
}
#else
/// watchOS: the data asset decoded whole (the pre-Phase-6 behaviour), so the shared call sites read
/// the same. `ImageIO` thumbnails are iOS-only here because the watch never lists these screens
/// at a size where the decode matters.
enum ImageThumbnails {
    static func fullImage(_ name: String) -> UIImage? {
        NSDataAsset(name: name).flatMap { UIImage(data: $0.data) }
    }
}

struct DownsampledImage: View {
    let name: String
    init(_ name: String, maxPixelWidth: CGFloat = 0) { self.name = name }
    var body: some View {
        if let image = ImageThumbnails.fullImage(name) {
            Image(uiImage: image).resizable()
        } else {
            Color.clear
        }
    }
}
#endif

/// A drop shadow that disappears on the reduced performance tier. Shadows are offscreen render passes,
/// and the Adhan tab alone stacks a dozen of them on material layers; on A11-A13 hardware under Low
/// Power Mode that is the difference between a smooth and a stuttering scroll. Same signature and
/// default color as `View.shadow`, so a site is a one-word rename.
struct SoftShadow: ViewModifier {
    @Environment(\.appearance) private var appearance

    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if appearance.dropShadows {
            content
        } else {
            content.shadow(color: color, radius: radius, x: x, y: y)
        }
    }
}

/// See `settingsDependent()`. The rail reads the accent off the environment: it used to read
/// `Settings.shared.accentColor` with nothing observing it, so an accent change left every rail on
/// the old color until the app restarted (the Settings pages re-render, but a modifier with no
/// changed input is never re-evaluated).
private struct SettingsDependentRail: ViewModifier {
    @Environment(\.appearance) private var appearance

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, 14)
            .padding(.vertical, 4)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(appearance.accent.opacity(0.55))
                    .frame(width: 3)
                    .padding(.vertical, 2)
            }
    }
}

extension View {
    /// See `AppearanceEnvironmentInjector`.
    func appearanceEnvironment() -> some View {
        modifier(AppearanceEnvironmentInjector())
    }

    /// Marks a setting that only exists because the setting above it is on.
    ///
    /// A dependent switch shown flush with its parent reads as a peer, and a reader hunting for why
    /// it vanished has nothing to look at. One step of indentation plus a thin accent rail on the
    /// leading edge says "this belongs to the row above" without a second header or a nested box.
    /// Used for the word-by-word lines, Hide Arabic Dots under Hide Tashkeel, the nagging schedule
    /// under Nagging Mode, and their kin. Vertically fixed so a caption wraps instead of truncating
    /// when the row animates in.
    func settingsDependent() -> some View {
        modifier(SettingsDependentRail())
    }

    /// `.shadow(...)` that the reduced performance tier skips. See `SoftShadow`.
    func softShadow(color: Color = Color(.sRGBLinear, white: 0, opacity: 0.33), radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) -> some View {
        modifier(SoftShadow(color: color, radius: radius, x: x, y: y))
    }
}

// MARK: - Apple Music-style bar minimization
//
// The system tab bar minimizes natively on iOS 26 (`tabBarMinimizeBehavior`); the app's custom glass bars
// mimic it by watching scroll direction (iOS 18+) and shrinking while the user scrolls down, re-expanding
// on scroll-up or at the top. Everything below no-ops on older OSes and on watchOS.

/// What the collapse watcher reads from the scroll geometry each change.
struct ScrollCollapseMetrics: Equatable {
    let offset: CGFloat
    let distanceFromBottom: CGFloat
}

/// A paragraph of body prose the iPhone reader can drag-select, the way Apple News lets you highlight
/// part of an article rather than all of it or none.
///
/// Declared here rather than beside `SelectableProse` (Helpers/SelectableText.swift, iPhone-only) so
/// views shared with the Watch app - the qiraat biographies, the credits - can use it too. watchOS has
/// no text selection and simply gets the plain `Text` it always had.
struct ProseText: View {
    let text: String
    var secondary: Bool = false

    var body: some View {
        #if os(iOS)
        SelectableProse(text: text, secondary: secondary)
        #else
        Text(text)
            .font(.body)
            .foregroundColor(secondary ? .secondary : .primary)
            .fixedSize(horizontal: false, vertical: true)
        #endif
    }
}

extension View {
    /// Watches this scroll view's direction and drives `collapsed`: true while scrolling down, false on
    /// scroll-up or near either END of the content. Attach to the `List`/`ScrollView` whose bars should
    /// minimize. iOS 18+; on earlier OSes `collapsed` simply never becomes true.
    @ViewBuilder
    func collapseBarsOnScroll(_ collapsed: Binding<Bool>) -> some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            self.onScrollGeometryChange(for: ScrollCollapseMetrics.self) { geometry in
                ScrollCollapseMetrics(
                    offset: geometry.contentOffset.y + geometry.contentInsets.top,
                    distanceFromBottom: geometry.contentSize.height + geometry.contentInsets.bottom
                        - (geometry.contentOffset.y + geometry.containerSize.height)
                )
            } action: { oldValue, newValue in
                // Near the top OR the bottom the bars always expand, and no further toggling happens there.
                // The bottom half of this matters doubly: collapsing/expanding a bar CHANGES the bottom
                // inset, which re-fires this watcher - near the end of a surah that fed back into an
                // oscillation of collapse/expand springs (the end-of-surah lag). Inside the end zones the
                // early return breaks the loop.
                if newValue.offset <= 24 || newValue.distanceFromBottom <= 140 {
                    if collapsed.wrappedValue {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            collapsed.wrappedValue = false
                        }
                    }
                    return
                }
                let delta = newValue.offset - oldValue.offset
                // Jitter gate: ignore sub-2pt wobble (bounce, precision) so the bars don't flicker.
                guard abs(delta) > 2 else { return }
                let shouldCollapse = delta > 0
                if shouldCollapse != collapsed.wrappedValue {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        collapsed.wrappedValue = shouldCollapse
                    }
                }
            }
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// Streams this scroll view's TRUE scroll progress (0...1 of the scrollable span) into `update`,
    /// or nil when the content fits the viewport and there is nothing to measure. iOS 18+ (same
    /// mechanism as `collapseBarsOnScroll`); on earlier OSes `update` is simply never called, so the
    /// consumer keeps whatever coarser fallback it has. Built for the reader's top progress bar: the
    /// ayah-anchor fill only moves when the TOP-visible ayah changes, which on a surah of a page or
    /// two meant sitting at ~25% and then snapping to 100% at the footer (user report).
    @ViewBuilder
    func trackScrollFraction(_ update: @escaping (Double?) -> Void) -> some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            self.onScrollGeometryChange(for: Double.self) { geometry in
                // Same adjusted-offset convention as `collapseBarsOnScroll`: 0 at rest at the top,
                // and the span ends where `distanceFromBottom` reaches 0.
                let span = geometry.contentSize.height + geometry.contentInsets.top
                    + geometry.contentInsets.bottom - geometry.containerSize.height
                guard span > 1 else { return -1 }
                let offset = geometry.contentOffset.y + geometry.contentInsets.top
                return min(max(offset / span, 0), 1)
            } action: { _, newValue in
                update(newValue < 0 ? nil : newValue)
            }
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// Drives `active` true while the user's finger is on this scroll view (including a still hold that
    /// hasn't moved it - `.tracking`) or while their flick is still coasting (`.decelerating`). Programmatic
    /// scrolls (`.animating`) don't count: they're ours, not the user's. iOS 18+, same pattern as
    /// `collapseBarsOnScroll`; on earlier OSes `active` simply never becomes true.
    @ViewBuilder
    func trackUserScrollTouch(_ active: Binding<Bool>) -> some View {
        #if os(iOS)
        if #available(iOS 18.0, *) {
            self.onScrollPhaseChange { _, newPhase in
                let touching: Bool
                switch newPhase {
                case .tracking, .interacting, .decelerating: touching = true
                default: touching = false
                }
                if active.wrappedValue != touching {
                    active.wrappedValue = touching
                }
            }
        } else {
            self
        }
        #else
        self
        #endif
    }

    /// The minimized look for a custom glass bar: scaled toward its bottom edge and slightly faded, the same
    /// visual language as the iOS 26 minimized tab bar. Pair with `collapsibleBarRow` for the bar's
    /// secondary rows.
    ///
    /// CURRENTLY OFF: the bars keep full size while scrolling. To bring the shrink back, uncomment the
    /// three modifiers below (0.75 is the agreed minimized scale).
    func minimizedBarStyle(_ collapsed: Bool) -> some View {
        self
            // .scaleEffect(collapsed ? 0.75 : 1, anchor: .bottom)
            // .opacity(collapsed ? 0.65 : 1)
            // .animation(.spring(response: 0.35, dampingFraction: 0.85), value: collapsed)
    }

    /// Collapses a bar's secondary row (font pickers, sliders) without unmounting it. Liquid Glass
    /// surfaces cannot participate in view insertion/removal transitions - mid-flight they snapshot as
    /// black boxes, which is exactly the blocky black flash that appeared when scrolling up re-expanded
    /// a minimized bar. So the row is never inserted or removed: it stays mounted and simply loses its
    /// height, opacity, and hit-testing while the bar is minimized. No transition, no snapshot, no flash.
    ///
    /// CURRENTLY OFF alongside `minimizedBarStyle`: with the shrink disabled the secondary rows stay
    /// visible too. Uncomment the modifiers below to restore the collapse.
    func collapsibleBarRow(_ collapsed: Bool) -> some View {
        self
            // .frame(height: collapsed ? 0 : nil)
            // .clipped()
            // .opacity(collapsed ? 0 : 1)
            // The row appears and disappears with NO animation of its own: the glass picker snaps in and
            // out while the bar's scale/fade (minimizedBarStyle) provides the motion. `nil` here overrides
            // the ambient `withAnimation` the scroll watcher wraps the state change in.
            // .animation(nil, value: collapsed)
            // .allowsHitTesting(!collapsed)
    }
}

#if os(iOS)
/// The navigation container for a SHEET: `NavigationStack` on iOS 16 and later, a stack-style
/// `NavigationView` on iOS 15. Sheets that open straight onto a sub-screen (the Adhan settings on
/// Traveling Mode or Prayer Calculation) push through `navigationDestination(isPresented:)`, which
/// only a `NavigationStack` honours; a legacy `NavigationLink(isActive:)` that is already true when a
/// `NavigationView` mounts never pushes at all (2026-09-05, seen on iOS 26).
struct SheetNavigationContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
                .navigationViewStyle(.stack)
        }
    }
}
#endif

/// `safeAreaBar` (the scroll-edge effect under a floating bar) on iOS 26, a plain `safeAreaInset`
/// on earlier systems.
///
/// The branch is on the OS ONLY, never on `appearance.liquidGlass`. It used to switch to
/// `safeAreaInset` under the Classic Look, and that flip (the toggle itself, or Low Power Mode
/// with the automatic rule on) swapped the modifier around the List, which recreated the List and
/// scrolled every screen back to the top; the Adhan tab, with no bottom bar, was the one screen
/// that kept its place. A constant modifier chain keeps the List's identity, so a look change is
/// now a restyle, not a reset. The bar's pills still follow the Classic Look through
/// `conditionalGlassEffect`; only the scroll-edge treatment under them stays the system's.
///
/// `spacing` is the pre-26 `safeAreaInset` spacing between the bar and what sits above it. Its
/// default there is 8pt, while `safeAreaBar` adds none, so a screen that stacks a second bar above
/// this one (the surah reader's legend row, the Quran tab's mini player) read 16pt between the two
/// on iOS 18 against 8pt on iOS 26. Those screens pass 0; a lone bar keeps the default clearance.
struct AdaptiveSafeArea<InsetContent: View>: ViewModifier {
    let edge: VerticalEdge
    var spacing: CGFloat? = nil
    let inset: InsetContent

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            content.safeAreaBar(edge: edge) { inset }
        } else {
            content.safeAreaInset(edge: edge, spacing: spacing) { inset }
        }
        #else
        content.safeAreaInset(edge: edge, spacing: spacing) { inset }
        #endif
    }
}

extension View {
    func adaptiveSafeArea<InsetContent: View>(
        edge: VerticalEdge,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> InsetContent
    ) -> some View {
        modifier(AdaptiveSafeArea(edge: edge, spacing: spacing, inset: content()))
    }

    /// `readingWidth`: a reading list (the ayah list, a hadith chapter, an article) keeps its rows
    /// inside a ~840 pt column on wide layouts, see `ReadingColumnMargins`.
    /// `followsListViewLive`: restyle at once when "Default List View" flips. Only the screen that
    /// holds that switch wants it; every other List keeps the style it opened with (see
    /// `ConditionalListStyle.latchedDefaultView`).
    func applyConditionalListStyle(disableNowPlayingInset: Bool = false, topContentMargin: CGFloat = 0,
                                   readingWidth: Bool = false, followsListViewLive: Bool = false) -> some View {
        modifier(ConditionalListStyle(disableNowPlayingInset: disableNowPlayingInset, topContentMargin: topContentMargin,
                                      readingWidth: readingWidth, followsListViewLive: followsListViewLive))
    }


    /// `applyConditionalListStyle()` plus text selection, for the app's ARTICLE screens - the Islam
    /// tab's explainers, the tajweed topics, the how-to guides, the qiraat biographies.
    ///
    /// This is the cheap, broad half of making the app's prose selectable: it costs nothing, changes
    /// no rendering, and gives every paragraph on the screen at least a long-press "Copy". The
    /// passages worth quoting precisely use `SelectableProse` (Helpers/SelectableText.swift) on top
    /// of it, which is what actually allows a partial highlight inside a List - see the note there
    /// for why the modifier alone can't. SwiftUI doesn't apply text selection to text inside
    /// controls, so rows that are navigation links or buttons keep behaving as taps.
    ///
    /// It also carries the search's landing: a page opened from an article search result arrives with
    /// `articleScrollTarget` set to a section heading, and the list scrolls to that `ArticleHeader`
    /// as it appears (see IslamSearch.swift).
    ///
    /// `article` is the page's catalog id ("ShahadahView") for the Pillars & Beliefs and How-to pages:
    /// it puts the page's own search bar at the foot (`ArticleSearchChrome`), which finds the page's
    /// sections and scrolls to them. Pages outside the catalog (the tajweed topics, the qiraat
    /// biographies) have no searchable text and leave it nil.
    ///
    /// `fallback` is a generated page's own sections (`IslamArticle.generated`) for an `article` id the
    /// corpus does not carry (a prophecy, a prophet's sign): the bar scans those instead, and a hit
    /// scrolls to the same `ArticleHeader` heading.
    func selectableArticleList(article: String? = nil, fallback: IslamArticle? = nil,
                               disableNowPlayingInset: Bool = false, topContentMargin: CGFloat = 0) -> some View {
        modifier(SelectableArticleList(article: article, fallback: fallback,
                                       disableNowPlayingInset: disableNowPlayingInset,
                                       topContentMargin: topContentMargin))
    }

    /// The article pages' list styling on its own: the reading-width list style plus text selection on
    /// iOS. `selectableArticleList` applies it, and so does the in-page search, which has to wrap the
    /// page BEFORE the style so its results share the page's wash and bottom insets.
    func articleListStyle(disableNowPlayingInset: Bool = false, topContentMargin: CGFloat = 0) -> some View {
        let styled = applyConditionalListStyle(
            disableNowPlayingInset: disableNowPlayingInset,
            topContentMargin: topContentMargin,
            readingWidth: true
        )
        #if os(iOS)
        return styled.textSelection(.enabled)
        #else
        return styled
        #endif
    }

    /// Tints list rows for the Sepia / Gray reading themes. Apply this to the rows/sections INSIDE a `List`
    /// (not to the `List` itself) - `.listRowBackground` only propagates when attached to row content, which
    /// is why the list-level version in `ConditionalListStyle` couldn't color the cells.
    func themedListRowBackground() -> some View {
        modifier(ThemedListRowBackground())
    }

    @ViewBuilder
    func compactListSectionSpacing() -> some View {
        #if os(iOS)
        if #available(iOS 17.0, macOS 14.0, tvOS 17.0, visionOS 1.0, *) {
            self.listSectionSpacing(.compact)
        } else {
            self
        }
        #elseif os(watchOS)
        if #available(watchOS 10.0, *) {
            self.listSectionSpacing(.compact)
        } else {
            self
        }
        #else
        self
        #endif
    }

    func endEditing() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    func dismissKeyboardOnScroll() -> some View {
        modifier(DismissKeyboardOnScrollModifier())
    }

    /// The keyboard goes away at the first touch here, before any menu in this view opens. For the
    /// search filter rows: a menu whose own label or toggles change while it is on screen over a live
    /// keyboard re-entered SwiftUI's graph update through the keyboard's re-layout and aborted in
    /// AttributeGraph (iOS 26.5, found by the monkey 2026-10-09). With the keyboard down first, no
    /// menu in the row is ever updated over one.
    @ViewBuilder
    func endsEditingOnTouch() -> some View {
        #if os(iOS)
        simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in endEditing() })
        #else
        self
        #endif
    }

    func apply<V: View>(@ViewBuilder _ block: (Self) -> V) -> V {
        block(self)
    }
    
    @ViewBuilder
    func topContentMargin(_ length: CGFloat? = 0) -> some View {
        if #available(iOS 17.0, watchOS 10.0, *) {
            self.contentMargins(.top, length)
        } else {
            self
        }
    }
}

/// Vertical spacing between views inside `safeAreaInset` stacks: 8pt everywhere. It was 12pt on
/// pre-26 systems and on the Classic Look, which read as a visibly wider gap between the sort row
/// and the search field than iOS 26 draws (Abu, 2026-09-04: "make it like post 26").
enum SafeAreaInsetVStackSpacing {
    static var standard: CGFloat { 8 }
}

#if os(iOS)
/// A reading list on a phone in LANDSCAPE, given its full width back.
///
/// Measured 2026-10-05 on an iPhone 17 Pro in landscape: the ayah list's own frame came out
/// 750 x 119 pt inside an 874 x 289 pt band, because the sensor housing's safe area insets the
/// scroll view 62 pt on BOTH sides. That is 124 pt (14% of the screen) spent on nothing, on the axis
/// a landscape reader has least to spare, and it makes every line of Arabic and translation wrap
/// harder than it needs to (Abu, 2026-10-05: "it just takes up horizontal padding").
///
/// Taking it back is two halves, and both are needed:
/// 1. the SCROLL VIEW ignores the horizontal container safe area, so the list is the full 874 pt and
///    its backgrounds, dividers and row cards reach both edges;
/// 2. the ROWS re-apply the clearance themselves through `safeAreaPadding`, which (unlike the inset
///    it replaces) is the REAL per-side value - so the notch side keeps its 62 pt and the other side,
///    which never had anything to clear, reads edge to edge.
///
/// Net on the measured band: the text column goes from 750 pt to ~812 pt and nothing moves under the
/// housing. Portrait and the iPad/Mac are untouched: `enabled` is only ever true for a compact
/// height, and the modifier is structurally constant in both states so the List is never rebuilt
/// (flipping between two branches here would reset its scroll position, Quality Guide G3).
private struct ReaderLandscapeWidth: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .ignoresSafeArea(enabled ? .container : [], edges: .horizontal)
                .safeAreaPadding(enabled ? .horizontal : [])
        } else {
            content
        }
    }
}
#endif

extension View {
    /// Gives a reading list its full width back on a phone in landscape - see `ReaderLandscapeWidth`.
    /// Pass `verticalSizeClass == .compact`; it is inert everywhere else.
    @ViewBuilder
    func readerLandscapeWidth(_ enabled: Bool) -> some View {
        #if os(iOS)
        modifier(ReaderLandscapeWidth(enabled: enabled))
        #else
        self
        #endif
    }
}

/// The cushion UNDER a floating bottom bar (above the tab bar / home indicator). On iOS 26 the bar
/// floats over content and 8pt reads right. Pre-26 this has swung both ways: 8pt read as dead space
/// when the bars were built on UISearchBar, whose own fat internal padding stacked onto it ("a lot
/// of padding on pre iOS 26"), so it went to 0 - but after the 38pt SwiftUI search field replaced
/// UISearchBar, 0 left the row sitting flush on the opaque tab bar ("no spacing at the bottom looks
/// bad"). With the compact field the same 8pt now reads right on both, so the cushion is uniform.
enum BottomBarCushion {
    static var standard: CGFloat { 8 }

    /// What a floating glass bar leaves between its own bottom edge and the screen's, measured off the
    /// app's ordinary chrome: 25.5pt.
    ///
    /// Only needed where a bar sits over a HIDDEN tab bar. Normally the tab bar absorbs the home
    /// indicator's safe area and `standard` rides on top of it, which lands right. Hide the tab bar and
    /// that safe area comes back as bottom inset, so the same 8pt floats the bar ~42pt up - measured on
    /// the folded mushaf page, 2026-10-05 ("the ground from the surah/juz to bototm is 43 and for the
    /// noraml iquidi glass is 25.5"). Subtract the live safe area from this to get the padding that puts
    /// a bar back on the standard, and never let the result go below `standard`.
    static var floatingGlassGround: CGFloat { 25.5 }

    /// How much of the home indicator's safe area a bar must reach back DOWN into to sit
    /// `floatingGlassGround` off the screen edge.
    ///
    /// The bar is laid out above `safeArea`, so its own edge starts at `safeArea` + `standard`; pulling
    /// back by this much lands it on the standard. Never negative: where the inset is already smaller
    /// than the target (no home indicator), the bar stays where it is.
    static func groundedOffset(safeArea: CGFloat) -> CGFloat {
        max((safeArea + standard) - floatingGlassGround, 0)
    }
}

/// The now-playing bar's narrow seam between shared chrome and whichever module owns playback.
///
/// Lives in HELPERS - not next to QuranPlayer - so shared files never name a Quran type: this is what
/// lets the Adhan/Hadith/Islam folders plus Helpers compile in sibling apps (Al-Adhan, Al-Hadith) that
/// don't ship the Quran module at all. Apps WITH recitation wire it up from their player: QuranPlayer's
/// `isPlaying`/`isPaused` didSets call `update(showsBar:)`, and `QuranPlayer.init` installs `barContent`.
/// Apps without simply never touch it - the flag stays false, the closure stays nil, everything compiles.
///
/// Publishes only when the bar actually appears or disappears (the narrow slice, NOT the whole player:
/// this wraps every list in the app, and observing `QuranPlayer` re-rendered all of them on every
/// per-ayah publish during recitation). Main-thread by the same convention as the player's publishes.
final class PlaybackVisibility: ObservableObject {
    static let shared = PlaybackVisibility()
    private init() {}

    @Published private(set) var showsNowPlaying = false

    /// The bar view itself, installed once by the module that owns it (`QuranPlayer.init` returns
    /// `AnyView(NowPlayingView())`). Nil means this app has no bar.
    var barContent: (() -> AnyView)? = nil

    func update(showsBar: Bool) {
        guard showsBar != showsNowPlaying else { return }
        showsNowPlaying = showsBar
    }
}

/// The top-of-screen accent wash: a quiet radial glow bleeding down from the top, gone by mid-screen.
/// Every list screen gets it through `ConditionalListStyle`'s background; the page-mode readers (the
/// Quran mushaf and the Hadith pager) apply it directly, since they are not lists.
///
/// Structurally constant: all three gradients are always in the tree, and the settings only drive
/// their opacities - the accent one for the normal glow, the yellow (leading) + green (trailing)
/// pair for the Al-Islam glow, the app icon's palette split across the top corners. Everything
/// collapses to invisible when the glow is off or a custom reading theme owns the background.
struct AccentGlowOverlay: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.colorScheme) private var systemColorScheme

    /// How far down the wash reaches before it is fully faded. The default covers the navigation
    /// area and dies before mid-screen. The PDF mushaf reader passes a short reach that ends at the
    /// surah-info bar: the facsimile page starts right below it, and the wash tinting the background
    /// around the page made the (black) night page read as a separate slab on a green field.
    var verticalReach: CGFloat = 380

    /// Light mode gets the HIGHER opacity, which looks backwards written down but is what parity
    /// requires: a translucent tint over white barely shifts the pixel, while the same tint over black
    /// is most of the light in it. At the old matched-ish 0.10 the light-mode wash was invisible - the
    /// yellow half especially, yellow-on-white being the weakest pairing in the brand palette. 0.26
    /// against dark's 0.16 reads as the same glow in both; measured side by side, not guessed.
    private var resolvedStrength: Double {
        guard !appearance.hasCustomTheme, appearance.showAccentGlow else { return 0 }
        return (appearance.colorScheme ?? systemColorScheme) == .dark ? 0.16 : 0.26
    }

    @ViewBuilder
    var body: some View {
        let strength = resolvedStrength
        let brand = appearance.alIslamGlow

        // Nothing to draw: skip the GeometryReader and the three zero-opacity gradients rather than
        // composing (and compositing) invisible layers behind ~90 screens. The wash lives inside a
        // `.background`, so swapping this subtree never touches the List it sits behind.
        if strength == 0 {
            Color.clear.allowsHitTesting(false)
        } else {
            glow(strength: strength, brand: brand)
        }
    }

    private func glow(strength: Double, brand: Bool) -> some View {

        // Top-only, by explicit choice (a bottom band was tried and rolled back): the wash lights the
        // navigation-bar edge and fades before mid-screen, leaving the bottom bars on plain background.
        //
        // The radius must track the screen width or wide screens break the look: 380pt covers an
        // iPhone edge-to-edge, but on iPad/Mac the single-color glow died mid-screen (lit middle,
        // dark corners) and the brand corners never met in the middle. Scaling the circle up would
        // also drag the wash way down the page, so the vertical axis is pinned back to the iPhone's
        // reach with a y-compression - the glow becomes a wide, shallow ellipse across the whole top.
        GeometryReader { geo in
            let radius = max(380, geo.size.width)

            ZStack {
                RadialGradient(
                    colors: [appearance.accent.opacity(brand ? 0 : strength), .clear],
                    center: .top,
                    startRadius: 8,
                    endRadius: radius
                )

                // Absolute corners, not leading/trailing: the brand look is yellow on the LEFT and
                // green on the RIGHT, and it shouldn't mirror when the app runs in an RTL locale.
                RadialGradient(
                    colors: [Color.yellow.opacity(brand ? strength : 0), .clear],
                    center: UnitPoint(x: 0, y: 0),
                    startRadius: 8,
                    endRadius: radius
                )

                RadialGradient(
                    colors: [Color.green.opacity(brand ? strength : 0), .clear],
                    center: UnitPoint(x: 1, y: 0),
                    startRadius: 8,
                    endRadius: radius
                )
            }
            .frame(width: geo.size.width, height: radius)
            .scaleEffect(y: verticalReach / radius, anchor: .top)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

#if os(watchOS)
/// The watch's top accent glow: a quiet radial wash bleeding down from the top edge - the
/// wrist-scale mirror of the iPhone's top accent wash (`AccentGlowOverlay`). Every list screen gets
/// it through `ConditionalListStyle`'s watch branch, so the whole watch app sits on the same
/// grounded light. (A bottom-anchored version shipped first and read as upside-down next to the
/// iPhone, so it now matches the phone: light from the top.)
///
/// Structurally constant like its iOS sibling: all three gradients are always in the tree and the
/// settings only drive their opacities - the accent one for the normal glow, the yellow (left) +
/// green (right) pair for the Al-Islam brand look. Everything collapses to invisible when the glow
/// is off or a custom reading theme owns the background, and theme/accent flips never recreate the
/// List they sit behind.
struct WatchTopGlowOverlay: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        // The watch renders on pure black OLED, so the wash can sit a touch brighter than the
        // iPhone's dark-mode 0.16 and still stay quiet.
        let strength: Double = (appearance.hasCustomTheme || !appearance.showAccentGlow) ? 0 : 0.20
        let brand = appearance.alIslamGlow

        // Same width-tracking ellipse as the iPhone overlay: the radius follows the screen width
        // (198pt on a 45mm, wider on Ultra) so the wash spans the whole top edge, then compresses
        // vertically to the tuned 150pt reach so it still dies well above the bottom.
        GeometryReader { geo in
            let radius = max(190, geo.size.width)
            let verticalReach: CGFloat = 150

            ZStack {
                RadialGradient(
                    colors: [appearance.accent.opacity(brand ? 0 : strength), .clear],
                    center: .top,
                    startRadius: 4,
                    endRadius: radius
                )

                // Absolute corners, not leading/trailing: the brand look is yellow on the LEFT and
                // green on the RIGHT, and it shouldn't mirror when the app runs in an RTL locale.
                RadialGradient(
                    colors: [Color.yellow.opacity(brand ? strength : 0), .clear],
                    center: UnitPoint(x: 0, y: 0),
                    startRadius: 4,
                    endRadius: radius
                )

                RadialGradient(
                    colors: [Color.green.opacity(brand ? strength : 0), .clear],
                    center: UnitPoint(x: 1, y: 0),
                    startRadius: 4,
                    endRadius: radius
                )
            }
            .frame(width: geo.size.width, height: radius)
            .scaleEffect(y: verticalReach / radius, anchor: .top)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
#endif

/// The app's ambient wash as a standalone modifier - the ONE implementation of "every screen sits on
/// the same light": the themed base color + top accent glow on iOS, the top accent glow on the
/// watch. `ConditionalListStyle` routes through this for every List screen; screens that are NOT
/// system Lists (ScrollView sheets like tafsir/comparison/share, custom canvases) apply it directly
/// via `.accentWashedBackground()`. Edit the look HERE and every screen on every platform follows.
///
/// Also re-asserts the theme's color scheme and accent: sheets are their own presentation contexts
/// and don't inherit the root's `preferredColorScheme` - without this, a forced-Dark theme would
/// paint a black wash behind light-mode sheet content.
struct AccentWashedBackground: ViewModifier {
    @Environment(\.appearance) private var appearance
    @Environment(\.colorScheme) private var systemColorScheme
    /// A List's own latched "Default List View" (`ConditionalListStyle`), so its ground matches the
    /// style it kept; nil follows the setting.
    var defaultViewOverride: Bool? = nil

    private var usesDefaultView: Bool { defaultViewOverride ?? appearance.defaultView }

    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .background(
                ZStack(alignment: .top) {
                    resolvedBackground

                    AccentGlowOverlay()
                }
                .ignoresSafeArea()
            )
            .accentColor(appearance.accent)
            .tint(appearance.accent)
            .preferredColorScheme(appearance.colorScheme)
        #elseif os(watchOS)
        // The watch does NOT honor the reading themes (user rule: don't send background/theme colors
        // to the watch) - a themed ground painted the whole watch gray and its flat row color erased
        // the native rounded section cards. The watch keeps its black ground + glow, always.
        content
            .background(
                ZStack(alignment: .top) {
                    WatchTopGlowOverlay()
                }
                .ignoresSafeArea()
            )
        #else
        content
        #endif
    }

    #if os(iOS)
    /// The list background every theme resolves to - identical to what `ConditionalListStyle` painted
    /// historically (`resolvedListBackground`), kept in ONE place now.
    private var resolvedBackground: Color {
        if appearance.hasCustomTheme {
            return appearance.themeBackground ?? Color(.systemGroupedBackground)
        }
        if usesDefaultView {
            return Color(.systemGroupedBackground)
        }
        return (appearance.colorScheme ?? systemColorScheme) == .dark ? .black : .white
    }
    #endif
}

/// The reading theme's base color alone (no glow, no scheme assertion) - for the page-mode readers,
/// which draw their own `AccentGlowOverlay` but historically fell through to the bare system window
/// background, so Sepia/Gray/Custom never reached them. No-op on Light/Dark/System.
struct ThemedReaderBackground: ViewModifier {
    @Environment(\.appearance) private var appearance

    func body(content: Content) -> some View {
        content.background((appearance.themeBackground ?? Color.clear).ignoresSafeArea())
    }
}

extension View {
    /// The themed base + accent glow for screens that are not system Lists - see `AccentWashedBackground`.
    func accentWashedBackground() -> some View {
        modifier(AccentWashedBackground())
    }

    /// The reading theme's base color for page-mode readers - see `ThemedReaderBackground`.
    func themedReaderBackground() -> some View {
        modifier(ThemedReaderBackground())
    }

    /// Clamp to `limit` lines AND always reserve that much height, so a one-line item and a three-line
    /// one occupy the same box and a column of preview cards never comes out ragged. `reservesSpace`
    /// is iOS 16+; below that this degrades to a plain clamp (ragged, but never clipped or crashed).
    func reservedLineLimit(_ limit: Int = 2) -> some View {
        modifier(ReservedLineLimit(limit: limit))
    }
}

/// Backing modifier for `reservedLineLimit(_:)` - the availability branch lives here so call sites stay
/// one clean modifier.
struct ReservedLineLimit: ViewModifier {
    let limit: Int

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.0, watchOS 9.0, *) {
            content.lineLimit(limit, reservesSpace: true)
        } else {
            content.lineLimit(limit)
        }
    }
}

#if os(iOS)
/// Reading lists on wide layouts: an iPad landscape detail column is ~800 pt, the 13-inch and a Mac
/// window over 1,000, and a 20 pt translation ran 110+ characters per line there (2026-09-06 iPad
/// pass). The list's content is held to `readingWidth` and centered, so the ayah / hadith /
/// article cards and their text narrow together; margins are 0 until the column is wider than that,
/// and iPhones never get the modifier (constant per device, so the List is never rebuilt). Measured
/// from the list's own frame, so it follows split-view resizes and rotation. iOS 17+; earlier
/// systems keep the full width.
///
/// Safe-area padding, not `contentMargins(for: .scrollContent)` (2026-10-12): beside iPadOS 26's
/// floating sidebar, which hands the detail column its width as a leading safe-area inset, the
/// scroll-content margin landed on the trailing edge only (the cards sat flush against the sidebar
/// with all the spare width on the right), and on the next launch not at all. A safe-area inset is
/// what the list already honours for the sidebar, so the margin adds to it on both sides.
private struct ReadingColumnMargins: ViewModifier {
    let enabled: Bool
    @State private var width: CGFloat = 0

    static let readingWidth: CGFloat = 840
    private static let wideIdiom: Bool = UIDevice.current.userInterfaceIdiom != .phone

    func body(content: Content) -> some View {
        if enabled, Self.wideIdiom, #available(iOS 17.0, *) {
            content
                .safeAreaPadding(.horizontal, max(0, (width - Self.readingWidth) / 2))
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { width = proxy.size.width; Self.log(proxy) }
                            .onChange(of: proxy.size.width) { width = $0; Self.log(proxy) }
                    }
                )
        } else {
            content
        }
    }

    /// "-layoutLog": the list's frame, safe-area insets and the margin it was given, one line per
    /// change, for reading a wide layout headlessly (`log show --predicate 'eventMessage CONTAINS "LAYOUT"'`).
    private static func log(_ proxy: GeometryProxy) {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-layoutLog") else { return }
        let frame = proxy.frame(in: .global)
        NSLog("LAYOUT reading-column size=%.1fx%.1f global x=%.1f...%.1f safe l=%.1f r=%.1f margin=%.1f",
              proxy.size.width, proxy.size.height, frame.minX, frame.maxX,
              proxy.safeAreaInsets.leading, proxy.safeAreaInsets.trailing,
              max(0, (proxy.size.width - readingWidth) / 2))
        #endif
    }
}
#endif

struct ConditionalListStyle: ViewModifier {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var playback = PlaybackVisibility.shared

    let disableNowPlayingInset: Bool
    var topContentMargin: CGFloat = 0
    var readingWidth: Bool = false
    var followsListViewLive: Bool = false

    /// "Default List View" as this List first appeared with it. The style is an `AnyView` swap (the two
    /// list styles are different types), so a live flip destroyed and rebuilt every mounted List, 277
    /// of them: no animation, and each lost its scroll position and state (the Quran reader in another
    /// tab came back at the top of its surah). Latched, a flip restyles each screen as it next opens
    /// (Quality Guide G3); the Look and Feel page, which holds the switch, follows it live.
    @State private var latchedDefaultView: Bool?

    private var usesDefaultView: Bool {
        followsListViewLive ? appearance.defaultView : (latchedDefaultView ?? appearance.defaultView)
    }

    private var shouldShowNowPlaying: Bool {
        playback.showsNowPlaying
    }

    func body(content: Content) -> some View {
        Group {
            #if os(iOS)
            styledContent(content)
                .modifier(ReadingColumnMargins(enabled: readingWidth))
                .navigationBarTitleDisplayMode(.inline)
            #else
            watchStyledContent(content)
            #endif
        }
        .accentColor(appearance.accent)
        .tint(appearance.accent)
        .dismissKeyboardOnScroll()
        .topContentMargin(topContentMargin)
        .onAppear {
            if latchedDefaultView == nil { latchedDefaultView = appearance.defaultView }
        }
        // Force the theme's light/dark base here (not just at the app root) so sheets - which are their own
        // presentation contexts and don't inherit the root's preferredColorScheme - also adopt the theme.
        .preferredColorScheme(appearance.colorScheme)
        #if os(iOS)
        .safeAreaInset(edge: .bottom) {
            if !disableNowPlayingInset && shouldShowNowPlaying, let bar = playback.barContent {
                VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                    bar()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
                .animation(.easeInOut, value: shouldShowNowPlaying)
            }
        }
        #endif
    }

    #if os(iOS)
    // Single, structurally-constant modifier chain (only the VALUES change with the theme). Switching to/from
    // Sepia/Gray used to flip between if/else branches, which changed the view tree and recreated the List -
    // scrolling it back to the top. Keeping one branch preserves the List, so no theme change resets scroll.
    // (Row colors are handled separately by `themedListRowBackground()` applied inside each List. The wash
    // itself lives in `AccentWashedBackground` - one implementation for lists, sheets, and the watch.)
    @ViewBuilder
    private func styledContent(_ content: Content) -> some View {
        let base = (usesDefaultView ? AnyView(content) : AnyView(content.listStyle(.plain)))
            // The style the rows are drawn in, for a row that paints its own cell (`rowWash`).
            .environment(\.listUsesDefaultView, usesDefaultView)

        if #available(iOS 16.0, *) {
            // Always hidden (not just for custom themes): the wash reproduces every theme's system
            // color exactly, and hiding the system layer is what lets the accent glow show through.
            base
                .scrollContentBackground(.hidden)
                .modifier(AccentWashedBackground(defaultViewOverride: usesDefaultView))
        } else {
            base
                .modifier(AccentWashedBackground(defaultViewOverride: usesDefaultView))
        }
    }
    #endif

    #if os(watchOS)
    /// The watch styling pass: the top accent glow behind every list (via the shared
    /// `AccentWashedBackground`) plus compact section spacing, so the small screen spends its pixels
    /// on content instead of gaps. The watch List canvas is transparent over black, so the wash reads
    /// through it; the chain stays structurally constant (the glow zeroes its opacities rather than
    /// leaving the tree), preserving List identity across theme and accent flips.
    @ViewBuilder
    private func watchStyledContent(_ content: Content) -> some View {
        if #available(watchOS 10.0, *) {
            content
                .listSectionSpacing(.compact)
                .modifier(AccentWashedBackground())
        } else {
            content
                .modifier(AccentWashedBackground())
        }
    }
    #endif
}

/// `selectableArticleList`'s body: the list style, text selection on iOS, the page's own search bar
/// (catalog articles), and the scroll to a search result's section. The scroll waits a beat for the
/// pushed page to lay its rows out; scrolling in the same frame as `onAppear` lands on nothing.
private struct SelectableArticleList: ViewModifier {
    @Environment(\.articleScrollTarget) private var scrollTarget
    /// The page's landing handle: the headers register their views with it (see `ArticleScroll`).
    @StateObject private var handle = ArticleScrollHandle()

    let article: String?
    /// The page's own sections when the corpus has no article for `article` (see `ArticleSearchChrome`).
    let fallback: IslamArticle?
    let disableNowPlayingInset: Bool
    let topContentMargin: CGFloat

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            styled(content, proxy: proxy)
                .environment(\.articleScrollHandle, handle)
                .onAppear {
                    guard let scrollTarget, !scrollTarget.isEmpty else { return }
                    ArticleScroll.land(on: scrollTarget, proxy: proxy, after: 0.45, handle: handle)
                }
        }
    }

    @ViewBuilder
    private func styled(_ content: Content, proxy: ScrollViewProxy) -> some View {
        #if os(iOS)
        if let article {
            // The search chrome applies `articleListStyle` itself, around the page AND its results.
            content.modifier(ArticleSearchChrome(articleID: article, proxy: proxy, handle: handle,
                                                 disableNowPlayingInset: disableNowPlayingInset,
                                                 topContentMargin: topContentMargin, fallback: fallback))
        } else {
            content.articleListStyle(disableNowPlayingInset: disableNowPlayingInset, topContentMargin: topContentMargin)
        }
        #else
        content.articleListStyle(disableNowPlayingInset: disableNowPlayingInset, topContentMargin: topContentMargin)
        #endif
    }
}

/// Paints the per-row background for the Sepia / Gray reading themes. Must be applied to rows/sections inside
/// a `List` so `.listRowBackground` actually reaches the cells. No-op for Light/Dark/System (system colors).
/// Under the whole-tab sky (`skyPageFill`) every row is the sky's glass instead, whatever the theme.
struct ThemedListRowBackground: ViewModifier {
    @Environment(\.appearance) private var appearance
    @Environment(\.skyPageFill) private var skyPageFill

    @ViewBuilder
    func body(content: Content) -> some View {
        // iOS only: on the watch a flat `.listRowBackground` color REPLACES the native rounded
        // section cards (rows read as square, "cut off") - and the reading themes are phone-only
        // looks anyway (they no longer sync to the watch).
        #if os(iOS)
        if skyPageFill {
            content.listRowBackground(SkyPageFill.rowColor)
        } else if let rowColor = appearance.themeRowBackground {
            content.listRowBackground(rowColor)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

/// The Adhan tab under its whole-tab sky (`Settings.skyFillsAdhanTab`, SkyPageBackground.swift).
/// Declared for every platform (the watch compiles the modifiers that read it; only iOS ever sets it).
enum SkyPageFill {
    /// What every row wears over the sky: a dark glass, so the gradient shows through and the white
    /// text the dark scheme gives the rows stays legible over a pale midday blue.
    static let rowColor = Color.black.opacity(0.30)
}

private struct SkyPageFillKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True inside the Adhan tab's List while the sky fills the tab: the row backgrounds
    /// (`ThemedListRowBackground`, `RowWashBackground`) paint the sky's glass instead of a theme's or
    /// the system's opaque cell.
    var skyPageFill: Bool {
        get { self[SkyPageFillKey.self] }
        set { self[SkyPageFillKey.self] = newValue }
    }
}

private struct ListUsesDefaultViewKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    /// The style the enclosing List draws its rows in: inset-grouped cards ("Default List View" on) or
    /// plain full-width rows. `ConditionalListStyle` sets it from the value it LATCHED, so it stays true
    /// to the List on screen after the switch flips.
    var listUsesDefaultView: Bool {
        get { self[ListUsesDefaultViewKey.self] }
        set { self[ListUsesDefaultViewKey.self] = newValue }
    }
}

extension View {
    /// The wash a List row wears while it is marked: the ayah being recited, the ayah or hadith the
    /// reader tapped or landed on, a row picked in select mode, the dhikr being counted, the current
    /// prayer. Pass nil while the row is not marked.
    ///
    /// It is the row's CELL background, not a shape behind the row's content. A shape behind the
    /// content reaches only as far as its guessed outset, and the cell's edges move with the list
    /// style and the iOS version: on iOS 27 the ayah's wash stopped 4 pt short of its card on every
    /// side and the hadith's 10 pt (Abu, 2026-10-09: "make sure it takes up full vertical and
    /// horizontal"). The cell background fills the cell exactly: the whole card, rounded corners
    /// included, with "Default List View" on, and the full width between the separators with it off.
    ///
    /// It stands in for the cell's own ground, so it paints that too: the reading theme's row color,
    /// else the system color of the List style around it. An unmarked row comes out exactly as the
    /// plain cell would. Apply it to the row itself, the view the List holds: from inside a Button's
    /// label or a `.background` it never reaches the cell. On a row it wins over the List-wide
    /// `themedListRowBackground()`.
    ///
    /// The watch keeps each row's own wash: there a cell background replaces the rounded section cards.
    ///
    /// `fade` is how long the wash takes to come and go.
    func rowWash(_ wash: Color?, fade: Double = 0.15) -> some View {
        modifier(RowWash(wash: wash, fade: fade))
    }
}

/// See `rowWash`.
struct RowWash: ViewModifier {
    let wash: Color?
    let fade: Double

    func body(content: Content) -> some View {
        #if os(iOS)
        content.listRowBackground(RowWashBackground(wash: wash, fade: fade))
        #else
        content
        #endif
    }
}

#if os(iOS)
/// The cell background `rowWash` installs. A view of its own so it reads the List's environment (the
/// theme, the latched style) and fades its own changes: a cell background is updated outside the
/// transaction that changed it, so a `withAnimation` around the change never reaches it.
///
/// Hand it to `.listRowBackground` yourself only when the row must not observe what marks it: a view
/// that observes the state and builds this one re-renders alone (see AdhkarView's `SpokenRowWash`).
struct RowWashBackground: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.listUsesDefaultView) private var usesDefaultView
    @Environment(\.skyPageFill) private var skyPageFill

    let wash: Color?
    var fade: Double = 0.15

    var body: some View {
        ZStack {
            if skyPageFill {
                SkyPageFill.rowColor
            } else {
                appearance.themeRowBackground
                    ?? Color(usesDefaultView ? UIColor.secondarySystemGroupedBackground : UIColor.systemBackground)
            }
            wash ?? .clear
        }
        .animation(.easeInOut(duration: fade), value: wash)
    }
}
#endif

/// The tints the two readers mark a row with, shared so an ayah and a hadith marked the same way look
/// the same.
enum ReaderRowTint {
    /// Tapped, landed on, or holding an open sheet.
    static let attention = Color.secondary.opacity(0.18)

    /// Being recited, or picked in select mode: the accent, stronger on the plain list's bare ground.
    static func accent(_ color: Color, defaultView: Bool) -> Color {
        color.opacity(defaultView ? 0.15 : 0.25)
    }
}

struct DismissKeyboardOnScrollModifier: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            #if os(iOS)
            if #available(iOS 16.0, *) {
                // Keep `.immediately` (both `.immediately` and `.interactively` showed a weird lurch). The
                // lurch isn't the dismiss mode - it's the bottom safe-area bar re-animating its position on a
                // curve that fights the keyboard's. That's fixed at the bar itself: the search-bar container
                // strips its inherited animation transaction (see QuranView `bottomControls`) so it snaps with
                // the keyboard instead of easing separately - the same `.transaction { $0.animation = nil }`
                // fix used in NowPlayingView.
                content.scrollDismissesKeyboard(.immediately)
            } else {
                content.gesture(
                    DragGesture().onChanged { _ in
                        dismissKeyboard()
                    }
                )
            }
            #else
            content
            #endif
        }
    }

    private func dismissKeyboard() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

#if os(iOS)
/// A calculator's explanation, moved off the screen and behind a tap.
///
/// The zakah and inheritance screens carry a lot of fiqh - which view they follow, who held what,
/// the hadith behind a threshold - and it is the most valuable thing on them. It was also printed
/// as section footers, so ~340 words sat between the reader and the number they came for (Abu,
/// 2026-09-19: "so cluttered and ugly and confusing"). Nothing is deleted: each section keeps a
/// one-line caption and puts the full text behind this button, which opens it as a sheet.
struct ExplainerButton: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    let title: String
    let body_: String
    /// A short line that stays visible under the section, when one is worth having.
    var caption: String? = nil

    @State private var showing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let caption {
                Text(caption.localizedDigits)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                settings.hapticFeedback()
                showing = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "info.circle")
                        .font(.caption2.weight(.semibold))
                    Text(title.localizedDigits)
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(settings.accentColor.accent1)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showing) {
            SheetNavigationContainer {
                List {
                    Section {
                        Text(body_.localizedDigits)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 2)
                    }
                    .themedListRowBackground()
                }
                .applyConditionalListStyle()
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .sheetDismissToolbar()
            }
        }
    }
}

/// The big answer a calculator exists to produce, at the TOP of its screen.
struct CalculatorResultCard<Detail: View>: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    let title: String
    let value: String
    /// Shown under the number: the working, or why there is nothing to pay.
    @ViewBuilder let detail: () -> Detail

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundColor(settings.accentColor.accent2)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            detail()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

// The reciter's menu rows and picker: the Quran player's.
#if HAS_QURAN
/// The "Choose Reciter" row every play menu opens with, captioned with who is reciting right now
/// (Abu, 2026-09-19: the menu said only "Choose Reciter", so the current reciter was invisible until
/// you opened the picker).
///
/// A `Label` cannot carry a subtitle, but a menu Button whose label is two `Text`s and an `Image`
/// renders as a title with a smaller grey line under it - the shape Apple's own menus use. See
/// `ReciterCaptionedMenuLabel` for the one form that works.
struct ChooseReciterMenuLabel: View {
    var title: String = String(localized: "Choose Reciter")

    var body: some View {
        ReciterCaptionedMenuLabel(title: title, systemImage: "headphones")
    }
}

/// A menu row captioned with the current reciter: "Choose Reciter" itself, and a "Play Surah" row in
/// a menu that has NO Choose Reciter row (the surah-row context menu). A menu names the reciter
/// ONCE: where Choose Reciter carries it, Play Surah is a plain Label (Abu, 2026-09-21: "no point in
/// saying the name twice").
struct ReciterCaptionedMenuLabel: View {
    let title: String
    let systemImage: String

    // OBSERVED, not read once at build time. The 09-20 version read `Settings.shared` bare on the
    // belief that a menu's content is rebuilt each time it opens; it is not. A `Menu`'s items are
    // built when its HOST's body runs, and reopening the menu shows the same items again. So after
    // Choose Reciter -> pick -> reopen, the page reader's footer menu still named the old reciter,
    // because nothing in the reader had re-rendered in between (Abu, 2026-09-21, reproduced with idb:
    // the store said Saud Al-Shuraim, the reopened menu said Saad Al-Ghamdi). Subscribing here lets
    // the reciter write re-run this label, and SwiftUI carries that into the menu's items.
    private let settings = Settings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    init(title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        let reciter = settings.currentReciterDisplayName
        // The three as bare SIBLINGS: a menu row reads its label's first Text as the title, the
        // second as the grey subtitle and the Image as the glyph. Wrapped in a VStack (the 09-19
        // version) the menu flattened the stack to its first Label and dropped the reciter line.
        Text(title)
        Text(reciter)
        Image(systemName: systemImage)
    }
}

/// The reciter picker as a sheet, with the house X. Was copy-pasted into the Quran list, the reader
/// and the page reader; now also used by the per-ayah menu, whose Play/Repeat submenus grew their own
/// "Choose Reciter" entry (Abu, 2026-09-19).
struct ReciterPickerSheet: ViewModifier {
    private let settings = Settings.shared
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            SheetNavigationContainer {
                ReciterListView(dismissAfterSelectingReciter: true)
                    .environmentObject(settings)
                    .sheetDismissToolbar()
            }
            .smallMediumSheetPresentation()
        }
    }
}
#endif

/// A grid tile that taps to act and PRESSES-AND-HOLDS to open its row's menu.
///
/// Grid tiles carried no menu for most of this app's life, because a `.contextMenu` on a tile lifts the
/// WHOLE `List` row as its preview - and a grid is one `LazyVGrid` inside a single row, so every tile in
/// the section rose at once. The workaround was a corner star for favoriting and nothing else, which left
/// the grid modes with a fraction of the actions the list rows offer.
///
/// `Menu { } label: { } primaryAction: { }` has neither problem: `primaryAction` runs on a plain tap, the
/// menu opens on a long press, and SwiftUI renders it as a popover anchored to the LABEL rather than as a
/// lifted context-menu preview of the row. `TrackerPrayerToggle` (PrayerTrackerView.swift) proved the
/// pattern on the prayer tracker's five slots; Abu asked for it across every grid (2026-09-19).
///
/// Two rules for call sites:
/// - Put `.contentShape(Rectangle())` INSIDE the label, so the whole tile is pressable.
/// - Keep `gridFavoriteStar` OUTSIDE this call. Inside the label its 30 pt tap target competes with the
///   menu's long press; outside, the star keeps its own tap and the rest of the tile keeps the menu.
///
/// THE FAST HOLD (2026-09-21). Abu found the hold "very slow", here and on the prayer tracker. Measured:
/// the menu opened at ~0.45 s, which is simply UIKit's context-menu delay. SwiftUI backs this `Menu`
/// with a `UIButton` whose hold timer is a private recognizer (`_UITouchDurationObservingGestureRecognizer`),
/// so there is no public way to shorten it. What IS public: `UIControl.performPrimaryAction()` (iOS 17.4)
/// presents the menu of a button that shows its menu as the primary action, which is exactly what a
/// SwiftUI `Menu` WITHOUT `primaryAction` is. So the fast path keeps such a menu behind the label as an
/// untouchable anchor, and lays its own tap + `GridTileMenuHold.duration` recognizers over the tile; the
/// hold finds the anchor's button by frame and fires it. Below iOS 17.4, under VoiceOver (whose users
/// get the system's own menu semantics), and if the button is ever not found (a future SwiftUI backing
/// the menu some other way), the tile is the plain `Menu(primaryAction:)` it always was.
struct GridTileMenu<Label: View, Menu: View>: View {
    let primaryAction: () -> Void
    @ViewBuilder let menu: () -> Menu
    @ViewBuilder let label: () -> Label

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverOn
    @ObservedObject private var hold = GridTileMenuHold.shared
    @State private var isPressed = false

    var body: some View {
        if #available(iOS 17.4, *), !voiceOverOn, !hold.isUnavailable {
            label()
                // The dim a plain button gives its label while a finger is on it.
                .opacity(isPressed ? 0.55 : 1)
                .background(
                    SwiftUI.Menu {
                        menu()
                    } label: {
                        Color.clear
                    }
                    .menuIndicator(.hidden)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                )
                .overlay(
                    GridTileHoldLayer(isEnabled: isEnabled, isPressed: $isPressed, onTap: primaryAction)
                )
                // Switch Control and Voice Control see a button, as they do on the system path.
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { primaryAction() }
        } else {
            SwiftUI.Menu {
                menu()
            } label: {
                label()
            } primaryAction: {
                primaryAction()
            }
            // The tile IS the control - a menu chevron drawn into a 4-across grid cell is noise.
            .menuIndicator(.hidden)
            .buttonStyle(.plain)
        }
    }
}

/// A menu with optional, explicitly named shortcuts. Single tap always opens the original menu.
/// VoiceOver keeps native menu activation; shortcuts are also exposed as named accessibility actions.
struct MenuShortcut {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }
}

struct ShortcutMenu<Content: View, Label: View>: View {
    var doubleTap: MenuShortcut? = nil
    var hold: MenuShortcut? = nil
    /// The square the label fills while the shortcut layer draws it, for a toolbar item: that item is
    /// not a button, so its glass takes the label's size plus the bar's 4 pt a side (36 makes the 44 pt
    /// circle the gear beside it wears; 44 made a 52 x 44 ellipse, measured 2026-10-18). Never on the
    /// native menu, whose toolbar button already sizes its glass: a 44 pt label inside it stretched the
    /// Adhan tab's circle the same way.
    var shortcutLabelSize: CGFloat? = nil
    @ViewBuilder let content: () -> Content
    @ViewBuilder let label: () -> Label

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverOn
    @StateObject private var availability = GridTileMenuHold()
    @State private var isPressed = false
    @State private var menuRequest = 0

    private var hint: String {
        var parts = [String(localized: "Tap for menu.")]
        if let doubleTap { parts.append(String(localized: "Double tap to \(doubleTap.title.lowercased()).")) }
        if let hold { parts.append(String(localized: "Hold to \(hold.title.lowercased()).")) }
        return parts.joined(separator: " ")
    }

    var body: some View {
        control
            .accessibilityHint(voiceOverOn ? String(localized: "Actions are also available in the menu.") : hint)
            .modifier(MenuShortcutAccessibilityAction(shortcut: doubleTap))
            .modifier(MenuShortcutAccessibilityAction(shortcut: hold))
    }

    @ViewBuilder private var control: some View {
        if #available(iOS 17.4, *), !voiceOverOn, !availability.isUnavailable,
           doubleTap != nil || hold != nil {
            label()
                .frame(width: shortcutLabelSize, height: shortcutLabelSize)
                .contentShape(Rectangle())
                // A native menu tints its label; this one is drawn outside any button, so it says so
                // (the ⋯ of every tab with a shortcut came out white beside the Adhan tab's accent one).
                .foregroundStyle(.tint)
                .opacity(isPressed ? 0.55 : 1)
                .background(
                    SwiftUI.Menu { content() } label: { Color.clear }
                        .fixedMenuOrder()
                        .menuIndicator(.hidden)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                )
                .overlay(
                    GridTileHoldLayer(isEnabled: isEnabled, isPressed: $isPressed, onTap: {},
                                      tapOpensMenu: true, onDoubleTap: doubleTap?.action,
                                      onHold: hold?.action, menuRequest: menuRequest,
                                      onUnavailable: { availability.markUnavailable() })
                )
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { menuRequest += 1 }
        } else {
            SwiftUI.Menu { content() } label: { label() }
                .fixedMenuOrder()
        }
    }
}

private struct MenuShortcutAccessibilityAction: ViewModifier {
    let shortcut: MenuShortcut?

    @ViewBuilder func body(content: Content) -> some View {
        if let shortcut {
            content.accessibilityAction(named: Text(shortcut.title), shortcut.action)
        } else {
            content
        }
    }
}

/// The fast hold's one tunable and its kill switch. See `GridTileMenu`.
final class GridTileMenuHold: ObservableObject {
    static let shared = GridTileMenuHold()

    /// Half the system's delay. Shorter than this and a thumb resting before a scroll opens menus.
    static let duration: TimeInterval = 0.25

    /// Set the first time a hold finds no menu button to fire: every tile then falls back to the
    /// system `Menu(primaryAction:)`, slow but certain, for the rest of the run.
    @Published private(set) var isUnavailable = false

    func markUnavailable() {
        if !isUnavailable { isUnavailable = true }
    }
}

/// The clear UIKit layer over a fast-hold tile: tap runs the tile's action, a short hold (or a
/// secondary click, for a pointer) opens the anchor menu underneath.
///
/// RIGHT CLICK (2026-09-29, Abu: "Right click doesnt work on grids on mac"). On a Mac running the app as
/// Designed for iPad, and on an iPad trackpad, a secondary click does not arrive as a touch at all (the
/// app does not opt into indirect input events), so the secondary-button tap below never fired. UIKit
/// sends a right click to a context-menu interaction instead, and the layer covers the anchor, so the
/// click found none. On the pad idiom (which a Mac is, here) the layer now carries one. It stands aside
/// for a finger: the interaction's own hold comes after the fast hold has opened the menu, and a second
/// open there dismissed it (and could flip every tile to the slow fallback), so it answers only while
/// the hold recognizer holds no touch and has not just opened the menu.
private struct GridTileHoldLayer: UIViewRepresentable {
    let isEnabled: Bool
    @Binding var isPressed: Bool
    let onTap: () -> Void
    var tapOpensMenu = false
    var onDoubleTap: (() -> Void)? = nil
    var onHold: (() -> Void)? = nil
    var menuRequest = 0
    var onUnavailable: () -> Void = { GridTileMenuHold.shared.markUnavailable() }

    func makeUIView(context: Context) -> HoldView {
        let view = HoldView()
        view.backgroundColor = .clear
        view.install()
        return view
    }

    func updateUIView(_ view: HoldView, context: Context) {
        view.onUnavailable = onUnavailable
        view.tapOpensMenu = tapOpensMenu
        view.onDoubleTap = onDoubleTap
        view.onHold = onHold
        view.doubleTapRecognizer?.isEnabled = onDoubleTap != nil
        view.onTap = onTap
        if view.menuRequest != menuRequest {
            view.menuRequest = menuRequest
            DispatchQueue.main.async { [weak view] in view?.openMenu() }
        }
        view.isUserInteractionEnabled = isEnabled
        view.onPressChange = { pressed in
            if isPressed != pressed { isPressed = pressed }
        }
    }

    final class HoldView: UIView, UIContextMenuInteractionDelegate, UIGestureRecognizerDelegate {
        var onTap: () -> Void = {}
        var tapOpensMenu = false
        var onDoubleTap: (() -> Void)?
        var onHold: (() -> Void)?
        var menuRequest = 0
        var onUnavailable: () -> Void = {}
        weak var doubleTapRecognizer: UITapGestureRecognizer?
        var onPressChange: (Bool) -> Void = { _ in }
        private weak var holdRecognizer: UILongPressGestureRecognizer?
        /// When the menu last opened here, by any route. Two routes answering one press (the fast hold,
        /// then the interaction's own hold) opened it twice, and the second open dismissed it.
        private var openedAt: Date = .distantPast
        private var openedJustNow: Bool { Date().timeIntervalSince(openedAt) < 1.5 }

        func install() {
            let hold = UILongPressGestureRecognizer(target: self, action: #selector(held(_:)))
            hold.minimumPressDuration = GridTileMenuHold.duration
            hold.delegate = self
            addGestureRecognizer(hold)
            holdRecognizer = hold

            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
            doubleTap.numberOfTapsRequired = 2
            doubleTap.require(toFail: hold)
            addGestureRecognizer(doubleTap)
            doubleTapRecognizer = doubleTap

            // The single tap waits for the double tap only on controls offering that shortcut.
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
            tap.require(toFail: hold)
            tap.require(toFail: doubleTap)
            addGestureRecognizer(tap)

            // Never after a hold: on the iPadOS 26.5 simulator this recognizer also took a finger held
            // about a second, and its second open at the lift closed the menu the hold had opened (0 of
            // 10 long holds kept their menu; measured 2026-09-29). A real right click is quick, so the
            // hold has failed by its lift.
            let secondary = UITapGestureRecognizer(target: self, action: #selector(secondaryClicked))
            secondary.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)]
            secondary.buttonMaskRequired = .secondary
            secondary.require(toFail: hold)
            addGestureRecognizer(secondary)

            if UIDevice.current.userInterfaceIdiom == .pad {
                addInteraction(UIContextMenuInteraction(delegate: self))
            }
        }

        // SwiftUI installs a row's context menu on its UIKit cell, even when the modifier is on
        // just the text. That recognizer must wait for a control's sheet shortcut. Panning stays
        // independent so scrolling still cancels a hold as soon as the finger moves.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            guard onHold != nil, gestureRecognizer === holdRecognizer,
                  let owner = otherGestureRecognizer.view, owner !== self,
                  isDescendant(of: owner), !(otherGestureRecognizer is UIPanGestureRecognizer) else { return false }
            return otherGestureRecognizer is UILongPressGestureRecognizer
                || owner.interactions.contains { $0 is UIContextMenuInteraction }
        }

        /// A right click: the anchor's own menu at the pointer when its button exposes one, else the
        /// anchor opened the way a hold opens it.
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                    configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            guard isUserInteractionEnabled, !openedJustNow else { return nil }
            if let hold = holdRecognizer,
               hold.numberOfTouches > 0 || hold.state == .began || hold.state == .changed {
                return nil
            }
            if let menu = (anchorButton() as? UIButton)?.menu {
                openedAt = Date()
                Settings.shared.hapticFeedback()
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in menu }
            }
            DispatchQueue.main.async { [weak self] in self?.openMenu() }
            return nil
        }

        @objc private func tapped() {
            if tapOpensMenu { openMenu() } else { onTap() }
        }

        @objc private func doubleTapped() { onDoubleTap?() }

        @objc private func secondaryClicked() {
            if !openedJustNow { openMenu() }
        }

        @objc private func held(_ recognizer: UILongPressGestureRecognizer) {
            guard recognizer.state == .began else { return }
            onPressChange(false)
            if let onHold {
                // Suppress a later pointer context-menu callback for the same physical hold.
                openedAt = Date()
                onHold()
            } else {
                openMenu()
            }
        }

        func openMenu() {
            openedAt = Date()
            onPressChange(false)
            guard #available(iOS 17.4, *), let button = anchorButton() else {
                onUnavailable()
                return
            }
            // The system's hold buzzes as its menu opens; a programmatic open is silent without this.
            Settings.shared.hapticFeedback()
            button.performPrimaryAction()
        }

        /// The anchor `Menu`'s button: the menu-as-primary-action control sharing this tile's frame.
        /// Searched from the window down on each hold (a few hundred views, once per press) rather
        /// than cached, because a lazy grid recycles both this view and the button.
        private func anchorButton() -> UIControl? {
            guard let window else { return nil }
            let mine = convert(bounds, to: nil)
            var best: (control: UIControl, distance: CGFloat)?
            func walk(_ view: UIView) {
                if let control = view as? UIControl, control.showsMenuAsPrimaryAction,
                   control.contextMenuInteraction != nil {
                    let theirs = control.convert(control.bounds, to: nil)
                    let centerDistance = abs(theirs.midX - mine.midX) + abs(theirs.midY - mine.midY)
                    let sizeDistance = abs(theirs.width - mine.width) + abs(theirs.height - mine.height)
                    let distance = centerDistance + sizeDistance
                    // Toolbars inset the native menu button (e.g. 48×36 around a 44×44 label).
                    // Match its center while allowing those insets, without accepting a neighboring
                    // control. Grid tiles retain their original exact-frame match.
                    let matches = tapOpensMenu
                        ? centerDistance < 4 && sizeDistance < 40
                        : distance < 4
                    if matches, distance < (best?.distance ?? .greatestFiniteMagnitude) {
                        best = (control, distance)
                    }
                }
                for child in view.subviews where !child.isHidden { walk(child) }
            }
            walk(window)
            return best?.control
        }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            onPressChange(true)
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event)
            onPressChange(false)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesCancelled(touches, with: event)
            onPressChange(false)
        }
    }
}

/// A section header's title with its controls (the Today pill, a count, a fold button) trailing it on
/// one line when both fit, and under it when they don't. Squeezed onto one line in an iPad sidebar the
/// title wrapped mid-word ("YOUR SUM- / MARY") beside a pill reading "To- / da / y" (2026-09-29).
/// Between the two, a title a little too long for the line shrinks up to a fifth first
/// (`HeaderLineLayout`): "NEED A HAND?" missed a sidebar's line by a few points and would otherwise
/// have left its count and chevron alone on a second line. Before iOS 16 (no `ViewThatFits`) it is the
/// one line it always was.
struct AdaptiveSectionHeader<Title: View, Controls: View>: View {
    var forceStacked = false
    @ViewBuilder let title: () -> Title
    @ViewBuilder let controls: () -> Controls

    private var stacked: some View {
        VStack(alignment: .leading, spacing: 8) {
            title()
            HStack(spacing: 8) { controls() }
        }
    }

    var body: some View {
        if forceStacked {
            stacked
        } else if #available(iOS 16.0, *) {
            ViewThatFits(in: .horizontal) {
                HeaderLineLayout {
                    title()
                        .lineLimit(1)
                        .minimumScaleFactor(HeaderLineLayout.minimumScale)
                    HStack(spacing: 8) { controls() }
                        .fixedSize()
                }
                stacked
            }
        } else {
            LegacyHeaderLine(title: title, controls: controls)
        }
    }
}

/// `AdaptiveSectionHeader` before iOS 16: the one line it always was. Its own view, not an `HStack`
/// written in the `else` above: with Al-Islam's floor at iOS 16 (2026-10-09), a several-child builder
/// inside a dead `#available` branch made the compiler warn twice (no `buildLimitedAvailability`, and a
/// `TupleContent` conformance it can only promise from iOS 26). Kept rather than deleted because
/// Al-Quran and Al-Adhan still ship this file on iOS 15.
private struct LegacyHeaderLine<Title: View, Controls: View>: View {
    let title: () -> Title
    let controls: () -> Controls

    var body: some View {
        HStack(spacing: 8) {
            title()
            Spacer()
            controls()
        }
    }
}

/// One header line: the title (subview 0) at the leading edge, the controls (subview 1) at the
/// trailing edge, both centred vertically. Its IDEAL width is the tightest line it can make, the title
/// at `minimumScale`, so `ViewThatFits` takes it whenever the shrunk title fits; placed, the title gets
/// all the room the controls leave, and scales only as far as it must.
@available(iOS 16.0, *)
struct HeaderLineLayout: Layout {
    static let minimumScale: CGFloat = 0.8
    var spacing: CGFloat = 8

    /// The title's ideal width times this is the least room it can take on the line. A little above
    /// `minimumScale`: an icon beside the words does not shrink with them.
    private static let fitFactor: CGFloat = 0.85

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let title = subviews[0].sizeThatFits(.unspecified)
        let controls = subviews[1].sizeThatFits(.unspecified)
        let width = proposal.width ?? (title.width * Self.fitFactor + spacing + controls.width)
        let titleWidth = min(title.width, max(width - spacing - controls.width, 0))
        let titleHeight = subviews[0].sizeThatFits(ProposedViewSize(width: titleWidth, height: nil)).height
        return CGSize(width: width, height: max(titleHeight, controls.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let title = subviews[0].sizeThatFits(.unspecified)
        let controls = subviews[1].sizeThatFits(.unspecified)
        let titleWidth = min(title.width, max(bounds.width - spacing - controls.width, 0))
        subviews[0].place(at: CGPoint(x: bounds.minX, y: bounds.midY), anchor: .leading,
                          proposal: ProposedViewSize(width: titleWidth, height: nil))
        subviews[1].place(at: CGPoint(x: bounds.maxX, y: bounds.midY), anchor: .trailing,
                          proposal: ProposedViewSize(width: controls.width, height: controls.height))
    }
}
#endif

// MARK: - Summary tile grid

/// The YOUR SUMMARY tiles' grid (the Quran and Hadith tabs), and every other small grid that is a List
/// row's content. Not lazy: inside a List row a `LazyVGrid` answered 246 pt and then 242 pt for the
/// same width on consecutive self-sizing passes, and iOS 26's collection view traps on a row that
/// never settles ("stuck in a recursive layout loop"). It took real Last Listened tiles and juz sort,
/// whose section index narrows every row, to land there (six crashes on 2026-10-07, reproduced
/// 2026-10-09); the iPad sidebar's narrow rows hit it too. A grid in a List row is built whole anyway,
/// so the laziness bought nothing. Here, with no `#if`, because the Adhan and Islam grids use it too
/// and Al-Adhan compiles none of the Quran folder.
///
/// The grid rows one List row holds where a grid is long (bookmarks, the 99 Names, the 604 pages):
/// `tileGridChunk(columns:)` tiles per List row, the rest in further rows, so the List keeps
/// virtualizing. ONE row, down from the 24 tiles of 2026-10-09: scrolling the pages sort in grid
/// mode spent 70% of its main-thread time re-laying out the visible chunk cells, and a cell of 24
/// ayah tiles - each with glass, a hold layer and a menu - is what every scroll frame re-laid out
/// (Abu, 2026-10-22: "604 items and it gets really laggy"). Measured over the same six swipes on
/// the simulator: 4349 ms of main thread with 24 tiles a row, 3644 with three rows a List row,
/// 3424 with one, against 3078 for the plain list; the 183 ms and 110 ms hitches at the old chunk
/// boundaries are gone. The chunk follows the column count so a row is never short; a rotation that
/// changes the columns re-identifies the rows, which the grid rebuilds anyway (checked live).
let tileGridRowsPerChunk = 1

/// Tiles per List row of a chunked grid with `columns` columns (see `tileGridRowsPerChunk`).
func tileGridChunk(columns: Int) -> Int { max(1, columns) * tileGridRowsPerChunk }

/// A List row's default leading / trailing content inset on iOS 26 (measured: the tiles of a
/// default-inset row start 16 pt inside the section card, in both list styles). Restated by the rows
/// that must set `listRowInsets` themselves, since the modifier takes all four edges at once.
let listRowDefaultInset: CGFloat = 16

/// A List row's default top / bottom content inset on iOS 26 (30 pt measured between two default
/// rows' content on the iPhone, 15 a side). See `listRowDefaultInset`.
let listRowDefaultVerticalInset: CGFloat = 15

/// The air the Quran grids keep above their first row and below their last, in place of the vertical
/// insets their rows give up: the default inset plus the 4 pt the grid always had there.
let tileGridOuterInset: CGFloat = listRowDefaultVerticalInset + 4

extension View {
    /// One List row of a grid chunked by `chunk` tiles (`tileGridChunk(columns:)`), starting at tile
    /// `start` of `count`: no separator, and the grid's own row gap (`spacing`) drawn INSIDE the row
    /// where two chunks meet, with the row's vertical insets at zero so the List adds nothing of its
    /// own there. `horizontalInset` is the tiles' distance from the cell's edges (the List's default,
    /// unless the grid used to pad out of it) and `outerInset` the air above the first row and below
    /// the last, in place of the vertical insets the rows give up.
    ///
    /// It used to take the List's inter-row spacing back with -10 pt of padding on each side of the
    /// seam (30 pt measured on the iPhone, 10 wanted). That made the tiles overflow their cells by
    /// 10 pt, and the seam was only right while the List really did add 30: on the Mac it added
    /// nothing, the two rows' glass tiles overlapped by 20 pt, and Liquid Glass drew the overlap as a
    /// bright band across the tiles above every seam (Abu, 2026-10-22, tiles 23/24). A tile now never
    /// leaves its cell, so a List that spaces its rows differently can at most widen the seam, never
    /// collide two glass shapes. The horizontal insets are the List's default (`listRowDefaultInset`)
    /// restated, because `listRowInsets` takes all four edges at once.
    @ViewBuilder
    func tileGridChunkRow(start: Int, count: Int, chunk: Int, spacing: CGFloat = 10,
                          horizontalInset: CGFloat = listRowDefaultInset,
                          outerInset: CGFloat = tileGridOuterInset) -> some View {
        let first = start == 0
        let last = start + chunk >= count
        let padded = self
            .padding(.top, first ? outerInset : 0)
            .padding(.bottom, last ? outerInset : spacing)
        #if os(iOS)
        padded
            .listRowInsets(EdgeInsets(top: 0, leading: horizontalInset, bottom: 0, trailing: horizontalInset))
            .listRowSeparator(.hidden)
        #else
        padded
        #endif
    }
}

/// `spacing` is the replaced grid's row spacing, and its column spacing too unless `columnSpacing`
/// says otherwise; `alignment: .top` stands for its `GridItem(alignment: .top)`, and anything else
/// centres a cell in its row. `adaptiveMinimum` stands for `GridItem(.adaptive(minimum:))`: as many
/// columns as fit at that width, the spare width shared out equally.
struct SummaryTileGrid<Content: View>: View {
    let columns: Int
    let adaptiveMinimum: CGFloat?
    let spacing: CGFloat
    let columnSpacing: CGFloat
    let alignment: VerticalAlignment
    let content: Content

    init(columns: Int, spacing: CGFloat = 10, columnSpacing: CGFloat? = nil, alignment: VerticalAlignment = .center,
         @ViewBuilder content: () -> Content) {
        self.columns = columns
        self.adaptiveMinimum = nil
        self.spacing = spacing
        self.columnSpacing = columnSpacing ?? spacing
        self.alignment = alignment
        self.content = content()
    }

    init(adaptiveMinimum: CGFloat, spacing: CGFloat = 10, columnSpacing: CGFloat? = nil,
         alignment: VerticalAlignment = .center, @ViewBuilder content: () -> Content) {
        self.columns = 1
        self.adaptiveMinimum = adaptiveMinimum
        self.spacing = spacing
        self.columnSpacing = columnSpacing ?? spacing
        self.alignment = alignment
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, watchOS 9.0, *) {
            EqualColumnsLayout(columns: columns, adaptiveMinimum: adaptiveMinimum, spacing: spacing,
                               columnSpacing: columnSpacing, alignment: alignment) { content }
        } else {
            let cellAlignment: Alignment? = alignment == .top ? .top : nil
            let items = adaptiveMinimum.map {
                [GridItem(.adaptive(minimum: $0), spacing: columnSpacing, alignment: cellAlignment)]
            } ?? Array(repeating: GridItem(.flexible(), spacing: columnSpacing, alignment: cellAlignment), count: columns)
            LazyVGrid(columns: items, alignment: .leading, spacing: spacing) { content }
        }
    }
}

/// Equal columns (a fixed count, or as many as fit at `adaptiveMinimum`), rows as tall as their
/// tallest cell: what the `LazyVGrid` drew, as a pure function of the proposed width.
@available(iOS 16.0, watchOS 9.0, *)
struct EqualColumnsLayout: Layout {
    let columns: Int
    var adaptiveMinimum: CGFloat? = nil
    let spacing: CGFloat
    var columnSpacing: CGFloat? = nil
    /// `.top` pins each cell to its row's top; anything else centres it vertically.
    var alignment: VerticalAlignment = .center

    private var gap: CGFloat { columnSpacing ?? spacing }

    private func columnCount(_ width: CGFloat?) -> Int {
        guard let minimum = adaptiveMinimum else { return max(columns, 1) }
        guard let width, width.isFinite, minimum + gap > 0 else { return 1 }
        return max(1, Int(((width + gap) / (minimum + gap)).rounded(.down)))
    }

    private func columnWidth(_ width: CGFloat?, count: Int, _ subviews: Subviews) -> CGFloat {
        if let width, width.isFinite {
            return max(0, (width - gap * CGFloat(count - 1)) / CGFloat(count))
        }
        return subviews.map { $0.sizeThatFits(.unspecified).width }.max() ?? 0
    }

    /// The measured row heights per column width. `sizeThatFits` and then `placeSubviews` both need
    /// them, and each used to re-measure every tile (shaping its Arabic text through CoreText) on
    /// its own. The cache spares the placement pass; a List's self-sizing measurement still arrives
    /// with a fresh cache, so that pass measures once per cell. SwiftUI empties the cache
    /// (`updateCache`) whenever the subviews change, a tile changing size included.
    struct Cache {
        var heightsByWidth: [CGFloat: [CGFloat]] = [:]
        var perRow = 0
        var count = 0
    }

    func makeCache(subviews: Subviews) -> Cache { Cache() }

    func updateCache(_ cache: inout Cache, subviews: Subviews) { cache = Cache() }

    private func rowHeights(_ width: CGFloat, perRow: Int, _ subviews: Subviews, cache: inout Cache) -> [CGFloat] {
        let key = (width * 2).rounded() / 2
        if cache.perRow == perRow, cache.count == subviews.count, let heights = cache.heightsByWidth[key] {
            return heights
        }
        let heights: [CGFloat] = stride(from: 0, to: subviews.count, by: perRow).map { start in
            subviews[start..<min(start + perRow, subviews.count)]
                .map { $0.sizeThatFits(ProposedViewSize(width: width, height: nil)).height }
                .max() ?? 0
        }
        if cache.perRow != perRow || cache.count != subviews.count {
            cache = Cache(perRow: perRow, count: subviews.count)
        }
        if cache.heightsByWidth.count >= 8 { cache.heightsByWidth.removeAll() }
        cache.heightsByWidth[key] = heights
        return heights
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let count = columnCount(proposal.width)
        let width = columnWidth(proposal.width, count: count, subviews)
        let heights = rowHeights(width, perRow: count, subviews, cache: &cache)
        let total = heights.reduce(0, +) + spacing * CGFloat(max(heights.count - 1, 0))
        return CGSize(width: width * CGFloat(count) + gap * CGFloat(count - 1), height: total)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        let count = columnCount(bounds.width)
        let width = columnWidth(bounds.width, count: count, subviews)
        let heights = rowHeights(width, perRow: count, subviews, cache: &cache)
        let top = alignment == .top
        var y = bounds.minY
        for (row, height) in heights.enumerated() {
            for column in 0..<count {
                let index = row * count + column
                guard index < subviews.count else { break }
                // Centred across the column, as `LazyVGrid` centres a cell narrower than its column.
                let x = bounds.minX + CGFloat(column) * (width + gap) + width / 2
                subviews[index].place(at: CGPoint(x: x, y: top ? y : y + height / 2),
                                      anchor: top ? .top : .center,
                                      proposal: ProposedViewSize(width: width, height: height))
            }
            y += height + spacing
        }
    }
}

extension View {
    #if os(iOS)
    #if HAS_QURAN
    /// See `ReciterPickerSheet`.
    func reciterPickerSheet(isPresented: Binding<Bool>) -> some View {
        modifier(ReciterPickerSheet(isPresented: isPresented))
    }
    #endif

    /// Wraps this view as a `GridTileMenu`'s label. See that type for the whole story.
    func gridTileMenu<MenuContent: View>(
        primaryAction: @escaping () -> Void,
        @ViewBuilder menu: @escaping () -> MenuContent
    ) -> some View {
        GridTileMenu(primaryAction: primaryAction, menu: menu) { self }
    }
    #endif

    /// The corner favorite star every grid tile shares: a small overlay (never part of the tile's own
    /// stack, so it costs no layout) tucked into the top-trailing corner with a hair of breathing room.
    /// The visible glyph is small; the tap target is padded well past it.
    func gridFavoriteStar(
        isFavorite: Bool,
        accent: Color,
        accessibilityName: String,
        onToggle: @escaping () -> Void
    ) -> some View {
        overlay(alignment: .topTrailing) {
            GridFavoriteStar(isFavorite: isFavorite, accent: accent, accessibilityName: accessibilityName,
                             onToggle: onToggle)
        }
    }

    /// The ring a grid tile wears while its screen fills the iPad/Mac detail column. A grid is ONE
    /// `List` row, so `List(selection:)` has no row of its own to highlight and the tile has to draw
    /// the selection itself. The Islam sidebar's look, shared by every grid beside a detail column
    /// (Quran, Hadith, Islam, the Settings cards) so it cannot drift again: the chapter tiles marked
    /// the open chapter with a lighter accent tint, which "just highlights the back as if its
    /// favorited", and the Quran tiles marked nothing at all (Abu, 2026-09-25).
    ///
    /// Apply it to the tile's LABEL, inside `GridTileMenu`, so it dims with the press like the rest of
    /// the tile. `cornerRadius` is the tile's own shape, `GlassCorner.rectangle` for a glass tile: at
    /// 12 against the glass's 24 the ring cut visible corners inside the tile it was meant to trace
    /// (Abu, 2026-09-19).
    func gridSelectionRing(_ isSelected: Bool, cornerRadius: CGFloat = GlassCorner.rectangle) -> some View {
        modifier(GridSelectionRing(isSelected: isSelected, cornerRadius: cornerRadius))
    }

    /// The highlight a LIST ROW wears while its screen fills the iPad/Mac detail column - the row
    /// counterpart of `gridSelectionRing`.
    ///
    /// Rows beside a detail column are plain `Button`s (a Button, not a NavigationLink, so re-tapping
    /// the open row still answers by popping its section back to the root), and `.buttonStyle(.plain)`
    /// draws no selection of its own. Where the sidebar is a `List(selection:)` the tag handles it;
    /// where it is not - the Quran and Hadith tabs drive their columns off a route instead - nothing
    /// was drawn at all, so a tap opened the detail with no sign of which row it came from
    /// (Abu, 2026-10-05: "sometimes it doesnt highlight at all").
    ///
    /// A filled bed rather than the tiles' ring: that is how a system sidebar marks a selected row,
    /// and a 2 pt ring around a full-width row reads as a box, not a selection.
    ///
    /// The bed fills the selected row's whole cell in UIKit's own selection shape: the pill a sidebar
    /// cell is drawn as (its corner radius read off the cell, 26 pt on iPadOS 26), a plain rectangle in
    /// a plain list. Until 2026-10-09 it was a 10 pt shape 8 pt past the label, inside the system's grey
    /// pill: a box within a box (Abu: every highlight takes up the full row). As the row's own cell
    /// background it still survives the three things that wiped the system's selection bed: a
    /// plain-styled Button, the reading theme's row color, and the plain list style. Apply it to the
    /// row itself, not to a Button's label: from inside a label it cannot reach the cell.
    ///
    /// Only the selected row paints its cell. A sidebar draws its other cells transparent over the
    /// section's card, with their own hover and press states; painting them all (as `rowWash` does)
    /// lifted every row off the card. `isActive` false leaves the row untouched, for the screens that
    /// share these rows with the iPhone's stack.
    func rowSelectionHighlight(_ isSelected: Bool, isActive: Bool = true) -> some View {
        modifier(RowSelectionHighlight(isSelected: isSelected, isActive: isActive))
    }
}

/// See `rowSelectionHighlight`.
private struct RowSelectionHighlight: ViewModifier {
    @Environment(\.appearance) private var appearance
    #if os(iOS)
    @StateObject private var cellShape = SidebarCellShape()
    #endif

    let isSelected: Bool
    let isActive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        #if os(iOS)
        if isActive {
            content
                .background(SidebarCellProbe(shape: cellShape, isSelected: isSelected))
                // An unselected row keeps the system's cell, or the theme's row color the List-wide
                // `themedListRowBackground()` would give it (a bare nil here would wipe that).
                .listRowBackground(isSelected
                    ? AnyView(SidebarSelectionPill(shape: cellShape, ground: appearance.themeRowBackground,
                                                   fill: appearance.accent.opacity(0.15)))
                    : appearance.themeRowBackground.map { AnyView($0) })
        } else {
            content
        }
        #else
        content
        #endif
    }
}

#if os(iOS)
/// The corner radius UIKit gives a cell's selected background, read off the cell by `SidebarCellProbe`.
@MainActor
private final class SidebarCellShape: ObservableObject {
    @Published var cornerRadius: CGFloat = 0
}

/// The selected row's cell: the accent in the shape UIKit would draw its own selection, over the row's
/// ground (clear in a sidebar, where the section's card shows through).
private struct SidebarSelectionPill: View {
    @ObservedObject var shape: SidebarCellShape
    let ground: Color?
    let fill: Color

    var body: some View {
        ZStack {
            ground ?? Color.clear
            RoundedRectangle(cornerRadius: shape.cornerRadius, style: .continuous)
                .fill(fill)
        }
    }
}

/// Reaches the List cell the row sits in, for the two things SwiftUI does not expose: the corner radius
/// UIKit draws a selected cell with, and the cell's focus ring.
///
/// UIKit rings a focused cell whose background it does not draw itself, and the selected row's
/// background is the pill. In these sidebars the selection follows keyboard focus, so the pill already
/// shows where focus is and the ring only doubled it as a hard square around the pill (measured on the
/// iPadOS 26 simulator, which has a hardware keyboard, as every Mac does). `.focusEffectDisabled()` does
/// not reach the cell's ring; the cell's own `focusEffect` does.
private struct SidebarCellProbe: UIViewRepresentable {
    let shape: SidebarCellShape
    let isSelected: Bool

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ view: ProbeView, context: Context) {
        view.shape = shape
        view.isSelected = isSelected
        view.apply()
    }

    final class ProbeView: UIView {
        weak var shape: SidebarCellShape?
        var isSelected = false

        override func didMoveToWindow() {
            super.didMoveToWindow()
            apply()
        }

        func apply() {
            guard window != nil else { return }
            var ancestor = superview
            while let view = ancestor, !(view is UICollectionViewListCell) {
                ancestor = view.superview
            }
            guard let cell = ancestor as? UICollectionViewListCell else { return }
            if isSelected { cell.focusEffect = nil }
            // `defaultBackgroundConfiguration()` is iOS 16; on 15 the shape keeps its default radius.
            guard #available(iOS 16.0, *) else { return }
            var state = cell.configurationState
            state.isSelected = true
            let radius = cell.defaultBackgroundConfiguration().updated(for: state).cornerRadius
            if let shape, shape.cornerRadius != radius {
                // Not inside SwiftUI's update of the row.
                DispatchQueue.main.async { shape.cornerRadius = radius }
            }
        }
    }
}
#endif

/// The corner star of `gridFavoriteStar`. A view of its own so it can watch Simple Mode itself: in
/// Simple Mode a tile that is not a favorite draws no star (`SimpleTrim.outlineStar`; every tile's
/// press-and-hold menu still offers Favorite), and an Equatable tile around it may not redraw when the
/// switch flips, where this view does (`hiddenInSimple` owns the observation).
private struct GridFavoriteStar: View {
    let isFavorite: Bool
    let accent: Color
    let accessibilityName: String
    let onToggle: () -> Void

    var body: some View {
        Image(systemName: isFavorite ? "star.fill" : "star")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(isFavorite ? accent : .secondary)
            // The tap target is a 30pt square CENTERED ON THE GLYPH, sized before the corner
            // positioning, not after. The old shape came after the 10/11pt paddings and then
            // inflated by another 10 (`inset(by: -10)`), hit-testing a ~40pt+ zone anchored at the
            // corner: on a small grid tile, tapping anywhere on the right side toggled the star
            // instead of opening the tile.
            .frame(width: 30, height: 30)
            .contentShape(Rectangle())
            .onTapGesture {
                Settings.shared.hapticFeedback()
                withAnimation(.easeInOut) {
                    onToggle()
                }
            }
            .padding(.top, 1)
            .padding(.trailing, 2)
            .accessibilityLabel(isFavorite ? String(localized: "Unfavorite \(accessibilityName)") : String(localized: "Favorite \(accessibilityName)"))
            // A tap-gesture image: VoiceOver announced it as an image, not something to press.
            .accessibilityRemoveTraits(.isImage)
            .accessibilityAddTraits(.isButton)
            .hiddenInSimple(.outlineStar, unless: isFavorite)
    }
}

/// See `gridSelectionRing`. The accent comes from the appearance snapshot, the one every tile's own
/// tint is drawn from.
private struct GridSelectionRing: ViewModifier {
    @Environment(\.appearance) private var appearance

    let isSelected: Bool
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(appearance.accent, lineWidth: 2)
                // Faded out rather than stroked at 0: a zero-width stroke is no promise of nothing drawn.
                .opacity(isSelected ? 1 : 0)
                // Decoration only: it must never sit between a finger and the tile, its star or its menu.
                .allowsHitTesting(false)
        )
    }
}

#if os(iOS)
/// The shared five-way Arabic face picker for the non-Quran Arabic screens (Hadith, Adhkar, Duas,
/// 99 Names, Arabic Alphabet). One control, one setting - every screen that shows standard Arabic
/// text offers the same choice: Uthmani, IndoPak, Hijazi, Kufi, or the system font.
struct IslamArabicFontPicker: View {
    private let settings = Settings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    var body: some View {
        Picker("Arabic Font", selection: Binding(
            get: { settings.islamArabicFace },
            set: { newValue in
                guard newValue != settings.islamArabicFace else { return }
                settings.hapticFeedback()
                settings.islamArabicFace = newValue
            }
        )) {
            Text("Uthmani").tag(Settings.IslamArabicFace.uthmani)
            Text("IndoPak").tag(Settings.IslamArabicFace.indopak)
            Text("Hijazi").tag(Settings.IslamArabicFace.hijazi)
            Text("Kufi").tag(Settings.IslamArabicFace.kufi)
            Text("Basic").tag(Settings.IslamArabicFace.basic)
        }
        .pickerStyle(.segmented)
    }
}
#endif

extension Color {
    /// Secondary text on the app's glass tiles and cards (2026-09-27). The system `.secondary` renders
    /// at 3.1:1 there (measured on the Adhan and Quran tiles, #878789 on #3B3B3D), under the 4.5:1
    /// small text needs; a plain primary at 65% keeps the step down from the headline and reads at 5:1
    /// or better in both appearances.
    static let secondaryOnGlass = Color.primary.opacity(0.65)
}

// MARK: - Section header accessories (count pill / collapse / shuffle)

/// The small numeric badge the Quran tab's section headers wear - caption-semibold, monospaced digits,
/// on glass. One view so every counted section in the app shows the identical pill. Counts are details
/// (Simple Mode spec rule 8), so the pill hides itself in Simple Mode and every caller is covered; the
/// rule's exceptions do not use this view.
struct CountPill: View {
    @Environment(\.appearance) private var appearance

    let count: Int
    /// "5+" style - set when the count is a floor from an early-exited search, not an exact total.
    var overflow: Bool = false

    var body: some View {
        Text("\(count)\(overflow ? "+" : "")")
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(appearance.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .conditionalGlassEffect()
            .hiddenInSimple(.sectionCounts)
    }
}

/// A full section header in the Quran tab's visual language: optional leading icon, the title, then on
/// the right an optional shuffle button, the count pill, and an optional collapse chevron. Pass
/// `isExpanded` to make the section collapsible (the same chevron.circle control Favorite Surahs and
/// Bookmarked Ayahs use) and `onShuffle` for sections where jumping to a random item makes sense.
extension String {
    /// Interface text set CENTERED (a tile's title or read-out), as a right-to-left line in a right-to-left
    /// interface. SwiftUI takes a line's direction from its first strong letter, not from the layout
    /// direction, so an Arabic caption that opens on a Latin name ("iCloud ...") laid out left to right.
    /// A RIGHT-TO-LEFT MARK in front settles it; unchanged left to right. Interface text only: English
    /// content (a book title, a translation) keeps its own direction.
    var interfaceParagraph: String {
        AppLanguage.isRightToLeft && !isEmpty ? "\u{200F}" + self : self
    }
}

/// A small accent-gradient icon chip - the iOS Settings app's row-icon grammar, tinted the app's
/// way. Shared by the Settings hub, settings search results, and the Islam tab's resource rows.
struct AccentIconChip: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.locale) private var locale

    /// Symbols that draw LATIN letters on purpose (the English Text pages, an English reading choice).
    /// SwiftUI draws a localized symbol in the interface's script, so under Arabic "textformat" drew
    /// "أ" and an English Text row read as a second Arabic Text row. An English locale keeps their Latin
    /// face in both languages; Arabic rows name their own variant ("textformat.ar").
    static let latinScriptSymbols: Set<String> = ["textformat", "textformat.abc"]

    let systemImage: String
    var tint: Color? = nil
    /// A SECOND colour, so the chip can carry two: it then runs from `tint` at the top-leading corner
    /// to this at the bottom-trailing, in place of the one-colour light-to-dark ramp. Islam Settings is
    /// the reason it exists (Abu, 2026-09-19): that section covers the whole app rather than one tab, so
    /// its row wears BOTH of Al-Islam's colours, yellow into green, where Prayer/Quran/Hadith each wear
    /// their own single one.
    var secondaryTint: Color? = nil
    var size: CGFloat = 29

    var body: some View {
        let tint = tint ?? appearance.accent
        // One colour ramps light-to-dark as it always has; two run corner to corner at full strength,
        // since dimming the second half would read as a smudge rather than as a second colour.
        let colors: [Color] = secondaryTint.map { [tint, $0] } ?? [tint.opacity(0.95), tint.opacity(0.65)]
        Image(systemName: systemImage)
            .environment(\.locale, Self.latinScriptSymbols.contains(systemImage) ? Locale(identifier: "en") : locale)
            // Scales with the chip (~footnote at the default 29pt), so mini chips stay balanced.
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            // Decoration beside a title in every one of its ~60 uses: VoiceOver read the symbol's own
            // name ("Hands With Sparkles, Filled") before the title it illustrates.
            .accessibilityHidden(true)
    }
}

/// Whether the Quran tab is the one on screen, as `MainTabView` sees it (`QuranView.isActiveTab`).
/// Read by the page reader's `MushafRootTabBarHidden`, which must not hide the SHARED root tab bar
/// while another tab is front - see the note there on the launch warm pass.
///
/// Declared here rather than beside its one reader because `QuranView.swift`, which PUBLISHES it,
/// compiles into the Watch target too, and MushafReader.swift does not.
struct QuranTabActiveKey: EnvironmentKey {
    /// True so a reader hosted outside the tab (a sheet, a preview) behaves as it always has.
    static let defaultValue = true
}

extension EnvironmentValues {
    var isQuranTabActive: Bool {
        get { self[QuranTabActiveKey.self] }
        set { self[QuranTabActiveKey.self] = newValue }
    }
}

/// A section header's title with an accent SF Symbol leading it: the one look for every major
/// section of a tab root (SURAHS, PRAYER TIMES, THE SIX BOOKS, SETTINGS...), with or without a count
/// pill beside it (Abu, 2026-10-11: "for each major section with a header ... put an sf symbol next to
/// it"). `SectionPillHeader` draws its title through this, so the two line up to the point.
struct SectionIconHeader: View {
    @Environment(\.appearance) private var appearance

    let title: String
    /// nil draws the bare title: `SectionPillHeader` without an icon.
    let icon: String?
    /// Accent the title AND its icon; false keeps both the header's gray. The rule (Abu, 2026-10-18,
    /// "make it consistent which ones are and which ones aren't"): a section that is YOURS is accent
    /// (Your Summary, Favorites, Bookmarks, Saved Reflections, notes, Last Read, Khatm Progress, the
    /// Prayer Tracker, Start Here, Need a Hand?); a catalog, a setting or a search result is gray. The
    /// icon follows its title ("it looks weird with colored sf symbols and non colored text").
    var accentTitle = false

    init(_ title: String, icon: String?, accentTitle: Bool = false) {
        self.title = title
        self.icon = icon
        self.accentTitle = accentTitle
    }

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                // Unstyled when the title is: it then takes whatever the header gives its title
                // (`.foreground` resolved to black, not the header's gray).
                Group {
                    if accentTitle {
                        Image(systemName: icon)
                            .foregroundStyle(appearance.accent)
                    } else {
                        Image(systemName: icon)
                    }
                }
                // Decoration beside the title: VoiceOver read the symbol's own name as a heading
                // of its own ("Question Mark In A Filled Circle", "Bookmark") before the title.
                .accessibilityHidden(true)
            }

            // The heading trait said explicitly: a List hands it to the header's FIRST element, which
            // was the icon, so the title itself read as plain text.
            Group {
                if accentTitle {
                    Text(title)
                        .foregroundStyle(appearance.accent)
                } else {
                    Text(title)
                }
            }
            .accessibilityAddTraits(.isHeader)
        }
    }
}

struct SectionPillHeader: View {
    @Environment(\.appearance) private var appearance

    let title: String
    let count: Int
    var icon: String? = nil
    /// Accent the icon + title, for a section that is yours (`SectionIconHeader.accentTitle`'s rule);
    /// false keeps both the standard header gray.
    var accentTitle: Bool = false
    var isExpanded: Binding<Bool>? = nil
    var onShuffle: (() -> Void)? = nil
    /// "5+" style count - set when the count is a floor from an early-exited search.
    var overflow: Bool = false
    /// A magnifier that starts a search held to this section's items (the Quran bookmarks and
    /// favorites). Sits between the count and the shuffle.
    var onSearch: (() -> Void)? = nil
    /// A trash that puts the whole section away (NEED A HAND?), drawn only while the section is
    /// folded: the arrow folds it, the trash removes it (Abu, 2026-10-10: "when a tips tab is
    /// collapsed have a button to trash remove it"). The owner confirms before removing anything.
    var onRemove: (() -> Void)? = nil

    /// The count pill's rendered height (caption line height + 2 x 4pt padding) - the shuffle circle
    /// matches it so the two controls read as one family.
    static var pillHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .caption1).lineHeight + 8
    }

    var body: some View {
        #if os(iOS)
        // The count and buttons drop under the title where the two do not fit on one line: squeezed
        // beside them in an iPad sidebar, "NEED A HAND?" wrapped to two lines (2026-09-29).
        AdaptiveSectionHeader { titleLabel } controls: { controls }
        #else
        HStack(spacing: 8) {
            titleLabel

            Spacer()

            controls
        }
        #endif
    }

    private var titleLabel: some View {
        SectionIconHeader(title, icon: icon, accentTitle: accentTitle)
    }

    @ViewBuilder
    private var controls: some View {
        // The trailing cluster's ONE ordering rule, app-wide: the count pill sits at the far LEFT
        // of the cluster (it is information, not a control), then the buttons: search, shuffle, trash,
        // then the expand chevron. SurahsHeader lays out the same way; a header that hand-rolls its
        // cluster must follow this order too. Simple Mode drops the count, search and shuffle (each
        // hides itself; the trash and the chevron stay).
        CountPill(count: count, overflow: overflow)

        if let onSearch {
            Image(systemName: "magnifyingglass")
                .font(.caption2.weight(.semibold))
                .foregroundColor(appearance.accent)
                .frame(width: Self.pillHeight, height: Self.pillHeight)
                .conditionalGlassEffect(circle: true)
                .onTapGesture {
                    Settings.shared.hapticFeedback()
                    onSearch()
                }
                .accessibilityLabel("Search \(title.lowercased())")
                .accessibilityRemoveTraits(.isImage)
                .accessibilityAddTraits(.isButton)
                .hiddenInSimple(.sectionSearch)
        }

        if let onShuffle {
            // A circle exactly as tall as the count pill (caption line + its 4pt vertical padding),
            // and as wide as it is tall.
            Image(systemName: "shuffle")
                .font(.caption2.weight(.semibold))
                .foregroundColor(appearance.accent)
                .frame(width: Self.pillHeight, height: Self.pillHeight)
                .conditionalGlassEffect(circle: true)
                .onTapGesture {
                    Settings.shared.hapticFeedback()
                    onShuffle()
                }
                .accessibilityLabel("Random \(title.lowercased())")
                // Tap-gesture images: without these VoiceOver said "image" and offered no action.
                .accessibilityRemoveTraits(.isImage)
                .accessibilityAddTraits(.isButton)
                .hiddenInSimple(.sectionShuffles)
        }

        // Only while folded: an open section's cards are still in use, and the arrow is the way to put
        // them out of sight. The shuffle's circle, so the cluster reads as one family.
        if let onRemove, isExpanded?.wrappedValue == false {
            Image(systemName: "trash")
                .font(.caption2.weight(.semibold))
                .foregroundColor(appearance.accent)
                .frame(width: Self.pillHeight, height: Self.pillHeight)
                .conditionalGlassEffect(circle: true)
                .onTapGesture {
                    Settings.shared.hapticFeedback()
                    onRemove()
                }
                .accessibilityLabel("Remove \(title.lowercased())")
                .accessibilityRemoveTraits(.isImage)
                .accessibilityAddTraits(.isButton)
        }

        if let isExpanded {
            Image(systemName: isExpanded.wrappedValue ? "chevron.down.circle" : "chevron.up.circle")
                .foregroundColor(appearance.accent)
                .padding(4)
                .conditionalGlassEffect()
                .onTapGesture {
                    Settings.shared.hapticFeedback()
                    withAnimation { isExpanded.wrappedValue.toggle() }
                }
                .accessibilityLabel(isExpanded.wrappedValue ? String(localized: "Collapse \(title.lowercased())") : String(localized: "Expand \(title.lowercased())"))
                .accessibilityRemoveTraits(.isImage)
                .accessibilityAddTraits(.isButton)
        }
    }
}

// MARK: - Compact/regular layout migrations

// Not iOS-gated: the Quran tab (which owns one of these migrations) compiles for watchOS too, where
// `columns` is simply always false and this never fires. Nothing inside is platform-specific.
/// Runs a sidebar/stack state migration when the window REALLY crosses the compact/regular boundary,
/// and never when iOS crosses it on its own behalf.
///
/// The iPad and Mac tabs (Islam, Quran, Hadith) each swap between a `NavigationSplitView` and a
/// `NavigationStack`, and each carries the open item across the swap so a Split View drag or a Stage
/// Manager resize does not dump the user back on the list. Those migrations are LOSSY by nature - the
/// stack path holds only the top-level section, so anything pushed deeper inside the detail column's
/// own stack (a Pillars & Beliefs article, say) is not in it and does not survive the round trip.
///
/// That was fine while only a real resize could trigger one. It isn't: sending the app to the
/// background makes iOS re-lay the window out COMPACT and then REGULAR again for its app-switcher
/// snapshots. Measured on an iPad Pro 11-inch, half a second after `.background`: compact at +494 ms,
/// regular again at +931 ms. Both flips ran the migration with nobody looking, so simply leaving the
/// app and coming back re-seated the navigation - the article gone, the section back at its root, the
/// scroll position lost. "When I screenshot or disappear and come back sometimes it reorients itself"
/// (Abu, 2026-09-09, iPad/Mac).
///
/// So: never migrate while the scene is `.background`, and remember the layout each migration settled
/// on. A flip observed while the app is away updates nothing, so the state still describes the layout
/// the user left. If the window genuinely DID change shape while the app was away (resized from the
/// app switcher, say), the phase change on the way back finds the mismatch and migrates then, once.
///
/// `.background` rather than "only while `.active`": the snapshot passes all land squarely in
/// `.background` (measured), while `.inactive` is an ordinary state for a foreground app - a system
/// alert over it, a Control Center pull, an unfocused Mac window - and a resize made in any of those
/// is a real one that should still carry.
struct ColumnLayoutMigration: ViewModifier {
    let columns: Bool
    let migrate: (Bool) -> Void

    @Environment(\.scenePhase) private var scenePhase
    /// The layout the state was last reconciled against; nil until the first active observation, which
    /// only records (there is nothing to carry across on the way in).
    @State private var reconciled: Bool?

    func body(content: Content) -> some View {
        content
            .onChange(of: columns) { _ in reconcile() }
            .onChange(of: scenePhase) { _ in reconcile() }
            .onAppear { reconcile() }
    }

    private func reconcile() {
        guard scenePhase != .background else { return }
        guard let previous = reconciled else {
            reconciled = columns
            return
        }
        guard previous != columns else { return }
        reconciled = columns
        migrate(columns)
    }
}

extension View {
    /// See `ColumnLayoutMigration`: `migrate` runs only for a boundary crossing the USER caused.
    func columnLayoutMigration(columns: Bool, migrate: @escaping (Bool) -> Void) -> some View {
        modifier(ColumnLayoutMigration(columns: columns, migrate: migrate))
    }
}
