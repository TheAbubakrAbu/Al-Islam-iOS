import SwiftUI
import Foundation

struct AyahRow: View, Equatable {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var quranData: QuranData
    @EnvironmentObject var quranPlayer: QuranPlayer
    
    @State private var ayahBeginnerMode = false
    
    #if os(iOS)
    @State private var showingAyahSheet = false
    @State private var showTafsirSheet = false
    
    @State private var showingNoteSheet = false
    @State private var draftNote: String = ""
    @State private var showCustomRangeSheet = false
    @State private var showQiraahComparisonSheet = false
    @State private var showEnglishComparisonSheet = false
    #endif
    #if os(watchOS)
    @State private var showWatchPlaybackDialog = false
    #endif
    
    let surah: Surah
    let ayah: Ayah
    /// When non-nil (e.g. comparison mode), use this qiraah for Arabic instead of global setting.
    var comparisonQiraahOverride: String? = nil
    var renderSettingsSignature: String = ""

    @Binding var scrollDown: Int?
    @Binding var searchText: String

    /// Fired when the ayah's actual text block (Arabic / translations) scrolls into view, not just the
    /// row's number/menu header. Drives last-read tracking and automatic khatm marking so an ayah only
    /// counts as "read" once its text is on screen.
    var onAyahTextAppear: (() -> Void)? = nil
    var onAyahTextDisappear: (() -> Void)? = nil

