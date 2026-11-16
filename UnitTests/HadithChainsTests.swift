import XCTest
@testable import iPhone

/// The chains of narrators (HadithChains.swift): the app decodes from the shipped pack exactly the names
/// and words of transmission that Scripts/build_hadith_chains.py read (its generated
/// `HadithChainSamples`), out of the very narration the reader sees, and builds a diagram from them.
final class HadithChainsTests: XCTestCase {
    private func book(_ slug: String) throws -> HadithBookData {
        let url = try XCTUnwrap(HadithPack.bundledURL(slug), slug)
        return HadithBookData(pack: try XCTUnwrap(HadithPack(slug: slug, url: url), slug))
    }

    private func flatten(_ column: [(String, [String])]) -> [String] {
        column.map { "\($0.0)|\($0.1.joined(separator: "+"))" }
    }

    func testDecoderMatchesTheScript() throws {
        XCTAssertGreaterThan(HadithChainSamples.all.count, 20)
        var books: [String: HadithBookData] = [:]
        for sample in HadithChainSamples.all {
            let data = try books[sample.slug] ?? book(sample.slug)
            books[sample.slug] = data
            let hadith = try XCTUnwrap(data.hadith(numbered: sample.idInBook), "\(sample.slug) \(sample.idInBook)")
            let parsed = try XCTUnwrap(HadithChainDecoder.parse(sample.code), sample.code)
            let words = HadithChainDecoder.tokens(hadith.arabic)
            XCTAssertEqual(parsed.tokenCount, words.count, "\(sample.slug) \(sample.idInBook): the narration's words moved")
            let columns = HadithChainDecoder.columns(parsed, words)
            XCTAssertEqual(flatten(columns.top), sample.top, "\(sample.slug) \(sample.idInBook)")
            XCTAssertEqual(columns.branches.map(flatten), sample.branches, "\(sample.slug) \(sample.idInBook)")
        }
    }

    private func pack() throws -> HadithChainPack {
        let url = try XCTUnwrap(HadithChainPack.bundledURL(), "HadithChains.qpk is not bundled")
        return try XCTUnwrap(HadithChainPack(url: url), "HadithChains.qpk does not open")
    }

    func testEveryBookOfThePackReadsBackInOrder() throws {
        let pack = try pack()
        XCTAssertEqual(pack.books.count, 11)
        XCTAssertGreaterThan(pack.chainCount, 20_000)
        var total = 0
        for (slug, book) in pack.books {
            let chains = pack.chains(slug: slug)
            XCTAssertEqual(chains.count, book.count, slug)
            XCTAssertEqual(chains.map(\.idInBook), chains.map(\.idInBook).sorted(), slug)
            XCTAssertTrue(chains.allSatisfy { HadithChainDecoder.parse($0.code) != nil }, slug)
            total += chains.count
        }
        XCTAssertEqual(total, pack.chainCount)
        XCTAssertNil(pack.code(slug: "bukhari", idInBook: 0))
        XCTAssertFalse(pack.contains(slug: "nawawi40", idInBook: 1))
    }

    /// The binary search finds, for every sample, exactly the code the script wrote for it.
    func testThePackHoldsTheScriptsCodes() throws {
        let pack = try pack()
        for sample in HadithChainSamples.all {
            XCTAssertTrue(pack.contains(slug: sample.slug, idInBook: sample.idInBook), "\(sample.slug) \(sample.idInBook)")
            XCTAssertEqual(pack.code(slug: sample.slug, idInBook: sample.idInBook), sample.code, "\(sample.slug) \(sample.idInBook)")
        }
    }

    func testPackLoadsAndEveryChainFitsItsNarration() throws {
        // Every chain of al-Bukhari decodes against its row: none was read from different words.
        let bukhari = try book("bukhari")
        let chains = try pack().chains(slug: "bukhari")
        XCTAssertGreaterThan(chains.count, 5_000)
        var drawn = 0
        for (id, code) in chains {
            let hadith = try XCTUnwrap(bukhari.hadith(numbered: id))
            if HadithChainDecoder.chain(code: code, arabic: hadith.arabic, compilerArabic: "البُخَارِيُّ", bookTitle: "Sahih al-Bukhari") != nil {
                drawn += 1
            }
        }
        XCTAssertEqual(drawn, chains.count)
    }

