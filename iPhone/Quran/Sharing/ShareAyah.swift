#if os(iOS)
import SwiftUI

// `ActionMode`, `ShareAyahRender` and the Allah ink (`ShareAllahInk`) are in
// iPhone/Helpers/UI/ShareSupport.swift, shared with the hadith and Name of Allah sheets.

/// The share sheet's Smart Ayah Matching switch (`smartAyahMatching` below), and what the static Copy
/// Image path reads for the same answer: one key, so the two can never drift apart.
private let qiraahSmartComparisonKey = "qiraahSmartComparison"

/// One ayah of a share, resolved on the main actor for the render queue (`ShareAyahSheet.shareEntries`):
/// the sheet shares one from the ayah menus and the actions sheet, several from the reader's Select
/// Ayahs bar (Abu, 2026-11-08: "support sharing multiple ayahs in one screen").
struct ShareAyahEntry {
    let surah: Surah
    /// The ayah whose ARABIC is shared, numbered as `arabicQiraah` numbers it.
    let ayah: Ayah
    /// The Hafs ayah whose transliteration and translations are shared (the sheet's smart matching).
    let hafsAyah: Ayah
    /// The rest of a split ayah, joined after `ayah` (`ShareAyahSheet.arabicSplitTail`).
    let tail: [Ayah]
    /// The riwayah the Arabic is read in: the sheet's, or Hafs where that riwayah does not number these words.
    let arabicQiraah: String
}

