import XCTest
@testable import iPhone

/// The precomputed packs (Performance Guide 10.14-10.17) must yield exactly what the code they stand
/// in for computes: `VerseSearchPack` (the ayah search index, the ranked search's lanes and the daily
/// card's flags) and the shipped cross-language lexicon. Each test builds the slow way and compares
/// with what the shipped file gives, so a fold, stem, skeleton or outline rule changed without a
/// re-export fails HERE instead of shipping a search that disagrees with the code.
///
/// `testExportWhenAsked` writes fresh files when `PRECOMPUTED_EXPORT_DIR` is set in the test host's
/// environment (`Scripts/export_precomputed_packs.sh` sets it through xcodebuild's `TEST_RUNNER_`
/// prefix and copies the files into Resources/Data/Quran); without it the test is skipped.
///
/// The packs are Hafs: a `-displayQiraah "<tag>"` launch persists that riwayah into the simulator's
/// defaults, and every test here then fails on its first assertion with the reset to run.
final class PrecomputedPackTests: XCTestCase {

    private static let hafsMessage = "the packs are Hafs: launch once with -displayQiraah \"\" first (a measurement launch persisted a riwayah into the simulator's defaults)"

    /// The live texts and the index built the slow way, once per process (each build is seconds).
    private static var fresh: (surahs: [Surah], entries: [VerseIndexEntry])?

    @MainActor
    private func freshBuild() async throws -> (surahs: [Surah], entries: [VerseIndexEntry]) {
        if let fresh = Self.fresh { return fresh }
        let data = QuranData.shared
        await data.waitUntilLoaded()
        XCTAssertNil(Settings.shared.displayQiraahForArabic, Self.hafsMessage)
        let surahs = data.quran
        XCTAssertEqual(surahs.count, 114)
        let built = await data.buildVerseIndexEntriesForTests(qiraahKey: "", surahs: surahs, allowPack: false)
        let entries = try XCTUnwrap(built)
        XCTAssertGreaterThanOrEqual(entries.count, 6236)
        Self.fresh = (surahs, entries)
        return (surahs, entries)
    }

    private func snapshot(_ entries: [VerseIndexEntry], surahs: [Surah]) -> QuranData.VerseSearchSnapshot {
        QuranData.VerseSearchSnapshot(qiraahKey: "", verseIndex: entries, allVerseIndices: Array(entries.indices),
                                      surahs: surahs, displayQiraah: nil)
    }

    private func assertSame(_ fresh: [VerseIndexEntry], _ packed: [VerseIndexEntry], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(fresh.count, packed.count, "entry count", file: file, line: line)
        for (a, b) in zip(fresh, packed) {
            // Scalars, not `==`: String equality is canonical equivalence, and the index must not drift
            // even by a composed form.
            XCTAssertEqual(a.id, b.id, file: file, line: line)
            XCTAssertEqual(a.surah, b.surah, file: file, line: line)
            XCTAssertEqual(a.ayah, b.ayah, file: file, line: line)
            XCTAssertEqual(a.surahOffset, b.surahOffset, a.id, file: file, line: line)
            XCTAssertEqual(a.ayahOffset, b.ayahOffset, a.id, file: file, line: line)
            XCTAssertEqual(Array(a.arabicBlob.utf8), Array(b.arabicBlob.utf8), "\(a.id) arabic", file: file, line: line)
            XCTAssertEqual(Array(a.silentArabicBlob.utf8), Array(b.silentArabicBlob.utf8), "\(a.id) silent", file: file, line: line)
            XCTAssertEqual(a.hamzaArabicBlob.map { Array($0.utf8) }, b.hamzaArabicBlob.map { Array($0.utf8) }, "\(a.id) hamza", file: file, line: line)
            XCTAssertEqual(Array(a.englishBlob.utf8), Array(b.englishBlob.utf8), "\(a.id) english", file: file, line: line)
        }
    }

    // MARK: - The shipped Hafs pack

    @MainActor
    func testShippedIndexMatchesFreshBuild() async throws {
        let (surahs, fresh) = try await freshBuild()
        let pack = try XCTUnwrap(VerseSearchPack.pack(for: "", surahs: surahs), "no usable quran-search.qsp in the bundle: run Scripts/export_precomputed_packs.sh")
        XCTAssertEqual(pack.quranFingerprint, VerseSearchPack.quranFingerprint)
        XCTAssertGreaterThanOrEqual(pack.recordCount, 6236)
        let read = await QuranData.shared.buildVerseIndexEntriesForTests(qiraahKey: "", surahs: surahs, allowPack: true)
        let packed = try XCTUnwrap(read)
        assertSame(fresh, packed)
    }

