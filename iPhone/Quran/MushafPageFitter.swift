#if os(iOS)
import SwiftUI
import UIKit

/// Picks the largest Arabic font size at which a whole mushaf page fits on screen without scrolling.
///
/// SwiftUI has no way to ask "how tall would this text be at size N?" - `minimumScaleFactor` only shrinks a
/// `Text` that has a line limit, and `ViewThatFits` needs iOS 16 and a fixed ladder of candidates. So the page
/// is measured directly with UIKit text layout: the same fonts, the same width, the same line spacing that
/// SwiftUI will use, laid out into an unbounded height. Then a binary search finds the biggest size whose
/// total height still fits.
///
/// This never *enlarges* past the user's chosen size - a page with only a few ayahs stays at the size they
/// picked rather than ballooning to fill the screen.
enum MushafPageFitter {
    /// Never shrink below this. Past it the text is unreadable and scrolling is the better answer.
    static let minimumFontSize: CGFloat = 9

    /// UIKit's line metrics and SwiftUI's don't agree to the pixel, so aim slightly under the real height.
    /// The reader keeps its `ScrollView` regardless, which turns any residual overflow into a short scroll
    /// rather than clipped ayahs.
    private static let safetyFactor: CGFloat = 0.97

    /// Chrome that sits inside the measured region, above and between the ayah blocks.
    private static let verticalPadding: CGFloat = 32      // .padding(.vertical, 16)
    private static let segmentSpacing: CGFloat = 18       // VStack(spacing: 18)
    private static let dividerToTextSpacing: CGFloat = 12 // VStack(spacing: 12)

    private struct Key: Hashable {
        let page: Int
        let ayahCount: Int
        let width: Int
        let height: Int
        let baseSize: Int
        let fontName: String
        let clean: Bool
    }

    /// Fitting all 604 pages costs real work, and SwiftUI re-evaluates a body freely, so memoize. The key
    /// carries everything that changes the answer; nothing else can.
    @MainActor private static var cache: [Key: CGFloat] = [:]

    @MainActor
    static func invalidate() { cache.removeAll() }

    /// - Parameters:
    ///   - availableWidth: the text's own width, i.e. after the page's horizontal padding.
    ///   - availableHeight: everything between the page header and the footer.
    ///   - baseSize: the user's chosen Arabic font size; the result never exceeds it.
    ///   - fontName: the custom Arabic font, or nil for the system font.
    @MainActor
    static func fittedFontSize(
        page: MushafPage,
        availableWidth: CGFloat,
        availableHeight: CGFloat,
        baseSize: CGFloat,
        fontName: String?,
        clean: Bool
    ) -> CGFloat {
        guard availableWidth > 1, availableHeight > 1, baseSize > minimumFontSize else { return baseSize }

        let key = Key(
            page: page.page,
            ayahCount: page.segments.reduce(0) { $0 + $1.ayahs.count },
            width: Int(availableWidth.rounded()),
            height: Int(availableHeight.rounded()),
            baseSize: Int(baseSize.rounded()),
            fontName: fontName ?? "",
            clean: clean
        )
        if let cached = cache[key] { return cached }

        let budget = availableHeight * safetyFactor
        let fits: (CGFloat) -> Bool = { size in
            height(of: page, at: size, baseSize: baseSize, width: availableWidth, fontName: fontName, clean: clean) <= budget
        }

        var result = baseSize
        if !fits(baseSize) {
            var low = minimumFontSize    // known to fit, or as small as we're willing to go
            var high = baseSize          // known not to fit
            // 8 halvings of a ≤66pt range lands inside a quarter point - finer than the half-point we round to.
            for _ in 0..<8 {
                let mid = (low + high) / 2
                if fits(mid) { low = mid } else { high = mid }
            }
            result = (low * 2).rounded(.down) / 2
        }

        // Bounded, unlike before: every (page, geometry, size, font) combination lived forever, so a
        // session that toured fonts/sizes/rotations grew the map without limit. Entries are tiny, so the
        // cap is generous - and a full reset is cheaper than LRU bookkeeping on this hot path.
        if cache.count > 4096 { cache.removeAll(keepingCapacity: true) }
        cache[key] = result
        return result
    }

    /// Line spacing scales with the text, so a shrunk page keeps the proportions of a full-size one. At the
    /// user's chosen size this is exactly the 12pt `lineSpacing` the reader has always used.
    static func lineSpacing(for size: CGFloat, baseSize: CGFloat) -> CGFloat {
        guard baseSize > 0 else { return 12 }
        return 12 * size / baseSize
    }

    // MARK: - Measurement

    @MainActor
    private static func height(
        of page: MushafPage,
        at size: CGFloat,
        baseSize: CGFloat,
        width: CGFloat,
        fontName: String?,
        clean: Bool
    ) -> CGFloat {
        var total = verticalPadding
        total += segmentSpacing * CGFloat(max(page.segments.count - 1, 0))
        total += (dividerHeight + dividerToTextSpacing) * CGFloat(page.segments.count)

        for segment in page.segments {
            total += textHeight(
                of: segment, at: size, baseSize: baseSize, width: width, fontName: fontName, clean: clean
            )
        }
        return total
    }

    /// The surah divider row: a single line of `.caption` at whatever Dynamic Type size is in force.
    private static var dividerHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .caption1).lineHeight
    }

    @MainActor
    private static func textHeight(
        of segment: MushafPage.Segment,
        at size: CGFloat,
        baseSize: CGFloat,
        width: CGFloat,
        fontName: String?,
        clean: Bool
    ) -> CGFloat {
        let arabic = font(named: fontName, size: size)
        let marker = font(named: Settings.qiraatUthmaniFontName, size: size * 0.85)

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = lineSpacing(for: size, baseSize: baseSize)
        paragraph.alignment = .center
        paragraph.baseWritingDirection = .rightToLeft

        // Mirrors `MushafPageContent.segmentBody`: each ayah's text, then its Arabic number, run together.
        let string = NSMutableAttributedString()
        for ayah in segment.ayahs {
            string.append(NSAttributedString(
                string: ayah.displayArabicText(surahId: segment.surah.id, clean: clean),
                attributes: [.font: arabic, .paragraphStyle: paragraph]
            ))
            string.append(NSAttributedString(
                string: " \(ayah.idArabic) ",
                attributes: [.font: marker, .paragraphStyle: paragraph]
            ))
        }

        let bounds = string.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return ceil(bounds.height)
    }

    /// Falls back to the system font when a custom face is missing, exactly as `Font.custom` does. The fallback is
    /// the *rounded* system face so it matches what `MushafPageComposer` actually draws, and so the height this
    /// fitter measures is the height the page renders at.
    private static func font(named name: String?, size: CGFloat) -> UIFont {
        guard let name, let font = UIFont(name: name, size: size) else {
            return .roundedSystemFont(ofSize: size)
        }
        return font
    }
}
#endif
