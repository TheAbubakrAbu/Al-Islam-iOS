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
        guard let json = SolidPack.json(named: name, inPack: "qiraah") ?? looseJSON(name) else { return nil }
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

    /// The pre-solidpack loose-file path, kept as a fallback: a `<name>.json.deflate` dropped into
    /// the bundle (e.g. a reading still being QA'd that isn't in `qiraah.solidpack` yet) loads with
    /// no repack step.
    private static func looseJSON(_ name: String) -> Data? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json.deflate", subdirectory: "QiraahBeta")
            ?? Bundle.main.url(forResource: name, withExtension: "json.deflate", subdirectory: "Data/QiraahBeta")
            ?? Bundle.main.url(forResource: name, withExtension: "json.deflate"),
              let blob = try? Data(contentsOf: url) else { return nil }
        return inflate(blob)
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

// MARK: - The beta-text consent

/// Shown IN PLACE of a beta riwayah's text the first time text would render (the
/// list reader; the Page Text menu routes here too). Selecting a beta riwayah is
/// never blocked - its printed mushaf is exact and loads without any of this -
/// so the consent lives exactly where the beta thing (the TEXT) would appear,
/// with both ways out on the same screen. No dialog, no settings scavenger hunt.
struct BetaTextConsentCard: View {
    @ObservedObject private var settings = Settings.shared

    /// Riwayah shown in the title, e.g. "Ruways an Yaqub".
    let riwayahLabel: String
    /// Switch this reader to the printed mushaf (page mode + facsimile).
    let onReadPrint: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "book.pages")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(settings.accentColor.color)
                    .padding(.top, 28)

                VStack(spacing: 6) {
                    Text(riwayahLabel)
                        .font(.title3.weight(.semibold))
                    Text("Printed mushaf, or beta text?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("The printed mushaf of this riwayah is exact - the scanned pages of its published print. Its SELECTABLE TEXT is a beta transcription:\n\n\(Settings.betaQiraatNotice)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 6)

                VStack(spacing: 10) {
                    Button {
                        settings.hapticFeedback()
                        onReadPrint()
                    } label: {
                        Label("Read the Printed Mushaf", systemImage: "doc.richtext")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(settings.accentColor.color)

                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) {
                            settings.betaQiraatEnabled = true
                            settings.acceptedBetaQiraatNotice = true
                        }
                    } label: {
                        Label("Use the Beta Text", systemImage: "flask")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(settings.accentColor.color)
                }

                Text("Change anytime: Quran Settings → Beta Text, or the reader's Page Text menu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }
}
#endif
