import Foundation
import Combine

// Quran Words (Arabic Alphabet, iPhone): the Quran's most common words, a hundred to a tier, with a
// known mark per word and a test per tier. Abu, 2026-11-16, after a reel on how few words carry the
// Quran: "do something about this in tajweed and arabic and pillars and beliefs". The data is
// `Resources/Data/Quran/QuranVocabulary.json.xz` (Scripts/build_quran_vocabulary.py); the design is
// Docs/Product/Quran Words Design.md. The screens are in QuranWordsViews.swift.

// MARK: - The pack

/// One headword of the list: a dictionary word (قَالَ stands for قَالُوا, يَقُولُ, قُلۡ ...) or, for
/// words that are only a pronoun (هُوَ, لَهُمۡ), the pronoun.
struct QuranWord: Identifiable, Hashable {
    /// 1 for the most common.
    let rank: Int
    /// The corpus headword: what a known mark and a missed question store, stable across rebuilds.
    let key: String
    /// The dictionary form in the mushaf's marks.
    let arabic: String
    let meaning: String
    /// The root's letters, spaced ("ق و ل"), or empty for a particle or a pronoun.
    let root: String
    /// Words of the Quran this headword stands for, each word counted once: its share of the text.
    let count: Int
    /// Every word it appears in (مِمَّا is a use of مَا too): the number the row shows.
    let uses: Int
    /// The first occurrence, for the Word Study card: a raw token index in this app's Hafs text,
    /// ornaments counted.
    let surah: Int
    let ayah: Int
    let token: Int

    var id: String { key }

    var isPronoun: Bool { key.hasPrefix("PRON:") }

    /// A verb's meaning is written as its past he-form ("he said", "it flowed"): the quiz draws a
    /// verb's wrong answers from other verbs so the form alone never gives the answer away.
    var isVerb: Bool {
        !isPronoun && ["he ", "she ", "it "].contains { meaning.hasPrefix($0) }
    }
}

/// A hundred words of the list, in rank order.
struct QuranWordsTier: Identifiable, Hashable {
    let number: Int
    let words: [QuranWord]

    var id: String { "words\(number)" }
    var first: Int { words.first?.rank ?? 0 }
    var last: Int { words.last?.rank ?? 0 }
    var title: String { String(localized: "Words \(first) to \(last)") }
}

struct QuranVocabulary {
    struct Totals {
        /// Words in this app's Hafs text (ornaments left out).
        let words: Int
        /// Words in the Quranic Arabic Corpus, the coverage's denominator (one fewer: it joins and
        /// splits a handful differently).
        let corpusWords: Int
        let lemmas: Int
        let roots: Int
        let spellings: Int
        let bareSpellings: Int
        let usedOnce: Int
        let tajweedMarks: Int
    }

    struct Milestone: Hashable {
        let words: Int
        let percent: Double
    }

    struct RuleCount: Identifiable, Hashable {
        let category: TajweedLegendCategory
        let count: Int
        var id: String { category.rawValue }
    }

    let totals: Totals
    let milestones: [Milestone]
    let words: [QuranWord]
    let tiers: [QuranWordsTier]
    /// Every coloured stretch the reader paints in Hafs, by rule, most common first.
    let tajweed: [RuleCount]

    private let countByKey: [String: Int]

    init(totals: Totals, milestones: [Milestone], words: [QuranWord], tierSize: Int, tajweed: [RuleCount]) {
        self.totals = totals
        self.milestones = milestones
        self.words = words
        self.tajweed = tajweed
        let size = max(tierSize, 1)
        tiers = stride(from: 0, to: words.count, by: size).enumerated().map { index, start in
            QuranWordsTier(number: index + 1, words: Array(words[start..<min(start + size, words.count)]))
        }
        countByKey = Dictionary(words.map { ($0.key, $0.count) }, uniquingKeysWith: { a, _ in a })
    }

    /// The share of the Quran's words, in percent, these headwords stand for.
    func share<S: Sequence>(of keys: S) -> Double where S.Element == String {
        guard totals.corpusWords > 0 else { return 0 }
        let sum = keys.reduce(0) { $0 + (countByKey[$1] ?? 0) }
        return 100 * Double(sum) / Double(totals.corpusWords)
    }

    func share(of tier: QuranWordsTier) -> Double { share(of: tier.words.map(\.key)) }

    func word(key: String) -> QuranWord? { words.first { $0.key == key } }

    func tier(id: String) -> QuranWordsTier? { tiers.first { $0.id == id } }

    func tier(of word: QuranWord) -> QuranWordsTier? { tiers.first { $0.words.contains(word) } }

    /// The share of every tajweed mark one rule makes, in percent.
    func share(of rule: RuleCount) -> Double {
        totals.tajweedMarks > 0 ? 100 * Double(rule.count) / Double(totals.tajweedMarks) : 0
    }

    // MARK: Parsing

