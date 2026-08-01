import Foundation
import WatchConnectivity
import Combine
import WidgetKit

/// Two-way settings sync between iPhone and Apple Watch.
///
/// The protocol is a **per-key last-writer-wins merge** (an LWW map). Every synced setting travels with
/// its own `(timestamp, deviceRank)` stamp, and a device applies an incoming key only when that key's
/// stamp is newer than the one it already holds (strictly later wall-clock time; the higher-ranked
/// device — iPhone — wins only an exact-same-instant tie).
///
/// Why per-key and not whole-snapshot: the previous protocol stamped the *entire* snapshot with one
/// timestamp per send. Any send from a device holding one stale value re-asserted that stale value as
/// "just written," so a watch that hadn't yet received a phone edit could revert it merely by syncing an
/// unrelated change — the "Hanafi calculation keeps reverting" bug — and the phone's still-queued edit
/// then looked old to the watch and was rejected, which presented as sync being broken entirely. With
/// per-key stamps a device only fresh-stamps keys whose value it actually changed, so a stale peer loses
/// exactly the keys it is stale on and nothing else.
///
/// Other invariants, kept from (or hardened over) the previous design:
/// - **Never transmits a default.** A payload carries only settings this device actually holds (see
///   `Settings.watchSyncSnapshot()`), and the receiver only writes keys that are present, so a freshly
///   installed device cannot reset its peer.
/// - **Bookkeeping commits only after the apply.** Stamps and echo-guard state for received keys are
///   persisted in the same main-actor pass that applies them, so a suspension can never leave a device
///   believing it holds a value it never wrote (and then re-broadcasting its stale one).
/// - **Echo suppression by convergence.** `lastPushedFields` records what the reliable channel already
///   holds; after applying a peer's keys we mark them pushed, so the local didSets an apply fires never
///   echo identical state back. Each side compares only against its *own* payload form, so structural
///   asymmetries (the watch never sends `travelingMode`) can't cause endless re-send ping-pong.
/// - **Reliable channel.** `updateApplicationContext` (always delivered, latest-state-wins — safe here
///   because every payload carries the full field map) plus an immediate `sendMessage` fast path when
///   reachable; duplicates are harmless because of the per-key recency check.
/// - **Clock-skew fencing.** A field stamped absurdly far in our future (mis-set peer clock) is skipped,
///   and local stamps are derived from `max(now, held stamp.nextUp)` with a clamped seed, so timestamps
///   can never run away into the future and freeze out legitimate edits.
/// - **Legacy interop.** A payload from a peer still on the whole-snapshot build (its single timestamp
///   applied to every key) merges through the same per-key gate, seeded from the old protocol's persisted
///   recency watermark — so a stale legacy peer is rejected exactly as it was before. Outgoing payloads
///   still mirror the legacy fields so an un-updated peer keeps receiving.
///
/// All sync bookkeeping is read and mutated only on the main thread (main queue hops + `@MainActor`
/// tasks), so the WCSession delegate callbacks (background queue) and the debounced sender never race.
final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    private let session = WCSession.default
    private var cancellables = Set<AnyCancellable>()

    /// Local persistent store (per-device; app groups don't sync across devices). Persisting the sync
    /// bookkeeping is what prevents a stale `receivedApplicationContext` from being re-applied over a
    /// newer local change on relaunch - the "change a setting, reopen, it reverts" bug.
    private let store: UserDefaults
    private static let fieldsKey = "watchSync.fieldStamps"
    private static let pushedKey = "watchSync.pushedFieldStamps"
    // Previous protocol's persisted watermark - read once to seed the per-key stamps, so a not-yet-updated
    // peer's whole-snapshot payloads face the same recency gate they always did.
    private static let legacyTimestampKey = "watchSync.knownTimestamp"
    private static let legacyRankKey = "watchSync.knownRank"

    /// How far ahead of our own clock an incoming stamp may be before we treat it as a bogus (mis-set)
    /// peer clock and skip that field. Paired devices stay within seconds of each other; a full hour of
    /// slack never trips in practice but stops a wildly-wrong clock from pinning a key into the future.
    private static let maxClockSkew: TimeInterval = 60 * 60

    /// One synced setting's state: the newest write we know of for that key.
    /// `t` is wall-clock seconds since 1970; `r` is the originating device's rank (iPhone 1, watch 0),
    /// used only to break an exact-same-instant tie. Kept as a Double because `Int` is 32-bit on some
    /// watchOS targets, where a millisecond timestamp would overflow.
    private struct Field {
        var t: Double
        var r: Int
        var v: Any

        var plist: [String: Any] { ["t": t, "r": r, "v": v] }

        init(t: Double, r: Int, v: Any) {
            self.t = t
            self.r = r
            self.v = v
        }

        init?(plist: Any) {
            guard let dict = plist as? [String: Any],
                  let t = (dict["t"] as? NSNumber)?.doubleValue, t.isFinite,
                  let r = (dict["r"] as? NSNumber)?.intValue,
                  let v = dict["v"] else { return nil }
            self.t = t
            self.r = r
            self.v = v
        }

        func isNewer(than other: Field?) -> Bool {
            guard let other else { return true }
            return t > other.t || (t == other.t && r > other.r)
        }
    }

    /// The newest stamp+value we know for each synced key, whether it originated here or on the peer.
    /// This is the merge state of the LWW map; persisted so a relaunch can't forget and re-accept an
    /// already-superseded payload, or fresh-stamp a value the peer legitimately overwrote.
    private var fields: [String: Field]

    /// What the reliable channel (or a converged apply) already holds, in *this device's own payload
    /// form*. The no-op guard compares the next candidate payload against this - never against the
    /// peer's differently-shaped payload - which is what keeps structural asymmetries from re-triggering
    /// sends forever.
    private var lastPushedFields: [String: Field]

    #if os(iOS)
    private let deviceRank = 1   // iPhone wins exact-tie stamps
    #else
    private let deviceRank = 0
    #endif

    private override init() {
        // Let `Settings` run its startup migrations first; the seed snapshot below must see their results.
        _ = Settings.shared.isReadyForUI

        let store = UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName) ?? .standard
        self.store = store

        if let data = store.data(forKey: Self.fieldsKey), let saved = Self.decodeFields(data) {
            self.fields = saved
            self.lastPushedFields = store.data(forKey: Self.pushedKey).flatMap(Self.decodeFields) ?? [:]
        } else {
            // First run on the per-key protocol (fresh install, or migration from the whole-snapshot
            // build): stamp every currently-held setting at the old protocol's recency watermark - clamped
            // to now so a watermark a past bug pinned into the future can't poison every seed - falling
            // back to 0 with this device's rank, so any real edit made after this moment outranks the seed
            // and the iPhone's rank resolves a fresh-install seed-vs-seed tie.
            let legacyT = min(store.double(forKey: Self.legacyTimestampKey), Date().timeIntervalSince1970)
            let seedT = max(legacyT, 0)
            #if os(iOS)
            let seedR = seedT > 0 ? store.integer(forKey: Self.legacyRankKey) : 1
            #else
            let seedR = seedT > 0 ? store.integer(forKey: Self.legacyRankKey) : 0
            #endif
            var seeded: [String: Field] = [:]
            for (key, value) in Settings.shared.watchSyncSnapshot() {
                seeded[key] = Field(t: seedT, r: seedR, v: value)
            }
            self.fields = seeded
            // Empty on purpose: the first activation compares the candidate payload against nothing and
            // pushes the full field map, so a peer that has never heard from this build gets everything.
            self.lastPushedFields = [:]
        }

        super.init()
        persistState()
        guard WCSession.isSupported() else { return }

        session.delegate = self
        session.activate()

        // Push any pending local change shortly after a settings edit (debounced to batch rapid edits).
        Settings.shared.objectWillChange
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.sendSnapshotIfChanged() }
            .store(in: &cancellables)
    }

    // MARK: - Persistence

    private func persistState() {
        store.set(Self.encodeFields(fields), forKey: Self.fieldsKey)
        store.set(Self.encodeFields(lastPushedFields), forKey: Self.pushedKey)
    }

    private static func encodeFields(_ map: [String: Field]) -> Data {
        let plist = map.mapValues { $0.plist }
        return (try? PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)) ?? Data()
    }

    private static func decodeFields(_ data: Data) -> [String: Field]? {
        guard !data.isEmpty,
              let raw = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any]
        else { return nil }
        var out: [String: Field] = [:]
        for (key, value) in raw {
            if let field = Field(plist: value) { out[key] = field }
        }
        return out
    }

    /// Plist-value equality (numbers, strings, bools, arrays, dicts - everything a snapshot can carry).
    private static func plistEqual(_ a: Any, _ b: Any) -> Bool {
        (a as? NSObject)?.isEqual(b) ?? false
    }

    private static func fieldMapsEqual(_ a: [String: Field], _ b: [String: Field]) -> Bool {
        guard a.count == b.count else { return false }
        for (key, fa) in a {
            guard let fb = b[key], fa.t == fb.t, fa.r == fb.r, plistEqual(fa.v, fb.v) else { return false }
        }
        return true
    }

    // MARK: - Sending

    /// Sends any pending local change immediately, bypassing the debounce. Call when the app is about to be
    /// backgrounded so a just-made change isn't lost if the app is suspended before the debounce fires.
    @MainActor func flushPendingSync() {
        sendSnapshotIfChanged()
    }

    /// Main thread only (all callers hop there). Fresh-stamps exactly the keys whose value changed since
    /// the last send/apply, then pushes the full field map if it differs from what the channel holds.
    private func sendSnapshotIfChanged() {
        guard session.activationState == .activated else { return }

        let snapshot = Settings.shared.watchSyncSnapshot()
        let now = Date().timeIntervalSince1970

        // A key whose value still matches the merge state keeps its existing stamp - possibly the peer's.
        // Only a genuinely new local value gets a fresh stamp, nudged past the held one if the clock
        // hasn't advanced (rapid successive edits, or a backward clock correction), so the new value is
        // strictly newer than anything either device has seen for that key.
        for (key, value) in snapshot {
            if let held = fields[key], Self.plistEqual(held.v, value) { continue }
            let base = fields[key]?.t ?? 0
            fields[key] = Field(t: max(now, base.nextUp), r: deviceRank, v: value)
        }

        // The payload carries only keys present in this device's snapshot: a key this device doesn't hold
        // (or deliberately excludes, like `travelingMode` on the watch) is "no opinion", never a delete.
        var candidate: [String: Field] = [:]
        for key in snapshot.keys {
            if let field = fields[key] { candidate[key] = field }
        }

        // Nothing to push and nothing to persist: a fresh stamp always makes the candidate differ from
        // what was last pushed, so reaching here means the stamping loop touched nothing - this is the
        // common no-op path (every debounced `objectWillChange`, e.g. a routine prayer fetch) and must
        // stay free of UserDefaults writes.
        guard !Self.fieldMapsEqual(candidate, lastPushedFields) else { return }

        var outFields: [String: Any] = [:]
        var legacySettings: [String: Any] = [:]
        var maxT = 0.0
        for (key, field) in candidate {
            outFields[key] = field.plist
            legacySettings[key] = field.v
            maxT = max(maxT, field.t)
        }
        let payload: [String: Any] = [
            "fields": outFields,
            // Legacy mirror so a peer still on the whole-snapshot build keeps receiving; it applies these
            // with its old single-timestamp gate.
            "timestamp": maxT, "rank": deviceRank, "settings": legacySettings,
        ]

        do {
            try session.updateApplicationContext(payload)
            // Recorded only AFTER the reliable channel accepted the payload; a failed write leaves the
            // candidate ≠ lastPushed, so the next trigger (settings change, background flush, reachability
            // change, activation) simply rebuilds and retries it.
            lastPushedFields = candidate
        } catch {
            logger.debug("WC updateApplicationContext error: \(error)")
        }
        persistState()

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { err in
                // No bookkeeping involvement: applicationContext (above) is the reliable channel and has
                // this payload queued; the message is only the fast path for a peer that is open right now.
                logger.debug("WC sendMessage error: \(err.localizedDescription)")
            }
        }
    }

    // MARK: - Receiving

    /// Main thread only (all callers hop there). Merges an incoming payload key-by-key, applies the keys
    /// that won their recency check, and only then - in the same main-actor pass - commits the stamps and
    /// echo-guard state, so an interrupted apply can never strand bookkeeping ahead of reality.
    private func processIncoming(_ payload: [String: Any], thenPushLocal: Bool = false) {
        var incoming: [String: Field] = [:]
        if let rawFields = payload["fields"] as? [String: Any] {
            for (key, raw) in rawFields {
                if let field = Field(plist: raw) { incoming[key] = field }
            }
        } else if let ts = (payload["timestamp"] as? NSNumber)?.doubleValue, ts.isFinite,
                  let rank = (payload["rank"] as? NSNumber)?.intValue,
                  let legacy = payload["settings"] as? [String: Any] {
            // Peer still on the whole-snapshot protocol: every key shares the payload's single stamp.
            for (key, value) in legacy { incoming[key] = Field(t: ts, r: rank, v: value) }
        }

        guard !incoming.isEmpty else {
            if thenPushLocal { sendSnapshotIfChanged() }
            return
        }

        Task { @MainActor in
            let horizon = Date().timeIntervalSince1970 + Self.maxClockSkew
            var accepted: [String: Field] = [:]
            var winners: [String: Any] = [:]
            for (key, field) in incoming {
                #if os(iOS)
                // `travelingMode` syncs ONE WAY (phone -> watch). Drop the key at the merge layer - not
                // even its stamp is adopted - so a peer that still sends it (an older watch build, or a
                // watch-side manual flip) can never influence the phone's state or its recency record.
                if key == "travelingMode" { continue }
                #endif
                // Skip a stamp absurdly far in our future (mis-set peer clock) so it can't pin this key
                // ahead and freeze out our own legitimately-newer edits.
                guard field.t <= horizon else { continue }
                guard field.isNewer(than: self.fields[key]) else { continue }
                accepted[key] = field
                winners[key] = field.v
            }

            if !accepted.isEmpty {
                Settings.shared.applyWatchSyncSnapshot(winners)

                // Commit bookkeeping from what actually stuck: value from our own post-apply snapshot
                // (so a key the apply rejected can't be resurrected under the peer's stamp), and the
                // echo guard only for keys our own payload form carries.
                let post = Settings.shared.watchSyncSnapshot()
                for (key, var field) in accepted {
                    if let actual = post[key] { field.v = actual }
                    self.fields[key] = field
                    if post[key] != nil { self.lastPushedFields[key] = field }
                }
                self.persistState()
            }

            if thenPushLocal { self.sendSnapshotIfChanged() }
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error { logger.debug("WC activation failed: \(error)") }
        logger.debug("WC activation → \(activationState.rawValue)")

        // Merge any context that arrived while we were inactive (each key rejected unless strictly newer
        // than what we already hold), then push any local change that wasn't sent before - between them,
        // the latest value of every individual setting wins and both devices converge regardless of who
        // was open when. Hop to main first: this delegate runs on a background queue, and all sync
        // bookkeeping must be touched only there.
        if activationState == .activated {
            let pending = session.receivedApplicationContext
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if pending.isEmpty {
                    self.sendSnapshotIfChanged()
                } else {
                    self.processIncoming(pending, thenPushLocal: true)
                }
            }
        }

        #if os(watchOS)
        // Now that we know whether the iPhone app is installed, (re)schedule prayer notifications on
        // the watch if it needs to handle them itself. `notification: true` is load-bearing: the launch
        // fetch usually ran (and was dropped by the ownership guard) BEFORE activation resolved, so by
        // now the prayers are fresh and a plain fetch would find nothing to do - `needsFetch == false`,
        // no scheduling pass, and a standalone watch got ZERO adhans until the next day-rollover fetch.
        // The forced notification pass also re-runs the paired-watch stale-schedule wipe.
        if activationState == .activated {
            Task { @MainActor in
                Settings.shared.fetchPrayerTimes(notification: true)
            }
        }
        #endif
    }

    /// The peer just came within reach (its app opened, Bluetooth reconnected). Everything already synced
    /// is a guarded no-op; what this actually delivers is the retry for a change whose reliable send failed
    /// (see the rollback in `sendSnapshotIfChanged`) - that change would otherwise wait for the next
    /// unrelated edit.
    func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        DispatchQueue.main.async { [weak self] in
            self?.sendSnapshotIfChanged()
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    /// A watch was paired or the watch app was just installed. That watch has never seen our settings, and
    /// the push guard can't know that - it only remembers what we last handed the session. Clearing it
    /// forces a full field-map push (with the *existing* stamps - nothing was edited, so nothing is
    /// re-stamped) so the new watch starts from the phone's config instead of its own defaults.
    func sessionWatchStateDidChange(_ session: WCSession) {
        guard session.isPaired, session.isWatchAppInstalled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.lastPushedFields = [:]
            // Persist the cleared guard NOW: if the send below can't run (session mid-reactivation for the
            // new watch) and the app dies before the next successful push, a stale persisted guard would
            // otherwise suppress the full push the new watch is owed.
            self.persistState()
            self.sendSnapshotIfChanged()
        }
    }
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.processIncoming(message) }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async { self.processIncoming(applicationContext) }
    }
}

