// Location and notifications, asked for where they are explained (Abu, 2026-10-11: "have location and
// notification permissions come as a separate sheet"; 2026-10-19: "have them be buttons in a splash
// screen page"; 2026-11-05: "if location or notification is not given then have it be in the actual app
// to give it"). Two places ask, over one state (`PermissionAsker`):
//
// - the welcome's page (WelcomePages.swift, `WelcomePermissionsPage`), over the two rows of
//   `PermissionCards`;
// - the Adhan tab (`AdhanPermissionSection`): a card where the prayer times would be while location is
//   not allowed, and a smaller one above the list while notifications are not.
//
// The tab's cards replaced the permissions sheet this file was named for, and the daily "Location Access
// Needed" and "Notifications Off" dialogs (2026-11-05). The tab never raises a system prompt or a dialog
// of its own now: a card stays until its permission is given or, where the tab has something else to
// show, until it is put away. Settings' Request Access still asks on demand.
#if os(iOS)
import SwiftUI
import Combine
import CoreLocation
import UserNotifications

// MARK: - The state

/// The two permissions' status and the asking of them, for the welcome's page and the Adhan tab's cards.
@MainActor
final class PermissionAsker: ObservableObject {
    /// The Adhan tab's, kept current by the tab's own refreshes (`AdhanView.prayerTimeRefresh`).
    static let shared = PermissionAsker()

    @Published private(set) var locationStatus = Settings.locationManager.authorizationStatus
    /// Nil until the first look at the notification center.
    @Published private(set) var notificationStatus: UNAuthorizationStatus?
    @Published private(set) var asking = false

    private var cancellable: AnyCancellable?

