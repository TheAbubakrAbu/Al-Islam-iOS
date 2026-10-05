import Foundation

/// The ayah search index and the ranked search's corpus lanes, precomputed once per build of the app
/// and shipped, instead of folded on every launch (Phase 10.14, Abu, 2026-10-04: "make things as
/// preprocessed as possible").
///
/// WHY: `QuranData.buildVerseIndexEntries` folded the 6,236 ayahs' Arabic three ways, their silent and
/// hamza folds and the three Latin texts after every reveal on the full tier (1.5 s of CPU in the
/// Debug launch profile), and `QuranRankedSearch.Lanes` then stemmed, skeletonised and sound-outlined
/// the same ayahs again (1.2 s). Both are pure functions of the texts in quran.qpk and of the fold
/// tables compiled into the app, so one build does them once, in the UnitTests target, and ships the
/// result as Resources/Data/Quran/quran-search.qsp: uncompressed, memory-mapped, read in tens of
/// milliseconds. The loaders rebuild the very same `VerseIndexEntry` values and lane byte arrays from
/// it, so nothing downstream knows the difference.
///
/// WHAT GUARDS IT: the header carries the quran.qpk source fingerprint (a pack built from other texts
/// is refused and the live build runs as before), the `format` number (bumped by hand when a fold or
/// lane rule changes) and the fingerprint of the daily card's blocked-word list for the gentle flags.
/// `UnitTests/PrecomputedPackTests` builds the index and the lanes afresh and compares every byte with
/// what the shipped file yields, so a rule change without a re-export fails the suite rather than
/// shipping a stale search. The export is that same test with `PRECOMPUTED_EXPORT_DIR` set
/// (`Scripts/export_precomputed_packs.sh` does it and copies the files into Resources).
///
/// OTHER RIWAYAT: the displayed riwayah changes the Arabic lanes, so a pack is keyed by the qiraah
/// key and only Hafs ("") ships. The first ranked search under another riwayah builds as before and
/// writes the pack to Caches/VerseSearch for this build of the app, the lexicon's arrangement (10.12).
///
/// DAILY FLAGS (10.15): each record also says whether its ayah is a candidate for the Ayah of the Day
/// (free of the blocked words; short enough for the card). `Settings.gentleAyahRefs` used to decide
/// that by lower-casing and word-splitting both translations of all 6,236 ayahs on the MAIN thread,
/// 200 ms inside the Quran tab's first body.
///
/// FILE LAYOUT, little-endian throughout:
///   header     u32 magic "QSP1", u32 format, u64 quran fingerprint, u64 blocked-word fingerprint,
///              u32 record count, u32 records offset, u32 blob offset, u32 blob length,
///              u32 vocabulary offset, u32 translation-words offset, u32 file length,
///              u16 key length, key bytes (the qiraah key)
///   records    record count x 48 bytes: u16 surah, u16 ayah, u16 flags, u16 word count,
///              u32 start of the record's bytes in the blob, 9 x u32 field lengths, the fields
///              following each other in the blob in this order: arabic blob, silent blob, hamza
///              blob (empty when the entry has none), english blob, arabic stems, skeleton words,
///              skeleton tight, roman words, roman tight
///   blob       the records' bytes, back to back
///   word lists u32 count, then per word u8 length + bytes; sorted, so one table is one file
enum VerseSearchPack {
    private static let magic: UInt32 = 0x3150_5351   // the bytes "QSP1"
    /// Bumped by hand when a fold, stem, skeleton, outline or daily-card rule changes: a pack of the
    /// old format is then refused and the live build runs (and the equivalence test asks for a
    /// re-export).
    /// 2 (2026-10-04): an en or em dash folds to a word break (the english blob and the Latin word
    /// lists changed), the clean Arabic lane is folded with its dots whatever Hide Arabic Dots says,
    /// and a riwayah's Latin lanes are read through its alignment to Hafs.
    static let format: UInt32 = 2
    private static let headerLength = 54
    private static let recordLength = 48
    private static let fieldCount = 9

