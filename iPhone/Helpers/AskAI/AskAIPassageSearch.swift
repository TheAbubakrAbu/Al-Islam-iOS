import Foundation

// Ask AI - finding a passage from a DESCRIPTION of it.
//
// "The verse about fathers killing their children out of shame" names no word of the verses it
// means: 16:58-59 say "informed of a female", "humiliation", "bury it in the ground", and 81:8-9
// "the girl buried alive". The search field's engine (`QuranRankedSearch`) scores the words as
// typed, and the meaning search averages word vectors, where "killing" sits nearest "shooting" and
// "shame" nearest "disgust": both answered with 7:141 (Pharaoh killing sons) and never reached the
// verses meant (Abu, 2026-11-25: "Google or ChatGPT would be able to find it").
//
// Asking the on-device model which verse it is was tried first and is no use: it answers with a
// confident reference and a quotation it made up ("Surah Al-Baqarah, verse 228: do not kill your
// children because of poverty; it is better for them to die than to be humiliated"). It can READ,
// though. So the app finds the candidates itself, and the model is handed more of them to read:
//
//   1. every word of the description is searched as a CONCEPT: itself and the words a translator
//      or a commentator might have used for the same thing (`AskAIWords.related`: shame, disgrace,
//      humiliation, dishonor; child, daughter, baby, infant, girl);
//   2. each ayah is scored on its two translations (BM25, so a rare word counts for more than a
//      common one), on its neighbours (a description often straddles two verses: the news of a
//      daughter is 16:58, burying her 16:59), on what the three English tafsirs say about it
//      (TafsirKeywords.bin, built by Scripts/build_tafsir_keywords.py), and on the topic index's
//      names for it (`QuranTopicsStore`: "burying daughters alive" lists 16:58-59);
//   3. concepts that sit together in the verse count for more than ones scattered through a long one.
//
// Measured on 40 described verses (2026-11-25, the list is in `AskAIPassageSearchTests`), with the
// same scoring run offline: the verse meant is the first result for 36 and among the first eight
// for all 40. Scored as typed words alone, with no concepts, neighbours, tafsir or topics, the same
// ranking gives 28 and 35.

#if os(iOS)

// MARK: - Words

/// The description search's own reading of English: a tokenizer, a small stemmer and a thesaurus of
/// concepts. Deliberately separate from `AskAILexicon` (whose synonyms name TOPICS: zakat, charity,
/// alms) and from the search field's stemmer (which also corrects spelling): this one must be the
/// same on both sides of the match, and nothing else.
enum AskAIWords {
    /// Words that carry no meaning in a text.
    static let stopWords: Set<String> = [
        "a", "an", "the", "and", "or", "of", "to", "in", "on", "at", "by", "for", "with", "from", "as", "is", "are", "was",
        "were", "be", "been", "being", "it", "its", "this", "that", "these", "those", "he", "she", "they", "them", "his",
        "her", "their", "you", "your", "we", "our", "i", "me", "my", "who", "whom", "whose", "which", "what", "when",
        "where", "why", "how", "do", "does", "did", "not", "no", "nor", "so", "if", "then", "than", "there", "here", "have",
        "has", "had", "will", "would", "shall", "should", "can", "could", "may", "might", "must", "about", "into", "out",
        "up", "down", "over", "under", "again", "also", "only", "very", "just", "one", "any", "all", "each", "some", "such",
        "both", "but", "because", "while", "him", "us", "s", "t", "d", "ll", "re", "ve", "m", "o",
    ]

    /// Words a QUESTION adds that describe the asking, not the passage.
    static let questionWords: Set<String> = [
        "verse", "verses", "ayah", "ayat", "ayahs", "aya", "quran", "quranic", "hadith", "hadiths", "hadeeth", "says",
        "say", "said", "saying", "talks", "talk", "talking", "story", "surah", "sura", "like", "given", "something",
        "other", "find", "looking", "remember", "mention", "mentions", "mentioned", "tell", "show", "passage", "chapter",
        "narration", "please", "know", "explain", "mean", "means", "there",
    ]

    private static let irregular: [String: String] = [
        "children": "child", "men": "man", "women": "woman", "wives": "wife", "slain": "slay", "slew": "slay",
        "buried": "bury", "burying": "bury", "killed": "kill", "killing": "kill", "feet": "foot", "daughters": "daughter",
        "sons": "son", "ate": "eat", "eaten": "eat", "eating": "eat", "spoke": "speak", "spoken": "speak",
        "speaking": "speak", "slept": "sleep", "sleeping": "sleep", "sleepers": "sleep", "told": "tell", "sent": "send",
        "brought": "bring", "took": "take", "taken": "take", "takes": "take", "gave": "give", "given": "give",
        "built": "build", "made": "make", "saw": "see", "seen": "see", "died": "die", "dies": "die", "dying": "die",
        "lives": "life", "knives": "knife", "wolves": "wolf", "forbade": "forbid", "forbidden": "forbid",
        "arrogantly": "arrogant", "arrogance": "arrogant", "fought": "fight", "wept": "weep", "stole": "steal",
        "stolen": "steal", "drank": "drink", "drunk": "drink", "fed": "feed", "led": "lead", "lost": "lose",
        "found": "find", "sold": "sell", "bought": "buy", "paid": "pay", "taught": "teach", "thieves": "thief",
        "prayed": "pray", "praying": "pray", "prayers": "pray", "prayer": "pray", "lying": "lie", "lied": "lie",
        "liars": "liar", "weakest": "weak", "weaker": "weak", "ashamed": "shame", "poverty": "poor",
    ]

    /// A word's stem: enough to bring "killing", "killed" and "kills" together, and no cleverer. A
    /// suffix is taken only from a word long enough to keep a stem of three letters, and a final
    /// "e" goes last, so "shade" and "shaded", "love" and "loving" meet.
    static func stem(_ word: String) -> String {
        let stem = suffixless(word)
        return stem.utf8.count > 3 && stem.hasSuffix("e") && !stem.hasSuffix("ee") ? String(stem.dropLast()) : stem
    }

