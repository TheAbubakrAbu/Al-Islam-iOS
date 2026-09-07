#if os(iOS)
import SwiftUI
import UIKit

// The Hadith Encyclopedia (الموسوعة الحديثية, hadeethenc.com): 2,328 narrations, each with a
// scholarly explanation, a list of benefits, its grading and its takhrij reference, in Arabic and
// English, under a tree of 452 topics. Prepared under the supervision of the Dawah and Guidance
// Association and the Association for Serving Islamic Content in Languages; ported to the app from
// Tilawa (Jamil Hammoudeh), with permission.
//
// The data is `Resources/Data/Hadith/HadeethEnc.json.xz` (Scripts/build_hadeethenc_pack.py). The
// site's terms allow reuse on two conditions: nothing is modified, added or removed, and the source is
// credited. So the texts render exactly as published, and every screen here carries the credit.

// MARK: - Model

struct HadeethEncCategory: Identifiable, Hashable {
    let id: String
    let parent: String?
    let english: String
    let arabic: String
    /// Narrations filed directly under this topic, and under it and every topic beneath it.
    let direct: Int
    let total: Int
}

struct HadeethEncHadith: Identifiable {
    struct Layer {
        let title: String
        let intro: String
        let body: String
        let explanation: String
        let benefits: [String]
        let attribution: String
        let grade: String
        let reference: String
    }

    let id: String
    let categories: [String]
    let arabic: Layer
    let english: Layer

    /// The whole entry as plain text, for copying and sharing, source included.
    var plainText: String {
        var parts: [String] = []
        if !arabic.body.isEmpty { parts.append(arabic.body) }
        if !english.body.isEmpty { parts.append(english.body) }
        let grading = [english.attribution, english.grade].filter { !$0.isEmpty }.joined(separator: " · ")
        if !grading.isEmpty { parts.append(grading) }
        if !english.explanation.isEmpty { parts.append("Explanation\n" + english.explanation) }
        if !english.benefits.isEmpty { parts.append("Benefits\n" + english.benefits.map { "• " + $0 }.joined(separator: "\n")) }
        if !arabic.reference.isEmpty { parts.append(arabic.reference) }
        parts.append("Hadith Encyclopedia (hadeethenc.com), via \(AppIdentifiers.appName)")
        return parts.joined(separator: "\n\n")
    }
}

// MARK: - Store

/// Lazy, lock-guarded, parsed off the hot path on first use, the other packs' pattern. The pack is
/// about 2 MB compressed and 14 MB of JSON, so it stays loaded once opened; `unload()` hands it back.
final class HadeethEncStore: @unchecked Sendable {
    static let shared = HadeethEncStore()
    private init() {}

    struct Library {
        let categories: [HadeethEncCategory]
        let categoriesById: [String: HadeethEncCategory]
        let roots: [HadeethEncCategory]
        let children: [String: [HadeethEncCategory]]
        let hadiths: [HadeethEncHadith]
        let hadithsById: [String: HadeethEncHadith]
        /// Narrations filed DIRECTLY under a topic, in id order.
        let directHadiths: [String: [HadeethEncHadith]]
        /// Search folds, parallel to `hadiths`.
        let englishFolds: [String]
        let arabicFolds: [String]

        func children(of category: HadeethEncCategory) -> [HadeethEncCategory] {
            children[category.id] ?? []
        }

        /// Every narration under a topic, its subtopics included, without repeats.
        func allHadiths(under category: HadeethEncCategory) -> [HadeethEncHadith] {
            var seen = Set<String>()
            var out: [HadeethEncHadith] = []
            var queue = [category]
            while !queue.isEmpty {
                let node = queue.removeFirst()
                for hadith in directHadiths[node.id] ?? [] where seen.insert(hadith.id).inserted {
                    out.append(hadith)
                }
                queue.append(contentsOf: children(of: node))
            }
            return out.sorted { (Int($0.id) ?? 0) < (Int($1.id) ?? 0) }
        }

