// iCloud Backup is Al-Islam's alone: this file compiles only where `HAS_ICLOUD_BACKUP` is defined
// (Al-Islam's project settings). The companion apps never receive it (sync-manifests).
#if HAS_ICLOUD_BACKUP
import Foundation
import CryptoKit
#if os(iOS)
import UIKit
#endif

/// One device's backup as it travels (docs/iCloud Sync Guide.md, section 5): the manifest's keys out
/// of standard defaults, the app-group-only preferences, and the user's Documents files.
///
/// A property list, because that is exactly what `UserDefaults` holds: `Data` stays `Data`, a `Bool`
/// stays distinct from an `Int`, and every stored blob round-trips byte for byte with nothing
/// decoded on the way. Only keys that EXIST are captured (read from the app's persistent domain, not
/// through `object(forKey:)`, which would also answer with registered defaults), so a key the source
/// device never set is absent, and a Replace removes it here so the default applies here too.
struct CloudSnapshot {
    static let currentSchemaVersion = 1

    var schemaVersion = CloudSnapshot.currentSchemaVersion
    var createdAt = Date()
    var deviceKind = ""
    var deviceID = ""
    var appVersion = ""
    var defaults: [String: Any] = [:]
    var appGroup: [String: Any] = [:]
    var files: [String: Data] = [:]

    enum Failure: LocalizedError {
        case unreadable
        case newerSchema(Int)

        var errorDescription: String? {
            switch self {
            case .unreadable:
                return "This is not a backup made by \(AppIdentifiers.appName), or it is damaged."
            case .newerSchema:
                return "This backup was made by a newer version of the app. Update the app, then restore."
            }
        }
    }

    // MARK: Capture

    /// What this device holds right now. Pending writes land first, so the snapshot is what the app
    /// WOULD have written, not what it happened to have written so far.
    @MainActor
    static func capture(deviceID: String) -> CloudSnapshot {
        Settings.flushAllPendingWrites()
        var snapshot = CloudSnapshot()
        snapshot.deviceKind = CloudDevice.kind
        snapshot.deviceID = deviceID
        snapshot.appVersion = CloudDevice.appVersion

        let domain = Bundle.main.bundleIdentifier.flatMap { UserDefaults.standard.persistentDomain(forName: $0) } ?? [:]
        for key in CloudManifest.contentKeys + CloudManifest.preferenceKeys {
            if let value = domain[key] { snapshot.defaults[key] = value }
        }
        // The app group only for keys the user CHOSE (the watch sync's ledger): an extension that
        // assigns a default creates the key, so presence alone would back up defaults (decision 15).
        if let group = Settings.shared.appGroupUserDefaults {
            let chosen = Settings.shared.explicitlySetKeys
            for key in CloudManifest.appGroupPreferenceKeys where chosen.contains(key) {
                if let value = group.object(forKey: key) { snapshot.appGroup[key] = value }
            }
        }
        for name in CloudManifest.files {
            if let url = documentURL(name), let data = try? Data(contentsOf: url), !data.isEmpty {
                snapshot.files[name] = data
            }
        }
        return snapshot
    }

