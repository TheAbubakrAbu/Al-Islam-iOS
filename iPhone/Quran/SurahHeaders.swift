import SwiftUI

struct SurahsHeader: View {
    @ObservedObject var quranData = QuranData.shared

    @State private var randomSurah: Surah?

    var headerText: String

    init(text: String = "SURAHS") {
        headerText = text
    }

    var body: some View {
        HStack {
            Text(headerText)

            #if os(iOS)
            Spacer()

            goToSurah
            // The count pill sits left of the shuffle, the section-header family's order.
            CountPill(count: quranData.quran.count)
            randomSurahLink
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
        } label: {
            Image(systemName: "shuffle.circle")
                .padding(4)
                .conditionalGlassEffect()
        }
    }
    
    private var goToSurah: some View {
        EmptyView()
    }
    #endif
}

struct JuzHeader: View {
    @ObservedObject var quranData = QuranData.shared
    #if os(iOS)
    @ObservedObject var settings = Settings.shared
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
            Text("JUZ \(juz.id)")
                .lineLimit(1)

            Text("- \(juz.nameTransliteration.uppercased()) - \(juz.nameArabic)")
                .font(.footnote)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            #if os(iOS)
            Spacer()

            surahCountBadge
            infoButton
            // Khatm's Juz grouping is about tracking a full read-through, so the random "shuffle to a surah"
            // jump doesn't belong there - hide it in khatm mode.
            if settings.quranSortMode != .khatm {
                randomSurahLink
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
        return """
        \(juz.nameArabic)

        Ayahs: \(stats.ayahCount)
        Pages: \(stats.pageCount)
        Words: \(stats.wordCount)
        Letters: \(stats.letterCount)

        Starts: Surah \(juz.startSurah):\(juz.startAyah)
        Ends: Surah \(juz.endSurah):\(juz.endAyah)
        """
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
        .confirmationDialog(
            "Juz \(juz.id) - \(juz.nameTransliteration)",
            isPresented: $showInfo,
            titleVisibility: .visible
        ) {
            Button("Copy Info") {
                settings.hapticFeedback()
                UIPasteboard.general.string = "Juz \(juz.id) - \(juz.nameTransliteration)\n\(infoMessage)"
            }
            Button("OK") {}
        } message: {
            Text(infoMessage)
        }
    }

    private var randomSurahLink: some View {
        NavigationLink {
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
        } label: {
            Image(systemName: "shuffle.circle")
                .padding(4)
                .conditionalGlassEffect()
        }
    }
    #endif
}

struct PageHeader: View {
    let page: Int

    var body: some View {
        HStack {
            Text("PAGE \(page)")
                .lineLimit(1)

            Spacer()
        }
    }
}

struct SurahSectionHeader: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranPlayer = QuranPlayer.shared

    var surah: Surah
    var compact: Bool = false

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
        compact ? .caption : .subheadline
        #else
        .title3
        #endif
    }

    /// On iOS the favorite star is a touch larger than the revelation emoji; on watchOS the two side icons
    /// match exactly (same size as `symbolFont`) so they look balanced.
    private var starFont: Font {
        #if os(iOS)
        compact ? .subheadline : .body
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
        Text("\(surah.ayahCountLabel(for: settings.displayQiraahForArabic)) - \(surah.pageCountLabel)")
            .textCase(.uppercase)
            .font(compact ? .caption.weight(.semibold) : .subheadline)
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

            if quranPlayer.isLoading {
                quranPlayer.isLoading = false
                quranPlayer.player?.pause()
            } else if quranPlayer.isPlaying {
                quranPlayer.pause(saveInfo: false)
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
                settings.toggleSurahFavorite(surah: surah.id)
            }
    }
}

struct HeaderRow: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranPlayer = QuranPlayer.shared

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
                .padding(.vertical, 4)
            }
        }
        .padding(.top, -8)
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
            return cleanedText.map { "\($0) " }.joined()
        }
        return cleanedText
    }

    /// "Remove Arabic dots" forces the system face, and so does picking "Basic" in the font picker. In both cases
    /// the bismillah / ta'awwudh is really system text, so it should stay rounded like the rest of the UI.
    private var usesCustomArabicFace: Bool {
        !settings.removeArabicDots && settings.quranUsesCustomArabicFace
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
