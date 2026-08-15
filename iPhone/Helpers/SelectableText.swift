import SwiftUI

#if os(iOS)
import UIKit

// MARK: - Selectable prose

/// Read-only, drag-selectable text - the Apple News behaviour, where any run of a passage can be
/// highlighted and copied rather than the whole block or nothing.
///
/// **Why this exists rather than `Text(...).textSelection(.enabled)`.** Inside a `List` row, that
/// modifier loses the press-and-drag to the list's own scroll gesture, so the best you ever get is a
/// long-press "Copy" of the entire block. Almost every prose surface in this app - the Islam tab's
/// articles, the hadith collection notes, the credits - is a `List`, so the modifier alone would have
/// given a copy button dressed up as selection. `isEditable = false` with `isSelectable = true` gives
/// the real thing: drag to highlight any part, copy it, and never alter a word.
///
/// It is deliberately NOT the default everywhere. A `UITextView` per row is heavier than a `Text` and
/// answers accessibility differently, so it belongs on the passages a reader would actually quote -
/// article bodies, biographies, explanations - while short labels, values, and row titles stay `Text`.
/// The lighter `.textSelection(.enabled)` covers the rest via `selectableArticleList()`.
struct SelectableTextView: UIViewRepresentable {
    /// The fully-styled string to draw. Callers with plain text use the convenience initializer below;
    /// callers with markdown or search highlighting hand over an already-built attributed string.
    let attributed: NSAttributedString

    /// A range to bring on screen whenever it changes - find-in-page. The text view doesn't scroll
    /// itself (it sizes to its content and the surrounding scroll view does the scrolling), so this
    /// scrolls the ENCLOSING scroll view instead. See `scroll(_:to:)`.
    var scrollTarget: NSRange? = nil

    init(attributed: NSAttributedString, scrollTarget: NSRange? = nil) {
        self.attributed = attributed
        self.scrollTarget = scrollTarget
    }

    init(
        text: String,
        font: UIFont,
        color: UIColor = .label,
        isArabic: Bool = false,
        lineSpacing: CGFloat = 2,
        alignment: NSTextAlignment? = nil
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment ?? (isArabic ? .right : .natural)
        paragraph.baseWritingDirection = isArabic ? .rightToLeft : .natural
        paragraph.lineSpacing = lineSpacing

        self.attributed = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
        ])
    }

    /// A non-scrolling text view whose intrinsic height always reflects the CURRENT width's layout.
    /// The stock view measures once before SwiftUI hands the row its real width (zero width = one
    /// endless line), and never re-reports - so every block stood one line tall, clipping the text
    /// and stopping any selection at that single visible line. Re-measure whenever the width moves.
    final class SelfSizingTextView: UITextView {
        private var lastMeasuredWidth: CGFloat = 0

        override var intrinsicContentSize: CGSize {
            let measureWidth = bounds.width > 0 ? bounds.width : UIView.layoutFittingExpandedSize.width
            let fitted = sizeThatFits(CGSize(width: measureWidth, height: .greatestFiniteMagnitude))
            return CGSize(width: UIView.noIntrinsicMetric, height: ceil(fitted.height))
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if abs(bounds.width - lastMeasuredWidth) > 0.5 {
                lastMeasuredWidth = bounds.width
                invalidateIntrinsicContentSize()
            }
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = SelfSizingTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false          // let it size itself; the List scrolls
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = false
        // Without this the text view reports a huge intrinsic width and the row stops wrapping.
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // Guarded: assigning `attributedText` forces a full text re-layout, and SwiftUI calls this on
        // every render of the enclosing view. Find-in-page on a long tafsir re-renders every block on
        // each keystroke, so re-laying out the blocks whose text didn't actually change was the
        // difference between a smooth search field and a stuttering one.
        if textView.attributedText != attributed {
            textView.attributedText = attributed
            // New text = new height at the same width.
            textView.invalidateIntrinsicContentSize()
        }

        guard let scrollTarget, scrollTarget != context.coordinator.lastScrollTarget else { return }
        context.coordinator.lastScrollTarget = scrollTarget
        // Deferred a runloop: when the text changed just above, the new glyph positions aren't laid
        // out yet and the rect would be measured against the old layout.
        DispatchQueue.main.async { Self.scroll(textView, to: scrollTarget) }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var lastScrollTarget: NSRange?
    }

    /// Brings a character range on screen by scrolling whatever scroll view the text view happens to
    /// live in. `scrollRangeToVisible` is no use here - it scrolls the text view's OWN scroll view,
    /// which is disabled so the view can size itself to its content inside the sheet's single
    /// scrolling column (the thing that lets the ayah card, the pickers and the tafsir scroll as one).
    private static func scroll(_ textView: UITextView, to range: NSRange) {
        guard let start = textView.position(from: textView.beginningOfDocument, offset: range.location),
              let end = textView.position(from: start, offset: range.length),
              let textRange = textView.textRange(from: start, to: end)
        else { return }

        let rect = textView.firstRect(for: textRange)
        guard !rect.isNull, rect.height.isFinite, rect.width.isFinite else { return }

        var ancestor: UIView? = textView.superview
        while let view = ancestor, !(view is UIScrollView) { ancestor = view.superview }
        guard let scrollView = ancestor as? UIScrollView else { return }

        // Converting INTO a scroll view's coordinate space yields content coordinates, so this is
        // directly comparable to `contentOffset`.
        let target = textView.convert(rect, to: scrollView)
        let centered = target.midY - scrollView.bounds.height / 2
        let maxOffset = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.setContentOffset(
            CGPoint(x: scrollView.contentOffset.x, y: min(max(0, centered), maxOffset)),
            animated: true
        )
    }

    /// iOS 16+: answer SwiftUI's size proposal directly with the wrapped height for the proposed
    /// width, so the row gets the right multi-line height on the FIRST layout pass - no
    /// invalidation round-trip (the subclass above still covers iOS 15).
    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }
        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fitted.height))
    }
}

