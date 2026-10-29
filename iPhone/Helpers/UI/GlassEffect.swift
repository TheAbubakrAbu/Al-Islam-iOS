import SwiftUI

/// The corner radius every rectangular glass surface uses, and that anything drawn ON one of them
/// (a selection border, a focus ring) must match.
///
/// It used to live privately inside the glass modifier while call sites that decorated a glass tile
/// hardcoded their own guess. The iPad/Mac sidebar's selection border guessed 12 against the tile's
/// real 24, so the highlight cut visible corners inside the tile it was meant to outline
/// (Abu, 2026-09-19, with a screenshot). One constant, so a border cannot drift from its shape again.
enum GlassCorner {
    /// The radius of `conditionalGlassEffect(rectangle: true)`. A 24pt curve reads right on
    /// iPhone-sized cards; on the watch's small tiles it rounds them into near-stadiums that look
    /// chopped, so the watch uses a gentler one.
    static var rectangle: CGFloat {
        #if os(watchOS)
        14
        #else
        24
        #endif
    }
}


struct ConditionalGlassEffect: ViewModifier {
    // The appearance snapshot, not `Settings`: this modifier sits on ~205 sites (35 on the Adhan tab
    // alone), and as an `@ObservedObject` each one was a subscriber that re-ran on every Settings
    // publish - a page turn re-rendered every pill in the app. The environment value changes only when
    // an appearance field (or the performance tier) does.
    @Environment(\.appearance) private var appearance
    /// The Adhan tab under its whole-tab sky (`Settings.skyFillsAdhanTab`, SkyPageBackground.swift):
    /// every glass surface inside that List draws the CLEAR Liquid Glass style, so the sky shows
    /// through the prayer tiles, the pills and the tracker instead of a frosted regular glass over a
    /// dark row (Abu, 2026-10-19: "if show sky is on then make liquid glass clear for adhan so it
    /// looks prettier"). Liquid Glass only: the pre-26 fallback's `clear` is the ultra-thin material,
    /// which the rows' dark wash would show straight through ("wayyy too transparent").
    @Environment(\.skyPageFill) private var skyPageFill

    var clear: Bool = false
    var rectangle: Bool = false
    var circle: Bool = false
    var useColor: Double? = nil
    /// When set, tints glass with this color (opacity from `useColor`, default 0.35) instead of the app accent.
    var customTint: Color? = nil
    var interactive: Bool = true
    /// When false, glass skips the Sepia/Gray reading-theme tint. Use for nested glass (e.g. a pill inside an
    /// already-tinted card) so it doesn't read as a heavy double-tinted box.
    var themeTint: Bool = true
    /// Pre-Liquid-Glass fallback only: a flat fill on every tier, not just the reduced one. For shapes
    /// that sit on a uniform list row (the prayer tiles, the bells, the Glance tiles): a material over a
    /// flat colour renders as that flat colour anyway, and each one was a backdrop-blur pass. iOS 26
    /// keeps its real glass.
    var flat: Bool = false
    /// Liquid Glass on every iOS 26, Classic Look or not. For the search bar's own chrome, which
    /// keeps the system glass field even when the rest of the app is on the classic fallback
    /// (Abu, 2026-09-04). Pre-26 systems still take the fallback.
    var systemGlass: Bool = false

    /// A 24pt radius reads right on iPhone-sized cards; on the watch's small tiles it rounds them into
    /// near-stadiums that look chopped, so the watch uses a gentler curve.
    private var rectangleCornerRadius: CGFloat { GlassCorner.rectangle }

