import SwiftUI

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
        let font = UIFont.preferredFont(forTextStyle: .headline)
        let text = "100" as NSString
        let size = text.size(withAttributes: [.font: font])
        return size.width + 8
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
        ZStack(alignment: .topTrailing) {
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
                .accessibilityLabel("Surah \(surah.id)")

            if favoriteState {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(settings.accentColor.color)
                    .padding(4)
                    .offset(x: 8, y: -6)
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

                HighlightedSnippet(
                    source: surah.nameTransliteration,
                    term: searchQuery,
                    font: .subheadline.weight(.semibold),
                    accent: accentColor.color,
                    fg: .primary
                )
                .lineLimit(1)

                HighlightedSnippet(
                    source: surah.nameEnglish,
                    term: searchQuery,
                    font: .caption,
                    accent: accentColor.color,
                    fg: showInfo ? .primary : .secondary,
                    trailingSuffix: showInfo ? "" : " \(revelationEmoji)"
                )
                .lineLimit(1)

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

                HighlightedSnippet(
                    source: surah.nameTransliteration,
                    term: searchQuery,
                    font: .subheadline.weight(.semibold),
                    accent: accentColor.color,
                    fg: .primary
                )
                .lineLimit(1)
            }
            .minimumScaleFactor(0.6)

            HighlightedSnippet(
                source: surah.nameEnglish,
                term: searchQuery,
                font: .caption,
                accent: accentColor.color,
                fg: showInfo ? .primary : .secondary,
                trailingSuffix: showInfo ? "" : " \(revelationEmoji)"
            )
            .lineLimit(1)
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
        lhs.displayQiraahKey == rhs.displayQiraahKey
    }
}

struct SurahAyahRow: View {
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

    private var isBookmarked: Bool {
        settings.bookmarkedAyahs.contains { $0.surah == surah.id && $0.ayah == ayah.id }
    }

