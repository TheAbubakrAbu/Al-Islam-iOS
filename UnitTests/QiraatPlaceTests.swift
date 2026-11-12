import XCTest
@testable import iPhone

/// The Qiraat Explorer's place builder (QiraatPlace.swift): how one Hafs ayah is cut into SITES, the
/// words some riwayah reads differently, and who reads each one how.
final class QiraatPlaceTests: XCTestCase {

    private let warsh = Settings.Riwayah.warsh
    private let qalun = Settings.Riwayah.qaloon
    private let duri = Settings.Riwayah.duri

    /// A riwayah's change against Hafs, flagged by hand: `word` are word-level token indices on each
    /// side, `letter` the letter-level ones (Every Difference only).
    private func change(hafs: String, riwayah: String,
                        wordHafs: Set<Int> = [], wordRiwayah: Set<Int> = [],
                        letterHafs: Set<Int> = [], letterRiwayah: Set<Int> = []) -> QiraatChange {
        QiraatChange(hafsText: hafs, riwayahText: riwayah, diff: QiraatWordDiff.compare(hafs: hafs, riwayah: riwayah),
                     hafsWords: wordHafs.union(letterHafs).sorted(), riwayahWords: wordRiwayah.union(letterRiwayah).sorted(),
                     hafsWordLevel: wordHafs, riwayahWordLevel: wordRiwayah, hafsWordsByAyah: [:])
    }

    private func side(_ tag: String, _ change: QiraatChange, base: Int = 0) -> QiraatPlaceSide {
        QiraatPlaceSide(tag: tag, resolved: ResolvedQiraahText(text: change.riwayahText, ownNumber: nil, mergedSpan: nil),
                        change: change, hafsBase: base)
    }

    private func sites(_ hafs: String, _ sides: [QiraatPlaceSide], every: Bool = false) -> [QiraatSite] {
        QiraatPlaceBuilder.sites(hafsTokens: QiraatWordDiff.tokens(of: hafs), sides: sides, everyDifference: every)
    }

    private func place(_ hafs: String, _ sides: [QiraatPlaceSide], every: Bool = false) -> QiraatPlace {
        let tokens = QiraatWordDiff.tokens(of: hafs)
        let built = sites(hafs, sides, every: every)
        let tints = QiraatPlaceBuilder.tints(hafsText: hafs, hafsTokens: tokens, sides: sides, sites: built)
        return QiraatPlace(surah: 112, hafsAyah: 1, everyDifference: every, hafsText: hafs, hafsTokens: tokens,
                           english: "", sides: sides, sites: built, audioTags: [], hasReference: false,
                           hafsTint: tints.hafs, riwayahTints: tints.riwayah)
    }

    private func text(_ string: String, _ range: NSRange) -> String {
        (string as NSString).substring(with: range)
    }

    private func texts(_ string: String, _ ranges: [NSRange]?) -> [String]? {
        ranges?.map { text(string, $0) }
    }

    // قل هو الله احد, and the same with هي for هو
    private let hafs = "\u{0642}\u{0644} \u{0647}\u{0648} \u{0627}\u{0644}\u{0644}\u{0647} \u{0627}\u{062D}\u{062F}"
    private let replaced = "\u{0642}\u{0644} \u{0647}\u{064A} \u{0627}\u{0644}\u{0644}\u{0647} \u{0627}\u{062D}\u{062F}"

    /// One word read another way by two riwayat, as Hafs by a third: one site, two readings, the
    /// riwayat in the classical order.
    func testReplacementIsOneSiteWithTwoReadings() throws {
        let changed = change(hafs: hafs, riwayah: replaced, wordHafs: [1], wordRiwayah: [1])
        let alike = change(hafs: hafs, riwayah: hafs)
        let result = sites(hafs, [side(qalun, changed), side(duri, alike), side(warsh, changed)])

        XCTAssertEqual(result.count, 1)
        let site = try XCTUnwrap(result.first)
        XCTAssertEqual(site.range, 1...1)
        XCTAssertEqual(site.readings.count, 2)
        XCTAssertEqual(site.readings[0].text, "\u{0647}\u{0648}")
        XCTAssertEqual(site.readings[0].tags, ["", duri])
        XCTAssertTrue(site.readings[0].isHafs)
        XCTAssertEqual(site.readings[1].text, "\u{0647}\u{064A}")
        XCTAssertEqual(site.readings[1].tags, [warsh, qalun])
        XCTAssertEqual(site.changedHafs[warsh], [1])
        XCTAssertEqual(site.changedRiwayah[qalun], [1])
        XCTAssertNil(site.changedHafs[duri])
    }

