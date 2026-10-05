import XCTest
@testable import iPhone

/// `Settings.cleanSearch` / `cleanSearchKeepingHamza` became table-driven on 2026-10-03 (Phase 10.1).
/// This pins them to the OLD implementation, kept here verbatim as the reference, over every ayah text
/// the index folds plus a bank of edge cases (mixed scripts, cased non-Latin letters, every whitespace
/// kind, operators, combining marks). Any divergence is a search-result change and fails here.
final class SearchFoldEquivalenceTests: XCTestCase {

    // MARK: Reference (the pre-Phase-10 code, character for character)

    private static func referenceFold(_ text: String, map: [UnicodeScalar: UnicodeScalar?],
                                      unwanted: CharacterSet, whitespace: Bool) -> String {
        var built = ""
        built.unicodeScalars.reserveCapacity(text.unicodeScalars.count)
        for scalar in text.unicodeScalars {
            // The one rule added since (2026-10-04): an en or em dash is a word break, not dropped.
            if scalar.value == 0x2013 || scalar.value == 0x2014 {
                built.unicodeScalars.append(" ")
                continue
            }
            if let mapped = map[scalar] {
                guard let replacement = mapped else { continue }
                if unwanted.contains(replacement) { continue }
                built.unicodeScalars.append(replacement)
            } else {
                if unwanted.contains(scalar) { continue }
                built.unicodeScalars.append(scalar)
            }
        }
        var cleaned = built.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if whitespace {
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return cleaned
    }

    private static let edgeCases: [String] = [
        "", " ", "\t\n\r", "  a  ", "A\u{0085}B", "x\u{00A0}y\u{2003}z\u{3000}w", "line1\nline2\r\nline3",
        "ABC def GHI", "İstanbul", "ΣΊΣΥΦΟΣ ὈΔΥΣΣΕΎΣ", "Straße GROSS", "ПРИВЕТ мир", "ǅ ǈ ǋ",
        "Mūsā ʿImrān Ṣaḥīḥ al-Bukhārī", "Abi\u{0304} Da\u{0304}wu\u{0304}d", "e\u{0301}\u{0301}",
        "#الله &|! = ^ % $", "\"quoted\" (parens) [brackets] {braces} ... ؟ ، ؛", "١٢٣ 123 ٠",
        "يَٰنِسَآءَ إِبۡرَٰهِـۧمَ ءَامَنُوا۟", "ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ", "نِسَآءِ نِسَآئِكُمۡ نِسَآؤُكُمۡ ء ٴ",
        "ۦ ۥ ى ة ـ ـٔ ٶ ٷ ٸ ٲ ٳ ٵ", "\u{06E7}\u{0670}\u{0671}", "emoji 😀 👍🏽 ﷺ", "𐐀𐐨 𝔄𝔅", // non-BMP
        "a\u{0300}\u{0301}b", "\u{0301}", "Tab\tSeparated\tValues", "trailing   ", "   leading",
        "MiXeD Case Arabic الله Latin ÀÉÎ", "NEL\u{0085}FF\u{000C}VT\u{000B}", "\u{2028}\u{2029}",
        "forefathers\u{2014}Abraham", "\u{2014}lead and trail\u{2013}", "a \u{2014} b", "2020\u{2013}24", "All-Knowing",
    ]

    private func corpusTexts() async -> [String] {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        var texts: [String] = []
        for surah in data.quran {
            texts.append(surah.nameArabic); texts.append(surah.nameTransliteration); texts.append(surah.nameEnglish)
            for ayah in surah.ayahs {
                texts.append(ayah.textHafs)
                texts.append(ayah.textCleanArabic(for: nil, surahID: surah.id, removeDots: false))
                texts.append(ayah.textEnglishSaheeh)
                texts.append(ayah.textEnglishMustafa)
                texts.append(ayah.textTransliteration)
                if let warsh = ayah.textWarsh { texts.append(warsh) }
            }
        }
        return texts
    }

    @MainActor
    func testCleanSearchMatchesReferenceOnCorpusAndEdgeCases() async {
        let settings = Settings.shared
        let map = Settings.canonicalArabicSearchScalarMapForTests
        let unwanted = Settings.unwantedCharSetForTests
        let texts = await corpusTexts() + Self.edgeCases
        XCTAssertGreaterThan(texts.count, 30_000)
        var mismatches = 0
        for text in texts {
            for whitespace in [false, true] {
                let expected = Self.referenceFold(text, map: map, unwanted: unwanted, whitespace: whitespace)
                let actual = settings.cleanSearch(text, whitespace: whitespace)
                if expected != actual {
                    mismatches += 1
                    if mismatches <= 10 { XCTFail("cleanSearch(\(text.debugDescription), whitespace: \(whitespace)) = \(actual.debugDescription), reference \(expected.debugDescription)") }
                }
            }
        }
        XCTAssertEqual(mismatches, 0)
    }

    @MainActor
    func testHamzaFoldMatchesReferenceOnCorpusAndEdgeCases() async {
        let settings = Settings.shared
        let map = Settings.hamzaPreservingArabicSearchScalarMapForTests
        let unwanted = Settings.unwantedCharSetForTests
        let texts = await corpusTexts() + Self.edgeCases
        var mismatches = 0
        for text in texts {
            for whitespace in [false, true] {
                let expected = Self.referenceFold(text, map: map, unwanted: unwanted, whitespace: whitespace)
                let actual = settings.cleanSearchKeepingHamza(text, whitespace: whitespace)
                if expected != actual {
                    mismatches += 1
                    if mismatches <= 10 { XCTFail("cleanSearchKeepingHamza(\(text.debugDescription)) = \(actual.debugDescription), reference \(expected.debugDescription)") }
                }
            }
        }
        XCTAssertEqual(mismatches, 0)
    }

    /// The index's computed tokens split the blob exactly as the old stored arrays did.
    func testIndexTokensMatchSplitRule() {
        let blob = "a  b c   d  "
        let reference = blob.split(separator: " ").map(String.init).filter { !$0.isEmpty }
        XCTAssertEqual(VerseIndexEntry.tokens(of: blob), reference)
        XCTAssertEqual(VerseIndexEntry.tokens(of: ""), [])
        XCTAssertEqual(VerseIndexEntry.tokens(of: "الحمد لله رب"), ["الحمد", "لله", "رب"])
    }
}

// MARK: - The silent-letter fold (Phase 10.1b)

extension SearchFoldEquivalenceTests {
    /// The pre-Phase-10 `removingSilentArabicLettersForSearch`, verbatim.
    private static func referenceSilent(_ text: String) -> String {
        var out = ""
        out.reserveCapacity(text.count)
        for cluster in text {
            let scalars = Array(String(cluster).unicodeScalars)
            guard let base = scalars.first(where: { (0x0621...0x064A).contains($0.value) || $0.value == 0x0671 }) else {
                out.append(cluster)
                continue
            }
            let hasStandardSukoon = scalars.contains { $0.value == 0x0652 }
            let hasDaggerAlif = scalars.contains { $0.value == 0x0670 }
            let hasShadda = scalars.contains { $0.value == 0x0651 }
            let hasUthmaniSukoon = scalars.contains { $0.value == 0x06E1 }
            let hasArabicVowel = scalars.contains {
                $0.value == 0x064E || $0.value == 0x064F || $0.value == 0x0650 ||
                $0.value == 0x064B || $0.value == 0x064C || $0.value == 0x064D ||
                $0.value == 0x0656 || $0.value == 0x0657 || $0.value == 0x065A
            }
            switch base.value {
            case 0x0627, 0x0648, 0x064A, 0x0649:
                if hasStandardSukoon && !hasUthmaniSukoon { continue }
            case 0x0644:
                if hasStandardSukoon { continue }
            default:
                break
            }
            if base.value == 0x0648, hasDaggerAlif, !hasArabicVowel, !hasShadda, !hasStandardSukoon, !hasUthmaniSukoon {
                continue
            }
            out.append(cluster)
        }
        return out
    }

