import SwiftUI

// Every article in two lengths (Abu, 2026-11-25: "We should do that for every single article have a
// setting picker that says long or short articles by default short and have a button at the top to read
// full article or short (defaults each time to whatever the setting was) and ask if they wanna change in
// settings. So we need to create a short and long version of each article").
//
// One source, two readings. A part only one version shows is marked where it is written, and everything
// unmarked is in both:
// - a data-backed article's section: `ArticleSection("HEADING", only: .long, [ ... ])`;
// - one block of a section: `.longOnly(.text("..."))`, `.shortOnly(.text("..."))`;
// - a view-based page's sections: `ArticleOnly(.long) { Section(header: ArticleHeader("...")) { ... } }`,
//   whole Sections only, never a row: a row that is a branch makes the List build every row of the page
//   on each update (see `OneRow`).
// The corpus builder (Scripts/build_islam_corpus.py) reads the same marks. The search and the Ask AI read
// the long version, each section flagged when only the long version shows it (a hit there opens the page
// long), and it writes `ArticleLengths.minutes` (ArticleLengths.swift) for the pages written twice: the
// pages that draw the switch, the first row of the page (`ArticleLengthSection`).

/// Which version of an article is on screen.
enum ArticleLength: String, CaseIterable, Sendable {
    case short, long

    /// What every article opens in: Islam Settings, Libraries. Short until the reader says otherwise.
    static var preferred: ArticleLength {
        ArticleLength(rawValue: Settings.shared.islamArticleLengthRaw) ?? .short
    }

    var other: ArticleLength { self == .short ? .long : .short }
}

/// What a page's switch reads and does: the version on screen, how long each takes, the choice, and the
/// question it asks after one (asked from the switch, so its popover points at it).
struct ArticleLengthControl {
    let length: ArticleLength
    let minutes: ArticleLengths.Minutes
    let choose: (ArticleLength) -> Void
    /// The version just chosen, while the question about making it the default is up.
    let asking: Binding<ArticleLength?>
}

private struct ArticleLengthKey: EnvironmentKey {
    /// A page with no switch (not an article, or one written once) shows everything but what only a
    /// short version shows.
    static let defaultValue: ArticleLength = .long
}

private struct ArticleLengthControlKey: EnvironmentKey {
    static let defaultValue: ArticleLengthControl? = nil
}

private struct ArticleOpensLongKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// The version the page shows (`ArticleLengthPage`).
    var articleLength: ArticleLength {
        get { self[ArticleLengthKey.self] }
        set { self[ArticleLengthKey.self] = newValue }
    }

    /// The page's switch, when the page is written twice.
    var articleLengthControl: ArticleLengthControl? {
        get { self[ArticleLengthControlKey.self] }
        set { self[ArticleLengthControlKey.self] = newValue }
    }

    /// Set by a search result that found its words where only the long version has them: the page
    /// opens long, whatever the setting, so the words are there to land on.
    var articleOpensLong: Bool {
        get { self[ArticleOpensLongKey.self] }
        set { self[ArticleOpensLongKey.self] = newValue }
    }
}

/// Sections of a view-based page that only one version shows. Goes round whole `Section`s: a branch
/// round a Section costs the List nothing, a branch round a row costs it every row.
struct ArticleOnly<Content: View>: View {
    @Environment(\.articleLength) private var length

    private let only: ArticleLength
    private let content: Content

    init(_ only: ArticleLength, @ViewBuilder content: () -> Content) {
        self.only = only
        self.content = content()
    }

    var body: some View {
        if length == only {
            content
        }
    }
}

extension ArticleSection {
    /// One section as a version shows it: its index in the article (the row's identity, kept across a
    /// switch), its heading, and the blocks it draws, unwrapped.
    struct Shown {
        let index: Int
        let heading: String
        let rows: [Row]
    }

    struct Row {
        let index: Int
        let block: ArticleBlock
    }

