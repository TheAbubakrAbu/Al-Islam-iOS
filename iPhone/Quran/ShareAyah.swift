#if os(iOS)
import SwiftUI

enum ActionMode: String {
    case text
    case image
}

enum ShareAyahRender {
    /// The widest layout measure a share image is drawn at. iPhones are all narrower than this, so
    /// they render at their real screen width as always; iPad/Mac (where `UIScreen.main` reports the
    /// full 800-1400pt display regardless of the window) clamp down to a phone-proportioned card.
    static let maxImageWidth: CGFloat = 440
}

struct ShareAyahSheet: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    @Environment(\.presentationMode) private var presentationMode

    let surahNumber: Int
    let ayahNumber: Int

    @State private var shareSettings = ShareSettings()

    @AppStorage("shareIncludeRiwayah") private var shareIncludeRiwayah = false
    @AppStorage("shareArabicFont") private var storedShareArabicFont = ""
    @AppStorage("shareAyahLastActionMode") private var storedActionModeRaw: String = ActionMode.image.rawValue
    @AppStorage("copyAyahArabic") private var storedCopyArabic = true
    @AppStorage("copyAyahTransliteration") private var storedCopyTransliteration = false
    @AppStorage("copyAyahEnglishSaheeh") private var storedCopyEnglishSaheeh = false
    @AppStorage("copyAyahEnglishMustafa") private var storedCopyEnglishMustafa = false
    @State private var actionMode: ActionMode = .image

    // The sheet's own riwayah, seeded from the reading view's, so switching here never disturbs the reader.
    @State private var shareQiraah: String = Settings.normalizeLegacyRiwayahTag(Settings.shared.displayQiraah)

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

    private var surah: Surah? { quranData.quran.first(where: { $0.id == surahNumber }) }
    private var ayah: Ayah? { surah?.ayahs.first(where: { $0.id == ayahNumber }) }
    // Tajweed data is Hafs-only, so it keys off the sheet's riwayah, not the reader's.
    private var isHafsShare: Bool { shareQiraah.isEmpty }
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
        qiraahOverride: String? = nil
    ) -> String {
        var base = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: qiraahOverride)
        if cleanArabic {
            base = base.removingArabicDiacriticsAndSigns
            if surah.id == 1 && ayah.id == 1 {
                let trimmed = base.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.hasPrefix("بسم") {
                    base = Ayah.bismillahCleanArabic
                }
            }
        }
        return hideArabicDots ? base.removingArabicDots : base
    }

    private static func shareRawArabicText(surah: Surah, ayah: Ayah) -> String {
        ayah.displayArabicText(surahId: surah.id, clean: false)
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

        for start in source.indices {
            if let range = arabicAllahRange(startingAt: start, in: source) {
                ranges.append(range)
            }
        }

        return ranges
    }

    private static func allahHighlightNSRanges(in source: String) -> [NSRange] {
        var ranges: [NSRange] = []

        var englishStart = source.startIndex
        while englishStart < source.endIndex,
              let match = source.range(
                of: "Allah",
                options: [.caseInsensitive, .diacriticInsensitive],
                range: englishStart..<source.endIndex
              ) {
            ranges.append(NSRange(match, in: source))
            englishStart = match.upperBound
        }

        for start in source.indices {
            if let range = arabicAllahNSRange(startingAt: start, in: source) {
                ranges.append(range)
            }
        }

        return ranges
    }

    private static func arabicAllahRange(startingAt start: String.Index, in source: String) -> Range<String.Index>? {
        if allahBase(for: source[start]) == "ا",
           let afterAlif = nextNonArabicMarkIndex(after: start, in: source),
           allahBase(for: source[afterAlif]) == "ل",
           let secondLam = nextNonArabicMarkIndex(after: afterAlif, in: source),
           allahBase(for: source[secondLam]) == "ل",
           let heh = nextNonArabicMarkIndex(after: secondLam, in: source),
           allahBase(for: source[heh]) == "ه" {
            return start..<rangeUpperBound(afterBaseAt: heh, in: source)
        }

        if allahBase(for: source[start]) == "ل",
           let secondLam = nextNonArabicMarkIndex(after: start, in: source),
           allahBase(for: source[secondLam]) == "ل",
           let heh = nextNonArabicMarkIndex(after: secondLam, in: source),
           allahBase(for: source[heh]) == "ه" {
            return start..<rangeUpperBound(afterBaseAt: heh, in: source)
        }

        return nil
    }

    private static func arabicAllahNSRange(startingAt start: String.Index, in source: String) -> NSRange? {
        if allahBase(for: source[start]) == "ا",
           let afterAlif = nextNonArabicMarkIndex(after: start, in: source),
           allahBase(for: source[afterAlif]) == "ل",
           let secondLam = nextNonArabicMarkIndex(after: afterAlif, in: source),
           allahBase(for: source[secondLam]) == "ل",
           let heh = nextNonArabicMarkIndex(after: secondLam, in: source),
           allahBase(for: source[heh]) == "ه" {
            return allahNSRange(from: start, throughHehAt: heh, in: source)
        }

        if allahBase(for: source[start]) == "ل",
           let secondLam = nextNonArabicMarkIndex(after: start, in: source),
           allahBase(for: source[secondLam]) == "ل",
           let heh = nextNonArabicMarkIndex(after: secondLam, in: source),
           allahBase(for: source[heh]) == "ه" {
            return allahNSRange(from: start, throughHehAt: heh, in: source)
        }

        return nil
    }

    private static func allahNSRange(from start: String.Index, throughHehAt heh: String.Index, in source: String) -> NSRange? {
        guard var scalarCursor = heh.samePosition(in: source.unicodeScalars) else { return nil }

        let lower = source.utf16.distance(from: source.startIndex, to: start)
        var upper = source.utf16.distance(from: source.startIndex, to: heh)
        var foundHeh = false

        while scalarCursor < source.unicodeScalars.endIndex {
            let scalar = source.unicodeScalars[scalarCursor]
            if !foundHeh {
                guard scalar.value == 0x0647 else { break }
                foundHeh = true
                upper += scalar.utf16.count
                scalarCursor = source.unicodeScalars.index(after: scalarCursor)
                continue
            }
            guard isArabicAllahHighlightMarkScalar(scalar) else { break }
            upper += scalar.utf16.count
            scalarCursor = source.unicodeScalars.index(after: scalarCursor)
        }

        guard upper > lower else { return nil }
        return NSRange(location: lower, length: upper - lower)
    }

    private static func nextNonArabicMarkIndex(after index: String.Index, in source: String) -> String.Index? {
        var cursor = source.index(after: index)
        while cursor < source.endIndex {
            if !isArabicMark(source[cursor]) {
                return cursor
            }
            cursor = source.index(after: cursor)
        }
        return nil
    }

    private static func rangeUpperBound(afterBaseAt index: String.Index, in source: String) -> String.Index {
        guard var scalarCursor = index.samePosition(in: source.unicodeScalars) else {
            return source.index(after: index)
        }

        var foundBase = false
        while scalarCursor < source.unicodeScalars.endIndex {
            let scalar = source.unicodeScalars[scalarCursor]
            if !foundBase {
                foundBase = scalar.value == 0x0647
                scalarCursor = source.unicodeScalars.index(after: scalarCursor)
                continue
            }
            guard isArabicAllahHighlightMarkScalar(scalar) else { break }
            scalarCursor = source.unicodeScalars.index(after: scalarCursor)
        }

        return scalarCursor.samePosition(in: source) ?? source.index(after: index)
    }

    private static func allahBase(for character: Character) -> Character? {
        for scalar in character.unicodeScalars where !isArabicMarkScalar(scalar) {
            switch scalar.value {
            case 0x0627, 0x0671:
                return "ا"
            case 0x0644:
                return "ل"
            case 0x0647:
                return "ه"
            default:
                continue
            }
        }

        return nil
    }

    private static func isArabicMark(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy(isArabicMarkScalar)
    }

    private static func isArabicAllahHighlightMark(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy(isArabicAllahHighlightMarkScalar)
    }

    private static func isArabicMarkScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x0610...0x061A,
             0x064B...0x065F,
             0x0670,
             0x06D6...0x06ED:
            return true
        default:
            return false
        }
    }

    private static func isArabicAllahHighlightMarkScalar(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x0610...0x061A,
             0x064B...0x065F,
             0x0670:
            return true
        default:
            return false
        }
    }

    // Internal (not private): HadithShareSheet applies the SAME Allah-name reddening to its share card
    // and text preview, so the two share surfaces render the names identically.
    static func applyAllahHighlight(to attributed: NSMutableAttributedString, source: String, enabled: Bool) {
        guard enabled, attributed.length > 0 else { return }
        for range in allahHighlightNSRanges(in: source) {
            attributed.addAttribute(.foregroundColor, value: UIColor.red, range: range)
        }
    }

    private static func allahHighlightedAttributedString(
        _ string: String,
        attributes: [NSAttributedString.Key: Any],
        enabled: Bool
    ) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: string, attributes: attributes)
        applyAllahHighlight(to: attributed, source: string, enabled: enabled)
        return attributed
    }

    static func allahHighlightedSwiftUIText(_ string: String, baseColor: Color, enabled: Bool) -> AttributedString {
        var attributed = AttributedString(string)
        attributed.foregroundColor = baseColor
        guard enabled else { return attributed }
        let mutable = NSMutableAttributedString(attributedString: NSAttributedString(attributed))
        for range in allahHighlightNSRanges(in: string) {
            mutable.addAttribute(.foregroundColor, value: UIColor.red, range: range)
        }
        return AttributedString(mutable)
    }

    private static func shareArabicImageAttributedText(
        surah: Surah,
        ayah: Ayah,
        shareSettings: ShareSettings,
        settings: Settings,
        qiraah: String,
        font: UIFont,
        paragraphStyle: NSParagraphStyle,
        textColor: UIColor
    ) -> NSAttributedString? {
        guard shareSettings.showTajweed,
              qiraah.isEmpty else {
            return nil
        }

        let rawText = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: qiraah)
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
            removeArabicDots: shareSettings.hideArabicDots || settings.removeArabicDots
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
        Self.applyAllahHighlight(to: attributed, source: displayText, enabled: settings.highlightAllahNames)
        return attributed
    }

    private var shareText: String {
        guard let surah = surah, let ayah = ayah else { return "" }

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
                qiraahOverride: shareQiraah
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
                ? "[\(trLabelName) \(surah.id):\(ayah.id)]"
                : nil

            appendBlock(
                label: header,
                text: settings.showAyahInformation ? ayah.textTransliteration : "\(ayah.textTransliteration) (\(ayah.id))"
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
                s += "[\(headerName) \(surah.id):\(ayah.id)]\n"
            }

            if shareSettings.englishSaheeh {
                if settings.showAyahInformation {
                    s += "- Saheeh International\n"
                }

                s += settings.showAyahInformation ? ayah.textEnglishSaheeh : "\(ayah.textEnglishSaheeh) (\(ayah.id))"
            }

            if shareSettings.englishMustafa {
                if shareSettings.englishSaheeh { s += "\n\n" }
                if settings.showAyahInformation {
                    s += "- Mustafa Khattab\n"
                }
                s += settings.showAyahInformation ? ayah.textEnglishMustafa : "\(ayah.textEnglishMustafa) (\(ayah.id))"
            }
        }

        // Note
        if includeNote, let note = noteText {
            appendBlock(label: "Note", text: note)
        }

        // Qiraah type (optional) - one line: Riwayah: English - Arabic
        if settings.showQiraahDetails && shareSettings.includeQiraah {
            let labels = Self.qiraahLabels(displayQiraah: shareQiraah)
            appendBlock(label: nil, text: "Riwayah: \(labels.english) – \(labels.arabic)")
        }

        if settings.showSurahInformation {
            if settings.showQiraahDetails && shareSettings.includeQiraah, !s.isEmpty { s += "\n" } else { sepIfNeeded() }
            s += "\(surah.ayahCountLabel()) – \(surah.pageCountLabel) – \(surah.type.capitalized) \(surah.type == "makkan" ? "🕋" : "🕌")"
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

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                ZStack {
                    if actionMode == .image {
                        if let img = generatedImage {
                            // The PREVIOUS image stays on screen while a regeneration runs (it is never
                            // nilled mid-flight), dimmed slightly so the swap reads as an update, not a
                            // teardown - this is what stopped the sheet's jump-and-reflow on every toggle.
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(24)
                                .padding(.horizontal, 16)
                                .contextMenu { copyMenu(image: img) }
                                .opacity(isGeneratingImage ? 0.6 : 1)
                                .animation(.easeInOut(duration: 0.15), value: isGeneratingImage)
                                .transition(.opacity)
                        } else {
                            // First render only: hold the preview slot at a stable size so the controls
                            // below don't shift when the image lands.
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                        }
                    } else {
                        Text(shareAttributedText)
                            .font(.body)
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(24)
                            .padding(.horizontal, 16)
                            .contextMenu { copyMenu(image: generatedImage) }
                            .lineLimit(nil)
                            .minimumScaleFactor(0.1)
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    }
                }
                .scaleEffect(isSharing ? 0.98 : 1)
                .animation(.easeInOut, value: actionMode)
                .animation(.easeInOut, value: isSharing)

                Spacer()

                ScrollView {
                    VStack(spacing: 2) {
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
                                .scaleEffect(0.8)
                                .padding(.horizontal, -24)
                                .padding(.vertical, 2)
                        }

                        if shareSettings.arabic {
                            if actionMode == .image && !shareSettings.hideArabicDots {
                                Picker("Arabic Font", selection: Binding(
                                    get: {
                                        Settings.normalizedArabicFontName(
                                            shareSettings.shareArabicFont.isEmpty ? settings.fontArabic : shareSettings.shareArabicFont
                                        )
                                    },
                                    set: { val in
                                        let normalizedFont = Settings.normalizedArabicFontName(val)
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
                                ).animation(.easeInOut)) {
                                    Text("Uthmani").tag(Settings.hafsUthmaniFontName)
                                    Text("Indopak").tag(Settings.indopakFontName)
                                    Text("Basic").tag(Settings.systemArabicFontName)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 2)
                            }

                            if actionMode == .image && isHafsShare {
                                Toggle("Show Tajweed", isOn: Binding(
                                    get: { shareSettings.showTajweed },
                                    set: { shareSettings = updatedShareSettings(showTajweed: $0) }
                                ).animation(.easeInOut))
                                .tint(settings.accentColor.color)
                                .scaleEffect(0.8)
                                .padding(.horizontal, -24)
                                .padding(.vertical, 2)
                            }

                            Toggle("Hide Tashkeel and Diacretics", isOn: $shareSettings.cleanArabic.animation(.easeInOut))
                                .tint(settings.accentColor.color)
                                .scaleEffect(0.8)
                                .padding(.horizontal, -24)
                                .padding(.vertical, 2)

                            if canShowHideArabicDotsToggle {
                                Toggle("Hide Arabic Dots", isOn: Binding(
                                    get: { shareSettings.hideArabicDots },
                                    set: { shareSettings = updatedShareSettings(hideArabicDots: $0) }
                                ).animation(.easeInOut))
                                .tint(settings.accentColor.color)
                                .scaleEffect(0.8)
                                .padding(.horizontal, -24)
                                .padding(.vertical, 2)
                            }
                        }

                        Toggle("Show Ayah Information", isOn: $settings.showAyahInformation.animation(.easeInOut))
                            .tint(settings.accentColor.color)
                            .scaleEffect(0.8)
                            .padding(.horizontal, -24)
                            .padding(.vertical, 2)

                        Toggle("Show Surah Information", isOn: $settings.showSurahInformation.animation(.easeInOut))
                            .tint(settings.accentColor.color)
                            .scaleEffect(0.8)
                            .padding(.horizontal, -24)
                            .padding(.vertical, 2)

                        if settings.showQiraahDetails {
                            Toggle(isOn: Binding(
                                get: { shareSettings.includeQiraah },
                                set: { newValue in
                                    // On Hafs the flip IS the saved preference. On any other riwayah the
                                    // flip is session-only - the next riwayah change re-resolves it, and
                                    // the Hafs preference stays untouched.
                                    if !Settings.isNonHafsQiraah(shareQiraah) {
                                        shareIncludeRiwayah = newValue
                                    }
                                    shareSettings = updatedShareSettings(includeQiraah: newValue)
                                }
                            )
                                .animation(.easeInOut)) {
                                Label("Show Riwayah/Qiraah", systemImage: "character.book.closed.fill.ar")
                            }
                            .tint(settings.accentColor.color)
                            .scaleEffect(0.8)
                            .padding(.horizontal, -24)
                            .padding(.vertical, 2)

                            // Last in the list, by request: which riwayah the shared Arabic is taken from.
                            //
                            // `useMenuRow`, NOT the bare glass chip. The chip form wraps its label in
                            // `conditionalGlassEffect()`, which on iOS 26 is INTERACTIVE Liquid Glass - the
                            // glass takes the touch to play its own press response, so the chip lit up like
                            // a button and the menu never opened ("I touch it and it acts like a button not
                            // a picker"). The row form's label is plain, with the whole row as one
                            // `contentShape` tap target - the same form the Settings screen and
                            // `SelectAyahTextSheet` use, where the picker has always opened correctly.
                            ArabicTextRiwayahPicker(
                                selection: $shareQiraah.animation(.easeInOut),
                                useMenuRow: true
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            .padding(.bottom, 4)

                            Text(ayahExistsInShareQiraah
                                ? "Ayah numbering can differ between riwayat: no ayah is ever missing, but some are joined or split differently (for example, \"Alif Lam Meem\" and \"Dhalika al-Kitab...\" form a single ayah in most qiraat)."
                                : "This ayah is not separate in this riwayah; its words are part of a neighboring ayah, so the Hafs text is shown.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 4)
                        }
                    }
                }
                .frame(maxHeight: 200)

                Picker("Action Mode", selection: $actionMode.animation(.easeInOut)) {
                    Text("Image").tag(ActionMode.image)
                    Text("Text").tag(ActionMode.text)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 4)

                HStack(spacing: 12) {
                    actionButton("Copy") {
                        performCopyOrGenerate()
                    }

                    actionButton("Share", isAnimating: isSharing)  {
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
            .navigationTitle(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: ayahNumber))
            .navigationBarTitleDisplayMode(.inline)
            // This sheet had no dismiss control at all - you could only swipe it away or complete a share.
            .sheetDismissToolbar()
            // Full-size before the wash so the background always covers the whole sheet.
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accentWashedBackground()
        }
        .navigationViewStyle(.stack)
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

                actionMode = ActionMode(rawValue: storedActionModeRaw) ?? .image
                generatePreviewImage()
            }

            DispatchQueue.main.async {
                didFinishInitialSetup = true
            }
        }

        .onChange(of: actionMode) { newValue in
            if didFinishInitialSetup { settings.hapticFeedback() }
            storedActionModeRaw = newValue.rawValue
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
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    @ViewBuilder
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



    private func performCopyOrGenerate() {
        settings.hapticFeedback()

        switch actionMode {
        case .text:
            UIPasteboard.general.string = shareText
            presentationMode.wrappedValue.dismiss()
        case .image:
            if let img = generatedImage {
                UIPasteboard.general.image = img
                presentationMode.wrappedValue.dismiss()
            } else {
                generatePreviewImage { img in
                    UIPasteboard.general.image = img
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    private func performShareOrGenerate() {
        switch actionMode {
        case .text:
            presentShareSheet(with: [shareText])
        case .image:
            if let img = generatedImage {
                presentShareSheet(with: [img])
            } else {
                generatePreviewImage { img in
                    presentShareSheet(with: [img])
                }
            }
        }
    }

    private func generatePreviewImage(completion: @escaping (UIImage) -> Void = { _ in }) {
        // Snapshot EVERY main-actor input on main, before hopping to the render queue: the queue must never
        // read view state (shareSettings, shareQiraah, the note) that a later toggle could be rewriting.
        let snapshot = shareSettings
        let qiraahSnapshot = shareQiraah
        let includeNoteSnapshot = includeNote
        let noteSnapshot = noteText
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
                    shareSettings: snapshot,
                    qiraah: qiraahSnapshot,
                    includeNote: includeNoteSnapshot,
                    noteText: noteSnapshot,
                    screenWidth: screenWidth
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

    private func drawImage(shareSettings: ShareSettings, qiraah shareQiraah: String, includeNote: Bool, noteText: String?, screenWidth: CGFloat) -> UIImage {
        guard let surah = surah, let ayah = ayah else { return UIImage() }

        // Rounded, to match the app's system-font design (the `fontDesign` environment does not reach this
        // UIKit-drawn image, so the design is asked for explicitly).
        let bodyFont   = UIFont.roundedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
        let selectedArabicFontName = shareSettings.shareArabicFont.isEmpty ? settings.fontArabic : shareSettings.shareArabicFont
        let arabicFontName = Settings.quranArabicFontName(selectedFontName: selectedArabicFontName, qiraah: shareQiraah, style: settings.arabicScriptStyle)
        let arabicFont = shareSettings.hideArabicDots
            ? bodyFont.withSize(bodyFont.pointSize * 1.15)
            // The "Basic" sentinel has no real UIFont - it falls back to the ROUNDED system face at the
            // same 1.15x Arabic scale (the bare bodyFont fallback silently shrank Basic Arabic).
            : (UIFont(name: arabicFontName, size: bodyFont.pointSize * 1.15)
                ?? UIFont.roundedSystemFont(ofSize: bodyFont.pointSize * 1.15))
        let arabicNumberFont = UIFont(name: Settings.hafsUthmaniFontName, size: bodyFont.pointSize * 1.15) ?? arabicFont
        let captionFont = UIFont.roundedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize)

        let textColor      = UIColor.white
        let secondaryColor = UIColor.secondaryLabel
        let accent         = settings.accentColor.color.uiColor

        // --- Layout constants
        let padding: CGFloat = 20, spacing: CGFloat = 8, extraSpacing: CGFloat = 30
        let iPhoneCanvasCap: CGFloat = 500
        let deviceWidth = screenWidth - 50
        let maxWidth = min(deviceWidth, iPhoneCanvasCap)

        // Paragraph styles
        let right = NSMutableParagraphStyle();  right.alignment = .right
        let left  = NSMutableParagraphStyle();  left.alignment  = .left
        let cent  = NSMutableParagraphStyle();  cent.alignment  = .center

        // Attr dictionaries
        let bodyAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: textColor] as [NSAttributedString.Key: Any]
        let arAttr = [NSAttributedString.Key.font: arabicFont, .foregroundColor: textColor, .paragraphStyle: right]
        let arNumberAttr = [NSAttributedString.Key.font: arabicNumberFont, .foregroundColor: textColor, .paragraphStyle: right]
        let accentAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent,    .paragraphStyle: left]
        let arAccent = [NSAttributedString.Key.font: arabicFont, .foregroundColor: accent,    .paragraphStyle: right]
        let centAccent = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent,    .paragraphStyle: cent]
        let captionAttr = [NSAttributedString.Key.font: captionFont, .foregroundColor: secondaryColor,.paragraphStyle: left]
        let captionCentAttr = [NSAttributedString.Key.font: captionFont, .foregroundColor: secondaryColor, .paragraphStyle: cent] as [NSAttributedString.Key: Any]

        // --- Compose full attributed text once
        let text = NSMutableAttributedString()
        func append(_ str: String, _ attrs: [NSAttributedString.Key: Any], highlightAllah: Bool = true) {
            text.append(Self.allahHighlightedAttributedString(str, attributes: attrs, enabled: highlightAllah && settings.highlightAllahNames))
        }
        func appendAttributed(_ attributed: NSAttributedString) { text.append(attributed) }
        func sepIfNeeded() { if text.length > 0 { append("\n\n", bodyAttr, highlightAllah: false) } }

        // Arabic
        if shareSettings.arabic {
            let arabicText = Self.shareArabicText(
                surah: surah,
                ayah: ayah,
                cleanArabic: effectiveCleanArabic,
                hideArabicDots: effectiveHideArabicDots,
                qiraahOverride: shareQiraah
            )

            if settings.showAyahInformation {
                append("[\(Settings.shared.cleanedQuranArabic(surah.nameArabic)) ", arAccent, highlightAllah: false)
                append("\(surah.idArabic):\(ayah.idArabic)]", accentAttr, highlightAllah: false)
                append("\n", bodyAttr, highlightAllah: false)
            } else {
            }

            if let tajweedText = Self.shareArabicImageAttributedText(
                surah: surah,
                ayah: ayah,
                shareSettings: shareSettings,
                settings: settings,
                qiraah: shareQiraah,
                font: arabicFont,
                paragraphStyle: right,
                textColor: textColor
            ) {
                appendAttributed(tajweedText)
                if !settings.showAyahInformation {
                    append(" \(ayah.idArabic)", arNumberAttr, highlightAllah: false)
                }
            } else {
                append(arabicText, arAttr)
                if !settings.showAyahInformation {
                    append(" \(ayah.idArabic)", arNumberAttr, highlightAllah: false)
                }
            }
        }

        // Transliteration (always offered; the text itself follows Hafs numbering)
        if shareSettings.transliteration {
            let trLabelName = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa)
                ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                : surah.nameTransliteration

            sepIfNeeded()

            if settings.showAyahInformation {
                append("[\(trLabelName) \(surah.id):\(ayah.id)]", accentAttr, highlightAllah: false)
                append("\n", bodyAttr, highlightAllah: false)
            }

            append(settings.showAyahInformation ? ayah.textTransliteration : "\(ayah.textTransliteration) (\(ayah.id))", bodyAttr)
        }

        let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
        if wantsAnyEnglish {
            let enHeaderName = (!shareSettings.transliteration)
                ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish)
                : surah.nameEnglish

            sepIfNeeded()

            if settings.showAyahInformation {
                append("[\(enHeaderName) \(surah.id):\(ayah.id)]", accentAttr, highlightAllah: false)
                append("\n", bodyAttr, highlightAllah: false)
            }

            if shareSettings.englishSaheeh {
                if settings.showAyahInformation {
                    append("- Saheeh International", captionAttr, highlightAllah: false)
                    append("\n", bodyAttr, highlightAllah: false)
                }
                append(settings.showAyahInformation ? ayah.textEnglishSaheeh : "\(ayah.textEnglishSaheeh) (\(ayah.id))", bodyAttr)
            }

            if shareSettings.englishMustafa {
                if shareSettings.englishSaheeh { append("\n\n", bodyAttr, highlightAllah: false) }

                if settings.showAyahInformation {
                    append("- Clear Quran (Mustafa Khattab)", captionAttr, highlightAllah: false)
                    append("\n", bodyAttr, highlightAllah: false)
                }
                append(settings.showAyahInformation ? ayah.textEnglishMustafa : "\(ayah.textEnglishMustafa) (\(ayah.id))", bodyAttr)
            }
        }

        if includeNote, let note = noteText {
            sepIfNeeded()
            append("- Note", captionAttr, highlightAllah: false)
            append("\n", bodyAttr, highlightAllah: false)
            append(note, bodyAttr)
        }

        if shareSettings.includeQiraah {
            sepIfNeeded()
            let labels = Self.qiraahLabels(displayQiraah: shareQiraah)
            append("Riwayah: \(labels.english) – \(labels.arabic)", captionCentAttr, highlightAllah: false)
        }
        if settings.showSurahInformation {
            if shareSettings.includeQiraah { append("\n", bodyAttr, highlightAllah: false) } else { sepIfNeeded() }
            append("\(surah.ayahCountLabel()) – \(surah.pageCountLabel) – \(surah.type.capitalized) \(surah.type == "makkan" ? "🕋" : "🕌")", captionCentAttr, highlightAllah: false)
        }
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
        textRect.size.height += logoSize.height + extraSpacing + 25

        let canvas = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: textRect.height))

        let r1 = UIGraphicsImageRenderer(size: canvas.size)
        let blackCard = r1.image { ctx in
            UIColor.black.setFill(); ctx.fill(canvas)
            text.draw(in: CGRect(x: padding, y: padding, width: canvas.width - 2*padding, height: canvas.height))

            let wmY = canvas.height - logoSize.height - extraSpacing/2
            let wmX = (canvas.width - (logoSize.width + spacing + wmTextSize.width)) / 2
            if let logo = logo {
                let rect = CGRect(origin: CGPoint(x: wmX, y: wmY), size: logoSize)
                ctx.cgContext.addPath(UIBezierPath(roundedRect: rect, cornerRadius: logoSize.height*0.25).cgPath)
                ctx.cgContext.clip(); logo.draw(in: rect); ctx.cgContext.resetClip()
            }
            wmText.draw(in: CGRect(x: wmX + logoSize.width + spacing, y: wmY, width: wmTextSize.width, height: wmTextSize.height))
        }
        return UIGraphicsImageRenderer(size: canvas.size).image { _ in
            UIBezierPath(roundedRect: canvas, cornerRadius: 20).addClip()
            blackCard.draw(at: .zero)
        }
    }
}

