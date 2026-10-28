import SwiftUI
import Foundation

/// Whether any per-ayah sheet (tafsir, share, note, comparisons, actions...) is currently presented
/// from the reader. The LIST reader's "follow the recitation" scroll consults this and holds still while
/// a sheet is up: auto-scrolling the List tears down the row that is PRESENTING the sheet, which dismissed
/// the sheet mid-read on every ayah advance - and reclaiming a cell that is also a live presentation
/// anchor is exactly the kind of teardown that can bring the whole presentation stack down. Following
/// resumes on the first ayah advance after the sheet closes. Main-thread only (all writers are SwiftUI
/// view callbacks).
///
/// The PAGE reader no longer consults it (2026-09-20): `SurahView` hosts every page-mode sheet, so a
/// page turn dismisses nothing and the recitation can keep turning pages behind an open sheet. The
/// counter is still driven by the host's `rowSheet` hooks in both modes; only the list scroll reads it.
/// See `Docs/Quran/Page Mode Sheet Ownership.md`.
final class AyahSheetPresence: ObservableObject {
    static let shared = AyahSheetPresence()
    private init() {}

    @Published private(set) var openCount = 0

    var anySheetOpen: Bool { openCount > 0 }

    func sheetOpened() { openCount += 1 }
    /// Clamped: a presenter torn down in an unexpected order must never push the count negative.
    func sheetClosed() { openCount = max(0, openCount - 1) }
}

/// The key suffix that keeps a BETA riwayah's locked and unlocked texts apart in the list reader's
/// caches (`AyahRow.arabicDisplayCache` and `matchSourcesCache`, `SurahView`'s prepared row set and
/// search blobs): "|beta" or "|locked" for a beta tag, empty for every other riwayah and for Hafs.
///
/// Locked, every reader of a beta riwayah's text gets the Hafs fallback and every row id "exists";
/// unlocked, the riwayah's own words and its own ayah count. Those caches keyed on the tag alone, and
/// the launch prewarm fills them while the riwayah is still locked (it reads as its printed mushaf
/// until "Use Beta Text"), so after the consent the list drew Hafs words under the riwayah's name for
/// the first screenfuls of the warmed surahs, al-Fatihah always, with rows past the riwayah's own
/// count, until the next launch (2026-10-04; Quality Guide A7 fixed the same thing for the page
/// caches, `MushafPagination.betaMark`). In the key, so no purge has to be remembered anywhere.
///
/// A plain enum, so it is callable from the off-main prewarms. The tag is already canonical
/// (`displayQiraahForArabic`, a comparison override), so this is one set lookup, and the defaults
/// read happens for a beta tag only.
enum RiwayahTextCacheMark {
    static func mark(for qiraah: String?) -> String {
        guard let qiraah, !qiraah.isEmpty, Settings.Riwayah.betaTags.contains(qiraah) else { return "" }
        return UserDefaults.standard.bool(forKey: "betaQiraatEnabled") ? "|beta" : "|locked"
    }
}

struct AyahRow: View, Equatable {
    /// Bumped when an off-main tajweed paint for this row lands (see `arabicTajweedText`).
    @State private var tajweedPaintGeneration = 0
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// NOT @ObservedObject (Phase 10.4): the body never reads a published field of it (the diff lane and
    /// the Copy action call its O(1) lookups), so observing it only re-ran every visible row on each
    /// QuranData publish (the load batch, the verse index, the surah search index), past `.equatable()`.
    private var quranData: QuranData { .shared }
    /// Only the highlighter's wash reads this: the same hue needs a heavier alpha on the dark page to
    /// register at all, so the tint is resolved per scheme rather than baked into the palette.
    @Environment(\.colorScheme) private var colorScheme
    /// The in-surah search's Match rule, so the word renderers paint what the snippet paints.
    @Environment(\.searchWordRule) private var wordRule
    /// NOT @ObservedObject: the player is used only inside action closures plus the one
    /// `isPlayingThis` input below. Observing it re-ran EVERY visible row's body once per ayah while
    /// a surah played (`currentAyahNumber` publishes each advance), bypassing `.equatable()` -
    /// observation invalidates independently of input comparison. The parent passes `isPlayingThis`
    /// instead, so an ayah advance re-renders exactly the two rows whose tint changes.
    private var quranPlayer: QuranPlayer { .shared }

    /// The per-ayah "Apply Settings" pins (beginner spacing, tajweed, tashkeel, dots, Highlight Allah,
    /// word by word), held in a shared session store rather than in this row's own `@State`. A row in a
    /// lazy list is torn down when it scrolls away and rebuilt from its inputs when it comes back, so
    /// private state could not survive - which is why the old toggle "sometimes didn't work".
    @ObservedObject private var displayOverrides = AyahDisplayOverrides.shared
    /// What this ayah renders with: its pins over the app settings.
    private var displayChoices: AyahDisplayChoices {
        displayOverrides.choices(surah: surah.id, ayah: ayah.id, settings: settings)
    }

    /// Lines a match FORCED visible (a search hit / arrival showing the transliteration or a translation
    /// even though its toggle is off), latched for as long as this row stays mounted: clearing the arrival
    /// used to collapse those lines, shrink the row, and nudge the whole list ("it'll scroll a little up
    /// or down" - user report). Latched lines keep the row's height stable through the clear; the row is
    /// recycled once it scrolls away, so the latch resets naturally. Order: translit, saheeh, mustafa, arabic.
    @State private var latchedForcedLines: [Bool] = [false, false, false, false]

    // (The row's sheets - share, tafsir, note, comparisons, custom range, the actions sheet and the
    // word cards - are presented by the HOST now, through `onRequestSheet`; see Phase 5 step 6.)
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
    var onToggleSelection: (() -> Void)? = nil

    /// Fired when the ayah's actual text block (Arabic / translations) scrolls into view, not just the
    /// row's number/menu header. Drives last-read tracking and automatic khatm marking so an ayah only
    /// counts as "read" once its text is on screen.
    var onAyahTextAppear: (() -> Void)? = nil
    var onAyahTextDisappear: (() -> Void)? = nil

    /// True when the player is currently on this exact ayah - drives the accent playing tint. Passed
    /// in (and compared in `==`) rather than read from an observed player; see the note on `quranPlayer`.
    var isPlayingThis: Bool = false
    /// True when this exact ayah is the saved single-ayah listening position (the speaker badge on
    /// the pill). Passed in and compared in `==` rather than decoded from Settings in every row's
    /// body: the decode is memoized, but the read still ran per row per pass (Phase 5 step 3).
    var isLastListened: Bool = false
    /// A lit theme's wash (see `ThemeHighlights`): the faintest standing mark, under every momentary
    /// tint and under the bookmark highlighter's own color.
    var themeWash: ThemeWashColor? = nil

    #if os(iOS)
    /// What Test Mode hides in this row, nil when it shows (see `QuranTestMode`). An input compared in
    /// `==`, like `isPlayingThis`: the row never reads the test's state itself.
    var testVeil: QuranTestVeil? = nil
    #endif