    /// A word the riwayah adds (تجري من تحتها) is shown with the words either side of it.
    func testAddedWordTakesItsNeighbors() throws {
        let hafs = "\u{062A}\u{062C}\u{0631}\u{064A} \u{062A}\u{062D}\u{062A}\u{0647}\u{0627} \u{0627}\u{0644}\u{0627}\u{0646}\u{0647}\u{0627}\u{0631}"
        let riwayah = "\u{062A}\u{062C}\u{0631}\u{064A} \u{0645}\u{0646} \u{062A}\u{062D}\u{062A}\u{0647}\u{0627} \u{0627}\u{0644}\u{0627}\u{0646}\u{0647}\u{0627}\u{0631}"
        let result = sites(hafs, [side(warsh, change(hafs: hafs, riwayah: riwayah, wordRiwayah: [1]))])

        let site = try XCTUnwrap(result.first)
        XCTAssertEqual(site.range, 0...1)
        XCTAssertEqual(site.readings[0].text, "\u{062A}\u{062C}\u{0631}\u{064A} \u{062A}\u{062D}\u{062A}\u{0647}\u{0627}")
        XCTAssertEqual(site.readings[1].text, "\u{062A}\u{062C}\u{0631}\u{064A} \u{0645}\u{0646} \u{062A}\u{062D}\u{062A}\u{0647}\u{0627}")
        XCTAssertEqual(site.changedHafs[warsh], [], "an added word changes no Hafs word")
        XCTAssertEqual(site.changedRiwayah[warsh], [1])
    }

    /// A word the riwayah drops (فان الله الغني for فان الله هو الغني) is shown with its neighbors,
    /// but only the dropped word is tinted in the Hafs ayah.
    func testDroppedWordTakesItsNeighborsButTintsAlone() throws {
        let hafs = "\u{0641}\u{0627}\u{0646} \u{0627}\u{0644}\u{0644}\u{0647} \u{0647}\u{0648} \u{0627}\u{0644}\u{063A}\u{0646}\u{064A}"
        let riwayah = "\u{0641}\u{0627}\u{0646} \u{0627}\u{0644}\u{0644}\u{0647} \u{0627}\u{0644}\u{063A}\u{0646}\u{064A}"
        let result = sites(hafs, [side(warsh, change(hafs: hafs, riwayah: riwayah, wordHafs: [2]))])

        let site = try XCTUnwrap(result.first)
        XCTAssertEqual(site.range, 1...3)
        XCTAssertEqual(site.readings[1].text, "\u{0627}\u{0644}\u{0644}\u{0647} \u{0627}\u{0644}\u{063A}\u{0646}\u{064A}")
        XCTAssertEqual(site.changedHafs[warsh], [2])
    }

    /// A word the print flags only for one letter's vowel counts under Every Difference alone.
    func testLetterLevelChangeNeedsEveryDifference() {
        let hafs = "\u{0645}\u{064E}\u{0644}\u{0650}\u{0643}\u{0650} \u{064A}\u{0648}\u{0645}"   // مَلِكِ يوم
        let riwayah = "\u{0645}\u{064E}\u{0644}\u{0650}\u{0643}\u{064F} \u{064A}\u{0648}\u{0645}" // مَلِكُ يوم
        let flagged = change(hafs: hafs, riwayah: riwayah, letterHafs: [0], letterRiwayah: [0])
        XCTAssertEqual(flagged.diff.pairs[0], 0, "the two forms fold alike, so they pair")

        XCTAssertTrue(sites(hafs, [side(warsh, flagged)], every: false).isEmpty)
        let every = sites(hafs, [side(warsh, flagged)], every: true)
        XCTAssertEqual(every.count, 1)
        XCTAssertEqual(every.first?.readings.last?.text, "\u{0645}\u{064E}\u{0644}\u{0650}\u{0643}\u{064F}")
    }

