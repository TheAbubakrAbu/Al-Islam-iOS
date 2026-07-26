import SwiftUI

#if os(iOS)

@MainActor
final class AyahTafsirViewModel: ObservableObject {
    @Published private(set) var tafsirs: [AyahTafsirEntry] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    /// Arabic editions load one at a time, on selection - separate flags so an Arabic fetch never swaps the
    /// whole sheet into the loading skeleton.
    @Published private(set) var isLoadingArabic = false
    @Published var arabicErrorMessage: String?

    private let surah: Int
    private let ayah: Int
    private var loadedKey: String?
    private var loadedArabicSlugs: Set<String> = []

    /// Session-wide rehydration cache: if SwiftUI ever recreates the sheet's StateObject mid-read, the
    /// new instance restores the SAME content synchronously in init - no reload, no skeleton flash, no
    /// "the whole page redid itself". Keyed by surah:ayah; small and main-actor confined.
    @MainActor private static var sessionCache: [String: (tafsirs: [AyahTafsirEntry], arabicSlugs: Set<String>)] = [:]

    init(surah: Int, ayah: Int) {
        self.surah = surah
        self.ayah = ayah
        let key = "\(surah)-\(ayah)"
        if let cached = Self.sessionCache[key] {
            tafsirs = cached.tafsirs
            loadedArabicSlugs = cached.arabicSlugs
            loadedKey = key
        }
    }

    private func updateSessionCache() {
        let key = "\(surah)-\(ayah)"
        Self.sessionCache[key] = (tafsirs, loadedArabicSlugs)
        // A handful of ayahs is all a reading session touches; keep the cache tiny.
        if Self.sessionCache.count > 8 {
            Self.sessionCache.remove(at: Self.sessionCache.indices.first!)
        }
    }

    func loadIfNeeded() async {
        await load(surah: surah, ayah: ayah)
    }

    func hasEntry(for author: TafsirAuthor) -> Bool {
        tafsirs.contains { author.matches($0.author) }
    }

    /// Fetch one Arabic edition's tafsir for this ayah (cache-first via TafsirStore) and append it to
    /// `tafsirs` under the author's rawValue, so the existing selection/matching machinery just works.
    func loadArabicIfNeeded(_ author: TafsirAuthor) async {
        guard let slug = author.arabicSlug,
              !loadedArabicSlugs.contains(slug),
              !isLoadingArabic else { return }

        isLoadingArabic = true
        arabicErrorMessage = nil

        do {
            // Unstructured Task: the page reader rebuilds its hosting view mid-flight, which cancels the
            // sheet's `.task` - without this wrapper that cancellation reached into URLSession and every
            // page-mode tafsir died with "Cancelled". The fetch now survives the view churn.
            let surah = self.surah, ayah = self.ayah
            let data = try await Task { try await TafsirStore.shared.data(editionSlug: slug, surah: surah, ayah: ayah) }.value
            let decoded = try JSONDecoder().decode(SpaTafsirAyahResponse.self, from: data)
            let text = decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty {
                tafsirs.append(AyahTafsirEntry(author: author.rawValue, groupVerse: nil, content: text))
            }
            loadedArabicSlugs.insert(slug)
            updateSessionCache()
        } catch {
            // Cancellation is view-lifecycle noise, not a failure - the next `.task` run retries silently.
            if !Self.isCancellation(error) {
                arabicErrorMessage = error.localizedDescription
            }
        }

        isLoadingArabic = false
    }

