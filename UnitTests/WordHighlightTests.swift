import XCTest
@testable import iPhone

/// The recited-word highlight's pure parts (WordHighlight.swift, 2026-11-02): how words are counted
/// against quran.com's positions, how its segments are read, and where the per-word clips live.
final class WordHighlightTests: XCTestCase {
    func testWordsAreCountedAsQuranComCountsThem() {
        let basmalah = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"
        XCTAssertEqual(QuranWords.count(in: basmalah), 4)
        // The standalone rub-el-hizb mark is a token of the text but never a word of the source.
        let marked = "۞ " + basmalah
        XCTAssertEqual(WordTokens.count(in: marked), 5)
        XCTAssertEqual(QuranWords.count(in: marked), 4)
        XCTAssertEqual(QuranWords.tokenIndex(ofWord: 0, in: marked, expecting: 4), 1)
        XCTAssertEqual(QuranWords.tokenIndex(ofWord: 3, in: marked, expecting: 4), 4)
        // A count that does not match the text lights nothing.
        XCTAssertNil(QuranWords.tokenIndex(ofWord: 0, in: marked, expecting: 5))
        XCTAssertNil(QuranWords.range(of: 1, in: basmalah, expecting: 3))
        let second = try? XCTUnwrap(QuranWords.range(of: 1, in: basmalah, expecting: 4))
        XCTAssertEqual((basmalah as NSString).substring(with: second ?? NSRange()), "ٱللَّهِ")
        // Inside a page's run the ayah ends with its number ornament, which carries no letter.
        let run = ("x " + basmalah + " ١ y") as NSString
        let ayahRange = NSRange(location: 2, length: (basmalah as NSString).length + 2)
        let word = QuranWords.range(ofWord: 3, in: ayahRange, of: run, expecting: 4)
        XCTAssertEqual(word.map { run.substring(with: $0) }, "ٱلرَّحِيمِ")
    }

    func testSegmentsAreMergedPerPositionAndMalformedOnesDropped() throws {
        let json = """
        {"audio_files":[{"id":911,"chapter_id":1,"audio_url":"https://x/1.mp3","duration":46000,
         "verse_timings":[
          {"verse_key":"1:1","timestamp_from":0,"timestamp_to":6090,"segments":[[1,0,580],[2,580,1409],[3,1409,2502],[4,2502,5840],[1]]},
          {"verse_key":"1:2","timestamp_from":6090,"timestamp_to":11680,"segments":[[1,6025,7025],[2,7025,7885],[2,7885,8100],[3,8100,8515],[4,8515,11550]]},
          {"verse_key":"1:4","timestamp_from":16300.0,"timestamp_to":20100,"segments":[[1,16300.0,17210.0],[2,17210.0,18005.5],[3,18005.5,20000.0]]},
          {"verse_key":"2:1","timestamp_from":0,"timestamp_to":10,"segments":[[1,0,10]]},
          {"verse_key":"1:3","timestamp_from":11680,"timestamp_to":16300,"segments":[]}
         ]}]}
        """
        let table = try XCTUnwrap(AyahWordTimingStore.parse(data: Data(json.utf8), surah: 1))
        XCTAssertEqual(Set(table.verses.keys), [1, 2, 4])
        let first = try XCTUnwrap(table.verses[1])
        XCTAssertEqual(first.words, [[1, 0, 580], [2, 580, 1409], [3, 1409, 2502], [4, 2502, 5840]])
        XCTAssertEqual(first.wordCount, 4)
        XCTAssertEqual(first.duration, 6090)
        let second = try XCTUnwrap(table.verses[2])
        // Position 2 was recorded in two pieces: one word, the first start and the last end.
        XCTAssertEqual(second.words, [[1, 6025, 7025], [2, 7025, 8100], [3, 8100, 8515], [4, 8515, 11550]])
        XCTAssertEqual(second.from, 6090)
        // Some reciters' values arrive as floats (Minshawi, al-Husary, Abdul Basit): rounded, not dropped.
        let fourth = try XCTUnwrap(table.verses[4])
        XCTAssertEqual(fourth.words, [[1, 16300, 17210], [2, 17210, 18006], [3, 18006, 20000]])
        XCTAssertEqual(fourth.from, 16300)
    }

    /// The shipped pack (Scripts/build_word_timings.py) decodes to the same tables the fetch would give.
    func testShippedTimingsCoverTheMappedReciters() throws {
        let reciters = ShippedWordTimings.reciters
        XCTAssertTrue(reciters.contains(7), "Alafasy is the reference reciter")
        for reciter in reciters {
            XCTAssertTrue(ShippedWordTimings.has(reciter: reciter))
            let fatihah = try XCTUnwrap(ShippedWordTimings.table(reciter: reciter, surah: 1), "reciter \(reciter)")
            XCTAssertEqual(fatihah.verses.count, 7, "reciter \(reciter)")
            for (ayah, verse) in fatihah.verses {
                XCTAssertFalse(verse.words.isEmpty, "reciter \(reciter) 1:\(ayah)")
                XCTAssertEqual(verse.words.map { $0[0] }, verse.words.map { $0[0] }.sorted(), "positions ascend")
                XCTAssertEqual(Set(verse.words.map { $0[0] }).count, verse.words.count, "positions are unique")
                XCTAssertTrue(verse.words.allSatisfy { $0[2] > $0[1] }, "every word lasts")
            }
            // Nothing is decoded for a surah number the pack has no section for.
            XCTAssertNil(ShippedWordTimings.table(reciter: reciter, surah: 115))
        }
        // Alafasy's al-Fatihah, as quran.com publishes it.
        let alafasy = try XCTUnwrap(ShippedWordTimings.table(reciter: 7, surah: 1))
        let first = try XCTUnwrap(alafasy.verses[1])
        XCTAssertEqual(first.from, 0)
        XCTAssertEqual(first.to, 6090)
        XCTAssertEqual(first.words, [[1, 0, 580], [2, 580, 1409], [3, 1409, 2502], [4, 2502, 5840]])
        let kursi = try XCTUnwrap(ShippedWordTimings.table(reciter: 7, surah: 2)?.verses[255])
        XCTAssertEqual(kursi.wordCount, 50)
        XCTAssertEqual(kursi.words.count, 50)
        // Once inflated, the cheap path answers too; before, it declines without work.
        XCTAssertNotNil(ShippedWordTimings.tableIfInflated(reciter: 7, surah: 36))
        ShippedWordTimings.dropInflated()
        XCTAssertNil(ShippedWordTimings.tableIfInflated(reciter: 7, surah: 36))
    }

    func testClipURLsFollowQuranComsNaming() {
        XCTAssertEqual(WordClipPlayer.clipURL(surah: 2, ayah: 255, position: 1)?.absoluteString,
                       "https://audio.qurancdn.com/wbw/002_255_001.mp3")
        XCTAssertEqual(WordClipPlayer.clipURL(surah: 114, ayah: 6, position: 12)?.absoluteString,
                       "https://audio.qurancdn.com/wbw/114_006_012.mp3")
    }
}