    func body(content: Content) -> some View {
        // `appearance.liquidGlass` is false on every pre-26 system and under the Classic Look (manual,
        // or automatic in Low Power Mode), so one flag routes all ~207 sites to the fallback.
        if #available(iOS 26.0, watchOS 26.0, *), appearance.liquidGlass || systemGlass {
            modernGlass(content: content)
        } else {
            fallbackGlass(content: content)
        }
    }

    @available(iOS 26.0, watchOS 26.0, *)
    private func modernGlass(content: Content) -> some View {
        Group {
            let regularStyle: Glass = {
                if let tintColor {
                    return interactive ? .regular.tint(tintColor).interactive() : .regular.tint(tintColor)
                }
                return interactive ? .regular.interactive() : .regular
            }()

            let clearStyle: Glass = {
                if let tintColor {
                    return interactive ? .clear.tint(tintColor).interactive() : .clear.tint(tintColor)
                }
                return interactive ? .clear.interactive() : .clear
            }()

            // Clear by the caller's choice, or for every site under the whole-tab sky (see `skyPageFill`).
            let drawsClear = clear || skyPageFill

            if circle {
                content.glassEffect(drawsClear ? clearStyle : regularStyle, in: Circle())
            } else if rectangle {
                content.glassEffect(drawsClear ? clearStyle : regularStyle, in: RoundedRectangle(cornerRadius: rectangleCornerRadius, style: .continuous))
            } else if drawsClear {
                content.glassEffect(clearStyle)
            } else {
                content.glassEffect(regularStyle)
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func fallbackGlass(content: Content) -> some View {
        if circle {
            fallbackGlassShape(content: content, shape: Circle())
        } else if rectangle {
            fallbackGlassShape(content: content, shape: RoundedRectangle(cornerRadius: rectangleCornerRadius, style: .continuous))
        } else {
            fallbackGlassShape(content: content, shape: Capsule())
        }
    }

    private func fallbackGlassShape<S: Shape>(content: Content, shape: S) -> some View {
        let fallbackBaseFill: Color = {
            #if os(iOS)
            return Color(UIColor.secondarySystemBackground).opacity(clear ? 0.7 : 1.0)
            #else
            return Color.gray.opacity(clear ? 0.12 : 0.18)
            #endif
        }()

        let fallbackOverlayColor = tintColor ?? .clear

        return content
            .background {
                // Reduced tier (Low Power Mode, thermal throttling, a 3 GB-class device) or Reduce
                // Transparency: a flat fill. Every material here is a backdrop blur pass, and a screen
                // stacks dozens of them; on A11-A13 GPUs that is the scroll stutter people report. The
                // tint overlay and the hairline stroke below still apply, so the pill keeps its shape.
                if appearance.flattenMaterials {
                    shape.fill(fallbackBaseFill)
                } else if flat {
                    // The colour a material lands on over a uniform list row (measured: ultra-thin
                    // and regular both read ~#2D2E2E on a dark grouped row, white on a light one),
                    // so a flat tile is indistinguishable from the blurred one it replaces.
                    #if os(iOS)
                    shape.fill(Color(UIColor.tertiarySystemBackground))
                    #else
                    shape.fill(fallbackBaseFill)
                    #endif
                } else if #available(iOS 15.0, watchOS 10.0, *) {
                    // Regular material, not ultra-thin: on pre-Liquid-Glass systems these pills float
                    // straight over list content, and ultra-thin let the rows bleed through them
                    // ("wayyy too transparent" - user report). `clear` keeps the see-through variant
                    // for surfaces that want it.
                    if clear {
                        shape.fill(.ultraThinMaterial)
                    } else {
                        shape.fill(.regularMaterial)
                    }
                } else {
                    shape.fill(fallbackBaseFill)
                }
            }
            // Overlays must not intercept taps - otherwise buttons/menus underneath never receive touches.
            .overlay(shape.fill(fallbackOverlayColor).allowsHitTesting(false))
            .overlay(shape.stroke(Color.primary.opacity(0.12), lineWidth: 1).allowsHitTesting(false))
    }

    private var tintColor: Color? {
        if let customTint {
            return customTint.opacity(useColor ?? 0.35)
        }
        if let useColor {
            return appearance.accent.opacity(useColor)
        }
        // Untinted glass picks up the active reading theme so cards aren't plain white/black in Sepia/Gray,
        // unless the caller opts out (nested glass that would otherwise double-tint).
        return themeTint ? appearance.glassTint : nil
    }
}

#if os(iOS)
/// The one place every sheet's size is decided. A sheet opens SMALL (about half the screen) and can be dragged
/// up to full height if its content needs the room - so a sheet never covers the screen for a choice that
/// takes a moment. On iPad a sheet is a centred card, where a half-height detent is meaningless, so it stays
/// full-size.
struct SheetPresentationModifier: ViewModifier {
    #if DEBUG
    /// "-sheetLarge" - open every sheet at full height. Sheets can't be dragged headlessly (taps
    /// aren't scriptable in the simulator), so verifying anything below the medium detent's fold
    /// needs the sheet to start there.
    private static let forceLarge = ProcessInfo.processInfo.arguments.contains("-sheetLarge")
    #else
    private static let forceLarge = false
    #endif

    /// Open at the large detent, with the medium one still a drag away: for a sheet whose content
    /// the medium detent would show only a sliver of (the ayah actions sheet of a long ayah, whose
    /// preview card reads at the reader's size). A plain Bool rather than a stored
    /// `PresentationDetent`, which does not exist on iOS 15.
    @State private var isLarge: Bool

    /// The sheet's own reason to refuse interactive dismissal (a save in flight, a system prompt up),
    /// folded in with the opening guard below. Passed here rather than stacked as a second
    /// `interactiveDismissDisabled` outside this modifier: nested copies resolve in one direction
    /// only, and whichever lost would be silently ignored.
    var dismissDisabled: Bool

    /// True for the first moments after the sheet appears. A sheet opened by a tap is closed by the
    /// SECOND tap of a double tap: UIKit presents on the first, and the second lands on the dimmed
    /// backdrop above the still-rising sheet, which is its "tap outside to close" (reproduced on the
    /// simulator at a 300 ms gap; at 150 ms the transition still swallows it). The ayah preview card
    /// opens a word card on ONE tap, so a double-tapped word opened its card and closed it again in
    /// the same motion (Abu, 2026-10-22: "when I double click a word there it auto dismisses it").
    /// Nobody means to close a sheet half a second after opening it, so interactive dismissal (the
    /// backdrop tap, the swipe down) waits that long; programmatic dismissal never does.
    @State private var settling = true
    private static let settleDuration: TimeInterval = 0.6

    /// Whether the Now Playing bar is up (the narrow slice, not the player: see `PlaybackVisibility`).
    @ObservedObject private var playback = PlaybackVisibility.shared
    /// True while a List inside this sheet draws the bar itself (`ConditionalListStyle` sets the
    /// preference), so the sheet never stacks a second one under it.
    @State private var listDrawsNowPlaying = false

    init(startLarge: Bool = false, dismissDisabled: Bool = false) {
        _isLarge = State(initialValue: startLarge)
        self.dismissDisabled = dismissDisabled
    }

    func body(content: Content) -> some View {
        detents(content)
            .environment(\.nowPlayingInSheet, true)
            .interactiveDismissDisabled(settling || dismissDisabled)
            .onPreferenceChange(NowPlayingBarProvidedKey.self) { listDrawsNowPlaying = $0 }
            // A bar, not a bare inset: the scroll edge fades the sheet's text under the player instead
            // of letting it run on behind it in full ink (see `nowPlayingInSheet`).
            .adaptiveSafeArea(edge: .bottom) { nowPlayingInset }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + Self.settleDuration) { settling = false }
            }
    }

    /// The Now Playing bar at the foot of the sheet while a recitation plays (Abu, 2026-10-26: "put
    /// now playing view in hold down ayah sheet, put it in every sheet"), the inset every list draws
    /// (`ConditionalListStyle`), for a sheet built on a `ScrollView`: the ayah actions sheet, the
    /// tafsir and word cards, Share Ayah. A sheet whose List already draws the bar gets nothing here, and
    /// neither does one in a `SheetNavigationContainer`, whose screens draw their own (`sheetNowPlayingBar()`):
    /// this copy would sit outside the navigation stack, where its inset never reaches the content.
    @ViewBuilder
    private var nowPlayingInset: some View {
        if !listDrawsNowPlaying, playback.showsNowPlaying, let bar = playback.barContent {
            NowPlayingBarStack(bar: bar, shown: playback.showsNowPlaying)
        }
    }

    /// The keyboard came up for a field in THIS sheet while it stood at the medium detent: commit the
    /// large detent. UIKit already lifts a medium sheet to make room for the keyboard, so nothing moves
    /// that was not already moving; what changes is the way OUT. Closed with the keyboard up (the X, a
    /// pick, a swipe), a sheet that was merely lifted snapped back toward its medium height while
    /// sliding away, its content re-laid out mid-slide (Abu, 2026-10-23, Choose Surah: "when it's half
    /// screen and I type and then dismiss it does a weird glitch thing"; frame-scanned on the
    /// simulator: the sheet jumped about 90 pt down a quarter of the way out and its search bar
    /// vanished). At a committed large detent the same close is one clean slide (checked first with
    /// `-sheetLarge`). The sheet then STAYS large once the keyboard goes, which the results it was
    /// typed for want anyway; it can still be dragged back down. Every sheet with a search bar or a
    /// text field gets this, so none of them needs to open full screen for it.
    private func growForKeyboard() {
        guard !isLarge else { return }
        isLarge = true
    }

    @ViewBuilder
    private func detents(_ content: Content) -> some View {
        if #available(iOS 16.0, *) {
            if UIDevice.current.userInterfaceIdiom == .phone {
                content
                    .background(SheetKeyboardProbe(onKeyboard: growForKeyboard))
                    .presentationDetents(
                        Self.forceLarge ? [.large] : [.medium, .large],
                        selection: Binding(
                            get: { (isLarge || Self.forceLarge) ? .large : .medium },
                            set: { isLarge = $0 == .large }
                        )
                    )
                    .presentationDragIndicator(.visible)
            } else {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        } else {
            content
        }
    }
}