    @MainActor
    func testSilentLetterFoldMatchesReferenceOnCorpus() async {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        var texts: [String] = ["", " ", "ءَامَنُوا۟ وَعَمِلُوا۟", "ٱلَّذِينَ", "وَٰلِدَيۡنِ", "a\u{0652}b", "\r\n", "۝١ بِسۡمِ"]
        for surah in data.quran {
            for ayah in surah.ayahs {
                texts.append(ayah.textHafs)
                texts.append(ayah.textCleanArabic(for: nil, surahID: surah.id, removeDots: false))
                texts.append(ayah.textHafs.removingDaggerAlifForSearch)
                if let warsh = ayah.textWarsh { texts.append(warsh) }
            }
        }
        var mismatches = 0
        for text in texts where Self.referenceSilent(text) != text.removingSilentArabicLettersForSearch {
            mismatches += 1
            if mismatches <= 5 { XCTFail("silent fold differs for \(text.debugDescription)") }
        }
        XCTAssertEqual(mismatches, 0)
        // The index's hamza lane with the caller's silent folds equals the self-computed lane.
        let settings = Settings.shared
        for surah in data.quran.prefix(3) {
            for ayah in surah.ayahs {
                let raw = ayah.textHafs, clean = ayah.textCleanArabic(for: nil, surahID: surah.id, removeDots: false)
                let direct = Settings.HamzaPrecisionFilter.corpusLanes(for: [raw, clean])
                let given = Settings.HamzaPrecisionFilter.corpusLanes(
                    for: [raw, clean],
                    silentFolds: [raw.removingSilentArabicLettersForSearch, clean.removingSilentArabicLettersForSearch])
                XCTAssertEqual(direct, given, "\(surah.id):\(ayah.id)")
                XCTAssertEqual(settings.cleanSearchIgnoringSilentArabicLetters(raw),
                               settings.cleanSearchIgnoringSilentArabicLetters(silentFold: raw.removingSilentArabicLettersForSearch))
            }
        }
    }
}
