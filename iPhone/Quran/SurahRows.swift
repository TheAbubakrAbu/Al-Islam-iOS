import SwiftUI

/// Measured widths for the fixed-format number badges ("100", "10:100"), keyed by template + text style
/// + the resolved font's point size (which tracks Dynamic Type). The measurement - `UIFont.preferredFont`
/// plus an `NSString.size` layout pass - used to run in every row body; the answer only changes when the
/// user's text size does. Main-thread only, like every row body that reads it.
enum BadgeWidthCache {
    private static var cache: [String: CGFloat] = [:]

    static func width(template: String, style: UIFont.TextStyle = .headline) -> CGFloat {
        let font = UIFont.preferredFont(forTextStyle: style)
        let key = "\(template)|\(style.rawValue)|\(font.pointSize)"
        if let cached = cache[key] { return cached }
        let width = (template as NSString).size(withAttributes: [.font: font]).width + 8
        cache[key] = width
        return width
    }
}

/// A slim, unobtrusive progress bar used under the last-read / last-listened rows.
struct TinyProgressBar: View {
    let fraction: Double
    let color: Color

    var body: some View {
        // The base capsule defines the bar's size (full width, fixed height); the fill is an overlay so it
        // never collapses to a sliver while the enclosing list row is still computing its layout.
        Capsule()
            .fill(color.opacity(0.22))
            .frame(height: 3)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    Capsule()
                        .fill(color)
                        .frame(width: max(0, min(1, fraction)) * geo.size.width, height: 3)
                }
            }
            .accessibilityHidden(true)
    }
}

struct SurahRow: View, Equatable {
    @ObservedObject var settings = Settings.shared
    
    let surah: Surah
    var ayah: Int?
    var end: Bool?
    let favoriteState: Bool
    let showInfo: Bool
    let accentColor: AccentColor
    let useFontArabic: Bool
    let fontArabic: String
    let khatmCompletedAyahs: Int?
    let khatmTotalAyahs: Int?
    let searchQuery: String
    /// When true, renders the same row content wrapped as a grid card (so grid == list look).
    let grid: Bool
    // Snapshotted at init so `==` can see them: the body reads these through `settings`, and an Equatable view
    // that reads state its `==` ignores renders stale when that state changes.
    let sortModeKey: String
    let displayQiraahKey: String
    /// This surah holds the last-read position - its number pill gets a book badge
    /// (the favorite grammar, with a book instead of a star) so "continue here" reads at a glance.
    let isLastRead: Bool
    /// The listening twin: this surah holds the last-listened full-surah playback position, so the
    /// pill gets a speaker badge. Star > book > speaker when a surah qualifies for more than one.
    let isLastListened: Bool

    init(
        surah: Surah,
        ayah: Int? = nil,
        end: Bool? = nil,
        isFavorite: Bool? = nil,
        hideInfo: Bool? = nil,
        accentColor: AccentColor = Settings.shared.accentColor,
        useFontArabic: Bool = Settings.shared.useFontArabic,
        fontArabic: String = Settings.shared.quranDisplayFontName,
        khatmCompletedAyahs: Int? = nil,
        khatmTotalAyahs: Int? = nil,
        searchQuery: String = "",
        grid: Bool = false
    ) {
        self.surah = surah
        self.ayah = ayah
        self.end = end
        self.favoriteState = isFavorite ?? Settings.shared.isSurahFavorite(surah: surah.id)
        self.showInfo = hideInfo.map { !$0 } ?? Settings.shared.showFullSurahRow
        self.accentColor = accentColor
        self.useFontArabic = useFontArabic
        self.fontArabic = fontArabic
        self.khatmCompletedAyahs = khatmCompletedAyahs
        self.khatmTotalAyahs = khatmTotalAyahs
        self.searchQuery = searchQuery
        self.grid = grid
        self.sortModeKey = Settings.shared.quranSortMode.rawValue
        self.displayQiraahKey = Settings.shared.displayQiraahForArabic ?? ""
        self.isLastRead = Settings.shared.saveLastReadAyah && Settings.shared.lastReadSurah == surah.id
        self.isLastListened = Settings.shared.lastListenedSurah?.surahNumber == surah.id
    }

    private var revelationEmoji: String {
        surah.type == "makkan" ? "🕋" : "🕌"
    }

    private var revelationName: String {
        surah.type == "makkan" ? "Makkan" : "Madinan"
    }

    private var pageCountLabel: String {
        let count = max(surah.pageCount, 1)
        if count == 1, surah.isLessThanOnePage == true {
            return "<1 Page"
        }
        return count == 1 ? "1 Page" : "\(count) Pages"
    }

    private var startPageNumber: Int {
        surah.pageStart ?? surah.ayahs.compactMap(\.page).min() ?? 1
    }

    private var ayahAndRevelationLine: String {
        "\(surah.numberOfAyahs) Ayahs \(revelationEmoji)"
    }

    private var sortedMetricLine: String? {
        switch settings.quranSortMode {
        case .ayahs:
            return surah.ayahCountLabel(for: settings.displayQiraahForArabic)
        case .page:
            return pageCountLabel
        case .words:
            return "Words: \(surah.wordCount)"
        case .letters:
            return "Letters: \(surah.letterCount)"
        default:
            return nil
        }
    }

    private var pageLine: String {
        "Page \(startPageNumber) • \(pageCountLabel)"
    }

    private var positionContextLine: String? {
        guard let ayah else { return nil }
        if end != nil {
            return "Ends at \(surah.id):\(ayah)"
        }
        return "Starts at \(surah.id):\(ayah)"
    }

    private var badgeWidth: CGFloat {
        BadgeWidthCache.width(template: "100")
    }

    private var isKhatmComplete: Bool {
        guard let khatmCompletedAyahs, let khatmTotalAyahs else { return false }
        return khatmTotalAyahs > 0 && khatmCompletedAyahs >= khatmTotalAyahs
    }

