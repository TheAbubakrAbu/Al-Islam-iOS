// The permissions sheet (Abu, 2026-10-11: "have location and notification permissions come as a
// separate sheet"). A new install used to meet the two bare system prompts the moment the Adhan tab
// was in front, one after the other, with nothing to say why. Now the tab presents this sheet first:
// one card per permission that says what it is for, with the status beside it and its own Allow
// button, and one primary button that asks for both in turn (location first, so two system prompts
// never stand on top of each other). Not Now puts the sheet away for a day (the same snooze the
// tab's Location Access Needed and Notifications Off dialogs use) and, while it stands, the tab
// never raises a system prompt on its own: this sheet is the one door to them. Settings' Request
// Access still asks on demand.
#if os(iOS)
import SwiftUI
import CoreLocation
import UserNotifications

struct PermissionsSheet: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var locationStatus = Settings.locationManager.authorizationStatus
    @State private var notificationStatus: UNAuthorizationStatus?
    @State private var asking = false

    private var accent: Color { settings.accentColor.color }

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
                        header
                        locationCard
                        notificationCard
                        Text(Self.footnote)
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

                actions
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
        .interactiveDismissDisabled(asking)
        .task { await refreshNotificationStatus() }
        .onReceive(NotificationCenter.default.publisher(for: Settings.locationAuthorizationDidChange)) { _ in
            locationStatus = Settings.locationManager.authorizationStatus
        }
    }

    // MARK: Pieces

    /// The system prompt's own promise: only Apple's services ever receive the location (the city
    /// name, nearby places, and on Al-Islam the opt-in sky weather), never anyone else.
    private static var footnote: String {
        "You can change either later in the Settings app. Only \(AppIdentifiers.appName) and Apple ever see your location, and it is never shared with anyone else."
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "location.north.circle.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(accent)
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

    private var locationCard: some View {
        card(systemImage: "location.fill", title: "Location",
             text: "Prayer times, the Qibla and Traveling Mode all start from where you are. Always lets the times and the widgets follow you without opening the app.",
             status: locationStatusText, allowed: locationAllowed, denied: locationStatus == .denied || locationStatus == .restricted,
             allow: askLocation)
    }

    private var notificationCard: some View {
        card(systemImage: "bell.badge.fill", title: "Notifications",
             text: "The adhan at each prayer, and reminders before them if you want them.",
             status: notificationStatusText, allowed: notificationsAllowed,
             denied: notificationStatus == .denied,
             allow: askNotifications)
    }

    private func card(systemImage: String, title: String, text: String, status: String, allowed: Bool,
                      denied: Bool, allow: @escaping () -> Void) -> some View {
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
                .disabled(asking)
                .padding(.leading, dynamicTypeSize.isAccessibilitySize ? 0 : 47)
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

    private var actions: some View {
        VStack(spacing: 6) {
            Button {
                settings.hapticFeedback()
                primaryAction()
            } label: {
                HStack(spacing: 8) {
                    if asking { ProgressView().tint(.primary) }
                    Text(primaryTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .conditionalGlassEffect(rectangle: true, useColor: 0.38, customTint: AppIdentifiers.mainColor.color)
            .disabled(asking)
            .accessibilityIdentifier("permissionsPrimary")

            if anythingUndetermined {
                Button {
                    settings.hapticFeedback()
                    dismiss()
                } label: {
                    Text("Not Now")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(asking)
                .accessibilityIdentifier("permissionsNotNow")
            }
        }
    }

    // MARK: State

    private var locationAllowed: Bool {
        locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse
    }

    private var notificationsAllowed: Bool {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    private var locationStatusText: String {
        switch locationStatus {
        case .notDetermined: return "Not asked"
        case .authorizedAlways: return "Always"
        case .authorizedWhenInUse: return "While Using"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        @unknown default: return "Unknown"
        }
    }

    private var notificationStatusText: String {
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

    private var anythingUndetermined: Bool {
        locationStatus == .notDetermined || notificationStatus == .notDetermined
    }

    private var primaryTitle: String {
        let location = locationStatus == .notDetermined
        let notifications = notificationStatus == .notDetermined
        if location && notifications { return "Allow Location & Notifications" }
        if location { return "Allow Location" }
        if notifications { return "Allow Notifications" }
        return "Done"
    }

    /// Both in turn (location first), or whichever is left, or done.
    private func primaryAction() {
        guard anythingUndetermined else {
            dismiss()
            return
        }
        asking = true
        settings.requestLocationIfUndetermined {
            locationStatus = Settings.locationManager.authorizationStatus
            settings.requestNotificationAuthorization {
                Task { @MainActor in
                    await refreshNotificationStatus()
                    asking = false
                }
            }
        }
    }

    private func askLocation() {
        asking = true
        settings.requestLocationIfUndetermined {
            locationStatus = Settings.locationManager.authorizationStatus
            asking = false
        }
    }

    private func askNotifications() {
        asking = true
        settings.requestNotificationAuthorization {
            Task { @MainActor in
                await refreshNotificationStatus()
                asking = false
            }
        }
    }

    @MainActor
    private func refreshNotificationStatus() async {
        notificationStatus = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
#endif
