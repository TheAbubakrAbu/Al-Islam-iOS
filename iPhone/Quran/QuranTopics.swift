#if os(iOS)
import SwiftUI

// Three more ways to find your way around the Quran, all from the Quranic Universal Library packs
// built by Scripts/build_qul_packs.py:
//   * `QuranTopicsStore`  - QuranTopics.json.xz: 2,512 topics in three families - the Clear Quran's
//                           thematic index (Doctrine, Stories, The Unseen), the Quranic Arabic
//                           Corpus ontology (concepts: Living Creation, Location, Event, ...) and a
//                           general A-Z index - each with the ayahs it annotates. Browse by Theme's
//                           other three tabs, the topic chips under an ayah, and topic search hits.
//   * `AyahThemesStore`   - AyahThemes.json.xz: 1,049 passage themes, one short sentence per run of
//                           ayahs ("Hypocrites and the consequences of hypocrisy", 2:8-16). The
//                           PASSAGE line under an ayah, a Themes source in About this Surah, and
//                           passage search hits.
//   * `QuranMetadata`     - QuranMetadata.json: the hizb, ruku and manzil boundaries. The metadata
//                           line under an ayah and the "hizb 5" / "ruku 12" / "manzil 3" searches.

// MARK: - Topics

final class QuranTopicsStore: @unchecked Sendable {
    static let shared = QuranTopicsStore()
    private init() {}

    enum Family: String, CaseIterable, Identifiable {
        /// The Clear Quran's thematic tree.
        case thematic
        /// The Quranic Arabic Corpus ontology.
        case ontology
        /// The general A-Z index.
        case index

        var id: String { rawValue }

        var title: String {
            switch self {
            case .thematic: return "Topics"
            case .ontology: return "Concepts"
            case .index: return "Index"
            }
        }

        var footnote: String {
            switch self {
            case .thematic: return "Thematic topics from The Clear Quran (Dr. Mustafa Khattab), via the Quranic Universal Library."
            case .ontology: return "Concepts from the Quranic Arabic Corpus ontology (Kais Dukes), via the Quranic Universal Library."
            case .index: return "General index from the Quranic Universal Library."
            }
        }
    }

    struct Topic: Identifiable, Hashable {
        let id: Int
        let name: String
        let arabic: String
        let parent: Int?
        let thematicParent: Int?
        let ontologyParent: Int?
        let description: String
        let wiki: String
        let isThematic: Bool
        let isOntology: Bool
        /// "surah:ayah" keys, in the corpus's order.
        let ayahs: [String]
        let related: [Int]

        static func == (lhs: Topic, rhs: Topic) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }

        var family: Family { isThematic ? .thematic : (isOntology ? .ontology : .index) }

        /// The parent link that matters for this topic's own family.
        var familyParent: Int? {
            switch family {
            case .thematic: return thematicParent
            case .ontology: return ontologyParent
            case .index: return parent
            }
        }