    private static func suffixless(_ word: String) -> String {
        if let known = irregular[word] { return known }
        let count = word.utf8.count
        func dropping(_ n: Int) -> String { String(word.dropLast(n)) }
        func undoubled(_ base: String) -> String {
            let letters = Array(base.utf8)
            guard letters.count > 2, letters[letters.count - 1] == letters[letters.count - 2],
                  letters[letters.count - 1] != UInt8(ascii: "l"), letters[letters.count - 1] != UInt8(ascii: "s") else { return base }
            return String(base.dropLast())
        }
        if count > 4, word.hasSuffix("ies") { return dropping(3) + "y" }
        if count > 5, word.hasSuffix("ing") { return undoubled(dropping(3)) }
        if count > 4, word.hasSuffix("ed") { return undoubled(dropping(2)) }
        if count > 4, word.hasSuffix("ly") { return dropping(2) }
        if count > 3, word.hasSuffix("es"), let before = word.dropLast(2).last, "sxz".contains(before) { return dropping(2) }
        if count > 3, word.hasSuffix("s"), !word.hasSuffix("ss") { return dropping(1) }
        return word
    }

    /// The words of `text`, lower case and without their accents, an apostrophe's tail dropped
    /// ("brother's" is "brother"), in order. Not stemmed and nothing left out.
    static func words(_ text: String) -> [String] {
        var out: [String] = []
        var current: [UInt8] = []
        var skipping = false
        func close() {
            if !current.isEmpty { out.append(String(decoding: current, as: UTF8.self)) }
            current.removeAll(keepingCapacity: true)
            skipping = false
        }
        for scalar in text.unicodeScalars {
            let value = scalar.value
            if value < 128 {
                let byte = UInt8(value)
                if byte >= 97, byte <= 122 {
                    if !skipping { current.append(byte) }
                } else if byte >= 65, byte <= 90 {
                    if !skipping { current.append(byte + 32) }
                } else if byte == 39 {
                    skipping = !current.isEmpty
                } else {
                    close()
                }
            } else if value == 0x2019 || value == 0x02BC {
                skipping = !current.isEmpty
            } else if scalar.properties.generalCategory == .nonspacingMark {
                continue
            } else if let base = Self.unaccented[value] {
                if !skipping { current.append(base) }
            } else {
                close()
            }
        }
        close()
        return out
    }

    /// The accented Latin letters the translations and transliterations use, as their plain letter.
    private static let unaccented: [UInt32: UInt8] = {
        var table: [UInt32: UInt8] = [:]
        let rows: [(String, Character)] = [
            ("āáàâäãĀÁÀÂ", "a"), ("ēéèêëĒÉ", "e"), ("īíìîïĪÍ", "i"), ("ōóòôöõŌÓ", "o"), ("ūúùûüŪÚ", "u"),
            ("ḥḤ", "h"), ("ṣṢšŠ", "s"), ("ḍḌ", "d"), ("ṭṬ", "t"), ("ẓẒžŽ", "z"), ("ñ", "n"), ("çč", "c"), ("ğġ", "g"),
        ]
        for (letters, plain) in rows {
            for scalar in letters.unicodeScalars { table[scalar.value] = plain.asciiValue ?? 0 }
        }
        return table
    }()

    /// The stems of a text's meaning-carrying words, in order (a word may repeat).
    static func stems(_ text: String, dropping extra: Set<String> = []) -> [String] {
        words(text).compactMap { word in
            guard word.utf8.count > 1, !stopWords.contains(word), !extra.contains(word) else { return nil }
            return stem(word)
        }
    }

    /// The stems a description is searched by: its meaning-carrying words, numbers written out the
    /// way a translation writes them ("300 years" is "three hundred years"), each stem once.
    static func queryStems(_ question: String) -> [String] {
        var seen = Set<String>()
        return stems(spellingOutNumbers(in: question), dropping: questionWords).filter { seen.insert($0).inserted }
    }

    private static let digitRun = try! NSRegularExpression(pattern: #"(?<![\d:.])\d{1,4}(?![\d:.])"#)
    private static let ones = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven",
                               "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
    private static let tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]

    static func numberWords(_ n: Int) -> [String] {
        if n < 20 { return [ones[n]] }
        if n < 100 { return [tens[n / 10]] + (n % 10 == 0 ? [] : [ones[n % 10]]) }
        if n < 1_000 { return (n / 100 > 1 ? [ones[n / 100]] : []) + ["hundred"] + (n % 100 == 0 ? [] : numberWords(n % 100)) }
        if n < 10_000, n % 1_000 == 0 { return (n / 1_000 > 1 ? [ones[n / 1_000]] : []) + ["thousand"] }
        return []
    }

    /// "slept for 300 years" as "slept for three hundred years". A verse reference ("2:255") is left alone.
    static func spellingOutNumbers(in text: String) -> String {
        let ns = text as NSString
        var out = text
        for match in digitRun.matches(in: text, range: NSRange(location: 0, length: ns.length)).reversed() {
            guard let n = Int(ns.substring(with: match.range)) else { continue }
            let spelled = numberWords(n)
            guard !spelled.isEmpty, let range = Range(match.range, in: out) else { continue }
            out.replaceSubrange(range, with: spelled.joined(separator: " "))
        }
        return out
    }

    /// How much of a description a passage must carry to be offered as THE passage meant: three
    /// concepts of four, two of three, both of two. Less than that is a passage on the subject.
    static let confidentCoverage = 0.6

    /// How much two texts' stems have in common: the shared ones over the smaller text's. The same
    /// narration told in two collections is near 1; two narrations on one subject seldom pass a half.
    static func overlap(_ first: Set<String>, _ second: Set<String>) -> Double {
        let smaller = min(first.count, second.count)
        guard smaller > 0 else { return 0 }
        return Double(first.intersection(second).count) / Double(smaller)
    }

    /// The stems a stem is searched with: every other member of each concept it belongs to.
    static let related: [String: [String]] = {
        var table: [String: [String]] = [:]
        for line in concepts {
            let members = line.split(separator: ",").map { stem($0.trimmingCharacters(in: .whitespaces)) }
            for member in members {
                for other in members where other != member && !(table[member] ?? []).contains(other) {
                    table[member, default: []].append(other)
                }
            }
        }
        return table
    }()

