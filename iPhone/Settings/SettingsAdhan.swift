import SwiftUI
import Adhan
import CoreLocation
import Network
import UserNotifications
import WidgetKit
import WatchConnectivity

struct AdhanSoundOption: Identifiable, Equatable {
    let id: String
    let title: String
}

extension Settings {
    /// Each adhan ships as three clips: `<id>.caf` (the whole adhan), `<id>-30.caf` (its opening 30 seconds)
    /// and `<id>-short.caf` (a 5–15 second excerpt). iOS rejects notification sounds longer than 30 seconds,
    /// so a notification gets one of the two cuts - which one is a per-prayer choice - while in-app playback
    /// and the settings preview get the full recording.
    static let supportedAdhanSounds: [AdhanSoundOption] = [
        .init(id: "default", title: "Default"),
        // A 3.6-second chime, not a call to prayer - for being told without being called. All three of its
        // clips are the same recording, because there is nothing to cut down.
        .init(id: "echo", title: "Echo"),

        .init(id: "egypt", title: "Egypt"),
        .init(id: "makkah", title: "Makkah"),
        .init(id: "madina", title: "Madina"),
        .init(id: "alaqsa", title: "Al-Aqsa"),
        .init(id: "alaqsa-2", title: "Al-Aqsa 2"),

        .init(id: "abdulbaset", title: "Abdul Baset"),
        .init(id: "abdulghaffar", title: "Abdul Ghaffar"),
        .init(id: "al-qatami", title: "Al-Qatami"),
        // The two Minshawi recordings are SWAPPED relative to their clip names: the one bundled as
        // `minshawi-2.caf` is the one titled "Minshawi 1", and vice versa. The titles moved, the ids did
        // not - an id is what a selection is stored as, so renaming the ids (or the .caf files) would have
        // silently handed every existing listener the other recording. Listed in title order so the picker
        // still reads 1 then 2.
        .init(id: "minshawi-2", title: "Minshawi 1"),
        .init(id: "minshawi-1", title: "Minshawi 2"),
        .init(id: "zakariya", title: "Zakariya")
    ]

    /// The adhan a fresh install gets: whichever clip is *titled* "Minshawi 1", which after the swap above
    /// is the one bundled as `minshawi-2`.
    static let defaultAdhanSoundID = "minshawi-2"
    static let adhanNotificationClipSuffix = "-30"
    static let adhanShortClipSuffix = "-short"

    /// Which cut of the adhan a prayer's notification plays. Both fit inside iOS's 30-second ceiling.
    enum AdhanClipLength {
        case full, short
        var suffix: String {
            switch self {
            case .full: return Settings.adhanNotificationClipSuffix
            case .short: return Settings.adhanShortClipSuffix
            }
        }
    }

    /// Per-prayer opt-in to the short cut. Prayers with no toggle of their own - Friday's Jumuah and the
    /// traveling-mode pairs - inherit from whichever prayer owns their notification preferences, matching
    /// how `notifTable` already routes them.
    func adhanClipLength(forPrayer transliteration: String) -> AdhanClipLength {
        let useShort: Bool
        switch transliteration {
        case "Fajr":                          useShort = shortAdhanFajr
        case "Dhuhr", "Jumuah", "Dhuhr/Asr":  useShort = shortAdhanDhuhr
        case "Asr":                           useShort = shortAdhanAsr
        case "Maghrib", "Maghrib/Isha":       useShort = shortAdhanMaghrib
        case "Isha":                          useShort = shortAdhanIsha
        default:                              useShort = false
        }
        return useShort ? .short : .full
    }

    /// Whether this prayer's at-time notification carries the chosen adhan, or just the system sound.
    /// Routed the same way as `adhanClipLength`, so Jumuah and the traveling pairs follow their base prayer.
    func playsAdhanSound(forPrayer transliteration: String) -> Bool {
        switch transliteration {
        case "Fajr":                          return adhanSoundFajr
        case "Dhuhr", "Jumuah", "Dhuhr/Asr":  return adhanSoundDhuhr
        case "Asr":                           return adhanSoundAsr
        case "Maghrib", "Maghrib/Isha":       return adhanSoundMaghrib
        case "Isha":                          return adhanSoundIsha
        // Shurooq and the optional times never carry an adhan; `prayerNotificationSound` already returns
        // `.default` for them before this is consulted.
        default:                              return false
        }
    }

    static let supportedAdhanSoundIDs = Set(supportedAdhanSounds.map(\.id))
    private static var adhanSoundResourceCache: [String: String?] = [:]

    /// Resolves a picker id to a bundled `.caf` resource name, or `nil` for "Default" and for any id whose
    /// clip is missing from the bundle. `variant` picks the full recording ("") or the 30-second cut.
    private func adhanSoundResource(for selection: String, variant: String) -> String? {
        // The static cache is a plain Dictionary; every current caller is main-confined and this keeps
        // that invariant enforced rather than remembered.
        assert(Thread.isMainThread, "adhanSoundResource(for:variant:) must be called on the main thread")
        let resource = selection + variant
        if let cached = Self.adhanSoundResourceCache[resource] {
            return cached
        }

        let resolved: String? = {
            guard selection != "default",
                  Self.supportedAdhanSoundIDs.contains(selection),
                  Bundle.main.path(forResource: resource, ofType: "caf") != nil else {
                return nil
            }
            return resource
        }()

        Self.adhanSoundResourceCache[resource] = resolved
        return resolved
    }

    /// Resource name (no extension) of the full-length adhan, for in-app playback and the preview button.
    func adhanFullSoundResource(for selection: String) -> String? {
        adhanSoundResource(for: selection, variant: "")
    }

    /// Filename of the notification cut, for `UNNotificationSound`. Falls back to the 30-second cut when the
    /// requested short clip isn't bundled, so a missing asset degrades to a longer adhan rather than silence.
    func adhanNotificationSoundFilename(for selection: String, length: AdhanClipLength = .full) -> String? {
        let resource = adhanSoundResource(for: selection, variant: length.suffix)
            ?? adhanSoundResource(for: selection, variant: Self.adhanNotificationClipSuffix)
        return resource.map { "\($0).caf" }
    }

    /// Repairs a selection stored by an older build, or pushed over by a Watch still running one: ids used
    /// to carry the `-30` suffix of the notification clip, and now name the adhan itself.
    static func normalizedAdhanSoundID(_ stored: String) -> String {
        let base = stored.hasSuffix(adhanNotificationClipSuffix)
            ? String(stored.dropLast(adhanNotificationClipSuffix.count))
            : stored
        return supportedAdhanSoundIDs.contains(base) ? base : defaultAdhanSoundID
    }

    func normalizeAdhanSoundSelection() {
        let normalized = Self.normalizedAdhanSoundID(adhanNotificationSound)
        if normalized != adhanNotificationSound {
            adhanNotificationSound = normalized
        }
    }

    private static let didAdoptMinshawiDefaultKey = "didAdoptMinshawiAdhanDefault"

    /// One-time startup migrations for the adhan sound selection. These write straight to `UserDefaults`
    /// (where `@AppStorage` reads from) instead of going through the property, so they can run inside
    /// `Settings.init` without the `didSet` kicking off a prayer-time refresh mid-initialization.
    func runAdhanSoundStartupMigrations() {
        let defaults = UserDefaults.standard
        let key = "adhanNotificationSound"

        if let stored = defaults.string(forKey: key) {
            let normalized = Self.normalizedAdhanSoundID(stored)
            if normalized != stored {
                defaults.set(normalized, forKey: key)
            }
        }

        // Minshawi 1 became the app's adhan. Adopt it once for everyone, including users who had already
        // picked something else, then never touch the choice again - the flag is what keeps a later re-pick
        // from being stomped on the next launch.
        if !defaults.bool(forKey: Self.didAdoptMinshawiDefaultKey) {
            defaults.set(true, forKey: Self.didAdoptMinshawiDefaultKey)
            // An explicit prior choice is NEVER overwritten. The old behavior force-adopted Minshawi 1
            // over whatever was stored - so a user who had deliberately chosen "Default" tapped a
            // notification, the relaunch ran this migration, and their selection silently became
            // Minshawi 1. A device that never set the key already resolves to `defaultAdhanSoundID`
            // through the `@AppStorage` default, which is all the adoption this migration ever needed.
            //
            // Nor is there a migration for the title swap above: anyone already listening to a Minshawi
            // adhan keeps the exact recording they picked (the ids never moved). It is now labelled with
            // the other number in the picker, which is the point of the swap.
        }
    }

    /// Accuracy while simply tracking where you are. 100 m costs a fraction of the power of `Best` (which
    /// pins the GPS chip), and is far finer than prayer times need: 100 m of longitude shifts solar noon by
    /// about a quarter of a second, and the Qibla bearing by a rounding error. `Best` is switched on only for
    /// the bounded refinement burst in `beginLocationRefinement`.
    static let restingAccuracy = kCLLocationAccuracyHundredMeters

    static let locationManager: CLLocationManager = {
        let lm = CLLocationManager()
        lm.desiredAccuracy = restingAccuracy
        lm.distanceFilter = halfMile
        return lm
    }()

    // MARK: - Location accuracy / refinement state
    //
    // iOS uses coarse significant-location-change monitoring in the background (battery friendly), so a
    // single, possibly-rough fix tends to "stick" while you stay in one place. When an accuracy-sensitive
    // view is open we briefly switch to high-accuracy continuous updates to lock in the exact spot, then
    // stop. While actually moving (road trip / walk / flight) we throttle commits so prayer times and the
    // city label don't churn on every cell-tower hop.
    private static var isRefiningLocation = false
    private static var refinementStartedAt: Date?
    private static var refinementTimeout: DispatchWorkItem?
    private static var lastFixAccuracy: CLLocationDistance?

    private static let lastFixAtKey = "lastLocationFixAt"
    /// When the last location fix was committed. Persisted (app group), so a cold launch in airplane
    /// mode knows how old the saved city label really is instead of assuming it's current.
    private static var lastLocationCommitAt: Date? {
        get { anchorStore?.object(forKey: lastFixAtKey) as? Date }
        set {
            guard let store = anchorStore else { return }
            if let newValue {
                store.set(newValue, forKey: lastFixAtKey)
            } else {
                store.removeObject(forKey: lastFixAtKey)
            }
        }
    }

    /// Stop the high-accuracy burst once a fix this good arrives.
    private static let refinementTargetAccuracy: CLLocationDistance = 12   // m
    /// Hard cap on how long the burst runs, in case a good fix never arrives.
    private static let refinementMaxDuration: TimeInterval = 25            // s
    /// The cap actually in force for the current burst (offline acquisition uses a longer one).
    private static var activeRefinementMaxDuration: TimeInterval = refinementMaxDuration
    /// Offline (airplane-mode) GPS acquisition burst cap. A one-shot `requestLocation` almost never
    /// locks without network assistance data - unassisted GPS needs continuous acquisition time, and a
    /// cold start can take a minute. This is why a whole flight used to pass with zero fixes.
    private static let offlineAcquisitionMaxDuration: TimeInterval = 90    // s
    /// Ignore sub-jitter coordinate changes when refining in place.
    private static let refineMinMove: CLLocationDistance = 8               // m
    /// While moving, don't recompute more often than this even past the distance threshold.
    private static let movingCommitMinInterval: TimeInterval = 30          // s
    /// Refinements that move at least this far also recompute prayer times (smaller moves don't matter).
    private static let prayerRecomputeDistance: CLLocationDistance = 75    // m
    
    private static let geocoder = CLGeocoder()
    private static var cachedPlacemark: (coord: CLLocationCoordinate2D, city: String, countryCode: String)?
    private struct RawPrayerCacheKey: Hashable {
        let year: Int
        let month: Int
        let day: Int
        let latitude: Double
        let longitude: Double
        let calculation: String
        let hanafiMadhab: Bool
        let highLatitudeRule: String
        let offsets: [Int]
    }

    private static var rawPrayerCache: [RawPrayerCacheKey: [Prayer]] = [:]
    /// Insertion order for LRU eviction. Room for a couple of rendered calendar months plus the
    /// countdown/widget days: a `[Prayer]` is a handful of tiny structs, so 96 entries is a few KB.
    /// Eviction drops only the OLDEST entry - the old cap-10 `removeAll` wipe meant a month calendar
    /// render thrashed the cache to zero hits and even evicted *today* out from under the countdown.
    private static var rawPrayerCacheOrder: [RawPrayerCacheKey] = []
    private static let rawPrayerCacheLimit = 96

    /// Drops memoized prayer times. Needed when something that is *baked into* a cached `Prayer` changes but
    /// isn't part of the cache key - custom prayer names, which alter the struct without altering the times.
    static func invalidatePrayerComputationCache() {
        rawPrayerCache.removeAll(keepingCapacity: true)
        rawPrayerCacheOrder.removeAll(keepingCapacity: true)
    }
    private static let geocodeActor = GeocodeActor()
    private static let networkMonitor = NWPathMonitor()
    private static let networkMonitorQueue = DispatchQueue(label: AppIdentifiers.networkMonitorQueueLabel)
    private static var didStartNetworkMonitor = false
    private static var isNetworkReachable = true
    private static var pendingGeocodeCoord: CLLocationCoordinate2D?
    
    private static let oneMile: CLLocationDistance = 1609.34   // m
    private static let halfMile: CLLocationDistance = 500      // m
    private static let maxAge: TimeInterval = 180              // s
    
    /// The distance from home at which prayers may be shortened (qasr). 48 miles is the classical
    /// two-marhalah threshold. The single source of truth - `checkIfTraveling` compares against this, and
    /// nothing else should restate the number.
    static let travelThresholdM: CLLocationDistance = 48 * oneMile   // ≈ 77 249 m

    /// How far back inside the threshold you must come before traveling mode switches itself OFF again. Kept to
    /// a single mile: enough that GPS jitter alone can't flip the mode back and forth on the 48-mile line, small
    /// enough that the threshold stays essentially exact.
    static let travelHysteresisM: CLLocationDistance = 1 * oneMile   // ≈ 1 609 m

    /// The auto-toggle can't notify more often than this, whatever the location does. A backstop for the case
    /// hysteresis can't cover: genuinely crossing back and forth over the line (a commute that straddles it).
    static let travelNotifyCooldown: TimeInterval = 30 * 60

    /// How far you can be from where a city name was *resolved* and still plausibly be in that city. Wide
    /// enough to cover a large metro area and a commute across it; narrow enough that a long drive, or the
    /// first hour of a flight, stops the app from claiming you are somewhere you left.
    private static let sameCityRadius: CLLocationDistance = 25_000   // 25 km ≈ 15.5 mi

