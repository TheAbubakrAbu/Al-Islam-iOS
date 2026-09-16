#if os(iOS)
import SwiftUI

// The colour legend behind thematic highlighting, ported from Tilawa's theme colour guide (Jamil
// Hammoudeh, with permission): seven MEANINGFUL colours, one per family of subject, so a wash in the
// reader says what a passage is about before a word of it is read (`ThemeWashColor` names them).
//
// Two classifiers, both Tilawa's. A topic (Browse by Theme) is matched by keyword against its name,
// description, domain and category, in a fixed priority order that lets the narrow meanings (Hellfire,
// rulings) win over the broad catch-all (the signs of Allah). A surah passage is scored against
// bilingual patterns over its English and Arabic titles, then a pass over the whole surah keeps
// neighbouring passages from wearing the same colour by accident while letting a run of Musa
// passages stay yellow on purpose.

enum ThemeColorGuide {
    // MARK: Topics

    /// Checked in this order: the first meaning with a keyword in the topic's text wins.
    private static let topicPriority: [ThemeWashColor] = [.hell, .law, .afterlife, .stories, .prophets, .quran, .signs]

    private static let topicKeywords: [ThemeWashColor: [String]] = [
        .signs: ["allah", "god", "oneness", "monotheism", "tawhid", "evidence", "sign", "signs", "proof", "power",
                 "majesty", "creation", "creator", "heavens", "earth", "mercy", "grace", "blessing", "divine", "lord",
                 "رب", "الله", "قدرة", "وحدانية", "آيات", "دلائل", "خلق", "رحمة"],
        .prophets: ["prophet's", "prophet", "muhammad", "messenger's", "attributes", "character", "ethics", "akhlaq",
                    "believer", "believers", "reward", "honor", "honors", "paradise", "garden", "jannah", "heaven",
                    "righteous", "success", "salvation", "peace and blessings",
                    "النبي", "صفات", "أخلاق", "مؤمن", "مؤمنين", "ثواب", "جنة", "الصالحين"],
        .law: ["law", "legal", "ruling", "rulings", "ahkam", "obligatory", "halal", "haram", "prayer", "fasting",
               "zakat", "hajj", "marriage", "divorce", "inheritance", "contract", "transaction", "witness", "hudud",
               "criminal", "commands", "prohibitions",
               "أحكام", "حلال", "حرام", "صلاة", "زكاة", "صيام", "حج", "نكاح", "طلاق", "ميراث", "حدود", "معاملات"],
        .stories: ["story", "stories", "messenger", "messengers", "prophet", "prophets", "musa", "moses", "ibrahim",
                   "abraham", "isa", "jesus", "nuh", "noah", "yusuf", "joseph", "lut", "hud", "salih", "shuayb",
                   "dawud", "sulayman", "miracle", "miracles", "seerah", "previous nations", "former nations",
                   "children of israel",
                   "قصص", "رسل", "أنبياء", "موسى", "إبراهيم", "عيسى", "نوح", "يوسف", "معجزات", "أمم"],
        .quran: ["quran", "qur'an", "book", "revelation", "scripture", "verses", "human", "mankind", "denial", "deny",
                 "reject", "arrogance", "false accusations", "accusation", "polytheist", "polytheists", "disbeliever",
                 "disbelievers", "hypocrite", "hypocrites", "sunnah of allah", "status", "guidance",
                 "قرآن", "وحي", "كتاب", "إنسان", "كفر", "تكذيب", "استكبار", "مشركين", "منافقين", "هداية"],
        .afterlife: ["resurrection", "judgment", "judgement", "day of judgment", "day of resurrection", "hour",
                     "last day", "hereafter", "akhirah", "reckoning", "account", "death", "grave", "warning", "warn",
                     "punishment", "fate", "inevitable", "doom",
                     "قيامة", "آخرة", "ساعة", "حساب", "موت", "قبر", "إنذار", "عقاب"],
        .hell: ["hell", "fire", "jahannam", "torment", "severe punishment", "wrath", "curse", "cursed", "blazing",
                "النار", "جهنم", "عذاب", "لعنة", "غضب"],
    ]

