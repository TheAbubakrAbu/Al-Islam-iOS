import XCTest
@testable import iPhone

/// The Reading Test's question factory (`ReadingQuestionFactory`), every tier and every skill: a seeded
/// generator builds hundreds of rounds and each question is checked the way the old scratchpad harness
/// checked it (four distinct choices, the right answer in its slot, build tiles that rebuild the word),
/// plus the three skills added on 2026-10-25: a gap whose missing letter is among the choices, four
/// pairs with distinct halves, and an odd one out that alone lacks the tier's feature.
final class ReadingTestFactoryTests: XCTestCase {

    /// A small deterministic generator, so a failure names a seed that replays.
    private struct Seeded: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    private func factory(seed: UInt64) -> ReadingQuestionFactory {
        var factory = ReadingQuestionFactory()
        factory.generator = Seeded(state: seed)
        factory.voiceAvailable = true
        return factory
    }

    private func check(_ question: ReadingQuestion, seed: UInt64, file: StaticString = #filePath, line: UInt = #line) {
        let context = "tier \(question.tier.id) skill \(question.skill.rawValue) seed \(seed) item \(question.item.arabic)"
        switch question.skill {
        case .build:
            XCTAssertFalse(question.tiles.isEmpty, context, file: file, line: line)
            XCTAssertGreaterThanOrEqual(question.target.count, 2, context, file: file, line: line)
            // Every target piece is on offer, and the pieces rebuild the word.
            var available = question.tiles.map(\.text)
            for piece in question.target {
                guard let index = available.firstIndex(of: piece) else {
                    XCTFail("missing tile \(piece): \(context)", file: file, line: line)
                    return
                }
                available.remove(at: index)
            }
            let rebuilt = question.target.joined(separator: question.tilesAreWords ? " " : "")
            XCTAssertEqual(rebuilt, question.item.arabic, context, file: file, line: line)
        case .match:
            XCTAssertEqual(question.pairs.count, 4, context, file: file, line: line)
            XCTAssertEqual(Set(question.pairs.map(\.item.arabic)).count, 4, "arabic halves repeat: \(context)", file: file, line: line)
            XCTAssertEqual(Set(question.pairs.map(\.item.reading)).count, 4, "reading halves repeat: \(context)", file: file, line: line)
            XCTAssertEqual(Set(question.pairs.map(\.leftSlot)), Set(0..<4), context, file: file, line: line)
            XCTAssertEqual(Set(question.pairs.map(\.rightSlot)), Set(0..<4), context, file: file, line: line)
        case .aloud:
            XCTAssertTrue(question.choices.isEmpty, context, file: file, line: line)
        default:
            XCTAssertEqual(question.choices.count, 4, context, file: file, line: line)
            XCTAssertEqual(Set(question.choices.map(\.text)).count, 4, "choices repeat: \(context)", file: file, line: line)
            XCTAssertTrue(question.choices.indices.contains(question.answer), context, file: file, line: line)
            let right = question.choices[question.answer].text
            switch question.skill {
            case .read: XCTAssertEqual(right, question.item.reading, context, file: file, line: line)
            case .stop: XCTAssertEqual(right, question.item.stopped, context, file: file, line: line)
            case .spell, .listen, .join: XCTAssertEqual(right, question.item.arabic, context, file: file, line: line)
            case .takeApart: XCTAssertEqual(right, question.item.reading, context, file: file, line: line)
            case .gap:
                guard let gapIndex = question.gapIndex, let parts = question.gapParts else {
                    XCTFail("no gap: \(context)", file: file, line: line)
                    return
                }
                let letters = ReadingTestText.letters(question.item.arabic)
                XCTAssertEqual(right, letters[gapIndex], context, file: file, line: line)
                XCTAssertEqual(parts.before + right + parts.after, question.item.arabic, "the gap does not rebuild the word: \(context)", file: file, line: line)
                // Every wrong letter wears the same marks as the right one, so only the letter decides.
                let marks = Array(right.unicodeScalars.dropFirst())
                for choice in question.choices where choice.id != question.answer {
                    XCTAssertEqual(Array(choice.text.unicodeScalars.dropFirst()), marks, "marks differ: \(context)", file: file, line: line)
                }
            case .odd:
                XCTAssertEqual(right, question.item.arabic, context, file: file, line: line)
                XCTAssertFalse(ReadingFeature.has(question.tier.id, question.item.arabic), "the odd one has the feature: \(context)", file: file, line: line)
                XCTAssertEqual(question.others.count, 3, context, file: file, line: line)
                for other in question.others {
                    XCTAssertTrue(ReadingFeature.has(question.tier.id, other.arabic), "an insider lacks the feature: \(context) \(other.arabic)", file: file, line: line)
                }
            default: break
            }
        }
    }

    func testEveryTierAndSkillBuildsSoundQuestions() {
        var total = 0
        for tier in ReadingTier.all {
            for skill in tier.skills {
                var produced = 0
                for seed in UInt64(1)...12 {
                    var factory = factory(seed: seed)
                    let round = factory.round(for: tier, length: 10, only: skill)
                    produced += round.count
                    for question in round { check(question, seed: seed) }
                }
                XCTAssertGreaterThan(produced, 0, "tier \(tier.id) never produced a \(skill.rawValue) question")
                total += produced
            }
        }
        XCTAssertGreaterThan(total, 2_000)
    }

