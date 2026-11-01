#if os(iOS)
import SwiftUI
import UIKit

// The tree of narrators of one narration (HadithIsnadTrees.swift), reached from the chain sheet, the
// similar sheet and the same-chain list (Abu, 2026-10-27: "one big chain from prophet Muhammad and all
// the different forks and all the other chains"): every chain of it and of the narrations that carry
// its text, merged from the Prophet ﷺ down through every fork to each compiler, drawn with this
// narration's own road as a straight line at the right and every other fork branching off it, and
// shared as an image. Nothing is merged here: the pack shipped the tree; the page lays it out.
// Since 2026-10-31 the tree sits on a canvas the reader pinches to zoom and drags in both directions
// (Abu: "allow me to zoom in and out for tree of narrators"), the generations closer together, and
// each name carries its English when the chain sheet's switch is on.

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
    static let columnPitch: CGFloat = 136
    static let inset: CGFloat = 12

    /// A chip with the English under the Arabic needs a line more.
    let chipHeight: CGFloat
    /// The gap between generations is the pitch less the chip: 22 points, half what it was.
    let rowPitch: CGFloat
    let english: Bool

    /// By node index.
    let placed: [Placed]
    let width: CGFloat
    let height: CGFloat
    let roads: Int
    let highlighted: Set<Int>

    init(tree: HadithIsnadTree, source: (slug: String, idInBook: Int)?, english: Bool = false) {
        self.english = english
        let chipHeight: CGFloat = english ? 74 : 62
        let rowPitch: CGFloat = chipHeight + 22
        self.chipHeight = chipHeight
        self.rowPitch = rowPitch
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
        self.height = CGFloat(deepest) * rowPitch + chipHeight + 2 * Self.inset
        self.roads = slot
        self.highlighted = highlighted
        self.placed = nodes.indices.map { index in
            Placed(id: index, node: nodes[index],
                   center: CGPoint(x: width - Self.inset - (CGFloat(columns[index]) + 0.5) * Self.columnPitch,
                                   y: Self.inset + CGFloat(depths[index]) * rowPitch + chipHeight / 2),
                   parent: parents[index], highlighted: highlighted.contains(index))
        }
    }

    var size: CGSize { CGSize(width: width, height: height) }
}

/// What the tree's chips say, read once when the page loads: the narrators' names in Arabic and in
/// English (the narrator index), the compilers' names (the chains pack), the narrations' numbers.
struct HadithIsnadTreeLabels {
    var names: [Int: String] = [:]
    var english: [Int: String] = [:]
    var compilers: [String: String] = [:]
    var numbers: [String: String] = [:]
}

// MARK: - The diagram

/// The tree drawn: the links on a canvas beneath, a chip per node over them, in the layout's
/// coordinates (always left to right; the first road is at the right by construction). Draws the same
/// on the page and in the shared image.
struct HadithIsnadTreeDiagram: View {
    @Environment(\.appearance) private var appearance

    let layout: HadithIsnadTreeLayout
    let labels: HadithIsnadTreeLabels
    /// The rendered image's fixed light look (the page follows the app's theme).
    var forImage = false
    var onNarratorTap: ((Int) -> Void)? = nil
    var onLeafTap: ((String, [Int]) -> Void)? = nil