    func testTheFirstHadithOfAlBukhari() throws {
        let hadith = try XCTUnwrap(try book("bukhari").hadith(numbered: 1))
        let chain = try XCTUnwrap(HadithChainStore.shared.chain(slug: "bukhari", idInBook: 1, arabic: hadith.arabic, bookTitle: "Sahih al-Bukhari"))
        XCTAssertTrue(HadithChainStore.shared.hasChain(slug: "bukhari", idInBook: 1))
        // The Prophet ﷺ, 'Umar, 'Alqamah, Muhammad ibn Ibrahim, Yahya ibn Sa'id, Sufyan, al-Humaydi.
        let names = chain.top.flatMap(\.nodes).map(\.arabic)
        XCTAssertEqual(names.count, 7)
        XCTAssertTrue(names[1].contains("عُمَرَ"))
        XCTAssertTrue(names.last?.contains("الْحُمَيْدِيُّ") == true)
        XCTAssertEqual(chain.bottom.first?.nodes.first?.arabic, "البُخَارِيُّ")
        XCTAssertEqual(chain.bottom.first?.title, "حَدَّثَنَا")
        // Every narrator named (the Prophet ﷺ and the collector aside) opens his page; the group of
        // chains that are this one is only there when another narration carries it.
        XCTAssertEqual(names.count - 1, chain.top.flatMap(\.nodes).compactMap(\.narratorID).count)
        let code = try XCTUnwrap(HadithChainStore.shared.pack?.code(slug: "bukhari", idInBook: 1))
        XCTAssertEqual(HadithChainDecoder.parse(code)?.group, HadithChainStore.shared.chainGroup(slug: "bukhari", idInBook: 1))
        // A memory warning empties the cache; the next question inflates the book again.
        HadithChainStore.shared.purge()
        XCTAssertTrue(HadithChainStore.shared.hasChain(slug: "bukhari", idInBook: 1))
    }

    func testAChainFromOtherWordsIsNotDrawn() throws {
        let code = try XCTUnwrap(HadithChainSamples.all.first?.code)
        XCTAssertNil(HadithChainDecoder.chain(code: code, arabic: "حَدَّثَنَا فُلاَنٌ", compilerArabic: "", bookTitle: ""))
    }

    // MARK: - The chain as one English line (the hadith row draws it beside its English)

    private func englishLine(_ slug: String, _ idInBook: Int) throws -> String? {
        let hadith = try XCTUnwrap(try book(slug).hadith(numbered: idInBook), "\(slug) \(idInBook)")
        return HadithChainStore.shared.englishLine(slug: slug, idInBook: idInBook, arabic: hadith.arabic)
    }

    func testTheEnglishLineReadsInTheOrderOfTheArabic() throws {
        // One road, from the collector's teacher up to the narrator below the last one: 'Umar opens
        // the hadith itself ("Narrated 'Umar bin Al-Khattab:"), so the line stops at 'Alqamah.
        XCTAssertEqual(try englishLine("bukhari", 1),
                       "Al-Humaidi Abdullah ibn az-Zubair narrated to us, Sufyan narrated to us, Yahya ibn Sa'id al-Ansari narrated to us, Muhammad ibn Ibrahim at-Taimi informed me, he heard Alqamah ibn Waqqas al-Laithi")
        XCTAssertEqual(try englishLine("bukhari", 6058), "Qutaibah narrated to us, Hammad narrated to us, from Kathir, from Ata'")
        // "حَدَّثَنَا أَبِي": a relation, in the first person.
        XCTAssertEqual(try englishLine("muslim", 5840),
                       "Ubaidullah ibn Mu'adh narrated it to me, my father narrated to us, Shu'bah narrated to us, from Muhammad ibn Ziyad")
    }

    func testTheEnglishLineReadsRoadByRoad() throws {
        // Two roads that each name the narrator where they meet, by their own word.
        XCTAssertEqual(try englishLine("muslim", 4892),
                       "Qutaibah ibn Sa'id narrated to us, al-Laith narrated to us; and Muhammad ibn Rumh narrated to me, al-Laith informed us, from Nafi'")
        // Three roads that name him once: "كُلُّهُمْ عَنْ عُبَيْدِ اللَّهِ".
        XCTAssertEqual(try englishLine("muslim", 1648),
                       "Abu Bakr ibn Abi Shaibah narrated to us, Abu Usamah narrated to us; and Ibn Numair narrated to us, my father narrated to us; and Zuhair ibn Harb and Ibn al-Muthanna narrated to me, Yahya narrated to us; all from Ubaidullah, from Nafi'")
        // Two: "كِلاَهُمَا عَنْ نَافِعٍ".
        XCTAssertEqual(try englishLine("muslim", 4965)?.hasSuffix("ad-Dahhak informed us; both from Nafi'"), true)
    }

