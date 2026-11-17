import XCTest
@testable import iPhone

/// The cross-language search highlight (`CrossLanguageWordHighlight`): an Arabic query lights the
/// aligned English words and an English query the Arabic ones. These pin its PRECISION rules, each
/// measured over the whole Quran and a hadith sample on 2026-11-14 before it was written:
///
/// * a word of the text that merely BEGINS a longer term is not that term ("themselves" lit every
///   "the", "Allah" lit "all", "forgiving" lit "for": 5.4% of the lit Quran rows carried one);
/// * a glue word is never lit on its own ("our", "your", "most");
/// * "Allah" names only the word that is Allah (the gloss pack repeats a phrase gloss on both of its
///   words, so يتوب and الله each read "Allah accepts repentance": 6.2% of the lit rows);
/// * the corpus lexicon fills a translation line only when the matched word's own gloss found nothing
///   in it (the union doubled the rows with four or more words lit for no row gained);
/// * an invisible direction mark glued to a hadith word does not hide it (2.7% of Bukhari's words,
///   13% of Riyad as-Salihin's), and the modern spelling of a word the mushaf writes with a waw
///   (الصلاة, الزكاة, الحياة) reaches the mushaf's key.
final class CrossLanguageHighlightTests: XCTestCase {

    // MARK: - Helpers

    private func lit(_ spans: [NSRange], in text: String) -> [String] {
        let ns = text as NSString
        return spans.sorted { $0.location < $1.location }.map { ns.substring(with: $0) }
    }

    private func lit(_ terms: [String], _ text: String) -> [String] {
        lit(CrossLanguageWordHighlight.wordSpans(of: terms, in: text), in: text)
    }

    /// Which whitespace tokens of `text` the spans cover, so an Arabic expectation is an index and
    /// never a second copy of a vowelled string.
    private func tokenIndices(_ spans: [NSRange], in text: String) -> [Int] {
        let tokens = WordTokens.ranges(in: text)
        return tokens.indices.filter { index in
            spans.contains { NSIntersectionRange($0, tokens[index]).length > 0 }
        }
    }

