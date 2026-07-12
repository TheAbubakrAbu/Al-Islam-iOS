import SwiftUI
import WidgetKit

@main
struct Widgets: WidgetBundle {
    var body: some Widget {
        SimpleWidget()
        CountdownWidget()
        Prayers2Widget()
        PrayersWidget()
        
        #if os(iOS)
        if #available(iOS 16.1, *) {
            LockScreen1Widget()
            LockScreen2Widget()
            LockScreen3Widget()
            LockScreen4Widget()
        }
        // Gated at 16.2 rather than 16.1, where Live Activities first appeared: `ActivityContent` - which the
        // app uses to start and update this one - only exists from 16.2. Suhoor and iftar countdowns; only
        // ever on screen during Ramadan.
        if #available(iOS 16.2, *) {
            FastingLiveActivity()
        }
        #endif
        
        LastListenedSurahWidget()
        LastListenedAyahWidget()
        LastReadSurahWidget()
        AyahOfTheDayWidget()
    }
}

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
