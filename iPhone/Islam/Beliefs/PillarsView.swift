import SwiftUI

/// The Pillars & Beliefs index. Its rows come from `IslamArticleCatalog` (the one list of articles the
/// search also reads), grouped into the sections the screen has always shown. Searching swaps the
/// index for two kinds of match: ARTICLES (row titles) and IN THE ARTICLES (a section of prose,
/// labelled with the article and the heading it sits under, which opens scrolled to that heading).
struct PillarsView: View {
    /// An article to push on top of the index as it appears: a result on the Islam tab's root. Nil opens
    /// the plain index (a DEBUG build may still take one from `-pillarsArticle`, see `ArticleAutoOpen`).
    var openArticle: IslamArticleOpenRequest?

    init(openArticle: IslamArticleOpenRequest? = nil) {
        self.openArticle = openArticle
    }

    /// The folded groups opened with "Show All". See `IslamArticleIndexSections`. (None folds since the
    /// 25 prophets' pages moved to Stories of the Prophets, 2026-11-25; the index keeps the mechanism.)
    @State private var unfoldedGroups: Set<String> = []

    #if os(iOS)
    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// The index row a result asked to scroll to ("Scroll To Article"), consumed once the search clears.
    @State private var scrollTarget: String?
    @StateObject private var search = IslamArticleSearchModel()
    /// The filter row over the results (`IslamSearchFilterBar`): Topics, Match, Words, Without, Best Match.
    @State private var searchFilters = IslamSearchFilters.remembered()
    /// The pillar the hero's building opened (a catalog id).
    @State private var heroArticle: String?
    #endif

