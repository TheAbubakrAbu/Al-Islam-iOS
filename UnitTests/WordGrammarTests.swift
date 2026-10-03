import XCTest
@testable import iPhone

/// The word card's grammar pack (WordGrammar.json.xz, Scripts/build_word_grammar.py): Tilawa's slicing
/// rule ported exactly, the pack's counts still cutting THIS app's runtime Hafs text, and the plain
/// sentences the Grammar page prints.
final class WordGrammarTests: XCTestCase {

    func testSliceFollowsBaseLetters() {
        XCTAssertEqual(WordGrammarStore.slice("بِسۡمِ", counts: [1, 2]), ["بِ", "سۡمِ"])
        XCTAssertEqual(WordGrammarStore.slice("ءَأَنذَرۡتَهُمۡ", counts: [1, 4, 1, 2]), ["ءَ", "أَنذَرۡ", "تَ", "هُمۡ"])
        XCTAssertEqual(WordGrammarStore.baseLetterCount("ءَأَنذَرۡتَهُمۡ"), 8)
        // A space-separated pause mark belongs to no segment; an implied segment is empty.
        XCTAssertEqual(WordGrammarStore.slice("دِينِ ۖ", counts: [3, 0]), ["دِينِ", ""])
    }

    /// 2:6, word 6: a question prefix, a Form IV verb, and two pronoun suffixes.
    @MainActor
    func testFourPartWord() async throws {
        await QuranData.shared.waitUntilLoaded()
        let ayah = try XCTUnwrap(QuranData.shared.ayah(surah: 2, ayah: 6))
        let token = WordTokens.tokens(in: ayah.rawArabicText(surahId: 2, qiraahOverride: ""))[5]
        let grammar = try XCTUnwrap(WordGrammarStore.shared.grammar(surah: 2, ayah: 6, token: 5, tokenText: token))

        XCTAssertTrue(grammar.isCutFromToken)
        XCTAssertEqual(grammar.segments.map(\.kind), [.prefix, .stem, .suffix, .suffix])
        XCTAssertEqual(grammar.segments.map(\.tag), ["EQ", "V", "PRON", "PRON"])
        XCTAssertEqual(grammar.segments.map(\.form).joined(), token)

        let stem = try XCTUnwrap(grammar.stem)
        XCTAssertEqual(WordGrammarText.describe(stem),
                       "Verb · second person masculine singular · past tense · Form IV (أَفْعَلَ)")
        XCTAssertEqual(WordGrammarText.describe(grammar.segments[3]), "Pronoun · they, them, their")

        let facts = WordGrammarText.facts(grammar, root: "ن ذ ر", lemma: nil)
        let person = try XCTUnwrap(facts.first { $0.label == "Person and number" })
        XCTAssertEqual(person.value, "second person masculine singular")
        XCTAssertEqual(person.explainer, "\u{201C}you (one man)\u{201D}")
        XCTAssertEqual(facts.first { $0.label == "Tense" }?.value, "past tense")
        XCTAssertEqual(WordGrammarText.chips(grammar).form, "Form IV")
    }

    /// Every counted entry still cuts the runtime text exactly: the builder checked its counts
    /// against Resources/JSONs-Deprecated/Quran.json, and the reader draws quran.qpk. A drift between
    /// the two would light the wrong letters, so it fails here instead.
    @MainActor
    func testCountsCutTheRuntimeTextEverywhere() async {
        await QuranData.shared.waitUntilLoaded()
        var annotated = 0, cut = 0
        var mismatches: [String] = []
        for surah in QuranData.shared.quran {
            for ayah in surah.ayahs where !ayah.textHafs.isEmpty {
                let tokens = WordTokens.tokens(in: ayah.rawArabicText(surahId: surah.id, qiraahOverride: ""))
                for (index, token) in tokens.enumerated() {
                    guard let grammar = WordGrammarStore.shared.grammar(
                        surah: surah.id, ayah: ayah.id, token: index, tokenText: token) else { continue }
                    annotated += 1
                    guard grammar.isCutFromToken else { continue }
                    cut += 1
                    var core = String.UnicodeScalarView()
                    core.append(contentsOf: WordGrammarStore.coreScalars(token))
                    if grammar.segments.map(\.form).joined() != String(core).trimmingCharacters(in: .whitespaces),
                       mismatches.count < 10 {
                        mismatches.append("\(surah.id):\(ayah.id):\(index)")
                    }
                }
            }
        }
        XCTAssertGreaterThan(annotated, 77_000, "the grammar pack did not load or lost its alignment")
        XCTAssertGreaterThan(cut, 77_300, "counts no longer fit the runtime text")
        XCTAssertEqual(mismatches, [], "cut pieces that do not join back into their word")
    }
}
