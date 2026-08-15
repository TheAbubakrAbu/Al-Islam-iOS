import SwiftUI

#if os(iOS)

@MainActor
final class AyahTafsirViewModel: ObservableObject {
    /// Every edition's entry for this ayah, in author order, read straight out of the bundled packs.
    /// All six are bundled, so this is synchronous and complete from the first render - no loading
    /// states, no error states, no network, no session cache to rehydrate.
    @Published private(set) var tafsirs: [AyahTafsirEntry] = []

    private let surah: Int
    private let ayah: Int

    init(surah: Int, ayah: Int) {
        self.surah = surah
        self.ayah = ayah
    }

    func loadIfNeeded() {
        guard tafsirs.isEmpty else { return }
        tafsirs = TafsirAuthor.allCases.compactMap {
            TafsirStore.shared.entry(author: $0, surah: surah, ayah: ayah)
        }
    }

    func hasEntry(for author: TafsirAuthor) -> Bool {
        tafsirs.contains { author.matches($0.author) }
    }
}

#if canImport(FoundationModels)
extension TafsirAuthor {
    /// The "=== ... ===" section heading this edition gets in the multi-source summarize source -
    /// language spelled out so the model knows what it is reading. Internal (not private): the shared
    /// gatherer `AyahAISources` labels the same six editions for every ayah AI entry point.
    var summarizeSectionLabel: String {
        switch self {
        case .ibnKathir:       return "Tafsir Ibn Kathir (English)"
        case .maarifUlQuran:   return "Maarif Ul Quran (English)"
        case .tazkirulQuran:   return "Tazkirul Quran (English)"
        case .ibnKathirArabic: return "Tafsir Ibn Kathir (Arabic)"
        case .tabariArabic:    return "Tafsir al-Tabari (Arabic)"
        case .saadiArabic:     return "Tafsir as-Sa'di (Arabic)"
        }
    }
}
#endif

struct AyahTafsirSheet: View {
    @ObservedObject var settings = Settings.shared
    /// NOT @ObservedObject: the sheet only reads the long-loaded quran array. Observing it meant every
    /// background publish (search-index rebuilds, prewarm state) re-rendered the whole sheet mid-read.
    let quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahName: String
    let surahNumber: Int
    let ayahNumber: Int

    @StateObject private var viewModel: AyahTafsirViewModel
    @State private var searchText = ""
    @State private var matchCount = 0
    @State private var currentMatchIndex = 0
    @State private var showSummarize = false
    @AppStorage("quran.tafsir.author") private var selectedAuthorRawValue = TafsirAuthor.ibnKathir.rawValue

    init(surahName: String, surahNumber: Int, ayahNumber: Int) {
        self.surahName = surahName
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        _viewModel = StateObject(wrappedValue: AyahTafsirViewModel(surah: surahNumber, ayah: ayahNumber))
    }

    private var selectedAuthor: TafsirAuthor {
        get { TafsirAuthor(rawValue: selectedAuthorRawValue) ?? .ibnKathir }
        nonmutating set { selectedAuthorRawValue = newValue.rawValue }
    }

    private var selectedAuthorBinding: Binding<TafsirAuthor> {
        Binding(
            get: { selectedAuthor },
            set: { selectedAuthor = $0 }
        )
    }

    /// Language toggle backing: flipping languages jumps to the counterpart author (Ibn Kathir stays Ibn
    /// Kathir across the flip; the others land on their language's first author).
    private var languageBinding: Binding<Bool> {
        Binding(
            get: { selectedAuthor.isArabic },
            set: { wantsArabic in
                guard wantsArabic != selectedAuthor.isArabic else { return }
                if wantsArabic {
                    selectedAuthor = selectedAuthor == .ibnKathir ? .ibnKathirArabic : (TafsirAuthor.arabicCases.first ?? .ibnKathirArabic)
                } else {
                    selectedAuthor = selectedAuthor == .ibnKathirArabic ? .ibnKathir : (TafsirAuthor.englishCases.first ?? .ibnKathir)
                }
            }
        )
    }

    private var selectedTafsirEntry: AyahTafsirEntry? {
        if let match = viewModel.tafsirs.first(where: { selectedAuthor.matches($0.author) }) {
            return match
        }
        // Falling back to an English entry under an Arabic heading would show the wrong tafsir -
        // an Arabic edition with no entry shows the placeholder instead.
        return selectedAuthor.isArabic ? nil : viewModel.tafsirs.first
    }

    private var selectedTafsirText: String? {
        selectedTafsirEntry?.content
    }

    private var hasActiveSearch: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// No `ScrollViewProxy` any more: the body is one text view, so there are no per-block view ids to
    /// scroll to. Moving the current index is enough - `TafsirMarkdownView` boxes that match and scrolls
    /// the enclosing scroll view to it.
    private func recomputeMatches() {
        matchCount = TafsirMarkdownView.matchCount(markdown: selectedTafsirText ?? "", query: searchText)
        currentMatchIndex = 0
    }

    private func goToMatch(_ delta: Int) {
        guard matchCount > 0 else { return }
        currentMatchIndex = (currentMatchIndex + delta + matchCount) % matchCount
    }