    /// One concept a line: the words a reader, a translator or a commentator may use for the same
    /// thing. Kept tight (a loose line is noise in every search that touches it), and only words
    /// the translations or the tafsirs actually use are worth a place. A word may sit on several lines.
    static let concepts: [String] = [
        // People and family
        "father, dad, parent, forefather, sire",
        "mother, mom, parent",
        "parent, father, mother",
        "child, kid, offspring, son, daughter, baby, infant, boy, girl, progeny, descendant, newborn",
        "daughter, girl, female, baby",
        "son, boy, male",
        "baby, infant, newborn, cradle, suckling",
        "wife, spouse, mate, consort, bride",
        "husband, spouse, mate",
        "marry, marriage, wed, wedlock, nikah",
        "divorce, separate, talaq",
        "orphan, fatherless",
        "brother, sibling, brethren",
        "sister, sibling",
        "relative, kin, kinsman, kindred, kinship, family",
        "friend, companion, ally, comrade, intimate",
        "enemy, foe, adversary, opponent",
        "king, ruler, monarch, sovereign, chief, governor",
        "queen, sheba, ruler",
        "governor, minister, chief, aziz",
        "slave, servant, bondman, captive",
        "poor, needy, destitute, indigent, pauper",
        "rich, wealthy, affluent, wealth, riches",
        "traveler, wayfarer",
        "old, elderly, aged",
        "young, youth, lad",
        "man, person, human, mankind, people",
        "woman, female, lady",
        // Death and harm
        "kill, slay, murder, slaughter, massacre, execute, bury",
        "bury, burial, grave, entomb",
        "die, death, dead, perish, decease",
        "dead, corpse, lifeless, deceased, carcass, death",
        "grave, tomb, burial",
        "fight, battle, war, combat, warfare",
        "army, soldier, troop, host, force, legion",
        "punish, punishment, penalty, torment, chastise, chastisement, retribution, torture",
        "oppress, oppression, tyranny, tyrant, injustice, wrongdoer",
        "harm, hurt, injure, injury, wound, damage",
        // Feeling and character
        "shame, disgrace, humiliation, humiliate, dishonor, embarrass, abase, ignominy",
        "pride, proud, arrogant, haughty, conceit, boast, insolent, exultant",
        "humble, humility, lowly, modest, meek",
        "fear, afraid, dread, terror, frighten, awe",
        "sad, grief, sorrow, grieve, mourn, distress, anguish",
        "happy, joy, rejoice, glad, delight, cheer",
        "anger, angry, wrath, rage, fury",
        "patient, patience, steadfast, persevere, endure, forbear",
        "grateful, thank, gratitude, thankful",
        "ungrateful, ingratitude, thankless",
        "envy, jealous, jealousy, covet",
        "greed, greedy, miser, stingy, niggardly, hoard, avarice",
        "generous, generosity, bountiful, spend",
        "love, affection, beloved, adore",
        "hate, hatred, detest, loathe, abhor, despise, enmity",
        "mercy, merciful, compassion, kind, kindness, clemency",
        "forgive, forgiveness, pardon, absolve",
        "repent, repentance, penitent",
        "despair, hopeless, despond",
        "lie, liar, falsehood, deceive, deceit, false",
        "truth, true, truthful, honest, sincere",
        "cheat, defraud, fraud, swindle",
        "mock, ridicule, scoff, jeer, deride",
        "backbite, slander, gossip, defame, calumny",
        "spy, pry",
        "suspicion, suspect, assumption",
        "insult, abuse, revile",
        "curse, damn, accursed",
        "wise, wisdom",
        "fool, foolish, ignorant, ignorance",
        "hasty, haste, impatient, hurry",
        "ease, relief, comfort",
        "hardship, difficulty, distress, adversity, hard",
        // The body
        "blind, sightless",
        "eye, sight, vision, gaze",
        "ear, hearing",
        "heart, breast, chest, bosom",
        "foot, leg",
        "face, countenance",
        "neck, jugular, vein, throat",
        "flesh, meat",
        "womb, pregnant, pregnancy, conceive",
        "breastfeed, suckle, nurse, wean",
        "sleep, slumber, asleep, remain",
        "hunger, hungry, starve, famine",
        "sick, ill, illness, disease, ailment",
        "heal, cure, recover",
        // Animals
        "animal, beast, creature, cattle, livestock",
        "camel, she-camel",
        "cow, heifer, calf, cattle",
        "sheep, goat, ewe, lamb, ram",
        "horse, steed, mule",
        "donkey, ass",
        "dog, hound",
        "bird, hoopoe, raven, crow, quail",
        "fish, whale",
        "bee, honey",
        "spider, web",
        "fly, gnat, mosquito",
        "snake, serpent",
        "pig, swine, pork",
        "ape, monkey",
        // The world
        "sky, heaven, firmament",
        "earth, land, ground",
        "sea, ocean, water",
        "river, stream",
        "rain, shower, downpour",
        "wind, gale, storm, tempest",
        "thunder, lightning, thunderbolt",
        "mountain, hill, mount",
        "garden, orchard, vineyard, paradise",
        "fire, flame, blaze, burn",
        "light, lamp, illuminate, shine, radiance",
        "dark, darkness, gloom",
        "night, evening",
        "day, morning, dawn, daybreak",
        "flood, deluge, drown",
        "earthquake, quake, tremor",
        "iron, metal",
        "stone, rock, pebble",
        "dust, clay, soil, mud",
        "ship, ark, boat, vessel",
        // Wealth and dealings
        "usury, interest, riba",
        "debt, loan, lend, borrow",
        "trade, commerce, merchandise, sell, buy, bargain",
        "money, wealth, property, riches",
        "charity, alms, zakah, zakat, sadaqah",
        "steal, theft, thief, rob",
        "inherit, inheritance, heir, bequest",
        "weigh, measure, scale, balance",
        "gamble, gambling, lot",
        "alcohol, wine, intoxicant, liquor, drink",
        // Worship and belief
        "pray, salah, worship",
        "fast, fasting, sawm",
        "pilgrimage, hajj, umrah",
        "mosque, masjid, sanctuary",
        "prostrate, prostration, sujud, bow",
        "supplicate, supplication, invoke, dua",
        "remember, remembrance, dhikr",
        "sacrifice, offering",
        "idol, statue, image, deity",
        "polytheist, idolater, pagan",
        "disbelieve, disbeliever, infidel, reject, deny, unbeliever",
        "believe, believer, faith, faithful",
        "prophet, messenger, apostle",
        "devil, satan, shaytan, iblis",
        "jinn, demon",
        "sabbath, saturday",
        "magic, sorcery, sorcerer, witchcraft, magician",
        "miracle, sign, wonder",
        "hell, hellfire, jahannam, blaze",
        "resurrection, resurrect, raise, revive",
        "sin, transgress, crime, offense, wrongdoing, iniquity",
        "adultery, fornication, zina",
        "chaste, chastity, modest",
        "oath, swear, vow, pledge, covenant",
        "witness, testify, testimony",
        "accuse, accusation, charge, slander",
        "judge, justice, just, fair, equity",
        "compel, compulsion, force, coerce",
        "obey, obedience, submit",
        "travel, journey, trip, voyage",
        // The prophets, by both their names
        "abraham, ibrahim", "moses, musa", "jesus, isa, messiah", "mary, maryam", "noah, nuh", "joseph, yusuf",
        "jacob, yaqub, israel", "solomon, sulayman, sulaiman", "david, dawud, dawood", "jonah, yunus", "job, ayyub",
        "lot, lut", "john, yahya", "zechariah, zakariyya", "aaron, harun", "pharaoh, firawn", "gabriel, jibril",
        "ishmael, ismail", "isaac, ishaq",
        // What happens
        "eat, consume, devour",
        "speak, say, talk, tell, inform",
        "build, construct, erect",
        "destroy, ruin, demolish, annihilate, perish",
        "create, creation, originate",
        "hide, conceal, secret",
        "cry, weep, tear",
        "laugh, smile",
        "walk, tread, stride",
        "flee, escape, run",
        "split, cleave, part, sunder, burst, separate",
        "join, joined, united, together, sewn, mass",
        "mix, merge, mingle, meet, transgress",
        "weak, frail, flimsy, feeble",
        "strong, mighty, powerful",
        "example, parable, similitude, likeness",
        "garment, clothing, clothes, raiment, robe, dress, cloak",
        "house, home, dwelling, abode",
        "seduce, seek, tempt, entice",
        "save, rescue, deliver",
        "cool, coolness, cold",
        "reminder, remind, reproach",
        "below, lower, beneath, inferior",
        "above, higher, superior",
        "shade, shadow",
        "advice, advise, counsel",
        "road, path, way, street",
        "thorn, thorny, branch",
        "control, restrain, suppress",
        "cat, kitten",
        "hell, fire, hellfire",
    ]
}

