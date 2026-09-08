#if os(iOS)
import SwiftUI

// Mutashabihat: the phrases the Quran repeats, from `Resources/Data/Quran/Mutashabihat.json.xz`
// (Scripts/build_qul_packs.py, the Quranic Universal Library's "Mutashabihat ul Quran" phrase set):
// 814 phrases, each with every ayah it occurs in and the exact words carrying it there. The Similar
// Ayahs sheet shows an ayah's phrases as its second tab; a phrase opens the full list of its
// occurrences with the shared words tinted - the memoriser's view, where two nearly identical
// ayahs are read side by side and the one word that differs stands out.
//
// Spans are 0-based inclusive token ranges of THIS APP's raw Hafs text (mapped at build time, gated
// by Scripts/verify_qul_packs.py), so the sheet never matches text.

final class MutashabihatStore: @unchecked Sendable {
    static let shared = MutashabihatStore()
    private init() {}

    struct Phrase: Identifiable, Hashable {
        let id: Int
        /// The ayah the phrase is defined from, and the tokens of that ayah that spell it.
        let sourceKey: String
        let sourceSpan: ClosedRange<Int>
        /// Total occurrences, ayahs carrying it, surahs carrying it.
        let count: Int
        let ayahCount: Int
        let surahCount: Int
        /// ayah key → the token spans carrying the phrase in that ayah.
        let occurrences: [String: [ClosedRange<Int>]]

        static func == (lhs: Phrase, rhs: Phrase) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }

        /// The occurrences in mushaf order.
        var orderedKeys: [String] {
            occurrences.keys.sorted { a, b in
                let pa = a.split(separator: ":").compactMap { Int($0) }
                let pb = b.split(separator: ":").compactMap { Int($0) }
                guard pa.count == 2, pb.count == 2 else { return a < b }
                return pa[0] != pb[0] ? pa[0] < pb[0] : pa[1] < pb[1]
            }
        }

        /// How long the phrase is, in words.
        var wordCount: Int { sourceSpan.count }
    }

    private struct Table {
        let phrases: [Int: Phrase]
        let index: [String: [Int]]
    }

    private let lock = NSLock()
    private var table: Table?
    private var loadFailed = false

    static let isBundled: Bool = ThemesPack.url("Mutashabihat") != nil

    /// The phrases this ayah shares with others, longest first (the pack's order), or [] for none.
    func phrases(surah: Int, ayah: Int) -> [Phrase] {
        guard let table = loadedTable() else { return [] }
        return (table.index["\(surah):\(ayah)"] ?? []).compactMap { table.phrases[$0] }
    }

    func phrase(id: Int) -> Phrase? {
        loadedTable()?.phrases[id]
    }

    /// A dictionary hit once loaded - the sheet's tab decides whether to show itself on this.
    func hasPhrases(surah: Int, ayah: Int) -> Bool {
        !(loadedTable()?.index["\(surah):\(ayah)"] ?? []).isEmpty
    }

    func unload() {
        lock.lock(); defer { lock.unlock() }
        table = nil
        loadFailed = false
    }

    private func loadedTable() -> Table? {
        lock.lock()
        if let table { lock.unlock(); return table }
        if loadFailed { lock.unlock(); return nil }
        lock.unlock()

        guard let parsed = Self.load() else {
            lock.lock(); loadFailed = true; lock.unlock()
            return nil
        }
        lock.lock(); defer { lock.unlock() }
        if let table { return table }
        table = parsed
        return parsed
    }

    private static func load() -> Table? {
        guard let root = ThemesPack.json("Mutashabihat") as? [String: Any],
              let rawPhrases = root["phrases"] as? [String: [Any]],
              let rawIndex = root["index"] as? [String: [Int]] else { return nil }
        var phrases: [Int: Phrase] = [:]
        phrases.reserveCapacity(rawPhrases.count)
        for (key, row) in rawPhrases {
            // row = [sourceKey, start, end, count, ayahs, surahs, {ayah: [[s, e], ...]}]
            guard let id = Int(key), row.count >= 7,
                  let sourceKey = row[0] as? String,
                  let start = row[1] as? Int, let end = row[2] as? Int, end >= start,
                  let count = row[3] as? Int, let ayahCount = row[4] as? Int, let surahCount = row[5] as? Int,
                  let rawOccurrences = row[6] as? [String: [[Int]]] else { continue }
            var occurrences: [String: [ClosedRange<Int>]] = [:]
            for (ayahKey, spans) in rawOccurrences {
                let ranges = spans.compactMap { span -> ClosedRange<Int>? in
                    guard span.count == 2, span[1] >= span[0] else { return nil }
                    return span[0]...span[1]
                }
                if !ranges.isEmpty { occurrences[ayahKey] = ranges }
            }
            phrases[id] = Phrase(id: id, sourceKey: sourceKey, sourceSpan: start...end, count: count,
                                 ayahCount: ayahCount, surahCount: surahCount, occurrences: occurrences)
        }
        return phrases.isEmpty ? nil : Table(phrases: phrases, index: rawIndex)
    }
}

