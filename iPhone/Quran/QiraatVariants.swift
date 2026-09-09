#if os(iOS)
import SwiftUI

// The variant readings of an ayah, annotated: from `Resources/Data/Quran/QiraatVariants.json.xz`
// (Scripts/build_qiraat_variants.py), the Quran.com qiraat matrix - for each of the 1,409 ayahs
// that carry a difference between the Ten, the word read differently (the JUNCTURE), each READING
// of it with who reads it, a transliteration, an English rendering and, often, why it matters.
//
// This is the layer the app's own texts cannot give: the comparison sheet shows exactly WHAT each
// riwayah reads (every word, from the printed mushafs); this says WHO among the Ten reads which
// form and WHAT it means. Shown under the ayah in its actions sheet while qiraah details are on.
//
// Segment ranges are 0-based inclusive token indices of this app's raw Hafs text (-1 when the
// builder could not place the word; the row then simply shows the word without tinting).

final class QiraatVariantsStore: @unchecked Sendable {
    static let shared = QiraatVariantsStore()
    private init() {}

    struct Reader: Identifiable {
        let id: Int
        let name: String
        let abbreviation: String
        let city: String
        let position: Int
    }

    struct Transmitter: Identifiable {
        let id: Int
        let name: String
        let readerID: Int
        /// This app's riwayah tag (Settings.Riwayah); "" is Hafs.
        let tag: String
    }

    struct Reading: Identifiable {
        let id: Int
        let text: String
        let transliteration: String
        let english: String
        let explanation: String
        let grammaticalForm: String
        let rootLetters: String
        /// Imams reading this form (both their transmitters follow it).
        let readers: [Int]
        /// Transmitters reading this form where the two of one imam differ.
        let transmitters: [Int]
    }

    struct Segment {
        let key: String
        let range: ClosedRange<Int>?
    }

    struct Juncture: Identifiable {
        let id: Int
        let text: String
        let category: String
        let segments: [Segment]
        let readings: [Reading]
        let note: String
    }

    private struct Table {
        let readers: [Int: Reader]
        let transmitters: [Int: Transmitter]
        let transmittersByReader: [Int: [Int]]
        let ayahs: [String: [Juncture]]
    }

    private let lock = NSLock()
    private var table: Table?
    private var loadFailed = false

    static let isBundled: Bool = ThemesPack.url("QiraatVariants") != nil

    /// Parses the table off the calling thread (the explorer's detached task), once. Without it
    /// the first `junctures` call inflated 949 KB on the main thread from a row build.
    func prewarm() {
        _ = loadedTable()
    }

    func junctures(surah: Int, ayah: Int) -> [Juncture] {
        loadedTable()?.ayahs["\(surah):\(ayah)"] ?? []
    }

    func hasVariants(surah: Int, ayah: Int) -> Bool {
        !junctures(surah: surah, ayah: ayah).isEmpty
    }

    func reader(id: Int) -> Reader? { loadedTable()?.readers[id] }

    func transmitter(id: Int) -> Transmitter? { loadedTable()?.transmitters[id] }

    /// Every transmitter that follows a reading: the transmitter cells, plus both transmitters of each
    /// reader cell - in the classical order of the Ten.
    func transmitters(following reading: Reading) -> [Transmitter] {
        guard let table = loadedTable() else { return [] }
        var ids: [Int] = reading.transmitters
        for readerID in reading.readers {
            ids.append(contentsOf: table.transmittersByReader[readerID] ?? [])
        }
        var seen = Set<Int>()
        let unique = ids.filter { seen.insert($0).inserted }.compactMap { table.transmitters[$0] }
        return unique.sorted { a, b in
            let pa = table.readers[a.readerID]?.position ?? 99
            let pb = table.readers[b.readerID]?.position ?? 99
            return pa != pb ? pa < pb : a.id < b.id
        }
    }

    /// The reading the riwayah with this tag follows at the juncture, if the matrix names it.
    /// A reading names an imam when BOTH his transmitters follow it, and names a transmitter when
    /// the two part company, so a transmitter named on one reading overrides his imam's listing on
    /// a sibling. He has to be looked for across the whole juncture before falling back to the
    /// imams: at 12:109 Asim is named on نوحي while Shubah is named on يوحى, and Shubah recites
    /// يوحى. Scanning reading by reading would show him his imam's form instead of his own.
    func reading(in juncture: Juncture, followedBy tag: String) -> Reading? {
        let canonical = Settings.Riwayah.canonicalTag(tag)
        let named = juncture.readings.first { reading in
            reading.transmitters.contains { transmitter(id: $0)?.tag == canonical }
        }
        if let named { return named }
        guard let table = loadedTable() else { return nil }
        return juncture.readings.first { reading in
            reading.readers.contains { readerID in
                (table.transmittersByReader[readerID] ?? []).contains { id in
                    table.transmitters[id]?.tag == canonical
                }
            }
        }
    }