struct ShareAyahSheet: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var quranData = QuranData.shared

    @Environment(\.presentationMode) private var presentationMode

    /// The ayahs this sheet shares, in reading order: one from the ayah menus and the actions sheet,
    /// several from the reader's Select Ayahs bar. Never empty.
    let refs: [HighlightedAyahRef]
    /// The first ayah: the single-ayah paths (the note, the smart-matching anchor) and the title's start.
    var surahNumber: Int { refs[0].surahID }
    var ayahNumber: Int { refs[0].ayahID }
    /// Called as the sheet closes itself after a copy or a completed share, never on a cancel or the X.
    /// The ayah actions sheet this one may be stacked on closes too (`AyahSecondarySheetContent`).
    var onShared: (() -> Void)? = nil

    /// The most ayahs one image card draws. A longer selection shares as text: a card of thirty ayahs
    /// of al-Baqarah with one translation is already some 5,000 pt tall.
    static let imageAyahLimit = 30

    init(surahNumber: Int, ayahNumber: Int, onShared: (() -> Void)? = nil) {
        self.init(refs: [HighlightedAyahRef(surahID: surahNumber, ayahID: ayahNumber)], onShared: onShared)
    }

    /// Several ayahs on one card. Sorted into reading order whatever order they were picked in.
    init(refs: [HighlightedAyahRef], onShared: (() -> Void)? = nil) {
        precondition(!refs.isEmpty, "ShareAyahSheet needs at least one ayah")
        self.refs = refs.sorted { ($0.surahID, $0.ayahID) < ($1.surahID, $1.ayahID) }
        self.onShared = onShared
    }

    @State private var shareSettings = ShareSettings()

    @AppStorage("shareIncludeRiwayah") private var shareIncludeRiwayah = false
    @AppStorage("shareArabicFont") private var storedShareArabicFont = ""
    @AppStorage("shareAyahLastActionMode") private var storedActionModeRaw: String = ActionMode.image.rawValue
    @AppStorage("copyAyahArabic") private var storedCopyArabic = true
    @AppStorage("copyAyahTransliteration") private var storedCopyTransliteration = false
    @AppStorage("copyAyahEnglishSaheeh") private var storedCopyEnglishSaheeh = false
    @AppStorage("copyAyahEnglishMustafa") private var storedCopyEnglishMustafa = false
    /// The image card's design (see `ShareBackdrop`); Copy Image from the actions sheet follows it.
    @AppStorage(ShareBackdrop.storageKey) private var storedBackdrop = ShareBackdrop.classic.rawValue
    @State private var actionMode: ActionMode = .image

    // The sheet's own riwayah, seeded from the reading view's, so switching here never disturbs the reader.
    @State private var shareQiraah: String = Settings.normalizeLegacyRiwayahTag(Settings.shared.displayQiraah)

    // The reader's riwayah at open time - the numbering `ayahNumber` was tapped under. Smart matching
    // anchors through Hafs from this origin; `shareQiraah` moves with the picker, this never does.
    private let originQiraah: String = Settings.normalizeLegacyRiwayahTag(Settings.shared.displayQiraah)

    // Same preference the comparison sheet stores: follow the WORDS across riwayat (numbering differs),
    // not the raw number.
    @AppStorage(qiraahSmartComparisonKey) private var smartAyahMatching = true

    @State private var didInit = false
    @State private var didFinishInitialSetup = false

    @State private var generatedImage: UIImage?
    @State private var activityItems: [Any] = []
    @State private var showingActivityView = false
    /// Whether the last system share actually completed (vs. cancelled) - see the activity sheet below.
    @State private var didCompleteShare = false
    @State private var includeNote: Bool = false
    @State private var isGeneratingImage = false
    @State private var isSharing = false
    @State private var imageGenerationID = 0
    private static let shareImageQueue = DispatchQueue(label: "app.shareAyah.imageGeneration", qos: .userInitiated)

    private func fetchNote() -> String? {
        // A note belongs to one ayah; a card of several draws none.
        guard !isMultiple else { return nil }
        if let idx = settings.bookmarkedAyahs.firstIndex(where: {
            $0.surah == surahNumber && $0.ayah == ayahNumber
        }) {
            let trimmed = settings.bookmarkedAyahs[idx].note?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (trimmed?.isEmpty == true) ? nil : trimmed
        }
        return nil
    }

    private var noteText: String? {
        guard let n = fetchNote()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !n.isEmpty else { return nil }
        return n
    }

    private var surah: Surah? { quranData.surah(surahNumber) }

    /// Whether this sheet shares more than one ayah (the reader's Select Ayahs bar).
    private var isMultiple: Bool { refs.count > 1 }
    private var imageAllowed: Bool { refs.count <= Self.imageAyahLimit }

    // MARK: Resolving one ayah
    //
    // Smart matching, the split tail and the translation's Hafs anchor, each for the ref it is asked
    // about: the single-ayah paths read `refs[0]` through the wrappers below, the card of several
    // resolves every ref in `shareEntries`.

    /// The ayah's Hafs anchor (identity when the reader was on Hafs or a Kufi-counted riwayah).
    private func anchorHafsAyah(for ref: HighlightedAyahRef) -> Int {
        QiraahComparison.hafsAnchor(surahID: ref.surahID, ayahNumber: ref.ayahID, tag: originQiraah, quranData: quranData)
    }

    /// The ayah number whose ARABIC the sheet serves. Smart matching resolves the share riwayah's own
    /// number for the tapped words via the Hafs anchor; off, it is the tapped number as-is (the old
    /// direct read, which for merged/shifted numbering shows whatever verse sits at that number).
    private func resolvedAyahNumber(for ref: HighlightedAyahRef) -> Int {
        guard smartAyahMatching else { return ref.ayahID }
        let anchor = anchorHafsAyah(for: ref)
        let tag = Settings.Riwayah.canonicalTag(shareQiraah)
        if tag.isEmpty { return anchor }
        guard let alignment = QiraahComparison.alignment(surahID: ref.surahID, tag: tag, quranData: quranData) else {
            return ref.ayahID
        }
        // Unnumbered there (`anchorUnnumberedInShareQiraah`): the Hafs ayah, read as Hafs.
        return alignment.riwayahNumberForHafs[anchor] ?? anchor
    }

    /// Smart matching finds the tapped words unnumbered in the share riwayah: its alignment maps their
    /// Hafs ayah to nothing (the basmalah in the Madani count of al-Fatiha), which `QiraahAyahResolver`
    /// calls unavailable. The sheet then shares the Hafs words, its fallback for any ayah a riwayah
    /// does not have, rather than that riwayah's unrelated ayah under the same number (Warsh 1:1's
    /// al-hamd under the basmalah's translation).
    private func anchorUnnumberedInShareQiraah(for ref: HighlightedAyahRef) -> Bool {
        guard smartAyahMatching else { return false }
        let tag = Settings.Riwayah.canonicalTag(shareQiraah)
        guard !tag.isEmpty,
              let alignment = QiraahComparison.alignment(surahID: ref.surahID, tag: tag, quranData: quranData) else { return false }
        return alignment.riwayahNumberForHafs[anchorHafsAyah(for: ref)] == nil
    }

    /// The riwayah the shared Arabic (and its riwayah line) is read in: the sheet's, or Hafs for the
    /// case above.
    private func arabicQiraah(for ref: HighlightedAyahRef) -> String {
        anchorUnnumberedInShareQiraah(for: ref) ? Settings.Riwayah.hafsTag : shareQiraah
    }

    /// The rest of a split ayah: the share riwayah's ayahs after `ayah` that carry the same ONE Hafs
    /// ayah (al-Fatiha's last ayah is two in the Madani count), shared after it as
    /// `QiraahAyahResolver` joins them, so the Arabic covers the whole translation. Empty elsewhere.
    private func arabicSplitTail(for ref: HighlightedAyahRef) -> [Ayah] {
        guard smartAyahMatching, let surah = quranData.surah(ref.surahID), let first = ayah(for: ref) else { return [] }
        let tag = Settings.Riwayah.canonicalTag(arabicQiraah(for: ref))
        guard !tag.isEmpty,
              let alignment = QiraahComparison.alignment(surahID: ref.surahID, tag: tag, quranData: quranData) else { return [] }
        let anchor = anchorHafsAyah(for: ref)
        var tail: [Ayah] = []
        var last = first.id
        while alignment.hafsRangeForRiwayah[last + 1] == anchor...anchor,
              let piece = surah.ayahs.first(where: { $0.id == last + 1 }),
              piece.existsInQiraah(tag, surahID: ref.surahID) {
            tail.append(piece)
            last += 1
        }
        return tail
    }

    private func ayah(for ref: HighlightedAyahRef) -> Ayah? {
        let number = resolvedAyahNumber(for: ref)
        return quranData.surah(ref.surahID)?.ayahs.first(where: { $0.id == number })
    }

    /// Hafs-keyed companions (transliteration, both translations) read from the Hafs anchor when smart
    /// matching is on, so the English always matches the words being shared even when the Arabic sits
    /// under a different riwayah number.
    private func translationAyah(for ref: HighlightedAyahRef) -> Ayah? {
        guard smartAyahMatching else { return ayah(for: ref) }
        let anchor = anchorHafsAyah(for: ref)
        return quranData.surah(ref.surahID)?.ayahs.first(where: { $0.id == anchor }) ?? ayah(for: ref)
    }

    private func ayahExistsInShareQiraah(for ref: HighlightedAyahRef) -> Bool {
        ayah(for: ref)?.existsInQiraah(shareQiraah, surahID: ref.surahID) ?? true
    }

    /// Every ayah of the share, resolved here on the main actor (the alignment cache is main-actor
    /// state the render queue must never touch), in reading order; a ref the data cannot serve is
    /// left out.
    private var shareEntries: [ShareAyahEntry] {
        refs.compactMap { ref in
            guard let surah = quranData.surah(ref.surahID), let ayah = ayah(for: ref) else { return nil }
            return ShareAyahEntry(surah: surah, ayah: ayah, hafsAyah: translationAyah(for: ref) ?? ayah,
                                  tail: arabicSplitTail(for: ref), arabicQiraah: arabicQiraah(for: ref))
        }
    }

    // The single-ayah forms, over the first ref: what the sheet's single-ayah paths read.
    private var firstRef: HighlightedAyahRef { refs[0] }
    private var anchorHafsAyah: Int { anchorHafsAyah(for: firstRef) }
    private var resolvedAyahNumber: Int { resolvedAyahNumber(for: firstRef) }
    private var anchorUnnumberedInShareQiraah: Bool { anchorUnnumberedInShareQiraah(for: firstRef) }
    private var arabicQiraah: String { arabicQiraah(for: firstRef) }
    private var arabicSplitTail: [Ayah] { arabicSplitTail(for: firstRef) }
    private var ayah: Ayah? { ayah(for: firstRef) }
    private var translationAyah: Ayah? { translationAyah(for: firstRef) }

    // Tajweed data is Hafs-only, so it keys off the sheet's riwayah, not the reader's.
    private var isHafsShare: Bool { shareQiraah.isEmpty }

    /// Smart Ayah Matching only matters once the sheet's riwayah has moved away from the one the ayah
    /// was tapped under - on the same riwayah the resolution is the identity, so the toggle is noise.
    private var shareQiraahDiffersFromOrigin: Bool {
        Settings.Riwayah.canonicalTag(shareQiraah) != Settings.Riwayah.canonicalTag(originQiraah)
    }
    private var ayahExistsInShareQiraah: Bool { ayah?.existsInQiraah(shareQiraah, surahID: surahNumber) ?? true }
    private var effectiveCleanArabic: Bool { shareSettings.cleanArabic }
    private var effectiveHideArabicDots: Bool { shareSettings.hideArabicDots }
    private var canShowHideArabicDotsToggle: Bool {
        shareSettings.cleanArabic || settings.cleanArabicText || settings.removeArabicDots || shareSettings.hideArabicDots
    }

    private func updatedShareSettings(
        arabic: Bool? = nil,
        transliteration: Bool? = nil,
        englishSaheeh: Bool? = nil,
        englishMustafa: Bool? = nil,
        includeQiraah: Bool? = nil,
        shareArabicFont: String? = nil,
        cleanArabic: Bool? = nil,
        hideArabicDots: Bool? = nil,
        showTajweed: Bool? = nil
    ) -> ShareSettings {
        ShareSettings(
            arabic: arabic ?? shareSettings.arabic,
            transliteration: transliteration ?? shareSettings.transliteration,
            englishSaheeh: englishSaheeh ?? shareSettings.englishSaheeh,
            englishMustafa: englishMustafa ?? shareSettings.englishMustafa,
            includeQiraah: includeQiraah ?? shareSettings.includeQiraah,
            shareArabicFont: shareArabicFont ?? shareSettings.shareArabicFont,
            cleanArabic: cleanArabic ?? shareSettings.cleanArabic,
            hideArabicDots: hideArabicDots ?? shareSettings.hideArabicDots,
            showTajweed: showTajweed ?? shareSettings.showTajweed
        )
    }

    private func persistentCopyBinding(
        get: @escaping () -> Bool,
        set: @escaping (Bool) -> Void,
        update: @escaping (Bool) -> ShareSettings
    ) -> Binding<Bool> {
        Binding(
            get: get,
            set: { newValue in
                set(newValue)
                shareSettings = update(newValue)
            }
        )
    }

    private static func shareArabicText(
        surah: Surah,
        ayah: Ayah,
        cleanArabic: Bool,
        hideArabicDots: Bool,
        qiraahOverride: String? = nil,
        tail: [Ayah] = []
    ) -> String {
        // The full dotted text (`removeDots: false`), then this card's own switches: the reader's
        // global Hide Dots must not decide for the share sheet's. `tail` is the rest of a split ayah
        // (`arabicSplitTail`), joined after it.
        var base = ([ayah] + tail)
            .map { $0.displayArabicText(surahId: surah.id, clean: false, removeDots: false, qiraahOverride: qiraahOverride) }
            .joined(separator: " ")
        if cleanArabic {
            if surah.id == 1 && ayah.id == 1 && Ayah.opensWithTaawwudh(base) {
                base = Ayah.bismillahCleanArabic
            } else {
                base = base.removingArabicDiacriticsAndSigns
            }
        }
        return hideArabicDots ? base.removingArabicDots : base
    }

    private static func shareRawArabicText(surah: Surah, ayah: Ayah) -> String {
        ayah.rawArabicText(surahId: surah.id)
    }

    private static func allahHighlightRanges(in source: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []

        var englishStart = source.startIndex
        while englishStart < source.endIndex,
              let match = source.range(
                of: "Allah",
                options: [.caseInsensitive, .diacriticInsensitive],
                range: englishStart..<source.endIndex
              ) {
            ranges.append(match)
            englishStart = match.upperBound
        }

        // One scanner for the whole app: `HighlightedSnippet` owns the rules for what counts as the
        // name (see `arabicAllahRange`), and the share card must paint exactly what the reader paints.
        ranges.append(contentsOf: HighlightedSnippet.arabicAllahRanges(in: source))

        return ranges
    }

    // Internal (not private): HadithShareSheet applies the SAME Allah-name reddening to its share card
    // and text preview, so the two share surfaces render the names identically.
    /// `color`: the share card passes its backdrop's own Allah ink (`ShareBackdrop.Palette.allah`).
    static func applyAllahHighlight(to attributed: NSMutableAttributedString, source: String, enabled: Bool,
                                    color: UIColor = .red, plainColor: UIColor? = nil) {
        ShareAllahInk.apply(to: attributed, source: source, enabled: enabled, color: color, plainColor: plainColor)
    }

    private static func allahHighlightedAttributedString(
        _ string: String,
        attributes: [NSAttributedString.Key: Any],
        enabled: Bool,
        color: UIColor = .red
    ) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: string, attributes: attributes)
        applyAllahHighlight(to: attributed, source: string, enabled: enabled, color: color)
        return attributed
    }

    static func allahHighlightedSwiftUIText(_ string: String, baseColor: Color, enabled: Bool) -> AttributedString {
        ShareAllahInk.swiftUIText(string, baseColor: baseColor, enabled: enabled)
    }

    private static func shareArabicImageAttributedText(
        surah: Surah,
        ayah: Ayah,
        shareSettings: ShareSettings,
        settings: Settings,
        qiraah: String,
        font: UIFont,
        paragraphStyle: NSParagraphStyle,
        textColor: UIColor,
        allahColor: UIColor = .red
    ) -> NSAttributedString? {
        guard shareSettings.showTajweed,
              qiraah.isEmpty else {
            return nil
        }

        let rawText = ayah.rawArabicText(surahId: surah.id, qiraahOverride: qiraah)
        let displayText = Self.shareArabicText(
            surah: surah,
            ayah: ayah,
            cleanArabic: shareSettings.cleanArabic,
            hideArabicDots: shareSettings.hideArabicDots,
            qiraahOverride: qiraah
        )
        guard let tajweed = TajweedStore.shared.attributedText(
            surah: surah.id,
            ayah: ayah.id,
            text: rawText,
            displayText: displayText,
            cleanDisplayText: shareSettings.cleanArabic,
            // The card's own switch only, the one `displayText` was built with: mixing in the
            // reader's global flag projected a dotless string onto a dotted card.
            removeArabicDots: shareSettings.hideArabicDots
        ) else {
            return nil
        }

        let nsTajweed = NSAttributedString(tajweed)
        let attributed = NSMutableAttributedString(attributedString: nsTajweed)
        attributed.addAttributes(
            [.font: font, .paragraphStyle: paragraphStyle] as [NSAttributedString.Key: Any],
            range: NSRange(location: 0, length: attributed.length)
        )
        // A FIXED trait, not `.current`: this runs on the share-image queue, where `UITraitCollection.current`
        // is thread-local and unspecified (it read as default/light regardless of the app's appearance). The
        // comparison only needs both sides resolved under the SAME traits to identify "label-colored" runs,
        // so any deterministic choice is correct - and it no longer reads main-thread-only UIKit state.
        let comparisonTraits = UITraitCollection(userInterfaceStyle: .light)
        let labelColor = UIColor.label.resolvedColor(with: comparisonTraits)
        attributed.enumerateAttribute(NSAttributedString.Key.foregroundColor, in: NSRange(location: 0, length: attributed.length)) { value, range, _ in
            guard let color = value as? UIColor else {
                attributed.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: range)
                return
            }
            let resolved = color.resolvedColor(with: comparisonTraits)
            if resolved.isVisuallyEqual(to: labelColor) {
                attributed.addAttribute(NSAttributedString.Key.foregroundColor, value: textColor, range: range)
            }
        }
        // Every plain run is `textColor` by now, so any other color on the name is a tajweed rule's.
        Self.applyAllahHighlight(to: attributed, source: displayText, enabled: settings.highlightAllahNames,
                                 color: allahColor, plainColor: textColor)
        return attributed
    }

    private var shareText: String {
        if isMultiple {
            return Self.multiShareText(entries: shareEntries, shareSettings: shareSettings, settings: settings,
                                       includeRiwayah: settings.showQiraahDetails && shareSettings.includeQiraah,
                                       riwayahTag: arabicQiraah)
        }
        guard let surah = surah, let ayah = ayah else { return "" }
        let hafsAyah = translationAyah ?? ayah

        var s = ""

        @inline(__always) func sepIfNeeded() {
            if !s.isEmpty { s += "\n\n" }
        }

        @inline(__always) func appendBlock(label: String?, text: String?) {
            guard let text = text, !text.isEmpty else { return }
            sepIfNeeded()
            if let label = label, !label.isEmpty {
                s += "\(label)\n"
            }
            s += text
        }

        // Arabic
        if shareSettings.arabic {
            let header: String? = settings.showAyahInformation
                ? "[\(Settings.shared.cleanedQuranArabic(surah.nameArabic)) \(surah.idArabic):\(ayah.idArabic)]"
                : nil

            let arabicText = Self.shareArabicText(
                surah: surah,
                ayah: ayah,
                cleanArabic: effectiveCleanArabic,
                hideArabicDots: effectiveHideArabicDots,
                qiraahOverride: arabicQiraah,
                tail: arabicSplitTail
            )
            appendBlock(
                label: header,
                text: (settings.showAyahInformation ? arabicText : "\(arabicText) \(ayah.idArabic)")
            )
        }

        // Transliteration (always offered; the text itself follows Hafs numbering)
        if shareSettings.transliteration {
            let trLabelName = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                : surah.nameTransliteration

            let header: String? = settings.showAyahInformation
                ? "[\(trLabelName) \(surah.id):\(hafsAyah.id)]"
                : nil

            appendBlock(
                label: header,
                text: settings.showAyahInformation ? hafsAyah.textTransliteration : "\(hafsAyah.textTransliteration) (\(hafsAyah.id))"
            )
        }

        // English
        let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
        if wantsAnyEnglish {
            let headerName = (!shareSettings.transliteration)
                ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                : surah.nameEnglish

            sepIfNeeded()

            if settings.showAyahInformation {
                s += "[\(headerName) \(surah.id):\(hafsAyah.id)]\n"
            }

            if shareSettings.englishSaheeh {
                if settings.showAyahInformation {
                    s += "- Saheeh International\n"
                }

                s += settings.showAyahInformation ? hafsAyah.textEnglishSaheeh : "\(hafsAyah.textEnglishSaheeh) (\(hafsAyah.id))"
            }

            if shareSettings.englishMustafa {
                if shareSettings.englishSaheeh { s += "\n\n" }
                if settings.showAyahInformation {
                    s += "- Mustafa Khattab\n"
                }
                s += settings.showAyahInformation ? hafsAyah.textEnglishMustafa : "\(hafsAyah.textEnglishMustafa) (\(hafsAyah.id))"
            }
        }

        // Note
        if includeNote, let note = noteText {
            appendBlock(label: String(localized: "Note"), text: note)
        }

        // Qiraah type (optional) - one line: Riwayah: English - Arabic
        if settings.showQiraahDetails && shareSettings.includeQiraah {
            let labels = Self.qiraahLabels(displayQiraah: arabicQiraah)
            appendBlock(label: nil, text: String(localized: "Riwayah: \(labels.english) – \(labels.arabic)"))
        }

        if settings.showSurahInformation {
            if settings.showQiraahDetails && shareSettings.includeQiraah, !s.isEmpty { s += "\n" } else { sepIfNeeded() }
            s += "\(surah.ayahCountLabel()) – \(surah.pageCountLabel) – \(surah.type.capitalized.localizedDisplay) \(surah.type == "makkan" ? "🕋" : "🕌")"
        }

        return s
    }

    private var shareAttributedText: AttributedString {
        Self.allahHighlightedSwiftUIText(shareText, baseColor: .white, enabled: settings.highlightAllahNames)
    }

    private func combinedName(translit: String, english: String) -> String {
        if translit.isEmpty { return english }
        if english.isEmpty { return translit }
        return "\(translit) | \(english)"
    }

    /// One ayah by name and number; a run of them as a range ("Al-Baqarah 2:1-5"); anything else by count.
    private var sheetTitle: String {
        guard isMultiple else { return ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber) }
        let oneSurah = refs.allSatisfy { $0.surahID == surahNumber }
        let contiguous = zip(refs, refs.dropFirst()).allSatisfy { $1.ayahID == $0.ayahID + 1 }
        if oneSurah, contiguous, let last = refs.last {
            return ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber, endAyah: last.ayahID)
        }
        return String(localized: "\(refs.count) Ayahs")
    }

    /// Returns (English, Arabic) display names for the given displayQiraah tag.
    /// Whether Show Riwayah should be on for `qiraah`: any non-Hafs riwayah always shows it (the riwayah
    /// is the point of the share then); Hafs follows the user's saved preference (off by default).
    private func resolvedIncludeRiwayah(for qiraah: String) -> Bool {
        Settings.isNonHafsQiraah(qiraah) ? true : shareIncludeRiwayah
    }

    private static func qiraahLabels(displayQiraah: String) -> (english: String, arabic: String) {
        let option = Settings.Riwayah.option(for: displayQiraah)
        return (option.label, option.arabic)
    }

    /// The card's appearance and its information lines, as the toolbar options menu (Design Grammar
    /// 6, the Qiraah Comparison sheet's layout; Abu, 2026-10-27): the face, tajweed and the two
    /// cleanup switches for the Arabic, the ayah and surah information, and which riwayah the Arabic
    /// is taken from. What to INCLUDE (Arabic, transliteration, the translations, the note) stays in
    /// the list under the preview, since those are flipped while watching it. Before, twelve rows
    /// scrolled in a 200 pt box between the preview and the buttons.
    private var optionsMenu: some View {
        Menu {
            if shareSettings.arabic {
                if actionMode == .image {
                    // The face is a property of the drawn card, not of the text.
                    Picker("Arabic Font", selection: shareArabicFontBinding) {
                        Text("Uthmani").tag(Settings.hafsUthmaniFontName)
                        Text("Indopak").tag(Settings.indopakFontName)
                        Text("Hijazi").tag(Settings.hijaziFontName)
                        Text("Kufi").tag(Settings.kufiFontName)
                        Text("Basic").tag(Settings.systemArabicFontName)
                    }
                    .pickerStyle(.menu)
                }
                // `.automatic`, not the app's padded switch: inside a menu that style draws
                // double-height rows with stray checkmarks (see the memory note on menu toggles).
                if actionMode == .image && isHafsShare {
                    Toggle(isOn: Binding(
                        get: { shareSettings.showTajweed },
                        set: { shareSettings = updatedShareSettings(showTajweed: $0) }
                    )) {
                        Label("Show Tajweed", systemImage: "paintpalette")
                    }
                    .toggleStyle(.automatic)
                }
                Toggle(isOn: $shareSettings.cleanArabic) {
                    Label("Hide Tashkeel and Signs", systemImage: "textformat")
                }
                .toggleStyle(.automatic)
                if canShowHideArabicDotsToggle {
                    Toggle(isOn: Binding(
                        get: { shareSettings.hideArabicDots },
                        set: { shareSettings = updatedShareSettings(hideArabicDots: $0) }
                    )) {
                        Label("Hide Arabic Dots", systemImage: "circle.dotted")
                    }
                    .toggleStyle(.automatic)
                }
                Divider()
            }
            Toggle(isOn: $quranDisplay.showAyahInformation) {
                Label("Show Ayah Information", systemImage: "number")
            }
            .toggleStyle(.automatic)
            Toggle(isOn: $quranDisplay.showSurahInformation) {
                Label("Show Surah Information", systemImage: "text.book.closed")
            }
            .toggleStyle(.automatic)
            if settings.showQiraahDetails {
                Divider()
                Toggle(isOn: includeQiraahBinding) {
                    Label("Show Riwayah/Qiraah", systemImage: "character.book.closed.fill.ar")
                }
                .toggleStyle(.automatic)
                // Which riwayah the shared Arabic is taken from.
                Picker("Riwayah", selection: $shareQiraah) {
                    ForEach(Settings.Riwayah.textOptions, id: \.tag) { option in
                        Text(AppLanguage.isArabicScript ? option.displayLabel(omitsDefaultSuffix: true) : option.label)
                            .tag(option.tag)
                    }
                }
                .pickerStyle(.menu)
                // The same words across riwayat (anchored through Hafs, like the comparison sheet)
                // vs. whatever verse sits at the raw tapped number. Only shown once the picker has
                // moved off the riwayah the ayah was tapped under: on the same riwayah the resolution
                // is the identity.
                if shareQiraahDiffersFromOrigin {
                    Toggle(isOn: $smartAyahMatching) {
                        Label("Smart Ayah Matching", systemImage: "wand.and.stars")
                        Text("Follow the same words where the numbering differs")
                    }
                    .toggleStyle(.automatic)
                }
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .fixedMenuOrder()
        .tint(settings.accentColor.color)
        .accessibilityLabel("Share options")
    }

    /// The face of the shared card; every Hijazi mark style reads as "Hijazi", and picking "Hijazi"
    /// means the mark style the reader is on (or the default one).
    private var shareArabicFontBinding: Binding<String> {
        Binding(
            get: {
                Settings.pickerFaceName(for: Settings.normalizedArabicFontName(
                    shareSettings.shareArabicFont.isEmpty ? settings.fontArabic : shareSettings.shareArabicFont
                ))
            },
            set: { val in
                let chosen = val == Settings.hijaziFontName ? Settings.currentHijaziFontName : val
                let normalizedFont = Settings.normalizedArabicFontName(chosen)
                storedShareArabicFont = normalizedFont
                shareSettings = ShareSettings(
                    arabic: shareSettings.arabic,
                    transliteration: shareSettings.transliteration,
                    englishSaheeh: shareSettings.englishSaheeh,
                    englishMustafa: shareSettings.englishMustafa,
                    includeQiraah: shareSettings.includeQiraah,
                    shareArabicFont: normalizedFont,
                    cleanArabic: shareSettings.cleanArabic,
                    hideArabicDots: shareSettings.hideArabicDots,
                    showTajweed: shareSettings.showTajweed
                )
            }
        )
    }

    /// Show Riwayah/Qiraah. On Hafs the flip IS the saved preference. On any other riwayah the flip
    /// is session-only: the next riwayah change re-resolves it, and the Hafs preference stays untouched.
    private var includeQiraahBinding: Binding<Bool> {
        Binding(
            get: { shareSettings.includeQiraah },
            set: { newValue in
                if !Settings.isNonHafsQiraah(shareQiraah) {
                    shareIncludeRiwayah = newValue
                }
                shareSettings = updatedShareSettings(includeQiraah: newValue)
            }
        )
    }

    /// The caption under the preview while the shared Arabic is Hafs's text standing in for the share
    /// riwayah's. The riwayah picker's footer said so until the options moved into the toolbar menu
    /// (2026-10-27); after that a card could read "Riwayah: Warsh" over Hafs words with nothing on
    /// screen saying why. Two ways in: smart matching finds the tapped words unnumbered in that
    /// riwayah (`anchorUnnumberedInShareQiraah`, the basmalah in the Madani count of al-Fatiha: the
    /// card's riwayah line then names Hafs, so the caption names the riwayah that was picked), or the
    /// ayah served has no text of its own there, merged into a neighbor, and `textArabic` falls back
    /// to Hafs (Smart Ayah Matching off on a number that riwayah lacks). Nil while no Arabic is shared.
    private var hafsFallbackNotice: String? {
        guard shareSettings.arabic, Settings.isNonHafsQiraah(shareQiraah) else { return nil }
        if refs.contains(where: anchorUnnumberedInShareQiraah(for:)) {
            let riwayah = Settings.Riwayah.option(for: shareQiraah).displayLabel(omitsDefaultSuffix: true)
            return String(localized: "\(riwayah) does not count these words as an ayah, so the Hafs text is shown.")
        }
        if refs.contains(where: { !ayahExistsInShareQiraah(for: $0) }) {
            return String(localized: "This ayah is not separate in this riwayah; its words are part of a neighboring ayah, so the Hafs text is shown.")
        }
        return nil
    }

    var body: some View {
        SheetNavigationContainer {
            VStack {
                Spacer()

                ZStack {
                    if actionMode == .image {
                        if let img = generatedImage {
                            // The PREVIOUS image stays on screen while a regeneration runs (it is never
                            // nilled mid-flight), dimmed slightly so the swap reads as an update, not a
                            // teardown - this is what stopped the sheet's jump-and-reflow on every toggle.
                            //
                            // Several ayahs can make a tall card: one taller than about 1.4 of its
                            // width scrolls at full width rather than shrinking into the slot, where
                            // a dozen ayahs were unreadable. A short one stays centred like a single.
                            if isMultiple, img.size.height > img.size.width * 1.4 {
                                ScrollView {
                                    previewImage(img)
                                        .padding(.vertical, 8)
                                }
                            } else {
                                previewImage(img)
                            }
                        } else {
                            // First render only: hold the preview slot at a stable size so the controls
                            // below don't shift when the image lands.
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                        }
                    } else if refs.count > 3 {
                        // Long text scrolls rather than shrinking to fit (see the image above).
                        ScrollView {
                            textPreview
                                .padding(.vertical, 8)
                        }
                    } else {
                        textPreview
                    }
                }
                .scaleEffect(isSharing ? 0.98 : 1)
                .animation(.easeInOut, value: actionMode)
                .animation(.easeInOut, value: isSharing)

                // Hafs's words standing in for the share riwayah's (`hafsFallbackNotice`), under the
                // preview in both modes: the copied text carries the same Arabic as the card.
                if let notice = hafsFallbackNotice {
                    Text(notice)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                }

                Spacer()

                ScrollView {
                    VStack(spacing: 2) {
                        if actionMode == .image {
                            backdropRow
                        }
                        toggle("Arabic", persistentCopyBinding(
                            get: { storedCopyArabic },
                            set: { storedCopyArabic = $0 },
                            update: { updatedShareSettings(arabic: $0) }
                        ),
                               disabled: !shareSettings.transliteration && !shareSettings.englishSaheeh && !shareSettings.englishMustafa)

                        toggle("Transliteration", persistentCopyBinding(
                            get: { storedCopyTransliteration },
                            set: { storedCopyTransliteration = $0 },
                            update: { updatedShareSettings(transliteration: $0) }
                        ),
                               disabled: !shareSettings.arabic && !shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                        toggle("Translation - Saheeh International", persistentCopyBinding(
                            get: { storedCopyEnglishSaheeh },
                            set: { storedCopyEnglishSaheeh = $0 },
                            update: { updatedShareSettings(englishSaheeh: $0) }
                        ),
                               disabled: !shareSettings.arabic && !shareSettings.transliteration && !shareSettings.englishMustafa)
                        toggle("Translation - Mustafa Khattab", persistentCopyBinding(
                            get: { storedCopyEnglishMustafa },
                            set: { storedCopyEnglishMustafa = $0 },
                            update: { updatedShareSettings(englishMustafa: $0) }
                        ),
                               disabled: !shareSettings.arabic && !shareSettings.transliteration && !shareSettings.englishSaheeh)

                        if noteText != nil {
                            Toggle("Include Note", isOn: $includeNote.animation(.easeInOut))
                                .tint(settings.accentColor.color)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 4)
                        }

                        // Everything that shapes the card rather than choosing what goes on it (the
                        // face, tajweed, the cleanup switches, the information lines, the riwayah) is
                        // in the toolbar menu: `optionsMenu`.
                    }
                }
                .frame(maxHeight: 200)

                if imageAllowed {
                    Picker("Action Mode", selection: $actionMode) {
                        Text("Image").tag(ActionMode.image)
                        Text("Text").tag(ActionMode.text)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                } else {
                    // Past `imageAyahLimit` the sheet is text only, and says why instead of greying a segment.
                    Text("Image cards are for up to \(Self.imageAyahLimit) ayahs; a longer selection shares as text.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 4)
                }

                HStack(spacing: 12) {
                    actionButton(String(localized: "Copy")) {
                        performCopyOrGenerate()
                    }

                    actionButton(String(localized: "Share"), isAnimating: isSharing)  {
                        performShareOrGenerate()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom)
                .sheet(isPresented: $showingActivityView) {
                    // didCompleteShare gates the auto-dismiss below: cancelling the share sheet used to
                    // dismiss ShareAyahSheet too, throwing away the user's configured preview ("it reset").
                    if #available(iOS 16.0, *) {
                        ActivityView(activityItems: activityItems, onComplete: { didCompleteShare = $0 })
                            .presentationDetents([.medium])
                    } else {
                        ActivityView(activityItems: activityItems, onComplete: { didCompleteShare = $0 })
                    }
                }
            }
            .navigationTitle(sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) { optionsMenu }
            }
            // This sheet had no dismiss control at all - you could only swipe it away or complete a share.
            .sheetDismissToolbar()
            // Full-size before the wash so the background always covers the whole sheet.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accentWashedBackground()
        }
        .accentColor(settings.accentColor.color)
        .onAppear {
            guard !didInit else { return }
            didInit = true

            withAnimation {
                let font = Settings.normalizedArabicFontName(storedShareArabicFont.isEmpty ? settings.fontArabic : storedShareArabicFont)
                if !storedShareArabicFont.isEmpty {
                    storedShareArabicFont = font
                }
                shareSettings = ShareSettings(
                    arabic: storedCopyArabic,
                    transliteration: storedCopyTransliteration,
                    englishSaheeh: storedCopyEnglishSaheeh,
                    englishMustafa: storedCopyEnglishMustafa,
                    includeQiraah: settings.showQiraahDetails ? resolvedIncludeRiwayah(for: shareQiraah) : false,
                    shareArabicFont: font,
                    cleanArabic: settings.cleanArabicText,
                    hideArabicDots: settings.removeArabicDots,
                    showTajweed: settings.showTajweedColors
                )

                actionMode = imageAllowed ? (ActionMode(rawValue: storedActionModeRaw) ?? .image) : .text
                if imageAllowed { generatePreviewImage() }
            }

            DispatchQueue.main.async {
                didFinishInitialSetup = true
            }
        }

        .onChange(of: actionMode) { newValue in
            if didFinishInitialSetup { settings.hapticFeedback() }
            // The forced text mode of a long selection is not a preference the user expressed.
            if imageAllowed { storedActionModeRaw = newValue.rawValue }
            if newValue == .image && generatedImage == nil {
                generatePreviewImage()
            }
        }
        // Every generation trigger below is gated on didFinishInitialSetup: onAppear already renders once
        // explicitly, and its own state seeding used to echo through these observers as a SECOND, immediately
        // discarded render (drawn in full on the serial queue - a wasted tajweed pass on every open).
        .onChange(of: shareSettings) { _ in
            guard didFinishInitialSetup else { return }
            settings.hapticFeedback()
            generatePreviewImage()
        }
        .onChange(of: storedBackdrop) { _ in
            guard didFinishInitialSetup else { return }
            generatePreviewImage()
        }
        .onChange(of: settings.showSurahInformation) { _ in
            guard didFinishInitialSetup else { return }
            settings.hapticFeedback()
            generatePreviewImage()
        }
        .onChange(of: settings.showAyahInformation) { _ in
            guard didFinishInitialSetup else { return }
            settings.hapticFeedback()
            generatePreviewImage()
        }
        .onChange(of: includeNote) { _ in
            guard didFinishInitialSetup else { return }
            settings.hapticFeedback()
            generatePreviewImage()
        }
        .onChange(of: smartAyahMatching) { _ in
            guard didFinishInitialSetup else { return }
            settings.hapticFeedback()
            generatePreviewImage()
        }
        // No .onChange(of: shareIncludeRiwayah): every write to it also updates shareSettings.includeQiraah,
        // so the shareSettings observer above already regenerates - a second observer meant every riwayah
        // toggle rendered the image twice.
        .onChange(of: shareQiraah) { newQiraah in
            guard didFinishInitialSetup else { return }
            settings.hapticFeedback()
            // Show Riwayah follows the riwayah: a non-Hafs choice turns it on (the riwayah is the whole
            // point of the share then); back on Hafs it returns to the saved Hafs preference.
            let resolved = settings.showQiraahDetails ? resolvedIncludeRiwayah(for: newQiraah) : false
            if resolved != shareSettings.includeQiraah {
                shareSettings = updatedShareSettings(includeQiraah: resolved)
                // shareSettings' own observer regenerates; skip the duplicate below.
                return
            }
            generatePreviewImage()
        }
        .onChange(of: settings.showQiraahDetails) { show in
            if !show, shareSettings.includeQiraah {
                shareIncludeRiwayah = false
                // The shareSettings observer regenerates from this write; no explicit call needed.
                shareSettings = updatedShareSettings(includeQiraah: false)
            }
        }
        .onChange(of: showingActivityView) { open in
            // Close the whole sheet only after a COMPLETED share. On cancel, stay put with the configured
            // preview intact.
            if !open && didCompleteShare {
                closeAfterSharing()
            }
        }
    }

    @ViewBuilder
    /// The image card's design, one chip per backdrop; the choice is remembered and Copy Image
    /// from the actions sheet follows it.
    private var backdropRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ShareBackdrop.allCases) { backdrop in
                    let selected = storedBackdrop == backdrop.rawValue
                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { storedBackdrop = backdrop.rawValue }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: backdrop.symbol)
                            Text(backdrop.title)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(selected ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(selected ? settings.accentColor.color : Color.primary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 4)
    }

    private func previewImage(_ img: UIImage) -> some View {
        Image(uiImage: img)
            .resizable()
            .scaledToFit()
            .cornerRadius(24)
            .padding(.horizontal, 16)
            .contextMenu { copyMenu(image: img) }
            .opacity(isGeneratingImage ? 0.6 : 1)
            .animation(.easeInOut(duration: 0.15), value: isGeneratingImage)
            .transition(.opacity)
    }

    private var textPreview: some View {
        Text(shareAttributedText)
            .font(.body)
            .textSelection(.enabled)
            // With a transliteration or a translation in it the preview reads left to
            // right in the Arabic interface too, as the shared text does; Arabic alone
            // follows the interface.
            .leftToRightContent(shareSettings.transliteration || shareSettings.englishSaheeh || shareSettings.englishMustafa)
            .padding()
            .background(Color.black)
            .cornerRadius(24)
            .padding(.horizontal, 16)
            .contextMenu { copyMenu(image: generatedImage) }
            .lineLimit(nil)
            .minimumScaleFactor(0.1)
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    private func toggle(_ title: LocalizedStringKey, _ binding: Binding<Bool>, disabled: Bool) -> some View {
        Toggle(isOn: binding.animation(.easeInOut)) {
            Text(title).foregroundColor(.primary)
        }
        .tint(settings.accentColor.color)
        .disabled(disabled)
        .padding(.horizontal, 20)
        .padding(.vertical, 4)
    }

    private func actionButton(_ title: String, isAnimating: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            settings.hapticFeedback()
            action()
        } label: {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .foregroundColor(.primary)
                .scaleEffect(isAnimating ? 0.96 : 1)
        }
        .conditionalGlassEffect(useColor: 0.25)
    }

    private func copyMenu(image: UIImage?) -> some View {
        Group {
            Text("Copy")
                .foregroundStyle(.secondary)

            Button {
                settings.hapticFeedback()
                UIPasteboard.general.string = shareText
            } label: { Label("Copy Text", systemImage: "doc.on.doc") }
            if let image {
                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.image = image
                } label: { Label("Copy Image", systemImage: "doc.on.doc.fill") }
            }
        }
    }

    private func animateShare(completion: @escaping () -> Void) {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            isSharing = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            completion()

            withAnimation(.easeOut(duration: 0.18)) {
                isSharing = false
            }
        }
    }

    private func presentShareSheet(with items: [Any]) {
        animateShare {
            didCompleteShare = false
            activityItems = items
            showingActivityView = true
        }
    }



    /// The copy is made or the share went through: the sheet is done, and says so before it closes.
    private func closeAfterSharing() {
        onShared?()
        presentationMode.wrappedValue.dismiss()
    }

    private func performCopyOrGenerate() {
        settings.hapticFeedback()

        switch actionMode {
        case .text:
            UIPasteboard.general.string = shareText
            closeAfterSharing()
        case .image:
            // Not while a render is in flight: the image on screen then predates the last toggle, and
            // the fresh render below supersedes the one running.
            if !isGeneratingImage, let img = generatedImage {
                UIPasteboard.general.image = img
                closeAfterSharing()
            } else {
                generatePreviewImage { img in
                    UIPasteboard.general.image = img
                    closeAfterSharing()
                }
            }
        }
    }

    private func performShareOrGenerate() {
        switch actionMode {
        case .text:
            presentShareSheet(with: [shareText])
        case .image:
            // Same rule as Copy: never the dimmed image of a render still running.
            if !isGeneratingImage, let img = generatedImage {
                presentShareSheet(with: [img])
            } else {
                generatePreviewImage { img in
                    presentShareSheet(with: [img])
                }
            }
        }
    }

    private func generatePreviewImage(completion: @escaping (UIImage) -> Void = { _ in }) {
        // A selection past the image limit is text only (see `imageAllowed`); nothing to draw.
        guard imageAllowed else { return }
        // Snapshot EVERY main-actor input on main, before hopping to the render queue: the queue must never
        // read view state (shareSettings, shareQiraah, the note) that a later toggle could be rewriting.
        let snapshot = shareSettings
        // The riwayah the Arabic is READ in (Hafs where the share riwayah does not number the words).
        let qiraahSnapshot = arabicQiraah
        let includeNoteSnapshot = includeNote
        let noteSnapshot = noteText
        let backdropSnapshot = ShareBackdrop(rawValue: storedBackdrop) ?? .classic
        // The RESOLVED ayahs too: resolving them (smart ayah matching) walks QiraahComparison's
        // main-actor alignment cache - an unsynchronized static dictionary the render queue must
        // never touch while the main thread (this sheet's own footer) is reading/populating it.
        let entriesSnapshot = shareEntries
        let generationID = imageGenerationID + 1
        imageGenerationID = generationID
        // The previous image deliberately STAYS visible (dimmed via isGeneratingImage) while this render
        // runs. Nilling it here collapsed the preview to zero height and made the whole sheet jump on
        // every toggle - the "screen jumps back" bug.
        isGeneratingImage = true
        // UIScreen.main is main-thread-only; capture the width here (still on main) for the queue below.
        // Clamped to a phone-like measure: on iPad/Mac the SCREEN is 800-1400pt wide even when the app's
        // window is narrow (Split View, Stage Manager), and an image laid out that wide reads terribly.
        // Every iPhone stays under the clamp, so phone output is unchanged.
        let screenWidth = min(UIScreen.main.bounds.width, ShareAyahRender.maxImageWidth)
        Self.shareImageQueue.async { [self] in
            // Superseded before we even started drawing? Skip the (expensive, tajweed-attributed) render
            // entirely instead of drawing an image only to discard it. main.sync is deadlock-free here:
            // nothing on the main thread ever blocks on this queue. (@State reads are live through SwiftUI's
            // storage, so this sees the CURRENT generation, not a stale copy.)
            let stillCurrent = DispatchQueue.main.sync { self.imageGenerationID == generationID }
            guard stillCurrent else { return }

            let img: UIImage = autoreleasepool {
                self.drawImage(
                    entries: entriesSnapshot,
                    shareSettings: snapshot,
                    qiraah: qiraahSnapshot,
                    includeNote: includeNoteSnapshot,
                    noteText: noteSnapshot,
                    screenWidth: screenWidth,
                    backdrop: backdropSnapshot
                )
            }
            DispatchQueue.main.async {
                guard self.imageGenerationID == generationID else { return }
                // Scoped to the image swap only - an unscoped withAnimation here animated the entire
                // sheet's layout, amplifying the jump.
                withAnimation(.easeInOut(duration: 0.15)) {
                    self.generatedImage = img
                    self.isGeneratingImage = false
                }
                if self.actionMode == .image {
                    self.activityItems = [img]
                }
                completion(img)
            }
        }
    }

    /// Runs on the render queue - the entries are passed in as main-thread snapshots, never resolved
    /// here (resolution touches the main-actor alignment cache).
    private func drawImage(entries: [ShareAyahEntry], shareSettings: ShareSettings, qiraah shareQiraah: String, includeNote: Bool, noteText: String?, screenWidth: CGFloat, backdrop: ShareBackdrop) -> UIImage {
        guard !entries.isEmpty else { return UIImage() }
        return Self.composeCard(entries: entries, shareSettings: shareSettings,
                                settings: settings, qiraah: shareQiraah, includeNote: includeNote, noteText: noteText,
                                screenWidth: screenWidth, backdrop: backdrop)
    }

    /// The editorial backdrop's watermark: the shared Arabic, marks stripped, in the chosen face,
    /// sized down for long ayahs. Nil for every other design.
    static func backdropWatermark(backdrop: ShareBackdrop, surah: Surah, ayah: Ayah, tail: [Ayah] = [], shareSettings: ShareSettings,
                                  qiraah: String?, fontName: String, width: CGFloat, color: UIColor) -> NSAttributedString? {
        guard backdrop == .editorial, shareSettings.arabic else { return nil }
        let plain = shareArabicText(surah: surah, ayah: ayah, cleanArabic: true, hideArabicDots: false, qiraahOverride: qiraah, tail: tail)
        let words = max(1, plain.split(whereSeparator: { $0.isWhitespace }).count)
        let scale = min(1, max(0.46, 30 / CGFloat(words)))
        let size = max(26, (width * 0.18 * scale).rounded())
        let font = UIFont(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size)
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineHeightMultiple = 1.2
        return NSAttributedString(string: plain, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: style])
    }
}

