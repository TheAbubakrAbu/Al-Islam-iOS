import SwiftUI

struct ArabicView: View {
    @EnvironmentObject private var settings: Settings
    @State private var searchText = ""
    @AppStorage("arabicFilterMode") private var filterModeRaw: String = ArabicFilterMode.normal.rawValue

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
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                arabicFontPicker

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
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
            .background(Color.white.opacity(0.00001))
        }
        #endif
        .applyConditionalListStyle()
        .navigationTitle("Arabic Alphabet")
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

    @ViewBuilder
    private var favoriteLettersSection: some View {
        if searchText.isEmpty, !settings.favoriteLetters.isEmpty {
            Section("FAVORITE LETTERS") {
                ForEach(settings.favoriteLetters.sorted(), id: \.id) {
                    letterRow(for: $0)
                }
            }
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
        Picker("Arabic Font", selection: $settings.useFontArabic.animation(.easeInOut)) {
            Text("Quranic Font").tag(true)
            Text("Basic Font").tag(false)
        }
        #if !os(watchOS)
        .pickerStyle(.segmented)
        #endif
        // Non-interactive glass: interactive Liquid Glass steals per-segment taps on real iOS 26 hardware.
        .conditionalGlassEffect(interactive: false)
        .onChange(of: settings.useFontArabic) { _ in settings.hapticFeedback() }
    }

    private func letterRow(for letterData: LetterData) -> some View {
        ArabicLetterRow(
            letterData: letterData,
            isFavorite: settings.isLetterFavorite(letterData: letterData),
            accentColor: settings.accentColor,
            useFontArabic: settings.useFontArabic,
            fontArabic: settings.fontArabic,
            searchQuery: searchText
        )
        .equatable()
    }

    @ViewBuilder
    private var mainLetterSections: some View {
        if searchText.isEmpty {
            standardLetterSections

            Section("SPECIAL ARABIC LETTERS") {
                ForEach(otherArabicLetters, id: \.letter) {
                    letterRow(for: $0)
                }
            }

            Section("ARABIC NUMBERS") {
                ForEach(numbers, id: \.number) { ArabicNumberRow(numberData: $0) }
            }

            tajweedSection

            Section("NON-ARABIC LETTERS") {
                ForEach(nonArabicArabicScriptLetters, id: \.letter) {
                    letterRow(for: $0)
                }
            }
        }
    }

    @ViewBuilder
    private var standardLetterSections: some View {
        switch filterMode {
        case .normal:
            Section("STANDARD ARABIC LETTERS") {
                ForEach(standardArabicLetters, id: \.letter) {
                    letterRow(for: $0)
                }
            }
        case .similarity:
            ForEach(similarityGroups.indices, id: \.self) { idx in
                let group = similarityGroups[idx]
                let header = idx == 0 ? "VOWEL LETTERS" : group.joined(separator: " - ")
                Section(header) {
                    ForEach(group, id: \.self) { ch in
                        letterData(for: ch).map { letterRow(for: $0) }
                    }
                }
            }
        case .heavyLight:
            Section("FOLLOWS PREVIOUS") {
                ForEach(standardArabicLetters.filter { $0.weight == .followsPrevious }, id: \.letter) {
                    letterRow(for: $0)
                }
            }
            
            Section("CONDITIONAL") {
                ForEach(standardArabicLetters.filter { $0.weight == .conditional }, id: \.letter) {
                    letterRow(for: $0)
                }
            }
            
            Section("HEAVY LETTERS") {
                ForEach(standardArabicLetters.filter { $0.weight == .heavy }, id: \.letter) {
                    letterRow(for: $0)
                }
            }

            Section("LIGHT LETTERS") {
                ForEach((standardArabicLetters + otherArabicLetters).filter {
                    $0.weight == .light
                        || $0.transliteration == "taa marbuuTah"
                        || $0.transliteration.lowercased().contains("hamza")
                }, id: \.id) {
                    letterRow(for: $0)
                }
            }
        }
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        if !searchText.isEmpty {
            Section {
                ForEach(filteredStandardForMode) {
                    letterRow(for: $0)
                }

                ForEach(filteredOther) {
                    letterRow(for: $0)
                }
            } header: {
                HStack {
                    Text("ARABIC SEARCH RESULTS")

                    Spacer()

                    Text("\(filteredStandardForMode.count + filteredOther.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .conditionalGlassEffect()
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

struct LetterSectionHeader: View {
    @EnvironmentObject var settings: Settings
    let letterData: LetterData

    var body: some View {
        HStack {
            Text("LETTER")
                .font(.subheadline)

            Spacer()

            Image(systemName: settings.isLetterFavorite(letterData: letterData) ? "star.fill" : "star")
                .foregroundColor(settings.accentColor.color)
                .onTapGesture {
                    settings.hapticFeedback()
                    settings.toggleLetterFavorite(letterData: letterData)
                }
        }
    }
}

struct ArabicLetterView: View {
    @EnvironmentObject var settings: Settings

    let letterData: LetterData

    private var useQuranicFontForLetter: Bool {
        settings.useFontArabic && !letterData.isNonArabicScriptLetter
    }

    private var nonArabicBaseSound: String {
        switch letterData.transliteration {
        case "pe": return "p"
        case "che": return "ch"
        case "ve": return "v"
        case "gaaf (gaa)": return "g"
        case "ngaf": return "ng"
        case "zhe": return "zh"
        default: return letterData.transliteration
        }
    }

    var body: some View {
        List {
            Group {
            #if os(watchOS)
            arabicFontPickerSection
            #endif
            Section(header: LetterSectionHeader(letterData: letterData)) {
                VStack {
                    HStack(alignment: .center) {
                        Text(letterData.transliteration)
                            .font(.subheadline)

                        Spacer()
                        
                        Text(letterData.letter)
                            .font(
                                useQuranicFontForLetter
                                    ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .largeTitle).pointSize)
                                    : .title
                            )
                        
                        Spacer()

                        Text(letterData.name)
                            .font(
                                useQuranicFontForLetter
                                    ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                                    : .title2
                            )
                    }
                }
                .padding(.vertical, useQuranicFontForLetter ? 0 : 2)
            }

            if let weight = letterData.weight {
                Section(header: Text("LIGHT / HEAVY PRONUNCIATION")) {
                    VStack(alignment: .leading, spacing: 8) {
                            Text(weight == .heavy ? "Heavy letter (Tafkhim)"
                                : weight == .light ? "Light letter (Tarqiq)"
                             : weight == .conditional ? "Conditional letter"
                             : "Follows previous letter")
                            .font(.headline)

                        if let weightRule = letterData.weightRule {
                            Text(weightRule)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section(header: Text("DIFFERENT FORMS")) {
                VStack {
                    HStack(alignment: .center) {
                        ForEach(0..<min(3, letterData.forms.count), id: \.self) { index in
                            Spacer()

                            Text(letterData.forms[index])
                                .font(
                                    useQuranicFontForLetter
                                        ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                                        : .title2
                                )

                            Spacer()
                        }
                    }
                }
                .padding(.vertical, useQuranicFontForLetter ? 0 : 2)
            }

            if ["alif", "waw", "yaa"].contains(letterData.transliteration) {
                Section(header: Text("SPECIAL ROLE OF VOWEL LETTERS")) {
                    Text("In Arabic, three letters (Alif, Waw, and Yaa) have a special dual role:")
                        .font(.body)

                    if letterData.transliteration == "alif" {
                        Text("- **Alif (ا)**: Functions as a long vowel \"aa\" when used after a letter with a fatha. For example, كِتَاب (kitaab - book). Alif itself is always a vowel letter, never a consonant. Do not confuse it with Hamza on Alif (أ or إ), which is a consonant hamzah.")
                            .font(.body)
                    }

                    if letterData.transliteration == "waw" {
                        Text("- **Waw (و)**: Functions as a long vowel \"uu\" when used after a letter with a damma, like in رَسُول (rasool - messenger). Otherwise, Waw is usually a consonant and makes the \"w\" sound, like in وَقَفَ (waqafa - stood).")
                            .font(.body)
                    }

                    if letterData.transliteration == "yaa" {
                        Text("- **Yaa (ي)**: Functions as a long vowel \"ii\" when used after a letter with a kasra, like in كِتَابِي (kitaabi - my book). Otherwise, Yaa is usually a consonant and makes the \"y\" sound, like in يَد (yad - hand).")
                            .font(.body)
                    }

                    Text("When these letters have no tashkeel, or have sukoon, and the letter before them has the matching harakah, they are treated as Madd Tabee (مَدّ طَبِيعِيّ), or natural Madd: Alif after fatha, Waw after damma, and Yaa after kasra. This is held for 2 harakaat (2 counts).")
                        .font(.body)

                    Text("If a hamzah comes after the vowel letter, or if a shaddah/permanent sukoon comes after it, the natural Madd can turn into one of the special mudood (مُدُود), such as Madd Muttassil, Madd Mufassil, or Madd Lazim. Then the length may become 4, 5, or 6 counts instead of 2.")
                        .font(.body)
                }
            }

            if letterData.showTashkeel {
                Section(header: Text("DIFFERENT HARAKAAT (VOWELS)")) {
                    let chunks = tashkeels.chunked(into: 3)
                    ForEach(chunks.indices, id: \.self) { idx in
                        VStack {
                            #if os(iOS)
                            if idx > 0 {
                                Divider().padding(.trailing, -100)
                            }
                            #endif

                            TashkeelRow(
                                letterData: letterData,
                                tashkeels: chunks[idx],
                                useQuranicFontForLetter: useQuranicFontForLetter
                            )
                            .padding(.top, 14)
                        }
                        #if os(iOS)
                        .listRowSeparator(.hidden, edges: .bottom)
                        #endif
                    }
                }

                Section(header: Text("WITH HAMZA")) {
                    HamzaPracticeRow(
                        letterData: letterData,
                        useQuranicFontForLetter: useQuranicFontForLetter
                    )
                }
            }

            if letterData.isNonArabicScriptLetter {
                Section(header: Text("SOUND WITH HARAKAAT")) {
                    NonArabicVowelPracticeRow(
                        letterData: letterData,
                        baseSound: nonArabicBaseSound,
                        useQuranicFontForLetter: useQuranicFontForLetter
                    )
                }
            }

            if (!letterData.showTashkeel && letterData.transliteration != "alif")
                || letterData.transliteration == "yaa" {
                Section(header: Text("PURPOSE")) {
                    purposeSection(for: letterData)
                }
            }

            if letterData.transliteration == "alif madd" {
                Section(header: Text("OUTSIDE OF THE QURAN")) {
                    Text("In modern Arabic outside of the Quran, Alif Madd usually does not mean a 4, 5, or 6 count Tajweed elongation by itself. It normally represents ءا, so آ is a shortened spelling of ءا.")
                        .font(.body)

                    Text("For example, قرءان is how it is spelled in the Quran, while outside the Quran it is commonly shortened to قرآن. Likewise, ءامين is commonly written آمين.")
                        .font(.body)
                }
            }
            }
            .themedListRowBackground()
        }
        #if !os(watchOS)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                arabicFontPicker
            }
            .padding(.horizontal, 24)
            .padding(.bottom)
            .background(Color.white.opacity(0.00001))
        }
        #endif
        .applyConditionalListStyle()
        .navigationTitle(letterData.letter)
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
        Picker("Arabic Font", selection: $settings.useFontArabic.animation(.easeInOut)) {
            Text("Quranic Font").tag(true)
            Text("Basic Font").tag(false)
        }
        #if !os(watchOS)
        .pickerStyle(.segmented)
        #endif
        // Non-interactive glass: interactive Liquid Glass steals per-segment taps on real iOS 26 hardware.
        .conditionalGlassEffect(interactive: false)
        .onChange(of: settings.useFontArabic) { _ in settings.hapticFeedback() }
    }

    @ViewBuilder
    private func purposeSection(for data: LetterData) -> some View {
        if data.isNonArabicScriptLetter {
            Group {
                Text("This letter is used in non-Arabic languages that use Arabic script.")
                Text("It is not one of the 28 standard Arabic alphabet letters.")
            }
            .font(.body)
        } else {
            switch data.transliteration {
            case "yaa":
                Text("In the Uthmani script of the Quran, when 'yaa' is written at the end of a word (or by itself), it is usually written without the two dots underneath.")
                    .font(.body)
            case "taa marbuuTah":
                Group {
                    Text("\"Taa marbuuTah\" means \"tied/knotted taa\" and is used to indicate the feminine gender in Arabic.")
                    Text("It is typically added to the end of a noun to show that the noun is feminine. For example, the Arabic word for teacher is \"معلم\" (mu'allim) for a male and \"معلمة\" (mu'allima) for a female.")
                    Text("Taa marbuuTah is pronounced as a \"t\" sound in certain cases, such as when the word is in the construct state or has a suffix. Otherwise, it is often silent but affects the preceding vowel, usually creating a short \"ah\" sound, similar to 'ه' (as in \"mu'allimah\").")
                }
                .font(.body)
            case "hamzatul waSl":
                Group {
                    Text("The term \"hamzatul waSl\" translates to \"connecting hamza\" or \"hamza of connection.\"")
                    Text("Hamzatul waSl is always written as an Alif (ا) and is pronounced only if it begins a word at the start of speech. When the word follows another in a sentence, the hamzatul waSl is not pronounced, creating a smooth connection between words.")
                    Text("If a word starts with hamzatul waSl, its pronunciation depends on the third letter of the word. For verbs: if the third letter has a damma, pronounce it with a damma (أُ); if it has a kasra or fatha, pronounce it with a kasra (إِ).")
                    Text("In the Quran, there are seven nouns that start with hamzatul waSl. These nouns always begin with a kasra when pronounced in isolation.")
                    Text("Hamzatul waSl is usually not written with diacritics, but in learner texts or the Quran, it may be marked with a small ص above the Alif, indicating waSl.")
                }
                .font(.body)
            default:
                if data.transliteration.contains("hamza") {
                    Group {
                        Text("The letter Hamza has multiple forms, depending on its position and the surrounding vowels or diacritics (tashkeel):")
                        Text("Hamza on its own (ء): Used when Hamza appears in the middle or end of a word without a preceding vowel.")
                        Text("Hamza on an Alif (أ or إ): When Hamza begins a word, it is written on an Alif. A fatha or damma places it above (أ), while a kasra places it below (إ).")
                        Text("Hamza on a Waw (ؤ): Appears after a damma or following a Waw.")
                        Text("Hamza on a Yaa (ئ): Appears after a kasra or following a Yaa.")
                        Text("Although Hamza takes different forms, it represents the same sound ('ah'). These forms are based on Arabic orthography (spelling conventions) rather than phonetics.")
                    }
                    .font(.body)
                } else if data.transliteration.contains("mad") {
                    Group {
                        Text("The wavy line above a vowel letter is called \"Madd.\" In Arabic, Madd (مَدّ) means stretching or elongation. In Quranic recitation, it marks a measured elongation, not just a decorative spelling mark.")
                        Text("In the Quran, this Madd can fall under 3 main long-Madd cases from Tajweed: Madd Muttassil, Madd Mufassil, and Madd Lazim.")
                        Text("Madd Muttassil (مَدّ مُتَّصِل) means \"connected Madd.\" Muttassil means connected because the Madd letter is followed by a hamzah in the same word, so it is lengthened 4 or 5 counts.")
                        Text("Madd Mufassil (مَدّ مُنْفَصِل) means \"separated Madd.\" Mufassil means separated because the Madd letter comes at the end of one word and the next word begins with hamzah, so it may be read 2, 4, or 5 counts depending on the recitation style.")
                        Text("Madd Lazim (مَدّ لَازِم) means \"necessary Madd.\" Lazim means necessary or required because the Madd letter is followed by a permanent sukoon or shaddah, so it is lengthened 6 counts.")
                        Text("These are special mudood (مُدُود), the plural of Madd. They happen when natural Madd is no longer just 2 counts because hamzah, sukoon, or shaddah changes the rule.")
                    }
                    .font(.body)
                } else if data.transliteration == "alif maqSoorah" {
                    Text("Alif maqSoorah resembles a Yaa without dots and usually replaces a regular Alif at the end of a word. It is used in certain cases, including some Quranic words and non-Arabic proper nouns. It is the exact same and sounds the same as alif.")
                        .font(.body)
                } else if data.transliteration == "laa" {
                    Text("The combination of ل and ا forms a unique shape: لا.")
                        .font(.body)
                }
            }
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

struct TashkeelRow: View {
    @EnvironmentObject var settings: Settings

    let letterData: LetterData
    let tashkeels: [Tashkeel]
    let useQuranicFontForLetter: Bool

    private var baseSound: String {
        letterData.sound
    }

    var body: some View {
        HStack(spacing: 20) {
            ForEach(tashkeels, id: \.english) { tk in
                VStack(spacing: useQuranicFontForLetter ? 4 : 8) {
                    Group {
                        if !tk.transliteration.isEmpty {
                            Text(baseSound + tk.transliteration)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if tk.english == "Shaddah" {
                            Text(baseSound + baseSound)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if tk.english.contains("Sukoon") {
                            Text(baseSound)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                    Text(letterData.letter + tk.tashkeelMark)
                        .font(
                            useQuranicFontForLetter
                                ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                                : .title
                        )
                        .frame(maxWidth: .infinity)

                    #if os(iOS)
                    Text(tk.english)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    #endif
                }
            }
        }
    }
}

struct HamzaPracticeRow: View {
    @EnvironmentObject var settings: Settings

    let letterData: LetterData
    let useQuranicFontForLetter: Bool

    private var hamzaShortSyllables: [(latin: String, arabic: String)] {
        let s = letterData.sound
        let l = letterData.letter
        return [
            ("a" + s, "أَ" + l),
            ("i" + s, "إِ" + l),
            ("u" + s, "أُ" + l)
        ]
    }

    private var hamzaLongSyllablesBasic: [(latin: String, arabic: String)] {
        let s = letterData.sound
        let l = letterData.letter
        return [
            ("aa" + s, "ءَ" + "ا" + l),
            ("ii" + s, "إِ" + "ي" + l),
            ("uu" + s, "أُ" + "و" + l)
        ]
    }

    private var hamzaLongSyllables: [(latin: String, arabic: String)] {
        let s = letterData.sound
        let l = letterData.letter
        return [
            ("a" + s + "aa", "أَ" + l + "َا"),
            ("a" + s + "ii", "أَ" + l + "ِي"),
            ("a" + s + "uu", "أَ" + l + "ُو")
        ]
    }

    private var hamzaShaddahA: [(latin: String, arabic: String)] {
        let s = letterData.sound
        let l = letterData.letter
        return [
            ("a" + s + s + "aa", "أَ" + l + "َّا"),
            ("a" + s + s + "ii", "أَ" + l + "ِّي"),
            ("a" + s + s + "uu", "أَ" + l + "ُّو")
        ]
    }

    private var hamzaShaddahI: [(latin: String, arabic: String)] {
        let s = letterData.sound
        let l = letterData.letter
        return [
            ("i" + s + s + "aa", "إِ" + l + "َّا"),
            ("i" + s + s + "ii", "إِ" + l + "ِّي"),
            ("i" + s + s + "uu", "إِ" + l + "ُّو")
        ]
    }

    private var hamzaShaddahU: [(latin: String, arabic: String)] {
        let s = letterData.sound
        let l = letterData.letter
        return [
            ("u" + s + s + "aa", "أُ" + l + "َّا"),
            ("u" + s + s + "ii", "أُ" + l + "ِّي"),
            ("u" + s + s + "uu", "أُ" + l + "ُّو")
        ]
    }

    private var rows: [[(latin: String, arabic: String)]] {
        [
            hamzaShortSyllables,
            hamzaLongSyllablesBasic,
            hamzaLongSyllables,
            hamzaShaddahA,
            hamzaShaddahI,
            hamzaShaddahU
        ]
    }

    @ViewBuilder
    private func practiceTriplet(_ syllables: [(latin: String, arabic: String)]) -> some View {
        HStack(spacing: 20) {
            ForEach(syllables, id: \.latin) { syllable in
                VStack {
                    Text(syllable.latin)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(syllable.arabic)
                        .font(
                            useQuranicFontForLetter
                                ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                                : .title
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, useQuranicFontForLetter ? 0 : 8)
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(rows.indices, id: \.self) { idx in
                #if os(iOS)
                if idx > 0 {
                    Divider().padding(.trailing, -100)
                }
                #endif

                practiceTriplet(rows[idx])
            }
        }
        .padding(.top, 6)
    }
}

struct NonArabicVowelPracticeRow: View {
    @EnvironmentObject var settings: Settings

    let letterData: LetterData
    let baseSound: String
    let useQuranicFontForLetter: Bool

    private var syllables: [(latin: String, arabic: String)] {
        [
            (baseSound + "a", letterData.letter + "َ"),
            (baseSound + "i", letterData.letter + "ِ"),
            (baseSound + "u", letterData.letter + "ُ")
        ]
    }

    var body: some View {
        HStack(spacing: 20) {
            ForEach(syllables, id: \.latin) { syllable in
                VStack {
                    Text(syllable.latin)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(syllable.arabic)
                        .font(
                            useQuranicFontForLetter
                                ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title1).pointSize)
                                : .title
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, useQuranicFontForLetter ? 0 : 8)
                }
            }
        }
    }
}

struct ArabicLetterRow: View, Equatable {
    @EnvironmentObject private var settings: Settings
    let letterData: LetterData
    let isFavorite: Bool
    let accentColor: AccentColor
    let useFontArabic: Bool
    let fontArabic: String
    let searchQuery: String

    init(
        letterData: LetterData,
        isFavorite: Bool? = nil,
        accentColor: AccentColor = Settings.shared.accentColor,
        useFontArabic: Bool = Settings.shared.useFontArabic,
        fontArabic: String = Settings.shared.fontArabic,
        searchQuery: String = ""
    ) {
        self.letterData = letterData
        self.isFavorite = isFavorite ?? Settings.shared.isLetterFavorite(letterData: letterData)
        self.accentColor = accentColor
        self.useFontArabic = useFontArabic
        self.fontArabic = fontArabic
        self.searchQuery = searchQuery
    }

    var body: some View {
        // A letter can also match on its hidden `name` / weight keywords / rule, so only guarantee a
        // highlight on a displayed field (transliteration or the letter glyph) when that field itself
        // contains the query — otherwise leave it un-highlighted rather than force-color an unrelated field.
        let query = searchQuery.lowercased()
        let matchedTransliteration = !query.isEmpty && letterData.transliteration.lowercased().contains(query)
        let matchedLetter = !query.isEmpty && letterData.letter.lowercased().contains(query)
        return NavigationLink(destination: ArabicLetterView(letterData: letterData)) {
            HStack {
                HighlightedSnippet(
                    source: letterData.transliteration,
                    term: searchQuery,
                    font: .subheadline,
                    accent: accentColor.color,
                    fg: .primary,
                    guaranteeMatch: matchedTransliteration
                )

                Spacer()

                HighlightedSnippet(
                    source: letterData.letter,
                    term: searchQuery,
                    font: (useFontArabic && !letterData.isNonArabicScriptLetter)
                        ? .custom(fontArabic, size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
                        : .title2,
                    accent: accentColor.color,
                    fg: accentColor.color,
                    guaranteeMatch: matchedLetter
                )
            }
            .padding(.vertical, -2)
        }
        #if os(iOS)
        .swipeActions(edge: .leading) { favButton() }
        .swipeActions(edge: .trailing) { favButton() }
        .contextMenu { contextItems() }
        #endif
    }

    @ViewBuilder
    private func favButton() -> some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.toggleLetterFavorite(letterData: letterData)
            }
        } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
        }
        .tint(accentColor.color)
    }

    @ViewBuilder
    private func contextItems() -> some View {
        #if os(iOS)
        Text("Letter Actions")
            .foregroundStyle(.secondary)

        Button(role: isFavorite ? .destructive : nil) {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.toggleLetterFavorite(letterData: letterData)
            }
        } label: {
            Label(isFavorite ? "Unfavorite Letter" : "Favorite Letter",
                  systemImage: isFavorite ? "star.fill" : "star")
        }

        Button {
            settings.hapticFeedback()
            UIPasteboard.general.string = letterData.letter
        } label: {
            Label("Copy Letter", systemImage: "doc.on.doc")
        }

        Button {
            settings.hapticFeedback()
            UIPasteboard.general.string = letterData.transliteration
        } label: {
            Label("Copy Transliteration", systemImage: "doc.on.doc")
        }
        #endif
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.letterData == rhs.letterData &&
        lhs.isFavorite == rhs.isFavorite &&
        lhs.accentColor == rhs.accentColor &&
        lhs.useFontArabic == rhs.useFontArabic &&
        lhs.fontArabic == rhs.fontArabic &&
        lhs.searchQuery == rhs.searchQuery
    }
}

struct ArabicNumberRow: View {
    @EnvironmentObject private var settings: Settings
    let numberData: (number: String, name: String, transliteration: String, englishNumber: String)

    var body: some View {
        HStack {
            Text(numberData.englishNumber)
                .font(.title3)

            Spacer()

            VStack(alignment: .center) {
                Text(numberData.name)
                    .font(
                        settings.useFontArabic
                            ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize)
                            : .subheadline
                    )
                    .foregroundColor(settings.accentColor.color)

                Text(numberData.transliteration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(numberData.number)
                .font(.title2)
                .foregroundColor(settings.accentColor.color)
        }
    }
}

struct StopSignInfo: Identifiable {
    let title: String
    let symbol: String

    var id: String { symbol + title }
}

struct StopInfoRow: View {
    let title: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Text(symbol)
                .font(.headline.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct QuranSignsSectionContent: View {
    let accentColor: Color
    var includeLearnMoreLink: Bool = true

    private let signs: [StopSignInfo] = [
        StopSignInfo(title: "Make Sujood", symbol: "۩"),
        StopSignInfo(title: "Hizb Marker", symbol: "۞"),
        StopSignInfo(title: "Mandatory Stop", symbol: "مـ"),
        StopSignInfo(title: "Preferred Stop", symbol: "قلى"),
        StopSignInfo(title: "Permissible Stop", symbol: "ج"),
        StopSignInfo(title: "Short Pause", symbol: "س"),
        StopSignInfo(title: "Stop at One", symbol: "∴ ∴"),
        StopSignInfo(title: "Prefer Continue", symbol: "صلى"),
        StopSignInfo(title: "Must Continue", symbol: "لا")
    ]

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8, alignment: .top),
            GridItem(.flexible(), spacing: 8, alignment: .top)
        ]
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(signs) { sign in
                StopInfoRow(title: sign.title, symbol: sign.symbol, color: accentColor)
            }

            if includeLearnMoreLink,
               let url = URL(string: "https://studioarabiya.com/blog/tajweed-rules-stopping-pausing-signs/") {
                Link(destination: url) {
                    HStack(spacing: 8) {
                        Text("View More")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(accentColor)
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .center)
                    .offset(y: -1)
                    .contentShape(Rectangle())
                }
            }
        }
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: true) {
        ArabicView()
    }
}