    /// "Nāfiʿ, Ibn Kathīr, Abū ʿAmr · Hishām" - imams whose both transmitters read it, then the
    /// single transmitters. Short names throughout.
    func attribution(for reading: Reading) -> String {
        guard let table = loadedTable() else { return "" }
        let readers = reading.readers.compactMap { table.readers[$0] }
            .sorted { $0.position < $1.position }
            .map(\.abbreviation)
        let transmitters = reading.transmitters.compactMap { table.transmitters[$0] }
            .sorted { a, b in
                let pa = table.readers[a.readerID]?.position ?? 99
                let pb = table.readers[b.readerID]?.position ?? 99
                return pa != pb ? pa < pb : a.id < b.id
            }
            .map { transmitter -> String in
                let reader = table.readers[transmitter.readerID]?.abbreviation ?? ""
                return reader.isEmpty ? transmitter.name : "\(transmitter.name) (\(reader))"
            }
        var parts: [String] = []
        if !readers.isEmpty { parts.append(readers.joined(separator: ", ")) }
        if !transmitters.isEmpty { parts.append(transmitters.joined(separator: ", ")) }
        return parts.joined(separator: " · ")
    }

    func unload() {
        lock.lock(); defer { lock.unlock() }
        table = nil
        loadFailed = false
    }

    private func loadedTable() -> Table? {
        lock.lock()
        if let table { lock.unlock(); return table }
        if loadFailed { lock.unlock(); return nil }
        lock.unlock()

        guard let parsed = Self.load() else {
            lock.lock(); loadFailed = true; lock.unlock()
            return nil
        }
        lock.lock(); defer { lock.unlock() }
        if let table { return table }
        table = parsed
        return parsed
    }

    private static func load() -> Table? {
        guard let root = ThemesPack.json("QiraatVariants") as? [String: Any],
              let rawReaders = root["readers"] as? [String: [String: Any]],
              let rawTransmitters = root["transmitters"] as? [String: [String: Any]],
              let rawAyahs = root["ayahs"] as? [String: [[String: Any]]] else { return nil }

        var readers: [Int: Reader] = [:]
        for (key, row) in rawReaders {
            guard let id = Int(key), let name = row["n"] as? String else { continue }
            readers[id] = Reader(id: id, name: name, abbreviation: row["a"] as? String ?? name,
                                 city: row["c"] as? String ?? "", position: row["p"] as? Int ?? 99)
        }
        var transmitters: [Int: Transmitter] = [:]
        var byReader: [Int: [Int]] = [:]
        for (key, row) in rawTransmitters {
            guard let id = Int(key), let name = row["n"] as? String, let readerID = row["r"] as? Int else { continue }
            transmitters[id] = Transmitter(id: id, name: name, readerID: readerID, tag: row["tag"] as? String ?? "")
            byReader[readerID, default: []].append(id)
        }
        for key in byReader.keys { byReader[key]?.sort() }

        var ayahs: [String: [Juncture]] = [:]
        ayahs.reserveCapacity(rawAyahs.count)
        for (key, rows) in rawAyahs {
            var junctures: [Juncture] = []
            for (index, row) in rows.enumerated() {
                let segments = (row["seg"] as? [[Any]] ?? []).compactMap { seg -> Segment? in
                    guard seg.count == 3, let segKey = seg[0] as? String,
                          let start = seg[1] as? Int, let end = seg[2] as? Int else { return nil }
                    return Segment(key: segKey, range: start >= 0 && end >= start ? start...end : nil)
                }
                let readings = (row["readings"] as? [[String: Any]] ?? []).enumerated().compactMap { offset, reading -> Reading? in
                    guard let text = reading["t"] as? String, !text.isEmpty else { return nil }
                    return Reading(
                        id: offset,
                        text: text,
                        transliteration: reading["tr"] as? String ?? "",
                        english: reading["en"] as? String ?? "",
                        explanation: reading["ex"] as? String ?? "",
                        grammaticalForm: reading["gf"] as? String ?? "",
                        rootLetters: reading["rt"] as? String ?? "",
                        readers: reading["rd"] as? [Int] ?? [],
                        transmitters: reading["tm"] as? [Int] ?? []
                    )
                }
                guard !readings.isEmpty else { continue }
                junctures.append(Juncture(
                    id: index,
                    text: row["t"] as? String ?? "",
                    category: row["c"] as? String ?? "",
                    segments: segments,
                    readings: readings,
                    note: row["note"] as? String ?? ""
                ))
            }
            if !junctures.isEmpty { ayahs[key] = junctures }
        }
        return ayahs.isEmpty ? nil : Table(readers: readers, transmitters: transmitters, transmittersByReader: byReader, ayahs: ayahs)
    }
}

// MARK: - Under the ayah: the other readings

/// The OTHER QIRAAT block of an ayah's actions sheet: each juncture with its readings, who reads
/// them and what they mean, the reader's own riwayah marked. Compact by design; the full page
/// (explanations, notes, transliterations) is one push away.
struct AyahQiraatVariantsSection: View {
    @ObservedObject private var settings = Settings.shared

    let surah: Surah
    let ayah: Ayah

    private var junctures: [QiraatVariantsStore.Juncture] {
        QiraatVariantsStore.shared.junctures(surah: surah.id, ayah: ayah.id)
    }