    /// A riwayah that joins two Hafs ayahs is diffed over the joined span: the place for the second
    /// ayah reads its sites in that ayah's own token numbers.
    func testJoinedSpanUsesTheAyahsOwnTokens() throws {
        let first = "\u{0642}\u{0644} \u{0647}\u{0648} \u{0627}\u{0644}\u{0644}\u{0647} \u{0627}\u{062D}\u{062F}"
        let second = "\u{0627}\u{0644}\u{0644}\u{0647} \u{0627}\u{0644}\u{0635}\u{0645}\u{062F}"
        let riwayah = first + " \u{0627}\u{0644}\u{0644}\u{0647} \u{0635}\u{0645}\u{062F}"
        let joined = change(hafs: first + " " + second, riwayah: riwayah, wordHafs: [5], wordRiwayah: [5])
        let result = sites(second, [side(warsh, joined, base: 4)])

        let site = try XCTUnwrap(result.first)
        XCTAssertEqual(site.range, 1...1)
        XCTAssertEqual(site.readings[0].text, "\u{0627}\u{0644}\u{0635}\u{0645}\u{062F}")
        XCTAssertEqual(site.readings[1].text, "\u{0635}\u{0645}\u{062F}")
    }

    // كتب علم نزل فعل
    private let four = "\u{0643}\u{062A}\u{0628} \u{0639}\u{0644}\u{0645} \u{0646}\u{0632}\u{0644} \u{0641}\u{0639}\u{0644}"

    /// Two riwayat changing overlapping runs of words share one site, each read over all of it.
    func testOverlappingChangesShareOneSite() throws {
        let both = "\u{0643}\u{062A}\u{0628} \u{0639}\u{0644}\u{0645}\u{0648} \u{0646}\u{0632}\u{0644}\u{0648} \u{0641}\u{0639}\u{0644}"
        let one = "\u{0643}\u{062A}\u{0628} \u{0639}\u{0644}\u{0645} \u{0627}\u{0646}\u{0632}\u{0644} \u{0641}\u{0639}\u{0644}"
        let result = sites(four, [
            side(warsh, change(hafs: four, riwayah: both, wordHafs: [1, 2], wordRiwayah: [1, 2])),
            side(duri, change(hafs: four, riwayah: one, wordHafs: [2], wordRiwayah: [2])),
        ])

        XCTAssertEqual(result.count, 1)
        let site = try XCTUnwrap(result.first)
        XCTAssertEqual(site.range, 1...2)
        XCTAssertEqual(site.readings.count, 3)
        XCTAssertEqual(site.reading(of: duri)?.text, "\u{0639}\u{0644}\u{0645} \u{0627}\u{0646}\u{0632}\u{0644}")
        XCTAssertEqual(site.changedRiwayah[duri], [2], "only the word it changes is tinted")
    }

    /// A gap that does not count under the tier (a silah, say) earns no card of its own, but it still
    /// widens a card it cuts through, and inside that card its riwayah is shown as it reads.
    func testUncountedGapWidensTheSite() throws {
        let silah = "\u{0643}\u{062A}\u{0628} \u{0639}\u{0644}\u{0645}\u{0648} \u{0646}\u{0632}\u{0644}\u{0648} \u{0641}\u{0639}\u{0644}"
        let one = "\u{0643}\u{062A}\u{0628} \u{0639}\u{0644}\u{0645} \u{0627}\u{0646}\u{0632}\u{0644} \u{0641}\u{0639}\u{0644}"
        let silahSide = side(warsh, change(hafs: four, riwayah: silah, letterHafs: [1, 2], letterRiwayah: [1, 2]))
        XCTAssertTrue(sites(four, [silahSide]).isEmpty, "letter level alone earns no card with Every Difference off")

        let result = sites(four, [silahSide, side(duri, change(hafs: four, riwayah: one, wordHafs: [2], wordRiwayah: [2]))])
        let site = try XCTUnwrap(result.first)
        XCTAssertEqual(site.range, 1...2)
        let reading = try XCTUnwrap(site.reading(of: warsh))
        XCTAssertFalse(reading.isHafs)
        XCTAssertEqual(reading.text, "\u{0639}\u{0644}\u{0645}\u{0648} \u{0646}\u{0632}\u{0644}\u{0648}")
    }

