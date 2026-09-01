#if DEBUG && os(iOS)
import Foundation
import Compression

/// "-auditPacks": walk every bundled pack and loose payload through the app's OWN readers and
/// fingerprint what they hand back, then write the report to Documents/packaudit.txt (and print
/// it). A repack (Scripts/reblock_packs.py, a deflate → xz swap, ...) is proven content-identical
/// by running this once before and once after and diffing the two reports: same rows, same
/// strings, same search hits, same hashes. Block indices are deliberately left out of every
/// hash - they are the one thing a repack is allowed to change.
enum PackAudit {
    /// FNV-1a 64 over UTF-8, a record separator after every field. Not `Hasher`, which is seeded
    /// per process and would never agree between two runs.
    private struct Fingerprint {
        private(set) var value: UInt64 = 0xcbf2_9ce4_8422_2325
        private(set) var fields = 0

        mutating func add(_ text: String) {
            for byte in text.utf8 {
                value ^= UInt64(byte)
                value = value &* 0x0000_0100_0000_01B3
            }
            value ^= 0x1E
            value = value &* 0x0000_0100_0000_01B3
            fields += 1
        }

        mutating func add(_ number: Int) { add(String(number)) }
        mutating func add(_ flag: Bool) { add(flag ? "1" : "0") }

        var hex: String { String(value, radix: 16) }
    }

