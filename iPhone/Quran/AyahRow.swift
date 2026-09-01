import SwiftUI
import Foundation

/// Whether any per-ayah sheet (tafsir, share, note, comparisons, page-mode actions...) is currently
/// presented from the reader. The readers' "follow the recitation" scrolls/page-turns consult this and
/// hold still while a sheet is up: auto-scrolling the List (or flipping the mushaf page) tears down the
/// row/page that is PRESENTING the sheet, which dismissed the sheet mid-read on every ayah advance - and
/// reclaiming a cell that is also a live presentation anchor is exactly the kind of teardown that can
/// bring the whole presentation stack down. Following resumes on the first ayah advance after the sheet
/// closes. Main-thread only (all writers are SwiftUI view callbacks).
final class AyahSheetPresence: ObservableObject {
    static let shared = AyahSheetPresence()
    private init() {}

    @Published private(set) var openCount = 0

    var anySheetOpen: Bool { openCount > 0 }

    func sheetOpened() { openCount += 1 }
    /// Clamped: a presenter torn down in an unexpected order must never push the count negative.
    func sheetClosed() { openCount = max(0, openCount - 1) }
}

struct AyahRow: View, Equatable {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    /// Only the highlighter's wash reads this: the same hue needs a heavier alpha on the dark page to
    /// register at all, so the tint is resolved per scheme rather than baked into the palette.
    @Environment(\.colorScheme) private var colorScheme
    /// NOT @ObservedObject: the player is used only inside action closures plus the one
    /// `isPlayingThis` input below. Observing it re-ran EVERY visible row's body once per ayah while
    /// a surah played (`currentAyahNumber` publishes each advance), bypassing `.equatable()` -
    /// observation invalidates independently of input comparison. The parent passes `isPlayingThis`
    /// instead, so an ayah advance re-renders exactly the two rows whose tint changes.
    private var quranPlayer: QuranPlayer { .shared }

    /// The per-ayah "Beginner Mode" toggle, held in a shared session store rather than in this row's own
    /// `@State`. A row in a lazy list is torn down when it scrolls away and rebuilt from its inputs when it
    /// comes back, so private state could not survive - which is why the toggle "sometimes didn't work".
    @ObservedObject private var beginnerOverrides = AyahBeginnerOverrides.shared
    private var ayahBeginnerMode: Bool { beginnerOverrides.contains(surah: surah.id, ayah: ayah.id) }

    /// Lines a match FORCED visible (a search hit / arrival showing the transliteration or a translation
    /// even though its toggle is off), latched for as long as this row stays mounted: clearing the arrival
    /// used to collapse those lines, shrink the row, and nudge the whole list ("it'll scroll a little up
    /// or down" - user report). Latched lines keep the row's height stable through the clear; the row is
    /// recycled once it scrolls away, so the latch resets naturally. Order: translit, saheeh, mustafa, arabic.
    @State private var latchedForcedLines: [Bool] = [false, false, false, false]

    #if os(iOS)
    @State private var showingAyahSheet = false
    @State private var showTafsirSheet = false
    /// The word of this ayah whose meaning card is up (word-by-word mode). Nil when none is.
    @State private var tappedWord: TappedWord?
    /// The word whose riwayah card is up (non-Hafs word tap). Nil when none is.
    @State private var tappedRiwayahWord: RiwayahTappedWord?

    @State private var showingNoteSheet = false
    @State private var draftNote: String = ""
    @State private var showCustomRangeSheet = false
    @State private var showQiraahComparisonSheet = false
    @State private var showEnglishComparisonSheet = false
    @State private var showSelectTextSheet = false
    /// The long-press ayah actions sheet - the same `AyahActionsSheet` page mode presents.
    @State private var showAyahActionsSheet = false
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
    /// The search term that travelled with the navigation that OPENED this surah - highlights this row's
    /// matched snippet in accent (exactly like an active search) without any filtering, until the reader
    /// touches the row and the parent clears it. Empty for every row but the arrival target.
    var arrivalTerm: String = ""

    /// The shared attention-highlight lands on this ayah - draw a persistent (grey) tint distinct from the
    /// player's accent tint. Set by opening to an ayah, switching reading modes, or tapping the ayah.
    var isHighlighted: Bool = false
    /// Tapping the row (when not searching) toggles the shared highlight.
    var onToggleHighlight: (() -> Void)? = nil

    /// Multi-select mode: the reader is picking several ayahs for a bulk action (share/copy/bookmark/note/
    /// beginner). Taps toggle membership instead of highlighting, and a checkmark circle leads the row.
    var isSelecting: Bool = false
    var isSelected: Bool = false
    /// Bulk "Beginner" action: render this ayah's Arabic letter-by-letter even though the global beginner
    /// mode (and this row's own context-menu toggle) are off.
    var forceBeginner: Bool = false
    var onToggleSelection: (() -> Void)? = nil

    /// Fired when the ayah's actual text block (Arabic / translations) scrolls into view, not just the
    /// row's number/menu header. Drives last-read tracking and automatic khatm marking so an ayah only
    /// counts as "read" once its text is on screen.
    var onAyahTextAppear: (() -> Void)? = nil
    var onAyahTextDisappear: (() -> Void)? = nil

    /// True when the player is currently on this exact ayah - drives the accent playing tint. Passed
    /// in (and compared in `==`) rather than read from an observed player; see the note on `quranPlayer`.
    var isPlayingThis: Bool = false

    @State private var showRespectAlert = false