    private var accent: Color { appearance.accent }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                let half = layout.chipHeight / 2
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
            chipBody(arabic: "رَسُولُ اللَّهِ ﷺ", english: layout.english ? HadithIsnadEnglish.prophet : nil, detail: nil,
                     filled: true, outlined: false, large: true, glyph: nil)
        case .narrator:
            let arabic = node.narratorID.flatMap { labels.names[$0] }.flatMap { $0.isEmpty ? nil : $0 } ?? node.text
            let english = layout.english ? (node.narratorID.flatMap { labels.english[$0] } ?? HadithIsnadEnglish.relation(node.text)) : nil
            if let onNarratorTap, let narratorID = node.narratorID, !forImage {
                Button {
                    onNarratorTap(narratorID)
                } label: {
                    chipBody(arabic: arabic, english: english, detail: nil, filled: placed.highlighted, outlined: false, large: false,
                             glyph: "person.text.rectangle")
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Opens every narration naming this narrator"))
            } else {
                chipBody(arabic: arabic, english: english, detail: nil, filled: placed.highlighted, outlined: false, large: false, glyph: nil)
            }
        case .compiler:
            let compiler = labels.compilers[node.slug] ?? HadithCatalogBook.bySlug[node.slug]?.arabicTitle ?? node.slug
            let shown = node.refs.prefix(3).map { ref in
                HadithCatalogBook.displayNumber(labels.numbers["\(node.slug):\(ref.idInBook)"] ?? String(ref.idInBook))
            }
            let detail = shown.joined(separator: ", ") + (node.refs.count > 3 ? " +\(node.refs.count - 3)" : "")
            let english = layout.english ? HadithIsnadEnglish(slug: node.slug).compiler : nil
            if let onLeafTap, !forImage {
                Button {
                    onLeafTap(node.slug, node.refs.map(\.idInBook))
                } label: {
                    chipBody(arabic: compiler, english: english, detail: detail, filled: placed.highlighted, outlined: true, large: false,
                             glyph: "list.bullet.rectangle")
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Opens the narrations this road reaches"))
            } else {
                chipBody(arabic: compiler, english: english, detail: detail, filled: placed.highlighted, outlined: true, large: false, glyph: nil)
            }
        }
    }

