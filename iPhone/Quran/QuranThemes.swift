#if os(iOS)
import SwiftUI
import Compression

// Browse by Theme + surah outlines, ported from Tilawa (by Jamil Hammoudeh) with permission.
//
// Two packs, both built by Scripts/build_quran_themes.py and gated by
// Scripts/verify_quran_themes.py:
//   * ThematicTopics.json.deflate - the QSAC corpus (CC BY 4.0): 323 topics, each carrying a
//     description, a domain, and the ayahs it annotates. Backs the Browse by Theme sheet.
//   * SurahSections.json.deflate - Quranpedia's passage outlines per surah. Surfaced as a
//     synthetic "Outline" source inside the existing About this Surah sheet, so it inherits
//     that sheet's picker, search, and text handling for free.

// MARK: - Topics store

struct ThemeTopic: Identifiable {
    let id: String
    let name: String
    let description: String
    let domain: String
    let category: String
    /// "surah:ayah" keys, in the corpus's order.
    let ayahs: [String]
}

final class ThematicTopicsStore: @unchecked Sendable {
    static let shared = ThematicTopicsStore()
    private init() {}

    private let lock = NSLock()
    private var cached: [ThemeTopic]?
    private var loadFailed = false

    static let isBundled: Bool = ThemesPack.url("ThematicTopics") != nil

    /// All topics in corpus order, or [] if the pack is missing/corrupt.
    func topics() -> [ThemeTopic] {
        lock.lock()
        if let cached { lock.unlock(); return cached }
        if loadFailed { lock.unlock(); return [] }
        lock.unlock()

        let parsed = Self.load()
        lock.lock(); defer { lock.unlock() }
        if let cached { return cached }
        if let parsed {
            cached = parsed
            return parsed
        }
        loadFailed = true
        return []
    }

    /// Topics grouped for the browse list, preserving domain order of first appearance.
    func topicsByDomain() -> [(domain: String, topics: [ThemeTopic])] {
        var order: [String] = []
        var groups: [String: [ThemeTopic]] = [:]
        for topic in topics() {
            let domain = topic.domain.isEmpty ? "Other" : topic.domain
            if groups[domain] == nil { order.append(domain) }
            groups[domain, default: []].append(topic)
        }
        return order.map { ($0, groups[$0] ?? []) }
    }

    private static func load() -> [ThemeTopic]? {
        guard let root = ThemesPack.json("ThematicTopics") as? [String: Any],
              let rows = root["topics"] as? [[String: Any]] else { return nil }
        let topics = rows.compactMap { row -> ThemeTopic? in
            guard let id = row["id"] as? String,
                  let name = row["name"] as? String,
                  let ayahs = row["ayahs"] as? [String], !ayahs.isEmpty else { return nil }
            return ThemeTopic(
                id: id,
                name: name,
                description: row["description"] as? String ?? "",
                domain: row["domain"] as? String ?? "",
                category: row["category"] as? String ?? "",
                ayahs: ayahs
            )
        }
        return topics.isEmpty ? nil : topics
    }
}

// MARK: - Sections store

final class SurahSectionsStore: @unchecked Sendable {
    static let shared = SurahSectionsStore()
    private init() {}

    private let lock = NSLock()
    private var table: [String: Any]?
    private var loadFailed = false

    static let isBundled: Bool = ThemesPack.url("SurahSections") != nil

