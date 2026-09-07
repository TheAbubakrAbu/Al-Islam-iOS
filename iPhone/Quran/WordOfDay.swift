import SwiftUI

#if os(iOS)
// MARK: - Word of the Day

/// One curated piece of Quranic vocabulary: the exact written form as it stands at its first
/// appearance, with the transliteration and gloss of that occurrence, and every ayah the same
/// written form appears in. The curation (149 words, themes interleaved so consecutive days feel
/// varied) is Tilawa's (Jamil Hammoudeh, with permission); the occurrences are derived from this
/// app's own Hafs text by `Scripts/build_word_of_day.py`, so the count on the card and the list
/// behind it are one derivation.
struct WordOfDayEntry: Identifiable, Equatable {
    struct Occurrence: Equatable {
        let surah: Int
        let ayah: Int
        /// 0-based whitespace-token indices into the ayah's raw Hafs text (a form can repeat inside one
        /// ayah: al-mulk three times in 3:26), the same indexing `WordTokens` uses.
        let tokens: [Int]
    }

    let id: String
    /// This app's own token at the anchor, so it renders in every bundled face.
    let arabic: String
    let transliteration: String
    let meaning: String
    /// The anchor occurrence: where the form first appears in the mushaf.
    let surah: Int
    let ayah: Int
    let token: Int
    /// Hits across the whole Quran (the sum of every occurrence's token count).
    let count: Int
    /// Every ayah carrying the form, in mushaf order.
    let occurrences: [Occurrence]
}

/// The bundled corpus (`Resources/Data/Quran/WordOfDay.json.xz`), parsed once on first use and kept.
final class WordOfDayStore: @unchecked Sendable {
    static let shared = WordOfDayStore()
    private init() {}

    /// A cheap URL lookup, so the settings toggle and the summary grid can gate on it without a parse.
    static let isBundled: Bool = ThemesPack.url("WordOfDay") != nil

    private let lock = NSLock()
    private var loaded: [WordOfDayEntry]?
    private var loadFailed = false

    var words: [WordOfDayEntry] {
        lock.lock()
        if let loaded { lock.unlock(); return loaded }
        if loadFailed { lock.unlock(); return [] }
        lock.unlock()

        let parsed = Self.load()
        lock.lock(); defer { lock.unlock() }
        if let loaded { return loaded }
        if let parsed { loaded = parsed; return parsed }
        loadFailed = true
        return []
    }

    /// Parses off-main so the first summary-grid pass never pays for it.
    static func prewarm() {
        guard isBundled else { return }
        DispatchQueue.global(qos: .utility).async { _ = shared.words }
    }

    /// Days since the reference date in the user's calendar: the word flips at local midnight, and the
    /// rotation walks the corpus in order (its themes are interleaved on purpose) rather than hashing.
    static func dayIndex(for date: Date = Date()) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: start).day ?? 0
    }

    func entry(for date: Date = Date()) -> WordOfDayEntry? {
        let all = words
        guard !all.isEmpty else { return nil }
        let index = ((Self.dayIndex(for: date) % all.count) + all.count) % all.count
        return all[index]
    }

    func entry(id: String) -> WordOfDayEntry? {
        words.first { $0.id == id }
    }

    private static func load() -> [WordOfDayEntry]? {
        guard let root = ThemesPack.json("WordOfDay") as? [String: Any],
              let rows = root["words"] as? [[String: Any]] else { return nil }
        var out: [WordOfDayEntry] = []
        out.reserveCapacity(rows.count)
        for row in rows {
            guard let id = row["id"] as? String,
                  let arabic = row["ar"] as? String,
                  let surah = row["s"] as? Int, let ayah = row["a"] as? Int, let token = row["p"] as? Int,
                  let count = row["n"] as? Int,
                  let occ = row["occ"] as? [[Any]] else { continue }
            let occurrences: [WordOfDayEntry.Occurrence] = occ.compactMap { item in
                guard item.count == 3, let s = item[0] as? Int, let a = item[1] as? Int,
                      let tokens = item[2] as? [Int] else { return nil }
                return .init(surah: s, ayah: a, tokens: tokens)
            }
            out.append(WordOfDayEntry(
                id: id, arabic: arabic,
                transliteration: row["tr"] as? String ?? "",
                meaning: row["en"] as? String ?? "",
                surah: surah, ayah: ayah, token: token, count: count,
                occurrences: occurrences
            ))
        }
        return out.isEmpty ? nil : out
    }
}

