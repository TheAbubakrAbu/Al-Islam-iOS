import SwiftUI

// The article design kit (Abu, 2026-09-29: "add pretty designs all over the place for how-to guides,
// pillars, miracles, prophecies etc so it's not just a blob of text ... big text, fancy design showing
// sahih, da'if").
//
// The Pillars & Beliefs pages, the How-to guides and the signs libraries were built almost entirely
// from one element, a paragraph of body text, with `ScriptureQuote` as the only card. These are the
// other shapes a page needs: a lead that says what the page is in one breath, numbered steps that read
// as steps, bullets with a mark, a closing card, callouts, term cards with the Arabic set large, stat
// tiles, a chain diagram for an isnad, a checklist, a side-by-side comparison, and the scale of hadith
// grades.
//
// Rules every piece keeps:
//   * plain shapes only (no glass, no UIKit): an article carries dozens of them, and the WATCH compiles
//     this file along with every article file that uses it;
//   * the accent and the Arabic faces come from `AppearanceEnvironment`, never from observing
//     `Settings`, the same reason `ScriptureQuoteBody` reads them there;
//   * the words stay in the call site as a plain string literal, so the Ask AI corpus
//     (Scripts/build_islam_corpus.py) reads a step or a lead exactly as it read the `Text` it replaced.

extension String {
    /// Kit text as drawn: a translated page's written-out digits follow the locale (`localizedDigits`),
    /// while an English article keeps its own ("Quran 2:255"). DISPLAY only.
    var articleDisplayDigits: String { isMostlyArabicScript ? localizedDigits : self }
}

// MARK: - Shared ground

/// The card ground every piece here shares with `ScriptureQuoteBody`: the accent falling away corner to
/// corner and a hairline in the same colour. `strength` scales the wash (the lead is the loudest card on
/// a page, a callout the quietest).
struct ArticleCardGround: View {
    let accent: Color
    var strength: Double = 1
    var radius: CGFloat = 16

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        shape
            .fill(
                LinearGradient(colors: [accent.opacity(0.16 * strength), accent.opacity(0.04 * strength)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(shape.strokeBorder(accent.opacity(0.2), lineWidth: 1))
    }
}

/// The small tracked capitals over a card ("IN SHORT", "WHY IT IS STRIKING").
private struct ArticleEyebrow: View {
    let text: String
    let systemImage: String
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
            Text(text.articleDisplayDigits)
                .font(.caption.weight(.bold))
                .tracking(AppLanguage.letterSpacing(1.1))
        }
        .foregroundColor(accent)
        .accessibilityElement(children: .combine)
    }
}

/// The digits or glyph in a filled accent tile, the `AccentIconChip` grammar with text inside.
private struct ArticleBadge: View {
    let text: String
    let accent: Color
    var size: CGFloat = 28

    var body: some View {
        Text(text)
            .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundColor(.white)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .fill(LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.7)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
            )
    }
}

extension View {
    /// A card that IS its List row: no row ground behind it, edge to edge with the section cards above
    /// and below, instead of a card framed inside a white row. No separator either: between two
    /// stacked cards (the Dhikr screen's callouts and closing, 2026-10-03) it drew a hairline across
    /// the gap that belonged to neither. iOS only: on the watch a row background replaces the native
    /// rounded cells.
    func articleCardRow() -> some View {
        #if os(iOS)
        self
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
            .listRowSeparator(.hidden)
        #else
        self
        #endif
    }

    /// `articleCardRow()` for a row that is a card only for some of its data (an article's blocks:
    /// the lead is a card, a paragraph is not). One chain with the values chosen inside it, never
    /// `if isCard { row.articleCardRow() } else { row }`: that branch would make the row one the
    /// List has to build to count (see `OneRow`).
    func articleCardRow(when isCard: Bool) -> some View {
        modifier(ArticleCardRowWhen(isCard: isCard))
    }
}

/// See `articleCardRow(when:)`.
private struct ArticleCardRowWhen: ViewModifier {
    @Environment(\.appearance) private var appearance
    @Environment(\.skyPageFill) private var skyPageFill

    let isCard: Bool

    func body(content: Content) -> some View {
        #if os(iOS)
        content
            // Not a card: what the List-wide `themedListRowBackground()` gives a row. A row's own
            // background wins over the List-wide one, so a bare nil would wipe the theme's.
            .listRowBackground(isCard ? Color.clear : (skyPageFill ? SkyPageFill.rowColor : appearance.themeRowBackground))
            .listRowInsets(isCard ? EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0) : nil)
            .listRowSeparator(isCard ? .hidden : .automatic)
        #else
        content
        #endif
    }
}

// MARK: - Paragraph

/// A paragraph of article prose the reader can drag-select (Abu, 2026-10-19: "make it where I can select
/// text in list for pillars and beliefs, how to guides, miracles of quran, etc"). The `Text(verbatim:)`
/// and `Text(articleMarkdown:)` rows every article page is built from, and the words inside the kit's
/// cards, all draw through this. On iOS it is a read-only text view (`SelectableAttributedProse`,
/// Helpers/UI/SelectableText.swift), so any run of a passage can be highlighted and copied rather than
/// the whole-block "Copy" that is all the List's `.textSelection` can offer. On the watch it is the
/// `Text` it always was.
///
/// The words stay in the call site as the same literal: the corpus builder reads
/// `ArticleParagraph(verbatim: "...")` and `ArticleParagraph(articleMarkdown: "...")` exactly as it read
/// the `Text` forms (Scripts/build_islam_corpus.py, TEXT_RE). Markdown prose keeps its **bold** terms.
/// Islam Settings' Highlight Allah (`Text.islamHighlighted`) is applied exactly where it was before: the
/// kit's cards drew their verbatim text through `Text.islamText` and still do (`highlightsAllah`); a
/// page's plain paragraph was a bare `Text(verbatim:)` and stays unpainted.
struct ArticleParagraph: View {
    @Environment(\.appearance) private var appearance

