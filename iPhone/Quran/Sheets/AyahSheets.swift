import SwiftUI
import UIKit

#if os(iOS)

enum AyahSecondarySheet: String, Identifiable {
    case tafsir, similarAyahs, mutashabihat, qiraah, translations, customRange, note, share, selectText
    /// "Summarize with AI" on the ayah itself (2026-09-21, parity with the hadith rows, which had it
    /// on their menu while the ayah offered it only inside the tafsir and comparison sheets).
    case summarize
    /// The reciter list, for the reader row's ▶ menu (Choose Reciter at its top, as in the Quran tab's
    /// Ayah Playback submenu). The actions sheet opens its own copy on top of itself instead, so picking a
    /// voice never closes the sheet you were about to play from.
    case reciter
    var id: String { rawValue }
}

/// The channel the "Keep Sheet Open" setting uses (Abu, 2026-09-19).
///
/// With the setting ON, a secondary sheet is presented BY the actions sheet rather than by the
/// reader that hosts it: SwiftUI silently drops a `.sheet` raised from a view whose own sheet is
/// already up, so the reader cannot stack one itself. The reader therefore posts the request here
/// and `AyahActionsSheet` - which is on screen and free to present - picks it up.
///
/// A singleton rather than a binding because the request crosses from the reader's `presentRowSheet`
/// into a sheet body it does not own; there is at most one ayah actions sheet up at a time, so one
/// slot is enough.
@MainActor
final class AyahSheetStack: ObservableObject {
    static let shared = AyahSheetStack()
    private init() {}

    /// The sheet the actions sheet should stack on top of itself, cleared when it closes.
    @Published var pending: AyahSecondarySheet?
    /// Set by a stacked range sheet that played a range wider than the actions sheet's own ayah
    /// (2026-10-31), or by a stacked Share Ayah sheet that copied or shared (2026-11-04): the actions
    /// sheet reads it when `pending` clears and closes itself too.
    var closeHostWhenCleared = false

    func present(_ sheet: AyahSecondarySheet) {
        pending = sheet
    }
}

/// One of the sheets an ayah row asks its host to present (Phase 5 step 6). A list row used to carry
/// twelve presentation modifiers of its own, ~100-150 presentation hosts churned per screenful of
/// scrolling; `SurahView` hosts ONE `.sheet(item:)` now and the rows route requests through
/// `AyahRow.onRequestSheet`, the way the page reader already did with `SecondarySheetRequest`.
enum AyahRowSheetKind: Equatable {
    /// The long-press actions sheet (`AyahActionsSheet`).
    case actions
    case secondary(AyahSecondarySheet)
    /// The word-by-word meaning card.
    case word(TappedWord)
    /// The riwayah word card (non-Hafs word tap).
    case riwayahWord(RiwayahTappedWord)
}

struct AyahRowSheetRequest: Identifiable {
    let surah: Surah
    let ayah: Ayah
    let kind: AyahRowSheetKind
    /// Whether the ACTIONS sheet opens at the large detent, decided here, ONCE, as the request is made:
    /// the decision measures the ayah card (`AyahActionsSheet.opensLarge(surah:ayah:)`), and the host's
    /// body, which presents the sheet, re-evaluates on every reader change while the sheet is up.
    /// False for every other kind (they open medium, or set their own detents).
    let opensLarge: Bool

    init(surah: Surah, ayah: Ayah, kind: AyahRowSheetKind) {
        self.surah = surah
        self.ayah = ayah
        self.kind = kind
        if case .actions = kind {
            opensLarge = AyahActionsSheet.opensLarge(surah: surah, ayah: ayah)
        } else {
            opensLarge = false
        }
    }

    var id: String {
        let kindKey: String
        switch kind {
        case .actions: kindKey = "actions"
        case .secondary(let sheet): kindKey = sheet.rawValue
        case .word(let tapped): kindKey = "word\(tapped.index)"
        case .riwayahWord(let tapped): kindKey = "rword\(tapped.index)"
        }
        return "\(surah.id):\(ayah.id):\(kindKey)"
    }
}

/// The body of a row-sheet host: every sheet a list row can ask for, built from the request.
struct AyahRowSheetContent: View {
    private let settings = Settings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var quranData = QuranData.shared
    private var quranPlayer: QuranPlayer { .shared }

    let request: AyahRowSheetRequest
    /// The actions sheet asked for another sheet: the host closes this one first, then presents it.
    let onRequestSecondary: (AyahSecondarySheet) -> Void
    let onDismiss: () -> Void

    init(request: AyahRowSheetRequest,
         onRequestSecondary: @escaping (AyahSecondarySheet) -> Void,
         onDismiss: @escaping () -> Void) {
        self.request = request
        self.onRequestSecondary = onRequestSecondary
        self.onDismiss = onDismiss
    }

    var body: some View {
        let surah = request.surah
        let ayah = request.ayah

        Group {
            switch request.kind {
            case .actions:
                // The list reader can draw the inline study layout, so its actions sheet offers the
                // per-ayah "Word by Word" pin; the page reader's cannot. One host serves both readers
                // now (the page reader routes its sheets here too), so the mode decides.
                AyahActionsSheet(surah: surah, ayah: ayah, onRequestSheet: onRequestSecondary,
                                 offersWordByWord: !settings.quranPageMode, opensLarge: request.opensLarge)
                    .smallMediumSheetPresentation(startLarge: request.opensLarge)

            case .word(let tapped):
                WordMeaningSheet(
                    surah: surah,
                    ayah: ayah,
                    word: tapped.word,
                    meaning: tapped.meaning,
                    position: tapped.index + 1,
                    total: tapped.total
                )
                .environmentObject(settings)

            case .riwayahWord(let tapped):
                RiwayahWordSheet(
                    surah: surah,
                    ayah: ayah,
                    tag: tapped.tag,
                    word: tapped.word,
                    index: tapped.index,
                    total: tapped.total
                )
                .environmentObject(settings)

            case .secondary(let kind):
                if kind == .customRange {
                    // The range sheet carries its own detents (it opens at full height).
                    secondary(kind, surah: surah, ayah: ayah)
                } else {
                    secondary(kind, surah: surah, ayah: ayah)
                        .smallMediumSheetPresentation()
                }
            }
        }
    }

    @ViewBuilder
    private func secondary(_ kind: AyahSecondarySheet, surah: Surah, ayah: Ayah) -> some View {
        AyahSecondarySheetContent(kind: kind, surah: surah, ayah: ayah, onDismiss: onDismiss)
    }
}

/// One secondary sheet's body, built from its kind. Extracted from `AyahRowSheetContent` so the
/// actions sheet can present the SAME sheet on top of itself when "Keep Sheet Open" is on
/// (Abu, 2026-09-19) - one builder, so the stacked copy can never drift from the swapped one.
struct AyahSecondarySheetContent: View {
    private let settings = Settings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var quranData = QuranData.shared
    private var quranPlayer: QuranPlayer { .shared }

    let kind: AyahSecondarySheet
    let surah: Surah
    let ayah: Ayah
    let onDismiss: () -> Void

    var body: some View {
        content
    }

    @ViewBuilder
    private var content: some View {
        switch kind {
        case .tafsir:
            AyahTafsirSheet(surahName: surah.nameTransliteration, surahNumber: surah.id, ayahNumber: ayah.id)

        case .similarAyahs:
            SimilarAyahsSheet(surahNumber: surah.id, ayahNumber: ayah.id)

        case .mutashabihat:
            SimilarAyahsSheet(surahNumber: surah.id, ayahNumber: ayah.id, initialTab: .phrases)

        case .qiraah:
            AyahQiraahComparisonSheet(surahNumber: surah.id, ayahNumber: ayah.id)
                .environmentObject(settings)
                .environmentObject(quranData)

        case .translations:
            AyahEnglishComparisonSheet(surahNumber: surah.id, ayahNumber: ayah.id)
                .environmentObject(settings)
                .environmentObject(quranData)

        case .customRange:
            PlayCustomRangeSheet(
                surah: surah,
                initialStartAyah: ayah.id,
                initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                    startAyah: ayah.id,
                    surah: surah,
                    displayQiraah: settings.displayQiraahForArabic
                ),
                onPlay: { selection in
                    quranPlayer.playCustomRange(selection)
                    // Keep Sheet Open While Playing holds the actions sheet under this one only for a
                    // range of ITS ayah alone (Abu, 2026-10-31: "it's nice seeing the ayah nice and big
                    // but it's annoying when the ayah changes, so if many ayahs then dismiss"). Any
                    // wider range, or a Recent Ranges row, closes the actions sheet once this one is down.
                    if AyahSheetStack.shared.pending == .customRange,
                       !(settings.keepAyahSheetOpenOnPlay && selection.isOnly(surah: surah.id, ayah: ayah.id)) {
                        AyahSheetStack.shared.closeHostWhenCleared = true
                    }
                    onDismiss()
                },
                onCancel: { onDismiss() }
            )
            .environmentObject(settings)

        case .note:
            AyahNoteSheet(surah: surah, ayah: ayah)

        case .share:
            // Stacked on the actions sheet (Keep Sheet Open), a copy or a completed share closes that
            // sheet too once this one is down (Abu, 2026-11-04: "why doesn't share ayah collapse the
            // ayah sheet"): sharing is what the ayah was opened for. A cancel or the X still lands
            // back on the actions.
            ShareAyahSheet(surahNumber: surah.id, ayahNumber: ayah.id, onShared: {
                if AyahSheetStack.shared.pending == .share {
                    AyahSheetStack.shared.closeHostWhenCleared = true
                }
            })

        case .selectText:
            SelectAyahTextSheet(surah: surah, ayah: ayah)

        case .summarize:
            AyahSummarizeSheet(surahNumber: surah.id, ayahNumber: ayah.id)

        case .reciter:
            // The picker the Tafsir sheet and the Quran tab open (`ReciterPickerSheet`), with this
            // host's detents: picking a reciter closes it.
            SheetNavigationContainer {
                ReciterListView(dismissAfterSelectingReciter: true)
                    .environmentObject(settings)
                    .sheetDismissToolbar()
            }
        }
    }
}

