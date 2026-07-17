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

    /// The minimized look for a custom glass bar: scaled toward its bottom edge and slightly faded, the same
    /// visual language as the iOS 26 minimized tab bar. Pair with hiding the bar's secondary rows.
    func minimizedBarStyle(_ collapsed: Bool) -> some View {
        self
            .scaleEffect(collapsed ? 0.86 : 1, anchor: .bottom)
            .opacity(collapsed ? 0.72 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: collapsed)
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

struct ConditionalListStyle: ViewModifier {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.customColorScheme) private var customColorScheme

    let disableNowPlayingInset: Bool
    var topContentMargin: CGFloat = 0

    private var currentColorScheme: ColorScheme {
        settings.colorScheme ?? systemColorScheme
    }

    private var shouldShowNowPlaying: Bool {
        quranPlayer.isPlaying || quranPlayer.isPaused
    }

    func body(content: Content) -> some View {
        Group {
            #if os(iOS)
            styledContent(content)
                .navigationBarTitleDisplayMode(.inline)
            #else
            content
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
            if !disableNowPlayingInset && shouldShowNowPlaying {
                VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                    NowPlayingView()
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
    // (Row colors are handled separately by `themedListRowBackground()` applied inside each List.)
    @ViewBuilder
    private func styledContent(_ content: Content) -> some View {
        let base = settings.defaultView ? AnyView(content) : AnyView(content.listStyle(.plain))

        if #available(iOS 16.0, *) {
            base
                .scrollContentBackground(settings.hasCustomThemeColors ? .hidden : .automatic)
                .background(resolvedListBackground.ignoresSafeArea())
        } else {
            base
                .background(resolvedListBackground.ignoresSafeArea())
        }
    }

    private var resolvedListBackground: Color {
        if settings.hasCustomThemeColors {
            return settings.themeBackgroundColor ?? Color(.systemGroupedBackground)
        }
        if settings.defaultView {
            return Color(.systemGroupedBackground)
        }
        return currentColorScheme == .dark ? .black : .white
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
                .padding(.top, 10)
                .padding(.trailing, 11)
                .contentShape(Rectangle().inset(by: -10))
                .onTapGesture {
                    Settings.shared.hapticFeedback()
                    withAnimation(.easeInOut) {
                        onToggle()
                    }
                }
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