    let text: String
    let markdown: Bool
    var textStyle: Font.TextStyle = .body
    var weight: Font.Weight = .regular
    var secondary: Bool = false
    /// Verbatim text with the name of Allah painted when the setting is on (markdown never is).
    var highlightsAllah: Bool = false

    /// Plain prose, drawn as written.
    init(verbatim text: String, textStyle: Font.TextStyle = .body, weight: Font.Weight = .regular,
         secondary: Bool = false, highlightsAllah: Bool = false) {
        self.init(text, markdown: false, textStyle: textStyle, weight: weight, secondary: secondary,
                  highlightsAllah: highlightsAllah)
    }

    /// Prose with inline **bold** terms.
    init(articleMarkdown text: String, textStyle: Font.TextStyle = .body, weight: Font.Weight = .regular,
         secondary: Bool = false) {
        self.init(text, markdown: true, textStyle: textStyle, weight: weight, secondary: secondary)
    }

    /// The kit's own cards, which already know which form they hold; their verbatim text is highlighted.
    init(_ text: String, markdown: Bool, textStyle: Font.TextStyle = .body, weight: Font.Weight = .regular,
         secondary: Bool = false, highlightsAllah: Bool = true) {
        self.text = text
        self.markdown = markdown
        self.textStyle = textStyle
        self.weight = weight
        self.secondary = secondary
        self.highlightsAllah = highlightsAllah
    }

    var body: some View {
        #if os(iOS)
        // 4 pt reproduces the `Text` line pitch (measured 2026-10-19 on the Shahadah page: SwiftUI
        // sets body at 24.0 pt a line and the title3 lead at 28.0 pt; the text view's own line height
        // is 20.3 / 23.9, so the same 4 pt lands within 0.3 pt of both and page heights do not move).
        // The ayahs and hadiths the paragraph cites open in their tabs (`ScriptureCitations`): a
        // tap opens one, a long press offers its link too. A paragraph that cites nothing is drawn
        // as it always was, with no link handling at all.
        let base = attributed
        let linked = ScriptureCitations.linked(base, accent: appearance.accent)
        SelectableAttributedProse(
            attributed: linked ?? base,
            textStyle: Self.uiTextStyle(textStyle),
            weight: Self.uiWeight(weight),
            secondary: secondary,
            lineSpacing: 4,
            onLink: linked == nil ? nil : { url in ScriptureCitations.open(url) },
            linkMenu: linked == nil ? nil : { url in ScriptureCitations.menu(for: url) }
        )
        #else
        Group {
            if markdown {
                Text(articleMarkdown: shown)
            } else if highlightsAllah {
                Text.islamText(shown, highlightAllah: appearance.highlightAllahIslam)
            } else {
                Text(verbatim: shown)
            }
        }
        .font(Font.system(textStyle).weight(weight))
        .foregroundColor(secondary ? .secondary : .primary)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        #endif
    }

    private var shown: String { text.articleDisplayDigits }

    #if os(iOS)
    private var attributed: AttributedString {
        let drawn = shown
        if markdown { return ArticleMarkdownCache.attributed(drawn) }
        if highlightsAllah,
           let painted = Text.islamHighlighted(drawn, highlightAllah: appearance.highlightAllahIslam) {
            return painted
        }
        return AttributedString(drawn)
    }

    private static func uiTextStyle(_ style: Font.TextStyle) -> UIFont.TextStyle {
        switch style {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
    }

    private static func uiWeight(_ weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
    #endif
}

// MARK: - Arabic

/// A passage of Arabic that is neither an ayah nor a narration: the words of the adhan and the iqamah,
/// the takbir, the shahadah. Set as a narration's Arabic is in a `ScriptureQuote` (the Islam tab's face,
/// the accent, trailing, the name of Allah painted when that is on), so every Arabic an article shows
/// reads as one thing (Abu, 2026-10-26: "Arabic text like that maybe should be written the same way as
/// Quran and Hadith with the different font and size and color and everything"). Not the mushaf face:
/// these words are not Quran. The corpus builder reads it as prose (`TEXT_RE` in
/// Scripts/build_islam_corpus.py), as it read the plain `Text` rows these replaced.
struct ArticleArabic: View {
    @Environment(\.appearance) private var appearance

    let text: String

    init(verbatim text: String) { self.text = text }

    var body: some View {
        Text.islamArabic(text.decomposingAlefMadda, highlightAllah: appearance.highlightAllahIslam)
            .font(appearance.islamArabicFont(base: 24, relativeTo: .title2))
            .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
            .lineSpacing(6)
            .foregroundColor(appearance.accent)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.vertical, 2)
    }
}

// MARK: - Lead

/// The page's opening card: its "In short:" sentence set large, under a small IN SHORT label. Replaces
/// the SUMMARY section's plain paragraph on every article, so each page opens on the one thing to
/// remember before the detail starts. "In short:" is lifted off the front for the eye only; the
/// string itself (and so the corpus and the copy menu) keeps it.
struct ArticleLead: View {
    @Environment(\.appearance) private var appearance

    let text: String
    var markdown: Bool = false
    /// The small label over the lead. The Islam tab is not translated yet, so its pages keep the English
    /// literal; a translated screen (the hadith history) passes its own `String(localized: "IN SHORT")`.
    var eyebrow: String = "IN SHORT"

    init(_ text: String, eyebrow: String = "IN SHORT") {
        self.text = text
        self.eyebrow = eyebrow
    }

    /// A lead with inline **bold** terms, the way some SUMMARY paragraphs were written.
    init(articleMarkdown text: String) {
        self.text = text
        self.markdown = true
    }

