#if os(iOS)
import Foundation

/// The bundled word alignment (`WordAlignment.bin`, built by `Scripts/build_word_alignment.py`):
/// for every ayah of the Hafs text and each shipped translation, which Arabic word each English
/// word renders. The cross-language search highlight (`CrossLanguageWordHighlight`) reads it so an
/// Arabic query lights the words the TRANSLATION uses for it, and an English one the Arabic word
/// under what was matched, where it used to guess both from the word-by-word gloss ("All-Aware"
/// where Saheeh says "Acquainted").
///
/// The file, little endian: magic "XAL1", format, quran.qpk's fingerprint, the ayah and surah
/// counts, each surah's first ayah ordinal, an offset per ayah, then per ayah the Arabic word count
/// and, for each translation, its English word count and one byte per English word: the RAW Hafs
/// word it renders, or 255 for none.
///
/// The one promise this type makes is that it never answers one word off. A pack stamped with
/// another text, or whose counts differ from the strings on screen (a riwayah, beginner spacing, a
/// translation edited after the pack was built), answers nil, and the highlight falls back to the
/// gloss as if there were no pack.
final class WordAlignmentStore: @unchecked Sendable {
    static let shared = WordAlignmentStore()

    /// The translations the pack covers, in the order it stores them.
    enum Translation: Int, CaseIterable {
        case saheeh = 0
        case mustafa = 1
    }

    private static let magic = 0x314C_4158            // "XAL1"
    /// A set, not an equality: a builder that bumps the format must be answered here on purpose,
    /// and until it is the pack is refused whole (the hosted tests fail on that, not the reader).
    private static let acceptedFormats: Set<Int> = [1]
    private static let noWord: UInt8 = 255
    private static let headerLength = 24

    private struct Pack {
        let data: Data
        let surahStarts: [Int]
        let ayahCount: Int
        let offsetsStart: Int
    }

    /// Mapped once, on first use, from whichever thread asks (a `static let` initialises once).
    private static let pack: Pack? = load()

    static var isBundled: Bool { pack != nil }

    private static func url() -> URL? {
        Bundle.main.url(forResource: "WordAlignment", withExtension: "bin", subdirectory: "Quran")
            ?? Bundle.main.url(forResource: "WordAlignment", withExtension: "bin", subdirectory: "Data/Quran")
            ?? Bundle.main.url(forResource: "WordAlignment", withExtension: "bin")
    }

    private static func load() -> Pack? {
        guard let url = url(), let data = try? Data(contentsOf: url, options: .mappedIfSafe),
              data.count >= headerLength,
              u32(data, 0) == magic, acceptedFormats.contains(u32(data, 4)),
              let quran = VerseSearchPack.quranFingerprint,
              u64(data, 8) == quran else { return nil }
        let ayahCount = u32(data, 16)
        let surahCount = u32(data, 20)
        let offsetsStart = headerLength + 4 * surahCount
        guard surahCount > 0, ayahCount > 0, data.count >= offsetsStart + 4 * (ayahCount + 1),
              u32(data, offsetsStart + 4 * ayahCount) == data.count else { return nil }
        let surahStarts = (0..<surahCount).map { u32(data, headerLength + 4 * $0) }
        return Pack(data: data, surahStarts: surahStarts, ayahCount: ayahCount, offsetsStart: offsetsStart)
    }

    private static func u16(_ data: Data, _ offset: Int) -> Int {
        let base = data.startIndex + offset
        return Int(data[base]) | Int(data[base + 1]) << 8
    }

    private static func u32(_ data: Data, _ offset: Int) -> Int {
        u16(data, offset) | u16(data, offset + 2) << 16
    }

    private static func u64(_ data: Data, _ offset: Int) -> UInt64 {
        UInt64(u32(data, offset)) | UInt64(u32(data, offset + 4)) << 32
    }

