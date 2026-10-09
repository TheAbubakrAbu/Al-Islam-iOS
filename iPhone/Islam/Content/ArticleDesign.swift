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
            Text(text)
                .font(.caption.weight(.bold))
                .tracking(1.1)
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

    init(_ text: String) {
        self.text = text
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
            ArticleEyebrow(text: "IN SHORT", systemImage: "sparkle", accent: accent)

            Group {
                if markdown {
                    Text(articleMarkdown: display)
                } else {
                    Text.islamText(display, highlightAllah: appearance.highlightAllahIslam)
                }
            }
                // A long lead at title size filled the screen; past ~240 characters it reads at body size.
                .font(display.count > 240 ? .body.weight(.medium) : .title3.weight(.medium))
                .foregroundColor(.primary)
                .lineSpacing(2)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
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
                ArticleBadge(text: number, accent: appearance.accent)
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
        Group {
            if markdown {
                Text(articleMarkdown: text)
            } else {
                Text.islamText(text, highlightAllah: appearance.highlightAllahIslam)
            }
        }
        .font(.body)
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
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

            Group {
                if markdown {
                    Text(articleMarkdown: text)
                } else {
                    Text.islamText(text, highlightAllah: appearance.highlightAllahIslam)
                }
            }
                .font(.body.weight(.medium))
                .foregroundColor(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
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

                Text(title)
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
                    .tracking(1.1)
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

            Text.islamText(text, highlightAllah: appearance.highlightAllahIslam)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
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

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                Text(term)
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

            Text(articleMarkdown: meaning)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
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
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(accent)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: systemImage)
                        .font(.subheadline)
                        .foregroundColor(accent)
                        .accessibilityHidden(true)

                    Text(articleMarkdown: item)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                .tracking(1)
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

            Text(articleMarkdown: side.caption)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
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
        HadithGrade(name: "Sahih", arabic: "صَحِيح", english: "Authentic",
                    definition: "An unbroken chain of upright narrators with precise memory from beginning to end, with no irregularity against stronger narrators and no hidden defect.",
                    verdict: "Accepted: a proof in belief and in law", rank: 0),
        HadithGrade(name: "Hasan", arabic: "حَسَن", english: "Good",
                    definition: "The same conditions, except that a narrator's memory is a little lighter than the sahih narrator's. Still upright, still connected, still sound.",
                    verdict: "Accepted: acted upon like the sahih", rank: 1),
        HadithGrade(name: "Da'if", arabic: "ضَعِيف", english: "Weak",
                    definition: "Missing one or more of those conditions: a break in the chain, an unknown narrator, a weak memory, or a narrator whose uprightness is in question.",
                    verdict: "Not established as his words", rank: 2),
        HadithGrade(name: "Mawdu'", arabic: "مَوضُوع", english: "Fabricated",
                    definition: "A report invented and attributed to the Prophet (peace and blessings be upon him), usually exposed by a known liar in its chain or by its matn.",
                    verdict: "Rejected: never narrated except to expose it", rank: 3),
    ]

    /// Counted by how many carried it rather than by how strong they were: the second axis every
    /// grading also has.
    static let byNumber: [(name: String, arabic: String, meaning: String)] = [
        ("Mutawatir", "مُتَوَاتِر", "So many at every level that a shared lie is impossible: certain knowledge"),
        ("Mashhur", "مَشهُور", "Three or more at every level"),
        ("'Aziz", "عَزِيز", "At least two at every level"),
        ("Gharib", "غَرِيب", "One narrator at some level, and still sahih when he is reliable"),
    ]
}

/// The scale of hadith grades, strongest at the top: each rung's colour, its Arabic set large, what it
/// means and what it is worth. Under it, the second axis (how many carried it), because "ahad" is not
/// a grade of weakness and readers often think it is.
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

            VStack(alignment: .leading, spacing: 6) {
                ArticleEyebrow(text: "BY HOW MANY CARRIED IT", systemImage: "person.3.fill", accent: accent)
                    .padding(.top, 4)

                ForEach(HadithGrade.byNumber, id: \.name) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                        Text.islamArabic(item.arabic, highlightAllah: false)
                            .font(appearance.islamArabicFont(base: 17, relativeTo: .subheadline))
                            .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                            .foregroundColor(accent)
                        Text(item.meaning)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }

                Text("Everything short of mutawatir is called ahad. Ahad is a count, not a weakness: most of the Sunnah is ahad and sahih, and it is binding.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
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
                        .tracking(1)
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

            Text(grade.definition)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

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
/// A resource puts it in its List through `ResourceHeroSection`, which draws nothing on the watch: the
/// watch compiles every resource that carries one, and a card this size would be the whole screen there.
struct ResourceHero<Footer: View>: View {
    @Environment(\.appearance) private var appearance

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
            .font(.title2.weight(.bold))
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
            .font(appearance.islamArabicFont(base: 26, relativeTo: .title2))
            .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
            .foregroundColor(accent)
            .multilineTextAlignment(.trailing)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    var body: some View {
        let accent = appearance.accent
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(eyebrow)
                    .tracking(1.3)
                    .lineLimit(2)
                    // A single word wider than the card cannot wrap: at the largest accessibility
                    // sizes "THE FOUNDATIONS" read "THE FOUNDATI..." (2026-10-04). It shrinks first.
                    .minimumScaleFactor(0.6)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.caption.weight(.bold))
            .foregroundColor(accent)

            VStack(alignment: .leading, spacing: 4) {
                if let arabic, !arabic.isEmpty {
                    headlineWithArabic(arabic, accent: accent)
                } else {
                    headlineText
                }

                if let source {
                    Text(source)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(accent)
                }
            }

            if !message.isEmpty {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !stats.isEmpty {
                ResourceHeroStats(stats)
                    .padding(.top, 2)
            }

            footer
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [accent.opacity(0.24), accent.opacity(0.05)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    Image(systemName: systemImage)
                        .font(.system(size: 110, weight: .bold))
                        .foregroundColor(accent.opacity(0.07))
                        .offset(x: 24, y: 24),
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

/// A hero's figures as chips, side by side: `ResourceHero`'s own row, and the one a hero's footer
/// draws when its figures belong below other lines (a hadith book's, under its compiler).
struct ResourceHeroStats: View {
    @Environment(\.appearance) private var appearance
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let stats: [ResourceHeroStat]

    init(_ stats: [ResourceHeroStat]) {
        self.stats = stats
    }

    var body: some View {
        // One column at the accessibility sizes, where three figures to a row shrank their labels
        // past reading.
        // Not lazy (`SummaryTileGrid`): a lazy grid in a List row can answer a different height on
        // each self-sizing pass, which iOS 26 traps on.
        SummaryTileGrid(columns: dynamicTypeSize.isAccessibilitySize ? 1 : max(stats.count, 1), spacing: 8) {
            ForEach(stats, id: \.self) { stat in
                statChip(stat, accent: appearance.accent)
            }
        }
    }

    private func statChip(_ stat: ResourceHeroStat, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(stat.value)
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(stat.label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.primary.opacity(0.05)))
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
