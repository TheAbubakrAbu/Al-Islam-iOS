#if os(iOS)
import SwiftUI

/// One stop on a `JumpIndexRail`: the short label the rail prints ("12"), and the title (with an
/// optional second line) the bubble beside the finger shows while scrubbing ("Juz 12", its name).
struct JumpIndexItem: Identifiable, Equatable {
    let id: Int
    let label: String
    let title: String
    var subtitle: String? = nil

    /// The stops for a numbered list (ayahs, hadiths, names, situations, chapters): its first number,
    /// every round step after it, and its last, the step the smallest of 5, 10, 20, 25, 50, 100 ...
    /// that keeps the rail to `maximumStops`, so the labels read as a ruler does (1, 10, 20 ... 280,
    /// 286), not as evenly spaced rows would (1, 11, 21 ...). `numbers` are the rows' numbers in list
    /// order, ascending; each stop's `id` is its row's index in them, for the caller to map back.
    static func numberedStops(_ numbers: [Int], maximumStops: Int = 30,
                              title: (Int) -> String, subtitle: (Int) -> String? = { _ in nil }) -> [JumpIndexItem] {
        guard let first = numbers.first, let last = numbers.last, last > first else { return [] }
        let span = last - first
        let step = [5, 10, 20, 25, 50, 100, 200, 250, 500, 1000, 2000, 2500, 5000]
            .first { span / $0 + 2 <= maximumStops } ?? 10000
        var indices = [0]
        var next = (first / step + 1) * step
        for (index, number) in numbers.enumerated() where number >= next {
            indices.append(index)
            next = (number / step + 1) * step
        }
        // The last row too, unless a round stop sits within half a step of it.
        if let stop = indices.last, stop != numbers.count - 1, last - numbers[stop] >= step / 2 {
            indices.append(numbers.count - 1)
        }
        return indices.map { index in
            JumpIndexItem(id: index, label: "\(numbers[index])".localizedDigits,
                          title: title(index), subtitle: subtitle(index))
        }
    }
}

/// The right-edge index of a long list, after UIKit's section index (Contacts' A to Z): tap a label
/// or drag along the rail to jump, with a bubble naming the stop under the finger.
///
/// Built by hand rather than with iOS 26's `sectionIndexLabel` (which the Quran tab's juz sort used
/// until 2026-10-27): that index exists on iOS 26 and later only, and it can point at `Section`s
/// only, while the Quran grid is one Section of chunk rows. This one hands its caller the stop and
/// lets it scroll to whatever row id it likes, on every iOS the app supports.
///
/// Lay it over the List with `.overlay(alignment: .trailing)`, the List itself first given
/// `jumpIndexRailRoom(items)` so its rows clear the labels: it takes the whole height to measure
/// itself but only its own column takes touches, so the list underneath scrolls as before. When the
/// height cannot fit every label (a phone in landscape), it prints every other one with a dot
/// between, as UIKit does; the finger still reaches every stop. While it shows, the list's own scroll
/// indicator is off, as under UIKit's index: it runs down the same strip of the edge.
struct JumpIndexRail: View {
    let items: [JumpIndexItem]
    let accent: Color
    /// The rail's VoiceOver name ("Juz index").
    let accessibilityName: String
    /// A new stop under the finger, or a VoiceOver swipe: jump there.
    let onSelect: (JumpIndexItem) -> Void
    /// The finger lifted on this stop (also sent after a VoiceOver swipe): the moment for a slower,
    /// corrective pass once the list has settled.
    var onSettle: (JumpIndexItem) -> Void = { _ in }

    /// The stop under the finger while it is down.
    @State private var activeIndex: Int?
    /// The finger's height on the rail, for the bubble.
    @State private var activeY: CGFloat = 0
    /// The last stop jumped to, so VoiceOver steps on from it.
    @State private var lastIndex: Int?

