import SwiftUI

// MARK: - The searchable topics of the Arabic Alphabet screen

/// One thing the Arabic Alphabet screen offers besides a letter: an Explore tile, a shape page, the
/// hamzatul waSl page or one of its drills, a grammar page, a Reading Test tier, or a section the
/// list scrolls to. The screen's search used to know only letters and letter families, so "hamzatul
/// wasl" found the letter ٱ and not the section named for it (Abu, 2026-11-08: "I'll say hamzatul
/// wasl and only the letter will show up not the section"). Every topic row the screen draws has an
/// entry here, and the TOPICS result section is built from the matches.
struct ArabicTopic: Identifiable, Equatable {
    /// Where the topic sits on the screen: the result row's eyebrow, and a search word in itself.
    enum Section: Equatable {
        case explore, shapes, vowelLetters, wasl, grammar, quranWords, numbers, signs, readingTest

        var title: String {
            switch self {
            case .explore: return String(localized: "Explore")
            case .shapes: return String(localized: "Letter Shapes")
            case .vowelLetters: return String(localized: "Vowel Letters")
            case .wasl: return String(localized: "Hamzatul WaSl")
            case .grammar: return String(localized: "Grammar")
            case .quranWords: return String(localized: "Quran Words")
            case .numbers: return String(localized: "Arabic Numbers")
            case .signs: return String(localized: "Quran Signs")
            case .readingTest: return String(localized: "Reading Test")
            }
        }
    }

    /// What a tap on the result does.
    enum Opens: Equatable {
        /// Pushes the topic's page (`ArabicTopicDestination` maps the id to the view).
        case page
        /// Clears the search and scrolls the alphabet to the row with this id: the topic is a section
        /// of this very screen and has no page of its own.
        case scroll(rowID: String)
    }

    /// The `-arabicTopic` debug ids, so one switch serves the debug route and the search rows.
    let id: String
    let section: Section
    let title: String
    let caption: String
    /// The Arabic drawn in the row's badge.
    let specimen: String
    let face: ArabicTopicLinkLabel.Face
    /// The topic's OTHER names: the spellings and the Arabic a searcher may type for the thing
    /// itself ("Hamzat al-Wasl", "همزة الوصل"). They rank like the title.
    let aliases: [String]
    /// Words a searcher types for what the page is ABOUT, which the title and caption do not carry
    /// ("tanween" on the Tashkeel table). They rank a notch under a name.
    let keywords: [String]
    let opens: Opens
    /// Everything the search matches against, folded ONCE here: the matcher runs on every keystroke,
    /// twice a body pass, over every topic.
    fileprivate let haystack: String

    init(id: String, section: Section, title: String, caption: String, specimen: String,
         face: ArabicTopicLinkLabel.Face = .reader, aliases: [String] = [], keywords: [String] = [], opens: Opens = .page) {
        self.id = id
        self.section = section
        self.title = title
        self.caption = caption
        self.specimen = specimen
        self.face = face
        self.aliases = aliases
        self.keywords = keywords
        self.opens = opens
        haystack = ArabicTopicCatalog.fold(([title, caption, section.title, specimen] + aliases + keywords).joined(separator: " "))
    }

    /// How well the topic answers the query. A hit on a NAME (the title or an alias) outranks any hit
    /// on what the topic is about, whatever `SearchRank` thinks of each: "tanween" is the Tanween
    /// tier's name and only a word on the Tashkeel table. Within each band `SearchRank`'s own tiers
    /// (the whole name, its start, a word of it, inside it) order the hits. Zero when nothing matches.
    fileprivate func score(_ query: SearchRank.Query) -> Int {
        var named = 0
        for name in [title] + aliases {
            named = max(named, SearchRank.score(query, name: name))
        }
        if named > 0 { return 1000 + named }
        var about = 0
        for word in [caption, specimen] + keywords {
            about = max(about, SearchRank.score(query, name: word))
        }
        return about
    }
}