/// The ayah's own "Summarize with AI" sheet: the model reads all three families for the ayah (the
/// bundled tafsirs first, then the riwayat and the translations - `AyahAISources`), the same
/// gathering the tafsir sheet's sparkles button does, reached from the row instead. One builder for
/// the row menu, the tab rows' menu and the actions sheet, so none of the three can drift.
struct AyahSummarizeSheet: View {
    let surahNumber: Int
    let ayahNumber: Int

    var body: some View {
        #if canImport(FoundationModels)
        SummarizeSheet(
            title: "\(AyahAISources.combinedTitlePrefix) of \(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber, english: true))",
            displayTitle: AyahAISources.combinedDisplayTitle(of: ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber)),
            sourceText: "",
            multiSource: true,
            gatherSource: {
                let anchor = AyahAISources.hafsAnchor(surahNumber: surahNumber, ayahNumber: ayahNumber)
                let online = await AyahAISources.fetchOnlineTranslations(surahNumber: surahNumber, hafsAyah: anchor)
                return OnDeviceAsk.combinedSource(
                    AyahAISources.combinedSections(
                        surahNumber: surahNumber,
                        ayahNumber: ayahNumber,
                        emphasis: .tafsir,
                        onlineTranslations: online
                    )
                )
            },
            excludedNote: AyahAISources.arabicExcludedNote
        )
        #else
        EmptyView()
        #endif
    }

    /// Whether the entry points should offer the sheet at all: Apple Intelligence on, and a Hafs
    /// reading (the tafsirs and translations are Hafs-keyed; the anchor covers the other riwayat's
    /// numbering, but a beta text's words may not be the ones the sources discuss).
    static var isOffered: Bool {
        #if canImport(FoundationModels)
        return OnDeviceAsk.isAvailable
        #else
        return false
        #endif
    }
}

/// The note editor plus the draft it edits. A small view of its own so the *parent* can present the editor
/// without owning the draft text and the profanity check.
struct AyahNoteSheet: View {
    private let settings = Settings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    let surah: Surah
    let ayah: Ayah

    @State private var draftNote = ""
    @State private var showRespectAlert = false

    private func isNoteAllowed(_ text: String) -> Bool {
        !textContainsProfanity(text)
    }

    var body: some View {
        NoteEditorSheet(
            title: String(localized: "Note for \(surah.displayName) \(surah.id):\(ayah.id)"),
            text: $draftNote,
            onAttemptSave: { text in
                if isNoteAllowed(text) {
                    settings.setBookmarkNote(surah: surah.id, ayah: ayah.id, note: text)
                    return true
                } else {
                    showRespectAlert = true
                    return false
                }
            },
            onCancel: {},
            onSave: { settings.setBookmarkNote(surah: surah.id, ayah: ayah.id, note: draftNote) }
        )
        .onAppear { draftNote = settings.bookmarkNoteText(surah: surah.id, ayah: ayah.id) }
        .confirmationDialog("Note not saved", isPresented: $showRespectAlert, titleVisibility: .visible) {
            Button("OK") {}
        } message: {
            Text("Please keep notes Islamic and respectful.")
        }
    }
}