    private static let topicLock = NSLock()
    private static var topicMemo: [String: ThemeWashColor] = [:]

    /// The meaning a topic's text lands on, memoized by topic id (Browse by Theme asks per row).
    static func color(for topic: ThemeTopic) -> ThemeWashColor {
        color(forTopicNamed: topic.name, id: topic.id, extra: [topic.description, topic.domain, topic.category])
    }

    /// The same match from a name alone: a lit theme saved before the legend carries only its name.
    static func color(forTopicNamed name: String, id: String, extra: [String] = []) -> ThemeWashColor {
        topicLock.lock()
        if let memo = topicMemo[id] { topicLock.unlock(); return memo }
        topicLock.unlock()
        let haystack = normalize(([name] + extra).joined(separator: " "))
        // Latin keywords match whole words or phrases: Tilawa's substring test lit "Shirk" orange
        // because "grave" sits inside "gravest". Arabic keywords still match anywhere, since the
        // article and the conjunctions are written onto the word (والصلاة carries صلاة).
        let padded = " " + haystack.replacingOccurrences(of: "[^\\p{L}\\p{N}']+", with: " ", options: .regularExpression) + " "
        var result: ThemeWashColor = .signs
        for candidate in topicPriority {
            let hit = topicKeywords[candidate, default: []].contains { keyword in
                let folded = normalize(keyword)
                if folded.unicodeScalars.allSatisfy({ $0.isASCII }) {
                    return padded.contains(" " + folded + " ")
                }
                return haystack.contains(folded)
            }
            if hit {
                result = candidate
                break
            }
        }
        topicLock.lock()
        topicMemo[id] = result
        topicLock.unlock()
        return result
    }

    /// Tilawa's normalisation: decomposed, combining marks dropped, lowercased. `folding` also strips
    /// Arabic tashkeel, which the keywords never carry, so a vocalised title still matches.
    private static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Passages

    /// One matching pattern counts for two, which is what Tilawa's `match(...).length` returned (the
    /// hit plus its one capture group), so a single hit already clears `strongMatch`.
    private static let strongMatch = 2.0

