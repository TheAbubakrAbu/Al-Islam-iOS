import SwiftUI

// Shared hadith pieces: the settings sheet, reference resolution, the hadith row, bookmark rows and
// tiles, the detail screen, immersive full-screen reading, and the Share Hadith sheet.

#if os(iOS)

// MARK: - Reference resolution ("bukhari 5")

/// Loads the book, resolves the reference, and shows the hadith - the landing screen for "bukhari 5"-style
/// lookups and for bookmarked hadiths.
struct HadithReferenceView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared

    let book: HadithCatalogBook
    /// 1-based chapter position when the lookup was "book C:N"; nil for a plain hadith number.
    let chapter: Int?
    let hadith: Int
    /// The citation's variant letter when the lookup carried one ("muslim 8a" -> "a"). Only
    /// meaningful without `chapter`.
    var suffix: String? = nil
    /// "muslim introduction 9": the number is the Introduction chapter's own (Sahih Muslim).
    var introduction: Bool = false
    /// Interpret `hadith` as the internal row number (idInBook), never as a citation - for records
    /// saved by row key whose hadith can no longer be resolved directly. Without this, a stale row
    /// key in a drifted book would be read citation-first and could open a DIFFERENT hadith.
    var byRowNumber: Bool = false

    /// The book, opened straight from its bundled pack - synchronous and instant, so this screen has
    /// no loading state and cannot fail for want of a network.
    private var data: HadithBookData? { store.book(book) }

    private var resolved: HadithBookData.Hadith? {
        guard let data else { return nil }
        if let chapter { return data.hadith(chapterPosition: chapter, position: hadith) }
        if byRowNumber { return data.hadith(numbered: hadith) }
        // Citation-first: "muslim 8" is the hadith CITED 8 (standard sunnah.com numbering), falling
        // back to the internal row number for the books that have no citations.
        return data.hadith(referenced: hadith, suffix: suffix, introduction: introduction)
    }

    /// The number as the user asked for it - base plus any variant letter ("8a").
    private var requestedNumber: String { "\(introduction ? "Introduction " : "")\(hadith)\(suffix ?? "")" }

    var body: some View {
        Group {
            if let data {
                if let resolved {
                    // The Quran search's way: land in the CHAPTER, scrolled to the hadith itself.
                    if let resolvedChapter = data.chapters.first(where: { $0.id == resolved.chapterId }) {
                        HadithChapterView(
                            book: book,
                            bookData: data,
                            chapter: resolvedChapter,
                            scrollToHadithId: resolved.idInBook
                        )
                    } else {
                        List {
                            Section {
                                HadithRow(book: book, hadith: resolved)
                                    .equatable()
                            }
                            .themedListRowBackground()
                        }
                        .applyConditionalListStyle()
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "questionmark.circle")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)

                        Text(chapter.map { "No hadith \(hadith) in chapter \($0) of \(book.englishTitle)." }
                             ?? "No hadith numbered \(requestedNumber) in \(book.englishTitle).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else {
                // The pack is bundled, so this only shows if its file is missing from the app itself.
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)

                    Text("\(book.englishTitle) could not be opened.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .navigationTitle(chapter.map { "\(book.englishTitle) \($0):\(hadith)" } ?? "\(book.englishTitle) \(requestedNumber)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension HadithReferenceView {
    /// A reference screen aimed at exactly this ALREADY-RESOLVED hadith: by its citation when it has
    /// one (the number `hadith(referenced:)` resolves citation-first), by its internal row number
    /// otherwise. The fallback call sites (a hit whose chapter can't be found) used to pass
    /// `idInBook` straight in, which citation-first resolution would now read as a citation.
    init(book: HadithCatalogBook, resolved: HadithBookData.Hadith) {
        if let citation = resolved.citation,
           let parsed = HadithBookData.citationNumber(inQuery: citation) {
            self.init(book: book, chapter: nil, hadith: parsed.base, suffix: parsed.suffix)
        } else {
            // No citation on the source hadith: its idInBook must be read as a ROW number, or an
            // uncited row inside a cited book (Muslim's muqaddimah) could resolve to the hadith
            // that happens to be CITED with that base.
            self.init(book: book, chapter: nil, hadith: resolved.idInBook, byRowNumber: true)
        }
    }
}

// MARK: - One hadith

extension Settings {
    /// One string folding every Settings field a hadith row's body reads - the hadith counterpart of
    /// `ayahRenderSettingsSignature`. Equatable hadith rows compare it so an appearance change still
    /// re-renders them, while an unrelated invalidation of their parent skips the long-text body.
    var hadithRenderSettingsSignature: String {
        [
            showHadithArabic ? "1" : "0",
            showHadithEnglish ? "1" : "0",
            highlightAllahNamesHadith ? "1" : "0",
            useFontArabic ? "1" : "0",
            nonQuranArabicFontName,
            "\(hadithArabicFontSize)",
            "\(hadithEnglishFontSize)",
            accentColor.rawValue,
            customAccentColorHex
        ].joined(separator: "|")
    }
}

/// The sunnah.com grade line ("Grade: Da'if (Al-Albani) · Da'if (Darussalam)"), rendered wherever a
/// full hadith shows. Verdicts display VERBATIM - the thousands of distinct nuanced strings are not
/// points on one scale, so nothing here parses, ranks, or color-codes them. Renders nothing when the
/// hadith carries no grading (Bukhari and Muslim carry none by design).
struct HadithGradeLine: View {
    /// Read, not observed: the line is rendered by rows whose parents already observe Settings and
    /// whose `==` folds the accent, so an observation here only bypassed that gate on every publish.
    private let accent: Color = Settings.shared.accentColor.color

    let grades: [(name: String, grade: String)]
    /// Caption-scale for compact (search-result) rows, footnote for reading rows.
    var font: Font = .footnote

    /// "Da'if (Al-Albani) · Da'if (Darussalam)" - the parenthetical omitted when the grader is unnamed.
    /// Shared with the Share/Copy composition so the row and the shared text always agree.
    static func joined(_ grades: [(name: String, grade: String)]) -> String {
        grades
            .map { $0.name.isEmpty ? $0.grade : "\($0.grade) (\($0.name))" }
            .joined(separator: " · ")
    }

    /// ONE wrapping line - "Grade: Sahih (Al-Albani) · Da'if (Darussalam)" - built from CONCATENATED
    /// `Text` runs so the coloring is per segment: the VERDICT term carries the accent color, the
    /// grader's name in parentheses (and the label and separators) stay secondary. Every verdict term
    /// gets the SAME accent - nothing here ranks or color-codes one verdict against another; the only
    /// distinction drawn is term-vs-name.
    private var line: Text {
        var result = Text("Grade: ").foregroundColor(.secondary)
        for (index, entry) in grades.enumerated() {
            if index > 0 {
                result = result + Text(" · ").foregroundColor(.secondary)
            }
            result = result + Text(entry.grade).foregroundColor(accent)
            if !entry.name.isEmpty {
                result = result + Text(" (\(entry.name))").foregroundColor(.secondary)
            }
        }
        return result
    }

    var body: some View {
        if !grades.isEmpty {
            line
                .font(font)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct HadithRow: View, Equatable {
    /// Read as a plain property, NOT observed: every Settings field this body reads is folded into
    /// `renderSettingsSignature`, and the parents that build rows observe Settings themselves - so an
    /// appearance change reaches the row through `==`, while an unrelated publish (a last-read
    /// write, a prayer-time tick) no longer re-lays out every visible hadith. An `@ObservedObject`
    /// here bypassed the Equatable gate entirely (performance plan, Phase 7 step 7).
    private var settings: Settings { Settings.shared }
    /// The row renders ONLY bookmark/note state, so it observes the user-data object - not HadithStore,
    /// whose download/prewarm publishes used to re-render every visible row on every tick.
    @ObservedObject private var userData = HadithUserData.shared

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith
    var searchText: String = ""
    /// The Quran ayah-search rows' scale: caption-sized type for search results, and the
    /// show-Arabic/English toggles don't apply. With a `searchText` the row is a search RESULT and
    /// shows a snippet, not the narration: the stretch around the first match in each language
    /// (`HadithSearchSnippet`), so a page of results is a page and the match is always in view. The
    /// whole hadith is one tap away. Without a `searchText` the full text renders, as before.
    var compact: Bool = false
    /// Show the "3 -" within-chapter position before the citation. Only the chapter reading
    /// screens pass true: in search results and standalone cards the ordinal is noise ("3 - 1000
    /// Bukhari" answers a question nobody asked outside the chapter).
    var showsChapterPosition: Bool = false
    /// The paged reader's Fit Page shrink - an overflowing page passes < 1 so its text fits the screen.
    var fontScale: CGFloat = 1
    /// Captured at construction so a parent re-render on an appearance change delivers a fresh value and
    /// fails `==` - see `Settings.hadithRenderSettingsSignature`.
    var renderSettingsSignature: String = Settings.shared.hadithRenderSettingsSignature
    /// Snapshotted at init (the row deliberately doesn't observe HadithStore): this hadith is its
    /// book's last-read position, so the pill gets the book badge - the Quran rows' grammar. A
    /// parent re-render delivers a fresh value and fails `==`, same as `renderSettingsSignature`.
    let isLastRead: Bool

    init(
        book: HadithCatalogBook,
        hadith: HadithBookData.Hadith,
        searchText: String = "",
        compact: Bool = false,
        fontScale: CGFloat = 1,
        showsChapterPosition: Bool = false
    ) {
        self.book = book
        self.hadith = hadith
        self.searchText = searchText
        self.compact = compact
        self.fontScale = fontScale
        self.showsChapterPosition = showsChapterPosition
        self.isLastRead = MainActor.assumeIsolated {
            HadithStore.shared.lastRead(for: book.slug)?.idInBook == hadith.idInBook
        }
    }

    /// The body lays out the hadith's FULL Arabic and English - the most expensive row in the tab - and
    /// its parents re-render on every publish of objects the row doesn't care about (the last-read save
    /// while reading, any Settings write). Bookmark/note state is deliberately NOT compared:
    /// it lives in observed `HadithUserData`, whose publish invalidates the row directly, bypassing `==`.
    static func == (l: Self, r: Self) -> Bool {
        l.book.slug == r.book.slug &&
        l.hadith.idInBook == r.hadith.idInBook &&
        l.hadith.chapterId == r.hadith.chapterId &&
        l.searchText == r.searchText &&
        l.compact == r.compact &&
        l.fontScale == r.fontScale &&
        l.renderSettingsSignature == r.renderSettingsSignature &&
        l.isLastRead == r.isLastRead
    }

    @State private var showShareSheet = false
    @State private var showNoteSheet = false
    @State private var noteDraft = ""
    @State private var showRespectAlert = false
    @State private var showSummarize = false
    @State private var showSelectTextSheet = false

    /// "Sahih al-Bukhari 1234" - the standard way a hadith is cited (the sunnah.com citation when
    /// one exists, the internal row number for the books that have none).
    private var reference: String {
        "\(book.englishTitle) \(hadith.displayNumber)"
    }

    #if os(iOS) && canImport(FoundationModels)
    /// What "Summarize with AI" hands the model: the citation, the narrator, then the narration.
    ///
    /// The citation leads because the model is told to ground on this text and nothing else, and a
    /// narration that names its own source is one it cannot quietly attribute elsewhere.
    ///
    /// The ARABIC is deliberately left out while `OnDeviceAsk.supportsArabic` is false, which is
    /// what every other AI entry point in the app does. Apple Intelligence has no Arabic as of
    /// iOS 26 and rejects a prompt carrying a substantial Arabic passage outright
    /// (`unsupportedLanguageOrLocale`), so including the narration's own Arabic would not enrich
    /// the summary - it would fail the request, and fail it hardest on the short narrations where
    /// the Arabic outweighs its translation. `excludedNote` says so on the sheet rather than
    /// letting the reader assume the Arabic was read.
    private var summarizeSource: String {
        let text = hadith.allText
        var parts = [reference]
        if !text.narrator.isEmpty { parts.append(text.narrator) }
        if OnDeviceAsk.supportsArabic, !text.arabic.isEmpty { parts.append(text.arabic) }
        if !text.text.isEmpty { parts.append(text.text) }
        return parts.joined(separator: "\n\n")
    }

    /// The note the sheet shows about what it could not read, or nil once the model gains Arabic.
    private var summarizeExcludedNote: String? {
        OnDeviceAsk.supportsArabic ? nil
            : "The narration\u{2019}s Arabic is left out: Apple Intelligence can\u{2019}t read Arabic on this device yet."
    }

    /// Whether there is anything the model can actually read. A few collections ship no English at
    /// all (Sunan ad-Darimi carries none), and offering a button that can only fail is worse than
    /// not offering it.
    private var canSummarize: Bool {
        let text = hadith.allText
        return OnDeviceAsk.supportsArabic ? !(text.text.isEmpty && text.arabic.isEmpty) : !text.text.isEmpty
    }
    #endif

    private var isBookmarked: Bool {
        userData.isBookmarked(slug: book.slug, idInBook: hadith.idInBook)
    }

    private var noteText: String? {
        userData.note(slug: book.slug, idInBook: hadith.idInBook)
    }

    /// The hadith's position WITHIN its chapter ("1 -" for the first hadith of a chapter that starts
    /// at #100), the ayah row's within-surah numbering. The chapter's first row was computed when the
    /// pack was built, so this is arithmetic - no scan, and nothing left to memoize (it used to walk
    /// the whole book for the chapter's lowest number, then cache the answer per chapter).
    private var chapterHadithNumber: Int? {
        guard showsChapterPosition else { return nil }
        return HadithStore.shared.cachedBook(book.slug)?.positionInChapter(hadith)
    }

    private var arabicFontSize: CGFloat {
        // Compact rows show the full text, so the type drops to caption scale (+2 keeps the Arabic
        // script legible at that size).
        (compact ? UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2 : settings.hadithArabicFontSize) * fontScale
    }

    private var englishFontSize: CGFloat {
        (compact ? UIFont.preferredFont(forTextStyle: .caption2).pointSize : settings.hadithEnglishFontSize) * fontScale
    }

    /// Which fields confidently contain the query, and - when none does - which single field gets
    /// `guaranteeMatch` so the row still shows at least one highlight (the ayah rows'
    /// `SearchVisibility`, for hadiths). The confident test uses the highlighter's OWN fold, so a
    /// `true` here means the snippet will find a real range. All-false happens legitimately: the
    /// search index folds differently than the highlighter, AI/semantic rows match on meaning rather
    /// than substring, and Ask citations aren't substring matches at all - in every one of those a
    /// searched row must still mark SOMETHING, exactly like the Quran's ayah results.
    private struct SearchVisibility {
        var mArabic = false
        var mNarrator = false
        var mText = false
        var guaranteeArabic = false
        var guaranteeNarrator = false
        var guaranteeText = false
    }

    private func searchVisibility(text: (arabic: String, narrator: String, text: String)) -> SearchVisibility {
        var v = SearchVisibility()
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return v }
        // A bare-citation query ("10", "8a") is a hadith NUMBER: the number is the row's identity,
        // not a text match (the BY NUMBER sections' rule) - forcing a closest-word span for "10"
        // would paint noise.
        guard HadithBookData.citationNumber(inQuery: trimmed) == nil else { return v }
        let normalizedTerm = HighlightedSnippet.normalizeForSearchText(searchText, trimWhitespace: true)
        guard !normalizedTerm.isEmpty else { return v }

        v.mArabic = HighlightedSnippet.foldedSourceMatches(
            HighlightedSnippet.cachedNormalizedSource(for: text.arabic), normalizedTerm: normalizedTerm
        )
        v.mNarrator = HighlightedSnippet.foldedSourceMatches(
            HighlightedSnippet.cachedNormalizedSource(for: text.narrator), normalizedTerm: normalizedTerm
        )
        v.mText = HighlightedSnippet.foldedSourceMatches(
            HighlightedSnippet.cachedNormalizedSource(for: text.text), normalizedTerm: normalizedTerm
        )
        guard !(v.mArabic || v.mNarrator || v.mText) else { return v }

        // Nothing confident: the query's script picks the field that carries the guaranteed span.
        if searchText.containsArabicLetters, !text.arabic.isEmpty {
            v.guaranteeArabic = true
        } else if !text.text.isEmpty {
            v.guaranteeText = true
        } else if !text.narrator.isEmpty {
            v.guaranteeNarrator = true
        } else if !text.arabic.isEmpty {
            v.guaranteeArabic = true
        }
        return v
    }

    /// Cross-language word highlight, for a corpus with NO word-alignment data: an Arabic query also
    /// lights the aligned English words in the narrator/body lines, and an English query lights the
    /// Arabic words - matched through the lexicon the Quran's word-by-word pack yields
    /// (`CrossLanguageWordHighlight`). Classical Arabic vocabulary overlaps heavily between the Quran
    /// and the hadith corpus; a word the Quran never uses simply highlights nothing.
    ///
    /// Runs for BOTH retrieval kinds - the AI (semantic) hits and the keyword hits - because it keys
    /// off the QUERY and the row's own text, never off which lane produced the row.
    private func crossLanguageSpans(text: (arabic: String, narrator: String, text: String))
    -> (arabic: [NSRange], narrator: [NSRange], text: [NSRange]) {
        Self.crossLanguageSpans(query: searchText, text: text)
    }

    /// The search pipelines call this from their detached prewarm for the hits about to render, so
    /// the row body's own call is a cache hit (`CrossLanguageWordHighlight` caches per query + text).
    /// Pure string work over thread-safe caches - safe off the main actor.
    nonisolated static func prewarmCrossLanguageSpans(query: String, text: (arabic: String, narrator: String, text: String)) {
        _ = crossLanguageSpans(query: query, text: text)
    }

    nonisolated private static func crossLanguageSpans(query searchText: String, text: (arabic: String, narrator: String, text: String))
    -> (arabic: [NSRange], narrator: [NSRange], text: [NSRange]) {
        #if HAS_QURAN
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              HadithBookData.citationNumber(inQuery: trimmed) == nil,
              WordByWordStore.isBundled else { return ([], [], []) }

        if trimmed.containsArabicLetters {
            let terms = CrossLanguageWordHighlight.englishTermsForUnalignedArabicQuery(trimmed)
            guard !terms.isEmpty else { return ([], [], []) }
            return ([],
                    CrossLanguageWordHighlight.wordSpans(of: terms, in: text.narrator),
                    CrossLanguageWordHighlight.wordSpans(of: terms, in: text.text))
        } else {
            return (CrossLanguageWordHighlight.arabicSpansForEnglishQuery(trimmed, arabicText: text.arabic), [], [])
        }
        #else
        return ([], [], [])
        #endif
    }

    var body: some View {
        RenderCounter.hit(compact ? "HadithRow.compact" : "HadithRow")
        // One block-cache lookup for all three strings. `hadith.arabic`/`hadith.english` are each a
        // full trip into the (locked) block cache; this body used to make six of those per pass,
        // which is also lock traffic contended against any detached search sweep.
        let text = hadith.allText
        // One block-cache lookup, same rule as `allText`.
        let grades = hadith.grades
        let visibility = searchVisibility(text: text)
        let cross = crossLanguageSpans(text: text)
        // Decided once per body: `hadithArabicFont(for:)` and `hadithArabicUsesCustomFace(for:)`
        // each walk the Arabic's grapheme count, and the body asked twice.
        // Length-blind now: a long narration renders in chunks (`HadithArabicText`) or, clamped, as a
        // prefix (`HadithArabicChunks.preview`), so the chosen face always applies.
        let arabicUsesCustomFace = settings.hadithArabicWantsCustomFace
        let arabicFont: Font = arabicUsesCustomFace
            ? Font.arabic(settings.nonQuranArabicFontName, size: arabicFontSize)
            : .system(size: arabicFontSize)
        // A search result shows the stretch around its first match (nil: short enough to show whole,
        // or not a search result). The spans are the ones a snippet of the WHOLE text would paint,
        // re-based onto the window, so the highlight survives the cut. The Arabic is windowed only
        // when the match is IN it; otherwise it keeps its opening, clamped to two lines.
        let isSearchResult = compact && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        // A bare number is the row's identity, not a text match (see `searchVisibility`): its digits
        // inside a narration are no anchor, so such a row shows its opening.
        let anchorTerm = HadithBookData.citationNumber(inQuery: searchText) == nil ? searchText : ""
        let arabicCarriesMatch = visibility.mArabic || visibility.guaranteeArabic || !cross.arabic.isEmpty
        let arabicWindow = isSearchResult && arabicCarriesMatch
            ? HadithSearchSnippet.window(
                of: text.arabic,
                spans: HighlightedSnippet.matchSpans(in: text.arabic, term: anchorTerm, guaranteeMatch: visibility.guaranteeArabic) + cross.arabic,
                length: HadithSearchSnippet.arabicLength)
            : nil
        let englishWindow = isSearchResult
            ? HadithSearchSnippet.window(
                of: text.text,
                spans: HighlightedSnippet.matchSpans(in: text.text, term: anchorTerm, guaranteeMatch: visibility.guaranteeText) + cross.text,
                length: HadithSearchSnippet.englishLength)
            : nil
        return VStack(alignment: .leading, spacing: compact ? 5 : 10) {
            HStack(spacing: 8) {
                // ONE glass capsule (the ayah row's "S:A" pill language): the hadith's position WITHIN
                // its chapter first, then the book-wide citation - "3 - 102 Sahih al-Bukhari" is the
                // 3rd hadith of a chapter that starts at #100. Tinted when bookmarked, and tapping it
                // toggles the bookmark, exactly like the ayah pill.
                HStack(spacing: 5) {
                    if let chapterNumber = chapterHadithNumber {
                        Text("\(chapterNumber)")
                            .font((compact ? Font.caption2 : .subheadline).monospacedDigit().weight(.semibold))

                        Text("-")
                            .font((compact ? Font.caption2 : .caption).weight(.semibold))
                            .opacity(0.55)
                    }

                    Text(hadith.displayNumber)
                        .font((compact ? Font.caption2 : .subheadline).monospacedDigit().weight(.semibold))

                    Text(book.englishTitle)
                        .font((compact ? Font.caption2 : .caption).weight(.semibold))
                }
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, compact ? 6 : 8)
                .frame(height: compact ? 22 : 28)
                .conditionalGlassEffect(
                    useColor: isBookmarked ? 0.3 : nil,
                    customTint: isBookmarked ? settings.accentColor.color : nil,
                    interactive: false
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { userData.toggleBookmarkOrConfirm(book: book, hadith: hadith) }
                }
                // The ayah pill's badge grammar: the bookmark badge when bookmarked (the tinted pill
                // plus this corner mark IS the bookmarked state - the actions button no longer morphs),
                // else the book badge for the last-read spot.
                .overlay(alignment: .topTrailing) {
                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(settings.accentColor.color)
                            .padding(4)
                            .offset(x: 8, y: -6)
                    } else if isLastRead {
                        Image(systemName: "book.fill")
                            .font(.caption2)
                            .foregroundStyle(settings.accentColor.color)
                            .padding(4)
                            .offset(x: 8, y: -6)
                    }
                }

                Spacer(minLength: 0)

                // The context menu, reachable without a long-press - the AyahRow actions button's exact
                // sizing (icon in a glass square matching the pill's height). Always the ellipsis:
                // bookmark state lives on the pill (tint + corner badge), the Quran rows' grammar.
                Menu {
                    menuContent
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: compact ? 19 : 25, height: compact ? 19 : 25)
                        .foregroundColor(settings.accentColor.color)
                        .conditionalGlassEffect()
                        .frame(width: compact ? 22 : 28, height: compact ? 22 : 28)
                        .contentShape(Rectangle())
                }
            }

            // A field that matched (or carries the guaranteed span) is forced visible even when its
            // toggle is off - a searched row must never hide the very text that matched, the ayah
            // rows' `showArabicLine` rule.
            if compact || settings.showHadithArabic || visibility.mArabic || visibility.guaranteeArabic
                || !cross.arabic.isEmpty, !text.arabic.isEmpty {
                Group {
                if !compact, HadithArabicChunks.needed(text.arabic) {
                    // The longest narrations, in the chosen face: sentence-bounded chunks, each short
                    // enough for the KFGQPC faces to shape (see `HadithArabicChunks`).
                    HadithArabicText(
                        text: text.arabic,
                        term: searchText,
                        font: arabicFont,
                        lineSpacing: 6,
                        guaranteeMatch: visibility.guaranteeArabic,
                        extraHighlightRanges: cross.arabic
                    )
                } else {
                HighlightedSnippet(
                    // A clamped row shows two lines, so a giant narration's opening is all it needs,
                    // and the opening is short enough for the chosen face.
                    source: arabicWindow?.text ?? (compact ? HadithArabicChunks.preview(text.arabic) : text.arabic),
                    // A window arrives with its spans already worked out over the whole narration.
                    term: arabicWindow == nil ? searchText : "",
                    font: arabicFont,
                    accent: settings.accentColor.color,
                    fg: .primary,
                    // A result whose match is in the English keeps the Arabic's opening, two lines of it.
                    lineLimit: isSearchResult && !arabicCarriesMatch ? 2 : nil,
                    highlightAllahNames: settings.highlightAllahNamesHadith,
                    guaranteeMatch: arabicWindow == nil && visibility.guaranteeArabic,
                    // The classical faces draw "،" as an ornament circle - commas fall back to the
                    // system face.
                    extraHighlightRanges: arabicWindow?.spans ?? cross.arabic
                )
                .arabicFontDesign(custom: arabicUsesCustomFace)
                .multilineTextAlignment(.trailing)
                .lineSpacing(compact ? 0 : 6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                }
                }
                .fixedSize(horizontal: false, vertical: true)
            }

            // Cross-language spans FORCE the English block visible too: an Arabic hit whose aligned
            // English words were found must show them even with the English toggle off.
            if compact || settings.showHadithEnglish || visibility.mNarrator || visibility.mText
                || visibility.guaranteeNarrator || visibility.guaranteeText
                || !cross.narrator.isEmpty || !cross.text.isEmpty {
                // The narrator is PART of the English text - it shows whenever English does (there is no
                // separate toggle; a hadith without its isnad line reads incomplete).
                if !text.narrator.isEmpty {
                    HighlightedSnippet(
                        source: text.narrator,
                        term: searchText,
                        font: .system(size: englishFontSize).italic(),
                        accent: settings.accentColor.color,
                        fg: .secondary,
                        // The narrator line is English text like any other - "Allah's Messenger" in an
                        // isnad gets the same red as the body, both scripts, like the Quran.
                        highlightAllahNames: settings.highlightAllahNamesHadith,
                        guaranteeMatch: visibility.guaranteeNarrator,
                        extraHighlightRanges: cross.narrator
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                }

                if !text.text.isEmpty {
                    HighlightedSnippet(
                        source: englishWindow?.text ?? text.text,
                        term: englishWindow == nil ? searchText : "",
                        font: .system(size: englishFontSize),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        highlightAllahNames: settings.highlightAllahNamesHadith,
                        guaranteeMatch: englishWindow == nil && visibility.guaranteeText,
                        extraHighlightRanges: englishWindow?.spans ?? cross.text
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            // The scholar verdicts, sunnah.com's way - under the text, above the note. Deliberately
            // OUTSIDE the Arabic/English blocks above: the grading is part of the hadith, not a
            // display preference, so it renders whenever the hadith has grades - including with both
            // display toggles off.
            HadithGradeLine(grades: grades, font: compact ? .caption2 : .footnote)

            // The bookmark's note, shown in the reading row exactly like a noted ayah - quiet, under the text.
            if !compact, let note = noteText {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundStyle(settings.accentColor.color)

                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, compact ? 2 : 4)
        .contextMenu { menuContent }
        // The ayah rows' swipes (2026-09-21): bookmark on the leading edge, copy and share on the
        // trailing one. Inert outside a List (the standalone cards), harmless there.
        .swipeActions(edge: .leading) {
            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) { userData.toggleBookmarkOrConfirm(book: book, hadith: hadith) }
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
            }
            .tint(settings.accentColor.color)
        }
        .swipeActions(edge: .trailing) {
            Button {
                settings.hapticFeedback()
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .tint(settings.accentColor.color)

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = HadithShareSheet.composedText(book: book, hadith: hadith)
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .tint(.secondary)
        }
        .sheet(isPresented: $showShareSheet) {
            HadithShareSheet(book: book, hadith: hadith)
                .smallMediumSheetPresentation()
        }
        .sheet(isPresented: $showSelectTextSheet) {
            SelectHadithTextSheet(book: book, hadith: hadith)
                .smallMediumSheetPresentation()
        }
        #if os(iOS) && canImport(FoundationModels)
        .sheet(isPresented: $showSummarize) {
            // Single-source: one narration, not a set of editions, so no `multiSource` and no
            // gatherer - the text is already in hand. Follow-up questions re-ground on this same
            // narration, which is what keeps the answers about THIS hadith.
            SummarizeSheet(
                title: reference,
                sourceText: summarizeSource,
                excludedNote: summarizeExcludedNote
            )
        }
        #endif
        .sheet(isPresented: $showNoteSheet) {
            // The ayah note editor, for a hadith: same sheet, same respect check, saved onto the bookmark.
            NoteEditorSheet(
                title: "Note for \(reference)",
                text: $noteDraft,
                onAttemptSave: { text in
                    if textContainsProfanity(text) {
                        showRespectAlert = true
                        return false
                    }
                    withAnimation(.easeInOut) {
                        userData.setNote(book: book, hadith: hadith, note: text)
                    }
                    return true
                },
                onCancel: {},
                onSave: {}
            )
            .smallMediumSheetPresentation()
        }
        .confirmationDialog("Note not saved", isPresented: $showRespectAlert, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text("Please keep notes Islamic and respectful.")
        }
    }

    /// One menu, two entrances: the long-press context menu and the row's ellipsis button.
    @ViewBuilder
    private var menuContent: some View {
        Text(reference)
            .foregroundStyle(.secondary)

        // The AyahRow menu's exact grammar: Bookmark, then the note actions, a divider, then Copy and
        // Share (in that order) - so the two rows read as one system.
        if isBookmarked {
            Button(role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    userData.toggleBookmarkOrConfirm(book: book, hadith: hadith)
                }
            } label: {
                Label("Remove Bookmark", systemImage: "bookmark.fill")
            }
        } else {
            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    userData.toggleBookmarkOrConfirm(book: book, hadith: hadith)
                }
            } label: {
                Label("Bookmark Hadith", systemImage: "bookmark")
            }
        }

        Button {
            settings.hapticFeedback()
            noteDraft = noteText ?? ""
            showNoteSheet = true
        } label: {
            Label(noteText == nil ? "Add Note" : "Edit Note", systemImage: "note.text")
        }

        if noteText != nil {
            Button(role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    userData.removeNote(slug: book.slug, idInBook: hadith.idInBook)
                }
            } label: {
                Label("Remove Note", systemImage: "minus.circle")
            }
        }

        Divider()

        // The ayah rows' Select Text (2026-09-21): the narration lifted into a sheet where a drag
        // selects text instead of fighting the list for the scroll.
        Button {
            settings.hapticFeedback()
            showSelectTextSheet = true
        } label: {
            Label("Select Text", systemImage: "highlighter")
        }

        // ONE share surface and ONE copy, both driven by the same composition options - the pile of
        // per-field copy actions collapsed into the Share Hadith sheet.
        Button {
            settings.hapticFeedback()
            UIPasteboard.general.string = HadithShareSheet.composedText(book: book, hadith: hadith)
        } label: {
            Label("Copy Hadith", systemImage: "doc.on.doc")
        }

        Button {
            settings.hapticFeedback()
            showShareSheet = true
        } label: {
            Label("Share Hadith", systemImage: "square.and.arrow.up")
        }

        #if os(iOS) && canImport(FoundationModels)
        // The availability check is INSIDE the menu, the pattern every other OnDeviceAsk entry
        // point uses: the row is simply absent on a device without Apple Intelligence rather than
        // present and dead. Last in the menu because it is the only item that leaves the screen.
        if OnDeviceAsk.isAvailable, canSummarize {
            Divider()

            Button {
                settings.hapticFeedback()
                showSummarize = true
            } label: {
                Label("Summarize with AI", systemImage: "text.append")
            }
        }
        #endif
    }
}

/// The hadith searches' recent-queries chips over the shared hadith history: the tab root and the
/// book view both show these inside the search-help card that floats over the list while the field
/// is focused and empty. Picking one re-runs it (and bumps it to the front), the ✕ forgets it.
struct HadithRecentSearches: View {
    @ObservedObject private var settings = Settings.shared
    @Binding var searchText: String

    var body: some View {
        RecentSearchChips(
            queries: settings.hadithSearchHistory,
            onPick: { query in
                withAnimation {
                    searchText = query
                    settings.addHadithSearchHistory(query)
                }
                endEditing()
            },
            onRemove: { settings.removeHadithSearchHistory($0) }
        )
    }
}

// MARK: - Search-result snippets

/// The stretch of a narration a compact search row shows: about `length` UTF-16 units around the
/// first match, opened at the sentence the match is in when that sentence starts close by, closed at
/// a sentence end when one is near and at a word otherwise, with "\u{2026}" on each side that was cut.
/// The text itself is never touched: the window is a slice of it, and the ellipses sit outside.
enum HadithSearchSnippet {
    struct Window {
        let text: String
        /// The highlight spans that fall inside the window, re-based onto `text` (UTF-16).
        let spans: [NSRange]
    }

    static let englishLength = 220
    /// Longer in units, not on screen: vocalized Arabic spends nearly a unit on marks per letter.
    static let arabicLength = 320
    /// How far back a sentence start may sit and still open the window.
    private static let sentenceReach = 120
    /// What stays in front of the match when its sentence started further back than that.
    private static let lead = 70

    private static let sentenceEnds: Set<unichar> = [0x2E, 0x21, 0x3F, 0x0A, 0x061F, 0x06D4]
    private static let whitespace: Set<unichar> = [0x20, 0x0A, 0x09, 0x0D, 0xA0]
    /// What may trail a sentence end before the next sentence begins: closing quotes and brackets.
    private static let closers: Set<unichar> = [0x22, 0x27, 0x29, 0x5D, 0x201D, 0x2019, 0xBB]

    /// Nil when the text is short enough to show whole (the caller keeps its ordinary path).
    /// `spans` are UTF-16 ranges over `source`, in any order; the earliest one is the anchor. With no
    /// span at all (a meaning match) the window is the opening.
    static func window(of source: String, spans: [NSRange], length: Int) -> Window? {
        let text = source as NSString
        let total = text.length
        guard total > length + 60 else { return nil }
        let valid = spans.filter { $0.location >= 0 && $0.length > 0 && NSMaxRange($0) <= total }
            .sorted { $0.location < $1.location }
        let anchorStart = valid.first?.location ?? 0
        let anchorEnd = valid.first.map(NSMaxRange) ?? 0

        var start = 0
        if anchorStart > lead {
            start = sentenceStart(in: text, before: anchorStart)
                ?? wordStart(in: text, from: anchorStart - lead, before: anchorStart)
        }
        while start < anchorStart, whitespace.contains(text.character(at: start)) { start += 1 }
        var end = min(total, max(start + length, anchorEnd))
        if end < total {
            let earliest = max(anchorEnd, start + length * 3 / 5)
            end = sentenceEnd(in: text, from: earliest, to: min(total, start + length + 60))
                ?? wordEnd(in: text, from: end, after: max(anchorEnd, start + 1))
        } else if start > 0, end - start < length {
            // The match sits near the end: spend the unused length in front of it.
            start = min(start, wordStart(in: text, from: max(0, total - length), before: start))
        }
        guard start > 0 || end < total else { return nil }

        // Every cut above lands on whitespace or a sentence mark; this only matters for a text with
        // neither in reach, where a cut must still not split a letter from its marks.
        let cut = text.rangeOfComposedCharacterSequences(for: NSRange(location: start, length: max(0, end - start)))
        var slice = text.substring(with: cut)
        while let last = slice.unicodeScalars.last, CharacterSet.whitespacesAndNewlines.contains(last) {
            slice.unicodeScalars.removeLast()
        }
        let opens = cut.location > 0
        let closes = NSMaxRange(cut) < total
        let shown = NSRange(location: cut.location, length: (slice as NSString).length)
        // A paragraph takes its direction from its first strong character. A window into an English
        // narration that happens to open at ﷺ (an Arabic-script character) laid the whole English
        // passage out right to left, punctuation flipped. When the window's first strong character
        // disagrees with the full text's, an invisible mark restores the text's own direction.
        let mark: String = {
            guard let whole = firstStrongIsRTL(source), let part = firstStrongIsRTL(slice), whole != part else { return "" }
            return whole ? "\u{200F}" : "\u{200E}"
        }()
        let head = mark + (opens ? "\u{2026}" : "")
        let shift = cut.location - (head as NSString).length
        let rebased: [NSRange] = valid.compactMap { span in
            let clipped = NSIntersectionRange(span, shown)
            return clipped.length > 0 ? NSRange(location: clipped.location - shift, length: clipped.length) : nil
        }
        // A window that closes on a finished sentence sets its ellipsis off with a space: "debt. …"
        // says more follows, where "debt.…" read as a typo.
        let endsSentence = (slice as NSString).length > 0 && {
            let last = (slice as NSString).character(at: (slice as NSString).length - 1)
            return sentenceEnds.contains(last) || closers.contains(last)
        }()
        let tail = closes ? (endsSentence ? " \u{2026}" : "\u{2026}") : ""
        return Window(text: head + slice + tail, spans: rebased)
    }

    /// Nil when the text has no letter at all.
    private static func firstStrongIsRTL(_ text: String) -> Bool? {
        for scalar in text.unicodeScalars {
            let value = scalar.value
            // The honorific ligatures (ﷺ and its neighbours) are symbols, not letters, yet they are
            // strongly right-to-left, and they are exactly what opens these windows.
            if (0xFDF0...0xFDFD).contains(value) { return true }
            guard scalar.properties.isAlphabetic else { continue }
            return (0x0590...0x08FF).contains(value) || (0xFB1D...0xFDFF).contains(value) || (0xFE70...0xFEFF).contains(value)
        }
        return nil
    }

    /// Where the sentence holding `location` begins, when that is within `sentenceReach` of it.
    private static func sentenceStart(in text: NSString, before location: Int) -> Int? {
        let floor = max(0, location - sentenceReach)
        var index = location - 1
        while index >= floor {
            if sentenceEnds.contains(text.character(at: index)) {
                var next = index + 1
                while next < location, closers.contains(text.character(at: next)) { next += 1 }
                // A full stop inside a word or a number ("3.5") is not a sentence end; a line break always is.
                let isLineBreak = text.character(at: index) == 0x0A
                if isLineBreak || (next < location && whitespace.contains(text.character(at: next))) {
                    while next < location, whitespace.contains(text.character(at: next)) { next += 1 }
                    return next
                }
            }
            index -= 1
        }
        return floor == 0 ? 0 : nil
    }

    /// The first sentence end in `from..<to`, as the index just past it (closers included).
    private static func sentenceEnd(in text: NSString, from: Int, to: Int) -> Int? {
        guard from < to else { return nil }
        var index = from
        while index < to {
            if sentenceEnds.contains(text.character(at: index)) {
                var next = index + 1
                while next < text.length, closers.contains(text.character(at: next)) { next += 1 }
                if next >= text.length || whitespace.contains(text.character(at: next)) { return next }
            }
            index += 1
        }
        return nil
    }

    /// The first word start at or after `from` (never past `limit`).
    private static func wordStart(in text: NSString, from: Int, before limit: Int) -> Int {
        guard from > 0 else { return 0 }
        var index = from
        while index < limit, !whitespace.contains(text.character(at: index - 1)) { index += 1 }
        return min(index, limit)
    }

    /// The last word end at or before `from`; `from` itself when no word ends after `floor`.
    private static func wordEnd(in text: NSString, from: Int, after floor: Int) -> Int {
        var index = min(from, text.length - 1)
        while index > floor, !whitespace.contains(text.character(at: index)) { index -= 1 }
        return index > floor ? index : from
    }
}

// MARK: - Long narrations in the custom face

/// A long Arabic narration cut into pieces the custom faces shape correctly.
///
/// The KFGQPC faces drop contextual shaping when ONE `Text` lays out a very long string (every letter
/// draws isolated, the "shattered Arabic" of the longest narrations). Falling back to the system face
/// past a length cliff kept the letters joined and threw the hadith font away, which is the wrong
/// trade for a reading screen. The text is instead split at sentence boundaries into runs under
/// `Settings.hadithArabicChunkLimit` characters, each rendered as its own `Text` in the chosen face:
/// a break between two sentences changes nothing a reader sees, and each run is short enough to shape.
/// Highlight spans that were computed over the whole string are re-based onto the chunk they fall in.
enum HadithArabicChunks {
    struct Chunk: Identifiable {
        let index: Int
        let text: String
        /// The chunk's start in the source, in UTF-16 units (what `NSRange` counts).
        let utf16Offset: Int
        var id: Int { index }
    }

    /// Where a sentence may end: the Arabic full stop and comma, the semicolon and question mark, the
    /// Latin full stop, and a line break.
    private static let boundaries: Set<Character> = [".", "\u{06D4}", "\u{060C}", "\u{061B}", "\u{061F}", "\n", "\u{06D6}"]

    static func needed(_ text: String) -> Bool {
        text.count >= Settings.arabicShapingCharacterLimit
    }

    /// The splits of the narrations on screen, keyed by the text's hash and length (a hadith's
    /// Arabic is immutable): `HadithArabicText` used to walk every character of a long narration on
    /// every body evaluation. Thread-safe, bounded, dropped under a memory warning.
    private final class ChunkList {
        let chunks: [Chunk]
        init(_ chunks: [Chunk]) { self.chunks = chunks }
    }
    nonisolated(unsafe) private static let splitCache: NSCache<NSString, ChunkList> = {
        let cache = NSCache<NSString, ChunkList>()
        cache.countLimit = 300
        return cache
    }()

    static func purgeCache() {
        splitCache.removeAllObjects()
    }

    /// The whole text as one chunk when it is short enough; sentence-bounded runs otherwise.
    static func split(_ text: String, limit: Int = Settings.hadithArabicChunkLimit) -> [Chunk] {
        guard needed(text) else { return [Chunk(index: 0, text: text, utf16Offset: 0)] }
        let key = "\(text.hashValue):\(text.utf8.count):\(limit)" as NSString
        if let cached = splitCache.object(forKey: key) { return cached.chunks }
        let chunks = computeSplit(text, limit: limit)
        splitCache.setObject(ChunkList(chunks), forKey: key)
        return chunks
    }

    private static func computeSplit(_ text: String, limit: Int) -> [Chunk] {
        var chunks: [Chunk] = []
        var start = text.startIndex
        var lastBoundary: String.Index?
        var count = 0
        var index = text.startIndex
        func emit(upTo end: String.Index) {
            let piece = String(text[start..<end])
            chunks.append(Chunk(index: chunks.count, text: piece,
                                utf16Offset: text.utf16.distance(from: text.utf16.startIndex, to: start)))
            start = end
            count = 0
            lastBoundary = nil
        }
        while index < text.endIndex {
            let character = text[index]
            count += 1
            if boundaries.contains(character) {
                lastBoundary = text.index(after: index)
            }
            if count >= limit {
                // Cut at the last sentence end inside the run, else at the last space, else here.
                let cut = lastBoundary
                    ?? text[start..<index].lastIndex(where: { $0 == " " }).map { text.index(after: $0) }
                    ?? text.index(after: index)
                emit(upTo: cut)
                index = cut
                continue
            }
            index = text.index(after: index)
        }
        if start < text.endIndex { emit(upTo: text.endIndex) }
        return chunks
    }

    /// The spans of `ranges` (UTF-16, over the whole text) that fall inside `chunk`, re-based to it.
    static func ranges(_ ranges: [NSRange], in chunk: Chunk) -> [NSRange] {
        guard !ranges.isEmpty else { return [] }
        let length = chunk.text.utf16.count
        let chunkRange = NSRange(location: chunk.utf16Offset, length: length)
        return ranges.compactMap { range in
            let clipped = NSIntersectionRange(range, chunkRange)
            guard clipped.length > 0 else { return nil }
            return NSRange(location: clipped.location - chunk.utf16Offset, length: clipped.length)
        }
    }

    /// The opening of a narration for a clamped preview (two lines of it are shown): short enough for
    /// the custom face, cut at a word. Cheap already (a prefix walk), so not memoized.
    static func preview(_ text: String, limit: Int = Settings.hadithArabicChunkLimit) -> String {
        guard needed(text) else { return text }
        let head = text.prefix(limit)
        if let space = head.lastIndex(of: " ") { return String(head[..<space]) }
        return String(head)
    }
}

/// The full Arabic of a hadith in the reading surfaces: one `HighlightedSnippet` per chunk (see
/// `HadithArabicChunks`), all in the chosen face, stacked with the paragraph spacing of a single text.
struct HadithArabicText: View {
    @ObservedObject private var settings = Settings.shared

    let text: String
    let term: String
    let font: Font
    let lineSpacing: CGFloat
    var guaranteeMatch: Bool = false
    var extraHighlightRanges: [NSRange] = []

    var body: some View {
        let chunks = HadithArabicChunks.split(text)
        let custom = settings.hadithArabicWantsCustomFace
        VStack(alignment: .trailing, spacing: lineSpacing) {
            ForEach(chunks) { chunk in
                HighlightedSnippet(
                    source: chunk.text,
                    term: term,
                    font: font,
                    accent: settings.accentColor.color,
                    fg: .primary,
                    highlightAllahNames: settings.highlightAllahNamesHadith,
                    // Only the first chunk carries the guarantee: forcing a paint on every piece would
                    // mark a run the term is not in.
                    guaranteeMatch: guaranteeMatch && chunk.index == 0 && chunks.count == 1,
                    extraHighlightRanges: HadithArabicChunks.ranges(extraHighlightRanges, in: chunk)
                )
                .arabicFontDesign(custom: custom)
                .multilineTextAlignment(.trailing)
                .lineSpacing(lineSpacing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Hadith Arabic in the Islam face, trailing - with commas falling back to the system face (the
/// classical faces draw "\u{060C}" as an ornament circle). Every preview row renders through this so
/// bookmarks, Hadith of the Day, Last Read, and the summary tiles all match the reader.
///
/// Clamped with the space RESERVED (two lines by default; callers pass four when this is the card's
/// only language): a short hadith and a long one produce the same card height, so a bookmark grid and
/// a stack of daily rows line up instead of stair-stepping. The English half of each card reserves
/// its lines the same way (`reservedLineLimit`).
struct HadithArabicPreview: View {
    @ObservedObject private var settings = Settings.shared

    let text: String
    var size: CGFloat = 15
    var lineLimit: Int = 2

    var body: some View {
        HighlightedSnippet(
            // A clamped card shows two lines, so a giant narration's opening is all it needs, and the
            // opening is short enough for the chosen face to shape (see `HadithArabicChunks`).
            source: HadithArabicChunks.preview(text),
            term: "",
            font: settings.useFontArabic
                ? (settings.hadithArabicWantsCustomFace ? Font.arabic(settings.nonQuranArabicFontName, size: size) : .system(size: size))
                : .footnote,
            accent: settings.accentColor.color,
            fg: .primary,
            // The clamp must ride INSIDE the snippet: it applies `.lineLimit` to its own Text, and the
            // innermost value wins - an outer `.reservedLineLimit` here was silently ignored.
            lineLimit: lineLimit,
            reservesSpace: true
        )
        .arabicFontDesign(custom: settings.hadithArabicWantsCustomFace)
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

/// The Quran search's Load More card, for hadith matches: a menu offering 5/10/20 more and a
/// load-all row beneath it (see `LoadMoreControls`). Shared by the tab root, the book view and the
/// chapter view.
struct HadithLoadMoreControls: View {
    let label: String
    let hasMore: Bool
    @Binding var limit: Int

    var body: some View {
        if hasMore {
            LoadMoreControls(
                label: label,
                onLoad: { limit += $0 },
                onLoadAll: { limit = Int.max }
            )
        }
    }
}

// MARK: - Bookmark rows (Quran-style one-line previews) + the full list

/// A bookmarked hadith row in the Quran-bookmark format: reference, ONE line of Arabic (trailing), ONE
/// line of English - never the narrator. Opens the hadith through the reference resolver.
/// The bookmarked-hadith menu and every sheet it opens, in one place so the LIST row and the GRID
/// tile offer exactly the same actions (Abu, 2026-09-19: press-and-hold should work on tiles too).
///
/// `gridTileAction` decides the entrance: nil gives the row a `contextMenu`; non-nil wraps the tile in
/// a `GridTileMenu`, whose tap runs the action and whose long press opens the menu - a `contextMenu`
/// in a grid lifts the whole List row (every tile at once) as its preview.
struct HadithBookmarkMenu: ViewModifier {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var userData = HadithUserData.shared

    let bookmark: HadithBookmark
    let book: HadithCatalogBook
    var gridTileAction: (() -> Void)? = nil

    @State private var showNoteSheet = false
    @State private var noteDraft = ""
    @State private var showRespectAlert = false
    @State private var shareHadith: HadithBookData.Hadith? = nil

    /// Removal and note-setting only need the identity fields; the store matches on slug + idInBook.
    private var placeholderHadith: HadithBookData.Hadith {
        HadithBookData.Hadith(
            id: -1, idInBook: bookmark.idInBook, chapterId: bookmark.chapterId ?? -1,
            arabic: "", english: HadithBookData.Hadith.EnglishText(narrator: "", text: "")
        )
    }

    /// The bookmarked hadith's full row from its book pack - opening a book is synchronous and cheap
    /// (mapped, not read), so resolving on menu tap is fine. Nil only if the pack is missing.
    private var fullHadith: HadithBookData.Hadith? {
        HadithStore.shared.book(book)?.hadith(numbered: bookmark.idInBook)
    }

    @ViewBuilder
    private var menuItems: some View {
        // HadithRow's menu grammar exactly - reference, bookmark, note actions, a divider,
        // then Copy and Share - so a bookmarked hadith's menu reads like every hadith's menu.
        Text(bookmark.reference)
            .foregroundStyle(.secondary)

        Button(role: .destructive) {
            settings.hapticFeedback()
            userData.toggleBookmarkOrConfirm(book: book, hadith: placeholderHadith, reference: bookmark.reference)
        } label: {
            Label("Remove Bookmark", systemImage: "bookmark.fill")
        }

        Button {
            settings.hapticFeedback()
            noteDraft = bookmark.note ?? ""
            showNoteSheet = true
        } label: {
            Label(bookmark.note == nil ? "Add Note" : "Edit Note", systemImage: "note.text")
        }

        if bookmark.note != nil {
            Button(role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    userData.removeNote(slug: bookmark.slug, idInBook: bookmark.idInBook)
                }
            } label: {
                Label("Remove Note", systemImage: "minus.circle")
            }
        }

        Divider()

        Button {
            settings.hapticFeedback()
            if let hadith = fullHadith {
                UIPasteboard.general.string = HadithShareSheet.composedText(book: book, hadith: hadith)
            }
        } label: {
            Label("Copy Hadith", systemImage: "doc.on.doc")
        }

        Button {
            settings.hapticFeedback()
            shareHadith = fullHadith
        } label: {
            Label("Share Hadith", systemImage: "square.and.arrow.up")
        }
    }

    func body(content: Content) -> some View {
        Group {
            if let gridTileAction {
                GridTileMenu(primaryAction: gridTileAction) {
                    menuItems
                } label: {
                    content
                }
            } else {
                content.contextMenu { menuItems }
            }
        }
        .sheet(item: $shareHadith) { hadith in
            HadithShareSheet(book: book, hadith: hadith)
                .smallMediumSheetPresentation()
        }
        .sheet(isPresented: $showNoteSheet) {
            NoteEditorSheet(
                title: "Note for \(bookmark.reference)",
                text: $noteDraft,
                onAttemptSave: { text in
                    if textContainsProfanity(text) {
                        showRespectAlert = true
                        return false
                    }
                    withAnimation(.easeInOut) {
                        userData.setNote(book: book, hadith: placeholderHadith, note: text)
                    }
                    return true
                },
                onCancel: {},
                onSave: {}
            )
            .smallMediumSheetPresentation()
        }
        .confirmationDialog("Note not saved", isPresented: $showRespectAlert, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text("Please keep notes Islamic and respectful.")
        }
    }
}

extension View {
    /// See `HadithBookmarkMenu`.
    func hadithBookmarkMenu(
        bookmark: HadithBookmark,
        book: HadithCatalogBook,
        gridTileAction: (() -> Void)? = nil
    ) -> some View {
        modifier(HadithBookmarkMenu(bookmark: bookmark, book: book, gridTileAction: gridTileAction))
    }
}

struct HadithBookmarkRow: View, Equatable {
    @ObservedObject private var settings = Settings.shared
    /// Bookmark rows render only user marks - observe the user-data object, not the whole store.
    @ObservedObject private var userData = HadithUserData.shared

    let bookmark: HadithBookmark
    /// See `Settings.hadithRenderSettingsSignature` - compared so appearance changes re-render the row.
    var renderSettingsSignature: String = Settings.shared.hadithRenderSettingsSignature

    /// These rows sit on the tab root, which stays alive under pushed screens - so while the user reads
    /// a book, every last-read save republishes the store and re-ran these long-text bodies for nothing.
    /// Note edits arrive through observed `HadithUserData` (bypasses `==`) AND through `bookmark` itself.
    static func == (l: Self, r: Self) -> Bool {
        l.bookmark == r.bookmark && l.renderSettingsSignature == r.renderSettingsSignature
    }

    /// The menu, its note editor and its share sheet all live in `HadithBookmarkMenu` now, so this row
    /// and `HadithBookmarkGridTile` cannot drift apart. The badge tap and the leading swipe below
    /// still need the identity-only hadith the store matches on (slug + idInBook).
    private var placeholderHadith: HadithBookData.Hadith {
        HadithBookData.Hadith(
            id: -1, idInBook: bookmark.idInBook, chapterId: bookmark.chapterId ?? -1,
            arabic: "", english: HadithBookData.Hadith.EnglishText(narrator: "", text: "")
        )
    }

    /// Value link on iOS 16, legacy destination push on iOS 15 - see the note at the call site.
    @ViewBuilder
    private func bookmarkLink<Label: View>(book: HadithCatalogBook, @ViewBuilder label: () -> Label) -> some View {
        if #available(iOS 16.0, *) {
            NavigationLink(value: HadithView.BookRoute.book(slug: book.slug, autoOpenHadithID: bookmark.idInBook)) {
                label()
            }
        } else {
            NavigationLink {
                HadithBookView(book: book, autoOpenHadithID: bookmark.idInBook)
            } label: {
                label()
            }
        }
    }

    var body: some View {
        if let book = HadithCatalogBook.bySlug[bookmark.slug] {
            // Books → Chapters → Hadiths: land in the book, which auto-pushes the hadith's chapter
            // scrolled to it - backing out of the hadith always shows the chapter list. By VALUE on
            // iOS 16 (both hadith containers are NavigationStacks whose `routeDestination` wires the
            // chapter push); a legacy destination push would leave the book's auto-open with no
            // path to append to.
            bookmarkLink(book: book) {
                HStack(spacing: 8) {
                    // The same accent-tinted glass number badge the Quran's bookmarked ayah rows lead
                    // with - and, like theirs, the filled bookmark sits in its corner and tapping the
                    // badge removes the bookmark (after the confirmation every removal asks for).
                    ZStack(alignment: .topTrailing) {
                        Text(bookmark.displayNumber)
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                            .padding(5)
                            .frame(minWidth: 44)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .conditionalGlassEffect(
                                useColor: 0.3,
                                customTint: settings.accentColor.color,
                                interactive: false
                            )
                            .onTapGesture {
                                settings.hapticFeedback()
                                userData.toggleBookmarkOrConfirm(book: book, hadith: placeholderHadith, reference: bookmark.reference)
                            }
                            .accessibilityLabel("Remove bookmark")

                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(settings.accentColor.color)
                            .padding(4)
                            .offset(x: 8, y: -6)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(bookmark.reference)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        // The reading rows' exact visibility rules: Arabic and English previews follow
                        // the same toggles the reader uses, so a bookmark looks like its hadith. Each
                        // enabled slot reserves its own TWO lines whether or not this bookmark has
                        // that language - an empty string still reserves them - so a hadith missing
                        // Arabic or English keeps the same row height as one that has both, and the
                        // list never stair-steps. Giving the surviving language four lines instead
                        // does NOT square them: four Arabic lines are taller than two Arabic plus two
                        // English, and four English lines are shorter.
                        if settings.showHadithArabic {
                            HadithArabicPreview(text: bookmark.arabicPreview ?? "", lineLimit: 2)
                        }

                        if settings.showHadithEnglish {
                            // A bookmark saved by an older build carries only the combined preview.
                            let english = bookmark.englishPreview ?? ""
                            Text(!english.isEmpty ? english : (bookmark.arabicPreview == nil ? bookmark.preview : ""))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .reservedLineLimit(2)
                        } else if bookmark.arabicPreview == nil {
                            // English hidden and nothing else stored: the legacy combined preview is all
                            // this bookmark has, so it shows anyway rather than leaving a blank row.
                            Text(bookmark.preview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .reservedLineLimit(2)
                        }

                        // The bookmark's note - the Quran bookmark rows' quiet one-liner.
                        if let note = bookmark.note, !note.isEmpty {
                            HStack(alignment: .top, spacing: 4) {
                                Image(systemName: "note.text")
                                    .font(.caption2)
                                    .foregroundStyle(settings.accentColor.color)

                                Text(note)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .hadithBookmarkMenu(bookmark: bookmark, book: book)
            // The Quran bookmark rows' leading swipe: the bookmark itself (after the confirmation).
            .swipeActions(edge: .leading) {
                Button {
                    settings.hapticFeedback()
                    userData.toggleBookmarkOrConfirm(book: book, hadith: placeholderHadith, reference: bookmark.reference)
                } label: {
                    Image(systemName: "bookmark.fill")
                }
                .tint(settings.accentColor.color)
            }
        }
    }
}

/// The grid form of a bookmarked hadith - the Quran's bookmark grid tile shape: reference on top,
/// two-line Arabic, two-line English, on clear glass, with the filled bookmark in the top-right corner
/// where tapping it removes the bookmark (after the confirmation) - the ayah tile's corner exactly.
struct HadithBookmarkGridTile: View, Equatable {
    @ObservedObject private var settings = Settings.shared

    let bookmark: HadithBookmark
    let onTap: () -> Void
    /// See `Settings.hadithRenderSettingsSignature` - compared so appearance changes re-render the tile.
    var renderSettingsSignature: String = Settings.shared.hadithRenderSettingsSignature

    /// `onTap` is excluded from `==`: the call site only assigns the bookmark into parent state through
    /// a binding, which stays valid however stale the captured closure is.
    static func == (l: Self, r: Self) -> Bool {
        l.bookmark == r.bookmark && l.renderSettingsSignature == r.renderSettingsSignature
    }

    /// Removal only needs the identity fields; the store matches on slug + idInBook.
    private var placeholderHadith: HadithBookData.Hadith {
        HadithBookData.Hadith(
            id: -1, idInBook: bookmark.idInBook, chapterId: bookmark.chapterId ?? -1,
            arabic: "", english: HadithBookData.Hadith.EnglishText(narrator: "", text: "")
        )
    }

    var body: some View {
        // Press-and-hold gets the row's full menu (`HadithBookmarkMenu`); a tap opens the hadith.
        // Falls back to a plain Button only if the bookmark's book is missing from the catalog.
        Group {
            if let book = HadithCatalogBook.bySlug[bookmark.slug] {
                tile.hadithBookmarkMenu(bookmark: bookmark, book: book, gridTileAction: {
                    settings.hapticFeedback()
                    onTap()
                })
            } else {
                Button {
                    settings.hapticFeedback()
                    onTap()
                } label: {
                    tile
                }
                .buttonStyle(.plain)
            }
        }
        // The Quran bookmark tile's corner: the filled bookmark on the RIGHT, and tapping it is how the
        // tile is unbookmarked. OUTSIDE the menu (like `gridFavoriteStar`) so the corner tap never
        // opens the hadith and never fights the long press.
        .overlay(alignment: .topTrailing) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(settings.accentColor.color)
                // The 30pt target is centered on the glyph and sized BEFORE the corner paddings (the
                // `gridFavoriteStar` fix): a target inflated after them swallowed the tile's right side.
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
                .onTapGesture {
                    settings.hapticFeedback()
                    if let book = HadithCatalogBook.bySlug[bookmark.slug] {
                        HadithUserData.shared.toggleBookmarkOrConfirm(
                            book: book, hadith: placeholderHadith, reference: bookmark.reference
                        )
                    }
                }
                .padding(.top, 1)
                .padding(.trailing, 2)
                .accessibilityLabel("Remove bookmark")
        }
    }

    private var tile: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(bookmark.reference)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    // Leaves the corner clear for the tappable bookmark overlay below.
                    Spacer(minLength: 20)
                }

                // The reader's own visibility toggles apply here exactly as in the bookmark list
                // rows, and each enabled slot reserves its own TWO lines whether or not this bookmark
                // has that language - an empty string still reserves them - so tiles keep their
                // neighbours' height instead of hugging shorter. Four lines for the surviving
                // language does NOT square them: four Arabic lines are taller than two Arabic plus
                // two English, and four English lines are shorter.
                // Old saves carry only `preview`: route it to the slot its SCRIPT belongs in, so an
                // Arabic-only book (Darimi, Ahmad) never lands its Arabic in the English slot with
                // the Arabic slot collapsed above it.
                let legacyIsArabic = bookmark.arabicPreview == nil && bookmark.preview.containsArabicScript
                let arabic = bookmark.arabicPreview ?? (legacyIsArabic ? bookmark.preview : "")
                let english = bookmark.englishPreview
                    ?? ((bookmark.arabicPreview == nil && !legacyIsArabic) ? bookmark.preview : "")

                // A blank slot still reserves its two lines: a single SPACE, never the empty string -
                // an empty Text lays out at zero height whatever `reservesSpace` says, which is exactly
                // how the Arabic-only tiles ended up shorter than their neighbours.
                if settings.showHadithArabic {
                    HadithArabicPreview(text: arabic.isEmpty ? " " : arabic, size: 14, lineLimit: 2)
                }

                if settings.showHadithEnglish {
                    Text(english.isEmpty ? " " : english)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .reservedLineLimit(2)
                }
            }
            // Hug the content - the old fixed 78pt frame left a band of dead space whenever the
            // preview ran short.
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .conditionalGlassEffect(clear: true, rectangle: true)
            .contentShape(Rectangle())
    }
}

// MARK: - Immersive full-screen reading (hadith / chapter / book)

/// Edge-to-edge distraction-free reading: just the hadith text on the system background, with a quiet
/// dismiss control - the hadith counterpart of the Quran's full-screen reading.
struct HadithImmersiveView: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    let title: String
    let book: HadithCatalogBook
    let hadiths: [HadithBookData.Hadith]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    ForEach(hadiths) { hadith in
                        HadithRow(book: book, hadith: hadith)
                            .equatable()
                            .textSelection(.enabled)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        settings.hapticFeedback()
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                    }
                    .accessibilityLabel("Exit full screen")
                    .tint(settings.accentColor.color)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Focus overlay items (the Quran's "View Fullscreen", for hadith books and chapters)

extension FocusItem {
    static func hadithBook(_ book: HadithCatalogBook) -> FocusItem {
        FocusItem(
            id: "hadith-book-\(book.slug)",
            arabic: book.arabicTitle,
            title: "\(book.number) · \(book.englishTitle)",
            subtitle: "\(book.authorEnglish) - \(book.era)",
            shareLabel: "Share Book",
            shareText: """
            \(book.englishTitle) (\(book.arabicTitle))
            \(book.authorEnglish) - \(book.era)
            """
        )
    }

    static func hadithChapter(book: HadithCatalogBook, chapter: HadithBookData.Chapter, ordinal: Int, rangeText: String?) -> FocusItem {
        FocusItem(
            id: "hadith-chapter-\(book.slug)-\(chapter.id)",
            arabic: chapter.arabic.isEmpty ? book.arabicTitle : chapter.arabic,
            title: "\(ordinal) · \(chapter.english.isEmpty ? book.englishTitle : chapter.english)",
            subtitle: book.englishTitle,
            footnote: rangeText,
            shareLabel: "Share Chapter",
            shareText: """
            \(book.englishTitle) - \(chapter.english)\(chapter.arabic.isEmpty ? "" : " (\(chapter.arabic))")\(rangeText.map { "\n\($0)" } ?? "")
            """
        )
    }
}

// MARK: - Share Hadith (custom sheet, image or text - the Share Ayah counterpart)

/// The Share Ayah sheet, for a hadith. Everything structural is mirrored from `ShareAyahSheet`: the
/// big live preview on top (the previous image STAYS on screen, dimmed, while a regeneration runs, so
/// the sheet never jumps), the compact option stack in its own 200pt scroller, the Image/Text
/// segmented picker, and the two glass action buttons feeding a `.sheet`-presented `ActivityView`
/// that only dismisses this sheet after a COMPLETED share. The card itself is drawn with ShareAyah's
/// `drawImage` layout - same rounded system fonts, same 1.15x Arabic scale, same padding/spacing
/// constants, same screen-derived canvas width, same black card at corner radius 20, same
/// logo + app-name watermark - with the hadith's parts (reference, Arabic, narrator, English, grade,
/// note) in place of the ayah's.
struct HadithShareSheet: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.presentationMode) private var presentationMode

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    // What travels with the share - persisted, and shared with Copy Hadith so the two always agree.
    @AppStorage("shareHadithArabic") private var includeArabic = true
    @AppStorage("shareHadithEnglish") private var includeEnglish = true
    @AppStorage("shareHadithReference") private var includeReference = true
    // There is deliberately NO narrator option (user rule, 2026-08-29): the narrator is PART of the
    // English - "my father said, then he went to the Prophet..." is often the sentence the body's
    // "He is greater than us" only makes sense after - so English on means narrator on, always,
    // exactly as the reading rows do it.
    // The Share Ayah sheet's applicable options, for hadith: the Arabic face, tashkeel, and the note.
    @AppStorage("shareHadithFontFace") private var shareFontFaceRaw = ""
    // DEFAULTS to the app-wide Hide Tashkeel, the way the ayah share sheet is seeded
    // (`ContextMenu.swift`). It used to default to `false` and never look at the global, so a
    // reader who had switched Hide Tashkeel on in Settings opened this sheet to find the box
    // unchecked and the diacritics back - one setting, disagreeing with itself in two places.
    //
    // Still `@AppStorage`, deliberately: the key is also read by the static `composedText` below,
    // which is what the context menu's Copy Hadith calls, and that parity is the reason the two
    // produce identical text. An `@AppStorage` default only applies while the key is ABSENT, so
    // this follows the global until the reader touches it here and becomes their own per-share
    // choice afterwards - and `composedText` reads it through the same absent-key fallback.
    @AppStorage("shareHadithHideTashkeel") private var hideTashkeel = Settings.shared.cleanArabicText
    @AppStorage("shareHadithIncludeNote") private var includeNote = true
    /// ShareAyah's `shareAyahLastActionMode`, for hadith: the sheet reopens in the mode last used.
    @AppStorage("shareHadithLastActionMode") private var storedActionModeRaw: String = ActionMode.image.rawValue

    // There is deliberately NO grade option: the grading is part of the hadith, not a preference, so
    // it always travels with the share - in the text AND on the card.

    @State private var actionMode: ActionMode = .image
    @State private var generatedImage: UIImage?
    @State private var activityItems: [Any] = []
    @State private var showingActivityView = false
    /// Whether the last system share actually completed (vs. cancelled) - see the activity sheet below.
    @State private var didCompleteShare = false
    @State private var didInit = false
    @State private var didFinishInitialSetup = false
    @State private var isGeneratingImage = false
    @State private var isSharing = false
    /// ShareAyah's generation guard: rapid toggle flips overlap renders, and without this the LAST
    /// render to FINISH won - a stale frame could land over the current options' image.
    @State private var imageGenerationID = 0
    private static let shareImageQueue = DispatchQueue(label: "app.shareHadith.imageGeneration", qos: .userInitiated)

    /// The share's Arabic face - defaults to the reading face until the user picks one here.
    private var shareFace: Settings.IslamArabicFace {
        Settings.IslamArabicFace(rawValue: shareFontFaceRaw) ?? settings.islamArabicFace
    }

    private var shareFaceBinding: Binding<Settings.IslamArabicFace> {
        Binding(get: { shareFace }, set: { shareFontFaceRaw = $0.rawValue })
    }

    private var noteText: String? {
        HadithStore.shared.note(slug: book.slug, idInBook: hadith.idInBook)
    }

    private var composed: String {
        Self.composedText(book: book, hadith: hadith)
    }

    /// The ayah sheet's text preview, for hadith: the same Allah-name reddening over a white base, so
    /// the two share surfaces render the names identically.
    private var composedAttributedText: AttributedString {
        ShareAyahSheet.allahHighlightedSwiftUIText(
            composed,
            baseColor: .white,
            enabled: settings.highlightAllahNamesHadith
        )
    }

    /// The unified hadith text composition, honoring the persisted include toggles - used by this sheet
    /// AND by the context menu's Copy Hadith, so copy and share always produce the same thing.
    static func composedText(book: HadithCatalogBook, hadith: HadithBookData.Hadith) -> String {
        let defaults = UserDefaults.standard
        func flag(_ key: String) -> Bool { defaults.object(forKey: key) == nil ? true : defaults.bool(forKey: key) }
        var parts: [String] = []
        // One block lookup for all three strings (this runs in a loop when sharing a whole chapter).
        let text = hadith.allText
        // Hide Tashkeel strips the diacritics for a cleaner shared text, the Share Ayah option's twin.
        // Absent means "not chosen here yet", which follows the app-wide setting - the same rule the
        // sheet's own `@AppStorage` default uses, so Copy Hadith and Share Hadith never disagree.
        let hideTashkeel = defaults.object(forKey: "shareHadithHideTashkeel") == nil
            ? Settings.shared.cleanArabicText
            : defaults.bool(forKey: "shareHadithHideTashkeel")
        let includeReference = flag("shareHadithReference")
        let includeArabic = flag("shareHadithArabic") && !text.arabic.isEmpty
        // The narrator is part of the English (no switch of its own, the reading rows' rule): English
        // on means the narrator line travels too, always.
        let includeEnglish = flag("shareHadithEnglish") && (!text.text.isEmpty || !text.narrator.isEmpty)
        // The Share Ayah grammar: each script's block opens with the reference in ITS OWN script, the
        // Arabic under "[سُنَن أَبِي داوُد ١٢٠]" and the English under "[Sunan Abi Dawud 120]", so a
        // reader of either half knows where the hadith is from without reading the other.
        if includeArabic {
            let arabic = hideTashkeel ? text.arabic.removingArabicDiacriticsAndSigns : text.arabic
            parts.append(includeReference
                ? "\(arabicReference(book: book, hadith: hadith, hideTashkeel: hideTashkeel))\n\(arabic)"
                : arabic)
        }
        if includeEnglish {
            var english: [String] = []
            if !text.narrator.isEmpty { english.append(text.narrator) }
            if !text.text.isEmpty { english.append(text.text) }
            let block = english.joined(separator: "\n\n")
            parts.append(includeReference ? "\(englishReference(book: book, hadith: hadith))\n\(block)" : block)
        } else if includeReference, !includeArabic {
            // The reference alone (every text part off): the bare English citation, as before.
            parts.append(englishReference(book: book, hadith: hadith))
        }
        // ALWAYS, with no option gating it: whoever receives a hadith must be able to tell sahih from
        // da'if, so the grading is not something a share can drop.
        let grades = hadith.grades
        if !grades.isEmpty { parts.append("Grade: \(HadithGradeLine.joined(grades))") }
        if flag("shareHadithIncludeNote"),
           let note = HadithStore.shared.note(slug: book.slug, idInBook: hadith.idInBook) {
            parts.append("Note: \(note)")
        }
        return parts.joined(separator: "\n\n")
    }

    /// "[سُنَن أَبِي داوُد ١٢٠]": the book's Arabic title with the citation in Arabic-Indic digits, the
    /// ayah share's "[سورة البقرة ٢:١٢٠]" for hadith. A citation's letter suffix ("8a") stays Latin: it
    /// is sunnah.com's, not Arabic.
    static func arabicReference(book: HadithCatalogBook, hadith: HadithBookData.Hadith, hideTashkeel: Bool) -> String {
        "[\(arabicReferenceTitle(book: book, hideTashkeel: hideTashkeel)) \(arabicDigits(hadith.displayNumber))]"
    }

    /// The Arabic title as the reference prints it: bare when the share hides tashkeel, so the heading
    /// is as clean as the text under it.
    static func arabicReferenceTitle(book: HadithCatalogBook, hideTashkeel: Bool) -> String {
        hideTashkeel ? book.arabicTitle.removingArabicDiacriticsAndSigns : book.arabicTitle
    }

    /// "[Sunan Abi Dawud 120]", the ayah share's "[Al-Baqarah 2:120]" for hadith.
    static func englishReference(book: HadithCatalogBook, hadith: HadithBookData.Hadith) -> String {
        "[\(book.englishTitle) \(hadith.displayNumber)]"
    }

    /// ASCII digits to Arabic-Indic (٠…٩); everything else passes through.
    static func arabicDigits(_ ascii: String) -> String {
        String(ascii.map { ch -> Character in
            guard ch.isASCII, let digit = ch.wholeNumberValue, let scalar = UnicodeScalar(0x0660 + digit) else { return ch }
            return Character(scalar)
        })
    }

    /// How many include-parts are on - the last one standing can't be turned off (an empty share is nothing).
    private var enabledPartCount: Int {
        let text = hadith.allText
        return [includeReference,
                includeArabic && !text.arabic.isEmpty,
                includeEnglish && (!text.text.isEmpty || !text.narrator.isEmpty)].filter { $0 }.count
    }

    // ShareAyahSheet's exact shape: the big preview on top (image, or the dark text card), the compact
    // toggle stack, the Image/Text segmented picker, and the Copy/Share glass buttons.
    var body: some View {
        let text = hadith.allText

        NavigationView {
            VStack {
                Spacer()

                ZStack {
                    if actionMode == .image {
                        if let img = generatedImage {
                            // The PREVIOUS image stays on screen while a regeneration runs (it is never
                            // nilled mid-flight), dimmed slightly so the swap reads as an update, not a
                            // teardown - the ayah sheet's fix for the jump-and-reflow on every toggle.
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(24)
                                .padding(.horizontal, 16)
                                .contextMenu { copyMenu(image: img) }
                                .opacity(isGeneratingImage ? 0.6 : 1)
                                .animation(.easeInOut(duration: 0.15), value: isGeneratingImage)
                                .transition(.opacity)
                        } else {
                            // First render only: hold the preview slot at a stable size so the controls
                            // below don't shift when the image lands.
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                        }
                    } else {
                        // The ayah sheet's dark text card, verbatim - except that it SCROLLS: a hadith
                        // runs many times an ayah's length, and the ayah card's shrink-to-fit would
                        // render the longest narrations at a few points tall.
                        ScrollView {
                            Text(composedAttributedText)
                                .font(.body)
                                .textSelection(.enabled)
                                .lineLimit(nil)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                        .background(Color.black)
                        .cornerRadius(24)
                        .padding(.horizontal, 16)
                        .contextMenu { copyMenu(image: generatedImage) }
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                .scaleEffect(isSharing ? 0.98 : 1)
                .animation(.easeInOut, value: actionMode)
                .animation(.easeInOut, value: isSharing)

                Spacer()

                ScrollView {
                    VStack(spacing: 2) {
                        toggle("Reference", $includeReference, disabled: includeReference && enabledPartCount == 1)

                        if !text.arabic.isEmpty {
                            toggle("Arabic", $includeArabic, disabled: includeArabic && enabledPartCount == 1)
                        }

                        // English carries its narrator line (no separate switch - see the include flags).
                        if !text.text.isEmpty || !text.narrator.isEmpty {
                            toggle("English", $includeEnglish, disabled: includeEnglish && enabledPartCount == 1)
                        }

                        // The ayah sheet's secondary options: the same 0.8-scaled compact rows, and the
                        // font picker lives INSIDE the option list, image mode only (the face is a
                        // property of the drawn card, not of the text).
                        if includeArabic, !text.arabic.isEmpty {
                            if actionMode == .image {
                                Picker("Arabic Font", selection: shareFaceBinding) {
                                    Text("Uthmani").tag(Settings.IslamArabicFace.uthmani)
                                    Text("IndoPak").tag(Settings.IslamArabicFace.indopak)
                                    Text("Hijazi").tag(Settings.IslamArabicFace.hijazi)
                                    Text("Kufi").tag(Settings.IslamArabicFace.kufi)
                                    Text("Basic").tag(Settings.IslamArabicFace.basic)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 2)
                            }

                            compactToggle("Hide Tashkeel and Diacretics", $hideTashkeel)
                        }

                        if noteText != nil {
                            compactToggle("Include Note", $includeNote)
                        }
                    }
                }
                .frame(maxHeight: 200)

                Picker("Action Mode", selection: $actionMode) {
                    Text("Image").tag(ActionMode.image)
                    Text("Text").tag(ActionMode.text)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 4)

                HStack(spacing: 12) {
                    actionButton("Copy") {
                        performCopyOrGenerate()
                    }

                    actionButton("Share", isAnimating: isSharing) {
                        performShareOrGenerate()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom)
                .sheet(isPresented: $showingActivityView) {
                    // didCompleteShare gates the auto-dismiss below: cancelling the system sheet must
                    // not throw away the configured preview.
                    if #available(iOS 16.0, *) {
                        ActivityView(activityItems: activityItems, onComplete: { didCompleteShare = $0 })
                            .presentationDetents([.medium])
                    } else {
                        ActivityView(activityItems: activityItems, onComplete: { didCompleteShare = $0 })
                    }
                }
            }
            .navigationTitle("\(book.englishTitle) \(hadith.displayNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            // Full-size before the wash so the background always covers the whole sheet.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accentWashedBackground()
        }
        .navigationViewStyle(.stack)
        .accentColor(settings.accentColor.color)
        .onAppear {
            guard !didInit else { return }
            didInit = true

            withAnimation {
                actionMode = ActionMode(rawValue: storedActionModeRaw) ?? .image
                generatePreviewImage()
            }

            DispatchQueue.main.async {
                didFinishInitialSetup = true
            }
        }
        // Every trigger below is gated on didFinishInitialSetup, the ayah sheet's rule: onAppear already
        // renders once explicitly, and its own state seeding used to echo through as a second, discarded render.
        .onChange(of: includeReference) { _ in regenerate() }
        .onChange(of: includeArabic) { _ in regenerate() }
        .onChange(of: includeEnglish) { _ in regenerate() }
        .onChange(of: hideTashkeel) { _ in regenerate() }
        .onChange(of: includeNote) { _ in regenerate() }
        .onChange(of: shareFontFaceRaw) { _ in regenerate() }
        .onChange(of: actionMode) { newValue in
            if didFinishInitialSetup { settings.hapticFeedback() }
            storedActionModeRaw = newValue.rawValue
            if newValue == .image && generatedImage == nil { generatePreviewImage() }
        }
        .onChange(of: showingActivityView) { open in
            // Close the whole sheet only after a COMPLETED share. On cancel, stay put with the
            // configured preview intact.
            if !open && didCompleteShare {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    private func regenerate() {
        guard didFinishInitialSetup else { return }
        settings.hapticFeedback()
        generatePreviewImage()
    }

    @ViewBuilder
    private func toggle(_ title: LocalizedStringKey, _ binding: Binding<Bool>, disabled: Bool) -> some View {
        Toggle(isOn: binding.animation(.easeInOut)) {
            Text(title).foregroundColor(.primary)
        }
        .tint(settings.accentColor.color)
        .disabled(disabled)
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }

    /// The ayah sheet's secondary-option row: the same 0.8 scale and negative inset, so an option that
    /// modifies a part reads quieter than the part's own switch.
    @ViewBuilder
    private func compactToggle(_ title: LocalizedStringKey, _ binding: Binding<Bool>) -> some View {
        Toggle(title, isOn: binding.animation(.easeInOut))
            .tint(settings.accentColor.color)
            .scaleEffect(0.8)
            .padding(.horizontal, -24)
            .padding(.vertical, 2)
    }

    private func actionButton(_ title: String, isAnimating: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.primary)
                .scaleEffect(isAnimating ? 0.96 : 1)
        }
        .conditionalGlassEffect(useColor: 0.25)
    }

    private func copyMenu(image: UIImage?) -> some View {
        Group {
            Text("Copy")
                .foregroundStyle(.secondary)

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = composed
            } label: { Label("Copy Text", systemImage: "doc.on.doc") }

            if let image {
                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.image = image
                } label: { Label("Copy Image", systemImage: "doc.on.doc.fill") }
            }
        }
    }

    private func animateShare(completion: @escaping () -> Void) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            isSharing = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            completion()

            withAnimation(.easeOut(duration: 0.18)) {
                isSharing = false
            }
        }
    }

    private func presentShareSheet(with items: [Any]) {
        animateShare {
            didCompleteShare = false
            activityItems = items
            showingActivityView = true
        }
    }

    private func performCopyOrGenerate() {
        switch actionMode {
        case .text:
            UIPasteboard.general.string = composed
            presentationMode.wrappedValue.dismiss()
        case .image:
            if let img = generatedImage {
                UIPasteboard.general.image = img
                presentationMode.wrappedValue.dismiss()
            } else {
                generatePreviewImage { img in
                    UIPasteboard.general.image = img
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func performShareOrGenerate() {
        switch actionMode {
        case .text:
            presentShareSheet(with: [composed])
        case .image:
            if let img = generatedImage {
                presentShareSheet(with: [img])
            } else {
                generatePreviewImage { img in
                    presentShareSheet(with: [img])
                }
            }
        }
    }

    // MARK: Card rendering

    /// Everything the card is drawn from, captured on the main actor before the render hops queues -
    /// the ayah sheet's rule: the render queue must never read view state a later toggle could be
    /// rewriting (and `UIScreen.main` is main-thread-only).
    private struct RenderInput {
        /// The Arabic reference's two halves (empty when the reference is off): the title is drawn in
        /// the share face, the number in the rounded face, the ayah card's split.
        var arabicReferenceTitle: String
        var arabicReferenceNumber: String
        var englishReference: String
        var arabic: String
        var narrator: String
        var english: String
        var grades: [(name: String, grade: String)]
        var note: String?
        var arabicFontName: String
        var arabicUsesCustomFace: Bool
        var accent: UIColor
        var highlightAllahNames: Bool
        var screenWidth: CGFloat
    }

    private func renderInput() -> RenderInput {
        let text = hadith.allText
        // Hide Tashkeel, the Share Ayah option's twin: strip the diacritics for a cleaner card.
        let arabicText = includeArabic
            ? (hideTashkeel ? text.arabic.removingArabicDiacriticsAndSigns : text.arabic)
            : ""
        // The KFGQPC faces DROP contextual shaping past a length cliff (every letter renders isolated),
        // so the longest narrations fall back to the system face on the card too - the live rows' rule,
        // see `arabicShapingCharacterLimit`. "Basic" is a sentinel with no real UIFont, and lands on the
        // same rounded-system fallback in `drawImage`.
        let usesCustomFace = shareFace != .basic && arabicText.count < Settings.arabicShapingCharacterLimit
        return RenderInput(
            arabicReferenceTitle: includeReference ? Self.arabicReferenceTitle(book: book, hideTashkeel: hideTashkeel) : "",
            arabicReferenceNumber: includeReference ? Self.arabicDigits(hadith.displayNumber) : "",
            englishReference: includeReference ? Self.englishReference(book: book, hadith: hadith) : "",
            arabic: arabicText,
            // The narrator travels with the English, never separately (see `composedText`).
            narrator: includeEnglish ? text.narrator : "",
            english: includeEnglish ? text.text : "",
            // No toggle: the grading always travels with the share.
            grades: hadith.grades,
            note: includeNote ? noteText : nil,
            arabicFontName: usesCustomFace ? shareFace.fontName : Settings.systemArabicFontName,
            arabicUsesCustomFace: usesCustomFace,
            accent: settings.accentColor.color.uiColor,
            highlightAllahNames: settings.highlightAllahNamesHadith,
            // Clamped to a phone-like measure, exactly like the ayah card: on iPad/Mac the SCREEN is
            // 800-1400pt wide even when the window is narrow, and a card laid out that wide reads terribly.
            screenWidth: min(UIScreen.main.bounds.width, ShareAyahRender.maxImageWidth)
        )
    }

    /// Renders off the main thread on a serial queue, ShareAyah's way, so toggling never hitches the sheet.
    private func generatePreviewImage(completion: @escaping (UIImage) -> Void = { _ in }) {
        let input = renderInput()
        let generationID = imageGenerationID + 1
        imageGenerationID = generationID
        // The previous image deliberately STAYS visible (dimmed via isGeneratingImage) while this render
        // runs - nilling it here would collapse the preview to zero height and make the sheet jump.
        isGeneratingImage = true
        Self.shareImageQueue.async {
            // Superseded before we even started drawing? Skip the render entirely instead of drawing an
            // image only to discard it. main.sync is deadlock-free here: nothing on the main thread ever
            // blocks on this queue.
            let stillCurrent = DispatchQueue.main.sync { self.imageGenerationID == generationID }
            guard stillCurrent else { return }

            let img: UIImage = autoreleasepool { Self.drawImage(input) }
            DispatchQueue.main.async {
                guard self.imageGenerationID == generationID else { return }
                // Scoped to the image swap only - an unscoped withAnimation animates the whole sheet's
                // layout and amplifies the jump.
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.generatedImage = img
                    self.isGeneratingImage = false
                }
                if self.actionMode == .image {
                    self.activityItems = [img]
                }
                completion(img)
            }
        }
    }

    /// The share card, drawn with `ShareAyahSheet.drawImage`'s layout: one attributed string composed
    /// block by block, measured against a screen-derived canvas, drawn on a black card at corner
    /// radius 20 with the logo + app-name watermark centered at the foot.
    private static func drawImage(_ input: RenderInput) -> UIImage {
        // Rounded, to match the app's system-font design (the `fontDesign` environment does not reach
        // this UIKit-drawn image, so the design is asked for explicitly).
        let bodyFont = UIFont.roundedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
        // The same 1.15x Arabic scale the ayah card uses, with the same rounded-system fallback for the
        // faces that have no real UIFont.
        let arabicSize = bodyFont.pointSize * 1.15
        let arabicFont = UIFont(name: input.arabicFontName, size: arabicSize)
            ?? UIFont.roundedSystemFont(ofSize: arabicSize)
        let captionFont = UIFont.roundedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize)
        let narratorFont = UIFont.italicSystemFont(ofSize: bodyFont.pointSize * 0.9)

        let textColor = UIColor.white
        // The ayah card's secondary caption color, RESOLVED for a dark card: this runs off the main
        // thread, where `UITraitCollection.current` is unspecified, and an unresolved secondaryLabel can
        // come back as near-black on the black card.
        let secondaryColor = UIColor.secondaryLabel.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        let accent = input.accent

        // --- Layout constants (ShareAyah's, unchanged)
        let padding: CGFloat = 20, spacing: CGFloat = 8, extraSpacing: CGFloat = 30
        let iPhoneCanvasCap: CGFloat = 500
        let deviceWidth = input.screenWidth - 50
        let maxWidth = min(deviceWidth, iPhoneCanvasCap)

        // Paragraph styles
        let right = NSMutableParagraphStyle(); right.alignment = .right
        let left  = NSMutableParagraphStyle(); left.alignment  = .left
        let cent  = NSMutableParagraphStyle(); cent.alignment  = .center

        // Attr dictionaries
        let bodyAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: textColor, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let arAttr = [NSAttributedString.Key.font: arabicFont, .foregroundColor: textColor, .paragraphStyle: right] as [NSAttributedString.Key: Any]
        let accentAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let arAccent = [NSAttributedString.Key.font: arabicFont, .foregroundColor: accent, .paragraphStyle: right] as [NSAttributedString.Key: Any]
        let narratorAttr = [NSAttributedString.Key.font: narratorFont, .foregroundColor: secondaryColor, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let captionAttr = [NSAttributedString.Key.font: captionFont, .foregroundColor: secondaryColor, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let captionAccentAttr = [NSAttributedString.Key.font: captionFont, .foregroundColor: accent, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let centAccent = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent, .paragraphStyle: cent] as [NSAttributedString.Key: Any]

        // --- Compose the full attributed text once
        let text = NSMutableAttributedString()
        func append(_ str: String, _ attrs: [NSAttributedString.Key: Any], highlightAllah: Bool = true) {
            let piece = NSMutableAttributedString(string: str, attributes: attrs)
            // The Share Ayah card's Allah-name reddening (Arabic pattern match + English "Allah") - the
            // live rows highlight the names, so the shared image must too.
            ShareAyahSheet.applyAllahHighlight(
                to: piece,
                source: str,
                enabled: highlightAllah && input.highlightAllahNames
            )
            text.append(piece)
        }
        func sepIfNeeded() { if text.length > 0 { append("\n\n", bodyAttr, highlightAllah: false) } }

        // The ayah card's grammar: each script's block opens with the reference in its own script, in
        // accent. "[سُنَن أَبِي داوُد ١٢٠]" over the Arabic (the title in the share face, the digits in
        // the rounded face, exactly the ayah card's "[سورة البقرة ٢:١٢٠]" split), "[Sunan Abi Dawud 120]"
        // over the narrator and English.
        if !input.arabic.isEmpty {
            if !input.arabicReferenceTitle.isEmpty {
                append("[\(input.arabicReferenceTitle) ", arAccent, highlightAllah: false)
                append("\(input.arabicReferenceNumber)]", accentAttr, highlightAllah: false)
                append("\n", bodyAttr, highlightAllah: false)
            }
            append(input.arabic, arAttr)
        }

        if !input.narrator.isEmpty || !input.english.isEmpty {
            sepIfNeeded()
            if !input.englishReference.isEmpty {
                append(input.englishReference, accentAttr, highlightAllah: false)
                append("\n", bodyAttr, highlightAllah: false)
            }

            // The narrator sits directly above the English on a single break - the ayah card's grammar
            // for an attribution line and the text it introduces ("- Saheeh International").
            if !input.narrator.isEmpty {
                append(input.narrator, narratorAttr)
                if !input.english.isEmpty { append("\n", bodyAttr, highlightAllah: false) }
            }

            if !input.english.isEmpty {
                append(input.english, bodyAttr)
            }
        } else if input.arabic.isEmpty, !input.englishReference.isEmpty {
            // The reference alone (every text part off): the bare English citation, as before.
            append(input.englishReference, accentAttr, highlightAllah: false)
        }

        // The grade line, drawn exactly as `HadithGradeLine` draws it on screen: the verdict term in the
        // accent color, the grader's name secondary. No ranking, no per-verdict color-coding.
        if !input.grades.isEmpty {
            sepIfNeeded()
            append("Grade: ", captionAttr, highlightAllah: false)
            for (index, entry) in input.grades.enumerated() {
                if index > 0 { append(" · ", captionAttr, highlightAllah: false) }
                append(entry.grade, captionAccentAttr, highlightAllah: false)
                if !entry.name.isEmpty {
                    append(" (\(entry.name))", captionAttr, highlightAllah: false)
                }
            }
        }

        if let note = input.note {
            sepIfNeeded()
            append("- Note", captionAttr, highlightAllah: false)
            append("\n", bodyAttr, highlightAllah: false)
            append(note, bodyAttr)
        }

        guard text.length > 0 else { return UIImage() }

        // --- Watermark (the ayah card's, unchanged): the app logo beside the full app name, in accent.
        let wmString = AppIdentifiers.appFullName
        let wmText = NSAttributedString(string: wmString, attributes: centAccent)
        var logo = UIImage(named: AppIdentifiers.appName)

        var wmTextSize = wmText.size()
        var logoSize = CGSize(width: wmTextSize.height, height: wmTextSize.height)
        let availWidth = maxWidth - 2*padding
        let desiredWmW = logoSize.width + spacing + wmTextSize.width

        if desiredWmW > availWidth {
            let scale = availWidth / desiredWmW
            wmTextSize = CGSize(width: wmTextSize.width*scale, height: wmTextSize.height*scale)
            logoSize = CGSize(width: logoSize.width*scale, height: logoSize.height*scale)
            if let img = logo {
                let r = UIGraphicsImageRenderer(size: logoSize)
                logo = r.image { _ in img.draw(in: CGRect(origin: .zero, size: logoSize)) }
            }
        }

        let constraint = CGSize(width: availWidth, height: .greatestFiniteMagnitude)
        var textRect = text.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
        textRect.size.width  += 2*padding
        textRect.size.height += logoSize.height + extraSpacing + 25

        let canvas = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: textRect.height))

        let r1 = UIGraphicsImageRenderer(size: canvas.size)
        let blackCard = r1.image { ctx in
            UIColor.black.setFill(); ctx.fill(canvas)
            text.draw(in: CGRect(x: padding, y: padding, width: canvas.width - 2*padding, height: canvas.height))

            let wmY = canvas.height - logoSize.height - extraSpacing/2
            let wmX = (canvas.width - (logoSize.width + spacing + wmTextSize.width)) / 2
            if let logo = logo {
                let rect = CGRect(origin: CGPoint(x: wmX, y: wmY), size: logoSize)
                ctx.cgContext.addPath(UIBezierPath(roundedRect: rect, cornerRadius: logoSize.height*0.25).cgPath)
                ctx.cgContext.clip(); logo.draw(in: rect); ctx.cgContext.resetClip()
            }
            wmText.draw(in: CGRect(x: wmX + logoSize.width + spacing, y: wmY, width: wmTextSize.width, height: wmTextSize.height))
        }
        return UIGraphicsImageRenderer(size: canvas.size).image { _ in
            UIBezierPath(roundedRect: canvas, cornerRadius: 20).addClip()
            blackCard.draw(at: .zero)
        }
    }
}

/// "Select Text" for a hadith - the ayah rows' `SelectAyahTextSheet`, for a narration (2026-09-21).
///
/// The reading row already has "Copy Hadith", but that copies the whole thing in the share sheet's
/// format. Selecting inside a row in the chapter list is fussy at best, because the row competes
/// for the same drag with the list's scroll. Lifting the text into a sheet of its own gives the
/// selection somewhere to live, and each block also gets a one-tap copy for when the whole block
/// is what you wanted.
struct SelectHadithTextSheet: View {
    @ObservedObject var settings = Settings.shared

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    @State private var copiedLabel: String?

    private var reference: String { "\(book.englishTitle) \(hadith.displayNumber)" }

    private var arabicFont: UIFont {
        let size = CGFloat(settings.hadithArabicFontSize)
        if settings.hadithArabicWantsCustomFace, let custom = UIFont(name: settings.nonQuranArabicFontName, size: size) {
            return custom
        }
        return .systemFont(ofSize: size)
    }

    private var englishFont: UIFont { .systemFont(ofSize: CGFloat(settings.hadithEnglishFontSize)) }

    var body: some View {
        let text = hadith.allText
        NavigationView {
            List {
                Group {
                    if !text.arabic.isEmpty {
                        selectableBlock(title: "ARABIC", text: text.arabic, font: arabicFont, isArabic: true)
                    }

                    if !text.narrator.isEmpty {
                        selectableBlock(title: "NARRATOR", text: text.narrator, font: englishFont, isArabic: false)
                    }

                    if !text.text.isEmpty {
                        selectableBlock(title: "ENGLISH", text: text.text, font: englishFont, isArabic: false)
                    }

                    Section {
                        Text("Press and drag over any part of the text above to select it, then copy. The button on each block copies that whole block.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .navigationTitle(reference)
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func selectableBlock(title: String, text: String, font: UIFont, isArabic: Bool) -> some View {
        Section {
            // A real (read-only) UITextView, not `Text(...).textSelection(.enabled)` - see the note
            // on `SelectableTextView` in Helpers/SelectableText.swift for why the modifier can't do
            // this job inside a List.
            SelectableTextView(text: text, font: font, isArabic: isArabic, lineSpacing: isArabic ? 8 : 2)
                .padding(.vertical, 4)
        } header: {
            HStack {
                Text(title)

                Spacer()

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = text
                    withAnimation(.easeInOut) { copiedLabel = title }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut) {
                            if copiedLabel == title { copiedLabel = nil }
                        }
                    }
                } label: {
                    Label(
                        copiedLabel == title ? "Copied" : "Copy",
                        systemImage: copiedLabel == title ? "checkmark" : "doc.on.doc"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                }
                .buttonStyle(.plain)
                .textCase(nil)
            }
        }
    }
}
#endif