extension NSAttributedString {
    /// Renders a SwiftUI `AttributedString` into UIKit attributes a `UITextView` can draw.
    ///
    /// `NSAttributedString(someAttributedString)` is NOT enough: markdown parsing leaves bold/italic as
    /// `inlinePresentationIntent` (a semantic marker SwiftUI resolves at draw time, not a font), and
    /// `foregroundColor`/`backgroundColor` land in the SwiftUI attribute scope, which UIKit ignores.
    /// Handed straight to a text view, a tafsir would come out uniformly regular and un-highlighted.
    /// So the runs are walked and each intent is resolved against `baseFont` here.
    static func selectableProse(
        _ attributed: AttributedString,
        baseFont: UIFont,
        baseColor: UIColor,
        paragraph: NSParagraphStyle
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        for run in attributed.runs {
            var font = baseFont
            var attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: baseColor,
                .paragraphStyle: paragraph,
            ]

            if let intent = run.inlinePresentationIntent {
                var traits = baseFont.fontDescriptor.symbolicTraits
                if intent.contains(.stronglyEmphasized) { traits.insert(.traitBold) }
                if intent.contains(.emphasized) { traits.insert(.traitItalic) }
                // Derived from the base descriptor, so the app's rounded design survives the trait.
                if let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits) {
                    font = UIFont(descriptor: descriptor, size: baseFont.pointSize)
                }
                if intent.contains(.strikethrough) {
                    attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                }
            }

            attributes[.font] = font
            // The search highlighter's tint, and the box on the find-in-page "current" match.
            if let foreground = run.foregroundColor { attributes[.foregroundColor] = UIColor(foreground) }
            if let background = run.backgroundColor { attributes[.backgroundColor] = UIColor(background) }
            // No bundled tafsir or surah-info source contains a markdown link today, but carrying the
            // attribute costs nothing and means a source that gains one stays tappable rather than
            // silently flattening to plain text.
            if let link = run.link { attributes[.link] = link }
            // SwiftUI's `underlineStyle` is a `Text.LineStyle`, not an option set, so its presence is
            // all that can be read across generically - drawn as a single rule.
            if run.underlineStyle != nil {
                attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }

            result.append(NSAttributedString(
                string: String(attributed[run.range].characters),
                attributes: attributes
            ))
        }

        return result
    }
}

/// Drag-selectable prose that keeps markdown styling and search highlighting - the tafsir and surah-info
/// bodies. Takes the same `AttributedString` the `Text` it replaces was given.
struct SelectableAttributedProse: View {
    let attributed: AttributedString
    var textStyle: UIFont.TextStyle = .body
    var weight: UIFont.Weight = .regular
    var lineSpacing: CGFloat = 5
    var alignment: NSTextAlignment = .natural

    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineSpacing = lineSpacing

        return SelectableTextView(attributed: .selectableProse(
            attributed,
            baseFont: .roundedSystemFont(
                ofSize: UIFont.preferredFont(forTextStyle: textStyle).pointSize,
                weight: weight
            ),
            baseColor: .label,
            paragraph: paragraph
        ))
        // See `SelectableProse` - the text view opts out of automatic content-size tracking, so the
        // font is rebuilt from this instead.
        .id(sizeCategory)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A drop-in replacement for `Text(prose).font(.body)` that the reader can drag-select.
///
/// Styled from a `UIFont.TextStyle` rather than a fixed point size so it tracks Dynamic Type the way
/// the `Text` it replaces did, and rendered in SF Rounded to match everything around it.
struct SelectableProse: View {
    let text: String
    var textStyle: UIFont.TextStyle = .body
    var weight: UIFont.Weight = .regular
    var secondary: Bool = false
    /// Overrides the label/secondary-label default - for accented pull quotes and the like.
    var color: Color? = nil
    var lineSpacing: CGFloat = 2
    var isArabic: Bool = false
    var alignment: NSTextAlignment? = nil

    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        SelectableTextView(
            text: text,
            font: resolvedFont,
            color: color.map(UIColor.init) ?? (secondary ? .secondaryLabel : .label),
            isArabic: isArabic,
            lineSpacing: lineSpacing,
            alignment: alignment
        )
        // The text view is told not to auto-track content size (it would fight the intrinsic-height
        // measurement), so the font is rebuilt here instead - reading `sizeCategory` is what makes
        // SwiftUI re-run this body when the user changes text size in Settings.
        .id(sizeCategory)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var resolvedFont: UIFont {
        let size = UIFont.preferredFont(forTextStyle: textStyle).pointSize
        // Arabic keeps whatever face the reader chose; English follows the app's rounded design.
        return isArabic
            ? UIFont.systemFont(ofSize: size, weight: weight)
            : .roundedSystemFont(ofSize: size, weight: weight)
    }
}

#endif