    /// Inside a card the tier does not hide a reading: two prints that flag the same reading at
    /// different levels (2:10's يُكَذِّبُونَ) are shown together, not one of them as Hafs.
    func testLetterLevelReadingJoinsTheWordLevelOneInsideACard() throws {
        let hafs = "\u{064A}\u{064E}\u{0643}\u{0630}\u{0628}\u{0648}\u{0646} \u{0642}\u{0644}"   // يَكذبون قل
        let other = "\u{064A}\u{064F}\u{0643}\u{0630}\u{0628}\u{0648}\u{0646} \u{0642}\u{0644}"  // يُكذبون قل
        let result = sites(hafs, [
            side(warsh, change(hafs: hafs, riwayah: other, letterHafs: [0], letterRiwayah: [0])),
            side(duri, change(hafs: hafs, riwayah: other, wordHafs: [0], wordRiwayah: [0])),
        ])
        let site = try XCTUnwrap(result.first)
        XCTAssertEqual(site.readings.count, 2)
        XCTAssertEqual(site.readings[1].tags, [warsh, duri])
    }

    /// Compare Two keeps only the sites where its two sides read differently, and tints each side's
    /// own words there, the side that reads as Hafs included. Without print letters, whole words.
    func testDuelKeepsWhereTheTwoPartWays() {
        let changed = change(hafs: hafs, riwayah: replaced, wordHafs: [1], wordRiwayah: [1])
        let alike = change(hafs: hafs, riwayah: hafs)
        let sides = [side(warsh, changed), side(qalun, changed), side(duri, alike)]
        let place = place(hafs, sides)
        XCTAssertEqual(place.hafsTint, QiraatTint.Spec(words: [1]), "no print letters: the word whole")
        XCTAssertNil(place.sites.first?.reading(of: warsh)?.letters)

        XCTAssertTrue(QiraatPlaceBuilder.duel(a: warsh, b: qalun, place: place).sites.isEmpty)

        let againstHafs = QiraatPlaceBuilder.duel(a: "", b: warsh, place: place)
        XCTAssertEqual(againstHafs.sites.count, 1)
        XCTAssertEqual(againstHafs.sites.first?.readings.map(\.tags), [[""], [warsh]])
        XCTAssertEqual(againstHafs.aTint, QiraatTint.Spec(words: [1]))
        XCTAssertEqual(againstHafs.bTint, QiraatTint.Spec(words: [1]))

        let againstDuri = QiraatPlaceBuilder.duel(a: duri, b: warsh, place: place)
        XCTAssertEqual(againstDuri.sites.count, 1)
        XCTAssertEqual(againstDuri.aTint, QiraatTint.Spec(words: [1]), "ad-Duri reads as Hafs here; its own word at the site is tinted")
    }

    // MARK: Letters (2026-11-02: the cards tint the letter that changes, not the word)

    // Hafs مَٰلِكِ يوم; a print that marks the mīm of its مَلِكِ (cluster 0); and one that reads هَلِكِ
    private let owner = "\u{0645}\u{064E}\u{0670}\u{0644}\u{0650}\u{0643}\u{0650} \u{064A}\u{0648}\u{0645}"
    private let king = "\u{0645}\u{064E}\u{0644}\u{0650}\u{0643}\u{0650} \u{064A}\u{0648}\u{0645}"
    private let other = "\u{0647}\u{064E}\u{0644}\u{0650}\u{0643}\u{0650} \u{064A}\u{0648}\u{0645}"

    /// A change whose print marks `extents` in riwayah word 0, paired with Hafs word 0.
    private func lettered(_ riwayah: String, extents: [(lo: Int, hi: Int)]) -> QiraatChange {
        var flagged = change(hafs: owner, riwayah: riwayah, wordHafs: [0], wordRiwayah: [0])
        flagged.hasPrintLetters = true
        flagged.riwayahLetters = [0: extents]
        flagged.letterPairs = [0: 0, 1: 1]
        return flagged
    }