    /// Test Mode hides the recitation here: the Arabic (in whichever renderer draws it), the muqattaat
    /// pronunciation and the transliteration.
    private var testHidesRecitation: Bool {
        #if os(iOS)
        return testVeil != nil
        #else
        return false
        #endif
    }

    /// Test Mode hides the translations here too.
    private var testHidesEverything: Bool {
        #if os(iOS)
        return testVeil == .everything
        #else
        return false
        #endif
    }

    private func sameTestVeil(as other: Self) -> Bool {
        #if os(iOS)
        return testVeil == other.testVeil
        #else
        return true
        #endif
    }

    #if os(iOS)
    /// The host presents this row's sheets (Phase 5 step 6): twelve `.sheet`/`.confirmationDialog`
    /// modifiers per row were ~100-150 presentation hosts churned per screenful of scrolling. The
    /// kind of the sheet currently up for THIS ayah comes back as `openSheet`, so the row keeps its
    /// attention tint while the sheet is open and lights the tapped word under its card.
    var onRequestSheet: ((AyahRowSheetKind) -> Void)? = nil
    var openSheet: AyahRowSheetKind? = nil

    private func requestSheet(_ kind: AyahRowSheetKind) {
        switch kind {
        case .word, .riwayahWord: Self.lastWordCardRequest = Date()
        default: break
        }
        onRequestSheet?(kind)
    }

    /// When a word card was last asked for, from any row: the ayah's own double tap (`ayahDoubleTap`)
    /// stands down when a word's two taps have just opened one.
    private static var lastWordCardRequest: Date = .distantPast

