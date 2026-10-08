#if os(iOS)
import SwiftUI
import UIKit

/// Shared line-spacing rule for mushaf page text.
///
/// This type once owned page fitting - a UIKit measurement + binary search that picked the largest font
/// size at which a whole page fit on screen. That job moved wholesale into `MushafPageComposer.fittedSize`
/// (composed off-main and cached by `MushafPageRenderCache`), which left everything here dead except this
/// one rule - and the fitted Arabic page no longer uses even that: it is measured at ZERO base spacing
/// (`MushafPageComposer.baseLineSpacing`, maximize-font user rule), so this rule now leads only the
/// English page renders and the fit-off scrolling page.
enum MushafPageFitter {
    /// Line spacing scales with the text, so a shrunk page keeps the proportions of a full-size one. At the
    /// user's chosen size this is exactly the 12pt `lineSpacing` the reader has always used.
    static func lineSpacing(for size: CGFloat, baseSize: CGFloat) -> CGFloat {
        guard baseSize > 0 else { return 12 }
        return 12 * size / baseSize
    }
}
#endif