    /// Record flag bits.
    enum Flag {
        /// The ayah's translations carry none of the daily card's blocked words.
        static let gentle: UInt16 = 1
        /// The ayah fits the daily card (`Settings.isAyahShort`).
        static let short: UInt16 = 2
        /// The entry carries a hamza blob (nil otherwise: an ayah with no hamza at all).
        static let hamzaPresent: UInt16 = 4
    }

    /// Field positions inside a record.
    enum Field {
        static let arabic = 0, silent = 1, hamza = 2, english = 3
        static let arabicStems = 4, skeletonWords = 5, skeletonTight = 6, romanWords = 7, romanTight = 8
    }

    // MARK: - Reading

    final class Pack: @unchecked Sendable {
        let qiraahKey: String
        let quranFingerprint: UInt64
        let blockedWordFingerprint: UInt64
        let recordCount: Int

        private let data: Data
        /// Twelve words per record: surah | ayah << 16, flags | wordCount << 16, blob start, nine lengths.
        private let table: [UInt32]
        /// Per surah (index = surah id): the first record and its ayah id, and how many records follow
        /// it with consecutive ayah ids. Lookups are arithmetic, verified against the record itself.
        private let surahFirstRecord: [Int32]
        private let surahFirstAyah: [Int32]
        private let surahRecordCount: [Int32]
        private let blobOffset: Int
        private let blobLength: Int
        private let vocabularyOffset: Int
        private let translationOffset: Int

        struct Record {
            let surah: Int
            let ayah: Int
            let flags: UInt16
            let wordCount: Int
            fileprivate let blobStart: Int
            fileprivate let lengths: [Int]

            /// The byte range of one field inside the pack's blob.
            fileprivate func range(of field: Int) -> Range<Int> {
                var start = blobStart
                for index in 0..<field { start += lengths[index] }
                return start..<(start + lengths[field])
            }
        }

        init?(url: URL) {
            guard let mapped = try? Data(contentsOf: url, options: [.mappedIfSafe]),
                  mapped.count >= VerseSearchPack.headerLength else { return nil }
            let count = mapped.count
            var header = QuranPackReader(data: mapped, cursor: 0)
            guard header.u32() == Int(VerseSearchPack.magic), header.u32() == Int(VerseSearchPack.format) else { return nil }
            quranFingerprint = header.u64()
            blockedWordFingerprint = header.u64()
            let recordCount = header.u32()
            let recordsOffset = header.u32()
            let blobOffset = header.u32()
            let blobLength = header.u32()
            let vocabularyOffset = header.u32()
            let translationOffset = header.u32()
            let fileLength = header.u32()
            let keyLength = header.u16()
            guard fileLength == count,
                  recordCount >= 0, recordCount <= 65_535,
                  VerseSearchPack.headerLength + keyLength <= recordsOffset,
                  recordsOffset + recordCount * VerseSearchPack.recordLength <= blobOffset,
                  blobOffset + blobLength <= vocabularyOffset,
                  vocabularyOffset <= translationOffset, translationOffset <= count else { return nil }
            qiraahKey = mapped.withUnsafeBytes { raw -> String in
                let start = VerseSearchPack.headerLength
                return String(decoding: UnsafeRawBufferPointer(rebasing: raw[start..<(start + keyLength)]), as: UTF8.self)
            }

            var table = [UInt32](repeating: 0, count: recordCount * 12)
            var firstRecord = [Int32](repeating: -1, count: 115)
            var firstAyah = [Int32](repeating: 0, count: 115)
            var runCount = [Int32](repeating: 0, count: 115)
            let consistent = mapped.withUnsafeBytes { raw -> Bool in
                var cursor = recordsOffset
                var previousSurah = -1
                var previousAyah = -1
                for record in 0..<recordCount {
                    let surah = Int(raw.loadUnaligned(fromByteOffset: cursor, as: UInt16.self).littleEndian)
                    let ayah = Int(raw.loadUnaligned(fromByteOffset: cursor + 2, as: UInt16.self).littleEndian)
                    let flags = UInt32(raw.loadUnaligned(fromByteOffset: cursor + 4, as: UInt16.self).littleEndian)
                    let words = UInt32(raw.loadUnaligned(fromByteOffset: cursor + 6, as: UInt16.self).littleEndian)
                    let blobStart = raw.loadUnaligned(fromByteOffset: cursor + 8, as: UInt32.self).littleEndian
                    let base = record * 12
                    table[base] = UInt32(surah) | UInt32(ayah) << 16
                    table[base + 1] = flags | words << 16
                    table[base + 2] = blobStart
                    var end = Int(blobStart)
                    for field in 0..<VerseSearchPack.fieldCount {
                        let length = raw.loadUnaligned(fromByteOffset: cursor + 12 + field * 4, as: UInt32.self).littleEndian
                        table[base + 3 + field] = length
                        end += Int(length)
                    }
                    guard end <= blobLength, surah >= 1, surah <= 114 else { return false }
                    if surah != previousSurah {
                        guard firstRecord[surah] < 0 else { return false }     // a surah's records are one run
                        firstRecord[surah] = Int32(record)
                        firstAyah[surah] = Int32(ayah)
                        runCount[surah] = 1
                    } else if ayah == previousAyah + 1 {
                        runCount[surah] += 1
                    } else {
                        return false                                            // ayah ids ascend by one
                    }
                    previousSurah = surah
                    previousAyah = ayah
                    cursor += VerseSearchPack.recordLength
                }
                return true
            }
            guard consistent else { return nil }

            data = mapped
            self.recordCount = recordCount
            self.table = table
            surahFirstRecord = firstRecord
            surahFirstAyah = firstAyah
            surahRecordCount = runCount
            self.blobOffset = blobOffset
            self.blobLength = blobLength
            self.vocabularyOffset = vocabularyOffset
            self.translationOffset = translationOffset
        }

