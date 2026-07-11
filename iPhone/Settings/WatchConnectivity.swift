import Foundation
import WatchConnectivity
import Combine
import WidgetKit

/// Two-way settings sync between iPhone and Apple Watch.
///
/// Designed to avoid the failure modes the previous version had:
/// - **Never transmits a default.** A snapshot carries *only* settings this device has actually set, and the
///   receiver only writes keys that are present. So a payload can never reset an unmentioned (or freshly
///   installed) setting to its default — the cause of settings randomly flipping on/off or "all resetting."
/// - **Wall-clock recency + device tiebreak.** Each payload carries the real timestamp of the write plus
///   the originating device's rank (iPhone outranks the watch). A device applies an incoming payload only
///   if it is *newer* than everything it has already sent or applied — strictly later in time, or, only
///   when two writes share the exact same instant, made by the higher-ranked device. So the literally
///   newest edit always wins and iPhone wins ties, instead of a logical counter letting a stale-but-busier
///   device clobber a newer one (which looked like settings randomly "resetting").
/// - **Echo suppression.** After applying a remote snapshot we remember its serialized form, so the local
///   change it triggers doesn't get sent straight back.
/// - **Reliable channel.** Uses `updateApplicationContext` (always delivered, latest-state-wins) plus an
///   immediate `sendMessage` when reachable; duplicates are harmless because of the recency check.
///
/// All sync bookkeeping is read and mutated only on the main queue, so the WCSession delegate callbacks
/// (which arrive on a background queue) and the debounced sender never race.
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    private let session = WCSession.default
    private var cancellables = Set<AnyCancellable>()

    /// Local persistent store (per-device; app groups don't sync across devices). Persisting the sync
    /// bookkeeping is what prevents a stale `applicationContext` from being re-applied over a newer local
    /// change on relaunch — the "change a setting, reopen, it reverts" bug.
    private let store: UserDefaults
    private static let timestampKey = "watchSync.knownTimestamp"
    private static let rankKey = "watchSync.knownRank"
    private static let lastSyncedKey = "watchSync.lastSyncedSettingsData"

    /// How far ahead of our own clock an incoming timestamp may be before we treat it as a bogus
    /// (mis-set) peer clock and ignore it. Paired devices stay within seconds of each other; a full hour
    /// of slack never trips in practice but stops a wildly-wrong clock from pinning sync into the future
    /// and freezing out our legitimately-newer edits.
    private static let maxClockSkew: TimeInterval = 60 * 60

    /// Serialized form of the settings dict we last sent or applied — used to skip no-op/echo sends.
    private var lastSyncedSettingsData: Data {
        didSet { store.set(lastSyncedSettingsData, forKey: Self.lastSyncedKey) }
    }
    /// Wall-clock recency (seconds since 1970) of the newest write we've sent or applied, with the
    /// originating device's rank as the tiebreak. Together they resolve conflicts: the literally newest
    /// write wins, and iPhone outranks the watch only when two writes share the exact same timestamp.
    /// Persisted so a relaunch doesn't forget and re-accept an already-superseded payload.
    ///
    /// (Kept as a Double rather than packed into one Int because `Int` is 32-bit on some watchOS targets,
    /// where a millisecond timestamp would overflow.)
    private var knownTimestamp: Double {
        didSet { store.set(knownTimestamp, forKey: Self.timestampKey) }
    }
    private var knownRank: Int {
        didSet { store.set(knownRank, forKey: Self.rankKey) }
    }

    #if os(iOS)
    private let deviceRank = 1   // iPhone wins ties
    #else
    private let deviceRank = 0
    #endif

    private override init() {
        // Let `Settings` run its startup migrations first. One of them clears the sync digest to force a
        // re-push; snapshotting the digest before that runs would resurrect the stale value.
        _ = Settings.shared.isReadyForUI

        let store = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName) ?? .standard
        self.store = store
        self.knownTimestamp = store.double(forKey: Self.timestampKey)
        self.knownRank = store.integer(forKey: Self.rankKey)
        self.lastSyncedSettingsData = store.data(forKey: Self.lastSyncedKey) ?? Data()
        super.init()
        guard WCSession.isSupported() else { return }

        session.delegate = self
        session.activate()

        // Push a fresh full snapshot shortly after any settings change (debounced to batch rapid edits).
        Settings.shared.objectWillChange
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.sendSnapshotIfChanged() }
            .store(in: &cancellables)
    }

    // MARK: - Sending

    /// Sends any pending local change immediately, bypassing the debounce. Call when the app is about to be
    /// backgrounded so a just-made change isn't lost if the app is suspended before the debounce fires.
    @MainActor func flushPendingSync() {
        sendSnapshotIfChanged()
    }

    private func sendSnapshotIfChanged() {
        guard session.activationState == .activated else { return }

        let snapshot = Settings.shared.watchSyncSnapshot()
        guard let data = try? JSONSerialization.data(withJSONObject: snapshot, options: [.sortedKeys]) else { return }
        guard data != lastSyncedSettingsData else { return }   // no real change, or an echo of what we just applied
        lastSyncedSettingsData = data

        // Stamp the write with the real wall clock so the newest edit always wins. If the clock hasn't
        // advanced past our last stamp (rapid successive edits, or a backward clock correction), nudge just
        // past it so this brand-new change is still strictly newer than anything we've already sent. The
        // rank tiebreak only matters when two devices write at the exact same instant.
        var ts = Date().timeIntervalSince1970
        if ts <= knownTimestamp { ts = knownTimestamp.nextUp }
        knownTimestamp = ts
        knownRank = deviceRank

        let payload: [String: Any] = ["timestamp": ts, "rank": deviceRank, "settings": snapshot]

        do { try session.updateApplicationContext(payload) }
        catch { logger.debug("WC updateApplicationContext error: \(error)") }

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { err in
                logger.debug("WC sendMessage error: \(err.localizedDescription)")
            }
        }
    }

    // MARK: - Receiving

    private func receive(_ payload: [String: Any]) {
        guard let ts = payload["timestamp"] as? Double,
              let rank = payload["rank"] as? Int,
              let settings = payload["settings"] as? [String: Any] else { return }
        // Ignore a timestamp absurdly far in our future — a peer with a badly mis-set clock — so it can't
        // pin our sync ahead and freeze out our own legitimately-newer edits.
        guard ts <= Date().timeIntervalSince1970 + Self.maxClockSkew else { return }
        // Accept only writes newer than anything we've sent or applied: a strictly later wall-clock time,
        // or — only as a tiebreak for the exact same instant — a higher-ranked device (iPhone > watch).
        let isNewer = ts > knownTimestamp || (ts == knownTimestamp && rank > knownRank)
        guard isNewer else { return }
        knownTimestamp = ts
        knownRank = rank

        // Remember the applied content so the change it triggers locally isn't echoed back.
        if let data = try? JSONSerialization.data(withJSONObject: settings, options: [.sortedKeys]) {
            lastSyncedSettingsData = data
        }

        Task { @MainActor in
            Settings.shared.applyWatchSyncSnapshot(settings)
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error { logger.debug("WC activation failed: \(error)") }
        logger.debug("WC activation → \(activationState.rawValue)")

        // Apply any context that arrived while we were inactive (rejected if not strictly newer than what
        // we already know), then push any local change that wasn't sent before — between them, the latest
        // value always wins and both devices converge regardless of who was open when. Hop to main first:
        // this delegate runs on a background queue, and all sync bookkeeping must be touched only there.
        if activationState == .activated {
            let pending = session.receivedApplicationContext
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if !pending.isEmpty { self.receive(pending) }
                self.sendSnapshotIfChanged()
            }
        }

        #if os(watchOS)
        // Now that we know whether the iPhone app is installed, (re)schedule prayer notifications
        // on the watch if it needs to handle them itself.
        if activationState == .activated {
            Task { @MainActor in
                Settings.shared.fetchPrayerTimes()
            }
        }
        #endif
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.receive(message) }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.receive(applicationContext) }
    }
}

