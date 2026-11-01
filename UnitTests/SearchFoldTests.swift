import XCTest
@testable import iPhone

/// Latin accents in search: `String.foldingLatinDiacritics` and every fold that carries it (Abu,
/// 2026-09-29: "Sunan Abī Dāwūd 3331, allow me to search this up with diacritics, so strip it").
final class SearchFoldTests: XCTestCase {

    func testFoldsAcademicTransliteration() {
        XCTAssertEqual("Sunan Abī Dāwūd".foldingLatinDiacritics, "Sunan Abi Dawud")
        XCTAssertEqual("Ṣaḥīḥ al-Bukhārī".foldingLatinDiacritics, "Sahih al-Bukhari")
        XCTAssertEqual("Jāmiʿ at-Tirmidhī".foldingLatinDiacritics, "Jami at-Tirmidhi")
        XCTAssertEqual("Nasāʾī".foldingLatinDiacritics, "Nasai")
        XCTAssertEqual("ʻUmar ibn al-Khaṭṭāb".foldingLatinDiacritics, "Umar ibn al-Khattab")
        XCTAssertEqual("Mûsa, Ibrâhîm, Muḥammad ﷺ".foldingLatinDiacritics, "Musa, Ibrahim, Muhammad ﷺ")
        XCTAssertEqual("ẒĀHIR, ḌUḤĀ".foldingLatinDiacritics, "ZAHIR, DUHA")
    }

    /// A pasted "ā" can arrive as "a" plus a combining macron.
    func testDecomposedAccentsFold() {
        XCTAssertEqual("Abi\u{0304} Da\u{0304}wu\u{0304}d".foldingLatinDiacritics, "Abi Dawud")
    }

    /// Arabic keeps every mark (its own folds decide what they mean), and plain text comes back as is.
    func testArabicAndPlainTextPassThrough() {
        let arabic = "سُنَن أَبِي داوُد ١٥"
        XCTAssertEqual(arabic.foldingLatinDiacritics, arabic)
        let plain = "Sunan Abi Dawud 3331, 'A'ishah (may Allah be pleased with her)"
        XCTAssertEqual(plain.foldingLatinDiacritics, plain)
    }

    /// The Encyclopedia's byte fold and `IslamArticles.fold` must agree byte for byte ("-auditPacks").
    func testByteFoldMatchesStringFold() {
        let samples = [
            "Ṣaḥīḥ al-Bukhārī", "Jāmiʿ at-Tirmidhī 2664", "ʿĀʾishah (may Allah be pleased with her)",
            "Abi\u{0304} Da\u{0304}wu\u{0304}d", "İstanbul", "Mûsa, Ibrâhîm", "سُنَن أَبِي داوُد", "Plain text, 42.",
        ]
        for sample in samples {
            var bytes: [UInt8] = []
            HadeethEncStore.foldEnglish(sample, into: &bytes)
            XCTAssertEqual(bytes, Array(IslamArticles.fold(sample).utf8), sample)
        }
        XCTAssertEqual(IslamArticles.fold("Ṣaḥīḥ al-Bukhārī"), "sahih al bukhari")
    }

    /// The Quran search fold reads accents in the same single pass as its Arabic folds.
    @MainActor
    func testCleanSearchFoldsAccents() {
        let settings = Settings.shared
        XCTAssertEqual(settings.cleanSearch("Mūsā"), "musa")
        XCTAssertEqual(settings.cleanSearch("ʿImrān", whitespace: true), "imran")
        XCTAssertEqual(settings.cleanSearch("Al-Fātiḥah"), settings.cleanSearch("Al-Fatihah"))
    }

    /// The highlighter finds the accented word for a plain query and paints exactly the letters that
    /// matched: from the Ā the query's "a" folded onto, not the ʿayn mark before it (whole-word snapping
    /// was withdrawn on 2026-10-20).
    @MainActor
    func testHighlightFindsAccentedWord() {
        XCTAssertEqual(HighlightedSnippet.normalizeForSearchText("Ṣaḥīḥ", trimWhitespace: true), "sahih")
        let source = "Narrated ʿĀʾishah: the Prophet said"
        let spans = HighlightedSnippet.matchSpans(in: source, term: "aishah", guaranteeMatch: false)
        XCTAssertEqual(spans.count, 1)
        if let span = spans.first, let range = Range(span, in: source) {
            XCTAssertEqual(String(source[range]), "Āʾishah")
        }
    }

