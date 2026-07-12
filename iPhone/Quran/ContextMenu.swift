import SwiftUI

struct SurahContextMenu: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @ObservedObject var quranPlayer = QuranPlayer.shared

    let surahID: Int
    let surahName: String

    let favoriteSurahs: Set<Int>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    var lastListened: Bool?

    private var isFavorite: Bool {
        favoriteSurahs.contains(surahID)
    }

    private var canAddToQueue: Bool {
        quranPlayer.isPlaying || quranPlayer.isPaused
    }

    var body: some View {
        #if os(iOS)
        if let surah = quranData.surah(surahID) {
            Button {
                settings.hapticFeedback()
                FocusOverlayPresenter.shared.present(.surah(surah))
            } label: {
                Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
            }

            Button {
                settings.hapticFeedback()
                presentSystemShareSheet(items: [FocusItem.surah(surah).shareText])
            } label: {
                Label("Share Surah", systemImage: "square.and.arrow.up")
            }

            Divider()
        }
        #endif

        Button(role: isFavorite ? .destructive : .cancel) {
            settings.hapticFeedback()
            withAnimation(.easeInOut) {
                settings.toggleSurahFavorite(surah: surahID)
            }
        } label: {
            Label(
                isFavorite ? "Unfavorite Surah" : "Favorite Surah",
                systemImage: isFavorite ? "star.fill" : "star"
            )
        }

        Button {
            settings.hapticFeedback()

            if let surah = quranData.surah(surahID) {
                if let randomAyah = surah.ayahs.randomElement() {
                    quranPlayer.playAyah(
                        surahNumber: surahID,
                        ayahNumber: randomAyah.id,
                        continueRecitation: true
                    )
                }
            }
        } label: {
            Label("Play Random Ayah", systemImage: "shuffle.circle")
        }

        if lastListened == nil {
            Button {
                settings.hapticFeedback()

                quranPlayer.playSurah(surahNumber: surahID, surahName: surahName)
            } label: {
                Label("Play Surah", systemImage: "play.fill")
            }
        }

        if canAddToQueue {
            Button {
                settings.hapticFeedback()
                quranPlayer.addSurahToQueue(surahNumber: surahID, surahName: surahName)
            } label: {
                Label("Add to Queue", systemImage: "text.line.last.and.arrowtriangle.forward")
            }
        }

        Button {
            settings.hapticFeedback()

            withAnimation {
                searchText = ""
                scrollToSurahID = surahID
                self.endEditing()
            }
        } label: {
            Text("Scroll To Surah")
            Image(systemName: "arrow.down.circle")
        }
    }
}

