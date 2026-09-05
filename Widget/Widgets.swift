import SwiftUI
import WidgetKit

@main
struct Widgets: WidgetBundle {
    var body: some Widget {
        // Al-Adhan: home screen, in gallery order - every layout on the current prayer's sky
        // gradient first, then the same layouts again - every one - on the standard background.
        // Both blocks share an order so a sky widget and its no-sky twin are easy to match up in
        // the gallery.
        // (Companion apps: delete the domains you don't ship; the Quran widgets are the block below.)
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
            // The date widgets (DateLockWidgets.swift): the next prayer with the date and city, then
            // both calendars, then the Hijri date alone, in English and in Arabic.
            NextPrayerDateLockWidget()
            DualCalendarLockWidget()
            HijriDateLockWidget()
            HijriDateArabicLockWidget()
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
