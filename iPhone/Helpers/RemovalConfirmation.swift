// The dialog is iOS-only: the file compiles in the Watch target too (registered like FocusOverlay.swift),
// where the hadith stores it extends don't exist and the shared Quran call sites get the plain toggles
// (the watch fallback at the bottom of the file).
#if os(iOS)
import SwiftUI
import UIKit

// MARK: - The topmost view controller

/// Where a UIKit presentation from SwiftUI lands: the key window's root, then down through whatever it
/// is presenting (a sheet, a share sheet, another alert), so the new controller sits on top of what
/// the user is looking at instead of failing underneath it.
@MainActor
func topmostViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first { $0.activationState == .foregroundActive }

    guard let window = scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first,
          var top = window.rootViewController else { return nil }

    while let presented = top.presentedViewController { top = presented }
    return top
}

// MARK: - Removing a saved mark always asks first

/// The one question every unbookmark and unfavorite asks before it happens (Abu, 2026-09-07: "if you
/// ever want to unbookmark or unfavorite anything have it be a confirmation dialog"). Presented
/// UIKit-side on the topmost view controller, the `presentSystemShareSheet` route, so a context menu
/// item, a swipe action, a sheet's tile and a grid corner all reach the same dialog without each row
/// carrying its own `.confirmationDialog` state. Adding a mark never asks.
@MainActor
enum RemovalConfirmation {
    static func present(title: String, message: String, confirmTitle: String, onConfirm: @escaping () -> Void) {
        guard let top = topmostViewController() else {
            withAnimation(.easeInOut) { onConfirm() }
            return
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: confirmTitle, style: .destructive) { _ in
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut) { onConfirm() }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        // The app's accent on the sheet's buttons, the way SwiftUI's own confirmation dialogs get it.
        alert.view.tintColor = UIColor(Settings.shared.accentColor.color)
        // iPad requires an anchor or the popover asserts on presentation. iPhone gets none: the sheet
        // slides up from the bottom with its Cancel button, whereas an anchor made iOS 26 float it
        // mid-screen as a popover (verified on the iPhone 17 Pro simulator).
        if UIDevice.current.userInterfaceIdiom != .phone, let popover = alert.popoverPresentationController {
            popover.sourceView = top.view
            popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        top.present(alert, animated: true)
    }
}

// MARK: - Ayah bookmarks and surah favorites

extension Settings {
    /// Bookmarks the ayah, or asks before removing an existing bookmark. The note, when there is one,
    /// goes with the bookmark, and the dialog says so.
    @MainActor
    func toggleBookmarkOrConfirm(surah: Int, ayah: Int) {
        guard isBookmarked(surah: surah, ayah: ayah) else {
            toggleBookmark(surah: surah, ayah: ayah)
            return
        }

        let name = QuranData.shared.surah(surah)?.nameTransliteration ?? "Surah \(surah)"
        let hasNote = bookmarkHasNote(surah: surah, ayah: ayah)
        RemovalConfirmation.present(
            title: hasNote ? "Remove bookmark and delete note?" : "Remove bookmark?",
            message: hasNote
                ? "\(name) \(surah):\(ayah) will be removed from your bookmarks, and its note will be deleted."
                : "\(name) \(surah):\(ayah) will be removed from your bookmarks.",
            confirmTitle: "Remove Bookmark"
        ) { [weak self] in
            self?.toggleBookmark(surah: surah, ayah: ayah)
        }
    }