        /// The topic path from a root down to `category`, for a breadcrumb.
        func ancestors(of category: HadeethEncCategory) -> [HadeethEncCategory] {
            var path: [HadeethEncCategory] = []
            var current = category
            while let parentId = current.parent, let parent = categoriesById[parentId] {
                path.insert(parent, at: 0)
                current = parent
            }
            return path
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

    func hadith(id: String) -> HadeethEncHadith? {
        library()?.hadithsById[id]
    }

    func unload() {
        lock.lock(); defer { lock.unlock() }
        loaded = nil
        loadFailed = false
    }

    /// Narrations carrying every word of the query, title and body hits first. English queries read
    /// the English layer (title, narration, explanation), Arabic ones the Arabic (title, narration).
    func search(_ query: String, limit: Int = 60) -> [HadeethEncHadith] {
        guard let library = library() else { return [] }
        let isArabic = HadithFold.isArabicScript(query)
        let folded = isArabic ? HadithFold.arabic(query) : IslamArticles.fold(query)
        let terms = folded.split(whereSeparator: { $0.isWhitespace }).map(String.init).filter { $0.count >= 2 }
        guard !terms.isEmpty else { return [] }
        let folds = isArabic ? library.arabicFolds : library.englishFolds
        var scored: [(index: Int, score: Int)] = []
        for (index, fold) in folds.enumerated() {
            guard terms.allSatisfy({ fold.contains($0) }) else { continue }
            // The title and the narration sit before the explanation in the fold, so an early hit is
            // a hit in what the hadith says rather than in the commentary on it.
            let hadith = library.hadiths[index]
            let head = isArabic ? hadith.arabic.title + " " + hadith.arabic.body : hadith.english.title + " " + hadith.english.body
            let headFold = isArabic ? HadithFold.arabic(head) : IslamArticles.fold(head)
            var score = 0
            for term in terms where headFold.contains(term) { score += 2 }
            if terms.count > 1, headFold.contains(folded) { score += 5 }
            scored.append((index, score))
        }
        scored.sort { $0.score != $1.score ? $0.score > $1.score : $0.index < $1.index }
        return scored.prefix(limit).map { library.hadiths[$0.index] }
    }

    private static func packURL() -> URL? {
        Bundle.main.url(forResource: "HadeethEnc", withExtension: "json.xz", subdirectory: "Data/Hadith")
            ?? Bundle.main.url(forResource: "HadeethEnc", withExtension: "json.xz", subdirectory: "Hadith")
            ?? Bundle.main.url(forResource: "HadeethEnc", withExtension: "json.xz")
    }

    private static func layer(_ raw: [String: Any]?) -> HadeethEncHadith.Layer {
        HadeethEncHadith.Layer(
            title: raw?["title"] as? String ?? "",
            intro: raw?["intro"] as? String ?? "",
            body: raw?["body"] as? String ?? "",
            explanation: raw?["explanation"] as? String ?? "",
            benefits: (raw?["benefits"] as? [String] ?? []).filter { !$0.isEmpty },
            attribution: raw?["attribution"] as? String ?? "",
            grade: raw?["grade"] as? String ?? "",
            reference: raw?["reference"] as? String ?? ""
        )
    }

    private static func load() -> Library? {
        guard let url = packURL(),
              let blob = try? Data(contentsOf: url),
              let json = SolidPack.xzDecompress(blob),
              let root = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any],
              let rawTree = root["tree"] as? [[String: Any]],
              let rawEntries = root["entries"] as? [[String: Any]] else { return nil }

        var categories: [HadeethEncCategory] = []
        for node in rawTree {
            guard let id = node["id"] as? String else { continue }
            categories.append(HadeethEncCategory(
                id: id, parent: node["parent"] as? String,
                english: node["en"] as? String ?? "", arabic: node["ar"] as? String ?? "",
                direct: node["direct"] as? Int ?? 0, total: node["total"] as? Int ?? 0
            ))
        }
        let byId = Dictionary(categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var children: [String: [HadeethEncCategory]] = [:]
        for category in categories {
            if let parent = category.parent { children[parent, default: []].append(category) }
        }
        let roots = categories.filter { $0.parent == nil }

        var hadiths: [HadeethEncHadith] = []
        var englishFolds: [String] = []
        var arabicFolds: [String] = []
        var direct: [String: [HadeethEncHadith]] = [:]
        hadiths.reserveCapacity(rawEntries.count)
        for raw in rawEntries {
            guard let id = raw["id"] as? String else { continue }
            let hadith = HadeethEncHadith(
                id: id,
                categories: raw["cats"] as? [String] ?? [],
                arabic: layer(raw["ar"] as? [String: Any]),
                english: layer(raw["en"] as? [String: Any])
            )
            guard !hadith.arabic.body.isEmpty else { continue }
            hadiths.append(hadith)
            englishFolds.append(IslamArticles.fold([hadith.english.title, hadith.english.body, hadith.english.explanation].joined(separator: " ")))
            arabicFolds.append(HadithFold.arabic([hadith.arabic.title, hadith.arabic.body, hadith.arabic.explanation].joined(separator: " ")))
            for category in hadith.categories { direct[category, default: []].append(hadith) }
        }
        guard !hadiths.isEmpty else { return nil }
        let hadithsById = Dictionary(hadiths.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return Library(categories: categories, categoriesById: byId, roots: roots, children: children,
                       hadiths: hadiths, hadithsById: hadithsById, directHadiths: direct,
                       englishFolds: englishFolds, arabicFolds: arabicFolds)
    }
}

// MARK: - The door

struct HadeethEncView: View {
    @ObservedObject private var settings = Settings.shared

    @State private var library: HadeethEncStore.Library?
    @State private var searchText = ""
    @State private var results: [HadeethEncHadith] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var barsCollapsed = false
    #if DEBUG
    @State private var debugHadith: HadeethEncHadith?
    @State private var debugOpen = false
    #endif

    private var query: String { searchText.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        List {
            if let library {
                if query.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hadith explained")
                                .font(.headline)
                            Text("\(library.hadiths.count.formatted()) narrations from the Hadith Encyclopedia, each with its meaning laid out by scholars, the lessons drawn from it, its grading and its sources, in Arabic and English. Browse by topic or search the texts.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }

                    Section(header: SectionPillHeader(title: "TOPICS", count: library.roots.count)) {
                        ForEach(library.roots) { root in
                            NavigationLink {
                                HadeethEncCategoryView(category: root)
                            } label: {
                                HadeethEncCategoryRow(category: root)
                            }
                        }
                    }

                    Section(footer: HadeethEncCreditFooter()) { EmptyView() }
                } else {
                    if results.isEmpty {
                        Section {
                            Text("No narrations carry \"\(query)\". Try one word, or browse the topics.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Section(header: SectionPillHeader(title: "MATCHING HADITHS", count: results.count)) {
                            ForEach(results) { hadith in
                                NavigationLink {
                                    HadeethEncHadithView(hadith: hadith)
                                } label: {
                                    HadeethEncHadithRow(hadith: hadith, query: query)
                                }
                            }
                        }
                    }
                }
            } else {
                Section {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Opening the encyclopedia…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .applyConditionalListStyle()
        .navigationTitle("Hadith Encyclopedia")
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut),
                      placeholder: "Search the encyclopedia")
                .minimizedBarStyle(barsCollapsed)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
        }
        #if DEBUG
        .pushDestination(isPresented: $debugOpen) {
            if let debugHadith { HadeethEncHadithView(hadith: debugHadith) }
        }
        #endif
        .onChange(of: searchText) { _ in runSearch() }
        .task {
            guard library == nil else { return }
            let loaded = await Task.detached(priority: .userInitiated) { HadeethEncStore.shared.library() }.value
            library = loaded
            #if DEBUG
            // "-hadeethEncOpen <id>" pushes one narration on top of the door.
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-hadeethEncOpen"), i + 1 < args.count,
               let hadith = loaded?.hadithsById[args[i + 1]] {
                debugHadith = hadith
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { debugOpen = true }
            }
            if let i = args.firstIndex(of: "-hadeethEncSearch"), i + 1 < args.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { searchText = args[i + 1] }
            }
            #endif
        }
    }

    private func runSearch() {
        searchTask?.cancel()
        let query = self.query
        guard query.count >= 2 else {
            results = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else { return }
            let found = await Task.detached(priority: .userInitiated) { HadeethEncStore.shared.search(query) }.value
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard query == self.query else { return }
                results = found
            }
        }
    }
}

private struct HadeethEncCreditFooter: View {
    var body: some View {
        Text("From the Hadith Encyclopedia (hadeethenc.com), prepared under the supervision of the Dawah and Guidance Association and the Association for Serving Islamic Content in Languages, reproduced without modification. Brought to the app from Tilawa, by Jamil Hammoudeh, with permission.")
            .font(.caption2)
    }
}

// MARK: - Topics

private struct HadeethEncCategoryRow: View {
    @ObservedObject private var settings = Settings.shared

