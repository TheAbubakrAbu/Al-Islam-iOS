import Foundation

// Builds the app's existing model types out of the .qpk packs, so switching away from the
// bundled JSON is a call-site swap rather than a rewrite of QuranData.
//
// Deliberately produces EXACTLY what `JSONDecoder` produced from Quran.json / SurahInfos.json /
// Qiraat/*.json - same fields, same optionality, same derived values - so nothing downstream
// (search indexes, boundary models, the caches, the views) has to change or even know.
//
// Verified against the JSON decode path with 135k+ assertions; see
// Quran-Tajweed-Engine/docs/09-qpk-format.md.
//
// ONE SUBTLETY WORTH KNOWING, because it is a silent-corruption trap:
//
//   `Ayah.init(from decoder:)` takes `wordCount` from the JSON when the key is present, and only
//   falls back to counting spaces when it is absent. The memberwise `Ayah.init(...)` ALWAYS
//   recomputes it. Those disagree for 199 of the 6,236 ayahs - the dataset's counts are not a
//   plain space-split. So this adapter must NOT build ayahs through the memberwise init, or
//   those 199 word counts would quietly change. It uses `init(packed:)` below, which carries the
//   packed counts through untouched.
//
//   `Surah`'s memberwise init sums its ayahs' counts, and the dataset's surah totals equal the
//   sum of their ayahs exactly (verified, 0 of 114 differ), so surahs are safe to build normally.

extension Ayah {
    /// Builds an ayah from packed values, preserving `wordCount` / `letterCount` exactly as the
    /// dataset holds them instead of recomputing. See the note above.
    init(packed id: Int, textHafs: String, textTransliteration: String,
         textEnglishSaheeh: String, textEnglishMustafa: String,
         juz: Int?, page: Int?, wordCount: Int, letterCount: Int,
         textWarsh: String?, textQaloon: String?, textDuri: String?,
         textBuzzi: String?, textQunbul: String?, textShubah: String?, textSusi: String?) {
        self.id = id
        self.idArabic = arabicNumberString(from: id)
        self.textHafs = textHafs
        self.textTransliteration = textTransliteration
        self.textEnglishSaheeh = textEnglishSaheeh
        self.textEnglishMustafa = textEnglishMustafa
        self.juz = juz
        self.page = page
        self.wordCount = wordCount
        self.letterCount = letterCount
        self.textWarsh = textWarsh
        self.textQaloon = textQaloon
        self.textDuri = textDuri
        self.textBuzzi = textBuzzi
        self.textQunbul = textQunbul
        self.textShubah = textShubah
        self.textSusi = textSusi
    }
}

/// Loads the Quran, the qiraat, and the surah-info prose from the bundled packs.
enum QuranPackLoader {

    /// Where to look for the packs. Normally the app bundle; a directory can be injected so the
    /// loader can be exercised outside an app (the verifier does exactly that).
    static var packDirectory: URL?

    /// Pack file names, and where Xcode may have put them. Internal: every `.qpk` lookup in the
    /// app (including NamesView's and the semantic-corpus stamp's) goes through this one probe.
    static func url(_ name: String) -> URL? {
        if let directory = packDirectory {
            let candidate = directory.appendingPathComponent("\(name).qpk")
            return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
        }
        return Bundle.main.url(forResource: name, withExtension: "qpk", subdirectory: "Quran")
            ?? Bundle.main.url(forResource: name, withExtension: "qpk", subdirectory: "Data/Quran")
            ?? Bundle.main.url(forResource: name, withExtension: "qpk")
    }

    /// Riwayah key in the pack → the `Ayah` field it populates. Mirrors `QuranData.qiraatKeys`.
    private static let qiraatFields: [(packKey: String, field: String)] = [
        ("warsh", "textWarsh"), ("qaloon", "textQaloon"), ("duri", "textDuri"),
        ("bazzi", "textBuzzi"), ("qunbul", "textQunbul"), ("shubah", "textShubah"),
        ("susi", "textSusi"),
    ]

