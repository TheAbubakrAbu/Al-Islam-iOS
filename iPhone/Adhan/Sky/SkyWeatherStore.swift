// Fetches the sky's weather from Apple Weather and keeps the one reading every sky paints from
// (SkyWeather.swift). The app only: a widget reads the cache this writes to the app group, which is
// what keeps the whole family inside the free allowance (one app fetch per half hour at most, and
// no widget ever calls Apple on its own).
//
// Needs the WeatherKit capability on the app's App ID (Certificates, Identifiers & Profiles, and
// again under App Services) and the `com.apple.developer.weatherkit` entitlement, which
// Entitlements-Main carries. Without the capability every request fails with a JWT error and the
// sky simply stays plain, which is also what the simulator shows until the App ID is set up.
//
// Al-Islam only (`HAS_WEATHER`, like iCloud Backup's `HAS_ICLOUD_BACKUP`): the companion apps
// compile none of this, and their sync manifests skip the flag (Abu, 2026-10-11).
#if os(iOS) && canImport(WeatherKit) && HAS_WEATHER
import SwiftUI
import CoreLocation
import WeatherKit
import WidgetKit

@MainActor
final class SkyWeatherStore: ObservableObject {
    static let shared = SkyWeatherStore()

    /// The last reading, fresh or not; readers take `freshWeather`.
    @Published private(set) var weather: SkyWeather?
    @Published private(set) var isFetching = false
    /// The last failure, for the detail sheet (the card itself never shows an error: no weather is
    /// just no weather).
    @Published private(set) var lastError: String?
    /// Apple's legal page for the attribution, from the service when it has answered, else the
    /// published address.
    @Published private(set) var legalURL = URL(string: "https://weatherkit.apple.com/legal-attribution.html")!
    /// A condition being tried on from the weather sheet (SkyWeatherCondition, Abu 2026-10-19: "allow
    /// me to preview somehow all the other conditions"). While set, every sky in the app paints the
    /// reading wearing it (`freshWeather`), whatever the switch and the reading's age say; the widgets
    /// never see it, since nothing is written to the cache. The sheet clears it on its way out.
    @Published var preview: SkyWeatherCondition?

    private var task: Task<Void, Never>?
    private var lastAttemptAt: Date?
    private var lastAttemptFailed = false
    /// After a failure the next try waits this long, so a missing capability or a dead network does
    /// not turn every tab appearance into a request.
    private static let retryAfterFailure: TimeInterval = 10 * 60