    /// Every ayah of the group as ONE concatenated Text, each followed by its Arabic ayah number in
    /// the accent - the same inline-marker flow a mushaf page uses.
    private var combinedArabicRun: Text {
        var result = Text(verbatim: "")
        for ayah in tafsirArabicAyahs {
            let piece: Text
            if let styled = tafsirTajweedText(ayah) {
                piece = Text(styled)
            } else {
                piece = Text(tafsirArabicDisplay(ayah))
            }
            result = result + piece + Text(" \(ayah.idArabic) ").foregroundColor(settings.accentColor.accent1)
        }
        return result
    }

    /// The reader's display text for one of the card's ayahs: clean/no-dots per settings, beginner
    /// letter spacing when on - the same string an AyahRow would show.
    private func tafsirArabicDisplay(_ ayah: Ayah) -> String {
        let text = ayah.displayArabicText(surahId: surahNumber, clean: settings.cleanArabicText, qiraahOverride: settings.displayQiraahForArabic)
        return settings.beginnerMode ? text.beginnerSpaced : text
    }

    /// Tajweed-colored attributed text for the card, when tajweed is on and the display is Hafs.
    private func tafsirTajweedText(_ ayah: Ayah) -> AttributedString? {
        guard settings.showTajweedColors, settings.showArabicText, settings.isHafsDisplay else { return nil }
        let text = ayah.displayArabicText(surahId: surahNumber, clean: false)
        let displayText = settings.cleanArabicText ? ayah.displayArabicText(surahId: surahNumber, clean: true) : text
        let rendered = settings.beginnerMode ? displayText.beginnerSpaced : displayText
        return TajweedStore.shared.attributedText(
            surah: surahNumber,
            ayah: ayah.id,
            text: text,
            displayText: rendered,
            cleanDisplayText: settings.cleanArabicText,
            beginnerSpacing: settings.beginnerMode
        )
    }

    private var tafsirAyahRange: ClosedRange<Int> {
        parsedAyahRange(from: selectedTafsirEntry?.groupVerse) ?? ayahNumber...ayahNumber
    }

    private var tafsirArabicAyahs: [Ayah] {
        quranData.surah(surahNumber)?.ayahs.filter {
            tafsirAyahRange.contains($0.id) && $0.existsInQiraah(settings.displayQiraahForArabic, surahID: surahNumber)
        } ?? []
    }

    private var tafsirRangeTitle: String {
        // Same reference format as every other ayah sheet (e.g. "Al-Baqarah 1:1-5"), so the tafsir card's
        // heading matches the page actions sheet and the rest.
        ayahSheetTitle(surahNumber: surahNumber, ayahNumber: tafsirAyahRange.lowerBound,
                       endAyah: tafsirAyahRange.upperBound == tafsirAyahRange.lowerBound ? nil : tafsirAyahRange.upperBound)
    }

    private func parsedAyahRange(from groupVerse: String?) -> ClosedRange<Int>? {
        guard let groupVerse else { return nil }
        let trimmed = groupVerse.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // The API sends a full SENTENCE: "You are reading a tafsir for the group of verses 27:15 to
        // 27:19". The old parse split on ":" and took the LAST piece - just "19" - which collapsed a
        // five-ayah group to one and mistitled the card ("27:19" for a tap on 16). Pull every
        // surah:ayah pair instead and span their AYAH numbers.
        var ayahNumbers: [Int] = []
        if let regex = try? NSRegularExpression(pattern: #"(\d{1,3})\s*:\s*(\d{1,3})"#) {
            let matches = regex.matches(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed))
            for match in matches {
                if let range = Range(match.range(at: 2), in: trimmed), let ayah = Int(trimmed[range]) {
                    ayahNumbers.append(ayah)
                }
            }
        }
        // No S:A pairs at all (some editions send bare numbers): fall back to every number present.
        if ayahNumbers.isEmpty {
            ayahNumbers = trimmed
                .components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
                .filter { $0 != surahNumber }   // a stray surah number isn't an ayah bound
        }
        guard var lower = ayahNumbers.min(), var upper = ayahNumbers.max() else { return nil }

        // The tapped ayah is, by definition, part of this tafsir's group - the shown range must
        // always contain it, whatever the sentence said.
        lower = min(lower, ayahNumber)
        upper = max(upper, ayahNumber)

