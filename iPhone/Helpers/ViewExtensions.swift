import SwiftUI

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

extension View {
    @ViewBuilder
    func adaptiveSafeArea<InsetContent: View>(edge: VerticalEdge, @ViewBuilder content: () -> InsetContent) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            self.safeAreaBar(edge: edge) {
                content()
            }
        } else {
            self.safeAreaInset(edge: edge) {
                content()
            }
        }
        #else
        self.safeAreaInset(edge: edge) {
            content()
        }
        #endif
    }

    func applyConditionalListStyle(disableNowPlayingInset: Bool = false, topContentMargin: CGFloat = 0) -> some View {
        modifier(ConditionalListStyle(disableNowPlayingInset: disableNowPlayingInset, topContentMargin: topContentMargin))
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

/// Vertical spacing between views inside `safeAreaInset` stacks: iOS 26+ uses tighter 8pt; older systems use 16pt.
enum SafeAreaInsetVStackSpacing {
    static var standard: CGFloat {
        if #available(iOS 26.0, watchOS 26.0, *) {
            return 8
        }
        return 12
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
    @ObservedObject private var settings = Settings.shared
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        let strength: Double = (settings.hasCustomThemeColors || !settings.showAccentGlow)
            ? 0 : ((settings.colorScheme ?? systemColorScheme) == .dark ? 0.16 : 0.10)
        let brand = settings.alIslamGlow

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
            let verticalReach: CGFloat = 380

            ZStack {
                RadialGradient(
                    colors: [settings.accentColor.color.opacity(brand ? 0 : strength), .clear],
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
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        // The watch renders on pure black OLED, so the wash can sit a touch brighter than the
        // iPhone's dark-mode 0.16 and still stay quiet.
        let strength: Double = (settings.hasCustomThemeColors || !settings.showAccentGlow) ? 0 : 0.20
        let brand = settings.alIslamGlow

        // Same width-tracking ellipse as the iPhone overlay: the radius follows the screen width
        // (198pt on a 45mm, wider on Ultra) so the wash spans the whole top edge, then compresses
        // vertically to the tuned 150pt reach so it still dies well above the bottom.
        GeometryReader { geo in
            let radius = max(190, geo.size.width)
            let verticalReach: CGFloat = 150

            ZStack {
                RadialGradient(
                    colors: [settings.accentColor.color.opacity(brand ? 0 : strength), .clear],
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
    @ObservedObject private var settings = Settings.shared
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
            .accentColor(settings.accentColor.color)
            .tint(settings.accentColor.color)
            .preferredColorScheme(settings.colorScheme)
        #elseif os(watchOS)
        content
            .background(WatchTopGlowOverlay())
        #else
        content
        #endif
    }

    #if os(iOS)
    /// The list background every theme resolves to - identical to what `ConditionalListStyle` painted
    /// historically (`resolvedListBackground`), kept in ONE place now.
    private var resolvedBackground: Color {
        if settings.hasCustomThemeColors {
            return settings.themeBackgroundColor ?? Color(.systemGroupedBackground)
        }
        if settings.defaultView {
            return Color(.systemGroupedBackground)
        }
        return (settings.colorScheme ?? systemColorScheme) == .dark ? .black : .white
    }
    #endif
}

extension View {
    /// The themed base + accent glow for screens that are not system Lists - see `AccentWashedBackground`.
    func accentWashedBackground() -> some View {
        modifier(AccentWashedBackground())
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
    @ObservedObject private var settings = Settings.shared
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
        .accentColor(settings.accentColor.color)
        .tint(settings.accentColor.color)
        .dismissKeyboardOnScroll()
        .topContentMargin(topContentMargin)
        // Force the theme's light/dark base here (not just at the app root) so sheets - which are their own
        // presentation contexts and don't inherit the root's preferredColorScheme - also adopt the theme.
        .preferredColorScheme(settings.colorScheme)
        #if os(iOS)
        .safeAreaInset(edge: .bottom) {
            if !disableNowPlayingInset && shouldShowNowPlaying, let bar = playback.barContent {
                VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                    bar()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
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
        let base = settings.defaultView ? AnyView(content) : AnyView(content.listStyle(.plain))

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

/// Paints the per-row background for the Sepia / Gray reading themes. Must be applied to rows/sections inside
/// a `List` so `.listRowBackground` actually reaches the cells. No-op for Light/Dark/System (system colors).
struct ThemedListRowBackground: ViewModifier {
    @ObservedObject private var settings = Settings.shared

    @ViewBuilder
    func body(content: Content) -> some View {
        if settings.hasCustomThemeColors, let rowColor = settings.themeRowBackgroundColor {
            content.listRowBackground(rowColor)
        } else {
            content
        }
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
/// The shared three-way Arabic face picker for the non-Quran Arabic screens (Hadith, Adhkar, Duas,
/// 99 Names, Arabic Alphabet). One control, one setting - every screen that shows standard Arabic
/// text offers the same choice: Uthmani (the Qiraat face), IndoPak, or the system font.
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
    let count: Int
    /// "5+" style - set when the count is a floor from an early-exited search, not an exact total.
    var overflow: Bool = false

    var body: some View {
        Text("\(count)\(overflow ? "+" : "")")
            .font(.caption.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(Settings.shared.accentColor.color)
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
    @ObservedObject private var settings = Settings.shared

    let systemImage: String
    var tint: Color? = nil
    var size: CGFloat = 29

    var body: some View {
        let tint = tint ?? settings.accentColor.color
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
    @ObservedObject private var settings = Settings.shared

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
                    .foregroundStyle(settings.accentColor.color)
            }

            if accentTitle {
                Text(title)
                    .foregroundStyle(settings.accentColor.color)
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
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: Self.pillHeight, height: Self.pillHeight)
                    .conditionalGlassEffect(circle: true)
                    .onTapGesture {
                        settings.hapticFeedback()
                        onShuffle()
                    }
                    .accessibilityLabel("Random \(title.lowercased())")
            }

            if let isExpanded {
                Image(systemName: isExpanded.wrappedValue ? "chevron.down.circle" : "chevron.up.circle")
                    .foregroundColor(settings.accentColor.color)
                    .padding(4)
                    .conditionalGlassEffect()
                    .onTapGesture {
                        settings.hapticFeedback()
                        withAnimation { isExpanded.wrappedValue.toggle() }
                    }
                    .accessibilityLabel(isExpanded.wrappedValue ? "Collapse \(title.lowercased())" : "Expand \(title.lowercased())")
            }
        }
    }
}
