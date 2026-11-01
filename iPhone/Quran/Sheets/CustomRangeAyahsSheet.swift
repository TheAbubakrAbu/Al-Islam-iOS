#if os(iOS)
import SwiftUI

/// Every ayah of the custom range that is playing, in order, with the one being recited marked and
/// kept in view (Abu, 2026-10-19: "a custom range view ... just shows all the ayahs that are
/// playing"). The Now Playing bar opens it: a tap on its range line, or "Range Ayahs" in its
/// long-press menu. A tap on a row moves the recitation to that ayah (`QuranPlayer.customRangeJump`).
///
/// Reads the player's published snapshot (`NowPlayingState`), so the header's pass counts and the
/// marked row follow the recitation live. The rows draw the ayah as the range sheet's preview does
/// (the Quran face at the title size, then the translations the reader shows), not as a reader row:
/// this is a list to scan, and the reader's rows carry word cards, tajweed and pins it has no use for.
/// A range that runs on into later surahs (a juz, 2026-10-31) lists every surah's ayahs, each row
/// named with its surah. What the rows show under the Arabic is the toolbar menu's (the reader's own
/// transliteration and translation switches), the Qiraah Comparison sheet's pattern.
struct CustomRangeAyahsSheet: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var nowPlaying = QuranPlayer.shared.nowPlaying
    private let quranPlayer = QuranPlayer.shared
    @Environment(\.appearance) private var appearance

    /// The playing range: its first surah and both of its ends.
    private struct PlayingRange {
        let surah: Surah
        let startSurah: Int
        let start: Int
        let endSurah: Int
        let end: Int
        var crossesSurahs: Bool { startSurah != endSurah }
    }

    /// One ayah of the range with its surah; the id is what the list scrolls by.
    private struct Entry: Identifiable {
        let surah: Surah
        let ayah: Ayah
        var id: String { "\(surah.id):\(ayah.id)" }
    }

    var body: some View {
        SheetNavigationContainer {
            content
                .navigationTitle("Now Playing")
                .navigationBarTitleDisplayMode(.inline)
                .sheetDismissToolbar()
                .toolbar {
                    ToolbarItem(placement: .primaryAction) { optionsMenu }
                }
        }
        // Full height first: the list is the point, and the half height showed two ayahs of it.
        .smallMediumSheetPresentation(startLarge: true)
        .onChange(of: quranDisplay.showTransliteration) { _ in settings.hapticFeedback() }
        .onChange(of: quranDisplay.showEnglishSaheeh) { _ in settings.hapticFeedback() }
        .onChange(of: quranDisplay.showEnglishMustafa) { _ in settings.hapticFeedback() }
    }

    /// The playing range, or nil once it has ended or been replaced by other playback.
    private var range: PlayingRange? {
        guard nowPlaying.isPlayingCustomRange,
              let start = nowPlaying.customRangeStartAyah,
              let end = nowPlaying.customRangeEndAyah
        else { return nil }
        // The range's own first surah, not the one being recited: a range that runs into the next
        // surah would otherwise shift under the list as the recitation crosses.
        let startSurah = nowPlaying.customRangeStartSurahNumber ?? nowPlaying.currentSurahNumber ?? 0
        guard let surah = quranPlayer.quranData.quran.first(where: { $0.id == startSurah }) else { return nil }
        return PlayingRange(surah: surah, startSurah: startSurah, start: start,
                            endSurah: nowPlaying.customRangeEndSurahNumber ?? startSurah, end: end)
    }

    /// Every ayah of the range in order, across its surahs, clamped to the active qiraah.
    private func entries(of range: PlayingRange) -> [Entry] {
        let qiraah = settings.displayQiraahForArabic
        var items: [Entry] = []
        for number in range.startSurah...max(range.startSurah, range.endSurah) {
            guard let surah = number == range.startSurah ? range.surah : quranPlayer.quranData.quran.first(where: { $0.id == number })
            else { continue }
            let from = number == range.startSurah ? range.start : 1
            let to = number == range.endSurah ? range.end : Int.max
            for ayah in surah.ayahs where ayah.id >= from && ayah.id <= to && ayah.existsInQiraah(qiraah, surahID: surah.id) {
                items.append(Entry(surah: surah, ayah: ayah))
            }
        }
        return items
    }

    @ViewBuilder
    private var content: some View {
        if let range {
            rangeList(range)
        } else {
            // The range ended, or something else started playing, while the sheet was up.
            VStack(spacing: 8) {
                Image(systemName: "speaker.slash")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Nothing Is Playing")
                    .font(.headline)
                Text("Play a custom range from an ayah's menu to see its ayahs here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// The id of the row being recited, in `Entry.id`'s form.
    private var currentID: String? {
        guard let surah = nowPlaying.currentSurahNumber, let ayah = nowPlaying.currentAyahNumber else { return nil }
        return "\(surah):\(ayah)"
    }

    private func rangeList(_ range: PlayingRange) -> some View {
        let qiraah = settings.displayQiraahForArabic
        let entries = entries(of: range)
        let current = currentID
        let accent = settings.accentColor.color

        return ScrollViewReader { proxy in
            List {
                Section {
                    header(range, count: entries.count)
                }

                Section {
                    ForEach(entries) { entry in
                        let isCurrent = entry.id == current
                        ayahRow(entry, named: range.crossesSurahs, qiraah: qiraah, isCurrent: isCurrent, accent: accent)
                            // The reader's "being recited" wash, on the ROW so it fills the cell
                            // (see `rowWash`); nil paints the plain themed cell.
                            .rowWash(isCurrent ? ReaderRowTint.accent(accent, defaultView: appearance.defaultView) : nil)
                            .id(entry.id)
                    }
                } header: {
                    SectionIconHeader(spanTitle(range), icon: "list.number")
                }
            }
            .applyConditionalListStyle(disableNowPlayingInset: true)
            .onAppear {
                if let current { proxy.scrollTo(current, anchor: .center) }
            }
            // Follows the recitation, like the readers do.
            .onChange(of: current) { id in
                guard let id else { return }
                withAnimation(.easeInOut) { proxy.scrollTo(id, anchor: .center) }
            }
        }
    }

    /// "Ayahs 75–98", or "18:75 – 19:98" for a range that runs into another surah.
    private func spanTitle(_ range: PlayingRange) -> String {
        if range.crossesSurahs {
            return "\(range.startSurah):\(range.start) \u{2013} \(range.endSurah):\(range.end)"
        }
        return String(localized: "Ayahs \(range.start)\u{2013}\(range.end)")
    }

    /// The surah (both surahs, across a boundary), the reciter and the live pass counts: what the
    /// bar's range line says, with room.
    private func header(_ range: PlayingRange, count: Int) -> some View {
        let endSurah = range.crossesSurahs ? quranPlayer.quranData.quran.first(where: { $0.id == range.endSurah }) : nil
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                // The Arabic interface names the surah once, in Arabic.
                if !AppLanguage.isArabicScript {
                    Text(endSurah.map { "\(range.surah.nameTransliteration) \u{2013} \($0.nameTransliteration)" } ?? range.surah.nameTransliteration)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Spacer(minLength: 8)
                }

                Text(endSurah.map { "\(range.surah.nameArabic) \u{2013} \($0.nameArabic)" } ?? range.surah.nameArabic)
                    .font(Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize))
                    .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if let reciter = nowPlaying.nowPlayingReciter {
                Label(reciter, systemImage: "person.wave.2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(passSummary(count: count))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    /// "10 ayahs · Each ayah ×2 · Section 1/∞ · Play 3 of 40": only the parts that apply.
    private func passSummary(count: Int) -> String {
        var parts = [count == 1 ? String(localized: "\(count) ayah") : String(localized: "\(count) ayahs")]
        let perAyah = max(1, nowPlaying.customRangeRepeatPerAyah)
        if perAyah > 1 {
            parts.append(String(localized: "Each ayah \u{00D7}\(perAyah)"))
        }
        let section = nowPlaying.customRangeRepeatSection
        let sectionIndex = nowPlaying.customRangeRepeatSectionIndex ?? 1
        if section == QuranPlayer.infiniteRepeat {
            parts.append(String(localized: "Section \(sectionIndex)/\u{221E}"))
        } else if section > 1 {
            parts.append(String(localized: "Section \(sectionIndex)/\(section)"))
        }
        if let total = nowPlaying.customRangeTotalItems, total > 1 {
            parts.append(String(localized: "Play \(nowPlaying.customRangeCurrentIndex ?? 1) of \(total)"))
        }
        return parts.joined(separator: " \u{00B7} ")
    }

    /// "Ayah 5 · Page 293 (1/12)", or "Al-Kahf 18:5 · Page ..." once the range spans surahs.
    private func ayahLabel(_ entry: Entry, named: Bool) -> String {
        let name = named
            ? "\(entry.surah.displayName) \(entry.surah.id):\(entry.ayah.id)"
            : String(localized: "Ayah \(entry.ayah.id)")
        if let page = entry.ayah.page {
            return "\(name) \u{00B7} \(mushafPageDisplayLabel(forAbsolutePage: page, in: entry.surah))"
        }
        return name
    }

    /// The rows' text under the Arabic: the reader's own switches, in the Qiraah Comparison sheet's
    /// toolbar menu pattern (Abu, 2026-10-31: "see if we can add that anywhere else").
    private var optionsMenu: some View {
        Menu {
            // `.automatic`, not the app's padded switch: inside a menu that style draws double-height
            // rows with stray checkmarks (see the memory note on menu toggles).
            Toggle(isOn: $quranDisplay.showTransliteration) {
                Label("Show Transliteration", systemImage: "character.textbox")
            }
            .toggleStyle(.automatic)
            Toggle(isOn: $quranDisplay.showEnglishSaheeh) {
                Label("Saheeh International", systemImage: "text.book.closed")
            }
            .toggleStyle(.automatic)
            Toggle(isOn: $quranDisplay.showEnglishMustafa) {
                Label("Clear Quran (Mustafa Khattab)", systemImage: "text.book.closed")
            }
            .toggleStyle(.automatic)
        } label: {
            Image(systemName: "slider.horizontal.3")
        }
        .fixedMenuOrder()
        .tint(settings.accentColor.color)
        .accessibilityLabel("Text options")
    }

    private func ayahRow(_ entry: Entry, named: Bool, qiraah: String?, isCurrent: Bool, accent: Color) -> some View {
        let surah = entry.surah
        let ayah = entry.ayah
        return Button {
            settings.hapticFeedback()
            quranPlayer.customRangeJump(toSurah: surah.id, ayah: ayah.id)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if isCurrent {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(accent)
                            .accessibilityLabel("Now playing")
                    }

                    Text(ayahLabel(entry, named: named))
                        .font(.caption2.weight(.medium))
                        .foregroundColor(isCurrent ? accent : Color(.tertiaryLabel))

                    Spacer(minLength: 0)

                    // Which play of this ayah is on, when each ayah repeats.
                    if isCurrent, nowPlaying.customRangeRepeatPerAyah > 1 {
                        Text("\(nowPlaying.customRangeCurrentRepeatWithinAyah ?? 1)/\(nowPlaying.customRangeRepeatPerAyah)")
                            .font(.caption2.monospacedDigit().weight(.semibold))
                            .foregroundColor(accent)
                            .accessibilityLabel("Play \(nowPlaying.customRangeCurrentRepeatWithinAyah ?? 1) of \(nowPlaying.customRangeRepeatPerAyah)")
                    }
                }

                Text(ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: qiraah))
                    .font(Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .title3).pointSize))
                    .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.primary)
                    // Its ideal height, never a line: inside a List row's Button the Text was
                    // sometimes offered one line and cut a long ayah off with an ellipsis.
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    // Arabic keeps the right edge: in the Arabic interface `.trailing` is the left.
                    .environment(\.layoutDirection, .leftToRight)

                if settings.showTransliteration {
                    Text(ayah.textTransliteration)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .leftToRightContent()
                }

                if settings.showEnglishSaheeh {
                    Text(ayah.textEnglishSaheeh)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .leftToRightContent()
                }

                if settings.showEnglishMustafa {
                    Text(ayah.textEnglishMustafa)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .leftToRightContent()
                }
            }
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Plays the range from this ayah")
    }
}

