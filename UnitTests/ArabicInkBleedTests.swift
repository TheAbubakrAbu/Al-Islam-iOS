import XCTest
import SwiftUI
@testable import iPhone

/// The Quranic faces draw ink past a glyph's advance box. In KFGQPC HAFS the small ṣād of a hamzat
/// wasl (ٱ) reaches about 1pt per 40pt of size to the RIGHT of the alif, and a line-final kasra or
/// tanween about 2.7pt to the LEFT (measured with CoreText, 2026-10-21). A line's first glyph sits
/// flush at the text container's right edge, so that ink falls outside the container, and a
/// `UITextView` rasterises its text in a surface exactly the container's size: `clipsToBounds = false`
/// frees SUBVIEWS, never the view's own drawing. The mark was sliced off in the list rows, the ayah
/// sheets and the mushaf page alike (Abu, 2026-10-21: "look at hamzatul wasl its broken").
///
/// These tests photograph the real on-screen drawing (`drawHierarchy`, the render server's pixels, not
/// `layer.render` which does not reproduce the surface limit) and look for ink in the strips just
/// outside the text column, on the side the Arabic starts and the side it ends.
final class ArabicInkBleedTests: XCTestCase {

    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        super.tearDown()
    }

    /// The list rows and the ayah sheets: a line-initial alif wasla keeps its ṣād at the right edge.
    @MainActor
    func testListRendererKeepsTheWaslaMarkPastTheRightEdge() throws {
        let segment = WordByWordSegment(
            displayText: "ٱلَّذِينَ",
            preStyled: nil,
            ayahNumberArabic: "١",
            glosses: [],
            highlightAllahNames: false
        )
        let content = VStack {
            WordByWordText(
                segments: [segment],
                fontName: Settings.hafsUthmaniFontName,
                fontSize: Self.fontSize,
                tapsRequired: 1,
                selectedWord: nil,
                onSelectWord: { _ in }
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, Self.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white)

        let window = show(content)
        let textView = try XCTUnwrap(Self.textView(in: window), "the ayah must render through the text view")
        let column = Self.textColumn(of: textView, in: window)
        XCTAssertGreaterThan(column.width, 100, "Precondition: the text column has its width")

        let snapshot = try XCTUnwrap(Snapshot(window: window), "the window must snapshot")
        let rightStrip = CGRect(x: column.maxX + 0.5, y: column.minY, width: Self.probe, height: column.height)
        XCTAssertGreaterThan(snapshot.inkCount(in: rightStrip), 0,
                             "No ink right of the text column: the alif wasla's ṣād was sliced off at the container edge")
    }

    /// The mushaf page: justified lines end flush at BOTH margins, so a line-final mark on the left
    /// and a line-initial wasla on the right both keep their ink.
    @MainActor
    func testPageRendererKeepsInkPastBothEdges() throws {
        let font = try XCTUnwrap(QuranFontCache.font(name: Settings.hafsUthmaniFontName, size: Self.fontSize))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        paragraph.baseWritingDirection = .rightToLeft
        let attributed = NSAttributedString(
            string: "ٱلَّذِينَ ذِكْرَى ٱلدَّارِ",
            attributes: [.font: font, .foregroundColor: UIColor.black, .paragraphStyle: paragraph]
        )
        // A container one point wider than the line, so the line fills it: its first glyph at the right
        // edge and its last within a point of the left one, the way a justified page line sits.
        let natural = attributed.boundingRect(with: CGSize(width: 10_000, height: CGFloat.greatestFiniteMagnitude),
                                              options: [.usesLineFragmentOrigin], context: nil)
        let width = ceil(natural.width) + 1
        let height = ceil(natural.height) + 8

        let content = MushafPageTextView(
            attributed: attributed,
            ranges: [],
            width: width,
            height: height,
            onTapAyah: { _, _ in },
            onLongPressAyah: { _, _ in }
        )
        .frame(width: width, height: height)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)

        let window = show(content)
        let textView = try XCTUnwrap(Self.textView(in: window), "the page must render through the text view")
        let column = Self.textColumn(of: textView, in: window)
        XCTAssertEqual(column.width, width, accuracy: 0.5, "Precondition: the container took the page width")

        let snapshot = try XCTUnwrap(Snapshot(window: window), "the window must snapshot")
        let rightStrip = CGRect(x: column.maxX + 0.5, y: column.minY, width: Self.probe, height: column.height)
        let leftStrip = CGRect(x: column.minX - 0.5 - Self.probe, y: column.minY, width: Self.probe, height: column.height)
        XCTAssertGreaterThan(snapshot.inkCount(in: rightStrip), 0,
                             "No ink right of the page's text column: the alif wasla's ṣād was sliced off")
        XCTAssertGreaterThan(snapshot.inkCount(in: leftStrip), 0,
                             "No ink left of the page's text column: the last letter's kasra was sliced off")
    }

    /// The fitted page squeezes every line box to 0.90 of the face's own and drops the baseline by half
    /// the overflow (`MushafPageComposer.lineBoxScale`, `bodyBaselineOffset`), so the tallest marks on a
    /// page's FIRST line rise above the column. The ۖ over ٱلصِّدِّيقُونَ reaches 1.7pt past the box at
    /// 60pt (CoreText, 2026-10-27), and at the top of its page (57:19) it lost the top of its ṣād (Abu,
    /// 2026-10-27: "the sillee is cut off").
    @MainActor
    func testFittedPageKeepsInkAboveItsFirstLine() throws {
        let font = try XCTUnwrap(QuranFontCache.font(name: Settings.hafsUthmaniFontName, size: Self.fontSize))
        let box = font.lineHeight * 0.90
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .right
        paragraph.baseWritingDirection = .rightToLeft
        paragraph.minimumLineHeight = box
        paragraph.maximumLineHeight = box
        let attributed = NSAttributedString(
            string: "هُمُ ٱلصِّدِّيقُونَۖ",
            attributes: [.font: font, .foregroundColor: UIColor.black, .paragraphStyle: paragraph]
        )
        let natural = attributed.boundingRect(with: CGSize(width: 10_000, height: CGFloat.greatestFiniteMagnitude),
                                              options: [.usesLineFragmentOrigin], context: nil)
        let width = ceil(natural.width) + 1
        let height = ceil(box)

        let content = MushafPageTextView(
            attributed: attributed,
            ranges: [],
            width: width,
            height: height,
            baselineOffset: ceil(font.ascender - (font.lineHeight - box) / 2),
            baselineBand: (box - 2)...(box + 2),
            onTapAyah: { _, _ in },
            onLongPressAyah: { _, _ in }
        )
        .frame(width: width, height: height)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)

        let window = show(content)
        let textView = try XCTUnwrap(Self.textView(in: window), "the page must render through the text view")
        let column = Self.textColumn(of: textView, in: window)
        XCTAssertEqual(column.height, height, accuracy: 0.5, "Precondition: the container took the page height")

        let snapshot = try XCTUnwrap(Snapshot(window: window), "the window must snapshot")
        let topStrip = CGRect(x: column.minX, y: column.minY - 0.5 - Self.probe, width: column.width, height: Self.probe)
        XCTAssertGreaterThan(snapshot.inkCount(in: topStrip), 0,
                             "No ink above the page's first line: the pause mark's ṣād was sliced off at the column's top")
    }

    // MARK: - Harness

    /// Big enough that the overhang is several pixels wide at 3x: about 1.6pt right and 4pt left.
    private static let fontSize: CGFloat = 60
    private static let margin: CGFloat = 40
    /// How far outside the column to look. Well inside `margin`, so nothing else can be there.
    private static let probe: CGFloat = 8

    @MainActor
    private func show<Content: View>(_ content: Content) -> UIWindow {
        let host = UIHostingController(rootView: AnyView(content))
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = scene.map { UIWindow(windowScene: $0) } ?? UIWindow()
        window.frame = CGRect(x: 0, y: 0, width: 402, height: 600)
        window.overrideUserInterfaceStyle = .light
        window.backgroundColor = .white
        window.rootViewController = host
        window.makeKeyAndVisible()
        self.window = window
        for _ in 0..<12 {
            window.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.04))
        }
        window.layoutIfNeeded()
        return window
    }

    /// The text container's box in window points: where the lines are laid out, whatever the view's
    /// own frame around it.
    @MainActor
    private static func textColumn(of textView: UITextView, in window: UIWindow) -> CGRect {
        let inset = textView.textContainerInset
        let local = CGRect(x: inset.left, y: inset.top,
                           width: textView.textContainer.size.width,
                           height: textView.bounds.height - inset.top - inset.bottom)
        return textView.convert(local, to: window)
    }

    private static func textView(in view: UIView) -> UITextView? {
        if let textView = view as? UITextView { return textView }
        for subview in view.subviews {
            if let found = textView(in: subview) { return found }
        }
        return nil
    }

    /// The window's pixels, as the screen shows them.
    private struct Snapshot {
        let width: Int
        let height: Int
        let scale: CGFloat
        let rgba: [UInt8]

        @MainActor
        init?(window: UIWindow) {
            let scale = window.screen.scale
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            var drew = false
            let image = UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
                drew = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            guard drew, let cg = image.cgImage else { return nil }
            let width = cg.width, height = cg.height
            var rgba = [UInt8](repeating: 0, count: width * height * 4)
            let ok = rgba.withUnsafeMutableBytes { bytes -> Bool in
                guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                                              bitsPerComponent: 8, bytesPerRow: width * 4,
                                              space: CGColorSpaceCreateDeviceRGB(),
                                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
                context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
                return true
            }
            guard ok else { return nil }
            self.width = width
            self.height = height
            self.scale = scale
            self.rgba = rgba
        }

        /// Dark pixels inside `rect` (window points) on the white page.
        func inkCount(in rect: CGRect) -> Int {
            let x0 = max(Int((rect.minX * scale).rounded(.down)), 0)
            let x1 = min(Int((rect.maxX * scale).rounded(.up)), width)
            let y0 = max(Int((rect.minY * scale).rounded(.down)), 0)
            let y1 = min(Int((rect.maxY * scale).rounded(.up)), height)
            var count = 0
            for y in y0..<y1 {
                for x in x0..<x1 {
                    let i = (y * width + x) * 4
                    let luminance = (Int(rgba[i]) + Int(rgba[i + 1]) + Int(rgba[i + 2])) / 3
                    if luminance < 150 { count += 1 }
                }
            }
            return count
        }
    }
}
