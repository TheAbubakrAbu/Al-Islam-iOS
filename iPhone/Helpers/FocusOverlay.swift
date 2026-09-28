// Imported unconditionally: the `focusableImage` modifier at the bottom of this file lives OUTSIDE the iOS-only
// block (the screens that use it build for the watch too), so SwiftUI has to be in scope on every platform.
import SwiftUI

#if os(iOS)

// MARK: - Fullscreen focus overlay

/// One thing shown as large as the screen allows: an Arabic letter, a surah name, or one of the 99 Names.
/// `arabic` is the hero - everything else is supporting text under it.
struct FocusItem: Identifiable, Equatable {
    let id: String
    let arabic: String
    let title: String
    let subtitle: String?
    let footnote: String?
    /// Extra Arabic shown small beneath the hero (a letter's three forms, a surah's number, …).
    let secondaryArabic: String?
    let shareLabel: String
    let shareText: String
    /// Letters from non-Arabic scripts (پ, چ, ژ …) aren't in the Quranic font, so they must fall back.
    let allowsQuranicFont: Bool
    /// An asset name. When set, the hero is that image - pinch/double-tap to zoom - instead of Arabic text,
    /// and the caption sits under it. This is what makes every diagram in the app openable full screen.
    let imageName: String?
    /// One of the 99 Names, when the overlay was opened from a grid tile: the overlay then shows what
    /// the LIST row shows when it expands - Other Names, the description, and the two doors under it
    /// (Abu, 2026-09-23: "when I click on a name I want it to do the same thing that list mode does").
    /// Nil for every other kind of focus item, which has no such second half.
    let nameDetail: NameOfAllah?

    init(
        id: String,
        arabic: String,
        title: String,
        subtitle: String? = nil,
        footnote: String? = nil,
        secondaryArabic: String? = nil,
        shareLabel: String,
        shareText: String,
        allowsQuranicFont: Bool = true,
        imageName: String? = nil,
        nameDetail: NameOfAllah? = nil
    ) {
        self.id = id
        self.arabic = arabic
        self.title = title
        self.subtitle = subtitle
        self.footnote = footnote
        self.secondaryArabic = secondaryArabic
        self.shareLabel = shareLabel
        self.shareText = shareText
        self.allowsQuranicFont = allowsQuranicFont
        self.imageName = imageName
        self.nameDetail = nameDetail
    }
}

/// Drives the app-wide focus overlay. A singleton rather than an `EnvironmentObject` because the rows that
/// present it (letter rows, name rows, surah context menus) live deep inside lists across three tabs, and
/// threading a binding down to each of them would touch far more code than it's worth.
@MainActor
final class FocusOverlayPresenter: ObservableObject {
    static let shared = FocusOverlayPresenter()
    private init() {}

    @Published var item: FocusItem?

    func present(_ item: FocusItem) {
        withAnimation(.easeInOut(duration: 0.22)) {
            self.item = item
        }
    }

    func dismiss() {
        withAnimation(.easeInOut(duration: 0.2)) {
            item = nil
        }
    }
}

/// What a 99 Names grid tile's tap shows under the hero: everything the LIST row reveals when it
/// expands (Abu, 2026-09-23: "when I click on a name I want it to do the same thing that list mode
/// does ... but can't open it at the end").
///
/// The "can't open it at the end" is the constraint that shapes this. The overlay is a plain
/// `ZStack` layer at the app root, NOT inside a `NavigationStack`, so a `NavigationLink` here fires
/// into nothing. So the two doors the expanded row offers are re-routed rather than dropped:
/// - "More about this name" presents `NameDetailView` as a SHEET, which is what the row's own
///   `NameDetailLink` already does - so that one is unchanged in behavior.
/// - "View First Found" hands the ayah to `AppNavigation.pendingQuran` and closes the overlay, the
///   cross-tab route a Sunnah reminder's notification already uses. The Quran tab opens it.
struct FocusNameDetails: View {
    @ObservedObject private var settings = Settings.shared

    let name: NameOfAllah

    @State private var showsDetail = false