    /// The Quran text, the gloss pack and the lexicon, all loaded. The lexicon builds off the main
    /// thread and its lookups answer empty (uncached) until it is there.
    @MainActor
    private func ready() async throws {
        await QuranData.shared.waitUntilLoaded()
        try XCTSkipIf(Settings.shared.displayQiraahForArabic != nil,
                      "the gloss pack is Hafs: launch once with -displayQiraah \"\" first")
        try XCTSkipUnless(WordByWordStore.isBundled, "no gloss pack in this bundle")
        CrossLanguageWordHighlight.prewarmLexicon()
        for _ in 0..<900 {
            if !CrossLanguageWordHighlight.englishTermsForUnalignedArabicQuery("الصبر").isEmpty { return }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTFail("the cross-language lexicon never became ready")
    }

    @MainActor
    private func ayahText(_ surah: Int, _ ayah: Int) throws -> (arabic: String, saheeh: String, mustafa: String) {
        let found = try XCTUnwrap(QuranData.shared.ayah(surah: surah, ayah: ayah), "\(surah):\(ayah)")
        return (found.rawArabicText(surahId: surah), found.textEnglishSaheeh, found.textEnglishMustafa)
    }

    @MainActor
    private func ownTerms(_ query: String, _ surah: Int, _ ayah: Int) throws -> [String] {
        let text = try ayahText(surah, ayah)
        return CrossLanguageWordHighlight.englishTermsForArabicMatch(
            query: query, surah: surah, ayah: ayah, rawText: text.arabic, displayText: text.arabic)
    }

    // MARK: - Word to word matching

    func testALongTermDoesNotLightTheShortWordItBeginsWith() {
        XCTAssertEqual(lit(["themselves"], "They wronged the people and themselves"), ["themselves"])
        XCTAssertEqual(lit(["allah"], "All praise is for Allah"), ["Allah"])
        XCTAssertEqual(lit(["forgiving"], "Ask for His forgiveness"), ["forgiveness"])
        XCTAssertEqual(lit(["sincere"], "a sin and a sincere deed"), ["sincere"])
    }

    func testAGlueWordIsNeverLitOnItsOwn() {
        XCTAssertEqual(lit(["yourselves"], "It is only for your own souls"), [])
        XCTAssertEqual(lit(["our", "eyes"], "under Our observation and before your eyes"), ["eyes"])
        XCTAssertEqual(lit(["most", "merciful"], "the Most Compassionate, Most Merciful"), ["Merciful"])
    }

    /// What the narrower rules must keep: an inflected or derived term still finds its base word, a
    /// base term its derived word, and two lit words still join across glue.
    func testAnInflectedTermStillLightsItsBaseWord() {
        XCTAssertEqual(lit(["used"], "what they use"), ["use"])
        XCTAssertEqual(lit(["pray"], "the prayer"), ["prayer"])
        XCTAssertEqual(lit(["mercy"], "He is merciful"), ["merciful"])
        XCTAssertEqual(lit(["believers"], "those who believe"), ["believe"])
        XCTAssertEqual(lit(["establish", "prayer"], "and establish the prayer"), ["establish the prayer"])
    }

    /// صلاتهم is صلاة + هم: the taa marbuta is written as a plain taa before the pronoun. The search
    /// fold writes ة as ه, so the restored form has to be the ه one to meet a typed صلاة.
    func testMatchVariantsMeetAcrossTheTaaMarbuta() {
        let prayer = HighlightedSnippet.normalizeForSearchText("صلاة", trimWhitespace: true)
        let theirPrayer = HighlightedSnippet.normalizeForSearchText("صلاتهم", trimWhitespace: true)
        XCTAssertTrue(CrossLanguageWordHighlight.arabicMatchVariants(of: theirPrayer).contains(prayer))
    }

    // MARK: - What a gloss names

    /// 23:27 بِأَعۡيُنِنَا is glossed "under Our eyes".
    @MainActor
    func testAPossessiveIsNotAContentWordOfItsGloss() async throws {
        try await ready()
        let terms = try ownTerms("بأعيننا", 23, 27)
        XCTAssertTrue(terms.contains("eyes"), "\(terms)")
        XCTAssertFalse(terms.contains("our"), "\(terms)")
    }

    /// 9:27 يَتُوبُ ٱللَّهُ: the pack gives BOTH words the phrase gloss "Allah accepts repentance".
    @MainActor
    func testAWordThatSharesAllahsGlossDoesNotNameAllah() async throws {
        try await ready()
        let verb = try ownTerms("يتوب", 9, 27)
        XCTAssertTrue(verb.contains("repentance"), "\(verb)")
        XCTAssertFalse(verb.contains("allah"), "\(verb)")
        XCTAssertEqual(try ownTerms("الله", 9, 27), ["allah"])
    }

    @MainActor
    func testLexiconTermsOfAnotherWordLeaveAllahOut() async throws {
        try await ready()
        let mercy = CrossLanguageWordHighlight.englishTermsForUnalignedArabicQuery("رحمة")
        XCTAssertTrue(mercy.contains("mercy"), "\(mercy)")
        XCTAssertFalse(mercy.contains("allah"), "\(mercy)")
        XCTAssertEqual(CrossLanguageWordHighlight.englishTermsForUnalignedArabicQuery("الله"), ["allah"])
        XCTAssertEqual(CrossLanguageWordHighlight.englishTermsForUnalignedArabicQuery("والله"), ["allah"])
    }

    /// A hadith's Arabic has no alignment of its own: an English "Allah" lights the two words that
    /// are Allah, not شاء and رحمة, whose Quran glosses happen to mention Him.
    @MainActor
    func testEnglishAllahLightsTheNameAndNothingElse() async throws {
        try await ready()
        let arabic = "إِنْ شَاءَ اللَّهُ وَرَحْمَةُ اللَّهِ"
        let spans = CrossLanguageWordHighlight.arabicSpansForEnglishQuery("Allah", arabicText: arabic)
        XCTAssertEqual(tokenIndices(spans, in: arabic), [2, 4])
    }

    // MARK: - Hadith text

    @MainActor
    func testADirectionMarkDoesNotHideAWord() async throws {
        try await ready()
        let plain = "وَرَحْمَةُ اللَّهِ"
        let marked = "وَرَحْمَةُ\u{200F}\u{200F} اللَّهِ"
        XCTAssertEqual(tokenIndices(CrossLanguageWordHighlight.arabicSpansForEnglishQuery("mercy", arabicText: plain), in: plain), [0])
        XCTAssertEqual(tokenIndices(CrossLanguageWordHighlight.arabicSpansForEnglishQuery("mercy", arabicText: marked), in: marked), [0])
    }

    /// The mushaf writes ٱلصَّلَوٰة; a hadith and a keyboard write الصلاة.
    @MainActor
    func testModernSpellingReachesTheMushafsWord() async throws {
        try await ready()
        let prayer = CrossLanguageWordHighlight.englishTermsForUnalignedArabicQuery("الصلاة")
        XCTAssertTrue(prayer.contains("prayer"), "\(prayer)")
        let zakah = CrossLanguageWordHighlight.englishTermsForUnalignedArabicQuery("الزكاة")
        XCTAssertTrue(zakah.contains("zakah"), "\(zakah)")
        let hisPrayer = CrossLanguageWordHighlight.englishTermsForUnalignedArabicQuery("صلاته")
        XCTAssertTrue(hisPrayer.contains("prayer"), "\(hisPrayer)")
        let arabic = "أَقَامَ الصَّلَاةَ"
        let spans = CrossLanguageWordHighlight.arabicSpansForEnglishQuery("prayer", arabicText: arabic)
        XCTAssertEqual(tokenIndices(spans, in: arabic), [1])
    }

    /// A hadith's words carry their punctuation ("بِالصَّلاَةِ،"): the word is lit, its comma is not.
    @MainActor
    func testALitHadithWordLeavesItsPunctuationUnlit() async throws {
        try await ready()
        let arabic = "أَبْرَدَ بِالصَّلاَةِ، يَعْنِي الْجُمُعَةَ."
        let spans = CrossLanguageWordHighlight.arabicSpansForEnglishQuery("prayer", arabicText: arabic)
        XCTAssertEqual(lit(spans, in: arabic), ["بِالصَّلاَةِ"])
    }

    // MARK: - The hadith dictionary

    private func hadith(_ query: String, arabic: String = "", narrator: String = "", text: String = "")
    -> (arabic: [NSRange], narrator: [NSRange], text: [NSRange]) {
        CrossLanguageWordHighlight.hadithSpans(query: query, arabic: arabic, narrator: narrator, text: text)
    }

    /// الوضوء is no word of the Quran, and no dictionary drawn from the Quran could hold a narrator's
    /// name: both come from the hadith shelf's own two languages.
    @MainActor
    func testAHadithWordLightsItsEnglish() async throws {
        try await ready()
        let english = "He made ablution and then prayed two rak'ahs."
        XCTAssertEqual(lit(hadith("الوضوء", text: english).text, in: english), ["ablution"])
        let narrator = "Narrated `Aisha:"
        XCTAssertEqual(lit(hadith("عائشة", narrator: narrator).narrator, in: narrator), ["Aisha"])
    }

    @MainActor
    func testAnEnglishQueryLightsTheHadithsArabicWord() async throws {
        try await ready()
        let arabic = "عَنْ عَائِشَةَ، أَنَّ النَّبِيَّ أَحْسَنَ الْوُضُوءَ"
        XCTAssertEqual(tokenIndices(hadith("ablution", arabic: arabic).arabic, in: arabic), [5])
        XCTAssertEqual(tokenIndices(hadith("Aisha", arabic: arabic).arabic, in: arabic), [1])
        XCTAssertEqual(tokenIndices(hadith("prophet", arabic: arabic).arabic, in: arabic), [3])
        // The lit word is the word: the comma glued to عَائِشَةَ stays unlit.
        XCTAssertEqual(lit(hadith("Aisha", arabic: arabic).arabic, in: arabic), ["عَائِشَةَ"])
    }

    /// كتاب begins with a ك that is also a preposition. The dictionary has كتاب itself, so it is
    /// never read as ك + تاب ("repented"), which is a word of its own.
    @MainActor
    func testAWordThatIsAKeyIsNotPeeledFurther() async throws {
        try await ready()
        let english = "He repented and then read the book."
        XCTAssertEqual(lit(hadith("كتاب", text: english).text, in: english), ["book"])
        XCTAssertEqual(lit(hadith("تاب", text: english).text, in: english), ["repented"])
    }

    /// مشكاة is a word of the Quran (24:35) the hadith shelf has too few times for the dictionary
    /// to carry. The Quran-derived lexicon still answers for it.
    @MainActor
    func testAWordTheDictionaryLacksFallsBackToTheQuranLexicon() async throws {
        try await ready()
        let english = "a niche in which there is a lamp"
        XCTAssertEqual(lit(hadith("مشكاة", text: english).text, in: english), ["niche"])
    }

    @MainActor
    func testAllahLightsOnlyTheNameInAHadith() async throws {
        try await ready()
        let arabic = "إِنْ شَاءَ اللَّهُ وَرَحْمَةُ اللَّهِ"
        XCTAssertEqual(tokenIndices(hadith("Allah", arabic: arabic).arabic, in: arabic), [2, 4])
        let english = "If Allah wills, and the mercy of Allah"
        XCTAssertEqual(lit(hadith("الله", text: english).text, in: english), ["Allah", "Allah"])
    }

    func testTheHadithDictionaryIsInTheBundle() {
        XCTAssertTrue(CrossLanguageWordHighlight.hasHadithDictionary,
                      "no usable HadithLexicon.bin: run Scripts/build_hadith_lexicon.py, and if the builder's format moved, accept it in hadithDictionaryFormats")
    }

    /// The file's layout on a table written out by hand, and every damaged form of it refused.
    func testTheHadithDictionaryCodec() {
        func u32(_ value: UInt32) -> [UInt8] {
            [UInt8(value & 0xFF), UInt8(value >> 8 & 0xFF), UInt8(value >> 16 & 0xFF), UInt8(value >> 24)]
        }
        let key = Array("وضو".utf8)
        let words = ["ablution", "wudu"]
        var bytes = u32(0x3158_4C48) + u32(1) + u32(1)
        bytes += [UInt8(key.count), 0] + key + [UInt8(words.count)]
        for word in words {
            bytes += [UInt8(word.utf8.count)] + Array(word.utf8)
        }
        XCTAssertEqual(CrossLanguageWordHighlight.decodeHadithDictionary(Data(bytes)), ["وضو": ["ablution", "wudu"]])
        XCTAssertNil(CrossLanguageWordHighlight.decodeHadithDictionary(Data()))
        XCTAssertNil(CrossLanguageWordHighlight.decodeHadithDictionary(Data(bytes.dropLast())))
        XCTAssertNil(CrossLanguageWordHighlight.decodeHadithDictionary(Data(bytes + [0])))
        var wrongMagic = bytes
        wrongMagic[0] &+= 1
        XCTAssertNil(CrossLanguageWordHighlight.decodeHadithDictionary(Data(wrongMagic)))
        var newerFormat = bytes
        newerFormat[4] = 2
        XCTAssertNil(CrossLanguageWordHighlight.decodeHadithDictionary(Data(newerFormat)))
    }

    /// The key is the folded word with the article, and what is written onto the article, off.
    /// A bare و is not the key's to drop: the lookup tries the word with it and then without.
    func testTheHadithKeyDropsTheArticleAndItsPrefixes() {
        for written in ["الصلاه", "والصلاه", "بالصلاه", "للصلاه", "فللصلاه", "صلاه"] {
            XCTAssertEqual(CrossLanguageWordHighlight.hadithKey(written), "صلاه", written)
        }
        XCTAssertEqual(CrossLanguageWordHighlight.hadithKey("وصلاه"), "وصلاه")
        XCTAssertEqual(CrossLanguageWordHighlight.hadithKey("الا"), "الا")
    }

    // MARK: - The alignment pack

    @MainActor
    private func spans(_ query: String, _ surah: Int, _ ayah: Int, wordRule: SearchWordRule = .anywhere) throws
    -> CrossLanguageWordHighlight.QuranSpans {
        let text = try ayahText(surah, ayah)
        return CrossLanguageWordHighlight.quranSpans(
            query: query, surah: surah, ayah: ayah, rawText: text.arabic, displayText: text.arabic,
            saheeh: text.saheeh, mustafa: text.mustafa, wordRule: wordRule)
    }

    /// 57:10 ends خَبِيرٞ, glossed "(is) All-Aware". Saheeh says "Acquainted": no gloss word, no
    /// lexicon word, and before the pack nothing was lit either way.
    @MainActor
    func testAnArabicQueryLightsTheTranslationsOwnWord() async throws {
        try await ready()
        let text = try ayahText(57, 10)
        XCTAssertEqual(lit(try spans("خبير", 57, 10).saheeh, in: text.saheeh), ["Acquainted"])
    }

    @MainActor
    func testAnEnglishQueryLightsTheArabicUnderWhatMatched() async throws {
        try await ready()
        let text = try ayahText(57, 10)
        let last = WordTokens.count(in: text.arabic) - 1
        XCTAssertEqual(tokenIndices(try spans("Acquainted", 57, 10).arabic, in: text.arabic), [last])
        // A phrase typed halfway: both of its words, though "pa" is no word of any gloss.
        let fatihah = try ayahText(1, 6)
        XCTAssertEqual(tokenIndices(try spans("straight pa", 1, 6).arabic, in: fatihah.arabic), [1, 2])
    }

    /// Letters that only occur INSIDE a word are painted where they are; they are not that word,
    /// and its Arabic stays unlit.
    @MainActor
    func testLettersInsideAWordLightNoArabic() async throws {
        try await ready()
        XCTAssertEqual(try spans("aight", 1, 6).arabic, [])
    }

    /// Under a word rule the match is already a whole word, a word's start or its end, and the
    /// Arabic follows whatever was painted.
    @MainActor
    func testAWordRuleDecidesWhatCountsAsMatched() async throws {
        try await ready()
        let text = try ayahText(1, 6)
        XCTAssertEqual(tokenIndices(try spans("ight", 1, 6, wordRule: .endsWith).arabic, in: text.arabic), [2])
        XCTAssertEqual(tokenIndices(try spans("path", 1, 6, wordRule: .wholeWord).arabic, in: text.arabic), [1])
    }

    /// 3:58 ٱلۡحَكِيمِ, "the precise [and wise] message". The pack knows Saheeh's own word for it,
    /// "precise", and that is what lights (the gloss says "wise", which is only in the brackets).
    @MainActor
    func testThePackLightsTheTranslationsOwnWordBeforeTheGlossWord() async throws {
        try await ready()
        let text = try ayahText(3, 58)
        XCTAssertEqual(lit(try spans("الحكيم", 3, 58).saheeh, in: text.saheeh), ["precise"])
    }

    /// The same ayah the other way: "wise" stands inside the translator's own brackets, which the
    /// pack never aligns, so the gloss answers.
    @MainActor
    func testWhereThePackHasNothingTheGlossStillAnswers() async throws {
        try await ready()
        let text = try ayahText(3, 58)
        XCTAssertEqual(tokenIndices(try spans("wise", 3, 58).arabic, in: text.arabic), [6])
    }

    // MARK: - The lexicon is not asked about a typed word the pack's line has no word for

    /// 4:84 وَٱللَّهُ أَشَدُّ بَأۡسٗا وَأَشَدُّ تَنكِيلٗا, Khattab: "Allah is far superior in might and in
    /// punishment." The pack has no word for بَأۡسٗا here ("might" is a glue word) and neither has its
    /// gloss. The Quran-wide lexicon used to answer "punishment", which is تَنكِيلٗا. Read by hand,
    /// what it lit on a line the pack knows was right 11 times in 40.
    @MainActor
    func testTheLexiconIsNotAskedAboutATypedWordOfALineThePackKnows() async throws {
        try await ready()
        let text = try ayahText(4, 84)
        XCTAssertEqual(lit(try spans("بأسا", 4, 84).mustafa, in: text.mustafa), [])
    }

    /// A row found by its meaning: 69:31 says ٱلۡجَحِيمَ and the query is جهنم. No word of the ayah
    /// was typed, there is nothing for the pack to follow, and the lexicon still lights "Hellfire".
    @MainActor
    func testARowWithoutTheTypedWordStillAsksTheLexicon() async throws {
        try await ready()
        let text = try ayahText(69, 31)
        XCTAssertEqual(lit(try spans("جهنم", 69, 31).saheeh, in: text.saheeh), ["Hellfire"])
    }

    // MARK: - The lexicon is a fallback

    /// 1:6 ٱهۡدِنَا ٱلصِّرَٰطَ ٱلۡمُسۡتَقِيمَ, "Guide us to the straight path". الصراط is glossed "(to) the
    /// path" and that word is in both translations, so the lexicon's other words for the family
    /// ("straight", from every صراط مستقيم) have no business in the line.
    @MainActor
    func testTheLexiconDoesNotAddToALineTheGlossAlreadyLit() async throws {
        try await ready()
        let text = try ayahText(1, 6)
        let spans = CrossLanguageWordHighlight.quranSpans(
            query: "الصراط", surah: 1, ayah: 6, rawText: text.arabic, displayText: text.arabic,
            saheeh: text.saheeh, mustafa: text.mustafa)
        XCTAssertEqual(lit(spans.saheeh, in: text.saheeh), ["path"])
        XCTAssertEqual(lit(spans.mustafa, in: text.mustafa), ["Path"])
    }

    /// 1:2 ٱلۡعَٰلَمِينَ is glossed "of the universe"; both translations say "worlds". The gloss finds
    /// nothing, so the lexicon's wording is what lights the line.
    @MainActor
    func testTheLexiconFillsALineTheGlossLeftEmpty() async throws {
        try await ready()
        let text = try ayahText(1, 2)
        let spans = CrossLanguageWordHighlight.quranSpans(
            query: "العالمين", surah: 1, ayah: 2, rawText: text.arabic, displayText: text.arabic,
            saheeh: text.saheeh, mustafa: text.mustafa)
        XCTAssertEqual(lit(spans.saheeh, in: text.saheeh), ["worlds"])
        XCTAssertEqual(lit(spans.mustafa, in: text.mustafa), ["worlds"])
    }

    /// The same ayah the other way: "straight" is ٱلۡمُسۡتَقِيمَ by the ayah's own alignment, and the
    /// lexicon's ٱلصِّرَٰطَ (a neighbour in every occurrence) is not added to it.
    @MainActor
    func testAnEnglishQueryKeepsToTheAyahsOwnAlignment() async throws {
        try await ready()
        let text = try ayahText(1, 6)
        let spans = CrossLanguageWordHighlight.quranSpans(
            query: "straight", surah: 1, ayah: 6, rawText: text.arabic, displayText: text.arabic,
            saheeh: text.saheeh, mustafa: text.mustafa)
        XCTAssertEqual(tokenIndices(spans.arabic, in: text.arabic), [2])
    }

    // MARK: - The transliteration line

    @MainActor
    private func transliterationSpans(_ query: String, _ surah: Int, _ ayah: Int) throws
    -> CrossLanguageWordHighlight.QuranSpans {
        let text = try ayahText(surah, ayah)
        let line = try XCTUnwrap(QuranData.shared.ayah(surah: surah, ayah: ayah)).textTransliteration
        return CrossLanguageWordHighlight.quranSpans(
            query: query, surah: surah, ayah: ayah, rawText: text.arabic, displayText: text.arabic,
            saheeh: text.saheeh, mustafa: text.mustafa, transliteration: line)
    }

    /// 80:14 "Marfoo'atim mutah-hara": "mutah" is half of the line's second word, which spells
    /// مُّطَهَّرَةِۭ. That word lights, and so does its English (Abu, 2026-11-16: only "mutah" was lit).
    @MainActor
    func testATransliterationMatchLightsTheArabicWordItSpells() async throws {
        try await ready()
        let text = try ayahText(80, 14)
        let spans = try transliterationSpans("mutah", 80, 14)
        XCTAssertEqual(tokenIndices(spans.arabic, in: text.arabic), [1])
        XCTAssertEqual(lit(spans.saheeh, in: text.saheeh), ["purified"])
    }

    /// 56:79 "Laa yamassuhooo illal mutahharoon": "illal" carries the next word's article, and that
    /// one letter is not enough to light ٱلۡمُطَهَّرُونَ; the word after it is its own.
    @MainActor
    func testATransliterationWordLightsOnlyTheWordsItReallyCovers() async throws {
        try await ready()
        let text = try ayahText(56, 79)
        XCTAssertEqual(tokenIndices(try transliterationSpans("illal", 56, 79).arabic, in: text.arabic), [2])
        XCTAssertEqual(tokenIndices(try transliterationSpans("mutahharoon", 56, 79).arabic, in: text.arabic), [3])
    }

    /// Two letters light nothing through the line: they match half of it.
    @MainActor
    func testAShortQueryLightsNothingThroughTheTransliteration() async throws {
        try await ready()
        let text = try ayahText(56, 79)
        let line = try XCTUnwrap(QuranData.shared.ayah(surah: 56, ayah: 79)).textTransliteration
        XCTAssertTrue(CrossLanguageWordHighlight.transliterationTokens(
            query: "la", transliteration: line, surah: 56, ayah: 79,
            rawText: text.arabic, displayText: text.arabic).isEmpty)
    }

    // MARK: - The transliteration line, the other way

    /// What the transliteration line lights for `query`, as the pieces of the line.
    @MainActor
    private func litTransliteration(_ query: String, _ surah: Int, _ ayah: Int) throws -> [String] {
        let line = try XCTUnwrap(QuranData.shared.ayah(surah: surah, ayah: ayah)).textTransliteration
        return try transliterationSpans(query, surah, ayah).transliteration
            .map { (line as NSString).substring(with: $0) }
    }

    /// 80:14 the other way: typing مطهرة lights "mutah-hara", one word written in two pieces, through
    /// its hyphen, and the word before it stays dark (Abu, 2026-11-16).
    @MainActor
    func testAnArabicQueryLightsTheTransliterationWordThatSpellsIt() async throws {
        try await ready()
        XCTAssertEqual(try litTransliteration("مطهرة", 80, 14), ["mutah-hara"])
        XCTAssertEqual(try litTransliteration("مرفوعة", 80, 14), ["Marfoo'atim"])
    }

    /// 56:79 "Laa yamassuhooo illal mutahharoon": إلا is "illal" though that word ends in the next
    /// one's article, and المطهرون is its own word, not the "l" before it.
    @MainActor
    func testATransliterationWordIsLitByTheArabicWordThatOwnsMostOfIt() async throws {
        try await ready()
        XCTAssertEqual(try litTransliteration("إلا", 56, 79), ["illal"])
        XCTAssertEqual(try litTransliteration("المطهرون", 56, 79), ["mutahharoon"])
    }

    /// 1:6 "Ihdinas-Siraatal-Mustaqeem" is three Arabic words in one written word: the hyphens cut it.
    @MainActor
    func testAHyphenatedTransliterationIsReadInPieces() async throws {
        try await ready()
        XCTAssertEqual(try litTransliteration("الصراط", 1, 6), ["Siraatal"])
        XCTAssertEqual(try litTransliteration("المستقيم", 1, 6), ["Mustaqeem"])
    }

    /// A word reached through a TRANSLATION line lights its transliteration too ("purified" is
    /// مُّطَهَّرَةِۭ, "mutah-hara"). One found in the line itself does not: the typed letters are already
    /// painted there, and a match is never grown to its word.
    @MainActor
    func testAnEnglishQueryLightsTheTransliterationOfTheWordItMeans() async throws {
        try await ready()
        XCTAssertEqual(try litTransliteration("purified", 80, 14), ["mutah-hara"])
        XCTAssertEqual(try litTransliteration("mutah", 80, 14), [])
    }

    /// 5:39 ends "'alaih; innal laaha Ghafoorur Raheem". The pause took the last vowel of عَلَيۡهِ, and
    /// the "i" after it is إِنَّ's own: each word lights its whole word of the line.
    @MainActor
    func testAPauseDoesNotMoveALetterToTheWordBeforeIt() async throws {
        try await ready()
        let text = try ayahText(5, 39)
        let line = try XCTUnwrap(QuranData.shared.ayah(surah: 5, ayah: 39)).textTransliteration
        func lit(_ token: Int) -> [String] {
            CrossLanguageWordHighlight.transliterationSpans(
                of: [token], transliteration: line, surah: 5, ayah: 39,
                rawText: text.arabic, displayText: text.arabic
            ).map { (line as NSString).substring(with: $0) }
        }
        XCTAssertEqual(lit(9), ["'alaih"])
        XCTAssertEqual(lit(10), ["innal"])
        XCTAssertEqual(lit(11), ["laaha"])
    }

    /// 22:6 writes عَلَىٰ كُلِّ as one word, "'alaakulli". Each Arabic word lights its own letters of it.
    @MainActor
    func testTwoArabicWordsWrittenAsOneAreLitByTheirLetters() async throws {
        try await ready()
        XCTAssertEqual(try litTransliteration("كل", 22, 6), ["kulli"])
        XCTAssertEqual(try litTransliteration("على", 22, 6), ["'alaa"])
    }

    /// 2:19 "wa-barq(unwi)": the ending the line keeps in brackets is part of the word, and the
    /// bracket that opens inside it is closed.
    @MainActor
    func testAnEndingInBracketsIsLitWithItsWord() async throws {
        try await ready()
        XCTAssertEqual(try litTransliteration("برق", 2, 19), ["wa-barq(unwi)"])
    }

    /// A row that does not show the line passes none, and nothing is asked of it.
    @MainActor
    func testNoTransliterationLineLightsNothing() async throws {
        try await ready()
        XCTAssertTrue(try spans("مطهرة", 80, 14).transliteration.isEmpty)
    }
}