/// Reports a keyboard coming up for a first responder inside the sheet this view sits in, and not for
/// one in a sheet stacked above it or anywhere else: the keyboard notification is app-wide, so the probe
/// finds the root of its own presentation up the responder chain and checks that the first responder is
/// a descendant of that controller's view. Inert otherwise: no size of its own, no touches.
private struct SheetKeyboardProbe: UIViewRepresentable {
    let onKeyboard: () -> Void

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.onKeyboard = onKeyboard
        return view
    }

    func updateUIView(_ view: ProbeView, context: Context) {
        view.onKeyboard = onKeyboard
    }

    final class ProbeView: UIView {
        var onKeyboard: (() -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            backgroundColor = .clear
            // Selector-based, so the observation ends with the view and nothing has to be removed.
            NotificationCenter.default.addObserver(
                self, selector: #selector(keyboardWillShow),
                name: UIResponder.keyboardWillShowNotification, object: nil
            )
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        @objc private func keyboardWillShow() {
            guard let window, let sheet = presentedRoot,
                  let responder = Self.firstResponder(in: window),
                  responder.isDescendant(of: sheet.view) else { return }
            onKeyboard?()
        }

        /// The root of the presentation this view is part of: up the responder chain to the first view
        /// controller that is presented, then up its parents. A navigation stack inside the sheet is a
        /// CHILD of the presented controller, and a `.searchable` field lives in its bar, outside the
        /// content's own view, so the check has to be against the root.
        private var presentedRoot: UIViewController? {
            var responder: UIResponder? = next
            while let current = responder {
                if let controller = current as? UIViewController, controller.presentingViewController != nil {
                    var root = controller
                    while let parent = root.parent { root = parent }
                    return root
                }
                responder = current.next
            }
            return nil
        }

        private static func firstResponder(in view: UIView) -> UIView? {
            if view.isFirstResponder { return view }
            for subview in view.subviews {
                if let found = firstResponder(in: subview) { return found }
            }
            return nil
        }
    }
}

