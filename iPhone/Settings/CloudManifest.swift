// iCloud Backup is Al-Islam's alone: this file compiles only where `HAS_ICLOUD_BACKUP` is defined
// (Al-Islam's project settings). The companion apps never receive it (sync-manifests).
#if HAS_ICLOUD_BACKUP
import Foundation

/// What an iCloud backup carries, key by key (docs/iCloud Sync Guide.md, section 5a).
///
/// A backup is an explicit list and never "whatever is in UserDefaults": restoring a device-only
/// key onto another phone (a migration flag, the armed-notification signature, a cached location)
/// breaks things quietly, the adhan schedule first among them. Every saved key in the sources is
/// therefore in exactly one class:
///
/// - **content**: `Settings.contentStorageKeys`, the list a keep-content reset preserves. Restored by
///   Replace and by Merge, each under a rule in `CloudMergeRules`.
/// - **preference**: `preferenceKeys` and `appGroupPreferenceKeys`. Restored by Replace only; a Merge
///   leaves this device's settings alone.
/// - **device-only**: `deviceOnlyKeys` and `deviceOnlyPrefixes`. Never backed up.
///
/// `Scripts/check_cloud_manifest.py` fails when a key named in the sources is in no list, and the
/// DEBUG launch argument `-cloudKeyAudit` does the same against the live defaults domain (for keys
/// built from strings). Nothing here names an app type, so the file compiles in the sibling apps,
/// where a key for a feature they lack is simply never present.
///
/// Three of the lists are not kept here at all (guide, section 12): the content list is the reset's
/// (`Settings.contentStorageKeys`), the app-group keys are the `backedUp` rows of the table the reset
/// and the watch sync read (`Settings.appGroupPreferences`), and every key the watch syncs
/// (`Settings.watchSyncedAppStorageKeys`) is a preference by construction.
enum CloudManifest {
    static var contentKeys: [String] { Settings.contentStorageKeys }

    /// Standard-defaults preferences: appearance, reading, prayer, notification and share options,
    /// the About You answers, and the small "how I left this screen" choices. The hand-kept list
    /// below plus whatever the watch syncs, so a key added to the watch sync is backed up without
    /// a second edit here (and the script fails if the watch list ever names a content key).
    static let preferenceKeys: [String] = {
        var seen = Set(listedPreferenceKeys)
        var keys = listedPreferenceKeys
        for key in Settings.watchSyncedAppStorageKeys where seen.insert(key).inserted { keys.append(key) }
        return keys
    }()