        /// The QSAC-shaped value the shared topic screens render.
        func asThemeTopic(parentName: String?) -> ThemeTopic {
            ThemeTopic(id: "qul-\(id)", name: name, description: description,
                       domain: family.title, category: parentName ?? "", ayahs: ayahs)
        }
    }

    struct Section: Identifiable {
        let title: String
        let topics: [Topic]
        var id: String { title }
    }

    private struct Table {
        let topics: [Topic]
        let byID: [Int: Topic]
        /// family parent id → children in id order.
        let children: [Int: [Int]]
        /// ayah key → topic ids.
        let byAyah: [String: [Int]]
    }

    private let lock = NSLock()
    private var table: Table?
    private var sectionsCache: [Family: [Section]] = [:]
    private var loadFailed = false

    static let isBundled: Bool = ThemesPack.url("QuranTopics") != nil

    func topics() -> [Topic] { loadedTable()?.topics ?? [] }

    func topic(id: Int) -> Topic? { loadedTable()?.byID[id] }

    /// The direct subtopics, in the corpus's order.
    func children(of topic: Topic) -> [Topic] {
        guard let table = loadedTable() else { return [] }
        return (table.children[topic.id] ?? []).compactMap { table.byID[$0] }
    }

    func parent(of topic: Topic) -> Topic? {
        guard let id = topic.familyParent else { return nil }
        return self.topic(id: id)
    }

    /// The path from the family's root down to the topic's parent, for a breadcrumb.
    func ancestors(of topic: Topic) -> [Topic] {
        var out: [Topic] = []
        var current = parent(of: topic)
        var seen = Set<Int>([topic.id])
        while let node = current, seen.insert(node.id).inserted {
            out.insert(node, at: 0)
            current = parent(of: node)
        }
        return out
    }

    /// Every topic annotating this ayah, thematic first, then concepts, then the index.
    func topics(forSurah surah: Int, ayah: Int) -> [Topic] {
        guard let table = loadedTable() else { return [] }
        let found = (table.byAyah["\(surah):\(ayah)"] ?? []).compactMap { table.byID[$0] }
        return found.sorted { a, b in
            if a.family != b.family { return Self.familyOrder(a.family) < Self.familyOrder(b.family) }
            return a.id < b.id
        }
    }

    private static func familyOrder(_ family: Family) -> Int {
        switch family {
        case .thematic: return 0
        case .ontology: return 1
        case .index: return 2
        }
    }

    /// The browse sections of one family, memoized: the thematic tree's second level, the
    /// ontology's roots, and the index's initial letters.
    func sections(for family: Family) -> [Section] {
        lock.lock()
        if let cached = sectionsCache[family] { lock.unlock(); return cached }
        lock.unlock()
        guard let table = loadedTable() else { return [] }

        let roots = table.topics.filter { $0.family == family && $0.familyParent == nil }
        var built: [Section] = []
        switch family {
        case .thematic:
            for root in roots {
                for child in children(of: root) {
                    let members = descendantsWithAyahs(of: child, table: table)
                    if !members.isEmpty {
                        built.append(Section(title: "\(root.name) › \(child.name)", topics: members))
                    }
                }
            }
        case .ontology:
            for root in roots {
                let members = descendantsWithAyahs(of: root, table: table)
                if !members.isEmpty {
                    built.append(Section(title: root.name, topics: members))
                }
            }
        case .index:
            var byLetter: [String: [Topic]] = [:]
            for root in roots where !root.ayahs.isEmpty || !(table.children[root.id] ?? []).isEmpty {
                let first = root.name.uppercased().first.map(String.init) ?? "#"
                let letter = first.rangeOfCharacter(from: .letters) != nil ? first : "#"
                byLetter[letter, default: []].append(root)
            }
            for letter in byLetter.keys.sorted() {
                let members = (byLetter[letter] ?? []).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                built.append(Section(title: letter, topics: members))
            }
        }

        lock.lock(); defer { lock.unlock() }
        if sectionsCache[family] == nil, !built.isEmpty { sectionsCache[family] = built }
        return sectionsCache[family] ?? built
    }

    /// The subtree under a node, depth first, keeping only the topics that annotate ayahs.
    private func descendantsWithAyahs(of node: Topic, table: Table) -> [Topic] {
        var out: [Topic] = []
        var seen = Set<Int>()
        func walk(_ topic: Topic) {
            guard seen.insert(topic.id).inserted else { return }
            if !topic.ayahs.isEmpty { out.append(topic) }
            for child in (table.children[topic.id] ?? []).compactMap({ table.byID[$0] }) {
                walk(child)
            }
        }
        walk(node)
        return out
    }

    /// Topics whose name, Arabic name or description carries the query, most-annotated first.
    func search(_ query: String, limit: Int = 12) -> [Topic] {
        let folded = Settings.shared.cleanSearch(query, whitespace: true)
        guard folded.count >= 2, let table = loadedTable() else { return [] }
        let settings = Settings.shared
        var hits = table.topics.filter { topic in
            !topic.ayahs.isEmpty && (
                settings.cleanSearch(topic.name).contains(folded)
                || (!topic.arabic.isEmpty && settings.cleanSearch(topic.arabic).contains(folded))
                || (!topic.description.isEmpty && settings.cleanSearch(topic.description).contains(folded))
            )
        }
        // Exact-name matches first, then the ones that start with the query, then by coverage.
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

    static func prewarm() {
        guard isBundled else { return }
        Task.detached(priority: .utility) { _ = QuranTopicsStore.shared.topics() }
    }

    func unload() {
        lock.lock(); defer { lock.unlock() }
        table = nil
        sectionsCache = [:]
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
        guard let root = ThemesPack.json("QuranTopics") as? [String: Any],
              let rows = root["topics"] as? [[String: Any]] else { return nil }
        var topics: [Topic] = []
        topics.reserveCapacity(rows.count)
        for row in rows {
            guard let id = row["id"] as? Int, let name = row["n"] as? String, !name.isEmpty else { continue }
            topics.append(Topic(
                id: id,
                name: name,
                arabic: row["ar"] as? String ?? "",
                parent: row["p"] as? Int,
                thematicParent: row["tp"] as? Int,
                ontologyParent: row["op"] as? Int,
                description: row["d"] as? String ?? "",
                wiki: row["w"] as? String ?? "",
                isThematic: (row["t"] as? Int ?? 0) == 1,
                isOntology: (row["o"] as? Int ?? 0) == 1,
                ayahs: row["ay"] as? [String] ?? [],
                related: row["rel"] as? [Int] ?? []
            ))
        }
        guard !topics.isEmpty else { return nil }
        topics.sort { $0.id < $1.id }
        var byID: [Int: Topic] = [:]
        var children: [Int: [Int]] = [:]
        var byAyah: [String: [Int]] = [:]
        for topic in topics {
            byID[topic.id] = topic
            if let parent = topic.familyParent { children[parent, default: []].append(topic.id) }
            for key in topic.ayahs { byAyah[key, default: []].append(topic.id) }
        }
        return Table(topics: topics, byID: byID, children: children, byAyah: byAyah)
    }
}