    /// True for the errors a torn-down SwiftUI task produces - never worth showing to the reader.
    static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        if let urlError = error as? URLError, urlError.code == .cancelled { return true }
        return (error as NSError).code == NSURLErrorCancelled
    }

    func load(surah: Int, ayah: Int) async {
        let key = "\(surah)-\(ayah)"
        if loadedKey == key, !tafsirs.isEmpty { return }
        if isLoading { return }

        isLoading = true
        errorMessage = nil

        do {
            // Cache-first through the shared store: an ayah whose tafsir was ever fetched (or bulk-downloaded)
            // loads instantly and offline; only a true first look hits the network. The unstructured Task
            // insulates the fetch from the page reader cancelling the sheet's `.task` mid-flight.
            let data = try await Task { try await TafsirStore.shared.data(surah: surah, ayah: ayah) }.value
            let decoded = try JSONDecoder().decode(AyahTafsirResponse.self, from: data)
            tafsirs = decoded.tafsirs
            loadedKey = key
            updateSessionCache()
        } catch {
            if !Self.isCancellation(error) {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}

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
    @State private var searchMatches: [(block: Int, occurrence: Int)] = []
    @State private var currentMatchIndex = 0
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

    private var loadKey: String {
        "\(surahNumber):\(ayahNumber)"
    }

    private var selectedTafsirEntry: AyahTafsirEntry? {
        if let match = viewModel.tafsirs.first(where: { selectedAuthor.matches($0.author) }) {
            return match
        }
        // An Arabic edition that hasn't loaded yet shows its own loading row - falling back to an English
        // entry here would flash the wrong tafsir under an Arabic heading.
        return selectedAuthor.isArabic ? nil : viewModel.tafsirs.first
    }

    private var selectedTafsirText: String? {
        selectedTafsirEntry?.content
    }

    private var hasActiveSearch: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var currentMatch: (block: Int, occurrence: Int)? {
        searchMatches.indices.contains(currentMatchIndex) ? searchMatches[currentMatchIndex] : nil
    }

    private func recomputeMatches(scrollProxy: ScrollViewProxy?) {
        searchMatches = TafsirMarkdownView.searchMatches(markdown: selectedTafsirText ?? "", query: searchText)
        currentMatchIndex = 0
        if let scrollProxy, let first = searchMatches.first {
            scrollToMatch(first, proxy: scrollProxy)
        }
    }

    private func goToMatch(_ delta: Int, proxy: ScrollViewProxy) {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + delta + searchMatches.count) % searchMatches.count
        scrollToMatch(searchMatches[currentMatchIndex], proxy: proxy)
    }

    private func scrollToMatch(_ match: (block: Int, occurrence: Int), proxy: ScrollViewProxy) {
        withAnimation { proxy.scrollTo(tafsirBlockScrollID(match.block), anchor: .center) }
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
        return settings.beginnerMode ? text.map { String($0) }.joined(separator: " ") : text
    }

    /// Tajweed-colored attributed text for the card, when tajweed is on and the display is Hafs.
    private func tafsirTajweedText(_ ayah: Ayah) -> AttributedString? {
        guard settings.showTajweedColors, settings.showArabicText, settings.isHafsDisplay else { return nil }
        let text = ayah.displayArabicText(surahId: surahNumber, clean: false)
        let displayText = settings.cleanArabicText ? ayah.displayArabicText(surahId: surahNumber, clean: true) : text
        let rendered = settings.beginnerMode ? displayText.map { String($0) }.joined(separator: " ") : displayText
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
            tafsirAyahRange.contains($0.id) && $0.existsInQiraah(settings.displayQiraahForArabic)
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
                            } else if selectedAuthor.isArabic, viewModel.isLoadingArabic {
                                ProgressView("Loading tafsir...")
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 12)
                            } else if selectedAuthor.isArabic, let arabicError = viewModel.arabicErrorMessage {
                                tafsirPlaceholder(
                                    title: "Couldn't Load Tafsir",
                                    systemImage: "wifi.exclamationmark",
                                    message: arabicError
                                )
                            } else if let errorMessage = viewModel.errorMessage, !selectedAuthor.isArabic {
                                tafsirPlaceholder(
                                    title: "Couldn't Load Tafsir",
                                    systemImage: "wifi.exclamationmark",
                                    message: errorMessage
                                )
                            } else {
                                tafsirPlaceholder(
                                    title: "No Tafsir Found",
                                    systemImage: "text.book.closed",
                                    message: "No tafsir was returned for this ayah."
                                )
                            }
                        }
                        .padding()
                    }
                    .safeAreaInset(edge: .bottom) {
                        if hasActiveSearch {
                            TafsirFindBar(
                                current: currentMatchIndex,
                                total: searchMatches.count,
                                onPrevious: { goToMatch(-1, proxy: proxy) },
                                onNext: { goToMatch(1, proxy: proxy) }
                            )
                        }
                    }
                    .onChange(of: searchText) { _ in recomputeMatches(scrollProxy: proxy) }
                    .onChange(of: selectedTafsirText) { _ in recomputeMatches(scrollProxy: nil) }
                    }
                    // The loading skeleton OVERLAYS the always-mounted scroll content instead of
                    // replacing it - swapping the branch reset the ScrollView's identity (and with it
                    // the reader's place) whenever the state flipped.
                    .overlay {
                        if viewModel.isLoading && viewModel.tafsirs.isEmpty {
                            tafsirLoadingView
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(UIColor.systemBackground))
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut, value: viewModel.isLoading)
            }
            // Title reflects the tafsir's FULL range: when the selected tafsir groups several ayahs (Ibn
            // Kathir often does) it reads e.g. "Al-Baqarah 1:1-5", not just the tapped ayah.
            .navigationTitle(ayahSheetTitle(surahNumber: surahNumber, ayahNumber: tafsirAyahRange.lowerBound, endAyah: tafsirAyahRange.upperBound))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText.animation(.easeInOut), prompt: "Search tafsir")
            .dismissKeyboardOnScroll()
            .sheetDismissToolbar()
        }
        .task(id: loadKey) {
            await viewModel.loadIfNeeded()
        }
        // The Arabic editions load one at a time, when selected (each is its own per-ayah file on the CDN).
        .task(id: "\(loadKey)|\(selectedAuthorRawValue)") {
            if selectedAuthor.isArabic {
                await viewModel.loadArabicIfNeeded(selectedAuthor)
            }
        }
    }

    private var noticeCard: some View {
        OnlineNoticeCard(text: "Tafsir is fetched online for the selected ayah or grouped ayahs, then saved on this device - an ayah you've opened before loads instantly and offline. English tafsirs load together; Arabic tafsirs (Ibn Kathir, al-Tabari, as-Sa'di) load per selection.")
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
                    return tafsirArabicAyahs.count > 1 ? "(\(ayah.id)) \(text)" : text
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
            currentMatch: currentMatch
        )
    }

    private var tafsirLoadingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                noticeCard

                ProgressView("Loading tafsir...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.18))
                    .frame(height: 32)
                    .overlay {
                        HStack(spacing: 8) {
                            Capsule().fill(Color.secondary.opacity(0.18))
                            Capsule().fill(Color.secondary.opacity(0.12))
                            Capsule().fill(Color.secondary.opacity(0.1))
                        }
                        .padding(4)
                    }

                ForEach(0..<4, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.16))
                            .frame(width: index == 0 ? 180 : 240, height: index == 0 ? 24 : 16)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.12))
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.09))
                            .frame(width: index.isMultiple(of: 2) ? 260 : 220, height: 16)
                    }
                    .redacted(reason: .placeholder)
                }
            }
            .padding()
        }
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
    @State private var searchMatches: [(block: Int, occurrence: Int)] = []
    @State private var currentMatchIndex = 0
    @AppStorage("quran.surahInfo.source") private var selectedSourceName = ""

    private var sources: [SurahInfoSource] {
        quranData.surahInfoSources(for: surahNumber)
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

    private var currentMatch: (block: Int, occurrence: Int)? {
        searchMatches.indices.contains(currentMatchIndex) ? searchMatches[currentMatchIndex] : nil
    }

    private func recomputeMatches(scrollProxy: ScrollViewProxy?) {
        searchMatches = TafsirMarkdownView.searchMatches(markdown: selectedSource?.contents ?? "", query: searchText)
        currentMatchIndex = 0
        if let scrollProxy, let first = searchMatches.first {
            scrollToMatch(first, proxy: scrollProxy)
        }
    }

    private func goToMatch(_ delta: Int, proxy: ScrollViewProxy) {
        guard !searchMatches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + delta + searchMatches.count) % searchMatches.count
        scrollToMatch(searchMatches[currentMatchIndex], proxy: proxy)
    }

    private func scrollToMatch(_ match: (block: Int, occurrence: Int), proxy: ScrollViewProxy) {
        withAnimation { proxy.scrollTo(tafsirBlockScrollID(match.block), anchor: .center) }
    }

    var body: some View {
        NavigationView {
            Group {
                if sources.isEmpty {
                    infoPlaceholder
                } else {
                    ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            noticeCard
                            surahHeaderCard

                            // Listen from here: the page-mode header opens this sheet, so "play this
                            // surah" (once or on repeat) belongs right under the surah's own card.
                            #if os(iOS)
                            if settings.isHafsDisplay {
                                SurahInfoPlaybackCard(surahNumber: surahNumber, surahName: surahName)
                            }
                            #endif

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
                                        currentMatch: currentMatch
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
                                total: searchMatches.count,
                                onPrevious: { goToMatch(-1, proxy: proxy) },
                                onNext: { goToMatch(1, proxy: proxy) }
                            )
                        }
                    }
                    .onChange(of: searchText) { _ in recomputeMatches(scrollProxy: proxy) }
                    .onChange(of: selectedSourceName) { _ in recomputeMatches(scrollProxy: nil) }
                    }
                }
            }
            .navigationTitle("Surah \(surahNumber): \(surahName)")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText.animation(.easeInOut), prompt: "Search info")
            .dismissKeyboardOnScroll()
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
        }
        .modifier(SheetPresentationModifier())
    }

    private var noticeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("About this Surah", systemImage: "book.closed")
                .font(.subheadline.weight(.semibold))

            Text("Background on this surah - its name, period of revelation, and themes. Switch between sources with the picker.")
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

