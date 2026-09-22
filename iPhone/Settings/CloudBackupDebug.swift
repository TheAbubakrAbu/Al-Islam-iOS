#if DEBUG
import Foundation

/// Headless checks for the iCloud backup's local half (docs/iCloud Sync Guide.md, section 10). None
/// of them touches iCloud: a snapshot is written to, and restored from, a file in Documents, which
/// is everything except the network hop. Results go to Documents too, because `NSLog` is not always
/// readable from `simctl` on this machine; read them with `simctl get_app_container <udid> <bid> data`.
///
///     -cloudKeyAudit                      every key in the LIVE defaults domain that no manifest
///                                         list names (catches keys built from strings, which
///                                         Scripts/check_cloud_manifest.py cannot see)
///     -cloudDumpSnapshot <name>           capture now, write <name>.aib and <name>.txt
///     -cloudRestoreFile <name> <mode>     restore <name>.aib, mode replace or merge
///     -cloudStoreProbe <tag>              what every store holds IN MEMORY, to cloud-probe-<tag>.txt;
///                                         with a restore in the same launch it also runs BEFORE it
///                                         (cloud-probe-<tag>-before.txt), and the pair is the
///                                         proof that the stores reloaded
///     -cloudDiffSnapshots <a> <b>         the keys and files that differ, to cloud-diff.txt
///     -cloudInventory                     What's Included as text (every category's count, the
///                                         settings count, the size), to cloud-inventory.txt
///     -cloudExportFile <name>             the Export a Backup File path, the file copied to
///                                         Documents/<name>.islambackup
///     -cloudImportFile <name> <mode>      the Restore from a File path on Documents/<name>.islambackup
///     -cloudResetProbe keep|erase         runs Reset All Settings (keeping content) or Erase
///                                         Everything, then writes the manager's state and the
///                                         persisted cloudBackup.* keys to cloud-reset-<which>.txt
///
/// They run in that order in one launch, two seconds after the reveal, so
/// `-cloudRestoreFile a replace -cloudStoreProbe after` restores and then probes.
enum CloudBackupDebug {
    @MainActor
    static func runLaunchArguments(storeProbe: (@MainActor () -> String)? = nil) async {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains(where: { $0.hasPrefix("-cloud") }) else { return }
        await AppReveal.waitUntilRevealed()
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        func values(after flag: String, count: Int) -> [String]? {
            guard let index = arguments.firstIndex(of: flag) else { return nil }
            let found = arguments.dropFirst(index + 1).prefix(count).filter { !$0.hasPrefix("-") }
            return found.count == count ? Array(found) : nil
        }

        let probeTag = values(after: "-cloudStoreProbe", count: 1)?.first
        let restoring = values(after: "-cloudRestoreFile", count: 2)

        if arguments.contains("-cloudKeyAudit") { keyAudit() }
        if arguments.contains("-cloudProbe") { write(await managerProbe(), to: "cloud-probe-manager.txt") }
        // Ahead of a restore the probe runs once BEFORE it as well. That records what memory held,
        // and, the part that matters, it creates every store: a store first touched after the
        // restore simply loads the new bytes and proves nothing about reloading.
        if let probeTag, restoring != nil {
            write(storeProbe?() ?? "no store probe installed", to: "cloud-probe-\(probeTag)-before.txt")
        }
        if arguments.contains("-cloudInventory") { write(inventory(), to: "cloud-inventory.txt") }
        if let name = values(after: "-cloudDumpSnapshot", count: 1)?.first { dump(named: name) }
        if let pair = restoring { restore(named: pair[0], mode: pair[1]) }
        if let name = values(after: "-cloudExportFile", count: 1)?.first { exportFile(named: name) }
        if let pair = values(after: "-cloudImportFile", count: 2) { importFile(named: pair[0], mode: pair[1]) }
        if let which = values(after: "-cloudResetProbe", count: 1)?.first { resetProbe(which) }
        if let tag = probeTag {
            // The reload lands inside the restore call; the achievements pass and the reminder
            // re-fit follow within two seconds, and the probe should see the settled state.
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            write(storeProbe?() ?? "no store probe installed", to: "cloud-probe-\(tag).txt")
        }
        if let pair = values(after: "-cloudDiffSnapshots", count: 2) { diff(pair[0], pair[1]) }
        NSLog("CLOUD DEBUG done")
    }

    // MARK: Checks