#if HAS_QURAN || HAS_HADITH

// MARK: - Scoring

/// One searchable field: who holds each stem, and how long each document is.
fileprivate struct DescribedField {
    /// Per stem id: the documents that hold it, each `document << 8 | occurrences`.
    var postings: [Int32: [UInt32]] = [:]
    var lengths: [Float] = []
    var average: Float = 1

    /// How much a stem's own occurrences saturate, and how much a long text is held against it.
    /// `b` is lower than the usual 0.75: the long ayahs are the legal ones, and "your spouses are a
    /// garment for you" is one clause of a long one (2:187); a long narration is a story told whole.
    static let k1: Float = 1.2
    static let b: Float = 0.5
    /// What a related word is worth against the word itself.
    static let relatedWeight: Float = 0.7

    /// BM25 for one stem: `visit(document, score)` for every document holding it.
    func score(_ stem: Int32, _ visit: (Int, Float) -> Void) {
        guard let list = postings[stem], !list.isEmpty else { return }
        let n = Float(lengths.count), df = Float(list.count)
        let idf = log(1 + (n - df + 0.5) / (df + 0.5))
        for packed in list {
            let document = Int(packed >> 8)
            let tf = Float(packed & 0xFF)
            visit(document, idf * tf * (Self.k1 + 1) / (tf + Self.k1 * (1 - Self.b + Self.b * lengths[document] / average)))
        }
    }

    /// The field's score per document for a description: the best of each concept's members (the
    /// word itself at full weight, a related word at `relatedWeight`), summed over the concepts.
    func scores(for concepts: [(main: Int32?, related: [Int32])]) -> [Float] {
        var total = [Float](repeating: 0, count: lengths.count)
        var best = [Float](repeating: 0, count: lengths.count)
        var touched: [Int] = []
        for concept in concepts {
            touched.removeAll(keepingCapacity: true)
            func take(_ stem: Int32, weight: Float) {
                score(stem) { document, score in
                    let value = score * weight
                    if best[document] == 0 { touched.append(document) }
                    if value > best[document] { best[document] = value }
                }
            }
            if let main = concept.main { take(main, weight: 1) }
            for related in concept.related { take(related, weight: Self.relatedWeight) }
            for document in touched {
                total[document] += best[document]
                best[document] = 0
            }
        }
        return total
    }

    /// Whether `document` holds the concept's word or one related to it. Each stem's documents are
    /// stored in rising order, so this is a few binary searches.
    func holds(_ concept: (main: Int32?, related: [Int32]), document: Int) -> Bool {
        for stem in [concept.main].compactMap({ $0 }) + concept.related {
            guard let list = postings[stem] else { continue }
            var low = 0, high = list.count - 1
            while low <= high {
                let middle = (low + high) / 2
                let found = Int(list[middle] >> 8)
                if found == document { return true }
                if found < document { low = middle + 1 } else { high = middle - 1 }
            }
        }
        return false
    }

    init() {}

    init(passages: [SearchWordsPack.Passage], stemOfWord: [Int32], occurrenceCap: Int) {
        var sum: Float = 0
        lengths.reserveCapacity(passages.count)
        for (passage, entry) in passages.enumerated() {
            // Several words of one passage may share a stem.
            var counts: [Int32: Int] = [:]
            for packed in entry.words {
                let word = Int(packed & 0xFF_FFFF)
                guard stemOfWord.indices.contains(word) else { continue }
                // Past a handful, more occurrences say nothing new, and they would make the passage
                // "long" to the scoring.
                counts[stemOfWord[word], default: 0] += min(Int(packed >> 24), occurrenceCap)
            }
            for (stem, n) in counts {
                postings[stem, default: []].append(UInt32(passage) << 8 | UInt32(min(n, 255)))
            }
            // The length the kept words add up to: the field scores what it holds.
            let length = Float(counts.values.reduce(0, +))
            lengths.append(length)
            sum += length
        }
        average = max(1, sum / Float(max(1, passages.count)))
    }
}