    var body: some View {
        #if os(iOS)
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        ScrollViewReader { proxy in
            List {
                Group {
                    if query.isEmpty {
                        Section {
                            IslamPillarsHero(open: $heroArticle)
                                .articleCardRow()
                        }

                        IslamArticleIndexSections(groups: IslamArticleCatalog.pillarsGroups, unfolded: $unfoldedGroups)
                    } else {
                        if searchFilters.shows(.askAI) {
                            AskAISearchSection(query: query)
                        }

                        IslamArticleSearchSections(
                            query: query,
                            homes: [.pillars],
                            contentHits: search.contentHits,
                            isSearching: search.isSearching,
                            onScrollTo: { entry in
                                withAnimation { searchText = "" }
                                // A row folded away behind "Show All": open its group so it is there
                                // to scroll to.
                                unfoldedGroups.insert("\(entry.home.rawValue)/\(entry.group)")
                                scrollTarget = entry.listID
                            },
                            filters: searchFilters,
                            reference: search.reference
                        )
                    }
                }
                .themedListRowBackground()
            }
            .englishArticle()
            .applyConditionalListStyle()
            .autoOpenArticle(openArticle, home: .pillars)
            // The hero's columns are Buttons in ONE List row writing this, with one destination on
            // the List (the one-link-per-row rule).
            .pushDestination(isPresented: Binding(
                get: { heroArticle != nil },
                set: { if !$0 { heroArticle = nil } }
            )) {
                if let heroArticle { IslamArticleCatalog.destination(id: heroArticle) }
            }
            .islamSearchFilterChrome($searchFilters, isSearching: !query.isEmpty, homes: [.pillars],
                                     kinds: [.scripture, .articles, .passages, .askAI])
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
            search.update(query: text, homes: [.pillars], filters: searchFilters)
            if !text.isEmpty { scrollTarget = nil }
        }
        .onChange(of: searchFilters) { filters in
            search.update(query: searchText, homes: [.pillars], filters: filters)
        }
        #else
        List {
            IslamArticleIndexSections(groups: IslamArticleCatalog.pillarsGroups, unfolded: $unfoldedGroups)
                .themedListRowBackground()
        }
        .englishArticle()
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
        let argument = home.debugArticleArgument
        // By key ("adam"), or by link key where two pages of one home share a key: Stories of the
        // Prophets has Adam's story and his own page ("pillars.adam").
        let rows = IslamArticleCatalog.groups(for: home).flatMap(\.entries)
        guard let idx = arguments.firstIndex(of: argument), arguments.indices.contains(idx + 1),
              let entry = rows.first(where: { $0.debugKey == arguments[idx + 1] })
                ?? rows.first(where: { $0.linkKey == arguments[idx + 1] }) else { return nil }
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
                           arabic: arabicText, dimmed: true, opens: .hadith(reference))
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
                               arabic: resolved.arabic, dimmed: false, emphasis: words, opens: .quran(reference))
                .equatable()
        } else {
            ScriptureQuoteBody(text: "(\(reference.citation))", arabic: nil, dimmed: false, opens: .quran(reference))
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
    /// What the quote opens in its tab (Abu, 2026-11-24: "for each Quran verse or ayah to have an
    /// option to open it and then it opens it in the Quran or Hadith tab"): a referenced quote's own
    /// reference; a literal quote's citation is read for one instead (`ScriptureCitations`).
    var opens: ScriptureQuoteTarget? = nil

    static func == (lhs: ScriptureQuoteBody, rhs: ScriptureQuoteBody) -> Bool {
        lhs.text == rhs.text && lhs.arabic == rhs.arabic && lhs.dimmed == rhs.dimmed && lhs.emphasis == rhs.emphasis
            && lhs.opens == rhs.opens
    }

    /// The Arabic as one `Text`: plain, or with the tokens outside `emphasis` lightened.
    private func arabicText(_ arabic: String) -> Text {
        guard let emphasis else {
            return Text.islamArabic(arabic.decomposingAlefMadda, highlightAllah: appearance.highlightAllahIslam)
        }
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
        var pieces: [String] = []
        if let arabic, !arabic.isEmpty { pieces.append(arabic) }
        pieces.append(text)
        return pieces.joined(separator: "\n\n")
    }

    /// `text` with its closing citation lifted out: "“...” (Quran 7:180)" reads as the quote and,
    /// under it, "Quran 7:180". Only a closing parenthetical that carries a number counts, so an
    /// aside such as "(peace be upon him)" stays in the sentence. `text` itself is untouched: it is
    /// what the copy menu hands over, citation included.
    private var quoteAndCitation: (quote: String, citation: String?) {
        let whole = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // A sentence's full stop after the citation ("... (Quran 2:255)." on the Miracles pages)
        // goes with it into the footer; anything else keeps its own.
        let trimmed = whole.hasSuffix(").") ? String(whole.dropLast()) : whole
        guard trimmed.hasSuffix(")") else { return (whole, nil) }
        var depth = 0
        var open: String.Index?
        var index = trimmed.endIndex
        while index > trimmed.startIndex {
            index = trimmed.index(before: index)
            let character = trimmed[index]
            if character == ")" { depth += 1 }
            if character == "(" {
                depth -= 1
                if depth == 0 { open = index; break }
            }
        }
        guard let open else { return (whole, nil) }
        let citation = String(trimmed[trimmed.index(after: open)..<trimmed.index(before: trimmed.endIndex)])
        guard citation.contains(where: \.isNumber) else { return (whole, nil) }
        let quote = trimmed[..<open].trimmingCharacters(in: .whitespacesAndNewlines)
        return (quote, citation)
    }

    /// The card's ground: the accent falling away corner to corner, a hairline in the same color, a
    /// solid bar down the leading edge (the blockquote's oldest sign), and a large faint glyph in
    /// the far corner that says which kind of text this is, a book for the Quran and a quotation
    /// mark for a narration. Plain shapes on purpose: an article carries dozens of these, and the
    /// watch compiles this file.
    /// `glyph` is off under a surah footer, whose own book disc says it, and whose Arabic name sits
    /// in that corner.
    private func cardBackground(glyph: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return shape
            .fill(
                LinearGradient(colors: [accent.opacity(0.17), accent.opacity(0.05)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                Image(systemName: dimmed ? "quote.closing" : "book.closed.fill")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(accent.opacity(glyph ? 0.07 : 0))
                    .rotationEffect(.degrees(dimmed ? 0 : -12))
                    .offset(x: 10, y: 14),
                alignment: .bottomTrailing
            )
            .overlay(
                Rectangle()
                    .fill(accent.opacity(0.85))
                    .frame(width: 3),
                alignment: .leading
            )
            .clipShape(shape)
            .overlay(shape.strokeBorder(accent.opacity(0.2), lineWidth: 1))
    }

    var body: some View {
        let _ = RenderCounter.hit("ScriptureQuote")
        let parts = quoteAndCitation
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

            // The size of the prose around it (Abu, 2026-09-20: "the same size as everything
            // else"). It was `.title3` in the accent, which made every quote shout over its article;
            // the card now does the setting-apart, so the words can read like the rest of the page.
            if !parts.quote.isEmpty {
                Text.islamText(parts.quote, highlightAllah: appearance.highlightAllahIslam)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let citation = parts.citation {
                citationLine(citation)
            }
        }
        .padding(.vertical, 12)
        .padding(.leading, 15)
        .padding(.trailing, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(glyph: dimmed || parts.citation.flatMap(QuranSurahNames.cited) == nil))
        .padding(.vertical, 3)
        // An English rendering (scripture stays English) reads left to right on a translated page too,
        // card and all, the Arabic original still on the right; inside an article it already does.
        .leftToRightContent(!parts.quote.isEmpty && !parts.quote.isMostlyArabicScript)
        #if os(iOS)
        // Kept as `Text`s rather than a `SelectableProse`: the context menu below already covers
        // "copy the whole quote, citation included", which is what a quote is normally wanted for,
        // and swapping in a text view per quote would put a UITextView in every article row to
        // duplicate a path that already works.
        quote
            .textSelection(.enabled)
            .contextMenu {
                Text(verbatim: AppLanguage.article("Copy"))
                    .foregroundStyle(.secondary)

                Button {
                    Settings.shared.hapticFeedback()
                    UIPasteboard.general.string = copyText
                } label: {
                    Label("Copy Quote", systemImage: "doc.on.doc")
                }

                if let link = openLink(citation: parts.citation) {
                    Button {
                        Settings.shared.hapticFeedback()
                        AppLinkRouter.open(link)
                    } label: {
                        Label(link.openTitle, systemImage: link.openSystemImage)
                    }

                    Button {
                        AppLinkShare.share(link, title: parts.citation ?? link.citationTitle)
                    } label: {
                        Label("Share Link", systemImage: "link")
                    }
                }
            }
        #else
        quote
        #endif
    }

    /// The citation under the quote. On the phone it is a button when the quote cites something the
    /// app carries: a tap opens the ayah in the Quran tab or the narration in the Hadith tab, where
    /// it can be read in full, played, bookmarked and shared.
    @ViewBuilder
    private func citationLine(_ citation: String) -> some View {
        if !dimmed, let cited = QuranSurahNames.cited(citation) {
            surahFooter(cited.reference, cited.names, citation: citation)
        } else {
            plainCitationLine(citation)
        }
    }

    /// A Quran quote's citation with its surah named (Abu, 2026-11-24: "I want to hear the surha name
    /// like Quran Maidah 5:3 but make it pretty"): "Quran Al-Ma'idah 5:3" over the surah's meaning,
    /// its Arabic name set large on the far side, under a hairline that sets it apart from the words,
    /// the way the Share Ayah card heads each block with the surah. On the phone the whole line opens
    /// the ayah in the Quran tab.
    @ViewBuilder
    private func surahFooter(_ reference: QuranQuoteReference, _ names: QuranSurahNames, citation: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(accent.opacity(0.18))
                .frame(height: 1)
            #if os(iOS)
            if let link = openLink(citation: citation) {
                Button {
                    Settings.shared.hapticFeedback()
                    AppLinkRouter.open(link)
                } label: {
                    surahRow(reference, names, opens: true)
                        .contentShape(Rectangle())
                }
                // Only the footer takes the tap: the rest of the card stays text to select.
                .buttonStyle(.borderless)
                .accessibilityHint(link.openTitle)
            } else {
                surahRow(reference, names, opens: false)
            }
            #else
            surahRow(reference, names, opens: false)
            #endif
        }
        .padding(.top, 2)
    }

    /// The footer's one line (see `surahFooter`); `opens` adds the arrow of a line that opens.
    private func surahRow(_ reference: QuranQuoteReference, _ names: QuranSurahNames, opens: Bool) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "book.closed.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(accent)
                .frame(width: 26, height: 26)
                .background(Circle().fill(accent.opacity(0.14)))

            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    (Text(verbatim: "Quran ").foregroundColor(accent.opacity(0.75))
                        + Text(verbatim: "\(names.transliteration) \(reference.text)").foregroundColor(accent))
                        .font(.caption.weight(.bold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if opens {
                        Image(systemName: "arrow.up.forward")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(accent.opacity(0.8))
                    }
                }
                Text(verbatim: names.english)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            Text(verbatim: names.arabic)
                .font(appearance.quranArabicFont(size: 22, relativeTo: .title3))
                .arabicFontDesign(custom: appearance.quranUsesCustomArabicFace)
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: "Quran, \(names.transliteration), \(names.english), \(reference.text)"))
    }

    @ViewBuilder
    private func plainCitationLine(_ citation: String) -> some View {
        let line = HStack(alignment: .firstTextBaseline, spacing: 5) {
            Image(systemName: dimmed ? "text.book.closed.fill" : "book.closed.fill")
                .font(.caption2)
            Text(citation)
                .font(.caption.weight(.semibold))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(accent)
        #if os(iOS)
        if let link = openLink(citation: citation) {
            Button {
                Settings.shared.hapticFeedback()
                AppLinkRouter.open(link)
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    line
                    Image(systemName: "arrow.up.forward")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(accent.opacity(0.8))
                }
                .contentShape(Rectangle())
            }
            // Only the line takes the tap: the rest of the card stays text to select.
            .buttonStyle(.borderless)
            .accessibilityHint(link.openTitle)
        } else {
            line
        }
        #else
        line
        #endif
    }

    #if os(iOS)
    /// The link the quote opens: its reference, or the first ayah or hadith its citation names. None
    /// in an app without that tab (`AppLink.opensInThisApp`): the citation is then words, as before.
    private func openLink(citation: String?) -> AppLink? {
        guard let link = citedLink(citation: citation), link.opensInThisApp else { return nil }
        return link
    }

    private func citedLink(citation: String?) -> AppLink? {
        switch opens {
        case .quran(let reference):
            return AppLink(key: "quran", value: "\(reference.surah):\(reference.runs.first?.lowerBound ?? 1)")
        case .hadith(let reference):
            let cited = reference.numbered.map { "id-\($0)" } ?? reference.citation.lowercased()
            return AppLink(key: "hadith", value: "\(reference.slug):\(cited)")
        case nil:
            return ScriptureCitations.firstLink(in: citation ?? text)
        }
    }
    #endif
}

