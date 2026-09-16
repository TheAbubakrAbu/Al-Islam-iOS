#if os(iOS)
import SwiftUI

// The Highlight Themes screen: Tilawa's Themes page in this app's list grammar. One switch washes
// every passage of the Quran in its meaning's colour; the legend says what the colours mean; a
// surah's passages can be lit one by one; and the lit themes from Browse by Theme are listed with
// a way to put each out. Reached from Quran Settings, from Browse by Theme, and from the settings
// search.

struct ThemeHighlightsView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared
    @ObservedObject private var themeHighlights = ThemeHighlights.shared

    /// Opens an ayah in the reader; nil where there is no reader to open (the Settings tab), in which
    /// case the row lands on the Quran tab through `AppNavigation`.
    var onOpenAyah: ((Int, Int) -> Void)? = nil

    /// The surah whose passages are listed: the last one read, until the picker says otherwise.
    @State private var surahID: Int = max(1, min(114, Settings.shared.lastReadSurah))

    private var sections: [SurahSection] { SurahSectionsStore.shared.sections(surah: surahID) }

    var body: some View {
        List {
            Group {
                introSection
                everyPassageSection
                legendSection
                passagesSection
                litThemesSection
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .compactListSectionSpacing()
        .navigationTitle("Highlight Themes")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var introSection: some View {
        Section {
            Text("Wash the ayahs of a passage or a theme in the color of what they speak about, in the list and page readers. A theme lights its own ayahs across the whole Quran; a passage lights one stretch of a surah.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// Tilawa's "Thematic Highlighting" switch: every passage of every surah at once.
    private var everyPassageSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { themeHighlights.allSectionsLit },
                set: { on in
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { themeHighlights.setAllSectionsLit(on) }
                }
            )) {
                HStack(spacing: 12) {
                    ThemeLegendChip(size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Highlight Every Passage")
                            .font(.subheadline.weight(.semibold))
                        Text(themeHighlights.allSectionsLit
                             ? "All \(SurahSectionsStore.shared.allSections().count) passages, each in its meaning's color"
                             : "Every surah, passage by passage, in the colors below")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(settings.accentColor.color)
        } footer: {
            if SurahSectionsStore.isBundled {
                Text("Passage outlines from Quranpedia. The colors follow the legend, matched from each passage's title, so a passage about the Day of Judgment reads orange wherever it falls.")
                    .font(.caption)
            }
        }
    }

    private var legendSection: some View {
        Section(header: Text("COLOR MEANINGS")) {
            ThemeColorLegend()
                .padding(.vertical, 4)
        }
    }

    /// The chosen surah's passages as toggles, the picker above them.
    @ViewBuilder
    private var passagesSection: some View {
        let sections = self.sections
        let litCount = themeHighlights.litSectionCount(inSurah: surahID)
        Section(header: passagesHeader(litCount: litCount)) {
            surahPicker

            if sections.isEmpty {
                Text("No passage outline for this surah.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(sections) { section in
                passageRow(section)
            }
        }
    }

    private func passagesHeader(litCount: Int) -> some View {
        HStack {
            Text("PASSAGES")
            Spacer()
            if themeHighlights.allSectionsLit {
                Text("All lit")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
            } else if litCount > 0 {
                Button("Put Out \(litCount)") {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        for section in sections where themeHighlights.isLit(section: section) {
                            themeHighlights.toggle(section: section)
                        }
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(settings.accentColor.color)
            }
        }
    }

    /// A menu of the 114 surahs, showing the chosen one's name and how many passages it has.
    private var surahPicker: some View {
        Picker(selection: $surahID.animation(.easeInOut)) {
            ForEach(quranData.quran) { surah in
                Text("\(surah.id). \(surah.nameTransliteration)").tag(surah.id)
            }
        } label: {
            HStack(spacing: 12) {
                AccentIconChip(systemImage: "book.closed.fill", size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Surah")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(quranData.surah(surahID)?.nameTransliteration ?? "Surah \(surahID)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .pickerStyle(.menu)
        .tint(settings.accentColor.color)
        .onChange(of: surahID) { _ in settings.hapticFeedback() }
    }

    /// One passage: its meaning's dot, the range, the title in both languages, the ayah count, and a
    /// check circle in the passage's colour. Tapping lights it; the whole-Quran switch makes the rows
    /// read-only (every one is lit) rather than pretending a single passage could be put out.
    private func passageRow(_ section: SurahSection) -> some View {
        let color = SurahSectionsStore.shared.color(for: section)
        let lit = themeHighlights.isLit(section: section)
        return Button {
            guard !themeHighlights.allSectionsLit else { return }
            settings.hapticFeedback()
            withAnimation(.easeInOut) { themeHighlights.toggle(section: section) }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(color.color)
                            .frame(width: 8, height: 8)
                        Text(section.rangeLabel.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text("· \(color.meaning)")
                            .font(.caption2)
                            .foregroundColor(color.color)
                            .lineLimit(1)
                    }

                    Text(section.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !section.titleArabic.isEmpty {
                        Text(section.titleArabic)
                            .font(.custom(settings.nonQuranArabicFontName, size: 14))
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(section.ayahCount) ayah\(section.ayahCount == 1 ? "" : "s")")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(lit ? color.color : .secondary)
                        .monospacedDigit()

                    ZStack {
                        Circle()
                            .fill(lit ? color.color.opacity(0.22) : Color.clear)
                        Circle()
                            .strokeBorder(lit ? color.color : color.color.opacity(0.35), lineWidth: 1)
                        if lit {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundColor(color.color)
                        }
                    }
                    .frame(width: 26, height: 26)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            // A lit passage carries its wash on the row itself, the way it will in the reader.
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(lit ? color.color.opacity(0.12) : Color.clear)
            )
            .padding(.horizontal, -8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                settings.hapticFeedback()
                openAyah(surah: section.surahID, ayah: section.ayahStart)
            } label: {
                Label("Read from Ayah \(section.ayahStart)", systemImage: "book")
            }
        }
    }

    /// The themes lit from Browse by Theme, each in its meaning's colour, and the door to more of them.
    @ViewBuilder
    private var litThemesSection: some View {
        Section(header: HStack {
            Text("THEMES")
            Spacer()
            if !themeHighlights.lit.isEmpty {
                Button("Put Out All") {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { themeHighlights.clear() }
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(settings.accentColor.color)
            }
        }) {
            ForEach(themeHighlights.lit) { theme in
                HStack(spacing: 10) {
                    Circle()
                        .fill(theme.color.color)
                        .frame(width: 12, height: 12)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(theme.name)
                            .font(.subheadline)
                        Text("\(theme.color.name.capitalized) · \(theme.color.meaning)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(theme.count)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { themeHighlights.remove(theme.id) }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Put out \(theme.name)")
                }
            }

            if ThematicTopicsStore.isBundled {
                NavigationLink(destination: LazyDestination {
                    ThemesBrowseView { surahID, ayahID in openAyah(surah: surahID, ayah: ayahID) }
                }) {
                    HStack(spacing: 12) {
                        AccentIconChip(systemImage: "square.grid.2x2.fill", size: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Browse by Theme")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text(themeHighlights.lit.isEmpty ? "Light a subject across the whole Quran" : "Light more subjects")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 3)
                }
                .tint(settings.accentColor.color)
            }
        }
    }

    private func openAyah(surah: Int, ayah: Int) {
        if let onOpenAyah {
            onOpenAyah(surah, ayah)
        } else {
            AppNavigation.shared.open(.ayah(surah, ayah))
        }
    }
}

/// The legend as one chip: the seven colours in a ring around a paintbrush, the row icon for
/// Highlight Themes wherever the app links to it.
struct ThemeLegendChip: View {
    var size: CGFloat = 29

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    AngularGradient(
                        colors: ThemeWashColor.allCases.map { $0.color.opacity(0.9) } + [ThemeWashColor.allCases[0].color.opacity(0.9)],
                        center: .center
                    )
                )
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}
#endif
