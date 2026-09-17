import SwiftUI

/// The Pillars & Beliefs index. Its rows come from `IslamArticleCatalog` (the one list of articles the
/// search also reads), grouped into the sections the screen has always shown. Searching swaps the
/// index for two kinds of match: ARTICLES (row titles) and IN THE ARTICLES (a section of prose,
/// labelled with the article and the heading it sits under, which opens scrolled to that heading).
struct PillarsView: View {
    @ObservedObject var settings = Settings.shared
    /// An article to push on top of the index as it appears: a result on the Islam tab's root. Nil opens
    /// the plain index (a DEBUG build may still take one from `-pillarsArticle`, see `ArticleAutoOpen`).
    var openArticle: IslamArticleOpenRequest?

    init(openArticle: IslamArticleOpenRequest? = nil) {
        self.openArticle = openArticle
    }

    #if os(iOS)
    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// The index row a result asked to scroll to ("Scroll To Article"), consumed once the search clears.
    @State private var scrollTarget: String?
    @StateObject private var search = IslamArticleSearchModel()
    #endif

    var body: some View {
        #if os(iOS)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        ScrollViewReader { proxy in
            List {
                Group {
                    if query.isEmpty {
                        IslamArticleIndexSections(groups: IslamArticleCatalog.pillarsGroups)
                    } else {
                        AskAISearchSection(query: query)

                        IslamArticleSearchSections(
                            query: query,
                            homes: [.pillars],
                            contentHits: search.contentHits,
                            isSearching: search.isSearching,
                            onScrollTo: { entry in
                                withAnimation { searchText = "" }
                                scrollTarget = entry.listID
                            }
                        )
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .autoOpenArticle(openArticle, home: .pillars)
            .islamArticleIndexSearch(searchText: $searchText, barsCollapsed: $barsCollapsed,
                                     scrollTarget: scrollTarget, proxy: proxy)
        }
        .navigationTitle("Pillars & Beliefs")
        .onAppear {
            IslamArticleSearchModel.prewarm()
            #if DEBUG
            if let seeded = IslamSearchDebug.launchQuery("-pillarsSearch"), searchText.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { searchText = seeded }
            }
            #endif
        }
        .onChange(of: searchText) { text in
            search.update(query: text, homes: [.pillars])
            if !text.isEmpty { scrollTarget = nil }
        }
        #else
        List {
            IslamArticleIndexSections(groups: IslamArticleCatalog.pillarsGroups)
                .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Pillars & Beliefs")
        #endif
    }
}

/// Pushes one article on top of its index as the index appears: what a result on the Islam tab's root
/// asks for (`IslamArticleOpenRequest`), so the article stacks on Pillars & Beliefs or the How-to Guides
/// and Back returns to the index, the way a hadith opened from the Hadith tab's search stacks on its
/// book and chapter. In DEBUG builds the launch argument `-pillarsArticle <key>` (or `-guidesArticle
/// <key>`, with `-articleSection <HEADING>` alongside) makes the same request: the only headless route
/// into these pages for screenshot checks. Attached to the index List and pushed through the List's own
/// `navigationDestination(isPresented:)` (see `PushDestination`); it used to be an invisible
/// `NavigationLink(isActive:)` row, deprecated on watchOS 9 and the pattern that crashed the Quran tab.
struct ArticleAutoOpen: ViewModifier {
    let home: IslamArticleHome
    let request: IslamArticleOpenRequest?
    @State private var isActive = false
    /// Once: the index's `onAppear` fires again when the reader comes Back from the article.
    @State private var didOpen = false

    private var resolved: IslamArticleOpenRequest? { request ?? Self.launchRequest(for: home) }

    func body(content: Content) -> some View {
        content
            .pushDestination(isPresented: $isActive) {
                if let resolved {
                    IslamArticleCatalog.destination(id: resolved.id, section: resolved.section)
                }
            }
            .onAppear {
                guard let resolved, !didOpen else { return }
                didOpen = true
                #if DEBUG
                NSLog("ARTICLEOPEN home=%@ article=%@ section=%@", home.rawValue, resolved.id, resolved.section ?? "")
                #endif
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isActive = true }
            }
    }

    /// The DEBUG launch arguments' request: nil in Release, and when none was passed.
    static func launchRequest(for home: IslamArticleHome) -> IslamArticleOpenRequest? {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let argument = home == .pillars ? "-pillarsArticle" : "-guidesArticle"
        guard let idx = arguments.firstIndex(of: argument), arguments.indices.contains(idx + 1),
              let entry = IslamArticleCatalog.groups(for: home).flatMap(\.entries)
                .first(where: { $0.debugKey == arguments[idx + 1] }) else { return nil }
        var section: String?
        if let sectionIdx = arguments.firstIndex(of: "-articleSection"), arguments.indices.contains(sectionIdx + 1) {
            section = arguments[sectionIdx + 1]
        }
        return IslamArticleOpenRequest(id: entry.id, section: section)
        #else
        return nil
        #endif
    }
}

extension View {
    func autoOpenArticle(_ request: IslamArticleOpenRequest?, home: IslamArticleHome) -> some View {
        modifier(ArticleAutoOpen(home: home, request: request))
    }
}

/// A quoted ayah or hadith in the Pillars, Beliefs and How-to guides: the original Arabic above its
/// English, in the accent colour, as one reusable view with a context menu that copies both, source
/// included (the citation is part of the English itself, e.g. "(Quran 2:43)" or "(Sahih al-Bukhari 631)").
///
/// The Arabic is the app's own text, not retyped: ayat are read from the bundled mushaf and hadith
/// from the bundled collection as the quote renders (`QuranQuote.swift`, `HadithQuote.swift`), so what
/// the reader sees here is what they find when they open the same reference in the Quran or Hadith tabs.
struct ScriptureQuote: View {
    let text: String
    var arabic: String? = nil
    var dimmed: Bool = false
    /// The reference form: a Quran quote whose words come from the Quran the app ships, never from
    /// a copy in the article (see `QuranQuote.swift`). `words` narrows it to the quoted words.
    var reference: QuranQuoteReference? = nil
    var words: ClosedRange<Int>? = nil
    /// The shelf form: a narration whose words come from the bundled collection (see
    /// `HadithQuote.swift`), the Arabic and the English each a token range of the row, or the
    /// literal `arabic` / `text` above when the article's wording is not the shelf's.
    var hadith: HadithQuoteReference? = nil
    var cite: String = ""
    var hadithArabic: ClosedRange<Int>? = nil
    var hadithEnglish: [ClosedRange<Int>] = []

