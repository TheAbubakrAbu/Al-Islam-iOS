import XCTest
@testable import iPhone

/// Quran Words (QuranWords.swift) and its pack, QuranVocabulary.json.xz (Scripts/build_quran_vocabulary.py).
final class QuranVocabularyTests: XCTestCase {
    private func vocabulary() throws -> QuranVocabulary {
        try XCTUnwrap(QuranVocabularyStore.shared.load(), "QuranVocabulary.json.xz is not bundled or does not parse")
    }

    func testPackShapeAndTotals() throws {
        let vocabulary = try vocabulary()
        XCTAssertEqual(vocabulary.words.count, 500)
        XCTAssertEqual(vocabulary.tiers.count, 5)
        XCTAssertTrue(vocabulary.tiers.allSatisfy { $0.words.count == 100 })
        XCTAssertEqual(vocabulary.tiers.first?.first, 1)
        XCTAssertEqual(vocabulary.tiers.last?.last, 500)
        XCTAssertEqual(vocabulary.totals.words, 77_430, "the Hafs text's words, the figure the Qiraat analysis also uses")
        XCTAssertEqual(vocabulary.totals.corpusWords, 77_429)
        XCTAssertEqual(vocabulary.totals.roots, 1_642)
        XCTAssertEqual(Set(vocabulary.words.map(\.key)).count, 500, "keys must be unique: they store the known marks")
        XCTAssertEqual(vocabulary.tajweed.count, TajweedLegendCategory.allCases.count, "every rule the reader colours is counted")
        XCTAssertEqual(vocabulary.tajweed.reduce(0) { $0 + $1.count }, vocabulary.totals.tajweedMarks)
    }

    /// The figures the article and the page quote, from the corpus.
    func testKnownAnchors() throws {
        let vocabulary = try vocabulary()
        XCTAssertEqual(vocabulary.word(key: "رَبّ")?.uses, 975)
        XCTAssertEqual(vocabulary.word(key: "قالَ")?.uses, 1_618)
        XCTAssertEqual(vocabulary.word(key: "اللَّه")?.rank, 2)
        XCTAssertTrue(vocabulary.word(key: "PRON:3MS")?.isPronoun == true)
        XCTAssertTrue(vocabulary.word(key: "قالَ")?.isVerb == true)
        XCTAssertFalse(vocabulary.word(key: "رَبّ")?.isVerb ?? true)
    }

    func testRanksFollowUsesAndCoverageRises() throws {
        let vocabulary = try vocabulary()
        for (index, word) in vocabulary.words.enumerated() {
            XCTAssertEqual(word.rank, index + 1)
            XCTAssertGreaterThanOrEqual(word.uses, word.count, "\(word.key): every word it heads is a use")
        }
        for (earlier, later) in zip(vocabulary.words, vocabulary.words.dropFirst()) {
            XCTAssertGreaterThanOrEqual(earlier.uses, later.uses, "\(earlier.key) before \(later.key)")
        }
        let percents = vocabulary.milestones.map(\.percent)
        XCTAssertEqual(percents, percents.sorted())
        XCTAssertEqual(vocabulary.milestones.last?.words, 500)
        XCTAssertEqual(vocabulary.share(of: vocabulary.words.map(\.key)), vocabulary.milestones.last?.percent ?? 0, accuracy: 0.05)
    }

    /// Each word heads its own share, so the tiers' shares add up to the whole list's.
    func testTierSharesAddUp() throws {
        let vocabulary = try vocabulary()
        let sum = vocabulary.tiers.reduce(0) { $0 + vocabulary.share(of: $1) }
        XCTAssertEqual(sum, vocabulary.share(of: vocabulary.words.map(\.key)), accuracy: 0.0001)
        XCTAssertEqual(vocabulary.share(of: ["not a key"]), 0)
    }

    /// Every first occurrence names a real word of this app's Hafs text, which the Word Study card opens.
    func testFirstOccurrencesResolve() async throws {
        let vocabulary = try vocabulary()
        await QuranData.shared.waitUntilLoaded()
        let letters = CharacterSet(charactersIn: "\u{0621}"..."\u{064A}").union(CharacterSet(charactersIn: "\u{0671}"..."\u{06D3}"))
        for word in vocabulary.words {
            let ayah = try XCTUnwrap(QuranData.shared.ayah(surah: word.surah, ayah: word.ayah), "\(word.key) \(word.surah):\(word.ayah)")
            let tokens = WordTokens.tokens(in: ayah.rawArabicText(surahId: word.surah, qiraahOverride: ""))
            XCTAssertTrue(tokens.indices.contains(word.token), "\(word.key): token \(word.token) of \(tokens.count)")
            if tokens.indices.contains(word.token) {
                XCTAssertNotNil(tokens[word.token].unicodeScalars.first { letters.contains($0) }, "\(word.key): an ornament, not a word")
            }
        }
    }

    func testQuizQuestionsAreWellFormed() throws {
        let vocabulary = try vocabulary()
        var generator = SplitMix64(seed: 2026)
        for tier in vocabulary.tiers {
            let questions = QuranWordsQuiz.round(for: tier, all: vocabulary.words, using: &generator)
            XCTAssertEqual(questions.count, QuranWordsQuiz.size)
            XCTAssertEqual(Set(questions.map(\.word.key)).count, questions.count, "no word asked twice")
            for question in questions {
                XCTAssertEqual(question.choices.count, 4)
                XCTAssertEqual(Set(question.choices.map { $0.lowercased() }).count, 4, "\(question.word.key): two choices read the same")
                XCTAssertEqual(question.choices[question.answer], question.word.meaning)
                XCTAssertTrue(tier.words.contains(question.word))
            }
        }
    }

    /// A verb's wrong answers are verbs too, so "he ..." never gives the answer away.
    func testVerbDistractorsAreVerbs() throws {
        let vocabulary = try vocabulary()
        let said = try XCTUnwrap(vocabulary.word(key: "قالَ"))
        let pool = try XCTUnwrap(vocabulary.tier(of: said)).words
        let verbMeanings = Set(vocabulary.words.filter(\.isVerb).map(\.meaning))
        var generator = SplitMix64(seed: 7)
        for _ in 0..<20 {
            let question = QuranWordsQuiz.question(id: 0, for: said, pool: pool, all: vocabulary.words, using: &generator)
            XCTAssertTrue(question.choices.allSatisfy { verbMeanings.contains($0) }, "\(question.choices)")
        }
    }
}

/// A small seeded generator, so a quiz round is the same on every run.
private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