    static let listedPreferenceKeys: [String] = [
        "THEfontArabic", "acceptedBetaQiraatNotice", "adhanNotificationSound", "adhanOverridesSilentMode",
        "adhanSoundAsr", "adhanSoundDhuhr", "adhanSoundFajr", "adhanSoundIsha", "adhanSoundMaghrib",
        "alIslamGlow", "alertToneSound", "arabicFilterMode", "arabicLetterSizeIndex",
        "automaticKhatmCompletion", "ayahPreviewCardScale", "beginnerMode", "betaQiraatEnabled",
        "calculationAutomatic", "classicLook", "classicLookInLowPower", "cleanArabicText",
        "colorSchemeString", "confirmedMinshawiAyahFallbackReciterIDs", "copyAyahArabic",
        "copyAyahEnglishMustafa", "copyAyahEnglishSaheeh", "copyAyahTransliteration", "customFajrAngle",
        "customIshaAngle", "customRangeRepeatPerAyah", "customRangeRepeatSection",
        "customRangeSelectionMode", "dailyRolloverAtFajr", "dateNotifications", "dateNotificationsDayBefore",
        "defaultView", "displayQiraah", "englishFontSize", "extraReminders", "faraidShowWider",
        "fontArabicSize", "gridModeArabicRaw", "gridModeIslamRaw", "gridModeNamesRaw",
        "hadithArabicFontSize", "hadithEnglishFontSize", "hadithGridMode", "hadithSearchFilterPreferences",
        "hadithSearchHelpCollapsed", "hapticOn", "hideEnglishInArabicLetters", "highlightAllahNames",
        "highlightAllahNamesHadith", "highlightAllahNamesIslam", "hijriCalendarDisplayMode",
        "islamArabicFontFace", "keepAyahSheetOpen", "khatmGroupByJuz", "launchTab", "launchTabChosen",
        "mushafBottomBarsCollapsed", "mushafFitPage", "mushafPDFAppearance", "mushafPageLanguage",
        "mushafTwoPageSpread", "naggingAsr", "naggingAyahInLastCall", "naggingDeadlineStarts",
        "naggingDhuhr", "naggingDuha", "naggingFajr", "naggingFollowUpMinutes", "naggingInterval",
        "naggingIsha", "naggingIslamicMidnight", "naggingLastCalls", "naggingLastThird",
        "naggingLoudLastCall", "naggingMaghrib", "naggingMode", "naggingPausedUntil",
        "naggingPerDeadlineStart", "naggingSound", "naggingStartOffset", "naggingSunrise", "notificationAsr",
        "notificationDhuhr", "notificationDuha", "notificationFajr", "notificationIsha",
        "notificationIslamicMidnight", "notificationLastThird", "notificationMaghrib", "notificationSunrise",
        "nowPlayingExpanded", "offsetAsr", "offsetDhuhr", "offsetFajr", "offsetIsha", "offsetMaghrib",
        "offsetSunrise", "prayerDisplayModeV2", "prayerNotificationEnglishNames",
        "prayerTimesMapShowCityTime", "prayerTimesMapShowDuha", "prayerTimesMapShowIslamicMidnight",
        "prayerTimesMapShowLastThird", "preNotificationAsr", "preNotificationDhuhr", "preNotificationDuha",
        "preNotificationFajr", "preNotificationIsha", "preNotificationIslamicMidnight",
        "preNotificationLastThird", "preNotificationMaghrib", "preNotificationSunrise",
        "qiraahCompareHideDots", "qiraahCompareHideTashkeel", "qiraahCompareShowTajweed", "qiraahDuelATag",
        "qiraahDuelBTag", "qiraahDuelMode", "qiraahSmartComparison", "qiraatComparisonMode",
        "qiraatExplorerDuelA", "qiraatExplorerDuelB", "qiraatExplorerEveryDifference",
        "qiraatExplorerFontSize", "qiraatExplorerOnlyDifferences", "qiraatExplorerRiwayah",
        "quran.surahInfo.source", "quran.tafsir.author", "quranArabicScriptStyle", "quranGridMode",
        "quranPageMode", "quranPlannerReminderEnabled", "quranPlannerReminderMinutes",
        "quranSearchFilterPreferences", "quranSearchHelpCollapsed", "quranSortDirection", "quranSortMode",
        "quranicSukoonInLetterPractice", "readerLegendPage", "reciteType", "reciter", "reciterId",
        "removeArabicDots", "riwayahTajweedHiddenRules", "saveLastListenedAyah", "saveLastListenedSurah",
        "saveLastReadAyah", "searchForSurahs", "shareArabicFont", "shareAyahBackdrop",
        "shareAyahLastActionMode", "shareHadithArabic", "shareHadithEnglish", "shareHadithFontFace",
        "shareHadithHideTashkeel", "shareHadithIncludeNote", "shareHadithLastActionMode",
        "shareHadithReference", "shareIncludeRiwayah", "shareShowAyahInformation",
        "shareShowSurahInformation", "shortAdhanAsr", "shortAdhanDhuhr", "shortAdhanFajr", "shortAdhanIsha",
        "shortAdhanMaghrib", "showAccentGlow", "showArabicText", "showAyahOfTheDay", "showBookmarks",
        "showDescription", "showDuha", "showEnglishMustafa", "showEnglishSaheeh", "showFavoriteLetters",
        "showFavoriteNames", "showFavorites", "showFullSurahRow", "showHadithArabic", "showHadithBookmarks",
        "showHadithEnglish", "showHadithFavoriteBooks", "showHadithOfTheDay", "showIslamFavorites", "showIslamicMidnight",
        "showLastThird", "showMuqattaatHelper", "showOtherQiraatReciters", "showPageJuzDividers",
        "showPrayerInfo", "showSkyScene", "showSkyView", "showTajweedBareNuunMeem", "showTajweedColors",
        "showTajweedGeneralGhunnah", "showTajweedHamzatWaslSilent", "showTajweedIdghamBiGhunnahHeavy",
        "showTajweedIdghamBilaGhunnah", "showTajweedIkhfaa", "showTajweedIqlab", "showTajweedLamShamsiyah",
        "showTajweedMadd246", "showTajweedMaddConnected", "showTajweedMaddNatural2",
        "showTajweedMaddNaturalMiniature", "showTajweedMaddNecessary6", "showTajweedMaddSeparated",
        "showTajweedQalqalah", "showTajweedSukoonJazm", "showTajweedTafkhim", "showTransliteration",
        "showWordOfTheDay", "skyGradients", "skySceneStyle", "splitMurattalRecitersByGroup", "startHereHidden",
        "startHereVisited", "sunnahReminders", "switchHijriDateAtMaghrib", "tajweedCompareGrouping",
        "tajweedCustomColors", "tasbihFreeCycle", "trackerRequiresPrayerTime", "travelAutomatic",
        "travelingShowFullPrayers", "useFontArabic", "userBackground", "wordByWordInline",
        "wordByWordInlineTranslation", "wordByWordInlineTransliteration", "wordByWordMeanings",
        "zakahNisabBasis", "zakahYearBasis",
    ]

