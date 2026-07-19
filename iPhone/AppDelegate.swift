#if os(iOS)
import AVFoundation
import BackgroundTasks
import Combine
import UIKit
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    private let taskID = AppIdentifiers.backgroundFetchPrayerTimesTaskIdentifier
    private let reciterDownloadsSessionID = AppIdentifiers.reciterDownloadsBackgroundSessionIdentifier

    // Performs startup setup: registers background refresh, schedules first refresh, and notification delegate.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        registerBackgroundRefreshTask()
        scheduleAppRefresh()
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Re-schedules the background refresh whenever the app moves to background.
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
    }

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

    // Shows in-app notifications as banner + sound when a notification arrives in foreground, and keeps
    // them in Notification Center (.list) so a missed banner isn't lost.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    // Registers the BGTask handler that refreshes prayer times in the background.
    private func registerBackgroundRefreshTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskID, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleAppRefresh(task: refreshTask)
        }
    }

    // Submits the next background refresh request using the computed target run date.
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskID)
        request.earliestBeginDate = nextRunDate()

        if let date = request.earliestBeginDate {
            logger.debug("🔧 Scheduling BGAppRefresh – earliestBeginDate: \(date.formatted())")
        }

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.debug("✅ BGAppRefresh submitted")
        } catch {
            logger.error("❌ BG submit failed: \(error.localizedDescription)")
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

    // Executes when BG refresh fires: re-schedules, handles expiration, and refreshes prayer times.
    private func handleAppRefresh(task: BGAppRefreshTask) {
        logger.debug("🚀 BGAppRefresh fired")
        scheduleAppRefresh()

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

        Settings.shared.fetchPrayerTimes {
            logger.debug("🎉 BG task completed – prayer times refreshed")
            complete(true)
        }
    }
}

/// Plays the adhan in-app, on time, while the app is active.
///
/// The scheduled notification is the source of truth when the app is closed/backgrounded, but the system
/// can deliver scheduled local notifications late while the app is open (notably on Mac/Catalyst). To make
/// the adhan reliable in that case, this arms a precise timer for the next at-time adhan and, when it fires
/// with the app active, plays the selected adhan sound directly and removes the now-redundant scheduled
/// notification so it can't sound again late. When the app isn't active this does nothing - the system
/// notification handles it exactly as before.
@MainActor
final class ForegroundAdhanPlayer: NSObject, ObservableObject {
    static let shared = ForegroundAdhanPlayer()

    /// The prayer whose adhan is playing right now, or `nil` when silent. Drives the on-screen stop control - 
    /// the full recording runs for minutes, so there has to be a way to cut it short.
    @Published private(set) var playingPrayerName: String?

    var isPlaying: Bool { playingPrayerName != nil }

    private var timer: DispatchSourceTimer?
    private var player: AVAudioPlayer?
    private var pausedQuranForAdhan = false
    private var lastPlayedID: String?
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        // Re-arm whenever prayer times or relevant settings change (debounced to batch rapid edits and the
        // burst of changes during a prayer-time refresh).
        Settings.shared.objectWillChange
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.reschedule() }
            .store(in: &cancellables)
    }

    /// Recomputes the next eligible adhan and arms a one-shot timer for it. Safe to call repeatedly
    /// (on app-active and whenever prayer times / settings change); it just re-arms.
    func reschedule() {
        cancelTimer()

        guard let next = Settings.shared.nextForegroundAdhan() else { return }
        let interval = next.date.timeIntervalSinceNow
        guard interval > 0 else { return }

        let t = DispatchSource.makeTimerSource(queue: .main)
        // WALL deadline, not monotonic: `deadline:` stops counting while the device sleeps, so on a Mac
        // (or an iPhone that napped) the timer fired LATE - a full adhan at some random later moment,
        // labeled with whatever "prayer" happened to be current then (the "Last Third adhan" report).
        t.schedule(wallDeadline: .now() + interval, leeway: .milliseconds(200))
        t.setEventHandler { [weak self] in
            self?.fire(target: next)
        }
        t.resume()
        timer = t
    }

    /// Stops the pending timer (e.g. when the app backgrounds). A currently-playing adhan is left to finish.
    func stop() {
        cancelTimer()
    }

    private func cancelTimer() {
        timer?.cancel()
        timer = nil
    }

    private func fire(target: (date: Date, name: String, notificationID: String)) {
        timer = nil

        // The adhan belongs to a MOMENT, not to whenever the timer managed to fire. If we're more than a
        // couple of minutes past the prayer's time (a sleep/wake drift, a suspended runloop), playing the
        // full recording now would be the "random adhan" - skip it and arm the next one instead.
        guard abs(target.date.timeIntervalSinceNow) < 150 else {
            reschedule()
            return
        }

        // Only the actual adhan sound files play in-app; if "Default" is selected there's no adhan audio to
        // play, so leave the system notification to handle the sound and just arm the next one. In-app
        // playback isn't bound by the notification sound's 30-second limit, so it uses the full recording.
        let settings = Settings.shared
        guard let resource = settings.adhanFullSoundResource(for: settings.adhanNotificationSound),
              let path = Bundle.main.path(forResource: resource, ofType: "caf") else {
            reschedule()
            return
        }

        guard target.notificationID != lastPlayedID else {
            reschedule()
            return
        }
        lastPlayedID = target.notificationID

        // Drop the redundant scheduled notification so it can't double-sound late.
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [target.notificationID])

        // Named for the prayer the adhan was ARMED for - never `currentPrayer`, which can be a
        // non-obligatory time (Last Third, Duhaa) by the moment the timer runs.
        playAdhan(path: path, prayerName: target.name)
        reschedule()
    }

    /// Fades out a playing adhan and restores whatever it interrupted. Safe to call when nothing is playing.
    func stopAdhan() {
        guard let player else { return }
        player.setVolume(0, fadeDuration: 0.4)
        // Hold the reference so `audioPlayerDidFinishPlaying` (which never fires for a manual stop) can't
        // race this cleanup against a fresh adhan armed in the meantime.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self, self.player === player else { return }
            player.stop()
            self.player = nil
            self.finishPlayback()
        }
    }

    private func playAdhan(path: String, prayerName: String?) {
        // Pause in-app audio (Quran) so the adhan isn't talked over; resume it when the adhan finishes.
        if QuranPlayer.shared.isPlaying {
            QuranPlayer.shared.pause(saveInfo: false)
            pausedQuranForAdhan = true
        }

        do {
            let session = AVAudioSession.sharedInstance()
            // .playback ignores the ringer switch; .ambient respects it. The override is an explicit
            // opt-in ("play the adhan in the app even in Silent Mode"), off by default.
            try session.setCategory(Settings.shared.adhanOverridesSilentMode ? .playback : .ambient, mode: .default)
            try session.setActive(true)

            let p = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            p.delegate = self
            p.prepareToPlay()
            p.play()
            player = p
            playingPrayerName = prayerName ?? "Adhan"
        } catch {
            logger.error("Foreground adhan playback failed: \(error.localizedDescription)")
            player = nil
            finishPlayback()
        }
    }

    private func finishPlayback() {
        playingPrayerName = nil
        if pausedQuranForAdhan {
            pausedQuranForAdhan = false
            QuranPlayer.shared.resume()
        } else {
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }
}

extension ForegroundAdhanPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            guard self.player === player else { return }
            self.player = nil
            self.finishPlayback()
        }
    }
}
#endif