    /// One entry per English token of `english` (`englishTokenRanges`): the index of the DISPLAYED
    /// Arabic token it renders, or nil. Nil overall when the pack is missing, stamped with another
    /// text, or its counts differ from these strings.
    func arabicTokens(surah: Int, ayah: Int, translation: Translation, english: String,
                      rawArabic: String, displayArabic: String) -> [Int?]? {
        guard let pack = Self.pack, surah >= 1, surah <= pack.surahStarts.count, ayah >= 1 else { return nil }
        let nextSurah = surah < pack.surahStarts.count ? pack.surahStarts[surah] : pack.ayahCount
        let ordinal = pack.surahStarts[surah - 1] + ayah - 1
        guard ordinal < nextSurah, ordinal < pack.ayahCount else { return nil }
        let data = pack.data
        let end = Self.u32(data, pack.offsetsStart + 4 * (ordinal + 1))
        var cursor = Self.u32(data, pack.offsetsStart + 4 * ordinal)
        guard cursor < end, end <= data.count else { return nil }

        let arabicCount = Int(data[data.startIndex + cursor])
        cursor += 1
        var bytes: Range<Int>?
        for index in 0...translation.rawValue {
            guard cursor + 2 <= end else { return nil }
            let count = Self.u16(data, cursor)
            cursor += 2
            guard cursor + count <= end else { return nil }
            if index == translation.rawValue { bytes = cursor..<(cursor + count) }
            cursor += count
        }
        guard let bytes, bytes.count == Self.englishTokenRanges(in: english).count,
              let displayed = Self.displayedIndices(rawArabic: rawArabic, displayArabic: displayArabic,
                                                    rawCount: arabicCount) else { return nil }
        return bytes.map { offset -> Int? in
            let word = data[data.startIndex + offset]
            return word == Self.noWord || Int(word) >= displayed.count ? nil : displayed[Int(word)]
        }
    }

    /// For each RAW Arabic word, its index among the DISPLAYED words, or nil for one the display
    /// dropped. "Hide Tashkeel and Signs" strips the ۞ that 199 ayahs carry as a word of its own, so
    /// every word after it sits one index lower than the pack's: the same reconciliation
    /// `WordByWordStore.entries` makes for the glosses. Nil when the texts cannot be reconciled.
    private static func displayedIndices(rawArabic: String, displayArabic: String, rawCount: Int) -> [Int?]? {
        let displayCount = WordTokens.count(in: displayArabic)
        if displayCount == rawCount { return Array(0..<rawCount) }
        let rawTokens = WordTokens.tokens(in: rawArabic)
        guard rawTokens.count == rawCount else { return nil }
        var out: [Int?] = []
        out.reserveCapacity(rawCount)
        var next = 0
        for token in rawTokens {
            if token.removingArabicDiacriticsAndSigns.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                out.append(nil)
            } else {
                out.append(next)
                next += 1
            }
        }
        return next == displayCount ? out : nil
    }

    /// The English tokens the pack counts: what whitespace OR a long dash ends. Khattab joins
    /// clauses with an em dash and no space ("a human life" + dash + "made sacred by Allah"), and
    /// the two halves render two Arabic words. The builder's `english_tokens` splits the same way;
    /// the whitespace is `WordTokens`'s.
    static func englishTokenRanges(in text: String) -> [NSRange] {
        var ranges: [NSRange] = []
        var start: Int?
        var offset = 0
        for unit in text.utf16 {
            if isSeparator(unit) {
                if let begin = start {
                    ranges.append(NSRange(location: begin, length: offset - begin))
                    start = nil
                }
            } else if start == nil {
                start = offset
            }
            offset += 1
        }
        if let begin = start {
            ranges.append(NSRange(location: begin, length: offset - begin))
        }
        return ranges
    }

    private static func isSeparator(_ unit: unichar) -> Bool {
        switch unit {
        case 0x20, 0x09, 0x0A, 0x0D, 0xA0, 0x2009, 0x200A, 0x202F: return true    // WordTokens' whitespace
        case 0x2014, 0x2013: return true                                           // em dash, en dash
        default: return false
        }
    }
}
#endif