    static func run() {
        var lines: [String] = []
        func emit(_ line: String) {
            lines.append(line)
            print("PACK AUDIT \(line)")
        }

        func bundled(_ name: String, _ ext: String) -> URL? {
            Bundle.main.url(forResource: name, withExtension: ext)
                ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Data/Quran")
                ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Quran")
        }

        // MARK: Hadith packs

        let hpkURLs = (Bundle.main.urls(forResourcesWithExtension: "hpk", subdirectory: nil) ?? [])
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        let queries = ["الصلاة", "prayer", "زكاة", "fasting", "عن أبي هريرة"].map(HadithFold.query)
        for url in hpkURLs {
            let slug = url.deletingPathExtension().lastPathComponent
            guard let pack = HadithPack(slug: slug, url: url) else {
                emit("HPK \(slug) FAILED TO OPEN")
                continue
            }
            var meta = Fingerprint()
            for title in [pack.arabicTitle, pack.arabicAuthor, pack.englishTitle, pack.englishAuthor] { meta.add(title) }
            for chapter in pack.chapters {
                meta.add(chapter.id); meta.add(chapter.firstRow); meta.add(chapter.rowCount)
                meta.add(chapter.arabic); meta.add(chapter.english); meta.add(chapter.foldArabic); meta.add(chapter.foldEnglish)
            }
            for row in pack.rows {
                meta.add(Int(row.id)); meta.add(Int(row.idInBook)); meta.add(Int(row.chapterId))
                meta.add(Int(row.citationBase)); meta.add(Int(row.citationSuffix)); meta.add(Int(row.flags))
            }
            var text = Fingerprint()
            var empties = 0
            for row in 0..<pack.rows.count {
                let strings = pack.strings(row: row)
                if strings.arabic.isEmpty && strings.text.isEmpty { empties += 1 }
                text.add(strings.arabic); text.add(strings.narrator); text.add(strings.text)
                text.add(pack.string(row: row, field: 3))
            }
            var hits: [Int] = []
            for query in queries {
                hits.append((0..<pack.rows.count).filter { pack.matches(row: $0, query: query) }.count)
            }
            emit("HPK \(slug) chapters=\(pack.chapters.count) rows=\(pack.rows.count) empty=\(empties) "
                 + "meta=\(meta.hex) text=\(text.hex)/\(text.fields) hits=\(hits) foldOK=\(pack.foldMatchesApp)")
        }

        // MARK: Quran packs (the ayah counts drive the tafsir walk below)

        var ayahCounts: [Int: Int] = [:]
        if let url = bundled("quran", "qpk"), let pack = QuranPack(url: url) {
            var meta = Fingerprint()
            for s in pack.surahs {
                meta.add(s.id); meta.add(s.isMakkan); meta.add(s.nameArabic); meta.add(s.nameTransliteration)
                meta.add(s.nameEnglish); meta.add(s.revelationExceptions); meta.add(s.numberOfAyahs)
                meta.add(s.pageStart); meta.add(s.pageEnd); meta.add(s.numberOfPages); meta.add(s.firstJuz)
                meta.add(s.lastJuz); meta.add(s.revelationOrder); meta.add(s.wordCount); meta.add(s.letterCount)
                meta.add(s.juzChangesWithinSurah); meta.add(s.juzs.map(String.init).joined(separator: ","))
                meta.add(s.similarNames.joined(separator: "|")); meta.add(s.firstRow)
                ayahCounts[s.id] = s.numberOfAyahs
            }
            for a in pack.ayahs {
                meta.add(a.id); meta.add(a.juz); meta.add(a.page); meta.add(a.wordCount); meta.add(a.letterCount)
            }
            var text = Fingerprint()
            var missing = 0
            for row in 0..<pack.ayahs.count {
                guard let t = pack.text(row: row) else { missing += 1; continue }
                text.add(t.arabic); text.add(t.transliteration); text.add(t.englishSaheeh); text.add(t.englishMustafa)
            }
            emit("QPK quran surahs=\(pack.surahs.count) ayahs=\(pack.ayahs.count) missing=\(missing) meta=\(meta.hex) text=\(text.hex)/\(text.fields)")
        } else {
            emit("QPK quran FAILED TO OPEN")
        }

        if let url = bundled("qiraat", "qpk"), let pack = QiraatPack(url: url) {
            for reading in pack.readings {
                var fp = Fingerprint()
                fp.add(reading.key)
                fp.add(reading.surahOrder.map(String.init).joined(separator: ","))
                fp.add(reading.ayahCounts.keys.sorted().map { "\($0):\(reading.ayahCounts[$0] ?? 0)" }.joined(separator: ","))
                var ayahs = 0
                if let surahs = pack.allAyahs(reading: reading.key) {
                    for entry in surahs {
                        fp.add(entry.surah)
                        for a in entry.ayahs { fp.add(a.id); fp.add(a.text); ayahs += 1 }
                    }
                } else {
                    fp.add("ALLAYAHS FAILED")
                }
                emit("QPK qiraat \(reading.key) surahs=\(reading.surahOrder.count) ayahs=\(ayahs) hash=\(fp.hex)/\(fp.fields)")
            }
        } else {
            emit("QPK qiraat FAILED TO OPEN")
        }

        if let url = bundled("surahinfos", "qpk"), let pack = SurahInfoPack(url: url) {
            var fp = Fingerprint()
            var sources = 0
            for entry in pack.entries {
                fp.add(entry.id)
                fp.add(entry.sourceNames.joined(separator: "|"))
                for (name, contents) in pack.sources(surah: entry.id) { fp.add(name); fp.add(contents); sources += 1 }
            }
            emit("QPK surahinfos entries=\(pack.entries.count) sources=\(sources) hash=\(fp.hex)/\(fp.fields)")
        } else {
            emit("QPK surahinfos FAILED TO OPEN")
        }

        if let url = Bundle.main.url(forResource: "namesofallah", withExtension: "qpk")
            ?? Bundle.main.url(forResource: "namesofallah", withExtension: "qpk", subdirectory: "Data"),
           let pack = NamesPack(url: url) {
            var fp = Fingerprint()
            for r in pack.records {
                fp.add(r.number); fp.add(r.name); fp.add(r.transliteration); fp.add(r.found); fp.add(r.meaning)
                fp.add(r.desc); fp.add(r.otherNames.joined(separator: "|"))
            }
            emit("QPK namesofallah records=\(pack.records.count) hash=\(fp.hex)/\(fp.fields)")
        } else {
            emit("QPK namesofallah FAILED TO OPEN")
        }

        // MARK: Tafsir packs

        let tpkURLs = (Bundle.main.urls(forResourcesWithExtension: "tpk", subdirectory: nil) ?? [])
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        for url in tpkURLs {
            let slug = url.deletingPathExtension().lastPathComponent
            guard let pack = TafsirPack(slug: slug, url: url) else {
                emit("TPK \(slug) FAILED TO OPEN")
                continue
            }
            var fp = Fingerprint()
            fp.add(pack.title)
            var entries = 0, missing = 0
            for surah in 1...114 {
                for ayah in 1...max(1, ayahCounts[surah] ?? 0) {
                    guard let entry = pack.entry(surah: surah, ayah: ayah) else { missing += 1; continue }
                    fp.add(entry.groupVerse ?? "<nil>"); fp.add(entry.content); fp.add(entry.groupStart); fp.add(entry.groupEnd)
                    entries += 1
                }
            }
            emit("TPK \(slug) entries=\(entries) missing=\(missing) hash=\(fp.hex)/\(fp.fields)")
        }

        // MARK: Loose JSON payloads (deflate or xz, whichever ships)

        for name in ["SimilarAyahs", "WordByWord", "ThematicTopics", "SurahSections", "TajweedLessons"] {
            var raw: Data?
            var ext = "?"
            if let url = bundled(name, "json.xz"), let blob = try? Data(contentsOf: url) {
                ext = "json.xz"
                raw = SolidPack.xzDecompress(blob)
            } else if let url = bundled(name, "json.deflate"), let blob = try? Data(contentsOf: url) {
                ext = "json.deflate"
                raw = inflate(blob)
            }
            guard let json = raw else {
                emit("JSON \(name) MISSING OR UNDECODABLE (\(ext))")
                continue
            }
            var fp = Fingerprint()
            fp.add(String(decoding: json, as: UTF8.self))
            let parses = (try? JSONSerialization.jsonObject(with: json)) != nil
            emit("JSON \(name) ext=\(ext) bytes=\(json.count) parses=\(parses) hash=\(fp.hex)")
        }

        // MARK: Word-by-word layers
        //
        // The pack's own gate (Scripts/verify_wordbyword.py) proves the two layers line up with the
        // app's tokens; this proves the SHIPPED pack still does after a repack, through the reader the
        // app actually uses. The two counts must stay equal: a word with a meaning has a pronunciation.
        if WordByWordStore.isBundled {
            var fp = Fingerprint()
            var tokens = 0, glossed = 0, transliterated = 0, unaligned = 0
            for surah in 1...114 {
                for ayah in 1...max(1, ayahCounts[surah] ?? 0) {
                    guard let glosses = WordByWordStore.shared.glosses(surah: surah, ayah: ayah),
                          let latin = WordByWordStore.shared.transliterations(surah: surah, ayah: ayah),
                          glosses.count == latin.count else { unaligned += 1; continue }
                    tokens += glosses.count
                    glossed += glosses.count { !$0.isEmpty }
                    transliterated += latin.count { !$0.isEmpty }
                    for (gloss, translit) in zip(glosses, latin) { fp.add(gloss); fp.add(translit) }
                }
            }
            emit("WBW tokens=\(tokens) glossed=\(glossed) transliterated=\(transliterated) "
                 + "unaligned=\(unaligned) hash=\(fp.hex)")
            for (surah, ayah) in [(1, 1), (2, 255), (112, 1)] {
                let glosses = WordByWordStore.shared.glosses(surah: surah, ayah: ayah) ?? []
                let latin = WordByWordStore.shared.transliterations(surah: surah, ayah: ayah) ?? []
                emit("WBW probe \(surah):\(ayah) -> \(Array(zip(latin, glosses).prefix(4)))")
            }
        } else {
            emit("WBW pack NOT BUNDLED")
        }

        // MARK: Islam article corpus

        // Read through IslamArticles itself, so this proves the SHIPPED pack decodes with the
        // shipped reader - and the probes prove the retrieval lane actually finds the right article.
        let corpus = IslamArticles.all
        if corpus.isEmpty {
            emit("ISLAM corpus FAILED TO LOAD")
        } else {
            var fp = Fingerprint()
            for article in corpus {
                fp.add(article.id); fp.add(article.title); fp.add(article.sections.count)
                for section in article.sections { fp.add(section.heading); fp.add(section.text) }
            }
            let chars = corpus.reduce(0) { $0 + $1.sections.reduce(0) { $0 + $1.text.count } }
            emit("ISLAM corpus articles=\(corpus.count) chars=\(chars) hash=\(fp.hex)")
            for probe in ["how do i make wudhu", "what breaks the fast", "five pillars of islam",
                          "what is tawhid", "who was ibn taymiyyah", "sunnah rakahs before dhuhr"] {
                let hits = IslamArticles.search(probe, limit: 3).map(\.article.title)
                emit("ISLAM probe \"\(probe)\" -> \(hits)")
            }
        }

        emit("DONE \(lines.count) lines")
        let report = lines.joined(separator: "\n") + "\n"
        if let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? report.write(to: documents.appendingPathComponent("packaudit.txt"), atomically: true, encoding: .utf8)
        }
    }

    /// Raw deflate (no zlib header), the loose payloads' old wrapping.
    private static func inflate(_ data: Data) -> Data? {
        let capacity = max(data.count * 16, 1 << 23)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        defer { buffer.deallocate() }
        let written = data.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) -> Int in
            guard let base = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return 0 }
            return compression_decode_buffer(buffer, capacity, base, data.count, nil, COMPRESSION_ZLIB)
        }
        guard written > 0 else { return nil }
        return Data(bytes: buffer, count: written)
    }
}
#endif