enum ArabicTopicCatalog {
    /// Hamzatul waSl's spellings: the page's other names, and words about each of its three drills,
    /// so any of them finds all four.
    private static let waslNames = [
        "Hamzatul Wasl", "Hamzat al-Wasl", "Hamzat ul Wasl", "Hamzat al Wasl", "Hamza al-Wasl", "Hamzah al-Wasl",
        "Wasl", "Wasla", "Waslah", "Connecting Hamza", "Joining Hamza", "Silent Alif", "Alif Wasl",
        "همزة الوصل", "ٱ",
    ]

    static let families = ArabicTopic(
        id: "families", section: .explore,
        title: String(localized: "Letter Families"), caption: String(localized: "Makharij, sifaat, rules"),
        specimen: "ص س ز",
        aliases: ["Makharij", "Sifaat", "Letter Groups", "مخارج", "صفات"],
        keywords: ["makhraj", "sifat", "articulation", "qualities", "tajweed rules", "groups",
                   "heavy", "light", "sun letters", "moon letters", "qalqalah", "noon sakinah", "meem sakinah", "أحكام"])

    static let soundAlikes = ArabicTopic(
        id: "soundAlikes", section: .explore,
        title: String(localized: "Sound-Alikes"), caption: String(localized: "Pairs people mix up"),
        specimen: "س ص",
        aliases: ["Sound Alikes", "Similar Sounds", "Confused Letters"],
        keywords: ["pairs", "mix up", "minimal pairs"])

    static let readingTest = ArabicTopic(
        id: "readingTest", section: .explore,
        title: String(localized: "Reading Test"), caption: String(localized: "21 tiers \u{00B7} letter quiz"),
        specimen: "بَ",
        aliases: ["Qaidah", "Qaida", "Noorani Qaidah"],
        keywords: ["test", "quiz", "tiers", "ladder", "reading", "practice", "placement", "find my level", "speed round"])

    static let quiz = ArabicTopic(
        id: "quiz", section: .readingTest,
        title: String(localized: "Letter Quiz"),
        caption: String(localized: "Name a letter, find it, read its joined form, place its family, or pick the one you hear. Ten questions a round."),
        specimen: "ب",
        keywords: ["quiz", "test", "letters", "listen", "forms", "practice"])

    static let tashkeel = ArabicTopic(
        id: "tashkeel", section: .explore,
        title: String(localized: "Tashkeel"), caption: String(localized: "Every mark on every letter"),
        specimen: "\u{0628}\u{064E}",
        aliases: ["Tashkil", "Harakat", "Harakaat", "Diacritics", "تشكيل", "حركات"],
        keywords: ["haraka", "vowels", "marks", "fatha", "kasra", "damma", "sukoon", "sukun",
                   "shaddah", "shadda", "tanween", "tanwin", "madd", "dagger alif", "تنوين", "شدة", "سكون"])

    static let defaultTashkeel = ArabicTopic(
        id: "defaultTashkeel", section: .explore,
        title: String(localized: "Default Tashkeel"), caption: String(localized: "Which mark a letter carries"),
        specimen: "\u{0628}\u{064F}",
        aliases: ["Default Marks"],
        keywords: ["unmarked", "forced marks", "no marks", "bare text", "which vowel"])

    static let basics = ArabicTopic(
        id: "basics", section: .explore,
        title: String(localized: "Basic Grammar"), caption: String(localized: "Gender, duals, plurals, and case endings"),
        specimen: "ال",
        aliases: ["Grammar", "Nahw", "نحو"],
        keywords: ["gender", "dual", "plural", "case", "i'raab", "iraab", "irab", "masculine", "feminine",
                   "idafa", "idaafah", "إعراب"])

    static let baaHaa = ArabicTopic(
        id: "baaHaa", section: .shapes,
        title: String(localized: "Baa on Haa"), caption: String(localized: "One shape, fifteen pairs"),
        specimen: BaaHaaShapesView.skeleton, face: .uthmani,
        aliases: ["Baa Haa", "Ba Ha", "بح"],
        keywords: ["shapes", "ligature", "stacked", "بحـ"])

    static let laamAlif = ArabicTopic(
        id: "laamAlif", section: .shapes,
        title: String(localized: "Laam Alif"), caption: String(localized: "The compulsory ligature"),
        specimen: LaamAlifShapesView.skeleton,
        aliases: ["Lam Alif", "Laam-Alif", "Lam-Alif", "لا", "لام ألف"],
        keywords: ["ligature", "laa"])

