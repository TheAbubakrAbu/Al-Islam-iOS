import SwiftUI

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
