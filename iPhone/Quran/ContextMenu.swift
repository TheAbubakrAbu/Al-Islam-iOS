import SwiftUI
#if os(iOS)
import UIKit
#endif

/// The one format every ayah sheet titles itself with: "Surah Name S:A" (or "Surah Name S:A-B" for a sheet
/// that covers a range, e.g. a tafsir that groups several ayahs). Kept in a single helper so the sheets can
/// never drift apart again ("Preview", "Qiraah Comparison", ... all used to invent their own).
func ayahSheetTitle(surahNumber: Int, ayahNumber: Int, endAyah: Int? = nil) -> String {
    let name = QuranData.shared.surah(surahNumber)?.nameTransliteration ?? "Surah"
    if let endAyah, endAyah > ayahNumber {
        return "\(name) \(surahNumber):\(ayahNumber)-\(endAyah)"
    }
    return "\(name) \(surahNumber):\(ayahNumber)"
}

/// The English translation currently being shown, by name - so ayah sheets can mention it consistently.
/// Mirrors the reader's own precedence (Saheeh unless only Mustafa is enabled).
func currentTranslationDisplayName() -> String {
    let settings = Settings.shared
    return (settings.showEnglishSaheeh || !settings.showEnglishMustafa)
        ? "Saheeh International"
        : "Clear Quran (Mustafa Khattab)"
}

/// The ayah's text in the currently-shown English translation (same precedence as the name above), or nil
/// when translations don't apply (non-Hafs display) or the text is empty. This is what ayah sheets show
/// under the reference - the actual translation, not just its name.
func currentTranslationText(for ayah: Ayah) -> String? {
    let settings = Settings.shared
    guard settings.isHafsDisplay else { return nil }
    let text = (settings.showEnglishSaheeh || !settings.showEnglishMustafa)
        ? ayah.textEnglishSaheeh
        : ayah.textEnglishMustafa
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}

struct SurahContextMenu: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @ObservedObject var quranPlayer = QuranPlayer.shared

    let surahID: Int
    let surahName: String

    let favoriteSurahs: Set<Int>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    var lastListened: Bool?

    private var isFavorite: Bool {
        favoriteSurahs.contains(surahID)
    }

    private var canAddToQueue: Bool {
        quranPlayer.isPlaying || quranPlayer.isPaused
    }

    var body: some View {
        #if os(iOS)
        if let surah = quranData.surah(surahID) {
            Button {
                settings.hapticFeedback()
                FocusOverlayPresenter.shared.present(.surah(surah))
            } label: {
                Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
            }

            Button {
                settings.hapticFeedback()
                presentSystemShareSheet(items: [FocusItem.surah(surah).shareText])
            } label: {
                Label("Share Surah", systemImage: "square.and.arrow.up")
            }

            Divider()
        }
        #endif

        Button(role: isFavorite ? .destructive : .cancel) {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.toggleSurahFavorite(surah: surahID)
            }
        } label: {
            Label(
                isFavorite ? "Unfavorite Surah" : "Favorite Surah",
                systemImage: isFavorite ? "star.fill" : "star"
            )
        }

        Button {
            settings.hapticFeedback()

            if let surah = quranData.surah(surahID) {
                if let randomAyah = surah.ayahs.randomElement() {
                    quranPlayer.playAyah(
                        surahNumber: surahID,
                        ayahNumber: randomAyah.id,
                        continueRecitation: true
                    )
                }
            }
        } label: {
            Label("Play Random Ayah", systemImage: "shuffle.circle")
        }

        if lastListened == nil {
            Button {
                settings.hapticFeedback()

                quranPlayer.playSurah(surahNumber: surahID, surahName: surahName)
            } label: {
                Label("Play Surah", systemImage: "play.fill")
            }
        }

        if canAddToQueue {
            Button {
                settings.hapticFeedback()
                quranPlayer.addSurahToQueue(surahNumber: surahID, surahName: surahName)
            } label: {
                Label("Add to Queue", systemImage: "text.line.last.and.arrowtriangle.forward")
            }
        }

        Button {
            settings.hapticFeedback()

            withAnimation {
                searchText = ""
                scrollToSurahID = surahID
                self.endEditing()
            }
        } label: {
            Text("Scroll To Surah")
            Image(systemName: "arrow.down.circle")
        }
    }
}

#if os(iOS)
enum TafsirAuthor: String, CaseIterable, Identifiable {
    // English (originally quranapi.pages.dev; now bundled as .tpk packs).
    case ibnKathir = "Ibn Kathir"
    case maarifUlQuran = "Maarif Ul Quran"
    case tazkirulQuran = "Tazkirul Quran"
    // Arabic (originally spa5k/tafsir_api; now bundled as .tpk packs).
    case ibnKathirArabic = "Tafsir Ibn Kathir (Arabic)"
    case tabariArabic = "Tafsir al-Tabari (Arabic)"
    case saadiArabic = "Tafsir as-Sa'di (Arabic)"