// MARK: - Passage themes

final class AyahThemesStore: @unchecked Sendable {
    static let shared = AyahThemesStore()
    private init() {}

    struct Theme: Identifiable, Hashable {
        let surah: Int
        let start: Int
        let end: Int
        let title: String
        let keywords: [String]

        var id: String { "\(surah):\(start)-\(end)" }
        var rangeLabel: String { start == end ? "\(surah):\(start)" : "\(surah):\(start)-\(end)" }
        var ayahCount: Int { end - start + 1 }
    }

    private let lock = NSLock()
    private var table: [Int: [Theme]]?
    private var loadFailed = false

    static let isBundled: Bool = ThemesPack.url("AyahThemes") != nil

    /// The passage an ayah sits in, or nil (two small gaps in the corpus).
    func theme(surah: Int, ayah: Int) -> Theme? {
        themes(surah: surah).first { $0.start <= ayah && ayah <= $0.end }
    }

    /// The surah's passages in order.
    func themes(surah: Int) -> [Theme] {
        loadedTable()?[surah] ?? []
    }

    /// Passages whose sentence carries the query, in mushaf order.
    func search(_ query: String, limit: Int = 10) -> [Theme] {
        let folded = Settings.shared.cleanSearch(query, whitespace: true)
        guard folded.count >= 3, let table = loadedTable() else { return [] }
        var hits: [Theme] = []
        for surah in table.keys.sorted() {
            for theme in table[surah] ?? [] where Settings.shared.cleanSearch(theme.title).contains(folded) {
                hits.append(theme)
                if hits.count >= limit { return hits }
            }
        }
        return hits
    }

    /// The surah's passages as an outline, in the markdown the About this Surah sheet renders.
    func outlineMarkdown(surah: Int) -> String? {
        let rows = themes(surah: surah)
        guard !rows.isEmpty else { return nil }
        var lines: [String] = []
        for theme in rows {
            let range = theme.start == theme.end ? "Ayah \(theme.start)" : "Ayahs \(theme.start)-\(theme.end)"
            lines.append("**\(range)**: \(theme.title)")
        }
        lines.append("")
        lines.append("_Passage themes from the Quranic Universal Library._")
        return lines.joined(separator: "\n\n")
    }

