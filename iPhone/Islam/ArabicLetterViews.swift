import SwiftUI

struct TashkeelLettersView: View {
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @ObservedObject private var settings = Settings.shared

    private static let shaddahMark = "\u{0651}"

    /// Every mark the per-letter detail shows - the short vowels, the tanween, the long vowels and their madd
    /// forms, the dagger alif and the miniatures, both sukoons, and the shaddah. This screen is the same table
    /// read the other way round, so it must not be a subset of it.
    ///
    /// The two sukoons are the exception: they're the same mark in two scripts (the plain one and the Uthmani
    /// one), so they share a single chip and the script is chosen below the grid - two tiles for one idea left
    /// the grid with an odd tile hanging off the end.
    private var marks: [Tashkeel] {
        tashkeels.filter { $0.english != Self.quranicSukoonName }
    }

    private static let plainSukoonName = "Sukuun 1"
    private static let quranicSukoonName = "Sukuun 2"

    /// Baa is the carrier in the chips. A harakah drawn on a bare tatweel (ـَ) is a floating stroke that reads
    /// as nothing; on a real letter it reads as the syllable it is.
    private static let carrierLetter = "ب"

    /// What a mark can actually be placed on: the letters, plus the standalone hamza.
    ///
    /// Alif is excluded. It never carries a harakah of its own - it's the long vowel that a *previous* letter's
    /// fatha lengthens (or a seat for a hamza), so "أَلِف with a damma" isn't a thing that occurs.
    private var letters: [LetterData] {
        standardArabicLetters.filter { $0.letter != "ا" }
            + otherArabicLetters.filter { $0.letter == "ء" }
    }

    @State private var selectedMarkName = "Fatha"
    /// Which vowel rides on the shaddah, or nil for the bare doubling. Only used while Shaddah is selected.
    @State private var shaddahVowelName: String?
    /// Which sukoon is drawn: the plain one, or the Uthmani one a mushaf prints. Only used while Sukoon is
    /// selected.
    @State private var useQuranicSukoon = false
    @State private var detailLetter: LetterData?

    /// The mark actually drawn. For the sukoon that's whichever script is chosen below the grid; for everything
    /// else it's simply the chip you picked.
    private var selectedMark: Tashkeel? {
        if isSukoon, useQuranicSukoon {
            return tashkeels.first { $0.english == Self.quranicSukoonName }
        }
        return marks.first { $0.english == selectedMarkName }
    }

    private var isShaddah: Bool { selectedMarkName == "Shaddah" }
    private var isSukoon: Bool { selectedMarkName == Self.plainSukoonName }

    private var shaddahVowels: [Tashkeel] {
        ["Fatha", "Kasra", "Damma"].compactMap { name in tashkeels.first { $0.english == name } }
    }

    private var useQuranicFont: Bool { settings.useFontArabic }

    /// "Sukuun 1" / "Sukuun 2" are how the mark table distinguishes the two scripts; to the reader they are both
    /// just the sukoon, and the script is a choice made below the grid.
    private func displayName(_ mark: Tashkeel) -> String {
        (mark.english == Self.plainSukoonName || mark.english == Self.quranicSukoonName) ? "Sukoon" : mark.english
    }

    /// The hamza has no consonant sound of its own in the table, so it gets the glottal stop.
    private func baseSound(_ letter: LetterData) -> String {
        letter.sound.isEmpty ? "'" : letter.sound
    }

    private func glyph(_ letter: LetterData) -> String {
        guard let mark = selectedMark else { return letter.letter }
        if isShaddah {
            let vowel = shaddahVowelName.flatMap { name in shaddahVowels.first { $0.english == name } }
            return letter.letter + Self.shaddahMark + (vowel?.tashkeelMark ?? "")
        }
        return letter.letter + mark.tashkeelMark
    }

    /// How the marked letter is read: "ba", "bun", "b" (sukoon), "bb" (shaddah), "bba" (shaddah + fatha).
    private func reading(_ letter: LetterData) -> String {
        let sound = baseSound(letter)
        guard let mark = selectedMark else { return sound }

        if isShaddah {
            let vowel = shaddahVowelName.flatMap { name in shaddahVowels.first { $0.english == name } }
            return sound + sound + (vowel?.transliteration ?? "")
        }
        // A sukoon carries no vowel, so the letter is just its own consonant sound.
        return sound + mark.transliteration
    }

    /// The chip's specimen: the mark drawn on baa.
    private func carrierGlyph(_ mark: Tashkeel) -> String {
        Self.carrierLetter + mark.tashkeelMark
    }

    var body: some View {
        List {
            Group {
                markPickerSection
                lettersSection
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Tashkeel")
        #if os(iOS)
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                ArabicSizeSlider()

                // The same three-way face choice the alphabet screen offers - a harakah sits very differently
                // on a Quranic face than on the system one, which is half of what you'd come here to see.
                IslamArabicFontPicker()
            }
            .minimizedBarStyle(barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .sheet(item: $detailLetter) { letter in
            NavigationView {
                shaddahDetail(for: letter)
            }
            .smallMediumSheetPresentation()
        }
        #endif
    }

    private var markPickerSection: some View {
        Section("HARAKAH") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 10)], spacing: 10) {
                ForEach(marks, id: \.english) { mark in
                    markChip(mark)
                }
            }
            .padding(.vertical, 4)

