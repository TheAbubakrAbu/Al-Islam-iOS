import SwiftUI

/// The Pillars & Beliefs index. Its rows come from `IslamArticleCatalog` (the one list of articles the
/// search also reads), grouped into the sections the screen has always shown. Searching swaps the
/// index for two kinds of match: ARTICLES (row titles) and IN THE ARTICLES (a section of prose,
/// labelled with the article and the heading it sits under, which opens scrolled to that heading).
struct PillarsView: View {
    @ObservedObject var settings = Settings.shared
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
                #if DEBUG
                DebugArticleLink(articles: IslamArticleCatalog.debugArticles(for: .pillars))
                #endif

                Group {
                    if query.isEmpty {
                        IslamArticleIndexSections(groups: IslamArticleCatalog.pillarsGroups)
                    } else {
                        AskAISearchSection(query: query)

                        IslamArticleSearchSections(
                            query: query,
                            homes: [.pillars],
                            contentHits: search.contentHits,
                            isSearching: search.isSearching
                        ) { entry in
                            withAnimation { searchText = "" }
                            scrollTarget = entry.listID
                        }
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
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

#if DEBUG
/// DEBUG launch argument `-pillarsArticle <key>` (and `-guidesArticle <key>` in the How-to guides): pushes
/// one article as its list appears, the only headless route into these pages for screenshot checks.
/// `-articleSection <HEADING>` alongside it opens the article scrolled to that section, the way a
/// search result does. Renders nothing on its own: an invisible `NavigationLink` that is active from
/// the first frame.
struct DebugArticleLink: View {
    let articles: [String: AnyView]
    var argument: String = "-pillarsArticle"
    @State private var isActive = false

    private var requested: AnyView? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let idx = arguments.firstIndex(of: argument), arguments.indices.contains(idx + 1) else { return nil }
        guard let view = articles[arguments[idx + 1]] else { return nil }
        if let sectionIdx = arguments.firstIndex(of: "-articleSection"), arguments.indices.contains(sectionIdx + 1) {
            return AnyView(view.environment(\.articleScrollTarget, arguments[sectionIdx + 1]))
        }
        return view
    }

    var body: some View {
        if let requested {
            NavigationLink(destination: LazyDestination { requested }, isActive: $isActive) { EmptyView() }
                .hidden()
                .frame(height: 0)
                .listRowInsets(EdgeInsets())
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isActive = true }
                }
        }
    }
}
#endif

/// A quoted ayah or hadith in the Pillars, Beliefs and How-to guides: the original Arabic above its
/// English, in the accent colour, as one reusable view with a context menu that copies both, source
/// included (the citation is part of the English itself, e.g. "(Quran 2:43)" or "(Sahih al-Bukhari 631)").
///
/// The Arabic is the app's own text, not retyped: ayat are the Uthmani text of the bundled mushaf and
/// hadith are the matn as printed in the bundled collection, so what the reader sees here is what they
/// find when they open the same reference in the Quran or Hadith tabs.
struct ScriptureQuote: View {
    let text: String
    var arabic: String? = nil
    var dimmed: Bool = false

    // Two layers: this thin wrapper takes the call site's plain inputs and hands them to an Equatable
    // body behind `.equatable()`, so the 1,400+ quotes across the article pages do not re-evaluate when
    // their article's body runs again with the same words (a section reveal, a deep-link scroll). The
    // accent and the Arabic faces come from `AppearanceEnvironment`, not from observing `Settings`, so
    // a location tick or a countdown never reaches a quote at all.
    var body: some View {
        ScriptureQuoteBody(text: text, arabic: arabic, dimmed: dimmed).equatable()
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

    static func == (lhs: ScriptureQuoteBody, rhs: ScriptureQuoteBody) -> Bool {
        lhs.text == rhs.text && lhs.arabic == rhs.arabic && lhs.dimmed == rhs.dimmed
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
                Text(arabic.decomposingAlefMadda)
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
