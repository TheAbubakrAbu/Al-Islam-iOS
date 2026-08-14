import SwiftUI
import CoreLocation
import WidgetKit
import Combine
import os

import Adhan

// DOMAIN MAP FOR THE COMPANION APPS (Al-Adhan / Al-Quran / Al-Hadith): the sections of this class
// are labelled with the app domain that owns them - see the [Al-Adhan] / [Al-Quran] / [Al-Hadith] /
// [Islam tab] / [Shared] MARK prefixes. When this file is copied into a companion app, delete the
// sections for domains it doesn't ship and keep every [Shared] one. The top of the class (init,
// app-group plumbing, accent/appearance) is [Shared]. The domain-specific extensions live in their
// own files already: SettingsAdhan.swift is wholly Al-Adhan, SettingsQuran.swift wholly Al-Quran.

let logger = Logger(subsystem: AppIdentifiers.bundleIdentifier, category: "Settings")

/// The single source of truth for all user settings.
///
/// **Why everything lives in this one file:** `@AppStorage` / `@Published` are stored property wrappers, and
/// Swift only allows stored properties in a type's primary declaration - never in an extension. So the
/// settings themselves can't be physically moved into separate Quran/Adhan files; the *behavior* that uses
/// them is what's split out, into `SettingsAdhan.swift` (prayer times, notifications, location) and
/// `SettingsQuran.swift` (reciters, bookmarks, khatm, …).
///
/// The declarations below are grouped, in order, into the four buckets:
///   1. **App Group** - `@Published`, mirrored into `appGroupUserDefaults` so widgets/extensions see them.
///   2. **App Storage - Adhan/Prayer** - `@AppStorage` prayer state, notifications, travel, calculation.
///   3. **App Storage - Quran** - `@AppStorage` reciter, favorites, sajdah/muqatta'at, bookmarks, khatm.
///   4. **App Storage - Arabic/Names + appearance/misc** - fonts, themes, haptics, color scheme.
/// Keep new settings in the matching section (and storage mechanism) so the split stays clean.
final class Settings: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = Settings()
    // Internal (not private): the per-domain extension files (SettingsQuran and friends) mirror their
    // typed accessors into the App Group suite for widgets/Siri, same as the members below do.
    let appGroupUserDefaults = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)
    @Published private(set) var isReadyForUI = false

    /// Decoded `prayers` cache so the `prayers` computed property doesn't re-run a full JSON decode on every
    /// read (it's read several times per `fetchPrayerTimes`, which itself runs multiple times at launch).
    /// Main-thread only - invalidated whenever `prayersData` changes; off-main reads decode directly to avoid
    /// racing the cache. See the `prayers` accessor below.
    private var cachedPrayers: Prayers?
    private var cachedPrayersValid = false

    /// Trailing-debounce work items so the launch burst of `fetchPrayerTimes` calls (onAppear + location
    /// callback + onChange + watch sync) collapses to a single notification reschedule / widget reload,
    /// off the synchronous first-paint path. Only used for callers that pass no completion (see
    /// `scheduleNotifications(deferred:)`); the background-refresh task path stays synchronous.
    /// (Not `private` because the coalescing helpers live in the `SettingsAdhan` extension, another file.)
    var pendingNotificationScheduleWorkItem: DispatchWorkItem?
    var pendingWidgetReloadWorkItem: DispatchWorkItem?

    static let encoder: JSONEncoder = {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .millisecondsSince1970
        return enc
    }()

    static let decoder: JSONDecoder = {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .millisecondsSince1970
        return dec
    }()

    private override init() {
        let storedAccent = AccentColor(rawValue: appGroupUserDefaults?.string(forKey: "accentColor") ?? AppIdentifiers.mainColorString) ?? AppIdentifiers.mainColor
        self.accentColor = storedAccent
        self.customAccentColorHex = appGroupUserDefaults?.string(forKey: "customAccentColorHex") ?? "34C759"
        self.customBackgroundColorHex = appGroupUserDefaults?.string(forKey: "customBackgroundColorHex") ?? "1C1C1E"

        // The Al-Islam glow defaults ON, but only makes sense on the DEFAULT accent. An existing
        // install that already moved to another accent gets no accent-CHANGE event to auto-disable
        // it (see `accentColor.didSet`), so the very first launch with no stored choice seeds it
        // off for them - exactly what the didSet would have done had this shipped earlier.
        if UserDefaults.standard.object(forKey: "alIslamGlow") == nil,
           storedAccent != AppIdentifiers.mainColor {
            UserDefaults.standard.set(false, forKey: "alIslamGlow")
        }

        self.prayersData = appGroupUserDefaults?.data(forKey: "prayersData") ?? Data()
        self.travelingMode = appGroupUserDefaults?.bool(forKey: "travelingMode") ?? false
        self.hanafiMadhab = appGroupUserDefaults?.bool(forKey: "hanafiMadhab") ?? false
        self.prayerCalculation = appGroupUserDefaults?.string(forKey: "prayerCalculation") ?? "Muslim World League"
        self.hijriOffset = appGroupUserDefaults?.integer(forKey: "hijriOffset") ?? 0
        self.highLatitudeRule = appGroupUserDefaults?.string(forKey: "highLatitudeRule") ?? Settings.automaticHighLatitudeRule
        self.customPrayerNames = (appGroupUserDefaults?.dictionary(forKey: "customPrayerNames") as? [String: String]) ?? [:]

        if let locationData = appGroupUserDefaults?.data(forKey: "currentLocation") {
            do {
                let location = try Self.decoder.decode(Location.self, from: locationData)
                currentLocation = location
            } catch {
                logger.debug("Failed to decode location: \(error)")
            }
        }

        if let homeLocationData = appGroupUserDefaults?.data(forKey: "homeLocationData") {
            do {
                let homeLocation = try Self.decoder.decode(Location.self, from: homeLocationData)
                self.homeLocation = homeLocation
            } catch {
                logger.debug("Failed to decode home location: \(error)")
            }
        }
        
        if let favoriteLocationsData = appGroupUserDefaults?.data(forKey: "favoriteLocations") {
            do {
                let locations = try Self.decoder.decode([Location].self, from: favoriteLocationsData)
                self.favoriteLocations = locations
            } catch {
                logger.debug("Failed to decode favorite locations: \(error)")
            }
        }

        super.init()
        loadKhatmProgressCacheFromStorage()
        Self.locationManager.delegate = self

        #if DEBUG
        // Headless riwayah forcing for simulator verification: `-displayQiraah <tag>` seeds the
        // riwayah + beta unlock BEFORE anything derives from them. Raw UserDefaults writes on
        // purpose - property didSets must not fire during init, and `simctl spawn defaults write`
        // races cfprefsd on freshly-installed containers.
        if let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-displayQiraah"),
           ProcessInfo.processInfo.arguments.indices.contains(idx + 1) {
            UserDefaults.standard.set(true, forKey: "betaQiraatEnabled")
            UserDefaults.standard.set(true, forKey: "acceptedBetaQiraatNotice")
            UserDefaults.standard.set(true, forKey: "showOtherQiraatReciters")
            UserDefaults.standard.set(ProcessInfo.processInfo.arguments[idx + 1], forKey: "displayQiraah")
        }
        if ProcessInfo.processInfo.arguments.contains("-quranPageMode") {
            UserDefaults.standard.set(true, forKey: "quranPageMode")
            UserDefaults.standard.set(112, forKey: "lastReadSurah")
            UserDefaults.standard.set(1, forKey: "lastReadAyah")
        }
        // The counterpart, for verifying the LIST reader headlessly: `simctl spawn defaults write
        // quranPageMode -bool NO` reads back as 0 but the app still opens the page reader (cfprefsd serves
        // its cached copy), so turning page mode OFF needed a launch argument of its own. Seeds the same
        // last-read position, so the reader lands somewhere rather than at the surah list.
        if ProcessInfo.processInfo.arguments.contains("-quranListMode") {
            UserDefaults.standard.set(false, forKey: "quranPageMode")
            UserDefaults.standard.set(112, forKey: "lastReadSurah")
            UserDefaults.standard.set(1, forKey: "lastReadAyah")
        }
        // "-lastRead 2:29" - open the reader at that position. Manual `simctl spawn defaults write`
        // can't do this (cfprefsd serves the app its cached copy), so verifying a SPECIFIC ayah's
        // rendering headlessly needs the seed to happen in-process. Placed after -quranPageMode /
        // -quranListMode so it overrides their 112:1 seed when combined.
        if let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-lastRead"),
           idx + 1 < ProcessInfo.processInfo.arguments.count {
            let parts = ProcessInfo.processInfo.arguments[idx + 1].split(separator: ":")
            if parts.count == 2, let s = Int(parts[0]), let a = Int(parts[1]) {
                UserDefaults.standard.set(s, forKey: "lastReadSurah")
                UserDefaults.standard.set(a, forKey: "lastReadAyah")
            }
        }
        if ProcessInfo.processInfo.arguments.contains("-qiraatComparisonMode") {
            UserDefaults.standard.set(true, forKey: "qiraatComparisonMode")
        }
        // Same headless-verification pattern for the facsimile: `-mushafPageLanguage pdf` puts page
        // mode on the printed mushaf, `-mushafPDFAppearance light|night|auto` pins its lighting.
        if let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-mushafPageLanguage"),
           ProcessInfo.processInfo.arguments.indices.contains(idx + 1) {
            UserDefaults.standard.set(ProcessInfo.processInfo.arguments[idx + 1], forKey: "mushafPageLanguage")
        }
        if let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-mushafPDFAppearance"),
           ProcessInfo.processInfo.arguments.indices.contains(idx + 1) {
            UserDefaults.standard.set(ProcessInfo.processInfo.arguments[idx + 1], forKey: "mushafPDFAppearance")
        }
        // "-hijriOffset 2" - seed the Hijri date adjustment headlessly. `simctl spawn defaults write
        // group.com.IslamicPillars.AppGroup ...` lands in the simulator-global prefs file, NOT the
        // app's shared container, so the app never sees it - the seed has to happen in-process.
        // Direct ivar assignment: didSet must not fire during init; `updateDates()` runs later in
        // this init and picks the value up.
        if let idx = ProcessInfo.processInfo.arguments.firstIndex(of: "-hijriOffset"),
           ProcessInfo.processInfo.arguments.indices.contains(idx + 1),
           let forcedOffset = Int(ProcessInfo.processInfo.arguments[idx + 1]) {
            self.hijriOffset = forcedOffset
        }
        #endif

        runQuranStartupMigrations()
        runAdhanSoundStartupMigrations()
        runWatchSyncKeyMigration()

        // Hadith Allah-highlighting used to follow the Quran toggle; when the setting split in two,
        // seed the new key from the old one so nothing visibly changes until the user flips it.
        if UserDefaults.standard.object(forKey: "highlightAllahNamesHadith") == nil {
            UserDefaults.standard.set(UserDefaults.standard.bool(forKey: "highlightAllahNames"),
                                      forKey: "highlightAllahNamesHadith")
        }
        isReadyForUI = true

        // Defer CoreLocation + NWPathMonitor startup off the synchronous init/first-paint path. Settings.shared
        // is created during @main's @StateObject init, before the first frame; kicking off authorization,
        // significant-location monitoring, and a location request right there competes with first paint (and,
        // on first launch, throws the permission dialog up before the UI is even visible). The stored
        // currentLocation (decoded above) is enough for the launch fetch; this refreshes it a tick later.
        if Self.isAppProcess {
            // One-time seed of the switchHijriDateAtMaghrib mirror (see its didSet): users who enabled the
            // toggle before the mirror existed would otherwise stay wrong in widgets until they re-toggled.
            appGroupUserDefaults?.setValue(switchHijriDateAtMaghrib, forKey: "switchHijriDateAtMaghrib")
            // Same seed for the sky palette (see skyGradientsJSON's didSet): palettes customized before
            // the mirror existed would otherwise never reach the gradient widget until re-edited.
            appGroupUserDefaults?.setValue(skyGradientsJSON, forKey: "skyGradients")
            // Same seed for the manual prayer offsets (see mirrorOffsetToAppGroup): offsets set before
            // the mirror existed would otherwise stay wrong in widgets until the user re-adjusted them.
            for key in Self.prayerOffsetKeys {
                mirrorOffsetToAppGroup(UserDefaults.standard.integer(forKey: key), key: key)
            }

            // Widgets read the app-group location; they must not touch CoreLocation authorization.
            DispatchQueue.main.async { [weak self] in
                self?.requestLocationAuthorization()
            }
        }
    }

    func waitUntilReady() async {
        while true {
            let isReady = await MainActor.run { self.isReadyForUI }
            if isReady { return }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
    
    /// Reload widget timelines, coalescing the launch burst the same way as `scheduleNotifications`.
    func reloadWidgets(deferred: Bool) {
        // See `scheduleNotifications`: a widget must not reload widget timelines - that is a self-reload loop.
        guard Settings.isAppProcess else { return }
        pendingWidgetReloadWorkItem?.cancel()
        pendingWidgetReloadWorkItem = nil
        guard deferred else {
            WidgetCenter.shared.reloadAllTimelines()
            return
        }
        let work = DispatchWorkItem { [weak self] in
            self?.pendingWidgetReloadWorkItem = nil
            WidgetCenter.shared.reloadAllTimelines()
        }
        pendingWidgetReloadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    /// Restores every *preference* (appearance, prayer, and Quran options) to its default while keeping the
    /// user's content. We wipe the app's standard-defaults domain - which clears all the `@AppStorage`
    /// preferences in one shot - but first snapshot the content keys and write them back afterward, then
    /// reset the app-group-backed `@Published` preferences (accent, calculation, madhab, traveling, Hijri
    /// offset) to their defaults via their setters so the shared store + widgets update too. Location and
    /// other app-group content are left untouched.
    @MainActor
    func resetAllSettings(keepingContent: Bool = true) {
        // Bookmarks, favorites, khatm progress, saved reading/listening positions, and search history are
        // content, not settings - preserved across the domain wipe unless the user asked to erase everything.
        let contentKeys = [
            "favoriteSurahsData", "bookmarkedAyahsData", "favoriteLetterData", "favoriteNameNumbersData",
            "khatmCompletedAyahsData", "quranPlanData", "favoriteReciterIDsData", "favoriteQiraahTagsData",
            "favoriteEnglishTranslationIDsData", "savedSajdahAyahIDsData", "savedBrokenLetterAyahIDsData",
            "lastReadSurah", "lastReadAyah", "lastReadTimestamp", "lastListenedAyahData", "lastListenedSurahData",
            "quranSearchHistoryData",
            // The prayer tracker and menses-pause record: months of marks and exempt days - the most
            // clearly "the user's, not a preference" data in the app.
            "prayerTrackerData", "prayerTrackerExemptDaysData", "mensesPauseActive", "mensesPauseStartStamp",
            // Hadith content: marks, favorites, reading positions, search history, daily-hadith history.
            "hadithFavoriteBooks", "hadithFavoriteChapters", "hadithBookmarks",
            "hadithLastReadByBook", "hadithSearchHistoryData", "hadithOfTheDayHistory", "hadithBookCounts",
            // Tally counts (and the free counter's custom label, which is the user's own text).
            "tasbihFreeCount", "tasbihPresetCounts", "tasbihFreeLabel",
            // Only wiped by a full erase: these are stats/history rather than saved items, but they're still
            // the user's, not preferences.
            "surahOpenCountsData", "surahPlayCountsData",
        ]

        let standard = UserDefaults.standard
        let preserved = keepingContent
            ? contentKeys.reduce(into: [String: Any]()) { dict, key in
                if let value = standard.object(forKey: key) { dict[key] = value }
            }
            : [:]

        if let bundleID = Bundle.main.bundleIdentifier {
            standard.removePersistentDomain(forName: bundleID)
        }

        for (key, value) in preserved {
            standard.set(value, forKey: key)
        }

        // A full erase also clears the shared app-group store - the saved location, the cached prayer times,
        // the widgets' copy of everything, and the one-shot migration flags. That's what makes it equivalent to
        // deleting and reinstalling the app, rather than just to clearing this process's defaults.
        if !keepingContent {
            appGroupUserDefaults?.removePersistentDomain(forName: AppIdentifiers.appGroupSuiteName)
            explicitlySetKeys.removeAll()
            homeLocation = nil
            currentLocation = nil
            favoriteLocations = []
            prayers = nil
        }

        // App-group preferences are mirrored by these @Published properties; reassigning to the defaults
        // re-persists them through each didSet. (Mirrors the init defaults.)
        accentColor = AppIdentifiers.mainColor
        customAccentColorHex = "34C759"
        customBackgroundColorHex = "1C1C1E"
        travelingMode = false
        hanafiMadhab = false
        prayerCalculation = "Muslim World League"
        hijriOffset = 0
        customPrayerNames = [:]
        highLatitudeRule = "Automatic"

        // The domain wipe changed the data underneath every in-memory cache. The memo-style caches
        // (favorites, bookmarks, sky palette) self-heal because they key on the stored bytes; these
        // presence-checked ones kept serving the erased values until a cold launch.
        loadKhatmProgressCacheFromStorage()
        Self.invalidateTrackerCaches()
        Self.invalidatePrayerComputationCache()

        objectWillChange.send()
        updateDates()
        fetchPrayerTimes(force: true)
        #if os(iOS) || os(watchOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    // MARK: - [Shared] App group - shared with widgets / extensions

    /// True in the iPhone app and the Watch app; false in every app extension.
    ///
    /// Extensions build a throwaway `Settings` and assign into it to render from the app group - see
    /// `PrayersProvider.makeEntry()`. They must never write back. The old test for this was
    /// `bundleIdentifier.contains("Widget")`, which silently missed the watch complication
    /// (`…watchkitapp.complication1`), letting that process persist its *fallback defaults* over the user's
    /// real values. Bundle layout, not naming, decides this: every extension lives in a `.appex`.
    static let isAppProcess = Bundle.main.bundleURL.pathExtension != "appex"

    /// The app-group keys holding a value the user (or an applied sync) actually chose, as opposed to one
    /// that merely sits at its default. `watchSyncSnapshot()` transmits only these, so a device that has
    /// never been configured cannot broadcast its defaults over an established peer.
    ///
    /// A plain `object(forKey:) != nil` check used to stand in for this, and it was wrong: any process that
    /// assigned a default created the key, and the default then looked chosen.
    private static let explicitKeysDefaultsKey = "settings.explicitlySetKeys"

    private(set) lazy var explicitlySetKeys: Set<String> =
        Set(appGroupUserDefaults?.stringArray(forKey: Self.explicitKeysDefaultsKey) ?? [])

    private func markExplicitlySet(_ key: String) {
        guard Self.isAppProcess, !explicitlySetKeys.contains(key) else { return }
        explicitlySetKeys.insert(key)
        appGroupUserDefaults?.set(Array(explicitlySetKeys), forKey: Self.explicitKeysDefaultsKey)
    }

    /// Backfills `explicitlySetKeys` once, and only on the iPhone.
    ///
    /// The iPhone's app group was never written by an extension (the iOS widget's bundle ID *did* contain
    /// "Widget", so the old guard held there), so every key present in it is a real choice and can be seeded.
    /// The watch's app group was polluted by the complication, so it is deliberately left to start empty:
    /// the watch will re-mark each key the moment it applies a snapshot or the user changes it there.
    ///
    /// Clearing the sync digest makes the phone re-push its true configuration on the next WC activation,
    /// with a fresh timestamp - which is what pulls a watch that has been broadcasting green back in line.
    private func runWatchSyncKeyMigration() {
        #if os(iOS)
        let migrationKey = "settings.didSeedExplicitKeys"
        guard Self.isAppProcess,
              let appGroup = appGroupUserDefaults,
              !appGroup.bool(forKey: migrationKey) else { return }

        let syncedAppGroupKeys = [
            "accentColor", "customAccentColorHex", "customBackgroundColorHex", "prayerCalculation",
            "hanafiMadhab", "travelingMode", "hijriOffset", "highLatitudeRule", "customPrayerNames",
        ]
        explicitlySetKeys.formUnion(syncedAppGroupKeys.filter { appGroup.object(forKey: $0) != nil })
        appGroup.set(Array(explicitlySetKeys), forKey: Self.explicitKeysDefaultsKey)
        appGroup.removeObject(forKey: "watchSync.lastSyncedSettingsData")
        appGroup.set(true, forKey: migrationKey)
        #endif
    }

    @Published var accentColor: AccentColor {
        didSet {
            guard Self.isAppProcess else { return }
            appGroupUserDefaults?.setValue(accentColor.rawValue, forKey: "accentColor")
            markExplicitlySet("accentColor")
            // The Al-Islam glow rides the DEFAULT accent: it's on out of the box, but the moment the
            // user picks any other accent it switches off so the glow follows their color instead of
            // clashing with it. One-way only - coming back to the default never re-enables it; that
            // takes the Appearance toggle. (Compared against `AppIdentifiers.mainColor`, not a
            // hardcoded green: companion apps ship different default accents.)
            if oldValue == AppIdentifiers.mainColor, accentColor != AppIdentifiers.mainColor {
                alIslamGlow = false
            }
            // Every widget renders in the accent, so a change must repaint them. Owned here (not an
            // `.onChange` at the app root) so every write path - the pickers, a synced snapshot, a
            // settings reset - repaints without each caller remembering to. Deferred so a burst of
            // writes (reset, sync apply) coalesces into one reload against WidgetKit's daily budget.
            reloadWidgets(deferred: true)
        }
    }

    /// Hex ("RRGGBB") backing `AccentColor.custom`'s primary stop, set via the Appearance color picker.
    @Published var customAccentColorHex: String {
        didSet {
            guard Self.isAppProcess else { return }
            appGroupUserDefaults?.setValue(customAccentColorHex, forKey: "customAccentColorHex")
            markExplicitlySet("customAccentColorHex")
        }
    }

    /// Hex ("RRGGBB") of the user-picked app background, used when the "custom" color theme is active. Kept
    /// `@Published` (not `@AppStorage`) so dragging the color picker updates the background live everywhere.
    @Published var customBackgroundColorHex: String {
        didSet {
            guard Self.isAppProcess else { return }
            appGroupUserDefaults?.setValue(customBackgroundColorHex, forKey: "customBackgroundColorHex")
            markExplicitlySet("customBackgroundColorHex")
        }
    }


    @Published var prayersData: Data {
        didSet {
            cachedPrayersValid = false   // backing bytes changed - drop the decoded cache
            guard Self.isAppProcess else { return }
            if !prayersData.isEmpty {
                appGroupUserDefaults?.setValue(prayersData, forKey: "prayersData")
            }
        }
    }

    var prayers: Prayers? {
        get {
            // Off the main thread (e.g. a background-refresh decode), don't touch the shared cache - just
            // decode locally. On main, decode once and reuse until `prayersData` changes.
            guard Thread.isMainThread else {
                return try? Self.decoder.decode(Prayers.self, from: prayersData)
            }
            if cachedPrayersValid { return cachedPrayers }
            let decoded = try? Self.decoder.decode(Prayers.self, from: prayersData)
            cachedPrayers = decoded
            cachedPrayersValid = true
            return decoded
        }
        set {
            // Encode/persist first (its didSet invalidates the cache), then prime the cache with the value we
            // just wrote so the very next read doesn't have to decode it straight back.
            prayersData = (try? Self.encoder.encode(newValue)) ?? Data()
            if Thread.isMainThread {
                cachedPrayers = newValue
                cachedPrayersValid = true
            }
        }
    }

    @Published var travelingMode: Bool {
        didSet {
            guard Self.isAppProcess else { return }
            appGroupUserDefaults?.setValue(travelingMode, forKey: "travelingMode")
            markExplicitlySet("travelingMode")
        }
    }

    @Published var currentLocation: Location? {
        didSet {
            guard Self.isAppProcess else { return }
            guard let location = currentLocation else { return }
            do {
                let locationData = try Self.encoder.encode(location)
                appGroupUserDefaults?.setValue(locationData, forKey: "currentLocation")
            } catch {
                logger.debug("Failed to encode location: \(error)")
            }
        }
    }

    @Published var homeLocation: Location? {
        didSet {
            guard Self.isAppProcess else { return }
            guard let homeLocation = homeLocation else {
                appGroupUserDefaults?.removeObject(forKey: "homeLocationData")
                return
            }
            do {
                let homeLocationData = try Self.encoder.encode(homeLocation)
                appGroupUserDefaults?.set(homeLocationData, forKey: "homeLocationData")
            } catch {
                logger.debug("Failed to encode home location: \(error)")
            }
        }
    }

    @Published var favoriteLocations: [Location] = [] {
        didSet {
            guard Self.isAppProcess else { return }
            do {
                let favoriteLocationsData = try Self.encoder.encode(favoriteLocations)
                appGroupUserDefaults?.set(favoriteLocationsData, forKey: "favoriteLocations")
            } catch {
                logger.debug("Failed to encode favorite locations: \(error)")
            }
        }
    }

    @Published var hanafiMadhab: Bool {
        didSet {
            guard Self.isAppProcess else { return }
            appGroupUserDefaults?.setValue(hanafiMadhab, forKey: "hanafiMadhab")
            // The madhab changes Asr's TIME (it's part of the computation cache key), so a flip must
            // recompute now - without this, times/notifications/widgets kept the old Asr until the next
            // unrelated fetch. `runAutoChecks: false` because this didSet also fires inside the
            // watch-sync APPLY (which assigns through real setters and is engineered to do exactly one
            // recompute with auto-checks off at the end) - letting auto-detection run mid-apply could
            // flip the calculation/traveling settings the snapshot is in the middle of delivering.
            fetchPrayerTimes(force: true, runAutoChecks: false)
            markExplicitlySet("hanafiMadhab")
        }
    }

    @Published var prayerCalculation: String {
        didSet {
            guard Self.isAppProcess else { return }
            appGroupUserDefaults?.setValue(prayerCalculation, forKey: "prayerCalculation")
            markExplicitlySet("prayerCalculation")
        }
    }

    @Published var hijriOffset: Int {
        didSet {
            guard Self.isAppProcess else { return }
            appGroupUserDefaults?.setValue(hijriOffset, forKey: "hijriOffset")
            markExplicitlySet("hijriOffset")
            // The offset shifts the displayed Hijri date everywhere it appears, so recompute it and
            // repaint the widgets that show it. Owned here for the same reason as `accentColor`'s.
            updateDates()
            // Prayer times and reminders consult the ADJUSTED calendar too (the Umm al-Qura Ramadan
            // Isha extension, and the Islamic-event notifications' Gregorian day), so a forced fetch
            // recomputes and reschedules under the new offset.
            fetchPrayerTimes(force: true, runAutoChecks: false)
            reloadWidgets(deferred: true)
        }
    }

    /// How Fajr and Isha are approximated where the sun never dips far enough below the horizon for the
    /// twilight angles to occur. `"Automatic"` defers to the Adhan library's latitude-based recommendation.
    @Published var highLatitudeRule: String {
        didSet {
            guard Self.isAppProcess else { return }
            appGroupUserDefaults?.setValue(highLatitudeRule, forKey: "highLatitudeRule")
            Settings.invalidatePrayerComputationCache()
            fetchPrayerTimes(force: true)
            markExplicitlySet("highLatitudeRule")
        }
    }

    /// User spellings for prayer names, keyed by the canonical transliteration ("Fajr" → "Fadjr"). Only the
    /// *display* name changes; the transliteration remains the key everywhere the app looks a prayer up.
    /// Lives in the app group so widgets and the Watch render the same names.
    @Published var customPrayerNames: [String: String] {
        didSet {
            guard Self.isAppProcess else { return }
            appGroupUserDefaults?.setValue(customPrayerNames, forKey: "customPrayerNames")
            Settings.invalidatePrayerComputationCache()
            fetchPrayerTimes(force: true)
            markExplicitlySet("customPrayerNames")
        }
    }

    // MARK: - [Al-Adhan] Prayer tracker

    /// Which prayers were marked prayed, per civil day: encoded `[String: [String]]` keyed by
    /// "yyyy-MM-dd", values are prayer transliterations. Helpers live in SettingsAdhan.swift.
    @AppStorage("prayerTrackerData") var prayerTrackerData: Data = Data()

    /// Days the tracker treats as EXEMPT (menstruation/postnatal): encoded `[String]` of "yyyy-MM-dd"
    /// keys. Exempt days don't count against streaks or completion - prayer is not obligatory then and
    /// is not made up later. Helpers live in SettingsAdhan.swift.
    @AppStorage("prayerTrackerExemptDaysData") var trackerExemptDaysData: Data = Data()

    /// The menses pause switch. While on, every day (from `mensesPauseStartStamp` forward) is exempt and
    /// nagging reminders stay silent; turning it off writes the finished range into the exempt-days set.
    /// Set through `setMensesPause` so the range bookkeeping and notification rebuild always happen.
    @AppStorage("mensesPauseActive") var mensesPauseActive: Bool = false
    @AppStorage("mensesPauseStartStamp") var mensesPauseStartStamp: Double = 0

    /// Set when a nagging notification is tapped: the prayer tab asks "Did you pray X?" and a yes
    /// marks the tracker and silences the rest of that cascade.
    struct PendingNagQuestion: Identifiable, Equatable {
        let id = UUID()
        /// The prayer being asked about (the one whose window is ending).
        let prayerName: String
        /// The upcoming prayer whose identifier the nag cascade is scheduled under.
        let cascadePrayerName: String
    }
    @Published var pendingNagQuestion: PendingNagQuestion?

    // MARK: - [Al-Adhan] Prayer - live state & hijri (app-storage persistence)

    @AppStorage("hijriDate") private var hijriDateData: String?
    var hijriDate: HijriDate? {
        get {
            guard let hijriDateData = hijriDateData,
                  let data = hijriDateData.data(using: .utf8) else {
                return nil
            }
            return try? Self.decoder.decode(HijriDate.self, from: data)
        }
        set {
            if let newValue = newValue {
                let encoded = try? Self.encoder.encode(newValue)
                hijriDateData = encoded.flatMap { String(data: $0, encoding: .utf8) }
            } else {
                hijriDateData = nil
            }
        }
    }

    @AppStorage("currentPrayerData") var currentPrayerData: Data?
    @Published var currentPrayer: Prayer? {
        didSet {
            currentPrayerData = try? Self.encoder.encode(currentPrayer)
        }
    }

    @AppStorage("nextPrayerData") var nextPrayerData: Data?
    @Published var nextPrayer: Prayer? {
        didSet {
            nextPrayerData = try? Self.encoder.encode(nextPrayer)
        }
    }

    @Published var datePrayers: [Prayer]?
    @Published var dateFullPrayers: [Prayer]?
    @Published var changedDate = false

    var hijriCalendar: Calendar = {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "ar")
        return calendar
    }()

    var specialEvents: [(String, DateComponents, String, String)] {
        // Offset-adjusted, like the displayed Hijri date: near Muharram 1 an offset user's "current
        // Hijri year" is the adjusted one, and taking the raw reference year put every event a year off.
        let effective = effectiveHijriReferenceDate()
        let adjusted = hijriCalendar.date(byAdding: .day, value: hijriOffset, to: effective) ?? effective
        let currentHijriYear = hijriCalendar.component(.year, from: adjusted)
        return [
            ("Islamic New Year", DateComponents(year: currentHijriYear, month: 1, day: 1), "Start of Hijri year", "The first day of the Islamic calendar; no special acts of worship or celebration are prescribed."),
            ("Day Before Ashura", DateComponents(year: currentHijriYear, month: 1, day: 9), "Recommended to fast", "The Prophet ﷺ intended to fast the 9th to differ from the Jews, making it Sunnah to do so before Ashura."),
            ("Day of Ashura", DateComponents(year: currentHijriYear, month: 1, day: 10), "Recommended to fast", "Ashura marks the day Allah saved Musa (Moses) and the Israelites from Pharaoh; fasting expiates sins of the previous year."),

            ("First Day of Ramadan", DateComponents(year: currentHijriYear, month: 9, day: 1), "Begin obligatory fast", "The month of fasting begins; all Muslims must fast from Fajr (dawn) to Maghrib (sunset)."),
            ("Last 10 Nights of Ramadan", DateComponents(year: currentHijriYear, month: 9, day: 21), "Seek Laylatul Qadr", "The most virtuous nights of the year; increase worship as these nights are beloved to Allah and contain Laylatul Qadr."),
            ("27th Night of Ramadan", DateComponents(year: currentHijriYear, month: 9, day: 27), "Likely Laylatul Qadr", "A strong possibility for Laylatul Qadr - the Night of Decree when the Qur’an was sent down - though not confirmed."),
            ("Eid Al-Fitr", DateComponents(year: currentHijriYear, month: 10, day: 1), "Celebration of ending the fast", "Celebration marking the end of Ramadan; fasting is prohibited on this day; encouraged to fast 6 days in Shawwal."),

            ("First 10 Days of Dhul-Hijjah", DateComponents(year: currentHijriYear, month: 12, day: 1), "Most beloved days", "The best days for righteous deeds; fasting the first nine days and dhikr are highly encouraged (the 10th is Eid al-Adha, on which fasting is not permitted)."),
            ("Beginning of Hajj", DateComponents(year: currentHijriYear, month: 12, day: 8), "Pilgrimage begins", "Pilgrims begin the rites of Hajj, heading to Mina to start the sacred journey."),
            ("Day of Arafah", DateComponents(year: currentHijriYear, month: 12, day: 9), "Recommended to fast", "Fasting for non-pilgrims expiates sins of the past and coming year."),
            ("Eid Al-Adha", DateComponents(year: currentHijriYear, month: 12, day: 10), "Celebration of sacrifice during Hajj", "The day of sacrifice; fasting is not allowed and sacrifice of an animal is offered."),
            ("End of Eid Al-Adha", DateComponents(year: currentHijriYear, month: 12, day: 13), "Hajj and Eid end", "Final day of Eid Al-Adha; pilgrims and non-pilgrims return to daily life."),
        ]
    }

    @AppStorage("lastScheduledHijriYear") private var lastScheduledHijriYear: Int = 0

    // MARK: - [Al-Adhan] Prayer - @AppStorage (notifications, travel, calculation, alerts)

    @AppStorage("dateNotifications") var dateNotifications = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }

    @AppStorage("switchHijriDateAtMaghrib") var switchHijriDateAtMaghrib: Bool = false {
        didSet {
            self.updateDates()
            // The Adhan widgets read this key from the App Group (PrayersProvider) to decide whether the
            // hijri date advances after Maghrib, but @AppStorage persists to standard defaults - without
            // this mirror every widget resolved it to false forever and showed the previous hijri day all
            // evening. (init seeds the mirror for values set before this fix shipped.)
            guard Self.isAppProcess else { return }
            appGroupUserDefaults?.setValue(switchHijriDateAtMaghrib, forKey: "switchHijriDateAtMaghrib")
        }
    }

    @AppStorage("naggingMode") var naggingMode: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingStartOffset") var naggingStartOffset: Int = 30 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("adhanNotificationSound") var adhanNotificationSound: String = Settings.defaultAdhanSoundID {
        didSet { self.fetchPrayerTimes(notification: true) }
    }

    // The tone for notifications that TELL rather than CALL: pre-alerts, the non-obligatory times, and any
    // prayer whose adhan is switched off. These used to be the iOS system sound, which is indistinguishable
    // from every other app's alert. Defaults to Echo - the bundled 3.6-second chime that exists for exactly
    // this purpose. "default" restores the old system sound for anyone who preferred it.
    @AppStorage("alertToneSound") var alertToneSound: String = Settings.defaultAlertToneID {
        didSet { self.fetchPrayerTimes(notification: true) }
    }

    // Per-prayer adhan length. iOS caps a notification sound at 30 seconds, so "full" means the 30-second cut
    // and "short" means a ~5-15s excerpt. Defaults to the full cut, which is what every existing user already
    // hears; opting a prayer down to the short clip is the new choice.
    @AppStorage("shortAdhanFajr") var shortAdhanFajr: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("shortAdhanDhuhr") var shortAdhanDhuhr: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("shortAdhanAsr") var shortAdhanAsr: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("shortAdhanMaghrib") var shortAdhanMaghrib: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("shortAdhanIsha") var shortAdhanIsha: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }

    // Whether a prayer's at-time notification plays the chosen adhan at all. Off means an ordinary
    // notification with the system sound - a plain alert for Dhuhr at work, the full adhan for Maghrib.
    // Independent of `notification*` (which silences the prayer entirely) and of `shortAdhan*` (which picks
    // the clip once you've decided you do want one).
    /// When true, the IN-APP adhan (the foreground player) uses a playback session that sounds even with
    /// the ringer switch on silent. Off by default: silent mode silences the in-app adhan like any app.
    @AppStorage("adhanOverridesSilentMode") var adhanOverridesSilentMode: Bool = false

    @AppStorage("adhanSoundFajr") var adhanSoundFajr: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("adhanSoundDhuhr") var adhanSoundDhuhr: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("adhanSoundAsr") var adhanSoundAsr: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("adhanSoundMaghrib") var adhanSoundMaghrib: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("adhanSoundIsha") var adhanSoundIsha: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }

    /// The sun arc, moon phase and starfield on the Adhan tab. Off falls back to the standalone
    /// Current/Upcoming countdown card, exactly as it looked before the two were merged.
    @AppStorage("showSkyView") var showSkyView: Bool = true

    /// JSON map of prayer → `[topHex, bottomHex]` for the Adhan tab's sky card. Empty means "all defaults".
    /// Read and written through the helpers in `SkyPalette.swift`. Mirrored to the app group because the
    /// gradient WIDGET renders through the same helpers - in the widget process, standard defaults are
    /// the widget's own (empty), so without the mirror a custom palette never reached the widget at all.
    /// (`resolvedSkyGradientsJSON` in SkyPalette.swift is the widget-side read.)
    @AppStorage("skyGradients") var skyGradientsJSON: String = "" {
        didSet {
            guard Self.isAppProcess else { return }
            appGroupUserDefaults?.setValue(skyGradientsJSON, forKey: "skyGradients")
        }
    }

    @AppStorage("preNotificationFajr") var preNotificationFajr: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationFajr") var notificationFajr: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingFajr") var naggingFajr: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    /// The six manual-offset keys, in prayer order. This list is the contract between three
    /// processes (app, widget extension, watch complication): the didSets mirror these into the
    /// App Group, the providers read them back, and the watch sync republishes them - all from
    /// this one list.
    static let prayerOffsetKeys = ["offsetFajr", "offsetSunrise", "offsetDhuhr", "offsetAsr", "offsetMaghrib", "offsetIsha"]

    /// The manual offsets are applied inside `_computeRawPrayers`, which the widget and complication
    /// providers re-run in their own processes (day rollover, boundary timelines) - so every offset
    /// must reach the App Group, or the extensions recompute with 0s and drift from the app: the
    /// reported "widget doesn't match the app after adjusting prayer times".
    func mirrorOffsetToAppGroup(_ value: Int, key: String) {
        guard Self.isAppProcess else { return }
        appGroupUserDefaults?.setValue(value, forKey: key)
    }

    @AppStorage("offsetFajr") var offsetFajr: Int = 0 {
        didSet {
            mirrorOffsetToAppGroup(offsetFajr, key: "offsetFajr")
            self.fetchPrayerTimes(force: true)
        }
    }

    @AppStorage("preNotificationSunrise") var preNotificationSunrise: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationSunrise") var notificationSunrise: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingSunrise") var naggingSunrise: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("offsetSunrise") var offsetSunrise: Int = 0 {
        didSet {
            mirrorOffsetToAppGroup(offsetSunrise, key: "offsetSunrise")
            self.fetchPrayerTimes(force: true)
        }
    }

    @AppStorage("preNotificationDhuhr") var preNotificationDhuhr: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationDhuhr") var notificationDhuhr: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingDhuhr") var naggingDhuhr: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("offsetDhuhr") var offsetDhuhr: Int = 0 {
        didSet {
            mirrorOffsetToAppGroup(offsetDhuhr, key: "offsetDhuhr")
            self.fetchPrayerTimes(force: true)
        }
    }

    @AppStorage("preNotificationAsr") var preNotificationAsr: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationAsr") var notificationAsr: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingAsr") var naggingAsr: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("offsetAsr") var offsetAsr: Int = 0 {
        didSet {
            mirrorOffsetToAppGroup(offsetAsr, key: "offsetAsr")
            self.fetchPrayerTimes(force: true)
        }
    }

    @AppStorage("preNotificationMaghrib") var preNotificationMaghrib: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationMaghrib") var notificationMaghrib: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingMaghrib") var naggingMaghrib: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("offsetMaghrib") var offsetMaghrib: Int = 0 {
        didSet {
            mirrorOffsetToAppGroup(offsetMaghrib, key: "offsetMaghrib")
            self.fetchPrayerTimes(force: true)
        }
    }

    @AppStorage("preNotificationIsha") var preNotificationIsha: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationIsha") var notificationIsha: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingIsha") var naggingIsha: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("offsetIsha") var offsetIsha: Int = 0 {
        didSet {
            mirrorOffsetToAppGroup(offsetIsha, key: "offsetIsha")
            self.fetchPrayerTimes(force: true)
        }
    }

    @AppStorage("preNotificationDuha") var preNotificationDuha: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationDuha") var notificationDuha: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingDuha") var naggingDuha: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }

    @AppStorage("preNotificationIslamicMidnight") var preNotificationIslamicMidnight: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationIslamicMidnight") var notificationIslamicMidnight: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingIslamicMidnight") var naggingIslamicMidnight: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }

    @AppStorage("preNotificationLastThird") var preNotificationLastThird: Int = 0 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("notificationLastThird") var notificationLastThird: Bool = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingLastThird") var naggingLastThird: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }

    @AppStorage("travelAutomatic") var travelAutomatic: Bool = true
    @AppStorage("travelTurnOffAutomatic") var travelTurnOffAutomatic: Bool = false
    @AppStorage("travelTurnOnAutomatic") var travelTurnOnAutomatic: Bool = false

    /// When the traveling-mode auto-toggle last announced itself. Persisted, so the cooldown survives a relaunch
    /// - the app is relaunched constantly in the background, and an in-memory timestamp would reset with it and
    /// let the notification through again. See `notifyTravelingModeChanged`.
    @AppStorage("lastTravelingNotificationAt") private var lastTravelingNotificationStamp: Double = 0
    var lastTravelingNotificationAt: Date? {
        get { lastTravelingNotificationStamp > 0 ? Date(timeIntervalSince1970: lastTravelingNotificationStamp) : nil }
        set { lastTravelingNotificationStamp = newValue?.timeIntervalSince1970 ?? 0 }
    }

    /// When the automatic-calculation switch last announced itself. Persisted for the same reason as
    /// `lastTravelingNotificationAt`: background relaunches would reset an in-memory stamp and let the
    /// notification repeat.
    @AppStorage("lastCalculationNotificationAt") private var lastCalculationNotificationStamp: Double = 0
    var lastCalculationNotificationAt: Date? {
        get { lastCalculationNotificationStamp > 0 ? Date(timeIntervalSince1970: lastCalculationNotificationStamp) : nil }
        set { lastCalculationNotificationStamp = newValue?.timeIntervalSince1970 ?? 0 }
    }

    /// The angles behind the "Custom Angles" calculation method. Changing either has to invalidate the prayer
    /// computation cache, which is keyed on the method LABEL - and the label doesn't change when only an angle
    /// does, so without this the times would keep coming back from the cache unchanged.
    @AppStorage("customFajrAngle") var customFajrAngle: Double = 18.0 {
        didSet {
            guard oldValue != customFajrAngle else { return }
            // Mirrored to the App Group for the same reason as the manual offsets: the widget and
            // complication providers recompute times in their own processes, and without the mirror
            // they run "Custom Angles" with the 18/17 defaults - drifting from the app by however far
            // the user's angles sit from those.
            if Self.isAppProcess { appGroupUserDefaults?.setValue(customFajrAngle, forKey: "customFajrAngle") }
            Settings.invalidatePrayerComputationCache()
            fetchPrayerTimes(force: true, runAutoChecks: false)
        }
    }
    @AppStorage("customIshaAngle") var customIshaAngle: Double = 17.0 {
        didSet {
            guard oldValue != customIshaAngle else { return }
            if Self.isAppProcess { appGroupUserDefaults?.setValue(customIshaAngle, forKey: "customIshaAngle") }
            Settings.invalidatePrayerComputationCache()
            fetchPrayerTimes(force: true, runAutoChecks: false)
        }
    }

    @AppStorage("calculationAutomatic") var calculationAutomatic: Bool = true {
        didSet {
            // Re-arming automatic selection is the user asking to be told again, so forget which detection
            // they last answered and let the next one raise its card. Turning it OFF deliberately keeps the
            // record - that is what makes an Override final. (Only a real off->on transition counts; the
            // watch-sync apply writes this key through raw `UserDefaults`, which bypasses this didSet.)
            guard calculationAutomatic, !oldValue else { return }
            calculationAutoAnsweredCountryCode = ""
            calculationAutoAnsweredMethod = ""
        }
    }
    @AppStorage("calculationAutoChanged") var calculationAutoChanged: Bool = false
    @AppStorage("calculationAutoPreviousMethod") var calculationAutoPreviousMethod: String = ""
    @AppStorage("calculationAutoDetectedMethod") var calculationAutoDetectedMethod: String = ""
    @AppStorage("calculationAutoDetectedCountryCode") var calculationAutoDetectedCountryCode: String = ""

    /// The detection the user has already answered on the "Calculation Method Changed" card - the region it
    /// was raised for and the method it recommended. Confirm and Override are both FINAL answers, so a
    /// detection matching this pair switches the method silently and never raises the card again; only a
    /// genuinely different detection (new region, or a new recommendation for the same one) may ask.
    ///
    /// Deliberately NOT synced to the watch: it records what the person tapped on THIS device, and the whole
    /// point of the pair is that a peer's copy of the calculation state can't resurrect an answered prompt.
    @AppStorage("calculationAutoAnsweredCountryCode") var calculationAutoAnsweredCountryCode: String = ""
    @AppStorage("calculationAutoAnsweredMethod") var calculationAutoAnsweredMethod: String = ""

    @AppStorage("currentCountryCode") var currentCountryCode: String = ""

    @AppStorage("showLocationAlert") var showLocationAlert: Bool = false {
        willSet { objectWillChange.send() }
    }
    @AppStorage("showNotificationAlert") var showNotificationAlert: Bool = false

    @AppStorage("locationNeverAskAgain") var locationNeverAskAgain = false
    @AppStorage("notificationNeverAskAgain") var notificationNeverAskAgain = false

    @AppStorage("showPrayerInfo") var showPrayerInfo: Bool = false

    // MARK: - [Al-Adhan] Optional Prayer Times (shown in app only, never in widgets)

    @AppStorage("showDuha") var showDuha: Bool = false {
        willSet { objectWillChange.send() }
        didSet { fetchPrayerTimes(notification: true) }
    }
    
    @AppStorage("showIslamicMidnight") var showIslamicMidnight: Bool = false {
        willSet { objectWillChange.send() }
        didSet { fetchPrayerTimes(notification: true) }
    }
    @AppStorage("showLastThird") var showLastThird: Bool = false {
        willSet { objectWillChange.send() }
        didSet { fetchPrayerTimes(notification: true) }
    }

    /// Names of optional/informational prayer times shown in the app, but not widgets.
    static let optionalPrayerNames: Set<String> = ["Duhaa", "Islamic Midnight", "Last Third"]

    // MARK: - [Al-Quran] Quran - @AppStorage

    /// Big vs. small in-app Now Playing player. An in-app UI preference, not shared with the widget/watch.
    @AppStorage("nowPlayingExpanded") var nowPlayingExpanded: Bool = false

    @AppStorage("reciter") var reciter: String = "Muhammad Al-Minshawi (Murattal)"

    /// Disambiguates reciters that share the same display name (qiraah / surah base URL).
    @AppStorage("reciterId") var reciterId: String = ""

    @AppStorage("favoriteReciterIDsData") private var favoriteReciterIDsData = Data()
    /// Memoized like `favoriteSurahs`: `isReciterFavorite` runs inside a `.filter` over the whole
    /// reciter list per body pass, which used to be a full JSON decode per element.
    private static var favoriteReciterIDsCache: (data: Data, value: [String])?
    var favoriteReciterIDs: [String] {
        get {
            if let cached = Self.favoriteReciterIDsCache, cached.data == favoriteReciterIDsData {
                return cached.value
            }
            let decoded = (try? Self.decoder.decode([String].self, from: favoriteReciterIDsData)) ?? []
            Self.favoriteReciterIDsCache = (favoriteReciterIDsData, decoded)
            return decoded
        }
        set {
            let normalized = Array(NSOrderedSet(array: newValue.compactMap {
                let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            })) as? [String] ?? []
            let encoded = (try? Self.encoder.encode(normalized)) ?? Data()
            Self.favoriteReciterIDsCache = (encoded, normalized)
            favoriteReciterIDsData = encoded
        }
    }

    @AppStorage("favoriteQiraahTagsData") private var favoriteQiraahTagsData = Data()
    private static var favoriteQiraahTagsCache: (data: Data, value: [String])?
    var favoriteQiraahTags: [String] {
        get {
            if let cached = Self.favoriteQiraahTagsCache, cached.data == favoriteQiraahTagsData {
                return cached.value
            }
            let decoded = (try? Self.decoder.decode([String].self, from: favoriteQiraahTagsData)) ?? []
            Self.favoriteQiraahTagsCache = (favoriteQiraahTagsData, decoded)
            return decoded
        }
        set {
            let normalized = Array(NSOrderedSet(array: newValue.map(Self.normalizeLegacyRiwayahTag))) as? [String] ?? []
            let encoded = (try? Self.encoder.encode(normalized)) ?? Data()
            Self.favoriteQiraahTagsCache = (encoded, normalized)
            favoriteQiraahTagsData = encoded
        }
    }

    @AppStorage("favoriteEnglishTranslationIDsData") private var favoriteEnglishTranslationIDsData = Data()
    var favoriteEnglishTranslationIDs: [String] {
        get {
            (try? Self.decoder.decode([String].self, from: favoriteEnglishTranslationIDsData)) ?? []
        }
        set {
            let normalized = Array(NSOrderedSet(array: newValue.compactMap {
                let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            })) as? [String] ?? []
            favoriteEnglishTranslationIDsData = (try? Self.encoder.encode(normalized)) ?? Data()
        }
    }

    // Saved user flags: sajdah ayahs and broken-letter (muqatta'at) ayahs.
    @AppStorage("savedSajdahAyahIDsData") private var savedSajdahAyahIDsData = Data()
    var savedSajdahAyahIDs: Set<String> {
        get {
            (try? Self.decoder.decode([String].self, from: savedSajdahAyahIDsData)) .flatMap { Set($0) } ?? Set()
        }
        set {
            let arr = Array(newValue)
            savedSajdahAyahIDsData = (try? Self.encoder.encode(arr)) ?? Data()
            objectWillChange.send()
        }
    }

    @AppStorage("savedBrokenLetterAyahIDsData") private var savedBrokenLetterAyahIDsData = Data()
    var savedBrokenLetterAyahIDs: Set<String> {
        get {
            (try? Self.decoder.decode([String].self, from: savedBrokenLetterAyahIDsData)) .flatMap { Set($0) } ?? Set()
        }
        set {
            let arr = Array(newValue)
            savedBrokenLetterAyahIDsData = (try? Self.encoder.encode(arr)) ?? Data()
            objectWillChange.send()
        }
    }

    @AppStorage("reciteType") var reciteType: String = "Continue to Next"

    @AppStorage("favoriteSurahsData") private var favoriteSurahsData = Data()
    /// Decoded-favorites memo. These getters are read from every surah row's body and from
    /// `QuranView.searchDisplayContext` on every render - without the memo each read re-ran a full
    /// JSONDecoder pass, so scrolling the list decoded the same bytes once per visible row per frame.
    private static var favoriteSurahsCache: (data: Data, value: [Int])?
    var favoriteSurahs: [Int] {
        get {
            if let cached = Self.favoriteSurahsCache, cached.data == favoriteSurahsData {
                return cached.value
            }
            let decoded = (try? Self.decoder.decode([Int].self, from: favoriteSurahsData)) ?? []
            Self.favoriteSurahsCache = (favoriteSurahsData, decoded)
            return decoded
        }
        set {
            let encoded = (try? Self.encoder.encode(newValue)) ?? Data()
            Self.favoriteSurahsCache = (encoded, newValue)
            favoriteSurahsData = encoded
        }
    }

    @AppStorage("khatmCompletedAyahsData") var khatmCompletedAyahsData = Data()
    @AppStorage("automaticKhatmCompletion") var automaticKhatmCompletion = true
    /// The Quran Planner's plan (goal + per-day bookkeeping), iOS-only UI in QuranPlannerView.swift.
    /// Declared here because extensions can't add stored properties; harmless on the other targets.
    @AppStorage("quranPlanData") var quranPlanData = Data()
    var khatmCompletedAyahSetCache: Set<String> = []
    /// Int-keyed mirror of `khatmCompletedAyahSetCache` (surah * 1000 + ayah). `isKhatmAyahComplete`
    /// runs per ayah row per render while scrolling in khatm mode - the mirror answers it without
    /// building and hashing a "surah:ayah" String each call. Maintained by every mutation site in
    /// SettingsQuran.swift; the String set stays authoritative for persistence.
    var khatmCompletedAyahIntCache: Set<Int> = []
    var khatmCompletedSurahCountsCache: [Int: Int] = [:]
    var khatmProgressSaveTask: Task<Void, Never>?
    /// Bumped on every khatm mark. The single debounce task re-arms itself while this keeps changing, so a
    /// burst of auto-marks (scrolling) rides one timer instead of cancelling/recreating a Task per ayah.
    var khatmSaveGeneration = 0
    /// Whether the pending debounce task should also fire a UI refresh (set by auto-marks; manual marks
    /// refresh synchronously and leave this false).
    var khatmProgressRefreshPending = false

    var khatmCompletedAyahs: [String] {
        get {
            Array(khatmCompletedAyahSetCache)
        }
        set {
            applyKhatmCompletedAyahKeys(newValue, persistImmediately: true)
        }
    }

    // Raw storage only; the typed `bookmarkedAyahs: [BookmarkedAyah]` accessor lives in SettingsQuran.swift
    // so this core file names no Quran model type (ports to sibling apps without the Quran module). Not
    // `private` so that extension can reach it.
    @AppStorage("bookmarkedAyahsData") var bookmarkedAyahsData = Data()

    @AppStorage("showBookmarks") var showBookmarks = true
    @AppStorage("showFavorites") var showFavorites = true

    /// Reads a surah as swipeable mushaf pages instead of a scrolling ayah list. Toggled from the Quran tab's
    /// toolbar, but only takes effect inside SurahView - the surah browse list itself is unchanged.
    @AppStorage("quranPageMode") var quranPageMode = false
    /// Reading mode shrinks each mushaf page's Arabic until the whole page fits on screen, the way a printed
    /// mushaf sets it. Off, the page renders at the chosen font size and scrolls.
    @AppStorage("mushafFitPage") var mushafFitPage = true

    /// What page mode draws as each page's BODY text. "arabic" (default) is the mushaf itself; the English
    /// options replace the page's text wholesale - same canonical page boundaries, same fit-to-page - with
    /// the transliteration, The Clear Quran, or Saheeh International. Headings follow the page's language.
    @AppStorage("mushafPageLanguage") var mushafPageLanguage: String = MushafPageLanguage.arabic.rawValue

    var resolvedMushafPageLanguage: MushafPageLanguage {
        let base = MushafPageLanguage(rawValue: mushafPageLanguage) ?? .arabic
        #if os(iOS)
        // A beta riwayah whose text hasn't been opted into: the composed Arabic page
        // would show the unaccepted transcription, so page mode reads the riwayah's
        // own printed mushaf instead - the exact print, nothing beta about it.
        // (All 12 beta riwayat ship their facsimile.) English pages stay English.
        if base == .arabic, displayBetaTextConsentNeeded { return .pdf }
        #endif
        return base
    }

    /// How the printed-mushaf PDF is lit: "auto" (default) follows the app's light/dark appearance, so a
    /// dark app shows the print inverted without being asked; "light"/"night" pin it either way. The
    /// invert is hue-preserving (the green border stays green). Raw `MushafPDFAppearance` value.
    @AppStorage("mushafPDFAppearance") var mushafPDFAppearance: String = MushafPDFAppearance.auto.rawValue
    /// Shows the spelled-out pronunciation aid above muqatta'at ayahs (e.g. أَلِفۡ لَآم مِيٓمۡ). Off by default.
    @AppStorage("showMuqattaatHelper") var showMuqattaatHelper = false

    @AppStorage("shareShowAyahInformation") var showAyahInformation: Bool = true
    @AppStorage("shareShowSurahInformation") var showSurahInformation: Bool = false

    @AppStorage("beginnerMode") var beginnerMode: Bool = false

    // Raw storage only; the typed `quranSortMode`/`quranSortDirection` accessors (and `groupBySurah`) live
    // in SettingsQuran.swift so this core file names no Quran sort enum. The defaults are the enum cases'
    // raw values written as literals (QuranSortMode.surah / QuranSortDirection.ascending) - a rawValue
    // change to either case must be mirrored here.
    @AppStorage("quranSortMode") var quranSortModeRaw: String = "surah"
    @AppStorage("quranSortDirection") var quranSortDirectionRaw: String = "ascending"
    /// In Khatm mode, the Surah/Juz toggle (which replaces the Asc/Desc control). When on, surahs are grouped
    /// under juz headers, each surah shown once in the juz it *starts* in - so juz that no surah opens (e.g.
    /// juz 2, 5) appear empty.
    @AppStorage("khatmGroupByJuz") var khatmGroupByJuz: Bool = false
    @AppStorage("searchForSurahs") var searchForSurahs: Bool = true
    // Silent-letter-insensitive Arabic ayah search is ALWAYS on (was `ignoreSilentLettersInQuranSearch`,
    // a toggle removed by request - the recitation-style fold is strictly additive, so there is no
    // reason to turn it off). The old UserDefaults key is simply orphaned.

    @AppStorage("lastReadSurah") var lastReadSurah: Int = 0
    @AppStorage("lastReadAyah") var lastReadAyah: Int = 0
    /// When the last-read position was recorded, for the summary tile's "Today 5:30 PM" caption.
    /// Stamped via `stampLastRead()` at both real save paths (list reader, mushaf pager flush) -
    /// clearing the position deliberately does not stamp. 0 = saved by a build without stamps.
    @AppStorage("lastReadTimestamp") private var lastReadTimestampRaw: Double = 0

    var lastReadDate: Date? {
        lastReadTimestampRaw > 0 ? Date(timeIntervalSince1970: lastReadTimestampRaw) : nil
    }

    func stampLastRead() {
        lastReadTimestampRaw = Date().timeIntervalSince1970
    }

    /// Debounced last-read bookkeeping for the mushaf pager.
    ///
    /// Recording the last-read position used to run inline on EVERY page turn, and it is expensive twice over:
    /// the `@AppStorage` writes fire `objectWillChange` (re-rendering every Settings-observing view, including
    /// all mounted pages), and `refreshQuranWidgets()` does a synchronous widget-snapshot disk write plus
    /// `WidgetCenter.reloadAllTimelines()`. None of that needs to happen mid-flip - only where the reader
    /// *stops* matters - so page turns note the position here and the write settles once the flipping pauses.
    /// `flushPendingLastRead()` runs on backgrounding so a quick exit can't lose the position.
    private var pendingLastRead: (surah: Int, ayah: Int)?
    private var pendingLastReadWorkItem: DispatchWorkItem?

    func noteLastRead(surah: Int, ayah: Int) {
        guard saveLastReadAyah else { return }
        guard lastReadSurah != surah || lastReadAyah != ayah else { return }
        pendingLastRead = (surah, ayah)

        pendingLastReadWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.flushPendingLastRead() }
        pendingLastReadWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)
    }

    func flushPendingLastRead() {
        pendingLastReadWorkItem?.cancel()
        pendingLastReadWorkItem = nil
        guard let pending = pendingLastRead else { return }
        pendingLastRead = nil

        lastReadSurah = pending.surah
        lastReadAyah = pending.ayah
        stampLastRead()
        refreshQuranWidgets()
    }

    // MARK: - [Al-Quran] Surah stats (times opened / played)
    // A tiny [surahID: count] map JSON-encoded in one key each - at most 114 small entries, so it costs
    // almost nothing in memory and is only decoded when a surah header is shown.
    @AppStorage("surahOpenCountsData") private var surahOpenCountsData: Data = Data()
    @AppStorage("surahPlayCountsData") private var surahPlayCountsData: Data = Data()

    private func decodeSurahCounts(_ data: Data) -> [Int: Int] {
        data.isEmpty ? [:] : ((try? Self.decoder.decode([Int: Int].self, from: data)) ?? [:])
    }

    func surahOpenCount(_ surahID: Int) -> Int { decodeSurahCounts(surahOpenCountsData)[surahID] ?? 0 }
    func surahPlayCount(_ surahID: Int) -> Int { decodeSurahCounts(surahPlayCountsData)[surahID] ?? 0 }

    // The whole map at once. The per-surah accessors above decode the JSON on EVERY call, which is fine
    // for a surah header (one call, one surah on screen) and quadratic-feeling for anything that wants
    // all 114 - the profile's totals asked for 228 decodes per pass before these existed.
    var allSurahOpenCounts: [Int: Int] { decodeSurahCounts(surahOpenCountsData) }
    var allSurahPlayCounts: [Int: Int] { decodeSurahCounts(surahPlayCountsData) }

    /// A cheap stamp of everything `ProfileStats` derives from, so the profile can skip recomputing when
    /// nothing it reads has changed. Kept next to the storage it hashes: a new counted thing must be
    /// added here or the profile will quietly show a stale number.
    var profileStatsStamp: Int {
        var hasher = Hasher()
        hasher.combine(prayerTrackerData)
        hasher.combine(trackerExemptDaysData)
        hasher.combine(mensesPauseActive)
        hasher.combine(mensesPauseStartStamp)
        hasher.combine(khatmCompletedAyahsData)
        hasher.combine(quranPlanData)
        hasher.combine(bookmarkedAyahsData)
        hasher.combine(favoriteSurahsData)
        hasher.combine(favoriteReciterIDsData)
        hasher.combine(surahOpenCountsData)
        hasher.combine(surahPlayCountsData)
        hasher.combine(Calendar.current.startOfDay(for: Date()))
        return hasher.finalize()
    }

    func recordSurahOpened(_ surahID: Int) {
        guard (1...114).contains(surahID) else { return }
        var counts = decodeSurahCounts(surahOpenCountsData)
        counts[surahID, default: 0] += 1
        if let data = try? Self.encoder.encode(counts) { surahOpenCountsData = data }
    }

    func recordSurahPlayed(_ surahID: Int) {
        guard (1...114).contains(surahID) else { return }
        var counts = decodeSurahCounts(surahPlayCountsData)
        counts[surahID, default: 0] += 1
        if let data = try? Self.encoder.encode(counts) { surahPlayCountsData = data }
    }

    /// When off, the app neither saves nor shows the "Last Read Ayah" / "Last Listened Surah" sections.
    @AppStorage("saveLastReadAyah") var saveLastReadAyah: Bool = true
    @AppStorage("saveLastListenedSurah") var saveLastListenedSurah: Bool = true
    /// When off, the app neither saves nor shows the "Last Listened Ayah" section.
    @AppStorage("saveLastListenedAyah") var saveLastListenedAyah: Bool = true
    /// When on, the Quran tab shows the daily "Ayah of the Day" card.
    @AppStorage("showAyahOfTheDay") var showAyahOfTheDay: Bool = true
    /// Day key (yyyy-MM-dd) for which the Ayah of the Day card has been hidden via "Hide for Today".
    @AppStorage("ayahOfTheDayHiddenDate") var ayahOfTheDayHiddenDate: String = ""
    /// A shuffled replacement for TODAY's Ayah of the Day, as "dayKey|surahID|ayahID". Stale days no
    /// longer match the key and are ignored, so the deterministic pick quietly resumes tomorrow.
    @AppStorage("ayahOfTheDayOverride") var ayahOfTheDayOverride: String = ""

    // The TYPED accessors over these two stores (`lastListenedAyah` / `lastListenedSurah`) live in
    // SettingsQuran.swift: they name Quran model types, and this core file stays free of every domain's
    // types except the prayer engine it structurally contains. Only the raw `Data` storage lives here
    // (stored properties can't move to extensions); internal so the extension can reach it.
    @AppStorage("lastListenedAyahData") var lastListenedAyahData: Data?
    @AppStorage("lastListenedSurahData") var lastListenedSurahData: Data?

    /// Which qiraah/riwayah to show for Arabic text. Empty or "Hafs" = Hafs an Asim (default). Transliteration and translations only apply to Hafs.
    @AppStorage("displayQiraah") var displayQiraah: String = ""

    /// When on, SurahView shows a qiraat picker above the search bar to compare riwayat in that view.
    @AppStorage("qiraatComparisonMode") var qiraatComparisonMode: Bool = false


    /// When on, ReciterListView reveals non-Hafs qiraat reciters.
    @AppStorage("showOtherQiraatReciters") var showOtherQiraatReciters: Bool = false

    /// Unlocks the 12 machine-extracted riwayat (Ibn Amir, Hamzah, al-Kisai, Abu Jafar,
    /// Yaqub, Khalaf al-Ashir). Their text is BETA - digitized from a printed mushaf set
    /// and not yet verified word-by-word, so it stays opt-in and never appears in
    /// comparison mode while off. Turning it off also drops a selected beta riwayah back
    /// to Hafs, so no unverified text can be left on screen by a stale setting.
    @AppStorage("betaQiraatEnabled") var betaQiraatEnabled: Bool = false {
        didSet {
            guard oldValue != betaQiraatEnabled else { return }
            if !betaQiraatEnabled {
                if Self.Riwayah.isBeta(displayQiraah) {
                    displayQiraah = Self.Riwayah.hafsTag
                }
                #if os(iOS)
                BetaQiraatStore.shared.unloadAll()
                #endif
            }
            objectWillChange.send()
        }
    }

    /// The beta notice has been shown and accepted once; further picks skip the dialog.
    @AppStorage("acceptedBetaQiraatNotice") var acceptedBetaQiraatNotice: Bool = false

    /// One wording for the beta warning, shown by the toggle and every selection dialog.
    static let betaQiraatNotice = """
        These twelve riwayat were digitized by machine from a printed mushaf and have \
        not yet been checked word by word. Their ayah numbering and surah divisions are \
        verified, but individual marks or letters may still be wrong. Please do not rely \
        on them for memorization or recitation - use Hafs or another verified riwayah \
        for that.
        """

    /// Shared expand/collapse state for qiraah details in Quran settings and reciter lists.
    var showQiraahDetails: Bool {
        get { showOtherQiraatReciters }
        set { showOtherQiraatReciters = newValue }
    }

    /// Pass to Ayah.displayArabicText(surahId:clean:qiraahOverride:). Nil means Hafs.
    var displayQiraahForArabic: String? {
        let normalized = Self.normalizeLegacyRiwayahTag(displayQiraah)
        return normalized.isEmpty ? nil : normalized
    }

    /// When false, only Arabic is shown (no transliteration or English), since those are for Hafs an Asim only.
    var isHafsDisplay: Bool {
        Self.normalizeLegacyRiwayahTag(displayQiraah).isEmpty
    }

    /// Arabic riwayah line for settings section headers (matches on-screen Arabic text riwayah).
    var displayQiraahArabicCaption: String {
        let key = Self.normalizeLegacyRiwayahTag(displayQiraah)
        return Self.Riwayah.arabicCaptionByTag[key] ?? Self.Riwayah.arabicCaptionByTag[Self.Riwayah.hafsTag]!
    }

    /// The displayed riwayah's tag when it is non-Hafs and ships a print-derived tajweed
    /// color pack (`QiraahTajweedStore`); nil on Hafs or when no pack is bundled.
    var riwayahTajweedPackTag: String? {
        #if os(iOS)
        guard let raw = displayQiraahForArabic else { return nil }
        let tag = Self.Riwayah.canonicalTag(raw)
        guard !tag.isEmpty, QiraahTajweedStore.shared.isAvailable(tag: tag) else { return nil }
        return tag
        #else
        return nil
        #endif
    }

    /// True when the DISPLAYED riwayah's selectable text is beta and the user hasn't
    /// opted into beta text yet. Text surfaces show the consent card instead of text;
    /// page mode falls back to the riwayah's printed mushaf (which is exact, not beta).
    var displayBetaTextConsentNeeded: Bool {
        guard let tag = displayQiraahForArabic else { return false }
        return Self.Riwayah.isBeta(Self.Riwayah.canonicalTag(tag)) && !betaQiraatEnabled
    }

    /// Hidden riwayah tajweed rules, by rule KEY ("idgham", "silah_meem", ...), comma-joined.
    /// Keys are meaning-stable across riwayat, so hiding "idgham" hides it in every riwayah.
    @AppStorage("riwayahTajweedHiddenRules") var riwayahTajweedHiddenRules: String = ""

    var riwayahTajweedHiddenRuleSet: Set<String> {
        Set(riwayahTajweedHiddenRules.split(separator: ",").map(String.init))
    }

    func isRiwayahTajweedRuleVisible(_ key: String) -> Bool {
        !riwayahTajweedHiddenRuleSet.contains(key)
    }

    func setRiwayahTajweedRule(_ key: String, visible: Bool) {
        var set = riwayahTajweedHiddenRuleSet
        if visible { set.remove(key) } else { set.insert(key) }
        riwayahTajweedHiddenRules = set.sorted().joined(separator: ",")
    }

    @AppStorage("showArabicText") var showArabicText: Bool = true
    @AppStorage("highlightAllahNames") var highlightAllahNames: Bool = false
    /// Tap a word in the reader to see what it means. ON by default - the meaning is the point of
    /// reading, and a reader who doesn't know the feature exists will never go looking for it in
    /// Settings. A tap that lands on a word opens its card; a tap anywhere else in the ayah still marks
    /// the ayah exactly as before (see `WordByWordTextView.Coordinator`, which only claims the tap when
    /// it is actually on a word). Only Hafs an Asim - the bundled glosses are indexed against its
    /// wording, and another riwayah's words would not line up (see `WordByWordStore`, which the iOS
    /// settings screen unloads when this is switched off).
    @AppStorage("wordByWordMeanings") var wordByWordMeanings: Bool = true
    /// ON by default: the colors are the fastest way to read correctly, and word-by-word (also
    /// default-on) leans on them - the tapped word's card names the rules its colors show.
    @AppStorage("showTajweedColors") var showTajweedColors: Bool = true
    @AppStorage("showTajweedTafkhim") var showTajweedTafkhim: Bool = true
    @AppStorage("showTajweedQalqalah") var showTajweedQalqalah: Bool = true
    @AppStorage("showTajweedLamShamsiyah") var showTajweedLamShamsiyah: Bool = true
    @AppStorage("showTajweedSukoonJazm") var showTajweedDroppedLetter: Bool = true
    @AppStorage("showTajweedBareNuunMeem") var showTajweedIdghamBiGhunnahLight: Bool = true
    @AppStorage("showTajweedIdghamBiGhunnahHeavy") var showTajweedIdghamBiGhunnahHeavy: Bool = true
    @AppStorage("showTajweedGeneralGhunnah") var showTajweedGeneralGhunnah: Bool = true
    @AppStorage("showTajweedIkhfaa") var showTajweedIkhfaa: Bool = true
    @AppStorage("showTajweedIqlab") var showTajweedIqlab: Bool = true
    @AppStorage("showTajweedIdghamBilaGhunnah") var showTajweedIdghamBilaGhunnah: Bool = true
    @AppStorage("showTajweedHamzatWaslSilent") var showTajweedHamzatWaslSilent: Bool = true
    @AppStorage("showTajweedMaddNatural2") var showTajweedMaddNatural2: Bool = true
    @AppStorage("showTajweedMaddNaturalMiniature") var showTajweedMaddNaturalMiniature: Bool = true
    @AppStorage("showTajweedMadd246") var showTajweedMaddAaridLisSukoon: Bool = true
    @AppStorage("showTajweedMaddNecessary6") var showTajweedMaddNecessary6: Bool = true
    @AppStorage("showTajweedMaddSeparated") var showTajweedMaddSeparated: Bool = true
    @AppStorage("showTajweedMaddConnected") var showTajweedMaddConnected: Bool = true
    @AppStorage("cleanArabicText") var cleanArabicText: Bool = false
    @AppStorage("removeArabicDots") var removeArabicDots: Bool = false

    @AppStorage("showTransliteration") var showTransliteration: Bool = false
    @AppStorage("showEnglishSaheeh") var showEnglishSaheeh: Bool = true
    @AppStorage("showEnglishMustafa") var showEnglishMustafa: Bool = false
    @AppStorage("copyAyahArabic") var copyAyahArabic: Bool = true
    @AppStorage("copyAyahTransliteration") var copyAyahTransliteration: Bool = false
    @AppStorage("copyAyahEnglishSaheeh") var copyAyahEnglishSaheeh: Bool = false
    @AppStorage("copyAyahEnglishMustafa") var copyAyahEnglishMustafa: Bool = false
    @AppStorage("showPageJuzDividers") var showPageJuzDividers: Bool = true
    @AppStorage("showFullSurahRow") var showFullSurahRow: Bool = false

    @AppStorage("quranSearchHistoryData") private var quranSearchHistoryData = Data()
    /// Memoized: the Quran search bar reads this per render while focused (per keystroke).
    private static var quranSearchHistoryCache: (data: Data, value: [String])?
    var quranSearchHistory: [String] {
        get {
            if let cached = Self.quranSearchHistoryCache, cached.data == quranSearchHistoryData {
                return cached.value
            }
            let decoded = (try? Self.decoder.decode([String].self, from: quranSearchHistoryData)) ?? []
            Self.quranSearchHistoryCache = (quranSearchHistoryData, decoded)
            return decoded
        }
        set {
            let capped = Array(newValue.prefix(10))
            let encoded = (try? Self.encoder.encode(capped)) ?? Data()
            Self.quranSearchHistoryCache = (encoded, capped)
            quranSearchHistoryData = encoded
        }
    }

    // The Hadith tab's recent searches - the Quran search history's exact twin (chips over the search bar).
    @AppStorage("hadithSearchHistoryData") private var hadithSearchHistoryData = Data()
    /// Memoized like `favoriteSurahs`: the chips row stays mounted and reads this on every render pass.
    private static var hadithSearchHistoryCache: (data: Data, value: [String])?
    var hadithSearchHistory: [String] {
        get {
            if let cached = Self.hadithSearchHistoryCache, cached.data == hadithSearchHistoryData {
                return cached.value
            }
            let decoded = (try? Self.decoder.decode([String].self, from: hadithSearchHistoryData)) ?? []
            Self.hadithSearchHistoryCache = (hadithSearchHistoryData, decoded)
            return decoded
        }
        set {
            let capped = Array(newValue.prefix(10))
            let encoded = (try? Self.encoder.encode(capped)) ?? Data()
            Self.hadithSearchHistoryCache = (encoded, capped)
            hadithSearchHistoryData = encoded
        }
    }

    func addHadithSearchHistory(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var history = hadithSearchHistory.filter {
            $0.caseInsensitiveCompare(trimmed) != .orderedSame
        }
        history.insert(trimmed, at: 0)
        hadithSearchHistory = Array(history.prefix(10))
    }

    func removeHadithSearchHistory(_ query: String) {
        hadithSearchHistory.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
    }

    @AppStorage("englishFontSize") var englishFontSize: Double = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
    
    // MARK: - [Al-Hadith] Hadith display

    /// Which parts of a hadith render in the Hadith tab (both default on; hiding one gives a pure-Arabic or
    /// pure-English reading experience).
    @AppStorage("showHadithArabic") var showHadithArabic = true
    @AppStorage("showHadithEnglish") var showHadithEnglish = true
    /// Hadith's own "Highlight Allah" toggle, split from the Quran's `highlightAllahNames` so the two
    /// readers can differ. Seeded from the Quran toggle once in `init` so the split changes nothing
    /// until the user actually flips it.
    @AppStorage("highlightAllahNamesHadith") var highlightAllahNamesHadith: Bool = false
    /// Hadith text sizes, independent of the Quran's own sliders.
    @AppStorage("hadithArabicFontSize") var hadithArabicFontSize: Double = Double(UIFont.preferredFont(forTextStyle: .body).pointSize + 4)
    @AppStorage("hadithEnglishFontSize") var hadithEnglishFontSize: Double = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)

    // MARK: - [Islam tab] Arabic letters & 99 Names
    
    /// THE grid toggle, app-wide: the Quran tab's lists, the Arabic alphabet, the 99 Names, and the Islam
    /// resources all follow this one switch - flipping it anywhere flips it everywhere. (The key keeps its
    /// historical name so existing users' Quran preference carries over. The retired per-screen
    /// `arabicDisplayMode` / `namesDisplayMode` strings are no longer migrated - those screens default to
    /// list until re-toggled.)
    @AppStorage("quranGridMode") var gridMode = false
    
    /// Per-screen grid choices (Arabic Alphabet / 99 Names / Islam tab; the Hadith tab and the Quran tab
    /// own theirs). -1 = "not chosen yet": falls back to the app-wide `gridMode`, so existing users keep
    /// their current look until they flip that screen's own toggle - after which each grid icon controls
    /// only its own screen.
    @AppStorage("gridModeArabicRaw") var gridModeArabicRaw: Int = -1
    @AppStorage("gridModeNamesRaw") var gridModeNamesRaw: Int = -1
    @AppStorage("gridModeIslamRaw") var gridModeIslamRaw: Int = -1

    var arabicGridMode: Bool {
        get { gridModeArabicRaw == -1 ? gridMode : gridModeArabicRaw == 1 }
        set { gridModeArabicRaw = newValue ? 1 : 0 }
    }

    var namesGridMode: Bool {
        get { gridModeNamesRaw == -1 ? gridMode : gridModeNamesRaw == 1 }
        set { gridModeNamesRaw = newValue ? 1 : 0 }
    }

    var islamGridMode: Bool {
        get { gridModeIslamRaw == -1 ? gridMode : gridModeIslamRaw == 1 }
        set { gridModeIslamRaw = newValue ? 1 : 0 }
    }
    
    @AppStorage("THEfontArabic") var fontArabic: String = "KFGQPCHAFSUthmanicScript-Regula"
    @AppStorage("fontArabicSize") var fontArabicSize: Double = Double(UIFont.preferredFont(forTextStyle: .title1).pointSize)
    @AppStorage("useFontArabic") var useFontArabic = true
    /// Raw storage for `arabicScriptStyle` (see SettingsQuran). Empty means the reader has never
    /// chosen, which resolves to Madani - the effective default. A value written here is always an
    /// explicit choice and is honored as one, so the old "automatic" saves still mean Automatic.
    @AppStorage("quranArabicScriptStyle") var arabicScriptStyleRaw: String = ""

    /// The Arabic face for the NON-Quran Arabic screens (Hadith, Adhkar, Duas, 99 Names, Arabic Alphabet).
    /// Independent of the Quran's own font picker.
    enum IslamArabicFace: String, CaseIterable {
        case uthmani, indopak, basic

        /// Outside the Quran, "Uthmani" is the Hafs face - the same one the mushaf uses. It ships
        /// no precomposed آ, which plain Arabic prose leans on constantly (5,616 times in six hadith
        /// books alone); every Arabic string is handed through `decomposingAlefMadda` first, so the
        /// face draws it from its own parts instead of falling back mid-word.
        var fontName: String {
            switch self {
            case .uthmani: return Settings.hafsUthmaniFontName
            case .indopak: return Settings.indopakFontName
            case .basic: return Settings.systemArabicFontName
            }
        }
    }

    /// Raw storage for `islamArabicFace`. Empty means "not chosen yet" - the legacy two-way
    /// Quranic-vs-Basic toggle (`useFontArabic`) seeds the richer choice on first read.
    @AppStorage("islamArabicFontFace") var islamArabicFaceRaw: String = ""

    var islamArabicFace: IslamArabicFace {
        get {
            if let face = IslamArabicFace(rawValue: islamArabicFaceRaw) { return face }
            return useFontArabic ? .uthmani : .basic
        }
        set {
            islamArabicFaceRaw = newValue.rawValue
            // Keep the legacy flag in step - the watch sync channel still speaks Quranic-vs-Basic.
            useFontArabic = newValue != .basic
        }
    }

    /// True when the Quran Arabic font picker is set to "Basic" (the standard Apple system font).
    var quranUsesSystemArabicFont: Bool { fontArabic == Settings.systemArabicFontName }

    /// True when Quran Arabic renders in a real bundled face (Uthmani / Qiraat / IndoPak) rather than the system
    /// font. Views pass this to `arabicFontDesign(custom:)` so the app-wide rounded design skips the bundled faces
    /// but still applies when "Basic" is selected. See the note in `Globals.swift`.
    var quranUsesCustomArabicFace: Bool { !quranUsesSystemArabicFont }

    /// Same question for the non-Quran Arabic screens (Hadith, Adhkar, Duas, 99 Names, Arabic Alphabet):
    /// true whenever their three-way face picker is on a real bundled face rather than "Basic".
    var islamUsesCustomArabicFace: Bool { islamArabicFace != .basic }

    /// The Arabic font for the non-Quran Arabic screens, straight from the three-way face choice:
    /// Uthmani (the Qiraat face - never the Hafs Quran face), IndoPak, or Basic (system).
    var nonQuranArabicFontName: String { islamArabicFace.fontName }

    // MARK: - [Islam tab] Arabic Alphabet screen size
    
    static let randomReciterName = "Random Reciter"
    static let hafsUthmaniFontName = "KFGQPCHAFSUthmanicScript-Regula"
    /// Migration sentinel only. The app once bundled the KFGQPC Qunbul face (as `Qiraat.ttf`)
    /// for non-Hafs qiraat and for all non-Quran Arabic; it is no longer shipped, and any stored
    /// `fontArabic` still holding this name is migrated to the Hafs face at launch.
    static let legacyQiraatFontName = "KFGQPCQUMBULUthmanicScript-Regu"
    static let indopakFontName = "Al_Mushaf"
    /// Migration sentinels: names the IndoPak face briefly shipped under during testing. A stored
    /// value matching one is rewritten at launch, or the reader keeps a name no font answers to.
    static let legacyIndopakFontNames = ["KFGQPCNastaleeq-Regular", "AlQuranIndoPakbyQuranWBW"]
    /// Sentinel `fontArabic` value meaning "use the standard Apple system font" for Quran Arabic. It is not a
    /// real installed font, so any stray `.custom(_)` with it falls back to the system font anyway.
    static let systemArabicFontName = "AlIslamSystemArabicFont"

    /// The Arabic Alphabet screens (ArabicView / ArabicLetterView) expose a size slider. This is its position
    /// as an index into `arabicLetterDynamicTypeSizes`. The views apply the result as a Dynamic-Type *floor*
    /// so text only ever grows from the device size, and the custom Arabic glyphs (built with `relativeTo:`)
    /// grow along with every other label.
    @AppStorage("arabicLetterSizeIndex") var arabicLetterSizeIndex: Int = 0

    /// Hides the English readings ("ba", "bi", "bu") under the tashkeel glyphs on the Arabic Alphabet screens, so
    /// the marks can be practised from the Arabic alone rather than read off the transliteration.
    @AppStorage("hideEnglishInArabicLetters") var hideEnglishInArabicLetters: Bool = false

    /// Writes the WITH HAMZA practice syllables with the Uthmani sukoon (U+06E1) instead of the plain
    /// one (U+0652), so learners can practise the exact mark shape the mushaf prints. Persisted (unlike
    /// the Tashkeel screen's ephemeral picker): letter screens are opened one at a time, and re-flipping
    /// the script on every letter would get old fast.
    @AppStorage("quranicSukoonInLetterPractice") var quranicSukoonInLetterPractice: Bool = false

    /// Starts at `.xSmall`, not `.large`: a floor is a *minimum*, so anchoring it at `.large` silently forced
    /// the alphabet up to the default text size for anyone whose system Dynamic Type is set smaller. The
    /// lowest slider position must mean "whatever the device is set to", which only `.xSmall` guarantees.
    static let arabicLetterDynamicTypeSizes: [DynamicTypeSize] =
        [.xSmall, .small, .medium, .large, .xLarge, .xxLarge, .xxxLarge, .accessibility1, .accessibility2, .accessibility3]

    var arabicLetterDynamicTypeSize: DynamicTypeSize {
        let sizes = Self.arabicLetterDynamicTypeSizes
        return sizes[min(max(arabicLetterSizeIndex, 0), sizes.count - 1)]
    }

    /// The Islam tab's Arabic face (`nonQuranArabicFontName`), scaling with Dynamic Type so the Arabic
    /// Alphabet size slider affects it. `base` is the point size at the default (`.large`) content size.
    ///
    /// Deliberately the NON-Quran face: every Islam-tab surface that shows standard Arabic - dua, dhikr,
    /// the 99 Names, the alphabet and its letter detail - answers to the one `IslamArabicFontPicker`, so
    /// this must read the same setting the rows beside it do. It used to read `fontArabic` (the *Quran*
    /// picker's face), which is why flipping the alphabet's own picker to IndoPak restyled the letter rows
    /// but left the big glyph on the detail screen in the mushaf face.
    func scalableIslamArabicFont(base: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        Font.arabic(nonQuranArabicFontName, size: base, relativeTo: style)
    }

    // Raw storage only; the typed `favoriteLetters: [LetterData]` accessor + toggles live next to the
    // `LetterData` type in ArabicLetters.swift, so this core file names no letter model type. Not `private`
    // so that extension can reach it.
    @AppStorage("favoriteLetterData") var favoriteLetterData = Data()

    /// Pinned Islam-tab resources, stored as the destination enum's raw values, comma-joined (a dozen short
    /// identifiers - a Codable blob would be ceremony).
    @AppStorage("favoriteIslamResources") private var favoriteIslamResourcesRaw = ""

    func isIslamResourceFavorite(_ id: String) -> Bool {
        favoriteIslamResourcesRaw.components(separatedBy: ",").contains(id)
    }

    func toggleIslamResourceFavorite(_ id: String) {
        var ids = favoriteIslamResourcesRaw.components(separatedBy: ",").filter { !$0.isEmpty }
        if let index = ids.firstIndex(of: id) {
            ids.remove(at: index)
        } else {
            ids.append(id)
        }
        favoriteIslamResourcesRaw = ids.joined(separator: ",")
    }

    @AppStorage("favoriteNameNumbersData") private var favoriteNameNumbersData = Data()
    var favoriteNameNumbers: [Int] {
        get {
            (try? Self.decoder.decode([Int].self, from: favoriteNameNumbersData)) ?? []
        }
        set {
            favoriteNameNumbersData = (try? Self.encoder.encode(newValue)) ?? Data()
        }
    }

    @AppStorage("showDescription") var showDescription = false

    func toggleNameFavorite(number: Int) {
        withAnimation {
            if isNameFavorite(number: number) {
                favoriteNameNumbers.removeAll(where: { $0 == number })
            } else {
                favoriteNameNumbers.append(number)
            }
        }
    }

    func isNameFavorite(number: Int) -> Bool {
        favoriteNameNumbers.contains(number)
    }
    
    // MARK: - [Shared] Arabic search normalization

    func cleanSearch(_ text: String, whitespace: Bool = false) -> String {
        // Single scalar walk: fold each Arabic scalar through the canonical map (dagger alif → alif, hamza
        // carriers → bare letters, teh marbuta → heh, …) and drop unwanted punctuation/marks in the SAME
        // pass. Replaces the old 22 sequential `replacingOccurrences` scans (each a full-string pass +
        // allocation) plus a separate filter pass - this runs on every keystroke query and ~7×/ayah during
        // index build, so collapsing 23 passes into 1 is a real win. Behavior is identical: all map keys are
        // single scalars, normalization still happens before the unwanted-char filter, lowercasing after.
        var built = ""
        built.unicodeScalars.reserveCapacity(text.unicodeScalars.count)
        for scalar in text.unicodeScalars {
            if let mapped = Self.canonicalArabicSearchScalarMap[scalar] {
                guard let replacement = mapped else { continue }   // map → nil means "drop" (e.g. bare hamza)
                if Self.unwantedCharSet.contains(replacement) { continue }
                built.unicodeScalars.append(replacement)
            } else {
                if Self.unwantedCharSet.contains(scalar) { continue }
                built.unicodeScalars.append(scalar)
            }
        }
        var cleaned = collapsingWhitespace(built.lowercased())

        if whitespace {
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleaned
    }

    /// The silent-letter search lane: the mushaf-sukoon fold (drops letters the recitation skips,
    /// e.g. the alif of ءَامَنُوا۟) followed by the alif-wiqaya trim. The trim runs on BOTH this
    /// corpus lane and the query, so spellings with the silent alif, without it, or MIXING both
    /// (ءامنو وعملوا) converge to the same bytes - the raw sukoon fold alone was all-or-nothing per
    /// blob, which is why partially-truncated queries used to miss.
    func cleanSearchIgnoringSilentArabicLetters(_ text: String, whitespace: Bool = false) -> String {
        cleanSearch(text.removingSilentArabicLettersForSearch, whitespace: whitespace)
            .removingAlifWiqayaForSearch
    }

    /// The hamza-PRECISION lane: the same fold as `cleanSearch` except every hamza - the bare ء and the
    /// waw/ya-seated ؤ ئ - survives as a single ء instead of being dropped or folded to its seat.
    ///
    /// `cleanSearch` deletes the hamza on purpose, so a typed نسا still finds نساء. The cost is that it
    /// also makes نساء (women) and نسى (forgets) collapse to the same bytes نسا, so searching يانساء
    /// returned يَنسَىٰ. This lane is the correction, and it is only consulted when the QUERY actually
    /// carries a bare ء (see `HamzaPrecisionFilter`): type the hamza and it counts, leave it out and
    /// nothing changes.
    ///
    /// Seated hamzas fold in because a word's hamza changes seat with its case ending - نِسَآءِ, نِسَآئِكُمۡ,
    /// نِسَآؤُكُمۡ are one word - so a typed نساء has to reach all three. Alif-seated أ إ آ are deliberately
    /// NOT folded here: they keep mapping to ا exactly as before, so word-initial spellings are untouched.
    func cleanSearchKeepingHamza(_ text: String, whitespace: Bool = false) -> String {
        var built = ""
        built.unicodeScalars.reserveCapacity(text.unicodeScalars.count)
        for scalar in text.unicodeScalars {
            if let mapped = Self.hamzaPreservingArabicSearchScalarMap[scalar] {
                guard let replacement = mapped else { continue }
                if Self.unwantedCharSet.contains(replacement) { continue }
                built.unicodeScalars.append(replacement)
            } else {
                if Self.unwantedCharSet.contains(scalar) { continue }
                built.unicodeScalars.append(scalar)
            }
        }
        var cleaned = collapsingWhitespace(built.lowercased())
        if whitespace {
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return cleaned
    }

    /// The hamza-precision test for one query, or nil when the query carries no bare ء and therefore
    /// nothing extra should be checked. Build it once per query; ask it about each candidate.
    ///
    /// It only ever REMOVES results. `cleanSearch` drops the hamza, so every hamza-lane match is also a
    /// plain-lane match - which is why this runs as a filter over what the normal search already found
    /// instead of as another index: no extra blob per ayah, and no cost at all for queries without a ء.
    struct HamzaPrecisionFilter {
        /// The folded query in every lane the ordinary search offers - plain, vocative-joined, and
        /// silent-letter - so this can only reject a candidate the normal search would have rejected
        /// for lacking the hamza, never one it found through a lane this doesn't model.
        private let needles: [String]

        init?(query: String) {
            guard query.containsBareHamza else { return nil }
            let settings = Settings.shared
            let base = query.removingAyahSearchOperators
            let plain = settings.cleanSearchKeepingHamza(base, whitespace: true)
            guard !plain.isEmpty else { return nil }
            let silent = settings.cleanSearchKeepingHamza(base.removingSilentArabicLettersForSearch, whitespace: true)
                .removingAlifWiqayaForSearch

            var built: [String] = []
            for candidate in [plain, silent] where !candidate.isEmpty {
                if !built.contains(candidate) { built.append(candidate) }
                let joined = candidate.joiningVocativeYaForSearch
                if joined != candidate, !built.contains(joined) { built.append(joined) }
            }
            needles = built
        }

        /// The hamza-preserving haystack for one ayah, in the same lanes the ordinary index builds.
        /// Returns nil when the text carries no hamza at all - such an ayah can never satisfy a query
        /// that has one, so callers can skip storing anything and treat nil as "no match".
        static func corpusLanes(for arabicTexts: [String]) -> String? {
            let settings = Settings.shared
            var lanes: [String] = []
            for text in arabicTexts {
                for variant in text.arabicDaggerVariantsForSearch {
                    lanes.append(settings.cleanSearchKeepingHamza(variant))
                    lanes.append(
                        settings.cleanSearchKeepingHamza(variant.removingSilentArabicLettersForSearch)
                            .removingAlifWiqayaForSearch
                    )
                }
            }
            let joined = lanes.joined(separator: " ")
            return joined.containsBareHamza ? joined : nil
        }

        /// True when the prebuilt haystack still contains the query with hamzas kept on both sides.
        func matches(lanes: String?) -> Bool {
            guard let lanes else { return false }
            return needles.contains { lanes.contains($0) }
        }

        /// Convenience for callers that hold the ayah's Arabic rather than a prebuilt haystack.
        func matches(anyOf arabicTexts: [String]) -> Bool {
            matches(lanes: Self.corpusLanes(for: arabicTexts))
        }
    }

    /// `canonicalArabicSearchScalarMap` with every hamza form redirected to a surviving ء.
    private static let hamzaPreservingArabicSearchScalarMap: [UnicodeScalar: UnicodeScalar?] = {
        var out = canonicalArabicSearchScalarMap
        let hamza = UnicodeScalar(0x0621)!
        // Bare hamza and its variants, plus the waw/ya-seated forms. The seat is not a letter here.
        for value in [0x0621, 0x0674, 0x0624, 0x0626, 0x0676, 0x0677, 0x0678] {
            if let scalar = UnicodeScalar(value) { out.updateValue(hamza, forKey: scalar) }
        }
        return out
    }()

    /// Scalar form of `canonicalArabicSearchMap`, built once: `key scalar → replacement scalar`, or `nil`
    /// to drop the scalar entirely. Lets `cleanSearch` normalize in a single pass instead of 22 string scans.
    /// (All `canonicalArabicSearchMap` keys are single scalars and values are one scalar or empty.)
    private static let canonicalArabicSearchScalarMap: [UnicodeScalar: UnicodeScalar?] = {
        var out: [UnicodeScalar: UnicodeScalar?] = [:]
        for (key, value) in canonicalArabicSearchMap {
            let keyScalars = Array(key.unicodeScalars)
            guard keyScalars.count == 1 else { continue }
            let valueScalars = Array(value.unicodeScalars)
            if valueScalars.isEmpty {
                out.updateValue(nil, forKey: keyScalars[0])              // store .none → drop
            } else if valueScalars.count == 1 {
                out.updateValue(valueScalars[0], forKey: keyScalars[0])  // store replacement scalar
            }
        }
        return out
    }()

    private static let canonicalArabicSearchMap: [String: String] = [
        // Alif family
        "\u{0670}": "ا", // dagger alif
        "ٱ": "ا",
        // Hamza family folds to plain carrier letters for forgiving search.
        "أ": "ا",
        "إ": "ا",
        "آ": "ا",
        "ٲ": "ا",
        "ٳ": "ا",
        "ٵ": "ا",
        "ؤ": "و",
        "ئ": "ي",
        "ء": "",
        "ٴ": "",
        "ٶ": "و",
        "ٷ": "و",
        "ٸ": "ي",
        // Waw variants
        "ۥ": "و",
        // Ya variants
        "ۦ": "ي",
        "\u{06E7}": "ي", // small high yeh (إِبۡرَٰهِـۧمَ) -> plain yaa, the dagger-alif treatment
        "ى": "ا", // alif maqsurah -> alif (matches both ى and ا forms in search)
        // Teh marbuta equivalence (broad)
        "ة": "ه",
        // Tatweel: a stretching stroke, and in the mushaf a CARRIER for floating marks (the ـۧ of
        // إِبۡرَٰهِـۧمَ, the ـٔ of يَٰٓـَٔادَمُ). The mark folds above; the carrier must not survive it,
        // or the folded word keeps a phantom letter no typed query contains ("ابراهـم"). Search
        // fold only - the display folds keep their carriers, so rendering is untouched.
        "\u{0640}": ""
    ]

    private static let unwantedCharSet: CharacterSet = {
        var set = CharacterSet.punctuationCharacters
            .union(.symbols)
            .union(.nonBaseCharacters)
        // Keep boolean-search operators in the normalized query.
        set.remove(charactersIn: "&|!#")
        return set
    }()

    private func collapsingWhitespace(_ text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    // MARK: - [Shared] App-wide appearance & misc @AppStorage

    @AppStorage("THEfirstLaunch") var firstLaunch = true

    @AppStorage("hapticOn") var hapticOn: Bool = true

    @AppStorage("defaultView") var defaultView: Bool = true

    /// The soft accent-colored radial wash at the top of every list (see `washedListBackground`).
    @AppStorage("showAccentGlow") var showAccentGlow: Bool = true

    /// Colors that wash with Al-Islam's brand yellow-and-green instead of the accent. ON by default -
    /// it IS the app's signature look on the default accent - and auto-disabled the moment the accent
    /// leaves the default (see `accentColor.didSet`); from there only the Appearance toggle brings it
    /// back.
    @AppStorage("alIslamGlow") var alIslamGlow: Bool = true

    @AppStorage("colorSchemeString") var colorSchemeString: String = "system"
    var colorScheme: ColorScheme? {
        get {
            colorSchemeFromString(colorSchemeString)
        }
        set {
            colorSchemeString = colorSchemeToString(newValue)
        }
    }

    // MARK: - [Shared] Global helpers (not Quran- or Adhan-specific)

    #if os(iOS)
    /// One reused, prepared generator: allocating a fresh `UIImpactFeedbackGenerator` per tap added
    /// latency/jitter on the highest-frequency taps in the app (the tasbih counter). Re-preparing after
    /// each impact keeps the Taptic Engine warm for the next one.
    private static let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    #endif

    func hapticFeedback() {
        #if os(iOS)
        if hapticOn {
            Self.impactGenerator.impactOccurred()
            Self.impactGenerator.prepare()
        }
        #endif

        #if os(watchOS)
        if hapticOn { WKInterfaceDevice.current().play(.click) }
        #endif
    }

    func colorSchemeFromString(_ colorScheme: String) -> ColorScheme? {
        switch colorScheme {
        case "light", "sepia":
            return .light
        case "dark", "gray":
            return .dark
        case "custom":
            // Pick a light or dark base from the chosen background's brightness so text stays readable.
            return (customBackgroundLuminance ?? 1) < 0.5 ? .dark : .light
        default:
            return nil
        }
    }

    /// RGB components (0…1) of a "RRGGBB" hex string, or nil if invalid.
    private func rgbComponents(fromHex hex: String) -> (r: Double, g: Double, b: Double)? {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let rgb = UInt64(s, radix: 16) else { return nil }
        return (Double((rgb >> 16) & 0xFF) / 255, Double((rgb >> 8) & 0xFF) / 255, Double(rgb & 0xFF) / 255)
    }

    /// Perceived luminance (0…1) of the custom background, used to choose its light/dark base and derive shades.
    private var customBackgroundLuminance: Double? {
        guard let c = rgbComponents(fromHex: customBackgroundColorHex) else { return nil }
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
    }

    /// The custom background nudged brighter/darker by `delta`, for deriving the row and glass-tint shades.
    private func adjustedCustomBackground(by delta: Double) -> Color? {
        guard let c = rgbComponents(fromHex: customBackgroundColorHex) else { return nil }
        func clampAdj(_ v: Double) -> Double { max(0, min(1, v + delta)) }
        return Color(red: clampAdj(c.r), green: clampAdj(c.g), blue: clampAdj(c.b))
    }

    // MARK: - [Shared] Reading themes (Sepia / Gray)
    // These layer custom background + row colors on top of a light (Sepia) or dark (Gray) base, so the app
    // offers warm/neutral reading looks beyond plain Light / Dark / System. Light/Dark/System return nil here
    // and keep the standard system grouped colors (no behavior change for existing users).

    /// True when the active theme paints its own background/row colors instead of the system grouped colors.
    var hasCustomThemeColors: Bool {
        colorSchemeString == "sepia" || colorSchemeString == "gray" || colorSchemeString == "custom"
    }

    /// Background shown behind list content for custom themes (warm cream / neutral charcoal / user-picked).
    var themeBackgroundColor: Color? {
        switch colorSchemeString {
        case "sepia": return Color(red: 0.90, green: 0.83, blue: 0.69)
        case "gray":  return Color(red: 0.13, green: 0.13, blue: 0.14)
        case "custom": return Color(hex: customBackgroundColorHex)
        default:      return nil
        }
    }

    /// Row / card color for plain (non-glass) list rows in custom themes, set apart from the background.
    var themeRowBackgroundColor: Color? {
        switch colorSchemeString {
        case "sepia": return Color(red: 0.93, green: 0.90, blue: 0.82)
        case "gray":  return Color(red: 0.19, green: 0.19, blue: 0.20)
        // A shade offset from the picked background (lighter on dark, darker on light) so cards stand out.
        case "custom": return adjustedCustomBackground(by: (customBackgroundLuminance ?? 1) < 0.5 ? 0.06 : -0.06)
        default:      return nil
        }
    }

    /// Tint blended into Liquid Glass cards/controls for custom themes, so glass reads as warm cream
    /// (Sepia) or neutral charcoal (Gray) instead of plain white/black. Nil = untinted system glass.
    var themeGlassTint: Color? {
        switch colorSchemeString {
        case "sepia": return Color(red: 0.85, green: 0.74, blue: 0.50).opacity(0.55)
        case "gray":  return Color(red: 0.33, green: 0.33, blue: 0.35).opacity(0.55)
        case "custom": return adjustedCustomBackground(by: (customBackgroundLuminance ?? 1) < 0.5 ? 0.12 : -0.08)?.opacity(0.55)
        default:      return nil
        }
    }

    func colorSchemeToString(_ colorScheme: ColorScheme?) -> String {
        switch colorScheme {
        case .light:
            return "light"
        case .dark:
            return "dark"
        default:
            return "system"
        }
    }
}