    var id: String { rawValue }

    /// The bundled pack for this edition (Resources/Data/Tafsir/{slug}.tpk, built by
    /// Tafsir-Corpus/build_tpk.py).
    var packSlug: String {
        switch self {
        case .ibnKathir:       return "en-tafsir-ibn-kathir"
        case .maarifUlQuran:   return "en-tafsir-maarif-ul-quran"
        case .tazkirulQuran:   return "en-tafsir-tazkirul-quran"
        case .ibnKathirArabic: return "ar-tafsir-ibn-kathir"
        case .tabariArabic:    return "ar-tafsir-al-tabari"
        case .saadiArabic:     return "ar-tafsir-as-saadi"
        }
    }

    var isArabic: Bool {
        switch self {
        case .ibnKathirArabic, .tabariArabic, .saadiArabic: return true
        default: return false
        }
    }

    static var englishCases: [TafsirAuthor] { allCases.filter { !$0.isArabic } }
    static var arabicCases: [TafsirAuthor] { allCases.filter { $0.isArabic } }

    var shortTitle: String {
        switch self {
        case .ibnKathir:       return "Ibn Kathir"
        case .maarifUlQuran:   return "Maarif"
        case .tazkirulQuran:   return "Tazkirul"
        case .ibnKathirArabic: return "ابن كثير"
        case .tabariArabic:    return "الطبري"
        case .saadiArabic:     return "السعدي"
        }
    }

    /// The heading shown above the tafsir body.
    var displayTitle: String {
        switch self {
        case .ibnKathirArabic: return "تفسير ابن كثير"
        case .tabariArabic:    return "تفسير الطبري"
        case .saadiArabic:     return "تفسير السعدي"
        default:               return rawValue
        }
    }

    func matches(_ author: String) -> Bool {
        normalized(author) == normalized(rawValue)
    }

    private func normalized(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

/// The standard "this content comes from the Internet" card, used by the online translation
/// comparison so online-backed sheets all disclose it the same way. (The tafsir sheet no longer
/// qualifies - every tafsir is bundled and read offline.)
struct OnlineNoticeCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Loaded from the Internet", systemImage: "icloud.and.arrow.down")
                .font(.subheadline.weight(.semibold))

            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

/// One tafsir entry as the sheets consume it. `groupVerse` is the source's own group sentence,
/// verbatim ("You are reading a tafsir for the group of verses 2:4 to 2:5"), which the sheet's
/// existing parser turns into the "Al-Baqarah 2:4-5" title; the Arabic editions carry none.
struct AyahTafsirEntry: Identifiable {
    let author: String
    let groupVerse: String?
    let content: String

    var id: String { author }
}

/// The tafsir data layer: six memory-mapped bundled packs (Resources/Data/Tafsir/*.tpk), one per
/// edition. Everything is on disk inside the app, so every read is synchronous and offline - there
/// is no fetch, no cache to warm, and no download machinery. Opening a pack costs its ~75 KB ayah
/// index; a read decompresses one ~256 KB block through the shared TafsirBlockCache.
@MainActor
final class TafsirStore {
    static let shared = TafsirStore()

    private init() {
        // The decompressed blocks are rebuildable from the bundle in a millisecond each - under
        // real memory pressure they all go rather than letting jetsam make the decision (the
        // HadithStore pattern). The packs stay mapped: a memory map is not resident memory.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main
        ) { _ in
            TafsirBlockCache.shared.purge()
        }
    }

    private var packs: [String: TafsirPack] = [:]
    /// Slugs whose bundled pack failed to open (missing from the bundle, or corrupt) - remembered
    /// so a broken pack is probed once, not on every read.
    private var failed: Set<String> = []

    private func pack(_ author: TafsirAuthor) -> TafsirPack? {
        let slug = author.packSlug
        if let open = packs[slug] { return open }
        guard !failed.contains(slug) else { return nil }
        guard let url = TafsirPack.bundledURL(slug), let pack = TafsirPack(slug: slug, url: url) else {
            failed.insert(slug)
            return nil
        }
        packs[slug] = pack
        return pack
    }

    /// One edition's tafsir for one ayah - synchronous, instant, always offline.
    func entry(author: TafsirAuthor, surah: Int, ayah: Int) -> AyahTafsirEntry? {
        guard let entry = pack(author)?.entry(surah: surah, ayah: ayah) else { return nil }
        return AyahTafsirEntry(author: author.rawValue, groupVerse: entry.groupVerse, content: entry.content)
    }

    /// Delete the pre-pack download cache, once. Before the editions shipped inside the app they
    /// were fetched to `Application Support/TafsirCache`, and a reader who had downloaded them all
    /// is carrying up to ~345 MB there that nothing will ever read again - and with the Downloads
    /// screen gone, no way to find it. Runs off-main at launch, and only until it succeeds.
    /// (The HadithStore.purgeLegacyDownloadCache pattern.)
    static func purgeLegacyDownloadCache() {
        let flag = "tafsirLegacyCachePurged"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        Task.detached(priority: .background) {
            guard let base = try? FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false
            ) else { return }
            let directory = base.appendingPathComponent("TafsirCache", isDirectory: true)
            if FileManager.default.fileExists(atPath: directory.path) {
                try? FileManager.default.removeItem(at: directory)
            }
            await MainActor.run { UserDefaults.standard.set(true, forKey: flag) }
        }
    }
}