    static func parse(_ root: [String: Any]) -> QuranVocabulary? {
        guard root["v"] as? Int == 1,
              let totals = root["totals"] as? [String: Int],
              let rows = root["words"] as? [[Any]],
              let tierSize = root["tierSize"] as? Int else { return nil }
        func total(_ name: String) -> Int { totals[name] ?? 0 }
        var words: [QuranWord] = []
        words.reserveCapacity(rows.count)
        for (index, row) in rows.enumerated() {
            guard row.count == 9,
                  let key = row[0] as? String, let arabic = row[1] as? String, let meaning = row[2] as? String,
                  let root = row[3] as? String, let count = row[4] as? Int, let uses = row[5] as? Int,
                  let surah = row[6] as? Int, let ayah = row[7] as? Int, let token = row[8] as? Int else { return nil }
            words.append(QuranWord(rank: index + 1, key: key, arabic: arabic, meaning: meaning, root: root,
                                   count: count, uses: uses, surah: surah, ayah: ayah, token: token))
        }
        let milestones = (root["milestones"] as? [[Any]] ?? []).compactMap { pair -> Milestone? in
            guard pair.count == 2, let words = pair[0] as? Int else { return nil }
            return Milestone(words: words, percent: (pair[1] as? NSNumber)?.doubleValue ?? 0)
        }
        let tajweed = (root["tajweed"] as? [[Any]] ?? []).compactMap { pair -> RuleCount? in
            guard pair.count == 2, let rule = pair[0] as? String, let count = pair[1] as? Int,
                  let category = TajweedLegendCategory(rawValue: rule) else { return nil }
            return RuleCount(category: category, count: count)
        }
        return QuranVocabulary(
            totals: Totals(words: total("words"), corpusWords: total("corpusWords"), lemmas: total("lemmas"),
                           roots: total("roots"), spellings: total("spellings"), bareSpellings: total("bareSpellings"),
                           usedOnce: total("usedOnce"), tajweedMarks: total("tajweedMarks")),
            milestones: milestones, words: words, tierSize: tierSize, tajweed: tajweed)
    }
}

/// The bundled pack, parsed once (it is 12 KB; a view still never parses it in its body: `ifLoaded`
/// there, `load()` from a task).
final class QuranVocabularyStore: @unchecked Sendable {
    static let shared = QuranVocabularyStore()
    private init() {}

    static let isBundled: Bool = ThemesPack.url("QuranVocabulary") != nil

    private let lock = NSLock()
    private var cached: QuranVocabulary?
    private var failed = false

    var ifLoaded: QuranVocabulary? {
        lock.lock(); defer { lock.unlock() }
        return cached
    }

    /// Parses on the calling thread the first time; safe from any thread.
    @discardableResult
    func load() -> QuranVocabulary? {
        lock.lock()
        if let cached { lock.unlock(); return cached }
        if failed { lock.unlock(); return nil }
        lock.unlock()
        let parsed = (ThemesPack.json("QuranVocabulary") as? [String: Any]).flatMap(QuranVocabulary.parse)
        lock.lock(); defer { lock.unlock() }
        if let cached { return cached }
        if let parsed { cached = parsed } else { failed = true }
        return parsed
    }

    /// `load()` off the main thread.
    func loaded() async -> QuranVocabulary? {
        if let ifLoaded { return ifLoaded }
        return await Task.detached(priority: .userInitiated) { self.load() }.value
    }
}

// MARK: - Progress

/// Each tier's test record, the missed bank and the rest of the study kit's ladder, under this
/// feature's keys. In UserDefaults and in the iCloud backup (CloudMergeRules, ContentCategories).
final class QuranWordsProgress: StudyLadderProgress {
    static let shared = QuranWordsProgress(key: "quranWordsProgress", placementKey: "quranWordsPlacement",
                                           missedKey: "quranWordsMissed", speedKey: "quranWordsSpeedBest")

    func record(for tier: QuranWordsTier) -> StudyRecord { record(id: tier.id) }

    func passedCount(in tiers: [QuranWordsTier]) -> Int { passedCount(in: tiers.map(\.id)) }

    func nextTier(in tiers: [QuranWordsTier]) -> QuranWordsTier? {
        nextID(in: tiers.map(\.id)).flatMap { id in tiers.first { $0.id == id } }
    }

    /// Files a tier's test; the words answered right leave the missed bank.
    func finish(_ tier: QuranWordsTier, right: Int, of total: Int, missed: [QuranWord], answeredRight: [QuranWord]) {
        finish(id: tier.id, right: right, of: total, hints: 0,
               missedIDs: missed.map(\.key), rightIDs: answeredRight.map(\.key))
    }

    /// Forgets missed words a rebuilt pack no longer lists: no right answer could ever clear them.
    func forgetUnlisted(in vocabulary: QuranVocabulary) {
        let keys = Set(vocabulary.words.map(\.key))
        forgetMissed { !keys.contains($0.id) }
    }
}

