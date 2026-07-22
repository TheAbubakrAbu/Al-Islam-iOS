import SwiftUI

// Shared hadith pieces: the settings sheet, reference resolution, the hadith row, bookmark rows and
// tiles, the detail screen, immersive full-screen reading, and the Share Hadith sheet.

#if os(iOS)

// MARK: - Hadith settings

/// What a hadith row shows: Arabic, English, the narrator line, and which Arabic face. Small enough to live
/// in a sheet off the Hadith tab rather than the app settings tree.
struct HadithSettingsSheet: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store = HadithStore.shared

    /// True when presented as a sheet (its own NavigationView + dismiss X); false when PUSHED from the
    /// Settings tab, where the surrounding navigation already provides the chrome.
    var presentedAsSheet: Bool = true

    /// What's on the device at a glance: every downloaded book with its size and a per-book delete.
    @ViewBuilder
    private var downloadedBooksSection: some View {
        let downloaded = HadithCatalogBook.all.filter { store.downloadedSlugs.contains($0.slug) }
        Section(
            header: SectionPillHeader(title: "DOWNLOADED", count: downloaded.count),
            footer: downloaded.isEmpty
                ? Text("No books are downloaded. Open any book to download it, or read it once without keeping it.")
                : Text("Tap the trash to remove a book from this device. It can be downloaded again anytime.")
        ) {
            ForEach(downloaded) { book in
                HStack(spacing: 8) {
                    Text(book.englishTitle)
                        .font(.subheadline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Spacer()

                    Text("~\(book.approximateMegabytes < 1 ? "0.1" : String(format: "%.0f", book.approximateMegabytes)) MB")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { store.deleteDownload(book) }
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var body: some View {
        if presentedAsSheet {
            NavigationView {
                settingsList
                    .navigationTitle("Hadith Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .sheetDismissToolbar()
            }
        } else {
            settingsList
                .navigationTitle("Hadith Settings")
        }
    }

    /// "Use System Font Size" for the hadith Arabic - pins it to the device's Dynamic Type body size
    /// (+4, the hadith default), the Quran settings' exact pattern.
    private var useSystemArabicFontSize: Binding<Bool> {
        Binding(
            get: {
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                return settings.hadithArabicFontSize == systemBodySize + 4
            },
            set: { newValue in
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                withAnimation {
                    settings.hadithArabicFontSize = newValue ? systemBodySize + 4 : systemBodySize + 5
                }
            }
        )
    }

    /// "Use System Font Size" for the hadith English - pins it to the device's Dynamic Type body size.
    private var useSystemEnglishFontSize: Binding<Bool> {
        Binding(
            get: {
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                return settings.hadithEnglishFontSize == systemBodySize
            },
            set: { newValue in
                let systemBodySize = Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
                withAnimation {
                    settings.hadithEnglishFontSize = newValue ? systemBodySize : systemBodySize + 1
                }
            }
        )
    }

    private var settingsList: some View {
            List {
                Group {
                    Section(footer: Text("Summary mode shows Hadith of the Day and your Last Read Hadith as compact tiles, like the Quran tab.")) {
                        Toggle("Summary Mode", isOn: Binding(
                            get: { UserDefaults.standard.object(forKey: "hadithSummaryMode") == nil ? true : UserDefaults.standard.bool(forKey: "hadithSummaryMode") },
                            set: { newValue in
                                settings.hapticFeedback()
                                UserDefaults.standard.set(newValue, forKey: "hadithSummaryMode")
                            }
                        ).animation(.easeInOut))
                    }

                    Section(header: Text("TEXT")) {
                        Toggle("Show Arabic", isOn: Binding(
                            get: { settings.showHadithArabic },
                            set: { newValue in
                                settings.hapticFeedback()
                                settings.showHadithArabic = newValue
                                // Never allow both off - there would be nothing left to read.
                                if !newValue && !settings.showHadithEnglish {
                                    settings.showHadithEnglish = true
                                }
                            }
                        ).animation(.easeInOut))

                        // No separate narrator toggle: the narrator is part of the English text and
                        // simply shows whenever English does - one less switch to reason about.
                        Toggle("Show English", isOn: Binding(
                            get: { settings.showHadithEnglish },
                            set: { newValue in
                                settings.hapticFeedback()
                                settings.showHadithEnglish = newValue
                                if !newValue && !settings.showHadithArabic {
                                    settings.showHadithArabic = true
                                }
                            }
                        ).animation(.easeInOut))
                    }

                    if settings.showHadithArabic {
                        Section(header: Text("ARABIC FONT"), footer: Text("Uthmani and IndoPak are classical script styles; Basic is the standard system font.")) {
                            IslamArabicFontPicker()

                            // The Quran settings' font controls, one for one: system-size toggle,
                            // stepper, and slider.
                            VStack(alignment: .leading, spacing: 16) {
                                Toggle("Use System Font Size", isOn: useSystemArabicFontSize.animation(.easeInOut))
                                    .font(.subheadline)
                                    .padding(.vertical, 2)

                                Stepper(value: $settings.hadithArabicFontSize.animation(.easeInOut), in: 15...40, step: 1) {
                                    Text("Arabic Font Size: \(Int(settings.hadithArabicFontSize))")
                                        .font(.subheadline)
                                }

                                Slider(value: $settings.hadithArabicFontSize.animation(.easeInOut), in: 15...40, step: 1)
                            }
                            .onChange(of: settings.hadithArabicFontSize) { _ in settings.hapticFeedback() }
                        }
                    }

                    if settings.showHadithEnglish {
                        Section(header: Text("ENGLISH FONT")) {
                            VStack(alignment: .leading, spacing: 16) {
                                Toggle("Use System Font Size", isOn: useSystemEnglishFontSize.animation(.easeInOut))
                                    .font(.subheadline)
                                    .padding(.vertical, 2)

                                Stepper(value: $settings.hadithEnglishFontSize.animation(.easeInOut), in: 10...32, step: 1) {
                                    Text("English Font Size: \(Int(settings.hadithEnglishFontSize))")
                                        .font(.subheadline)
                                }

                                Slider(value: $settings.hadithEnglishFontSize.animation(.easeInOut), in: 10...32, step: 1)
                            }
                            .onChange(of: settings.hadithEnglishFontSize) { _ in settings.hapticFeedback() }
                        }
                    }

                    // No "Fit Page" toggle: hadith pages ALWAYS fit the screen (the pagination packs
                    // whole hadiths per page at the chosen sizes) - unlike the mushaf, where fixed text
                    // per page makes fitting a real choice.

                    downloadedBooksSection
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
    }
}

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

    @State private var data: HadithBookData?
    @State private var loadError: String?
    @State private var didConfirmDownload = false
    @State private var confirmDownload = false

    private var resolved: HadithBookData.Hadith? {
        guard let data else { return nil }
        if let chapter {
            guard data.chapters.indices.contains(chapter - 1) else { return nil }
            let chapterID = data.chapters[chapter - 1].id
            let inChapter = data.hadiths.filter { $0.chapterId == chapterID }
            guard inChapter.indices.contains(hadith - 1) else { return nil }
            return inChapter[hadith - 1]
        }
        return data.hadiths.first { $0.idInBook == hadith }
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
            } else if let loadError {
                Text(loadError)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else if !store.isAvailableOffline(book) && !didConfirmDownload {
                // Same courtesy as opening the book itself: never silently pull a large file.
                VStack(spacing: 12) {
                    Text("\(book.englishTitle) has not been downloaded yet (~\(String(format: "%.0f", max(book.approximateMegabytes, 1))) MB).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        settings.hapticFeedback()
                        confirmDownload = true
                    } label: {
                        Label("Download Book", systemImage: "icloud.and.arrow.down")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                    }
                }
                .padding()
                .confirmationDialog("Download \(book.englishTitle)?", isPresented: $confirmDownload, titleVisibility: .visible) {
                    Button("Download") {
                        settings.hapticFeedback()
                        didConfirmDownload = true
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This fetches the whole book for offline reading. It may use significant data - Wi-Fi is recommended.")
                }
            } else {
                ProgressView("Loading \(book.englishTitle)...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(chapter.map { "\(book.englishTitle) \($0):\(hadith)" } ?? "\(book.englishTitle) \(hadith)")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: didConfirmDownload) {
            guard data == nil, store.isAvailableOffline(book) || didConfirmDownload else { return }
            do {
                data = try await store.book(book)
            } catch {
                loadError = error.localizedDescription
            }
        }
    }
}

// MARK: - One hadith

struct HadithRow: View {
    @ObservedObject private var settings = Settings.shared
    /// The row renders ONLY bookmark/note state, so it observes the user-data object - not HadithStore,
    /// whose download/prewarm publishes used to re-render every visible row on every tick.
    @ObservedObject private var userData = HadithUserData.shared

    let book: HadithCatalogBook
    let hadith: HadithBookData.Hadith
    var searchText: String = ""
    /// The Quran ayah-search rows' scale: small type and clipped lines, for search results.
    var compact: Bool = false
    /// The paged reader's Fit Page shrink - an overflowing page passes < 1 so its text fits the screen.
    var fontScale: CGFloat = 1

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

    /// First hadith id of each chapter, memoized per (book, chapter) - the row shows the hadith's
    /// position WITHIN its chapter ("1 -" for the first hadith of a chapter that starts at #100),
    /// the ayah row's within-surah numbering, for hadiths.
    @MainActor private static var chapterStartCache: [String: Int] = [:]

    private var chapterHadithNumber: Int? {
        let key = "\(book.slug)-\(hadith.chapterId)"
        if let start = Self.chapterStartCache[key] {
            return hadith.idInBook - start + 1
        }
        // Only resolvable once the book is in the session cache - daily/summary rows before the book
        // loads simply omit the chapter position.
        guard let data = HadithStore.shared.cachedBook(book.slug),
              let start = data.hadiths.lazy.filter({ $0.chapterId == hadith.chapterId }).map(\.idInBook).min()
        else { return nil }
        Self.chapterStartCache[key] = start
        return hadith.idInBook - start + 1
    }

    private var arabicFontSize: CGFloat {
        (compact ? UIFont.preferredFont(forTextStyle: .subheadline).pointSize + 2 : settings.hadithArabicFontSize) * fontScale
    }

    private var englishFontSize: CGFloat {
        (compact ? UIFont.preferredFont(forTextStyle: .caption1).pointSize : settings.hadithEnglishFontSize) * fontScale
    }

    var body: some View {
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

            if settings.showHadithArabic, !hadith.arabic.isEmpty {
                HighlightedSnippet(
                    source: hadith.arabic,
                    term: searchText,
                    font: settings.useFontArabic
                        ? Font.arabic(settings.nonQuranArabicFontName, size: arabicFontSize)
                        : .system(size: arabicFontSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    lineLimit: compact ? 2 : nil,
                    highlightAllahNames: settings.highlightAllahNames,
                    // The classical faces draw "،" as an ornament circle - commas fall back to the
                    // system face.
                    basicFontForCommas: settings.useFontArabic ? arabicFontSize : nil
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .lineSpacing(compact ? 0 : 6)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .fixedSize(horizontal: false, vertical: !compact)
            }

            if settings.showHadithEnglish {
                // The narrator is PART of the English text - it shows whenever English does (there is no
                // separate toggle; a hadith without its isnad line reads incomplete).
                if !hadith.english.narrator.isEmpty {
                    HighlightedSnippet(
                        source: hadith.english.narrator,
                        term: searchText,
                        font: .system(size: englishFontSize).italic(),
                        accent: settings.accentColor.color,
                        fg: .secondary,
                        lineLimit: compact ? 1 : nil
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: !compact)
                }

                if !hadith.english.text.isEmpty {
                    HighlightedSnippet(
                        source: hadith.english.text,
                        term: searchText,
                        font: .system(size: englishFontSize),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        lineLimit: compact ? 3 : nil,
                        highlightAllahNames: settings.highlightAllahNames
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: !compact)
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
struct HadithBookmarkRow: View {
    @ObservedObject private var settings = Settings.shared
    /// Bookmark rows render only user marks - observe the user-data object, not the whole store.
    @ObservedObject private var userData = HadithUserData.shared

    let bookmark: HadithBookmark

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
struct HadithBookmarkGridTile: View {
    @ObservedObject private var settings = Settings.shared

    let bookmark: HadithBookmark
    let onTap: () -> Void

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
        if flag("shareHadithReference") { parts.append("[\(book.englishTitle) \(hadith.idInBook)]") }
        if flag("shareHadithArabic"), !hadith.arabic.isEmpty {
            // Hide Tashkeel strips the diacritics for a cleaner shared text, the Share Ayah option's twin.
            let arabic = defaults.bool(forKey: "shareHadithHideTashkeel")
                ? hadith.arabic.removingArabicDiacriticsAndSigns
                : hadith.arabic
            parts.append(arabic)
        }
        if flag("shareHadithNarrator"), !hadith.english.narrator.isEmpty { parts.append(hadith.english.narrator) }
        if flag("shareHadithEnglish"), !hadith.english.text.isEmpty { parts.append(hadith.english.text) }
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
                            Text(ShareAyahSheet.allahHighlightedSwiftUIText(composed, baseColor: .white, enabled: settings.highlightAllahNames))
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
            ShareAyahSheet.applyAllahHighlight(to: piece, source: string, enabled: settings.highlightAllahNames)
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
