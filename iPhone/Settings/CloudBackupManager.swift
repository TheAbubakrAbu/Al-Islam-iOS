#if os(iOS)
import Foundation
import CloudKit
import Combine

/// The iCloud half of the backup (docs/iCloud Sync Guide.md, sections 4 and 8): profiles in the
/// user's private CloudKit database, one record each, and this device's claim on one of them.
///
/// The rules that matter, from the guide:
/// - **A device writes one profile, its own.** It never touches another without the user picking
///   it in a restore, and picking one always restores first and claims after (nothing in iCloud is
///   destroyed except by Delete).
/// - **A takeover is detected, not fought.** A save uses `.ifServerRecordUnchanged`; when the server
///   copy moved and its `ownerDeviceID` is not ours, another device took the profile over (a new
///   phone), and this one stops saving and says so, rather than the two overwriting each other.
/// - **Failures are a status line.** No iCloud account, no network, quota, taken over: all end up in
///   `status`, shown in Settings, never as a modal in the middle of reading.
/// - **Nothing is sent that did not change.** The snapshot's content digest is compared with the
///   last one saved; a background pass with nothing new costs no upload.
///
/// - **Everything is written down.** `history` keeps the last 30 events (a save and its size, a
///   skipped save, a restore, an export, a failure and why) on the device, for the History page.
///
/// Everything here is main-actor state; CloudKit calls hop off and come back.
@MainActor
final class CloudBackupManager: ObservableObject {
    static let shared = CloudBackupManager()

    // MARK: Constants

    nonisolated static let maxProfiles = 6
    nonisolated static let recordType = "Profile"
    nonisolated static let zoneName = "Profiles"
    /// Automatic saves: on leaving the foreground when something changed and the last save is
    /// older than this, and on coming to the foreground when it is older than `staleInterval`.
    static let backgroundInterval: TimeInterval = 5 * 60
    static let staleInterval: TimeInterval = 6 * 60 * 60

    enum Field {
        static let nickname = "nickname"
        static let deviceKind = "deviceKind"
        static let ownerDeviceID = "ownerDeviceID"
        static let updatedAt = "updatedAt"
        static let schemaVersion = "schemaVersion"
        static let appVersion = "appVersion"
        static let payload = "payload"
        static let payloadBytes = "payloadBytes"
        static let payloadDigest = "payloadDigest"
        static let summary = "summary"
        /// Everything but the payload: what a profile listing fetches.
        static let listed = [nickname, deviceKind, ownerDeviceID, updatedAt, schemaVersion, appVersion, payloadBytes, payloadDigest, summary]
    }

    // MARK: State this device keeps (device-only keys, `cloudBackup.` prefix)

    private enum Key {
        static let enabled = "cloudBackup.enabled"
        static let profileID = "cloudBackup.profileID"
        static let nickname = "cloudBackup.nickname"
        static let deviceID = "cloudBackup.deviceID"
        static let lastSavedAt = "cloudBackup.lastSavedAt"
        static let lastSavedDigest = "cloudBackup.lastSavedDigest"
        static let zoneReady = "cloudBackup.zoneReady"
        static let takenOver = "cloudBackup.takenOver"
        static let lastSavedBytes = "cloudBackup.lastSavedBytes"
        static let lastSavedAutomatically = "cloudBackup.lastSavedAutomatically"
        static let history = "cloudBackup.history"
    }

    /// This install, for the profile's `ownerDeviceID`. Made once; a reinstall is a new device,
    /// which is right: it would restore before claiming, like any other new device. A full erase
    /// mints a new one for the same reason (`forgetEverything`).
    private(set) var deviceID: String

    @Published private(set) var isEnabled: Bool
    @Published private(set) var profileID: String?
    @Published private(set) var nickname: String
    @Published private(set) var lastSavedAt: Date?
    /// The last upload's compressed size, and whether an automatic pass made it.
    @Published private(set) var lastSavedBytes: Int
    @Published private(set) var lastSavedAutomatically: Bool
    @Published private(set) var status: Status = .idle
    @Published private(set) var isBusy = false
    /// The profiles in the account as last listed (never the payloads).
    @Published private(set) var profiles: [ProfileSummary] = []
    @Published private(set) var accountAvailable: Bool?
    /// What happened, newest first (`Event`), kept on the device.
    @Published private(set) var history: [Event] = []