    private var display: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        for prefix in ["In short:", "In short,"] where trimmed.hasPrefix(prefix) {
            let rest = trimmed.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
            guard let first = rest.first else { return trimmed }
            return first.uppercased() + rest.dropFirst()
        }
        return trimmed
    }

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 8) {
            ArticleEyebrow(text: eyebrow, systemImage: "sparkle", accent: accent)

            // A long lead at title size filled the screen; past ~240 characters it reads at body size.
            ArticleParagraph(display, markdown: markdown,
                             textStyle: display.count > 240 ? .body : .title3, weight: .medium)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ArticleCardGround(accent: accent, strength: 1.25, radius: 18)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 58, weight: .bold))
                        .foregroundColor(accent.opacity(0.07))
                        .offset(x: 8, y: 12),
                    alignment: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
        .padding(.vertical, 3)
        .articleCardRow()
    }
}

// MARK: - Steps and bullets

/// One numbered step of a how-to: the number in an accent tile, the step beside it. Takes the step as
/// the page always wrote it ("3. Wash both **hands** ..."), so the number stays in the words the corpus
/// reads and only the eye sees it lifted into the tile. A string with no leading number draws as a
/// bullet.
struct ArticleStep: View {
    @Environment(\.appearance) private var appearance

    let source: String
    let markdown: Bool

    /// A step with inline **bold** terms.
    init(_ markdown: String) {
        self.source = markdown
        self.markdown = true
    }

    /// A plain step, drawn verbatim.
    init(verbatim: String) {
        self.source = verbatim
        self.markdown = false
    }

    /// "12. Rest of it" -> ("12", "Rest of it").
    static func split(_ text: String) -> (number: String?, body: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        var digits = ""
        var index = trimmed.startIndex
        while index < trimmed.endIndex, trimmed[index].isNumber, digits.count < 3 {
            digits.append(trimmed[index])
            index = trimmed.index(after: index)
        }
        guard !digits.isEmpty, index < trimmed.endIndex, trimmed[index] == "." || trimmed[index] == ")" else {
            return (nil, trimmed)
        }
        let rest = trimmed[trimmed.index(after: index)...].trimmingCharacters(in: .whitespaces)
        return (digits, rest)
    }

    var body: some View {
        let parts = Self.split(source)
        if let number = parts.number {
            HStack(alignment: .top, spacing: 12) {
                ArticleBadge(text: source.isMostlyArabicScript ? number.localizedDigits : number,
                             accent: appearance.accent)
                    .padding(.top, 1)
                    .accessibilityLabel("Step \(number)")

                ArticleProse(text: parts.body, markdown: markdown)
            }
            .padding(.vertical, 3)
        } else {
            ArticleBullet(source: source, markdown: markdown)
        }
    }
}

/// One bullet: an accent mark in place of the "•" the pages typed, the text beside it.
struct ArticleBullet: View {
    @Environment(\.appearance) private var appearance

    let source: String
    let markdown: Bool

    init(_ markdown: String) {
        self.init(source: markdown, markdown: true)
    }

    init(verbatim: String) {
        self.init(source: verbatim, markdown: false)
    }

    fileprivate init(source: String, markdown: Bool) {
        self.source = source
        self.markdown = markdown
    }

    private var bodyText: String {
        var trimmed = source.trimmingCharacters(in: .whitespaces)
        for mark in ["•", "- ", "–"] where trimmed.hasPrefix(mark) {
            trimmed = String(trimmed.dropFirst(mark.count)).trimmingCharacters(in: .whitespaces)
            break
        }
        return trimmed
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\u{25C6}")
                .font(.caption2)
                .foregroundColor(appearance.accent)
                .accessibilityHidden(true)

            ArticleProse(text: bodyText, markdown: markdown)
        }
        .padding(.vertical, 1)
    }
}

/// Body prose, markdown or verbatim, with Islam Settings' Highlight Allah applied to the verbatim form
/// (`Text.islamText`), the way the rest of an article's text reads.
private struct ArticleProse: View {
    @Environment(\.appearance) private var appearance

    let text: String
    let markdown: Bool

    var body: some View {
        ArticleParagraph(text, markdown: markdown)
    }
}

// MARK: - Closing and callouts

/// The IN SUMMARY paragraph as the page's closing card: a seal, and the sentence set a little heavier
/// than the prose above it.
struct ArticleClosing: View {
    @Environment(\.appearance) private var appearance

    let text: String
    var markdown: Bool = false

    init(_ text: String) {
        self.text = text
    }

    init(articleMarkdown text: String) {
        self.text = text
        self.markdown = true
    }

    var body: some View {
        let accent = appearance.accent
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundColor(accent)
                .accessibilityHidden(true)

            ArticleParagraph(text, markdown: markdown, weight: .medium)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(ArticleCardGround(accent: accent, strength: 0.8))
        .padding(.vertical, 3)
    }
}

/// A point the page wants remembered, set apart: an icon tile, a title, and the text under it. Used for
/// "Why it is striking" on the prophecies, the key idea of a section, a caution.
struct ArticleCallout: View {
    @Environment(\.appearance) private var appearance

    let text: String
    let title: String
    let systemImage: String
    /// Several paragraphs of one callout, drawn as one card (the signs libraries' "WHY IT IS STRIKING"
    /// sections are one to three paragraphs). `text` is the first of them.
    var more: [String] = []
    var markdown: Bool = true
    /// Each paragraph behind the bullet mark (`init(bullets:)`): a card of short quoted lines.
    var bulleted: Bool = false

    init(_ text: String, title: String, systemImage: String = "lightbulb.fill") {
        self.text = text
        self.title = title
        self.systemImage = systemImage
    }

