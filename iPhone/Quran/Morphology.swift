#if os(iOS)
import SwiftUI

// Root and lemma of every word of the Quran, from `Resources/Data/Quran/Morphology.json.xz`
// (Scripts/build_qul_packs.py): the Quranic Arabic Corpus morphology (Kais Dukes), as redistributed
// by the Quranic Universal Library. Two things use it: the word card names the tapped word's root and
// dictionary form and lists every other word of that root, and the Quran tab's search answers a bare
// root (رحم, سلم) with every ayah that carries it.
//
// THE INVARIANT: like the gloss pack, one entry per whitespace token of THIS APP's Hafs text, in the
// app's own token order (the alignment against Quran.com's word positions is done at build time and
// gated by Scripts/verify_qul_packs.py). Index n is the nth token; 0 means "no root" (particles,
// the ۞ mark). The reader never matches or normalizes.

/// One word of the Quran: the ayah and the 0-based index of the token inside its raw Hafs text.
struct WordLocation: Hashable, Identifiable {
    let surah: Int
    let ayah: Int
    let token: Int

    var id: String { "\(surah):\(ayah):\(token)" }
    var ayahKey: String { "\(surah):\(ayah)" }
}

final class MorphologyStore: @unchecked Sendable {
    static let shared = MorphologyStore()
    private init() {}

    struct Root: Equatable {
        /// The letters with spaces between them, the way lexicons print a root: "ر ب ب".
        let letters: String
        /// Buckwalter transliteration of the same letters ("rbb"), kept for Latin-typed lookups.
        let buckwalter: String

        var joined: String { letters.replacingOccurrences(of: " ", with: "") }
    }

    struct Lemma: Equatable {
        /// The dictionary form with its marks: رَبّ.
        let text: String
        /// The same without marks: رب.
        let clean: String
    }

    private struct Table {
        let roots: [Root]
        let lemmas: [Lemma]
        /// surah id → ayahs in id order → one id per token (0 = none).
        let rootIDs: [Int: [[Int]]]
        let lemmaIDs: [Int: [[Int]]]
    }

    private struct Occurrences {
        let byRoot: [Int: [WordLocation]]
        let byLemma: [Int: [WordLocation]]
    }

    private let lock = NSLock()
    private var table: Table?
    private var occurrences: Occurrences?
    private var loadFailed = false

    static let isBundled: Bool = ThemesPack.url("Morphology") != nil

    // MARK: Lookups

    func root(id: Int) -> Root? {
        guard id >= 1, let table = loadedTable(), id <= table.roots.count else { return nil }
        return table.roots[id - 1]
    }

    func lemma(id: Int) -> Lemma? {
        guard id >= 1, let table = loadedTable(), id <= table.lemmas.count else { return nil }
        return table.lemmas[id - 1]
    }

    /// The root and lemma ids of every token of the ayah's RAW Hafs text (0 = none), or nil when the
    /// pack is missing or does not cover the ayah.
    func ids(surah: Int, ayah: Int) -> (roots: [Int], lemmas: [Int])? {
        guard let table = loadedTable(),
              let roots = table.rootIDs[surah], let lemmas = table.lemmaIDs[surah],
              ayah >= 1, ayah <= roots.count, ayah <= lemmas.count else { return nil }
        return (roots[ayah - 1], lemmas[ayah - 1])
    }

    /// The root of one token of the raw Hafs text.
    func root(surah: Int, ayah: Int, token: Int) -> (id: Int, root: Root)? {
        guard let ids = ids(surah: surah, ayah: ayah), ids.roots.indices.contains(token) else { return nil }
        let id = ids.roots[token]
        guard let root = root(id: id) else { return nil }
        return (id, root)
    }

    /// The lemma of one token of the raw Hafs text.
    func lemma(surah: Int, ayah: Int, token: Int) -> (id: Int, lemma: Lemma)? {
        guard let ids = ids(surah: surah, ayah: ayah), ids.lemmas.indices.contains(token) else { return nil }
        let id = ids.lemmas[token]
        guard let lemma = lemma(id: id) else { return nil }
        return (id, lemma)
    }

