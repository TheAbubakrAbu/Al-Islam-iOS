#if os(iOS)
import SwiftUI

// The Tajweed Test: a ladder of the course's ten chapters (TajweedCourse.swift), one tier each, in the
// course's four stages, tested the way the Reading Test tests the alphabet (Abu, 2026-10-25: "Add
// Tajweed test mode too for tajweed course"). Nothing here is typed: every question is built from the
// lesson pack (its self-check questions, its rule cards, its letter sets, its word lists, its example
// ayahs, its common mistakes and its definitions), and a question about a real ayah is graded against
// the reader's own tajweed painter where the painter knows the rule.
//
// This file is the model: the tiers, the skills, the question factory and the progress. The screens
// (ladder, chapter page, session) are in TajweedTestViews.swift; the pieces shared with the Reading
// Test are in StudyKit.swift.

// MARK: - Tiers

/// One chapter of the course as a tier of the ladder.
struct TajweedTestTier: Identifiable, Hashable {
    let chapter: TajweedLessonChapter
    let stage: TajweedCourseStage?
    /// 1-based place on the ladder.
    let number: Int
    /// How many tiers the ladder has.
    let count: Int

    var id: String { chapter.id }
    var title: String { chapter.title.localizedDisplay }
    var subtitle: String { chapter.subtitle.localizedDisplay }
    var lessons: [TajweedLesson] { chapter.lessons }

    /// The colour the chapter wears: the first lesson colour the reader paints in (grey ones read as
    /// switched off, so those fall back to the accent).
    var legend: TajweedLegendCategory? {
        for lesson in lessons {
            guard let legend = lesson.legend else { continue }
            switch legend {
            case .lamShamsiyah, .droppedLetter, .hamzatWaslSilent, .idghamBilaGhunnah: continue
            default: return legend
            }
        }
        return nil
    }

    func accent(fallback: Color) -> Color { legend?.color ?? fallback }