/// The "here is the ayah you touched" card, shared by the page actions sheet and the tafsir sheet (Abu,
/// 2026-09-05: "make it use the same exact code ... so it looks and acts the exact same"): the ayah(s) in
/// the reader's own rendering - the Quran face, tajweed colors, tashkeel / dots choices, beginner spacing
/// and the ayah's own pins - as ONE continuous run with inline number markers, every word opening its
/// card on a SINGLE tap, a plain-text toggle, the reference caption, the translation, and any notes. A
/// tafsir group hands in several ayahs; the actions sheet hands in one.
struct AyahPreviewCard: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var displayOverrides = AyahDisplayOverrides.shared

    let surah: Surah
    let ayahs: [Ayah]
    /// The minus | % | plus size stepper. The tafsir sheet's card turns it off (Abu, 2026-10-22: "for
    /// tafsir dont have + or -"); the card still draws at the remembered scale, so the two sheets match.
    var showsSizeStepper: Bool = true
    /// A size of its own instead of the remembered `ayahPreviewCardScale`. The tafsir sheet pins 0.8
    /// (Abu, 2026-10-28: "for tafsir for the ayah it is so big make it like 80% and make it fixed"):
    /// the card there sits above pages of commentary, and the actions sheet's stepper at 145% made it
    /// fill the screen. With a fixed scale the stepper never shows.
    var fixedScale: Double? = nil

    /// Show the ayah as PLAIN standard text - full tashkeel and dots, no tajweed coloring, no Allah
    /// highlight, no beginner spacing - while the reader has any of those shaping it (user rule).
    /// Card-local; the reader keeps its own. The Allah highlight joined the list on 2026-09-16 (Abu:
    /// "choosing plain text ... doesn't get rid of highlight Allah").
    #if DEBUG
    /// "-previewPlainText" opens the card already in plain text (the toggle is not tappable headlessly).
    @State private var showPlainText = ProcessInfo.processInfo.arguments.contains("-previewPlainText")
    #else
    @State private var showPlainText = false
    #endif

    /// The tapped word's card (the Hafs gloss + tajweed-rules card, or the riwayah word card), presented
    /// OVER the sheet this card sits in, so closing it returns here. `item:` so tapping a different word
    /// re-presents with the new word.
    @State private var tappedWord: PreviewTappedWord?
    @State private var tappedRiwayahWord: PreviewTappedRiwayahWord?

    private struct PreviewTappedWord: Identifiable {
        let segment: Int
        let ayah: Ayah
        let index: Int
        let word: String
        let meaning: String
        let total: Int
        var id: String { "\(ayah.id).\(index)" }
    }

    private struct PreviewTappedRiwayahWord: Identifiable {
        let segment: Int
        let ayah: Ayah
        let index: Int
        let word: String
        let total: Int
        let tag: String
        var id: String { "\(ayah.id).\(index)" }
    }

    /// One ayah's rendering inputs, resolved once per body pass.
    private struct Piece {
        let ayah: Ayah
        let segment: WordByWordSegment
        let glosses: [String]
        /// Non-Hafs: the riwayah whose word card a tapped word opens (its pack is bundled).
        let riwayahWordTag: String?
        /// Whether the reader's choices shape this ayah at all - the plain-text button appears when
        /// there is something to undo.
        let modified: Bool
    }

    /// Non-Hafs: a tapped word opens the riwayah word card instead (its rules + the Hafs counterpart) -
    /// same rule as the list rows, only when the riwayah's pack is bundled.
    private var riwayahWordTag: String? {
        guard !settings.isHafsDisplay else { return nil }
        let tag = Settings.Riwayah.canonicalTag(settings.displayQiraahForArabic ?? "")
        return !tag.isEmpty && QiraahTajweedStore.shared.isAvailable(tag: tag) ? tag : nil
    }

    /// `plain`: the card's plain-text switch (`showPlainText`), or false for a measurement made before
    /// the card exists (`estimatedHeight`).
    private func piece(for ayah: Ayah, plain: Bool) -> Piece {
        let choices = displayOverrides.choices(surah: surah.id, ayah: ayah.id, settings: settings)
        let clean = choices.hideTashkeel && !plain
        let dots = choices.hideDots && !plain
        let beginner = choices.beginner && !plain
        let qiraah = settings.displayQiraahForArabic
        let raw = ayah.rawArabicText(surahId: surah.id, qiraahOverride: qiraah)
        let base = ayah.displayArabicText(surahId: surah.id, clean: clean, removeDots: dots, qiraahOverride: qiraah)
        let display = beginner ? base.beginnerSpaced : base

        let tajweedOn = !plain && choices.tajweed && settings.showArabicText
        let hafsTajweed = tajweedOn && settings.isHafsDisplay
        let riwayahTajweedTag = tajweedOn ? settings.riwayahTajweedPackTag : nil

        // The tajweed-colored run, when either store paints this ayah.
        let preStyled: AttributedString? = {
            if hafsTajweed,
               let styled = TajweedStore.shared.attributedText(
                   surah: surah.id, ayah: ayah.id, text: raw, displayText: display,
                   cleanDisplayText: clean, beginnerSpacing: beginner, removeArabicDots: dots
               ) {
                return styled
            }
            if let tag = riwayahTajweedTag,
               let styled = QiraahTajweedStore.shared.attributedText(
                   tag: tag, surah: surah.id, ayah: ayah.id, displayText: display,
                   beginnerSpacing: beginner,
                   hiddenRules: settings.riwayahTajweedHiddenRuleSet,
                   fullText: clean ? (beginner ? raw.beginnerSpaced : raw) : nil
               ) {
                return styled
            }
            return nil
        }()

        // Hafs: glosses lined up with the run's tokens, so a tapped word opens the same meaning +
        // tajweed card the list rows offer. Empty (but still tappable) when the pack can't line up -
        // the card then shows the word's rules without a gloss. Beginner spacing splits every letter
        // into a token, so no word can be trusted there (the reader rows opt out the same way).
        let glosses: [String] = settings.isHafsDisplay && !beginner
            ? (WordByWordStore.shared.glosses(
                surah: surah.id, ayah: ayah.id,
                rawText: ayah.rawArabicText(surahId: surah.id, qiraahOverride: nil),
                displayText: display
              ) ?? [])
            : []
        let wordTag = beginner ? nil : riwayahWordTag

        let tajweedCanPaint = settings.showArabicText
            && (settings.isHafsDisplay || settings.riwayahTajweedPackTag != nil)
        let modified = choices.hideTashkeel || choices.hideDots || choices.beginner
            || (choices.tajweed && tajweedCanPaint) || choices.highlightAllah

        return Piece(
            ayah: ayah,
            segment: WordByWordSegment(
                displayText: display,
                preStyled: preStyled,
                ayahNumberArabic: ayah.idArabic,
                glosses: glosses,
                alwaysTappable: (settings.isHafsDisplay && glosses.isEmpty && !beginner) || wordTag != nil,
                highlightAllahNames: choices.highlightAllah && !plain
            ),
            glosses: glosses,
            riwayahWordTag: wordTag,
            modified: modified
        )
    }

    private var selectedWord: WordByWordRef? {
        if let tappedWord { return WordByWordRef(segment: tappedWord.segment, index: tappedWord.index) }
        if let tappedRiwayahWord { return WordByWordRef(segment: tappedRiwayahWord.segment, index: tappedRiwayahWord.index) }
        return nil
    }

    private func select(_ ref: WordByWordRef, pieces: [Piece]) {
        guard pieces.indices.contains(ref.segment) else { return }
        let piece = pieces[ref.segment]
        let tokens = WordTokens.tokens(in: piece.segment.displayText)
        guard tokens.indices.contains(ref.index) else { return }
        if let tag = piece.riwayahWordTag {
            tappedRiwayahWord = PreviewTappedRiwayahWord(
                segment: ref.segment, ayah: piece.ayah, index: ref.index,
                word: tokens[ref.index], total: tokens.count, tag: tag
            )
        } else if settings.isHafsDisplay {
            tappedWord = PreviewTappedWord(
                segment: ref.segment, ayah: piece.ayah, index: ref.index,
                word: tokens[ref.index],
                meaning: piece.glosses.indices.contains(ref.index) ? piece.glosses[ref.index] : "",
                total: piece.glosses.isEmpty ? tokens.count : piece.glosses.count
            )
        }
    }

    /// The same reference format every ayah sheet uses; a group reads e.g. "Al-Baqarah 2:1-5".
    private var title: String? {
        guard let first = ayahs.first, let last = ayahs.last else { return nil }
        return ayahSheetTitle(surahNumber: surah.id, ayahNumber: first.id, endAyah: last.id > first.id ? last.id : nil)
    }

    /// The reference in the other language, at the far end of the same line (`ayahSheetCounterpartTitle`).
    private var counterpartTitle: String? {
        guard let first = ayahs.first, let last = ayahs.last else { return nil }
        return ayahSheetCounterpartTitle(surahNumber: surah.id, ayahNumber: first.id, endAyah: last.id > first.id ? last.id : nil)
    }

    private struct TranslationBlock: Identifiable {
        let name: String
        let text: String
        var id: String { name }
    }

    /// BOTH bundled translations of the card's ayahs, each joined into one paragraph (numbered inline
    /// when the group spans several), the reader's current one first (the precedence of
    /// `currentTranslationText(for:)`). Empty on a non-Hafs display, whose numbering they do not follow.
    private var translationBlocks: [TranslationBlock] {
        guard settings.isHafsDisplay else { return [] }
        let saheeh = TranslationBlock(name: "Saheeh International", text: joinedTranslation(\.textEnglishSaheeh))
        let mustafa = TranslationBlock(name: "Clear Quran (Mustafa Khattab)", text: joinedTranslation(\.textEnglishMustafa))
        let currentIsSaheeh = settings.showEnglishSaheeh || !settings.showEnglishMustafa
        return (currentIsSaheeh ? [saheeh, mustafa] : [mustafa, saheeh]).filter { !$0.text.isEmpty }
    }

    private func joinedTranslation(_ keyPath: KeyPath<Ayah, String>) -> String {
        ayahs.compactMap { ayah -> String? in
            let text = ayah[keyPath: keyPath].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            return ayahs.count > 1 ? "\(text) (\(ayah.id))" : text
        }.joined(separator: " ")
    }

    /// The card's Arabic size: the reader's own, clamped to what fits a sheet, times the remembered
    /// `ayahPreviewCardScale`. The clamp is applied BEFORE the scale so the multiplier always means
    /// the same thing whatever the reader is set to.
    private var cardFontSize: CGFloat {
        let base = min(max(CGFloat(settings.fontArabicSize), 20), 36)
        return (base * CGFloat(fixedScale ?? settings.ayahPreviewCardScale)).rounded()
    }

    /// The stepper only where the size is the reader's to change.
    private var showsStepper: Bool { showsSizeStepper && fixedScale == nil }

    /// The reference line and the translations under it. Also what `estimatedHeight` measures, hosted
    /// offscreen, so the estimate and the card can never disagree on a wrap.
    private func captionsBlock(title: String) -> some View {
        VStack(alignment: .leading, spacing: Self.captionSpacing) {
            // The reference both ways (Abu, 2026-10-26): the interface's name leading, the
            // other language's trailing, a spacer between them, as the reader's title pill
            // names the surah in both scripts.
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                Spacer(minLength: 8)
                if let counterpartTitle {
                    Text(counterpartTitle)
                }
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)

            ForEach(translationBlocks) { block in
                VStack(alignment: .leading, spacing: Self.translationNameSpacing) {
                    Text(block.name)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(settings.accentColor.accent1)

                    Text(block.text)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // An English translation under its English name: left to right in the Arabic interface.
                .leftToRightContent()
                .padding(.top, Self.translationTopPadding)
            }
        }
    }

    /// One bookmark note under its ayah, numbered when the card holds several. Measured by
    /// `estimatedHeight` the same way as the captions.
    private func noteRow(ayah: Ayah, note: String) -> some View {
        HStack(alignment: .top, spacing: Self.noteIconSpacing) {
            Image(systemName: "note.text")
                .font(.caption2)
                .foregroundStyle(settings.accentColor.accent1)
                .padding(.top, 1)

            Text(ayahs.count > 1 ? "\(String(ayah.id).localizedDigits). \(note)" : note)
                .font(.caption)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Self.noteHorizontalPadding)
        .padding(.vertical, Self.noteVerticalPadding)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(settings.accentColor.accent1.opacity(0.08))
        )
    }

    // MARK: Height before layout

    /// The card's chrome, named once so the body and `estimatedHeight` cannot drift apart.
    private static let rowSpacing: CGFloat = 6
    private static let horizontalPadding: CGFloat = 12
    private static let verticalPadding: CGFloat = 10
    private static let stepperButtonSize: CGFloat = 26
    private static let captionSpacing: CGFloat = 3
    private static let translationTopPadding: CGFloat = 2
    private static let translationNameSpacing: CGFloat = 1
    private static let noteIconSpacing: CGFloat = 6
    private static let noteHorizontalPadding: CGFloat = 10
    private static let noteVerticalPadding: CGFloat = 8

    /// The card's height at `width` BEFORE it is on screen, for the ayah actions sheet's opening detent
    /// (`AyahActionsSheet.opensLarge(surah:ayah:)`). The Arabic run is measured for real
    /// (`WordByWordText.measuredHeight`: the TextKit layout the card draws, at the same width and
    /// size); the captions and the notes are the body's own views laid out offscreen; the chrome is
    /// the body's own numbers above, each used by the modifier it stands for. Plain text off, as a
    /// fresh card opens. `-ayahSheetFitLog` prints the estimate beside the laid-out height to check it
    /// (2026-11-09, three simulators: the run and the card matched to the point).
    func estimatedHeight(width: CGFloat) -> CGFloat {
        let inner = width - 2 * Self.horizontalPadding
        guard inner > 0 else { return 0 }
        let pieces = ayahs.map { piece(for: $0, plain: false) }
        var rows: [(String, CGFloat)] = []

        if showsStepper || pieces.contains(where: \.modified) {
            rows.append(("stepper", Self.stepperButtonSize))
        }

        if pieces.isEmpty {
            rows.append(("unavailable", Self.lineHeight(.subheadline)))
        } else {
            let run = WordByWordText(
                segments: pieces.map(\.segment),
                fontName: settings.quranDisplayUsesCustomArabicFace ? settings.quranDisplayFontName : nil,
                fontSize: cardFontSize,
                tapsRequired: 1,
                selectable: true,
                selectedWord: nil,
                onSelectWord: { _ in }
            )
            rows.append(("run", run.measuredHeight(width: inner)))
        }

        if let title {
            rows.append(("captions", Self.hostedHeight(captionsBlock(title: title), width: inner)))
        }

        for ayah in ayahs {
            let note = settings.bookmarkNoteText(surah: surah.id, ayah: ayah.id)
            guard !note.isEmpty else { continue }
            rows.append(("note", Self.hostedHeight(noteRow(ayah: ayah, note: note), width: inner)))
        }

        let total = 2 * Self.verticalPadding + rows.map(\.1).reduce(0, +)
            + CGFloat(max(0, rows.count - 1)) * Self.rowSpacing
        #if DEBUG
        Self.lastBreakdown = "width=\(Int(width)) " + rows.map { "\($0.0)=\(Int($0.1.rounded()))" }.joined(separator: " ")
        #endif
        return total
    }

    #if DEBUG
    /// The last estimate's rows, for `-ayahSheetFitLog`.
    static var lastBreakdown = ""
    #endif

    private static func lineHeight(_ style: UIFont.TextStyle) -> CGFloat {
        ceil(UIFont.preferredFont(forTextStyle: style).lineHeight)
    }

    /// A SwiftUI view's height at `width`, laid out offscreen by a hosting controller. The captions and
    /// the notes are plain `Text`, so this is exact; a UIKit string measurement of the same words
    /// wrapped a line earlier than `Text` did (2026-11-09).
    private static func hostedHeight<V: View>(_ view: V, width: CGFloat) -> CGFloat {
        let host = UIHostingController(rootView: view.frame(width: width))
        let size = host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
        return ceil(size.height)
    }

    private func stepScale(_ direction: Double) {
        let range = Settings.ayahPreviewScaleRange
        let next = (settings.ayahPreviewCardScale + direction * Settings.ayahPreviewScaleStep)
        let clamped = min(max((next * 100).rounded() / 100, range.lowerBound), range.upperBound)
        guard clamped != settings.ayahPreviewCardScale else { return }
        settings.hapticFeedback()
        withAnimation(.easeInOut(duration: 0.15)) { settings.ayahPreviewCardScale = clamped }
    }

    /// Minus | percentage | plus. The number is the affordance that says the setting is remembered -
    /// without it, two identical circles give no hint that the size persists.
    private var sizeStepper: some View {
        let range = Settings.ayahPreviewScaleRange
        return HStack(spacing: 8) {
            stepperButton("minus", enabled: settings.ayahPreviewCardScale > range.lowerBound) { stepScale(-1) }

            Text("\(Int((settings.ayahPreviewCardScale * 100).rounded()))%")
                .font(.caption2.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 34)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Tap the number to go back to the reader's size.
                    guard settings.ayahPreviewCardScale != 1.0 else { return }
                    settings.hapticFeedback()
                    withAnimation(.easeInOut(duration: 0.15)) { settings.ayahPreviewCardScale = 1.0 }
                }
                .accessibilityLabel("Ayah size \(Int((settings.ayahPreviewCardScale * 100).rounded())) percent, tap to reset")

            stepperButton("plus", enabled: settings.ayahPreviewCardScale < range.upperBound) { stepScale(1) }
        }
    }

    private func stepperButton(_ systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.bold))
                .foregroundStyle(enabled ? settings.accentColor.accent1 : .secondary)
                .frame(width: Self.stepperButtonSize, height: Self.stepperButtonSize)
                .contentShape(Rectangle())
                .conditionalGlassEffect(clear: true, circle: true)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(systemImage == "plus" ? "Larger" : "Smaller")
    }

    var body: some View {
        let pieces = ayahs.map { piece(for: $0, plain: showPlainText) }
        let anyModified = pieces.contains { $0.modified }

        return VStack(spacing: Self.rowSpacing) {
            // The controls ride ABOVE the Arabic (Abu, 2026-10-22: "put the + and - and the zoom in at
            // the top so when i shrink and enlarge it doesnt move the buttons"): under it, every step
            // of the size moved the row the stepper sat on. The row is skipped only when it would be
            // empty (a tafsir card with nothing to plain-text).
            //
            // Plain standard text on demand (user rule): with tajweed colors, the Allah highlight, hidden
            // tashkeel, hidden dots or beginner spacing shaping the run, one tap shows the ayah exactly
            // as written (full marks, no coloring) without touching the reader's settings. The size
            // stepper shares the line (Abu, 2026-09-19): the card's Arabic is the thing being read, and
            // the reader's own size is not always the right one inside a sheet.
            if showsStepper || anyModified {
                HStack(spacing: 10) {
                    if showsStepper {
                        sizeStepper
                    }

                    Spacer(minLength: 8)

                    if anyModified {
                        Button {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) { showPlainText.toggle() }
                        } label: {
                            Label(showPlainText ? "Show Reader's Text" : "Show Plain Text",
                                  systemImage: showPlainText ? "paintpalette" : "textformat")
                                .font(.caption2.weight(.medium))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(settings.accentColor.accent1)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            if pieces.isEmpty {
                Text("Arabic ayah unavailable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Rendered through the word-by-word TextKit view so every word is tappable - ONE tap
                // here (Abu, 2026-09-05), where the reader rows take two: there is no row tap to collide
                // with. At the reader's own size (Abu, 2026-09-07: "why is the ayah in arabic so
                // small" - it used to be little more than half of it): the sheet scrolls, so a long
                // ayah costs a swipe rather than pushing the actions off it. Clamped only for the
                // accessibility sizes.
                //
                // Selectable (Abu, 2026-10-22: the word card's hero selects, "allow me to do the same
                // thing" on the held ayah): a press-and-drag on the run highlights any part of it and
                // offers Copy / Look Up on exactly that range. A tap still opens the word.
                // The recited word (a recitation behind the sheet, or Play Word by Word from it) lights
                // on the card too; the host re-renders this run alone on each word.
                PlayingWordHost(surah: surah.id, ayahs: ayahs.map(\.id)) { playingWord in
                    WordByWordText(
                        segments: pieces.map(\.segment),
                        fontName: settings.quranDisplayUsesCustomArabicFace ? settings.quranDisplayFontName : nil,
                        fontSize: cardFontSize,
                        tapsRequired: 1,
                        selectable: true,
                        selectedWord: selectedWord,
                        playingWord: playingWord.flatMap { word in
                            guard let segment = pieces.firstIndex(where: { $0.ayah.id == word.ayah }),
                                  let token = QuranWords.tokenIndex(ofWord: word.index,
                                                                    in: pieces[segment].segment.displayText,
                                                                    expecting: word.count) else { return nil }
                            return WordByWordRef(segment: segment, index: token)
                        },
                        onSelectWord: { ref in select(ref, pieces: pieces) }
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .ayahSheetFitProbe("run")
            }

            // The reference caption, then the ayah's ACTUAL text in BOTH bundled translations, each
            // under its name (Abu, 2026-10-22: "include mustafa khattab clear quran for tafsir and when
            // i long hold an ayah"), the reader's current one first: one flowing paragraph each,
            // numbered inline when the group spans several.
            if let title {
                captionsBlock(title: title)
            }

            // The bookmark notes, right under the ayahs they belong to - they existed only behind "Edit
            // Note", so the one place you tapped the ayah never showed you what you'd written about it.
            ForEach(ayahs.filter { !settings.bookmarkNoteText(surah: surah.id, ayah: $0.id).isEmpty }) { ayah in
                noteRow(ayah: ayah, note: settings.bookmarkNoteText(surah: surah.id, ayah: ayah.id))
            }
        }
        .padding(.horizontal, Self.horizontalPadding)
        .padding(.vertical, Self.verticalPadding)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
        .sheet(item: $tappedWord) { tapped in
            WordMeaningSheet(
                surah: surah,
                ayah: tapped.ayah,
                word: tapped.word,
                meaning: tapped.meaning,
                position: tapped.index + 1,
                total: tapped.total
            )
            .environmentObject(settings)
        }
        .sheet(item: $tappedRiwayahWord) { tapped in
            RiwayahWordSheet(
                surah: surah,
                ayah: tapped.ayah,
                tag: tapped.tag,
                word: tapped.word,
                index: tapped.index,
                total: tapped.total
            )
            .environmentObject(settings)
        }
    }
}

/// The same actions the list view offers on an ayah - bookmark, note, tafsir, compare, playback, copy, share - 
/// reconstructed from `(surah, ayah)` and presented as a sheet when an ayah is tapped in page mode.
///
/// Anything that opens ANOTHER sheet is not presented from here. It's reported through `onRequestSheet`, and the
/// parent closes this sheet first and then presents the new one, so you never end up with a sheet stacked on a
/// sheet.
struct AyahActionsSheet: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var quranData = QuranData.shared
    /// Actions only (`playAyah`): the sheet reads no player state, and observing it rebuilt the whole
    /// action grid on every ayah advance of a recitation running behind the sheet (Phase 10.4).
    private var quranPlayer: QuranPlayer { .shared }
    /// The per-ayah pins (beginner spacing, tajweed, tashkeel, dots, ...), shared with the list rows, the
    /// preview card and the page composer - so the "Apply Settings" tile's menu shows the ayah's real
    /// current state and a pin re-composes the page behind the sheet.
    @ObservedObject private var displayOverrides = AyahDisplayOverrides.shared
    /// The "Keep Sheet Open" channel: non-nil while a secondary sheet is stacked over this one.
    @ObservedObject private var sheetStack = AyahSheetStack.shared
    /// Play Word by Word's run (publishes on start and stop only): the tile reads Play or Stop.
    @ObservedObject private var wordClips = WordClipPlayer.shared
    @Environment(\.dismiss) private var dismiss
    /// The reciter list, presented ON this sheet rather than swapped for it, so the voice can be
    /// changed and the ayah played without leaving the actions (Abu, 2026-10-25).
    @State private var showReciterPicker = false
    /// The displayed riwayah changed under this sheet (see `closeAfterRiwayahChange`).
    @State private var riwayahChanged = false

    let surah: Surah
    let ayah: Ayah
    var onRequestSheet: ((AyahSecondarySheet) -> Void)?
    /// Whether the host can draw the inline study layout (the list reader), so the "Apply Settings"
    /// menu offers the per-ayah "Word by Word" pin.
    var offersWordByWord: Bool = false
    /// The detent this sheet opened at (`AyahRowSheetRequest.opensLarge`), so a sheet stacked on it
    /// (`StackedSecondaryPresentation`) rises to the same height instead of deciding again.
    var opensLarge: Bool = false

    private var isBookmarked: Bool { settings.bookmarkIndex(surah: surah.id, ayah: ayah.id) != nil }
    private var currentNote: String { settings.bookmarkNoteText(surah: surah.id, ayah: ayah.id) }
    private var currentHighlight: AyahHighlightColor? {
        settings.bookmarkHighlight(surah: surah.id, ayah: ayah.id)
    }
    private var canShowTafsir: Bool { settings.isHafsDisplay }
    /// The comparison tile is worth showing as soon as either comparison is available.
    private var canCompare: Bool { settings.showQiraahDetails || settings.isHafsDisplay }

    /// After Play This Ayah or Repeat Ayah: the sheet closes, unless "Keep Sheet Open While Playing"
    /// is on (Abu, 2026-10-25: "sometimes when its playing i want to read the big sheet"). Play From
    /// Ayah does not come through here since 2026-10-26 (Abu: "play from ayah shouldn't count for
    /// keeping sheet opened, only repeat and play this ayah"): the recitation moves on through the page
    /// or surah, so the sheet's own ayah is not what is playing; it closes. Play Custom Range never comes
    /// through here either: its own sheet plays, and since 2026-10-31 it keeps this sheet only for a
    /// range of this one ayah (see `AyahSecondarySheetContent`).
    private func closeAfterPlaying() {
        if !settings.keepAyahSheetOpenOnPlay { dismiss() }
    }

    /// A reciter of another riwayah picked on top of this sheet switches the display off Hafs, and
    /// `ayah` is a NUMBER: under the new riwayah the card shows that riwayah's ayah of the number
    /// (other words where the counts differ) and Bookmark and Note file under it. The sheet closes
    /// instead, once nothing is presented on top of it (a presenter dismissed while its child is
    /// still leaving is ignored), a beat later as the hosts' own sheet swaps wait.
    private func closeAfterRiwayahChange() {
        guard riwayahChanged, !showReciterPicker, sheetStack.pending == nil else { return }
        riwayahChanged = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { dismiss() }
    }

    // MARK: The opening detent

    /// The sheet content's geometry, named once so the body and the fit decision stay in step.
    static let contentHorizontalPadding: CGFloat = 16
    static let contentTopPadding: CGFloat = 8
    static let contentSpacing: CGFloat = 14
    static let actionTileHeight: CGFloat = 62
    /// Air under the first row of actions before the medium detent counts as "fits". A hair only: the
    /// room is measured above the home indicator's safe area, under which the sheet's own background
    /// goes on, so a row that ends at the fold still has 34 pt of sheet beneath it (al-Fatihah 1:7 ends
    /// 6 pt above the fold and opens medium; a 12 pt allowance sent it large, 2026-11-09).
    private static let fitAllowance: CGFloat = 4
    /// The Now Playing bar at the sheet's foot while a recitation plays (`SheetNavigationContainer`),
    /// counted generously: over-counting only tips a borderline card to the large detent.
    private static let nowPlayingBarAllowance: CGFloat = 64

    /// Whether the sheet opens at the large detent: when the ayah card and one full row of actions
    /// would NOT both fit at the medium one (Abu, 2026-11-08: "if it can all fit and there are some
    /// other options it should open half, else if the whole ayah won't fit open full screen"). The card
    /// is measured before the sheet exists (`AyahPreviewCard.estimatedHeight`: the run's real TextKit
    /// layout at the reader's size, the captions at their fonts) and set against the room the medium
    /// detent leaves under the sheet's navigation bar; the other detent stays a drag away either way.
    /// Until 2026-11-08 a 24-Hafs-word proxy decided, which opened a 23-word ayah at a large reader
    /// size with no action in sight and a short one at a huge card size folded in half; the proxy
    /// (`opensLargeByLength`) is the fallback when there is no portrait window to measure against.
    /// Phones only: `SheetPresentationModifier` presents large on every other idiom regardless.
    static func opensLarge(surah: Surah, ayah: Ayah) -> Bool {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return false }
        guard let window = ayahSheetKeyWindow(),
              window.bounds.width > 0, window.bounds.height > window.bounds.width else {
            return opensLargeByLength(for: ayah)
        }
        let recorded = AyahSheetMediumRoom.recorded(for: window)
        var room = recorded ?? mediumDetentRoomEstimate(in: window)
        if PlaybackVisibility.shared.showsNowPlaying { room -= nowPlayingBarAllowance }
        let card = AyahPreviewCard(surah: surah, ayahs: [ayah])
            .estimatedHeight(width: sheetWidth(in: window) - 2 * contentHorizontalPadding)
        let needed = contentTopPadding + card + contentSpacing + actionTileHeight + fitAllowance
        #if DEBUG
        if AyahSheetFitProbe.enabled {
            NSLog("AyahSheetFit decide %d:%d window=%.0fx%.0f safe(top=%.0f,bottom=%.0f) card=%.1f [%@] needed=%.1f room=%.1f (%@) -> %@",
                  surah.id, ayah.id, window.bounds.width, window.bounds.height,
                  window.safeAreaInsets.top, window.safeAreaInsets.bottom, card, AyahPreviewCard.lastBreakdown,
                  needed, room, recorded == nil ? "estimated" : "measured", needed > room ? "large" : "medium")
        }
        #endif
        return needed > room
    }

    /// The width the sheet lays its content out in: the window's, less 8 pt on iOS 26, whose sheets
    /// inset their scrolling content by 4 pt a side (the card measured 40 pt narrower than the window
    /// on three simulators, 2026-11-09).
    private static func sheetWidth(in window: UIWindow) -> CGFloat {
        if #available(iOS 26.0, *) { return window.bounds.width - 8 }
        return window.bounds.width
    }

    /// What the medium detent shows of the sheet's scrolling content, above the home indicator, until a
    /// sheet has stood at that detent and MEASURED it (`AyahSheetMediumRoom`, which the decision prefers).
    /// Not derivable with confidence: on iOS 26 the medium sheet floats and its height follows the
    /// device (365.7 pt of room on an iPhone 17 Pro, 407.7 on a 17 Pro Max, the same safe areas either
    /// side; the large sheet's top sits at the Dynamic Island on those and 10 pt under the status bar on
    /// an iPhone 16e), so this fits those readings: half the window under the status bar, less 40.
    /// Before iOS 26, UIKit's medium is half of the large detent (the window less the status bar and a
    /// 10 pt gap), with the 56 pt navigation bar and the bottom safe area inside it.
    private static func mediumDetentRoomEstimate(in window: UIWindow) -> CGFloat {
        let bounds = window.bounds, safe = window.safeAreaInsets
        if #available(iOS 26.0, *) {
            return ((bounds.height - safe.top) / 2).rounded(.down) - 40
        }
        return ((bounds.height - safe.top - 10) / 2).rounded(.down) - 56 - safe.bottom
    }

    /// The length proxy the decision falls back on without a window to measure against: 24 Hafs words
    /// and up opens large. Counted on the Hafs text whatever riwayah is displayed.
    static func opensLargeByLength(for ayah: Ayah) -> Bool {
        WordTokens.tokens(in: ayah.textHafs).count >= 24
    }

    /// One action. A compact square rather than a full-width list row: the actions are icons with a word under
    /// them, so a dozen of them fit a small sheet with no scrolling.
    private func actionTile(_ title: String, systemImage: String, destructive: Bool = false,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionTileLabel(title, systemImage: systemImage, destructive: destructive)
        }
        .buttonStyle(.plain)
    }

    private func actionTileLabel(_ title: String, systemImage: String, destructive: Bool = false,
                                 tint: Color? = nil) -> some View {
        // `tint` overrides the accent for one tile (the highlighter, showing its color). `destructive`
        // still wins - a red tile is a warning, and nothing should be able to paint over that.
        let color = destructive ? Color.red : (tint ?? settings.accentColor.accent1)

        return VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                // A fixed slot: the symbols differ in height (bookmark, note.text, text.quote), which set
                // the titles of one row on three different lines.
                .frame(height: 22)

            // ONE line, always (Abu, 2026-10-25), at ONE size across the grid. The longest titles
            // ("Play Custom Range", "Unbookmark Ayah", "Highlight: Purple") just fit a tile at the
            // default text size, so the title stops growing there: above it the long ones shrank while
            // their neighbours grew, a row of mismatched sizes, and "Play Custom Range" still
            // truncated at the largest setting. The scale factor is only the fallback for a longer
            // translation.
            Text(title)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
                .dynamicTypeSize(...DynamicTypeSize.large)
        }
        .padding(.horizontal, 6)
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
        .frame(height: Self.actionTileHeight)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.10))
        )
    }

    /// One entry in the grid. `repeatMenu` is the odd one out - it opens a menu rather than firing an action - 
    /// so it carries no `action`.
    private struct AyahAction: Identifiable {
        /// The two tiles that open a menu instead of firing an action: the repeat count and the comparison
        /// (qiraah vs translation) both need a choice before anything happens.
        enum Kind { case button, repeatMenu, playFromMenu, comparisonMenu, highlightMenu, settingsMenu, noteMenu }

        let id: String
        let title: String
        let systemImage: String
        var kind: Kind = .button
        var destructive = false
        /// Paints the tile in the ayah's highlight color instead of the accent - only the highlight tile
        /// uses it, so the tile shows which color the ayah is wearing without being opened.
        var tint: Color? = nil
        var action: () -> Void = {}
    }

    /// Which tiles exist depends on the qiraah and on whether the ayah has a note, so the set is built first and
    /// the column count is chosen from its size - see `columnCount`.
    private var actions: [AyahAction] {
        // The ayah menus' order and wording (the reader's ⋯ and ▶ menus, the Quran tab's long press):
        // mark, study, Apply Settings, play, then the text. Abu, 2026-10-25: "make sure context menu is
        // consistent with long hold ayah sheet". The grid stays flat where a menu nests (Study Ayah),
        // but nothing here is named or ordered differently from the menus.
        var list: [AyahAction] = [
            AyahAction(
                id: "bookmark",
                title: isBookmarked ? String(localized: "Unbookmark Ayah") : String(localized: "Bookmark Ayah"),
                systemImage: isBookmarked ? "bookmark.fill" : "bookmark",
                action: {
                    settings.hapticFeedback()
                    settings.toggleBookmarkOrConfirm(surah: surah.id, ayah: ayah.id)
                }
            ),
            // Next to the bookmark tile, because it is one: picking a color saves the ayah and colors its
            // bookmark. The tile itself wears the current color, so page mode can answer "what did I mark
            // this in?" without opening the menu.
            AyahAction(
                id: "highlight",
                title: currentHighlight.map { String(localized: "Highlight: \($0.title)") } ?? String(localized: "Highlight"),
                systemImage: "highlighter",
                kind: .highlightMenu,
                tint: currentHighlight?.color
            ),
        ]

        // Add Note on its own; once a note is saved, one Note tile opens Edit Note and Remove Note, the
        // menus' Note submenu (it was two tiles here).
        if currentNote.isEmpty {
            list.append(AyahAction(
                id: "note",
                title: String(localized: "Add Note"),
                systemImage: "note.text",
                action: {
                    settings.hapticFeedback()
                    if !isBookmarked { settings.ensureBookmarkExists(surah: surah.id, ayah: ayah.id) }
                    onRequestSheet?(.note)
                }
            ))
        } else {
            list.append(AyahAction(id: "note", title: String(localized: "Note"), systemImage: "note.text", kind: .noteMenu))
        }

        if canShowTafsir {
            list.append(AyahAction(id: "tafsir", title: String(localized: "See Tafsir"), systemImage: "text.book.closed", action: {
                settings.hapticFeedback()
                onRequestSheet?(.tafsir)
            }))
        }

        // Similar Ayahs reads against the Hafs text like the tafsir, and shows whenever the pack is
        // bundled (probing THIS ayah would parse 4.5 MB of JSON on every open; the sheet handles the
        // no-matches case). The Quran tab's rows offered it and the readers didn't.
        if canShowTafsir, SimilarAyahsStore.isBundled {
            list.append(AyahAction(id: "similar", title: String(localized: "Similar Ayahs"), systemImage: "doc.text.magnifyingglass", action: {
                settings.hapticFeedback()
                onRequestSheet?(.similarAyahs)
            }))
        }

        // The repeated phrases (mutashabihat) live in the same sheet as Similar Ayahs, on their
        // own tab; this tile opens straight onto it.
        if canShowTafsir, MutashabihatStore.isBundled {
            list.append(AyahAction(id: "mutashabihat", title: String(localized: "Mutashabihat"), systemImage: "text.quote", action: {
                settings.hapticFeedback()
                onRequestSheet?(.mutashabihat)
            }))
        }

        // Qiraah and translation are the same idea - see this ayah rendered another way - so they're one tile
        // holding both, rather than two that look like unrelated features.
        if canCompare {
            list.append(AyahAction(
                id: "comparison",
                title: String(localized: "Compare Ayah"),
                systemImage: "arrow.left.arrow.right.square",
                kind: .comparisonMenu
            ))
        }

        // Last of the study tiles, where the menus' Study Ayah submenu ends with it. Absent on a device
        // without Apple Intelligence rather than present and dead (the OnDeviceAsk pattern).
        if canShowTafsir, AyahSummarizeSheet.isOffered {
            list.append(AyahAction(id: "summarize", title: String(localized: "Summarize with AI"), systemImage: "text.append", action: {
                settings.hapticFeedback()
                onRequestSheet?(.summarize)
            }))
        }

        // Was a per-ayah "Beginner" toggle: now the whole "Apply Settings" menu (Abu, 2026-09-05) - beginner
        // spacing, tajweed, tashkeel, dots, Highlight Allah (and word by word in the list), several at once,
        // pinned to THIS ayah, with a reset when it differs from the app. The tile wears the accent while
        // the ayah pins anything, so page mode can answer "is this ayah different?" without opening it.
        // Sits right after the study tiles, where the reader rows' ellipsis menu puts it.
        if settings.showArabicText {
            let pinned = displayOverrides.hasOverride([HighlightedAyahRef(surahID: surah.id, ayahID: ayah.id)])
            list.append(AyahAction(
                id: "settings",
                title: String(localized: "Apply Settings"),
                systemImage: pinned ? "slider.horizontal.2.square" : "slider.horizontal.3",
                kind: .settingsMenu
            ))
        }

        if settings.isHafsDisplay {
            // The ▶ menu's playback list in its order (and the Quran tab's Ayah Playback submenu): Repeat
            // Ayah, Play Custom Range, Play From Ayah, then Play This Ayah, the primary action, lowest and
            // nearest the thumb. Who recites is the Choose Reciter row under the grid. Repeat and Play
            // This close the sheet unless Keep Sheet Open While Playing is on (`closeAfterPlaying`);
            // Play From always closes it, and Custom Range opens its own sheet.
            list.append(AyahAction(id: "repeat", title: String(localized: "Repeat Ayah"), systemImage: "repeat", kind: .repeatMenu))

            list.append(AyahAction(id: "customRange", title: String(localized: "Play Custom Range"), systemImage: "slider.horizontal.3", action: {
                settings.hapticFeedback()
                // With Keep Sheet Open While Playing on, the range sheet stacks on this one, so a
                // range of this one ayah can hand the sheet back (see `AyahSecondarySheetContent`);
                // otherwise the host swaps it in, as for every other secondary sheet.
                if settings.keepAyahSheetOpenOnPlay {
                    sheetStack.present(.customRange)
                } else {
                    onRequestSheet?(.customRange)
                }
            }))

            // A MENU since 2026-10-07 (Abu: "play from ayah ... it becomes a menu and then theres play
            // til end of page, or end of surah or end of juz or end of infinitely"). The tile itself is
            // unchanged; picking how far it carries is the choice the menu asks for.
            list.append(AyahAction(id: "playFrom", title: String(localized: "Play From Ayah"), systemImage: "play.circle.fill",
                                   kind: .playFromMenu))

            // Play Word by Word (Abu, 2026-11-02): quran.com's clip of each word in turn, the word lit
            // on the card above as it sounds (WordClipPlayer). The sheet stays up, following along being
            // the point; the same tile stops the run.
            let wordsPlaying = wordClips.isPlaying(surah: surah.id, ayah: ayah.id)
            list.append(AyahAction(id: "wordByWord",
                                   title: wordsPlaying ? String(localized: "Stop Word by Word") : String(localized: "Play Word by Word"),
                                   systemImage: wordsPlaying ? "stop.circle" : "text.word.spacing", action: {
                settings.hapticFeedback()
                WordClipPlayer.shared.toggle(surah: surah.id, ayah: ayah.id)
            }))

            list.append(AyahAction(id: "play", title: String(localized: "Play This Ayah"), systemImage: "play.circle", action: {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
                closeAfterPlaying()
            }))
        }

        // Select Text and Copy Ayah ARE tiles (Abu, 2026-09-22: "select text and copy ayah in the
        // long hold sheet make them normal grid buttons so only share ayah takes up the whole row").
        // They were a half-width pair of their own under the grid from 2026-09-07, which gave the
        // sheet three different button widths; now only Share Ayah is a row, the one filled button,
        // and the thing you most often came for is still the biggest target on the sheet.
        //
        // Last in the grid, in the ellipsis menu's own order (Select Text, Copy Ayah, then Share):
        // see `ayah-menu-parity-and-search-paint` - one action list, one order, every menu.
        // `selection.pin.in.out`, not the menus' `highlighter`: the Highlight tile is RIGHT THERE in
        // the same grid wearing that symbol, and two identical icons side by side say nothing. The
        // menus never had the clash because a text list names every row. Titles still match exactly.
        list.append(AyahAction(id: "selectText", title: String(localized: "Select Text"), systemImage: "selection.pin.in.out", action: {
            settings.hapticFeedback()
            onRequestSheet?(.selectText)
        }))

        list.append(AyahAction(id: "copy", title: String(localized: "Copy Ayah"), systemImage: "doc.on.doc", action: {
            settings.hapticFeedback()
            ShareAyahSheet.copyAyahToPasteboard(surahNumber: surah.id, ayahNumber: ayah.id,
                                                settings: settings, quranData: quranData)
            dismiss()
        }))

        return list
    }

    /// The ONE full-width row under the grid (Abu, 2026-09-22: "only share ayah takes up the whole
    /// row"): the filled, accent-colored button the sheet is built around. Select Text and Copy Ayah
    /// used to flank it as a half-width pair; they are grid tiles now, see `actions`.
    private var shareRow: some View {
        Button {
            settings.hapticFeedback()
            onRequestSheet?(.share)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .semibold))
                Text("Share Ayah")
                    .font(.headline)
                    .lineLimit(1)
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [settings.accentColor.accent1, settings.accentColor.accent1.opacity(0.78)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: settings.accentColor.accent1.opacity(0.28), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    /// The sheet's own options, one card under Share (Abu, 2026-10-25): who recites, whether playing
    /// from here closes the sheet, and whether the screen may sleep while it is up. It replaced the lone
    /// "Keep Sheet Open" row, whose switch (Tafsir and the rest stacking on top of this sheet) still
    /// lives in Quran Settings > Reading View. The reciter and the playing switch go with the playback
    /// tiles, so they show only where those do (Hafs).
    private var optionsCard: some View {
        VStack(spacing: 0) {
            if settings.isHafsDisplay {
                reciterRow

                Divider()
                    .padding(.leading, 44)

                optionToggle(
                    String(localized: "Keep Sheet Open While Playing"),
                    caption: String(localized: "Play This Ayah, Repeat Ayah and a custom range of this one ayah leave this sheet up so you can keep reading. Play From Ayah and wider ranges still close it."),
                    systemImage: "rectangle.stack",
                    isOn: $quranDisplay.keepAyahSheetOpenOnPlay
                )

                Divider()
                    .padding(.leading, 44)
            }

            optionToggle(
                String(localized: "Keep Screen On"),
                caption: String(localized: "The screen stays awake while this sheet is open."),
                systemImage: "sun.max",
                isOn: $quranDisplay.ayahSheetKeepsScreenOn
            )
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(settings.accentColor.accent1.opacity(0.10))
        )
        // The grid's rule: one-line titles at one size. "Keep Sheet Open While Playing" fills the
        // row at the default text size, so the card stops growing there; above it that title shrank
        // under its neighbours. The ayah card above still follows the reader's text size.
        .dynamicTypeSize(...DynamicTypeSize.large)
        .onChange(of: quranDisplay.keepAyahSheetOpenOnPlay) { _ in settings.hapticFeedback() }
        .onChange(of: quranDisplay.ayahSheetKeepsScreenOn) { _ in settings.hapticFeedback() }
        // On the card, not the reciter row: picking a reciter of another riwayah can switch the
        // display off Hafs, which removes the row, and a sheet whose host vanishes is torn down
        // mid-choice.
        .reciterPickerSheet(isPresented: $showReciterPicker)
    }

    /// Choose Reciter with the current voice under it, the menus' `ChooseReciterMenuLabel` as a row.
    /// The list opens on top of this sheet and closes on a pick, back to the tiles.
    private var reciterRow: some View {
        Button {
            settings.hapticFeedback()
            showReciterPicker = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "headphones")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(settings.accentColor.accent1)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Choose Reciter")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.accent1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(settings.currentReciterDisplayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.forward")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reciter: \(settings.currentReciterDisplayName)")
        .accessibilityHint("Opens the reciter list")
    }

    private func optionToggle(_ title: String, caption: String, systemImage: String,
                              isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(settings.accentColor.accent1)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.accent1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(settings.accentColor.accent1)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private var actionGrid: some View {
        // Always three across: a stable grid beats the old adaptive 2/3/4 column count, which made the
        // sheet re-arrange itself depending on whether the ayah happened to carry a note.
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
            spacing: 10
        ) {
            ForEach(actions) { item in
                switch item.kind {
                case .repeatMenu:
                    Menu {
                        // The menus' Repeat Ayah submenu, header included.
                        Text("Repeat Count")
                            .foregroundStyle(.secondary)

                        ForEach([2, 3, 5, 10, 15, 20], id: \.self) { count in
                            Button {
                                settings.hapticFeedback()
                                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: count)
                                closeAfterPlaying()
                            } label: {
                                Label("Repeat \(count)×", systemImage: "\(count).circle")
                            }
                        }

                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: QuranPlayer.infiniteRepeat)
                            closeAfterPlaying()
                        } label: {
                            Label("Repeat Forever", systemImage: "infinity")
                        }
                        // Play Custom Range is its own tile beside this one; it no longer ends this
                        // menu as well (the menus' one-home rule, 2026-10-21).
                    } label: {
                        actionTileLabel(item.title, systemImage: item.systemImage)
                    }

                case .playFromMenu:
                    Menu {
                        // Always closes, whatever Keep Sheet Open While Playing says: the recitation
                        // carries on past this ayah (see `closeAfterPlaying`).
                        ayahPlayFromMenuItems(surah: surah.id, ayah: ayah.id, settings: settings,
                                              quranPlayer: quranPlayer) { dismiss() }
                    } label: {
                        actionTileLabel(item.title, systemImage: item.systemImage)
                    }
                    // Page first, top to bottom, wherever the tile sits: a tile low in the sheet opens
                    // its menu upward, and the automatic order would put Page at the bottom.
                    .fixedMenuOrder()

                case .comparisonMenu where !settings.showQiraahDetails && !settings.isHafsDisplay:
                    // Neither comparison applies (riwayah details off while another riwayah is still on
                    // display): no tile. The menu below would have had no rows, and a single-choice tile
                    // here opened the Qiraah Comparison the user had switched off.
                    EmptyView()

                case .comparisonMenu where !(settings.showQiraahDetails && settings.isHafsDisplay):
                    // One choice (no riwayah details, or a non-Hafs display): the tile opens it directly
                    // instead of a menu holding a single row.
                    actionTile(item.title, systemImage: item.systemImage) {
                        settings.hapticFeedback()
                        onRequestSheet?(settings.isHafsDisplay ? .translations : .qiraah)
                    }

                case .comparisonMenu:
                    Menu {
                        if settings.showQiraahDetails {
                            Button {
                                settings.hapticFeedback()
                                onRequestSheet?(.qiraah)
                            } label: {
                                Label("Qiraah Comparison", systemImage: "character.book.closed.fill.ar")
                            }
                        }
                        if settings.isHafsDisplay {
                            Button {
                                settings.hapticFeedback()
                                onRequestSheet?(.translations)
                            } label: {
                                Label("Translation Comparison", systemImage: "character.book.closed")
                            }
                        }
                    } label: {
                        actionTileLabel(item.title, systemImage: item.systemImage)
                    }

                case .noteMenu:
                    // The menus' Note submenu: shown once the ayah has a note.
                    Menu {
                        Button {
                            settings.hapticFeedback()
                            onRequestSheet?(.note)
                        } label: {
                            Label("Edit Note", systemImage: "note.text")
                        }

                        Button(role: .destructive) {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) {
                                settings.removeBookmarkNote(surah: surah.id, ayah: ayah.id)
                            }
                        } label: {
                            Label("Remove Note", systemImage: "minus.circle")
                        }
                    } label: {
                        actionTileLabel(item.title, systemImage: item.systemImage)
                    }

                case .highlightMenu:
                    Menu {
                        ayahHighlightMenuItems(surah: surah.id, ayah: ayah.id, settings: settings)
                    } label: {
                        actionTileLabel(item.title, systemImage: item.systemImage, tint: item.tint)
                    }

                case .settingsMenu:
                    Menu {
                        ayahDisplayMenuItems(refs: [HighlightedAyahRef(surahID: surah.id, ayahID: ayah.id)],
                                             settings: settings, offersWordByWord: offersWordByWord)
                    } label: {
                        actionTileLabel(item.title, systemImage: item.systemImage)
                    }

                case .button:
                    actionTile(item.title, systemImage: item.systemImage, destructive: item.destructive, action: item.action)
                }
            }
        }
    }

    var body: some View {
        SheetNavigationContainer {
            ScrollView {
                VStack(spacing: Self.contentSpacing) {
                    // The ayah itself, so the sheet says what you tapped rather than only naming it - the
                    // same card the tafsir sheet shows (word taps, plain-text toggle, translation, note).
                    AyahPreviewCard(surah: surah, ayahs: [ayah])
                        .ayahSheetFitProbe("card") { width in
                            AyahPreviewCard(surah: surah, ayahs: [ayah]).estimatedHeight(width: width)
                        }

                    actionGrid

                    shareRow

                    optionsCard

                    // With qiraah details on, the readings of the Ten at this ayah's variant words -
                    // who reads what, and what it means (Abu, 2026-09-07: "if qiraah is turned on
                    // show other qiraat underneath").
                    if settings.showQiraahDetails, QiraatVariantsStore.isBundled {
                        AyahQiraatVariantsSection(surah: surah, ayah: ayah)
                    }

                    // What the ayah is about and where it sits: its passage, hizb / ruku / manzil,
                    // and the topics that annotate it, headed by what the card is.
                    AyahInsightsCard(surah: surah, ayah: ayah, explains: true)
                }
                .padding(.horizontal, Self.contentHorizontalPadding)
                .padding(.top, Self.contentTopPadding)
                .padding(.bottom, 16)
            }
            .ayahSheetFitProbe("content")
            .recordAyahSheetMediumRoom()
            .navigationTitle(ayahSheetTitle(surahNumber: surah.id, ayahNumber: ayah.id))
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            .accentWashedBackground()
        }
        .ayahSheetFitProbe("sheet")
        // "Keep Screen On": held while this sheet is up, including under a sheet stacked on it, and
        // let go the moment it closes (`KeepScreenAwake` releases on disappear).
        .keepScreenAwake(while: quranDisplay.ayahSheetKeepsScreenOn)
        // "Keep Sheet Open": the reader posts the request here rather than swapping this sheet out,
        // and this sheet - which is on screen, so it CAN present - stacks it on top of itself. The
        // second sheet's dismiss lands back here (Abu, 2026-09-19).
        .sheet(item: $sheetStack.pending) { secondary in
            AyahSecondarySheetContent(
                kind: secondary,
                surah: surah,
                ayah: ayah,
                onDismiss: { sheetStack.pending = nil }
            )
            .modifier(StackedSecondaryPresentation(kind: secondary, startLarge: opensLarge))
        }
        .onChange(of: quranDisplay.displayQiraah) { _ in
            riwayahChanged = true
            closeAfterRiwayahChange()
        }
        .onChange(of: showReciterPicker) { _ in closeAfterRiwayahChange() }
        .onChange(of: sheetStack.pending == nil) { cleared in
            closeAfterRiwayahChange()
            // A custom range wider than this ayah was played from the range sheet stacked here, or
            // the Share Ayah sheet stacked here copied or shared: this sheet goes too, once that one
            // is down (`AyahSheetStack.closeHostWhenCleared`). A beat later, so the two do not fight
            // over one dismissal.
            if cleared, sheetStack.closeHostWhenCleared {
                sheetStack.closeHostWhenCleared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { dismiss() }
            }
        }
    }
}