/// What a quote card opens (see `ScriptureQuoteBody.opens`).
enum ScriptureQuoteTarget: Equatable {
    case quran(QuranQuoteReference)
    case hadith(HadithQuoteReference)
}

/// The words and the symbol of "open this in its tab", one pair wherever an ayah or a hadith is
/// shown outside its own reader (Abu, 2026-11-24: "add consistency for what opening an ayah or
/// Hadith looks like in all tabs"): a reminder, the Daily hub, a tajweed lesson's example, the
/// Tajweed Test, the Qiraat Explorer, a hadith study sheet, a quote's menu, an Ask AI source. The
/// words name the tab it lands on and the symbol is that tab's own (MainTabView's), so the button
/// says where it goes before it is tapped. `OpenInTabButton` (AppLink.swift) draws it as a button.
enum OpenInTab {
    static var quranTitle: String { String(localized: "Open in Quran") }
    static var hadithTitle: String { String(localized: "Open in Hadith") }
    static let quranSymbol = "character.book.closed.ar"
    static let hadithSymbol = "books.vertical"
}

#if os(iOS)
/// The Pillars & Beliefs index's opening card (Abu, 2026-09-29: "pretty designs ... for pillars"): the
/// hadith of the five, drawn the way it is worded, as a building. The roof is Islam, the five pillars
/// hold it up, and it stands on the six of iman. Every column and every foundation stone opens its
/// article. They are Buttons writing one binding, because the whole card is ONE List row and two
/// NavigationLinks in one row both fire on any tap.
struct IslamPillarsHero: View {
    @Environment(\.appearance) private var appearance
    @Binding var open: String?

