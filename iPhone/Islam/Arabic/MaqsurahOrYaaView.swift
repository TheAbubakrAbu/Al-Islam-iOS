import SwiftUI

// MARK: - Alif maqSoorah or yaa

/// ى or ي: the two letters that share one shape at the end of a word, and the three ways the mushaf
/// writes alif maqSoorah (Abu, 2026-10-24: "a section to differentiate between alif maqsuurah and yaa
/// with the 3 types of alif maqsuurah: by its own, with alif sagheera, with alif sagheera madd and
/// have practice for it", placed after Baa on Haa and Laam Alif under LETTER SHAPES).
///
/// Modern print keeps the two apart with dots: ي is yaa, ى is alif maqSoorah. The mushaf drops a
/// final yaa's dots too, so there the marks around the letter decide, and that is what this page
/// teaches. Every Quran word on it is drawn in the Uthmani hand the mushaf is printed in, whatever
/// the reader's Arabic face is: in Kufi or the system face a final yaa keeps its dots and the
/// question never comes up.
///
/// The three spellings follow exact rules in the Hafs text (checked over every occurrence,
/// 2026-10-24): a bare ى only ever follows a tanween (93) or comes before hamzatul waSl (578), and
/// ىٰٓ only ever comes before a hamza (392, across an ayah's end too). Everything else is ىٰ.
struct MaqsurahOrYaaView: View {
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared

    /// The link label's specimen: the two letters in plain print, where the dots still tell them apart.
    static let specimen = "\u{064A} \u{0649}"

    /// The same word written all three ways: عَلَى is spelled each of them in the mushaf, depending
    /// on what follows it.
    private static let spellings: [(word: String, name: String, length: String)] = [
        ("\u{0639}\u{064E}\u{0644}\u{064E}\u{0649}", String(localized: "on its own"), String(localized: "not read when joined")),
        ("\u{0639}\u{064E}\u{0644}\u{064E}\u{0649}\u{0670}", String(localized: "with alif sagheerah"), String(localized: "2 counts")),
        ("\u{0639}\u{064E}\u{0644}\u{064E}\u{0649}\u{0670}\u{0653}", String(localized: "with alif sagheerah and madd"), String(localized: "4 or 5 counts")),
    ]

    private func uthmani(_ base: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        Font.arabic(Settings.hafsUthmaniFontName, size: base, relativeTo: style)
    }

    var body: some View {
        List {
            Group {
                shapeSection
                spellingsSection
                bareSection
                daggerSection
                maddSection
                yaaSection
                rulesSection
                sideBySideSection
                #if os(iOS)
                practiceSection
                #endif
            }
            .themedListRowBackground()
        }
        .selectableArticleList()
        .navigationTitle("MaqSoorah or Yaa")
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

    // MARK: The shape

    /// Print against the mushaf, one column per letter: in print the dots differ, in the mushaf they
    /// are gone from both. The print row is the system face on purpose (see the type's comment).
    @ViewBuilder
    private var shapeSection: some View {
        Section {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
                    columnHead(arabic: "\u{064A}\u{064E}\u{0627}\u{0621}", english: "Yaa")
                    columnHead(arabic: "\u{0623}\u{064E}\u{0644}\u{0650}\u{0641} \u{0645}\u{064E}\u{0642}\u{0635}\u{064F}\u{0648}\u{0631}\u{064E}\u{0629}", english: "Alif MaqSoorah")
                }

                Divider()

                HStack(spacing: 0) {
                    rowHead(String(localized: "Modern print"))
                    Text("\u{0641}\u{064A}")
                        .font(.system(size: 34))
                        .shapeCell(steps: settings.arabicLetterSizeIndex)
                    Text("\u{0639}\u{0644}\u{0649}")
                        .font(.system(size: 34))
                        .shapeCell(steps: settings.arabicLetterSizeIndex)
                }

                Divider()

                HStack(spacing: 0) {
                    rowHead(String(localized: "The mushaf"))
                    Text("\u{0641}\u{0650}\u{064A}")
                        .font(uthmani(34, relativeTo: .largeTitle))
                        .arabicFontDesign(custom: true)
                        .shapeCell(steps: settings.arabicLetterSizeIndex)
                    Text("\u{0639}\u{064E}\u{0644}\u{064E}\u{0649}\u{0670}")
                        .font(uthmani(34, relativeTo: .largeTitle))
                        .arabicFontDesign(custom: true)
                        .shapeCell(steps: settings.arabicLetterSizeIndex)
                }
            }
            .foregroundColor(settings.accentColor.color)
            .padding(.vertical, 2)
            .rowSeparatorFromLeadingEdge()
        } header: {
            Text("THE SHAPE")
        } footer: {
            // Opens on English: a paragraph whose first letter is Arabic is laid out right to left.
            Text("The yaa that ends فِي (\u{201C}in\u{201D}) and the alif maqSoorah that ends عَلَىٰ (\u{201C}on\u{201D}). In print the dots tell them apart; in the mushaf neither has dots.")
        }

