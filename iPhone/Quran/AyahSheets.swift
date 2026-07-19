import SwiftUI
import UIKit

#if os(iOS)

enum AyahSecondarySheet: String, Identifiable {
    case tafsir, qiraah, translations, customRange, note, share
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
                } else {
                    Text(arabic) + Text(" \(ayah.idArabic)").foregroundColor(settings.accentColor.accent1)
                }
            }
            // Deliberately smaller than the reader's own size: this is a reminder of which ayah you tapped,
            // not a place to read from, and at full size it pushed every action off the sheet.
            .font(Font.arabic(settings.quranDisplayFontName, size: min(settings.fontArabicSize * 0.55, 20)))
            .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
            .multilineTextAlignment(.trailing)
            .lineSpacing(4)
            .environment(\.layoutDirection, .rightToLeft)
            .frame(maxWidth: .infinity)

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

        list.append(AyahAction(id: "copy", title: "Copy", systemImage: "doc.on.doc", action: {
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

    /// Three across, unless that would leave a last row holding a single tile - a 10th tile stranded on its own
    /// row reads as a mistake. In that case two across (which divides evenly), else four.
    private var columnCount: Int {
        let count = actions.count
        for candidate in [3, 2, 4] where count % candidate != 1 {
            return candidate
        }
        return 3
    }

    private var actionGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: columnCount),
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
        }
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