/// The phrase's wording, read off the source ayah's raw Hafs tokens.
func mutashabihPhraseText(_ phrase: MutashabihatStore.Phrase, quranData: QuranData) -> String {
    let parts = phrase.sourceKey.split(separator: ":").compactMap { Int($0) }
    guard parts.count == 2, let ayah = quranData.ayah(surah: parts[0], ayah: parts[1]) else { return "" }
    let tokens = WordTokens.tokens(in: ayah.displayArabicText(surahId: parts[0], clean: false, qiraahOverride: ""))
    guard phrase.sourceSpan.lowerBound >= 0, phrase.sourceSpan.upperBound < tokens.count else { return "" }
    return tokens[phrase.sourceSpan].joined(separator: " ")
}

// MARK: - The phrases of one ayah

/// The rows of the Similar Ayahs sheet's "Repeated Phrases" tab: each phrase this ayah shares, with
/// how widely it repeats, opening the full list of its occurrences.
struct MutashabihatRows: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    let surahNumber: Int
    let ayahNumber: Int
    let phrases: [MutashabihatStore.Phrase]

    private var originKey: String { "\(surahNumber):\(ayahNumber)" }

    var body: some View {
        ForEach(phrases) { phrase in
            NavigationLink {
                PhraseOccurrencesView(phrase: phrase, originKey: originKey)
            } label: {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(mutashabihPhraseText(phrase, quranData: quranData))
                        .font(.custom(settings.quranArabicFontName(for: nil), size: CGFloat(settings.fontArabicSize) - 4))
                        .arabicFontDesign(custom: true)
                        .foregroundColor(settings.accentColor.color)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(Self.summary(phrase))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }
        }
    }

    static func summary(_ phrase: MutashabihatStore.Phrase) -> String {
        let times = phrase.count == 1 ? "once" : "\(phrase.count) times"
        let ayahs = phrase.ayahCount == 1 ? "1 ayah" : "\(phrase.ayahCount) ayahs"
        let surahs = phrase.surahCount == 1 ? "1 surah" : "\(phrase.surahCount) surahs"
        return "Repeated \(times) in \(ayahs) across \(surahs)"
    }
}

// MARK: - Every occurrence of one phrase

/// All the places one phrase occurs, in mushaf order, the phrase tinted in each ayah so the words
/// around it - what changes from one occurrence to the next - can be read against each other.
struct PhraseOccurrencesView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    let phrase: MutashabihatStore.Phrase
    /// The ayah the list was opened from, marked in the list.
    var originKey: String? = nil

    private struct Row: Identifiable {
        let key: String
        let surah: Surah
        let ayah: Ayah
        let tokens: [Int]
        /// Words this occurrence reads that the origin ayah does not (the folded-word diff).
        var contrast: [Int] = []
        var id: String { key }
    }

    private var rows: [Row] {
        // The occurrence the list was opened from (or the phrase's own source ayah) is the yardstick:
        // every other row tints the words it does NOT share with it, so what changes between two
        // near-identical ayahs is the first thing the eye lands on.
        let originKey = originKey ?? phrase.sourceKey
        let originText: String? = {
            let parts = originKey.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2, let ayah = quranData.ayah(surah: parts[0], ayah: parts[1]) else { return nil }
            return ayah.displayArabicText(surahId: parts[0], clean: false, qiraahOverride: "")
        }()
        return phrase.orderedKeys.compactMap { key in
            let parts = key.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2, let surah = quranData.surah(parts[0]),
                  let ayah = quranData.ayah(surah: parts[0], ayah: parts[1]) else { return nil }
            let tokens = (phrase.occurrences[key] ?? []).flatMap { Array($0) }
            var contrast: [Int] = []
            if key != originKey, let originText {
                let text = ayah.displayArabicText(surahId: parts[0], clean: false, qiraahOverride: "")
                let shared = Set(tokens)
                let diff = QiraatWordDiff.compare(hafs: originText, riwayah: text)
                let differing = diff.riwayahOnly.filter { !shared.contains($0) }
                // Only near-twins get the orange: on an ayah that merely shares a short phrase, most
                // words differ and tinting them all would say nothing. At most half may differ.
                if differing.count * 2 <= max(1, diff.riwayah.count) { contrast = differing }
            }
            return Row(key: key, surah: surah, ayah: ayah, tokens: tokens, contrast: contrast)
        }
    }

    var body: some View {
        let list = rows
        List {
            Section {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(mutashabihPhraseText(phrase, quranData: quranData))
                        .font(.custom(settings.quranArabicFontName(for: nil), size: CGFloat(settings.fontArabicSize)))
                        .arabicFontDesign(custom: true)
                        .foregroundColor(settings.accentColor.color)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Text(MutashabihatRows.summary(phrase))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }

            Section(header: SectionPillHeader(title: "OCCURRENCES", count: list.count)) {
                ForEach(list) { row in
                    WordOccurrenceRow(surah: row.surah, ayah: row.ayah, tokens: row.tokens,
                                      isOrigin: row.key == (originKey ?? phrase.sourceKey), contrastTokens: row.contrast)
                        .equatable()
                        .id(row.id)
                }
            }

            Section(footer:
                Text("Repeated phrases from the Quranic Universal Library's Mutashabihat ul Quran. The accent words are the shared phrase; the orange words are what each occurrence says differently from the ayah you came from.")
                    .font(.caption2)
            ) { EmptyView() }
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .navigationTitle("Repeated Phrase")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