// MARK: - The summary tile

/// The Quran tab's Word of the Day tile, the fourth kind of tile in the summary grid: the word in the
/// reader's own face, its gloss, and where it first appears. Same construction as `SummaryAyahTile`
/// (ideal-height measurement feeding `SummaryTileHeightKey`, top-leading in the equalized frame).
struct SummaryWordTile: View {
    @ObservedObject var settings = Settings.shared

    static let title = "Word of the Day"

    let word: WordOfDayEntry
    let surahName: String
    var rowHeight: CGFloat? = nil

    private var arabicText: String {
        settings.cleanedQuranArabic(word.arabic)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "character.book.closed")
                    .font(.caption)
                    .foregroundColor(settings.accentColor.color)
                Text(Self.title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
                Spacer(minLength: 0)
            }

            Text("\(surahName) \(word.surah):\(word.ayah)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            if settings.showArabicText {
                Text(arabicText)
                    .font(Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * 1.35))
                    .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Text(word.meaning)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(word.transliteration) · \(word.count) \(word.count == 1 ? "time" : "times")")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .fixedSize(horizontal: false, vertical: true)
        .background(GeometryReader { proxy in
            Color.clear.preference(key: SummaryTileHeightKey.self, value: [Self.title: proxy.size.height])
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .frame(height: rowHeight)
        .conditionalGlassEffect(clear: true, rectangle: true)
        .contentShape(Rectangle())
    }
}

// MARK: - The word's own screen

/// The rest of the tile's sentence: the word, what it means, how it spreads across the mushaf, its
/// root and dictionary form (from the morphology pack, when bundled), and every ayah it appears in
/// with the form tinted, each a tap away from the reader.
struct WordOfDayDetailView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    let word: WordOfDayEntry
    var onOpenAyah: ((Int, Int) -> Void)? = nil

    /// A word like an-nas lands 170+ ayahs here, every one of them full Quranic text: the first batch
    /// fills a screen and the rest arrives on demand.
    private static let firstBatch = 15
    private static let batchStep = 50
    @State private var visibleCount = WordOfDayDetailView.firstBatch

    private struct Row: Identifiable {
        let surah: Surah
        let ayah: Ayah
        let tokens: [Int]
        var id: String { "\(surah.id):\(ayah.id)" }
    }

    private var rows: [Row] {
        word.occurrences.compactMap { occurrence in
            guard let surah = quranData.surah(occurrence.surah),
                  let ayah = quranData.ayah(surah: occurrence.surah, ayah: occurrence.ayah) else { return nil }
            return Row(surah: surah, ayah: ayah, tokens: occurrence.tokens)
        }
    }

    private struct Spread {
        var ayahs = 0
        var surahs = 0
        var meccan = 0
        var medinan = 0
    }

    private func spread(of rows: [Row]) -> Spread {
        var out = Spread()
        var seen: Set<Int> = []
        out.ayahs = rows.count
        for row in rows {
            seen.insert(row.surah.id)
            if row.surah.type.lowercased().hasPrefix("mad") {
                out.medinan += row.tokens.count
            } else {
                out.meccan += row.tokens.count
            }
        }
        out.surahs = seen.count
        return out
    }

    private var arabicFontName: String { settings.quranArabicFontName(for: nil) }