// MARK: - Settings snapshot for Watch ⇄ iPhone sync
//
// Lives with the WatchConnectivity code (its only caller) rather than in SettingsAdhan, because the synced
// set is cross-cutting — appearance + prayer/adhan + Quran + tajweed + sharing — not Adhan-specific.
extension Settings {

    /// `@AppStorage` (UserDefaults.standard) keys that are safe to mirror between iPhone and Watch.
    /// Deliberately excludes device-sensed / transient / large state (location, prayer caches, auto-detected
    /// calculation, reading position, day-specific flags) so syncing can never clobber per-device data.
    static let watchSyncedAppStorageKeys: [String] = [
        // Appearance & general
        "colorSchemeString", "defaultView", "hapticOn",
        // Prayer / notifications
        "calculationAutomatic", "travelAutomatic", "switchHijriDateAtMaghrib", "dateNotifications",
        "naggingMode", "naggingStartOffset", "adhanNotificationSound", "showPrayerInfo",
        "shortAdhanFajr", "shortAdhanDhuhr", "shortAdhanAsr", "shortAdhanMaghrib", "shortAdhanIsha",
        "adhanSoundFajr", "adhanSoundDhuhr", "adhanSoundAsr", "adhanSoundMaghrib", "adhanSoundIsha",
        "notificationFajr", "notificationSunrise", "notificationDhuhr", "notificationAsr",
        "notificationMaghrib", "notificationIsha", "notificationDuha", "notificationIslamicMidnight",
        "notificationLastThird", "showDuha", "showIslamicMidnight", "showLastThird",
        "naggingFajr", "naggingSunrise", "naggingDhuhr", "naggingAsr", "naggingMaghrib", "naggingIsha",
        "naggingDuha", "naggingIslamicMidnight", "naggingLastThird",
        "preNotificationFajr", "preNotificationSunrise", "preNotificationDhuhr", "preNotificationAsr",
        "preNotificationMaghrib", "preNotificationIsha", "preNotificationDuha",
        "preNotificationIslamicMidnight", "preNotificationLastThird",
        "offsetFajr", "offsetSunrise", "offsetDhuhr", "offsetAsr", "offsetMaghrib", "offsetIsha",
        // Quran display
        "showArabicText", "showTransliteration", "showEnglishSaheeh", "showEnglishMustafa",
        "cleanArabicText", "removeArabicDots", "beginnerMode", "highlightAllahNames",
        "useFontArabic", "THEfontArabic", "fontArabicSize", "englishFontSize",
        "showTajweedColors", "reciter", "reciterId", "reciteType", "displayQiraah",
        "showOtherQiraatReciters", "qiraatComparisonMode", "ignoreSilentLettersInQuranSearch",
        "quranSummaryMode", "quranGridMode", "quranPageMode", "showFullSurahRow", "showMuqattaatHelper",
        "showPageJuzDividers", "searchForSurahs", "showBookmarks", "showFavorites",
        "saveLastReadAyah", "saveLastListenedSurah", "saveLastListenedAyah", "showAyahOfTheDay",
        // Tajweed categories
        "showTajweedTafkhim", "showTajweedQalqalah", "showTajweedLamShamsiyah", "showTajweedBareNuunMeem",
        "showTajweedIdghamBiGhunnahHeavy", "showTajweedGeneralGhunnah", "showTajweedIkhfaa",
        "showTajweedIqlab", "showTajweedIdghamBilaGhunnah", "showTajweedHamzatWaslSilent",
        "showTajweedSukoonJazm", "showTajweedMaddNatural2", "showTajweedMaddNaturalMiniature",
        "showTajweedMaddSeparated", "showTajweedMaddConnected", "showTajweedMaddNecessary6",
        "showTajweedMadd246",
        // Sharing / copy
        "shareShowAyahInformation", "shareShowSurahInformation",
        "copyAyahArabic", "copyAyahTransliteration", "copyAyahEnglishSaheeh", "copyAyahEnglishMustafa",
    ]