/// The key window, for the sheet geometry the detent decision measures against.
private func ayahSheetKeyWindow() -> UIWindow? {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
        .first { $0.isKeyWindow }
}

/// How much of the ayah actions sheet's scrolling content the MEDIUM detent shows above the home
/// indicator, as measured the last time a sheet stood there (`MediumRoomRecorder`), per window size
/// (devices and orientations differ) and kept across launches. `AyahActionsSheet.opensLarge` decides
/// from this and estimates only until the first measurement.
enum AyahSheetMediumRoom {
    private static var cache: [String: CGFloat] = [:]

    private static func key(for window: UIWindow) -> String {
        "ayahSheetMediumRoom.\(Int(window.bounds.width))x\(Int(window.bounds.height))"
    }

    static func recorded(for window: UIWindow) -> CGFloat? {
        let key = key(for: window)
        if let hit = cache[key] { return hit }
        let stored = UserDefaults.standard.double(forKey: key)
        guard stored > 0 else { return nil }
        cache[key] = stored
        return stored
    }

    static func record(_ room: CGFloat, for window: UIWindow) {
        let key = key(for: window)
        guard room > 0, abs((cache[key] ?? 0) - room) > 0.5 else { return }
        cache[key] = room
        UserDefaults.standard.set(Double(room), forKey: key)
    }
}