    var body: some View {
        let rows = rows
        let spread = spread(of: rows)
        let shown = Array(rows.prefix(visibleCount))
        let remaining = rows.count - shown.count

        List {
            Section {
                hero
            }

            Section(header: Text("ACROSS THE QURAN")) {
                HStack(spacing: 0) {
                    stat(value: word.count, label: word.count == 1 ? "Occurrence" : "Occurrences")
                    Divider()
                    stat(value: spread.ayahs, label: spread.ayahs == 1 ? "Ayah" : "Ayahs")
                    Divider()
                    stat(value: spread.surahs, label: spread.surahs == 1 ? "Surah" : "Surahs")
                }
                .padding(.vertical, 4)

                Text("\(spread.meccan) in Meccan surahs · \(spread.medinan) in Medinan surahs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            morphologySection

            Section(header: SectionPillHeader(title: "WHERE IT APPEARS", count: rows.count)) {
                ForEach(Array(shown.enumerated()), id: \.element.id) { index, row in
                    occurrenceRow(row, isAnchor: index == 0 && row.surah.id == word.surah && row.ayah.id == word.ayah)
                }
                if remaining > 0 {
                    Button {
                        settings.hapticFeedback()
                        visibleCount += Self.batchStep
                    } label: {
                        Text("Show \(min(remaining, Self.batchStep)) more")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(settings.accentColor.color)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            Section(footer:
                Text("The count is of this exact written form; other forms of the same root are listed under its root above. Curated with Tilawa; the gloss is Quran.com's word-by-word English.")
                    .font(.caption2)
            ) { EmptyView() }
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .navigationTitle("Word of the Day")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(spacing: 8) {
            Text(settings.cleanedQuranArabic(word.arabic))
                .font(Font.arabic(arabicFontName, size: 44))
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            Text(word.transliteration)
                .font(.subheadline.italic())
                .foregroundStyle(.secondary)

            Text("MEANING")
                .kerning(0.8)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Text(word.meaning)
                .font(.title3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let surah = quranData.surah(word.surah) {
                Text("First appears in \(surah.nameTransliteration) \(word.surah):\(word.ayah)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private func stat(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.title2.weight(.bold))
                .monospacedDigit()
            Text(label.uppercased())
                .kerning(0.6)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    /// Root and dictionary form of the anchor token, each a door to every ayah that carries it.
    @ViewBuilder
    private var morphologySection: some View {
        let store = MorphologyStore.shared
        let root = store.root(surah: word.surah, ayah: word.ayah, token: word.token)
        let lemma = store.lemma(surah: word.surah, ayah: word.ayah, token: word.token)
        if root != nil || lemma != nil {
            Section(header: Text("ROOT AND FORM")) {
                if let root {
                    let locations = store.occurrences(ofRoot: root.id)
                    NavigationLink(destination: LazyDestination {
                        RootOccurrencesView(
                            title: "Root \(root.root.letters)",
                            locations: locations,
                            highlight: WordLocation(surah: word.surah, ayah: word.ayah, token: word.token),
                            onOpenAyah: onOpenAyah
                        )
                    }) {
                        morphologyRow(label: "Root", arabic: root.root.letters, count: locations.count)
                    }
                }
                if let lemma {
                    let locations = store.occurrences(ofLemma: lemma.id)
                    NavigationLink(destination: LazyDestination {
                        RootOccurrencesView(
                            title: lemma.lemma.text,
                            locations: locations,
                            highlight: WordLocation(surah: word.surah, ayah: word.ayah, token: word.token),
                            onOpenAyah: onOpenAyah
                        )
                    }) {
                        morphologyRow(label: "Form", arabic: lemma.lemma.text, count: locations.count)
                    }
                }
            }
        }
    }

    private func morphologyRow(label: String, arabic: String, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(arabic)
                .font(Font.arabic(arabicFontName, size: 22))
                .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                .lineLimit(1)
            Spacer()
            CountPill(count: count)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func occurrenceRow(_ row: Row, isAnchor: Bool) -> some View {
        let caption: String? = {
            if isAnchor { return "First appearance" }
            if row.tokens.count > 1 { return "\(row.tokens.count) times in this ayah" }
            return nil
        }()
        let content = WordOccurrenceRow(surah: row.surah, ayah: row.ayah, tokens: row.tokens, caption: caption)
        if let onOpenAyah {
            Button {
                settings.hapticFeedback()
                onOpenAyah(row.surah.id, row.ayah.id)
            } label: {
                content.contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}
#endif