    /// A snapshot of the synced settings, containing **only keys this device has actually set**. A value
    /// the user never touched is absent from its backing store, so it is left out — and the receiver only
    /// writes keys that are present. That is the core safeguard against the "everything reset" bug: a
    /// freshly-installed (or never-configured) device cannot broadcast its defaults over an established
    /// peer, because it transmits nothing for settings it doesn't hold.
    func watchSyncSnapshot() -> [String: Any] {
        var dict: [String: Any] = [:]

        // Core @Published settings live in the app-group store. Transmit one only if it was *chosen* — the
        // mere existence of the key isn't enough, because a process that assigns a default creates the key
        // too. See `Settings.explicitlySetKeys`.
        let chosen = explicitlySetKeys
        if chosen.contains("accentColor") { dict["accentColor"] = accentColor.rawValue }
        if chosen.contains("customAccentColorHex") { dict["customAccentColorHex"] = customAccentColorHex }
        if chosen.contains("customBackgroundColorHex") { dict["customBackgroundColorHex"] = customBackgroundColorHex }
        if chosen.contains("prayerCalculation") { dict["prayerCalculation"] = prayerCalculation }
        if chosen.contains("hanafiMadhab") { dict["hanafiMadhab"] = hanafiMadhab }
        if chosen.contains("travelingMode") { dict["travelingMode"] = travelingMode }
        if chosen.contains("hijriOffset") { dict["hijriOffset"] = hijriOffset }
        if chosen.contains("highLatitudeRule") { dict["highLatitudeRule"] = highLatitudeRule }
        if chosen.contains("customPrayerNames") { dict["customPrayerNames"] = customPrayerNames }

        // @AppStorage settings — likewise only keys that have been explicitly written.
        let store = UserDefaults.standard
        for key in Self.watchSyncedAppStorageKeys where store.object(forKey: key) != nil {
            dict[key] = store.object(forKey: key)
        }
        return dict
    }