    private var currentTag: String { Settings.Riwayah.canonicalTag(settings.displayQiraah) }

    /// The riwayah's name without the picker's "(default)" suffix: a pill, not a menu row.
    private var currentLabel: String {
        Settings.Riwayah.option(for: currentTag).label
            .replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression)
    }

    var body: some View {
        let junctures = junctures
        if !junctures.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("OTHER QIRAAT")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(junctures.count == 1 ? "1 word read differently" : "\(junctures.count) words read differently")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                ForEach(junctures) { juncture in
                    junctureBlock(juncture)
                }

                NavigationLink {
                    AyahQiraatVariantsView(surah: surah, ayah: ayah)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "text.book.closed")
                        Text("All Readings and Notes")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .font(.subheadline)
                    .foregroundColor(settings.accentColor.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(settings.accentColor.color.opacity(0.10))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
        }
    }

    private func junctureBlock(_ juncture: QiraatVariantsStore.Juncture) -> some View {
        let mine = QiraatVariantsStore.shared.reading(in: juncture, followedBy: currentTag)

        return VStack(alignment: .leading, spacing: 6) {
            Text(juncture.text)
                .font(.custom(settings.quranArabicFontName(for: nil), size: 20))
                .arabicFontDesign(custom: true)
                .foregroundColor(settings.accentColor.color)
                .frame(maxWidth: .infinity, alignment: .trailing)

            ForEach(juncture.readings) { reading in
                let isMine = mine?.id == reading.id
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(QiraatVariantsStore.shared.attribution(for: reading))
                                .font(.caption.weight(isMine ? .semibold : .regular))
                                .foregroundStyle(isMine ? AnyShapeStyle(settings.accentColor.color) : AnyShapeStyle(.secondary))
                                .lineLimit(2)
                            if isMine {
                                Text(currentLabel)
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(settings.accentColor.color.opacity(0.15)))
                                    .foregroundColor(settings.accentColor.color)
                            }
                        }
                        if !reading.english.isEmpty {
                            Text(reading.english)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text(reading.text)
                        .font(.custom(settings.quranArabicFontName(for: nil), size: 18))
                        .arabicFontDesign(custom: true)
                        .foregroundColor(isMine ? settings.accentColor.color : .primary)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - The full page

/// Every juncture of the ayah with its readings in full: the form, who reads it, how it is said, what
/// it means, and the source's explanation and note. Pushed from the actions sheet.
struct AyahQiraatVariantsView: View {
    @ObservedObject private var settings = Settings.shared

    let surah: Surah
    let ayah: Ayah

    private var junctures: [QiraatVariantsStore.Juncture] {
        QiraatVariantsStore.shared.junctures(surah: surah.id, ayah: ayah.id)
    }

    private var currentTag: String { Settings.Riwayah.canonicalTag(settings.displayQiraah) }

    var body: some View {
        List {
            Section {
                AyahPreviewCard(surah: surah, ayahs: [ayah])
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            ForEach(junctures) { juncture in
                Section(header: Text(junctures.count == 1 ? "THE WORD" : "WORD \(juncture.id + 1) OF \(junctures.count)")) {
                    Text(juncture.text)
                        .font(.custom(settings.quranArabicFontName(for: nil), size: CGFloat(settings.fontArabicSize)))
                        .arabicFontDesign(custom: true)
                        .foregroundColor(settings.accentColor.color)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.vertical, 4)

                    ForEach(juncture.readings) { reading in
                        readingRow(reading, mine: QiraatVariantsStore.shared.reading(in: juncture, followedBy: currentTag)?.id == reading.id)
                    }

                    if !juncture.note.isEmpty {
                        Text(juncture.note)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Section(footer:
                Text("Readings of the Ten and their meanings from the Quran.com qiraat reference (Quran Foundation). The app's Qiraah Comparison shows the full text of every riwayah from its printed mushaf.")
                    .font(.caption2)
            ) { EmptyView() }
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .navigationTitle("Readings of \(ayahSheetTitle(surahNumber: surah.id, ayahNumber: ayah.id))")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func readingRow(_ reading: QiraatVariantsStore.Reading, mine: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    if mine {
                        Text("YOUR RIWAYAH · \(Settings.Riwayah.option(for: currentTag).label.replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression).uppercased())")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(settings.accentColor.color)
                    }
                    Text(QiraatVariantsStore.shared.attribution(for: reading))
                        .font(.subheadline.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                    if !reading.transliteration.isEmpty {
                        Text(reading.transliteration)
                            .font(.caption.italic())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(reading.text)
                    .font(.custom(settings.quranArabicFontName(for: nil), size: 22))
                    .arabicFontDesign(custom: true)
                    .foregroundColor(mine ? settings.accentColor.color : .primary)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !reading.english.isEmpty {
                Text(reading.english)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !reading.explanation.isEmpty {
                Text(reading.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !reading.grammaticalForm.isEmpty || !reading.rootLetters.isEmpty {
                Text([reading.grammaticalForm, reading.rootLetters].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .textSelection(.enabled)
    }
}
#endif
