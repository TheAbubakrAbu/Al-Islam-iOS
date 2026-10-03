import XCTest
@testable import iPhone

/// The ranked Quran lane (`QuranRankedSearch`), against the app's own text. Each test pins a result
/// that was WRONG before 2026-10-02 and was measured on the real corpus: these are the behaviours a
/// change to the scoring must not lose.
final class QuranRankedSearchTests: XCTestCase {

    @MainActor
    private func snapshot() async throws -> QuranData.VerseSearchSnapshot {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        data.ensureVerseSearchIndex()
        for await ready in data.$isVerseSearchReady.values where ready { break }
        return try XCTUnwrap(data.verseSearchSnapshot())
    }

    private func refs(_ outcome: QuranRankedSearch.Outcome) -> [String] {
        outcome.hits.map { "\($0.surah):\($0.ayah)" }
    }

    // MARK: English words

    /// "mercies" is an inflection of a word the corpus knows. It used to be "corrected" to "merges".
    @MainActor
    func testInflectionIsNotASpellingMistake() async throws {
        let snapshot = try await snapshot()
        let plural = QuranRankedSearch.search("mercies", snapshot: snapshot, limit: 8)
        let singular = QuranRankedSearch.search("mercy", snapshot: snapshot, limit: 8)
        XCTAssertTrue(plural.corrections.isEmpty)
        XCTAssertEqual(plural.total, singular.total)
        XCTAssertEqual(plural.highlightQuery, "mercy")
    }

    /// A stem is matched at the start of a word: "kindness" reaches "kind", never "mankind".
    @MainActor
    func testStemNeverMatchesInsideAWord() async throws {
        let snapshot = try await snapshot()
        let outcome = QuranRankedSearch.search("kindness", snapshot: snapshot, limit: 200)
        XCTAssertFalse(refs(outcome).contains("114:2"), "The Sovereign of mankind is not about kindness")
        XCTAssertTrue(outcome.hits.first?.englishBlob.contains("kindness") ?? false)
    }

    /// How a word matched outranks how short the ayah is: the typed word leads its stem's matches.
    @MainActor
    func testTypedWordLeadsItsStem() async throws {
        let snapshot = try await snapshot()
        for query in ["praying", "forgiving", "kindness"] {
            let outcome = QuranRankedSearch.search(query, snapshot: snapshot, limit: 5)
            for hit in outcome.hits {
                XCTAssertTrue(hit.englishBlob.contains(query), "\(query): \(hit.surah):\(hit.ayah) leads without the word")
            }
        }
    }

    @MainActor
    func testTyposAreCorrected() async throws {
        let snapshot = try await snapshot()
        let patience = QuranRankedSearch.search("patiance", snapshot: snapshot, limit: 8)
        XCTAssertEqual(patience.corrections.map(\.to), ["patience"])
        XCTAssertEqual(refs(patience), refs(QuranRankedSearch.search("patience", snapshot: snapshot, limit: 8)))
        XCTAssertEqual(QuranRankedSearch.search("mercyful", snapshot: snapshot, limit: 8).corrections.map(\.to), ["merciful"])
        XCTAssertTrue(QuranRankedSearch.search("mercy", snapshot: snapshot, limit: 8).corrections.isEmpty)
    }

    @MainActor
    func testSeveralWordsNeedNotTouch() async throws {
        let snapshot = try await snapshot()
        XCTAssertEqual(Set(refs(QuranRankedSearch.search("patience prayer", snapshot: snapshot, limit: 8))), ["2:45", "2:153"])
        XCTAssertEqual(refs(QuranRankedSearch.search("controlling anger", snapshot: snapshot, limit: 8)), ["3:134"])
    }

    @MainActor
    func testOneLetterAndNonsenseAreRefused() async throws {
        let snapshot = try await snapshot()
        XCTAssertTrue(QuranRankedSearch.search("q", snapshot: snapshot, limit: 8).isEmpty)
        XCTAssertTrue(QuranRankedSearch.search("zzzqqq", snapshot: snapshot, limit: 8).isEmpty)
    }

    // MARK: Romanised Arabic

    /// A romanised word reaches the Arabic through the transliteration's sound, however it is spelled.
    @MainActor
    func testRomanisedWordsReachTheirAyahs() async throws {
        let snapshot = try await snapshot()
        let expectations: [(query: String, ayah: String, least: Int)] = [
            ("dhikr", "15:9", 40),          // the transliteration writes it "zikr": found nothing before
            ("tawbah", "9:104", 5),         // "tawbata": was corrected to "tawrah"
            ("shaytan", "4:120", 50),       // "Shaitaana": found 2 before
            ("jannah", "9:111", 50),        // "jannata": found 6 before
            ("salah", "2:43", 50),          // "salaata": found 11 before
            ("koran", "55:2", 20),          // k for q
        ]
        for expected in expectations {
            let outcome = QuranRankedSearch.search(expected.query, snapshot: snapshot, limit: 8)
            XCTAssertTrue(outcome.corrections.isEmpty, "\(expected.query) was corrected to \(outcome.corrections)")
            XCTAssertGreaterThanOrEqual(outcome.total, expected.least, expected.query)
            XCTAssertTrue(refs(outcome).contains(expected.ayah), "\(expected.query): \(refs(outcome))")
        }
    }

    /// Two words can share a sound outline. The transliteration that starts the way the word was
    /// typed leads: "tawbah" opens on at-tawbah, not on "Tabbat yadaa".
    @MainActor
    func testLiteralSpellingLeadsASharedOutline() async throws {
        let snapshot = try await snapshot()
        let tawbah = refs(QuranRankedSearch.search("tawbah", snapshot: snapshot, limit: 4))
        XCTAssertFalse(tawbah.contains("111:1"), "\(tawbah)")
        let jannah = refs(QuranRankedSearch.search("jannah", snapshot: snapshot, limit: 12))
        XCTAssertFalse(jannah.contains("114:6"), "minal jinnati is not jannah: \(jannah)")
    }