// MARK: - Copy Ayah (matches Share sheet: image or text per stored preference)
extension ShareAyahSheet {
    private static let copyActionModeKey = "shareAyahLastActionMode"

    private static let shareIncludeRiwayahKey = "shareIncludeRiwayah"

    /// What "Copy Ayah" copies right now ("as image" / "as text"). The actions sheet showed it as a
    /// caption under a half-width row until 2026-09-22; that row is a grid tile now, and the tile
    /// keeps the canonical title ("Copy Ayah", see `ayah-menu-parity-and-search-paint`) with no room
    /// for a caption, so nothing reads this at the moment. Kept because the mode itself still exists
    /// and the share sheet's own copy of this label is the only other place that says which it is.
    static var copyModeLabel: String {
        let raw = UserDefaults.standard.string(forKey: copyActionModeKey) ?? ActionMode.image.rawValue
        return (ActionMode(rawValue: raw) ?? .image) == .image ? String(localized: "as image") : String(localized: "as text")
    }

    /// - Parameter mode: what to put on the pasteboard. Nil follows the share sheet's remembered
    ///   choice, which is what a single "Copy" action wants. The mushaf's actions sheet offers Copy
    ///   Text and Copy Image as separate tiles and passes the mode outright, so what you tap is what
    ///   you get rather than whatever you last shared as.
    static func copyAyahToPasteboard(surahNumber: Int, ayahNumber: Int, settings: Settings,
                                     quranData: QuranData, mode: ActionMode? = nil) {
        guard let surah = quranData.surah(surahNumber),
              let ayah = surah.ayahs.first(where: { $0.id == ayahNumber }) else { return }
        // Same rule as the sheet: a non-Hafs reading riwayah always names itself; Hafs follows the saved
        // preference (off by default).
        let includeRiwayah = settings.showQiraahDetails
            && (Settings.isNonHafsQiraah(settings.displayQiraah) || UserDefaults.standard.bool(forKey: shareIncludeRiwayahKey))
        let shareFont = UserDefaults.standard.string(forKey: "shareArabicFont") ?? ""
        let shareSettings = ShareSettings(
            arabic: settings.copyAyahArabic,
            transliteration: settings.copyAyahTransliteration,
            englishSaheeh: settings.copyAyahEnglishSaheeh,
            englishMustafa: settings.copyAyahEnglishMustafa,
            includeQiraah: includeRiwayah,
            shareArabicFont: Settings.normalizedArabicFontName(shareFont.isEmpty ? settings.fontArabic : shareFont),
            cleanArabic: settings.cleanArabicText,
            hideArabicDots: settings.removeArabicDots,
            showTajweed: settings.showTajweedColors
        )
        let noteText: String? = {
            guard let idx = settings.bookmarkedAyahs.firstIndex(where: { $0.surah == surahNumber && $0.ayah == ayahNumber }) else { return nil }
            let trimmed = settings.bookmarkedAyahs[idx].note?.trimmingCharacters(in: .whitespacesAndNewlines)
            return (trimmed?.isEmpty == true) ? nil : trimmed
        }()
        let includeNote = (noteText != nil)
        let actionMode: ActionMode = mode ?? {
            let raw = UserDefaults.standard.string(forKey: copyActionModeKey) ?? ActionMode.image.rawValue
            return ActionMode(rawValue: raw) ?? .image
        }()

        // The Hafs ayah whose transliteration and translations the copy prints, for the text and the
        // card alike. With Smart Ayah Matching on (the share sheet's switch, on by default) it is the
        // anchor of the tapped WORDS, so under a merged or shifted riwayah numbering the English
        // matches the Arabic rather than Hafs's verse of the same number (the sheet's
        // `translationAyah`; both paths passed the ayah itself and printed Hafs 2:9's translation
        // under Warsh 2:9's words, the text path until 2026-10-28). A static path, so the sheet's
        // `@AppStorage` is out of reach: the same key, read raw.
        let smartMatching = UserDefaults.standard.object(forKey: qiraahSmartComparisonKey) as? Bool ?? true
        let hafsAyah: Ayah = {
            guard smartMatching else { return ayah }
            let anchor = QiraahComparison.hafsAnchor(surahID: surah.id, ayahNumber: ayah.id,
                                                     tag: Settings.normalizeLegacyRiwayahTag(settings.displayQiraah),
                                                     quranData: QuranData.shared)
            return surah.ayahs.first(where: { $0.id == anchor }) ?? ayah
        }()

        switch actionMode {
        case .text:
            let text = buildShareText(surah: surah, ayah: ayah, hafsAyah: hafsAyah, shareSettings: shareSettings, settings: settings, includeNote: includeNote, noteText: noteText)
            UIPasteboard.general.string = text
            CopyConfirmation.shared.show()
        case .image:
            // UIScreen.main is main-thread-only; capture the width here (still on main) for the queue below.
            // Same phone-like clamp as the share-sheet render - see `ShareAyahRender.maxImageWidth`.
            let screenWidth = min(UIScreen.main.bounds.width, ShareAyahRender.maxImageWidth)
            DispatchQueue.global(qos: .userInitiated).async {
                // The remembered backdrop (the share sheet's chips), so Copy Image matches the last share.
                let img = composeCard(surah: surah, ayah: ayah, hafsAyah: hafsAyah, shareSettings: shareSettings, settings: settings,
                                      qiraah: Settings.normalizeLegacyRiwayahTag(settings.displayQiraah),
                                      includeNote: includeNote, noteText: noteText, screenWidth: screenWidth,
                                      backdrop: .stored)
                DispatchQueue.main.async {
                    UIPasteboard.general.image = img
                    CopyConfirmation.shared.show()
                }
            }
        }
    }