    /// No book's English search text still carries a letter the fold would change, so a plain query
    /// reaches every narration.
    func testPackSearchTextIsFolded() {
        for book in HadithCatalogBook.all {
            guard let url = HadithPack.bundledURL(book.slug), let pack = HadithPack(slug: book.slug, url: url) else {
                XCTFail("\(book.slug) did not open")
                continue
            }
            // Built with the fold the app queries with (Hadith-JSON-Engine's tools/pack/build.sh).
            XCTAssertTrue(pack.foldMatchesApp, "\(book.slug) was packed with another fold")
            var unfolded = 0
            pack.scanSearchFolds(in: 0..<pack.rows.count, isArabic: false) { _, fold in
                guard fold.contains(where: { $0 >= 0xC3 && ($0 <= 0xCD || $0 == 0xE1) }) else { return }
                if String(decoding: fold, as: UTF8.self).unicodeScalars.contains(where: LatinFold.affects) { unfolded += 1 }
            }
            XCTAssertEqual(unfolded, 0, book.slug)
        }
    }

    /// A narration spelled with accents is found by its plain spelling, through the same sweep the
    /// Hadith tab runs.
    func testPlainQueryFindsAccentedNarration() {
        var checked = 0
        for slug in ["tirmidhi", "muslim", "mishkat_almasabih"] {
            guard let url = HadithPack.bundledURL(slug), let pack = HadithPack(slug: slug, url: url) else {
                XCTFail("\(slug) did not open")
                continue
            }
            var found = 0
            for row in 0..<pack.rows.count where found < 3 {
                let strings = pack.strings(row: row)
                let words = (strings.text + " " + strings.narrator).split(whereSeparator: \.isWhitespace)
                guard let word = words.first(where: { word in
                    word.unicodeScalars.contains { LatinFold.base($0) != nil }
                        && HadithFold.english(String(word).foldingLatinDiacritics).count >= 3
                }) else { continue }
                let query = HadithFold.query(String(word))
                XCTAssertEqual(pack.matchingRows(in: row..<(row + 1), query: query, limit: 1), [row],
                               "\(slug) row \(row): \(word)")
                found += 1
            }
            checked += found
        }
        XCTAssertGreaterThan(checked, 0, "no accented narration found to check")
    }

    /// The packs' fold (`HadithFold.english`, copied from the engine) and the app's `LatinFold` read
    /// every Latin letter alike, so what the Hadith search finds is what the highlighter paints.
    func testPackFoldAgreesWithAppFold() {
        let strip = CharacterSet.punctuationCharacters.union(.symbols).union(.nonBaseCharacters)
        var disagreements: [String] = []
        for range: ClosedRange<UInt32> in [0x0020...0x036F, 0x1E00...0x1EFF] {
            for value in range {
                guard let scalar = Unicode.Scalar(value) else { continue }
                let app = String(String(scalar).foldingLatinDiacritics.unicodeScalars.filter { !strip.contains($0) }).lowercased()
                if HadithFold.english(String(scalar)) != app { disagreements.append(String(format: "U+%04X", value)) }
            }
        }
        XCTAssertEqual(disagreements, [])
        XCTAssertEqual(HadithFold.english("Sunan Abī Dāwūd, ʿĀʾishah, Muħammad"), "sunan abi dawud aishah muhammad")
    }
}

/// The hadith search's Match button (Abu, 2026-10-31: "Hadith search should support some things that
/// Quran search supports like exact match"): the word-edge rule the byte sweep applies to the prebuilt
/// folds (`HadithMatchRule`) and Exact's letter-for-letter check on the row's own text
/// (`HadithSearchFilters.LetterMatch`). Pure functions, no pack opened.
final class HadithMatchRuleTests: XCTestCase {

    // MARK: Word edges on the fold

    func testContainsFindsAnywhere() {
        // Inside a longer word, at a word's start or buried in it: anywhere.
        XCTAssertTrue(HadithMatchRule.contains.occurs("merc", in: "the mercies of allah"))
        XCTAssertTrue(HadithMatchRule.contains.occurs("mercy", in: "showmercy to them"))
        XCTAssertTrue(HadithMatchRule.contains.occurs("رب", in: "اربعة"))
        XCTAssertFalse(HadithMatchRule.contains.occurs("patience", in: "the mercies of allah"))
    }

