// A newer version on the App Store is offered when the app opens (Abu, 2026-10-19: "if there is a new
// update tell them to update it with a confirmation dialog when opening the app").
//
// The App Store's lookup service says which version it is selling. When that is newer than the one
// running, and it runs on this iOS, a confirmation dialog rises over the app once it is on screen:
// Update opens the store page, Later puts it away. Paced like the app's other launch prompts (the
// review ask, the traveling dialog, a tapped notification's question): the store is asked at most once
// every six hours, the dialog is raised at most once a day for a given version, never over the launch
// or welcome cover, never on top of a sheet or another dialog, and the first minutes of a fresh install
// are left to the welcome. Presented UIKit-side on the topmost controller, the way the prayer question
// is (AppDelegate.swift): a SwiftUI dialog on the root is a popover on the iPad with no Cancel, and a
// controller found at the moment of asking lands on whatever the reader is looking at.
//
// iPhone target only. The companion apps wire the same file into their own roots (`appUpdatePrompt()`)
// and read their own `AppIdentifiers.appStoreID`.
#if os(iOS)
import SwiftUI
import UIKit

@MainActor
final class AppUpdateChecker {
    static let shared = AppUpdateChecker()

    /// What the store answered: the version it sells and the lowest iOS that version runs on.
    struct StoreListing: Equatable {
        let version: String
        let minimumOSVersion: String
        let storeURL: URL?
    }

    /// The store is not asked again sooner than this.
    nonisolated static let checkInterval: TimeInterval = 6 * 60 * 60
    /// The same version is not offered again sooner than this.
    nonisolated static let offerInterval: TimeInterval = 24 * 60 * 60
    /// How long after the app is on screen the dialog waits, so it rises over a settled tab.
    private static let settleDelay: TimeInterval = 1.5

    private enum Key {
        static let lastCheckedAt = "appUpdate.lastCheckedAt"
        static let listingVersion = "appUpdate.listingVersion"
        static let listingMinimumOS = "appUpdate.listingMinimumOS"
        static let listingURL = "appUpdate.listingURL"
        static let lastOfferedVersion = "appUpdate.lastOfferedVersion"
        static let lastOfferedAt = "appUpdate.lastOfferedAt"
    }

    private let defaults = UserDefaults.standard
    private var running: Task<Void, Never>?
    private weak var presented: UIAlertController?

    private init() {}

    // MARK: The pure rules (nonisolated: no state, and the unit tests call them off the main actor)

    /// Dotted versions compared number by number ("4.7" > "4.6.5"; "4.6.5" == "4.6.5.0"). Anything that
    /// is not a number counts as zero, so a build suffix never makes a version look newer.
    nonisolated static func isVersion(_ candidate: String, newerThan installed: String) -> Bool {
        compare(candidate, installed) == .orderedDescending
    }

    nonisolated static func compare(_ a: String, _ b: String) -> ComparisonResult {
        let left = components(a)
        let right = components(b)
        for index in 0..<max(left.count, right.count) {
            let l = index < left.count ? left[index] : 0
            let r = index < right.count ? right[index] : 0
            if l != r { return l < r ? .orderedAscending : .orderedDescending }
        }
        return .orderedSame
    }