/// A description's concepts against an index's stems: each word's own stem, and its related stems.
fileprivate func describedConcepts(_ stems: [String], in ids: [String: Int32]) -> [(main: Int32?, related: [Int32])] {
    stems.map { stem in (ids[stem], (AskAIWords.related[stem] ?? []).compactMap { ids[$0] }) }
}

#endif

#if HAS_QURAN

// MARK: - The Quran, searched by description

/// See the head of this file. Built once per launch from the Quran's two English translations and
/// the shipped tafsir words (about 60 ms off the main thread on the simulator), then every search is
/// a walk of a few posting lists: under 5 ms.
enum QuranDescribedSearch {
    struct Hit: Equatable {
        let surah: Int
        let ayah: Int
        let score: Double
        /// The ayah before or after it that carries part of the description too (the news of a
        /// daughter is 16:58, burying her 16:59): the two are read together. Nil when it stands alone.
        var partner: Int? = nil
        /// The share of the description's concepts that the ayah's own words, or its neighbours',
        /// carry (0 to 1): how far the app may say "this is the passage" (`isConfident`).
        var coverage: Double = 0

        /// Whether the ayah carries enough of the description to be offered as the passage meant.
        var isConfident: Bool { coverage >= AskAIWords.confidentCoverage }
    }



    @MainActor private static var built: Index?
    @MainActor private static var building: Task<Index?, Never>?

    /// The index, built on first use. Nil only while the Quran itself has not loaded.
    @MainActor
    static func index(quranData: QuranData) async -> Index? {
        if let built { return built }
        if building == nil {
            var texts: [Index.Text] = []
            texts.reserveCapacity(6_236)
            for surah in quranData.quran {
                for ayah in surah.ayahs {
                    texts.append(Index.Text(surah: surah.id, ayah: ayah.id, first: ayah.textEnglishSaheeh, second: ayah.textEnglishMustafa))
                }
            }
            guard !texts.isEmpty else { return nil }
            building = Task.detached(priority: .userInitiated) {
                // The topic index: a few words that say what its ayahs are about ("burying daughters alive").
                let topics = QuranTopicsStore.shared.topics().map { Index.Topic(name: $0.name, ayahs: $0.ayahs) }
                return Index(texts: texts, tafsir: SearchWordsPack.load("TafsirKeywords", subdirectory: "Quran"), topics: topics)
            }
        }
        built = await building?.value
        return built
    }

    /// The index if it is already built (nil before the first search of a launch).
    @MainActor static var builtIndex: Index? { built }

    /// Starts the build without waiting for it (the chat's warm-up).
    @MainActor
    static func prewarm(quranData: QuranData) {
        guard built == nil, building == nil else { return }
        Task { _ = await index(quranData: quranData) }
    }

    // MARK: The index

    final class Index: @unchecked Sendable {
        struct Text {
            let surah: Int
            let ayah: Int
            let first: String
            let second: String
        }

        /// An entry of the Quran topic index (`QuranTopicsStore`): its name, and its ayahs as "16:58".
        struct Topic {
            let name: String
            let ayahs: [String]
        }

        /// What a neighbouring ayah's match adds to an ayah, and what each tafsir's does.
        private static let neighbourWeight: Float = 0.35
        private static let tafsirWeight: Float = 0.25
        /// What the best-fitting topic that lists an ayah adds to it. A topic's name is a person's
        /// own description of its ayahs ("burying daughters alive" for 16:58-59, where the
        /// translations say neither word of a reader's "killing their children out of shame"), so
        /// it counts for most of what the ayah's own words do. A topic that lists more ayahs than
        /// `topicReach` is a subject, not a description, and is left out.
        private static let topicWeight: Float = 0.8
        private static let topicReach = 40
        /// Concepts within this many meaning-carrying words of each other sit together.
        private static let nearSpan = 5
        private static let nearBonus: Float = 0.5
        private static let tafsirOccurrences = 6
        /// A neighbour is read with an ayah when its own match is at least this share of the ayah's.
        private static let partnerShare: Float = 0.3
        private static let partnered = 3
        private static let rescored = 150

        private let surahs: [Int32]
        private let ayahs: [Int32]
        private let stemIDs: [String: Int32]
        private let own: DescribedField
        /// Each ayah's stems in order, one run per translation, for `near`.
        private let firstRuns: [[Int32]]
        private let secondRuns: [[Int32]]
        /// Each ayah's two translations as plain lower-case words, space-padded, for `wording`.
        private let plain: [[UInt8]]
        /// Per tafsir: its field over passages, and each ayah's passage (-1 for none).
        private let editions: [(field: DescribedField, passageOfAyah: [Int32])]
        /// The topic names as a field, and the ayahs (by index) each topic lists.
        private let topics: DescribedField
        private let ayahsOfTopic: [[Int32]]

        var count: Int { ayahs.count }
        /// Whether the translations use this word (as any of its forms).
        func knows(_ word: String) -> Bool { stemIDs[AskAIWords.stem(word.lowercased())] != nil }
        /// Whether the shipped tafsir words were found and read (`-askAILog` says so when not).
        var hasTafsir: Bool { !editions.isEmpty }