    private static func combinedName(translit: String, english: String) -> String {
        if translit.isEmpty { return english }
        if english.isEmpty { return translit }
        return "\(translit) | \(english)"
    }

    private static func effectiveCleanArabic(_ shareSettings: ShareSettings) -> Bool {
        shareSettings.cleanArabic
    }

    private static func effectiveHideArabicDots(_ shareSettings: ShareSettings) -> Bool {
        shareSettings.hideArabicDots
    }

    /// `hafsAyah` carries the transliteration and translations, as on the card (`composeCard`).
    private static func buildShareText(surah: Surah, ayah: Ayah, hafsAyah: Ayah, shareSettings: ShareSettings, settings: Settings, includeNote: Bool, noteText: String?) -> String {
        var s = ""
        func sepIfNeeded() { if !s.isEmpty { s += "\n\n" } }
        func appendBlock(label: String?, text: String?) {
            guard let text = text, !text.isEmpty else { return }
            sepIfNeeded()
            if let label = label, !label.isEmpty { s += "\(label)\n" }
            s += text
        }
        if shareSettings.arabic {
            let header: String? = settings.showAyahInformation ? "[\(Settings.shared.cleanedQuranArabic(surah.nameArabic)) \(surah.idArabic):\(ayah.idArabic)]" : nil
            let arabicText = Self.shareArabicText(
                surah: surah,
                ayah: ayah,
                cleanArabic: effectiveCleanArabic(shareSettings),
                hideArabicDots: effectiveHideArabicDots(shareSettings),
                qiraahOverride: settings.displayQiraahForArabic
            )
            appendBlock(label: header, text: settings.showAyahInformation ? arabicText : "\(arabicText) \(ayah.idArabic)")
        }
        if shareSettings.transliteration {
            let trLabelName = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa) ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish) : surah.nameTransliteration
            let header: String? = settings.showAyahInformation ? "[\(trLabelName) \(surah.id):\(hafsAyah.id)]" : nil
            appendBlock(label: header, text: settings.showAyahInformation ? hafsAyah.textTransliteration : "\(hafsAyah.textTransliteration) (\(hafsAyah.id))")
        }
        let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
        if wantsAnyEnglish {
            let headerName = (!shareSettings.transliteration) ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish) : surah.nameEnglish
            sepIfNeeded()
            if settings.showAyahInformation { s += "[\(headerName) \(surah.id):\(hafsAyah.id)]\n" }
            if shareSettings.englishSaheeh {
                if settings.showAyahInformation { s += "- Saheeh International\n" }
                s += settings.showAyahInformation ? hafsAyah.textEnglishSaheeh : "\(hafsAyah.textEnglishSaheeh) (\(hafsAyah.id))"
            }
            if shareSettings.englishMustafa {
                if shareSettings.englishSaheeh { s += "\n\n" }
                if settings.showAyahInformation { s += "- Mustafa Khattab\n" }
                s += settings.showAyahInformation ? hafsAyah.textEnglishMustafa : "\(hafsAyah.textEnglishMustafa) (\(hafsAyah.id))"
            }
        }
        if includeNote, let note = noteText { appendBlock(label: String(localized: "Note"), text: note) }
        if shareSettings.includeQiraah {
            let labels = qiraahLabels(displayQiraah: settings.displayQiraah)
            appendBlock(label: nil, text: String(localized: "Riwayah: \(labels.english) – \(labels.arabic)"))
        }
        if settings.showSurahInformation {
            if shareSettings.includeQiraah, !s.isEmpty { s += "\n" } else { sepIfNeeded() }
            s += "\(surah.ayahCountLabel()) – \(surah.pageCountLabel) – \(surah.type.capitalized.localizedDisplay) \(surah.type == "makkan" ? "🕋" : "🕌")"
        }
        return s
    }

    /// THE share card: the share sheet's preview and share, and Copy Image from the actions sheet.
    /// One composer, so the two can never disagree about a header, an ink or the tajweed base color
    /// (the copy path was a second, drifting copy until 2026-09-29: tajweed's plain letters took the
    /// translation's white on the Nature card and its Arabic header lost the accent).
    /// `hafsAyah` carries the transliteration and translations (the sheet's smart matching); `qiraah`
    /// is the riwayah the Arabic, its face and the riwayah line follow; `arabicTail` the rest of a split
    /// ayah (the sheet's `arabicSplitTail`, resolved on main). Safe off the main thread.
    static func composeCard(surah: Surah, ayah: Ayah, hafsAyah: Ayah, arabicTail: [Ayah] = [], shareSettings: ShareSettings, settings: Settings,
                            qiraah: String, includeNote: Bool, noteText: String?, screenWidth: CGFloat,
                            backdrop: ShareBackdrop) -> UIImage {
        composeCard(entries: [ShareAyahEntry(surah: surah, ayah: ayah, hafsAyah: hafsAyah, tail: arabicTail, arabicQiraah: qiraah)],
                    shareSettings: shareSettings, settings: settings, qiraah: qiraah, includeNote: includeNote,
                    noteText: noteText, screenWidth: screenWidth, backdrop: backdrop)
    }

    /// The card of one ayah or of several (the reader's Select Ayahs bar). One ayah keeps the layout
    /// it always had; several are drawn per surah as one Arabic passage with the ayah numbers inline,
    /// the way a mushaf line reads, then the transliteration and the translations as numbered lines
    /// under the same reference. `qiraah` is the riwayah the face and the riwayah line follow; each
    /// entry carries the riwayah its own Arabic is read in.
    static func composeCard(entries: [ShareAyahEntry], shareSettings: ShareSettings, settings: Settings,
                            qiraah: String, includeNote: Bool, noteText: String?, screenWidth: CGFloat,
                            backdrop: ShareBackdrop) -> UIImage {
        let first = entries[0]
        let surah = first.surah, ayah = first.ayah, hafsAyah = first.hafsAyah, arabicTail = first.tail
        // Rounded, to match the app's system-font design (the `fontDesign` environment does not reach this
        // UIKit-drawn image, so the design is asked for explicitly).
        let bodyFont   = UIFont.roundedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
        let selectedArabicFontName = shareSettings.shareArabicFont.isEmpty ? settings.fontArabic : shareSettings.shareArabicFont
        let arabicFontName = Settings.quranArabicFontName(selectedFontName: selectedArabicFontName, qiraah: qiraah, style: settings.arabicScriptStyle)
        // Dots-hidden text renders in the chosen face too (the ttfs carry real dotless glyphs now).
        // The "Basic" sentinel has no real UIFont - it falls back to the ROUNDED system face at the
        // same 1.15x Arabic scale (the bare bodyFont fallback silently shrank Basic Arabic).
        let arabicFont = UIFont(name: arabicFontName, size: bodyFont.pointSize * 1.15)
            ?? UIFont.roundedSystemFont(ofSize: bodyFont.pointSize * 1.15)
        let arabicNumberFont = UIFont(name: Settings.hafsUthmaniFontName, size: bodyFont.pointSize * 1.15) ?? arabicFont
        let captionFont = UIFont.roundedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize)

        // The backdrop's inks: the classic card keeps the reader's accent, the designs carry their own.
        // The accent is dynamic (4.5:1 in each appearance), so it is resolved for the card's ground,
        // not the phone's: the light variant is the dark one, made for white.
        let palette = backdrop.palette
        let textColor      = palette.text
        let arabicColor    = palette.arabic
        let secondaryColor = palette.caption
        let accent = ShareInk.readable(palette.accent ?? settings.accentColor.color.uiColor,
                                       on: palette.ground, dark: palette.isDark, minimum: 4.5)

        // --- Layout constants
        let spacing: CGFloat = 8, extraSpacing: CGFloat = 30
        let iPhoneCanvasCap: CGFloat = 500
        let deviceWidth = screenWidth - 50
        let maxWidth = min(deviceWidth, iPhoneCanvasCap)
        let padding = backdrop.padding(forWidth: maxWidth)
        let headroom = backdrop.headroom(forWidth: maxWidth)

        // Paragraph styles
        let right = NSMutableParagraphStyle();  right.alignment = .right
        let left  = NSMutableParagraphStyle();  left.alignment  = .left
        let cent  = NSMutableParagraphStyle();  cent.alignment  = .center

        // Attr dictionaries
        var bodyAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: textColor] as [NSAttributedString.Key: Any]
        if palette.textShadow {
            // Translation lines over scenery carry a soft shadow so they read on the sky.
            let shadow = NSShadow()
            shadow.shadowOffset = CGSize(width: 0, height: 1)
            shadow.shadowBlurRadius = 8
            shadow.shadowColor = UIColor(white: 0, alpha: 0.55)
            bodyAttr[.shadow] = shadow
        }
        // The transliteration and the translations: an explicit left-to-right paragraph, because the
        // default (natural) one resolves to the right edge when the interface is Arabic.
        let englishParagraph = NSMutableParagraphStyle()
        englishParagraph.alignment = .left
        englishParagraph.baseWritingDirection = .leftToRight
        var englishBodyAttr = bodyAttr
        englishBodyAttr[.paragraphStyle] = englishParagraph
        let arAttr = [NSAttributedString.Key.font: arabicFont, .foregroundColor: arabicColor, .paragraphStyle: right] as [NSAttributedString.Key: Any]
        let arNumberAttr = [NSAttributedString.Key.font: arabicNumberFont, .foregroundColor: arabicColor, .paragraphStyle: right] as [NSAttributedString.Key: Any]
        let accentAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let arAccent = [NSAttributedString.Key.font: arabicFont, .foregroundColor: accent, .paragraphStyle: right] as [NSAttributedString.Key: Any]
        let centAccent = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent, .paragraphStyle: cent] as [NSAttributedString.Key: Any]
        let captionAttr = [NSAttributedString.Key.font: captionFont, .foregroundColor: secondaryColor, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let captionCentAttr = [NSAttributedString.Key.font: captionFont, .foregroundColor: secondaryColor, .paragraphStyle: cent] as [NSAttributedString.Key: Any]

        // --- Compose full attributed text once
        let text = NSMutableAttributedString()
        func append(_ str: String, _ attrs: [NSAttributedString.Key: Any], highlightAllah: Bool = true) {
            text.append(Self.allahHighlightedAttributedString(str, attributes: attrs, enabled: highlightAllah && settings.highlightAllahNames,
                                                              color: palette.allah))
        }
        func sepIfNeeded() { if text.length > 0 { append("\n\n", bodyAttr, highlightAllah: false) } }

        if entries.count == 1 {
            // Arabic
            if shareSettings.arabic {
                let arabicText = Self.shareArabicText(
                    surah: surah,
                    ayah: ayah,
                    cleanArabic: effectiveCleanArabic(shareSettings),
                    hideArabicDots: effectiveHideArabicDots(shareSettings),
                    qiraahOverride: qiraah,
                    tail: arabicTail
                )

                if settings.showAyahInformation {
                    append("[\(Settings.shared.cleanedQuranArabic(surah.nameArabic)) ", arAccent, highlightAllah: false)
                    append("\(surah.idArabic):\(ayah.idArabic)]", accentAttr, highlightAllah: false)
                    append("\n", bodyAttr, highlightAllah: false)
                }

                if let tajweedText = Self.shareArabicImageAttributedText(
                    surah: surah,
                    ayah: ayah,
                    shareSettings: shareSettings,
                    settings: settings,
                    qiraah: qiraah,
                    font: arabicFont,
                    paragraphStyle: right,
                    textColor: arabicColor,
                    allahColor: palette.allah
                ) {
                    text.append(tajweedText)
                } else {
                    append(arabicText, arAttr)
                }
                if !settings.showAyahInformation {
                    append(" \(ayah.idArabic)", arNumberAttr, highlightAllah: false)
                }
            }

            // Transliteration (always offered; the text itself follows Hafs numbering)
            if shareSettings.transliteration {
                let trLabelName = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                    ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                    : surah.nameTransliteration

                sepIfNeeded()

                if settings.showAyahInformation {
                    append("[\(trLabelName) \(surah.id):\(hafsAyah.id)]", accentAttr, highlightAllah: false)
                    append("\n", bodyAttr, highlightAllah: false)
                }

                append(settings.showAyahInformation ? hafsAyah.textTransliteration : "\(hafsAyah.textTransliteration) (\(hafsAyah.id))", englishBodyAttr)
            }

            let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
            if wantsAnyEnglish {
                let enHeaderName = (!shareSettings.transliteration)
                    ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                    : surah.nameEnglish

                sepIfNeeded()

                if settings.showAyahInformation {
                    append("[\(enHeaderName) \(surah.id):\(hafsAyah.id)]", accentAttr, highlightAllah: false)
                    append("\n", bodyAttr, highlightAllah: false)
                }

                if shareSettings.englishSaheeh {
                    if settings.showAyahInformation {
                        append("- Saheeh International", captionAttr, highlightAllah: false)
                        append("\n", bodyAttr, highlightAllah: false)
                    }
                    append(settings.showAyahInformation ? hafsAyah.textEnglishSaheeh : "\(hafsAyah.textEnglishSaheeh) (\(hafsAyah.id))", englishBodyAttr)
                }

                if shareSettings.englishMustafa {
                    if shareSettings.englishSaheeh { append("\n\n", bodyAttr, highlightAllah: false) }

                    if settings.showAyahInformation {
                        append("- Clear Quran (Mustafa Khattab)", captionAttr, highlightAllah: false)
                        append("\n", bodyAttr, highlightAllah: false)
                    }
                    append(settings.showAyahInformation ? hafsAyah.textEnglishMustafa : "\(hafsAyah.textEnglishMustafa) (\(hafsAyah.id))", englishBodyAttr)
                }
            }

            if includeNote, let note = noteText {
                sepIfNeeded()
                append("- \(String(localized: "Note"))", captionAttr, highlightAllah: false)
                append("\n", bodyAttr, highlightAllah: false)
                append(note, bodyAttr)
            }

            if shareSettings.includeQiraah {
                sepIfNeeded()
                let labels = Self.qiraahLabels(displayQiraah: qiraah)
                append(String(localized: "Riwayah: \(labels.english) – \(labels.arabic)"), captionCentAttr, highlightAllah: false)
            }
            if settings.showSurahInformation {
                if shareSettings.includeQiraah { append("\n", bodyAttr, highlightAllah: false) } else { sepIfNeeded() }
                append("\(surah.ayahCountLabel()) – \(surah.pageCountLabel) – \(surah.type.capitalized.localizedDisplay) \(surah.type == "makkan" ? "🕋" : "🕌")", captionCentAttr, highlightAllah: false)
            }
        } else {
            // Several ayahs: per surah, one passage with the ayah numbers inline, then the
            // transliteration and the translations numbered line by line under the same reference.
            // A note belongs to one ayah, so none is drawn here.
            let groups = Self.surahGroups(entries)

            if shareSettings.arabic {
                for group in groups {
                    sepIfNeeded()
                    if settings.showAyahInformation {
                        append("[\(Settings.shared.cleanedQuranArabic(group.surah.nameArabic)) ", arAccent, highlightAllah: false)
                        append("\(group.surah.idArabic):\(Self.referenceLabel(ayahIDs: group.entries.map { $0.ayah.id }, arabicDigits: true))]",
                               accentAttr, highlightAllah: false)
                        append("\n", bodyAttr, highlightAllah: false)
                    }
                    for (index, entry) in group.entries.enumerated() {
                        if index > 0 { append(" ", arAttr, highlightAllah: false) }
                        if let tajweedText = Self.shareArabicImageAttributedText(
                            surah: group.surah,
                            ayah: entry.ayah,
                            shareSettings: shareSettings,
                            settings: settings,
                            qiraah: entry.arabicQiraah,
                            font: arabicFont,
                            paragraphStyle: right,
                            textColor: arabicColor,
                            allahColor: palette.allah
                        ) {
                            text.append(tajweedText)
                        } else {
                            append(Self.shareArabicText(
                                surah: group.surah,
                                ayah: entry.ayah,
                                cleanArabic: effectiveCleanArabic(shareSettings),
                                hideArabicDots: effectiveHideArabicDots(shareSettings),
                                qiraahOverride: entry.arabicQiraah,
                                tail: entry.tail
                            ), arAttr)
                        }
                        // The ayah's number after its words, as the single card draws it without a header.
                        append(" \(entry.ayah.idArabic)", arNumberAttr, highlightAllah: false)
                    }
                }
            }

            if shareSettings.transliteration {
                for group in groups {
                    let trLabelName = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                        ? combinedName(translit: group.surah.nameTransliteration, english: group.surah.nameEnglish)
                        : group.surah.nameTransliteration

                    sepIfNeeded()

                    if settings.showAyahInformation {
                        append("[\(trLabelName) \(group.surah.id):\(Self.referenceLabel(ayahIDs: group.entries.map { $0.hafsAyah.id }))]",
                               accentAttr, highlightAllah: false)
                        append("\n", bodyAttr, highlightAllah: false)
                    }
                    for (index, entry) in group.entries.enumerated() {
                        if index > 0 { append("\n", bodyAttr, highlightAllah: false) }
                        append("\(entry.hafsAyah.id). \(entry.hafsAyah.textTransliteration)", englishBodyAttr)
                    }
                }
            }

            let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
            if wantsAnyEnglish {
                for group in groups {
                    let enHeaderName = (!shareSettings.transliteration)
                        ? combinedName(translit: group.surah.nameTransliteration, english: group.surah.nameEnglish)
                        : group.surah.nameEnglish

                    sepIfNeeded()

                    if settings.showAyahInformation {
                        append("[\(enHeaderName) \(group.surah.id):\(Self.referenceLabel(ayahIDs: group.entries.map { $0.hafsAyah.id }))]",
                               accentAttr, highlightAllah: false)
                        append("\n", bodyAttr, highlightAllah: false)
                    }

                    if shareSettings.englishSaheeh {
                        if settings.showAyahInformation {
                            append("- Saheeh International", captionAttr, highlightAllah: false)
                            append("\n", bodyAttr, highlightAllah: false)
                        }
                        for (index, entry) in group.entries.enumerated() {
                            if index > 0 { append("\n", bodyAttr, highlightAllah: false) }
                            append("\(entry.hafsAyah.id). \(entry.hafsAyah.textEnglishSaheeh)", englishBodyAttr)
                        }
                    }

                    if shareSettings.englishMustafa {
                        if shareSettings.englishSaheeh { append("\n\n", bodyAttr, highlightAllah: false) }

                        if settings.showAyahInformation {
                            append("- Clear Quran (Mustafa Khattab)", captionAttr, highlightAllah: false)
                            append("\n", bodyAttr, highlightAllah: false)
                        }
                        for (index, entry) in group.entries.enumerated() {
                            if index > 0 { append("\n", bodyAttr, highlightAllah: false) }
                            append("\(entry.hafsAyah.id). \(entry.hafsAyah.textEnglishMustafa)", englishBodyAttr)
                        }
                    }
                }
            }

            if shareSettings.includeQiraah {
                sepIfNeeded()
                let labels = Self.qiraahLabels(displayQiraah: qiraah)
                append(String(localized: "Riwayah: \(labels.english) – \(labels.arabic)"), captionCentAttr, highlightAllah: false)
            }
            // The surah line names ONE surah; a selection that crossed into the next says nothing here.
            if settings.showSurahInformation, groups.count == 1 {
                let only = groups[0].surah
                if shareSettings.includeQiraah { append("\n", bodyAttr, highlightAllah: false) } else { sepIfNeeded() }
                append("\(only.ayahCountLabel()) – \(only.pageCountLabel) – \(only.type.capitalized.localizedDisplay) \(only.type == "makkan" ? "🕋" : "🕌")", captionCentAttr, highlightAllah: false)
            }
        }
        // Every run on the card's ground at 3:1 or better: the tajweed colors (made for the reader's
        // white or black page) and any custom ones, which the designs' own inks already clear.
        ShareInk.enforce(text, palette: palette, minimum: 3)

        // --- Watermark
        let wmString = AppIdentifiers.appFullName
        let wmText = NSAttributedString(string: wmString, attributes: centAccent)
        var logo = UIImage(named: AppIdentifiers.appName)

        var wmTextSize = wmText.size()
        var logoSize = CGSize(width: wmTextSize.height, height: wmTextSize.height)
        let availWidth = maxWidth - 2*padding
        let desiredWmW = logoSize.width + spacing + wmTextSize.width

        if desiredWmW > availWidth {
            let scale = availWidth / desiredWmW
            wmTextSize = CGSize(width: wmTextSize.width*scale, height: wmTextSize.height*scale)
            logoSize = CGSize(width: logoSize.width*scale, height: logoSize.height*scale)
            if let img = logo {
                let r = UIGraphicsImageRenderer(size: logoSize)
                logo = r.image { _ in img.draw(in: CGRect(origin: .zero, size: logoSize)) }
            }
        }

        let constraint = CGSize(width: availWidth, height: .greatestFiniteMagnitude)
        var textRect = text.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
        textRect.size.width  += 2*padding
        // The classic card's 20/15 vertical margins, widened with the design's padding.
        textRect.size.height += logoSize.height + extraSpacing + 25 + 2 * (padding - 20)

        let canvas = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: textRect.height + headroom.top + headroom.bottom))
        // The editorial card's watermark: the ayah itself, faint and large, behind the words.
        let watermark = Self.backdropWatermark(backdrop: backdrop, surah: surah, ayah: ayah, tail: arabicTail, shareSettings: shareSettings,
                                               qiraah: qiraah, fontName: arabicFontName, width: maxWidth, color: arabicColor)

        // A long passage (the Select Ayahs bar) makes a tall card: past ~1,800 pt it is drawn at 2x
        // rather than the screen's 3x, which keeps a thirty-ayah card's bitmap under ~50 MB.
        let format = UIGraphicsImageRendererFormat.default()
        if canvas.height > 1800 { format.scale = 2 }
        let r1 = UIGraphicsImageRenderer(size: canvas.size, format: format)
        let card = r1.image { ctx in
            let textFrame = CGRect(x: padding, y: headroom.top + padding, width: canvas.width - 2*padding,
                                   height: textRect.height - 2*padding)
            backdrop.paint(canvas: canvas, textFrame: textFrame, watermark: watermark, in: ctx.cgContext)
            text.draw(in: CGRect(x: padding, y: headroom.top + padding, width: canvas.width - 2*padding, height: canvas.height))

            let wmY = canvas.height - headroom.bottom - (padding - 20) - logoSize.height - extraSpacing/2
            let wmX = (canvas.width - (logoSize.width + spacing + wmTextSize.width)) / 2
            if let logo = logo {
                let rect = CGRect(origin: CGPoint(x: wmX, y: wmY), size: logoSize)
                ctx.cgContext.addPath(UIBezierPath(roundedRect: rect, cornerRadius: logoSize.height*0.25).cgPath)
                ctx.cgContext.clip(); logo.draw(in: rect); ctx.cgContext.resetClip()
            }
            wmText.draw(in: CGRect(x: wmX + logoSize.width + spacing, y: wmY, width: wmTextSize.width, height: wmTextSize.height))
        }
        return UIGraphicsImageRenderer(size: canvas.size, format: format).image { _ in
            UIBezierPath(roundedRect: canvas, cornerRadius: backdrop.cornerRadius).addClip()
            card.draw(at: .zero)
        }
    }

    // MARK: Several ayahs

    /// The entries grouped by surah, in order: a selection that crossed a surah boundary (page mode)
    /// gets one passage and one set of headers per surah.
    static func surahGroups(_ entries: [ShareAyahEntry]) -> [(surah: Surah, entries: [ShareAyahEntry])] {
        var groups: [(surah: Surah, entries: [ShareAyahEntry])] = []
        for entry in entries {
            if let last = groups.indices.last, groups[last].surah.id == entry.surah.id {
                groups[last].entries.append(entry)
            } else {
                groups.append((surah: entry.surah, entries: [entry]))
            }
        }
        return groups
    }

    /// "1-5" for a run of ayahs, "1, 3, 7-9" otherwise; Arabic-Indic digits (and the Arabic comma)
    /// for the Arabic header. Duplicates fold, order is numeric.
    static func referenceLabel(ayahIDs: [Int], arabicDigits: Bool = false) -> String {
        let ids = Array(Set(ayahIDs)).sorted()
        var runs: [String] = []
        var index = 0
        while index < ids.count {
            var end = index
            while end + 1 < ids.count, ids[end + 1] == ids[end] + 1 { end += 1 }
            let from = arabicDigits ? arabicNumberString(from: ids[index]) : String(ids[index])
            let to = arabicDigits ? arabicNumberString(from: ids[end]) : String(ids[end])
            runs.append(end > index ? "\(from)-\(to)" : from)
            index = end + 1
        }
        return runs.joined(separator: arabicDigits ? "، " : ", ")
    }

    /// The text of several ayahs (the Select Ayahs bar's share in text mode): the card's sections in
    /// plain text. `includeRiwayah` is already gated on `showQiraahDetails`, as the single text is.
    static func multiShareText(entries: [ShareAyahEntry], shareSettings: ShareSettings, settings: Settings,
                               includeRiwayah: Bool, riwayahTag: String) -> String {
        var s = ""
        func sepIfNeeded() { if !s.isEmpty { s += "\n\n" } }
        let groups = surahGroups(entries)

        if shareSettings.arabic {
            for group in groups {
                sepIfNeeded()
                if settings.showAyahInformation {
                    s += "[\(Settings.shared.cleanedQuranArabic(group.surah.nameArabic)) \(group.surah.idArabic):\(referenceLabel(ayahIDs: group.entries.map { $0.ayah.id }, arabicDigits: true))]\n"
                }
                s += group.entries.map { entry in
                    shareArabicText(surah: group.surah, ayah: entry.ayah,
                                    cleanArabic: effectiveCleanArabic(shareSettings),
                                    hideArabicDots: effectiveHideArabicDots(shareSettings),
                                    qiraahOverride: entry.arabicQiraah, tail: entry.tail) + " \(entry.ayah.idArabic)"
                }.joined(separator: " ")
            }
        }

        if shareSettings.transliteration {
            for group in groups {
                sepIfNeeded()
                let name = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                    ? combinedName(translit: group.surah.nameTransliteration, english: group.surah.nameEnglish)
                    : group.surah.nameTransliteration
                if settings.showAyahInformation {
                    s += "[\(name) \(group.surah.id):\(referenceLabel(ayahIDs: group.entries.map { $0.hafsAyah.id }))]\n"
                }
                s += group.entries.map { "\($0.hafsAyah.id). \($0.hafsAyah.textTransliteration)" }.joined(separator: "\n")
            }
        }

        if shareSettings.englishSaheeh || shareSettings.englishMustafa {
            for group in groups {
                sepIfNeeded()
                let name = (!shareSettings.transliteration)
                    ? combinedName(translit: group.surah.nameTransliteration, english: group.surah.nameEnglish)
                    : group.surah.nameEnglish
                if settings.showAyahInformation {
                    s += "[\(name) \(group.surah.id):\(referenceLabel(ayahIDs: group.entries.map { $0.hafsAyah.id }))]\n"
                }
                if shareSettings.englishSaheeh {
                    if settings.showAyahInformation { s += "- Saheeh International\n" }
                    s += group.entries.map { "\($0.hafsAyah.id). \($0.hafsAyah.textEnglishSaheeh)" }.joined(separator: "\n")
                }
                if shareSettings.englishMustafa {
                    if shareSettings.englishSaheeh { s += "\n\n" }
                    if settings.showAyahInformation { s += "- Mustafa Khattab\n" }
                    s += group.entries.map { "\($0.hafsAyah.id). \($0.hafsAyah.textEnglishMustafa)" }.joined(separator: "\n")
                }
            }
        }

        if includeRiwayah {
            sepIfNeeded()
            let labels = qiraahLabels(displayQiraah: riwayahTag)
            s += String(localized: "Riwayah: \(labels.english) – \(labels.arabic)")
        }
        if settings.showSurahInformation, groups.count == 1 {
            let only = groups[0].surah
            if includeRiwayah, !s.isEmpty { s += "\n" } else { sepIfNeeded() }
            s += "\(only.ayahCountLabel()) – \(only.pageCountLabel) – \(only.type.capitalized.localizedDisplay) \(only.type == "makkan" ? "🕋" : "🕌")"
        }
        return s
    }

}

