import SwiftUI

struct TashkeelLettersView: View {
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @ObservedObject private var settings = Settings.shared

    private static let shaddahMark = arabicShaddahMark

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

    /// The one row being taught right now. Shared with the per-letter practice tables, so exactly one
    /// thing anywhere is ever selected - and only the selection carries a play button.
    @ObservedObject private var selection = ArabicPracticeSelection.shared

    /// Letters whose shaddah line is written out as the two letters the shaddah stands for.
    @State private var expandedShaddahLetters: Set<Int> = []

    /// Vowels whose row in the shaddah detail sheet is written out the same way.
    @State private var expandedDetailVowels: Set<String> = []

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
                allMarksSection
            }
            .themedListRowBackground()

        }
        .applyConditionalListStyle()
        .navigationTitle("Tashkeel")
        .onDisappear {
            ArabicSpeech.shared.stop()
            ArabicPracticeSelection.shared.clear()
        }
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
            .navigationViewStyle(.stack)
            .smallMediumSheetPresentation()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HideEnglishToolbarButton()
            }
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
                    .font(useQuranicFont ? settings.scalableIslamArabicFont(base: 24, relativeTo: .title2) : .title2)
                    .arabicFontDesign(custom: useQuranicFont && settings.islamUsesCustomArabicFace)
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

    /// The grid read the other way round, all at once: one row per letter carrying every core mark side by
    /// side - the short vowels, the sukoon, the three tanween, and beneath them the shaddah with each vowel.
    /// The grid above answers "one mark on every letter"; this answers "every mark on one letter" without
    /// touching the picker. The long vowels and madd forms stay in the grid only - ten glyphs to a line is
    /// already the limit of legible.
    private static let allMarksCoreNames = ["Fatha", "Kasra", "Damma", plainSukoonName, "Fathatayn", "Kasratayn", "Dammatayn"]

    /// بَ بِ بُ بْ بًا بٍ بٌ - written fatha-first, so under right-to-left rendering the fatha lands on the
    /// right, the order the marks are taught in. Em-spaced like the letter forms, so the groups stay separate.
    private func allMarksLine(_ letter: LetterData) -> String {
        Self.allMarksCoreNames
            .compactMap { name in tashkeels.first { $0.english == name }?.tashkeelMark }
            .map { letter.letter + $0 }
            .joined(separator: "\u{2002}")
    }

    /// بَّ بِّ بُّ - the shaddah carrying each short vowel, the second line of each row.
    private func allMarksShaddahLine(_ letter: LetterData) -> String {
        ["\u{064E}", "\u{0650}", "\u{064F}"]
            .map { letter.letter + Self.shaddahMark + $0 }
            .joined(separator: "\u{2002}")
    }

    /// The same shaddah line written out as what a shaddah IS: the letter with sukoon, then the letter
    /// carrying the vowel. The sukoon is whichever script the letter practice is set to.
    private func allMarksShaddahExpandedLine(_ letter: LetterData) -> String {
        ["\u{064E}", "\u{0650}", "\u{064F}"]
            .map { shaddahWrittenOut(letter: letter.letter, vowel: $0) }
            .joined(separator: "\u{2002}")
    }

    private var allMarksSection: some View {
        Section {
            ForEach(letters) { letter in
                allMarksRow(letter)
            }
        } header: {
            Text("EVERY MARK ON EVERY LETTER")
        } footer: {
            Text("Read each row right to left: fatha, kasra, damma, sukoon, then the three tanween - and beneath them the shaddah carrying each vowel. The \"an\" tanween is written with its silent alif, as it appears at the end of words. Tap a row to select it - the selected row offers play, and a chevron that writes the shaddah line out beneath as the two letters it stands for.")
        }
    }

    private func allMarksRow(_ letter: LetterData) -> some View {
        let id = "allMarks:\(letter.id)"
        let isSelected = selection.isSelected(id)
        // Expansion only SHOWS on the selected row (the chevron lives on the selection, so a
        // deselected row must never be stuck open with no control to close it). The set remembers
        // the choice, so re-selecting the letter comes back expanded.
        let isExpanded = isSelected && expandedShaddahLetters.contains(letter.id)

        return HStack(alignment: .center, spacing: 10) {
            // A FIXED leading slot (user rule: selecting must never resize the letters - the controls
            // used to be INSERTED here, and the width they took scaled the whole Arabic line down).
            // Unselected it carries the reading; selected, the chevron and play stack into the same
            // slot - so the Arabic keeps its exact size either way.
            Group {
                if isSelected {
                    VStack(spacing: 5) {
                        ShaddahExpandButton(isExpanded: isExpanded) {
                            if isExpanded {
                                expandedShaddahLetters.remove(letter.id)
                            } else {
                                expandedShaddahLetters.insert(letter.id)
                            }
                        }

                        PracticeListenButton(text: allMarksLine(letter))
                    }
                } else if !settings.hideEnglishInArabicLetters {
                    Text(letter.transliteration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .frame(width: 34)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 0) {
                Text(allMarksLine(letter))
                Text(allMarksShaddahLine(letter))
                // The chevron ADDS the written-out spelling beneath the shaddah line - the normal
                // shaddah and its sukoon-decomposed form read together (user rule), instead of the
                // old in-place swap that hid what the expansion was explaining.
                if isExpanded {
                    Text(allMarksShaddahExpandedLine(letter))
                }
            }
            .font(useQuranicFont ? settings.scalableIslamArabicFont(base: 20, relativeTo: .title3) : .title3)
            .arabicFontDesign(custom: useQuranicFont && settings.islamUsesCustomArabicFace)
            .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        // The wash reaches the row's full height (user rule), not just the text band.
        .arabicPracticeSelection(isSelected, hInset: -8, vInset: -6)
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation(.easeInOut) { selection.toggle(id) }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(letter.transliteration) with every mark\(isSelected ? ", selected" : "")")
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
                .font(useQuranicFont ? settings.scalableIslamArabicFont(base: 28, relativeTo: .title) : .title)
                .arabicFontDesign(custom: useQuranicFont && settings.islamUsesCustomArabicFace)
                .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(height: glyphBoxHeight)
                .fixedSize(horizontal: false, vertical: true)

            // The reading is the answer to the marked glyph above it, so it obeys the same Hide English flag
            // the per-letter tables do - this screen used to show it regardless, which made the toggle look
            // broken when you arrived here from the alphabet's menu.
            if !settings.hideEnglishInArabicLetters {
                Text(reading(letter))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
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
                        let isExpanded = expandedDetailVowels.contains(vowel.english)

                        HStack {
                            // The same chevron the hamza practice table carries: it writes the doubling
                            // out instead of only describing it in the footer.
                            ShaddahExpandButton(isExpanded: isExpanded) {
                                if isExpanded {
                                    expandedDetailVowels.remove(vowel.english)
                                } else {
                                    expandedDetailVowels.insert(vowel.english)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Shaddah + \(vowel.english)")
                                    .font(.subheadline.weight(.semibold))

                                // The mark's NAME stays (it's what the row is about); only the reading -
                                // the answer - follows Hide English, as in `TashkeelDetailSheet`.
                                if !settings.hideEnglishInArabicLetters {
                                    Text(isExpanded
                                         ? sound + "-" + sound + vowel.transliteration
                                         : sound + sound + vowel.transliteration)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            // The chevron ADDS the written-out spelling beneath the shaddah form - both
                            // read together (user rule), never an in-place swap.
                            VStack(alignment: .trailing, spacing: 0) {
                                Text(letter.letter + Self.shaddahMark + vowel.tashkeelMark)

                                if isExpanded {
                                    Text(shaddahWrittenOut(letter: letter.letter, vowel: vowel.tashkeelMark))
                                }
                            }
                            .font(useQuranicFont ? settings.scalableIslamArabicFont(base: 30, relativeTo: .title) : .title)
                            .arabicFontDesign(custom: useQuranicFont && settings.islamUsesCustomArabicFace)
                            .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .multilineTextAlignment(.trailing)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("\(letter.transliteration.uppercased()) WITH SHADDAH")
                } footer: {
                    Text("A shaddah doubles the letter: the first is silent (sukoon) and the second carries the vowel. It never appears at the start of a word. Press the chevron to see the doubling written out beneath - the letter with sukoon, then the letter with its vowel.")
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

#if os(iOS)
/// The eye toggle for `settings.hideEnglishInArabicLetters` - the same control the Arabic Alphabet screen
/// carries in its sort menu, as a toolbar button for the screens that have no menu (the per-letter detail
/// and the Tashkeel table). One setting, so hiding the readings on any of them hides them on all.
///
/// A standalone struct rather than a computed property on either screen: it is the only thing on those
/// screens that redraws when the flag flips, so the toggle owns the observation.
struct HideEnglishToolbarButton: View {
    @ObservedObject private var settings = Settings.shared

    var body: some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.hideEnglishInArabicLetters.toggle()
            }
        } label: {
            Image(systemName: settings.hideEnglishInArabicLetters ? "eye.slash" : "eye")
        }
        .accessibilityLabel(settings.hideEnglishInArabicLetters ? "Show English" : "Hide English")
        .tint(settings.accentColor.accent2)
    }
}
#endif

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

    /// One of the five bounce letters (قطب جد) - the letter page names the rule right where a learner
    /// meets the letter (user rule).
    private var isQalqalahLetter: Bool {
        letterData.letter.count == 1 && TajweedRules.qalqalahLetters.contains(letterData.letter.first!)
    }

    /// Whether this page shows any English readings the eye toggle can hide - the harakaat/hamza practice
    /// tables, the non-Arabic vowel row, or the taa marbuuTah worked examples. Letters without them (the
    /// hamza forms) have nothing for the toggle to do, so it isn't offered and the name label ignores the flag.
    private var hasHideableEnglish: Bool {
        letterData.showTashkeel || letterData.isNonArabicScriptLetter || isTaaMarbuta || isAlifMaqsurah
    }

    private var isTaaMarbuta: Bool {
        letterData.transliteration == "taa marbuuTah"
    }

    private var isAlifMaqsurah: Bool {
        letterData.transliteration == "alif maqSoorah"
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
                        // The transliteration is the ANSWER to the glyph beside it, so it goes with the rest of
                        // the English when the reader is practising from the Arabic alone.
                        if !settings.hideEnglishInArabicLetters || !hasHideableEnglish {
                            Text(letterData.transliteration)
                                .font(.subheadline)
                        }

                        Spacer()

                        Text(letterData.letter)
                            .font(
                                useQuranicFontForLetter
                                    ? settings.scalableIslamArabicFont(base: 34, relativeTo: .largeTitle)
                                    : .title
                            )
                            .arabicFontDesign(custom: useQuranicFontForLetter && settings.islamUsesCustomArabicFace)
                            .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)

                        Spacer()

                        Text(letterData.name)
                            .font(
                                useQuranicFontForLetter
                                    ? settings.scalableIslamArabicFont(base: 28, relativeTo: .title)
                                    : .title2
                            )
                            .arabicFontDesign(custom: useQuranicFontForLetter && settings.islamUsesCustomArabicFace)
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

            // The five qalqalah letters carry their bounce wherever they appear - name the rule on the
            // letter's own page (user rule), with the glyph in the exact color the Quran reader paints
            // qalqalah so the two surfaces teach each other.
            if isQalqalahLetter {
                Section(header: Text("QALQALAH (BOUNCE LETTER)")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .center, spacing: 12) {
                            Text("\(letterData.transliteration.capitalized) is one of the five qalqalah letters (قُطۡبُ جَدٍّ - ق ط ب ج د). When it carries a sukoon, or you stop on it, it is pronounced with a short, crisp bounce - a quick echo of the letter, never a flat stop. The Quran reader colors it this way when tajweed colors are on.")
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 8)

                            Text(letterData.letter + LetterPracticeSukoon.mark)
                                .font(useQuranicFontForLetter
                                      ? settings.scalableIslamArabicFont(base: 34, relativeTo: .largeTitle)
                                      : .largeTitle)
                                .arabicFontDesign(custom: useQuranicFontForLetter && settings.islamUsesCustomArabicFace)
                                .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                                .foregroundColor(TajweedLegendCategory.qalqalah.color)
                        }

                        NavigationLink(destination: LazyDestination { TajweedFoundationsView() }) {
                            Label("Learn the Qalqalah Rule", systemImage: "book")
                                .font(.body)
                                .foregroundColor(settings.accentColor.color)
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
                                        ? settings.scalableIslamArabicFont(base: 28, relativeTo: .title)
                                        : .title2
                                )
                                .arabicFontDesign(custom: useQuranicFontForLetter && settings.islamUsesCustomArabicFace)
                                .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)

                            Spacer()
                        }
                    }
                }
                .padding(.vertical, useQuranicFontForLetter ? 0 : 2)
            }

            if isTaaMarbuta {
                taaMarbutaPracticeSections
            }

            if isAlifMaqsurah {
                alifMaqsurahPracticeSections
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
                        Text("- **Waw (و)**: As a **vowel** it is the long \"uu\" (also written \"oo\", and shortened to \"u\"), used after a letter with a damma, like in رَسُول (rasool, messenger). As a **consonant** it makes the \"w\" sound, like in وَقَفَ (waqafa, stood).")
                            .font(.body)
                    }

                    if letterData.transliteration == "yaa" {
                        Text("- **Yaa (ي)**: As a **vowel** it is the long \"ee\" (also written \"ii\", and shortened to \"i\"), used after a letter with a kasra, like in كِتَابِي (kitaabi, my book). As a **consonant** it makes the \"y\" sound, like in يَد (yad, hand).")
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

                Section {
                    // Same mark, two scripts - the plain sukoon and the Uthmani one the mushaf prints
                    // (the Tashkeel screen's "Sukoon script" choice, persisted here). It also writes the
                    // sukoon in the expanded shaddah rows below.
                    Toggle("Use Quranic Sukoon", isOn: Binding(
                        get: { settings.quranicSukoonInLetterPractice },
                        set: { newValue in
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) { settings.quranicSukoonInLetterPractice = newValue }
                        }
                    ))
                    .font(.subheadline)
                    .tint(settings.accentColor.color)

                    HamzaPracticeRow(
                        letterData: letterData,
                        useQuranicFontForLetter: useQuranicFontForLetter
                    )
                } header: {
                    Text("WITH HAMZA")
                } footer: {
                    Text("Tap a syllable to select it, then press play to hear it. The last three rows carry a shaddah: select one and press the chevron to see each syllable written out beneath as the two letters the shaddah stands for - the letter with sukoon, then the letter with the tashkeel.")
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
                    Text("In modern Arabic outside of the Quran, Alif Madd usually does not mean a 4, 5, or 6 count Tajweed elongation by itself. It normally represents ءا, so آ is a shortened spelling of ءا.")
                        .font(.body)

                    Text("For example, قُرۡءَان is how it is spelled in the Quran, while outside the Quran it is commonly shortened to قُرآن. Likewise, ءَامِين is commonly written آمِين.")
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
        .onDisappear {
            ArabicSpeech.shared.stop()
            ArabicPracticeSelection.shared.clear()
        }
        #if os(iOS)
        // Every reading on this screen (the transliteration above, the harakaat table, the hamza and
        // non-Arabic practice rows) is spelled out in English - this hides them all so the letter can be
        // practised from the Arabic alone. Same flag as the alphabet screen's menu item. Offered only on
        // pages that actually have readings to hide.
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // The condition lives INSIDE the item (not around it): ToolbarContentBuilder has no
                // buildIf on the iOS 15 target, but an empty ViewBuilder item renders nothing.
                if hasHideableEnglish {
                    HideEnglishToolbarButton()
                }
            }
        }
        #endif
    }

    /// The taa marbuuTah page's worked examples, in the same section grammar as WITH HAMZA above: real words,
    /// practised three ways. First stopping on the ة (it closes to a soft "h"), then continuing through it
    /// (it opens to a full "t"), then unknotting it entirely - the dual and the sound feminine plural turn
    /// the ة into an open ت.
    @ViewBuilder
    private var taaMarbutaPracticeSections: some View {
        Section {
            ArabicExampleRow(
                arabic: "ٱلۡجَنَّة",
                transliteration: "al-jannah",
                note: "Paradise"
            )
            ArabicExampleRow(
                arabic: "رَحۡمَة",
                transliteration: "rahmah",
                note: "Mercy"
            )
            ArabicExampleRow(
                arabic: "صَلَاة",
                transliteration: "salah",
                note: "Prayer"
            )
            ArabicExampleRow(
                arabic: "مَدۡرَسَة",
                transliteration: "madrasah",
                note: "School"
            )
        } header: {
            Text("STOPPING ON IT: SOUNDS LIKE HAA")
        } footer: {
            Text("Stop on a word ending in ة and it closes into a soft \"h\", exactly like a haa.")
        }

        Section {
            ArabicExampleRow(
                arabic: "رَحۡمَةُ ٱللَّهِ",
                transliteration: "rahmatu-llahi",
                note: "The mercy of Allah"
            )
            ArabicExampleRow(
                arabic: "سُورَةُ ٱلۡبَقَرَة",
                transliteration: "suratu-l-baqarah",
                note: "Surah al-Baqarah - the first ة is read \"t\"; the last is stopped on as \"h\""
            )
            ArabicExampleRow(
                arabic: "مَدِينَةُ ٱلنَّبِيِّ",
                transliteration: "madinatu-n-nabiyy",
                note: "The city of the Prophet"
            )
        } header: {
            Text("CONTINUING THROUGH: SOUNDS LIKE TAA")
        } footer: {
            Text("Keep reading into the next word and the ة is pronounced as a full \"t\".")
        }

        Section {
            ArabicExampleRow(
                arabic: "مُسۡلِمَة \u{2190} مُسۡلِمَتَانِ",
                transliteration: "muslimah \u{2192} muslimataan(i)",
                note: "One Muslim woman \u{2192} two: the ة opens into ت"
            )
            ArabicExampleRow(
                arabic: "مُسۡلِمَات",
                transliteration: "muslimaat",
                note: "Muslim women: ـات replaces the ة"
            )
            ArabicExampleRow(
                arabic: "شَجَرَة \u{2190} شَجَرَتَانِ",
                transliteration: "shajarah \u{2192} shajarataan(i)",
                note: "One tree \u{2192} two trees"
            )
            ArabicExampleRow(
                arabic: "صَلَاة \u{2190} صَلَوَات",
                transliteration: "salah \u{2192} salawaat",
                note: "Prayer \u{2192} prayers: this plural brings out a waaw"
            )
        } header: {
            Text("UNKNOTTING INTO AN OPEN TAA")
        } footer: {
            Text("In the dual (ـتَانِ) and the sound feminine plural (ـات) the knot opens: the ة becomes a regular ت.")
        }
    }

    /// The alif maqSoorah page's worked examples, in the taa marbuuTah sections' grammar: first the
    /// Quran's dagger-alif spellings (the small alif above the ى IS the long "aa"), then the pairs that
    /// teach how to tell a final ى-shape apart from a dotless yaa - in the mushaf both are written
    /// without dots, so the vowel BEFORE the letter is what decides it.
    @ViewBuilder
    private var alifMaqsurahPracticeSections: some View {
        Section {
            ArabicExampleRow(
                arabic: "عَلَىٰ",
                transliteration: "'alaa",
                note: "Upon - the dagger alif above the ى writes the long \"aa\""
            )
            ArabicExampleRow(
                arabic: "إِلَىٰ",
                transliteration: "ilaa",
                note: "To / toward"
            )
            ArabicExampleRow(
                arabic: "مُوسَىٰ",
                transliteration: "Musaa",
                note: "Musa (Moses) - names ending in the \"aa\" sound use it too"
            )
            ArabicExampleRow(
                arabic: "هُدٗى",
                transliteration: "hudan",
                note: "Guidance - with tanween the maqsurah still looks the same"
            )
        } header: {
            Text("WITH THE DAGGER ALIF")
        } footer: {
            Text("In the Quran the alif maqSoorah very often carries a small dagger alif (ىٰ). That tiny mark IS the alif: it writes the 2-count \"aa\" the letter stands for.")
        }

        Section {
            ArabicExampleRow(
                arabic: "ٱهۡتَدَىٰ",
                transliteration: "ihtadaa",
                note: "FATHA before it \u{2192} alif maqSoorah, read \"aa\""
            )
            ArabicExampleRow(
                arabic: "فِي",
                transliteration: "fee",
                note: "KASRA before it \u{2192} a yaa, read \"ee\" - dotless in the mushaf"
            )
            ArabicExampleRow(
                arabic: "ٱلَّذِي",
                transliteration: "alladhee",
                note: "Kasra before \u{2192} yaa again, even though it looks identical"
            )
        } header: {
            Text("MAQSURAH OR YAA? THE VOWEL BEFORE TELLS YOU")
        } footer: {
            Text("The mushaf writes the final yaa without dots too, so the SHAPE cannot tell you which letter it is. Read the vowel before it: after a fatha (or under a dagger alif) it is alif maqSoorah and sounds \"aa\"; after a kasra it is yaa and sounds \"ee\". Outside the Quran, modern print dots the yaa (ي) and leaves the maqsurah bare (ى), so there the dots decide.")
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
                    Text("\"Taa marbuuTah\" means \"tied/knotted taa.\" It is written as a haa (ه) with the two dots of taa (ت) above it, and it is used to indicate the feminine gender in Arabic.")
                    Text("It is typically added to the end of a noun to show that the noun is feminine. For example, the Arabic word for teacher is \"مُعَلِّم\" (mu'allim) for a male and \"مُعَلِّمَة\" (mu'allimah) for a female.")
                    Text("Its pronunciation depends on whether you stop or keep going: if you continue reading past the word, it is pronounced as a taa (\"t\"), as in \"مُعَلِّمَةُ ٱلۡفَصۡلِ\" (mu'allimatul-faSl). If you stop on the word, it is pronounced as a haa (\"h\"), as in \"mu'allimah.\"")
                    Text("When a singular feminine word is made plural, the taa marbuuTah is unknotted: it is removed and an alif and a regular taa (ـات) are added in its place. For example, \"مُعَلِّمَة\" (mu'allimah) becomes \"مُعَلِّمَات\" (mu'allimaat).")
                    Text("If the feminine word ends in a hamza instead, like \"سَمَآء\" (samaa', sky), the plural is formed by adding a waaw, then an alif and a taa: \"سَمَآء\" becomes \"سَمَاوَات\" (samaawaat).")
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
                        Text("Madd Munfasil (مَدّ مُنفَصِل) means \"separated Madd.\" Munfasil means separated because the Madd letter comes at the end of one word and the next word begins with hamzah, so it may be read 2, 4, or 5 counts depending on the recitation style.")
                        Text("Madd Lazim (مَدّ لَازِم) means \"necessary Madd.\" Lazim means necessary or required because the Madd letter is followed by a permanent sukoon or shaddah, so it is lengthened 6 counts.")
                        Text("These are special mudood (مُدُود), the plural of Madd. They happen when natural Madd is no longer just 2 counts because hamzah, sukoon, or shaddah changes the rule.")
                    }
                    .font(.body)
                } else if data.transliteration == "alif maqSoorah" {
                    Group {
                        Text("Alif maqSoorah is an alif written in the SHAPE of a dotless yaa (ى). It only ever appears at the end of a word, and it is pronounced exactly like a regular alif - a 2-count \"aa\".")
                        Text("In the Quran it usually carries a small dagger alif above it (ىٰ), as in عَلَىٰ and مُوسَىٰ - that tiny mark IS the alif sound, written small. The examples below practise it.")
                        Text("Telling it apart from yaa: the mushaf writes the final yaa without dots too, so the shape alone cannot decide. Read the vowel before the letter - a fatha before it means alif maqSoorah (\"aa\", as in ٱهۡتَدَىٰ); a kasra before it means yaa (\"ee\", as in فِي and ٱلَّذِي).")
                    }
                    .font(.body)
                } else if data.transliteration == "laam alif" {
                    // The case used to check "laa", which is not this letter's transliteration - so the
                    // PURPOSE section rendered empty for the one ligature letter (user report).
                    Group {
                        Text("When laam (ل) is followed by alif (ا), the two must be written as one joined shape: لا. It is the only compulsory ligature in Arabic script - writing them side by side unjoined is considered incorrect - which is why it is taught alongside the alphabet.")
                        Text("The sound does not change: read it simply as laam, then the long alif. Order matters, though - the definite article ٱل is alif then laam, so no ligature forms there.")
                        Text("You meet it constantly in the Quran, most familiarly as the word of negation لَا (\"no\" / \"not\") and in لَآ إِلَٰهَ إِلَّا ٱللَّهُ.")
                    }
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

// MARK: - Practice tables: selection, playback, and the shaddah written out

/// Which single cell or row of the Arabic practice tables is being taught right now.
///
/// The tables used to SPEAK on tap, which meant a teacher could not point at a combination without the
/// device blurting it out. Now a tap only SELECTS - the selection is drawn with the accent wash the
/// Tashkeel screen's chosen mark chip carries - and the play button appears on (and speaks for) the
/// selected one alone. Tapping the selection again clears it.
///
/// One shared object rather than per-table state: the selection is exactly one thing per screen, and the
/// tables are separate views (three `TashkeelRow` chunks, the hamza table, the example rows) that would
/// otherwise each keep their own.
@MainActor
final class ArabicPracticeSelection: ObservableObject {
    static let shared = ArabicPracticeSelection()

    private init() {}

    @Published private(set) var selectedID: String?

    func isSelected(_ id: String) -> Bool { selectedID == id }

    /// Selects `id`, or clears it when it is already the selection. Deselecting also stops whatever the
    /// old selection was saying - the play button that started it is gone.
    func toggle(_ id: String) {
        if selectedID == id {
            selectedID = nil
            ArabicSpeech.shared.stop()
        } else {
            selectedID = id
        }
    }

    /// Leaving a screen drops the selection, so arriving back never shows a stale highlight.
    func clear() {
        guard selectedID != nil else { return }
        selectedID = nil
        ArabicSpeech.shared.stop()
    }
}

extension View {
    /// The one "this is the combination being taught" treatment on the Arabic screens: the accent wash and
    /// hairline `TashkeelLettersView`'s chosen mark chip already uses. The insets let a full-width list row
    /// bleed its wash past the text without the text itself moving when the selection changes.
    func arabicPracticeSelection(
        _ isSelected: Bool,
        cornerRadius: CGFloat = 12,
        hInset: CGFloat = 0,
        vInset: CGFloat = 0
    ) -> some View {
        let accent = Settings.shared.accentColor.color
        return background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(accent.opacity(isSelected ? 0.18 : 0))
                .padding(.horizontal, hInset)
                .padding(.vertical, vInset)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(isSelected ? accent : .clear, lineWidth: 1.5)
                .padding(.horizontal, hInset)
                .padding(.vertical, vInset)
        )
    }
}