    static let maqsurahYaa = ArabicTopic(
        id: "maqsurahYaa", section: .shapes,
        title: String(localized: "Alif MaqSoorah or Yaa"), caption: String(localized: "One shape at the end, two letters"),
        specimen: MaqsurahOrYaaView.specimen, face: .plain,
        aliases: ["Alif Maqsurah", "Alif Maqsura", "Maqsurah", "Maqsoorah", "Maqsura", "Maqsoora", "ألف مقصورة"],
        keywords: ["yaa", "ya", "dotless yaa", "ى", "ي", "ياء"])

    static let wasl = ArabicTopic(
        id: "wasl", section: .wasl,
        title: String(localized: "Hamzatul WaSl"), caption: String(localized: "The hamza you only say at a start"),
        specimen: HamzatulWaslView.specimen, face: .uthmani,
        aliases: waslNames,
        keywords: ["tanween", "start vowel", "article", "al", "ibn", "ism", "two hamzas", "hamzatul qat'",
                   "hamzat al-qat", "qat", "qata", "همزة القطع"])

    static let pronouns = ArabicTopic(
        id: "pronouns", section: .grammar,
        title: ArabicGrammarTopic.pronouns.title, caption: ArabicGrammarTopic.pronouns.caption,
        specimen: ArabicGrammarTopic.pronouns.specimen,
        aliases: ["Pronouns", "Endings", "ضمائر", "ضمير"],
        keywords: ["pronoun", "suffix", "suffixes", "huwa", "hiya", "anta", "anti", "ana", "nahnu", "hum",
                   "attached", "possessive"])

    static let noun = ArabicTopic(
        id: "noun", section: .grammar,
        title: ArabicGrammarTopic.noun.title, caption: ArabicGrammarTopic.noun.caption,
        specimen: ArabicGrammarTopic.noun.specimen,
        aliases: ["Noun", "Ism", "اسم"],
        keywords: ["nouns", "i'raab", "iraab", "irab", "case endings", "nominative", "accusative", "genitive",
                   "damma", "dammatayn", "tanween", "إعراب"])

    static let verb = ArabicTopic(
        id: "verb", section: .grammar,
        title: ArabicGrammarTopic.verb.title, caption: ArabicGrammarTopic.verb.caption,
        specimen: ArabicGrammarTopic.verb.specimen,
        aliases: ["Verb", "Fi'l", "فعل"],
        keywords: ["verbs", "fil", "fiil", "past", "present", "command", "imperative", "tense"])

    static let harf = ArabicTopic(
        id: "harf", section: .grammar,
        title: ArabicGrammarTopic.harf.title, caption: ArabicGrammarTopic.harf.caption,
        specimen: ArabicGrammarTopic.harf.specimen,
        aliases: ["Harf", "Particles", "حرف"],
        keywords: ["huruf", "particle", "preposition", "prepositions", "little words", "fi", "min", "wa", "la", "حروف"])

    /// The screen's own sections: no page, the result scrolls the list to them.
    static let numbers = ArabicTopic(
        id: "numbers", section: .numbers,
        title: String(localized: "Arabic Numbers"), caption: String(localized: "The digits 0 to 9 and 10"),
        // Plain face: the mushaf faces draw bare digits inside an ayah-end ornament.
        specimen: "\u{0661}\u{0662}\u{0663}", face: .plain,
        aliases: ["Numbers", "Digits", "Numerals", "أرقام"],
        keywords: ["number", "counting", "arabic-indic", "zero", "one", "ten",
                   "٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩", "عدد"],
        opens: .scroll(rowID: ArabicTopicRowID.numbers))

    static let signs = ArabicTopic(
        id: "signs", section: .signs,
        title: String(localized: "Quran Signs"), caption: String(localized: "The stop and pause marks of the mushaf"),
        specimen: "مـ",
        aliases: ["Waqf Signs", "Stop Signs", "Pause Marks", "Signs", "علامات الوقف", "وقف"],
        keywords: ["waqf", "stops", "pause", "pauses", "mushaf marks", "sajdah", "ruku"] + StopSignInfo.all.map(\.title),
        opens: .scroll(rowID: ArabicTopicRowID.signs))

