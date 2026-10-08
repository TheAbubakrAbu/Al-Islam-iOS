#if os(iOS)
import SwiftUI

// WHERE A NARRATOR DIFFERS FROM HAFS, on his page in the Qiraat guide.
//
// The profile pages say what a riwayah is known for; this section shows it: the places where the
// narrator's own text reads a word differently from Hafs, as Hafs-reads / he-reads pairs, with the
// meaning of each form where the Quran.com qiraat reference gives one, and the same reciter reading
// the verse both ways where a recording exists (Warsh, Qalun, ad-Duri and Shubah have one). Every
// row opens the Qiraat Explorer at that place, and the section ends with the walk of a whole surah.
//
// Nothing here is authored. The pairs come from the app's own riwayah texts diffed against Hafs
// exactly as the explorer diffs them (`QiraatChange`), so a pair appears only because the two texts
// disagree at that word. Candidates are the classical teaching sites first (1:4 مالك / ملك and the
// rest of the list Tilawa's reference screen leads with), then the riwayah's own place index in
// mushaf order; a place is kept when the change is word-level (another word form, added or dropped
// letters) and short enough to read as one pair. The idea of worked examples under each rawi is
// Tilawa's (Jamil Hammoudeh), credited in Settings → Credits.
//
// Beta riwayat render text only once beta text is unlocked (`Settings.betaQiraatEnabled`); this
// section respects that gate like every other text surface, and says so instead of showing Hafs.

@MainActor
enum RiwayahDifferenceFinder {
    struct Example: Identifiable {
        let surah: Int
        let ayah: Int
        let surahName: String
        /// The Hafs words that change, as one phrase (stop signs dropped).
        let hafsWords: String
        /// The narrator's words in their place.
        let riwayahWords: String
        /// The reference's English rendering of the narrator's form; "" when it has none.
        let riwayahMeaning: String
        /// Hafs's rendering when the reference gives one that differs; "" otherwise.
        let hafsMeaning: String
        /// One reciter recorded the verse both ways.
        let hasAudio: Bool

        var id: String { "\(surah):\(ayah)" }
    }

    struct Summary {
        /// Hafs ayahs the narrator reads differently at word level.
        let wordLevel: Int
        /// Every differing ayah, down to one letter's dots, hamzah or vowel.
        let every: Int
    }

    /// The classical teaching sites, in their traditional order (Tilawa's list). A riwayah that
    /// differs at one of them leads with it, and only then falls through to its own place index.
    static let classicalSites: [(surah: Int, ayah: Int)] = [
        (1, 4), (2, 9), (2, 184), (2, 259), (2, 271), (3, 146), (5, 6), (30, 54),
        (21, 4), (2, 58), (4, 94), (9, 66), (12, 110), (18, 36), (43, 19), (57, 24),
        (2, 140), (6, 96), (10, 2), (34, 19), (2, 219), (3, 37), (7, 57), (11, 46),
        (17, 93), (20, 63), (25, 8), (28, 48), (36, 35), (39, 29), (48, 15), (53, 35),
        (56, 22), (67, 9), (81, 24), (85, 22), (92, 3), (101, 5),
    ]

    /// A pair stops reading as a pair past this many words a side.
    static let maxWordsPerSide = 4
    /// Places examined at most, so a riwayah that differs almost everywhere (Warsh: 3,700 ayahs)
    /// cannot keep the page waiting.
    static let maxCandidates = 240

    /// Counts across the Quran, from the bundled place index (per surah on demand without it).
    static func summary(tag: String) -> Summary {
        let store = QiraatPlacesStore.shared
        guard store.hasWholeQuranCounts else { return Summary(wordLevel: 0, every: 0) }
        var word = 0
        var every = 0
        for surah in 1...114 {
            for (_, words) in store.places(surah: surah, tag: tag) {
                every += 1
                if QiraatPlacesStore.counts(words, everyDifference: false) { word += 1 }
            }
        }
        return Summary(wordLevel: word, every: every)
    }

