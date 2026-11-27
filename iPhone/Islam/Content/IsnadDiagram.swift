import SwiftUI

// Chains of transmission (isnad) drawn as a diagram: the Prophet ﷺ at the top, each generation a row
// below him, and where a chain divides, its roads side by side. First drawn for the ten readings
// (Quran/Qiraat/QiraatIsnad.swift, which keeps their data and pages); since 2026-10-27 the same diagram
// draws the chains in the Hadith & Its Sciences articles, the compiling of the Quran, the Quranists
// answer and the madhahib (Abu: "the whole chain stuff is sick add it anywhere else it applies in the
// app especially with Hadith science and Quran compilation").
//
// The model compiles everywhere the articles do (the watch included); the diagram and the shared
// image are iOS, and the watch lists the same chain as plain rows.

struct IsnadNode: Identifiable, Hashable {
    enum Role: Hashable {
        /// The origin of what is carried, drawn filled at the top: the Quran's chain begins with Allah's speech.
        case source
        case prophet, companion, successor, imam, link, narrator, student
    }

    let name: String
    let arabic: String
    var detail: String? = nil
    var role: Role = .link
    /// A hadith narrator's row in the shelf's narrator index (HadithNarrators.swift): the chip opens
    /// his profile when the diagram is given `onNarratorTap`. Nil everywhere else.
    var narratorID: Int? = nil
    /// How many narrators stand at this level of the chain ("1"), badged at the chip's far side in
    /// the compact look: the count a hadith is named by at its narrowest point (gharib, 'aziz,
    /// mashhur). Nil everywhere else.
    var count: String? = nil

    var id: String { name + "|" + arabic }
}

/// What a chain opens into at its foot when the roads below it are too many to draw: rays down to
/// a row of dots, and a line saying who they are ("a great many narrators").
struct IsnadFan {
    let rays: Int
    let caption: String
}

struct IsnadLayer: Identifiable {
    let title: String
    let nodes: [IsnadNode]
    /// The English of a hadith chain's word of transmission ("narrated to us"), drawn under the Arabic
    /// title when the chain is shown with its English (HadithIsnadEnglish). Nil everywhere else.
    var subtitle: String? = nil
    var id: String { title + nodes.map(\.id).joined() }
}

/// One road below the point where a chain divides: its layers, top to bottom.
struct IsnadBranch: Identifiable {
    let id: String
    /// The road this page is about (or every road, where none is singled out): drawn at full strength.
    let highlighted: Bool
    let layers: [IsnadLayer]
}

/// A whole chain: the layers every road shares, then the roads side by side (none for a single line),
/// then what they meet in again at the foot (a hadith's collector, who received it by two roads).
struct IsnadChain {
    let top: [IsnadLayer]
    let branches: [IsnadBranch]
    var bottom: [IsnadLayer] = []
    /// The spread below the last narrator drawn (`IsnadFan`), in the compact look.
    var fan: IsnadFan? = nil

    var isEmpty: Bool { top.isEmpty && branches.isEmpty && bottom.isEmpty }
}

#if os(iOS)
// MARK: - The diagram

/// The chain as a vertical diagram: one row per generation, connected top to bottom, the Prophet ﷺ at
/// the top, and below the point where the chain divides one column per road. Draws the same on the
/// page and in the shared image.
struct IsnadDiagram: View {
    @Environment(\.appearance) private var appearance

    let chain: IsnadChain
    /// The rendered image's fixed light look (the page follows the app's theme).
    var forImage = false
    /// A hadith chain's narrators open their profiles: every node with a `narratorID` becomes a
    /// button (never in the image). The page decides what a tap does.
    var onNarratorTap: ((Int) -> Void)? = nil
    /// A hadith chain (Abu, 2026-10-31: "the text for the chain is too small", "have the line between
    /// each one be smaller"): the Arabic a size up and the links between generations half as tall.
    /// The article chains keep their measure.
    var hadith = false
    /// The short look (Abu, 2026-11-22, of a chain drawn as slim capsules: "make the thing each one
    /// short like that instead of so big"): every narrator one capsule about a finger tall, his name
    /// and its English on two tight lines; the word of transmission a line of text on the link, not
    /// a box of its own; a node's `count` badged at its far side; the chain's `fan` at its foot. A
    /// hadith chain is always drawn so (its cards stood 108 points apiece, three and a half to a
    /// screen); an article's chain asks for it (`ArticleIsnad.compact`).
    var compact = false

    private var accent: Color { appearance.accent }
    private var isCompact: Bool { hadith || compact }
    /// The straight part of a link above and below its chevron.
    private var linkHeight: CGFloat { isCompact ? 5 : 14 }

    /// The gap between the branch columns; `IsnadBranchSplit` aims its legs at their centres.
    private static let columnSpacing: CGFloat = 10