    /// Every word of the Quran carrying this root, in mushaf order.
    func occurrences(ofRoot id: Int) -> [WordLocation] {
        loadedOccurrences()?.byRoot[id] ?? []
    }

    /// Every word of the Quran carrying this lemma, in mushaf order.
    func occurrences(ofLemma id: Int) -> [WordLocation] {
        loadedOccurrences()?.byLemma[id] ?? []
    }

    /// The fold both a typed query and the tables are compared under: the search fold (hamza
    /// seats, dagger alif, teh marbuta) with every space and mark gone.
    static func fold(_ text: String) -> String {
        Settings.shared.cleanSearch(text.removingArabicDiacriticsAndSigns, whitespace: true)
            .replacingOccurrences(of: " ", with: "")
    }

    /// Roots whose letters, run together, are exactly the folded query - a bare 2-5 letter Arabic
    /// word typed into the search (رحم, سلم, كتب). Nothing for anything longer or with spaces.
    func roots(matching query: String) -> [(id: Int, root: Root)] {
        let folded = Self.fold(query)
        guard (2...5).contains(folded.count), folded.allSatisfy(\.isArabicLetterForMorphology),
              let table = loadedTable() else { return [] }
        return table.roots.enumerated().compactMap { index, root in
            Self.fold(root.joined) == folded ? (index + 1, root) : nil
        }
    }

    /// Lemmas whose bare form is exactly the folded query (كتاب, صلاة).
    func lemmas(matching query: String) -> [(id: Int, lemma: Lemma)] {
        let folded = Self.fold(query)
        guard folded.count >= 2, folded.allSatisfy(\.isArabicLetterForMorphology),
              let table = loadedTable() else { return [] }
        return table.lemmas.enumerated().compactMap { index, lemma in
            Self.fold(lemma.clean.isEmpty ? lemma.text : lemma.clean) == folded ? (index + 1, lemma) : nil
        }
    }

    /// Warms the parse (and the inverted index) off the calling thread's critical path.
    static func prewarm() {
        guard isBundled else { return }
        Task.detached(priority: .utility) {
            _ = MorphologyStore.shared.loadedOccurrences()
        }
    }

    func unload() {
        lock.lock(); defer { lock.unlock() }
        table = nil
        occurrences = nil
        loadFailed = false
    }

    // MARK: Loading

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

    private func loadedOccurrences() -> Occurrences? {
        lock.lock()
        if let occurrences { lock.unlock(); return occurrences }
        lock.unlock()
        guard let table = loadedTable() else { return nil }

        var byRoot: [Int: [WordLocation]] = [:]
        var byLemma: [Int: [WordLocation]] = [:]
        for surah in table.rootIDs.keys.sorted() {
            let roots = table.rootIDs[surah] ?? []
            let lemmas = table.lemmaIDs[surah] ?? []
            for (ayahIndex, tokens) in roots.enumerated() {
                for (token, id) in tokens.enumerated() where id != 0 {
                    byRoot[id, default: []].append(WordLocation(surah: surah, ayah: ayahIndex + 1, token: token))
                }
            }
            for (ayahIndex, tokens) in lemmas.enumerated() {
                for (token, id) in tokens.enumerated() where id != 0 {
                    byLemma[id, default: []].append(WordLocation(surah: surah, ayah: ayahIndex + 1, token: token))
                }
            }
        }
        let built = Occurrences(byRoot: byRoot, byLemma: byLemma)
        lock.lock(); defer { lock.unlock() }
        if let occurrences { return occurrences }
        occurrences = built
        return built
    }

