#if os(iOS)
import SwiftUI
import Compression

// Browse by Theme + surah outlines, ported from Tilawa (by Jamil Hammoudeh) with permission.
//
// Two packs, both built by Scripts/build_quran_themes.py and gated by
// Scripts/verify_quran_themes.py:
//   * ThematicTopics.json.xz - the QSAC corpus (CC BY 4.0): 323 topics, each carrying a
//     description, a domain, and the ayahs it annotates. Backs the Browse by Theme sheet.
//   * SurahSections.json.xz - Quranpedia's passage outlines per surah. Surfaced as a
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
    /// The grouped browse list, built once. The topics never change after load, and the browse screen's
    /// body used to re-group all 323 of them (dictionary + order walk) on every render pass.
    private var groupedCache: [(domain: String, topics: [ThemeTopic])]?
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

    /// Topics grouped for the browse list, preserving domain order of first appearance. Memoized -
    /// the corpus is immutable after load, so the grouping is computed exactly once.
    func topicsByDomain() -> [(domain: String, topics: [ThemeTopic])] {
        lock.lock()
        if let groupedCache { lock.unlock(); return groupedCache }
        lock.unlock()

        var order: [String] = []
        var groups: [String: [ThemeTopic]] = [:]
        for topic in topics() {
            let domain = topic.domain.isEmpty ? "Other" : topic.domain
            if groups[domain] == nil { order.append(domain) }
            groups[domain, default: []].append(topic)
        }
        let grouped = order.map { ($0, groups[$0] ?? []) }

        lock.lock(); defer { lock.unlock() }
        // Don't cache the empty answer a missing/corrupt pack produces via `topics()` - `loadFailed`
        // already remembers that case, and caching [] here would also freeze an early call that raced
        // the pack load.
        if groupedCache == nil, !grouped.isEmpty { groupedCache = grouped }
        return groupedCache ?? grouped
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
        Bundle.main.url(forResource: name, withExtension: "json.xz", subdirectory: "Data/Quran")
            ?? Bundle.main.url(forResource: name, withExtension: "json.xz", subdirectory: "Quran")
            ?? Bundle.main.url(forResource: name, withExtension: "json.xz")
    }

    static func json(_ name: String) -> Any? {
        guard let url = url(name),
              let blob = try? Data(contentsOf: url),
              let json = inflate(blob) else { return nil }
        return try? JSONSerialization.jsonObject(with: json)
    }

    /// The payload is an xz stream; `COMPRESSION_LZMA` reads that container directly.
    private static func inflate(_ data: Data) -> Data? {
        SolidPack.xzDecompress(data)
    }
}

// MARK: - Browse by Theme

/// Domains → topics → the topic's ayahs.
///
/// PUSHED, not presented. It used to be a half-height sheet, which cut a three-level browse (domains,
/// topics, ayahs) off at the knees - every list arrived pre-scrolled into a letterbox. As a pushed
/// screen it gets the full height on iPhone, and inside the Quran tab's `NavigationSplitView` it pushes
/// in the LEFT column exactly as a hadith book's chapters do: the topic list stays on the left while
/// the ayah you pick opens in the reader on the right.
///
/// That is also why this owns no NavigationView of its own - it must inherit whichever column it was
/// pushed into. "Open in reader" hands the ayah back to QuranView through `onOpenAyah`, which routes it
/// via `push(surahID:ayahID:)` and therefore does the right thing in both layouts for free.
struct ThemesBrowseView: View {
    @ObservedObject private var settings = Settings.shared

    let onOpenAyah: (Int, Int) -> Void

    @State private var searchText = ""
    /// Domains the user folded shut. Stored as the EXCEPTION set so every section starts expanded.
    @State private var collapsedDomains = Set<String>()
    /// Domains whose "Show All" was tapped - those sections list every topic instead of the first 10.
    @State private var showAllDomains = Set<String>()
    #if DEBUG
    /// Drives the hidden "-openThemeTopic" link, which only exists when the argument was passed.
    /// DEBUG builds only.
    @State private var debugOpenFirstTopic = false
    private static let debugWantsTopic = ProcessInfo.processInfo.arguments.contains("-openThemeTopic")
    #endif

