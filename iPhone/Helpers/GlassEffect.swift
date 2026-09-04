import SwiftUI

struct ConditionalGlassEffect: ViewModifier {
    // The appearance snapshot, not `Settings`: this modifier sits on ~205 sites (35 on the Adhan tab
    // alone), and as an `@ObservedObject` each one was a subscriber that re-ran on every Settings
    // publish - a page turn re-rendered every pill in the app. The environment value changes only when
    // an appearance field (or the performance tier) does.
    @Environment(\.appearance) private var appearance

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

    /// A 24pt radius reads right on iPhone-sized cards; on the watch's small tiles it rounds them into
    /// near-stadiums that look chopped, so the watch uses a gentler curve.
    private var rectangleCornerRadius: CGFloat {
        #if os(watchOS)
        14
        #else
        24
        #endif
    }

    func body(content: Content) -> some View {
        // `appearance.liquidGlass` is false on every pre-26 system and under the Classic Look (manual,
        // or automatic in Low Power Mode), so one flag routes all ~207 sites to the fallback.
        if #available(iOS 26.0, watchOS 26.0, *), appearance.liquidGlass {
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
            
            if circle {
                content.glassEffect(clear ? clearStyle : regularStyle, in: Circle())
            } else if rectangle {
                content.glassEffect(clear ? clearStyle : regularStyle, in: RoundedRectangle(cornerRadius: rectangleCornerRadius, style: .continuous))
            } else if clear {
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

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            if UIDevice.current.userInterfaceIdiom == .phone {
                content
                    .presentationDetents(Self.forceLarge ? [.large] : [.medium, .large])
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
        flat: Bool = false
    ) -> some View {
        modifier(ConditionalGlassEffect(clear: clear, rectangle: rectangle, circle: circle, useColor: useColor, customTint: customTint, interactive: interactive, themeTint: themeTint, flat: flat))
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
    func smallMediumSheetPresentation() -> some View {
        modifier(SheetPresentationModifier())
    }

    /// An X to close, plus an optional checkmark to confirm. See `SheetDismissToolbar`.
    func sheetDismissToolbar(onConfirm: (() -> Bool)? = nil) -> some View {
        modifier(SheetDismissToolbar(onConfirm: onConfirm))
    }
    #endif
}
