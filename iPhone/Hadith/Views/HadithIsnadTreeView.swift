#if os(iOS)
import SwiftUI

// The tree of narrators of one narration (HadithIsnadTrees.swift), reached from the chain sheet, the
// similar sheet and the same-chain list (Abu, 2026-10-27: "one big chain from prophet Muhammad and all
// the different forks and all the other chains"): every chain of it and of the narrations that carry
// its text, merged from the Prophet ﷺ down through every fork to each compiler, drawn with this
// narration's own road as a straight line at the right and every other fork branching off it, and
// shared as an image. Nothing is merged here: the pack shipped the tree; the page lays it out.

/// The door to the tree, the row the three pages share: drawn like the same-chain door.
struct HadithIsnadTreeDoor: View {
    /// The accent off the environment, so an accent change redraws this view (a bare `Settings` read
    /// in a view that observes nothing kept the old colour).
    @Environment(\.appearance) private var appearance
    private let settings = Settings.shared

    let summary: HadithIsnadTreesPack.Summary
    let open: () -> Void

    var body: some View {
        Button {
            settings.hapticFeedback()
            open()
        } label: {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tree of Narrators")
                            .foregroundColor(.primary)
                        Text(String(localized: "\(summary.narrations) narrations") + " · " + String(localized: "\(summary.books) books"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundColor(appearance.accent)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - The layout

/// Where each node of a tree sits: one row per generation down from the root, one column per road,
/// a narrator over the first of his roads (so the road the page is about is a straight line from the
/// root to its compiler, and every other fork branches off to the side), the first column at the
/// RIGHT, as the chains read. Computed once per tree; the diagram and the shared image draw it alike.
struct HadithIsnadTreeLayout {
    struct Placed: Identifiable {
        /// The node's index in the tree.
        let id: Int
        let node: HadithIsnadTree.Node
        let center: CGPoint
        let parent: Int?
        /// On the road from the root to the narration the page is about.
        let highlighted: Bool
    }

    static let chipWidth: CGFloat = 124
    static let chipHeight: CGFloat = 62
    static let columnPitch: CGFloat = 136
    static let rowPitch: CGFloat = 98
    static let inset: CGFloat = 12

    /// By node index.
    let placed: [Placed]
    let width: CGFloat
    let height: CGFloat
    let roads: Int
    let highlighted: Set<Int>

    init(tree: HadithIsnadTree, source: (slug: String, idInBook: Int)?) {
        let nodes = tree.nodes
        var parents = [Int?](repeating: nil, count: nodes.count)
        for (index, node) in nodes.enumerated() {
            for child in node.children where nodes.indices.contains(child) { parents[child] = index }
        }
        var highlighted: Set<Int> = []
        if let source, let leaf = nodes.firstIndex(where: { node in
            node.kind == .compiler && node.slug == source.slug && node.refs.contains { $0.idInBook == source.idInBook }
        }) {
            var at: Int? = leaf
            while let index = at, highlighted.insert(index).inserted { at = parents[index] }
        }
        var columns = [Int](repeating: 0, count: nodes.count)
        var depths = [Int](repeating: 0, count: nodes.count)
        var slot = 0
        var deepest = 0
        func place(_ index: Int, depth: Int) {
            guard depth < 64 else { return }
            depths[index] = depth
            deepest = max(deepest, depth)
            let children = nodes[index].children.filter { nodes.indices.contains($0) }
            guard !children.isEmpty else {
                columns[index] = slot
                slot += 1
                return
            }
            // This narration's road first: the one straight line down from the root.
            let ordered = children.filter { highlighted.contains($0) } + children.filter { !highlighted.contains($0) }
            for child in ordered { place(child, depth: depth + 1) }
            columns[index] = columns[ordered[0]]
        }
        if !nodes.isEmpty { place(0, depth: 0) }
        let width = CGFloat(max(slot, 1)) * Self.columnPitch + 2 * Self.inset
        self.width = width
        self.height = CGFloat(deepest) * Self.rowPitch + Self.chipHeight + 2 * Self.inset
        self.roads = slot
        self.highlighted = highlighted
        self.placed = nodes.indices.map { index in
            Placed(id: index, node: nodes[index],
                   center: CGPoint(x: width - Self.inset - (CGFloat(columns[index]) + 0.5) * Self.columnPitch,
                                   y: Self.inset + CGFloat(depths[index]) * Self.rowPitch + Self.chipHeight / 2),
                   parent: parents[index], highlighted: highlighted.contains(index))
        }
    }
}

// MARK: - The diagram

/// The tree drawn: the links on a canvas beneath, a chip per node over them, in the layout's
/// coordinates (always left to right; the first road is at the right by construction). Draws the same
/// on the page and in the shared image.
struct HadithIsnadTreeDiagram: View {
    @Environment(\.appearance) private var appearance

    let layout: HadithIsnadTreeLayout
    /// Narrator names by id, as the narrator index writes them.
    let names: [Int: String]
    /// Each compiler's name, by his book's slug, as the chains pack names him.
    let compilers: [String: String]
    /// The narrations' numbers as their books print them, by "slug:idInBook".
    let numbers: [String: String]
    /// The rendered image's fixed light look (the page follows the app's theme).
    var forImage = false
    var onNarratorTap: ((Int) -> Void)? = nil
    var onLeafTap: ((String, [Int]) -> Void)? = nil

    private var accent: Color { appearance.accent }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                let half = HadithIsnadTreeLayout.chipHeight / 2
                for placed in layout.placed {
                    guard let parent = placed.parent, layout.placed.indices.contains(parent) else { continue }
                    let above = layout.placed[parent]
                    let strong = placed.highlighted && above.highlighted
                    // The link from the root is dashed where no narration beneath names the Prophet ﷺ.
                    let dashed = above.node.kind == .root && !placed.node.raised
                    let start = CGPoint(x: above.center.x, y: above.center.y + half)
                    let end = CGPoint(x: placed.center.x, y: placed.center.y - half)
                    var path = Path()
                    path.move(to: start)
                    if abs(start.x - end.x) < 0.5 {
                        path.addLine(to: end)
                    } else {
                        // A fork: down from the narrator, across, and down to the road.
                        let middle = (start.y + end.y) / 2
                        path.addLine(to: CGPoint(x: start.x, y: middle))
                        path.addLine(to: CGPoint(x: end.x, y: middle))
                        path.addLine(to: end)
                    }
                    context.stroke(path, with: .color(accent.opacity(strong ? 0.9 : 0.4)),
                                   style: StrokeStyle(lineWidth: strong ? 2.5 : 1.5, lineCap: .round, lineJoin: .round,
                                                      dash: dashed ? [5, 5] : []))
                }
            }

            ForEach(layout.placed) { placed in
                chip(placed)
                    .position(placed.center)
            }
        }
        .frame(width: layout.width, height: layout.height)
        // The layout's coordinates are plain: the first road sits at the right by construction.
        .environment(\.layoutDirection, .leftToRight)
    }

    @ViewBuilder
    private func chip(_ placed: HadithIsnadTreeLayout.Placed) -> some View {
        let node = placed.node
        switch node.kind {
        case .root:
            chipBody(arabic: "رَسُولُ اللَّهِ ﷺ", detail: nil, filled: true, outlined: false, large: true, glyph: nil)
        case .narrator:
            let arabic = node.narratorID.flatMap { names[$0] }.flatMap { $0.isEmpty ? nil : $0 } ?? node.text
            if let onNarratorTap, let narratorID = node.narratorID, !forImage {
                Button {
                    onNarratorTap(narratorID)
                } label: {
                    chipBody(arabic: arabic, detail: nil, filled: placed.highlighted, outlined: false, large: false,
                             glyph: "person.text.rectangle")
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Opens every narration naming this narrator"))
            } else {
                chipBody(arabic: arabic, detail: nil, filled: placed.highlighted, outlined: false, large: false, glyph: nil)
            }
        case .compiler:
            let compiler = compilers[node.slug] ?? HadithCatalogBook.bySlug[node.slug]?.arabicTitle ?? node.slug
            let shown = node.refs.prefix(3).map { ref in
                HadithCatalogBook.displayNumber(numbers["\(node.slug):\(ref.idInBook)"] ?? String(ref.idInBook))
            }
            let detail = shown.joined(separator: ", ") + (node.refs.count > 3 ? " +\(node.refs.count - 3)" : "")
            if let onLeafTap, !forImage {
                Button {
                    onLeafTap(node.slug, node.refs.map(\.idInBook))
                } label: {
                    chipBody(arabic: compiler, detail: detail, filled: placed.highlighted, outlined: true, large: false,
                             glyph: "list.bullet.rectangle")
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Opens the narrations this road reaches"))
            } else {
                chipBody(arabic: compiler, detail: detail, filled: placed.highlighted, outlined: true, large: false, glyph: nil)
            }
        }
    }

    private func chipBody(arabic: String, detail: String?, filled: Bool, outlined: Bool, large: Bool, glyph: String?) -> some View {
        let primaryText: Color = forImage ? .black : .primary
        return VStack(spacing: 2) {
            Text(arabic)
                .font(appearance.islamArabicFont(base: large ? 19 : 15, relativeTo: .body))
                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                .foregroundColor(filled ? .white : accent)
                .lineLimit(detail == nil ? 2 : 1)
                .minimumScaleFactor(0.65)
                .multilineTextAlignment(.center)

            if let detail {
                Text(detail)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundColor(filled ? Color.white.opacity(0.9) : primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            if let glyph {
                Image(systemName: glyph)
                    .font(.system(size: 9))
                    .foregroundColor(filled ? Color.white.opacity(0.85) : accent.opacity(0.8))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .frame(width: HadithIsnadTreeLayout.chipWidth, height: HadithIsnadTreeLayout.chipHeight)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(filled
                      ? AnyShapeStyle(LinearGradient(colors: [accent, accent.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                      : AnyShapeStyle(forImage ? accent.opacity(0.12) : accent.opacity(0.1)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(accent.opacity(outlined && !filled ? 0.55 : 0), lineWidth: 1.5)
        )
    }
}

/// The tree framed for sharing: a title, the tree, and the app's name at the foot, on paper.
struct HadithIsnadTreeShareCard: View {
    let title: String
    let subtitle: String
    let layout: HadithIsnadTreeLayout
    let names: [Int: String]
    let compilers: [String: String]
    let numbers: [String: String]

    static func width(for layout: HadithIsnadTreeLayout) -> CGFloat { max(layout.width, 320) + 48 }

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(Color.black.opacity(0.6))
            }
            .multilineTextAlignment(.center)

            HadithIsnadTreeDiagram(layout: layout, names: names, compilers: compilers, numbers: numbers, forImage: true)

            Text(verbatim: AppIdentifiers.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color.black.opacity(0.45))
        }
        .padding(24)
        .frame(width: Self.width(for: layout))
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
    }
}

// MARK: - The page

/// One narration's tree: the counts, the diagram scrolled to its own road, the share, and the toolbar
/// menu that leaves out the narrations of similar wording.
struct HadithIsnadTreeView: View {
    @Environment(\.appearance) private var appearance
    private let settings = Settings.shared

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith
    let summary: HadithIsnadTreesPack.Summary

    /// Which narrations' chains the tree keeps: all the pack merged, or only the ones carrying this
    /// text (the similar-wording narrations left out).
    enum Scope: String, CaseIterable, Identifiable {
        case all, sameText

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return String(localized: "Similar Wording Too")
            case .sameText: return String(localized: "Same Text Only")
            }
        }
    }

    struct Leaf: Identifiable {
        let slug: String
        let ids: [Int]
        var id: String { slug + ids.map(String.init).joined(separator: ",") }
    }

    @State private var tree: HadithIsnadTree?
    @State private var names: [Int: String] = [:]
    @State private var compilers: [String: String] = [:]
    @State private var numbers: [String: String] = [:]
    /// "slug:idInBook" of the narrations in the tree that match this one by similar wording only.
    @State private var similar: Set<String> = []
    @State private var scope: Scope = .all
    @State private var pushedNarrator: Int?
    @State private var pushedLeaf: Leaf?
    @State private var missing = false

    private var reference: String { book.displayReference(hadith.displayNumber) }

    /// The tree as the scope leaves it, laid out with this narration's road first; nil while it
    /// loads, or when the scope leaves nothing.
    private var drawn: (tree: HadithIsnadTree, layout: HadithIsnadTreeLayout)? {
        guard let tree else { return nil }
        var shown: HadithIsnadTree? = tree
        if scope == .sameText, !similar.isEmpty {
            shown = tree.pruned { slug, idInBook in !similar.contains("\(slug):\(idInBook)") }
        }
        guard let shown else { return nil }
        return (shown, HadithIsnadTreeLayout(tree: shown, source: (book.slug, hadith.idInBook)))
    }

    var body: some View {
        List {
            Group {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(String(localized: "Every chain of \(reference) and of the narrations that carry its text, merged from the Prophet ﷺ down to each compiler."))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if let drawn {
                            Text([String(localized: "\(summary.narrations) narrations"), String(localized: "\(summary.books) books"),
                                  String(localized: "\(drawn.layout.roads) roads")].joined(separator: " · "))
                                .font(.caption.weight(.semibold))
                                .foregroundColor(appearance.accent)
                        }
                    }
                    .padding(.vertical, 2)

                    // Above the tree, which can run a dozen generations deep: the share within reach.
                    if let drawn, #available(iOS 16.0, *) {
                        let width = HadithIsnadTreeShareCard.width(for: drawn.layout)
                        IsnadShareButton(label: String(localized: "Share the Tree as an Image"),
                                         title: String(localized: "Tree of Narrators") + " · " + reference,
                                         salt: scope.rawValue, width: width,
                                         // A tree too wide for 2x is rendered smaller, never past 8,192 px a side.
                                         scale: min(2, 8192 / max(width, drawn.layout.height + 140)),
                                         debugArgument: "-shareIsnadTree") {
                            HadithIsnadTreeShareCard(title: reference, subtitle: "شَجَرَةُ الإِسنَادِ", layout: drawn.layout,
                                                     names: names, compilers: compilers, numbers: numbers)
                        }
                    }
                }

                if let drawn {
                    Section {
                        ScrollView(.horizontal, showsIndicators: true) {
                            HadithIsnadTreeDiagram(layout: drawn.layout, names: names, compilers: compilers, numbers: numbers,
                                                   onNarratorTap: { pushedNarrator = $0 },
                                                   onLeafTap: { pushedLeaf = Leaf(slug: $0, ids: $1) })
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                        }
                        // Opens at its right edge, where the root and this narration's road stand.
                        .environment(\.layoutDirection, .rightToLeft)
                        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))

                    } footer: {
                        Text("Drawn ahead of time from the chains the app can read. Narrators are matched by their names as the narrations write them; a shorter name is joined to the fuller one it begins only where no other narrator of that name is known under the same teacher, so one man may still stand twice, and one written name may be two men. A dashed line marks a narration whose chain, as written, does not name the Prophet ﷺ. Tap a narrator for every narration naming him, a compiler for the narrations his road reaches.")
                    }
                } else if tree != nil {
                    Section {
                        Text("Every chain here belongs to a narration of similar wording.")
                            .foregroundStyle(.secondary)
                    }
                } else if missing {
                    Section {
                        Text("This narration's tree could not be drawn.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .toolbar {
            if !similar.isEmpty {
                ToolbarItem(placement: .primaryAction) { optionsMenu }
            }
        }
        .pushDestination(item: $pushedNarrator) { narratorID in
            HadithNarratorView(narratorID: narratorID)
        }
        .pushDestination(item: $pushedLeaf) { leaf in
            HadithIsnadLeafView(slug: leaf.slug, ids: leaf.ids)
        }
        .navigationTitle(String(localized: "Tree of Narrators"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    /// The scope, in the slider menu every list of these pages carries.
    private var optionsMenu: some View {
        Menu {
            Section("Narrations") {
                Picker("Narrations", selection: Binding(get: { scope }, set: { scope = $0; settings.hapticFeedback() })) {
                    ForEach(Scope.allCases) { choice in
                        Text(choice.title).tag(choice)
                    }
                }
                .pickerStyle(.inline)
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .fixedMenuOrder()
        .tint(appearance.accent)
        .accessibilityLabel("Tree options")
    }

    /// The tree and what its chips say, read off the main thread: the narrators' names from their
    /// index, the compilers' from the chains pack, the numbers from the books themselves.
    private func load() async {
        let id = summary.tree
        let slug = book.slug
        let idInBook = hadith.idInBook
        let loaded = await Task.detached(priority: .userInitiated) { () -> (HadithIsnadTree?, [Int: String], [String: String], Set<String>) in
            guard let tree = HadithIsnadTreeStore.shared.tree(id: id) else { return (nil, [:], [:], []) }
            var names: [Int: String] = [:]
            var compilers: [String: String] = [:]
            for node in tree.nodes {
                for narrator in node.narratorIDs where names[narrator] == nil {
                    names[narrator] = HadithNarratorStore.shared.profile(id: narrator)?.name ?? ""
                }
                if node.kind == .compiler, compilers[node.slug] == nil {
                    compilers[node.slug] = HadithChainStore.shared.pack?.books[node.slug]?.compilerArabic
                        ?? HadithCatalogBook.bySlug[node.slug]?.arabicTitle ?? node.slug
                }
            }
            let similar = Set(SimilarHadithsStore.shared.matches(slug: slug, idInBook: idInBook)
                                .filter { $0.tier == .similar }.map { "\($0.slug):\($0.idInBook)" })
            return (tree, names, compilers, similar)
        }.value
        guard let tree = loaded.0 else {
            missing = true
            return
        }
        var opened: [String: HadithBookData] = [:]
        for ref in tree.refs where opened[ref.slug] == nil {
            guard let catalog = HadithCatalogBook.bySlug[ref.slug] else { continue }
            if let data = await HadithStore.shared.openOffMain(catalog) { opened[ref.slug] = data }
        }
        let books = opened
        let refs = tree.refs
        let numbers = await Task.detached(priority: .userInitiated) { () -> [String: String] in
            var out: [String: String] = [:]
            for ref in refs {
                if let number = books[ref.slug]?.hadith(numbered: ref.idInBook)?.displayNumber {
                    out["\(ref.slug):\(ref.idInBook)"] = number
                }
            }
            return out
        }.value
        names = loaded.1
        compilers = loaded.2
        similar = loaded.3
        self.numbers = numbers
        self.tree = tree
        #if DEBUG
        // "-openIsnadTreeLeaf" (with -openIsnadTree): this narration's own compiler, pushed. Headless
        // verification only.
        if ProcessInfo.processInfo.arguments.contains("-openIsnadTreeLeaf"),
           let leaf = tree.nodes.first(where: { $0.kind == .compiler && $0.slug == slug && $0.refs.contains { $0.idInBook == idInBook } }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { pushedLeaf = Leaf(slug: leaf.slug, ids: leaf.refs.map(\.idInBook)) }
        }
        #endif
    }
}

/// The narrations one road of the tree reaches in a compiler's book.
struct HadithIsnadLeafView: View {
    let slug: String
    let ids: [Int]

    @State private var entries: [HadithListEntry]?

    private var title: String { HadithCatalogBook.bySlug[slug]?.displayTitle ?? slug }

    var body: some View {
        Group {
            if let entries {
                HadithResolvedList(
                    entries: entries,
                    emptyText: String(localized: "No narration of this road could be read."),
                    footnote: String(localized: "The narrations this road of the tree reaches in \(title).")
                ) {
                    EmptyView()
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            entries = await HadithListEntry.resolve(ids.map { HadithListEntry.Request(slug: slug, idInBook: $0) })
        }
    }
}
#endif
