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
        return data.hadith(numbered: hadith)
    }

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
                             ?? "No hadith numbered \(hadith) in \(book.englishTitle).")
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
        .navigationTitle(chapter.map { "\(book.englishTitle) \($0):\(hadith)" } ?? "\(book.englishTitle) \(hadith)")
        .navigationBarTitleDisplayMode(.inline)
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
        fontScale: CGFloat = 1
    ) {
        self.book = book
        self.hadith = hadith
        self.searchText = searchText
        self.compact = compact
        self.fontScale = fontScale
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

    /// "Sahih al-Bukhari 1234" - the standard way a hadith is cited.
    private var reference: String {
        "\(book.englishTitle) \(hadith.idInBook)"
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
        HadithStore.shared.cachedBook(book.slug)?.positionInChapter(hadith)
    }

    private var arabicFontSize: CGFloat {
        // Compact rows show the full text, so the type drops to caption scale (+2 keeps the Arabic
        // script legible at that size).
        (compact ? UIFont.preferredFont(forTextStyle: .caption1).pointSize + 2 : settings.hadithArabicFontSize) * fontScale
    }

    private var englishFontSize: CGFloat {
        (compact ? UIFont.preferredFont(forTextStyle: .caption2).pointSize : settings.hadithEnglishFontSize) * fontScale
    }

    var body: some View {
        // One block-cache lookup for all three strings. `hadith.arabic`/`hadith.english` are each a
        // full trip into the (locked) block cache; this body used to make six of those per pass,
        // which is also lock traffic contended against any detached search sweep.
        let text = hadith.allText
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

                    Text("\(hadith.idInBook)")
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
                .overlay(alignment: .topTrailing) {
                    if isLastRead {
                        Image(systemName: "book.fill")
                            .font(.caption2)
                            .foregroundStyle(settings.accentColor.color)
                            .padding(4)
                            .offset(x: 8, y: -6)
                    }
                }

                Spacer(minLength: 0)

                // The context menu, reachable without a long-press - the AyahRow actions button's exact
                // sizing (icon in a glass square matching the pill's height). When bookmarked, the icon
                // IS the bookmark, so the state and the menu share one control instead of two.
                Menu {
                    menuContent
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.circle.fill" : "ellipsis.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: compact ? 19 : 25, height: compact ? 19 : 25)
                        .foregroundColor(settings.accentColor.color)
                        .conditionalGlassEffect()
                        .frame(width: compact ? 22 : 28, height: compact ? 22 : 28)
                        .contentShape(Rectangle())
                }
            }

            if compact || settings.showHadithArabic, !text.arabic.isEmpty {
                HighlightedSnippet(
                    source: text.arabic,
                    term: searchText,
                    font: settings.useFontArabic
                        ? Font.arabic(settings.nonQuranArabicFontName, size: arabicFontSize)
                        : .system(size: arabicFontSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    highlightAllahNames: settings.highlightAllahNamesHadith,
                    // The classical faces draw "،" as an ornament circle - commas fall back to the
                    // system face.
                    basicFontForCommas: settings.useFontArabic ? arabicFontSize : nil
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .lineSpacing(compact ? 0 : 6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .fixedSize(horizontal: false, vertical: true)
            }

            if compact || settings.showHadithEnglish {
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
                        highlightAllahNames: settings.highlightAllahNamesHadith
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
                        highlightAllahNames: settings.highlightAllahNamesHadith
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

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

/// One line of hadith Arabic in the Islam face, trailing - with commas falling back to the system
/// face (the classical faces draw "\u{060C}" as an ornament circle). Every preview row renders through
/// this so bookmarks, Hadith of the Day, Last Read, and the summary tiles all match the reader.
struct HadithArabicPreview: View {
    @ObservedObject private var settings = Settings.shared

    let text: String
    var size: CGFloat = 15

    var body: some View {
        HighlightedSnippet(
            source: text,
            term: "",
            font: settings.useFontArabic
                ? Font.arabic(settings.nonQuranArabicFontName, size: size)
                : .footnote,
            accent: settings.accentColor.color,
            fg: .primary,
            lineLimit: 1,
            basicFontForCommas: settings.useFontArabic ? size : nil
        )
        .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
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

    var body: some View {
        if let book = HadithCatalogBook.bySlug[bookmark.slug] {
            NavigationLink {
                // Books → Chapters → Hadiths: land in the book, which auto-pushes the hadith's chapter
                // scrolled to it - backing out of the hadith always shows the chapter list.
                HadithBookView(book: book, autoOpenHadithID: bookmark.idInBook)
            } label: {
                HStack(spacing: 8) {
                    // The same accent-tinted glass number badge the Quran's bookmarked ayah rows lead with.
                    Text("\(bookmark.idInBook)")
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
                        // the same toggles the reader uses, so a bookmark looks like its hadith.
                        if settings.showHadithArabic, let arabic = bookmark.arabicPreview, !arabic.isEmpty {
                            HadithArabicPreview(text: arabic)
                        }

                        if settings.showHadithEnglish, let english = bookmark.englishPreview, !english.isEmpty {
                            Text(english)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else if bookmark.arabicPreview == nil {
                            // A bookmark saved by an older build carries only the combined preview.
                            Text(bookmark.preview)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
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

                if let arabic = bookmark.arabicPreview, !arabic.isEmpty {
                    HadithArabicPreview(text: arabic, size: 14)
                }

                Text(bookmark.englishPreview?.isEmpty == false ? (bookmark.englishPreview ?? "") : bookmark.preview)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
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

/// Every bookmarked hadith, pushed from the "View All" row.
struct HadithBookmarksListView: View {
    @ObservedObject private var settings = Settings.shared
    /// Renders only the bookmark list - observe the user-data object, not the whole store.
    @ObservedObject private var userData = HadithUserData.shared

    var body: some View {
        List {
            Group {
                Section(header: SectionPillHeader(title: "BOOKMARKS", count: userData.bookmarks.count)) {
                    ForEach(userData.bookmarks) { bookmark in
                        HadithBookmarkRow(bookmark: bookmark)
                            .equatable()
                    }

                    if userData.bookmarks.isEmpty {
                        Text("No bookmarked hadiths yet. Press and hold any hadith to bookmark it.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .compactListSectionSpacing()
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.inline)
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

struct HadithShareSheet: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith

    // What travels with the share - persisted, and shared with Copy Hadith so the two always agree.
    @AppStorage("shareHadithArabic") private var includeArabic = true
    @AppStorage("shareHadithEnglish") private var includeEnglish = true
    @AppStorage("shareHadithNarrator") private var includeNarrator = true
    @AppStorage("shareHadithReference") private var includeReference = true
    @AppStorage("shareHadithAsImage") private var shareAsImage = true
    // The Share Ayah sheet's applicable options, for hadith: the Arabic face, tashkeel, and the note.
    @AppStorage("shareHadithFontFace") private var shareFontFaceRaw = ""
    @AppStorage("shareHadithHideTashkeel") private var hideTashkeel = false
    @AppStorage("shareHadithIncludeNote") private var includeNote = true

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

    /// The unified hadith text composition, honoring the persisted include toggles - used by this sheet
    /// AND by the context menu's Copy Hadith, so copy and share always produce the same thing.
    static func composedText(book: HadithCatalogBook, hadith: HadithBookData.Hadith) -> String {
        let defaults = UserDefaults.standard
        func flag(_ key: String) -> Bool { defaults.object(forKey: key) == nil ? true : defaults.bool(forKey: key) }
        var parts: [String] = []
        // One block lookup for all three strings (this runs in a loop when sharing a whole chapter).
        let text = hadith.allText
        if flag("shareHadithReference") { parts.append("[\(book.englishTitle) \(hadith.idInBook)]") }
        if flag("shareHadithArabic"), !text.arabic.isEmpty {
            // Hide Tashkeel strips the diacritics for a cleaner shared text, the Share Ayah option's twin.
            let arabic = defaults.bool(forKey: "shareHadithHideTashkeel")
                ? text.arabic.removingArabicDiacriticsAndSigns
                : text.arabic
            parts.append(arabic)
        }
        if flag("shareHadithNarrator"), !text.narrator.isEmpty { parts.append(text.narrator) }
        if flag("shareHadithEnglish"), !text.text.isEmpty { parts.append(text.text) }
        if flag("shareHadithIncludeNote"),
           let note = HadithStore.shared.note(slug: book.slug, idInBook: hadith.idInBook) {
            parts.append("Note: \(note)")
        }
        return parts.joined(separator: "\n\n")
    }

    @State private var generatedImage: UIImage?
    @State private var didInit = false
    /// ShareAyahSheet's generation guard: rapid toggle flips overlap renders, and without this the LAST
    /// render to FINISH won - a stale frame could land over the current options' image.
    @State private var renderGeneration = 0

    /// How many include-parts are on - the last one standing can't be turned off (an empty share is nothing).
    private var enabledPartCount: Int {
        [includeReference,
         includeArabic && !hadith.arabic.isEmpty,
         includeNarrator && !hadith.english.narrator.isEmpty,
         includeEnglish && !hadith.english.text.isEmpty].filter { $0 }.count
    }

    // ShareAyahSheet's exact shape: the big preview on top (image, or the dark text card), the compact
    // toggle stack, the Image/Text segmented picker, and the Copy/Share glass buttons.
    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                ZStack {
                    if shareAsImage {
                        if let img = generatedImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(24)
                                .padding(.horizontal, 16)
                                .contextMenu { copyMenu(image: img) }
                                .transition(.opacity)
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                        }
                    } else {
                        ScrollView {
                            // Same Allah-name reddening the Share Ayah text preview applies - the live
                            // hadith rows highlight the names, so the share preview must too.
                            Text(ShareAyahSheet.allahHighlightedSwiftUIText(composed, baseColor: .white, enabled: settings.highlightAllahNamesHadith))
                                .font(.body)
                                .textSelection(.enabled)
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
                .animation(.easeInOut, value: shareAsImage)

                Spacer()

                ScrollView {
                    VStack(spacing: 2) {
                        toggle("Reference", $includeReference, disabled: includeReference && enabledPartCount == 1)

                        if !hadith.arabic.isEmpty {
                            toggle("Arabic", $includeArabic, disabled: includeArabic && enabledPartCount == 1)

                            // Applicable Share Ayah options, one for one: tashkeel off for a cleaner
                            // card, and the Arabic face choice (segmented, like the ayah sheet's).
                            if includeArabic {
                                toggle("Hide Tashkeel", $hideTashkeel, disabled: false)
                            }
                        }

                        if !hadith.english.narrator.isEmpty {
                            toggle("Narrator", $includeNarrator, disabled: includeNarrator && enabledPartCount == 1)
                        }

                        if !hadith.english.text.isEmpty {
                            toggle("English", $includeEnglish, disabled: includeEnglish && enabledPartCount == 1)
                        }

                        if noteText != nil {
                            toggle("Include Note", $includeNote, disabled: false)
                        }
                    }
                }
                .frame(maxHeight: 200)

                if includeArabic, !hadith.arabic.isEmpty {
                    Picker("Arabic Font", selection: shareFaceBinding.animation(.easeInOut)) {
                        Text("Uthmani").tag(Settings.IslamArabicFace.uthmani)
                        Text("IndoPak").tag(Settings.IslamArabicFace.indopak)
                        Text("Basic").tag(Settings.IslamArabicFace.basic)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }

                Picker("Action Mode", selection: $shareAsImage.animation(.easeInOut)) {
                    Text("Image").tag(true)
                    Text("Text").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 4)

                HStack(spacing: 12) {
                    actionButton("Copy") {
                        if shareAsImage, let img = generatedImage {
                            UIPasteboard.general.image = img
                        } else {
                            UIPasteboard.general.string = composed
                        }
                        dismiss()
                    }

                    actionButton("Share") {
                        if shareAsImage, let img = generatedImage {
                            presentSystemShareSheet(items: [img])
                        } else {
                            presentSystemShareSheet(items: [composed])
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom)
            }
            .navigationTitle("\(book.englishTitle) \(hadith.idInBook)")
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
        .accentColor(settings.accentColor.color)
        .onAppear {
            guard !didInit else { return }
            didInit = true
            generatePreviewImage()
        }
        .onChange(of: includeReference) { _ in settings.hapticFeedback(); generatePreviewImage() }
        .onChange(of: includeArabic) { _ in settings.hapticFeedback(); generatePreviewImage() }
        .onChange(of: includeNarrator) { _ in settings.hapticFeedback(); generatePreviewImage() }
        .onChange(of: includeEnglish) { _ in settings.hapticFeedback(); generatePreviewImage() }
        .onChange(of: hideTashkeel) { _ in settings.hapticFeedback(); generatePreviewImage() }
        .onChange(of: includeNote) { _ in settings.hapticFeedback(); generatePreviewImage() }
        .onChange(of: shareFontFaceRaw) { _ in settings.hapticFeedback(); generatePreviewImage() }
        .onChange(of: shareAsImage) { asImage in
            settings.hapticFeedback()
            if asImage && generatedImage == nil { generatePreviewImage() }
        }
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

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.primary)
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

    /// Renders off the main thread, ShareAyah's way, so toggling never hitches the sheet.
    private func generatePreviewImage() {
        renderGeneration += 1
        let generation = renderGeneration
        DispatchQueue.global(qos: .userInitiated).async {
            let image = renderImage()
            DispatchQueue.main.async {
                // A newer toggle superseded this render - drop the stale frame (the newer one is coming).
                guard generation == renderGeneration else { return }
                withAnimation(.easeInOut(duration: 0.15)) { generatedImage = image }
            }
        }
    }

    /// The dark rounded share card, in the Share Ayah visual language: reference caption, Arabic
    /// trailing in the reader's face (Basic falls back to the rounded system face), narrator italic,
    /// English body.
    private func renderImage() -> UIImage? {
        let width: CGFloat = 1080
        let inset: CGFloat = 72
        let textWidth = width - inset * 2

        let baseSize: CGFloat = 40
        // The user's chosen share face (Uthmani / IndoPak / Basic), the Share Ayah picker's twin.
        let arabicFont = UIFont(name: shareFace.fontName, size: baseSize * 1.2)
            ?? .roundedSystemFont(ofSize: baseSize * 1.2)
        let englishFont = UIFont.roundedSystemFont(ofSize: baseSize)
        let narratorFont = UIFont.italicSystemFont(ofSize: baseSize * 0.85)
        let captionFont = UIFont.roundedSystemFont(ofSize: baseSize * 0.7, weight: .semibold)
        let noteFont = UIFont.italicSystemFont(ofSize: baseSize * 0.75)

        let accent = UIColor(settings.accentColor.color)

        func paragraph(_ alignment: NSTextAlignment, spacing: CGFloat = 8) -> NSParagraphStyle {
            let p = NSMutableParagraphStyle()
            p.alignment = alignment
            p.lineSpacing = spacing
            return p
        }

        // The classical faces draw "،" and "؛" as ornament circles - those runs fall back to the
        // system face, exactly like the live rows' `basicFontForCommas`.
        func applyBasicFontToCommas(_ piece: NSMutableAttributedString, size: CGFloat) {
            let ns = piece.string as NSString
            for i in 0..<ns.length {
                let ch = ns.substring(with: NSRange(location: i, length: 1))
                if ch == "،" || ch == "؛" || ch == "," {
                    piece.addAttribute(.font, value: UIFont.roundedSystemFont(ofSize: size), range: NSRange(location: i, length: 1))
                }
            }
        }

        let text = NSMutableAttributedString()
        func append(_ string: String, font: UIFont, color: UIColor, alignment: NSTextAlignment, isArabic: Bool = false) {
            if text.length > 0 { text.append(NSAttributedString(string: "\n\n")) }
            let piece = NSMutableAttributedString(string: string, attributes: [
                .font: font, .foregroundColor: color, .paragraphStyle: paragraph(alignment)
            ])
            // The Share Ayah card's Allah-name reddening, applied to every part (Arabic pattern match +
            // English "Allah") - the live rows highlight the names, so the shared image must too.
            ShareAyahSheet.applyAllahHighlight(to: piece, source: string, enabled: settings.highlightAllahNamesHadith)
            if isArabic, shareFace != .basic {
                applyBasicFontToCommas(piece, size: baseSize * 1.2)
            }
            text.append(piece)
        }

        // Hide Tashkeel, the Share Ayah option's twin: strip the diacritics for a cleaner card.
        let arabicText = hideTashkeel ? hadith.arabic.removingArabicDiacriticsAndSigns : hadith.arabic

        if includeReference { append("\(book.englishTitle) \(hadith.idInBook)", font: captionFont, color: accent, alignment: .center) }
        if includeArabic, !arabicText.isEmpty { append(arabicText, font: arabicFont, color: .white, alignment: .right, isArabic: true) }
        if includeNarrator, !hadith.english.narrator.isEmpty { append(hadith.english.narrator, font: narratorFont, color: .lightGray, alignment: .left) }
        if includeEnglish, !hadith.english.text.isEmpty { append(hadith.english.text, font: englishFont, color: .white, alignment: .left) }
        if includeNote, let note = noteText { append("Note: \(note)", font: noteFont, color: .lightGray, alignment: .left) }
        guard text.length > 0 else { return nil }

        // The Al-Islam watermark, quietly at the bottom of every shared card.
        let watermark = NSAttributedString(string: "Al-Islam", attributes: [
            .font: UIFont.roundedSystemFont(ofSize: baseSize * 0.55, weight: .semibold),
            .foregroundColor: accent.withAlphaComponent(0.85),
            .paragraphStyle: paragraph(.center, spacing: 0)
        ])

        let bounds = text.boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let watermarkBounds = watermark.boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let watermarkGap: CGFloat = 28
        let height = ceil(bounds.height) + inset * 2 + watermarkGap + ceil(watermarkBounds.height)
        let canvas = CGRect(x: 0, y: 0, width: width, height: height)

        return UIGraphicsImageRenderer(size: canvas.size).image { context in
            UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1).setFill()
            UIBezierPath(roundedRect: canvas, cornerRadius: 48).fill()
            text.draw(with: CGRect(x: inset, y: inset, width: textWidth, height: ceil(bounds.height)),
                      options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            watermark.draw(with: CGRect(x: inset, y: inset + ceil(bounds.height) + watermarkGap,
                                        width: textWidth, height: ceil(watermarkBounds.height)),
                           options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        }
    }
}
#endif