    var body: some View {
        // Centered under the centered hero and caption (Abu, 2026-09-25: "make other names and the
        // description look prettier and centered"): the old block was the LIST row's layout,
        // leading-aligned, which read as a different page pasted under the name.
        VStack(spacing: 14) {
            if !name.otherNames.isEmpty {
                VStack(spacing: 8) {
                    Text("ALSO CALLED")
                        .font(.caption2.weight(.bold))
                        .tracking(0.8)
                        .foregroundColor(settings.accentColor.color)

                    otherNames
                }
            }

            Text.islamText(name.desc, highlightAllah: settings.highlightAllahNamesIslam)
                .font(.callout)
                .foregroundColor(.primary.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(settings.accentColor.color.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(settings.accentColor.color.opacity(0.18), lineWidth: 1)
                )

            doors
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showsDetail) {
            SheetNavigationContainer {
                NameDetailView(name: name, isSheet: true)
            }
        }
    }

    /// The other names as chips, wrapped and centered row by row.
    @ViewBuilder
    private var otherNames: some View {
        if #available(iOS 16.0, *) {
            CenteredChipFlow(spacing: 6) {
                ForEach(name.otherNames, id: \.self) { other in
                    Text(other)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(settings.accentColor.color.opacity(0.12)))
                }
            }
        } else {
            Text(name.otherNames.joined(separator: " \u{00B7} "))
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// "More about this name" and "View First Found", side by side and the same width.
    @ViewBuilder
    private var doors: some View {
        let hasDetail = NamesDetailsStore.isBundled
        #if HAS_QURAN
        let firstFound: (surah: Int, ayah: Int)? = name.firstFoundSurah.flatMap { surah in
            name.firstFoundAyah.map { (surah, $0) }
        }
        #else
        let firstFound: (surah: Int, ayah: Int)? = nil
        #endif
        if hasDetail || firstFound != nil {
            HStack(spacing: 10) {
                if hasDetail {
                    Button {
                        settings.hapticFeedback()
                        showsDetail = true
                    } label: {
                        detailLabel("More about this name", systemImage: "text.book.closed")
                    }
                    .buttonStyle(.plain)
                }

                #if HAS_QURAN
                if let firstFound {
                    Button {
                        settings.hapticFeedback()
                        // Close the overlay FIRST: the tab switch happens under it, and a layer left up
                        // over the arriving surah would read as the app ignoring the tap.
                        FocusOverlayPresenter.shared.dismiss()
                        AppNavigation.shared.pendingQuran = .ayah(firstFound.surah, firstFound.ayah)
                    } label: {
                        detailLabel("View First Found", systemImage: "book")
                    }
                    .buttonStyle(.plain)
                }
                #endif
            }
        }
    }

    private func detailLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundColor(settings.accentColor.color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .contentShape(Capsule())
        .conditionalGlassEffect(useColor: 0.2)
    }
}

/// Chips of any width, wrapped onto as many rows as they need, each row centered: the name overlay's
/// "Also called" line, where the chips sit under a centered hero.
@available(iOS 16.0, *)
struct CenteredChipFlow: Layout {
    var spacing: CGFloat = 6