        fileprivate init(texts: [Text], tafsir: SearchWordsPack?, topics: [Topic] = []) {
            var ids: [String: Int32] = [:]
            func id(_ stem: String) -> Int32 {
                if let known = ids[stem] { return known }
                let new = Int32(ids.count)
                ids[stem] = new
                return new
            }
            var field = DescribedField()
            var firstRuns: [[Int32]] = []
            var secondRuns: [[Int32]] = []
            var plain: [[UInt8]] = []
            plain.reserveCapacity(texts.count)
            firstRuns.reserveCapacity(texts.count)
            secondRuns.reserveCapacity(texts.count)
            field.lengths.reserveCapacity(texts.count)
            var total: Float = 0
            for (document, text) in texts.enumerated() {
                let first = AskAIWords.stems(text.first).map(id)
                let second = AskAIWords.stems(text.second).map(id)
                plain.append(Array((" " + AskAIWords.words(text.first).joined(separator: " ") + " | "
                                    + AskAIWords.words(text.second).joined(separator: " ") + " ").utf8))
                firstRuns.append(first)
                secondRuns.append(second)
                var counts: [Int32: Int] = [:]
                for stem in first { counts[stem, default: 0] += 1 }
                for stem in second { counts[stem, default: 0] += 1 }
                for (stem, n) in counts {
                    field.postings[stem, default: []].append(UInt32(document) << 8 | UInt32(min(n, 255)))
                }
                let length = Float(first.count + second.count)
                field.lengths.append(length)
                total += length
            }
            field.average = max(1, total / Float(max(1, texts.count)))

            var editions: [(field: DescribedField, passageOfAyah: [Int32])] = []
            if let tafsir {
                // A pack's words are stemmed here, once.
                let stemOfWord: [Int32] = tafsir.words.map { id(AskAIWords.stem($0)) }
                var position: [Int: Int] = [:]
                for (index, text) in texts.enumerated() { position[text.surah << 16 | text.ayah] = index }
                for edition in tafsir.editions {
                    let passages = DescribedField(passages: edition.passages, stemOfWord: stemOfWord,
                                                  occurrenceCap: Self.tafsirOccurrences)
                    var passageOfAyah = [Int32](repeating: -1, count: texts.count)
                    for entry in edition.ayahs {
                        if let index = position[entry.surah << 16 | entry.ayah], entry.passage < edition.passages.count {
                            passageOfAyah[index] = Int32(entry.passage)
                        }
                    }
                    editions.append((passages, passageOfAyah))
                }
            }

            var topicField = DescribedField()
            var ayahsOfTopic: [[Int32]] = []
            if !topics.isEmpty {
                var position: [String: Int32] = [:]
                for (index, text) in texts.enumerated() { position["\(text.surah):\(text.ayah)"] = Int32(index) }
                var sum: Float = 0
                for topic in topics where !topic.ayahs.isEmpty && topic.ayahs.count <= Self.topicReach {
                    let listed = topic.ayahs.compactMap { position[$0] }
                    let stems = AskAIWords.stems(topic.name).map(id)
                    guard !listed.isEmpty, !stems.isEmpty else { continue }
                    let document = ayahsOfTopic.count
                    var counts: [Int32: Int] = [:]
                    for stem in stems { counts[stem, default: 0] += 1 }
                    for (stem, n) in counts {
                        topicField.postings[stem, default: []].append(UInt32(document) << 8 | UInt32(min(n, 255)))
                    }
                    topicField.lengths.append(Float(stems.count))
                    sum += Float(stems.count)
                    ayahsOfTopic.append(listed)
                }
                topicField.average = max(1, sum / Float(max(1, ayahsOfTopic.count)))
            }

            self.topics = topicField
            self.ayahsOfTopic = ayahsOfTopic
            self.surahs = texts.map { Int32($0.surah) }
            self.ayahs = texts.map { Int32($0.ayah) }
            self.stemIDs = ids
            self.own = field
            self.firstRuns = firstRuns
            self.secondRuns = secondRuns
            self.plain = plain
            self.editions = editions
        }

        /// The ayahs that best fit a description, best first. Nothing below a third of the best
        /// score is returned: past that the list is words in common, not the passage described.
        func search(_ question: String, limit: Int) -> [Hit] {
            let stems = AskAIWords.queryStems(question)
            guard !stems.isEmpty, limit > 0 else { return [] }
            let concepts = describedConcepts(stems, in: stemIDs)
            let n = ayahs.count

            let ownScores = own.scores(for: concepts)
            var total = ownScores
            for index in 0..<n where ownScores[index] > 0 {
                if index > 0, surahs[index - 1] == surahs[index] { total[index - 1] += Self.neighbourWeight * ownScores[index] }
                if index + 1 < n, surahs[index + 1] == surahs[index] { total[index + 1] += Self.neighbourWeight * ownScores[index] }
            }
            for edition in editions {
                let passageScores = edition.field.scores(for: concepts)
                for index in 0..<n {
                    let passage = Int(edition.passageOfAyah[index])
                    if passage >= 0 { total[index] += Self.tafsirWeight * passageScores[passage] }
                }
            }

            if !ayahsOfTopic.isEmpty {
                // Each ayah takes the best-fitting topic that lists it.
                var best = [Float](repeating: 0, count: n)
                for (topic, score) in topics.scores(for: concepts).enumerated() where score > 0 {
                    for ayah in ayahsOfTopic[topic] where score > best[Int(ayah)] { best[Int(ayah)] = score }
                }
                for index in 0..<n where best[index] > 0 { total[index] += Self.topicWeight * best[index] }
            }

            var ranked = (0..<n).filter { total[$0] > 0 }.sorted { total[$0] > total[$1] }
            guard !ranked.isEmpty else { return [] }
            // A re-score of the head of the list: concepts that sit together in the verse, and the
            // reader's own wording found in it word for word ("a garment for you", "closer than
            // the jugular vein": what is half remembered is often a phrase).
            let runs = Self.wordRuns(of: question)
            if stems.count > 1 || !runs.isEmpty {
                var conceptsOfStem: [Int32: UInt32] = [:]
                for (index, concept) in concepts.enumerated() where index < 32 {
                    if let main = concept.main { conceptsOfStem[main, default: 0] |= 1 << UInt32(index) }
                    for related in concept.related { conceptsOfStem[related, default: 0] |= 1 << UInt32(index) }
                }
                let head = ranked.prefix(Self.rescored)
                var rescored: [(index: Int, score: Float)] = head.map { index in
                    var factor: Float = 1
                    if stems.count > 1 {
                        let pairs = max(near(firstRuns[index], conceptsOfStem), near(secondRuns[index], conceptsOfStem))
                        factor += Self.nearBonus * min(1, Float(pairs) / Float(stems.count - 1))
                    }
                    if let length = runs.first(where: { Self.holds(plain[index], $0.bytes) })?.words {
                        factor += min(1, 0.25 * Float(length - 1))
                    }
                    return (index, total[index] * factor)
                }
                rescored.sort { $0.score > $1.score }
                for entry in rescored { total[entry.index] = entry.score }
                ranked = rescored.map(\.index) + ranked.dropFirst(head.count)
            }
            let floor = total[ranked[0]] / 3
            let chosen = ranked.prefix(limit).filter { total[$0] >= floor }
            let taken = Set(chosen)
            return chosen.enumerated().map { rank, index in
                // The neighbour that carries a real share of the description itself, unless it is
                // already in the list on its own. Only for the leading few: a partner takes a place
                // in what the model reads, and the tail's partners pushed better ayahs out of it.
                var partner: Int?
                var share = Self.partnerShare * ownScores[index]
                for neighbour in [index - 1, index + 1] where rank < Self.partnered && neighbour >= 0 && neighbour < n
                    && surahs[neighbour] == surahs[index] && !taken.contains(neighbour) && ownScores[neighbour] > share {
                    partner = Int(ayahs[neighbour])
                    share = ownScores[neighbour]
                }
                var carried = 0
                for concept in concepts {
                    let near = [index - 1, index, index + 1].filter { $0 >= 0 && $0 < n && surahs[$0] == surahs[index] }
                    if near.contains(where: { own.holds(concept, document: $0) }) { carried += 1 }
                }
                return Hit(surah: Int(surahs[index]), ayah: Int(ayahs[index]), score: Double(total[index]), partner: partner,
                           coverage: Double(carried) / Double(concepts.count))
            }
        }