    /// How many topics a section shows before the "Show All" button takes over. Big domains carry
    /// 40+ topics; ten keeps the browse scannable without hiding the small domains at all.
    private static let topicsPerSection = 10

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The memoized store grouping, filtered in the view (the store's comment: never re-group per
    /// render). Searching matches a topic's name, description, category, or its domain's name.
    private var displayedGroups: [(domain: String, topics: [ThemeTopic])] {
        let groups = ThematicTopicsStore.shared.topicsByDomain()
        let query = settings.cleanSearch(trimmedQuery, whitespace: true)
        guard !query.isEmpty else { return groups }

        return groups.compactMap { group in
            if settings.cleanSearch(group.domain, whitespace: true).contains(query) {
                return group
            }
            let topics = group.topics.filter { topic in
                settings.cleanSearch(topic.name, whitespace: true).contains(query)
                || settings.cleanSearch(topic.description, whitespace: true).contains(query)
                || settings.cleanSearch(topic.category, whitespace: true).contains(query)
            }
            return topics.isEmpty ? nil : (group.domain, topics)
        }
    }

    var body: some View {
        let isSearching = !trimmedQuery.isEmpty
        let groups = displayedGroups

        List {
            #if DEBUG
            // "-openThemeTopic" pushes the first topic on launch, so the ayah rows (which are the
            // reader's own AyahRow) can be verified headlessly. DEBUG builds only.
            //
            // Inserted ONLY when the argument is actually present: a hidden zero-height view is
            // still a List ROW, and it drew an empty card above the first domain.
            if Self.debugWantsTopic, let first = groups.first?.topics.first {
                NavigationLink(isActive: $debugOpenFirstTopic) {
                    ThemeTopicDetailView(topic: first, onOpenAyah: onOpenAyah)
                } label: { EmptyView() }
                    .frame(height: 0)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .hidden()
                    .onAppear { debugOpenFirstTopic = true }
            }
            #endif

            ForEach(groups, id: \.domain) { group in
                themeSection(group, isSearching: isSearching)
            }

            if isSearching && groups.isEmpty {
                Section {
                    Text("No themes match your search.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // The credits hide while searching, the app's convention for trailing footers.
            if !isSearching {
                Section(footer:
                    Text("Topics from the Quran Semantic Annotation Corpus (CC BY 4.0).")
                        .font(.caption2)
                ) { EmptyView() }
            }
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .dismissKeyboardOnScroll()
        // The app's own bottom search bar, not `.searchable` - the same inset the surah picker and
        // the Quran/Hadith readers use, so every search in the app sits in the same place.
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut), placeholder: "Search themes")
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
        }
        .navigationTitle("Browse by Theme")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// One domain's section: a fold-able pill header, the first ten topics, and a "Show All" row for
    /// the rest. While searching every match shows (no fold, no truncation) - a search that hid its
    /// own results inside collapsed sections would read as broken.
    @ViewBuilder
    private func themeSection(_ group: (domain: String, topics: [ThemeTopic]), isSearching: Bool) -> some View {
        let isExpanded = isSearching || !collapsedDomains.contains(group.domain)
        let showsAll = isSearching || showAllDomains.contains(group.domain)
        let shown = showsAll ? group.topics : Array(group.topics.prefix(Self.topicsPerSection))

        Section(header: SectionPillHeader(
            title: group.domain.uppercased(),
            count: group.topics.count,
            isExpanded: isSearching ? nil : Binding(
                get: { !collapsedDomains.contains(group.domain) },
                set: { expanded in
                    if expanded {
                        collapsedDomains.remove(group.domain)
                    } else {
                        collapsedDomains.insert(group.domain)
                    }
                }
            )
        )) {
            if isExpanded {
                ForEach(shown) { topic in
                    NavigationLink {
                        ThemeTopicDetailView(topic: topic, onOpenAyah: onOpenAyah)
                    } label: {
                        topicLabel(topic)
                    }
                }

                if !showsAll && group.topics.count > Self.topicsPerSection {
                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) {
                            _ = showAllDomains.insert(group.domain)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.down.circle")
                                .font(.subheadline)

                            Text("Show All \(group.topics.count) Topics")
                                .font(.subheadline.weight(.semibold))

                            Spacer()
                        }
                        .foregroundColor(settings.accentColor.color)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func topicLabel(_ topic: ThemeTopic) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                // Highlighted like every other search surface, so a match shows WHY it matched.
                HighlightedSnippet(
                    source: topic.name,
                    term: trimmedQuery,
                    font: .headline,
                    accent: settings.accentColor.color,
                    fg: .primary
                )

                Spacer(minLength: 8)

                // The ayah count as a pill rather than bare grey digits - it is the row's one piece of
                // quantitative information and it reads as a tag, not as trailing punctuation.
                Text("\(topic.ayahs.count)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(settings.accentColor.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(settings.accentColor.color.opacity(0.12))
                    )
            }

            if !topic.description.isEmpty {
                HighlightedSnippet(
                    source: topic.description,
                    term: trimmedQuery,
                    font: .caption,
                    accent: settings.accentColor.color,
                    fg: .secondary,
                    lineLimit: 2
                )
            }
        }
        .padding(.vertical, 2)
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

    /// The reader's OWN row, not a copy of it.
    ///
    /// This screen used to draw its own three `Text`s, which meant it quietly ignored every Arabic
    /// setting the reader honours: tajweed colours, hide-tashkeel, hide-dots, beginner mode, the
    /// chosen riwayah, the font face and size, word-by-word, which translations are on. Reading the
    /// same ayah here and in the reader gave you two different-looking verses. `AyahRow` takes only
    /// `surah` and `ayah` as required inputs, so the fix is to use it: everything else follows from
    /// the same settings, for free, and stays right when a new setting is added.
    ///
    /// The two bindings it wants are inert here - this list has no scroll target and no search - so
    /// they are constants. The row's tap opens the ayah in the reader instead of toggling the
    /// reader's highlight, which is what this screen has always done.
    @ViewBuilder
    private func ayahRow(_ key: String) -> some View {
        let parts = key.split(separator: ":").compactMap { Int($0) }
        // Both lookups indexed: `surah.ayahs.first(where:)` here was a linear walk per row, which on a
        // 267-ayah topic over Al-Baqarah's 286 ayahs is real per-frame work while the list scrolls.
        if parts.count == 2,
           let surah = quranData.surah(parts[0]),
           let ayah = quranData.ayah(surah: parts[0], ayah: parts[1]) {
            VStack(alignment: .leading, spacing: 6) {
                // Which surah this is: the reader's row carries the ayah number but not the surah,
                // and a topic list crosses all 114.
                Text("\(surah.nameTransliteration) \(parts[0]):\(parts[1])")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .frame(maxWidth: .infinity, alignment: .leading)

                AyahRow(
                    surah: surah,
                    ayah: ayah,
                    renderSettingsSignature: settings.ayahRenderSettingsSignature,
                    scrollDown: .constant(nil),
                    searchText: .constant(""),
                    onToggleHighlight: {
                        settings.hapticFeedback()
                        onOpenAyah(parts[0], parts[1])
                    }
                )
                .equatable()
            }
            .padding(.vertical, 2)
        }
    }
}
#endif