/// The play control that appears on the SELECTED practice cell or row - the Adhkar screen's Listen/Stop
/// button shrunk to fit a table. It renders nothing when the device has no Arabic voice; the selection
/// highlight still works, because pointing at a combination is most of what it is for.
struct PracticeListenButton: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var speech = ArabicSpeech.shared

    let text: String

    @ViewBuilder
    var body: some View {
        if speech.isAvailable {
            let isSpeaking = speech.currentText == text
            Button {
                settings.hapticFeedback()
                if isSpeaking {
                    speech.stop()
                } else {
                    speech.speak(text)
                }
            } label: {
                Image(systemName: isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
                    .conditionalGlassEffect(circle: true)
            }
            .buttonStyle(.plain)
            // The tables render right-to-left; the button is an icon, and must not be mirrored with them.
            .environment(\.layoutDirection, .leftToRight)
            .accessibilityLabel(isSpeaking ? "Stop" : "Hear it")
        }
    }
}

/// The chevron that writes a shaddah out as the two letters it stands for, in the app's expand/collapse
/// idiom (`SectionPillHeader`'s accent chevron-in-a-circle).
struct ShaddahExpandButton: View {
    @ObservedObject private var settings = Settings.shared

    let isExpanded: Bool
    let toggle: () -> Void