    private static let sectionPatterns: [ThemeWashColor: [NSRegularExpression]] = {
        let sources: [ThemeWashColor: [String]] = [
            .hell: [
                #"\b(hell|hellfire|jahannam|torment|blazing|hellbound|damned|inferno)\b"#,
                #"(جهنم|سعير|لظى|حطمة|عذاب\s*شديد|نار\s*جهنم|لعنة\s*الله)"#,
            ],
            .afterlife: [
                #"\b(resurrection|judgment|judgement|reckoning|hereafter|akhirah|grave|day of judg|last day|the hour|doomsday|day of resurrection|warning|warned|punishment|fate of|end times|final|day of reckoning)\b"#,
                #"(قيامة|آخرة|الساعة|البعث|الحساب|محشر|قبر|عاقبة|إنذار|يوم\s*الدين|يوم\s*القيامة)"#,
            ],
            .law: [
                #"\b(law|laws|legal|ruling|rulings|ahkam|halal|haram|prayer|salah|fasting|sawm|zakat|hajj|marriage|divorce|inheritance|contract|covenant|witness|hudud|qiblah|jihad|prohibition|prohibitions|obligation|obligations|injunction|injunctions|command|commandments|practice|practices|duty|duties|matters of|rules of|regulations|detailed laws|detailed rulings|fiqh|sharia|shari'a|sharī'a|legislation)\b"#,
                #"(أحكام|حلال|حرام|صلاة|زكاة|صيام|حج|نكاح|طلاق|ميراث|حدود|معاملات|قبلة|واجب|فريضة|تشريع|فقه|شريعة|أوامر)"#,
            ],
            .stories: [
                #"\b(musa|moses|ibrahim|abraham|isa|jesus|nuh|noah|yusuf|joseph|lut|lot|hud|salih|shu['’]?ayb|dawud|david|sulayman|solomon|adam|harun|aaron|yunus|jonah|zakariyya|yahya|maryam|mary|dhul[- ]?qarnayn|khidr|bani[- ]israel|children of israel|pharaoh|fir['’]?awn|the cave|companions of the|story of|stories of|tale of|prophets of|messengers of|miracle|miracles|seerah|of old|previous nations|former nations|earlier nations|the jews|the christians|polytheists of mecca|parable of|two gardens|two sons|the elephant|the people of)\b"#,
                #"(موسى|إبراهيم|عيسى|نوح|يوسف|لوط|هود|صالح|شعيب|داود|سليمان|آدم|هارون|يونس|زكريا|يحيى|مريم|ذو\s*القرنين|بني\s*إسرائيل|فرعون|قصة|قصص|أهل\s*الكهف|أمم\s*سابقة|أصحاب\s*الفيل|أصحاب\s*السبت)"#,
            ],
            .prophets: [
                #"\b(the prophet|prophet muhammad|the messenger|messenger of allah|messenger of god|believers|the believers|the muslims|the muslim ummah|righteous|the righteous|piety|piousness|paradise|gardens of|gardens beneath|jannah|reward of|reward for|honor of|character of the|attributes of believers|ethics|akhlaq|taqwa|patience|charity|brotherhood|ummah|foundations of the muslim|leadership of the ummah|salvation|success of believers|saved|peace and blessings)\b"#,
                #"(النبي|الرسول|محمد|المؤمنين|أهل\s*الإيمان|الصالحين|تقوى|الجنة|جنات|ثواب|أخلاق|صبر|إيمان|فلاح|أمة\s*الإسلام|أهل\s*التقوى)"#,
            ],
            .quran: [
                #"\b(qur['’]?an|quran|revelation|the book|scripture|denial|deny|deniers|reject|rejecters|rejection|arrogance|arrogant|haughty|hypocrite|hypocrites|hypocrisy|polytheist|polytheists|polytheism|disbeliever|disbelievers|disbelief|opposition|opponents|enemies of|stubbornness|stubborn|mocking|disputing|dispute|debate|argument with|opposition to|rebellion against|response of|responses of|reproof|reminder and reproof)\b"#,
                #"(قرآن|الكتاب|وحي|تكذيب|إنكار|استكبار|كبر|منافقين|نفاق|مشركين|شرك|كافرين|كفر|عناد|جدال|خصومة|تهكم|استهزاء|إعراض)"#,
            ],
            .signs: [
                #"\b(signs of|sign of|creation|creator|the heavens|the earth|sky|skies|stars|sun|moon|night and day|rain|wind|winds|mountains|seas|oceans|animals|birth|death and life|cosmos|universe|wonders|reflection|reflect on|consider|ponder|oneness|tawhid|monotheism|divine power|divine signs|mercy of allah|mercy of god|grace|blessing|blessings|favors of|bounties of|praise|praise and|glorify|glorification|tasbih|stewardship|guidance and stewardship|surah overview|overview)\b"#,
                #"(آيات\s*الله|دلائل|خلق|السماء|الأرض|كواكب|الشمس|القمر|الليل|النهار|جبال|البحار|توحيد|وحدانية|رحمة|نعمة|نعم|فضل|حمد|تسبيح|استخلاف)"#,
            ],
        ]
        var compiled: [ThemeWashColor: [NSRegularExpression]] = [:]
        for (color, patterns) in sources {
            compiled[color] = patterns.compactMap { try? NSRegularExpression(pattern: $0, options: [.caseInsensitive]) }
        }
        return compiled
    }()

    private struct Classification {
        var id: ThemeWashColor
        var topScore: Double
        var scores: [ThemeWashColor: Double]
    }