#endif

struct AyahContextMenuModifier: ViewModifier {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    /// NOT @ObservedObject: the player is only ever touched inside button-action closures here, never
    /// in the render path - but observing it re-ran this modifier's body on every visible ayah row
    /// each time the player published (it publishes `currentAyahNumber` once per ayah while a surah
    /// plays). Observation invalidates whether or not the body reads the object.
    private var quranPlayer: QuranPlayer { .shared }

    let surah: Int
    let ayah: Int

    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    let lastRead: Bool
    /// When true, the menu leads with "Hide for Today" + "Delete Forever" (the Ayah of the Day card).
    var ayahOfTheDay: Bool = false
    /// When true, an ellipsis actions button is overlaid at the row's top-trailing corner - the
    /// HadithRow header grammar for the compact search rows, which reserve a 22pt slot for it. The
    /// button opens the SAME menu the long-press does, from the same modifier, so both entrances
    /// share every sheet and confirmation for free.
    var inlineEllipsis: Bool = false

    @State var showAyahSheet = false

    @State private var showingNoteSheet = false
    @State private var draftNote: String = ""
    @State private var showRespectAlert = false
    @State private var showCustomRangeSheet = false
    @State private var showTafsirSheet = false
    @State private var showQiraahComparisonSheet = false
    @State private var showEnglishComparisonSheet = false

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah)-\(ayah)")
    }

    func containsProfanity(_ text: String) -> Bool {
        textContainsProfanity(text)
    }

    private func isNoteAllowed(_ text: String) -> Bool {
        !containsProfanity(text)
    }

    private var bookmarkIndex: Int? {
        settings.bookmarkIndex(surah: surah, ayah: ayah)
    }

    private var bookmark: BookmarkedAyah? {
        settings.bookmarkedAyah(surah: surah, ayah: ayah)
    }

    private var isBookmarkedHere: Bool { bookmarkIndex != nil }
    private var currentNote: String {
        settings.bookmarkNoteText(surah: surah, ayah: ayah)
    }

    private var canCompareEnglishText: Bool {
        settings.isHafsDisplay
    }

    #if os(iOS)
    @ViewBuilder
    private var comparisonMenuBlock: some View {
        if settings.showQiraahDetails && canCompareEnglishText {
            Menu {
                Button {
                    settings.hapticFeedback()
                    showQiraahComparisonSheet = true
                } label: {
                    Label("Qiraah Comparison", systemImage: "character.book.closed.fill.ar")
                }

                Button {
                    settings.hapticFeedback()
                    showEnglishComparisonSheet = true
                } label: {
                    Label("Translation Comparison", systemImage: "character.book.closed")
                }
            } label: {
                Label("Compare Ayah", systemImage: "rectangle.split.2x1")
            }
        } else if settings.showQiraahDetails {
            Button {
                settings.hapticFeedback()
                showQiraahComparisonSheet = true
            } label: {
                Label("Qiraah Comparison", systemImage: "character.book.closed.fill.ar")
            }
        } else if canCompareEnglishText {
            Button {
                settings.hapticFeedback()
                showEnglishComparisonSheet = true
            } label: {
                Label("Translation Comparison", systemImage: "character.book.closed")
            }
        }
    }
    #endif

    private func setNote(_ text: String?) {
        settings.setBookmarkNote(surah: surah, ayah: ayah, note: text)
    }

    private func removeNote() {
        settings.removeBookmarkNote(surah: surah, ayah: ayah)
    }

    @State private var confirmRemoveNote = false
    @State private var confirmDeleteForever = false

    private func toggleBookmarkWithNoteGuard() {
        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah, ayah: ayah) {
            confirmRemoveNote = true
        }
    }

    /// The full action list, shared verbatim by the long-press context menu and (when
    /// `inlineEllipsis` is on) the header ellipsis Menu - one list, two entrances, the HadithRow
    /// grammar. Lives on this modifier because every sheet it opens presents from here.
    #if os(iOS)
    @ViewBuilder
    private func menuItems(surahObj: Surah?) -> some View {
                if ayahOfTheDay {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation {
                            settings.ayahOfTheDayHiddenDate = Settings.dayKey()
                        }
                    } label: { Label("Hide for Today", systemImage: "eye.slash") }

                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        confirmDeleteForever = true
                    } label: { Label("Delete Forever", systemImage: "trash") }

                    Divider()
                } else if lastRead {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation {
                            settings.lastReadSurah = 0
                            settings.lastReadAyah = 0
                        }
                    } label: { Label("Remove", systemImage: "minus.circle") }

                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        confirmDeleteForever = true
                    } label: { Label("Delete Forever", systemImage: "trash") }

                    Divider()
                }

                Button(role: isBookmarked ? .destructive : .cancel) {
                    settings.hapticFeedback()
                    toggleBookmarkWithNoteGuard()
                } label: {
                    Label(
                        isBookmarked ? "Unbookmark Ayah" : "Bookmark Ayah",
                        systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                    )
                }

                Button {
                    settings.hapticFeedback()
                    if !isBookmarked {
                        settings.ensureBookmarkExists(surah: surah, ayah: ayah)
                    }
                    draftNote = currentNote
                    showingNoteSheet = true
                } label: {
                    Label(currentNote.isEmpty ? "Add Note" : "Edit Note", systemImage: "note.text")
                }

                if !currentNote.isEmpty {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) {
                            removeNote()
                        }
                    } label: {
                        Label("Remove Note", systemImage: "minus.circle")
                    }
                }

                if settings.isHafsDisplay {
                    Button {
                        settings.hapticFeedback()
                        showTafsirSheet = true
                    } label: {
                        Label("See Tafsir", systemImage: "text.book.closed")
                    }
                }

                comparisonMenuBlock

                if settings.isHafsDisplay {
                    Menu {
                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playAyah(surahNumber: surah, ayahNumber: ayah)
                        } label: {
                            Label("Play This Ayah", systemImage: "play.circle")
                        }
                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playAyah(
                                surahNumber: surah,
                                ayahNumber: ayah,
                                continueRecitation: true
                            )
                        } label: {
                            Label("Play From Ayah", systemImage: "play.circle.fill")
                        }
                        Button {
                            settings.hapticFeedback()
                            showCustomRangeSheet = true
                        } label: {
                            Label("Play Custom Range", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Label("Play Ayah", systemImage: "play.circle")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    ShareAyahSheet.copyAyahToPasteboard(surahNumber: surah, ayahNumber: ayah, settings: settings, quranData: quranData)
                } label: {
                    Label("Copy Ayah", systemImage: "doc.on.doc")
                }

                Button {
                    settings.hapticFeedback()
                    showAyahSheet = true
                } label: {
                    Label("Share Ayah", systemImage: "square.and.arrow.up")
                }

                Divider()

                if let surah = surahObj {
                    SurahContextMenu(
                        surahID: surah.id,
                        surahName: surah.nameTransliteration,
                        favoriteSurahs: favoriteSurahs,
                        searchText: $searchText,
                        scrollToSurahID: $scrollToSurahID
                    )
                }
    }
    #endif

    @ViewBuilder
    func body(content: Content) -> some View {
        // O(1) dictionary lookup, not an O(114) linear scan. This `body` re-evaluates whenever
        // `settings` publishes, and the modifier sits on every history/bookmark/favorite row - the
        // linear scan added up across all visible rows.
        let surahObj = quranData.surah(surah)

        #if os(iOS)
        content
            .contextMenu {
                menuItems(surahObj: surahObj)
            }
            .overlay(alignment: .topTrailing) {
                if inlineEllipsis {
                    Menu {
                        Text("Ayah Actions")
                            .foregroundStyle(.secondary)

                        menuItems(surahObj: surahObj)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 19, height: 19)
                            .foregroundColor(settings.accentColor.color)
                            .conditionalGlassEffect()
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    // Lands in the 22pt slot the compact search row reserves at its header's
                    // trailing edge; the 2pt matches the row's own vertical padding.
                    .padding(.top, 2)
                }
            }
            .sheet(isPresented: $showAyahSheet) {
                ShareAyahSheet(
                    surahNumber: surah,
                    ayahNumber: ayah
                )
                .smallMediumSheetPresentation()
            }
            .sheet(isPresented: $showTafsirSheet) {
                if let surahObj = surahObj {
                    AyahTafsirSheet(
                        surahName: surahObj.nameTransliteration,
                        surahNumber: surahObj.id,
                        ayahNumber: ayah
                    )
                    .smallMediumSheetPresentation()
                }
            }
            .sheet(isPresented: $showCustomRangeSheet) {
                if let surahObj = surahObj {
                    PlayCustomRangeSheet(
                        surah: surahObj,
                        initialStartAyah: ayah,
                        initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                            startAyah: ayah,
                            surah: surahObj,
                            displayQiraah: settings.displayQiraahForArabic
                        ),
                        onPlay: { start, end, repAyah, repSec in
                            quranPlayer.playCustomRange(
                                surahNumber: surahObj.id,
                                surahName: surahObj.nameTransliteration,
                                startAyah: start,
                                endAyah: end,
                                repeatPerAyah: repAyah,
                                repeatSection: repSec
                            )
                        },
                        onCancel: { showCustomRangeSheet = false }
                    )
                    .environmentObject(settings)
                    .smallMediumSheetPresentation()
                }
            }
            .sheet(isPresented: $showQiraahComparisonSheet) {
                AyahQiraahComparisonSheet(surahNumber: surah, ayahNumber: ayah)
                    .smallMediumSheetPresentation()
                    .environmentObject(settings)
                    .environmentObject(quranData)
            }
            .sheet(isPresented: $showEnglishComparisonSheet) {
                AyahEnglishComparisonSheet(surahNumber: surah, ayahNumber: ayah)
                    .smallMediumSheetPresentation()
                    .environmentObject(settings)
                    .environmentObject(quranData)
            }
            .sheet(isPresented: $showingNoteSheet) {
                if let surah = surahObj {
                    NoteEditorSheet(
                        title: "Note for \(surah.nameTransliteration) \(surah.id):\(ayah)",
                        text: $draftNote,
                        onAttemptSave: { text in
                            if isNoteAllowed(text) {
                                setNote(text)
                                return true
                            } else {
                                showRespectAlert = true
                                return false
                            }
                        },
                        onCancel: {},
                        onSave: { setNote(draftNote) }
                    )
                    .smallMediumSheetPresentation()
                }
            }
            .confirmationDialog("Note not saved", isPresented: $showRespectAlert, titleVisibility: .visible) {
                Button("OK") { }
            } message: {
                Text("Please keep notes Islamic and respectful.")
            }
            .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    settings.hapticFeedback()
                    settings.toggleBookmark(surah: surah, ayah: ayah)
                }
                Button("Cancel") {}
            } message: {
                Text(Settings.bookmarkNoteRemovalDialogMessage)
            }
            .confirmationDialog("Are you sure?", isPresented: $confirmDeleteForever, titleVisibility: .visible) {
                Button("Remove Permanently", role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        if ayahOfTheDay {
                            settings.showAyahOfTheDay = false
                        } else {
                            settings.lastReadSurah = 0
                            settings.lastReadAyah = 0
                            settings.saveLastReadAyah = false
                        }
                    }
                }
                Button("Cancel") {}
            } message: {
                Text(ayahOfTheDay
                     ? "You can re-enable Ayah of the Day later in Quran Settings."
                     : "You can re-enable Last Read Ayah later in Quran Settings.")
            }
        #else
        content
        #endif
    }
}

