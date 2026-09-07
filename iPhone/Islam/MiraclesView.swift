#if os(iOS)
import SwiftUI
import ImageIO
import UIKit

// Miracles of the Quran: the miracles-of-quran.com library (202 articles across fifteen subjects),
// ported from the Tilawa app by Jamil Hammoudeh, with permission. The data is
// `Resources/Data/Islam/Miracles.json.xz` (Scripts/build_miracles_pack.py): the site's own prose, which
// it waives copyright on; third-party excerpts trimmed at import to a short attributed quote that links
// out; Quran verses as references, drawn from the app's own text here so the mushaf face, the tashkeel
// choices and the Saheeh International translation match the rest of the app; and the illustrations
// (mostly animated diagrams) fetched from Tilawa's CDN on demand rather than bundled (about 100 MB).
//
// The genre (i'jaz 'ilmi) is uneven, and the library says so: the index carries a note that these are
// one site's arguments, not tafsir, and that the meaning of an ayah rests with the classical scholars.

// MARK: - Model

struct MiracleLink: Hashable {
    let label: String
    var slug: String? = nil
    var category: String? = nil
    var url: String? = nil
}

enum MiracleBlock {
    /// The one line the article argues ("Have roots."), set large under the title.
    case claim(String, [MiracleLink])
    /// The opening paragraph, a shade heavier than the body.
    case lead(String, [MiracleLink])
    case text(String, [MiracleLink])
    /// The rhetorical line the article closes on.
    case closer(String, [MiracleLink])
    /// A cited verse or short range; the text comes from `QuranData` at render time.
    case ayah(surah: Int, ayah: Int, endAyah: Int?)
    /// A trimmed excerpt from another publisher, with its source.
    case quote(text: String, sourceLabel: String, sourceURL: String)
    /// An illustration on the CDN; `alt` is the site's caption (often its page builder's default).
    case image(path: String, alt: String)
}

enum MiracleLevel: String, CaseIterable, Identifiable {
    case simple, intermediate, advanced

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    /// The source site grades one physiology article "extreme"; it folds into Advanced rather than
    /// earning a tier of its own.
    init(sourceValue: String) {
        self = MiracleLevel(rawValue: sourceValue == "extreme" ? "advanced" : sourceValue) ?? .intermediate
    }
}

/// ORDER IS THE INDEX: grouped by how much background a subject assumes, easiest first, which is how
/// the source site sequences them and the right order for someone browsing rather than searching.
enum MiracleCategory: String, CaseIterable, Identifiable {
    case history, egyptology, zoology, botany, mathematics
    case biology, physiology, geology, hydrology, meteorology
    case embryology, chemistry, physics, astronomy, cosmology

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var level: MiracleLevel {
        switch self {
        case .history, .egyptology, .zoology, .botany, .mathematics: return .simple
        case .biology, .physiology, .geology, .hydrology, .meteorology: return .intermediate
        case .embryology, .chemistry, .physics, .astronomy, .cosmology: return .advanced
        }
    }

    var systemImage: String {
        switch self {
        case .history: return "scroll"
        case .egyptology: return "building.columns"
        case .zoology: return "pawprint"
        case .botany: return "leaf"
        case .mathematics: return "number"
        case .biology: return "allergens"
        case .physiology: return "heart"
        case .geology: return "square.stack.3d.up"
        case .hydrology: return "drop"
        case .meteorology: return "cloud.rain"
        case .embryology: return "figure.and.child.holdinghands"
        case .chemistry: return "flame"
        case .physics: return "bolt"
        case .astronomy: return "star"
        case .cosmology: return "sparkles"
        }
    }
}

struct MiracleArticle: Identifiable {
    let slug: String
    let title: String
    let category: MiracleCategory
    let level: MiracleLevel
    let blocks: [MiracleBlock]
    /// The claim line, or the first sentence of the opening paragraph: what a list row shows under the
    /// title, because "Mountains" says nothing and "Have roots" says the whole argument.
    let summary: String
    /// Title and summary, folded once for the library search.
    let searchKey: String

    var id: String { slug }