    init(paragraphs: [String], title: String, systemImage: String, markdown: Bool = false) {
        self.text = paragraphs.first ?? ""
        self.more = Array(paragraphs.dropFirst())
        self.title = title
        self.systemImage = systemImage
        self.markdown = markdown
    }

    /// Short lines under one title, each with the bullet mark: the "Quranic Reminders" and
    /// "Prophetic Guidance" cards of the Dhikr and Dua screens (2026-10-03), one ayah or hadith a line.
    init(bullets: [String], title: String, systemImage: String, markdown: Bool = false) {
        self.init(paragraphs: bullets, title: title, systemImage: systemImage, markdown: markdown)
        self.bulleted = true
    }

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                AccentIconChip(systemImage: systemImage, size: 26)

                Text(title.articleDisplayDigits)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(accent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(Array(([text] + more).enumerated()), id: \.offset) { _, paragraph in
                if bulleted {
                    ArticleBullet(source: paragraph, markdown: markdown)
                } else {
                    ArticleProse(text: paragraph, markdown: markdown)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArticleCardGround(accent: accent, strength: 0.7))
        .padding(.vertical, 3)
    }
}

// MARK: - Etymology

/// Where a word comes from, the way the Dhikr and Dua screens open their ETYMOLOGY section
/// (2026-10-03): the word in English and set large in Arabic, its three root letters in a chip, the
/// root's core meaning, and what the word has come to mean.
struct ArticleEtymologyCard: View {
    @Environment(\.appearance) private var appearance

    let word: String
    let arabic: String
    /// The root letters spaced apart ("ذ ك ر") and their Latin spelling ("dh-k-r").
    let root: String
    let rootLatin: String
    /// The root's core meaning ("to remember, to mention, to be mindful").
    let coreMeaning: String
    let text: String

    init(_ word: String, arabic: String, root: String, rootLatin: String, coreMeaning: String, text: String) {
        self.word = word
        self.arabic = arabic
        self.root = root
        self.rootLatin = rootLatin
        self.coreMeaning = coreMeaning
        self.text = text
    }

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Text(word)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                Text.islamArabic(arabic, highlightAllah: appearance.highlightAllahIslam)
                    .font(appearance.islamArabicFont(base: 34, relativeTo: .title))
                    .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            HStack(spacing: 8) {
                Text("ROOT")
                    .font(.caption2.weight(.bold))
                    .tracking(AppLanguage.letterSpacing(1.1))
                    .foregroundColor(accent)

                Text(root)
                    .font(appearance.islamArabicFont(base: 18, relativeTo: .subheadline))
                    .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                    .foregroundColor(.primary)

                Text(rootLatin)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(Capsule().fill(accent.opacity(0.12)))
            .accessibilityElement(children: .combine)

            Text(coreMeaning)
                .font(.headline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            ArticleParagraph(verbatim: text, textStyle: .subheadline, secondary: true, highlightsAllah: true)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ArticleCardGround(accent: accent, strength: 1.1, radius: 18)
                .overlay(
                    Image(systemName: "character.book.closed.fill")
                        .font(.system(size: 58, weight: .bold))
                        .foregroundColor(accent.opacity(0.06))
                        .offset(x: 8, y: 12),
                    alignment: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
        .padding(.vertical, 3)
        .articleCardRow()
    }
}

// MARK: - Terms

/// A term with its Arabic set large, the way a teacher writes a word on the board before explaining it:
/// the English name, the Arabic, and the meaning under them.
struct ArticleTermCard: View {
    @Environment(\.appearance) private var appearance

    let term: String
    let arabic: String
    let meaning: String

    init(_ term: String, arabic: String, meaning: String) {
        self.term = term
        self.arabic = arabic
        self.meaning = meaning
    }

    /// A word sits beside its term on one line; a phrase (three words or more, a dua's clause) takes
    /// its own line under the term, where it can wrap, instead of shrinking and then truncating.
    private var isPhrase: Bool {
        arabic.split(whereSeparator: \.isWhitespace).count > 2
    }

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 6) {
            if isPhrase {
                Text(term.articleDisplayDigits)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text.islamArabic(arabic, highlightAllah: appearance.highlightAllahIslam)
                    .font(appearance.islamArabicFont(base: 26, relativeTo: .title2))
                    .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                    .foregroundColor(accent)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, 2)
            } else {
                HStack(alignment: .center, spacing: 12) {
                    Text(term.articleDisplayDigits)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    Text.islamArabic(arabic, highlightAllah: appearance.highlightAllahIslam)
                        .font(appearance.islamArabicFont(base: 30, relativeTo: .title))
                        .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                        .foregroundColor(accent)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }

            ArticleParagraph(articleMarkdown: meaning, textStyle: .subheadline, secondary: true)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArticleCardGround(accent: accent, strength: 0.6))
        .padding(.vertical, 2)
    }
}

// MARK: - Stats

struct ArticleStat: Hashable {
    let value: String
    let label: String

    init(_ value: String, _ label: String) {
        self.value = value
        self.label = label
    }
}

/// Numbers worth seeing at a glance, as tiles: the figure large in the accent, what it counts under it.
struct ArticleStatGrid: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let stats: [ArticleStat]