extension View {
    func ayahContextMenuModifier(
        surah: Int,
        ayah: Int,
        favoriteSurahs: Set<Int>,
        bookmarkedAyahs: Set<String>,
        searchText: Binding<String>,
        scrollToSurahID: Binding<Int>,
        lastRead: Bool = false,
        ayahOfTheDay: Bool = false,
        inlineEllipsis: Bool = false
    ) -> some View {
        self.modifier(AyahContextMenuModifier(
            surah: surah,
            ayah: ayah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: searchText,
            scrollToSurahID: scrollToSurahID,
            lastRead: lastRead,
            ayahOfTheDay: ayahOfTheDay,
            inlineEllipsis: inlineEllipsis
        ))
    }
}

struct LeftSwipeActions: ViewModifier {
    @ObservedObject private var settings = Settings.shared

    let surah: Int
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>?
    let bookmarkedSurah: Int?
    let bookmarkedAyah: Int?

    private var isFavorite: Bool {
        favoriteSurahs.contains(surah)
    }

    private var isBookmarked: Bool {
        if let bookmarkedAyahs, let s = bookmarkedSurah, let a = bookmarkedAyah {
            return bookmarkedAyahs.contains("\(s)-\(a)")
        }
        return false
    }

    private var bookmarkIndex: Int? {
        let surah = bookmarkedSurah ?? 1
        let ayah = bookmarkedAyah ?? 1

        return settings.bookmarkIndex(surah: surah, ayah: ayah)
    }

