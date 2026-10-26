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
struct CustomRangeAyahsSheet: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    @ObservedObject private var nowPlaying = QuranPlayer.shared.nowPlaying
    private let quranPlayer = QuranPlayer.shared
    @Environment(\.appearance) private var appearance

    var body: some View {
        SheetNavigationContainer {
            content
                .navigationTitle("Now Playing")
                .navigationBarTitleDisplayMode(.inline)
                .sheetDismissToolbar()
        }
        // Full height first: the list is the point, and the half height showed two ayahs of it.
        .smallMediumSheetPresentation(startLarge: true)
    }

    /// The playing range, or nil once it has ended or been replaced by other playback.
    private var range: (surah: Surah, start: Int, end: Int)? {
        guard nowPlaying.isPlayingCustomRange,
              let surahNumber = nowPlaying.currentSurahNumber,
              let start = nowPlaying.customRangeStartAyah,
              let end = nowPlaying.customRangeEndAyah,
              let surah = quranPlayer.quranData.quran.first(where: { $0.id == surahNumber })
        else { return nil }
        return (surah, start, end)
    }

    @ViewBuilder
    private var content: some View {
        if let range {
            rangeList(surah: range.surah, start: range.start, end: range.end)
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

    private func rangeList(surah: Surah, start: Int, end: Int) -> some View {
        let qiraah = settings.displayQiraahForArabic
        let ayahs = surah.ayahs.filter {
            $0.id >= start && $0.id <= end && $0.existsInQiraah(qiraah, surahID: surah.id)
        }
        let current = nowPlaying.currentAyahNumber
        let accent = settings.accentColor.color

        return ScrollViewReader { proxy in
            List {
                Section {
                    header(surah: surah, start: start, end: end, count: ayahs.count)
                }

                Section {
                    ForEach(ayahs) { ayah in
                        let isCurrent = ayah.id == current
                        ayahRow(ayah, surah: surah, qiraah: qiraah, isCurrent: isCurrent, accent: accent)
                            // The reader's "being recited" wash, on the ROW so it fills the cell
                            // (see `rowWash`); nil paints the plain themed cell.
                            .rowWash(isCurrent ? ReaderRowTint.accent(accent, defaultView: appearance.defaultView) : nil)
                            .id(ayah.id)
                    }
                } header: {
                    SectionIconHeader(String(localized: "Ayahs \(start)\u{2013}\(end)"), icon: "list.number")
                }
            }
            .applyConditionalListStyle(disableNowPlayingInset: true)
            .onAppear {
                if let current { proxy.scrollTo(current, anchor: .center) }
            }
            // Follows the recitation, like the readers do.
            .onChange(of: current) { ayah in
                guard let ayah else { return }
                withAnimation(.easeInOut) { proxy.scrollTo(ayah, anchor: .center) }
            }
        }
    }

    /// The surah, the reciter and the live pass counts: what the bar's range line says, with room.
    private func header(surah: Surah, start: Int, end: Int, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                // The Arabic interface names the surah once, in Arabic.
                if !AppLanguage.isArabic {
                    Text(surah.nameTransliteration)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer(minLength: 8)
                }

                Text(surah.nameArabic)
                    .font(Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .headline).pointSize))
                    .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                    .foregroundColor(.primary)
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

    private func ayahLabel(_ ayah: Ayah, surah: Surah) -> String {
        if let page = ayah.page {
            return String(localized: "Ayah \(ayah.id) \u{00B7} \(mushafPageDisplayLabel(forAbsolutePage: page, in: surah))")
        }
        return String(localized: "Ayah \(ayah.id)")
    }

    private func ayahRow(_ ayah: Ayah, surah: Surah, qiraah: String?, isCurrent: Bool, accent: Color) -> some View {
        Button {
            settings.hapticFeedback()
            quranPlayer.customRangeJump(toAyah: ayah.id)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    if isCurrent {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(accent)
                            .accessibilityLabel("Now playing")
                    }

                    Text(ayahLabel(ayah, surah: surah))
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
                    snapshot.customRangeRepeatPerAyah = 2
                    snapshot.customRangeRepeatSection = 3
                    snapshot.customRangeCurrentIndex = 5
                    snapshot.customRangeTotalItems = 36
                    snapshot.customRangeCurrentRepeatWithinAyah = 1
                    snapshot.customRangeRepeatSectionIndex = 1
                    snapshot.nowPlayingTitle = "\(surah.nameTransliteration) \(surah.id):3 (Ayah 1/2) (Sec 1/3)"
                    snapshot.nowPlayingReciter = "Mishary Rashid Alafasy"
                }
            }
    }
}
#endif
#endif
