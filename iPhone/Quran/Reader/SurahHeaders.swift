import SwiftUI

struct SurahsHeader: View {
    @ObservedObject var quranData = QuranData.shared

    @State private var randomSurah: Surah?

    var headerText: String
    /// The glyph leading the title; REVELATION ORDER passes its own.
    var icon: String

    init(text: String = String(localized: "SURAHS"), icon: String = "book.fill") {
        headerText = text
        self.icon = icon
    }

    var body: some View {
        HStack {
            SectionIconHeader(headerText, icon: icon)

            #if os(iOS)
            Spacer()

            goToSurah
            // The count pill sits left of the shuffle, the section-header family's order. Simple Mode
            // drops the count (CountPill hides itself) and the shuffle; Random Surah moves to the
            // tab's More menu.
            CountPill(count: quranData.quran.count)
            randomSurahLink
                .hiddenInSimple(.surahShuffle)
            #endif
        }
        .onAppear {
            if randomSurah == nil {
                randomSurah = quranData.quran.randomElement()
            }
        }
    }

    #if os(iOS)
    private var randomSurahLink: some View {
        NavigationLink {
            LazyDestination {
                Group {
                    if let randomSurah {
                        SurahView(surah: randomSurah)
                    } else {
                        Text("No surah found!")
                    }
                }
                .onDisappear {
                    randomSurah = quranData.quran.randomElement()
                }
            }
        } label: {
            Image(systemName: "shuffle.circle")
                .padding(4)
                .conditionalGlassEffect()
        }
        // VoiceOver read the symbol's own name, "Shuffle In A Circle".
        .accessibilityLabel("Random Surah")
    }
    
    private var goToSurah: some View {
        EmptyView()
    }
    #endif
}

struct JuzHeader: View {
    @ObservedObject var quranData = QuranData.shared
    #if os(iOS)
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    #endif

    let juz: Juz

    @State private var randomSurah: Surah?
    #if os(iOS)
    @State private var showInfo = false
    #endif

    private var surahCount: Int {
        quranData.surahs(inJuz: juz.id).count
    }

    var body: some View {
        HStack {
            SectionIconHeader(String(localized: "JUZ \(juz.id)"), icon: "square.grid.3x3.fill")
                .lineLimit(1)

            // The Arabic interface names the juz once, in Arabic.
            Group {
                if AppLanguage.isArabicScript {
                    Text(verbatim: "- \(juz.displayName)")
                } else {
                    Text("- \(juz.nameTransliteration.uppercased()) - \(Settings.shared.cleanedQuranArabic(juz.nameArabic))")
                }
            }
            .font(.footnote)
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            #if os(iOS)
            Spacer()

            // Simple Mode drops the count and the shuffle, as `SurahsHeader` does; the info button stays.
            surahCountBadge
            infoButton
            // Khatm's Juz grouping is about tracking a full read-through, so the random "shuffle to a surah"
            // jump doesn't belong there - hide it in khatm mode.
            if settings.quranSortMode != .khatm {
                randomSurahLink
                    .hiddenInSimple(.sectionShuffles)
            }
            #endif
        }
        .onAppear {
            if randomSurah == nil {
                randomSurah = randomSurahInJuz
            }
        }
    }

    private var surahsInRange: [Surah] {
        quranData.quran.filter { $0.id >= juz.startSurah && $0.id <= juz.endSurah }
    }

    private var randomSurahInJuz: Surah? {
        surahsInRange.randomElement()
    }

    #if os(iOS)
    private var infoMessage: String {
        let stats = quranData.juzStats(for: juz)
        return String(localized: """
        \(Settings.shared.cleanedQuranArabic(juz.nameArabic))

        Ayahs: \(stats.ayahCount)
        Pages: \(stats.pageCount)
        Words: \(stats.wordCount)
        Letters: \(stats.letterCount)

        Starts: Surah \(juz.startSurah):\(juz.startAyah)
        Ends: Surah \(juz.endSurah):\(juz.endAyah)
        """)
    }