    private var bookmark: BookmarkedAyah? {
        settings.bookmarkedAyah(surah: bookmarkedSurah ?? 1, ayah: bookmarkedAyah ?? 1)
    }

    private var isBookmarkedHere: Bool { bookmarkIndex != nil }

    private var currentNote: String {
        settings.bookmarkNoteText(surah: bookmarkedSurah ?? 1, ayah: bookmarkedAyah ?? 1)
    }

    @State private var confirmRemoveNote = false

    private func toggleBookmarkWithNoteGuard(_ surah: Int, _ ayah: Int) {
        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah, ayah: ayah) {
            confirmRemoveNote = true
        }
    }

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .swipeActions(edge: .leading) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.toggleSurahFavorite(surah: surah)
                    }
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .tint(settings.accentColor.color)

                if let s = bookmarkedSurah, let a = bookmarkedAyah {
                    Button {
                        settings.hapticFeedback()
                        toggleBookmarkWithNoteGuard(s, a)
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                    .tint(settings.accentColor.color)
                }
            }
            #endif
            .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    settings.hapticFeedback()
                    settings.toggleBookmark(surah: bookmarkedSurah ?? 1, ayah: bookmarkedAyah ?? 1)
                }
                Button("Cancel") {}
            } message: {
                Text(Settings.bookmarkNoteRemovalDialogMessage)
            }
    }
}