    /// The Explore tiles, as rows. The Reading Test tile and the Letter Quiz are phone screens.
    static let explore: [ArabicTopic] = {
        var topics = [families, soundAlikes]
        #if os(iOS)
        topics.append(readingTest)
        #endif
        topics += [tashkeel, defaultTashkeel, basics]
        return topics
    }()

    static let shapes: [ArabicTopic] = [baaHaa, laamAlif, maqsurahYaa]

    #if os(iOS)
    static let vowelLetters = ArabicTopic(
        id: "vowelLetters", section: .vowelLetters,
        title: String(localized: "Vowel Letters"),
        caption: String(localized: "When alif, waaw and yaa are vowels, and when consonants"),
        specimen: VowelLettersView.specimen, face: .plain,
        aliases: ["Huroof al-Madd", "Huruf al-Madd", "Madd Letters", "حروف المد", "حروف العلة"],
        keywords: ["long vowels", "alif waaw yaa", "alif waw ya", "vowel or consonant", "consonant", "leen", "soft letters"])

    static let vowelPractice = ArabicTopic(
        id: "vowelPractice", section: .vowelLetters,
        title: VowelOrConsonantPracticeView.title(for: nil),
        caption: String(localized: "Is the tinted letter a vowel or a consonant?"),
        specimen: VowelLetterRoles.waaw, face: .plain,
        keywords: ["vowel", "consonant", "practice", "drill", "quiz", "alif", "waaw", "yaa"])

    static let vowelLetterTopics: [ArabicTopic] = [vowelLetters, vowelPractice]

    /// The three drills, from the practice screen's own modes.
    static let waslDrills: [ArabicTopic] = HamzatulWaslPracticeView.Mode.allCases.map { mode in
        let own: [String]
        switch mode {
        case .start: own = ["start on it", "which vowel", "a i u", "fatha kasra damma", "start"]
        case .tanween: own = ["tanween", "tanwin", "noon", "nun", "kasra", "join", "تنوين"]
        case .readOn: own = ["read on", "read it on", "join", "long vowel", "sukoon", "tanween", "vowel"]
        }
        return ArabicTopic(id: "wasl" + mode.rawValue.prefix(1).uppercased() + mode.rawValue.dropFirst(), section: .wasl,
                           title: mode.title, caption: mode.caption, specimen: mode.specimen, face: .uthmani,
                           keywords: waslNames + ["practice", "drill", "exercise", "quiz"] + own)
    }

    /// Every tier of the Reading Test, so "tanween" also finds the tier that drills it.
    static let readingTiers: [ArabicTopic] = ReadingTier.all.map { tier in
        ArabicTopic(id: "tier:" + tier.id, section: .readingTest,
                    title: tier.title, caption: tier.summary, specimen: tier.specimen, face: .plain,
                    aliases: [tier.arabic],
                    keywords: ["tier", "reading test", "level"] + (tier.feature.map { [$0] } ?? []))
    }
    #else
    static let vowelLetterTopics: [ArabicTopic] = []
    static let waslDrills: [ArabicTopic] = []
    static let readingTiers: [ArabicTopic] = []
    #endif

    static let grammar: [ArabicTopic] = [pronouns, noun, verb, harf]

    /// The Quran's most common words (2026-11-16), after the grammar pages: the phone's, and only
    /// where the Quran ships (its rows open the Word Study card).
    #if os(iOS) && HAS_QURAN
    static let quranWords = ArabicTopic(
        id: "quranWords", section: .quranWords,
        title: String(localized: "Quran Words"),
        caption: String(localized: "The 500 most common words, four in five of what you recite"),
        specimen: "قَالَ", face: .uthmani,
        aliases: ["Quran Vocabulary", "Common Words", "مفردات القرآن", "كلمات القرآن"],
        keywords: ["vocabulary", "words", "most common", "frequency", "lemma", "root", "roots",
                   "meaning", "understand", "learn words", "flashcards", "quiz", "test"])

