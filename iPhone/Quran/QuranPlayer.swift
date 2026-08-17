import SwiftUI
import AVFoundation
import MediaPlayer
import Foundation
import CryptoKit
import Network

struct SurahQueueItem: Identifiable, Equatable {
    let id = UUID()
    let surahNumber: Int
    let surahName: String
}

// `PlaybackVisibility` (the bar-visibility slice every list observes) lives in Helpers/ViewExtensions -
// NOT here - so shared chrome compiles in sibling apps without the Quran module. This player feeds it
// from the `isPlaying`/`isPaused` didSets and installs its bar content + the speech session hook in
// `init` below; that self-registration is the Quran module's entire wiring into shared code.
final class QuranPlayer: ObservableObject {
    static let shared = QuranPlayer()
    private static let listeningHistoryKey = "quranListeningHistoryData"
    private static let readingHistoryKey = "quranReadingHistoryData"
    private static let ayahListeningHistoryKey = "quranAyahListeningHistoryData"
    
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    
    @Published var isLoading = false
    @Published private(set) var isReadyForUI = false
    @Published private(set) var isPlaying = false {
        didSet { PlaybackVisibility.shared.update(showsBar: isPlaying || isPaused) }
    }
    @Published private(set) var isPaused = false {
        didSet { PlaybackVisibility.shared.update(showsBar: isPlaying || isPaused) }
    }
    
    @Published var currentSurahNumber: Int?
    @Published var currentAyahNumber: Int?
    @Published var isPlayingSurah = false
    @Published var isPlayingCustomRange = false
    @Published var showInternetAlert = false
    @Published var playbackAlertTitle = "Playback Error"
    @Published var playbackAlertMessage = "Unable to load this recitation right now. Please try again."

    /// Offered alongside the playback alert when streaming is impossible but other reciters have this
    /// surah on disk: the dialog gains a "switch and play" button for `suggested`.
    struct OfflineReciterSwitch: Equatable {
        let surahNumber: Int
        let surahName: String
        let downloadedReciters: [Reciter]
        let suggested: Reciter
    }
    @Published var offlineReciterSwitch: OfflineReciterSwitch?

    /// Reciter ids whose Minshawi ayah substitution the user has already been told about. Joined with a
    /// unit separator because `Reciter.id` itself contains "|". Remembered across launches.
    @AppStorage("confirmedMinshawiAyahFallbackReciterIDs") private var confirmedMinshawiAyahFallbackReciterIDsRaw = ""
    private static let minshawiConfirmationSeparator = "\u{1F}"

    @Published private(set) var surahQueue: [SurahQueueItem] = []

    @Published private(set) var customRangeStartAyah: Int?
    @Published private(set) var customRangeEndAyah: Int?
    @Published private(set) var customRangeRepeatPerAyah: Int = 1
    @Published private(set) var customRangeRepeatSection: Int = 1
    @Published private(set) var customRangeCurrentIndex: Int?
    @Published private(set) var customRangeTotalItems: Int?
    @Published private(set) var customRangeCurrentRepeatWithinAyah: Int?
    @Published private(set) var customRangeRepeatSectionIndex: Int?

    @Published var listeningHistory: [ListeningHistoryItem] = [] {
        didSet { persistListeningHistory() }
    }
    @Published var readingHistory: [ReadingHistoryItem] = [] {
        didSet { persistReadingHistory() }
    }
    @Published var ayahListeningHistory: [AyahListeningHistoryItem] = [] {
        didSet { persistAyahListeningHistory() }
    }

    private var lastSavedListeningSurahNumber: Int?
    private var lastSavedReadingPosition: (surahNumber: Int, ayahNumber: Int)?

    private var backButtonClickCount = 0
    private var backButtonClickTimestamp: Date?
    /// Ayah skip-back: delay-based so one tap = restart, two taps = previous. Avoids double-tap from one press.
    private var ayahBackPendingRestart: DispatchWorkItem?
    private var ayahBackPendingRestartScheduledAt: Date?
    private let ayahBackDoubleTapMinInterval: TimeInterval = 0.25
    private let ayahBackRestartDelay: TimeInterval = 0.4
    private var continueRecitationFromAyah = false
    private var didHandleSingleAyahEnd = false
    
    var player: AVPlayer?
    private var queuePlayer: AVQueuePlayer?
    
    private var statusObserver: NSKeyValueObservation?
    private var queuePlayerItemObserver: NSKeyValueObservation?
    private var notificationObservers = [NSObjectProtocol]()

    /// Periodic observer on the surah player used to prewarm the next surah near the end of the current one.
    private var surahTimeObserver: Any?

    /// The next surah, already created and buffering in a paused player, ready to be promoted for a gapless
    /// hand-off (mirrors the AVQueuePlayer next-ayah prefetch). Built ~`surahPrewarmLeadTime` before the end.
    private struct PrewarmedSurah {
        let surahNumber: Int
        let surahName: String
        let reciterSurahLink: String
        let url: URL
        let player: AVPlayer
        let item: AVPlayerItem
    }
    private var prewarmedSurah: PrewarmedSurah?
    private let surahPrewarmLeadTime: TimeInterval = 10
    
    var nowPlayingTitle: String?
    var nowPlayingReciter: String?

    private let reciterDownloadManager = ReciterDownloadManager.shared
    private let localSurahStartupBuffer: TimeInterval = 0.03
    private let remoteSurahStartupBuffer: TimeInterval = 0.75
    private let ayahStartupBuffer: TimeInterval = 0.6

    /// Tracks reachability so an offline tap on a non-downloaded reciter can offer the downloaded ones
    /// immediately, instead of spinning until the AVPlayerItem times out into a generic failure.
    private static let networkMonitor = NWPathMonitor()
    private static let networkMonitorQueue = DispatchQueue(label: "\(AppIdentifiers.appName).QuranPlayerNetworkMonitor")
    private static var isNetworkReachable = true

