import SwiftUI
import CoreLocation
import WidgetKit
import Combine
import os

import Adhan

let logger = Logger(subsystem: AppIdentifiers.bundleIdentifier, category: "Settings")

/// The single source of truth for all user settings.
///
/// **Why everything lives in this one file:** `@AppStorage` / `@Published` are stored property wrappers, and
/// Swift only allows stored properties in a type's primary declaration — never in an extension. So the
/// settings themselves can't be physically moved into separate Quran/Adhan files; the *behavior* that uses
/// them is what's split out, into `SettingsAdhan.swift` (prayer times, notifications, location) and
/// `SettingsQuran.swift` (reciters, bookmarks, khatm, …).
///
/// The declarations below are grouped, in order, into the four buckets:
///   1. **App Group** — `@Published`, mirrored into `appGroupUserDefaults` so widgets/extensions see them.
///   2. **App Storage — Adhan/Prayer** — `@AppStorage` prayer state, notifications, travel, calculation.
///   3. **App Storage — Quran** — `@AppStorage` reciter, favorites, sajdah/muqatta'at, bookmarks, khatm.
///   4. **App Storage — Arabic/Names + appearance/misc** — fonts, themes, haptics, color scheme.
/// Keep new settings in the matching section (and storage mechanism) so the split stays clean.
final class Settings: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = Settings()
    private let appGroupUserDefaults = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)
    @Published private(set) var isReadyForUI = false

    /// Decoded `prayers` cache so the `prayers` computed property doesn't re-run a full JSON decode on every
    /// read (it's read several times per `fetchPrayerTimes`, which itself runs multiple times at launch).
    /// Main-thread only — invalidated whenever `prayersData` changes; off-main reads decode directly to avoid
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
        self.accentColor = AccentColor(rawValue: appGroupUserDefaults?.string(forKey: "accentColor") ?? AppIdentifiers.mainColorString) ?? AppIdentifiers.mainColor
        self.customAccentColorHex = appGroupUserDefaults?.string(forKey: "customAccentColorHex") ?? "34C759"
        self.customBackgroundColorHex = appGroupUserDefaults?.string(forKey: "customBackgroundColorHex") ?? "1C1C1E"

        self.prayersData = appGroupUserDefaults?.data(forKey: "prayersData") ?? Data()
        self.travelingMode = appGroupUserDefaults?.bool(forKey: "travelingMode") ?? false
        self.hanafiMadhab = appGroupUserDefaults?.bool(forKey: "hanafiMadhab") ?? false
        self.prayerCalculation = appGroupUserDefaults?.string(forKey: "prayerCalculation") ?? "Muslim World League"
        self.hijriOffset = appGroupUserDefaults?.integer(forKey: "hijriOffset") ?? 0

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

        runQuranStartupMigrations()
        isReadyForUI = true

        // Defer CoreLocation + NWPathMonitor startup off the synchronous init/first-paint path. Settings.shared
        // is created during @main's @StateObject init, before the first frame; kicking off authorization,
        // significant-location monitoring, and a location request right there competes with first paint (and,
        // on first launch, throws the permission dialog up before the UI is even visible). The stored
        // currentLocation (decoded above) is enough for the launch fetch; this refreshes it a tick later.
        DispatchQueue.main.async { [weak self] in
            self?.requestLocationAuthorization()
        }
    }

    func waitUntilReady() async {
        while true {
            let isReady = await MainActor.run { self.isReadyForUI }
            if isReady { return }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    /// Restores every *preference* (appearance, prayer, and Quran options) to its default while keeping the
    /// user's content. We wipe the app's standard-defaults domain — which clears all the `@AppStorage`
    /// preferences in one shot — but first snapshot the content keys and write them back afterward, then
    /// reset the app-group-backed `@Published` preferences (accent, calculation, madhab, traveling, Hijri
    /// offset) to their defaults via their setters so the shared store + widgets update too. Location and
    /// other app-group content are left untouched.
    @MainActor
    func resetAllSettings() {
        // Bookmarks, favorites, khatm progress, saved reading/listening positions, and search history are
        // content, not settings — preserve them across the domain wipe.
        let contentKeys = [
            "favoriteSurahsData", "bookmarkedAyahsData", "favoriteLetterData", "favoriteNameNumbersData",
            "khatmCompletedAyahsData", "favoriteReciterIDsData", "favoriteQiraahTagsData",
            "favoriteEnglishTranslationIDsData", "savedSajdahAyahIDsData", "savedBrokenLetterAyahIDsData",
            "lastReadSurah", "lastReadAyah", "lastListenedAyahData", "lastListenedSurahData",
            "quranSearchHistoryData",
        ]

        let standard = UserDefaults.standard
        let preserved = contentKeys.reduce(into: [String: Any]()) { dict, key in
            if let value = standard.object(forKey: key) { dict[key] = value }
        }

        if let bundleID = Bundle.main.bundleIdentifier {
            standard.removePersistentDomain(forName: bundleID)
        }

        for (key, value) in preserved {
            standard.set(value, forKey: key)
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

        objectWillChange.send()
        updateDates()
        fetchPrayerTimes(force: true)
        #if os(iOS) || os(watchOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    // MARK: - App group — shared with widgets / extensions

    @Published var accentColor: AccentColor {
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            appGroupUserDefaults?.setValue(accentColor.rawValue, forKey: "accentColor")
        }
    }

    /// Hex ("RRGGBB") backing `AccentColor.custom`, set via the Appearance color picker.
    @Published var customAccentColorHex: String {
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            appGroupUserDefaults?.setValue(customAccentColorHex, forKey: "customAccentColorHex")
        }
    }

    /// Hex ("RRGGBB") of the user-picked app background, used when the "custom" color theme is active. Kept
    /// `@Published` (not `@AppStorage`) so dragging the color picker updates the background live everywhere.
    @Published var customBackgroundColorHex: String {
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            appGroupUserDefaults?.setValue(customBackgroundColorHex, forKey: "customBackgroundColorHex")
        }
    }


    @Published var prayersData: Data {
        didSet {
            cachedPrayersValid = false   // backing bytes changed — drop the decoded cache
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            if !prayersData.isEmpty {
                appGroupUserDefaults?.setValue(prayersData, forKey: "prayersData")
            }
        }
    }

    var prayers: Prayers? {
        get {
            // Off the main thread (e.g. a background-refresh decode), don't touch the shared cache — just
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
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            appGroupUserDefaults?.setValue(travelingMode, forKey: "travelingMode")
        }
    }

    @Published var currentLocation: Location? {
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
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
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
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
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
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
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            appGroupUserDefaults?.setValue(hanafiMadhab, forKey: "hanafiMadhab")
        }
    }

    @Published var prayerCalculation: String {
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            appGroupUserDefaults?.setValue(prayerCalculation, forKey: "prayerCalculation")
        }
    }

    @Published var hijriOffset: Int {
        didSet {
            guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return }
            appGroupUserDefaults?.setValue(hijriOffset, forKey: "hijriOffset")
        }
    }

    // MARK: - Prayer — live state & hijri (app-storage persistence)

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
        let currentHijriYear = hijriCalendar.component(.year, from: effectiveHijriReferenceDate())
        return [
            ("Islamic New Year", DateComponents(year: currentHijriYear, month: 1, day: 1), "Start of Hijri year", "The first day of the Islamic calendar; no special acts of worship or celebration are prescribed."),
            ("Day Before Ashura", DateComponents(year: currentHijriYear, month: 1, day: 9), "Recommended to fast", "The Prophet ﷺ intended to fast the 9th to differ from the Jews, making it Sunnah to do so before Ashura."),
            ("Day of Ashura", DateComponents(year: currentHijriYear, month: 1, day: 10), "Recommended to fast", "Ashura marks the day Allah saved Musa (Moses) and the Israelites from Pharaoh; fasting expiates sins of the previous year."),

            ("First Day of Ramadan", DateComponents(year: currentHijriYear, month: 9, day: 1), "Begin obligatory fast", "The month of fasting begins; all Muslims must fast from Fajr (dawn) to Maghrib (sunset)."),
            ("Last 10 Nights of Ramadan", DateComponents(year: currentHijriYear, month: 9, day: 21), "Seek Laylatul Qadr", "The most virtuous nights of the year; increase worship as these nights are beloved to Allah and contain Laylatul Qadr."),
            ("27th Night of Ramadan", DateComponents(year: currentHijriYear, month: 9, day: 27), "Likely Laylatul Qadr", "A strong possibility for Laylatul Qadr — the Night of Decree when the Qur’an was sent down — though not confirmed."),
            ("Eid Al-Fitr", DateComponents(year: currentHijriYear, month: 10, day: 1), "Celebration of ending the fast", "Celebration marking the end of Ramadan; fasting is prohibited on this day; encouraged to fast 6 days in Shawwal."),

            ("First 10 Days of Dhul-Hijjah", DateComponents(year: currentHijriYear, month: 12, day: 1), "Most beloved days", "The best days for righteous deeds; fasting and dhikr are highly encouraged."),
            ("Beginning of Hajj", DateComponents(year: currentHijriYear, month: 12, day: 8), "Pilgrimage begins", "Pilgrims begin the rites of Hajj, heading to Mina to start the sacred journey."),
            ("Day of Arafah", DateComponents(year: currentHijriYear, month: 12, day: 9), "Recommended to fast", "Fasting for non-pilgrims expiates sins of the past and coming year."),
            ("Eid Al-Adha", DateComponents(year: currentHijriYear, month: 12, day: 10), "Celebration of sacrifice during Hajj", "The day of sacrifice; fasting is not allowed and sacrifice of an animal is offered."),
            ("End of Eid Al-Adha", DateComponents(year: currentHijriYear, month: 12, day: 13), "Hajj and Eid end", "Final day of Eid Al-Adha; pilgrims and non-pilgrims return to daily life."),
        ]
    }

    @AppStorage("lastScheduledHijriYear") private var lastScheduledHijriYear: Int = 0

    // MARK: - Prayer — @AppStorage (notifications, travel, calculation, alerts)

    @AppStorage("dateNotifications") var dateNotifications = true {
        didSet { self.fetchPrayerTimes(notification: true) }
    }

    @AppStorage("switchHijriDateAtMaghrib") var switchHijriDateAtMaghrib: Bool = false {
        didSet { self.updateDates() }
    }

    @AppStorage("naggingMode") var naggingMode: Bool = false {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("naggingStartOffset") var naggingStartOffset: Int = 30 {
        didSet { self.fetchPrayerTimes(notification: true) }
    }
    @AppStorage("adhanNotificationSound") var adhanNotificationSound: String = "egypt-30" {
        didSet { self.fetchPrayerTimes(notification: true) }
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
    @AppStorage("offsetFajr") var offsetFajr: Int = 0 {
        didSet { self.fetchPrayerTimes(force: true) }
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
        didSet { self.fetchPrayerTimes(force: true) }
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
        didSet { self.fetchPrayerTimes(force: true) }
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
        didSet { self.fetchPrayerTimes(force: true) }
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
        didSet { self.fetchPrayerTimes(force: true) }
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
        didSet { self.fetchPrayerTimes(force: true) }
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
    /// Set by the UI when the user toggles Traveling Mode; fetchPrayerTimes skips checkIfTraveling once so we don’t override or notify.
    var travelingModeManuallyToggled: Bool = false

    @AppStorage("calculationAutomatic") var calculationAutomatic: Bool = true
    @AppStorage("calculationAutoChanged") var calculationAutoChanged: Bool = false
    @AppStorage("calculationAutoPreviousMethod") var calculationAutoPreviousMethod: String = ""
    @AppStorage("calculationAutoDetectedMethod") var calculationAutoDetectedMethod: String = ""
    @AppStorage("calculationAutoDetectedCountryCode") var calculationAutoDetectedCountryCode: String = ""
    @AppStorage("currentCountryCode") var currentCountryCode: String = ""
    /// Set by the UI when the user manually picks a method while automatic mode is enabled.
    var calculationManuallyToggled: Bool = false

    @AppStorage("showLocationAlert") var showLocationAlert: Bool = false {
        willSet { objectWillChange.send() }
    }
    @AppStorage("showNotificationAlert") var showNotificationAlert: Bool = false

    @AppStorage("locationNeverAskAgain") var locationNeverAskAgain = false
    @AppStorage("notificationNeverAskAgain") var notificationNeverAskAgain = false

    @AppStorage("showPrayerInfo") var showPrayerInfo: Bool = false

    // MARK: - Optional Prayer Times (shown in app only, never in widgets)

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

    // MARK: - Quran — @AppStorage

    /// Big vs. small in-app Now Playing player. An in-app UI preference, not shared with the widget/watch.
    @AppStorage("nowPlayingExpanded") var nowPlayingExpanded: Bool = false

    @AppStorage("reciter") var reciter: String = "Muhammad Al-Minshawi (Murattal)"

    /// Disambiguates reciters that share the same display name (qiraah / surah base URL).
    @AppStorage("reciterId") var reciterId: String = ""

    @AppStorage("favoriteReciterIDsData") private var favoriteReciterIDsData = Data()
    var favoriteReciterIDs: [String] {
        get {
            (try? Self.decoder.decode([String].self, from: favoriteReciterIDsData)) ?? []
        }
        set {
            let normalized = Array(NSOrderedSet(array: newValue.compactMap {
                let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? nil : trimmed
            })) as? [String] ?? []
            favoriteReciterIDsData = (try? Self.encoder.encode(normalized)) ?? Data()
        }
    }

    @AppStorage("favoriteQiraahTagsData") private var favoriteQiraahTagsData = Data()
    var favoriteQiraahTags: [String] {
        get {
            (try? Self.decoder.decode([String].self, from: favoriteQiraahTagsData)) ?? []
        }
        set {
            let normalized = Array(NSOrderedSet(array: newValue.map(Self.normalizeLegacyRiwayahTag))) as? [String] ?? []
            favoriteQiraahTagsData = (try? Self.encoder.encode(normalized)) ?? Data()
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
    var favoriteSurahs: [Int] {
        get {
            (try? Self.decoder.decode([Int].self, from: favoriteSurahsData)) ?? []
        }
        set {
            favoriteSurahsData = (try? Self.encoder.encode(newValue)) ?? Data()
        }
    }

    @AppStorage("khatmCompletedAyahsData") var khatmCompletedAyahsData = Data()
    @AppStorage("automaticKhatmCompletion") var automaticKhatmCompletion = true
    var khatmCompletedAyahSetCache: Set<String> = []
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

    @AppStorage("bookmarkedAyahsData") private var bookmarkedAyahsData = Data()
    var bookmarkedAyahs: [BookmarkedAyah] {
        get {
            (try? Self.decoder.decode([BookmarkedAyah].self, from: bookmarkedAyahsData)) ?? []
        }
        set {
            bookmarkedAyahsData = (try? Self.encoder.encode(newValue)) ?? Data()
        }
    }

    @AppStorage("showBookmarks") var showBookmarks = true
    @AppStorage("showFavorites") var showFavorites = true
    /// One master grid toggle (driven by the toolbar button) for every list on the Quran tab except the
    /// summary: bookmarked ayahs, favorite surahs, and the surah / juz browse list.
    @AppStorage("quranGridMode") var quranGridMode = false
    /// Shows the spelled-out pronunciation aid above muqatta'at ayahs (e.g. أَلِفۡ لَآم مِيٓمۡ). Off by default.
    @AppStorage("showMuqattaatHelper") var showMuqattaatHelper = false

    @AppStorage("shareShowAyahInformation") var showAyahInformation: Bool = true
    @AppStorage("shareShowSurahInformation") var showSurahInformation: Bool = false

    @AppStorage("beginnerMode") var beginnerMode: Bool = false

    @AppStorage("quranSortMode") var quranSortModeRaw: String = QuranSortMode.surah.rawValue
    @AppStorage("quranSortDirection") var quranSortDirectionRaw: String = QuranSortDirection.ascending.rawValue

    var quranSortMode: QuranSortMode {
        get { QuranSortMode(rawValue: quranSortModeRaw) ?? .surah }
        set { quranSortModeRaw = newValue.rawValue }
    }

    var quranSortDirection: QuranSortDirection {
        get { QuranSortDirection(rawValue: quranSortDirectionRaw) ?? .ascending }
        set { quranSortDirectionRaw = newValue.rawValue }
    }

    var groupBySurah: Bool { quranSortMode == .surah }
    /// In Khatm mode, the Surah/Juz toggle (which replaces the Asc/Desc control). When on, surahs are grouped
    /// under juz headers, each surah shown once in the juz it *starts* in — so juz that no surah opens (e.g.
    /// juz 2, 5) appear empty.
    @AppStorage("khatmGroupByJuz") var khatmGroupByJuz: Bool = false
    @AppStorage("searchForSurahs") var searchForSurahs: Bool = true
    @AppStorage("ignoreSilentLettersInQuranSearch") var ignoreSilentLettersInQuranSearch: Bool = true

    @AppStorage("lastReadSurah") var lastReadSurah: Int = 0
    @AppStorage("lastReadAyah") var lastReadAyah: Int = 0

    /// When off, the app neither saves nor shows the "Last Read Ayah" / "Last Listened Surah" sections.
    @AppStorage("saveLastReadAyah") var saveLastReadAyah: Bool = true
    @AppStorage("saveLastListenedSurah") var saveLastListenedSurah: Bool = true
    /// When off, the app neither saves nor shows the "Last Listened Ayah" section.
    @AppStorage("saveLastListenedAyah") var saveLastListenedAyah: Bool = true
    /// When on, the Quran tab shows the daily "Ayah of the Day" card.
    @AppStorage("showAyahOfTheDay") var showAyahOfTheDay: Bool = true
    /// When on, the Quran tab collapses the Ayah of the Day / Last Listened / Last Read cards into one
    /// compact section of tiles. On by default.
    @AppStorage("quranSummaryMode") var quranSummaryMode: Bool = true
    /// Day key (yyyy-MM-dd) for which the Ayah of the Day card has been hidden via "Hide for Today".
    @AppStorage("ayahOfTheDayHiddenDate") var ayahOfTheDayHiddenDate: String = ""

    @AppStorage("lastListenedAyahData") private var lastListenedAyahData: Data?
    var lastListenedAyah: LastListenedAyah? {
        get {
            guard let data = lastListenedAyahData else { return nil }
            do {
                return try Self.decoder.decode(LastListenedAyah.self, from: data)
            } catch {
                logger.debug("Failed to decode last listened ayah: \(error)")
                return nil
            }
        }
        set {
            if let newValue = newValue {
                do {
                    lastListenedAyahData = try Self.encoder.encode(newValue)
                } catch {
                    logger.debug("Failed to encode last listened ayah: \(error)")
                }
            } else {
                lastListenedAyahData = nil
            }
        }
    }

    @AppStorage("lastListenedSurahData") private var lastListenedSurahData: Data?
    var lastListenedSurah: LastListenedSurah? {
        get {
            guard let data = lastListenedSurahData else { return nil }
            do {
                return try Self.decoder.decode(LastListenedSurah.self, from: data)
            } catch {
                logger.debug("Failed to decode last listened surah: \(error)")
                return nil
            }
        }
        set {
            if let newValue = newValue {
                do {
                    lastListenedSurahData = try Self.encoder.encode(newValue)
                } catch {
                    logger.debug("Failed to encode last listened surah: \(error)")
                }
            } else {
                lastListenedSurahData = nil
            }
        }
    }

    /// Which qiraah/riwayah to show for Arabic text. Empty or "Hafs" = Hafs an Asim (default). Transliteration and translations only apply to Hafs.
    @AppStorage("displayQiraah") var displayQiraah: String = ""

    /// When on, SurahView shows a qiraat picker above the search bar to compare riwayat in that view.
    @AppStorage("qiraatComparisonMode") var qiraatComparisonMode: Bool = false

    /// When on, ReciterListView reveals non-Hafs qiraat reciters.
    @AppStorage("showOtherQiraatReciters") var showOtherQiraatReciters: Bool = false

    /// Shared expand/collapse state for qiraah details in Quran settings and reciter lists.
    var showQiraahDetails: Bool {
        get { showOtherQiraatReciters }
        set { showOtherQiraatReciters = newValue }
    }

    /// Pass to Ayah.displayArabic(qiraah:clean:). Nil means Hafs.
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

    @AppStorage("showArabicText") var showArabicText: Bool = true
    @AppStorage("highlightAllahNames") var highlightAllahNames: Bool = false
    @AppStorage("showTajweedColors") var showTajweedColors: Bool = false
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
    var quranSearchHistory: [String] {
        get {
            (try? Self.decoder.decode([String].self, from: quranSearchHistoryData)) ?? []
        }
        set {
            quranSearchHistoryData = (try? Self.encoder.encode(Array(newValue.prefix(10)))) ?? Data()
        }
    }

    @AppStorage("englishFontSize") var englishFontSize: Double = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)

    // MARK: - Arabic letters & 99 Names
    
    @AppStorage("THEfontArabic") var fontArabic: String = "KFGQPCHAFSUthmanicScript-Regula"
    @AppStorage("fontArabicSize") var fontArabicSize: Double = Double(UIFont.preferredFont(forTextStyle: .title1).pointSize)
    @AppStorage("useFontArabic") var useFontArabic = true

    @AppStorage("favoriteLetterData") private var favoriteLetterData = Data()
    var favoriteLetters: [LetterData] {
        get {
            (try? Self.decoder.decode([LetterData].self, from: favoriteLetterData)) ?? []
        }
        set {
            favoriteLetterData = (try? Self.encoder.encode(newValue)) ?? Data()
        }
    }
    
    func toggleLetterFavorite(letterData: LetterData) {
        withAnimation {
            if isLetterFavorite(letterData: letterData) {
                favoriteLetters.removeAll(where: { $0.id == letterData.id })
            } else {
                favoriteLetters.append(letterData)
            }
        }
    }

    func isLetterFavorite(letterData: LetterData) -> Bool {
        favoriteLetters.contains { $0.id == letterData.id }
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
    
    // MARK: Arabic search normalization

    func cleanSearch(_ text: String, whitespace: Bool = false) -> String {
        // Single scalar walk: fold each Arabic scalar through the canonical map (dagger alif → alif, hamza
        // carriers → bare letters, teh marbuta → heh, …) and drop unwanted punctuation/marks in the SAME
        // pass. Replaces the old 22 sequential `replacingOccurrences` scans (each a full-string pass +
        // allocation) plus a separate filter pass — this runs on every keystroke query and ~7×/ayah during
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

    func cleanSearchIgnoringSilentArabicLetters(_ text: String, whitespace: Bool = false) -> String {
        cleanSearch(text.removingSilentArabicLettersForSearch, whitespace: whitespace)
    }

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
        "ى": "ا", // alif maqsurah -> alif (matches both ى and ا forms in search)
        // Teh marbuta equivalence (broad)
        "ة": "ه"
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
    
    // MARK: - App-wide appearance & misc @AppStorage

    @AppStorage("THEfirstLaunch") var firstLaunch = true

    @AppStorage("hapticOn") var hapticOn: Bool = true

    @AppStorage("defaultView") var defaultView: Bool = true

    @AppStorage("colorSchemeString") var colorSchemeString: String = "system"
    var colorScheme: ColorScheme? {
        get {
            colorSchemeFromString(colorSchemeString)
        }
        set {
            colorSchemeString = colorSchemeToString(newValue)
        }
    }

    // MARK: - Global helpers (not Quran- or Adhan-specific)

    func hapticFeedback() {
        #if os(iOS)
        if hapticOn { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
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

    // MARK: - Reading themes (Sepia / Gray)
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