    var body: some View {
        Button {
            settings.hapticFeedback()
            withAnimation(.easeInOut) { toggle() }
        } label: {
            Image(systemName: isExpanded ? "chevron.down.circle" : "chevron.up.circle")
                .font(.footnote.weight(.semibold))
                .foregroundColor(settings.accentColor.color)
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
                .conditionalGlassEffect(circle: true)
        }
        .buttonStyle(.plain)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityLabel(isExpanded
            ? "Write the shaddah back as one letter"
            : "Write the shaddah out as two letters")
    }
}

/// The one place the practice screens decide which sukoon they draw: the plain U+0652, or the Uthmani
/// U+06E1 a printed mushaf uses, per `settings.quranicSukoonInLetterPractice` (the "Use Quranic Sukoon"
/// toggle in the WITH HAMZA section). The shaddah expansions write a sukoon, so they answer to it too.
enum LetterPracticeSukoon {
    static var mark: String {
        Settings.shared.quranicSukoonInLetterPractice ? "\u{06E1}" : "\u{0652}"
    }
}

/// The shaddah, U+0651.
let arabicShaddahMark = "\u{0651}"

/// A shaddah is a DOUBLED letter, so `بَّ` is really `بْ` + `بَ`: the letter with sukoon, then the same
/// letter carrying the vowel. This rewrites one such syllable that way, and it is the single definition
/// every expand button on these screens uses.
///
/// - Parameters:
///   - prefix: whatever is written before the doubled letter (the hamza seat, or nothing).
///   - letter: the doubled letter.
///   - vowel: the harakah riding on the shaddah - the one the SECOND copy carries.
///   - suffix: whatever follows (the madd letter of a long ending, or nothing).
func shaddahWrittenOut(prefix: String = "", letter: String, vowel: String, suffix: String = "") -> String {
    prefix + letter + LetterPracticeSukoon.mark + letter + vowel + suffix
}