        /// The record for an ayah, or nil when the pack has none for it (an ayah only another riwayah
        /// numbers, whose Hafs text is empty; the caller computes those live).
        func recordIndex(surah: Int, ayah: Int) -> Int? {
            guard surah >= 1, surah <= 114 else { return nil }
            let first = Int(surahFirstRecord[surah])
            guard first >= 0 else { return nil }
            let offset = ayah - Int(surahFirstAyah[surah])
            guard offset >= 0, offset < Int(surahRecordCount[surah]) else { return nil }
            let index = first + offset
            let packed = table[index * 12]
            guard Int(packed & 0xFFFF) == surah, Int(packed >> 16) == ayah else { return nil }
            return index
        }

        func record(at index: Int) -> Record {
            let base = index * 12
            let packed = table[base]
            let flagsAndWords = table[base + 1]
            var lengths: [Int] = []
            lengths.reserveCapacity(VerseSearchPack.fieldCount)
            for field in 0..<VerseSearchPack.fieldCount { lengths.append(Int(table[base + 3 + field])) }
            return Record(surah: Int(packed & 0xFFFF), ayah: Int(packed >> 16),
                          flags: UInt16(truncatingIfNeeded: flagsAndWords & 0xFFFF),
                          wordCount: Int(flagsAndWords >> 16),
                          blobStart: Int(table[base + 2]), lengths: lengths)
        }

        /// One field's bytes, copied out of the mapping (the lanes own their rows, as the built ones do).
        func bytes(_ record: Record, field: Int) -> [UInt8] {
            let range = record.range(of: field)
            return data.withUnsafeBytes { raw in
                Array(UnsafeRawBufferPointer(rebasing: raw[(blobOffset + range.lowerBound)..<(blobOffset + range.upperBound)]))
            }
        }

        /// One field as the String the index stores.
        func string(_ record: Record, field: Int) -> String {
            let range = record.range(of: field)
            return data.withUnsafeBytes { raw in
                String(decoding: UnsafeRawBufferPointer(rebasing: raw[(blobOffset + range.lowerBound)..<(blobOffset + range.upperBound)]),
                       as: UTF8.self)
            }
        }

        /// Every Latin word of the translations and the transliteration that the spelling corrector
        /// may read (`Lanes.vocabulary`), as the union over the pack's records.
        var vocabulary: [String] { wordList(at: vocabularyOffset, end: translationOffset) }
        /// The translations' words alone (`Lanes.translationWords`).
        var translationWords: [String] { wordList(at: translationOffset, end: data.count) }

