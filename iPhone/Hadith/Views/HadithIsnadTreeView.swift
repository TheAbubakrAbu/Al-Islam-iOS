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
// each name carries its English under it, always (Abu, 2026-11-15: "Don't have a button for chain of
// narrators to be English just always have it"; it was a switch from 2026-10-31 until then).

/// The door to the tree, the row the three pages share: drawn like the same-chain door.
struct HadithIsnadTreeDoor: View {
    private let settings = Settings.shared

    let summary: HadithIsnadTreesPack.Summary
    let open: () -> Void

    var body: some View {
        Button {
            settings.hapticFeedback()
            open()
        } label: {
            // The app's door row (`SettingsRowLabel`): the accent chip, the title over its caption,
            // the chevron. It drew its own bare glyph and chevron until 2026-11-15.
            // A tree inside one book says only how many narrations it joins ("3 narrations", not
            // "3 narrations · 1 books").
            SettingsRowLabel(title: String(localized: "Tree of Narrators"), systemImage: "arrow.triangle.branch",
                             subtitle: String(localized: "\(summary.narrations) narrations")
                                + (summary.books == 1 ? "" : " · " + String(localized: "\(summary.books) books")),
                             showsChevron: true)
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
    static let chipCorner: CGFloat = 12

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

    /// The rectangle a node's chip fills, in the layout's coordinates.
    func chipFrame(_ placed: Placed) -> CGRect {
        CGRect(x: placed.center.x - Self.chipWidth / 2, y: placed.center.y - chipHeight / 2,
               width: Self.chipWidth, height: chipHeight)
    }

    /// The chip at a point, if one is drawn there.
    func chip(at point: CGPoint) -> Placed? {
        placed.first { chipFrame($0).contains(point) }
    }

    /// The links between the chips as four paths, one per way a link is drawn: this narration's own
    /// road strong and every other faint, each plain or dashed (the link from the root is dashed where
    /// no narration beneath names the Prophet ﷺ). The canvas strokes them as vector layers and the
    /// shared image on its own canvas, from the same four.
    struct Links {
        let faint: CGPath
        let strong: CGPath
        let faintDashed: CGPath
        let strongDashed: CGPath

        static let faintWidth: CGFloat = 1.5
        static let strongWidth: CGFloat = 2.5
        static let faintOpacity: CGFloat = 0.4
        static let strongOpacity: CGFloat = 0.9
        static let dash: [CGFloat] = [5, 5]
    }

    var links: Links {
        let faint = CGMutablePath(), strong = CGMutablePath()
        let faintDashed = CGMutablePath(), strongDashed = CGMutablePath()
        let half = chipHeight / 2
        for node in placed {
            guard let parent = node.parent, placed.indices.contains(parent) else { continue }
            let above = placed[parent]
            let isStrong = node.highlighted && above.highlighted
            let isDashed = above.node.kind == .root && !node.node.raised
            let path = isDashed ? (isStrong ? strongDashed : faintDashed) : (isStrong ? strong : faint)
            let start = CGPoint(x: above.center.x, y: above.center.y + half)
            let end = CGPoint(x: node.center.x, y: node.center.y - half)
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
        }
        return Links(faint: faint, strong: strong, faintDashed: faintDashed, strongDashed: strongDashed)
    }
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

/// The tree drawn: the links beneath, a chip per node over them, in the layout's coordinates (always
/// left to right; the first road is at the right by construction). The shared image draws all of it;
/// the page's canvas draws the chips alone and strokes the links itself, as vector layers
/// (`drawsLinks` false): a SwiftUI `Canvas` is one bitmap the size of the tree, which a tree of
/// sixty roads (8,600 points, 25,800 pixels) is too wide to have, so its links were simply not drawn.
///
/// A chip is never a `Button`. On the canvas a tap is the scroll view's own (`HadithZoomableCanvas`),
/// because a finger that came down on a SwiftUI button could not start a pinch or a drag: neither of
/// the scroll view's gestures ever began (measured 2026-11-23, see the canvas). VoiceOver still opens
/// a chip, through its accessibility action.
struct HadithIsnadTreeDiagram: View {
    @Environment(\.appearance) private var appearance

    let layout: HadithIsnadTreeLayout
    let labels: HadithIsnadTreeLabels
    /// The rendered image's fixed light look (the page follows the app's theme).
    var forImage = false
    var drawsLinks = true
    var onNarratorTap: ((Int) -> Void)? = nil
    var onLeafTap: ((String, [Int]) -> Void)? = nil

    private var accent: Color { appearance.accent }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if drawsLinks {
                Canvas { context, _ in
                    typealias Links = HadithIsnadTreeLayout.Links
                    let links = layout.links
                    func stroke(_ path: CGPath, strong: Bool, dashed: Bool) {
                        guard !path.isEmpty else { return }
                        context.stroke(Path(path), with: .color(accent.opacity(strong ? Links.strongOpacity : Links.faintOpacity)),
                                       style: StrokeStyle(lineWidth: strong ? Links.strongWidth : Links.faintWidth,
                                                          lineCap: .round, lineJoin: .round, dash: dashed ? Links.dash : []))
                    }
                    stroke(links.faint, strong: false, dashed: false)
                    stroke(links.faintDashed, strong: false, dashed: true)
                    stroke(links.strong, strong: true, dashed: false)
                    stroke(links.strongDashed, strong: true, dashed: true)
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
                chipBody(arabic: arabic, english: english, detail: nil, filled: placed.highlighted, outlined: false, large: false,
                         glyph: "person.text.rectangle")
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint(Text("Opens every narration naming this narrator"))
                    .accessibilityAction { onNarratorTap(narratorID) }
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
                chipBody(arabic: compiler, english: english, detail: detail, filled: placed.highlighted, outlined: true, large: false,
                         glyph: "list.bullet.rectangle")
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityHint(Text("Opens the narrations this road reaches"))
                    .accessibilityAction { onLeafTap(node.slug, node.refs.map(\.idInBook)) }
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
        .background(
            RoundedRectangle(cornerRadius: HadithIsnadTreeLayout.chipCorner, style: .continuous)
                .fill(filled
                      ? AnyShapeStyle(LinearGradient(colors: [accent, accent.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                      : AnyShapeStyle(forImage ? accent.opacity(0.12) : accent.opacity(0.1)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: HadithIsnadTreeLayout.chipCorner, style: .continuous)
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

/// The canvas's zoom, between the page's three buttons and the scroll view: the buttons ask through
/// it, and read from it only whether a step is left. So a pinch publishes when the zoom reaches or
/// leaves an end and at no other time. The page used to hold the scale itself, as `@State`: every
/// step of a pinch then ran the page's body, laid the tree out twice and rebuilt the hosted diagram,
/// 50 to 290 ms a step on the shelf's largest tree (295 chips; measured 2026-11-23, when Abu
/// reported "it just lags out").
final class HadithTreeZoom: ObservableObject {
    /// The closest the canvas zooms in.
    static let maximumScale: CGFloat = 3
    /// Below this a chip is too small to read or to hit, so a tap steps in instead of opening it.
    static let readableScale: CGFloat = 0.55

    @Published fileprivate(set) var canZoomIn = true
    @Published fileprivate(set) var canZoomOut = true
    fileprivate weak var scroll: FittingScrollView?

    func zoomIn() { step(2) }
    func zoomOut() { step(0.5) }

    /// Back to the whole tree in view.
    func showWhole() {
        guard let scroll else { return }
        scroll.setZoomScale(scroll.minimumZoomScale, animated: true)
    }

    /// Twice as close or half, between the whole tree and the closest zoom. The natural size is a
    /// stop on the way, in or out: a step never jumps over the size the tree is drawn to be read at.
    private func step(_ factor: CGFloat) {
        guard let scroll else { return }
        let from = scroll.zoomScale
        var target = from * factor
        if (from < 0.999 && target > 1) || (from > 1.001 && target < 1) { target = 1 }
        scroll.setZoomScale(min(scroll.maximumZoomScale, max(scroll.minimumZoomScale, target)), animated: true)
    }

    /// The scroll view's zoom moved: the buttons hear of it only when an end is reached or left.
    /// Published on the next turn of the run loop, since the first fit zooms inside a layout pass.
    fileprivate func note(_ scroll: UIScrollView) {
        let zoomIn = scroll.zoomScale < scroll.maximumZoomScale - 0.01
        let zoomOut = scroll.zoomScale > scroll.minimumZoomScale + 0.001
        guard zoomIn != canZoomIn || zoomOut != canZoomOut else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if zoomIn != self.canZoomIn { self.canZoomIn = zoomIn }
            if zoomOut != self.canZoomOut { self.canZoomOut = zoomOut }
        }
    }
}

/// A path the canvas strokes beneath its content, in the content's coordinates. A vector layer: it
/// is drawn at the zoom on screen, sharp at every scale, and has no bitmap to outgrow.
struct HadithCanvasStroke {
    let path: CGPath
    let color: UIColor
    let width: CGFloat
    var dash: [CGFloat] = []
}

/// What a tap on the canvas found: the frame to light, and what to open.
struct HadithCanvasTarget {
    let frame: CGRect
    let cornerRadius: CGFloat
    let open: () -> Void
}

/// A SwiftUI view on a UIScrollView that pans in both directions and pinches to zoom (a SwiftUI
/// ScrollView zooms nothing). Opens with the whole tree in view when that still reads, else at its
/// natural size scrolled to the top right corner, where the root and this narration's own road
/// stand. The whole tree is the floor of the zoom, whatever its size. A tap opens what it lands on,
/// a double tap on the ground between steps in and out.
///
/// Rebuilt 2026-11-23 (Abu: "If I zoom out too much for Hadith chain image it just lags out and
/// doesn't work pinch and zoom. Pinch and zoom and whatnot is just broken in general"), on what a
/// scripted pinch and a frame counter showed:
/// - The content takes no touches. Its chips were SwiftUI buttons, and with a finger down on one
///   neither the pinch nor the drag ever began: four pinches out of four did nothing on a freshly
///   opened tree, and the further out the zoom, the less of the screen is not a chip. The taps are
///   the scroll view's own now (`target`), hit-tested against the layout.
/// - The content is rebuilt when `key` changes and never otherwise. It used to be rebuilt on every
///   pass of the page, and the page ran once for every step of a pinch (see `HadithTreeZoom`).
/// - The links are vector layers under the content (`strokes`), not a `Canvas` inside it, which
///   is one bitmap the size of the tree: at sixty roads it drew nothing at all.
/// - The floor is the whole tree. It was a fifth of the natural size, where a wide tree is still
///   four screens across, the pinch bounced back, and Show the Whole Tree did not.
/// - The content sits in a plain view that the scroll view zooms and keeps centred by its frame;
///   the hosted view inside it is never transformed or inset.
///
/// The hosted view keeps its own SwiftUI environment, so the appearance is passed in by the page.
struct HadithZoomableCanvas<Key: Equatable, Content: View>: UIViewRepresentable {
    let contentSize: CGSize
    /// What the content and the strokes are drawn from: they are rebuilt when it changes.
    let key: Key
    let zoom: HadithTreeZoom
    let strokes: [HadithCanvasStroke]
    /// What stands at a point of the content, when a tap there opens something.
    let target: (CGPoint) -> HadithCanvasTarget?
    @ViewBuilder let content: () -> Content

    func makeUIView(context: Context) -> FittingScrollView {
        let coordinator = context.coordinator
        let scroll = FittingScrollView()
        scroll.delegate = coordinator
        scroll.maximumZoomScale = HadithTreeZoom.maximumScale
        scroll.bouncesZoom = true
        // A tree smaller than the canvas still gives under the finger, and the drag stays the canvas's.
        scroll.alwaysBounceVertical = true
        scroll.alwaysBounceHorizontal = true
        scroll.showsHorizontalScrollIndicator = true
        scroll.showsVerticalScrollIndicator = true
        scroll.backgroundColor = .clear
        scroll.contentInsetAdjustmentBehavior = .never

        let zoomView = UIView(frame: CGRect(origin: .zero, size: contentSize))
        zoomView.backgroundColor = .clear
        let host = UIHostingController(rootView: content())
        if #available(iOS 16.4, *) { host.safeAreaRegions = [] }
        host.view.backgroundColor = .clear
        host.view.isUserInteractionEnabled = false
        host.view.frame = zoomView.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        zoomView.addSubview(host.view)
        scroll.addSubview(zoomView)
        scroll.zoomView = zoomView
        scroll.naturalSize = contentSize
        scroll.contentSize = contentSize

        coordinator.host = host
        coordinator.scroll = scroll
        coordinator.key = key
        coordinator.target = target
        coordinator.zoom = zoom
        coordinator.draw(strokes)
        zoom.scroll = scroll

        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.tapped(_:)))
        tap.delegate = coordinator
        scroll.addGestureRecognizer(tap)
        coordinator.tap = tap
        let doubleTap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = coordinator
        scroll.addGestureRecognizer(doubleTap)
        coordinator.doubleTap = doubleTap
        return scroll
    }

    func updateUIView(_ scroll: FittingScrollView, context: Context) {
        let coordinator = context.coordinator
        // The closure reads the page's current state; taking the newest costs nothing.
        coordinator.target = target
        guard coordinator.key != key else { return }
        coordinator.key = key
        coordinator.host?.rootView = content()
        coordinator.draw(strokes)
        if scroll.naturalSize != contentSize {
            // Another tree (the scope left some roads out): start again from its whole.
            scroll.zoomScale = 1
            scroll.naturalSize = contentSize
            scroll.zoomView?.frame = CGRect(origin: .zero, size: contentSize)
            scroll.contentSize = contentSize
            scroll.needsFit = true
            scroll.setNeedsLayout()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var host: UIHostingController<Content>?
        weak var scroll: FittingScrollView?
        var key: Key?
        var target: ((CGPoint) -> HadithCanvasTarget?)?
        weak var zoom: HadithTreeZoom?
        weak var tap: UITapGestureRecognizer?
        weak var doubleTap: UITapGestureRecognizer?
        private var strokeLayers: [CAShapeLayer] = []

        /// The strokes as shape layers under the hosted content, replacing the ones before.
        func draw(_ strokes: [HadithCanvasStroke]) {
            guard let zoomView = scroll?.zoomView else { return }
            strokeLayers.forEach { $0.removeFromSuperlayer() }
            strokeLayers = strokes.filter { !$0.path.isEmpty }.map { stroke in
                let layer = CAShapeLayer()
                layer.path = stroke.path
                layer.strokeColor = stroke.color.cgColor
                layer.fillColor = nil
                layer.lineWidth = stroke.width
                layer.lineCap = .round
                layer.lineJoin = .round
                layer.lineDashPattern = stroke.dash.isEmpty ? nil : stroke.dash.map { NSNumber(value: Double($0)) }
                zoomView.layer.insertSublayer(layer, at: 0)
                return layer
            }
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { scroll?.zoomView }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            (scrollView as? FittingScrollView)?.centerContent()
            zoom?.note(scrollView)
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            zoom?.note(scrollView)
        }

        /// A tap opens what it lands on. Where the chips are too small to read it steps in around
        /// the finger instead: an overview is a map, and a chip a few points wide is not a button.
        @objc func tapped(_ gesture: UITapGestureRecognizer) {
            guard let scroll, let zoomView = scroll.zoomView else { return }
            let point = gesture.location(in: zoomView)
            if scroll.zoomScale < HadithTreeZoom.readableScale {
                show(point, at: 1)
            } else if let found = target?(point) {
                flash(found, in: zoomView)
                found.open()
            }
        }

        /// A double tap on the ground between the chips: in to the natural size around the finger,
        /// or from there back out to the whole tree.
        @objc func doubleTapped(_ gesture: UITapGestureRecognizer) {
            guard let scroll, let zoomView = scroll.zoomView else { return }
            if scroll.zoomScale < 0.999 {
                show(gesture.location(in: zoomView), at: 1)
            } else {
                scroll.setZoomScale(scroll.minimumZoomScale, animated: true)
            }
        }

        /// A single tap is for what opens and a double tap for the ground between, so neither
        /// waits on the other: a chip opens on the touch, not a third of a second after it.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let scroll, let zoomView = scroll.zoomView else { return true }
            let small = scroll.zoomScale < HadithTreeZoom.readableScale
            let opens = target?(touch.location(in: zoomView)) != nil
            if gestureRecognizer === tap { return small || opens }
            if gestureRecognizer === doubleTap { return !small && !opens }
            return true
        }

        /// Zooms to `scale` with a point of the content in the middle of the canvas.
        private func show(_ point: CGPoint, at scale: CGFloat) {
            guard let scroll else { return }
            let size = CGSize(width: scroll.bounds.width / scale, height: scroll.bounds.height / scale)
            scroll.zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2,
                                   width: size.width, height: size.height), animated: true)
        }

        /// The pressed look a button gave: a wash over the chip that fades as its page opens.
        private func flash(_ found: HadithCanvasTarget, in zoomView: UIView) {
            let layer = CALayer()
            layer.frame = found.frame
            layer.cornerRadius = found.cornerRadius
            layer.cornerCurve = .continuous
            layer.backgroundColor = UIColor.label.resolvedColor(with: zoomView.traitCollection).withAlphaComponent(0.22).cgColor
            zoomView.layer.addSublayer(layer)
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.fromValue = 1
            fade.toValue = 0
            fade.duration = 0.4
            fade.fillMode = .forwards
            fade.isRemovedOnCompletion = false
            CATransaction.begin()
            CATransaction.setCompletionBlock { layer.removeFromSuperlayer() }
            layer.add(fade, forKey: "fade")
            CATransaction.commit()
        }
    }
}

/// The scroll view under the canvas. On the first layout with a size it shows the whole tree when
/// that still reads (a zoom of half or more), else the natural size scrolled to the top right
/// corner, where the root and this narration's own road stand. The whole tree in view is as far
/// out as it zooms, and a tree smaller than the view sits in its middle.
final class FittingScrollView: UIScrollView {
    /// What the scroll view zooms: a plain view the size of the tree, holding the links and the
    /// hosted chips.
    weak var zoomView: UIView?
    var naturalSize: CGSize = .zero
    var needsFit = true
    private var lastBounds: CGSize = .zero

    /// The zoom that shows the whole tree: 1 for a tree that fits at its natural size.
    var wholeScale: CGFloat {
        guard naturalSize.width > 0, naturalSize.height > 0, bounds.width > 0, bounds.height > 0 else { return 1 }
        return min(1, bounds.width / naturalSize.width, bounds.height / naturalSize.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != .zero, naturalSize != .zero else { return }
        if bounds.size != lastBounds || needsFit {
            lastBounds = bounds.size
            let whole = wholeScale
            minimumZoomScale = whole
            if needsFit {
                needsFit = false
                zoomScale = whole >= 0.5 ? whole : 1
                // The root and this narration's road stand at the right: open there.
                contentOffset = CGPoint(x: max(0, contentSize.width - bounds.width), y: 0)
            } else if zoomScale < whole {
                // A wider canvas (the phone turned): the whole tree is larger in it.
                zoomScale = whole
            }
        }
        centerContent()
    }

    /// A tree narrower or shorter than the view sits in its middle, not in a corner. By the zoomed
    /// view's frame, as the scroll view lays it out itself, and not by an inset: an inset moves the
    /// offset under a pinch that is working it out.
    func centerContent() {
        guard let zoomView else { return }
        var frame = zoomView.frame
        frame.origin.x = frame.width < bounds.width ? (bounds.width - frame.width) / 2 : 0
        frame.origin.y = frame.height < bounds.height ? (bounds.height - frame.height) / 2 : 0
        if frame.origin != zoomView.frame.origin { zoomView.frame = frame }
    }

    /// A drag that starts on the canvas moves the tree and nothing else. UIKit asks the view under
    /// the finger before any gesture begins (how a slider keeps a swipe that starts on its thumb),
    /// and the canvas answers no to every drag but its own: the sheet this page stands in would
    /// otherwise pull down under a drag on a tree too short to scroll, and the page before it come
    /// back under a drag to the right. A swipe in from the screen's edge still goes back.
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer, gestureRecognizer !== panGestureRecognizer,
           !(gestureRecognizer is UIScreenEdgePanGestureRecognizer) {
            return false
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }
}

// MARK: - The page

/// One narration's tree: the counts and the share above, the tree on its canvas filling the rest of
/// the page, the zoom buttons over its corner, and the toolbar menu that leaves out the narrations of
/// similar wording.
struct HadithIsnadTreeView: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.colorScheme) private var colorScheme
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
    @State private var showsAbout = false
    /// The tree as the scope leaves it, laid out; nil while it loads, or when the scope leaves
    /// nothing. Made by `redraw` when the tree arrives and when the scope changes, and held: it was
    /// a computed property the body read twice, so every pass of the page pruned and laid the tree
    /// out twice over.
    @State private var drawn: Drawn?
    @State private var drawnSerial = 0
    /// The canvas's zoom: the three buttons watch it, the page does not (`HadithTreeZoom`), which
    /// is why it is held as plain state and not as a `@StateObject`, whose owner runs on every
    /// change it publishes.
    @State private var zoom = HadithTreeZoom()

    /// A tree laid out with this narration's road first, and its links as the canvas strokes them.
    struct Drawn {
        let tree: HadithIsnadTree
        let layout: HadithIsnadTreeLayout
        let links: HadithIsnadTreeLayout.Links
        /// Which drawing this is: the canvas rebuilds its content when the number moves.
        let serial: Int
    }

    /// What the canvas's content is drawn from (`HadithZoomableCanvas.key`).
    private struct CanvasKey: Equatable {
        let serial: Int
        let appearance: AppearanceEnvironment
        let colorScheme: ColorScheme
    }

    private var reference: String { book.displayReference(hadith.displayNumber) }

    /// Prunes the tree to the scope and lays it out.
    private func redraw() {
        guard let tree else { return }
        var shown: HadithIsnadTree? = tree
        if scope == .sameText, !similar.isEmpty {
            shown = tree.pruned { slug, idInBook in !similar.contains("\(slug):\(idInBook)") }
        }
        drawnSerial += 1
        drawn = shown.map { shown in
            let layout = HadithIsnadTreeLayout(tree: shown, source: (book.slug, hadith.idInBook), english: true)
            return Drawn(tree: shown, layout: layout, links: layout.links, serial: drawnSerial)
        }
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
            // Only a tree with narrations of similar wording has a choice to offer.
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
        .sheetNowPlayingBar()
        .task { await load() }
        .onChange(of: scope) { _ in redraw() }
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
                                         salt: scope.rawValue + "en", width: width,
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

    private func canvas(_ drawn: Drawn) -> some View {
        typealias Links = HadithIsnadTreeLayout.Links
        let accent = UIColor(appearance.accent)
        let faint = accent.withAlphaComponent(Links.faintOpacity), strong = accent.withAlphaComponent(Links.strongOpacity)
        let layout = drawn.layout
        return HadithZoomableCanvas(
            contentSize: layout.size,
            key: CanvasKey(serial: drawn.serial, appearance: appearance, colorScheme: colorScheme),
            zoom: zoom,
            strokes: [HadithCanvasStroke(path: drawn.links.faint, color: faint, width: Links.faintWidth),
                      HadithCanvasStroke(path: drawn.links.faintDashed, color: faint, width: Links.faintWidth, dash: Links.dash),
                      HadithCanvasStroke(path: drawn.links.strong, color: strong, width: Links.strongWidth),
                      HadithCanvasStroke(path: drawn.links.strongDashed, color: strong, width: Links.strongWidth, dash: Links.dash)],
            target: { point in target(at: point, in: layout) }
        ) {
            // The chips alone: the links are the canvas's strokes, and the taps the canvas's own.
            // The two closures are what VoiceOver's activation calls.
            HadithIsnadTreeDiagram(layout: layout, labels: labels, drawsLinks: false,
                                   onNarratorTap: { pushedNarrator = $0 },
                                   onLeafTap: { pushedLeaf = Leaf(slug: $0, ids: $1) })
                .environment(\.injectedAppearance, appearance)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomTrailing) { HadithTreeZoomControls(zoom: zoom) }
        .overlay(alignment: .top) { Divider() }
    }

    /// What a tap at a point of the tree opens: a narrator's page, or the narrations a compiler's
    /// road reaches. Nothing on the root, on a relation ("his father", no one's page) or between.
    private func target(at point: CGPoint, in layout: HadithIsnadTreeLayout) -> HadithCanvasTarget? {
        guard let placed = layout.chip(at: point) else { return nil }
        let node = placed.node
        let open: () -> Void
        switch node.kind {
        case .root:
            return nil
        case .narrator:
            guard let narratorID = node.narratorID else { return nil }
            open = { pushedNarrator = narratorID }
        case .compiler:
            open = { pushedLeaf = Leaf(slug: node.slug, ids: node.refs.map(\.idInBook)) }
        }
        return HadithCanvasTarget(frame: layout.chipFrame(placed), cornerRadius: HadithIsnadTreeLayout.chipCorner) {
            settings.hapticFeedback()
            open()
        }
    }

    /// The scope, in the slider menu every list of these pages carries. (The English names were a
    /// switch here too until 2026-11-15; they are always drawn now.)
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
        redraw()
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

/// Step in, step out, the whole tree: for a Mac, an iPad with a mouse, and a reader who prefers
/// buttons to a pinch. A view of its own, so a zoom that reaches an end redraws these three buttons
/// and not the page behind them.
private struct HadithTreeZoomControls: View {
    @Environment(\.appearance) private var appearance
    private let settings = Settings.shared

    @ObservedObject var zoom: HadithTreeZoom

    var body: some View {
        VStack(spacing: 0) {
            button("plus", label: "Zoom in", disabled: !zoom.canZoomIn) { zoom.zoomIn() }
            Divider().frame(width: 28)
            button("minus", label: "Zoom out", disabled: !zoom.canZoomOut) { zoom.zoomOut() }
            Divider().frame(width: 28)
            // At the whole tree already, there is nothing for it to do.
            button("arrow.down.left.and.arrow.up.right", label: "Show the whole tree", disabled: !zoom.canZoomOut) { zoom.showWhole() }
        }
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.thinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.primary.opacity(0.08)))
        .padding(14)
    }

    private func button(_ symbol: String, label: LocalizedStringKey, disabled: Bool, action: @escaping () -> Void) -> some View {
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
        .accessibilityLabel(label)
    }
}

/// The narrations one road of the tree reaches in a compiler's book.
struct HadithIsnadLeafView: View {
    let slug: String

    /// The rows by their keys, made with the page: nothing to wait for (`HadithListEntry.make`).
    @StateObject private var list: HadithListModel

    init(slug: String, ids: [Int]) {
        self.slug = slug
        _list = StateObject(wrappedValue: HadithListModel(requests: ids.map { HadithListEntry.Request(slug: slug, idInBook: $0) }))
    }

    private var title: String { HadithCatalogBook.bySlug[slug]?.displayTitle ?? slug }

    var body: some View {
        HadithResolvedList(
            model: list,
            emptyText: String(localized: "No narration of this road could be read."),
            footnote: String(localized: "The narrations this road of the tree reaches in \(title).")
        ) {
            EmptyView()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - The hadiths with the most chains

// Abu, 2026-11-23: "would be fire to see/filter Hadiths with the most amount of chains whether in
// narrators or add as a filter thing or as another navigation link like most overlap most chains".
// A page of its own, behind a door on the Hadith tab and one at the foot of each book: the hadiths
// that come down by the most chains, most first, each one's count the door to the tree of all of
// them. Nothing is counted or ranked here: Scripts/build_isnad_trees.py did both (`rank`) and the
// pack ships the lists (`HadithIsnadTreesPack.mostChains`). The same order is on offer in every
// list of narrations (`HadithListModel.Sort.chains`).

/// The page's list, made with the page: the pack's rows in the pack's order (`HadithListEntry.make`
/// reads no text), so the page is whole on the frame it opens.
@MainActor
final class HadithMostChainsPage: ObservableObject {
    /// The book whose hadiths these are; nil lists the whole shelf's.
    let book: HadithCatalogBook?
    let list: HadithListModel

    init(book: HadithCatalogBook?) {
        self.book = book
        let rows = HadithIsnadTreeStore.shared.mostChains(slug: book?.slug)
        list = HadithListModel(requests: rows.map { HadithListEntry.Request(slug: $0.slug, idInBook: $0.idInBook) },
                               sort: .chains, grouping: HadithListModel.Grouping.none)
    }
}

/// The hadiths with the most chains, the shelf's or one book's: the hero, then the narrations in
/// the list every study screen shares, searched and narrowed from the bar at its foot.
struct HadithMostChainsView: View {
    @StateObject private var page: HadithMostChainsPage

    init(book: HadithCatalogBook? = nil) {
        _page = StateObject(wrappedValue: HadithMostChainsPage(book: book))
    }

    var body: some View {
        HadithResolvedList(
            model: page.list,
            emptyText: String(localized: "No hadith here has enough chains to be listed."),
            footnote: String(localized: "A chain is the narrators as written, from the top down to one compiler, counted once however many narrations repeat it. The narrations counted with a hadith carry its text or similar wording, and each hadith is listed once. A narration whose text only points at another one is left out. The counts describe this shelf of books; they are not a ruling on any hadith."),
            opensTrees: true
        ) {
            ResourceHeroSection(ResourceHero(
                eyebrow: (page.book?.displayTitle ?? String(localized: "Hadiths With the Most Chains")).localizedUppercase,
                systemImage: "arrow.triangle.branch",
                headline: String(localized: "The Most Widely Carried"),
                message: String(localized: "Ordered by how many chains carry each hadith on this shelf. Tap a count to see every chain as one tree.")
            ))
        }
        .navigationTitle(String(localized: "Most Chains"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The door to the page, as the app's door row: at the foot of a book (its own list), and in the
/// Hadith tab's NARRATORS section (the shelf's). Shown only where the list holds something.
struct HadithMostChainsDoor: View {
    private let settings = Settings.shared

    /// The book the door stands in, whose list it opens; nil opens the shelf's.
    let book: HadithCatalogBook?
    /// How many hadiths the list behind the door holds.
    let count: Int
    let open: () -> Void

    var body: some View {
        Button {
            settings.hapticFeedback()
            open()
        } label: {
            SettingsRowLabel(title: book == nil ? String(localized: "Hadiths With the Most Chains") : String(localized: "Most Chains in This Book"),
                             systemImage: "arrow.triangle.branch",
                             subtitle: String(localized: "\(count) hadiths, the most chains first"),
                             showsChevron: true)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // The list and the counts its order reads, inflated off the main thread while the door is
        // on screen, so the page behind it is whole on its first frame.
        .task(id: book?.slug) {
            let slug = book?.slug
            await Task.detached(priority: .utility) { Self.prewarm(slug: slug) }.value
        }
    }

    /// Reads the list behind a door and one count from each book it names: the pack's blocks the
    /// page will sort by are then in the cache.
    nonisolated static func prewarm(slug: String?) {
        let store = HadithIsnadTreeStore.shared
        for book in Set(store.mostChains(slug: slug).map(\.slug)) {
            _ = store.summary(slug: book, idInBook: 1)
        }
    }
}
#endif
