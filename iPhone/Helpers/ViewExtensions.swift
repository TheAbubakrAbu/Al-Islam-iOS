import SwiftUI

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
    /// (not to the `List` itself) — `.listRowBackground` only propagates when attached to row content, which
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
        // Force the theme's light/dark base here (not just at the app root) so sheets — which are their own
        // presentation contexts and don't inherit the root's preferredColorScheme — also adopt the theme.
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
    // Sepia/Gray used to flip between if/else branches, which changed the view tree and recreated the List —
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
                // lurch isn't the dismiss mode — it's the bottom safe-area bar re-animating its position on a
                // curve that fights the keyboard's. That's fixed at the bar itself: the search-bar container
                // strips its inherited animation transaction (see QuranView `bottomControls`) so it snaps with
                // the keyboard instead of easing separately — the same `.transaction { $0.animation = nil }`
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