    /// The sound outline is asked of every row, and must never cost a row the typed word found.
    @MainActor
    func testRomanisedWordKeepsEveryExactHit() async throws {
        let snapshot = try await snapshot()
        for query in ["taqwa", "musa", "yawm", "rizq", "sabr", "kufr", "ibrahim"] {
            let exact = snapshot.search(term: query, limit: .max).count
            let ranked = QuranRankedSearch.search(query, snapshot: snapshot, limit: 8).total
            XCTAssertGreaterThanOrEqual(ranked, exact, query)
        }
    }

    /// The consonant skeleton is the last resort: "kufr" is not every "kafaroo", "shirk" not "saariq".
    @MainActor
    func testSkeletonStandsDownOnceTheSoundAnswered() async throws {
        let snapshot = try await snapshot()
        XCTAssertLessThan(QuranRankedSearch.search("kufr", snapshot: snapshot, limit: 8).total, 80)
        XCTAssertLessThan(QuranRankedSearch.search("shirk", snapshot: snapshot, limit: 8).total, 20)
        XCTAssertLessThan(QuranRankedSearch.search("tawbah", snapshot: snapshot, limit: 8).total, 60)
    }

    @MainActor
    func testRomanisedPhrases() async throws {
        let snapshot = try await snapshot()
        let first: [(String, String)] = [
            ("qul huwa allahu ahad", "112:1"),      // answered 2:282 before
            ("alhamdulillah", "1:2"),
            ("bismillah", "1:1"),
            ("rabbi zidni ilma", "20:114"),
        ]
        for (query, ayah) in first {
            XCTAssertEqual(refs(QuranRankedSearch.search(query, snapshot: snapshot, limit: 8)).first, ayah, query)
        }
        let contains: [(String, String)] = [
            ("la ilaha illa allah", "47:19"),
            ("hasbunallah", "3:173"),
            ("subhanallah", "37:159"),
            ("inna lillahi", "2:156"),
            ("ya ayyuhal ladhina amanu", "2:153"),
        ]
        for (query, ayah) in contains {
            let found = refs(QuranRankedSearch.search(query, snapshot: snapshot, limit: 8))
            XCTAssertTrue(found.contains(ayah), "\(query): \(found)")
        }
    }

    // MARK: Arabic script

    @MainActor
    func testArabicQueries() async throws {
        let snapshot = try await snapshot()
        XCTAssertEqual(refs(QuranRankedSearch.search("قل هو الله أحد", snapshot: snapshot, limit: 8)).first, "112:1")
        XCTAssertEqual(refs(QuranRankedSearch.search("الحمد لله", snapshot: snapshot, limit: 8)).first, "1:2")
        let sabr = QuranRankedSearch.search("صبر", snapshot: snapshot, limit: 8)
        XCTAssertGreaterThanOrEqual(sabr.total, snapshot.search(term: "صبر", limit: .max).count)
    }

    /// The corpus build reads the translations' and the transliteration's words off the index instead
    /// of folding them again; it must read exactly what the folds would say, for every ayah.
    @MainActor
    func testLatinTokenShortcutMatchesTheFolds() async throws {
        let snapshot = try await snapshot()
        XCTAssertEqual(QuranRankedSearch.verifyLatinTokenShortcut(snapshot: snapshot), 0)
    }

    // MARK: The sound outline

    func testOutlineAgreesAcrossSpellings() {
        let same: [(String, String)] = [
            ("shaytan", "shaitan"), ("rahmaan", "rahman"), ("yawm", "yaum"), ("muslim", "moslem"),
            ("moosaa", "musa"), ("qayyum", "qaiyoom"), ("jannah", "janah"), ("mecca", "mekka"),
        ]
        for (a, b) in same {
            XCTAssertEqual(QuranRankedSearch.romanKey(a), QuranRankedSearch.romanKey(b), "\(a) / \(b)")
        }
    }

    /// The outline keeps what a spelling never varies: a/i against u, where the vowels fall, q against k.
    func testOutlineKeepsWordsApart() {
        let different: [(String, String)] = [
            ("salaah", "sallooh"), ("kufr", "kafara"), ("sabr", "saabir"), ("qalb", "kalb"), ("shirk", "sharika"),
        ]
        for (a, b) in different {
            XCTAssertNotEqual(QuranRankedSearch.romanKey(a), QuranRankedSearch.romanKey(b), "\(a) / \(b)")
        }
    }

    // MARK: Ayahs known by a name

    @MainActor
    func testNamedAyahs() {
        let kursi = NamedAyah.Entry(surah: 2, ayah: 255, title: "Ayat al-Kursi")
        for name in ["ayatul kursi", "Ayat al-Kursi", "Āyat al-Kursī", "ayat ul kursee", "Throne Verse", "آية الكرسي", "اية الكرسي"] {
            XCTAssertEqual(NamedAyah.resolve(name), kursi, name)
        }
        XCTAssertEqual(NamedAyah.resolve("ayat an-nur")?.ayah, 35)
        XCTAssertEqual(NamedAyah.resolve("verse of light")?.surah, 24)
        XCTAssertEqual(NamedAyah.resolve("آية الدين")?.ayah, 282)
        // A word of the name is an ordinary search, and so is anything with a number in it.
        for text in ["kursi", "light", "ayat", "the throne", "ayatul kursi 2", "mercy", "الكرسي"] {
            XCTAssertNil(NamedAyah.resolve(text), text)
        }
    }
}