    static func documentURL(_ name: String) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(name, isDirectory: false)
    }

    /// The exported file's name: "Al-Islam Backup 2026-09-21 14.32.islambackup". One extension for
    /// the three sibling apps, because the bytes are the same format.
    static let fileExtension = "islambackup"

    static func fileName(at date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH.mm"
        return "\(AppIdentifiers.appName) Backup \(formatter.string(from: date)).\(fileExtension)"
    }

    // MARK: Encoding

    /// Four bytes ahead of the compressed property list, so a file that is not one of these is
    /// refused before anything tries to inflate it.
    private static let magic = Data("AIB1".utf8)

    func encoded() throws -> Data {
        let plist: [String: Any] = [
            "schemaVersion": schemaVersion,
            "createdAt": createdAt,
            "deviceKind": deviceKind,
            "deviceID": deviceID,
            "appVersion": appVersion,
            "defaults": defaults,
            "appGroup": appGroup,
            "files": files,
        ]
        let raw = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
        let compressed = try (raw as NSData).compressed(using: .zlib) as Data
        return Self.magic + compressed
    }

    static func decode(_ data: Data) throws -> CloudSnapshot {
        guard data.count > magic.count, data.prefix(magic.count) == magic else { throw Failure.unreadable }
        let body = data.dropFirst(magic.count)
        guard let raw = try? (Data(body) as NSData).decompressed(using: .zlib) as Data,
              let plist = try? PropertyListSerialization.propertyList(from: raw, options: [], format: nil) as? [String: Any],
              let version = plist["schemaVersion"] as? Int else { throw Failure.unreadable }
        guard version <= currentSchemaVersion else { throw Failure.newerSchema(version) }

        var snapshot = CloudSnapshot()
        snapshot.schemaVersion = version
        snapshot.createdAt = plist["createdAt"] as? Date ?? Date(timeIntervalSince1970: 0)
        snapshot.deviceKind = plist["deviceKind"] as? String ?? ""
        snapshot.deviceID = plist["deviceID"] as? String ?? ""
        snapshot.appVersion = plist["appVersion"] as? String ?? ""
        snapshot.defaults = plist["defaults"] as? [String: Any] ?? [:]
        snapshot.appGroup = plist["appGroup"] as? [String: Any] ?? [:]
        snapshot.files = plist["files"] as? [String: Data] ?? [:]
        return snapshot
    }

    // MARK: Digest

    /// SHA-256 of what the snapshot SAYS (the keys, the values, the files), walked in sorted key
    /// order. Not of the encoded bytes: a dictionary serializes in whatever order it enumerates, and
    /// the date and device lines change on every capture, so two captures of identical content
    /// would never match and every background pass would upload.
    var contentDigest: String {
        var hasher = SHA256()
        Self.feed(defaults, into: &hasher)
        Self.feed(appGroup, into: &hasher)
        Self.feed(files, into: &hasher)
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func feed(_ value: Any, into hasher: inout SHA256) {
        switch value {
        case let dictionary as [String: Any]:
            hasher.update(data: Data([0x01]))
            for key in dictionary.keys.sorted() {
                hasher.update(data: Data(key.utf8))
                hasher.update(data: Data([0x00]))
                if let inner = dictionary[key] { feed(inner, into: &hasher) }
            }
            hasher.update(data: Data([0x02]))
        case let array as [Any]:
            hasher.update(data: Data([0x03]))
            for element in array { feed(element, into: &hasher) }
            hasher.update(data: Data([0x04]))
        case let data as Data:
            hasher.update(data: Data([0x05]))
            hasher.update(data: data)
        case let string as String:
            hasher.update(data: Data([0x06]))
            hasher.update(data: Data(string.utf8))
        case let date as Date:
            hasher.update(data: Data([0x07]))
            hasher.update(data: Data(String(date.timeIntervalSince1970).utf8))
        case let number as NSNumber:
            // A Bool and the Int 1 are different settings; NSNumber alone cannot say which it is.
            let isBool = CFGetTypeID(number) == CFBooleanGetTypeID()
            hasher.update(data: Data([isBool ? 0x08 : 0x09]))
            hasher.update(data: Data(number.stringValue.utf8))
        default:
            hasher.update(data: Data([0x0A]))
        }
    }

    // MARK: Describing

    /// One line for the profile picker, read out of the blobs without any of the app's model types:
    /// the same counts What's Included shows (`ContentCategory`), top four.
    var summaryLine: String { ContentInventory(self, bytes: 0).summaryLine }

    // MARK: Applying

    enum RestoreMode: String {
        /// This device becomes the backup: content AND settings, and a manifest key the backup
        /// lacks is removed here. The new-phone choice.
        case replace
        /// The backup's content joins what is here (`CloudMergeRules`); this device's settings stay
        /// its own. The second-device choice.
        case merge
    }

    /// Writes the snapshot underneath the running app, then has every store take the new bytes
    /// (`Settings.storedContentWasReplaced`). Device-only keys are never touched in either mode.
    @MainActor
    func apply(_ mode: RestoreMode) {
        Settings.flushAllPendingWrites()
        let store = UserDefaults.standard

        switch mode {
        case .replace:
            for key in CloudManifest.contentKeys + CloudManifest.preferenceKeys {
                if let value = defaults[key] {
                    store.set(value, forKey: key)
                } else {
                    store.removeObject(forKey: key)
                }
            }
            if let group = Settings.shared.appGroupUserDefaults {
                for key in CloudManifest.appGroupPreferenceKeys {
                    if let value = appGroup[key] {
                        group.set(value, forKey: key)
                    } else {
                        group.removeObject(forKey: key)
                    }
                }
            }
            for name in CloudManifest.files {
                guard let url = Self.documentURL(name) else { continue }
                if let data = files[name] {
                    try? data.write(to: url, options: .atomic)
                } else {
                    try? FileManager.default.removeItem(at: url)
                }
            }

        case .merge:
            let domain = Bundle.main.bundleIdentifier.flatMap { store.persistentDomain(forName: $0) } ?? [:]
            for (key, value) in CloudMergeRules.merged(local: domain, incoming: defaults) {
                store.set(value, forKey: key)
            }
            for name in CloudManifest.files {
                guard let incoming = files[name], let url = Self.documentURL(name) else { continue }
                let local = try? Data(contentsOf: url)
                if let merged = CloudMergeRules.mergedFile(name, local: local, incoming: incoming) {
                    try? merged.write(to: url, options: .atomic)
                }
            }
        }

        Settings.shared.storedContentWasReplaced(includingPreferences: mode == .replace)
    }
}

/// What the backup says about the device that wrote it. Not the marketing name ("iPhone 17 Pro"):
/// that needs a table of machine identifiers that is out of date every September, and since iOS 16
/// the system will not give an app the device's own name either. The user's nickname carries that.
enum CloudDevice {
    static var kind: String {
        #if os(iOS)
        if ProcessInfo.processInfo.isiOSAppOnMac { return "Mac" }
        return UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        #else
        return "Apple Watch"
        #endif
    }

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    /// A nickname to start from: "iPhone", or the device's own name where the system still gives it.
    static var suggestedNickname: String {
        #if os(iOS)
        let name = UIDevice.current.name
        return name.isEmpty ? kind : name
        #else
        return kind
        #endif
    }
}

/// JSON read and written generically (`JSONSerialization`), which is what lets the merge work on
/// every blob without naming one of the app's model types.
enum CloudJSON {
    static func object(_ value: Any?) -> Any? {
        guard let data = value as? Data, !data.isEmpty else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: [])
    }

    static func array(_ value: Any?) -> [Any]? { object(value) as? [Any] }

    static func dictionary(_ value: Any?) -> [String: Any]? { object(value) as? [String: Any] }

    static func data(_ object: Any) -> Data? {
        guard JSONSerialization.isValidJSONObject(object) else { return nil }
        return try? JSONSerialization.data(withJSONObject: object, options: [.withoutEscapingSlashes])
    }
}
#endif