    private init() {
        // Self-registration into shared chrome (see the note above the class): the bar the now-playing
        // inset renders, and the speech engine's "does recitation still own the audio session?" probe.
        // Both closures resolve `.shared` lazily at CALL time - never during this init - and both stay
        // nil in sibling apps that don't compile this module.
        PlaybackVisibility.shared.barContent = { AnyView(NowPlayingView()) }
        ArabicSpeech.recitationOwnsSession = { QuranPlayer.shared.isPlaying || QuranPlayer.shared.isPaused }
        #if os(iOS)
        // The foreground adhan pauses recitation while it plays; installed here (same seam) so its file in
        // the Adhan module names no Quran type. iOS only - the watch has no foreground adhan player.
        ForegroundAdhanPlayer.pauseRecitationIfPlaying = {
            guard QuranPlayer.shared.isPlaying else { return false }
            QuranPlayer.shared.pause(saveInfo: false)
            return true
        }
        ForegroundAdhanPlayer.resumeRecitation = { QuranPlayer.shared.resume() }
        #endif

        Self.networkMonitor.pathUpdateHandler = { path in
            let reachable = (path.status == .satisfied)
            DispatchQueue.main.async { Self.isNetworkReachable = reachable }
        }
        Self.networkMonitor.start(queue: Self.networkMonitorQueue)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        // Unplugging headphones (or a Bluetooth device dropping) must PAUSE, not continue out of the
        // speaker - with a `.playback` session iOS does not do this for us, and recitation suddenly
        // blasting from the phone in public is exactly what the standard media-app convention prevents.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
        // If the media server itself restarts, every AVPlayer and the session are dead objects; playing
        // into them produces silent, stuck UI. Reset to a clean stopped state instead.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServicesReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance()
        )
        loadHistoryFromDefaults()
        setupRemoteTransportControls()
        isReadyForUI = true
    }

    func waitUntilReady() async {
        while true {
            let isReady = await MainActor.run { self.isReadyForUI }
            if isReady { return }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        deactivateAudioSession()
    }
    
    #if os(watchOS)
    /// watchOS audio routing. There are two genuinely different paths and picking the wrong one is what
    /// used to strand people on the "Connect to a device" sheet:
    ///
    /// - **Something wireless is already connected** → `.longFormAudio` plus the ASYNC
    ///   `activate(options:completionHandler:)`. That combination is the only one that keeps a multi-minute
    ///   surah playing with the wrist down (it rides the `audio` background mode declared in Info-Main.plist).
    ///   The iOS-style synchronous `setActive(true)` never routes long-form audio on the watch, which is why
    ///   full-surah playback silently produced nothing while short per-ayah clips scraped by.
    ///
    /// - **Nothing connected** → the DEFAULT route-sharing policy, which plays out of the watch's own
    ///   speaker. `.longFormAudio` can NOT use the speaker: activating it with no active route makes the
    ///   system present its route picker, so anyone who just wanted to listen on the watch got nagged to
    ///   pair headphones (and got it again even with Bluetooth off, because the sheet is the system asking
    ///   for a route, not the app asking for Bluetooth). Apple's guidance is explicit - to play through the
    ///   speaker, don't set the long-form policy.
    ///
    /// The route is re-evaluated on every fresh activation, so connecting AirPods and playing again picks
    /// the long-form path back up on its own.
    private var audioSessionActivated = false
    private var audioSessionActivating = false
    private var pendingSessionStarts: [() -> Void] = []

    /// True when there is already an output we can hand long-form audio to. When this is false, asking for
    /// `.longFormAudio` is what summons the route sheet.
    private var hasWirelessAudioRoute: Bool {
        AVAudioSession.sharedInstance().currentRoute.outputs.contains { output in
            switch output.portType {
            case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE, .airPlay: return true
            default:                                                    return false
            }
        }
    }
    #endif

    private func setupAudioSession() {
        let s = AVAudioSession.sharedInstance()
        #if os(watchOS)
        guard !audioSessionActivated, !audioSessionActivating else { return }

        // Nothing to send long-form audio to: go straight out of the watch speaker rather than making the
        // system ask for a device the listener never wanted.
        guard hasWirelessAudioRoute else {
            activateWatchSpeakerSession()
            return
        }

        do {
            try s.setCategory(.playback, mode: .default, policy: .longFormAudio)
        } catch {
            logger.debug("Audio session category failed: \(error)")
        }
        audioSessionActivating = true
        s.activate(options: []) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.audioSessionActivating = false
                if let error { logger.debug("Audio session activation failed: \(error)") }

                if success {
                    self.audioSessionActivated = true
                    let starts = self.pendingSessionStarts
                    self.pendingSessionStarts = []
                    starts.forEach { $0() }
                } else {
                    // The headphones went away between the route check and the activation, or the listener
                    // dismissed the sheet. Dismissing it means "not on headphones" - so play on the speaker
                    // instead of scolding them into pairing something.
                    self.activateWatchSpeakerSession()
                }
            }
        }
        #else
        do {
            try s.setCategory(.playback)
            try s.setActive(true, options: .notifyOthersOnDeactivation)
        } catch { logger.debug("Audio session setup failed: \(error)") }
        #endif
    }

    #if os(watchOS)
    /// The watch-speaker path: the DEFAULT route-sharing policy (no `.longFormAudio`), activated
    /// synchronously. This is what makes the recitation come out of the watch itself, and it is also the
    /// fallback when a long-form activation doesn't land - either way the listener gets audio instead of
    /// a route sheet. Trade-off worth knowing: without the long-form policy the system may stop playback
    /// when the app leaves the foreground, so headphones remain the better experience for a whole surah.
    private func activateWatchSpeakerSession() {
        let s = AVAudioSession.sharedInstance()
        do {
            try s.setCategory(.playback, mode: .default)
            try s.setActive(true, options: .notifyOthersOnDeactivation)
            audioSessionActivated = true
        } catch {
            logger.debug("Watch speaker session failed: \(error)")
            audioSessionActivated = false
        }

        let starts = pendingSessionStarts
        pendingSessionStarts = []

        guard audioSessionActivated else {
            // Genuinely no way to play. The call sites flipped isPlaying on when the item became ready -
            // audio never started, so roll the play state back rather than showing a "playing" UI over
            // silence.
            player?.pause()
            queuePlayer?.pause()
            isLoading = false
            isPlaying = false
            isPaused = false
            presentPlaybackFailure(
                "The watch couldn't start audio. Try again, or connect Bluetooth headphones like AirPods.",
                title: "Playback Error"
            )
            return
        }
        starts.forEach { $0() }
    }
    #endif

    /// Runs a play-start now - or, on watchOS, once the async long-form activation has an output route.
    /// Starting the player before that completes is silently dropped by the system, which looked like
    /// "loading forever". On iOS the session is already active synchronously, so this is a plain call.
    private func whenAudioSessionReady(_ start: @escaping () -> Void) {
        #if os(watchOS)
        if audioSessionActivated {
            start()
        } else {
            pendingSessionStarts.append(start)
            setupAudioSession()
        }
        #else
        start()
        #endif
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false,
                                                          options: .notifyOthersOnDeactivation)
        } catch { logger.debug("Audio session deactivate failed: \(error)") }
        #if os(watchOS)
        audioSessionActivated = false
        pendingSessionStarts = []
        #endif
    }

    private func makeFastStartItem(url: URL, bufferDuration: TimeInterval = 2) -> AVPlayerItem {
        // islamweb-hosted riwayah feeds refuse requests without their Referer header;
        // `assetOptions` is empty for every other host, so this is a no-op for mp3quran & co.
        var options: [String: Any] = [AVURLAssetPreferPreciseDurationAndTimingKey: false]
        ReciterAudioHosting.assetOptions(for: url).forEach { options[$0.key] = $0.value }
        let asset = AVURLAsset(url: url, options: options)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = bufferDuration
        return item
    }

    private func configureFastStartPlayer(_ player: AVPlayer, bufferDuration: TimeInterval = 2) {
        player.automaticallyWaitsToMinimizeStalling = false
        player.currentItem?.preferredForwardBufferDuration = bufferDuration
    }

    private func presentPlaybackFailure(_ message: String, title: String = "Playback Error", offlineSwitch: OfflineReciterSwitch? = nil) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.isPlaying = false
            self.isPaused = false
            self.playbackAlertTitle = title
            self.playbackAlertMessage = message
            self.offlineReciterSwitch = offlineSwitch
            self.showInternetAlert = true
            self.idleTimerSet(false)
        }
    }

    /// What actually went wrong with a failed item, bucketed for the user. Every `.failed` observer used
    /// to collapse into one "check your internet connection" line, so a server missing the file (a 404 -
    /// the Hazza Al-Balushi report) read as an offline problem on a perfectly connected phone.
    enum PlaybackFailureKind {
        case offline, timeout, notFound, server, unknown
    }

    static func classifyPlaybackError(_ error: Error?) -> PlaybackFailureKind {
        guard let nsError = error as NSError? else { return .unknown }
        // AVFoundation wraps the transport failure; the underlying error carries the real cause.
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            let kind = classifyPlaybackError(underlying)
            if kind != .unknown { return kind }
        }
        switch (nsError.domain, nsError.code) {
        case (NSURLErrorDomain, NSURLErrorNotConnectedToInternet),
             (NSURLErrorDomain, NSURLErrorNetworkConnectionLost),
             (NSURLErrorDomain, NSURLErrorInternationalRoamingOff),
             (NSURLErrorDomain, NSURLErrorDataNotAllowed),
             // DNS failures are connectivity-shaped in practice (captive portals, dead Wi-Fi).
             (NSURLErrorDomain, NSURLErrorCannotFindHost),
             (NSURLErrorDomain, NSURLErrorDNSLookupFailed):
            return .offline
        case (NSURLErrorDomain, NSURLErrorTimedOut):
            return .timeout
        case (NSURLErrorDomain, NSURLErrorFileDoesNotExist),
             (NSURLErrorDomain, NSURLErrorZeroByteResource),
             (NSURLErrorDomain, NSURLErrorResourceUnavailable),
             // The CoreMedia HTTP loader's "server sent 404" / "403" codes.
             ("CoreMediaErrorDomain", -12938),
             ("CoreMediaErrorDomain", -12660):
            return .notFound
        case (NSURLErrorDomain, NSURLErrorBadServerResponse),
             (NSURLErrorDomain, NSURLErrorCannotConnectToHost):
            return .server
        default:
            return .unknown
        }
    }

    /// The specific, honest alert for a failed load: names the real problem (missing file, timeout,
    /// server trouble, offline) instead of blaming the connection for everything. `what` reads like
    /// "surah" / "ayah" / "custom range"; `wasLocal` marks a corrupt DOWNLOADED file, which is a
    /// re-download problem, not a network one.
    func playbackFailureDetails(for error: Error?, reciter: Reciter?, what: String,
                                wasLocal: Bool = false) -> (title: String, message: String) {
        if wasLocal {
            return ("Downloaded File Problem",
                    "The downloaded audio for this \(what) could not be played - the file may be damaged. Re-download this reciter in Settings → Manage Audio.")
        }
        switch Self.classifyPlaybackError(error) {
        case .offline:
            return ("No Internet Connection",
                    "You appear to be offline. Connect to the internet and try again.")
        case .timeout:
            return ("Server Not Responding",
                    "The audio server is taking too long to respond. Try again in a moment.")
        case .notFound:
            let name = reciter?.name ?? "this reciter"
            return ("Recitation Not Available",
                    "The audio for this \(what) could not be found on the server - \(name) may not have recorded it. Try another reciter.")
        case .server:
            return ("Server Problem",
                    "The audio server could not serve this \(what) right now. Please try again later or pick another reciter.")
        case .unknown:
            var message = "Unable to load this \(what). Check your internet connection and try again."
            if let description = (error as NSError?)?.localizedDescription, !description.isEmpty {
                message += "\n(\(description))"
            }
            return ("Playback Error", message)
        }
    }

    /// Downloaded reciters that carry `surahNumber`, favorites first, alphabetical within each tier
    /// (the global `reciters` list is already name-sorted, so filtering preserves that order).
    private func downloadedRecitersForSurah(_ surahNumber: Int, excluding excluded: Reciter) -> [Reciter] {
        let downloaded = reciters.filter {
            $0.id != excluded.id &&
            reciterDownloadManager.localSurahURL(reciter: $0, surahNumber: surahNumber) != nil
        }
        let favorites = downloaded.filter { settings.isReciterFavorite(reciterID: $0.id) }
        let rest = downloaded.filter { !settings.isReciterFavorite(reciterID: $0.id) }
        return favorites + rest
    }

    /// When a surah can't be streamed, offer the reciters that DO have it on disk. Returns false when
    /// there's nothing to offer (caller falls back to the generic failure alert).
    private func presentOfflineReciterOptions(surahNumber: Int, surahName: String, failedReciter: Reciter) -> Bool {
        let downloaded = downloadedRecitersForSurah(surahNumber, excluding: failedReciter)
        guard let suggested = downloaded.first else { return false }

        let names = downloaded.map { $0.name }.joined(separator: ", ")
        let countText = downloaded.count == 1
            ? "1 reciter downloaded"
            : "\(downloaded.count) reciters downloaded"
        presentPlaybackFailure(
            "\(failedReciter.name) isn't downloaded and can't be streamed without internet. You have \(countText): \(names).",
            title: "Reciter Not Downloaded",
            offlineSwitch: OfflineReciterSwitch(
                surahNumber: surahNumber,
                surahName: surahName,
                downloadedReciters: downloaded,
                suggested: suggested
            )
        )
        return true
    }

    /// Accepts the offer above: switches the selected reciter and replays the surah from it.
    func acceptOfflineReciterSwitch() {
        guard let offer = offlineReciterSwitch else { return }
        offlineReciterSwitch = nil
        showInternetAlert = false
        settings.setSelectedReciter(offer.suggested)
        playSurah(surahNumber: offer.surahNumber, surahName: offer.surahName)
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard
            let user = notification.userInfo,
            let tVal = user[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: tVal)
        else { return }

        // Interruption notifications arrive on the session's own queue, not main. Everything below mutates
        // @Published state - the same discipline the KVO observers in this file already follow.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch type {
            case .began:
                self.pause()
                self.idleTimerSet(false)
                #if os(watchOS)
                // The system deactivated our session for the interrupting audio. The flag must reflect that,
                // or the resume below would "play" into a dead session and produce silence.
                self.audioSessionActivated = false
                #endif

            case .ended:
                if let opts = user[AVAudioSessionInterruptionOptionKey] as? UInt,
                   AVAudioSession.InterruptionOptions(rawValue: opts).contains(.shouldResume) {
                    self.whenAudioSessionReady { [weak self] in
                        self?.player?.play()
                    }
                    self.isPlaying = true
                    self.isPaused = false
                    self.idleTimerSet(true)
                }

            @unknown default:
                break
            }
            self.updateNowPlayingInfo()
        }
    }
    
    /// Pauses when the current output route disappears (wired headphones unplugged, Bluetooth device
    /// off). Other route changes - a new device connecting, category renegotiation - are left alone.
    @objc private func handleRouteChange(notification: Notification) {
        guard
            let info = notification.userInfo,
            let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
            reason == .oldDeviceUnavailable
        else { return }

        // Route notifications arrive on the session's queue; @Published mutations hop to main, same as
        // the interruption handler above.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isPlaying else { return }
            self.pause()
            self.updateNowPlayingInfo()
        }
    }

    /// The audio server restarted (rare, but real): the session and every player object are invalid.
    /// Tear down to a clean stopped state so the next tap starts fresh instead of playing into a corpse.
    @objc private func handleMediaServicesReset(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            #if os(watchOS)
            self.audioSessionActivated = false
            #endif
            if self.isPlaying || self.isPaused || self.isLoading {
                self.stop()
            }
        }
    }

    private func setupRemoteTransportControls() {
        let cmd = MPRemoteCommandCenter.shared()
        
        // MPRemoteCommand handlers are invoked on a MediaPlayer queue, not main. The guards read state to
        // decide the returned status (a benign racy read); every MUTATION of @Published state and every
        // player call hops to main, matching the discipline the KVO observers in this file follow.
        cmd.playCommand.addTarget { [unowned self] _ in
            guard !isPlaying else { return .commandFailed }
            DispatchQueue.main.async {
                self.whenAudioSessionReady { [weak self] in
                    self?.player?.play()
                }
                self.isPlaying = true
                self.isPaused = false
                self.idleTimerSet(true)
                self.updateNowPlayingInfo()
            }
            return .success
        }

        cmd.pauseCommand.addTarget { [unowned self] _ in
            guard isPlaying else { return .commandFailed }
            DispatchQueue.main.async { self.pause() }
            return .success
        }

        cmd.stopCommand.addTarget { [unowned self] _ in
            guard isPlaying else { return .commandFailed }
            DispatchQueue.main.async {
                self.pause()
                self.isPlaying = false
                self.isPaused = false
            }
            return .success
        }

        cmd.previousTrackCommand.addTarget { [unowned self] _ in
            DispatchQueue.main.async { self.skipBackwardFromRemote() }
            return .success
        }
        cmd.nextTrackCommand.addTarget { [unowned self] _ in
            DispatchQueue.main.async { self.skipForwardFromRemote() }
            return .success
        }

        cmd.skipBackwardCommand.addTarget { [unowned self] _ in
            guard player != nil else { return .commandFailed }
            DispatchQueue.main.async { self.skipBackwardFromRemote() }
            return .success
        }
        cmd.skipForwardCommand.addTarget { [unowned self] _ in
            guard player != nil else { return .commandFailed }
            DispatchQueue.main.async { self.skipForwardFromRemote() }
            return .success
        }
        cmd.skipBackwardCommand.isEnabled = false
        cmd.skipForwardCommand.isEnabled = false
        cmd.skipBackwardCommand.preferredIntervals = []
        cmd.skipForwardCommand.preferredIntervals = []

        cmd.changePlaybackPositionCommand.addTarget { [unowned self] evt in
            guard
                let e = evt as? MPChangePlaybackPositionCommandEvent,
                let p = player
            else { return .commandFailed }
            // Timescale 600, not 1: a timescale of 1 rounds the target to whole seconds, which made
            // lock-screen scrubbing land up to half a second off where the user let go.
            let target = CMTime(seconds: e.positionTime, preferredTimescale: 600)
            DispatchQueue.main.async {
                p.seek(to: target) { _ in
                    DispatchQueue.main.async {
                        self.updateNowPlayingInfo()
                        self.saveLastListenedSurah()
                    }
                }
            }
            return .success
        }
    }
    
    /// In-app: double-tap = previous, single-tap = restart current.
    func skipBackward()  {
        if isPlayingCustomRange { customRangeSkipAyah(by: -1); return }
        player == nil ? () : isPlayingSurah ? surahSkipBackward() : ayahSkipBackward()
    }
    func skipForward()   {
        if isPlayingCustomRange { customRangeSkipAyah(by: 1); return }
        player == nil ? () : isPlayingSurah ? surahSkipForward() : ayahSkipForward(continueRecitation: continueRecitationFromAyah)
    }

    /// Control Center / Lock Screen: one tap = previous/next and play (no double-tap).
    private func skipBackwardFromRemote() {
        if isPlayingCustomRange { customRangeSkipAyah(by: -1); return }
        guard player != nil else { return }
        if isPlayingSurah {
            surahSkipBackward()
            return
        }
        ayahGoToPreviousAndPlay()
    }
    private func skipForwardFromRemote() {
        if isPlayingCustomRange { customRangeSkipAyah(by: 1); return }
        guard player != nil else { return }
        if isPlayingSurah {
            surahSkipForward()
            return
        }
        ayahSkipForward(continueRecitation: continueRecitationFromAyah)
    }

    /// Previous ayah and start playing (used from Control Center where double-tap isn’t possible).
    private func ayahGoToPreviousAndPlay() {
        guard let s = currentSurahNumber, let a = currentAyahNumber else { return }
        let repeatCountToKeep = ayahRepeatCount
        if a > 1 {
            playAyah(
                surahNumber: s,
                ayahNumber: a - 1,
                continueRecitation: continueRecitationFromAyah,
                repeatCount: repeatCountToKeep
            )
        }
    }
    
    func pause(saveInfo: Bool = true) {
        if saveInfo { saveLastListenedSurah(); saveLastListenedAyah() }
        player?.pause()
        // No withAnimation: the now-playing inset animates its own appearance via `.animation(value:)`, and
        // isPlaying||isPaused stays true across pause/resume so nothing should move. A global withAnimation
        // here also sweeps the player's follow-up KVO/time updates into the same transaction (the weird
        // resume glitch) and animates the whole List that observes play state.
        isPlaying = false; isPaused = true
        updateNowPlayingInfo()
        idleTimerSet(false)
    }
    func resume() {
        whenAudioSessionReady { [weak self] in
            self?.player?.play()
        }
        isPlaying = true; isPaused = false
        updateNowPlayingInfo()
        idleTimerSet(true)
    }
    
    func seek(by seconds: Double) {
        guard let p = player else { return }
        let current = CMTimeGetSeconds(p.currentTime())
        guard current.isFinite else { return }
        var target = current + seconds
        // Clamp to [0, duration] so a skip near the ends can't seek negative or past the item.
        if let item = p.currentItem {
            let dur = CMTimeGetSeconds(item.duration)
            if dur.isFinite, dur > 0 { target = min(target, dur) }
        }
        target = max(0, target)
        guard target.isFinite else { return }
        // Timescale 600, not 1: a timescale of 1 quantizes the seek to whole seconds.
        p.seek(to: CMTime(seconds: target, preferredTimescale: 600)) { _ in
            self.updateNowPlayingInfo(); self.saveLastListenedSurah(); self.saveLastListenedAyah()
        }
    }
    
    func stop() {
        ayahBackPendingRestart?.cancel()
        ayahBackPendingRestart = nil
        ayahBackPendingRestartScheduledAt = nil
        didHandleSingleAyahEnd = false
        repeatCount = 1
        repeatRemaining = 1
        ayahRepeatCount = 1
        ayahRepeatRemaining = 1

        // Persist position OUTSIDE withAnimation: these write @AppStorage-backed settings, which republish
        // observing screens (e.g. SurahView). Animating that republish mid-scroll makes the reading view
        // visibly "jump"/scroll a little when playback ends, so keep the save un-animated.
        saveLastListenedSurah()
        saveLastListenedAyah()

        // No withAnimation here (or anywhere in the player). All animation is view-driven: the now-playing
        // views carry their own `.animation(value:)` so transitions are scoped and never animate the List.
        isLoading = false

        player?.currentItem?.cancelPendingSeeks()
        player?.currentItem?.asset.cancelLoading()

        player?.pause()
        removeAllObservers()
        discardPrewarm()

        player = nil
        queuePlayer = nil
        currentSurahNumber = nil
        currentAyahNumber = nil
        isPlayingSurah = false
        isPlayingCustomRange = false
        isPlaying = false
        isPaused = false
        customRangeSequence = []
        customRangeSurahNumber = 0
        customRangeSurahName = ""
        customRangeStartAyah = nil
        customRangeEndAyah = nil
        customRangeRepeatPerAyah = 1
        customRangeRepeatSection = 1
        customRangeCurrentIndex = nil
        customRangeTotalItems = nil
        customRangeCurrentRepeatWithinAyah = nil
        customRangeRepeatSectionIndex = nil

        updateNowPlayingInfo(clear: true)

        DispatchQueue.global(qos: .userInitiated).async {
            self.deactivateAudioSession()
        }

        self.idleTimerSet(false)
    }
    
    private func removeAllObservers() {
        notificationObservers.forEach(NotificationCenter.default.removeObserver)
        notificationObservers.removeAll()
        queuePlayerItemObserver = nil
        statusObserver = nil
        // The time observer was added to the current `player`; always removed here before `player` is
        // reassigned/nilled, so it's removed from the same instance it was added to (never crashes).
        if let obs = surahTimeObserver {
            player?.removeTimeObserver(obs)
            surahTimeObserver = nil
        }
    }
    
    private var repeatCount: Int = 1
    private var repeatRemaining: Int = 1
    private var playbackReciter: Reciter?

    private func repeatSuffix(total: Int, remaining: Int) -> String {
        guard total > 1 else { return "" }
        let index = max(1, total - remaining + 1)
        return " (x\(index)/\(total))"
    }

    private func ayahNowPlayingReciterName(for reciter: Reciter) -> String {
        if reciter.defaultToMinshawi {
            return Reciter.minshawiAyahFallbackName
        }
        // Mujawwad/Muallim variants with no per-ayah recording in that style play the reciter's Murattal - 
        // show that during ayah/range playback so the label matches what's actually heard.
        if let note = reciter.ayahMurattalStyleNote {
            return note
        }
        return reciter.displayNameForNowPlaying
    }

    private func resolvedSelectedReciter() -> Reciter? {
        if settings.reciter == Settings.randomReciterName {
            return reciters.randomElement()
        }

        return settings.resolvedSelectedReciterIgnoringRandom()
    }

    func playSurah(
        surahNumber: Int,
        surahName: String,
        certainReciter: Bool = false,
        skipSurah: Bool = false,
        repeatCount: Int = 1
    ) {
        ayahBackPendingRestart?.cancel()
        ayahBackPendingRestart = nil
        ayahBackPendingRestartScheduledAt = nil
        guard (1...114).contains(surahNumber) else {
            presentPlaybackFailure("This surah could not be found. Please select a valid surah and try again.")
            return
        }

        self.repeatCount = max(1, repeatCount)
        self.repeatRemaining = self.repeatCount

        settings.recordSurahPlayed(surahNumber)

        // Synchronous @Published writes coalesce into one view update on their own - no withAnimation needed
        // (it would animate the whole observing List, not just the now-playing inset).
        currentSurahNumber = surahNumber
        currentAyahNumber = nil
        isPlayingSurah = true
        continueRecitationFromAyah = false
        backButtonClickCount = 0

        guard let reciterPref = resolvedSelectedReciter() else {
            presentPlaybackFailure("The selected reciter could not be found. Please choose another reciter in settings.")
            return
        }
        let reciter: Reciter
        if certainReciter, let lastReciter = settings.lastListenedSurah?.reciter {
            reciter = lastReciter
        } else {
            reciter = reciterPref
        }
        playbackReciter = reciter

        guard reciter.carriesSurah(surahNumber) else {
            presentPlaybackFailure("\(reciter.name) has not recorded this surah. Please choose another reciter for it.")
            return
        }

        let remoteURLString = "\(reciter.surahLink)\(String(format: "%03d", surahNumber)).mp3"
        guard let remoteURL = URL(string: remoteURLString) else {
            presentPlaybackFailure("The recitation link appears invalid. Please try another reciter.")
            return
        }

        let localURL = reciterDownloadManager.localSurahURL(reciter: reciter, surahNumber: surahNumber)
        let url = localURL ?? remoteURL

        // Offline with nothing on disk for this reciter: streaming can only end in the generic timeout
        // alert, so short-circuit to the "switch to a downloaded reciter" offer when one exists. If none
        // exists the stream is still attempted - reachability can be stale, and the reactive .failed
        // path below catches the honest outcome.
        if localURL == nil, !Self.isNetworkReachable,
           presentOfflineReciterOptions(surahNumber: surahNumber, surahName: surahName, failedReciter: reciter) {
            return
        }

        setupAudioSession()
        isLoading = true
        player?.pause(); removeAllObservers()

        let startupBuffer: TimeInterval = localURL != nil ? localSurahStartupBuffer : remoteSurahStartupBuffer

        // Adopt a matching prewarmed (already-buffering) player for a gapless hand-off; otherwise build fresh.
        let item: AVPlayerItem
        if let pre = prewarmedSurah, pre.surahNumber == surahNumber, pre.url == url {
            prewarmedSurah = nil
            item = pre.item
            configureFastStartPlayer(pre.player, bufferDuration: startupBuffer)
            player = pre.player
        } else {
            discardPrewarm()
            let fresh = makeFastStartItem(url: url, bufferDuration: startupBuffer)
            let avPlayer = AVPlayer(playerItem: fresh)
            configureFastStartPlayer(avPlayer, bufferDuration: startupBuffer)
            item = fresh
            player = avPlayer
        }

        wireSurahPlayback(
            item: item,
            surahNumber: surahNumber,
            surahName: surahName,
            reciter: reciter,
            certainReciter: certainReciter,
            skipSurah: skipSurah,
            wasLocal: localURL != nil
        )
    }

    /// Applies the "ready to play" transition for a surah item (used by the status observer and, when a
    /// prewarmed item is already ready, invoked directly since KVO doesn't fire for the current value).
    private func onSurahItemReady(surahNumber: Int, surahName: String, reciter: Reciter, certainReciter: Bool, skipSurah: Bool) {
        whenAudioSessionReady { [weak self] in
            self?.player?.playImmediately(atRate: 1.0)
        }
        // Flip isLoading off in the SAME update that turns isPlaying on, otherwise there's a frame where all
        // of isLoading/isPlaying/isPaused are false and the control briefly flashes the play icon. Synchronous
        // @Published writes already coalesce into one view update, so no withAnimation is needed (it animated
        // the whole observing List); the inset's own `.animation(value:)` handles its appearance.
        isLoading = false
        isPlaying = true
        isPaused = false
        nowPlayingTitle = "Surah \(surahNumber): \(surahName)" +
            repeatSuffix(total: repeatCount, remaining: repeatRemaining)
        nowPlayingReciter = reciter.displayNameForNowPlaying
        updateNowPlayingInfo()
        recordListeningHistory(surahNumber: surahNumber, surahName: surahName, reciter: reciter.displayNameWithEnglishQiraah)

        idleTimerSet(true)

        var didResume = false
        if certainReciter,
           let last = settings.lastListenedSurah,
           last.surahNumber == surahNumber,
           last.currentDuration > 1 {
            let seekT = CMTime(seconds: last.currentDuration, preferredTimescale: 600)
            player?.seek(to: seekT) { [weak self] _ in self?.updateNowPlayingInfo() }
            didResume = true
        }

        if !didResume && (!certainReciter || !skipSurah) {
            saveLastListenedSurah()
        }
    }

    /// Wires the status observer (+ already-ready fast path), end-of-item handler, and the prewarm timer for
    /// a surah player. Shared by fresh playback and prewarm adoption so behavior never diverges.
    private func wireSurahPlayback(item: AVPlayerItem, surahNumber: Int, surahName: String, reciter: Reciter, certainReciter: Bool, skipSurah: Bool, wasLocal: Bool = false) {
        statusObserver = item.observe(\.status) { [weak self] itm, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch itm.status {
                case .readyToPlay:
                    self.onSurahItemReady(surahNumber: surahNumber, surahName: surahName, reciter: reciter, certainReciter: certainReciter, skipSurah: skipSurah)
                case .failed:
                    // Only a CONNECTIVITY-shaped failure is the reactive offline signal (the reachability
                    // flag can miss captive/portal states, so those still offer downloaded reciters). A
                    // missing file (404) on a healthy connection must say so instead - the old blanket
                    // "check your internet" is exactly how a partial-mushaf reciter read as broken.
                    let kind = Self.classifyPlaybackError(itm.error)
                    let offlineShaped = kind == .offline || kind == .timeout || kind == .unknown
                    if wasLocal || !offlineShaped
                        || !self.presentOfflineReciterOptions(surahNumber: surahNumber, surahName: surahName, failedReciter: reciter) {
                        let details = self.playbackFailureDetails(for: itm.error, reciter: reciter,
                                                                  what: "surah", wasLocal: wasLocal)
                        self.presentPlaybackFailure(details.message, title: details.title)
                    }
                default:
                    break   // .unknown / still loading - wait for the next status change
                }
            }
        }
        // A prewarmed item may already be ready; KVO won't fire for the current value, so kick it now.
        if item.status == .readyToPlay {
            onSurahItemReady(surahNumber: surahNumber, surahName: surahName, reciter: reciter, certainReciter: certainReciter, skipSurah: skipSurah)
        }

        let obs = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item, queue: .main
        ) { [weak self] _ in
            guard let self = self, self.player?.currentItem === item else { return }

            if self.repeatRemaining > 1 {
                self.repeatRemaining -= 1

                if let n = self.currentSurahNumber, n == surahNumber {
                    self.nowPlayingTitle = "Surah \(surahNumber): \(surahName)" +
                        self.repeatSuffix(total: self.repeatCount, remaining: self.repeatRemaining)
                    self.updateNowPlayingInfo()
                }

                self.player?.seek(to: .zero) { _ in
                    self.player?.play()
                    self.isPlaying = true
                    self.isPaused = false
                    self.updateNowPlayingInfo()
                }
                return
            }

            if self.playNextQueuedSurahIfAvailable(certainReciter: certainReciter) {
                return
            }

            // At the ends of the mushaf (surah 114 going forward, surah 1 going backward) there is nothing
            // to continue to. playNext/PreviousSurah just return there, which left the player sitting at
            // the end of the item with `isPlaying` still true - a stuck now-playing bar and a disabled idle
            // timer. Recitation is over: stop properly.
            switch self.settings.reciteType {
            case "Continue to Previous":
                if let n = self.currentSurahNumber, n > 1 {
                    self.playPreviousSurah(certainReciter: certainReciter)
                } else {
                    self.stop()
                }
            case "End Recitation":
                self.stop()
            default:
                if let n = self.currentSurahNumber, n < 114 {
                    self.playNextSurah(certainReciter: certainReciter)
                } else {
                    self.stop()
                }
            }
        }
        notificationObservers.append(obs)

        // Prewarm the upcoming surah as the current one nears its end (gapless, like the next-ayah prefetch).
        if let p = player {
            let interval = CMTime(seconds: 1, preferredTimescale: 1)
            surahTimeObserver = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
                self?.maybePrewarmNextSurah(certainReciter: certainReciter)
            }
        }
    }

    /// The surah that will play after the current one ends - mirrors the end-of-item branch (queue first,
    /// then `reciteType`), excluding the repeat case (which replays the same surah).
    private func nextSurahDescriptor() -> (number: Int, name: String)? {
        if let queued = surahQueue.first {
            return (queued.surahNumber, queued.surahName)
        }
        guard let n = currentSurahNumber else { return nil }
        switch settings.reciteType {
        case "Continue to Previous":
            guard n > 1, let s = quranData.surah(n - 1) else { return nil }
            return (s.id, s.nameTransliteration)
        case "End Recitation":
            return nil
        default:
            guard n < 114, let s = quranData.surah(n + 1) else { return nil }
            return (s.id, s.nameTransliteration)
        }
    }

    /// Called from the surah time observer: once the current surah is within `surahPrewarmLeadTime` of the
    /// end (and not mid-repeat), build and start buffering the next surah's player so the hand-off is gapless.
    private func maybePrewarmNextSurah(certainReciter: Bool) {
        guard repeatRemaining <= 1 else { return }   // a repeat replays the same surah; nothing to prewarm
        guard let p = player, let item = p.currentItem else { return }
        let dur = CMTimeGetSeconds(item.duration)
        let cur = CMTimeGetSeconds(p.currentTime())
        guard dur.isFinite, dur > 0, cur.isFinite else { return }
        let remaining = dur - cur
        guard remaining > 0, remaining <= surahPrewarmLeadTime else { return }

        guard let next = nextSurahDescriptor() else { return }
        if prewarmedSurah?.surahNumber == next.number { return }   // already prewarmed
        prewarmNextSurah(number: next.number, name: next.name)
    }

    private func prewarmNextSurah(number: Int, name: String) {
        discardPrewarm()
        guard let reciter = playbackReciter ?? resolvedSelectedReciter() else { return }
        let localURL = reciterDownloadManager.localSurahURL(reciter: reciter, surahNumber: number)
        let remote = URL(string: "\(reciter.surahLink)\(String(format: "%03d", number)).mp3")
        guard let url = localURL ?? remote else { return }

        let buffer = localURL != nil ? localSurahStartupBuffer : remoteSurahStartupBuffer
        let item = makeFastStartItem(url: url, bufferDuration: buffer)
        let pre = AVPlayer(playerItem: item)
        pre.automaticallyWaitsToMinimizeStalling = false
        pre.pause()   // attaching the item to a player starts buffering even while paused
        prewarmedSurah = PrewarmedSurah(
            surahNumber: number,
            surahName: name,
            reciterSurahLink: reciter.surahLink,
            url: url,
            player: pre,
            item: item
        )
    }

    /// Tears down any prewarmed (but not yet promoted) surah player.
    private func discardPrewarm() {
        prewarmedSurah?.player.pause()
        prewarmedSurah?.item.asset.cancelLoading()
        prewarmedSurah = nil
    }

    func addSurahToQueue(surahNumber: Int, surahName: String) {
        guard (1...114).contains(surahNumber) else { return }
        let resolvedName = quranData.surah(surahNumber)?.nameTransliteration ?? surahName
        surahQueue.append(SurahQueueItem(surahNumber: surahNumber, surahName: resolvedName))
    }

    func removeQueuedSurah(id: UUID) {
        surahQueue.removeAll { $0.id == id }
    }

    func clearSurahQueue() {
        surahQueue.removeAll()
    }

    @discardableResult
    private func playNextQueuedSurahIfAvailable(certainReciter: Bool) -> Bool {
        guard !surahQueue.isEmpty else { return false }
        let next = surahQueue.removeFirst()
        playSurah(
            surahNumber: next.surahNumber,
            surahName: next.surahName,
            certainReciter: certainReciter,
            skipSurah: true
        )
        return true
    }
    
    private func playNextSurah(certainReciter: Bool = false) {
        repeatCount = 1
        repeatRemaining = 1
        
        guard let n = currentSurahNumber, n < 114, let next = quranData.quran.first(where: { $0.id == n + 1 })
        else { return }
        playSurah(surahNumber: next.id,
                  surahName: next.nameTransliteration,
                  certainReciter: certainReciter,
                  skipSurah: true)
    }
    
    private func playPreviousSurah(certainReciter: Bool = false) {
        repeatCount = 1
        repeatRemaining = 1
        
        guard let n = currentSurahNumber, n > 1, let prev = quranData.quran.first(where: { $0.id == n - 1 })
        else { return }
        playSurah(surahNumber: prev.id,
                  surahName: prev.nameTransliteration,
                  certainReciter: certainReciter,
                  skipSurah: true)
    }
    
    private func surahSkipBackward() {
        guard currentSurahNumber != nil else { return }
        let now = Date()
        // Two clicks within this window = go to the previous surah; a lone click just restarts the current
        // one. Widened to 1.5s (was 0.75s) so the second tap is easier to land from Control Center / the
        // Lock Screen / Notification Center where taps are slower.
        if let last = backButtonClickTimestamp, now.timeIntervalSince(last) < 1.5 {
            backButtonClickCount += 1
        } else {
            backButtonClickCount = 1
        }
        backButtonClickTimestamp = now

        if backButtonClickCount == 2 {
            playPreviousSurah(); backButtonClickCount = 0
        } else {
            pause()
            player?.seek(to: .zero) { [weak self] _ in self?.resume() }
            updateNowPlayingInfo()
            // Reset must outlast the double-tap window above, otherwise a legitimate second tap near the
            // 1.5s edge would be counted as a fresh first tap and just restart instead of going back.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { self.backButtonClickCount = 0 }
        }
    }
    private func surahSkipForward() { playNextSurah() }
    
    private var ayahRepeatCount: Int = 1
    private var ayahRepeatRemaining: Int = 1
    private var lastAyahParams: (surahNumber: Int, ayahNumber: Int, isBismillah: Bool, continueRecitation: Bool)?

    private var customRangeSequence: [(ayahNumber: Int, isBismillah: Bool)] = []
    private var customRangeSurahNumber: Int = 0
    private var customRangeSurahName: String = ""

    func playAyah(
        surahNumber: Int,
        ayahNumber: Int,
        isBismillah: Bool = false,
        continueRecitation: Bool = false,
        repeatCount: Int = 1
    ) {
        ayahBackPendingRestart?.cancel()
        ayahBackPendingRestart = nil
        ayahBackPendingRestartScheduledAt = nil
        guard let surah = quranData.quran.first(where: { $0.id == surahNumber }) else {
            presentPlaybackFailure("This surah could not be found. Please try again.")
            return
        }
        guard (1...surah.numberOfAyahs).contains(ayahNumber) else {
            presentPlaybackFailure("This ayah is outside the valid range for the selected surah.")
            return
        }
        guard let resolvedReciter = resolvedSelectedReciter() else {
            presentPlaybackFailure("The selected reciter could not be found. Please choose another reciter in settings.")
            return
        }

        // Playback is unconditional: the Minshawi-substitution heads-up is a SELECTION-time notice
        // (`needsMinshawiFallbackNotice(for:)`), so pressing play never opens a dialog.
        beginAyahPlayback(
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            isBismillah: isBismillah,
            continueRecitation: continueRecitation,
            repeatCount: repeatCount,
            reciter: resolvedReciter
        )
    }

    /// The tail of `playAyah` once a reciter is settled - split out so the Minshawi confirmation can
    /// resume the EXACT held playback (same reciter: re-resolving would re-roll "Random Reciter").
    private func beginAyahPlayback(
        surahNumber: Int,
        ayahNumber: Int,
        isBismillah: Bool,
        continueRecitation: Bool,
        repeatCount: Int,
        reciter: Reciter
    ) {
        playbackReciter = reciter

        self.ayahRepeatCount      = max(1, repeatCount)
        self.ayahRepeatRemaining  = self.ayahRepeatCount
        self.lastAyahParams       = (surahNumber, ayahNumber, isBismillah, continueRecitation)

        currentSurahNumber = surahNumber
        currentAyahNumber  = ayahNumber
        isPlayingSurah     = false

        continueRecitationFromAyah = continueRecitation
        didHandleSingleAyahEnd = false
        if !isBismillah { saveLastListenedAyah() }
        startAyahPlayback(
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
            isBismillah: isBismillah,
            continueRecitation: continueRecitation
        )
    }

    // MARK: - Minshawi ayah-fallback notice (selection time)
    //
    // Reciters with no verse-by-verse feed of their own silently borrow Al-Minshawi's Murattal for
    // single ayahs and custom ranges. The user is told about that ONCE, at the moment they pick such a
    // reciter - never again, and never by interrupting a play. The reciter picker owns the dialog; this
    // player owns the memory of who has already been told.

    /// True when choosing `reciter` should first surface the substitution notice. False once the user
    /// has acknowledged it for that reciter, on this or any later launch.
    func needsMinshawiFallbackNotice(for reciter: Reciter) -> Bool {
        reciter.defaultToMinshawi && !isMinshawiAyahFallbackConfirmed(reciter)
    }

    /// The picker's "select anyway" tap: record that this reciter's notice has been shown, so the
    /// dialog never appears for them again.
    func confirmMinshawiFallbackNotice(for reciter: Reciter) {
        rememberMinshawiAyahFallbackConfirmed(reciter)
    }

    /// The notice's body text, kept here so every presenter words the substitution identically.
    func minshawiFallbackNoticeMessage(for reciter: Reciter?) -> String {
        "\(reciter?.name ?? "This reciter") has no verse-by-verse recordings. Individual ayahs and custom ranges will play in \(Reciter.minshawiAyahFallbackName). This won't be asked again for this reciter."
    }

    private func isMinshawiAyahFallbackConfirmed(_ reciter: Reciter) -> Bool {
        confirmedMinshawiAyahFallbackReciterIDsRaw
            .components(separatedBy: Self.minshawiConfirmationSeparator)
            .contains(reciter.id)
    }

    private func rememberMinshawiAyahFallbackConfirmed(_ reciter: Reciter) {
        guard !isMinshawiAyahFallbackConfirmed(reciter) else { return }
        var ids = confirmedMinshawiAyahFallbackReciterIDsRaw
            .components(separatedBy: Self.minshawiConfirmationSeparator)
            .filter { !$0.isEmpty }
        ids.append(reciter.id)
        confirmedMinshawiAyahFallbackReciterIDsRaw = ids.joined(separator: Self.minshawiConfirmationSeparator)
    }

    func playCustomRange(
        surahNumber: Int,
        surahName: String,
        startAyah: Int,
        endAyah: Int,
        repeatPerAyah: Int,
        repeatSection: Int,
        initialSequenceIndex: Int = 0
    ) {
        ayahBackPendingRestart?.cancel()
        ayahBackPendingRestart = nil
        ayahBackPendingRestartScheduledAt = nil
        guard let surah = quranData.quran.first(where: { $0.id == surahNumber }) else {
            presentPlaybackFailure("This surah could not be found. Please try again.")
            return
        }
        guard (1...surah.numberOfAyahs).contains(startAyah),
              (1...surah.numberOfAyahs).contains(endAyah) else {
            presentPlaybackFailure("The selected ayah range is not valid for this surah.")
            return
        }
        guard startAyah <= endAyah else {
            presentPlaybackFailure("The range start cannot be after the range end.")
            return
        }
        guard let reciter = resolvedSelectedReciter() else {
            presentPlaybackFailure("The selected reciter could not be found. Please choose another reciter in settings.")
            return
        }
        playbackReciter = reciter

        let perAyah = max(1, repeatPerAyah)
        let section = max(1, repeatSection)

        var sequence: [(ayahNumber: Int, isBismillah: Bool)] = []
        for _ in 1...section {
            for ayah in startAyah...endAyah {
                for _ in 1...perAyah {
                    sequence.append((ayah, false))
                }
            }
        }

        guard !sequence.isEmpty
        else { return }
        let initialIndex = min(max(0, initialSequenceIndex), sequence.count - 1)
        let first = sequence[initialIndex]

        removeAllObservers()
        discardPrewarm()
        customRangeSequence = sequence
        customRangeSurahNumber = surahNumber
        customRangeSurahName = surahName
        customRangeStartAyah = startAyah
        customRangeEndAyah = endAyah
        customRangeRepeatPerAyah = perAyah
        customRangeRepeatSection = section
        customRangeCurrentIndex = initialIndex + 1
        customRangeTotalItems = sequence.count
        customRangeCurrentRepeatWithinAyah = ((initialIndex % perAyah) + 1)
        let itemsPerSection = max(1, (endAyah - startAyah + 1) * perAyah)
        customRangeRepeatSectionIndex = (initialIndex / itemsPerSection) + 1

        currentSurahNumber = surahNumber
        currentAyahNumber = first.ayahNumber
        isPlayingSurah = false
        isPlayingCustomRange = true
        continueRecitationFromAyah = false

        setupAudioSession()
        isLoading = true

        guard let firstItem = makeItem(forSurah: surah, reciter: reciter, ayahNumber: first.ayahNumber, isBismillah: first.isBismillah) else {
            isLoading = false
            presentPlaybackFailure("Unable to prepare the first ayah for this range.", title: "Range Playback Failed")
            customRangeSequence = []
            customRangeStartAyah = nil
            customRangeEndAyah = nil
            return
        }
        firstItem.preferredForwardBufferDuration = ayahStartupBuffer

        let q = AVQueuePlayer()
        q.actionAtItemEnd = .advance
        q.automaticallyWaitsToMinimizeStalling = false
        q.insert(firstItem, after: nil)

        let nextSequenceIndex = initialIndex + 1
        if nextSequenceIndex < sequence.count {
            let second = sequence[nextSequenceIndex]
            if let secondItem = makeItem(forSurah: surah, reciter: reciter, ayahNumber: second.ayahNumber, isBismillah: second.isBismillah) {
                secondItem.preferredForwardBufferDuration = ayahStartupBuffer
                q.insert(secondItem, after: firstItem)
            }
        }

        queuePlayer = q
        player = q

        statusObserver = firstItem.observe(\.status) { [weak self] itm, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                self.idleTimerSet(true)
                if itm.status == .readyToPlay {
                    guard initialIndex >= 0, initialIndex < self.customRangeSequence.count else { return }
                    self.whenAudioSessionReady { [weak self] in
                        self?.queuePlayer?.playImmediately(atRate: 1.0)
                    }
                    self.isPlaying = true
                    self.isPaused = false
                    let (ayahNum, isBismillah) = self.customRangeSequence[initialIndex]
                    let base = self.customRangeTitle(ayahNum: ayahNum, isBismillah: isBismillah, zeroBasedIndex: initialIndex)
                    self.nowPlayingTitle = base
                    self.nowPlayingReciter = self.ayahNowPlayingReciterName(for: reciter)
                    self.updateNowPlayingInfo()
                } else if itm.status == .failed {
                    let details = self.playbackFailureDetails(for: itm.error, reciter: reciter, what: "custom range")
                    self.presentPlaybackFailure(details.message, title: details.title)
                }
            }
        }

        queuePlayerItemObserver = q.observe(\.currentItem, options: [.old, .new]) { [weak self] qPlayer, change in
            guard let self = self else { return }
            DispatchQueue.main.async {
                guard self.isPlayingCustomRange else { return }

                guard let currentItem = qPlayer.currentItem else {
                    self.stop()
                    return
                }

                if change.oldValue != nil {
                    self.customRangeCurrentIndex = min((self.customRangeCurrentIndex ?? 1) + 1, self.customRangeSequence.count)
                }

                let currentIndex = max(1, self.customRangeCurrentIndex ?? 1)
                let zeroBasedIndex = currentIndex - 1
                guard zeroBasedIndex >= 0, zeroBasedIndex < self.customRangeSequence.count else {
                    self.stop()
                    return
                }

                let (ayahNum, isBismillah) = self.customRangeSequence[zeroBasedIndex]
                let perAyah = max(1, self.customRangeRepeatPerAyah)
                let repeatWithinAyah = ((zeroBasedIndex % perAyah) + 1)
                let numAyahsInRange = (self.customRangeEndAyah ?? 1) - (self.customRangeStartAyah ?? 1) + 1
                let itemsPerSection = numAyahsInRange * perAyah
                let sectionIndex = (zeroBasedIndex / max(1, itemsPerSection)) + 1

                let base = self.customRangeTitle(ayahNum: ayahNum, isBismillah: isBismillah, zeroBasedIndex: zeroBasedIndex)
                self.currentAyahNumber = ayahNum
                self.customRangeCurrentIndex = currentIndex
                self.customRangeCurrentRepeatWithinAyah = repeatWithinAyah
                self.customRangeRepeatSectionIndex = sectionIndex
                self.nowPlayingTitle = base
                self.nowPlayingReciter = self.ayahNowPlayingReciterName(for: reciter)
                self.updateNowPlayingInfo()
                self.saveLastListenedAyah()

                // Keep only a lightweight queue (current + next) to prevent large-memory lag spikes.
                if qPlayer.items().count < 2 {
                    let nextIndex = zeroBasedIndex + qPlayer.items().count
                    if nextIndex < self.customRangeSequence.count {
                        let next = self.customRangeSequence[nextIndex]
                        if let nextItem = self.makeItem(forSurah: surah, reciter: reciter, ayahNumber: next.ayahNumber, isBismillah: next.isBismillah) {
                            nextItem.preferredForwardBufferDuration = self.ayahStartupBuffer
                            qPlayer.insert(nextItem, after: currentItem)
                        }
                    }
                }
            }
        }
    }

    private func customRangeSkipAyah(by delta: Int) {
        guard isPlayingCustomRange,
              delta != 0,
              let currentIndex = customRangeCurrentIndex,
              let startAyah = customRangeStartAyah,
              let endAyah = customRangeEndAyah,
              customRangeSurahNumber > 0,
              !customRangeSurahName.isEmpty else {
            return
        }

        let perAyah = max(1, customRangeRepeatPerAyah)
        let ayahCount = max(1, endAyah - startAyah + 1)
        let itemsPerSection = ayahCount * perAyah
        let currentZeroBased = max(0, currentIndex - 1)
        let sectionStartIndex = (currentZeroBased / itemsPerSection) * itemsPerSection
        let ayahOffsetInSection = min(ayahCount - 1, max(0, (currentZeroBased - sectionStartIndex) / perAyah))
        let targetAyahOffset = min(ayahCount - 1, max(0, ayahOffsetInSection + delta))
        guard targetAyahOffset != ayahOffsetInSection else { return }

        let targetSequenceIndex = sectionStartIndex + (targetAyahOffset * perAyah)
        playCustomRange(
            surahNumber: customRangeSurahNumber,
            surahName: customRangeSurahName,
            startAyah: startAyah,
            endAyah: endAyah,
            repeatPerAyah: perAyah,
            repeatSection: customRangeRepeatSection,
            initialSequenceIndex: targetSequenceIndex
        )
    }

    /// Restart the in-progress custom range from the current ayah using the currently selected reciter,
    /// so the user can switch reciter mid-range without losing their place. `playCustomRange` re-resolves
    /// the selected reciter, so this just rebuilds the queue from the current position.
    func reloadCustomRangeWithCurrentReciter() {
        guard isPlayingCustomRange,
              let currentIndex = customRangeCurrentIndex,
              let startAyah = customRangeStartAyah,
              let endAyah = customRangeEndAyah,
              customRangeSurahNumber > 0,
              !customRangeSurahName.isEmpty else {
            return
        }
        playCustomRange(
            surahNumber: customRangeSurahNumber,
            surahName: customRangeSurahName,
            startAyah: startAyah,
            endAyah: endAyah,
            repeatPerAyah: max(1, customRangeRepeatPerAyah),
            repeatSection: customRangeRepeatSection,
            initialSequenceIndex: max(0, currentIndex - 1)
        )
    }

    private func customRangeTitle(ayahNum: Int, isBismillah: Bool, zeroBasedIndex: Int) -> String {
        let base = "\(customRangeSurahName) \(customRangeSurahNumber):\(ayahNum)"

        let perAyah = max(1, customRangeRepeatPerAyah)
        let sectionTotal = max(1, customRangeRepeatSection)
        let repeatWithinAyah = (zeroBasedIndex % perAyah) + 1
        let numAyahsInRange = max(1, (customRangeEndAyah ?? 1) - (customRangeStartAyah ?? 1) + 1)
        let itemsPerSection = max(1, numAyahsInRange * perAyah)
        let sectionIndex = (zeroBasedIndex / itemsPerSection) + 1

        return base + " (Ayah \(repeatWithinAyah)/\(perAyah)) (Sec \(sectionIndex)/\(sectionTotal))"
    }

    private func startAyahPlayback(
        surahNumber: Int,
        ayahNumber: Int,
        isBismillah: Bool,
        continueRecitation: Bool
    ) {
        removeAllObservers()
        discardPrewarm()

        guard
            let surah  = quranData.quran.first(where: { $0.id == surahNumber }),
            (1...surah.numberOfAyahs).contains(ayahNumber),
            let reciter = playbackReciter ?? resolvedSelectedReciter()
        else {
            presentPlaybackFailure("Could not prepare this ayah for playback. Please verify surah, ayah, and reciter settings.")
            return
        }

        setupAudioSession()
        isLoading = true

        if ayahRepeatCount > 1 || !continueRecitation {
            queuePlayer = nil

            guard let firstItem = makeItem(forSurah: surah, reciter: reciter, ayahNumber: ayahNumber, isBismillah: isBismillah) else {
                isLoading = false
                presentPlaybackFailure("Unable to load this ayah audio. Check your internet connection and try again.")
                return
            }
            firstItem.preferredForwardBufferDuration = ayahStartupBuffer

            let single = AVPlayer(playerItem: firstItem)
            single.actionAtItemEnd = .none
            configureFastStartPlayer(single, bufferDuration: ayahStartupBuffer)
            player = single

            statusObserver = firstItem.observe(\.status) { [weak self] itm, _ in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.idleTimerSet(true)
                    if itm.status == .readyToPlay {
                        self.whenAudioSessionReady { [weak self] in
                            self?.player?.playImmediately(atRate: 1.0)
                        }
                        // Clear isLoading in the same update that sets isPlaying to avoid a one-frame
                        // play-icon flash before the stop button appears (synchronous writes coalesce).
                        self.isLoading = false
                        self.isPlaying = true
                        self.isPaused  = false
                        let base = "\(surah.nameTransliteration) \(surahNumber):\(ayahNumber)"
                        self.nowPlayingTitle = base + self.repeatSuffix(total: self.ayahRepeatCount, remaining: self.ayahRepeatRemaining)
                        self.nowPlayingReciter = self.ayahNowPlayingReciterName(for: reciter)
                        self.updateNowPlayingInfo()
                    } else if itm.status == .failed {
                        self.isLoading = false
                        let details = self.playbackFailureDetails(for: itm.error, reciter: reciter, what: "ayah")
                        self.presentPlaybackFailure(details.message, title: details.title)
                    }
                }
            }

            let endObs = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: nil,
                queue: .main
            ) { [weak self] note in
                guard let self = self else { return }
                
                guard let finishedItem = note.object as? AVPlayerItem,
                      finishedItem == self.player?.currentItem else { return }

                guard !self.didHandleSingleAyahEnd else { return }
                self.didHandleSingleAyahEnd = true

                if self.ayahRepeatRemaining > 1 {
                    self.ayahRepeatRemaining -= 1
                    self.player?.seek(to: .zero) { _ in
                        self.didHandleSingleAyahEnd = false
                        self.nowPlayingTitle =
                            "\(surah.nameTransliteration) \(surahNumber):\(ayahNumber)" +
                            self.repeatSuffix(total: self.ayahRepeatCount,
                                              remaining: self.ayahRepeatRemaining)
                        self.updateNowPlayingInfo()
                        self.player?.play()
                        self.isPlaying = true
                        self.isPaused  = false
                    }
                } else {
                    self.stop()
                }
            }

            notificationObservers.append(endObs)
            return
        }

        guard let firstItem = makeItem(forSurah: surah, reciter: reciter, ayahNumber: ayahNumber, isBismillah: isBismillah) else {
            isLoading = false
            presentPlaybackFailure("Unable to load this ayah audio. Check your internet connection and try again.")
            return
        }
        firstItem.preferredForwardBufferDuration = ayahStartupBuffer

        var nextItem: AVPlayerItem?
        if ayahNumber < surah.numberOfAyahs {
            nextItem = makeItem(forSurah: surah, reciter: reciter, ayahNumber: ayahNumber + 1)
            nextItem?.preferredForwardBufferDuration = ayahStartupBuffer
        }

        let q = AVQueuePlayer()
        q.actionAtItemEnd = .advance
        q.automaticallyWaitsToMinimizeStalling = false

        q.insert(firstItem, after: nil)

        if let ni = nextItem {
            q.insert(ni, after: firstItem)
        }

        queuePlayer = q
        player = q

        statusObserver = firstItem.observe(\.status) { [weak self] itm, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.idleTimerSet(true)
                if itm.status == .readyToPlay {
                    self.whenAudioSessionReady { [weak self] in
                        self?.queuePlayer?.playImmediately(atRate: 1.0)
                    }
                    let base = "\(surah.nameTransliteration) \(surahNumber):\(ayahNumber)"
                    // Clear isLoading together with isPlaying so the control never flashes the play
                    // icon during the loading -> playing transition (synchronous writes coalesce).
                    self.isLoading = false
                    self.isPlaying = true
                    self.isPaused  = false
                    self.nowPlayingTitle = base
                    self.nowPlayingReciter = self.ayahNowPlayingReciterName(for: reciter)
                    self.updateNowPlayingInfo()
                } else if itm.status == .failed {
                    self.isLoading = false
                    let details = self.playbackFailureDetails(for: itm.error, reciter: reciter, what: "ayah")
                    self.presentPlaybackFailure(details.message, title: details.title)
                }
            }
        }

        queuePlayerItemObserver = q.observe(\.currentItem, options: [.old, .new]) { [weak self] qPlayer, change in
            guard let self = self else { return }
            
            if qPlayer.currentItem == nil || qPlayer.items().isEmpty {
                DispatchQueue.main.async {
                    self.stop()
                }
                return
            }
            
            guard let newItem = change.newValue as? AVPlayerItem else { return }

            // KVO for `currentItem` can fire on a non-main thread; marshal all @Published
            // mutations to main and avoid force-unwrapping state another path may have reset.
            DispatchQueue.main.async {
                guard let s = self.currentSurahNumber,
                      let a = self.currentAyahNumber,
                      let sur = self.quranData.quran.first(where: { $0.id == s }) else { return }

                guard a < sur.numberOfAyahs else {
                    self.stop()
                    return
                }

                let newAyah = a + 1
                self.currentAyahNumber = newAyah
                if let recNow = self.playbackReciter ?? self.resolvedSelectedReciter() {
                    self.nowPlayingTitle = "\(sur.nameTransliteration) \(s):\(newAyah)"
                    self.nowPlayingReciter = self.ayahNowPlayingReciterName(for: recNow)
                    self.updateNowPlayingInfo()
                }

                if self.continueRecitationFromAyah,
                   qPlayer.items().count < 2,
                   let rec = self.playbackReciter ?? self.resolvedSelectedReciter() {

                    let nextAyah = newAyah + 1
                    if nextAyah <= sur.numberOfAyahs,
                       let upcoming = self.makeItem(forSurah: sur, reciter: rec, ayahNumber: nextAyah) {
                        upcoming.preferredForwardBufferDuration = self.ayahStartupBuffer
                        qPlayer.insert(upcoming, after: newItem)
                    }
                }
            }
        }
    }
    
    private func makeItem(
        forSurah surah: Surah,
        reciter: Reciter,
        ayahNumber: Int,
        isBismillah: Bool = false
    ) -> AVPlayerItem? {
        // Offline-first: a downloaded surah with a VALIDATED timing table plays this ayah as a slice of the
        // local file - the reciter's own voice, no network. Everything about the item (duration, end
        // notification, repeats) matches a standalone ayah file, so the paths below stay authoritative for
        // every other case. Bismillah inserts keep the streaming path: timing tables don't carry them.
        if !isBismillah,
           let localURL = reciterDownloadManager.localSurahURL(reciter: reciter, surahNumber: surah.id) {
            if let window = AyahTimingStore.shared.validatedWindow(reciter: reciter, surahNumber: surah.id, ayahNumber: ayahNumber),
               let item = AyahTimingStore.makeSegmentItem(localURL: localURL, fromMs: window.fromMs, toMs: window.toMs) {
                return item
            }
            // Downloaded but no table yet: kick a background fetch so the NEXT playback is offline-capable.
            AyahTimingStore.shared.fetchTimingsIfNeeded(reciter: reciter, surahNumber: surah.id)
        }

        let urlStr: String
        if let folder = reciter.everyayahFolder {
            // everyayah.com uses a surah+ayah filename scheme. Used for editions whose cdn.islamic.network
            // feed is unreliable - Minshawi Mujawwad's islamic.network ayahs are the Murattal recording for
            // ~1 in 5 verses (same md5), which is what audibly dropped playback to Murattal mid-surah.
            urlStr = "https://everyayah.com/data/\(folder)/\(String(format: "%03d%03d", surah.id, ayahNumber)).mp3"
        } else {
            let globalId = quranData.quran.prefix(surah.id - 1).reduce(0) { $0 + $1.numberOfAyahs } + ayahNumber
            urlStr = "https://cdn.islamic.network/quran/audio/\(reciter.ayahBitrate)/\(reciter.ayahIdentifier)/\(globalId).mp3"
        }
        guard let url = URL(string: urlStr) else {
            presentPlaybackFailure("A valid audio link could not be created for this ayah.")
            return nil
        }
        return makeFastStartItem(url: url, bufferDuration: ayahStartupBuffer)
    }
    
    private func incrementAyahIfNeeded() {
        guard
            let s = currentSurahNumber,
            let a = currentAyahNumber,
            let sur = quranData.quran.first(where: { $0.id == s }),
            a < sur.numberOfAyahs
        else { return }
        currentAyahNumber = a + 1
    }
    
    func playBismillah() { playAyah(surahNumber: 1, ayahNumber: 1, isBismillah: true) }
    
    private func ayahSkipBackward() {
        guard let s = currentSurahNumber, let a = currentAyahNumber else { return }
        let repeatCountToKeep = ayahRepeatCount
        let now = Date()

        if let scheduledAt = ayahBackPendingRestartScheduledAt,
           now.timeIntervalSince(scheduledAt) >= ayahBackDoubleTapMinInterval {
            ayahBackPendingRestart?.cancel()
            ayahBackPendingRestart = nil
            ayahBackPendingRestartScheduledAt = nil
            if a > 1 {
                playAyah(
                    surahNumber: s,
                    ayahNumber: a - 1,
                    continueRecitation: continueRecitationFromAyah,
                    repeatCount: repeatCountToKeep
                )
            }
            return
        }
        if ayahBackPendingRestart != nil {
            return
        }

        let work = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.ayahBackPendingRestart = nil
            self.ayahBackPendingRestartScheduledAt = nil
            self.pause()
            self.player?.seek(to: .zero) { [weak self] _ in self?.resume() }
            self.updateNowPlayingInfo()
        }
        ayahBackPendingRestart = work
        ayahBackPendingRestartScheduledAt = now
        DispatchQueue.main.asyncAfter(deadline: .now() + ayahBackRestartDelay, execute: work)
    }
    
    private func ayahSkipForward(continueRecitation: Bool) {
        guard
            let s = currentSurahNumber,
            let a = currentAyahNumber,
            let sur = quranData.quran.first(where: { $0.id == s })
        else { return }
        let repeatCountToKeep = ayahRepeatCount
        (a + 1) <= sur.numberOfAyahs
            ? playAyah(
                surahNumber: s,
                ayahNumber: a + 1,
                continueRecitation: continueRecitation,
                repeatCount: repeatCountToKeep
            )
            : ()
    }
    
    private func updateNowPlayingInfo(clear: Bool = false) {
        let cmd = MPRemoteCommandCenter.shared()
        if clear {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            cmd.skipBackwardCommand.preferredIntervals = []
            cmd.skipForwardCommand.preferredIntervals = []
            cmd.skipBackwardCommand.isEnabled = false
            cmd.skipForwardCommand.isEnabled = false
            return
        }
        // Keep every system surface on previous/next controls instead of +/- seconds.
        cmd.previousTrackCommand.isEnabled = true
        cmd.nextTrackCommand.isEnabled = true
        cmd.skipBackwardCommand.isEnabled = false
        cmd.skipForwardCommand.isEnabled = false
        cmd.skipBackwardCommand.preferredIntervals = []
        cmd.skipForwardCommand.preferredIntervals = []

        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = nowPlayingTitle
        info[MPMediaItemPropertyArtist] = nowPlayingReciter
        if let dur = player?.currentItem?.duration {
            info[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(dur)
        }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(player?.currentTime() ?? .zero)
        info[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate
        if let img = UIImage(named: AppIdentifiers.appName) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func saveLastListenedSurah() {
        guard settings.saveLastListenedSurah else { return }
        guard
            nowPlayingTitle != nil,
            let num = currentSurahNumber,
            let p = player
        else { return }
        let rec = playbackReciter ?? settings.resolvedSelectedReciterIgnoringRandom()
        guard let rec else { return }

        let currDur = CMTimeGetSeconds(p.currentTime())
        let fullDur = CMTimeGetSeconds(p.currentItem?.duration ?? .zero)

        if isPlayingSurah, let sur = quranData.quran.first(where: { $0.id == num }) {
            // Tolerance, not ==: currentTime() and the item duration are Doubles from different clocks and
            // are almost never bit-identical, so exact equality made the "advance to the next surah" record
            // essentially unreachable.
            let endReached = fullDur > 0 && fullDur.isFinite && (fullDur - currDur) < 0.5
            let nextSurahNumber: Int? = endReached
                ? (settings.reciteType == "Continue to Previous" ? (num > 1 ? num - 1 : nil)
                   : settings.reciteType == "End Recitation"     ? nil
                   : (num < 114 ? num + 1 : nil))
                : nil

            if let nxt = nextSurahNumber, let nSur = quranData.quran.first(where: { $0.id == nxt }) {
                // No withAnimation: this republishes observing screens (e.g. SurahView); animating it
                // mid-scroll causes a visible jump when playback ends.
                //
                // fullDuration starts at 0 (every consumer guards `> 0`) and is patched in asynchronously.
                // It used to come from a SYNCHRONOUS `AVURLAsset.duration` on the next surah's REMOTE mp3 -
                // blocking network I/O on the main thread, a multi-second freeze when the next surah wasn't
                // downloaded and the connection was slow.
                settings.lastListenedSurah = LastListenedSurah(
                    surahNumber: nxt,
                    surahName: nSur.nameTransliteration,
                    reciter: rec,
                    currentDuration: 0,
                    fullDuration: 0,
                    savedAt: Date()
                )
                loadSurahDurationAsync(surahNumber: nxt, reciter: rec)
            } else {
                settings.lastListenedSurah = LastListenedSurah(
                    surahNumber: num,
                    surahName: sur.nameTransliteration,
                    reciter: rec,
                    currentDuration: currDur,
                    fullDuration: fullDur,
                    savedAt: Date()
                )
            }
        }
    }

    /// Persists the current single-ayah / custom-range position as the "Last Listened Ayah". Full-surah
    /// playback is handled by `saveLastListenedSurah()` instead, so this no-ops during surah playback.
    func saveLastListenedAyah() {
        guard settings.saveLastListenedAyah else { return }
        guard !isPlayingSurah,
              let surahNum = currentSurahNumber,
              let ayahNum = currentAyahNumber,
              let surah = quranData.quran.first(where: { $0.id == surahNum })
        else { return }
        let rec = playbackReciter ?? settings.resolvedSelectedReciterIgnoringRandom()
        guard let rec else { return }

        // When moving to a new ayah, push the previous one into the listening history below the row.
        if let previous = settings.lastListenedAyah,
           !(previous.surahNumber == surahNum && previous.ayahNumber == ayahNum) {
            recordAyahListeningHistory(previous)
        }

        settings.lastListenedAyah = LastListenedAyah(
            surahNumber: surahNum,
            surahName: surah.nameTransliteration,
            ayahNumber: ayahNum,
            reciter: rec,
            savedAt: Date()
        )
    }

    /// Adds a previously listened ayah to the history. Deduped by surah:ayah AND reciter: replaying the
    /// same ayah with the same reciter replaces the old entry and moves it to the top with a fresh
    /// timestamp; a different reciter is its own entry. Newest first, capped at 10.
    func recordAyahListeningHistory(_ entry: LastListenedAyah) {
        let item = AyahListeningHistoryItem(
            surahNumber: entry.surahNumber,
            surahName: entry.surahName,
            ayahNumber: entry.ayahNumber,
            reciter: entry.reciter
        )
        var updated = ayahListeningHistory.filter {
            !($0.surahNumber == entry.surahNumber
              && $0.ayahNumber == entry.ayahNumber
              && $0.reciter.name == entry.reciter.name)
        }
        updated.insert(item, at: 0)
        ayahListeningHistory = normalizeAyahListeningHistory(updated)
    }

    private func normalizeAyahListeningHistory(_ items: [AyahListeningHistoryItem]) -> [AyahListeningHistoryItem] {
        var seenKeys = Set<String>()
        var normalized: [AyahListeningHistoryItem] = []
        for item in items {
            let key = "\(item.surahNumber)-\(item.ayahNumber)-\(item.reciter.name)"
            if seenKeys.insert(key).inserted {
                normalized.append(item)
            }
        }
        return Array(normalized.prefix(10))
    }

    private func persistAyahListeningHistory() {
        let normalized = normalizeAyahListeningHistory(ayahListeningHistory)
        let hasChanged = normalized.count != ayahListeningHistory.count ||
            normalized.map { "\($0.surahNumber)-\($0.ayahNumber)" } !=
            ayahListeningHistory.map { "\($0.surahNumber)-\($0.ayahNumber)" }
        if hasChanged {
            ayahListeningHistory = normalized
            return
        }

        if let data = try? Settings.encoder.encode(normalized) {
            UserDefaults.standard.set(data, forKey: Self.ayahListeningHistoryKey)
        }
    }

    /// Records listening history when a new surah starts: the surah being DISPLACED from Last Listened
    /// goes into history, carrying its real Reciter and the position where the user stopped - so each
    /// history row can offer "resume from here" as well as "from the beginning". Deduped by surah AND
    /// reciter: replaying the same pair replaces the old entry at the top with a fresh timestamp; a
    /// different reciter (or surah) is its own entry. Newest first, cap 10.
    func recordListeningHistory(surahNumber: Int, surahName: String, reciter: String) {
        guard let previous = settings.lastListenedSurah else {
            lastSavedListeningSurahNumber = surahNumber
            return
        }
        // Restarting the same surah with the same reciter merely refreshes Last Listened - nothing was
        // displaced, so there is nothing to file into history.
        if previous.surahNumber == surahNumber,
           previous.reciter.displayNameWithEnglishQiraah == reciter {
            lastSavedListeningSurahNumber = surahNumber
            return
        }

        let item = ListeningHistoryItem(
            surahNumber: previous.surahNumber,
            surahName: previous.surahName,
            reciter: previous.reciter,
            currentDuration: previous.currentDuration,
            fullDuration: previous.fullDuration
        )

        var updated = listeningHistory.filter {
            !($0.surahNumber == previous.surahNumber && $0.reciter.name == previous.reciter.name)
        }
        updated.insert(item, at: 0)
        listeningHistory = normalizeListeningHistory(updated)

        lastSavedListeningSurahNumber = surahNumber
    }
    
    /// Records reading history with hybrid deduplication.
    /// Only saves if switching to different Surah OR moving 5+ ayahs away within same Surah.
    /// Also prevents saving if it matches the current last read ayah.
    func recordReadingHistory(surahNumber: Int, surahName: String, ayahNumber: Int) {
        let normalizedAyah = max(1, ayahNumber)

        // A position already in history isn't a duplicate to drop - it moves to the top as the newest
        // entry with a fresh timestamp.
        if readingHistory.contains(where: { $0.surahNumber == surahNumber && $0.ayahNumber == normalizedAyah }) {
            var updated = readingHistory.filter { !($0.surahNumber == surahNumber && $0.ayahNumber == normalizedAyah) }
            updated.insert(ReadingHistoryItem(surahNumber: surahNumber, surahName: surahName, ayahNumber: normalizedAyah), at: 0)
            readingHistory = normalizeReadingHistory(updated)
            lastSavedReadingPosition = (surahNumber, normalizedAyah)
            return
        }
        
        // Don't save if it matches the current last read ayah
        if settings.lastReadSurah == surahNumber && settings.lastReadAyah == normalizedAyah {
            return
        }
        
        let shouldSave: Bool
        
        if let last = lastSavedReadingPosition {
            if last.surahNumber != surahNumber {
                // Different surah - always save
                shouldSave = true
            } else if abs(last.ayahNumber - normalizedAyah) >= 5 {
                // Same surah but 5+ ayahs away - save
                shouldSave = true
            } else {
                // Same surah and within 4 ayahs - don't save
                shouldSave = false
            }
        } else {
            // First time - always save
            shouldSave = true
        }
        
        if shouldSave {
            let item = ReadingHistoryItem(
                surahNumber: surahNumber,
                surahName: surahName,
                ayahNumber: normalizedAyah
            )
            
            readingHistory.insert(item, at: 0)
            readingHistory = normalizeReadingHistory(readingHistory)

            lastSavedReadingPosition = (surahNumber, normalizedAyah)
        }
    }

    private func normalizeListeningHistory(_ items: [ListeningHistoryItem]) -> [ListeningHistoryItem] {
        var seenKeys = Set<String>()
        var normalized: [ListeningHistoryItem] = []

        for item in items {
            let key = "\(item.surahNumber)-\(item.reciter.name)"
            if seenKeys.insert(key).inserted {
                normalized.append(item)
            }
        }

        return Array(normalized.prefix(10))
    }

    private func normalizeReadingHistory(_ items: [ReadingHistoryItem]) -> [ReadingHistoryItem] {
        var seenKeys = Set<String>()
        var normalized: [ReadingHistoryItem] = []

        for item in items {
            let key = "\(item.surahNumber)-\(item.ayahNumber)"
            if seenKeys.insert(key).inserted {
                normalized.append(item)
            }
        }

        return Array(normalized.prefix(10))
    }

    private func persistListeningHistory() {
        let normalized = normalizeListeningHistory(listeningHistory)
        let hasChanged = normalized.count != listeningHistory.count ||
            normalized.map(\.surahNumber) != listeningHistory.map(\.surahNumber)
        if hasChanged {
            listeningHistory = normalized
            return
        }

        if let data = try? Settings.encoder.encode(normalized) {
            UserDefaults.standard.set(data, forKey: Self.listeningHistoryKey)
        }
    }

    private func persistReadingHistory() {
        let normalized = normalizeReadingHistory(readingHistory)
        let hasChanged = normalized.count != readingHistory.count ||
            normalized.map { "\($0.surahNumber)-\($0.ayahNumber)" } !=
            readingHistory.map { "\($0.surahNumber)-\($0.ayahNumber)" }
        if hasChanged {
            readingHistory = normalized
            return
        }

        if let data = try? Settings.encoder.encode(normalized) {
            UserDefaults.standard.set(data, forKey: Self.readingHistoryKey)
        }
    }

    private func loadHistoryFromDefaults() {
        if let listeningData = UserDefaults.standard.data(forKey: Self.listeningHistoryKey),
           let decodedListening = try? Settings.decoder.decode([ListeningHistoryItem].self, from: listeningData) {
            listeningHistory = normalizeListeningHistory(decodedListening)
            if let firstListening = listeningHistory.first {
                lastSavedListeningSurahNumber = firstListening.surahNumber
            }
        }

        if let readingData = UserDefaults.standard.data(forKey: Self.readingHistoryKey),
           let decodedReading = try? Settings.decoder.decode([ReadingHistoryItem].self, from: readingData) {
            let normalizedReading = decodedReading.map {
                ReadingHistoryItem(
                    surahNumber: $0.surahNumber,
                    surahName: $0.surahName,
                    ayahNumber: max(1, $0.ayahNumber)
                )
            }
            readingHistory = normalizeReadingHistory(normalizedReading)
            if let firstReading = readingHistory.first {
                lastSavedReadingPosition = (firstReading.surahNumber, firstReading.ayahNumber)
            }
        }

        if let ayahListeningData = UserDefaults.standard.data(forKey: Self.ayahListeningHistoryKey),
           let decodedAyahListening = try? Settings.decoder.decode([AyahListeningHistoryItem].self, from: ayahListeningData) {
            ayahListeningHistory = normalizeAyahListeningHistory(decodedAyahListening)
        }
    }

    
    /// Loads the surah's duration off-main (the asset may be a remote mp3 - loading it synchronously
    /// blocked the main thread on the network) and patches it into the just-written "last listened" record,
    /// but only if that record is still the one this load was started for.
    private func loadSurahDurationAsync(surahNumber: Int, reciter: Reciter) {
        #if os(iOS)
        guard let url = URL(string: "\(reciter.surahLink)\(String(format: "%03d", surahNumber)).mp3") else { return }

        Task.detached(priority: .utility) {
            let duration = (try? await AVURLAsset(url: url, options: ReciterAudioHosting.assetOptions(for: url)).load(.duration)) ?? .invalid
            guard duration.isValid, !duration.isIndefinite else { return }
            let seconds = CMTimeGetSeconds(duration)
            guard seconds.isFinite, seconds > 0 else { return }

            await MainActor.run {
                let settings = Settings.shared
                guard let current = settings.lastListenedSurah,
                      current.surahNumber == surahNumber,
                      current.reciter.ayahIdentifier == reciter.ayahIdentifier,
                      current.fullDuration == 0 else { return }
                settings.lastListenedSurah = LastListenedSurah(
                    surahNumber: current.surahNumber,
                    surahName: current.surahName,
                    reciter: current.reciter,
                    currentDuration: current.currentDuration,
                    fullDuration: seconds,
                    // A duration patch, not a new listen - keep the original stamp.
                    savedAt: current.savedAt
                )
            }
        }
        #endif
    }
    
    func idleTimerSet(_ disabled: Bool) {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = disabled
        #endif
    }
}

final class ReciterDownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = ReciterDownloadManager()

    struct DownloadState: Equatable {
        var isDownloading = false
        var completedSurahs = 0
        var totalSurahs = 114
        var totalBytes: Int64 = 0
        var currentSurahNumber: Int?
        var currentSurahProgress: Double = 0
        var errorMessage: String?
    }

    @Published private(set) var statesByReciterID: [String: DownloadState] = [:]

    private let sessionIdentifier = AppIdentifiers.reciterDownloadsBackgroundSessionIdentifier
    private let fileManager = FileManager.default
    private var activeTasks: [String: URLSessionDownloadTask] = [:]
    private var backgroundCompletionHandler: (() -> Void)?
    private let dedupeQueue = DispatchQueue(label: AppIdentifiers.reciterDownloadDedupeQueueLabel, qos: .utility)

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        configuration.isDiscretionary = false
        configuration.sessionSendsLaunchEvents = true
        configuration.waitsForConnectivity = true
        // A stalled transfer must eventually FAIL (and enter the per-surah retry path) rather than sit
        // in the background-session default of 7 days while the UI shows a frozen progress bar.
        configuration.timeoutIntervalForResource = 60 * 60
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    private override init() {
        super.init()
        configureBaseDirectory()
        restoreOngoingDownloads()
        dedupeQueue.async {
            self.deduplicateExistingDownloadsIfNeeded()
        }
    }

    func state(for reciter: Reciter) -> DownloadState {
        return statesByReciterID[reciter.id] ?? DownloadState()
    }

    /// Read-only snapshot for SwiftUI rendering. Does not publish any state changes.
    func stateSnapshot(for reciter: Reciter) -> DownloadState {
        if let existing = statesByReciterID[reciter.id] {
            return existing
        }
        let (count, bytes) = downloadedStats(for: reciter)
        return DownloadState(
            isDownloading: false,
            completedSurahs: count,
            // The reciter's CARRIED count, not 114: a partial-mushaf reciter's finished download
            // otherwise reads ~96% forever ("109 of 114").
            totalSurahs: reciter.carriedSurahCount,
            totalBytes: bytes,
            errorMessage: nil
        )
    }

    func ensureStateLoaded(for reciter: Reciter) {
        guard statesByReciterID[reciter.id] == nil else { return }
        let (count, bytes) = downloadedStats(for: reciter)
        statesByReciterID[reciter.id] = DownloadState(
            isDownloading: false,
            completedSurahs: count,
            totalSurahs: reciter.carriedSurahCount,
            totalBytes: bytes,
            errorMessage: nil
        )
    }

    /// Where a surah's ayah-timing table lives (or will live) - unlike `localSurahURL`, this does NOT
    /// require the audio file to exist yet, because the table is fetched alongside the download itself.
    func timingsFileURL(reciter: Reciter, surahNumber: Int) -> URL {
        try? ensureReciterDirectoryExists(reciter: reciter)
        return reciterDirectoryURL(reciter: reciter)
            .appendingPathComponent(String(format: "%03d.timings.json", surahNumber), isDirectory: false)
    }

    func localSurahURL(reciter: Reciter, surahNumber: Int) -> URL? {
        let url = localSurahFileURL(reciter: reciter, surahNumber: surahNumber)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func beginDownloadAll(for reciter: Reciter) {
        ensureStateLoaded(for: reciter)
        let reciterID = reciter.id

        // Only full-surah reciters can be downloaded; ayah-by-ayah reciters have no surah link, so fail
        // clearly instead of starting tasks against an invalid URL that would silently error out.
        guard !reciter.surahLink.isEmpty else {
            finishWithError(for: reciterID, message: "This reciter doesn't offer full-surah downloads.")
            return
        }

        if activeTasks[reciterID] != nil {
            return
        }

        // A fresh run retries everything still missing, including surahs that exhausted their retry
        // budget last time.
        failedSurahsByReciterID[reciterID] = nil
        lastFailureMessageByReciterID[reciterID] = nil
        retryAttempts = retryAttempts.filter { !$0.key.hasPrefix("\(reciterID)#") }

        var nextState = statesByReciterID[reciterID] ?? DownloadState()
        nextState.isDownloading = true
        nextState.errorMessage = nil
        nextState.currentSurahProgress = 0
        statesByReciterID[reciterID] = nextState
        scheduleNextDownload(for: reciter)
    }

    func cancelDownload(for reciter: Reciter) {
        let reciterID = reciter.id
        activeTasks[reciterID]?.cancel()
        activeTasks[reciterID] = nil

        // Drop this run's retry bookkeeping; any backoff timer still pending checks `isDownloading`
        // before re-enqueueing and finds it false.
        failedSurahsByReciterID[reciterID] = nil
        lastFailureMessageByReciterID[reciterID] = nil
        retryAttempts = retryAttempts.filter { !$0.key.hasPrefix("\(reciterID)#") }

        guard var state = statesByReciterID[reciterID] else { return }
        state.isDownloading = false
        state.currentSurahNumber = nil
        state.currentSurahProgress = 0
        statesByReciterID[reciterID] = state
    }

    func deleteDownloads(for reciter: Reciter) {
        cancelDownload(for: reciter)
        // The timing tables live in the reciter directory removed below; drop their memory cache with them
        // so a later re-download re-reads (and re-validates) from disk instead of trusting stale entries.
        DispatchQueue.main.async {
            AyahTimingStore.shared.forgetTimings(reciterID: reciter.id)
        }
        do {
            let dir = reciterDirectoryURL(reciter: reciter)
            if fileManager.fileExists(atPath: dir.path) {
                try fileManager.removeItem(at: dir)
            }
            try pruneUnusedSharedAudioFiles()
        } catch {
            var state = statesByReciterID[reciter.id] ?? DownloadState()
            state.errorMessage = error.localizedDescription
            statesByReciterID[reciter.id] = state
        }

        // Fresh state must keep the CARRIED denominator - `DownloadState()` defaults to 114, which
        // resurrected the forever-96% bar on a partial-mushaf reciter's delete-then-redownload.
        statesByReciterID[reciter.id] = DownloadState(totalSurahs: reciter.carriedSurahCount)
    }

    func deleteAllDownloads() {
        for reciterID in activeTasks.keys {
            activeTasks[reciterID]?.cancel()
        }
        activeTasks.removeAll()

        do {
            let root = baseDirectoryURL()
            if fileManager.fileExists(atPath: root.path) {
                try fileManager.removeItem(at: root)
            }
        } catch {
            logger.warning("Failed to delete all reciter downloads: \(error.localizedDescription)")
        }

        statesByReciterID.removeAll()
    }

    /// Reconciles published state with what is actually on disk. This USED to delete any reciter folder
    /// holding fewer than the reciter's full surah package - which defeated resume: a cancelled,
    /// interrupted, or partially-failed "Download all" lost every finished surah the moment the reciter
    /// list reappeared, forcing a from-scratch redownload. Each surah file is only ever installed whole
    /// (the finished background task's temp file is moved into place atomically), so a partial set is
    /// valid, playable, and resumable - keep it and just refresh the counts.
    func purgeIncompleteReciterDownloads() {
        for reciter in reciters {
            guard let state = statesByReciterID[reciter.id], !state.isDownloading else { continue }
            refreshState(for: reciter)
        }
    }

    func storageText(for reciter: Reciter) -> String {
        let state = stateSnapshot(for: reciter)
        return storageText(bytes: state.totalBytes)
    }

    func storageText(bytes: Int64) -> String {
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    func backgroundSessionCompletionHandler(_ completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler = completionHandler
            self.completeBackgroundEventsIfPossible()
        }
    }

    private func finishSuccess(for reciter: Reciter) {
        refreshState(for: reciter)
        DispatchQueue.main.async {
            self.activeTasks[reciter.id] = nil
            var state = self.statesByReciterID[reciter.id] ?? DownloadState()
            state.isDownloading = false
            state.currentSurahNumber = nil
            state.currentSurahProgress = 0
            state.errorMessage = nil
            self.statesByReciterID[reciter.id] = state
            self.completeBackgroundEventsIfPossible()
        }
    }

    private func finishWithError(for reciterID: String, message: String) {
        DispatchQueue.main.async {
            self.activeTasks[reciterID] = nil
            var state = self.statesByReciterID[reciterID] ?? DownloadState()
            state.isDownloading = false
            state.currentSurahNumber = nil
            state.currentSurahProgress = 0
            state.errorMessage = message
            self.statesByReciterID[reciterID] = state
            self.completeBackgroundEventsIfPossible()
        }
    }

    private func finishCancellation(for reciterID: String) {
        DispatchQueue.main.async {
            self.activeTasks[reciterID] = nil
            var state = self.statesByReciterID[reciterID] ?? DownloadState()
            state.isDownloading = false
            state.currentSurahNumber = nil
            state.currentSurahProgress = 0
            self.statesByReciterID[reciterID] = state
            self.completeBackgroundEventsIfPossible()
        }
    }

    private func refreshState(for reciter: Reciter) {
        let (count, bytes) = downloadedStats(for: reciter)
        DispatchQueue.main.async {
            var state = self.statesByReciterID[reciter.id] ?? DownloadState()
            state.completedSurahs = count
            state.totalBytes = bytes
            self.statesByReciterID[reciter.id] = state
        }
    }

    private func restoreOngoingDownloads() {
        session.getAllTasks { tasks in
            for task in tasks {
                guard let downloadTask = task as? URLSessionDownloadTask,
                      let (reciter, surahNumber) = self.taskContext(for: downloadTask) else {
                    task.cancel()
                    continue
                }

                DispatchQueue.main.async {
                    self.activeTasks[reciter.id] = downloadTask

                    let existing = self.statesByReciterID[reciter.id] ?? self.stateSnapshot(for: reciter)
                    var nextState = existing
                    nextState.isDownloading = true
                    nextState.currentSurahNumber = surahNumber
                    nextState.currentSurahProgress = 0
                    nextState.errorMessage = nil
                    self.statesByReciterID[reciter.id] = nextState
                }
            }
        }
    }

    private func scheduleNextDownload(for reciter: Reciter) {
        do {
            try ensureReciterDirectoryExists(reciter: reciter)
        } catch {
            finishWithError(for: reciter.id, message: error.localizedDescription)
            return
        }

        let failedThisRun = failedSurahsByReciterID[reciter.id] ?? []
        for surahNumber in 1...114 {
            // A partial mushaf's absent surahs aren't errors to retry - the file does not exist upstream.
            guard reciter.carriesSurah(surahNumber) else { continue }

            // Exhausted its retry budget this run: move past it so one bad file can't wedge the queue.
            // The final error summary (below) tells the user what is still missing.
            if failedThisRun.contains(surahNumber) { continue }

            let targetURL = localSurahFileURL(reciter: reciter, surahNumber: surahNumber)
            if fileManager.fileExists(atPath: targetURL.path) {
                continue
            }

            enqueueSurahDownload(reciter: reciter, surahNumber: surahNumber)
            return
        }

        if failedThisRun.isEmpty {
            finishSuccess(for: reciter)
        } else {
            failedSurahsByReciterID[reciter.id] = nil
            refreshState(for: reciter)
            var message = failedThisRun.count == 1
                ? "1 surah failed to download after several attempts. Tap Download to retry just the missing surahs."
                : "\(failedThisRun.count) surahs failed to download after several attempts. Tap Download to retry just the missing surahs."
            if let lastError = lastFailureMessageByReciterID.removeValue(forKey: reciter.id) {
                message += " (Last error: \(lastError))"
            }
            finishWithError(for: reciter.id, message: message)
        }
    }

    /// One surah's download. Timing-mapped reciters download the QDC encode instead of mp3quran's: the
    /// ayah timestamps were cut against QDC's files, and mp3quran's run seconds longer (different edits),
    /// so timings can only ever validate against the file they describe. One API call hands back BOTH the
    /// audio URL and the timing table; if it fails, the mp3quran path below downloads exactly as it always
    /// has (and the timing table simply never validates - nothing new breaks).
    private func enqueueSurahDownload(reciter: Reciter, surahNumber: Int) {
        if reciter.qdcReciterID != nil {
            Task { @MainActor in
                let qdc = await AyahTimingStore.shared.fetchDownloadSource(reciter: reciter, surahNumber: surahNumber)
                self.startSurahDownloadTask(reciter: reciter, surahNumber: surahNumber, overrideURL: qdc)
            }
        } else {
            startSurahDownloadTask(reciter: reciter, surahNumber: surahNumber, overrideURL: nil)
        }
    }

    // MARK: Per-surah retry bookkeeping (main thread only)

    /// Failed attempts per surah in the CURRENT run, keyed by `retryKey`.
    private var retryAttempts: [String: Int] = [:]
    /// Surahs that exhausted their retry budget this run; the queue moves past them and the run ends
    /// with an error summary instead of stopping on the first bad file.
    private var failedSurahsByReciterID: [String: Set<Int>] = [:]
    /// The most recent failure's message per reciter, surfaced in the end-of-run summary.
    private var lastFailureMessageByReciterID: [String: String] = [:]
    private let maxAttemptsPerSurah = 3

    /// "#" never appears in a reciter ID (name|qiraah|surahLink), so the key parses unambiguously.
    private func retryKey(_ reciterID: String, _ surahNumber: Int) -> String { "\(reciterID)#\(surahNumber)" }

    /// One surah's task failed: retry it with backoff (up to `maxAttemptsPerSurah` total tries), then
    /// give up on JUST that surah and let the queue continue. Main thread only.
    private func handleSurahFailure(reciter: Reciter, surahNumber: Int, message: String) {
        lastFailureMessageByReciterID[reciter.id] = message

        let key = retryKey(reciter.id, surahNumber)
        let attempts = (retryAttempts[key] ?? 0) + 1
        retryAttempts[key] = attempts

        guard attempts < maxAttemptsPerSurah else {
            retryAttempts[key] = nil
            failedSurahsByReciterID[reciter.id, default: []].insert(surahNumber)
            scheduleNextDownload(for: reciter)
            return
        }

        let backoff = pow(2.0, Double(attempts)) // 2s after the first failure, 4s after the second
        DispatchQueue.main.asyncAfter(deadline: .now() + backoff) { [weak self] in
            guard let self else { return }
            // The run may have been cancelled (or replaced) while the backoff timer waited.
            guard self.statesByReciterID[reciter.id]?.isDownloading == true,
                  self.activeTasks[reciter.id] == nil else { return }
            self.enqueueSurahDownload(reciter: reciter, surahNumber: surahNumber)
        }
    }

    /// Enqueue one surah's background download - from `overrideURL` (the QDC encode, for timing-mapped
    /// reciters) or the reciter's mp3quran link.
    private func startSurahDownloadTask(reciter: Reciter, surahNumber: Int, overrideURL: URL?) {
        let remoteURL: URL
        if let overrideURL {
            remoteURL = overrideURL
        } else {
            let remoteString = "\(reciter.surahLink)\(String(format: "%03d", surahNumber)).mp3"
            guard let url = URL(string: remoteString) else {
                finishWithError(for: reciter.id, message: "Invalid reciter link.")
                return
            }
            remoteURL = url
        }

        // Request (not bare URL) so islamweb-hosted feeds get their required Referer header.
        let task = session.downloadTask(with: ReciterAudioHosting.request(for: remoteURL))
        task.taskDescription = taskDescription(for: reciter, surahNumber: surahNumber)

        DispatchQueue.main.async {
            self.activeTasks[reciter.id] = task
            var state = self.statesByReciterID[reciter.id] ?? self.stateSnapshot(for: reciter)
            state.isDownloading = true
            state.currentSurahNumber = surahNumber
            state.currentSurahProgress = 0
            state.errorMessage = nil
            self.statesByReciterID[reciter.id] = state
            task.resume()
        }
    }

    private func taskDescription(for reciter: Reciter, surahNumber: Int) -> String {
        "\(reciter.id)|\(surahNumber)"
    }

    /// Resolves a task to its reciter/surah purely from the task's immutable `taskDescription`.
    /// Intentionally avoids any shared mutable cache so it is safe to call from the background
    /// URLSession delegate queue without racing the main-thread dictionary writers.
    private func taskContext(for task: URLSessionTask) -> (reciter: Reciter, surahNumber: Int)? {
        // `Reciter.id` ITSELF contains "|" separators (it is "name|qiraah|surahLink"), so the surah
        // number is everything after the LAST "|". Splitting at the FIRST one - the old parsing -
        // could never resolve a single task, which silently disabled every delegate callback: no
        // progress, no file install, no next-surah scheduling. The visible symptom was every surah
        // download frozen at "Downloading surah 1 of 114 (0%)" forever.
        guard let description = task.taskDescription,
              let separator = description.lastIndex(of: "|") else { return nil }
        let reciterID = String(description[..<separator])
        guard let surahNumber = Int(description[description.index(after: separator)...]),
              let reciter = reciters.first(where: { $0.id == reciterID }) else {
            return nil
        }
        return (reciter, surahNumber)
    }

    private func completeBackgroundEventsIfPossible() {
        guard let handler = backgroundCompletionHandler else { return }
        session.getAllTasks { tasks in
            guard tasks.isEmpty else { return }
            DispatchQueue.main.async {
                self.backgroundCompletionHandler = nil
                handler()
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let context = taskContext(for: downloadTask) else { return }
        let progress: Double
        if totalBytesExpectedToWrite > 0 {
            progress = min(max(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite), 0), 1)
        } else {
            progress = 0
        }

        DispatchQueue.main.async {
            var state = self.statesByReciterID[context.reciter.id] ?? self.stateSnapshot(for: context.reciter)
            state.isDownloading = true
            state.currentSurahNumber = context.surahNumber
            state.currentSurahProgress = progress
            state.errorMessage = nil
            self.statesByReciterID[context.reciter.id] = state
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let context = taskContext(for: downloadTask) else { return }

        // A non-2xx response is a FAILED download, whatever the transport says: a 404 error page used
        // to be installed as "NNN.mp3", counted as downloaded, and then played as a corrupt local file.
        if let http = downloadTask.response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            installFailedReciterIDs.insert(context.reciter.id)
            let message = http.statusCode == 404
                ? "The server has no audio file for surah \(context.surahNumber) from this reciter."
                : "The server refused surah \(context.surahNumber) (HTTP \(http.statusCode))."
            finishWithError(for: context.reciter.id, message: message)
            return
        }

        do {
            let targetURL = localSurahFileURL(reciter: context.reciter, surahNumber: context.surahNumber)
            try installDownloadedFile(from: location, to: targetURL, reciter: context.reciter)

            // The surah is on disk: fetch its ayah-timing table too (mapped reciters only; see
            // `AyahTimingStore`), so offline ayah ranges work from the moment the download finishes.
            let reciter = context.reciter
            let surahNumber = context.surahNumber
            DispatchQueue.main.async {
                AyahTimingStore.shared.fetchTimingsIfNeeded(reciter: reciter, surahNumber: surahNumber)
            }
        } catch {
            // Remember the failed INSTALL (disk full, move failure): the task itself "succeeded", so
            // `didCompleteWithError` arrives with error == nil and would otherwise overwrite this
            // error and schedule the SAME surah again - a silent re-download loop on a full disk.
            // Delegate callbacks share one serial queue, so the plain Set is safe here.
            installFailedReciterIDs.insert(context.reciter.id)
            finishWithError(for: context.reciter.id, message: error.localizedDescription)
        }
    }

    /// Reciters whose last finished task failed to INSTALL its file. Touched only on the session's
    /// serial delegate queue.
    private var installFailedReciterIDs: Set<String> = []

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let context = taskContext(for: task) else { return }
        // Read on the delegate queue BEFORE hopping to main: didFinishDownloadingTo runs on the same
        // serial queue and has already recorded any install failure for this task.
        let installFailed = error == nil && installFailedReciterIDs.remove(context.reciter.id) != nil

        DispatchQueue.main.async {
            self.activeTasks[context.reciter.id] = nil

            if let nsError = error as NSError? {
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    self.finishCancellation(for: context.reciter.id)
                } else {
                    // Transient failures (offline, timeout, server hiccup) retry with backoff; a surah
                    // that keeps failing is skipped so the rest of the queue still completes.
                    self.handleSurahFailure(
                        reciter: context.reciter,
                        surahNumber: context.surahNumber,
                        message: nsError.localizedDescription
                    )
                }
                return
            }

            // A failed install already surfaced its error; scheduling the next download would pick the
            // still-missing surah again, forever. Stop the chain - the user retries explicitly.
            if installFailed { return }

            self.retryAttempts[self.retryKey(context.reciter.id, context.surahNumber)] = nil
            self.refreshState(for: context.reciter)
            self.scheduleNextDownload(for: context.reciter)
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard let handler = self.backgroundCompletionHandler else { return }
            self.backgroundCompletionHandler = nil
            handler()
        }
    }

    private func downloadedStats(for reciter: Reciter) -> (count: Int, bytes: Int64) {
        let dir = reciterDirectoryURL(reciter: reciter)
        guard let urls = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return (0, 0)
        }

        var count = 0
        var totalBytes: Int64 = 0

        for surahNumber in 1...114 {
            let fileURL = localSurahFileURL(reciter: reciter, surahNumber: surahNumber)
            guard fileManager.fileExists(atPath: fileURL.path) else { continue }
            count += 1
        }

        for url in urls where url.pathExtension.lowercased() == "mp3" {
            if let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
               let size = values.fileSize {
                totalBytes += Int64(size)
            }
        }

        return (count, totalBytes)
    }

    private func ensureReciterDirectoryExists(reciter: Reciter) throws {
        let dir = reciterDirectoryURL(reciter: reciter)
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func installDownloadedFile(from temporaryURL: URL, to targetURL: URL, reciter: Reciter) throws {
        try ensureReciterDirectoryExists(reciter: reciter)
        try ensureSharedAudioDirectoryExists()

        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }

        let sharedURL = try canonicalSharedFileURL(forDownloadedFileAt: temporaryURL)
        if fileManager.fileExists(atPath: sharedURL.path) {
            try? fileManager.removeItem(at: temporaryURL)
        } else {
            try fileManager.moveItem(at: temporaryURL, to: sharedURL)
        }

        do {
            try fileManager.linkItem(at: sharedURL, to: targetURL)
        } catch {
            try fileManager.copyItem(at: sharedURL, to: targetURL)
        }
    }

    private func deduplicateExistingDownloadsIfNeeded() {
        let defaults = UserDefaults.standard
        let currentVersion = 1
        guard defaults.integer(forKey: "ReciterDownloadManagerDedupeVersion") < currentVersion else { return }
        try? ensureSharedAudioDirectoryExists()

        let root = baseDirectoryURL()
        guard let reciterDirectories = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        for directory in reciterDirectories where directory.lastPathComponent != "SharedAudio" {
            guard let files = try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }

            for fileURL in files where fileURL.pathExtension.lowercased() == "mp3" {
                do {
                    let sharedURL = try canonicalSharedFileURL(forDownloadedFileAt: fileURL)
                    if fileURL.standardizedFileURL == sharedURL.standardizedFileURL {
                        continue
                    }

                    if !fileManager.fileExists(atPath: sharedURL.path) {
                        try fileManager.moveItem(at: fileURL, to: sharedURL)
                    } else {
                        try fileManager.removeItem(at: fileURL)
                    }

                    do {
                        try fileManager.linkItem(at: sharedURL, to: fileURL)
                    } catch {
                        try fileManager.copyItem(at: sharedURL, to: fileURL)
                    }
                } catch {
                    logger.warning("Failed to deduplicate \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }

        defaults.set(currentVersion, forKey: "ReciterDownloadManagerDedupeVersion")
    }

    private func canonicalSharedFileURL(forDownloadedFileAt fileURL: URL) throws -> URL {
        let hash = try sha256Hash(for: fileURL)
        let ext = fileURL.pathExtension.isEmpty ? "mp3" : fileURL.pathExtension.lowercased()
        return sharedAudioDirectoryURL().appendingPathComponent("\(hash).\(ext)", isDirectory: false)
    }

    private func sha256Hash(for fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }

        var hasher = SHA256()
        while true {
            let chunk = try handle.read(upToCount: 1_048_576) ?? Data()
            if chunk.isEmpty { break }
            hasher.update(data: chunk)
        }

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private func configureBaseDirectory() {
        var root = baseDirectoryURL()
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? root.setResourceValues(values)
    }

    private func ensureSharedAudioDirectoryExists() throws {
        let dir = sharedAudioDirectoryURL()
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func pruneUnusedSharedAudioFiles() throws {
        let sharedDir = sharedAudioDirectoryURL()
        guard fileManager.fileExists(atPath: sharedDir.path) else { return }

        let sharedFiles = try fileManager.contentsOfDirectory(
            at: sharedDir,
            includingPropertiesForKeys: [.linkCountKey],
            options: [.skipsHiddenFiles]
        )

        for fileURL in sharedFiles where fileURL.pathExtension.lowercased() == "mp3" {
            let values = try? fileURL.resourceValues(forKeys: [.linkCountKey])
            let linkCount = values?.linkCount ?? 1
            if linkCount <= 1 {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }

    private func sharedAudioDirectoryURL() -> URL {
        baseDirectoryURL().appendingPathComponent("SharedAudio", isDirectory: true)
    }

    private func reciterDirectoryURL(reciter: Reciter) -> URL {
        let root = baseDirectoryURL()
        return root.appendingPathComponent(safeDirectoryName(for: reciter), isDirectory: true)
    }

    private func localSurahFileURL(reciter: Reciter, surahNumber: Int) -> URL {
        let filename = String(format: "%03d.mp3", surahNumber)
        return reciterDirectoryURL(reciter: reciter).appendingPathComponent(filename, isDirectory: false)
    }

    private func baseDirectoryURL() -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let root = appSupport.appendingPathComponent("ReciterDownloads", isDirectory: true)
        if !fileManager.fileExists(atPath: root.path) {
            try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        }
        return root
    }

    private func safeDirectoryName(for reciter: Reciter) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let sanitized = reciter.id.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        let joined = String(sanitized)
        return joined.isEmpty ? "reciter" : String(joined.prefix(180))
    }
}

// MARK: - Ayah timings (offline in-surah segment playback)

/// Per-surah ayah timestamps for reciters with a `qdcReciterID`, fetched from the QDC audio API (the service
/// behind quran.com and QUL) and cached next to the reciter's downloaded surah files.
///
/// The timestamps were cut against QDC's own audio encodes, and ours come from mp3quran - usually the same
/// studio recordings, but not guaranteed. So a timing table is only ever USED after validation: the API's
/// total duration must agree with the local file's real duration to within a small tolerance. A table that
/// fails validation is kept (so it isn't refetched) but marked unusable, and playback silently keeps its
/// existing per-ayah streaming behavior. Segment playback is therefore strictly additive: no local file, no
/// mapping, no fetch yet, or a failed validation all mean "exactly what the app did before".
@MainActor
final class AyahTimingStore {
    static let shared = AyahTimingStore()
    private init() {}

    struct SurahTimings: Codable {
        /// True when the API duration matched the LOCAL file's duration - the only state segments play from.
        let validated: Bool
        /// Milliseconds, keyed by ayah number: [from, to] within the surah file.
        let timings: [Int: [Int]]
    }

    /// Memory cache keyed by "\(reciter.id)|\(surah)"; misses fall through to disk once, then stay resident.
    private var cache: [String: SurahTimings] = [:]
    /// Keys with a fetch in flight, so bursts of makeItem calls don't stack duplicate requests.
    private var inFlight: Set<String> = []

    private func key(_ reciter: Reciter, _ surahNumber: Int) -> String { "\(reciter.id)|\(surahNumber)" }

    private func timingsFileURL(reciter: Reciter, surahNumber: Int) -> URL {
        ReciterDownloadManager.shared.timingsFileURL(reciter: reciter, surahNumber: surahNumber)
    }

    /// The download-time half of the pipeline: one API call returns BOTH the QDC audio URL (the encode the
    /// timestamps describe) and the timing table. The table is persisted as validated - audio and timings
    /// come from the same source, so there is nothing to cross-check - and the audio URL is handed back for
    /// the download manager to enqueue. nil (unmapped reciter, network/API failure) tells the caller to
    /// download from mp3quran exactly as before.
    func fetchDownloadSource(reciter: Reciter, surahNumber: Int) async -> URL? {
        guard let qdcID = reciter.qdcReciterID,
              let url = URL(string: "https://api.qurancdn.com/api/qdc/audio/reciters/\(qdcID)/audio_files?chapter=\(surahNumber)&segments=true"),
              let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let parsed = Self.parse(data: data, surahNumber: surahNumber),
              let audioURLString = parsed.audioURL,
              let audioURL = URL(string: audioURLString) else { return nil }

        let table = SurahTimings(validated: true, timings: parsed.timings)
        if let encoded = try? JSONEncoder().encode(table) {
            try? encoded.write(to: timingsFileURL(reciter: reciter, surahNumber: surahNumber), options: .atomic)
        }
        cache[key(reciter, surahNumber)] = table
        return audioURL
    }

    /// The validated [fromMs, toMs] window for one ayah, or nil in every case where segment playback
    /// shouldn't happen. Purely local: never blocks, never touches the network.
    func validatedWindow(reciter: Reciter, surahNumber: Int, ayahNumber: Int) -> (fromMs: Int, toMs: Int)? {
        guard reciter.qdcReciterID != nil else { return nil }
        let k = key(reciter, surahNumber)

        var table = cache[k]
        if table == nil {
            let fileURL = timingsFileURL(reciter: reciter, surahNumber: surahNumber)
            guard let data = try? Data(contentsOf: fileURL),
                  let decoded = try? JSONDecoder().decode(SurahTimings.self, from: data) else { return nil }
            cache[k] = decoded
            table = decoded
        }

        guard let table, table.validated,
              let window = table.timings[ayahNumber], window.count == 2 else { return nil }
        return (window[0], window[1])
    }

    /// Drops every cached table for a reciter - called when its downloads are deleted.
    func forgetTimings(reciterID: String) {
        cache = cache.filter { !$0.key.hasPrefix("\(reciterID)|") }
    }

    /// Fetch + validate + persist the timing table for a DOWNLOADED surah. No-op unless the reciter is
    /// mapped, the surah file is on disk, and no table exists yet. Fire-and-forget: callers never wait on it.
    func fetchTimingsIfNeeded(reciter: Reciter, surahNumber: Int) {
        guard let qdcID = reciter.qdcReciterID,
              let localURL = ReciterDownloadManager.shared.localSurahURL(reciter: reciter, surahNumber: surahNumber) else { return }
        let fileURL = timingsFileURL(reciter: reciter, surahNumber: surahNumber)

        let k = key(reciter, surahNumber)
        guard cache[k] == nil, !FileManager.default.fileExists(atPath: fileURL.path), !inFlight.contains(k) else { return }
        inFlight.insert(k)

        guard let url = URL(string: "https://api.qurancdn.com/api/qdc/audio/reciters/\(qdcID)/audio_files?chapter=\(surahNumber)&segments=true") else {
            inFlight.remove(k)
            return
        }

        Task { [weak self] in
            defer { Task { @MainActor in self?.inFlight.remove(k) } }

            guard let (data, response) = try? await URLSession.shared.data(from: url),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let parsed = Self.parse(data: data, surahNumber: surahNumber) else { return }

            // The local file's REAL duration, off the main thread - this is the validation yardstick.
            let asset = AVURLAsset(url: localURL)
            let localSeconds: Double
            if let duration = try? await asset.load(.duration) { localSeconds = duration.seconds } else { return }

            let localMs = localSeconds * 1000
            // The API reports ms; tolerate a moment of trailing silence difference between encodes.
            let apiMs = Double(parsed.apiDurationMs)
            let validated = abs(localMs - apiMs) <= 2_000 || abs(localMs - apiMs * 1000) <= 2_000

            let table = SurahTimings(validated: validated, timings: parsed.timings)
            guard let encoded = try? JSONEncoder().encode(table) else { return }
            try? encoded.write(to: fileURL, options: .atomic)

            await MainActor.run { [weak self] in
                self?.cache[k] = table
            }
        }
    }

    /// Pull `verse_timings` (and the audio URL the timings describe) out of the QDC response.
    /// `nonisolated` static: pure parsing, no shared state.
    nonisolated private static func parse(data: Data, surahNumber: Int) -> (apiDurationMs: Int, timings: [Int: [Int]], audioURL: String?)? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let files = root["audio_files"] as? [[String: Any]],
              let file = files.first else { return nil }

        var timings: [Int: [Int]] = [:]
        for entry in (file["verse_timings"] as? [[String: Any]]) ?? [] {
            guard let verseKey = entry["verse_key"] as? String,
                  let from = entry["timestamp_from"] as? Int,
                  let to = entry["timestamp_to"] as? Int else { continue }
            let parts = verseKey.split(separator: ":")
            guard parts.count == 2, Int(parts[0]) == surahNumber, let ayah = Int(parts[1]) else { continue }
            timings[ayah] = [from, to]
        }
        guard !timings.isEmpty else { return nil }

        // Prefer the API's total; fall back to the last ayah's end when the field is missing.
        let apiDuration = (file["duration"] as? Int) ?? timings.values.map { $0[1] }.max() ?? 0
        return (apiDuration, timings, file["audio_url"] as? String)
    }

    /// An `AVPlayerItem` holding just this ayah's slice of the local surah file. A composition rather than a
    /// seek + forward-end: the item then IS the ayah - its duration, its end-of-item notification, its repeat
    /// behavior all match a standalone per-ayah file, so the existing playback engine needs no special cases.
    nonisolated static func makeSegmentItem(localURL: URL, fromMs: Int, toMs: Int) -> AVPlayerItem? {
        guard toMs > fromMs else { return nil }
        let asset = AVURLAsset(url: localURL)
        let composition = AVMutableComposition()
        let range = CMTimeRange(
            start: CMTime(value: CMTimeValue(fromMs), timescale: 1000),
            end: CMTime(value: CMTimeValue(toMs), timescale: 1000)
        )
        do {
            try composition.insertTimeRange(range, of: asset, at: .zero)
        } catch {
            return nil
        }
        // `AVPlayerItem(asset:)` is MainActor-annotated in the current SDK. Every known call path is the
        // playback engine's main thread - but `assumeIsolated` would CRASH (a release-mode dispatch
        // precondition) if any future path ever arrived off-main, so prove the assumption safely: hop
        // synchronously when needed instead of trapping.
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                AVPlayerItem(asset: composition)
            }
        }
        return DispatchQueue.main.sync {
            AVPlayerItem(asset: composition)
        }
    }
}
