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
    /// Interpret `hadith` as the internal row number (idInBook), never as a citation - for records
    /// saved by row key whose hadith can no longer be resolved directly. Without this, a stale row
    /// key in a drifted book would be read citation-first and could open a DIFFERENT hadith.
    var byRowNumber: Bool = false

    /// The book, opened straight from its bundled pack - synchronous and instant, so this screen has
    /// no loading state and cannot fail for want of a network.
    private var data: HadithBookData? { store.book(book) }

    private var resolved: HadithBookData.Hadith? {
        guard let data else { return nil }
        if let chapter {
            guard data.chapters.indices.contains(chapter - 1) else { return nil }
            let inChapter = data.hadiths(in: data.chapters[chapter - 1])
            let offset = inChapter.startIndex + (hadith - 1)
            guard hadith >= 1, offset < inChapter.endIndex else { return nil }
            return inChapter[offset]
        }
        if byRowNumber { return data.hadith(numbered: hadith) }
        // Citation-first: "muslim 8" is the hadith CITED 8 (standard sunnah.com numbering), falling
        // back to the internal row number for the books that have no citations.
        return data.hadith(referenced: hadith, suffix: suffix)
    }

    /// The number as the user asked for it - base plus any variant letter ("8a").
    private var requestedNumber: String { "\(hadith)\(suffix ?? "")" }

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
    @ObservedObject private var settings = Settings.shared

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
            result = result + Text(entry.grade).foregroundColor(settings.accentColor.color)
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
    @ObservedObject private var settings = Settings.shared
    /// The row renders ONLY bookmark/note state, so it observes the user-data object - not HadithStore,
    /// whose download/prewarm publishes used to re-render every visible row on every tick.
    @ObservedObject private var userData = HadithUserData.shared

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith
    var searchText: String = ""
    /// The Quran ayah-search rows' scale: caption-sized type for search results. The FULL Arabic and
    /// English always render (no line clipping, and the show-Arabic/English toggles don't apply) so the
    /// highlighted match is visible wherever it falls in the text.
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

    /// "Sahih al-Bukhari 1234" - the standard way a hadith is cited (the sunnah.com citation when
    /// one exists, the internal row number for the books that have none).
    private var reference: String {
        "\(book.englishTitle) \(hadith.displayNumber)"
    }

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
        // One block-cache lookup for all three strings. `hadith.arabic`/`hadith.english` are each a
        // full trip into the (locked) block cache; this body used to make six of those per pass,
        // which is also lock traffic contended against any detached search sweep.
        let text = hadith.allText
        // One block-cache lookup, same rule as `allText`.
        let grades = hadith.grades
        let visibility = searchVisibility(text: text)
        let cross = crossLanguageSpans(text: text)
        VStack(alignment: .leading, spacing: compact ? 5 : 10) {
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
                    withAnimation(.easeInOut) { userData.toggleBookmark(book: book, hadith: hadith) }
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
                HighlightedSnippet(
                    source: text.arabic,
                    term: searchText,
                    // The longest narrations fall back to the system face: the custom KFGQPC faces
                    // DROP contextual shaping past a length cliff and every letter renders isolated
                    // (see `arabicShapingCharacterLimit`).
                    font: settings.hadithArabicFont(for: text.arabic, size: arabicFontSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    highlightAllahNames: settings.highlightAllahNamesHadith,
                    guaranteeMatch: visibility.guaranteeArabic,
                    // The classical faces draw "،" as an ornament circle - commas fall back to the
                    // system face.
                    extraHighlightRanges: cross.arabic
                )
                .arabicFontDesign(custom: settings.hadithArabicUsesCustomFace(for: text.arabic))
                .multilineTextAlignment(.trailing)
                .lineSpacing(compact ? 0 : 6)
                .frame(maxWidth: .infinity, alignment: .trailing)
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
                        source: text.text,
                        term: searchText,
                        font: .system(size: englishFontSize),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        highlightAllahNames: settings.highlightAllahNamesHadith,
                        guaranteeMatch: visibility.guaranteeText,
                        extraHighlightRanges: cross.text
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
        .sheet(isPresented: $showShareSheet) {
            HadithShareSheet(book: book, hadith: hadith)
                .smallMediumSheetPresentation()
        }
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
                    userData.toggleBookmark(book: book, hadith: hadith)
                }
            } label: {
                Label("Remove Bookmark", systemImage: "bookmark.fill")
            }
        } else {
            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    userData.toggleBookmark(book: book, hadith: hadith)
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
    }
}

/// The Quran tab's recent-searches chips, shared by the Hadith tab root AND the book view - one
/// horizontal row of tappable glass chips over the search bar (tap to re-run, ✕ to remove). One
/// component so every hadith search surface reads identically.
struct HadithSearchHistoryChips: View {
    @ObservedObject var settings = Settings.shared
    @Binding var searchText: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(settings.hadithSearchHistory, id: \.self) { query in
                    chip(query: query)
                }
            }
        }
    }

    private func chip(query: String) -> some View {
        HStack(spacing: 4) {
            Button {
                settings.hapticFeedback()
                withAnimation {
                    searchText = query
                    settings.addHadithSearchHistory(query)
                    self.endEditing()
                }
            } label: {
                Text(query)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
            }

            Button {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.removeHadithSearchHistory(query)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.bold())
                    .padding(.trailing, 8)
            }
        }
        .foregroundStyle(settings.accentColor.color)
        .conditionalGlassEffect(useColor: 0.25)
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
            source: text,
            term: "",
            // Length-aware face (see `arabicShapingCharacterLimit`): a card whose source is a full
            // giant narration must not shatter just because it is clamped to two lines.
            font: settings.useFontArabic
                ? settings.hadithArabicFont(for: text, size: size)
                : .footnote,
            accent: settings.accentColor.color,
            fg: .primary,
            // The clamp must ride INSIDE the snippet: it applies `.lineLimit` to its own Text, and the
            // innermost value wins - an outer `.reservedLineLimit` here was silently ignored.
            lineLimit: lineLimit,
            reservesSpace: true
        )
        .arabicFontDesign(custom: settings.hadithArabicUsesCustomFace(for: text))
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