    init(_ stats: [ArticleStat]) {
        self.stats = stats
    }

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : (stats.count == 3 ? 3 : 2)
        return Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: count)
    }

    var body: some View {
        let accent = appearance.accent
        // Not lazy (`SummaryTileGrid`): a lazy grid in a List row can answer a different height on
        // each self-sizing pass, which iOS 26 traps on. `.top`: the columns' own alignment.
        SummaryTileGrid(columns: columns.count, spacing: 8, alignment: .top) {
            ForEach(stats, id: \.self) { stat in
                VStack(alignment: .leading, spacing: 3) {
                    Text(stat.value)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Text(stat.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 11)
                .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                .background(ArticleCardGround(accent: accent, strength: 0.55, radius: 14))
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Chains

struct ArticleChainLink: Hashable {
    let name: String
    let detail: String

    init(_ name: String, _ detail: String = "") {
        self.name = name
        self.detail = detail
    }
}

/// A chain drawn as a chain: one node per link, joined by a rail, top to bottom. An isnad reads from
/// the collector down to the Prophet (peace and blessings be upon him), so the last node carries the
/// seal.
struct ArticleChainDiagram: View {
    @Environment(\.appearance) private var appearance

    let links: [ArticleChainLink]
    var caption: String?

    init(_ links: [ArticleChainLink], caption: String? = nil) {
        self.links = links
        self.caption = caption
    }

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 0) {
            if let caption {
                Text(caption)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(Array(links.enumerated()), id: \.offset) { index, link in
                let last = index == links.count - 1
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(last ? accent : accent.opacity(0.18))
                                .frame(width: 22, height: 22)
                            if last {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Circle()
                                    .fill(accent)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        if !last {
                            Rectangle()
                                .fill(accent.opacity(0.35))
                                .frame(width: 2)
                                .frame(minHeight: 18, maxHeight: .infinity)
                        }
                    }
                    .frame(width: 22)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(link.name)
                            .font(.subheadline.weight(last ? .bold : .semibold))
                            .foregroundColor(last ? accent : .primary)
                            .fixedSize(horizontal: false, vertical: true)

                        if !link.detail.isEmpty {
                            Text(link.detail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, 1)
                    .padding(.bottom, last ? 0 : 10)

                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArticleCardGround(accent: accent, strength: 0.5))
        .padding(.vertical, 3)
    }
}

// MARK: - Checklist

/// A short list set as one card with a heading: the questions a critic has to answer, the conditions
/// of a sound hadith, the things that break wudhu. Each line leads with the card's own mark.
struct ArticleChecklist: View {
    @Environment(\.appearance) private var appearance

    let items: [String]
    let title: String
    let systemImage: String

    init(_ items: [String], title: String, systemImage: String = "checkmark.circle.fill") {
        self.items = items
        self.title = title
        self.systemImage = systemImage
    }

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 9) {
            Text(title.articleDisplayDigits)
                .font(.subheadline.weight(.bold))
                .foregroundColor(accent)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.subheadline)
                        .foregroundColor(accent)
                        .accessibilityHidden(true)

                    ArticleParagraph(articleMarkdown: item)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArticleCardGround(accent: accent, strength: 0.6))
        .padding(.vertical, 3)
    }
}

// MARK: - Side by side

/// Two things set side by side: two spellings of one word in two riwayat, the Bible's word beside the
/// Quran's. Each side has a label, an optional large Arabic line, and a caption.
struct ArticleVersus: View {
    struct Side: Hashable {
        let label: String
        var arabic: String? = nil
        let caption: String

        init(_ label: String, arabic: String? = nil, caption: String) {
            self.label = label
            self.arabic = arabic
            self.caption = caption
        }
    }

    @Environment(\.appearance) private var appearance

    let left: Side
    let right: Side
    /// The Arabic is Quran text (set in the Quran face) rather than a term (the Islam face).
    var quranic: Bool = true

    init(_ left: Side, _ right: Side, quranic: Bool = true) {
        self.left = left
        self.right = right
        self.quranic = quranic
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            side(left, emphasized: false)
            side(right, emphasized: true)
        }
        .padding(.vertical, 4)
    }

    private func side(_ side: Side, emphasized: Bool) -> some View {
        let accent = appearance.accent
        return VStack(alignment: .leading, spacing: 6) {
            Text(side.label.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(AppLanguage.letterSpacing(1))
                .foregroundColor(emphasized ? accent : .secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let arabic = side.arabic {
                Text(arabic.decomposingAlefMadda)
                    .font(quranic
                          ? appearance.quranArabicFont(size: 28, relativeTo: .title)
                          : appearance.islamArabicFont(base: 28, relativeTo: .title))
                    .arabicFontDesign(custom: quranic ? appearance.quranUsesCustomArabicFace
                                                      : appearance.islamUsesCustomArabicFace)
                    .foregroundColor(emphasized ? accent : .primary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            ArticleParagraph(articleMarkdown: side.caption, textStyle: .caption, secondary: true)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 11)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(ArticleCardGround(accent: accent, strength: emphasized ? 0.9 : 0.35, radius: 14))
    }
}

// MARK: - The grades of hadith

/// One rung of the scale of authenticity. The table below is the ONE copy of these definitions: the
/// ladder draws it, and the corpus builder reads the same literals for the Ask AI text.
struct HadithGrade: Identifiable, Hashable {
    let name: String
    let arabic: String
    let english: String
    let definition: String
    let verdict: String
    /// 0 is the strongest; the colour runs green to red down the ladder.
    let rank: Int

    var id: String { name }

    var color: Color {
        switch rank {
        case 0: return .green
        case 1: return .teal
        case 2: return .orange
        default: return .red
        }
    }

    static let all: [HadithGrade] = [
        HadithGrade(name: "Saheeh", arabic: "صَحِيح", english: "Authentic",
                    definition: "An unbroken chain of upright narrators with precise memory from beginning to end, with no irregularity against stronger narrators and no hidden defect.",
                    verdict: "Accepted: a proof in belief and in law", rank: 0),
        HadithGrade(name: "Hasan", arabic: "حَسَن", english: "Good",
                    definition: "The same conditions, except that a narrator's memory is a little lighter than the saheeh narrator's. Still upright, still connected, still sound.",
                    verdict: "Accepted: acted upon like the saheeh", rank: 1),
        HadithGrade(name: "Da‘eef", arabic: "ضَعِيف", english: "Weak",
                    definition: "Missing one or more of those conditions: a break in the chain, an unknown narrator, a weak memory, or a narrator whose uprightness is in question.",
                    verdict: "Not established as his words", rank: 2),
        HadithGrade(name: "Mawdoo‘", arabic: "مَوضُوع", english: "Fabricated",
                    definition: "A report invented and attributed to the Prophet (peace and blessings be upon him), usually exposed by a known liar in its chain or by its matn.",
                    verdict: "Rejected: never narrated except to expose it", rank: 3),
    ]

    /// Counted by how many carried it rather than by how strong they were: the second axis every
    /// grading also has, from the fewest to the most (`HadithCountLadder` draws it; the corpus
    /// builder reads these literals, three strings a row).
    static let byNumber: [(name: String, arabic: String, meaning: String)] = [
        ("Ghareeb", "غَرِيب", "One narrator at its narrowest level"),
        ("Azeez", "عَزِيز", "Two narrators at its narrowest level"),
        ("Mashhoor", "مَشهُور", "Three or more at its narrowest level"),
        ("Mutawaatir", "مُتَوَاتِر", "Too many, at every level, to agree on a lie"),
    ]

    /// The count each of those is named by, in `byNumber`'s order: what its medallion shows.
    static let byNumberMarks = ["1", "2", "3+", "∞"]
}

/// The scale of hadith grades, strongest at the top: each rung's colour, its Arabic set large, what it
/// means and what it is worth. The second axis, how many carried it, is its own card
/// (`HadithCountLadder`).
struct HadithGradeLadder: View {
    @Environment(\.appearance) private var appearance

    init() {}

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 10) {
            ArticleEyebrow(text: "THE SCALE OF AUTHENTICITY", systemImage: "checkmark.shield.fill", accent: accent)

            HStack(alignment: .top, spacing: 10) {
                // The rail: the scale itself, green at the top to red at the foot.
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(LinearGradient(colors: HadithGrade.all.map(\.color),
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 6)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(HadithGrade.all) { grade in
                        rung(grade)
                    }
                }
            }

        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArticleCardGround(accent: accent, strength: 0.5))
        .padding(.vertical, 3)
    }

    private func rung(_ grade: HadithGrade) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(grade.name)
                        .font(.title3.weight(.bold))
                        .foregroundColor(grade.color)
                    Text(grade.english.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(AppLanguage.letterSpacing(1))
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 8)

                Text.islamArabic(grade.arabic, highlightAllah: false)
                    .font(appearance.islamArabicFont(base: 34, relativeTo: .largeTitle))
                    .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                    .foregroundColor(grade.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            ArticleParagraph(verbatim: grade.definition, textStyle: .subheadline)

            Text(grade.verdict)
                .font(.caption.weight(.semibold))
                .foregroundColor(grade.color)
                .padding(.vertical, 3)
                .padding(.horizontal, 8)
                .background(Capsule().fill(grade.color.opacity(0.14)))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(grade.color.opacity(0.07))
        )
        .accessibilityElement(children: .combine)
    }
}

/// The second axis of every grading: a hadith named by how many carried it, counted where its chain
/// is narrowest (Abu, 2026-11-22, of a card that set the four out as numbered rows: "include those
/// things for hadith science"). One row a class, its count in a medallion, its Arabic at the far
/// edge, from one narrator up to mass transmission. It was four lines of small text at the foot of
/// the scale of authenticity until then, where "ahad" was easy to read as a grade of weakness.
struct HadithCountLadder: View {
    @Environment(\.appearance) private var appearance

    init() {}

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 10) {
            ArticleEyebrow(text: "COUNTED AT THE NARROWEST POINT", systemImage: "person.3.fill", accent: accent)

            VStack(spacing: 6) {
                ForEach(Array(HadithGrade.byNumber.enumerated()), id: \.element.name) { index, item in
                    row(item, mark: HadithGrade.byNumberMarks.indices.contains(index) ? HadithGrade.byNumberMarks[index] : "",
                        accent: accent)
                }
            }

            ArticleParagraph(verbatim: "Everything short of mutawaatir is called aahaad. Aahaad is a count, not a weakness: most of the Sunnah is aahaad and saheeh, and it is binding.",
                             textStyle: .caption, secondary: true)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ArticleCardGround(accent: accent, strength: 0.5))
        .padding(.vertical, 3)
    }

    private func row(_ item: (name: String, arabic: String, meaning: String), mark: String, accent: Color) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(mark)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .monospacedDigit()
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 34, height: 34)
                .background(Circle().fill(accent.opacity(0.12)))
                .overlay(Circle().strokeBorder(accent.opacity(0.5), lineWidth: 1))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(item.meaning)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Text.islamArabic(item.arabic, highlightAllah: false)
                .font(appearance.islamArabicFont(base: 24, relativeTo: .title2))
                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.primary.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(accent.opacity(0.18), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Resource hero

/// One figure on a resource hero: the value set large over its label ("17" over "chapters").
struct ResourceHeroStat: Hashable {
    let value: String
    let label: String

    init(_ value: String, _ label: String) {
        self.value = value
        self.label = label
    }
}

/// The card every Islam resource opens on (Abu, 2026-10-02: Proving Islam's header "looks beautiful,
/// can we add that to every islamic resource/tool"). Proving Islam's opening card, generalised: tracked
/// capitals with the resource's symbol, one large line saying what the screen is for, the sentence under
/// it, and up to three figures. The accent wash falls away corner to corner, the symbol sits large and
/// faint in the bottom corner, and a hairline frames it.
///
/// Set small since 2026-11-25 (Abu: "the whole top section be smaller but still just as informative"):
/// the card had grown past a whole screen on most resources, with the tool or the index under it out
/// of sight. Every word and figure is still there: the headline is a size down, the sentence is the
/// footnote size, the figures are one line of text instead of three tiles (`ResourceHeroStats`), and the
/// card's own padding and gaps are tighter.
///
/// A resource puts it in its List through `ResourceHeroSection`, which draws nothing on the watch: the
/// watch compiles every resource that carries one, and a card this size would be the whole screen there.
struct ResourceHero<Footer: View>: View {
    @Environment(\.appearance) private var appearance
    /// An English article page (`englishArticle()`): outside English, the card opens by saying so.
    @Environment(\.isEnglishArticle) private var isEnglishArticle

    let eyebrow: String
    let systemImage: String
    let headline: String
    /// The headline's Arabic name, set large in the accent beside it (or under it when the two do not
    /// fit one line): a hadith book's title, a lesson's term.
    var arabic: String?
    /// Where the headline comes from, when it is a quotation ("Quran 40:60"): set under it, small.
    var source: String?
    /// The sentence under the headline; empty draws nothing (a hero whose words sit in its footer).
    let message: String
    var stats: [ResourceHeroStat] = []
    /// Anything the resource adds under the figures: a progress bar, a diagram that opens articles.
    let footer: Footer

    init(eyebrow: String, systemImage: String, headline: String, arabic: String? = nil, source: String? = nil,
         message: String, stats: [ResourceHeroStat] = [], @ViewBuilder footer: () -> Footer) {
        self.eyebrow = eyebrow
        self.systemImage = systemImage
        self.headline = headline
        self.arabic = arabic
        self.source = source
        self.message = message
        self.stats = stats
        self.footer = footer()
    }

    private var headlineText: some View {
        Text(headline)
            .font(.title3.weight(.bold))
            .foregroundColor(.primary)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The headline and its Arabic side by side while both fit; the Arabic on its own line, trailing,
    /// when not, and always on the watch and before iOS 16 (`ViewThatFits` is iOS 16+).
    @ViewBuilder
    private func headlineWithArabic(_ arabic: String, accent: Color) -> some View {
        let stacked = VStack(alignment: .leading, spacing: 4) {
            headlineText
            arabicText(arabic, accent: accent)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        #if os(iOS)
        if #available(iOS 16.0, *) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 12) {
                    headlineText.fixedSize()
                    Spacer(minLength: 8)
                    arabicText(arabic, accent: accent).fixedSize()
                }
                stacked
            }
        } else {
            stacked
        }
        #else
        stacked
        #endif
    }

    @ViewBuilder
    private func arabicText(_ arabic: String, accent: Color) -> some View {
        Text.islamArabic(arabic, highlightAllah: appearance.highlightAllahIslam)
            .font(appearance.islamArabicFont(base: 23, relativeTo: .title3))
            .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
            .foregroundColor(accent)
            .multilineTextAlignment(.trailing)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 9) {
            if isEnglishArticle && EnglishOnly.isShown {
                EnglishOnlyNotice()
            }

            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(eyebrow.articleDisplayDigits)
                    .tracking(AppLanguage.letterSpacing(1.3))
                    .lineLimit(2)
                    // A single word wider than the card cannot wrap: at the largest accessibility
                    // sizes "THE FOUNDATIONS" read "THE FOUNDATI..." (2026-10-04). It shrinks first.
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.caption.weight(.bold))
            .foregroundColor(accent)

            VStack(alignment: .leading, spacing: 3) {
                if let arabic, !arabic.isEmpty {
                    headlineWithArabic(arabic, accent: accent)
                } else {
                    // Often an ayah's English translation (scripture stays English): it keeps the left
                    // edge and its own direction even on a translated page.
                    headlineText
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .leftToRightContent(!headline.isMostlyArabicScript)
                }

                if let source {
                    // A verse names its surah: "Quran Ar-Ra'd 13:28" (`QuranSurahNames.naming`).
                    Text(QuranSurahNames.naming(source).articleDisplayDigits)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(accent)
                }
            }

            if !message.isEmpty {
                Text(message.articleDisplayDigits)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !stats.isEmpty {
                ResourceHeroStats(stats)
            }

            footer
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [accent.opacity(0.24), accent.opacity(0.05)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    Image(systemName: systemImage)
                        .font(.system(size: 88, weight: .bold))
                        .foregroundColor(accent.opacity(0.07))
                        .offset(x: 20, y: 20),
                    alignment: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(accent.opacity(0.22), lineWidth: 1))
        )
        // One element when it is all words; a container when the footer holds buttons (the pillars,
        // the How-to steps), which VoiceOver must still reach one by one.
        .accessibilityElement(children: Footer.self == EmptyView.self ? .combine : .contain)
    }
}