    /// The literal form: the words of the Companions and scholars, and anything else the app's
    /// packs do not carry. Quran quotes use `init(quran:words:)`; hadith use `init(hadith:cite:)`.
    init(text: String, arabic: String? = nil, dimmed: Bool = false) {
        self.text = text
        self.arabic = arabic
        self.dimmed = dimmed
    }

    /// The reference is one surah's ayahs: 2:255, 52:35-36 or 2:43, 110. A reference that does not
    /// parse renders as its citation alone, which the corpus gate (Scripts/verify_islam_corpus.py)
    /// refuses to ship in the first place.
    init(quran reference: String, words: ClosedRange<Int>? = nil) {
        self.text = "(Quran \(reference))"
        self.reference = QuranQuoteReference(reference)
        self.words = words
    }

    /// A narration on the shelf, "bukhari:6306", cited as written ("Sahih al-Bukhari 6306, Sahih
    /// Muslim 2705"). `arabic` is the matn's token range in the row's Arabic and `english` the quoted
    /// sentence's in its translation; a side the shelf does not have in the article's words is
    /// carried literally instead (`arabicText`, or `text` with its quote marks and no citation).
    init(hadith link: String, cite: String, arabic: ClosedRange<Int>? = nil, english: ClosedRange<Int>? = nil,
         text: String? = nil, arabicText: String? = nil) {
        self.init(hadith: link, cite: cite, arabic: arabic, english: english.map { [$0] } ?? [],
                  text: text, arabicText: arabicText)
    }