    /// The outline for one surah as ready-to-render markdown, or nil when the surah has none.
    /// Markdown because the consumer is the About this Surah sheet's existing markdown view -
    /// the outline behaves exactly like the bundled prose sources there.
    func outlineMarkdown(surah: Int) -> String? {
        guard let entry = loadedTable()?["\(surah)"] as? [String: Any] else { return nil }
        let overview = (entry["overview"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let sections = entry["sections"] as? [[Any]] ?? []

        var blocks: [String] = []
        if !overview.isEmpty { blocks.append(overview) }
        for row in sections {
            guard row.count >= 4,
                  let start = row[0] as? Int, let end = row[1] as? Int else { continue }
            let english = (row[2] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let arabic = (row[3] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let range = start == end ? "Ayah \(start)" : "Ayahs \(start)-\(end)"
            var block = "**\(range)**"
            if !english.isEmpty { block += "\n\n\(english)" }
            if !arabic.isEmpty { block += "\n\n\(arabic)" }
            blocks.append(block)
        }
        guard !blocks.isEmpty else { return nil }
        return blocks.joined(separator: "\n\n---\n\n")
    }

    private func loadedTable() -> [String: Any]? {
        lock.lock()
        if let table { lock.unlock(); return table }
        if loadFailed { lock.unlock(); return nil }
        lock.unlock()

        let parsed = ThemesPack.json("SurahSections") as? [String: Any]
        lock.lock(); defer { lock.unlock() }
        if let table { return table }
        if let parsed {
            table = parsed
            return parsed
        }
        loadFailed = true
        return nil
    }
}

// MARK: - Shared pack loading

enum ThemesPack {
    static func url(_ name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "json.deflate", subdirectory: "Data/Quran")
            ?? Bundle.main.url(forResource: name, withExtension: "json.deflate", subdirectory: "Quran")
            ?? Bundle.main.url(forResource: name, withExtension: "json.deflate")
    }

    static func json(_ name: String) -> Any? {
        guard let url = url(name),
              let blob = try? Data(contentsOf: url),
              let json = inflate(blob) else { return nil }
        return try? JSONSerialization.jsonObject(with: json)
    }

    private static func inflate(_ data: Data) -> Data? {
        let capacity = max(data.count * 14, 1 << 21)
        var out = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        defer { buffer.deallocate() }
        let written = data.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) -> Int in
            guard let base = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return compression_decode_buffer(buffer, capacity, base, data.count, nil, COMPRESSION_ZLIB)
        }
        guard written > 0 else { return nil }
        out.append(buffer, count: written)
        return out
    }
}

// MARK: - Browse by Theme

/// Domains → topics → the topic's ayahs. Self-contained sheet: pushes happen inside its own
/// NavigationView, and "open in reader" hands the ayah back to QuranView through `onOpenAyah`
/// (which closes the sheet first) so the reader push uses the tab's own navigation machinery.
struct ThemesBrowseSheet: View {
    @ObservedObject private var settings = Settings.shared

    let onOpenAyah: (Int, Int) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(ThematicTopicsStore.shared.topicsByDomain(), id: \.domain) { group in
                    Section(header: Text(group.domain.uppercased())) {
                        ForEach(group.topics) { topic in
                            NavigationLink {
                                ThemeTopicDetailView(topic: topic, onOpenAyah: onOpenAyah)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(topic.name)
                                            .font(.headline)
                                        Spacer()
                                        Text("\(topic.ayahs.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    if !topic.description.isEmpty {
                                        Text(topic.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }

                Section(footer:
                    Text("Topics from the Quran Semantic Annotation Corpus (CC BY 4.0), via Tilawa.")
                        .font(.caption2)
                ) { EmptyView() }
            }
            .applyConditionalListStyle(disableNowPlayingInset: true)
            .navigationTitle("Browse by Theme")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
        .smallMediumSheetPresentation()
    }
}

private struct ThemeTopicDetailView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    let topic: ThemeTopic
    let onOpenAyah: (Int, Int) -> Void

    var body: some View {
        List {
            if !topic.description.isEmpty {
                Section {
                    Text(topic.description)
                        .font(.body)
                }
            }

            Section(header: Text("\(topic.ayahs.count) AYAHS")) {
                ForEach(topic.ayahs, id: \.self) { key in
                    ayahRow(key)
                }
            }
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .navigationTitle(topic.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func ayahRow(_ key: String) -> some View {
        let parts = key.split(separator: ":").compactMap { Int($0) }
        if parts.count == 2,
           let surah = quranData.surah(parts[0]),
           let ayah = surah.ayahs.first(where: { $0.id == parts[1] }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("\(surah.nameTransliteration) \(parts[0]):\(parts[1])")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(settings.accentColor.color)
                    Spacer()
                    Button {
                        settings.hapticFeedback()
                        QuranPlayer.shared.playAyah(surahNumber: parts[0], ayahNumber: parts[1])
                    } label: {
                        Image(systemName: "play.circle")
                            .foregroundColor(settings.accentColor.color)
                    }
                    .buttonStyle(.plain)
                }

                Text(ayah.textEnglishSaheeh)
                    .font(.system(size: CGFloat(settings.englishFontSize)))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                settings.hapticFeedback()
                onOpenAyah(parts[0], parts[1])
            }
        }
    }
}
#endif