/// The standard sheet toolbar: an X to close, and (when the sheet edits something) a checkmark to confirm.
///
/// This exact pair was copy-pasted into a dozen sheets, and had already drifted - one used `.subheadline`
/// where the rest used `.body`, several dropped the accent tint, and a few sheets used a text "Done" button or
/// had no dismiss control at all. Defining it once means every sheet dismisses the same way.
struct SheetDismissToolbar: ViewModifier {
    @Environment(\.appearance) private var appearance
    @Environment(\.dismiss) private var dismiss

    /// When non-nil, a checkmark is shown. Returning `false` keeps the sheet open (e.g. a failed validation).
    var onConfirm: (() -> Bool)?

    // Branching happens here at the VIEW level, not inside the `toolbar` builder: `ToolbarContentBuilder`'s
    // `if` needs iOS 16, and the app deploys to 15.
    @ViewBuilder
    func body(content: Content) -> some View {
        if let onConfirm {
            content
                .toolbar { closeItem }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            Settings.shared.hapticFeedback()
                            if onConfirm() { dismiss() }
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.body.weight(.semibold))
                        }
                        .tint(appearance.accent)
                        .accessibilityLabel("Done")
                    }
                }
        } else {
            content.toolbar { closeItem }
        }
    }

    private var closeItem: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                Settings.shared.hapticFeedback()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
            }
            .tint(appearance.accent)
            .accessibilityLabel("Close")
        }
    }
}
#endif