    static let quranWordsTopics: [ArabicTopic] = [quranWords]
    #else
    static let quranWordsTopics: [ArabicTopic] = []
    #endif

    /// Every topic, in the order the screen shows them: a tie in the ranking keeps this order.
    static let all: [ArabicTopic] = {
        var topics = explore
        topics += shapes
        topics += vowelLetterTopics
        topics += [wasl]
        topics += waslDrills
        topics += grammar
        topics += quranWordsTopics
        topics += [numbers, signs]
        #if os(iOS)
        topics += [quiz]
        #endif
        topics += readingTiers
        return topics
    }()

    static func topic(id: String) -> ArabicTopic? { all.first { $0.id == id } }

    /// The search fold both sides go through: accents off the Latin, then the app's search fold
    /// (case, Arabic marks and letter forms, joiners as word breaks).
    static func fold(_ text: String) -> String {
        SearchRank.fold(text.foldingLatinDiacritics)
    }

    /// The topics whose words carry EVERY word of the query, the ones named for it first. Three
    /// characters before anything answers ("ba" would list half the screen above the letters it
    /// names), two when the query is Arabic.
    ///
    /// `ArabicTopic.score`, with one rule of this screen's on top: a Reading Test tier ranks a notch
    /// under the screen's own sections, so "hamzat al-wasl", the tier's exact title and the page's
    /// other spelling, still leads with the page. Ties keep the order the screen shows them in.
    static func matching(_ text: String) -> [ArabicTopic] {
        let folded = fold(text)
        guard let query = SearchRank.Query(folded) else { return [] }
        let minimum = folded.containsArabicScript ? 2 : 3
        guard folded.replacingOccurrences(of: " ", with: "").count >= minimum else { return [] }
        var scored: [(topic: ArabicTopic, score: Int, order: Int)] = []
        for (order, topic) in all.enumerated() {
            let haystack = topic.haystack
            guard query.terms.allSatisfy({ haystack.contains($0) }) else { continue }
            var score = topic.score(query)
            if topic.section == .readingTest { score -= 50 }
            scored.append((topic, score, order))
        }
        return scored
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.order < $1.order }
            .map(\.topic)
    }
}

/// The ids the alphabet list's scroll-to results land on: on the section's header, which is a real
/// row of the List (a `Section` itself has no scroll identity).
enum ArabicTopicRowID {
    static let numbers = "section_numbers"
    static let signs = "section_signs"
}

// MARK: - Opening a topic

/// The page a topic id opens: the one switch behind the search rows and the `-arabicTopic` debug
/// route. A scroll topic has no page; its row never asks for one.
struct ArabicTopicDestination: View {
    let id: String

    var body: some View {
        switch id {
        case "families": LetterFamiliesView()
        case "soundAlikes": SoundAlikeLettersView()
        case "tashkeel": TashkeelLettersView()
        case "defaultTashkeel": DefaultTashkeelView()
        case "basics": ArabicBasicsView()
        case "baaHaa": BaaHaaShapesView()
        case "laamAlif": LaamAlifShapesView()
        case "maqsurahYaa": MaqsurahOrYaaView()
        case "wasl": HamzatulWaslView()
        case "pronouns": ArabicPronounsView()
        case "noun": ArabicNounView()
        case "verb": ArabicVerbView()
        case "harf": ArabicHarfView()
        #if os(iOS)
        case "readingTest": ReadingTestView()
        case "quiz": LetterQuizView()
        case "waslStart": HamzatulWaslPracticeView(mode: .start)
        case "waslTanween": HamzatulWaslPracticeView(mode: .tanween)
        case "waslReadOn": HamzatulWaslPracticeView(mode: .readOn)
        case "vowelLetters": VowelLettersView()
        case "vowelPractice": VowelOrConsonantPracticeView(letter: nil)
        #if HAS_QURAN
        case "quranWords": QuranWordsView()
        #endif
        case let tier where tier.hasPrefix("tier:"):
            if let tier = ReadingTier.all.first(where: { $0.id == String(tier.dropFirst("tier:".count)) }) {
                ReadingTierView(tier: tier)
            }
        #endif
        default: EmptyView()
        }
    }
}
