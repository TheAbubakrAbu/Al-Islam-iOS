import Foundation

// Ask AI - what a question IS, decided before anything is retrieved or generated.
//
// The old chat ran every message through the same retrieval and the same prompt, so "hello" fetched
// five hadiths about greetings and "how do I change the reciter" fetched Taraweeh. A question's kind
// now decides whether it retrieves at all, which lanes lead, how the model is asked to shape the
// answer, and how long the answer may run. A follow-up ("why?", "who narrated that?") is recognised
// too, so it searches with the conversation's topic and answers from the previous turn's sources.

#if os(iOS)

enum AskAIIntent: String, Codable, CaseIterable {
    // Conversation, no retrieval.
    case greeting, thanks, farewell, capabilities, smallTalk
    /// About the previous answer's sources ("who narrated that?", "which surah is that from?"):
    /// answered from the previous turn's sources, nothing new fetched.
    case sourceQuestion
    /// A rework of the previous answer ("summarize that", "simpler", "shorter"): the last turn
    /// alone, its sources kept, nothing new fetched.
    case recap
    // Retrieval, each with its own lane weights and task line.
    case appHelp, prayerTimes, reference, scripture, hadith, define, howTo, ruling, story, dua, general

    /// Whether the app searches its library for this question.
    var retrieves: Bool {
        switch self {
        case .greeting, .thanks, .farewell, .capabilities, .smallTalk, .sourceQuestion, .recap: return false
        default: return true
        }
    }

    var isConversational: Bool {
        switch self {
        case .greeting, .thanks, .farewell, .capabilities, .smallTalk: return true
        default: return false
        }
    }

    /// The token ceiling for the answer. Chit-chat is a sentence or two; a how-to or a story may
    /// run long; everything else stops before a small model starts padding.
    var maxResponseTokens: Int {
        switch self {
        case .greeting, .thanks, .farewell, .smallTalk: return 160
        case .capabilities: return 260
        case .sourceQuestion: return 400
        case .recap: return 500
        case .howTo, .story: return 1000
        default: return 900
        }
    }

    /// Measured on the on-device model: 0.7 drifts from the sources, 0.3 loops; 0.5 keeps
    /// citations put. Conversation can be warmer.
    var temperature: Double { isConversational ? 0.7 : 0.5 }

    /// What the model is told to do with this question, after the sources and the conversation.
    var taskLine: String {
        switch self {
        case .greeting:
            return "The reader is greeting you. Greet them back warmly in one or two sentences (return a salam with a salam) and offer to help with the Quran, the hadith, prayer, or the app. No sources, no list."
        case .thanks:
            return "The reader is thanking you. Reply briefly and warmly, one sentence or two, and offer to help further."
        case .farewell:
            return "The reader is saying goodbye. Reply briefly and warmly, one sentence or two."
        case .capabilities:
            return "The reader is asking what you can do. Say, warmly and briefly, what you can help with here: explaining verses and surahs, what the Quran and the hadith say on a subject, the Names of Allah, duas, how to pray, fast and perform other acts of worship, Islamic history and the prophets, and using this app (reciters, fonts, notifications, widgets). Invite a question. No sources."
        case .smallTalk:
            return "The reader is making small talk. Reply naturally and briefly, as a friendly assistant inside a Quran app would, then offer help."
        case .sourceQuestion:
            return "The reader is asking about the sources of the previous answer (who narrated it, which collection or surah it comes from, how it is graded, where to find it). Answer in a sentence or two per source asked about, from the details written beside that source above: the collection and its compiler, the chapter, the narrator, the grade; for a verse, its surah and translation. Cite by number. If the reader calls a source a hadith but it is a verse of the Quran (or the other way round), say so. If the details do not say, say so plainly rather than guessing."
        case .recap:
            return "The reader wants your previous answer reworked as asked (a summary, a shorter or simpler version, a restatement). Rework ONLY that answer, keeping its citations by number; add no new subjects."
        case .appHelp:
            return "The question is about using THIS app (Al-Islam). Answer only from the setting and tip sources: name the exact place (the tab, then the screen, then the setting, in the app's own words, for example Settings, then Quran Settings, then Recitation) and what the control does, as short steps if there are several. Do not invent screens or controls. If no source covers it, say you are not sure the app has that and suggest searching in Settings."
        case .prayerTimes:
            return "The question is about today's prayer schedule. Answer from the \u{201C}Prayer times today\u{201D} source exactly as written (times and rakah counts), doing any arithmetic the question needs from the current time it states."
        case .reference:
            return "The question names a specific verse, surah, hadith or Name, marked SUBJECT OF THE QUESTION. Explain that one: what it says, its context, and its meaning, drawing on the tafsir or background source when there is one, and say where each point comes from. Do not describe some other verse instead."
        case .scripture:
            return "Say what the Quran and the hadith teach on this subject, in two to four short paragraphs written in your own words (no list of quotations). Make each point from the sources that actually address the question, say where it comes from (a verse as Allah's words in its surah; a hadith by its narrator and collection), and cite by number. Quote at most one short phrase or sentence per source, in quotation marks."
        case .hadith:
            return "The reader wants what the hadith say. Answer in short paragraphs written in your own words, from the hadith sources first: name the collection and the narrator of each, with its grade where given, and cite by number; add the Quran where it bears on the subject. Quote at most one short phrase or sentence per source."
        case .define:
            return "Define or explain the term in one clear paragraph in your own words, then deepen it in one or two more paragraphs with what the Quran, the hadith and the app's articles say about it, citing each by number and saying where it comes from. Do not copy a source's text; restate it."
        case .howTo:
            return "Give clear practical guidance as numbered steps written in your own words, drawn from the sources (the app's how-to article when there is one, the hadith that establish the practice), then the conditions or common mistakes worth knowing. Say where each point comes from and cite by number. Never copy the numbered source lines themselves into the answer."
        case .ruling:
            return "This asks whether something is allowed. Do not issue a verdict. Explain the considerations, what the evidence says and where scholars differ, citing the sources by number and saying where each comes from, and close by pointing the reader to a qualified scholar for their own situation."
        case .story:
            return "Tell it the way the Quran and the hadith tell it, in order, as flowing paragraphs in your own words, naming where each part comes from (the surah; the collection and narrator) and citing by number. Keep to what the sources and sound knowledge support, and say when something is a scholarly view rather than the text."
        case .dua:
            return "Give the dua or dhikr from the sources: when it is said, then its meaning in English, citing by number and naming its collection and reference. The app shows the Arabic and the transliteration beneath your answer, so do not attempt to write Arabic letters."
        case .general:
            return "Answer the question directly and completely, using the sources that fit (say where each comes from and cite by number) and general knowledge for the rest, saying which is which."
        }
    }
}