// MARK: - Settings snapshot for Watch ⇄ iPhone sync
//
// Lives with the WatchConnectivity code (its only caller) rather than in SettingsAdhan, because the synced
// set is cross-cutting - appearance + prayer/adhan + Quran + tajweed + sharing - not Adhan-specific.
extension Settings {

    /// `@AppStorage` (UserDefaults.standard) keys that are safe to mirror between iPhone and Watch.
    /// Deliberately excludes device-sensed / transient / large state (location, prayer caches, auto-detected
    /// calculation, reading position, day-specific flags) so syncing can never clobber per-device data.
    // Grouped by app domain like Settings' sections - when copied into a companion app, delete the
    // domains it doesn't ship ([Shared] stays).
    static let watchSyncedAppStorageKeys: [String] = prayerOffsetKeys + [
        // [Shared] Appearance & general
        "colorSchemeString", "defaultView", "hapticOn",
        // [Al-Adhan] Prayer / notifications
        "calculationAutomatic", "switchHijriDateAtMaghrib", "dateNotifications",
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
        // [Al-Quran] Quran display
        "showArabicText", "showTransliteration", "showEnglishSaheeh", "showEnglishMustafa",
        "cleanArabicText", "removeArabicDots", "beginnerMode", "highlightAllahNames",
        "useFontArabic", "THEfontArabic", "fontArabicSize", "englishFontSize",
        "showTajweedColors", "reciter", "reciterId", "reciteType", "displayQiraah",
        "showOtherQiraatReciters", "qiraatComparisonMode",
        "quranSummaryMode", "quranGridMode", "quranPageMode", "mushafPageLanguage", "showFullSurahRow", "showMuqattaatHelper",
        "showPageJuzDividers", "searchForSurahs", "showBookmarks", "showFavorites",
        "saveLastReadAyah", "saveLastListenedSurah", "saveLastListenedAyah", "showAyahOfTheDay",
        // [Al-Quran] Tajweed categories
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
    /// the user never touched is absent from its backing store, so it is left out - and the receiver only
    /// writes keys that are present. That is the core safeguard against the "everything reset" bug: a
    /// freshly-installed (or never-configured) device cannot broadcast its defaults over an established
    /// peer, because it transmits nothing for settings it doesn't hold.
    func watchSyncSnapshot() -> [String: Any] {
        var dict: [String: Any] = [:]

        // Core @Published settings live in the app-group store. Transmit one only if it was *chosen* - the
        // mere existence of the key isn't enough, because a process that assigns a default creates the key
        // too. See `Settings.explicitlySetKeys`.
        let chosen = explicitlySetKeys
        if chosen.contains("accentColor") { dict["accentColor"] = accentColor.rawValue }
        if chosen.contains("customAccentColorHex") { dict["customAccentColorHex"] = customAccentColorHex }
        if chosen.contains("customBackgroundColorHex") { dict["customBackgroundColorHex"] = customBackgroundColorHex }
        if chosen.contains("hanafiMadhab") { dict["hanafiMadhab"] = hanafiMadhab }
        if chosen.contains("hijriOffset") { dict["hijriOffset"] = hijriOffset }
        if chosen.contains("highLatitudeRule") { dict["highLatitudeRule"] = highLatitudeRule }
        if chosen.contains("customPrayerNames") { dict["customPrayerNames"] = customPrayerNames }

        // `travelingMode` syncs ONE WAY: phone -> watch, value only. The phone is the sole authority -
        // it owns the home location and every auto-check. A watch-side flip stays on the watch (its
        // snapshot simply never carries the key), so the watch can never overwrite the phone's state.
        #if os(iOS)
        if chosen.contains("travelingMode") { dict["travelingMode"] = travelingMode }
        #endif
        // `prayerCalculation` keeps the gate: BOTH devices can derive it (it needs no home location), so the
        // two-deriving-devices loop is still real there. Only a manual choice (automatic OFF) travels.
        if chosen.contains("prayerCalculation"), !calculationAutomatic { dict["prayerCalculation"] = prayerCalculation }

        // @AppStorage settings - likewise only keys that have been explicitly written.
        let store = UserDefaults.standard
        for key in Self.watchSyncedAppStorageKeys where store.object(forKey: key) != nil {
            dict[key] = store.object(forKey: key)
        }
        return dict
    }

    /// Apply settings received from the paired device - the manager passes only the keys that won their
    /// per-key recency check. Only keys actually present are written, via the real setters (so persistence
    /// + side effects fire correctly), then a single recompute/refresh - and only if something actually
    /// changed. A payload that changes nothing must be a complete no-op: the force-fetch it used to run
    /// unconditionally rescheduled notifications and re-ran the travel/calculation auto-checks every time
    /// the watch was merely opened, which is where the phantom phone notifications came from.
    @MainActor
    func applyWatchSyncSnapshot(_ dict: [String: Any]) {
        var changed = false

        if let raw = dict["accentColor"] as? String, let c = AccentColor(rawValue: raw), c != accentColor { accentColor = c; changed = true }
        if let v = dict["customAccentColorHex"] as? String, v != customAccentColorHex { customAccentColorHex = v; changed = true }
        if let v = dict["customBackgroundColorHex"] as? String, v != customBackgroundColorHex { customBackgroundColorHex = v; changed = true }
        if let v = dict["hanafiMadhab"] as? Bool, v != hanafiMadhab { hanafiMadhab = v; changed = true }
        if let v = dict["hijriOffset"] as? Int, v != hijriOffset { hijriOffset = v; changed = true }
        if let v = dict["highLatitudeRule"] as? String, v != highLatitudeRule { highLatitudeRule = v; changed = true }
        if let v = dict["customPrayerNames"] as? [String: String], v != customPrayerNames { customPrayerNames = v; changed = true }

        // These two arrive only when the sender's automatic mode is off (see `watchSyncSnapshot`), so they
        // are the user's manual choice; the recompute below runs with auto-checks off so this device cannot
        // immediately overwrite them.
        if let v = dict["prayerCalculation"] as? String, v != prayerCalculation {
            prayerCalculation = v
            changed = true
        }
        // Phone -> watch only: the watch adopts the phone's travelingMode; the phone ignores the key
        // entirely (an older watch build may still send it - it must not win).
        #if os(watchOS)
        if let v = dict["travelingMode"] as? Bool, v != travelingMode {
            travelingMode = v
            changed = true
        }
        #endif

        let store = UserDefaults.standard
        for key in Self.watchSyncedAppStorageKeys {
            guard let incoming = dict[key] else { continue }
            let current = store.object(forKey: key)
            // NSObject equality covers every plist type the snapshot can carry (numbers, strings, arrays, dicts).
            if let current = current as? NSObject, let incoming = incoming as? NSObject, current == incoming { continue }
            store.set(incoming, forKey: key)
            changed = true
        }

        // switchHijriDateAtMaghrib lives in standard defaults but is mirrored into the App Group for the
        // widget/complication providers; the raw store.set above bypasses its didSet, so refresh the mirror.
        // On the watch this is the main write path for the key - the complication would never see it otherwise.
        UserDefaults(suiteName: AppIdentifiers.appGroupSuiteName)?
            .setValue(switchHijriDateAtMaghrib, forKey: "switchHijriDateAtMaghrib")

        // Same for the six manual prayer offsets: their didSet mirrors were bypassed by the raw
        // store.set above, and on the watch this sync IS the write path - without this the
        // complication recomputes prayer times with offsets of 0.
        for key in Settings.prayerOffsetKeys {
            mirrorOffsetToAppGroup(store.integer(forKey: key), key: key)
        }

        guard changed else { return }

        objectWillChange.send()
        updateDates()
        fetchPrayerTimes(force: true, runAutoChecks: false)
        #if os(iOS) || os(watchOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
