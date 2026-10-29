import SwiftUI

// MARK: - The vowel letters

/// Alif, waaw and yaa: when each is a vowel and when a consonant, and the rule that decides it (Abu,
/// 2026-10-28: "Add a section to tell whether the 3 vowel letters are vowels or consonants with
/// examples. alif is always vowel. Then test it and explain why and when waw and yaa are
/// vowels/consonants. Put it in alif waaw and yaa and make a section for vowel letters").
///
/// Every example is a word from the Reading Test's verified bank, sorted by `VowelLetterRoles` from
/// its marks; nothing on this page types a word. iPhone only, like the bank it reads.
struct VowelLettersView: View {
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    @Environment(\.appearance) private var appearance
    @ObservedObject private var islamSettings = IslamSettings.shared

    /// The link tile's specimen: the three letters, right to left.
    static let specimen = "\u{0627}\u{2009}\u{0648}\u{2009}\u{064A}"

    var body: some View {
        List {
            Group {
                lettersSection
                howToTellSection
                VowelRoleSection(letter: VowelLetterRoles.alif)
                VowelRoleSection(letter: VowelLetterRoles.waaw)
                VowelRoleSection(letter: VowelLetterRoles.yaa)
                practiceSection
            }
            .themedListRowBackground()
        }
        .applyConditionalListStyle()
        .navigationTitle("Vowel Letters")
        .onDisappear {
            ArabicSpeech.shared.stop()
            ArabicPracticeSelection.shared.clear()
        }
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
    }

    // MARK: The three letters

    private static let letters: [(arabic: String, name: String, role: String)] = [
        ("\u{0627}", String(localized: "Alif"), String(localized: "Always a vowel")),
        ("\u{0648}", String(localized: "Waaw"), String(localized: "Vowel or consonant")),
        ("\u{064A}", String(localized: "Yaa"), String(localized: "Vowel or consonant")),
    ]

    private var lettersSection: some View {
        Section {
            HStack(spacing: 8) {
                ForEach(Self.letters, id: \.arabic) { letter in
                    VStack(spacing: 4) {
                        // The plain system face, whatever the reader's: the mushaf faces draw a lone yaa
                        // without its dots, which is the shape of alif maqSoorah (the dotless بى trap).
                        Text(letter.arabic)
                            .font(.largeTitle)
                            .arabicLetterTypeFloor(steps: islamSettings.arabicLetterSizeIndex)
                            .foregroundColor(appearance.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.4)

                        Text(letter.name)
                            .font(.caption.weight(.semibold))

                        Text(letter.role)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(appearance.accent.opacity(0.08))
                    )
                    .accessibilityElement(children: .combine)
                }
            }
            // Right to left, like the script: alif on the right.
            .environment(\.layoutDirection, .rightToLeft)
            .padding(.vertical, 4)

            ArticleLead(String(localized: "Arabic has three vowel letters: alif, waaw and yaa. Each can stretch the short vowel before it into a long one. Alif does nothing else, so it is always a vowel. Waaw and yaa lead double lives: in some words they are the long vowels \u{201C}oo\u{201D} and \u{201C}ee\u{201D}, in others the consonants \u{201C}w\u{201D} and \u{201C}y\u{201D}. The marks around the letter tell you which, every time."), eyebrow: String(localized: "IN SHORT"))
        } header: {
            Text("THE THREE VOWEL LETTERS")
        }
    }

    // MARK: How to tell

