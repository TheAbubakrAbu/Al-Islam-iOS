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

    var id: String { name + "|" + arabic }
}

struct IsnadLayer: Identifiable {
    let title: String
    let nodes: [IsnadNode]
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

    private var accent: Color { appearance.accent }

    /// The gap between the branch columns; `IsnadBranchSplit` aims its legs at their centres.
    private static let columnSpacing: CGFloat = 10

    var body: some View {
        VStack(spacing: 0) {
            // By place, not by `IsnadLayer.id`: one road can hold two equal generations ("عن أبيه" twice
            // in the chain of tirmidhi:1081, Ibrahim ibn Sa'd from his father and 'Umar ibn Abi Salamah
            // from his), and a chain never reorders under the diagram.
            ForEach(Array(chain.top.enumerated()), id: \.offset) { index, layer in
                layerBlock(layer)
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
        }
        .padding(.vertical, 6)
    }

    /// A generation's title: the article chains' small capitals, or a hadith chain's Arabic word of
    /// transmission (حدثنا, عن) in the Arabic face, never tracked (spacing letters breaks their joins).
    @ViewBuilder
    private func layerTitle(_ title: String, tracking: CGFloat) -> some View {
        if title.isEmpty {
            EmptyView()
        } else if title.unicodeScalars.contains(where: { (0x0600...0x06FF).contains($0.value) }) {
            Text(verbatim: title)
                .font(appearance.islamArabicFont(base: 15, relativeTo: .caption))
                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                .foregroundStyle(forImage ? Color.black.opacity(0.55) : Color.secondary)
                .lineLimit(1)
        } else {
            Text(title)
                .font(.caption2.weight(.bold))
                .tracking(tracking)
                .foregroundStyle(forImage ? Color.black.opacity(0.55) : Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
        }
    }

    /// One road, top-down: a chevron from the split, then each layer stacked (a column is too narrow to
    /// set two people side by side).
    private func branchColumn(_ branch: IsnadBranch) -> some View {
        VStack(spacing: 0) {
            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(accent.opacity(0.7))
                .padding(.bottom, 4)

            ForEach(Array(branch.layers.enumerated()), id: \.offset) { index, layer in
                VStack(spacing: 6) {
                    layerTitle(layer.title, tracking: 0.6)

                    ForEach(layer.nodes) { node in
                        nodeChip(node)
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

    private var connector: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(accent.opacity(0.45))
                .frame(width: 2, height: 14)
            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(accent.opacity(0.7))
            Rectangle()
                .fill(accent.opacity(0.45))
                .frame(width: 2, height: 14)
        }
        .padding(.vertical, 2)
    }

    private func layerBlock(_ layer: IsnadLayer) -> some View {
        VStack(spacing: 8) {
            layerTitle(layer.title, tracking: 0.8)

            if layer.nodes.count == 1, let node = layer.nodes.first {
                nodeChip(node)
                    .frame(maxWidth: 300)
            } else if #available(iOS 16.0, *) {
                // Centered rows (Abu, 2026-09-25: "some arent centered"): an adaptive grid filled its
                // columns from the leading edge, so a pair sat at the left of a wide row on iPad and Mac.
                IsnadCenteredRows(spacing: 8) {
                    ForEach(layer.nodes) { node in
                        nodeChip(node)
                            .frame(maxHeight: .infinity)
                    }
                }
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 132, maximum: 200), spacing: 8)], spacing: 8) {
                    ForEach(layer.nodes) { node in
                        nodeChip(node)
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
                chipBody(node, tappable: true)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Opens every narration naming this narrator"))
        } else {
            chipBody(node, tappable: false)
        }
    }

    private func chipBody(_ node: IsnadNode, tappable: Bool) -> some View {
        let filled = node.role == .prophet || node.role == .narrator || node.role == .source
        let outlined = node.role == .imam || node.role == .companion
        let primaryText: Color = forImage ? .black : .primary
        let secondaryText: Color = forImage ? Color.black.opacity(0.6) : .secondary

        return VStack(spacing: 3) {
            Text(node.arabic)
                .font(appearance.islamArabicFont(base: node.role == .prophet || node.role == .source ? 22 : 17, relativeTo: .body))
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

            // The one sign a chip opens something: a small person glyph under the name.
            if tappable {
                Image(systemName: "person.text.rectangle")
                    .font(.caption2)
                    .foregroundColor(filled ? Color.white.opacity(0.85) : accent.opacity(0.8))
                    .padding(.top, 1)
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

            IsnadDiagram(chain: chain, forImage: true)

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
            HStack {
                Label(label, systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.medium))
                Spacer()
                if preparing { ProgressView() }
            }
            .foregroundColor(appearance.accent)
            .contentShape(Rectangle())
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
    /// A chain's card: the title, the chain, the app's name at the foot, 560 points wide at 2x.
    init(label: String, title: String, subtitle: String, footer: String = "", chain: IsnadChain) {
        self.init(label: label, title: title, salt: subtitle, width: IsnadShareCard.width) {
            IsnadShareCard(title: title, subtitle: subtitle, footer: footer, chain: chain)
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
            IsnadDiagram(chain: isnad.chain)
            if #available(iOS 16.0, *) {
                IsnadShareButton(label: AppLanguage.article("Share the Chain as an Image"),
                                 title: isnad.title, subtitle: isnad.subtitle, chain: isnad.chain)
                    .padding(.top, 2)
            }
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
        }
    }

    private func rows(_ layer: IsnadLayer) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(layer.title).font(.caption2.weight(.bold)).foregroundColor(.secondary)
            ForEach(layer.nodes) { node in
                Text(node.name.isEmpty ? node.arabic : node.name).font(.footnote)
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
        subtitle: "Sahih al-Bukhari 1 · Sahih Muslim 1907",
        chain: IsnadChain(
            top: [
                layer("THE PROPHET ﷺ", prophet),
                layer("THE COMPANION", node("‘Umar ibn al-Khattab", "عُمَرُ بنُ الخَطَّابِ", "d. 23 AH, from the minbar", .companion)),
                layer("THE SUCCESSOR", node("‘Alqamah ibn Waqqas al-Laythi", "عَلقَمَةُ بنُ وَقَّاصٍ اللَّيثِيُّ", "of Madinah, d. 65–86 AH", .successor)),
                layer("HIS STUDENT", node("Muhammad ibn Ibrahim at-Taymi", "مُحَمَّدُ بنُ إِبرَاهِيمَ التَّيمِيُّ", "of Madinah, d. 120 AH", .successor)),
                layer("WHERE THE CHAIN DIVIDES", node("Yahya ibn Sa‘id al-Ansari", "يَحيَى بنُ سَعِيدٍ الأَنصَارِيُّ", "of Madinah, d. 144 AH or after", .imam)),
            ],
            branches: [
                IsnadBranch(id: "bukhari", highlighted: true, layers: [
                    layer("HIS STUDENT", node("Sufyan ibn ‘Uyaynah", "سُفيَانُ بنُ عُيَينَةَ", "of Makkah, d. 198 AH", .link)),
                    layer("HIS STUDENT", node("al-Humaydi", "عَبدُ اللَّهِ بنُ الزُّبَيرِ الحُمَيدِيُّ", "of Makkah, d. 219 AH", .link)),
                    layer("THE COLLECTOR", node("al-Bukhari", "مُحَمَّدُ بنُ إِسمَاعِيلَ البُخَارِيُّ", "d. 256 AH", .narrator)),
                ]),
                IsnadBranch(id: "muslim", highlighted: true, layers: [
                    layer("HIS STUDENT", node("Malik ibn Anas", "مَالِكُ بنُ أَنَسٍ", "of Madinah, d. 179 AH", .link)),
                    layer("HIS STUDENT", node("al-Qa‘nabi", "عَبدُ اللَّهِ بنُ مَسلَمَةَ القَعنَبِيُّ", "of Basra, d. 221 AH", .link)),
                    layer("THE COLLECTOR", node("Muslim", "مُسلِمُ بنُ الحَجَّاجِ", "d. 261 AH", .narrator)),
                ]),
            ]))

    /// The Sahifah of Hammam ibn Munabbih, which both Sahihs take from ‘Abd ar-Razzaq: Sahih al-Bukhari
    /// 2073 through Yahya ibn Musa, Sahih Muslim 225 through Muhammad ibn Rafi‘ (read from both rows).
    static let hammamSahifah = ArticleIsnad(
        title: "The Sahifah of Hammam",
        subtitle: "Sahih al-Bukhari 2073 · Sahih Muslim 225",
        chain: IsnadChain(
            top: [
                layer("THE PROPHET ﷺ", prophet),
                layer("THE COMPANION", node("Abu Hurayrah", "أَبُو هُرَيرَةَ", "d. 57–59 AH", .companion)),
                layer("WHO WROTE IT DOWN", node("Hammam ibn Munabbih", "هَمَّامُ بنُ مُنَبِّهٍ", "of San‘a, d. 132 AH", .successor)),
                layer("HIS STUDENT", node("Ma‘mar ibn Rashid", "مَعمَرُ بنُ رَاشِدٍ", "of Basra, settled in Yemen, d. 154 AH", .link)),
                layer("WHERE THE CHAIN DIVIDES", node("‘Abd ar-Razzaq as-San‘ani", "عَبدُ الرَّزَّاقِ الصَّنعَانِيُّ", "author of the Musannaf, d. 211 AH", .imam)),
            ],
            branches: [
                IsnadBranch(id: "bukhari", highlighted: true, layers: [
                    layer("HIS STUDENT", node("Yahya ibn Musa", "يَحيَى بنُ مُوسَى", "of Balkh, d. 240 AH", .link)),
                    layer("THE COLLECTOR", node("al-Bukhari", "مُحَمَّدُ بنُ إِسمَاعِيلَ البُخَارِيُّ", "d. 256 AH", .narrator)),
                ]),
                IsnadBranch(id: "muslim", highlighted: true, layers: [
                    layer("HIS STUDENT", node("Muhammad ibn Rafi‘", "مُحَمَّدُ بنُ رَافِعٍ", "of Nishapur, d. 245 AH", .link)),
                    layer("THE COLLECTOR", node("Muslim", "مُسلِمُ بنُ الحَجَّاجِ", "d. 261 AH", .narrator)),
                ]),
            ]))

    /// Malik from Nafi‘ from Ibn ‘Umar, which al-Bukhari called the soundest of chains, carried on to
    /// ash-Shafi‘i, Malik's student, and Ahmad, ash-Shafi‘i's: the chain the scholars called golden.
    static let goldenChain = ArticleIsnad(
        title: "The Golden Chain",
        subtitle: "Malik from Nafi‘ from Ibn ‘Umar",
        chain: IsnadChain(
            top: [
                layer("THE PROPHET ﷺ", prophet),
                layer("THE COMPANION", node("‘Abdullah ibn ‘Umar", "عَبدُ اللَّهِ بنُ عُمَرَ", "d. 73 AH", .companion)),
                layer("HIS FREED SLAVE", node("Nafi‘", "نَافِعٌ مَولَى ابنِ عُمَرَ", "of Madinah, d. 117 AH", .successor)),
                layer("THE IMAM OF MADINAH", node("Malik ibn Anas", "مَالِكُ بنُ أَنَسٍ", "d. 179 AH", .narrator)),
                layer("HIS STUDENT", node("ash-Shafi‘i", "مُحَمَّدُ بنُ إِدرِيسَ الشَّافِعِيُّ", "d. 204 AH", .link)),
                layer("HIS STUDENT", node("Ahmad ibn Hanbal", "أَحمَدُ بنُ حَنبَلٍ", "d. 241 AH", .link)),
            ],
            branches: []))

    /// How the Quran came to the cities: Allah's speech, through Jibril, to the Prophet ﷺ; taught to
    /// the Companions; gathered under Abu Bakr; kept by Hafsah; copied under ‘Uthman; sent out to the
    /// cities whose readers became the ten imams. Sahih al-Bukhari 4986 and 4987, and 4999 for the four
    /// the Prophet named.
    static let quranCompilation = ArticleIsnad(
        title: "How the Quran Reached Us",
        subtitle: "From the Prophet ﷺ to the copies of ‘Uthman",
        chain: IsnadChain(
            top: [
                layer("THE SPEECH OF", node("Allah, Exalted is He", "اللَّهُ عَزَّ وَجَلَّ", "His speech, not created", .source)),
                layer("BROUGHT DOWN BY", node("Jibril", "جِبرِيلُ عَلَيهِ السَّلَامُ", "the trustworthy Spirit (26:193)", .companion)),
                layer("TO", prophet),
                layer("WHO TAUGHT IT TO THE COMPANIONS",
                      node("‘Abdullah ibn Mas‘ud", "عَبدُ اللَّهِ بنُ مَسعُودٍ", "d. 32 AH", .companion),
                      node("Salim, mawla of Abu Hudhayfah", "سَالِمٌ مَولَى أَبِي حُذَيفَةَ", "fell at al-Yamamah, 12 AH", .companion),
                      node("Mu‘adh ibn Jabal", "مُعَاذُ بنُ جَبَلٍ", "d. 18 AH", .companion),
                      node("Ubayy ibn Ka‘b", "أُبَيُّ بنُ كَعبٍ", "d. 30 AH", .companion),
                      node("Zayd ibn Thabit", "زَيدُ بنُ ثَابِتٍ", "his scribe, d. 45 AH", .companion),
                      node("‘Ali ibn Abi Talib", "عَلِيُّ بنُ أَبِي طَالِبٍ", "d. 40 AH", .companion)),
                layer("GATHERED INTO ONE VOLUME, 12 AH",
                      node("Abu Bakr as-Siddiq", "أَبُو بَكرٍ الصِّدِّيقُ", "ordered it at ‘Umar's counsel, d. 13 AH", .imam),
                      node("Zayd ibn Thabit", "زَيدُ بنُ ثَابِتٍ", "gathered it from the written pieces and the memories of men", .link)),
                layer("KEPT BY", node("Hafsah bint ‘Umar", "حَفصَةُ بِنتُ عُمَرَ", "the sheets passed from Abu Bakr to ‘Umar, then to her", .link)),
                layer("COPIED UNDER ‘UTHMAN, c. 25 AH",
                      node("‘Uthman ibn ‘Affan", "عُثمَانُ بنُ عَفَّانَ", "ordered the copies, d. 35 AH", .imam),
                      node("Zayd ibn Thabit", "زَيدُ بنُ ثَابِتٍ", "d. 45 AH", .link),
                      node("‘Abdullah ibn az-Zubayr", "عَبدُ اللَّهِ بنُ الزُّبَيرِ", "d. 73 AH", .link),
                      node("Sa‘id ibn al-‘As", "سَعِيدُ بنُ العَاصِ", "d. c. 59 AH", .link),
                      node("‘Abd ar-Rahman ibn al-Harith", "عَبدُ الرَّحمَنِ بنُ الحَارِثِ بنِ هِشَامٍ", "d. 43 AH", .link)),
                layer("SENT TO THE CITIES, AND READ THERE BY",
                      node("Madinah", "المَدِينَةُ", "Nafi‘ and Abu Ja‘far", .student),
                      node("Makkah", "مَكَّةُ", "Ibn Kathir", .student),
                      node("Sham", "الشَّامُ", "Ibn ‘Amir", .student),
                      node("Basra", "البَصرَةُ", "Abu ‘Amr and Ya‘qub", .student),
                      node("Kufa", "الكُوفَةُ", "‘Asim, Hamzah, al-Kisa’i and Khalaf", .student)),
            ],
            branches: []))

    /// Where the four imams learned: the Kufan road from Ibn Mas‘ud to Abu Hanifah, and the Madinan road
    /// from Ibn ‘Umar to Malik, ash-Shafi‘i and Ahmad.
    static let madhhabImams = ArticleIsnad(
        title: "Where the Four Imams Learned",
        subtitle: "From the Companions to the four madhahib",
        chain: IsnadChain(
            top: [
                layer("THE PROPHET ﷺ", prophet),
            ],
            branches: [
                IsnadBranch(id: "kufa", highlighted: true, layers: [
                    layer("THE COMPANION", node("‘Abdullah ibn Mas‘ud", "عَبدُ اللَّهِ بنُ مَسعُودٍ", "d. 32 AH, taught in Kufa", .companion)),
                    layer("HIS STUDENT", node("‘Alqamah ibn Qays", "عَلقَمَةُ بنُ قَيسٍ النَّخَعِيُّ", "d. after 60 AH", .successor)),
                    layer("HIS STUDENT", node("Ibrahim an-Nakha‘i", "إِبرَاهِيمُ النَّخَعِيُّ", "d. 96 AH", .successor)),
                    layer("HIS STUDENT", node("Hammad ibn Abi Sulayman", "حَمَّادُ بنُ أَبِي سُلَيمَانَ", "d. 120 AH", .link)),
                    layer("THE IMAM", node("Abu Hanifa", "أَبُو حَنِيفَةَ النُّعمَانُ", "d. 150 AH", .narrator)),
                    layer("HIS STUDENTS",
                          node("Abu Yusuf", "أَبُو يُوسُفَ", "d. 182 AH", .student),
                          node("Muhammad ash-Shaybani", "مُحَمَّدُ بنُ الحَسَنِ الشَّيبَانِيُّ", "d. 189 AH", .student)),
                ]),
                IsnadBranch(id: "madinah", highlighted: true, layers: [
                    layer("THE COMPANION", node("‘Abdullah ibn ‘Umar", "عَبدُ اللَّهِ بنُ عُمَرَ", "d. 73 AH, of Madinah", .companion)),
                    layer("HIS STUDENT", node("Nafi‘", "نَافِعٌ مَولَى ابنِ عُمَرَ", "d. 117 AH", .successor)),
                    layer("THE IMAM", node("Malik ibn Anas", "مَالِكُ بنُ أَنَسٍ", "d. 179 AH", .narrator)),
                    layer("HIS STUDENT", node("ash-Shafi‘i", "مُحَمَّدُ بنُ إِدرِيسَ الشَّافِعِيُّ", "d. 204 AH", .narrator)),
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
        return ArticleIsnad(title: "Hafs an ‘Asim", subtitle: "The chain of the reading most Muslims recite", chain: chain)
    }
}
