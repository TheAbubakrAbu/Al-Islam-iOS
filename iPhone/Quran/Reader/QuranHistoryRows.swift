import SwiftUI

/// The clock time of a history entry, e.g. "5:30 PM" (locale-aware, so 24-hour locales get "17:30").
private let historyTimeFormatter: DateFormatter = {
    let f = DateFormatter()
    f.setLocalizedDateFormatFromTemplate("jmm")
    return f
}()

/// The weekday for entries inside the last week, e.g. "Mon".
private let historyWeekdayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.setLocalizedDateFormatFromTemplate("EEE")
    return f
}()

/// Month + day for anything older than a week, e.g. "Jul 12".
private let historyDayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.setLocalizedDateFormatFromTemplate("MMMd")
    return f
}()

/// The "when" for a history entry as an actual time rather than a relative age: "Today 5:30 PM",
/// "Yesterday 5:30 PM", "Mon 5:30 PM", "Jul 12 5:30 PM". Shown next to each history item so the
/// expanded list reads as a timeline.
func formatHistoryTimestamp(_ date: Date) -> String {
    let calendar = Calendar.current
    let time = historyTimeFormatter.string(from: date)

    if calendar.isDateInToday(date) { return String(localized: "Today \(time)") }
    if calendar.isDateInYesterday(date) { return String(localized: "Yesterday \(time)") }

    let daysAgo = calendar.dateComponents(
        [.day],
        from: calendar.startOfDay(for: date),
        to: calendar.startOfDay(for: Date())
    ).day ?? 0

    if daysAgo > 0 && daysAgo < 7 {
        return "\(historyWeekdayFormatter.string(from: date)) \(time)"
    }
    return "\(historyDayFormatter.string(from: date)) \(time)"
}

/// The tightest "when" that still means something, for the summary tiles' crowded title rows:
/// the bare time today ("5:30 PM"), "\(n)d" inside a week ("1d", "6d"), then "Jul 12". Even
/// "Yesterday" was too wide next to "Last Read Hadith" on a half-width tile.
func formatCompactHistoryTimestamp(_ date: Date) -> String {
    let calendar = Calendar.current
    if calendar.isDateInToday(date) { return historyTimeFormatter.string(from: date) }

    let daysAgo = calendar.dateComponents(
        [.day],
        from: calendar.startOfDay(for: date),
        to: calendar.startOfDay(for: Date())
    ).day ?? 0

    if daysAgo > 0 && daysAgo < 7 { return String(localized: "\(daysAgo)d") }
    return historyDayFormatter.string(from: date)
}