    nonisolated private static func components(_ version: String) -> [Int] {
        version.split(separator: ".").map { Int($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
    }

    /// Whether `listing` is worth the dialog on a device running `installed` on iOS `os`, given when this
    /// same version was last offered. Pure, so the unit tests pin it.
    nonisolated static func shouldOffer(listing: StoreListing, installed: String, os: String,
                                        lastOfferedVersion: String, lastOfferedAt: Date?, now: Date) -> Bool {
        guard isVersion(listing.version, newerThan: installed) else { return false }
        // A version this iOS cannot install is not an update for this device.
        if compare(listing.minimumOSVersion, os) == .orderedDescending { return false }
        if lastOfferedVersion == listing.version, let lastOfferedAt,
           now.timeIntervalSince(lastOfferedAt) < offerInterval {
            return false
        }
        return true
    }

    /// The lookup service's answer (`results[0]`): `version`, `minimumOsVersion` and `trackViewUrl`.
    /// Nil when the store lists nothing for the id (an unreleased app, a storefront it is not in).
    nonisolated static func parseListing(_ data: Data) -> StoreListing? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = object["results"] as? [[String: Any]],
              let first = results.first,
              let version = first["version"] as? String, !version.isEmpty else { return nil }
        let minimum = first["minimumOsVersion"] as? String ?? "1.0"
        let url = (first["trackViewUrl"] as? String).flatMap(URL.init(string:))
        return StoreListing(version: version, minimumOSVersion: minimum, storeURL: url)
    }

    /// The lookup URL for this app in `region` ("us"); the storefront matters, since a release can take
    /// hours to reach every country.
    nonisolated static func lookupURL(bundleIdentifier: String, region: String) -> URL? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "bundleId", value: bundleIdentifier),
            URLQueryItem(name: "country", value: region.lowercased()),
        ]
        return components?.url
    }

    // MARK: Asking

    /// Called when the app opens (the root's `appUpdatePrompt()`: at launch and on each return to the
    /// foreground). Asks the store when the last answer is old, then offers the update when the rules
    /// say so. One run at a time; a second call while one is in flight is a no-op.
    func checkAndOffer() {
        guard running == nil else { return }
        running = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.running = nil }
            guard let listing = await self.currentListing() else { return }
            guard self.shouldOffer(listing) else { return }
            await self.present(listing)
        }
    }

    private var installedVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    private func shouldOffer(_ listing: StoreListing) -> Bool {
        #if DEBUG
        if Self.debugListing() != nil { return true }
        #endif
        let offeredAt = defaults.object(forKey: Key.lastOfferedAt) as? Date
        return Self.shouldOffer(listing: listing, installed: installedVersion, os: UIDevice.current.systemVersion,
                                lastOfferedVersion: defaults.string(forKey: Key.lastOfferedVersion) ?? "",
                                lastOfferedAt: offeredAt, now: Date())
    }

    /// The cached answer while it is under `checkInterval` old, else a fresh one from the store (and
    /// nil when the store cannot be reached: no dialog is better than a wrong one).
    private func currentListing() async -> StoreListing? {
        #if DEBUG
        if let fake = Self.debugListing() { return fake }
        #endif
        if let checked = defaults.object(forKey: Key.lastCheckedAt) as? Date,
           Date().timeIntervalSince(checked) < Self.checkInterval {
            return cachedListing()
        }
        let listing = await fetchListing()
        defaults.set(Date(), forKey: Key.lastCheckedAt)
        if let listing {
            defaults.set(listing.version, forKey: Key.listingVersion)
            defaults.set(listing.minimumOSVersion, forKey: Key.listingMinimumOS)
            defaults.set(listing.storeURL?.absoluteString, forKey: Key.listingURL)
        }
        return listing ?? cachedListing()
    }

    private func cachedListing() -> StoreListing? {
        guard let version = defaults.string(forKey: Key.listingVersion), !version.isEmpty else { return nil }
        return StoreListing(version: version,
                            minimumOSVersion: defaults.string(forKey: Key.listingMinimumOS) ?? "1.0",
                            storeURL: defaults.string(forKey: Key.listingURL).flatMap(URL.init(string:)))
    }

    /// The device's storefront first, then the US one when that lists nothing (the app is not in every
    /// country, and a reader abroad still deserves the answer).
    private func fetchListing() async -> StoreListing? {
        let region: String
        if #available(iOS 16.0, *) {
            region = Locale.current.region?.identifier ?? "us"
        } else {
            region = Locale.current.regionCode ?? "us"
        }
        var regions = [region.lowercased()]
        if region.lowercased() != "us" { regions.append("us") }
        for candidate in regions {
            guard let url = Self.lookupURL(bundleIdentifier: AppIdentifiers.bundleIdentifier, region: candidate) else { continue }
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 12)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? true else { continue }
                if let listing = Self.parseListing(data) { return listing }
            } catch {
                NSLog("APP UPDATE lookup failed: %@", error.localizedDescription)
                return nil
            }
        }
        return nil
    }

    /// Waits for the screen to be able to take a dialog (on screen, foreground, nothing modal up), then
    /// raises it. Gives up for this opening after a minute of waiting; the next opening tries again.
    private func present(_ listing: StoreListing) async {
        await AppReveal.waitUntilRevealed()
        try? await Task.sleep(nanoseconds: UInt64(Self.settleDelay * 1_000_000_000))
        for _ in 0..<60 {
            guard !Task.isCancelled else { return }
            if presentNow(listing) { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

    /// True once the dialog is up (or must not be: the screen is busy, try again later is false).
    private func presentNow(_ listing: StoreListing) -> Bool {
        guard AppReveal.revealed,
              UIApplication.shared.applicationState == .active,
              !ModalPresence.isPresenting,
              presented == nil,
              let top = topmostViewController(),
              !(top is UIAlertController),
              top.transitionCoordinator == nil, !top.isBeingPresented, !top.isBeingDismissed
        else { return false }

        let settings = Settings.shared
        let installed = installedVersion
        // iPad (and the Mac) get an alert: their action sheets are popovers, which need an anchor this
        // question does not have and which drop the Cancel button. iPhone keeps the sheet that slides
        // up from the bottom, the app's confirmation-dialog shape.
        let alert = UIAlertController(
            title: "Update Available",
            message: "\(AppIdentifiers.appName) \(listing.version) is on the App Store, and you have \(installed). Updating brings the latest fixes and features.",
            preferredStyle: UIDevice.current.userInterfaceIdiom == .phone ? .actionSheet : .alert
        )
        alert.addAction(UIAlertAction(title: "Update", style: .default) { _ in
            settings.hapticFeedback()
            UIApplication.shared.open(listing.storeURL ?? AppIdentifiers.appStoreURL)
        })
        alert.addAction(UIAlertAction(title: "Later", style: .cancel) { _ in
            settings.hapticFeedback()
        })
        alert.view.tintColor = UIColor(settings.accentColor.color)

        top.present(alert, animated: true)
        presented = alert
        defaults.set(listing.version, forKey: Key.lastOfferedVersion)
        defaults.set(Date(), forKey: Key.lastOfferedAt)
        return true
    }

    #if DEBUG
    /// `-fakeUpdate <version>`: the store "sells" that version, no network and no pacing, so the dialog
    /// can be screenshotted (`-fakeUpdate 9.9`).
    private static func debugListing() -> StoreListing? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-fakeUpdate"), arguments.indices.contains(index + 1) else { return nil }
        return StoreListing(version: arguments[index + 1], minimumOSVersion: "16.0", storeURL: AppIdentifiers.appStoreURL)
    }
    #endif
}

// MARK: - The root's hook

private struct AppUpdatePromptModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onAppear { AppUpdateChecker.shared.checkAndOffer() }
            .onChange(of: scenePhase) { phase in
                guard phase == .active else { return }
                AppUpdateChecker.shared.checkAndOffer()
            }
    }
}

extension View {
    /// Offers a newer App Store version when the app opens. See `AppUpdateChecker`.
    func appUpdatePrompt() -> some View {
        modifier(AppUpdatePromptModifier())
    }
}
#endif
