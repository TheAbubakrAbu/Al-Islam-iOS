import XCTest
import SwiftUI
@testable import iPhone

/// The ayah text view must follow its container in BOTH directions.
///
/// `WordByWordText` learns its width by measuring itself, and `WordByWordTextView.sizeThatFits`
/// used to answer with that stored width whatever it was offered. The measurement was therefore
/// circular: once the stored width was wider than the container, the view still claimed it, its
/// measured size stayed wide, and nothing could ever shrink it. Rotating the ayah actions sheet
/// back from landscape left the whole sheet laid out at the landscape width (2026-10-09: three tile
/// columns clipped at both edges, Arabic and English running off each side). The list reader hid
/// it only because its rows take a new identity on rotation; a sheet gets no such reset.
final class WordByWordWidthTests: XCTestCase {

    private var window: UIWindow?

    override func tearDown() {
        window?.isHidden = true
        window?.rootViewController = nil
        window = nil
        super.tearDown()
    }

    /// Landscape to portrait: the text view must narrow to the new container.
    @MainActor
    func testTextNarrowsWhenTheContainerNarrows() async throws {
        let host = makeHost(width: 800)

        let wide = try XCTUnwrap(Self.column(in: host.view), "the ayah must render through the text view")
        XCTAssertGreaterThan(wide.frame.width, 700, "Precondition: the text took the wide container's width")

        await resize(to: 402)

        let narrow = try XCTUnwrap(Self.column(in: host.view))
        XCTAssertLessThanOrEqual(narrow.frame.width, 402 - 2 * Self.margin + 0.5,
                                 "The text kept its stale width (\(narrow.frame.width)pt) inside a 402pt container")
    }

    /// Portrait to landscape: the direction that already worked must keep working.
    @MainActor
    func testTextWidensWhenTheContainerWidens() async throws {
        let host = makeHost(width: 402)

        let narrow = try XCTUnwrap(Self.column(in: host.view), "the ayah must render through the text view")
        XCTAssertLessThanOrEqual(narrow.frame.width, 402 - 2 * Self.margin + 0.5)

        await resize(to: 800)

        let wide = try XCTUnwrap(Self.column(in: host.view))
        XCTAssertGreaterThan(wide.frame.width, 700, "The text did not grow into the wider container")
    }

    // MARK: - One typesetting per run

    /// The run is typeset in a column only the view itself resizes (`OwnedTextContainer`). A frame
    /// change and a measurement, the two things a non-scrolling text view answers by writing its own
    /// geometry into its container, each used to typeset the whole ayah again: three typesettings
    /// in the frame that built a reader row (2026-11-13). Neither may touch the layout now.
    @MainActor
    func testFrameChangesAndMeasurementsLeaveTheTypesettingAlone() async throws {
        let host = makeHost(width: 402, text: try await longAyah())
        let column = try XCTUnwrap(Self.column(in: host.view), "the ayah must render through the text view")
        let textView = column.textView
        let container = try XCTUnwrap(textView.textContainer as? OwnedTextContainer,
                                      "The run must be typeset in a container the text view cannot resize")
        let typeset = container.size
        XCTAssertEqual(typeset.height, .greatestFiniteMagnitude, "The column has no height limit")
        XCTAssertEqual(typeset.width, column.frame.width, accuracy: 0.5, "The column is the row's width")

        let counter = InvalidationCounter()
        textView.layoutManager.delegate = counter
        textView.frame = textView.frame.insetBy(dx: 0, dy: -40)
        _ = textView.sizeThatFits(CGSize(width: 250, height: 90))
        column.setNeedsLayout()
        column.layoutIfNeeded()

        XCTAssertEqual(container.size, typeset, "A frame change or a measurement resized the run's column")
        XCTAssertEqual(counter.invalidations, 0, "A frame change or a measurement threw the typesetting away")
    }

    /// The height a row takes is read off that one layout. It must be the text view's own answer
    /// for the column, at every width, or a row would clip its last line or carry a band of air.
    @MainActor
    func testTheRowHeightIsTheTextViewsOwnAnswer() async throws {
        let ayah = try await longAyah()
        for width: CGFloat in [320, 402, 800] {
            let host = makeHost(width: width, text: ayah)
            let column = try XCTUnwrap(Self.column(in: host.view), "the ayah must render through the text view")
            let own = ceil(column.textView.sizeThatFits(
                CGSize(width: column.frame.width + 2 * ArabicInkBleedHost.bleed, height: .greatestFiniteMagnitude)
            ).height)
            XCTAssertGreaterThan(own, 80, "Precondition: the ayah wraps to several lines at \(width)pt")
            XCTAssertEqual(column.frame.height, own, accuracy: 0.5, "At \(width)pt the row is not the text's height")
            window?.isHidden = true
            window?.rootViewController = nil
            window = nil
        }
    }

    private final class InvalidationCounter: NSObject, NSLayoutManagerDelegate {
        var invalidations = 0
        func layoutManagerDidInvalidateLayout(_ sender: NSLayoutManager) { invalidations += 1 }
    }

    /// Ayat al-Kursi (2:255), from the app's own text: long enough to wrap to several lines at every
    /// width tested.
    @MainActor
    private func longAyah() async throws -> String {
        await QuranData.shared.waitUntilLoaded()
        return try XCTUnwrap(QuranData.shared.ayah(surah: 2, ayah: 255)?.textArabic, "2:255 must load")
    }

    // MARK: - Harness

    private static let margin: CGFloat = 16

    /// The actions sheet's shape: a vertical ScrollView holding a padded stack with the text in it.
    @MainActor
    private func makeHost(width: CGFloat,
                          text: String = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ") -> UIHostingController<AnyView> {
        let segment = WordByWordSegment(
            displayText: text,
            preStyled: nil,
            ayahNumberArabic: "١",
            glosses: [],
            highlightAllahNames: false
        )
        let content = ScrollView {
            VStack(spacing: 14) {
                WordByWordText(
                    segments: [segment],
                    fontName: nil,
                    fontSize: 28,
                    tapsRequired: 1,
                    selectedWord: nil,
                    onSelectWord: { _ in }
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, Self.margin)
        }
        let host = UIHostingController(rootView: AnyView(content))
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = scene.map { UIWindow(windowScene: $0) } ?? UIWindow()
        window.frame = CGRect(x: 0, y: 0, width: width, height: 600)
        window.rootViewController = host
        window.makeKeyAndVisible()
        self.window = window
        settleSynchronously()
        return host
    }

    @MainActor
    private func resize(to width: CGFloat) async {
        window?.frame = CGRect(x: 0, y: 0, width: width, height: 600)
        await settle()
    }

    /// Lets SwiftUI deliver the geometry callback, apply the width it stores, and lay out again.
    @MainActor
    private func settle() async {
        for _ in 0..<12 {
            window?.layoutIfNeeded()
            try? await Task.sleep(nanoseconds: 40_000_000)
        }
        window?.layoutIfNeeded()
    }

    @MainActor
    private func settleSynchronously() {
        for _ in 0..<12 {
            window?.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.04))
        }
        window?.layoutIfNeeded()
    }

    /// The ayah's text COLUMN: the frame SwiftUI lays out, which the text view hangs out of by its
    /// ink bleed on each side (`ArabicInkBleedHost`).
    private static func column(in view: UIView) -> ArabicInkBleedHost? {
        if let column = view as? ArabicInkBleedHost { return column }
        for subview in view.subviews {
            if let found = column(in: subview) { return found }
        }
        return nil
    }
}
