#if os(iOS)
import BackgroundTasks
import CoreLocation
import UIKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let taskID = AppIdentifiers.backgroundFetchPrayerTimesTaskIdentifier
    private let reciterDownloadsSessionID = AppIdentifiers.reciterDownloadsBackgroundSessionIdentifier
    
    // Connects iOS background URL session wakeups to the reciter download manager.
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        guard identifier == reciterDownloadsSessionID else {
            completionHandler()
            return
        }

        ReciterDownloadManager.shared.backgroundSessionCompletionHandler(completionHandler)
    }

    // Performs startup setup: registers background refresh, schedules first refresh, and notification delegate.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        registerBackgroundRefreshTask()
        scheduleBackgroundRefreshes()
        UNUserNotificationCenter.current().delegate = self

        // Re-arm the background refreshes every time the app is backgrounded - via the NOTIFICATION,
        // not the legacy `applicationDidEnterBackground` delegate method: this is a scene-based
        // (SwiftUI-lifecycle) app, so UIKit never calls that method and the old re-arm was dead code.
        // Launch-time scheduling alone left a single far-future request that the system routinely
        // dropped - the "background refresh never runs" bug.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main
        ) { _ in
            self.scheduleBackgroundRefreshes()
        }

        // The nag cascade's "Did you pray?" action. No .foreground option: answering from the lock
        // screen marks the tracker and silences the remaining nags without ever opening the app.
        let markPrayed = UNNotificationAction(
            identifier: Settings.nagActionMarkPrayedIdentifier,
            title: "Yes, I prayed it",
            options: []
        )
        let nagCategory = UNNotificationCategory(
            identifier: Settings.nagCategoryIdentifier,
            actions: [markPrayed],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([nagCategory])
        // A time-zone change (landing after a flight, DST) invalidates every scheduled prayer trigger:
        // the times must be recomputed and the whole schedule rebuilt for the new zone immediately, not
        // whenever the next fetch happens to run - stale triggers are how a "Dhuhr/Asr" adhan sounds at
        // night. The triggers are also zone-pinned (see `makePrayerNotificationRequest`), so even before
        // this fires nothing drifts to a wrong wall-clock moment.
        NotificationCenter.default.addObserver(
            forName: .NSSystemTimeZoneDidChange, object: nil, queue: .main
        ) { _ in
            Settings.shared.fetchPrayerTimes(force: true)
        }
        return true
    }


    // Shows in-app notifications as banner + sound when a notification arrives in foreground, and keeps
    // them in Notification Center (.list) so a missed banner isn't lost.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // An adhan (or any prayer alert) belongs to its MOMENT. The system can deliver scheduled local
        // notifications late while the app is open (a suspended runloop, Mac/Catalyst, a slept device) -
        // if this delivery is well past the instant it was scheduled for, keep it silently in the list
        // instead of blaring a full adhan at some unrelated time of day.
        if let intended = notification.request.content.userInfo[Settings.intendedFireDateUserInfoKey] as? TimeInterval,
           Date().timeIntervalSince1970 - intended > 180 {
            completionHandler([.list])
            return
        }
        completionHandler([.banner, .list, .sound])
    }

    // Handles nag-notification responses: the "Yes, I prayed it" action marks the tracker and cancels
    // the rest of that cascade directly; a plain tap opens the app and raises the same question as an
    // in-app dialog (see AdhanView).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let content = response.notification.request.content
        guard content.categoryIdentifier == Settings.nagCategoryIdentifier,
              let cascadeName = content.userInfo[Settings.nagPrayerNameUserInfoKey] as? String else {
            completionHandler()
            return
        }

        let actionIdentifier = response.actionIdentifier
        DispatchQueue.main.async {
            let settings = Settings.shared
            let asked = settings.naggedPrayerName(forCascade: cascadeName)
            switch actionIdentifier {
            case Settings.nagActionMarkPrayedIdentifier:
                settings.markPrayerPrayedFromNag(asked: asked, cascadePrayerName: cascadeName)
            case UNNotificationDefaultActionIdentifier:
                // Already marked (from the tracker, or an earlier nag in the cascade) - asking "did you
                // pray it?" again would be exactly the nagging the mark was supposed to end.
                if !settings.isPrayerMarkedPrayed(asked, on: settings.trackerDate(forMarking: asked)) {
                    settings.pendingNagQuestion = .init(prayerName: asked, cascadePrayerName: cascadeName)
                }
            default:
                break
            }
            completionHandler()
        }
    }

    // Registers both background task handlers: the opportunistic app refresh and its overnight
    // BGProcessingTask twin. Both run the same refresh; they differ only in when the system grants them
    // time (short daytime windows vs. the nightly maintenance window that lines up with pre-Fajr).
    private func registerBackgroundRefreshTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            self.handleAppRefresh(task: task)
        }
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: AppIdentifiers.backgroundProcessingRefreshTaskIdentifier, using: nil
        ) { task in
            self.handleAppRefresh(task: task)
        }
    }

    // Submits both pending requests. Safe to call repeatedly - a submit replaces any pending request
    // with the same identifier.
    private func scheduleBackgroundRefreshes() {
        // The app refresh asks for the pre-Fajr target but never more than 4 hours out: iOS routinely
        // drops a lone request ~20 hours in the future, and each run re-arms the next one anyway - so
        // through the day this yields a few opportunistic refreshes (fresh widgets, the traveling-mode
        // check) and the last one lands near Fajr.
        let refresh = BGAppRefreshTaskRequest(identifier: taskID)
        refresh.earliestBeginDate = min(nextRunDate(), Date().addingTimeInterval(4 * 60 * 60))
        submit(refresh, label: "BGAppRefresh")

        // The processing request keeps the true pre-Fajr target: processing tasks run in the system's
        // nightly maintenance window, which is the slot that actually matches it. Network required -
        // the refresh geocodes and fetches.
        let processing = BGProcessingTaskRequest(identifier: AppIdentifiers.backgroundProcessingRefreshTaskIdentifier)
        processing.earliestBeginDate = nextRunDate()
        processing.requiresNetworkConnectivity = true
        processing.requiresExternalPower = false
        submit(processing, label: "BGProcessing")
    }

    private func submit(_ request: BGTaskRequest, label: String) {
        if let date = request.earliestBeginDate {
            logger.debug("🔧 Scheduling \(label) – earliestBeginDate: \(date.formatted())")
        }
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.debug("✅ \(label) submitted")
        } catch {
            // Expected on the Simulator (background tasks are unsupported there) - harmless.
            logger.error("❌ \(label) submit failed: \(error.localizedDescription)")
        }
    }

    // Calculates the next refresh time (before tomorrow's Fajr, with a minimum lead time).
    private func nextRunDate(offsetMins: Double = 35) -> Date {
        guard let fajr = nextFajrTime else {
            return Date().addingTimeInterval(24 * 60 * 60)
        }

        let timeParts = Calendar.current.dateComponents([.hour, .minute, .second], from: fajr)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let scheduledTomorrow = Calendar.current.date(
            bySettingHour: timeParts.hour ?? 0,
            minute: timeParts.minute ?? 0,
            second: timeParts.second ?? 0,
            of: tomorrow
        ) ?? tomorrow

        let target = scheduledTomorrow.addingTimeInterval(-offsetMins * 60)
        let minimum = Date().addingTimeInterval(15 * 60)
        return max(target, minimum)
    }

    // Reads the earliest prayer time from saved prayer data (used as Fajr anchor).
    private var nextFajrTime: Date? {
        Settings.shared.prayers?
            .prayers
            .sorted(by: { $0.time < $1.time })
            .first?
            .time
    }

    // Executes when either background task fires: re-schedules both, handles expiration, and refreshes
    // prayer times (with a fresh location fix when authorized - see below).
    private func handleAppRefresh(task: BGTask) {
        logger.debug("🚀 Background refresh fired (\(task.identifier))")
        scheduleBackgroundRefreshes()

        // `setTaskCompleted` must be called exactly once. The expiration handler and the fetch completion
        // can race (e.g. the fetch finishes just as the task expires), so gate it behind a lock + flag.
        let completionLock = NSLock()
        var didComplete = false
        func complete(_ success: Bool) {
            completionLock.lock()
            defer { completionLock.unlock() }
            guard !didComplete else { return }
            didComplete = true
            task.setTaskCompleted(success: success)
        }

        task.expirationHandler = {
            logger.error("⏰ BG task expired before finishing")
            complete(false)
        }

        // A refresh computed against the stored location faithfully rebuilds widgets for the city you LEFT
        // and feeds the traveling-mode check coordinates from before the trip. Ask for one fresh fix first:
        // its delegate callback commits the move, and that commit re-fetches prayer times, reschedules
        // notifications and reloads widgets on its own. The fetch below still runs immediately with the
        // stored location, so the task succeeds even when no fix arrives.
        let requestedLocationFix = Settings.locationManager.authorizationStatus == .authorizedAlways
        if requestedLocationFix {
            Settings.locationManager.requestLocation()
        }

        Settings.shared.fetchPrayerTimes {
            logger.debug("🎉 BG task completed – prayer times refreshed")
            guard requestedLocationFix else {
                complete(true)
                return
            }
            // Hold the task open a beat so the one-shot fix - and the commit/fetch/reload chain it
            // triggers - can land before iOS suspends the process. BGAppRefresh allows ~30 s; the
            // expiration handler still completes us if the system calls time first.
            DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                complete(true)
            }
        }
    }
}
#endif