        Section {
            ArticleLead(String(localized: "Alif maqSoorah (ى) is an alif written in the shape of a yaa with no dots. It only ever ends a word, and it is read as a long \u{201C}aa\u{201D}. A yaa at the end of a word is read \u{201C}ee\u{201D}, or as a consonant \u{201C}y\u{201D} when it carries a vowel of its own."), eyebrow: String(localized: "IN SHORT"))

            Text("Modern print keeps them apart with the two dots under the yaa. The mushaf writes a final yaa without its dots as well, so the shape alone cannot tell you which letter it is. The marks around it can, every time.")
                .font(.body)
        }
    }

    private func columnHead(arabic: String, english: String) -> some View {
        VStack(spacing: 0) {
            Text(arabic)
                .font(uthmani(20, relativeTo: .title3))
                .arabicFontDesign(custom: true)
                .foregroundColor(settings.accentColor.color)

            if !settings.hideEnglishInArabicLetters {
                Text(english)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func rowHead(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(.secondary)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Alif maqSoorah's three spellings

    private var spellingsSection: some View {
        Section {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Self.spellings, id: \.word) { spelling in
                    VStack(spacing: 2) {
                        Text(spelling.word)
                            .font(uthmani(34, relativeTo: .largeTitle))
                            .arabicFontDesign(custom: true)
                            .arabicLetterTypeFloor(steps: settings.arabicLetterSizeIndex)
                            .foregroundColor(settings.accentColor.color)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)
                            .frame(height: 56)

                        if !settings.hideEnglishInArabicLetters {
                            Text(spelling.name)
                                .font(.caption2.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)

                            Text(spelling.length)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 2)
                    .accessibilityElement(children: .combine)
                }
            }
            // Right to left, like the script: the bare spelling first, on the right.
            .environment(\.layoutDirection, .rightToLeft)
            .padding(.vertical, 4)
        } header: {
            Text("THREE WAYS TO WRITE ALIF MAQSOORAH")
        } footer: {
            Text("The same word, عَلَى (\u{201C}on\u{201D}), is written all three ways in the mushaf. What decides the spelling is what comes next: a word opening with hamzatul waSl, any other letter, or a hamza.")
        }
    }

    private var bareSection: some View {
        Section {
            quranRow("\u{0647}\u{064F}\u{062F}\u{0657}\u{0649} \u{0644}\u{0651}\u{0650}\u{0644}\u{06E1}\u{0645}\u{064F}\u{062A}\u{0651}\u{064E}\u{0642}\u{0650}\u{064A}\u{0646}\u{064E}",
                     reading: "hudal-lil-muttaqeen",
                     note: String(localized: "Guidance for the righteous (2:2): a tanween before it, so the tanween is what you say"))
            quranRow("\u{0639}\u{064E}\u{0644}\u{064E}\u{0649} \u{0671}\u{0644}\u{06E1}\u{0645}\u{064E}\u{0644}\u{064E}\u{0670}\u{0653}\u{0626}\u{0650}\u{0643}\u{064E}\u{0629}\u{0650}",
                     reading: "'alal-malaaa'ikati",
                     note: String(localized: "To the angels (2:31): hamzatul waSl next, so you read straight into the laam"))
            quranRow("\u{0645}\u{064F}\u{0648}\u{0633}\u{064E}\u{0649} \u{0671}\u{0644}\u{06E1}\u{0643}\u{0650}\u{062A}\u{064E}\u{0670}\u{0628}\u{064E}",
                     reading: "Musal-kitaaba",
                     note: String(localized: "Musa the Scripture (2:53): the same rule on a name"))
        } header: {
            Text("ON ITS OWN: \u{0649}")
        } footer: {
            Text("With nothing over it, the long vowel is not read when you join the words. The mushaf writes it bare in two places only: after a tanween, where the tanween is what you say, and before a word that opens with hamzatul waSl, where you read straight on into that word. Stop on the word and it reads \u{201C}aa\u{201D} like the others: هُدٗى is \u{201C}hudaa\u{201D} on its own.")
        }
    }

    private var daggerSection: some View {
        Section {
            quranRow("\u{0639}\u{064E}\u{0644}\u{064E}\u{0649}\u{0670} \u{0647}\u{064F}\u{062F}\u{0657}\u{0649}",
                     reading: "'alaa hudan",
                     note: String(localized: "On guidance (2:5)"))
            quranRow("\u{0625}\u{0650}\u{0644}\u{064E}\u{0649}\u{0670} \u{0634}\u{064E}\u{064A}\u{064E}\u{0670}\u{0637}\u{0650}\u{064A}\u{0646}\u{0650}\u{0647}\u{0650}\u{0645}\u{06E1}",
                     reading: "ilaa shayaaTeenihim",
                     note: String(localized: "With their devils (2:14)"))
            quranRow("\u{0645}\u{064F}\u{0648}\u{0633}\u{064E}\u{0649}\u{0670} \u{0644}\u{0650}\u{0642}\u{064E}\u{0648}\u{06E1}\u{0645}\u{0650}\u{0647}\u{0650}\u{06E6}",
                     reading: "Musaa liqawmihee",
                     note: String(localized: "Musa to his people (2:54)"))
        } header: {
            Text("WITH ALIF SAGHEERAH: \u{0649}\u{0670}")
        } footer: {
            Text("The small alif over it (alif sagheerah, also called the dagger alif) IS the long \u{201C}aa\u{201D}: held for 2 counts like any natural madd. This is the commonest of the three.")
        }
    }

    private var maddSection: some View {
        Section {
            quranRow("\u{0639}\u{064E}\u{0644}\u{064E}\u{0649}\u{0670}\u{0653} \u{0625}\u{0650}\u{0628}\u{06E1}\u{0631}\u{064E}\u{0670}\u{0647}\u{0650}\u{064A}\u{0645}\u{064E}",
                     reading: "'alaaa ibraaheema",
                     note: String(localized: "To Ibrahim (3:84)"))
            quranRow("\u{062D}\u{064E}\u{062A}\u{0651}\u{064E}\u{0649}\u{0670}\u{0653} \u{0625}\u{0650}\u{0630}\u{064E}\u{0627}",
                     reading: "Hattaaa idhaa",
                     note: String(localized: "Until, when (3:152)"))
            quranRow("\u{0645}\u{064F}\u{0648}\u{0633}\u{064E}\u{0649}\u{0670}\u{0653} \u{0623}\u{064E}\u{0631}\u{06E1}\u{0628}\u{064E}\u{0639}\u{0650}\u{064A}\u{0646}\u{064E}",
                     reading: "Musaaa arba'eena",
                     note: String(localized: "Musa, forty (2:51)"))

            TajweedLessonLink(lessonID: "mudood-chart") {
                Label("Learn the Madd Rules", systemImage: "book")
                    .font(.body)
                    .foregroundColor(settings.accentColor.color)
            }
        } header: {
            Text("WITH ALIF SAGHEERAH AND MADD: \u{0649}\u{0670}\u{0653}")
        } footer: {
            Text("The madd sign over the small alif appears only when the next word opens with a hamza. That is madd munfasil, the separated madd: the \u{201C}aa\u{201D} is held 4 or 5 counts in Hafs.")
        }
    }

    // MARK: Yaa

    private var yaaSection: some View {
        Section {
            quranRow("\u{0641}\u{0650}\u{064A}", reading: "fee",
                     note: String(localized: "In (2:10): a kasra before it, the long \u{201C}ee\u{201D}"), letter: "\u{064A}")
            quranRow("\u{0671}\u{0644}\u{0651}\u{064E}\u{0630}\u{0650}\u{064A}", reading: "alladhee",
                     note: String(localized: "The one who (2:17): a kasra before it again"), letter: "\u{064A}")
            quranRow("\u{0631}\u{064E}\u{0628}\u{0651}\u{0650}\u{064A}", reading: "rabbee",
                     note: String(localized: "My Lord (3:51): the kasra rides on the shaddah before it"), letter: "\u{064A}")
            quranRow("\u{0647}\u{0650}\u{064A}\u{064E}", reading: "hiya",
                     note: String(localized: "It is (2:68): a fatha on the yaa itself, so it is the consonant \u{201C}y\u{201D}"), letter: "\u{064A}")
            quranRow("\u{0639}\u{064E}\u{0644}\u{064E}\u{064A}\u{0651}\u{064E}", reading: "'alayya",
                     note: String(localized: "On me (4:72): a shaddah and a fatha on it; only a yaa carries those"), letter: "\u{064A}")
        } header: {
            Text("YAA AT THE END OF A WORD")
        } footer: {
            Text("No dots in the mushaf, so it looks just like alif maqSoorah. Two things give it away: a kasra on the letter before it (the long \u{201C}ee\u{201D}), or a mark on the yaa itself (the consonant \u{201C}y\u{201D}).")
        }
    }

    // MARK: Telling them apart

    private var rulesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                ArticleBullet(String(localized: "- **A small alif over it**, as in عَلَىٰ: alif maqSoorah, always."))
                ArticleBullet(String(localized: "- **A fatha or a tanween on the letter before it**: alif maqSoorah, read \u{201C}aa\u{201D}."))
                ArticleBullet(String(localized: "- **A kasra on the letter before it**, and nothing on the letter: yaa, read \u{201C}ee\u{201D}."))
                ArticleBullet(String(localized: "- **A vowel or a shaddah on the letter itself**: yaa, the consonant \u{201C}y\u{201D}."))
            }
            .font(.body)

            Text("Outside the Quran, modern print settles it with the dots: ي is yaa and ى is alif maqSoorah. Some print, and Egyptian print especially, leaves the yaa undotted too, and then the same marks decide.")
                .font(.body)
        } header: {
            Text("HOW TO TELL THEM APART")
        }
    }

    private var sideBySideSection: some View {
        Section {
            quranRow("\u{0639}\u{0650}\u{064A}\u{0633}\u{064E}\u{0649}\u{0670}", reading: "'Eesaa",
                     note: String(localized: "'Isa (3:52): a yaa as the long \u{201C}ee\u{201D} in the middle, alif maqSoorah at the end"))
            quranRow("\u{064A}\u{064E}\u{062D}\u{06E1}\u{064A}\u{064E}\u{0649}\u{0670}", reading: "Yahyaa",
                     note: String(localized: "Yahya (19:7): two yaas with fathas of their own, then alif maqSoorah"))
            quranRow("\u{0639}\u{064E}\u{0644}\u{064E}\u{0649}\u{0670} \u{00B7} \u{0639}\u{064E}\u{0644}\u{064E}\u{064A}\u{0651}\u{064E}", reading: "'alaa \u{00B7} 'alayya",
                     note: String(localized: "On \u{00B7} on me (2:5, 4:72): the same three letters, alif maqSoorah then yaa"))
            quranRow("\u{0625}\u{0650}\u{0644}\u{064E}\u{0649}\u{0670} \u{00B7} \u{0625}\u{0650}\u{0644}\u{064E}\u{064A}\u{0651}\u{064E}", reading: "ilaa \u{00B7} ilayya",
                     note: String(localized: "To \u{00B7} to Me (2:142, 3:55): the same pair"))
        } header: {
            Text("SIDE BY SIDE")
        } footer: {
            Text("Drawn in the mushaf's own Uthmani hand, the way the Quran reader prints them, whatever your Arabic face is: in other faces a final yaa keeps its dots and the two never look alike.")
        }
    }

    // MARK: Practice

    #if os(iOS)
    /// One link per row (`one-link-per-list-row`).
    private var practiceSection: some View {
        Section {
            ForEach(MaqsurahPracticeView.Mode.allCases) { mode in
                NavigationLink(destination: LazyDestination { MaqsurahPracticeView(mode: mode) }) {
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
    #endif

    /// A Quran word or phrase in the Uthmani hand, with the alif maqSoorah (or `letter`) tinted where
    /// it first occurs.
    private func quranRow(_ arabic: String, reading: String, note: String, letter: String = "\u{0649}") -> some View {
        ArabicExampleRow(
            arabic: arabic,
            transliteration: reading,
            note: note,
            fontName: Settings.hafsUthmaniFontName,
            highlightLetter: letter
        )
    }
}

private extension View {
    /// One cell of THE SHAPE's print-and-mushaf table.
    func shapeCell(steps: Int) -> some View {
        self
            .arabicLetterTypeFloor(steps: steps)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }
}

/// The way in to `MaqsurahOrYaaView` from the pages that meet the question: yaa's PURPOSE section,
/// alif maqSoorah's MAQSURAH OR YAA? section, and the mark sheets of the alif sagheerah and the three
/// maqSoorah spellings. A List row of its own wherever it goes (one link per row).
struct MaqsurahOrYaaLink: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared

    var body: some View {
        NavigationLink(destination: LazyDestination { MaqsurahOrYaaView() }) {
            Label("Alif MaqSoorah or Yaa?", systemImage: "book")
                .font(.body)
                .foregroundColor(settings.accentColor.color)
        }
    }
}

// MARK: - Practice

#if os(iOS)
/// The page's two drills, one question at a time, in `LetterQuizView`'s grammar (a big prompt, tiles
/// to choose from, the reason once you have chosen, then the next): which letter ends a mushaf word,
/// and how long an alif maqSoorah is held. Every word is the Hafs text's own spelling, checked
/// against the mushaf with its reference, and drawn in the Uthmani hand, where a final yaa has no
/// dots and the marks are all there is to go on.
struct MaqsurahPracticeView: View {
    @Environment(\.appearance) private var appearance

    enum Mode: String, CaseIterable, Identifiable {
        /// Alif maqSoorah or yaa?
        case letter
        /// Not read when joined, 2 counts, or 4 or 5 counts?
        case length

        var id: String { rawValue }

        var title: String {
            switch self {
            case .letter: return String(localized: "MaqSoorah or Yaa?")
            case .length: return String(localized: "How Long Is It Held?")
            }
        }

        var caption: String {
            switch self {
            case .letter: return String(localized: "Name the last letter of a mushaf word")
            case .length: return String(localized: "On its own, with alif sagheerah, or with madd")
            }
        }

        var specimen: String {
            switch self {
            case .letter: return "\u{0641}\u{0650}\u{064A}"
            case .length: return "\u{0644}\u{064E}\u{0649}\u{0670}\u{0653}"
            }
        }

        var other: Mode { self == .letter ? .length : .letter }
    }

    /// What the asked-about letter is, which is also the answer.
    enum Kind {
        /// ى on its own: a tanween before it, or hamzatul waSl after it.
        case bare
        /// ىٰ: 2 counts.
        case dagger
        /// ىٰٓ: 4 or 5 counts, a hamza next.
        case madd
        /// A yaa read as the long "ee".
        case yaaVowel
        /// A yaa that carries its own mark: the consonant "y".
        case yaaConsonant

        var isMaqsurah: Bool { self == .bare || self == .dagger || self == .madd }
    }

    struct Item {
        let arabic: String
        let reading: String
        let gloss: String
        let reference: String
        let kind: Kind
        /// Why the answer is what it is, said from the marks the learner can see.
        let why: String
    }

    struct Choice: Identifiable {
        let id: Int
        let text: String
        /// Names the choice once the question is answered (it would give the answer away before).
        let caption: String
    }

    let mode: Mode

    @State private var current: Mode
    @State private var questions: [Item] = []
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

    private func choices(for mode: Mode) -> [Choice] {
        switch mode {
        case .letter:
            return [
                Choice(id: 0, text: String(localized: "Alif MaqSoorah"), caption: String(localized: "read \u{201C}aa\u{201D}")),
                Choice(id: 1, text: String(localized: "Yaa"), caption: String(localized: "read \u{201C}ee\u{201D} or \u{201C}y\u{201D}")),
            ]
        case .length:
            return [
                Choice(id: 0, text: String(localized: "Not read when joined"), caption: String(localized: "on its own, \u{0649}")),
                Choice(id: 1, text: String(localized: "2 counts"), caption: String(localized: "with alif sagheerah, \u{0649}\u{0670}")),
                Choice(id: 2, text: String(localized: "4 or 5 counts"), caption: String(localized: "with alif sagheerah and madd, \u{0649}\u{0670}\u{0653}")),
            ]
        }
    }

    private func answer(for item: Item) -> Int {
        switch current {
        case .letter:
            return item.kind.isMaqsurah ? 0 : 1
        case .length:
            switch item.kind {
            case .bare: return 0
            case .madd: return 2
            default: return 1
            }
        }
    }

    private var ask: String {
        switch current {
        case .letter: return String(localized: "Is the tinted letter alif maqSoorah or yaa?")
        case .length: return String(localized: "How long is the tinted alif maqSoorah held when you read on?")
        }
    }

    /// The prompt with the letter being asked about tinted: the last letter of the first word, which
    /// is where the alif maqSoorah or the yaa sits in every item. One colour run in one Text, so the
    /// joining is untouched.
    private func prompt(_ arabic: String) -> Text {
        var attributed = AttributedString(arabic)
        let wordEnd = arabic.firstIndex(of: " ") ?? arabic.endIndex
        if wordEnd > arabic.startIndex {
            let letterStart = arabic.index(before: wordEnd)
            if let start = AttributedString.Index(letterStart, within: attributed),
               let end = AttributedString.Index(wordEnd, within: attributed) {
                attributed[start..<end].foregroundColor = appearance.accent
            }
        }
        return Text(attributed)
    }

    @ViewBuilder
    private func questionSections(_ item: Item) -> some View {
        let right = answer(for: item)

        Section {
            VStack(spacing: 10) {
                prompt(item.arabic)
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
            // each self-sizing pass, which iOS 26 traps on. The length drill's three answers are
            // phrases, so they stack.
            SummaryTileGrid(columns: current == .letter ? 2 : 1) {
                ForEach(choices(for: current)) { choice in
                    choiceButton(choice, right: right)
                }
            }
            .padding(.vertical, 4)

            if let chosen {
                VStack(alignment: .leading, spacing: 6) {
                    Label(chosen == right ? String(localized: "Right") : String(localized: "Not quite"),
                          systemImage: chosen == right ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(chosen == right ? .green : .red)

                    Text(item.why)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)

                // The word itself, read and glossed, with its place in the Quran.
                HStack(spacing: 12) {
                    PracticeListenButton(text: item.arabic)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.reading)
                            .font(.subheadline.weight(.semibold))

                        Text("\u{201C}\(item.gloss)\u{201D} (Quran \(item.reference.localizedDigits))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
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
                Text(choice.text)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if answered {
                    Text(choice.caption)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity, minHeight: current == .letter ? 64 : 52)
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
        .accessibilityLabel(answered ? "\(choice.text), \(choice.caption)" : choice.text)
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

            Button {
                Settings.shared.hapticFeedback()
                start(current.other)
            } label: {
                Label(current.other.title, systemImage: "arrow.forward.circle")
                    .font(.body)
                    .foregroundColor(appearance.accent)
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

    /// Ten a round. The letter drill takes five of each letter; the length drill four bare spellings
    /// and three of each of the others.
    private static func makeRound(_ mode: Mode) -> [Item] {
        switch mode {
        case .letter:
            let maqsurah = letterItems.filter { $0.kind.isMaqsurah }.shuffled().prefix(5)
            let yaa = letterItems.filter { !$0.kind.isMaqsurah }.shuffled().prefix(5)
            return (Array(maqsurah) + Array(yaa)).shuffled()
        case .length:
            let bare = lengthItems.filter { $0.kind == .bare }.shuffled().prefix(4)
            let dagger = lengthItems.filter { $0.kind == .dagger }.shuffled().prefix(3)
            let madd = lengthItems.filter { $0.kind == .madd }.shuffled().prefix(3)
            return (Array(bare) + Array(dagger) + Array(madd)).shuffled()
        }
    }

    // MARK: The words

    /// Single words, each the Hafs text's spelling at the reference given.
    private static let letterItems: [Item] = [
        Item(arabic: "\u{0639}\u{064E}\u{0644}\u{064E}\u{0649}\u{0670}", reading: "'alaa", gloss: "on", reference: "2:5", kind: .dagger,
             why: String(localized: "The small alif over it marks alif maqSoorah: the long \u{201C}aa\u{201D}.")),
        Item(arabic: "\u{0625}\u{0650}\u{0644}\u{064E}\u{0649}\u{0670}", reading: "ilaa", gloss: "to", reference: "2:142", kind: .dagger,
             why: String(localized: "A fatha on the laam before it and a small alif over it: alif maqSoorah.")),
        Item(arabic: "\u{0645}\u{064F}\u{0648}\u{0633}\u{064E}\u{0649}\u{0670}", reading: "Musaa", gloss: "Musa", reference: "2:54", kind: .dagger,
             why: String(localized: "A fatha on the seen before it and a small alif over it: alif maqSoorah.")),
        Item(arabic: "\u{0628}\u{064E}\u{0644}\u{064E}\u{0649}\u{0670}", reading: "balaa", gloss: "Yes", reference: "2:81", kind: .dagger,
             why: String(localized: "The small alif over it marks alif maqSoorah: \u{201C}balaa\u{201D}.")),
        Item(arabic: "\u{0645}\u{064E}\u{062A}\u{064E}\u{0649}\u{0670}", reading: "mataa", gloss: "When", reference: "2:214", kind: .dagger,
             why: String(localized: "A fatha on the taa before it and a small alif over it: alif maqSoorah.")),
        Item(arabic: "\u{062D}\u{064E}\u{062A}\u{0651}\u{064E}\u{0649}\u{0670}", reading: "Hattaa", gloss: "until", reference: "2:55", kind: .dagger,
             why: String(localized: "The fatha rides on the shaddah before it, and the small alif marks alif maqSoorah.")),
        Item(arabic: "\u{0648}\u{064E}\u{0643}\u{064E}\u{0641}\u{064E}\u{0649}\u{0670}", reading: "wakafaa", gloss: "And sufficient is", reference: "4:6", kind: .dagger,
             why: String(localized: "A fatha on the faa before it and a small alif over it: alif maqSoorah.")),
        Item(arabic: "\u{0647}\u{064F}\u{062F}\u{0657}\u{0649}", reading: "hudan", gloss: "guidance", reference: "2:2", kind: .bare,
             why: String(localized: "A tanween on the daal before it: alif maqSoorah on its own. Joined, it reads \u{201C}hudan\u{201D}; stop on it and it is \u{201C}hudaa\u{201D}.")),
        Item(arabic: "\u{0639}\u{0650}\u{064A}\u{0633}\u{064E}\u{0649}\u{0670}", reading: "'Eesaa", gloss: "'Isa", reference: "3:52", kind: .dagger,
             why: String(localized: "The last letter carries a small alif: alif maqSoorah. The yaa in the middle, after a kasra, is the long \u{201C}ee\u{201D}.")),
        Item(arabic: "\u{064A}\u{064E}\u{062D}\u{06E1}\u{064A}\u{064E}\u{0649}\u{0670}", reading: "Yahyaa", gloss: "Yahya", reference: "19:7", kind: .dagger,
             why: String(localized: "A small alif over the last letter: alif maqSoorah. The two yaas before it carry fathas, so they are consonants.")),
        Item(arabic: "\u{0641}\u{0650}\u{064A}", reading: "fee", gloss: "in", reference: "2:10", kind: .yaaVowel,
             why: String(localized: "A kasra on the faa before it and nothing on the letter: a yaa, the long \u{201C}ee\u{201D}.")),
        Item(arabic: "\u{0644}\u{0650}\u{064A}", reading: "lee", gloss: "to Me", reference: "2:152", kind: .yaaVowel,
             why: String(localized: "A kasra on the laam before it: a yaa, read \u{201C}lee\u{201D}.")),
        Item(arabic: "\u{0671}\u{0644}\u{0651}\u{064E}\u{0630}\u{0650}\u{064A}", reading: "alladhee", gloss: "the one who", reference: "2:17", kind: .yaaVowel,
             why: String(localized: "A kasra on the dhaal before it: a yaa, the long \u{201C}ee\u{201D}.")),
        Item(arabic: "\u{0671}\u{0644}\u{0651}\u{064E}\u{062A}\u{0650}\u{064A}", reading: "allatee", gloss: "whose", reference: "2:24", kind: .yaaVowel,
             why: String(localized: "A kasra on the taa before it: a yaa, the long \u{201C}ee\u{201D}.")),
        Item(arabic: "\u{0631}\u{064E}\u{0628}\u{0651}\u{0650}\u{064A}", reading: "rabbee", gloss: "my Lord", reference: "3:51", kind: .yaaVowel,
             why: String(localized: "The kasra rides on the shaddah before it: a yaa, the long \u{201C}ee\u{201D}.")),
        Item(arabic: "\u{0625}\u{0650}\u{0646}\u{0651}\u{0650}\u{064A}", reading: "innee", gloss: "Indeed, I", reference: "2:30", kind: .yaaVowel,
             why: String(localized: "A kasra under the doubled noon before it: a yaa, read \u{201C}innee\u{201D}.")),
        Item(arabic: "\u{062A}\u{064E}\u{062C}\u{06E1}\u{0631}\u{0650}\u{064A}", reading: "tajree", gloss: "flow", reference: "2:25", kind: .yaaVowel,
             why: String(localized: "A kasra on the raa before it: a yaa, the long \u{201C}ee\u{201D}.")),
        Item(arabic: "\u{064A}\u{064E}\u{0647}\u{06E1}\u{062F}\u{0650}\u{064A}", reading: "yahdee", gloss: "He guides", reference: "2:142", kind: .yaaVowel,
             why: String(localized: "A kasra on the daal before it: a yaa, the long \u{201C}ee\u{201D}.")),
        Item(arabic: "\u{0647}\u{0650}\u{064A}\u{064E}", reading: "hiya", gloss: "it (is)", reference: "2:68", kind: .yaaConsonant,
             why: String(localized: "The letter carries a fatha of its own, and only a yaa can: the consonant \u{201C}y\u{201D}, \u{201C}hiya\u{201D}.")),
        Item(arabic: "\u{0645}\u{064E}\u{0639}\u{0650}\u{064A}\u{064E}", reading: "ma'iya", gloss: "with me", reference: "7:105", kind: .yaaConsonant,
             why: String(localized: "A fatha on the letter itself: a yaa, the consonant \u{201C}y\u{201D}.")),
        Item(arabic: "\u{0639}\u{064E}\u{0644}\u{064E}\u{064A}\u{0651}\u{064E}", reading: "'alayya", gloss: "on me", reference: "4:72", kind: .yaaConsonant,
             why: String(localized: "A shaddah and a fatha on the letter itself: a yaa, \u{201C}'alayya\u{201D}. Compare عَلَىٰ, \u{201C}'alaa\u{201D}.")),
        Item(arabic: "\u{0625}\u{0650}\u{0644}\u{064E}\u{064A}\u{0651}\u{064E}", reading: "ilayya", gloss: "to Myself", reference: "3:55", kind: .yaaConsonant,
             why: String(localized: "A shaddah and a fatha on the letter itself: a yaa, \u{201C}ilayya\u{201D}. Compare إِلَىٰ, \u{201C}ilaa\u{201D}.")),
    ]

    /// Two-word phrases, so the reason for the spelling (the word after it) is on screen.
    private static let lengthItems: [Item] = [
        Item(arabic: "\u{0647}\u{064F}\u{062F}\u{0657}\u{0649} \u{0644}\u{0651}\u{0650}\u{0644}\u{06E1}\u{0645}\u{064F}\u{062A}\u{0651}\u{064E}\u{0642}\u{0650}\u{064A}\u{0646}\u{064E}",
             reading: "hudal-lil-muttaqeen", gloss: "guidance for the righteous", reference: "2:2", kind: .bare,
             why: String(localized: "Nothing over it, and a tanween before it: the tanween is what you say, so the alif is not read. Stopping on هُدٗى, it is \u{201C}hudaa\u{201D}.")),
        Item(arabic: "\u{0639}\u{064E}\u{0644}\u{064E}\u{0649} \u{0671}\u{0644}\u{06E1}\u{0645}\u{064E}\u{0644}\u{064E}\u{0670}\u{0653}\u{0626}\u{0650}\u{0643}\u{064E}\u{0629}\u{0650}",
             reading: "'alal-malaaa'ikati", gloss: "to the angels", reference: "2:31", kind: .bare,
             why: String(localized: "Nothing over it, and the next word opens with hamzatul waSl: the long vowel drops and you read straight into the laam.")),
        Item(arabic: "\u{0645}\u{064F}\u{0648}\u{0633}\u{064E}\u{0649} \u{0671}\u{0644}\u{06E1}\u{0643}\u{0650}\u{062A}\u{064E}\u{0670}\u{0628}\u{064E}",
             reading: "Musal-kitaaba", gloss: "Musa the Scripture", reference: "2:53", kind: .bare,
             why: String(localized: "Nothing over it, and hamzatul waSl next: not read when joined, \u{201C}Musal-kitaaba\u{201D}.")),
        Item(arabic: "\u{0639}\u{0650}\u{064A}\u{0633}\u{064E}\u{0649} \u{0671}\u{0628}\u{06E1}\u{0646}\u{064E}",
             reading: "'Eesabna", gloss: "'Isa, the son", reference: "2:87", kind: .bare,
             why: String(localized: "Nothing over it, and hamzatul waSl next: the long vowel drops, \u{201C}'Eesabna\u{201D}.")),
        Item(arabic: "\u{0648}\u{064E}\u{062A}\u{064E}\u{0631}\u{064E}\u{0649} \u{0671}\u{0644}\u{06E1}\u{0645}\u{064F}\u{062C}\u{06E1}\u{0631}\u{0650}\u{0645}\u{0650}\u{064A}\u{0646}\u{064E}",
             reading: "wa taral-mujrimeena", gloss: "and you will see the criminals", reference: "14:49", kind: .bare,
             why: String(localized: "Nothing over it, and hamzatul waSl next: not read when joined, \u{201C}taral-mujrimeena\u{201D}.")),
        Item(arabic: "\u{0639}\u{064E}\u{0644}\u{064E}\u{0649}\u{0670} \u{0647}\u{064F}\u{062F}\u{0657}\u{0649}",
             reading: "'alaa hudan", gloss: "on guidance", reference: "2:5", kind: .dagger,
             why: String(localized: "A small alif over it and an ordinary letter next: the natural 2 counts.")),
        Item(arabic: "\u{0625}\u{0650}\u{0644}\u{064E}\u{0649}\u{0670} \u{0634}\u{064E}\u{064A}\u{064E}\u{0670}\u{0637}\u{0650}\u{064A}\u{0646}\u{0650}\u{0647}\u{0650}\u{0645}\u{06E1}",
             reading: "ilaa shayaaTeenihim", gloss: "with their devils", reference: "2:14", kind: .dagger,
             why: String(localized: "A small alif with no madd sign: 2 counts.")),
        Item(arabic: "\u{0645}\u{064F}\u{0648}\u{0633}\u{064E}\u{0649}\u{0670} \u{0644}\u{0650}\u{0642}\u{064E}\u{0648}\u{06E1}\u{0645}\u{0650}\u{0647}\u{0650}\u{06E6}",
             reading: "Musaa liqawmihee", gloss: "Musa to his people", reference: "2:54", kind: .dagger,
             why: String(localized: "A small alif over it and a laam next: 2 counts.")),
        Item(arabic: "\u{0628}\u{064E}\u{0644}\u{064E}\u{0649}\u{0670} \u{0648}\u{064E}\u{0644}\u{064E}\u{0670}\u{0643}\u{0650}\u{0646}",
             reading: "balaa wa laakin", gloss: "Yes, but", reference: "2:260", kind: .dagger,
             why: String(localized: "A small alif with no madd sign: 2 counts.")),
        Item(arabic: "\u{0639}\u{064E}\u{0644}\u{064E}\u{0649}\u{0670}\u{0653} \u{0625}\u{0650}\u{0628}\u{06E1}\u{0631}\u{064E}\u{0670}\u{0647}\u{0650}\u{064A}\u{0645}\u{064E}",
             reading: "'alaaa ibraaheema", gloss: "to Ibrahim", reference: "3:84", kind: .madd,
             why: String(localized: "The madd sign over the small alif, and a hamza opens the next word: madd munfasil, 4 or 5 counts.")),
        Item(arabic: "\u{0625}\u{0650}\u{0644}\u{064E}\u{0649}\u{0670}\u{0653} \u{0623}\u{064E}\u{0634}\u{064E}\u{062F}\u{0651}\u{0650}",
             reading: "ilaaa ashaddi", gloss: "to the most severe", reference: "2:85", kind: .madd,
             why: String(localized: "A hamza opens the next word, so the small alif carries the madd sign: 4 or 5 counts.")),
        Item(arabic: "\u{062D}\u{064E}\u{062A}\u{0651}\u{064E}\u{0649}\u{0670}\u{0653} \u{0625}\u{0650}\u{0630}\u{064E}\u{0627}",
             reading: "Hattaaa idhaa", gloss: "until, when", reference: "3:152", kind: .madd,
             why: String(localized: "The madd sign, then a hamza: madd munfasil, 4 or 5 counts.")),
        Item(arabic: "\u{0645}\u{064F}\u{0648}\u{0633}\u{064E}\u{0649}\u{0670}\u{0653} \u{0623}\u{064E}\u{0631}\u{06E1}\u{0628}\u{064E}\u{0639}\u{0650}\u{064A}\u{0646}\u{064E}",
             reading: "Musaaa arba'eena", gloss: "Musa, forty", reference: "2:51", kind: .madd,
             why: String(localized: "The madd sign over the small alif, and a hamza next: 4 or 5 counts.")),
    ]
}
#endif
