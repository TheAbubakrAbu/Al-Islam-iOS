#if os(iOS)
import BackgroundTasks
import CoreLocation
import SwiftUI
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
        // The two `BGTaskScheduler.submit`s are synchronous XPC round trips: off the first-paint path.
        // Every backgrounding re-arms them (below); the first arm waits for the launch cover to lift.
        Task { @MainActor in
            await AppReveal.waitUntilRevealed()
            self.scheduleBackgroundRefreshes()
            // (The reminders' launch pass, the Sunnah presets and the extra kinds together, runs
            // from MainTabView's post-reveal schedule at +1.5 s: `ReminderScheduler.rearmAfterLaunch`.)
        }
        UNUserNotificationCenter.current().delegate = self

        // The selected adhan's notification cuts live in Library/Sounds, rendered from the bundled
        // recording (AdhanClipStore). Start that now so the launch's scheduling pass, which runs a few
        // seconds later, finds them; if they land after it, only the notification schedule reruns with
        // the real sound (the prayer times themselves do not depend on which caf a request carries).
        AdhanClipStore.ensureClips(for: Settings.shared.adhanNotificationSound) { rendered in
            if rendered { Settings.shared.scheduleNotifications(deferred: true) }
        }

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
            title: "Yes, on time",
            options: []
        )
        let markPrayedLate = UNNotificationAction(
            identifier: Settings.nagActionMarkPrayedLateIdentifier,
            title: "Yes, but late",
            options: []
        )
        let nagCategory = UNNotificationCategory(
            identifier: Settings.nagCategoryIdentifier,
            actions: [markPrayed, markPrayedLate],
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
        #if DEBUG
        PrayerNotificationPrompt.handleLaunchArguments()
        #endif
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
        // The in-app player is sounding this adhan itself (its timer is armed for this very
        // notification, or has just fired): show the banner, but never a second adhan under the first.
        if ForegroundAdhanPlayer.shared.soundsInApp(notificationID: notification.request.identifier) {
            completionHandler([.banner, .list])
            return
        }
        completionHandler([.banner, .list, .sound])
    }

    // Handles prayer-notification responses. A nag's "Yes" actions mark the tracker and cancel the
    // rest of that cascade straight from the lock screen; a plain tap on ANY prayer notification (the
    // adhan, a pre-notification, a nag) opens the app and raises "Did you pray X?" there
    // (`PrayerNotificationPrompt`, below).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let request = response.notification.request
        let content = request.content
        // A Sunnah reminder: open the Quran where the reminder points (`SunnahReminderStore`). The
        // target is parked on `AppNavigation`; the tab view and the Quran tab take it from there.
        if let encoded = content.userInfo[SunnahReminderStore.targetUserInfoKey] as? String,
           let target = QuranOpenTarget(encoded: encoded) {
            DispatchQueue.main.async { AppNavigation.shared.open(target) }
            completionHandler()
            return
        }
        guard let moment = Settings.tappedPrayerNotification(from: request, deliveredAt: response.notification.date) else {
            completionHandler()
            return
        }

        let actionIdentifier = response.actionIdentifier
        DispatchQueue.main.async {
            let settings = Settings.shared
            // A nag action can COLD-LAUNCH the app in the background (no scene, no .onAppear fetch),
            // leaving `prayers` holding yesterday's snapshot, and silencing the answered cascade walks
            // that snapshot. Refresh first; when it is already today's, this is a no-op. (The question
            // itself resolves against the notification's own day, not this snapshot: un-refreshed, a
            // 5 AM "did you pray Isha?" once marked TODAY instead of yesterday.)
            settings.fetchPrayerTimes()
            switch actionIdentifier {
            case Settings.nagActionMarkPrayedIdentifier, Settings.nagActionMarkPrayedLateIdentifier:
                // Both actions stay on the notification whatever the hour: a category's buttons are
                // fixed when it is registered, so they cannot follow the window closing the way the
                // in-app question does. The answer is recorded as given.
                if let question = settings.prayerQuestion(for: moment) {
                    let late = actionIdentifier == Settings.nagActionMarkPrayedLateIdentifier
                    settings.answer(question, mark: late ? .late : .onTime, from: moment)
                }
            case UNNotificationDefaultActionIdentifier:
                PrayerNotificationPrompt.ask(about: moment)
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
            logger.debug("🔧 Scheduling \(label), earliest begin date: \(date.formatted())")
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

        // BGTaskScheduler invokes this handler on ITS queue (registered with `using: nil`), but
        // everything below touches main-confined state - `Settings.shared.prayers` (read by
        // `nextFajrTime` inside `scheduleBackgroundRefreshes`), the location manager created and
        // delegated on main. Hop once; the expiration handler is installed before the hop.
        DispatchQueue.main.async {
            self.scheduleBackgroundRefreshes()
            // A refresh computed against the stored location faithfully rebuilds widgets for the city you
            // LEFT and feeds the traveling-mode check coordinates from before the trip. Ask for one fresh
            // fix first: its delegate callback commits the move, and that commit re-fetches prayer times,
            // reschedules notifications and reloads widgets on its own. The fetch below still runs
            // immediately with the stored location, so the task succeeds even when no fix arrives.
            let requestedLocationFix = Settings.locationManager.authorizationStatus == .authorizedAlways
            if requestedLocationFix {
                Settings.locationManager.requestLocation()
            }

            Settings.shared.fetchPrayerTimes {
                logger.debug("🎉 BG task completed, prayer times refreshed")
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
}

// MARK: - "Did you pray X?" after a notification tap

/// The question a tapped prayer notification raises once the app is open (Abu, 2026-09-20: "always
/// show the did you pray X confirmation dialog if one clicks on a prayer notification").
///
/// Presented UIKit-side on the topmost view controller, the `RemovalConfirmation` route, instead of
/// a `.confirmationDialog` on the tab view, which is what it used to be. That one could only ask
/// when nothing else was presented: SwiftUI drops a root-level dialog while any sheet is up, so a
/// tap that reopened the app on an open sheet asked nothing. It also came up over the launch
/// screen on a cold start, and on iOS 26 it was anchored to the whole tab view as a popover, which
/// has no Cancel button. It lived in the per-app root as well, which the sibling apps never merge.
@MainActor
enum PrayerNotificationPrompt {
    private static var waiting: Task<Void, Never>?
    private static weak var presented: UIAlertController?

    static func ask(about moment: Settings.PrayerNotificationMoment) {
        waiting?.cancel()
        waiting = Task { @MainActor in
            // A tap that cold-starts the app lands here while the launch screen is still up. The
            // reveal flips at the START of the cover's 0.5 s fade, so a launch waits that out too:
            // the question arrives on the app, never over the launch screen.
            let launching = !AppReveal.revealed
            await AppReveal.waitUntilRevealed()
            if launching { try? await Task.sleep(nanoseconds: 700_000_000) }

            // Then until the screen can take it: the scene is still inactive for a beat after a tap
            // foregrounds the app, and another alert (the traveling-mode dialog at launch) has to be
            // answered first. A minute, then the tap is old news.
            for _ in 0..<200 {
                guard !Task.isCancelled else { return }
                if present(moment) { return }
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
        }
    }

    /// False while the screen cannot take a presentation yet; true once the question is up, or once
    /// it turns out there is nothing to ask.
    private static func present(_ moment: Settings.PrayerNotificationMoment) -> Bool {
        // A second tap while the first question is still up replaces it.
        if let presented, presented.presentingViewController != nil {
            presented.dismiss(animated: false)
            return false
        }
        guard UIApplication.shared.applicationState == .active,
              let top = topmostViewController(),
              !(top is UIAlertController),
              top.transitionCoordinator == nil, !top.isBeingPresented, !top.isBeingDismissed
        else { return false }

        // Resolved now, not at the tap: a launch takes seconds, and whether "late" is an answer
        // depends on the moment the question is actually read.
        let settings = Settings.shared
        guard let question = settings.prayerQuestion(for: moment), settings.isUnanswered(question) else {
            #if DEBUG
            print("PRAYER TAP \(moment.name)-\(moment.minutesBefore): nothing to ask")
            #endif
            return true
        }
        let offersLate = question.allowsLateAnswer()
        #if DEBUG
        print("PRAYER TAP \(moment.name)-\(moment.minutesBefore): asks \(question.prayerName) on \(question.trackerDay.formatted(date: .numeric, time: .omitted)), window ends \(question.windowEnd?.formatted(date: .omitted, time: .shortened) ?? "unknown"), late offered \(offersLate)")
        #endif

        // iPad (and the Mac) get an alert: their action sheets are popovers, which need an anchor
        // this question does not have and which drop the Cancel button - and Dismiss is always
        // there (Abu, 2026-09-20). iPhone keeps the sheet that slides up from the bottom.
        let alert = UIAlertController(
            title: "Did you pray \(question.displayName)\(dayPhrase(for: question))?",
            message: settings.naggingMode
                ? "Answering yes marks it in the prayer tracker and stops the remaining reminders."
                : "Answering yes marks it in the prayer tracker.",
            preferredStyle: UIDevice.current.userInterfaceIdiom == .phone ? .actionSheet : .alert
        )
        func answer(_ mark: PrayerMark) -> (UIAlertAction) -> Void {
            { _ in
                settings.hapticFeedback()
                settings.answer(question, mark: mark, from: moment)
            }
        }
        // "Late" only once the prayer's window has closed. Until then a prayer that was prayed was
        // prayed on time, so there is one yes and it does not need the qualifier.
        alert.addAction(UIAlertAction(title: offersLate ? "Yes, on time" : "Yes, I prayed it", style: .default, handler: answer(.onTime)))
        if offersLate {
            alert.addAction(UIAlertAction(title: "Yes, but late", style: .default, handler: answer(.late)))
        }
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        alert.view.tintColor = UIColor(settings.accentColor.color)

        top.present(alert, animated: true)
        presented = alert
        return true
    }

    /// Nothing for the prayer's most recent instance; " yesterday", " on Thursday" or " on Sep 12" for
    /// a notification tapped after a later one began, so an old notification in Notification Center
    /// asks about (and marks) the day it was for instead of passing as today's.
    private static func dayPhrase(for question: Settings.PrayerQuestion, now: Date = Date()) -> String {
        // The next instance begins a day later, give or take the minutes prayer times drift.
        guard now.timeIntervalSince(question.prayerTime) > 23.5 * 3600 else { return "" }
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day], from: calendar.startOfDay(for: question.trackerDay), to: calendar.startOfDay(for: now)
        ).day ?? 0
        let formatter = DateFormatter()
        switch days {
        case ...1:
            return " yesterday"
        case 2...6:
            formatter.dateFormat = "EEEE"
        default:
            formatter.setLocalizedDateFormatFromTemplate("MMMd")
        }
        return " on \(formatter.string(from: question.trackerDay))"
    }

    #if DEBUG
    /// "-simulatePrayerTap Asr:30": what tapping the "30m until Asr" notification does ("Asr:0" is
    /// the at-time one), with the time read off today's list; a third field offsets the day
    /// ("Asr:30:-1" is yesterday's). Runs from launch, like a tap that cold-starts the app, so the
    /// launch-cover wait is exercised too. The resolved question is printed ("PRAYER TAP ...").
    static func handleLaunchArguments() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-simulatePrayerTap"), arguments.indices.contains(index + 1) else { return }
        let fields = arguments[index + 1].split(separator: ":").map(String.init)
        guard fields.count >= 2, let minutes = Int(fields[1]) else { return }
        let settings = Settings.shared
        guard let day = Calendar.current.date(byAdding: .day, value: fields.count > 2 ? Int(fields[2]) ?? 0 : 0, to: Date()),
              let here = settings.currentLocation else {
            print("PRAYER TAP \(arguments[index + 1]): no location")
            return
        }
        let listed = (settings.getPrayerTimes(for: day) ?? [])
            + settings.optionalPrayers(for: day, at: here, duha: true, islamicMidnight: true, lastThird: true)
        guard let prayer = listed.first(where: { $0.nameTransliteration == fields[0] }) else {
            print("PRAYER TAP \(arguments[index + 1]): no such time in \(listed.map(\.nameTransliteration))")
            return
        }
        // Through the same door as a real tap: a request carrying the identifier and userInfo the
        // scheduler writes, read back by the parser, so a change to either shows up here.
        let fired = prayer.time.addingTimeInterval(-Double(minutes) * 60)
        let stamp = Calendar.current.dateComponents([.year, .month, .day], from: fired)
        let content = UNMutableNotificationContent()
        content.userInfo[Settings.intendedFireDateUserInfoKey] = fired.timeIntervalSince1970
        let request = UNNotificationRequest(
            identifier: "\(fields[0])-\(minutes)-\(stamp.year ?? 0)-\(stamp.month ?? 0)-\(stamp.day ?? 0)"
                + Settings.notificationContentSignature(settings),
            content: content,
            trigger: nil
        )
        guard let moment = Settings.tappedPrayerNotification(from: request, deliveredAt: fired) else {
            print("PRAYER TAP \(request.identifier): not read as a prayer notification")
            return
        }
        ask(about: moment)
    }
    #endif
}
#endif