extension View {
    func conditionalGlassEffect(
        clear: Bool = false,
        rectangle: Bool = false,
        circle: Bool = false,
        useColor: Double? = nil,
        customTint: Color? = nil,
        interactive: Bool = true,
        themeTint: Bool = true,
        flat: Bool = false,
        systemGlass: Bool = false
    ) -> some View {
        modifier(ConditionalGlassEffect(clear: clear, rectangle: rectangle, circle: circle, useColor: useColor, customTint: customTint, interactive: interactive, themeTint: themeTint, flat: flat, systemGlass: systemGlass))
    }

    /// Presents a `Menu`'s items in DECLARED order, top to bottom, wherever the menu pops up from.
    /// iOS's automatic ordering reverses a menu that opens UPWARD (e.g. from a play button at the bottom
    /// of the screen) so the first-declared item lands nearest the finger - which visually dumped
    /// "Choose Reciter" to the BOTTOM of every play menu that deliberately declares it first. No-op below
    /// iOS 16, where the modifier doesn't exist and menus keep the system behavior.
    @ViewBuilder
    func fixedMenuOrder() -> some View {
        if #available(iOS 16.0, watchOS 9.0, *) {
            self.menuOrder(.fixed)
        } else {
            self
        }
    }

    #if os(iOS)
    /// `startLarge` opens the sheet at full height (see `SheetPresentationModifier.isLarge`);
    /// `dismissDisabled` is the sheet's own reason to refuse interactive dismissal (see
    /// `SheetPresentationModifier.dismissDisabled`). Every standard sheet also refuses it for its
    /// first moments on screen (`SheetPresentationModifier.settling`).
    func smallMediumSheetPresentation(startLarge: Bool = false, dismissDisabled: Bool = false) -> some View {
        modifier(SheetPresentationModifier(startLarge: startLarge, dismissDisabled: dismissDisabled))
    }

    /// An X to close, plus an optional checkmark to confirm. See `SheetDismissToolbar`.
    func sheetDismissToolbar(onConfirm: (() -> Bool)? = nil) -> some View {
        modifier(SheetDismissToolbar(onConfirm: onConfirm))
    }

    /// `sheetDismissToolbar()` only when this copy of the screen IS a sheet. For the views that are
    /// reached both ways (pushed onto a stack and presented as a sheet): a pushed copy already has
    /// the stack's back button, and a second dismiss control beside it is wrong.
    @ViewBuilder
    func sheetDismissToolbarIf(_ isSheet: Bool, onConfirm: (() -> Bool)? = nil) -> some View {
        if isSheet { modifier(SheetDismissToolbar(onConfirm: onConfirm)) } else { self }
    }
    #endif
}