    private var isKhatmPartiallyComplete: Bool {
        guard let khatmCompletedAyahs, let khatmTotalAyahs else { return false }
        return khatmCompletedAyahs > 0 && khatmCompletedAyahs < khatmTotalAyahs
    }

    @ViewBuilder
    private var khatmProgressLine: some View {
        if let khatmCompletedAyahs, let khatmTotalAyahs {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Image(systemName: isKhatmComplete ? "checkmark.circle.fill" : "circle.dashed")
                        .font(.caption2.weight(.semibold))
                    Text("\(khatmCompletedAyahs)/\(khatmTotalAyahs) ayahs")
                        .font(.caption2.weight(isKhatmComplete ? .semibold : .regular))
                }
                .foregroundStyle(
                    isKhatmComplete ? accentColor.color :
                    isKhatmPartiallyComplete ? accentColor.color.opacity(0.72) :
                    .secondary
                )

                // Per-surah progress bar (shown in both Surah and Juz khatm grouping).
                ProgressView(
                    value: Double(min(max(khatmCompletedAyahs, 0), khatmTotalAyahs)),
                    total: Double(max(khatmTotalAyahs, 1))
                )
                .progressViewStyle(.linear)
                .tint(accentColor.color)
            }
            // Fill the content column so the bar uses its full width (leading-aligned).
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var surahNumberPill: some View {
        Text("\(surah.id)")
            .font(.caption.weight(.bold))
            .foregroundColor(accentColor.color)
            .frame(width: badgeWidth)
            .frame(maxHeight: .infinity)
            .conditionalGlassEffect(
                useColor: favoriteState ? 0.3 : nil,
                customTint: favoriteState ? accentColor.color : nil
            )
            .onTapGesture {
                settings.hapticFeedback()
                settings.toggleSurahFavorite(surah: surah.id)
            }
            .accessibilityLabel("Surah \(surah.id)\(isLastRead ? ", last read" : isLastListened ? ", last listened" : "")")
            // The favourite star keeps the RIGHT corner - that is where favouriting a surah has always
            // shown up. Reading position moves to the LEFT (user rule), so the two stop competing for one
            // corner: a favourited surah that is also where you left off now shows both badges, where the
            // star used to hide the book outright.
            .overlay(alignment: .topTrailing) {
                if favoriteState {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(settings.accentColor.color)
                        .padding(4)
                        .offset(x: 8, y: -6)
                }
            }
            .overlay(alignment: .topLeading) {
                if isLastRead {
                    Image(systemName: "book.fill")
                        .font(.caption2)
                        .foregroundStyle(settings.accentColor.color)
                        .padding(4)
                        .offset(x: -6, y: -6)
                } else if isLastListened {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.caption2)
                        .foregroundStyle(settings.accentColor.color)
                        .padding(4)
                        .offset(x: -6, y: -6)
                }
            }
            .padding(.vertical, {
                if #available(iOS 26, *) { 0 } else { 8 }
            }())
    }
    
    var body: some View {
        #if os(iOS)
        if grid { gridBody } else { listBody }
        #else
        VStack {
            HStack {
                Text("\(surah.id) - \(surah.nameTransliteration)")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(Settings.shared.cleanedQuranArabic(surah.nameArabic)) - \(surah.idArabic)")
                    .font(.headline)
                    .foregroundColor(settings.accentColor.color)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .minimumScaleFactor(0.9)
            }

            Text("\(revelationEmoji) • \(surah.numberOfAyahs) Ayahs • \(pageLine)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .contentShape(Rectangle())
        #endif
    }

    #if os(iOS)
    // The normal surah row. Used in both the list and (wrapped as a card) the grid, so favorites look
    // identical to normal surahs in either layout.
    private var listBody: some View {
        HStack(alignment: .center) {
            surahNumberPill
                .padding(.trailing, 2)

            // Khatm progress lives INSIDE this content column so the column (and therefore the full-height
            // number pill beside it, plus the vertically-centered Arabic name) grows to include it - rather
            // than hanging below the row where the pill wouldn't reach it.
            VStack(alignment: .leading, spacing: 2) {
                if let context = positionContextLine {
                    Text(context)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // `lineLimit: 1` INSIDE both snippets: HighlightedSnippet applies its own `.lineLimit`
                // to the inner Text, so the outer clamps here were silently overridden and long names
                // ("The Enshrouded One" + the revelation emoji) wrapped to a second line.
                HighlightedSnippet(
                    source: surah.nameTransliteration,
                    term: searchQuery,
                    font: .subheadline.weight(.semibold),
                    accent: accentColor.color,
                    fg: .primary,
                    lineLimit: 1
                )

                HighlightedSnippet(
                    source: surah.nameEnglish,
                    term: searchQuery,
                    font: .caption,
                    accent: accentColor.color,
                    fg: showInfo ? .primary : .secondary,
                    trailingSuffix: showInfo ? "" : " \(revelationEmoji)",
                    lineLimit: 1
                )

                if showInfo {
                    Text(pageLine)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(ayahAndRevelationLine)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let sortedMetricLine,
                       settings.quranSortMode == .words || settings.quranSortMode == .letters {
                        Text(sortedMetricLine)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else if let sortedMetricLine {
                    Text(sortedMetricLine)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                khatmProgressLine
            }
            .lineLimit(1)
            .layoutPriority(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                HighlightedSnippet(
                    source: Settings.shared.cleanedQuranArabic(surah.nameArabic),
                    term: searchQuery,
                    font: Font.arabic(fontArabic, size: UIFont.preferredFont(forTextStyle: .title3).pointSize),
                    accent: accentColor.color,
                    fg: .primary,
                    // HighlightedSnippet applies its own `.lineLimit` to the inner Text, which would otherwise
                    // override the row's outer `.lineLimit(1)` (the closest modifier wins) and let long Arabic
                    // names like آل عمران wrap to two lines.
                    lineLimit: 1
                )
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)

                Text(surah.idArabic)
                    .font(.custom(Settings.hafsUthmaniFontName, size: UIFont.preferredFont(forTextStyle: .title1).pointSize))
                    .arabicFontDesign(custom: true)
                    .foregroundColor(accentColor.color)
            }
            .minimumScaleFactor(0.5)
            .padding(.leading, 8)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .contentShape(Rectangle())
    }

    /// Custom grid tile: the same information as the list row, re-laid out vertically so it reads
    /// well in a narrow 2-column grid cell.
    private var gridBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Arabic id ornament + name on the top row. The favorite star is the tappable corner overlay
            // (`.gridFavoriteStar`) applied by the enclosing grid tile - NOT a second inline star here, which
            // is what produced the double star on a favorited surah. The trailing Spacer leaves the corner
            // clear for that overlay. The id now prefixes the transliteration below (e.g. "1: Al-Fatihah").
            HStack(spacing: 4) {
                Text(surah.idArabic)
                    .font(.custom(Settings.hafsUthmaniFontName, size: UIFont.preferredFont(forTextStyle: .title3).pointSize))
                    .arabicFontDesign(custom: true)
                    .foregroundColor(accentColor.color)

                HighlightedSnippet(
                    source: Settings.shared.cleanedQuranArabic(surah.nameArabic),
                    term: searchQuery,
                    font: Font.arabic(fontArabic, size: UIFont.preferredFont(forTextStyle: .title3).pointSize),
                    accent: accentColor.color,
                    fg: .primary,
                    lineLimit: 1
                )
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)

                // Leaves room at the trailing edge for the corner star overlay.
                Spacer(minLength: 20)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            if let context = positionContextLine {
                Text(context)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Text("\(surah.id):")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundColor(accentColor.color)
                    .layoutPriority(1)

                // Inner `lineLimit: 1`, same as the list row - the outer clamp was overridden.
                HighlightedSnippet(
                    source: surah.nameTransliteration,
                    term: searchQuery,
                    font: .subheadline.weight(.semibold),
                    accent: accentColor.color,
                    fg: .primary,
                    lineLimit: 1
                )
            }
            .minimumScaleFactor(0.6)

            HighlightedSnippet(
                source: surah.nameEnglish,
                term: searchQuery,
                font: .caption,
                accent: accentColor.color,
                fg: showInfo ? .primary : .secondary,
                trailingSuffix: showInfo ? "" : " \(revelationEmoji)",
                lineLimit: 1
            )
            .minimumScaleFactor(0.6)

            if showInfo {
                Text(pageLine)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(ayahAndRevelationLine)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let sortedMetricLine,
                   settings.quranSortMode == .words || settings.quranSortMode == .letters {
                    Text(sortedMetricLine)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            } else if let sortedMetricLine {
                Text(sortedMetricLine)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            khatmProgressLine

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        // Favorites are tinted, everything else is clear - see the 99 Names grid for the same reasoning.
        .conditionalGlassEffect(
            clear: !favoriteState,
            rectangle: true,
            useColor: favoriteState ? 0.25 : nil,
            customTint: favoriteState ? accentColor.color : nil
        )
        .contentShape(Rectangle())
    }
    #endif

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.surah == rhs.surah &&
        lhs.ayah == rhs.ayah &&
        lhs.end == rhs.end &&
        lhs.favoriteState == rhs.favoriteState &&
        lhs.showInfo == rhs.showInfo &&
        lhs.accentColor == rhs.accentColor &&
        lhs.useFontArabic == rhs.useFontArabic &&
        lhs.fontArabic == rhs.fontArabic &&
        lhs.khatmCompletedAyahs == rhs.khatmCompletedAyahs &&
        lhs.khatmTotalAyahs == rhs.khatmTotalAyahs &&
        lhs.searchQuery == rhs.searchQuery &&
        lhs.grid == rhs.grid &&
        lhs.sortModeKey == rhs.sortModeKey &&
        lhs.displayQiraahKey == rhs.displayQiraahKey &&
        lhs.isLastRead == rhs.isLastRead &&
        lhs.isLastListened == rhs.isLastListened
    }
}

struct SurahAyahRow: View, Equatable {
    @ObservedObject var settings = Settings.shared
    @State private var confirmRemoveNote = false

    var surah: Surah
    var ayah: Ayah
    var note: String? = nil
    var disableTajweedColors: Bool = false
    /// When true, renders the same single-line row content wrapped as a grid card (grid == list look).
    var grid: Bool = false
    /// Multiplier on the Arabic line's font size (default matches the normal row). Pass a smaller value
    /// for compact contexts such as the page/juz starting-ayah lists.
    var arabicScale: CGFloat = 1.1
    /// Folds every settings field the body reads (fonts, tajweed, translation toggles) so `==` stays correct
    /// when the user changes appearance - see `Settings.ayahRenderSettingsSignature`. Captured at
    /// construction, so the parent re-rendering on a settings change delivers a fresh signature.
    var renderSettingsSignature: String = Settings.shared.ayahRenderSettingsSignature

    /// This row builds tajweed AttributedStrings and beginner-mode spaced Arabic in its body, and it sits
    /// in lists (last read, bookmarks, histories) whose parents re-render on every playback tick. The
    /// bookmark state is deliberately NOT compared: it lives in observed `Settings`, whose publish
    /// invalidates this row directly - bypassing `==` - so a toggle always redraws.
    static func == (l: Self, r: Self) -> Bool {
        l.surah.id == r.surah.id && l.ayah.id == r.ayah.id &&
        l.note == r.note &&
        l.disableTajweedColors == r.disableTajweedColors &&
        l.grid == r.grid &&
        l.arabicScale == r.arabicScale &&
        l.renderSettingsSignature == r.renderSettingsSignature
    }

    private var isBookmarked: Bool {
        // Through the indexed accessor, not a scan of the list: this row renders in the bookmarks list,
        // the histories, and the search results, all of which mount many of it at once.
        settings.isBookmarked(surah: surah.id, ayah: ayah.id)
    }

    /// A highlighted ayah's bookmark carries the highlight's color into every list that shows it - the
    /// bookmarks list, the histories, the search results - so the color is a property of the SAVED ayah
    /// rather than something that only exists on the page you highlighted it on.
    private var bookmarkTint: Color {
        settings.bookmarkHighlight(surah: surah.id, ayah: ayah.id)?.color ?? settings.accentColor.color
    }

    private func toggleBookmarkWithNoteGuard() {
        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah.id, ayah: ayah.id) {
            confirmRemoveNote = true
        }
    }

    private func arabicDisplayText() -> String {
        let clean = settings.cleanArabicText
        let text = ayah.displayArabicText(surahId: surah.id, clean: clean)
        return settings.beginnerMode ? text.beginnerSpaced : text
    }

    private var shouldShowTajweedColors: Bool {
        if disableTajweedColors { return false }
        return settings.showTajweedColors
            && settings.showArabicText
            && settings.isHafsDisplay
    }

    private func arabicTajweedText() -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        let text = ayah.displayArabicText(surahId: surah.id, clean: false)
        let displayText = settings.cleanArabicText ? ayah.displayArabicText(surahId: surah.id, clean: true) : text
        let renderedDisplayText = settings.beginnerMode ? displayText.beginnerSpaced : displayText
        return TajweedStore.shared.attributedText(
            surah: surah.id,
            ayah: ayah.id,
            text: text,
            displayText: renderedDisplayText,
            cleanDisplayText: settings.cleanArabicText,
            beginnerSpacing: settings.beginnerMode
        )
    }

    private var tajweedAnimationKey: String {
        let categorySignature = TajweedLegendCategory.allCases
            .map { settings.isTajweedCategoryVisible($0) ? "1" : "0" }
            .joined()
        return [
            settings.showTajweedColors ? "1" : "0",
            settings.cleanArabicText ? "1" : "0",
            settings.beginnerMode ? "1" : "0",
            settings.displayQiraah,
            categorySignature
        ].joined(separator: "|")
    }
    
    private var badgeWidth: CGFloat {
        BadgeWidthCache.width(template: "10:100")
    }

    private var listBody: some View {
        HStack {
            VStack {
                ZStack(alignment: .topTrailing) {
                    Text("\(surah.id):\(ayah.id)")
                        .font(.headline)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        #if os(iOS)
                        .frame(width: badgeWidth, alignment: .center)
                        .padding(4)
                        #else
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        #endif
                        .conditionalGlassEffect(
                            useColor: isBookmarked ? 0.3 : nil,
                            customTint: isBookmarked ? bookmarkTint : nil,
                            interactive: false
                        )
                        .onTapGesture {
                            settings.hapticFeedback()
                            toggleBookmarkWithNoteGuard()
                        }

                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(bookmarkTint)
                            .padding(4)
                            .offset(x: 8, y: -6)
                    }
                }

                Text(surah.nameTransliteration)
                    #if os(iOS)
                    .font(.caption)
                    #else
                    .font(.caption2)
                    #endif
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            #if os(iOS)
            .frame(width: 65, alignment: .center)
            #else
            .frame(width: 50, alignment: .center)
            #endif
            .foregroundColor(settings.accentColor.color)
            .padding(.trailing, 8)

            ayahContent
        }
        .padding(.vertical, 2)
    }

    /// The ayah text (note, or Arabic + transliteration + English, single line each) shared by the
    /// list row and the grid tile so they show identical information.
    @ViewBuilder
    private var ayahContent: some View {
        if let note = note {
            Text(note)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
        } else {
            VStack {
                if settings.showArabicText {
                    HighlightedSnippet(
                        source: arabicDisplayText(),
                        term: "",
                        font: Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * arabicScale),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        preStyledSource: arabicTajweedText(),
                        beginnerMode: settings.beginnerMode,
                        lineLimit: 1
                    )
                        .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                if settings.showTransliteration, settings.isHafsDisplay {
                    Text(ayah.textTransliteration)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                }

                if settings.showEnglishSaheeh, settings.isHafsDisplay {
                    Text(ayah.textEnglishSaheeh)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                } else if settings.showEnglishMustafa, settings.isHafsDisplay {
                    Text(ayah.textEnglishMustafa)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                }
            }
            .foregroundColor(.primary)
        }
    }

    #if os(iOS)
    /// Custom grid tile: the same ayah information as the list row, laid out vertically for a 2-column cell.
    /// Styled to match a favorited `SurahRow` grid tile - accent-tinted conditional glass when bookmarked -
    /// with a tappable bookmark in the corner (the counterpart of SurahRow's corner favorite star).
    private var gridBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("\(surah.nameTransliteration) \(surah.id):\(ayah.id)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                // Leaves the corner clear for the tappable bookmark overlay below.
                Spacer(minLength: 20)
            }

            ayahContent

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        // Always CLEAR glass, even when bookmarked - the accent-filled bookmark icon in the corner carries
        // the state; a tinted card here read as too loud next to the surah grid.
        .conditionalGlassEffect(clear: true, rectangle: true)
        .overlay(alignment: .topTrailing) {
            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isBookmarked ? bookmarkTint : .secondary)
                // Same fix as `gridFavoriteStar`: the target is a 30pt square centered on the GLYPH.
                // The old shape came after the corner paddings and inflated by 10 more, hit-testing a
                // ~40pt+ zone that swallowed the tile's right side (taps opened the bookmark, not the ayah).
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { toggleBookmarkWithNoteGuard() }
                }
                .padding(.top, 1)
                .padding(.trailing, 2)
                .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
        }
        .contentShape(Rectangle())
    }
    #endif

    var body: some View {
        Group {
            #if os(iOS)
            if grid { gridBody } else { listBody }
            #else
            listBody
            #endif
        }
        .contentShape(Rectangle())
        .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.toggleBookmark(surah: surah.id, ayah: ayah.id)
                }
            }
            Button("Cancel") {}
        } message: {
            Text(Settings.bookmarkNoteRemovalDialogMessage)
        }
    }
}

