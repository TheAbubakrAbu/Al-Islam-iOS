import SwiftUI

struct ArabicView: View {
    @ObservedObject private var settings = Settings.shared
    @State private var searchText = ""
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @AppStorage("arabicFilterMode") private var filterModeRaw: String = ArabicFilterMode.normal.rawValue
    /// List of rows, or a grid of tiles - the same choice the 99 Names screen offers. Watch is always a list.

    private enum ArabicFilterMode: String, CaseIterable, Identifiable {
        case normal
        case similarity
        case heavyLight

        var id: String { rawValue }

        var title: String {
            switch self {
            case .normal: return "Normal Grouping"
            case .similarity: return "Similar Letters"
            case .heavyLight: return "Heavy vs Light"
            }
        }

        var icon: String {
            switch self {
            case .normal: return "square.grid.2x2"
            case .similarity: return "square.grid.3x3"
            case .heavyLight: return "circle.lefthalf.filled"
            }
        }
    }

    private var filterMode: ArabicFilterMode {
        get { ArabicFilterMode(rawValue: filterModeRaw) ?? .normal }
        set { filterModeRaw = newValue.rawValue }
    }

    private let similarityGroups: [[String]] = [
        ["ا", "و", "ي"], ["ب", "ت", "ث"], ["ج", "ح", "خ"], ["د", "ذ"],
        ["ر", "ز"], ["س", "ش"], ["ص", "ض"], ["ط", "ظ"], ["ع", "غ"],
        ["ف", "ق"], ["ك", "ل"], ["م", "ن"], ["ه", "ة"]
    ]

    /// What the letters in a similarity group have in COMMON - the shared skeleton, with the dots stripped off.
    /// The letters themselves are right there in the section, so listing them again in the header ("ب - ت - ث")
    /// said nothing; the dotless form is the actual point of the grouping. Where the letters don't merely differ
    /// by dots (kaaf/laam, meem/nuun), there's no shared skeleton to show, so the group falls back to naming them.
    private static let dotlessSkeletons: [String: String] = [
        "بتث": "\u{066E}",   // dotless beh
        "جحخ": "ح",          // the letters are haa + a dot above / below
        "دذ": "د",
        "رز": "ر",
        "سش": "س",
        "صض": "ص",
        "طظ": "ط",
        "عغ": "ع",
        "فق": "\u{066F}",    // dotless qaf
        "هة": "ه",           // taa marbuutah is a haa with two dots
    ]

    private static func similarityHeader(for group: [String]) -> String {
        dotlessSkeletons[group.joined()] ?? group.joined(separator: " - ")
    }

    private var filteredStandard: [LetterData] {
        guard !searchText.isEmpty else { return standardArabicLetters }
        let st = searchText.lowercased()
        return standardArabicLetters.filter { matchesSearch($0, st) }
    }

    private var filteredOther: [LetterData] {
        let allOtherLetters = otherArabicLetters + nonArabicArabicScriptLetters
        guard !searchText.isEmpty else { return allOtherLetters }
        let st = searchText.lowercased()
        return allOtherLetters.filter {
            $0.letter.lowercased().contains(st)
                || $0.name.lowercased().contains(st)
                || $0.transliteration.lowercased().contains(st)
        }
    }

    private func matchesSearch(_ letter: LetterData, _ st: String) -> Bool {
        var parts: [String] = [
            letter.letter.lowercased(),
            letter.name.lowercased(),
            letter.transliteration.lowercased()
        ]

        if let weight = letter.weight {
            switch weight {
            case .followsPrevious:
                parts += ["follows previous", "follows", "previous"]
            case .conditional:
                parts += ["conditional"]
            case .heavy:
                parts += ["heavy", "tafkhim", "istila", "isti'la"]
            case .light:
                parts += ["light", "tarqiq"]
            }
        }

        if let rule = letter.weightRule?.lowercased() {
            parts.append(rule)
        }

        return parts.contains { $0.contains(st) }
    }

    private var filteredStandardForMode: [LetterData] {
        switch filterMode {
        case .normal, .similarity:
            return filteredStandard
        case .heavyLight:
            return filteredStandard.filter { $0.weight != nil }
        }
    }

