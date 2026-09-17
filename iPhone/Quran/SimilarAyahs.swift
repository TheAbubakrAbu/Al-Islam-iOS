#if os(iOS)
import SwiftUI
import Compression

// Similar Ayahs: pick an ayah, see the other places the Quran says something like it.
//
// The data is `Resources/Data/Quran/SimilarAyahs.json.xz`, built by
// Scripts/build_similar_ayahs.py and gated by Scripts/verify_similar_ayahs.py. Three sources,
// merged and RANKED AT BUILD TIME so nothing here scores or sorts:
//   * verified - qurani.ai's similar-ayah corpus (the classical mutashabihat), shown first;
//   * generated - phrase-overlap matches from the Tilawa app's generator, with reason labels;
//   * QUL - the Quranic Universal Library's similar-ayah table, which adds the SPANS of the shared
//     words in the matched ayah (tinted in the rows) and the pairs the other two lack.
// The pack stores NO Quran text: the shared wording every source records is located in the
// matched ayah at build time and kept as token spans into this app's own text, so the rows tint
// the words the reader has, never a copy that can drift from them (version 2, 2026-09-16).
// The sheet's second tab is the repeated PHRASES of the ayah (`MutashabihatStore`).
//
// Ported from Tilawa (by Jamil Hammoudeh), with permission - see CreditsView.

// MARK: - Store

/// One match row, in display order. `spans` is the shared wording, as token ranges into the
/// matched ayah; `labels` the generated matcher's reasons (empty for verified rows).
struct SimilarAyahMatch: Identifiable {
    let surah: Int
    let ayah: Int
    let verified: Bool
    let labels: [String]
    /// 0-based inclusive token ranges of the shared words in the TARGET ayah's raw Hafs text:
    /// QUL's own placement where it lists the pair, else the corpus's recorded phrase located in
    /// the ayah at build time. Empty when no source records shared wording for the pair.
    var spans: [ClosedRange<Int>] = []
    /// QUL's 0-100 similarity score, when it listed the pair.
    var score: Int? = nil

    var id: String { "\(surah):\(ayah)" }
}

/// Same load pattern as `WordByWordStore`: lazy, lock-guarded, ~4.5 MB of JSON parsed off the
/// hot path on first use, dropped wholesale on `unload()`.
final class SimilarAyahsStore: @unchecked Sendable {
    static let shared = SimilarAyahsStore()
    private init() {}

    private let lock = NSLock()
    private var table: [String: [SimilarAyahMatch]]?
    private var loadFailed = false

    static let isBundled: Bool = packURL() != nil

    /// Matches for one ayah in display order, or [] when it has none (most short ayahs).
    func matches(surah: Int, ayah: Int) -> [SimilarAyahMatch] {
        loadedTable()?["\(surah):\(ayah)"] ?? []
    }

    /// Whether the sheet is worth offering for this ayah - a dictionary hit, no text decode.
    func hasMatches(surah: Int, ayah: Int) -> Bool {
        !matches(surah: surah, ayah: ayah).isEmpty
    }

    func unload() {
        lock.lock(); defer { lock.unlock() }
        table = nil
        loadFailed = false
    }