#if DEBUG
extension ShareAyahSheet {
    /// "-shareCardGallery [tag]": every backdrop for four sample cards, one PNG each in
    /// Documents/sharecards/<tag>/ (read them with `simctl get_app_container <udid> <bid> data`),
    /// then "SHARE GALLERY <folder>" in the log. Samples: 1:1 with tajweed and the Saheeh line; 2:255
    /// (long) with transliteration; 112:1 without tajweed and both translations (the Allah highlight
    /// in two scripts); 2:1 with tajweed alone, so the madd and ghunnah inks show on every ground.
    static func debugRenderGallery(tag: String) {
        let settings = Settings.shared
        let quranData = QuranData.shared
        let samples: [(name: String, surah: Int, ayah: Int, share: ShareSettings)] = [
            ("fatihah", 1, 1, ShareSettings(arabic: true, englishSaheeh: true, showTajweed: true)),
            ("kursi", 2, 255, ShareSettings(arabic: true, transliteration: true, englishSaheeh: true, showTajweed: true)),
            ("ikhlas", 112, 1, ShareSettings(arabic: true, englishSaheeh: true, englishMustafa: true)),
            ("tajweed", 2, 5, ShareSettings(arabic: true, showTajweed: true)),
        ]
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sharecards/\(tag)", isDirectory: true)
        try? FileManager.default.removeItem(at: folder)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for sample in samples {
            guard let surah = quranData.surah(sample.surah),
                  let ayah = surah.ayahs.first(where: { $0.id == sample.ayah }) else { continue }
            for backdrop in ShareBackdrop.allCases {
                let image = composeCard(surah: surah, ayah: ayah, hafsAyah: ayah, shareSettings: sample.share, settings: settings,
                                        qiraah: "", includeNote: false, noteText: nil, screenWidth: 402, backdrop: backdrop)
                try? image.pngData()?.write(to: folder.appendingPathComponent("\(sample.name)-\(backdrop.rawValue).png"))
            }
        }
        // Several ayahs on one card (the Select Ayahs bar): al-Baqarah 2:1-5 with tajweed and the
        // Saheeh line, on every backdrop.
        if let baqarah = quranData.surah(2) {
            let entries = baqarah.ayahs.filter { (1...5).contains($0.id) }.map {
                ShareAyahEntry(surah: baqarah, ayah: $0, hafsAyah: $0, tail: [], arabicQiraah: "")
            }
            for backdrop in ShareBackdrop.allCases {
                let image = composeCard(entries: entries, shareSettings: ShareSettings(arabic: true, englishSaheeh: true, showTajweed: true),
                                        settings: settings, qiraah: "", includeNote: false, noteText: nil, screenWidth: 402, backdrop: backdrop)
                try? image.pngData()?.write(to: folder.appendingPathComponent("multi-\(backdrop.rawValue).png"))
            }
        }
        // The classic card takes the reader's accent: every preset's contrast on its black ground,
        // as the phone's appearance would have resolved it and as the card now draws it.
        let classic = ShareBackdrop.classic.palette
        for accent in AccentColor.allCases where accent != .custom {
            let raw = UIColor(accent.color)
            let lightResolved = raw.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            let drawn = ShareInk.readable(raw, on: classic.ground, dark: classic.isDark, minimum: 4.5)
            NSLog("SHARE GALLERY accent %@: light-mode ink %.1f:1, drawn %.1f:1", accent.rawValue,
                  ShareInk.contrast(lightResolved, on: classic.ground), ShareInk.contrast(drawn, on: classic.ground))
        }
        NSLog("SHARE GALLERY %@", folder.path)
    }
}
#endif

// `Color.uiColor` is in iPhone/Helpers/UI/ShareSupport.swift (ShareName.swift draws with it too).

private extension UIColor {
    func isVisuallyEqual(to other: UIColor) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        guard getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
              other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else {
            return false
        }
        return abs(r1 - r2) < 0.01
            && abs(g1 - g2) < 0.01
            && abs(b1 - b2) < 0.01
            && abs(a1 - a2) < 0.01
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        ShareAyahSheet(surahNumber: 2, ayahNumber: 5)
    }
}
#endif