    /// Whether any of this ayah's action sheets/dialogs is open - drives the "keep it lit until the sheet is
    /// gone" tint. watchOS has none of these sheets, so it's always false there.
    private var anyAyahSheetOpen: Bool {
        #if os(iOS)
        showingAyahSheet || showTafsirSheet || showingNoteSheet || showCustomRangeSheet
            || showQiraahComparisonSheet || showEnglishComparisonSheet || showSelectTextSheet
            || showAyahActionsSheet || tappedWord != nil || tappedRiwayahWord != nil
        #else
        false
        #endif
    }

    #if os(iOS)
    /// Routes the actions sheet's "open another sheet" requests onto this row's own sheet states -
    /// the list-mode twin of `MushafPageContent.requestSecondarySheet`. The actions sheet closes
    /// first; UIKit can't present a second sheet while the first is still animating away.
    private func requestRowSecondarySheet(_ kind: AyahSecondarySheet) {
        showAyahActionsSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            switch kind {
            case .tafsir: showTafsirSheet = true
            case .qiraah: showQiraahComparisonSheet = true
            case .translations: showEnglishComparisonSheet = true
            case .customRange: showCustomRangeSheet = true
            case .note:
                draftNote = currentNote
                showingNoteSheet = true
            case .share: showingAyahSheet = true
            case .selectText: showSelectTextSheet = true
            }
        }
    }
    #endif

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.surah == rhs.surah &&
        lhs.ayah == rhs.ayah &&
        lhs.comparisonQiraahOverride == rhs.comparisonQiraahOverride &&
        lhs.renderSettingsSignature == rhs.renderSettingsSignature &&
        lhs.scrollDown == rhs.scrollDown &&
        lhs.isHighlighted == rhs.isHighlighted &&
        lhs.isPlayingThis == rhs.isPlayingThis &&
        lhs.arrivalTerm == rhs.arrivalTerm &&
        lhs.isSelecting == rhs.isSelecting &&
        lhs.isSelected == rhs.isSelected &&
        lhs.forceBeginner == rhs.forceBeginner &&
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
        textContainsProfanity(text)
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

    /// This ayah's highlight, read straight from the bookmark record - a highlight has no storage of its
    /// own, so there is nothing here to keep in sync with the bookmark.
    private var ayahHighlight: AyahHighlightColor? {
        bookmark?.highlight
    }

    /// What the bookmark badge paints with: the highlight's color when there is one, the accent otherwise.
    private var bookmarkTint: Color {
        ayahHighlight?.color ?? settings.accentColor.color
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
        (settings.beginnerMode || ayahBeginnerMode || forceBeginner) ? text.beginnerSpaced : text
    }

    private func arabicDisplayText() -> String {
        let clean = settings.cleanArabicText
        let qiraahKey = comparisonQiraahOverride ?? (settings.displayQiraahForArabic ?? "Hafs")
        // The dots flag must be in the key: it changes the text `textCleanArabic` returns for the
        // same `clean` bit, and nothing purges this cache when the toggle flips.
        let key = "\(surah.id):\(ayah.id)|\(clean ? 1 : 0)\(settings.removeArabicDots ? 1 : 0)|\((settings.beginnerMode || ayahBeginnerMode || forceBeginner) ? 1 : 0)|\(qiraahKey)"

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

        for ayah in ayahs where ayah.existsInQiraah(qiraah, surahID: surah.id) {
            let key = "\(surah.id):\(ayah.id)|\(clean ? 1 : 0)\(settings.removeArabicDots ? 1 : 0)|\(beginner ? 1 : 0)|\(qiraahKey)" as NSString
            if Self.arabicDisplayCache.object(forKey: key) != nil { continue }

            let baseText = ayah.displayArabicText(surahId: surah.id, clean: clean, qiraahOverride: qiraah)
            let displayText = beginner ? baseText.beginnerSpaced : baseText
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
                ayah.textArabic(for: comparisonQiraahOverride ?? settings.displayQiraahForArabic, surahID: surah.id),
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

    #if os(iOS)
    /// The per-word glosses to render this ayah with, or nil when word-by-word is off / can't apply here.
    ///
    /// Every condition is a case where a word index would not mean what the pack says it means:
    /// another riwayah words the ayah differently, beginner mode splits every letter into its own token,
    /// a comparison column isn't the reader's own text, and an active search needs the tap to belong to
    /// the search highlight rather than to a word. Multi-select owns the tap outright.
    private func wordByWordGlosses(displayText: String, beginner: Bool, highlightQuery: String) -> [String]? {
        guard settings.wordByWordMeanings,
              settings.showArabicText,
              settings.isHafsDisplay,
              !beginner,
              !isSelecting,
              comparisonQiraahOverride == nil,
              highlightQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        let raw = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: nil)
        return WordByWordStore.shared.glosses(
            surah: surah.id,
            ayah: ayah.id,
            rawText: raw,
            displayText: displayText
        )
    }

    /// The per-word transliteration for the inline study layout, aligned with `wordByWordGlosses`.
    ///
    /// Gated on the study layout's OWN transliteration switch, not on the ayah's transliteration line:
    /// the two answer different questions (how this word is said, versus how the whole ayah is said),
    /// so a reader can want either without the other. Empty (not nil) when it can't apply, so the
    /// layout just omits the line.
    private func wordByWordTransliterations(displayText: String) -> [String] {
        guard settings.wordByWordInlineTransliteration else { return [] }
        let raw = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: nil)
        return WordByWordStore.shared.transliterations(
            surah: surah.id,
            ayah: ayah.id,
            rawText: raw,
            displayText: displayText
        ) ?? []
    }
    #endif

    /// The reader's normal Arabic - one `Text`, search-highlighted. Extracted so the word-by-word
    /// renderer can sit beside it as an alternative without duplicating the styling arguments.
    private func arabicSnippet(source: String, font: Font, preStyled: AttributedString?,
                               beginner: Bool, suffixFont: Font,
                               highlightQuery: String, matchedArabic: Bool,
                               extraRanges: [NSRange] = []) -> some View {
        HighlightedSnippet(
            source: source,
            term: highlightQuery,
            font: font,
            accent: settings.accentColor.color,
            fg: .primary,
            preStyledSource: preStyled,
            beginnerMode: beginner,
            trailingSuffix: " \(ayah.idArabic)",
            trailingSuffixFont: suffixFont,
            trailingSuffixColor: ayahNumberColor,
            highlightAllahNames: settings.highlightAllahNames,
            guaranteeMatch: matchedArabic,
            extraHighlightRanges: extraRanges
        )
        .arabicFontDesign(custom: true)
        .id(tajweedAnimationKey)
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .lineLimit(nil)
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

    /// The color of this row's trailing ayah number. The prints ring an ayah's number medallion
    /// in magenta when its NUMBERING differs from Hafs (a merge/split point of the riwayah's own
    /// counting) - mirror that here. A fact of the riwayah's text, not a tajweed color, so it
    /// shows whenever a non-Hafs riwayah with a bundled pack is displayed (same philosophy as
    /// the always-on word diff tint), independent of the tajweed toggle.
    private var ayahNumberColor: Color {
        #if os(iOS)
        let raw = comparisonQiraahOverride ?? (settings.displayQiraahForArabic ?? "")
        let tag = Settings.Riwayah.canonicalTag(raw == "Hafs" ? "" : raw)
        if !tag.isEmpty,
           QiraahTajweedStore.shared.isKhilafNumbered(tag: tag, surah: surah.id, ayah: ayah.id) {
            return Color(QiraahTajweedStore.khilafNumberColor)
        }
        #endif
        return settings.accentColor.color
    }

    #if os(iOS)
    #if DEBUG
    /// One-shot launch args for headless verification - taps aren't scriptable in the simulator:
    /// "-openWordCard N" opens the riwayah word card for word N of the first tappable non-Hafs
    /// row on screen; "-openQiraahComparison" opens the first such row's comparison sheet.
    private static var debugWordCardIndex: Int? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-openWordCard"), i + 1 < args.count else { return nil }
        return Int(args[i + 1])
    }()
    private static var debugOpenComparison = ProcessInfo.processInfo.arguments.contains("-openQiraahComparison")
    /// The "s:a" the session was launched at (the "-lastRead" arg) - matched directly because the
    /// live last-read tracking overwrites the defaults as rows scroll past.
    private static let debugTargetAyah: (surah: Int, ayah: Int)? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-lastRead"), i + 1 < args.count else { return nil }
        let parts = args[i + 1].split(separator: ":")
        guard parts.count == 2, let s = Int(parts[0]), let a = Int(parts[1]) else { return nil }
        return (s, a)
    }()
    #endif

    /// The row's non-Hafs riwayah tag when its WORDS should be tappable: word-by-word mode on
    /// (the master switch for tappable words), a non-Hafs riwayah with a bundled pack displayed,
    /// and none of the states where a word index would lie (beginner letter-spacing, multi-select,
    /// an active search that owns the tap). The card shows the riwayah's rules and the aligned
    /// Hafs counterpart instead of a gloss - there is no gloss pack for non-Hafs texts.
    private func riwayahWordTapTag(beginner: Bool, highlightQuery: String) -> String? {
        guard settings.wordByWordMeanings,
              settings.showArabicText,
              !beginner,
              !isSelecting,
              highlightQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let raw = comparisonQiraahOverride ?? (settings.displayQiraahForArabic ?? "")
        let tag = Settings.Riwayah.canonicalTag(raw == "Hafs" ? "" : raw)
        guard !tag.isEmpty, QiraahTajweedStore.shared.isAvailable(tag: tag) else { return nil }
        return tag
    }
    #endif

    /// The current row's non-Hafs riwayah tag when its print-derived tajweed colors should paint:
    /// tajweed toggle on, not searching, and the riwayah's tajweed pack is bundled. The pack's
    /// magenta khilaf words ARE the printed "differs from Hafs" highlighting, so while this is
    /// non-nil the computed diff tint stands down (even on ayahs the print leaves uncolored).
    private var riwayahTajweedTag: String? {
        #if os(iOS)
        guard settings.showTajweedColors, settings.showArabicText else { return nil }
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let raw = comparisonQiraahOverride ?? (settings.displayQiraahForArabic ?? "")
        let tag = Settings.Riwayah.canonicalTag(raw == "Hafs" ? "" : raw)
        guard !tag.isEmpty, QiraahTajweedStore.shared.isAvailable(tag: tag) else { return nil }
        return tag
        #else
        return nil
        #endif
    }

    /// Reading a non-Hafs riwayah with tajweed colors on: the display text colored word-by-word
    /// the way THAT riwayah's printed mushaf colors it (khilaf words, idgham, imalah, ...).
    /// Word indices come from the same space/NBSP tokenization the extraction used; beginner
    /// spacing keeps its colors - the store re-tokenizes by the 2+ space original word gaps.
    private func arabicRiwayahTajweedText(displayText: String, beginner: Bool) -> AttributedString? {
        #if os(iOS)
        guard let tag = riwayahTajweedTag else { return nil }
        // With "Hide Tashkeel and Signs" on, the store colors the FULL text and projects the runs
        // onto the stripped rendering - so the print's coloring survives the strip, like Hafs's does.
        let fullText: String? = {
            guard settings.cleanArabicText else { return nil }
            let full = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: comparisonQiraahOverride)
            return beginner ? full.beginnerSpaced : full
        }()
        return QiraahTajweedStore.shared.attributedText(
            tag: tag, surah: surah.id, ayah: ayah.id, displayText: displayText,
            beginnerSpacing: beginner,
            hiddenRules: settings.riwayahTajweedHiddenRuleSet,
            fullText: fullText
        )
        #else
        return nil
        #endif
    }

    /// Reading a non-Hafs riwayah with "Highlight Differences from Hafs" on: the display text with
    /// every word that differs from Hafs an Asim tinted (`QiraahComparison`). This row's id is the
    /// riwayah's OWN ayah number, so the Hafs reference is looked up through the alignment - a
    /// merged ayah diffs against BOTH Hafs neighbors it spans. Nil on Hafs, while searching (the
    /// search paint wins), and in beginner spacing (letter spacing breaks word alignment). Takes
    /// the tajweed slot, which is free here: tajweed colors are Hafs-only.
    private func arabicDiffText(displayText: String, beginner: Bool) -> AttributedString? {
        // Always on: seeing which words differ from Hafs IS the point of reading another riwayah,
        // so it is no longer a setting. Beginner mode still opts out - its spaced letterforms are
        // for learning the script, and tinting words on top of that is noise.
        guard !beginner else { return nil }
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        // The print's own coloring supersedes the computed diff whenever it is active.
        guard riwayahTajweedTag == nil else { return nil }
        let raw = comparisonQiraahOverride ?? (settings.displayQiraahForArabic ?? "")
        let tag = Settings.Riwayah.canonicalTag(raw == "Hafs" ? "" : raw)
        guard !tag.isEmpty else { return nil }

        let quranData = QuranData.shared
        let span = QiraahComparison.alignment(surahID: surah.id, tag: tag, quranData: quranData)?
            .hafsRangeForRiwayah[ayah.id] ?? (ayah.id...ayah.id)
        var referenceParts: [String] = []
        for n in span {
            if let hafsAyah = quranData.ayah(surah: surah.id, ayah: n) {
                referenceParts.append(hafsAyah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: ""))
            }
        }
        guard !referenceParts.isEmpty else { return nil }
        return QiraahComparison.diffAttributed(
            text: displayText,
            reference: referenceParts.joined(separator: " "),
            baseColor: .primary,
            diffColor: settings.accentColor.color
        )
    }

    /// For surahs that open with the disconnected letters (muqatta'at, e.g. الٓمٓ), shows a small aid
    /// above the ayah with the letters spaced out, their recited Arabic names, and a transliteration.
    @ViewBuilder
    private func muqattaatPronunciationBlock() -> some View {
        if settings.showArabicText, let p = Muqattaat.pronunciation(surah: surah.id, ayah: ayah.id) {
            // "Basic" renders these names with the system face, which should stay rounded like the rest of the UI.
            let usesCustomFace = settings.quranUsesCustomArabicFace
            let arabicFont: Font = usesCustomFace
                ? Font.arabic(settings.fontArabic, size: settings.fontArabicSize * 0.62)
                : .system(size: settings.fontArabicSize * 0.62, design: .rounded)
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
                        .arabicFontDesign(custom: usesCustomFace)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    muqattaatNamesView(p, font: arabicFont)
                        .arabicFontDesign(custom: usesCustomFace)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Divider()
                        .padding(.vertical, 2)

                    // The letter count, plus the elongation - but only the elongation these particular letters
                    // actually carry. Ṭā-Hā has no maddah sign on either name, so it is 2 counts, not 6.
                    HStack(spacing: 8) {
                        Text("\(p.letters.count) \(p.letters.count == 1 ? "letter" : "letters")")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)

                        Spacer()

                        if let maddDescription = p.maddDescription {
                            Text(maddDescription)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
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
        let categorySignature = settings.tajweedCategoryVisibilitySignature
        let qiraahKey = comparisonQiraahOverride ?? settings.displayQiraah
        return [
            settings.showTajweedColors ? "1" : "0",
            settings.highlightAllahNames ? "1" : "0",
            settings.cleanArabicText ? "1" : "0",
            (settings.beginnerMode || ayahBeginnerMode || forceBeginner) ? "1" : "0",
            qiraahKey,
            categorySignature,
            settings.riwayahTajweedHiddenRules
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
        // This exact ayah is the last-listened single-ayah playback position - a speaker badge on
        // the pill, the surah rows' listening grammar. The bookmark badge wins when both apply.
        let isLastListened = settings.lastListenedAyah.map {
            $0.surahNumber == surah.id && $0.ayahNumber == ayah.id
        } ?? false
        let hafsOnly: Bool = if let override = comparisonQiraahOverride {
            override.isEmpty || override == "Hafs"
        } else {
            settings.isHafsDisplay
        }
        // The active in-list search term, or - when this row is a search hit the reader just navigated
        // to - the term that travelled with the navigation. Either colors the matched snippet in accent.
        let activeTerm: String = {
            let live = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !live.isEmpty { return searchText }
            return arrivalTerm
        }()
        let hasSearch = !activeTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let normalizedQuery = hasSearch
            ? settings.cleanSearch(activeTerm, whitespace: true).removingArabicDiacriticsAndSigns
            : ""
        let matchSources = hasSearch ? normalizedMatchSources() : nil

        let mTranslit = matchSources?.transliteration.contains(normalizedQuery) ?? false
        let mSaheeh = matchSources?.saheeh.contains(normalizedQuery) ?? false
        let mMustafa = matchSources?.mustafa.contains(normalizedQuery) ?? false
        // Guarantee a highlight: the LIST FILTER that put this row on screen normalizes differently than these
        // per-field checks (it also strips silent letters), so a row can match the filter while none of the
        // fields' exact-contains checks fire. When that happens, force the always-shown Arabic field to
        // guarantee at least one highlighted span (HighlightedSnippet's closest-match fallback) - a searched
        // ayah on screen must never render with nothing highlighted.
        let rawArabicMatch = matchSources?.arabic.contains(normalizedQuery) ?? false
        let anyFieldMatched = rawArabicMatch || mTranslit || mSaheeh || mMustafa
        let mArabic = rawArabicMatch || (hasSearch && !anyFieldMatched)

        // Cross-language word highlight, the search rows' behavior brought into the reader itself: an
        // Arabic term (typed in the in-surah search, or riding a search-arrival) also lights its aligned
        // ENGLISH words, and an English term lights the Arabic tokens whose gloss carries it.
        #if os(iOS)
        let cross = hasSearch ? crossLanguageSpans(query: activeTerm)
                              : (arabic: [NSRange](), saheeh: [NSRange](), mustafa: [NSRange]())
        #else
        let cross: (arabic: [NSRange], saheeh: [NSRange], mustafa: [NSRange]) = ([], [], [])
        #endif

        // Cross spans FORCE the opposite-language line visible (the search rows' rule): an Arabic hit
        // whose aligned English words were found must show them even when the translation toggle is off.
        // Saheeh takes precedence when both translations would be forced. Forced lines are LATCHED (see
        // `latchedForcedLines`) so clearing the arrival doesn't shrink the row and jiggle the list.
        let forcedTranslit = hafsOnly && mTranslit
        let forcedSaheeh = hafsOnly && (mSaheeh || !cross.saheeh.isEmpty)
        let forcedMustafa = hafsOnly && (mMustafa || (!cross.mustafa.isEmpty && !forcedSaheeh))
        let forcedArabic = !settings.showArabicText && (mArabic || !cross.arabic.isEmpty)
        let forcedNow = [forcedTranslit, forcedSaheeh, forcedMustafa, forcedArabic]

        let showArabic = settings.showArabicText || forcedArabic || latchedForcedLines[3]
        let showTranslit = hafsOnly && (settings.showTransliteration || forcedTranslit || latchedForcedLines[0])
        let showEnglishSaheeh = hafsOnly && (settings.showEnglishSaheeh || forcedSaheeh || latchedForcedLines[1])
        let showEnglishMustafa = hafsOnly
            && (settings.showEnglishMustafa || forcedMustafa || latchedForcedLines[2])
        let highlightQuery = hasSearch ? queryForInlineHighlight(activeTerm) : ""
        let fontSizeEN = settings.englishFontSize

        // `isPlayingThis` is the input property - see its declaration.
        // The persistent attention tint (grey), separate from the accent playing tint: shown when this ayah is
        // the shared highlight OR while one of its action sheets is open (keep the selection lit until the
        // sheet is gone). The accent playing tint always wins when this ayah is being recited. In multi-select
        // mode, a SELECTED row gets the accent tint instead.
        let showSelectionTint = isSelecting && isSelected
        let showAttentionTint = !isPlayingThis && !isSelecting && (isHighlighted || anyAyahSheetOpen)

        // The highlighter's wash. It is the quietest of the four tints on purpose: the recitation tint,
        // the selection tint, and the attention tint are all momentary - what the app is doing right now -
        // while the highlight is a standing mark the user left, and it must not compete with them for the
        // same row. So a highlighted ayah shows its color only when nothing momentary is on it, and the
        // color comes back the moment the reciter moves on.
        let highlightWash = ayahHighlight

        ZStack {
            if isPlayingThis || showAttentionTint || showSelectionTint {
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        isPlayingThis || showSelectionTint
                        ? settings.accentColor.color.opacity(settings.defaultView ? 0.15 : 0.25)
                        : Color.secondary.opacity(0.18)
                    )
                    .padding(.horizontal, -12)
                    .padding(.vertical, ayahHighlightBackgroundVerticalPadding)
            } else if let highlightWash {
                RoundedRectangle(cornerRadius: 24)
                    .fill(highlightWash.tint(colorScheme))
                    .padding(.horizontal, -12)
                    .padding(.vertical, ayahHighlightBackgroundVerticalPadding)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    Text("\(surah.id):\(ayah.id)")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundColor(settings.accentColor.color)
                        .padding(5)
                        .frame(width: 60, height: 28)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .conditionalGlassEffect(
                            useColor: isBookmarked ? 0.3 : nil,
                            customTint: isBookmarked ? bookmarkTint : nil,
                            interactive: false
                        )
                        .onTapGesture {
                            settings.hapticFeedback()
                            toggleBookmarkWithNoteGuard()
                        }
                        // The bookmark keeps the RIGHT corner - that is where saving an ayah has always
                        // shown up. The listening badge moves to the LEFT (user rule), so the two no longer
                        // compete for one corner: an ayah that is both bookmarked and the last one listened
                        // to now shows both, instead of the bookmark silently hiding the speaker.
                        .overlay(alignment: .topTrailing) {
                            if isBookmarked {
                                // The bookmark wears the highlight's color when the ayah is highlighted,
                                // and the accent when it isn't - so the color you picked is visible from
                                // the row's badge alone, without reading the wash behind the text.
                                Image(systemName: "bookmark.fill")
                                    .font(.caption2)
                                    .foregroundStyle(bookmarkTint)
                                    .padding(4)
                                    .offset(x: 8, y: -6)
                            }
                        }
                        .overlay(alignment: .topLeading) {
                            if isLastListened {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.caption2)
                                    .foregroundStyle(settings.accentColor.color)
                                    .padding(4)
                                    .offset(x: -6, y: -6)
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
                    .sheet(isPresented: $showSelectTextSheet) {
                        SelectAyahTextSheet(surah: surah, ayah: ayah)
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
                    matchedMustafa: mMustafa,
                    crossArabic: cross.arabic,
                    crossSaheeh: cross.saheeh,
                    crossMustafa: cross.mustafa
                )
                .padding(.bottom, 2)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .lineLimit(nil)
        // Multi-select: content slides right to make room for the leading checkmark circle.
        .padding(.leading, isSelecting ? 32 : 0)
        .overlay(alignment: .leading) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? settings.accentColor.color : Color.secondary)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isSelecting)
        #if os(iOS)
        // Report this row's sheet state to the shared tracker so the reader's follow-the-recitation
        // scroll holds still while one of this row's sheets is up (see `AyahSheetPresence`).
        .onChange(of: anyAyahSheetOpen) { open in
            if open {
                AyahSheetPresence.shared.sheetOpened()
            } else {
                AyahSheetPresence.shared.sheetClosed()
            }
        }
        // If the row leaves the hierarchy while its flag is still set (e.g. the reader is popped with a
        // sheet open), the onChange(false) above never fires - release the claim here so the follow
        // scroll is never left disabled.
        .onDisappear {
            if anyAyahSheetOpen {
                AyahSheetPresence.shared.sheetClosed()
            }
        }
        #endif
        // Latch every line a match forces visible - one-way, cleared only by row recycling - so the
        // arrival-clear tap never changes this row's height (the list-jiggle fix; see the state's doc).
        .onAppear {
            for i in forcedNow.indices where forcedNow[i] { latchedForcedLines[i] = true }
        }
        .onChange(of: forcedNow) { now in
            for i in now.indices where now[i] { latchedForcedLines[i] = true }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelecting {
                // Multi-select mode: a tap anywhere on the row toggles its membership.
                settings.hapticFeedback()
                onToggleSelection?()
            } else if !searchText.isEmpty {
                settings.hapticFeedback()
                withAnimation {
                    scrollDown = ayah.id
                }
            } else if let onToggleHighlight {
                // Not searching: tapping an ayah marks it (and tapping the marked ayah again clears it).
                settings.hapticFeedback()
                onToggleHighlight()
            }
        }
        #if os(iOS)
        // Long press opens the SAME ayah actions sheet page mode's long press shows (user rule: one
        // grammar for "act on this ayah" in both modes) - the old .contextMenu is retired. The row's
        // ellipsis menu keeps the inline menu for discoverability.
        .onLongPressGesture {
            guard !isSelecting else { return }
            settings.hapticFeedback()
            showAyahActionsSheet = true
        }
        .sheet(isPresented: $showAyahActionsSheet) {
            AyahActionsSheet(
                surah: surah,
                ayah: ayah,
                onRequestSheet: { kind in requestRowSecondarySheet(kind) }
            )
            .smallMediumSheetPresentation()
        }
        // The tap-to-scroll jump, as a swipe too: while searching, swipe the result row to scroll down
        // to that ayah in the full list.
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        scrollDown = ayah.id
                    }
                } label: {
                    Label("Scroll Down", systemImage: "arrow.down.to.line")
                }
                .tint(settings.accentColor.color)
            }
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
        // Word-by-word: the card for the word the reader tapped. `item:` rather than `isPresented:` so
        // tapping a DIFFERENT word while the card is up re-presents it with the new word instead of
        // leaving the old one on screen.
        .sheet(item: $tappedWord) { tapped in
            WordMeaningSheet(
                surah: surah,
                ayah: ayah,
                word: tapped.word,
                meaning: tapped.meaning,
                position: tapped.index + 1,
                total: tapped.total
            )
            .environmentObject(settings)
        }
        // The riwayah word card: this riwayah's rules on the tapped word plus its Hafs counterpart.
        .sheet(item: $tappedRiwayahWord) { tapped in
            RiwayahWordSheet(
                surah: surah,
                ayah: ayah,
                tag: tapped.tag,
                word: tapped.word,
                index: tapped.index,
                total: tapped.total
            )
            .environmentObject(settings)
        }
        #endif
    }

    #if os(iOS)
    /// Cross-language spans for the reader's own rows - the search rows' `crossLanguageSpans`, with the
    /// same guards (Hafs display, no beginner letter-spacing, gloss pack bundled; comparison columns are
    /// another riwayah's text, so they opt out). Arabic query → aligned English words in each translation;
    /// English query → the Arabic tokens whose gloss carries it. Per-ayah exact alignment first, then the
    /// corpus lexicon fallback, exactly like the search results - so tapping a hit and landing here shows
    /// the same words lit that the result row showed.
    private func crossLanguageSpans(query: String) -> (arabic: [NSRange], saheeh: [NSRange], mustafa: [NSRange]) {
        let trimmed = queryForInlineHighlight(query)
        guard !trimmed.isEmpty,
              settings.isHafsDisplay,
              comparisonQiraahOverride == nil,
              !(settings.beginnerMode || ayahBeginnerMode || forceBeginner),
              WordByWordStore.isBundled else { return ([], [], []) }

        let displayText = arabicDisplayText()
        // The gloss pack's token order is defined against the RAW (unstripped) text; with "Hide
        // Tashkeel and Signs" off the display text IS raw, so the second resolve is skipped.
        let rawText = settings.cleanArabicText
            ? ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: nil)
            : displayText

        if trimmed.containsArabicLetters {
            // Per-ayah exact terms UNIONED with the corpus lexicon's - not a fallback. The aligned gloss
            // is one wording of the word ("straitened"); the lexicon carries the word family's gloss
            // variants from every occurrence, which is what bridges to a translation that phrased it
            // differently ("confining"). The union is what "maximize" buys here.
            var terms = CrossLanguageWordHighlight.englishTermsForArabicMatch(
                query: trimmed, surah: surah.id, ayah: ayah.id, rawText: rawText, displayText: displayText
            )
            for term in CrossLanguageWordHighlight.englishTermsForUnalignedArabicQuery(trimmed)
            where !terms.contains(term) {
                terms.append(term)
            }
            // The morphological Arabic spans are ADDITIVE: tokens of the same word family the plain
            // highlighter misses (صلاتهم for a صلاة query) light up in the Arabic line too.
            let arabicExtra = CrossLanguageWordHighlight.arabicSpansForArabicQuery(
                query: trimmed, in: displayText
            )
            guard !terms.isEmpty || !arabicExtra.isEmpty else { return ([], [], []) }
            return (arabicExtra,
                    CrossLanguageWordHighlight.wordSpans(of: terms, in: ayah.textEnglishSaheeh),
                    CrossLanguageWordHighlight.wordSpans(of: terms, in: ayah.textEnglishMustafa))
        } else {
            // Union here too: the per-ayah alignment and the corpus lexicon each catch tokens the
            // other misses (an inflected form the exact gloss missed; a gloss wording the lexicon
            // dropped under its noise cap).
            var spans = CrossLanguageWordHighlight.arabicSpansForEnglishMatch(
                query: trimmed, surah: surah.id, ayah: ayah.id, rawText: rawText, displayText: displayText
            )
            for span in CrossLanguageWordHighlight.arabicSpansForEnglishQuery(trimmed, arabicText: displayText)
            where !spans.contains(where: { NSIntersectionRange($0, span).length > 0 }) {
                spans.append(span)
            }
            return (spans, [], [])
        }
    }
    #endif

    /// Shifts UTF-16 spans forward when the rendered line carries an "N. " prefix the spans were not
    /// computed against.
    private static func offsetSpans(_ spans: [NSRange], by offset: Int) -> [NSRange] {
        guard offset > 0, !spans.isEmpty else { return spans }
        return spans.map { NSRange(location: $0.location + offset, length: $0.length) }
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
        matchedMustafa: Bool = false,
        crossArabic: [NSRange] = [],
        crossSaheeh: [NSRange] = [],
        crossMustafa: [NSRange] = []
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
                let beginner = settings.beginnerMode || ayahBeginnerMode || forceBeginner
                let arabicSource = arabicDisplayText()
                // "Basic" font renders with the standard Apple system font. The design is named explicitly rather
                // than inherited, because this view opts out of the app-wide rounded design below (its ayah-number
                // suffix always uses a bundled face, which that design would clobber). Dots-removed text stays in
                // the chosen bundled face - the ttfs carry real dotless glyphs now (patch_dotless_glyphs.py).
                let useSystemArabic = settings.quranUsesSystemArabicFont
                let arabicFont: Font = useSystemArabic
                    ? .system(size: settings.fontArabicSize, design: .rounded)
                    : .custom(
                        ayahArabicFontName(for: comparisonQiraahOverride ?? settings.displayQiraahForArabic),
                        size: settings.fontArabicSize
                    )
                // The ayah-end marker is always the Hafs Uthmani face: that font is what renders the digits as the
                // circled-flower ornament, so falling back to the system font here would print bare digits instead.
                let suffixFont: Font = .custom(Settings.hafsUthmaniFontName, size: settings.fontArabicSize)
                let preStyled = arabicTajweedText(displayText: arabicSource, beginner: beginner)
                    ?? arabicRiwayahTajweedText(displayText: arabicSource, beginner: beginner)
                    ?? arabicDiffText(displayText: arabicSource, beginner: beginner)

                #if os(iOS)
                if let glosses = wordByWordGlosses(displayText: arabicSource, beginner: beginner,
                                                   highlightQuery: highlightQuery) {
                    let selectWord: (Int) -> Void = { index in
                        tappedWord = TappedWord(
                            index: index,
                            word: WordTokens.tokens(in: arabicSource)[index],
                            meaning: glosses[index],
                            total: glosses.count
                        )
                    }
                    if settings.wordByWordInline {
                        // The study layout: each word a column with its meaning beneath it. Tapping
                        // still opens the same word card.
                        WordByWordInlineText(
                            displayText: arabicSource,
                            preStyled: preStyled,
                            fontName: useSystemArabic
                                ? nil
                                : ayahArabicFontName(for: comparisonQiraahOverride ?? settings.displayQiraahForArabic),
                            fontSize: CGFloat(settings.fontArabicSize),
                            ayahNumberArabic: ayah.idArabic,
                            glosses: glosses,
                            showsGlosses: settings.wordByWordInlineTranslation,
                            transliterations: wordByWordTransliterations(displayText: arabicSource),
                            selectedWord: tappedWord?.index,
                            onSelectWord: selectWord
                        )
                        .id(tajweedAnimationKey)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        // Same text, same colors - rendered through TextKit so a single word can be tapped.
                        WordByWordText(
                            displayText: arabicSource,
                            preStyled: preStyled,
                            fontName: useSystemArabic
                                ? nil
                                : ayahArabicFontName(for: comparisonQiraahOverride ?? settings.displayQiraahForArabic),
                            fontSize: CGFloat(settings.fontArabicSize),
                            ayahNumberArabic: ayah.idArabic,
                            glosses: glosses,
                            selectedWord: tappedWord?.index,
                            onSelectWord: selectWord
                        )
                        .id(tajweedAnimationKey)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    #if DEBUG
                    // "-openWordCard N" on a HAFS row opens the meaning card instead - same one-shot,
                    // same launch-target-row guard as the riwayah branch below.
                    Color.clear
                        .frame(height: 0)
                        .onAppear {
                            guard let target = Self.debugTargetAyah,
                                  target.surah == surah.id, target.ayah == ayah.id,
                                  let idx = Self.debugWordCardIndex else { return }
                            Self.debugWordCardIndex = nil
                            let tokens = WordTokens.tokens(in: arabicSource)
                            guard tokens.indices.contains(idx), glosses.indices.contains(idx) else { return }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                tappedWord = TappedWord(
                                    index: idx, word: tokens[idx], meaning: glosses[idx], total: glosses.count
                                )
                            }
                        }
                    #endif

                } else if let riwayahTag = riwayahWordTapTag(beginner: beginner, highlightQuery: highlightQuery) {
                    // Non-Hafs word tap: same tappable TextKit rendering, no glosses - the tap opens
                    // the riwayah word card (this riwayah's rules + the Hafs counterpart) instead.
                    WordByWordText(
                        displayText: arabicSource,
                        preStyled: preStyled,
                        fontName: useSystemArabic
                            ? nil
                            : ayahArabicFontName(for: comparisonQiraahOverride ?? settings.displayQiraahForArabic),
                        fontSize: CGFloat(settings.fontArabicSize),
                        ayahNumberArabic: ayah.idArabic,
                        glosses: [],
                        alwaysTappable: true,
                        selectedWord: tappedRiwayahWord?.index,
                        onSelectWord: { index in
                            let tokens = WordTokens.tokens(in: arabicSource)
                            guard tokens.indices.contains(index) else { return }
                            tappedRiwayahWord = RiwayahTappedWord(
                                index: index,
                                word: tokens[index],
                                total: tokens.count,
                                tag: riwayahTag
                            )
                        }
                    )
                    .id(tajweedAnimationKey)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    #if DEBUG
                    .onAppear {
                        // Only the launch-target row consumes the one-shot: any other row may be a
                        // recycled off-screen cell whose sheet SwiftUI immediately tears down.
                        guard let target = Self.debugTargetAyah,
                              target.surah == surah.id, target.ayah == ayah.id else { return }
                        if let idx = Self.debugWordCardIndex {
                            Self.debugWordCardIndex = nil
                            let tokens = WordTokens.tokens(in: arabicSource)
                            if tokens.indices.contains(idx) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    tappedRiwayahWord = RiwayahTappedWord(
                                        index: idx, word: tokens[idx], total: tokens.count, tag: riwayahTag
                                    )
                                }
                            }
                        }
                        if Self.debugOpenComparison {
                            Self.debugOpenComparison = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                showQiraahComparisonSheet = true
                            }
                        }
                    }
                    #endif

                } else {
                    arabicSnippet(source: arabicSource, font: arabicFont, preStyled: preStyled,
                                  beginner: beginner, suffixFont: suffixFont,
                                  highlightQuery: highlightQuery, matchedArabic: matchedArabic,
                                  extraRanges: crossArabic)
                }
                #else
                arabicSnippet(source: arabicSource, font: arabicFont, preStyled: preStyled,
                              beginner: beginner, suffixFont: suffixFont,
                              highlightQuery: highlightQuery, matchedArabic: matchedArabic,
                              extraRanges: crossArabic)
                #endif
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
                let prefix = prefixOnSaheeh ? "\(ayah.id). " : ""
                let txt = prefix + ayah.textEnglishSaheeh
                VStack(alignment: .leading, spacing: 4) {
                    HighlightedSnippet(
                        source: txt,
                        term: highlightQuery,
                        font: .system(size: fontSizeEN),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        highlightAllahNames: settings.highlightAllahNames,
                        guaranteeMatch: matchedSaheeh,
                        extraHighlightRanges: Self.offsetSpans(crossSaheeh, by: (prefix as NSString).length)
                    )
                    Text("- Saheeh International")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)
            }

            if showEnglishMustafa {
                let prefix = prefixOnMustafa ? "\(ayah.id). " : ""
                let txt = prefix + ayah.textEnglishMustafa
                VStack(alignment: .leading, spacing: 4) {
                    HighlightedSnippet(
                        source: txt,
                        term: highlightQuery,
                        font: .system(size: fontSizeEN),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        highlightAllahNames: settings.highlightAllahNames,
                        guaranteeMatch: matchedMustafa,
                        extraHighlightRanges: Self.offsetSpans(crossMustafa, by: (prefix as NSString).length)
                    )
                    Text("- Clear Quran (Mustafa Khattab)")
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
            // While searching within the surah, the row's TAP scrolls down to the ayah in the full list -
            // the same jump offered here for discoverability (and as a swipe action on the row).
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        scrollDown = ayah.id
                    }
                } label: {
                    Label("Scroll Down to Ayah", systemImage: "arrow.down.to.line")
                }

                Divider()
            }

            Button(role: isBookmarked ? .destructive : nil) {
                settings.hapticFeedback()
                toggleBookmarkWithNoteGuard()
            } label: {
                Label(
                    isBookmarked ? "Unbookmark Ayah" : "Bookmark Ayah",
                    systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                )
            }

            // Directly under the bookmark row, because it IS a bookmark action: picking a color saves
            // the ayah and paints its bookmark in that color - the same Highlight menu page mode's
            // actions sheet and the history cards already offer (list-mode parity, user rule).
            Menu {
                ayahHighlightMenuItems(surah: surah.id, ayah: ayah.id, settings: settings)
            } label: {
                Label(
                    ayahHighlight == nil ? "Highlight" : "Highlight: \(ayahHighlight!.title)",
                    systemImage: "highlighter"
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
                        beginnerOverrides.toggle(surah: surah.id, ayah: ayah.id)
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
                showSelectTextSheet = true
            } label: {
                Label("Select Text", systemImage: "highlighter")
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
