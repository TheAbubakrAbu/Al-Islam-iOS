import SwiftUI
import UIKit

#if os(iOS)

enum AyahSecondarySheet: String, Identifiable {
    case tafsir, qiraah, translations, customRange, note, share, selectText
    var id: String { rawValue }
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
    /// The per-ayah beginner spacing, shared with the list rows and the page composer - so the tile below
    /// shows the ayah's real current state and toggling it re-composes the page behind the sheet.
    @ObservedObject private var beginnerOverrides = AyahBeginnerOverrides.shared
    @Environment(\.dismiss) private var dismiss

    let surah: Surah
    let ayah: Ayah
    var onRequestSheet: ((AyahSecondarySheet) -> Void)?

    @State private var confirmRemoveNote = false

    /// Word-by-word: the tapped word's card (the Hafs gloss + tajweed-rules card, or the riwayah word
    /// card), presented OVER this sheet so closing it returns to the actions.
    @State private var tappedWord: TappedWord?
    @State private var tappedRiwayahWord: RiwayahTappedWord?

    private var isBookmarked: Bool { settings.bookmarkIndex(surah: surah.id, ayah: ayah.id) != nil }
    private var currentNote: String { settings.bookmarkNoteText(surah: surah.id, ayah: ayah.id) }
    private var currentHighlight: AyahHighlightColor? {
        settings.bookmarkHighlight(surah: surah.id, ayah: ayah.id)
    }
    private var canShowTafsir: Bool { settings.isHafsDisplay }
    /// The comparison tile is worth showing as soon as either comparison is available.
    private var canCompare: Bool { settings.showQiraahDetails || settings.isHafsDisplay }

    /// The ayah itself, so the sheet says what you tapped rather than only naming it. Tajweed-coloured when
    /// that's on, and it carries the Arabic ayah marker the page does.
    @ViewBuilder
    private var ayahPreview: some View {
        let arabic = ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText)
        let showsTajweed = settings.showTajweedColors && settings.showArabicText && settings.isHafsDisplay
        let riwayahTajweedTag = settings.showTajweedColors && settings.showArabicText
            ? settings.riwayahTajweedPackTag : nil

        // The tajweed-colored preview text, when either store paints this ayah.
        let preStyled: AttributedString? = {
            if showsTajweed,
               let styled = TajweedStore.shared.attributedText(
                   surah: surah.id,
                   ayah: ayah.id,
                   text: ayah.displayArabicText(surahId: surah.id, clean: false),
                   displayText: arabic,
                   cleanDisplayText: settings.cleanArabicText,
                   beginnerSpacing: false
               ) {
                return styled
            }
            if let tag = riwayahTajweedTag,
               let styled = QiraahTajweedStore.shared.attributedText(
                   tag: tag, surah: surah.id, ayah: ayah.id, displayText: arabic,
                   hiddenRules: settings.riwayahTajweedHiddenRuleSet
               ) {
                return styled
            }
            return nil
        }()
        // Hafs: glosses lined up with the preview's tokens, so a tapped word opens the same meaning +
        // tajweed card the list rows offer. Empty (but still tappable) when the pack can't line up -
        // the card then shows the word's rules without a gloss.
        let glosses: [String] = settings.isHafsDisplay
            ? (WordByWordStore.shared.glosses(
                surah: surah.id, ayah: ayah.id,
                rawText: ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: nil),
                displayText: arabic
              ) ?? [])
            : []
        // Non-Hafs: a tapped word opens the riwayah word card instead (its rules + the Hafs
        // counterpart) - same rule as the list rows, only when the riwayah's pack is bundled.
        let riwayahWordTag: String? = {
            guard !settings.isHafsDisplay else { return nil }
            let tag = Settings.Riwayah.canonicalTag(settings.displayQiraahForArabic ?? "")
            return !tag.isEmpty && QiraahTajweedStore.shared.isAvailable(tag: tag) ? tag : nil
        }()

        VStack(spacing: 6) {
            // Rendered through the word-by-word TextKit view so every word is tappable (task: tap a word
            // in this sheet to open its card) - same colors and trailing alignment the plain Text had.
            // Deliberately smaller than the reader's own size: this is a reminder of which ayah you
            // tapped, not a place to read from, and at full size it pushed every action off the sheet.
            WordByWordText(
                displayText: arabic,
                preStyled: preStyled,
                fontName: settings.quranDisplayUsesCustomArabicFace ? settings.quranDisplayFontName : nil,
                fontSize: min(CGFloat(settings.fontArabicSize) * 0.55, 20),
                ayahNumberArabic: ayah.idArabic,
                glosses: glosses,
                alwaysTappable: (settings.isHafsDisplay && glosses.isEmpty) || riwayahWordTag != nil,
                selectedWord: tappedWord?.index ?? tappedRiwayahWord?.index,
                onSelectWord: { index in
                    let tokens = WordTokens.tokens(in: arabic)
                    guard tokens.indices.contains(index) else { return }
                    if let tag = riwayahWordTag {
                        tappedRiwayahWord = RiwayahTappedWord(
                            index: index, word: tokens[index], total: tokens.count, tag: tag
                        )
                    } else if settings.isHafsDisplay {
                        tappedWord = TappedWord(
                            index: index,
                            word: tokens[index],
                            meaning: glosses.indices.contains(index) ? glosses[index] : "",
                            total: glosses.isEmpty ? tokens.count : glosses.count
                        )
                    }
                }
            )
            .frame(maxWidth: .infinity, alignment: .trailing)

            // The same reference format every ayah sheet uses, plus the ayah's ACTUAL text in the active
            // translation (not just the translation's name).
            VStack(spacing: 3) {
                Text(ayahSheetTitle(surahNumber: surah.id, ayahNumber: ayah.id))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let translation = currentTranslationText(for: ayah) {
                    Text(translation)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // The bookmark note, right under the ayah it belongs to - it existed only behind "Edit Note",
            // so the one place you tapped the ayah never showed you what you'd written about it.
            if !currentNote.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundStyle(settings.accentColor.accent1)
                        .padding(.top, 1)

                    Text(currentNote)
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
        .padding(.vertical, 2)
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
        enum Kind { case button, repeatMenu, comparisonMenu, highlightMenu }

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

        // The per-ayah letter spacing, offered here exactly as the list rows offer it in their context menu -
        // page mode had no route to it at all. Hidden while the GLOBAL beginner mode is on, since then every
        // ayah is already spaced and the toggle would do nothing (same rule as the list's).
        if settings.showArabicText && !settings.beginnerMode {
            let isBeginner = beginnerOverrides.contains(surah: surah.id, ayah: ayah.id)
            list.append(AyahAction(
                id: "beginner",
                title: "Beginner",
                systemImage: isBeginner ? "textformat.size.larger.ar" : "textformat.size.ar",
                action: {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        beginnerOverrides.toggle(surah: surah.id, ayah: ayah.id)
                    }
                }
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
                    ayahPreview
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.primary.opacity(0.05))
                        )

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
        // The tapped word's card, presented over this sheet (the one deliberate sheet-on-sheet here:
        // closing the card should land you back on the actions, mid-exploration). `item:` so tapping a
        // different word re-presents with the new word.
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
    }
}

#endif
