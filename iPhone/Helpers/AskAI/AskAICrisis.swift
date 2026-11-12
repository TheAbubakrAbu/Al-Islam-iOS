import Foundation

// A first-person expression of suicidal intent or self-harm is not a question for the library.
// The app answers it itself: no model, no retrieval, a help line for the reader's region, and
// nothing kept as conversation history (the next question must not be grounded on this turn).
// A question ABOUT suicide ("Is suicide haram?") is still a question; it only earns the help line
// beneath its normal, sourced answer.

#if os(iOS)

enum AskAICrisis {
    /// The shapes of a first-person crisis, matched on the FOLDED text (lowercased, apostrophes
    /// removed, so "dont" and "cant" are the spellings). Shapes that also fit a question about the
    /// subject ("commit suicide", "self harm", "going to die") need a first-person subject within a
    /// few words before them; "want to die" followed by "as", "in", "while", "on", "a", "for" is a
    /// question about dying ("I want to die as a Muslim"); "cut myself" followed by "shaving" or
    /// "hurt myself during" is an accident; "cant go on" followed by a noun is a trip.
    private static let crisisRegex = try! NSRegularExpression(pattern: #"""
        (?ix)
        \b(end|ending|take|taking)\ my\ (own\ )?life\b
        | \bkill(ing)?\ myself\b
        | \b(want\ to|wanna|wanting\ to)\ die\b(?!\ (as|in|while|on|a|for)\b)
        | \bi(m|\ am)?\ (am\ )?going\ to\ die\b(?!\ (as|in|while|on|a|for|one\ day|someday|eventually)\b)
        | \b(dont|do\ not|cant|cannot)\ want\ to\ (live|be\ alive|be\ here)\b
        | \bno\ reason\ to\ live\b
        | \bbetter\ off\ dead\b
        | \bwish\ i\ (was|were)\ dead\b
        | \b(hurt|hurting|harm|harming)\ myself\b(?!\ (during|while|in|on|at|by|with|doing)\b)
        | \b(cut|cutting)\ myself\b(?!\ (shaving|while|during|by|with|on|accidentally)\b)
        | \bi(m|ve|\ am|\ have|\ have\ been|\ was)?\ (been\ )?self\ ?harm(ing|ed)?\b
        | \b(im|i\ am|i\ feel|feeling|been|being)\ suicidal\b
        | \bi(m|ve|\ am|\ have|\ want\ to|\ will|\ might|\ keep)?\ (been\ |going\ to\ |gonna\ )?(commit|committing|thinking\ about|thoughts\ of|considering)\ suicide\b
        | \bend\ it\ all\b
        | \b(cant|cannot|can\ not)\ go\ on\b(?!\ (hajj|umrah|a|an|the|to|with|my|our|that|this|his|her|their|holiday|vacation|trips?|tours?)\b)
        """#)

    /// The same shapes in Arabic and Urdu, on the folded text: harakat gone, every hamza form a
    /// bare alif ("أريد" is "اريد"), so the patterns are written hamza-less. Arabic: "I want to
    /// die / kill myself / end my life", "I think about suicide", "I will commit suicide", "I do
    /// not want to live", "I wish for death", "I hurt myself"; a third person ("من قتل نفسه") or a
    /// "لا"/"ما" before "I want to die" is not that. Urdu: "I want to die", "want to commit
    /// suicide", "thinking about suicide", "do not want to live", "take my life", "kill myself",
    /// "hurt myself" (conjugated, so "is hurting oneself haram" stays a question), "feel like dying".
    private static let arabicUrduCrisisRegex = try! NSRegularExpression(pattern: #"""
        (?x)
        (?<!\bلا\s)(?<!\bما\s)\b(اريد|ابغى|ابي|بدي|عايز|عاوز|اتمنى)\s+(ان\s+|لو\s+)?(اموت|انتحر|اقتل\s+نفسي|انهي\s+حياتي|اؤذي\s+نفسي|اوذي\s+نفسي|اجرح\s+نفسي)\b
        | \b(س|سوف\s+|راح\s+|رح\s+)(انتحر|اقتل\s+نفسي|انهي\s+حياتي)\b
        | \bافكر\s+(في\s+|ب)?(ال)?(انتحار|قتل\s+نفسي|انهاء\s+حياتي)\b
        | \b(لا|ما|لم\s+اعد)\s+(اريد|ابغى|ابي|بدي)\s+(ان\s+)?(اعيش|احيا|الحياة|العيش)\b
        | \bاتمنى\s+(الموت|ان\s+اموت|لو\s+اموت)\b
        | \b(اؤذي|اوذي|اجرح|اضر|اعذب)\s+نفسي\b
        | \bمر(نا|\s+جانا)\s+چاہت[اىیے]\s+(ہوں|ہون)\b
        | \bم[یي]ں\s+(\S+\s+){0,3}مر(نا|\s+جانا)\s+چاہت[اىیے]\b
        | \bمرنے\s+(کو|کا)\s+دل\b
        | \bج[یي]نے\s+(کو|کا)\s+دل\s+نہ[یي]ں\b
        | \bخود\s?[کك]ش[یي]\s+(کرنا\s+چاہت|کر\s+لوں|کرنے\s+کا\s+سوچ|کے\s+بارے\s+م[یي]ں\s+سوچ)
        | \bزندہ\s+نہ[یي]ں\s+رہنا\s+چاہت[اىیے]\b
        | \bج[یي]نا\s+نہ[یي]ں\s+چاہت[اىیے]\b
        | \bاپن[یي]\s+(جان\s+(لینا|لے\s+لوں|لے\s+لینا|لے\s+لی)|زندگ[یي]\s+ختم\s+کر)
        | \bخود\s+کو\s+(مار(نا\s+چاہت|\s+لوں|\s+ڈالوں)|ختم\s+کر(نا\s+چاہت|\s+لوں|\s+دوں)|نقصان\s+پہنچا(ت[اىیے]|\s+رہ)|تکل[یي]ف\s+د(یت[اىیے]|ے\s+رہ)|کاٹت[اىیے]|زخم[یي]\s+کرت[اىیے])
        """#)

    private static let mentionRegex = try! NSRegularExpression(
        pattern: #"\bsuicid(e|al)\b|\bself\ ?harm(ing|ed)?\b|\bkills?\ (himself|herself|themselves|yourself|oneself)\b|\bkilling\ (himself|herself|themselves|yourself|oneself)\b"#)

    private static let arabicUrduMentionRegex = try! NSRegularExpression(
        pattern: #"\b(ال)?انتحار\b|\b[يی]نتحر\b|\bقتل\s+نفس[هة]\b|\b[يی]قتل\s+نفسه\b|\bخود\s?[کك]ش[یي]\b|\bخود\s+کو\s+(نقصان|تکل[یي]ف|مار|ختم)"#)

    static func isCrisis(_ raw: String) -> Bool {
        let folded = AskAILexicon.fold(raw)
        return matches(crisisRegex, folded) || matches(arabicUrduCrisisRegex, hamzaless(folded))
    }

    /// The text talks about suicide or self-harm without expressing it: a normal answer, with the
    /// help line beneath it.
    static func mentionsSelfHarm(_ raw: String) -> Bool {
        let folded = AskAILexicon.fold(raw)
        return (matches(mentionRegex, folded) || matches(arabicUrduMentionRegex, hamzaless(folded))) && !isCrisis(raw)
    }

    /// `fold` keeps the hamza forms (they are letters, not marks): "أريد", "إن" and "آ" become the
    /// bare alif, "ؤ" the waw and "ئ" the ya, so one spelling of each pattern covers them all.
    private static func hamzaless(_ text: String) -> String {
        var out = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x0623, 0x0625, 0x0622, 0x0671: out.append("\u{0627}")
            case 0x0624: out.append("\u{0648}")
            case 0x0626: out.append("\u{064A}")
            default: out.append(scalar)
            }
        }
        return String(out)
    }

    private static func matches(_ regex: NSRegularExpression, _ text: String) -> Bool {
        regex.firstMatch(in: text, range: NSRange(location: 0, length: (text as NSString).length)) != nil
    }

    /// The reply, written by the app. `citingEase` adds the sentence whose "[1]" is Quran 94:5: only
    /// when that verse is the first of `sources()` (the Quran ships with the app and has loaded).
    static func reply(citingEase: Bool) -> String {
        var text = String(localized: "I am really glad you told me. What you are feeling matters, and you deserve support right now from a person who can be with you. If you are in immediate danger, call your local emergency number.")
        text += " " + helpLine(regionCode: Locale.current.region?.identifier)
        text += " " + String(localized: "Please also reach out to someone you trust: a family member, a friend, or an imam.")
        if citingEase {
            text += " " + String(localized: "Allah knows what you are carrying, and He promises that with hardship comes ease [1].")
        }
        text += " " + String(localized: "You do not have to face this alone.")
        return text
    }

    /// The reply for the sources the app has right now.
    @MainActor static var reply: String {
        if case .ayah? = sources().first?.kind { return reply(citingEase: true) }
        return reply(citingEase: false)
    }

    /// A help line for the reader's region; the finder where no number has been confirmed. The
    /// number's digits follow the locale (the Arabic translation writes them Arabic-Indic).
    static func helpLine(regionCode: String?) -> String {
        helpLineText(regionCode: regionCode).localizedDigits
    }

    private static func helpLineText(regionCode: String?) -> String {
        switch regionCode?.uppercased() {
        case "US", "CA": return String(localized: "Call or text 988 (Suicide and Crisis Lifeline), any hour.")
        case "GB", "IE": return String(localized: "Call Samaritans on 116 123, free, any hour.")
        case "AU": return String(localized: "Call Lifeline on 13 11 14, any hour.")
        case "NZ": return String(localized: "Call or text 1737, any hour.")
        case "IN": return String(localized: "Call Tele-MANAS on 14416, any hour.")
        default: return String(localized: "You can find a free helpline for your country at findahelpline.com.")
        }
    }

    /// The number (or the finder) to open: what the help line says, as a thing to tap.
    static func helpLineAction(regionCode: String?) -> (label: String, url: URL)? {
        let pair: (String, String)
        switch regionCode?.uppercased() {
        case "US", "CA": pair = (String(localized: "Call 988"), "tel:988")
        case "GB", "IE": pair = (String(localized: "Call 116 123"), "tel:116123")
        case "AU": pair = (String(localized: "Call 13 11 14"), "tel:131114")
        case "NZ": pair = (String(localized: "Call 1737"), "tel:1737")
        case "IN": pair = (String(localized: "Call 14416"), "tel:14416")
        default: pair = (String(localized: "Find a helpline"), "https://findahelpline.com")
        }
        guard let url = URL(string: pair.1) else { return nil }
        return (pair.0.localizedDigits, url)
    }

    /// English like every other chip (a chip is a question for the model, which reads English);
    /// the Quran chip only where the Quran ships.
    static let suggestions: [String] = {
        var out = ["Is there a dua for anxiety and sorrow?"]
        #if HAS_QURAN
        out.append("What does the Quran say about hope?")
        #else
        out.append("What does Islam say about hope?")
        #endif
        return out
    }()

    /// [1] Quran 94:5, [2] the Hisn al-Muslim dua for anxiety and sorrow, whichever the app has
    /// loaded. An empty array is fine: the reply's markers are policed against the count.
    @MainActor static func sources() -> [AskAISource] {
        var out: [AskAISource] = []
        #if HAS_QURAN
        if let ease = AskAISourceFactory.ayah(surah: 94, ayah: 5, quranData: QuranData.shared) { out.append(ease) }
        #endif
        if let library = HisnDuasStore.shared.libraryIfLoaded,
           let entry = library.entries.first(where: {
               let title = AskAILexicon.fold($0.title)
               return title.contains("anxiety") && title.contains("sorrow")
           }),
           let category = library.categories.first(where: { $0.id == entry.categoryID }),
           let source = AskAISourceFactory.hisn(entry, category: category.label) {
            out.append(source)
        }
        return out
    }
}

#endif