    /// The highest ayah NUMBER any of the twelve BETA riwayat uses per surah, where it exceeds the
    /// Hafs/bundled-overlay union (measured across the shipped QiraahBeta payloads). The Shami count
    /// splits verses Hafs joins - al-Ikhlas is FIVE ayahs there - and without an `Ayah` struct for
    /// the extra id, the riwayah's final verse did not exist ANYWHERE in the app: not in the list,
    /// not on a mushaf page, not in search (the "missing a verse" bug). Structs minted for these ids
    /// carry empty Hafs text, so `existsInQiraah` keeps them invisible everywhere except the riwayat
    /// whose side-table actually has words for them - identical to how the 156 bundled-overlay extra
    /// ids already behave.
    private static let betaMaxAyahID: [Int: Int] = [
        2: 287, 4: 177, 5: 123, 6: 167, 8: 77, 9: 130, 10: 110, 13: 47, 14: 55, 18: 111,
        20: 140, 23: 119, 27: 95, 34: 55, 35: 46, 40: 86, 47: 40, 56: 99, 71: 30, 78: 41,
        89: 32, 91: 16, 96: 20, 97: 6, 98: 9, 99: 9, 106: 5, 112: 5, 114: 7,
    ]

    /// `field` → surah id → ayah id → text. Same shape `loadQiraatOverlay()` returns, so it can
    /// be dropped in unchanged. Empty strings are skipped, exactly as the JSON path does.
    static func qiraatOverlay() -> [String: [Int: [Int: String]]] {
        guard let url = url("qiraat"), let pack = QiraatPack(url: url) else { return [:] }
        var result: [String: [Int: [Int: String]]] = [:]
        for (packKey, field) in qiraatFields {
            guard let surahs = pack.allAyahs(reading: packKey) else { continue }
            var bySurah: [Int: [Int: String]] = [:]
            bySurah.reserveCapacity(surahs.count)
            for entry in surahs {
                var lookup: [Int: String] = [:]
                lookup.reserveCapacity(entry.ayahs.count)
                for a in entry.ayahs where !a.text.isEmpty { lookup[a.id] = a.text }
                bySurah[entry.surah] = lookup
            }
            result[field] = bySurah
        }
        return result
    }

