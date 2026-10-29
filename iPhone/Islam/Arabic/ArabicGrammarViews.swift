import SwiftUI

// MARK: - The grammar section

/// The alphabet's GRAMMAR section (Abu, 2026-10-28: "Create another section in Arabic Alphabet that is
/// focused on pronouns and endings. And basic noun section damma, dammatayn and the other tashkeel and
/// iraab. Basic verb. Basic harf"): four pages after HAMZATUL WASL, one link per row, in his order.
///
/// The same article grammar as `ArabicBasicsView`, which stays the Explore tile it was: worked rows,
/// each rule said once in a footer, recognition level, not a grammar course. Every Quran phrase is the
/// Hafs text's own spelling at its reference (checked against Quran-Tajweed-Engine/sources/Quran.json,
/// 2026-10-28) and is drawn in the Uthmani hand. The made-up teaching words follow the reader's Arabic
/// face, written the Quran's way: ۡ for a sukoon, ٱ on the article, and a bare noon where the mushaf
/// hides it (أَنتَ).
enum ArabicGrammarTopic: String, CaseIterable, Identifiable {
    case pronouns, noun, verb, harf

    var id: String { rawValue }

    /// The link tile's specimen: the grammarians' own names for the three kinds of word.
    var specimen: String {
        switch self {
        case .pronouns: return "هُوَ"
        case .noun: return "ٱسۡمٌ"
        case .verb: return "فِعۡلٌ"
        case .harf: return "حَرۡفٌ"
        }
    }

    var title: String {
        switch self {
        case .pronouns: return String(localized: "Pronouns and Endings")
        case .noun: return String(localized: "Basic Noun")
        case .verb: return String(localized: "Basic Verb")
        case .harf: return String(localized: "Basic Harf")
        }
    }

    var caption: String {
        switch self {
        case .pronouns: return String(localized: "I, you, he: alone and as endings")
        case .noun: return String(localized: "The six endings and i\u{2019}raab")
        case .verb: return String(localized: "Past, present, and command")
        case .harf: return String(localized: "In, from, and, not: the little words")
        }
    }

    /// A line of what the page holds, under the caption.
    var preview: String {
        switch self {
        case .pronouns: return "أَنَا  نَحۡنُ  أَنتَ  هُوَ  هِيَ  هُمۡ"
        case .noun: return "ٱلۡكِتَابُ  كِتَابٌ  كِتَابًا  كِتَابٍ"
        case .verb: return "كَتَبَ  يَكۡتُبُ  ٱكۡتُبۡ"
        case .harf: return "فِي  مِنۡ  إِلَىٰ  عَلَىٰ  إِنَّ  لَمۡ"
        }
    }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .pronouns: ArabicPronounsView()
        case .noun: ArabicNounView()
        case .verb: ArabicVerbView()
        case .harf: ArabicHarfView()
        }
    }
}

// MARK: - Pronouns and endings

/// The twelve pronouns, each as a word of its own and as the ending it becomes, then what the endings
/// do on a noun, a verb and a harf, the hu/hi switch, the small waaw and yaa of the mushaf, and إِيَّا.
struct ArabicPronounsView: View {
    var body: some View {
        GrammarPage(topic: .pronouns) {
            leadSection
            pronounSection(String(localized: "I AND WE"), PronounEntry.first,
                           footer: "The ending for my is a kasra and a yaa (ـِي), and the kasra takes the place of the word\u{2019}s own last vowel: rabbu becomes rabbee. When Allah says We of Himself (نَحۡنُ، إِنَّا), it is the plural of majesty, not of number: He is One.")
            pronounSection(String(localized: "grammar.you", defaultValue: "YOU"), PronounEntry.second,
                           footer: "One man is -ka and one woman -ki: only the last vowel tells them apart. Two people, men or women, share -kumaa. The plural with no shaddah (antum, -kum) is for men, or men and women together. The mushaf writes the noon of anta bare, with no sukoon, because it is hidden in the taa.")
            pronounSection(String(localized: "HE, SHE AND THEY"), PronounEntry.third,
                           footer: "Arabic has no separate word for it: a thing is he or she, after the gender of its word, and a group of things is often she. Hum is for men, or men and women together; hunna is for women only.")
            threeKindsSection
            meSection
            huHiSection
            silahSection
            iyyaaSection
            quranSection
        }
    }

    private var leadSection: some View {
        Section {
            ArticleLead(String(localized: "A pronoun stands in for a name: I, you, he, they. Arabic writes each one in two ways: as a word on its own (هُوَ, he) and as an ending joined to another word (رَبُّهُ, his Lord)."), eyebrow: String(localized: "IN SHORT"))

            Text("Arabic also tells a man from a woman, and one from two from more, so where English has seven pronouns it has twelve. The endings are among the most common words in the Quran, which makes them the place to start.")
                .font(.body)
        }
    }

    /// "YOU" is a dotted key: the catalog's plain "YOU" is أنت, where these three headers name the
    /// grammatical persons (المتكلم، المخاطب، الغائب).
    private func pronounSection(_ title: String, _ entries: [PronounEntry], footer: LocalizedStringKey) -> some View {
        Section {
            ForEach(entries, id: \.alone) { PronounRow(entry: $0) }
        } header: {
            PronounColumnsHeader(title: title)
        } footer: {
            Text(footer)
        }
    }

    private var threeKindsSection: some View {
        Section {
            GrammarExampleRow(arabic: "رَبُّنَا", reading: "rabbunaa",
                              note: String(localized: "Noun: our Lord"), focus: ["نَا"])
            GrammarExampleRow(arabic: "خَلَقَنَا", reading: "khalaqanaa",
                              note: String(localized: "Verb: He created us"), focus: ["نَا"])
            GrammarExampleRow(arabic: "لَنَا", reading: "lanaa",
                              note: String(localized: "Harf: for us"), focus: ["نَا"])
        } header: {
            Text("ONE ENDING ON ALL THREE KINDS OF WORD")
        } footer: {
            Text("The ending is the same on all three. On a noun it says whose, on a verb whom, and after a harf what the harf points to. A verb\u{2019}s ending can also say who did it: with a sukoon, خَلَقۡنَا (khalaqnaa) is we created.")
        }
    }

    private var meSection: some View {
        Section {
            GrammarExampleRow(arabic: "رَبِّي", reading: "rabbee",
                              note: String(localized: "Noun: my Lord"), focus: ["ي"])
            GrammarExampleRow(arabic: "خَلَقَنِي", reading: "khalaqanee",
                              note: String(localized: "Verb: He created me"), focus: ["نِي"])
            GrammarExampleRow(arabic: "لِي", reading: "lee",
                              note: String(localized: "Harf: for me"), focus: ["ي"])
            GrammarExampleRow(arabic: "ٱلَّذِي خَلَقَنِي فَهُوَ يَهۡدِينِ", reference: "26:78", reading: "alladhee khalaqanee fa huwa yahdeen",
                              note: String(localized: "Who created me, and He guides me"), focus: ["خَلَقَنِي", "يَهۡدِينِ"])
        } header: {
            Text("ME: ـنِي ON A VERB")
        } footer: {
            Text("The ending for me is ـِي on a noun or a harf, but ـنِي on a verb: the extra noon keeps the verb\u{2019}s own last vowel from changing. At the end of a verb the mushaf sometimes leaves that yaa unwritten and keeps only the kasra under the noon, as in يَهۡدِينِ (yahdeeni).")
        }
    }

    private var huHiSection: some View {
        Section {
            GrammarExampleRow(arabic: "لَهُ", reading: "lahu",
                              note: String(localized: "For him: after a fatha, -hu"), focus: ["هُ"])
            GrammarExampleRow(arabic: "بِهِ", reading: "bihi",
                              note: String(localized: "With it: after a kasra, -hi"), focus: ["هِ"])
            GrammarExampleRow(arabic: "لَا رَيۡبَ فِيهِ", reference: "2:2", reading: "laa rayba feeh",
                              note: String(localized: "No doubt is in it: after a yaa, -hi"), focus: ["هِ"])
            GrammarExampleRow(arabic: "أَنۡعَمۡتَ عَلَيۡهِمۡ", reference: "1:7", reading: "an\u{2019}amta \u{2018}alayhim",
                              note: String(localized: "You have favored them: -hum becomes -him the same way"), focus: ["هِمۡ"])
            GrammarExampleRow(arabic: "عَٰهَدَ عَلَيۡهُ ٱللَّهَ", reference: "48:10", reading: "\u{2018}aahada \u{2018}alayhu llaaha",
                              note: String(localized: "He promised Allah: Hafs keeps -hu here"), focus: ["هُ"])
        } header: {
            Text("HU OR HI")
        } footer: {
            Text("After a kasra or a yaa, the haa of -hu, -humaa, -hum and -hunna is said with a kasra: -hi, -himaa, -him, -hinna. Hafs keeps the damma in two places: the last row, and أَنسَىٰنِيهُ (18:63).")
        }
    }