    /// Up to `limit` word-level pairs for the narrator, classical sites first. Yields between
    /// candidates so the page stays live while the surahs align.
    static func examples(tag: String, limit: Int) async -> [Example] {
        let quranData = QuranData.shared
        let store = QiraatPlacesStore.shared
        var seen = Set<String>()
        var candidates: [(surah: Int, ayah: Int)] = []
        for site in classicalSites where seen.insert("\(site.surah):\(site.ayah)").inserted {
            candidates.append(site)
        }
        scan: for surah in 1...114 {
            let places = store.places(surah: surah, tag: tag)
            for ayah in places.keys.sorted() where QiraatPlacesStore.counts(places[ayah] ?? [], everyDifference: false) {
                if seen.insert("\(surah):\(ayah)").inserted { candidates.append((surah, ayah)) }
                if candidates.count >= maxCandidates { break scan }
            }
            if surah % 10 == 0 { await Task.yield() }
        }

        var out: [Example] = []
        for (index, candidate) in candidates.enumerated() {
            if Task.isCancelled || out.count >= limit { break }
            if index % 4 == 3 { await Task.yield() }
            if let example = example(tag: tag, surah: candidate.surah, ayah: candidate.ayah, quranData: quranData) {
                out.append(example)
            }
        }
        return out
    }

    /// The pair at one Hafs ayah, or nil when the narrator reads it as Hafs does, differs only in
    /// a letter's marks, or changes more than reads as a pair.
    static func example(tag: String, surah: Int, ayah: Int, quranData: QuranData) -> Example? {
        guard let surahObject = quranData.surah(surah),
              let resolved = QiraahAyahResolver.resolve(surahNumber: surah, ayahNumber: ayah, anchorHafsAyah: ayah,
                                                        optionTag: tag, clean: false) else { return nil }
        let change = QiraatExplorerView.change(for: tag, surah: surah, hafsAyah: ayah, resolved: resolved, quranData: quranData)
        guard change.differsAtWordLevel else { return nil }
        let hafsIndices = change.hafsWordLevel.sorted()
        let riwayahIndices = change.riwayahWordLevel.sorted()
        guard !hafsIndices.isEmpty, !riwayahIndices.isEmpty,
              hafsIndices.count <= maxWordsPerSide, riwayahIndices.count <= maxWordsPerSide else { return nil }
        let hafsWords = phrase(change.diff.hafs, hafsIndices)
        let riwayahWords = phrase(change.diff.riwayah, riwayahIndices)
        guard !hafsWords.isEmpty, !riwayahWords.isEmpty, hafsWords != riwayahWords else { return nil }

        // The meaning, from the qiraat reference: the juncture whose Hafs words this change touches.
        var riwayahMeaning = ""
        var hafsMeaning = ""
        let variants = QiraatVariantsStore.shared
        let junctures = variants.junctures(surah: surah, ayah: ayah)
        let touched = Set(change.hafsWordsByAyah[ayah]?.filter { $0 >= 0 } ?? [])
        let key = "\(surah):\(ayah)"
        let juncture = junctures.first { juncture in
            juncture.segments.contains { segment in
                segment.key == key && (segment.range.map { range in range.contains(where: touched.contains) } ?? false)
            }
        } ?? (junctures.count == 1 ? junctures.first : nil)
        if let juncture {
            riwayahMeaning = variants.reading(in: juncture, followedBy: tag)?.english ?? ""
            let hafs = variants.reading(in: juncture, followedBy: "")?.english ?? ""
            if hafs != riwayahMeaning { hafsMeaning = hafs }
        }

        let hasAudio = QiraatVariantAudioStore.isBundled
            && QiraatVariantAudioStore.shared.pair(tag: tag, surah: surah, ayah: ayah) != nil
        return Example(surah: surah, ayah: ayah, surahName: surahObject.nameTransliteration,
                       hafsWords: hafsWords, riwayahWords: riwayahWords,
                       riwayahMeaning: riwayahMeaning, hafsMeaning: hafsMeaning, hasAudio: hasAudio)
    }

    private static func phrase(_ tokens: [QiraatWordDiff.Token], _ indices: [Int]) -> String {
        indices.compactMap { tokens.indices.contains($0) ? QiraatTint.withoutStopSigns(tokens[$0].text) : nil }
            .joined(separator: " ")
    }
}

// MARK: - The section

/// "WHERE WARSH DIFFERS FROM HAFS": the count of places, the pairs, and the way into the explorer.
struct RiwayahDifferencesSection: View {
    @ObservedObject private var settings = Settings.shared
    @Environment(\.appearance) private var appearance