    private var howToTellSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                ArticleBullet(String(localized: "- **Is it alif?** A vowel: the long \u{201C}aa\u{201D} after a fatha. A hamza on it (\u{0623} \u{0625}) is a different letter, and that hamza is a consonant."))
                ArticleBullet(String(localized: "- **Does it open the word?** A consonant. No Arabic word begins on a vowel."))
                ArticleBullet(String(localized: "- **Does it carry a fatha, kasra, damma, tanween or shaddah?** A consonant: a letter with a vowel of its own is a consonant."))
                ArticleBullet(String(localized: "- **A sukoon, with a fatha before it?** A consonant: the leen (soft) letter. The fatha glides into it, \u{201C}aw\u{201D} or \u{201C}ay\u{201D}, and nothing is stretched."))
                ArticleBullet(String(localized: "- **No mark, and the matching vowel before it?** A vowel: a damma before waaw makes the long \u{201C}oo\u{201D}, a kasra before yaa the long \u{201C}ee\u{201D}, held for 2 counts."))
            }
            .font(.body)
        } header: {
            Text("HOW TO TELL")
        } footer: {
            Text("Ask in this order and the first yes settles it. Every word below is from the Quran, with the letter in question tinted.")
        }
    }

    // MARK: Practice

    private var practiceSection: some View {
        Section {
            VowelOrConsonantPracticeLink(letter: nil)

            TajweedLessonLink(lessonID: "mudood-chart") {
                Label("Learn the Madd Rules", systemImage: "book")
                    .font(.body)
                    .foregroundColor(appearance.accent)
            }
        } header: {
            Text("PRACTICE")
        } footer: {
            Text("Ten Quran words a round, half of them vowels and half consonants. After each answer you see the rule that decides it.")
        }
    }
}

// MARK: - One letter's examples

/// One letter's rules, each with a Quran word that follows it: the section the topic page shows for
/// all three letters and the alif, waaw and yaa pages show for their own. Vowel rules first, then
/// consonant ones.
struct VowelRoleSection: View {
    @Environment(\.appearance) private var appearance

    let letter: String
    /// On a letter's own page: the topic page and the practice, each on a List row of its own.
    var showsLinks = false

    private var isAlif: Bool { letter == VowelLetterRoles.alif }

    private var header: String {
        switch letter {
        case VowelLetterRoles.alif: return String(localized: "ALIF: ALWAYS A VOWEL")
        case VowelLetterRoles.waaw: return String(localized: "WAAW: VOWEL OR CONSONANT?")
        default: return String(localized: "YAA: VOWEL OR CONSONANT?")
        }
    }

    private var footer: String {
        switch letter {
        case VowelLetterRoles.alif:
            return String(localized: "Alif never carries a vowel of its own, so it is never a consonant. When a word seems to open on an alif, look again: that is a hamza on it (\u{0623} \u{0625}), and the hamza is the consonant. The alif is only its seat.")
        case VowelLetterRoles.waaw:
            return String(localized: "Waaw is the vowel \u{201C}oo\u{201D} only when it is bare and a damma comes before it. Anything that gives it a sound of its own makes it the consonant \u{201C}w\u{201D}: a vowel or a shaddah on it, or a place at the start of the word. With a sukoon after a fatha it is the leen letter, the soft \u{201C}w\u{201D} of \u{201C}aw\u{201D}.")
        default:
            return String(localized: "Yaa is the vowel \u{201C}ee\u{201D} only when it is bare and a kasra comes before it. Anything that gives it a sound of its own makes it the consonant \u{201C}y\u{201D}: a vowel or a shaddah on it, or a place at the start of the word. With a sukoon after a fatha it is the leen letter, the soft \u{201C}y\u{201D} of \u{201C}ay\u{201D}.")
        }
    }

    var body: some View {
        Section {
            ForEach(VowelLetterRoles.examples(for: letter), id: \.self) { occurrence in
                VowelRoleRow(occurrence: occurrence)
            }

            if showsLinks {
                VowelLettersLink()
                VowelOrConsonantPracticeLink(letter: letter)
            }
        } header: {
            Text(header)
        } footer: {
            Text(footer)
        }
    }
}

/// One Quran word with the vowel letter tinted, its verdict (VOWEL or CONSONANT) and the rule that
/// decides it. The verdict and the rule stay under Hide English: they are the lesson, like the rule
/// notes elsewhere; only the reading and the gloss (the answers to the Arabic) hide.
struct VowelRoleRow: View {
    @Environment(\.appearance) private var appearance
    /// Snapshotted at creation (the NameRow rule): this row observes nothing, so the parent hands
    /// it every Settings field its body reads and rebuilds it when one changes.
    var letterSizeSteps: Int = Settings.shared.arabicLetterSizeIndex
    var hideEnglish: Bool = Settings.shared.hideEnglishInArabicLetters
    var quranicSukoon: Bool = Settings.shared.quranicSukoonInLetterPractice
    @ObservedObject private var selection = ArabicPracticeSelection.shared