public extension View {
    func leftSwipeActions(
        surah: Int,
        favoriteSurahs: Set<Int>,
        bookmarkedAyahs: Set<String>? = nil,
        bookmarkedSurah: Int? = nil,
        bookmarkedAyah: Int? = nil
    ) -> some View {
        modifier(LeftSwipeActions(
            surah: surah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            bookmarkedSurah: bookmarkedSurah,
            bookmarkedAyah: bookmarkedAyah
        ))
    }
}

struct RightSwipeActions: ViewModifier {
    @ObservedObject private var settings = Settings.shared
    /// NOT @ObservedObject - action-closure use only; see AyahContextMenuModifier's note. This
    /// modifier also sits on every row, so player publishes fanned out across the whole list.
    private var quranPlayer: QuranPlayer { .shared }

    let surahID: Int
    let surahName: String
    let ayahID: Int?
    let certainReciter: Bool

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    private func endEditing() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .swipeActions(edge: .trailing) {
                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: surahID,
                        surahName: surahName,
                        certainReciter: certainReciter
                    )
                } label: {
                    Image(systemName: "play.fill")
                }
                .tint(settings.accentColor.color)

                if let ayah = ayahID {
                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playAyah(surahNumber: surahID, ayahNumber: ayah)
                    } label: {
                        Image(systemName: "play.circle")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        searchText = ""
                        scrollToSurahID = surahID
                        endEditing()
                    }
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .tint(.secondary)
            }
            #endif
    }
}

public extension View {
    func rightSwipeActions(
        surahID: Int,
        surahName: String,
        ayahID: Int? = nil,
        certainReciter: Bool = false,
        searchText: Binding<String>,
        scrollToSurahID: Binding<Int>
    ) -> some View {
        modifier(RightSwipeActions(
            surahID: surahID,
            surahName: surahName,
            ayahID: ayahID,
            certainReciter: certainReciter,
            searchText: searchText,
            scrollToSurahID: scrollToSurahID
        ))
    }
}

#if os(iOS)
import SwiftUI

struct NoteEditorSheet: View {
    @ObservedObject var settings = Settings.shared

    let title: String
    @Binding var text: String
    var onAttemptSave: (String) -> Bool
    var onCancel: () -> Void
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    private let maxChars: Int = 300

    private var characterCount: Int { text.count }
    private var remaining: Int { max(0, maxChars - characterCount) }
    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                let cardFill   = Color(UIColor.secondarySystemBackground)
                let cardStroke = Color.primary.opacity(0.12)

                TextEditor(text: $text)
                    .padding(12)
                    .background(Color.clear)
                    .frame(minHeight: 220)
                    .modifier(HideEditorScrollBackground())
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .onChange(of: text) { newValue in
                        if newValue.count > maxChars {
                            text = String(newValue.prefix(maxChars))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(cardFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(cardStroke, lineWidth: 1)
                    )

                Text("\(remaining) characters left")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Character limit")
                    .accessibilityValue("\(maxChars) limit, \(remaining) remaining")

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "hands.sparkles")
                            .imageScale(.large)
                        Text("A respectful reminder")
                            .font(.headline)
                    }
                    .foregroundColor(.accentColor)

                    Text("Your note will appear next to the Quran, the Words of Allah ﷻ. Please keep it dignified and beneficial.")
                        .font(.subheadline)

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Avoid profanity or insults", systemImage: "checkmark.seal")
                        Label("No mockery, slurs, or indecency", systemImage: "checkmark.seal")
                        Label("Keep remarks relevant and respectful", systemImage: "checkmark.seal")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)

                    Text("May Allah ﷻ reward you, protect you, and keep us all firm upon the truth.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
                .accessibilityElement(children: .combine)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(cardFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(cardStroke, lineWidth: 1)
                )
            }
            .padding(.horizontal)
            // Full-size BEFORE the wash: this VStack hugs its content, and a background on a hugging
            // view would paint a floating rectangle instead of covering the sheet.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .accentWashedBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        settings.hapticFeedback()
                        onCancel()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(settings.accentColor.color)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        settings.hapticFeedback()
                        if onAttemptSave(text) {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(settings.accentColor.color)
                    .disabled(isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private struct HideEditorScrollBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
                .onAppear {
                    UITextView.appearance().backgroundColor = .clear
                }
        }
    }
}

private struct SurahContextMenuPreviewContent: View {
    @State private var searchText = ""
    @State private var scrollToSurahID = 0