struct TashkeelRow: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject private var selection = ArabicPracticeSelection.shared

    let letterData: LetterData
    let tashkeels: [Tashkeel]
    let useQuranicFontForLetter: Bool

    /// The mark whose detail sheet is open. A tap no longer opens it (nor speaks): a tap SELECTS the cell,
    /// and the selected cell offers the two buttons - hear it, and what the mark is.
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
                let glyph = letterData.letter + tk.tashkeelMark
                let id = "tashkeel:\(letterData.letter):\(tk.english)"
                let isSelected = selection.isSelected(id)

                VStack(spacing: 4) {
                    if !settings.hideEnglishInArabicLetters {
                        Text(reading(tk))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }

                    Text(glyph)
                        .font(
                            useQuranicFontForLetter
                                ? settings.scalableIslamArabicFont(base: 28, relativeTo: .title)
                                : .title
                        )
                        .arabicFontDesign(custom: useQuranicFontForLetter && settings.islamUsesCustomArabicFace)
                        .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, useQuranicFontForLetter ? 0 : 8)

                    // The selection's two actions: hear it, and read what the mark is. Tapping used to do
                    // both at once, unasked - now nothing happens until one of these is pressed.
                    if isSelected {
                        HStack(spacing: 6) {
                            PracticeListenButton(text: glyph)

                            Button {
                                settings.hapticFeedback()
                                selectedTashkeel = tk
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(settings.accentColor.color)
                                    .frame(width: 28, height: 28)
                                    .contentShape(Rectangle())
                                    .conditionalGlassEffect(circle: true)
                            }
                            .buttonStyle(.plain)
                            .environment(\.layoutDirection, .leftToRight)
                            .accessibilityLabel("About \(tk.english)")
                        }
                    }
                }
                .contentShape(Rectangle())
                .arabicPracticeSelection(isSelected, cornerRadius: 10, hInset: -4, vInset: -2)
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { selection.toggle(id) }
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("\(tk.english), read \(reading(tk))\(isSelected ? ", selected" : "")")
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
/// mouth has to do to make it. Opened from the info button on the selected mark.
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
                                    ? settings.scalableIslamArabicFont(base: 64, relativeTo: .largeTitle)
                                    : .system(size: 64)
                            )
                            .arabicFontDesign(custom: useQuranicFontForLetter && settings.islamUsesCustomArabicFace)
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
                                    ? settings.scalableIslamArabicFont(base: 20, relativeTo: .body)
                                    : .body
                            )
                            .arabicFontDesign(custom: useQuranicFontForLetter && settings.islamUsesCustomArabicFace)
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
                                        ? settings.scalableIslamArabicFont(base: 20, relativeTo: .body)
                                        : .body
                                )
                                .arabicFontDesign(custom: useQuranicFontForLetter && settings.islamUsesCustomArabicFace)
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
        .navigationViewStyle(.stack)
    }
}

