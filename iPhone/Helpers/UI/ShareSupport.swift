#if os(iOS)
import SwiftUI

// What every share sheet draws with: the ayah's (ShareAyah.swift), the hadith's and a Name of Allah's
// (ShareName.swift). Here rather than in ShareAyah.swift, which ships only with the Quran reader, so an
// app without it (Al-Adhan) still shares a Name of Allah exactly the way Al-Islam does.

/// The UIKit color a share renderer draws with (ShareName.swift passes the accent this way).
extension Color { var uiColor: UIColor { UIColor(self) } }

/// Whether a share sheet sends the words, a drawn card, or a link that opens the app on them
/// (AppLink.swift). Only `text` and `image` are ever stored as the sheet's last mode: a link is a
/// one-off, and the Copy shortcuts that read the stored mode know only those two.
enum ActionMode: String {
    case text
    case image
    case link

    /// The mode a sheet reopens in: the stored one, never Link.
    static func restored(_ raw: String) -> ActionMode {
        let mode = ActionMode(rawValue: raw) ?? .image
        return mode == .link ? .image : mode
    }
}

/// The share sheets' Link preview: what the link opens, the address itself, and what happens for
/// someone without the app. Drawn on the dark card the Text preview uses, so the three modes swap in
/// one slot.
struct ShareLinkPreview: View {
    @Environment(\.appearance) private var appearance
    let title: String
    let link: AppLink

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "link")
                .font(.title3.weight(.semibold))
                .foregroundColor(appearance.accent)
                .frame(width: 48, height: 48)
                .background(Circle().fill(appearance.accent.opacity(0.22)))

            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(verbatim: link.url.absoluteString)
                .font(.footnote.monospaced())
                .foregroundColor(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
                .environment(\.layoutDirection, .leftToRight)

            Text("Opens this in \(AppIdentifiers.displayName). Without the app, it opens the App Store.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .cornerRadius(24)
        .padding(.horizontal, 16)
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }
}

enum ShareAyahRender {
    /// The widest layout measure a share image is drawn at. iPhones are all narrower than this, so
    /// they render at their real screen width as always; iPad/Mac (where `UIScreen.main` reports the
    /// full 800-1400pt display regardless of the window) clamp down to a phone-proportioned card.
    static let maxImageWidth: CGFloat = 440
}

/// The name of Allah in red on a share card and its text preview: "Allah" in English, and every Arabic
/// spelling `HighlightedSnippet` counts as the name, so a card paints exactly what the reader paints.
enum ShareAllahInk {
    static func nsRanges(in source: String) -> [NSRange] {
        var ranges: [NSRange] = []

        var englishStart = source.startIndex
        while englishStart < source.endIndex,
              let match = source.range(
                of: "Allah",
                options: [.caseInsensitive, .diacriticInsensitive],
                range: englishStart..<source.endIndex
              ) {
            ranges.append(NSRange(match, in: source))
            englishStart = match.upperBound
        }

        for range in HighlightedSnippet.arabicAllahRanges(in: source) {
            ranges.append(NSRange(range, in: source))
        }

        return ranges
    }

    /// `color`: the share card passes its backdrop's own Allah ink (`ShareBackdrop.Palette.allah`).
    /// `plainColor`: on tajweed-colored text, the card's plain text color - any other color on a letter
    /// of the name is a rule's and stays (`AllahNameInk`). Nil reddens the whole name.
    static func apply(to attributed: NSMutableAttributedString, source: String, enabled: Bool,
                      color: UIColor = .red, plainColor: UIColor? = nil) {
        guard enabled, attributed.length > 0 else { return }
        for range in nsRanges(in: source) {
            if let plainColor {
                AllahNameInk.paint(attributed, range: range, color: color, plain: plainColor)
            } else {
                attributed.addAttribute(.foregroundColor, value: color, range: range)
            }
        }
    }

    static func swiftUIText(_ string: String, baseColor: Color, enabled: Bool) -> AttributedString {
        var attributed = AttributedString(string)
        attributed.foregroundColor = baseColor
        guard enabled else { return attributed }
        let mutable = NSMutableAttributedString(attributedString: NSAttributedString(attributed))
        for range in nsRanges(in: string) {
            mutable.addAttribute(.foregroundColor, value: UIColor.red, range: range)
        }
        return AttributedString(mutable)
    }
}
#endif