/// Stable scroll id for the Nth render block of a `TafsirMarkdownView` (used by find-in-page navigation).
private func tafsirBlockScrollID(_ offset: Int) -> String { "tafsir-block-\(offset)" }

private struct TafsirMarkdownView: View {
    let markdown: String
    let searchText: String
    let accent: Color
    /// Text/line alignment for the rendered blocks. Pass `.trailing` for Arabic so it reads right-to-left.
    var textAlignment: TextAlignment = .leading
    /// The find-in-page "current" match as (render-block offset, occurrence index within that block); the
    /// matching occurrence gets a background box so the user can see which hit they're on.
    var currentMatch: (block: Int, occurrence: Int)? = nil

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

    /// Document-order list of search matches, each as (render-block offset, occurrence index within block).
    /// Counting on the same `displayText` the highlighter searches keeps the count and the highlights in sync.
    static func searchMatches(markdown: String, query: String) -> [(block: Int, occurrence: Int)] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var matches: [(block: Int, occurrence: Int)] = []
        for (offset, block) in blocks(from: markdown).enumerated() {
            let text = block.displayText
            var start = text.startIndex
            var occurrence = 0
            while start < text.endIndex,
                  let found = text.range(
                    of: trimmed,
                    options: [.caseInsensitive, .diacriticInsensitive],
                    range: start..<text.endIndex
                  ) {
                matches.append((offset, occurrence))
                occurrence += 1
                start = found.upperBound
            }
        }
        return matches
    }

    var body: some View {
        VStack(alignment: stackAlignment, spacing: 14) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { item in
                let offset = item.offset
                let block = item.element
                let currentOccurrence = currentMatch?.block == offset ? currentMatch?.occurrence : nil

                Group {
                    switch block.kind {
                    case .heading:
                        Text(block.highlightedDisplayText(searchText: searchText, accent: accent, currentOccurrence: currentOccurrence))
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: frameAlignment)
                    case .body:
                        if let attributed = block.attributedText(searchText: searchText, accent: accent, currentOccurrence: currentOccurrence) {
                            Text(attributed)
                                .frame(maxWidth: .infinity, alignment: frameAlignment)
                                .textSelection(.enabled)
                                .lineSpacing(5)
                        } else {
                            Text(block.displayText)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: frameAlignment)
                                .textSelection(.enabled)
                                .lineSpacing(5)
                        }
                    }
                }
                .id(tafsirBlockScrollID(offset))
            }
        }
        .frame(maxWidth: .infinity, alignment: frameAlignment)
        .multilineTextAlignment(textAlignment)
        .textSelection(.enabled)
    }
}

/// Class boxes so parsed value-type results can live in an NSCache.
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
