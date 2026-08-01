import SwiftUI
import WidgetKit

@main
struct Widgets: WidgetBundle {
    var body: some Widget {
        // Al-Adhan: home screen, in gallery order - every layout on the standard background first,
        // then the same layouts again - every one - on the current prayer's sky gradient. Both blocks
        // share an order so a no-sky widget and its sky twin are easy to match up in the gallery.
        // (Companion apps: delete the domains you don't ship; the Quran widgets are the block below.)
        PrayerGlanceWidget()
        SolarArcWidget()
        MoonWidget()
        SolarMoonWidget()
        NextPrayerBoardWidget()
        PrayerDayWidget()
        CountdownWidget()
        SimpleWidget()
        PrayerListSmallWidget()
        PrayersWidget()
        Prayers2Widget()
        FastingCountdownWidget()

        PrayerGradientWidget()          // the sky twin of Prayer Glance
        SolarArcSkyWidget()
        MoonSkyWidget()
        SolarMoonSkyWidget()
        NextPrayerBoardSkyWidget()
        PrayerDaySkyWidget()
        CountdownSkyWidget()
        SimpleSkyWidget()
        PrayerListSmallSkyWidget()
        PrayersSkyWidget()
        Prayers2SkyWidget()
        FastingCountdownSkyWidget()

        #if os(iOS)
        // Lock screen: the two circulars, then the rectangulars from richest to plainest.
        if #available(iOS 16.1, *) {
            PrayerProgressRingWidget()
            PrayerCountdownCircularWidget()
            LockScreen1Widget()
            PrayerWaveWidget()
            LockScreen2Widget()
            NextPrayerProgressWidget()
            PrayerRowLockWidget()
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
        
        // Al-Quran: the reading/listening widgets.
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