    private var silahSection: some View {
        Section {
            GrammarExampleRow(arabic: "إِنَّهُۥ هُوَ ٱلتَّوَّابُ ٱلرَّحِيمُ", reference: "2:37", reading: "innahoo huwa t-tawwaabu r-raHeem",
                              note: String(localized: "He is the Accepting of repentance, the Merciful: said long, -hoo"), focus: ["هُۥ"])
            GrammarExampleRow(arabic: "فَإِنَّ ٱللَّهَ بِهِۦ عَلِيمٞ", reference: "3:92", reading: "fa inna llaaha bihee \u{2018}aleem",
                              note: String(localized: "Allah knows it well: said long, -hee"), focus: ["هِۦ"])
            GrammarExampleRow(arabic: "لَهُ ٱلۡمُلۡكُ", reference: "64:1", reading: "lahu l-mulku",
                              note: String(localized: "His is the dominion: short before hamzatul waSl"), focus: ["هُ"])
            GrammarExampleRow(arabic: "مِنۡهُ ءَايَٰتٞ", reference: "3:7", reading: "minhu aayaat",
                              note: String(localized: "In it are verses: short after a sukoon"), focus: ["هُ"])
            GrammarExampleRow(arabic: "فِيهِۦ مُهَانًا", reference: "25:69", reading: "feehee muhaanaa",
                              note: String(localized: "In it, humiliated: long after a long vowel, the one place Hafs does it"), focus: ["هِۦ"])
        } header: {
            Text("THE SMALL WAAW AND YAA")
        } footer: {
            Text("Where the mushaf prints a small waaw or yaa after the haa (ـهُۥ، ـهِۦ), say it long: hoo, hee. That is almost always between two vowels. After a sukoon or a long vowel, and before hamzatul waSl, it stays short.")
        }
    }

    private var iyyaaSection: some View {
        Section {
            GrammarExampleRow(arabic: "إِيَّاكَ نَعۡبُدُ وَإِيَّاكَ نَسۡتَعِينُ", reference: "1:5", reading: "iyyaaka na\u{2019}budu wa iyyaaka nasta\u{2019}een",
                              note: String(localized: "You alone we worship, and You alone we ask for help"), focus: ["إِيَّاكَ"], focusEvery: true)
        } header: {
            Text("IYYAA: THE OBJECT PUT FIRST")
        } footer: {
            Text("An object ending needs a verb to hang on. To put the object first, Arabic hangs the ending on إِيَّا instead: إِيَّاكَ, you; إِيَّاهُ, him. Put first, it means you alone.")
        }
    }

    private var quranSection: some View {
        Section {
            GrammarExampleRow(arabic: "إِنَّنِيٓ أَنَا ٱللَّهُ", reference: "20:14", reading: "innanee ana llaah",
                              note: String(localized: "Indeed, I am Allah"), focus: ["أَنَا"])
            GrammarExampleRow(arabic: "إِنَّا نَحۡنُ نَزَّلۡنَا ٱلذِّكۡرَ", reference: "15:9", reading: "innaa naHnu nazzalna dh-dhikra",
                              note: String(localized: "Indeed, it is We who sent down the Reminder"), focus: ["نَحۡنُ"])
            GrammarExampleRow(arabic: "إِنَّكَ أَنتَ ٱلسَّمِيعُ ٱلۡعَلِيمُ", reference: "2:127", reading: "innaka anta s-samee\u{2019}u l-\u{2018}aleem",
                              note: String(localized: "Indeed, You are the Hearing, the Knowing"), focus: ["أَنتَ"])
            GrammarExampleRow(arabic: "قُلۡ هُوَ ٱللَّهُ أَحَدٌ", reference: "112:1", reading: "qul huwa llaahu aHad",
                              note: String(localized: "Say: He is Allah, the One"), focus: ["هُوَ"])
            GrammarExampleRow(arabic: "هِيَ عَصَايَ", reference: "20:18", reading: "hiya \u{2018}aSaaya",
                              note: String(localized: "It is my staff: a staff is she in Arabic"), focus: ["هِيَ"])
            GrammarExampleRow(arabic: "هُنَّ أُمُّ ٱلۡكِتَٰبِ", reference: "3:7", reading: "hunna ummu l-kitaab",
                              note: String(localized: "They are the foundation of the Book: verses are she"), focus: ["هُنَّ"])
            GrammarExampleRow(arabic: "هُمۡ فِيهَا خَٰلِدُونَ", reference: "2:39", reading: "hum feehaa khaalidoon",
                              note: String(localized: "They will abide in it forever"), focus: ["هُمۡ"])
        } header: {
            Text("ON THEIR OWN, IN THE QURAN")
        }
    }
}

/// One pronoun: the word on its own, and the ending it becomes, shown on رَبّ (Lord).
private struct PronounEntry {
    let alone: String
    let readingAlone: String
    let example: String
    let readingExample: String
    /// The ending inside `example`, tinted.
    let ending: String
    let person: String
    let gloss: String

    static let first: [PronounEntry] = [
        PronounEntry(alone: "أَنَا", readingAlone: "anaa", example: "رَبِّي", readingExample: "rabbee", ending: "ي",
                     person: String(localized: "I"), gloss: String(localized: "my Lord")),
        PronounEntry(alone: "نَحۡنُ", readingAlone: "naHnu", example: "رَبُّنَا", readingExample: "rabbunaa", ending: "نَا",
                     person: String(localized: "we"), gloss: String(localized: "our Lord")),
    ]

    static let second: [PronounEntry] = [
        PronounEntry(alone: "أَنتَ", readingAlone: "anta", example: "رَبُّكَ", readingExample: "rabbuka", ending: "كَ",
                     person: String(localized: "you, one man"), gloss: String(localized: "your Lord")),
        PronounEntry(alone: "أَنتِ", readingAlone: "anti", example: "رَبُّكِ", readingExample: "rabbuki", ending: "كِ",
                     person: String(localized: "you, one woman"), gloss: String(localized: "your Lord")),
        PronounEntry(alone: "أَنتُمَا", readingAlone: "antumaa", example: "رَبُّكُمَا", readingExample: "rabbukumaa", ending: "كُمَا",
                     person: String(localized: "you two"), gloss: String(localized: "your Lord")),
        PronounEntry(alone: "أَنتُمۡ", readingAlone: "antum", example: "رَبُّكُمۡ", readingExample: "rabbukum", ending: "كُمۡ",
                     person: String(localized: "you all"), gloss: String(localized: "your Lord")),
        PronounEntry(alone: "أَنتُنَّ", readingAlone: "antunna", example: "رَبُّكُنَّ", readingExample: "rabbukunna", ending: "كُنَّ",
                     person: String(localized: "you all, women only"), gloss: String(localized: "your Lord")),
    ]

    static let third: [PronounEntry] = [
        PronounEntry(alone: "هُوَ", readingAlone: "huwa", example: "رَبُّهُ", readingExample: "rabbuhu", ending: "هُ",
                     person: String(localized: "he, it"), gloss: String(localized: "his Lord")),
        PronounEntry(alone: "هِيَ", readingAlone: "hiya", example: "رَبُّهَا", readingExample: "rabbuhaa", ending: "هَا",
                     person: String(localized: "she, it"), gloss: String(localized: "her Lord")),
        PronounEntry(alone: "هُمَا", readingAlone: "humaa", example: "رَبُّهُمَا", readingExample: "rabbuhumaa", ending: "هُمَا",
                     person: String(localized: "they two"), gloss: String(localized: "their Lord")),
        PronounEntry(alone: "هُمۡ", readingAlone: "hum", example: "رَبُّهُمۡ", readingExample: "rabbuhum", ending: "هُمۡ",
                     person: String(localized: "they"), gloss: String(localized: "their Lord")),
        PronounEntry(alone: "هُنَّ", readingAlone: "hunna", example: "رَبُّهُنَّ", readingExample: "rabbuhunna", ending: "هُنَّ",
                     person: String(localized: "they, women only"), gloss: String(localized: "their Lord")),
    ]
}

/// The two Arabic columns of a pronoun row share one width, so the rows line up as a table under
/// the section header's column names.
private enum PronounColumns {
    static let width: CGFloat = 78
    static let spacing: CGFloat = 10
}