struct HamzaPracticeRow: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject private var selection = ArabicPracticeSelection.shared

    let letterData: LetterData
    let useQuranicFontForLetter: Bool

    /// Which shaddah rows are currently written out as the two letters they stand for.
    @State private var expandedRows: Set<Int> = []

    /// The sukoon written onto the closing consonant of each closed syllable (with sukoon, not bare):
    /// these rows teach "hamza + vowel + stopped letter", and without the sukoon the final letter reads
    /// as unmarked. Plain U+0652 by default; the section's toggle swaps in the Uthmani U+06E1 the mushaf
    /// prints - and that same choice writes the sukoon in the expanded shaddahs below.
    private var sukoon: String { LetterPracticeSukoon.mark }

    // Every piece these tables are built from, spelled out by code point. A combining mark is invisible
    // in source and easy to reorder by accident; this is teaching material, so the sequences are explicit.
    private static let hamzaSeatFatha = "\u{0623}\u{064E}"   // أَ - hamza on alif with fatha
    private static let hamzaSeatKasra = "\u{0625}\u{0650}"   // إِ - hamza under alif with kasra
    private static let hamzaSeatDamma = "\u{0623}\u{064F}"   // أُ - hamza on alif with damma
    private static let bareHamzaFatha = "\u{0621}\u{064E}"   // ءَ - the standalone hamza with fatha
    private static let alif = "\u{0627}"
    private static let yaa = "\u{064A}"
    private static let waaw = "\u{0648}"
    private static let fatha = "\u{064E}"
    private static let kasra = "\u{0650}"
    private static let damma = "\u{064F}"

    /// One cell of a practice triplet: what is written, how it reads, and - on the shaddah cells only -
    /// the same syllable spelled out as the doubled letter a shaddah actually is.
    private struct Syllable {
        let latin: String
        let arabic: String
        var expandedLatin: String? = nil
        var expandedArabic: String? = nil
    }

    /// The long ending each shaddah row runs through: the harakah, the madd letter it is written with, and
    /// how the pair reads. Fatha + alif, kasra + yaa, damma + waaw - the order every table here uses.
    private static let longEndings: [(vowel: String, madd: String, latin: String)] = [
        (fatha, alif, "aa"),
        (kasra, yaa, "ii"),
        (damma, waaw, "uu")
    ]

    private var hamzaShortSyllables: [Syllable] {
        let s = letterData.sound
        let l = letterData.letter + sukoon
        return [
            Syllable(latin: "a" + s, arabic: Self.hamzaSeatFatha + l),
            Syllable(latin: "i" + s, arabic: Self.hamzaSeatKasra + l),
            Syllable(latin: "u" + s, arabic: Self.hamzaSeatDamma + l)
        ]
    }

    private var hamzaLongSyllablesBasic: [Syllable] {
        let s = letterData.sound
        let l = letterData.letter + sukoon
        return [
            Syllable(latin: "aa" + s, arabic: Self.bareHamzaFatha + Self.alif + l),
            Syllable(latin: "ii" + s, arabic: Self.hamzaSeatKasra + Self.yaa + l),
            Syllable(latin: "uu" + s, arabic: Self.hamzaSeatDamma + Self.waaw + l)
        ]
    }

    private var hamzaLongSyllables: [Syllable] {
        let s = letterData.sound
        let l = letterData.letter
        return [
            Syllable(latin: "a" + s + "aa", arabic: Self.hamzaSeatFatha + l + Self.fatha + Self.alif),
            Syllable(latin: "a" + s + "ii", arabic: Self.hamzaSeatFatha + l + Self.kasra + Self.yaa),
            Syllable(latin: "a" + s + "uu", arabic: Self.hamzaSeatFatha + l + Self.damma + Self.waaw)
        ]
    }

    /// One shaddah row: the hamza seat, then this letter doubled by a shaddah carrying each long ending.
    ///
    /// Collapsed, it is written the way a mushaf writes it - hamza, letter, shaddah, vowel, madd letter.
    /// Expanded, it is written the way it is READ, which is what the shaddah has meant all along: the
    /// letter with sukoon, then the same letter with the tashkeel. Same seat, same letter, same ending;
    /// only the shaddah is unpacked.
    private func shaddahTriplet(seat: String, seatLatin: String) -> [Syllable] {
        let s = letterData.sound
        let l = letterData.letter
        return Self.longEndings.map { ending in
            Syllable(
                latin: seatLatin + s + s + ending.latin,
                arabic: seat + l + arabicShaddahMark + ending.vowel + ending.madd,
                // The hyphen stands where the sukoon does: it marks where the first letter stops.
                expandedLatin: seatLatin + s + "-" + s + ending.latin,
                expandedArabic: shaddahWrittenOut(
                    prefix: seat,
                    letter: l,
                    vowel: ending.vowel,
                    suffix: ending.madd
                )
            )
        }
    }

    private var rows: [[Syllable]] {
        [
            hamzaShortSyllables,
            hamzaLongSyllablesBasic,
            hamzaLongSyllables,
            shaddahTriplet(seat: Self.hamzaSeatFatha, seatLatin: "a"),
            shaddahTriplet(seat: Self.hamzaSeatKasra, seatLatin: "i"),
            shaddahTriplet(seat: Self.hamzaSeatDamma, seatLatin: "u")
        ]
    }

    @ViewBuilder
    private func practiceTriplet(_ syllables: [Syllable], expanded: Bool) -> some View {
        HStack(spacing: 20) {
            ForEach(syllables, id: \.latin) { syllable in
                // Keyed on the COLLAPSED spelling, so expanding a row never drops its selection.
                let id = "hamza:" + syllable.arabic
                let isSelected = selection.isSelected(id)

                VStack(spacing: 4) {
                    if !settings.hideEnglishInArabicLetters {
                        Text(syllable.latin)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }

                    Text(syllable.arabic)
                        .font(
                            useQuranicFontForLetter
                                ? settings.scalableIslamArabicFont(base: 28, relativeTo: .title)
                                : .title
                        )
                        .arabicFontDesign(custom: useQuranicFontForLetter && settings.islamUsesCustomArabicFace)
                        .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, useQuranicFontForLetter ? 0 : 8)

                    // The chevron ADDS the written-out spelling beneath the shaddah form (user rule:
                    // the normal shaddah and its sukoon decomposition read together), instead of the
                    // old in-place swap that hid the very form the expansion explains.
                    if expanded, let expandedArabic = syllable.expandedArabic {
                        Text(expandedArabic)
                            .font(
                                useQuranicFontForLetter
                                    ? settings.scalableIslamArabicFont(base: 28, relativeTo: .title)
                                    : .title
                            )
                            .arabicFontDesign(custom: useQuranicFontForLetter && settings.islamUsesCustomArabicFace)
                            .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, useQuranicFontForLetter ? 0 : 8)

                        if !settings.hideEnglishInArabicLetters, let expandedLatin = syllable.expandedLatin {
                            Text(expandedLatin)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                    }

                    // The play button belongs to the selection alone - a tap anywhere else only selects.
                    if isSelected {
                        PracticeListenButton(text: syllable.arabic)
                    }
                }
                .contentShape(Rectangle())
                .arabicPracticeSelection(isSelected, cornerRadius: 10, hInset: -4, vInset: -2)
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { selection.toggle(id) }
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(isSelected ? "\(syllable.latin), selected" : syllable.latin)
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

                practiceLine(rows[idx], index: idx)
            }
        }
        .padding(.top, 6)
    }

    /// A triplet with its expand control. The control's column is reserved on EVERY row, not just the
    /// shaddah ones, so the three glyphs stay in the same three places all the way down the table -
    /// and so the chevron APPEARING never shifts anything (user rule: selection must not resize).
    /// The chevron itself only exists while one of the row's syllables is selected; expansion shows
    /// only then too, so a deselected row can never be stuck open with no control to close it.
    private func practiceLine(_ syllables: [Syllable], index: Int) -> some View {
        let hasShaddah = syllables.contains { $0.expandedArabic != nil }
        let rowSelected = syllables.contains { selection.isSelected("hamza:" + $0.arabic) }
        let isExpanded = rowSelected && expandedRows.contains(index)

        return HStack(spacing: 2) {
            Group {
                if hasShaddah, rowSelected {
                    ShaddahExpandButton(isExpanded: isExpanded) {
                        if isExpanded {
                            expandedRows.remove(index)
                        } else {
                            expandedRows.insert(index)
                        }
                    }
                }
            }
            .frame(width: 28)

            practiceTriplet(syllables, expanded: isExpanded)
        }
    }
}

