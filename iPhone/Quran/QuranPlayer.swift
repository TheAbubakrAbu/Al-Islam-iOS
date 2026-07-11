import SwiftUI
import AVFoundation
import MediaPlayer
import Foundation
import CryptoKit

struct SurahQueueItem: Identifiable, Equatable {
    let id = UUID()
    let surahNumber: Int
    let surahName: String
}

final class QuranPlayer: ObservableObject {
    static let shared = QuranPlayer()
    private static let listeningHistoryKey = "quranListeningHistoryData"
    private static let readingHistoryKey = "quranReadingHistoryData"
    private static let ayahListeningHistoryKey = "quranAyahListeningHistoryData"
    
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    
    @Published var isLoading = false
    @Published private(set) var isReadyForUI = false
    @Published private(set) var isPlaying = false
    @Published private(set) var isPaused = false
    
    @Published var currentSurahNumber: Int?
    @Published var currentAyahNumber: Int?
    @Published var isPlayingSurah = false
    @Published var isPlayingCustomRange = false
    @Published var showInternetAlert = false
    @Published var playbackAlertTitle = "Playback Error"
    @Published var playbackAlertMessage = "Unable to load this recitation right now. Please try again."
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
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
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
    
    private func setupAudioSession() {
        do {
            let s = AVAudioSession.sharedInstance()
            try s.setCategory(.playback)
            try s.setActive(true, options: .notifyOthersOnDeactivation)
        } catch { logger.debug("Audio session setup failed: \(error)") }
    }
    
    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false,
                                                          options: .notifyOthersOnDeactivation)
        } catch { logger.debug("Audio session deactivate failed: \(error)") }
    }

    private func makeFastStartItem(url: URL, bufferDuration: TimeInterval = 2) -> AVPlayerItem {
        let asset = AVURLAsset(
            url: url,
            options: [AVURLAssetPreferPreciseDurationAndTimingKey: false]
        )
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = bufferDuration
        return item
    }

    private func configureFastStartPlayer(_ player: AVPlayer, bufferDuration: TimeInterval = 2) {
        player.automaticallyWaitsToMinimizeStalling = false
        player.currentItem?.preferredForwardBufferDuration = bufferDuration
    }

    private func presentPlaybackFailure(_ message: String, title: String = "Playback Error") {
        DispatchQueue.main.async {
            self.isLoading = false
            self.isPlaying = false
            self.isPaused = false
            self.playbackAlertTitle = title
            self.playbackAlertMessage = message
            self.showInternetAlert = true
            self.idleTimerSet(false)
        }
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard
            let user = notification.userInfo,
            let tVal = user[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: tVal)
        else { return }
        
        switch type {
        case .began:
            pause()
            idleTimerSet(false)
            
        case .ended:
            if let opts = user[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: opts).contains(.shouldResume) {
                player?.play()
                isPlaying = true
                isPaused = false
                idleTimerSet(true)
            }
            
        @unknown default:
            break
        }
        updateNowPlayingInfo()
    }
    
    private func setupRemoteTransportControls() {
        let cmd = MPRemoteCommandCenter.shared()
        
        cmd.playCommand.addTarget { [unowned self] _ in
            guard !isPlaying else { return .commandFailed }
            player?.play()
            isPlaying = true
            isPaused = false
            idleTimerSet(true)
            updateNowPlayingInfo()
            return .success
        }
        
        cmd.pauseCommand.addTarget { [unowned self] _ in
            guard isPlaying else { return .commandFailed }
            pause()
            return .success
        }
        
        cmd.stopCommand.addTarget { [unowned self] _ in
            guard isPlaying else { return .commandFailed }
            pause()
            isPlaying = false
            isPaused = false
            return .success
        }
        
        cmd.previousTrackCommand.addTarget { [unowned self] _ in
            skipBackwardFromRemote()
            return .success
        }
        cmd.nextTrackCommand.addTarget { [unowned self] _ in
            skipForwardFromRemote()
            return .success
        }
        
        cmd.skipBackwardCommand.addTarget { [unowned self] _ in
            guard player != nil else { return .commandFailed }
            skipBackwardFromRemote()
            return .success
        }
        cmd.skipForwardCommand.addTarget { [unowned self] _ in
            guard player != nil else { return .commandFailed }
            skipForwardFromRemote()
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
            p.seek(to: CMTime(seconds: e.positionTime, preferredTimescale: 1)) { _ in
                self.updateNowPlayingInfo()
                self.saveLastListenedSurah()
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
        player?.play()
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
        p.seek(to: CMTime(seconds: target, preferredTimescale: 1)) { _ in
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
        // Mujawwad/Muallim variants with no per-ayah recording in that style play the reciter's Murattal —
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

        // Synchronous @Published writes coalesce into one view update on their own — no withAnimation needed
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

        let remoteURLString = "\(reciter.surahLink)\(String(format: "%03d", surahNumber)).mp3"
        guard let remoteURL = URL(string: remoteURLString) else {
            presentPlaybackFailure("The recitation link appears invalid. Please try another reciter.")
            return
        }

        let localURL = reciterDownloadManager.localSurahURL(reciter: reciter, surahNumber: surahNumber)
        let url = localURL ?? remoteURL

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
            skipSurah: skipSurah
        )
    }

    /// Applies the "ready to play" transition for a surah item (used by the status observer and, when a
    /// prewarmed item is already ready, invoked directly since KVO doesn't fire for the current value).
    private func onSurahItemReady(surahNumber: Int, surahName: String, reciter: Reciter, certainReciter: Bool, skipSurah: Bool) {
        player?.playImmediately(atRate: 1.0)
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
            let seekT = CMTime(seconds: last.currentDuration, preferredTimescale: 1)
            player?.seek(to: seekT) { [weak self] _ in self?.updateNowPlayingInfo() }
            didResume = true
        }

        if !didResume && (!certainReciter || !skipSurah) {
            saveLastListenedSurah()
        }
    }

    /// Wires the status observer (+ already-ready fast path), end-of-item handler, and the prewarm timer for
    /// a surah player. Shared by fresh playback and prewarm adoption so behavior never diverges.
    private func wireSurahPlayback(item: AVPlayerItem, surahNumber: Int, surahName: String, reciter: Reciter, certainReciter: Bool, skipSurah: Bool) {
        statusObserver = item.observe(\.status) { [weak self] itm, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch itm.status {
                case .readyToPlay:
                    self.onSurahItemReady(surahNumber: surahNumber, surahName: surahName, reciter: reciter, certainReciter: certainReciter, skipSurah: skipSurah)
                case .failed:
                    self.presentPlaybackFailure("Unable to load this recitation. Check your internet connection and try again.", title: "Playback Unavailable")
                default:
                    break   // .unknown / still loading — wait for the next status change
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

            switch self.settings.reciteType {
            case "Continue to Previous": self.playPreviousSurah(certainReciter: certainReciter)
            case "End Recitation": self.stop()
            default: self.playNextSurah(certainReciter: certainReciter)
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

    /// The surah that will play after the current one ends — mirrors the end-of-item branch (queue first,
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
        playbackReciter = resolvedReciter

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
                    self.queuePlayer?.playImmediately(atRate: 1.0)
                    self.isPlaying = true
                    self.isPaused = false
                    let (ayahNum, isBismillah) = self.customRangeSequence[initialIndex]
                    let base = self.customRangeTitle(ayahNum: ayahNum, isBismillah: isBismillah, zeroBasedIndex: initialIndex)
                    self.nowPlayingTitle = base
                    self.nowPlayingReciter = self.ayahNowPlayingReciterName(for: reciter)
                    self.updateNowPlayingInfo()
                } else if itm.status == .failed {
                    self.presentPlaybackFailure("Unable to start this custom range. Check your internet connection and try again.", title: "Range Playback Failed")
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
                        self.player?.playImmediately(atRate: 1.0)
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
                        self.presentPlaybackFailure("Unable to start ayah playback. Check your internet connection and try again.")
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
                    self.queuePlayer?.playImmediately(atRate: 1.0)
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
                    self.presentPlaybackFailure("Unable to continue ayah playback. Check your internet connection and try again.")
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
        let urlStr: String
        if let folder = reciter.everyayahFolder {
            // everyayah.com uses a surah+ayah filename scheme. Used for editions whose cdn.islamic.network
            // feed is unreliable — Minshawi Mujawwad's islamic.network ayahs are the Murattal recording for
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
            let endReached = currDur == fullDur
            let nextSurahNumber: Int? = endReached
                ? (settings.reciteType == "Continue to Previous" ? (num > 1 ? num - 1 : nil)
                   : settings.reciteType == "End Recitation"     ? nil
                   : (num < 114 ? num + 1 : nil))
                : nil

            if let nxt = nextSurahNumber, let nSur = quranData.quran.first(where: { $0.id == nxt }) {
                // No withAnimation: this republishes observing screens (e.g. SurahView); animating it
                // mid-scroll causes a visible jump when playback ends.
                settings.lastListenedSurah = LastListenedSurah(
                    surahNumber: nxt,
                    surahName: nSur.nameTransliteration,
                    reciter: rec,
                    currentDuration: 0,
                    fullDuration: getSurahDuration(surahNumber: nxt)
                )
            } else {
                settings.lastListenedSurah = LastListenedSurah(
                    surahNumber: num,
                    surahName: sur.nameTransliteration,
                    reciter: rec,
                    currentDuration: currDur,
                    fullDuration: fullDur
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
            reciter: rec
        )
    }

    /// Adds a previously listened ayah to the history (deduped by surah:ayah, newest first, capped).
    func recordAyahListeningHistory(_ entry: LastListenedAyah) {
        if ayahListeningHistory.contains(where: { $0.surahNumber == entry.surahNumber && $0.ayahNumber == entry.ayahNumber }) {
            return
        }
        let item = AyahListeningHistoryItem(
            surahNumber: entry.surahNumber,
            surahName: entry.surahName,
            ayahNumber: entry.ayahNumber,
            reciter: entry.reciter
        )
        ayahListeningHistory.insert(item, at: 0)
        ayahListeningHistory = normalizeAyahListeningHistory(ayahListeningHistory)
    }

    private func normalizeAyahListeningHistory(_ items: [AyahListeningHistoryItem]) -> [AyahListeningHistoryItem] {
        var seenKeys = Set<String>()
        var normalized: [AyahListeningHistoryItem] = []
        for item in items {
            let key = "\(item.surahNumber)-\(item.ayahNumber)"
            if seenKeys.insert(key).inserted {
                normalized.append(item)
            }
        }
        return Array(normalized.prefix(5))
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

    /// Records listening history with surah-based deduplication.
    /// Saves only if the surah is not already present in history.
    func recordListeningHistory(surahNumber: Int, surahName: String, reciter: String) {
        // Don't save if this surah already exists anywhere in history.
        if listeningHistory.contains(where: { $0.surahNumber == surahNumber }) {
            return
        }

        if let lastSavedListeningSurahNumber, lastSavedListeningSurahNumber == surahNumber {
            return
        }
        
        // Don't save if it matches the current last listened surah
        if let lastListened = settings.lastListenedSurah, lastListened.surahNumber == surahNumber {
            return
        }

        let item = ListeningHistoryItem(
            surahNumber: surahNumber,
            surahName: surahName,
            reciter: Reciter(
                name: reciter,
                ayahIdentifier: "",
                ayahBitrate: "",
                surahLink: ""
            )
        )

        listeningHistory.insert(item, at: 0)
        listeningHistory = normalizeListeningHistory(listeningHistory)

        lastSavedListeningSurahNumber = surahNumber
    }
    
    /// Records reading history with hybrid deduplication.
    /// Only saves if switching to different Surah OR moving 5+ ayahs away within same Surah.
    /// Also prevents saving if it matches the current last read ayah.
    func recordReadingHistory(surahNumber: Int, surahName: String, ayahNumber: Int) {
        let normalizedAyah = max(1, ayahNumber)

        // Don't save duplicates already in history.
        if readingHistory.contains(where: { $0.surahNumber == surahNumber && $0.ayahNumber == normalizedAyah }) {
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
        var seenSurahNumbers = Set<Int>()
        var normalized: [ListeningHistoryItem] = []

        for item in items {
            if seenSurahNumbers.insert(item.surahNumber).inserted {
                normalized.append(item)
            }
        }

        return Array(normalized.prefix(5))
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

        return Array(normalized.prefix(5))
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

    
    func getSurahDuration(surahNumber: Int) -> Double {
        #if os(iOS)
        guard
            let rec = playbackReciter ?? resolvedSelectedReciter(),
            let url = URL(string: "\(rec.surahLink)\(String(format: "%03d", surahNumber)).mp3")
        else { return 0 }

        let duration = AVURLAsset(url: url).duration
        guard duration.isValid, !duration.isIndefinite else { return 0 }
        let seconds = CMTimeGetSeconds(duration)
        return seconds.isFinite ? seconds : 0
        #else
        // The watch doesn't rely on this value, so just return 0
        return 0
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
            totalSurahs: 114,
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
            totalSurahs: 114,
            totalBytes: bytes,
            errorMessage: nil
        )
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

        guard var state = statesByReciterID[reciterID] else { return }
        state.isDownloading = false
        state.currentSurahNumber = nil
        state.currentSurahProgress = 0
        statesByReciterID[reciterID] = state
    }

    func deleteDownloads(for reciter: Reciter) {
        cancelDownload(for: reciter)
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

        statesByReciterID[reciter.id] = DownloadState()
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

    /// Removes reciter folders that have some surahs but not the full 114-surah package (interrupted or failed download).
    /// Skips reciters that still have an active URLSession task or `isDownloading` state.
    func purgeIncompleteReciterDownloads() {
        session.getAllTasks { tasks in
            let busyReciterIDs = Set(
                tasks.compactMap { self.taskContext(for: $0)?.reciter.id }
            )
            DispatchQueue.main.async {
                for reciter in reciters {
                    if busyReciterIDs.contains(reciter.id) { continue }
                    if self.activeTasks[reciter.id] != nil { continue }
                    if self.statesByReciterID[reciter.id]?.isDownloading == true { continue }
                    let (count, _) = self.downloadedStats(for: reciter)
                    if count > 0 && count < 114 {
                        self.deleteDownloads(for: reciter)
                    }
                }
            }
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

        for surahNumber in 1...114 {
            let targetURL = localSurahFileURL(reciter: reciter, surahNumber: surahNumber)
            if fileManager.fileExists(atPath: targetURL.path) {
                continue
            }

            let remoteString = "\(reciter.surahLink)\(String(format: "%03d", surahNumber)).mp3"
            guard let remoteURL = URL(string: remoteString) else {
                finishWithError(for: reciter.id, message: "Invalid reciter link.")
                return
            }

            let task = session.downloadTask(with: remoteURL)
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
            return
        }

        finishSuccess(for: reciter)
    }

    private func taskDescription(for reciter: Reciter, surahNumber: Int) -> String {
        "\(reciter.id)|\(surahNumber)"
    }

    /// Resolves a task to its reciter/surah purely from the task's immutable `taskDescription`.
    /// Intentionally avoids any shared mutable cache so it is safe to call from the background
    /// URLSession delegate queue without racing the main-thread dictionary writers.
    private func taskContext(for task: URLSessionTask) -> (reciter: Reciter, surahNumber: Int)? {
        guard let description = task.taskDescription else { return nil }
        let parts = description.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2,
              let surahNumber = Int(parts[1]),
              let reciter = reciters.first(where: { $0.id == parts[0] }) else {
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
        do {
            let targetURL = localSurahFileURL(reciter: context.reciter, surahNumber: context.surahNumber)
            try installDownloadedFile(from: location, to: targetURL, reciter: context.reciter)
        } catch {
            finishWithError(for: context.reciter.id, message: error.localizedDescription)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let context = taskContext(for: task) else { return }
        DispatchQueue.main.async {
            self.activeTasks[context.reciter.id] = nil
        }

        if let nsError = error as NSError? {
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                finishCancellation(for: context.reciter.id)
            } else {
                finishWithError(for: context.reciter.id, message: nsError.localizedDescription)
            }
            return
        }

        refreshState(for: context.reciter)
        scheduleNextDownload(for: context.reciter)
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
