import XCTest
@testable import iPhone

/// The Tajweed Test's question factory (`TajweedTestFactory`) over the shipped lesson pack: every
/// chapter builds a round of ten, every skill a chapter offers builds sound questions (four distinct
/// choices, the right one in its slot, the pack's own answer kept), and a Find It question's words
/// are the ayah's own words with the pack's span among the right ones.
@MainActor
final class TajweedTestFactoryTests: XCTestCase {

    private struct Seeded: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    private var tiers: [TajweedTestTier] = []

    override func setUp() async throws {
        try await super.setUp()
        guard let course = TajweedLessonsStore.shared.course() else {
            throw XCTSkip("the tajweed course pack is not bundled")
        }
        await QuranData.shared.waitUntilLoaded()
        tiers = TajweedTestLadder.tiers(in: course)
    }

    private func factory(seed: UInt64) -> TajweedTestFactory {
        var factory = TajweedTestFactory(tiers: tiers, quran: QuranData.shared)
        factory.generator = Seeded(state: seed)
        factory.visibleCategories = Set(TajweedLegendCategory.allCases)
        return factory
    }

    private func check(_ question: TajweedTestQuestion, seed: UInt64, file: StaticString = #filePath, line: UInt = #line) {
        let context = "chapter \(question.tier.id) lesson \(question.lesson.id) skill \(question.skill.rawValue) seed \(seed) source \(question.sourceKey)"
        XCTAssertFalse(question.ask.isEmpty, context, file: file, line: line)
        XCTAssertTrue(question.sourceKey.hasPrefix(question.lesson.id + "|" + question.skill.rawValue + "|"), context, file: file, line: line)
        if question.skill == .spot {
            XCTAssertTrue(question.choices.isEmpty, context, file: file, line: line)
            XCTAssertGreaterThanOrEqual(question.words.count, 4, context, file: file, line: line)
            XCTAssertFalse(question.rightWords.isEmpty, context, file: file, line: line)
            XCTAssertTrue(question.rightWords.allSatisfy { question.words.indices.contains($0) }, context, file: file, line: line)
            XCTAssertGreaterThanOrEqual(question.words.count - question.rightWords.count, 3, "nothing wrong to choose: \(context)", file: file, line: line)
            // The words are the ayah's own.
            if let reference = question.reference, let ayah = QuranData.shared.ayah(surah: reference.surah, ayah: reference.ayah) {
                let raw = ayah.rawArabicText(surahId: reference.surah, qiraahOverride: "")
                let tokens = raw.split(whereSeparator: { $0.isWhitespace }).map(String.init)
                for word in question.words {
                    XCTAssertTrue(tokens.contains(word), "\(word) is not in \(reference.surah):\(reference.ayah): \(context)", file: file, line: line)
                }
            } else {
                XCTFail("no ayah: \(context)", file: file, line: line)
            }
        } else {
            XCTAssertEqual(question.choices.count, 4, context, file: file, line: line)
            XCTAssertEqual(Set(question.choices.map(\.text)).count, 4, "choices repeat: \(context)", file: file, line: line)
            XCTAssertTrue(question.choices.indices.contains(question.answer), context, file: file, line: line)
            let right = question.choices[question.answer].text
            switch question.skill {
            case .recall:
                let index = Int(question.sourceKey.split(separator: "|").last ?? "") ?? -1
                XCTAssertTrue(question.lesson.quiz.indices.contains(index), context, file: file, line: line)
                let source = question.lesson.quiz[index]
                XCTAssertEqual(right, source.choices[source.answer], "the pack's answer moved: \(context)", file: file, line: line)
                XCTAssertEqual(Set(question.choices.map(\.text)), Set(source.choices), context, file: file, line: line)
            case .name:
                XCTAssertEqual(right, question.lesson.titleEn.localizedDisplay, context, file: file, line: line)
                XCTAssertFalse(question.prompt.isEmpty, context, file: file, line: line)
                XCTAssertTrue(question.promptIsArabic, context, file: file, line: line)
            case .letters:
                XCTAssertTrue(question.choices.allSatisfy(\.isArabic), context, file: file, line: line)
                let index = Int(question.sourceKey.split(separator: "|").last ?? "") ?? -1
                let sources = TajweedTestSources(lesson: question.lesson)
                let set = sources.letterSets[index / 2]
                if index % 2 == 1 {
                    XCTAssertFalse(set.letters.contains(right), "the outsider is inside: \(context)", file: file, line: line)
                    for choice in question.choices where choice.id != question.answer {
                        XCTAssertTrue(set.letters.contains(choice.text), "an insider is outside: \(context)", file: file, line: line)
                    }
                } else {
                    XCTAssertTrue(set.letters.contains(right), "the insider is outside: \(context)", file: file, line: line)
                    for choice in question.choices where choice.id != question.answer {
                        XCTAssertFalse(set.letters.contains(choice.text), "an outsider is inside: \(context)", file: file, line: line)
                    }
                }
            case .count:
                XCTAssertEqual(right, question.lesson.ruleCard?.countEn.localizedDisplay, context, file: file, line: line)
                XCTAssertTrue(question.promptIsArabic, context, file: file, line: line)
            case .fix:
                XCTAssertTrue(question.lesson.mistakes.map { $0.right.localizedDisplay }.contains(right), context, file: file, line: line)
                XCTAssertTrue(question.lesson.mistakes.map { $0.wrong.localizedDisplay }.contains(question.prompt), context, file: file, line: line)
            case .term:
                XCTAssertEqual(right, question.lesson.definition?.literal.localizedDisplay, context, file: file, line: line)
                XCTAssertEqual(question.prompt, question.lesson.definition?.termAr, context, file: file, line: line)
            case .spot:
                break
            }
        }
    }