    private static let rowHeight: CGFloat = 15
    private static let minimumRowHeight: CGFloat = 11
    /// The touch target's least width: wider than the labels, reaching in toward the list.
    private static let minimumTouchWidth: CGFloat = 30
    private static let verticalMargin: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let height = max(0, proxy.size.height - Self.verticalMargin * 2)
            let slots = Self.slots(count: items.count, height: height)
            let row = slots.isEmpty ? Self.rowHeight : min(Self.rowHeight, height / CGFloat(slots.count))
            column(slots: slots, row: row, laneWidth: Self.laneWidth(for: items))
                // The face the lane is measured in, whatever design the list's subtree carries (a
                // reader's Arabic opts its rows out of the rounded design).
                .appFontDesign()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .background {
                    ScrollIndicatorHider(listMinimumHeight: proxy.size.height / 2)
                        .frame(width: 1, height: 1)
                }
        }
    }

    // MARK: - Lane

    /// The labels' column. It was a fixed 18 pt and the labels shrank to fit it, so "100" to "286"
    /// ran out of the 16 pt gutter onto the cards and the Musnad's four-figure chapters printed "10…"
    /// (Abu, 2026-11-10: "Fix the right numbers theres overlap in the scrolling and whatnot"). Now it
    /// is as wide as the widest label at full size, and the rows make room for it (`listRoom`).
    /// No condensed face for the long numbers: the app draws in SF Rounded, which has none, and
    /// `.width(.condensed)` under it is silently dropped (measured).
    private static let labelFont: Font = .system(size: 11, weight: .bold).monospacedDigit()

    /// `labelFont` as UIKit measures it, in the app's rounded design (`appFontDesign`).
    private static let measuringFont: UIFont = {
        let font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .bold)
        return font.fontDescriptor.withDesign(.rounded).map { UIFont(descriptor: $0, size: 11) } ?? font
    }()

    /// Space each side of a label inside the column.
    private static let labelInset: CGFloat = 1
    /// The list's own trailing margin beside its cards on a phone, which the column sits in.
    private static let listGutter: CGFloat = 16
    /// What the column keeps clear of the cards.
    private static let cardGap: CGFloat = 2
    /// The column before iOS 17, where the rows cannot make room (`jumpIndexRailRoom`): the width it
    /// always had, the longer labels shrinking into it as they did.
    private static let fixedLaneWidth: CGFloat = 18

    static func laneWidth(for items: [JumpIndexItem]) -> CGFloat {
        let widest = items.map { ($0.label as NSString).size(withAttributes: [.font: measuringFont]).width }.max() ?? 0
        let fitted = ceil(widest) + labelInset * 2
        if #available(iOS 17.0, *) { return fitted }
        return min(fitted, fixedLaneWidth)
    }

    /// How far the list's rows move in so the column clears them: 4 pt for two figures (the juz
    /// rail), 12 for three (an ayah rail on a long surah), 19 for four (the Musnad's chapters).
    /// Nothing without stops.
    static func listRoom(for items: [JumpIndexItem]) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        return max(0, laneWidth(for: items) + cardGap - listGutter)
    }

    // MARK: - Layout

    /// What each printed slot shows: a stop's label, or a dot standing for the stops between two
    /// labels when the height is short.
    private enum Slot {
        case label(Int)
        case dot
    }

    /// The slots that fit `height`: every stop when they all fit at the minimum row height, else an
    /// odd number of slots alternating label and dot, the first and the last stop always printed.
    private static func slots(count: Int, height: CGFloat) -> [Slot] {
        guard count > 0 else { return [] }
        let fitting = Int(max(0, height) / minimumRowHeight)
        if count <= fitting { return (0..<count).map { .label($0) } }
        var slotCount = max(3, fitting)
        if slotCount % 2 == 0 { slotCount -= 1 }
        return (0..<slotCount).map { slot in
            slot % 2 == 0 ? .label(itemIndex(atSlot: CGFloat(slot), slots: slotCount, count: count)) : .dot
        }
    }

    /// The stop at a (fractional) slot position: slot centres land on the stops they print, so a
    /// finger on a label picks that label even when dots stand between.
    private static func itemIndex(atSlot slot: CGFloat, slots: Int, count: Int) -> Int {
        guard slots > 1, count > 1 else { return 0 }
        let fraction = min(max(slot / CGFloat(slots - 1), 0), 1)
        return Int((fraction * CGFloat(count - 1)).rounded())
    }

    private func column(slots: [Slot], row: CGFloat, laneWidth: CGFloat) -> some View {
        let railHeight = row * CGFloat(slots.count)
        let touchWidth = max(Self.minimumTouchWidth, laneWidth + 12)
        return VStack(spacing: 0) {
            ForEach(Array(slots.enumerated()), id: \.offset) { _, slot in
                switch slot {
                case .label(let index):
                    Text(verbatim: items[index].label)
                        .font(Self.labelFont)
                        .lineLimit(1)
                        // Full size wherever the column is fitted to the labels; only the fixed
                        // column before iOS 17 shrinks them.
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(accent)
                        .frame(width: laneWidth, height: row)
                case .dot:
                    Circle()
                        .fill(accent.opacity(0.6))
                        .frame(width: 3.5, height: 3.5)
                        .frame(width: laneWidth, height: row)
                }
            }
        }
        .padding(.vertical, 6)
        .background {
            Capsule()
                .fill(accent.opacity(activeIndex == nil ? 0 : 0.14))
        }
        .frame(width: touchWidth, alignment: .trailing)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    // The column is padded 6 pt top and bottom; slot 0's centre is half a row in.
                    let y = value.location.y - 6
                    activeY = min(max(value.location.y, 6), railHeight + 6)
                    let slot = y / max(row, 1) - 0.5
                    let index = Self.itemIndex(atSlot: slot, slots: slots.count, count: items.count)
                    guard items.indices.contains(index), index != activeIndex else { return }
                    activeIndex = index
                    lastIndex = index
                    onSelect(items[index])
                }
                .onEnded { _ in
                    if let index = activeIndex, items.indices.contains(index) {
                        onSettle(items[index])
                    }
                    activeIndex = nil
                }
        )
        .overlay(alignment: .trailing) {
            if let index = activeIndex, items.indices.contains(index) {
                bubble(items[index])
                    .fixedSize()
                    // Beside the rail (padding, so it flips with the layout direction), centred on
                    // the finger: the overlay centres it on the column, 6 pt padding included.
                    .padding(.trailing, touchWidth + 6)
                    .offset(y: activeY - (railHeight + 12) / 2)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.12), value: activeIndex == nil)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityName)
        .accessibilityValue(lastIndex.flatMap { items.indices.contains($0) ? items[$0].title : nil } ?? "")
        .accessibilityHint(Text("Swipe up or down to jump."))
        .accessibilityAdjustableAction { direction in
            guard !items.isEmpty else { return }
            // `lastIndex` outlives a change of `items`: the list reader swaps its surah in place, so a
            // stop from al-Baqarah's 30 can meet Al Imran's 21, and stepping down from it indexed past
            // the end. A stop the list no longer has counts as none.
            let current = lastIndex.flatMap { items.indices.contains($0) ? $0 : nil } ?? -1
            let next: Int
            switch direction {
            case .increment: next = min(items.count - 1, current + 1)
            case .decrement: next = max(0, current - 1)
            @unknown default: return
            }
            lastIndex = next
            onSelect(items[next])
            onSettle(items[next])
        }
    }

    private func bubble(_ item: JumpIndexItem) -> some View {
        VStack(spacing: 1) {
            Text(verbatim: item.title)
                .font(.headline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(accent)
            if let subtitle = item.subtitle {
                Text(verbatim: subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        // A situation's or a chapter's name can be a sentence: it truncates rather than running the
        // bubble off the far edge.
        .frame(maxWidth: 240)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
    }
}

/// Turns off the vertical scroll indicator of the list a rail lies over, and back on when the rail
/// goes. Mid-scroll the indicator was drawn straight through the labels (measured 396 to 399 pt on
/// the 17 Pro, the labels 387 to 400). UIKit, not `.scrollIndicators(.hidden)`: that one is an
/// environment value, so it would reach every scroll view under the list as well, the sheets its
/// rows present among them. A 1 pt probe at the middle of the rail's area looks for the list among
/// the views beside it: the scroll view under that point at least half the rail's height (a row's
/// horizontal strip never is).
private struct ScrollIndicatorHider: UIViewRepresentable {
    let listMinimumHeight: CGFloat

    func makeUIView(context: Context) -> ProbeView {
        let view = ProbeView()
        view.isUserInteractionEnabled = false
        view.listMinimumHeight = listMinimumHeight
        return view
    }

    func updateUIView(_ uiView: ProbeView, context: Context) {
        uiView.listMinimumHeight = listMinimumHeight
        uiView.attach()
    }

    static func dismantleUIView(_ uiView: ProbeView, coordinator: ()) {
        uiView.release()
    }

    final class ProbeView: UIView {
        var listMinimumHeight: CGFloat = 0
        private weak var list: UIScrollView?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return release() }
            attach()
            // The list can join the window a pass after the overlay does.
            DispatchQueue.main.async { [weak self] in self?.attach() }
        }

        func attach() {
            guard let window else { return }
            if list == nil { list = findList(in: window) }
            if list?.showsVerticalScrollIndicator == true { list?.showsVerticalScrollIndicator = false }
        }

        func release() {
            list?.showsVerticalScrollIndicator = true
            list = nil
        }

        /// The nearest ancestors first, so the rail's own list wins over any further away.
        private func findList(in window: UIWindow) -> UIScrollView? {
            let point = convert(CGPoint(x: bounds.midX, y: bounds.midY), to: window)
            var branch: UIView = self
            var ancestor = superview
            var levels = 0
            while let container = ancestor, container !== window, levels < 8 {
                for view in container.subviews.reversed() where view !== branch {
                    if let found = scrollView(in: view, under: point, window: window) { return found }
                }
                branch = container
                ancestor = container.superview
                levels += 1
            }
            return nil
        }

        private func scrollView(in view: UIView, under point: CGPoint, window: UIWindow) -> UIScrollView? {
            guard !view.isHidden, view.alpha > 0 else { return nil }
            if let scroll = view as? UIScrollView, !(scroll is UITextView) {
                let frame = scroll.convert(scroll.bounds, to: window)
                return frame.contains(point) && frame.height >= listMinimumHeight ? scroll : nil
            }
            for sub in view.subviews.reversed() {
                if let found = scrollView(in: sub, under: point, window: window) { return found }
            }
            return nil
        }
    }
}

extension View {
    /// Moves a List's rows in from the trailing edge by what a rail with these stops needs beyond the
    /// list's own margin (`JumpIndexRail.listRoom`), so no label sits on a card. Safe-area padding,
    /// as the reading column's margins are (`ReadingColumnMargins`): the rows already honour it.
    /// iOS 17+; before it the rail keeps its fixed column.
    ///
    /// Apply it to the List ITSELF, before `applyConditionalListStyle`: the style's Now Playing bar
    /// is a bottom inset on the styled list, and padding laid around that squeezed the bar in from
    /// the same edge (measured 2026-11-10 on the Musnad's chapters, 19 pt). No stops is no room, so
    /// it stays on the List while a search hides the rail.
    @ViewBuilder
    func jumpIndexRailRoom(_ items: [JumpIndexItem]) -> some View {
        if #available(iOS 17.0, *) {
            safeAreaPadding(.trailing, JumpIndexRail.listRoom(for: items))
        } else {
            self
        }
    }

    /// A `JumpIndexRail` down the trailing edge of a List that jumps by row id (the reader's ayahs, a
    /// chapter's hadiths, the 99 Names, Hisn al-Muslim's situations, a book's chapters; Abu,
    /// 2026-10-27, on the rail going to other screens: "could be fire"). A stop scrolls its row to the
    /// top at once, unanimated so a drag along the rail keeps up; when the finger lifts, the same row
    /// once more, after the rows a far jump passed over have measured themselves (a lazy List lands
    /// the first time on estimated heights). No `items` draws nothing. The List takes the same
    /// `items` in `jumpIndexRailRoom`, so its rows clear the labels.
    func jumpIndexRail<ID: Hashable>(_ items: [JumpIndexItem], accessibilityName: String,
                                     proxy: ScrollViewProxy, rowID: @escaping (JumpIndexItem) -> ID?) -> some View {
        overlay(alignment: .trailing) {
            if !items.isEmpty {
                JumpIndexRail(
                    items: items,
                    accent: Settings.shared.accentColor.color,
                    accessibilityName: accessibilityName,
                    onSelect: { item in
                        Settings.shared.hapticFeedback()
                        if let id = rowID(item) { proxy.scrollTo(id, anchor: .top) }
                    },
                    onSettle: { item in
                        guard let id = rowID(item) else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { proxy.scrollTo(id, anchor: .top) }
                    }
                )
            }
        }
    }
}
#endif