// MARK: - English only

/// What still reads English in every interface language: the Islam tab's ARTICLES, which are Faith &
/// Proofs (the pillars and beliefs, How-To Guides, the miracles, the prophecies, the Sunnahs, Proving
/// Islam), the Hadith tab's pages about the Sunnah and its sciences, and the riwayat page
/// (Docs/Engineering/Localization Guide.md). Abu, 2026-11-24: "For those that don't support other
/// languages ... say it only supports English clearly." So the tiles and rows that open them carry an
/// "English only" tag, and each page's opening card says it in a line of its own. Nothing is drawn in
/// English, where there is nothing to warn about.
enum EnglishOnly {
    static var isShown: Bool { AppLanguage.pinsArticlesEnglish }
}

/// "English only" as a small tinted capsule with a globe: beside a section title or a row's title, and
/// as "EN" in a grid tile's corner, where the words do not fit.
struct EnglishOnlyTag: View {
    @Environment(\.appearance) private var appearance
    var compact = false

    var body: some View {
        HStack(spacing: 3) {
            if compact {
                // A tile's corner has room for the two letters alone (the globe ran into its icon).
                Text(verbatim: "EN")
            } else {
                Image(systemName: "globe")
                    .imageScale(.small)
                Text("English only")
            }
        }
        .font(.caption2.weight(.bold))
        .foregroundColor(appearance.accent)
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, compact ? 5 : 7)
        .padding(.vertical, 2)
        .background(Capsule().fill(appearance.accent.opacity(0.14)))
        .overlay(Capsule().strokeBorder(appearance.accent.opacity(0.3), lineWidth: 0.5))
        // The words, never "EN": a screen reader spells the corner tag out.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("English only"))
    }
}