    func testEveryChapterBuildsARoundOfTen() {
        XCTAssertEqual(tiers.count, 10)
        for tier in tiers {
            var factory = factory(seed: 11)
            let round = factory.round(for: tier)
            XCTAssertEqual(round.count, 10, "chapter \(tier.id)")
            XCTAssertEqual(Set(round.map(\.sourceKey)).count, round.count, "chapter \(tier.id) asked a source twice")
            XCTAssertGreaterThanOrEqual(Set(round.map(\.skill)).count, 3, "chapter \(tier.id) asked only \(Set(round.map(\.skill)))")
            for question in round { check(question, seed: 11) }
        }
    }

    func testEverySkillEveryChapterOffers() {
        var total = 0
        var bySkill: [TajweedTestSkill: Int] = [:]
        for tier in tiers {
            let base = factory(seed: 1)
            for skill in base.skills(for: tier) {
                var produced = 0
                for seed in UInt64(1)...6 {
                    var factory = factory(seed: seed)
                    let round = factory.round(for: tier, length: 10, only: skill)
                    produced += round.count
                    for question in round {
                        XCTAssertEqual(question.skill, skill)
                        check(question, seed: seed)
                    }
                }
                XCTAssertGreaterThan(produced, 0, "chapter \(tier.id) offers \(skill.rawValue) and never asked it")
                bySkill[skill, default: 0] += produced
                total += produced
            }
        }
        // Every skill is asked somewhere on the ladder.
        for skill in TajweedTestSkill.allCases {
            XCTAssertGreaterThan(bySkill[skill] ?? 0, 0, "\(skill.rawValue) is never asked")
        }
        XCTAssertGreaterThan(total, 500)
    }

    func testSpotAcceptsThePackSpan() {
        // The pack's own span is always among the right words, whatever the painter adds.
        var factory = factory(seed: 5)
        var seen = 0
        for tier in tiers {
            for lesson in tier.lessons {
                let sources = TajweedTestSources(lesson: lesson)
                for (index, example) in sources.spot.enumerated() {
                    guard let question = factory.question(fromSourceKey: TajweedTestFactory.sourceKey(lesson: lesson.id, skill: .spot, index: index), in: tier),
                          let span = example.wordSpan, let reference = question.reference,
                          let ayah = QuranData.shared.ayah(surah: reference.surah, ayah: reference.ayah) else { continue }
                    seen += 1
                    let raw = ayah.rawArabicText(surahId: reference.surah, qiraahOverride: "")
                    let tokens = raw.split(whereSeparator: { $0.isWhitespace }).map(String.init)
                    // The span's words, by text, are all marked right in the window.
                    for position in span where tokens.indices.contains(position) {
                        if let shown = question.words.firstIndex(of: tokens[position]) {
                            XCTAssertTrue(question.rightWords.contains(shown), "\(lesson.id) \(reference.surah):\(reference.ayah) span word \(tokens[position]) is not accepted")
                        }
                    }
                }
            }
        }
        XCTAssertGreaterThan(seen, 50)
    }

    func testPlacementReviewAndMissedRebuild() {
        var factory = factory(seed: 9)
        for tier in tiers {
            let pair = factory.placementPair(for: tier)
            XCTAssertEqual(pair.count, 2, "chapter \(tier.id)")
            for question in pair { check(question, seed: 9) }
        }
        let review = factory.review(of: tiers, length: 20)
        XCTAssertEqual(review.count, 20)
        for question in review { check(question, seed: 9) }

        // Every question's source key rebuilds a question of the same lesson and skill.
        for question in review {
            let again = factory.question(fromSourceKey: question.sourceKey, in: question.tier)
            XCTAssertEqual(again?.lesson.id, question.lesson.id, question.sourceKey)
            XCTAssertEqual(again?.skill, question.skill, question.sourceKey)
            XCTAssertEqual(again?.sourceKey, question.sourceKey)
        }
        let missed = factory.review(ofMissed: review.prefix(5).map { ($0.sourceKey, $0.tier.id) })
        XCTAssertEqual(missed.count, 5)
    }

    func testHiddenRulesTakeFindItOffTheTable() {
        var factory = factory(seed: 2)
        factory.visibleCategories = []
        for tier in tiers {
            XCTAssertFalse(factory.skills(for: tier).contains(.spot), "chapter \(tier.id) offers Find It with every colour off")
            let round = factory.round(for: tier)
            XCTAssertFalse(round.contains { $0.skill == .spot }, "chapter \(tier.id)")
        }
    }
}