    /// The whole Quran. `includeQiraat` mirrors the existing flag: most users never look at
    /// another reading, so the overlay is only merged when one is actually shown.
    ///
    /// Returns nil if the pack is missing or unreadable, so a caller can fall back to the JSON
    /// path during migration rather than launching into an empty Quran.
    static func quran(includeQiraat: Bool) -> [Surah]? {
        guard let url = url("quran"), let pack = QuranPack(url: url) else { return nil }
        // All four text blocks decoded at once across the cores (see `materializeAllBlocks`), so the
        // sequential row walk below never waits on LZMA.
        pack.materializeAllBlocks()
        let overlay = includeQiraat ? qiraatOverlay() : [:]

        var surahs: [Surah] = []
        surahs.reserveCapacity(pack.surahs.count)

        for meta in pack.surahs {
            var ayahs: [Ayah] = []

            if overlay.isEmpty {
                // The common case (Hafs only): the pack already stores rows ascending, so walk them
                // directly - no dictionary, no id-set union, no sort.
                ayahs.reserveCapacity(meta.numberOfAyahs)
                for offset in 0..<meta.numberOfAyahs {
                    let row = meta.firstRow + offset
                    guard row < pack.ayahs.count, let text = pack.text(row: row) else { continue }
                    let scalars = pack.ayahs[row]
                    ayahs.append(Ayah(
                        packed: scalars.id,
                        textHafs: text.arabic,
                        textTransliteration: text.transliteration,
                        textEnglishSaheeh: text.englishSaheeh,
                        textEnglishMustafa: text.englishMustafa,
                        juz: scalars.juz, page: scalars.page,
                        wordCount: scalars.wordCount,
                        letterCount: scalars.letterCount,
                        textWarsh: nil, textQaloon: nil, textDuri: nil,
                        textBuzzi: nil, textQunbul: nil, textShubah: nil, textSusi: nil))
                }
            } else {
                // Base ayahs, straight out of the pack.
                var baseByID: [Int: (text: QuranPack.AyahText, scalars: QuranPack.AyahMeta)] = [:]
                baseByID.reserveCapacity(meta.numberOfAyahs)
                for offset in 0..<meta.numberOfAyahs {
                    let row = meta.firstRow + offset
                    guard row < pack.ayahs.count, let text = pack.text(row: row) else { continue }
                    baseByID[pack.ayahs[row].id] = (text, pack.ayahs[row])
                }

                // A qiraah can carry ayah numbers Hafs does not have - Warsh splits some verses that
                // Hafs joins, so 156 ids across the seven readings fall outside the Hafs set. The JSON
                // path unions them in, and dropping them would silently lose those verses whenever a
                // reader switched riwayah.
                var allIDs = Set(baseByID.keys)
                for (_, field) in qiraatFields {
                    if let ids = overlay[field]?[meta.id]?.keys { allIDs.formUnion(ids) }
                }
                // The BETA riwayat can count past the bundled union too (see `betaMaxAyahID`).
                if let betaMax = betaMaxAyahID[meta.id], let unionMax = allIDs.max(), betaMax > unionMax {
                    allIDs.formUnion((unionMax + 1)...betaMax)
                }

                // Per-surah overlay tables hoisted out of the ayah loop (the field+surah lookup is
                // loop-invariant; only the ayah lookup varies).
                let surahOverlays = qiraatFields.map { overlay[$0.field]?[meta.id] }

                ayahs.reserveCapacity(allIDs.count)
                for ayahID in allIDs.sorted() {
                    let base = baseByID[ayahID]
                    ayahs.append(Ayah(
                        packed: ayahID,
                        textHafs: base?.text.arabic ?? "",
                        textTransliteration: base?.text.transliteration ?? "",
                        textEnglishSaheeh: base?.text.englishSaheeh ?? "",
                        textEnglishMustafa: base?.text.englishMustafa ?? "",
                        juz: base?.scalars.juz, page: base?.scalars.page,
                        // Ayahs that exist only in a qiraah have no Hafs text, so there is nothing to
                        // count; 0 matches what the JSON path produces for them.
                        wordCount: base?.scalars.wordCount ?? 0,
                        letterCount: base?.scalars.letterCount ?? 0,
                        textWarsh: surahOverlays[0]?[ayahID], textQaloon: surahOverlays[1]?[ayahID],
                        textDuri: surahOverlays[2]?[ayahID], textBuzzi: surahOverlays[3]?[ayahID],
                        textQunbul: surahOverlays[4]?[ayahID], textShubah: surahOverlays[5]?[ayahID],
                        textSusi: surahOverlays[6]?[ayahID]))
                }
            }

            surahs.append(Surah(
                id: meta.id,
                idArabic: arabicNumberString(from: meta.id),
                nameArabic: meta.nameArabic,
                nameTransliteration: meta.nameTransliteration,
                nameEnglish: meta.nameEnglish,
                similarNames: meta.similarNames,
                type: meta.isMakkan ? "makkan" : "madinan",
                numberOfAyahs: meta.numberOfAyahs,
                revelationOrder: meta.revelationOrder,
                revelationExceptions: meta.revelationExceptions,
                pageStart: meta.pageStart,
                pageEnd: meta.pageEnd,
                numberOfPages: meta.numberOfPages,
                // Absent from the dataset, so the JSON path decodes it as nil. Keep it nil.
                isLessThanOnePage: nil,
                firstJuz: meta.firstJuz,
                lastJuz: meta.lastJuz,
                juzs: meta.juzs,
                juzChangesWithinSurah: meta.juzChangesWithinSurah,
                ayahs: ayahs))
        }
        return surahs
    }

    /// The surah-info pack, opened once (mmap + eager parse) and kept - `surahInfo(surah:)` is a
    /// per-view-open call and re-opening the container each time defeated the one-block-per-surah
    /// layout. The container's block cache is budget-bounded and purgeable.
    private static let surahInfoPack: SurahInfoPack? = {
        guard let url = url("surahinfos") else { return nil }
        return SurahInfoPack(url: url)
    }()

    /// The info sources for ONE surah, decompressing only that surah's block - the reason the pack
    /// keeps 114 separate blocks. (The old eager `surahInfos()` decompressed all 114 on first open.)
    static func surahInfo(surah: Int) -> [SurahInfoSource] {
        surahInfoPack?.sources(surah: surah).map { SurahInfoSource(name: $0.name, contents: $0.contents) } ?? []
    }
}