        /// Every run of three to eight of the question's own words that holds at least two
        /// meaning-carrying ones (one will do in a run of four: "a garment for you"), longest first,
        /// space-padded for a whole-word search. The words that
        /// only ask ("verse about", "which hadith says") are dropped from the front first.
        fileprivate static func wordRuns(of question: String) -> [(bytes: [UInt8], words: Int)] {
            var words = AskAIWords.words(question)
            while let first = words.first, AskAIWords.questionWords.contains(first) || AskAIWords.stopWords.contains(first) {
                words.removeFirst()
            }
            guard words.count >= 3 else { return [] }
            var runs: [(bytes: [UInt8], words: Int)] = []
            for length in stride(from: min(words.count, 8), through: 3, by: -1) {
                for start in 0...(words.count - length) {
                    let run = words[start..<(start + length)]
                    let carrying = run.filter { !AskAIWords.stopWords.contains($0) }.count
                    guard carrying >= 2 || (carrying == 1 && length >= 4) else { continue }
                    runs.append((Array((" " + run.joined(separator: " ") + " ").utf8), length))
                }
            }
            return runs
        }

        fileprivate static func holds(_ text: [UInt8], _ run: [UInt8]) -> Bool {
            guard !run.isEmpty, text.count >= run.count else { return false }
            return text.withUnsafeBytes { haystack in
                run.withUnsafeBytes { needle in
                    memmem(haystack.baseAddress, haystack.count, needle.baseAddress, needle.count) != nil
                }
            }
        }

        /// How many pairs of DIFFERENT concepts have a member each within `nearSpan` words in one run.
        private func near(_ run: [Int32], _ conceptsOfStem: [Int32: UInt32]) -> Int {
            var hits: [(position: Int, concepts: UInt32)] = []
            for (position, stem) in run.enumerated() {
                if let mask = conceptsOfStem[stem] { hits.append((position, mask)) }
            }
            guard hits.count > 1 else { return 0 }
            var pairs = Set<Int>()
            for first in hits.indices {
                for second in hits.indices where second > first {
                    if hits[second].position - hits[first].position > Self.nearSpan { break }
                    var a = hits[first].concepts
                    while a != 0 {
                        let i = a.trailingZeroBitCount
                        a &= a - 1
                        var b = hits[second].concepts
                        while b != 0 {
                            let j = b.trailingZeroBitCount
                            b &= b - 1
                            if i != j { pairs.insert(min(i, j) * 32 + max(i, j)) }
                        }
                    }
                }
            }
            return pairs.count
        }
    }
}

#endif

// MARK: - Hadith, searched by description

#if HAS_HADITH

/// The eight major collections searched the same way: each narration scored on the concepts it
/// shares with the description, a rare word counting for more than a common one. The search field's
/// engine (`HadithRankedSearch`) wants every typed word present as typed, so "the woman who went to
/// hell because of a cat" found nothing (the narration says she "entered the Fire"), and "the man
/// who killed 99 people" nothing either (it is written "ninety-nine").
///
/// The words come from Resources/Data/Hadith/HadithSearchWords.bin (Scripts/build_hadith_search_words.py),
/// one list per narration in each collection's row order.
enum HadithDescribedSearch {
    struct Hit: Equatable {
        let slug: String
        let row: Int
        let score: Double
        /// The share of the description's concepts the narration carries (see `QuranDescribedSearch.Hit`).
        var coverage: Double = 0

        var isConfident: Bool { coverage >= AskAIWords.confidentCoverage }
    }

    @MainActor private static var built: Index?
    @MainActor private static var building: Task<Index?, Never>?

    /// The index, built on first use. `rowCounts` is each open collection's number of narrations: a
    /// collection whose count differs from the shipped words' (a pack rebuilt without them) is left out.
    @MainActor
    static func index(rowCounts: [String: Int]) async -> Index? {
        if let built { return built }
        if building == nil {
            building = Task.detached(priority: .userInitiated) {
                guard let pack = SearchWordsPack.load("HadithSearchWords", subdirectory: "Hadith") else { return nil }
                return Index(pack: pack, rowCounts: rowCounts)
            }
        }
        built = await building?.value
        return built
    }

    final class Index: @unchecked Sendable {
        /// A sound collection leads a later one that tells the same narration in the same words.
        private static let bookWeight: [String: Float] = ["bukhari": 1.06, "muslim": 1.05, "nawawi40": 1.08, "riyad_assalihin": 1.03]