/// A small trailing timestamp caption for a history row.
func historyTimestampLabel(_ date: Date) -> some View {
    Text(formatHistoryTimestamp(date))
        .font(.caption2)
        .monospacedDigit()
        .foregroundStyle(.secondary)
        .lineLimit(1)
        // The label is now a date + time, so keep it whole and let the ayah beside it truncate instead.
        .fixedSize(horizontal: true, vertical: false)
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
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var quranData = QuranData.shared
    /// Actions only: not observed. Play state and the history lists publish on their own objects
    /// (see `NowPlayingState`), so an ayah advance no longer re-evaluates the summary tiles.
    private let quranPlayer = QuranPlayer.shared
    @ObservedObject private var playbackPhase = QuranPlayer.shared.phase
    @ObservedObject private var playbackHistory = QuranPlayer.shared.history

    let lastListenedSurah: LastListenedSurah
    let favoriteSurahs: Set<Int>
    
    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    var qiraahRefreshKey: String = ""
    @Binding var showListeningHistory: Bool
    var onSelectSurah: ((Int) -> Void)? = nil


    var body: some View {
        guard let surah = quranData.surah(lastListenedSurah.surahNumber)
        else { return AnyView(EmptyView()) }

        return AnyView(
            Section(header:
                HStack {
                    SectionIconHeader(String(localized: "LAST LISTENED SURAH"), icon: "headphones", accentTitle: true)

                    Spacer()

                    if !playbackHistory.listeningHistory.isEmpty {
                        Image(systemName: showListeningHistory ? "minus.circle" : "plus.circle")
                            .foregroundColor(settings.accentColor.color)
                            .padding(4)
                            .contentSurface()
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
                            NavigationLink(destination: LazyDestination {
                                SurahView(surah: surah)
                                    .transition(.opacity)
                                    .animation(.easeInOut, value: lastListenedSurah.surahName)
                            }) {
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

                        Text("\(formatMMSS(lastListenedSurah.currentDuration).localizedDigits) / \(formatMMSS(lastListenedSurah.fullDuration).localizedDigits)")
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
                    .opacity(playbackPhase.isPlaying || playbackPhase.isPaused ? 0.35 : 1)
                    .animation(.easeInOut, value: playbackPhase.isPlaying || playbackPhase.isPaused)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())

                if showListeningHistory && !playbackHistory.listeningHistory.isEmpty {
                    // Each entry's surah is looked up before the ForEach and the two-armed row sits in
                    // one view, so a row is one view by its type (see `OneRow`).
                    ForEach(playbackHistory.listeningHistory.paired { quranData.surah($0.surahNumber) }, id: \.item.id) { entry in
                        let item = entry.item
                        let historySurah = entry.found
                        OneRow {
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
                                NavigationLink(destination: LazyDestination { SurahView(surah: historySurah) }) {
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
            #endif
            .animation(.easeInOut, value: playbackPhase.isPlaying || playbackPhase.isPaused)
        )
    }

    private func lastListenedTitleRow(surah: Surah) -> some View {
        HStack {
            Text("Surah \(lastListenedSurah.surahNumber): \(lastListenedSurah.displaySurahName)")
                .font(.title2.bold())
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Spacer()

            ShortcutMenu(hold: MenuShortcut(String(localized: "Play Last Listened")) {
                settings.hapticFeedback()
                quranPlayer.playSurah(surahNumber: lastListenedSurah.surahNumber,
                                      surahName: lastListenedSurah.surahName, certainReciter: true)
            }) {
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
                    .opacity(!playbackPhase.isPlaying && !playbackPhase.isPaused ? 1 : 0.35)
                    // The opacity only depends on whether playback is active, so animate on that one value.
                    .animation(.easeInOut, value: playbackPhase.isPlaying || playbackPhase.isPaused)
                    .contentShape(Rectangle())
            }
            .disabled(playbackPhase.isPlaying || playbackPhase.isPaused)
        }
    }

    private func listeningHistoryLabel(_ item: ListeningHistoryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Surah \(item.surahNumber): \(item.displaySurahName)")
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
                    Text("\(formatMMSS(current).localizedDigits) / \(formatMMSS(full).localizedDigits)")
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
            ShortcutMenu(hold: MenuShortcut(String(localized: "Play from Beginning")) {
                settings.hapticFeedback()
                quranPlayer.playSurah(surahNumber: item.surahNumber, surahName: item.surahName)
            }) {
                Text("Surah \(item.surahNumber): \(item.displaySurahName)")
                    .foregroundStyle(.secondary)

                if let current = item.currentDuration, item.fullDuration != nil, current > 1 {
                    Button {
                        settings.hapticFeedback()
                        // Resuming makes this entry the Last Listened again, with its own reciter and
                        // position, after filing the surah it displaces (`resumeHistoryItem`).
                        quranPlayer.resumeHistoryItem(item)
                    } label: {
                        Label("Resume from \(formatMMSS(current).localizedDigits)", systemImage: "play.fill")
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

// MARK: - Summary lines

/// One item of a tab's YOUR SUMMARY, as a full-width line: the icon chip and the item's name
/// leading, its reference in the accent trailing, the history expander last. Under the line, for
/// the one item that is there to be READ rather than returned to (the Ayah or Hadith of the Day),
/// its text at reading size.
///
/// The summaries were 2x2 grids of half-width tiles until 2026-11-25. Half a screen is too narrow
/// for what a tile was asked to hold: "Last Listened Ayah" wrapped to two lines where the other
/// titles took one, every tile was then stretched to the tallest, and a verse got about four words
/// at caption size (Abu: "Summary tiles are so ugly with inconsistencies 2 lines for headers and the
/// actual verses are too small"). He looked at four layouts built as real screens and chose this
/// one: a line is as wide as the screen, so every name fits on one line at one size, the day's verse
/// is whole, and the places to pick up from are 44 pt each.
///
/// The label alone, so a host can put its own control round it (`GridTileMenu` on the Hadith of the
/// Day, for its long-press menu); `SummaryLine` is the label as a plain button.
struct SummaryLineLabel<Accessory: View, Detail: View>: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// An iPad sidebar's column, where the name and the reference cannot share a line.
    @Environment(\.isSidebarColumn) private var isSidebarColumn

    let title: String
    let icon: String
    let reference: String
    /// Whether `detail` draws anything: the line then keeps air above and below, where a bare line
    /// is centred in its 44 pt.
    var hasDetail: Bool = false
    /// Whether the line keeps the expander's slot when it has none, so every reference in the
    /// summary ends on the same edge.
    var keepsExpanderSlot: Bool = true
    /// Whether this item's recents are the ones unfolded under the summary (flips the expander).
    var isExpanded: Bool = false
    /// Unfolds this item's recents under the summary; nil, no expander.
    var onExpand: (() -> Void)? = nil
    /// Before the reference: the last listened surah's play button.
    @ViewBuilder var accessory: Accessory
    /// Under the line: the day's verse or narration.
    @ViewBuilder var detail: Detail

    var body: some View {
        // The name over the reference where one line cannot hold both: the accessibility text sizes
        // and an iPad sidebar. Decided from the environment, never by `ViewThatFits`: in a List row
        // that measures the taller form while the shorter one draws.
        let stacked = dynamicTypeSize.isAccessibilitySize || isSidebarColumn
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: stacked ? .top : .center, spacing: SummaryLineMetrics.chipGap) {
                AccentIconChip(systemImage: icon, size: SummaryLineMetrics.chipSize)

                if stacked {
                    VStack(alignment: .leading, spacing: 2) {
                        name
                        HStack(spacing: 6) {
                            accessory
                            referenceText
                        }
                    }
                    Spacer(minLength: 6)
                } else {
                    name.layoutPriority(1)
                    Spacer(minLength: 6)
                    accessory
                    referenceText
                }

                expander
            }

            if hasDetail {
                detail
            }
        }
        // The content keeps its IDEAL height. A VStack offers each child an equal share of the
        // height it is given before it offers the rest, and a Text offered less than its lines need
        // truncates to fit the offer: the day's Arabic came out as ONE line ending in an ellipsis,
        // with the room for its second line left empty above the block (at the accessibility sizes
        // on 26:8; at any size on an ayah two lines long).
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, hasDetail || stacked ? 10 : 0)
        // 44 pt, the smallest thing a finger should be asked to hit.
        .frame(maxWidth: .infinity, minHeight: SummaryLineMetrics.minHeight, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var name: some View {
        Text(title)
            .font(.footnote.weight(.medium))
            .foregroundColor(.secondaryOnGlass)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }

    private var referenceText: some View {
        Text(reference.localizedDigits)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(settings.accentColor.color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    @ViewBuilder
    private var expander: some View {
        if let onExpand {
            Image(systemName: isExpanded ? "minus.circle" : "plus.circle")
                .font(.subheadline)
                .foregroundColor(settings.accentColor.color)
                .frame(width: SummaryLineMetrics.expanderWidth)
                .contentShape(Rectangle().inset(by: -10))
                .onTapGesture {
                    settings.hapticFeedback()
                    onExpand()
                }
                .accessibilityLabel("Show recent \(title)")
        } else if keepsExpanderSlot {
            Color.clear.frame(width: SummaryLineMetrics.expanderWidth, height: 1)
        }
    }
}

/// A summary line as a button (see `SummaryLineLabel`).
struct SummaryLine<Accessory: View, Detail: View>: View {
    let title: String
    let icon: String
    let reference: String
    var hasDetail: Bool = false
    var keepsExpanderSlot: Bool = true
    var isExpanded: Bool = false
    var onExpand: (() -> Void)? = nil
    let onTap: () -> Void
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var detail: Detail

    var body: some View {
        Button {
            Settings.shared.hapticFeedback()
            onTap()
        } label: {
            SummaryLineLabel(title: title, icon: icon, reference: reference, hasDetail: hasDetail,
                             keepsExpanderSlot: keepsExpanderSlot, isExpanded: isExpanded, onExpand: onExpand,
                             accessory: { accessory }, detail: { detail })
        }
        .buttonStyle(SummaryLineButtonStyle())
    }
}

/// The lines' shared measures. File scope: the lines are generic and cannot hold static stored constants.
enum SummaryLineMetrics {
    static let chipSize: CGFloat = 24
    static let chipGap: CGFloat = 10
    static let expanderWidth: CGFloat = 22
    static let minHeight: CGFloat = 44
    /// Where a line's name starts, past its chip: where the hairline between two lines starts too.
    static let textInset: CGFloat = chipSize + chipGap

    /// The day's Arabic under its line: title3, the size a verse reads at, and no larger than 34 pt
    /// at the accessibility sizes, where uncapped it left room for four words in two lines.
    static func arabicSize(at size: DynamicTypeSize) -> CGFloat {
        min(textStylePointSize(.title3, at: size), 34)
    }

    /// `name` at exactly `arabicSize`. A FIXED size: `Font.custom(_:size:)` scales with the text
    /// size again on top of a size that already follows it, and at the accessibility sizes the
    /// 34 pt this asks for was drawn near 66.
    static func arabicFont(_ name: String, at size: DynamicTypeSize) -> Font {
        let points = arabicSize(at: size)
        return name == Settings.systemArabicFontName
            ? .system(size: points, design: .rounded)
            : .custom(name, fixedSize: points)
    }

    /// How many lines of each script the day's text gets under its line.
    static func detailLines(at size: DynamicTypeSize) -> Int {
        size.isAccessibilitySize ? 3 : 2
    }
}

/// The hairline between two summary lines, from where their names start.
struct SummaryLineDivider: View {
    var body: some View {
        Divider().padding(.leading, SummaryLineMetrics.textInset)
    }
}

/// A summary line under the finger dims, the way a list row answers a touch.
struct SummaryLineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// The Ayah of the Day under its summary line: the Arabic in the reader's own face and colours,
/// then whichever transliteration and translation the reader shows, up to two lines of each. A line
/// is the screen's width, so most ayahs are here whole; a long one ends in an ellipsis and opens on
/// a tap.
struct SummaryVerseLines: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// Read because the Arabic bakes a text style's size into a fixed font.
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let surah: Surah
    let ayah: Ayah

    private var arabicText: String {
        let text = ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText)
        return settings.beginnerMode ? text.beginnerSpaced : text
    }

    private var tajweedText: AttributedString? {
        guard settings.showTajweedColors, settings.showArabicText, settings.isHafsDisplay else { return nil }
        let text = ayah.displayArabicText(surahId: surah.id, clean: false)
        let displayText = settings.cleanArabicText ? ayah.displayArabicText(surahId: surah.id, clean: true) : text
        return TajweedStore.shared.attributedText(
            surah: surah.id,
            ayah: ayah.id,
            text: text,
            displayText: settings.beginnerMode ? displayText.beginnerSpaced : displayText,
            cleanDisplayText: settings.cleanArabicText,
            beginnerSpacing: settings.beginnerMode
        )
    }

    private var translation: String? {
        guard settings.isHafsDisplay else { return nil }
        if settings.showEnglishSaheeh { return ayah.textEnglishSaheeh }
        if settings.showEnglishMustafa { return ayah.textEnglishMustafa }
        return nil
    }

    var body: some View {
        // A third line of each at the accessibility text sizes, where two hold only a few words.
        let lines = SummaryLineMetrics.detailLines(at: dynamicTypeSize)
        VStack(alignment: .leading, spacing: 6) {
            if settings.showArabicText {
                HighlightedSnippet(
                    source: arabicText,
                    term: "",
                    font: SummaryLineMetrics.arabicFont(settings.quranDisplayFontName, at: dynamicTypeSize),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    preStyledSource: tajweedText,
                    beginnerMode: settings.beginnerMode,
                    lineLimit: lines
                )
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
                .environment(\.layoutDirection, .leftToRight)
            }

            if settings.showTransliteration, settings.isHafsDisplay {
                Text(ayah.textTransliteration)
                    .font(.footnote)
                    .foregroundColor(.secondaryOnGlass)
                    .lineLimit(lines)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .leftToRightContent()
            }

            if let translation {
                Text(translation)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(lines)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .leftToRightContent()
            }
        }
    }
}

/// The last listened surah's play button, before its name on the summary line: a tap opens its two
/// ways to play, a hold resumes where the listening stopped.
struct SummarySurahPlayButton: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    /// Actions only: not observed. Play state publishes on its own object (see `NowPlayingState`).
    private let quranPlayer = QuranPlayer.shared
    @ObservedObject private var playbackPhase = QuranPlayer.shared.phase

    let surah: Surah
    let lastListenedSurah: LastListenedSurah

    var body: some View {
        ShortcutMenu(hold: MenuShortcut(String(localized: "Play Last Listened")) {
            settings.hapticFeedback()
            quranPlayer.playSurah(surahNumber: lastListenedSurah.surahNumber,
                                  surahName: lastListenedSurah.surahName, certainReciter: true)
        }) {
            // Who recited it and how far in: the tile drew these on lines of their own.
            Text(verbatim: "\(lastListenedSurah.reciter.displayNameWithEnglishQiraah), \(formatMMSS(lastListenedSurah.currentDuration).localizedDigits) / \(formatMMSS(lastListenedSurah.fullDuration).localizedDigits)")
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
                .opacity(!playbackPhase.isPlaying && !playbackPhase.isPaused ? 1 : 0.35)
                // The glyph is small: the target is the line's whole height and reaches back
                // toward the name's side, while the glyph itself stays beside the surah it plays.
                .frame(minWidth: 30, minHeight: SummaryLineMetrics.minHeight, alignment: .trailing)
                .contentShape(Rectangle())
        }
        .disabled(playbackPhase.isPlaying || playbackPhase.isPaused)
    }
}
#endif

struct LastReadAyahRow: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// Actions only: not observed. Play state and the history lists publish on their own objects
    /// (see `NowPlayingState`), so an ayah advance no longer re-evaluates the summary tiles.
    private let quranPlayer = QuranPlayer.shared
    @ObservedObject private var playbackPhase = QuranPlayer.shared.phase
    @ObservedObject private var playbackHistory = QuranPlayer.shared.history
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
                .equatable()
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
                .equatable()
                .opacity(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            historyTimestampLabel(timestamp)
        }
        .contentShape(Rectangle())
    }

    var body: some View {
        Section(header:
            HStack {
                SectionIconHeader(String(localized: "LAST READ AYAH"), icon: "clock.arrow.circlepath", accentTitle: true)

                Spacer()

                if !playbackHistory.readingHistory.isEmpty {
                    Image(systemName: showReadingHistory ? "minus.circle" : "plus.circle")
                        .foregroundColor(settings.accentColor.color)
                        .padding(4)
                        .contentSurface()
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
                    NavigationLink(destination: LazyDestination { SurahView(surah: surah, ayah: ayah.id) }) {
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

            if showReadingHistory && !playbackHistory.readingHistory.isEmpty {
                // Each entry's surah and ayah are looked up before the ForEach and the two-armed row
                // sits in one view, so a row is one view by its type (see `OneRow`).
                let entries = playbackHistory.readingHistory.paired { item in
                    quranData.surah(item.surahNumber).flatMap { surah in
                        quranData.ayah(surah: item.surahNumber, ayah: max(1, item.ayahNumber)).map { (surah: surah, ayah: $0) }
                    }
                }
                ForEach(entries, id: \.item.id) { entry in
                    let item = entry.item
                    let surah = entry.found.surah
                    let ayah = entry.found.ayah
                    OneRow {
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
                            NavigationLink(destination: LazyDestination { SurahView(surah: surah, ayah: ayah.id) }) {
                                readHistoryLabel(surah: surah, ayah: ayah, timestamp: item.timestamp)
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
                        bookmarkedAyah: ayah.id
                    )
                    // No `lastRead:` here, as on the listening history's rows: that flag leads the
                    // menu with Remove, which clears the LAST READ position, so holding an older
                    // history entry and tapping Remove wiped the card above and kept the entry.
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
        }
    }
}

#if os(iOS)
/// The last individual ayah the user listened to (single ayah or custom range). Mirrors LastReadAyahRow.
struct LastListenedAyahRow: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// Actions only: not observed. Play state and the history lists publish on their own objects
    /// (see `NowPlayingState`), so an ayah advance no longer re-evaluates the summary tiles.
    private let quranPlayer = QuranPlayer.shared
    @ObservedObject private var playbackPhase = QuranPlayer.shared.phase
    @ObservedObject private var playbackHistory = QuranPlayer.shared.history
    @ObservedObject private var quranData = QuranData.shared

    let surah: Surah
    let ayah: Ayah
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int
    @Binding var showAyahListeningHistory: Bool
    var onSelectAyah: ((Int, Int) -> Void)? = nil


    private var rowContent: some View {
        HStack(spacing: 8) {
            SurahAyahRow(surah: surah, ayah: ayah)
                .equatable()
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
                .equatable()
                .opacity(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            historyTimestampLabel(timestamp)
        }
        .contentShape(Rectangle())
    }

    /// The history's entries beside the surah and ayah each names, the ones not loaded left out:
    /// looked up before the ForEach, so a row is never an `if let` (see `OneRow`).
    private var historyEntries: [(item: AyahListeningHistoryItem, found: (surah: Surah, ayah: Ayah))] {
        playbackHistory.ayahListeningHistory.paired { item in
            quranData.surah(item.surahNumber).flatMap { surah in
                surah.ayahs.first(where: { $0.id == item.ayahNumber }).map { (surah: surah, ayah: $0) }
            }
        }
    }

    private func historyRow(_ item: AyahListeningHistoryItem, histSurah: Surah, histAyah: Ayah) -> some View {
        OneRow {
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
                NavigationLink(destination: LazyDestination { SurahView(surah: histSurah, ayah: histAyah.id) }) {
                    ayahHistoryLabel(histSurah: histSurah, histAyah: histAyah, timestamp: item.timestamp)
                }
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
        .ayahContextMenuModifier(
            surah: histSurah.id,
            ayah: histAyah.id,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: $searchText,
            scrollToSurahID: $scrollToSurahID
        )
    }

    var body: some View {
        Section(header:
            HStack {
                SectionIconHeader(String(localized: "LAST LISTENED AYAH"), icon: "headphones", accentTitle: true)

                Spacer()

                if !playbackHistory.ayahListeningHistory.isEmpty {
                    Image(systemName: showAyahListeningHistory ? "minus.circle" : "plus.circle")
                        .foregroundColor(settings.accentColor.color)
                        .padding(4)
                        .contentSurface()
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
                    NavigationLink(destination: LazyDestination { SurahView(surah: surah, ayah: ayah.id) }) {
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

                Divider()

                Button {
                    settings.hapticFeedback()
                    quranPlayer.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
                } label: {
                    Label("Play This Ayah", systemImage: "play.circle")
                }

                #if os(iOS)
                Button {
                    settings.hapticFeedback()
                    WordClipPlayer.shared.toggle(surah: surah.id, ayah: ayah.id)
                } label: {
                    Label("Play Word by Word", systemImage: "text.word.spacing")
                }
                #endif

                Menu {
                    ayahPlayFromMenuItems(surah: surah.id, ayah: ayah.id, settings: settings,
                                          quranPlayer: quranPlayer)
                } label: {
                    Label("Play From Ayah", systemImage: "play.circle.fill")
                }
            }

            if showAyahListeningHistory && !playbackHistory.ayahListeningHistory.isEmpty {
                ForEach(historyEntries, id: \.item.id) { entry in
                    historyRow(entry.item, histSurah: entry.found.surah, histAyah: entry.found.ayah)
                }
            }
        }
    }
}

/// The deterministic daily "Ayah of the Day" card shown at the top of the Quran tab.
struct AyahOfTheDayRow: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// Actions only: not observed. Play state and the history lists publish on their own objects
    /// (see `NowPlayingState`), so an ayah advance no longer re-evaluates the summary tiles.
    private let quranPlayer = QuranPlayer.shared
    @ObservedObject private var playbackPhase = QuranPlayer.shared.phase
    @ObservedObject private var playbackHistory = QuranPlayer.shared.history

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
                    // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
                    .environment(\.layoutDirection, .leftToRight)
                    .lineSpacing(6)
            }

            Text("Surah \(surah.id):\(ayah.id) · \(surah.displayName)")
                .font(.caption.weight(.semibold))
                .foregroundColor(settings.accentColor.color)

            Text(ayah.textEnglishSaheeh.isEmpty ? ayah.textEnglishMustafa : ayah.textEnglishSaheeh)
                .font(.subheadline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .leftToRightContent()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentSurface(rectangle: true, useColor: 0.18)
        .contentShape(Rectangle())
    }

    var body: some View {
        Section(header:
            // Gray: the day's pick, not one of yours (`SectionIconHeader.accentTitle`'s rule).
            SectionIconHeader(String(localized: "AYAH OF THE DAY"), icon: "sparkles")
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
                    NavigationLink(destination: LazyDestination { SurahView(surah: surah, ayah: ayah.id) }) {
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

#if os(iOS)
// MARK: - The Quran tab's history screen

/// Everything the Quran tab remembers, on one screen: what you read, what you listened to (surah and
/// ayah), the Ayah of the Day on earlier days, and your recent searches. The hadith tab's History
/// door, for the Quran (Abu, 2026-09-07).
///
/// The summary tiles each unfold their OWN slice inline; this is the whole of it in one place, so a
/// reader who wants "where was I last week" does not have to open four tiles. Every row pushes
/// through `onOpen`, the tab's own `push(surahID:ayahID:)`, so a history row lands in the reader
/// exactly like a bookmark does.
struct QuranHistoryView: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var playbackHistory = QuranPlayer.shared.history
    @Environment(\.dismiss) private var dismiss

    /// Pushes the reader at this ayah (nil ayah = the surah's top).
    let onOpen: (Int, Int?) -> Void

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// The last ten days' Ayah of the Day, oldest last - the same walk the summary tile's expansion does.
    private var recentAyahsOfTheDay: [(dayLabel: String, surah: Surah, ayah: Ayah)] {
        (0..<10).compactMap { daysBack in
            guard let date = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()),
                  let ref = settings.ayahOfTheDayReference(for: date),
                  let surah = quranData.surah(ref.surahID),
                  let ayah = surah.ayahs.first(where: { $0.id == ref.ayahID })
            else { return nil }
            return (Self.dayFormatter.string(from: date), surah, ayah)
        }
    }

    var body: some View {
        let _ = RenderCounter.hit("QuranHistoryView")
        let reading = playbackHistory.readingHistory
        let listenedAyahs = playbackHistory.ayahListeningHistory
        let listenedSurahs = playbackHistory.listeningHistory
        // Each row's surah and ayah are looked up HERE, not inside the ForEach. A row that is an
        // `if let` is not one view by its type, and the List then deletes and re-inserts the section's
        // off-screen rows when this body runs again after a scroll (measured 2026-11-17; see
        // `SummaryTileGrid.body`). An item whose ayah is not loaded gives no row, as before, and its
        // section still shows by the history itself, as before.
        let readingRows = reading.compactMap { item in
            quranData.surah(item.surahNumber).flatMap { surah in
                surah.ayahs.first(where: { $0.id == max(1, item.ayahNumber) }).map { (item: item, surah: surah, ayah: $0) }
            }
        }
        let listenedAyahRows = listenedAyahs.compactMap { item in
            quranData.surah(item.surahNumber).flatMap { surah in
                surah.ayahs.first(where: { $0.id == item.ayahNumber }).map { (item: item, surah: surah, ayah: $0) }
            }
        }
        let listenedSurahRows = listenedSurahs.compactMap { item in
            quranData.surah(item.surahNumber).map { (item: item, surah: $0) }
        }
        let daily = settings.showAyahOfTheDay ? recentAyahsOfTheDay : []
        let searches = settings.quranSearchHistory

        List {
            Group {
                // What the screen is, said once at the top rather than as a caption on the door that
                // opens it (Abu, 2026-09-07). The article kit's lead card, as the Hadith tab's History
                // opens (2026-10-26); it was a plain paragraph here.
                Section {
                    ArticleLead(String(localized: "Everything this tab remembers: the ayahs you read, what you listened to, the Ayah of the Day on earlier days, and your recent searches. Tap any of them to open it in the reader. It never leaves this device."),
                                eyebrow: String(localized: "IN SHORT"))
                }

                if reading.isEmpty, listenedAyahs.isEmpty, listenedSurahs.isEmpty, daily.isEmpty, searches.isEmpty {
                    Section {
                        Text(String(localized: "Nothing yet. Read an ayah, play a surah or search, and it collects here."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if !reading.isEmpty {
                    Section(header: Text("WHAT YOU READ")) {
                        ForEach(readingRows, id: \.item.id) { row in
                            ayahRow(surah: row.surah, ayah: row.ayah, caption: nil, timestamp: row.item.timestamp)
                        }
                    }
                }

                if !listenedAyahs.isEmpty {
                    Section(header: Text("AYAHS YOU LISTENED TO")) {
                        ForEach(listenedAyahRows, id: \.item.id) { row in
                            ayahRow(surah: row.surah, ayah: row.ayah,
                                    caption: row.item.reciter.displayNameWithEnglishQiraah,
                                    timestamp: row.item.timestamp)
                        }
                    }
                }

                if !listenedSurahs.isEmpty {
                    Section(header: Text("SURAHS YOU LISTENED TO")) {
                        ForEach(listenedSurahRows, id: \.item.id) { row in
                            surahRow(surah: row.surah,
                                     reciter: row.item.reciter.displayNameWithEnglishQiraah,
                                     timestamp: row.item.timestamp)
                        }
                    }
                }

                if !daily.isEmpty {
                    Section(header: Text("AYAH OF THE DAY, EARLIER")) {
                        ForEach(Array(daily.enumerated()), id: \.element.dayLabel) { index, entry in
                            // Today's row IS the current ayah, not history - full brightness.
                            ayahRow(surah: entry.surah, ayah: entry.ayah,
                                    caption: entry.dayLabel, timestamp: nil, dimmed: index != 0)
                        }
                    }
                }

                if !searches.isEmpty {
                    Section(header: Text("RECENT SEARCHES")) {
                        ForEach(searches, id: \.self) { term in
                            Button {
                                settings.hapticFeedback()
                                QuranSearchHandoff.shared.request(term)
                                dismiss()
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(term)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Spacer(minLength: 0)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func ayahRow(surah: Surah, ayah: Ayah, caption: String?, timestamp: Date?, dimmed: Bool = true) -> some View {
        Button {
            settings.hapticFeedback()
            onOpen(surah.id, ayah.id)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                if let caption {
                    Text(caption)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // The "when" sits over SurahAyahRow's 65 pt number-pill column, the summary
                // expansions' grammar.
                if let timestamp {
                    Text(formatCompactHistoryTimestamp(timestamp))
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(width: 65)
                }

                SurahAyahRow(surah: surah, ayah: ayah)
                    .equatable()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .opacity(dimmed ? 0.75 : 1)
        }
        .buttonStyle(.plain)
    }

    private func surahRow(surah: Surah, reciter: String, timestamp: Date) -> some View {
        Button {
            settings.hapticFeedback()
            onOpen(surah.id, nil)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatCompactHistoryTimestamp(timestamp))
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(surah.id) - \(surah.displayName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)

                Text(reciter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .opacity(0.75)
        }
        .buttonStyle(.plain)
    }
}
#endif