    private static let cityAnchorLatitudeKey = "cityAnchorLatitude"
    private static let cityAnchorLongitudeKey = "cityAnchorLongitude"
    private static let anchorStore = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)

    /// The coordinate at which the current city label was last resolved by the geocoder. Persisted, so a cold
    /// launch in airplane mode still knows whether the saved city name is still true.
    private static var cityAnchor: CLLocation? {
        get {
            guard let store = anchorStore, store.object(forKey: cityAnchorLatitudeKey) != nil else { return nil }
            return CLLocation(latitude: store.double(forKey: cityAnchorLatitudeKey),
                              longitude: store.double(forKey: cityAnchorLongitudeKey))
        }
        set {
            guard let store = anchorStore else { return }
            guard let newValue else {
                store.removeObject(forKey: cityAnchorLatitudeKey)
                store.removeObject(forKey: cityAnchorLongitudeKey)
                return
            }
            store.set(newValue.coordinate.latitude, forKey: cityAnchorLatitudeKey)
            store.set(newValue.coordinate.longitude, forKey: cityAnchorLongitudeKey)
        }
    }

    private static func ensureNetworkMonitorStarted() {
        // Extensions (widgets) don't geocode or refetch on reconnect; a path monitor there is pure overhead.
        guard Settings.isAppProcess else { return }
        guard !didStartNetworkMonitor else { return }
        didStartNetworkMonitor = true

        // The handler arrives on the monitor's own queue, but every piece of state it touches
        // (`isNetworkReachable`, `pendingGeocodeCoord`) is read by the main-confined prayer pipeline - so hop
        // to main FIRST and do all reads/writes there. This keeps the entire location/prayer state
        // main-confined, with no cross-thread mutation left anywhere in the pipeline.
        networkMonitor.pathUpdateHandler = { path in
            let isNowReachable = (path.status == .satisfied)
            Task { @MainActor in
                let becameReachable = isNowReachable && !isNetworkReachable
                isNetworkReachable = isNowReachable

                guard becameReachable else { return }

                let pending = pendingGeocodeCoord
                pendingGeocodeCoord = nil
                guard pending != nil else { return }
                // Geocode where we are *now*, not the coordinate that was queued when the signal dropped.
                // `updateCity` writes the coordinates it is handed straight into `currentLocation`, so feeding
                // it the stale one would teleport a passenger who lost signal over the Atlantic back there the
                // moment their phone reconnects on the ground in Istanbul.
                let coord = Settings.shared.currentLocation.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                } ?? pending!

                // Ask for a fresh fix too: significant-change monitoring leans on cell towers, so a flight in
                // airplane mode delivers no updates at all, and the newest coordinate we hold may be the
                // departure airport.
                Settings.locationManager.requestLocation()

                await Settings.shared.updateCity(latitude: coord.latitude, longitude: coord.longitude)
                Settings.shared.fetchPrayerTimes(force: true)
            }
        }

        networkMonitor.start(queue: networkMonitorQueue)
    }

    private func queueGeocodeForReconnect(_ coord: CLLocationCoordinate2D) {
        Self.pendingGeocodeCoord = coord
    }

    private func isNetworkGeocodeError(_ error: Error) -> Bool {
        if let clError = error as? CLError {
            return clError.code == .network
        }

        let nsError = error as NSError
        return nsError.domain == kCLErrorDomain && nsError.code == CLError.Code.network.rawValue
    }
    
    // AUTHORIZATION CHANGES
    func locationManager(_ mgr: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            showLocationAlert = false
            mgr.requestLocation()
            #if os(iOS)
            mgr.startMonitoringSignificantLocationChanges()
            #else
            mgr.startUpdatingLocation()
            #endif
            
        case .denied where !locationNeverAskAgain:
            showLocationAlert = true

        case .restricted, .notDetermined:
            logger.debug("Location authorization is restricted or not determined.")
            break

        default: break
        }
    }
    
    // MAIN LOCATION CALLBACK
    func locationManager(_ mgr: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }

        let isValid = loc.horizontalAccuracy > 0
        let isFresh = abs(loc.timestamp.timeIntervalSinceNow) <= 300
        guard isValid && isFresh else { return }

        if Self.isRefiningLocation {
            commitLocation(loc, refining: true)
            let elapsed = Date().timeIntervalSince(Self.refinementStartedAt ?? Date())
            if loc.horizontalAccuracy <= Self.refinementTargetAccuracy || elapsed >= Self.activeRefinementMaxDuration {
                endLocationRefinement()
            }
        } else {
            commitLocation(loc, refining: false)
        }
    }

    /// Seeds the home location from the current location the first time we have a valid fix.
    /// A freshly installed app - or an existing user who never set a home - automatically adopts the
    /// first location it gets as home, so Traveling Mode and travel-distance work out of the box.
    /// Once a home exists it is never overwritten here.
    @MainActor
    func seedHomeLocationIfNeeded() {
        guard homeLocation == nil,
              let current = currentLocation,
              current.latitude != 1000,
              current.longitude != 1000 else { return }
        withAnimation {
            homeLocation = current
        }
    }

    /// Decide whether a new reading is worth saving, and update only as much as needed.
    /// - `refining`: true during a high-accuracy burst (accept small accuracy improvements in place);
    ///   false for passive significant-change updates while moving (only real, throttled moves commit).
    private func commitLocation(_ loc: CLLocation, refining: Bool) {
        let newCoord = loc.coordinate

        guard let cur = currentLocation else {
            Self.lastLocationCommitAt = Date()
            Self.lastFixAccuracy = loc.horizontalAccuracy
            Task { @MainActor in
                await updateCity(latitude: newCoord.latitude, longitude: newCoord.longitude)
                // Fresh install: now that the first fix has a city, adopt it as home.
                seedHomeLocationIfNeeded()
                fetchPrayerTimes(force: false)
            }
            return
        }

        let prev = CLLocation(latitude: cur.latitude, longitude: cur.longitude)
        let moved = prev.distance(from: loc)

        if refining {
            // Sitting in one place: accept a meaningfully better fix (or a small genuine move) so the
            // saved coordinate converges on the exact spot instead of keeping the first rough fix.
            let moreAccurate = loc.horizontalAccuracy + 5 < (Self.lastFixAccuracy ?? .greatestFiniteMagnitude)
            guard moved >= Self.refineMinMove || moreAccurate else { return }
        } else {
            // Moving: only commit once you've actually relocated, and not more than once per interval,
            // so a road trip / walk / flight doesn't constantly recompute.
            guard moved >= Self.halfMile else { return }
            if let last = Self.lastLocationCommitAt,
               Date().timeIntervalSince(last) < Self.movingCommitMinInterval { return }
        }

        Self.lastLocationCommitAt = Date()
        Self.lastFixAccuracy = loc.horizontalAccuracy

        let cityLikelyChanged = moved >= Self.halfMile
        let shouldRecomputePrayers = !refining || moved >= Self.prayerRecomputeDistance

        Task { @MainActor in
            if cityLikelyChanged {
                await updateCity(latitude: newCoord.latitude, longitude: newCoord.longitude)
            } else {
                // Same place, just a sharper fix - keep the city label, sharpen the coordinates so the
                // Qibla bearing and display use the most accurate position available.
                withAnimation {
                    currentLocation = Location(city: cur.city, latitude: newCoord.latitude, longitude: newCoord.longitude)
                }
            }
            // Existing user with a location but no home yet: adopt the current location as home.
            seedHomeLocationIfNeeded()
            if shouldRecomputePrayers {
                fetchPrayerTimes(force: false)
            }
        }
    }

    /// Briefly switch to high-accuracy continuous updates to lock in a precise fix, then auto-stop.
    /// Call when an accuracy-sensitive view appears (Qibla / prayer times). Bounded by accuracy target
    /// and a hard timeout so it never drains battery; coarse significant-change monitoring keeps running.
    func beginLocationRefinement(maxDuration: TimeInterval = Settings.refinementMaxDuration) {
        #if os(iOS)
        let status = Self.locationManager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
        guard !Self.isRefiningLocation else { return }

        Self.isRefiningLocation = true
        Self.refinementStartedAt = Date()
        Self.activeRefinementMaxDuration = maxDuration
        Self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        Self.locationManager.distanceFilter = kCLDistanceFilterNone
        Self.locationManager.startUpdatingLocation()

        let timeout = DispatchWorkItem { [weak self] in self?.endLocationRefinement() }
        Self.refinementTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + maxDuration, execute: timeout)
        #endif
    }

    func endLocationRefinement() {
        #if os(iOS)
        guard Self.isRefiningLocation else { return }
        Self.isRefiningLocation = false
        Self.refinementStartedAt = nil
        Self.refinementTimeout?.cancel()
        Self.refinementTimeout = nil

        // Stop the continuous burst; significant-change monitoring stays active for background movement.
        // Accuracy goes back to the cheap resting value - leaving it on `Best` would keep the GPS awake for
        // every subsequent one-shot fix.
        Self.locationManager.stopUpdatingLocation()
        Self.locationManager.distanceFilter = Self.halfMile
        Self.locationManager.desiredAccuracy = Self.restingAccuracy
        #endif
    }

    // MARK: - Location freshness (foreground)
    //
    // Significant-change monitoring needs cell towers, so it goes silent exactly when movement is fastest:
    // on a plane, or just after landing abroad before roaming kicks in. Nothing then asks the GPS for a fix,
    // and the screen keeps showing the last city (LAX all the way into Tokyo). These two hooks fill that gap
    // with single one-shot fixes - no continuous updates, no extra radio time when the last fix is recent.

    /// How stale the last committed fix may get while the app is frontmost before a one-shot refresh.
    private static let foregroundLocationMaxAge: TimeInterval = 5 * 60
    private static var foregroundLocationTimer: Timer?

    /// Requests a fresh fix if the last committed one is older than `maxAge` (or none exists).
    /// Online, one cheap self-terminating `requestLocation()` suffices (assisted GPS locks fast).
    /// Offline it does NOT: without assistance data a one-shot never acquires, which is how a whole
    /// flight used to pass with zero fixes and a frozen departure-city label - so offline runs a
    /// bounded continuous-GPS burst instead, and separately degrades a too-stale city label to
    /// honest coordinates.
    func refreshLocationIfStale(olderThan maxAge: TimeInterval = Settings.foregroundLocationMaxAge) {
        let status = Self.locationManager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }

        #if os(iOS)
        // Runs regardless of any in-flight burst: it depends only on how old the last fix is.
        degradeCityLabelIfFixTooStale()
        #endif

        // A refinement burst is already streaming fresh fixes; a one-shot request on top is redundant (and
        // mixing `requestLocation` with `startUpdatingLocation` is discouraged).
        guard !Self.isRefiningLocation else { return }
        if let last = Self.lastLocationCommitAt, Date().timeIntervalSince(last) < maxAge { return }

        #if os(iOS)
        if !Self.isNetworkReachable {
            beginLocationRefinement(maxDuration: Self.offlineAcquisitionMaxDuration)
            return
        }
        #endif
        Self.locationManager.requestLocation()
    }

    #if os(iOS)
    /// How long the app tolerates having NO fix at all while offline before it stops vouching for the
    /// saved city name. Long enough that a stationary signal-less phone whose occasional GPS fixes keep
    /// landing never trips it; short enough that a flight shows coordinates well before landing.
    private static let staleCityMaxAge: TimeInterval = 30 * 60

    /// The offline honesty backstop for when even the GPS bursts can't get a lock (window seats get real
    /// coordinate updates; aisle seats get this): once no fix has been committed for `staleCityMaxAge`
    /// with no network, the saved city may be long gone, so show the last fix's raw coordinates instead.
    /// The label heals automatically - the reconnect handler re-geocodes as soon as network returns, and
    /// any successful offline fix goes through `applyLabelWithoutGeocode` as usual.
    /// (iOS-only: the watch's reachability flag is unreliable - see `updateCity`.)
    private func degradeCityLabelIfFixTooStale() {
        guard !Self.isNetworkReachable else { return }
        guard let cur = currentLocation, !cur.city.contains("(") else { return }
        guard let last = Self.lastLocationCommitAt,
              Date().timeIntervalSince(last) >= Self.staleCityMaxAge else { return }

        withAnimation {
            currentLocation = Location(
                city: "(\(cur.latitude.stringRepresentation), \(cur.longitude.stringRepresentation))",
                latitude: cur.latitude,
                longitude: cur.longitude
            )
            currentCountryCode = ""
            Self.cityAnchor = nil
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    #endif

    /// While the app is frontmost, checks staleness every 5 minutes. Deliberately infrequent: the point is
    /// "the times update over a long flight with the app open", not live tracking. Stopped on backgrounding.
    func beginForegroundLocationCadence() {
        Self.foregroundLocationTimer?.invalidate()
        let timer = Timer(timeInterval: Self.foregroundLocationMaxAge, repeats: true) { [weak self] _ in
            self?.refreshLocationIfStale(olderThan: Self.foregroundLocationMaxAge - 30)
        }
        // .common so the checks still fire while the user is scrolling.
        RunLoop.main.add(timer, forMode: .common)
        Self.foregroundLocationTimer = timer
    }

    func endForegroundLocationCadence() {
        Self.foregroundLocationTimer?.invalidate()
        Self.foregroundLocationTimer = nil
    }

    // ERROR HANDLER
    func locationManager(_ mgr: CLLocationManager, didFailWithError err: Error) {
        logger.error("CLLocationManager failed: \(err.localizedDescription)")
    }

    // PERMISSION REQUEST
    func requestLocationAuthorization() {
        Self.ensureNetworkMonitorStarted()

        switch Self.locationManager.authorizationStatus {
        case .notDetermined:
            Self.locationManager.requestAlwaysAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            #if os(iOS)
            Self.locationManager.startMonitoringSignificantLocationChanges()
            #else
            Self.locationManager.startUpdatingLocation()
            #endif

            Self.locationManager.requestLocation()
        default:
            break
        }
    }
    
    actor GeocodeActor {
        private let gc = CLGeocoder()
        func placemark(for location: CLLocation) async throws -> CLPlacemark? {
            if gc.isGeocoding { gc.cancelGeocode() }
            return try await gc.reverseGeocodeLocation(location).first
        }
    }
    
    /// Label to show when reverse-geocoding can't resolve a real place name. We prefer an honest city
    /// name and never invent one: if a previously-resolved city is still nearby it stays (a momentary
    /// geocode failure shouldn't flip a known place to raw numbers), but once we've moved far enough that
    /// the old name would be wrong, raw coordinates are shown instead of a stale/"fake" city.
    private func cityFallback(latitude: Double, longitude: Double) -> String {
        if let cur = currentLocation, !cur.city.contains("(") {
            // Measured from where the name was actually resolved, not from the last (possibly sharpened) fix - 
            // otherwise a chain of small offline moves drags the reference along with you and the name never
            // expires. Falls back to the saved coordinate for anyone upgrading without an anchor yet.
            let anchor = Self.cityAnchor ?? CLLocation(latitude: cur.latitude, longitude: cur.longitude)
            let moved = anchor.distance(from: CLLocation(latitude: latitude, longitude: longitude))
            if moved <= Self.sameCityRadius { return cur.city }
        }
        return "(\(latitude.stringRepresentation), \(longitude.stringRepresentation))"
    }

    /// The best label we can produce without a geocoder: the saved city while we are plausibly still inside
    /// it, otherwise honest coordinates. Called on every fix that arrives while offline - no signal, airplane
    /// mode, mid-flight - so standing still keeps the city name and travelling far enough drops it.
    ///
    /// Writes only on an actual change, since this runs for every committed fix.
    @MainActor
    private func applyLabelWithoutGeocode(latitude: Double, longitude: Double) {
        let label = cityFallback(latitude: latitude, longitude: longitude)
        let unchanged = currentLocation?.city == label
            && currentLocation?.latitude == latitude
            && currentLocation?.longitude == longitude
        guard !unchanged else { return }

        withAnimation {
            currentLocation = Location(city: label, latitude: latitude, longitude: longitude)
            // Once the label degrades to coordinates we no longer know the country, so automatic
            // calculation-method switching must not keep acting on a stale one.
            if label.contains("(") {
                currentCountryCode = ""
                Self.cityAnchor = nil
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Reverse‑geocode utilities.
    ///
    /// `maxAttempts` defaults higher than one round-trip because watchOS reverse-geocoding (which often
    /// has to relay through the paired iPhone) is slower and flakier than on iOS; persisting through a few
    /// backed-off retries is what keeps a real city label from prematurely degrading to raw coordinates.
    @MainActor
    func updateCity(latitude: Double, longitude: Double, attempt: Int = 0, maxAttempts: Int = 5) async {
        Self.ensureNetworkMonitorStarted()

        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        // On watchOS, `NWPathMonitor` frequently reports `.unsatisfied` even though `CLGeocoder` still
        // resolves fine by relaying through the paired iPhone - and because the path never "becomes
        // reachable," the queued retry never fires, so the watch would sit on raw coordinates forever. So we
        // only trust the reachability flag to pre-empt the geocode on iOS; on the watch we always attempt it
        // and let a real geocode error (handled in the catch below) decide whether to defer.
        #if os(iOS)
        if !Self.isNetworkReachable {
            queueGeocodeForReconnect(coord)
            // Re-evaluate the label every time, not just when it is missing. The old check only ever *added* a
            // label, so a phone that lost signal in one city and landed in another kept displaying - and
            // country-matching - the city it left.
            applyLabelWithoutGeocode(latitude: latitude, longitude: longitude)
            return
        }
        #endif

        if let cached = Self.cachedPlacemark,
           CLLocation(latitude: cached.coord.latitude, longitude: cached.coord.longitude)
             .distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude)) < 100,
                     cached.city == currentLocation?.city,
                     cached.countryCode == currentCountryCode {
            return
        }

        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            guard let placemark = try await Self.geocodeActor.placemark(for: location) else {
                throw CLError(.geocodeFoundNoResult)
            }

            let newCity: String = {
                let cityLike = placemark.locality
                           ?? placemark.subLocality
                           ?? placemark.subAdministrativeArea
                           ?? placemark.name
                let region = placemark.administrativeArea ?? placemark.country
                if let c = cityLike, let r = region { return "\(c), \(r)" }
                if let c = cityLike { return c }
                if let r = region { return r }
                return cityFallback(latitude: latitude, longitude: longitude)
            }()

            let detectedCountryCode = placemark.isoCountryCode?.uppercased() ?? ""

            if newCity != currentLocation?.city || detectedCountryCode != currentCountryCode {
                withAnimation {
                    currentLocation = Location(city: newCity, latitude: latitude, longitude: longitude)
                    currentCountryCode = detectedCountryCode
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }

            Self.cachedPlacemark = (coord, newCity, detectedCountryCode)
            // Anchor the name to where it was resolved, so `cityFallback` can later tell "still here" from
            // "long gone" without a network.
            Self.cityAnchor = CLLocation(latitude: latitude, longitude: longitude)

        } catch {
            // On iOS an unreachable path means "wait for reconnect." On watchOS the path flag is unreliable
            // (see above), so only a genuine network geocode error defers - otherwise we fall through to the
            // backed-off retry, which is what actually lands a city on the watch.
            #if os(iOS)
            let networkDefer = isNetworkGeocodeError(error) || !Self.isNetworkReachable
            #else
            let networkDefer = isNetworkGeocodeError(error)
            #endif
            if networkDefer {
                queueGeocodeForReconnect(coord)
                applyLabelWithoutGeocode(latitude: latitude, longitude: longitude)
                logger.warning("Geocode deferred until network returns")
                return
            }

            logger.warning("Geocode attempt \(attempt+1) failed: \(error.localizedDescription)")
            guard attempt + 1 < maxAttempts else {
                // Only degrade the visible label to coordinates when we don't already have a still-valid
                // nearby city (handled by `cityFallback`); a far move yields honest coordinates.
                applyLabelWithoutGeocode(latitude: latitude, longitude: longitude)
                return
            }
            // Backed-off retry, capped so the tail attempts don't stretch the wait out indefinitely.
            let delaySeconds = min(pow(2.0, Double(attempt)) * 2.0, 10.0)
            let delay = UInt64(delaySeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: delay)
            await updateCity(latitude: latitude, longitude: longitude, attempt: attempt + 1, maxAttempts: maxAttempts)
        }
    }
    
    private static let travelingNotificationId = "\(AppIdentifiers.appName).TravelingMode"
    private static let calculationNotificationId = "\(AppIdentifiers.appName).CalculationMode"

    /// Which method a country uses, derived from the catalogue so the mapping can never disagree with the
    /// method list (and so no country can be claimed by two methods).
    private static var countryCalculationMap: [String: String] { PrayerCalculationCatalog.byCountry }

    // MARK: - High latitude rule

    static let automaticHighLatitudeRule = "Automatic"

    /// Picker labels, in the order they read best. `Automatic` uses Adhan's own recommendation, which is
    /// `seventhOfTheNight` above 48° latitude and `middleOfTheNight` below it.
    static let highLatitudeRuleOptions: [String] = [
        automaticHighLatitudeRule,
        "Middle of the Night",
        "Seventh of the Night",
        "Twilight Angle"
    ]

    private static let highLatitudeRuleValues: [String: HighLatitudeRule] = [
        "Middle of the Night": .middleOfTheNight,
        "Seventh of the Night": .seventhOfTheNight,
        "Twilight Angle": .twilightAngle
    ]

    private static let highLatitudeRuleLabels: [HighLatitudeRule: String] = [
        .middleOfTheNight: "Middle of the Night",
        .seventhOfTheNight: "Seventh of the Night",
        .twilightAngle: "Twilight Angle"
    ]

    /// The rule actually applied at a coordinate. `Automatic` resolves per-location, so viewing another city's
    /// times in the map picker uses the rule appropriate to *that* latitude rather than the user's.
    func resolvedHighLatitudeRule(at coordinates: Coordinates) -> HighLatitudeRule {
        Self.highLatitudeRuleValues[highLatitudeRule] ?? HighLatitudeRule.recommended(for: coordinates)
    }

    /// Label for the rule `Automatic` would pick here - shown under the picker so the choice isn't opaque.
    func recommendedHighLatitudeRuleLabel(at coordinates: Coordinates) -> String {
        Self.highLatitudeRuleLabels[.recommended(for: coordinates)] ?? "Middle of the Night"
    }

    // MARK: - Custom prayer names

    /// Prayers a user may rename. Sunrise and the optional times are excluded - they aren't prayers.
    static let renameablePrayerNames = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    /// The user's spelling of a prayer, or `nil` when they haven't set one. Blank entries count as unset.
    func customPrayerName(for transliteration: String) -> String? {
        guard let custom = customPrayerNames[transliteration]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !custom.isEmpty else { return nil }
        return custom
    }

    private func automaticCalculationMethod(for countryCode: String) -> String {
        Self.countryCalculationMap[countryCode] ?? PrayerCalculationCatalog.muslimWorldLeagueID
    }

    /// Recommended calculation-method label for an arbitrary ISO country code.
    /// Used when viewing/comparing other cities so each city can use the method
    /// appropriate to its country instead of the app's single global method.
    func recommendedCalculationMethod(forCountryCode countryCode: String) -> String {
        canonicalPrayerCalculationMethod(automaticCalculationMethod(for: countryCode.uppercased()))
    }

    /// Resolves a stored label to a real method id: an exact catalogue hit, a legacy alias, or the global
    /// default. Nothing else in the app should have to know that old labels ever existed.
    func canonicalPrayerCalculationMethod(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == PrayerCalculationCatalog.customID { return trimmed }
        if PrayerCalculationCatalog.method(id: trimmed) != nil { return trimmed }
        if let alias = PrayerCalculationCatalog.legacyAliases[trimmed] { return alias }
        return PrayerCalculationCatalog.muslimWorldLeagueID
    }

    /// Returns `true` if it switched `prayerCalculation`, so the enclosing fetch recomputes the prayer list.
    @discardableResult
    func checkAutomaticPrayerCalculation() -> Bool {
        guard Bundle.main.bundleIdentifier?.contains("Widget") != true,
              calculationAutomatic,
              let currentLocation = currentLocation,
              currentLocation.latitude != 1000,
              currentLocation.longitude != 1000
        else { return false }

        let countryCode = currentCountryCode.uppercased()
        guard !countryCode.isEmpty else { return false }

        let detectedRaw = automaticCalculationMethod(for: countryCode)
        let detectedMethod = canonicalPrayerCalculationMethod(detectedRaw)
        let detectedParams = calculationParameters(forStoredLabel: detectedMethod)

        let previousMethod = prayerCalculation
        // Nothing to do only when we are ALREADY on the detected method. The check used to compare the computed
        // angles instead, which quietly stranded anyone on "Custom Angles": its defaults (18°/17°) are the same
        // numbers Muslim World League uses, so the params matched, this returned early, and turning Automatic on
        // appeared to do nothing at all. Identity is the question being asked here - "am I on the method this
        // country uses?" - and Custom is never that method, whatever its angles happen to be set to.
        //
        // Canonicalized on both sides: a stored legacy alias IS the detected method, and treating it as a
        // different one would switch the label and announce a change that isn't one.
        if canonicalPrayerCalculationMethod(previousMethod) == detectedMethod {
            return false
        }

        let currentParams = calculationParameters(forStoredLabel: previousMethod)
        withAnimation {
            prayerCalculation = detectedMethod
        }

        calculationAutoPreviousMethod = previousMethod
        calculationAutoDetectedMethod = detectedMethod
        calculationAutoDetectedCountryCode = countryCode
        calculationAutoChanged = true

        // The method switched either way, but the prayer TIMES only actually move if the angles differ. When they
        // don't (Custom sitting on the MWL angles, or two catalogue methods that agree), skip the push
        // notification - it would announce a change to times that are identical to the ones already on screen.
        guard detectedParams != currentParams else { return true }

        #if os(iOS)
        // Same rate limit as the traveling-mode announcement: the method itself still switches; only the
        // notification is capped, so a border area (or geocode noise flipping the detected country) can't
        // announce every flip.
        let now = Date()
        if let last = lastCalculationNotificationAt,
           now.timeIntervalSince(last) < Self.travelNotifyCooldown {
            logger.debug("Calculation-switch notification suppressed (cooldown)")
            return true   // the method DID switch; only the announcement is suppressed
        }
        lastCalculationNotificationAt = now

        let content = UNMutableNotificationContent()
        content.title = AppIdentifiers.appName
        content.body = "Prayer calculation switched to \(detectedMethod) for \(currentLocation.city)."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: Self.calculationNotificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
        #endif
        return true
    }

    // Runs synchronously inside `fetchPrayerTimes` (its only caller), which itself always runs on the main
    // thread - hopping there with `sync`, never `async`, so the check can never be reordered against the
    // caller that asked for it. Whether a manual change suppresses this check is carried by the
    // `runAutoChecks` parameter, not by mutable state.
    //
    /// Whether THIS device may auto-toggle `travelingMode`.
    ///
    /// The iPhone always may - it is the sole authority for traveling mode and syncs the verdict to the
    /// watch (one-way; see `watchSyncSnapshot`). A **paired** watch must NOT run its own check: it senses
    /// its own location against its own independently-seeded home (`seedHomeLocationIfNeeded` runs on the
    /// watch too), so its verdict can disagree with the phone's and silently flip the just-synced value
    /// right back - the "traveling mode works on the phone but keeps reverting on the watch" bug. And since
    /// the key syncs one way, the phone never learns about the flip, so the two devices disagree forever.
    /// A **standalone** watch (no companion iPhone app) has no phone to defer to and keeps the check.
    /// Before WCSession activation resolves the answer isn't known yet - treat that as "not mine": skipping
    /// one early check is harmless (the next fetch re-runs it), flipping a paired watch's mode is not.
    var ownsTravelingModeAutoCheck: Bool {
        #if os(watchOS)
        // Query WCSession directly (rather than via WatchConnectivityManager) so this also compiles in
        // targets that don't include the manager source, e.g. the watch Complication extension.
        let session = WCSession.default
        return session.activationState == .activated && !session.isCompanionAppInstalled
        #else
        return true
        #endif
    }

    /// Returns `true` if it changed `travelingMode`, so the enclosing fetch recomputes the prayer list.
    @discardableResult
    func checkIfTraveling() -> Bool {
        guard Bundle.main.bundleIdentifier?.contains("Widget") != true else { return false }

        guard ownsTravelingModeAutoCheck else {
            // A paired watch defers to the phone. Any standing auto-change flag here is a leftover from a
            // build where the watch still ran this check itself (or from before pairing): presenting its
            // dialog would offer override buttons that flip the just-synced value right back - the "watch
            // randomly says traveling mode turned on" bug - so retire the flags instead of showing them.
            if travelTurnOnAutomatic { travelTurnOnAutomatic = false }
            if travelTurnOffAutomatic { travelTurnOffAutomatic = false }
            return false
        }

        guard travelAutomatic,
              let currentLocation = currentLocation,
              let homeLocation = homeLocation,
              currentLocation.latitude != 1000,
              currentLocation.longitude != 1000
        else { return false }

        let here  = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let home  = CLLocation(latitude: homeLocation.latitude, longitude: homeLocation.longitude)
        // Compared in metres against the one declared threshold, rather than re-deriving 48 miles here with a
        // second copy of the metres-per-mile constant.
        let distance = here.distance(from: home)

        // HYSTERESIS. A single threshold is what made this spam: sitting anywhere near 48 miles - or simply
        // having the GPS wander by a few hundred metres, which it does constantly - flipped `travelingMode`
        // back and forth, and every flip fired a notification AND queued a confirmation dialog. Turning ON
        // still happens at the threshold, but turning OFF requires coming a clear margin back inside it, so a
        // borderline position settles on one answer instead of oscillating.
        let isAway: Bool
        if travelingMode {
            isAway = distance > Self.travelThresholdM - Self.travelHysteresisM
        } else {
            isAway = distance >= Self.travelThresholdM
        }

        if isAway {
            if !travelingMode {
                withAnimation { travelingMode = true }
                travelTurnOffAutomatic = false
                travelTurnOnAutomatic  = true
                notifyTravelingModeChanged(
                    body: "Traveling mode automatically turned on at \(currentLocation.city), away from your home city of \(homeLocation.city)"
                )
                return true
            }
        } else {
            if travelingMode {
                withAnimation { travelingMode = false }
                travelTurnOnAutomatic  = false
                travelTurnOffAutomatic = true
                notifyTravelingModeChanged(
                    body: "Traveling mode automatically turned off at \(currentLocation.city), near your home city of \(homeLocation.city)"
                )
                return true
            }
        }
        return false
    }

    /// The auto-toggle's notification, rate-limited. Even with hysteresis, a route that genuinely crosses the
    /// 48-mile line repeatedly (a commute that straddles it) would otherwise notify on every crossing - so a
    /// cooldown caps it. The mode itself still switches; only the *announcement* is suppressed.
    private func notifyTravelingModeChanged(body: String) {
        #if os(iOS)
        let now = Date()
        if let last = lastTravelingNotificationAt,
           now.timeIntervalSince(last) < Self.travelNotifyCooldown {
            logger.debug("Traveling-mode notification suppressed (cooldown)")
            return
        }
        lastTravelingNotificationAt = now

        let content = UNMutableNotificationContent()
        content.title = AppIdentifiers.appName
        content.body  = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: Self.travelingNotificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
        #endif
    }
    
    private static let hijriCalendarAR: Calendar = {
        var c = Calendar(identifier: .islamicUmmAlQura)
        c.locale = Locale(identifier: "ar")
        return c
    }()

    private static let hijriFormatterAR: DateFormatter = {
        let f = DateFormatter()
        f.calendar = hijriCalendarAR
        f.locale   = Locale(identifier: "ar")
        f.dateFormat = "d MMMM، yyyy"
        return f
    }()

    private static let hijriFormatterEN: DateFormatter = {
        let f = DateFormatter()
        f.calendar = hijriCalendarAR
        f.locale   = Locale(identifier: "en")
        f.dateStyle = .long
        return f
    }()
    
    private static let gregorian: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.locale = .current
        return c
    }()
    
    @inline(__always)
    func arabicNumberString<S: StringProtocol>(from ascii: S) -> String {
        var out = String();  out.reserveCapacity(ascii.count)
        for ch in ascii {
            if let d = ch.asciiDigitValue {
                out.unicodeScalars.append(UnicodeScalar(0x0660 + d)!)   // ٠…٩
            } else {
                out.append(ch)
            }
        }
        return out
    }

    func formatArabicDate(_ date: Date) -> String {
        arabicNumberString(from: DateFormatter.timeAR.string(from: date))
    }

    func formatDate(_ date: Date) -> String {
        DateFormatter.timeEN.string(from: date)
    }

    func effectiveHijriReferenceDate(now: Date = Date()) -> Date {
        guard switchHijriDateAtMaghrib else { return now }
        guard let prayers = getPrayerTimes(for: now, fullPrayers: true) else { return now }
        guard let maghrib = prayers.first(where: { $0.nameTransliteration == "Maghrib" })?.time else { return now }
        guard now >= maghrib else { return now }
        return Self.gregorian.date(byAdding: .day, value: 1, to: now) ?? now
    }
    
    func updateDates() {
        let now = Date()
        let effectiveDate = effectiveHijriReferenceDate(now: now)
        if let h = hijriDate, Self.gregorian.isDate(h.date, inSameDayAs: effectiveDate) {
            return
        }

        let base = Self.hijriCalendarAR.date(byAdding: .day, value: hijriOffset, to: effectiveDate) ?? effectiveDate
        let arabic = arabicNumberString(from: Self.hijriFormatterAR.string(from: base)) + " هـ"
        let english = Self.hijriFormatterEN.string(from: base)

        withAnimation {
            hijriDate = HijriDate(english: english, arabic: arabic, date: effectiveDate)
        }
    }
    
    /// The parameters for a stored method label. Everything routes through `PrayerCalculationCatalog`, so a
    /// method is data (a name plus its angles) rather than a case of the Adhan package's enum - which is what
    /// lets the app carry regional methods the package never shipped, and the user's own angles.
    func calculationParameters(forStoredLabel name: String) -> CalculationParameters {
        let id = canonicalPrayerCalculationMethod(name)
        if id == PrayerCalculationCatalog.customID {
            return PrayerCalculationCatalog
                .custom(fajrAngle: customFajrAngle, ishaAngle: customIshaAngle)
                .parameters
        }
        guard let method = PrayerCalculationCatalog.method(id: id) else {
            return PrayerCalculationCatalog.method(id: PrayerCalculationCatalog.muslimWorldLeagueID)!.parameters
        }
        return method.parameters
    }

    /// True when this method's Isha is Umm al-Qura's 90-minute interval, which stretches to 120 in Ramadan.
    private func usesUmmAlQuraRamadanExtension(_ label: String) -> Bool {
        canonicalPrayerCalculationMethod(label) == "Saudi Arabia (Umm Al-Qura)"
    }

    private struct NotifPrefs {
        let enabled: ReferenceWritableKeyPath<Settings, Bool>
        let preMinutes: ReferenceWritableKeyPath<Settings, Int>
        let nagging: ReferenceWritableKeyPath<Settings, Bool>
    }
    
    private struct Proto {
        let ar, tr, en, img, rakah, sunnahB, sunnahA: String
    }

    private static let prayerProtos: [String: Proto] = [
        "Fajr":      .init(ar:"الفَجر",  tr:"Fajr",   en:"Dawn",     img:"sun.horizon",       rakah:"2", sunnahB:"2", sunnahA:"0"),
        "Sunrise":   .init(ar:"الشُرُوق", tr:"Shurooq",en:"Sunrise",  img:"sunrise",  rakah:"0", sunnahB:"0", sunnahA:"0"),
        "Dhuhr":     .init(ar:"الظُهر",  tr:"Dhuhr",  en:"Noon",     img:"sun.max",       rakah:"4", sunnahB:"2 and 2", sunnahA:"2"),
        "Asr":       .init(ar:"العَصر",  tr:"Asr",    en:"Afternoon",img:"sun.min",       rakah:"4", sunnahB:"0", sunnahA:"0"),
        "Maghrib":   .init(ar:"المَغرِب",tr:"Maghrib",en:"Sunset",   img:"sunset",        rakah:"3", sunnahB:"0", sunnahA:"2"),
        "Isha":      .init(ar:"العِشَاء", tr:"Isha",   en:"Night",    img:"moon",          rakah:"4", sunnahB:"0", sunnahA:"2"),
        // grouped (travel) variants
        "Dhuhr/Asr":    .init(ar:"الظُهر وَالعَصر", tr:"Dhuhr/Asr",   en:"Daytime",   img:"sun.max", rakah:"2 and 2", sunnahB:"0", sunnahA:"0"),
        "Maghrib/Isha": .init(ar:"المَغرِب وَالعِشَاء", tr:"Maghrib/Isha", en:"Nighttime", img:"sunset", rakah:"3 and 2",sunnahB:"0", sunnahA:"0")
    ]
    
    @inline(__always)
    private func prayer(from key: String, time: Date) -> Prayer {
        let p = Self.prayerProtos[key]!
        return Prayer(
            nameArabic: p.ar,
            nameTransliteration: p.tr,
            nameEnglish: p.en,
            time: time,
            image: p.img,
            rakah: p.rakah,
            sunnahBefore: p.sunnahB,
            sunnahAfter: p.sunnahA,
            nameCustom: customDisplayName(forPrayerKey: p.tr)
        )
    }

    /// The custom name for a prayer key, including the traveling-mode pairs - "Dhuhr/Asr" reads as the user's
    /// two spellings joined, and only differs from the default when at least one half was actually renamed.
    private func customDisplayName(forPrayerKey key: String) -> String? {
        let halves = key.split(separator: "/").map(String.init)
        guard halves.count > 1 else { return customPrayerName(for: key) }

        guard halves.contains(where: { customPrayerName(for: $0) != nil }) else { return nil }
        return halves.map { customPrayerName(for: $0) ?? $0 }.joined(separator: "/")
    }
    
    /// Ultra‑fast prayer generator. Returns `nil` if location is not valid.
    func getPrayerTimes(for date: Date, fullPrayers: Bool = false) -> [Prayer]? {
        guard let here = currentLocation else { return nil }
        return getPrayerTimes(for: date, at: here, fullPrayers: fullPrayers)
    }

    /// Computes prayer times for an explicit location without changing the app's saved current location.
    /// Pass `calculationOverride` to use a specific calculation method (e.g. one matched to the
    /// viewed city's country) instead of the app's global `prayerCalculation`.
    func getPrayerTimes(for date: Date, at location: Location, fullPrayers: Bool = false, calculationOverride: String? = nil) -> [Prayer]? {
        let rawPrayers = _computeRawPrayers(for: date, at: location, calculationOverride: calculationOverride)
        guard !rawPrayers.isEmpty else { return nil }
        
        if fullPrayers || !travelingMode {
            return rawPrayers
        }
        
        return _filterTravelingMode(rawPrayers)
    }    

    /// Optimized getter that computes both normal and full prayer lists in a single calculation pass
    func getPrayerTimesNormalAndFull(for date: Date) -> (normal: [Prayer], full: [Prayer])? {
        let rawPrayers = _computeRawPrayers(for: date)
        guard !rawPrayers.isEmpty else { return nil }
        
        let fullList = rawPrayers
        let normalList = travelingMode ? _filterTravelingMode(rawPrayers) : rawPrayers
        
        return (normal: normalList, full: fullList)
    }    

    func prayersIncludingOptional(_ base: [Prayer], for date: Date) -> [Prayer] {
        let optional = getOptionalPrayers(for: date)
        guard !optional.isEmpty else { return base }

        let existingNames = Set(base.map(\.nameTransliteration))
        let missingOptional = optional.filter { !existingNames.contains($0.nameTransliteration) }
        return (base + missingOptional).sorted { $0.time < $1.time }
    }

    /// Computes the raw unfiltered prayer times for a given date. This internal function
    /// handles all PrayerTimes calculation logic once, avoiding duplicate computations.
    private func _computeRawPrayers(for date: Date) -> [Prayer] {
        guard let here = currentLocation else { return [] }
        return _computeRawPrayers(for: date, at: here)
    }

    private func _computeRawPrayers(for date: Date, at here: Location, calculationOverride: String? = nil) -> [Prayer] {
        // `rawPrayerCache` (and its eviction) is a plain static Dictionary. All callers are main-confined
        // today - SwiftUI bodies, @MainActor intents, and the widget provider's DispatchQueue.main.sync -
        // and this trips in debug if a future caller breaks that instead of corrupting the cache.
        assert(Thread.isMainThread, "_computeRawPrayers must be called on the main thread")
        guard here.latitude != 1000, here.longitude != 1000 else { return [] }

        let method = calculationOverride ?? prayerCalculation

        let comps = Self.gregorian.dateComponents([.year, .month, .day], from: date)
        let cacheKey = RawPrayerCacheKey(
            year: comps.year ?? 0,
            month: comps.month ?? 0,
            day: comps.day ?? 0,
            latitude: here.latitude,
            longitude: here.longitude,
            calculation: method,
            hanafiMadhab: hanafiMadhab,
            highLatitudeRule: highLatitudeRule,
            offsets: [offsetFajr, offsetSunrise, offsetDhuhr, offsetAsr, offsetMaghrib, offsetIsha]
        )

        if let cached = Self.rawPrayerCache[cacheKey] {
            return cached
        }

        let coordinates = Coordinates(latitude: here.latitude, longitude: here.longitude)

        var params = calculationParameters(forStoredLabel: method)
        params.madhab = hanafiMadhab ? Madhab.hanafi : Madhab.shafi
        params.highLatitudeRule = resolvedHighLatitudeRule(at: coordinates)

        // Umm Al-Qura delays Isha by 30 minutes throughout Ramadan. The reference date is pushed a day forward
        // because taraweeh on the night *before* 1 Ramadan already follows the Ramadan timing.
        if usesUmmAlQuraRamadanExtension(method) {
            let hijriMonth = Self.hijriCalendarAR.dateComponents([.month], from: date.addingTimeInterval(86_400)).month
            if hijriMonth == 9 {
                params.adjustments.isha += 30
            }
        }

        guard let raw = PrayerTimes(
                coordinates: coordinates,
                date: comps,
                calculationParameters: params
        )
        else { return [] }

        @inline(__always) func off(_ d: Date, by m: Int) -> Date {
            d.addingTimeInterval(Double(m) * 60)
        }

        let fajr     = off(raw.fajr,     by: offsetFajr)
        let sunrise  = off(raw.sunrise,  by: offsetSunrise)
        let dhuhr    = off(raw.dhuhr,    by: offsetDhuhr)
        let asr      = off(raw.asr,      by: offsetAsr)
        let maghrib  = off(raw.maghrib,  by: offsetMaghrib)
        let isha     = off(raw.isha,     by: offsetIsha)

        let isFriday = Self.gregorian.component(.weekday, from: date) == 6

        var list: [Prayer] = [
            prayer(from: "Fajr",    time: fajr),
            prayer(from: "Sunrise", time: sunrise)
        ]

        // Dhuhr / Jumuah switch
        if isFriday {
            list.append(
                Prayer(nameArabic: "الجُمُعَة",
                       nameTransliteration: "Jumuah",
                       nameEnglish: "Friday",
                       time: dhuhr,
                       image: "sun.max.fill",
                       rakah: "2",
                       sunnahBefore: "0",
                       sunnahAfter: "2 and 2")
            )
        } else {
            list.append(prayer(from: "Dhuhr", time: dhuhr))
        }

        list += [
            prayer(from: "Asr",     time: asr),
            prayer(from: "Maghrib", time: maghrib),
            prayer(from: "Isha",    time: isha)
        ]

        // Manual offsets reach +/-190 minutes, which is more than enough to push Fajr past Sunrise. The list
        // is consumed as a chronology - widgets slice its head and tail, the countdown walks it, the calendar
        // prints it - so order it by time rather than by the sequence it happens to be built in. Sorted on
        // (time, build index) because `sort` isn't stable and two prayers can share a minute once offsets
        // collide; ties then keep their canonical order.
        list = list.enumerated()
            .sorted { ($0.element.time, $0.offset) < ($1.element.time, $1.offset) }
            .map(\.element)

        while Self.rawPrayerCache.count >= Self.rawPrayerCacheLimit, let oldest = Self.rawPrayerCacheOrder.first {
            Self.rawPrayerCacheOrder.removeFirst()
            Self.rawPrayerCache.removeValue(forKey: oldest)
        }
        Self.rawPrayerCache[cacheKey] = list
        Self.rawPrayerCacheOrder.append(cacheKey)
        return list
    }

    /// The Asr time computed with the *opposite* madhab to the user's current setting (Hanafi ↔ Standard),
    /// for the day of `referenceTime` at the current location, using the same calculation method and Asr
    /// offset as the shown times. Used to display "the other Asr" in the Asr detail. Nil if no valid location.
    func otherMadhabAsrTime(onSameDayAs referenceTime: Date) -> Date? {
        guard let loc = currentLocation, loc.latitude != 1000, loc.longitude != 1000 else { return nil }
        var params = calculationParameters(forStoredLabel: prayerCalculation)
        params.madhab = hanafiMadhab ? Madhab.shafi : Madhab.hanafi
        let comps = Self.gregorian.dateComponents([.year, .month, .day], from: referenceTime)
        guard let raw = PrayerTimes(
            coordinates: Coordinates(latitude: loc.latitude, longitude: loc.longitude),
            date: comps,
            calculationParameters: params
        ) else { return nil }
        return raw.asr.addingTimeInterval(Double(offsetAsr) * 60)
    }

    /// Computes the enabled optional prayer times (Duhaa, Islamic Midnight, Last Third) for a given date.
    /// These are NOT stored in `prayers` (which is shared with widgets) and NOT shown in widgets.
    func getOptionalPrayers(for date: Date) -> [Prayer] {
        let raw = _computeRawPrayers(for: date)
        guard !raw.isEmpty else { return [] }

        guard
            let sunrise = raw.first(where: { $0.nameTransliteration == "Shurooq" })?.time,
            let maghrib = raw.first(where: { $0.nameTransliteration == "Maghrib" })?.time
        else { return [] }

        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        let nextRaw = _computeRawPrayers(for: nextDay)
        let fajrNext = nextRaw.first(where: { $0.nameTransliteration == "Fajr" })?.time

        var result: [Prayer] = []

        if showDuha {
            result.append(Prayer(
                nameArabic: "صَلَاةُ الضُّحَى",
                nameTransliteration: "Duhaa",
                nameEnglish: "Forenoon Prayer",
                time: sunrise.addingTimeInterval(15 * 60),
                image: "sun.haze.fill",
                rakah: "2–8",
                sunnahBefore: "0",
                sunnahAfter: "0"
            ))
        }

        

        if let fajrNext {
            let nightDuration = fajrNext.timeIntervalSince(maghrib)

            if showIslamicMidnight {
                result.append(Prayer(
                    nameArabic: "نِصْفُ اللَّيْلِ الشَّرْعِيُّ",
                    nameTransliteration: "Islamic Midnight",
                    nameEnglish: "Islamic Middle of Night",
                    time: maghrib.addingTimeInterval(nightDuration / 2),
                    image: "moon.fill",
                    rakah: "0",
                    sunnahBefore: "0",
                    sunnahAfter: "0"
                ))
            }

            if showLastThird {
                result.append(Prayer(
                    nameArabic: "الثُّلُثُ الْأَخِيرُ مِنَ اللَّيْلِ",
                    nameTransliteration: "Last Third",
                    nameEnglish: "Last Third of Night",
                    time: fajrNext.addingTimeInterval(-nightDuration / 3),
                    image: "moon.stars.fill",
                    rakah: "0",
                    sunnahBefore: "0",
                    sunnahAfter: "0"
                ))
            }
        }

        return result
    }

    // Always runs on the main thread, and always runs *synchronously* with respect to its caller.
    //
    // Both halves matter. It mutates `@Published` UI state (`prayers`, `currentPrayer`, `travelingMode` via
    // the auto-check) yet is invoked from background contexts - the BGTask handler, App Intents, the widget
    // provider - so off-main callers must hop to main. But the hop must be `sync`, not `async`: an async
    // deferral would reorder it against whatever its caller does next, and callers reason about this as an
    // inline call.
    //
    // `runAutoChecks` is how a caller says "this refresh must not second-guess what just happened." A manual
    // travel/calculation change passes `false`, so the automatic detection can never immediately override the
    // user's (or the paired device's) explicit choice. This used to be communicated through one-shot mutable
    // flags consumed at the next fetch - a message passed through time - which twice produced spam bugs when
    // execution order shifted. A parameter cannot arrive late.
    //
    // Deadlock safety: nothing on the main thread ever blocks waiting on the queues that call this
    // (BGTaskScheduler's queue, the App Intents queue, the widget provider's queue), so `main.sync` from
    // them cannot deadlock.
    func fetchPrayerTimes(force: Bool = false, notification: Bool = false, runAutoChecks: Bool = true, calledFrom: StaticString = #function, completion: (() -> Void)? = nil) {
        if Thread.isMainThread {
            fetchPrayerTimesCore(force: force, notification: notification, runAutoChecks: runAutoChecks, calledFrom: calledFrom, completion: completion)
        } else {
            DispatchQueue.main.sync {
                self.fetchPrayerTimesCore(force: force, notification: notification, runAutoChecks: runAutoChecks, calledFrom: calledFrom, completion: completion)
            }
        }
    }

    private func fetchPrayerTimesCore(force: Bool, notification: Bool, runAutoChecks: Bool, calledFrom: StaticString, completion: (() -> Void)?) {
        Self.ensureNetworkMonitorStarted()
        updateDates()

        guard let loc = currentLocation, loc.latitude  != 1000, loc.longitude != 1000 else {
            logger.debug("No valid location – skip refresh")
            // Hijri-event reminders are date-based and don't need a location, so still (re)schedule
            // them even when prayer times can't be computed yet (the scheduler skips the prayer
            // parts and leaves existing prayer notifications untouched when there's no location).
            scheduleNotifications(deferred: completion == nil)
            completion?()
            return
        }
        
        if force || loc.city.contains("(") {
            // watchOS: attempt the geocode regardless of the path-monitor flag (it under-reports on the watch,
            // see `updateCity`). iOS: only when the network is actually reachable, otherwise defer.
            // Structured as a local launch + per-platform gate (not a constant boolean) so the watch build
            // doesn't carry a provably-dead else branch ("will never be executed").
            func launchGeocode() {
                Task { @MainActor in
                    await updateCity(latitude: loc.latitude, longitude: loc.longitude)
                    if Bundle.main.bundleIdentifier?.contains("Widget") != true,
                       runAutoChecks,
                       calculationAutomatic,
                       checkAutomaticPrayerCalculation() {
                        // The method changed after this fetch already computed, so recompute with it. Checks
                        // stay off: the switch was just made from a fresh placemark, nothing to re-detect.
                        fetchPrayerTimes(force: true, runAutoChecks: false)
                    }
                }
            }

            #if os(iOS)
            if Self.isNetworkReachable {
                launchGeocode()
            } else {
                queueGeocodeForReconnect(CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude))
                logger.debug("Skipping geocode while offline; will retry on reconnect")
            }
            #else
            launchGeocode()
            #endif
        }

        // The automatic travel/calculation checks report whether they changed state; a change makes THIS
        // fetch recompute the prayer list below. (Previously a change here relied on an app-level `.onChange`
        // firing a second, later fetch to pick it up.)
        let isWidget = Bundle.main.bundleIdentifier?.contains("Widget") == true
        var autoStateChanged = false
        if !isWidget, runAutoChecks {
            // No `travelAutomatic`/`homeLocation` preconditions here: `checkIfTraveling` re-guards both
            // itself, and on a paired watch its non-owner path also retires stale auto-change flags - it
            // must run even when those preconditions are false.
            if checkIfTraveling() {
                autoStateChanged = true
            }
            // Coordinate placeholder city means ISO country may still be wrong or empty; geocode runs
            // asynchronously above - the check reruns from that Task once the placemark is known.
            if calculationAutomatic, !loc.city.contains("("), checkAutomaticPrayerCalculation() {
                autoStateChanged = true
            }
        }

        // Decide if we need fresh prayers
        let today      = Date()
        let stored     = prayers
        let staleCity  = stored?.city != currentLocation?.city
        let staleDate  = !(stored?.day.isSameDay(as: today) ?? false)
        let emptyList  = stored?.prayers.isEmpty ?? true
        let needsFetch = force || autoStateChanged || stored == nil || staleCity || staleDate || emptyList

        // A caller with a completion (notably the background-refresh task) needs the reschedule to finish
        // before it returns/reports done, so it runs synchronously. Everyone else (the launch burst, setting
        // toggles) defers + coalesces the heavy reschedule/widget-reload off the synchronous path.
        let deferWork = completion == nil

        if needsFetch {
            logger.debug("Fetching prayer times – caller: \(calledFrom)")
            
            // Single calculation – both filtered and full lists derived from same source
            let rawPrayers    = _computeRawPrayers(for: today)
            let todayPrayers  = travelingMode ? _filterTravelingMode(rawPrayers) : rawPrayers
            let fullPrayers   = rawPrayers  // Full list already computed
            
            prayers = Prayers(
                day: today,
                city: currentLocation?.city ?? loc.city,
                prayers: todayPrayers,
                fullPrayers: fullPrayers,
                setNotification: false
            )
            
            scheduleNotifications(deferred: deferWork)
            reloadWidgets(deferred: deferWork)
        } else if notification {
            scheduleNotifications(deferred: deferWork)
            reloadWidgets(deferred: deferWork)
        }
        
        updateCurrentAndNextPrayer()
        completion?()
    }
    
    /// Condenses the day into the traveling (Qasr) list: Fajr, Sunrise, Dhuhr+Asr, Maghrib+Isha.
    ///
    /// Looked up by name rather than by position: the source list is sorted by time, so a large enough manual
    /// offset moves prayers around in it, and on Friday index 2 is Jumuah rather than Dhuhr. Returns the list
    /// unchanged if any prayer it needs is missing, so a partial day can never yield a wrong combination.
    private func _filterTravelingMode(_ rawPrayers: [Prayer]) -> [Prayer] {
        func prayer(named names: String...) -> Prayer? {
            for name in names {
                if let match = rawPrayers.first(where: { $0.nameTransliteration == name }) { return match }
            }
            return nil
        }

        guard let fajr = prayer(named: "Fajr"),
              let sunrise = prayer(named: "Shurooq"),
              // Friday replaces Dhuhr with Jumuah, but the combined traveling prayer keeps its own name.
              let dhuhr = prayer(named: "Dhuhr", "Jumuah"),
              let maghrib = prayer(named: "Maghrib")
        else { return rawPrayers }

        return [
            fajr,
            sunrise,
            self.prayer(from: "Dhuhr/Asr", time: dhuhr.time),
            self.prayer(from: "Maghrib/Isha", time: maghrib.time)
        ]
        .enumerated()
        .sorted { ($0.element.time, $0.offset) < ($1.element.time, $1.offset) }
        .map(\.element)
    }
    
    /// The merged, sorted prayer timeline for yesterday/today/tomorrow around `now`, including optional
    /// prayers. This is what current/next are resolved against - shared with the widget provider, which
    /// walks the same timeline to pre-build one entry per prayer boundary (so widgets flip at the exact
    /// prayer time without depending on WidgetKit granting a reload on schedule).
    func prayerBoundaryTimeline(around now: Date = Date()) -> [Prayer] {
        guard let prayerObj = prayers, !prayerObj.prayers.isEmpty else { return [] }

        let calendar = Calendar.current
        return [-1, 0, 1]
            .compactMap { calendar.date(byAdding: .day, value: $0, to: now) }
            .flatMap { date -> [Prayer] in
                let base = calendar.isDate(date, inSameDayAs: prayerObj.day)
                    ? prayerObj.prayers
                    : (getPrayerTimes(for: date) ?? [])
                return prayersIncludingOptional(base, for: date)
            }
            .sorted { $0.time < $1.time }
    }

    func updateCurrentAndNextPrayer() {
        guard prayers?.prayers.isEmpty == false else {
            logger.debug("No prayer list to compute current/next")
            return
        }

        let now = Date()
        let timeline = prayerBoundaryTimeline(around: now)

        guard !timeline.isEmpty else {
            logger.debug("No prayer timeline to compute current/next")
            return
        }

        let resolvedCurrent = timeline.last { $0.time <= now } ?? timeline.first
        let resolvedNext = timeline.first { $0.time > now }

        if currentPrayer != resolvedCurrent {
            currentPrayer = resolvedCurrent
        }
        if nextPrayer != resolvedNext {
            nextPrayer = resolvedNext
        }
    }

    /// Whether THIS device should schedule prayer notifications locally.
    ///
    /// The iPhone always schedules. The Watch schedules **only when it is standalone** - i.e. there is no
    /// paired iPhone running this app's companion. When a companion iPhone exists it owns prayer
    /// notifications, so the Watch stays silent to avoid double-alerting the user across both devices.
    /// `companionPhoneExists` keys off installation (not Bluetooth range), so a phone left at home still
    /// counts; and it is re-evaluated on every scheduling pass, so the behavior tracks a user who later
    /// pairs an iPhone (Watch goes silent) or unpairs one (Watch resumes scheduling).
    var shouldScheduleNotificationsLocally: Bool {
        #if os(watchOS)
        // Query WCSession directly (rather than via WatchConnectivityManager) so this also compiles in
        // targets that don't include the manager source, e.g. the watch Complication extension.
        // `isCompanionAppInstalled` reflects installation, not Bluetooth range, so a phone left at home
        // still counts as "exists"; it's re-read on every scheduling pass, so the behavior tracks a user
        // who later pairs an iPhone (Watch goes silent) or unpairs one (Watch resumes scheduling).
        let session = WCSession.default
        let companionPhoneExists = session.activationState == .activated && session.isCompanionAppInstalled
        return !companionPhoneExists
        #elseif os(iOS)
        return true
        #else
        return false
        #endif
    }

    /// Whether the standalone-vs-companion question can even be ANSWERED yet. WCSession activation is
    /// async, and before it completes `activationState` reads `.notActivated` - which made the launch
    /// scheduling pass conclude "no phone → I'm standalone" and schedule local adhans on a paired watch.
    /// If the wrist dropped before activation resolved (the normal raise-and-drop interaction), those
    /// survived and the user heard every adhan TWICE. Until this is true, a scheduling pass must neither
    /// schedule nor wipe - `activationDidCompleteWith` reschedules the moment the answer exists.
    var watchNotificationOwnershipResolved: Bool {
        #if os(watchOS)
        return WCSession.default.activationState == .activated
        #else
        return true
        #endif
    }

    @MainActor
    func requestNotificationAuthorization() async -> Bool {
        #if os(watchOS)
        guard shouldScheduleNotificationsLocally else { return true }
        #endif
        #if os(iOS) || os(watchOS)
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus

        switch status {
        case .authorized:
            showNotificationAlert = false
            return true

        case .provisional, .ephemeral:
            // Both allow delivering notifications, so treat them like authorized and keep scheduling.
            showNotificationAlert = false
            return true

        case .denied:
            showNotificationAlert = !notificationNeverAskAgain
            logger.debug("Notification permission denied")
            return false

        case .notDetermined:
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound])
                showNotificationAlert = !granted && !notificationNeverAskAgain
                if granted { fetchPrayerTimes(notification: true) }
                return granted
            } catch {
                logger.error("Notification request failed: \(error.localizedDescription)")
                showNotificationAlert = !notificationNeverAskAgain
                return false
            }

        @unknown default:
            return false
        }
        #else
        return true
        #endif
    }
    
    func requestNotificationAuthorization(completion: (() -> Void)? = nil) {
        Task { @MainActor in
            _ = await requestNotificationAuthorization()
            completion?()
        }
    }
    
    /// Debug-only dump of pending notifications. Gated so it never round-trips to the notification daemon in
    /// release builds (it used to be called on every `fetchPrayerTimes`, i.e. several times per launch).
    func printAllScheduledNotifications() {
        #if DEBUG
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { (requests) in
            for request in requests {
                logger.debug("\(request.content.body)")
            }
        }
        #endif
    }

    /// Reschedule prayer/event notifications, coalescing the launch burst. `deferred == false` runs it
    /// synchronously (callers that must finish before reporting done - e.g. background refresh). `deferred ==
    /// true` trailing-debounces it on the main queue so the multiple `fetchPrayerTimes` calls fired during
    /// launch / setting changes collapse to one run, off the synchronous first-paint path.
    func scheduleNotifications(deferred: Bool) {
        // Only the APP schedules notifications. A widget whose cached prayers had gone stale used to reach
        // this through `fetchPrayerTimesCore` and schedule (or prune) the user's notifications from inside
        // the extension - and, via `reloadWidgets`, trigger a widget reload FROM a widget. Both were saved
        // only by the extension usually dying before the 0.35s defer fired.
        guard Settings.isAppProcess else { return }
        pendingNotificationScheduleWorkItem?.cancel()
        pendingNotificationScheduleWorkItem = nil
        guard deferred else {
            schedulePrayerTimeNotifications()
            return
        }
        let work = DispatchWorkItem { [weak self] in
            self?.pendingNotificationScheduleWorkItem = nil
            self?.schedulePrayerTimeNotifications()
        }
        pendingNotificationScheduleWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
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

    /// Static lookup table
    private static let notifTable: [String: NotifPrefs] = [
        "Fajr":          .init(enabled: \.notificationFajr,  preMinutes: \.preNotificationFajr,  nagging: \.naggingFajr),
        "Shurooq":       .init(enabled: \.notificationSunrise, preMinutes: \.preNotificationSunrise, nagging: \.naggingSunrise),
        "Dhuhr":         .init(enabled: \.notificationDhuhr, preMinutes: \.preNotificationDhuhr, nagging: \.naggingDhuhr),
        "Dhuhr/Asr":         .init(enabled: \.notificationDhuhr, preMinutes: \.preNotificationDhuhr, nagging: \.naggingDhuhr),
        "Jumuah":       .init(enabled: \.notificationDhuhr, preMinutes: \.preNotificationDhuhr, nagging: \.naggingDhuhr),
        "Asr":           .init(enabled: \.notificationAsr,   preMinutes: \.preNotificationAsr,   nagging: \.naggingAsr),
        "Maghrib":       .init(enabled: \.notificationMaghrib, preMinutes: \.preNotificationMaghrib, nagging: \.naggingMaghrib),
        "Maghrib/Isha":         .init(enabled: \.notificationMaghrib, preMinutes: \.preNotificationMaghrib, nagging: \.naggingMaghrib),
        "Isha":          .init(enabled: \.notificationIsha,  preMinutes: \.preNotificationIsha,  nagging: \.naggingIsha),
        "Duhaa":         .init(enabled: \.notificationDuha, preMinutes: \.preNotificationDuha, nagging: \.naggingDuha),
        "Islamic Midnight": .init(enabled: \.notificationIslamicMidnight, preMinutes: \.preNotificationIslamicMidnight, nagging: \.naggingIslamicMidnight),
        "Last Third":    .init(enabled: \.notificationLastThird, preMinutes: \.preNotificationLastThird, nagging: \.naggingLastThird)
    ]

    /// Pre‑computes the full list of minutes‑before offsets for a prayer.
    /// The distinct minutes-before offsets a prayer should fire at. Deduplicated: a prenotification of 15
    /// minutes and a nagging step at 15 minutes describe the same notification, and every offset consumes one
    /// slot of iOS's 64-request budget - a duplicate would silently cost a *later* prayer its adhan.
    ///
    /// `includeNags` is the per-prayer, per-day verdict from `nagCascadeIsAnswered`: a cascade whose
    /// question is already answered ("yes, I prayed it" - or tracking is paused) is never scheduled at
    /// all, instead of being scheduled and then cancelled.
    private func offsets(for prefs: NotifPrefs, includeNags: Bool = true) -> [Int] {
        var result: Set<Int> = []

        if self[keyPath: prefs.enabled] { result.insert(0) }

        let minutes = self[keyPath: prefs.preMinutes]
        if self[keyPath: prefs.enabled], minutes > 0 {
            result.insert(minutes)
        }

        if includeNags && naggingMode && self[keyPath: prefs.nagging] {
            result.formUnion(naggingCascade(start: naggingStartOffset))
        }
        return result.sorted(by: >)
    }

    /// True when the nag cascade leading up to `prayer` on `day` already has its answer, so scheduling
    /// it would only nag about a prayer that is already prayed. The cascade before a prayer asks about
    /// the PREVIOUS trackable prayer of that day; the cascade before the day's first (Fajr) asks about
    /// the night prayer begun the previous civil day (Isha). Menses pause silences every cascade.
    private func nagCascadeIsAnswered(for prayer: Prayer, in dayList: [Prayer], on day: Date) -> Bool {
        if isTrackerExempt(on: day) || isTrackerExempt(on: Date()) { return true }

        if let previous = dayList
            .filter({ $0.time < prayer.time
                && $0.nameTransliteration != prayer.nameTransliteration
                && Self.trackablePrayerNames.contains($0.nameTransliteration) })
            .max(by: { $0.time < $1.time }) {
            return isPrayerMarkedPrayed(previous.nameTransliteration, on: day)
        }

        guard let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: day) else { return false }
        return isPrayerMarkedPrayed("Isha", on: previousDay)
    }

    /// The reminder cascade leading up to a prayer: 30, 15, 10, 5 minutes before, by default.
    ///
    /// A *set*, because the arithmetic overlaps for some starting values - a start of 20 walks down to 5, and
    /// the trailing `[10, 5]` re-adds 5. Duplicates each claimed a notification slot while resolving to the
    /// same identifier, so the second silently replaced the first and the budget was spent for nothing.
    private func naggingCascade(start: Int) -> Set<Int> {
        guard start > 0 else { return [] }
        var m = start
        var out: Set<Int> = []
        while m > 15 { out.insert(m); m -= 15 }
        if m >= 5 { out.insert(m) }
        out.formUnion([10, 5].filter { $0 < start })
        return out
    }

    private func makeRefreshNagRequest(
        inDays offset: Int = 2,
        hour: Int = 12,
        minute: Int = 0
    ) -> (request: UNNotificationRequest, date: Date)? {
        guard let day = Calendar.current.date(byAdding: .day, value: offset, to: Date()) else { return nil }

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: day)
        comps.hour = hour
        comps.minute = minute

        guard let date = Calendar.current.date(from: comps), date > Date() else { return nil }

        // Pinned to the scheduling zone + stamped with its intended instant, same as the prayer requests.
        comps.timeZone = Calendar.current.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = AppIdentifiers.appName
        content.body  = "Please open the app to refresh today’s prayer times and notifications."
        content.sound = .default
        content.userInfo[Self.intendedFireDateUserInfoKey] = date.timeIntervalSince1970
        #if os(iOS)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        #endif

        // Unique per-day id so we don’t collide across days
        let id = String(format: "RefreshReminder-%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)

        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        return (req, date)
    }


    func schedulePrayerTimeNotifications() {
        #if os(watchOS)
        // Activation still pending: standalone-vs-companion is UNKNOWN. Scheduling would double-alert a
        // paired user; wiping would strand a truly standalone watch that suspends before activation.
        // Do neither - `activationDidCompleteWith` reschedules as soon as the answer exists.
        guard watchNotificationOwnershipResolved else { return }
        guard shouldScheduleNotificationsLocally else {
            // A companion iPhone now owns notifications - clear anything this Watch scheduled while it was
            // standalone so the two devices can't double-alert for the same prayer.
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            return
        }
        #endif
        #if os(iOS) || os(watchOS)
        logger.debug("Scheduling prayer time notifications")
        let center = UNUserNotificationCenter.current()

        // iOS keeps at most 64 pending notifications and silently drops the rest. The app can build far
        // more than that (multiple prayers × offsets × days × nags + events), which is why adhan /
        // notification sounds previously "didn't always work" - later prayers got dropped. Collect every
        // candidate, then add them in priority order under a safe cap so the at-time adhan always survives.
        let maxPending = 60

        var adhanRequests: [(request: UNNotificationRequest, date: Date)] = []
        var reminderRequests: [(request: UNNotificationRequest, date: Date)] = []

        // Prayer notifications need a resolved location + computed prayer times. Hijri-event reminders and
        // refresh nags below do NOT, so they're collected regardless of location - date notifications work
        // even before (or without) a location fix, instead of being silently skipped by an early return.
        let hasPrayers = currentLocation?.city != nil && prayers != nil
        if let city = currentLocation?.city, let prayerObj = prayers {
            func collectPrayer(_ prayer: Prayer, _ minutes: Int?) {
                guard let built = makePrayerNotificationRequest(for: prayer, preNotificationTime: minutes, city: city) else { return }
                if built.isAdhan {
                    adhanRequests.append((built.request, built.date))
                } else {
                    reminderRequests.append((built.request, built.date))
                }
            }

            let todayList = prayersIncludingOptional(prayerObj.prayers, for: prayerObj.day)
            for prayer in todayList {
                guard let prefs = Self.notifTable[prayer.nameTransliteration] else { continue }
                let includeNags = !nagCascadeIsAnswered(for: prayer, in: todayList, on: prayerObj.day)
                for minutes in offsets(for: prefs, includeNags: includeNags) {
                    collectPrayer(prayer, minutes == 0 ? nil : minutes)
                }
            }

            let futureDays = naggingMode ? 1 : 3
            if futureDays > 0 {
                for dayOffset in 1...futureDays {
                    let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: prayerObj.day) ?? Date()
                    guard let list = getPrayerTimes(for: date) else { continue }
                    let dayList = prayersIncludingOptional(list, for: date)
                    for prayer in dayList {
                        guard let prefs = Self.notifTable[prayer.nameTransliteration] else { continue }
                        let includeNags = !nagCascadeIsAnswered(for: prayer, in: dayList, on: date)
                        for minutes in offsets(for: prefs, includeNags: includeNags) {
                            collectPrayer(prayer, minutes == 0 ? nil : minutes)
                        }
                    }
                }
            }
        }

        var eventRequests: [(request: UNNotificationRequest, date: Date)] = []
        if dateNotifications {
            for event in specialEvents {
                if let built = makeEventNotificationRequest(for: event) { eventRequests.append(built) }
            }
        }

        var nagRequests: [(request: UNNotificationRequest, date: Date)] = []
        if naggingMode, let built = makeRefreshNagRequest(inDays: 1) { nagRequests.append(built) }
        if let built = makeRefreshNagRequest(inDays: 2) { nagRequests.append(built) }
        if let built = makeRefreshNagRequest(inDays: 3) { nagRequests.append(built) }

        // Add in priority order, soonest-first within each tier, capped under iOS's 64 limit:
        //   1. at-time adhan (the actual sound) - must never be dropped
        //   2. refresh nags - keep the rolling schedule alive so future days get rescheduled
        //   3. special-event reminders
        //   4. pre-/nagging reminders - fill whatever budget remains
        var finalRequests: [UNNotificationRequest] = []
        func appendCapped(_ items: [(request: UNNotificationRequest, date: Date)]) {
            for item in items.sorted(by: { $0.date < $1.date }) where finalRequests.count < maxPending {
                finalRequests.append(item.request)
            }
        }
        appendCapped(adhanRequests)
        appendCapped(nagRequests)
        appendCapped(eventRequests)
        appendCapped(reminderRequests)

        // Incremental refresh instead of wiping everything first: adding a request with an existing
        // identifier replaces it in place (all our identifiers are stable), so unchanged notifications are
        // never torn down - no brief window with zero pending, less churn, faster, and the system keeps the
        // already-scheduled fire times steady. Afterwards, prune only the now-stale ones (past days,
        // prayers turned off, items pushed out by the cap).
        let desiredIDs = Set(finalRequests.map { $0.identifier })
        for req in finalRequests {
            center.add(req) { error in
                if let error { logger.debug("Notification add failed: \(error.localizedDescription)") }
            }
        }
        center.getPendingNotificationRequests { pending in
            let stale = pending.map(\.identifier).filter { id in
                guard !desiredIDs.contains(id) else { return false }
                // Never prune the one-shot informational alerts (traveling-mode on/off, auto-calculation
                // change). They are scheduled by `checkIfTraveling` / `checkAutomaticPrayerCalculation` with
                // their own fixed IDs and a ~1s trigger, so they are always "pending" for about a second and
                // are never part of `desiredIDs`. Because those very state changes trigger this reschedule,
                // pruning them here would delete the alert before it is ever delivered - which is exactly why
                // the "traveling mode turned on/off" notification never appeared.
                if id == Self.travelingNotificationId || id == Self.calculationNotificationId { return false }
                // When there were no prayers to rebuild (no location yet), only prune the categories we DID
                // rebuild - events and refresh nags. Leaving prayer notifications alone means a momentary
                // location gap can't wipe a working adhan schedule.
                if !hasPrayers { return id.hasPrefix("Event-") || id.hasPrefix("RefreshReminder-") }
                return true
            }
            if !stale.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: stale)
            }
        }

        prayers?.setNotification = true
        #else
        return
        #endif
    }
    
    #if os(iOS)
    /// The next at-time adhan the in-app foreground player should sound: a main prayer (not Shurooq /
    /// optional) whose "at time" notification is enabled, with a fire time still ahead. Returns its date,
    /// name, and the matching scheduled-notification identifier so the now-redundant notification can be
    /// pruned when the app plays the adhan itself.
    func nextForegroundAdhan(after now: Date = Date()) -> (date: Date, name: String, notificationID: String)? {
        guard let prayerObj = prayers else { return nil }

        var candidates: [(date: Date, name: String)] = []
        for prayer in prayersIncludingOptional(prayerObj.prayers, for: prayerObj.day) {
            candidates.append((prayer.time, prayer.nameTransliteration))
        }
        // Include tomorrow so the Isha → next-Fajr gap is covered.
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: prayerObj.day),
           let list = getPrayerTimes(for: tomorrow) {
            for prayer in prayersIncludingOptional(list, for: tomorrow) {
                candidates.append((prayer.time, prayer.nameTransliteration))
            }
        }

        guard let next = candidates
            .filter({ $0.date > now && isForegroundAdhanEligible($0.name) })
            .min(by: { $0.date < $1.date })
        else { return nil }

        // Mirrors the at-time identifier built in makePrayerNotificationRequest (minutes == nil → "0").
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: next.date)
        let id = "\(next.name)-0-\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
        return (next.date, next.name, id)
    }

    private func isForegroundAdhanEligible(_ name: String) -> Bool {
        guard Self.adhanEligiblePrayerNames.contains(name) else { return false }
        // A prayer whose adhan sound is off gets the system notification sound; playing the recording in-app
        // anyway would be the exact thing the user turned off.
        guard playsAdhanSound(forPrayer: name) else { return false }
        guard let prefs = Self.notifTable[name] else { return false }
        return self[keyPath: prefs.enabled]
    }
    #endif

    private func buildBody(prayer: Prayer, minutesBefore: Int?, city: String) -> String {
        let englishPart: String = {
            switch prayer.nameTransliteration {
            case "Shurooq":
                return " (end of Fajr)"
            case "Jumuah":
                return " (Friday)"
            default:
                return ""
            }
        }()

        if let m = minutesBefore {
            // “n m until …”
            return "\(m)m until \(prayer.displayName)\(englishPart) in \(city)"
                 + (travelingMode ? " (traveling)" : "")
                 + " [\(formatDate(prayer.time))]"
        } else if prayer.nameTransliteration == "Fajr",
                  // Fajr ends at sunrise - found by name, because a manual offset can move Sunrise off index 1.
                  let sunrise = prayers?.prayers.first(where: { $0.nameTransliteration == "Shurooq" })?.time,
                  sunrise > prayer.time {
            return "Time for \(prayer.displayName)\(englishPart)"
                 + " at \(formatDate(prayer.time)) in \(city)"
                 + (travelingMode ? " (traveling)" : "")
                 + " [ends at \(formatDate(sunrise))]"
        } else {
            return "Time for \(prayer.displayName)\(englishPart)"
                 + " at \(formatDate(prayer.time)) in \(city)"
                 + (travelingMode ? " (traveling)" : "")
        }
    }

    /// The five obligatory prayers (and the names that route to them) - the ONLY notifications allowed
    /// to carry an adhan. Everything else - Shurooq, Duhaa, Islamic Midnight, Last Third, and any name
    /// added later - falls through to the system default sound by construction, not by enumeration.
    static let adhanEligiblePrayerNames: Set<String> = [
        "Fajr", "Dhuhr", "Jumuah", "Dhuhr/Asr", "Asr", "Maghrib", "Maghrib/Isha", "Isha"
    ]

    // MARK: - Prayer tracker

    /// The prayers the tracker records: the obligatory ones (including the traveling-mode combined
    /// names) - the same set that may carry an adhan.
    static var trackablePrayerNames: Set<String> { adhanEligiblePrayerNames }

    /// The five obligatory prayers in day order. Every tracker statistic is computed against these
    /// canonical names, whatever name a prayer was *recorded* under.
    static let canonicalObligatoryPrayers = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]

    /// Which of the five obligatory prayers a recorded (or displayed) name stands for. This is what makes
    /// a traveling-mode "Dhuhr/Asr" count as BOTH Dhuhr and Asr, "Maghrib/Isha" count as both, and a
    /// Friday "Jumuah" count as Dhuhr - in the tracker row, the history views, and every statistic.
    static func canonicalCoverage(of prayerName: String) -> Set<String> {
        switch prayerName {
        case "Dhuhr/Asr":    return ["Dhuhr", "Asr"]
        case "Maghrib/Isha": return ["Maghrib", "Isha"]
        case "Jumuah":       return ["Dhuhr"]
        default:             return canonicalObligatoryPrayers.contains(prayerName) ? [prayerName] : []
        }
    }

    /// The canonical prayers marked prayed on `date`, resolved through `canonicalCoverage` - so a day
    /// recorded while traveling ("Dhuhr/Asr") reads correctly after traveling mode turns off, and vice
    /// versa.
    func coveredCanonicalPrayers(on date: Date) -> Set<String> {
        coveredCanonicalPrayers(forDayKey: prayerTrackerKey(for: date))
    }

    func coveredCanonicalPrayers(forDayKey key: String) -> Set<String> {
        guard let day = loadPrayerTracker()[key] else { return [] }
        return day.reduce(into: Set<String>()) { $0.formUnion(Self.canonicalCoverage(of: $1)) }
    }

    /// Prayer names that can OWN a nag cascade (have a nagging preference): the next one of these
    /// after a prayer is where that prayer's nags are scheduled.
    private static let nagCascadeOwnerNames: Set<String> = [
        "Fajr", "Shurooq", "Dhuhr", "Dhuhr/Asr", "Jumuah", "Asr", "Maghrib", "Maghrib/Isha", "Isha"
    ]

    static let nagCategoryIdentifier = "PRAYER_NAG"
    static let nagActionMarkPrayedIdentifier = "PRAYER_NAG_MARK_PRAYED"
    static let nagPrayerNameUserInfoKey = "nagPrayerName"

    private static let prayerTrackerDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Decoded tracker, cached - rows read this on every render and the underlying data only changes
    /// through `savePrayerTracker`.
    private static var prayerTrackerCache: [String: Set<String>]?

    private func prayerTrackerKey(for date: Date) -> String {
        Self.prayerTrackerDayFormatter.string(from: date)
    }

    private func loadPrayerTracker() -> [String: Set<String>] {
        if let cached = Self.prayerTrackerCache { return cached }
        let decoded = (try? JSONDecoder().decode([String: [String]].self, from: prayerTrackerData)) ?? [:]
        let tracker = decoded.mapValues(Set.init)
        Self.prayerTrackerCache = tracker
        return tracker
    }

    private func savePrayerTracker(_ tracker: [String: Set<String>]) {
        var pruned = tracker
        // "yyyy-MM-dd" sorts lexicographically, so pruning is a string compare. Five years of history:
        // the year-by-year tracker views need real history, and a full year of marks is only a few KB.
        if let cutoffDate = Calendar.current.date(byAdding: .day, value: -1850, to: Date()) {
            let cutoff = prayerTrackerKey(for: cutoffDate)
            pruned = pruned.filter { $0.key >= cutoff }
        }
        Self.prayerTrackerCache = pruned
        prayerTrackerData = (try? JSONEncoder().encode(pruned.mapValues { Array($0).sorted() })) ?? Data()
    }

    /// True when everything `prayerName` stands for is covered on `date`: a combined "Dhuhr/Asr" row
    /// reads prayed only when BOTH are covered; a "Dhuhr" row reads prayed if the day recorded "Dhuhr",
    /// "Jumuah", or a combined "Dhuhr/Asr".
    func isPrayerMarkedPrayed(_ prayerName: String, on date: Date = Date()) -> Bool {
        let target = Self.canonicalCoverage(of: prayerName)
        guard !target.isEmpty else {
            return loadPrayerTracker()[prayerTrackerKey(for: date)]?.contains(prayerName) ?? false
        }
        return target.isSubset(of: coveredCanonicalPrayers(on: date))
    }

    /// How many of `prayerNames` are marked prayed on `date` (the tracker row's "3/5").
    func trackedPrayerCount(_ prayerNames: [String], on date: Date = Date()) -> Int {
        let covered = coveredCanonicalPrayers(on: date)
        return prayerNames.filter { name in
            let target = Self.canonicalCoverage(of: name)
            return !target.isEmpty && target.isSubset(of: covered)
        }.count
    }

    func setPrayerPrayed(_ prayerName: String, on date: Date = Date(), prayed: Bool) {
        var tracker = loadPrayerTracker()
        let key = prayerTrackerKey(for: date)
        var day = tracker[key] ?? []

        let target = Self.canonicalCoverage(of: prayerName)
        if prayed {
            // Combined rows are stored as their canonical members, so the record stays meaningful in
            // whatever mode it is later read. Jumuah is kept as itself - "prayed Jumuah" is worth
            // remembering, and its coverage makes it count as Dhuhr everywhere.
            if prayerName == "Jumuah" || target.isEmpty {
                day.insert(prayerName)
            } else {
                day.formUnion(target)
            }
        } else if target.isEmpty {
            day.remove(prayerName)
        } else {
            // Unmarking removes exactly the canonical prayers this name stands for. A stored entry that
            // covers MORE than that (unmarking "Dhuhr" on a day recorded as "Dhuhr/Asr") is replaced by
            // its residual coverage, so the other half stays prayed.
            for stored in day where !Self.canonicalCoverage(of: stored).isDisjoint(with: target) {
                day.remove(stored)
                day.formUnion(Self.canonicalCoverage(of: stored).subtracting(target))
            }
        }
        tracker[key] = day.isEmpty ? nil : day
        savePrayerTracker(tracker)

        // Yesterday's Isha still has live nags: they fire before TODAY's Fajr, under today's identifier
        // (marking Isha in the small hours records it on the previous civil day - see `trackerDate`).
        let affectsLiveNags = Calendar.current.isDateInToday(date)
            || (Calendar.current.isDateInYesterday(date) && target.contains("Isha"))

        if prayed {
            if Calendar.current.isDateInToday(date) {
                // Marking a prayer prayed TODAY also silences its remaining nags (they live under the
                // NEXT prayer's identifier).
                cancelNagsAboutPrayer(prayerName)
            } else if affectsLiveNags {
                cancelPendingNags(cascadePrayerName: "Fajr", on: Date())
            }
        } else if naggingMode, affectsLiveNags {
            // Unmarking re-arms them: the schedule is rebuilt, and the builder re-adds any nag
            // cascade that is no longer answered (see `nagCascadeIsAnswered`).
            fetchPrayerTimes(notification: true)
        }
    }

    // MARK: - Prayer tracker: exempt days (menses pause)

    /// Decoded exempt-day set, cached for the same reason as the tracker cache.
    private static var exemptDaysCache: Set<String>?

    private func loadExemptDays() -> Set<String> {
        if let cached = Self.exemptDaysCache { return cached }
        let decoded = (try? JSONDecoder().decode([String].self, from: trackerExemptDaysData)) ?? []
        let days = Set(decoded)
        Self.exemptDaysCache = days
        return days
    }

    private func saveExemptDays(_ days: Set<String>) {
        var pruned = days
        if let cutoffDate = Calendar.current.date(byAdding: .day, value: -1850, to: Date()) {
            let cutoff = prayerTrackerKey(for: cutoffDate)
            pruned = pruned.filter { $0 >= cutoff }
        }
        Self.exemptDaysCache = pruned
        trackerExemptDaysData = (try? JSONEncoder().encode(Array(pruned).sorted())) ?? Data()
    }

    var mensesPauseStartDate: Date? {
        mensesPauseStartStamp > 0 ? Date(timeIntervalSince1970: mensesPauseStartStamp) : nil
    }

    /// True when `date` is exempt from tracking: a recorded exempt day, or any day covered by the
    /// currently-active menses pause (its start through today, and every future day while it stays on).
    func isTrackerExempt(on date: Date) -> Bool {
        if isTrackerExempt(forDayKey: prayerTrackerKey(for: date)) { return true }
        if mensesPauseActive {
            let day = Calendar.current.startOfDay(for: date)
            let start = Calendar.current.startOfDay(for: mensesPauseStartDate ?? Date())
            return day >= start
        }
        return false
    }

    func isTrackerExempt(forDayKey key: String) -> Bool {
        if loadExemptDays().contains(key) { return true }
        guard mensesPauseActive, let start = mensesPauseStartDate else { return false }
        return key >= prayerTrackerKey(for: start)
    }

    /// Starts or ends the menses pause. Ending it writes every day of the finished range into the
    /// exempt-days set, so the pause is remembered by the history views after it is over. Both
    /// directions rebuild notifications, because the pause silences nagging reminders.
    func setMensesPause(_ active: Bool) {
        guard active != mensesPauseActive else { return }
        if active {
            mensesPauseStartStamp = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
            mensesPauseActive = true
        } else {
            var days = loadExemptDays()
            var day = Calendar.current.startOfDay(for: mensesPauseStartDate ?? Date())
            let today = Calendar.current.startOfDay(for: Date())
            while day <= today {
                days.insert(prayerTrackerKey(for: day))
                guard let next = Calendar.current.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
            saveExemptDays(days)
            mensesPauseActive = false
            mensesPauseStartStamp = 0
        }
        fetchPrayerTimes(notification: true)
    }

    /// Manual per-day correction from the history views. Days inside the ACTIVE pause range can't be
    /// individually un-exempted (end the pause instead) - the range is a single fact, not per-day marks.
    func setTrackerExempt(_ exempt: Bool, on date: Date) {
        let key = prayerTrackerKey(for: date)
        var days = loadExemptDays()
        if exempt { days.insert(key) } else { days.remove(key) }
        saveExemptDays(days)
        if Calendar.current.isDateInToday(date) || date > Date() {
            fetchPrayerTimes(notification: true)
        }
    }

    /// Whether the exempt state of `date` may be edited directly: false only for days covered by the
    /// live pause (turn the pause off to end it).
    func canEditExemption(on date: Date) -> Bool {
        guard mensesPauseActive, let start = mensesPauseStartDate else { return true }
        let day = Calendar.current.startOfDay(for: date)
        return day < Calendar.current.startOfDay(for: start)
    }

    // MARK: - Prayer tracker: statistics support

    /// The tracker's day key for `date` - public counterpart of `prayerTrackerKey` for the stats engine.
    func trackerDayKey(for date: Date) -> String {
        prayerTrackerKey(for: date)
    }

    /// One consistent snapshot of everything the statistics are computed from. Handing the decoded
    /// dictionaries out once lets the stats engine walk a whole year without a lookup-per-day through
    /// the accessor methods.
    func trackerSnapshot() -> (marks: [String: Set<String>], exemptDays: Set<String>, activePauseStartKey: String?) {
        let startKey = (mensesPauseActive && mensesPauseStartDate != nil)
            ? prayerTrackerKey(for: mensesPauseStartDate!) : nil
        return (loadPrayerTracker(), loadExemptDays(), startKey)
    }

    /// Drops the presence-checked tracker caches so the next read re-decodes from storage. Needed by the
    /// reset flows: after a defaults-domain wipe these caches kept serving the erased marks and exempt
    /// days until a cold launch (they don't key on the underlying data like the memo-style caches do).
    static func invalidateTrackerCaches() {
        prayerTrackerCache = nil
        exemptDaysCache = nil
    }

    /// The first day that has any mark or exemption - "tracking since". Nil until something is recorded.
    func trackerEarliestDayKey() -> String? {
        let marks = loadPrayerTracker().keys.min()
        let exempt = loadExemptDays().min()
        switch (marks, exempt) {
        case let (m?, e?): return min(m, e)
        default: return marks ?? exempt
        }
    }

    /// The prayer a nag BEFORE `cascadePrayerName` is actually about: the trackable prayer whose
    /// window ends when it arrives - i.e. the previous obligatory prayer of the day. A pre-Fajr nag
    /// is about Isha (the night prayer, begun the previous civil day).
    func naggedPrayerName(forCascade cascadePrayerName: String) -> String {
        guard let ordered = prayers?.prayers.sorted(by: { $0.time < $1.time }),
              let cascadeIndex = ordered.firstIndex(where: { $0.nameTransliteration == cascadePrayerName })
        else { return cascadePrayerName }

        let cascadeTime = ordered[cascadeIndex].time
        if let previous = ordered.last(where: {
            $0.time < cascadeTime && Self.trackablePrayerNames.contains($0.nameTransliteration)
                && $0.nameTransliteration != cascadePrayerName
        }) {
            return previous.nameTransliteration
        }
        return "Isha"
    }

    /// The civil day a "\(prayerName) prayed just now" belongs to: if today's instance hasn't started
    /// yet (answering a pre-Fajr nag about Isha in the small hours), the prayed instance was
    /// yesterday's.
    func trackerDate(forMarking prayerName: String, at now: Date = Date()) -> Date {
        if let time = prayers?.prayers.first(where: { $0.nameTransliteration == prayerName })?.time,
           time > now {
            return Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        }
        return now
    }

    /// The full "Yes, I prayed it" handling shared by the notification action and the in-app dialog.
    func markPrayerPrayedFromNag(asked prayerName: String, cascadePrayerName: String) {
        setPrayerPrayed(prayerName, on: trackerDate(forMarking: prayerName), prayed: true)
        cancelPendingNags(cascadePrayerName: cascadePrayerName)
    }

    /// Removes today's still-pending nag notifications scheduled under `cascadePrayerName`. Only the
    /// nag-cascade offsets go - the at-time adhan (minutes 0) and the user's own single
    /// pre-notification minute survive, since those announce the NEXT prayer, which is still coming.
    func cancelPendingNags(cascadePrayerName: String, on date: Date = Date()) {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        guard let y = comps.year, let m = comps.month, let d = comps.day else { return }
        let suffix = "-\(y)-\(m)-\(d)"
        let prefix = "\(cascadePrayerName)-"

        var cancellableMinutes = naggingCascade(start: naggingStartOffset)
        if let prefs = Self.notifTable[cascadePrayerName] {
            cancellableMinutes.remove(self[keyPath: prefs.preMinutes])
        }
        cancellableMinutes.remove(0)
        guard !cancellableMinutes.isEmpty else { return }

        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { id in
                guard id.hasPrefix(prefix), id.hasSuffix(suffix) else { return false }
                // "Name-minutes-y-m-d": the name never contains "-", so minutes is the 2nd field.
                let fields = id.split(separator: "-")
                guard fields.count >= 2, let minutes = Int(fields[1]) else { return false }
                return cancellableMinutes.contains(minutes)
            }
            if !ids.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: ids)
            }
        }
    }

    /// Silences today's remaining nags ABOUT `prayerName` - they are scheduled under the next
    /// nag-owning prayer's identifier, so resolve that successor and cancel its cascade.
    ///
    /// Matched by canonical coverage, not name equality, so marking "Dhuhr" from the history view still
    /// finds the traveling-mode "Dhuhr/Asr" row (and vice versa). When there is no successor left today
    /// (Isha, or the combined Maghrib/Isha), the nags about it live under TOMORROW's Fajr - cancel there.
    private func cancelNagsAboutPrayer(_ prayerName: String) {
        guard let ordered = prayers?.prayers.sorted(by: { $0.time < $1.time }) else { return }
        let target = Self.canonicalCoverage(of: prayerName)
        guard let index = ordered.firstIndex(where: {
            $0.nameTransliteration == prayerName
                || !Self.canonicalCoverage(of: $0.nameTransliteration).isDisjoint(with: target)
        }) else { return }

        if let successor = ordered.dropFirst(index + 1).first(where: {
            Self.nagCascadeOwnerNames.contains($0.nameTransliteration)
        }) {
            cancelPendingNags(cascadePrayerName: successor.nameTransliteration)
        } else if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
            cancelPendingNags(cascadePrayerName: "Fajr", on: tomorrow)
        }
    }

    /// userInfo key carrying the absolute instant (epoch seconds) a scheduled notification is FOR. The
    /// foreground delegate compares it to "now" at delivery and silences anything that arrives late.
    static let intendedFireDateUserInfoKey = "intendedFireDate"

    private func prayerNotificationSound(for prayer: Prayer, minutesBefore: Int?) -> UNNotificationSound {
        // Only an obligatory prayer's AT-TIME notification may play the adhan; the non-obligatory times
        // (Shurooq, Duhaa, Islamic Midnight, Last Third) always use the default sound.
        guard Self.adhanEligiblePrayerNames.contains(prayer.nameTransliteration) else { return .default }
        guard minutesBefore == nil else { return .default }

        #if os(iOS)
        guard playsAdhanSound(forPrayer: prayer.nameTransliteration) else { return .default }

        let length = adhanClipLength(forPrayer: prayer.nameTransliteration)
        guard let filename = adhanNotificationSoundFilename(for: adhanNotificationSound, length: length) else {
            return .default
        }
        return UNNotificationSound(named: UNNotificationSoundName(filename))
        #else
        return .default
        #endif
    }

    /// Builds an at-time / pre-notification prayer request. `isAdhan` marks the at-time notification of a
    /// main prayer (the one that carries the adhan sound) so the scheduler can prioritize it.
    private func makePrayerNotificationRequest(for prayer: Prayer, preNotificationTime minutes: Int?, city: String) -> (request: UNNotificationRequest, date: Date, isAdhan: Bool)? {
        let triggerTime: Date = {
            if let m = minutes, m != 0 {
                return Calendar.current.date(byAdding: .minute, value: -m, to: prayer.time) ?? prayer.time
            }
            return prayer.time
        }()

        guard triggerTime > Date() else { return nil }

        let content = UNMutableNotificationContent()
        content.title = AppIdentifiers.appName
        content.body = buildBody(prayer: prayer, minutesBefore: minutes, city: city)
        content.sound = prayerNotificationSound(for: prayer, minutesBefore: minutes)
        // The absolute instant this notification is FOR. The foreground delegate reads it and silences
        // any delivery that arrives well past its moment - an adhan belongs to its prayer time, never to
        // "whenever the system got around to it".
        content.userInfo[Self.intendedFireDateUserInfoKey] = triggerTime.timeIntervalSince1970
        #if os(iOS)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }

        // Nag-cascade deliveries carry the "Did you pray?" category: the notification gains a
        // "Yes, I prayed it" action, and tapping it in asks the same question in-app. Only actual
        // cascade offsets - the plain pre-notification and the at-time adhan stay plain.
        if let m = minutes, m != 0, naggingMode,
           let prefs = Self.notifTable[prayer.nameTransliteration],
           self[keyPath: prefs.nagging],
           naggingCascade(start: naggingStartOffset).contains(m) {
            content.categoryIdentifier = Self.nagCategoryIdentifier
            content.userInfo[Self.nagPrayerNameUserInfoKey] = prayer.nameTransliteration
        }
        #endif

        var comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerTime)
        // Pin the trigger to the zone the prayer time was computed in. Without an explicit timeZone,
        // iOS re-interprets these WALL-CLOCK components in whatever zone the device is in at delivery -
        // fly across time zones and a "1:30 PM Dhuhr/Asr" fires when the NEW local clock reads 1:30,
        // which can land anywhere in the day (the "Dhuhr/Asr adhan past Isha" report). Pinned, the
        // trigger stays the absolute instant the prayer actually occurs.
        comps.timeZone = Calendar.current.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let id = "\(prayer.nameTransliteration)-\(minutes ?? 0)-\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
        let req  = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        let isAdhan = minutes == nil
            && prayer.nameTransliteration != "Shurooq"
            && !Self.optionalPrayerNames.contains(prayer.nameTransliteration)
        return (req, triggerTime, isAdhan)
    }

    func scheduleNotification(for prayer: Prayer, preNotificationTime minutes: Int?, city: String, using center: UNUserNotificationCenter = .current()) {
        guard let built = makePrayerNotificationRequest(for: prayer, preNotificationTime: minutes, city: city) else { return }
        center.add(built.request) { error in
            if let error { logger.debug("Notification add failed: \(error.localizedDescription)") }
        }
    }

    private func makeEventNotificationRequest(for event: (String, DateComponents, String, String)) -> (request: UNNotificationRequest, date: Date)? {
        let (titleText, hijriComps, eventSubTitle, _) = event

        let gregorianCalendar = Calendar(identifier: .gregorian)

        // The Hijri components carry the current Hijri year, so an event that already passed this year
        // would otherwise produce no notification at all (its Gregorian date is in the past). Roll the
        // occurrence forward one Hijri year at a time until it lands in the future, so each event always
        // has an upcoming reminder scheduled - even late in the Hijri year after all of this year's
        // events are behind us.
        var comps = hijriComps
        var finalDate: Date?
        var beforeFajr = false
        for _ in 0...1 {
            guard let hijriDate = hijriCalendar.date(from: comps) else { return nil }
            let eventDay = gregorianCalendar.startOfDay(for: hijriDate)
            // Fire 30 minutes before Fajr on the event day (useful for fasting days - suhoor / intention).
            // Fajr needs computed prayer times, which need a location; if those aren't available, fall back
            // to 5:00 AM so the reminder still lands pre-dawn.
            let candidate: Date?
            // Found by name, not by position: a large manual Fajr offset can move it out of first place
            // now that the day is ordered chronologically.
            if let fajr = getPrayerTimes(for: eventDay, fullPrayers: true)?
                .first(where: { $0.nameTransliteration == "Fajr" }) {
                candidate = gregorianCalendar.date(byAdding: .minute, value: -30, to: fajr.time)
                beforeFajr = true
            } else {
                candidate = gregorianCalendar.date(bySettingHour: 5, minute: 0, second: 0, of: eventDay)
                beforeFajr = false
            }
            if let candidate, candidate > Date() {
                finalDate = candidate
                break
            }
            comps.year = (comps.year ?? hijriCalendar.component(.year, from: Date())) + 1
        }

        guard let finalDate else { return nil }
        var gregorianComps = gregorianCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate)
        // Pinned to the scheduling zone + stamped with its intended instant, same as the prayer
        // requests - see `makePrayerNotificationRequest`.
        gregorianComps.timeZone = gregorianCalendar.timeZone

        let content = UNMutableNotificationContent()
        content.title = AppIdentifiers.appName
        content.body = beforeFajr
            ? "\(titleText) is today - \(eventSubTitle). Sent 30 minutes before Fajr."
            : "\(titleText) is today - \(eventSubTitle)."
        content.sound = .default
        content.userInfo[Self.intendedFireDateUserInfoKey] = finalDate.timeIntervalSince1970
        #if os(iOS)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        #endif

        let trigger = UNCalendarNotificationTrigger(dateMatching: gregorianComps, repeats: false)
        // Stable identifier (title + date) so incremental rescheduling updates the same request in place
        // instead of churning a new UUID every refresh.
        let id = "Event-\(titleText)-\(gregorianComps.year ?? 0)-\(gregorianComps.month ?? 0)-\(gregorianComps.day ?? 0)"
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        return (request, finalDate)
    }

    func scheduleNotification(for event: (String, DateComponents, String, String), using center: UNUserNotificationCenter = .current()) {
        guard let built = makeEventNotificationRequest(for: event) else { return }
        center.add(built.request) { error in
            if let error = error {
                logger.debug("Failed to schedule special event notification: \(error)")
            }
        }
    }
    
    @inline(__always)
    private func binding<T>(_ key: ReferenceWritableKeyPath<Settings, T>, default value: T) -> Binding<T> {
        Binding(
            get: { self[keyPath: key] },
            set: { self[keyPath: key] = $0 }
        )
    }

    func currentNotification(prayerTime: Prayer) -> Binding<Bool> {
        guard let prefs = Self.notifTable[prayerTime.nameTransliteration] else {
            return .constant(false)
        }
        return binding(prefs.enabled, default: false)
    }

    func currentPreNotification(prayerTime: Prayer) -> Binding<Int> {
        guard let prefs = Self.notifTable[prayerTime.nameTransliteration] else {
            return .constant(0)
        }
        return binding(prefs.preMinutes, default: 0)
    }

    enum PrayerNotificationMode {
        case off
        case atTime
        case preNotification

        var symbolName: String {
            switch self {
            case .off:
                return "bell.slash"
            case .atTime:
                return "bell"
            case .preNotification:
                return "bell.fill"
            }
        }
    }

    func notificationMode(for prayerTime: Prayer) -> PrayerNotificationMode {
        guard let prefs = Self.notifTable[prayerTime.nameTransliteration] else { return .off }

        let enabled = self[keyPath: prefs.enabled]
        let preMinutes = self[keyPath: prefs.preMinutes]

        if enabled && preMinutes > 0 {
            return .preNotification
        }

        if enabled {
            return .atTime
        }

        return .off
    }

    func setNotificationMode(_ mode: PrayerNotificationMode, for prayerTime: Prayer) {
        guard let prefs = Self.notifTable[prayerTime.nameTransliteration] else { return }

        switch mode {
        case .off:
            self[keyPath: prefs.preMinutes] = 0
            self[keyPath: prefs.enabled] = false
        case .atTime:
            self[keyPath: prefs.preMinutes] = 0
            self[keyPath: prefs.enabled] = true
        case .preNotification:
            self[keyPath: prefs.preMinutes] = 15
            self[keyPath: prefs.enabled] = true
        }
    }

    @discardableResult
    func cycleNotificationMode(for prayerTime: Prayer) -> PrayerNotificationMode {
        let nextMode: PrayerNotificationMode

        switch notificationMode(for: prayerTime) {
        case .off:
            nextMode = .atTime
        case .atTime:
            nextMode = .preNotification
        case .preNotification:
            nextMode = .off
        }

        setNotificationMode(nextMode, for: prayerTime)
        return nextMode
    }

    func shouldShowFilledBell(prayerTime: Prayer) -> Bool {
        notificationMode(for: prayerTime) == .preNotification
    }

    func shouldShowOutlinedBell(prayerTime: Prayer) -> Bool {
        notificationMode(for: prayerTime) == .atTime
    }

    // MARK: - Travel & automatic calculation (UI prompts)

    func automaticTravelMessage(turnOn: Bool) -> String {
        // Name the home city the detection is measured against so the user knows the reference point. Falls
        // back to the city-less wording if no home is set (shouldn't happen - checkIfTraveling requires one
        // before raising this dialog - but keeps the copy clean if it's ever empty).
        let homeCity = homeLocation?.city
        if turnOn {
            if let homeCity, !homeCity.isEmpty {
                return "\(AppIdentifiers.appName) has automatically detected that you are traveling away from your home city of \(homeCity), so your prayers will be shortened."
            }
            return "\(AppIdentifiers.appName) has automatically detected that you are traveling, so your prayers will be shortened."
        }
        if let homeCity, !homeCity.isEmpty {
            return "\(AppIdentifiers.appName) has automatically detected that you have returned to your home city of \(homeCity), so your prayers will not be shortened."
        }
        return "\(AppIdentifiers.appName) has automatically detected that you are no longer traveling, so your prayers will not be shortened."
    }

    var automaticCalculationMessage: String {
        let country = calculationAutoDetectedCountryCode.isEmpty ? "unknown" : calculationAutoDetectedCountryCode
        return "\(AppIdentifiers.appName) detected your region as \(country) and switched prayer calculation from \(calculationAutoPreviousMethod) to \(calculationAutoDetectedMethod)."
    }

    func resetTravelAutomaticFlags() {
        travelTurnOnAutomatic = false
        travelTurnOffAutomatic = false
    }

    // MARK: Manual changes
    //
    // Every manual travel/calculation change funnels through one of these four, and all of them refresh with
    // `runAutoChecks: false` - the refresh that applies a person's explicit choice must never be the same
    // refresh that lets the automatic detection argue with it.

    /// The user flipped the Traveling Mode toggle themselves.
    func setTravelingModeManually(_ on: Bool) {
        withAnimation {
            travelingMode = on
        }
        resetTravelAutomaticFlags()
        fetchPrayerTimes(force: true, runAutoChecks: false)
    }

    /// The user picked a calculation method themselves (which also ends automatic selection).
    func setPrayerCalculationManually(_ method: String) {
        calculationAutomatic = false
        calculationAutoChanged = false
        withAnimation {
            prayerCalculation = method
        }
        fetchPrayerTimes(force: true, runAutoChecks: false)
    }

    func overrideTravelingMode(keepOn: Bool) {
        withAnimation {
            travelingMode = keepOn
        }
        travelAutomatic = false
        resetTravelAutomaticFlags()
        fetchPrayerTimes(force: true, runAutoChecks: false)
    }

    func confirmTravelAutomaticChange() {
        resetTravelAutomaticFlags()
    }

    func overrideAutomaticCalculationKeepingPrevious() {
        withAnimation {
            prayerCalculation = calculationAutoPreviousMethod
        }
        calculationAutomatic = false
        calculationAutoChanged = false
        fetchPrayerTimes(force: true, runAutoChecks: false)
    }

    func confirmAutomaticCalculationChange() {
        calculationAutoChanged = false
    }
}