    private var surahCountBadge: some View {
        Text("\(surahCount)")
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(settings.accentColor.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .conditionalGlassEffect()
            .accessibilityLabel("\(surahCount) surahs")
            .hiddenInSimple(.sectionCounts)
    }

    private var infoButton: some View {
        Button {
            settings.hapticFeedback()
            showInfo = true
        } label: {
            Image(systemName: "info.circle")
                .padding(4)
                .conditionalGlassEffect()
        }
        .buttonStyle(.plain)
        .foregroundStyle(settings.accentColor.color)
        // Anchored to the info button itself, so the dialog pops from where the tap happened.
        // In Arabic the message's first line already names the juz in Arabic: the title is the number.
        .confirmationDialog(
            AppLanguage.isArabicScript ? String(localized: "Juz \(juz.id)") : String(localized: "Juz \(juz.id) - \(juz.nameTransliteration)"),
            isPresented: $showInfo,
            titleVisibility: .visible
        ) {
            Button("Copy Info") {
                settings.hapticFeedback()
                UIPasteboard.general.string = AppLanguage.isArabicScript
                    ? String(localized: "Juz \(juz.id)") + "\n" + infoMessage
                    : String(localized: "Juz \(juz.id) - \(juz.nameTransliteration)\n\(infoMessage)")
            }
            Button("OK") {}
        } message: {
            Text(infoMessage)
        }
    }

    private var randomSurahLink: some View {
        NavigationLink {
            LazyDestination {
                Group {
                    if let randomSurah {
                        SurahView(surah: randomSurah)
                    } else {
                        Text("No surah found in Juz \(juz.id).")
                    }
                }
                .onDisappear {
                    randomSurah = randomSurahInJuz
                }
            }
        } label: {
            Image(systemName: "shuffle.circle")
                .padding(4)
                .conditionalGlassEffect()
        }
        // VoiceOver read the symbol's own name, "Shuffle In A Circle".
        .accessibilityLabel("Random Surah")
    }
    #endif
}

struct PageHeader: View {
    let page: Int

    var body: some View {
        HStack {
            SectionIconHeader(String(localized: "PAGE \(page)"), icon: "doc.text.fill")
                .lineLimit(1)

            Spacer()
        }
    }
}

struct SurahSectionHeader: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranContent = QuranContent.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    // Player state is only READ on watchOS (the wrist playback button). Observing it on iOS re-rendered
    // this header on every play/pause/ayah-advance publish for a body that never looks at it.
    #if os(watchOS)
    @ObservedObject var quranPlayer = QuranPlayer.shared
    #endif

    var surah: Surah
    var compact: Bool = false
    /// One step smaller again than `compact` - the page footer pill's row (user rule: caption2 there).
    var micro: Bool = false

    var body: some View {
        #if os(watchOS)
        // watchOS has too little width to fit the emoji, ayah/page summary, play, and star on one line,
        // so the controls get their own row beneath the summary. The emoji + summary sit together as one
        // centered group (no stretched gap between them), and the play/star row sits tight just below.
        VStack(spacing: 3) {
            HStack(spacing: 5) {
                revelationSymbol
                ayahSummary
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 22) {
                watchPlaybackButton
                favoriteToggle
            }
        }
        .padding(.bottom, 2)
        #else
        // Revelation symbol on the left, ayah/page info centered, favorite star on the right.
        // The symbol and star share the same size so the centered text sits exactly in the middle.
        ZStack {
            ayahSummary
                .padding(.horizontal, 34)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                revelationSymbol

                Spacer()

                favoriteToggle
            }
        }
        #endif
    }

    private var symbolFont: Font {
        #if os(iOS)
        // Micro sizes are absolute, a step under caption2/caption: the strip has to sit comfortably
        // inside its hairline pill (user rule: "make the text and the emoji and the star a little
        // smaller to fit comfortably inside").
        micro ? .system(size: 9) : (compact ? .caption : .subheadline)
        #else
        .title3
        #endif
    }

    /// On iOS the favorite star is a touch larger than the revelation emoji; on watchOS the two side icons
    /// match exactly (same size as `symbolFont`) so they look balanced.
    private var starFont: Font {
        #if os(iOS)
        micro ? .system(size: 11) : (compact ? .subheadline : .body)
        #else
        .title3
        #endif
    }

    private var revelationSymbol: some View {
        Text(surah.type == "makkan" ? "🕋" : "🕌")
            .font(symbolFont)
            .lineLimit(1)
    }

    private var ayahSummary: some View {
        // Compact (the mushaf page header): .subheadline with the smaller side icons - the page reader
        // wants its chrome tight, not tiny.
        Text("\(surah.ayahCountLabel(for: settings.displayQiraahForArabic)) - \(surah.pageCountLabel)")
            .textCase(.uppercase)
            .font(micro ? .system(size: 10, weight: .semibold) : .subheadline)
            .lineLimit(1)
            .minimumScaleFactor(compact ? 0.6 : 0.25)
    }
    #if os(watchOS)
    private var watchPlaybackButton: some View {
        Group {
            if quranPlayer.isLoading {
                RotatingGearView()
                    .transition(.opacity)
            } else if quranPlayer.isPlaying {
                Image(systemName: "pause.fill")
                    .foregroundColor(settings.accentColor.color)
                    .font(.title3)
                    .transition(.opacity)
            } else {
                Image(systemName: "play.fill")
                    .foregroundColor(settings.accentColor.color)
                    .font(.title3)
                    .transition(.opacity)
            }
        }
        .onTapGesture {
            settings.hapticFeedback()

            // Playing comes first: the gear also shows while a recitation waits on the network mid-ayah
            // (2026-10-11, `QuranPlayer.observeBuffering`), and a bare `player.pause()` there left
            // `isPlaying` true over silence. The cancel path is for a first load only.
            if quranPlayer.isPlaying {
                quranPlayer.pause(saveInfo: false)
            } else if quranPlayer.isLoading {
                quranPlayer.isLoading = false
                quranPlayer.player?.pause()
            } else {
                quranPlayer.playSurah(surahNumber: surah.id, surahName: surah.nameTransliteration)
            }
        }
    }
    #endif

    private var favoriteToggle: some View {
        Image(systemName: settings.isSurahFavorite(surah: surah.id) ? "star.fill" : "star")
            .foregroundColor(settings.accentColor.color)
            .font(starFont)
            .onTapGesture {
                settings.hapticFeedback()
                settings.toggleSurahFavoriteOrConfirm(surah: surah.id)
            }
    }
}