    private static func load() -> Table? {
        guard let root = ThemesPack.json("Morphology") as? [String: Any],
              let rootRows = root["roots"] as? [[String]],
              let lemmaRows = root["lemmas"] as? [[String]],
              let rootIDs = root["r"] as? [String: [[Int]]],
              let lemmaIDs = root["l"] as? [String: [[Int]]] else { return nil }
        let roots = rootRows.map { Root(letters: $0.first ?? "", buckwalter: $0.count > 1 ? $0[1] : "") }
        let lemmas = lemmaRows.map { Lemma(text: $0.first ?? "", clean: $0.count > 1 ? $0[1] : "") }
        func keyed(_ raw: [String: [[Int]]]) -> [Int: [[Int]]] {
            var out: [Int: [[Int]]] = [:]
            for (key, rows) in raw {
                if let sid = Int(key) { out[sid] = rows }
            }
            return out
        }
        let table = Table(roots: roots, lemmas: lemmas, rootIDs: keyed(rootIDs), lemmaIDs: keyed(lemmaIDs))
        return table.roots.isEmpty || table.rootIDs.isEmpty ? nil : table
    }
}

private extension Character {
    var isArabicLetterForMorphology: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return (0x0621...0x064A).contains(scalar.value)
    }
}

// MARK: - The word card's morphology section

/// Root, dictionary form and counts for one tapped word, with the way into every other word of the
/// same root. Sits in the word card under the meaning; silent when the pack has nothing for the word.
struct WordMorphologySection: View {
    @ObservedObject private var settings = Settings.shared

    let surah: Surah
    let ayah: Ayah
    /// The token index inside the ayah's RAW Hafs text (the index the pack is aligned to).
    let tokenIndex: Int

    private var rootInfo: (id: Int, root: MorphologyStore.Root)? {
        MorphologyStore.shared.root(surah: surah.id, ayah: ayah.id, token: tokenIndex)
    }

    private var lemmaInfo: (id: Int, lemma: MorphologyStore.Lemma)? {
        MorphologyStore.shared.lemma(surah: surah.id, ayah: ayah.id, token: tokenIndex)
    }

    var body: some View {
        if MorphologyStore.isBundled, rootInfo != nil || lemmaInfo != nil {
            VStack(alignment: .leading, spacing: 10) {
                Divider()
                    .padding(.bottom, 4)

                Text("ROOT AND FORM")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                HStack(alignment: .top, spacing: 12) {
                    if let rootInfo {
                        morphologyTile(title: "Root", value: rootInfo.root.letters, count: MorphologyStore.shared.occurrences(ofRoot: rootInfo.id).count)
                    }
                    if let lemmaInfo {
                        morphologyTile(title: "Dictionary form", value: lemmaInfo.lemma.text, count: MorphologyStore.shared.occurrences(ofLemma: lemmaInfo.id).count)
                    }
                }

                if let rootInfo {
                    let locations = MorphologyStore.shared.occurrences(ofRoot: rootInfo.id)
                    NavigationLink {
                        RootOccurrencesView(
                            title: "Root \(rootInfo.root.letters)",
                            locations: locations,
                            highlight: WordLocation(surah: surah.id, ayah: ayah.id, token: tokenIndex)
                        )
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "text.magnifyingglass")
                            Text("Every Word From This Root")
                                .fontWeight(.medium)
                            Spacer()
                            Text("\(locations.count)")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .font(.subheadline)
                        .foregroundColor(settings.accentColor.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(settings.accentColor.color.opacity(0.10))
                        )
                    }
                    .buttonStyle(.plain)
                }

                Text("Roots and dictionary forms from the Quranic Arabic Corpus (Kais Dukes), via the Quranic Universal Library.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 8)
        }
    }

    private func morphologyTile(title: String, value: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.custom(settings.quranArabicFontName(for: nil), size: 22))
                .arabicFontDesign(custom: true)
                .foregroundColor(settings.accentColor.color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(count == 1 ? "1 word in the Quran" : "\(count) words in the Quran")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        )
    }
}

// MARK: - Every word of one root