#if DEBUG
#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        CustomRangeAyahsSheet()
            .onAppear {
                let surah = AlIslamPreviewData.quranData.quran.first(where: { $0.id == 18 }) ?? AlIslamPreviewData.surah
                QuranPlayer.shared.nowPlaying.previewSeed { snapshot in
                    snapshot.isPlaying = true
                    snapshot.isPaused = false
                    snapshot.isLoading = false
                    snapshot.currentSurahNumber = surah.id
                    snapshot.currentAyahNumber = 3
                    snapshot.isPlayingSurah = false
                    snapshot.isPlayingCustomRange = true
                    snapshot.customRangeStartAyah = 1
                    snapshot.customRangeEndAyah = 6
                    snapshot.customRangeStartSurahNumber = surah.id
                    snapshot.customRangeEndSurahNumber = surah.id
                    snapshot.customRangeRepeatPerAyah = 2
                    snapshot.customRangeRepeatSection = 3
                    snapshot.customRangeCurrentIndex = 5
                    snapshot.customRangeTotalItems = 36
                    snapshot.customRangeCurrentRepeatWithinAyah = 1
                    snapshot.customRangeRepeatSectionIndex = 1
                    snapshot.nowPlayingTitle = "\(surah.nameTransliteration) \(surah.id):3 (1\u{2013}6) (Ayah 1/2) (Sec 1/3)"
                    snapshot.nowPlayingReciter = "Mishary Rashid Alafasy"
                }
            }
    }
}
#endif
#endif