struct NonArabicVowelPracticeRow: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject private var selection = ArabicPracticeSelection.shared

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
                let id = "nonArabic:" + syllable.arabic
                let isSelected = selection.isSelected(id)

                VStack(spacing: 4) {
                    if !settings.hideEnglishInArabicLetters {
                        Text(syllable.latin)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(syllable.arabic)
                        .font(
                            useQuranicFontForLetter
                                ? settings.scalableIslamArabicFont(base: 28, relativeTo: .title)
                                : .title
                        )
                        .arabicFontDesign(custom: useQuranicFontForLetter && settings.islamUsesCustomArabicFace)
                        .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, useQuranicFontForLetter ? 0 : 8)

                    // Tapping selects; only the selected syllable carries (and answers to) a play button.
                    if isSelected {
                        PracticeListenButton(text: syllable.arabic)
                    }
                }
                .contentShape(Rectangle())
                .arabicPracticeSelection(isSelected, cornerRadius: 10, hInset: -4, vInset: -2)
                .onTapGesture {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) { selection.toggle(id) }
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel(isSelected ? "\(syllable.latin), selected" : syllable.latin)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

/// One worked example: the Arabic large on the trailing side in the app's Arabic font settings, the
/// transliteration and a one-line English note leading - the shaddah detail rows' shape, shared by the
/// taa marbuuTah teaching sections and the Basic Grammar screen. Tap to SELECT the row - the play button
/// appears on the selection alone - and the English obeys the same Hide English flag every other practice
/// table does.
struct ArabicExampleRow: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject private var selection = ArabicPracticeSelection.shared

    let arabic: String
    let transliteration: String
    let note: String

    private var useQuranicFont: Bool { settings.useFontArabic }

    var body: some View {
        let id = "example:" + arabic
        let isSelected = selection.isSelected(id)

        return HStack(alignment: .center, spacing: 12) {
            if isSelected {
                PracticeListenButton(text: arabic)
            }

            if !settings.hideEnglishInArabicLetters {
                VStack(alignment: .leading, spacing: 2) {
                    Text(transliteration)
                        .font(.subheadline.weight(.semibold))

                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            Text(arabic)
                .font(useQuranicFont ? settings.scalableIslamArabicFont(base: 24, relativeTo: .title2) : .title2)
                .arabicFontDesign(custom: useQuranicFont && settings.islamUsesCustomArabicFace)
                .dynamicTypeSize(settings.arabicLetterDynamicTypeSize...)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .arabicPracticeSelection(isSelected, hInset: -8, vInset: -2)
        .onTapGesture {
            settings.hapticFeedback()
            withAnimation(.easeInOut) { selection.toggle(id) }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(transliteration), \(note)\(isSelected ? ", selected" : "")")
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
                    // The badge is a GLYPH slot: laam alif's full "ل ا - لا" spelling doesn't fit a
                    // 42pt pill at any legible scale (user report: it gets cut off), so the badge shows
                    // the ligature itself and the composite stays in the title and the detail page.
                    source: letterData.letter.components(separatedBy: " - ").last ?? letterData.letter,
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
        // LIST ROWS ONLY. `ArabicLetterGridTile` deliberately has no menu: the grid is a LazyVGrid inside a
        // single List row, so a context menu on a tile lifts the WHOLE row - every tile at once - as its
        // preview. The tile's corner star is the favorite action instead.
        .contextMenu { arabicLetterContextItems(letterData, isFavorite: isFavorite) }
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
                            ? settings.scalableIslamArabicFont(base: 17, relativeTo: .subheadline)
                            : .subheadline
                    )
                    .arabicFontDesign(custom: settings.useFontArabic && settings.islamUsesCustomArabicFace)
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
                        ? settings.scalableIslamArabicFont(base: 26, relativeTo: .title2)
                        : .title2
                )
                .arabicFontDesign(custom: settings.useFontArabic && settings.islamUsesCustomArabicFace)
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
        // LIST ROWS ONLY, same reason as the letter rows - `ArabicNumberGridTile` carries no menu.
        .contextMenu { arabicNumberContextItems(numberData) }
        #endif
    }
}

#if os(iOS)
/// The number as a tile, mirroring `ArabicLetterGridTile` so the grid mode covers the whole screen and not
/// just the letters. No `contextMenu`, for the same reason the letter tiles have none: the grid is one List
/// row, so a menu on a tile lifts every tile at once.
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
                            ? settings.scalableIslamArabicFont(base: 30, relativeTo: .title)
                            : .title
                    )
                    .arabicFontDesign(custom: settings.useFontArabic && settings.islamUsesCustomArabicFace)
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
/// The long-press menu for a single letter, used by `ArabicLetterRow`. A free function rather than a method so
/// the number row beside it can follow the same shape without inheriting the row's state.
///
/// Deliberately NOT used by `ArabicLetterGridTile`: a context menu inside a LazyVGrid-in-a-List-row lifts the
/// whole row (every tile at once) as its preview, so the grid puts its favorite action on the tile's own star.
@ViewBuilder
func arabicLetterContextItems(_ letterData: LetterData, isFavorite: Bool) -> some View {
    let settings = Settings.shared

    Text("Letter Actions")
        .foregroundStyle(.secondary)

    Button {
        settings.hapticFeedback()
        FocusOverlayPresenter.shared.present(.letter(letterData))
    } label: {
        Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
    }

    Button {
        settings.hapticFeedback()
        presentSystemShareSheet(items: [FocusItem.letter(letterData).shareText])
    } label: {
        Label("Share Letter", systemImage: "square.and.arrow.up")
    }

    Divider()

    Button(role: isFavorite ? .destructive : nil) {
        settings.hapticFeedback()
        withAnimation(.easeInOut) {
            settings.toggleLetterFavorite(letterData: letterData)
        }
    } label: {
        Label(isFavorite ? "Unfavorite Letter" : "Favorite Letter",
              systemImage: isFavorite ? "star.fill" : "star")
    }

    Divider()

    Button {
        settings.hapticFeedback()
        UIPasteboard.general.string = letterData.letter
    } label: {
        Label("Copy Letter", systemImage: "doc.on.doc")
    }

    Button {
        settings.hapticFeedback()
        UIPasteboard.general.string = letterData.name
    } label: {
        Label("Copy Arabic Name", systemImage: "doc.on.doc")
    }

    Button {
        settings.hapticFeedback()
        UIPasteboard.general.string = letterData.transliteration
    } label: {
        Label("Copy Transliteration", systemImage: "doc.on.doc")
    }

    Button {
        settings.hapticFeedback()
        // `forms` is [final, medial, initial]; reversed so the copied text reads initial-first, the way the
        // row and the detail screen show them.
        UIPasteboard.general.string = letterData.forms.prefix(3).reversed().joined(separator: " ")
    } label: {
        Label("Copy Forms", systemImage: "doc.on.doc")
    }
}