    func unload() {
        lock.lock(); defer { lock.unlock() }
        table = nil
        loadFailed = false
    }

    private func loadedTable() -> [Int: [Theme]]? {
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

    private static func load() -> [Int: [Theme]]? {
        guard let root = ThemesPack.json("AyahThemes") as? [String: Any],
              let rows = root["themes"] as? [String: [[Any]]] else { return nil }
        var out: [Int: [Theme]] = [:]
        for (key, entries) in rows {
            guard let surah = Int(key) else { continue }
            let themes = entries.compactMap { entry -> Theme? in
                guard entry.count >= 3, let start = entry[0] as? Int, let end = entry[1] as? Int,
                      let title = entry[2] as? String, !title.isEmpty else { return nil }
                let keywords = (entry.count > 3 ? entry[3] as? String : nil)?
                    .split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } ?? []
                return Theme(surah: surah, start: start, end: end, title: title, keywords: keywords)
            }
            if !themes.isEmpty { out[surah] = themes.sorted { ($0.start, $0.end) < ($1.start, $1.end) } }
        }
        return out.isEmpty ? nil : out
    }
}

// MARK: - Hizb, ruku, manzil

/// The mushaf's other divisions. Boundaries are (surah, ayah) pairs, which order exactly like the
/// mushaf, so a lookup is a binary search over them - no global ayah table needed.
enum QuranMetadata {
    struct Boundary: Comparable {
        let surah: Int
        let ayah: Int
        static func < (lhs: Boundary, rhs: Boundary) -> Bool {
            lhs.surah != rhs.surah ? lhs.surah < rhs.surah : lhs.ayah < rhs.ayah
        }
    }

    enum Division: String, CaseIterable {
        case hizb, ruku, manzil

        var title: String {
            switch self {
            case .hizb: return "Hizb"
            case .ruku: return "Ruku"
            case .manzil: return "Manzil"
            }
        }
    }

    private struct Table {
        let boundaries: [Division: [Boundary]]
    }

    private static let table: Table? = load()

    static var isBundled: Bool { table != nil }

    /// The 1-based number of the division holding the ayah.
    static func number(of division: Division, surah: Int, ayah: Int) -> Int? {
        guard let boundaries = table?.boundaries[division], !boundaries.isEmpty else { return nil }
        let target = Boundary(surah: surah, ayah: ayah)
        // The last boundary at or before the ayah.
        var low = 0, high = boundaries.count - 1, found = -1
        while low <= high {
            let mid = (low + high) / 2
            if boundaries[mid] <= target { found = mid; low = mid + 1 } else { high = mid - 1 }
        }
        return found >= 0 ? found + 1 : nil
    }

    static func count(of division: Division) -> Int {
        table?.boundaries[division]?.count ?? 0
    }

    /// The first ayah of a division, and the first ayah of the next one (nil past the last).
    static func range(of division: Division, number: Int) -> (start: Boundary, next: Boundary?)? {
        guard let boundaries = table?.boundaries[division], (1...boundaries.count).contains(number) else { return nil }
        let next = number < boundaries.count ? boundaries[number] : nil
        return (boundaries[number - 1], next)
    }

    /// "Juz 1 · Hizb 1 · Ruku 1 · Manzil 1 · Page 1" for one ayah, from what is known about it.
    static func caption(for ayah: Ayah, surah: Int) -> String {
        var parts: [String] = []
        if let juz = ayah.juz { parts.append("Juz \(juz)") }
        if let hizb = number(of: .hizb, surah: surah, ayah: ayah.id) { parts.append("Hizb \(hizb)") }
        if let ruku = number(of: .ruku, surah: surah, ayah: ayah.id) { parts.append("Ruku \(ruku)") }
        if let manzil = number(of: .manzil, surah: surah, ayah: ayah.id) { parts.append("Manzil \(manzil)") }
        if let page = ayah.page { parts.append("Page \(page)") }
        return parts.joined(separator: " · ")
    }