    private func loadedTable() -> [String: [SimilarAyahMatch]]? {
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

    private static func packURL() -> URL? {
        Bundle.main.url(forResource: "SimilarAyahs", withExtension: "json.xz", subdirectory: "Data/Quran")
            ?? Bundle.main.url(forResource: "SimilarAyahs", withExtension: "json.xz", subdirectory: "Quran")
            ?? Bundle.main.url(forResource: "SimilarAyahs", withExtension: "json.xz")
    }

    private static func load() -> [String: [SimilarAyahMatch]]? {
        guard let url = packURL(),
              let blob = try? Data(contentsOf: url),
              let json = inflate(blob),
              let pack = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              // Version 2 only: a version-1 pack carried the shared wording as text, which the
              // sheet no longer reads, so an old pack is treated as no pack rather than half a one.
              pack["v"] as? Int == 2,
              let raw = pack["ayahs"] as? [String: [[Any]]] else { return nil }

        var out: [String: [SimilarAyahMatch]] = [:]
        out.reserveCapacity(raw.count)
        for (key, rows) in raw {
            var matches: [SimilarAyahMatch] = []
            matches.reserveCapacity(rows.count)
            for row in rows {
                // row = [surah, ayah, verifiedFlag, spans, labels, score] - see the build script.
                guard row.count == 6,
                      let surah = row[0] as? Int,
                      let ayah = row[1] as? Int,
                      let flag = row[2] as? Int else { continue }
                let spans = (row[3] as? [[Int]] ?? []).compactMap { span -> ClosedRange<Int>? in
                    guard span.count == 2, span[1] >= span[0] else { return nil }
                    return span[0]...span[1]
                }
                let labels = row[4] as? [String] ?? []
                let score = row[5] as? Int
                matches.append(SimilarAyahMatch(
                    surah: surah, ayah: ayah, verified: flag == 1, labels: labels,
                    spans: spans, score: score
                ))
            }
            if !matches.isEmpty { out[key] = matches }
        }
        return out.isEmpty ? nil : out
    }

    /// The payload is an xz stream; `COMPRESSION_LZMA` reads that container directly.
    private static func inflate(_ data: Data) -> Data? {
        SolidPack.xzDecompress(data)
    }
}

// MARK: - Sheet

/// The related verses for one ayah, readable in place: reference, why it matched (verified
/// badge or the matcher's reasons), the shared wording, then the full Arabic and English.
/// Why a match is a match, from its reason labels: the generator names a shared phrase, shared
/// roots ("Root ktb", Buckwalter letters) and shared themes. The chips above the list filter on them.
enum SimilarAyahFilter: String, CaseIterable, Identifiable {
    case all, verified, phrase, root, theme

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .verified: return "Verified"
        case .phrase: return "Phrase"
        case .root: return "Roots"
        case .theme: return "Themes"
        }
    }

    func matches(_ match: SimilarAyahMatch) -> Bool {
        switch self {
        case .all: return true
        case .verified: return match.verified
        case .phrase: return !match.spans.isEmpty || match.labels.contains("Shared phrase")
        case .root: return match.labels.contains { $0.hasPrefix("Root ") }
        case .theme: return match.labels.contains { $0 != "Shared phrase" && !$0.hasPrefix("Root ") }
        }
    }

    /// The Buckwalter transliteration the labels carry roots in, back to Arabic letters.
    private static let buckwalter: [Character: String] = [
        "'": "ء", "|": "آ", ">": "أ", "&": "ؤ", "<": "إ", "}": "ئ", "A": "ا", "b": "ب", "p": "ة",
        "t": "ت", "v": "ث", "j": "ج", "H": "ح", "x": "خ", "d": "د", "*": "ذ", "r": "ر", "z": "ز",
        "s": "س", "$": "ش", "S": "ص", "D": "ض", "T": "ط", "Z": "ظ", "E": "ع", "g": "غ", "f": "ف",
        "q": "ق", "k": "ك", "l": "ل", "m": "م", "n": "ن", "h": "ه", "w": "و", "Y": "ى", "y": "ي",
        "{": "ٱ",
    ]

    /// "Root ktb" -> "Root ك ت ب": the shared root spelled out in Arabic, letters spaced.
    static func displayLabel(_ label: String) -> String {
        guard label.hasPrefix("Root ") else { return label }
        let root = label.dropFirst(5).filter { $0 != " " && $0 != "-" }
        let letters = root.compactMap { buckwalter[$0] }
        return letters.isEmpty ? label : "Root " + letters.joined(separator: " ")
    }
}