    func testWholeWordNeedsBothEdges() {
        let rule = HadithMatchRule.wholeWord
        XCTAssertTrue(rule.occurs("mercy", in: "the mercy of allah"))
        XCTAssertFalse(rule.occurs("merc", in: "the mercies of allah"), "a leading edge alone is not a whole word")
        XCTAssertFalse(rule.occurs("mercy", in: "showmercy to them"), "a trailing edge alone is not a whole word")
        // The span's own edges count as word edges.
        XCTAssertTrue(rule.occurs("mercy", in: "mercy of allah"))
        XCTAssertTrue(rule.occurs("mercy", in: "of allah mercy"))
        XCTAssertTrue(rule.occurs("mercy", in: "mercy"))
        // A phrase needle: edges at the phrase's ends only.
        XCTAssertTrue(rule.occurs("mercy of", in: "the mercy of allah"))
        XCTAssertFalse(rule.occurs("mercy of", in: "the mercy offered"))
    }

    /// A hit the rule turns down is stepped over by one byte, so a real hit later in the row is found.
    func testRefusedHitStepsForwardOneByte() {
        XCTAssertTrue(HadithMatchRule.wholeWord.occurs("رب", in: "اربعة رب"))
        XCTAssertTrue(HadithMatchRule.wholeWord.occurs("ab", in: "xab ab"))
        XCTAssertTrue(HadithMatchRule.wholeWord.occurs("aa", in: "aaa aa"))
        XCTAssertFalse(HadithMatchRule.wholeWord.occurs("aa", in: "aaa aaa"))
        XCTAssertTrue(HadithMatchRule.startsWith.occurs("an", in: "banana and"))
    }

    func testStartsWithAndEndsWith() {
        XCTAssertTrue(HadithMatchRule.startsWith.occurs("merc", in: "the mercies of allah"))
        XCTAssertFalse(HadithMatchRule.startsWith.occurs("ercies", in: "the mercies of allah"))
        XCTAssertTrue(HadithMatchRule.endsWith.occurs("ies", in: "the mercies of allah"))
        XCTAssertFalse(HadithMatchRule.endsWith.occurs("merci", in: "the mercies of allah"))
        XCTAssertTrue(HadithMatchRule.endsWith.occurs("allah", in: "the mercies of allah"))
    }

    /// The English fold keeps its newlines and tabs, and a no-break space survives as C2 A0.
    func testEveryWhitespaceIsAWordEdge() {
        XCTAssertTrue(HadithMatchRule.wholeWord.occurs("mercy", in: "narrated abu hurairah\nmercy\tis wide"))
        XCTAssertTrue(HadithMatchRule.wholeWord.occurs("mercy", in: "his\u{00A0}mercy\u{00A0}is wide"))
        XCTAssertFalse(HadithMatchRule.wholeWord.occurs("mercy", in: "his\u{00A0}mercyis wide"))
    }

    func testEmptyNeedleAndShortFoldNeverMatch() {
        XCTAssertFalse(HadithMatchRule.wholeWord.occurs("", in: "mercy"))
        XCTAssertFalse(HadithMatchRule.contains.occurs("mercy of allah", in: "mercy"))
        XCTAssertFalse(HadithMatchRule.wholeWord.occurs("mercy", in: ""))
    }

    // MARK: The filters

    func testMatchFoldsIntoTheSession() {
        var filters = HadithSearchFilters()
        XCTAssertFalse(filters.hasSessionFilters)
        filters.match = .wholeWord
        XCTAssertTrue(filters.hasSessionFilters)
        XCTAssertEqual(filters.activeCount, 1)
        XCTAssertEqual(filters.activeCount(in: .oneChapter), 1)
        XCTAssertEqual(filters.needles(for: "mercy").rule, .wholeWord)
        XCTAssertEqual(filters.highlightWordRule, .wholeWord)
        filters.match = .exact
        XCTAssertEqual(filters.needles(for: "mercy").rule, .wholeWord, "Exact is whole words on the fold, letters on the row")
        XCTAssertEqual(filters.highlightWordRule, .wholeWord)
        filters.match = .startsWith
        XCTAssertEqual(filters.needles(for: "mer").rule, .startsWith)
        XCTAssertEqual(filters.highlightWordRule, .startsWith)
        filters.resetSession()
        XCTAssertEqual(filters.match, .contains)
        XCTAssertFalse(filters.hasSessionFilters)
        XCTAssertEqual(filters.needles(for: "mercy").rule, .contains)
        XCTAssertEqual(filters.highlightWordRule, .anywhere)
    }