    /// The narrator's riwayah tag (`Settings.Riwayah`); never Hafs.
    let tag: String
    /// The narrator's short name, as the header and the rows call him.
    let name: String

    @State private var examples: [RiwayahDifferenceFinder.Example] = []
    @State private var summary: RiwayahDifferenceFinder.Summary?
    @State private var loading = true
    @State private var showAll = false

    private static let collapsed = 6
    private static let limit = 14

    /// Beta text renders only once unlocked; a locked narrator's page says so instead of showing Hafs.
    private var unlocked: Bool {
        Settings.Riwayah.textOptions.contains { $0.tag == tag }
    }

    private var shown: [RiwayahDifferenceFinder.Example] {
        showAll ? examples : Array(examples.prefix(Self.collapsed))
    }

    var body: some View {
        Section {
            if !unlocked {
                Text("\(name)'s text is beta: machine-read from the printed mushaf and not yet proofread. Turn on beta qiraat text in the Quran settings to compare it with Hafs here; the printed mushaf itself is always in the reader.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                if let summary, summary.every > 0 {
                    Text(summaryLine(summary))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if loading && examples.isEmpty {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Finding the places…")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else if examples.isEmpty {
                    Text("\(name) reads no word differently from Hafs at the places checked; the differences are in the marks, which the Qiraat Explorer shows in full.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ForEach(shown) { example in
                    row(example)
                }

                if examples.count > Self.collapsed {
                    Button {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) { showAll.toggle() }
                    } label: {
                        HStack {
                            Text(showAll ? "Show fewer" : "Show \(examples.count - Self.collapsed) more")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Image(systemName: showAll ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .foregroundColor(appearance.accent)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink(destination: LazyDestination { QiraatExplorerView(surahWalk: tag) }) {
                    Label("Walk a whole surah as \(name) reads it", systemImage: "arrow.left.and.right.text.vertical")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(appearance.accent)
                }
            }
        } header: {
            Text("WHERE \(name.uppercased()) DIFFERS FROM HAFS")
        } footer: {
            if unlocked {
                Text("From this app's own text of the riwayah, compared with Hafs word by word the way the Qiraat Explorer compares them. Meanings are from the Quran.com qiraat reference; a recording plays where one reciter recorded both readings.")
            }
        }
        .task(id: "\(tag)|\(unlocked)") {
            await load()
        }
    }

    private func summaryLine(_ summary: RiwayahDifferenceFinder.Summary) -> String {
        if summary.wordLevel == summary.every {
            return "Reads \(summary.every.formatted()) ayahs differently from Hafs."
        }
        return "Reads \(summary.wordLevel.formatted()) ayahs differently from Hafs in their wording, and \(summary.every.formatted()) once every vowel and dot is counted."
    }

    private func load() async {
        guard unlocked else {
            loading = false
            return
        }
        loading = true
        summary = RiwayahDifferenceFinder.summary(tag: tag)
        let found = await RiwayahDifferenceFinder.examples(tag: tag, limit: Self.limit)
        guard !Task.isCancelled else { return }
        examples = found
        loading = false
    }

    private func row(_ example: RiwayahDifferenceFinder.Example) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(destination: LazyDestination { QiraatExplorerView(surah: example.surah, ayah: example.ayah) }) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(example.surahName) \(example.surah):\(example.ayah)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    pairLine("Hafs reads", words: example.hafsWords, tag: "", tint: .primary)
                    pairLine("\(name) reads", words: example.riwayahWords, tag: tag, tint: appearance.accent)

                    if !example.riwayahMeaning.isEmpty {
                        Text(example.riwayahMeaning)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        if !example.hafsMeaning.isEmpty {
                            Text("Hafs: \(example.hafsMeaning)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            if example.hasAudio {
                QiraatVariantAudioButtons(tag: tag, surah: example.surah, ayah: example.ayah, compact: true)
            }
        }
        .padding(.vertical, 2)
    }

    private func pairLine(_ label: String, words: String, tag: String, tint: Color) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 84, alignment: .leading)
            Spacer(minLength: 0)
            Text(words)
                .font(.custom(settings.quranArabicFontName(for: tag), size: 21))
                .arabicFontDesign(custom: true)
                .foregroundColor(tint)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
#endif