/// The opening line of an English page's card, in the reader's own language and direction (the page
/// around it is pinned left to right for its English): a globe, "Available in English only", and why.
struct EnglishOnlyNotice: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "globe")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(appearance.accent)
                .frame(width: 30, height: 30)
                .background(Circle().fill(appearance.accent.opacity(0.16)))
            VStack(alignment: .leading, spacing: 2) {
                Text("Available in English only")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text("This page has not been translated yet, so it reads in English.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(appearance.accent.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(appearance.accent.opacity(0.25), lineWidth: 1))
        .environment(\.layoutDirection, AppLanguage.isRightToLeft ? .rightToLeft : .leftToRight)
        .accessibilityElement(children: .combine)
    }
}

/// A hero's figures as one line: each number in the accent, its label after it, a dot between them
/// ("36 chapters · 25 prophets named · 10 parts"). `ResourceHero`'s own line, and the one a hero's
/// footer draws when its figures belong below other lines (a hadith book's, under its compiler).
///
/// One line of text since 2026-11-25, where there were three tiles side by side: the tiles took as
/// much height as the sentence above them to say three numbers. It wraps like any sentence, so a long
/// label is never shrunk or cut, and nothing here is measured.
struct ResourceHeroStats: View {
    @Environment(\.appearance) private var appearance