    @State private var showRespectAlert = false

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.surah == rhs.surah &&
        lhs.ayah == rhs.ayah &&
        lhs.comparisonQiraahOverride == rhs.comparisonQiraahOverride &&
        lhs.renderSettingsSignature == rhs.renderSettingsSignature &&
        lhs.scrollDown == rhs.scrollDown &&
        lhs.searchText == rhs.searchText
    }

    private static let arabicDisplayCache: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = AppPerformance.ayahRowCacheLimit
        return cache
    }()

    private final class MatchSources {
        let arabic: String
        let transliteration: String
        let saheeh: String
        let mustafa: String

        init(arabic: String, transliteration: String, saheeh: String, mustafa: String) {
            self.arabic = arabic
            self.transliteration = transliteration
            self.saheeh = saheeh
            self.mustafa = mustafa
        }
    }

    private static let matchSourcesCache: NSCache<NSString, MatchSources> = {
        let cache = NSCache<NSString, MatchSources>()
        cache.countLimit = AppPerformance.ayahRowCacheLimit
        return cache
    }()

    
    func containsProfanity(_ text: String) -> Bool {
        let t = text.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current).lowercased()
        return profanityFilter.contains { !$0.isEmpty && t.contains($0) }
    }
    
    private func isNoteAllowed(_ text: String) -> Bool {
        !containsProfanity(text)
    }
    
    private var bookmarkIndex: Int? {
        settings.bookmarkIndex(surah: surah.id, ayah: ayah.id)
    }
    
    private var bookmark: BookmarkedAyah? {
        settings.bookmarkedAyah(surah: surah.id, ayah: ayah.id)
    }
    
    private var isBookmarkedHere: Bool { bookmarkIndex != nil }
    private var currentNote: String {
        settings.bookmarkNoteText(surah: surah.id, ayah: ayah.id)
    }

    private var canCompareEnglishText: Bool {
        settings.isHafsDisplay
    }

    private var shouldShowKhatmCheckmark: Bool {
        settings.quranSortMode == .khatm && settings.isKhatmAyahComplete(surah: surah.id, ayah: ayah.id)
    }

    private var shouldShowManualKhatmButton: Bool {
        settings.quranSortMode == .khatm &&
        settings.isHafsDisplay &&   // khatm marking only works on Hafs an Asim; hide the dead button otherwise
        !settings.automaticKhatmCompletion &&
        comparisonQiraahOverride == nil &&
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !settings.isKhatmAyahComplete(surah: surah.id, ayah: ayah.id)
    }
    
    private func setNote(_ text: String?) {
        settings.setBookmarkNote(surah: surah.id, ayah: ayah.id, note: text)
    }

    private func removeNote() {
        settings.removeBookmarkNote(surah: surah.id, ayah: ayah.id)
    }
    
    private func spacedArabic(_ text: String) -> String {
        (settings.beginnerMode || ayahBeginnerMode) ? text.map { String($0) }.joined(separator: " ") : text
    }

    private func arabicDisplayText() -> String {
        let clean = settings.cleanArabicText
        let qiraahKey = comparisonQiraahOverride ?? (settings.displayQiraahForArabic ?? "Hafs")
        let key = "\(surah.id):\(ayah.id)|\(clean ? 1 : 0)|\((settings.beginnerMode || ayahBeginnerMode) ? 1 : 0)|\(qiraahKey)"

        if let cached = Self.arabicDisplayCache.object(forKey: key as NSString) {
            return cached as String
        }

        let baseText = ayah.displayArabicText(surahId: surah.id, clean: clean, qiraahOverride: comparisonQiraahOverride)
        let spaced = spacedArabic(baseText)
        Self.arabicDisplayCache.setObject(spaced as NSString, forKey: key as NSString)
        return spaced
    }

    static func prewarmArabicDisplay(surah: Surah, settings: Settings, limit: Int? = nil) {
        let clean = settings.cleanArabicText
        let beginner = settings.beginnerMode
        let qiraah = settings.displayQiraahForArabic
        let qiraahKey = qiraah ?? "Hafs"
        let ayahs = limit.map { Array(surah.ayahs.prefix($0)) } ?? surah.ayahs

        for ayah in ayahs where ayah.existsInQiraah(qiraah) {
            let key = "\(surah.id):\(ayah.id)|\(clean ? 1 : 0)|\(beginner ? 1 : 0)|\(qiraahKey)" as NSString
            if Self.arabicDisplayCache.object(forKey: key) != nil { continue }

            let baseText = ayah.displayArabicText(surahId: surah.id, clean: clean, qiraahOverride: qiraah)
            let displayText = beginner ? baseText.map { String($0) }.joined(separator: " ") : baseText
            Self.arabicDisplayCache.setObject(displayText as NSString, forKey: key)
        }
    }

    private func normalizedMatchSources() -> MatchSources {
        let qiraahKey = comparisonQiraahOverride ?? (settings.displayQiraahForArabic ?? "Hafs")
        let key = "\(surah.id):\(ayah.id)|\(qiraahKey)" as NSString

        if let cached = Self.matchSourcesCache.object(forKey: key) {
            return cached
        }

        let sources = MatchSources(
            arabic: settings.cleanSearch(
                ayah.textArabic(for: comparisonQiraahOverride ?? settings.displayQiraahForArabic),
                whitespace: false
            ).removingArabicDiacriticsAndSigns,
            transliteration: settings.cleanSearch(ayah.textTransliteration, whitespace: false).removingArabicDiacriticsAndSigns,
            saheeh: settings.cleanSearch(ayah.textEnglishSaheeh, whitespace: false).removingArabicDiacriticsAndSigns,
            mustafa: settings.cleanSearch(ayah.textEnglishMustafa, whitespace: false).removingArabicDiacriticsAndSigns
        )
        Self.matchSourcesCache.setObject(sources, forKey: key)
        return sources
    }

    private func ayahArabicFontName(for qiraah: String?) -> String {
        settings.quranArabicFontName(for: qiraah)
    }

    private func queryForInlineHighlight(_ query: String) -> String {
        // Drop every search operator (& | ! # ^ % $) so the residual text highlights correctly.
        query.removingAyahSearchOperators.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shouldShowTajweedColors: Bool {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }

        let usingHafs: Bool = if let override = comparisonQiraahOverride {
            override.isEmpty || override == "Hafs"
        } else {
            settings.isHafsDisplay
        }

        return settings.showTajweedColors
            && settings.showArabicText
            && usingHafs
    }

    private func arabicTajweedText(displayText renderedDisplayText: String, beginner: Bool) -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        let text = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: comparisonQiraahOverride)
        return TajweedStore.shared.attributedText(
            surah: surah.id,
            ayah: ayah.id,
            text: text,
            displayText: renderedDisplayText,
            cleanDisplayText: settings.cleanArabicText,
            beginnerSpacing: beginner
        )
    }

    /// For surahs that open with the disconnected letters (muqatta'at, e.g. الٓمٓ), shows a small aid
    /// above the ayah with the letters spaced out, their recited Arabic names, and a transliteration.
    @ViewBuilder
    private func muqattaatPronunciationBlock() -> some View {
        if settings.showArabicText, let p = Muqattaat.pronunciation(surah: surah.id, ayah: ayah.id) {
            let arabicFont = Font.custom(settings.fontArabic, size: settings.fontArabicSize * 0.62)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("ACTUAL PRONUNCIATION")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)

                    Spacer()

                    Image(systemName: settings.showMuqattaatHelper ? "chevron.down.circle" : "chevron.up.circle")
                        .font(.caption)
                        .foregroundColor(settings.accentColor.color)
                        .onTapGesture {
                            settings.hapticFeedback()
                            withAnimation { settings.showMuqattaatHelper.toggle() }
                        }
                }

                if settings.showMuqattaatHelper {
                    Text(p.individualLetters)
                        .font(arabicFont)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    muqattaatNamesView(p, font: arabicFont)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(settings.accentColor.color.opacity(0.06))
            )
        }
    }

    /// The recited letter names (e.g. أَلِف لَام مِيم), tajweed-coloured when tajweed colours are on.
    /// Uses surah/ayah 0 so the cache and rule lookups don't collide with the real ayah's coloring.
    @ViewBuilder
    private func muqattaatNamesView(_ p: Muqattaat.Pronunciation, font: Font) -> some View {
        if settings.showTajweedColors,
           let styled = TajweedStore.shared.attributedText(
               surah: 0,
               ayah: 0,
               text: p.spelledOutArabic,
               displayText: p.spelledOutArabic
           ) {
            Text(styled).font(font)
        } else {
            Text(p.spelledOutArabic)
                .font(font)
                .foregroundColor(.primary)
        }
    }

    private var tajweedAnimationKey: String {
        let categorySignature = TajweedLegendCategory.allCases
            .map { settings.isTajweedCategoryVisible($0) ? "1" : "0" }
            .joined()
        let qiraahKey = comparisonQiraahOverride ?? settings.displayQiraah
        return [
            settings.showTajweedColors ? "1" : "0",
            settings.highlightAllahNames ? "1" : "0",
            settings.cleanArabicText ? "1" : "0",
            (settings.beginnerMode || ayahBeginnerMode) ? "1" : "0",
            qiraahKey,
            categorySignature
        ].joined(separator: "|")
    }

    private var ayahHighlightBackgroundVerticalPadding: CGFloat {
        if #available(iOS 26.0, watchOS 26.0, *) {
            return -11
        }
        return -2
    }

    var body: some View {
        let isBookmarked = isBookmarkedHere
        let hafsOnly: Bool = if let override = comparisonQiraahOverride {
            override.isEmpty || override == "Hafs"
        } else {
            settings.isHafsDisplay
        }
        let hasSearch = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let normalizedQuery = hasSearch
            ? settings.cleanSearch(searchText, whitespace: true).removingArabicDiacriticsAndSigns
            : ""
        let matchSources = hasSearch ? normalizedMatchSources() : nil

        let mArabic = matchSources?.arabic.contains(normalizedQuery) ?? false
        let mTranslit = matchSources?.transliteration.contains(normalizedQuery) ?? false
        let mSaheeh = matchSources?.saheeh.contains(normalizedQuery) ?? false
        let mMustafa = matchSources?.mustafa.contains(normalizedQuery) ?? false

        let showArabic = settings.showArabicText || mArabic
        let showTranslit = hafsOnly && (settings.showTransliteration || mTranslit)
        let showEnglishSaheeh = hafsOnly && (settings.showEnglishSaheeh || mSaheeh)
        let showEnglishMustafa = hafsOnly && (settings.showEnglishMustafa || mMustafa)
        let highlightQuery = hasSearch ? queryForInlineHighlight(searchText) : ""
        let fontSizeEN = settings.englishFontSize
        
        ZStack {
            if let currentSurah = quranPlayer.currentSurahNumber, let currentAyah = quranPlayer.currentAyahNumber, currentSurah == surah.id {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        currentAyah == ayah.id
                        ? settings.accentColor.color.opacity(settings.defaultView ? 0.15 : 0.25)
                        : .clear
                    )
                    .padding(.horizontal, -12)
                    .padding(.vertical, ayahHighlightBackgroundVerticalPadding)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    ZStack(alignment: .topTrailing) {
                        Text("\(surah.id):\(ayah.id)")
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                            .padding(5)
                            .frame(width: 60, height: 28)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .conditionalGlassEffect(
                                useColor: isBookmarked ? 0.3 : nil,
                                customTint: isBookmarked ? settings.accentColor.color : nil,
                                interactive: false
                            )
                            .onTapGesture {
                                settings.hapticFeedback()
                                toggleBookmarkWithNoteGuard()
                            }

                        if isBookmarked {
                            Image(systemName: "bookmark.fill")
                                .font(.caption2)
                                .foregroundStyle(settings.accentColor.color)
                                .padding(4)
                                .offset(x: 8, y: -6)
                        }
                    }
                    
                    Spacer()
                    
                    #if os(iOS)
                    if shouldShowManualKhatmButton {
                        Button {
                            settings.hapticFeedback()
                            settings.markKhatmAyahComplete(surah: surah.id, ayah: ayah.id, immediate: true)
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .foregroundColor(settings.accentColor.color)
                                .conditionalGlassEffect()
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Mark Ayah Viewed")
                    }

                    if shouldShowKhatmCheckmark {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .foregroundColor(settings.accentColor.color)
                            .conditionalGlassEffect()
                            .frame(width: 28, height: 28)
                    }

                    if settings.isHafsDisplay {
                        Menu {
                            Text("Ayah Playback")
                                .foregroundStyle(.secondary)

                            playbackMenuBlock()
                        } label: {
                            Image(systemName: "play.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .foregroundColor(settings.accentColor.color)
                                .conditionalGlassEffect()
                                .frame(width: 28, height: 28)
                        }
                    }
                    
                    Menu {
                        Text("Ayah Actions")
                            .foregroundStyle(.secondary)

                        menuBlock(isBookmarked: isBookmarked, includePlaybackOptions: false)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25, height: 25)
                            .foregroundColor(settings.accentColor.color)
                            .conditionalGlassEffect()
                            .frame(width: 28, height: 28)
                    }
                    .sheet(isPresented: $showingAyahSheet) {
                        ShareAyahSheet(
                            surahNumber: surah.id,
                            ayahNumber: ayah.id
                        )
                        .smallMediumSheetPresentation()
                    }
                    .sheet(isPresented: $showTafsirSheet) {
                        AyahTafsirSheet(
                            surahName: surah.nameTransliteration,
                            surahNumber: surah.id,
                            ayahNumber: ayah.id
                        )
                        .smallMediumSheetPresentation()
                    }
                    .sheet(isPresented: $showQiraahComparisonSheet) {
                        AyahQiraahComparisonSheet(surahNumber: surah.id, ayahNumber: ayah.id)
                            .environmentObject(settings)
                            .environmentObject(quranData)
                            .smallMediumSheetPresentation()
                    }
                    .sheet(isPresented: $showEnglishComparisonSheet) {
                        AyahEnglishComparisonSheet(surahNumber: surah.id, ayahNumber: ayah.id)
                            .environmentObject(settings)
                            .environmentObject(quranData)
                            .smallMediumSheetPresentation()
                    }
                    .sheet(isPresented: $showingNoteSheet) {
                        NoteEditorSheet(
                            title: "Note for \(surah.nameTransliteration) \(surah.id):\(ayah.id)",
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
                    #else
                    HStack(spacing: 8) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)
                            .foregroundColor(settings.accentColor.color)

                        if settings.isHafsDisplay {
                            Image(systemName: "play.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 24, height: 24)
                                .foregroundColor(settings.accentColor.color)
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    showWatchPlaybackDialog = true
                                }
                        }
                    }
                    #endif
                }
                .padding(.bottom, settings.showArabicText ? 8 : 2)
                .padding(.trailing, 1)
                
                ayahTextBlock(
                    showArabic: showArabic,
                    showTranslit: showTranslit,
                    showEnglishSaheeh: showEnglishSaheeh,
                    showEnglishMustafa: showEnglishMustafa,
                    fontSizeEN: fontSizeEN,
                    highlightQuery: highlightQuery,
                    matchedArabic: mArabic,
                    matchedTranslit: mTranslit,
                    matchedSaheeh: mSaheeh,
                    matchedMustafa: mMustafa
                )
                .padding(.bottom, 2)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .lineLimit(nil)
        .contentShape(Rectangle())
        .onTapGesture {
            if !searchText.isEmpty {
                settings.hapticFeedback()
                withAnimation {
                    scrollDown = ayah.id
                }
            }
        }
        #if os(iOS)
        .contextMenu {
            menuBlock(isBookmarked: isBookmarked, includePlaybackOptions: true)
        }
        #endif
        .confirmationDialog("Note not saved", isPresented: $showRespectAlert, titleVisibility: .visible) {
            Button("OK") { }
        } message: {
            Text("Please keep notes Islamic and respectful.")
        }
        .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
            }
            Button("Cancel") {}
        } message: {
            Text(Settings.bookmarkNoteRemovalDialogMessage)
        }
        #if os(watchOS)
        .confirmationDialog("Play Ayah", isPresented: $showWatchPlaybackDialog, titleVisibility: .visible) {
            Button("Play Ayah") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
            }

            Button("Play From Ayah") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
            }

            Button("Repeat Ayah 2×") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 2)
            }

            Button("Repeat Ayah 3×") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 3)
            }

            Button("Repeat Ayah 5×") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 5)
            }

            Button("Repeat Ayah 10×") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 10)
            }

            Button("Repeat Ayah 15×") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 15)
            }

            Button("Repeat Ayah 20×") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 20)
            }
        } message: {
            Text("Choose how you want to start playback for this ayah.")
        }
        #else
        .sheet(isPresented: $showCustomRangeSheet) {
            PlayCustomRangeSheet(
                surah: surah,
                initialStartAyah: ayah.id,
                initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                    startAyah: ayah.id,
                    surah: surah,
                    displayQiraah: settings.displayQiraahForArabic
                ),
                onPlay: { start, end, repAyah, repSec in
                    quranPlayer.playCustomRange(
                        surahNumber: surah.id,
                        surahName: surah.nameTransliteration,
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
        #endif
    }
    
    @ViewBuilder
    private func ayahTextBlock(
        showArabic: Bool,
        showTranslit: Bool,
        showEnglishSaheeh: Bool,
        showEnglishMustafa: Bool,
        fontSizeEN: CGFloat,
        highlightQuery: String,
        matchedArabic: Bool = false,
        matchedTranslit: Bool = false,
        matchedSaheeh: Bool = false,
        matchedMustafa: Bool = false
    ) -> some View {
        let groupHasEnglishOrTranslit = showTranslit || showEnglishSaheeh || showEnglishMustafa
        let prefixOnTranslit  = groupHasEnglishOrTranslit && showTranslit
        let prefixOnSaheeh    = groupHasEnglishOrTranslit && !showTranslit && showEnglishSaheeh
        let prefixOnMustafa   = groupHasEnglishOrTranslit && !showTranslit && !showEnglishSaheeh && showEnglishMustafa

        VStack(alignment: .leading, spacing: 14) {
            if !currentNote.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "note.text")
                        .foregroundColor(settings.accentColor.color)
                    
                    Text(currentNote)
                        .font(.callout)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                }
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(settings.accentColor.color.opacity(0.25), lineWidth: 1)
                )
                .conditionalGlassEffect(rectangle: true)
                .frame(maxWidth: .infinity, alignment: .center)
                #if os(iOS)
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation {
                        draftNote = currentNote
                        showingNoteSheet = true
                    }
                }
                #endif
                .padding(.top, 4)
            }

            muqattaatPronunciationBlock()

            if showArabic {
                let beginner = settings.beginnerMode || ayahBeginnerMode
                let arabicSource = arabicDisplayText()
                let arabicFont: Font = settings.removeArabicDots
                    ? .system(size: settings.fontArabicSize)
                    : .custom(
                        ayahArabicFontName(for: comparisonQiraahOverride ?? settings.displayQiraahForArabic),
                        size: settings.fontArabicSize
                    )
                let suffixFont: Font = .custom(Settings.hafsUthmaniFontName, size: settings.fontArabicSize)

                HighlightedSnippet(
                    source: arabicSource,
                    term: highlightQuery,
                    font: arabicFont,
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: arabicTajweedText(displayText: arabicSource, beginner: beginner),
                    beginnerMode: beginner,
                    trailingSuffix: " \(ayah.idArabic)",
                    trailingSuffixFont: suffixFont,
                    trailingSuffixColor: settings.accentColor.color,
                    highlightAllahNames: settings.highlightAllahNames,
                    guaranteeMatch: matchedArabic
                )
                .id(tajweedAnimationKey)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(nil)
            }

            if showTranslit {
                let txt = prefixOnTranslit ? "\(ayah.id). \(ayah.textTransliteration)" : ayah.textTransliteration
                HighlightedSnippet(
                    source: txt,
                    term: highlightQuery,
                    font: .system(size: fontSizeEN),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    highlightAllahNames: settings.highlightAllahNames,
                    guaranteeMatch: matchedTranslit
                )
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)
            }

            if showEnglishSaheeh {
                let txt = prefixOnSaheeh ? "\(ayah.id). \(ayah.textEnglishSaheeh)" : ayah.textEnglishSaheeh
                VStack(alignment: .leading, spacing: 4) {
                    HighlightedSnippet(
                        source: txt,
                        term: highlightQuery,
                        font: .system(size: fontSizeEN),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        highlightAllahNames: settings.highlightAllahNames,
                        guaranteeMatch: matchedSaheeh
                    )
                    Text("— Saheeh International")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)
            }

            if showEnglishMustafa {
                let txt = prefixOnMustafa ? "\(ayah.id). \(ayah.textEnglishMustafa)" : ayah.textEnglishMustafa
                VStack(alignment: .leading, spacing: 4) {
                    HighlightedSnippet(
                        source: txt,
                        term: highlightQuery,
                        font: .system(size: fontSizeEN),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        highlightAllahNames: settings.highlightAllahNames,
                        guaranteeMatch: matchedMustafa
                    )
                    Text("— Clear Quran (Mustafa Khattab)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)
            }
        }
        .lineLimit(nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.bottom, 2)
        #if os(iOS)
        .textSelection(.enabled)
        #endif
        .onAppear { onAyahTextAppear?() }
        .onDisappear { onAyahTextDisappear?() }
    }

    @State private var confirmRemoveNote = false

    private func toggleBookmarkWithNoteGuard() {
        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah.id, ayah: ayah.id) {
            confirmRemoveNote = true
        }
    }

    #if os(iOS)
    @ViewBuilder
    private func playbackMenuBlock() -> some View {
        let repeatOptions = [2, 3, 5, 10, 15, 20]

        Group {
            Menu {
                Text("Repeat Count")
                    .foregroundStyle(.secondary)

                ForEach(repeatOptions, id: \.self) { count in
                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: count)
                    } label: {
                        Label("Repeat \(count)×", systemImage: "\(count).circle")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    showCustomRangeSheet = true
                } label: {
                    Label("Play Custom Range", systemImage: "slider.horizontal.3")
                }
            } label: {
                Label("Repeat Ayah", systemImage: "repeat")
            }
            
            Button {
                settings.hapticFeedback()
                showCustomRangeSheet = true
            } label: {
                Label("Play Custom Range", systemImage: "slider.horizontal.3")
            }

            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
            } label: {
                Label("Play From Ayah", systemImage: "play.circle.fill")
            }
            
            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
            } label: {
                Label("Play This Ayah", systemImage: "play.circle")
            }
        }
    }

    @ViewBuilder
    private func contextPlaybackMenuBlock() -> some View {
        let repeatOptions = [2, 3, 5, 10, 15, 20]

        Menu {
            ForEach(repeatOptions, id: \.self) { count in
                Button {
                    settings.hapticFeedback()
                    quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: count)
                } label: {
                    Label("Repeat \(count)×", systemImage: "\(count).circle")
                }
            }

            Button {
                settings.hapticFeedback()
                showCustomRangeSheet = true
            } label: {
                Label("Play Custom Range", systemImage: "slider.horizontal.3")
            }
        } label: {
            Label("Repeat Ayah", systemImage: "repeat")
        }

        Menu {
            Button {
                settings.hapticFeedback()
                showCustomRangeSheet = true
            } label: {
                Label("Play Custom Range", systemImage: "slider.horizontal.3")
            }

            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
            } label: {
                Label("Play From Ayah", systemImage: "play.circle.fill")
            }
            
            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
            } label: {
                Label("Play This Ayah", systemImage: "play.circle")
            }
        } label: {
            Label("Play Ayah", systemImage: "play.circle")
        }
    }

    @ViewBuilder
    private func comparisonMenuBlock(canShowQiraah: Bool, canShowTranslation: Bool) -> some View {
        if canShowQiraah && canShowTranslation {
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
        } else if canShowQiraah {
            Button {
                settings.hapticFeedback()
                showQiraahComparisonSheet = true
            } label: {
                Label("Qiraah Comparison", systemImage: "character.book.closed.fill.ar")
            }
        } else if canShowTranslation {
            Button {
                settings.hapticFeedback()
                showEnglishComparisonSheet = true
            } label: {
                Label("Translation Comparison", systemImage: "character.book.closed")
            }
        }
    }
    #endif

    @ViewBuilder
    private func menuBlock(isBookmarked: Bool, includePlaybackOptions: Bool) -> some View {
        #if os(iOS)
        let canShowTafsir: Bool = {
            if let override = comparisonQiraahOverride {
                return override.isEmpty || override == "Hafs"
            }
            return settings.isHafsDisplay
        }()

        VStack(alignment: .leading) {
            Button(role: isBookmarked ? .destructive : nil) {
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
                    settings.ensureBookmarkExists(surah: surah.id, ayah: ayah.id)
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

            if canShowTafsir {
                Button {
                    settings.hapticFeedback()
                    showTafsirSheet = true
                } label: {
                    Label("See Tafsir", systemImage: "text.book.closed")
                }
            }

            comparisonMenuBlock(
                canShowQiraah: settings.showQiraahDetails,
                canShowTranslation: canCompareEnglishText
            )
            
            if settings.showArabicText && !settings.beginnerMode {
                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        ayahBeginnerMode.toggle()
                    }
                } label: {
                    Label("Beginner Mode",
                          systemImage: ayahBeginnerMode
                          ? "textformat.size.larger.ar"
                          : "textformat.size.ar")
                }
            }
            
            Divider()
            
            if includePlaybackOptions && settings.isHafsDisplay {
                contextPlaybackMenuBlock()
                Divider()
            }

            Button {
                settings.hapticFeedback()
                ShareAyahSheet.copyAyahToPasteboard(surahNumber: surah.id, ayahNumber: ayah.id, settings: settings, quranData: quranData)
            } label: {
                Label("Copy Ayah", systemImage: "doc.on.doc")
            }

            Button {
                settings.hapticFeedback()
                showingAyahSheet = true
            } label: {
                Label("Share Ayah", systemImage: "square.and.arrow.up")
            }
        }
        .lineLimit(nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.bottom, 2)
        #endif
    }
}

private struct AyahRowPreviewContent: View {
    @State private var scrollDown: Int? = nil
    @State private var searchText = ""

    var body: some View {
        List {
            AyahRow(
                surah: AlIslamPreviewData.surah,
                ayah: AlIslamPreviewData.ayah,
                scrollDown: $scrollDown,
                searchText: $searchText
            )
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        QuranView()
        //AyahRowPreviewContent()
    }
}