    /// With print letters the Hafs card tints the counterpart of the marked letter (the mīm with its
    /// dagger alif), the riwayah's card its own mīm, the site reading that letter alone, and Compare
    /// Two against Hafs carries the same letter both ways.
    func testPrintLettersTintTheLetterOnEveryCard() throws {
        let sides = [side(warsh, lettered(king, extents: [(lo: 0, hi: 0)]))]
        let place = place(owner, sides)

        XCTAssertEqual(texts(owner, place.hafsTint.letters), ["\u{0645}\u{064E}\u{0670}"])
        XCTAssertEqual(place.hafsTint.words, [])
        XCTAssertEqual(texts(king, place.tint(warsh).letters), ["\u{0645}\u{064E}"])
        XCTAssertEqual(place.tint(warsh).words, [])
        let reading = try XCTUnwrap(place.sites.first?.reading(of: warsh))
        XCTAssertEqual(reading.text, "\u{0645}\u{064E}\u{0644}\u{0650}\u{0643}\u{0650}")
        XCTAssertEqual(texts(reading.text, reading.letters), ["\u{0645}\u{064E}"])
        XCTAssertNil(place.sites.first?.readings[0].letters, "Hafs's own reading carries no letters")

        let duel = QiraatPlaceBuilder.duel(a: "", b: warsh, place: place)
        XCTAssertEqual(texts(owner, duel.aTint.letters), ["\u{0645}\u{064E}\u{0670}"])
        XCTAssertEqual(texts(king, duel.bTint.letters), ["\u{0645}\u{064E}"])
        XCTAssertTrue(duel.aTint.words.isEmpty && duel.bTint.words.isEmpty)

        // The riwayah first: Hafs's reading is the emphasized one, so it gets the letters carried over.
        let reversed = QiraatPlaceBuilder.duel(a: warsh, b: "", place: place)
        let readings = try XCTUnwrap(reversed.sites.first?.readings)
        XCTAssertEqual(readings.map(\.readsAsHafs), [false, true])
        XCTAssertEqual(texts(readings[1].text, readings[1].letters), ["\u{0645}\u{064E}\u{0670}"])
        XCTAssertEqual(texts(readings[0].text, readings[0].letters), ["\u{0645}\u{064E}"])
    }

    /// A print that marks the whole word (lo -1) tints it whole on both cards. A changed word the
    /// print leaves black (Warsh's مَلِكِ at 1:4) narrows to the letters the two words disagree on:
    /// the mīm, whose dagger alif is the difference.
    func testWholeWordMarksStayWholeAndUnmarkedWordsNarrowToTheirLetters() throws {
        let whole = place(owner, [side(warsh, lettered(king, extents: [(lo: -1, hi: -1)]))])
        XCTAssertEqual(texts(owner, whole.hafsTint.letters), ["\u{0645}\u{064E}\u{0670}\u{0644}\u{0650}\u{0643}\u{0650}"])
        XCTAssertEqual(texts(king, whole.tint(warsh).letters), ["\u{0645}\u{064E}\u{0644}\u{0650}\u{0643}\u{0650}"])

        var black = lettered(king, extents: [])
        black.riwayahLetters = [:]
        let unmarked = place(owner, [side(warsh, black)])
        XCTAssertEqual(texts(owner, unmarked.hafsTint.letters), ["\u{0645}\u{064E}\u{0670}"])
        XCTAssertEqual(unmarked.hafsTint.words, [])
        XCTAssertEqual(texts(king, unmarked.tint(warsh).letters), ["\u{0645}\u{064E}"])
        let reading = try XCTUnwrap(unmarked.sites.first?.reading(of: warsh))
        XCTAssertEqual(texts(reading.text, reading.letters), ["\u{0645}\u{064E}"])
    }