    /// The iCloud half's state: account, claim, last save, and the profiles it can list. The one
    /// check here that talks to CloudKit, so on the simulator it reports the missing account.
    @MainActor
    private static func managerProbe() async -> String {
        #if os(iOS)
        let manager = CloudBackupManager.shared
        var out = "deviceID \(manager.deviceID)\nenabled \(manager.isEnabled) profile \(manager.profileID ?? "none") nickname \"\(manager.nickname)\"\n"
        out += "lastSavedAt \(manager.lastSavedAt.map { "\($0)" } ?? "never") status \(manager.status)\n"
        let available = await manager.refreshAccountStatus()
        out += "account available \(available)\n"
        if available {
            do {
                for profile in try await manager.listProfiles() {
                    out += "profile \(profile.id) \"\(profile.nickname)\" \(profile.deviceKind) owner \(profile.ownerDeviceID) updated \(profile.updatedAt) \(profile.payloadBytes) bytes: \(profile.summary)\n"
                }
            } catch {
                out += "list failed: \(error.localizedDescription)\n"
            }
        }
        return out
        #else
        return "no CloudKit on this platform\n"
        #endif
    }

    /// The What's Included page as text, from the same `ContentInventory` the page builds.
    @MainActor
    private static func inventory() -> String {
        let inventory = ContentInventory.current()
        var out = "size \(inventory.bytes) bytes (\(inventory.sizeLine))\nsettings \(inventory.settingsChanged) changed\nsummary \(inventory.summaryLine)\n"
        for row in inventory.rows {
            out += "\(row.category.id): \(row.isEmpty ? "none" : row.measure.phrase)\n"
        }
        out += "categories cover \(ContentCategory.all.flatMap(\.keys).count) keys and \(ContentCategory.all.flatMap(\.files).count) files\n"
        out += "never included: \(ContentCategory.neverIncluded.map(\.title).joined(separator: "; "))\n"
        // The watch's view of the same tables: what the phone would send, and the app-group rows
        // among it (chosen ones only, like the backup's app-group capture).
        let watch = Settings.shared.watchSyncSnapshot()
        let groupKeys = Settings.appGroupPreferences.map(\.key).filter { watch[$0] != nil }.sorted()
        out += "watch snapshot \(watch.count) keys; app-group rows sent: \(groupKeys.joined(separator: ", "))\n"
        out += "phone-authoritative: \(Settings.phoneAuthoritativeSyncKeys.sorted().joined(separator: ", "))\n"
        out += "chosen app-group keys: \(Settings.shared.explicitlySetKeys.sorted().joined(separator: ", "))\n"
        out += "manifest app-group keys: \(CloudManifest.appGroupPreferenceKeys.joined(separator: ", ")); preference keys \(CloudManifest.preferenceKeys.count)\n"
        return out
    }

    #if os(iOS)
    @MainActor
    private static func exportFile(named name: String) {
        do {
            let url = try CloudBackupManager.shared.exportFile()
            guard let target = CloudSnapshot.documentURL("\(name).\(CloudSnapshot.fileExtension)") else { return }
            try? FileManager.default.removeItem(at: target)
            try FileManager.default.copyItem(at: url, to: target)
            let bytes = (try? Data(contentsOf: target))?.count ?? 0
            write("exported \(url.lastPathComponent) as \(target.lastPathComponent), \(bytes) bytes\nhistory: \(CloudBackupManager.shared.latestEventLine ?? "none")", to: "cloud-export.txt")
        } catch {
            write("export failed: \(error.localizedDescription)", to: "cloud-export.txt")
        }
    }

    @MainActor
    private static func importFile(named name: String, mode: String) {
        guard let url = CloudSnapshot.documentURL("\(name).\(CloudSnapshot.fileExtension)"),
              let restoreMode = CloudSnapshot.RestoreMode(rawValue: mode) else {
            write("unknown mode \(mode)", to: "cloud-import.txt")
            return
        }
        do {
            let imported = try CloudBackupManager.importFile(url)
            CloudBackupManager.shared.restore(file: imported.snapshot, named: url.lastPathComponent, mode: restoreMode)
            write("imported \(url.lastPathComponent) (\(mode)), \(imported.bytes) bytes, digest \(imported.snapshot.contentDigest)\nhistory: \(CloudBackupManager.shared.latestEventLine ?? "none")", to: "cloud-import.txt")
        } catch {
            write("import failed: \(error.localizedDescription)", to: "cloud-import.txt")
        }
    }