    func testScoredRoundsMixTheSkills() {
        for tier in ReadingTier.all {
            var factory = factory(seed: 7)
            let round = factory.round(for: tier)
            XCTAssertEqual(round.count, 10, "tier \(tier.id)")
            let skills = Set(round.map(\.skill))
            XCTAssertGreaterThanOrEqual(skills.count, min(tier.skills.count, 3), "tier \(tier.id) asked only \(skills)")
            // No word twice in a round of ten (the bank has far more than ten everywhere).
            let items = round.filter { $0.skill != .match && $0.skill != .odd }.map(\.item)
            XCTAssertEqual(Set(items).count, items.count, "tier \(tier.id) repeated a word")
        }
    }

    func testOddOneOutFeaturesMatchTheBank() {
        // Every word the builder filed under a tier with a feature shows that feature, so the odd one
        // out can trust the predicate; the spaced tier (short vowels only) shows none of them.
        for tier in ReadingTier.all where tier.feature != nil {
            let items = ReadingTestBank.items(for: tier).filter { !$0.arabic.contains(" ") }
            let showing = items.filter { ReadingFeature.has(tier.id, $0.arabic) }.count
            XCTAssertGreaterThan(Double(showing), Double(items.count) * 0.9, "tier \(tier.id): \(showing) of \(items.count) words show the feature")
            for item in ReadingTestBank.words["spaced"] ?? [] where !item.arabic.contains(" ") {
                XCTAssertFalse(ReadingFeature.has(tier.id, item.arabic), "a letter-by-letter word \(item.arabic) shows \(tier.id)")
            }
        }
    }

    func testSpeedAndMissedRounds() {
        var factory = factory(seed: 3)
        let speed = factory.speedRound(from: ReadingTier.all, length: 40)
        XCTAssertEqual(speed.count, 40)
        XCTAssertTrue(speed.allSatisfy { $0.skill.isQuick })
        for question in speed { check(question, seed: 3) }

        // One word from each of six tiers that ask to read (the joined-shapes tier's two-letter words
        // can have no look-alike spellings to choose from, so a review may have to drop them).
        let missed = ReadingTier.all.filter { $0.skills.contains(.read) }.prefix(6)
            .compactMap { tier in ReadingTestBank.items(for: tier).first.map { (tier, $0) } }
        let review = factory.review(ofMissed: missed)
        XCTAssertEqual(review.count, missed.count)
        XCTAssertEqual(Set(review.map(\.item)), Set(missed.map(\.1)))
    }

    func testEveryTierNamesWhatItCatches() {
        for tier in ReadingTier.all {
            XCTAssertFalse(tier.catches.isEmpty, "tier \(tier.id) lists nothing it catches")
        }
    }

    // MARK: Progress

    func testRecordDecodesTheOldShape() throws {
        // What the ladder wrote before 2026-10-25: no skillBest.
        let old = Data("""
        {"vowels":{"best":90,"attempts":2,"mastered":false},"letters":{"best":100,"attempts":1,"mastered":true,"lastPlayed":700000000}}
        """.utf8)
        let records = try JSONDecoder().decode([String: StudyRecord].self, from: old)
        XCTAssertEqual(records["vowels"]?.best, 90)
        XCTAssertEqual(records["vowels"]?.skillBest, [:])
        XCTAssertEqual(records["letters"]?.mastered, true)
        XCTAssertNotNil(records["letters"]?.lastPlayed)
        XCTAssertTrue(records["vowels"]?.passed ?? false)
    }

    func testLadderProgressRoundTrip() throws {
        let suffix = String(UUID().uuidString.prefix(8))
        let progress = StudyLadderProgress(key: "test.ladder.\(suffix)", placementKey: "test.placement.\(suffix)",
                                           missedKey: "test.missed.\(suffix)", speedKey: "test.speed.\(suffix)")
        defer { progress.reset() }
        progress.finish(id: "a", right: 8, of: 10, hints: 1, missedIDs: ["x", "y"])
        XCTAssertEqual(progress.record(id: "a").best, 80)
        XCTAssertTrue(progress.record(id: "a").passed)
        XCTAssertFalse(progress.record(id: "a").mastered)
        XCTAssertEqual(progress.missed.map(\.id), ["y", "x"])
        progress.finish(id: "a", right: 10, of: 10, hints: 0, missedIDs: [], rightIDs: ["x"])
        XCTAssertTrue(progress.record(id: "a").mastered)
        XCTAssertEqual(progress.missed.map(\.id), ["y"])
        progress.recordPractice(id: "a", skill: "read", right: 7, of: 10)
        progress.recordPractice(id: "a", skill: "read", right: 5, of: 10)
        XCTAssertEqual(progress.record(id: "a").skillBest["read"], 70)
        progress.recordSpeed(right: 12)
        progress.recordSpeed(right: 9)
        XCTAssertEqual(progress.speedBest, 12)
        XCTAssertEqual(progress.nextID(in: ["a", "b", "c"]), "b")
        progress.setPlacement(id: "c")
        XCTAssertEqual(progress.nextID(in: ["a", "b", "c"]), "c")

        // What is on disk reads back the same.
        let twin = StudyLadderProgress(key: progress.key, placementKey: progress.placementKey,
                                       missedKey: progress.missedKey, speedKey: progress.speedKey)
        XCTAssertEqual(twin.records, progress.records)
        XCTAssertEqual(twin.missed, progress.missed)
        XCTAssertEqual(twin.placement, "c")
        XCTAssertEqual(twin.speedBest, 12)
    }
}
