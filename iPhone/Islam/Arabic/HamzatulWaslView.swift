import SwiftUI

// MARK: - Hamzatul waSl

/// ٱ, the hamza that is said only at a start, with drills (Abu, 2026-10-27: "have a whole hamzatul
/// wasl section in Arabic alphabet with exercises especially tanween then hamzatul wasl how you have
/// to say in"). A section of its own on the alphabet, after LETTER SHAPES: this page and its three
/// drills, one link per row.
///
/// What it teaches, in the order a reader meets it: the two hamzas; which vowel to START on (the
/// article takes a fatha, nouns a kasra, verbs follow their third letter, five verbs only look like
/// a damma); that reading ON drops it; and what the word before does when it has no vowel of its own
/// to carry you in. A long vowel shortens and a sukoon takes a vowel, both printed or plain to see in
/// the mushaf. A TANWEEN is the one the mushaf does not write out: its noon takes a kasra and joins
/// on (نُوحٌ ٱبۡنَهُۥ, "nooHunibnahu"), so it gets a section and a drill of its own.
///
/// Every Quran word and phrase is the Hafs text's own spelling at the reference given (checked
/// against Quran-Tajweed-Engine/sources/Quran.json, 2026-10-27; the 46 tanween-before-waSl junctures
/// inside an ayah were listed from it, and the examples come from them), drawn in the Uthmani hand.
/// The "said as" lines are NOT mushaf spellings: they write out what is heard, as the Tajweed topic's
/// بِغُلَٰمِنِ سۡمُهُۥ does, and the voice reads those respellings, because read as printed it says the
/// hamza the rule drops.
///
/// Hafs throughout. Some readers give that noon a damma before a verb that starts on a damma (see
/// `wasl-sign-notation-setting`); Hafs always says the kasra, and the drill asks about it once
/// (خَبِيثَةٍ ٱجۡتُثَّتۡ, 14:26).
struct HamzatulWaslView: View {
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared

    /// The link label's specimen.
    static let specimen = "ٱ"

    private func uthmani(_ base: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        Font.arabic(Settings.hafsUthmaniFontName, size: base, relativeTo: style)
    }

