// The permissions sheet (Abu, 2026-10-11: "have location and notification permissions come as a
// separate sheet"). A new install used to meet the two bare system prompts the moment the Adhan tab
// was in front, one after the other, with nothing to say why. Now the tab presents this sheet first:
// one card per permission that says what it is for, with the status beside it and its own Allow
// button, and one primary button that asks for both in turn (location first, so two system prompts
// never stand on top of each other). Not Now puts the sheet away for a day (the same snooze the
// tab's Location Access Needed and Notifications Off dialogs use) and, while it stands, the tab
// never raises a system prompt on its own: this sheet is the one door to them. Settings' Request
// Access still asks on demand.
//
// Since 2026-10-19 the first launch asks on a page of the welcome instead (WelcomePages.swift,
// `WelcomePermissionsPage`; Abu: "instead of asking location and notification at the same time have
// them be buttons in a splash screen page"). That page and this sheet are the same two cards over the
// same state, `PermissionAsker` and `PermissionCards` below; its Skip snoozes like Not Now does, so
// the sheet never follows the welcome with the same question.
#if os(iOS)
import SwiftUI
import Combine
import CoreLocation
import UserNotifications

// MARK: - The state

/// The two permissions' status and the asking of them, for the sheet and the welcome's page.
@MainActor
final class PermissionAsker: ObservableObject {
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
                Task { @MainActor in self?.locationStatus = Settings.locationManager.authorizationStatus }
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

    var anythingUndetermined: Bool { locationUndetermined || notificationsUndetermined }

    var locationStatusText: String {
        switch locationStatus {
        case .notDetermined: return "Not asked"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "While Using"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        @unknown default: return "Unknown"
        }
    }

    var notificationStatusText: String {
        switch notificationStatus {
        case nil: return "Checking"
        case .notDetermined?: return "Not asked"
        case .denied?: return "Denied"
        case .authorized?: return "Allowed"
        case .provisional?: return "Provisional"
        case .ephemeral?: return "Ephemeral"
        default: return "Unknown"
        }
    }

    func refresh() async {
        notificationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        locationStatus = Settings.locationManager.authorizationStatus
    }

    func askLocation() {
        asking = true
        Settings.shared.requestLocationIfUndetermined { [weak self] in
            Task { @MainActor in
                self?.locationStatus = Settings.locationManager.authorizationStatus
                self?.asking = false
            }
        }
    }

    func askNotifications() {
        asking = true
        Settings.shared.requestNotificationAuthorization { [weak self] in
            Task { @MainActor in
                await self?.refresh()
                self?.asking = false
            }
        }
    }

    /// Both in turn (location first), so two system prompts never stand on top of each other.
    func askBoth() {
        asking = true
        Settings.shared.requestLocationIfUndetermined { [weak self] in
            Task { @MainActor in
                self?.locationStatus = Settings.locationManager.authorizationStatus
                Settings.shared.requestNotificationAuthorization { [weak self] in
                    Task { @MainActor in
                        await self?.refresh()
                        self?.asking = false
                    }
                }
            }
        }
    }

    /// Whatever is still unanswered waits a day (the dialogs' snooze), so nothing asks again the moment
    /// the welcome or the sheet is put away.
    func snoozeUnanswered() {
        if locationUndetermined { Settings.shared.snoozePermissionAlert(location: true) }
        if notificationsUndetermined { Settings.shared.snoozePermissionAlert(location: false) }
    }
}

// MARK: - The pieces