    /// A silah written as a letter of its own (رزقنهمو for Hafs's رزقنهم) that the print files under
    /// its silah rule rather than the khilaf colour: the added wāw is the riwayah's letter, and on
    /// Hafs's side it lands on the mīm it follows; in Compare Two both ways round.
    func testSilahWrittenAsALetterTintsThatLetterWhereThePrintMarksNone() throws {
        let hafs = "\u{0631}\u{0632}\u{0642}\u{0646}\u{0647}\u{0645} \u{064A}\u{0646}\u{0641}\u{0642}\u{0648}\u{0646}"
        let silah = "\u{0631}\u{0632}\u{0642}\u{0646}\u{0647}\u{0645}\u{0648} \u{064A}\u{0646}\u{0641}\u{0642}\u{0648}\u{0646}"
        var flagged = change(hafs: hafs, riwayah: silah, wordHafs: [0], wordRiwayah: [0])
        flagged.hasPrintLetters = true
        flagged.letterPairs = [0: 0, 1: 1]
        let place = place(hafs, [side(warsh, flagged)])

        XCTAssertEqual(texts(hafs, place.hafsTint.letters), ["\u{0645}"])
        XCTAssertEqual(texts(silah, place.tint(warsh).letters), ["\u{0648}"])
        let reading = try XCTUnwrap(place.sites.first?.reading(of: warsh))
        XCTAssertEqual(reading.text, "\u{0631}\u{0632}\u{0642}\u{0646}\u{0647}\u{0645}\u{0648}")
        XCTAssertEqual(texts(reading.text, reading.letters), ["\u{0648}"])

        let duel = QiraatPlaceBuilder.duel(a: "", b: warsh, place: place)
        XCTAssertEqual(texts(hafs, duel.aTint.letters), ["\u{0645}"])
        XCTAssertEqual(texts(silah, duel.bTint.letters), ["\u{0648}"])
        let reversed = QiraatPlaceBuilder.duel(a: warsh, b: "", place: place)
        XCTAssertEqual(texts("\u{0631}\u{0632}\u{0642}\u{0646}\u{0647}\u{0645}", reversed.sites.first?.readings[1].letters), ["\u{0645}"])
    }

    /// Compare Two of two riwayat: where one reads as Hafs, the other's letters are carried onto its
    /// word; where both change the word, each keeps it whole, since a print's letters are measured
    /// from Hafs and not from the other riwayah.
    func testDuelOfTwoRiwayatCarriesLettersOnlyOntoAHafsReading() throws {
        var alike = change(hafs: owner, riwayah: owner)
        alike.hasPrintLetters = true
        alike.letterPairs = [0: 0, 1: 1]
        let sides = [side(warsh, lettered(king, extents: [(lo: 0, hi: 0)])),
                     side(qalun, lettered(other, extents: [(lo: 0, hi: 0)])),
                     side(duri, alike)]
        let place = place(owner, sides)

        let againstDuri = QiraatPlaceBuilder.duel(a: duri, b: warsh, place: place)
        XCTAssertEqual(againstDuri.sites.count, 1)
        XCTAssertEqual(texts(owner, againstDuri.aTint.letters), ["\u{0645}\u{064E}\u{0670}"], "ad-Duri reads as Hafs: Warsh's letter lands on his word")
        XCTAssertEqual(texts(king, againstDuri.bTint.letters), ["\u{0645}\u{064E}"])

        let bothChange = QiraatPlaceBuilder.duel(a: qalun, b: warsh, place: place)
        XCTAssertEqual(bothChange.sites.count, 1)
        XCTAssertEqual(bothChange.aTint, QiraatTint.Spec(words: [0]))
        XCTAssertEqual(bothChange.bTint, QiraatTint.Spec(words: [0]))
        let site = try XCTUnwrap(bothChange.sites.first)
        XCTAssertFalse(site.readings[0].readsAsHafs, "the first reading is Qalun's own, so the row sets Warsh's whole")
        XCTAssertNotNil(site.readings[1].letters)
    }

    /// Who reads it: an imam where both his compared narrators agree, the narrators otherwise, and
    /// the two ad-Duris told apart by their imams.
    func testReaderNamesCompressToImams() {
        let eight: Set<String> = ["", Settings.Riwayah.shubah, warsh, qalun, Settings.Riwayah.buzzi,
                                  Settings.Riwayah.qunbul, duri, Settings.Riwayah.susi]
        XCTAssertEqual(QiraatReaderNames.names([warsh, qalun, Settings.Riwayah.buzzi], compared: eight), ["Nafi", "al-Bazzi"])
        XCTAssertEqual(QiraatReaderNames.names(["", Settings.Riwayah.shubah], compared: eight), ["Asim"])
        XCTAssertEqual(QiraatReaderNames.names([duri], compared: eight), ["ad-Duri"])
        XCTAssertEqual(QiraatReaderNames.names([duri], compared: eight.union([Settings.Riwayah.duriKisai])),
                       ["ad-Duri (Abu Amr)"])
        XCTAssertEqual(QiraatReaderNames.list(["Nafi", "Ibn Kathir", "Abu Amr"]), "Nafi, Ibn Kathir and Abu Amr")
    }