    private func rows(_ subviews: Subviews, width: CGFloat) -> [[(index: Int, size: CGSize)]] {
        var rows: [[(index: Int, size: CGSize)]] = [[]]
        var x: CGFloat = 0
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !rows[rows.count - 1].isEmpty, x + size.width > width {
                rows.append([])
                x = 0
            }
            rows[rows.count - 1].append((index, size))
            x += size.width + spacing
        }
        return rows
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = rows(subviews, width: width)
        let height = rows.map { $0.map(\.size.height).max() ?? 0 }.reduce(0, +)
            + spacing * CGFloat(max(0, rows.count - 1))
        let widest = rows.map { row in
            row.map(\.size.width).reduce(0, +) + spacing * CGFloat(max(0, row.count - 1))
        }.max() ?? 0
        return CGSize(width: width == .infinity ? widest : width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(subviews, width: bounds.width) {
            let rowWidth = row.map(\.size.width).reduce(0, +) + spacing * CGFloat(max(0, row.count - 1))
            let rowHeight = row.map(\.size.height).max() ?? 0
            var x = bounds.midX - rowWidth / 2
            for item in row {
                subviews[item.index].place(at: CGPoint(x: x, y: y + (rowHeight - item.size.height) / 2),
                                           proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += rowHeight + spacing
        }
    }
}

/// Sits at the top of the app's root `ZStack` - not a sheet, so it can cover the tab bar and animate as a
/// plain cross-fade instead of the system's slide-up.
struct FocusOverlayHost: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var presenter = FocusOverlayPresenter.shared

    @State private var showingActivityView = false

    private var useQuranicFont: Bool {
        settings.useFontArabic && (presenter.item?.allowsQuranicFont ?? false)
    }

    /// Whether the hero glyph resolves to a bundled face, and so must opt out of the app-wide rounded design.
    private var usesCustomArabicFace: Bool {
        useQuranicFont && settings.quranUsesCustomArabicFace
    }

    var body: some View {
        if let item = presenter.item {
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .onTapGesture { presenter.dismiss() }

                VStack(spacing: 0) {
                    closeRow

                    Spacer(minLength: 0)

                    hero(item)

                    Spacer(minLength: 0)

                    caption(item)

                    // A Name's second half, when it has one. In its own scroller so a long
                    // description can never push the Copy/Share buttons off the screen.
                    if let name = item.nameDetail {
                        ScrollView {
                            FocusNameDetails(name: name)
                        }
                        .frame(maxHeight: 260)
                        .padding(.bottom, 16)
                    }

                    actions(item)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .transition(.opacity)
            // The hero is already at the largest size the screen fits; letting Dynamic Type scale it again
            // just overflows and clips the glyph.
            .dynamicTypeSize(.large)
            .sheet(isPresented: $showingActivityView) {
                ActivityView(activityItems: shareItems(item))
            }
        }
    }

    private var closeRow: some View {
        HStack {
            Spacer()

            Button {
                settings.hapticFeedback()
                presenter.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(settings.accentColor.color)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .conditionalGlassEffect(circle: true)
            }
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func hero(_ item: FocusItem) -> some View {
        if let imageName = item.imageName {
            ZoomableImage(imageName: imageName)
        } else {
            textHero(item)
        }
    }

    @ViewBuilder
    private func textHero(_ item: FocusItem) -> some View {
        VStack(spacing: 20) {
            Text(item.arabic)
                .font(useQuranicFont ? Font.arabic(settings.fontArabic, size: 130) : .system(size: 110))
                .arabicFontDesign(custom: usesCustomArabicFace)
                .foregroundStyle(settings.accentColor.color)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.15)
                .lineLimit(3)
                .textSelection(.enabled)

            if let secondaryArabic = item.secondaryArabic {
                Text(secondaryArabic)
                    .font(useQuranicFont ? Font.arabic(settings.fontArabic, size: 34) : .system(size: 30))
                    .arabicFontDesign(custom: usesCustomArabicFace)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .conditionalGlassEffect(rectangle: true, useColor: 0.12)
    }

    @ViewBuilder
    private func caption(_ item: FocusItem) -> some View {
        VStack(spacing: 6) {
            Text(item.title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            if let subtitle = item.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let footnote = item.footnote {
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    private func actions(_ item: FocusItem) -> some View {
        HStack(spacing: 12) {
            Button {
                settings.hapticFeedback()
                // An image copies as an image; everything else copies its Arabic.
                if let imageName = item.imageName, let image = UIImage(named: imageName) {
                    UIPasteboard.general.image = image
                } else {
                    UIPasteboard.general.string = item.arabic
                }
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                    .conditionalGlassEffect()
            }

            Button {
                settings.hapticFeedback()
                showingActivityView = true
            } label: {
                Label(item.shareLabel, systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                    .conditionalGlassEffect(useColor: 0.25)
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(settings.accentColor.color)
    }

    /// What the share sheet sends: the image itself for an image item, the text otherwise.
    private func shareItems(_ item: FocusItem) -> [Any] {
        if let imageName = item.imageName, let image = UIImage(named: imageName) {
            return [image]
        }
        return [item.shareText]
    }
}

// MARK: - Zoomable image

/// The image hero: pinch to zoom, drag to pan, double-tap to toggle between fit and 2.5×. Scale is clamped so
/// the image can't be shrunk away or blown up past legibility, and it springs back to fit when zoomed out.
struct ZoomableImage: View {
    let imageName: String

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 5

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                // Panning only makes sense once you're zoomed in; at fit scale the drag would just slide the
                // image around inside empty space.
                DragGesture()
                    .onChanged { value in
                        guard scale > 1 else { return }
                        offset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in lastOffset = offset }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = min(max(lastScale * value, minScale), maxScale)
                    }
                    .onEnded { _ in
                        lastScale = scale
                        if scale <= 1 { resetZoom() }
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if scale > 1 {
                        resetZoom()
                    } else {
                        scale = 2.5
                        lastScale = 2.5
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .frame(maxWidth: .infinity)
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
}

// MARK: - Sharing

/// Wraps `UIActivityViewController` for use from a `.sheet`.
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    /// Called when the activity sheet finishes; `completed` is false when the user cancelled. Lets a caller
    /// (e.g. the Share Ayah sheet) dismiss itself only after a REAL share, not on cancel.
    var onComplete: ((_ completed: Bool) -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        vc.modalPresentationStyle = .formSheet
        if let onComplete {
            vc.completionWithItemsHandler = { _, completed, _, _ in
                onComplete(completed)
            }
        }
        return vc
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Shares from a context-menu button. A `.sheet` can't be used there - the menu's host row is gone by the
/// time the action runs - so present the activity controller on the topmost view controller instead.
@MainActor
func presentSystemShareSheet(items: [Any]) {
    guard let top = topmostViewController() else { return }

    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    // iPad requires an anchor or the popover asserts on presentation.
    controller.popoverPresentationController?.sourceView = top.view
    controller.popoverPresentationController?.sourceRect = CGRect(
        x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0
    )
    controller.popoverPresentationController?.permittedArrowDirections = []
    top.present(controller, animated: true)
}

// MARK: - Focus items for each kind of content
//
// Only the kinds this file can build on its own. Content types that live outside Helpers - a Quran `Surah`,
// say - declare their own `FocusItem` factory next to the model, so this file drops into an app that has no
// Quran (Al-Adhan) without dragging the Quran folder along.

extension FocusItem {
    static func letter(_ data: LetterData) -> FocusItem {
        FocusItem(
            id: "letter-\(data.id)",
            arabic: data.letter,
            title: data.transliteration,
            subtitle: data.name,
            footnote: data.weightRule,
            // `forms` is [final, medial, initial]; reversed so this RTL-rendered text puts the initial form on the right.
            secondaryArabic: data.forms.prefix(3).reversed().joined(separator: "   "),
            shareLabel: "Share Letter",
            // Always share as "English - Arabic", e.g. "Baa - ب".
            shareText: "\(data.transliteration) - \(data.letter)",
            allowsQuranicFont: !data.isNonArabicScriptLetter
        )
    }

    /// Any asset image, blown up full screen and zoomable.
    static func image(_ assetName: String, title: String, subtitle: String? = nil) -> FocusItem {
        FocusItem(
            id: "image-\(assetName)",
            arabic: "",
            title: title,
            subtitle: subtitle,
            shareLabel: "Share Image",
            shareText: title,
            imageName: assetName
        )
    }

    /// An Arabic numeral, so the numbers open full screen like the letters do.
    static func number(_ data: (number: String, name: String, transliteration: String, englishNumber: String)) -> FocusItem {
        FocusItem(
            id: "number-\(data.englishNumber)",
            arabic: data.number,
            title: data.transliteration,
            subtitle: data.name,
            footnote: "Number \(data.englishNumber)",
            secondaryArabic: data.englishNumber,
            shareLabel: "Share Number",
            shareText: "\(data.transliteration) - \(data.number)",
            // The Hafs face draws Arabic-Indic digits as ayah medallions (a dot in a ring), so a
            // numeral is always set in the system face.
            allowsQuranicFont: false
        )
    }

    /// `withDetails` adds the name's second half (Other Names, the description, and the two doors);
    /// see `FocusNameDetails`. A TAP passes true, in the grid and (since 2026-09-25) the list
    /// alike: it is the one way to that content in both. The context menu's "View Fullscreen"
    /// passes false, the name alone at full size.
    static func name(_ name: NameOfAllah, withDetails: Bool = false) -> FocusItem {
        FocusItem(
            id: "name-\(name.number)",
            arabic: name.displayArabicName,
            title: name.transliteration,
            subtitle: name.meaning,
            footnote: "First found: \(name.firstFoundShort)",
            secondaryArabic: name.numberArabic,
            shareLabel: "Share Name",
            // Always share as "English - Arabic", e.g. "Ar-Rahman - الرحمن".
            shareText: "\(name.transliteration) - \(name.name.removeDiacriticsFromLastLetter())",
            nameDetail: withDetails ? name : nil
        )
    }
}

#endif

// MARK: - Presenting

// Outside the `#if os(iOS)` above: the screens that carry these images (Tajweed, Pillars) build for the watch
// too, so the modifier has to EXIST there or every call site fails to compile. There's no focus overlay on
// watchOS - no room for one - so it's a no-op there rather than a per-call-site `#if`.
extension View {
    /// Makes an inline image open full screen (zoomable, shareable) on tap. Attach it to the `Image` itself:
    ///
    ///     Image("Makharij1").resizable().scaledToFit().focusableImage("Makharij1", title: "Makharij")
    ///
    /// The whole image is the hit target, so it's easy to hit - the diagrams in Pillars and Tajweed are far too
    /// small to read inline, and this is the way out of that.
    @ViewBuilder
    func focusableImage(_ assetName: String, title: String, subtitle: String? = nil) -> some View {
        #if os(iOS)
        contentShape(Rectangle())
            .onTapGesture {
                Settings.shared.hapticFeedback()
                FocusOverlayPresenter.shared.present(.image(assetName, title: title, subtitle: subtitle))
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("\(title). Open full screen")
        #else
        self
        #endif
    }
}