    var body: some View {
        Menu("Open Surah Actions") {
            SurahContextMenu(
                surahID: AlIslamPreviewData.surah.id,
                surahName: AlIslamPreviewData.surah.nameTransliteration,
                favoriteSurahs: [],
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
        }
        .padding()
    }
}

// The generic focus overlay lives in Helpers and knows nothing about the Quran; a surah teaches it how to
// render itself here, so the overlay stays usable in an app that ships without a Quran.
extension FocusItem {
    static func surah(_ surah: Surah) -> FocusItem {
        FocusItem(
            id: "surah-\(surah.id)",
            arabic: surah.nameArabic,
            title: "\(surah.id) · \(surah.nameTransliteration)",
            subtitle: surah.nameEnglish,
            footnote: "\(surah.type.capitalized) · \(surah.numberOfAyahs) ayahs",
            secondaryArabic: surah.idArabic,
            shareLabel: "Share Surah",
            shareText: """
            Surah \(surah.id) - \(surah.nameTransliteration) (\(surah.nameArabic))
            \(surah.nameEnglish)
            \(surah.type.capitalized) · \(surah.numberOfAyahs) ayahs
            """
        )
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        SurahContextMenuPreviewContent()
    }
}

/// Lets you pull text out of an ayah by hand: drag over any part of the Arabic, the transliteration, or a
/// translation and copy exactly that.
///
/// The reader already has "Copy Ayah", but that copies the whole thing in a fixed format. Selecting inside a row in
/// the surah list is fussy at best, because the row is competing for the same drag with the list's scroll. Lifting
/// the text into a sheet of its own gives the selection somewhere to live, and each block also gets a one-tap copy
/// for when the whole block is what you wanted.
struct SelectAyahTextSheet: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    let surah: Surah
    let ayah: Ayah

    @State private var copiedLabel: String?
    // The sheet's own riwayah, seeded from the reading view's, so switching here never disturbs the reader.
    @State private var selectedQiraah: String = Settings.normalizeLegacyRiwayahTag(Settings.shared.displayQiraah)

    // The sheet's own cleanup switches - the reading view's exact Hide Tashkeel / Hide Dots options,
    // seeded from its settings but scoped to the text you are selecting here.
    @State private var hideTashkeel = Settings.shared.cleanArabicText
    @State private var hideDots = Settings.shared.removeArabicDots

    // The sheet's own Arabic face, seeded from what the reader is showing for the current riwayah -
    // switching here restyles only the text being selected, never the reading view.
    @State private var selectedFontName: String = Settings.shared.quranArabicFontName(
        for: Settings.normalizeLegacyRiwayahTag(Settings.shared.displayQiraah)
    )

    private var usesCustomArabicFace: Bool {
        // The bundled faces carry no glyphs for the dotless skeleton letters, so hiding dots
        // falls back to the system face - the reading view's own rule.
        !hideDots && selectedFontName != Settings.systemArabicFontName
    }

    private var ayahExistsInSelectedQiraah: Bool {
        ayah.existsInQiraah(selectedQiraah, surahID: surah.id)
    }

    private var arabicText: String {
        var text = ayah.displayArabicText(
            surahId: surah.id,
            clean: hideTashkeel,
            qiraahOverride: selectedQiraah
        )
        if hideDots { text = text.removingArabicDots }
        return text
    }

    private var arabicFontName: String {
        selectedFontName
    }