    /// Runs `body` with the riwayah text columns loaded. They load only when the details switch (or a
    /// non-Hafs display) asks for them, and `rawArabicText(qiraahOverride:)` falls back to Hafs
    /// without them, so on a clean simulator the shipped-text tests skipped every time and ran only
    /// by order pollution. Asks for them the way FatihahCleanModeTests does, and puts the switch back
    /// on every exit.
    @MainActor
    private func withRiwayahColumns(_ body: () async throws -> Void) async throws {
        let quranData = QuranData.shared
        await quranData.waitUntilLoaded()
        let settings = Settings.shared
        let previousShowQiraah = settings.showQiraahDetails
        let hadOverlays = quranData.surah(1)?.ayahs.first?.textWarsh != nil
        if !hadOverlays {
            settings.showQiraahDetails = true
            quranData.reloadForQiraahAvailabilityChange()
            let deadline = Date().addingTimeInterval(20)
            while quranData.surah(1)?.ayahs.first?.textWarsh == nil, Date() < deadline {
                try await Task.sleep(nanoseconds: 50_000_000)
            }
        }
        func restoreQiraahDetails() async throws {
            guard !hadOverlays else { return }
            settings.showQiraahDetails = previousShowQiraah
            if previousShowQiraah != true {
                quranData.reloadForQiraahAvailabilityChange()
                let settle = Date().addingTimeInterval(10)
                while quranData.surah(1)?.ayahs.first?.textWarsh != nil, Date() < settle {
                    try await Task.sleep(nanoseconds: 20_000_000)
                }
            }
        }
        do {
            try await body()
        } catch {
            try await restoreQiraahDetails()
            throw error
        }
        try await restoreQiraahDetails()
    }

    /// Against the app's own texts: al-Fatiha 1:4, where Warsh reads مَلِكِ for Hafs's مَٰلِكِ.
    @MainActor
    func testFatihahFourAgainstTheShippedTexts() async throws {
        try await withRiwayahColumns {
            let quranData = QuranData.shared
            let ayah = try XCTUnwrap(quranData.ayah(surah: 1, ayah: 4), "The Quran is not loaded in this host.")
            let warshText = ayah.rawArabicText(surahId: 1, qiraahOverride: warsh)
            let hafsText = ayah.rawArabicText(surahId: 1, qiraahOverride: "")
            XCTAssertFalse(warshText.isEmpty, "Warsh's 1:4 is empty")
            XCTAssertNotEqual(warshText, hafsText, "Warsh's text did not load: the overlays are missing from this build")

            let place = await QiraatPlaceBuilder.build(surah: 1, hafsAyah: 4, tags: [warsh], everyDifference: false, quranData: quranData)
            let site = try XCTUnwrap(place.sites.first { $0.range.contains(0) })
            let warshReading = try XCTUnwrap(site.reading(of: warsh))
            XCTAssertFalse(warshReading.isHafs)
            XCTAssertNotEqual(warshReading.text, site.readings[0].text)
            XCTAssertTrue(place.hafsTinted.contains(0))
        }
    }