/// The Quran search's Load More pair, for hadith matches: a menu offering 5/10/20 more, and a
/// load-all underneath. Shared by the book view and the chapter view.
struct HadithLoadMoreControls: View {
    @ObservedObject private var settings = Settings.shared

    let label: String
    let hasMore: Bool
    @Binding var limit: Int

    var body: some View {
        if hasMore {
            Menu {
                Text("Load More")
                    .foregroundStyle(.secondary)

                ForEach([5, 10, 20], id: \.self) { amount in
                    Button {
                        settings.hapticFeedback()
                        limit += amount
                    } label: {
                        Label("Load \(amount)", systemImage: "\(amount).circle")
                    }
                }
            } label: {
                Text("Load more \(label)")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            .conditionalGlassEffect()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .listRowSeparator(.hidden, edges: .bottom)
            .padding(.bottom, -8)

            Button {
                settings.hapticFeedback()
                limit = Int.max
            } label: {
                Text("Load all \(label)")
            }
            .foregroundColor(settings.accentColor.color)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(8)
            .conditionalGlassEffect()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.top, -8)
            .listRowSeparator(.hidden)
        }
    }
}

// MARK: - Bookmark rows (Quran-style one-line previews) + the full list

/// A bookmarked hadith row in the Quran-bookmark format: reference, ONE line of Arabic (trailing), ONE
/// line of English - never the narrator. Opens the hadith through the reference resolver.
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

    @State private var showNoteSheet = false
    @State private var noteDraft = ""
    @State private var showRespectAlert = false
    /// Set to the FULL hadith (resolved from the book pack on demand) when Share Hadith is tapped -
    /// the bookmark itself only stores previews.
    @State private var shareHadith: HadithBookData.Hadith? = nil

    /// The bookmarked hadith's full row from its book pack - opening a book is synchronous and cheap
    /// (mapped, not read), so resolving on menu tap is fine. Nil only if the pack is missing.
    private func fullHadith(in book: HadithCatalogBook) -> HadithBookData.Hadith? {
        HadithStore.shared.book(book)?.hadith(numbered: bookmark.idInBook)
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
                    // The same accent-tinted glass number badge the Quran's bookmarked ayah rows lead with.
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
            .contextMenu {
                // HadithRow's menu grammar exactly - reference, bookmark, note actions, a divider,
                // then Copy and Share - so a bookmarked hadith's menu reads like every hadith's menu.
                Text(bookmark.reference)
                    .foregroundStyle(.secondary)

                Button(role: .destructive) {
                    settings.hapticFeedback()
                    let placeholder = HadithBookData.Hadith(
                        id: -1, idInBook: bookmark.idInBook, chapterId: bookmark.chapterId ?? -1,
                        arabic: "", english: HadithBookData.Hadith.EnglishText(narrator: "", text: "")
                    )
                    userData.toggleBookmark(book: book, hadith: placeholder)
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
                    if let hadith = fullHadith(in: book) {
                        UIPasteboard.general.string = HadithShareSheet.composedText(book: book, hadith: hadith)
                    }
                } label: {
                    Label("Copy Hadith", systemImage: "doc.on.doc")
                }

                Button {
                    settings.hapticFeedback()
                    shareHadith = fullHadith(in: book)
                } label: {
                    Label("Share Hadith", systemImage: "square.and.arrow.up")
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
                        let placeholder = HadithBookData.Hadith(
                            id: -1, idInBook: bookmark.idInBook, chapterId: bookmark.chapterId ?? -1,
                            arabic: "", english: HadithBookData.Hadith.EnglishText(narrator: "", text: "")
                        )
                        withAnimation(.easeInOut) {
                            userData.setNote(book: book, hadith: placeholder, note: text)
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
}

/// The grid form of a bookmarked hadith - the Quran's bookmark grid tile shape: reference on top,
/// one-line Arabic, one-line English, on clear glass.
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

    var body: some View {
        Button {
            settings.hapticFeedback()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "bookmark.fill")
                        .font(.caption2)
                        .foregroundStyle(settings.accentColor.color)

                    Text(bookmark.reference)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                // The reader's own visibility toggles apply here exactly as in the bookmark list
                // rows, and each enabled slot reserves its own TWO lines whether or not this bookmark
                // has that language - an empty string still reserves them - so tiles keep their
                // neighbours' height instead of hugging shorter. Four lines for the surviving
                // language does NOT square them: four Arabic lines are taller than two Arabic plus
                // two English, and four English lines are shorter.
                if settings.showHadithArabic {
                    HadithArabicPreview(text: bookmark.arabicPreview ?? "", size: 14, lineLimit: 2)
                }

                if settings.showHadithEnglish {
                    let english = bookmark.englishPreview ?? ""
                    Text(!english.isEmpty ? english : (bookmark.arabicPreview == nil ? bookmark.preview : ""))
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
        .buttonStyle(.plain)
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
    @AppStorage("shareHadithHideTashkeel") private var hideTashkeel = false
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
        let hideTashkeel = defaults.bool(forKey: "shareHadithHideTashkeel")
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
                                Picker("Arabic Font", selection: shareFaceBinding.animation(.easeInOut)) {
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

                Picker("Action Mode", selection: $actionMode.animation(.easeInOut)) {
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
#endif