/// A question, analysed: its intent, whether it is a follow-up, its content words and search terms.
struct AskAIQuestion {
    let raw: String
    let intent: AskAIIntent
    /// Whether the question only makes sense with the previous turn beside it ("why?", "and zakat?").
    let isFollowUp: Bool
    /// The lowercased words that carry meaning: no stop words, no question words, no generic
    /// "islam/quran/hadith" words (those steer the lanes instead, see `leansQuran`/`leansHadith`).
    let contentWords: [String]
    /// The text the retrieval searches: for a follow-up, the conversation's topic folded in.
    let searchText: String
    /// Content words plus their synonyms across English and Arabic ("prayer" adds "salah").
    let searchTerms: [String]
    /// The terms the question's SHAPE contributed ("how much" -> amount, rate, nisab): what a
    /// follow-up is really asking, when its own words are all stop words.
    let hintTerms: [String]
    let isArabic: Bool
    let asksForRuling: Bool
    let leansQuran: Bool
    let leansHadith: Bool
    /// Whether the question mentions the app itself, its screens or its settings.
    let mentionsApp: Bool
    /// The content words as the reader typed them (their case kept), for the suggestion chips.
    let topicDisplay: String
    /// The subject, for the next follow-up's search: the content words joined.
    var topic: String { contentWords.joined(separator: " ") }

    // MARK: Analysis

    /// `previousTopic` is the conversation's current subject (the last standalone question's
    /// content words); `hasHistory` whether there is any completed turn to follow up on.
    static func analyze(_ raw: String, previousTopic: String?, hasHistory: Bool) -> AskAIQuestion {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = AskAILexicon.fold(trimmed)
        let words = lowered.split(separator: " ").map(String.init)
        let isArabic = trimmed.containsArabicLetters
        var content = isArabic
            ? words.filter { $0.count >= 2 }
            : words.filter { $0.count >= 2 && !AskAILexicon.stopWords.contains($0) && !AskAILexicon.domainWords.contains($0) }
        let mentionsApp = AskAILexicon.mentionsApp(lowered)
        let asksForRuling = AskAILexicon.rulingRegex.firstMatch(in: trimmed, range: NSRange(location: 0, length: (trimmed as NSString).length)) != nil
        // "is music haram": the ruling words name no topic and match everywhere ("Masjid al-Haram",
        // "halal food"), so they leave the search terms when a real topic word remains.
        let withoutRulingWords = content.filter { !AskAILexicon.rulingWords.contains($0) }
        if !withoutRulingWords.isEmpty { content = withoutRulingWords }
        let leansQuran = ["quran", "qur'an", "koran", "verse", "verses", "ayah", "ayat", "surah", "sura", "chapter"].contains(where: { lowered.contains($0) })
        let leansHadith = ["hadith", "hadiths", "ahadith", "sunnah", "narrat", "prophet said", "prophet say", "messenger said", "bukhari", "muslim narr", "tirmidhi"].contains(where: { lowered.contains($0) })

        // "this app" / "the app" name the app, never the previous turn.
        let backReferenceWords = lowered.replacingOccurrences(of: "this app", with: "app").replacingOccurrences(of: "the app", with: "app")
            .split(separator: " ").map(String.init)
        let substantive = words.filter { !AskAILexicon.stopWords.contains($0) }.count
        // An Arabic query is a topic in its own right ("الصبر"), never a follow-up.
        var followUp = !isArabic && looksLikeFollowUp(lowered, words: backReferenceWords, substantiveCount: substantive, hasHistory: hasHistory)
        let intent = classify(trimmed: trimmed, lowered: lowered, words: words, contentCount: content.count,
                              isArabic: isArabic, mentionsApp: mentionsApp, asksForRuling: asksForRuling,
                              leansHadith: leansHadith, isFollowUp: followUp, hasHistory: hasHistory)
        // "Explain 2:255" names its own subject: a follow-up only when it also points back.
        if intent == .reference, !backReferenceWords.contains(where: { AskAILexicon.backReferences.contains($0) }) {
            followUp = false
        }
        // The content words as typed, hyphens and apostrophes kept ("al-Wadud"), for the chips.
        let originalWords = trimmed.components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-'\u{2019}")).inverted)
            .filter { !$0.isEmpty }
        let topicDisplay = originalWords.filter { word in
            let folded = AskAILexicon.fold(word)
            return folded.split(separator: " ").contains { content.contains(String($0)) }
        }.joined(separator: " ")

        // A follow-up searches as "topic + this question": on its own "why?" retrieves noise.
        var searchText = trimmed
        if followUp, let previousTopic, !previousTopic.isEmpty, !isArabic {
            searchText = previousTopic + " " + trimmed
        }
        var terms = content
        if followUp, let previousTopic { terms = previousTopic.split(separator: " ").map(String.init) + terms }
        // Content words, then their synonyms, then the hints: "how much", "who has to", "what breaks"
        // carry meaning their words (all stop words) do not, and the hints put it into the search
        // AFTER the synonyms, so a spelling twin ("wudhu") is never crowded out.
        var expanded = AskAILexicon.expand(terms)
        let hints = AskAILexicon.phraseHints(in: lowered)
        for hint in hints where !expanded.contains(hint) { expanded.append(hint) }

        return AskAIQuestion(raw: trimmed, intent: intent, isFollowUp: followUp, contentWords: content,
                             searchText: searchText, searchTerms: expanded, hintTerms: hints, isArabic: isArabic,
                             asksForRuling: asksForRuling, leansQuran: leansQuran, leansHadith: leansHadith,
                             mentionsApp: mentionsApp, topicDisplay: topicDisplay.isEmpty ? content.joined(separator: " ") : topicDisplay)
    }