/// A pronoun section's header: its name, then the two column names over the Arabic, right to left
/// like the columns (alone first, the ending after). One word each: "AS AN ENDING" truncated at 78 pt.
private struct PronounColumnsHeader: View {
    @ScaledMetric(relativeTo: .title2) private var columnWidth = PronounColumns.width
    let title: String

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: PronounColumns.spacing) {
            Text(title)
            Spacer(minLength: 8)
            Text("ENDING")
                .frame(width: columnWidth)
            Text("ALONE")
                .frame(width: columnWidth)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

/// One pronoun on its own and as an ending: the person and the example's meaning leading, the two
/// Arabic columns trailing in fixed widths (a selection's play button can never squeeze them), each
/// with its reading under it. Tap to select; the voice says both.
private struct PronounRow: View {
    @Environment(\.appearance) private var appearance
    /// Snapshotted at creation (the NameRow rule): the page observes the slices and rebuilds the rows.
    var letterSizeSteps: Int = Settings.shared.arabicLetterSizeIndex
    var hideEnglish: Bool = Settings.shared.hideEnglishInArabicLetters
    var useFontArabic: Bool = Settings.shared.useFontArabic
    @ObservedObject private var selection = ArabicPracticeSelection.shared
    @ScaledMetric(relativeTo: .title2) private var columnWidth = PronounColumns.width

    let entry: PronounEntry

    var body: some View {
        let id = "pronoun:" + entry.alone
        let isSelected = selection.isSelected(id)
        let ending = GrammarTint.ranges(of: [entry.ending], in: entry.example)

        return HStack(alignment: .center, spacing: PronounColumns.spacing) {
            if isSelected {
                PracticeListenButton(text: "\(entry.alone)، \(entry.example)")
            }

            if !hideEnglish {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.person)
                        .font(.subheadline.weight(.semibold))

                    Text(entry.gloss)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            cell(Text(GrammarTint.attributed(entry.example, ranges: ending, color: appearance.accent)),
                 reading: entry.readingExample)

            cell(Text(entry.alone).foregroundColor(appearance.accent), reading: entry.readingAlone)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .arabicPracticeRowSelection(isSelected, hInset: -8, vInset: -2)
        .onTapGesture {
            Settings.shared.hapticFeedback()
            withAnimation(.easeInOut) { selection.toggle(id) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(isSelected
            ? String(localized: "\(entry.person), \(entry.gloss), selected")
            : String(localized: "\(entry.person), \(entry.gloss)"))
    }

    private func cell(_ arabic: Text, reading: String) -> some View {
        VStack(spacing: 0) {
            arabic
                .font(useFontArabic ? appearance.islamArabicFont(base: 24, relativeTo: .title2) : .title2)
                .arabicFontDesign(custom: useFontArabic && appearance.islamUsesCustomArabicFace)
                .arabicLetterTypeFloor(steps: letterSizeSteps)
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            if !hideEnglish {
                Text(reading)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(width: columnWidth)
    }
}

// MARK: - Basic noun

/// The noun: how to spot one, the six endings (the three single marks with ٱلۡ, the three tanween
/// without it), fathatayn's alif, stopping, the three cases with Quran examples, the cases carried by
/// letters, the nouns with no tanween, and the nouns whose ending never moves.
struct ArabicNounView: View {
    /// The accent for the Basic Grammar link, off the environment so an accent change redraws it (a bare
    /// `Settings.shared` read in a view that observes nothing kept the old colour).
    @Environment(\.appearance) private var appearance

    var body: some View {
        GrammarPage(topic: .noun) {
            leadSection
            sixEndingsSection
            signsSection
            tanweenSection
            singleMarkSection
            fathataynSection
            stoppingSection
            rafSection
            nasbSection
            jarrSection
            lettersSection
            noTanweenSection
            fixedSection
        }
    }

    private var leadSection: some View {
        Section {
            WordKindsStrip(current: .noun)

            ArticleLead(String(localized: "Every Arabic word is a noun, a verb or a harf. A noun (ism) names a person, a thing, a place or an idea, and its last mark tells you what job it does in the sentence."), eyebrow: String(localized: "IN SHORT"))

            Text("That changing last mark is the i\u{2019}raab. There are three cases, raf\u{2019}, naSb and jarr, and each is a damma, a fatha or a kasra: doubled into tanween when the noun has no ٱلۡ.")
                .font(.body)
        }
    }

    private var sixEndingsSection: some View {
        Section {
            CaseGrid()
                #if DEBUG
                .modifier(GrammarDebugRowID(reading: "caseGrid"))
                #endif
        } header: {
            Text("THE SIX ENDINGS")
        } footer: {
            Text("On top, with ٱلۡ: one mark. Underneath, with no ٱلۡ: the same mark doubled, which is tanween. Raf\u{2019} is on the right, where Arabic starts.")
        }
    }

    private var signsSection: some View {
        Section {
            GrammarExampleRow(arabic: "ٱلۡكِتَابُ", reading: "al-kitaabu",
                              note: String(localized: "It can take ٱلۡ, the: the book"), focus: ["ٱلۡ"])
            GrammarExampleRow(arabic: "كِتَابٌ", reading: "kitaabun",
                              note: String(localized: "It can take tanween: a book"), focus: ["بٌ"])
            GrammarExampleRow(arabic: "فِي كِتَابٍ", reading: "fee kitaabin",
                              note: String(localized: "It can follow a harf of jarr like fee (in): in a book"), focus: ["فِي"])
        } header: {
            Text("HOW TO SPOT A NOUN")
        } footer: {
            Text("Any one of these is enough. They are the signs the Ajurrumiyyah, the classic first book of grammar, gives for a noun; a verb or a harf can take none of them.")
        }
    }

    private var tanweenSection: some View {
        Section {
            GrammarExampleRow(arabic: "كِتَابٌ", reading: "kitaabun",
                              note: String(localized: "Dammatayn (ـٌ): -un, raf\u{2019}"), focus: ["بٌ"])
            GrammarExampleRow(arabic: "كِتَابًا", reading: "kitaaban",
                              note: String(localized: "Fathatayn (ـً): -an, naSb"), focus: ["بًا"])
            GrammarExampleRow(arabic: "كِتَابٍ", reading: "kitaabin",
                              note: String(localized: "Kasratayn (ـٍ): -in, jarr"), focus: ["بٍ"])
        } header: {
            Text("TANWEEN: NO ٱلۡ")
        } footer: {
            Text("Tanween is an n sound at the end of a noun, written as a doubled mark and never as a noon. It ends most nouns that have no ٱلۡ. So كِتَابٌ is a book, and ٱلۡكِتَابُ the book. Names take it too: مُحَمَّدٌ.")
        }
    }

    private var singleMarkSection: some View {
        Section {
            GrammarExampleRow(arabic: "ٱلۡكِتَابُ", reading: "al-kitaabu",
                              note: String(localized: "Damma (ـُ): -u, raf\u{2019}"), focus: ["بُ"])
            GrammarExampleRow(arabic: "ٱلۡكِتَابَ", reading: "al-kitaaba",
                              note: String(localized: "Fatha (ـَ): -a, naSb"), focus: ["بَ"])
            GrammarExampleRow(arabic: "ٱلۡكِتَابِ", reading: "al-kitaabi",
                              note: String(localized: "Kasra (ـِ): -i, jarr"), focus: ["بِ"])
            GrammarExampleRow(arabic: "كِتَابُ ٱللَّهِ", reading: "kitaabu llaahi",
                              note: String(localized: "The Book of Allah: followed by its owner, no ٱلۡ and still one mark"), focus: ["بُ"])
        } header: {
            Text("WITH ٱلۡ: ONE MARK")
        } footer: {
            Text("A noun has ٱلۡ or tanween, never both. The first noun of an idaafah (X of Y: the Book of Allah) drops its tanween too, and ends on one mark.")
        }
    }

    private var fathataynSection: some View {
        Section {
            GrammarExampleRow(arabic: "كِتَابًا", reading: "kitaaban",
                              note: String(localized: "An alif after it, written but not said long"), focus: ["ا"])
            GrammarExampleRow(arabic: "رَحۡمَةً", reading: "raHmatan",
                              note: String(localized: "Mercy: no alif after taa marbuuTah (ة)"), focus: ["ةً"])
            GrammarExampleRow(arabic: "مَآءً", reading: "maa\u{2019}an",
                              note: String(localized: "Water: no alif after a hamza that follows an alif"), focus: ["ءً"])
        } header: {
            Text("FATHATAYN AND ITS ALIF")
        } footer: {
            Text("Fathatayn is the one tanween that brings a letter with it: an alif, written after it but not said. It skips the alif after ة and after ـَآء. The mushaf puts the two fathas on the letter before the alif: كِتَٰبٗا.")
        }
    }

    private var stoppingSection: some View {
        Section {
            GrammarExampleRow(arabic: "كِتَابٌ \u{2190} كِتَابۡ", reading: "kitaabun \u{2192} kitaab",
                              note: String(localized: "A damma or a kasra goes, tanween and all"), focus: ["بۡ"])
            GrammarExampleRow(arabic: "كِتَابًا \u{2190} كِتَابَا", reading: "kitaaban \u{2192} kitaabaa",
                              note: String(localized: "Fathatayn turns into a long aa"), focus: ["بَا"])
            GrammarExampleRow(arabic: "رَحۡمَةٌ \u{2190} رَحۡمَهۡ", reading: "raHmatun \u{2192} raHmah",
                              note: String(localized: "Taa marbuuTah turns into a haa"), focus: ["هۡ"])
        } header: {
            Text("STOPPING ON A NOUN")
        } footer: {
            Text("You stop at the end of every ayah, so these endings are mostly heard in the middle of one. Stopping takes off a last short vowel and its tanween (a sukoon instead), turns fathatayn into a long aa (but not on ة), and turns ة into a haa.")
        }
    }

    private var rafSection: some View {
        Section {
            GrammarExampleRow(arabic: "ٱلۡحَمۡدُ لِلَّهِ", reference: "1:2", reading: "al-Hamdu lillaah",
                              note: String(localized: "All praise is for Allah: the sentence starts on praise"), focus: ["ٱلۡحَمۡدُ"])
            GrammarExampleRow(arabic: "ٱللَّهُ ٱلصَّمَدُ", reference: "112:2", reading: "allaahu S-Samad",
                              note: String(localized: "Allah, the Eternal Refuge: what is said about Allah is raf\u{2019} too"), focus: ["ٱلصَّمَدُ"])
            GrammarExampleRow(arabic: "إِذَا جَآءَ نَصۡرُ ٱللَّهِ", reference: "110:1", reading: "idhaa jaa\u{2019}a naSru llaah",
                              note: String(localized: "When the help of Allah comes: the help is the one doing it"), focus: ["نَصۡرُ"])
        } header: {
            Text("RAF\u{2019}: THE DOER, AND WHAT A SENTENCE IS ABOUT")
        } footer: {
            Text("Raf\u{2019} (marfoo\u{2019}) is a damma, or dammatayn with no ٱلۡ. It marks the doer of a verb, the noun a sentence starts on, and what is said about it.")
        }
    }

    private var nasbSection: some View {
        Section {
            GrammarExampleRow(arabic: "وَرَأَيۡتَ ٱلنَّاسَ", reference: "110:2", reading: "wa ra\u{2019}ayta n-naasa",
                              note: String(localized: "And you see the people: the people are what is seen"), focus: ["ٱلنَّاسَ"])
            GrammarExampleRow(arabic: "خَلَقَ ٱلۡإِنسَٰنَ", reference: "96:2", reading: "khalaqa l-insaana",
                              note: String(localized: "He created man: man is what was created"), focus: ["ٱلۡإِنسَٰنَ"])
            GrammarExampleRow(arabic: "إِنَّ ٱللَّهَ غَفُورٞ رَّحِيمٞ", reference: "2:182", reading: "inna llaaha ghafoorun raHeem",
                              note: String(localized: "Indeed, Allah is Forgiving and Merciful: a fatha after inna"), focus: ["ٱللَّهَ"])
        } header: {
            Text("NASB: WHAT IT IS DONE TO")
        } footer: {
            Text("NaSb (manSoob) is a fatha, or fathatayn with no ٱلۡ. It marks the object of a verb, the noun after inna and its sisters (see Basic Harf), and a few more jobs, like saying when or how.")
        }
    }

    private var jarrSection: some View {
        Section {
            GrammarExampleRow(arabic: "بِسۡمِ ٱللَّهِ", reference: "1:1", reading: "bismi llaah",
                              note: String(localized: "In the name of Allah: ismi after bi, and Allah after of"), focus: ["سۡمِ", "ٱللَّهِ"])
            GrammarExampleRow(arabic: "فِي دِينِ ٱللَّهِ", reference: "110:2", reading: "fee deeni llaah",
                              note: String(localized: "Into the religion of Allah: after fee"), focus: ["دِينِ"])
            GrammarExampleRow(arabic: "مِنۡ عَلَقٍ", reference: "96:2", reading: "min \u{2018}alaq",
                              note: String(localized: "From a clinging substance: kasratayn, no ٱلۡ"), focus: ["عَلَقٍ"])
        } header: {
            Text("JARR: AFTER A HARF, OR AFTER OF")
        } footer: {
            Text("Jarr (majroor) is a kasra, or kasratayn with no ٱلۡ. It marks a noun after a harf of jarr (bi, li, fee, min, ilaa, \u{2018}alaa) and the second noun of an idaafah, the Y of X of Y.")
        }
    }

    private var lettersSection: some View {
        Section {
            GrammarExampleRow(arabic: "قَالَ أَبُوهُمۡ", reference: "12:94", reading: "qaala aboohum",
                              note: String(localized: "Their father said: raf\u{2019} with a waaw"), focus: ["بُو"])
            GrammarExampleRow(arabic: "وَجَآءُوٓ أَبَاهُمۡ", reference: "12:16", reading: "wa jaa\u{2019}oo abaahum",
                              note: String(localized: "And they came to their father: naSb with an alif"), focus: ["بَا"])
            GrammarExampleRow(arabic: "إِلَىٰٓ أَبِيهِمۡ", reference: "12:63", reading: "ilaa abeehim",
                              note: String(localized: "To their father: jarr with a yaa"), focus: ["بِي"])
            #if os(iOS)
            OpenScreenLink(screen: .arabicGrammar, id: "basics") {
                ArabicBasicsView()
            } label: {
                Label("Duals and Plurals in Basic Grammar", systemImage: "book")
                    .font(.body)
                    .foregroundColor(appearance.accent)
            }
            #endif
        } header: {
            Text("WHEN THE CASE IS A LETTER")
        } footer: {
            Text("A few nouns carry their case in a long vowel instead of a mark: the dual (ـَانِ، ـَيۡنِ), the sound masculine plural (ـُونَ، ـِينَ), and five nouns like أَب, father, when a word follows them. All three rows are from Surah Yusuf.")
        }
    }

    private var noTanweenSection: some View {
        Section {
            GrammarExampleRow(arabic: "عَلَىٰٓ إِبۡرَٰهِيمَ", reference: "21:69", reading: "\u{2018}alaa ibraaheem",
                              note: String(localized: "Upon Ibraaheem: after a harf of jarr, yet a fatha"), focus: ["مَ"])
            GrammarExampleRow(arabic: "مِن مَّحَٰرِيبَ وَتَمَٰثِيلَ", reference: "34:13", reading: "min maHaareeba wa tamaatheela",
                              note: String(localized: "Of chambers and statues: plural shapes with no tanween"), focus: ["بَ", "لَ"])
        } header: {
            Text("NO TANWEEN, AND A FATHA FOR JARR")
        } footer: {
            Text("Some nouns never take tanween, and in jarr they take a fatha where you expect a kasra: most foreign names (إِبۡرَٰهِيمُ، يُوسُفُ) and some plural shapes (مَسَاجِدُ, mosques). With ٱلۡ, or followed by their owner, they take the kasra again.")
        }
    }

    private var fixedSection: some View {
        Section {
            GrammarExampleRow(arabic: "ذَٰلِكَ ٱلۡكِتَٰبُ", reference: "2:2", reading: "dhaalika l-kitaabu",
                              note: String(localized: "That is the Book: dhaalika never changes"), focus: ["ذَٰلِكَ"])
            GrammarExampleRow(arabic: "رَبِّكَ ٱلَّذِي خَلَقَ", reference: "96:1", reading: "rabbika lladhee khalaq",
                              note: String(localized: "Your Lord who created: alladhee, who, never changes"), focus: ["ٱلَّذِي"])
            GrammarExampleRow(arabic: "وَإِذۡ قَالَ مُوسَىٰ", reference: "2:54", reading: "wa idh qaala moosaa",
                              note: String(localized: "And when Moosaa said: a raf\u{2019} that cannot show"), focus: ["مُوسَىٰ"])
        } header: {
            Text("WHEN THE ENDING DOES NOT MOVE")
        } footer: {
            Text("Pronouns, pointing words (هَٰذَا، ذَٰلِكَ) and the words for who and which (ٱلَّذِي) are built fixed (mabnee): their ending stays put whatever their job. A noun that ends in an alif, like مُوسَىٰ, does have a case; it just cannot show it.")
        }
    }
}

/// The six endings at a glance: a column per case, right to left from raf\u{2019}; ٱلۡكِتَاب with its
/// one mark on top, كِتَاب with its tanween underneath, the ending tinted in each.
private struct CaseGrid: View {
    @Environment(\.appearance) private var appearance
    var letterSizeSteps: Int = Settings.shared.arabicLetterSizeIndex
    var hideEnglish: Bool = Settings.shared.hideEnglishInArabicLetters
    var useFontArabic: Bool = Settings.shared.useFontArabic

    private struct Column {
        let name: String
        let definite: String
        let definiteReading: String
        let definiteEnding: String
        let definiteMark: String
        let indefinite: String
        let indefiniteReading: String
        let indefiniteEnding: String
        let indefiniteMark: String
    }

    private var columns: [Column] {
        [
            Column(name: String(localized: "Raf\u{2019}"),
                   definite: "ٱلۡكِتَابُ", definiteReading: "al-kitaabu", definiteEnding: "بُ", definiteMark: String(localized: "damma"),
                   indefinite: "كِتَابٌ", indefiniteReading: "kitaabun", indefiniteEnding: "بٌ", indefiniteMark: String(localized: "dammatayn")),
            Column(name: String(localized: "NaSb"),
                   definite: "ٱلۡكِتَابَ", definiteReading: "al-kitaaba", definiteEnding: "بَ", definiteMark: String(localized: "fatha"),
                   indefinite: "كِتَابًا", indefiniteReading: "kitaaban", indefiniteEnding: "بًا", indefiniteMark: String(localized: "fathatayn")),
            Column(name: String(localized: "Jarr"),
                   definite: "ٱلۡكِتَابِ", definiteReading: "al-kitaabi", definiteEnding: "بِ", definiteMark: String(localized: "kasra"),
                   indefinite: "كِتَابٍ", indefiniteReading: "kitaabin", indefiniteEnding: "بٍ", indefiniteMark: String(localized: "kasratayn")),
        ]
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(columns, id: \.definite) { column in
                VStack(spacing: 3) {
                    Text(column.name)
                        .font(.subheadline.weight(.semibold))

                    word(column.definite, ending: column.definiteEnding, reading: column.definiteReading, mark: column.definiteMark)

                    Divider()
                        .padding(.vertical, 3)

                    word(column.indefinite, ending: column.indefiniteEnding, reading: column.indefiniteReading, mark: column.indefiniteMark)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.vertical, 10)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(appearance.accent.opacity(0.08))
                )
                .accessibilityElement(children: .combine)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        // Right to left, like the script: raf\u{2019} first, on the right.
        .environment(\.layoutDirection, .rightToLeft)
        .padding(.vertical, 4)
    }

    private func word(_ arabic: String, ending: String, reading: String, mark: String) -> some View {
        VStack(spacing: 1) {
            Text(GrammarTint.attributed(arabic, ranges: GrammarTint.ranges(of: [ending], in: arabic), color: appearance.accent))
                .font(useFontArabic ? appearance.islamArabicFont(base: 24, relativeTo: .title2) : .title2)
                .arabicFontDesign(custom: useFontArabic && appearance.islamUsesCustomArabicFace)
                .arabicLetterTypeFloor(steps: letterSizeSteps)
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            if !hideEnglish {
                Text(reading)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(mark)
                .font(.caption.weight(.medium))
                .foregroundColor(appearance.accent)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

// MARK: - Basic verb

/// The verb: three root letters, the three kinds, the past's endings, the present's front letters,
/// the command, the present's three states, and the passive.
struct ArabicVerbView: View {
    var body: some View {
        GrammarPage(topic: .verb) {
            leadSection
            kindsSection
            rootSection
            pastSection
            presentSection
            commandSection
            moodSection
            passiveSection
        }
    }

    private var leadSection: some View {
        Section {
            WordKindsStrip(current: .verb)

            ArticleLead(String(localized: "A verb (fi\u{2019}l) is an action tied to a time. Most are built on three root letters, and what is added around them tells you who does it and when."), eyebrow: String(localized: "IN SHORT"))
        }
    }

    private var kindsSection: some View {
        Section {
            HStack(alignment: .top, spacing: 8) {
                GrammarCard(specimen: "كَتَبَ", reading: "kataba", title: String(localized: "grammar.past", defaultValue: "Past"), caption: String(localized: "he wrote"))
                GrammarCard(specimen: "يَكۡتُبُ", reading: "yaktubu", title: String(localized: "grammar.present", defaultValue: "Present"), caption: String(localized: "he writes, or will write"))
                GrammarCard(specimen: "ٱكۡتُبۡ", reading: "uktub", title: String(localized: "grammar.command", defaultValue: "Command"), caption: String(localized: "write!"))
            }
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.layoutDirection, .rightToLeft)
            .padding(.vertical, 4)
        } header: {
            Text("THREE KINDS OF VERB")
        } footer: {
            Text("Their names in grammar: maaDee (past), muDaari\u{2019} (present, which also covers the future) and amr (command).")
        }
    }

    private var rootSection: some View {
        Section {
            GrammarExampleRow(arabic: "كَتَبَ", reading: "kataba",
                              note: String(localized: "He wrote: the root ك ت ب, writing"))
            GrammarExampleRow(arabic: "كِتَاب", reading: "kitaab",
                              note: String(localized: "A book: something written"))
            GrammarExampleRow(arabic: "كَاتِب", reading: "kaatib",
                              note: String(localized: "A writer: one who writes"))
            GrammarExampleRow(arabic: "مَكۡتُوب", reading: "maktoob",
                              note: String(localized: "Written"))
        } header: {
            Text("THREE ROOT LETTERS")
        } footer: {
            Text("A root gives a whole family of words, verbs and nouns alike. Grammar books use ف ع ل (to do) as the model root, so a pattern is written with its letters: kataba is on the pattern فَعَلَ, fa\u{2019}ala.")
        }
    }

    private var pastSection: some View {
        Section {
            GrammarExampleRow(arabic: "كَتَبَ", reading: "kataba", note: String(localized: "he wrote"))
            GrammarExampleRow(arabic: "كَتَبَتۡ", reading: "katabat", note: String(localized: "she wrote"), focus: ["تۡ"])
            GrammarExampleRow(arabic: "كَتَبُواْ", reading: "kataboo", note: String(localized: "they wrote"), focus: ["واْ"])
            GrammarExampleRow(arabic: "كَتَبۡتَ", reading: "katabta", note: String(localized: "you wrote, one man"), focus: ["تَ"])
            GrammarExampleRow(arabic: "كَتَبۡتِ", reading: "katabti", note: String(localized: "you wrote, one woman"), focus: ["تِ"])
            GrammarExampleRow(arabic: "كَتَبۡتُمۡ", reading: "katabtum", note: String(localized: "you all wrote"), focus: ["تُمۡ"])
            GrammarExampleRow(arabic: "كَتَبۡتُ", reading: "katabtu", note: String(localized: "I wrote"), focus: ["تُ"])
            GrammarExampleRow(arabic: "كَتَبۡنَا", reading: "katabnaa", note: String(localized: "we wrote"), focus: ["نَا"])
            GrammarExampleRow(arabic: "لَقَدۡ خَلَقۡنَا ٱلۡإِنسَٰنَ", reference: "95:4", reading: "laqad khalaqnaa l-insaan",
                              note: String(localized: "We have certainly created man: -naa, we"), focus: ["نَا"])
        } header: {
            Text("THE PAST: ENDINGS SAY WHO")
        } footer: {
            Text("The form for he is the bare verb; every other person adds an ending. Before an ending that starts with a taa or a noon carrying a vowel (-tu, -ta, -naa), the last root letter goes quiet: kataba, but katabtu. Katabat keeps its fatha, because the taa of she has a sukoon.")
        }
    }

    private var presentSection: some View {
        Section {
            GrammarExampleRow(arabic: "أَكۡتُبُ", reading: "aktubu", note: String(localized: "I write"), focus: ["أَ"])
            GrammarExampleRow(arabic: "نَكۡتُبُ", reading: "naktubu", note: String(localized: "we write"), focus: ["نَ"])
            GrammarExampleRow(arabic: "يَكۡتُبُ", reading: "yaktubu", note: String(localized: "he writes"), focus: ["يَ"])
            GrammarExampleRow(arabic: "تَكۡتُبُ", reading: "taktubu", note: String(localized: "she writes, or you write"), focus: ["تَ"])
            GrammarExampleRow(arabic: "يَكۡتُبُونَ", reading: "yaktuboona", note: String(localized: "they write"), focus: ["يَ", "ونَ"])
            GrammarExampleRow(arabic: "تَكۡتُبُونَ", reading: "taktuboona", note: String(localized: "you all write"), focus: ["تَ", "ونَ"])
            GrammarExampleRow(arabic: "إِيَّاكَ نَعۡبُدُ", reference: "1:5", reading: "iyyaaka na\u{2019}budu",
                              note: String(localized: "You alone we worship: na-, we"), focus: ["نَ"])
        } header: {
            Text("THE PRESENT: A LETTER IN FRONT")
        } footer: {
            Text("Four letters start a present verb, remembered as أَنَيۡتُ (anaytu): a- for I, na- for we, ya- for he, ta- for you or she. A plural adds -oona at the end. The present covers now and later: yaktubu is he writes, he is writing, or he will write.")
        }
    }

    private var commandSection: some View {
        Section {
            GrammarExampleRow(arabic: "ٱقۡرَأۡ بِٱسۡمِ رَبِّكَ", reference: "96:1", reading: "iqra\u{2019} bismi rabbik",
                              note: String(localized: "Read in the name of your Lord: from taqra\u{2019}u"), focus: ["ٱقۡرَأۡ"])
            GrammarExampleRow(arabic: "قُلۡ هُوَ ٱللَّهُ أَحَدٌ", reference: "112:1", reading: "qul huwa llaahu aHad",
                              note: String(localized: "Say: He is Allah, the One. From taqoolu, the long oo drops"), focus: ["قُلۡ"])
            GrammarExampleRow(arabic: "ٱهۡدِنَا ٱلصِّرَٰطَ ٱلۡمُسۡتَقِيمَ", reference: "1:6", reading: "ihdina S-Siraata l-mustaqeem",
                              note: String(localized: "Guide us to the straight path: said to Allah, a command is a supplication"), focus: ["ٱهۡدِنَا"])
            GrammarExampleRow(arabic: "لَا تَحۡزَنۡ إِنَّ ٱللَّهَ مَعَنَا", reference: "9:40", reading: "laa taHzan inna llaaha ma\u{2018}anaa",
                              note: String(localized: "Do not grieve, Allah is with us: laa, then a sukoon"), focus: ["لَا", "تَحۡزَنۡ"])
        } header: {
            Text("THE COMMAND")
        } footer: {
            Text("Take the present, drop its first letter and end on a sukoon. If what is left starts on a sukoon, hamzatul waSl is added to start on (its vowel is on the Hamzatul WaSl page). To say do not, put لَا before the present and end it the same way.")
        }
    }

    /// The whole verb is tinted here, not its last letter: the Uthmani face joins لم and لد into one
    /// glyph, and a glyph takes one colour, so a tinted ending lit the laam before it too.
    private var moodSection: some View {
        Section {
            GrammarExampleRow(arabic: "وَٱللَّهُ يَعۡلَمُ", reference: "47:19", reading: "wallaahu ya\u{2018}lamu",
                              note: String(localized: "And Allah knows: a damma, its usual state (raf\u{2019})"), focus: ["يَعۡلَمُ"])
            GrammarExampleRow(arabic: "أَن يَضۡرِبَ مَثَلٗا", reference: "2:26", reading: "an yaDriba mathalan",
                              note: String(localized: "To present an example: a fatha after an (naSb)"), focus: ["يَضۡرِبَ"])
            GrammarExampleRow(arabic: "لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ", reference: "112:3", reading: "lam yalid wa lam yoolad",
                              note: String(localized: "He neither begets nor is born: a sukoon after lam (jazm)"), focus: ["يَلِدۡ", "يُولَدۡ"])
            GrammarExampleRow(arabic: "فَإِن لَّمۡ تَفۡعَلُواْ وَلَن تَفۡعَلُواْ", reference: "2:24", reading: "fa il-lam taf\u{2019}aloo wa lan taf\u{2019}aloo",
                              note: String(localized: "But if you do not, and you never will: taf\u{2019}aloona drops its noon"), focus: ["تَفۡعَلُواْ"], focusEvery: true)
        } header: {
            Text("THE PRESENT\u{2019}S LAST MARK")
        } footer: {
            Text("Only the present changes with its job: raf\u{2019} (a damma) on its own, naSb (a fatha) after an, lan and kay, and jazm (a sukoon) after lam, after the laa that forbids, and in an if-sentence. A plural like taf\u{2019}aloona drops its noon for both. A verb is never jarr, and a noun never jazm; the past and the command never change (mabnee).")
        }
    }

    private var passiveSection: some View {
        Section {
            GrammarExampleRow(arabic: "خَلَقَ ٱلۡإِنسَٰنَ مِنۡ عَلَقٍ", reference: "96:2", reading: "khalaqa l-insaana min \u{2018}alaq",
                              note: String(localized: "He created man from a clinging substance: man is the object, naSb"), focus: ["خَلَقَ", "ٱلۡإِنسَٰنَ"])
            GrammarExampleRow(arabic: "خُلِقَ ٱلۡإِنسَٰنُ مِنۡ عَجَلٖ", reference: "21:37", reading: "khuliqa l-insaanu min \u{2018}ajal",
                              note: String(localized: "Man was created of haste: the verb turns passive, and man takes raf\u{2019}"), focus: ["خُلِقَ", "ٱلۡإِنسَٰنُ"])
        } header: {
            Text("DONE BY, OR DONE TO")
        } footer: {
            Text("A damma on the first letter and a kasra before the last make a past verb passive: khalaqa, he created, becomes khuliqa, was created. The noun it was done to then takes raf\u{2019}, as the two rows show with the same word.")
        }
    }
}

// MARK: - Basic harf

/// The harf: the jarr harfs, the joining ones, inna and its sisters, the ones that work on a verb,
/// denying and asking, and calling with يَا.
struct ArabicHarfView: View {
    var body: some View {
        GrammarPage(topic: .harf) {
            leadSection
            jarrSection
            joiningSection
            innaSection
            verbSection
            denySection
            callingSection
        }
    }

    private var leadSection: some View {
        Section {
            WordKindsStrip(current: .harf)

            ArticleLead(String(localized: "A harf is a small word that means something only beside another word: in, from, and, not, indeed. Its own ending never changes, but many harfs change the ending of the word after them."), eyebrow: String(localized: "IN SHORT"))

            Text("Harf also means a letter of the alphabet. Here it is the third kind of word, after the noun and the verb. These are the ones you will meet most.")
                .font(.body)
        }
    }

    private var jarrSection: some View {
        Section {
            GrammarExampleRow(arabic: "بِسۡمِ ٱللَّهِ", reference: "1:1", reading: "bismi llaah",
                              note: String(localized: "bi, with, in: in the name of Allah"), focus: ["بِ"])
            GrammarExampleRow(arabic: "ٱلۡحَمۡدُ لِلَّهِ", reference: "1:2", reading: "al-Hamdu lillaah",
                              note: String(localized: "li, for: all praise is for Allah"), focus: ["لِ"])
            GrammarExampleRow(arabic: "فِي دِينِ ٱللَّهِ", reference: "110:2", reading: "fee deeni llaah",
                              note: String(localized: "fee, in: into the religion of Allah"), focus: ["فِي"])
            GrammarExampleRow(arabic: "مِنۡ عَلَقٍ", reference: "96:2", reading: "min \u{2018}alaq",
                              note: String(localized: "min, from: from a clinging substance"), focus: ["مِنۡ"])
            GrammarExampleRow(arabic: "وَإِلَى ٱللَّهِ تُرۡجَعُ ٱلۡأُمُورُ", reference: "2:210", reading: "wa ila llaahi turja\u{2018}u l-umoor",
                              note: String(localized: "ilaa, to: and to Allah all matters return"), focus: ["إِلَى"])
            GrammarExampleRow(arabic: "عَلَىٰ كُلِّ شَيۡءٖ قَدِيرٞ", reference: "2:20", reading: "\u{2018}alaa kulli shay\u{2019}in qadeer",
                              note: String(localized: "\u{2018}alaa, on, over: over all things competent"), focus: ["عَلَىٰ"])
            GrammarExampleRow(arabic: "عَنِ ٱلنَّبَإِ ٱلۡعَظِيمِ", reference: "78:2", reading: "\u{2018}ani n-naba\u{2019}i l-\u{2018}aZeem",
                              note: String(localized: "\u{2018}an, about: about the great news"), focus: ["عَنِ"])
            GrammarExampleRow(arabic: "كَٱلۡفَرَاشِ ٱلۡمَبۡثُوثِ", reference: "101:4", reading: "kal-faraashi l-mabthooth",
                              note: String(localized: "ka, like: like moths, scattered"), focus: ["كَ"])
        } header: {
            Text("HARFS OF JARR: A KASRA AFTER")
        } footer: {
            Text("Every one of these makes the noun after it jarr: a kasra, or kasratayn. Three are a single letter written onto the next word (bi, li, ka), so read them as part of it: bismi is bi + ismi, with the alif of ismi dropped.")
        }
    }

    private var joiningSection: some View {
        Section {
            GrammarExampleRow(arabic: "وَإِيَّاكَ نَسۡتَعِينُ", reference: "1:5", reading: "wa iyyaaka nasta\u{2019}een",
                              note: String(localized: "wa, and: and You alone we ask for help"), focus: ["وَ"])
            GrammarExampleRow(arabic: "فَصَلِّ لِرَبِّكَ وَٱنۡحَرۡ", reference: "108:2", reading: "fa Salli li rabbika wanHar",
                              note: String(localized: "fa, so (straight after): so pray to your Lord and sacrifice"), focus: ["فَ"])
            GrammarExampleRow(arabic: "ثُمَّ رَدَدۡنَٰهُ أَسۡفَلَ سَٰفِلِينَ", reference: "95:5", reading: "thumma radadnaahu asfala saafileen",
                              note: String(localized: "thumma, then (after a while): then We returned him to the lowest of the low"), focus: ["ثُمَّ"])
            GrammarExampleRow(arabic: "يَوۡمًا أَوۡ بَعۡضَ يَوۡمٖ", reference: "2:259", reading: "yawman aw ba\u{2018}Da yawm",
                              note: String(localized: "aw, or: a day or part of a day"), focus: ["أَوۡ"])
            GrammarExampleRow(arabic: "بَلۡ تُؤۡثِرُونَ ٱلۡحَيَوٰةَ ٱلدُّنۡيَا", reference: "87:16", reading: "bal tu\u{2019}thiroona l-Hayaata d-dunyaa",
                              note: String(localized: "bal, rather: but you prefer the life of this world"), focus: ["بَلۡ"])
        } header: {
            Text("JOINING: AND, THEN, OR")
        } footer: {
            Text("Wa and fa are written onto the next word. Joining two nouns, a harf like these gives the second the case of the first: a day or part of a day are both naSb.")
        }
    }

    private var innaSection: some View {
        Section {
            GrammarExampleRow(arabic: "إِنَّ ٱللَّهَ غَفُورٞ رَّحِيمٞ", reference: "2:182", reading: "inna llaaha ghafoorun raHeem",
                              note: String(localized: "inna, indeed: indeed, Allah is Forgiving and Merciful"), focus: ["إِنَّ"])
            GrammarExampleRow(arabic: "أَنَّهُۥ لَآ إِلَٰهَ إِلَّا ٱللَّهُ", reference: "47:19", reading: "annahoo laa ilaaha illa llaah",
                              note: String(localized: "anna, that: that there is no deity except Allah"), focus: ["أَنَّ"])
            GrammarExampleRow(arabic: "وَلَٰكِنَّ أَكۡثَرَ ٱلنَّاسِ لَا يَعۡلَمُونَ", reference: "7:187", reading: "wa laakinna akthara n-naasi laa ya\u{2018}lamoon",
                              note: String(localized: "laakinna, but: but most of the people do not know"), focus: ["لَٰكِنَّ"])
            GrammarExampleRow(arabic: "كَأَنَّهُمۡ جَرَادٞ مُّنتَشِرٞ", reference: "54:7", reading: "ka\u{2019}annahum jaraadun muntashir",
                              note: String(localized: "ka\u{2019}anna, as if: as if they were locusts spreading"), focus: ["كَأَنَّ"])
            GrammarExampleRow(arabic: "يَٰلَيۡتَنِي كُنتُ تُرَٰبَۢا", reference: "78:40", reading: "yaa laytanee kuntu turaabaa",
                              note: String(localized: "layta, if only: oh, I wish that I were dust"), focus: ["لَيۡتَ"])
            GrammarExampleRow(arabic: "لَعَلَّكُمۡ تَتَّقُونَ", reference: "2:183", reading: "la\u{2018}allakum tattaqoon",
                              note: String(localized: "la\u{2018}alla, so that: so that you may become righteous"), focus: ["لَعَلَّ"])
        } header: {
            Text("INNA AND ITS SISTERS: A FATHA AFTER")
        } footer: {
            Text("These six make the noun after them naSb and leave what is said about it in raf\u{2019}: in the first row Allah takes a fatha, and Forgiving and Merciful keep their dammatayn. An ending on them, as in لَعَلَّكُمۡ, is that noun.")
        }
    }

    private var verbSection: some View {
        Section {
            GrammarExampleRow(arabic: "لَمۡ يَلِدۡ وَلَمۡ يُولَدۡ", reference: "112:3", reading: "lam yalid wa lam yoolad",
                              note: String(localized: "lam, did not: He neither begets nor is born"), focus: ["لَمۡ"], focusEvery: true)
            GrammarExampleRow(arabic: "لَن تَنَالُواْ ٱلۡبِرَّ", reference: "3:92", reading: "lan tanaaloo l-birra",
                              note: String(localized: "lan, will never: you will never attain righteousness"), focus: ["لَن"])
            GrammarExampleRow(arabic: "أَن يَضۡرِبَ مَثَلٗا", reference: "2:26", reading: "an yaDriba mathalan",
                              note: String(localized: "an, to: to present an example"), focus: ["أَن"])
            GrammarExampleRow(arabic: "قَدۡ أَفۡلَحَ ٱلۡمُؤۡمِنُونَ", reference: "23:1", reading: "qad aflaHa l-mu\u{2019}minoon",
                              note: String(localized: "qad, truly: the believers have truly succeeded"), focus: ["قَدۡ"])
            GrammarExampleRow(arabic: "سَيَقُولُ ٱلسُّفَهَآءُ", reference: "2:142", reading: "sa yaqoolu s-sufahaa\u{2019}",
                              note: String(localized: "sa-, will: the foolish will say"), focus: ["سَ"])
            GrammarExampleRow(arabic: "وَلَسَوۡفَ يُعۡطِيكَ رَبُّكَ فَتَرۡضَىٰٓ", reference: "93:5", reading: "wa la sawfa yu\u{2018}Teeka rabbuka fa tarDaa",
                              note: String(localized: "sawfa, will: your Lord is going to give you, and you will be satisfied"), focus: ["سَوۡفَ"])
        } header: {
            Text("HARFS ON A VERB")
        } footer: {
            Text("Lam and the laa that forbids give a present verb a sukoon (jazm); lan and an give it a fatha (naSb). Sa- and sawfa point it to the future. Qad before a past verb says it truly happened.")
        }
    }

    private var denySection: some View {
        Section {
            GrammarExampleRow(arabic: "لَآ إِلَٰهَ إِلَّا ٱللَّهُ", reference: "37:35", reading: "laa ilaaha illa llaah",
                              note: String(localized: "laa, no, and illaa, except: there is no deity except Allah"), focus: ["لَآ", "إِلَّا"])
            GrammarExampleRow(arabic: "مَا وَدَّعَكَ رَبُّكَ", reference: "93:3", reading: "maa wadda\u{2018}aka rabbuk",
                              note: String(localized: "maa, not: your Lord has not taken leave of you"), focus: ["مَا"])
            GrammarExampleRow(arabic: "هَلۡ أَتَىٰكَ حَدِيثُ ٱلۡغَٰشِيَةِ", reference: "88:1", reading: "hal ataaka Hadeethu l-ghaashiyah",
                              note: String(localized: "hal, a question: has the report of the Overwhelming reached you?"), focus: ["هَلۡ"])
            GrammarExampleRow(arabic: "أَلَمۡ نَشۡرَحۡ لَكَ صَدۡرَكَ", reference: "94:1", reading: "alam nashraH laka Sadrak",
                              note: String(localized: "a-, a question, with lam: did We not expand your chest for you?"), focus: ["أَ"])
        } header: {
            Text("NO, AND ASKING")
        } footer: {
            Text("Laa and maa both say not. Before a noun, laa denies it altogether, and the noun takes a fatha with no tanween: لَآ إِلَٰهَ, no deity at all. Hal and a- ask a question; a- with lam asks did ... not, and expects a yes.")
        }
    }

    private var callingSection: some View {
        Section {
            GrammarExampleRow(arabic: "يَٰٓأَيُّهَا ٱلنَّاسُ ٱعۡبُدُواْ رَبَّكُمُ", reference: "2:21", reading: "yaa ayyuha n-naasu \u{2018}budoo rabbakum",
                              note: String(localized: "O mankind, worship your Lord"), focus: ["يَٰٓ"])
            GrammarExampleRow(arabic: "قَالُواْ يَٰٓأَبَانَا", reference: "12:63", reading: "qaaloo yaa abaanaa",
                              note: String(localized: "They said, O our father"), focus: ["يَٰٓ"])
        } header: {
            Text("CALLING: YAA")
        } footer: {
            Text("The mushaf writes the alif of yaa small and joins it to the next word: يَٰٓأَبَانَا. Before a noun with ٱلۡ, ayyuhaa comes between them: يَٰٓأَيُّهَا ٱلنَّاسُ.")
        }
    }
}

// MARK: - Shared pieces

/// The frame every grammar page shares: the List, the size slider and Hide English the other alphabet
/// pages have, and the links to the other grammar pages at the foot.
private struct GrammarPage<Content: View>: View {
    /// Apple Music-style bar minimization: true while scrolling down.
    @State private var barsCollapsed = false
    /// The rows snapshot these slices' fields, so the page observes them and rebuilds the rows.
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared
    @ObservedObject private var islamSettings = IslamSettings.shared
    @ObservedObject private var quranDisplay = QuranDisplay.shared

    let topic: ArabicGrammarTopic
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Group {
                    content()
                    #if os(iOS)
                    ArabicGrammarLinksSection(current: topic)
                    #endif
                }
                .themedListRowBackground()
            }
            #if DEBUG
            .onAppear {
                guard let target = GrammarDebugScroll.target else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { proxy.scrollTo(target, anchor: .top) }
            }
            #endif
        }
        .selectableArticleList()
        .navigationTitle(topic.title)
        .openScreen(.arabicGrammar, id: topic.rawValue)
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
}

#if DEBUG
/// "-grammarScrollTo lahu" (with "-arabicTopic pronouns|noun|verb|harf"): opens the page scrolled to the
/// first row with that reading, so a headless screenshot reaches the sections below the fold. Rows carry
/// the id only when the argument is given. A pronoun row is reached by its Arabic (هُوَ), its ForEach id.
enum GrammarDebugScroll {
    static let target: String? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-grammarScrollTo"), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }()
}

private struct GrammarDebugRowID: ViewModifier {
    let reading: String

    func body(content: Content) -> some View {
        if GrammarDebugScroll.target != nil {
            content.id(reading)
        } else {
            content
        }
    }
}
#endif

/// One worked example on the grammar pages: `ArabicExampleRow`'s layout and tap-to-hear, with the word
/// or ending the row is about tinted in the accent. A row with a `reference` is a Quran quote: the Hafs
/// text's own spelling, in the mushaf's Uthmani hand, its reference after the note.
struct GrammarExampleRow: View {
    @Environment(\.appearance) private var appearance
    /// Snapshotted at creation (the NameRow rule): the page observes the slices and rebuilds the rows.
    var letterSizeSteps: Int = Settings.shared.arabicLetterSizeIndex
    var hideEnglish: Bool = Settings.shared.hideEnglishInArabicLetters
    var useFontArabic: Bool = Settings.shared.useFontArabic
    @ObservedObject private var selection = ArabicPracticeSelection.shared

    let arabic: String
    /// "1:5": the row quotes the Quran at that ayah.
    var reference: String? = nil
    let reading: String
    let note: String
    /// What to tint, each where it LAST occurs, so an ending never lights the same letters earlier in
    /// the word (the taa of كَتَبۡتَ is also its second letter).
    var focus: [String] = []
    /// Every occurrence instead, for a word said twice in the phrase (إِيَّاكَ ... وَإِيَّاكَ).
    var focusEvery = false

    private var fullNote: String {
        guard let reference else { return note }
        return "\(note) (\(reference.localizedDigits))"
    }

    private var arabicText: Text {
        let ranges = GrammarTint.ranges(of: focus, in: arabic, every: focusEvery)
        guard !ranges.isEmpty else {
            return Text.islamArabic(arabic, highlightAllah: appearance.highlightAllahIslam)
        }
        return Text(GrammarTint.attributed(arabic, ranges: ranges, color: appearance.accent,
                                           highlightAllah: appearance.highlightAllahIslam))
    }

    private var arabicFont: Font {
        if reference != nil {
            return Font.arabic(Settings.hafsUthmaniFontName, size: 24, relativeTo: .title2)
        }
        return useFontArabic ? appearance.islamArabicFont(base: 24, relativeTo: .title2) : .title2
    }

    var body: some View {
        // The note too: the noun page shows كِتَابٌ in two sections, and one tap must not select both.
        let id = "grammar:" + arabic + "|" + note
        let isSelected = selection.isSelected(id)

        return HStack(alignment: .center, spacing: 12) {
            if isSelected {
                PracticeListenButton(text: arabic)
            }

            if !hideEnglish {
                VStack(alignment: .leading, spacing: 2) {
                    Text(reading)
                        .font(.subheadline.weight(.semibold))

                    Text.islamText(fullNote, highlightAllah: appearance.highlightAllahIslam)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            arabicText
                .font(arabicFont)
                .arabicFontDesign(custom: reference != nil || (useFontArabic && appearance.islamUsesCustomArabicFace))
                .arabicLetterTypeFloor(steps: letterSizeSteps)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
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
            ? String(localized: "\(reading), \(fullNote), selected")
            : String(localized: "\(reading), \(fullNote)"))
        #if DEBUG
        .modifier(GrammarDebugRowID(reading: reading))
        #endif
    }
}

/// Finds and tints the part of an Arabic phrase a grammar row is about.
enum GrammarTint {
    /// The ranges of each piece in `text`, matched Character by Character. A Character is a letter
    /// with its marks, so a match always starts and ends on whole letters (a tinted ending never splits
    /// a letter from its vowel), and Character equality is canonical, so a piece typed fatha-then-shaddah
    /// still finds the Quran text's shaddah-then-fatha.
    static func ranges(of pieces: [String], in text: String, every: Bool = false) -> [Range<String.Index>] {
        let characters = Array(text)
        let starts = Array(text.indices) + [text.endIndex]
        var found: [Range<String.Index>] = []
        for piece in pieces {
            let target = Array(piece)
            guard !target.isEmpty, target.count <= characters.count else { continue }
            var matches: [Int] = []
            for start in 0...(characters.count - target.count)
            where characters[start..<(start + target.count)].elementsEqual(target) {
                matches.append(start)
            }
            for start in every ? matches : Array(matches.suffix(1)) {
                found.append(starts[start]..<starts[start + target.count])
            }
        }
        return found
    }

    /// `text` with `ranges` in `color`: one attributed string, so the letters still join across a tint.
    /// With `highlightAllah`, the name of Allah is red first (Islam Settings' Highlight Allah, as
    /// `Text.islamArabic` paints it) and the tint goes over it only where a row is ABOUT that word, the
    /// way a tajweed rule's paint outranks the name in the readers.
    static func attributed(_ text: String, ranges: [Range<String.Index>], color: Color,
                           highlightAllah: Bool = false) -> AttributedString {
        var attributed = Text.islamHighlighted(text, highlightAllah: highlightAllah) ?? AttributedString(text)
        for range in ranges {
            if let start = AttributedString.Index(range.lowerBound, within: attributed),
               let end = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[start..<end].foregroundColor = color
            }
        }
        return attributed
    }
}

/// A tile in a grammar page's strip: an Arabic specimen and its reading over a title and a caption,
/// the Hamzatul WaSl page's two-hamza card. `isCurrent` fills it, for the page you are on.
private struct GrammarCard: View {
    @Environment(\.appearance) private var appearance
    var letterSizeSteps: Int = Settings.shared.arabicLetterSizeIndex
    var hideEnglish: Bool = Settings.shared.hideEnglishInArabicLetters
    var useFontArabic: Bool = Settings.shared.useFontArabic

    let specimen: String
    let reading: String
    let title: String
    let caption: String
    var isCurrent = false

    var body: some View {
        VStack(spacing: 3) {
            Text(specimen)
                .font(useFontArabic ? appearance.islamArabicFont(base: 28, relativeTo: .title) : .title)
                .arabicFontDesign(custom: useFontArabic && appearance.islamUsesCustomArabicFace)
                .arabicLetterTypeFloor(steps: letterSizeSteps)
                .foregroundColor(appearance.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.4)

            if !hideEnglish {
                Text(reading)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)

            if !hideEnglish {
                Text(caption)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(appearance.accent.opacity(isCurrent ? 0.2 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(appearance.accent.opacity(isCurrent ? 0.6 : 0), lineWidth: 1.5)
        )
        .accessibilityElement(children: .combine)
    }
}

/// The three kinds of word, the page's own filled: the noun, verb and harf pages open on it, so each
/// says where it sits among the other two.
private struct WordKindsStrip: View {
    let current: ArabicGrammarTopic

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            GrammarCard(specimen: ArabicGrammarTopic.noun.specimen, reading: "ism",
                        title: String(localized: "Noun"), caption: String(localized: "a name: a person, a thing, an idea"),
                        isCurrent: current == .noun)
            GrammarCard(specimen: ArabicGrammarTopic.verb.specimen, reading: "fi\u{2019}l",
                        title: String(localized: "Verb"), caption: String(localized: "an action, in a time"),
                        isCurrent: current == .verb)
            // "Particle" under the reading Harf, so the tile does not say Harf twice. Dotted keys here and on
            // the verb page's cards: the catalog's plain "Particle" and "Command" are the word-grammar
            // card's لام الحرف and لام الأمر (Localization Guide, "Two meanings, two keys").
            GrammarCard(specimen: ArabicGrammarTopic.harf.specimen, reading: "Harf",
                        title: String(localized: "grammar.particle", defaultValue: "Particle"), caption: String(localized: "a link: in, from, and"),
                        isCurrent: current == .harf)
        }
        .fixedSize(horizontal: false, vertical: true)
        // Right to left, like the script: the noun first, on the right.
        .environment(\.layoutDirection, .rightToLeft)
        .padding(.vertical, 4)
    }
}

#if os(iOS)
/// The other grammar pages, one link per row, at the foot of each grammar page and of Basic Grammar.
/// They all link to each other, so every row is an `OpenScreenLink` (`no-infinite-nav-chains`): a page
/// already on the stack is greyed, not a door back into itself.
struct ArabicGrammarLinksSection: View {
    private let settings = Settings.shared
    @ObservedObject private var appearanceSettings = AppearanceSettings.shared

    /// The page this sits on; nil on Basic Grammar, which lists all four.
    let current: ArabicGrammarTopic?

    var body: some View {
        Section {
            ForEach(ArabicGrammarTopic.allCases.filter { $0 != current }) { topic in
                OpenScreenLink(screen: .arabicGrammar, id: topic.rawValue) {
                    topic.destination
                } label: {
                    ArabicTopicLinkLabel(specimen: topic.specimen, title: topic.title, caption: topic.caption)
                }
                .tint(settings.accentColor.color)
            }

            if current != nil {
                OpenScreenLink(screen: .arabicGrammar, id: "basics") {
                    ArabicBasicsView()
                } label: {
                    ArabicTopicLinkLabel(specimen: "ال", title: String(localized: "Basic Grammar"),
                                         caption: String(localized: "Gender, duals, plurals, and case endings"))
                }
                .tint(settings.accentColor.color)
            }
        } header: {
            Text("MORE GRAMMAR")
        }
    }
}
#endif
