import XCTest
@testable import iPhone

/// Leaving page mode has to land the list on the surah you were actually reading.
///
/// The page reader crosses surah boundaries, so the surah on screen lives in `pageSurah`
/// (`displayedSurah`) while `SurahView.surah` stays whatever the view was OPENED with. The mode switch
/// used to judge its surah swap against `surah`, so paging from al-Ma'idah to al-Ikhlas and then
/// switching to list view reopened al-Ma'idah (reported 2026-10-05). The second clause covers the round
/// trip: `surah` is `swappedSurah ?? initialSurah`, so returning to the opened surah still has to seat
/// the swap or the landing ayah falls back to the route's original `initialAyah`.
final class ReadingModeLandingTests: XCTestCase {

    private func needsSwap(landing: Int, displayed: Int, swapped: Int?) -> Bool {
        SurahView.leavingPageModeNeedsSurahSwap(landing: landing, displayed: displayed, swapped: swapped)
    }

    /// The reported case: opened on al-Ma'idah (5), paged to al-Ikhlas (112), left page mode.
    /// The landing surah differs from the one on screen only because the reader moved, and the swap
    /// must happen even though `surah` is still 5.
    func testPagingIntoAnotherSurahSwaps() {
        XCTAssertTrue(needsSwap(landing: 112, displayed: 5, swapped: nil),
                      "al-Ma'idah -> al-Ikhlas must re-seat the surah")
    }

    /// The anchor already reports the surah on screen (the reader swiped there and `pageSurah` followed),
    /// but no swap is seated yet, so `surah` would still resolve to the opened surah.
    func testOnScreenSurahWithNoSwapSeatedStillSwaps() {
        XCTAssertTrue(needsSwap(landing: 112, displayed: 112, swapped: nil),
                      "a surah on screen with no swap seated must still be written")
    }

    /// The round trip: opened on al-Ma'idah, paged to al-Ikhlas (seating 112), paged back to al-Ma'idah.
    /// 5 is `initialSurah`, so `swappedSurah` has to be rewritten to 5 rather than left on 112.
    func testPagingBackToTheOpenedSurahReseats() {
        XCTAssertTrue(needsSwap(landing: 5, displayed: 5, swapped: 112),
                      "returning to the opened surah must replace a stale swap")
    }

    /// Nothing moved: the landing surah is on screen and already seated, so no swap and no reset of the
    /// per-surah reading state.
    func testNoMoveDoesNotSwap() {
        XCTAssertFalse(needsSwap(landing: 112, displayed: 112, swapped: 112),
                       "an unchanged surah must not be re-swapped")
    }

    // MARK: list -> page

    private func listLanding(marked: (surahID: Int, ayahID: Int)?, surahID: Int, topVisible: Int?) -> Int? {
        SurahView.leavingListModeLandingAyah(marked: marked, surahID: surahID, topVisible: topVisible)
    }

    /// The mark wins over the scroll position: reading at the top of al-Ikhlas with ayah 3 marked opens
    /// the page holding 3, not the page under the viewport.
    func testMarkedAyahBeatsTheScrollPosition() {
        XCTAssertEqual(listLanding(marked: (112, 3), surahID: 112, topVisible: 1), 3)
    }

    /// Nothing marked: the ayah at the top of the screen decides the page.
    func testUnmarkedUsesTheTopVisibleAyah() {
        XCTAssertEqual(listLanding(marked: nil, surahID: 112, topVisible: 2), 2)
    }

    /// A mark left over from ANOTHER surah (marked while paging, then carried into the list) must not
    /// decide the page: it would open a surah the list was never showing. The scroll position stands in.
    func testStaleMarkFromAnotherSurahIsIgnored() {
        XCTAssertEqual(listLanding(marked: (5, 100), surahID: 112, topVisible: 2), 2,
                       "a mark from al-Ma'idah must not steer a landing while al-Ikhlas is open")
    }

    /// The round trip the page -> list fix enables: page from al-Ma'idah to al-Ikhlas, switch to list
    /// (which marks the landing ayah in 112), then switch straight back to pages. The mark is now in the
    /// right surah, so it steers the landing rather than being discarded.
    func testRoundTripBackToPagesKeepsTheLanding() {
        XCTAssertEqual(listLanding(marked: (112, 1), surahID: 112, topVisible: 1), 1)
    }

    /// Both directions agree on the same spot, so a flip either way is lossless rather than drifting.
    func testTheTwoDirectionsAgree() {
        // Leaving pages on al-Ikhlas ayah 3 seats the surah...
        XCTAssertTrue(needsSwap(landing: 112, displayed: 5, swapped: nil))
        // ...and leaving the list again returns the very same ayah.
        XCTAssertEqual(listLanding(marked: (112, 3), surahID: 112, topVisible: 3), 3)
    }

