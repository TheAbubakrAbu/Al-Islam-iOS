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
    /// The Quran face (`Settings.fontArabic`) for the ayat quoted on those pages, and its custom flag.
    var quranArabicFontName: String
    var quranUsesCustomArabicFace: Bool

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
            quranArabicFontName: settings.fontArabic,
            quranUsesCustomArabicFace: settings.quranUsesCustomArabicFace
        )
    }
}

struct AppearanceEnvironmentKey: EnvironmentKey {
    /// A one-time snapshot, for trees no root injects into (previews). Every real root applies
    /// `.appearanceEnvironment()`, which keeps the value live.
    static let defaultValue = AppearanceEnvironment.snapshot(Settings.shared, profile: PerformanceProfile.shared)
}

extension EnvironmentValues {
    var appearance: AppearanceEnvironment {
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

    private var cancellable: AnyCancellable?
    private var refreshScheduled = false

    private init() {
        let settings = Settings.shared
        environment = AppearanceEnvironment.snapshot(settings, profile: PerformanceProfile.shared)
        firstLaunch = settings.firstLaunch
        cancellable = settings.objectWillChange.sink { [weak self] _ in self?.scheduleRefresh() }
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
            .environment(\.appearance, environment)
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

extension View {
    /// See `AppearanceEnvironmentInjector`.
    func appearanceEnvironment() -> some View {
        modifier(AppearanceEnvironmentInjector())
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

    func applyConditionalListStyle(disableNowPlayingInset: Bool = false, topContentMargin: CGFloat = 0) -> some View {
        modifier(ConditionalListStyle(disableNowPlayingInset: disableNowPlayingInset, topContentMargin: topContentMargin))
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
    func selectableArticleList(disableNowPlayingInset: Bool = false, topContentMargin: CGFloat = 0) -> some View {
        modifier(SelectableArticleList(disableNowPlayingInset: disableNowPlayingInset, topContentMargin: topContentMargin))
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

/// The cushion UNDER a floating bottom bar (above the tab bar / home indicator). On iOS 26 the bar
/// floats over content and 8pt reads right. Pre-26 this has swung both ways: 8pt read as dead space
/// when the bars were built on UISearchBar, whose own fat internal padding stacked onto it ("a lot
/// of padding on pre iOS 26"), so it went to 0 - but after the 38pt SwiftUI search field replaced
/// UISearchBar, 0 left the row sitting flush on the opaque tab bar ("no spacing at the bottom looks
/// bad"). With the compact field the same 8pt now reads right on both, so the cushion is uniform.
enum BottomBarCushion {
    static var standard: CGFloat { 8 }
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
        if appearance.defaultView {
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

struct ConditionalListStyle: ViewModifier {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var playback = PlaybackVisibility.shared

    let disableNowPlayingInset: Bool
    var topContentMargin: CGFloat = 0

    private var shouldShowNowPlaying: Bool {
        playback.showsNowPlaying
    }

    func body(content: Content) -> some View {
        Group {
            #if os(iOS)
            styledContent(content)
                .navigationBarTitleDisplayMode(.inline)
            #else
            watchStyledContent(content)
            #endif
        }
        .accentColor(appearance.accent)
        .tint(appearance.accent)
        .dismissKeyboardOnScroll()
        .topContentMargin(topContentMargin)
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
        let base = appearance.defaultView ? AnyView(content) : AnyView(content.listStyle(.plain))

        if #available(iOS 16.0, *) {
            // Always hidden (not just for custom themes): the wash reproduces every theme's system
            // color exactly, and hiding the system layer is what lets the accent glow show through.
            base
                .scrollContentBackground(.hidden)
                .modifier(AccentWashedBackground())
        } else {
            base
                .modifier(AccentWashedBackground())
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

/// `selectableArticleList`'s body: the list style, text selection on iOS, and the scroll to a search
/// result's section. The scroll waits a beat for the pushed page to lay its rows out; scrolling in the
/// same frame as `onAppear` lands on nothing.
private struct SelectableArticleList: ViewModifier {
    @Environment(\.articleScrollTarget) private var scrollTarget

    let disableNowPlayingInset: Bool
    let topContentMargin: CGFloat

    func body(content: Content) -> some View {
        ScrollViewReader { proxy in
            styled(content)
                .onAppear {
                    guard let scrollTarget, !scrollTarget.isEmpty else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        withAnimation { proxy.scrollTo(ArticleHeader.anchorID(scrollTarget), anchor: .top) }
                    }
                }
        }
    }

    @ViewBuilder
    private func styled(_ content: Content) -> some View {
        let styled = content.applyConditionalListStyle(
            disableNowPlayingInset: disableNowPlayingInset,
            topContentMargin: topContentMargin
        )
        #if os(iOS)
        styled.textSelection(.enabled)
        #else
        styled
        #endif
    }
}

/// Paints the per-row background for the Sepia / Gray reading themes. Must be applied to rows/sections inside
/// a `List` so `.listRowBackground` actually reaches the cells. No-op for Light/Dark/System (system colors).
struct ThemedListRowBackground: ViewModifier {
    @Environment(\.appearance) private var appearance

    @ViewBuilder
    func body(content: Content) -> some View {
        // iOS only: on the watch a flat `.listRowBackground` color REPLACES the native rounded
        // section cards (rows read as square, "cut off") - and the reading themes are phone-only
        // looks anyway (they no longer sync to the watch).
        #if os(iOS)
        if let rowColor = appearance.themeRowBackground {
            content.listRowBackground(rowColor)
        } else {
            content
        }
        #else
        content
        #endif
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

extension View {
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
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isFavorite ? accent : .secondary)
                // The tap target is a 30pt square CENTERED ON THE GLYPH - sized before the corner
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
                .accessibilityLabel(isFavorite ? "Unfavorite \(accessibilityName)" : "Favorite \(accessibilityName)")
        }
    }
}

#if os(iOS)
/// The shared five-way Arabic face picker for the non-Quran Arabic screens (Hadith, Adhkar, Duas,
/// 99 Names, Arabic Alphabet). One control, one setting - every screen that shows standard Arabic
/// text offers the same choice: Uthmani, IndoPak, Hijazi, Kufi, or the system font.
struct IslamArabicFontPicker: View {
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        Picker("Arabic Font", selection: Binding(
            get: { settings.islamArabicFace },
            set: { newValue in
                guard newValue != settings.islamArabicFace else { return }
                settings.hapticFeedback()
                withAnimation(.easeInOut) { settings.islamArabicFace = newValue }
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

// MARK: - Section header accessories (count pill / collapse / shuffle)

/// The small numeric badge the Quran tab's section headers wear - caption-semibold, monospaced digits,
/// on glass. One view so every counted section in the app shows the identical pill.
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
    }
}

/// A full section header in the Quran tab's visual language: optional leading icon, the title, then on
/// the right an optional shuffle button, the count pill, and an optional collapse chevron. Pass
/// `isExpanded` to make the section collapsible (the same chevron.circle control Favorite Surahs and
/// Bookmarked Ayahs use) and `onShuffle` for sections where jumping to a random item makes sense.
/// A small accent-gradient icon chip - the iOS Settings app's row-icon grammar, tinted the app's
/// way. Shared by the Settings hub, settings search results, and the Islam tab's resource rows.
struct AccentIconChip: View {
    @Environment(\.appearance) private var appearance

    let systemImage: String
    var tint: Color? = nil
    var size: CGFloat = 29

    var body: some View {
        let tint = tint ?? appearance.accent
        Image(systemName: systemImage)
            // Scales with the chip (~footnote at the default 29pt), so mini chips stay balanced.
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.95), tint.opacity(0.65)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
}

struct SectionPillHeader: View {
    @Environment(\.appearance) private var appearance

    let title: String
    let count: Int
    var icon: String? = nil
    /// Accent the icon + title (the Quran favorites style); false keeps the standard header gray.
    var accentTitle: Bool = false
    var isExpanded: Binding<Bool>? = nil
    var onShuffle: (() -> Void)? = nil
    /// "5+" style count - set when the count is a floor from an early-exited search.
    var overflow: Bool = false

    /// The count pill's rendered height (caption line height + 2 x 4pt padding) - the shuffle circle
    /// matches it so the two controls read as one family.
    static var pillHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .caption1).lineHeight + 8
    }

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(appearance.accent)
            }

            if accentTitle {
                Text(title)
                    .foregroundStyle(appearance.accent)
            } else {
                Text(title)
            }

            Spacer()

            // The trailing cluster's ONE ordering rule, app-wide: the count pill sits at the far LEFT
            // of the cluster (it is information, not a control), then the buttons - shuffle, then the
            // expand chevron. SurahsHeader lays out the same way; a header that hand-rolls its cluster
            // must follow this order too.
            CountPill(count: count, overflow: overflow)

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
                    .accessibilityLabel(isExpanded.wrappedValue ? "Collapse \(title.lowercased())" : "Expand \(title.lowercased())")
            }
        }
    }
}
