import SwiftUI
import UIKit

#if os(iOS)

enum AyahSecondarySheet: String, Identifiable {
    case tafsir, qiraah, translations, customRange, note, share, selectText
    var id: String { rawValue }
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
                // per-ayah "Word by Word" pin; the page reader's cannot.
                AyahActionsSheet(surah: surah, ayah: ayah, onRequestSheet: onRequestSecondary,
                                 offersWordByWord: true)
                    .smallMediumSheetPresentation()

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
                secondary(kind, surah: surah, ayah: ayah)
                    .smallMediumSheetPresentation()
            }
        }
    }

    @ViewBuilder
    private func secondary(_ kind: AyahSecondarySheet, surah: Surah, ayah: Ayah) -> some View {
        switch kind {
        case .tafsir:
            AyahTafsirSheet(surahName: surah.nameTransliteration, surahNumber: surah.id, ayahNumber: ayah.id)

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

    /// Show the ayah as PLAIN standard text - full tashkeel and dots, no tajweed coloring, no beginner
    /// spacing - while the reader has any of those shaping it (user rule). Card-local; the reader keeps
    /// its own.
    @State private var showPlainText = false

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
            || (choices.tajweed && tajweedCanPaint)

        return Piece(
            ayah: ayah,
            segment: WordByWordSegment(
                displayText: display,
                preStyled: preStyled,
                ayahNumberArabic: ayah.idArabic,
                glosses: glosses,
                alwaysTappable: (settings.isHafsDisplay && glosses.isEmpty && !beginner) || wordTag != nil,
                highlightAllahNames: choices.highlightAllah
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
                // with. Deliberately smaller than the reader's own size: this is a reminder of which
                // ayah you touched, not a place to read from, and at full size it pushed every action
                // off the sheet.
                WordByWordText(
                    segments: pieces.map(\.segment),
                    fontName: settings.quranDisplayUsesCustomArabicFace ? settings.quranDisplayFontName : nil,
                    fontSize: min(CGFloat(settings.fontArabicSize) * 0.55, 20),
                    tapsRequired: 1,
                    selectedWord: selectedWord,
                    onSelectWord: { ref in select(ref, pieces: pieces) }
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Plain standard text on demand (user rule): with tajweed colors, hidden tashkeel, hidden
            // dots or beginner spacing shaping the run, one tap shows the ayah exactly as written -
            // full marks, no coloring - without touching the reader's settings.
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
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

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
    @Environment(\.dismiss) private var dismiss

    let surah: Surah
    let ayah: Ayah
    var onRequestSheet: ((AyahSecondarySheet) -> Void)?
    /// Whether the host can draw the inline study layout (the list reader), so the "Apply Settings"
    /// menu offers the per-ayah "Word by Word" pin.
    var offersWordByWord: Bool = false

    @State private var confirmRemoveNote = false

    private var isBookmarked: Bool { settings.bookmarkIndex(surah: surah.id, ayah: ayah.id) != nil }
    private var currentNote: String { settings.bookmarkNoteText(surah: surah.id, ayah: ayah.id) }
    private var currentHighlight: AyahHighlightColor? {
        settings.bookmarkHighlight(surah: surah.id, ayah: ayah.id)
    }
    private var canShowTafsir: Bool { settings.isHafsDisplay }
    /// The comparison tile is worth showing as soon as either comparison is available.
    private var canCompare: Bool { settings.showQiraahDetails || settings.isHafsDisplay }

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
                    if !settings.toggleBookmarkIfNoNoteLoss(surah: surah.id, ayah: ayah.id) {
                        confirmRemoveNote = true
                    }
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
            list.append(AyahAction(id: "tafsir", title: "Tafsir", systemImage: "text.book.closed", action: {
                settings.hapticFeedback()
                onRequestSheet?(.tafsir)
            }))
        }

        // Qiraah and translation are the same idea - see this ayah rendered another way - so they're one tile
        // holding both, rather than two that look like unrelated features.
        if canCompare {
            list.append(AyahAction(
                id: "comparison",
                title: "Comparison",
                systemImage: "arrow.left.arrow.right.square",
                kind: .comparisonMenu
            ))
        }

        if settings.isHafsDisplay {
            // Playback actions close the sheet: once the recitation starts you want to be looking at the page
            // (where the ayah is highlighted), not at the menu you started it from.
            list.append(AyahAction(id: "play", title: "Play Ayah", systemImage: "play.circle", action: {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
                dismiss()
            }))

            list.append(AyahAction(id: "playFrom", title: "Play From Here", systemImage: "play.circle.fill", action: {
                settings.hapticFeedback()
                quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
                dismiss()
            }))

            list.append(AyahAction(id: "repeat", title: "Repeat", systemImage: "repeat", kind: .repeatMenu))

            list.append(AyahAction(id: "customRange", title: "Custom Range", systemImage: "slider.horizontal.3", action: {
                settings.hapticFeedback()
                onRequestSheet?(.customRange)
            }))
        }

        // The page's text view is deliberately non-selectable (taps and presses are ayah gestures), so this
        // is page mode's route to the same select-and-copy sheet the list rows offer. It sits ahead of the
        // copy tiles because picking out part of an ayah is the finer-grained version of copying it whole.
        list.append(AyahAction(id: "selectText", title: "Select Text", systemImage: "highlighter", action: {
            settings.hapticFeedback()
            onRequestSheet?(.selectText)
        }))

        // Was a per-ayah "Beginner" toggle: now the whole "Apply Settings" menu (Abu, 2026-09-05) - beginner
        // spacing, tajweed, tashkeel, dots, Highlight Allah (and word by word in the list), several at once,
        // pinned to THIS ayah, with a reset when it differs from the app. The tile wears the accent while
        // the ayah pins anything, so page mode can answer "is this ayah different?" without opening it.
        if settings.showArabicText {
            let pinned = displayOverrides.hasOverride([HighlightedAyahRef(surahID: surah.id, ayahID: ayah.id)])
            list.append(AyahAction(
                id: "settings",
                title: "Apply Settings",
                systemImage: pinned ? "slider.horizontal.2.square" : "slider.horizontal.3",
                kind: .settingsMenu
            ))
        }

        // ONE copy tile, in the remembered mode - the same "Copy Ayah" the list rows offer (user rule).
        // This used to be two tiles, Copy Text and Copy Image, which is the one thing page mode did
        // differently from the list for no reason the reader could see.
        list.append(AyahAction(id: "copy", title: "Copy Ayah", systemImage: "doc.on.doc", action: {
            settings.hapticFeedback()
            ShareAyahSheet.copyAyahToPasteboard(surahNumber: surah.id, ayahNumber: ayah.id,
                                                settings: settings, quranData: quranData)
            dismiss()
        }))

        list.append(AyahAction(id: "share", title: "Share Ayah", systemImage: "square.and.arrow.up", action: {
            settings.hapticFeedback()
            onRequestSheet?(.share)
        }))

        return list
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
        .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                settings.hapticFeedback()
                settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(Settings.bookmarkNoteRemovalDialogMessage)
        }
    }
}

#endif