/// Measures the medium detent's room for `AyahSheetMediumRoom`: the scroll view's own height, once it
/// has held still for half a second. Only a height under 60% of the window's can be the medium detent
/// (the large one shows over 80% on every phone), which keeps a sheet dragged to the large detent, and
/// the frames on the way there, out of the record; so does the Now Playing bar, which shortens the
/// content while a recitation plays.
private struct MediumRoomRecorder: ViewModifier {
    @ObservedObject private var playback = PlaybackVisibility.shared
    @State private var pending: DispatchWorkItem?

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { schedule(proxy.size.height) }
                    .onChange(of: proxy.size.height) { schedule($0) }
            }
        )
    }

    private func schedule(_ height: CGFloat) {
        pending?.cancel()
        let barShown = playback.showsNowPlaying
        let work = DispatchWorkItem {
            guard !barShown, height > 0, let window = ayahSheetKeyWindow(),
                  height < window.bounds.height * 0.6 else { return }
            AyahSheetMediumRoom.record(height, for: window)
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: work)
    }
}

extension View {
    func recordAyahSheetMediumRoom() -> some View { modifier(MediumRoomRecorder()) }
}

/// The stacked sheet's detents: the range picker opens full height, everything else takes the
/// small/medium pair the swapped copy uses, opening at the detent the actions sheet beneath it
/// opened at, so the stack rises as one.
private struct StackedSecondaryPresentation: ViewModifier {
    let kind: AyahSecondarySheet
    let startLarge: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if kind == .customRange {
            content
        } else {
            content.smallMediumSheetPresentation(startLarge: startLarge)
        }
    }
}