struct HeaderRow: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared
    @ObservedObject private var systemSettings = SystemSettings.shared
    /// Actions only (`playBismillah`): observing the player re-ran this row's three highlighted
    /// snippets on every ayah advance while a surah played from its start (Phase 10.4).
    private var quranPlayer: QuranPlayer { .shared }

    let arabicText: String
    let englishTransliteration: String
    let englishTranslation: String

    @State private var ayahBeginnerMode = false

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            HighlightedSnippet(
                source: displayArabicText,
                term: "",
                font: arabicFont,
                accent: settings.accentColor.color,
                fg: settings.accentColor.color,
                beginnerMode: settings.beginnerMode || ayahBeginnerMode,
                highlightAllahNames: settings.highlightAllahNames
            )
            .arabicFontDesign(custom: usesCustomArabicFace)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 8)

            if settings.showTransliteration, settings.isHafsDisplay {
                HighlightedSnippet(
                    source: englishTransliteration,
                    term: "",
                    font: .system(size: settings.englishFontSize),
                    accent: settings.accentColor.color,
                    fg: settings.accentColor.color,
                    highlightAllahNames: settings.highlightAllahNames
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .leftToRightContent()
                .padding(.vertical, 4)
            }

            if (settings.showEnglishSaheeh || settings.showEnglishMustafa), settings.isHafsDisplay {
                HighlightedSnippet(
                    source: englishTranslation,
                    term: "",
                    font: .system(size: settings.englishFontSize),
                    accent: settings.accentColor.color,
                    fg: settings.accentColor.color,
                    highlightAllahNames: settings.highlightAllahNames
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .leftToRightContent()
                .padding(.vertical, 4)
            }
        }
        // Was -8, which pressed the Arabic's tall marks against the card's top edge - the Quran line
        // read as chopped (user report). -2 keeps the row snug without starving the ink of air.
        .padding(.top, -2)
        #if os(iOS)
        .contextMenu {
            Text("Ayah Actions")
                .foregroundStyle(.secondary)

            if !settings.beginnerMode {
                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        ayahBeginnerMode.toggle()
                    }
                } label: {
                    Label("Beginner Mode", systemImage: ayahBeginnerMode ? "textformat.size.larger.ar" : "textformat.size.ar")
                }
            }

            if englishTranslation.contains("name"), settings.isHafsDisplay {
                Button {
                    settings.hapticFeedback()
                    quranPlayer.playBismillah()
                } label: {
                    Label("Play Ayah", systemImage: "play.circle")
                }
            }
        }
        #endif
    }

    private var displayArabicText: String {
        var cleanedText = settings.cleanArabicText ? arabicText.removingArabicDiacriticsAndSigns : arabicText
        if settings.removeArabicDots {
            cleanedText = cleanedText.removingArabicDots
        }
        if settings.beginnerMode || ayahBeginnerMode {
            return cleanedText.beginnerSpaced
        }
        return cleanedText
    }

    /// Picking "Basic" in the font picker means system text, so the bismillah / ta'awwudh stays rounded like
    /// the rest of the UI. (Dots-removed text no longer forces the system face: the bundled ttfs carry real
    /// dotless skeleton glyphs now - `Scripts/patch_dotless_glyphs.py`.)
    private var usesCustomArabicFace: Bool {
        settings.quranUsesCustomArabicFace
    }

    private var arabicFont: Font {
        usesCustomArabicFace
            ? Font.arabic(settings.fontArabic, size: settings.fontArabicSize)
            : .system(size: settings.fontArabicSize)
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        List {
            SurahSectionHeader(surah: AlIslamPreviewData.surah)
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
    }
}
