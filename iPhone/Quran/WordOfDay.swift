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

/// The bundled corpus (`Resources/Data/Quran/WordOfDay.json.xz`), parsed once off-main (kicked at
/// app init, before the under-cover walk builds the Quran root that reads it) and kept.
final class WordOfDayStore: @unchecked Sendable {
    static let shared = WordOfDayStore()
    private init() {}

    /// A cheap URL lookup, so the settings toggle and the summary grid can gate on it without a parse.
    static let isBundled: Bool = ThemesPack.url("WordOfDay") != nil

    private let lock = NSLock()
    private var loaded: [WordOfDayEntry]?
    private var loadFailed = false
    /// True while one thread parses the pack; a second asker waits instead of parsing a copy (the
    /// old accessor dropped the lock during the parse, so the root body and the prewarm both parsed).
    private var loading = false
    private let loadDone = DispatchGroup()
    private var waiters: [CheckedContinuation<Void, Never>] = []

    /// The corpus. Parses on the calling thread when nothing has parsed it yet, waits (never parses
    /// twice) when another thread is on it. Never from a view body: `wordsIfLoaded` there.
    var words: [WordOfDayEntry] {
        lock.lock()
        if let loaded { lock.unlock(); return loaded }
        if loadFailed { lock.unlock(); return [] }
        if loading {
            lock.unlock()
            loadDone.wait()
            lock.lock(); defer { lock.unlock() }
            return loaded ?? []
        }
        loading = true
        loadDone.enter()
        lock.unlock()
        let parsed = Self.load()
        finishLoad(parsed)
        return parsed ?? []
    }

    /// The corpus if it is in memory, else nil (kicking the off-main parse if none is running): the
    /// accessor for view bodies, which must never parse.
    var wordsIfLoaded: [WordOfDayEntry]? {
        lock.lock()
        let loaded = loaded
        let failed = loadFailed
        lock.unlock()
        if let loaded { return loaded }
        if failed { return [] }
        prewarm()
        return nil
    }

    /// Whether the corpus is in memory (or failed to parse).
    var isLoaded: Bool {
        lock.lock(); defer { lock.unlock() }
        return loaded != nil || loadFailed
    }

    /// Parses off-main, once; safe to call again from anywhere.
    func prewarm() {
        guard Self.isBundled else { return }
        lock.lock()
        let needed = loaded == nil && !loadFailed && !loading
        if needed {
            loading = true
            loadDone.enter()
        }
        lock.unlock()
        guard needed else { return }
        DispatchQueue.global(qos: .utility).async { self.finishLoad(Self.load()) }
    }

    static func prewarm() { shared.prewarm() }

    /// Suspends until the corpus is in memory (or has failed), kicking the parse if nobody has.
    func waitUntilLoaded() async {
        guard Self.isBundled else { return }
        prewarm()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            lock.lock()
            if loaded != nil || loadFailed {
                lock.unlock()
                continuation.resume()
                return
            }
            waiters.append(continuation)
            lock.unlock()
        }
    }

    private func finishLoad(_ parsed: [WordOfDayEntry]?) {
        lock.lock()
        if let parsed { loaded = parsed } else { loadFailed = true }
        loading = false
        let parked = waiters
        waiters.removeAll()
        lock.unlock()
        loadDone.leave()
        parked.forEach { $0.resume() }
    }

    /// Today's word: the corpus walked in order (its themes are interleaved on purpose, so no
    /// hashing) one entry per daily-rollover day (Fajr by default, shared with every other "of the
    /// day" feature).
    func entry(for date: Date = Date()) -> WordOfDayEntry? {
        Self.word(in: words, for: date)
    }

    /// `entry(for:)` for view bodies: nil until the parse has landed.
    func entryIfLoaded(for date: Date = Date()) -> WordOfDayEntry? {
        guard let all = wordsIfLoaded else { return nil }
        return Self.word(in: all, for: date)
    }

    func entry(id: String) -> WordOfDayEntry? {
        words.first { $0.id == id }
    }

    private static func word(in all: [WordOfDayEntry], for date: Date) -> WordOfDayEntry? {
        guard !all.isEmpty else { return nil }
        let index = ((Settings.shared.dailyDayIndex(for: date) % all.count) + all.count) % all.count
        return all[index]
    }

    private static func load() -> [WordOfDayEntry]? {
        PackTrace.measure("WordOfDay") { () -> (result: [WordOfDayEntry]?, bytes: Int) in
            guard let json = ThemesPack.data("WordOfDay") else { return (nil, 0) }
            return (parse(json), json.count)
        }
    }

    private static func parse(_ json: Data) -> [WordOfDayEntry]? {
        guard let root = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any],
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

