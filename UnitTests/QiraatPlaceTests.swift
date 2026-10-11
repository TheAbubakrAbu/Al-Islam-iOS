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
    /// own words there, the side that reads as Hafs included.
    func testDuelKeepsWhereTheTwoPartWays() {
        let changed = change(hafs: hafs, riwayah: replaced, wordHafs: [1], wordRiwayah: [1])
        let alike = change(hafs: hafs, riwayah: hafs)
        let sides = [side(warsh, changed), side(qalun, changed), side(duri, alike)]
        let place = QiraatPlace(surah: 112, hafsAyah: 1, everyDifference: false, hafsText: hafs,
                                hafsTokens: QiraatWordDiff.tokens(of: hafs), english: "", sides: sides,
                                sites: sites(hafs, sides), audioTags: [], hasReference: false)

        XCTAssertTrue(QiraatPlaceBuilder.duel(a: warsh, b: qalun, place: place).sites.isEmpty)

        let againstHafs = QiraatPlaceBuilder.duel(a: "", b: warsh, place: place)
        XCTAssertEqual(againstHafs.sites.count, 1)
        XCTAssertEqual(againstHafs.sites.first?.readings.map(\.tags), [[""], [warsh]])
        XCTAssertEqual(againstHafs.aTinted, [1])
        XCTAssertEqual(againstHafs.bTinted, [1])

        let againstDuri = QiraatPlaceBuilder.duel(a: duri, b: warsh, place: place)
        XCTAssertEqual(againstDuri.sites.count, 1)
        XCTAssertEqual(againstDuri.aTinted, [1], "ad-Duri reads as Hafs here; its own word at the site is tinted")
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

    /// Against the app's own texts: al-Fatiha 1:4, where Warsh reads مَلِكِ for Hafs's مَٰلِكِ.
    func testFatihahFourAgainstTheShippedTexts() async throws {
        let quranData = QuranData.shared
        guard let ayah = quranData.ayah(surah: 1, ayah: 4) else { throw XCTSkip("The Quran is not loaded in this host.") }
        let warshText = ayah.rawArabicText(surahId: 1, qiraahOverride: warsh)
        let hafsText = ayah.rawArabicText(surahId: 1, qiraahOverride: "")
        guard !warshText.isEmpty, warshText != hafsText else { throw XCTSkip("Warsh's text is not loaded in this host.") }

        let place = await QiraatPlaceBuilder.build(surah: 1, hafsAyah: 4, tags: [warsh], everyDifference: false, quranData: quranData)
        let site = try XCTUnwrap(place.sites.first { $0.range.contains(0) })
        let warshReading = try XCTUnwrap(site.reading(of: warsh))
        XCTAssertFalse(warshReading.isHafs)
        XCTAssertNotEqual(warshReading.text, site.readings[0].text)
        XCTAssertTrue(place.hafsTinted.contains(0))
    }
}