        private func wordList(at offset: Int, end: Int) -> [String] {
            data.withUnsafeBytes { raw -> [String] in
                guard offset + 4 <= end else { return [] }
                let count = Int(raw.loadUnaligned(fromByteOffset: offset, as: UInt32.self).littleEndian)
                var words: [String] = []
                words.reserveCapacity(min(count, max(0, end - offset)))
                var cursor = offset + 4
                for _ in 0..<count {
                    guard cursor < end else { return [] }
                    let length = Int(raw[cursor])
                    cursor += 1
                    guard cursor + length <= end else { return [] }
                    words.append(String(decoding: UnsafeRawBufferPointer(rebasing: raw[cursor..<(cursor + length)]), as: UTF8.self))
                    cursor += length
                }
                return words
            }
        }
    }

    // MARK: - Which pack answers for a qiraah key

    private static let lock = NSLock()
    nonisolated(unsafe) private static var cachesPack: (key: String, text: UInt64, pack: Pack)?

    /// The shipped Hafs pack, when it was built from the quran.qpk this app carries. Nil on the Watch and
    /// in the extensions (the file ships with the phone app alone) and whenever the fingerprints differ.
    static let bundled: Pack? = {
        guard let url = bundledURL(), let pack = Pack(url: url), pack.qiraahKey.isEmpty,
              let fingerprint = quranFingerprint, pack.quranFingerprint == fingerprint else { return nil }
        return pack
    }()

    private static func bundledURL() -> URL? {
        Bundle.main.url(forResource: "quran-search", withExtension: "qsp", subdirectory: "Quran")
            ?? Bundle.main.url(forResource: "quran-search", withExtension: "qsp", subdirectory: "Data/Quran")
            ?? Bundle.main.url(forResource: "quran-search", withExtension: "qsp")
    }

    /// The pack for the texts the index is built from: the shipped one for Hafs, else the one this
    /// build of the app wrote to Caches after building the lanes under that riwayah; nil when there is
    /// none and everything is built live (and then written, see `saveToCaches`).
    static func pack(for qiraahKey: String, surahs: [Surah]) -> Pack? {
        if qiraahKey.isEmpty, let bundled { return bundled }
        let text = textFingerprint(qiraahKey: qiraahKey, surahs: surahs)
        lock.lock()
        if let cached = cachesPack, cached.key == qiraahKey, cached.text == text { lock.unlock(); return cached.pack }
        lock.unlock()
        guard let url = cachesURL(for: qiraahKey, text: text), let pack = Pack(url: url), pack.qiraahKey == qiraahKey,
              let fingerprint = quranFingerprint, pack.quranFingerprint == fingerprint else { return nil }
        lock.lock()
        cachesPack = (qiraahKey, text, pack)
        lock.unlock()
        return pack
    }

    /// FNV-1a over the Arabic of every ayah the riwayah numbers, exactly as the index reads it. It is
    /// part of a Caches pack's NAME (2026-10-04): the key alone said which riwayah, not which TEXT,
    /// and a beta riwayah indexed before its text was accepted (every row Hafs's fallback) kept that
    /// pack after the text was unlocked, so search matched Hafs's words under the riwayah's numbers
    /// until the app was updated. A pack is now served only for the text it was built from.
    static func textFingerprint(qiraahKey: String, surahs: [Surah]) -> UInt64 {
        let qiraah = qiraahKey.isEmpty ? nil : qiraahKey
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for surah in surahs {
            for ayah in surah.ayahs where ayah.existsInQiraah(qiraah, surahID: surah.id) {
                for byte in ayah.textArabic(for: qiraah, surahID: surah.id).utf8 {
                    hash ^= UInt64(byte)
                    hash = hash &* 0x0000_0100_0000_01B3
                }
                hash ^= 0x0A
                hash = hash &* 0x0000_0100_0000_01B3
            }
        }
        return hash
    }