/// The Quran tab's Word of the Day tile, the grid's fifth kind of tile - drawn only when the history
/// tiles leave the grid one short of even, so it squares the grid up rather than sitting alone on a
/// row (the row form below takes over otherwise). Same construction as `SummaryAyahTile`: a plain
/// Button (a NavigationLink tile picked up the List's chevron and shrank), ideal-height measurement
/// feeding `SummaryTileHeightKey`, top-leading in the equalized frame. Title, first appearance, the
/// word in the reader's own face, its gloss - and no transliteration-and-count line (Abu, 2026-09-07:
/// it made every other tile taller for nothing).
struct SummaryWordTile: View, Equatable {
    static let title = "Word of the Day"

    let word: WordOfDayEntry
    let surahName: String
    /// The grid's common tile height (the tallest tile's natural height), once measured.
    var rowHeight: CGFloat? = nil
    let onTap: () -> Void

    // Captured at init (Tilawa Guide, Phase 8 step 1): the Quran root that hosts the tile observes
    // Settings and re-creates it on a publish, and `==` then decides whether the tile re-renders.
    private let accent: Color
    /// The word in the reader's face, nil when Arabic text is off.
    private let arabic: String?
    private let fontName: String
    private let customFace: Bool

    init(word: WordOfDayEntry, surahName: String, rowHeight: CGFloat? = nil, onTap: @escaping () -> Void) {
        self.word = word
        self.surahName = surahName
        self.rowHeight = rowHeight
        self.onTap = onTap
        let settings = Settings.shared
        accent = settings.accentColor.color
        arabic = settings.showArabicText ? settings.cleanedQuranArabic(word.arabic) : nil
        fontName = settings.quranDisplayFontName
        customFace = settings.quranDisplayUsesCustomArabicFace
    }

    static func == (lhs: SummaryWordTile, rhs: SummaryWordTile) -> Bool {
        lhs.word.id == rhs.word.id && lhs.surahName == rhs.surahName && lhs.rowHeight == rhs.rowHeight
            && lhs.accent == rhs.accent && lhs.arabic == rhs.arabic && lhs.fontName == rhs.fontName && lhs.customFace == rhs.customFace
    }