/// The same menu for an Arabic numeral, so the numbers in the alphabet's list answer to a long press like the
/// letters above them do. Numbers have no favorite state, so it's fullscreen / share / copy only.
@ViewBuilder
func arabicNumberContextItems(
    _ numberData: (number: String, name: String, transliteration: String, englishNumber: String)
) -> some View {
    let settings = Settings.shared

    Text("Number Actions")
        .foregroundStyle(.secondary)

    Button {
        settings.hapticFeedback()
        FocusOverlayPresenter.shared.present(.number(numberData))
    } label: {
        Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
    }

    Button {
        settings.hapticFeedback()
        presentSystemShareSheet(items: [FocusItem.number(numberData).shareText])
    } label: {
        Label("Share Number", systemImage: "square.and.arrow.up")
    }

    Divider()

    Button {
        settings.hapticFeedback()
        UIPasteboard.general.string = numberData.number
    } label: {
        Label("Copy Numeral", systemImage: "doc.on.doc")
    }

    Button {
        settings.hapticFeedback()
        UIPasteboard.general.string = numberData.name
    } label: {
        Label("Copy Arabic Name", systemImage: "doc.on.doc")
    }

    Button {
        settings.hapticFeedback()
        UIPasteboard.general.string = numberData.transliteration
    } label: {
        Label("Copy Transliteration", systemImage: "doc.on.doc")
    }
}

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