/// The ayahs carrying a root (or a dictionary form), the carrying word tinted in each. Pushed inside a
/// sheet (the word card) or from the Quran tab's search; with `onOpenAyah` set, tapping a row opens
/// the ayah in the reader.
struct RootOccurrencesView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    let title: String
    let locations: [WordLocation]
    /// The word the list was opened from, marked so the reader can find their place in a long list.
    var highlight: WordLocation? = nil
    var onOpenAyah: ((Int, Int) -> Void)? = nil

    @State private var searchText = ""

    private struct Row: Identifiable {
        let surah: Surah
        let ayah: Ayah
        let tokens: [Int]
        var id: String { "\(surah.id):\(ayah.id)" }
    }

    /// One row per ayah (a root can occur twice in an ayah), in mushaf order.
    private var rows: [Row] {
        var order: [String] = []
        var tokens: [String: [Int]] = [:]
        for location in locations {
            if tokens[location.ayahKey] == nil { order.append(location.ayahKey) }
            tokens[location.ayahKey, default: []].append(location.token)
        }
        return order.compactMap { key in
            let parts = key.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 2, let surah = quranData.surah(parts[0]),
                  let ayah = quranData.ayah(surah: parts[0], ayah: parts[1]) else { return nil }
            return Row(surah: surah, ayah: ayah, tokens: tokens[key] ?? [])
        }
    }

    private var filteredRows: [Row] {
        let query = settings.cleanSearch(searchText, whitespace: true)
        let all = rows
        guard !query.isEmpty else { return all }
        return all.filter { row in
            settings.cleanSearch(row.surah.nameTransliteration).contains(query)
                || "\(row.surah.id):\(row.ayah.id)".contains(query)
                || settings.cleanSearch(row.ayah.textEnglishSaheeh).contains(query)
                || settings.cleanSearch(row.ayah.textHafs).contains(query)
        }
    }

    var body: some View {
        let shown = filteredRows
        let ayahCount = rows.count

        List {
            Section(header: SectionPillHeader(title: "AYAHS", count: shown.count)) {
                ForEach(shown) { row in
                    occurrenceRow(row)
                        .id(row.id)
                }
                if shown.isEmpty {
                    Text("No ayahs match your search.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if searchText.isEmpty {
                Section(footer:
                    Text("\(locations.count) words across \(ayahCount) ayahs. The tinted word carries the root; roots come from the Quranic Arabic Corpus via the Quranic Universal Library.")
                        .font(.caption2)
                ) { EmptyView() }
            }
        }
        .applyConditionalListStyle(disableNowPlayingInset: true)
        .dismissKeyboardOnScroll()
        .adaptiveSafeArea(edge: .bottom) {
            SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut), placeholder: "Search these ayahs")
                .padding(.horizontal, 24)
                .padding(.bottom, BottomBarCushion.standard)
                .background(Color.white.opacity(0.00001))
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func occurrenceRow(_ row: Row) -> some View {
        let content = WordOccurrenceRow(
            surah: row.surah, ayah: row.ayah, tokens: row.tokens,
            isOrigin: highlight?.surah == row.surah.id && highlight?.ayah == row.ayah.id
        ).equatable()
        if let onOpenAyah {
            Button {
                settings.hapticFeedback()
                onOpenAyah(row.surah.id, row.ayah.id)
            } label: {
                content
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

/// One ayah with some of its words tinted: the reference, the Arabic (raw Hafs text, so the token
/// indices from the packs land exactly), and the current translation. Shared by the root list and
/// the repeated-phrases list. Everything the body needs is derived once at init (the inputs are
/// immutable) and the row is Equatable over it, so a list of 170 of these re-renders a row only when
/// its own words, or a setting it reads, changed (Tilawa Guide, Phase 6 step 8). Wrap call sites in
/// `.equatable()`.
struct WordOccurrenceRow: View, Equatable {
    @ObservedObject private var settings = Settings.shared

    let surah: Surah
    let ayah: Ayah
    /// 0-based token indices of the RAW Hafs text to tint.
    let tokens: [Int]
    var isOrigin: Bool = false
    var caption: String? = nil
    /// Tokens tinted in a SECOND color (orange): the words that differ from the occurrence the list
    /// was opened from, so two near-identical ayahs are told apart at a glance.
    var contrastTokens: [Int] = []

    // Derived at init.
    private let arabic: String
    private let tintRanges: [NSRange]
    /// The two-color rendering: shared words in the accent, differing words in orange.
    private let contrastStyled: AttributedString?
    private let translation: String?
    // The settings the body reads, captured so `==` can compare them.
    private let accent: Color
    private let fontName: String
    private let arabicSize: CGFloat
    private let englishSize: CGFloat

    init(surah: Surah, ayah: Ayah, tokens: [Int], isOrigin: Bool = false, caption: String? = nil, contrastTokens: [Int] = []) {
        self.surah = surah
        self.ayah = ayah
        self.tokens = tokens
        self.isOrigin = isOrigin
        self.caption = caption
        self.contrastTokens = contrastTokens
        let settings = Settings.shared
        accent = settings.accentColor.color
        fontName = settings.quranArabicFontName(for: nil)
        arabicSize = CGFloat(settings.fontArabicSize) - 4
        englishSize = CGFloat(settings.englishFontSize)
        let text = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: "")
        arabic = text
        let ranges = WordTokens.ranges(in: text)
        tintRanges = tokens.compactMap { ranges.indices.contains($0) ? ranges[$0] : nil }
        if contrastTokens.isEmpty {
            contrastStyled = nil
        } else {
            var styled = AttributedString(text)
            styled.foregroundColor = .primary
            func paint(_ indices: [Int], _ color: Color) {
                for index in indices where ranges.indices.contains(index) {
                    guard let range = Range(ranges[index], in: text),
                          let lo = AttributedString.Index(range.lowerBound, within: styled),
                          let hi = AttributedString.Index(range.upperBound, within: styled), lo < hi else { continue }
                    styled[lo..<hi].foregroundColor = color
                }
            }
            paint(contrastTokens, .orange)
            paint(tokens, accent)
            contrastStyled = styled
        }
        translation = currentTranslationText(for: ayah)
    }

    static func == (lhs: WordOccurrenceRow, rhs: WordOccurrenceRow) -> Bool {
        lhs.surah.id == rhs.surah.id && lhs.ayah.id == rhs.ayah.id && lhs.tokens == rhs.tokens
            && lhs.isOrigin == rhs.isOrigin && lhs.caption == rhs.caption && lhs.contrastTokens == rhs.contrastTokens
            && lhs.accent == rhs.accent && lhs.fontName == rhs.fontName && lhs.arabicSize == rhs.arabicSize
            && lhs.englishSize == rhs.englishSize && lhs.translation == rhs.translation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("\(surah.nameTransliteration) \(surah.id):\(ayah.id)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(accent)

                if isOrigin {
                    Text("This ayah")
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(accent.opacity(0.15)))
                        .foregroundColor(accent)
                }

                if let caption {
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    settings.hapticFeedback()
                    QuranPlayer.shared.playAyah(surahNumber: surah.id, ayahNumber: ayah.id)
                } label: {
                    Image(systemName: "play.circle")
                        .font(.body)
                        .foregroundColor(accent)
                }
                .buttonStyle(.plain)
            }

            HighlightedSnippet(
                source: arabic,
                term: "",
                font: .custom(fontName, size: arabicSize),
                accent: accent,
                fg: .primary,
                preStyledSource: contrastStyled,
                extraHighlightRanges: contrastStyled == nil ? tintRanges : []
            )
            .arabicFontDesign(custom: true)
            .multilineTextAlignment(.trailing)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .trailing)

            if let translation {
                Text(translation)
                    .font(.system(size: englishSize))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 6)
        .textSelection(.enabled)
    }
}
#endif