#if DEBUG
/// `-ayahSheetFitLog`: prints a view's laid-out size and safe-area insets whenever they change, and
/// an estimate made from its width, so the detent decision's constants (`AyahActionsSheet.opensLarge`)
/// can be read against the real layout. Nothing without the flag; nothing at all in Release.
struct AyahSheetFitProbe: ViewModifier {
    static let enabled = ProcessInfo.processInfo.arguments.contains("-ayahSheetFitLog")

    let label: String
    let estimate: ((CGFloat) -> CGFloat)?

    @ViewBuilder
    func body(content: Content) -> some View {
        if Self.enabled {
            content.background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { report(proxy) }
                        .onChange(of: proxy.size.height) { _ in report(proxy) }
                }
            )
        } else {
            content
        }
    }

    private func report(_ proxy: GeometryProxy) {
        let estimated = estimate.map { String(format: "%.1f [%@]", $0(proxy.size.width), AyahPreviewCard.lastBreakdown) } ?? "-"
        let global = proxy.frame(in: .global)
        NSLog("AyahSheetFit %@ size=%.1fx%.1f global(x=%.1f-%.1f,y=%.1f-%.1f) safe(top=%.1f,bottom=%.1f) estimate=%@",
              label, proxy.size.width, proxy.size.height,
              global.minX, global.maxX, global.minY, global.maxY,
              proxy.safeAreaInsets.top, proxy.safeAreaInsets.bottom, estimated)
    }
}

extension View {
    func ayahSheetFitProbe(_ label: String, estimate: ((CGFloat) -> CGFloat)? = nil) -> some View {
        modifier(AyahSheetFitProbe(label: label, estimate: estimate))
    }
}
#else
extension View {
    func ayahSheetFitProbe(_ label: String, estimate: ((CGFloat) -> CGFloat)? = nil) -> some View { self }
}
#endif

#endif