    var body: some View {
        Button {
            Settings.shared.hapticFeedback()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    AccentIconChip(systemImage: "character.book.closed.fill", tint: accent, size: 18)
                    Text(Self.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(accent)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                    Spacer(minLength: 0)
                }

                Text("\(surahName) \(word.surah):\(word.ayah)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let arabic {
                    Text(arabic)
                        .font(Font.arabic(fontName, size: UIFont.preferredFont(forTextStyle: .subheadline).pointSize * 1.2))
                        .arabicFontDesign(custom: customFace)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Text(word.meaning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            // The content keeps its IDEAL height whatever the tile is stretched to, so the measurement
            // below can never depend on the frame it feeds (see `SummaryAyahTile`).
            .fixedSize(horizontal: false, vertical: true)
            .background(GeometryReader { proxy in
                Color.clear.preference(key: SummaryTileHeightKey.self, value: [Self.title: proxy.size.height])
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .frame(height: rowHeight)
            .conditionalGlassEffect(clear: true, rectangle: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - The summary row

/// The Quran tab's Word of the Day row, under the theme door whenever the summary grid is already
/// even (see `SummaryWordTile`): the word in the reader's own face, its gloss, and where it first
/// appears. Its host is a plain Button, so it carries no link chevron (Abu, 2026-09-07). Settings
/// captured at init and Equatable, like the tile.
struct WordOfDayRow: View, Equatable {
    let word: WordOfDayEntry
    let surahName: String
    private let arabic: String?
    private let fontName: String
    private let customFace: Bool

    init(word: WordOfDayEntry, surahName: String) {
        self.word = word
        self.surahName = surahName
        let settings = Settings.shared
        arabic = settings.showArabicText ? settings.cleanedQuranArabic(word.arabic) : nil
        fontName = settings.quranDisplayFontName
        customFace = settings.quranDisplayUsesCustomArabicFace
    }

    static func == (lhs: WordOfDayRow, rhs: WordOfDayRow) -> Bool {
        lhs.word.id == rhs.word.id && lhs.surahName == rhs.surahName && lhs.arabic == rhs.arabic
            && lhs.fontName == rhs.fontName && lhs.customFace == rhs.customFace
    }

    var body: some View {
        HStack(spacing: 12) {
            AccentIconChip(systemImage: "character.book.closed.fill", size: 26)

            VStack(alignment: .leading, spacing: 1) {
                Text("Word of the Day")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text("\(word.meaning) · \(surahName) \(word.surah):\(word.ayah)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            if let arabic {
                Text(arabic)
                    .font(Font.arabic(fontName, size: UIFont.preferredFont(forTextStyle: .title3).pointSize * 1.1))
                    .arabicFontDesign(custom: customFace)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.vertical, 1)
    }
}

// MARK: - The word's own screen

/// The rest of the tile's sentence: the word, what it means, how it spreads across the mushaf, its
/// root and dictionary form (from the morphology pack, when bundled), and every ayah it appears in
/// with the form tinted, each a tap away from the reader.
struct WordOfDayDetailView: View {
    @ObservedObject private var settings = Settings.shared

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

    private struct Spread {
        var ayahs = 0
        var surahs = 0
        var meccan = 0
        var medinan = 0
    }

    /// The anchor token's root and dictionary form with every location of each, from the
    /// morphology pack.
    private struct Morphology {
        var root: (id: Int, root: MorphologyStore.Root)?
        var rootLocations: [WordLocation] = []
        var lemma: (id: Int, lemma: MorphologyStore.Lemma)?
        var lemmaLocations: [WordLocation] = []

        var isEmpty: Bool { root == nil && lemma == nil }
    }

    /// Everything the screen derives from the word, computed once in `.task` (the ayah lookups on the
    /// main actor, the morphology off it: a root like ق و ل has thousands of locations) and paged
    /// from here, so a "Show more" tap costs one body over a stored array instead of 170 ayah
    /// lookups and a root walk per evaluation.
    @State private var rows: [Row] = []
    @State private var spread = Spread()
    @State private var morphology: Morphology?

    private static func spread(of rows: [Row]) -> Spread {
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
        let _ = RenderCounter.hit("WordOfDayDetailView")
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
        .task { await derive() }
    }

    @MainActor
    private func derive() async {
        let data = QuranData.shared
        let resolved: [Row] = word.occurrences.compactMap { occurrence in
            guard let surah = data.surah(occurrence.surah),
                  let ayah = data.ayah(surah: occurrence.surah, ayah: occurrence.ayah) else { return nil }
            return Row(surah: surah, ayah: ayah, tokens: occurrence.tokens)
        }
        rows = resolved
        spread = Self.spread(of: resolved)
        let word = self.word
        morphology = await Task.detached(priority: .userInitiated) { () -> Morphology in
            let store = MorphologyStore.shared
            var out = Morphology()
            if let root = store.root(surah: word.surah, ayah: word.ayah, token: word.token) {
                out.root = root
                out.rootLocations = store.occurrences(ofRoot: root.id)
            }
            if let lemma = store.lemma(surah: word.surah, ayah: word.ayah, token: word.token) {
                out.lemma = lemma
                out.lemmaLocations = store.occurrences(ofLemma: lemma.id)
            }
            return out
        }.value
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

            if let surah = QuranData.shared.surah(word.surah) {
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
        if let morphology, !morphology.isEmpty {
            Section(header: Text("ROOT AND FORM")) {
                if let root = morphology.root {
                    NavigationLink(destination: LazyDestination {
                        RootOccurrencesView(
                            title: "Root \(root.root.letters)",
                            locations: morphology.rootLocations,
                            highlight: WordLocation(surah: word.surah, ayah: word.ayah, token: word.token),
                            onOpenAyah: onOpenAyah
                        )
                    }) {
                        morphologyRow(label: "Root", arabic: root.root.letters, count: morphology.rootLocations.count)
                    }
                }
                if let lemma = morphology.lemma {
                    NavigationLink(destination: LazyDestination {
                        RootOccurrencesView(
                            title: lemma.lemma.text,
                            locations: morphology.lemmaLocations,
                            highlight: WordLocation(surah: word.surah, ayah: word.ayah, token: word.token),
                            onOpenAyah: onOpenAyah
                        )
                    }) {
                        morphologyRow(label: "Form", arabic: lemma.lemma.text, count: morphology.lemmaLocations.count)
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
        let content = WordOccurrenceRow(surah: row.surah, ayah: row.ayah, tokens: row.tokens, caption: caption).equatable()
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