        private let slugs: [String]
        private let bookOfDocument: [UInt8]
        private let rowOfDocument: [Int32]
        private let stemIDs: [String: Int32]
        private let field: DescribedField
        /// The collections left out because their narration counts did not match (`-askAILog`).
        let skipped: [String]

        var count: Int { rowOfDocument.count }

        fileprivate init(pack: SearchWordsPack, rowCounts: [String: Int]) {
            var ids: [String: Int32] = [:]
            let stemOfWord: [Int32] = pack.words.map { word in
                let stem = AskAIWords.stem(word)
                if let known = ids[stem] { return known }
                let new = Int32(ids.count)
                ids[stem] = new
                return new
            }
            var slugs: [String] = []
            var bookOfDocument: [UInt8] = []
            var rowOfDocument: [Int32] = []
            var passages: [SearchWordsPack.Passage] = []
            var skipped: [String] = []
            for edition in pack.editions {
                guard rowCounts[edition.slug] == edition.passages.count else {
                    skipped.append(edition.slug)
                    continue
                }
                let book = UInt8(slugs.count)
                slugs.append(edition.slug)
                for row in edition.passages.indices {
                    bookOfDocument.append(book)
                    rowOfDocument.append(Int32(row))
                }
                passages += edition.passages
            }
            self.slugs = slugs
            self.bookOfDocument = bookOfDocument
            self.rowOfDocument = rowOfDocument
            self.stemIDs = ids
            self.field = DescribedField(passages: passages, stemOfWord: stemOfWord, occurrenceCap: 6)
            self.skipped = skipped
        }

        /// The narrations that best fit a description, best first; nothing below two fifths of the best.
        func search(_ question: String, limit: Int) -> [Hit] {
            let stems = AskAIWords.queryStems(question)
            guard !stems.isEmpty, limit > 0, !rowOfDocument.isEmpty else { return [] }
            let concepts = describedConcepts(stems, in: stemIDs)
            var total = field.scores(for: concepts)
            for document in total.indices where total[document] > 0 {
                total[document] *= Self.bookWeight[slugs[Int(bookOfDocument[document])]] ?? 1
            }
            let ranked = total.indices.filter { total[$0] > 0 }.sorted { total[$0] > total[$1] }
            guard let first = ranked.first else { return [] }
            let floor = total[first] * 0.4
            return ranked.prefix(limit).filter { total[$0] >= floor }.map { document in
                let carried = concepts.filter { field.holds($0, document: document) }.count
                return Hit(slug: slugs[Int(bookOfDocument[document])], row: Int(rowOfDocument[document]), score: Double(total[document]),
                           coverage: Double(carried) / Double(concepts.count))
            }
        }
    }
}

#endif

#if HAS_QURAN || HAS_HADITH

// MARK: - The shipped search words

/// A shipped list of search words per passage: Resources/Data/Quran/TafsirKeywords.bin (each English
/// tafsir passage's most telling words, with the ayahs it covers) and
/// Resources/Data/Hadith/HadithSearchWords.bin (each narration's words). The layout is in
/// Scripts/build_tafsir_keywords.py, which writes the first; the second has no ayah table.
struct SearchWordsPack {
    struct Passage {
        /// Each `vocabulary index | occurrences << 24`.
        let words: [UInt32]
    }

    struct Edition {
        let slug: String
        let passages: [Passage]
        let ayahs: [(surah: Int, ayah: Int, passage: Int)]
    }

    let words: [String]
    let editions: [Edition]

    static func load(_ name: String, subdirectory: String) -> SearchWordsPack? {
        guard let url = ShippedFile.url(name, "bin", subdirectories: [subdirectory, "Data/\(subdirectory)", nil]),
              let data = ShippedFile.data(at: url) else { return nil }
        return SearchWordsPack(data: data)
    }

    init?(data: Data) {
        let bytes = [UInt8](data)
        var cursor = 0
        func has(_ n: Int) -> Bool { cursor + n <= bytes.count }
        func u8() -> Int { defer { cursor += 1 }; return Int(bytes[cursor]) }
        func u16() -> Int { defer { cursor += 2 }; return Int(bytes[cursor]) | Int(bytes[cursor + 1]) << 8 }
        func u32() -> UInt32 {
            defer { cursor += 4 }
            return UInt32(bytes[cursor]) | UInt32(bytes[cursor + 1]) << 8 | UInt32(bytes[cursor + 2]) << 16 | UInt32(bytes[cursor + 3]) << 24
        }
        func text() -> String? {
            guard has(1) else { return nil }
            let length = u8()
            guard has(length) else { return nil }
            defer { cursor += length }
            return String(decoding: bytes[cursor..<(cursor + length)], as: UTF8.self)
        }
        guard has(12), u32() == 0x574B_5351, u16() == 1 else { return nil }
        let editionCount = u16()
        let wordCount = Int(u32())
        var words: [String] = []
        words.reserveCapacity(wordCount)
        for _ in 0..<wordCount {
            guard let word = text() else { return nil }
            words.append(word)
        }
        var editions: [Edition] = []
        for _ in 0..<editionCount {
            guard let slug = text(), has(8) else { return nil }
            let passageCount = Int(u32())
            let ayahCount = Int(u32())
            guard has(ayahCount * 5) else { return nil }
            var ayahs: [(surah: Int, ayah: Int, passage: Int)] = []
            ayahs.reserveCapacity(ayahCount)
            for _ in 0..<ayahCount { ayahs.append((u8(), u16(), u16())) }
            var passages: [Passage] = []
            passages.reserveCapacity(passageCount)
            for _ in 0..<passageCount {
                guard has(4) else { return nil }
                _ = u16()   // the passage's full length; the field scores the kept words (see `Index.init`)
                let kept = u16()
                guard has(kept * 4) else { return nil }
                var entry: [UInt32] = []
                entry.reserveCapacity(kept)
                for _ in 0..<kept { entry.append(u32()) }
                passages.append(Passage(words: entry))
            }
            editions.append(Edition(slug: slug, passages: passages, ayahs: ayahs))
        }
        self.words = words
        self.editions = editions
    }
}

#endif
#endif