    /// The sections `length` shows, each with the blocks it shows: a section marked for the other
    /// version is left out, and so is a block marked for it or one that draws no row here (a door this
    /// platform does not have, `drawsRow`). A section left with no rows is left out too.
    static func shown(_ sections: [ArticleSection], in length: ArticleLength) -> [Shown] {
        sections.indices.compactMap { index in
            let section = sections[index]
            if let only = section.only, only != length { return nil }
            let rows = section.blocks.indices.compactMap { blockIndex -> Row? in
                guard let block = section.blocks[blockIndex].shown(in: length), block.drawsRow else { return nil }
                return Row(index: blockIndex, block: block)
            }
            return rows.isEmpty ? nil : Shown(index: index, heading: section.heading, rows: rows)
        }
    }
}

extension ArticleBlock {
    /// The block as `length` draws it: unwrapped from its mark, or nil when only the other version
    /// shows it.
    func shown(in length: ArticleLength) -> ArticleBlock? {
        switch self {
        case .longOnly(let block): return length == .long ? block.shown(in: length) : nil
        case .shortOnly(let block): return length == .short ? block.shown(in: length) : nil
        default: return self
        }
    }
}

// MARK: - The switch

/// The first row of an article written twice, above SUMMARY (Abu, 2026-11-25: "Have a picker or toggle
/// or something at the top of each page that says short or long"): the two versions side by side across
/// the page, each with its reading time, the one on screen filled. A data-backed page gets it from
/// `ArticleSectionsView`; a view-based page puts `ArticleLengthSection()` first in its List, before its
/// SUMMARY. A page with no switch (one written once) draws nothing here.
struct ArticleLengthSection: View {
    @Environment(\.articleLengthControl) private var control

    init() {}

    var body: some View {
        // A branch round a whole Section: the List still counts the page's rows off their types.
        if control != nil {
            Section {
                ArticleLengthSwitch()
            }
        }
    }
}