    // MARK: the page reader's reading position

    /// A navigation that lands on a surah is positioned IN that surah, on every surah, including the 64
    /// that open partway down a page; a swipe (no landing) is positioned at the page's first row. The
    /// Choose Surah coin flip (2026-10-20): al-Falaq picked, the page's first row said al-Ikhlas.
    @MainActor
    func testLandingOnEverySurahPositionsTheReaderInThatSurah() async {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let pages = MushafPagination.pages(quran: data.quran, qiraah: nil)
        XCTAssertFalse(pages.isEmpty, "no pagination")

        var midPage: [Int] = []
        for surah in data.quran {
            guard let index = MushafPagination.pageIndex(surahID: surah.id, ayahID: nil, in: pages) else {
                XCTFail("surah \(surah.id) is on no page"); continue
            }
            let page = pages[index]
            let landed = MushafPagination.readingPosition(on: page, landing: (surah.id, nil))
            XCTAssertEqual(landed?.surah.id, surah.id, "landing on \(surah.id) must position the reader in it")
            XCTAssertEqual(landed?.ayah.id, surah.ayahs.first?.id, "landing on \(surah.id) must stand on its first ayah")
            let swiped = MushafPagination.readingPosition(on: page, landing: nil)
            XCTAssertEqual(swiped?.surah.id, page.firstSurah?.id, "a swipe onto page \(page.page) reads its first row")
            XCTAssertEqual(swiped?.ayah.id, page.firstAyah?.id)
            if page.firstSurah?.id != surah.id { midPage.append(surah.id) }
        }
        XCTAssertEqual(midPage.count, 64, "the Madinah mushaf opens 64 surahs partway down a page: \(midPage)")
        XCTAssertTrue(midPage.contains(113), "al-Falaq opens under al-Ikhlas on page 604")
        XCTAssertFalse(midPage.contains(2), "al-Baqarah opens page 2")
    }

    /// On the last page (al-Ikhlas, al-Falaq, an-Nas): a named ayah the page holds is the position; an
    /// ayah it does not hold falls back to that surah's first ayah on the page; a surah it does not hold
    /// falls back to the page's first row.
    @MainActor
    func testLandingResolvesToWhatTheLastPageHolds() async {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        let pages = MushafPagination.pages(quran: data.quran, qiraah: nil)
        guard let index = MushafPagination.pageIndex(surahID: 113, ayahID: 3, in: pages) else {
            return XCTFail("113:3 is on no page")
        }
        let page = pages[index]
        XCTAssertEqual(page.firstSurah?.id, 112, "al-Falaq's page opens with al-Ikhlas")

        let named = MushafPagination.readingPosition(on: page, landing: (113, 3))
        XCTAssertEqual(named?.surah.id, 113)
        XCTAssertEqual(named?.ayah.id, 3)

        let missingAyah = MushafPagination.readingPosition(on: page, landing: (113, 99))
        XCTAssertEqual(missingAyah?.surah.id, 113)
        XCTAssertEqual(missingAyah?.ayah.id, 1)

        let missingSurah = MushafPagination.readingPosition(on: page, landing: (2, 1))
        XCTAssertEqual(missingSurah?.surah.id, 112)
        XCTAssertEqual(missingSurah?.ayah.id, 1)

        let anNas = MushafPagination.readingPosition(on: page, landing: (114, nil))
        XCTAssertEqual(anNas?.surah.id, 114)
        XCTAssertEqual(anNas?.ayah.id, 1)
    }

    /// Every surah in the Quran satisfies the same rule, in both directions, for a real swap pair.
    @MainActor
    func testRuleHoldsForEveryAdjacentSurahPair() async {
        let data = QuranData.shared
        await data.waitUntilLoaded()
        XCTAssertEqual(data.quran.count, 114, "the Quran did not load")

        for (from, to) in zip(data.quran, data.quran.dropFirst()) {
            // Paged forward from `from` into `to`, nothing seated yet.
            XCTAssertTrue(needsSwap(landing: to.id, displayed: from.id, swapped: nil),
                          "\(from.id) -> \(to.id) must swap")
            // And back again, with `to` left seated from the forward trip.
            XCTAssertTrue(needsSwap(landing: from.id, displayed: from.id, swapped: to.id),
                          "\(to.id) -> \(from.id) must re-seat")
            // Settled on `to`: no further swap.
            XCTAssertFalse(needsSwap(landing: to.id, displayed: to.id, swapped: to.id),
                           "\(to.id) settled must not swap")
        }
    }
}