/// "Prayer times for where you are": the sentence above the two cards.
struct PermissionsIntro: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "location.north.circle.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(appearance.accent)
                .padding(.bottom, 2)
                .accessibilityHidden(true)

            Text("Prayer times for where you are")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text("Two permissions make \(AppIdentifiers.appName) work on its own: one to find today's times, one to call you to them.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The two cards, each with its status and its own Allow button.
struct PermissionCards: View {
    @ObservedObject var asker: PermissionAsker
    @ObservedObject private var settings = Settings.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var accent: Color { settings.accentColor.color }

    /// The system prompt's own promise: only Apple's services ever receive the location (the city
    /// name, nearby places, and on Al-Islam the opt-in sky weather), never anyone else.
    static var footnote: String {
        "You can change either later in the Settings app. Only \(AppIdentifiers.appName) and Apple ever see your location, and it is never shared with anyone else."
    }

    var body: some View {
        VStack(spacing: 18) {
            card(systemImage: "location.fill", title: "Location",
                 text: "Prayer times, the Qibla and Traveling Mode all start from where you are. Always lets the times and the widgets follow you without opening the app.",
                 status: asker.locationStatusText, allowed: asker.locationAllowed, denied: asker.locationDenied,
                 identifier: "permissionsAllowLocation", allow: asker.askLocation)

            card(systemImage: "bell.badge.fill", title: "Notifications",
                 text: "The adhan at each prayer, and reminders before them if you want them.",
                 status: asker.notificationStatusText, allowed: asker.notificationsAllowed, denied: asker.notificationsDenied,
                 identifier: "permissionsAllowNotifications", allow: asker.askNotifications)
        }
    }

    private func card(systemImage: String, title: String, text: String, status: String, allowed: Bool,
                      denied: Bool, identifier: String, allow: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 13) {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(LinearGradient(colors: [accent, accent.opacity(0.74)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer(minLength: 4)
                        statusPill(status, allowed: allowed, denied: denied)
                    }
                    Text(text)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !allowed {
                Button {
                    settings.hapticFeedback()
                    if denied { openAppSettings() } else { allow() }
                } label: {
                    Text(denied ? "Open Settings" : "Allow \(title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(accent.opacity(0.14))
                        )
                }
                .buttonStyle(.plain)
                .disabled(asker.asking)
                .padding(.leading, dynamicTypeSize.isAccessibilitySize ? 0 : 47)
                .accessibilityIdentifier(identifier)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func statusPill(_ text: String, allowed: Bool, denied: Bool) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundColor(allowed ? .green : (denied ? .red : .secondary))
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background(Capsule().fill((allowed ? Color.green : (denied ? Color.red : Color.secondary)).opacity(0.14)))
            .accessibilityLabel("Status, \(text)")
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - The sheet

struct PermissionsSheet: View {
    @ObservedObject private var settings = Settings.shared
    @StateObject private var asker = PermissionAsker()
    @Environment(\.dismiss) private var dismiss

    /// Whether the tab should put this sheet up: a permission is still unanswered, not snoozed and not
    /// declared Never Ask Again. Pure, so SimpleModeTests can pin it. DEBUG: `-skipNotificationPrompt`
    /// (every headless recipe) never shows it, and `-showPermissionsSheet` always does.
    static func shouldPresent(locationUndetermined: Bool, notificationsUndetermined: Bool,
                              locationSnoozedUntil: Double, notificationSnoozedUntil: Double,
                              locationNeverAskAgain: Bool, notificationNeverAskAgain: Bool,
                              now: Date = Date()) -> Bool {
        let location = locationUndetermined && !locationNeverAskAgain
            && !SimpleMode.isSnoozed(until: locationSnoozedUntil, now: now)
        let notifications = notificationsUndetermined && !notificationNeverAskAgain
            && !SimpleMode.isSnoozed(until: notificationSnoozedUntil, now: now)
        return location || notifications
    }

    @MainActor
    static func shouldPresent(_ settings: Settings) async -> Bool {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-showPermissionsSheet") { return true }
        if arguments.contains("-skipNotificationPrompt") { return false }
        #endif
        let notifications = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        return shouldPresent(
            locationUndetermined: Settings.locationManager.authorizationStatus == .notDetermined,
            notificationsUndetermined: notifications == .notDetermined,
            locationSnoozedUntil: settings.locationAlertSnoozedUntil,
            notificationSnoozedUntil: settings.notificationAlertSnoozedUntil,
            locationNeverAskAgain: settings.locationNeverAskAgain,
            notificationNeverAskAgain: settings.notificationNeverAskAgain)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        PermissionsIntro()
                        PermissionCards(asker: asker)
                        Text(PermissionCards.footnote)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 22)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }

                WelcomeActionBar(
                    primaryTitle: primaryTitle,
                    primaryBusy: asker.asking,
                    primaryIdentifier: "permissionsPrimary",
                    primaryAction: primaryAction,
                    secondaryTitle: asker.anythingUndetermined ? "Not Now" : nil,
                    secondaryIdentifier: "permissionsNotNow",
                    secondaryAction: { dismiss() }
                )
                .frame(maxWidth: 560)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .accentWashedBackground()
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
        .smallMediumSheetPresentation(startLarge: true)
        .interactiveDismissDisabled(asker.asking)
        .task { await asker.refresh() }
    }

    private var primaryTitle: String {
        let location = asker.locationUndetermined
        let notifications = asker.notificationsUndetermined
        if location && notifications { return "Allow Location & Notifications" }
        if location { return "Allow Location" }
        if notifications { return "Allow Notifications" }
        return "Done"
    }

    /// Both in turn (location first), or whichever is left, or done.
    private func primaryAction() {
        guard asker.anythingUndetermined else {
            dismiss()
            return
        }
        asker.askBoth()
    }
}
#endif