    private static func classify(_ section: SurahSection) -> Classification {
        let haystack = [section.title, section.titleArabic].filter { !$0.isEmpty }.joined(separator: " ")
        let range = NSRange(haystack.startIndex..., in: haystack)
        var scores: [ThemeWashColor: Double] = [:]
        for (color, patterns) in sectionPatterns {
            var score = 0.0
            for pattern in patterns where pattern.firstMatch(in: haystack, range: range) != nil {
                score += strongMatch
            }
            if score > 0 { scores[color] = score }
        }
        if let best = scores.max(by: { a, b in a.value < b.value || (a.value == b.value && a.key.rawValue > b.key.rawValue) }) {
            return Classification(id: best.key, topScore: best.value, scores: scores)
        }
        // No semantic hit at all: rotate through the legend by position, so the passage still gets a
        // stable colour distinct from its neighbours (Tilawa's baked-in colour index; the pack here
        // carries the passage's place in the surah instead, which serves the same purpose).
        let palette = ThemeWashColor.allCases
        return Classification(id: palette[((section.order % palette.count) + palette.count) % palette.count], topScore: 0, scores: scores)
    }

    private static func secondBest(_ scores: [ThemeWashColor: Double], excluding excluded: ThemeWashColor) -> ThemeWashColor? {
        var bestID: ThemeWashColor?
        var bestScore = 0.0
        for (id, score) in scores where id != excluded && score > bestScore {
            bestScore = score
            bestID = id
        }
        return bestID
    }

    private static func rotationalFallback(excluding excluded: ThemeWashColor, section: SurahSection) -> ThemeWashColor {
        let palette = ThemeWashColor.allCases
        let seed = (((section.order + 1) % palette.count) + palette.count) % palette.count
        for step in 0..<palette.count {
            let candidate = palette[(seed + step) % palette.count]
            if candidate != excluded { return candidate }
        }
        return excluded
    }

    /// The colour of every passage in one surah, keyed by `SurahSection.id`. Pure; the store memoizes it.
    static func colors(forSections sections: [SurahSection]) -> [String: ThemeWashColor] {
        var classifications = sections.map(classify)

        // Neighbour inheritance: a passage with no semantic hit that sits between two strong, agreeing
        // neighbours almost always belongs to that same theme. Surah 12's "His Brothers Plot Against
        // Him" names no prophet but is unmistakably part of the Yusuf narrative; the neighbours prove it.
        for index in classifications.indices where classifications[index].topScore == 0 {
            let left = index > 0 ? classifications[index - 1] : nil
            let right = index + 1 < classifications.count ? classifications[index + 1] : nil
            let leftStrong = left.flatMap { $0.topScore >= strongMatch ? $0.id : nil }
            let rightStrong = right.flatMap { $0.topScore >= strongMatch ? $0.id : nil }
            if let leftStrong, leftStrong == rightStrong {
                classifications[index].id = leftStrong
                classifications[index].topScore = strongMatch
            }
        }

        var result: [String: ThemeWashColor] = [:]
        var previous: ThemeWashColor?
        for (index, section) in sections.enumerated() {
            let classification = classifications[index]
            var color = classification.id
            // Adjacency dedup applies only to weak matches. Strong semantic matches are preserved so a
            // recurring theme stays consistent across passages.
            if color == previous, classification.topScore < strongMatch {
                color = secondBest(classification.scores, excluding: color) ?? rotationalFallback(excluding: color, section: section)
            }
            result[section.id] = color
            previous = color
        }
        return result
    }
}

// MARK: - The legend

/// The seven meanings as a two-column grid of tinted tiles: the colour bar, its name, what it means,
/// and Tilawa's line about it. The Highlight Themes screen shows it; any screen that paints the washes
/// can.
struct ThemeColorLegend: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(ThemeWashColor.allCases) { color in
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Capsule()
                            .fill(color.color)
                            .frame(width: 22, height: 4)

                        Text(color.name.capitalized)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(color.color)
                    }

                    Text(color.meaning)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(color.legendDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.color.opacity(0.12))
                )
            }
        }
    }
}
#endif