    let stats: [ResourceHeroStat]

    init(_ stats: [ResourceHeroStat]) {
        self.stats = stats
    }

    var body: some View {
        line
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Simple Mode drops the figures: a hero is a welcome, not a dashboard (spec rule 8).
            .hiddenInSimple(.heroStats)
    }

    /// The figures joined into one `Text`, so the line breaks between figures the way a sentence
    /// breaks between words. A figure and its label are tied by a no-break space.
    private var line: Text {
        let accent = appearance.accent
        var text = Text(verbatim: "")
        for (index, stat) in stats.enumerated() {
            if index > 0 {
                text = text + Text(verbatim: "   \u{00B7}   ").font(.caption).foregroundColor(.secondary)
            }
            text = text
                + Text(verbatim: stat.value.localizedDigits)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(accent)
                + Text(verbatim: "\u{00A0}" + stat.label.articleDisplayDigits.replacingOccurrences(of: " ", with: "\u{00A0}"))
                    .font(.caption)
                    .foregroundColor(.secondary)
        }
        return text
    }
}

extension ResourceHero where Footer == EmptyView {
    init(eyebrow: String, systemImage: String, headline: String, arabic: String? = nil, source: String? = nil,
         message: String, stats: [ResourceHeroStat] = []) {
        self.init(eyebrow: eyebrow, systemImage: systemImage, headline: headline, arabic: arabic, source: source,
                  message: message, stats: stats) {
            EmptyView()
        }
    }
}

/// A resource's hero as the first section of its List: the card is its own row, edge to edge
/// (`articleCardRow`). Nothing on the watch (see `ResourceHero`).
struct ResourceHeroSection<Footer: View>: View {
    let hero: ResourceHero<Footer>

    init(_ hero: ResourceHero<Footer>) {
        self.hero = hero
    }

    var body: some View {
        #if os(iOS)
        Section {
            hero.articleCardRow()
        }
        #endif
    }
}

// MARK: - Video links

/// A video on YouTube as a row: a red play chip, the video's title, who made it, and the outward
/// arrow. Tapping opens it; holding offers to copy its link (Abu, 2026-11-09: "allow me to copy them
/// with context menu"). The row sits at the TOP of its page, right under the summary or the intro,
/// never at the foot (Abu, the same day: "put YouTube video links at the top of each thing").
///
/// The English articles keep an English caption; a translated page passes `translated: true` and the
/// caption follows the app's language (the "%@, on YouTube" and "YouTube" catalog keys).
struct ArticleVideoLink: View {
    let title: String
    let url: String
    /// Who made it, for the caption. Empty reads "YouTube" alone.
    var channel: String = "Arabic 101"
    var translated: Bool = false

    var body: some View {
        if let destination = URL(string: url) {
            Link(destination: destination) {
                HStack(spacing: 12) {
                    AccentIconChip(systemImage: "play.fill", tint: .red, size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        // Explicit greys: inside a Link the hierarchical styles take the link's tint.
                        caption
                            .font(.caption)
                            .foregroundColor(Self.secondaryInk)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Self.secondaryInk)
                }
                .padding(.vertical, 2)
            }
            #if os(iOS)
            .contextMenu {
                Text("Copy")
                    .foregroundStyle(.secondary)

                Button {
                    Settings.shared.hapticFeedback()
                    UIPasteboard.general.string = url
                } label: {
                    Label("Copy Link", systemImage: "doc.on.doc")
                }
            }
            #endif
        }
    }

    private var caption: Text {
        if channel.isEmpty {
            return translated ? Text("YouTube") : Text(verbatim: "YouTube")
        }
        return translated ? Text("\(channel), on YouTube") : Text(verbatim: "\(channel), on YouTube")
    }

    private static var secondaryInk: Color {
        #if os(iOS)
        Color(UIColor.secondaryLabel)
        #else
        Color.gray
        #endif
    }
}