    init() {
        // Location status changes arrive from `didChangeAuthorization` (posted on the main thread).
        cancellable = NotificationCenter.default.publisher(for: Settings.locationAuthorizationDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in self?.note(location: Settings.locationManager.authorizationStatus) }
            }
    }

    var locationAllowed: Bool {
        locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse
    }

    var locationDenied: Bool {
        locationStatus == .denied || locationStatus == .restricted
    }

    var notificationsAllowed: Bool {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    var notificationsDenied: Bool { notificationStatus == .denied }

    var locationUndetermined: Bool { locationStatus == .notDetermined }

    /// Unanswered, or not looked at yet (a page cannot say "all answered" before it knows).
    var notificationsUndetermined: Bool {
        notificationStatus == nil || notificationStatus == .notDetermined
    }

    func refresh() async {
        let notifications = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        note(location: Settings.locationManager.authorizationStatus)
        note(notifications: notifications)
    }

    /// Only a change publishes (the Adhan tab refreshes on every activation), and it animates: a card
    /// leaves the tab as its permission arrives.
    private func note(location status: CLAuthorizationStatus) {
        guard status != locationStatus else { return }
        withAnimation(.easeInOut) { locationStatus = status }
    }

    private func note(notifications status: UNAuthorizationStatus) {
        guard status != notificationStatus else { return }
        withAnimation(.easeInOut) { notificationStatus = status }
    }

    /// Raises the system's location prompt; `done` runs once it is answered (at once when it already is).
    func askLocation(then done: (() -> Void)? = nil) {
        asking = true
        Settings.shared.requestLocationIfUndetermined { [weak self] in
            Task { @MainActor in
                self?.note(location: Settings.locationManager.authorizationStatus)
                self?.asking = false
                done?()
            }
        }
    }

    /// Raises the system's notification prompt; `done` runs once it is answered (or was not put: Allow
    /// Notifications off in the app).
    func askNotifications(then done: (() -> Void)? = nil) {
        asking = true
        Settings.shared.requestNotificationAuthorization { [weak self] in
            Task { @MainActor in
                await self?.refresh()
                self?.asking = false
                done?()
            }
        }
    }

    /// The app's page in the Settings app: the only door once iOS holds a permission denied.
    static func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - The welcome's card

/// The two permissions as two rows of one card, each with its status: an empty ring until it is asked, a
/// tick once it is allowed, Open Settings once iOS holds it denied. The welcome's one button does the
/// asking (`WelcomePermissionsPage`).
struct PermissionCards: View {
    @ObservedObject var asker: PermissionAsker
    private let settings = Settings.shared
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @Environment(\.appearance) private var appearance
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showHomePicker = false

    /// The system prompt's own promise: only Apple's services ever receive the location (the city
    /// name, nearby places, and on Al-Islam the opt-in sky weather), never anyone else.
    static var footnote: String {
        String(localized: "Only \(AppIdentifiers.displayName) and Apple ever see your location.")
    }

    /// The Location row's text. The first fix is saved as the home city (`seedHomeLocationIfNeeded`) and
    /// Traveling Mode measures from it, which readers who installed away from home never knew (Abu,
    /// 2026-10-31), so the row says it; the Adhan tutorial tells the rest.
    static var locationText: String {
        String(localized: "Where you are now is saved as your home city.")
    }

    /// The home city the Location row names, with its Change button: only once location is allowed and a
    /// fix has named a city, so the row never shows an empty or stale guess.
    static func homeCity(locationAllowed: Bool, home: Location?) -> String? {
        guard locationAllowed,
              let city = home?.displayCity.trimmingCharacters(in: .whitespacesAndNewlines),
              !city.isEmpty else { return nil }
        return city
    }

    var body: some View {
        VStack(spacing: 0) {
            row(systemImage: "location.fill", title: String(localized: "Location"), text: Self.locationText,
                allowed: asker.locationAllowed, denied: asker.locationDenied)

            if let city = Self.homeCity(locationAllowed: asker.locationAllowed, home: adhanSettings.homeLocation) {
                homeRow(city)
            }

            Divider()
                .padding(.leading, 61)

            row(systemImage: "bell.badge.fill", title: String(localized: "Notifications"),
                text: String(localized: "The adhan at each prayer."),
                allowed: asker.notificationsAllowed, denied: asker.notificationsDenied)
        }
        .padding(.vertical, 4)
        .background(WelcomeCardSurface())
        .sheet(isPresented: $showHomePicker) {
            MapView(choosingPrayerTimes: false)
                .environmentObject(settings)
                .smallMediumSheetPresentation()
        }
    }

    private func row(systemImage: String, title: String, text: String, allowed: Bool, denied: Bool) -> some View {
        HStack(alignment: .center, spacing: 13) {
            AccentIconChip(systemImage: systemImage, size: 34)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(text)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            status(allowed: allowed, denied: denied)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    @ViewBuilder
    private func status(allowed: Bool, denied: Bool) -> some View {
        if denied {
            Button {
                settings.hapticFeedback()
                PermissionAsker.openAppSettings()
            } label: {
                Text("Open Settings")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(appearance.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(appearance.accent.opacity(0.14)))
            }
            .buttonStyle(.plain)
        } else {
            Image(systemName: allowed ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(allowed ? appearance.accent : Color.secondary.opacity(0.5))
                .accessibilityLabel(allowed ? Text("Allowed") : Text("Not asked"))
        }
    }

    /// "Home city: X" and a Change button that opens the same map as Settings › Prayer Settings ›
    /// Traveling Mode › Set Home City, for whoever is not at home right now.
    private func homeRow(_ city: String) -> some View {
        HStack(spacing: 8) {
            Text("Home city: \(city)")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button {
                settings.hapticFeedback()
                showHomePicker = true
            } label: {
                Text("Change")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(appearance.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(appearance.accent.opacity(0.14)))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("permissionsChangeHomeCity")
        }
        .padding(.leading, dynamicTypeSize.isAccessibilitySize ? 14 : 61)
        .padding(.trailing, 14)
        .padding(.bottom, 11)
    }
}

// MARK: - On the Adhan tab

/// Which of the two asks the Adhan tab shows. Pure, so SkyWeatherTests can pin it.
enum PermissionAsk {
    /// Location, until it is allowed. With no times to show, the card is all the tab has and cannot be
    /// put away; over times from a stored place, its X is Never Ask Again.
    static func showsLocation(allowed: Bool, hasTimes: Bool, neverAskAgain: Bool) -> Bool {
        !allowed && !(hasTimes && neverAskAgain)
    }

    /// Notifications, unanswered or denied, while the app's own Allow Notifications is on and the card
    /// has not been put away. Not looked at yet (nil) shows nothing, so no card flashes at launch.
    static func showsNotifications(status: UNAuthorizationStatus?, enabledInApp: Bool, neverAskAgain: Bool) -> Bool {
        guard enabledInApp, !neverAskAgain else { return false }
        return status == .notDetermined || status == .denied
    }
}

/// The Adhan tab's asks, as rows of the tab: "Turn On Location" where the prayer times would be, and
/// "Turn On Notifications" above the list. A button asks right there, or opens the Settings app once iOS
/// holds the permission denied (the system prompt is put only once).
struct AdhanPermissionSection: View {
    private let settings = Settings.shared
    @ObservedObject private var asker = PermissionAsker.shared
    /// The slice that publishes the two Never Ask Again flags and Allow Notifications.
    @ObservedObject private var adhanSettings = AdhanSettings.shared
    @Environment(\.appearance) private var appearance

    /// Whether the tab has prayer times on screen (from a stored place, while location is not allowed).
    let hasTimes: Bool
    /// An ask was answered: the tab refreshes its times and its schedule.
    let onAnswered: () -> Void

    var body: some View {
        if PermissionAsk.showsLocation(allowed: asker.locationAllowed, hasTimes: hasTimes,
                                       neverAskAgain: settings.locationNeverAskAgain) {
            Section {
                if hasTimes {
                    row(systemImage: "location.fill", title: String(localized: "Turn On Location"),
                        text: String(localized: "Location is off, so these times are for the last place \(AppIdentifiers.displayName) knew."),
                        button: locationButtonTitle, identifier: "adhanAllowLocation", action: askLocation,
                        close: { settings.locationNeverAskAgain = true })
                } else {
                    locationCard
                }
            }
            .transition(.opacity)
        }

        if PermissionAsk.showsNotifications(status: asker.notificationStatus, enabledInApp: settings.notificationsEnabled,
                                            neverAskAgain: settings.notificationNeverAskAgain) {
            Section {
                row(systemImage: "bell.badge.fill", title: String(localized: "Turn On Notifications"),
                    text: asker.notificationsDenied
                        ? String(localized: "Notifications are off for \(AppIdentifiers.displayName) in the Settings app.")
                        : String(localized: "Hear the adhan at each prayer."),
                    button: asker.notificationsDenied ? String(localized: "Open Settings") : String(localized: "Allow Notifications"),
                    identifier: "adhanAllowNotifications", action: askNotifications,
                    close: { settings.notificationNeverAskAgain = true })
            }
            .transition(.opacity)
        }
    }

    private var locationButtonTitle: String {
        asker.locationDenied ? String(localized: "Open Settings") : String(localized: "Allow Location")
    }

    /// With no times to show, the ask is the tab's whole middle: centred, with the one prominent button.
    private var locationCard: some View {
        VStack(spacing: 8) {
            AccentIconChip(systemImage: "location.fill", size: 48)
                .padding(.bottom, 4)
                .accessibilityHidden(true)

            Text("Turn On Location")
                .font(.title3.bold())
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(asker.locationDenied
                 ? String(localized: "Location is off for \(AppIdentifiers.displayName) in the Settings app. Prayer times and the Qibla need it.")
                 : String(localized: "Prayer times and the Qibla need to know where you are."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: askLocation) {
                Text(locationButtonTitle)
                    .font(.headline)
            }
            .buttonStyle(.glassAction)
            .disabled(asker.asking)
            .padding(.top, 8)
            .accessibilityIdentifier("adhanAllowLocation")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    /// The smaller ask, in the grammar of the tab's other notices (`TutorialNudgeSection`): what it is,
    /// one line on why, its button, and an X that puts it away for good.
    private func row(systemImage: String, title: String, text: String, button: String, identifier: String,
                     action: @escaping () -> Void, close: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AccentIconChip(systemImage: systemImage, size: 34)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(text)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Borderless: two buttons in one List row each keep their own tap.
                Button(action: action) {
                    Text(button)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(appearance.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(appearance.accent.opacity(0.14)))
                }
                .buttonStyle(.borderless)
                .disabled(asker.asking)
                .padding(.top, 4)
                .accessibilityIdentifier(identifier)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) { close() }
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Close"))
            .accessibilityIdentifier("\(identifier)Close")
        }
        .padding(.vertical, 4)
    }

    private func askLocation() {
        settings.hapticFeedback()
        if asker.locationUndetermined {
            asker.askLocation(then: onAnswered)
        } else {
            PermissionAsker.openAppSettings()
        }
    }

    private func askNotifications() {
        settings.hapticFeedback()
        if asker.notificationsUndetermined {
            asker.askNotifications(then: onAnswered)
        } else {
            PermissionAsker.openAppSettings()
        }
    }
}
#endif