    static func == (lhs: TajweedTestTier, rhs: TajweedTestTier) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum TajweedTestLadder {
    /// The tiers of the loaded course, in course order.
    static func tiers(in course: TajweedLessonsStore.Course) -> [TajweedTestTier] {
        let stages = Dictionary(course.stages.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return course.chapters.enumerated().map { index, chapter in
            TajweedTestTier(chapter: chapter, stage: stages[chapter.stage], number: index + 1, count: course.chapters.count)
        }
    }

    /// The tiers grouped under their stages, in the course's order; chapters whose stage the pack does
    /// not name come last under no stage.
    static func stages(in course: TajweedLessonsStore.Course) -> [(stage: TajweedCourseStage?, tiers: [TajweedTestTier])] {
        let all = tiers(in: course)
        var out: [(stage: TajweedCourseStage?, tiers: [TajweedTestTier])] = []
        for stage in course.stages {
            let mine = all.filter { $0.chapter.stage == stage.id }
            if !mine.isEmpty { out.append((stage, mine)) }
        }
        let known = Set(course.stages.map(\.id))
        let orphans = all.filter { !known.contains($0.chapter.stage) }
        if !orphans.isEmpty { out.append((nil, orphans)) }
        return out
    }

    static func tier(id: String, in course: TajweedLessonsStore.Course) -> TajweedTestTier? {
        tiers(in: course).first { $0.id == id }
    }

    /// The symbol a stage's header wears: the course's own order, read, shape, rules, mushaf.
    static func systemImage(for stage: TajweedCourseStage?) -> String {
        switch stage?.id {
        case "read": return "textformat.size.ar"
        case "shape": return "mouth"
        case "rules": return "arrow.triangle.branch"
        case "mushaf": return "book.closed"
        default: return "graduationcap"
        }
    }
}

// MARK: - Skills

/// What a question asks the learner to do.
enum TajweedTestSkill: String, CaseIterable, Identifiable {
    /// The lesson's own self-check questions.
    case recall
    /// See a word, name the rule at work in it.
    case name
    /// See an ayah, tap the word the rule is in.
    case spot
    /// Which of these letters belongs to the group (or does not).
    case letters
    /// See a word, say how long the hold is.
    case count
    /// A common mistake: what to do instead.
    case fix
    /// The Arabic term: what it means.
    case term

    var id: String { rawValue }

    var title: String {
        switch self {
        case .recall: return String(localized: "Check Yourself")
        case .name: return String(localized: "Name the Rule")
        case .spot: return String(localized: "Find It in the Ayah")
        case .letters: return String(localized: "Which Letter?")
        case .count: return String(localized: "How Many Counts?")
        case .fix: return String(localized: "Fix the Mistake")
        case .term: return String(localized: "The Word Itself")
        }
    }

    var caption: String {
        switch self {
        case .recall: return String(localized: "The lessons' own questions, answered from the lesson")
        case .name: return String(localized: "See a word from the chapter, name the rule at work in it")
        case .spot: return String(localized: "See an ayah, tap the word the rule is in")
        case .letters: return String(localized: "Which letter belongs to the group, and which does not")
        case .count: return String(localized: "See a word, say how long it is held")
        case .fix: return String(localized: "A common mistake: choose what to do instead")
        case .term: return String(localized: "The Arabic term, and what it means")
        }
    }

    var systemImage: String {
        switch self {
        case .recall: return "target"
        case .name: return "tag"
        case .spot: return "text.magnifyingglass"
        case .letters: return "character.book.closed.ar"
        case .count: return "timer"
        case .fix: return "exclamationmark.circle"
        case .term: return "character.textbox.ar"
        }
    }
}

// MARK: - Questions

struct TajweedTestChoice: Identifiable, Hashable {
    let id: Int
    let text: String
    let isArabic: Bool
}

struct TajweedTestQuestion: Identifiable {
    let id = UUID()
    let tier: TajweedTestTier
    let skill: TajweedTestSkill
    let lesson: TajweedLesson
    /// What the missed bank keeps, and what rebuilds the question: "<lesson>|<skill>|<n>".
    let sourceKey: String
    /// What is asked, in words.
    let ask: String
    /// What is shown over the question: Arabic in the Quran's face, or a line of prose. Empty when the
    /// choices are the whole question.
    let prompt: String
    let promptIsArabic: Bool
    /// The ayah the prompt (or the words) comes from, when it is Quran: the feedback paints it.
    let reference: (surah: Int, ayah: Int)?
    /// Multiple choice. Empty for `spot`.
    let choices: [TajweedTestChoice]
    let answer: Int
    /// `spot`: the words on offer, in reading order, and the ones that are right.
    let words: [String]
    let rightWords: Set<Int>
    /// Why, said after the answer.
    let explain: String
    /// What the hint shows: the rule's trigger, the mnemonic, the lesson in a sentence. nil when a
    /// hint would be the answer.
    let hint: String?

    var isAnswerable: Bool { skill == .spot ? !rightWords.isEmpty : choices.indices.contains(answer) }
}

// MARK: - Sources

/// A lesson's Arabic, wherever the pack keeps it: a rule card's fragment, a word list's word, an example
/// ayah's span, a drill. Located in the Quran, or written out.
struct TajweedTestArabicSource {
    let text: String
    let ayah: TajweedAyahWords?
    /// The caption the pack gave it ("tanween before د"), for the explanation.
    let caption: String

    func arabic(in quran: QuranData?) -> String {
        if let ayah {
            guard let quran else { return "" }
            return ayah.words(in: quran)
        }
        return text
    }

    var reference: (surah: Int, ayah: Int)? { ayah.map { ($0.surahId, $0.ayahNumber) } }
}

/// What one lesson offers each skill, indexed so a question's source can be named and found again.
struct TajweedTestSources {
    let lesson: TajweedLesson
    let recall: [TajweedQuizQuestion]
    let arabic: [TajweedTestArabicSource]
    /// Examples with a word span whose rule the painter can grade.
    let spot: [TajweedLessonExample]
    /// Letter sets made of letters of the alphabet alone (not marks, not words, not the whole alphabet).
    let letterSets: [TajweedLessonLetterSet]
    /// The rule card's hold, when it is one of the counted ones, with the fragments to ask it on.
    let countLabel: String?
    let countFragments: [TajweedTestArabicSource]
    let mistakes: [TajweedLessonMistake]
    let definition: TajweedLessonDefinition?

    /// Whether the lesson teaches one named thing a word can be an example of.
    var namesARule: Bool {
        (lesson.legend != nil || lesson.ruleCode != nil || lesson.ruleCard != nil) && !arabic.isEmpty
    }

    func supports(_ skill: TajweedTestSkill) -> Bool {
        switch skill {
        case .recall: return !recall.isEmpty
        case .name: return namesARule
        case .spot: return !spot.isEmpty
        case .letters: return !letterSets.isEmpty
        case .count: return countLabel != nil && !countFragments.isEmpty
        case .fix: return !mistakes.isEmpty
        case .term: return definition.map { !$0.literal.isEmpty } ?? false
        }
    }

    /// The hold labels a count question chooses between: the course's own, the ones with a figure in.
    static let countLabels = ["2 counts", "4-5 counts", "6 counts", "2, 4 or 6 counts", "2-count ghunnah", "2, or 4-5 before a hamzah"]

    /// The rules whose examples the painter can grade word by word: the rule's own colours, and the
    /// alias when the colour is another rule's. Rules the painter spreads wider than the lesson (every
    /// heavy letter is painted tafkhim, a raa lesson is about the raa alone) are left out, so a learner
    /// is never marked wrong for a word the lesson would also have accepted.
    static let spotRules: [String: (categories: Set<TajweedLegendCategory>, alias: TajweedRuleAlias?)] = [
        "ikhfa": ([.ikhfaaLight, .ikhfaaHeavy], nil),
        "iqlab": ([.iqlaab], nil),
        "idgham_ghunnah": ([.idghamGhunnah], nil),
        "idgham_no_ghunnah": ([.idghamBilaGhunnah], nil),
        "qalqalah": ([.qalqalah], nil),
        "madd_muttasil": ([.maddConnected], nil),
        "madd_munfasil": ([.maddSeparated], nil),
        "madd_lazim": ([.maddNecessary], nil),
        "madd_arid": ([.maddSukoon], nil),
        "madd_tabii": ([.maddNatural, .maddNaturalMiniature], nil),
        "lam_shamsiyyah": ([.lamShamsiyah], nil),
        "ghunnah": ([.generalGhunnah], nil),
        "ikhfa_shafawi": ([.ikhfaaLight], .ikhfaaShafawi),
    ]

    init(lesson: TajweedLesson) {
        self.lesson = lesson
        recall = lesson.quiz
        var arabic: [TajweedTestArabicSource] = []
        for fragment in lesson.ruleCard?.fragments ?? [] {
            arabic.append(TajweedTestArabicSource(text: fragment.text, ayah: fragment.ayah, caption: fragment.caption))
        }
        for group in lesson.words {
            for word in group.items {
                arabic.append(TajweedTestArabicSource(text: word.text, ayah: word.ayah, caption: word.note.isEmpty ? group.label : word.note))
            }
        }
        for example in lesson.examples where example.wordSpan != nil {
            arabic.append(TajweedTestArabicSource(text: "", ayah: TajweedAyahWords(surahId: example.surahId, ayahNumber: example.ayahNumber, span: example.wordSpan!), caption: example.focus))
        }
        // A drill that contrasts two forms ("جَا -> جَآءَ") is not one example of the rule.
        for drill in lesson.drills where drill.ayah != nil || (!drill.text.isEmpty && !drill.text.contains("->") && !drill.text.contains("/")) {
            arabic.append(TajweedTestArabicSource(text: drill.text, ayah: drill.ayah, caption: drill.caption))
        }
        self.arabic = arabic.filter { $0.ayah != nil || !$0.text.isEmpty }

        spot = lesson.examples.filter { example in
            guard example.wordSpan != nil, let rule = example.rule else { return false }
            return Self.spotRules[rule] != nil
        }

        letterSets = lesson.letterSets.filter { set in
            !set.letters.isEmpty && set.letters.count < 20
                && set.letters.allSatisfy { LetterTraits.letterData(for: $0) != nil }
        }

        if let card = lesson.ruleCard, Self.countLabels.contains(card.countEn) {
            countLabel = card.countEn
            countFragments = card.fragments.map { TajweedTestArabicSource(text: $0.text, ayah: $0.ayah, caption: $0.caption) }
                .filter { $0.ayah != nil || !$0.text.isEmpty }
        } else {
            countLabel = nil
            countFragments = []
        }
        mistakes = lesson.mistakes.filter { !$0.wrong.isEmpty && !$0.right.isEmpty }
        definition = lesson.definition
    }
}

// MARK: - Factory

/// Builds rounds. Everything random goes through `generator`, so a test can replay a round. Built off
/// the main thread by the session (the painter is pure and its caches are thread-safe), with the
/// Quran and the reader's visible rules handed in.
struct TajweedTestFactory {
    var generator: RandomNumberGenerator = SystemRandomNumberGenerator()
    /// The loaded Quran, for the ayah-located sources; nil leaves those out.
    var quran: QuranData?
    /// The tajweed rules the reader has on: a Find It question is only asked where its rule is painted,
    /// since the painter is what tells the other right words from the wrong ones.
    var visibleCategories: Set<TajweedLegendCategory> = Set(TajweedLegendCategory.allCases)
    /// All the ladder's tiers, for the pools wrong answers are drawn from.
    let tiers: [TajweedTestTier]

    private var sourcesByLesson: [String: TajweedTestSources] = [:]

    init(tiers: [TajweedTestTier], quran: QuranData? = nil) {
        self.tiers = tiers
        self.quran = quran
        for tier in tiers {
            for lesson in tier.lessons {
                sourcesByLesson[lesson.id] = TajweedTestSources(lesson: lesson)
            }
        }
    }

    func sources(for lesson: TajweedLesson) -> TajweedTestSources {
        sourcesByLesson[lesson.id] ?? TajweedTestSources(lesson: lesson)
    }

    /// The skills a tier can ask: what any of its lessons offers.
    func skills(for tier: TajweedTestTier) -> [TajweedTestSkill] {
        TajweedTestSkill.allCases.filter { skill in
            tier.lessons.contains { lessonSupports($0, skill) }
        }
    }

    private func lessonSupports(_ lesson: TajweedLesson, _ skill: TajweedTestSkill) -> Bool {
        let sources = sources(for: lesson)
        guard sources.supports(skill) else { return false }
        if skill == .spot {
            // Needs the Quran, and the rule's colours on.
            guard quran != nil else { return false }
            return sources.spot.contains { example in
                guard let rule = example.rule, let paint = TajweedTestSources.spotRules[rule] else { return false }
                return paint.categories.isSubset(of: visibleCategories)
            }
        }
        if skill == .name || skill == .count {
            // Needs an Arabic that resolves (an ayah-located word needs the Quran).
            let pool = skill == .name ? sources.arabic : sources.countFragments
            return pool.contains { !$0.arabic(in: quran).isEmpty }
        }
        return true
    }

    // MARK: Rounds

    /// A scored round: the tier's skills mixed, no source asked twice, the lessons spread out.
    mutating func round(for tier: TajweedTestTier, length: Int = 10, only skill: TajweedTestSkill? = nil) -> [TajweedTestQuestion] {
        var skills = self.skills(for: tier)
        if let skill { skills = skills.contains(skill) ? [skill] : [] }
        guard !skills.isEmpty else { return [] }
        var out: [TajweedTestQuestion] = []
        var used: Set<String> = []
        var lessonUse: [String: Int] = [:]
        var turn = Int(next(upTo: skills.count))
        var guardrail = 0
        while out.count < length, guardrail < length * 8 {
            guardrail += 1
            let chosen = skills[turn % skills.count]
            turn += 1
            // The lessons that can ask this, least asked first, ties broken at random.
            let able = shuffled(tier.lessons.filter { lessonSupports($0, chosen) })
                .sorted { lessonUse[$0.id, default: 0] < lessonUse[$1.id, default: 0] }
            var placed = false
            for lesson in able {
                guard let question = question(for: lesson, in: tier, skill: chosen, avoiding: used) else { continue }
                used.insert(question.sourceKey)
                lessonUse[lesson.id, default: 0] += 1
                out.append(question)
                placed = true
                break
            }
            // Every source of this skill is spent: let the rotation move on without it.
            if !placed, skills.count > 1 { skills.removeAll { $0 == chosen } }
            if skills.isEmpty { break }
        }
        return out
    }

    /// Find My Level: two questions a tier, up the ladder. The caller stops at the first miss.
    mutating func placementPair(for tier: TajweedTestTier) -> [TajweedTestQuestion] {
        let available = skills(for: tier)
        let preferred = [TajweedTestSkill.recall, .name, .letters, .count, .fix, .term].filter(available.contains)
        guard !preferred.isEmpty else { return [] }
        var out: [TajweedTestQuestion] = []
        var used: Set<String> = []
        var guardrail = 0
        while out.count < 2, guardrail < 12 {
            guardrail += 1
            let skill = preferred[out.count % preferred.count]
            let lessons = shuffled(tier.lessons.filter { lessonSupports($0, skill) })
            for lesson in lessons {
                if let question = question(for: lesson, in: tier, skill: skill, avoiding: used) {
                    used.insert(question.sourceKey)
                    out.append(question)
                    break
                }
            }
        }
        return out
    }

    /// A mixed review across every tier in `tiers`.
    mutating func review(of tiers: [TajweedTestTier], length: Int = 20) -> [TajweedTestQuestion] {
        guard !tiers.isEmpty else { return [] }
        var out: [TajweedTestQuestion] = []
        var used: Set<String> = []
        var guardrail = 0
        while out.count < length, guardrail < length * 6 {
            guardrail += 1
            let tier = tiers[Int(next(upTo: tiers.count))]
            let skills = self.skills(for: tier)
            guard !skills.isEmpty else { continue }
            let skill = skills[Int(next(upTo: skills.count))]
            let lessons = shuffled(tier.lessons.filter { lessonSupports($0, skill) })
            for lesson in lessons {
                if let question = question(for: lesson, in: tier, skill: skill, avoiding: used) {
                    used.insert(question.sourceKey)
                    out.append(question)
                    break
                }
            }
        }
        return out
    }

    /// The missed bank asked again, each source once, in a fresh shuffle of its wrong answers.
    /// A key that cannot be rebuilt now (its rule switched off) does not cost the round a place.
    mutating func review(ofMissed keys: [(key: String, tier: String)], length: Int = 15) -> [TajweedTestQuestion] {
        var out: [TajweedTestQuestion] = []
        for (key, tierID) in shuffled(keys) where out.count < length {
            guard let tier = tiers.first(where: { $0.id == tierID }),
                  let question = question(fromSourceKey: key, in: tier) else { continue }
            out.append(question)
        }
        return out
    }

    // MARK: One question

    /// A fresh question for `lesson` by `skill`, from a source not in `avoiding`.
    mutating func question(for lesson: TajweedLesson, in tier: TajweedTestTier, skill: TajweedTestSkill, avoiding used: Set<String>) -> TajweedTestQuestion? {
        let sources = sources(for: lesson)
        let count: Int
        switch skill {
        case .recall: count = sources.recall.count
        case .name: count = sources.arabic.count
        case .spot: count = sources.spot.count
        case .letters: count = sources.letterSets.count * 2
        case .count: count = sources.countFragments.count
        case .fix: count = sources.mistakes.count
        case .term: count = 1
        }
        guard count > 0 else { return nil }
        let order = shuffled(Array(0..<count))
        for n in order {
            let key = Self.sourceKey(lesson: lesson.id, skill: skill, index: n)
            guard !used.contains(key) else { continue }
            if let question = build(lesson: lesson, in: tier, skill: skill, index: n) { return question }
        }
        return nil
    }

    /// The question a missed-bank key names, rebuilt.
    mutating func question(fromSourceKey key: String, in tier: TajweedTestTier) -> TajweedTestQuestion? {
        let parts = key.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3, let skill = TajweedTestSkill(rawValue: parts[1]), let index = Int(parts[2]),
              let lesson = tier.lessons.first(where: { $0.id == parts[0] }) else { return nil }
        return build(lesson: lesson, in: tier, skill: skill, index: index)
    }

    /// Whether the question a missed-bank key names can be asked again, judged the way `lessonSupports`
    /// judges a skill, without building it (the ladder asks as it draws): true now; false not now (a
    /// Find It whose rule's colours are off, back when they are); nil never (the pack has no such
    /// chapter, lesson or source any more).
    func canRebuild(sourceKey key: String, tier tierID: String) -> Bool? {
        let parts = key.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 3, let skill = TajweedTestSkill(rawValue: parts[1]), let index = Int(parts[2]), index >= 0,
              let tier = tiers.first(where: { $0.id == tierID }),
              let lesson = tier.lessons.first(where: { $0.id == parts[0] }) else { return nil }
        let sources = sources(for: lesson)
        switch skill {
        case .recall: return sources.recall.indices.contains(index) ? true : nil
        case .name: return sources.arabic.indices.contains(index) ? !sources.arabic[index].arabic(in: quran).isEmpty : nil
        case .spot:
            guard sources.spot.indices.contains(index), let rule = sources.spot[index].rule,
                  let paint = TajweedTestSources.spotRules[rule] else { return nil }
            return quran != nil && paint.categories.isSubset(of: visibleCategories)
        case .letters: return sources.letterSets.indices.contains(index / 2) ? true : nil
        case .count:
            return sources.countFragments.indices.contains(index) ? !sources.countFragments[index].arabic(in: quran).isEmpty : nil
        case .fix: return sources.mistakes.indices.contains(index) ? true : nil
        case .term: return lesson.definition.map { !$0.literal.isEmpty && !$0.termAr.isEmpty } == true ? true : nil
        }
    }

    static func sourceKey(lesson: String, skill: TajweedTestSkill, index: Int) -> String {
        "\(lesson)|\(skill.rawValue)|\(index)"
    }

    private mutating func build(lesson: TajweedLesson, in tier: TajweedTestTier, skill: TajweedTestSkill, index: Int) -> TajweedTestQuestion? {
        switch skill {
        case .recall: return recallQuestion(lesson, in: tier, index: index)
        case .name: return nameQuestion(lesson, in: tier, index: index)
        case .spot: return spotQuestion(lesson, in: tier, index: index)
        case .letters: return lettersQuestion(lesson, in: tier, index: index)
        case .count: return countQuestion(lesson, in: tier, index: index)
        case .fix: return fixQuestion(lesson, in: tier, index: index)
        case .term: return termQuestion(lesson, in: tier)
        }
    }

    /// The pack's own question, its choices reshuffled.
    private mutating func recallQuestion(_ lesson: TajweedLesson, in tier: TajweedTestTier, index: Int) -> TajweedTestQuestion? {
        let quiz = sources(for: lesson).recall
        guard quiz.indices.contains(index) else { return nil }
        let source = quiz[index]
        guard source.choices.indices.contains(source.answer) else { return nil }
        let order = shuffled(Array(source.choices.indices))
        let choices = order.enumerated().map { slot, original in
            TajweedTestChoice(id: slot, text: source.choices[original], isArabic: Self.isArabicOnly(source.choices[original]))
        }
        let arabic = quran.map { source.arabic(in: $0) } ?? source.arabic
        return TajweedTestQuestion(
            tier: tier, skill: .recall, lesson: lesson,
            sourceKey: Self.sourceKey(lesson: lesson.id, skill: .recall, index: index),
            ask: source.prompt.localizedDisplay, prompt: arabic, promptIsArabic: !arabic.isEmpty,
            reference: source.ayah.map { ($0.surahId, $0.ayahNumber) },
            choices: choices, answer: order.firstIndex(of: source.answer) ?? 0,
            words: [], rightWords: [], explain: source.explain.localizedDisplay,
            hint: lesson.summary.isEmpty ? nil : lesson.summary.localizedDisplay)
    }

    /// A word of the lesson; the lessons of the chapter (then the stage, then the course) as the names.
    private mutating func nameQuestion(_ lesson: TajweedLesson, in tier: TajweedTestTier, index: Int) -> TajweedTestQuestion? {
        let sources = sources(for: lesson)
        guard sources.arabic.indices.contains(index) else { return nil }
        let source = sources.arabic[index]
        let arabic = source.arabic(in: quran)
        guard !arabic.isEmpty else { return nil }
        let right = lesson.titleEn.localizedDisplay
        let pools = titlePools(for: lesson, in: tier, title: { $0.titleEn.localizedDisplay }, eligible: { self.sources(for: $0).namesARule })
        let wrong = pick(3, from: pools)
        guard wrong.count == 3 else { return nil }
        let (choices, answer) = arrange(right: right, wrong: wrong, arabic: false)
        var explain = lesson.summary.localizedDisplay
        if !source.caption.isEmpty { explain = source.caption.localizedDisplay + (explain.isEmpty ? "" : " " + explain) }
        return TajweedTestQuestion(
            tier: tier, skill: .name, lesson: lesson,
            sourceKey: Self.sourceKey(lesson: lesson.id, skill: .name, index: index),
            ask: String(localized: "Which rule is at work here?"), prompt: arabic, promptIsArabic: true,
            reference: source.reference, choices: choices, answer: answer,
            words: [], rightWords: [], explain: explain, hint: ruleHint(lesson))
    }

    /// An example ayah with the rule's word to find. Right: the pack's span, and any other word the
    /// painter paints in the rule's colour.
    private mutating func spotQuestion(_ lesson: TajweedLesson, in tier: TajweedTestTier, index: Int) -> TajweedTestQuestion? {
        let examples = sources(for: lesson).spot
        guard examples.indices.contains(index), let quran else { return nil }
        let example = examples[index]
        guard let span = example.wordSpan, let rule = example.rule, let paint = TajweedTestSources.spotRules[rule],
              paint.categories.isSubset(of: visibleCategories),
              let surah = quran.surah(example.surahId),
              let ayah = surah.ayahs.first(where: { $0.id == example.ayahNumber }) else { return nil }
        let raw = ayah.rawArabicText(surahId: surah.id, qiraahOverride: "")
        let tokens = raw.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard span.upperBound < tokens.count, tokens.count >= 4 else { return nil }

        // Every word's place in the raw text, walked in order (a word can recur in an ayah).
        var ranges: [NSRange] = []
        var cursor = 0
        let nsRaw = raw as NSString
        for token in tokens {
            let found = nsRaw.range(of: token, options: [], range: NSRange(location: cursor, length: nsRaw.length - cursor))
            guard found.location != NSNotFound else { return nil }
            ranges.append(found)
            cursor = found.location + found.length
        }
        var right = Set(span)
        for (index, range) in ranges.enumerated() where !right.contains(index) {
            let rules = TajweedStore.shared.wordRules(surah: surah.id, ayah: ayah.id, text: raw, wordRange: range)
            if rules.contains(where: { paint.categories.contains($0.category) && $0.alias == paint.alias }) {
                right.insert(index)
            }
        }
        // Something has to be wrong to choose from.
        guard tokens.count - right.count >= 3 else { return nil }

        // A long ayah is shown as a window around the span, nine words or so, with wrong words in it.
        var window = 0..<tokens.count
        if tokens.count > 12 {
            let width = 9
            let center = (span.lowerBound + span.upperBound) / 2
            var start = max(0, center - width / 2)
            start = min(start, tokens.count - width)
            window = start..<(start + width)
            guard window.filter({ !right.contains($0) }).count >= 3 else { return nil }
        }
        let words = Array(tokens[window])
        let rightWords = Set(right.compactMap { window.contains($0) ? $0 - window.lowerBound : nil })
        guard !rightWords.isEmpty else { return nil }
        let ruleName = lesson.titleEn.localizedDisplay
        return TajweedTestQuestion(
            tier: tier, skill: .spot, lesson: lesson,
            sourceKey: Self.sourceKey(lesson: lesson.id, skill: .spot, index: index),
            ask: String(localized: "Tap the word where \(ruleName) happens."),
            prompt: "\(surah.nameTransliteration) \u{00B7} \(surah.id):\(ayah.id)".localizedDigits, promptIsArabic: false,
            reference: (surah.id, ayah.id), choices: [], answer: 0,
            words: words, rightWords: rightWords,
            explain: example.focus.isEmpty ? lesson.summary.localizedDisplay : example.focus.localizedDisplay,
            hint: ruleHint(lesson))
    }

    /// One letter in or out of a letter set, against three the other way.
    private mutating func lettersQuestion(_ lesson: TajweedLesson, in tier: TajweedTestTier, index: Int) -> TajweedTestQuestion? {
        let sets = sources(for: lesson).letterSets
        let setIndex = index / 2
        let asksOutsider = index % 2 == 1
        guard sets.indices.contains(setIndex) else { return nil }
        let set = sets[setIndex]
        let inside = Array(Set(set.letters))
        let outside = LetterTraits.alphabet.filter { !inside.contains($0) }
        let label = set.label.localizedDisplay
        let ask: String
        let right: String
        let wrong: [String]
        if asksOutsider {
            guard inside.count >= 3, let odd = shuffled(outside).first else { return nil }
            right = odd
            wrong = Array(shuffled(inside).prefix(3))
            ask = String(localized: "Three of these are \u{201C}\(label)\u{201D}. Which one is not?")
        } else {
            guard outside.count >= 3, let one = shuffled(inside).first else { return nil }
            right = one
            wrong = Array(shuffled(outside).prefix(3))
            ask = String(localized: "Which of these letters is \u{201C}\(label)\u{201D}?")
        }
        guard wrong.count == 3 else { return nil }
        let (choices, answer) = arrange(right: right, wrong: wrong, arabic: true)
        var explain = String(localized: "\(label): \(set.letters.joined(separator: " "))")
        if !set.note.isEmpty { explain += ". " + set.note.localizedDisplay }
        return TajweedTestQuestion(
            tier: tier, skill: .letters, lesson: lesson,
            sourceKey: Self.sourceKey(lesson: lesson.id, skill: .letters, index: index),
            ask: ask, prompt: "", promptIsArabic: true, reference: nil,
            choices: choices, answer: answer, words: [], rightWords: [],
            explain: explain,
            hint: set.note.isEmpty ? (lesson.summary.isEmpty ? nil : lesson.summary.localizedDisplay) : set.note.localizedDisplay)
    }

    /// A fragment of the rule card; the course's hold labels to choose from.
    private mutating func countQuestion(_ lesson: TajweedLesson, in tier: TajweedTestTier, index: Int) -> TajweedTestQuestion? {
        let sources = sources(for: lesson)
        guard let label = sources.countLabel, sources.countFragments.indices.contains(index) else { return nil }
        let fragment = sources.countFragments[index]
        let arabic = fragment.arabic(in: quran)
        guard !arabic.isEmpty else { return nil }
        let wrong = Array(shuffled(TajweedTestSources.countLabels.filter { $0 != label }).prefix(3))
        guard wrong.count == 3 else { return nil }
        let (choices, answer) = arrange(right: label.localizedDisplay, wrong: wrong.map(\.localizedDisplay), arabic: false)
        let hold = lesson.ruleCard?.hold ?? ""
        return TajweedTestQuestion(
            tier: tier, skill: .count, lesson: lesson,
            sourceKey: Self.sourceKey(lesson: lesson.id, skill: .count, index: index),
            ask: String(localized: "How long is the hold here?"), prompt: arabic, promptIsArabic: true,
            reference: fragment.reference, choices: choices, answer: answer, words: [], rightWords: [],
            explain: (hold.isEmpty ? lesson.summary : hold).localizedDisplay, hint: ruleHint(lesson))
    }

    /// A common mistake; what to do instead, against three other lessons' corrections.
    private mutating func fixQuestion(_ lesson: TajweedLesson, in tier: TajweedTestTier, index: Int) -> TajweedTestQuestion? {
        let mistakes = sources(for: lesson).mistakes
        guard mistakes.indices.contains(index) else { return nil }
        let mistake = mistakes[index]
        var seen: Set<String> = [mistake.right]
        // The lesson's other corrections first (the confusable ones, at most two), then the chapter's,
        // then the stage's, until there are three.
        var wrong: [String] = []
        for other in shuffled(mistakes) where wrong.count < 2 && seen.insert(other.right).inserted { wrong.append(other.right) }
        let chapterPool = tier.lessons.filter { $0.id != lesson.id }.flatMap { sources(for: $0).mistakes.map(\.right) }
        for candidate in shuffled(chapterPool) where wrong.count < 3 && seen.insert(candidate).inserted { wrong.append(candidate) }
        if wrong.count < 3 {
            let stagePool = tiers.filter { $0.id != tier.id && $0.stage?.id == tier.stage?.id }
                .flatMap(\.lessons).flatMap { sources(for: $0).mistakes.map(\.right) }
            for candidate in shuffled(stagePool) where wrong.count < 3 && seen.insert(candidate).inserted { wrong.append(candidate) }
        }
        guard wrong.count == 3 else { return nil }
        let (choices, answer) = arrange(right: mistake.right.localizedDisplay, wrong: wrong.map(\.localizedDisplay), arabic: false)
        return TajweedTestQuestion(
            tier: tier, skill: .fix, lesson: lesson,
            sourceKey: Self.sourceKey(lesson: lesson.id, skill: .fix, index: index),
            ask: String(localized: "What should you do instead?"), prompt: mistake.wrong.localizedDisplay, promptIsArabic: false,
            reference: nil, choices: choices, answer: answer, words: [], rightWords: [],
            explain: mistake.why.isEmpty ? lesson.summary.localizedDisplay : mistake.why.localizedDisplay,
            hint: lesson.summary.isEmpty ? nil : lesson.summary.localizedDisplay)
    }

    /// The term in Arabic; its literal meaning against three other lessons' terms.
    private mutating func termQuestion(_ lesson: TajweedLesson, in tier: TajweedTestTier) -> TajweedTestQuestion? {
        guard let definition = lesson.definition, !definition.literal.isEmpty, !definition.termAr.isEmpty else { return nil }
        let pools = titlePools(for: lesson, in: tier, title: { $0.definition?.literal ?? "" },
                               eligible: { $0.definition.map { !$0.literal.isEmpty } ?? false })
        let wrong = pick(3, from: pools)
        guard wrong.count == 3 else { return nil }
        let (choices, answer) = arrange(right: definition.literal.localizedDisplay, wrong: wrong.map(\.localizedDisplay), arabic: false)
        return TajweedTestQuestion(
            tier: tier, skill: .term, lesson: lesson,
            sourceKey: Self.sourceKey(lesson: lesson.id, skill: .term, index: 0),
            ask: String(localized: "What does this term mean, word for word?"), prompt: definition.termAr, promptIsArabic: true,
            reference: nil, choices: choices, answer: answer, words: [], rightWords: [],
            explain: definition.technical.isEmpty ? lesson.summary.localizedDisplay : definition.technical.localizedDisplay,
            hint: lesson.summary.isEmpty ? nil : lesson.summary.localizedDisplay)
    }

    // MARK: Plumbing

    /// Other lessons' names, in three pools the wrong answers are drawn from in order: the chapter's,
    /// then the stage's, then the rest of the course's. Only lessons passing `eligible`, no name twice
    /// and never the lesson's own. Reads only, so the callers' closures may look at the factory.
    private func titlePools(for lesson: TajweedLesson, in tier: TajweedTestTier,
                            title: (TajweedLesson) -> String, eligible: (TajweedLesson) -> Bool) -> [[String]] {
        var seen: Set<String> = [title(lesson)]
        func names(_ lessons: [TajweedLesson]) -> [String] {
            var out: [String] = []
            for other in lessons where other.id != lesson.id && eligible(other) {
                let name = title(other)
                guard !name.isEmpty, seen.insert(name).inserted else { continue }
                out.append(name)
            }
            return out
        }
        let chapter = names(tier.lessons)
        let stage = names(tiers.filter { $0.id != tier.id && $0.stage?.id == tier.stage?.id }.flatMap(\.lessons))
        let course = names(tiers.filter { $0.id != tier.id && $0.stage?.id != tier.stage?.id }.flatMap(\.lessons))
        return [chapter, stage, course]
    }

    /// `count` names, each pool shuffled and drained before the next is opened.
    private mutating func pick(_ count: Int, from pools: [[String]]) -> [String] {
        var out: [String] = []
        for pool in pools where out.count < count {
            out += shuffled(pool).prefix(count - out.count)
        }
        return out
    }

    /// The rule card's trigger, the hint for a question that asks the rule's name or hold.
    private func ruleHint(_ lesson: TajweedLesson) -> String? {
        if let trigger = lesson.ruleCard?.trigger, !trigger.isEmpty { return trigger.localizedDisplay }
        return lesson.summary.isEmpty ? nil : lesson.summary.localizedDisplay
    }

    static func isArabicOnly(_ text: String) -> Bool {
        text.containsArabicScript && !text.contains(where: { $0.isASCII && $0.isLetter })
    }

    private mutating func arrange(right: String, wrong: [String], arabic: Bool) -> ([TajweedTestChoice], Int) {
        let order = shuffled([right] + wrong)
        let choices = order.enumerated().map { TajweedTestChoice(id: $0.offset, text: $0.element, isArabic: arabic) }
        return (choices, order.firstIndex(of: right) ?? 0)
    }

    private mutating func next(upTo bound: Int) -> UInt {
        bound <= 1 ? 0 : UInt.random(in: 0..<UInt(bound), using: &generator)
    }

    private mutating func shuffled<T>(_ values: [T]) -> [T] {
        values.shuffled(using: &generator)
    }
}

// MARK: - Progress

/// What the learner has done on each chapter: the kit's ladder store with the Tajweed Test's keys.
final class TajweedTestProgress: StudyLadderProgress {
    static let shared = TajweedTestProgress(key: "tajweedTestProgress", placementKey: "tajweedTestPlacement",
                                            missedKey: "tajweedTestMissed", speedKey: "tajweedTestSpeedBest")

    func record(for tier: TajweedTestTier) -> StudyRecord { record(id: tier.id) }

    func passedCount(in tiers: [TajweedTestTier]) -> Int { passedCount(in: tiers.map(\.id)) }

    func masteredCount(in tiers: [TajweedTestTier]) -> Int { masteredCount(in: tiers.map(\.id)) }

    func nextTier(in tiers: [TajweedTestTier]) -> TajweedTestTier? {
        nextID(in: tiers.map(\.id)).flatMap { id in tiers.first { $0.id == id } }
    }

    func finish(_ tier: TajweedTestTier, right: Int, of total: Int, hints: Int, missed: [TajweedTestQuestion], answeredRight: [TajweedTestQuestion]) {
        finish(id: tier.id, right: right, of: total, hints: hints,
               missedIDs: missed.map(\.sourceKey), rightIDs: answeredRight.map(\.sourceKey))
    }

    func recordPractice(_ tier: TajweedTestTier, skill: TajweedTestSkill, right: Int, of total: Int) {
        recordPractice(id: tier.id, skill: skill.rawValue, right: right, of: total)
    }

    /// The missed questions `factory` can ask again now, newest first: what Practice Missed Questions
    /// counts and opens. A Find It whose rule is switched off stays in the bank, out of the count,
    /// until the reader turns the rule back on.
    func reviewableMissed(_ factory: TajweedTestFactory) -> [StudyMissedItem] {
        missed.filter { factory.canRebuild(sourceKey: $0.id, tier: $0.tier) == true }
    }

    /// Forgets the missed questions the pack can never rebuild (a lesson an update renamed): nothing
    /// could answer them right. Only with the course loaded, or every key would look unknown.
    func forgetUnrebuildableMissed(_ factory: TajweedTestFactory) {
        guard !factory.tiers.isEmpty else { return }
        forgetMissed { factory.canRebuild(sourceKey: $0.id, tier: $0.tier) == nil }
    }

    func setPlacement(_ tier: TajweedTestTier) { setPlacement(id: tier.id) }

    #if DEBUG
    func debugSeed(passed count: Int, tiers: [TajweedTestTier]) { debugSeed(passed: count, in: tiers.map(\.id)) }
    #endif
}
#endif