    var body: some View {
        VStack(spacing: 0) {
            // By place, not by `IsnadLayer.id`: one road can hold two equal generations ("عن أبيه" twice
            // in the chain of tirmidhi:1081, Ibrahim ibn Sa'd from his father and 'Umar ibn Abi Salamah
            // from his), and a chain never reorders under the diagram.
            ForEach(Array(chain.top.enumerated()), id: \.offset) { index, layer in
                layerBlock(layer, leads: index == 0)
                if index < chain.top.count - 1 {
                    connector
                }
            }

            if chain.branches.count == 1, let branch = chain.branches.first {
                if !chain.top.isEmpty { connector }
                branchColumn(branch)
            } else if chain.branches.count > 1 {
                // Where the one chain becomes several: a stem, a bar, and a leg down to each road.
                IsnadBranchSplit(columns: chain.branches.count, spacing: Self.columnSpacing)
                    .stroke(accent.opacity(0.45), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(height: 26)
                    .padding(.top, 2)

                HStack(alignment: .top, spacing: Self.columnSpacing) {
                    ForEach(chain.branches) { branch in
                        branchColumn(branch)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            if !chain.bottom.isEmpty {
                if chain.branches.count > 1 {
                    // The roads close again, the split drawn upside down.
                    IsnadBranchSplit(columns: chain.branches.count, spacing: Self.columnSpacing)
                        .stroke(accent.opacity(0.45), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(height: 26)
                        .scaleEffect(x: 1, y: -1)
                        .padding(.top, 2)
                } else {
                    connector
                }
                ForEach(Array(chain.bottom.enumerated()), id: \.offset) { index, layer in
                    layerBlock(layer)
                    if index < chain.bottom.count - 1 {
                        connector
                    }
                }
            }

            if let fan = chain.fan {
                fanFoot(fan)
            }
        }
        // Its own height, never one handed down: in a List row the stack was offered the row's
        // height to share out, and every name with a `minimumScaleFactor` shrank to fit its share
        // instead of taking its line (a chain stood in a row 50 points taller than it drew, with
        // "Umar" a size smaller than "ibn al-Khattab" beside it).
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, isCompact ? 2 : 6)
    }

    /// The chain's spread at its foot: rays from the last narrator down to a row of dots, and the
    /// line that names them.
    private func fanFoot(_ fan: IsnadFan) -> some View {
        VStack(spacing: 6) {
            IsnadFanRays(rays: fan.rays)
                .stroke(accent.opacity(0.45), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .frame(height: 30)
                .overlay(alignment: .bottom) {
                    HStack(spacing: 0) {
                        ForEach(0..<max(fan.rays, 1), id: \.self) { index in
                            Circle()
                                .fill(accent.opacity(0.85))
                                .frame(width: 7, height: 7)
                            if index < fan.rays - 1 { Spacer(minLength: 0) }
                        }
                    }
                    .offset(y: 3.5)
                }
                .padding(.horizontal, 4)
                .padding(.top, 2)

            Text(fan.caption)
                .font(.caption.weight(.medium))
                .foregroundColor(forImage ? Color.black.opacity(0.55) : Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .frame(maxWidth: 320)
        .accessibilityElement(children: .combine)
    }

    /// A generation's title: the article chains' small capitals, or a hadith chain's Arabic word of
    /// transmission (حدثنا, عن) in the Arabic face, never tracked (spacing letters breaks their joins),
    /// with its English beside it when the chain carries one.
    @ViewBuilder
    private func layerTitle(_ title: String, subtitle: String? = nil, tracking: CGFloat, narrow: Bool = false) -> some View {
        if title.isEmpty {
            EmptyView()
        } else if Self.isArabic(title) {
            let word = Text(verbatim: title)
                .font(appearance.islamArabicFont(base: hadith ? 16 : 15, relativeTo: .caption))
                .foregroundColor(forImage ? Color.black.opacity(hadith ? 0.7 : 0.55) : (hadith ? Color.primary.opacity(0.75) : Color.secondary))
            let meaning = Text(subtitle ?? "")
                .font(hadith ? .caption.weight(.medium) : .caption2)
                .foregroundColor(forImage ? Color.black.opacity(0.5) : Color.secondary)
            if hadith {
                // The word of transmission is the label of its link: a line of text the link runs
                // into and the arrow runs on from, the word and its meaning side by side in the
                // chain's one column and stacked in a road's (two or three side by side). It was
                // a bordered capsule of its own between every two narrators until 2026-11-22.
                transmissionLabel(word: word, meaning: (subtitle ?? "").isEmpty ? nil : meaning, stacked: narrow)
            } else {
                VStack(spacing: 1) {
                    word
                        .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                        .lineLimit(1)
                    if let subtitle, !subtitle.isEmpty {
                        meaning
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
        } else {
            Text(title)
                .font(.caption2.weight(.bold))
                .tracking(AppLanguage.letterSpacing(tracking))
                .foregroundStyle(forImage ? Color.black.opacity(0.55) : Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
        }
    }

    private static func isArabic(_ text: String) -> Bool {
        text.unicodeScalars.contains(where: { (0x0600...0x06FF).contains($0.value) })
    }

    /// `stacked` is told, never measured: a `ViewThatFits` here answered the stacked height when the
    /// List sized the row and drew the one line, so the chain stood in 46 points of empty row.
    private func transmissionLabel(word: Text, meaning: Text?, stacked: Bool) -> some View {
        let arabic = word
            .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
            .lineLimit(1)
            .fixedSize()
        return Group {
            if let meaning, stacked {
                VStack(spacing: 0) {
                    arabic
                        .frame(height: 20)
                    meaning.lineLimit(1).minimumScaleFactor(0.8)
                }
            } else if let meaning {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    arabic
                    meaning.lineLimit(1).minimumScaleFactor(0.8)
                }
                // The Arabic face's line is half again as tall as its letters: the label keeps
                // the height of its English, and the word's marks draw past it.
                .frame(height: 20)
            } else {
                arabic
                    .frame(height: 20)
            }
        }
        .padding(.horizontal, 6)
    }

    /// A generation: its title, then its people. A hadith chain's word of transmission sits on the
    /// link itself, so the arrow runs on from it to the narrator who received by it; every other
    /// title stands `gap` above its people, as it always has.
    private func generation<People: View>(_ layer: IsnadLayer, tracking: CGFloat, gap: CGFloat, leads: Bool = false,
                                          narrow: Bool = false, @ViewBuilder people: () -> People) -> some View {
        VStack(spacing: 0) {
            if !layer.title.isEmpty {
                layerTitle(layer.title, subtitle: layer.subtitle, tracking: tracking, narrow: narrow)
                if hadith, Self.isArabic(layer.title) {
                    arrowHead
                        .padding(.bottom, 2)
                } else {
                    Color.clear.frame(height: gap)
                }
            } else if isCompact, !leads {
                // A compact chain with no word on this link: the arrow alone. Nothing over the
                // generation the diagram opens with (`leads`).
                arrowHead
                    .padding(.bottom, 2)
            }
            people()
        }
    }

    private var arrowHead: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: isCompact ? 9 : 11, weight: .bold))
            .foregroundColor(accent.opacity(0.7))
    }

    /// One road, top-down: a chevron from the split, then each layer stacked (a column is too narrow to
    /// set two people side by side).
    private func branchColumn(_ branch: IsnadBranch) -> some View {
        VStack(spacing: 0) {
            if !isCompact {
                arrowHead
                    .padding(.bottom, 4)
            }

            ForEach(Array(branch.layers.enumerated()), id: \.offset) { index, layer in
                generation(layer, tracking: 0.6, gap: 6, leads: index == 0 && chain.top.isEmpty && chain.branches.count == 1,
                           narrow: chain.branches.count > 1) {
                    VStack(spacing: 6) {
                        ForEach(layer.nodes) { node in
                            nodeChip(node)
                        }
                    }
                }
                if index < branch.layers.count - 1 {
                    connector
                }
            }
        }
        // A road that is not this page's own: present, but a step back.
        .opacity(branch.highlighted ? 1 : 0.8)
    }

    /// The link from one generation down to the next. The compact look draws only the line here:
    /// the next generation brings its own label and arrow (`generation`).
    @ViewBuilder
    private var connector: some View {
        if isCompact {
            Rectangle()
                .fill(accent.opacity(0.45))
                .frame(width: 2, height: linkHeight)
                .padding(.top, 2)
        } else {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(accent.opacity(0.45))
                    .frame(width: 2, height: linkHeight)
                arrowHead
                Rectangle()
                    .fill(accent.opacity(0.45))
                    .frame(width: 2, height: linkHeight)
            }
            .padding(.vertical, 2)
        }
    }

    private func layerBlock(_ layer: IsnadLayer, leads: Bool = false) -> some View {
        generation(layer, tracking: 0.8, gap: 8, leads: leads) {
            if layer.nodes.count == 1, let node = layer.nodes.first {
                nodeChip(node)
                    .frame(maxWidth: isCompact ? 320 : 300)
            } else {
                // Centered rows (Abu, 2026-09-25: "some arent centered"): an adaptive grid filled its
                // columns from the leading edge, so a pair sat at the left of a wide row on iPad and Mac.
                IsnadCenteredRows(spacing: 8) {
                    ForEach(layer.nodes) { node in
                        nodeChip(node)
                            .frame(maxHeight: .infinity)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func nodeChip(_ node: IsnadNode) -> some View {
        if let onNarratorTap, let narratorID = node.narratorID, !forImage {
            Button {
                onNarratorTap(narratorID)
            } label: {
                chip(node, tappable: true)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Opens every narration naming this narrator"))
        } else {
            chip(node, tappable: false)
        }
    }

    @ViewBuilder
    private func chip(_ node: IsnadNode, tappable: Bool) -> some View {
        if isCompact {
            compactChip(node, tappable: tappable)
        } else {
            chipBody(node, tappable: tappable)
        }
    }

    /// One narrator as a short capsule: the name as the narration writes it and its English on two
    /// tight lines (a hadith chain), or the one name an article gives. An aside in Arabic ("على
    /// المنبر") runs on after the Arabic name, any other detail after the English. The chevron of a
    /// narrator who opens his page, or the node's count, sits at the far side, and the text keeps
    /// the same room on both sides so it stays centred.
    private func compactChip(_ node: IsnadNode, tappable: Bool) -> some View {
        let filled = node.role == .prophet || node.role == .narrator || node.role == .source
        let outlined = node.role == .imam || node.role == .companion
        let primaryText: Color = forImage ? .black : .primary
        let secondaryText: Color = forImage ? Color.black.opacity(0.6) : .secondary
        let large = node.role == .prophet || node.role == .source
        let arabicDetail = node.detail.flatMap { Self.isArabic($0) ? $0 : nil }
        let latinDetail = node.detail.flatMap { Self.isArabic($0) ? nil : $0 }
        let hasAccessory = tappable || node.count != nil
        let shape = RoundedRectangle(cornerRadius: 23, style: .continuous)

        let arabicLine = Group {
            if !node.arabic.isEmpty {
                (Text(node.arabic)
                    .foregroundColor(filled ? .white : accent)
                 + Text(arabicDetail.map { "  \($0)" } ?? "")
                    .font(appearance.islamArabicFont(base: 14, relativeTo: .footnote))
                    .foregroundColor(filled ? Color.white.opacity(0.85) : secondaryText))
                    .font(appearance.islamArabicFont(base: large ? 20 : 18, relativeTo: .body))
                    .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.center)
            }
        }
        let nameLine = Group {
            if !node.name.isEmpty {
                (Text(node.name)
                    .fontWeight(.semibold)
                    .foregroundColor(filled ? .white : primaryText)
                 + Text(latinDetail.map { " · \($0)" } ?? "")
                    .foregroundColor(filled ? Color.white.opacity(0.85) : secondaryText))
                    // The one line of an article's node reads a size up; under an Arabic name it
                    // is the caption it always was.
                    .font(node.arabic.isEmpty ? .subheadline : .caption)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
        }

        return VStack(spacing: 0) {
            // The Arabic face's line stands half again as tall as its letters; the capsule
            // keeps the letters' share of it.
            arabicLine
                .padding(.vertical, -3)
            nameLine
        }
        .padding(.horizontal, hasAccessory ? 30 : 16)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, minHeight: 44)
        .overlay(alignment: .trailing) {
            if let count = node.count {
                Text(count)
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundColor(filled ? .white : accent)
                    .frame(minWidth: 22, minHeight: 22)
                    .overlay(Circle().strokeBorder(filled ? Color.white.opacity(0.7) : accent.opacity(0.6), lineWidth: 1))
                    .padding(.trailing, 9)
            } else if tappable {
                Image(systemName: "chevron.forward")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(filled ? Color.white.opacity(0.8) : accent.opacity(0.55))
                    .padding(.trailing, 12)
            }
        }
        .contentShape(shape)
        .background(
            shape
                .fill(filled
                      ? AnyShapeStyle(LinearGradient(colors: [accent, accent.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                      : AnyShapeStyle(accent.opacity(node.role == .student ? 0.06 : 0.1)))
        )
        .overlay(
            shape.strokeBorder(accent.opacity(outlined ? 0.55 : (filled ? 0 : 0.2)), lineWidth: outlined ? 1.5 : 1)
        )
    }

    private func chipBody(_ node: IsnadNode, tappable: Bool) -> some View {
        let filled = node.role == .prophet || node.role == .narrator || node.role == .source
        let outlined = node.role == .imam || node.role == .companion
        let primaryText: Color = forImage ? .black : .primary
        let secondaryText: Color = forImage ? Color.black.opacity(0.6) : .secondary

        let large = node.role == .prophet || node.role == .source
        return VStack(spacing: 3) {
            Text(node.arabic)
                .font(appearance.islamArabicFont(base: large ? 22 : 17, relativeTo: .body))
                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                .foregroundColor(filled ? .white : accent)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)

            if !node.name.isEmpty {
                Text(node.name)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(filled ? .white : primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }

            if let detail = node.detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(filled ? Color.white.opacity(0.85) : secondaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }

        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(filled
                      ? AnyShapeStyle(LinearGradient(colors: [accent, accent.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing))
                      : AnyShapeStyle(accent.opacity(node.role == .student ? 0.06 : 0.1)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(accent.opacity(outlined ? 0.55 : 0), lineWidth: 1.5)
        )
    }
}

/// The rays of a chain's spread (`IsnadFan`): from the top centre down to `rays` points set evenly
/// along the bottom edge, where the dots sit.
struct IsnadFanRays: Shape {
    let rays: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard rays > 0 else { return path }
        let inset: CGFloat = 3.5
        let span = rect.width - inset * 2
        for index in 0..<rays {
            let x = rays == 1 ? rect.midX : rect.minX + inset + span * CGFloat(index) / CGFloat(rays - 1)
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        return path
    }
}

/// The fork where a chain divides: one stem down from the centre, a bar across, and a leg down to the
/// centre of each road's column (columns equal width, `spacing` apart).
struct IsnadBranchSplit: Shape {
    let columns: Int
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard columns > 0 else { return path }
        let columnWidth = (rect.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let centres = (0..<columns).map { rect.minX + columnWidth / 2 + CGFloat($0) * (columnWidth + spacing) }
        let bar = rect.minY + rect.height * 0.45
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: bar))
        if let first = centres.first, let last = centres.last {
            path.move(to: CGPoint(x: first, y: bar))
            path.addLine(to: CGPoint(x: last, y: bar))
        }
        for x in centres {
            path.move(to: CGPoint(x: x, y: bar))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        return path
    }
}

/// One generation with more than one person in it: equal-width cards in as many columns as fit (never
/// more than there are people), each ROW centered, and the cards of a row stretched to the row's
/// tallest so a two-line name does not leave its neighbour short.
@available(iOS 16.0, *)
private struct IsnadCenteredRows: Layout {
    var spacing: CGFloat = 8
    var minItemWidth: CGFloat = 132
    var maxItemWidth: CGFloat = 200

    private func metrics(width: CGFloat, count: Int) -> (columns: Int, itemWidth: CGFloat) {
        guard count > 0 else { return (1, 0) }
        let fit = max(1, Int((width + spacing) / (minItemWidth + spacing)))
        let columns = min(count, fit)
        let itemWidth = min(maxItemWidth, (width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
        return (columns, max(0, itemWidth))
    }

    private func rows(_ subviews: Subviews, columns: Int, itemWidth: CGFloat) -> [(range: Range<Int>, height: CGFloat)] {
        stride(from: 0, to: subviews.count, by: columns).map { start in
            let range = start..<min(start + columns, subviews.count)
            let height = range.map {
                subviews[$0].sizeThatFits(ProposedViewSize(width: itemWidth, height: nil)).height
            }.max() ?? 0
            return (range, height)
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width
            ?? (maxItemWidth * CGFloat(subviews.count) + spacing * CGFloat(max(0, subviews.count - 1)))
        let (columns, itemWidth) = metrics(width: width, count: subviews.count)
        let heights = rows(subviews, columns: columns, itemWidth: itemWidth).map(\.height)
        let height = heights.reduce(0, +) + spacing * CGFloat(max(0, heights.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let (columns, itemWidth) = metrics(width: bounds.width, count: subviews.count)
        var y = bounds.minY
        for row in rows(subviews, columns: columns, itemWidth: itemWidth) {
            let rowWidth = itemWidth * CGFloat(row.range.count) + spacing * CGFloat(row.range.count - 1)
            var x = bounds.midX - rowWidth / 2
            for index in row.range {
                subviews[index].place(at: CGPoint(x: x, y: y),
                                      proposal: ProposedViewSize(width: itemWidth, height: row.height))
                x += itemWidth + spacing
            }
            y += row.height + spacing
        }
    }
}

// MARK: - Sharing

/// The diagram framed for sharing: a title, the chain, and the app's name at the foot, on paper.
struct IsnadShareCard: View {
    static let width: CGFloat = 560

    let title: String
    let subtitle: String
    /// The line at the foot ("Al-Islam · The Ten Qiraat"); empty for the app's name alone.
    var footer: String = ""
    let chain: IsnadChain
    /// A hadith chain's measure (`IsnadDiagram.hadith`).
    var hadith = false
    /// The short look (`IsnadDiagram.compact`).
    var compact = false

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.black)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(Color.black.opacity(0.6))
                }
            }
            .multilineTextAlignment(.center)

            IsnadDiagram(chain: chain, forImage: true, hadith: hadith, compact: compact)

            Text(verbatim: footer.isEmpty ? AppIdentifiers.displayName : footer)
                .font(.caption2.weight(.semibold))
                .foregroundColor(Color.black.opacity(0.45))
        }
        .padding(24)
        .frame(width: Self.width)
        .background(Color(red: 0.99, green: 0.98, blue: 0.95))
    }
}

/// The rendered chains of this session, by title, theme and direction: a second share of the same
/// chain opens the sheet at once.
@MainActor
private enum IsnadShareCache {
    static var files: [String: URL] = [:]
    #if DEBUG
    /// The launch arguments already acted on ("-shareChain", "-shareIsnadTree"): each fires once.
    static var debugShared: Set<String> = []
    #endif
}

/// "Share the Chain as an Image" as ONE tap (Abu, 2026-10-27: "Share the chain as an image is laggy").
/// It used to take two: the first rendered the card on the main thread at 3x with no feedback (the
/// spinner was set and cleared in the same pass, so it never drew), and only then did the row become
/// a `ShareLink`, whose sheet encoded the 6.5-megapixel image as it opened. Now the tap shows the
/// spinner, the card is rendered at 2x (1,120 px wide, plenty for any chat or feed), the PNG is encoded
/// and written off the main thread to a file named after the chain, and the share sheet opens on that
/// file. Measured on the simulator: render 27-70 ms, PNG 61-73 ms at 3x.
///
/// Any card can be shared this way (a hadith's tree of narrators, HadithIsnadTreeView.swift): the
/// button takes the card to render, its width in points and the pixels per point; the chain's card
/// is the convenience below.
@available(iOS 16.0, *)
struct IsnadShareButton<Card: View>: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.layoutDirection) private var layoutDirection

    let label: String
    /// The shared image's title: its file name, and with `salt` its key in the session's cache.
    let title: String
    var salt: String = ""
    /// The card's width in points, and the pixels per point of the image: 2 for a chain, less for a
    /// tree too wide for that.
    let width: CGFloat
    var scale: CGFloat = 2
    /// The DEBUG launch argument that presses this button once, for a headless check of the flow.
    var debugArgument: String = "-shareChain"
    @ViewBuilder let card: () -> Card

    @State private var preparing = false

    var body: some View {
        Button {
            share()
        } label: {
            // One soft button the width of the chain it shares, the spinner in the glyph's place
            // while the image is made (it was a line of accent text with the spinner at the far edge).
            HStack(spacing: 8) {
                if preparing {
                    ProgressView()
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
                Text(label)
                    .multilineTextAlignment(.center)
            }
            // The label reads the interface's way. The direction this button SITS in is the
            // diagram's (right to left for a hadith chain), which only the image should take.
            .environment(\.layoutDirection, AppLanguage.isRightToLeft ? .rightToLeft : .leftToRight)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(appearance.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(appearance.accent.opacity(0.1)))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.borderless)
        .disabled(preparing)
        #if DEBUG
        .onAppear {
            // "-shareChain": share the first chain on screen, for a headless check of the flow.
            guard ProcessInfo.processInfo.arguments.contains(debugArgument),
                  !IsnadShareCache.debugShared.contains(debugArgument) else { return }
            IsnadShareCache.debugShared.insert(debugArgument)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { share() }
        }
        #endif
    }

    private var cacheKey: String {
        "\(title)|\(salt)|\(layoutDirection == .rightToLeft)|\(appearance.accent.description)"
    }

    @MainActor
    private func share() {
        Settings.shared.hapticFeedback()
        if let file = IsnadShareCache.files[cacheKey], FileManager.default.fileExists(atPath: file.path) {
            presentSystemShareSheet(items: [file])
            return
        }
        preparing = true
        let key = cacheKey
        let name = Self.fileName(title)
        Task { @MainActor in
            // One frame for the spinner before the render takes the main thread.
            try? await Task.sleep(nanoseconds: 30_000_000)
            let content = card()
                .environment(\.injectedAppearance, appearance)
                // The renderer starts from a default environment: without this the image would lay the
                // roads out left to right while the page beside it reads right to left.
                .environment(\.layoutDirection, layoutDirection)
            let renderer = ImageRenderer(content: content)
            renderer.scale = scale
            renderer.proposedSize = ProposedViewSize(width: width, height: nil)
            guard let image = renderer.uiImage else {
                preparing = false
                return
            }
            let file: URL? = await Task.detached(priority: .userInitiated) {
                guard let data = image.pngData() else { return nil }
                let folder = FileManager.default.temporaryDirectory.appendingPathComponent("Chains", isDirectory: true)
                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                let url = folder.appendingPathComponent(name)
                do { try data.write(to: url, options: .atomic) } catch { return nil }
                return url
            }.value
            preparing = false
            guard let file else { return }
            // One file per title: another look of it cached before (the tree's other scope, another
            // accent or direction) no longer has its image there, so it renders again when asked.
            IsnadShareCache.files = IsnadShareCache.files.filter { $0.value != file }
            IsnadShareCache.files[key] = file
            presentSystemShareSheet(items: [file])
        }
    }

    /// "Warsh an Nafi.png": the title, without the characters a file name cannot hold.
    private static func fileName(_ title: String) -> String {
        let cleaned = title.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>")).joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (cleaned.isEmpty ? "Chain" : cleaned) + ".png"
    }
}

@available(iOS 16.0, *)
extension IsnadShareButton where Card == IsnadShareCard {
    /// A chain's card: the title, the chain, the app's name at the foot, 560 points wide at 2x. A
    /// hadith chain's `salt` tells its English look from its Arabic one in the session's cache.
    init(label: String, title: String, subtitle: String, footer: String = "", chain: IsnadChain, hadith: Bool = false,
         compact: Bool = false, salt: String = "") {
        self.init(label: label, title: title, salt: subtitle + salt, width: IsnadShareCard.width) {
            IsnadShareCard(title: title, subtitle: subtitle, footer: footer, chain: chain, hadith: hadith, compact: compact)
        }
    }
}
#endif

// MARK: - Chains in the articles

/// A chain an article draws, with what its shared image is called.
struct ArticleIsnad {
    /// The shared image's title, and its file name.
    let title: String
    let subtitle: String
    let chain: IsnadChain
    /// Drawn in the short look (`IsnadDiagram.compact`): one capsule a narrator, counts and a fan.
    var compact = false
}

/// One chain inside an article: the caption that names its people in order (the words the corpus
/// builder reads, `ISNAD_RE` in Scripts/build_islam_corpus.py, so Ask AI keeps them), the diagram,
/// and the way to share it. On the watch, the same chain as plain rows.
struct ArticleIsnadCard: View {
    let caption: String
    let isnad: ArticleIsnad

    init(_ caption: String, isnad: ArticleIsnad) {
        self.caption = caption
        self.isnad = isnad
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(caption)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            #if os(iOS)
            IsnadDiagram(chain: isnad.chain, compact: isnad.compact)
            IsnadShareButton(label: AppLanguage.article("Share the Chain as an Image"),
                             title: isnad.title, subtitle: isnad.subtitle, chain: isnad.chain, compact: isnad.compact)
                .padding(.top, isnad.compact ? 8 : 2)
            #else
            IsnadPlainList(chain: isnad.chain)
            #endif
        }
        .padding(.vertical, 6)
    }
}

#if !os(iOS)
/// The watch's chain: every layer as a titled list, the roads one after the other.
private struct IsnadPlainList: View {
    let chain: IsnadChain

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(chain.top) { layer in rows(layer) }
            ForEach(chain.branches) { branch in
                ForEach(branch.layers) { layer in rows(layer) }
            }
            if let fan = chain.fan {
                Text(fan.caption).font(.footnote).foregroundColor(.secondary)
            }
        }
    }

    private func rows(_ layer: IsnadLayer) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if !layer.title.isEmpty {
                Text(layer.title).font(.caption2.weight(.bold)).foregroundColor(.secondary)
            }
            ForEach(layer.nodes) { node in
                // A counted level reads "1 · ‘Umar ibn al-Khattab".
                Text((node.count.map { "\($0) · " } ?? "") + (node.name.isEmpty ? node.arabic : node.name)).font(.footnote)
            }
        }
    }
}
#endif

extension ArticleIsnad {
    private static let prophet = IsnadNode(name: "Prophet Muhammad ﷺ", arabic: "رَسُولُ اللَّهِ ﷺ", detail: "d. 11 AH", role: .prophet)

    private static func node(_ name: String, _ arabic: String, _ detail: String, _ role: IsnadNode.Role) -> IsnadNode {
        IsnadNode(name: name, arabic: arabic, detail: detail, role: role)
    }

    private static func layer(_ title: String, _ nodes: IsnadNode...) -> IsnadLayer {
        IsnadLayer(title: title, nodes: nodes)
    }

    /// The first hadith of Sahih al-Bukhari and the same hadith in Sahih Muslim (1907): one chain from
    /// the Prophet ﷺ to Yahya ibn Sa'id al-Ansari, where it divides. Read from the Arabic of both rows on
    /// the shelf; death dates from Ibn Hajar's Taqrib at-Tahdhib.
    static let bukhariFirst = ArticleIsnad(
        title: "Actions Are by Intentions",
        subtitle: "Saheeh al-Bukhaari 1 · Saheeh Muslim 1907",
        chain: IsnadChain(
            top: [
                layer("THE PROPHET ﷺ", prophet),
                layer("THE COMPANION", node("Umar ibn al-Khattaab", "عُمَرُ بنُ الخَطَّابِ", "d. 23 AH, from the minbar", .companion)),
                layer("THE SUCCESSOR", node("Alqamah ibn Waqqaas al-Laythi", "عَلقَمَةُ بنُ وَقَّاصٍ اللَّيثِيُّ", "of Madinah, d. 65–86 AH", .successor)),
                layer("HIS STUDENT", node("Muhammad ibn Ibraaheem at-Taymi", "مُحَمَّدُ بنُ إِبرَاهِيمَ التَّيمِيُّ", "of Madinah, d. 120 AH", .successor)),
                layer("WHERE THE CHAIN DIVIDES", node("Yahya ibn Sa‘eed al-Ansaari", "يَحيَى بنُ سَعِيدٍ الأَنصَارِيُّ", "of Madinah, d. 144 AH or after", .imam)),
            ],
            branches: [
                IsnadBranch(id: "bukhari", highlighted: true, layers: [
                    layer("HIS STUDENT", node("Sufyaan ibn Uyaynah", "سُفيَانُ بنُ عُيَينَةَ", "of Makkah, d. 198 AH", .link)),
                    layer("HIS STUDENT", node("al-Humaydi", "عَبدُ اللَّهِ بنُ الزُّبَيرِ الحُمَيدِيُّ", "of Makkah, d. 219 AH", .link)),
                    layer("THE COLLECTOR", node("al-Bukhaari", "مُحَمَّدُ بنُ إِسمَاعِيلَ البُخَارِيُّ", "d. 256 AH", .narrator)),
                ]),
                IsnadBranch(id: "muslim", highlighted: true, layers: [
                    layer("HIS STUDENT", node("Maalik ibn Anas", "مَالِكُ بنُ أَنَسٍ", "of Madinah, d. 179 AH", .link)),
                    layer("HIS STUDENT", node("al-Qa‘nabi", "عَبدُ اللَّهِ بنُ مَسلَمَةَ القَعنَبِيُّ", "of Basrah, d. 221 AH", .link)),
                    layer("THE COLLECTOR", node("Muslim", "مُسلِمُ بنُ الحَجَّاجِ", "d. 261 AH", .narrator)),
                ]),
            ]))

    /// The hadith of intentions counted at each level (Sahih al-Bukhari 1, Sahih Muslim 1907): one
    /// narrator at each of its first four links, then the many who took it from Yahya ibn Sa‘id. The
    /// narrowest point is one, so the scholars of hadith call it gharib; the same five men head
    /// `bukhariFirst` above, which gives their dates.
    static let intentionsNarrowing = ArticleIsnad(
        title: "Named by Its Narrowest Point",
        subtitle: "The hadith of intentions, counted at each level",
        chain: IsnadChain(
            top: [
                IsnadLayer(title: "", nodes: [IsnadNode(name: "The Prophet ﷺ", arabic: "", role: .prophet)]),
                IsnadLayer(title: "", nodes: [IsnadNode(name: "Umar ibn al-Khattaab", arabic: "", role: .companion, count: "1")]),
                IsnadLayer(title: "", nodes: [IsnadNode(name: "Alqamah ibn Waqqaas", arabic: "", role: .link, count: "1")]),
                IsnadLayer(title: "", nodes: [IsnadNode(name: "Muhammad ibn Ibraaheem at-Taymi", arabic: "", role: .link, count: "1")]),
                IsnadLayer(title: "", nodes: [IsnadNode(name: "Yahya ibn Sa‘eed al-Ansaari", arabic: "", role: .link, count: "1")]),
            ],
            branches: [],
            fan: IsnadFan(rays: 9, caption: "then a great many narrators from Yahya")),
        compact: true)

    /// The Sahifah of Hammam ibn Munabbih, which both Sahihs take from ‘Abd ar-Razzaq: Sahih al-Bukhari
    /// 2073 through Yahya ibn Musa, Sahih Muslim 225 through Muhammad ibn Rafi‘ (read from both rows).
    static let hammamSahifah = ArticleIsnad(
        title: "The Saheefah of Hammaam",
        subtitle: "Saheeh al-Bukhaari 2073 · Saheeh Muslim 225",
        chain: IsnadChain(
            top: [
                layer("THE PROPHET ﷺ", prophet),
                layer("THE COMPANION", node("Abu Hurayrah", "أَبُو هُرَيرَةَ", "d. 57–59 AH", .companion)),
                layer("WHO WROTE IT DOWN", node("Hammaam ibn Munabbih", "هَمَّامُ بنُ مُنَبِّهٍ", "of San‘a, d. 132 AH", .successor)),
                layer("HIS STUDENT", node("Ma‘mar ibn Raashid", "مَعمَرُ بنُ رَاشِدٍ", "of Basrah, settled in Yemen, d. 154 AH", .link)),
                layer("WHERE THE CHAIN DIVIDES", node("Abd ar-Razzaaq as-San‘aani", "عَبدُ الرَّزَّاقِ الصَّنعَانِيُّ", "author of the Musannaf, d. 211 AH", .imam)),
            ],
            branches: [
                IsnadBranch(id: "bukhari", highlighted: true, layers: [
                    layer("HIS STUDENT", node("Yahya ibn Moosa", "يَحيَى بنُ مُوسَى", "of Balkh, d. 240 AH", .link)),
                    layer("THE COLLECTOR", node("al-Bukhaari", "مُحَمَّدُ بنُ إِسمَاعِيلَ البُخَارِيُّ", "d. 256 AH", .narrator)),
                ]),
                IsnadBranch(id: "muslim", highlighted: true, layers: [
                    layer("HIS STUDENT", node("Muhammad ibn Raafi‘", "مُحَمَّدُ بنُ رَافِعٍ", "of Nishapur, d. 245 AH", .link)),
                    layer("THE COLLECTOR", node("Muslim", "مُسلِمُ بنُ الحَجَّاجِ", "d. 261 AH", .narrator)),
                ]),
            ]))

    /// Malik from Nafi‘ from Ibn ‘Umar, which al-Bukhari called the soundest of chains, carried on to
    /// ash-Shafi‘i, Malik's student, and Ahmad, ash-Shafi‘i's: the chain the scholars called golden.
    static let goldenChain = ArticleIsnad(
        title: "The Golden Chain",
        subtitle: "Maalik from Naafi‘ from Ibn Umar",
        chain: IsnadChain(
            top: [
                layer("THE PROPHET ﷺ", prophet),
                layer("THE COMPANION", node("Abdullah ibn Umar", "عَبدُ اللَّهِ بنُ عُمَرَ", "d. 73 AH", .companion)),
                layer("HIS FREED SLAVE", node("Naafi‘", "نَافِعٌ مَولَى ابنِ عُمَرَ", "of Madinah, d. 117 AH", .successor)),
                layer("THE IMAM OF MADINAH", node("Maalik ibn Anas", "مَالِكُ بنُ أَنَسٍ", "d. 179 AH", .narrator)),
                layer("HIS STUDENT", node("ash-Shaafi‘i", "مُحَمَّدُ بنُ إِدرِيسَ الشَّافِعِيُّ", "d. 204 AH", .link)),
                layer("HIS STUDENT", node("Ahmad ibn Hanbal", "أَحمَدُ بنُ حَنبَلٍ", "d. 241 AH", .link)),
            ],
            branches: []))

    /// How the Quran came to the cities: Allah's speech, through Jibril, to the Prophet ﷺ; taught to
    /// the Companions; gathered under Abu Bakr; kept by Hafsah; copied under ‘Uthman; sent out to the
    /// cities whose readers became the ten imams. Sahih al-Bukhari 4986 and 4987, and 4999 for the four
    /// the Prophet named.
    static let quranCompilation = ArticleIsnad(
        title: "How the Quran Reached Us",
        subtitle: "From the Prophet ﷺ to the copies of Uthmaan",
        chain: IsnadChain(
            top: [
                layer("THE SPEECH OF", node("Allah, Exalted is He", "اللَّهُ عَزَّ وَجَلَّ", "His speech, not created", .source)),
                layer("BROUGHT DOWN BY", node("Jibreel", "جِبرِيلُ عَلَيهِ السَّلَامُ", "the trustworthy Spirit (26:193)", .companion)),
                layer("TO", prophet),
                layer("WHO TAUGHT IT TO THE COMPANIONS",
                      node("Abdullah ibn Mas‘ood", "عَبدُ اللَّهِ بنُ مَسعُودٍ", "d. 32 AH", .companion),
                      node("Saalim, mawla of Abu Hudhayfah", "سَالِمٌ مَولَى أَبِي حُذَيفَةَ", "fell at al-Yamaamah, 12 AH", .companion),
                      node("Mu‘aadh ibn Jabal", "مُعَاذُ بنُ جَبَلٍ", "d. 18 AH", .companion),
                      node("Ubayy ibn Ka‘b", "أُبَيُّ بنُ كَعبٍ", "d. 30 AH", .companion),
                      node("Zayd ibn Thaabit", "زَيدُ بنُ ثَابِتٍ", "his scribe, d. 45 AH", .companion),
                      node("Ali ibn Abi Taalib", "عَلِيُّ بنُ أَبِي طَالِبٍ", "d. 40 AH", .companion)),
                layer("GATHERED INTO ONE VOLUME, 12 AH",
                      node("Abu Bakr as-Siddeeq", "أَبُو بَكرٍ الصِّدِّيقُ", "ordered it at Umar's counsel, d. 13 AH", .imam),
                      node("Zayd ibn Thaabit", "زَيدُ بنُ ثَابِتٍ", "gathered it from the written pieces and the memories of men", .link)),
                layer("KEPT BY", node("Hafsah bint Umar", "حَفصَةُ بِنتُ عُمَرَ", "the sheets passed from Abu Bakr to Umar, then to her", .link)),
                layer("COPIED UNDER UTHMAAN, c. 25 AH",
                      node("Uthmaan ibn Affaan", "عُثمَانُ بنُ عَفَّانَ", "ordered the copies, d. 35 AH", .imam),
                      node("Zayd ibn Thaabit", "زَيدُ بنُ ثَابِتٍ", "d. 45 AH", .link),
                      node("Abdullah ibn az-Zubayr", "عَبدُ اللَّهِ بنُ الزُّبَيرِ", "d. 73 AH", .link),
                      node("Sa‘eed ibn al-As", "سَعِيدُ بنُ العَاصِ", "d. c. 59 AH", .link),
                      node("Abd ar-Rahman ibn al-Haarith", "عَبدُ الرَّحمَنِ بنُ الحَارِثِ بنِ هِشَامٍ", "d. 43 AH", .link)),
                layer("SENT TO THE CITIES, AND READ THERE BY",
                      node("Madinah", "المَدِينَةُ", "Naafi‘ and Abu Ja‘far", .student),
                      node("Makkah", "مَكَّةُ", "Ibn Katheer", .student),
                      node("Shaam", "الشَّامُ", "Ibn Aamir", .student),
                      node("Basrah", "البَصرَةُ", "Abu Amr and Ya‘qoob", .student),
                      node("Koofah", "الكُوفَةُ", "Aasim, Hamzah, al-Kisaa’i and Khalaf", .student)),
            ],
            branches: []))

    /// Where the four imams learned: the Kufan road from Ibn Mas‘ud to Abu Hanifah, and the Madinan road
    /// from Ibn ‘Umar to Malik, ash-Shafi‘i and Ahmad.
    static let madhhabImams = ArticleIsnad(
        title: "Where the Four Imams Learned",
        subtitle: "From the Companions to the four madhaahib",
        chain: IsnadChain(
            top: [
                layer("THE PROPHET ﷺ", prophet),
            ],
            branches: [
                IsnadBranch(id: "kufa", highlighted: true, layers: [
                    layer("THE COMPANION", node("Abdullah ibn Mas‘ood", "عَبدُ اللَّهِ بنُ مَسعُودٍ", "d. 32 AH, taught in Koofah", .companion)),
                    layer("HIS STUDENT", node("Alqamah ibn Qays", "عَلقَمَةُ بنُ قَيسٍ النَّخَعِيُّ", "d. after 60 AH", .successor)),
                    layer("HIS STUDENT", node("Ibraaheem an-Nakha‘i", "إِبرَاهِيمُ النَّخَعِيُّ", "d. 96 AH", .successor)),
                    layer("HIS STUDENT", node("Hammaad ibn Abi Sulaymaan", "حَمَّادُ بنُ أَبِي سُلَيمَانَ", "d. 120 AH", .link)),
                    layer("THE IMAM", node("Abu Haneefah", "أَبُو حَنِيفَةَ النُّعمَانُ", "d. 150 AH", .narrator)),
                    layer("HIS STUDENTS",
                          node("Abu Yoosuf", "أَبُو يُوسُفَ", "d. 182 AH", .student),
                          node("Muhammad ash-Shaybaani", "مُحَمَّدُ بنُ الحَسَنِ الشَّيبَانِيُّ", "d. 189 AH", .student)),
                ]),
                IsnadBranch(id: "madinah", highlighted: true, layers: [
                    layer("THE COMPANION", node("Abdullah ibn Umar", "عَبدُ اللَّهِ بنُ عُمَرَ", "d. 73 AH, of Madinah", .companion)),
                    layer("HIS STUDENT", node("Naafi‘", "نَافِعٌ مَولَى ابنِ عُمَرَ", "d. 117 AH", .successor)),
                    layer("THE IMAM", node("Maalik ibn Anas", "مَالِكُ بنُ أَنَسٍ", "d. 179 AH", .narrator)),
                    layer("HIS STUDENT", node("ash-Shaafi‘i", "مُحَمَّدُ بنُ إِدرِيسَ الشَّافِعِيُّ", "d. 204 AH", .narrator)),
                    layer("HIS STUDENT", node("Ahmad ibn Hanbal", "أَحمَدُ بنُ حَنبَلٍ", "d. 241 AH", .narrator)),
                ]),
            ]))

    /// The reading of ‘Asim, through his two narrators, Hafs (highlighted: the narration most Muslims
    /// recite) and Shu‘bah: the Qiraat guide's own chain (QiraatIsnad), which the iPhone app carries.
    static var hafsReading: ArticleIsnad {
        #if os(iOS)
        let chain = QiraatIsnad.chain(master: Settings.Riwayah.asimTeacher, highlighting: Settings.Riwayah.hafsTag)
        #else
        let chain = IsnadChain(top: [], branches: [])
        #endif
        return ArticleIsnad(title: "Hafs an Aasim", subtitle: "The chain of the reading most Muslims recite", chain: chain)
    }
}