#if os(iOS)
private enum TafsirAuthor: String, CaseIterable, Identifiable {
    case ibnKathir = "Ibn Kathir"
    case maarifUlQuran = "Maarif Ul Quran"
    case tazkirulQuran = "Tazkirul Quran"

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .ibnKathir:
            return "Ibn Kathir"
        case .maarifUlQuran:
            return "Maarif"
        case .tazkirulQuran:
            return "Tazkirul"
        }
    }

    func matches(_ author: String) -> Bool {
        normalized(author) == normalized(rawValue)
    }

    private func normalized(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

private struct AyahTafsirResponse: Decodable {
    let surahName: String
    let surahNo: Int
    let ayahNo: Int
    let tafsirs: [AyahTafsirEntry]
}

private struct AyahTafsirEntry: Decodable, Identifiable {
    let author: String
    let groupVerse: String?
    let content: String

    var id: String { author }
}

@MainActor
private final class AyahTafsirViewModel: ObservableObject {
    @Published private(set) var tafsirs: [AyahTafsirEntry] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let surah: Int
    private let ayah: Int
    private var loadedKey: String?
    private var loadTask: Task<Void, Never>?

    init(surah: Int, ayah: Int) {
        self.surah = surah
        self.ayah = ayah
    }

    deinit {
        loadTask?.cancel()
    }

    func loadIfNeeded() async {
        await load(surah: surah, ayah: ayah)
    }

    func load(surah: Int, ayah: Int) async {
        let key = "\(surah)-\(ayah)"
        if loadedKey == key, !tafsirs.isEmpty { return }
        if isLoading { return }

        isLoading = true
        errorMessage = nil

        do {
            let endpoint = "https://quranapi.pages.dev/api/tafsir/\(surah)_\(ayah).json"
            guard let url = URL(string: endpoint) else {
                throw URLError(.badURL)
            }

            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(AyahTafsirResponse.self, from: data)
            tafsirs = decoded.tafsirs
            loadedKey = key
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct AyahTafsirSheet: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
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

    private var loadKey: String {
        "\(surahNumber):\(ayahNumber)"
    }

    private var selectedTafsirEntry: AyahTafsirEntry? {
        viewModel.tafsirs.first(where: { selectedAuthor.matches($0.author) }) ?? viewModel.tafsirs.first
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

    private var tafsirAyahRange: ClosedRange<Int> {
        parsedAyahRange(from: selectedTafsirEntry?.groupVerse) ?? ayahNumber...ayahNumber
    }

    private var tafsirArabicAyahs: [Ayah] {
        quranData.surah(surahNumber)?.ayahs.filter {
            tafsirAyahRange.contains($0.id) && $0.existsInQiraah(settings.displayQiraahForArabic)
        } ?? []
    }

    private var tafsirRangeTitle: String {
        tafsirAyahRange.lowerBound == tafsirAyahRange.upperBound
            ? "Ayah \(tafsirAyahRange.lowerBound)"
            : "Ayahs \(tafsirAyahRange.lowerBound)-\(tafsirAyahRange.upperBound)"
    }

    private func parsedAyahRange(from groupVerse: String?) -> ClosedRange<Int>? {
        guard let groupVerse else { return nil }
        let trimmed = groupVerse.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let versePortion = trimmed.split(separator: ":").last.map(String.init) ?? trimmed
        let numbers = versePortion
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }

        guard let first = numbers.first else { return nil }
        let second = numbers.dropFirst().first ?? first
        let lower = min(first, second)
        let upper = max(first, second)
        let maxAyah = quranData.surah(surahNumber)?.numberOfAyahs(for: settings.displayQiraahForArabic) ?? upper
        let clampedLower = min(max(lower, 1), maxAyah)
        let clampedUpper = min(max(upper, clampedLower), maxAyah)
        return clampedLower...clampedUpper
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.tafsirs.isEmpty {
                    tafsirLoadingView
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            noticeCard
                            arabicAyahsCard

                            Picker("Tafsir", selection: selectedAuthorBinding.animation(.easeInOut)) {
                                ForEach(TafsirAuthor.allCases) { author in
                                    Text(author.shortTitle).tag(author)
                                }
                            }
                            .pickerStyle(.segmented)
                            .animation(.easeInOut, value: selectedAuthor)
                            .onChange(of: selectedAuthor) { _ in settings.hapticFeedback() }

                            if let tafsirText = selectedTafsirText {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(selectedAuthor.rawValue)
                                        .font(.headline)

                                    tafsirContentView(for: tafsirText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(selectedAuthor.rawValue)
                                .textSelection(.enabled)
                            } else if let errorMessage = viewModel.errorMessage {
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
                }
            }
            .navigationTitle("\(surahName) \(surahNumber):\(ayahNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText.animation(.easeInOut), prompt: "Search tafsir")
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
        .modifier(TafsirSheetPresentationModifier())
        .task(id: loadKey) {
            await viewModel.loadIfNeeded()
        }
    }

    private var noticeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Loaded from the Internet", systemImage: "icloud.and.arrow.down")
                .font(.subheadline.weight(.semibold))

            Text("Tafsir is fetched online for the selected ayah or grouped ayahs. The app loads all 3 available tafsirs together, then you can switch between them with the picker.")
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

    private var arabicAyahsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tafsirRangeTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            if tafsirArabicAyahs.isEmpty {
                Text("Arabic ayah unavailable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .trailing, spacing: 10) {
                    ForEach(tafsirArabicAyahs) { ayah in
                        Text(ayah.displayArabicText(surahId: surahNumber, clean: settings.cleanArabicText, qiraahOverride: settings.displayQiraahForArabic))
                            .font(
                                settings.useFontArabic
                                    ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title3).pointSize)
                                    : .title3
                            )
                            .arabicFontDesign(custom: settings.islamUsesCustomArabicFace)
                            .multilineTextAlignment(.trailing)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
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
        .animation(.easeInOut, value: tafsirRangeTitle)
    }

    @ViewBuilder
    private func tafsirContentView(for content: String) -> some View {
        TafsirMarkdownView(markdown: content, searchText: searchText, accent: settings.accentColor.color, currentMatch: currentMatch)
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

    static func blocks(from markdown: String) -> [TafsirMarkdownBlock] {
        normalizedMarkdown(markdown)
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map(TafsirMarkdownBlock.init(raw:))
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

private struct TafsirMarkdownBlock {
    enum Kind {
        case heading
        case body
    }

    let kind: Kind
    let rawText: String

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
    }

    var displayText: String {
        rawText.replacingOccurrences(of: #"\\-"#, with: "-", options: .regularExpression)
    }

    func attributedText(searchText: String, accent: Color, currentOccurrence: Int? = nil) -> AttributedString? {
        guard kind == .body else { return nil }
        guard var attributed = try? AttributedString(markdown: displayText) else { return nil }
        for run in attributed.runs {
            if let intent = run.inlinePresentationIntent, intent.contains(.code) {
                attributed[run.range].inlinePresentationIntent = nil
            }
        }
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

private struct TafsirSheetPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}

struct AyahQiraahComparisonSheet: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahNumber: Int
    let ayahNumber: Int
    @State private var searchText = ""


    private struct QiraahDisplay: Identifiable {
        let label: String
        let tag: String
        let arabicCaption: String
        let teacher: String
        let teacherArabic: String
        let order: Int

        var id: String { tag.isEmpty ? "Hafs" : tag }
    }

    private var options: [QiraahDisplay] {
        Settings.Riwayah.options.map {
            QiraahDisplay(
                label: $0.label,
                tag: $0.tag,
                arabicCaption: $0.arabic,
                teacher: $0.teacher,
                teacherArabic: $0.teacherArabic,
                order: $0.order
            )
        }
    }

    private var favoriteOptions: [QiraahDisplay] {
        filteredOptions.filter { settings.isQiraahFavorite(tag: $0.tag) }
            .sorted { $0.order < $1.order }
    }

    private var groupedOptions: [(teacher: String, teacherArabic: String, options: [QiraahDisplay])] {
        Settings.Riwayah.groups.compactMap { group in
            let rows = filteredOptions
                .filter { $0.teacher == group.teacher && !settings.isQiraahFavorite(tag: $0.tag) }
                .sorted { $0.order < $1.order }
            guard !rows.isEmpty else { return nil }
            return (group.teacher, group.teacherArabic, rows)
        }
    }

    private var filteredOptions: [QiraahDisplay] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return options }
        return options.filter { option in
            option.label.localizedCaseInsensitiveContains(query) ||
            option.arabicCaption.localizedCaseInsensitiveContains(query) ||
            option.teacher.localizedCaseInsensitiveContains(query) ||
            option.teacherArabic.localizedCaseInsensitiveContains(query) ||
            (qiraahText(for: option)?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        NavigationView {
            List {
                Group {
                    Section {
                        Text("Compare this ayah across the Arabic riwayat available in the app. Some riwayat merge or omit Hafs ayah numbers, so unavailable rows are dimmed.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if !favoriteOptions.isEmpty {
                        Section(header: Text("FAVORITES")) {
                            ForEach(favoriteOptions) { option in
                                qiraahRow(option)
                            }
                        }
                    }

                    ForEach(groupedOptions, id: \.teacher) { group in
                        Section(header: Text("\(group.teacher.uppercased()) - \(group.teacherArabic)")) {
                            ForEach(group.options) { option in
                                qiraahRow(option)
                            }
                        }
                    }

                    if filteredOptions.isEmpty {
                        Section {
                            Text("No riwayat found.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .compactListSectionSpacing()
            .navigationTitle("Qiraah Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText.animation(.easeInOut), prompt: "Search riwayat")
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
        .modifier(TafsirSheetPresentationModifier())
    }

    private func qiraahText(for option: QiraahDisplay) -> String? {
        guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber),
              ayah.existsInQiraah(option.tag) else {
            return nil
        }
        return ayah.displayArabicText(surahId: surahNumber, clean: settings.cleanArabicText, qiraahOverride: option.tag)
    }

    private func comparisonArabicFontName(for option: QiraahDisplay) -> String {
        settings.quranArabicFontName(for: option.tag)
    }

    private func qiraahRow(_ option: QiraahDisplay) -> some View {
        let text = qiraahText(for: option)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                HStack {
                    HighlightedSnippet(
                        source: option.label,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )

                    HighlightedSnippet(
                        source: option.arabicCaption,
                        term: searchText,
                        font: .caption,
                        accent: settings.accentColor.color,
                        fg: settings.accentColor.color
                    )
                }

                Spacer()

                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.toggleQiraahFavorite(tag: option.tag)
                    }
                } label: {
                    Image(systemName: settings.isQiraahFavorite(tag: option.tag) ? "star.fill" : "star")
                        .foregroundStyle(settings.accentColor.color)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settings.isQiraahFavorite(tag: option.tag) ? "Unfavorite Riwayah" : "Favorite Riwayah")

                if text == nil {
                    Text("Unavailable")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            HighlightedSnippet(
                source: text ?? "This ayah is not separate in this riwayah.",
                term: searchText,
                font: .custom(
                    comparisonArabicFontName(for: option),
                    size: UIFont.preferredFont(forTextStyle: .title3).pointSize
                ),
                accent: settings.accentColor.color,
                fg: text == nil ? .secondary : .primary
            )
                .arabicFontDesign(custom: settings.quranUsesCustomArabicFace)
                .multilineTextAlignment(.trailing)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .opacity(text == nil ? 0.55 : 1)
        .textSelection(.enabled)
    }
}

private struct EnglishEdition: Identifiable {
    let id: String
    let name: String
}

private let inAppEnglishComparisonEditions: [EnglishEdition] = [
    EnglishEdition(id: "inapp.saheeh", name: "Saheeh International"),
    EnglishEdition(id: "inapp.mustafa", name: "Clear Quran (Mustafa Khattab)")
]

private let englishComparisonEditions: [EnglishEdition] = [
    EnglishEdition(id: "en.ahmedali", name: "Ahmed Ali"),
    EnglishEdition(id: "en.ahmedraza", name: "Ahmed Raza Khan"),
    EnglishEdition(id: "en.arberry", name: "A. J. Arberry"),
    EnglishEdition(id: "en.asad", name: "Muhammad Asad"),
    EnglishEdition(id: "en.daryabadi", name: "Abdul Majid Daryabadi"),
    EnglishEdition(id: "en.hilali", name: "Hilali & Khan"),
    EnglishEdition(id: "en.pickthall", name: "Pickthall"),
    EnglishEdition(id: "en.qaribullah", name: "Qaribullah & Darwish"),
    EnglishEdition(id: "en.sarwar", name: "Muhammad Sarwar"),
    EnglishEdition(id: "en.yusufali", name: "Yusuf Ali"),
    EnglishEdition(id: "en.maududi", name: "Abul Ala Maududi"),
    EnglishEdition(id: "en.shakir", name: "Shakir"),
    EnglishEdition(id: "en.itani", name: "Clear Quran (Talal Itani)"),
    EnglishEdition(id: "en.mubarakpuri", name: "Mubarakpuri"),
    EnglishEdition(id: "en.qarai", name: "Qarai"),
    EnglishEdition(id: "en.wahiduddin", name: "Wahiduddin Khan")
]

private struct AyahEditionResponse: Decodable {
    let data: [AyahEditionData]
}

private struct AyahEditionData: Decodable {
    let text: String
    let edition: AyahEditionMetadata
}

private struct AyahEditionMetadata: Decodable {
    let identifier: String
    let englishName: String?
}

@MainActor
private final class EnglishComparisonViewModel: ObservableObject {
    @Published private(set) var translations: [String: String] = [:]
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let surah: Int
    private let ayah: Int
    private var loadedReference: String?

    init(surah: Int, ayah: Int) {
        self.surah = surah
        self.ayah = ayah
    }

    func loadIfNeeded() async {
        await load(surah: surah, ayah: ayah)
    }

    func load(surah: Int, ayah: Int) async {
        let reference = "\(surah):\(ayah)"
        guard loadedReference != reference || translations.isEmpty else { return }
        if isLoading { return }

        isLoading = true
        errorMessage = nil

        do {
            let editions = englishComparisonEditions.map(\.id).joined(separator: ",")
            guard let url = URL(string: "https://api.alquran.cloud/v1/ayah/\(reference)/editions/\(editions)") else {
                throw URLError(.badURL)
            }

            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(AyahEditionResponse.self, from: data)
            translations = Dictionary(uniqueKeysWithValues: decoded.data.map { ($0.edition.identifier, $0.text) })
            loadedReference = reference
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct AyahEnglishComparisonSheet: View {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @Environment(\.dismiss) private var dismiss

    let surahNumber: Int
    let ayahNumber: Int

    @StateObject private var viewModel: EnglishComparisonViewModel
    @State private var searchText = ""

    init(surahNumber: Int, ayahNumber: Int) {
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        _viewModel = StateObject(wrappedValue: EnglishComparisonViewModel(surah: surahNumber, ayah: ayahNumber))
    }

    private var loadKey: String {
        "\(surahNumber):\(ayahNumber)"
    }

    private var filteredEditions: [EnglishEdition] {
        filteredOnlineEditions
    }

    private var filteredInAppEditions: [EnglishEdition] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = inAppEnglishComparisonEditions.sorted { lhs, rhs in
            let lhsFavorite = settings.isEnglishTranslationFavorite(id: lhs.id)
            let rhsFavorite = settings.isEnglishTranslationFavorite(id: rhs.id)
            if lhsFavorite != rhsFavorite { return lhsFavorite }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        guard !query.isEmpty else { return sorted }

        return sorted.filter { edition in
            edition.name.localizedCaseInsensitiveContains(query) ||
            inAppTranslationText(for: edition.id).localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredOnlineEditions: [EnglishEdition] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = englishComparisonEditions.sorted { lhs, rhs in
            let lhsFavorite = settings.isEnglishTranslationFavorite(id: lhs.id)
            let rhsFavorite = settings.isEnglishTranslationFavorite(id: rhs.id)
            if lhsFavorite != rhsFavorite { return lhsFavorite }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        guard !query.isEmpty else { return sorted }

        return sorted.filter { edition in
            edition.name.localizedCaseInsensitiveContains(query) ||
            (viewModel.translations[edition.id]?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    private var shouldShowQuranText: Bool {
        guard quranData.ayah(surah: surahNumber, ayah: ayahNumber) != nil else {
            return false
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        guard let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber) else { return false }
        let arabic = ayah.displayArabicText(surahId: surahNumber, clean: settings.cleanArabicText)
        return "Transliteration".localizedCaseInsensitiveContains(query) ||
            arabic.localizedCaseInsensitiveContains(query) ||
            ayah.textTransliteration.localizedCaseInsensitiveContains(query)
    }

    var body: some View {
        NavigationView {
            List {
                Group {
                    Section {
                        Text("Compare this ayah across several English Qur'an translations. Results are loaded from alquran.cloud.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if shouldShowQuranText,
                       let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber) {
                        Section(header: Text("QURAN TEXT")) {
                            comparisonRow(
                                title: nil,
                                text: ayah.displayArabicText(surahId: surahNumber, clean: settings.cleanArabicText),
                                isArabic: true
                            )

                            if settings.showTransliteration {
                                comparisonRow(title: "Transliteration", text: ayah.textTransliteration)
                            }
                        }
                    }

                    Section(header: Text("DOWNLOADED TRANSLATIONS")) {
                        if let ayah = quranData.ayah(surah: surahNumber, ayah: ayahNumber) {
                            ForEach(filteredInAppEditions) { edition in
                                comparisonRow(
                                    title: edition.name,
                                    text: inAppTranslationText(for: edition.id, ayah: ayah),
                                    editionID: edition.id,
                                    isDownloaded: true
                                )
                            }

                            if filteredInAppEditions.isEmpty {
                                Text("No downloaded translations found.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Section(header: Text("ONLINE TRANSLATIONS")) {
                        if viewModel.isLoading && viewModel.translations.isEmpty {
                            HStack {
                                ProgressView()
                                Text("Loading translations...")
                                    .foregroundStyle(.secondary)
                            }
                        } else if let errorMessage = viewModel.errorMessage, viewModel.translations.isEmpty {
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                            ForEach(filteredOnlineEditions) { edition in
                                comparisonRow(
                                    title: edition.name,
                                    text: viewModel.translations[edition.id] ?? "Unavailable",
                                    editionID: edition.id
                                )
                                .opacity(viewModel.translations[edition.id] == nil ? 0.55 : 1)
                            }

                            if filteredOnlineEditions.isEmpty {
                                Text("No translations found.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .compactListSectionSpacing()
            .navigationTitle("Translation Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText.animation(.easeInOut), prompt: "Search translations")
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
            .task(id: loadKey) {
                await viewModel.loadIfNeeded()
            }
        }
        .modifier(TafsirSheetPresentationModifier())
    }

    private func inAppTranslationText(for editionID: String, ayah: Ayah? = nil) -> String {
        let resolvedAyah = ayah ?? quranData.ayah(surah: surahNumber, ayah: ayahNumber)
        guard let resolvedAyah else { return "" }
        switch editionID {
        case "inapp.saheeh":
            return resolvedAyah.textEnglishSaheeh
        case "inapp.mustafa":
            return resolvedAyah.textEnglishMustafa
        default:
            return ""
        }
    }

    private func comparisonRow(title: String?, text: String, editionID: String? = nil, isArabic: Bool = false, isDownloaded: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title, !title.isEmpty {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    HighlightedSnippet(
                        source: title,
                        term: searchText,
                        font: .subheadline.weight(.semibold),
                        accent: settings.accentColor.color,
                        fg: .primary
                    )

                    Spacer()

                    if let editionID, !isDownloaded {
                        Button {
                            settings.hapticFeedback()
                            withAnimation(.easeInOut) {
                                settings.toggleEnglishTranslationFavorite(id: editionID)
                            }
                        } label: {
                            Image(systemName: settings.isEnglishTranslationFavorite(id: editionID) ? "star.fill" : "star")
                                .foregroundStyle(settings.accentColor.color)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(settings.isEnglishTranslationFavorite(id: editionID) ? "Unfavorite Translation" : "Favorite Translation")
                    }
                }
            }

            HighlightedSnippet(
                source: text,
                term: searchText,
                font: isArabic
                    ? .custom(settings.fontArabic, size: UIFont.preferredFont(forTextStyle: .title3).pointSize)
                    : .subheadline,
                accent: settings.accentColor.color,
                fg: .primary
            )
                .arabicFontDesign(custom: isArabic && settings.quranUsesCustomArabicFace)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(isArabic ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
        }
        .padding(.vertical, 4)
        .textSelection(.enabled)
    }
}
#endif

struct AyahContextMenuModifier: ViewModifier {
    @ObservedObject var settings = Settings.shared
    @ObservedObject var quranData = QuranData.shared
    @ObservedObject var quranPlayer = QuranPlayer.shared

    let surah: Int
    let ayah: Int

    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    let lastRead: Bool
    /// When true, the menu leads with "Hide for Today" + "Delete Forever" (the Ayah of the Day card).
    var ayahOfTheDay: Bool = false

    @State var showAyahSheet = false

    @State private var showingNoteSheet = false
    @State private var draftNote: String = ""
    @State private var showRespectAlert = false
    @State private var showCustomRangeSheet = false
    @State private var showTafsirSheet = false
    @State private var showQiraahComparisonSheet = false
    @State private var showEnglishComparisonSheet = false

    private var isBookmarked: Bool {
        bookmarkedAyahs.contains("\(surah)-\(ayah)")
    }

    func containsProfanity(_ text: String) -> Bool {
        let t = text.folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current).lowercased()
        return profanityFilter.contains { !$0.isEmpty && t.contains($0) }
    }

    private func isNoteAllowed(_ text: String) -> Bool {
        !containsProfanity(text)
    }

    private var bookmarkIndex: Int? {
        settings.bookmarkIndex(surah: surah, ayah: ayah)
    }

    private var bookmark: BookmarkedAyah? {
        settings.bookmarkedAyah(surah: surah, ayah: ayah)
    }

    private var isBookmarkedHere: Bool { bookmarkIndex != nil }
    private var currentNote: String {
        settings.bookmarkNoteText(surah: surah, ayah: ayah)
    }

    private var canCompareEnglishText: Bool {
        settings.isHafsDisplay
    }

    #if os(iOS)
    @ViewBuilder
    private var comparisonMenuBlock: some View {
        if settings.showQiraahDetails && canCompareEnglishText {
            Menu {
                Button {
                    settings.hapticFeedback()
                    showQiraahComparisonSheet = true
                } label: {
                    Label("Qiraah Comparison", systemImage: "character.book.closed.fill.ar")
                }

                Button {
                    settings.hapticFeedback()
                    showEnglishComparisonSheet = true
                } label: {
                    Label("Translation Comparison", systemImage: "character.book.closed")
                }
            } label: {
                Label("Compare Ayah", systemImage: "rectangle.split.2x1")
            }
        } else if settings.showQiraahDetails {
            Button {
                settings.hapticFeedback()
                showQiraahComparisonSheet = true
            } label: {
                Label("Qiraah Comparison", systemImage: "character.book.closed.fill.ar")
            }
        } else if canCompareEnglishText {
            Button {
                settings.hapticFeedback()
                showEnglishComparisonSheet = true
            } label: {
                Label("Translation Comparison", systemImage: "character.book.closed")
            }
        }
    }
    #endif

    private func setNote(_ text: String?) {
        settings.setBookmarkNote(surah: surah, ayah: ayah, note: text)
    }

    private func removeNote() {
        settings.removeBookmarkNote(surah: surah, ayah: ayah)
    }

    @State private var confirmRemoveNote = false
    @State private var confirmDeleteForever = false

    private func toggleBookmarkWithNoteGuard() {
        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah, ayah: ayah) {
            confirmRemoveNote = true
        }
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        // O(1) dictionary lookup, not an O(114) linear scan. This `body` re-evaluates whenever `settings`/
        // `quranPlayer` publish (constant during playback), and the modifier sits on every history/bookmark/
        // favorite row - the linear scan added up across all visible rows.
        let surahObj = quranData.surah(surah)

        #if os(iOS)
        content
            .contextMenu {
                if ayahOfTheDay {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation {
                            settings.ayahOfTheDayHiddenDate = Settings.dayKey()
                        }
                    } label: { Label("Hide for Today", systemImage: "eye.slash") }

                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        confirmDeleteForever = true
                    } label: { Label("Delete Forever", systemImage: "trash") }

                    Divider()
                } else if lastRead {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation {
                            settings.lastReadSurah = 0
                            settings.lastReadAyah = 0
                        }
                    } label: { Label("Remove", systemImage: "minus.circle") }

                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        confirmDeleteForever = true
                    } label: { Label("Delete Forever", systemImage: "trash") }

                    Divider()
                }

                Button(role: isBookmarked ? .destructive : .cancel) {
                    settings.hapticFeedback()
                    toggleBookmarkWithNoteGuard()
                } label: {
                    Label(
                        isBookmarked ? "Unbookmark Ayah" : "Bookmark Ayah",
                        systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                    )
                }

                Button {
                    settings.hapticFeedback()
                    if !isBookmarked {
                        settings.ensureBookmarkExists(surah: surah, ayah: ayah)
                    }
                    draftNote = currentNote
                    showingNoteSheet = true
                } label: {
                    Label(currentNote.isEmpty ? "Add Note" : "Edit Note", systemImage: "note.text")
                }

                if !currentNote.isEmpty {
                    Button(role: .destructive) {
                        settings.hapticFeedback()
                        withAnimation(.easeInOut) {
                            removeNote()
                        }
                    } label: {
                        Label("Remove Note", systemImage: "minus.circle")
                    }
                }

                if settings.isHafsDisplay {
                    Button {
                        settings.hapticFeedback()
                        showTafsirSheet = true
                    } label: {
                        Label("See Tafsir", systemImage: "text.book.closed")
                    }
                }

                comparisonMenuBlock

                if settings.isHafsDisplay {
                    Menu {
                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playAyah(surahNumber: surah, ayahNumber: ayah)
                        } label: {
                            Label("Play This Ayah", systemImage: "play.circle")
                        }
                        Button {
                            settings.hapticFeedback()
                            quranPlayer.playAyah(
                                surahNumber: surah,
                                ayahNumber: ayah,
                                continueRecitation: true
                            )
                        } label: {
                            Label("Play From Ayah", systemImage: "play.circle.fill")
                        }
                        Button {
                            settings.hapticFeedback()
                            showCustomRangeSheet = true
                        } label: {
                            Label("Play Custom Range", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Label("Play Ayah", systemImage: "play.circle")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    ShareAyahSheet.copyAyahToPasteboard(surahNumber: surah, ayahNumber: ayah, settings: settings, quranData: quranData)
                } label: {
                    Label("Copy Ayah", systemImage: "doc.on.doc")
                }

                Button {
                    settings.hapticFeedback()
                    showAyahSheet = true
                } label: {
                    Label("Share Ayah", systemImage: "square.and.arrow.up")
                }

                Divider()

                if let surah = surahObj {
                    SurahContextMenu(
                        surahID: surah.id,
                        surahName: surah.nameTransliteration,
                        favoriteSurahs: favoriteSurahs,
                        searchText: $searchText,
                        scrollToSurahID: $scrollToSurahID
                    )
                }
            }
            .sheet(isPresented: $showAyahSheet) {
                ShareAyahSheet(
                    surahNumber: surah,
                    ayahNumber: ayah
                )
                .smallMediumSheetPresentation()
            }
            .sheet(isPresented: $showTafsirSheet) {
                if let surahObj = surahObj {
                    AyahTafsirSheet(
                        surahName: surahObj.nameTransliteration,
                        surahNumber: surahObj.id,
                        ayahNumber: ayah
                    )
                    .smallMediumSheetPresentation()
                }
            }
            .sheet(isPresented: $showCustomRangeSheet) {
                if let surahObj = surahObj {
                    PlayCustomRangeSheet(
                        surah: surahObj,
                        initialStartAyah: ayah,
                        initialEndAyah: PlayCustomRangeSheet.defaultEndAyah(
                            startAyah: ayah,
                            surah: surahObj,
                            displayQiraah: settings.displayQiraahForArabic
                        ),
                        onPlay: { start, end, repAyah, repSec in
                            quranPlayer.playCustomRange(
                                surahNumber: surahObj.id,
                                surahName: surahObj.nameTransliteration,
                                startAyah: start,
                                endAyah: end,
                                repeatPerAyah: repAyah,
                                repeatSection: repSec
                            )
                        },
                        onCancel: { showCustomRangeSheet = false }
                    )
                    .environmentObject(settings)
                    .smallMediumSheetPresentation()
                }
            }
            .sheet(isPresented: $showQiraahComparisonSheet) {
                AyahQiraahComparisonSheet(surahNumber: surah, ayahNumber: ayah)
                    .smallMediumSheetPresentation()
                    .environmentObject(settings)
                    .environmentObject(quranData)
            }
            .sheet(isPresented: $showEnglishComparisonSheet) {
                AyahEnglishComparisonSheet(surahNumber: surah, ayahNumber: ayah)
                    .smallMediumSheetPresentation()
                    .environmentObject(settings)
                    .environmentObject(quranData)
            }
            .sheet(isPresented: $showingNoteSheet) {
                if let surah = surahObj {
                    NoteEditorSheet(
                        title: "Note for \(surah.nameTransliteration) \(surah.id):\(ayah)",
                        text: $draftNote,
                        onAttemptSave: { text in
                            if isNoteAllowed(text) {
                                setNote(text)
                                return true
                            } else {
                                showRespectAlert = true
                                return false
                            }
                        },
                        onCancel: {},
                        onSave: { setNote(draftNote) }
                    )
                    .smallMediumSheetPresentation()
                }
            }
            .confirmationDialog("Note not saved", isPresented: $showRespectAlert, titleVisibility: .visible) {
                Button("OK") { }
            } message: {
                Text("Please keep notes Islamic and respectful.")
            }
            .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    settings.hapticFeedback()
                    settings.toggleBookmark(surah: surah, ayah: ayah)
                }
                Button("Cancel") {}
            } message: {
                Text(Settings.bookmarkNoteRemovalDialogMessage)
            }
            .confirmationDialog("Are you sure?", isPresented: $confirmDeleteForever, titleVisibility: .visible) {
                Button("Remove Permanently", role: .destructive) {
                    settings.hapticFeedback()
                    withAnimation {
                        if ayahOfTheDay {
                            settings.showAyahOfTheDay = false
                        } else {
                            settings.lastReadSurah = 0
                            settings.lastReadAyah = 0
                            settings.saveLastReadAyah = false
                        }
                    }
                }
                Button("Cancel") {}
            } message: {
                Text(ayahOfTheDay
                     ? "You can re-enable Ayah of the Day later in Quran Settings."
                     : "You can re-enable Last Read Ayah later in Quran Settings.")
            }
        #else
        content
        #endif
    }
}

extension View {
    func ayahContextMenuModifier(
        surah: Int,
        ayah: Int,
        favoriteSurahs: Set<Int>,
        bookmarkedAyahs: Set<String>,
        searchText: Binding<String>,
        scrollToSurahID: Binding<Int>,
        lastRead: Bool = false,
        ayahOfTheDay: Bool = false
    ) -> some View {
        self.modifier(AyahContextMenuModifier(
            surah: surah,
            ayah: ayah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            searchText: searchText,
            scrollToSurahID: scrollToSurahID,
            lastRead: lastRead,
            ayahOfTheDay: ayahOfTheDay
        ))
    }
}

struct LeftSwipeActions: ViewModifier {
    @ObservedObject private var settings = Settings.shared

    let surah: Int
    let favoriteSurahs: Set<Int>
    let bookmarkedAyahs: Set<String>?
    let bookmarkedSurah: Int?
    let bookmarkedAyah: Int?

    private var isFavorite: Bool {
        favoriteSurahs.contains(surah)
    }

    private var isBookmarked: Bool {
        if let bookmarkedAyahs, let s = bookmarkedSurah, let a = bookmarkedAyah {
            return bookmarkedAyahs.contains("\(s)-\(a)")
        }
        return false
    }

    private var bookmarkIndex: Int? {
        let surah = bookmarkedSurah ?? 1
        let ayah = bookmarkedAyah ?? 1

        return settings.bookmarkIndex(surah: surah, ayah: ayah)
    }

    private var bookmark: BookmarkedAyah? {
        settings.bookmarkedAyah(surah: bookmarkedSurah ?? 1, ayah: bookmarkedAyah ?? 1)
    }

    private var isBookmarkedHere: Bool { bookmarkIndex != nil }

    private var currentNote: String {
        settings.bookmarkNoteText(surah: bookmarkedSurah ?? 1, ayah: bookmarkedAyah ?? 1)
    }

    @State private var confirmRemoveNote = false

    private func toggleBookmarkWithNoteGuard(_ surah: Int, _ ayah: Int) {
        if !settings.toggleBookmarkIfNoNoteLoss(surah: surah, ayah: ayah) {
            confirmRemoveNote = true
        }
    }

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .swipeActions(edge: .leading) {
                Button {
                    settings.hapticFeedback()
                    withAnimation(.easeInOut) {
                        settings.toggleSurahFavorite(surah: surah)
                    }
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                }
                .tint(settings.accentColor.color)

                if let s = bookmarkedSurah, let a = bookmarkedAyah {
                    Button {
                        settings.hapticFeedback()
                        toggleBookmarkWithNoteGuard(s, a)
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                    .tint(settings.accentColor.color)
                }
            }
            #endif
            .confirmationDialog(Settings.bookmarkNoteRemovalDialogTitle, isPresented: $confirmRemoveNote, titleVisibility: .visible) {
                Button("Remove", role: .destructive) {
                    settings.hapticFeedback()
                    settings.toggleBookmark(surah: bookmarkedSurah ?? 1, ayah: bookmarkedAyah ?? 1)
                }
                Button("Cancel") {}
            } message: {
                Text(Settings.bookmarkNoteRemovalDialogMessage)
            }
    }
}

public extension View {
    func leftSwipeActions(
        surah: Int,
        favoriteSurahs: Set<Int>,
        bookmarkedAyahs: Set<String>? = nil,
        bookmarkedSurah: Int? = nil,
        bookmarkedAyah: Int? = nil
    ) -> some View {
        modifier(LeftSwipeActions(
            surah: surah,
            favoriteSurahs: favoriteSurahs,
            bookmarkedAyahs: bookmarkedAyahs,
            bookmarkedSurah: bookmarkedSurah,
            bookmarkedAyah: bookmarkedAyah
        ))
    }
}

struct RightSwipeActions: ViewModifier {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var quranPlayer = QuranPlayer.shared

    let surahID: Int
    let surahName: String
    let ayahID: Int?
    let certainReciter: Bool

    @Binding var searchText: String
    @Binding var scrollToSurahID: Int

    private func endEditing() {
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    func body(content: Content) -> some View {
        content
            #if os(iOS)
            .swipeActions(edge: .trailing) {
                Button {
                    settings.hapticFeedback()
                    quranPlayer.playSurah(
                        surahNumber: surahID,
                        surahName: surahName,
                        certainReciter: certainReciter
                    )
                } label: {
                    Image(systemName: "play.fill")
                }
                .tint(settings.accentColor.color)

                if let ayah = ayahID {
                    Button {
                        settings.hapticFeedback()
                        quranPlayer.playAyah(surahNumber: surahID, ayahNumber: ayah)
                    } label: {
                        Image(systemName: "play.circle")
                    }
                }

                Button {
                    settings.hapticFeedback()
                    withAnimation {
                        searchText = ""
                        scrollToSurahID = surahID
                        endEditing()
                    }
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .tint(.secondary)
            }
            #endif
    }
}

public extension View {
    func rightSwipeActions(
        surahID: Int,
        surahName: String,
        ayahID: Int? = nil,
        certainReciter: Bool = false,
        searchText: Binding<String>,
        scrollToSurahID: Binding<Int>
    ) -> some View {
        modifier(RightSwipeActions(
            surahID: surahID,
            surahName: surahName,
            ayahID: ayahID,
            certainReciter: certainReciter,
            searchText: searchText,
            scrollToSurahID: scrollToSurahID
        ))
    }
}

#if os(iOS)
import SwiftUI

struct NoteEditorSheet: View {
    @ObservedObject var settings = Settings.shared

    let title: String
    @Binding var text: String
    var onAttemptSave: (String) -> Bool
    var onCancel: () -> Void
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    private let maxChars: Int = 300

    private var characterCount: Int { text.count }
    private var remaining: Int { max(0, maxChars - characterCount) }
    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                let cardFill   = Color(UIColor.secondarySystemBackground)
                let cardStroke = Color.primary.opacity(0.12)

                TextEditor(text: $text)
                    .padding(12)
                    .background(Color.clear)
                    .frame(minHeight: 220)
                    .modifier(HideEditorScrollBackground())
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .onChange(of: text) { newValue in
                        if newValue.count > maxChars {
                            text = String(newValue.prefix(maxChars))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(cardFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(cardStroke, lineWidth: 1)
                    )

                Text("\(remaining) characters left")
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Character limit")
                    .accessibilityValue("\(maxChars) limit, \(remaining) remaining")

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "hands.sparkles")
                            .imageScale(.large)
                        Text("A respectful reminder")
                            .font(.headline)
                    }
                    .foregroundColor(.accentColor)

                    Text("Your note will appear next to the Quran, the Words of Allah ﷻ. Please keep it dignified and beneficial.")
                        .font(.subheadline)

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Avoid profanity or insults", systemImage: "checkmark.seal")
                        Label("No mockery, slurs, or indecency", systemImage: "checkmark.seal")
                        Label("Keep remarks relevant and respectful", systemImage: "checkmark.seal")
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)

                    Text("May Allah ﷻ reward you, protect you, and keep us all firm upon the truth.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
                .accessibilityElement(children: .combine)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(cardFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(cardStroke, lineWidth: 1)
                )
            }
            .padding(.horizontal)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        settings.hapticFeedback()
                        onCancel()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(settings.accentColor.color)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        settings.hapticFeedback()
                        if onAttemptSave(text) {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.body.weight(.semibold))
                    }
                    .tint(settings.accentColor.color)
                    .disabled(isEmpty)
                }
            }
        }
    }
}

private struct HideEditorScrollBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
                .onAppear {
                    UITextView.appearance().backgroundColor = .clear
                }
        }
    }
}

private struct SurahContextMenuPreviewContent: View {
    @State private var searchText = ""
    @State private var scrollToSurahID = 0

    var body: some View {
        Menu("Open Surah Actions") {
            SurahContextMenu(
                surahID: AlIslamPreviewData.surah.id,
                surahName: AlIslamPreviewData.surah.nameTransliteration,
                favoriteSurahs: [],
                searchText: $searchText,
                scrollToSurahID: $scrollToSurahID
            )
        }
        .padding()
    }
}

// The generic focus overlay lives in Helpers and knows nothing about the Quran; a surah teaches it how to
// render itself here, so the overlay stays usable in an app that ships without a Quran.
extension FocusItem {
    static func surah(_ surah: Surah) -> FocusItem {
        FocusItem(
            id: "surah-\(surah.id)",
            arabic: surah.nameArabic,
            title: "\(surah.id) · \(surah.nameTransliteration)",
            subtitle: surah.nameEnglish,
            footnote: "\(surah.type.capitalized) · \(surah.numberOfAyahs) ayahs",
            secondaryArabic: surah.idArabic,
            shareLabel: "Share Surah",
            shareText: """
            Surah \(surah.id) - \(surah.nameTransliteration) (\(surah.nameArabic))
            \(surah.nameEnglish)
            \(surah.type.capitalized) · \(surah.numberOfAyahs) ayahs
            """
        )
    }
}

#Preview {
    AlIslamPreviewContainer(embedInNavigation: false) {
        SurahContextMenuPreviewContent()
    }
}

/// Lets you pull text out of an ayah by hand: drag over any part of the Arabic, the transliteration, or a
/// translation and copy exactly that.
///
/// The reader already has "Copy Ayah", but that copies the whole thing in a fixed format. Selecting inside a row in
/// the surah list is fussy at best, because the row is competing for the same drag with the list's scroll. Lifting
/// the text into a sheet of its own gives the selection somewhere to live, and each block also gets a one-tap copy
/// for when the whole block is what you wanted.
struct SelectAyahTextSheet: View {
    @ObservedObject var settings = Settings.shared
    @Environment(\.dismiss) private var dismiss

    let surah: Surah
    let ayah: Ayah

    @State private var copiedLabel: String?

    private var usesCustomArabicFace: Bool {
        !settings.removeArabicDots && settings.quranUsesCustomArabicFace
    }

    private var arabicText: String {
        ayah.displayArabicText(
            surahId: surah.id,
            clean: settings.cleanArabicText,
            qiraahOverride: settings.displayQiraahForArabic
        )
    }

    var body: some View {
        NavigationView {
            List {
                Group {
                    if settings.showArabicText {
                        selectableBlock(
                            title: "ARABIC",
                            text: arabicText,
                            font: usesCustomArabicFace
                                ? .custom(settings.fontArabic, size: settings.fontArabicSize)
                                : .system(size: settings.fontArabicSize, design: .rounded),
                            isArabic: true
                        )
                    }

                    if settings.showTransliteration, settings.isHafsDisplay, !ayah.textTransliteration.isEmpty {
                        selectableBlock(
                            title: "TRANSLITERATION",
                            text: ayah.textTransliteration,
                            font: .system(size: settings.englishFontSize),
                            isArabic: false
                        )
                    }

                    if settings.showEnglishSaheeh, settings.isHafsDisplay, !ayah.textEnglishSaheeh.isEmpty {
                        selectableBlock(
                            title: "SAHEEH INTERNATIONAL",
                            text: ayah.textEnglishSaheeh,
                            font: .system(size: settings.englishFontSize),
                            isArabic: false
                        )
                    }

                    if settings.showEnglishMustafa, settings.isHafsDisplay, !ayah.textEnglishMustafa.isEmpty {
                        selectableBlock(
                            title: "CLEAR QURAN (MUSTAFA KHATTAB)",
                            text: ayah.textEnglishMustafa,
                            font: .system(size: settings.englishFontSize),
                            isArabic: false
                        )
                    }

                    Section {
                        Text("Press and drag over any part of the text above to select it, then copy. The button on each block copies that whole block.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .themedListRowBackground()
            }
            .applyConditionalListStyle()
            .navigationTitle("\(surah.nameTransliteration) \(surah.id):\(ayah.id)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func selectableBlock(title: String, text: String, font: Font, isArabic: Bool) -> some View {
        Section {
            Text(text)
                .font(font)
                .arabicFontDesign(custom: isArabic && usesCustomArabicFace)
                .foregroundColor(.primary)
                .multilineTextAlignment(isArabic ? .trailing : .leading)
                .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
                .lineSpacing(isArabic ? 8 : 2)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .padding(.vertical, 4)
        } header: {
            HStack {
                Text(title)

                Spacer()

                Button {
                    settings.hapticFeedback()
                    UIPasteboard.general.string = text
                    withAnimation(.easeInOut) { copiedLabel = title }
                    // Long enough to read, short enough that it doesn't linger into the next copy.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut) {
                            if copiedLabel == title { copiedLabel = nil }
                        }
                    }
                } label: {
                    Label(
                        copiedLabel == title ? "Copied" : "Copy",
                        systemImage: copiedLabel == title ? "checkmark" : "doc.on.doc"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundColor(settings.accentColor.color)
                }
                .buttonStyle(.plain)
                .textCase(nil)
            }
        }
    }
}
#endif