    var body: some View {
        NavigationView {
            List {
                Group {
                    if settings.showQiraahDetails {
                        Section {
                            ArabicTextRiwayahPicker(selection: $selectedQiraah.animation(.easeInOut), useMenuRow: true)
                        } footer: {
                            Text("Switching the riwayah changes the Arabic text only. Ayah numbering can differ between riwayat: no ayah is ever missing, but some are joined or split differently (for example, \"Alif Lam Meem\" and \"Dhalika al-Kitab...\" form a single ayah in most qiraat), so this ayah may appear under a different number or merged with its neighbor.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Section {
                        Picker("Arabic Font", selection: $selectedFontName.animation(.easeInOut)) {
                            Text("Uthmani").tag(Settings.hafsUthmaniFontName)
                            Text("Maghribi").tag(Settings.warshUthmaniFontName)
                            Text("Indopak").tag(Settings.indopakFontName)
                            Text("Basic").tag(Settings.systemArabicFontName)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .disabled(hideDots)
                        .onChange(of: selectedFontName) { _ in settings.hapticFeedback() }

                        Toggle("Hide Tashkeel (Vowel Diacritics) and Signs", isOn: $hideTashkeel.animation(.easeInOut))
                            .font(.subheadline)
                            .onChange(of: hideTashkeel) { _ in settings.hapticFeedback() }

                        if hideTashkeel || hideDots {
                            Toggle("Hide Arabic Dots", isOn: $hideDots.animation(.easeInOut))
                                .font(.subheadline)
                                .onChange(of: hideDots) { _ in settings.hapticFeedback() }
                        }
                    } footer: {
                        Text("Shapes only the Arabic text below; the reading view keeps its own settings. Hiding Arabic dots always uses the Basic face - the classical faces have no dotless letterforms.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if ayahExistsInSelectedQiraah {
                        selectableBlock(
                            title: "ARABIC",
                            text: arabicText,
                            font: usesCustomArabicFace
                                ? .custom(arabicFontName, size: settings.fontArabicSize)
                                : .system(size: settings.fontArabicSize, design: .rounded),
                            isArabic: true
                        )
                    } else {
                        Section(header: Text("ARABIC")) {
                            Text("This ayah is not separate in this riwayah; its words are part of a neighboring ayah.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    if !ayah.textTransliteration.isEmpty {
                        selectableBlock(
                            title: "TRANSLITERATION",
                            text: ayah.textTransliteration,
                            font: .system(size: settings.englishFontSize),
                            isArabic: false
                        )
                    }

                    if !ayah.textEnglishSaheeh.isEmpty {
                        selectableBlock(
                            title: "SAHEEH INTERNATIONAL",
                            text: ayah.textEnglishSaheeh,
                            font: .system(size: settings.englishFontSize),
                            isArabic: false
                        )
                    }

                    if !ayah.textEnglishMustafa.isEmpty {
                        selectableBlock(
                            title: "CLEAR QURAN (MUSTAFA KHATTAB)",
                            text: ayah.textEnglishMustafa,
                            font: .system(size: settings.englishFontSize),
                            isArabic: false
                        )
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
            .navigationTitle(ayahSheetTitle(surahNumber: surah.id, ayahNumber: ayah.id))
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private func selectableBlock(title: String, text: String, font: Font, isArabic: Bool) -> some View {
        Section {
            // A real (read-only) UITextView, not `Text(...).textSelection(.enabled)`. Inside a List row, that
            // modifier loses the press-and-drag to the list's own scroll gesture, so all you ever get is a
            // whole-block "Copy" on long press - never the partial highlight this sheet exists to provide.
            SelectableTextView(
                text: text,
                font: resolvedUIFont(font, isArabic: isArabic),
                isArabic: isArabic,
                lineSpacing: isArabic ? 8 : 2
            )
            .padding(.vertical, 4)
        } header: {
            HStack {
                Text(title)

                Spacer()

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = text
                    withAnimation(.easeInOut) { copiedLabel = title }
                    // Long enough to read, short enough that it doesn't linger into the next copy.
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

    /// The sheet's fonts are declared as SwiftUI `Font`s; the text view needs `UIFont`s. Resolved here rather
    /// than plumbed through, so the call sites keep reading the way the rest of the app's Arabic sites do.
    private func resolvedUIFont(_ font: Font, isArabic: Bool) -> UIFont {
        if isArabic {
            let size = CGFloat(settings.fontArabicSize)
            if usesCustomArabicFace, let custom = UIFont(name: arabicFontName, size: size) {
                return custom
            }
            return .roundedSystemFont(ofSize: size)
        }
        return .roundedSystemFont(ofSize: CGFloat(settings.englishFontSize))
    }
}

/// Read-only, selectable text. `isEditable = false` with `isSelectable = true` gives exactly what is wanted
/// here: you can drag to highlight any part of the passage and copy it, but you cannot alter a word of it.
private struct SelectableTextView: UIViewRepresentable {
    let text: String
    let font: UIFont
    let isArabic: Bool
    let lineSpacing: CGFloat

    /// A non-scrolling text view whose intrinsic height always reflects the CURRENT width's layout.
    /// The stock view measures once before SwiftUI hands the row its real width (zero width = one
    /// endless line), and never re-reports - so every block stood one line tall, clipping the text
    /// and stopping any selection at that single visible line. Re-measure whenever the width moves.
    final class SelfSizingTextView: UITextView {
        private var lastMeasuredWidth: CGFloat = 0

        override var intrinsicContentSize: CGSize {
            let measureWidth = bounds.width > 0 ? bounds.width : UIView.layoutFittingExpandedSize.width
            let fitted = sizeThatFits(CGSize(width: measureWidth, height: .greatestFiniteMagnitude))
            return CGSize(width: UIView.noIntrinsicMetric, height: ceil(fitted.height))
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if abs(bounds.width - lastMeasuredWidth) > 0.5 {
                lastMeasuredWidth = bounds.width
                invalidateIntrinsicContentSize()
            }
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = SelfSizingTextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = false            // let it size itself; the List scrolls
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.adjustsFontForContentSizeCategory = false
        // Without this the text view reports a huge intrinsic width and the row stops wrapping.
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.required, for: .vertical)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = isArabic ? .right : .natural
        paragraph.baseWritingDirection = isArabic ? .rightToLeft : .natural
        paragraph.lineSpacing = lineSpacing

        tv.attributedText = NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraph,
        ])
        // New text = new height at the same width.
        tv.invalidateIntrinsicContentSize()
    }

    /// iOS 16+: answer SwiftUI's size proposal directly with the wrapped height for the proposed
    /// width, so the row gets the right multi-line height on the FIRST layout pass - no
    /// invalidation round-trip (the subclass above still covers iOS 15).
    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width.isFinite, width > 0 else { return nil }
        let fitted = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fitted.height))
    }
}
#endif