    private static func load() -> Table? {
        guard let url = Bundle.main.url(forResource: "QuranMetadata", withExtension: "json", subdirectory: "Data/Quran")
                ?? Bundle.main.url(forResource: "QuranMetadata", withExtension: "json", subdirectory: "Quran")
                ?? Bundle.main.url(forResource: "QuranMetadata", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        var boundaries: [Division: [Boundary]] = [:]
        for division in Division.allCases {
            guard let keys = root[division.rawValue] as? [String] else { return nil }
            let parsed = keys.compactMap { key -> Boundary? in
                let parts = key.split(separator: ":").compactMap { Int($0) }
                guard parts.count == 2 else { return nil }
                return Boundary(surah: parts[0], ayah: parts[1])
            }
            guard parsed.count == keys.count, parsed == parsed.sorted() else { return nil }
            boundaries[division] = parsed
        }
        return Table(boundaries: boundaries)
    }
}

// MARK: - What an ayah is about: passage, topics, place in the mushaf

/// The insight rows under an ayah in its actions sheet: the passage it belongs to, where it sits in
/// the mushaf's divisions, and the topics that annotate it (each a push to the topic's ayahs).
struct AyahInsightsCard: View {
    @ObservedObject private var settings = Settings.shared

    let surah: Surah
    let ayah: Ayah

    /// QSAC and QUL topics together, QSAC first (the app's own Browse by Theme corpus).
    private var topics: [ThemeTopic] {
        var out: [ThemeTopic] = ThematicTopicsStore.shared.topics(forSurah: surah.id, ayah: ayah.id)
        for topic in QuranTopicsStore.shared.topics(forSurah: surah.id, ayah: ayah.id) {
            let parentName = QuranTopicsStore.shared.parent(of: topic)?.name
            out.append(topic.asThemeTopic(parentName: parentName))
        }
        return out
    }

    private var passage: AyahThemesStore.Theme? {
        AyahThemesStore.shared.theme(surah: surah.id, ayah: ayah.id)
    }

    var body: some View {
        let passage = passage
        let topics = topics
        let caption = QuranMetadata.caption(for: ayah, surah: surah.id)

        if passage != nil || !topics.isEmpty || !caption.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                if let passage {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("PASSAGE")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(passage.rangeLabel)
                                .font(.caption2.weight(.semibold).monospacedDigit())
                                .foregroundColor(settings.accentColor.color)
                            if passage.ayahCount > 1 {
                                Text("· \(passage.ayahCount) ayahs")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Text(passage.title)
                            .font(.subheadline.weight(.medium))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !caption.isEmpty {
                    Label(caption, systemImage: "map")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                if !topics.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TOPICS")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TopicChipFlow(topics: topics)
                    }
                }
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
}

/// Topic chips that wrap onto as many lines as they need, each pushing the topic's ayahs.
struct TopicChipFlow: View {
    @ObservedObject private var settings = Settings.shared

    let topics: [ThemeTopic]

    var body: some View {
        FlowLayoutView(spacing: 6) {
            ForEach(topics) { topic in
                NavigationLink {
                    ThemeTopicDetailView(topic: topic, onOpenAyah: nil)
                } label: {
                    HStack(spacing: 4) {
                        Text(topic.name)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                        Text("\(topic.ayahs.count)")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(settings.accentColor.color.opacity(0.12)))
                    .foregroundColor(settings.accentColor.color)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// A wrapping row of chips. iOS 16 has `Layout`; below it the chips fall back to a plain column.
struct FlowLayoutView<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 16.0, *) {
            FlowLayout(spacing: spacing) { content() }
        } else {
            VStack(alignment: .leading, spacing: spacing) { content() }
        }
    }
}

@available(iOS 16.0, *)
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, x - spacing)
        }
        return CGSize(width: width == .infinity ? maxX : width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
#endif