    init(slug: String, title: String, category: MiracleCategory, level: MiracleLevel, blocks: [MiracleBlock]) {
        self.slug = slug
        self.title = title
        self.category = category
        self.level = level
        self.blocks = blocks
        var summary = ""
        for block in blocks {
            if case .claim(let text, _) = block { summary = text; break }
        }
        if summary.isEmpty {
            for block in blocks {
                switch block {
                case .lead(let text, _), .text(let text, _):
                    summary = Self.firstSentence(of: text)
                default:
                    continue
                }
                if !summary.isEmpty { break }
            }
        }
        self.summary = summary
        self.searchKey = IslamArticles.fold(title + " " + summary)
    }

    private static func firstSentence(of text: String) -> String {
        var end = text.endIndex
        for (index, character) in zip(text.indices, text) where ".!?".contains(character) {
            let next = text.index(after: index)
            if next == text.endIndex || text[next].isWhitespace { end = next; break }
        }
        let sentence = String(text[..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
        if sentence.count > 120 {
            return String(sentence.prefix(117)).trimmingCharacters(in: .whitespaces) + "…"
        }
        return sentence
    }

    /// The whole article as plain text, for copying and sharing: every block in reading order, quotes
    /// with their source (an excerpt that travels without its attribution stops being a citation),
    /// verses with their reference in the app's own wording.
    func plainText(quranData: QuranData) -> String {
        var parts: [String] = [title]
        for block in blocks {
            switch block {
            case .claim(let text, _), .lead(let text, _), .text(let text, _), .closer(let text, _):
                parts.append(text)
            case .ayah(let surah, let first, let endAyah):
                let last = min(endAyah ?? first, first + 4)
                var lines: [String] = []
                for number in first...last {
                    guard let ayah = quranData.ayah(surah: surah, ayah: number) else { continue }
                    lines.append(ayah.displayArabicText(surahId: surah, clean: false, qiraahOverride: ""))
                    lines.append(ayah.textEnglishSaheeh)
                }
                guard !lines.isEmpty else { break }
                let name = quranData.surah(surah)?.nameTransliteration ?? "Surah \(surah)"
                lines.append(last > first ? "\(name) \(surah):\(first)-\(last)" : "\(name) \(surah):\(first)")
                parts.append(lines.joined(separator: "\n"))
            case .quote(let text, let sourceLabel, let sourceURL):
                let source = [sourceLabel, sourceURL].filter { !$0.isEmpty }.joined(separator: ", ")
                parts.append(source.isEmpty ? text : "\(text)\n(\(source))")
            case .image:
                break
            }
        }
        parts.append("Shared from \(AppIdentifiers.appName)")
        return parts.joined(separator: "\n\n")
    }
}

// MARK: - Store

/// Same load pattern as `SimilarAyahsStore`: lazy, lock-guarded, parsed off the hot path on first use.
final class MiraclesStore: @unchecked Sendable {
    static let shared = MiraclesStore()
    private init() {}

    struct Library {
        let articles: [MiracleArticle]
        let bySlug: [String: MiracleArticle]
        let imageBase: URL?

        func articles(in category: MiracleCategory) -> [MiracleArticle] {
            articles.filter { $0.category == category }
        }

        func count(in category: MiracleCategory) -> Int {
            articles.reduce(0) { $0 + ($1.category == category ? 1 : 0) }
        }
    }

    private let lock = NSLock()
    private var loaded: Library?
    private var loadFailed = false

    static let isBundled: Bool = packURL() != nil

    func library() -> Library? {
        lock.lock()
        if let loaded { lock.unlock(); return loaded }
        if loadFailed { lock.unlock(); return nil }
        lock.unlock()

        guard let parsed = Self.load() else {
            lock.lock(); loadFailed = true; lock.unlock()
            return nil
        }
        lock.lock(); defer { lock.unlock() }
        if let loaded { return loaded }
        loaded = parsed
        return parsed
    }

    func article(slug: String) -> MiracleArticle? {
        library()?.bySlug[slug]
    }

    func imageURL(path: String) -> URL? {
        library()?.imageBase.map { $0.appendingPathComponent(path) }
    }

    func unload() {
        lock.lock(); defer { lock.unlock() }
        loaded = nil
        loadFailed = false
    }

    private static func packURL() -> URL? {
        Bundle.main.url(forResource: "Miracles", withExtension: "json.xz", subdirectory: "Data/Islam")
            ?? Bundle.main.url(forResource: "Miracles", withExtension: "json.xz", subdirectory: "Islam")
            ?? Bundle.main.url(forResource: "Miracles", withExtension: "json.xz")
    }

    private static func load() -> Library? {
        guard let url = packURL(),
              let blob = try? Data(contentsOf: url),
              let json = SolidPack.xzDecompress(blob),
              let root = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any],
              let rows = root["articles"] as? [[String: Any]] else { return nil }

        var articles: [MiracleArticle] = []
        articles.reserveCapacity(rows.count)
        for row in rows {
            guard let slug = row["slug"] as? String,
                  let title = row["title"] as? String,
                  let categoryRaw = row["category"] as? String,
                  let category = MiracleCategory(rawValue: categoryRaw),
                  let levelRaw = row["level"] as? String,
                  let rawBlocks = row["blocks"] as? [[String: Any]] else { continue }
            let blocks = rawBlocks.compactMap(parseBlock)
            guard !blocks.isEmpty else { continue }
            articles.append(MiracleArticle(slug: slug, title: title, category: category,
                                           level: MiracleLevel(sourceValue: levelRaw), blocks: blocks))
        }
        guard !articles.isEmpty else { return nil }
        let bySlug = Dictionary(articles.map { ($0.slug, $0) }, uniquingKeysWith: { first, _ in first })
        let imageBase = (root["imageBase"] as? String).flatMap(URL.init(string:))
        return Library(articles: articles, bySlug: bySlug, imageBase: imageBase)
    }

    private static func parseBlock(_ raw: [String: Any]) -> MiracleBlock? {
        guard let kind = raw["kind"] as? String else { return nil }
        switch kind {
        case "claim", "lead", "text", "closer":
            guard let text = raw["text"] as? String, !text.isEmpty else { return nil }
            let links = (raw["links"] as? [[String: Any]] ?? []).compactMap { link -> MiracleLink? in
                guard let label = link["label"] as? String, !label.isEmpty else { return nil }
                return MiracleLink(label: label, slug: link["slug"] as? String,
                                   category: link["category"] as? String, url: link["url"] as? String)
            }
            switch kind {
            case "claim": return .claim(text, links)
            case "lead": return .lead(text, links)
            case "closer": return .closer(text, links)
            default: return .text(text, links)
            }
        case "ayah":
            guard let surah = raw["surah"] as? Int, let ayah = raw["ayah"] as? Int else { return nil }
            return .ayah(surah: surah, ayah: ayah, endAyah: raw["endAyah"] as? Int)
        case "quote":
            guard let text = raw["text"] as? String, !text.isEmpty else { return nil }
            return .quote(text: text, sourceLabel: raw["sourceLabel"] as? String ?? "",
                          sourceURL: raw["sourceUrl"] as? String ?? "")
        case "image":
            guard let path = raw["path"] as? String, !path.isEmpty else { return nil }
            var alt = raw["alt"] as? String ?? ""
            // The site's page builder stamps its own name on captionless images.
            if alt == "Mobirise" { alt = "" }
            return .image(path: path, alt: alt)
        default:
            return nil
        }
    }
}

// MARK: - The library

/// The door into the library: browse by subject (grouped by the background it assumes) or search,
/// because 202 articles need both.
struct MiraclesView: View {
    @ObservedObject private var settings = Settings.shared

