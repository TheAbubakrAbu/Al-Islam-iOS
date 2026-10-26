import SwiftUI
import UIKit

#if os(iOS)

enum AyahSecondarySheet: String, Identifiable {
    case tafsir, similarAyahs, mutashabihat, qiraah, translations, customRange, note, share, selectText
    /// "Summarize with AI" on the ayah itself (2026-09-21, parity with the hadith rows, which had it
    /// on their menu while the ayah offered it only inside the tafsir and comparison sheets).
    case summarize
    /// The reciter list, for the reader row's ▶ menu (Choose Reciter at its top, as in the Quran tab's
    /// Play Ayah submenu). The actions sheet opens its own copy on top of itself instead, so picking a
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
                                 offersWordByWord: !settings.quranPageMode)
                    .smallMediumSheetPresentation(startLarge: AyahActionsSheet.opensLarge(for: ayah))

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
                onPlay: { start, end, repAyah, repSec in
                    quranPlayer.playCustomRange(
                        surahNumber: surah.id,
                        surahName: surah.nameTransliteration,
                        startAyah: start,
                        endAyah: end,
                        repeatPerAyah: repAyah,
                        repeatSection: repSec
                    )
                    onDismiss()
                },
                onCancel: { onDismiss() }
            )
            .environmentObject(settings)

        case .note:
            AyahNoteSheet(surah: surah, ayah: ayah)

        case .share:
            ShareAyahSheet(surahNumber: surah.id, ayahNumber: ayah.id)

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

    private func piece(for ayah: Ayah) -> Piece {
        let choices = displayOverrides.choices(surah: surah.id, ayah: ayah.id, settings: settings)
        let plain = showPlainText
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
        return (base * CGFloat(settings.ayahPreviewCardScale)).rounded()
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
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
                .conditionalGlassEffect(clear: true, circle: true)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(systemImage == "plus" ? "Larger" : "Smaller")
    }

    var body: some View {
        let pieces = ayahs.map(piece(for:))
        let anyModified = pieces.contains { $0.modified }

        return VStack(spacing: 6) {
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
            if showsSizeStepper || anyModified {
                HStack(spacing: 10) {
                    if showsSizeStepper {
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
                WordByWordText(
                    segments: pieces.map(\.segment),
                    fontName: settings.quranDisplayUsesCustomArabicFace ? settings.quranDisplayFontName : nil,
                    fontSize: cardFontSize,
                    tapsRequired: 1,
                    selectable: true,
                    selectedWord: selectedWord,
                    onSelectWord: { ref in select(ref, pieces: pieces) }
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // The reference caption, then the ayah's ACTUAL text in BOTH bundled translations, each
            // under its name (Abu, 2026-10-22: "include mustafa khattab clear quran for tafsir and when
            // i long hold an ayah"), the reader's current one first: one flowing paragraph each,
            // numbered inline when the group spans several.
            if let title {
                VStack(alignment: .leading, spacing: 3) {
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
                        VStack(alignment: .leading, spacing: 1) {
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
                        .padding(.top, 2)
                    }
                }
            }

            // The bookmark notes, right under the ayahs they belong to - they existed only behind "Edit
            // Note", so the one place you tapped the ayah never showed you what you'd written about it.
            ForEach(ayahs.filter { !settings.bookmarkNoteText(surah: surah.id, ayah: $0.id).isEmpty }) { ayah in
                let note = settings.bookmarkNoteText(surah: surah.id, ayah: ayah.id)
                HStack(alignment: .top, spacing: 6) {
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
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(settings.accentColor.accent1.opacity(0.08))
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
    @Environment(\.dismiss) private var dismiss
    /// The reciter list, presented ON this sheet rather than swapped for it, so the voice can be
    /// changed and the ayah played without leaving the actions (Abu, 2026-10-25).
    @State private var showReciterPicker = false

    let surah: Surah
    let ayah: Ayah
    var onRequestSheet: ((AyahSecondarySheet) -> Void)?
    /// Whether the host can draw the inline study layout (the list reader), so the "Apply Settings"
    /// menu offers the per-ayah "Word by Word" pin.
    var offersWordByWord: Bool = false

    private var isBookmarked: Bool { settings.bookmarkIndex(surah: surah.id, ayah: ayah.id) != nil }
    private var currentNote: String { settings.bookmarkNoteText(surah: surah.id, ayah: ayah.id) }
    private var currentHighlight: AyahHighlightColor? {
        settings.bookmarkHighlight(surah: surah.id, ayah: ayah.id)
    }
    private var canShowTafsir: Bool { settings.isHafsDisplay }
    /// The comparison tile is worth showing as soon as either comparison is available.
    private var canCompare: Bool { settings.showQiraahDetails || settings.isHafsDisplay }

    /// After Play This Ayah, Play From Ayah or Repeat Ayah: the sheet closes, unless "Keep Sheet Open
    /// While Playing" is on (Abu, 2026-10-25: "sometimes when its playing i want to read the big
    /// sheet"). Play Custom Range never comes through here; its own sheet plays and closes.
    private func closeAfterPlaying() {
        if !settings.keepAyahSheetOpenOnPlay { dismiss() }
    }

    /// Whether the sheet opens at the large detent. The preview card reads at the reader's size
    /// now, so a long ayah fills the medium detent by itself and every action would start below
    /// the fold; short ayahs keep the lighter medium opening (the other detent stays a drag away
    /// either way). Counted on the Hafs text whatever riwayah is displayed: a proxy for length,
    /// not a rendering.
    static func opensLarge(for ayah: Ayah) -> Bool {
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
        .frame(height: 62)
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
            // The ▶ menu's playback list in its order (and the Quran tab's Play Ayah submenu): Repeat
            // Ayah, Play Custom Range, Play From Ayah, then Play This Ayah, the primary action, lowest and
            // nearest the thumb. Who recites is the Choose Reciter row under the grid. Repeat, Play From
            // and Play This close the sheet unless Keep Sheet Open While Playing is on
            // (`closeAfterPlaying`); Custom Range opens its own sheet.
            list.append(AyahAction(id: "repeat", title: String(localized: "Repeat Ayah"), systemImage: "repeat", kind: .repeatMenu))

            list.append(AyahAction(id: "customRange", title: String(localized: "Play Custom Range"), systemImage: "slider.horizontal.3", action: {
                settings.hapticFeedback()
                onRequestSheet?(.customRange)
            }))

            // A MENU since 2026-10-07 (Abu: "play from ayah ... it becomes a menu and then theres play
            // til end of page, or end of surah or end of juz or end of infinitely"). The tile itself is
            // unchanged; picking how far it carries is the choice the menu asks for.
            list.append(AyahAction(id: "playFrom", title: String(localized: "Play From Ayah"), systemImage: "play.circle.fill",
                                   kind: .playFromMenu))

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
                    caption: String(localized: "Play This Ayah, Play From Ayah and Repeat Ayah leave this sheet up so you can keep reading. Play Custom Range still closes it."),
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
                        ayahPlayFromMenuItems(surah: surah.id, ayah: ayah.id, settings: settings,
                                              quranPlayer: quranPlayer) { closeAfterPlaying() }
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
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    // The ayah itself, so the sheet says what you tapped rather than only naming it - the
                    // same card the tafsir sheet shows (word taps, plain-text toggle, translation, note).
                    AyahPreviewCard(surah: surah, ayahs: [ayah])

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
                    // and the topics that annotate it.
                    AyahInsightsCard(surah: surah, ayah: ayah)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .navigationTitle(ayahSheetTitle(surahNumber: surah.id, ayahNumber: ayah.id))
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            .accentWashedBackground()
        }
        .navigationViewStyle(.stack)
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
            .modifier(StackedSecondaryPresentation(kind: secondary, ayah: ayah))
        }
    }
}

/// The stacked sheet's detents: the range picker opens full height, everything else takes the
/// small/medium pair the swapped copy uses.
private struct StackedSecondaryPresentation: ViewModifier {
    let kind: AyahSecondarySheet
    let ayah: Ayah

    @ViewBuilder
    func body(content: Content) -> some View {
        if kind == .customRange {
            content
        } else {
            content.smallMediumSheetPresentation(startLarge: AyahActionsSheet.opensLarge(for: ayah))
        }
    }
}

#endif