    /// The same with an English quote that skips part of the narration: one range per piece.
    init(hadith link: String, cite: String, arabic: ClosedRange<Int>? = nil, english: [ClosedRange<Int>],
         text: String? = nil, arabicText: String? = nil) {
        self.text = text ?? ""
        self.arabic = arabicText
        self.dimmed = true
        self.hadith = HadithQuoteReference(link)
        self.cite = cite
        self.hadithArabic = arabic
        self.hadithEnglish = english
    }

    // Two layers: this thin wrapper takes the call site's plain inputs and hands them to an Equatable
    // body behind `.equatable()`, so the 1,400+ quotes across the article pages do not re-evaluate when
    // their article's body runs again with the same words (a section reveal, a deep-link scroll). The
    // accent and the Arabic faces come from `AppearanceEnvironment`, not from observing `Settings`, so
    // a location tick or a countdown never reaches a quote at all.
    var body: some View {
        if let reference {
            QuranQuoteView(reference: reference, words: words)
        } else if let hadith {
            HadithQuoteView(reference: hadith, cite: cite, arabic: hadithArabic, english: hadithEnglish,
                            literalText: text, literalArabic: arabic)
        } else {
            ScriptureQuoteBody(text: text, arabic: arabic, dimmed: dimmed).equatable()
        }
    }
}

/// A referenced hadith quote: the row's texts come from `HadithQuoteSource`, synchronously when the
/// row is warm (a quote scrolled back into view) and after one off-main read the first time, during
/// which the citation shows alone. A link the shelf cannot resolve keeps showing the citation (and
/// whichever side is literal), which the corpus gate refuses to ship in the first place.
private struct HadithQuoteView: View {
    let reference: HadithQuoteReference
    let cite: String
    let arabic: ClosedRange<Int>?
    let english: [ClosedRange<Int>]
    let literalText: String
    let literalArabic: String?

    @State private var late: HadithQuoteText?

    var body: some View {
        let row = late ?? HadithQuoteSource.cached(reference)
        let englishText: String = english.isEmpty
            ? literalText
            : row.map { "\u{201C}\(WordRange.words($0.text, english))\u{201D}" } ?? ""
        let arabicText: String? = arabic.map { range in row.map { WordRange.words($0.arabic, range) } } ?? literalArabic
        ScriptureQuoteBody(text: englishText.isEmpty ? "(\(cite))" : "\(englishText) (\(cite))",
                           arabic: arabicText, dimmed: true)
            .equatable()
            .task(id: reference) {
                if row == nil { late = await HadithQuoteSource.resolve(reference) }
            }
    }
}

/// A referenced Quran quote: resolved from the app's own text as it renders (a dictionary lookup,
/// not an observation of `QuranData`, so a load step never re-evaluates every quote on a page). In
/// the one case the text is not there yet, an article opened in the first moments of a cold launch,
/// the citation shows alone and the words follow once the Quran has loaded.
private struct QuranQuoteView: View {
    let reference: QuranQuoteReference
    let words: ClosedRange<Int>?

    @State private var late: QuranQuoteText?

    var body: some View {
        let resolved = late ?? QuranQuoteSource.resolve(reference)
        if let resolved {
            ScriptureQuoteBody(text: "\u{201C}\(resolved.english)\u{201D} (\(reference.citation))",
                               arabic: resolved.arabic, dimmed: false, emphasis: words)
                .equatable()
        } else {
            ScriptureQuoteBody(text: "(\(reference.citation))", arabic: nil, dimmed: false)
                .equatable()
                .task {
                    await QuranQuoteSource.waitUntilReady()
                    late = QuranQuoteSource.resolve(reference)
                }
        }
    }
}

private struct ScriptureQuoteBody: View, Equatable {
    @Environment(\.appearance) private var appearance