        let maxAyah = quranData.surah(surahNumber)?.numberOfAyahs(for: settings.displayQiraahForArabic) ?? upper
        let clampedLower = min(max(lower, 1), maxAyah)
        let clampedUpper = min(max(upper, clampedLower), maxAyah)
        return clampedLower...clampedUpper
    }

    var body: some View {
        NavigationView {
            // The ScrollView is ALWAYS mounted - the loading skeleton overlays it instead of replacing
            // it. A structural swap here gave the ScrollView a fresh identity whenever the state
            // flipped, which reset the reader's scroll position mid-read.
            Group {
                    ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            noticeCard
                            arabicAyahsCard

                            // Two-level author choice: language first, then the three authors of that
                            // language - six segments in one control were unreadably cramped.
                            Picker("Language", selection: languageBinding.animation(.easeInOut)) {
                                Text("English").tag(false)
                                Text("العربية").tag(true)
                            }
                            .pickerStyle(.segmented)

                            Picker("Tafsir", selection: selectedAuthorBinding.animation(.easeInOut)) {
                                ForEach(selectedAuthor.isArabic ? TafsirAuthor.arabicCases : TafsirAuthor.englishCases) { author in
                                    Text(author.shortTitle).tag(author)
                                }
                            }
                            .pickerStyle(.segmented)
                            .animation(.easeInOut, value: selectedAuthor)
                            .onChange(of: selectedAuthor) { _ in settings.hapticFeedback() }

                            if let tafsirText = selectedTafsirText {
                                VStack(alignment: selectedAuthor.isArabic ? .trailing : .leading, spacing: 12) {
                                    Text(selectedAuthor.displayTitle)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: selectedAuthor.isArabic ? .trailing : .leading)

                                    tafsirContentView(for: tafsirText)
                                        .frame(maxWidth: .infinity, alignment: selectedAuthor.isArabic ? .trailing : .leading)
                                }
                                .frame(maxWidth: .infinity, alignment: selectedAuthor.isArabic ? .trailing : .leading)
                                // Same trap as the ayah card above, on the tafsir PROSE: the Arabic branch
                                // asked for `.trailing` and then set an RTL environment, which resolves
                                // `.trailing` to the LEFT edge - so an Arabic tafsir (Ibn Kathir, al-Tabari,
                                // as-Sa'di) rendered leading. Pinned left-to-right so `.trailing` is the
                                // right edge and `.leading` the left, matching how `TafsirMarkdownView`'s
                                // `textAlignment` is read on the Surah Info sheet, which sets no override.
                                .environment(\.layoutDirection, .leftToRight)
                                .id(selectedAuthor.rawValue)
                                .textSelection(.enabled)
                            } else {
                                tafsirPlaceholder(
                                    title: "No Tafsir Found",
                                    systemImage: "text.book.closed",
                                    message: "This edition has no tafsir for this ayah."
                                )
                            }
                        }
                        .padding()
                    }
                    .safeAreaInset(edge: .bottom) {
                        if hasActiveSearch {
                            TafsirFindBar(
                                current: currentMatchIndex,
                                total: matchCount,
                                onPrevious: { goToMatch(-1) },
                                onNext: { goToMatch(1) }
                            )
                        }
                    }
                    .onChange(of: searchText) { _ in recomputeMatches() }
                    .onChange(of: selectedTafsirText) { _ in recomputeMatches() }
                    }
            }
            // Title reflects the tafsir's FULL range: when the selected tafsir groups several ayahs (Ibn
            // Kathir often does) it reads e.g. "Al-Baqarah 1:1-5", not just the tapped ayah.
            .navigationTitle(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: tafsirAyahRange.lowerBound, endAyah: tafsirAyahRange.upperBound))
            .navigationBarTitleDisplayMode(.inline)
            // The app's own bottom search bar, not `.searchable` - matching the reciter picker
            // (`SettingsQuranView.reciterSearchControlsInset`) and every other search in the app.
            // Behavior is unchanged: the same `searchText` still drives `recomputeMatches` and the find bar.
            .adaptiveSafeArea(edge: .bottom) {
                SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut), placeholder: "Search tafsir")
                    .padding([.leading, .top], -8)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .background(Color.white.opacity(0.00001))
            }
            .dismissKeyboardOnScroll()
            .sheetDismissToolbar()
            .accentWashedBackground()
            // On-device AI: summarize EVERYTHING the app has for this ayah - all six tafsir editions
            // plus the riwayat readings and the English translations (the shared `AyahAISources`
            // gathering), then chat about them, grounded only on those texts. Hidden entirely when
            // Apple Intelligence is unavailable (the Ask pattern).
            #if canImport(FoundationModels)
            .toolbar {
                // The availability check lives INSIDE the item (ViewBuilder, iOS 15-safe):
                // conditional toolbar items need the iOS 16 ToolbarContentBuilder.
                ToolbarItem(placement: .primaryAction) {
                    if OnDeviceAsk.isAvailable, !viewModel.tafsirs.isEmpty {
                        SummarizeToolbarButton { showSummarize = true }
                    }
                }
            }
            .sheet(isPresented: $showSummarize) {
                SummarizeSheet(
                    title: "Tafsir, riwayat & translations of \(tafsirRangeTitle)",
                    sourceText: "",
                    multiSource: true,
                    gatherSource: {
                        // The tafsirs and riwayat are instant local reads; the online translation
                        // editions are fetched best-effort (bundled ones go in regardless).
                        let online = await AyahAISources.fetchOnlineTranslations(surahNumber: surahNumber, hafsAyah: ayahNumber)
                        return OnDeviceAsk.combinedSource(
                            AyahAISources.combinedSections(
                                surahNumber: surahNumber,
                                ayahNumber: ayahNumber,
                                emphasis: .tafsir,
                                onlineTranslations: online
                            )
                        )
                    }
                )
            }
            #endif
        }
        .navigationViewStyle(.stack)
        // Synchronous: the packs are bundled, so the entries exist before the first frame renders.
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }

    private var noticeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Built Into the App", systemImage: "internaldrive")
                .font(.subheadline.weight(.semibold))

            Text("Every tafsir is built into the app and works offline: three English editions (Ibn Kathir, Maarif Ul Quran, Tazkirul Quran) and three Arabic (Ibn Kathir, al-Tabari, as-Sa'di). Nothing is downloaded.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    // The same ayah-card format as the page actions sheet: Arabic first, then the "Name S:A" reference
    // caption, then the ayah's ACTUAL text in the active translation - not just the translation's name.
    private var arabicAyahsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if tafsirArabicAyahs.isEmpty {
                Text("Arabic ayah unavailable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // ONE continuous run with inline ayah markers - the mushaf page's shape, not a stack of
                // separate rows. Rendered like the reader: the QURAN face, tajweed colors when on,
                // clean-text / no-dots choices, and beginner letter spacing.
                combinedArabicRun
                    .font(Font.arabic(settings.quranDisplayFontName, size: UIFont.preferredFont(forTextStyle: .title3).pointSize))
                    .arabicFontDesign(custom: settings.quranDisplayUsesCustomArabicFace)
                    // NO `.environment(\.layoutDirection, .rightToLeft)` here - see the same note on
                    // `AyahActionsSheet.ayahPreview`. `.trailing` means "the END edge", not "the right edge",
                    // so an RTL override resolves BOTH modifiers above to the LEFT and the ayah renders
                    // leading - which is exactly what it was doing. The bidi algorithm already lays the
                    // Arabic out right-to-left from the characters themselves; the visual right edge is
                    // `.trailing` in the app's left-to-right layout.
                    .multilineTextAlignment(.trailing)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // The reference header and the translation are English, so they read from the leading edge -
            // the mirror image of the Arabic run above, which sits trailing.
            VStack(alignment: .leading, spacing: 3) {
                Text(tafsirRangeTitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // The translation of every ayah the tafsir covers - one flowing paragraph (numbered
                // inline when the group spans several ayahs), matching the Arabic run above.
                let translations = tafsirArabicAyahs.compactMap { ayah -> String? in
                    guard let text = currentTranslationText(for: ayah) else { return nil }
                    return tafsirArabicAyahs.count > 1 ? "\(text) (\(ayah.id))" : text
                }
                if !translations.isEmpty {
                    Text(translations.joined(separator: " "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Clear glass - the accent-tinted wash fought the tajweed colors and the accent ayah markers.
        .conditionalGlassEffect(clear: true, rectangle: true)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(settings.accentColor.color.opacity(0.18), lineWidth: 1)
        )
        .textSelection(.enabled)
        .animation(.easeInOut, value: tafsirRangeTitle)
    }

    @ViewBuilder
    private func tafsirContentView(for content: String) -> some View {
        TafsirMarkdownView(
            markdown: content,
            searchText: searchText,
            accent: settings.accentColor.color,
            textAlignment: selectedAuthor.isArabic ? .trailing : .leading,
            currentMatchIndex: currentMatchIndex
        )
    }

    private func tafsirPlaceholder(title: String, systemImage: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

/// "About this Surah" sheet - bundled surah background, mirroring the Tafsir sheet: a source picker
/// (Maududi / Ibn Ashur), searchable content, and the same accent-foreground search match (no highlight box).
struct SurahInfoSheet: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahName: String
    let surahNumber: Int

    @State private var searchText = ""
    @State private var matchCount = 0
    @State private var currentMatchIndex = 0
    @State private var showSummarize = false
    @AppStorage("quran.surahInfo.source") private var selectedSourceName = ""

    private var sources: [SurahInfoSource] {
        var list = quranData.surahInfoSources(for: surahNumber)
        // Quranpedia's passage outline rides in as one more source: this sheet's picker, search,
        // and markdown handling all apply to it unchanged. Appended HERE (not in QuranData) so
        // targets that compile QuranData without the themes pack - the widget - never need the
        // store symbol.
        if let outline = SurahSectionsStore.shared.outlineMarkdown(surah: surahNumber) {
            list.append(SurahInfoSource(name: "Outline (Quranpedia)", contents: outline))
        }
        return list
    }

    private var selectedSource: SurahInfoSource? {
        sources.first(where: { $0.name == selectedSourceName }) ?? sources.first
    }

    private var selectedSourceBinding: Binding<String> {
        Binding(
            get: { selectedSource?.name ?? "" },
            set: { selectedSourceName = $0 }
        )
    }

    /// Starting the surah from this sheet closes it: you asked to LISTEN to the surah, so the reader - not
    /// the background info you were reading - is what should be on screen. Deferred by one runloop turn so
    /// the action (including one taken from the Repeat menu, whose own dismissal is still animating) has
    /// fully completed before its host goes away.
    private func dismissAfterStartingPlayback() {
        DispatchQueue.main.async { dismiss() }
    }

    /// True when the text is mostly Arabic script, so the sheet can lay it out right-to-left.
    private static func isArabic(_ text: String) -> Bool {
        var arabic = 0, latin = 0
        for scalar in text.unicodeScalars {
            let v = scalar.value
            if (0x0600...0x06FF).contains(v) || (0x0750...0x077F).contains(v) || (0x08A0...0x08FF).contains(v) {
                arabic += 1
            } else if (0x41...0x5A).contains(v) || (0x61...0x7A).contains(v) {
                latin += 1
            }
        }
        return arabic > latin
    }

    private var hasActiveSearch: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// No `ScrollViewProxy` any more: the body is one text view, so there are no per-block view ids to
    /// scroll to. Moving the current index is enough - `TafsirMarkdownView` boxes that match and scrolls
    /// the enclosing scroll view to it.
    private func recomputeMatches() {
        matchCount = TafsirMarkdownView.matchCount(markdown: selectedSource?.contents ?? "", query: searchText)
        currentMatchIndex = 0
    }

    private func goToMatch(_ delta: Int) {
        guard matchCount > 0 else { return }
        currentMatchIndex = (currentMatchIndex + delta + matchCount) % matchCount
    }

    var body: some View {
        NavigationView {
            Group {
                if sources.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Even with no bundled info, the sheet still offers playback.
                            #if os(iOS)
                            SurahInfoPlaybackCard(surahNumber: surahNumber, surahName: surahName,
                                                  onStartedPlaying: dismissAfterStartingPlayback)
                            #endif

                            infoPlaceholder
                        }
                        .padding()
                    }
                } else {
                    ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Listen from here: the page-mode header opens this sheet, so "play this
                            // surah" (once or on repeat) leads the sheet. Deliberately NOT gated on the
                            // displayed riwayah (isHafsDisplay): playback follows the selected reciter,
                            // which works whatever Arabic text is on screen - hiding the button under
                            // other qiraat display was wrong.
                            #if os(iOS)
                            SurahInfoPlaybackCard(surahNumber: surahNumber, surahName: surahName,
                                                  onStartedPlaying: dismissAfterStartingPlayback)
                            #endif

                            noticeCard
                            surahHeaderCard

                            if sources.count > 1 {
                                Picker("Source", selection: selectedSourceBinding.animation(.easeInOut)) {
                                    ForEach(sources) { source in
                                        Text(source.name).tag(source.name)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .animation(.easeInOut, value: selectedSource)
                                .onChange(of: selectedSourceName) { _ in settings.hapticFeedback() }
                            }

                            if let source = selectedSource {
                                let arabic = Self.isArabic(source.contents)
                                VStack(alignment: arabic ? .trailing : .leading, spacing: 12) {
                                    Text(source.name)
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: arabic ? .trailing : .leading)

                                    TafsirMarkdownView(
                                        markdown: source.contents,
                                        searchText: searchText,
                                        accent: settings.accentColor.color,
                                        textAlignment: arabic ? .trailing : .leading,
                                        currentMatchIndex: currentMatchIndex
                                    )
                                    .frame(maxWidth: .infinity, alignment: arabic ? .trailing : .leading)
                                }
                                .frame(maxWidth: .infinity, alignment: arabic ? .trailing : .leading)
                                .id(source.name)
                                .textSelection(.enabled)
                            }
                        }
                        .padding()
                    }
                    .safeAreaInset(edge: .bottom) {
                        if hasActiveSearch {
                            TafsirFindBar(
                                current: currentMatchIndex,
                                total: matchCount,
                                onPrevious: { goToMatch(-1) },
                                onNext: { goToMatch(1) }
                            )
                        }
                    }
                    .onChange(of: searchText) { _ in recomputeMatches() }
                    .onChange(of: selectedSourceName) { _ in recomputeMatches() }
                    }
                }
            }
            .navigationTitle("Surah \(surahNumber): \(surahName)")
            .navigationBarTitleDisplayMode(.inline)
            // The app's own bottom search bar, not `.searchable` - see the tafsir sheet above.
            .adaptiveSafeArea(edge: .bottom) {
                SearchBar(text: AppPerformance.shouldReduceAnimations ? $searchText : $searchText.animation(.easeInOut), placeholder: "Search info")
                    .padding([.leading, .top], -8)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                    .background(Color.white.opacity(0.00001))
            }
            .dismissKeyboardOnScroll()
            .accentWashedBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            // On-device AI: summarize the surah's FULL background - every bundled source (Maududi,
            // Ibn Ashur, ...), not just the one on screen - then chat about it, grounded only on
            // those texts. Hidden entirely when Apple Intelligence is unavailable.
            #if canImport(FoundationModels)
            .toolbar {
                // The availability check lives INSIDE the item (ViewBuilder, iOS 15-safe):
                // conditional toolbar items need the iOS 16 ToolbarContentBuilder.
                ToolbarItem(placement: .primaryAction) {
                    if OnDeviceAsk.isAvailable,
                       sources.contains(where: { !$0.contents.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                        SummarizeToolbarButton { showSummarize = true }
                    }
                }
            }
            .sheet(isPresented: $showSummarize) {
                let combined = OnDeviceAsk.combinedSource(sources.map {
                    OnDeviceAsk.SummarizeSection(label: "\($0.name) - About this Surah", text: $0.contents)
                })
                SummarizeSheet(
                    title: "About Surah \(surahNumber): \(surahName)",
                    sourceText: combined.text,
                    multiSource: true,
                    sourceTruncated: combined.truncated
                )
            }
            #endif
        }
        .navigationViewStyle(.stack)
        .modifier(SheetPresentationModifier())
    }

    private var noticeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About this Surah", systemImage: "book.closed")
                .font(.subheadline.weight(.semibold))

            Text("Background on this surah: its name, period of revelation, and themes. Switch between sources with the picker.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.1))
        )
    }

    @ViewBuilder
    private var surahHeaderCard: some View {
        if let surah = quranData.surah(surahNumber) {
            VStack(alignment: .leading, spacing: 10) {
                // Always show the full surah row details.
                SurahRow(surah: surah, hideInfo: false).equatable()

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Label("Revelation Info", systemImage: "book.closed")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)

                    Text("Revelation order: #\(surah.revelationOrder.map(String.init) ?? "Unknown")")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let exceptions = surah.revelationExceptions?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !exceptions.isEmpty {
                        Text("Exceptions: \(exceptions)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Precomputed at build time (Scripts/generate_surah_stats.py) and bundled as
                // surah-stats.json - decoded once into SurahStatsStore, never counted at runtime.
                if let stats = SurahStatsStore.stats(for: surahNumber) {
                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Label("Surah Facts", systemImage: "number")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(settings.accentColor.color)

                        Text("Ayahs: \(stats.ayahs.formatted())")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Words: \(stats.words.formatted())")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Letters: \(stats.letters.formatted())")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(stats.juzLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Revelation: \(stats.revelationLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Label("Your Stats", systemImage: "chart.bar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(settings.accentColor.color)

                    Text("Opened: \(settings.surahOpenCount(surahNumber)) time\(settings.surahOpenCount(surahNumber) == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Played: \(settings.surahPlayCount(surahNumber)) time\(settings.surahPlayCount(surahNumber) == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .conditionalGlassEffect(rectangle: true, useColor: 0.08)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(settings.accentColor.color.opacity(0.18), lineWidth: 1)
            )
            .textSelection(.enabled)
        }
    }

    private var infoPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "text.book.closed")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("No Info Found")
                .font(.headline)

            Text("No background information is available for this surah.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#if os(iOS)
/// The surah info sheet's playback card: play the surah once, or a chosen number of times. A separate
/// struct so the player's per-ayah ticks only re-render this card, not the whole markdown sheet.
private struct SurahInfoPlaybackCard: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared

    let surahNumber: Int
    let surahName: String
    /// Called right after playback STARTS (once or on repeat) - never on stop. The sheet uses it to close
    /// itself, so starting a surah leaves you looking at the surah instead of at the info you just read.
    var onStartedPlaying: () -> Void = {}

    private var isPlayingThisSurah: Bool {
        (quranPlayer.isPlaying || quranPlayer.isPaused) && quranPlayer.currentSurahNumber == surahNumber
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                settings.hapticFeedback()
                if isPlayingThisSurah {
                    quranPlayer.stop()
                } else {
                    quranPlayer.playSurah(surahNumber: surahNumber, surahName: surahName)
                    onStartedPlaying()
                }
            } label: {
                Label(isPlayingThisSurah ? "Stop Playing" : "Play Surah",
                      systemImage: isPlayingThisSurah ? "stop.fill" : "play.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(settings.accentColor.color)
            .conditionalGlassEffect(rectangle: true, useColor: 0.12)

            Menu {
                Text("Play the surah this many times")
                    .foregroundStyle(.secondary)

                ForEach([2, 3, 5, 10, 15, 20], id: \.self) { n in
                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playSurah(surahNumber: surahNumber, surahName: surahName, repeatCount: n)
                        onStartedPlaying()
                    } label: {
                        Label("Play \(n)×", systemImage: "\(n).circle")
                    }
                }
            } label: {
                Label("Repeat", systemImage: "repeat")
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .contentShape(Rectangle())
            }
            .foregroundColor(settings.accentColor.color)
            .conditionalGlassEffect(rectangle: true, useColor: 0.12)
        }
        .animation(.easeInOut(duration: 0.15), value: isPlayingThisSurah)
    }
}
#endif

private struct TafsirMarkdownView: View {
    let markdown: String
    let searchText: String
    let accent: Color
    /// Text/line alignment for the rendered blocks. Pass `.trailing` for Arabic so it reads right-to-left.
    var textAlignment: TextAlignment = .leading
    /// Index of the find-in-page "current" match in document order. It gets a background box, and the
    /// text view scrolls it into view - the sheet no longer drives that through a `ScrollViewProxy`,
    /// because with one text container there are no per-block view ids left to scroll to.
    var currentMatchIndex: Int? = nil

    @Environment(\.sizeCategory) private var sizeCategory

    private var frameAlignment: Alignment {
        switch textAlignment {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }

    private var stackAlignment: HorizontalAlignment {
        switch textAlignment {
        case .leading:  return .leading
        case .center:   return .center
        case .trailing: return .trailing
        }
    }

    /// The text views draw their own paragraphs, so the SwiftUI `.multilineTextAlignment` below no
    /// longer reaches the text - the same choice has to be handed to the paragraph style. `.natural`
    /// rather than `.left` for leading, so Arabic tafsir laid out leading still reads correctly.
    private var nsTextAlignment: NSTextAlignment {
        switch textAlignment {
        case .leading:  return .natural
        case .center:   return .center
        case .trailing: return .right
        }
    }

    private var blocks: [TafsirMarkdownBlock] { Self.blocks(from: markdown) }

    static func normalizedMarkdown(_ markdown: String) -> String {
        markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(
                of: #"(?m)^\\-\s+"#,
                with: "- ",
                options: .regularExpression
            )
    }

    /// Parsed blocks per tafsir text. `blocks` is read from `body` (and from search recomputes), which
    /// SwiftUI re-evaluates on every keystroke of the find bar - without this cache each evaluation re-ran a
    /// whole-document regex plus a split/trim/parse of every block, which is exactly the tafsir-sheet lag.
    private static let blocksCache: NSCache<NSString, TafsirBlocksBox> = {
        let cache = NSCache<NSString, TafsirBlocksBox>()
        cache.countLimit = 12
        return cache
    }()

    static func blocks(from markdown: String) -> [TafsirMarkdownBlock] {
        let key = markdown as NSString
        if let hit = blocksCache.object(forKey: key) {
            return hit.value
        }
        let parsed = normalizedMarkdown(markdown)
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map(TafsirMarkdownBlock.init(raw:))
        blocksCache.setObject(TafsirBlocksBox(parsed), forKey: key)
        return parsed
    }

    /// The whole entry as ONE attributed string, plus the ordered ranges of the search matches in it.
    ///
    /// Joining the blocks is the entire point of this type now. Selection on iOS can only ever span a
    /// single text container - a drag that starts in one text view has no notion of the next one - so
    /// rendering a paragraph per view capped every selection at one paragraph. Apple News reads as one
    /// continuous document because it IS one: headings are runs with a heavier font and paragraph breaks
    /// are `paragraphSpacing`, not gaps between views. Same here, so a drag now runs from a heading
    /// through the paragraphs beneath it.
    ///
    /// Matches are found on the RENDERED text, not on the raw markdown. That also fixes a quiet bug in
    /// the old per-block highlighter: it searched `displayText` (with the `**` markers still in) and then
    /// applied those offsets to the PARSED string, which has the markers stripped - so in any block
    /// containing bold, every highlight after it landed a couple of characters to the left.
    static func document(
        markdown: String,
        searchText: String,
        accent: Color,
        alignment: NSTextAlignment,
        currentMatchIndex: Int?
    ) -> (text: NSAttributedString, currentRange: NSRange?) {
        let base = baseDocument(markdown: markdown, alignment: alignment)
        let ranges = matchRanges(in: base.string, query: searchText)
        guard !ranges.isEmpty else { return (base, nil) }

        let highlighted = NSMutableAttributedString(attributedString: base)
        let accentColor = UIColor(accent)
        for range in ranges {
            highlighted.addAttribute(.foregroundColor, value: accentColor, range: range)
        }
        // The find bar's "current" hit also gets a soft box, so the up/down arrows are followable.
        var currentRange: NSRange?
        if let index = currentMatchIndex, ranges.indices.contains(index) {
            currentRange = ranges[index]
            highlighted.addAttribute(.backgroundColor, value: accentColor.withAlphaComponent(0.25), range: ranges[index])
        }
        return (highlighted, currentRange)
    }

    /// How many matches the find bar should report. Counted on the same rendered text `document` uses, so
    /// the count and the highlights can never disagree.
    static func matchCount(markdown: String, query: String) -> Int {
        matchRanges(in: baseDocument(markdown: markdown, alignment: .natural).string, query: query).count
    }

    private static func matchRanges(in text: String, query: String) -> [NSRange] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var ranges: [NSRange] = []
        let nsText = text as NSString
        var searchStart = 0
        while searchStart < nsText.length {
            let found = nsText.range(
                of: trimmed,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: NSRange(location: searchStart, length: nsText.length - searchStart)
            )
            guard found.location != NSNotFound else { break }
            ranges.append(found)
            searchStart = found.location + max(1, found.length)
        }
        return ranges
    }

    /// The unhighlighted document. Cached because find-in-page rebuilds this on every keystroke, and the
    /// markdown parse plus the run walk over ~76 blocks is the expensive half - only the cheap highlight
    /// pass above should run per character typed.
    private static let documentCache: NSCache<NSString, TafsirDocumentBox> = {
        let cache = NSCache<NSString, TafsirDocumentBox>()
        cache.countLimit = 8
        return cache
    }()

    private static func baseDocument(markdown: String, alignment: NSTextAlignment) -> NSAttributedString {
        let bodyFont = UIFont.roundedSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
        let headingFont = UIFont.roundedSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize,
            weight: .bold
        )
        // Keyed on the resolved type size too: the fonts are baked into the document here, so a Dynamic
        // Type change has to miss the cache rather than be served one set at the old size.
        let key = "\(alignment.rawValue)|\(bodyFont.pointSize)|\(markdown)" as NSString
        if let hit = documentCache.object(forKey: key) { return hit.value }

        let document = NSMutableAttributedString()
        for block in blocks(from: markdown) {
            let isHeading = block.kind == .heading
            let font = isHeading ? headingFont : bodyFont

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = alignment
            paragraph.lineSpacing = isHeading ? 2 : 5
            // What used to be the VStack's 14pt spacing, now carried by the text itself.
            paragraph.paragraphSpacing = 14
            if isHeading, document.length > 0 { paragraph.paragraphSpacingBefore = 6 }

            let attributed: AttributedString = isHeading
                ? block.highlightedDisplayText(searchText: "", accent: .primary)
                : (block.attributedText(searchText: "", accent: .primary) ?? AttributedString(block.displayText))

            if document.length > 0 {
                document.append(NSAttributedString(string: "\n", attributes: [
                    .font: font,
                    .paragraphStyle: paragraph,
                ]))
            }
            document.append(.selectableProse(
                attributed,
                baseFont: font,
                baseColor: .label,
                paragraph: paragraph
            ))
        }

        documentCache.setObject(TafsirDocumentBox(document), forKey: key)
        return document
    }

    var body: some View {
        let document = Self.document(
            markdown: markdown,
            searchText: searchText,
            accent: accent,
            alignment: nsTextAlignment,
            currentMatchIndex: currentMatchIndex
        )

        return SelectableTextView(attributed: document.text, scrollTarget: document.currentRange)
            // The fonts are resolved into the document above, so a type-size change must rebuild it.
            .id(sizeCategory)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }
}

/// NSCache holds objects, so the built document rides in a box (same shape as `TafsirBlocksBox`).
private final class TafsirDocumentBox {
    let value: NSAttributedString
    init(_ value: NSAttributedString) { self.value = value }
}

private final class TafsirBlocksBox {
    let value: [TafsirMarkdownBlock]
    init(_ value: [TafsirMarkdownBlock]) { self.value = value }
}

private final class TafsirAttributedBox {
    let value: AttributedString
    init(_ value: AttributedString) { self.value = value }
}

private struct TafsirMarkdownBlock {
    enum Kind {
        case heading
        case body
    }

    let kind: Kind
    let rawText: String
    /// Computed once at init - this used to be a computed var running a regex on EVERY access, and it is
    /// accessed several times per block per render.
    let displayText: String

    init(raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("## ") {
            kind = .heading
            rawText = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if trimmed.hasPrefix("# ") {
            kind = .heading
            rawText = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            kind = .body
            rawText = trimmed
        }
        displayText = rawText.replacingOccurrences(of: #"\\-"#, with: "-", options: .regularExpression)
    }

    /// The markdown parse is the expensive part (AttributedString(markdown:) on every block of a long Ibn
    /// Kathir entry), and it doesn't depend on the search state - so parse each block once, cache it, and
    /// apply the (cheap) search highlight to a value-copy per render.
    private static let baseParseCache: NSCache<NSString, TafsirAttributedBox> = {
        let cache = NSCache<NSString, TafsirAttributedBox>()
        cache.countLimit = 400
        return cache
    }()

    private func baseAttributed() -> AttributedString? {
        guard kind == .body else { return nil }
        let key = displayText as NSString
        if let hit = Self.baseParseCache.object(forKey: key) {
            return hit.value
        }
        guard var attributed = try? AttributedString(markdown: displayText) else { return nil }
        for run in attributed.runs {
            if let intent = run.inlinePresentationIntent, intent.contains(.code) {
                attributed[run.range].inlinePresentationIntent = nil
            }
        }
        Self.baseParseCache.setObject(TafsirAttributedBox(attributed), forKey: key)
        return attributed
    }

    func attributedText(searchText: String, accent: Color, currentOccurrence: Int? = nil) -> AttributedString? {
        guard var attributed = baseAttributed() else { return nil }
        applySearchHighlight(to: &attributed, searchText: searchText, accent: accent, currentOccurrence: currentOccurrence)
        return attributed
    }

    func highlightedDisplayText(searchText: String, accent: Color, currentOccurrence: Int? = nil) -> AttributedString {
        var attributed = AttributedString(displayText)
        applySearchHighlight(to: &attributed, searchText: searchText, accent: accent, currentOccurrence: currentOccurrence)
        return attributed
    }

    private func applySearchHighlight(to attributed: inout AttributedString, searchText: String, accent: Color, currentOccurrence: Int?) {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var searchStart = displayText.startIndex
        var occurrence = 0
        while searchStart < displayText.endIndex,
              let found = displayText.range(
                of: trimmed,
                options: [.caseInsensitive, .diacriticInsensitive],
                range: searchStart..<displayText.endIndex
              ) {
            if let lower = AttributedString.Index(found.lowerBound, within: attributed),
               let upper = AttributedString.Index(found.upperBound, within: attributed) {
                // Tint every match with the accent foreground; the find-in-page "current" match also gets a
                // soft background box so the user can see which hit the up/down arrows landed on.
                attributed[lower..<upper].foregroundColor = accent
                if occurrence == currentOccurrence {
                    attributed[lower..<upper].backgroundColor = accent.opacity(0.25)
                }
            }
            occurrence += 1
            searchStart = found.upperBound
        }
    }
}

/// Find-in-page control bar: "current/total" plus up/down arrows, styled to match the app. Shown over the
/// Tafsir / Surah Info sheets while a search query is active.
private struct TafsirFindBar: View {
    @ObservedObject var settings = Settings.shared

    let current: Int   // 0-based index of the active match
    let total: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 18) {
            Text(total == 0 ? "0/0" : "\(current + 1)/\(total)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(total == 0 ? .secondary : .primary)

            Button {
                settings.hapticFeedback()
                onPrevious()
            } label: {
                Image(systemName: "chevron.up")
                    .font(.body.weight(.semibold))
            }
            .disabled(total == 0)

            Button {
                settings.hapticFeedback()
                onNext()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.body.weight(.semibold))
            }
            .disabled(total == 0)
        }
        .foregroundStyle(settings.accentColor.color)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .conditionalGlassEffect(rectangle: true)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#endif