// MARK: - Copy Ayah (matches Share sheet: image or text per stored preference)
extension ShareAyahSheet {
    private static let copyActionModeKey = "shareAyahLastActionMode"

    private static let shareIncludeRiwayahKey = "shareIncludeRiwayah"

    /// - Parameter mode: what to put on the pasteboard. Nil follows the share sheet's remembered
    ///   choice, which is what a single "Copy" action wants. The mushaf's actions sheet offers Copy
    ///   Text and Copy Image as separate tiles and passes the mode outright, so what you tap is what
    ///   you get rather than whatever you last shared as.
    static func copyAyahToPasteboard(surahNumber: Int, ayahNumber: Int, settings: Settings,
                                     quranData: QuranData, mode: ActionMode? = nil) {
        guard let surah = quranData.quran.first(where: { $0.id == surahNumber }),
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

        switch actionMode {
        case .text:
            let text = buildShareText(surah: surah, ayah: ayah, shareSettings: shareSettings, settings: settings, includeNote: includeNote, noteText: noteText)
            UIPasteboard.general.string = text
        case .image:
            // UIScreen.main is main-thread-only; capture the width here (still on main) for the queue below.
            // Same phone-like clamp as the share-sheet render - see `ShareAyahRender.maxImageWidth`.
            let screenWidth = min(UIScreen.main.bounds.width, ShareAyahRender.maxImageWidth)
            DispatchQueue.global(qos: .userInitiated).async {
                let img = buildShareImage(surah: surah, ayah: ayah, shareSettings: shareSettings, settings: settings, includeNote: includeNote, noteText: noteText, screenWidth: screenWidth)
                DispatchQueue.main.async {
                    UIPasteboard.general.image = img
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

    private static func buildShareText(surah: Surah, ayah: Ayah, shareSettings: ShareSettings, settings: Settings, includeNote: Bool, noteText: String?) -> String {
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
            let header: String? = settings.showAyahInformation ? "[\(trLabelName) \(surah.id):\(ayah.id)]" : nil
            appendBlock(label: header, text: settings.showAyahInformation ? ayah.textTransliteration : "\(ayah.textTransliteration) (\(ayah.id))")
        }
        let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
        if wantsAnyEnglish {
            let headerName = (!shareSettings.transliteration) ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish) : surah.nameEnglish
            sepIfNeeded()
            if settings.showAyahInformation { s += "[\(headerName) \(surah.id):\(ayah.id)]\n" }
            if shareSettings.englishSaheeh {
                if settings.showAyahInformation { s += "- Saheeh International\n" }
                s += settings.showAyahInformation ? ayah.textEnglishSaheeh : "\(ayah.textEnglishSaheeh) (\(ayah.id))"
            }
            if shareSettings.englishMustafa {
                if shareSettings.englishSaheeh { s += "\n\n" }
                if settings.showAyahInformation { s += "- Mustafa Khattab\n" }
                s += settings.showAyahInformation ? ayah.textEnglishMustafa : "\(ayah.textEnglishMustafa) (\(ayah.id))"
            }
        }
        if includeNote, let note = noteText { appendBlock(label: "Note", text: note) }
        if shareSettings.includeQiraah {
            let labels = qiraahLabels(displayQiraah: settings.displayQiraah)
            appendBlock(label: nil, text: "Riwayah: \(labels.english) – \(labels.arabic)")
        }
        if settings.showSurahInformation {
            if shareSettings.includeQiraah, !s.isEmpty { s += "\n" } else { sepIfNeeded() }
            s += "\(surah.ayahCountLabel()) – \(surah.pageCountLabel) – \(surah.type.capitalized) \(surah.type == "makkan" ? "🕋" : "🕌")"
        }
        return s
    }

    private static func buildShareImage(surah: Surah, ayah: Ayah, shareSettings: ShareSettings, settings: Settings, includeNote: Bool, noteText: String?, screenWidth: CGFloat) -> UIImage {
        // Rounded, to match the app's system-font design (see the note in the other renderer above).
        let bodyFont = UIFont.roundedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
        let selectedArabicFontName = shareSettings.shareArabicFont.isEmpty ? settings.fontArabic : shareSettings.shareArabicFont
        let arabicFontName = Settings.quranArabicFontName(selectedFontName: selectedArabicFontName, qiraah: settings.displayQiraahForArabic, style: settings.arabicScriptStyle)
        let arabicFont = shareSettings.hideArabicDots
            ? bodyFont.withSize(bodyFont.pointSize * 1.15)
            // The "Basic" sentinel has no real UIFont - it falls back to the ROUNDED system face at the
            // same 1.15x Arabic scale (the bare bodyFont fallback silently shrank Basic Arabic).
            : (UIFont(name: arabicFontName, size: bodyFont.pointSize * 1.15)
                ?? UIFont.roundedSystemFont(ofSize: bodyFont.pointSize * 1.15))
        let arabicNumberFont = UIFont(name: Settings.hafsUthmaniFontName, size: bodyFont.pointSize * 1.15) ?? arabicFont
        let captionFont = UIFont.roundedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .caption2).pointSize)
        let textColor = UIColor.white
        let secondaryColor = UIColor.secondaryLabel
        let accent = settings.accentColor.color.uiColor
        let padding: CGFloat = 20, spacing: CGFloat = 8, extraSpacing: CGFloat = 30
        let iPhoneCanvasCap: CGFloat = 500
        let deviceWidth = screenWidth - 50
        let maxWidth = min(deviceWidth, iPhoneCanvasCap)
        let right = NSMutableParagraphStyle(); right.alignment = .right
        let left = NSMutableParagraphStyle(); left.alignment = .left
        let cent = NSMutableParagraphStyle(); cent.alignment = .center
        let bodyAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: textColor] as [NSAttributedString.Key: Any]
        let arAttr = [NSAttributedString.Key.font: arabicFont, .foregroundColor: textColor, .paragraphStyle: right] as [NSAttributedString.Key: Any]
        let arNumberAttr = [NSAttributedString.Key.font: arabicNumberFont, .foregroundColor: textColor, .paragraphStyle: right] as [NSAttributedString.Key: Any]
        let accentAttr = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let _ = [NSAttributedString.Key.font: arabicFont, .foregroundColor: accent, .paragraphStyle: right] as [NSAttributedString.Key: Any]
        let centAccent = [NSAttributedString.Key.font: bodyFont, .foregroundColor: accent, .paragraphStyle: cent] as [NSAttributedString.Key: Any]
        let captionAttr = [NSAttributedString.Key.font: captionFont, .foregroundColor: secondaryColor, .paragraphStyle: left] as [NSAttributedString.Key: Any]
        let captionCentAttr = [NSAttributedString.Key.font: captionFont, .foregroundColor: secondaryColor, .paragraphStyle: cent] as [NSAttributedString.Key: Any]
        let text = NSMutableAttributedString()
        func append(_ str: String, _ attrs: [NSAttributedString.Key: Any], highlightAllah: Bool = true) {
            text.append(Self.allahHighlightedAttributedString(str, attributes: attrs, enabled: highlightAllah && settings.highlightAllahNames))
        }
        func appendAttributed(_ attributed: NSAttributedString) { text.append(attributed) }
        func sepIfNeeded() { if text.length > 0 { append("\n\n", bodyAttr, highlightAllah: false) } }
        if shareSettings.arabic {
            let arabicText = Self.shareArabicText(
                surah: surah,
                ayah: ayah,
                cleanArabic: effectiveCleanArabic(shareSettings),
                hideArabicDots: effectiveHideArabicDots(shareSettings),
                qiraahOverride: settings.displayQiraahForArabic
            )
            if settings.showAyahInformation {
            } else {
            }

            if let tajweedText = Self.shareArabicImageAttributedText(
                surah: surah,
                ayah: ayah,
                shareSettings: shareSettings,
                settings: settings,
                qiraah: Settings.normalizeLegacyRiwayahTag(settings.displayQiraah),
                font: arabicFont,
                paragraphStyle: right,
                textColor: textColor
            ) {
                if settings.showAyahInformation {
                    append("[\(Settings.shared.cleanedQuranArabic(surah.nameArabic)) \(surah.idArabic):\(ayah.idArabic)]\n", arAttr, highlightAllah: false)
                }
                appendAttributed(tajweedText)
                if !settings.showAyahInformation {
                    append(" \(ayah.idArabic)", arNumberAttr, highlightAllah: false)
                }
            } else {
                if settings.showAyahInformation {
                    append("[\(Settings.shared.cleanedQuranArabic(surah.nameArabic)) \(surah.idArabic):\(ayah.idArabic)]\n", arAttr, highlightAllah: false)
                }
                append(arabicText, arAttr)
                if !settings.showAyahInformation {
                    append(" \(ayah.idArabic)", arNumberAttr, highlightAllah: false)
                }
            }
        }
        if shareSettings.transliteration {
            let trLabelName = (!shareSettings.englishSaheeh && !shareSettings.englishMustafa) ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish) : surah.nameTransliteration
            sepIfNeeded()
            if settings.showAyahInformation { append("[\(trLabelName) \(surah.id):\(ayah.id)]", accentAttr, highlightAllah: false); append("\n", bodyAttr, highlightAllah: false) }
            append(settings.showAyahInformation ? ayah.textTransliteration : "\(ayah.textTransliteration) (\(ayah.id))", bodyAttr)
        }
        let wantsAnyEnglish = shareSettings.englishSaheeh || shareSettings.englishMustafa
        if wantsAnyEnglish {
            let enHeaderName = (!shareSettings.transliteration) ? combinedName(translit: surah.nameTransliteration, english: surah.nameEnglish) : surah.nameEnglish
            sepIfNeeded()
            if settings.showAyahInformation { append("[\(enHeaderName) \(surah.id):\(ayah.id)]", accentAttr, highlightAllah: false); append("\n", bodyAttr, highlightAllah: false) }
            if shareSettings.englishSaheeh {
                if settings.showAyahInformation { append("- Saheeh International", captionAttr, highlightAllah: false); append("\n", bodyAttr, highlightAllah: false) }
                append(settings.showAyahInformation ? ayah.textEnglishSaheeh : "\(ayah.textEnglishSaheeh) (\(ayah.id))", bodyAttr)
            }
            if shareSettings.englishMustafa {
                if shareSettings.englishSaheeh { append("\n\n", bodyAttr, highlightAllah: false) }
                if settings.showAyahInformation { append("- Clear Quran (Mustafa Khattab)", captionAttr, highlightAllah: false); append("\n", bodyAttr, highlightAllah: false) }
                append(settings.showAyahInformation ? ayah.textEnglishMustafa : "\(ayah.textEnglishMustafa) (\(ayah.id))", bodyAttr)
            }
        }
        if includeNote, let note = noteText { sepIfNeeded(); append("- Note", captionAttr, highlightAllah: false); append("\n", bodyAttr, highlightAllah: false); append(note, bodyAttr) }
        if shareSettings.includeQiraah {
            sepIfNeeded()
            let labels = qiraahLabels(displayQiraah: settings.displayQiraah)
            append("Riwayah: \(labels.english) – \(labels.arabic)", captionCentAttr, highlightAllah: false)
        }
        if settings.showSurahInformation {
            if shareSettings.includeQiraah { append("\n", bodyAttr, highlightAllah: false) } else { sepIfNeeded() }
            append("\(surah.ayahCountLabel()) – \(surah.pageCountLabel) – \(surah.type.capitalized) \(surah.type == "makkan" ? "🕋" : "🕌")", captionCentAttr, highlightAllah: false)
        }
        let wmString = AppIdentifiers.appFullName
        let wmText = NSAttributedString(string: wmString, attributes: centAccent)
        var logo = UIImage(named: AppIdentifiers.appName)
        var wmTextSize = wmText.size()
        var logoSize = CGSize(width: wmTextSize.height, height: wmTextSize.height)
        let availWidth = maxWidth - 2 * padding
        let desiredWmW = logoSize.width + spacing + wmTextSize.width
        if desiredWmW > availWidth {
            let scale = availWidth / desiredWmW
            wmTextSize = CGSize(width: wmTextSize.width * scale, height: wmTextSize.height * scale)
            logoSize = CGSize(width: logoSize.width * scale, height: logoSize.height * scale)
            if let img = logo {
                let r = UIGraphicsImageRenderer(size: logoSize)
                logo = r.image { _ in img.draw(in: CGRect(origin: .zero, size: logoSize)) }
            }
        }
        let constraint = CGSize(width: availWidth, height: .greatestFiniteMagnitude)
        var textRect = text.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral
        textRect.size.width += 2 * padding
        textRect.size.height += logoSize.height + extraSpacing + 25
        let canvas = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: textRect.height))
        let r1 = UIGraphicsImageRenderer(size: canvas.size)
        let blackCard = r1.image { ctx in
            UIColor.black.setFill(); ctx.fill(canvas)
            text.draw(in: CGRect(x: padding, y: padding, width: canvas.width - 2 * padding, height: canvas.height))
            let wmY = canvas.height - logoSize.height - extraSpacing / 2
            let wmX = (canvas.width - (logoSize.width + spacing + wmTextSize.width)) / 2
            if let logo = logo {
                let rect = CGRect(origin: CGPoint(x: wmX, y: wmY), size: logoSize)
                ctx.cgContext.addPath(UIBezierPath(roundedRect: rect, cornerRadius: logoSize.height * 0.25).cgPath)
                ctx.cgContext.clip(); logo.draw(in: rect); ctx.cgContext.resetClip()
            }
            wmText.draw(in: CGRect(x: wmX + logoSize.width + spacing, y: wmY, width: wmTextSize.width, height: wmTextSize.height))
        }
        return UIGraphicsImageRenderer(size: canvas.size).image { _ in
            UIBezierPath(roundedRect: canvas, cornerRadius: 20).addClip()
            blackCard.draw(at: .zero)
        }
    }

}

extension Color { var uiColor: UIColor { UIColor(self) } }

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