            if isShaddah {
                // A bare shaddah is only ever half the story - these are the readings it actually appears with.
                Picker("Shaddah vowel", selection: $shaddahVowelName.animation(.easeInOut)) {
                    Text("Shaddah").tag(String?.none)
                    ForEach(shaddahVowels, id: \.english) { vowel in
                        Text("+ \(vowel.english)").tag(String?.some(vowel.english))
                    }
                }
                #if !os(watchOS)
                .pickerStyle(.segmented)
                #endif
            }

            if isSukoon {
                // Same mark, two scripts: the plain sukoon, and the Uthmani one a printed mushaf uses.
                Picker("Sukoon script", selection: $useQuranicSukoon.animation(.easeInOut)) {
                    Text("Normal").tag(false)
                    Text("Quranic").tag(true)
                }
                #if !os(watchOS)
                .pickerStyle(.segmented)
                #endif
            }
        }
    }

    private func markChip(_ mark: Tashkeel) -> some View {
        let isSelected = mark.english == selectedMarkName
        // The sukoon chip previews whichever script is currently chosen, so the tile matches the letters below.
        let previewMark = (mark.english == Self.plainSukoonName && useQuranicSukoon)
            ? (tashkeels.first { $0.english == Self.quranicSukoonName } ?? mark)
            : mark

        return Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                selectedMarkName = mark.english
                if mark.english != "Shaddah" { shaddahVowelName = nil }
                if mark.english != Self.plainSukoonName { useQuranicSukoon = false }
            }
        } label: {
            VStack(spacing: 1) {
                // Drawn on baa, not on a bare tatweel: a floating stroke isn't recognizable, "بَ" is.
                Text(carrierGlyph(previewMark))
                    .font(useQuranicFont ? settings.scalableArabicFont(base: 24, relativeTo: .title2) : .title2)
                    .arabicFontDesign(custom: useQuranicFont && settings.quranUsesCustomArabicFace)
                    .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                    .foregroundColor(isSelected ? settings.accentColor.color : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(height: 32)
                    .fixedSize(horizontal: false, vertical: true)

                Text(displayName(mark))
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundColor(isSelected ? settings.accentColor.color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .padding(.horizontal, 2)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(settings.accentColor.color.opacity(isSelected ? 0.18 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? settings.accentColor.color : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private var lettersSection: some View {
        Section(selectedMark.map { "LETTERS WITH \(displayName($0).uppercased())" } ?? "LETTERS") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60), spacing: 6)], spacing: 6) {
                ForEach(letters) { letter in
                    letterTile(letter)
                }
            }
            .padding(.vertical, 2)
        }
    }

    /// Sized to the glyph, not to the Quranic face's (very tall) line box - but it grows with the size slider,
    /// or the letters would be pinned at whatever fits 34pt no matter where the slider sat.
    private var glyphBoxHeight: CGFloat {
        let steps = Settings.arabicLetterDynamicTypeSizes.count - 1
        let index = min(max(settings.arabicLetterSizeIndex, 0), steps)
        return 34 + CGFloat(index) * 7
    }

    private func letterTile(_ letter: LetterData) -> some View {
        VStack(spacing: 2) {
            Text(glyph(letter))
                .font(useQuranicFont ? settings.scalableArabicFont(base: 28, relativeTo: .title) : .title)
                .arabicFontDesign(custom: useQuranicFont && settings.quranUsesCustomArabicFace)
                .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(height: glyphBoxHeight)
                .fixedSize(horizontal: false, vertical: true)

            Text(reading(letter))
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        // Only the shaddah tiles are actionable (they open the three readings), so only they are filled.
        .conditionalGlassEffect(clear: !isShaddah, rectangle: true)
        #if os(iOS)
        .onTapGesture {
            guard isShaddah else { return }
            settings.hapticFeedback()
            detailLetter = letter
        }
        #endif
    }

    #if os(iOS)
    /// The three readings a shaddah actually takes, for one letter.
    private func shaddahDetail(for letter: LetterData) -> some View {
        let sound = baseSound(letter)

        return List {
            Group {
                Section {
                    ForEach(shaddahVowels, id: \.english) { vowel in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Shaddah + \(vowel.english)")
                                    .font(.subheadline.weight(.semibold))

                                Text(sound + sound + vowel.transliteration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Text(letter.letter + Self.shaddahMark + vowel.tashkeelMark)
                                .font(useQuranicFont ? settings.scalableArabicFont(base: 30, relativeTo: .title) : .title)
                                .arabicFontDesign(custom: useQuranicFont && settings.quranUsesCustomArabicFace)
                                .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("\(letter.transliteration.uppercased()) WITH SHADDAH")
                } footer: {
                    Text("A shaddah doubles the letter: the first is silent (sukoon) and the second carries the vowel. It never appears at the start of a word.")
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(letter.transliteration.capitalized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    settings.hapticFeedback()
                    detailLetter = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                }
                .tint(settings.accentColor.color)
            }
        }
    }
    #endif
}

struct LetterSectionHeader: View {
    @ObservedObject var settings = Settings.shared
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
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @ObservedObject var settings = Settings.shared

    let letterData: LetterData

    private var useQuranicFontForLetter: Bool {
        settings.useFontArabic && !letterData.isNonArabicScriptLetter
    }

    /// The "it is always this" sentence for a letter whose weight never changes, phrased exactly like the one
    /// waaw and yaa already carry. `nil` for `.conditional` / `.followsPrevious`, which are never "always"
    /// anything and always supply their own rule.
    private static func alwaysWeightRule(for weight: LetterWeight, letterData: LetterData) -> String? {
        let name = letterData.transliteration.capitalized
        switch weight {
        case .light:
            return "\(name) is always pronounced as a light letter, in every position."
        case .heavy:
            return "\(name) is always pronounced as a heavy letter, in every position. It is one of the letters of isti'la (elevation)."
        case .conditional, .followsPrevious:
            return nil
        }
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
            // Hidden for the non-Arabic letters: they aren't in the Quranic faces, so the pick changes nothing.
            if !letterData.isNonArabicScriptLetter {
                arabicFontPickerSection
            }
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
                                    ? settings.scalableArabicFont(base: 34, relativeTo: .largeTitle)
                                    : .title
                            )
                            .arabicFontDesign(custom: useQuranicFontForLetter && settings.quranUsesCustomArabicFace)
                            .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)

                        Spacer()

                        Text(letterData.name)
                            .font(
                                useQuranicFontForLetter
                                    ? settings.scalableArabicFont(base: 28, relativeTo: .title)
                                    : .title2
                            )
                            .arabicFontDesign(custom: useQuranicFontForLetter && settings.quranUsesCustomArabicFace)
                            .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                    }
                }
                .padding(.vertical, useQuranicFontForLetter ? 0 : 2)
            }

            if let weight = letterData.weight {
                Section(header: Text("LIGHT / HEAVY PRONUNCIATION")) {
                    VStack(alignment: .leading, spacing: 8) {
                            // The letter itself is described, so the masculine adjective (mufakhkham /
                            // muraqqaq) is what applies - not the feminine noun for the act (tafkhim's
                            // "mufakhkhamah").
                            Text(weight == .heavy ? "Heavy letter (Mufakhkham)"
                                : weight == .light ? "Light letter (Muraqqaq)"
                             : weight == .conditional ? "Conditional letter"
                             : "Follows previous letter")
                            .font(.headline)

                        // A plain light/heavy letter carries no rule of its own, and used to show nothing
                        // here at all - which made the two letters that DO spell it out (waaw and yaa:
                        // "pronounced as a light letter in all positions") look special. They aren't; they
                        // were simply the only ones that said so. Every unconditional letter now says it, in
                        // the same words.
                        if let rule = letterData.weightRule ?? Self.alwaysWeightRule(for: weight, letterData: letterData) {
                            Text(rule)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section(header: Text("DIFFERENT FORMS")) {
                VStack {
                    // `forms` is ordered [final, medial, initial], so laid out left-to-right the initial form
                    // lands on the right - the correct right-to-left reading order for Arabic.
                    HStack(alignment: .center) {
                        ForEach(0..<min(3, letterData.forms.count), id: \.self) { index in
                            Spacer()

                            Text(letterData.forms[index])
                                .font(
                                    useQuranicFontForLetter
                                        ? settings.scalableArabicFont(base: 28, relativeTo: .title)
                                        : .title2
                                )
                                .arabicFontDesign(custom: useQuranicFontForLetter && settings.quranUsesCustomArabicFace)
                                .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)

                            Spacer()
                        }
                    }
                }
                .padding(.vertical, useQuranicFontForLetter ? 0 : 2)
            }

            if ["alif", "waaw", "yaa"].contains(letterData.transliteration) {
                // Alif is NOT one of the letters with two roles. Waaw and yaa really do switch between vowel and
                // consonant; alif is a vowel every single time it appears. The consonant people mistake it for is
                // the hamzah that sits on it.
                let isAlif = letterData.transliteration == "alif"

                Section(header: Text(isAlif ? "ALIF IS ALWAYS A VOWEL" : "SPECIAL ROLE OF VOWEL LETTERS")) {
                    if isAlif {
                        Text("Alif is always a vowel letter. Unlike Waw and Yaa, it never acts as a consonant.")
                            .font(.body)

                        Text("- **Alif (ا)**: The long vowel \"aa\", used after a letter with a fatha. For example, كِتَاب (kitaab, book).")
                            .font(.body)

                        Text("Do not confuse Alif with Hamza on Alif (أ or إ). The hamzah is the consonant there; the alif is only its seat.")
                            .font(.body)
                    } else {
                        Text("Two letters (Waw and Yaa) have a dual role, acting as a vowel in some words and a consonant in others:")
                            .font(.body)
                    }

                    if letterData.transliteration == "waaw" {
                        Text("- **Waw (و)**: As a **vowel** it is the long \"uu\" (also written \"oo\", and shortened to \"u\"), used after a letter with a damma, like in رَسُول (rasool - messenger). As a **consonant** it makes the \"w\" sound, like in وَقَفَ (waqafa - stood).")
                            .font(.body)
                    }

                    if letterData.transliteration == "yaa" {
                        Text("- **Yaa (ي)**: As a **vowel** it is the long \"ee\" (also written \"ii\", and shortened to \"i\"), used after a letter with a kasra, like in كِتَابِي (kitaabi - my book). As a **consonant** it makes the \"y\" sound, like in يَد (yad - hand).")
                            .font(.body)
                    }

                    Text("When these letters have no tashkeel, or have sukoon, and the letter before them has the matching harakah, they are treated as Madd Tabee (مَدّ طَبِيعِيّ), or natural Madd: Alif after fatha, Waw after damma, and Yaa after kasra. This is held for 2 harakaat (2 counts).")
                        .font(.body)

                    Text("When the madd is longer than 2 counts, the mushaf tells you so: a squiggly line (ٓ) is written above the letter. That mark is the sign of one of the special mudood (مُدُود), such as Madd Muttassil, Madd Munfasil, or Madd Lazim, held for 4, 5, or 6 counts instead of 2. Without the squiggle, the madd stays at its natural 2 counts.")
                        .font(.body)

                    NavigationLink(destination: LazyDestination { TajweedFoundationsView() }) {
                        Label("Learn the Madd Rules", systemImage: "book")
                            .font(.body)
                            .foregroundColor(settings.accentColor.color)
                    }
                }
            }

            if letterData.showTashkeel {
                Section(header: Text("DIFFERENT HARAKAAT (VOWELS)")) {
                    // ONE list row holding every triplet - the same shape as the Hamza section below. Each
                    // triplet used to be its own row, so all seven paid the list's row insets and minimum row
                    // height on top of their own 14pt padding, which is where the wasted height came from.
                    VStack(alignment: .leading, spacing: 10) {
                        let chunks = tashkeels.chunked(into: 3)
                        ForEach(chunks.indices, id: \.self) { idx in
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
                        }
                    }
                    .padding(.top, 6)
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
        // Apple Music-style: the bottom bar minimizes while scrolling down, restores on scroll-up.
        .collapseBarsOnScroll($barsCollapsed)
        .adaptiveSafeArea(edge: .bottom) {
            VStack(spacing: SafeAreaInsetVStackSpacing.standard) {
                ArabicSizeSlider()

                // The Quranic/Basic choice is meaningless for پ چ ژ and the rest: they aren't in the Quranic
                // faces at all, so both options render them identically in the system font. Offering the pick
                // implies a difference that isn't there.
                if !letterData.isNonArabicScriptLetter {
                    arabicFontPicker
                }
            }
            .minimizedBarStyle(barsCollapsed)
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
                        Text("In the Quran, this Madd can fall under 3 main long-Madd cases from Tajweed: Madd Muttassil, Madd Munfasil, and Madd Lazim.")
                        Text("Madd Muttassil (مَدّ مُتَّصِل) means \"connected Madd.\" Muttassil means connected because the Madd letter is followed by a hamzah in the same word, so it is lengthened 4 or 5 counts.")
                        Text("Madd Munfasil (مَدّ مُنْفَصِل) means \"separated Madd.\" Munfasil means separated because the Madd letter comes at the end of one word and the next word begins with hamzah, so it may be read 2, 4, or 5 counts depending on the recitation style.")
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
    @ObservedObject var settings = Settings.shared

    let letterData: LetterData
    let tashkeels: [Tashkeel]
    let useQuranicFontForLetter: Bool

    /// The mark whose detail sheet is open. Tapping a cell both speaks it and opens this.
    @State private var selectedTashkeel: Tashkeel?

    private var baseSound: String {
        letterData.sound
    }

    /// How the letter is READ with this mark - the only caption a row needs. Naming the mark ("Miniature Waaw",
    /// "Sukuun 2") told the reader nothing about the sound and made every cell three lines tall. The name is in
    /// the detail sheet instead, where there is room for it.
    private func reading(_ tk: Tashkeel) -> String {
        if !tk.transliteration.isEmpty { return baseSound + tk.transliteration }
        if tk.english == "Shaddah" { return baseSound + baseSound }
        return baseSound   // the sukoons: the bare consonant
    }

    var body: some View {
        // Deliberately the SAME layout as `HamzaPracticeRow.practiceTriplet`: reading above, glyph below, 20pt
        // between columns, and no fixed glyph box - the letter is free to grow with the size slider, and the
        // spacing is the one that already reads well on the Hamza section.
        HStack(spacing: 20) {
            // The table doesn't divide evenly into threes, so the last row is short. Its placeholders come
            // FIRST, which under right-to-left puts them on the right - leaving the real entry in the column it
            // continues from (the Uthmani sukoon lands directly beneath the plain one).
            if tashkeels.count < 3 {
                ForEach(0..<(3 - tashkeels.count), id: \.self) { _ in
                    Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                }
            }

            ForEach(tashkeels, id: \.english) { tk in
                VStack {
                    if !settings.hideEnglishInArabicLetters {
                        Text(reading(tk))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }

                    Text(letterData.letter + tk.tashkeelMark)
                        .font(
                            useQuranicFontForLetter
                                ? settings.scalableArabicFont(base: 28, relativeTo: .title)
                                : .title
                        )
                        .arabicFontDesign(custom: useQuranicFontForLetter && settings.quranUsesCustomArabicFace)
                        .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, useQuranicFontForLetter ? 0 : 8)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    settings.hapticFeedback()
                    ArabicSpeech.shared.speak(letterData.letter + tk.tashkeelMark)
                    selectedTashkeel = tk
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("\(tk.english), read \(reading(tk))")
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .sheet(item: $selectedTashkeel) { tk in
            TashkeelDetailSheet(
                tashkeel: tk,
                letterData: letterData,
                reading: reading(tk),
                useQuranicFontForLetter: useQuranicFontForLetter
            )
            #if os(iOS)
            .smallMediumSheetPresentation()
            #endif
        }
    }
}

/// What a tashkeel mark actually is: its name, the root that name comes from, how long it is held, and what your
/// mouth has to do to make it. Opened by tapping a mark, which also speaks it.
struct TashkeelDetailSheet: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    let tashkeel: Tashkeel
    let letterData: LetterData
    let reading: String
    let useQuranicFontForLetter: Bool

    private var spokenText: String { letterData.letter + tashkeel.tashkeelMark }

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 12) {
                        Text(spokenText)
                            .font(
                                useQuranicFontForLetter
                                    ? settings.scalableArabicFont(base: 64, relativeTo: .largeTitle)
                                    : .system(size: 64)
                            )
                            .arabicFontDesign(custom: useQuranicFontForLetter && settings.quranUsesCustomArabicFace)
                            .frame(maxWidth: .infinity)

                        if !settings.hideEnglishInArabicLetters {
                            Text(reading)
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.secondary)
                        }

                        if ArabicSpeech.shared.isAvailable {
                            Button {
                                settings.hapticFeedback()
                                ArabicSpeech.shared.speak(spokenText)
                            } label: {
                                Label("Hear It", systemImage: "speaker.wave.2.fill")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.bordered)
                            .tint(settings.accentColor.color)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Text("THE MARK")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(tashkeel.english)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Arabic")
                        Spacer()
                        Text(tashkeel.arabic)
                            .font(
                                useQuranicFontForLetter
                                    ? settings.scalableArabicFont(base: 20, relativeTo: .body)
                                    : .body
                            )
                            .arabicFontDesign(custom: useQuranicFontForLetter && settings.quranUsesCustomArabicFace)
                            .foregroundColor(.secondary)
                    }

                    if let length = tashkeel.length {
                        HStack {
                            Text("Length")
                            Spacer()
                            Text(length)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let root = tashkeel.root, let rootMeaning = tashkeel.rootMeaning {
                    Section(header: Text("WHERE THE NAME COMES FROM")) {
                        HStack {
                            Text("Root")
                            Spacer()
                            Text(root)
                                .font(
                                    useQuranicFontForLetter
                                        ? settings.scalableArabicFont(base: 20, relativeTo: .body)
                                        : .body
                                )
                                .arabicFontDesign(custom: useQuranicFontForLetter && settings.quranUsesCustomArabicFace)
                                .foregroundColor(settings.accentColor.color)
                        }

                        Text(rootMeaning)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }

                if let howTo = tashkeel.howTo {
                    Section(header: Text("HOW TO SAY IT")) {
                        Text(howTo)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .applyConditionalListStyle()
            .navigationTitle(tashkeel.english)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
            #endif
        }
    }
}

struct HamzaPracticeRow: View {
    @ObservedObject var settings = Settings.shared

    let letterData: LetterData
    let useQuranicFontForLetter: Bool

    /// U+0652 SUKUN, written onto the closing consonant of each closed syllable (أَبْ, not أَب): these rows
    /// teach "hamza + vowel + stopped letter", and without the sukoon the final letter reads as unmarked.
    private static let sukoon = "\u{0652}"

    private var hamzaShortSyllables: [(latin: String, arabic: String)] {
        let s = letterData.sound
        let l = letterData.letter + Self.sukoon
        return [
            ("a" + s, "أَ" + l),
            ("i" + s, "إِ" + l),
            ("u" + s, "أُ" + l)
        ]
    }

    private var hamzaLongSyllablesBasic: [(latin: String, arabic: String)] {
        let s = letterData.sound
        let l = letterData.letter + Self.sukoon
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
                    if !settings.hideEnglishInArabicLetters {
                        Text(syllable.latin)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(syllable.arabic)
                        .font(
                            useQuranicFontForLetter
                                ? settings.scalableArabicFont(base: 28, relativeTo: .title)
                                : .title
                        )
                        .arabicFontDesign(custom: useQuranicFontForLetter && settings.quranUsesCustomArabicFace)
                        .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, useQuranicFontForLetter ? 0 : 8)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    settings.hapticFeedback()
                    ArabicSpeech.shared.speak(syllable.arabic)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
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
    @ObservedObject var settings = Settings.shared

    let letterData: LetterData
    let baseSound: String
    let useQuranicFontForLetter: Bool

    /// a → i → u, the order every other table on this screen uses (and the order the vowels are taught in). This
    /// row used to run a → u → i, which was the odd one out.
    private var syllables: [(latin: String, arabic: String)] {
        [
            (baseSound + "a", letterData.letter + "َ"),
            (baseSound + "i", letterData.letter + "ِ"),
            (baseSound + "u", letterData.letter + "ُ")
        ]
    }

    var body: some View {
        // Arabic reads right-to-left, so the syllable columns run right-to-left (first one on the right).
        HStack(spacing: 20) {
            ForEach(syllables, id: \.latin) { syllable in
                VStack {
                    if !settings.hideEnglishInArabicLetters {
                        Text(syllable.latin)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(syllable.arabic)
                        .font(
                            useQuranicFontForLetter
                                ? settings.scalableArabicFont(base: 28, relativeTo: .title)
                                : .title
                        )
                        .arabicFontDesign(custom: useQuranicFontForLetter && settings.quranUsesCustomArabicFace)
                        .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, useQuranicFontForLetter ? 0 : 8)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    settings.hapticFeedback()
                    ArabicSpeech.shared.speak(syllable.arabic)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct ArabicLetterRow: View, Equatable {
    @ObservedObject private var settings = Settings.shared
    let sizeIndex: Int
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
        fontArabic: String = Settings.shared.nonQuranArabicFontName,
        searchQuery: String = ""
    ) {
        self.letterData = letterData
        self.isFavorite = isFavorite ?? Settings.shared.isLetterFavorite(letterData: letterData)
        self.accentColor = accentColor
        self.useFontArabic = useFontArabic
        self.fontArabic = fontArabic
        self.searchQuery = searchQuery
        // Snapshotted so `==` sees the size slider: the body applies `settings.arabicLetterDynamicTypeSize`,
        // and an Equatable view must not ignore state that changes its rendering.
        self.sizeIndex = Settings.shared.arabicLetterSizeIndex
    }

    /// The three Arabic `Text`s below all render in a bundled face under exactly this condition, so it is also the
    /// condition for opting them out of the app-wide rounded design.
    private var usesCustomArabicFace: Bool {
        useFontArabic && !letterData.isNonArabicScriptLetter && fontArabic != Settings.systemArabicFontName
    }

    var body: some View {
        // A letter can also match on its hidden `name` / weight keywords / rule, so only guarantee a
        // highlight on a displayed field (transliteration or the letter glyph) when that field itself
        // contains the query - otherwise leave it un-highlighted rather than force-color an unrelated field.
        let query = searchQuery.lowercased()
        let matchedTransliteration = !query.isEmpty && letterData.transliteration.lowercased().contains(query)
        let matchedLetter = !query.isEmpty && letterData.letter.lowercased().contains(query)
        return NavigationLink(destination: LazyDestination { ArabicLetterView(letterData: letterData) }) {
            // The row carries what the grid tile carries - the letter, its Arabic name, its transliteration and
            // its three joined forms - instead of a transliteration marooned at one edge and a glyph at the
            // other. The letter leads in the glass badge the Quran and 99 Names rows put their NUMBER in; here
            // there is no number, so the letter itself takes that place - clear when it's an ordinary letter,
            // tinted in the accent when it's a favorite, so favorites are visible while scrolling.
            HStack(spacing: 12) {
                HighlightedSnippet(
                    source: letterData.letter,
                    term: searchQuery,
                    font: (useFontArabic && !letterData.isNonArabicScriptLetter)
                        ? Font.arabic(fontArabic, size: 24, relativeTo: .title2)
                        : .title2,
                    accent: accentColor.color,
                    fg: accentColor.color,
                    guaranteeMatch: matchedLetter
                )
                .arabicFontDesign(custom: usesCustomArabicFace)
                .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: 42, height: 38)
                .conditionalGlassEffect(
                    clear: !isFavorite,
                    rectangle: true,
                    useColor: isFavorite ? 0.25 : nil,
                    customTint: isFavorite ? accentColor.color : nil
                )
                // Tapping the badge favorites the letter, the way tapping the Quran's glass number pill bookmarks
                // an ayah. It has to outrank the row's own tap, or the NavigationLink swallows it and pushes the
                // letter instead; the rest of the row still navigates.
                .contentShape(Rectangle())
                .highPriorityGesture(
                    TapGesture().onEnded {
                        settings.hapticFeedback()
                        settings.toggleLetterFavorite(letterData: letterData)
                    }
                )
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(isFavorite ? "Unfavorite \(letterData.transliteration)"
                                               : "Favorite \(letterData.transliteration)")

                VStack(alignment: .leading, spacing: 1) {
                    Text(letterData.name)
                        .font(
                            (useFontArabic && !letterData.isNonArabicScriptLetter)
                                ? Font.arabic(fontArabic, size: 16, relativeTo: .subheadline)
                                : .subheadline
                        )
                        .arabicFontDesign(custom: usesCustomArabicFace)
                        .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    HighlightedSnippet(
                        source: letterData.transliteration,
                        term: searchQuery,
                        font: .caption,
                        accent: accentColor.color,
                        fg: .secondary,
                        guaranteeMatch: matchedTransliteration
                    )
                    .lineLimit(1)
                }

                Spacer(minLength: 4)

                // `forms` is [final, medial, initial]; reversed so this RTL-rendered text puts the initial form
                // on the right, matching the detail view.
                Text(letterData.forms.prefix(3).reversed().joined(separator: "\u{2002}"))
                    .font(
                        (useFontArabic && !letterData.isNonArabicScriptLetter)
                            ? Font.arabic(fontArabic, size: 13, relativeTo: .caption)
                            : .caption
                    )
                    .arabicFontDesign(custom: usesCustomArabicFace)
                    .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.vertical, 2)
        }
        #if os(iOS)
        .swipeActions(edge: .leading) { favButton() }
        .swipeActions(edge: .trailing) { favButton() }
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

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.letterData == rhs.letterData &&
        lhs.isFavorite == rhs.isFavorite &&
        lhs.accentColor == rhs.accentColor &&
        lhs.useFontArabic == rhs.useFontArabic &&
        lhs.fontArabic == rhs.fontArabic &&
        lhs.searchQuery == rhs.searchQuery &&
        lhs.sizeIndex == rhs.sizeIndex
    }
}

/// The Western digit in a badge on the left, the Arabic name and its transliteration in the middle, the Arabic
/// numeral large on the right - the same left-to-right reading order as a letter row, instead of the three
/// loose columns it used to be.
struct ArabicNumberRow: View {
    @ObservedObject private var settings = Settings.shared
    let numberData: (number: String, name: String, transliteration: String, englishNumber: String)

    var body: some View {
        HStack(spacing: 12) {
            Text(numberData.englishNumber)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundColor(.secondary)
                .frame(minWidth: 26)
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(settings.accentColor.color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(numberData.name)
                    .font(
                        settings.useFontArabic
                            ? settings.scalableArabicFont(base: 17, relativeTo: .subheadline)
                            : .subheadline
                    )
                    .arabicFontDesign(custom: settings.useFontArabic && settings.quranUsesCustomArabicFace)
                    .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                    .foregroundColor(.primary)

                Text(numberData.transliteration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 4)

            Text(numberData.number)
                .font(
                    settings.useFontArabic
                        ? settings.scalableArabicFont(base: 26, relativeTo: .title2)
                        : .title2
                )
                .arabicFontDesign(custom: settings.useFontArabic && settings.quranUsesCustomArabicFace)
                .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                .foregroundColor(settings.accentColor.color)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        // Negative: the Arabic numeral's line box is taller than the glyph (the Quranic faces leave room for
        // tashkeel above it), so the row already carries more height than it looks like it does.
        .padding(.vertical, -2)
        #if os(iOS)
        // Tapping a number blows it up full screen, exactly like a letter or a name.
        .contentShape(Rectangle())
        .onTapGesture {
            settings.hapticFeedback()
            FocusOverlayPresenter.shared.present(.number(numberData))
        }
        #endif
    }
}

#if os(iOS)
/// The number as a tile, mirroring `ArabicLetterGridTile` so the grid mode covers the whole screen and not
/// just the letters.
struct ArabicNumberGridTile: View {
    @ObservedObject private var settings = Settings.shared
    let numberData: (number: String, name: String, transliteration: String, englishNumber: String)

    var body: some View {
        Button {
            settings.hapticFeedback()
            FocusOverlayPresenter.shared.present(.number(numberData))
        } label: {
            VStack(spacing: 3) {
                // Fixed box for the same reason as the letter tiles: the Arabic face's line box is much taller
                // than the glyph, and the difference is dead space.
                Text(numberData.number)
                    .font(
                        settings.useFontArabic
                            ? settings.scalableArabicFont(base: 30, relativeTo: .title)
                            : .title
                    )
                    .arabicFontDesign(custom: settings.useFontArabic && settings.quranUsesCustomArabicFace)
                    .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(height: 34)
                    .fixedSize(horizontal: false, vertical: true)

                Text(numberData.englishNumber)
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundColor(.primary)

                Text(numberData.transliteration)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            .conditionalGlassEffect(clear: true, rectangle: true)
        }
        .buttonStyle(.plain)
    }
}
#endif

struct StopSignInfo: Identifiable {
    let title: String
    let symbol: String

    var id: String { symbol + title }
}

struct StopInfoRow: View {
    @ObservedObject private var settings = Settings.shared

    let title: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            // These are mushaf glyphs (۩ ۞ قلى ج صلى ...), not UI text - they belong in the Quranic face, and
            // read wrong in SF Rounded.
            Text(symbol)
                .font(
                    settings.islamUsesCustomArabicFace
                        ? Font.arabic(settings.nonQuranArabicFontName, size: 20, relativeTo: .headline)
                        : .headline.weight(.semibold)
                )
                .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
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

#if os(iOS)
/// A letter as a tile, mirroring `NameGridTile` on the 99 Names screen. Tapping opens the letter's detail - 
/// the same primary action the list row has.
struct ArabicLetterGridTile: View, Equatable {
    @ObservedObject private var settings = Settings.shared

    let letterData: LetterData
    let isFavorite: Bool
    let accentColor: AccentColor
    let useFontArabic: Bool
    let fontArabic: String
    /// Snapshot of the size slider, folded into `==` because the body scales with it.
    var sizeIndex: Int = Settings.shared.arabicLetterSizeIndex

    /// `onTap` is deliberately not compared (closures cannot be) - it is stable per call site, and every
    /// input that changes what the tile DRAWS is compared, so skipping the body on equality is safe.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.letterData == rhs.letterData &&
        lhs.isFavorite == rhs.isFavorite &&
        lhs.accentColor == rhs.accentColor &&
        lhs.useFontArabic == rhs.useFontArabic &&
        lhs.fontArabic == rhs.fontArabic &&
        lhs.sizeIndex == rhs.sizeIndex
    }

    /// Letters from other scripts (پ, چ, ژ) aren't in the Quranic font, so they fall back to the system one.
    private var glyphFont: Font {
        useFontArabic && !letterData.isNonArabicScriptLetter
            ? Font.arabic(fontArabic, size: 30, relativeTo: .title)
            : .title
    }

    /// Whether `glyphFont` (and the forms line below it) resolve to a bundled face, and so must opt out of the
    /// app-wide rounded design.
    private var usesCustomArabicFace: Bool {
        useFontArabic && !letterData.isNonArabicScriptLetter && fontArabic != Settings.systemArabicFontName
    }

    /// The tile reports the tap instead of carrying its own `NavigationLink`. A per-tile link - even a hidden
    /// one behind the tile - pushes *every* letter at once, because the whole `LazyVGrid` is a single `List`
    /// row and one tap activates every link inside that row. `ArabicView` owns one link for the grid.
    let onTap: () -> Void

    var body: some View {
        Button {
            settings.hapticFeedback()
            onTap()
        } label: {
            tile
        }
        .buttonStyle(.plain)
    }

    /// Sized to the glyph rather than to the Quranic face's (very tall) line box - but it grows with the size
    /// slider, or the letter would be pinned at whatever fits 34pt no matter where the slider sat.
    private var glyphBoxHeight: CGFloat {
        let steps = Settings.arabicLetterDynamicTypeSizes.count - 1
        let index = min(max(settings.arabicLetterSizeIndex, 0), steps)
        return 34 + CGFloat(index) * 7
    }

    private var tile: some View {
        Group {
            VStack(spacing: 3) {
                Text(letterData.letter)
                    .font(glyphFont)
                    .arabicFontDesign(custom: usesCustomArabicFace)
                    .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                    .foregroundColor(accentColor.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(height: glyphBoxHeight)
                    .fixedSize(horizontal: false, vertical: true)

                Text(letterData.transliteration)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                // Em spaces, not a plain space: the initial/medial/final forms of a letter run together
                // otherwise, and they read as one word. One `Text` (rather than an `HStack`) so all three
                // forms shrink by the same factor when the tile is tight. `forms` is [final, medial, initial];
                // reversed here so this RTL-rendered `Text` places the initial form on the right, matching the
                // per-letter detail view's left-to-right layout.
                Text(letterData.forms.prefix(3).reversed().joined(separator: "\u{2002}"))
                    .font(useFontArabic && !letterData.isNonArabicScriptLetter
                          ? Font.arabic(fontArabic, size: 12, relativeTo: .caption2)
                          : .caption2)
                    .arabicFontDesign(custom: usesCustomArabicFace)
                    .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(height: 18)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            // Clear unless it's a favorite - same as the 99 Names and surah grids.
            .conditionalGlassEffect(
                clear: !isFavorite,
                rectangle: true,
                useColor: isFavorite ? 0.25 : nil,
                customTint: isFavorite ? accentColor.color : nil
            )
            .gridFavoriteStar(
                isFavorite: isFavorite,
                accent: accentColor.color,
                accessibilityName: letterData.transliteration
            ) {
                settings.toggleLetterFavorite(letterData: letterData)
            }
        }
    }
}
#endif