    @MainActor
    func testShippedLanesMatchFreshBuild() async throws {
        let (surahs, fresh) = try await freshBuild()
        XCTAssertNotNil(VerseSearchPack.pack(for: "", surahs: surahs), "no usable quran-search.qsp in the bundle: run Scripts/export_precomputed_packs.sh")
        let snapshot = snapshot(fresh, surahs: surahs)
        let built = QuranRankedSearch.lanesForTests(snapshot: snapshot, allowPack: false)
        let read = QuranRankedSearch.lanesForTests(snapshot: snapshot, allowPack: true)
        XCTAssertFalse(built.readFromPack)
        XCTAssertTrue(read.readFromPack)
        XCTAssertEqual(built.english.count, fresh.count)
        XCTAssertEqual(built.english, read.english)
        XCTAssertEqual(built.arabic, read.arabic)
        XCTAssertEqual(built.arabicStems, read.arabicStems)
        XCTAssertEqual(built.skeletonWords, read.skeletonWords)
        XCTAssertEqual(built.skeletonTight, read.skeletonTight)
        XCTAssertEqual(built.romanWords, read.romanWords)
        XCTAssertEqual(built.romanTight, read.romanTight)
        XCTAssertEqual(built.wordCounts, read.wordCounts)
        XCTAssertEqual(built.vocabulary, read.vocabulary)
        XCTAssertEqual(built.translationWords, read.translationWords)
        XCTAssertEqual(built.correctionsByLength, read.correctionsByLength)
        XCTAssertGreaterThan(read.vocabulary.count, 5_000)
    }

    /// The daily-card flags of every record say what the texts say, and the picker's pool is the one
    /// the live decision gives.
    @MainActor
    func testShippedDailyFlagsMatchTheTexts() async throws {
        let (surahs, _) = try await freshBuild()
        let pack = try XCTUnwrap(VerseSearchPack.dailyFlagsPack(), "the shipped pack was stamped with another blocked-word list: run Scripts/export_precomputed_packs.sh")
        var checked = 0
        var eligible = 0
        for surah in surahs {
            for ayah in surah.ayahs where !ayah.textHafs.isEmpty {
                let index = try XCTUnwrap(pack.recordIndex(surah: surah.id, ayah: ayah.id), "\(surah.id):\(ayah.id) has no record")
                let record = pack.record(at: index)
                XCTAssertEqual(record.surah, surah.id)
                XCTAssertEqual(record.ayah, ayah.id)
                let both = VerseSearchPack.Flag.gentle | VerseSearchPack.Flag.short
                XCTAssertEqual(record.flags & both, Settings.dailyCardFlags(for: ayah), "\(surah.id):\(ayah.id)")
                checked += 1
                if record.flags & both == both { eligible += 1 }
            }
        }
        XCTAssertGreaterThanOrEqual(checked, 6236)
        XCTAssertGreaterThan(eligible, 1_000, "the daily pool is thousands of ayahs")
        // Through the picker itself: the same ayah for a fixed day as the texts alone would give is
        // what `gentleAyahRefs` promises; the pool size is what we can see from here.
        XCTAssertNotNil(Settings.shared.ayahOfTheDayReference(for: Date(timeIntervalSince1970: 1_700_000_000)))
    }

    @MainActor
    func testShippedLexiconMatchesFreshBuild() async throws {
        let (surahs, _) = try await freshBuild()
        let shipped = try XCTUnwrap(CrossLanguageWordHighlight.bundledLexiconForTests(), "no usable CrossLanguageLexicon.bin in the bundle: run Scripts/export_precomputed_packs.sh")
        let built = CrossLanguageWordHighlight.buildLexiconTableForTests(surahs: surahs)
        XCTAssertGreaterThan(built.count, 10_000)
        XCTAssertEqual(built.count, shipped.count)
        XCTAssertEqual(built, shipped)
    }

    // MARK: - The codec on its own