    private struct Pillar: Identifiable {
        let id: String
        let name: String
        let arabic: String
        let systemImage: String
    }

    private static let five: [Pillar] = [
        Pillar(id: "ShahadahView", name: "Shahaadah", arabic: "الشَّهَادَة", systemImage: "quote.bubble"),
        Pillar(id: "SalahView", name: "Salaah", arabic: "الصَّلَاة", systemImage: "sun.max"),
        Pillar(id: "ZakahView", name: "Zakaah", arabic: "الزَّكَاة", systemImage: "heart.circle"),
        Pillar(id: "SawmView", name: "Sawm", arabic: "الصَّوم", systemImage: "moon.stars"),
        Pillar(id: "HajjView", name: "Hajj", arabic: "الحَجّ", systemImage: "house"),
    ]

    private static let six: [Pillar] = [
        Pillar(id: "GodView", name: "Allah", arabic: "", systemImage: "circle.hexagongrid"),
        Pillar(id: "AngelsView", name: "Angels", arabic: "", systemImage: "wind"),
        Pillar(id: "BooksView", name: "Books", arabic: "", systemImage: "book.closed"),
        Pillar(id: "ProphetsView", name: "Prophets", arabic: "", systemImage: "person.2"),
        Pillar(id: "DayView", name: "Last Day", arabic: "", systemImage: "hourglass"),
        Pillar(id: "QadarView", name: "Qadar", arabic: "", systemImage: "scalemass"),
    ]