    /// Against the app's own texts and Warsh's pack: Hafs 2:3, where his print marks the wāw of
    /// يُومِنُونَ (his own ayah 2, Madani count). Every card tints that one letter: the Hafs card the
    /// hamzah seat ؤۡ it answers to (the same letter the reader and the comparison sheet tint), his
    /// own card and the site reading the wāw, and Compare Two against Hafs both. Letter khilaf
    /// earns a site under Every Difference only.
    @MainActor
    func testBaqarahThreeTintsTheLetterOnEveryCard() async throws {
        try await withRiwayahColumns {
            let quranData = QuranData.shared
            let hafsText = try XCTUnwrap(quranData.ayah(surah: 2, ayah: 3)).rawArabicText(surahId: 2, qiraahOverride: "")
            let warshText = try XCTUnwrap(quranData.ayah(surah: 2, ayah: 2)).rawArabicText(surahId: 2, qiraahOverride: warsh)
            guard warshText != hafsText, warshText.contains("\u{064A}\u{064F}\u{0648}\u{0645}\u{0650}\u{0646}\u{064F}\u{0648}\u{0646}\u{064E}") else {
                throw XCTSkip("Warsh's text did not load: the overlays are missing from this build")
            }
            guard QiraatLetterDiff.hasLetterPack(tag: warsh) else { throw XCTSkip("Warsh's pack is not bundled") }

            let place = await QiraatPlaceBuilder.build(surah: 2, hafsAyah: 3, tags: [warsh], everyDifference: true, quranData: quranData)
            XCTAssertEqual(place.hafsText, hafsText)
            XCTAssertEqual(texts(place.hafsText, place.hafsTint.letters), ["\u{0624}\u{06E1}"])
            XCTAssertEqual(place.hafsTint.words, [])
            let change = try XCTUnwrap(place.side(warsh)?.change)
            XCTAssertTrue(change.hasPrintLetters)
            XCTAssertEqual(texts(change.riwayahText, place.tint(warsh).letters), ["\u{0648}"])
            XCTAssertEqual(place.tint(warsh).words, [])
            let site = try XCTUnwrap(place.sites.first)
            let reading = try XCTUnwrap(site.reading(of: warsh))
            XCTAssertEqual(reading.text, "\u{064A}\u{064F}\u{0648}\u{0645}\u{0650}\u{0646}\u{064F}\u{0648}\u{0646}\u{064E}")
            XCTAssertEqual(texts(reading.text, reading.letters), ["\u{0648}"])
            XCTAssertTrue(site.readings[0].readsAsHafs)

            let duel = QiraatPlaceBuilder.duel(a: "", b: warsh, place: place)
            XCTAssertEqual(texts(place.hafsText, duel.aTint.letters), ["\u{0624}\u{06E1}"])
            XCTAssertEqual(texts(change.riwayahText, duel.bTint.letters), ["\u{0648}"])

            let hidden = await QiraatPlaceBuilder.build(surah: 2, hafsAyah: 3, tags: [warsh], everyDifference: false, quranData: quranData)
            XCTAssertTrue(hidden.sites.isEmpty, "a letter's khilaf earns a site under Every Difference only")
            XCTAssertTrue(hidden.hafsTint.isEmpty)

            // With al-Bazzi beside him: his silah رَزَقۡنَٰهُمُۥ is under his silah rule, not his khilaf colour,
            // so the words themselves give the letter: his mīm, whose vowel and small wāw change, and
            // on the Hafs card the mīm it answers to, beside Warsh's hamzah seat.
            let bazzi = Settings.Riwayah.buzzi
            let bazziText = try XCTUnwrap(quranData.ayah(surah: 2, ayah: 2)).rawArabicText(surahId: 2, qiraahOverride: bazzi)
            guard bazziText != hafsText, QiraatLetterDiff.hasLetterPack(tag: bazzi) else { return }
            let two = await QiraatPlaceBuilder.build(surah: 2, hafsAyah: 3, tags: [warsh, bazzi], everyDifference: true, quranData: quranData)
            XCTAssertEqual(texts(two.hafsText, two.hafsTint.letters), ["\u{0624}\u{06E1}", "\u{0645}\u{06E1}"])
            XCTAssertEqual(two.hafsTint.words, [])
            let bazziChange = try XCTUnwrap(two.side(bazzi)?.change)
            XCTAssertEqual(texts(bazziChange.riwayahText, two.tint(bazzi).letters), ["\u{0645}\u{064F}\u{06E5}"])
            let silahSite = try XCTUnwrap(two.sites.first { $0.reading(of: bazzi)?.readsAsHafs == false })
            let bazziReading = try XCTUnwrap(silahSite.reading(of: bazzi))
            XCTAssertEqual(texts(bazziReading.text, bazziReading.letters), ["\u{0645}\u{064F}\u{06E5}"])
        }
    }
}
