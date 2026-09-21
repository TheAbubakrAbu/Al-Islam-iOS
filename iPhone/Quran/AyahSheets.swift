import SwiftUI
import UIKit

#if os(iOS)

enum AyahSecondarySheet: String, Identifiable {
    case tafsir, similarAyahs, mutashabihat, qiraah, translations, customRange, note, share, selectText
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
    @ObservedObject private var settings = Settings.shared
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
    @ObservedObject private var settings = Settings.shared
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
        }
    }
}

/// The note editor plus the draft it edits. A small view of its own so the *parent* can present the editor
/// without owning the draft text and the profanity check.
struct AyahNoteSheet: View {
    @ObservedObject private var settings = Settings.shared

    let surah: Surah
    let ayah: Ayah

    @State private var draftNote = ""
    @State private var showRespectAlert = false

    private func isNoteAllowed(_ text: String) -> Bool {
        !textContainsProfanity(text)
    }

    var body: some View {
        NoteEditorSheet(
            title: "Note for \(surah.nameTransliteration) \(surah.id):\(ayah.id)",
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
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var displayOverrides = AyahDisplayOverrides.shared

    let surah: Surah
    let ayahs: [Ayah]

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
        let raw = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: qiraah)
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
                rawText: ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: nil),
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
                WordByWordText(
                    segments: pieces.map(\.segment),
                    fontName: settings.quranDisplayUsesCustomArabicFace ? settings.quranDisplayFontName : nil,
                    fontSize: cardFontSize,
                    tapsRequired: 1,
                    selectedWord: selectedWord,
                    onSelectWord: { ref in select(ref, pieces: pieces) }
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Plain standard text on demand (user rule): with tajweed colors, the Allah highlight, hidden
            // tashkeel, hidden dots or beginner spacing shaping the run, one tap shows the ayah exactly
            // as written - full marks, no coloring - without touching the reader's settings.
            //
            // The size stepper sits on the same line (Abu, 2026-09-19): the card's Arabic is the thing
            // being read, and the reader's own size is not always the right one inside a sheet. Always
            // shown, even when there is nothing to plain-text.
            HStack(spacing: 10) {
                sizeStepper

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

            // The reference caption, plus the ayah's ACTUAL text in the active translation (not just the
            // translation's name) - one flowing paragraph, numbered inline when the group spans several.
            if let title {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    let translations = ayahs.compactMap { ayah -> String? in
                        guard let text = currentTranslationText(for: ayah) else { return nil }
                        return ayahs.count > 1 ? "\(text) (\(ayah.id))" : text
                    }
                    if !translations.isEmpty {
                        Text(translations.joined(separator: " "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
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

                    Text(ayahs.count > 1 ? "\(ayah.id). \(note)" : note)
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
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared
    /// The per-ayah pins (beginner spacing, tajweed, tashkeel, dots, ...), shared with the list rows, the
    /// preview card and the page composer - so the "Apply Settings" tile's menu shows the ayah's real
    /// current state and a pin re-composes the page behind the sheet.
    @ObservedObject private var displayOverrides = AyahDisplayOverrides.shared
    /// The "Keep Sheet Open" channel: non-nil while a secondary sheet is stacked over this one.
    @ObservedObject private var sheetStack = AyahSheetStack.shared
    @Environment(\.dismiss) private var dismiss

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

        return VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))

            Text(title)
                .font(.caption2.weight(.medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
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
        enum Kind { case button, repeatMenu, comparisonMenu, highlightMenu, settingsMenu }

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
        var list: [AyahAction] = [
            AyahAction(
                id: "bookmark",
                title: isBookmarked ? "Unbookmark" : "Bookmark",
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
                title: currentHighlight?.title ?? "Highlight",
                systemImage: "highlighter",
                kind: .highlightMenu,
                tint: currentHighlight?.color
            ),
            AyahAction(
                id: "note",
                title: currentNote.isEmpty ? "Add Note" : "Edit Note",
                systemImage: "note.text",
                action: {
                    settings.hapticFeedback()
                    if !isBookmarked { settings.ensureBookmarkExists(surah: surah.id, ayah: ayah.id) }
                    onRequestSheet?(.note)
                }
            ),
        ]

        if !currentNote.isEmpty {
            list.append(AyahAction(
                id: "removeNote",
                title: "Remove Note",
                systemImage: "minus.circle",
                destructive: true,
                action: {
                    settings.hapticFeedback()
                    settings.removeBookmarkNote(surah: surah.id, ayah: ayah.id)
                }
            ))
        }

        if canShowTafsir {
            list.append(AyahAction(id: "tafsir", title: "See Tafsir", systemImage: "text.book.closed", action: {
                settings.hapticFeedback()
                onRequestSheet?(.tafsir)
            }))
        }

        // Similar Ayahs reads against the Hafs text like the tafsir, and shows whenever the pack is
        // bundled (probing THIS ayah would parse 4.5 MB of JSON on every open; the sheet handles the
        // no-matches case). The Quran tab's rows offered it and the readers didn't.
        if canShowTafsir, SimilarAyahsStore.isBundled {
            list.append(AyahAction(id: "similar", title: "Similar Ayahs", systemImage: "doc.text.magnifyingglass", action: {
                settings.hapticFeedback()
                onRequestSheet?(.similarAyahs)
            }))
        }

        // The repeated phrases (mutashabihat) live in the same sheet as Similar Ayahs, on their
        // own tab; this tile opens straight onto it.
        if canShowTafsir, MutashabihatStore.isBundled {
            list.append(AyahAction(id: "mutashabihat", title: "Mutashabihat", systemImage: "text.quote", action: {
                settings.hapticFeedback()
                onRequestSheet?(.mutashabihat)
            }))
        }

        // Qiraah and translation are the same idea - see this ayah rendered another way - so they're one tile
        // holding both, rather than two that look like unrelated features.
        if canCompare {
            list.append(AyahAction(
                id: "comparison",
                title: "Compare Ayah",
                systemImage: "arrow.left.arrow.right.square",
                kind: .comparisonMenu
            ))
        }

        // Was a per-ayah "Beginner" toggle: now the whole "Apply Settings" menu (Abu, 2026-09-05) - beginner
        // spacing, tajweed, tashkeel, dots, Highlight Allah (and word by word in the list), several at once,
        // pinned to THIS ayah, with a reset when it differs from the app. The tile wears the accent while
        // the ayah pins anything, so page mode can answer "is this ayah different?" without opening it.
        // Sits right after Comparison, where the reader rows' ellipsis menu puts it.
        if settings.showArabicText {
            let pinned = displayOverrides.hasOverride([HighlightedAyahRef(surahID: surah.id, ayahID: ayah.id)])
            list.append(AyahAction(
                id: "settings",
                title: "Apply Settings",
                systemImage: pinned ? "slider.horizontal.2.square" : "slider.horizontal.3",
                kind: .settingsMenu
            ))
        }

        if settings.isHafsDisplay {
            // Playback actions close the sheet: once the recitation starts you want to be looking at the page
            // (where the ayah is highlighted), not at the menu you started it from. The titles are the
            // ellipsis menu's, word for word (Abu, 2026-09-07: "make sure menu and context menu have
            // all the same options"), so nothing here reads as a different feature from what the row
            // offers.
            list.append(AyahAction(id: "play", title: "Play Ayah", systemImage: "play.circle", action: {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
                dismiss()
            }))

            list.append(AyahAction(id: "playFrom", title: "Play From Ayah", systemImage: "play.circle.fill", action: {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
                dismiss()
            }))

            list.append(AyahAction(id: "repeat", title: "Repeat Ayah", systemImage: "repeat", kind: .repeatMenu))

            list.append(AyahAction(id: "customRange", title: "Play Custom Range", systemImage: "slider.horizontal.3", action: {
                settings.hapticFeedback()
                onRequestSheet?(.customRange)
            }))
        }

        // Select Text, Copy Ayah and Share Ayah are not tiles: they are the rows under the grid (Abu,
        // 2026-09-07: "make the share ayah button a full row below it") - select and copy side by
        // side, then share as the one filled button, where the things you most often came for are
        // the biggest targets on the sheet.
        return list
    }

    /// The text rows under the grid: Select Text (page mode's route to the list rows' select-and-copy
    /// sheet - the page's text view is deliberately non-selectable) beside Copy Ayah (in the
    /// remembered mode, the same "Copy Ayah" the list rows offer), then Share Ayah as the one filled,
    /// accent-colored button on the sheet.
    private var copyShareRows: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                textRow(title: "Select Text", systemImage: "highlighter", caption: nil) {
                    settings.hapticFeedback()
                    onRequestSheet?(.selectText)
                }

                textRow(title: "Copy Ayah", systemImage: "doc.on.doc", caption: ShareAyahSheet.copyModeLabel) {
                    settings.hapticFeedback()
                    ShareAyahSheet.copyAyahToPasteboard(surahNumber: surah.id, ayahNumber: ayah.id,
                                                        settings: settings, quranData: quranData)
                    dismiss()
                }
            }

            Button {
                settings.hapticFeedback()
                onRequestSheet?(.share)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Share Ayah")
                        .font(.headline)
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
    }

    /// "Keep Sheet Open", IN the sheet it is about (Abu, 2026-09-20; the switch already lived under
    /// Quran Settings > Reading, which is a long way from where the question comes up). The same
    /// stored setting, so either switch moves the other.
    private var keepSheetOpenRow: some View {
        Toggle(isOn: $settings.keepAyahSheetOpen.animation(.easeInOut)) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.stack")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(settings.accentColor.accent1)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Keep Sheet Open")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.accent1)
                    Text("Tafsir, Custom Range and the rest open on top of this sheet")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(settings.accentColor.accent1)
        .onChange(of: settings.keepAyahSheetOpen) { _ in settings.hapticFeedback() }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(settings.accentColor.accent1.opacity(0.10))
        )
    }

    /// One tinted row of the pair above the share button.
    private func textRow(title: String, systemImage: String, caption: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let caption {
                        Text(caption)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(settings.accentColor.accent1)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(settings.accentColor.accent1.opacity(0.10))
            )
        }
        .buttonStyle(.plain)
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
                        ForEach([2, 3, 5, 10, 15, 20], id: \.self) { count in
                            Button {
                                settings.hapticFeedback()
                                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, repeatCount: count)
                                dismiss()
                            } label: {
                                Label("Repeat \(count)×", systemImage: "\(count).circle")
                            }
                        }

                        // The ellipsis menu's Repeat Ayah submenu ends with the custom range too.
                        Button {
                            settings.hapticFeedback()
                            onRequestSheet?(.customRange)
                        } label: {
                            Label("Play Custom Range", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        actionTileLabel(item.title, systemImage: item.systemImage)
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

                    copyShareRows

                    keepSheetOpenRow

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
