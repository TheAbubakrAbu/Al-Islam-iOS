import SwiftUI
import WidgetKit

// The chrome every widget in the bundle shares, in a file the app compiles too: the DEBUG widget gallery
// (`-widgetGallery`, iPhone/Adhan/WidgetGalleryView.swift) draws the same layouts inside the app, and it
// needs this extension without the `@main` bundle that used to sit beside it (Widgets.swift).

extension View {
    /// iOS 17 requires every widget to declare its background through `containerBackground(for:)`.
    /// Widgets that don't adopt it render blank on iOS 17+ and can disappear from the widget gallery.
    /// Home-screen (system) widgets get the default system background; lock-screen (accessory) widgets
    /// stay clear so the system can apply its own vibrant treatment. `legacyPadding` restores the manual
    /// padding these widgets relied on before iOS 17.
    ///
    /// Every widget goes through here, so this is also where the app-wide rounded design is applied to the widget
    /// tree (the app's own root modifier can't reach an extension). Arabic in a widget opts back out at its own
    /// call site, the same as in the app.
    @ViewBuilder
    func widgetContainerBackground(accessory: Bool = false, legacyPadding: Bool = false) -> some View {
        Group {
            if #available(iOS 17.0, *) {
                if accessory {
                    containerBackground(.clear, for: .widget)
                } else {
                    containerBackground(.background, for: .widget)
                }
            } else if legacyPadding {
                padding()
            } else {
                self
            }
        }
        .appFontDesign()
    }
}

/// WidgetKit's `\.widgetFamily` is read-only, so a layout drawn OUTSIDE WidgetKit (the app's widget gallery)
/// can't be told which family to render. The layouts that switch on the family read this first; it is nil
/// everywhere but the gallery, where each card sets it to the family it is drawing.
private struct PreviewWidgetFamilyKey: EnvironmentKey {
    static let defaultValue: WidgetFamily? = nil
}

extension EnvironmentValues {
    var previewWidgetFamily: WidgetFamily? {
        get { self[PreviewWidgetFamilyKey.self] }
        set { self[PreviewWidgetFamilyKey.self] = newValue }
    }
}