    // MARK: Exact: letter for letter on the row

    func testExactEnglishKeepsCapitals() {
        let capital = HadithSearchFilters.LetterMatch("Mercy", words: .phrase)
        XCTAssertTrue(capital.matches(arabic: "", english: ["Narrated Abu Hurairah:", "The Mercy of Allah is wide."]))
        XCTAssertFalse(capital.matches(arabic: "", english: ["Narrated Abu Hurairah:", "The mercy of Allah is wide."]))
        let small = HadithSearchFilters.LetterMatch("mercy", words: .phrase)
        XCTAssertTrue(small.matches(arabic: "", english: ["", "The mercy of Allah is wide."]))
        XCTAssertFalse(small.matches(arabic: "", english: ["", "The mercies of Allah are wide."]))
        // Punctuation around a word is not a letter; the words of a phrase stay consecutive.
        let phrase = HadithSearchFilters.LetterMatch("mercy of Allah", words: .phrase)
        XCTAssertTrue(phrase.matches(arabic: "", english: ["", "\"The mercy of Allah,\" he said."]))
        XCTAssertFalse(phrase.matches(arabic: "", english: ["", "The mercy of the Lord, Allah."]))
    }

    /// A Latin query reads the narrator line and the narration together, as the fold stores them.
    func testExactEnglishSpansNarratorAndText() {
        let all = HadithSearchFilters.LetterMatch("Hurairah mercy", words: .allWords)
        XCTAssertTrue(all.matches(arabic: "", english: ["Narrated Abu Hurairah:", "The mercy of Allah is wide."]))
        XCTAssertFalse(all.matches(arabic: "", english: ["Narrated Abu Hurairah:", "The Mercy of Allah is wide."]))
        let any = HadithSearchFilters.LetterMatch("Hurairah patience", words: .anyWord)
        XCTAssertTrue(any.matches(arabic: "", english: ["Narrated Abu Hurairah:", "The mercy of Allah is wide."]))
        XCTAssertFalse(any.matches(arabic: "", english: ["Narrated Anas:", "The mercy of Allah is wide."]))
    }

    /// Marks go, letter forms stay: أ and ا, ة and ه, ى and ي are different letters here.
    func testExactArabicKeepsLetterFormsAndDropsMarks() {
        let taMarbuta = HadithSearchFilters.LetterMatch("رحمة", words: .phrase)
        XCTAssertTrue(taMarbuta.matches(arabic: "إِنَّ رَحْمَةَ اللَّهِ وَاسِعَةٌ", english: []))
        XCTAssertFalse(taMarbuta.matches(arabic: "إِنَّ رَحْمَهُ اللَّهُ", english: []))
        XCTAssertFalse(taMarbuta.matches(arabic: "بِرَحْمَةِ اللَّهِ", english: []), "a prefixed word is not the whole word")

        let hamza = HadithSearchFilters.LetterMatch("أربعة", words: .phrase)
        XCTAssertTrue(hamza.matches(arabic: "عَلَى أَرْبَعَةٍ", english: []))
        XCTAssertFalse(hamza.matches(arabic: "عَلَى اربعة", english: []))

        let maqsurah = HadithSearchFilters.LetterMatch("على", words: .phrase)
        XCTAssertTrue(maqsurah.matches(arabic: "عَلَى أَرْبَعَةٍ", english: []))
        XCTAssertFalse(maqsurah.matches(arabic: "علي بن أبي طالب", english: []))

        // A query typed with tashkeel matches the same letters written bare.
        let vocalized = HadithSearchFilters.LetterMatch("رَحْمَة", words: .phrase)
        XCTAssertTrue(vocalized.matches(arabic: "رحمة الله", english: []))
    }

    func testExactArabicReadsTheArabicOnly() {
        let arabic = HadithSearchFilters.LetterMatch("رحمة", words: .phrase)
        XCTAssertFalse(arabic.matches(arabic: "", english: ["", "رحمة"]))
        let english = HadithSearchFilters.LetterMatch("mercy", words: .phrase)
        XCTAssertFalse(english.matches(arabic: "mercy", english: ["", ""]))
    }
}