    @State private var library: MiraclesStore.Library?
    @State private var searchText = ""
    @State private var barsCollapsed = false
    #if DEBUG
    @State private var debugArticle: MiracleArticle?
    @State private var debugOpen = false
    #endif

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Every term has to hit, so "mountain root" finds the one article that "mountain" alone would bury.
    private var results: [MiracleArticle] {
        guard let library else { return [] }
        let terms = IslamArticles.fold(query).split(separator: " ").map(String.init)
        guard !terms.isEmpty else { return [] }
        return library.articles.filter { article in terms.allSatisfy { article.searchKey.contains($0) } }
    }

    var body: some View {
        List {
            if let library {
                if query.isEmpty {
                    Section {
                        Text("Two hundred short articles arguing that the Quran describes the world as science and history later found it: mountains with roots, the expanding universe, the stages of the embryo. Each argument is the site's own; the meaning of an ayah rests with the classical scholars of tafsir, and a scientific claim can move on. Read them as invitations to reflect.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(MiracleLevel.allCases) { level in
                        Section(header: Text(level.title.uppercased())) {
                            ForEach(MiracleCategory.allCases.filter { $0.level == level }) { category in
                                NavigationLink {
                                    MiracleCategoryView(category: category)
                                } label: {
                                    HStack {
                                        Label(category.title, systemImage: category.systemImage)
                                        Spacer()
                                        Text("\(library.count(in: category))")
                                            .font(.caption.weight(.semibold).monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    Section(footer: MiracleCreditFooter()) { EmptyView() }
                } else {
                    let matches = results
                    if matches.isEmpty {
                        Section {
                            Text("No articles match \"\(query)\". Try a different word, or browse the subjects.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Section(header: SectionPillHeader(title: "ARTICLES", count: matches.count)) {
                            ForEach(matches) { article in
                                NavigationLink {
                                    MiracleArticleView(article: article)
                                } label: {
                                    MiracleArticleRow(article: article, showCategory: true, query: query)
                                }
                            }
                        }
                    }
                }
            } else {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
        }
        .modifier(MiracleListChrome())
        .navigationTitle("Miracles of the Quran")
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                      placeholder: "Search miracles")
                .minimizedBarStyle(barsCollapsed)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
        }
        #if DEBUG
        .pushDestination(isPresented: $debugOpen) {
            if let debugArticle { MiracleArticleView(article: debugArticle) }
        }
        #endif
        .task {
            guard library == nil else { return }
            let loaded = await Task.detached(priority: .userInitiated) { MiraclesStore.shared.library() }.value
            library = loaded
            #if DEBUG
            // "-miracleArticle <slug>" pushes one article on top of the index, the only headless way in.
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-miracleArticle"), i + 1 < args.count,
               let article = loaded?.bySlug[args[i + 1]] {
                debugArticle = article
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { debugOpen = true }
            }
            #endif
        }
    }
}

/// The list styling the three library screens share.
private struct MiracleListChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .applyConditionalListStyle()
    }
}

/// One subject's articles, grouped by level only when the subject spans more than one: a single header
/// over the whole list would be noise, not structure.
struct MiracleCategoryView: View {
    let category: MiracleCategory

    @State private var articles: [MiracleArticle]?

    var body: some View {
        List {
            if let articles {
                let levels = MiracleLevel.allCases.map { level in (level, articles.filter { $0.level == level }) }
                    .filter { !$0.1.isEmpty }
                if levels.count > 1 {
                    ForEach(levels, id: \.0) { level, rows in
                        Section(header: SectionPillHeader(title: level.title.uppercased(), count: rows.count)) {
                            ForEach(rows) { article in
                                NavigationLink {
                                    MiracleArticleView(article: article)
                                } label: {
                                    MiracleArticleRow(article: article, showCategory: false, query: "")
                                }
                            }
                        }
                    }
                } else {
                    Section(header: SectionPillHeader(title: "ARTICLES", count: articles.count)) {
                        ForEach(articles) { article in
                            NavigationLink {
                                MiracleArticleView(article: article)
                            } label: {
                                MiracleArticleRow(article: article, showCategory: false, query: "")
                            }
                        }
                    }
                }
                Section(footer: MiracleCreditFooter()) { EmptyView() }
            } else {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
        }
        .modifier(MiracleListChrome())
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard articles == nil else { return }
            let category = self.category
            articles = await Task.detached(priority: .userInitiated) {
                MiraclesStore.shared.library()?.articles(in: category) ?? []
            }.value
        }
    }
}

/// A row in a list of articles: the title, and under it the one line saying what the article argues.
struct MiracleArticleRow: View {
    @ObservedObject private var settings = Settings.shared

    let article: MiracleArticle
    let showCategory: Bool
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HighlightedSnippet(
                source: article.title,
                term: query,
                font: .body.weight(.semibold),
                accent: settings.accentColor.color,
                fg: .primary,
                lineLimit: 2
            )

            if !article.summary.isEmpty {
                HighlightedSnippet(
                    source: article.summary,
                    term: query,
                    font: .subheadline,
                    accent: settings.accentColor.color,
                    fg: .secondary,
                    lineLimit: 2
                )
            }

            if showCategory {
                Text("\(article.category.title) · \(article.level.title)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct MiracleCreditFooter: View {
    var body: some View {
        Text("Articles from miracles-of-quran.com, whose authors waive copyright on their own writing; quoted passages from other publishers are shortened to short attributed excerpts that link to the original. Brought to the app from Tilawa, by Jamil Hammoudeh, with permission.")
            .font(.caption2)
    }
}

// MARK: - One article

struct MiracleArticleView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    let article: MiracleArticle

    /// Previous and next within the same subject, so an article is a place in a list rather than a
    /// cul-de-sac the reader has to back out of.
    @State private var siblings: (previous: MiracleArticle?, next: MiracleArticle?) = (nil, nil)
    /// An in-app link followed from the prose: another article, or a subject's index.
    @State private var linkedArticle: MiracleArticle?
    @State private var linkedCategory: MiracleCategory?
    @State private var linkOpen = false
    @State private var copied = false

    var body: some View {
        List {
            Group {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(article.category.title) · \(article.level.title)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)

                        ForEach(Array(article.blocks.enumerated()), id: \.offset) { _, block in
                            if case .claim(let text, let links) = block {
                                MiracleProse(text: text, links: links, style: .claim)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                Section {
                    ForEach(Array(article.blocks.enumerated()), id: \.offset) { _, block in
                        MiracleBlockView(block: block)
                    }
                }

                if siblings.previous != nil || siblings.next != nil {
                    Section(header: Text("IN \(article.category.title.uppercased())")) {
                        if let previous = siblings.previous {
                            NavigationLink {
                                MiracleArticleView(article: previous)
                            } label: {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Previous")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Text(previous.title)
                                            .font(.subheadline.weight(.semibold))
                                    }
                                } icon: {
                                    Image(systemName: "chevron.left.circle")
                                        .foregroundStyle(settings.accentColor.color)
                                }
                            }
                        }
                        if let next = siblings.next {
                            NavigationLink {
                                MiracleArticleView(article: next)
                            } label: {
                                Label {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Next")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        Text(next.title)
                                            .font(.subheadline.weight(.semibold))
                                    }
                                } icon: {
                                    Image(systemName: "chevron.right.circle")
                                        .foregroundStyle(settings.accentColor.color)
                                }
                            }
                        }
                    }
                }

                Section(footer: MiracleCreditFooter()) { EmptyView() }
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        settings.hapticFeedback()
                        UIPasteboard.general.string = article.plainText(quranData: quranData)
                        withAnimation { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { copied = false } }
                    } label: {
                        Label(copied ? "Copied" : "Copy Article", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    Button {
                        settings.hapticFeedback()
                        presentSystemShareSheet(items: [article.plainText(quranData: quranData)])
                    } label: {
                        Label("Share Article", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .tint(settings.accentColor.color)
            }
        }
        // The prose's in-app links land here: `MiracleProse` routes them through `openURL` with the
        // app's own scheme, and the push happens on the List (a lazy row's destination never fires).
        .environment(\.openURL, OpenURLAction { url in
            guard url.scheme == MiracleProse.scheme else { return .systemAction }
            if url.host == "article", let slug = url.pathComponents.dropFirst().first,
               let target = MiraclesStore.shared.article(slug: slug) {
                settings.hapticFeedback()
                linkedArticle = target
                linkedCategory = nil
                linkOpen = true
            } else if url.host == "category", let raw = url.pathComponents.dropFirst().first,
                      let category = MiracleCategory(rawValue: raw) {
                settings.hapticFeedback()
                linkedCategory = category
                linkedArticle = nil
                linkOpen = true
            }
            return .handled
        })
        .pushDestination(isPresented: $linkOpen) {
            if let linkedArticle {
                MiracleArticleView(article: linkedArticle)
            } else if let linkedCategory {
                MiracleCategoryView(category: linkedCategory)
            }
        }
        .task {
            let category = article.category, slug = article.slug
            let pair = await Task.detached(priority: .utility) { () -> (MiracleArticle?, MiracleArticle?) in
                let rows = MiraclesStore.shared.library()?.articles(in: category) ?? []
                guard let at = rows.firstIndex(where: { $0.slug == slug }) else { return (nil, nil) }
                return (at > 0 ? rows[at - 1] : nil, at + 1 < rows.count ? rows[at + 1] : nil)
            }.value
            siblings = pair
        }
    }
}

/// One block of an article as a list row.
struct MiracleBlockView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    let block: MiracleBlock

    var body: some View {
        switch block {
        case .claim:
            // Set with the title above the blocks, not here.
            EmptyView()
        case .lead(let text, let links):
            MiracleProse(text: text, links: links, style: .lead)
        case .text(let text, let links):
            MiracleProse(text: text, links: links, style: .body)
        case .closer(let text, let links):
            VStack(alignment: .leading, spacing: 10) {
                Divider()
                MiracleProse(text: text, links: links, style: .closer)
            }
            .padding(.top, 4)
        case .ayah(let surah, let first, let endAyah):
            // A cited range is capped at five: the point is the verse the article argues from.
            let last = min(endAyah ?? first, first + 4)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(first...max(first, last)), id: \.self) { number in
                    if let ayah = quranData.ayah(surah: surah, ayah: number) {
                        ScriptureQuote(
                            text: "“\(ayah.textEnglishSaheeh)” (Quran \(surah):\(number)).",
                            arabic: ayah.displayArabicText(surahId: surah, clean: settings.cleanArabicText, qiraahOverride: "")
                        )
                    }
                }
            }
        case .quote(let text, let sourceLabel, let sourceURL):
            MiracleQuoteView(text: text, sourceLabel: sourceLabel, sourceURL: sourceURL)
        case .image(let path, let alt):
            MiracleImageView(path: path, alt: alt)
        }
    }
}

/// Prose with its links made tappable. The importer keeps a link only when its label survives verbatim
/// into the paragraph, so each label is located by search; labels are matched left to right and never
/// overlap. An in-app link (another article, a subject) carries the app's own scheme and is routed by
/// the article view; a citation to somebody else's site opens outward.
struct MiracleProse: View {
    enum Style { case claim, lead, body, closer }

    static let scheme = "alislam-miracle"

    @ObservedObject private var settings = Settings.shared

    let text: String
    let links: [MiracleLink]
    let style: Style

    var body: some View {
        let base = Text(attributed)
        return (style == .closer ? base.italic() : base)
            .font(font)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var font: Font {
        switch style {
        case .claim: return .title2.weight(.bold)
        case .lead: return .body.weight(.semibold)
        case .body: return .body
        case .closer: return .body.weight(.semibold)
        }
    }

    private var attributed: AttributedString {
        var result = AttributedString(text)
        guard !links.isEmpty else { return result }
        var claimed: [Range<String.Index>] = []
        for link in links {
            var from = text.startIndex
            var found: Range<String.Index>?
            while from < text.endIndex, let range = text.range(of: link.label, range: from..<text.endIndex) {
                if !claimed.contains(where: { $0.overlaps(range) }) { found = range; break }
                from = text.index(after: range.lowerBound)
            }
            guard let range = found, let url = destination(for: link) else { continue }
            claimed.append(range)
            guard let lower = AttributedString.Index(range.lowerBound, within: result),
                  let upper = AttributedString.Index(range.upperBound, within: result) else { continue }
            result[lower..<upper].link = url
            result[lower..<upper].foregroundColor = settings.accentColor.color
            result[lower..<upper].underlineStyle = .single
        }
        return result
    }

    private func destination(for link: MiracleLink) -> URL? {
        if let slug = link.slug { return URL(string: "\(Self.scheme)://article/\(slug)") }
        if let category = link.category { return URL(string: "\(Self.scheme)://category/\(category)") }
        if let url = link.url { return URL(string: url) }
        return nil
    }
}

/// A short excerpt from an outside publisher, with its source one tap away. The passage was trimmed at
/// import, so this row's job is to keep the attribution visible.
private struct MiracleQuoteView: View {
    @ObservedObject private var settings = Settings.shared

    let text: String
    let sourceLabel: String
    let sourceURL: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.body)
                .italic()
                .foregroundStyle(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            if let url = URL(string: sourceURL), !sourceURL.isEmpty {
                Link(destination: url) {
                    Label(sourceLabel.isEmpty ? sourceURL : sourceLabel, systemImage: "safari")
                        .font(.caption.weight(.semibold))
                        .lineLimit(2)
                }
                .tint(settings.accentColor.color)
            } else if !sourceLabel.isEmpty {
                Text(sourceLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.leading, 12)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 2)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Illustrations

/// An article illustration from the CDN. The frame says whether it is loading or failed rather than
/// sitting as an empty box (some of these are multi-megabyte animations; four are already gone
/// upstream), and an animated GIF plays, because the diagrams are the point of the picture.
private struct MiracleImageView: View {
    @StateObject private var loader = MiracleImageLoader()

    let path: String
    let alt: String

    var body: some View {
        VStack(spacing: 6) {
            switch loader.state {
            case .loaded(let image, let aspect):
                MiracleAnimatedImage(image: image)
                    .aspectRatio(aspect, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            case .failed:
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
                    .frame(height: 96)
                    .overlay(
                        Label("Image unavailable", systemImage: "photo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    )
            case .loading:
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .overlay(ProgressView())
            }

            if !alt.isEmpty {
                Text(alt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
        .task(id: path) { await loader.load(path: path) }
    }
}

/// A `UIImageView`, so an animated `UIImage` actually animates (`Image` shows the first frame only).
private struct MiracleAnimatedImage: UIViewRepresentable {
    let image: UIImage

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        if view.image !== image { view.image = image }
    }
}

@MainActor
private final class MiracleImageLoader: ObservableObject {
    enum State {
        case loading
        case loaded(UIImage, CGFloat)
        case failed
    }

    @Published var state: State = .loading

    /// Decoded images, shared across the library and dropped under memory pressure; the bytes
    /// themselves sit in the URL cache, so a re-open re-decodes without re-downloading.
    private static let decoded = NSCache<NSString, UIImage>()
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 16 << 20, diskCapacity: 256 << 20, diskPath: "miracles-images")
        return URLSession(configuration: config)
    }()

    func load(path: String) async {
        if let cached = Self.decoded.object(forKey: path as NSString) {
            state = .loaded(cached, Self.aspect(of: cached))
            return
        }
        guard let url = MiraclesStore.shared.imageURL(path: path) else {
            state = .failed
            return
        }
        state = .loading
        do {
            let (data, response) = try await Self.session.data(from: url)
            if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                state = .failed
                return
            }
            let image = await Task.detached(priority: .userInitiated) { Self.decode(data) }.value
            guard let image else {
                state = .failed
                return
            }
            Self.decoded.setObject(image, forKey: path as NSString, cost: Self.cost(of: image))
            state = .loaded(image, Self.aspect(of: image))
        } catch {
            state = .failed
        }
    }

    private static func aspect(of image: UIImage) -> CGFloat {
        image.size.height > 0 ? image.size.width / image.size.height : 4 / 3
    }

    private static func cost(of image: UIImage) -> Int {
        let frames = image.images?.count ?? 1
        return Int(image.size.width * image.size.height * image.scale * image.scale * 4) * frames
    }

    /// Frame cap and size cap keep a 288-frame animation from decoding into hundreds of megabytes: the
    /// frames are sampled evenly and rendered at most 480 points wide, which is what the column shows.
    nonisolated private static let maxFrames = 40
    nonisolated private static let maxPixels = 480

    nonisolated private static func decode(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return UIImage(data: data) }
        let count = CGImageSourceGetCount(source)
        guard count > 1 else { return UIImage(data: data) }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixels,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        let step = max(1, Int((Double(count) / Double(maxFrames)).rounded(.up)))
        var frames: [UIImage] = []
        var duration: Double = 0
        var index = 0
        while index < count {
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, index, thumbnailOptions as CFDictionary) else {
                index += step
                continue
            }
            frames.append(UIImage(cgImage: cgImage))
            // The sampled frame stands in for the ones skipped, so it holds their delays too.
            var stepDuration: Double = 0
            for offset in 0..<step where index + offset < count {
                stepDuration += frameDelay(source, index + offset)
            }
            duration += stepDuration
            index += step
        }
        guard !frames.isEmpty else { return UIImage(data: data) }
        if frames.count == 1 { return frames[0] }
        return UIImage.animatedImage(with: frames, duration: max(0.1, duration))
    }

    nonisolated private static func frameDelay(_ source: CGImageSource, _ index: Int) -> Double {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] else { return 0.1 }
        let containers: [CFString] = [kCGImagePropertyGIFDictionary, kCGImagePropertyPNGDictionary, kCGImagePropertyWebPDictionary]
        for key in containers {
            guard let dict = properties[key] as? [CFString: Any] else { continue }
            let unclamped = (dict[kCGImagePropertyGIFUnclampedDelayTime] as? Double)
                ?? (dict[kCGImagePropertyAPNGUnclampedDelayTime] as? Double)
                ?? (dict[kCGImagePropertyWebPUnclampedDelayTime] as? Double)
            let clamped = (dict[kCGImagePropertyGIFDelayTime] as? Double)
                ?? (dict[kCGImagePropertyAPNGDelayTime] as? Double)
                ?? (dict[kCGImagePropertyWebPDelayTime] as? Double)
            let delay = unclamped ?? clamped ?? 0.1
            // Browsers treat a zero or near-zero delay as 100 ms; so does this.
            return delay < 0.011 ? 0.1 : delay
        }
        return 0.1
    }
}
#endif
