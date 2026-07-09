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
    /// Each adhan ships as two clips: `<id>.caf` (the whole adhan) and `<id>-30.caf` (its opening 30
    /// seconds). iOS rejects notification sounds longer than 30 seconds, so notifications always get the
    /// short cut, while in-app playback and the settings preview get the full recording.
    static let supportedAdhanSounds: [AdhanSoundOption] = [
        .init(id: "default", title: "Default"),
        .init(id: "egypt", title: "Egypt"),
        .init(id: "makkah", title: "Makkah"),
        .init(id: "madina", title: "Madina"),
        .init(id: "alaqsa", title: "Al-Aqsa"),
        .init(id: "alaqsa-2", title: "Al-Aqsa 2"),

        .init(id: "abdulbaset", title: "Abdul Baset"),
        .init(id: "abdulghaffar", title: "Abdul Ghaffar"),
        .init(id: "al-qatami", title: "Al-Qatami"),
        .init(id: "minshawi-1", title: "Minshawi 1"),
        .init(id: "minshawi-2", title: "Minshawi 2"),
        .init(id: "zakariya", title: "Zakariya")
    ]

    static let defaultAdhanSoundID = "minshawi-1"
    static let adhanNotificationClipSuffix = "-30"

    static let supportedAdhanSoundIDs = Set(supportedAdhanSounds.map(\.id))
    private static var adhanSoundResourceCache: [String: String?] = [:]

    /// Resolves a picker id to a bundled `.caf` resource name, or `nil` for "Default" and for any id whose
    /// clip is missing from the bundle. `variant` picks the full recording ("") or the 30-second cut.
    private func adhanSoundResource(for selection: String, variant: String) -> String? {
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

    /// Filename of the 30-second cut, for `UNNotificationSound`.
    func adhanNotificationSoundFilename(for selection: String) -> String? {
        adhanSoundResource(for: selection, variant: Self.adhanNotificationClipSuffix)
            .map { "\($0).caf" }
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
        // picked something else, then never touch the choice again — the flag is what keeps a later re-pick
        // from being stomped on the next launch.
        if !defaults.bool(forKey: Self.didAdoptMinshawiDefaultKey) {
            defaults.set(true, forKey: Self.didAdoptMinshawiDefaultKey)
            // Only overwrite an explicit prior choice. A device that never set the key already resolves to
            // Minshawi 1 through the `@AppStorage` default, and the key must stay unset so `watchSyncSnapshot`
            // still omits it — otherwise a fresh Watch install would broadcast this default over an
            // established iPhone's real selection.
            if defaults.object(forKey: key) != nil {
                defaults.set(Self.defaultAdhanSoundID, forKey: key)
            }
        }
    }

    static let locationManager: CLLocationManager = {
        let lm = CLLocationManager()
        lm.desiredAccuracy = kCLLocationAccuracyBest
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
    private static var lastLocationCommitAt: Date?
    private static var lastFixAccuracy: CLLocationDistance?

    /// Stop the high-accuracy burst once a fix this good arrives.
    private static let refinementTargetAccuracy: CLLocationDistance = 12   // m
    /// Hard cap on how long the burst runs, in case a good fix never arrives.
    private static let refinementMaxDuration: TimeInterval = 25            // s
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
        let offsets: [Int]
    }

    private static var rawPrayerCache: [RawPrayerCacheKey: [Prayer]] = [:]
    private static let rawPrayerCacheLimit = 10
    private static let geocodeActor = GeocodeActor()
    private static let networkMonitor = NWPathMonitor()
    private static let networkMonitorQueue = DispatchQueue(label: AppIdentifiers.networkMonitorQueueLabel)
    private static var didStartNetworkMonitor = false
    private static var isNetworkReachable = true
    private static var pendingGeocodeCoord: CLLocationCoordinate2D?
    
    private static let oneMile: CLLocationDistance = 1609.34   // m
    private static let halfMile: CLLocationDistance = 500      // m
    private static let maxAge: TimeInterval = 180              // s
    
    private static let travelThresholdM: CLLocationDistance = 48 * oneMile   // ≈ 77 112 m

    private static func ensureNetworkMonitorStarted() {
        guard !didStartNetworkMonitor else { return }
        didStartNetworkMonitor = true

        networkMonitor.pathUpdateHandler = { path in
            let isNowReachable = (path.status == .satisfied)
            let becameReachable = isNowReachable && !isNetworkReachable
            isNetworkReachable = isNowReachable

            guard becameReachable else { return }

            let pending = pendingGeocodeCoord
            pendingGeocodeCoord = nil
            guard let pending else { return }

            Task { @MainActor in
                await Settings.shared.updateCity(latitude: pending.latitude, longitude: pending.longitude)
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
            if loc.horizontalAccuracy <= Self.refinementTargetAccuracy || elapsed >= Self.refinementMaxDuration {
                endLocationRefinement()
            }
        } else {
            commitLocation(loc, refining: false)
        }
    }

    /// Seeds the home location from the current location the first time we have a valid fix.
    /// A freshly installed app — or an existing user who never set a home — automatically adopts the
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
                // Same place, just a sharper fix — keep the city label, sharpen the coordinates so the
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
    func beginLocationRefinement() {
        #if os(iOS)
        let status = Self.locationManager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
        guard !Self.isRefiningLocation else { return }

        Self.isRefiningLocation = true
        Self.refinementStartedAt = Date()
        Self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        Self.locationManager.distanceFilter = kCLDistanceFilterNone
        Self.locationManager.startUpdatingLocation()

        let timeout = DispatchWorkItem { [weak self] in self?.endLocationRefinement() }
        Self.refinementTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.refinementMaxDuration, execute: timeout)
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
        Self.locationManager.stopUpdatingLocation()
        Self.locationManager.distanceFilter = Self.halfMile
        #endif
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
            let moved = CLLocation(latitude: cur.latitude, longitude: cur.longitude)
                .distance(from: CLLocation(latitude: latitude, longitude: longitude))
            if moved < Self.halfMile { return cur.city }
        }
        return "(\(latitude.stringRepresentation), \(longitude.stringRepresentation))"
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
        // resolves fine by relaying through the paired iPhone — and because the path never "becomes
        // reachable," the queued retry never fires, so the watch would sit on raw coordinates forever. So we
        // only trust the reachability flag to pre-empt the geocode on iOS; on the watch we always attempt it
        // and let a real geocode error (handled in the catch below) decide whether to defer.
        #if os(iOS)
        if !Self.isNetworkReachable {
            queueGeocodeForReconnect(coord)

            // Keep coordinates usable for prayer calculations while waiting for connectivity.
            if currentLocation == nil || currentLocation?.city.contains("(") == true {
                withAnimation {
                    currentLocation = Location(city: cityFallback(latitude: latitude, longitude: longitude),
                                               latitude: latitude, longitude: longitude)
                }
            }
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

        } catch {
            // On iOS an unreachable path means "wait for reconnect." On watchOS the path flag is unreliable
            // (see above), so only a genuine network geocode error defers — otherwise we fall through to the
            // backed-off retry, which is what actually lands a city on the watch.
            #if os(iOS)
            let networkDefer = isNetworkGeocodeError(error) || !Self.isNetworkReachable
            #else
            let networkDefer = isNetworkGeocodeError(error)
            #endif
            if networkDefer {
                queueGeocodeForReconnect(coord)
                logger.warning("Geocode deferred until network returns")
                return
            }

            logger.warning("Geocode attempt \(attempt+1) failed: \(error.localizedDescription)")
            guard attempt + 1 < maxAttempts else {
                // Only degrade the visible label to coordinates when we don't already have a still-valid
                // nearby city (handled by `cityFallback`); a far move yields honest coordinates.
                let fallbackCity = cityFallback(latitude: latitude, longitude: longitude)
                if fallbackCity != currentLocation?.city {
                    withAnimation {
                        currentLocation = Location(city: fallbackCity, latitude: latitude, longitude: longitude)
                        currentCountryCode = ""
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
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

    private static let countryCalculationMap: [String: String] = [
        // North America method (mainland + US territories commonly on ISNA-style defaults)
        "US": "North America",
        "CA": "North America",
        "MX": "North America",
        "PR": "North America",
        "VI": "North America",
        "GU": "North America",
        "AS": "North America",
        "MP": "North America",
        "UM": "North America",

        // United Kingdom
        "GB": "Britain (Moonsighting Committee)",
        "IE": "Britain (Moonsighting Committee)",

        // Saudi Arabia and nearby countries that commonly follow it
        "SA": "Saudi Arabia (Umm Al-Qura)",
        "BH": "Saudi Arabia (Umm Al-Qura)",
        "OM": "Saudi Arabia (Umm Al-Qura)",
        "YE": "Saudi Arabia (Umm Al-Qura)",

        // Egyptian method and nearby region defaults
        "EG": "Egypt",
        "LY": "Egypt",
        "TN": "Egypt",
        "DZ": "Egypt",
        "MA": "Egypt",
        "SD": "Egypt",
        "SS": "Egypt",
        "DJ": "Egypt",
        "ER": "Egypt",
        "SO": "Egypt",
        "JO": "Egypt",
        "LB": "Egypt",
        "SY": "Egypt",
        "IQ": "Egypt",
        "PS": "Egypt",

        // Gulf country-specific methods
        "AE": "Dubai",
        "KW": "Kuwait",
        "QA": "Qatar",

        // Turkey
        "TR": "Turkey",
        "CY": "Turkey",
        "AL": "Turkey",
        "XK": "Turkey",
        "BA": "Turkey",
        "MK": "Turkey",

        // Tehran
        "IR": "Tehran",

        // Karachi method (South Asia)
        "PK": "Karachi",
        "IN": "Karachi",
        "BD": "Karachi",
        "AF": "Karachi",
        "NP": "Karachi",
        "LK": "Karachi",

        // Singapore method (Southeast Asia)
        "SG": "Singapore",
        "MY": "Singapore",
        "BN": "Singapore",
        "ID": "Singapore",
        "TH": "Singapore",
        "PH": "Singapore"
    ]

    private func automaticCalculationMethod(for countryCode: String) -> String {
        Self.countryCalculationMap[countryCode] ?? "Muslim World League"
    }

    /// Recommended calculation-method label for an arbitrary ISO country code.
    /// Used when viewing/comparing other cities so each city can use the method
    /// appropriate to its country instead of the app's single global method.
    func recommendedCalculationMethod(forCountryCode countryCode: String) -> String {
        canonicalPrayerCalculationMethod(automaticCalculationMethod(for: countryCode.uppercased()))
    }

    /// Maps stored or auto-detected labels to a key that exists in `calcParams` (avoids repeat auto-changes / picker fights).
    private func canonicalPrayerCalculationMethod(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if Self.calcParams[trimmed] != nil { return trimmed }
        switch trimmed {
        case "Saudi Arabia":
            return "Saudi Arabia (Umm Al-Qura)"
        case "United Kingdom":
            return "Britain (Moonsighting Committee)"
        default:
            return "Muslim World League"
        }
    }

    /// Resolves the Adhan parameters for whatever string is stored (picker label, legacy name, or unknown → MWL fallback).
    private func calculationParameters(forStoredLabel name: String) -> CalculationParameters {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let params = Self.calcParams[trimmed] { return params }
        let canonical = canonicalPrayerCalculationMethod(trimmed)
        return Self.calcParams[canonical] ?? Self.calcParams["Muslim World League"]!
    }

    func checkAutomaticPrayerCalculation() {
        guard Bundle.main.bundleIdentifier?.contains("Widget") != true,
              calculationAutomatic,
              let currentLocation = currentLocation,
              currentLocation.latitude != 1000,
              currentLocation.longitude != 1000
        else { return }

        let countryCode = currentCountryCode.uppercased()
        guard !countryCode.isEmpty else { return }

        let detectedRaw = automaticCalculationMethod(for: countryCode)
        let detectedMethod = canonicalPrayerCalculationMethod(detectedRaw)
        guard let detectedParams = Self.calcParams[detectedMethod] else { return }

        let currentParams = calculationParameters(forStoredLabel: prayerCalculation)
        if detectedParams == currentParams {
            return
        }

        let previousMethod = prayerCalculation
        withAnimation {
            prayerCalculation = detectedMethod
        }

        calculationAutoPreviousMethod = previousMethod
        calculationAutoDetectedMethod = detectedMethod
        calculationAutoDetectedCountryCode = countryCode
        calculationAutoChanged = true

        #if os(iOS)
        let content = UNMutableNotificationContent()
        content.title = AppIdentifiers.appName
        content.body = "Prayer calculation switched to \(detectedMethod) for \(currentLocation.city)."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: Self.calculationNotificationId, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
        #endif
    }

    func checkIfTraveling() {
        guard Bundle.main.bundleIdentifier?.contains("Widget") != true,
              travelAutomatic,
              let currentLocation = currentLocation,
              let homeLocation = homeLocation,
              currentLocation.latitude != 1000,
              currentLocation.longitude != 1000
        else { return }

        let here  = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let home  = CLLocation(latitude: homeLocation.latitude, longitude: homeLocation.longitude)
        let miles = here.distance(from: home) / 1609.34
        let isAway = miles >= 48

        if isAway {
            if !travelingMode {
                withAnimation { travelingMode = true }
                travelTurnOffAutomatic = false
                travelTurnOnAutomatic  = true
                #if os(iOS)
                let content = UNMutableNotificationContent()
                content.title = AppIdentifiers.appName
                content.body  = "Traveling mode automatically turned on at \(currentLocation.city), away from your home city of \(homeLocation.city)"
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let req = UNNotificationRequest(identifier: Self.travelingNotificationId, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(req)
                #endif
            }
        } else {
            if travelingMode {
                withAnimation { travelingMode = false }
                travelTurnOnAutomatic  = false
                travelTurnOffAutomatic = true
                #if os(iOS)
                let content = UNMutableNotificationContent()
                content.title = AppIdentifiers.appName
                content.body  = "Traveling mode automatically turned off at \(currentLocation.city), near your home city of \(homeLocation.city)"
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let req = UNNotificationRequest(identifier: Self.travelingNotificationId, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(req)
                #endif
            }
        }
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
    
    private static let calcParams: [String: CalculationParameters] = {
        let map: [(String, CalculationMethod)] = [
            ("Muslim World League", .muslimWorldLeague),
            ("Britain (Moonsighting Committee)",      .moonsightingCommittee),
            ("Saudi Arabia (Umm Al-Qura)",        .ummAlQura),
            ("Egypt",               .egyptian),
            ("Dubai",               .dubai),
            ("Kuwait",              .kuwait),
            ("Qatar",               .qatar),
            ("Turkey",              .turkey),
            ("Tehran",              .tehran),
            ("Karachi",             .karachi),
            ("Singapore",           .singapore),
            ("North America",       .northAmerica),
            
            // Legacy labels kept for backward compatibility with saved settings.
            ("Moonsight Committee", .moonsightingCommittee),
            ("Umm Al-Qura",         .ummAlQura)
        ]
        return Dictionary(uniqueKeysWithValues: map.map { ($0.0, $0.1.params) })
    }()
    
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
            sunnahAfter: p.sunnahA
        )
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
            offsets: [offsetFajr, offsetSunrise, offsetDhuhr, offsetAsr, offsetMaghrib, offsetIsha]
        )

        if let cached = Self.rawPrayerCache[cacheKey] {
            return cached
        }

        var params = Self.calcParams[method] ?? Self.calcParams["Muslim World League"]!
        params.madhab = hanafiMadhab ? Madhab.hanafi : Madhab.shafi

        guard let raw = PrayerTimes(
                coordinates: Coordinates(latitude: here.latitude, longitude: here.longitude),
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
        
        if Self.rawPrayerCache.count > Self.rawPrayerCacheLimit {
            Self.rawPrayerCache.removeAll(keepingCapacity: true)
        }
        Self.rawPrayerCache[cacheKey] = list
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

    func fetchPrayerTimes(force: Bool = false, notification: Bool = false, calledFrom: StaticString = #function, completion: (() -> Void)? = nil) {
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
            let coord = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
            // watchOS: attempt the geocode regardless of the path-monitor flag (it under-reports on the watch,
            // see `updateCity`). iOS: only when the network is actually reachable, otherwise defer.
            #if os(iOS)
            let shouldAttemptGeocode = Self.isNetworkReachable
            #else
            let shouldAttemptGeocode = true
            #endif
            if shouldAttemptGeocode {
                Task { @MainActor in
                    await updateCity(latitude: loc.latitude, longitude: loc.longitude)
                    if Bundle.main.bundleIdentifier?.contains("Widget") != true,
                       calculationAutomatic,
                       !calculationManuallyToggled {
                        checkAutomaticPrayerCalculation()
                    }
                }
            } else {
                queueGeocodeForReconnect(coord)
                logger.debug("Skipping geocode while offline; will retry on reconnect")
            }
        }
        
        let isWidget = Bundle.main.bundleIdentifier?.contains("Widget") == true
        if !isWidget, travelAutomatic, homeLocation != nil, !travelingModeManuallyToggled {
            travelingModeManuallyToggled = false
            checkIfTraveling()
        } else if travelingModeManuallyToggled {
            travelingModeManuallyToggled = false
        }

        if !isWidget, calculationAutomatic, !calculationManuallyToggled {
            calculationManuallyToggled = false
            // Coordinate placeholder city means ISO country may still be wrong or empty; geocode runs
            // asynchronously above — we run the check again from that Task once the placemark is known.
            if !loc.city.contains("(") {
                checkAutomaticPrayerCalculation()
            }
        } else if calculationManuallyToggled {
            calculationManuallyToggled = false
        }
        
        // Decide if we need fresh prayers
        let today      = Date()
        let stored     = prayers
        let staleCity  = stored?.city != currentLocation?.city
        let staleDate  = !(stored?.day.isSameDay(as: today) ?? false)
        let emptyList  = stored?.prayers.isEmpty ?? true
        let needsFetch = force || stored == nil || staleCity || staleDate || emptyList

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
                city: currentLocation!.city,
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
    
    /// Efficiently filters raw prayers to traveling mode format (condensed list)
    private func _filterTravelingMode(_ rawPrayers: [Prayer]) -> [Prayer] {
        guard rawPrayers.count >= 6 else { return rawPrayers }

        let combinedDhuhrAsr = prayer(from: "Dhuhr/Asr", time: rawPrayers[2].time)
        let combinedMaghribIsha = prayer(from: "Maghrib/Isha", time: rawPrayers[4].time)

        return [rawPrayers[0], rawPrayers[1], combinedDhuhrAsr, combinedMaghribIsha]
    }
    
    func updateCurrentAndNextPrayer() {
        guard let prayerObj = prayers, !prayerObj.prayers.isEmpty else {
            logger.debug("No prayer list to compute current/next")
            return
        }

        let now = Date()
        let calendar = Calendar.current

        let timeline = [-1, 0, 1]
            .compactMap { calendar.date(byAdding: .day, value: $0, to: now) }
            .flatMap { date -> [Prayer] in
                let base = calendar.isDate(date, inSameDayAs: prayerObj.day)
                    ? prayerObj.prayers
                    : (getPrayerTimes(for: date) ?? [])
                return prayersIncludingOptional(base, for: date)
            }
            .sorted { $0.time < $1.time }

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

    /// Efficiently gets just the first prayer of a given day (optimized for getting tomorrow's Fajr)
    private func _getFirstPrayerOfDay(for date: Date) -> Prayer? {
        let raw = _computeRawPrayers(for: date)
        return raw.first  // Fajr is always first regardless of mode
    }
    
    /// Whether THIS device should schedule prayer notifications locally.
    ///
    /// The iPhone always schedules. The Watch schedules **only when it is standalone** — i.e. there is no
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
    /// synchronously (callers that must finish before reporting done — e.g. background refresh). `deferred ==
    /// true` trailing-debounces it on the main queue so the multiple `fetchPrayerTimes` calls fired during
    /// launch / setting changes collapse to one run, off the synchronous first-paint path.
    func scheduleNotifications(deferred: Bool) {
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
    private func offsets(for prefs: NotifPrefs) -> [Int] {
        var result: [Int] = []

        // “at time” alert
        if self[keyPath: prefs.enabled] { result.append(0) }

        // user‑defined single offset
        let minutes = self[keyPath: prefs.preMinutes]
        if self[keyPath: prefs.enabled], minutes > 0 {
            result.append(minutes)
        }

        // nagging offsets (if globally on *and* per‑prayer nagging on)
        if naggingMode && self[keyPath: prefs.nagging] {
            result += naggingCascade(start: naggingStartOffset)
        }
        return result
    }

    /// Generates exponential‑type cascade: 30,15,10,5 (by default)
    private func naggingCascade(start: Int) -> [Int] {
        guard start > 0 else { return [] }
        var m = start
        var out: [Int] = []
        while m > 15 { out.append(m); m -= 15 }
        if m >= 5  { out.append(m) }
        out += [10,5].filter { $0 < start }
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

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = AppIdentifiers.appName
        content.body  = "Please open the app to refresh today’s prayer times and notifications."
        content.sound = .default
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

    private func scheduleRefreshNag(
        inDays offset: Int = 2,
        hour: Int = 12,
        minute: Int = 0,
        using center: UNUserNotificationCenter = .current()
    ) {
        guard let built = makeRefreshNagRequest(inDays: offset, hour: hour, minute: minute) else { return }
        center.add(built.request) { error in
            if let error { logger.debug("Refresh reminder add failed: \(error.localizedDescription)") }
        }
    }

    func schedulePrayerTimeNotifications() {
        #if os(watchOS)
        guard shouldScheduleNotificationsLocally else {
            // A companion iPhone now owns notifications — clear anything this Watch scheduled while it was
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
        // notification sounds previously "didn't always work" — later prayers got dropped. Collect every
        // candidate, then add them in priority order under a safe cap so the at-time adhan always survives.
        let maxPending = 60

        var adhanRequests: [(request: UNNotificationRequest, date: Date)] = []
        var reminderRequests: [(request: UNNotificationRequest, date: Date)] = []

        // Prayer notifications need a resolved location + computed prayer times. Hijri-event reminders and
        // refresh nags below do NOT, so they're collected regardless of location — date notifications work
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

            for prayer in prayersIncludingOptional(prayerObj.prayers, for: prayerObj.day) {
                guard let prefs = Self.notifTable[prayer.nameTransliteration] else { continue }
                for minutes in offsets(for: prefs) {
                    collectPrayer(prayer, minutes == 0 ? nil : minutes)
                }
            }

            let futureDays = naggingMode ? 1 : 3
            if futureDays > 0 {
                for dayOffset in 1...futureDays {
                    let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: prayerObj.day) ?? Date()
                    guard let list = getPrayerTimes(for: date) else { continue }
                    for prayer in prayersIncludingOptional(list, for: date) {
                        guard let prefs = Self.notifTable[prayer.nameTransliteration] else { continue }
                        for minutes in offsets(for: prefs) {
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
        //   1. at-time adhan (the actual sound) — must never be dropped
        //   2. refresh nags — keep the rolling schedule alive so future days get rescheduled
        //   3. special-event reminders
        //   4. pre-/nagging reminders — fill whatever budget remains
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
        // never torn down — no brief window with zero pending, less churn, faster, and the system keeps the
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
                // pruning them here would delete the alert before it is ever delivered — which is exactly why
                // the "traveling mode turned on/off" notification never appeared.
                if id == Self.travelingNotificationId || id == Self.calculationNotificationId { return false }
                // When there were no prayers to rebuild (no location yet), only prune the categories we DID
                // rebuild — events and refresh nags. Leaving prayer notifications alone means a momentary
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
        guard name != "Shurooq", !Self.optionalPrayerNames.contains(name) else { return false }
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
            return "\(m)m until \(prayer.nameTransliteration)\(englishPart) in \(city)"
                 + (travelingMode ? " (traveling)" : "")
                 + " [\(formatDate(prayer.time))]"
        } else if prayer.nameTransliteration == "Fajr",
                  let list = prayers?.prayers, list.count > 1 {
            // Special Fajr “ends at …” text
            return "Time for \(prayer.nameTransliteration)\(englishPart)"
                 + " at \(formatDate(prayer.time)) in \(city)"
                 + (travelingMode ? " (traveling)" : "")
                 + " [ends at \(formatDate(list[1].time))]"
        } else {
            return "Time for \(prayer.nameTransliteration)\(englishPart)"
                 + " at \(formatDate(prayer.time)) in \(city)"
                 + (travelingMode ? " (traveling)" : "")
        }
    }

    private func prayerNotificationSound(for prayer: Prayer, minutesBefore: Int?) -> UNNotificationSound {
        // Shurooq and optional informational times use default sound, never full adhan.
        if prayer.nameTransliteration == "Shurooq" || Self.optionalPrayerNames.contains(prayer.nameTransliteration) {
            return .default
        }
        guard minutesBefore == nil else { return .default }

        #if os(iOS)
        guard let filename = adhanNotificationSoundFilename(for: adhanNotificationSound) else {
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
        #if os(iOS)
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        #endif

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerTime)
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
        // has an upcoming reminder scheduled — even late in the Hijri year after all of this year's
        // events are behind us.
        var comps = hijriComps
        var finalDate: Date?
        var beforeFajr = false
        for _ in 0...1 {
            guard let hijriDate = hijriCalendar.date(from: comps) else { return nil }
            let eventDay = gregorianCalendar.startOfDay(for: hijriDate)
            // Fire 30 minutes before Fajr on the event day (useful for fasting days — suhoor / intention).
            // Fajr needs computed prayer times, which need a location; if those aren't available, fall back
            // to 5:00 AM so the reminder still lands pre-dawn.
            let candidate: Date?
            if let fajr = getPrayerTimes(for: eventDay, fullPrayers: true)?.first {
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
        let gregorianComps = gregorianCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: finalDate)

        let content = UNMutableNotificationContent()
        content.title = AppIdentifiers.appName
        content.body = beforeFajr
            ? "\(titleText) is today — \(eventSubTitle). Sent 30 minutes before Fajr."
            : "\(titleText) is today — \(eventSubTitle)."
        content.sound = .default
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
        // back to the city-less wording if no home is set (shouldn't happen — checkIfTraveling requires one
        // before raising this dialog — but keeps the copy clean if it's ever empty).
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

    func overrideTravelingMode(keepOn: Bool) {
        travelingModeManuallyToggled = true
        withAnimation {
            travelingMode = keepOn
        }
        travelAutomatic = false
        resetTravelAutomaticFlags()
        fetchPrayerTimes(force: true)
    }

    func confirmTravelAutomaticChange() {
        resetTravelAutomaticFlags()
    }

    func overrideAutomaticCalculationKeepingPrevious() {
        calculationManuallyToggled = true
        withAnimation {
            prayerCalculation = calculationAutoPreviousMethod
        }
        calculationAutomatic = false
        calculationAutoChanged = false
        fetchPrayerTimes(force: true)
    }

    func confirmAutomaticCalculationChange() {
        calculationAutoChanged = false
    }
}
