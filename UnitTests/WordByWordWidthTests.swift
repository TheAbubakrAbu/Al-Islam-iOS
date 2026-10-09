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

        let wide = try XCTUnwrap(Self.textView(in: host.view), "the ayah must render through the text view")
        XCTAssertGreaterThan(wide.frame.width, 700, "Precondition: the text took the wide container's width")

        await resize(to: 402)

        let narrow = try XCTUnwrap(Self.textView(in: host.view))
        XCTAssertLessThanOrEqual(narrow.frame.width, 402 - 2 * Self.margin + 0.5,
                                 "The text kept its stale width (\(narrow.frame.width)pt) inside a 402pt container")
    }

    /// Portrait to landscape: the direction that already worked must keep working.
    @MainActor
    func testTextWidensWhenTheContainerWidens() async throws {
        let host = makeHost(width: 402)

        let narrow = try XCTUnwrap(Self.textView(in: host.view), "the ayah must render through the text view")
        XCTAssertLessThanOrEqual(narrow.frame.width, 402 - 2 * Self.margin + 0.5)

        await resize(to: 800)

        let wide = try XCTUnwrap(Self.textView(in: host.view))
        XCTAssertGreaterThan(wide.frame.width, 700, "The text did not grow into the wider container")
    }

    // MARK: - Harness

    private static let margin: CGFloat = 16

    /// The actions sheet's shape: a vertical ScrollView holding a padded stack with the text in it.
    @MainActor
    private func makeHost(width: CGFloat) -> UIHostingController<AnyView> {
        let segment = WordByWordSegment(
            displayText: "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ",
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

    private static func textView(in view: UIView) -> UITextView? {
        if let textView = view as? UITextView { return textView }
        for subview in view.subviews {
            if let found = textView(in: subview) { return found }
        }
        return nil
    }
}