    enum Status: Equatable {
        case idle
        case saving
        case saved
        case noAccount
        case offline
        case quotaExceeded
        case takenOver
        case failed(String)

        /// The line under the switch in Settings.
        var line: String {
            switch self {
            case .idle: return ""
            case .saving: return "Backing up..."
            case .saved: return "Backed up"
            case .noAccount: return "Not backed up: sign in to iCloud in Settings"
            case .offline: return "Not backed up yet: no connection"
            case .quotaExceeded: return "Not backed up: iCloud storage is full"
            case .takenOver: return "Another device now backs up to this profile. Choose a profile to continue on this device."
            case .failed(let message): return "Not backed up: \(message)"
            }
        }
    }

    struct ProfileSummary: Identifiable, Equatable {
        let id: String
        let nickname: String
        let deviceKind: String
        let ownerDeviceID: String
        let updatedAt: Date
        let schemaVersion: Int
        let appVersion: String
        let payloadBytes: Int
        let summary: String

        var isNewerThanThisApp: Bool { schemaVersion > CloudSnapshot.currentSchemaVersion }
    }

    /// One line of the History page.
    struct Event: Identifiable, Codable, Equatable {
        enum Kind: String, Codable {
            case backedUp, unchanged, restored, exported, started, switched, renamed, stopped, deleted, failed, takenOver, erased
        }

        let at: Date
        let kind: Kind
        /// The line itself: "Backed up automatically, 5.6 KB".
        let line: String
        var id: String { "\(at.timeIntervalSince1970)-\(kind.rawValue)" }

        var systemImage: String {
            switch kind {
            case .backedUp: return "checkmark.icloud.fill"
            case .unchanged: return "icloud"
            case .restored: return "arrow.down.circle.fill"
            case .exported: return "square.and.arrow.up"
            case .started, .switched: return "icloud.and.arrow.up"
            case .renamed: return "pencil"
            case .stopped, .erased: return "icloud.slash"
            case .deleted: return "trash"
            case .failed: return "exclamationmark.icloud"
            case .takenOver: return "arrow.triangle.swap"
            }
        }

        var isProblem: Bool { kind == .failed || kind == .takenOver }
    }

    static let historyLimit = 30

    enum Failure: LocalizedError {
        case noAccount
        case offline
        case quotaExceeded
        case takenOver
        case profileLimit
        case notEnabled
        case notFound
        case other(String)

        var errorDescription: String? {
            switch self {
            case .noAccount: return "Sign in to iCloud in the Settings app to back up."
            case .offline: return "No connection. Try again when you are online."
            case .quotaExceeded: return "Your iCloud storage is full."
            case .takenOver: return "Another device now backs up to this profile."
            case .profileLimit: return "You already have \(CloudBackupManager.maxProfiles) profiles. Delete one to add another."
            case .notEnabled: return "iCloud Backup is off on this device."
            case .notFound: return "That profile is no longer in iCloud."
            case .other(let message): return message
            }
        }
    }

    // MARK: Setup

    private let defaults = UserDefaults.standard
    private var container: CKContainer { CKContainer.default() }
    private var database: CKDatabase { container.privateCloudDatabase }
    private var zoneID: CKRecordZone.ID { CKRecordZone.ID(zoneName: Self.zoneName, ownerName: CKCurrentUserDefaultName) }
    private var contentChangedSinceSave = false
    private var observers: [NSObjectProtocol] = []