    /// The shipped pack when its daily flags were decided with THIS build's blocked-word list; the
    /// Ayah of the Day picker falls back to reading the texts otherwise.
    static func dailyFlagsPack() -> Pack? {
        guard let bundled, bundled.blockedWordFingerprint == blockedWordFingerprint(Settings.dailyCardBlockedWords) else { return nil }
        return bundled
    }

    /// `HadithFold.wordListFingerprint`'s rule (the hadith packs stamp their daily flags the same way),
    /// kept here because that file is not in every target this one is.
    static func blockedWordFingerprint(_ words: Set<String>) -> UInt64 {
        fnv1a(words.map { $0.lowercased() }.sorted().joined(separator: "\n").utf8)
    }

    static func fnv1a<S: Sequence>(_ bytes: S) -> UInt64 where S.Element == UInt8 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }

    /// quran.qpk's own source fingerprint (its container header, bytes 32-39), read once.
    static let quranFingerprint: UInt64? = {
        guard let url = QuranPackLoader.url("quran"), let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        guard let header = try? handle.read(upToCount: 48), header.count == 48 else { return nil }
        var reader = QuranPackReader(data: header, cursor: 32)
        return reader.u64()
    }()

    // MARK: - Caches (a riwayah other than Hafs, or a shipped pack that could not be used)

    private static func stamp(_ url: URL?) -> String? {
        guard let url, let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber,
              let date = attributes[.modificationDate] as? Date else { return nil }
        return "\(size.int64Value)-\(Int64(date.timeIntervalSince1970))"
    }

    /// The Caches file for one riwayah's text, and the prefix every file of THIS build shares (the
    /// format, the executable's and quran.qpk's stamps), whatever its riwayah.
    private static func cachesLocation(for qiraahKey: String, text: UInt64) -> (url: URL, buildPrefix: String, riwayahPrefix: String)? {
        guard let app = stamp(Bundle.main.executableURL),
              let quran = stamp(QuranPackLoader.url("quran")),
              let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let directory = caches.appendingPathComponent("VerseSearch", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let slug = qiraahKey.isEmpty ? "hafs" : String(qiraahKey.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : "_"
        })
        let buildPrefix = "search-v\(format)-\(app)-\(quran)-"
        let riwayahPrefix = buildPrefix + "\(slug)-"
        return (directory.appendingPathComponent(riwayahPrefix + String(text, radix: 16) + ".qsp"), buildPrefix, riwayahPrefix)
    }

    private static func cachesURL(for qiraahKey: String, text: UInt64) -> URL? {
        cachesLocation(for: qiraahKey, text: text)?.url
    }

    /// Writes the pack this build just computed for `qiraahKey` from `surahs`, so the next launch reads
    /// it instead. Files of other builds (another executable or quran.qpk stamp) are dead weight and
    /// go, and so does this riwayah's pack of another text.
    static func saveToCaches(qiraahKey: String, surahs: [Surah], records: [RecordInput], vocabulary: [String],
                             translationWords: [String]) {
        guard let location = cachesLocation(for: qiraahKey, text: textFingerprint(qiraahKey: qiraahKey, surahs: surahs)),
              let fingerprint = quranFingerprint,
              let data = encode(qiraahKey: qiraahKey, quranFingerprint: fingerprint,
                                blockedWordFingerprint: blockedWordFingerprint(Settings.dailyCardBlockedWords),
                                records: records, vocabulary: vocabulary, translationWords: translationWords) else { return }
        let url = location.url
        let directory = url.deletingLastPathComponent()
        let keep = url.lastPathComponent
        if let siblings = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) {
            for sibling in siblings where sibling.lastPathComponent != keep {
                let name = sibling.lastPathComponent
                guard !name.hasPrefix(location.buildPrefix) || name.hasPrefix(location.riwayahPrefix) else { continue }
                try? FileManager.default.removeItem(at: sibling)
            }
        }
        try? data.write(to: url, options: .atomic)
        lock.lock()
        cachesPack = nil
        lock.unlock()
    }

    // MARK: - Writing

    /// One ayah's share of a pack: what the index stores for it and what the lanes derive from it.
    struct RecordInput: Equatable {
        var surah: Int
        var ayah: Int
        var flags: UInt16
        var wordCount: Int
        var arabic: [UInt8]
        var silent: [UInt8]
        var hamza: [UInt8]?
        var english: [UInt8]
        var arabicStems: [UInt8]
        var skeletonWords: [UInt8]
        var skeletonTight: [UInt8]
        var romanWords: [UInt8]
        var romanTight: [UInt8]
    }

    /// The file for these records, or nil when something does not fit the fixed widths (an ayah id or a
    /// field length past them is a build change, never a runtime condition).
    static func encode(qiraahKey: String, quranFingerprint: UInt64, blockedWordFingerprint: UInt64,
                       records: [RecordInput], vocabulary: [String], translationWords: [String]) -> Data? {
        let key = Array(qiraahKey.utf8)
        guard key.count <= Int(UInt16.max), records.count <= 65_535 else { return nil }
        let recordsOffset = headerLength + key.count
        let blobOffset = recordsOffset + records.count * recordLength

        var table = Data()
        table.reserveCapacity(records.count * recordLength)
        var blob = Data()
        blob.reserveCapacity(records.count * 1_600)
        func appendU16(_ value: Int, to data: inout Data) -> Bool {
            guard value >= 0, value <= Int(UInt16.max) else { return false }
            withUnsafeBytes(of: UInt16(value).littleEndian) { data.append(contentsOf: $0) }
            return true
        }
        func appendU32(_ value: Int, to data: inout Data) -> Bool {
            guard value >= 0, value <= Int(UInt32.max) else { return false }
            withUnsafeBytes(of: UInt32(value).littleEndian) { data.append(contentsOf: $0) }
            return true
        }
        for record in records {
            var flags = record.flags & ~Flag.hamzaPresent
            if record.hamza != nil { flags |= Flag.hamzaPresent }
            guard appendU16(record.surah, to: &table), appendU16(record.ayah, to: &table),
                  appendU16(Int(flags), to: &table), appendU16(record.wordCount, to: &table),
                  appendU32(blob.count, to: &table) else { return nil }
            let fields: [[UInt8]] = [record.arabic, record.silent, record.hamza ?? [], record.english,
                                     record.arabicStems, record.skeletonWords, record.skeletonTight,
                                     record.romanWords, record.romanTight]
            for field in fields {
                guard appendU32(field.count, to: &table) else { return nil }
                blob.append(contentsOf: field)
            }
        }
        func wordList(_ words: [String]) -> Data? {
            var data = Data()
            guard appendU32(words.count, to: &data) else { return nil }
            for word in words.sorted() {
                let bytes = Array(word.utf8)
                guard bytes.count <= Int(UInt8.max) else { return nil }
                data.append(UInt8(bytes.count))
                data.append(contentsOf: bytes)
            }
            return data
        }
        guard let vocabularyData = wordList(vocabulary), let translationData = wordList(translationWords) else { return nil }
        let vocabularyOffset = blobOffset + blob.count
        let translationOffset = vocabularyOffset + vocabularyData.count
        let fileLength = translationOffset + translationData.count

        var out = Data()
        out.reserveCapacity(fileLength)
        _ = appendU32(Int(magic), to: &out)
        _ = appendU32(Int(format), to: &out)
        withUnsafeBytes(of: quranFingerprint.littleEndian) { out.append(contentsOf: $0) }
        withUnsafeBytes(of: blockedWordFingerprint.littleEndian) { out.append(contentsOf: $0) }
        guard appendU32(records.count, to: &out), appendU32(recordsOffset, to: &out),
              appendU32(blobOffset, to: &out), appendU32(blob.count, to: &out),
              appendU32(vocabularyOffset, to: &out), appendU32(translationOffset, to: &out),
              appendU32(fileLength, to: &out), appendU16(key.count, to: &out) else { return nil }
        out.append(contentsOf: key)
        out.append(table)
        out.append(blob)
        out.append(vocabularyData)
        out.append(translationData)
        guard out.count == fileLength else { return nil }
        return out
    }
}