    private func chipBody(arabic: String, english: String?, detail: String?, filled: Bool, outlined: Bool, large: Bool, glyph: String?) -> some View {
        let primaryText: Color = forImage ? .black : .primary
        let secondLine = english.flatMap { $0.isEmpty ? nil : $0 }
        return VStack(spacing: 2) {
            Text(arabic)
                .font(appearance.islamArabicFont(base: large ? 19 : 15, relativeTo: .body))
                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                .foregroundColor(filled ? .white : accent)
                .lineLimit(detail == nil && secondLine == nil ? 2 : 1)
                .minimumScaleFactor(0.65)
                .multilineTextAlignment(.center)

            if let secondLine {
                Text(secondLine)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(filled ? Color.white.opacity(0.9) : primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

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
        .frame(width: HadithIsnadTreeLayout.chipWidth, height: layout.chipHeight)
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

extension HadithIsnadEnglish {
    /// The English of a relation node of the tree ("أبيه"), or nil for a word the table does not know.
    static func relation(_ arabic: String) -> String? {
        let english = HadithIsnadEnglish(slug: "").narrator(arabic: arabic, id: nil)
        return english.isEmpty ? nil : english
    }
}

/// The tree framed for sharing: a title, the tree, and the app's name at the foot, on paper.
struct HadithIsnadTreeShareCard: View {
    let title: String
    let subtitle: String
    let layout: HadithIsnadTreeLayout
    let labels: HadithIsnadTreeLabels

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

            HadithIsnadTreeDiagram(layout: layout, labels: labels, forImage: true)

            Text(verbatim: AppIdentifiers.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color.black.opacity(0.45))
        }
        .padding(24)
        .frame(width: Self.width(for: layout))
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
    }
}

// MARK: - The canvas

/// What the page asks of the canvas between renders: a step in, a step out, or back to the whole
/// tree. Each request has its own number, so one is applied once.
struct HadithTreeZoomRequest: Equatable {
    enum Kind { case zoomIn, zoomOut, fit }
    let kind: Kind
    let serial: Int

    /// The closest the canvas zooms in (a generic type cannot hold the constant itself).
    static let maximumScale: CGFloat = 3
}

/// A SwiftUI view on a UIScrollView that pans in both directions and pinches to zoom (a SwiftUI
/// ScrollView zooms nothing). Opens with the whole tree in view when that still reads, else at its
/// natural size scrolled to the top right corner, where the root and this narration's own road
/// stand; a double tap steps between the two. The hosted view keeps its own SwiftUI environment, so the
/// appearance is passed in by the page.
struct HadithZoomableCanvas<Content: View>: UIViewRepresentable {
    let contentSize: CGSize
    let request: HadithTreeZoomRequest?
    /// The scale on screen, reported back so the buttons know when they can step no further.
    @Binding var scale: CGFloat
    @ViewBuilder let content: () -> Content

    func makeUIView(context: Context) -> FittingScrollView {
        let scroll = FittingScrollView()
        scroll.delegate = context.coordinator
        scroll.maximumZoomScale = HadithTreeZoomRequest.maximumScale
        scroll.minimumZoomScale = 0.2
        scroll.bouncesZoom = true
        scroll.alwaysBounceVertical = false
        scroll.alwaysBounceHorizontal = false
        scroll.showsHorizontalScrollIndicator = true
        scroll.showsVerticalScrollIndicator = true
        scroll.backgroundColor = .clear
        scroll.contentInsetAdjustmentBehavior = .never
        let host = UIHostingController(rootView: AnyView(content()))
        host.view.backgroundColor = .clear
        host.view.frame = CGRect(origin: .zero, size: contentSize)
        scroll.addSubview(host.view)
        scroll.contentSize = contentSize
        scroll.hosted = host.view
        context.coordinator.host = host
        context.coordinator.scroll = scroll
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        scroll.addGestureRecognizer(doubleTap)
        return scroll
    }

    func updateUIView(_ scroll: FittingScrollView, context: Context) {
        context.coordinator.host?.rootView = AnyView(content())
        if scroll.naturalSize != contentSize {
            scroll.naturalSize = contentSize
            scroll.hosted?.bounds.size = contentSize
            scroll.contentSize = CGSize(width: contentSize.width * scroll.zoomScale, height: contentSize.height * scroll.zoomScale)
            scroll.needsFit = true
            scroll.setNeedsLayout()
        }
        if let request, request != context.coordinator.applied {
            context.coordinator.applied = request
            switch request.kind {
            case .zoomIn: scroll.setZoomScale(min(HadithTreeZoomRequest.maximumScale, scroll.zoomScale * 1.4), animated: true)
            case .zoomOut: scroll.setZoomScale(max(scroll.minimumZoomScale, scroll.zoomScale / 1.4), animated: true)
            case .fit: scroll.setZoomScale(scroll.fitScale, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(scale: $scale) }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var host: UIHostingController<AnyView>?
        weak var scroll: FittingScrollView?
        var applied: HadithTreeZoomRequest?
        private let scale: Binding<CGFloat>

        init(scale: Binding<CGFloat>) { self.scale = scale }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { host?.view }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            (scrollView as? FittingScrollView)?.centerContent()
            let zoom = scrollView.zoomScale
            if abs(scale.wrappedValue - zoom) > 0.001 {
                DispatchQueue.main.async { self.scale.wrappedValue = zoom }
            }
        }

        @objc func doubleTapped(_ gesture: UITapGestureRecognizer) {
            guard let scroll, let hosted = scroll.hosted else { return }
            if scroll.zoomScale < 0.999 {
                // In, around the tap.
                let point = gesture.location(in: hosted)
                let size = CGSize(width: scroll.bounds.width, height: scroll.bounds.height)
                scroll.zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height), animated: true)
            } else {
                scroll.setZoomScale(scroll.fitScale, animated: true)
            }
        }
    }
}

/// The scroll view under the canvas: on the first layout with a size, the whole tree when that still
/// reads (a zoom of half or more), else the natural size scrolled to the top right corner, where the
/// root and this narration's own road stand (the fit button shows the whole); a tree smaller than the
/// view is centred.
final class FittingScrollView: UIScrollView {
    weak var hosted: UIView?
    var naturalSize: CGSize = .zero
    var needsFit = true
    private var lastBounds: CGSize = .zero

    /// The zoom that shows the whole tree, or 1 when it fits already.
    var fitScale: CGFloat {
        guard naturalSize.width > 0, naturalSize.height > 0, bounds.width > 0, bounds.height > 0 else { return 1 }
        return max(minimumZoomScale, min(1, bounds.width / naturalSize.width, bounds.height / naturalSize.height))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != .zero else { return }
        if bounds.size != lastBounds || needsFit {
            lastBounds = bounds.size
            minimumZoomScale = max(0.15, min(fitScale, 0.5))
            if needsFit {
                needsFit = false
                zoomScale = fitScale >= 0.5 ? fitScale : 1
                // The root and this narration's road stand at the right: open there.
                contentOffset = CGPoint(x: max(0, contentSize.width - bounds.width), y: 0)
            }
        }
        centerContent()
    }

    /// A tree narrower or shorter than the view sits in its middle, not in a corner.
    func centerContent() {
        let horizontal = max(0, (bounds.width - contentSize.width) / 2)
        let vertical = max(0, (bounds.height - contentSize.height) / 2)
        contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}

// MARK: - The page

/// One narration's tree: the counts and the share above, the tree on its canvas filling the rest of
/// the page, the zoom buttons over its corner, and the toolbar menu that leaves out the narrations of
/// similar wording.
struct HadithIsnadTreeView: View {
    @Environment(\.appearance) private var appearance
    @AppStorage(HadithChainSheet.englishKey) private var showsEnglish = true
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
    @State private var labels = HadithIsnadTreeLabels()
    /// "slug:idInBook" of the narrations in the tree that match this one by similar wording only.
    @State private var similar: Set<String> = []
    @State private var scope: Scope = .all
    @State private var pushedNarrator: Int?
    @State private var pushedLeaf: Leaf?
    @State private var missing = false
    @State private var zoomRequest: HadithTreeZoomRequest?
    @State private var zoomSerial = 0
    @State private var scale: CGFloat = 1
    @State private var showsAbout = false

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
        return (shown, HadithIsnadTreeLayout(tree: shown, source: (book.slug, hadith.idInBook), english: showsEnglish))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if let drawn {
                canvas(drawn)
            } else if tree != nil {
                Text("Every chain here belongs to a narration of similar wording.")
                    .foregroundStyle(.secondary)
                    .padding()
                Spacer()
            } else if missing {
                Text("This narration's tree could not be drawn.")
                    .foregroundStyle(.secondary)
                    .padding()
                Spacer()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accentWashedBackground()
        .toolbar {
            ToolbarItem(placement: .primaryAction) { optionsMenu }
        }
        .pushDestination(item: $pushedNarrator) { narratorID in
            HadithNarratorView(narratorID: narratorID)
        }
        .pushDestination(item: $pushedLeaf) { leaf in
            HadithIsnadLeafView(slug: leaf.slug, ids: leaf.ids)
        }
        .navigationTitle(String(localized: "Tree of Narrators"))
        .navigationBarTitleDisplayMode(.inline)
        .sheetNowPlayingBar()
        .task { await load() }
    }

    /// The sentence, the counts, the share and the fold-out note, in a card above the canvas: a tree
    /// can run a dozen generations deep, so the share stays within reach.
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "Every chain of \(reference) and of the narrations that carry its text, merged from the Prophet ﷺ down to each compiler."))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let drawn {
                // The counts of the tree as drawn: the pack's while it is whole, the pruned tree's
                // own once the similar wording is left out (the roads always were).
                let pruned = scope == .sameText && !similar.isEmpty ? drawn.tree.refs : nil
                let narrations = pruned?.count ?? summary.narrations
                let books = pruned.map { Set($0.map(\.slug)).count } ?? summary.books
                HStack(alignment: .firstTextBaseline) {
                    Text([String(localized: "\(narrations) narrations"), String(localized: "\(books) books"),
                          String(localized: "\(drawn.layout.roads) roads")].joined(separator: " · "))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(appearance.accent)
                    Spacer()
                    if #available(iOS 16.0, *) {
                        let width = HadithIsnadTreeShareCard.width(for: drawn.layout)
                        IsnadShareButton(label: String(localized: "Share"),
                                         title: String(localized: "Tree of Narrators") + " · " + reference,
                                         salt: scope.rawValue + (showsEnglish ? "en" : ""), width: width,
                                         // A tree too wide for 2x is rendered smaller, never past 8,192 px a side.
                                         scale: min(2, 8192 / max(width, drawn.layout.height + 140)),
                                         debugArgument: "-shareIsnadTree") {
                            HadithIsnadTreeShareCard(title: reference, subtitle: "شَجَرَةُ الإِسنَادِ", layout: drawn.layout, labels: labels)
                        }
                        .fixedSize()
                    }
                }
            }
            DisclosureGroup(isExpanded: $showsAbout) {
                Text("Drawn ahead of time from the chains the app can read. Narrators are matched by their names as the narrations write them, the written forms of one man joined where a title, a case ending or a shorter form of his name tells them apart and nothing else does; one man may still stand twice, and one written name may be two men. A dashed line marks a narration whose chain, as written, does not name the Prophet ﷺ. Tap a narrator for every narration naming him, a compiler for the narrations his road reaches. Pinch to zoom, drag to move; a double tap steps in and out.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            } label: {
                Text("How this tree is drawn")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .tint(appearance.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func canvas(_ drawn: (tree: HadithIsnadTree, layout: HadithIsnadTreeLayout)) -> some View {
        HadithZoomableCanvas(contentSize: drawn.layout.size, request: zoomRequest, scale: $scale) {
            HadithIsnadTreeDiagram(layout: drawn.layout, labels: labels,
                                   onNarratorTap: { pushedNarrator = $0 },
                                   onLeafTap: { pushedLeaf = Leaf(slug: $0, ids: $1) })
                .environment(\.injectedAppearance, appearance)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomTrailing) { zoomControls }
        .overlay(alignment: .top) { Divider() }
    }

    /// Step in, step out, the whole tree: for a Mac, an iPad with a mouse, and a reader who prefers
    /// buttons to a pinch.
    private var zoomControls: some View {
        VStack(spacing: 0) {
            zoomButton("plus", disabled: scale >= HadithTreeZoomRequest.maximumScale - 0.01) { request(.zoomIn) }
            Divider().frame(width: 28)
            zoomButton("minus", disabled: scale <= 0.16) { request(.zoomOut) }
            Divider().frame(width: 28)
            zoomButton("arrow.down.left.and.arrow.up.right", disabled: false) { request(.fit) }
        }
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.thinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.primary.opacity(0.08)))
        .padding(14)
    }

    private func zoomButton(_ symbol: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.footnote.weight(.semibold))
                .frame(width: 36, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(disabled ? Color.secondary.opacity(0.5) : appearance.accent)
        .disabled(disabled)
        .accessibilityLabel(symbol == "plus" ? "Zoom in" : (symbol == "minus" ? "Zoom out" : "Show the whole tree"))
    }

    private func request(_ kind: HadithTreeZoomRequest.Kind) {
        zoomSerial += 1
        zoomRequest = HadithTreeZoomRequest(kind: kind, serial: zoomSerial)
    }

    /// The scope and the English, in the slider menu every list of these pages carries.
    private var optionsMenu: some View {
        Menu {
            if !similar.isEmpty {
                Section("Narrations") {
                    Picker("Narrations", selection: Binding(get: { scope }, set: { scope = $0; settings.hapticFeedback() })) {
                        ForEach(Scope.allCases) { choice in
                            Text(choice.title).tag(choice)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
            Toggle(isOn: Binding(get: { showsEnglish }, set: { showsEnglish = $0; settings.hapticFeedback() })) {
                Label("English Names", systemImage: "character.book.closed")
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .fixedMenuOrder()
        .tint(appearance.accent)
        .accessibilityLabel("Tree options")
    }

    /// The tree and what its chips say, read off the main thread: the narrators' names from their
    /// index (Arabic and English), the compilers' from the chains pack, the numbers from the books themselves.
    private func load() async {
        let id = summary.tree
        let slug = book.slug
        let idInBook = hadith.idInBook
        let loaded = await Task.detached(priority: .userInitiated) { () -> (HadithIsnadTree?, HadithIsnadTreeLabels, Set<String>) in
            guard let tree = HadithIsnadTreeStore.shared.tree(id: id) else { return (nil, HadithIsnadTreeLabels(), []) }
            var labels = HadithIsnadTreeLabels()
            for node in tree.nodes {
                for narrator in node.narratorIDs where labels.names[narrator] == nil {
                    let profile = HadithNarratorStore.shared.profile(id: narrator)
                    labels.names[narrator] = profile?.name ?? ""
                    labels.english[narrator] = profile?.english ?? ""
                }
                if node.kind == .compiler, labels.compilers[node.slug] == nil {
                    labels.compilers[node.slug] = HadithChainStore.shared.pack?.books[node.slug]?.compilerArabic
                        ?? HadithCatalogBook.bySlug[node.slug]?.arabicTitle ?? node.slug
                }
            }
            let similar = Set(SimilarHadithsStore.shared.matches(slug: slug, idInBook: idInBook)
                                .filter { $0.tier == .similar }.map { "\($0.slug):\($0.idInBook)" })
            return (tree, labels, similar)
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
        var labels = loaded.1
        labels.numbers = numbers
        self.labels = labels
        similar = loaded.2
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