    /// Favorites the surah, or asks before removing it from the favorites.
    @MainActor
    func toggleSurahFavoriteOrConfirm(surah: Int) {
        guard isSurahFavorite(surah: surah) else {
            toggleSurahFavorite(surah: surah)
            return
        }

        let name = QuranData.shared.surah(surah)?.nameTransliteration ?? "Surah \(surah)"
        RemovalConfirmation.present(
            title: "Remove from favorites?",
            message: "\(name) will be removed from your favorite surahs.",
            confirmTitle: "Remove from Favorites"
        ) { [weak self] in
            self?.toggleSurahFavorite(surah: surah)
        }
    }
}

// MARK: - Hadith bookmarks and favorites

extension HadithUserData {
    /// Bookmarks the hadith, or asks before removing an existing bookmark (with its note, when it has
    /// one). `reference` is the citation the dialog names; the saved bookmark's own when not given, so
    /// the placeholder hadiths the bookmark rows build (identity fields only) still read correctly.
    func toggleBookmarkOrConfirm(book: HadithCatalogBook, hadith: HadithBookData.Hadith, reference: String? = nil) {
        guard isBookmarked(slug: book.slug, idInBook: hadith.idInBook) else {
            toggleBookmark(book: book, hadith: hadith)
            return
        }

        let saved = bookmarks.first { $0.slug == book.slug && $0.idInBook == hadith.idInBook }
        let name = reference ?? saved?.reference ?? "\(book.englishTitle) \(hadith.displayNumber)"
        let hasNote = note(slug: book.slug, idInBook: hadith.idInBook) != nil
        RemovalConfirmation.present(
            title: hasNote ? "Remove bookmark and delete note?" : "Remove bookmark?",
            message: hasNote
                ? "\(name) will be removed from your bookmarks, and its note will be deleted."
                : "\(name) will be removed from your bookmarks.",
            confirmTitle: "Remove Bookmark"
        ) { [weak self] in
            self?.toggleBookmark(book: book, hadith: hadith)
        }
    }

    /// Favorites the book, or asks before removing it from the favorites.
    func toggleFavoriteOrConfirm(_ book: HadithCatalogBook) {
        guard isFavorite(book.slug) else {
            toggleFavorite(book.slug)
            return
        }

        RemovalConfirmation.present(
            title: "Remove from favorites?",
            message: "\(book.englishTitle) will be removed from your favorite books.",
            confirmTitle: "Remove from Favorites"
        ) { [weak self] in
            self?.toggleFavorite(book.slug)
        }
    }

    /// Favorites the chapter, or asks before removing it from the favorites.
    func toggleChapterFavoriteOrConfirm(book: HadithCatalogBook, chapter: HadithBookData.Chapter) {
        guard isChapterFavorite(slug: book.slug, chapterId: chapter.id) else {
            toggleChapterFavorite(slug: book.slug, chapterId: chapter.id)
            return
        }

        let name = chapter.english.isEmpty ? "This chapter of \(book.englishTitle)" : chapter.english
        RemovalConfirmation.present(
            title: "Remove from favorites?",
            message: "\(name) will be removed from your favorite chapters.",
            confirmTitle: "Remove from Favorites"
        ) { [weak self] in
            self?.toggleChapterFavorite(slug: book.slug, chapterId: chapter.id)
        }
    }
}

extension HadithStore {
    /// The store's forwards for the asking toggles, so call sites that hold the store keep their shape.
    func toggleBookmarkOrConfirm(book: HadithCatalogBook, hadith: HadithBookData.Hadith, reference: String? = nil) {
        HadithUserData.shared.toggleBookmarkOrConfirm(book: book, hadith: hadith, reference: reference)
    }

    func toggleFavoriteOrConfirm(_ book: HadithCatalogBook) {
        HadithUserData.shared.toggleFavoriteOrConfirm(book)
    }

    func toggleChapterFavoriteOrConfirm(book: HadithCatalogBook, chapter: HadithBookData.Chapter) {
        HadithUserData.shared.toggleChapterFavoriteOrConfirm(book: book, chapter: chapter)
    }
}
#else
import SwiftUI

// MARK: - watchOS: the same entry points, no dialog

/// The watch's surah header star and the shared Quran rows call these names too; there the toggle is
/// immediate - the confirmation is an iPhone rule (its bookmark and favorite screens), and the watch
/// only ever offers the header star.
extension Settings {
    func toggleBookmarkOrConfirm(surah: Int, ayah: Int) {
        toggleBookmark(surah: surah, ayah: ayah)
    }

    func toggleSurahFavoriteOrConfirm(surah: Int) {
        toggleSurahFavorite(surah: surah)
    }
}
#endif