    var body: some View {
        List {
            Group {
                #if os(watchOS)
                arabicFontPickerSection
                #endif
                favoriteLettersSection
                mainLetterSections
                searchResultsSection
            }
            .themedListRowBackground()
        }
        #if os(watchOS)
        .searchable(text: $searchText.animation(.easeInOut))
        #else
        .background(gridNavigationLink)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                // No size slider here. It lives on the per-letter detail screen (`ArabicLetterView`), which is
                // where you are actually looking at a letter big enough to want it resized. The size it sets is
                // global (`settings.arabicLetterSizeIndex`), and these rows and tiles already honour it through
                // `arabicLetterDynamicTypeSize`, so the alphabet list still resizes - it just doesn't carry the
                // control, which was crowding the bottom bar alongside the font picker and the search field.
                // The font picker above the search bar is OFF for now (it was the row that vanished when
                // scrolling down) - uncomment to bring it back. The picker still lives in the letter
                // detail screens' ARABIC FONT section.
                // arabicFontPicker
                //     // Stays mounted while minimized (height 0) - inserting/removing glass renders black boxes.
                //     .collapsibleBarRow(barsCollapsed)

                HStack(spacing: 0) {
                    SearchBar(text: $searchText.animation(.easeInOut))

                    Menu {
                        Text("Arabic Sort")
                            .foregroundStyle(.secondary)

                        ForEach(ArabicFilterMode.allCases) { mode in
                            Button {
                                settings.hapticFeedback()
                                withAnimation(.easeInOut) {
                                    filterModeRaw = mode.rawValue
                                }
                            } label: {
                                Label(
                                    mode.title,
                                    systemImage: mode == filterMode ? "checkmark" : mode.icon
                                )
                            }
                        }

                        Divider()

                        Text("Display")
                            .foregroundStyle(.secondary)

                        // Lets the marks be practised from the Arabic alone, without reading the answer off the
                        // transliteration underneath.
                        Button {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) {
                                settings.hideEnglishInArabicLetters.toggle()
                            }
                        } label: {
                            Label(
                                settings.hideEnglishInArabicLetters ? "Show English" : "Hide English",
                                systemImage: settings.hideEnglishInArabicLetters ? "eye" : "eye.slash"
                            )
                        }
                    } label: {
                        adaptiveMenuButtonLabel {
                            Image(systemName: filterMode.icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(settings.accentColor.color)
                                .transition(.opacity)
                        }
                    }
                    .padding(.bottom, 2)
                }
                .padding([.leading, .top], -8)
                .minimizedBarStyle(barsCollapsed)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
        }
        #endif
        .applyConditionalListStyle()
        .navigationTitle("Arabic Alphabet")
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // The one app-wide grid toggle - flipping it here flips Quran, Names, and Islam too.
                Button {
                    settings.hapticFeedback()
                    withAnimation { settings.arabicGridMode.toggle() }
                } label: {
                    Image(systemName: isGridMode ? "list.bullet" : "square.grid.2x2")
                }
                .accessibilityLabel(isGridMode ? "Show list" : "Show grid")
                .tint(settings.accentColor.accent2)
            }
        }
        #endif
    }

    private func adaptiveMenuButtonLabel<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(width: 27, height: 27)
            .padding()
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .conditionalGlassEffect()
    }

    /// A letter section with the shared counted header. `shuffle` adds the random button (iOS only -
    /// it pushes through the grid's hidden navigation link, which the watch list doesn't have).
    @ViewBuilder
    private func countedLetterSection(_ title: String, _ letters: [LetterData], shuffle: Bool = false) -> some View {
        #if os(iOS)
        Section(header: SectionPillHeader(
            title: title,
            count: letters.count,
            onShuffle: shuffle ? { if let letter = letters.randomElement() { gridSelection = letter } } : nil
        )) {
            letterCollection(letters)
        }
        #else
        Section(header: SectionPillHeader(title: title, count: letters.count)) {
            letterCollection(letters)
        }
        #endif
    }

    @ViewBuilder
    private var favoriteLettersSection: some View {
        if searchText.isEmpty, !settings.favoriteLetters.isEmpty {
            let favorites = settings.favoriteLetters.sorted()
            #if os(iOS)
            Section(header: SectionPillHeader(
                title: "FAVORITE LETTERS",
                count: favorites.count,
                icon: "star.fill",
                accentTitle: true,
                isExpanded: $showFavoriteLetters,
                onShuffle: { if let letter = favorites.randomElement() { gridSelection = letter } }
            )) {
                if showFavoriteLetters {
                    letterCollection(favorites)
                }
            }
            #else
            Section(header: SectionPillHeader(title: "FAVORITE LETTERS", count: favorites.count)) {
                letterCollection(favorites)
            }
            #endif
        }
    }

    @ViewBuilder
    private var arabicFontPickerSection: some View {
        Section {
            arabicFontPicker
        } header: {
            Text("ARABIC FONT")
        }
    }

    @ViewBuilder
    private var arabicFontPicker: some View {
        #if os(watchOS)
        // The watch keeps the simple two-way choice; the richer three-way face picker is a phone thing.
        Picker("Arabic Font", selection: $settings.useFontArabic.animation(.easeInOut)) {
            Text("Quranic Font").tag(true)
            Text("Basic Font").tag(false)
        }
        .conditionalGlassEffect(interactive: false)
        .onChange(of: settings.useFontArabic) { _ in settings.hapticFeedback() }
        #else
        IslamArabicFontPicker()
            // Non-interactive glass: interactive Liquid Glass steals per-segment taps on real iOS 26 hardware.
            .conditionalGlassEffect(interactive: false)
        #endif
    }

    private var isGridMode: Bool {
        #if os(iOS)
        return settings.arabicGridMode
        #else
        return false
        #endif
    }

    #if os(iOS)
    /// The letter a grid tile asked to open. Every grid section shares the one link below, so exactly one
    /// letter is ever pushed.
    @State private var gridSelection: LetterData?

    /// Collapse state for the favorites section, same as the Quran tab's Favorite Surahs.
    @AppStorage("showFavoriteLetters") private var showFavoriteLetters = true

    @ViewBuilder
    private var gridNavigationLink: some View {
        NavigationLink(
            isActive: Binding(
                get: { gridSelection != nil },
                set: { if !$0 { gridSelection = nil } }
            )
        ) {
            if let gridSelection {
                ArabicLetterView(letterData: gridSelection)
            }
        } label: {
            EmptyView()
        }
        .opacity(0)
    }
    #endif

    /// Every letter section renders through here, so list and grid can never fall out of sync on *which*
    /// letters a section contains - only on how they're drawn.
    @ViewBuilder
    private func letterCollection(_ letters: [LetterData]) -> some View {
        #if os(iOS)
        if isGridMode {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(letters) { letter in
                    ArabicLetterGridTile(
                        letterData: letter,
                        isFavorite: settings.isLetterFavorite(letterData: letter),
                        accentColor: settings.accentColor,
                        useFontArabic: settings.useFontArabic,
                        fontArabic: settings.nonQuranArabicFontName,
                        onTap: { gridSelection = letter }
                    )
                    .equatable()
                }
            }
            .padding(.horizontal, -8)
            .padding(.vertical, 2)
        } else {
            ForEach(letters) { letterRow(for: $0) }
        }
        #else
        ForEach(letters) { letterRow(for: $0) }
        #endif
    }

    /// The numbers follow the letters' display mode, so the screen is either all rows or all tiles.
    @ViewBuilder
    private var numberCollection: some View {
        #if os(iOS)
        if isGridMode {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(numbers, id: \.number) { ArabicNumberGridTile(numberData: $0) }
            }
            .padding(.horizontal, -8)
            .padding(.vertical, 2)
        } else {
            ForEach(numbers, id: \.number) { ArabicNumberRow(numberData: $0) }
        }
        #else
        ForEach(numbers, id: \.number) { ArabicNumberRow(numberData: $0) }
        #endif
    }

    private func letterRow(for letterData: LetterData) -> some View {
        ArabicLetterRow(
            letterData: letterData,
            isFavorite: settings.isLetterFavorite(letterData: letterData),
            accentColor: settings.accentColor,
            useFontArabic: settings.useFontArabic,
            fontArabic: settings.nonQuranArabicFontName,
            searchQuery: searchText
        )
        .equatable()
    }

    @ViewBuilder
    private var mainLetterSections: some View {
        if searchText.isEmpty {
            standardLetterSections

            Section("TASHKEEL") {
                NavigationLink {
                    TashkeelLettersView()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Letters with Tashkeel")
                                .foregroundColor(.primary)

                            Text("Every letter carrying one harakah at a time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Text("\u{0640}\u{064E}")
                            .foregroundColor(settings.accentColor.color)
                    }
                    .padding(.vertical, 4)
                }
            }

            countedLetterSection("SPECIAL ARABIC LETTERS", otherArabicLetters)

            Section(header: SectionPillHeader(title: "ARABIC NUMBERS", count: numbers.count)) {
                numberCollection
            }

            tajweedSection

            countedLetterSection("NON-ARABIC LETTERS", nonArabicArabicScriptLetters)
        }
    }

    @ViewBuilder
    private var standardLetterSections: some View {
        switch filterMode {
        case .normal:
            countedLetterSection("STANDARD ARABIC LETTERS", standardArabicLetters, shuffle: true)
        case .similarity:
            ForEach(similarityGroups.indices, id: \.self) { idx in
                let group = similarityGroups[idx]
                let header = idx == 0 ? "VOWEL LETTERS" : Self.similarityHeader(for: group)
                countedLetterSection(header, group.compactMap { letterData(for: $0) })
            }
        case .heavyLight:
            countedLetterSection("FOLLOWS PREVIOUS", standardArabicLetters.filter { $0.weight == .followsPrevious })

            countedLetterSection("CONDITIONAL", standardArabicLetters.filter { $0.weight == .conditional })

            countedLetterSection("HEAVY LETTERS", standardArabicLetters.filter { $0.weight == .heavy })

            countedLetterSection("LIGHT LETTERS", (standardArabicLetters + otherArabicLetters).filter {
                $0.weight == .light
                    || $0.transliteration == "taa marbuuTah"
                    || $0.transliteration.lowercased().contains("hamza")
            })
        }
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        if !searchText.isEmpty {
            Section {
                letterCollection(filteredStandardForMode + filteredOther)
            } header: {
                HStack {
                    Text("ARABIC SEARCH RESULTS")

                    Spacer()

                    CountPill(count: filteredStandardForMode.count + filteredOther.count)
                        .opacity(searchText.isEmpty ? 0 : 1)
                }
            }
        }
    }

    private func letterData(for glyph: String) -> LetterData? {
        standardArabicLetters.first { $0.letter == glyph }
            ?? otherArabicLetters.first { $0.letter == glyph }
            ?? nonArabicArabicScriptLetters.first { $0.letter == glyph }
    }

    @ViewBuilder
    private var tajweedSection: some View {
        Section("QURAN SIGNS") {
            QuranSignsSectionContent(accentColor: settings.accentColor.color)
        }
    }
}