    /// Records who writes a key after a reset: a KVO observer on `UserDefaults` that appends the
    /// call stack of every change to cloud-reset-writers.txt ("-cloudResetWriters key1,key2").
    private final class WriterTrace: NSObject {
        static var shared: WriterTrace?
        let keys: [String]
        var log = ""
        init(keys: [String]) {
            self.keys = keys
            super.init()
            for key in keys { UserDefaults.standard.addObserver(self, forKeyPath: key, options: [.new], context: nil) }
        }
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            let value = change?[.newKey]
            log += "\n=== \(keyPath ?? "?") -> \(CloudBackupDebug.describe(value is NSNull ? nil : value)) on \(Thread.isMainThread ? "main" : "background")\n"
            log += Thread.callStackSymbols.prefix(28).joined(separator: "\n") + "\n"
        }
    }

    /// Reset All Settings, keeping content, or Erase Everything, then what the manager holds in
    /// memory and what survived on disk: the claim must survive a reset and vanish after an erase.
    @MainActor
    private static func resetProbe(_ which: String) {
        if let index = ProcessInfo.processInfo.arguments.firstIndex(of: "-cloudResetWriters"),
           ProcessInfo.processInfo.arguments.indices.contains(index + 1) {
            let trace = WriterTrace(keys: ProcessInfo.processInfo.arguments[index + 1].split(separator: ",").map(String.init))
            WriterTrace.shared = trace
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 4_000_000_000)
                write(trace.log.isEmpty ? "no writes observed" : trace.log, to: "cloud-reset-writers.txt")
            }
        }
        let manager = CloudBackupManager.shared
        let settings = Settings.shared
        func wrappers() -> String {
            let raw = UserDefaults.standard
            return "wrappers: bookmarks \(settings.bookmarkedAyahsData.count)/\(raw.data(forKey: "bookmarkedAyahsData")?.count ?? -1) tracker \(settings.prayerTrackerData.count)/\(raw.data(forKey: "prayerTrackerData")?.count ?? -1) colorScheme \(settings.colorSchemeString)/\(raw.string(forKey: "colorSchemeString") ?? "nil") offsetFajr \(settings.offsetFajr)/\(raw.integer(forKey: "offsetFajr"))\n"
        }
        let before = "before: enabled \(manager.isEnabled) profile \(manager.profileID ?? "none") device \(manager.deviceID) history \(manager.history.count)\n" + wrappers()
        switch which {
        case "keep": Settings.shared.resetAllSettings(keepingContent: true)
        case "erase": Settings.shared.resetAllSettings(keepingContent: false)
        default:
            write("unknown reset \(which)", to: "cloud-reset-\(which).txt")
            return
        }
        var out = before
        out += "after: enabled \(manager.isEnabled) profile \(manager.profileID ?? "none") device \(manager.deviceID) history \(manager.history.count) status \(manager.status)\n" + wrappers()
        // Where a surviving value lives: the search list, the app domain, each volatile domain,
        // the current-host domain, the global domain.
        if let bid = Bundle.main.bundleIdentifier {
            for key in ["bookmarkedAyahsData", "prayerTrackerData"] {
                let standard = UserDefaults.standard
                out += "where \(key): searchList \(describe(standard.dictionaryRepresentation()[key])) appDomain \(describe(standard.persistentDomain(forName: bid)?[key]))"
                for name in standard.volatileDomainNames { out += " volatile[\(name)] \(describe(standard.volatileDomain(forName: name)[key]))" }
                out += " currentHost \(describe(CFPreferencesCopyValue(key as CFString, bid as CFString, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)))"
                out += " anyHost \(describe(CFPreferencesCopyValue(key as CFString, bid as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)))"
                out += " global \(describe(CFPreferencesCopyValue(key as CFString, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)))\n"
            }
        }
        let domain = Bundle.main.bundleIdentifier.flatMap { UserDefaults.standard.persistentDomain(forName: $0) } ?? [:]
        for key in domain.keys.sorted() where key.hasPrefix("cloudBackup.") {
            out += "disk \(key) = \(describe(domain[key]))\n"
        }
        let content = CloudManifest.contentKeySet
        let survivingContent = domain.keys.filter { content.contains($0) }.sorted()
        out += "disk content keys \(survivingContent.count), preference keys \(domain.keys.filter { CloudManifest.preferenceKeySet.contains($0) }.count)\n"
        for key in survivingContent { out += "  content \(key) = \(describe(domain[key]))\n" }
        for name in CloudManifest.files {
            let size = CloudSnapshot.documentURL(name).flatMap { try? Data(contentsOf: $0) }?.count ?? 0
            out += "  file \(name) \(size) bytes\n"
        }
        if let group = Settings.shared.appGroupUserDefaults {
            out += "group offsetFajr \(group.integer(forKey: "offsetFajr")) accent \(group.string(forKey: "accentColor") ?? "nil")\n"
        }
        write(out, to: "cloud-reset-\(which).txt")
    }
    #else
    private static func exportFile(named name: String) {}
    private static func importFile(named name: String, mode: String) {}
    private static func resetProbe(_ which: String) {}
    #endif

    private static func keyAudit() {
        let domain = Bundle.main.bundleIdentifier.flatMap { UserDefaults.standard.persistentDomain(forName: $0) } ?? [:]
        let unclassified = domain.keys.filter { !CloudManifest.isClassified($0) && !CloudManifest.isSystemKey($0) }.sorted()
        var out = "\(domain.count) keys in the live domain, \(unclassified.count) unclassified\n"
        for key in unclassified { out += "UNCLASSIFIED \(key) = \(describe(domain[key]))\n" }
        write(out, to: "cloud-key-audit.txt")
    }

    @MainActor
    private static func dump(named name: String) {
        let snapshot = CloudSnapshot.capture(deviceID: "debug")
        guard let data = try? snapshot.encoded(), let url = CloudSnapshot.documentURL("\(name).aib") else { return }
        try? data.write(to: url, options: .atomic)
        var out = "digest \(snapshot.contentDigest)\nsummary \(snapshot.summaryLine)\n"
        out += "encoded \(data.count) bytes, \(snapshot.defaults.count) defaults, \(snapshot.appGroup.count) app group, \(snapshot.files.count) files\n"
        let content = CloudManifest.contentKeySet
        for key in snapshot.defaults.keys.sorted() {
            out += "\(content.contains(key) ? "content   " : "preference") \(key) = \(describe(snapshot.defaults[key]))\n"
        }
        for key in snapshot.appGroup.keys.sorted() { out += "app group  \(key) = \(describe(snapshot.appGroup[key]))\n" }
        for name in snapshot.files.keys.sorted() { out += "file       \(name) = \(snapshot.files[name]?.count ?? 0) bytes\n" }
        write(out, to: "\(name).txt")
    }

    @MainActor
    private static func restore(named name: String, mode: String) {
        guard let url = CloudSnapshot.documentURL("\(name).aib"), let data = try? Data(contentsOf: url),
              let restoreMode = CloudSnapshot.RestoreMode(rawValue: mode) else {
            write("cannot read \(name).aib or unknown mode \(mode)", to: "cloud-restore.txt")
            return
        }
        do {
            let snapshot = try CloudSnapshot.decode(data)
            snapshot.apply(restoreMode)
            write("restored \(name) (\(mode)), digest \(snapshot.contentDigest)", to: "cloud-restore.txt")
        } catch {
            write("restore failed: \(error.localizedDescription)", to: "cloud-restore.txt")
        }
    }

    private static func diff(_ first: String, _ second: String) {
        func load(_ name: String) -> CloudSnapshot? {
            CloudSnapshot.documentURL("\(name).aib").flatMap { try? Data(contentsOf: $0) }.flatMap { try? CloudSnapshot.decode($0) }
        }
        guard let a = load(first), let b = load(second) else {
            write("cannot read \(first).aib or \(second).aib", to: "cloud-diff.txt")
            return
        }
        var out = "\(first) \(a.contentDigest)\n\(second) \(b.contentDigest)\n"
        func compare(_ label: String, _ x: [String: Any], _ y: [String: Any]) {
            for key in Set(x.keys).union(y.keys).sorted() {
                switch (x[key], y[key]) {
                case let (left?, right?):
                    if !(left as AnyObject).isEqual(right) { out += "CHANGED \(label) \(key): \(describe(left)) -> \(describe(right))\n" }
                case let (left?, nil): out += "ONLY IN \(first) \(label) \(key) = \(describe(left))\n"
                case let (nil, right?): out += "ONLY IN \(second) \(label) \(key) = \(describe(right))\n"
                default: break
                }
            }
        }
        compare("defaults", a.defaults, b.defaults)
        compare("appGroup", a.appGroup, b.appGroup)
        compare("file", a.files, b.files)
        if a.contentDigest == b.contentDigest { out += "IDENTICAL\n" }
        write(out, to: "cloud-diff.txt")
    }

    // MARK: Pieces

    /// A value short enough for a report: a blob by its size (and its JSON shape when it has one).
    static func describe(_ value: Any?) -> String {
        switch value {
        case let data as Data:
            if let array = CloudJSON.array(data) { return "<\(data.count) bytes, JSON array of \(array.count)>" }
            if let dictionary = CloudJSON.dictionary(data) { return "<\(data.count) bytes, JSON object of \(dictionary.count)>" }
            return "<\(data.count) bytes>"
        case let array as [Any]: return "[\(array.count) items]"
        case let dictionary as [String: Any]: return "{\(dictionary.count) keys}"
        case let string as String: return string.count > 60 ? "\"\(string.prefix(60))...\"" : "\"\(string)\""
        case let some?: return "\(some)"
        case nil: return "nil"
        }
    }

    private static func write(_ text: String, to name: String) {
        guard let url = CloudSnapshot.documentURL(name) else { return }
        try? text.write(to: url, atomically: true, encoding: .utf8)
        NSLog("CLOUD DEBUG wrote %@", name)
    }
}
#endif