/// The words the reader has marked known, by key. Small, in UserDefaults (and in the iCloud backup),
/// the shape of `TajweedLessonProgress`.
final class QuranWordsKnown: ObservableObject {
    static let shared = QuranWordsKnown()
    static let key = "quranWordsKnown"

    @Published private(set) var known: Set<String>

    private var storageObserver: StoredContentObserver?

    private init() {
        known = Set(UserDefaults.standard.stringArray(forKey: Self.key) ?? [])
        ObjectPublishCounter.attach(self, label: "QuranWordsKnown")
        // A restore or an erase rewrites the key underneath this object.
        storageObserver = StoredContentObserver(reload: {
            let stored = Set(UserDefaults.standard.stringArray(forKey: QuranWordsKnown.key) ?? [])
            if stored != QuranWordsKnown.shared.known { QuranWordsKnown.shared.known = stored }
        })
    }

    func contains(_ word: QuranWord) -> Bool { known.contains(word.key) }

    func toggle(_ word: QuranWord) {
        if known.contains(word.key) { known.remove(word.key) } else { known.insert(word.key) }
        save()
    }

    func mark(_ words: [QuranWord]) {
        let before = known.count
        known.formUnion(words.map(\.key))
        if known.count != before { save() }
    }

    func unmark(_ words: [QuranWord]) {
        let before = known.count
        known.subtract(words.map(\.key))
        if known.count != before { save() }
    }

    func knownCount(in words: [QuranWord]) -> Int { words.filter { known.contains($0.key) }.count }

    private func save() {
        if known.isEmpty {
            UserDefaults.standard.removeObject(forKey: Self.key)
        } else {
            UserDefaults.standard.set(Array(known).sorted(), forKey: Self.key)
        }
    }
}

// MARK: - The quiz

/// One question: an Arabic word, four meanings, one of them its own.
struct QuranWordsQuestion: Identifiable {
    let id: Int
    let word: QuranWord
    let choices: [String]
    let answer: Int
}

enum QuranWordsQuiz {
    /// Questions in a tier's test: ten right out of twelve passes (the kit's eight in ten).
    static let size = 12

    /// A tier's test: `size` of its words, each against three wrong meanings from the same tier.
    static func round<G: RandomNumberGenerator>(for tier: QuranWordsTier, all: [QuranWord],
                                                using generator: inout G) -> [QuranWordsQuestion] {
        let picked = Array(tier.words.shuffled(using: &generator).prefix(size))
        return questions(for: picked, pool: tier.words, all: all, using: &generator)
    }

    static func round(for tier: QuranWordsTier, all: [QuranWord]) -> [QuranWordsQuestion] {
        var generator = SystemRandomNumberGenerator()
        return round(for: tier, all: all, using: &generator)
    }

    /// The given words, each once, in random order: the missed bank's round.
    static func review(of words: [QuranWord], vocabulary: QuranVocabulary) -> [QuranWordsQuestion] {
        var generator = SystemRandomNumberGenerator()
        let shuffled = words.shuffled(using: &generator)
        return shuffled.enumerated().map { index, word in
            let pool = vocabulary.tier(of: word)?.words ?? vocabulary.words
            return question(id: index, for: word, pool: pool, all: vocabulary.words, using: &generator)
        }
    }

    static func questions<G: RandomNumberGenerator>(for words: [QuranWord], pool: [QuranWord], all: [QuranWord],
                                                    using generator: inout G) -> [QuranWordsQuestion] {
        words.enumerated().map { index, word in question(id: index, for: word, pool: pool, all: all, using: &generator) }
    }

    /// Three wrong meanings for `word`: of its own kind (verb or not) from `pool` first, then from the
    /// whole list, never a meaning equal to its own or to another choice.
    static func question<G: RandomNumberGenerator>(id: Int, for word: QuranWord, pool: [QuranWord], all: [QuranWord],
                                                   using generator: inout G) -> QuranWordsQuestion {
        var wrong: [String] = []
        let own = word.meaning.lowercased()
        func take(from candidates: [QuranWord]) {
            for candidate in candidates.shuffled(using: &generator) where wrong.count < 3 {
                let meaning = candidate.meaning
                guard candidate.key != word.key, meaning.lowercased() != own,
                      !wrong.contains(where: { $0.lowercased() == meaning.lowercased() }) else { continue }
                wrong.append(meaning)
            }
        }
        take(from: pool.filter { $0.isVerb == word.isVerb && $0.isPronoun == word.isPronoun })
        take(from: pool.filter { $0.isVerb == word.isVerb })
        take(from: all.filter { $0.isVerb == word.isVerb })
        take(from: all)
        var choices = wrong + [word.meaning]
        choices.shuffle(using: &generator)
        return QuranWordsQuestion(id: id, word: word, choices: choices,
                                  answer: choices.firstIndex(of: word.meaning) ?? 0)
    }
}