/// The switch's row (see `ArticleLengthSection`).
private struct ArticleLengthSwitch: View {
    @Environment(\.articleLengthControl) private var control
    @Environment(\.appearance) private var appearance
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // One container round the branch, so the row is one view whatever the page knows.
        ZStack {
            if let control {
                track(control)
            }
        }
        .frame(maxWidth: .infinity)
        .articleCardRow()
    }

    private func track(_ control: ArticleLengthControl) -> some View {
        let accent = appearance.accent
        return HStack(spacing: 3) {
            ForEach(ArticleLength.allCases, id: \.self) { length in
                segment(length, control: control, accent: accent)
            }
        }
        .padding(3)
        .background(Capsule(style: .continuous).fill(accent.opacity(0.08)))
        .overlay(Capsule(style: .continuous).strokeBorder(accent.opacity(0.16), lineWidth: 0.5))
        .modifier(ArticleLengthQuestion(asking: control.asking))
        .padding(.vertical, 2)
    }

    private func segment(_ length: ArticleLength, control: ArticleLengthControl, accent: Color) -> some View {
        let selected = control.length == length
        let minutes = length == .short ? control.minutes.short : control.minutes.long
        // Side by side while both halves fit their name and time on one line; the time under the name
        // in the large text sizes. Chosen from the size, never measured (`ViewThatFits` in a List row
        // sizes the row for its taller choice).
        let layout = typeSize >= .xxLarge ? AnyLayout(VStackLayout(spacing: 1)) : AnyLayout(HStackLayout(spacing: 6))
        return Button {
            guard !selected else { return }
            Settings.shared.hapticFeedback()
            control.choose(length)
        } label: {
            layout {
                HStack(spacing: 5) {
                    Image(systemName: length == .short ? "text.alignleft" : "text.justify.leading")
                        .font(.footnote.weight(.semibold))
                    Text(verbatim: AppLanguage.article(length == .short ? "Short" : "Full Article"))
                        .font(.subheadline.weight(.semibold))
                }
                Text(verbatim: "\(minutes) \(AppLanguage.article("min"))")
                    .font(.footnote.monospacedDigit())
                    .foregroundColor(selected ? accent.opacity(0.85) : .secondary)
            }
            .lineLimit(1)
            .foregroundColor(selected ? accent : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Capsule(style: .continuous).fill(selected ? accent.opacity(0.18) : Color.clear))
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text(verbatim: AppLanguage.article(length == .short ? "Short version" : "Full article")))
        .accessibilityValue(Text(verbatim: "\(minutes) \(AppLanguage.article("minutes"))"))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// The question the switch asks when it is moved away from the setting: make that the default? On the
/// switch itself, so on iOS 26 its popover rises from the control the reader just touched.
private struct ArticleLengthQuestion: ViewModifier {
    @Binding var asking: ArticleLength?

    func body(content: Content) -> some View {
        content
            .confirmationDialog(dialogTitle, isPresented: Binding(get: { asking != nil }, set: { if !$0 { asking = nil } }),
                                titleVisibility: .visible) {
                if let asking {
                    Button(AppLanguage.article(asking == .long ? "Always Open Full Articles" : "Always Open Short Versions")) {
                        Settings.shared.islamArticleLengthRaw = asking.rawValue
                    }
                    Button(AppLanguage.article("Don’t Ask Again")) {
                        Settings.shared.islamArticleLengthNoAsk = true
                    }
                    Button(AppLanguage.article("Just This Article"), role: .cancel) {}
                }
            } message: {
                Text(verbatim: AppLanguage.article("Articles open in the length set in Islam Settings, under Libraries, and you can change it there at any time."))
            }
    }

    private var dialogTitle: String {
        AppLanguage.article(asking == .short ? "Open Every Article Short?" : "Open Every Article in Full?")
    }
}

// MARK: - The page

/// What `selectableArticleList` adds to a page written twice: the version on screen (each visit opens on
/// the setting's), the switch's control, and the state of the question the switch asks when it is moved
/// away from the setting: make that the default? (`ArticleLengthQuestion`, on the switch.)
struct ArticleLengthPage: ViewModifier {
    let article: String?
    @ObservedObject var handle: ArticleScrollHandle

    @Environment(\.articleOpensLong) private var opensLong
    /// The section the page opens on, when it opens on one (a search hit, a link).
    @Environment(\.articleScrollTarget) private var scrollTarget
    /// The version just chosen, while the question about making it the default is up.
    @State private var asking: ArticleLength?
    /// Set once the opening version is decided: coming back to the page from one it pushed must not
    /// undo a switch the reader made since.
    @State private var opened = false

    private var minutes: ArticleLengths.Minutes? { article.flatMap { ArticleLengths.minutes[$0] } }

    func body(content: Content) -> some View {
        let minutes = minutes
        content
            .environment(\.articleLength, minutes == nil ? .long : handle.length)
            .environment(\.articleLengthControl, minutes.map { minutes in
                ArticleLengthControl(length: handle.length, minutes: minutes, choose: { choose($0) }, asking: $asking)
            })
            // The page's own: nothing it pushes opens long because this one did.
            .environment(\.articleOpensLong, false)
            .onAppear {
                guard !opened else { return }
                opened = true
                if minutes != nil, opensLong || landsInFullOnly { handle.length = .long }
            }
    }

    /// The page opens on a section only the full article has (any way in: a search hit, a shared
    /// link, a door), so it opens in full: in the short version the landing would find no heading.
    private var landsInFullOnly: Bool {
        guard handle.length == .short, let article, let target = scrollTarget, !target.isEmpty,
              let page = IslamArticles.all.first(where: { $0.id == article }) else { return false }
        let landing = page.sections.filter { $0.landing == target }
        return !landing.isEmpty && landing.allSatisfy { $0.only == .long }
    }

    private func choose(_ length: ArticleLength) {
        withAnimation(.easeInOut(duration: 0.2)) { handle.length = length }
        guard length != ArticleLength.preferred, !Settings.shared.islamArticleLengthNoAsk else { return }
        // After the switch has settled, so the question rises over the version it asks about.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { asking = length }
    }
}