    /// The English rendering with its citation.
    let text: String
    /// The Arabic original: the ayah, or the hadith's matn (the Prophet's words, or the Companion's
    /// report), without the chain of narrators.
    let arabic: String?
    /// Hadith and the words of the Companions render slightly softened (0.85 opacity) so ayat keep
    /// the fullest accent, and their Arabic is set in the Islam tab's face rather than the mushaf face.
    let dimmed: Bool
    /// The words the article is about, as a token range of `arabic`: those keep the full accent and
    /// the rest of the ayah steps back. Nil quotes the whole text evenly.
    var emphasis: ClosedRange<Int>? = nil

    static func == (lhs: ScriptureQuoteBody, rhs: ScriptureQuoteBody) -> Bool {
        lhs.text == rhs.text && lhs.arabic == rhs.arabic && lhs.dimmed == rhs.dimmed && lhs.emphasis == rhs.emphasis
    }

    /// The Arabic as one `Text`: plain, or with the tokens outside `emphasis` lightened.
    private func arabicText(_ arabic: String) -> Text {
        guard let emphasis else { return Text(arabic.decomposingAlefMadda) }
        let tokens = arabic.split(separator: " ", omittingEmptySubsequences: true)
        var out = Text("")
        for (index, token) in tokens.enumerated() {
            var piece = Text(String(token).decomposingAlefMadda)
            if !emphasis.contains(index) { piece = piece.foregroundColor(accent.opacity(0.5)) }
            out = index == 0 ? piece : out + Text(" ") + piece
        }
        return out
    }

    private var accent: Color { appearance.accent.opacity(dimmed ? 0.85 : 1) }

    /// Ayat follow the Quran font picker (they ARE Quran, with its pause marks and Uthmani spelling);
    /// everything else follows the Islam tab's Arabic face, the same one the duas and adhkar use.
    private var arabicFont: Font {
        dimmed
            ? appearance.islamArabicFont(base: 22, relativeTo: .title2)
            : appearance.quranArabicFont(size: 24, relativeTo: .title2)
    }

    private var arabicUsesCustomFace: Bool {
        dimmed ? appearance.islamUsesCustomArabicFace : appearance.quranUsesCustomArabicFace
    }

    private var copyText: String {
        if let arabic, !arabic.isEmpty { return arabic + "\n\n" + text }
        return text
    }

    var body: some View {
        let _ = RenderCounter.hit("ScriptureQuote")
        let quote = VStack(alignment: .leading, spacing: 10) {
            if let arabic, !arabic.isEmpty {
                arabicText(arabic)
                    .font(arabicFont)
                    .arabicFontDesign(custom: arabicUsesCustomFace)
                    .lineSpacing(6)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .foregroundColor(accent)
                    // The AyahRow rule: a long Arabic line must WRAP, never clamp to "…". Inside a List
                    // row the text is otherwise free to take a single-line height and truncate.
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(text)
                .font(.title3)
                .foregroundColor(accent)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
        #if os(iOS)
        // Kept as `Text`s rather than a `SelectableProse`: the context menu below already covers
        // "copy the whole quote, citation included", which is what a quote is normally wanted for,
        // and swapping in a text view per quote would put a UITextView in every article row to
        // duplicate a path that already works.
        quote
            .textSelection(.enabled)
            .contextMenu {
                Text("Copy")
                    .foregroundStyle(.secondary)

                Button {
                    Settings.shared.hapticFeedback()
                    UIPasteboard.general.string = copyText
                } label: {
                    Label("Copy Quote", systemImage: "doc.on.doc")
                }
            }
        #else
        quote
        #endif
    }
}