    let category: HadeethEncCategory

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(category.english)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                Text(category.arabic)
                    .font(settings.useFontArabic
                          ? Font.arabic(settings.nonQuranArabicFontName, size: UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2)
                          : .caption)
                    .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                    .foregroundStyle(settings.accentColor.color)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            CountPill(count: category.total)
        }
        .padding(.vertical, 2)
    }
}

struct HadeethEncCategoryView: View {
    let category: HadeethEncCategory

    @State private var children: [HadeethEncCategory] = []
    @State private var hadiths: [HadeethEncHadith] = []
    @State private var loaded = false

    var body: some View {
        List {
            if loaded {
                if !children.isEmpty {
                    Section(header: SectionPillHeader(title: "SUBTOPICS", count: children.count)) {
                        ForEach(children) { child in
                            NavigationLink {
                                HadeethEncCategoryView(category: child)
                            } label: {
                                HadeethEncCategoryRow(category: child)
                            }
                        }
                    }
                }
                if !hadiths.isEmpty {
                    Section(header: SectionPillHeader(title: children.isEmpty ? "HADITHS" : "HADITHS IN THIS TOPIC", count: hadiths.count)) {
                        ForEach(hadiths) { hadith in
                            NavigationLink {
                                HadeethEncHadithView(hadith: hadith)
                            } label: {
                                HadeethEncHadithRow(hadith: hadith, query: "")
                            }
                        }
                    }
                }
                if children.isEmpty, hadiths.isEmpty {
                    Section {
                        Text("No narrations are filed under this topic.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Section {
                    HStack { Spacer(); ProgressView(); Spacer() }
                }
            }
        }
        .applyConditionalListStyle()
        .navigationTitle(category.english)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !loaded else { return }
            let category = self.category
            let result = await Task.detached(priority: .userInitiated) { () -> ([HadeethEncCategory], [HadeethEncHadith]) in
                guard let library = HadeethEncStore.shared.library() else { return ([], []) }
                let children = library.children(of: category)
                // A leaf lists its own narrations; a branch lists the narrations filed directly on it,
                // and its subtopics carry the rest.
                let rows = (library.directHadiths[category.id] ?? []).sorted { (Int($0.id) ?? 0) < (Int($1.id) ?? 0) }
                return (children, rows)
            }.value
            children = result.0
            hadiths = result.1
            loaded = true
        }
    }
}

// MARK: - Rows

struct HadeethEncHadithRow: View {
    @ObservedObject private var settings = Settings.shared