    /// The resource's card (`ResourceHero`), with the building as its picture: the five columns and
    /// the six beliefs under them each open their article.
    var body: some View {
        ResourceHero(
            eyebrow: "THE FOUNDATIONS",
            systemImage: "moon.stars.fill",
            headline: "Indeed, the religion in the sight of Allah is Islam.",
            source: "Quran 3:19",
            // No figures: the building under it already counts the five and the six.
            message: "The five pillars of Islam, the six of eemaan and the three of tawheed, then the Quran and the hadith, the scholars and the answers to other paths. Tap a pillar to open it."
        ) {
            building
        }
    }

    private var building: some View {
        let accent = appearance.accent
        return VStack(spacing: 0) {
            // The roof.
            ZStack {
                PillarsRoof()
                    .fill(LinearGradient(colors: [accent.opacity(0.95), accent.opacity(0.7)],
                                         startPoint: .top, endPoint: .bottom))
                VStack(spacing: 0) {
                    Text("الإِسلَام")
                        .font(appearance.islamArabicFont(base: 22, relativeTo: .title3))
                        .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                    Text("ISLAM IS BUILT ON FIVE")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(AppLanguage.letterSpacing(1.4))
                }
                .foregroundColor(.white)
                .padding(.top, 16)
            }
            .frame(height: 70)
            .accessibilityElement(children: .combine)

            // The five columns.
            HStack(spacing: 6) {
                ForEach(Self.five) { pillar in
                    Button {
                        Settings.shared.hapticFeedback()
                        open = pillar.id
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: pillar.systemImage)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(accent)
                            Text(pillar.name)
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(pillar.arabic)
                                .font(appearance.islamArabicFont(base: 13, relativeTo: .caption))
                                .arabicFontDesign(custom: appearance.islamUsesCustomArabicFace)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(accent.opacity(0.12))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(accent.opacity(0.3), lineWidth: 1))
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(pillar.name), a pillar of Islam")
                }
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 6)

            // The foundation: the six of iman.
            VStack(spacing: 6) {
                Text("ON THE SIX PILLARS OF EEMAAN")
                    .font(.system(size: 9, weight: .heavy))
                    .tracking(AppLanguage.letterSpacing(1.4))
                    .foregroundColor(accent)

                // Not lazy (`SummaryTileGrid`): a lazy grid in a List row can answer a different height
                // on each self-sizing pass, which iOS 26 traps on.
                SummaryTileGrid(columns: 3, spacing: 5) {
                    ForEach(Self.six) { pillar in
                        Button {
                            Settings.shared.hapticFeedback()
                            open = pillar.id
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: pillar.systemImage)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(accent)
                                Text(pillar.name)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(accent.opacity(0.1)))
                            .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Belief in \(pillar.name)")
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accent.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(accent.opacity(0.25), lineWidth: 1))
            )
        }
        .padding(.vertical, 4)
    }
}

/// A shallow pediment: the roof over the five columns.
private struct PillarsRoof: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
#endif