    var body: some View {
        List {
            Group {
                letterSection
                twoHamzasSection
                startSection
                nounSection
                verbSection
                exceptionSection
                readOnSection
                longVowelSection
                sukoonSection
                tanweenSection
                tanweenRowsSection
                #if os(iOS)
                practiceSection
                moreSection
                #endif
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("Hamzatul WaSl")
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
            }
            .minimizedBarStyle(barsCollapsed)
            .padding(.horizontal, 24)
            .padding(.bottom, BottomBarCushion.standard)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HideEnglishToolbarButton()
            }
        }
        #endif
    }

    // MARK: The letter

    private var letterSection: some View {
        Section {
            VStack(spacing: 4) {
                Text(Self.specimen)
                    .font(uthmani(64, relativeTo: .largeTitle))
                    .arabicFontDesign(custom: true)
                    .arabicLetterTypeFloor(steps: settings.arabicLetterSizeIndex)
                    .foregroundColor(settings.accentColor.color)
                    .frame(height: 96)

                Text(verbatim: "هَمۡزَةُ ٱلۡوَصۡلِ")
                    .font(uthmani(24, relativeTo: .title2))
                    .arabicFontDesign(custom: true)

                if !settings.hideEnglishInArabicLetters {
                    Text("hamzatul waSl, \u{201C}the joining hamza\u{201D}")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)

            ArticleLead(String(localized: "Hamzatul waSl is a hamza you say only when you START on its word. Read on from the word before and it is silent: the sound before it runs straight into the letter after it."), eyebrow: String(localized: "IN SHORT"))

            Text("The mushaf marks it with a small saad over the alif, ٱ, from صِلَة (\u{201C}joining\u{201D}). It only ever begins a word: the article ٱلۡ, a handful of nouns, and many verbs.")
                .font(.body)
        }
    }

    private var twoHamzasSection: some View {
        Section {
            HStack(alignment: .top, spacing: 8) {
                hamzaCard(glyph: "أ إ",
                          name: String(localized: "Hamzatul qaT\u{2019}"),
                          meaning: String(localized: "the cutting hamza"),
                          rule: String(localized: "Always said, at a start or in the middle of reading."),
                          example: "أَنۡعَمۡتَ", reading: "an'amta (1:7)")
                hamzaCard(glyph: "ٱ",
                          name: String(localized: "Hamzatul waSl"),
                          meaning: String(localized: "the joining hamza"),
                          rule: String(localized: "Said only when you start on its word."),
                          example: "ٱهۡدِنَا", reading: "ihdinaa (1:6)")
            }
            .padding(.vertical, 4)

            // The same phrase is a row of AFTER A LONG VOWEL too: its own selection id, so one tap
            // never selects both.
            waslRow(Self.ihdinaSirat, selectionScope: "twoHamzas")
        } header: {
            Text("TWO KINDS OF HAMZA")
        } footer: {
            Text("In ٱهۡدِنَا ٱلصِّرَٰطَ the first hamza is said, because you start on it; the second is silent, because you are reading on into it.")
        }
    }

    private func hamzaCard(glyph: String, name: String, meaning: String, rule: String, example: String, reading: String) -> some View {
        VStack(spacing: 4) {
            Text(glyph)
                .font(uthmani(34, relativeTo: .largeTitle))
                .arabicFontDesign(custom: true)
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(height: 50)

            Text(name)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)

            if !settings.hideEnglishInArabicLetters {
                Text(meaning)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text(rule)
                .font(.caption)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(example)
                .font(uthmani(22, relativeTo: .title3))
                .arabicFontDesign(custom: true)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            if !settings.hideEnglishInArabicLetters {
                Text(reading)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(settings.accentColor.color.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: Starting on it

    private var startSection: some View {
        Section {
            ForEach(WaslData.starts.filter { $0.group == .article }.prefix(5), id: \.arabic) { item in
                startRow(item)
            }
        } header: {
            Text("STARTING ON IT: THE ARTICLE TAKES A FATHA")
        } footer: {
            Text("Starting on ٱلۡ, say \u{201C}a\u{201D}. Before a sun letter the laam is not heard and the next letter doubles: ar-RaHmaan, an-naas.")
        }
    }

    private var nounSection: some View {
        Section {
            ForEach(WaslData.starts.filter { $0.group == .noun }, id: \.arabic) { item in
                startRow(item)
            }
        } header: {
            Text("NOUNS TAKE A KASRA")
        } footer: {
            Text("Seven nouns in the Quran begin with hamzatul waSl: son, daughter, a man, a woman, two (both genders), and name. They and the verbal nouns of the longer verbs, like ٱبۡتِغَآءَ (ibtighaa\u{2019}a, seeking), all start on \u{201C}i\u{201D}.")
        }
    }

    private var verbSection: some View {
        Section {
            ForEach(WaslData.starts.filter { $0.group == .verbDamma }.prefix(4), id: \.arabic) { item in
                startRow(item)
            }
            ForEach(WaslData.starts.filter { $0.group == .verbKasra }.prefix(5), id: \.arabic) { item in
                startRow(item)
            }
        } header: {
            Text("VERBS: LOOK AT THE THIRD LETTER")
        } footer: {
            Text("Count the hamza as the first letter. A damma on the third letter: start on \u{201C}u\u{201D}. A fatha or a kasra there: start on \u{201C}i\u{201D}. A shaddah is two letters, so in ٱتَّقُواْ the third letter is the second taa, with its fatha: ittaqoo.")
        }
    }

    private var exceptionSection: some View {
        Section {
            ForEach(WaslData.starts.filter { $0.group == .exception }, id: \.arabic) { item in
                startRow(item)
            }
        } header: {
            Text("FIVE THAT ONLY LOOK LIKE A DAMMA")
        } footer: {
            Text("Their third letter carries a damma only because of the waaw after it; the verb's own vowel there is a kasra (imshiyoo became imshoo), so they start on \u{201C}i\u{201D}. The fifth, ٱمۡضُواْ (imDoo, 15:65), comes in the Quran only after wa. In ٱئۡتُواْ the hamza with a sukoon turns into a long \u{201C}ee\u{201D}: eetoo.")
        }
    }

    // MARK: Reading on

    private var readOnSection: some View {
        Section {
            ForEach(WaslData.phrases.filter { $0.kind == .vowel }, id: \.arabic) { waslRow($0) }
        } header: {
            Text("READING ON: IT IS SILENT")
        } footer: {
            Text("The vowel at the end of the word before carries you straight into the letter after the alif. The alif stays written, and nothing of it is said.")
        }
    }

    private var longVowelSection: some View {
        Section {
            ForEach(WaslData.phrases.filter { $0.kind == .longVowel }, id: \.arabic) { waslRow($0) }
        } header: {
            Text("AFTER A LONG VOWEL: IT SHORTENS")
        } footer: {
            Text("The letter after the alif has a sukoon or a shaddah, and Arabic never says a long vowel straight into one. So the long vowel is written but said short: fee becomes fi.")
        }
    }

    private var sukoonSection: some View {
        Section {
            ForEach(WaslData.phrases.filter { $0.kind == .sukoon }, id: \.arabic) { waslRow($0) }
        } header: {
            Text("AFTER A SUKOON: IT TAKES A VOWEL")
        } footer: {
            Text("Two sukoons cannot be said one after the other, so the first takes a vowel: usually a kasra, a damma on the meem of a plural (ـهُمُ، ـكُمُ) and on a plural verb's waaw, and a fatha on مِنَ before the article. You never have to work it out: the mushaf prints the vowel.")
        }
    }

    // MARK: Tanween before it

    private var tanweenSection: some View {
        Section {
            ArticleLead(String(localized: "A tanween before hamzatul waSl is the one the mushaf does not write out. Say its noon with a kasra and join on: نُوحٌ ٱبۡنَهُۥ is read nooHunibnahu."), eyebrow: String(localized: "TANWEEN THEN WASL"))

            VStack(alignment: .leading, spacing: 6) {
                ArticleBullet(String(localized: "- **Why:** a tanween is a noon with a sukoon at the end of the word. With the alif silent, it meets the sukoon after the alif, so it takes a vowel like any other sukoon: a kasra."))
                ArticleBullet(String(localized: "- **All three:** -un, -an and -in become -uni, -ani and -ini."))
                ArticleBullet(String(localized: "- **Hafs says the kasra even before a verb you would start on a damma:** خَبِيثَةٍ ٱجۡتُثَّتۡ is khabeethatinij-tuththat (14:26)."))
                ArticleBullet(String(localized: "- **Stopping instead:** stop on the tanween word the way any stop goes (خَيۡرًا, khayraa), then start the next on its hamza (al-waSiyyatu)."))
            }
            .font(.body)

            Text("It happens 46 times inside an ayah in the Hafs text. Tap a row to hear it as it is said.")
                .font(.body)
        }
    }

    private var tanweenRowsSection: some View {
        Section {
            ForEach(WaslData.tanween.prefix(7), id: \.arabic) { waslRow($0) }
        } header: {
            Text("TANWEEN THEN WASL IN THE QURAN")
        } footer: {
            Text("Under each phrase, \u{201C}said as\u{201D} writes out what you hear: the tanween turned into a noon with a kasra, and the alif gone. It is not how the mushaf spells it.")
        }
    }

    // MARK: Practice

    #if os(iOS)
    /// One link per row (`one-link-per-list-row`).
    private var practiceSection: some View {
        Section {
            ForEach(HamzatulWaslPracticeView.Mode.allCases) { mode in
                NavigationLink(destination: LazyDestination { HamzatulWaslPracticeView(mode: mode) }) {
                    ArabicTopicLinkLabel(specimen: mode.specimen, title: mode.title, caption: mode.caption, face: .uthmani)
                }
                .tint(settings.accentColor.color)
            }
        } header: {
            Text("PRACTICE")
        } footer: {
            Text("Ten Quran words or phrases a round, in the mushaf's hand.")
        }
    }

    private var moreSection: some View {
        Section {
            NavigationLink(destination: LazyDestination { TajweedHamzatulWaslView() }) {
                Label("Hamzatul Wasl in Tajweed Foundations", systemImage: "book")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }

            TajweedLessonLink(lessonID: "hamzat-al-wasl") {
                Label("The Tajweed Course Lesson", systemImage: "graduationcap")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
        } header: {
            Text("LEARN MORE")
        }
    }
    #endif

    // MARK: Rows

    private func startRow(_ item: WaslData.Start) -> some View {
        WaslExampleRow(arabic: item.arabic,
                       reading: item.reading,
                       note: "\(item.gloss) (\(item.reference.localizedDigits))",
                       saidAs: item.saidAs,
                       spoken: item.saidAs,
                       highlightsWasla: true)
    }

    private func waslRow(_ phrase: WaslData.Phrase, selectionScope: String = "") -> some View {
        WaslExampleRow(arabic: phrase.arabic,
                       reading: phrase.reading,
                       note: "\(phrase.gloss) (\(phrase.reference.localizedDigits))",
                       saidAs: phrase.kind == .tanween ? phrase.saidAs : nil,
                       spoken: phrase.spoken,
                       highlightsWasla: true,
                       selectionScope: selectionScope)
    }

    private static let ihdinaSirat = WaslData.phrases.first { $0.reference == "1:6" } ?? WaslData.phrases[0]
}

/// A Quran word or phrase in the Uthmani hand with its reading and gloss, ArabicExampleRow's layout
/// and tap-to-hear. Its own row because the voice must read `spoken` (what is heard), not the
/// printed text: read as printed, a tanween before hamzatul waSl comes out with the hamza the rule
/// drops. Hamzatul waSl itself is tinted wherever it is written.
private struct WaslExampleRow: View {
    @Environment(\.appearance) private var appearance
    /// Snapshotted at creation (the NameRow rule): the page observes the slices and rebuilds the rows.
    var letterSizeSteps: Int = Settings.shared.arabicLetterSizeIndex
    var hideEnglish: Bool = Settings.shared.hideEnglishInArabicLetters
    @ObservedObject private var selection = ArabicPracticeSelection.shared

    let arabic: String
    let reading: String
    let note: String
    /// What you hear, written out, under the phrase. Not a mushaf spelling.
    let saidAs: String?
    let spoken: String
    var highlightsWasla = false
    /// Set where a phrase is shown twice on the page, so the two rows keep separate selections.
    var selectionScope = ""

    private var arabicText: Text {
        guard highlightsWasla else { return Text(arabic) }
        var attributed = AttributedString(arabic)
        var cursor = attributed.startIndex
        while let range = attributed[cursor...].range(of: "ٱ") {
            attributed[range].foregroundColor = appearance.accent
            cursor = range.upperBound
        }
        return Text(attributed)
    }

    var body: some View {
        let id = "wasl:" + selectionScope + arabic
        let isSelected = selection.isSelected(id)

        return HStack(alignment: .center, spacing: 12) {
            if isSelected {
                PracticeListenButton(text: spoken)
            }

            if !hideEnglish {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reading)
                        .font(.subheadline.weight(.semibold))

                    Text(note)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                arabicText
                    .font(Font.arabic(Settings.hafsUthmaniFontName, size: 24, relativeTo: .title2))
                    .arabicFontDesign(custom: true)
                    .arabicLetterTypeFloor(steps: letterSizeSteps)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)

                if let saidAs {
                    HStack(spacing: 4) {
                        Text(saidAs)
                            .font(Font.arabic(Settings.hafsUthmaniFontName, size: 17, relativeTo: .body))
                            .arabicFontDesign(custom: true)
                            .foregroundColor(appearance.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        if !hideEnglish {
                            Text("said as")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    // Right to left, like the script: the respelling on the right, under the phrase.
                    .environment(\.layoutDirection, .rightToLeft)
                }
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .arabicPracticeRowSelection(isSelected, hInset: -8, vInset: -2)
        .onTapGesture {
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut) { selection.toggle(id) }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(isSelected
            ? String(localized: "\(reading), \(note), selected")
            : String(localized: "\(reading), \(note)"))
    }
}

/// The way in to `HamzatulWaslView` from hamzatul waSl's own letter page. A List row of its own
/// wherever it goes (one link per row).
struct HamzatulWaslLink: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared

    var body: some View {
        NavigationLink(destination: LazyDestination { HamzatulWaslView() }) {
            Label("Hamzatul WaSl, With Practice", systemImage: "book")
                .font(.body)
                .foregroundColor(settings.accentColor.color)
        }
    }
}

// MARK: - The words

/// The page's and the drills' Quran words, each the Hafs text's spelling at its reference.
enum WaslData {
    /// The vowel a word starts on.
    enum Vowel: Int, CaseIterable {
        case a, i, u
    }

    struct Start {
        enum Group { case article, noun, verbDamma, verbKasra, exception }

        let arabic: String
        /// Read from a start.
        let reading: String
        let gloss: String
        let reference: String
        let group: Group
        /// The word with the hamza written in, as it is said from a start (also what the voice reads).
        let saidAs: String
        let why: String

        var vowel: Vowel {
            switch group {
            case .article: return .a
            case .verbDamma: return .u
            case .noun, .verbKasra, .exception: return .i
            }
        }
    }

    struct Phrase {
        enum Kind { case vowel, longVowel, sukoon, tanween }

        let arabic: String
        /// Read on, joined: the right answer.
        let reading: String
        /// Two wrong readings: the hamza said, and the other slip this kind invites.
        let wrong: [String]
        let gloss: String
        let reference: String
        let kind: Kind
        /// What you hear, written out (shown for a tanween).
        let saidAs: String
        /// What the voice reads.
        let spoken: String
        let why: String
    }

    static let starts: [Start] = [
        // The article: a fatha.
        Start(arabic: "ٱلۡحَمۡدُ", reading: "al-Hamdu", gloss: String(localized: "all praise"), reference: "1:2", group: .article, saidAs: "أَلۡحَمۡدُ",
              why: String(localized: "The article ٱلۡ always starts on a fatha: \u{201C}al\u{201D}.")),
        Start(arabic: "ٱلۡكِتَٰبُ", reading: "al-kitaabu", gloss: String(localized: "the Book"), reference: "2:2", group: .article, saidAs: "أَلۡكِتَٰبُ",
              why: String(localized: "The article: start on a fatha.")),
        Start(arabic: "ٱلنَّاسُ", reading: "an-naasu", gloss: String(localized: "the people"), reference: "2:13", group: .article, saidAs: "أَلنَّاسُ",
              why: String(localized: "The article, before a sun letter: start on a fatha and the noon doubles, \u{201C}an-naasu\u{201D}.")),
        Start(arabic: "ٱلرَّحۡمَٰنُ", reading: "ar-RaHmaanu", gloss: String(localized: "the Most Merciful"), reference: "20:5", group: .article, saidAs: "أَلرَّحۡمَٰنُ",
              why: String(localized: "The article before a sun letter: \u{201C}ar-RaHmaanu\u{201D}, on a fatha.")),
        Start(arabic: "ٱلۡقَمَرُ", reading: "al-qamaru", gloss: String(localized: "the moon"), reference: "54:1", group: .article, saidAs: "أَلۡقَمَرُ",
              why: String(localized: "The article: start on a fatha.")),
        Start(arabic: "ٱلصِّرَٰطَ", reading: "aS-Siraata", gloss: String(localized: "the path"), reference: "1:6", group: .article, saidAs: "أَلصِّرَٰطَ",
              why: String(localized: "The article before a sun letter: \u{201C}aS-Siraata\u{201D}, on a fatha.")),
        Start(arabic: "ٱلَّذِينَ", reading: "alladheena", gloss: String(localized: "those who"), reference: "1:7", group: .article, saidAs: "أَلَّذِينَ",
              why: String(localized: "It begins with the article's alif and laam: start on a fatha, \u{201C}alladheena\u{201D}.")),

        // The nouns: a kasra.
        Start(arabic: "ٱبۡنُ", reading: "ibnu", gloss: String(localized: "son"), reference: "3:45", group: .noun, saidAs: "إِبۡنُ",
              why: String(localized: "A noun without the article: start on a kasra.")),
        Start(arabic: "ٱسۡمُهُ", reading: "ismuhu", gloss: String(localized: "his name"), reference: "3:45", group: .noun, saidAs: "إِسۡمُهُ",
              why: String(localized: "The noun ٱسۡم (name) is one of those that start on a kasra.")),
        Start(arabic: "ٱمۡرَأَتُ", reading: "imra\u{2019}atu", gloss: String(localized: "the wife of"), reference: "3:35", group: .noun, saidAs: "إِمۡرَأَتُ",
              why: String(localized: "A noun: start on a kasra, even though the third letter has a fatha (that rule is for verbs).")),
        Start(arabic: "ٱثۡنَانِ", reading: "ithnaani", gloss: String(localized: "two"), reference: "5:106", group: .noun, saidAs: "إِثۡنَانِ",
              why: String(localized: "A noun: start on a kasra.")),
        Start(arabic: "ٱبۡنَتَ", reading: "ibnata", gloss: String(localized: "the daughter of"), reference: "66:12", group: .noun, saidAs: "إِبۡنَتَ",
              why: String(localized: "A noun: start on a kasra.")),
        Start(arabic: "ٱمۡرُؤٌاْ", reading: "imru\u{2019}un", gloss: String(localized: "a man"), reference: "4:176", group: .noun, saidAs: "إِمۡرُؤٌ",
              why: String(localized: "A noun, so a kasra, even with a damma on the third letter: the third-letter rule is only for verbs.")),

        // Verbs with a damma on the third letter: a damma.
        Start(arabic: "ٱدۡعُ", reading: "ud\u{2019}u", gloss: String(localized: "invite"), reference: "16:125", group: .verbDamma, saidAs: "أُدۡعُ",
              why: String(localized: "A verb whose third letter, the \u{2018}ayn, has a damma: start on a damma.")),
        Start(arabic: "ٱنظُرۡ", reading: "unZur", gloss: String(localized: "look"), reference: "6:65", group: .verbDamma, saidAs: "أُنظُرۡ",
              why: String(localized: "The third letter, Zhaa, has a damma: start on a damma.")),
        Start(arabic: "ٱعۡبُدُواْ", reading: "u\u{2019}budoo", gloss: String(localized: "worship"), reference: "2:21", group: .verbDamma, saidAs: "أُعۡبُدُواْ",
              why: String(localized: "The third letter, baa, has a damma: start on a damma.")),
        Start(arabic: "ٱذۡكُرُواْ", reading: "udhkuroo", gloss: String(localized: "remember"), reference: "2:40", group: .verbDamma, saidAs: "أُذۡكُرُواْ",
              why: String(localized: "The third letter, kaaf, has a damma: start on a damma.")),
        Start(arabic: "ٱخۡرُجۡ", reading: "ukhruj", gloss: String(localized: "get out"), reference: "7:18", group: .verbDamma, saidAs: "أُخۡرُجۡ",
              why: String(localized: "The third letter, raa, has a damma: start on a damma.")),
        Start(arabic: "ٱتۡلُ", reading: "utlu", gloss: String(localized: "recite"), reference: "29:45", group: .verbDamma, saidAs: "أُتۡلُ",
              why: String(localized: "The third letter, laam, has a damma: start on a damma.")),
        Start(arabic: "ٱضۡطُرَّ", reading: "uDTurra", gloss: String(localized: "is forced"), reference: "2:173", group: .verbDamma, saidAs: "أُضۡطُرَّ",
              why: String(localized: "The third letter, Taa, has a damma: start on a damma.")),

        // Verbs with a fatha or a kasra on the third letter: a kasra.
        Start(arabic: "ٱهۡدِنَا", reading: "ihdinaa", gloss: String(localized: "guide us"), reference: "1:6", group: .verbKasra, saidAs: "إِهۡدِنَا",
              why: String(localized: "The third letter, daal, has a kasra: start on a kasra.")),
        Start(arabic: "ٱذۡهَبۡ", reading: "idh-hab", gloss: String(localized: "go"), reference: "20:24", group: .verbKasra, saidAs: "إِذۡهَبۡ",
              why: String(localized: "The third letter, haa, has a fatha: start on a kasra.")),
        Start(arabic: "ٱضۡرِب", reading: "iDrib", gloss: String(localized: "strike"), reference: "2:60", group: .verbKasra, saidAs: "إِضۡرِبۡ",
              why: String(localized: "The third letter, raa, has a kasra: start on a kasra.")),
        Start(arabic: "ٱسۡتَغۡفِرُواْ", reading: "istaghfiroo", gloss: String(localized: "ask forgiveness"), reference: "11:3", group: .verbKasra, saidAs: "إِسۡتَغۡفِرُواْ",
              why: String(localized: "The third letter, taa, has a fatha: start on a kasra.")),
        Start(arabic: "ٱتَّقُواْ", reading: "ittaqoo", gloss: String(localized: "fear (Allah)"), reference: "2:278", group: .verbKasra, saidAs: "إِتَّقُواْ",
              why: String(localized: "The shaddah is two taas, so the third letter is the second taa, with a fatha: start on a kasra.")),
        Start(arabic: "ٱرۡكَعُواْ", reading: "irka\u{2019}oo", gloss: String(localized: "bow"), reference: "22:77", group: .verbKasra, saidAs: "إِرۡكَعُواْ",
              why: String(localized: "The third letter, kaaf, has a fatha: start on a kasra.")),
        Start(arabic: "ٱهۡبِطُواْ", reading: "ihbiToo", gloss: String(localized: "go down"), reference: "2:36", group: .verbKasra, saidAs: "إِهۡبِطُواْ",
              why: String(localized: "The third letter, baa, has a kasra: start on a kasra.")),
        Start(arabic: "ٱعۡلَمُوٓاْ", reading: "i\u{2019}lamoo", gloss: String(localized: "know"), reference: "5:98", group: .verbKasra, saidAs: "إِعۡلَمُواْ",
              why: String(localized: "The third letter, laam, has a fatha: start on a kasra.")),

        // The verbs whose damma is not their own: a kasra.
        Start(arabic: "ٱمۡشُواْ", reading: "imshoo", gloss: String(localized: "go on"), reference: "38:6", group: .exception, saidAs: "إِمۡشُواْ",
              why: String(localized: "One of the five: the damma on the sheen is only there for the waaw after it. Start on a kasra.")),
        Start(arabic: "ٱقۡضُوٓاْ", reading: "iqDoo", gloss: String(localized: "carry it out"), reference: "10:71", group: .exception, saidAs: "إِقۡضُواْ",
              why: String(localized: "One of the five: the verb's own vowel there is a kasra. Start on a kasra.")),
        Start(arabic: "ٱبۡنُواْ", reading: "ibnoo", gloss: String(localized: "build"), reference: "18:21", group: .exception, saidAs: "إِبۡنُواْ",
              why: String(localized: "One of the five: the damma comes from the waaw, not the verb. Start on a kasra.")),
        Start(arabic: "ٱئۡتُواْ", reading: "eetoo", gloss: String(localized: "come"), reference: "20:64", group: .exception, saidAs: "إِيتُواْ",
              why: String(localized: "One of the five, so a kasra; and the hamza with a sukoon after it turns into a long \u{201C}ee\u{201D}: eetoo.")),
    ]

    static let phrases: [Phrase] = [
        // A vowel before it.
        Phrase(arabic: "بِسۡمِ ٱللَّهِ", reading: "bismil-laahi", wrong: ["bismi allaahi", "bismal-laahi"],
               gloss: String(localized: "in the name of Allah"), reference: "1:1", kind: .vowel,
               saidAs: "بِسۡمِ للَّهِ", spoken: "بِسْمِلَّاهِ",
               why: String(localized: "The kasra on the meem carries you straight into the laam; the alif is silent.")),
        Phrase(arabic: "رَبِّ ٱلۡعَٰلَمِينَ", reading: "rabbil-\u{2019}aalameen", wrong: ["rabbi al-\u{2019}aalameen", "rabbal-\u{2019}aalameen"],
               gloss: String(localized: "Lord of the worlds"), reference: "1:2", kind: .vowel,
               saidAs: "رَبِّ لۡعَٰلَمِينَ", spoken: "رَبِّلْعَالَمِينَ",
               why: String(localized: "The kasra under the baa joins straight onto the laam: \u{201C}rabbil\u{201D}.")),
        Phrase(arabic: "ذَٰلِكَ ٱلۡكِتَٰبُ", reading: "dhaalikal-kitaabu", wrong: ["dhaalika al-kitaabu", "dhaalikil-kitaabu"],
               gloss: String(localized: "that is the Book"), reference: "2:2", kind: .vowel,
               saidAs: "ذَٰلِكَ لۡكِتَٰبُ", spoken: "ذَالِكَلْكِتَابُ",
               why: String(localized: "The kaaf's fatha runs into the laam: \u{201C}dhaalikal\u{201D}. The article's own fatha is only for a start.")),

        // A long vowel before it.
        Phrase(arabic: "ٱهۡدِنَا ٱلصِّرَٰطَ", reading: "ihdinaS-Siraata", wrong: ["ihdinaa aS-Siraata", "ihdinaaS-Siraata"],
               gloss: String(localized: "guide us to the path"), reference: "1:6", kind: .longVowel,
               saidAs: "إِهۡدِنَ صِّرَٰطَ", spoken: "إِهْدِنَصِّرَاطَ",
               why: String(localized: "The alif after the noon is written but not lengthened: a doubled Saad comes next, so \u{201C}naa\u{201D} is said \u{201C}na\u{201D}.")),
        Phrase(arabic: "فِي ٱلۡأَرۡضِ", reading: "fil-arDi", wrong: ["fee al-arDi", "feel-arDi"],
               gloss: String(localized: "on the earth"), reference: "2:11", kind: .longVowel,
               saidAs: "فِ لۡأَرۡضِ", spoken: "فِلْأَرْضِ",
               why: String(localized: "A laam with a sukoon follows, so the long \u{201C}ee\u{201D} of فِي is said short: \u{201C}fil\u{201D}.")),
        Phrase(arabic: "إِذَا ٱلشَّمۡسُ", reading: "idhash-shamsu", wrong: ["idhaa ash-shamsu", "idhaash-shamsu"],
               gloss: String(localized: "when the sun"), reference: "81:1", kind: .longVowel,
               saidAs: "إِذَ شَّمۡسُ", spoken: "إِذَشَّمْسُ",
               why: String(localized: "A doubled sheen follows, so the alif of إِذَا is not lengthened: \u{201C}idhash\u{201D}.")),
        Phrase(arabic: "عَلَى ٱلۡمَلَٰٓئِكَةِ", reading: "\u{2019}alal-malaa\u{2019}ikati", wrong: ["\u{2019}alaa al-malaa\u{2019}ikati", "\u{2019}alaal-malaa\u{2019}ikati"],
               gloss: String(localized: "to the angels"), reference: "2:31", kind: .longVowel,
               saidAs: "عَلَ لۡمَلَٰٓئِكَةِ", spoken: "عَلَلْمَلَائِكَةِ",
               why: String(localized: "The alif maqSoorah is not read before hamzatul waSl; you go straight to the laam: \u{201C}\u{2019}alal\u{201D}.")),
        Phrase(arabic: "وَأَقِيمُواْ ٱلصَّلَوٰةَ", reading: "wa aqeemuS-Salaata", wrong: ["wa aqeemoo aS-Salaata", "wa aqeemooS-Salaata"],
               gloss: String(localized: "and establish prayer"), reference: "2:43", kind: .longVowel,
               saidAs: "وَأَقِيمُ صَّلَوٰةَ", spoken: "وَأَقِيمُصَّلَاةَ",
               why: String(localized: "The waaw and the alif after the meem are written, but the long \u{201C}oo\u{201D} is said short before the doubled Saad: \u{201C}aqeemuS\u{201D}.")),

        // A sukoon before it.
        Phrase(arabic: "وَقَالَتِ ٱلۡيَهُودُ", reading: "wa qaalatil-yahoodu", wrong: ["wa qaalat al-yahoodu", "wa qaalatul-yahoodu"],
               gloss: String(localized: "and the Jews said"), reference: "2:113", kind: .sukoon,
               saidAs: "وَقَالَتِ لۡيَهُودُ", spoken: "وَقَالَتِلْيَهُودُ",
               why: String(localized: "The sukoon that ends قَالَتۡ takes a kasra before hamzatul waSl, and the mushaf prints it: \u{201C}qaalatil\u{201D}.")),
        Phrase(arabic: "قُلِ ٱللَّهُمَّ", reading: "qulil-laahumma", wrong: ["qul allaahumma", "qulal-laahumma"],
               gloss: String(localized: "say, O Allah"), reference: "3:26", kind: .sukoon,
               saidAs: "قُلِ للَّهُمَّ", spoken: "قُلِلَّاهُمَّ",
               why: String(localized: "The laam of قُلۡ takes the printed kasra: \u{201C}qulil-laahumma\u{201D}.")),
        Phrase(arabic: "أَوِ ٱدۡعُواْ", reading: "awid-\u{2019}oo", wrong: ["aw ud\u{2019}oo", "awud-\u{2019}oo"],
               gloss: String(localized: "or call upon"), reference: "17:110", kind: .sukoon,
               saidAs: "أَوِ دۡعُواْ", spoken: "أَوِدْعُوا",
               why: String(localized: "The waaw of أَوۡ takes the printed kasra and joins onto the daal: \u{201C}awid-\u{2019}oo\u{201D}. The damma you would start ٱدۡعُواْ on is never heard here.")),
        Phrase(arabic: "عَلَيۡهِمُ ٱلذِّلَّةُ", reading: "\u{2019}alayhimudh-dhillatu", wrong: ["\u{2019}alayhim adh-dhillatu", "\u{2019}alayhimidh-dhillatu"],
               gloss: String(localized: "humiliation upon them"), reference: "2:61", kind: .sukoon,
               saidAs: "عَلَيۡهِمُ ذِّلَّةُ", spoken: "عَلَيْهِمُذِّلَّةُ",
               why: String(localized: "The meem of a plural takes a damma, printed in the mushaf: \u{201C}\u{2019}alayhimudh\u{201D}.")),
        Phrase(arabic: "ٱشۡتَرَوُاْ ٱلضَّلَٰلَةَ", reading: "ishtarawuD-Dalaalata", wrong: ["ishtaraw aD-Dalaalata", "ishtarawiD-Dalaalata"],
               gloss: String(localized: "they bought error"), reference: "2:16", kind: .sukoon,
               saidAs: "إِشۡتَرَوُ ضَّلَٰلَةَ", spoken: "إِشْتَرَوُضَّلَالَةَ",
               why: String(localized: "A plural verb's waaw takes a damma, printed: \u{201C}ishtarawuD\u{201D}.")),
    ] + tanween

    static let tanween: [Phrase] = [
        Phrase(arabic: "نُوحٌ ٱبۡنَهُۥ", reading: "nooHunibnahu", wrong: ["nooHun ibnahu", "nooHubnahu"],
               gloss: String(localized: "Nuh (called) his son"), reference: "11:42", kind: .tanween,
               saidAs: "نُوحُنِ بۡنَهُۥ", spoken: "نُوحُنِبْنَهُ",
               why: String(localized: "The tanween\u{2019}s noon takes a kasra and joins on: \u{201C}nooHu-ni-bnahu\u{201D}. The hamza of ٱبۡنَهُۥ is not said.")),
        Phrase(arabic: "خَيۡرًا ٱلۡوَصِيَّةُ", reading: "khayranil-waSiyyatu", wrong: ["khayran al-waSiyyatu", "khayral-waSiyyatu"],
               gloss: String(localized: "wealth, the bequest"), reference: "2:180", kind: .tanween,
               saidAs: "خَيۡرَنِ لۡوَصِيَّةُ", spoken: "خَيْرَنِلْوَصِيَّةُ",
               why: String(localized: "-an becomes -ani and runs into the laam: \u{201C}khayra-nil-waSiyyatu\u{201D}.")),
        Phrase(arabic: "بِغُلَٰمٍ ٱسۡمُهُۥ", reading: "bighulaaminismuhu", wrong: ["bighulaamin ismuhu", "bighulaamismuhu"],
               gloss: String(localized: "of a boy whose name"), reference: "19:7", kind: .tanween,
               saidAs: "بِغُلَٰمِنِ سۡمُهُۥ", spoken: "بِغُلَامِنِسْمُهُ",
               why: String(localized: "-in becomes -ini and joins the seen: \u{201C}bighulaami-ni-smuhu\u{201D}.")),
        Phrase(arabic: "عُزَيۡرٌ ٱبۡنُ", reading: "\u{2019}Uzayrunibnu", wrong: ["\u{2019}Uzayrun ibnu", "\u{2019}Uzayrubnu"],
               gloss: String(localized: "\u{2019}Uzayr is the son of"), reference: "9:30", kind: .tanween,
               saidAs: "عُزَيۡرُنِ بۡنُ", spoken: "عُزَيْرُنِبْنُ",
               why: String(localized: "-un becomes -uni: \u{201C}\u{2019}Uzayru-ni-bnu\u{201D}, with no hamza.")),
        Phrase(arabic: "يَوۡمَئِذٍ ٱلۡحَقُّ", reading: "yawma\u{2019}idhinil-Haqqu", wrong: ["yawma\u{2019}idhin al-Haqqu", "yawma\u{2019}idhil-Haqqu"],
               gloss: String(localized: "that Day, the true"), reference: "25:26", kind: .tanween,
               saidAs: "يَوۡمَئِذِنِ لۡحَقُّ", spoken: "يَوْمَئِذِنِلْحَقُّ",
               why: String(localized: "-in becomes -ini and joins the laam: \u{201C}yawma\u{2019}idhi-nil-Haqqu\u{201D}.")),
        Phrase(arabic: "جَمِيعًا ٱلَّذِي", reading: "jamee\u{2019}anil-ladhee", wrong: ["jamee\u{2019}an alladhee", "jamee\u{2019}al-ladhee"],
               gloss: String(localized: "all, (from) the One who"), reference: "7:158", kind: .tanween,
               saidAs: "جَمِيعَنِ لَّذِي", spoken: "جَمِيعَنِلَّذِي",
               why: String(localized: "-an becomes -ani and runs into the doubled laam: \u{201C}jamee\u{2019}a-nil-ladhee\u{201D}.")),
        Phrase(arabic: "رَجُلٌ ٱفۡتَرَىٰ", reading: "rajulunif-taraa", wrong: ["rajulun iftaraa", "rajuluf-taraa"],
               gloss: String(localized: "a man who invented"), reference: "23:38", kind: .tanween,
               saidAs: "رَجُلُنِ فۡتَرَىٰ", spoken: "رَجُلُنِفْتَرَى",
               why: String(localized: "-un becomes -uni and joins the faa: \u{201C}rajulu-nif-taraa\u{201D}.")),
        Phrase(arabic: "لُوطٍ ٱلۡمُرۡسَلِينَ", reading: "Lootinil-mursaleen", wrong: ["Lootin al-mursaleen", "Lootil-mursaleen"],
               gloss: String(localized: "(the people of) Lut, the messengers"), reference: "26:160", kind: .tanween,
               saidAs: "لُوطِنِ لۡمُرۡسَلِينَ", spoken: "لُوطِنِلْمُرْسَلِينَ",
               why: String(localized: "-in becomes -ini: \u{201C}Looti-nil-mursaleen\u{201D}.")),
        Phrase(arabic: "قَرۡيَةٍ ٱسۡتَطۡعَمَآ", reading: "qaryatinis-taT\u{2019}amaa", wrong: ["qaryatin istaT\u{2019}amaa", "qaryatis-taT\u{2019}amaa"],
               gloss: String(localized: "a town, they asked for food"), reference: "18:77", kind: .tanween,
               saidAs: "قَرۡيَتِنِ سۡتَطۡعَمَآ", spoken: "قَرْيَتِنِسْتَطْعَمَا",
               why: String(localized: "The taa marbuuTah is read as a taa, and its -in becomes -ini: \u{201C}qaryati-nis-taT\u{2019}amaa\u{201D}.")),
        Phrase(arabic: "خَبِيثَةٍ ٱجۡتُثَّتۡ", reading: "khabeethatinij-tuththat", wrong: ["khabeethatin ujtuththat", "khabeethatinuj-tuththat"],
               gloss: String(localized: "a bad tree, uprooted"), reference: "14:26", kind: .tanween,
               saidAs: "خَبِيثَتِنِ جۡتُثَّتۡ", spoken: "خَبِيثَتِنِجْتُثَّتْ",
               why: String(localized: "Started on, ٱجۡتُثَّتۡ takes a damma (ujtuththat). Joined to a tanween, Hafs still gives the noon a kasra: \u{201C}khabeethati-nij-tuththat\u{201D}.")),
        Phrase(arabic: "وَرَهۡبَانِيَّةً ٱبۡتَدَعُوهَا", reading: "wa rahbaaniyyatanib-tada\u{2019}oohaa", wrong: ["wa rahbaaniyyatan ibtada\u{2019}oohaa", "wa rahbaaniyyatab-tada\u{2019}oohaa"],
               gloss: String(localized: "and monasticism, which they invented"), reference: "57:27", kind: .tanween,
               saidAs: "وَرَهۡبَانِيَّتَنِ بۡتَدَعُوهَا", spoken: "وَرَهْبَانِيَّتَنِبْتَدَعُوهَا",
               why: String(localized: "-an becomes -ani and joins the baa: \u{201C}rahbaaniyyata-nib-tada\u{2019}oohaa\u{201D}.")),
        Phrase(arabic: "كَرَمَادٍ ٱشۡتَدَّتۡ", reading: "karamaadinish-taddat", wrong: ["karamaadin ishtaddat", "karamaadish-taddat"],
               gloss: String(localized: "like ashes, blown hard upon"), reference: "14:18", kind: .tanween,
               saidAs: "كَرَمَادِنِ شۡتَدَّتۡ", spoken: "كَرَمَادِنِشْتَدَّتْ",
               why: String(localized: "-in becomes -ini and joins the sheen: \u{201C}karamaadi-nish-taddat\u{201D}.")),
        Phrase(arabic: "يَوۡمَئِذٍ ٱلسَّلَمَۖ", reading: "yawma\u{2019}idhinis-salama", wrong: ["yawma\u{2019}idhin as-salama", "yawma\u{2019}idhis-salama"],
               gloss: String(localized: "that Day, submission"), reference: "16:87", kind: .tanween,
               saidAs: "يَوۡمَئِذِنِ سَّلَمَ", spoken: "يَوْمَئِذِنِسَّلَمَ",
               why: String(localized: "Before a sun letter too: -in becomes -ini and the seen doubles, \u{201C}yawma\u{2019}idhi-nis-salama\u{201D}.")),
        Phrase(arabic: "لَهۡوًا ٱنفَضُّوٓاْ", reading: "lahwaninfaDDoo", wrong: ["lahwan infaDDoo", "lahwanfaDDoo"],
               gloss: String(localized: "some amusement, they rushed to it"), reference: "62:11", kind: .tanween,
               saidAs: "لَهۡوَنِ نفَضُّوٓاْ", spoken: "لَهْوَنِنْفَضُّوا",
               why: String(localized: "-an becomes -ani, then the noon of the verb: \u{201C}lahwa-nin-faDDoo\u{201D}, two noons heard.")),
    ]
}

// MARK: - Practice

#if os(iOS)
/// The page's three drills, in `MaqsurahPracticeView`'s grammar (a big prompt, tiles to choose from,
/// the reason once you have chosen, then the next): which vowel starts a word, how a tanween joins
/// hamzatul waSl, and how any phrase reads on. Ten a round.
struct HamzatulWaslPracticeView: View {
    @Environment(\.appearance) private var appearance

    enum Mode: String, CaseIterable, Identifiable {
        /// Which vowel does the hamza take at a start?
        case start
        /// A tanween, then hamzatul waSl: how is it read joined?
        case tanween
        /// Any phrase: how is it read joined?
        case readOn

        var id: String { rawValue }

        var title: String {
            switch self {
            case .start: return String(localized: "Start on It")
            case .tanween: return String(localized: "Tanween Then WaSl")
            case .readOn: return String(localized: "Read It On")
            }
        }

        var caption: String {
            switch self {
            case .start: return String(localized: "Which vowel begins the word: a, i, or u")
            case .tanween: return String(localized: "Say the noon with a kasra and join")
            case .readOn: return String(localized: "Vowels, long vowels, sukoons and tanween")
            }
        }

        var specimen: String {
            switch self {
            case .start: return "ٱهۡدِنَا"
            case .tanween: return "نُوحٌ ٱبۡنَهُۥ"
            case .readOn: return "فِي ٱلۡأَرۡضِ"
            }
        }
    }

    /// One question, whichever drill: a prompt, its choices, and the right one.
    private struct Question {
        let arabic: String
        /// The right reading.
        let reading: String
        let gloss: String
        let reference: String
        let choices: [Choice]
        let answer: Int
        let saidAs: String
        let spoken: String
        let why: String
    }

    private struct Choice: Identifiable {
        let id: Int
        let text: String
        /// A small Arabic line above the text (the start drill's hamza and vowel).
        var arabic: String? = nil
    }

    let mode: Mode

    @State private var current: Mode
    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var chosen: Int?
    @State private var correct = 0
    @State private var finished = false

    init(mode: Mode) {
        self.mode = mode
        _current = State(initialValue: mode)
    }

    var body: some View {
        List {
            Group {
                if finished {
                    resultsSection
                } else if questions.indices.contains(index) {
                    questionSections(questions[index])
                }
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle(current.title)
        .onAppear { if questions.isEmpty { start(current) } }
        .onDisappear { ArabicSpeech.shared.stop() }
    }

    // MARK: Asking

    private var ask: String {
        switch current {
        case .start: return String(localized: "You are starting on this word. Which vowel does the hamza take?")
        case .tanween, .readOn: return String(localized: "Reading straight on, without stopping, how is it said?")
        }
    }

    /// The prompt with every hamzatul waSl tinted. One colour run per alif in one Text, so the joining
    /// is untouched.
    private func prompt(_ arabic: String) -> Text {
        var attributed = AttributedString(arabic)
        var cursor = attributed.startIndex
        while let range = attributed[cursor...].range(of: "ٱ") {
            attributed[range].foregroundColor = appearance.accent
            cursor = range.upperBound
        }
        return Text(attributed)
    }

    @ViewBuilder
    private func questionSections(_ question: Question) -> some View {
        Section {
            VStack(spacing: 10) {
                prompt(question.arabic)
                    .font(Font.arabic(Settings.hafsUthmaniFontName, size: 52, relativeTo: .largeTitle))
                    .arabicFontDesign(custom: true)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .frame(minHeight: 96)

                Text(ask)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        } header: {
            HStack {
                Text("QUESTION \(index + 1) OF \(questions.count)")

                Spacer()

                if correct > 0 {
                    Text("\(correct) right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(appearance.accent)
                        .textCase(nil)
                }
            }
        }

        Section {
            // Not lazy (`SummaryTileGrid`): a lazy grid in a List row can answer a different height on
            // each self-sizing pass, which iOS 26 traps on. Readings are phrases, so they stack.
            SummaryTileGrid(columns: current == .start ? 3 : 1) {
                ForEach(question.choices) { choice in
                    choiceButton(choice, right: question.answer)
                }
            }
            .padding(.vertical, 4)

            if let chosen {
                VStack(alignment: .leading, spacing: 6) {
                    Label(chosen == question.answer ? String(localized: "Right") : String(localized: "Not quite"),
                          systemImage: chosen == question.answer ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(chosen == question.answer ? .green : .red)

                    Text(question.why)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)

                // What is heard, written out, then the reading and where it is in the Quran.
                HStack(spacing: 12) {
                    PracticeListenButton(text: question.spoken)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(question.reading)
                            .font(.subheadline.weight(.semibold))

                        Text("\u{201C}\(question.gloss)\u{201D} (Quran \(question.reference.localizedDigits))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 0) {
                        Text(question.saidAs)
                            .font(Font.arabic(Settings.hafsUthmaniFontName, size: 22, relativeTo: .title3))
                            .arabicFontDesign(custom: true)
                            .foregroundColor(appearance.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)

                        Text("said as")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    Settings.shared.hapticFeedback()
                    advance()
                } label: {
                    Text(index + 1 == questions.count ? String(localized: "See Results") : String(localized: "Next Question"))
                        .font(.body.weight(.semibold))
                        .foregroundColor(appearance.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .conditionalGlassEffect(rectangle: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func choiceButton(_ choice: Choice, right: Int) -> some View {
        let answered = chosen != nil
        let isAnswer = choice.id == right
        let isWrongPick = chosen == choice.id && !isAnswer
        let stroke: Color = !answered ? .clear : isAnswer ? .green : isWrongPick ? .red : .clear

        return Button {
            guard chosen == nil else { return }
            Settings.shared.hapticFeedback()
            chosen = choice.id
            if isAnswer { correct += 1 }
        } label: {
            VStack(spacing: 2) {
                if let arabic = choice.arabic {
                    Text(arabic)
                        .font(Font.arabic(Settings.hafsUthmaniFontName, size: 30, relativeTo: .title))
                        .arabicFontDesign(custom: true)
                        .foregroundColor(appearance.accent)
                        .lineLimit(1)
                }

                Text(choice.text)
                    .font(current == .start ? .title3.weight(.semibold) : .body.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, minHeight: current == .start ? 76 : 48)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(appearance.accent.opacity(answered && isAnswer ? 0.18 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(stroke, lineWidth: 2)
            )
            .opacity(answered && !isAnswer && !isWrongPick ? 0.45 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(choice.text)
    }

    // MARK: Results

    private var resultsSection: some View {
        Section {
            VStack(spacing: 8) {
                Text("\(correct) of \(questions.count)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(appearance.accent)

                Text(correct == questions.count ? String(localized: "Every one right.")
                     : correct * 2 >= questions.count ? String(localized: "Most of it is there. Another round will settle the rest.")
                     : String(localized: "Read the page's rules once more, then come back for another round."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)

            Button {
                Settings.shared.hapticFeedback()
                start(current)
            } label: {
                Label("Play Again", systemImage: "arrow.clockwise")
                    .font(.body.weight(.semibold))
                    .foregroundColor(appearance.accent)
            }

            ForEach(Mode.allCases.filter { $0 != current }) { other in
                Button {
                    Settings.shared.hapticFeedback()
                    start(other)
                } label: {
                    Label(other.title, systemImage: "arrow.forward.circle")
                        .font(.body)
                        .foregroundColor(appearance.accent)
                }
            }
        } header: {
            Text("RESULTS")
        }
    }

    // MARK: Running a round

    private func start(_ mode: Mode) {
        current = mode
        questions = Self.makeRound(mode)
        index = 0
        chosen = nil
        correct = 0
        finished = false
    }

    private func advance() {
        chosen = nil
        if index + 1 >= questions.count {
            finished = true
        } else {
            index += 1
        }
    }

    /// Ten a round. Start on It: three article words, three damma verbs, and four kasras (nouns, kasra
    /// verbs, and one of the five look-alikes), so each vowel comes up. Tanween Then WaSl: ten of the
    /// tanween phrases. Read It On: two of each other kind and four tanween, the one to drill.
    private static func makeRound(_ mode: Mode) -> [Question] {
        switch mode {
        case .start:
            var picked: [WaslData.Start] = []
            picked += sample(WaslData.starts, 3) { $0.group == .article }
            picked += sample(WaslData.starts, 3) { $0.group == .verbDamma }
            picked += sample(WaslData.starts, 3) { $0.group == .noun || $0.group == .verbKasra }
            picked += sample(WaslData.starts, 1) { $0.group == .exception }
            return picked.shuffled().map(startQuestion)
        case .tanween:
            return WaslData.tanween.shuffled().prefix(10).map(phraseQuestion)
        case .readOn:
            var picked: [WaslData.Phrase] = []
            picked += sample(WaslData.phrases, 2) { $0.kind == .vowel }
            picked += sample(WaslData.phrases, 2) { $0.kind == .longVowel }
            picked += sample(WaslData.phrases, 2) { $0.kind == .sukoon }
            picked += sample(WaslData.phrases, 4) { $0.kind == .tanween }
            return picked.shuffled().map(phraseQuestion)
        }
    }

    /// `count` items at random from those `matching`.
    private static func sample<T>(_ items: [T], _ count: Int, matching: (T) -> Bool) -> [T] {
        Array(items.filter(matching).shuffled().prefix(count))
    }

    private static func startQuestion(_ item: WaslData.Start) -> Question {
        let choices = [
            Choice(id: WaslData.Vowel.a.rawValue, text: "a", arabic: "أَ"),
            Choice(id: WaslData.Vowel.i.rawValue, text: "i", arabic: "إِ"),
            Choice(id: WaslData.Vowel.u.rawValue, text: "u", arabic: "أُ"),
        ]
        return Question(arabic: item.arabic, reading: item.reading, gloss: item.gloss, reference: item.reference,
                        choices: choices, answer: item.vowel.rawValue,
                        saidAs: item.saidAs, spoken: item.saidAs, why: item.why)
    }

    /// The right reading and the two slips, in a shuffled order.
    private static func phraseQuestion(_ phrase: WaslData.Phrase) -> Question {
        let readings = ([phrase.reading] + phrase.wrong).shuffled()
        let choices = readings.enumerated().map { Choice(id: $0.offset, text: $0.element) }
        let answer = readings.firstIndex(of: phrase.reading) ?? 0
        return Question(arabic: phrase.arabic, reading: phrase.reading, gloss: phrase.gloss, reference: phrase.reference,
                        choices: choices, answer: answer,
                        saidAs: phrase.saidAs, spoken: phrase.spoken, why: phrase.why)
    }
}
#endif