    /// A synthetic pack round-trips byte for byte, including an empty field, a nil hamza blob and a
    /// surah with a gap in it, and damaged files are refused rather than read.
    func testPackCodecRoundTrips() throws {
        func record(_ surah: Int, _ ayah: Int, flags: UInt16, hamza: [UInt8]?) -> VerseSearchPack.RecordInput {
            VerseSearchPack.RecordInput(surah: surah, ayah: ayah, flags: flags, wordCount: ayah * 3,
                                        arabic: Array("ارابيك \(surah) \(ayah)".utf8), silent: Array("silent".utf8), hamza: hamza,
                                        english: Array(" in the name of allah \(ayah) ".utf8), arabicStems: [0x20, 0x61, 0x20],
                                        skeletonWords: Array("skel".utf8), skeletonTight: [], romanWords: [0x20],
                                        romanTight: Array("rmn".utf8))
        }
        let records = [record(1, 1, flags: 3, hamza: Array("hmz".utf8)), record(1, 2, flags: 0, hamza: nil),
                       record(1, 3, flags: 1, hamza: []), record(2, 1, flags: 2, hamza: nil)]
        let data = try XCTUnwrap(VerseSearchPack.encode(qiraahKey: "", quranFingerprint: 42, blockedWordFingerprint: 7,
                                                        records: records, vocabulary: ["name", "allah", "beneficent"],
                                                        translationWords: ["name"]))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("codec-\(UUID().uuidString).qsp")
        try data.write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        let pack = try XCTUnwrap(VerseSearchPack.Pack(url: url))
        XCTAssertEqual(pack.qiraahKey, "")
        XCTAssertEqual(pack.quranFingerprint, 42)
        XCTAssertEqual(pack.blockedWordFingerprint, 7)
        XCTAssertEqual(pack.recordCount, 4)
        XCTAssertEqual(pack.vocabulary, ["allah", "beneficent", "name"])
        XCTAssertEqual(pack.translationWords, ["name"])
        for input in records {
            let index = try XCTUnwrap(pack.recordIndex(surah: input.surah, ayah: input.ayah))
            let read = pack.record(at: index)
            XCTAssertEqual(read.surah, input.surah)
            XCTAssertEqual(read.ayah, input.ayah)
            XCTAssertEqual(read.wordCount, input.wordCount)
            XCTAssertEqual(read.flags & 3, input.flags)
            XCTAssertEqual(read.flags & VerseSearchPack.Flag.hamzaPresent != 0, input.hamza != nil)
            XCTAssertEqual(pack.bytes(read, field: VerseSearchPack.Field.arabic), input.arabic)
            XCTAssertEqual(pack.string(read, field: VerseSearchPack.Field.arabic), String(decoding: input.arabic, as: UTF8.self))
            XCTAssertEqual(pack.bytes(read, field: VerseSearchPack.Field.silent), input.silent)
            XCTAssertEqual(pack.bytes(read, field: VerseSearchPack.Field.hamza), input.hamza ?? [])
            XCTAssertEqual(pack.bytes(read, field: VerseSearchPack.Field.english), input.english)
            XCTAssertEqual(pack.bytes(read, field: VerseSearchPack.Field.arabicStems), input.arabicStems)
            XCTAssertEqual(pack.bytes(read, field: VerseSearchPack.Field.skeletonWords), input.skeletonWords)
            XCTAssertEqual(pack.bytes(read, field: VerseSearchPack.Field.skeletonTight), input.skeletonTight)
            XCTAssertEqual(pack.bytes(read, field: VerseSearchPack.Field.romanWords), input.romanWords)
            XCTAssertEqual(pack.bytes(read, field: VerseSearchPack.Field.romanTight), input.romanTight)
        }
        XCTAssertNil(pack.recordIndex(surah: 1, ayah: 4))
        XCTAssertNil(pack.recordIndex(surah: 2, ayah: 2))
        XCTAssertNil(pack.recordIndex(surah: 3, ayah: 1))
        XCTAssertNil(pack.recordIndex(surah: 0, ayah: 1))

        func refused(_ bytes: Data, _ what: String) {
            let damaged = url.deletingLastPathComponent().appendingPathComponent("damaged-\(UUID().uuidString).qsp")
            try? bytes.write(to: damaged)
            defer { try? FileManager.default.removeItem(at: damaged) }
            XCTAssertNil(VerseSearchPack.Pack(url: damaged), what)
        }
        refused(data.prefix(data.count - 1), "truncated")
        refused(data + Data([0]), "appended byte")
        var wrongMagic = data
        wrongMagic[0] = wrongMagic[0] &+ 1
        refused(wrongMagic, "wrong magic")
        var wrongFormat = data
        wrongFormat[4] = wrongFormat[4] &+ 1
        refused(wrongFormat, "wrong format")
        // A record out of order is refused as a whole: the lookups are arithmetic on the ayah ids.
        let shuffled = try XCTUnwrap(VerseSearchPack.encode(qiraahKey: "", quranFingerprint: 42, blockedWordFingerprint: 7,
                                                            records: [records[1], records[0]], vocabulary: [], translationWords: []))
        refused(shuffled, "ayahs out of order")

        // A riwayah key survives, and the same records give the same bytes.
        let keyed = try XCTUnwrap(VerseSearchPack.encode(qiraahKey: "Warsh an Nafi", quranFingerprint: 1, blockedWordFingerprint: 2,
                                                         records: records, vocabulary: ["b", "a"], translationWords: []))
        let keyedURL = url.deletingLastPathComponent().appendingPathComponent("keyed-\(UUID().uuidString).qsp")
        try keyed.write(to: keyedURL)
        defer { try? FileManager.default.removeItem(at: keyedURL) }
        XCTAssertEqual(VerseSearchPack.Pack(url: keyedURL)?.qiraahKey, "Warsh an Nafi")
        XCTAssertEqual(VerseSearchPack.Pack(url: keyedURL)?.vocabulary, ["a", "b"])
        XCTAssertEqual(data, VerseSearchPack.encode(qiraahKey: "", quranFingerprint: 42, blockedWordFingerprint: 7,
                                                    records: records, vocabulary: ["allah", "name", "beneficent"], translationWords: ["name"]))
    }