    private static let store = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)

    private var observers: [NSObjectProtocol] = []

    private init() {
        weather = SkyWeather.cached(in: Self.store)
        #if DEBUG
        if let fake = Self.debugFake() {
            weather = fake
            Self.write(fake)
        }
        #endif
        // Settings posts rather than calls (its files compile into the widget, which has no store).
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: Settings.skyWeatherSwitchDidChange, object: nil, queue: .main) { _ in
            Task { @MainActor in
                if Settings.shared.skyShowsWeather {
                    SkyWeatherStore.shared.refreshIfNeeded(force: true)
                } else {
                    SkyWeatherStore.shared.clear()
                }
            }
        })
        observers.append(center.addObserver(forName: Settings.skyWeatherRefreshRequested, object: nil, queue: .main) { _ in
            Task { @MainActor in SkyWeatherStore.shared.refreshIfNeeded() }
        })
    }

    /// The reading while it is still fresh and the switch is on; nil paints a plain sky. A preview
    /// from the sheet wins while it stands: the real reading wearing the chosen condition, or a sample
    /// in it when nothing has been fetched yet.
    var freshWeather: SkyWeather? {
        if let preview {
            if let weather { return weather.wearing(preview) }
            let location = Settings.shared.currentLocation
            return SkyWeather.sample(preview, latitude: location?.latitude ?? 21.4225, longitude: location?.longitude ?? 39.8262)
        }
        guard Settings.shared.skyShowsWeather, let weather, weather.isFresh() else { return nil }
        return weather
    }

    /// How long ago the reading was taken, for the sheet ("Updated 12 min ago").
    var updatedText: String? {
        guard let weather else { return nil }
        let minutes = Int(Date().timeIntervalSince(weather.fetchedAt) / 60)
        if minutes < 1 { return String(localized: "Updated just now") }
        if minutes < 60 { return String(localized: "Updated \(minutes) min ago") }
        let hours = minutes / 60
        return hours == 1 ? String(localized: "Updated \(hours) hour ago") : String(localized: "Updated \(hours) hours ago")
    }

    /// Asks Apple for the stored location when the reading is missing, half an hour old, or for
    /// another place. `force` (the sheet's Refresh) skips the age check but never the failure back-off
    /// or the five-minute floor, so a tap cannot run up the allowance.
    func refreshIfNeeded(force: Bool = false) {
        guard Settings.isAppProcess, Settings.shared.skyShowsWeather else { return }
        #if DEBUG
        if Self.debugFake() != nil { return }
        #endif
        guard let location = Settings.shared.currentLocation,
              location.latitude != 1000, location.longitude != 1000 else { return }
        if let weather, !force,
           weather.describes(latitude: location.latitude, longitude: location.longitude),
           !weather.needsRefresh() {
            return
        }
        let now = Date()
        if let lastAttemptAt {
            let floor: TimeInterval = lastAttemptFailed ? Self.retryAfterFailure : 5 * 60
            if now.timeIntervalSince(lastAttemptAt) < floor { return }
        }
        guard task == nil else { return }
        lastAttemptAt = now
        isFetching = true
        let fetch = Task { [weak self] in
            guard let self else { return }
            await self.fetch(latitude: location.latitude, longitude: location.longitude)
        }
        task = fetch
        Task { [weak self] in
            await fetch.value
            // Only the fetch still on record clears the flags: `clear()` (the switch going off) drops a
            // fetch mid-flight, and a refresh started after it must not be marked finished by the old one
            // (which also let a third request start beside the second).
            guard let self, self.task == fetch else { return }
            self.task = nil
            self.isFetching = false
        }
    }

    /// The switch went off: the reading is dropped everywhere, the widgets included.
    func clear() {
        task?.cancel()
        task = nil
        isFetching = false
        weather = nil
        preview = nil
        Self.store?.removeObject(forKey: SkyWeather.storageKey)
        Settings.shared.reloadWidgets(deferred: true)
    }

    private func fetch(latitude: Double, longitude: Double) async {
        // Kept for the companion apps, which still deploy to iOS 15: every WeatherKit type is iOS 16+.
        guard #available(iOS 16.0, *) else {
            lastAttemptFailed = true
            lastError = String(localized: "Weather needs iOS 16.")
            return
        }
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let service = WeatherService.shared
        do {
            let (current, hourly, daily) = try await service.weather(for: location, including: .current, .hourly, .daily)
            let now = Date()
            let hour = hourly.forecast.first { $0.date <= now && now < $0.date.addingTimeInterval(3600) }
                ?? hourly.forecast.first
            let today = daily.forecast.first { Calendar.current.isDate($0.date, inSameDayAs: now) }
            let reading = SkyWeather(
                fetchedAt: now,
                latitude: latitude,
                longitude: longitude,
                temperatureC: current.temperature.converted(to: .celsius).value,
                apparentC: current.apparentTemperature.converted(to: .celsius).value,
                highC: today?.highTemperature.converted(to: .celsius).value,
                lowC: today?.lowTemperature.converted(to: .celsius).value,
                humidity: current.humidity,
                dewPointC: current.dewPoint.converted(to: .celsius).value,
                uvIndex: current.uvIndex.value,
                uvCategory: current.uvIndex.category.description,
                cloudCover: current.cloudCover,
                condition: current.condition.rawValue,
                conditionText: current.condition.description,
                symbolName: current.symbolName,
                windKph: current.wind.speed.converted(to: .kilometersPerHour).value,
                windDirection: current.wind.compassDirection.abbreviation,
                visibilityKm: current.visibility.converted(to: .kilometers).value,
                pressureHPa: current.pressure.converted(to: .hectopascals).value,
                pressureTrend: current.pressureTrend.description,
                precipitationChance: hour?.precipitationChance,
                precipitationMm: hour?.precipitationAmount.converted(to: .millimeters).value ?? 0,
                isDaylight: current.isDaylight
            )
            guard !Task.isCancelled else { return }
            let previous = weather
            weather = reading
            lastError = nil
            lastAttemptFailed = false
            Self.write(reading)
            // The widgets paint from the cache: tell them only when their picture changes.
            if previous?.widgetSignature != reading.widgetSignature {
                Settings.shared.reloadWidgets(deferred: true)
            }
            if let attribution = try? await service.attribution {
                legalURL = attribution.legalPageURL
            }
        } catch {
            guard !Task.isCancelled else { return }
            lastAttemptFailed = true
            lastError = error.localizedDescription
            NSLog("SKY WEATHER fetch failed: %@", error.localizedDescription)
        }
    }

    private static func write(_ reading: SkyWeather) {
        guard let data = try? JSONEncoder().encode(reading) else { return }
        store?.set(data, forKey: SkyWeather.storageKey)
    }

    #if DEBUG
    /// `-fakeWeather <preset>[,<celsius>]` (see `SkyWeather.fake`).
    private static func debugFake() -> SkyWeather? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-fakeWeather"), arguments.indices.contains(index + 1) else { return nil }
        let parts = arguments[index + 1].split(separator: ",").map(String.init)
        let location = Settings.shared.currentLocation
        return SkyWeather.fake(preset: parts[0], celsius: parts.count > 1 ? Double(parts[1]) : nil,
                               latitude: location?.latitude ?? 21.4225, longitude: location?.longitude ?? 39.8262)
    }
    #endif
}
#endif