    private func toggleBookmarkWithNoteGuard() {
        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah.id, ayah: ayah.id) {
            confirmRemoveNote = true
        }
    }

    private func arabicDisplayText() -> String {
        let clean = settings.cleanArabicText
        let text = ayah.displayArabicText(surahId: surah.id, clean: clean)
        return settings.beginnerMode ? text.map { String($0) }.joined(separator: " ") : text
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
        let renderedDisplayText = settings.beginnerMode ? displayText.map { String($0) }.joined(separator: " ") : displayText
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
        let font = UIFont.preferredFont(forTextStyle: .headline)
        let text = "10:100" as NSString
        let size = text.size(withAttributes: [.font: font])
        return size.width + 8
    }
    
    private var listBody: some View {
        HStack {
            VStack {
                ZStack(alignment: .topTrailing) {
                    Text("\(surah.id):\(ayah.id)")
                        .font(.headline)
                        .monospacedDigit()
                        #if os(iOS)
                        .frame(width: badgeWidth, alignment: .center)
                        .padding(4)
                        #else
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        #endif
                        .conditionalGlassEffect(
                            useColor: isBookmarked ? 0.3 : nil,
                            customTint: isBookmarked ? settings.accentColor.color : nil,
                            interactive: false
                        )
                        .onTapGesture {
                            settings.hapticFeedback()
                            toggleBookmarkWithNoteGuard()
                        }

                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(settings.accentColor.color)
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
                .foregroundColor(isBookmarked ? settings.accentColor.color : .secondary)
                .padding(.top, 10)
                .padding(.trailing, 11)
                .contentShape(Rectangle().inset(by: -10))
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { toggleBookmarkWithNoteGuard() }
                }
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

/// A short "when" for a history entry, e.g. "2h ago" / "Yesterday". Shown next to each history item so the
/// expanded list reads as a timeline.
private let historyRelativeFormatter: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .abbreviated
    return f
}()

func formatHistoryTimestamp(_ date: Date) -> String {
    historyRelativeFormatter.localizedString(for: date, relativeTo: Date())
}

/// A small trailing timestamp caption for a history row.
func historyTimestampLabel(_ date: Date) -> some View {
    Text(formatHistoryTimestamp(date))
        .font(.caption2)
        .monospacedDigit()
        .foregroundStyle(.secondary)
}

/// Formats a duration as H:MM:SS once it reaches an hour, otherwise MM:SS.
@inline(__always)
func formatMMSS(_ seconds: Double) -> String {
    let total = max(0, Int(seconds.rounded()))
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%02d:%02d", m, s)
}

#if os(iOS)
struct LastListenedSurahRow: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared

    let lastListenedSurah: LastListenedSurah
    let favoriteSurahs: Set<Int>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    var qiraahRefreshKey: String = ""
    @Binding var showListeningHistory: Bool
    var onSelectSurah: ((Int) -> Void)? = nil

    @State private var confirmDeleteForever = false

    var body: some View {
        guard let surah = quranData.quran.first(where: { $0.id == lastListenedSurah.surahNumber })
        else { return AnyView(EmptyView()) }

        return AnyView(
            Section(header:
                HStack {
                    Text("LAST LISTENED SURAH")

                    Spacer()

                    if !quranPlayer.listeningHistory.isEmpty {
                        Image(systemName: showListeningHistory ? "minus.circle" : "plus.circle")
                            .foregroundColor(settings.accentColor.color)
                            .padding(4)
                            .conditionalGlassEffect()
                            .onTapGesture {
                                settings.hapticFeedback()
                                
                                withAnimation {
                                    showListeningHistory.toggle()
                                }
                            }
                    }
                }
            ) {
                VStack {
                    Group {
                        if let onSelectSurah {
                            Button {
                                settings.hapticFeedback()
                                onSelectSurah(surah.id)
                            } label: {
                                lastListenedTitleRow(surah: surah)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                        } else {
                            NavigationLink(destination:
                                SurahView(surah: surah)
                                    .transition(.opacity)
                                    .animation(.easeInOut, value: lastListenedSurah.surahName)
                            ) {
                                lastListenedTitleRow(surah: surah)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .padding(.bottom, 1)

                    HStack {
                        Text(lastListenedSurah.reciter.displayNameWithEnglishQiraah)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Spacer()

                        Text("\(formatMMSS(lastListenedSurah.currentDuration)) / \(formatMMSS(lastListenedSurah.fullDuration))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }

                    TinyProgressBar(
                        fraction: lastListenedSurah.fullDuration > 0 ? lastListenedSurah.currentDuration / lastListenedSurah.fullDuration : 0,
                        color: settings.accentColor.color
                    )
                    .padding(.top, 3)
                    .opacity(quranPlayer.isPlaying || quranPlayer.isPaused ? 0.35 : 1)
                    .animation(.easeInOut, value: quranPlayer.isPlaying || quranPlayer.isPaused)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())

                if showListeningHistory && !quranPlayer.listeningHistory.isEmpty {
                    ForEach(quranPlayer.listeningHistory) { item in
                        if let historySurah = quranData.quran.first(where: { $0.id == item.surahNumber }) {
                            if let onSelectSurah {
                                Button {
                                    settings.hapticFeedback()
                                    onSelectSurah(historySurah.id)
                                } label: {
                                    listeningHistoryLabel(item)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            } else {
                                NavigationLink(destination: SurahView(surah: historySurah)) {
                                    listeningHistoryLabel(item)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .contentShape(Rectangle())
                            }
                        }
                    }
                }
            }
            .rightSwipeActions(
                surahID: surah.id,
                surahName: surah.nameTransliteration,
                certainReciter: true,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
            .leftSwipeActions(surah: surah.id, favoriteSurahs: favoriteSurahs)
            #if os(iOS)
            .contextMenu {
                Text("Surah Actions")
                    .foregroundStyle(.secondary)

                Button(role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        settings.lastListenedSurah = nil
                    }
                } label: {
                    Label("Remove", systemImage: "minus.circle")
                }

                Button(role: .destructive) {
                    settings.hapticFeedback()
                    confirmDeleteForever = true
                } label: {
                    Label("Delete Forever", systemImage: "trash")
                }

                Divider()

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: lastListenedSurah.surahNumber,
                        surahName: lastListenedSurah.surahName,
                        certainReciter: true
                    )
                } label: {
                    Label("Play Last Listened", systemImage: "play.fill")
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: lastListenedSurah.surahNumber,
                        surahName: surah.nameTransliteration
                    )
                } label: {
                    Label("Play from Beginning", systemImage: "memories")
                }

                Divider()

                SurahContextMenu(
                    surahID: surah.id,
                    surahName: surah.nameTransliteration,
                    favoriteSurahs: favoriteSurahs,
                    searchText: $searchText,
                    scrollToSurahID: $scrollToSurahID,
                    lastListened: true
                )
            }
            .confirmationDialog("Are you sure?", isPresented: $confirmDeleteForever, titleVisibility: .visible) {
                Button("Remove Permanently", role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        settings.lastListenedSurah = nil
                        settings.saveLastListenedSurah = false
                    }
                }
                Button("Cancel") {}
            } message: {
                Text("You can re-enable Last Listened Surah later in Quran Settings.")
            }
            #endif
            .animation(.easeInOut, value: quranPlayer.isPlaying || quranPlayer.isPaused)
        )
    }

    private func lastListenedTitleRow(surah: Surah) -> some View {
        HStack {
            Text("Surah \(lastListenedSurah.surahNumber): \(lastListenedSurah.surahName)")
                .font(.title2.bold())
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer()

            Menu {
                Text("Last Listened")
                    .foregroundStyle(.secondary)

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: lastListenedSurah.surahNumber,
                        surahName: lastListenedSurah.surahName,
                        certainReciter: true)
                } label: {
                    Label("Play Last Listened", systemImage: "play.fill")
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: lastListenedSurah.surahNumber,
                        surahName: surah.nameTransliteration)
                } label: {
                    Label("Play from Beginning", systemImage: "memories")
                }
            } label: {
                Image(systemName: "play.fill")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .foregroundColor(settings.accentColor.color)
                    .minimumScaleFactor(0.75)
                    .transition(.opacity)
                    .opacity(!quranPlayer.isPlaying && !quranPlayer.isPaused ? 1 : 0.35)
                    // The opacity only depends on whether playback is active, so animate on that one value.
                    .animation(.easeInOut, value: quranPlayer.isPlaying || quranPlayer.isPaused)
                    .contentShape(Rectangle())
            }
            .disabled(quranPlayer.isPlaying || quranPlayer.isPaused)
        }
    }

    private func listeningHistoryLabel(_ item: ListeningHistoryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Surah \(item.surahNumber): \(item.surahName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(item.reciter.displayNameWithEnglishQiraah)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                // Where the user stopped, when the entry knows it (entries from older builds don't).
                if let current = item.currentDuration, let full = item.fullDuration, full > 0 {
                    Text("\(formatMMSS(current)) / \(formatMMSS(full))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            Spacer(minLength: 8)

            historyTimestampLabel(item.timestamp)

            #if os(iOS)
            // Play controls for the history entry: from the top, or - when the stopped position is known - 
            // picking up exactly where the user left off (the same resume path Last Listened uses).
            Menu {
                Text("Surah \(item.surahNumber): \(item.surahName)")
                    .foregroundStyle(.secondary)

                if let current = item.currentDuration, let full = item.fullDuration, current > 1 {
                    Button {
                        settings.hapticFeedback()
                        // Resuming makes this entry the Last Listened again - with its own reciter and
                        // position - then plays through the standard certain-reciter resume path.
                        settings.lastListenedSurah = LastListenedSurah(
                            surahNumber: item.surahNumber,
                            surahName: item.surahName,
                            reciter: item.reciter,
                            currentDuration: current,
                            fullDuration: full
                        )
                        quranPlayer.playSurah(
                            surahNumber: item.surahNumber,
                            surahName: item.surahName,
                            certainReciter: true
                        )
                    } label: {
                        Label("Resume from \(formatMMSS(current))", systemImage: "play.fill")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: item.surahNumber,
                        surahName: item.surahName
                    )
                } label: {
                    Label("Play from Beginning", systemImage: "memories")
                }
            } label: {
                Image(systemName: "play.fill")
                    .font(.footnote)
                    .foregroundColor(settings.accentColor.color.opacity(0.75))
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            #endif
        }
        .padding(.vertical, 4)
    }
}

/// Compact summary-mode tile that previews a single ayah (Arabic / transliteration / English),
/// each limited to two lines - like a normal AyahRow but trimmed to fit a tile.
struct SummaryAyahTile: View {
    @ObservedObject var settings = Settings.shared

    let title: String
    let icon: String
    let surah: Surah
    let ayah: Ayah
    var titleColor: Color = .secondary
    /// Whether this tile's recents are the ones currently unfolded below the grid (flips the corner icon).
    var isExpanded: Bool = false
    /// When set, the tile grows a small toggle in its corner that unfolds this tile's recent history below
    /// the summary grid - the summary-mode counterpart of the +/- the full-size rows carry on their headers.
    var onExpand: (() -> Void)? = nil
    let onTap: () -> Void

    /// e.g. "Al-Fatiha 1:5"
    private var detail: String { "\(surah.nameTransliteration) \(surah.id):\(ayah.id)" }

    private func arabicDisplayText() -> String {
        let text = ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText)
        return settings.beginnerMode ? text.map { String($0) }.joined(separator: " ") : text
    }

    private var shouldShowTajweedColors: Bool {
        settings.showTajweedColors && settings.showArabicText && settings.isHafsDisplay
    }

    private func arabicTajweedText() -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        let text = ayah.displayArabicText(surahId: surah.id, clean: false)
        let displayText = settings.cleanArabicText ? ayah.displayArabicText(surahId: surah.id, clean: true) : text
        let renderedDisplayText = settings.beginnerMode ? displayText.map { String($0) }.joined(separator: " ") : displayText
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
        Button {
            settings.hapticFeedback()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                if !title.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundColor(settings.accentColor.color)
                        Text(title)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(titleColor)
                            .lineLimit(1)

                        if let onExpand {
                            Spacer(minLength: 0)

                            Image(systemName: isExpanded ? "minus.circle" : "plus.circle")
                                .font(.caption)
                                .foregroundColor(settings.accentColor.color)
                                .contentShape(Rectangle().inset(by: -8))
                                .onTapGesture {
                                    settings.hapticFeedback()
                                    onExpand()
                                }
                                .accessibilityLabel("Show recent \(title)")
                        }
                    }
                }

                Text(detail)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                ayahPreview

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(12)
            // Clear conditional glass (never accent-tinted) - these summary tiles have no favorite state, so
            // they stay a plain glass card like the rest of the app's clear tiles.
            .conditionalGlassEffect(clear: true, rectangle: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var ayahPreview: some View {
        VStack(alignment: .leading, spacing: 6) {
            if settings.showArabicText {
                HighlightedSnippet(
                    source: arabicDisplayText(),
                    term: "",
                    font: Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * 1.1),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: arabicTajweedText(),
                    beginnerMode: settings.beginnerMode,
                    lineLimit: 1
                )
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            if settings.showTransliteration, settings.isHafsDisplay {
                Text(ayah.textTransliteration)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if settings.showEnglishSaheeh, settings.isHafsDisplay {
                Text(ayah.textEnglishSaheeh)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if settings.showEnglishMustafa, settings.isHafsDisplay {
                Text(ayah.textEnglishMustafa)
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Compact summary-mode tile for the last-listened surah. There is no ayah, so it shows the reciter,
/// duration, a play button, and a tiny progress bar instead - sized to match the ayah tile beside it.
struct SummarySurahTile: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranPlayer = QuranPlayer.shared

    let title: String
    let icon: String
    let surah: Surah
    let lastListenedSurah: LastListenedSurah
    var titleColor: Color = .secondary
    /// See `SummaryAyahTile.isExpanded` / `.onExpand`.
    var isExpanded: Bool = false
    var onExpand: (() -> Void)? = nil
    let onTap: () -> Void

    /// e.g. "1 - Al-Fatiha"
    private var detail: String { "\(surah.id) - \(surah.nameTransliteration)" }

    var body: some View {
        Button {
            settings.hapticFeedback()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(settings.accentColor.color)
                    Text(title)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(titleColor)
                        .lineLimit(1)

                    if let onExpand {
                        Spacer(minLength: 0)

                        Image(systemName: isExpanded ? "minus.circle" : "plus.circle")
                            .font(.caption)
                            .foregroundColor(settings.accentColor.color)
                            .contentShape(Rectangle().inset(by: -8))
                            .onTapGesture {
                                settings.hapticFeedback()
                                onExpand()
                            }
                            .accessibilityLabel("Show recent \(title)")
                    }
                }

                Text(detail)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text(lastListenedSurah.reciter.displayNameWithEnglishQiraah)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 6) {
                    Text("\(formatMMSS(lastListenedSurah.currentDuration)) / \(formatMMSS(lastListenedSurah.fullDuration))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Spacer()

                    Menu {
                        Text("Last Listened")
                            .foregroundStyle(.secondary)

                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playSurah(
                                surahNumber: lastListenedSurah.surahNumber,
                                surahName: lastListenedSurah.surahName,
                                certainReciter: true
                            )
                        } label: {
                            Label("Play Last Listened", systemImage: "play.fill")
                        }

                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playSurah(
                                surahNumber: lastListenedSurah.surahNumber,
                                surahName: surah.nameTransliteration
                            )
                        } label: {
                            Label("Play from Beginning", systemImage: "memories")
                        }
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.subheadline)
                            .foregroundColor(settings.accentColor.color)
                            .opacity(!quranPlayer.isPlaying && !quranPlayer.isPaused ? 1 : 0.35)
                            .contentShape(Rectangle())
                    }
                    .disabled(quranPlayer.isPlaying || quranPlayer.isPaused)
                }

                TinyProgressBar(
                    fraction: lastListenedSurah.fullDuration > 0 ? lastListenedSurah.currentDuration / lastListenedSurah.fullDuration : 0,
                    color: settings.accentColor.color
                )
                .padding(.top, 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(12)
            // Clear conditional glass (never accent-tinted) - these summary tiles have no favorite state, so
            // they stay a plain glass card like the rest of the app's clear tiles.
            .conditionalGlassEffect(clear: true, rectangle: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
#endif

struct LastReadAyahRow: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared
    @ObservedObject private var quranData = QuranData.shared

    let surah: Surah
    let ayah: Ayah

    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    @Binding var showReadingHistory: Bool
    var onSelectAyah: ((Int, Int) -> Void)? = nil

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah.id)-\(ayah.id)")
    }
    
    private var noteToShow: String? {
        noteText(surahID: surah.id, ayahID: ayah.id)
    }

    private func noteText(surahID: Int, ayahID: Int) -> String? {
        guard let idx = settings.bookmarkedAyahs.firstIndex(where: { $0.surah == surahID && $0.ayah == ayahID }) else {
            return nil
        }
        let t = settings.bookmarkedAyahs[idx].note?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (t?.isEmpty == false) ? t : nil
    }

    /// The ayah row plus its progress bar as a single tappable unit, so swipe/context actions cover both
    /// and there is no stray standalone row (which left a large gap when the ayah had no note).
    private var lastReadRowContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            SurahAyahRow(surah: surah, ayah: ayah, note: noteToShow)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            TinyProgressBar(
                fraction: surah.numberOfAyahs > 0 ? Double(ayah.id) / Double(surah.numberOfAyahs) : 0,
                color: settings.accentColor.color
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// A reading-history entry: the ayah, dimmed, with a trailing "when" timestamp.
    private func readHistoryLabel(surah: Surah, ayah: Ayah, timestamp: Date) -> some View {
        HStack(spacing: 8) {
            SurahAyahRow(surah: surah, ayah: ayah, note: noteText(surahID: surah.id, ayahID: ayah.id))
                .opacity(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            historyTimestampLabel(timestamp)
        }
        .contentShape(Rectangle())
    }

    var body: some View {
        Section(header:
            HStack {
                Text("LAST READ AYAH")

                Spacer()

                if !quranPlayer.readingHistory.isEmpty {
                    Image(systemName: showReadingHistory ? "minus.circle" : "plus.circle")
                        .foregroundColor(settings.accentColor.color)
                        .padding(4)
                        .conditionalGlassEffect()
                        .onTapGesture {
                            settings.hapticFeedback()
                            
                            withAnimation {
                                showReadingHistory.toggle()
                            }
                        }
                }
            }
        ) {
            Group {
                if let onSelectAyah {
                    Button {
                        settings.hapticFeedback()
                        onSelectAyah(surah.id, ayah.id)
                    } label: {
                        lastReadRowContent
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                } else {
                    NavigationLink(destination: SurahView(surah: surah, ayah: ayah.id)) {
                        lastReadRowContent
                    }
                    .tag(surah.id)
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
                bookmarkedAyah: ayah.id
            )
            .ayahContextMenuModifier(
                surah: surah.id,
                ayah: ayah.id,
                favoriteSurahs: favoriteSurahs,
                bookmarkedAyahs: bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID,
                lastRead: true
            )

            if showReadingHistory && !quranPlayer.readingHistory.isEmpty {
                ForEach(quranPlayer.readingHistory) { item in
                    let normalizedAyah = max(1, item.ayahNumber)
                    if let surah = quranData.quran.first(where: { $0.id == item.surahNumber }), let ayah = surah.ayahs.first(where: { $0.id == normalizedAyah }) {
                        Group {
                            if let onSelectAyah {
                                Button {
                                    settings.hapticFeedback()
                                    onSelectAyah(surah.id, ayah.id)
                                } label: {
                                    readHistoryLabel(surah: surah, ayah: ayah, timestamp: item.timestamp)
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            } else {
                                NavigationLink(destination: SurahView(surah: surah, ayah: ayah.id)) {
                                    readHistoryLabel(surah: surah, ayah: ayah, timestamp: item.timestamp)
                                }
                                .tag(surah.id)
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
                            bookmarkedAyah: ayah.id
                        )
                        .ayahContextMenuModifier(
                            surah: surah.id,
                            ayah: ayah.id,
                            favoriteSurahs: favoriteSurahs,
                            bookmarkedAyahs: bookmarkedAyahs,
                            searchText: $searchText,
                            scrollToSurahID: $scrollToSurahID,
                            lastRead: true
                        )
                    }
                }
            }
        }
    }
}

#if os(iOS)
/// The last individual ayah the user listened to (single ayah or custom range). Mirrors LastReadAyahRow.
struct LastListenedAyahRow: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared
    @ObservedObject private var quranData = QuranData.shared

    let surah: Surah
    let ayah: Ayah
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    @Binding var showAyahListeningHistory: Bool
    var onSelectAyah: ((Int, Int) -> Void)? = nil

    @State private var confirmDeleteForever = false

    private var rowContent: some View {
        HStack(spacing: 8) {
            SurahAyahRow(surah: surah, ayah: ayah)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Resume: play from this ayah and keep going through the surah (task: "play from ayah so it keeps
            // playing after"). A child onTapGesture (not a nested Button) so it works inside the row's
            // navigation wrapper, the same pattern the grid favorite star uses.
            Image(systemName: "play.circle.fill")
                .font(.title3)
                .foregroundStyle(settings.accentColor.color)
                .contentShape(Rectangle().inset(by: -8))
                .onTapGesture {
                    settings.hapticFeedback()
                    quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
                }
                .accessibilityLabel("Play from this ayah")
        }
        .contentShape(Rectangle())
    }

    /// A history entry's row: the ayah, dimmed, with a trailing "when" timestamp.
    private func ayahHistoryLabel(histSurah: Surah, histAyah: Ayah, timestamp: Date) -> some View {
        HStack(spacing: 8) {
            SurahAyahRow(surah: histSurah, ayah: histAyah)
                .opacity(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            historyTimestampLabel(timestamp)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func historyRow(_ item: AyahListeningHistoryItem) -> some View {
        if let histSurah = quranData.surah(item.surahNumber),
           let histAyah = histSurah.ayahs.first(where: { $0.id == item.ayahNumber }) {
            Group {
                if let onSelectAyah {
                    Button {
                        settings.hapticFeedback()
                        onSelectAyah(histSurah.id, histAyah.id)
                    } label: {
                        ayahHistoryLabel(histSurah: histSurah, histAyah: histAyah, timestamp: item.timestamp)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                } else {
                    NavigationLink(destination: SurahView(surah: histSurah, ayah: histAyah.id)) {
                        ayahHistoryLabel(histSurah: histSurah, histAyah: histAyah, timestamp: item.timestamp)
                    }
                    .tag(histSurah.id)
                    .contentShape(Rectangle())
                }
            }
            .rightSwipeActions(
                surahID: histSurah.id,
                surahName: histSurah.nameTransliteration,
                ayahID: histAyah.id,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
            .leftSwipeActions(
                surah: histSurah.id,
                favoriteSurahs: favoriteSurahs,
                bookmarkedAyahs: bookmarkedAyahs,
                bookmarkedSurah: histSurah.id,
                bookmarkedAyah: histAyah.id
            )
        }
    }

    var body: some View {
        Section(header:
            HStack {
                Text("LAST LISTENED AYAH")

                Spacer()

                if !quranPlayer.ayahListeningHistory.isEmpty {
                    Image(systemName: showAyahListeningHistory ? "minus.circle" : "plus.circle")
                        .foregroundColor(settings.accentColor.color)
                        .padding(4)
                        .conditionalGlassEffect()
                        .onTapGesture {
                            settings.hapticFeedback()
                            withAnimation {
                                showAyahListeningHistory.toggle()
                            }
                        }
                }
            }
        ) {
            Group {
                if let onSelectAyah {
                    Button {
                        settings.hapticFeedback()
                        onSelectAyah(surah.id, ayah.id)
                    } label: {
                        rowContent
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                } else {
                    NavigationLink(destination: SurahView(surah: surah, ayah: ayah.id)) {
                        rowContent
                    }
                    .tag(surah.id)
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
                bookmarkedAyah: ayah.id
            )
            .contextMenu {
                Text("Last Listened Ayah")
                    .foregroundStyle(.secondary)

                Button(role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        settings.lastListenedAyah = nil
                    }
                } label: {
                    Label("Remove", systemImage: "minus.circle")
                }

                Button(role: .destructive) {
                    settings.hapticFeedback()
                    confirmDeleteForever = true
                } label: {
                    Label("Delete Forever", systemImage: "trash")
                }

                Divider()

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
                } label: {
                    Label("Play This Ayah", systemImage: "play.circle")
                }

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id, continueRecitation: true)
                } label: {
                    Label("Play From Ayah", systemImage: "play.circle.fill")
                }
            }
            .confirmationDialog("Are you sure?", isPresented: $confirmDeleteForever, titleVisibility: .visible) {
                Button("Remove Permanently", role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        settings.lastListenedAyah = nil
                        settings.saveLastListenedAyah = false
                    }
                }
                Button("Cancel") {}
            } message: {
                Text("You can re-enable Last Listened Ayah later in Quran Settings.")
            }

            if showAyahListeningHistory && !quranPlayer.ayahListeningHistory.isEmpty {
                ForEach(quranPlayer.ayahListeningHistory) { item in
                    historyRow(item)
                }
            }
        }
    }
}

/// The deterministic daily "Ayah of the Day" card shown at the top of the Quran tab.
struct AyahOfTheDayRow: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared

    let surah: Surah
    let ayah: Ayah
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    var onSelectAyah: ((Int, Int) -> Void)? = nil

    /// A featured card (accent-tinted glass, larger centered Arabic + translation) so the daily ayah looks
    /// distinct from the compact Last Read / Last Listened rows.
    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if settings.showArabicText {
                Text(ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: settings.displayQiraahForArabic))
                    .font(Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .title2).pointSize))
                    .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineSpacing(6)
            }

            Text("Surah \(surah.id):\(ayah.id) · \(surah.nameTransliteration)")
                .font(.caption.weight(.semibold))
                .foregroundColor(settings.accentColor.color)

            Text(ayah.textEnglishSaheeh.isEmpty ? ayah.textEnglishMustafa : ayah.textEnglishSaheeh)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .conditionalGlassEffect(rectangle: true, useColor: 0.18)
        .contentShape(Rectangle())
    }

    var body: some View {
        Section(header:
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("AYAH OF THE DAY")
            }
            .foregroundColor(settings.accentColor.color)
        ) {
            Group {
                if let onSelectAyah {
                    Button {
                        settings.hapticFeedback()
                        onSelectAyah(surah.id, ayah.id)
                    } label: {
                        rowContent
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                } else {
                    NavigationLink(destination: SurahView(surah: surah, ayah: ayah.id)) {
                        rowContent
                    }
                    .tag(surah.id)
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
                bookmarkedAyah: ayah.id
            )
            .ayahContextMenuModifier(
                surah: surah.id,
                ayah: ayah.id,
                favoriteSurahs: favoriteSurahs,
                bookmarkedAyahs: bookmarkedAyahs,
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID,
                ayahOfTheDay: true
            )
        }
    }
}
#endif

/// Compact, Arabic-only ayah row: the ayah reference (and an optional leading label like "Page 3")
/// plus the Arabic text with tajweed + all reading settings applied, sized down to read nicely in
/// page/juz search results and the Pages browse list.
struct CompactAyahArabicRow: View {
    @ObservedObject var settings = Settings.shared

    let surah: Surah
    let ayah: Ayah
    var leadingLabel: String? = nil

    private var shouldShowTajweedColors: Bool {
        settings.showTajweedColors && settings.showArabicText && settings.isHafsDisplay
    }

    private func arabicDisplayText() -> String {
        let text = ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText)
        return settings.beginnerMode ? text.map { String($0) }.joined(separator: " ") : text
    }

    private func arabicTajweedText() -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        let text = ayah.displayArabicText(surahId: surah.id, clean: false)
        let displayText = settings.cleanArabicText ? ayah.displayArabicText(surahId: surah.id, clean: true) : text
        let renderedDisplayText = settings.beginnerMode ? displayText.map { String($0) }.joined(separator: " ") : displayText
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
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                if let leadingLabel {
                    Text(leadingLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Text("\(surah.id):\(ayah.id)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: 64, alignment: .leading)

            if settings.showArabicText {
                HighlightedSnippet(
                    source: arabicDisplayText(),
                    term: "",
                    font: Font.arabic(settings.quranDisplayFontName, size: settings.fontArabicSize * 0.8),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: arabicTajweedText(),
                    beginnerMode: settings.beginnerMode,
                    lineLimit: nil
                )
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, 2)
    }
}

/// Just the Arabic text of an ayah, rendered through the same pipeline as the reading view - same font,
/// tajweed colors, beginner-mode spacing, and Allah highlighting - sized by `scale`. Used for compact
/// previews such as the page/juz dividers in SurahView.
struct AyahArabicSnippet: View {
    @ObservedObject var settings = Settings.shared

    let surah: Surah
    let ayah: Ayah
    var scale: CGFloat = 0.8
    var lineLimit: Int? = 1

    private var shouldShowTajweedColors: Bool {
        settings.showTajweedColors && settings.showArabicText && settings.isHafsDisplay
    }

    private func arabicDisplayText() -> String {
        let text = ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText)
        return settings.beginnerMode ? text.map { String($0) }.joined(separator: " ") : text
    }

    private func arabicTajweedText() -> AttributedString? {
        guard shouldShowTajweedColors else { return nil }
        let text = ayah.displayArabicText(surahId: surah.id, clean: false)
        let displayText = settings.cleanArabicText ? ayah.displayArabicText(surahId: surah.id, clean: true) : text
        let renderedDisplayText = settings.beginnerMode ? displayText.map { String($0) }.joined(separator: " ") : displayText
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

            if settings.showFullSurahRow, let pageJuzLine {
                Label(pageJuzLine, systemImage: "map")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
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
    
    private var badgeWidth: CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .headline)
        let text = "10:100" as NSString
        let size = text.size(withAttributes: [.font: font])
        return size.width + 8
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
                .frame(width: badgeWidth, alignment: .center)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .conditionalGlassEffect(
                    useColor: isBookmarked ? 0.3 : nil,
                    customTint: isBookmarked ? settings.accentColor.color : nil
                )
                .onTapGesture {
                    settings.hapticFeedback()
                    toggleBookmarkWithNoteGuard()
                }

            if isBookmarked {
                Image(systemName: "bookmark.fill")
                    .font(.caption2)
                    .foregroundStyle(settings.accentColor.color)
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
        settings.beginnerMode ? arabic.map { String($0) }.joined(separator: " ") : arabic
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

    @ViewBuilder
    private func buildCompactSearchRow() -> some View {
        let visibility = searchVisibility()

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ayahReferenceBadge

                if visibility.showArabicLine {
                    HighlightedSnippet(
                        source: arabicDisplayText(),
                        term: (visibility.mArabic || visibility.forceArabicHighlight) ? query : "",
                        font: .custom(searchArabicFontName, size: UIFont.preferredFont(forTextStyle: .body).pointSize),
                        accent: settings.accentColor.color,
                        fg: .primary,
                        preStyledSource: arabicTajweedText(),
                        beginnerMode: settings.beginnerMode,
                        lineLimit: nil,
                        guaranteeMatch: visibility.forceArabicHighlight
                    )
                    .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .multilineTextAlignment(.trailing)
                    // Inside this badge+Arabic HStack SwiftUI otherwise truncates a long ayah to one line;
                    // fixedSize lets it wrap to as many lines as needed.
                    .fixedSize(horizontal: false, vertical: true)
                }
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

            if visibility.showSaheehLine {
                HighlightedSnippet(
                    source: englishSaheeh,
                    term: visibility.mSaheeh ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            if visibility.showMustafaLine {
                HighlightedSnippet(
                    source: englishMustafa,
                    term: visibility.mMustafa ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
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

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ayahReferenceBadge

                Text(surahName)
            }
            .font(.caption)
            .foregroundColor(settings.accentColor.color)
            .transition(.opacity)

            if visibility.showArabicLine {
                HighlightedSnippet(
                    source: arabicDisplayText(),
                    term: (visibility.mArabic || visibility.forceArabicHighlight) ? query : "",
                    font: .custom(searchArabicFontName, size: UIFont.preferredFont(forTextStyle: .body).pointSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: arabicTajweedText(),
                    beginnerMode: settings.beginnerMode,
                    lineLimit: nil,
                    guaranteeMatch: visibility.forceArabicHighlight
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

            if visibility.showSaheehLine {
                HighlightedSnippet(
                    source: englishSaheeh,
                    term: visibility.mSaheeh ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
                )
            }

            if visibility.showMustafaLine {
                HighlightedSnippet(
                    source: englishMustafa,
                    term: visibility.mMustafa ? query : "",
                    font: .footnote,
                    accent: settings.accentColor.color,
                    fg: .secondary
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
            scrollToSurahID: $scrollToSurahID
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