    /// High priority makes the sheet open during the hold, before the reading surface's tap ends.
    /// Apply only to the text and reference pill, so each menu control owns its own gestures.
    private var actionsHoldGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.45)
            .onEnded { _ in
                settings.hapticFeedback()
                requestSheet(.actions)
            }
    }

    /// Two taps on the ayah's text, off any word, play just that ayah (Kalysbek, 2026-10-21: the play
    /// button's double tap "works sometimes and mostly doesn't" against the menu its single tap opened,
    /// and the button is "too small for double tap"; Abu: "tapping anywhere that's not a word plays the
    /// ayah once"). Simultaneous with the row's single tap, so marking an ayah stays instant: the two
    /// taps mark it and unmark it again, the trade a word's two taps already make (`WordByWordTextView`).
    /// A word's own two taps fire alongside this one, so the play waits a beat and stands down when a
    /// word card was just asked for, whichever of the two actions ran first.
    private var ayahDoubleTap: some Gesture {
        TapGesture(count: 2)
            .onEnded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    guard Date().timeIntervalSince(Self.lastWordCardRequest) > 0.5 else { return }
                    settings.hapticFeedback()
                    quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
                }
            }
    }

    /// The double tap plays only in the plain reading state: a search term gives the row's taps to the
    /// scroll-to-match, multi-select gives them to the checkmark, and ayah audio is Hafs-numbered (the
    /// play button's own gate).
    private var playsOnDoubleTap: Bool {
        !isSelecting
            && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && settings.isHafsDisplay
    }

    private var openWordIndex: Int? {
        if case .word(let tapped) = openSheet { return tapped.index }
        return nil
    }

    private var openRiwayahWordIndex: Int? {
        if case .riwayahWord(let tapped) = openSheet { return tapped.index }
        return nil
    }
    #endif

    private func sameOpenSheet(as other: Self) -> Bool {
        #if os(iOS)
        return openSheet == other.openSheet
        #else
        return true
        #endif
    }

    /// Whether any of this ayah's action sheets/dialogs is open - drives the "keep it lit until the sheet is
    /// gone" tint. watchOS has none of these sheets, so it's always false there.
    private var anyAyahSheetOpen: Bool {
        #if os(iOS)
        openSheet != nil
        #else
        false
        #endif
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.surah == rhs.surah &&
        lhs.ayah == rhs.ayah &&
        lhs.comparisonQiraahOverride == rhs.comparisonQiraahOverride &&
        lhs.renderSettingsSignature == rhs.renderSettingsSignature &&
        lhs.scrollDown == rhs.scrollDown &&
        lhs.isHighlighted == rhs.isHighlighted &&
        lhs.themeWash == rhs.themeWash &&
        lhs.isPlayingThis == rhs.isPlayingThis &&
        lhs.isLastListened == rhs.isLastListened &&
        lhs.arrivalTerm == rhs.arrivalTerm &&
        lhs.isSelecting == rhs.isSelecting &&
        lhs.isSelected == rhs.isSelected &&
        lhs.searchText == rhs.searchText &&
        lhs.sameOpenSheet(as: rhs) &&
        lhs.sameTestVeil(as: rhs)
    }

    nonisolated(unsafe) private static let arabicDisplayCache: NSCache<NSString, NSString> = {
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

    private func arabicDisplayText() -> String {
        let choices = displayChoices
        let clean = choices.hideTashkeel
        let qiraah = comparisonQiraahOverride ?? settings.displayQiraahForArabic
        let qiraahKey = qiraah ?? "Hafs"
        // The dots flag must be in the key: it changes the text `textCleanArabic` returns for the
        // same `clean` bit, and nothing purges this cache when the toggle flips. The beta mark for
        // the same reason (`RiwayahTextCacheMark`), and the hamzat al-wasl notation likewise.
        let wasl = settings.waslSign(for: qiraah)
        let key = "\(surah.id):\(ayah.id)|\(clean ? 1 : 0)\(choices.hideDots ? 1 : 0)|\(choices.beginner ? 1 : 0)|\(qiraahKey)|\(wasl.rawValue)"
            + RiwayahTextCacheMark.mark(for: qiraah)
        // The key names the ayah by its surah and number alone, so it is only right while `ayah` really
        // is that surah's ayah. A row handed another surah's ayah files those words under this number for
        // as long as the entry lives: the Previous / Next defect (see `SurahView.listAyahs`).
        assert(surah.ayahs.first(where: { $0.id == ayah.id }) == ayah,
               "AyahRow \(surah.id):\(ayah.id) was handed another surah's ayah")

        if let cached = Self.arabicDisplayCache.object(forKey: key as NSString) {
            return cached as String
        }

        let baseText = ayah.displayArabicText(surahId: surah.id, clean: clean, removeDots: choices.hideDots,
                                              qiraahOverride: comparisonQiraahOverride, waslSign: wasl)
        let spaced = choices.beginner ? baseText.beginnerSpaced : baseText
        Self.arabicDisplayCache.setObject(spaced as NSString, forKey: key as NSString)
        return spaced
    }

    nonisolated static func prewarmArabicDisplay(surah: Surah, settings: Settings, limit: Int? = nil) {
        let clean = settings.cleanArabicText
        // Same key shape as `arabicDisplayText`, so the warm hits; and the text is computed with the
        // SAME dots bit the key carries (it used to key on `clean && dots` while the text read the
        // global flag, filing dotless text under a dotted key).
        let dots = settings.removeArabicDots
        let beginner = settings.beginnerMode
        let qiraah = settings.displayQiraahForArabic
        let qiraahKey = qiraah ?? "Hafs"
        let betaMark = RiwayahTextCacheMark.mark(for: qiraah)
        let wasl = settings.waslSign(for: qiraah)
        let ayahs = limit.map { Array(surah.ayahs.prefix($0)) } ?? surah.ayahs

        for ayah in ayahs where ayah.existsInQiraah(qiraah, surahID: surah.id) {
            let key = ("\(surah.id):\(ayah.id)|\(clean ? 1 : 0)\(dots ? 1 : 0)|\(beginner ? 1 : 0)|\(qiraahKey)|\(wasl.rawValue)" + betaMark) as NSString
            if Self.arabicDisplayCache.object(forKey: key) != nil { continue }

            let baseText = ayah.displayArabicText(surahId: surah.id, clean: clean, removeDots: dots, qiraahOverride: qiraah, waslSign: wasl)
            let displayText = beginner ? baseText.beginnerSpaced : baseText
            Self.arabicDisplayCache.setObject(displayText as NSString, forKey: key)
        }
    }

    private func normalizedMatchSources() -> MatchSources {
        let qiraah = comparisonQiraahOverride ?? settings.displayQiraahForArabic
        let key = ("\(surah.id):\(ayah.id)|\(qiraah ?? "Hafs")" + RiwayahTextCacheMark.mark(for: qiraah)) as NSString

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
        let residual = query.removingAyahSearchOperators.trimmingCharacters(in: .whitespacesAndNewlines)
        // A reference query ("5:5", "page 12") names a place, not words: nothing in the text IS the
        // match, and the guaranteed-highlight fallback would paint some arbitrary closest word - the
        // rule `AyahArrivalTerm` already applies to the terms that travel with a navigation.
        guard residual.rangeOfCharacter(from: .decimalDigits) == nil else { return "" }
        return residual
    }

    private var shouldShowTajweedColors: Bool {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }

        let usingHafs: Bool = if let override = comparisonQiraahOverride {
            override.isEmpty || override == "Hafs"
        } else {
            settings.isHafsDisplay
        }

        return displayChoices.tajweed
            && settings.showArabicText
            && usingHafs
    }

    #if os(iOS)
    /// The per-word glosses to render this ayah with, or nil when word-by-word is off / can't apply here.
    ///
    /// Every condition is a case where a word index would not mean what the pack says it means:
    /// another riwayah words the ayah differently, beginner mode splits every letter into its own token,
    /// a comparison column isn't the reader's own text. A search or a multi-select is NOT a reason:
    /// the renderer used to give way to the one-Text snippet while a term was typed (or an arrival
    /// term showed, or select mode was on) and come back when it cleared, and every flip re-spaced
    /// the Arabic (Abu, 2026-09-05). Those states own the TAP instead - see `wordTapsAllowed`.
    private func wordByWordGlosses(displayText: String, beginner: Bool) -> [String]? {
        // Either word feature wants the glosses: the study layout draws them under the words, the
        // tap opens them in a card. The two are independent switches (Abu, 2026-09-04).
        guard settings.wordByWordMeanings || displayChoices.wordByWord,
              settings.showArabicText,
              settings.isHafsDisplay,
              !beginner,
              comparisonQiraahOverride == nil else { return nil }

        let raw = ayah.rawArabicText(surahId: surah.id, qiraahOverride: nil)
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
        let raw = ayah.rawArabicText(surahId: surah.id, qiraahOverride: nil)
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
            highlightAllahNames: displayChoices.highlightAllah,
            guaranteeMatch: matchedArabic,
            extraHighlightRanges: extraRanges
        )
        .arabicFontDesign(custom: true)
        .id(tajweedAnimationKey)
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
        // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
        .environment(\.layoutDirection, .leftToRight)
        .lineLimit(nil)
    }

    private func arabicTajweedText(displayText renderedDisplayText: String, beginner: Bool) -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        let text = ayah.rawArabicText(surahId: surah.id, qiraahOverride: comparisonQiraahOverride)
        // The paint completion bumps `tajweedPaintGeneration`, but SwiftUI re-evaluates a body only
        // for state the body READ: a bumped-but-never-read @State is a silent no-op, and the row kept
        // its plain first paint until something else re-rendered it (a tap, a font change, even the
        // screenshot that "verified" this path). Reading it here, inside the body pass, is the
        // dependency (2026-09-05, Abu: "some ayahs have tajweed off unless I tap a word or an ayah").
        _ = tajweedPaintGeneration
        let choices = displayChoices
        switch TajweedStore.shared.cachedAttributedText(
            surah: surah.id,
            ayah: ayah.id,
            text: text,
            displayText: renderedDisplayText,
            cleanDisplayText: choices.hideTashkeel,
            beginnerSpacing: beginner,
            removeArabicDots: choices.hideDots
        ) {
        case .painted(let styled):
            #if DEBUG
            if RenderCounter.enabled, tajweedPaintGeneration > 0 {
                NSLog("TAJWEED REPAINT %d:%d generation %d", surah.id, ayah.id, tajweedPaintGeneration)
            }
            #endif
            return styled
        case .nothing:
            return nil
        case nil:
            // Ahead of the warm: never the cluster analysis in body. Paint off main and re-render
            // this one row (the @State bump) when the cache holds it.
            TajweedStore.shared.paintOffMain(
                surah: surah.id,
                ayah: ayah.id,
                text: text,
                displayText: renderedDisplayText,
                cleanDisplayText: choices.hideTashkeel,
                beginnerSpacing: beginner,
                removeArabicDots: choices.hideDots
            ) { tajweedPaintGeneration &+= 1 }
            return nil
        }
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
    /// "-openAyahSecondary <kind>" (share, selectText, tafsir, translations...: `AyahSecondarySheet`'s raw
    /// values) opens that sheet of the same row, for screenshot runs of the sheets' chrome.
    private static var debugOpenSecondary: AyahSecondarySheet? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-openAyahSecondary"), i + 1 < args.count else { return nil }
        return AyahSecondarySheet(rawValue: args[i + 1])
    }()
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
    /// and not beginner letter-spacing (where a word index would lie). A search or a multi-select
    /// keeps this renderer too (same reasoning as `wordByWordGlosses`); they only take the tap.
    /// The card shows the riwayah's rules and the aligned Hafs counterpart instead of a gloss -
    /// there is no gloss pack for non-Hafs texts.
    private func riwayahWordTapTag(beginner: Bool) -> String? {
        guard settings.wordByWordMeanings,
              settings.showArabicText,
              !beginner else { return nil }
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
        guard displayChoices.tajweed, settings.showArabicText else { return nil }
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
            guard displayChoices.hideTashkeel else { return nil }
            let full = ayah.rawArabicText(surahId: surah.id, qiraahOverride: comparisonQiraahOverride)
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
                referenceParts.append(hafsAyah.displayArabicText(surahId: surah.id, clean: displayChoices.hideTashkeel,
                                                                 removeDots: displayChoices.hideDots, qiraahOverride: ""))
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
                        // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
                        .environment(\.layoutDirection, .leftToRight)

                    muqattaatNamesView(p, font: arabicFont)
                        .arabicFontDesign(custom: usesCustomFace)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
                        .environment(\.layoutDirection, .leftToRight)

                    Divider()
                        .padding(.vertical, 2)

                    // The letter count, plus the elongation - but only the elongation these particular letters
                    // actually carry. Ṭā-Hā has no maddah sign on either name, so it is 2 counts, not 6.
                    HStack(spacing: 8) {
                        Text(p.letters.count == 1 ? String(localized: "\(p.letters.count) letter") : String(localized: "\(p.letters.count) letters"))
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)

                        Spacer()

                        if let maddDescription = p.maddDescription {
                            Text(maddDescription.localizedDigits)
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
        if displayChoices.tajweed,
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

    /// The identity of the Arabic text views in this row: a change here REPLACES the view rather than
    /// updating it.
    ///
    /// `renderSettingsSignature` is part of it, which folds the window width (see SurahView), so a
    /// ROTATION gives these views a fresh identity (Abu, 2026-10-07: "going from horizontal to vertical
    /// or vice versa ruins list"). `WordByWordText` keeps its measured content width in `@State`, and
    /// `@State` is tied to a view's IDENTITY, not to its value: re-rendering the row (which the
    /// signature in `AyahRow.==` already forced correctly) does NOT reset a child's state, so the view
    /// kept the previous orientation's width - 794pt of TextKit layout inside a ~338pt card. Traced:
    /// `updateUIView` was still being handed `width=794` after the interface came back to 402pt. Since
    /// nothing above `WordByWordTextView` clips (and a view's own drawing fills its bounds whatever its
    /// `clipsToBounds` says), that overflow PAINTED outside the row - Arabic and English running off both sides, and a List
    /// that scrolled sideways. A new identity discards the stale state and the view re-measures.
    private var tajweedAnimationKey: String {
        let categorySignature = settings.tajweedCategoryVisibilitySignature
        let qiraahKey = comparisonQiraahOverride ?? settings.displayQiraah
        let choices = displayChoices
        return [
            renderSettingsSignature,
            choices.tajweed ? "1" : "0",
            choices.highlightAllah ? "1" : "0",
            choices.hideTashkeel ? "1" : "0",
            choices.hideDots ? "1" : "0",
            choices.beginner ? "1" : "0",
            choices.wordByWord ? "1" : "0",
            qiraahKey,
            categorySignature,
            settings.riwayahTajweedHiddenRules
        ].joined(separator: "|")
    }

    #if os(watchOS)
    /// How far the watch's wash reaches above and below the text. The phone paints the whole cell
    /// instead (`rowWash`).
    private var ayahHighlightBackgroundVerticalPadding: CGFloat {
        if #available(watchOS 26.0, *) {
            return -11
        }
        return -2
    }
    #endif

    /// The gutter the reading column keeps on each side, ON TOP of the List row's own inset (Abu,
    /// 2026-09-22: "why is there no natural horizontal padding for list mode for ayahs"). Measured
    /// before this existed: the row inset is 24pt, every wash below expands 12pt OUTWARD to read as
    /// a band rather than a strip, and justified Arabic then filled the full 24pt-inset width - so
    /// the visible margin was the wash's 12pt and glyph ink came within about 20pt of the screen.
    ///
    /// 2026-10-05: back to 0 on the phone. The 12pt was measured against a 24pt row inset, but the
    /// reader's list is inset-grouped whenever `defaultView` is on, where the system's own row inset
    /// is already ~20pt - so the two stacked and the text column lost ~32pt a side, about 16% of a
    /// 402pt screen, on the axis justified Arabic needs most (Abu, 2026-10-05: "why is there
    /// horizontal padding bruv"). The system inset IS the natural padding the original request asked
    /// for; this constant only ever added a second one on top of it. A marked ayah's wash is the
    /// whole cell (`rowWash`), so it never depended on this.
    ///
    /// Kept as a named constant rather than deleted: the select-mode checkmark is positioned relative
    /// to it, and a future idiom (a wider phone, a different list style) may want it back. The watch
    /// keeps 0 for its own reason: 12pt of a 40mm screen is a line of text.
    private static let readingGutter: CGFloat = 0

    #if os(iOS)
    /// The air around the header's 28 pt play and ⋯ controls that still counts as a tap on them (Kalysbek,
    /// 2026-10-21: "the play button is just too small"; Abu: the same height as now, a bigger hit box "as
    /// long as it doesnt bleed into words"). Up into the row's top inset and out into the list's margin,
    /// where nothing else answers; between the two only half their 4 pt gap, so neither takes the other's
    /// taps; and down only the header's own 2 pt of padding, short of the Arabic line under them. The
    /// control's label wears the slop as padding and the control takes it back as negative padding, so
    /// the row's layout does not move.
    private static let playHitSlop = EdgeInsets(top: 8, leading: 4, bottom: 2, trailing: 2)
    private static let ellipsisHitSlop = EdgeInsets(top: 8, leading: 2, bottom: 2, trailing: 8)

    /// A header control's icon wearing its hit slop (see `playHitSlop`).
    private func headerControlIcon(_ systemName: String, slop: EdgeInsets) -> some View {
        Image(systemName: systemName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 25, height: 25)
            .foregroundColor(settings.accentColor.color)
            .conditionalGlassEffect()
            .frame(width: 28, height: 28)
            .padding(slop)
            .contentShape(Rectangle())
    }
    #endif

    #if os(watchOS)
    /// How far the watch's wash reaches past the text on each side, so a marked ayah reads as a band.
    private static let washOutset: CGFloat = 12
    #endif

    /// The one wash a row wears, the strongest claim first.
    ///
    /// Being recited, or picked in select mode, is the accent. Tapped, landed on, or holding one of its
    /// sheets open (lit until the sheet is gone) is the grey attention tint; select mode shows only
    /// the selection. Then the highlighter's color: it is the quietest of the four tints on purpose.
    /// Recitation, selection and attention are momentary, what the app is doing right now, while the
    /// highlight is a standing mark the user left and must not compete with them for the same row: it
    /// shows only when nothing momentary is on the ayah, and comes back the moment the reciter moves
    /// on. Last, a lit theme's wash.
    ///
    /// Static so the reader can lay it over the row's whole cell (`rowWash`) from OUTSIDE `.equatable()`:
    /// a cell background set inside this body never reached the List (measured 2026-10-09: every ayah
    /// card stayed its plain color).
    static func wash(
        isPlaying: Bool,
        isSelecting: Bool,
        isSelected: Bool,
        isMarked: Bool,
        highlight: AyahHighlightColor?,
        themeWash: ThemeWashColor?,
        colorScheme: ColorScheme,
        accent: Color,
        defaultView: Bool,
        themeGround: Color? = nil
    ) -> Color? {
        if isPlaying || (isSelecting && isSelected) {
            return ReaderRowTint.accent(accent, defaultView: defaultView)
        }
        if !isSelecting && isMarked {
            return ReaderRowTint.attention
        }
        if let highlight {
            return highlight.tint(colorScheme)
        }
        return themeWash?.tint(colorScheme, on: themeGround)
    }

    var body: some View {
        let _ = RenderCounter.hit("AyahRow")
        let isBookmarked = isBookmarkedHere
        // (`isLastListened`, the speaker badge on the pill, is an input now - see the property.)
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

        // The row's wash (see `wash(...)`). The phone paints it as the row's whole cell from the reader
        // (`SurahView.ayahRowGroup`); the watch draws it here, behind the text.
        #if os(watchOS)
        let wash = Self.wash(isPlaying: isPlayingThis, isSelecting: isSelecting, isSelected: isSelected,
                             isMarked: isHighlighted || anyAyahSheetOpen, highlight: ayahHighlight,
                             themeWash: themeWash, colorScheme: colorScheme,
                             accent: settings.accentColor.color, defaultView: settings.defaultView)
        #endif

        ZStack {
            #if os(watchOS)
            if let wash {
                RoundedRectangle(cornerRadius: 24)
                    .fill(wash)
                    .padding(.horizontal, -Self.washOutset)
                    .padding(.vertical, ayahHighlightBackgroundVerticalPadding)
            }
            #endif

            VStack(alignment: .leading, spacing: 8) {
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
                            toggleBookmarkOrConfirm()
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

                    #if os(iOS)
                    .highPriorityGesture(actionsHoldGesture, including: isSelecting ? .subviews : .all)
                    #endif

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

                    // Simple Mode folds the play menu into the one ayah menu, whose first action is
                    // Play This Ayah (Docs/Product/Simple Mode Guide.md).
                    //
                    // A tap opens the playback MENU, a double tap plays from this ayah to the end of
                    // the surah, and a hold opens Play Custom Range (Abu, 2026-10-23: "return it as a
                    // menu... if you double tap it play from here until end of Surah but if you hold
                    // it open custom range"). The ⋯ beside it has the same tap / double tap / hold
                    // shape (`ShortcutMenu`), so the pair behaves alike. For two days (2026-10-21) the
                    // tap played and the hold opened the menu. The one ayah stays the text's double
                    // tap (`ayahDoubleTap`).
                    if settings.isHafsDisplay, !settings.hides(.ayahPlayMenu) {
                        ShortcutMenu(
                            doubleTap: MenuShortcut(String(localized: "Play From Ayah")) {
                                settings.hapticFeedback()
                                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id,
                                                     continueRecitation: true, continueScope: .surah)
                            },
                            hold: MenuShortcut(String(localized: "Play Custom Range")) {
                                settings.hapticFeedback()
                                requestSheet(.secondary(.customRange))
                            }
                        ) {
                            Text("Ayah Playback")
                                .foregroundStyle(.secondary)

                            ayahPlaybackItems()
                        } label: {
                            headerControlIcon("play.circle", slop: Self.playHitSlop)
                        }
                        .padding(Self.playHitSlop.negated)
                        .accessibilityLabel("Ayah Playback")
                        .accessibilityIdentifier("ayahPlayButton")
                    }

                    ShortcutMenu(
                        doubleTap: MenuShortcut(String(localized: "Copy Ayah")) {
                            settings.hapticFeedback()
                            ShareAyahSheet.copyAyahToPasteboard(surahNumber: surah.id, ayahNumber: ayah.id,
                                                              settings: settings, quranData: quranData)
                        },
                        hold: MenuShortcut(String(localized: "Share Ayah")) {
                            settings.hapticFeedback()
                            requestSheet(.secondary(.share))
                        }
                    ) {
                        Text("Ayah Actions")
                            .foregroundStyle(.secondary)

                        // The same list every other ayah menu shows (user rule 2026-09-05: the Quran
                        // tab's long press, this menu and the page's sheet offer the same actions),
                        // minus playback: the ▶ beside it IS the playback menu, so Play Ayah is not
                        // repeated here (Abu, 2026-10-23: "remove that from three ellipses"). Simple
                        // Mode is the other exception: five actions and More Actions, which opens the
                        // long-press sheet with all of them (Abu, 2026-10-10).
                        if settings.hides(.ayahLongMenu) {
                            simpleMenuBlock(isBookmarked: isBookmarked)
                        } else {
                            menuBlock(isBookmarked: isBookmarked)
                        }
                    } label: {
                        headerControlIcon("ellipsis.circle", slop: Self.ellipsisHitSlop)
                    }
                    .padding(Self.ellipsisHitSlop.negated)
                    .accessibilityLabel("Ayah Actions")
                    .accessibilityIdentifier("ayahActionsMenu")
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
                .padding(.bottom, settings.showArabicText ? 4 : 2)
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
                #if os(iOS)
                // Keep the row's actions hold on the reading surface. Putting it on the whole row
                // lets SwiftUI's high-priority recognizer steal holds from the play/ellipsis controls.
                .contentShape(Rectangle())
                .highPriorityGesture(actionsHoldGesture, including: isSelecting ? .subviews : .all)
                // The ayah's two-tap play, on the same surface (see `ayahDoubleTap`): not the header,
                // whose pill and controls answer taps of their own.
                .simultaneousGesture(ayahDoubleTap, including: playsOnDoubleTap ? .all : .subviews)
                #endif
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
        // The reading gutter, OUTERMOST: the select-mode checkmark stays inside the margin instead of
        // sitting flush against the screen edge. The whole row moves in by this much.
        .padding(.horizontal, Self.readingGutter)
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

            Button(String(localized: "Repeat Ayah 3×").localizedDigits) {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 3)
            }

            Button(String(localized: "Repeat Ayah 5×").localizedDigits) {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 5)
            }

            Button(String(localized: "Repeat Ayah 10×").localizedDigits) {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 10)
            }

            Button(String(localized: "Repeat Ayah 15×").localizedDigits) {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 15)
            }

            Button(String(localized: "Repeat Ayah 20×").localizedDigits) {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: 20)
            }

            Button("Repeat Ayah Forever") {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: QuranPlayer.infiniteRepeat)
            }
        } message: {
            Text("Choose how you want to start playback for this ayah.")
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
              !displayChoices.beginner,
              WordByWordStore.isBundled else { return ([], [], []) }

        let displayText = arabicDisplayText()
        // The gloss pack's token order is defined against the RAW (unstripped) text; with "Hide
        // Tashkeel and Signs" off the display text IS raw, so the second resolve is skipped.
        let rawText = displayChoices.hideTashkeel
            ? ayah.rawArabicText(surahId: surah.id, qiraahOverride: nil)
            : displayText

        if trimmed.containsArabicLetters {
            // Per-ayah exact terms UNIONED with the corpus lexicon's - not a fallback. The aligned gloss
            // is one wording of the word ("straitened"); the lexicon carries the word family's gloss
            // variants from every occurrence, which is what bridges to a translation that phrased it
            // differently ("confining"). The union is what "maximize" buys here.
            var terms = CrossLanguageWordHighlight.englishTermsForArabicMatch(
                query: trimmed, surah: surah.id, ayah: ayah.id, rawText: rawText, displayText: displayText,
                wordRule: wordRule
            )
            for term in CrossLanguageWordHighlight.englishTermsForUnalignedArabicQuery(trimmed)
            where !terms.contains(term) {
                terms.append(term)
            }
            // The morphological Arabic spans are ADDITIVE: tokens of the same word family the plain
            // highlighter misses (صلاتهم for a صلاة query) light up in the Arabic line too.
            let arabicExtra = CrossLanguageWordHighlight.arabicSpansForArabicQuery(
                query: trimmed, in: displayText, wordRule: wordRule
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
        // This ayah's pins over the app settings - one resolve for the whole block.
        let choices = displayChoices

        VStack(alignment: .leading, spacing: 10) {
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
                    requestSheet(.secondary(.note))
                }
                #endif
                .padding(.top, 4)
            }

            muqattaatPronunciationBlock()
                .quranTestVeiledIfAvailable(testHidesRecitation)

            // One unit for Test Mode, whichever renderer draws the Arabic. A `Group`, so the modifier
            // reaches each view inside and the stack's spacing is exactly what it was.
            Group {
            if showArabic {
                let beginner = choices.beginner
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
                // The search look the word renderers share with the one-Text snippet: the term's
                // words (from the snippet's own match ladder) plus the cross-language spans, in the
                // accent over plain text. Computed here so the renderers keep drawing through a
                // search, an arrival and a multi-select instead of swapping to the snippet and back.
                let hasTerm = !highlightQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let searchRanges: [NSRange] = {
                    var spans: [NSRange] = hasTerm
                        ? HighlightedSnippet.matchRanges(of: highlightQuery, in: arabicSource, guaranteeMatch: matchedArabic, wordRule: wordRule)
                            .map { NSRange($0, in: arabicSource) }
                        : []
                    for span in crossArabic
                    where !spans.contains(where: { NSIntersectionRange($0, span).length > 0 }) {
                        spans.append(span)
                    }
                    return spans
                }()
                let searchActive = hasTerm || !searchRanges.isEmpty
                // A word opens its card only when nothing else owns the tap: while a term is typed the
                // row's tap scrolls to (or clears) the match, and in multi-select it toggles the row.
                // Nor while Test Mode hides the ayah: the tap is the reveal, and a card would be the answer.
                let wordTapsAllowed = !isSelecting && !hasTerm && !testHidesRecitation
                // On a matched row the accent spans win over tajweed (the snippet's priority).
                let wordPreStyled = searchActive ? nil : preStyled
                if let glosses = wordByWordGlosses(displayText: arabicSource, beginner: beginner) {
                    // The card opens from a word only with "Tap a Word for Its Meaning" on; the
                    // study layout below still draws its glosses without it.
                    let selectWord: ((Int) -> Void)? = settings.wordByWordMeanings && wordTapsAllowed ? { index in
                        WordCardTrace.stamp("request")
                        requestSheet(.word(TappedWord(
                            index: index,
                            word: WordTokens.tokens(in: arabicSource)[index],
                            meaning: glosses[index],
                            total: glosses.count
                        )))
                    } : nil
                    if choices.wordByWord {
                        // The study layout: each word a column with its meaning beneath it. Tapping
                        // still opens the same word card.
                        WordByWordInlineText(
                            displayText: arabicSource,
                            preStyled: wordPreStyled,
                            fontName: useSystemArabic
                                ? nil
                                : ayahArabicFontName(for: comparisonQiraahOverride ?? settings.displayQiraahForArabic),
                            fontSize: CGFloat(settings.fontArabicSize),
                            ayahNumberArabic: ayah.idArabic,
                            glosses: glosses,
                            highlightAllahNames: choices.highlightAllah,
                            showsGlosses: settings.wordByWordInlineTranslation,
                            transliterations: wordByWordTransliterations(displayText: arabicSource),
                            selectedWord: openWordIndex,
                            onSelectWord: selectWord,
                            searchPaint: searchActive
                                ? WordByWordSearchPaint(
                                    arabicRanges: searchRanges,
                                    normalizedQuery: HighlightedSnippet.normalizeForSearchText(highlightQuery, trimWhitespace: true)
                                )
                                : nil
                        )
                        .id(tajweedAnimationKey)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        // Same text, same colors - rendered through TextKit so a single word can be
                        // tapped. `wordByWordGlosses` returns glosses only with one of the two word
                        // switches on, so with the study layout off the tap switch is the one that is
                        // on and `selectWord` is set; the fallback closure is never reached.
                        WordByWordText(
                            displayText: arabicSource,
                            preStyled: wordPreStyled,
                            fontName: useSystemArabic
                                ? nil
                                : ayahArabicFontName(for: comparisonQiraahOverride ?? settings.displayQiraahForArabic),
                            fontSize: CGFloat(settings.fontArabicSize),
                            ayahNumberArabic: ayah.idArabic,
                            glosses: glosses,
                            highlightAllahNames: choices.highlightAllah,
                            highlightRanges: searchRanges,
                            selectedWord: openWordIndex,
                            onSelectWord: selectWord ?? { _ in }
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
                                requestSheet(.word(TappedWord(
                                    index: idx, word: tokens[idx], meaning: glosses[idx], total: glosses.count
                                )))
                            }
                        }
                    #endif

                } else if let riwayahTag = riwayahWordTapTag(beginner: beginner) {
                    // Non-Hafs word tap: same tappable TextKit rendering, no glosses - the tap opens
                    // the riwayah word card (this riwayah's rules + the Hafs counterpart) instead.
                    WordByWordText(
                        displayText: arabicSource,
                        preStyled: wordPreStyled,
                        fontName: useSystemArabic
                            ? nil
                            : ayahArabicFontName(for: comparisonQiraahOverride ?? settings.displayQiraahForArabic),
                        fontSize: CGFloat(settings.fontArabicSize),
                        ayahNumberArabic: ayah.idArabic,
                        glosses: [],
                        alwaysTappable: true,
                        highlightAllahNames: choices.highlightAllah,
                        highlightRanges: searchRanges,
                        selectedWord: openRiwayahWordIndex,
                        onSelectWord: { index in
                            guard wordTapsAllowed else { return }
                            let tokens = WordTokens.tokens(in: arabicSource)
                            guard tokens.indices.contains(index) else { return }
                            requestSheet(.riwayahWord(RiwayahTappedWord(
                                index: index,
                                word: tokens[index],
                                total: tokens.count,
                                tag: riwayahTag
                            )))
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
                                    requestSheet(.riwayahWord(RiwayahTappedWord(
                                        index: idx, word: tokens[idx], total: tokens.count, tag: riwayahTag
                                    )))
                                }
                            }
                        }
                        if Self.debugOpenComparison {
                            Self.debugOpenComparison = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                requestSheet(.secondary(.qiraah))
                            }
                        }
                        if let kind = Self.debugOpenSecondary {
                            Self.debugOpenSecondary = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                requestSheet(.secondary(kind))
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
            }
            .quranTestVeiledIfAvailable(testHidesRecitation)

            if showTranslit {
                let txt = prefixOnTranslit ? "\(ayah.id). \(ayah.textTransliteration)" : ayah.textTransliteration
                HighlightedSnippet(
                    source: txt,
                    term: highlightQuery,
                    font: .system(size: fontSizeEN),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    highlightAllahNames: choices.highlightAllah,
                    guaranteeMatch: matchedTranslit
                )
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)
                // English content reads left to right in the Arabic interface too (this and the two
                // translations below).
                .leftToRightContent()
                .quranTestVeiledIfAvailable(testHidesRecitation)
            }

            if showEnglishSaheeh {
                let prefix = prefixOnSaheeh ? "\(ayah.id). " : ""
                let txt = prefix + ayah.textEnglishSaheeh
                VStack(alignment: .leading, spacing: 2) {
                    HighlightedSnippet(
                        source: txt,
                        term: highlightQuery,
                        font: .system(size: fontSizeEN),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        highlightAllahNames: choices.highlightAllah,
                        guaranteeMatch: matchedSaheeh,
                        extraHighlightRanges: Self.offsetSpans(crossSaheeh, by: (prefix as NSString).length)
                    )
                    // The translation's name tells two apart; with the default alone on screen, Simple
                    // Mode drops it.
                    // Verbatim: the caption names the English text it sits under, inside its
                    // left-to-right block; translated, it read as Arabic hugging the left edge.
                    if !settings.hides(.translationCaption, unless: showEnglishMustafa) {
                        Text(verbatim: "Saheeh International")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)
                .leftToRightContent()
                .quranTestVeiledIfAvailable(testHidesEverything)
            }

            if showEnglishMustafa {
                let prefix = prefixOnMustafa ? "\(ayah.id). " : ""
                let txt = prefix + ayah.textEnglishMustafa
                VStack(alignment: .leading, spacing: 2) {
                    HighlightedSnippet(
                        source: txt,
                        term: highlightQuery,
                        font: .system(size: fontSizeEN),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        highlightAllahNames: choices.highlightAllah,
                        guaranteeMatch: matchedMustafa,
                        extraHighlightRanges: Self.offsetSpans(crossMustafa, by: (prefix as NSString).length)
                    )
                    // Always named, Simple Mode or not: it is the translation someone chose over the
                    // default, so the screen says which one it is (Docs/Product/Simple Mode Guide.md, rule 2).
                    Text(verbatim: "Clear Quran (Mustafa Khattab)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)
                .leftToRightContent()
                .quranTestVeiledIfAvailable(testHidesEverything)
            }
        }
        .lineLimit(nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
        .padding(.bottom, 2)
        // No `.textSelection(.enabled)` here (it was, since 4.5.0): inside a List it gives only a
        // whole-block Copy/Share on long press, and that long press won over the row's own, so
        // holding the translation showed Copy/Share instead of the ayah actions sheet (Abu,
        // 2026-09-04). Copy and Share live in that sheet and in the ellipsis menu.
        .onAppear { onAyahTextAppear?() }
        .onDisappear { onAyahTextDisappear?() }
    }

    /// Bookmarks the ayah, or asks before removing the bookmark (`Settings.toggleBookmarkOrConfirm`).
    private func toggleBookmarkOrConfirm() {
        settings.toggleBookmarkOrConfirm(surah: surah.id, ayah: ayah.id)
    }

    #if os(iOS)
    /// The ayah's playback actions: the ▶ button's menu, flat (Abu, 2026-10-21: "organize all menus...
    /// if need be put menus in menus"; since 2026-10-23 the ⋯ menu no longer repeats them as a Play
    /// Ayah submenu). Play This Ayah sits at the visual bottom, the primary action nearest the thumb, as
    /// Play Surah does in the surah menus. Play Custom Range appears once: it used to end the Repeat
    /// submenu as well. Choose Reciter leads, as in the Quran tab's Ayah Playback submenu and the actions
    /// sheet's reciter row (Abu, 2026-10-25); the host presents the list (`AyahSecondarySheet.reciter`).
    @ViewBuilder
    private func ayahPlaybackItems() -> some View {
        Button {
            settings.hapticFeedback()
            requestSheet(.secondary(.reciter))
        } label: {
            ChooseReciterMenuLabel()
        }

        Divider()

        Menu {
            Text("Repeat Count")
                .foregroundStyle(.secondary)

            ForEach([2, 3, 5, 10, 15, 20], id: \.self) { count in
                Button {
                    settings.hapticFeedback()
                    quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: count)
                } label: {
                    Label("Repeat \(count)×", systemImage: "\(count).circle")
                }
            }

            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: QuranPlayer.infiniteRepeat)
            } label: {
                Label("Repeat Forever", systemImage: "infinity")
            }
        } label: {
            Label("Repeat Ayah", systemImage: "repeat")
        }

        Button {
            settings.hapticFeedback()
            requestSheet(.secondary(.customRange))
        } label: {
            Label("Play Custom Range", systemImage: "slider.horizontal.3")
        }

        Menu {
            ayahPlayFromMenuItems(surah: surah.id, ayah: ayah.id, settings: settings,
                                  quranPlayer: quranPlayer)
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

    /// Add Note on its own; once a note is saved, one Note submenu holds Edit and Remove instead of
    /// two rows (the ⋯ menu's row budget, 2026-10-21).
    @ViewBuilder
    private func noteMenuItems(isBookmarked: Bool) -> some View {
        if currentNote.isEmpty {
            Button {
                settings.hapticFeedback()
                if !isBookmarked {
                    settings.ensureBookmarkExists(surah: surah.id, ayah: ayah.id)
                }
                requestSheet(.secondary(.note))
            } label: {
                Label("Add Note", systemImage: "note.text")
            }
        } else {
            Menu {
                Button {
                    settings.hapticFeedback()
                    requestSheet(.secondary(.note))
                } label: {
                    Label("Edit Note", systemImage: "note.text")
                }

                Button(role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        removeNote()
                    }
                } label: {
                    Label("Remove Note", systemImage: "minus.circle")
                }
            } label: {
                Label("Note", systemImage: "note.text")
            }
        }
    }

    /// The deeper study of the ayah as one submenu: the repeated phrases, the two comparisons and
    /// the AI summary. See Tafsir stays outside it, the study action a reader reaches for most
    /// (Simple Mode's five). Nothing when none of them applies.
    @ViewBuilder
    private func studyMenu(canShowTafsir: Bool) -> some View {
        // Similar Ayahs and Mutashabihat read against the Hafs text like the tafsir, and show whenever
        // the pack is bundled (probing THIS ayah would parse 4.5 MB of JSON on menu open; the sheet
        // handles the no-matches case).
        let similar = canShowTafsir && SimilarAyahsStore.isBundled
        let mutashabihat = canShowTafsir && MutashabihatStore.isBundled
        let qiraah = settings.showQiraahDetails
        let translation = canCompareEnglishText
        // Hidden without Apple Intelligence rather than present and dead (the OnDeviceAsk pattern).
        let summarize = canShowTafsir && AyahSummarizeSheet.isOffered

        if similar || mutashabihat || qiraah || translation || summarize {
            Menu {
                if similar {
                    Button {
                        settings.hapticFeedback()
                        requestSheet(.secondary(.similarAyahs))
                    } label: {
                        Label("Similar Ayahs", systemImage: "doc.text.magnifyingglass")
                    }
                }

                if mutashabihat {
                    Button {
                        settings.hapticFeedback()
                        requestSheet(.secondary(.mutashabihat))
                    } label: {
                        Label("Mutashabihat", systemImage: "text.quote")
                    }
                }

                if (similar || mutashabihat) && (qiraah || translation) {
                    Divider()
                }

                if qiraah {
                    Button {
                        settings.hapticFeedback()
                        requestSheet(.secondary(.qiraah))
                    } label: {
                        Label("Qiraah Comparison", systemImage: "character.book.closed.fill.ar")
                    }
                }

                if translation {
                    Button {
                        settings.hapticFeedback()
                        requestSheet(.secondary(.translations))
                    } label: {
                        Label("Translation Comparison", systemImage: "character.book.closed")
                    }
                }

                if summarize {
                    Divider()

                    Button {
                        settings.hapticFeedback()
                        requestSheet(.secondary(.summarize))
                    } label: {
                        Label("Summarize with AI", systemImage: "text.append")
                    }
                }
            } label: {
                Label("Study Ayah", systemImage: "books.vertical")
            }
        }
    }
    #endif

    /// Simple Mode's ayah menu (Docs/Product/Simple Mode Guide.md): the five actions a reader reaches for, then
    /// More Actions, which opens the long-press sheet holding every action there is. Each item is the
    /// full menu's own action, so the two can never drift in what a tap does.
    @ViewBuilder
    private func simpleMenuBlock(isBookmarked: Bool) -> some View {
        #if os(iOS)
        let canShowTafsir: Bool = {
            if let override = comparisonQiraahOverride {
                return override.isEmpty || override == "Hafs"
            }
            return settings.isHafsDisplay
        }()

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

        // Ayah audio is Hafs-numbered, so playback follows the play menu's own gate.
        if settings.isHafsDisplay {
            Button {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
            } label: {
                Label("Play This Ayah", systemImage: "play.circle")
            }
        }

        Button(role: isBookmarked ? .destructive : nil) {
            settings.hapticFeedback()
            toggleBookmarkOrConfirm()
        } label: {
            Label(
                isBookmarked ? "Unbookmark Ayah" : "Bookmark Ayah",
                systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
            )
        }

        if canShowTafsir {
            Button {
                settings.hapticFeedback()
                requestSheet(.secondary(.tafsir))
            } label: {
                Label("See Tafsir", systemImage: "text.book.closed")
            }
        }

        Button {
            settings.hapticFeedback()
            ShareAyahSheet.copyAyahToPasteboard(surahNumber: surah.id, ayahNumber: ayah.id, settings: settings, quranData: quranData)
        } label: {
            Label("Copy Ayah", systemImage: "doc.on.doc")
        }

        Button {
            settings.hapticFeedback()
            requestSheet(.secondary(.share))
        } label: {
            Label("Share Ayah", systemImage: "square.and.arrow.up")
        }

        Divider()

        Button {
            settings.hapticFeedback()
            requestSheet(.actions)
        } label: {
            Label("More Actions\u{2026}", systemImage: "ellipsis.circle")
        }
        #endif
    }

    /// The full ⋯ menu: ten rows at most, in four groups (Abu, 2026-10-21: "organize all menus and
    /// context menus... make sure not too long if need be put menus in menus"; it was sixteen). Mark
    /// (bookmark, highlight, note), study (tafsir, the Study Ayah submenu, the per-ayah settings),
    /// and text (select, copy, share); playback is the ▶ button beside the menu. The Quran tab's ayah
    /// menu (`AyahContextMenuModifier`) is this list block for block (user rule 2026-09-05), plus the
    /// surah, Play This Ayah and an Ayah Playback submenu, since no ▶ sits beside a Quran tab row.
    @ViewBuilder
    private func menuBlock(isBookmarked: Bool) -> some View {
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
                toggleBookmarkOrConfirm()
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

            noteMenuItems(isBookmarked: isBookmarked)

            Divider()

            if canShowTafsir {
                Button {
                    settings.hapticFeedback()
                    requestSheet(.secondary(.tafsir))
                } label: {
                    Label("See Tafsir", systemImage: "text.book.closed")
                }
            }

            studyMenu(canShowTafsir: canShowTafsir)

            // Was a per-ayah "Beginner Mode" toggle: now the whole "Apply Settings" menu (Abu,
            // 2026-09-05) - beginner spacing, tajweed, tashkeel, dots, Highlight Allah, word by word,
            // several at once, pinned to THIS ayah, with a reset when it differs from the app.
            if settings.showArabicText {
                Menu {
                    ayahDisplayMenuItems(refs: [HighlightedAyahRef(surahID: surah.id, ayahID: ayah.id)],
                                         settings: settings, offersWordByWord: true)
                } label: {
                    Label("Apply Settings", systemImage: "slider.horizontal.3")
                }
            }

            Divider()

            Button {
                settings.hapticFeedback()
                requestSheet(.secondary(.selectText))
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
                requestSheet(.secondary(.share))
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

private extension View {
    /// Test Mode's veil (`quranTestVeiled`) on iOS. The watch has no Test Mode and draws the line as is.
    @ViewBuilder
    func quranTestVeiledIfAvailable(_ hidden: Bool) -> some View {
        #if os(iOS)
        quranTestVeiled(hidden)
        #else
        self
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

private extension EdgeInsets {
    /// The same insets pulled in instead of pushed out.
    var negated: EdgeInsets {
        EdgeInsets(top: -top, leading: -leading, bottom: -bottom, trailing: -trailing)
    }
}