/// Just the Arabic text of an ayah, rendered through the same pipeline as the reading view - same font,
/// tajweed colors, beginner-mode spacing, and Allah highlighting - sized by `scale`. Used for compact
/// previews such as the page/juz dividers in SurahView.
struct AyahArabicSnippet: View, Equatable {
    @ObservedObject var settings = Settings.shared

    let surah: Surah
    let ayah: Ayah
    var scale: CGFloat = 0.8
    var lineLimit: Int? = 1
    /// Same idiom as `SurahAyahRow`: every settings field the body reads, folded into one compared input
    /// captured at construction, so appearance changes fail `==` while unchanged data skips the
    /// tajweed-AttributedString rebuild. Matters in `SurahView`'s page/juz dividers, which re-render with
    /// the reader on every playback tick.
    var renderSettingsSignature: String = Settings.shared.ayahRenderSettingsSignature

    static func == (l: Self, r: Self) -> Bool {
        l.surah.id == r.surah.id && l.ayah.id == r.ayah.id &&
        l.scale == r.scale &&
        l.lineLimit == r.lineLimit &&
        l.renderSettingsSignature == r.renderSettingsSignature
    }

    private var shouldShowTajweedColors: Bool {
        settings.showTajweedColors && settings.showArabicText && settings.isHafsDisplay
    }