    private static let standaloneShapeRegex = try! NSRegularExpression(
        pattern: #"^(what|who|when|where|which|how|why) (is|are|was|were|does|do|did|can|should|would|will) [a-z]"#)

    /// A question that only makes sense with the previous turn beside it: a short message with
    /// fewer than two substantive words ("why?", "and zakat?", "tell me more"), unless it has the
    /// shape of a whole question ("what is tawhid"); or a short one that opens like a continuation
    /// ("what about fasting") or leans on a pronoun ("who narrated that?").
    private static func looksLikeFollowUp(_ lowered: String, words: [String], substantiveCount: Int, hasHistory: Bool) -> Bool {
        guard hasHistory, !lowered.isEmpty else { return false }
        let whole = NSRange(location: 0, length: (lowered as NSString).length)
        let standaloneShape = standaloneShapeRegex.firstMatch(in: lowered, range: whole) != nil
        if substantiveCount < 2, words.count <= 5, !(standaloneShape && substantiveCount >= 1) { return true }
        guard substantiveCount <= 3 else { return false }
        if AskAILexicon.followUpStarters.contains(where: { lowered.hasPrefix($0) }) { return true }
        if words.contains(where: { AskAILexicon.backReferences.contains($0) }) { return true }
        return false
    }

    private static func classify(trimmed: String, lowered: String, words: [String], contentCount: Int,
                                 isArabic: Bool, mentionsApp: Bool, asksForRuling: Bool, leansHadith: Bool,
                                 isFollowUp: Bool, hasHistory: Bool) -> AskAIIntent {
        let wordCount = words.count
        let whole = NSRange(location: 0, length: (lowered as NSString).length)
        // Conversation first, and only when the WHOLE message is the pleasantry: "hello, what does
        // the Quran say about patience" is a question with a greeting on it, not a greeting.
        if wordCount <= 6 {
            if AskAILexicon.matchesWhole(lowered, any: AskAILexicon.greetings) { return .greeting }
            if AskAILexicon.matchesWhole(lowered, any: AskAILexicon.thanks) { return .thanks }
            if AskAILexicon.matchesWhole(lowered, any: AskAILexicon.farewells) { return .farewell }
        }
        if wordCount <= 12 {
            if AskAILexicon.capabilities.contains(where: { lowered.contains($0) }) { return .capabilities }
            if AskAILexicon.smallTalk.contains(where: { lowered.contains($0) }) { return .smallTalk }
        }
        if hasHistory, AskAILexicon.sourceQuestionRegex.firstMatch(in: lowered, range: whole) != nil {
            return .sourceQuestion
        }
        if hasHistory, wordCount <= 8, AskAILexicon.recapRegex.firstMatch(in: lowered, range: whole) != nil {
            return .recap
        }
        // Today's clock: a named prayer, or prayer in general with a clock word (the loose gate used
        // to drag the whole timetable into answers about charity).
        let wordSet = Set(words)
        let namedPrayer = !wordSet.isDisjoint(with: AskAILexicon.prayerNames)
        let clock = !wordSet.isDisjoint(with: AskAILexicon.clockWords)
        let prayerGeneral = !wordSet.isDisjoint(with: AskAILexicon.prayerGeneral)
        #if HAS_ADHAN
        if (namedPrayer && clock) || (prayerGeneral && clock && wordCount <= 10) || (namedPrayer && wordCount <= 4) {
            return .prayerTimes
        }
        #else
        _ = (namedPrayer, clock, prayerGeneral)
        #endif
        if mentionsApp, AskAILexicon.appHelpRegex.firstMatch(in: lowered, range: whole) != nil {
            return .appHelp
        }
        // A named verse, surah, hadith or Name (the retrieval resolves it; here only the shape). A
        // time of day ("isha at 11:30") is not a verse reference.
        let withoutClockTimes = AskAILexicon.maskingClockTimes(trimmed)
        var namesReference = AskAILexicon.referenceRegex.firstMatch(in: withoutClockTimes, range: NSRange(location: 0, length: (withoutClockTimes as NSString).length)) != nil
        #if HAS_HADITH
        if !namesReference, HadithReferenceParser.parse(trimmed) != nil { namesReference = true }
        #endif
        if namesReference { return .reference }
        if AskAILexicon.duaWords.contains(where: { lowered.contains($0) }) { return .dua }
        if asksForRuling { return .ruling }
        if AskAILexicon.howToRegex.firstMatch(in: lowered, range: whole) != nil { return .howTo }
        if AskAILexicon.storyRegex.firstMatch(in: lowered, range: whole) != nil { return .story }
        if leansHadith { return .hadith }
        if AskAILexicon.scriptureRegex.firstMatch(in: lowered, range: whole) != nil { return .scripture }
        if AskAILexicon.defineRegex.firstMatch(in: lowered, range: whole) != nil { return .define }
        // A bare topic ("patience", "zakat on gold") is a what-does-the-Quran-say question.
        if !isFollowUp, contentCount <= 3, wordCount <= 4 { return .scripture }
        return .general
    }
}

// MARK: - Word lists

enum AskAILexicon {
    /// Lowercased, accents stripped, apostrophes dropped, everything else non-alphanumeric a space.
    /// Arabic harakat, Quranic annotation marks and the tatweel go too: diacritic folding leaves
    /// them (they count as alphanumerics), so "الصَّبْر" never matched "الصبر".
    static func fold(_ text: String) -> String {
        var plain = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
        for apostrophe in ["'", "\u{2019}", "\u{02BC}", "`"] {
            plain = plain.replacingOccurrences(of: apostrophe, with: "")
        }
        var scalars = String.UnicodeScalarView()
        for scalar in plain.unicodeScalars {
            if arabicMarks.contains(scalar.value) { continue }
            scalars.append(CharacterSet.alphanumerics.contains(scalar) || scalar == ":" ? scalar : " ")
        }
        return String(scalars).replacingOccurrences(of: #" {2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    /// The harakat (U+064B-065F), the superscript alef (U+0670), the Quranic annotation marks
    /// (U+06D6-06ED) and the tatweel (U+0640).
    private static func isArabicMark(_ value: UInt32) -> Bool {
        (0x064B...0x065F).contains(value) || value == 0x0670 || (0x06D6...0x06ED).contains(value) || value == 0x0640
    }
    private static let arabicMarks: Set<UInt32> = Set((UInt32(0x0600)...UInt32(0x06FF)).filter(isArabicMark))

    /// Whether the (folded) question is about the app: a whole-word match on a word that only the
    /// app's own features use ("reciter", "widget", "settings"), or on an everyday verb ("share",
    /// "copy", "turn off") that only counts beside a thing the app shows. Substrings used to count,
    /// so "charitable" held "tab", "compassion" held "compass", and "how do I share inheritance"
    /// was sent to the settings index.
    static func mentionsApp(_ lowered: String) -> Bool {
        let padded = " " + lowered + " "
        func has(_ phrase: String) -> Bool { padded.contains(" " + phrase + " ") }
        if appWords.contains(where: has) { return true }
        guard appVerbs.contains(where: has) else { return false }
        return appObjects.contains(where: has)
    }

    /// Whether the whole (folded) message is one of the phrases, allowing a trailing name or
    /// pleasantry ("hello there", "thanks a lot", "assalamu alaikum brother").
    static func matchesWhole(_ lowered: String, any phrases: [String]) -> Bool {
        for phrase in phrases {
            if lowered == phrase { return true }
            if lowered.hasPrefix(phrase + " ") {
                let rest = lowered.dropFirst(phrase.count + 1)
                let restWords = rest.split(separator: " ")
                if restWords.count <= 3, restWords.allSatisfy({ pleasantryTails.contains(String($0)) }) { return true }
            }
        }
        return false
    }

    private static let pleasantryTails: Set<String> = [
        "there", "brother", "sister", "friend", "again", "ai", "assistant", "everyone", "all", "you", "so", "much",
        "a", "lot", "very", "really", "bro", "sis", "akhi", "ukhti", "dear", "and", "hi", "hello",
    ]

    static let greetings = [
        "hello", "hi", "hey", "hii", "hiii", "heya", "yo", "salam", "salaam", "salam alaikum", "salam alaykum",
        "salamu alaikum", "salamu alaykum", "assalamu alaikum", "assalamu alaykum", "assalamualaikum", "asalamu alaikum",
        "asalamualaikum", "as salamu alaykum", "as salamu alaikum", "assalam o alaikum", "assalamu alaikum wa rahmatullah",
        "assalamu alaikum wa rahmatullahi wa barakatuh", "peace be upon you", "good morning", "good evening",
        "good afternoon", "morning", "evening", "greetings", "whats up", "sup", "hello ai", "hi ai", "hi there",
        "hello there", "hey there", "hi assistant",
    ]
    static let thanks = [
        "thanks", "thank you", "thankyou", "thx", "ty", "thank u", "thanks a lot", "thank you so much", "thanks so much",
        "jazakallah", "jazak allah", "jazakallah khair", "jazakallahu khairan", "jazakallah khayr", "jazakallahu khair",
        "jazakallahu khayran", "jazakumullah khairan", "shukran", "barakallahu feek", "barakallah feek", "barak allahu feek",
        "appreciate it", "much appreciated", "great thanks", "perfect thanks", "ok thanks", "okay thanks", "cool thanks",
        "thanks that helps", "that helps", "great", "perfect", "awesome", "nice", "cool", "got it", "ok", "okay", "alright",
        "mashallah", "masha allah", "alhamdulillah",
    ]
    static let farewells = [
        "bye", "goodbye", "bye bye", "see you", "see ya", "take care", "good night", "goodnight", "fi amanillah",
        "fi aman allah", "salam bye", "assalamu alaikum bye", "later", "cya", "im done", "thats all", "that is all",
        "thats all thanks",
    ]
    static let capabilities = [
        "what can you do", "what do you do", "how can you help", "what can i ask", "what are you able", "what can you help",
        "who are you", "what are you", "are you an ai", "are you chatgpt", "are you a bot", "are you human", "what is this",
        "how does this work", "how do you work", "what is ask ai", "what should i ask", "help me", "can you help",
        "what are you for", "what is your name", "whats your name", "your name", "introduce yourself",
    ]
    static let smallTalk = [
        "how are you", "how are u", "hows it going", "how is it going", "how do you do", "hows your day", "are you ok",
        "are you okay", "are you a muslim", "are you muslim", "do you pray", "do you sleep", "are you real", "i love you",
        "you are great", "you are awesome", "youre great", "youre awesome", "good job", "well done", "lol", "haha",
        "i am bored", "im bored", "tell me a joke", "im sad", "i am sad", "i feel sad", "im tired",
    ]

    /// The words that carry no subject: never searched, never a topic.
    static let stopWords: Set<String> = [
        "a", "an", "the", "of", "in", "on", "at", "to", "for", "from", "by", "with", "about", "and", "or", "but",
        "is", "are", "was", "were", "be", "been", "being", "am", "do", "does", "did", "have", "has", "had", "having",
        "i", "me", "my", "mine", "you", "your", "yours", "we", "our", "us", "he", "she", "it", "they", "them", "his",
        "her", "hers", "its", "their", "theirs", "this", "that", "these", "those", "there", "here", "what", "which",
        "who", "whom", "whose", "why", "how", "when", "where", "can", "could", "should", "would", "will", "shall",
        "may", "might", "must", "please", "pls", "plz", "tell", "explain", "mean", "means", "meaning", "say", "says",
        "said", "some", "any", "many", "much", "more", "most", "very", "really", "just", "also", "so", "than",
        "then", "if", "not", "no", "yes", "ok", "okay", "like", "into", "over", "under", "again", "get", "give",
        "know", "want", "need", "thing", "things", "something", "anything", "one", "ones", "way", "kind", "sort",
        "lot", "bit", "all", "every", "each", "both", "few", "such", "own", "same", "other", "others", "too",
        "only", "ever", "never", "always", "up", "down", "out", "off", "let", "im", "ive", "dont", "cant", "isnt",
        "whats", "wheres", "hows", "thats", "doesnt", "didnt", "wont", "u", "ur", "r", "regarding",
        "according", "describe", "discuss", "talk", "regard", "someone", "anyone", "people", "person",
        "true", "correct", "right", "wrong", "good", "bad", "best", "better", "important", "difference", "between",
        "vs", "versus", "example", "examples", "list", "name", "names", "kinds", "types", "type", "sorts",
        "perform", "performing", "performed", "make", "making", "made", "done", "doing", "step", "steps", "guide",
        "procedure", "method", "properly", "correctly", "exactly", "basically", "actually", "simply",
    ]

    /// Question shapes made of stop words, and the search terms that carry their meaning.
    private static let phraseHintTable: [(String, [String])] = [
        ("how much", ["amount", "rate", "nisab", "percent", "calculate"]),
        ("how many", ["number", "count", "times"]),
        ("how long", ["duration", "length", "period"]),
        ("how often", ["frequency", "daily", "times"]),
        ("who has to", ["obligatory", "conditions", "who must", "eligible"]),
        ("who must", ["obligatory", "conditions", "eligible"]),
        ("who should", ["obligatory", "conditions"]),
        ("when should", ["time", "timing", "when"]),
        ("when is", ["time", "timing"]),
        ("when do", ["time", "timing"]),
        ("what breaks", ["nullifies", "invalidates", "breaks", "invalid"]),
        ("what invalidates", ["nullifies", "breaks", "invalid"]),
        ("what happens if", ["missed", "mistake", "forgot", "ruling"]),
        ("what if i", ["missed", "mistake", "forgot"]),
        ("what are the conditions", ["conditions", "requirements", "obligatory"]),
        ("what is the reward", ["reward", "virtue", "merit"]),
        ("what is the punishment", ["punishment", "warning", "sin"]),
    ]

    static func phraseHints(in lowered: String) -> [String] {
        var out: [String] = []
        for (phrase, hints) in phraseHintTable where lowered.contains(phrase) {
            for hint in hints where !out.contains(hint) { out.append(hint) }
        }
        return out
    }

    /// The words a ruling question is asked with; they steer the intent, not the search.
    static let rulingWords: Set<String> = [
        "haram", "halal", "haraam", "halaal", "permissible", "permitted", "allowed", "forbidden", "prohibited",
        "makruh", "makrooh", "obligatory", "wajib", "fard", "sinful", "sin", "ok", "okay", "fine",
    ]

    /// Generic to this app: they steer which lanes lead, but name no topic.
    static let domainWords: Set<String> = [
        "islam", "islamic", "muslim", "muslims", "religion", "religious", "quran", "quraan", "koran", "qur", "hadith",
        "hadiths", "ahadith", "hadees", "sunnah", "allah", "god", "prophet", "prophets", "messenger", "rasul",
        "verse", "verses", "ayah", "ayat", "ayahs", "surah", "sura", "surat", "chapter", "chapters", "book", "books",
        "teach", "teaches", "teaching", "teachings", "scholars", "scholar", "sheikh", "shaykh", "imam", "ruling",
        "rulings", "evidence", "daleel", "dalil", "proof",
    ]

    /// Words (folded, matched whole) that only the app's own features use. No question shapes
    /// ("how do i get", "where is the"): those are how every religious question starts too.
    static let appWords = [
        "app", "apps", "setting", "settings", "widget", "widgets", "notification", "notifications", "reciter", "reciters",
        "font", "fonts", "dark mode", "light mode", "download", "downloads", "downloaded", "bookmark", "bookmarks",
        "bookmarked", "tab", "tabs", "button", "buttons", "screen", "page mode", "list mode", "playback", "siri",
        "apple watch", "icloud", "backup", "back up", "tracker", "streak", "qibla compass", "compass", "tasbih counter",
        "adhan sound", "athan sound", "adhan notification", "prayer notification", "accent color", "accent colour",
        "app icon", "haptic", "haptics", "translation setting", "word by word", "tajweed color", "tajweed colors",
        "tajweed colour", "tajweed colours", "night mode", "lock screen", "home screen", "live activity",
        "search bar", "long press", "reading mode", "arabic font", "text size", "font size", "reading theme",
        "reading themes", "app theme",
    ]
    /// Everyday verbs and nouns that mean the app only beside one of `appObjects`: "share an ayah"
    /// is the app, "share inheritance" is not. ("Themes" stays out: "the themes of Surah Yusuf".)
    static let appVerbs = [
        "share", "sharing", "copy", "copying", "export", "import", "sync", "offline", "filter", "sort", "swipe", "tap",
        "toggle", "switch", "enable", "disable", "turn on", "turn off", "customize", "customise", "change the",
        "highlight", "highlighting", "audio", "accent", "transliteration", "counter", "the watch",
    ]
    static let appObjects = [
        "ayah", "ayahs", "verse", "verses", "hadith", "hadiths", "surah", "dua", "duas", "answer", "answers",
        "image", "picture", "screenshot", "card", "link", "text", "note", "notes", "journal", "arabic", "translation",
        "tafsir", "riwayah", "qiraah", "qiraat", "recitation", "mushaf", "color", "colour", "colors", "colours",
        "adhan", "athan", "alarm", "sound", "sounds", "volume", "language", "sepia", "count", "phone", "iphone",
        "ipad", "mac", "view", "mode", "layout", "page", "pages", "size", "reminder", "reminders", "calendar",
        "history", "search", "results", "progress", "data", "tajweed", "word", "words",
    ]
    static let appHelpRegex = try! NSRegularExpression(
        pattern: #"(?i)\b(how (do|can|to|does|should) (i|you|one|we)?|where (is|are|can|do)|can (i|you)|is there (a|an)|does (the|this) app|change|turn (on|off)|enable|disable|set up|setting|settings|widget|notification|reciter|font|theme|dark mode|bookmark|download|customi[sz]e|toggle|switch|option|icon|siri|watch|backup|icloud|tracker|streak|qibla|compass|tasbih|counter|playback|audio|highlight|layout|export|share|copy|search|filter|sort)\b"#)

    static let prayerNames: Set<String> = [
        "fajr", "sunrise", "shuruq", "shurooq", "dhuhr", "duhr", "zuhr", "dhur", "asr", "maghrib", "isha", "ishaa",
        "esha", "jumuah", "jumaah", "jummah", "duha", "duhaa", "tahajjud", "witr", "qiyam", "suhoor", "suhur", "iftar",
    ]
    static let prayerGeneral: Set<String> = [
        "prayer", "prayers", "pray", "prayed", "praying", "salah", "salat", "salaah", "namaz", "adhan", "athan",
        "iqamah", "rakah", "rakahs", "rakat", "rakaat", "midnight", "night",
    ]
    static let clockWords: Set<String> = [
        "time", "times", "when", "schedule", "timetable", "today", "tonight", "tomorrow", "now", "next", "left",
        "until", "till", "start", "starts", "started", "begin", "begins", "end", "ends", "late", "early", "minutes",
        "hours", "remaining", "countdown", "clock", "oclock", "long", "soon", "yet", "still", "missed", "miss",
    ]

    static let duaWords = [
        "dua", "duas", "du'a", "supplication", "supplications", "what to say when", "what do i say", "what should i say",
        "what should i recite", "what to recite", "adhkar", "azkar", "dhikr", "zikr", "morning adhkar", "evening adhkar",
        "istikhara", "istikharah dua", "dua for", "prayer for ", "invocation",
    ]
    static let rulingRegex = try! NSRegularExpression(
        pattern: #"(?i)\b(?:haram|halal|haraam|halaal|permissible|permitted|allowed|forbidden|prohibited|makruh|makrooh|obligatory|wajib|fard|sinful|a sin|is it ok|is it okay|is (?:that|this) (?:ok|okay|fine|allowed|permissible)|can i|am i allowed|may i|are we allowed|is it allowed|is it wrong|is it a sin|is it bad|is it fine|allowed to|ok to|okay to)\b|حرام|حلال|يجوز|جائز"#)
    static let howToRegex = try! NSRegularExpression(
        pattern: #"(?i)\b(how (do|to|should|can|does) (i|we|you|one|a muslim|someone|people)? ?(pray|perform|make|do|fast|give|calculate|wash|clean|say|recite|read|memorize|memorise|learn|start|prepare|repent|convert|become|sit|stand|prostrate|bury|wrap|slaughter|pay|combine|shorten|catch up|make up)|steps (of|to|for)|the (right|correct|proper) way|how is .* (done|performed|prayed)|what are the steps|how many rakah|how many rakat|what is the procedure|guide to|walk me through)\b"#)
    static let storyRegex = try! NSRegularExpression(
        pattern: #"(?i)\b(story of|the story|tell me about|what happened (to|at|in|during|when)|history of|life of|biography|who was|who were|battle of|the battle|life story|how did .* (die|live|become)|what did .* do|birth of|death of|childhood|the night of|the year of|isra|miraj|hijrah|hijra|migration|the flood|the ark)\b"#)
    static let scriptureRegex = try! NSRegularExpression(
        pattern: #"(?i)\b(quran say|quran says|quran teach|quran teaches|quran mention|quran mentions|does the quran|in the quran|hadith say|hadith says|hadiths say|sunnah say|islam say|islam says|islam teach|does islam|in islam|verse about|verses about|ayah about|ayahs about|ayat about|hadith about|hadiths about|what does .* say about|evidence for|evidence of|proof of|proof for|daleel|dalil|reward of|reward for|virtue of|virtues of|benefits of|importance of|punishment for|punishment of|rights of|the right of|duty of|duties of|status of|about (patience|prayer|charity|fasting|marriage|parents|death|paradise|hell|forgiveness|repentance|mercy|justice|knowledge|wealth|women|men|children|orphans|neighbou?rs|anger|envy|pride|gratitude|trust|hope|fear|love|sabr|salah|zakat|sawm|hajj|tawhid|shirk|jannah|jahannam|tawbah|iman|taqwa|ihsan|dua|dhikr))\b"#)
    static let defineRegex = try! NSRegularExpression(
        pattern: #"(?i)^(what (is|are|was|were) (a |an |the )?|whats (a |an |the )?|what does .* mean|meaning of|define|definition of|who (is|are) (the )?|explain (what|the meaning|the term|the concept)|what do (you|we|muslims) mean by|what is meant by|tell me what)"#)
    static let referenceRegex = try! NSRegularExpression(
        pattern: #"(?i)(?<![\d:])\d{1,3}\s*:\s*\d{1,3}(?![\d:])|\b(surah|surat|soorah|sura|chapter)\s+(?:[\p{L}'’\-]+|\d{1,3}\b)|\b(ayah|ayat|aya|verse)\s+\d{1,3}\b|\bayat?u?l?[ -]?kursi\b|\bthrone verse\b|\bverse of (the )?(throne|light)\b|\bal[- ][a-z]+ (verse|ayah|surah)\b"#)
    static let recapRegex = try! NSRegularExpression(
        pattern: #"^(summari[sz]e|sum up|tldr|tl;dr|shorter|simpler|simplify|in short|briefly|make (it|that) (shorter|simpler|brief)|say (that|it) again|repeat that|rephrase|reword|explain (that|it) again|(can|could) you (summari[sz]e|simplify|shorten|rephrase))\b"#)
    /// About the previous answer's sources. The narrator forms need a back-reference ("who
    /// narrated THAT"): "Who narrated the hadith of Jibril?" is a new question, and used to be
    /// answered from the previous turn's sources.
    static let sourceQuestionRegex = try! NSRegularExpression(
        pattern: #"(?i)\b(who (narrated|reported|related|transmitted) (that|this|it|them|those)\b|who (is|was) the narrator\b(?! of (?!(that|this|it)\b))|narrators? of (that|this|it)\b|(that|this|it) (was |is )?(narrated|reported) by|which (book|collection|surah|chapter|hadith|verse|ayah) (is|was|does|did) (that|this|it)|which (book|collection|surah) (is|was) (that|it) (from|in)|where (is|was|does|did) (that|this|it) (from|come from|found|mentioned|appear)|whats the source|what is the source|source of (that|this|it)|is (that|this|it) (sahih|authentic|weak|daif|da'if|hasan|reliable|graded)|grade of (that|this|it)|what grade|how (authentic|reliable) is (that|this|it)|reference for (that|this|it)|what surah is that|what surah was that|which surah was that|what hadith (is|was) that|cite (that|this|it)|the citation)\b"#)

    // MARK: Times of day

    /// "11:30", "4:45 PM": an hour and two-digit minutes, the shape a verse reference shares.
    private static let clockCandidateRegex = try! NSRegularExpression(pattern: #"(?<![\d:])(?:[01]?\d|2[0-3])\s*:\s*[0-5]\d(?![\d:])"#)
    private static let meridiemRegex = try! NSRegularExpression(pattern: #"(?i)\A\s*[ap]\.?\s?m\b"#)
    private static let timePrepositionRegex = try! NSRegularExpression(pattern: #"(?i)\b(?:at|by|until|till|til|around)\s*\z"#)

    /// The text with every time of day blanked to spaces (UTF-16 length kept, so a range found in
    /// the result indexes the original). A time is h:mm followed by am/pm, or after "at", "by",
    /// "until" or "around", or anywhere in a message that names a prayer ("is 11:30 too late for
    /// isha"); "prayer" alone needs a clock word too, because "what does 2:45 say about prayer"
    /// names a verse.
    static func maskingClockTimes(_ text: String) -> String {
        let ns = text as NSString
        let matches = clockCandidateRegex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return text }
        let words = Set(fold(text).split(separator: " ").map(String.init))
        let namesPrayer = !words.isDisjoint(with: prayerNames)
        let prayerWithClock = !words.isDisjoint(with: prayerGeneral) && !words.isDisjoint(with: clockWords)
        let result = NSMutableString(string: text)
        for match in matches {
            let after = ns.substring(from: match.range.location + match.range.length)
            let before = ns.substring(to: match.range.location)
            let meridiem = meridiemRegex.firstMatch(in: after, range: NSRange(location: 0, length: (after as NSString).length)) != nil
            let preposition = timePrepositionRegex.firstMatch(in: before, range: NSRange(location: 0, length: (before as NSString).length)) != nil
            guard meridiem || preposition || namesPrayer || prayerWithClock else { continue }
            result.replaceCharacters(in: match.range, with: String(repeating: " ", count: match.range.length))
        }
        return result as String
    }

    static let followUpStarters = [
        "and ", "but ", "so ", "then ", "also ", "what about", "how about", "why", "more ", "more?", "elaborate", "expand",
        "explain that", "explain this", "explain it", "explain more", "tell me more", "give me more", "another", "again",
        "in arabic", "in english", "shorter", "simpler", "simplify", "summarize", "summarise", "example", "examples",
        "continue", "go on", "what else", "anything else", "which one", "the first", "the second", "the last", "that one",
        "this one", "can you", "could you", "ok ", "okay ", "really", "are you sure", "is that", "was that", "does that",
        "did that", "do they", "did he", "does he", "did she", "does it", "is it", "was it", "and the", "what did",
        "meaning", "translate", "translation", "show me", "in more detail", "in detail", "briefly", "in short",
    ]
    static let backReferences: Set<String> = [
        "it", "that", "this", "those", "these", "he", "she", "they", "him", "her", "them", "its", "his", "their",
        "one", "same", "above", "previous", "earlier", "last",
    ]

    // MARK: Synonyms across English and Arabic terms

    /// Each word and the words it also searches as, both ways. Kept to plain, common pairs: the
    /// lanes score the mean over query words, so a wrong expansion costs more than a missing one.
    private static let synonymPairs: [(String, [String])] = [
        ("patience", ["sabr", "patient", "perseverance", "endurance"]),
        ("prayer", ["salah", "salat", "namaz", "pray"]),
        ("charity", ["zakat", "zakah", "sadaqah", "alms", "giving"]),
        ("fasting", ["sawm", "siyam", "fast", "ramadan"]),
        ("pilgrimage", ["hajj", "umrah"]),
        ("bath", ["ghusl", "purification"]),
        ("faith", ["iman", "belief", "believe"]),
        ("oneness", ["tawhid", "tawheed", "monotheism"]),
        ("polytheism", ["shirk", "idolatry", "idols"]),
        ("paradise", ["jannah", "heaven", "garden"]),
        ("hell", ["jahannam", "hellfire", "fire"]),
        ("supplication", ["dua", "invocation", "supplicate"]),
        ("remembrance", ["dhikr", "adhkar", "zikr", "remember"]),
        ("repentance", ["tawbah", "repent", "forgiveness", "istighfar"]),
        ("forgiveness", ["forgive", "forgiving", "pardon", "maghfirah"]),
        ("marriage", ["nikah", "marry", "married", "spouse", "wedding"]),
        ("divorce", ["talaq", "divorced"]),
        ("funeral", ["janazah", "burial", "death", "dead"]),
        ("death", ["dying", "die", "died", "grave"]),
        ("interest", ["riba", "usury"]),
        ("modesty", ["haya", "hijab", "modest"]),
        ("parents", ["mother", "father", "parent"]),
        ("kindness", ["kind", "gentleness", "ihsan", "goodness"]),
        ("mercy", ["merciful", "rahmah", "compassion"]),
        ("anger", ["angry", "rage", "temper"]),
        ("gratitude", ["shukr", "thankful", "grateful", "thanks"]),
        ("trust", ["tawakkul", "reliance", "rely"]),
        ("piety", ["taqwa", "righteousness", "righteous", "fear of allah"]),
        ("sincerity", ["ikhlas", "sincere"]),
        ("hypocrisy", ["nifaq", "hypocrite", "hypocrites"]),
        ("angels", ["angel", "malaikah", "jibril", "gabriel"]),
        ("satan", ["shaytan", "iblis", "devil", "devils"]),
        ("judgment", ["qiyamah", "resurrection", "hereafter", "akhirah", "judgement", "last day"]),
        ("destiny", ["qadar", "fate", "decree", "predestination"]),
        ("messenger", ["rasul", "nabi", "prophethood"]),
        ("migration", ["hijrah", "hijra", "emigrate"]),
        ("companions", ["sahabah", "sahaba", "companion"]),
        ("friday", ["jumuah", "jummah", "jumu'ah"]),
        ("night prayer", ["tahajjud", "qiyam"]),
        ("travel", ["traveller", "traveler", "journey", "safar", "travelling"]),
        ("sick", ["illness", "ill", "disease", "sickness"]),
        ("knowledge", ["ilm", "learning", "learn", "seeking knowledge"]),
        ("honesty", ["truthfulness", "truthful", "honest", "sidq"]),
        ("lying", ["lies", "liar", "falsehood", "lie"]),
        ("backbiting", ["gheebah", "ghibah", "gossip", "slander"]),
        ("neighbor", ["neighbour", "neighbors", "neighbours"]),
        ("orphan", ["orphans", "yateem"]),
        ("poor", ["poverty", "needy", "miskeen", "destitute"]),
        ("wealth", ["money", "rizq", "provision", "rich"]),
        ("alcohol", ["khamr", "intoxicants", "wine", "drinking"]),
        ("gambling", ["maysir", "betting", "lottery"]),
        ("clothing", ["dress", "clothes", "garment", "awrah"]),
        ("women", ["woman", "wife", "wives", "female"]),
        ("men", ["man", "husband", "male"]),
        ("children", ["child", "kids", "son", "daughter"]),
        ("mosque", ["masjid", "mosques"]),
        ("kaaba", ["ka'bah", "kabah", "qibla", "makkah", "mecca"]),
        ("madinah", ["medina", "madina"]),
        ("jerusalem", ["aqsa", "al-aqsa", "quds"]),
        ("jesus", ["isa", "eesa", "messiah"]),
        ("moses", ["musa"]),
        ("abraham", ["ibrahim"]),
        ("noah", ["nuh"]),
        ("joseph", ["yusuf"]),
        ("mary", ["maryam"]),
        ("jonah", ["yunus"]),
        ("david", ["dawud", "dawood"]),
        ("solomon", ["sulayman", "sulaiman"]),
        ("jacob", ["yaqub"]),
        ("job", ["ayyub"]),
        ("adam", ["hawwa", "eve"]),
        ("muhammad", ["messenger", "rasulullah"]),
        ("jihad", ["struggle", "striving", "fighting"]),
        ("justice", ["adl", "fairness", "just", "fair"]),
        ("oppression", ["zulm", "injustice", "oppress", "tyranny"]),
        ("envy", ["hasad", "jealousy", "jealous"]),
        ("pride", ["kibr", "arrogance", "arrogant", "proud"]),
        ("humility", ["humble", "tawadu", "modest"]),
        ("love", ["mahabbah", "beloved", "loving"]),
        ("hope", ["raja", "hopeful"]),
        ("fear", ["khawf", "afraid"]),
        ("dreams", ["dream", "ruya", "vision"]),
        ("sleep", ["sleeping", "bed", "night"]),
        ("hardship", ["difficulty", "trial", "trials", "test", "tests", "calamity", "affliction", "suffering", "adversity"]),
        ("ease", ["relief", "comfort"]),
        ("anxiety", ["worry", "stress", "depression", "sadness", "grief", "sorrow", "distress"]),
        ("intention", ["niyyah", "intentions"]),
        ("cleanliness", ["purity", "taharah", "clean"]),
        ("food", ["eating", "eat", "meal", "halal food"]),
        ("water", ["drink", "drinking"]),
        ("manners", ["adab", "etiquette", "character", "akhlaq"]),
        ("truth", ["haqq"]),
        ("light", ["nur", "noor"]),
        ("guidance", ["hidayah", "guide", "guided"]),
        ("worship", ["ibadah", "ibadat", "obedience"]),
        ("sin", ["sins", "sinning", "dhanb", "wrongdoing"]),
        ("reward", ["ajr", "thawab", "rewards"]),
        ("punishment", ["adhab", "torment", "punish"]),
        ("brotherhood", ["brother", "brothers", "ummah", "unity"]),
        ("wisdom", ["hikmah", "wise"]),
        ("shahada", ["shahadah", "testimony", "declaration of faith"]),
        ("names of allah", ["asma", "asma ul husna", "beautiful names"]),
        ("recitation", ["recite", "tilawah", "tajweed", "reading quran"]),
        ("memorization", ["memorize", "memorise", "hifz", "hafiz"]),
        ("eid", ["festival", "celebration"]),
        ("sacrifice", ["qurbani", "udhiyah"]),
        ("moon", ["hilal", "crescent", "moon sighting"]),
        ("music", ["singing", "musical instruments", "instruments", "song", "songs", "singer"]),
        ("smoking", ["tobacco", "cigarettes", "cigarette", "vaping"]),
        ("tattoo", ["tattoos", "tattooing"]),
        ("dog", ["dogs", "puppy"]),
        ("pork", ["swine", "pig", "pigs"]),
        ("pictures", ["images", "photos", "photographs", "image", "picture"]),
        ("beard", ["shaving", "shave"]),
        ("birthday", ["birthdays", "celebrating"]),
        ("gold", ["jewellery", "jewelry", "silver"]),
        ("perfume", ["fragrance", "scent"]),
        ("menstruation", ["period", "menses", "haid"]),
        ("prayer times", ["salah times", "timetable"]),
        ("ablution", ["wudu", "wudhu", "wudoo"]),
    ]

    private static let synonyms: [String: [String]] = {
        var table: [String: [String]] = [:]
        for (head, related) in synonymPairs {
            let group = [head] + related
            for word in group {
                let key = fold(word)
                for other in group where fold(other) != key {
                    table[key, default: []].append(fold(other))
                }
            }
        }
        return table
    }()

    /// The terms with up to two synonyms apiece appended (unique, order kept).
    static func expand(_ terms: [String]) -> [String] {
        var out: [String] = []
        var seen = Set<String>()
        for term in terms where seen.insert(term).inserted { out.append(term) }
        for term in terms {
            for related in (synonyms[term] ?? []).prefix(2) where seen.insert(related).inserted {
                out.append(related)
            }
        }
        // A two-word phrase in the table ("night prayer", "names of allah") is looked up whole too.
        let joined = terms.joined(separator: " ")
        for (head, _) in synonymPairs where head.contains(" ") && joined.contains(head) {
            for related in (synonyms[fold(head)] ?? []).prefix(2) where seen.insert(related).inserted {
                out.append(related)
            }
        }
        return out
    }
}

#endif
