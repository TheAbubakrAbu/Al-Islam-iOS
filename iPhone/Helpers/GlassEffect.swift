import SwiftUI

struct ConditionalGlassEffect: ViewModifier {
    @ObservedObject private var settings = Settings.shared

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

    func body(content: Content) -> some View {
        if #available(iOS 26.0, watchOS 26.0, *) {
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
                content.glassEffect(clear ? clearStyle : regularStyle, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
            fallbackGlassShape(content: content, shape: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
                if #available(iOS 15.0, watchOS 10.0, *) {
                    shape.fill(.ultraThinMaterial)
                } else {
                    shape.fill(fallbackBaseFill)
                }
            }
            // Overlays must not intercept taps — otherwise buttons/menus underneath never receive touches.
            .overlay(shape.fill(fallbackOverlayColor).allowsHitTesting(false))
            .overlay(shape.stroke(Color.primary.opacity(0.12), lineWidth: 1).allowsHitTesting(false))
    }

    private var tintColor: Color? {
        if let customTint {
            return customTint.opacity(useColor ?? 0.35)
        }
        if let useColor {
            return settings.accentColor.color.opacity(useColor)
        }
        // Untinted glass picks up the active reading theme so cards aren't plain white/black in Sepia/Gray,
        // unless the caller opts out (nested glass that would otherwise double-tint).
        return themeTint ? settings.themeGlassTint : nil
    }
}

#if os(iOS)
struct SheetPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            if UIDevice.current.userInterfaceIdiom == .phone {
                content
                    .presentationDetents([.medium, .large])
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
#endif

extension View {
    func conditionalGlassEffect(
        clear: Bool = false,
        rectangle: Bool = false,
        circle: Bool = false,
        useColor: Double? = nil,
        customTint: Color? = nil,
        interactive: Bool = true,
        themeTint: Bool = true
    ) -> some View {
        modifier(ConditionalGlassEffect(clear: clear, rectangle: rectangle, circle: circle, useColor: useColor, customTint: customTint, interactive: interactive, themeTint: themeTint))
    }

    #if os(iOS)
    func smallMediumSheetPresentation() -> some View {
        modifier(SheetPresentationModifier())
    }
    #endif
}