    let hadith: HadeethEncHadith
    let query: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HighlightedSnippet(
                source: hadith.english.title,
                term: query,
                font: .subheadline.weight(.semibold),
                accent: settings.accentColor.color,
                fg: .primary,
                lineLimit: 3
            )
            if !hadith.english.intro.isEmpty {
                Text(hadith.english.intro)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            HStack(spacing: 6) {
                if !hadith.english.grade.isEmpty {
                    Text(hadith.english.grade)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                }
                if !hadith.english.attribution.isEmpty {
                    Text(hadith.english.attribution)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - One narration

struct HadeethEncHadithView: View {
    @ObservedObject private var settings = Settings.shared

    let hadith: HadeethEncHadith

    @State private var showArabicExplanation = false
    @State private var copied = false
    @State private var topics: [HadeethEncCategory] = []

    private var arabicFont: Font {
        settings.hadithArabicWantsCustomFace
            ? Font.arabic(settings.nonQuranArabicFontName, size: settings.hadithArabicFontSize)
            : .system(size: settings.hadithArabicFontSize)
    }

    private var arabicCaptionFont: Font {
        settings.hadithArabicWantsCustomFace
            ? Font.arabic(settings.nonQuranArabicFontName, size: max(15, settings.hadithArabicFontSize - 4))
            : .system(size: max(15, settings.hadithArabicFontSize - 4))
    }

    var body: some View {
        List {
            Group {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(hadith.english.title)
                            .font(.headline)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 8) {
                            if !hadith.english.grade.isEmpty {
                                Text(hadith.english.grade)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(settings.accentColor.color.opacity(0.15)))
                                    .foregroundStyle(settings.accentColor.color)
                            }
                            if !hadith.english.attribution.isEmpty {
                                Text(hadith.english.attribution)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                Section(header: Text("THE HADITH")) {
                    HadithArabicText(text: hadith.arabic.body, term: "", font: arabicFont, lineSpacing: 6)
                        .textSelection(.enabled)
                    Text(hadith.english.body)
                        .font(.system(size: CGFloat(settings.englishFontSize)))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }

                if !hadith.english.explanation.isEmpty || !hadith.arabic.explanation.isEmpty {
                    Section(header: Text("EXPLANATION")) {
                        if !hadith.english.explanation.isEmpty {
                            ForEach(Array(paragraphs(hadith.english.explanation).enumerated()), id: \.offset) { _, paragraph in
                                Text(paragraph)
                                    .font(.system(size: CGFloat(settings.englishFontSize)))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        if !hadith.arabic.explanation.isEmpty {
                            Button {
                                settings.hapticFeedback()
                                withAnimation { showArabicExplanation.toggle() }
                            } label: {
                                Label(showArabicExplanation ? "Hide the Arabic explanation" : "Show the Arabic explanation",
                                      systemImage: showArabicExplanation ? "chevron.up" : "chevron.down")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(settings.accentColor.color)
                            if showArabicExplanation {
                                ForEach(Array(paragraphs(hadith.arabic.explanation).enumerated()), id: \.offset) { _, paragraph in
                                    Text(paragraph)
                                        .font(arabicCaptionFont)
                                        .arabicFontDesign(custom: settings.hadithArabicWantsCustomFace)
                                        .multilineTextAlignment(.trailing)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }

                let benefits = hadith.english.benefits.isEmpty ? hadith.arabic.benefits : hadith.english.benefits
                if !benefits.isEmpty {
                    let arabicBenefits = hadith.english.benefits.isEmpty
                    Section(header: SectionPillHeader(title: "BENEFITS", count: benefits.count)) {
                        ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                            HStack(alignment: .top, spacing: 10) {
                                if arabicBenefits {
                                    Text(benefit)
                                        .font(arabicCaptionFont)
                                        .arabicFontDesign(custom: settings.hadithArabicWantsCustomFace)
                                        .multilineTextAlignment(.trailing)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    Text("\(index + 1)")
                                        .font(.caption.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(settings.accentColor.color)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.caption.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(settings.accentColor.color)
                                        .frame(width: 18, alignment: .trailing)
                                    Text(benefit)
                                        .font(.system(size: CGFloat(settings.englishFontSize)))
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                if !hadith.arabic.reference.isEmpty {
                    Section(header: Text("SOURCES")) {
                        ForEach(Array(paragraphs(hadith.arabic.reference, separator: "\n").enumerated()), id: \.offset) { _, line in
                            Text(line)
                                .font(arabicCaptionFont)
                                .arabicFontDesign(custom: settings.hadithArabicWantsCustomFace)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if !topics.isEmpty {
                    Section(header: Text("TOPICS")) {
                        ForEach(topics) { topic in
                            NavigationLink {
                                HadeethEncCategoryView(category: topic)
                            } label: {
                                HadeethEncCategoryRow(category: topic)
                            }
                        }
                    }
                }

                Section(footer: HadeethEncCreditFooter()) { EmptyView() }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Hadith \(hadith.id)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        settings.hapticFeedback()
                        UIPasteboard.general.string = hadith.plainText
                        withAnimation { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { copied = false } }
                    } label: {
                        Label(copied ? "Copied" : "Copy Hadith", systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    Button {
                        settings.hapticFeedback()
                        presentSystemShareSheet(items: [hadith.plainText])
                    } label: {
                        Label("Share Hadith", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .tint(settings.accentColor.color)
            }
        }
        .task {
            let ids = hadith.categories
            topics = await Task.detached(priority: .utility) {
                guard let library = HadeethEncStore.shared.library() else { return [] }
                return ids.compactMap { library.categoriesById[$0] }
            }.value
        }
    }

    private func paragraphs(_ text: String, separator: String = "\n\n") -> [String] {
        text.components(separatedBy: separator)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
#endif