struct SimilarAyahsSheet: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranData = QuranData.shared

    /// The sheet's two lists: ayahs that say something like this one, and the phrases this one
    /// repeats word for word elsewhere (mutashabihat).
    enum Tab: String, CaseIterable, Identifiable {
        case similar, phrases
        var id: String { rawValue }
        var title: String { self == .similar ? "Similar Ayahs" : "Repeated Phrases" }
    }

    let surahNumber: Int
    let ayahNumber: Int

    init(surahNumber: Int, ayahNumber: Int, initialTab: Tab = .similar) {
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        _tab = State(initialValue: MutashabihatStore.isBundled ? initialTab : .similar)
    }

    @State private var tab: Tab

    /// nil while the pack is still parsing. The first open pays a ~4.5 MB JSON parse, so it
    /// happens off the main thread behind a spinner instead of freezing the sheet's slide-up;
    /// every later open is a dictionary hit and resolves before the spinner can appear.
    @State private var matches: [SimilarAyahMatch]?
    /// The repeated phrases, loaded alongside (a much smaller pack).
    @State private var phrases: [MutashabihatStore.Phrase]?
    /// Which reasons the similar list is narrowed to (the chips above it).
    @State private var filter: SimilarAyahFilter = .all

    private var sheetTitle: String {
        let name = quranData.surah(surahNumber)?.nameTransliteration ?? "Surah \(surahNumber)"
        return tab == .similar ? "Similar to \(name) \(surahNumber):\(ayahNumber)" : "Phrases in \(name) \(surahNumber):\(ayahNumber)"
    }

    var body: some View {
        NavigationView {
            Group {
                if let matches {
                    List {
                        if MutashabihatStore.isBundled {
                            Section {
                                Picker("List", selection: $tab) {
                                    ForEach(Tab.allCases) { item in
                                        Text(item.title).tag(item)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: tab) { _ in settings.hapticFeedback() }
                                .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                                .listRowBackground(Color.clear)
                            }
                        }

                        if tab == .phrases {
                            let list = phrases ?? []
                            if list.isEmpty {
                                Text("No repeated phrases are recorded for this ayah.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            } else {
                                Section(footer:
                                    Text("Phrases this ayah shares word for word with others, longest first, from the Quranic Universal Library's Mutashabihat ul Quran. Open one to read every occurrence side by side.")
                                        .font(.caption2)
                                ) {
                                    MutashabihatRows(surahNumber: surahNumber, ayahNumber: ayahNumber, phrases: list)
                                }
                            }
                        } else if matches.isEmpty {
                            Text("No similar ayahs are recorded for this ayah.")
                                .font(.body)
                                .foregroundColor(.secondary)
                        } else {
                            let shown = matches.filter { filter.matches($0) }
                            Section {
                                filterChips(matches)
                                    .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
                                    .listRowBackground(Color.clear)
                            }

                            Section(footer: sourcesFootnote) {
                                if shown.isEmpty {
                                    Text("No \(filter.title.lowercased()) matches for this ayah. Try another filter.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                ForEach(shown) { match in
                                    matchRow(match)
                                }
                            }
                        }
                    }
                    .applyConditionalListStyle(disableNowPlayingInset: true)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .sheetDismissToolbar()
        }
        .navigationViewStyle(.stack)
        .smallMediumSheetPresentation()
        .task {
            let surah = surahNumber, ayah = ayahNumber
            // The stores are lock-guarded, so the parses are safe off the main actor.
            let loaded = await Task.detached(priority: .userInitiated) {
                (SimilarAyahsStore.shared.matches(surah: surah, ayah: ayah),
                 MutashabihatStore.isBundled ? MutashabihatStore.shared.phrases(surah: surah, ayah: ayah) : [])
            }.value
            phrases = loaded.1
            matches = loaded.0
        }
    }

    /// One chip per reason kind that has matches, with its count; a chip only appears when it would
    /// show something, so short lists carry two chips and long ones five.
    private func filterChips(_ matches: [SimilarAyahMatch]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SimilarAyahFilter.allCases) { kind in
                    let count = matches.filter { kind.matches($0) }.count
                    if count > 0, kind == .all || count < matches.count || kind == .verified {
                        let selected = filter == kind
                        Button {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) { filter = kind }
                        } label: {
                            HStack(spacing: 5) {
                                Text(kind.title)
                                Text("\(count)")
                                    .foregroundColor(selected ? .white.opacity(0.85) : .secondary)
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(selected ? .white : .primary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(selected ? settings.accentColor.color : Color.primary.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
    }

    /// The reasons as chips: the shared phrase in the accent, roots spelled in Arabic, themes plain.
    private func reasonChips(_ labels: [String]) -> some View {
        FlowLayoutView(spacing: 6) {
            ForEach(Array(labels.enumerated()), id: \.offset) { _, label in
                let isPhrase = label == "Shared phrase"
                let isRoot = label.hasPrefix("Root ")
                Text(SimilarAyahFilter.displayLabel(label))
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(isPhrase ? settings.accentColor.color : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(isPhrase ? settings.accentColor.color.opacity(0.14)
                                       : (isRoot ? Color.primary.opacity(0.10) : Color.primary.opacity(0.06)))
                    )
            }
        }
    }

    private var sourcesFootnote: some View {
        Text("Verified matches come from qurani.ai's similar-ayah corpus; the rest are phrase-overlap matches, with the shared words tinted where the Quranic Universal Library's similar-ayah table places them.")
            .font(.caption2)
    }

    /// The tinted spans of a match, mapped from raw-text token indices onto the text on screen
    /// (Hide Tashkeel deletes the standalone ۞ token, so the display can be one token shorter).
    private func displayRanges(for match: SimilarAyahMatch, surah: Surah, ayah: Ayah, display: String) -> [NSRange] {
        guard !match.spans.isEmpty else { return [] }
        let raw = ayah.displayArabicText(surahId: surah.id, clean: false, qiraahOverride: "")
        let rawTokens = WordTokens.tokens(in: raw)
        let displayRanges = WordTokens.ranges(in: display)
        // Raw token index → display token index: identity when the counts agree, else the raw
        // tokens that survive sign-stripping, in order.
        var displayIndex: [Int] = []
        if rawTokens.count == displayRanges.count {
            displayIndex = Array(rawTokens.indices)
        } else {
            var next = 0
            for token in rawTokens {
                let survives = !token.removingArabicDiacriticsAndSigns.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                displayIndex.append(survives ? next : -1)
                if survives { next += 1 }
            }
            guard next == displayRanges.count else { return [] }
        }
        var out: [NSRange] = []
        for span in match.spans {
            for token in span where displayIndex.indices.contains(token) {
                let mapped = displayIndex[token]
                if mapped >= 0, displayRanges.indices.contains(mapped) { out.append(displayRanges[mapped]) }
            }
        }
        return out
    }

    @ViewBuilder
    private func matchRow(_ match: SimilarAyahMatch) -> some View {
        if let surah = quranData.surah(match.surah),
           let ayah = surah.ayahs.first(where: { $0.id == match.ayah }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("\(surah.nameTransliteration) \(match.surah):\(match.ayah)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(settings.accentColor.color)

                    if match.verified {
                        Text("Verified")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(settings.accentColor.color.opacity(0.15)))
                            .foregroundColor(settings.accentColor.color)
                    }

                    Spacer()

                    // The one action a row needs: hear this ayah where it lives.
                    Button {
                        settings.hapticFeedback()
                        QuranPlayer.shared.playAyah(surahNumber: match.surah, ayahNumber: match.ayah)
                    } label: {
                        Image(systemName: "play.circle")
                            .font(.body)
                            .foregroundColor(settings.accentColor.color)
                    }
                    .buttonStyle(.plain)
                }

                if !match.labels.isEmpty {
                    reasonChips(match.labels)
                }

                // The shared words tinted, from the pack's spans into this ayah's own tokens (QUL's
                // placement where it lists the pair, else the corpus's phrase located at build time).
                let display = ayah.displayArabicText(surahId: surah.id, clean: settings.cleanArabicText, qiraahOverride: "")
                let spans = displayRanges(for: match, surah: surah, ayah: ayah, display: display)
                HighlightedSnippet(
                    source: display,
                    term: "",
                    font: .custom(settings.quranArabicFontName(for: nil), size: CGFloat(settings.fontArabicSize) - 4),
                    accent: settings.accentColor.color,
                    fg: .primary,
                    extraHighlightRanges: spans
                )
                    .arabicFontDesign(custom: true)
                    .multilineTextAlignment(.trailing)
                    // Same fix as the theme topic rows: without an explicit "take the height you need",
                    // a long ayah in the bundled Uthmani face stops at two lines and ellipsizes mid-word.
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if settings.showEnglishSaheeh || !settings.showEnglishMustafa {
                    Text(ayah.textEnglishSaheeh)
                        .font(.system(size: CGFloat(settings.englishFontSize)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(ayah.textEnglishMustafa)
                        .font(.system(size: CGFloat(settings.englishFontSize)))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 6)
            // Brings these rows in line with `AyahRow`, which has had selection all along - the same
            // ayah shouldn't be copyable in the reader and inert in the similar-ayahs list.
            .textSelection(.enabled)
        }
    }
}
#endif