    let occurrence: VowelLetterRoles.Occurrence

    private var id: String { "vowelRole:\(occurrence.item.arabic):\(occurrence.letterIndex)" }

    var body: some View {
        let isSelected = selection.isSelected(id)
        let reason = occurrence.reason

        return HStack(alignment: .center, spacing: 12) {
            if isSelected {
                PracticeListenButton(text: occurrence.item.spoken)
            }

            VStack(alignment: .leading, spacing: 4) {
                VowelVerdictChip(isVowel: reason.isVowel)

                Text(VowelRoleText.rule(for: occurrence))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if !hideEnglish {
                    Text(occurrence.item.reading)
                        .font(.subheadline.weight(.semibold))

                    if let gloss = VowelRoleText.gloss(occurrence.item) {
                        Text(gloss)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Spacer(minLength: 8)

            VowelRoleText.tinted(occurrence, quranicSukoon: quranicSukoon, tint: appearance.accent)
                .font(appearance.useFontArabic
                      ? appearance.islamArabicFont(base: 26, relativeTo: .title2)
                      : .title2)
                .arabicFontDesign(custom: appearance.useFontArabic && appearance.islamUsesCustomArabicFace)
                .arabicLetterTypeFloor(steps: letterSizeSteps)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .arabicPracticeRowSelection(isSelected, hInset: -8, vInset: -2)
        .onTapGesture {
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut) { selection.toggle(id) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(isSelected
            ? String(localized: "\(occurrence.item.reading), \(VowelRoleText.verdict(reason.isVowel)), \(VowelRoleText.rule(for: occurrence)), selected")
            : String(localized: "\(occurrence.item.reading), \(VowelRoleText.verdict(reason.isVowel)), \(VowelRoleText.rule(for: occurrence))"))
    }
}

/// VOWEL or CONSONANT, as a small capsule: the accent for a vowel, plain grey for a consonant.
struct VowelVerdictChip: View {
    @Environment(\.appearance) private var appearance
    let isVowel: Bool

    var body: some View {
        Text(VowelRoleText.verdict(isVowel).uppercased())
            .font(.caption2.weight(.bold))
            .foregroundColor(isVowel ? appearance.accent : .primary)
            .padding(.horizontal, 8)
            // Nastaliq's tall strokes rise past the line box: Urdu gets the room to stay inside the capsule.
            .padding(.vertical, AppLanguage.isUrdu ? 6 : 3)
            .background(Capsule().fill((isVowel ? appearance.accent : Color.secondary).opacity(0.16)))
    }
}

/// The way in to `VowelLettersView` from the alif, waaw and yaa pages. A List row of its own
/// wherever it goes (one link per row).
struct VowelLettersLink: View {
    @Environment(\.appearance) private var appearance

    var body: some View {
        NavigationLink(destination: LazyDestination { VowelLettersView() }) {
            Label("Vowel Letters: Vowel or Consonant?", systemImage: "book")
                .font(.body)
                .foregroundColor(appearance.accent)
        }
    }
}

/// The practice, for one letter or (nil) all three. A List row of its own.
struct VowelOrConsonantPracticeLink: View {
    @Environment(\.appearance) private var appearance
    let letter: String?

    var body: some View {
        NavigationLink(destination: LazyDestination { VowelOrConsonantPracticeView(letter: letter) }) {
            // The bare letter in the plain face: a lone yaa in a mushaf face loses its dots.
            ArabicTopicLinkLabel(specimen: letter ?? VowelLetterRoles.waaw,
                                 title: VowelOrConsonantPracticeView.title(for: letter),
                                 caption: String(localized: "Is the tinted letter a vowel or a consonant?"),
                                 face: .plain)
        }
        .tint(appearance.accent)
    }
}

// MARK: - The words of the explanations

/// Every sentence the rows and the practice say about a letter, built from the occurrence's own marks
/// and syllable, so an explanation can never disagree with the word it is about.
enum VowelRoleText {
    /// Dotted keys: the catalog's plain "Vowel" is a harakah (الحركة, حرکت), the mark, and this is the
    /// letter's role (the shared-key sense clash the Localization Guide warns about).
    static func verdict(_ isVowel: Bool) -> String {
        isVowel ? String(localized: "vowelLetters.vowel", defaultValue: "Vowel")
            : String(localized: "vowelLetters.consonant", defaultValue: "Consonant")
    }

    /// "a fatha", "a tanween", ... for the mark a rule turns on.
    private static func markName(_ mark: Unicode.Scalar?) -> String {
        switch mark {
        case ReadingTestText.fatha?: return String(localized: "a fatha")
        case ReadingTestText.kasra?: return String(localized: "a kasra")
        case ReadingTestText.damma?: return String(localized: "a damma")
        case ReadingTestText.mushafSukoon?: return String(localized: "a sukoon")
        default: return String(localized: "a tanween")
        }
    }

    /// The rule in a few words, for the row under the verdict.
    static func rule(for occurrence: VowelLetterRoles.Occurrence) -> String {
        let mark = markName(occurrence.mark)
        switch occurrence.reason {
        case .opensWord: return String(localized: "Opens the word")
        case .ownVowel: return String(localized: "Carries \(mark) of its own")
        case .shaddah: return String(localized: "Carries a shaddah")
        case .leen: return String(localized: "Sukoon after a fatha: the leen letter")
        case .longVowel: return String(localized: "No mark, \(mark) before it")
        case .maddVowel: return String(localized: "The madd sign, \(mark) before it")
        case .alifLong: return String(localized: "After a fatha: the long \u{201C}aa\u{201D}")
        case .alifMadd: return String(localized: "The madd sign: the long \u{201C}aa\u{201D}, held longer")
        case .hamzaSeat: return String(localized: "A hamza on the alif: the hamza is the consonant")
        }
    }

    /// The full reason, said once the practice has been answered. One sentence per letter wherever the
    /// English quotes the letter's sound ("w", "oo"): spliced in as an argument, that Latin token would
    /// have to stand in the Arabic and Urdu too, which say the same thing without it.
    static func why(for occurrence: VowelLetterRoles.Occurrence) -> String {
        let isWaaw = occurrence.letter == VowelLetterRoles.waaw
        let mark = markName(occurrence.mark)
        let sentence: String
        switch occurrence.reason {
        case .opensWord:
            sentence = isWaaw
                ? String(localized: "Waaw opens the word, and no Arabic word begins on a vowel, so it is the consonant \u{201C}w\u{201D}.")
                : String(localized: "Yaa opens the word, and no Arabic word begins on a vowel, so it is the consonant \u{201C}y\u{201D}.")
        case .ownVowel:
            sentence = isWaaw
                ? String(localized: "Waaw carries \(mark) of its own, and a letter with its own vowel is a consonant: the \u{201C}w\u{201D} sound.")
                : String(localized: "Yaa carries \(mark) of its own, and a letter with its own vowel is a consonant: the \u{201C}y\u{201D} sound.")
        case .shaddah:
            sentence = isWaaw
                ? String(localized: "Waaw carries a shaddah: it is said twice, \u{201C}ww\u{201D}, closing one syllable and opening the next. A doubled letter is a consonant.")
                : String(localized: "Yaa carries a shaddah: it is said twice, \u{201C}yy\u{201D}, closing one syllable and opening the next. A doubled letter is a consonant.")
        case .leen:
            sentence = isWaaw
                ? String(localized: "Waaw has a sukoon and the letter before it a fatha. Nothing is stretched: the fatha glides into a soft \u{201C}w\u{201D}, \u{201C}aw\u{201D} as in \u{201C}cow\u{201D}. This is the leen (soft) letter, a consonant.")
                : String(localized: "Yaa has a sukoon and the letter before it a fatha. Nothing is stretched: the fatha glides into a soft \u{201C}y\u{201D}, \u{201C}ay\u{201D} as in \u{201C}day\u{201D}. This is the leen (soft) letter, a consonant.")
        case .longVowel:
            sentence = isWaaw
                ? String(localized: "Waaw has no mark of its own, and the letter before it carries a damma: together they make the long \u{201C}oo\u{201D}, held for 2 counts. A vowel.")
                : String(localized: "Yaa has no mark of its own, and the letter before it carries a kasra: together they make the long \u{201C}ee\u{201D}, held for 2 counts. A vowel.")
        case .maddVowel:
            sentence = isWaaw
                ? String(localized: "Waaw has no vowel of its own, a damma comes before it, and the madd sign is over it: the long \u{201C}oo\u{201D}, held longer than its natural 2 counts. A vowel.")
                : String(localized: "Yaa has no vowel of its own, a kasra comes before it, and the madd sign is over it: the long \u{201C}ee\u{201D}, held longer than its natural 2 counts. A vowel.")
        case .alifLong:
            sentence = String(localized: "Alif never carries a vowel of its own. After a fatha it is the long \u{201C}aa\u{201D}, held for 2 counts: a vowel, every time.")
        case .alifMadd:
            sentence = String(localized: "Alif with the madd sign over it: the long \u{201C}aa\u{201D}, held longer than its natural 2 counts. Still a vowel: the sign only lengthens it.")
        case .hamzaSeat:
            sentence = String(localized: "This is a hamza, not a bare alif: the hamza carries \(mark) and is the consonant, a catch in the throat. The alif is only its seat.")
        }
        guard let syllable = occurrence.syllable?.reading, !syllable.isEmpty else { return sentence }
        return sentence + " " + String(localized: "The syllable is read \u{201C}\(syllable)\u{201D}.")
    }

    /// "“And He” (Quran 2:29)", or nil when the bank has neither.
    static func gloss(_ item: ReadingItem) -> String? {
        switch (item.gloss, item.reference) {
        case let (gloss?, reference?): return String(localized: "\u{201C}\(gloss)\u{201D} (Quran \(reference.localizedDigits))")
        case let (gloss?, nil): return "\u{201C}\(gloss)\u{201D}"
        case let (nil, reference?): return String(localized: "Quran \(reference.localizedDigits)")
        case (nil, nil): return nil
        }
    }

    /// The word in the chosen sukoon, with THIS occurrence of the letter tinted. One colour run in one
    /// Text, so the joining is untouched.
    static func tinted(_ occurrence: VowelLetterRoles.Occurrence, quranicSukoon: Bool, tint: Color) -> Text {
        let shown = ReadingTestText.display(occurrence.item.arabic, mushafMarks: quranicSukoon)
        var attributed = AttributedString(shown)
        if let range = ArabicLetterMatch.range(of: occurrence.letter, in: shown, letterIndex: occurrence.letterIndex),
           let start = AttributedString.Index(range.lowerBound, within: attributed),
           let end = AttributedString.Index(range.upperBound, within: attributed) {
            attributed[start..<end].foregroundColor = tint
        }
        return Text(attributed)
    }
}

// MARK: - Practice

/// Vowel or consonant? One Quran word at a time with one vowel letter tinted, in `MaqsurahPracticeView`'s
/// grammar: a big prompt, two tiles, the rule once you have chosen, then the next. The round is built
/// by `VowelLetterRoles.round`: half vowels and half consonants, the consonants spread over their rules.
struct VowelOrConsonantPracticeView: View {
    @Environment(\.appearance) private var appearance
    @ObservedObject private var islamSettings = IslamSettings.shared

    /// ا, و or ي for one letter's round, nil for all three.
    let letter: String?

    @State private var questions: [VowelLetterRoles.Occurrence] = []
    @State private var index = 0
    /// The tile chosen for this question: true for Vowel.
    @State private var chosen: Bool?
    @State private var correct = 0
    @State private var finished = false

    static func title(for letter: String?) -> String {
        switch letter {
        case VowelLetterRoles.alif?: return String(localized: "Alif: Vowel or Consonant?")
        case VowelLetterRoles.waaw?: return String(localized: "Waaw: Vowel or Consonant?")
        case VowelLetterRoles.yaa?: return String(localized: "Yaa: Vowel or Consonant?")
        default: return String(localized: "Vowel or Consonant?")
        }
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
        .navigationTitle(Self.title(for: letter))
        .onAppear { if questions.isEmpty { start() } }
        .onDisappear { ArabicSpeech.shared.stop() }
    }

    // MARK: Asking

    @ViewBuilder
    private func questionSections(_ occurrence: VowelLetterRoles.Occurrence) -> some View {
        let isVowel = occurrence.reason.isVowel

        Section {
            VStack(spacing: 10) {
                VowelRoleText.tinted(occurrence, quranicSukoon: islamSettings.quranicSukoonInLetterPractice, tint: appearance.accent)
                    .font(appearance.useFontArabic
                          ? appearance.islamArabicFont(base: 52, relativeTo: .largeTitle)
                          : .system(size: 52))
                    .arabicFontDesign(custom: appearance.useFontArabic && appearance.islamUsesCustomArabicFace)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
                    .frame(minHeight: 96)

                Text("Is the tinted letter a vowel or a consonant?")
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
            // each self-sizing pass, which iOS 26 traps on.
            SummaryTileGrid(columns: 2) {
                choiceButton(vowel: true, isAnswer: isVowel)
                choiceButton(vowel: false, isAnswer: !isVowel)
            }
            .padding(.vertical, 4)

            if let chosen {
                VStack(alignment: .leading, spacing: 6) {
                    Label(chosen == isVowel ? String(localized: "Right") : String(localized: "Not quite"),
                          systemImage: chosen == isVowel ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(chosen == isVowel ? .green : .red)

                    HStack(spacing: 6) {
                        VowelVerdictChip(isVowel: isVowel)

                        Text(VowelRoleText.rule(for: occurrence))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(VowelRoleText.why(for: occurrence))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)

                // The word itself, read and glossed, with its place in the Quran.
                HStack(spacing: 12) {
                    PracticeListenButton(text: occurrence.item.spoken)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(occurrence.item.reading)
                            .font(.subheadline.weight(.semibold))

                        if let gloss = VowelRoleText.gloss(occurrence.item) {
                            Text(gloss)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
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

    private func choiceButton(vowel: Bool, isAnswer: Bool) -> some View {
        let answered = chosen != nil
        let isWrongPick = chosen == vowel && !isAnswer
        let stroke: Color = !answered ? .clear : isAnswer ? .green : isWrongPick ? .red : .clear

        return Button {
            guard chosen == nil else { return }
            Settings.shared.hapticFeedback()
            chosen = vowel
            if isAnswer { correct += 1 }
        } label: {
            VStack(spacing: 2) {
                Text(VowelRoleText.verdict(vowel))
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if answered {
                    Text(vowel ? String(localized: "stretches the vowel before it") : String(localized: "a sound of its own"))
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            // Room above and below the words: Nastaliq's tall strokes (Urdu) reached the tile's border.
            // The minimum height still sets the tile in English and Arabic.
            .padding(.vertical, AppLanguage.isUrdu ? 12 : 6)
            .frame(maxWidth: .infinity, minHeight: 64)
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
        .accessibilityLabel(VowelRoleText.verdict(vowel))
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
                     : String(localized: "Read the rules on the Vowel Letters page once more, then come back for another round."))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)

            Button {
                Settings.shared.hapticFeedback()
                start()
            } label: {
                Label("Play Again", systemImage: "arrow.clockwise")
                    .font(.body.weight(.semibold))
                    .foregroundColor(appearance.accent)
            }
        } header: {
            Text("RESULTS")
        }
    }

    // MARK: Running a round

    private func start() {
        questions = VowelLetterRoles.round(for: letter)
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
}