    private func arabicDisplayText() -> String {
        let text = ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText)
        return settings.beginnerMode ? text.beginnerSpaced : text
    }

    private func arabicTajweedText() -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        let text = ayah.displayArabicText(surahId: surah.id, clean: false)
        let displayText = settings.cleanArabicText ? ayah.displayArabicText(surahId: surah.id, clean: true) : text
        let renderedDisplayText = settings.beginnerMode ? displayText.beginnerSpaced : displayText
        return TajweedStore.shared.attributedText(
            surah: surah.id,
            ayah: ayah.id,
            text: text,
            displayText: renderedDisplayText,
            cleanDisplayText: settings.cleanArabicText,
            beginnerSpacing: settings.beginnerMode
        )
    }

    var body: some View {
        if settings.showArabicText {
            HighlightedSnippet(
                source: arabicDisplayText(),
                term: "",
                font: Font.arabic(settings.quranDisplayFontName, size: settings.fontArabicSize * scale),
                accent: settings.accentColor.color,
                fg: .primary,
                preStyledSource: arabicTajweedText(),
                beginnerMode: settings.beginnerMode,
                lineLimit: lineLimit,
                highlightAllahNames: settings.highlightAllahNames
            )
            .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct AyahSearchResultRow: View {
    @ObservedObject private var settings = Settings.shared

    let surah: Surah
    let ayah: Ayah

    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    var disableTajweedColors: Bool = false
    /// When true, the Arabic line is rendered smaller (used by the page/juz starting-ayah lists).
    var compactArabic: Bool = false
    var onSelectAyah: ((Int, Int) -> Void)? = nil

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah.id)-\(ayah.id)")
    }

    private var pageJuzLine: String? {
        if let page = ayah.page, let juz = ayah.juz {
            return "Page \(page) • Juz \(juz)"
        }
        if let page = ayah.page {
            return "Page \(page)"
        }
        if let juz = ayah.juz {
            return "Juz \(juz)"
        }
        return nil
    }

    var body: some View {
        let row = VStack(alignment: .leading, spacing: 4) {
            SurahAyahRow(surah: surah, ayah: ayah, disableTajweedColors: disableTajweedColors, arabicScale: compactArabic ? 0.8 : 1.1)
                .equatable()

            if settings.showFullSurahRow, let pageJuzLine {
                Label(pageJuzLine, systemImage: "map")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }

        Group {
            if let onSelectAyah {
                Button {
                    settings.hapticFeedback()
                    onSelectAyah(surah.id, ayah.id)
                } label: {
                    row
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            } else {
                NavigationLink(destination: SurahView(surah: surah, ayah: ayah.id)) {
                    row
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .contentShape(Rectangle())
            }
        }
        .rightSwipeActions(
            surahID: surah.id,
            surahName: surah.nameTransliteration,
            ayahID: ayah.id,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
        .leftSwipeActions(
            surah: surah.id,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            bookmarkedSurah: surah.id,
            bookmarkedAyah: ayah.id,
        )
        .ayahContextMenuModifier(
            surah: surah.id,
            ayah: ayah.id,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
    }
}

struct AyahSearchRow: View, Equatable {
    @ObservedObject private var settings = Settings.shared
    @State private var confirmRemoveNote = false

    
    let surahName: String
    let surah: Int
    let ayah:  Int
    let query: String
    
    let arabic: String
    let transliteration: String
    let englishSaheeh: String
    let englishMustafa: String
    let page: Int?
    let juz: Int?
    
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    var qiraahRefreshKey: String = ""

    /// When true (Quran search grouped by surah): `surah:ayah` label + same Arabic / transliteration / English visibility rules as the full row, without the top surah name line.
    var compact: Bool = false
    var disableTajweedColors: Bool = false
    /// Folds every settings field the body reads (fonts, tajweed, translation toggles) so `==` stays correct
    /// when the user changes appearance - see `Settings.ayahRenderSettingsSignature`.
    var renderSettingsSignature: String = Settings.shared.ayahRenderSettingsSignature

    private final class NormalizedSources {
        let arabic: String
        let transliteration: String
        let saheeh: String
        let mustafa: String

        init(arabic: String, transliteration: String, saheeh: String, mustafa: String) {
            self.arabic = arabic
            self.transliteration = transliteration
            self.saheeh = saheeh
            self.mustafa = mustafa
        }
    }

    private struct SearchVisibility {
        let mArabic: Bool
        let mTr: Bool
        let mSaheeh: Bool
        let mMustafa: Bool
        let showArabicLine: Bool
        let showTrLine: Bool
        let showSaheehLine: Bool
        let showMustafaLine: Bool
        /// When the verse-search index returned this ayah but none of the fields matched under THIS row's
        /// normalization, force the Arabic line to show and guarantee at least one highlighted span - a
        /// search result must never appear with nothing highlighted.
        let forceArabicHighlight: Bool
    }

    private static let normalizedSourcesCache: NSCache<NSString, NormalizedSources> = {
        let cache = NSCache<NSString, NormalizedSources>()
        cache.countLimit = 5000
        return cache
    }()
    
    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah)-\(ayah)")
    }

    /// Same rule as `SurahAyahRow.bookmarkTint`: highlighted ayahs carry their color into the search and
    /// history rows too, so one saved ayah looks the same wherever it surfaces.
    private var bookmarkTint: Color {
        settings.bookmarkHighlight(surah: surah, ayah: ayah)?.color ?? settings.accentColor.color
    }

    private var badgeWidth: CGFloat {
        BadgeWidthCache.width(template: "10:100")
    }

    private var pageJuzLine: String? {
        if let page, let juz {
            return "Page \(page) • Juz \(juz)"
        }
        if let page {
            return "Page \(page)"
        }
        if let juz {
            return "Juz \(juz)"
        }
        return nil
    }

    @ViewBuilder
    private var pageJuzMetadata: some View {
        if settings.showFullSurahRow, let pageJuzLine {
            Label(pageJuzLine, systemImage: "map")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private func toggleBookmarkWithNoteGuard() {
        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah, ayah: ayah) {
            confirmRemoveNote = true
        }
    }

    @ViewBuilder
    private var ayahReferenceBadge: some View {
        ZStack(alignment: .topTrailing) {
            Text("\(surah):\(ayah)")
                .font(.caption.weight(.semibold))
                .foregroundColor(settings.accentColor.color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(width: badgeWidth, alignment: .center)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .conditionalGlassEffect(
                    useColor: isBookmarked ? 0.3 : nil,
                    customTint: isBookmarked ? bookmarkTint : nil
                )
                .onTapGesture {
                    settings.hapticFeedback()
                    toggleBookmarkWithNoteGuard()
                }

            if isBookmarked {
                Image(systemName: "bookmark.fill")
                    .font(.caption2)
                    .foregroundStyle(bookmarkTint)
                    .padding(4)
                    .offset(x: 8, y: -6)
            }
        }
    }

    private var shouldShowTajweedColors: Bool {
        if disableTajweedColors { return false }
        return settings.showTajweedColors
            && settings.showArabicText
            && settings.isHafsDisplay
    }

    private var searchArabicFontName: String {
        settings.quranArabicFontName(for: settings.displayQiraahForArabic)
    }

    private func arabicDisplayText() -> String {
        settings.beginnerMode ? arabic.beginnerSpaced : arabic
    }

    private func arabicTajweedText() -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        return TajweedStore.shared.attributedText(
            surah: surah,
            ayah: ayah,
            text: arabic,
            displayText: arabicDisplayText(),
            cleanDisplayText: settings.cleanArabicText,
            beginnerSpacing: settings.beginnerMode
        )
    }

    private var tajweedAnimationKey: String {
        let categorySignature = TajweedLegendCategory.allCases
            .map { settings.isTajweedCategoryVisible($0) ? "1" : "0" }
            .joined()
        return [
            settings.showTajweedColors ? "1" : "0",
            settings.cleanArabicText ? "1" : "0",
            settings.beginnerMode ? "1" : "0",
            settings.displayQiraah,
            categorySignature,
            query
        ].joined(separator: "|")
    }

    private func normalizedSources() -> NormalizedSources {
        let key = "\(surah):\(ayah)|\(qiraahRefreshKey)|\(arabic.hashValue)|\(transliteration.hashValue)|\(englishSaheeh.hashValue)|\(englishMustafa.hashValue)" as NSString
        if let cached = Self.normalizedSourcesCache.object(forKey: key) {
            return cached
        }

        let sources = NormalizedSources(
            arabic: settings.cleanSearch(arabic, whitespace: false).removingArabicDiacriticsAndSigns,
            transliteration: settings.cleanSearch(transliteration, whitespace: false).removingArabicDiacriticsAndSigns,
            saheeh: settings.cleanSearch(englishSaheeh, whitespace: false).removingArabicDiacriticsAndSigns,
            mustafa: settings.cleanSearch(englishMustafa, whitespace: false).removingArabicDiacriticsAndSigns
        )
        Self.normalizedSourcesCache.setObject(sources, forKey: key)
        return sources
    }

    /// A source "matches" the query when it contains the whole phrase contiguously OR matches it loosely as
    /// a phrase-prefix (consecutive words, last is a prefix) - the same close-match rule the verse search
    /// uses. Gating highlights on the strict `contains` alone meant close matches showed the row but never
    /// highlighted; this keeps the two in sync so the matched words always color.
    private func sourceMatchesQuery(_ source: String, normalizedQuery: String) -> Bool {
        guard !normalizedQuery.isEmpty else { return false }
        if source.contains(normalizedQuery) { return true }

        let queryTokens = normalizedQuery.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        guard queryTokens.count >= 1 else { return false }
        let sourceTokens = source.split(separator: " ").map(String.init)
        guard sourceTokens.count >= queryTokens.count else { return false }

        for start in 0...(sourceTokens.count - queryTokens.count) {
            var matched = true
            for offset in queryTokens.indices {
                let word = sourceTokens[start + offset]
                let token = queryTokens[offset]
                if offset == queryTokens.count - 1 {
                    if !word.hasPrefix(token) { matched = false; break }
                } else if word != token {
                    matched = false
                    break
                }
            }
            if matched { return true }
        }
        return false
    }

    private func searchVisibility() -> SearchVisibility {
        let normalizedQuery = settings.cleanSearch(query.removingAyahSearchOperators, whitespace: true).removingArabicDiacriticsAndSigns
        let sources = normalizedSources()

        let mArabic = sourceMatchesQuery(sources.arabic, normalizedQuery: normalizedQuery)
        let mTr = sourceMatchesQuery(sources.transliteration, normalizedQuery: normalizedQuery)
        let mSaheeh = sourceMatchesQuery(sources.saheeh, normalizedQuery: normalizedQuery)
        let mMustafa = sourceMatchesQuery(sources.mustafa, normalizedQuery: normalizedQuery)
        // The index that produced this result normalizes/stems differently than sourceMatchesQuery, so a
        // returned ayah can have no field match here. In that case force the Arabic line + a guaranteed span.
        let forceArabicHighlight = !normalizedQuery.isEmpty && !(mArabic || mTr || mSaheeh || mMustafa)
        let showArabicLine = settings.showArabicText || mArabic || forceArabicHighlight
        let showTrLine = settings.isHafsDisplay && (settings.showTransliteration || mTr)

        let showEnglishLines: (saheeh: Bool, mustafa: Bool) = {
            guard settings.isHafsDisplay else { return (false, false) }
            let userSaheehOn = settings.showEnglishSaheeh
            let userMustafaOn = settings.showEnglishMustafa
            if mSaheeh && mMustafa { return (true, true) }
            if mSaheeh || mMustafa { return (mSaheeh, mMustafa) }
            if userSaheehOn && !userMustafaOn { return (true, false) }
            if userMustafaOn && !userSaheehOn { return (false, true) }
            if userSaheehOn && userMustafaOn { return (true, false) }
            return (false, false)
        }()

        return SearchVisibility(
            mArabic: mArabic,
            mTr: mTr,
            mSaheeh: mSaheeh,
            mMustafa: mMustafa,
            showArabicLine: showArabicLine,
            showTrLine: showTrLine,
            showSaheehLine: showEnglishLines.saheeh,
            showMustafaLine: showEnglishLines.mustafa,
            forceArabicHighlight: forceArabicHighlight
        )
    }

    /// Cross-language word highlight (iOS, Hafs, non-beginner): an Arabic query also lights the
    /// aligned English words in the translation lines, and an English query also lights the Arabic
    /// tokens whose gloss carries it - so a hit like ضاقت shows WHERE it sits in the translation.
    /// Routed through the word-by-word gloss pack, whose per-ayah alignment is exact.
    ///
    /// Deliberately NOT gated on `visibility` (which only reports LITERAL field matches): the AI
    /// (semantic) results and the string results are the same rows, and a semantic hit is exactly
    /// the case where "where is this in the ayah?" matters most. The alignment itself decides -
    /// when the query's words aren't in this ayah, both directions return no spans anyway. Where
    /// the pack's alignment contract doesn't hold (other riwayat, beginner spacing) this returns
    /// empty and the row renders exactly as before.
    ///
    /// The per-ayah pass finds nothing for a query whose wording isn't literally in this ayah (a
    /// semantic hit, a different inflection), so both directions fall back to the corpus-wide
    /// Quran lexicon - the same path the hadith rows use.
    private func crossLanguageSpans() -> (arabic: [NSRange], saheeh: [NSRange], mustafa: [NSRange]) {
        #if os(iOS)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              settings.isHafsDisplay,
              !settings.beginnerMode,
              WordByWordStore.isBundled else { return ([], [], []) }

        let displayText = arabicDisplayText()
        // The gloss pack's token order is defined against the RAW (unstripped) text; with "Hide
        // Tashkeel and Signs" off the display text IS raw, so the lookup is skipped.
        let rawText = settings.cleanArabicText
            ? (QuranData.shared.ayah(surah: surah, ayah: ayah)?.displayArabicText(surahId: surah, clean: false) ?? displayText)
            : arabic

        if trimmed.containsArabicLetters {
            // Per-ayah exact terms UNIONED with the corpus lexicon's - not a fallback. The aligned gloss
            // is one wording of the word ("straitened"); the lexicon carries the word family's gloss
            // variants from every occurrence, which is what bridges to a translation that phrased it
            // differently ("confining"). The union is what "maximize" buys here.
            var terms = CrossLanguageWordHighlight.englishTermsForArabicMatch(
                query: trimmed, surah: surah, ayah: ayah, rawText: rawText, displayText: displayText
            )
            for term in CrossLanguageWordHighlight.englishTermsForUnalignedArabicQuery(trimmed)
            where !terms.contains(term) {
                terms.append(term)
            }
            // The morphological Arabic spans are ADDITIVE: tokens of the same word family the plain
            // highlighter misses (صلاتهم for a صلاة query) light up in the Arabic line too.
            let arabicExtra = CrossLanguageWordHighlight.arabicSpansForArabicQuery(
                query: trimmed, in: displayText
            )
            guard !terms.isEmpty || !arabicExtra.isEmpty else { return ([], [], []) }
            return (arabicExtra,
                    CrossLanguageWordHighlight.wordSpans(of: terms, in: englishSaheeh),
                    CrossLanguageWordHighlight.wordSpans(of: terms, in: englishMustafa))
        } else {
            // Union here too: the per-ayah alignment and the corpus lexicon each catch tokens the
            // other misses (an inflected form the exact gloss missed; a gloss wording the lexicon
            // dropped under its noise cap).
            var spans = CrossLanguageWordHighlight.arabicSpansForEnglishMatch(
                query: trimmed, surah: surah, ayah: ayah, rawText: rawText, displayText: displayText
            )
            for span in CrossLanguageWordHighlight.arabicSpansForEnglishQuery(trimmed, arabicText: displayText)
            where !spans.contains(where: { NSIntersectionRange($0, span).length > 0 }) {
                spans.append(span)
            }
            return (spans, [], [])
        }
        #else
        return ([], [], [])
        #endif
    }

    @ViewBuilder
    private func buildCompactSearchRow() -> some View {
        let visibility = searchVisibility()
        let cross = crossLanguageSpans()

        VStack(alignment: .leading, spacing: 8) {
            // The HadithRow header grammar: the reference pill leading, the ellipsis actions button
            // trailing. The button itself is OVERLAID by `ayahContextMenuModifier(inlineEllipsis:)`
            // (which owns the menu items and every sheet they present) - this row just reserves its
            // 22pt slot so the header lays out around it.
            HStack(spacing: 8) {
                ayahReferenceBadge

                Spacer(minLength: 0)

                Color.clear
                    .frame(width: 22, height: 22)
            }

            if visibility.showArabicLine || !cross.arabic.isEmpty {
                HighlightedSnippet(
                    source: arabicDisplayText(),
                    term: (visibility.mArabic || visibility.forceArabicHighlight) ? query : "",
                    font: .custom(searchArabicFontName, size: UIFont.preferredFont(forTextStyle: .body).pointSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: arabicTajweedText(),
                    beginnerMode: settings.beginnerMode,
                    lineLimit: nil,
                    guaranteeMatch: visibility.forceArabicHighlight,
                    extraHighlightRanges: cross.arabic
                )
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
            }

            if visibility.showTrLine {
                HighlightedSnippet(
                    source: transliteration,
                    term: visibility.mTr ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            // Cross-language spans FORCE the translation line visible: an Arabic hit whose aligned
            // English words were found must show them even when the user's translation toggle is off.
            if visibility.showSaheehLine || !cross.saheeh.isEmpty {
                HighlightedSnippet(
                    source: englishSaheeh,
                    term: visibility.mSaheeh ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary,
                    extraHighlightRanges: cross.saheeh
                )
            }

            if visibility.showMustafaLine || (!cross.mustafa.isEmpty && !visibility.showSaheehLine && cross.saheeh.isEmpty) {
                HighlightedSnippet(
                    source: englishMustafa,
                    term: visibility.mMustafa ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary,
                    extraHighlightRanges: cross.mustafa
                )
            }

            pageJuzMetadata
        }
        .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                settings.hapticFeedback()
                withAnimation(.easeInOut) {
                    settings.toggleBookmark(surah: surah, ayah: ayah)
                }
            }
            Button("Cancel") {}
        } message: {
            Text(Settings.bookmarkNoteRemovalDialogMessage)
        }
    }

    @ViewBuilder
    private func buildFullSearchRow() -> some View {
        let visibility = searchVisibility()
        let cross = crossLanguageSpans()

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ayahReferenceBadge

                Text(surahName)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .font(.caption)
            .foregroundColor(settings.accentColor.color)
            .transition(.opacity)

            if visibility.showArabicLine || !cross.arabic.isEmpty {
                HighlightedSnippet(
                    source: arabicDisplayText(),
                    term: (visibility.mArabic || visibility.forceArabicHighlight) ? query : "",
                    font: .custom(searchArabicFontName, size: UIFont.preferredFont(forTextStyle: .body).pointSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: arabicTajweedText(),
                    beginnerMode: settings.beginnerMode,
                    lineLimit: nil,
                    guaranteeMatch: visibility.forceArabicHighlight,
                    extraHighlightRanges: cross.arabic
                )
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
            }

            if visibility.showTrLine {
                HighlightedSnippet(
                    source: transliteration,
                    term: visibility.mTr ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            // Cross-language spans FORCE the translation line visible - see buildCompactSearchRow.
            if visibility.showSaheehLine || !cross.saheeh.isEmpty {
                HighlightedSnippet(
                    source: englishSaheeh,
                    term: visibility.mSaheeh ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary,
                    extraHighlightRanges: cross.saheeh
                )
            }

            if visibility.showMustafaLine || (!cross.mustafa.isEmpty && !visibility.showSaheehLine && cross.saheeh.isEmpty) {
                HighlightedSnippet(
                    source: englishMustafa,
                    term: visibility.mMustafa ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary,
                    extraHighlightRanges: cross.mustafa
                )
            }

            pageJuzMetadata
        }
    }

    var body: some View {
        Group {
            if compact {
                buildCompactSearchRow()
            } else {
                buildFullSearchRow()
            }
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .rightSwipeActions(
            surahID: surah,
            surahName: surahName,
            ayahID: ayah,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
        .leftSwipeActions(
            surah: surah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            bookmarkedSurah: surah,
            bookmarkedAyah: ayah
        )
        .ayahContextMenuModifier(
            surah: surah,
            ayah: ayah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID,
            // Compact rows carry the HadithRow-style header, whose trailing slot this fills.
            inlineEllipsis: compact
        )
    }

    static func == (l: Self, r: Self) -> Bool {
        l.surah == r.surah && l.ayah == r.ayah &&
        l.query == r.query &&
        l.qiraahRefreshKey == r.qiraahRefreshKey &&
        l.compact == r.compact &&
        l.disableTajweedColors == r.disableTajweedColors &&
        l.page == r.page &&
        l.juz == r.juz &&
        l.favoriteSurahs == r.favoriteSurahs &&
        l.bookmarkedAyahs == r.bookmarkedAyahs &&
        l.renderSettingsSignature == r.renderSettingsSignature
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        List {
            SurahRow(
                surah: AlIslamPreviewData.surah,
            )
            
            SurahAyahRow(
                surah: AlIslamPreviewData.surah,
                ayah: AlIslamPreviewData.ayah
            )
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
    }
}
