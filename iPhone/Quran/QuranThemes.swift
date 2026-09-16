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
    /// ayah key → indices into `topics()`, built once on first use (the insights card under an ayah).
    private var byAyahCache: [String: [Int]]?
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

    /// Every topic annotating this ayah, in corpus order.
    func topics(forSurah surah: Int, ayah: Int) -> [ThemeTopic] {
        let all = topics()
        guard !all.isEmpty else { return [] }
        lock.lock()
        if byAyahCache == nil {
            var index: [String: [Int]] = [:]
            for (offset, topic) in all.enumerated() {
                for key in topic.ayahs { index[key, default: []].append(offset) }
            }
            byAyahCache = index
        }
        let hits = byAyahCache?["\(surah):\(ayah)"] ?? []
        lock.unlock()
        return hits.compactMap { all.indices.contains($0) ? all[$0] : nil }
    }

    /// Topics whose name, category or description carries the query, exact names first.
    func search(_ query: String, limit: Int = 12) -> [ThemeTopic] {
        let settings = Settings.shared
        let folded = settings.cleanSearch(query, whitespace: true)
        guard folded.count >= 2 else { return [] }
        var hits = topics().filter { topic in
            settings.cleanSearch(topic.name).contains(folded)
                || settings.cleanSearch(topic.category).contains(folded)
                || settings.cleanSearch(topic.description).contains(folded)
        }
        hits.sort { a, b in
            let an = settings.cleanSearch(a.name), bn = settings.cleanSearch(b.name)
            let aExact = an == folded, bExact = bn == folded
            if aExact != bExact { return aExact }
            let aPrefix = an.hasPrefix(folded), bPrefix = bn.hasPrefix(folded)
            if aPrefix != bPrefix { return aPrefix }
            return a.ayahs.count > b.ayahs.count
        }
        return Array(hits.prefix(limit))
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

/// One passage of a surah's outline (Quranpedia, via Tilawa): where it runs and what it is about.
struct SurahSection: Identifiable, Hashable {
    /// "<surah>:<order>": two passages can share a range (surah 18's two "Two Gardens" rows), so the
    /// position in the outline is the identity.
    let id: String
    let surahID: Int
    let order: Int
    let ayahStart: Int
    let ayahEnd: Int
    let title: String
    let titleArabic: String

    var ayahCount: Int { ayahEnd - ayahStart + 1 }

    /// "Ayahs 7-18", or "Ayah 3".
    var rangeLabel: String {
        ayahStart == ayahEnd ? "Ayah \(ayahStart)" : "Ayahs \(ayahStart)-\(ayahEnd)"
    }

    func contains(ayah: Int) -> Bool {
        (ayahStart...ayahEnd).contains(ayah)
    }
}

final class SurahSectionsStore: @unchecked Sendable {
    static let shared = SurahSectionsStore()
    private init() {}

    private let lock = NSLock()
    private var table: [String: Any]?
    private var loadFailed = false
    /// The structured passages per surah, and their legend colours, built once each.
    private var sectionsBySurah: [Int: [SurahSection]] = [:]
    private var colorsBySurah: [Int: [String: ThemeWashColor]] = [:]
    private var allSectionsCache: [SurahSection]?

    static let isBundled: Bool = ThemesPack.url("SurahSections") != nil

    /// The surah's passages in outline order, or [] when it has none.
    func sections(surah: Int) -> [SurahSection] {
        lock.lock()
        if let cached = sectionsBySurah[surah] { lock.unlock(); return cached }
        lock.unlock()
        let rows = (loadedTable()?["\(surah)"] as? [String: Any])?["sections"] as? [[Any]] ?? []
        var sections: [SurahSection] = []
        for row in rows {
            guard row.count >= 4, let start = row[0] as? Int, let end = row[1] as? Int, end >= start else { continue }
            sections.append(SurahSection(
                id: "\(surah):\(sections.count)",
                surahID: surah,
                order: sections.count,
                ayahStart: start,
                ayahEnd: end,
                title: (row[2] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
                titleArabic: (row[3] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }
        lock.lock(); defer { lock.unlock() }
        if sectionsBySurah[surah] == nil { sectionsBySurah[surah] = sections }
        return sectionsBySurah[surah] ?? sections
    }

    /// Every passage of every surah (741 of them), mushaf order.
    func allSections() -> [SurahSection] {
        lock.lock()
        if let cached = allSectionsCache { lock.unlock(); return cached }
        lock.unlock()
        let all = (1...114).flatMap { sections(surah: $0) }
        lock.lock(); defer { lock.unlock() }
        if allSectionsCache == nil, !all.isEmpty { allSectionsCache = all }
        return all
    }

    func section(id: String) -> SurahSection? {
        let parts = id.split(separator: ":")
        guard parts.count == 2, let surah = Int(parts[0]), let order = Int(parts[1]) else { return nil }
        let list = sections(surah: surah)
        return list.indices.contains(order) ? list[order] : nil
    }

    /// The passages naming this ayah, narrowest first (an outline can nest a passage in a passage).
    func sections(surah: Int, ayah: Int) -> [SurahSection] {
        sections(surah: surah).filter { $0.contains(ayah: ayah) }.sorted { $0.ayahCount < $1.ayahCount }
    }

    /// The passage's legend colour (`ThemeColorGuide`), classified once per surah.
    func color(for section: SurahSection) -> ThemeWashColor {
        lock.lock()
        if let cached = colorsBySurah[section.surahID]?[section.id] { lock.unlock(); return cached }
        lock.unlock()
        let colors = ThemeColorGuide.colors(forSections: sections(surah: section.surahID))
        lock.lock(); defer { lock.unlock() }
        if colorsBySurah[section.surahID] == nil { colorsBySurah[section.surahID] = colors }
        return colorsBySurah[section.surahID]?[section.id] ?? .signs
    }

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
        PackTrace.measure(name) { () -> (result: Any?, bytes: Int) in
            guard let json = data(name) else { return (nil, 0) }
            return (try? JSONSerialization.jsonObject(with: json), json.count)
        }
    }

    /// The inflated JSON bytes of a pack, for a store that parses (and measures) them itself.
    static func data(_ name: String) -> Data? {
        guard let url = url(name),
              let blob = try? Data(contentsOf: url) else { return nil }
        return inflate(blob)
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
/// The four corpora Browse by Theme walks: the app's QSAC themes, and the Quranic Universal
/// Library's thematic topics, concepts and A-Z index (see `QuranTopicsStore`).
enum ThemeBrowseFamily: String, CaseIterable, Identifiable {
    case themes, topics, concepts, index

    var id: String { rawValue }

    var title: String {
        switch self {
        case .themes: return "Themes"
        case .topics: return "Topics"
        case .concepts: return "Concepts"
        case .index: return "Index"
        }
    }

    var qulFamily: QuranTopicsStore.Family? {
        switch self {
        case .themes: return nil
        case .topics: return .thematic
        case .concepts: return .ontology
        case .index: return .index
        }
    }

    var footnote: String {
        qulFamily?.footnote ?? "Topics from the Quran Semantic Annotation Corpus (CC BY 4.0)."
    }

    var searchPlaceholder: String {
        switch self {
        case .themes: return "Search themes"
        case .topics: return "Search topics"
        case .concepts: return "Search concepts"
        case .index: return "Search the index"
        }
    }
}

struct ThemesBrowseView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var themeHighlights = ThemeHighlights.shared

    let onOpenAyah: (Int, Int) -> Void

    @State private var searchText = ""
    /// Which corpus the list shows. The QSAC themes are the app's own and open first; the other
    /// three exist only while the QUL topics pack is bundled.
    @State private var family: ThemeBrowseFamily = .themes
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

    /// The memoized store grouping of the chosen family, filtered in the view (the store's comment:
    /// never re-group per render). Searching matches a topic's name, description, category, or its
    /// domain's name.
    private var displayedGroups: [(domain: String, topics: [ThemeTopic])] {
        let groups: [(domain: String, topics: [ThemeTopic])]
        if let qul = family.qulFamily {
            let store = QuranTopicsStore.shared
            groups = store.sections(for: qul).map { section in
                (section.title, section.topics.map { $0.asThemeTopic(parentName: store.parent(of: $0)?.name) })
            }
        } else {
            groups = ThematicTopicsStore.shared.topicsByDomain()
        }
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
            // What this screen is, said here rather than as a caption on the door that opens it
            // (Abu, 2026-09-07). Hidden while searching - the results are the answer then.
            if !isSearching {
                Section {
                    Text(verbatim: "Ayahs grouped by what they speak about. Open a subject to read its ayahs, and light it up to see it marked in the reader as you read.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // The passages and the legend: every theme here is lit in its meaning's colour, and
                    // that screen says what the colours mean and washes whole surahs by passage.
                    NavigationLink(destination: LazyDestination { ThemeHighlightsView(onOpenAyah: onOpenAyah) }) {
                        HStack(spacing: 12) {
                            ThemeLegendChip(size: 30)

                            VStack(alignment: .leading, spacing: 1) {
                                Text("Highlight Themes")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.primary)
                                Text(themeHighlights.summary == "Off" ? "Color-coded passages and what each color means" : themeHighlights.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 3)
                    }
                    .tint(settings.accentColor.color)
                }
            }

            // The four corpora as one segmented switch: the app's themes, then the Quranic Universal
            // Library's thematic topics, concepts and A-Z index. Only with the QUL pack bundled.
            if QuranTopicsStore.isBundled {
                Section {
                    Picker("Corpus", selection: $family) {
                        ForEach(ThemeBrowseFamily.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: family) { _ in
                        settings.hapticFeedback()
                        collapsedDomains.removeAll()
                        showAllDomains.removeAll()
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    .listRowBackground(Color.clear)
                }
            }

            // What is lit in the reader right now, with a way to put each one (or all) out.
            if !isSearching, !themeHighlights.lit.isEmpty {
                Section(header: HStack {
                    Text("LIT IN THE READER")
                    Spacer()
                    Button("Clear All") {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { themeHighlights.clear() }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                }) {
                    ForEach(themeHighlights.lit) { theme in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(theme.color.color)
                                .frame(width: 12, height: 12)
                            Text(theme.name)
                                .font(.subheadline)
                            Spacer()
                            Text("\(theme.count)")
                                .font(.caption.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.secondary)
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) { themeHighlights.remove(theme.id) }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Put out \(theme.name)")
                        }
                    }
                }
            }

            ForEach(groups, id: \.domain) { group in
                themeSection(group, isSearching: isSearching)
            }

            if isSearching && groups.isEmpty {
                Section {
                    Text("Nothing here matches your search.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // The credits hide while searching, the app's convention for trailing footers.
            if !isSearching {
                Section(footer:
                    Text(family.footnote)
                        .font(.caption2)
                ) { EmptyView() }
            }
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        #if DEBUG
        // "-openThemeTopic" pushes the first topic on launch, so the ayah rows (which are the reader's
        // own AyahRow) can be verified headlessly. Through the List's own destination (see
        // `DebugPushDestination`), never a hidden link row. DEBUG builds only.
        .debugPushDestination(isPresented: $debugOpenFirstTopic) {
            if let first = displayedGroups.first?.topics.first {
                ThemeTopicDetailView(topic: first, onOpenAyah: onOpenAyah)
            }
        }
        .onAppear {
            // "-themesFamily topics|concepts|index" opens that corpus, for headless screenshots.
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-themesFamily"), i + 1 < args.count,
               let wanted = ThemeBrowseFamily(rawValue: args[i + 1]) {
                family = wanted
            }
            guard Self.debugWantsTopic else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { debugOpenFirstTopic = true }
        }
        #endif
        .dismissKeyboardOnScroll()
        // The app's own bottom search bar, not `.searchable` - the same inset the surah picker and
        // the Quran/Hadith readers use, so every search in the app sits in the same place.
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut), placeholder: family.searchPlaceholder)
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
                // The meaning's colour, the colour the theme lights up in (Tilawa's category dot).
                Circle()
                    .fill(ThemeColorGuide.color(for: topic).color)
                    .frame(width: 10, height: 10)

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

/// One topic's ayahs: the app's QSAC themes and the QUL topics alike (a QUL topic's id carries the
/// "qul-" prefix, and its Arabic name, subtopics, related topics and reference link come from
/// `QuranTopicsStore`). Pushed from Browse by Theme (rows open the reader through `onOpenAyah`) and
/// from the topic chips under an ayah in its sheets (no reader to open there: `onOpenAyah` is nil,
/// and the rows keep their own menus).
struct ThemeTopicDetailView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var themeHighlights = ThemeHighlights.shared

    let topic: ThemeTopic
    let onOpenAyah: ((Int, Int) -> Void)?
    /// The rows' sheet host (Phase 5 step 6): the reader's row presents nothing itself any more.
    @State private var rowSheet: AyahRowSheetRequest?

    /// The QUL topic behind a "qul-N" id, for the extras the QSAC rows do not have.
    private var qulTopic: QuranTopicsStore.Topic? {
        guard topic.id.hasPrefix("qul-"), let id = Int(topic.id.dropFirst(4)) else { return nil }
        return QuranTopicsStore.shared.topic(id: id)
    }

    var body: some View {
        let qul = qulTopic
        let store = QuranTopicsStore.shared
        let subtopics = qul.map { store.children(of: $0) } ?? []
        let related = qul.map { $0.related.compactMap { store.topic(id: $0) } } ?? []
        let ancestors = qul.map { store.ancestors(of: $0) } ?? []

        List {
            if !topic.description.isEmpty || qul != nil {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        if let qul, !qul.arabic.isEmpty {
                            Text(qul.arabic)
                                .font(.custom(settings.quranArabicFontName(for: nil), size: 24))
                                .arabicFontDesign(custom: true)
                                .foregroundColor(settings.accentColor.color)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        if !ancestors.isEmpty {
                            Text((["\(topic.domain)"] + ancestors.map(\.name)).joined(separator: " › "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if !topic.description.isEmpty {
                            Text(topic.description)
                                .font(.body)
                        }
                        if let qul, !qul.wiki.isEmpty, let url = URL(string: qul.wiki) {
                            Link(destination: url) {
                                Label("Read more on Wikipedia", systemImage: "safari")
                                    .font(.caption.weight(.medium))
                            }
                            .tint(settings.accentColor.color)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            // Light the theme in the reader: every ayah it names takes a faint wash of one color, in
            // both readers, until it is put out here or in Browse by Theme.
            if !topic.ayahs.isEmpty {
                let color = themeHighlights.color(for: topic.id) ?? ThemeColorGuide.color(for: topic)
                let isLit = themeHighlights.isLit(topic.id)
                Section {
                    Toggle(isOn: Binding(
                        get: { themeHighlights.isLit(topic.id) },
                        set: { _ in
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) { themeHighlights.toggle(topic) }
                        }
                    )) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 14, height: 14)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Highlight in the Reader")
                                    .font(.subheadline.weight(.semibold))
                                Text(isLit
                                     ? "Lit in \(color.name) (\(color.meaning.lowercased())) across \(topic.ayahs.count) ayahs"
                                     : "A faint \(color.name) wash, the color of \(color.meaning.lowercased()), on its \(topic.ayahs.count) ayahs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(settings.accentColor.color)
                } footer: {
                    Text("Up to \(ThemeHighlights.limit) themes can be lit at once, each in the color of what it speaks about, in the list and page readers. Put them out here, at the top of Browse by Theme, or under Highlight Themes, which also says what every color means.")
                        .font(.caption)
                }
            }

            if !subtopics.isEmpty {
                Section(header: SectionPillHeader(title: "SUBTOPICS", count: subtopics.count)) {
                    ForEach(subtopics) { child in
                        NavigationLink {
                            ThemeTopicDetailView(topic: child.asThemeTopic(parentName: topic.name), onOpenAyah: onOpenAyah)
                        } label: {
                            HStack {
                                Text(child.name)
                                    .font(.subheadline)
                                Spacer()
                                if !child.ayahs.isEmpty {
                                    Text("\(child.ayahs.count)")
                                        .font(.caption.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(settings.accentColor.color)
                                }
                            }
                        }
                    }
                }
            }

            if !related.isEmpty {
                Section(header: Text("RELATED")) {
                    TopicChipFlow(topics: related.map { $0.asThemeTopic(parentName: store.parent(of: $0)?.name) })
                        .padding(.vertical, 4)
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
        .sheet(item: $rowSheet) { request in
            AyahRowSheetContent(
                request: request,
                onRequestSecondary: { kind in
                    rowSheet = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        rowSheet = AyahRowSheetRequest(surah: request.surah, ayah: request.ayah, kind: .secondary(kind))
                    }
                },
                onDismiss: { rowSheet = nil }
            )
        }
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
                    onToggleHighlight: onOpenAyah.map { open in
                        {
                            settings.hapticFeedback()
                            open(parts[0], parts[1])
                        }
                    },
                    onRequestSheet: { kind in
                        rowSheet = AyahRowSheetRequest(surah: surah, ayah: ayah, kind: kind)
                    },
                    openSheet: (rowSheet?.surah.id == surah.id && rowSheet?.ayah.id == ayah.id) ? rowSheet?.kind : nil
                )
                .equatable()
            }
            .padding(.vertical, 2)
        }
    }
}
#endif