    private init() {
        if let stored = defaults.string(forKey: Key.deviceID) {
            deviceID = stored
        } else {
            let fresh = UUID().uuidString
            defaults.set(fresh, forKey: Key.deviceID)
            deviceID = fresh
        }
        isEnabled = defaults.bool(forKey: Key.enabled)
        profileID = defaults.string(forKey: Key.profileID)
        nickname = defaults.string(forKey: Key.nickname) ?? ""
        let saved = defaults.double(forKey: Key.lastSavedAt)
        lastSavedAt = saved > 0 ? Date(timeIntervalSince1970: saved) : nil
        lastSavedBytes = defaults.integer(forKey: Key.lastSavedBytes)
        lastSavedAutomatically = defaults.bool(forKey: Key.lastSavedAutomatically)
        history = defaults.data(forKey: Key.history).flatMap { try? JSONDecoder().decode([Event].self, from: $0) } ?? []
        if defaults.bool(forKey: Key.takenOver) { status = .takenOver } else if lastSavedAt != nil { status = .saved }
        #if DEBUG
        // "-cloudFakeEnabled": this device already backs up to the first fake profile (in memory
        // only; nothing is written to the defaults, so the next launch is clean).
        if Self.fakeProfileCount != nil, ProcessInfo.processInfo.arguments.contains("-cloudFakeEnabled") {
            isEnabled = true
            profileID = "fake-0"
            nickname = "Abu's iPhone"
            lastSavedAt = Date().addingTimeInterval(-3_600 * 2)
            lastSavedBytes = 5_608
            lastSavedAutomatically = true
            status = .saved
            if history.isEmpty {
                let now = Date()
                history = [
                    Event(at: now.addingTimeInterval(-3_600 * 2), kind: .backedUp, line: "Backed up automatically, 5.6 KB"),
                    Event(at: now.addingTimeInterval(-3_600 * 9), kind: .unchanged, line: "Checked, nothing new since the last backup"),
                    Event(at: now.addingTimeInterval(-86_400), kind: .failed, line: "Backup failed: no connection"),
                    Event(at: now.addingTimeInterval(-86_400 * 3), kind: .backedUp, line: "Backed up with Back Up Now, 5.4 KB"),
                    Event(at: now.addingTimeInterval(-86_400 * 12), kind: .restored, line: "Restored \u{201C}Old iPhone 13\u{201D} with Merge"),
                    Event(at: now.addingTimeInterval(-86_400 * 12 - 60), kind: .started, line: "Started backing up as \u{201C}Abu's iPhone\u{201D}"),
                ]
            }
        }
        #endif
        ObjectPublishCounter.attach(self, label: "CloudBackupManager")

        // Any content store publishing is "something changed"; cheap, and it only arms a flag.
        observers.append(NotificationCenter.default.addObserver(
            forName: ActivityLog.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.contentChangedSinceSave = true } })
        observers.append(NotificationCenter.default.addObserver(
            forName: Settings.storedContentReplacedNotification, object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.contentChangedSinceSave = true } })
        // A full erase (posted on the main thread, delivered inside the post): the defaults domain
        // that held the claim is already gone; memory follows, before the erase's own reload lands.
        observers.append(NotificationCenter.default.addObserver(
            forName: Settings.contentErasedNotification, object: nil, queue: nil
        ) { [weak self] _ in MainActor.assumeIsolated { self?.forgetEverything() } })
    }

    /// Erase Everything: this device forgets its claim and starts over with a new id, exactly as a
    /// reinstall would. The profile stays in iCloud (deleting it is the page's Delete, on purpose).
    private func forgetEverything() {
        let wasEnabled = isEnabled
        let name = nickname
        isEnabled = false
        profileID = nil
        nickname = ""
        lastSavedAt = nil
        lastSavedBytes = 0
        lastSavedAutomatically = false
        status = .idle
        contentChangedSinceSave = false
        profiles = []
        history = []
        deviceID = UUID().uuidString
        defaults.set(deviceID, forKey: Key.deviceID)
        if wasEnabled {
            record(.erased, "Erased everything on this \(CloudDevice.kind); it no longer backs up to \u{201C}\(name)\u{201D}. The profile stays in iCloud.")
        }
    }

    // MARK: History

    /// Writes one line of the History page and keeps the last `historyLimit`.
    private func record(_ kind: Event.Kind, _ line: String) {
        history.insert(Event(at: Date(), kind: kind, line: line), at: 0)
        if history.count > Self.historyLimit { history.removeLast(history.count - Self.historyLimit) }
        if let data = try? JSONEncoder().encode(history) { defaults.set(data, forKey: Key.history) }
    }

    /// The History page's newest line, for the row that opens it.
    var latestEventLine: String? { history.first?.line }

    /// Whether the account can hold a backup right now. Cached on the object for the screens.
    @discardableResult
    func refreshAccountStatus() async -> Bool {
        #if DEBUG
        if Self.fakeProfileCount != nil {
            accountAvailable = true
            return true
        }
        #endif
        let available: Bool
        do {
            available = try await container.accountStatus() == .available
        } catch {
            available = false
        }
        accountAvailable = available
        if !available, isEnabled { status = .noAccount }
        return available
    }

    #if DEBUG
    /// "-cloudFakeAccount <n>": the simulator has no iCloud account, so the signed-in screens (the
    /// naming card, the profile picker, the Settings page's list) could never be seen headlessly.
    /// Pretends the account is there and lists n synthetic profiles (the first is "this device's"
    /// when "-cloudFakeEnabled" is also passed). A real save still goes to CloudKit and fails with
    /// the not-signed-in status line, which is itself worth a look.
    static let fakeProfileCount: Int? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-cloudFakeAccount"), arguments.indices.contains(index + 1) else { return nil }
        return Int(arguments[index + 1])
    }()

    private func fakeProfiles(_ count: Int) -> [ProfileSummary] {
        let seeds: [(String, String, Int, String)] = [
            ("Abu's iPhone", "iPhone", 3_600 * 2, "212 bookmarks, 431 prayer days, 14 journal entries, 9,120 dhikr"),
            ("Mama's iPad", "iPad", 86_400 * 3, "38 bookmarks, 802 prayer days"),
            ("Yusuf", "iPhone", 86_400 * 12, "5 bookmarks, 61 prayer days, 2 journal entries"),
            ("Old iPhone 13", "iPhone", 86_400 * 200, "97 bookmarks, 1,850 prayer days, 6,236 khatm ayahs"),
            ("Study iPad", "iPad", 86_400 * 40, "Settings only"),
            ("Mac", "Mac", 86_400 * 9, "12 bookmarks"),
        ]
        return seeds.prefix(max(0, min(count, seeds.count))).enumerated().map { index, seed in
            ProfileSummary(id: "fake-\(index)", nickname: seed.0, deviceKind: seed.1,
                           ownerDeviceID: index == 0 && ProcessInfo.processInfo.arguments.contains("-cloudFakeEnabled") ? deviceID : "other-\(index)",
                           updatedAt: Date().addingTimeInterval(-Double(seed.2)),
                           schemaVersion: index == 3 ? CloudSnapshot.currentSchemaVersion + 1 : CloudSnapshot.currentSchemaVersion,
                           appVersion: "4.6.5", payloadBytes: 5_608 + index * 40_000, summary: seed.3)
        }
    }
    #endif

    // MARK: Turning on: a new profile, or an existing one

    /// Starts a new profile with this device's content and claims it.
    func createProfile(nickname rawNickname: String) async throws {
        try await ensureZone()
        let existing = try await listProfiles()
        guard existing.count < Self.maxProfiles else { throw Failure.profileLimit }
        let name = Self.cleanNickname(rawNickname)
        let id = UUID().uuidString
        setClaim(profileID: id, nickname: name)
        do {
            try await save(force: true, creating: true, automatic: false)
        } catch {
            clearClaim()
            throw error
        }
        record(.started, "Started backing up as \u{201C}\(name)\u{201D}")
    }

    /// The backup behind a profile, downloaded and decoded but not applied: the restore sheet shows
    /// it against this device first (`ContentInventory`), then asks how.
    func download(_ profile: ProfileSummary) async throws -> CloudSnapshot {
        guard !profile.isNewerThanThisApp else { throw CloudSnapshot.Failure.newerSchema(profile.schemaVersion) }
        #if DEBUG
        if Self.fakeProfileCount != nil { return fakeSnapshot(for: profile) }
        #endif
        return try await downloadSnapshot(profileID: profile.id)
    }

    #if DEBUG
    /// A fake profile's "download": this device's own snapshot with the first profile's summary
    /// numbers planted in it (212 bookmarks, 14 journal entries, 9,120 dhikr), so the restore
    /// preview has two different columns to show. Never applied by the fake flows' screenshots.
    private func fakeSnapshot(for profile: ProfileSummary) -> CloudSnapshot {
        var snapshot = CloudSnapshot.capture(deviceID: profile.ownerDeviceID)
        snapshot.createdAt = profile.updatedAt
        snapshot.deviceKind = profile.deviceKind
        let bookmarks = (0..<212).map { ["surah": 2 + $0 % 100, "ayah": 1 + $0 % 40, "createdAt": 1_700_000_000 + $0] as [String: Any] }
        snapshot.defaults["bookmarkedAyahsData"] = CloudJSON.data(bookmarks)
        snapshot.defaults["tasbihLifetimeCount"] = 9_120
        let journal = (0..<14).map { ["id": "fake-\($0)", "title": "Entry \($0)", "updatedAt": 1_700_000_000 + $0] as [String: Any] }
        snapshot.files["journal.json"] = CloudJSON.data(journal)
        return snapshot
    }
    #endif

    /// Restores a downloaded profile onto this device. With `claim`, this device then writes the
    /// profile from now on (the old writer notices at its next save); without it, "bring that
    /// profile's things here" while this device keeps writing its own profile (or none).
    func restore(_ snapshot: CloudSnapshot, from profile: ProfileSummary, mode: CloudSnapshot.RestoreMode, claim: Bool) async throws {
        if claim { try await ensureZone() }
        snapshot.apply(mode)
        let how = mode == .replace ? "Replace" : "Merge"
        guard claim else {
            contentChangedSinceSave = true
            record(.restored, "Restored \u{201C}\(profile.nickname)\u{201D} with \(how)")
            return
        }
        setClaim(profileID: profile.id, nickname: profile.nickname)
        // Claim by writing: the record's owner becomes this device, with this device's content
        // (which, after the restore, includes the profile's). `force` because the digest we last
        // saved is not this profile's.
        try await save(force: true, creating: false, automatic: false, expectOwner: profile.ownerDeviceID)
        record(.switched, "Restored \u{201C}\(profile.nickname)\u{201D} with \(how) and switched to it")
    }

    /// Restores a backup file (`importFile`) onto this device. Never claims anything: a file has no
    /// profile behind it.
    func restore(file snapshot: CloudSnapshot, named name: String, mode: CloudSnapshot.RestoreMode) {
        snapshot.apply(mode)
        contentChangedSinceSave = true
        record(.restored, "Restored the file \u{201C}\(name)\u{201D} with \(mode == .replace ? "Replace" : "Merge")")
    }

    /// Stops backing up from this device. The profile stays in iCloud for a restore later.
    func disable() {
        let name = nickname
        clearClaim()
        status = .idle
        record(.stopped, "Stopped backing up to \u{201C}\(name)\u{201D} from this \(CloudDevice.kind)")
    }

    func rename(_ rawNickname: String) async throws {
        let name = Self.cleanNickname(rawNickname)
        let previous = nickname
        nickname = name
        defaults.set(name, forKey: Key.nickname)
        guard let profileID else { return }
        let record = try await fetchRecord(profileID: profileID, keys: Field.listed)
        record[Field.nickname] = name as NSString
        _ = try await modify(record, policy: .changedKeys)
        if let index = profiles.firstIndex(where: { $0.id == profileID }) {
            profiles[index] = summary(of: record) ?? profiles[index]
        }
        self.record(.renamed, "Renamed \u{201C}\(previous)\u{201D} to \u{201C}\(name)\u{201D}")
    }

    /// Deletes a profile from iCloud, for good. Deleting this device's own profile also turns the
    /// backup off here.
    func delete(_ profile: ProfileSummary) async throws {
        do {
            _ = try await database.deleteRecord(withID: CKRecord.ID(recordName: profile.id, zoneID: zoneID))
        } catch {
            throw Self.failure(from: error)
        }
        profiles.removeAll { $0.id == profile.id }
        let own = profile.id == profileID
        if own {
            clearClaim()
            status = .idle
        }
        record(.deleted, "Deleted \u{201C}\(profile.nickname)\u{201D} from iCloud" + (own ? "; this \(CloudDevice.kind) stopped backing up" : ""))
    }

    // MARK: The backup file

    /// This device's snapshot as a file in the temporary directory, for the share sheet.
    func exportFile() throws -> URL {
        let snapshot = CloudSnapshot.capture(deviceID: deviceID)
        let data = try snapshot.encoded()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(CloudSnapshot.fileName(), isDirectory: false)
        try data.write(to: url, options: .atomic)
        record(.exported, "Exported a backup file, \(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))")
        return url
    }

    /// A picked file that was not a backup: one history line, so "I tried to restore and nothing
    /// happened" has an answer.
    func noteRefusedFile(_ name: String, reason: String) {
        record(.failed, "Could not restore \u{201C}\(name)\u{201D}: \(reason)")
    }

    /// Reads a backup file the user picked. Security-scoped: the Files picker hands out URLs the
    /// app may read only between these two calls.
    nonisolated static func importFile(_ url: URL) throws -> (snapshot: CloudSnapshot, bytes: Int) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw Failure.other("The file could not be opened.")
        }
        return (try CloudSnapshot.decode(data), data.count)
    }

    // MARK: Saving

    /// The user's Back Up Now.
    func backUpNow() async throws {
        try await save(force: true, creating: false, automatic: false)
    }

    /// The automatic pass (`AppLifecycle`): silent, throttled, and skipped when nothing changed.
    func automaticSaveIfDue(reason: AutomaticReason) {
        guard isEnabled, profileID != nil, !isBusy, status != .takenOver else { return }
        let age = lastSavedAt.map { Date().timeIntervalSince($0) } ?? .greatestFiniteMagnitude
        switch reason {
        case .background:
            guard contentChangedSinceSave || lastSavedAt == nil, age > Self.backgroundInterval else { return }
        case .foreground:
            guard age > Self.staleInterval else { return }
        }
        Task { try? await save(force: false, creating: false, automatic: true) }
    }

    enum AutomaticReason { case background, foreground }

    /// One save. `force` uploads even when the digest matches (Back Up Now, a claim); otherwise an
    /// unchanged snapshot only refreshes the date locally. `expectOwner` is the owner we are
    /// deliberately taking over from (an adopt); any other foreign owner means WE were taken over.
    private func save(force: Bool, creating: Bool, automatic: Bool, expectOwner: String? = nil) async throws {
        guard isEnabled, let profileID else { throw Failure.notEnabled }
        guard !isBusy else { return }
        isBusy = true
        status = .saving
        defer { isBusy = false }

        do {
            guard await refreshAccountStatus() else { throw Failure.noAccount }
            try await ensureZone()

            let snapshot = CloudSnapshot.capture(deviceID: deviceID)
            let digest = snapshot.contentDigest
            if !force, digest == defaults.string(forKey: Key.lastSavedDigest) {
                markSaved(digest: digest, bytes: lastSavedBytes, automatic: automatic)
                record(.unchanged, "Checked, nothing new since the last backup")
                return
            }
            let payload = try snapshot.encoded()

            // The record as the server has it, so the owner can be checked and the change tag kept.
            let recordID = CKRecord.ID(recordName: profileID, zoneID: zoneID)
            let record: CKRecord
            if creating {
                record = CKRecord(recordType: Self.recordType, recordID: recordID)
            } else {
                do {
                    record = try await database.record(for: recordID)
                } catch let error as CKError where error.code == .unknownItem {
                    // Deleted from another device, or never made it: recreate under the same id.
                    record = CKRecord(recordType: Self.recordType, recordID: recordID)
                }
                if let owner = record[Field.ownerDeviceID] as? String, owner != deviceID, owner != expectOwner {
                    throw Failure.takenOver
                }
            }
            try fill(record, nickname: nickname, snapshot: snapshot, payload: payload, digest: digest)
            let saved = try await modify(record, policy: .ifServerRecordUnchanged)
            markSaved(digest: digest, bytes: payload.count, automatic: automatic)
            let size = ByteCountFormatter.string(fromByteCount: Int64(payload.count), countStyle: .file)
            self.record(.backedUp, automatic ? "Backed up automatically, \(size)" : "Backed up with Back Up Now, \(size)")
            if let summary = summary(of: saved) {
                if let index = profiles.firstIndex(where: { $0.id == summary.id }) { profiles[index] = summary } else { profiles.append(summary) }
            }
        } catch {
            let failure = Self.failure(from: error)
            status = Self.status(for: failure)
            if case .takenOver = failure {
                defaults.set(true, forKey: Key.takenOver)
                self.record(.takenOver, "Another device took over \u{201C}\(nickname)\u{201D}; this \(CloudDevice.kind) stopped saving to it")
            } else {
                self.record(.failed, "Backup failed: \(Self.shortReason(failure))")
            }
            throw failure
        }
    }

    private func markSaved(digest: String, bytes: Int, automatic: Bool) {
        let now = Date()
        lastSavedAt = now
        lastSavedBytes = bytes
        lastSavedAutomatically = automatic
        defaults.set(now.timeIntervalSince1970, forKey: Key.lastSavedAt)
        defaults.set(digest, forKey: Key.lastSavedDigest)
        defaults.set(bytes, forKey: Key.lastSavedBytes)
        defaults.set(automatic, forKey: Key.lastSavedAutomatically)
        defaults.set(false, forKey: Key.takenOver)
        contentChangedSinceSave = false
        status = .saved
    }

    /// A failure as a few words for a history line ("no connection", "iCloud storage is full").
    private static func shortReason(_ failure: Failure) -> String {
        switch failure {
        case .noAccount: return "not signed in to iCloud"
        case .offline: return "no connection"
        case .quotaExceeded: return "iCloud storage is full"
        case .takenOver: return "another device took the profile over"
        case .profileLimit: return "too many profiles"
        case .notEnabled: return "backup is off"
        case .notFound: return "the profile is no longer in iCloud"
        case .other(let message): return message
        }
    }

    // MARK: Listing and fetching

    /// Every profile in the account, newest first, without payloads. Also refreshes `profiles`.
    @discardableResult
    func listProfiles() async throws -> [ProfileSummary] {
        guard await refreshAccountStatus() else { throw Failure.noAccount }
        #if DEBUG
        if let count = Self.fakeProfileCount {
            profiles = fakeProfiles(count)
            return profiles
        }
        #endif
        try await ensureZone()
        var found: [ProfileSummary] = []
        var token: CKServerChangeToken?
        do {
            repeat {
                let page = try await database.recordZoneChanges(inZoneWith: zoneID, since: token, desiredKeys: Field.listed)
                for (_, result) in page.modificationResultsByID {
                    if case .success(let modification) = result, let summary = summary(of: modification.record) {
                        found.append(summary)
                    }
                }
                token = page.changeToken
                if !page.moreComing { break }
            } while true
        } catch {
            throw Self.failure(from: error)
        }
        found.sort { $0.updatedAt > $1.updatedAt }
        profiles = found
        return found
    }

    private func downloadSnapshot(profileID: String) async throws -> CloudSnapshot {
        let record = try await fetchRecord(profileID: profileID, keys: nil)
        guard let asset = record[Field.payload] as? CKAsset, let url = asset.fileURL,
              let data = try? Data(contentsOf: url) else { throw Failure.notFound }
        return try CloudSnapshot.decode(data)
    }

    private func fetchRecord(profileID: String, keys: [CKRecord.FieldKey]?) async throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: profileID, zoneID: zoneID)
        do {
            if let keys {
                let results = try await database.records(for: [recordID], desiredKeys: keys)
                guard let result = results[recordID] else { throw Failure.notFound }
                return try result.get()
            }
            return try await database.record(for: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            throw Failure.notFound
        } catch {
            throw Self.failure(from: error)
        }
    }

    private func modify(_ record: CKRecord, policy: CKModifyRecordsOperation.RecordSavePolicy) async throws -> CKRecord {
        do {
            let result = try await database.modifyRecords(saving: [record], deleting: [], savePolicy: policy, atomically: true)
            guard let saved = result.saveResults[record.recordID] else { throw Failure.other("iCloud returned no record.") }
            return try saved.get()
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Someone else wrote this profile since we read it. Ours if the owner is still us (a
            // second save racing the first); otherwise a takeover.
            if let server = error.serverRecord, (server[Field.ownerDeviceID] as? String) == deviceID {
                for key in record.allKeys() { server[key] = record[key] }
                return try await modify(server, policy: .ifServerRecordUnchanged)
            }
            throw Failure.takenOver
        } catch {
            throw Self.failure(from: error)
        }
    }

    /// The custom zone, made once per account. Remembered locally; an account switch (the zone
    /// gone) surfaces as `.zoneNotFound` on the next call and the flag is cleared.
    private func ensureZone() async throws {
        if defaults.bool(forKey: Key.zoneReady) { return }
        do {
            _ = try await database.save(CKRecordZone(zoneID: zoneID))
            defaults.set(true, forKey: Key.zoneReady)
        } catch {
            throw Self.failure(from: error)
        }
    }

    // MARK: Pieces

    private func fill(_ record: CKRecord, nickname: String, snapshot: CloudSnapshot, payload: Data, digest: String) throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("profile-\(UUID().uuidString).aib")
        try payload.write(to: url, options: .atomic)
        record[Field.nickname] = nickname as NSString
        record[Field.deviceKind] = snapshot.deviceKind as NSString
        record[Field.ownerDeviceID] = deviceID as NSString
        record[Field.updatedAt] = snapshot.createdAt as NSDate
        record[Field.schemaVersion] = NSNumber(value: snapshot.schemaVersion)
        record[Field.appVersion] = snapshot.appVersion as NSString
        record[Field.payload] = CKAsset(fileURL: url)
        record[Field.payloadBytes] = NSNumber(value: payload.count)
        record[Field.payloadDigest] = digest as NSString
        record[Field.summary] = snapshot.summaryLine as NSString
    }

    private func summary(of record: CKRecord) -> ProfileSummary? {
        guard record.recordType == Self.recordType else { return nil }
        return ProfileSummary(
            id: record.recordID.recordName,
            nickname: record[Field.nickname] as? String ?? "Profile",
            deviceKind: record[Field.deviceKind] as? String ?? "",
            ownerDeviceID: record[Field.ownerDeviceID] as? String ?? "",
            updatedAt: record[Field.updatedAt] as? Date ?? record.modificationDate ?? Date(timeIntervalSince1970: 0),
            schemaVersion: (record[Field.schemaVersion] as? NSNumber)?.intValue ?? 1,
            appVersion: record[Field.appVersion] as? String ?? "",
            payloadBytes: (record[Field.payloadBytes] as? NSNumber)?.intValue ?? 0,
            summary: record[Field.summary] as? String ?? ""
        )
    }

    private func setClaim(profileID id: String, nickname name: String) {
        isEnabled = true
        profileID = id
        nickname = name
        defaults.set(true, forKey: Key.enabled)
        defaults.set(id, forKey: Key.profileID)
        defaults.set(name, forKey: Key.nickname)
        defaults.set(false, forKey: Key.takenOver)
        defaults.removeObject(forKey: Key.lastSavedDigest)
    }

    private func clearClaim() {
        isEnabled = false
        profileID = nil
        lastSavedAt = nil
        lastSavedBytes = 0
        lastSavedAutomatically = false
        for key in [Key.enabled, Key.profileID, Key.lastSavedAt, Key.lastSavedDigest, Key.takenOver, Key.lastSavedBytes, Key.lastSavedAutomatically] {
            defaults.removeObject(forKey: key)
        }
    }

    static func cleanNickname(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? CloudDevice.suggestedNickname : trimmed
        return String(name.prefix(40))
    }

    /// Is this device's own profile: the one it writes.
    func isOwn(_ profile: ProfileSummary) -> Bool { profile.id == profileID }

    private static func failure(from error: Error) -> Failure {
        if let failure = error as? Failure { return failure }
        if let failure = error as? CloudSnapshot.Failure { return .other(failure.localizedDescription) }
        guard let ck = error as? CKError else { return .other(error.localizedDescription) }
        switch ck.code {
        case .notAuthenticated, .accountTemporarilyUnavailable: return .noAccount
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy: return .offline
        case .quotaExceeded: return .quotaExceeded
        case .unknownItem: return .notFound
        case .zoneNotFound, .userDeletedZone:
            UserDefaults.standard.set(false, forKey: Key.zoneReady)
            return .offline
        default: return .other(ck.localizedDescription)
        }
    }

    private static func status(for failure: Failure) -> Status {
        switch failure {
        case .noAccount: return .noAccount
        case .offline: return .offline
        case .quotaExceeded: return .quotaExceeded
        case .takenOver: return .takenOver
        case .profileLimit, .notEnabled, .notFound, .other: return .failed(failure.localizedDescription)
        }
    }
}
#endif