    func testNoEnglishLineWhereItWouldBeAGuess() throws {
        // The roads meet at two narrators the text names road by road: which road heard which of
        // the two is not in the code, so nothing is written.
        XCTAssertNil(try englishLine("muslim", 6555))
        // Other words than the chain was read from.
        let code = try XCTUnwrap(HadithChainStore.shared.pack?.code(slug: "bukhari", idInBook: 1))
        let parsed = try XCTUnwrap(HadithChainDecoder.parse(code))
        XCTAssertNil(HadithChainDecoder.englishLine(parsed, arabic: "حَدَّثَنَا فُلاَنٌ", english: HadithIsnadEnglish(slug: "bukhari")))
    }

    func testEveryChainOfAlBukhariHasItsEnglishLine() throws {
        // Every narration the row cuts at its last narrator has the line to go with the cut, and
        // the line is English throughout: no name fell back to its Arabic, no generation is empty.
        let bukhari = try book("bukhari")
        let english = HadithIsnadEnglish(slug: "bukhari")
        var cut = 0
        for (id, code) in try pack().chains(slug: "bukhari") {
            let hadith = try XCTUnwrap(bukhari.hadith(numbered: id))
            let parsed = try XCTUnwrap(HadithChainDecoder.parse(code))
            guard HadithChainDecoder.matnStart(parsed, arabic: hadith.arabic) != nil else { continue }
            cut += 1
            let line = try XCTUnwrap(HadithChainDecoder.englishLine(parsed, arabic: hadith.arabic, english: english), "bukhari \(id)")
            XCTAssertFalse(line.unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) }, "bukhari \(id): \(line)")
            XCTAssertFalse(line.contains(", ,") || line.contains("  ") || line.hasSuffix(" "), "bukhari \(id): \(line)")
        }
        XCTAssertGreaterThan(cut, 5_000)
    }

    func testAWordOfTransmissionBesideAName() {
        XCTAssertEqual(HadithIsnadEnglish.phrase("Sufyan", transmission: "narrated to us"), "Sufyan narrated to us")
        XCTAssertEqual(HadithIsnadEnglish.phrase("Nafi'", transmission: "from"), "from Nafi'")
        XCTAssertEqual(HadithIsnadEnglish.phrase("Khilas", transmission: "I heard"), "I heard Khilas")
        XCTAssertEqual(HadithIsnadEnglish.phrase("Alqamah", transmission: "heard"), "he heard Alqamah")
        // The table's pronoun is the name itself once the name stands beside the word.
        XCTAssertEqual(HadithIsnadEnglish.phrase("Amrah", transmission: "she narrated to me"), "Amrah narrated to me")
        XCTAssertEqual(HadithIsnadEnglish.phrase("Urwah", transmission: "that he"), "that Urwah")
        XCTAssertEqual(HadithIsnadEnglish.phrase("Malik", transmission: ""), "Malik")
    }

    func testMyFatherAndUbayyAreToldApartByTheirVowels() {
        let english = HadithIsnadEnglish(slug: "bukhari")
        XCTAssertEqual(english.narrator(arabic: "أَبِي", id: nil), "my father")
        XCTAssertEqual(english.narrator(arabic: "أُبَيٍّ", id: nil), "Ubayy")
        XCTAssertEqual(english.narrator(arabic: "أبي", id: nil), "")
        XCTAssertEqual(english.narrator(arabic: "أَبِيهِ", id: nil), "his father")
        // Set in braces by the text (al-Bukhari 2464): the brace is punctuation, as in the script.
        XCTAssertEqual(english.narrator(arabic: "أَبِيهِ\u{200F}}\u{200F}", id: nil), "his father")
        XCTAssertEqual(english.transmission("\u{200F}{\u{200F}عَنْ"), "from")
    }
}