    /// Preferences that live ONLY in the app group (the widgets read them there): the `backedUp`
    /// rows of `Settings.appGroupPreferences` (all but `travelingMode`, which is location-derived).
    /// Captured only when chosen (`Settings.explicitlySetKeys`), written to the group store on a
    /// Replace, then assigned through their setters (`Settings.storedContentWasReplaced`).
    static let appGroupPreferenceKeys: [String] = Settings.appGroupPreferences.filter(\.backedUp).map(\.key)

    /// The Documents files that are the user's. Carried as opaque bytes: the journal is written by
    /// a plain `JSONEncoder` and most of the app by `Settings.encoder`, and a backup that never
    /// decodes either cannot damage either date format.
    static var files: [String] { Settings.contentDocumentFiles }

    /// Never backed up. Location first: the permission prompt promises "your location stays on your
    /// device", so nothing derived from it leaves, the saved home city and favorite locations
    /// included. Then what describes THIS install rather than the person: prompts already shown,
    /// migrations already run, what was last scheduled, what was last drawn.
    static let deviceOnlyKeys: [String] = [
        // Location, and everything computed from it (standard defaults and the app group).
        "currentLocation", "homeLocationData", "favoriteLocations", "prayersData", "currentPrayerData",
        "nextPrayerData", "currentCountryCode", "lastLocationFixAt", "cityAnchorLatitude", "cityAnchorLongitude",
        "travelingMode", "travelTurnOffAutomatic", "travelTurnOnAutomatic",
        "calculationAutoAnsweredCountryCode", "calculationAutoAnsweredMethod", "calculationAutoChanged",
        "calculationAutoDetectedCountryCode", "calculationAutoDetectedMethod", "calculationAutoPreviousMethod",
        // Onboarding and permission prompts this install has already been through.
        "THEfirstLaunch", "aboutYouVersionSeen",
        "locationNeverAskAgain", "notificationNeverAskAgain", "showLocationAlert", "showNotificationAlert",
        // Migrations and one-time seeds.
        "appGroupMirrorsSeeded.v1", "settings.explicitlySetKeys", "settings.didSeedExplicitKeys",
        "didAdoptMinshawiAdhanDefault", "ReciterDownloadManagerDedupeVersion", "hadithLastRead", "groupBySurah",
        // What was last scheduled, played or drawn here.
        "lastCalculationNotificationAt", "lastTravelingNotificationAt", "lastScheduledHijriYear",
        "extraRemindersArmedSignature", "foregroundAdhanLastPlayedMoment", "adhanClipStamps",
        "dailyWidgetsWrittenDay", "quranWidgetSnapshot", "dailyWidgetSnapshot", "mushaf.lastPageGeometry",
        // The page reader's learned fold and find-bar band pairs: this screen's geometry, like the one above.
        "mushaf.foldTwins", "mushaf.findTwins",
        // More of the same, found by `-cloudKeyAudit` in a live domain (2026-09-21): the source scan
        // cannot see a key declared as `let flag = "..."` or passed as an argument. The locator
        // caches are LOCATION (the masjids and halal places around the home city).
        "halalLocatorHomeCacheData", "masjidLocatorHomeCacheData",
        "didPurgeLegacyQuranCaches", "hadithBookCorporaPurged1", "hadithCitationRefresh1",
        "hadithLegacyCachePurged", "tafsirLegacyCachePurged",
        "appReviewAskDates", "appReviewSessionCount", "timeSpent",
        // Retired keys an older build left in the domain; nothing reads them now.
        "foregroundAdhanLastPlayedID", "gridMode", "islamGridMode", "namesGridMode",
        // Today's picks: tomorrow they are wrong anyway.
        "hijriDate", "ayahOfTheDayHiddenDate", "ayahOfTheDayOverride", "hadithOfTheDayHiddenDate", "hadithOfTheDayOverride", "hadithOfTheDayResolved",
    ]

    /// Whole families that are device-only: the watch sync's bookkeeping, and the backup's own.
    static let deviceOnlyPrefixes: [String] = ["watchSync.", "cloudBackup."]

    // MARK: Lookups

    static let contentKeySet = Set(Settings.contentStorageKeys)
    static let preferenceKeySet = Set(preferenceKeys)
    static let deviceOnlyKeySet = Set(deviceOnlyKeys)

    /// Whether any list names the key. Apple's own keys in the domain (`Apple…`, `NS…`, `com.apple.…`,
    /// `AK…`, `PK…`, `WebKit…`, `INNext…`) are not the app's to classify.
    static func isClassified(_ key: String) -> Bool {
        contentKeySet.contains(key) || preferenceKeySet.contains(key) || deviceOnlyKeySet.contains(key)
            || appGroupPreferenceKeys.contains(key)
            || deviceOnlyPrefixes.contains(where: key.hasPrefix)
    }

    static func isSystemKey(_ key: String) -> Bool {
        ["Apple", "NS", "com.apple.", "AK", "PK", "WebKit", "INNext", "MSV", "MultiPath", "METAL", "CK", "UIKit"]
            .contains(where: key.hasPrefix)
    }
}
#endif
