#if os(iOS)
import Foundation
import SwiftUI
import Compression

/// The 12 riwayat of the Ten Qiraat that the King Fahd Complex has never published as
/// digital text (Ibn Amir's, Hamzah's, al-Kisai's, Abu Jafar's, Yaqub's and Khalaf
/// al-Ashir's transmissions). Their text is machine-extracted from the Islamweb printed
/// mushaf series and is **beta**: verified for structure (every riwayah carries its own
/// canonical ayah count and surah split) but not yet proofread word-by-word.
///
/// Kept OUT of `Ayah` and out of `quran.qpk` on purpose:
/// * the eight verified riwayat stay exactly as they are - no pack rebuild, no risk to
///   the text 99% of users read;
/// * these load lazily, only when someone actually selects one (or opens comparison
///   mode with beta on), and unload with the app;
/// * a future verified drop is a file swap, not a schema change.
///
/// Payload format: one deflate-compressed JSON per riwayah in `Data/QiraahBeta/`,
/// shaped exactly like the legacy overlay JSONs (`{"1":[{"id":1,"text":"..."}]}`).
/// Thread-safe by lock rather than actor isolation: ayah text is read from the main
/// thread (rendering) AND from detached background scans (search), exactly like the
/// bundled riwayat, so it can never be main-actor bound.
final class BetaQiraatStore: @unchecked Sendable {
    static let shared = BetaQiraatStore()
    private init() {}

    private let lock = NSLock()
    /// riwayah tag → surah id → ayah id → text.
    private var loaded: [String: [Int: [Int: String]]] = [:]
    private var missing: Set<String> = []

    /// File base name for a riwayah tag; nil when the tag isn't a beta riwayah.
    static func fileName(for tag: String) -> String? {
        switch Settings.Riwayah.canonicalTag(tag) {
        case Settings.Riwayah.hisham: return "QiraahHisham"
        case Settings.Riwayah.ibnDhakwan: return "QiraahIbnDhakwan"
        case Settings.Riwayah.khalaf: return "QiraahKhalaf"
        case Settings.Riwayah.khallad: return "QiraahKhallad"
        case Settings.Riwayah.abuHarith: return "QiraahAbuHarith"
        case Settings.Riwayah.duriKisai: return "QiraahDuriKisai"
        case Settings.Riwayah.ibnWardan: return "QiraahIbnWardan"
        case Settings.Riwayah.ibnJammaz: return "QiraahIbnJammaz"
        case Settings.Riwayah.ruways: return "QiraahRuways"
        case Settings.Riwayah.rawh: return "QiraahRawh"
        case Settings.Riwayah.ishaq: return "QiraahIshaq"
        case Settings.Riwayah.idris: return "QiraahIdris"
        default: return nil
        }
    }

    /// Text for one ayah, or nil when this riwayah isn't beta / isn't bundled / merges
    /// this ayah into a neighbor (the canonical counts differ between riwayat).
    func text(tag: String, surah: Int, ayah: Int) -> String? {
        guard let table = table(for: tag) else { return nil }
        return table[surah]?[ayah]
    }

    /// Ayah count this riwayah has for a surah - the authentic per-riwayah numbering.
    func ayahCount(tag: String, surah: Int) -> Int? {
        table(for: tag)?[surah]?.count
    }

    func isAvailable(tag: String) -> Bool {
        table(for: tag) != nil
    }

    /// Drop everything (used when beta mode is switched off).
    func unloadAll() {
        lock.lock(); defer { lock.unlock() }
        loaded.removeAll()
        missing.removeAll()
    }

    private func table(for tag: String) -> [Int: [Int: String]]? {
        let key = Settings.Riwayah.canonicalTag(tag)
        lock.lock()
        if let cached = loaded[key] { lock.unlock(); return cached }
        if missing.contains(key) { lock.unlock(); return nil }
        lock.unlock()

        // Parse OUTSIDE the lock (a few MB of JSON); double-check on the way back in so
        // two threads racing the same riwayah just keep the first result.
        guard let name = Self.fileName(for: key), let parsed = Self.load(name) else {
            lock.lock(); missing.insert(key); lock.unlock()
            return nil
        }
        lock.lock(); defer { lock.unlock() }
        if let cached = loaded[key] { return cached }
        loaded[key] = parsed
        return parsed
    }

    private static func load(_ name: String) -> [Int: [Int: String]]? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json.deflate", subdirectory: "QiraahBeta")
            ?? Bundle.main.url(forResource: name, withExtension: "json.deflate", subdirectory: "Data/QiraahBeta")
            ?? Bundle.main.url(forResource: name, withExtension: "json.deflate"),
              let blob = try? Data(contentsOf: url),
              let json = inflate(blob) else { return nil }
        guard let raw = try? JSONSerialization.jsonObject(with: json) as? [String: [[String: Any]]] else { return nil }
        var out: [Int: [Int: String]] = [:]
        out.reserveCapacity(raw.count)
        for (surahKey, ayahs) in raw {
            guard let sid = Int(surahKey) else { continue }
            var lookup: [Int: String] = [:]
            lookup.reserveCapacity(ayahs.count)
            for entry in ayahs {
                guard let aid = entry["id"] as? Int,
                      let text = entry["text"] as? String,
                      !text.isEmpty else { continue }
                lookup[aid] = text
            }
            out[sid] = lookup
        }
        return out.isEmpty ? nil : out
    }

    /// Raw-deflate inflate (the payloads are written with a raw stream, no zlib header,
    /// which is exactly what `COMPRESSION_ZLIB` expects from Apple's Compression).
    private static func inflate(_ data: Data) -> Data? {
        let capacity = max(data.count * 12, 1 << 21)
        var out = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        defer { buffer.deallocate() }
        let written = data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> Int in
            guard let base = raw.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return compression_decode_buffer(buffer, capacity, base, data.count, nil, COMPRESSION_ZLIB)
        }
        guard written > 0 else { return nil }
        out.append(buffer, count: written)
        return out
    }
}

// MARK: - The beta notice

/// One shared confirmation for picking a beta riwayah, wherever the pick happens
/// (Quran settings, the reader's riwayah menu, the comparison sheet). Presented as a
/// dialog attached to the control that triggered it, so iPad anchors it correctly.
struct BetaQiraahConfirmation: ViewModifier {
    @ObservedObject private var settings = Settings.shared

    @Binding var option: Settings.Riwayah.Option?
    let onAccept: (Settings.Riwayah.Option) -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "Use \(option?.label ?? "this riwayah")?",
            isPresented: Binding(
                get: { option != nil },
                set: { if !$0 { option = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Continue") {
                settings.hapticFeedback()
                settings.acceptedBetaQiraatNotice = true
                if let option { onAccept(option) }
                option = nil
            }
            Button("Cancel", role: .cancel) { option = nil }
        } message: {
            Text(Settings.betaQiraatNotice)
        }
    }
}

extension View {
    /// Confirms a beta-riwayah selection before applying it.
    func betaQiraahConfirmation(
        option: Binding<Settings.Riwayah.Option?>,
        onAccept: @escaping (Settings.Riwayah.Option) -> Void
    ) -> some View {
        modifier(BetaQiraahConfirmation(option: option, onAccept: onAccept))
    }
}
#endif