    /// Apply a snapshot received from the paired device. Only keys actually present are written, via the
    /// real setters (so persistence + side effects fire correctly), then a single recompute/refresh.
    @MainActor
    func applyWatchSyncSnapshot(_ dict: [String: Any]) {
        if let raw = dict["accentColor"] as? String, let c = AccentColor(rawValue: raw), c != accentColor { accentColor = c }
        if let v = dict["customAccentColorHex"] as? String, v != customAccentColorHex { customAccentColorHex = v }
        if let v = dict["customBackgroundColorHex"] as? String, v != customBackgroundColorHex { customBackgroundColorHex = v }
        if let v = dict["prayerCalculation"] as? String, v != prayerCalculation { prayerCalculation = v }
        if let v = dict["hanafiMadhab"] as? Bool, v != hanafiMadhab { hanafiMadhab = v }
        if let v = dict["travelingMode"] as? Bool, v != travelingMode { travelingMode = v }
        if let v = dict["hijriOffset"] as? Int, v != hijriOffset { hijriOffset = v }
        if let v = dict["highLatitudeRule"] as? String, v != highLatitudeRule { highLatitudeRule = v }
        if let v = dict["customPrayerNames"] as? [String: String], v != customPrayerNames { customPrayerNames = v }

        let store = UserDefaults.standard
        for key in Self.watchSyncedAppStorageKeys where dict[key] != nil {
            store.set(dict[key], forKey: key)
        }

        objectWillChange.send()
        updateDates()
        fetchPrayerTimes(force: true)
        #if os(iOS) || os(watchOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
