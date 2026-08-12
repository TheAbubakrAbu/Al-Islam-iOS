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

    private var isBookmarked: Bool { settings.bookmarkIndex(surah: surah.id, ayah: ayah.id) != nil }
    private var currentNote: String { settings.bookmarkNoteText(surah: surah.id, ayah: ayah.id) }
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

        VStack(spacing: 6) {
            Group {
                if showsTajweed,
                   let styled = TajweedStore.shared.attributedText(
                       surah: surah.id,
                       ayah: ayah.id,
                       text: ayah.displayArabicText(surahId: surah.id, clean: false),
                       displayText: arabic,
                       cleanDisplayText: settings.cleanArabicText,
                       beginnerSpacing: false
                   ) {
                    Text(styled) + Text(" \(ayah.idArabic)").foregroundColor(settings.accentColor.accent1)
                } else if let tag = riwayahTajweedTag,
                          let styled = QiraahTajweedStore.shared.attributedText(
                              tag: tag, surah: surah.id, ayah: ayah.id, displayText: arabic,
                              hiddenRules: settings.riwayahTajweedHiddenRuleSet
                          ) {
                    Text(styled) + Text(" \(ayah.idArabic)").foregroundColor(settings.accentColor.accent1)
                } else {
                    Text(arabic) + Text(" \(ayah.idArabic)").foregroundColor(settings.accentColor.accent1)
                }
            }
            // Deliberately smaller than the reader's own size: this is a reminder of which ayah you tapped,
            // not a place to read from, and at full size it pushed every action off the sheet.
            .font(Font.arabic(settings.quranDisplayFontName, size: min(settings.fontArabicSize * 0.55, 20)))
            .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
            // NO `.environment(\.layoutDirection, .rightToLeft)` here - in an RTL context `.trailing`
            // resolves to the LEFT edge, so that override made this exact modifier left-align wrapped
            // Arabic (the "still not trailing" bug). The bidi algorithm already lays the Arabic out
            // right-to-left from the characters themselves; what we want is the visual right edge, which
            // in the app's LTR layout is `.trailing` - on both the wrapped lines AND the frame (a
            // max-width frame with no alignment CENTERS a short single-line ayah).
            .multilineTextAlignment(.trailing)
            .lineSpacing(4)
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

    private func actionTileLabel(_ title: String, systemImage: String, destructive: Bool = false) -> some View {
        VStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))

            Text(title)
                .font(.caption2.weight(.medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(destructive ? Color.red : settings.accentColor.accent1)
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill((destructive ? Color.red : settings.accentColor.accent1).opacity(0.10))
        )
    }

    /// One entry in the grid. `repeatMenu` is the odd one out - it opens a menu rather than firing an action - 
    /// so it carries no `action`.
    private struct AyahAction: Identifiable {
        /// The two tiles that open a menu instead of firing an action: the repeat count and the comparison
        /// (qiraah vs translation) both need a choice before anything happens.
        enum Kind { case button, repeatMenu, comparisonMenu }

        let id: String
        let title: String
        let systemImage: String
        var kind: Kind = .button
        var destructive = false
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

        list.append(AyahAction(id: "share", title: "Share", systemImage: "square.and.arrow.up", action: {
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
    }
}

#endif