    // MARK: - Export

    /// Writes quran-search.qsp and CrossLanguageLexicon.bin from a live build into PRECOMPUTED_EXPORT_DIR,
    /// then reads both back through the app's own loaders.
    @MainActor
    func testExportWhenAsked() async throws {
        guard let directory = ProcessInfo.processInfo.environment["PRECOMPUTED_EXPORT_DIR"], !directory.isEmpty else {
            throw XCTSkip("set TEST_RUNNER_PRECOMPUTED_EXPORT_DIR to export the packs (Scripts/export_precomputed_packs.sh)")
        }
        let (surahs, fresh) = try await freshBuild()
        try XCTSkipIf(Settings.shared.displayQiraahForArabic != nil, Self.hafsMessage)
        let folder = URL(fileURLWithPath: directory, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let snapshot = snapshot(fresh, surahs: surahs)
        let inputs = QuranRankedSearch.packInputsForTests(snapshot: snapshot)
        XCTAssertEqual(inputs.records.count, 6236, "one record per Hafs ayah")
        let quranFingerprint = try XCTUnwrap(VerseSearchPack.quranFingerprint)
        let search = try XCTUnwrap(VerseSearchPack.encode(
            qiraahKey: "", quranFingerprint: quranFingerprint,
            blockedWordFingerprint: VerseSearchPack.blockedWordFingerprint(Settings.dailyCardBlockedWords),
            records: inputs.records, vocabulary: inputs.vocabulary, translationWords: inputs.translationWords))
        let searchURL = folder.appendingPathComponent("quran-search.qsp")
        try search.write(to: searchURL, options: .atomic)
        let readBack = try XCTUnwrap(VerseSearchPack.Pack(url: searchURL))
        XCTAssertEqual(readBack.recordCount, inputs.records.count)
        XCTAssertEqual(readBack.quranFingerprint, quranFingerprint)
        XCTAssertEqual(Set(readBack.vocabulary), Set(inputs.vocabulary))

        let table = CrossLanguageWordHighlight.buildLexiconTableForTests(surahs: surahs)
        XCTAssertGreaterThan(table.count, 10_000)
        let lexicon = try XCTUnwrap(CrossLanguageWordHighlight.exportLexiconForTests(table))
        let lexiconURL = folder.appendingPathComponent("CrossLanguageLexicon.bin")
        try lexicon.write(to: lexiconURL, options: .atomic)
        XCTAssertEqual(CrossLanguageWordHighlight.decodeLexiconForTests(lexicon), table)

        NSLog("PRECOMPUTED EXPORT %@ (%d KB) and %@ (%d KB)", searchURL.path, search.count / 1024, lexiconURL.path, lexicon.count / 1024)
    }
}