/// Bottom size control shared by the Arabic Alphabet list and the per-letter detail. Drives
/// `settings.arabicLetterSizeIndex`, which both screens apply as a Dynamic-Type floor. Position 0 is
/// `.xSmall`, i.e. no floor at all - the alphabet then renders at whatever size the device is set to.
struct ArabicSizeSlider: View {
    @ObservedObject var settings = Settings.shared

    private var maxIndex: Int { Settings.arabicLetterDynamicTypeSizes.count - 1 }

    private var indexBinding: Binding<Double> {
        Binding(
            get: { Double(min(max(settings.arabicLetterSizeIndex, 0), maxIndex)) },
            set: { settings.arabicLetterSizeIndex = min(max(Int($0.rounded()), 0), maxIndex) }
        )
    }

    private func step(by delta: Int) {
        let next = min(max(settings.arabicLetterSizeIndex + delta, 0), maxIndex)
        guard next != settings.arabicLetterSizeIndex else { return }
        settings.hapticFeedback()
        settings.arabicLetterSizeIndex = next
    }

    var body: some View {
        HStack(spacing: 10) {
            sizeStepButton(systemImage: "textformat.size.smaller", delta: -1, enabled: settings.arabicLetterSizeIndex > 0)

            Slider(value: indexBinding, in: 0...Double(maxIndex), step: 1) { editing in
                if !editing { settings.hapticFeedback() }
            }
            .tint(settings.accentColor.color)

            sizeStepButton(systemImage: "textformat.size.larger", delta: 1, enabled: settings.arabicLetterSizeIndex < maxIndex)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .conditionalGlassEffect()
        // Keep the control itself a stable size regardless of the floor it sets for the content.
        .dynamicTypeSize(.large)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Letter size")
    }

    private func sizeStepButton(systemImage: String, delta: Int, enabled: Bool) -> some View {
        Button {
            step(by: delta)
        } label: {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(enabled ? settings.accentColor.color : Color.secondary)
                .frame(width: 30, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// The alphabet seen through one harakah at a time - the transpose of the per-letter detail, which shows one
/// letter carrying every harakah. Pick a mark and all 28 letters (plus the hamza) are rendered with it.
///
/// Shaddah is the exception: on its own it only says "double this letter", and in real words it always carries
/// a vowel with it, so selecting it reveals the four readings (bare, then with fatha / damma / kasra) and every
/// letter becomes tappable to see its own three side by side.